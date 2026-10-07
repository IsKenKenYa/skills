#!/usr/bin/env node
import { existsSync, mkdirSync, writeFileSync, renameSync } from 'node:fs';
import { join, resolve } from 'node:path';
import readline from 'node:readline/promises';
import { detectModel, enumerateFiles, extractReferences } from './extract.js';
import { detectSdkCandidates, validateSdkDir, sdkVersionOf } from './sdk-locator.js';
import { scanMarks } from './sdk-marks.js';
import { buildKitIndex } from './kit-index.js';
import { buildNativeSymbolIndex } from './native-index.js';
import { loadRules, classify, BUCKETS } from './classify.js';
import { renderJson, renderMarkdown } from './report.js';

/** CLI 退出码映射（spec CLI-1，v1.2 固化，跨版本稳定） */
const EXIT_OK = 0;        // 成功（含 SDK 未检出单源降级的成功产出，R-14）
const EXIT_INTERNAL = 1;  // 内部错误：未预期异常
const EXIT_USAGE = 2;     // 输入无效：根目录不存在/不可读、参数非法值
const EXIT_MODEL = 3;     // 模型不支持：project_model=fa/unknown（产物照常写出）
const EXIT_ABORT = 4;     // 用户中止：SDK 目录确认环节中止/输入流结束（R-15）

function usage() {
  return [
    '用法: node scripts/scan.js <工程根目录> [--out <输出目录>] [--sdk-dir <OpenHarmony SDK 目录>] [--yes] [--no-sdk] [--rules <规则表路径>]',
    '',
    '  <工程根目录>            待扫描的 Stage 工程根目录（必填）',
    '  --out <目录>            输出目录（默认 <工程根>/arkuix-scan-output；重跑覆盖旧产物时有确认/警示）',
    '  --sdk-dir <目录>        显式指定 OpenHarmony SDK 目录（视同确认；适用于 CI/脚本；--sdk-path 为兼容别名）',
    '  --yes                   非交互采纳探测到的 SDK（视同确认）',
    '  --no-sdk                明确降级为规则表单源判定（报告中显著标注）',
    '  --rules <路径>          自定义规则表（默认 rules/adaptation.json）',
    '',
    '退出码: 0=成功（含单源降级产出）; 1=内部错误; 2=输入无效; 3=模型不支持（FA/unknown，产物照常写出）; 4=用户中止（SDK 确认中止）'
  ].join('\n');
}

function parseArgs(argv) {
  const opts = { root: null, out: null, sdkDir: null, yes: false, noSdk: false, rules: null };
  const positional = [];
  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i];
    if (arg === '--out') opts.out = argv[++i];
    else if (arg === '--sdk-dir' || arg === '--sdk-path') opts.sdkDir = argv[++i];
    else if (arg === '--yes') opts.yes = true;
    else if (arg === '--no-sdk') opts.noSdk = true;
    else if (arg === '--rules') opts.rules = argv[++i];
    else if (arg === '-h' || arg === '--help') { console.log(usage()); process.exit(EXIT_OK); }
    else positional.push(arg);
  }
  opts.root = positional[0] || null;
  return opts;
}

/** 仅当存在 Native 源码文件时才构建 sysroot 索引（纯 ArkTS 工程零开销） */
function inventoryHasNative(files) {
  const nativeExts = new Set(['.cpp', '.cc', '.cxx', '.h', '.hpp']);
  return files.some((f) => nativeExts.has(f.slice(f.lastIndexOf('.'))));
}

function emptyAdaptation() {
  const adaptation = {};
  for (const bucket of BUCKETS) adaptation[bucket] = [];
  return adaptation;
}

function atomicWrite(file, content) {
  const tmp = `${file}.tmp-${process.pid}`;
  writeFileSync(tmp, content, 'utf8');
  renameSync(tmp, file);
}

/**
 * R-15：探测 → 展示 → 确认/调整 → 校验；AC-2.9 未确认不产出判定。
 * 非 TTY 且未提供 --sdk-dir/--no-sdk → 自动降级单源并标注（CI 不中断，AC-2.9）。
 * 返回 {aborted:true} 表示用户中止/流结束（调用方退出码 4）。
 */
