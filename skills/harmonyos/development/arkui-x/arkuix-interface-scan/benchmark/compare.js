#!/usr/bin/env node
/**
 * 全量验收（TASK-5 + 跟进轮 TASK-6~10，VM-1~VM-16 对应入口）：
 * 1. Stage fixture 端到端（mini-sdk 双源 + C-API/动态加载/单平台占比）→ expected-metrics 逐项比对
 * 2. FA fixture → project_model=fa + 空分类 + 目录零变更快照 + 退出码 3（模型不支持，产物照常写出）
 * 3. 空目录 → project_model=unknown + 退出码 3
 * 4. 降级路径（--no-sdk 与非 TTY 自动降级）→ 单源采信 + 报告标注 + scan-report 无 sdk 字段 + 退出码 0
 * 5. 3 次一致性（INV-3 / AC-4.3）
 * 6. VM-16 demo 采样 → unknown 占比 ≤20% 且逐项归因
 * 7. 离线静态检查（AC-4.2：交付物零网络 API 引用）
 */
import { spawnSync } from 'node:child_process';
import { readFileSync, readdirSync, statSync, existsSync, rmSync, mkdirSync, mkdtempSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { fileURLToPath } from 'node:url';
import { dirname, join, relative } from 'node:path';
import { tmpdir, homedir } from 'node:os';

const ROOT = dirname(dirname(fileURLToPath(import.meta.url)));
const BENCH = join(ROOT, 'benchmark');
const SCAN = join(ROOT, 'scripts', 'scan.js');
const expected = JSON.parse(readFileSync(join(BENCH, 'expected-metrics.json'), 'utf8'));

let failures = 0;
function check(ok, label, detail = '') {
  const mark = ok ? '✔' : '✖';
  console.log(`${mark} ${label}${detail && !ok ? ` — ${detail}` : ''}`);
  if (!ok) failures++;
}

function runScan(args) {
  const result = spawnSync(process.execPath, [SCAN, ...args], {
    encoding: 'utf8',
    env: { ...process.env, OH_SDK_DIR: '', OHOS_SDK_HOME: '', DEVECO_SDK_HOME: '' }
  });
  return result;
}

function readReport(outDir) {
  return JSON.parse(readFileSync(join(outDir, 'scan-report.json'), 'utf8'));
}

function itemOf(report, bucket, key) {
  return report.adaptation[bucket].find((i) => `${i.module}#${i.symbol}` === key);
}

// ── 1. Stage 端到端（双源 + C-API/动态加载/单平台） ────────────────────
const stageOut = join(BENCH, '.tmp-out-stage');
rmSync(stageOut, { recursive: true, force: true });
const stageRun = runScan([
  join(BENCH, 'fixture-stage-project'),
  '--out', stageOut,
  '--sdk-dir', join(BENCH, 'mini-sdk')
]);
check(stageRun.status === 0, 'VM-1/VM-3: Stage 端到端退出码 0', `stderr: ${stageRun.stderr}`);
const stageReport = readReport(stageOut);
check(stageReport.project_model === 'stage', 'VM-1: project_model=stage');
check(stageReport.inventory.length === expected.stage.inventory_count,
  `VM-1: inventory 覆盖完整（${expected.stage.inventory_count}，含 C-API 与 dlopen 字面量）`, `实际 ${stageReport.inventory.length}`);
check(stageReport.sdk && stageReport.sdk.confirmed === true, 'VM-10/AC-2.9: sdk 字段记录且 confirmed');

const ndkItems = stageReport.inventory.filter((i) => i.source === 'ndk');
check(ndkItems.length === 9, 'VM-1: Native 引用计入 inventory（9 项：3 include + 5 OH_* + 1 dlopen）', `实际 ${ndkItems.length}`);
check(stageReport.inventory.some((i) => i.module === 'libblend.z.so' && i.symbol === '*dlopen*'),
  'VM-1: dlopen 字面量 .so 库名计入（module=so 库名）');

for (const [key, exp] of Object.entries(expected.stage.items)) {
  const item = itemOf(stageReport, exp.bucket, key);
  check(item !== undefined, `VM-3: ${key} → ${exp.bucket}`, `未找到于 ${exp.bucket}`);
  if (!item) continue;
  if (exp.occurrences !== undefined) {
    check(item.occurrences === exp.occurrences, `VM-5: ${key} occurrences=${exp.occurrences}`, `实际 ${item.occurrences}`);
  }
  if (exp.reason_contains) {
    check(item.reason.includes(exp.reason_contains), `VM-3: ${key} reason 含「${exp.reason_contains}」`, item.reason);
  }
  if (exp.suggested_alternative_contains) {
    check(item.suggested_alternative.includes(exp.suggested_alternative_contains),
      `VM-8: ${key} 替代建议含「${exp.suggested_alternative_contains}」`, item.suggested_alternative);
  }
}
{
  const ndkSources = new Set();
  for (const items of Object.values(stageReport.adaptation)) {
    for (const item of items) ndkSources.add(item.source);
  }
  check(ndkSources.has('ndk'), 'VM-3/VM-10: adaptation 含 source=ndk 项（C-API 判定）');
}

// 桶互斥总检（INV-1）
{
  const seen = new Map();
  let dup = null;
  for (const [bucket, items] of Object.entries(stageReport.adaptation)) {
    for (const item of items) {
      const key = `${item.module}#${item.symbol}`;
      if (seen.has(key)) dup = `${key}: ${seen.get(key)} + ${bucket}`;
      seen.set(key, bucket);
    }
  }
  check(dup === null, 'INV-1/VM-3: 桶互斥（无重复接口）', dup || '');
}

// Markdown 报告结构（VM-9 + 动态加载提示 + 单平台占比）
{
  const md = readFileSync(join(stageOut, 'migration-advice.md'), 'utf8');
  check(md.includes('③ 等价桥接（equivalent_bridge）— 将由 F3 生成桥接'), 'VM-9: ③ 标注 F3 桥接');
  // RD6（v1.6.1）：vibrator 升 full_direct 后 fixture 无 degraded_bridge 条目 → ④ 段不再渲染（有则校验）
  if (md.includes('④ 降级桥接')) {
    check(md.includes('④ 降级桥接（degraded_bridge）— 将由 F3 生成桥接'), 'VM-9: ④ 标注 F3 桥接');
  }
  check(md.includes('unknown — 待人工确认'), 'VM-9: unknown 待确认清单');
  check(md.includes('存在不可静态解析的动态加载'), 'VM-9/AC-1.1: 动态加载提示在场（R-1）');
  check(md.includes('（dynamic import）') && md.includes('（dlopen）'), 'VM-9: 动态加载提示含两类位置');
  check(md.includes(`单平台支持接口占比：${expected.stage.platform_ratio}`), 'VM-9/AC-3.1: 单平台支持接口占比统计节', `期望 ${expected.stage.platform_ratio}`);
  check(/\| ohos \|/.test(md) && /\| ndk \|/.test(md), 'VM-9: 来源列含 ohos/ndk 展示（v1.2）');
  check(!/function publish|struct Index|build\(\)/.test(md), 'INV-2/VM-11: 报告零源码正文');
}

// ── 2. FA fixture（R-2 + 零写快照 + 退出码 3） ─────────────────────────
{
  const faRoot = join(BENCH, 'fixture-fa-project');
  const before = snapshotDir(faRoot);
  const faOut = join(BENCH, '.tmp-out-fa');
  rmSync(faOut, { recursive: true, force: true });
  const faRun = runScan([faRoot, '--out', faOut]);
  check(faRun.status === expected.fa.exit_code, `VM-2/CLI-1: FA 扫描退出码 ${expected.fa.exit_code}（模型不支持）`, `实际 ${faRun.status}`);
  const faReport = readReport(faOut);
  check(faReport.project_model === expected.fa.project_model, 'VM-2/AC-1.2: project_model=fa');
  check(faReport.inventory.length === expected.fa.inventory_count, 'VM-2: FA inventory 空');
  check(Object.values(faReport.adaptation).every((arr) => arr.length === 0), 'VM-2: FA adaptation 全空');
  check(faRun.stdout.includes('FA 模型不支持'), 'VM-2: FA 提示输出');
  const faMd = readFileSync(join(faOut, 'migration-advice.md'), 'utf8');
  check(faMd.includes('FA 模型不支持'), 'VM-2: FA 报告明示不支持');
  check(snapshotDir(faRoot) === before, 'VM-2: FA fixture 目录零变更');
}

// ── 3. 空目录 → unknown（R-2 + 退出码 3，产物照常写出） ────────────────
{
  const emptyRoot = join(BENCH, '.tmp-empty-project');
  rmSync(emptyRoot, { recursive: true, force: true });
  mkdirSync(emptyRoot, { recursive: true });
  const unkOut = join(BENCH, '.tmp-out-unknown');
  rmSync(unkOut, { recursive: true, force: true });
  const unkRun = runScan([emptyRoot, '--out', unkOut, '--no-sdk']);
  check(unkRun.status === expected.unknown_model.exit_code, `VM-2/CLI-1: 模型无法判定退出码 ${expected.unknown_model.exit_code}`, `实际 ${unkRun.status}`);
  const unkReport = readReport(unkOut);
  check(unkReport.project_model === 'unknown', 'VM-2: 空目录 project_model=unknown');
  check(existsSync(join(unkOut, 'scan-report.json')), 'CLI-1: unknown 产物照常写出');
}

// ── 3.5 清单场景 fixture（v1.2.0 单平台 + v1.3.0 C-API + 撤下条目落 unknown） ──
{
  const capiOut = join(BENCH, '.tmp-out-capi');
  rmSync(capiOut, { recursive: true, force: true });
  const capiRun = runScan([join(BENCH, 'fixture-capi-project'), '--out', capiOut, '--sdk-dir', join(BENCH, 'mini-sdk')]);
  check(capiRun.status === 0, '清单场景: C-API/单平台 fixture 扫描退出码 0', capiRun.stderr);
  const capi = readReport(capiOut);
  check(capi.inventory.length === expected.capi.inventory_count,
    `清单场景: inventory=${expected.capi.inventory_count}`, `实际 ${capi.inventory.length}`);
  for (const [key, exp] of Object.entries(expected.capi.items)) {
    const item = itemOf(capi, exp.bucket, key);
    check(item !== undefined, `清单场景: ${key} → ${exp.bucket}`, '未找到');
    if (item && exp.reason_contains) {
      check(item.reason.includes(exp.reason_contains), `清单场景: ${key} reason 含「${exp.reason_contains}」`, item.reason);
    }
  }
  check(capi.adaptation.unknown.length === expected.capi.unknown_count,
    `清单场景: 撤下条目落 unknown=${expected.capi.unknown_count}（宁缺毋错）`, `实际 ${capi.adaptation.unknown.length}`);
  const capiMd = readFileSync(join(capiOut, 'migration-advice.md'), 'utf8');
  check(capiMd.includes(`单平台支持接口占比：${expected.capi.platform_ratio}`),
    `清单场景: 真实单平台条目占比 ${expected.capi.platform_ratio}（分子/分母皆真实清单命中）`, '未命中占比行');
}

// ── 4. 降级路径（R-14：--no-sdk 与非 TTY 自动降级） ────────────────────
{
  const degOut = join(BENCH, '.tmp-out-degraded');
  rmSync(degOut, { recursive: true, force: true });
  const degRun = runScan([join(BENCH, 'fixture-stage-project'), '--out', degOut, '--no-sdk']);
  check(degRun.status === expected.degraded.exit_code, 'VM-14: 降级扫描退出码 0', `实际 ${degRun.status}`);
  const degReport = readReport(degOut);
  check(degReport.sdk === undefined, 'VM-14/AC-2.8: 降级时 scan-report 无 sdk 字段');
  const md = readFileSync(join(degOut, 'migration-advice.md'), 'utf8');
  check(md.includes('SDK 未检出，单源判定'), 'VM-14: 报告显著标注降级');
  const exp = expected.degraded['@ohos.geoLocationManager#getCurrentLocation'];
  const item = itemOf(degReport, exp.bucket, '@ohos.geoLocationManager#getCurrentLocation');
  check(item !== undefined, 'VM-14: 降级单源采信（geoLocationManager→③）');
  if (item) check(item.reason.includes(exp.reason_contains), 'VM-14: reason 注明降级', item.reason);

  // SD32：非 TTY 未提供 --sdk-dir/--yes 时按"是否有 SDK 候选"分两形态：
  // a) 有候选（本机默认位置探测到）→ exit 4 零产出 + 候选清单（agent 须呈报用户确认，不可默默选）
  // b) 无候选（干净环境）→ 自动降级单源 exit 0（AC-2.9，CI 不中断）
  const envClean = { ...process.env, OH_SDK_DIR: '', OHOS_SDK_HOME: '', DEVECO_SDK_HOME: '', HOME: mkdtempSync(join(tmpdir(), 'f2-nohome-')) };
  const noCandOut = join(BENCH, '.tmp-out-autodeg');
  rmSync(noCandOut, { recursive: true, force: true });
  const noCandRun = spawnSync(process.execPath, [SCAN, join(BENCH, 'fixture-stage-project'), '--out', noCandOut],
    { encoding: 'utf8', env: envClean });
  check(noCandRun.status === 0, 'VM-15/AC-2.9: 无候选环境自动降级退出码 0（CI 不中断）', `status=${noCandRun.status} ${noCandRun.stderr}`);
  check(readReport(noCandOut).sdk === undefined, 'VM-15: 自动降级无 sdk 字段');
  check(readFileSync(join(noCandOut, 'migration-advice.md'), 'utf8').includes('SDK 未检出，单源判定'),
    'VM-15: 自动降级报告标注');

  const candOut = join(BENCH, '.tmp-out-sdkcand');
  rmSync(candOut, { recursive: true, force: true });
  const candRun = runScan([join(BENCH, 'fixture-stage-project'), '--out', candOut]);
  const probeHome = join(homedir(), 'Library', 'OpenHarmony', 'Sdk');
  if (candRun.status === 4) {
    // 本机存在默认位置候选（开发/CI 常态）：SD32 拦截形态
    check((candRun.stderr || '').includes('未经确认，不产出判定'), 'VM-15/SD32: 有候选非 TTY 零产出+候选清单');
    check(!existsSync(join(candOut, 'scan-report.json')), 'VM-15/SD32: 拦截形态零产出');
  } else if (existsSync(probeHome)) {
    check(false, 'VM-15/SD32: 本机有默认 SDK 但未触发确认拦截（应 exit 4）', `status=${candRun.status}`);
  } else {
    check(candRun.status === 0, 'VM-15/SD32: 本机无候选时降级 0', `status=${candRun.status}`);
  }
  rmSync(envClean.HOME, { recursive: true, force: true });
}

// ── 5. 3 次一致性（AC-4.3 / INV-3） ───────────────────────────────────
{
  const runs = [];
  for (let i = 0; i < 3; i++) {
    const out = join(BENCH, `.tmp-out-rerun-${i}`);
    rmSync(out, { recursive: true, force: true });
    const run = runScan([join(BENCH, 'fixture-stage-project'), '--out', out, '--sdk-dir', join(BENCH, 'mini-sdk')]);
    if (run.status !== 0) { check(false, `VM-12: 第 ${i + 1} 次运行失败`, run.stderr); break; }
    runs.push(readFileSync(join(out, 'scan-report.json'), 'utf8'));
  }
  if (runs.length === 3) {
    check(runs[0] === runs[1] && runs[1] === runs[2], 'VM-12/AC-4.3: 3 次 ScanReport 逐字节一致');
  }
}

// ── 6. VM-16 demo 采样（unknown 占比 ≤20% 且逐项归因） ────────────────
{
  const demoOut = join(BENCH, '.tmp-out-demo');
  rmSync(demoOut, { recursive: true, force: true });
  const demoRun = runScan([join(BENCH, 'fixture-demo-project'), '--out', demoOut, '--sdk-dir', join(BENCH, 'mini-sdk')]);
  check(demoRun.status === 0, 'VM-16: demo 采样扫描退出码 0', demoRun.stderr);
  const demoReport = readReport(demoOut);
  const allItems = Object.values(demoReport.adaptation).reduce((sum, arr) => sum + arr.length, 0);
  const unknownItems = demoReport.adaptation.unknown;
  const ratio = allItems === 0 ? 0 : (unknownItems.length / allItems) * 100;
  check(allItems > 0, 'VM-16: demo 采样产出非空 adaptation');
  check(ratio <= expected.demo.unknown_ratio_max,
    `VM-16/规则表覆盖度: unknown 占比 ${ratio.toFixed(1)}% ≤ ${expected.demo.unknown_ratio_max}%`,
    `unknown ${unknownItems.length}/${allItems}`);
  console.log('  VM-16 逐项归因:');
  for (const item of unknownItems) {
    const attribution = Object.keys(expected.demo.unknown_attribution).includes(`${item.module}#${item.symbol}`)
      ? expected.demo.unknown_attribution[`${item.module}#${item.symbol}`]
      : (item.reason.includes('双源冲突') ? '双源冲突' : '规则表未覆盖');
    console.log(`    - ${item.module}#${item.symbol} → ${attribution}`);
    check(item.reason.length > 0, `VM-16: ${item.module}#${item.symbol} 归因可述`);
  }
}

// ── 7. 离线静态检查（AC-4.2 / R-11） ──────────────────────────────────
{
  const NET_RE = /require\(['"](?:net|http|https|dns|tls|fetch)['"]\)|\bfetch\s*\(|import\s+['"]node:(?:net|http|https|dns|tls)['"]/;
  const offenders = [];
  for (const dir of ['scripts', 'benchmark']) {
    walkFiles(join(ROOT, dir)).forEach((f) => {
      if (!f.endsWith('.js') || f.endsWith('.test.js') || f.endsWith('compare.js')) return;
      if (NET_RE.test(readFileSync(f, 'utf8'))) offenders.push(relative(ROOT, f));
    });
  }
  check(offenders.length === 0, 'VM-11/AC-4.2: 交付物零网络 API 引用', offenders.join(', '));
}

// ── 清理临时输出 ────────────────────────────────────────────────────────
for (const dir of ['.tmp-out-stage', '.tmp-out-capi', '.tmp-out-fa', '.tmp-out-unknown', '.tmp-out-degraded', '.tmp-out-autodeg',
  '.tmp-out-rerun-0', '.tmp-out-rerun-1', '.tmp-out-rerun-2', '.tmp-out-demo', '.tmp-empty-project']) {
  rmSync(join(BENCH, dir), { recursive: true, force: true });
}

console.log(failures === 0 ? '\n全部验收项 PASS' : `\n${failures} 项 FAIL`);
process.exit(failures === 0 ? 0 : 1);

function snapshotDir(root) {
  const entries = [];
  walkFiles(root).forEach((f) => {
    entries.push(`${relative(root, f)}:${createHash('sha256').update(readFileSync(f)).digest('hex')}`);
  });
  return entries.sort().join('|');
}

function walkFiles(dir) {
  const files = [];
  if (!existsSync(dir)) return files;
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    const full = join(dir, entry.name);
    if (entry.isDirectory()) files.push(...walkFiles(full));
    else if (entry.isFile()) files.push(full);
  }
  return files;
}

// 收尾：统一清理全部临时产物（替代目录级 .gitignore 防线，保持 skill 交付面干净）
import { readdirSync as _rd, rmSync as _rm } from 'node:fs';
for (const tmp of _rd(BENCH).filter((f) => f.startsWith('.tmp-'))) {
  _rm(join(BENCH, tmp), { recursive: true, force: true });
}
