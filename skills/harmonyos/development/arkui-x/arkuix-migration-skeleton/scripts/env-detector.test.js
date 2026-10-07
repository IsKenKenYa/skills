import { test } from 'node:test';
import assert from 'node:assert/strict';
import { detectEnvironment, parseVersionFromCheck, parseVersionFromPath, apiLevelOf } from './env-detector.js';

function runOf(checkText) {
  return (cmd, args) => {
    if (args[0] === 'check') return { status: 0, stdout: checkText };
    if (cmd === 'gradle' || cmd === 'java' || cmd === 'xcodebuild' || cmd === 'pod') return { status: 0, stdout: 'ok' };
    return { status: 1, stdout: '' };
  };
}

test('VM-1/R-1 arkui_x_sdk：ace check 版本行检出 + API 24+ 门槛判定（26.0.0 → 可用）', () => {
  const env = detectEnvironment({
    run: runOf('[√] ArkUI-X (ArkUI-X SDK version 26.0.0.38)\n[√] Android toolchains\n[√] Xcode\n'),
    platform: 'darwin'
  });
  assert.equal(env.arkui_x_sdk.detected, true);
  assert.equal(env.arkui_x_sdk.version, '26.0.0');
  assert.equal(env.arkui_x_sdk.modify_available, true);
});

test('R-1 低版本（23）→ modify_available=false', () => {
  const env = detectEnvironment({
    run: runOf('[√] ArkUI-X (ArkUI-X SDK version 23)\n'),
    platform: 'darwin'
  });
  assert.equal(env.arkui_x_sdk.version, '23');
  assert.equal(env.arkui_x_sdk.modify_available, false);
});

test('R-1 版本归一比较：两位 "24" 与三段式 "26.0.0" 均按数字比较（禁止字符串直比）', () => {
  assert.equal(apiLevelOf('24'), 24);
  assert.equal(apiLevelOf('26.0.0'), 26);
  assert.equal(apiLevelOf('23'), 23);
  assert.equal(apiLevelOf(''), null);
  assert.equal(apiLevelOf('abc'), null);
  assert.equal(apiLevelOf('2.6'), null, '两位起始约束');
});

test('R-1 ace check 输出解析：ArkUI-X 版本行优先（不受其他版本行干扰）', () => {
  const text = [
    '[√] OpenHarmony toolchains - develop for OpenHarmony devices (OpenHarmony SDK version 26.0.0.25)',
    '[√] ArkUI-X (ArkUI-X SDK version 26.0.0.38)',
    '[√] Android toolchains - develop for Android devices (Android SDK version 35.0.0)'
  ].join('\n');
  assert.equal(parseVersionFromCheck(text), '26.0.0');
});

test('R-1 aceBin 路径版本段解析兜底：…/ArkUI-X/Sdk/26.0.0/arkui-x/toolchains/bin/ace → 26.0.0', () => {
  assert.equal(parseVersionFromPath('/Users/x/Library/ArkUI-X/Sdk/26.0.0/arkui-x/toolchains/bin/ace'), '26.0.0');
  assert.equal(parseVersionFromPath('/opt/arkui-x-sdk-23/bin/ace'), '23');
});

test('R-1 ace 不可用 → detected=false 且 modify_available=false（保守）', () => {
  const env = detectEnvironment({
    run: () => ({ status: 1, stdout: '', error: { code: 'ENOENT' } }),
    platform: 'darwin'
  });
  assert.equal(env.arkui_x_sdk.detected, false);
  assert.equal(env.arkui_x_sdk.modify_available, false);
  assert.equal(env.android.ready, false);
  assert.equal(env.ios.ready, false);
});

test('R-1/R-2 环境检测结构：android/ios 分项 + 非 macOS 时 ios 注明需 macOS', () => {
  const env = detectEnvironment({ run: runOf(''), platform: 'linux' });
  assert.ok(env.ios.missing.some((m) => m.includes('需 macOS')));
  assert.equal(env.ios.ready, false);
  assert.ok(Array.isArray(env.android.missing));
});
