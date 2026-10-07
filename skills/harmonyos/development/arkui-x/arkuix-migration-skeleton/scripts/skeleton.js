#!/usr/bin/env node
import { existsSync, mkdirSync, writeFileSync, renameSync, readFileSync } from 'node:fs';
import { join, relative, resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import readline from 'node:readline/promises';
import { loadReport, check, rejectMessage } from './model-gate.js';
import { detectEnvironment } from './env-detector.js';
import { preflight, invokeModify, resolveTimeoutMs, collectAceWarnings } from './ace-invoker.js';
import { checkOutputDir, decideOnNonEmpty, createScaffold, scaffoldPresent, resolveShells, materializeFromArchive } from './scaffold.js';
import { migrateSources, verifyMigration } from './migrate.js';
import { snapshotProject, diffSnapshots } from './snapdiff.js';
import { renderJson, renderMarkdown, renderVerificationAssists } from './result.js';

/** CLI 退出码映射（spec CLI-1，v1.1 固化，跨版本稳定） */
const EXIT_OK = 0;        // 正常结束：完成产出；或用户跳过（不产出，stdout 明示）
const EXIT_INTERNAL = 1;  // 内部错误：未预期异常
const EXIT_USAGE = 2;     // 输入无效：根目录不存在/不可读、参数非法值（含非交互模式/平台非法值）
const EXIT_MODEL = 3;     // 模型拒绝：project_model=fa / ScanReport 缺失不可解析 unknown
const EXIT_ENV = 4;       // 环境不满足：SDK < API 24 且模式=modify（R-1 边界）
const EXIT_TOOL = 5;      // 工具失败：ace tool 非零退出或超时（R-5）
const EXIT_ABORT = 6;     // 用户中止：交互无效输入连续/流结束、覆盖确认中止、计划确认未 --yes

const PLATFORMS = ['both', 'android', 'ios'];
const MAX_INVALID_ATTEMPTS = 3;

function usage() {
  return [
    '用法: node scripts/skeleton.js <工程根目录> --scan-report <F2 scan-report.json> [选项]',
    '',
    '  <工程根目录>                 Stage 工程根目录（必填）',
    '  --scan-report <路径>         F2 ScanReport 路径（必填，project_model 判定输入）',
    '  --mode <modify|new>          骨架生成模式（未指定时交互引导，默认建议 modify；非交互必填）',
    '  --platform <both|android|ios> 平台选项（默认 both；未指定时交互引导）',
    '  --out <目录>                 输出目录（new 模式 scaffold 落点；默认 <工程根>/arkuix-skeleton-output）',
    '  --confirm-overwrite <skip|overwrite|abort> 输出目录非空确认（非交互等价参数；非 TTY 缺省 abort）',
    '  --yes                        跳过 modify 计划改动清单确认（非 TTY 无则按用户中止，退出码 6）',
    '  --ace-bin <路径>             ace 命令路径（默认 PATH 中的 ace）',
    '  --timeout-ms <毫秒>          ace 子进程超时阈值（默认 300000；环境变量 ARKUIX_ACE_TIMEOUT_MS 可覆盖）',
    '',
    '退出码: 0=完成/跳过; 1=内部错误; 2=输入无效; 3=模型拒绝; 4=环境不满足(SDK<API24+modify); 5=工具失败; 6=用户中止'
  ].join('\n');
}

function parseArgs(argv) {
  const opts = {
    root: null, scanReport: null, mode: null, platform: null, out: null,
    confirmOverwrite: null, yes: false, aceBin: null, timeoutMs: null
  };
  const positional = [];
  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i];
    if (arg === '--scan-report') opts.scanReport = argv[++i];
    else if (arg === '--mode') opts.mode = argv[++i];
    else if (arg === '--platform') opts.platform = argv[++i];
    else if (arg === '--out') opts.out = argv[++i];
    else if (arg === '--confirm-overwrite') opts.confirmOverwrite = argv[++i];
    else if (arg === '--yes') opts.yes = true;
    else if (arg === '--ace-bin') opts.aceBin = argv[++i];
    else if (arg === '--scaffold-from') {
      const next = argv[i + 1];
      if (next && !next.startsWith('--')) opts.scaffoldFrom = argv[++i];
      else opts.scaffoldFrom = true; // 无值 → 内置归档 assets/scaffold-26.0.0
    }
    else if (arg === '--project-name') opts.projectName = argv[++i];
    else if (arg === '--bundle-name') opts.bundleName = argv[++i];
    else if (arg === '--timeout-ms') {
      const value = Number(argv[++i]);
      if (!Number.isInteger(value) || value <= 0) {
        console.error(`错误: --timeout-ms 须为正整数毫秒，收到 ${argv[i]}`);
        process.exit(EXIT_USAGE);
      }
      opts.timeoutMs = value;
    }
    else if (arg === '-h' || arg === '--help') { console.log(usage()); process.exit(EXIT_OK); }
    else positional.push(arg);
  }
  opts.root = positional[0] || null;
  if (opts.mode && !['modify', 'new'].includes(opts.mode)) {
    console.error(`错误: --mode 仅支持 modify/new，收到 ${opts.mode}`);
    process.exit(EXIT_USAGE);
  }
  if (opts.platform && !PLATFORMS.includes(opts.platform)) {
    console.error(`错误: --platform 仅支持 both/android/ios，收到 ${opts.platform}`);
    process.exit(EXIT_USAGE);
  }
  if (opts.confirmOverwrite && !['skip', 'overwrite', 'abort'].includes(opts.confirmOverwrite)) {
    console.error(`错误: --confirm-overwrite 仅支持 skip/overwrite/abort，收到 ${opts.confirmOverwrite}`);
    process.exit(EXIT_USAGE);
  }
  return opts;
}

