import { existsSync, readdirSync, statSync } from 'node:fs';
import { homedir } from 'node:os';
import { join } from 'node:path';

/**
 * SDK 探测（ADR-5）：候选序（design 固化）
 * 1. 显式参数（--sdk-path，视同确认）
 * 2. 环境变量 OH_SDK_DIR / OHOS_SDK_HOME / DEVECO_SDK_HOME
 * 3. 平台默认安装位置（macOS/Windows/Linux 常规路径，取 ets/api 在场的最新版本）
 */
export function detectSdkCandidates(explicitPath) {
  const candidates = [];
  if (explicitPath) {
    candidates.push({ path: explicitPath, origin: 'explicit' });
    return candidates;
  }
  for (const envVar of ['OH_SDK_DIR', 'OHOS_SDK_HOME', 'DEVECO_SDK_HOME']) {
    if (process.env[envVar]) {
      candidates.push({ path: process.env[envVar], origin: `env:${envVar}` });
    }
  }
  const home = homedir();
  const defaultRoots = [
    join(home, 'Library', 'OpenHarmony', 'Sdk'),
    join(home, 'AppData', 'Local', 'OpenHarmony', 'Sdk'),
    join(home, '.openharmony', 'sdk'),
    join(home, 'Library', 'Huawei', 'Sdk')
  ];
  for (const root of defaultRoots) {
    if (!existsSync(root)) continue;
    let versions = [];
    try {
      versions = readdirSync(root).filter((v) => isValidSdkDir(join(root, v))).sort();
    } catch {
      continue;
    }
    for (const v of versions) candidates.push({ path: join(root, v), origin: `default:${root}` });
  }
  return candidates;
}

/** 目录有效性校验（R-15）：含 ets/api 且存在 @ohos.*.d.ts */
export function validateSdkDir(path) {
  try {
    const stat = statSync(path);
    if (!stat.isDirectory()) return { ok: false, reason: '不是目录' };
  } catch {
    return { ok: false, reason: '目录不存在或不可读' };
  }
  // 允许直接指到 SDK 根或其 ets/api 父级
  const apiDir = resolveApiDir(path);
  if (!apiDir) {
    return { ok: false, reason: '目录中未找到 ets/api 的 @ohos.*.d.ts（应为 OpenHarmony SDK 根目录）' };
  }
  return { ok: true, apiDir };
}

export function resolveApiDir(path) {
  const tries = [
    join(path, 'ets', 'api'),
    join(path, 'api')
  ];
  for (const dir of tries) {
    if (!existsSync(dir)) continue;
    try {
      const hasOhos = readdirSync(dir).some((f) => f.startsWith('@ohos.') && f.endsWith('.d.ts'));
      if (hasOhos) return dir;
    } catch {
      continue;
    }
  }
  return null;
}

function isValidSdkDir(path) {
  return resolveApiDir(path) !== null;
}

export function sdkVersionOf(path) {
  const parts = path.split('/');
  return parts[parts.length - 1] || 'unknown';
}