async function confirmSdk(opts) {
  if (opts.noSdk) return { degraded: true };
  if (opts.sdkDir) {
    const validation = validateSdkDir(opts.sdkDir);
    if (!validation.ok) {
      console.error(`错误: 指定的 SDK 目录无效（${validation.reason}）: ${opts.sdkDir}`);
      process.exit(EXIT_USAGE);
    }
    return { path: resolve(opts.sdkDir), apiDir: validation.apiDir, confirmed: true, origin: 'explicit' };
  }

  const valid = [];
  for (const candidate of detectSdkCandidates(null)) {
    const validation = validateSdkDir(candidate.path);
    if (validation.ok) valid.push({ ...candidate, ...validation });
  }
  if (valid.length === 0) return requestSdkOrDegrade();

  const best = valid[0];
  if (opts.yes) {
    // SD32：--yes = 显式授权自动探测（CI 语义），confirmed=true，origin 记 auto 供报告追溯
    return { path: resolve(best.path), apiDir: best.apiDir, confirmed: true, origin: `auto:${best.origin}` };
  }
  if (!process.stdin.isTTY) {
    // SD32（用户反馈：SDK 判定源必须经使用者确认——agent 驱动场景不能默默选）：
    // 非 TTY 探测到候选但无 --sdk-dir（显式确认）也无 --yes（授权自动探测）→ 不产出判定，
    // 列出全部候选请 agent 呈报用户确认后以 --sdk-dir 重跑（退出码 4，零产出）
    console.error('检测到以下 OpenHarmony SDK 候选（未经确认，不产出判定）：');
    for (const c of valid) {
      console.error(`  - ${c.path}（版本 ${sdkVersionOf(c.path)}，来源 ${c.origin}）`);
    }
    console.error('请确认用作判定源的 SDK 目录后，以 --sdk-dir <目录> 重跑；CI/自动化可 --yes 接受自动探测的最佳候选。');
    return { aborted: true, reason: 'SDK 候选未经确认（非交互）' };
  }
  const picked = await interactiveConfirm(valid);
  return picked.aborted ? picked : { ...picked, origin: 'interactive' };
}

async function requestSdkOrDegrade() {
  if (!process.stdin.isTTY) {
    console.error('未检出 OpenHarmony SDK；非交互环境自动降级为规则表单源判定并在报告标注（如需双源判定请以 --sdk-dir 提供 SDK 目录）。');
    return { degraded: true };
  }
  const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
  try {
    const answer = (await rl.question(
      '未检出 OpenHarmony SDK。请输入 SDK 目录（直接回车 = 降级为规则表单源判定，报告中将标注）: ')).trim();
    if (answer === '') return { degraded: true };
    const validation = validateSdkDir(answer);
    if (!validation.ok) {
      console.error(`目录无效（${validation.reason}），请重新运行并提供有效 SDK 目录。`);
      process.exit(EXIT_USAGE);
    }
    return { path: resolve(answer), apiDir: validation.apiDir, confirmed: true };
  } catch (err) {
    return { aborted: true };
  } finally {
    rl.close();
  }
}

async function interactiveConfirm(valid) {
  const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
  try {
    let index = 0;
    for (;;) {
      const candidate = valid[index];
      const version = sdkVersionOf(candidate.path);
      console.log('\n检测到 OpenHarmony SDK:');
      console.log(`  目录: ${candidate.path}`);
      console.log(`  版本: ${version}（来源: ${candidate.origin}）`);
      const answer = (await rl.question(
        '确认使用该 SDK？[Y=确认 / n=输入其他目录 / r=切换下一个候选 / q=中止] ')).trim().toLowerCase();
      if (answer === '' || answer === 'y') {
        return { path: candidate.path, apiDir: candidate.apiDir, confirmed: true };
      }
      if (answer === 'r') {
        index = (index + 1) % valid.length;
        continue;
      }
      if (answer === 'q') {
        return { aborted: true };
      }
      const validation = validateSdkDir(answer);
      if (!validation.ok) {
        console.log(`目录无效（${validation.reason}），请重试。`);
        continue;
      }
      return { path: resolve(answer), apiDir: validation.apiDir, confirmed: true };
    }
  } catch (err) {
    return { aborted: true };
  } finally {
    rl.close();
  }
}

