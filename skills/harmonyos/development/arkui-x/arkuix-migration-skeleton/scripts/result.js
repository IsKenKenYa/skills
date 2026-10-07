import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const SKILL_ROOT = dirname(dirname(fileURLToPath(import.meta.url)));

function wantsAndroid(platform) {
  return platform === 'both' || platform === 'android';
}

function wantsIos(platform) {
  return platform === 'both' || platform === 'ios';
}

/**
 * SkeletonResult JSON 渲染（SKRS-1 v1.1；键序固定保证确定性 INV-4；壳字段按平台条件输出）。
 * 路径统一为相对路径（spec：modify 相对工程根（.arkui-x/android、entry）、new 相对输出目录（android、…））。
 */
export function renderJson(result) {
  const ordered = {
    schema_version: result.schema_version,
    mode: result.mode,
    platform: result.platform,
    ...(wantsAndroid(result.platform) ? { android_shell: result.android_shell } : {}),
    ...(wantsIos(result.platform) ? { ios_shell: result.ios_shell } : {}),
    shared_arkts_dir: result.shared_arkts_dir,
    // SD25（r6）：new 模式如实记录各模块落点（SKRS-1 契约字段；modify 不迁入→不输出）
    ...(Array.isArray(result.migrated_modules) && result.migrated_modules.length
      ? { migrated_modules: result.migrated_modules.map((m) => ({ name: m.name, target: m.target, files: m.files })) }
      : {}),
    // SD26（r7）：ace WARN 级提示沉淀（编译前必办；无→不输出）
    ...(Array.isArray(result.ace_warnings) && result.ace_warnings.length
      ? { ace_warnings: result.ace_warnings.map((w) => String(w)) }
      : {}),
    environment: {
      android: orderPlatform(result.environment.android),
      ios: orderPlatform(result.environment.ios),
      arkui_x_sdk: orderArkuiXSdk(result.environment.arkui_x_sdk)
    }
  };
  return JSON.stringify(ordered, null, 2) + '\n';
}

function orderPlatform(platform) {
  return { ready: platform.ready, missing: [...platform.missing].sort() };
}

function orderArkuiXSdk(sdk) {
  return {
    detected: !!(sdk && sdk.detected),
    version: (sdk && sdk.version) || '',
    modify_available: !!(sdk && sdk.modify_available)
  };
}

