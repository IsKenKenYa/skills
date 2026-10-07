import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, mkdirSync, writeFileSync, rmSync, chmodSync, existsSync, readdirSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { checkOutputDir, decideOnNonEmpty, createScaffold } from './scaffold.js';
const SKILL_ROOT = join(dirname(fileURLToPath(import.meta.url)), '..');
import { migrateSources, verifyMigration } from './migrate.js';

/** mock ace create（r3：6 题交互仿真 + .arkui-x 真实布局） */
function makeMockCreateAce(root) {
  const dir = join(root, 'mock-bin');
  mkdirSync(dir, { recursive: true });
  const file = join(dir, 'ace');
  writeFileSync(file, `#!/usr/bin/env node
const { mkdirSync, writeFileSync } = require('node:fs');
const { join } = require('node:path');
let input = '';
process.stdin.on('data', (d) => { input += d; });
process.stdin.on('end', () => {
  if (input.split('\\n').length < 6) {
    console.log('? Please select the Complie SDk (1: 10; 2: 11; 3: 12; 14: 23; 16: 26.0.0): ');
    process.exit(1);
  }
  const out = process.argv[3];
  mkdirSync(join(out, '.arkui-x/android/app'), { recursive: true });
  writeFileSync(join(out, '.arkui-x/android/build.gradle'), '// gradle\\n');
  mkdirSync(join(out, '.arkui-x/ios/app'), { recursive: true });
  mkdirSync(join(out, 'entry/src/main'), { recursive: true });
  console.log('create success');
});
`, 'utf8');
  chmodSync(file, 0o755);
  return file;
}

function makeSourceProject() {
  const root = mkdtempSync(join(tmpdir(), 'f1-migrate-'));
  const files = {
    'entry/src/main/module.json5': '{"module":{"name":"entry"}}\n',
    'entry/src/main/ets/Index.ets': '@Entry\n@Component\nstruct Index {}\n',
    'entry/src/main/ets/pages/Detail.ets': '@Component\nstruct Detail {}\n',
    'entry/src/main/resources/base/media/icon.png': 'binary-ish\n',
    'entry/src/main/oh_modules/dep/index.ets': 'should-not-migrate\n',
    'AppScope/app.json5': '{}\n'
  };
  for (const [rel, content] of Object.entries(files)) {
    const file = join(root, rel);
    mkdirSync(dirname2(file), { recursive: true });
    writeFileSync(file, content, 'utf8');
  }
  return root;
}

function dirname2(p) {
  const idx = p.lastIndexOf('/');
  return idx === -1 ? '.' : p.slice(0, idx);
}

test('R-7 checkOutputDir：不存在/空/非空 三态', () => {
  const root = mkdtempSync(join(tmpdir(), 'f1-scaffold-'));
  const absent = join(root, 'a');
  const empty = join(root, 'b');
  mkdirSync(empty);
  const nonEmpty = join(root, 'c');
  mkdirSync(nonEmpty);
  writeFileSync(join(nonEmpty, 'x.txt'), 'x');
  assert.deepEqual(checkOutputDir(absent), { exists: false, nonEmpty: false });
  assert.deepEqual(checkOutputDir(empty), { exists: true, nonEmpty: false });
  assert.deepEqual(checkOutputDir(nonEmpty), { exists: true, nonEmpty: true });
  rmSync(root, { recursive: true, force: true });
});

test('R-7 decideOnNonEmpty：跳过/覆盖/中止；无效应答返回 null（重新询问）', () => {
  assert.equal(decideOnNonEmpty('s'), 'skip');
  assert.equal(decideOnNonEmpty('y'), 'overwrite');
  assert.equal(decideOnNonEmpty('q'), 'abort');
  assert.equal(decideOnNonEmpty('x'), null, '无效应答应返回 null 由调用方重新询问');
  assert.equal(decideOnNonEmpty('maybe'), null);
});

test('SD3/SD6：mock ace create（6 题仿真+菜单发现）→ .arkui-x/{android,ios} + entry 断言', () => {
  const root = mkdtempSync(join(tmpdir(), 'f1-scaffold-'));
  const ace = makeMockCreateAce(root);
  const outDir = join(root, 'out-project');
  const result = createScaffold(outDir, { aceBin: ace });
  assert.equal(result.ok, true, result.reason);
  assert.ok(existsSync(join(outDir, '.arkui-x', 'android')), 'SD3：壳在 .arkui-x/ 下');
  assert.ok(existsSync(join(outDir, '.arkui-x', 'ios')));
  assert.equal(result.sharedArktsDir, join(outDir, 'entry'));
  assert.equal(result.legacy, false);
  rmSync(root, { recursive: true, force: true });
});