async function main(argv) {
  const opts = parseArgs(argv);
  if (!opts.root) {
    console.error(usage());
    process.exit(EXIT_USAGE);
  }
  const root = resolve(opts.root);
  if (!existsSync(root)) {
    console.error(`错误: 工程根目录不存在: ${root}`);
    process.exit(EXIT_USAGE);
  }
  // SD33（A）：缺省输出目录锚定工程根（原 CWD 漂移——在哪跑落哪，产物散落且曾误入 git）
  const outDir = resolve(opts.out || join(root, 'arkuix-scan-output'));
  // SD33（B）：覆盖确认——已有旧产物时 TTY 询问、非 TTY 显著警示后继续（不阻断 CI）
  const prevReport = join(outDir, 'scan-report.json');
  if (existsSync(prevReport) && !opts.yes) {
    if (process.stdin.isTTY) {
      const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
      try {
        const answer = (await rl.question(
          `输出目录已有上次扫描产物（${outDir}），覆盖? [Y=覆盖 / q=中止] `)).trim().toLowerCase();
        if (answer === 'q' || answer === 'n') {
          console.error('用户中止：未覆盖既有产物（可 --out 指定新目录后重跑）。');
          process.exit(EXIT_ABORT);
        }
      } finally {
        rl.close();
      }
    } else {
      console.error(`提示: 输出目录已有上次扫描产物，本次将覆盖（${outDir}）；如需保留请 --out 指定新目录。`);
    }
  }

  const model = detectModel(root);
  let inventory = [];
  let dynamicHints = [];
  let adaptation = emptyAdaptation();
  let sdkInfo = null;
  let degraded = false;
  let rules = null;

  if (model === 'stage') {
    sdkInfo = await confirmSdk(opts);
    if (sdkInfo.aborted) {
      console.error('用户中止：未完成 SDK 确认，不产出适配判定（AC-2.9）。');
      process.exit(EXIT_ABORT);
    }
    const files = enumerateFiles(root);
    const kitsDir = sdkInfo && !sdkInfo.degraded && sdkInfo.apiDir
      ? join(sdkInfo.apiDir, '..', 'kits') : null;
    const sysrootDir = sdkInfo && !sdkInfo.degraded && sdkInfo.apiDir
      ? join(sdkInfo.apiDir, '..', '..', 'native', 'sysroot', 'usr', 'include') : null;
    ({ inventory, dynamicHints } = extractReferences(root, files, {
      kitIndex: buildKitIndex(kitsDir),
      nativeIndex: inventoryHasNative(files) ? buildNativeSymbolIndex(existsSync(sysrootDir) ? sysrootDir : null) : null
    }));
    rules = loadRules(opts.rules);
    let marks = null;
    if (sdkInfo && !sdkInfo.degraded) {
      try {
        marks = scanMarks(sdkInfo.apiDir);
      } catch (err) {
        console.error(`错误: ${err.message}`);
        process.exit(EXIT_INTERNAL);
      }
    } else {
      degraded = true;
    }
    ({ adaptation } = classify(inventory, rules, marks));
  }

  const scanReport = {
    schema_version: 1,
    project_model: model,
    ...((sdkInfo && !sdkInfo.degraded)
      ? { sdk: { path: sdkInfo.path, version: sdkVersionOf(sdkInfo.path), confirmed: sdkInfo.confirmed, origin: sdkInfo.origin || 'unknown' } }
      : {}),
    inventory,
    adaptation
  };

  mkdirSync(outDir, { recursive: true });
  atomicWrite(join(outDir, 'scan-report.json'), renderJson(scanReport));
  atomicWrite(join(outDir, 'migration-advice.md'), renderMarkdown(scanReport, { degraded, rules, dynamicHints }));

  if (model === 'fa') {
    console.log('FA 模型不支持，仅支持 Stage 模型；ScanReport.project_model=fa，未产出适配分类。');
    process.exit(EXIT_MODEL);
  } else if (model === 'unknown') {
    console.log('工程模型无法判定（缺 Stage/FA 工程特征）；ScanReport.project_model=unknown，未产出适配分类。');
    process.exit(EXIT_MODEL);
  } else if (degraded) {
    console.log('完成（SDK 未检出，单源判定，已在报告标注）: scan-report.json + migration-advice.md');
  } else {
    console.log(`完成（SDK: ${sdkInfo.path}，确认途径 ${sdkInfo.origin}）: scan-report.json + migration-advice.md`);
  }
  process.exit(EXIT_OK);
}

main(process.argv.slice(2)).catch((err) => {
  console.error(`内部错误: ${err.message}`);
  process.exit(EXIT_INTERNAL);
});
