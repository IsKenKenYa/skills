#!/usr/bin/env node
/**
 * 全量验收（TASK-5 + 跟进轮 TASK-6~8，VM-1~VM-14 对应入口）：
 * 1. modify 成功（mock-ace）→ 按平台选项的 .arkui-x 壳 + SkeletonResult（INV-2 v1.1）
 * 2. modify 平台三取值（--platform both/android/ios，VM-4）
 * 3. new 平台三取值 + 迁入完整性（VM-6，INV-3）
 * 4. modify 失败 → 失败原因 + 改用 new 建议 + 退出码 5（R-5/VM-5）
 * 5. 超时：--timeout-ms 与 ARKUIX_ACE_TIMEOUT_MS 覆盖生效（VM-5/TASK-8）
 * 6. SDK 低版本 + modify → 拒绝提示 + 退出码 4 + 零写（R-1 边界/CLI-1 场景 8）
 * 7. 覆盖确认三分支（skip=0/overwrite=产出/abort=6，VM-7）+ 非交互缺省 abort
 * 8. 计划确认：非 TTY 无 --yes → 退出码 6；模型拒绝 → 退出码 3（VM-8/VM-9）
 * 9. 参数非法值 → 退出码 2（VM-13 非交互部分）
 * 10. 全参数组合零交互（VM-14）
 * 11. 3 次一致性（INV-4）
 * 12. 离线静态检查（VM-11）
 */