/** SD18：迁入后回写 build-profile 注册各模块（宽松 JSON5 解析 + 保序写入） */
function registerModules(outDir, modules) {
  if (!modules || modules.length === 0) return;
  const bpPath = join(outDir, 'build-profile.json5');
  if (!existsSync(bpPath)) {
    // scaffold 未自带 build-profile（mock 或旧版 ace）→ 创建基础骨架并注册全部模块
    const skeleton = { app: { products: [{ name: 'default' }] },
      modules: modules.map((m) => ({ name: m.name, srcPath: `./${m.name}` })) };
    atomicWrite(bpPath, JSON.stringify(skeleton, null, 2) + '\n');
    console.log(`SD18: 已创建 build-profile.json5 并注册 ${modules.length} 个迁入模块`);
    return;
  }
  try {
    const doc = JSON.parse(looseParseBuildProfile(readFileSync(bpPath, 'utf8')));
    const existing = new Set((doc.modules ?? []).map((m) => m.srcPath));
    // SD35（E2E-6 实测）：新增清单与计数同源（原 added 计数与括号内全量模块名错乱）；
    // 注册项补 targets（与 scaffold 自带 entry 形态对称，业务名模块此前缺该字段）
    const added = [];
    for (const mod of modules) {
      const srcPath = `./${mod.name}`;
      if (!existing.has(srcPath)) {
        (doc.modules ??= []).push({ name: mod.name, srcPath,
          targets: [{ name: 'default', applyToProducts: ['default'] }] });
        added.push(mod.name);
      }
    }
    if (added.length > 0) {
      atomicWrite(bpPath, JSON.stringify(doc, null, 2) + '\n');
      console.log(`SD18: build-profile.json5 已注册 ${added.length} 个迁入模块（${added.join('、')}）`);
    }
  } catch (err) {
    console.error(`警告: build-profile 注册回写失败（${err.message}）——产出工程需手动注册各模块`);
  }
}

/** 宽松解析（复用 migrate.js 同思路：剥注释+无引号键+尾逗号） */
function looseParseBuildProfile(text) {
  return text
    .replace(/\/\*[\s\S]*?\*\//g, '')   // 块注释
    .replace(/\/\/.*$/gm, '')            // 行注释
    .replace(/([{,]\s*)([A-Za-z_$][A-Za-z0-9_$]*)(\s*:)/g, '$1"$2"$3')
    .replace(/'([^'\\]*)'/g, '"$1"')
    .replace(/,(\s*[}\]])/g, '$1');
}

