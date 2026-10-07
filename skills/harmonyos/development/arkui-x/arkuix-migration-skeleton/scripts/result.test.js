import { test } from 'node:test';
import assert from 'node:assert/strict';
import { renderJson, renderMarkdown, renderVerificationAssists } from './result.js';

function sample(platform = 'both') {
  return {
    schema_version: 1,
    mode: 'modify',
    platform,
    android_shell: '.arkui-x/android',
    ios_shell: '.arkui-x/ios',
    shared_arkts_dir: 'entry',
    environment: {
      android: { ready: true, missing: [] },
      ios: { ready: false, missing: ['CocoaPods'] },
      arkui_x_sdk: { detected: true, version: '26.0.0', modify_available: true }
    }
  };
}

test('SKRS-1 v1.1 renderJson：键序固定，platform 在场，environment 含 arkui_x_sdk', () => {
  const parsed = JSON.parse(renderJson(sample()));
  assert.deepEqual(Object.keys(parsed), [
    'schema_version', 'mode', 'platform', 'android_shell', 'ios_shell', 'shared_arkts_dir', 'environment']);
  assert.deepEqual(Object.keys(parsed.environment), ['android', 'ios', 'arkui_x_sdk']);
  assert.deepEqual(parsed.environment.arkui_x_sdk, { detected: true, version: '26.0.0', modify_available: true });
});

test('v1.1 renderJson：platform=android 时 ios_shell 不出现（条件输出）', () => {
  const parsed = JSON.parse(renderJson(sample('android')));
  assert.equal(parsed.platform, 'android');
  assert.ok(parsed.android_shell);
  assert.equal(parsed.ios_shell, undefined);
  const parsedIos = JSON.parse(renderJson(sample('ios')));
  assert.equal(parsedIos.android_shell, undefined);
  assert.ok(parsedIos.ios_shell);
});

test('SD25 renderJson：new 模式 migrated_modules 在场（键序固定、条目键序 name/target/files）；modify 不输出', () => {
  const withModules = { ...sample(), mode: 'new', migrated_modules: [
    { name: 'entry', target: 'entry', files: 79 },
    { name: 'common', target: 'common', files: 12 }
  ] };
  const parsed = JSON.parse(renderJson(withModules));
  assert.deepEqual(Object.keys(parsed), [
    'schema_version', 'mode', 'platform', 'android_shell', 'ios_shell', 'shared_arkts_dir', 'migrated_modules', 'environment']);
  assert.deepEqual(parsed.migrated_modules, [
    { name: 'entry', target: 'entry', files: 79 },
    { name: 'common', target: 'common', files: 12 }
  ]);
  const noModules = JSON.parse(renderJson(sample()));
  assert.equal(noModules.migrated_modules, undefined, 'modify（无迁入）不应输出该字段');
  const emptyModules = JSON.parse(renderJson({ ...sample(), migrated_modules: [] }));
  assert.equal(emptyModules.migrated_modules, undefined, '空数组同样不输出');
});

test('SD26 renderJson/Markdown：ace_warnings 非空沉淀（键序在 migrated_modules 后）+ 报告"编译前必办"段；空不输出', () => {
  const warn = "WARN: arkui-x project must delete the 'useNormalizedOHMUrl' Setting Items in build-profile.json5";
  const withWarn = { ...sample(), mode: 'modify', migrated_modules: [{ name: 'entry', target: 'entry', files: 3 }], ace_warnings: [warn] };
  const parsed = JSON.parse(renderJson(withWarn));
  assert.deepEqual(Object.keys(parsed), [
    'schema_version', 'mode', 'platform', 'android_shell', 'ios_shell', 'shared_arkts_dir',
    'migrated_modules', 'ace_warnings', 'environment']);
  assert.deepEqual(parsed.ace_warnings, [warn]);
  const md = renderMarkdown(withWarn, { aceWarnings: [warn] });
  assert.match(md, /ace 迁移提示（编译前必办/);
  assert.match(md, /useNormalizedOHMUrl/);
  assert.equal(JSON.parse(renderJson(sample())).ace_warnings, undefined, '无 WARN 不输出字段');
  const mdNoWarn = renderMarkdown(sample(), {});
  assert.doesNotMatch(mdNoWarn, /编译前必办/);
});

test('INV-4 renderJson 确定性：同输入两次渲染一致；missing 稳定排序', () => {
  const a = sample();
  a.environment.ios.missing = ['Xcode', 'CocoaPods'];
  const b = sample();
  b.environment.ios.missing = ['CocoaPods', 'Xcode'];
  assert.equal(renderJson(a), renderJson(b), '乱序 missing 应归一');
});

test('R-2 报告：环境未就绪标注补验（骨架不受影响）', () => {
  const md = renderMarkdown(sample(), {});
  assert.match(md, /iOS 环境未就绪，需在对应环境补验/);
  assert.match(md, /骨架文件已按所选平台生成，不受环境影响/);
  assert.match(md, /CocoaPods/);
});

test('v1.1 报告：平台选项与 ArkUI-X SDK 状态呈现', () => {
  const md = renderMarkdown(sample('android'), {});
  assert.match(md, /仅 Android/);
  assert.match(md, /ArkUI-X SDK/);
  assert.match(md, /检出（版本 26\.0\.0/);
  assert.match(md, /（未选，platform 不含 iOS）/);
});

test('R-3 验证辅助：仅就绪且所选平台生成（baseDir 拼接绝对路径）', () => {
  const assists = renderVerificationAssists(sample(), '/proj');
  assert.deepEqual(Object.keys(assists).sort(),
    ['verification/android-build.txt', 'verification/verify-android.sh']);
  assert.match(assists['verification/android-build.txt'], /cd \/proj\/\.arkui-x\/android/);
  assert.match(assists['verification/android-build.txt'], /gradlew assembleDebug/);
  assert.match(assists['verification/verify-android.sh'], /回填/);
  // platform=ios：android 就绪也不生成（未选平台）
  const iosOnly = renderVerificationAssists(sample('ios'), '/proj');
  assert.deepEqual(Object.keys(iosOnly), []);
});

test('R-6 报告：迁入统计呈现', () => {
  const md = renderMarkdown(sample(), { migration: { filesMoved: 12, ignored: ['oh_modules'] } });
  assert.match(md, /12 个文件已原样搬移/);
  assert.match(md, /oh_modules/);
});

test('v1.1 报告：实际改动文件清单呈现（modify 成功路径）', () => {
  const md = renderMarkdown(sample(), { changedFiles: ['.arkui-x/android/build.gradle'] });
  assert.match(md, /实际改动文件清单/);
  assert.match(md, /\.arkui-x\/android\/build\.gradle/);
});

test('报告零源码正文（渲染仅白名单字段）', () => {
  const md = renderMarkdown(sample(), {});
  assert.doesNotMatch(md, /struct Index|build\(\)|@Component/);
});
