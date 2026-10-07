import { test } from 'node:test';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const root = dirname(dirname(fileURLToPath(import.meta.url)));
const schema = JSON.parse(readFileSync(join(root, 'rules', 'schema.json'), 'utf8'));

const SKRS1_TOP_REQUIRED = ['schema_version', 'mode', 'platform', 'shared_arkts_dir', 'environment'];
const PLATFORM_REQUIRED = ['ready', 'missing'];
const ARKUIX_SDK_REQUIRED = ['detected', 'version', 'modify_available'];

test('SKRS-1 v1.1 顶层字段齐备且必填（platform 必填；壳字段条件必填不在 required）', () => {
  const props = schema.properties;
  for (const field of SKRS1_TOP_REQUIRED) {
    if (!(field in props)) throw new Error(`缺少顶层字段: ${field}`);
    if (!schema.required.includes(field)) throw new Error(`${field} 应为必填`);
  }
  if (schema.required.includes('android_shell') || schema.required.includes('ios_shell')) {
    throw new Error('壳字段应为条件必填（allOf/if-then），不在顶层 required');
  }
  for (const field of ['android_shell', 'ios_shell']) {
    if (!(field in props)) throw new Error(`缺少字段定义: ${field}`);
  }
});

test('mode 枚举为 modify/new', () => {
  const pm = schema.properties.mode;
  if (JSON.stringify(pm.enum) !== JSON.stringify(['modify', 'new'])) {
    throw new Error(`mode 枚举不符: ${JSON.stringify(pm.enum)}`);
  }
});

test('v1.1 platform 枚举为 both/android/ios', () => {
  const pf = schema.properties.platform;
  if (JSON.stringify(pf.enum) !== JSON.stringify(['both', 'android', 'ios'])) {
    throw new Error(`platform 枚举不符: ${JSON.stringify(pf.enum)}`);
  }
});

test('v1.1 壳字段条件必填（allOf if-then 两分支）', () => {
  const branches = schema.allOf || [];
  if (branches.length !== 2) throw new Error(`应有两个条件必填分支: ${branches.length}`);
  const androidBranch = branches.find((b) => (b.then?.required || []).includes('android_shell'));
  const iosBranch = branches.find((b) => (b.then?.required || []).includes('ios_shell'));
  if (!androidBranch) throw new Error('缺 android_shell 条件分支');
  if (!iosBranch) throw new Error('缺 ios_shell 条件分支');
  if (JSON.stringify(androidBranch.if.properties.platform.enum) !== JSON.stringify(['both', 'android'])) {
    throw new Error('android_shell 分支条件应为 platform ∈ {both, android}');
  }
  if (JSON.stringify(iosBranch.if.properties.platform.enum) !== JSON.stringify(['both', 'ios'])) {
    throw new Error('ios_shell 分支条件应为 platform ∈ {both, ios}');
  }
});

test('environment 结构 {android, ios, arkui_x_sdk}', () => {
  const env = schema.properties.environment;
  for (const key of ['android', 'ios']) {
    if (!(key in env.properties)) throw new Error(`environment 缺少 ${key}`);
    if (!env.required.includes(key)) throw new Error(`environment.${key} 应为必填`);
    const platform = env.properties[key].properties
      || schema.definitions[env.properties[key].$ref.split('/').pop()].properties;
    for (const f of PLATFORM_REQUIRED) {
      if (!(f in platform)) throw new Error(`environment.${key} 缺少 ${f}`);
    }
    if (platform.ready.type !== 'boolean') throw new Error('ready 应为 boolean');
    if (platform.missing.type !== 'array') throw new Error('missing 应为 array');
  }
  if (!env.required.includes('arkui_x_sdk')) throw new Error('environment.arkui_x_sdk 应为必填（v1.1）');
  const sdkDef = schema.definitions[env.properties.arkui_x_sdk.$ref.split('/').pop()];
  for (const f of ARKUIX_SDK_REQUIRED) {
    if (!(f in sdkDef.properties)) throw new Error(`arkui_x_sdk 缺少 ${f}`);
    if (!sdkDef.required.includes(f)) throw new Error(`arkui_x_sdk.${f} 应为必填`);
  }
  if (sdkDef.properties.detected.type !== 'boolean') throw new Error('arkui_x_sdk.detected 应为 boolean');
  if (sdkDef.properties.modify_available.type !== 'boolean') throw new Error('arkui_x_sdk.modify_available 应为 boolean');
});

test('schema_version 常量 1', () => {
  if (schema.properties.schema_version.const !== 1) throw new Error('schema_version 应为常量 1');
});