/** 骨架报告（Markdown，含补验标注/迁入统计；v1.1 平台与 arkui_x_sdk 输出） */
export function renderMarkdown(result, options = {}) {
  const template = readFileSync(join(SKILL_ROOT, 'templates', 'report.md.tpl'), 'utf8');
  const sections = [];

  if (!result.environment.android.ready || !result.environment.ios.ready) {
    const notes = [];
    if (!result.environment.android.ready) {
      notes.push(`Android 环境未就绪，需在对应环境补验（缺失：${result.environment.android.missing.join('、') || '未知'}）`);
    }
    if (!result.environment.ios.ready) {
      notes.push(`iOS 环境未就绪，需在对应环境补验（缺失：${result.environment.ios.missing.join('、') || '未知'}）`);
    }
    sections.push(`> ⚠️ ${notes.join('；')}。骨架文件已按所选平台生成，不受环境影响。`);
  }
  if (options.migration && options.migration.filesMoved !== undefined) {
    const ignored = options.migration.ignored.length ? `（已忽略：${options.migration.ignored.join('、')}）` : '';
    sections.push(`源码迁入：${options.migration.filesMoved} 个文件已原样搬移至共享 ArkTS 目录${ignored}，内容哈希校验一致。`);
  }
  if (options.changedFiles && options.changedFiles.length > 0) {
    sections.push(['实际改动文件清单（modify 成功路径）:', ...options.changedFiles.map((f) => `- ${f}`)].join('\n'));
  }
  // SD26（r7）：ace WARN 级提示归档（一次性 stdout → 产物沉淀，迁移后编译前必办）
  if (options.aceWarnings && options.aceWarnings.length > 0) {
    sections.push(['### ace 迁移提示（编译前必办，来自 ace modify 输出）',
      ...options.aceWarnings.map((w) => `- ${w}`)].join('\n'));
  }

  sections.push('### 编译验证辅助（R-3：Skill 不直接执行，结果留白由开发者确认）');
  if (result.environment.android.ready && wantsAndroid(result.platform)) {
    sections.push('- Android：见 `verification/android-build.txt` 与 `verification/verify-android.sh`；执行后将结果回填本报告。');
  } else if (wantsAndroid(result.platform)) {
    sections.push('- Android：环境未就绪，未生成辅助（在 Android 环境补验）。');
  }
  if (result.environment.ios.ready && wantsIos(result.platform)) {
    sections.push('- iOS：见 `verification/ios-build.txt` 与 `verification/verify-ios.sh`；执行后将结果回填本报告。');
  } else if (wantsIos(result.platform)) {
    sections.push('- iOS：环境未就绪，未生成辅助（在 macOS + Xcode 环境补验）。');
  }

  const platformLabel = { both: '双平台（Android + iOS）', android: '仅 Android', ios: '仅 iOS' }[result.platform] || result.platform;
  const sdk = result.environment.arkui_x_sdk || {};
  const sdkLine = sdk.detected
    ? `✅ 检出（版本 ${sdk.version || '未知'}；modify 可用：${sdk.modify_available ? '是（API ≥ 24）' : '否（API < 24）'}）`
    : '❌ 未检出（ace tool 不在 PATH；如需 modify 请安装 ArkUI-X SDK 或以 --ace-bin 指定）';

  return template
    .replace(/{{MODE}}/g, result.mode)
    .replace(/{{PLATFORM}}/g, platformLabel)
    .replace(/{{ANDROID_SHELL}}/g, wantsAndroid(result.platform) ? result.android_shell : '（未选，platform 不含 Android）')
    .replace(/{{IOS_SHELL}}/g, wantsIos(result.platform) ? result.ios_shell : '（未选，platform 不含 iOS）')
    .replace(/{{SHARED_ARKTS_DIR}}/g, result.shared_arkts_dir)
    .replace(/{{ARKUIX_SDK}}/g, sdkLine)
    .replace(/{{ANDROID_READY}}/g, result.environment.android.ready ? '✅ 就绪' : `❌ 未就绪（${result.environment.android.missing.join('、')}）`)
    .replace(/{{IOS_READY}}/g, result.environment.ios.ready ? '✅ 就绪' : `❌ 未就绪（${result.environment.ios.missing.join('、')}）`)
    .replace(/{{SECTIONS}}/g, sections.join('\n\n'));
}

/** R-3：编译验证辅助产物（仅就绪且所选平台生成；命令文本+脚本，结果留白）。baseDir=壳所在生成根（modify=工程根，new=输出目录） */
export function renderVerificationAssists(result, baseDir) {
  const assists = {};
  if (result.environment.android.ready && wantsAndroid(result.platform)) {
    const androidShellAbs = join(baseDir, result.android_shell);
    assists['verification/android-build.txt'] = [
      '# Android 编译验证命令（由开发者执行，结果经确认后记入报告）',
      `cd ${androidShellAbs}`,
      './gradlew assembleDebug',
      ''
    ].join('\n');
    assists['verification/verify-android.sh'] = [
      '#!/usr/bin/env bash',
      '# Android 编译验证脚本（执行后将 PASS/FAIL 回填 migration-skeleton-report.md）',
      'set -e',
      `cd "${androidShellAbs}"`,
      './gradlew assembleDebug',
      'echo "ANDROID_VERIFY=PASS（请将本行结果回填报告）"',
      ''
    ].join('\n');
  }
  if (result.environment.ios.ready && wantsIos(result.platform)) {
    const iosShellAbs = join(baseDir, result.ios_shell);
    assists['verification/ios-build.txt'] = [
      '# iOS 编译验证命令（由开发者执行，结果经确认后记入报告）',
      `cd ${iosShellAbs}`,
      'xcodebuild -project "*.xcodeproj" -scheme "*" -sdk iphonesimulator build',
      ''
    ].join('\n');
    assists['verification/verify-ios.sh'] = [
      '#!/usr/bin/env bash',
      '# iOS 编译验证脚本（执行后将 PASS/FAIL 回填 migration-skeleton-report.md）',
      'set -e',
      `cd "${iosShellAbs}"`,
      'pod install 2>/dev/null || true',
      'xcodebuild -project "*.xcodeproj" -scheme "*" -sdk iphonesimulator build',
      'echo "IOS_VERIFY=PASS（请将本行结果回填报告）"',
      ''
    ].join('\n');
  }
  return assists;
}