function atomicWrite(file, content) {
  const tmp = `${file}.tmp-${process.pid}`;
  writeFileSync(tmp, content, 'utf8');
  renameSync(tmp, file);
}

/** 交互询问循环骨架：无效应答提示并重新询问，连续 MAX_INVALID_ATTEMPTS 次或流结束 → 用户中止（码 6） */
async function askLoop(rl, question, normalize) {
  let invalid = 0;
  for (;;) {
    let answer;
    try {
      answer = await rl.question(question);
    } catch {
      return { aborted: true, reason: '输入流结束' };
    }
    if (answer === null) return { aborted: true, reason: '输入流结束' };
    const decision = normalize(answer);
    if (decision === 'abort') return { aborted: true, reason: '用户选择中止' };
    if (decision === null) {
      invalid += 1;
      if (invalid >= MAX_INVALID_ATTEMPTS) {
        return { aborted: true, reason: `连续 ${MAX_INVALID_ATTEMPTS} 次无效输入` };
      }
      console.log('输入无效，请按提示重新输入。');
      continue;
    }
    return { value: decision };
  }
}

async function resolveMode(opts) {
  if (opts.mode) return opts.mode;
  if (opts.yes) return 'modify'; // F1-Q1：默认建议 modify（改动小）
  if (!process.stdin.isTTY) {
    console.error('未指定 --mode 且当前为非交互环境；请显式指定 --mode modify 或 --mode new（默认建议 modify，改动小）。');
    process.exit(EXIT_USAGE);
  }
  const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
  try {
    const result = await askLoop(rl,
      '选择骨架生成模式 [M=modify（默认建议，就地改造原工程）/ n=new（新建 scaffold 迁入源码）] ',
      (answer) => {
        const a = answer.trim().toLowerCase();
        if (a === '' || a === 'm') return 'modify';
        if (a === 'n') return 'new';
        if (a === 'q') return 'abort';
        return null;
      });
    if (result.aborted) {
      console.error(`用户中止（${result.reason}）：未开始任何生成动作，零写操作。`);
      process.exit(EXIT_ABORT);
    }
    return result.value;
  } finally {
    rl.close();
  }
}

/** v1.1 平台选项引导（默认 both；非交互缺省 both） */
async function resolvePlatform(opts) {
  if (opts.platform) return opts.platform;
  if (!process.stdin.isTTY) return 'both';
  const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
  try {
    const result = await askLoop(rl,
      '选择平台选项 [B=双平台（默认） / a=仅 Android / i=仅 iOS] ',
      (answer) => {
        const a = answer.trim().toLowerCase();
        if (a === '' || a === 'b') return 'both';
        if (a === 'a') return 'android';
        if (a === 'i') return 'ios';
        if (a === 'q') return 'abort';
        return null;
      });
    if (result.aborted) {
      console.error(`用户中止（${result.reason}）：未开始任何生成动作，零写操作。`);
      process.exit(EXIT_ABORT);
    }
    return result.value;
  } finally {
    rl.close();
  }
}

/** R-4：modify 计划改动清单确认（TTY 交互；非 TTY 需 --yes，无则按用户中止，码 6） */
async function confirmPlanChanges(plan, opts) {
  console.log('将以 modify 模式执行以下改动（执行前确认）：');
  for (const line of plan) console.log(`  - ${line}`);
  if (opts.yes) {
    console.log('（--yes：跳过确认）');
    return;
  }
  if (!process.stdin.isTTY) {
    console.error('非交互环境执行 modify 需 --yes 跳过计划改动清单确认（未提供则按用户中止，退出码 6）。');
    process.exit(EXIT_ABORT);
  }
  const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
  try {
    const result = await askLoop(rl, '确认执行以上改动？[Y=继续 / q=中止] ', (answer) => {
      const a = answer.trim().toLowerCase();
      if (a === '' || a === 'y') return 'go';
      if (a === 'q' || a === 'n') return 'abort';
      return null;
    });
    if (result.aborted) {
      console.error(`用户中止（${result.reason}）：零写操作。`);
      process.exit(EXIT_ABORT);
    }
  } finally {
    rl.close();
  }
}

