import { spawnSync } from 'node:child_process';
import { spawnAce } from './ace-invoker.js';
import { realpathSync } from 'node:fs';

/** modify 可用门槛（proposal：ace modify 自 API 24 起提供） */
const MODIFY_API_THRESHOLD = 24;

/**
 * 环境检测（R-1/R-2/R-3，ADR-3；v1.1 增 arkui_x_sdk 检出）：
 * 主源=解析 `ace check` 输出（toolchains/Xcode 就绪状态 + ArkUI-X SDK 版本行）；
 * 补测=Gradle/JDK/CocoaPods 分项独立探测（AC-1.1 粒度）。
 * 检测不阻断骨架生成（环境仅决定验证范围）；例外：modify_available=false 且模式=modify
 * 由 CliEntry 拒绝（R-1 边界，退出码 4，零写）。
 *
 * @param {{aceBin?: string, run?: Function, platform?: string, aceCheckOutput?: string,
 *          env?: object}} options
 *   run(cmd, args) → {status, stdout} 注入用（测试）；缺省用 spawnSync
 */
export function detectEnvironment(options = {}) {
  const run = options.run || ((cmd, args) => spawnAce(cmd, args, { spawnOpts: { encoding: 'utf8', timeout: 15000 } }));
  const platform = options.platform || process.platform;

  const android = { ready: false, missing: [] };
  const ios = { ready: false, missing: [] };

  if (platform !== 'darwin') {
    ios.missing.push('需 macOS（iOS 编译环境仅可在 macOS 上就绪）');
  }

  // 主源：ace check（可注入输出或执行体）
  let checkText = null;
  const aceBin = options.aceBin || 'ace';
  let aceAvailable = false;
  if (options.aceCheckOutput !== undefined) {
    checkText = options.aceCheckOutput;
    aceAvailable = true;
  } else {
    const result = run(aceBin, ['check']);
    aceAvailable = !result.error && result.status === 0;
    if (aceAvailable && result.stdout) checkText = result.stdout;
  }
  if (checkText) {
    applyAceCheck(checkText, android, ios);
  }

  // 分项补测（AC-1.1 粒度）
  probe(android, 'Gradle', () => run('gradle', ['--version']));
  probe(android, 'JDK', () => run('java', ['-version']));
  if (platform === 'darwin') {
    probe(ios, 'Xcode', () => run('xcodebuild', ['-version']));
    probe(ios, 'CocoaPods', () => run('pod', ['--version']));
  }

  android.ready = android.missing.length === 0;
  ios.ready = ios.missing.length === 0;

  // v1.1：arkui_x_sdk 检出（detected/version/modify_available=API 24+ 门槛）
  const arkuiXSdk = detectArkuiXSdk({ aceBin, run, checkText, aceAvailable, options });
  return { android, ios, arkui_x_sdk: arkuiXSdk };
}

/**
 * ArkUI-X SDK 检出（TASK-7）：
 * - detected：ace 工具在场（ace check 可执行）
 * - version：ace check 版本行（如 "[√] ArkUI-X (ArkUI-X SDK version 26.0.0.38)" → 26.0.0.38）
 *   或 aceBin 路径中的版本目录段（如 .../ArkUI-X/Sdk/26.0.0/...）
 * - modify_available：版本归一后 major >= 24（"24"/"23" 两位与 "26.0.0" 三段式均按数字比较，
 *   禁止字符串直比）；无法判定版本时=false（保守）
 */
export function detectArkuiXSdk({ aceBin, run, checkText, aceAvailable, options }) {
  let version = '';
  if (checkText) {
    version = parseVersionFromCheck(checkText);
  }
  if (!version && aceBin && aceBin !== 'ace') {
    version = parseVersionFromPath(aceBin);
  }
  if (!version && aceAvailable && !options.aceCheckOutput) {
    // ace check --version 形态兜底（不计入 detected 判定）
    const result = run(aceBin, ['--version']);
    if (!result.error && result.status === 0 && result.stdout) {
      version = parseVersionFromCheck(result.stdout);
    }
  }
  const api = apiLevelOf(version);
  return {
    detected: aceAvailable,
    version,
    modify_available: api !== null && api >= MODIFY_API_THRESHOLD
  };
}

/** ace check 输出中的版本行解析：[√] ArkUI-X (ArkUI-X SDK version 26.0.0.38) */
export function parseVersionFromCheck(text) {
  for (const line of String(text || '').split('\n')) {
    if (!/ArkUI-X/i.test(line)) continue;
    const m = line.match(/version\s+v?(\d{2}(?:\.\d+){0,2})/i);
    if (m) return m[1];
  }
  return '';
}

/** ace 命令路径中的版本目录段：…/ArkUI-X/Sdk/26.0.0/arkui-x/toolchains/bin/ace → 26.0.0 */
export function parseVersionFromPath(aceBin) {
  let real = aceBin;
  try {
    real = realpathSync(aceBin);
  } catch {
    real = aceBin;
  }
  const m = real.match(/(\d{2}(?:\.\d+){0,2})/g);
  if (!m) return '';
  // 取最后一个形如版本目录的段（排除文件名中的零散数字由 \d{2} 起始约束）
  return m[m.length - 1] || '';
}

/** 版本归一比较（design 固化）：API <26 两位数字（"24"）与 API ≥26 三段式（"26.0.0"）统一取 major 数字比较 */
export function apiLevelOf(version) {
  if (!version || typeof version !== 'string') return null;
  const m = version.match(/^(\d{2})(?:\.\d+){0,2}$/);
  if (!m) return null;
  const major = Number(m[1]);
  return Number.isFinite(major) ? major : null;
}

function applyAceCheck(text, android, ios) {
  const lines = text.split('\n');
  const okMarked = (label) => lines.some((l) => l.includes('[√]') && l.includes(label));
  const badMarked = (label) => lines.some((l) => l.includes('[X]') && l.includes(label));
  if (okMarked('Android toolchains')) {
    removeFrom(android.missing, 'Android SDK');
  } else if (badMarked('Android toolchains') || text.includes('Android SDK is not installed')) {
    if (!android.missing.includes('Android SDK')) android.missing.push('Android SDK');
  }
  if (okMarked('Xcode')) {
    removeFrom(ios.missing, 'Xcode');
  } else if (badMarked('Xcode')) {
    if (!ios.missing.includes('Xcode')) ios.missing.push('Xcode');
  }
}

function probe(status, name, exec) {
  if (status.missing.includes(`需 macOS`)) return; // 平台不可用时分项不重复报
  let ok = false;
  try {
    const result = exec();
    ok = result.status === 0;
  } catch {
    ok = false;
  }
  if (!ok && !status.missing.includes(name)) status.missing.push(name);
  if (ok) removeFrom(status.missing, name);
}

function removeFrom(list, name) {
  const idx = list.indexOf(name);
  if (idx !== -1) list.splice(idx, 1);
}
