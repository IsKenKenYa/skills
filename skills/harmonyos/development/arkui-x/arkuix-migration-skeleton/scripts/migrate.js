import { readdirSync, readFileSync, writeFileSync, mkdirSync, copyFileSync, existsSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { join, dirname } from 'node:path';

/** 忽略清单（design 风险表：特殊文件处理，SKILL.md 声明） */
const IGNORED_NAMES = new Set(['.hvigor', 'build', 'oh_modules', 'node_modules', '.git', '.idea', '.clangd', '.arkui-x']);

/**
 * 模块发现（SD5 r3 修订）：根 build-profile.json5 的 modules[].srcPath 驱动，
 * 支持业务名 entry（如 veditor）与 products/default 布局；解析失败回退经典 entry/src/main。
 * @returns {Array<{name: string, path: string}>} 模块 src/main 清单（排序确定）
 */
export function discoverModuleMains(root) {
  const mains = [];
  const bp = join(root, 'build-profile.json5');
  let parseError = null;
  if (existsSync(bp)) {
    try {
      const doc = JSON.parse(looseJson5(readFileSync(bp, 'utf8')));
      for (const m of doc?.modules ?? []) {
        if (!m || typeof m.srcPath !== 'string') continue;
        const p = join(root, m.srcPath, 'src', 'main');
        if (existsSync(p)) mains.push({ name: String(m.name ?? m.srcPath), path: p });
      }
    } catch (err) {
      parseError = err.message; // SD12：解析失败显式透出（不再静默吞掉）
    }
  }
  if (mains.length === 0) {
    const classic = join(root, 'entry', 'src', 'main');
    if (existsSync(classic)) mains.push({ name: 'entry', path: classic });
  }
  mains.sort((a, b) => a.name.localeCompare(b.name));
  mains.parseError = parseError;
  return mains;
}

/** 宽松 JSON5：剥注释、无引号键加引号、单引号串转双引号、去尾逗号
 * （SD12/r3：官方样例 build-profile 无引号键为常态写法，严格 JSON.parse 必败） */
function looseJson5(text) {
  const stripped = stripJsonComments(text);
  return stripped
    .replace(/([{,]\s*)([A-Za-z_$][A-Za-z0-9_$]*)(\s*:)/g, '$1"$2"$3') // 无引号键
    .replace(/'([^'\\]*)'/g, '"$1"')                                     // 单引号串
    .replace(/,(\s*[}\]])/g, '$1');                                      // 尾逗号
}

function stripJsonComments(text) {
  let out = '';
  let inBlock = false;
  let quote = null;
  for (let i = 0; i < text.length; i++) {
    const ch = text[i];
    const next = text[i + 1];
    if (inBlock) {
      if (ch === '*' && next === '/') { inBlock = false; i += 1; out += '  '; }
      else out += ch === '\n' ? '\n' : ' ';
      continue;
    }
    if (quote) {
      out += ch;
      if (ch === '\\') { out += next ?? ''; i += 1; continue; }
      if (ch === quote) quote = null;
      continue;
    }
    if (ch === '/' && next === '/') { while (i < text.length && text[i] !== '\n') i += 1; out += '\n'; continue; }
    if (ch === '/' && next === '*') { inBlock = true; i += 1; out += '  '; continue; }
    if (ch === '"' || ch === "'") { quote = ch; out += ch; continue; }
    out += ch;
  }
  return out;
}

/**
 * 源码迁入（R-6，INV-3；SD5 r3 修订：多模块布局支持）：
 * - 逐模块将 <srcPath>/src/main/** 原样搬移至 <outDir>/<moduleName>/src/main
 *   （entry 模块即 scaffold 的共享 ArkTS 目录，落点与其天然一致；其余模块与 entry 平级）
 * - 搬移=复制（源工程保留原件）；不改写内容（哈希前后一致）
 * - 零迁入 = 显式失败（SD5：不再静默伪成功），由调用方以退出码 2 终止
 *
 * @param {string} srcRoot 源工程根
 * @param {string} outDir new 模式输出目录（模块迁入基准）
 * @returns {{filesMoved: number, modules: Array<{name, files}>, ignored: string[],
 *            hashes: Map<string, string>, ok: boolean, reason?: string}}
 */
export function migrateSources(srcRoot, outDir) {
  const modules = discoverModuleMains(srcRoot);
  if (modules.length === 0) {
    return { filesMoved: 0, modules: [], ignored: [], hashes: new Map(), ok: false,
      reason: '源工程无可迁入源码（未发现任何模块的 src/main：build-profile modules 与经典 entry 布局均缺失）' };
  }
  const ignored = [];
  const hashes = new Map();
  const perModule = [];
  let filesMoved = 0;
  // SD24（r5）：仅名为 entry 的模块 → 合入 scaffold 的 entry/（覆盖 Hello World 模板）。
  // 无 entry 命名模块时不猜测主模块（业务名工程保持模块名平级目录，scaffold entry/ 保留模板），
  // shared_arkts_dir 如实指向内容实际所在（由调用方读取 modules[].target 判断）。
  const primaryMod = modules.find((m) => m.name === 'entry');
  for (const mod of modules) {
    const files = [];
    collect(mod.path, mod.path, files, ignored);
    files.sort();
    const targetDir = mod === primaryMod ? 'entry' : mod.name;
    for (const rel of files) {
      const from = join(mod.path, rel);
      const to = join(outDir, targetDir, 'src', 'main', rel);
      mkdirSync(dirname(to), { recursive: true });
      copyFileSync(from, to);
      hashes.set(`${mod.name}:${rel}`, hashOf(from));
      filesMoved += 1;
    }
    perModule.push({ name: mod.name, files: files.length, target: targetDir });
  }
  ignored.sort();
  if (filesMoved === 0) {
    return { filesMoved: 0, modules: perModule, ignored, hashes, ok: false,
      reason: '迁移清单为空（各模块 src/main 下无文件或全部被忽略清单排除）' };
  }
  return { filesMoved, modules: perModule, ignored, hashes, ok: true };
}

/** INV-3 校验：目标文件集合与内容哈希同源一致 */
export function verifyMigration(srcRoot, outDir, migration) {
  if (!migration || !migration.ok) return { ok: false, reason: (migration && migration.reason) || '迁移统计缺失' };
  const targetMap = new Map((migration.modules ?? []).map((m) => [m.name, m.target ?? m.name]));
  for (const [key, expectedHash] of migration.hashes) {
    const [modName, ...rest] = key.split(':');
    const targetDir = targetMap.get(modName) ?? modName;
    const to = join(outDir, targetDir, 'src', 'main', rest.join(':'));
    if (!existsSync(to)) return { ok: false, reason: `迁入缺失: ${key}` };
    if (hashOf(to) !== expectedHash) return { ok: false, reason: `内容被改写: ${key}` };
  }
  return { ok: true };
}

function collect(root, dir, files, ignored) {
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    if (IGNORED_NAMES.has(entry.name)) {
      ignored.push(entry.name);
      continue;
    }
    const full = join(dir, entry.name);
    if (entry.isDirectory()) {
      collect(root, full, files, ignored);
    } else if (entry.isFile()) {
      files.push(full.slice(root.length + 1));
    }
  }
}

function hashOf(file) {
  return createHash('sha256').update(readFileSync(file)).digest('hex');
}