test('SD4：scaffold 已在场 → 跳过 create（假 aceBin 不可用仍成功）', () => {
  const root = mkdtempSync(join(tmpdir(), 'f1-scaffold-'));
  const outDir = join(root, 'pre-made');
  mkdirSync(join(outDir, '.arkui-x', 'android'), { recursive: true });
  mkdirSync(join(outDir, '.arkui-x', 'ios'), { recursive: true });
  mkdirSync(join(outDir, 'entry', 'src', 'main'), { recursive: true });
  const result = createScaffold(outDir, { aceBin: '/no/such/ace' });
  assert.equal(result.ok, true, result.reason);
  assert.equal(result.skippedCreate, true, 'SD4：在场即跳过 ace create');
  rmSync(root, { recursive: true, force: true });
});

test('v1.1/R-6 createScaffold：按所选平台裁剪未选平台壳（.arkui-x 布局）', () => {
  const rootA = mkdtempSync(join(tmpdir(), 'f1-scaffold-'));
  const aceA = makeMockCreateAce(rootA);
  const outA = join(rootA, 'out-android');
  createScaffold(outA, { aceBin: aceA, platform: 'android' });
  assert.ok(existsSync(join(outA, '.arkui-x', 'android')), 'android 壳在场');
  assert.ok(!existsSync(join(outA, '.arkui-x', 'ios')), 'ios 壳应被裁剪');

  const rootI = mkdtempSync(join(tmpdir(), 'f1-scaffold-'));
  const aceI = makeMockCreateAce(rootI);
  const outI = join(rootI, 'out-ios');
  createScaffold(outI, { aceBin: aceI, platform: 'ios' });
  assert.ok(existsSync(join(outI, '.arkui-x', 'ios')), 'ios 壳在场');
  assert.ok(!existsSync(join(outI, '.arkui-x', 'android')), 'android 壳应被裁剪');

  rmSync(rootA, { recursive: true, force: true });
  rmSync(rootI, { recursive: true, force: true });
});

test('createScaffold：ace create 失败 → 失败原因', () => {
  const root = mkdtempSync(join(tmpdir(), 'f1-scaffold-'));
  const result = createScaffold(join(root, 'o'), { aceBin: '/no/such/ace' });
  assert.equal(result.ok, false);
  assert.match(result.reason, /ace 命令不可用/);
  rmSync(root, { recursive: true, force: true });
});

test('INV-3 migrateSources（新 API）：entry 模块迁至 <out>/entry/src/main + 哈希一致 + oh_modules 排除', () => {
  const srcRoot = makeSourceProject();
  const outDir = mkdtempSync(join(tmpdir(), 'f1-out-'));
  const migration = migrateSources(srcRoot, outDir);

  assert.equal(migration.ok, true, migration.reason);
  assert.equal(migration.filesMoved, 4, 'module.json5 + 2 ets + 1 resource');
  assert.deepEqual(migration.modules, [{ name: 'entry', files: 4, target: 'entry' }]);
  for (const rel of ['module.json5', 'ets/Index.ets', 'ets/pages/Detail.ets', 'resources/base/media/icon.png']) {
    assert.ok(existsSync(join(outDir, 'entry', 'src', 'main', rel)), `缺失 ${rel}`);
  }
  assert.ok(!existsSync(join(outDir, 'entry', 'src', 'main', 'oh_modules')), 'oh_modules 不得迁入');

  const verification = verifyMigration(srcRoot, outDir, migration);
  assert.equal(verification.ok, true, verification.reason);
  rmSync(srcRoot, { recursive: true, force: true });
  rmSync(outDir, { recursive: true, force: true });
});

test('SD5：多模块（业务名 entry + feature）按 build-profile modules 逐模块迁入', () => {
  const srcRoot = mkdtempSync(join(tmpdir(), 'f1-multi-'));
  const files = {
    'build-profile.json5': '{ "modules": [{ "name": "entry", "srcPath": "./entry" }, { "name": "feature", "srcPath": "./feature" }] }\n',
    'entry/src/main/module.json5': '{}\n',
    'entry/src/main/ets/Index.ets': 'struct I {}\n',
    'feature/src/main/module.json5': '{}\n',
    'feature/src/main/ets/Feature.ets': 'struct F {}\n'
  };
  for (const [rel, content] of Object.entries(files)) {
    const file = join(srcRoot, rel);
    mkdirSync(join(file, '..'), { recursive: true });
    writeFileSync(file, content, 'utf8');
  }
  const outDir = mkdtempSync(join(tmpdir(), 'f1-multi-out-'));
  const migration = migrateSources(srcRoot, outDir);
  assert.equal(migration.ok, true, migration.reason);
  assert.equal(migration.filesMoved, 4);
  assert.ok(existsSync(join(outDir, 'entry', 'src', 'main', 'ets', 'Index.ets')));
  assert.ok(existsSync(join(outDir, 'feature', 'src', 'main', 'ets', 'Feature.ets')), 'SD5：feature 模块迁入（此前零迁入伪成功）');
  assert.equal(verifyMigration(srcRoot, outDir, migration).ok, true);
  rmSync(srcRoot, { recursive: true, force: true });
  rmSync(outDir, { recursive: true, force: true });
});