import { spawnSync } from 'node:child_process';
import { readFileSync, readdirSync, existsSync, mkdirSync, writeFileSync, rmSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { fileURLToPath } from 'node:url';
import { dirname, join, relative } from 'node:path';

const ROOT = dirname(dirname(fileURLToPath(import.meta.url)));
const BENCH = join(ROOT, 'benchmark');
const SKELETON = join(ROOT, 'scripts', 'skeleton.js');
const MOCK_ACE = join(BENCH, 'mock-ace', 'ace.js');
const expected = JSON.parse(readFileSync(join(BENCH, 'expected-metrics.json'), 'utf8'));

let failures = 0;
function check(ok, label, detail = '') {
  console.log(`${ok ? '✔' : '✖'} ${label}${ok || !detail ? '' : ` — ${detail}`}`);
  if (!ok) failures++;
}

function run(args, env = {}) {
  return spawnSync(process.execPath, [SKELETON, ...args], {
    encoding: 'utf8',
    env: { ...process.env, ...env }
  });
}

const aceArgs = ['--ace-bin', MOCK_ACE];
const EXIT = expected.exit_codes;

function readResult(outDir) {
  return JSON.parse(readFileSync(join(outDir, 'skeleton-result.json'), 'utf8'));
}

function snapshotDir(root) {
  const entries = [];
  walk(root).forEach((f) => {
    entries.push(`${relative(root, f)}:${createHash('sha256').update(readFileSync(f)).digest('hex')}`);
  });
  return entries.sort().join('|');
}

function walk(dir) {
  const files = [];
  if (!existsSync(dir)) return files;
  for (const e of readdirSync(dir, { withFileTypes: true })) {
    const full = join(dir, e.name);
    if (e.isDirectory()) files.push(...walk(full));
    else if (e.isFile()) files.push(full);
  }
  return files;
}

const stageFixture = join(BENCH, 'fixture-stage-project');
const faFixture = join(BENCH, 'fixture-fa-project');
const stageReport = join(BENCH, 'scan-reports', 'stage.json');
const faReport = join(BENCH, 'scan-reports', 'fa.json');

function freshCopy(name) {
  const dir = join(BENCH, name);
  rmSync(dir, { recursive: true, force: true });
  cpDir(stageFixture, dir);
  return dir;
}

// ── 1. modify 成功（VM-4，platform=both） ──────────────────────────────
const stageWork = freshCopy('.tmp-stage-work');
{
  const out = join(BENCH, '.tmp-out-modify');
  rmSync(out, { recursive: true, force: true });
  const runRes = run([stageWork, '--scan-report', stageReport, '--mode', 'modify', '--out', out, '--yes', ...aceArgs]);
  check(runRes.status === EXIT.ok, 'VM-4: modify 成功退出码 0', runRes.stderr);
  const result = readResult(out);
  check(result.mode === expected.modify.mode, 'VM-4: SkeletonResult.mode=modify');
  check(result.platform === expected.modify.platform, 'VM-4: platform=both 记录所选平台');
  check(result.android_shell === expected.modify.android_shell, 'INV-2: android_shell 相对路径 .arkui-x/android', result.android_shell);
  check(result.ios_shell === expected.modify.ios_shell, 'INV-2: ios_shell 相对路径 .arkui-x/ios', result.ios_shell);
  check(result.shared_arkts_dir === expected.modify.shared_arkts_dir, 'SKRS-1: shared_arkts_dir=entry（相对工程根）');
  check(existsSync(join(stageWork, '.arkui-x', 'android', 'build.gradle')), 'INV-2: .arkui-x/android 产物在场');
  check(existsSync(join(stageWork, '.arkui-x', 'ios')), 'INV-2: .arkui-x/ios 产物在场');
  check(result.environment && result.environment.arkui_x_sdk
    && result.environment.arkui_x_sdk.detected === true
    && result.environment.arkui_x_sdk.modify_available === true,
  'VM-1: environment.arkui_x_sdk 检出且 modify_available（26.0.0 ≥ API 24）');
  check((runRes.stdout || '').includes('实际改动文件清单'), 'R-4: modify 成功路径输出实际改动清单');
  check(existsSync(join(out, 'migration-skeleton-report.md')), 'VM-9: 骨架报告产出');
}

// ── 2. modify 平台三取值（VM-4 v1.1） ─────────────────────────────────
for (const platform of ['both', 'android', 'ios']) {
  const work = freshCopy(`.tmp-stage-p-${platform}`);
  const out = join(BENCH, `.tmp-out-p-${platform}`);
  rmSync(out, { recursive: true, force: true });
  const runRes = run([work, '--scan-report', stageReport, '--mode', 'modify', '--platform', platform,
    '--out', out, '--yes', ...aceArgs]);
  check(runRes.status === EXIT.ok, `VM-4: modify --platform=${platform} 退出码 0`, runRes.stderr);
  const result = readResult(out);
  check(result.platform === platform, `VM-4: platform=${platform} 记录`);
  const androidShellExists = existsSync(join(work, '.arkui-x', 'android'));
  const iosShellExists = existsSync(join(work, '.arkui-x', 'ios'));
  if (platform === 'both') {
    check(androidShellExists && iosShellExists, 'VM-4: both → 双平台壳在场');
    check(result.android_shell && result.ios_shell, 'SKRS-1: both → 两壳字段必填');
  } else if (platform === 'android') {
    check(androidShellExists && !iosShellExists, 'VM-4: android → 仅 android 壳', `a=${androidShellExists} i=${iosShellExists}`);
    check(result.android_shell === expected.modify.platform_cases.android.android_shell
      && result.ios_shell === undefined, 'SKRS-1: android → android_shell 必填、ios_shell 不出现');
  } else {
    check(iosShellExists && !androidShellExists, 'VM-4: ios → 仅 ios 壳', `a=${androidShellExists} i=${iosShellExists}`);
    check(result.ios_shell === expected.modify.platform_cases.ios.ios_shell
      && result.android_shell === undefined, 'SKRS-1: ios → ios_shell 必填、android_shell 不出现');
  }
  rmSync(work, { recursive: true, force: true });
}

// ── 3. modify 失败（VM-5） ─────────────────────────────────────────────
{
  const failWork = freshCopy('.tmp-stage-fail');
  const out = join(BENCH, '.tmp-out-fail');
  rmSync(out, { recursive: true, force: true });
  const runRes = run([failWork, '--scan-report', stageReport, '--mode', 'modify', '--out', out, '--yes', ...aceArgs],
    { MOCK_ACE_BEHAVIOR: 'fail' });
  check(runRes.status === EXIT.tool_fail, `VM-5: modify 失败退出码 ${EXIT.tool_fail}`, `status=${runRes.status}`);
  check((runRes.stderr || '').includes('建议改用 new'), 'VM-5/AC-2.2: 输出建议改用 new 模式', runRes.stderr);
  check((runRes.stderr || '').includes('ace modify 失败'), 'VM-5: 输出失败原因');
  check(!existsSync(join(out, 'skeleton-result.json')), 'VM-5: 失败路径不产出 SkeletonResult');
  rmSync(failWork, { recursive: true, force: true });
}

// ── 4. modify 前置失败（缺三件套） ─────────────────────────────────────
{
  const incomplete = join(BENCH, '.tmp-stage-incomplete');
  rmSync(incomplete, { recursive: true, force: true });
  mkdirSync(join(incomplete, 'AppScope'), { recursive: true });
  writeFileSync(join(incomplete, 'AppScope', 'app.json5'), '{}');
  const runRes = run([incomplete, '--scan-report', stageReport, '--mode', 'modify', '--yes', ...aceArgs]);
  check(runRes.status === EXIT.usage, '前置校验：缺三件套退出码 2（输入无效）');
  check((runRes.stderr || '').includes('工程不完整'), '前置校验：提示工程不完整', runRes.stderr);
  check(!existsSync(join(incomplete, '.arkui-x')), '前置校验：零产出');
}

// ── 5. 超时：--timeout-ms 透传 + ARKUIX_ACE_TIMEOUT_MS 覆盖生效（TASK-8） ──
{
  const timeoutWork = freshCopy('.tmp-stage-timeout');
  const runRes = run([timeoutWork, '--scan-report', stageReport, '--mode', 'modify', '--yes',
    '--timeout-ms', '1', ...aceArgs], { MOCK_ACE_BEHAVIOR: 'timeout' });
  check(runRes.status === EXIT.tool_timeout, `--timeout-ms=1 超时路径退出码 ${EXIT.tool_timeout}`, `status=${runRes.status}`);
  check((runRes.stderr || '').includes('>1ms'), '超时失败消息含实际阈值（>1ms）', runRes.stderr);
  const invalid = run([stageFixture, '--scan-report', stageReport, '--timeout-ms', 'abc']);
  check(invalid.status === EXIT.usage && (invalid.stderr || '').includes('正整数毫秒'), '非法 --timeout-ms 拒绝（码 2）');

  // 环境变量覆盖：小阈值注入验证生效（design：非法值回默认并警告）
  const envWork = freshCopy('.tmp-stage-envtimeout');
  const envRun = run([envWork, '--scan-report', stageReport, '--mode', 'modify', '--yes', ...aceArgs],
    { MOCK_ACE_BEHAVIOR: 'timeout', ARKUIX_ACE_TIMEOUT_MS: '100' });
  check(envRun.status === EXIT.tool_timeout, 'TASK-8: ARKUIX_ACE_TIMEOUT_MS=100 覆盖生效（超时触发）', `status=${envRun.status}`);
  check((envRun.stderr || '').includes('>100ms'), 'TASK-8: 环境变量超时消息含覆盖阈值（>100ms）', envRun.stderr);
  const envInvalid = run([stageFixture, '--scan-report', stageReport, '--mode', 'modify', '--yes', ...aceArgs],
    { MOCK_ACE_BEHAVIOR: 'fail', ARKUIX_ACE_TIMEOUT_MS: 'bogus' });
  check((envInvalid.stderr || '').includes('ARKUIX_ACE_TIMEOUT_MS 非法值'), 'TASK-8: 非法环境值警告后回默认', envInvalid.stderr);
  rmSync(timeoutWork, { recursive: true, force: true });
  rmSync(envWork, { recursive: true, force: true });
}

// ── 6. SDK 低版本 + modify → 拒绝（R-1 边界，退出码 4，零写） ──────────
{
  const lowWork = freshCopy('.tmp-stage-low');
  const before = snapshotDir(lowWork);
  const runRes = run([lowWork, '--scan-report', stageReport, '--mode', 'modify', '--yes', ...aceArgs],
    { MOCK_ACE_VERSION: '23' });
  check(runRes.status === EXIT.env_low_sdk, `VM-1/CLI-1 场景8: SDK<API24 + modify 退出码 ${EXIT.env_low_sdk}`, `status=${runRes.status}`);
  check((runRes.stderr || '').includes('ace modify 不可用'), 'R-1: 拒绝提示在场', runRes.stderr);
  check((runRes.stderr || '').includes('23'), 'R-1: 提示含检出版本', runRes.stderr);
  check((runRes.stderr || '').includes('new'), 'R-1: 提示含改用 new 建议');
  check(snapshotDir(lowWork) === before, 'R-1: 拒绝路径零写');
  // new 模式不受门槛阻断
  const newOut = join(BENCH, '.tmp-out-lownew');
  rmSync(newOut, { recursive: true, force: true });
  const newRun = run([lowWork, '--scan-report', stageReport, '--mode', 'new', '--out', newOut, '--yes', ...aceArgs],
    { MOCK_ACE_VERSION: '23' });
  check(newRun.status === EXIT.ok, 'R-1: SDK 低版本不阻断 new 模式', newRun.stderr);
  check(readResult(newOut).environment.arkui_x_sdk.modify_available === false, 'R-1: environment 记录 modify_available=false');
  rmSync(lowWork, { recursive: true, force: true });
}

// ── 7. new 成功 + 平台三取值 + 迁入完整性（VM-6，INV-3） ────────────────
for (const platform of ['both', 'android', 'ios']) {
  const out = join(BENCH, `.tmp-out-new-${platform}`);
  rmSync(out, { recursive: true, force: true });
  const runRes = run([stageFixture, '--scan-report', stageReport, '--mode', 'new', '--platform', platform,
    '--out', out, '--yes', ...aceArgs]);
  check(runRes.status === EXIT.ok, `VM-6: new --platform=${platform} 退出码 0`, runRes.stderr);
  const result = readResult(out);
  check(result.mode === expected.new.mode && result.platform === platform, `VM-6: mode=new platform=${platform}`);
  check(existsSync(join(out, '.arkui-x', 'android')) === (platform !== 'ios'), `VM-6/SD3: android 壳在 .arkui-x/ 按平台生成/裁剪（${platform}）`);
  check(existsSync(join(out, '.arkui-x', 'ios')) === (platform !== 'android'), `VM-6/SD3: ios 壳在 .arkui-x/ 按平台生成/裁剪（${platform}）`);
  if (platform === 'android') check(result.ios_shell === undefined, 'SKRS-1: new+android → ios_shell 不出现');
  if (platform === 'ios') check(result.android_shell === undefined, 'SKRS-1: new+ios → android_shell 不出现');
  if (platform !== 'ios') check(result.android_shell === '.arkui-x/android', 'SD3: 壳路径=.arkui-x/android（ace 26.0.0 布局）', result.android_shell);
  const sharedSrc = join(out, 'entry', 'src', 'main');
  const srcMain = join(stageFixture, 'entry', 'src', 'main');
  let migrationOk = true;
  const detail = [];
  for (const rel of expected.new.migrated_rels) {
    const from = join(srcMain, rel);
    const to = join(sharedSrc, rel);
    if (!existsSync(to)) { migrationOk = false; detail.push(`缺失 ${rel}`); continue; }
    if (hashOf(from) !== hashOf(to)) { migrationOk = false; detail.push(`改写 ${rel}`); }
  }
  check(migrationOk, 'INV-3: 迁入文件集合+内容哈希一致', detail.join('; '));
  check(walk(sharedSrc).length >= expected.new.migrated_files, 'INV-3: 迁入数量', `实际 ${walk(sharedSrc).length}`);
  check(existsSync(join(out, 'migration-skeleton-report.md')), 'VM-9: 报告产出');
  check(result.shared_arkts_dir === 'entry', 'SKRS-1: new shared_arkts_dir 相对输出目录（entry）', result.shared_arkts_dir);
}

// ── 8. 覆盖确认三分支（VM-7：skip=0/overwrite=产出/abort=6） ───────────
{
  const mkNonEmpty = () => {
    const out = join(BENCH, '.tmp-out-nonempty');
    rmSync(out, { recursive: true, force: true });
    mkdirSync(out, { recursive: true });
    writeFileSync(join(out, 'keep.txt'), 'x');
    return out;
  };
  // skip：零变更不产出 + 退出码 0 + stdout 明示
  {
    const out = mkNonEmpty();
    const before = snapshotDir(out);
    const runRes = run([stageFixture, '--scan-report', stageReport, '--mode', 'new', '--out', out,
      '--confirm-overwrite', 'skip', '--yes', ...aceArgs]);
    check(runRes.status === EXIT.skip, `VM-7: skip 分支退出码 ${EXIT.skip}（编排方可继续的良性结束）`, `status=${runRes.status}`);
    check((runRes.stdout || '').includes('已跳过本次骨架生成'), 'VM-7: skip stdout 明示');
    check(snapshotDir(out) === before, 'VM-7: skip 目录零变更');
    check(!existsSync(join(out, 'skeleton-result.json')), 'VM-7: skip 不产出 SkeletonResult');
  }
  // abort：非 0 + 零新增
  {
    const out = mkNonEmpty();
    const before = snapshotDir(out);
    const runRes = run([stageFixture, '--scan-report', stageReport, '--mode', 'new', '--out', out,
      '--confirm-overwrite', 'abort', '--yes', ...aceArgs]);
    check(runRes.status === EXIT.user_abort, `VM-7: abort 分支退出码 ${EXIT.user_abort}`, `status=${runRes.status}`);
    check((runRes.stderr || '').includes('用户中止'), 'VM-7: abort stderr 用户中止');
    check(snapshotDir(out) === before, 'VM-7: abort 确认前零新文件');
  }
  // overwrite：确认后正常产出
  {
    const out = mkNonEmpty();
    const runRes = run([stageFixture, '--scan-report', stageReport, '--mode', 'new', '--out', out,
      '--confirm-overwrite', 'overwrite', '--yes', ...aceArgs]);
    check(runRes.status === EXIT.ok, 'VM-7: overwrite 分支确认后正常产出', runRes.stderr);
    check(existsSync(join(out, 'skeleton-result.json')), 'VM-7: overwrite 产出 SkeletonResult');
  }
  // 非交互缺省 = abort
  {
    const out = mkNonEmpty();
    const before = snapshotDir(out);
    const runRes = run([stageFixture, '--scan-report', stageReport, '--mode', 'new', '--out', out, ...aceArgs]);
    check(runRes.status === EXIT.user_abort, 'VM-7: 非 TTY 未提供参数缺省按中止（码 6）', `status=${runRes.status}`);
    check(snapshotDir(out) === before, 'VM-7: 缺省中止目录零新增');
  }
}

// ── 9. 计划确认（非 TTY 无 --yes → 6）与模型拒绝（3） ──────────────────
{
  const planWork = freshCopy('.tmp-stage-plan');
  const runRes = run([planWork, '--scan-report', stageReport, '--mode', 'modify', ...aceArgs]);
  check(runRes.status === EXIT.user_abort, 'R-4: 非 TTY modify 无 --yes 按用户中止（码 6）', `status=${runRes.status}`);
  check(!existsSync(join(planWork, '.arkui-x')), 'R-4: 计划确认中止零写');
  rmSync(planWork, { recursive: true, force: true });
}
{
  const before = snapshotDir(faFixture);
  const runRes = run([faFixture, '--scan-report', faReport, '--mode', 'modify', '--yes', ...aceArgs]);
  check(runRes.status === EXIT.model, `VM-8/AC-4.1: FA 拒绝退出码 ${EXIT.model}（模型拒绝）`, `status=${runRes.status}`);
  check((runRes.stderr || '').includes(expected.rejects.fa_message), 'VM-8: FA 不支持提示', runRes.stderr);
  check(snapshotDir(faFixture) === before, 'INV-1: FA fixture 目录零变更');
}
{
  const missing = run([stageFixture, '--scan-report', join(BENCH, 'no-such.json'), '--mode', 'modify', '--yes', ...aceArgs]);
  check(missing.status === EXIT.model, `VM-9/AC-4.2: ScanReport 缺失退出码 ${EXIT.model}`, `status=${missing.status}`);
  check((missing.stderr || '').includes(expected.rejects.unknown_message), 'VM-9: 引导先运行 F2', missing.stderr);

  const unknownReport = join(BENCH, '.tmp-unknown-report.json');
  writeFileSync(unknownReport, JSON.stringify({ schema_version: 1, project_model: 'unknown' }));
  const unknown = run([stageFixture, '--scan-report', unknownReport, '--mode', 'modify', '--yes', ...aceArgs]);
  check(unknown.status === EXIT.model && (unknown.stderr || '').includes(expected.rejects.unknown_message),
    'VM-9: project_model=unknown 引导 F2（码 3）');
  check(!existsSync(join(stageFixture, '.arkui-x')), 'INV-1: unknown 路径零写（stage fixture 原件未触碰）');
}

// ── 10. 参数非法值 → 退出码 2（VM-13 非交互部分） ──────────────────────
{
  const badPlatform = run([stageFixture, '--scan-report', stageReport, '--mode', 'modify', '--platform', 'windows', '--yes', ...aceArgs]);
  check(badPlatform.status === EXIT.usage && (badPlatform.stderr || '').includes('both/android/ios'),
    'VM-13: --platform 非法值 → 码 2', badPlatform.stderr);
  const badMode = run([stageFixture, '--scan-report', stageReport, '--mode', 'rebuild', '--yes', ...aceArgs]);
  check(badMode.status === EXIT.usage, 'VM-13: --mode 非法值 → 码 2');
  const badConfirm = run([stageFixture, '--scan-report', stageReport, '--mode', 'new', '--out', join(BENCH, '.tmp-x'),
    '--confirm-overwrite', 'force', ...aceArgs]);
  check(badConfirm.status === EXIT.usage && (badConfirm.stderr || '').includes('skip/overwrite/abort'),
    'VM-13: --confirm-overwrite 非法值 → 码 2', badConfirm.stderr);
  const noMode = run([stageFixture, '--scan-report', stageReport, ...aceArgs]);
  check(noMode.status === EXIT.usage, 'VM-13: 非 TTY 缺 --mode → 码 2（design 参数表必填）');
}

// ── 11. VM-14 全参数组合（modify/new 各 1，零交互，预置非空目录触发覆盖确认路径） ──
{
  // modify：--mode + --platform + --confirm-overwrite + --yes 全参数
  const comboWork = freshCopy('.tmp-stage-combo');
  const modOut = join(BENCH, '.tmp-out-combo-mod');
  rmSync(modOut, { recursive: true, force: true });
  const modRes = run([comboWork, '--scan-report', stageReport, '--mode', 'modify', '--platform', 'android',
    '--confirm-overwrite', 'overwrite', '--out', modOut, '--yes', ...aceArgs]);
  check(modRes.status === EXIT.ok, 'VM-14: modify 全参数组合退出码 0（零交互）', modRes.stderr);
  const modResult = readResult(modOut);
  check(modResult.mode === 'modify' && modResult.platform === 'android', 'VM-14: modify 组合结果与交互路径等价（mode/platform）');
  check(modResult.ios_shell === undefined, 'VM-14: modify+android → ios_shell 不出现');
  // SD26（r7）：mock-ace modify 成功输出 WARN → 成功产物沉淀（result 字段 + 报告必办段）
  check(Array.isArray(modResult.ace_warnings) && modResult.ace_warnings.some((w) => w.includes('useNormalizedOHMUrl')),
    'SD26: modify 成功 skeleton-result.json 沉淀 ace_warnings（useNormalizedOHMUrl 必办）', JSON.stringify(modResult.ace_warnings));
  const modReport = readFileSync(join(modOut, 'migration-skeleton-report.md'), 'utf8');
  check(/ace 迁移提示（编译前必办/.test(modReport) && modReport.includes('useNormalizedOHMUrl'),
    'SD26: migration-skeleton-report.md 含"ace 迁移提示（编译前必办）"段');
  rmSync(comboWork, { recursive: true, force: true });

  // new：预置非空目录触发覆盖确认路径（--confirm-overwrite overwrite 显式跳过询问）
  const newOut = join(BENCH, '.tmp-out-combo-new');
  rmSync(newOut, { recursive: true, force: true });
  mkdirSync(newOut, { recursive: true });
  writeFileSync(join(newOut, 'keep.txt'), 'x');
  const newRes = run([stageFixture, '--scan-report', stageReport, '--mode', 'new', '--platform', 'ios',
    '--confirm-overwrite', 'overwrite', '--out', newOut, '--yes', ...aceArgs]);
  check(newRes.status === EXIT.ok, 'VM-14: new 全参数组合退出码 0（非空目录经 overwrite 参数零交互通过）', newRes.stderr);
  const newResult = readResult(newOut);
  check(newResult.mode === 'new' && newResult.platform === 'ios', 'VM-14: new 组合结果与交互路径等价');
  check(newResult.android_shell === undefined, 'VM-14: new+ios → android_shell 不出现');
}

// ── 11.5 r3 修复场景：SD4 回退 / SD9 改动清单 / SD5 多模块 / SD8 幂等 ───
{
  // SD4：预置 scaffold → 跳过 create 直接迁入（假 ace 佐证未调用 ace）
  const pre = join(BENCH, '.tmp-out-prefab');
  rmSync(pre, { recursive: true, force: true });
  mkdirSync(join(pre, '.arkui-x', 'android'), { recursive: true });
  mkdirSync(join(pre, '.arkui-x', 'ios'), { recursive: true });
  mkdirSync(join(pre, 'entry', 'src', 'main'), { recursive: true });
  const prefabRun = run([stageFixture, '--scan-report', stageReport, '--mode', 'new',
    '--out', pre, '--confirm-overwrite', 'overwrite', '--yes', '--ace-bin', '/no/such/ace']);
  check(prefabRun.status === EXIT.ok, 'SD4: scaffold 在场跳过 create 直接迁入（假 ace 佐证未调用 ace）', prefabRun.stderr);
  check((prefabRun.stdout || '').includes('跳过 ace create'), 'SD4: 跳过提示输出');
  check(existsSync(join(pre, 'entry', 'src', 'main', 'ets', 'Index.ets')), 'SD4: 迁入完成');

  // SD9：success-rewrite → 改动清单含既有文件改写
  const rwWork = freshCopy('.tmp-stage-rewrite');
  const rwOut = join(BENCH, '.tmp-out-rewrite');
  rmSync(rwOut, { recursive: true, force: true });
  const rwRun = run([rwWork, '--scan-report', stageReport, '--mode', 'modify', '--out', rwOut, '--yes', ...aceArgs],
    { MOCK_ACE_BEHAVIOR: 'success-rewrite' });
  check(rwRun.status === EXIT.ok, 'SD9: success-rewrite 退出码 0', rwRun.stderr);
  check(/~ hvigorfile\.ts/.test(rwRun.stdout || ''), 'SD9: 改动清单含既有文件改写（~ hvigorfile.ts）');
  check(/\+ \.arkui-x\//.test(rwRun.stdout || ''), 'SD9: 改动清单含新增（+ .arkui-x/…）');
  rmSync(rwWork, { recursive: true, force: true });

  // SD5：多模块 fixture → 逐模块迁入
  const mmOut = join(BENCH, '.tmp-out-multimod');
  rmSync(mmOut, { recursive: true, force: true });
  const mmRun = run([join(BENCH, 'fixture-multimodule-project'), '--scan-report', stageReport,
    '--mode', 'new', '--out', mmOut, '--yes', ...aceArgs]);
  check(mmRun.status === EXIT.ok, 'SD5: 多模块工程 new 退出码 0', mmRun.stderr);
  check(existsSync(join(mmOut, 'entry', 'src', 'main', 'ets', 'EntryIndex.ets')), 'SD5: entry 模块迁入');
  check(existsSync(join(mmOut, 'feature', 'src', 'main', 'ets', 'Feature.ets')), 'SD5: feature 模块迁入（业务名 entry 布局）');

  // SD28 根治：--scaffold-from 归档物化（零 ace 交互，SDK 26.0.0 确定性）
  const archOut = join(BENCH, '.tmp-out-archive');
  rmSync(archOut, { recursive: true, force: true });
  const archRun = run([join(BENCH, 'fixture-multimodule-project'), '--scan-report', stageReport,
    '--mode', 'new', '--out', archOut, '--yes', '--scaffold-from',
    '--project-name', 'benchapp', '--bundle-name', 'com.bench.app', '--ace-bin', '/no/such/ace']);
  check(archRun.status === EXIT.ok, 'SD28: 归档物化 new 退出码 0（不依赖 ace）', archRun.stderr);
  check(/"compileSdkVersion": "26\.0\.0"/.test(readFileSync(join(archOut, 'build-profile.json5'), 'utf8')),
    'SD28: 归档物化 compileSdkVersion 确定性 26.0.0');
  check(readFileSync(join(archOut, 'AppScope/app.json5'), 'utf8').includes('"bundleName": "com.bench.app"'),
    'SD28: 归档物化 bundleName 变量替换');
  check(existsSync(join(archOut, '.arkui-x/android/app/src/main/java/com/bench/app/EntryEntryAbilityActivity.java')),
    'SD28: java 包目录按 bundleName 重组');
  check(existsSync(join(archOut, 'feature', 'src', 'main', 'ets', 'Feature.ets')), 'SD28: 归档路径迁入正常');
  rmSync(archOut, { recursive: true, force: true });

  // SD8：幂等重跑（modify 后二跑，假 ace 佐证跳过 ace 调用）
  const idemWork = freshCopy('.tmp-stage-idem');
  const o1 = join(BENCH, '.tmp-out-idem1');
  rmSync(o1, { recursive: true, force: true });
  run([idemWork, '--scan-report', stageReport, '--mode', 'modify', '--out', o1, '--yes', ...aceArgs]);
  const o2 = join(BENCH, '.tmp-out-idem2');
  rmSync(o2, { recursive: true, force: true });
  const idemRun = run([idemWork, '--scan-report', stageReport, '--mode', 'modify', '--out', o2, '--yes', '--ace-bin', '/no/such/ace']);
  check(idemRun.status === EXIT.ok, 'SD8: 已 modify 工程幂等重跑（假 ace 佐证跳过 ace 调用）', idemRun.stderr);
  check((idemRun.stdout || '').includes('幂等重跑'), 'SD8: 幂等跳过提示');
  check(existsSync(join(o2, 'skeleton-result.json')), 'SD8: 幂等路径产出 SkeletonResult');
  rmSync(idemWork, { recursive: true, force: true });
}

// ── 12. 3 次一致性（VM-12，INV-4；new 全新目录+路径归一化） ─────────────
{
  const runs = [];
  let allOk = true;
  for (let i = 0; i < 3; i++) {
    const out = join(BENCH, `.tmp-out-rerun-${i}`);
    rmSync(out, { recursive: true, force: true });
    const runRes = run([stageFixture, '--scan-report', stageReport, '--mode', 'new', '--out', out, '--yes', ...aceArgs]);
    if (runRes.status !== 0) { allOk = false; check(false, `VM-12: 第 ${i + 1} 次运行失败`, runRes.stderr); break; }
    runs.push(normalize(readResult(out), out));
  }
  if (runs.length === 3) {
    check(allOk && JSON.stringify(runs[0]) === JSON.stringify(runs[1]) && JSON.stringify(runs[1]) === JSON.stringify(runs[2]),
      'VM-12/AC-5.3: 3 次 SkeletonResult 语义一致（路径前缀归一化）');
  }
}

// ── 13. 离线静态检查（VM-11） ───────────────────────────────────────────
{
  const NET_RE = /require\(['"](?:net|http|https|dns|tls|fetch)['"]\)|\bfetch\s*\(|import\s+['"]node:(?:net|http|https|dns|tls)['"]/;
  const offenders = [];
  for (const dir of ['scripts', 'benchmark']) {
    walk(join(ROOT, dir)).forEach((f) => {
      if (!f.endsWith('.js') || f.endsWith('.test.js') || f.endsWith('compare.js') || f.endsWith('ace.js')) return;
      if (NET_RE.test(readFileSync(f, 'utf8'))) offenders.push(relative(ROOT, f));
    });
  }
  check(offenders.length === 0, 'VM-11/AC-5.2: 交付物零网络 API 引用', offenders.join(', '));
}

// ── 清理 ───────────────────────────────────────────────────────────────
for (const dir of ['.tmp-stage-work', '.tmp-stage-timeout', '.tmp-stage-envtimeout', '.tmp-stage-low', '.tmp-stage-combo',
  '.tmp-out-modify', '.tmp-out-combo-mod', '.tmp-out-combo-new', '.tmp-stage-fail', '.tmp-out-fail', '.tmp-stage-incomplete',
  '.tmp-out-new-both', '.tmp-out-new-android', '.tmp-out-new-ios', '.tmp-out-lownew', '.tmp-out-nonempty',
  '.tmp-out-rerun-0', '.tmp-out-rerun-1', '.tmp-out-rerun-2', '.tmp-out-prefab', '.tmp-out-rewrite', '.tmp-out-multimod', '.tmp-out-idem1', '.tmp-out-idem2', '.tmp-stage-rewrite', '.tmp-stage-idem']) {
  rmSync(join(BENCH, dir), { recursive: true, force: true });
}
for (const platform of ['both', 'android', 'ios']) {
  rmSync(join(BENCH, `.tmp-stage-p-${platform}`), { recursive: true, force: true });
  rmSync(join(BENCH, `.tmp-out-p-${platform}`), { recursive: true, force: true });
}
rmSync(join(BENCH, '.tmp-unknown-report.json'), { force: true });

console.log(failures === 0 ? '\n全部验收项 PASS' : `\n${failures} 项 FAIL`);
process.exit(failures === 0 ? 0 : 1);

function normalize(result, outDir) {
  const json = JSON.stringify(result);
  return json.split(outDir).join('<OUT>');
}

function hashOf(file) {
  return createHash('sha256').update(readFileSync(file)).digest('hex');
}

// 收尾：统一清理全部临时产物（替代目录级 .gitignore 防线，保持 skill 交付面干净）
for (const tmp of readdirSync(BENCH).filter((f) => f.startsWith('.tmp-'))) {
  rmSync(join(BENCH, tmp), { recursive: true, force: true });
}

function cpDir(from, to) {
  mkdirSync(to, { recursive: true });
  walk(from).forEach((f) => {
    const rel = relative(from, f);
    const dest = join(to, rel);
    mkdirSync(dirname(dest), { recursive: true });
    writeFileSync(dest, readFileSync(f));
  });
}