/**
 * SD31：F2 分类结果逐桶确认（风险序 unknown→①；TTY 逐桶 y/a/n；非 TTY 需 --yes）。
 * 每非空桶展示计数 + Top3 条目摘要；y=确认本桶 / a=剩余全部确认 / n|q=中止（码 6，零写）。
 */
const BUCKET_RISK_ORDER = [
  ['unknown', '⑦ unknown（待人工确认）'],
  ['business_decision', '⑥ 业务决策（business_decision）'],
  ['reduced_direct', '② 有损直用（reduced_direct）'],
  ['degraded_bridge', '④ 降级桥接（degraded_bridge）'],
  ['equivalent_bridge', '③ 等价桥接（equivalent_bridge）'],
  ['platform_trim', '⑤ 平台裁剪（platform_trim）'],
  ['full_direct', '① 完整直用（full_direct）']
];

export async function confirmScanBuckets(doc, scanReportPath, opts = {}, io = {}) {
  const adaptation = (doc && doc.adaptation) || {};
  const advicePath = String(scanReportPath || '').replace(/scan-report\.json$/, 'migration-advice.md');
  const counts = BUCKET_RISK_ORDER.map(([b]) => (adaptation[b] || []).length);
  console.log('── F2 扫描结果确认 ──');
  console.log(BUCKET_RISK_ORDER.map(([b, label], i) => `${label} ${counts[i]}`).join(' | '));
  if (advicePath) console.log(`完整清单: ${advicePath}`);

  if (opts.yes) {
    console.log('（--yes：跳过逐桶确认）');
    return 'ok';
  }
  const isTTY = io.isTTY !== undefined ? io.isTTY : process.stdin.isTTY;
  if (!isTTY) {
    // SD31 交互序修正：非 TTY 未确认（--yes）→ 零产出退出（与 SD32 SDK 确认同款强制）——
    // agent 须将 migration-advice.md 分类结论呈报用户确认后带 --yes 重跑；分类是迁移决策的根基，不可默默继续。
    // 方案1（呈报块）：随退出输出预格式化逐桶呈报材料，agent 应整块转述（逐桶读给用户/贴给用户）后收集确认
    console.error('F2 分类结果未经确认（非交互环境）。请将以下呈报块完整转述给用户确认'
      + '（逐桶读出/粘贴，收集确认或异议），确认后以 --yes 重跑本命令；TTY 环境将逐桶交互确认。未确认不执行任何生成动作。');
    console.error('\n===== F2 分类结果呈报块（风险序，请逐桶向用户确认）=====');
    for (const [bucket, label] of BUCKET_RISK_ORDER) {
      const items = (adaptation[bucket] || []);
      console.error(`\n【${label}】共 ${items.length} 条`);
      for (const it of items.slice(0, 3)) {
        console.error(`  - ${it.module} → ${it.symbol}：${String(it.reason || '').slice(0, 60)}`);
      }
      if (items.length > 3) console.error(`  - ……其余 ${items.length - 3} 条见 ${advicePath || 'migration-advice.md'}`);
      if (items.length === 0) console.error('  （空）');
    }
    console.error('\n===== 呈报块结束 =====');
    process.exit(EXIT_ABORT);
  }
  const rl = io.readline || readline.createInterface({ input: process.stdin, output: process.stdout });
  try {
    let total = 0;
    for (let i = 0; i < BUCKET_RISK_ORDER.length; i++) {
      const [bucket, label] = BUCKET_RISK_ORDER[i];
      const items = adaptation[bucket] || [];
      if (items.length === 0) continue;
      total += 1;
      console.log(`\n（${total}）${label}，共 ${items.length} 条，示例：`);
      for (const it of items.slice(0, 3)) {
        const reason = String(it.reason || '').slice(0, 48);
        console.log(`    ${it.module} → ${it.symbol}   ${reason}`);
      }
      if (items.length > 3) console.log(`    …等 ${items.length - 3} 条见完整清单`);
      const result = await askLoop(rl, '本桶确认? [y=确认 / a=剩余全部确认 / n=中止复核] ', (answer) => {
        const a = answer.trim().toLowerCase();
        if (a === '' || a === 'y') return 'yes';
        if (a === 'a') return 'all';
        if (a === 'n' || a === 'q') return 'abort';
        return null;
      });
      if (result.aborted) {
        console.error(`用户中止（${result.reason}）：请复核 ${advicePath || 'F2 报告'} 后重跑本命令。零写操作。`);
        process.exit(EXIT_ABORT);
      }
      if (result.value === 'all') {
        console.log('（剩余桶全部确认）');
        return 'ok';
      }
    }
    return 'ok';
  } finally {
    rl.close();
  }
}