test('INV-3 verifyMigration：内容被改写 → 校验失败', () => {
  const srcRoot = makeSourceProject();
  const outDir = mkdtempSync(join(tmpdir(), 'f1-out-'));
  const migration = migrateSources(srcRoot, outDir);
  writeFileSync(join(outDir, 'entry', 'src', 'main', 'ets', 'Index.ets'), 'tampered\n', 'utf8');
  const verification = verifyMigration(srcRoot, outDir, migration);
  assert.equal(verification.ok, false);
  assert.match(verification.reason, /内容被改写/);
  rmSync(srcRoot, { recursive: true, force: true });
  rmSync(outDir, { recursive: true, force: true });
});

test('SD5：零迁入 → ok=false 显式失败（不再静默伪成功）', () => {
  const srcRoot = mkdtempSync(join(tmpdir(), 'f1-migrate-'));
  const outDir = mkdtempSync(join(tmpdir(), 'f1-out-'));
  const migration = migrateSources(srcRoot, outDir);
  assert.equal(migration.filesMoved, 0);
  assert.equal(migration.ok, false, 'SD5：零迁入必须显式失败');
  assert.match(migration.reason, /无可迁入源码/);
  rmSync(srcRoot, { recursive: true, force: true });
  rmSync(outDir, { recursive: true, force: true });
});

// ── SD28 根治：归档 scaffold 物化 ───
import { materializeFromArchive, ARCHIVE_DEFAULTS } from './scaffold.js';
import { readFileSync as rf, existsSync as ex, rmSync as rm2, readdirSync as rd } from 'node:fs';

test('SD28 materialize：变量替换（项目名/bundleName/iOS 显示名）+ java 包目录重组 + 双平台保留', () => {
  const root = mkdtempSync(join(tmpdir(), 'f1-arch-'));
  const archive = join(SKILL_ROOT, 'assets', 'scaffold-26.0.0');
  const out = join(root, 'out');
  const r = materializeFromArchive(archive, out, { name: 'myapp', bundle: 'com.demo.myapp', platform: 'both', ohpmPath: '/opt/ohpm', arkuiXSdkPath: '/opt/arkui-x' });
  assert.equal(r.ok, true, r.reason);
  assert.equal(rf(join(out, 'AppScope/app.json5'), 'utf8').includes('"bundleName": "com.demo.myapp"'), true);
  assert.equal(rf(join(out, 'oh-package.json5'), 'utf8').includes('"name": "myapp"'), true);
  assert.equal(ex(join(out, '.arkui-x/android/app/src/main/java/com/demo/myapp/EntryEntryAbilityActivity.java')), true, 'java 包目录按新 bundle 重组');
  assert.equal(ex(join(out, '.arkui-x/android/app/src/main/java/com/example/arkuixapp')), false, '旧包目录清除');
  assert.match(rf(join(out, '.arkui-x/android/buildArkTS'), 'utf8'), /project_path=".*out"/, '环境路径注入');
  assert.equal(rf(join(out, '.arkui-x/android/buildArkTS'), 'utf8').includes('__OHPM_PATH__'), false);
  assert.equal(ex(join(out, '.arkui-x/android')), true, '双平台保留 android');
  assert.equal(ex(join(out, '.arkui-x/ios')), true, '双平台保留 ios');
  assert.match(rf(join(out, 'build-profile.json5'), 'utf8'), /"compileSdkVersion": "26\.0\.0"/, 'SDK 固定 26.0.0');
  assert.deepEqual(JSON.parse(rf(join(out, '.projectInfo'), 'utf8')).platforms, ['android', 'ios']);
  rm2(root, { recursive: true, force: true });
});

test('SD28 materialize：platform=ios 裁剪 android 壳 + .projectInfo 重写；非法归档拒绝', () => {
  const root = mkdtempSync(join(tmpdir(), 'f1-arch-'));
  const archive = join(SKILL_ROOT, 'assets', 'scaffold-26.0.0');
  const out = join(root, 'out');
  const r = materializeFromArchive(archive, out, { platform: 'ios' });
  assert.equal(r.ok, true, r.reason);
  assert.equal(ex(join(out, '.arkui-x/android')), false, 'ios-only 裁剪 android');
  assert.equal(ex(join(out, '.arkui-x/ios')), true);
  assert.deepEqual(JSON.parse(rf(join(out, '.projectInfo'), 'utf8')).platforms, ['ios']);
  assert.match(rf(join(out, '.arkui-x/ios/buildArkTS.sh'), 'utf8'), /__OHPM_PATH__/, '未提供 ohpm 路径→保留占位');
  assert.ok((r.envNote || []).some((n) => n.includes('ohpm')), 'envNote 提示占位符');
  // 非法归档目录
  const bad = materializeFromArchive(join(root, 'no-such'), join(root, 'o2'), {});
  assert.equal(bad.ok, false);
  // 非法项目名
  const badName = materializeFromArchive(archive, join(root, 'o3'), { name: '9bad name' });
  assert.equal(badName.ok, false);
  rm2(root, { recursive: true, force: true });
});
