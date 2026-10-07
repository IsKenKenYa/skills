import { cpSync, existsSync, mkdirSync, readFileSync, readdirSync, renameSync, rmSync, rmdirSync, writeFileSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import { spawnAce } from './ace-invoker.js';
import { join } from 'node:path';

/** scaffold 共享 ArkTS 候选（ace create 官方模板布局的归一顺序，design 固化；r3 探针实证 entry/ 顶层在场） */
const SHARED_CANDIDATES = ['entry', 'ets', 'ets_stage/source/entry'];

/**
 * 非空目录检查（R-7）
 * @returns {{exists: boolean, nonEmpty: boolean}}
 */
export function checkOutputDir(dir) {
  if (!existsSync(dir)) return { exists: false, nonEmpty: false };
  let entries = [];
  try {
    entries = readdirSync(dir);
  } catch {
    return { exists: true, nonEmpty: true };
  }
  return { exists: true, nonEmpty: entries.length > 0 };
}

/**
 * 覆盖确认决策（R-7，v1.1 语义）：无效应答返回 null（调用方提示合法取值并重新询问）
 * @returns {'skip'|'overwrite'|'abort'|null}
 */
export function decideOnNonEmpty(answer) {
  const normalized = String(answer || '').trim().toLowerCase();
  if (normalized === '' ) return null;
  if (normalized === 's' || normalized === 'skip' || normalized === '跳过') return 'skip';
  if (normalized === 'y' || normalized === 'o' || normalized === 'overwrite' || normalized === '覆盖') return 'overwrite';
  if (normalized === 'q' || normalized === 'a' || normalized === 'abort' || normalized === '中止') return 'abort';
  return null;
}

/**
 * 两级壳布局归一（SD3，ace 26.0.0 实测）：优先真实布局 .arkui-x/{android,ios}，
 * 兼容 legacy 顶层 android/ios（旧 ace / mock）。
 * @returns {{root: string, android: string, ios: string, legacy: boolean}}
 */
export function resolveShells(outDir) {
  const axAndroid = join(outDir, '.arkui-x', 'android');
  const axIos = join(outDir, '.arkui-x', 'ios');
  if (existsSync(axAndroid) || existsSync(axIos)) {
    return { root: join(outDir, '.arkui-x'), android: axAndroid, ios: axIos, legacy: false };
  }
  return { root: outDir, android: join(outDir, 'android'), ios: join(outDir, 'ios'), legacy: true };
}

/** scaffold 已在场判定（SD4）：.arkui-x/ 在场，或 legacy 顶层双壳 */
export function scaffoldPresent(outDir) {
  if (existsSync(join(outDir, '.arkui-x'))) return true;
  return existsSync(join(outDir, 'android')) && existsSync(join(outDir, 'ios'));
}

/**
 * Compile SDK 菜单最大索引发现（仅适用于在崩溃前打印菜单的 ace 实现/mock 生态；
 * 真 ace 26.0.0 管道模式在 Q1 重绘即崩、不输出菜单——r3 实测后主流程已不依赖本函数）
 */
export function discoverCompileSdkMaxIndex(aceBin, nearDir) {
  const probeDir = `${nearDir}.acescan-${process.pid}`;
  let stdout = '';
  let spawnError = null;
  try {
    const result = spawnAce(aceBin, ['create', probeDir, '-t', 'app'], {
      spawnOpts: {
        encoding: 'utf8',
        input: '\n\n1\n',
        timeout: 20000
      }
    });
    stdout = result.stdout || '';
    if (result.error) spawnError = result.error;
  } catch (err) {
    spawnError = err;
  } finally {
    rmSync(probeDir, { recursive: true, force: true });
  }
  if (spawnError) return { error: spawnError };
  const line = stdout.split('\n').find((l) => /select\s+the\s+Comp\w*\s*SDk/i.test(l)); // 兼容 ace 拼写 Complie
  if (!line) return { idx: null };
  const pairs = [...line.matchAll(/(\d+)\s*:\s*\d[\w.]*/g)].map((m) => Number(m[1]));
  if (pairs.length === 0) return { idx: null };
  return { idx: Math.max(...pairs) };
}

/**
 * 包装 `ace create <dir> -t app`（ADR-2；SD3/SD4/SD6 r3 修订）
 * - 交互模型（ace 26.0.0 实测 6 题）：项目名(默认)→bundleName(默认)→runtimeOS(1=OpenHarmony)
 *   →Compile SDK(菜单自适应索引)→平台(1/2/3 映射)→Framework(2=CocoaPods，Native Manual 路径实测挂起)
 * - scaffold 已在场（SD4）：跳过 create 直接返回迁入所需信息（官方回退路径兑现）
 * - 布局（SD3）：断言经 resolveShells 归一（.arkui-x/ 优先）
 * @param {{aceBin?: string, timeoutMs?: number, platform?: 'both'|'android'|'ios'}} options
 * @returns {{ok: boolean, reason?: string, sharedArktsDir?: string, skippedCreate?: boolean, legacy?: boolean}}
 */
export function createScaffold(outDir, options = {}) {
  const aceBin = options.aceBin || 'ace';
  const timeoutMs = options.timeoutMs || 300000;
  const platform = options.platform || 'both';

  // SD4：scaffold 已在场 → 跳过 ace create，直接供迁入（"手动 create 后重跑"承诺兑现）
  if (scaffoldPresent(outDir)) {
    return { ok: true, skippedCreate: true, sharedArktsDir: resolveSharedDir(outDir), legacy: resolveShells(outDir).legacy };
  }

  const platformAnswer = { both: '1', android: '2', ios: '3' }[platform];

  // 坑①前置避让（统一轮实测 26 次 expect 绕行后固化）：真 ace 26.0.0 的 readline
  // 在管道模式下必崩（ERR_USE_AFTER_CLOSE），且 ace create 无 CLI 参数跳过交互——
  // 非 TTY 环境直接给出可执行指引，不再浪费一次必崩的管道尝试（省 ~10s + 消除堆栈噪音）
  if (!process.stdin.isTTY) {
    // 先检测 ace 是否存在：不存在直接报因（不走短路长指引）
    const aceExists = existsSync(aceBin) || aceBin === 'ace';
    if (!aceExists) {
      return { ok: false, reason: `ace 命令不可用（${aceBin}）；请确认 ArkUI-X SDK toolchains 在 PATH 或以 --ace-bin 指定` };
    }
    const isMock = /mock|benchmark/i.test(aceBin);  // 单测 mock-bin / benchmark mock-ace / 显式 test 标记
    if (!isMock) {
      // 真 ace + 非 TTY → 短路，给 copy-paste 指引
      console.error(`
┌─ ace create 在非 TTY 环境不可用（工具交互限制）─────────────┐
│ ace 26.0.0 的 create 为 6 题交互，管道模式下 readline 必崩。   │
│                                                              │
│ 请选择以下方式之一：                                          │
│                                                              │
│ A. 在终端手动执行（复制以下命令，按提示作答）：                  │
│      ${aceBin} create ${outDir} -t app                │
│    建议答案：                                                │
│      1. 项目名      → 回车（默认）                            │
│      2. bundleName  → 回车（默认）                            │
│      3. runtimeOS   → 1（OpenHarmony）                      │
│      4. Compile SDK → 输最大项编号 16 后回车（= 26.0.0）        │
│      5. 平台        → ${platformAnswer}（${platform}）${' '.repeat(Math.max(0, 10 - platform.length))}       │
│      6. Framework   → 2（CocoaPods）                        │
│                                                              │
│ B. 手动 create 完成后重跑本命令                               │
│    （scaffold 已在场时自动跳过 create 直接迁入）                │
│                                                              │
│ C. 在 TTY 终端运行本命令（自动透传交互）                        │
└──────────────────────────────────────────────────────────┘`);
      return { ok: false, reason: 'ace create 在非 TTY 环境不可用（详见上方指引，手动 create 后重跑即可跳过）', guidance: true };
    }
    // mock / benchmark：管道预喂可用
    const result = spawnAce(aceBin, ['create', outDir, '-t', 'app'], {
      spawnOpts: {
        encoding: 'utf8',
        timeout: timeoutMs,
        input: `\n\n1\n16\n${platformAnswer}\n2\n`
      }
    });
    return interpretCreateResult(result, outDir, platform, timeoutMs, aceBin);
  }

  // TTY 环境：透传交互（坑④：进入前打印完整题面预告+建议答案）
  console.log(`
即将进入 ace create 交互，共 6 题（建议答案加粗）：
  1. 项目名        回车（默认）
  2. bundleName    回车（默认）
  3. runtimeOS     1 = OpenHarmony（推荐）
  4. Compile SDK   输编号 16 后回车（= 26.0.0 最大项；文本输入，整串提交）
  5. 平台          ${platformAnswer} = ${platform}
  6. Framework     2 = CocoaPods（推荐；Native Manual 实测有问题）
`);
  let result = spawnAce(aceBin, ['create', outDir, '-t', 'app'], {
    spawnOpts: {
      stdio: ['inherit', 'inherit', 'inherit'],
      timeout: timeoutMs
    }
  });
  result = { ...result, stdout: '', stderr: '（TTY 透传模式：输出已直达终端）' };
  return interpretCreateResult(result, outDir, platform, timeoutMs, aceBin);
}

function interpretCreateResult(result, outDir, platform, timeoutMs, aceBin) {
  if (result.signal === 'SIGTERM' || result.error?.code === 'ETIMEDOUT') {
    return { ok: false, reason: `ace create 超时（>${timeoutMs}ms）被终止` };
  }
  if (result.error) {
    return { ok: false, reason: `ace 命令不可用（${result.error.message}）；请确认 ArkUI-X SDK toolchains 在 PATH 或以 --ace-bin 指定` };
  }
  if (result.status !== 0) {
    // 坑③：截获 ERR_USE_AFTER_CLOSE 崩溃，替换为人话
    const raw = `${result.stdout || ''}${result.stderr || ''}`;
    if (raw.includes('ERR_USE_AFTER_CLOSE')) {
      return { ok: false, reason: 'ace 交互在管道模式下崩溃（工具已知限制）——请在 TTY 终端运行本命令，或手动执行 ace create 后重跑（跳过 create）' };
    }
    const tail = (result.stderr || result.stdout || '').trim().split('\n').slice(-3).join(' | ');
    return { ok: false, reason: `ace create 失败（退出码 ${result.status}）${tail ? `：${tail}` : ''}` };
  }

  const shells = resolveShells(outDir);
  const wantAndroid = platform === 'both' || platform === 'android';
  const wantIos = platform === 'both' || platform === 'ios';
  const missing = [];
  if (wantAndroid && !existsSync(shells.android)) missing.push(`${shells.legacy ? '' : '.arkui-x/'}android`);
  if (wantIos && !existsSync(shells.ios)) missing.push(`${shells.legacy ? '' : '.arkui-x/'}ios`);
  if (missing.length > 0) {
    return { ok: false, reason: `ace create 退出码 0 但未检出所选平台壳 ${missing.join(' 与 ')}（scaffold 结构断言失败）` };
  }
  trimUnselectedShells(shells, platform);
  return { ok: true, sharedArktsDir: resolveSharedDir(outDir), legacy: shells.legacy };
}

/**
 * v1.1/R-6：按所选平台裁剪未选平台壳（platform=android 时移除 ios/，反之亦然）
 */
export function trimUnselectedShells(shells, platform) {
  if (platform === 'android') rmSync(shells.ios, { recursive: true, force: true });
  if (platform === 'ios') rmSync(shells.android, { recursive: true, force: true });
}

/** 归一共享 ArkTS 目录（候选序；均缺失时落到 entry 由迁移方创建） */
export function resolveSharedDir(outDir) {
  for (const candidate of SHARED_CANDIDATES) {
    if (existsSync(join(outDir, candidate))) return join(outDir, candidate);
  }
  return join(outDir, 'entry');
}

// ── SD28 根治：归档 scaffold 复用（零交互、确定性） ───

/** 归档内置默认值（make-scaffold-archive.js 组装锚，materialize 替换锚） */
export const ARCHIVE_DEFAULTS = { name: 'arkuixapp', bundle: 'com.example.arkuixapp' };

/**
 * 归档 scaffold 物化（SD28 根治）：复制归档 → 项目名/bundleName 变量替换 → java 包目录重组
 * → buildArkTS 环境路径注入 → platform 裁剪 → .projectInfo 重写 → compileSdk 断言。
 * 行为等价 ace create 26.0.0（标准答案：双平台/CocoaPods/OpenHarmony），零交互、确定性。
 * @param {{name?: string, bundle?: string, platform?: 'both'|'android'|'ios', ohpmPath?: string, arkuiXSdkPath?: string}} opts
 */
export function materializeFromArchive(archiveDir, outDir, opts = {}) {
  if (!existsSync(join(archiveDir, '.arkui-x'))) {
    return { ok: false, reason: `归档目录不合法（缺 .arkui-x/）: ${archiveDir}` };
  }
  const name = String(opts.name || ARCHIVE_DEFAULTS.name);
  const bundle = String(opts.bundle || ARCHIVE_DEFAULTS.bundle);
  if (!/^[a-z][a-z0-9_]*$/i.test(name)) return { ok: false, reason: `项目名非法（字母/数字/下划线，字母开头）: ${name}` };
  if (!/^[a-z][a-z0-9_.]*$/i.test(bundle)) return { ok: false, reason: `bundleName 非法（反向域名形态）: ${bundle}` };
  const platform = opts.platform || 'both';

  cpSync(archiveDir, outDir, { recursive: true, filter: (src) => !src.includes('xcuserdata') });

  // 变量替换（锚=归档默认值；覆盖 iOS 大写显示名形态）
  const AN = ARCHIVE_DEFAULTS.name;
  const AB = ARCHIVE_DEFAULTS.bundle;
  const newTail = bundle.split('.').at(-1);
  const oldTail = AB.split('.').at(-1);
  const TEXT_SUBS = [
    ['AppScope/app.json5'], ['AppScope/resources/base/element/string.json'], ['oh-package.json5'],
    ['.arkui-x/android/settings.gradle'], ['.arkui-x/android/app/src/main/res/values/strings.xml'],
    ['.arkui-x/android/app/src/main/AndroidManifest.xml'], ['.arkui-x/android/app/build.gradle'],
    ['.arkui-x/ios/app.xcodeproj/project.pbxproj'], ['.arkui-x/ios/app/AppDelegate.m'], ['.arkui-x/ios/app/Info.plist']
  ].map(([rel]) => join(outDir, rel));
  const javaDirs = ['.arkui-x/android/app/src/main/java', '.arkui-x/android/app/src/test/java', '.arkui-x/android/app/src/androidTest/java'].map((d) => join(outDir, d));
  const iosName = oldTail; // 归档 Info.plist 中的显示名= arkuixapp（小写形态首字母大写两处）
  for (const file of [...TEXT_SUBS, ...walkJava(javaDirs)]) {
    if (!existsSync(file)) continue;
    let s = readFileSync(file, 'utf8');
    s = s.split(AB).join(bundle).split(`${AB}:entry:EntryAbility:`).join(`${bundle}:entry:EntryAbility:`)
      .split(AN).join(name)
      .split(iosName.slice(0, 1).toUpperCase() + iosName.slice(1)).join(newTail.slice(0, 1).toUpperCase() + newTail.slice(1));
    writeFileSync(file, s);
  }

  // java 包目录重组（com/example/arkuixapp → 新 bundle 分包）
  const newParts = bundle.split('.');
  const oldParts = AB.split('.');
  for (const base of javaDirs) {
    const oldDir = join(base, ...oldParts);
    const newDir = join(base, ...newParts);
    if (!existsSync(oldDir)) continue;
    mkdirSync(newDir, { recursive: true });
    for (const f of readdirSync(oldDir)) {
      renameSync(join(oldDir, f), join(newDir, f));
    }
    // 清掉空旧目录链（保留 base；rmdirSync 空删语义——非空即抛错终止，防误删）
    let cur = oldDir;
    for (let i = 0; i < oldParts.length; i++) {
      try { rmdirSync(cur); } catch { break; }
      cur = join(cur, '..');
    }
  }

  // buildArkTS 环境路径注入（占位符 → 实际路径；未知则保留占位并提示）
  const envNote = [];
  const ohpm = opts.ohpmPath || '';
  const sdk = opts.arkuiXSdkPath || '';
  for (const rel of ['.arkui-x/android/buildArkTS', '.arkui-x/android/buildArkTS.bat', '.arkui-x/ios/buildArkTS.sh']) {
    const file = join(outDir, rel);
    if (!existsSync(file)) continue;
    let s = readFileSync(file, 'utf8');
    s = s.replaceAll('__PROJECT_PATH__', outDir);
    if (ohpm) s = s.replaceAll('__OHPM_PATH__', ohpm); else if (s.includes('__OHPM_PATH__')) envNote.push('ohpm 路径未检出（buildArkTS 保留占位符，编译前请手动改 ohpm_path）');
    if (sdk) s = s.replaceAll('__ARKUIX_SDK_PATH__', sdk); else if (s.includes('__ARKUIX_SDK_PATH__')) envNote.push('ArkUI-X SDK 路径未检出（buildArkTS 保留占位符，编译前请手动改 arkuiXSdkPath）');
    writeFileSync(file, s);
  }

  // platform 裁剪 + .projectInfo 重写
  const shells = resolveShells(outDir);
  trimUnselectedShells(shells, platform);
  writeFileSync(join(outDir, '.projectInfo'), JSON.stringify({
    projectTemplate: 'app', moduleInfo: [], abilityInfo: [],
    platforms: platform === 'both' ? ['android', 'ios'] : [platform]
  }, null, 2) + '\n');

  // 断言：归档固有 compileSdkVersion 26.0.0 在场（防归档被误改）
  const bp = readFileSync(join(outDir, 'build-profile.json5'), 'utf8');
  if (!/"compileSdkVersion"\s*:\s*"26\.0\.0"/.test(bp)) {
    return { ok: false, reason: '归档 build-profile.json5 的 compileSdkVersion 非 26.0.0（归档被改动？），拒绝物化' };
  }
  return { ok: true, sharedArktsDir: resolveSharedDir(outDir), legacy: false, fromArchive: true, envNote };
}

function walkJava(bases) {
  const out = [];
  for (const base of bases) {
    if (!existsSync(base)) continue;
    for (const root of [base, ...javaSubdirs(base)]) {
      for (const f of readdirSync(root)) {
        const full = join(root, f);
        if (full.endsWith('.java')) out.push(full);
      }
    }
  }
  return out;
}

function javaSubdirs(base) {
  const dirs = [];
  (function walk(dir) {
    for (const e of readdirSync(dir, { withFileTypes: true })) {
      if (e.isDirectory()) { const full = join(dir, e.name); dirs.push(full); walk(full); }
    }
  })(base);
  return dirs;
}