/** R-7：非空目录确认（跳过/覆盖/中止）；确认前零产出。跳过=退出码 0（stdout 明示）；中止=码 6 */async function confirmNonEmpty(outDir, opts) {
  const state = checkOutputDir(outDir);
  if (!state.exists || !state.nonEmpty) return 'overwrite';
  if (opts.confirmOverwrite) return opts.confirmOverwrite;
  if (opts.yes) return 'overwrite';
  if (!process.stdin.isTTY) {
    console.error(`输出目录已存在且非空: ${outDir}；非交互环境缺省按中止处理（可使用 --confirm-overwrite overwrite/skip 或 --yes）。`);
    return 'abort';
  }
  const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
  try {
    const result = await askLoop(rl,
      `输出目录已存在且非空: ${outDir}\n选择策略 [s=跳过(零变更结束) / y=覆盖 / q=中止] `,
      (answer) => decideOnNonEmpty(answer));
    if (result.aborted) {
      console.error(`用户中止（${result.reason}）：确认前未产出任何新文件。`);
      process.exit(EXIT_ABORT);
    }
    return result.value;
  } finally {
    rl.close();
  }
}

async function main(argv) {
  const opts = parseArgs(argv);
  if (!opts.root || !opts.scanReport) {
    console.error(usage());
    process.exit(EXIT_USAGE);
  }
  const root = resolve(opts.root);
  if (!existsSync(root)) {
    console.error(`错误: 工程根目录不存在: ${root}`);
    process.exit(EXIT_USAGE);
  }
  // ScanReport 存在性/可解析性由 ModelGate 统一判定（R-9：缺失也走引导 F2 路径）

  // R-8/R-9：模型前置（INV-1——任何写操作之前；退出码 3）
  const scanReport = loadReport(resolve(opts.scanReport));
  const gate = check(scanReport);
  if (gate.verdict !== 'pass') {
    console.error(rejectMessage(gate));
    process.exit(EXIT_MODEL);
  }

  // R-1/R-2：环境检测（不阻断；arkui_x_sdk 检出供 modify 门槛判定）
  const environment = detectEnvironment(opts.aceBin ? { aceBin: opts.aceBin } : {});

  // 参数硬校验（先于任何交互/确认）：非 TTY 缺 --mode（且无 --yes 缺省豁免）→ 码 2（VM-13 语义保持）
  if (!opts.mode && !opts.yes && !process.stdin.isTTY) {
    console.error('未指定 --mode 且当前为非交互环境；请显式指定 --mode modify 或 --mode new（默认建议 modify，改动小）。');
    process.exit(EXIT_USAGE);
  }

  // SD31（交互序修正，用户反馈）：F2 分类结果逐桶确认——必须在骨架生成方式（mode/platform）询问**之前**，
  // 正确决策链 = SDK 确认（F2）→ 分类确认 → 骨架生成方式 → 执行；非 TTY 未确认（--yes）即停（与 SD32 同款强制）
  await confirmScanBuckets(scanReport.doc, resolve(opts.scanReport), opts);

  // 交互定序（v1.1）：模式 → 平台 →（new）目录确认 → 生成
  const mode = await resolveMode(opts);
  const platform = await resolvePlatform(opts);

  // SD8（r3）：幂等重跑前置——已 modify 工程无需 ace（先于 SDK 门槛判定）
  const alreadyModifiedPre = mode === 'modify' && existsSync(join(root, '.arkui-x', 'arkui-x-config.json5'));

  // R-1 边界：modify_available=false 且模式=modify → 拒绝（码 4，零写）；幂等重跑豁免（不调用 ace）
  if (mode === 'modify' && !alreadyModifiedPre && !environment.arkui_x_sdk.modify_available) {
    const detected = environment.arkui_x_sdk.detected
      ? `检出版本 ${environment.arkui_x_sdk.version || '未知'}`
      : '未检出 ArkUI-X SDK（ace tool 不在 PATH）';
    console.error(`ArkUI-X SDK 版本低于 API 24，ace modify 不可用（${detected}）。建议：升级 ArkUI-X SDK 至 API 24+，或改用 new 模式（--mode new）。`);
    process.exit(EXIT_ENV);
  }

  // SD33（A）：缺省输出目录锚定工程根（原 CWD 漂移——产物散落且曾误入 git）
  const outDir = resolve(opts.out || join(root, 'arkuix-skeleton-output'));
  // SD33（B）：modify 报告覆盖警示（new 模式的目录确认由 R-7 confirmNonEmpty 管）
  if (mode === 'modify' && existsSync(join(outDir, 'skeleton-result.json'))) {
    console.log(`提示: 输出目录已有上次产物，本次将覆盖（${outDir}）；如需保留请 --out 指定新目录。`);
  }
  const timeoutMs = resolveTimeoutMs(opts.timeoutMs);

  let artifacts;
  let migration = null;
  let changedFiles = [];
  let aceWarnings = []; // SD26（r7）：ace WARN 级提示沉淀（report/result，编译前必办）
  let resultBaseDir = root; // 壳相对路径基准（modify=工程根；new=输出目录）

  if (mode === 'modify') {
    // 前置：工程完整性（design 代码事实 3）
    const pf = preflight(root);
    if (!pf.ok) {
      console.error(`工程不完整（缺 ${pf.missing.join('、')}），ace modify 将拒绝执行；请补全 Stage 工程构建配置后重试，或改用 --mode new。`);
      process.exit(EXIT_USAGE);
    }
    // SD8（r3）：幂等重跑——.arkui-x/arkui-x-config.json5 在场 = 已 modify，跳过 ace 调用
    // （同时消除实测发现的"已 modify 工程重跑挂起"触发路径）
    const alreadyModified = alreadyModifiedPre;
    if (alreadyModified) {
      console.log('检测到工程已 modify（.arkui-x/arkui-x-config.json5 在场），跳过 ace 调用（幂等重跑）。');
      const shells = resolveShells(root);
      const wantAndroid = platform === 'both' || platform === 'android';
      const wantIos = platform === 'both' || platform === 'ios';
      if ((wantAndroid && !existsSync(shells.android)) || (wantIos && !existsSync(shells.ios))) {
        console.error(`已 modify 工程缺少所选平台壳（platform=${platform}）；如需补齐请先移除 .arkui-x/ 后重跑。`);
        process.exit(EXIT_TOOL);
      }
      // SD26：幂等路径无 ace stdout → 静态复核已知必办项（build-profile 含 useNormalizedOHMUrl 即补）
      aceWarnings = collectAceWarnings('', '', root);
    } else {
      // Scope Guard：modify 执行前明示计划改动清单并确认（R-4）
      const platformLabel = { both: '双平台（Default(Android, iOS)，应答 1）', android: '仅 Android（应答 2）', ios: '仅 iOS（应答 3）' }[platform];
      const plannedDirs = platform === 'both' ? '.arkui-x/android/ 与 .arkui-x/ios/' : (platform === 'android' ? '.arkui-x/android/' : '.arkui-x/ios/');
      await confirmPlanChanges([
        `调用 ace modify --project（平台选项: ${platformLabel}）`,
        `在原工程注入 ${plannedDirs}（官方模板展开与工程配置注入项；可能改写既有构建配置文件）`,
        '原工程结构与 entry 源码保留（就地改造，不做源码内容改写）'
      ], opts);
      const snapBefore = snapshotProject(root); // SD9：全工程前后快照 diff
      const invocation = invokeModify(root, { aceBin: opts.aceBin, timeoutMs, platform });
      changedFiles = diffSnapshots(snapBefore, snapshotProject(root));
      if (!invocation.ok) {
        console.error(`失败：${invocation.reason}`);
        if (changedFiles.length) {
          console.error(`实际改动文件清单（保留供排查，不自动回滚；建议以工程版本控制还原）：\n${changedFiles.map((f) => `  - ${f}`).join('\n')}`);
        }
        console.error('建议改用 new 模式（--mode new：新建跨平台空工程后迁入源码）。');
    console.error(`
┌─ 下一步建议 ─────────────────────────────────────┐
│ A. 在 TTY 终端重跑本命令（多模块时自动透传交互）        │
│ B. 改用 new 模式：                                     │
│    node scripts/skeleton.js <工程> --scan-report <F2产物> --mode new --yes │
│ C. 手动执行 ace 后重跑（幂等跳过 ace 调用）：            │
│    ace modify --project  （在工程根目录下执行）           │
└─────────────────────────────────────────────────┘`);
        process.exit(EXIT_TOOL);
      }
      if (changedFiles.length) {
        console.log(`实际改动文件清单（+ 新增 / ~ 改写 / - 删除）：\n${changedFiles.map((f) => `  - ${f}`).join('\n')}`);
      }
      // SD26（r7）：成功路径沉淀 ace WARN（stdout 提取 + 静态复核兜底）
      aceWarnings = collectAceWarnings(invocation.stdout, invocation.stderr, root);
    }
    artifacts = {
      androidShell: '.arkui-x/android',
      iosShell: '.arkui-x/ios',
      sharedArktsDir: existsSync(join(root, 'entry')) ? 'entry' : '.'
    };
  } else {
    // R-7：非空确认（跳过=退出码 0；中止=码 6）
    const decision = await confirmNonEmpty(outDir, opts);
    if (decision === 'skip') {
      console.log('已跳过本次骨架生成');
      process.exit(EXIT_OK);
    }
    if (decision === 'abort') {
      console.error('用户中止：确认前未产出任何新文件。');
      process.exit(EXIT_ABORT);
    }
    // SD28 根治：--scaffold-from 归档物化（零交互、确定性）优先于 ace create
    const archiveDir = opts.scaffoldFrom === true ? join(dirname(fileURLToPath(import.meta.url)), '..', 'assets', 'scaffold-26.0.0') : opts.scaffoldFrom;
    let scaffold;
    if (archiveDir) {
      // SDK 路径推断：aceBin 形如 .../<ver>/arkui-x/toolchains/bin/ace → .../<ver>/arkui-x
      const aceBinPath = opts.aceBin && opts.aceBin !== 'ace' ? opts.aceBin : '';
      const sdkPath = aceBinPath ? resolve(aceBinPath, '..', '..', '..') : '';
      scaffold = materializeFromArchive(archiveDir, outDir, {
        name: opts.projectName, bundle: opts.bundleName, platform,
        arkuiXSdkPath: environment.arkui_x_sdk.detected ? sdkPath : ''
      });
      if (!scaffold.ok) {
        console.error(`失败：${scaffold.reason}`);
        process.exit(EXIT_TOOL);
      }
      console.log(`已从归档 scaffold 物化（零交互，SDK 26.0.0 固定）：${archiveDir}`);
      for (const note of scaffold.envNote || []) console.log(`标注：${note}`);
    } else {
      scaffold = createScaffold(outDir, { aceBin: opts.aceBin, timeoutMs, platform });
    }
    if (!scaffold.ok) {
      console.error(`失败：${scaffold.reason}`);
      
    console.error(`
┌─ 下一步建议 ─────────────────────────────────────┐
│ A. 在 TTY 终端运行本命令（自动透传 ace 交互）            │
│ B. 手动执行 ace create 后重跑本命令（跳过 create）：     │
│    ${opts.aceBin || 'ace'} create ${outDir} -t app           │
│    建议答案：默认/默认/1(OpenHarmony)/16(最大项SDK)/1(双平台)/2(CocoaPods) │
│ C. 改用 modify 模式（如工程构建配置完整）                │
└─────────────────────────────────────────────────┘`);
      process.exit(EXIT_TOOL);
    }
    if (scaffold.skippedCreate) {
      console.log('检测到 scaffold 已在场（.arkui-x/ 或双壳目录），跳过 ace create，直接执行源码迁入（官方回退路径）。');
    }
    migration = migrateSources(root, outDir);
    if (!migration.ok) {
      // SD5（r3）：零迁入显式失败（退出码 2）——修复静默伪成功
      console.error(`迁入失败：${migration.reason}`);
      
    console.error(`
┌─ 下一步建议 ─────────────────────────────────────┐
│ 迁入失败常见原因：                                       │
│ · build-profile.json5 的 modules[].srcPath 指向无效目录   │
│ · 工程无可迁入源码（各模块 src/main 下为空）              │
│ 请检查后重跑，或改用 modify 模式就地改造。                 │
└─────────────────────────────────────────────────┘`);
      process.exit(EXIT_USAGE);
    }
    const verification = verifyMigration(root, outDir, migration);
    if (!verification.ok) {
      console.error(`迁入完整性校验失败：${verification.reason}`);
      process.exit(EXIT_INTERNAL);
    }
    // SD18（统一轮立案）：迁入后回写 build-profile 注册各模块——否则产出仅能构建 scaffold 自带的 Hello World
    registerModules(outDir, migration.modules);
    resultBaseDir = outDir;
    // SD3（r3）：壳路径按真实布局归一（.arkui-x/ 优先；legacy 顶层兼容 mock/旧 ace）
    const legacyLayout = scaffold.legacy === true;
    artifacts = {
      androidShell: legacyLayout ? 'android' : '.arkui-x/android',
      iosShell: legacyLayout ? 'ios' : '.arkui-x/ios',
      sharedArktsDir: relative(outDir, scaffold.sharedArktsDir) || '.',
      // SD24：如实描述各模块实际落点（entry→entry/，业务名→<模块名>/）
      migratedModules: (migration.modules ?? []).map((m) => ({ name: m.name, target: m.target ?? m.name, files: m.files }))
    };
  }

  // SKRS-1 产物 + 报告 + 验证辅助（壳路径为相对路径，基准=resultBaseDir）
  const skeletonResult = {
    schema_version: 1,
    mode,
    platform,
    android_shell: artifacts.androidShell,
    ios_shell: artifacts.iosShell,
    shared_arkts_dir: artifacts.sharedArktsDir,
    // SD25（r6）：artifacts.migratedModules 透传至 JSON 契约（modify 分支无值→条件省略）
    migrated_modules: artifacts.migratedModules,
    // SD26（r7）：ace WARN 级提示沉淀（编译前必办；无→条件省略）
    ace_warnings: aceWarnings,
    environment
  };
  mkdirSync(outDir, { recursive: true });
  atomicWrite(join(outDir, 'skeleton-result.json'), renderJson(skeletonResult));
  atomicWrite(join(outDir, 'migration-skeleton-report.md'),
    renderMarkdown(skeletonResult, { migration, changedFiles, aceWarnings }));

  // R-3：编译验证辅助（就绪且所选平台生成；不直接执行）
  const assists = renderVerificationAssists(skeletonResult, resultBaseDir);
  for (const [relPath, content] of Object.entries(assists)) {
    const file = join(outDir, relPath);
    mkdirSync(join(file, '..'), { recursive: true });
    atomicWrite(file, content);
  }

  const envNote = [];
  if (platform !== 'ios' && !environment.android.ready) envNote.push('Android 环境未就绪，需在对应环境补验');
  if (platform !== 'android' && !environment.ios.ready) envNote.push('iOS 环境未就绪，需在对应环境补验');
  console.log(`完成（mode=${mode}，platform=${platform}）：skeleton-result.json + migration-skeleton-report.md（${outDir}）`);
  if (envNote.length) console.log(`标注：${envNote.join('；')}（骨架已按所选平台生成，不受影响）`);
  process.exit(EXIT_OK);
}

// 入口守卫（SD31）：仅直接执行时跑主流程，import（单测取 confirmScanBuckets 等）不触发
if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  main(process.argv.slice(2)).catch((err) => {
    console.error(`内部错误: ${err.message}`);
    process.exit(EXIT_INTERNAL);
  });
}
