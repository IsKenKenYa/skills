---
name: install-apple-skills
description: 介绍 Apple 生态（iOS/macOS/Swift/SwiftUI）的 agent skills 并指导安装。当用户想获取 Apple/Xcode 开发技能、询问 iOS/macOS/SwiftUI/Swift skills 怎么装、提到 WWDC26 session 269、Apple 官方 skill 导出（xcrun agent skills export）、OpenAI build-ios-apps / build-macos-apps 插件，或要做 iOS/Swift 开发时使用。涵盖 Apple 官方导出、三个 GitHub 上游、以及本仓库中文化版的获取途径。
---

# 安装 Apple 生态 Skills 指南

本 skill 帮你把 Apple 生态的 agent skills 装到当前环境。收录四个来源：**Apple 官方**（Xcode 27 内置）、**OpenAI 官方**（build-ios-apps / build-macos-apps 插件）、**twostraws**（SwiftUI Pro）、**AvdLee**（Swift Concurrency）。

## 来源一：Apple 官方（Xcode 27 内置，来自 WWDC26 session 269）

Xcode 27 在 Coding Assistant 中内置了官方 agent skills（SwiftUI Specialist、What's New In SwiftUI、App Intents Specialist 等），正文为 Apple 权威 guidance（"unconditionally supersedes prior training"）。**没有公开仓库**，唯一获取方式是从装有 Xcode 27+ 的机器导出：

```bash
xcrun agent skills export --output-dir <目录> [--replace-existing]
```

导出后把各 skill 子目录复制到你的代理 skills 目录即可。本仓库的 `skills/apple/official/` 即为从 Xcode 27.2 导出的 11 个：swiftui-specialist、swiftui-whats-new-27、app-intents-specialist、app-intents-whats-new-27、building-document-based-swiftui-applications、app-resizability、device-interaction、modernize-tests、xctrace、adopt-c-bounds-safety、audit-xcode-security-settings。Xcode 更新后可重新导出并覆盖同步。

## 来源二：OpenAI 官方 plugins（build-ios-apps / build-macos-apps）

上游仓库 `https://github.com/openai/plugins`（OpenAI 维护的 Codex 插件集），其中两个 Apple 平台插件：

- `build-ios-apps/skills/`（9 个）：ios-debugger-agent、ios-simulator-browser、ios-app-intents、ios-memgraph-leaks、ios-ettrace-performance、swiftui-liquid-glass、swiftui-performance-audit、swiftui-ui-patterns、swiftui-view-refactor
- `build-macos-apps/skills/`（11 个）：build-run-debug、swiftpm-macos、swiftui-patterns、view-refactor、appkit-interop、liquid-glass、window-management、signing-entitlements、packaging-notarization、test-triage、telemetry

Codex 用户可直接安装插件；其他代理用本仓库的中文化版：

```bash
npx skills@latest add IsKenKenYa/skills
```

然后挑选 `apple/ios/` 与 `apple/macos/` 分类。

## 来源三/四：社区精品 skill

- `https://github.com/twostraws/SwiftUI-Agent-Skill`（Paul Hudson）：`swiftui-pro` 单 skill + 8 个 references（views/data/performance/api/localization 等），覆盖 Apple 全平台 → 本仓库 `skills/apple/swiftui/swiftui-pro`
- `https://github.com/AvdLee/Swift-Concurrency-Agent-Skill`（Antoine van der Lee）：`swift-concurrency` 单 skill + 5 个 references（async/await、actor、Sendable、Swift 6 迁移），Swift 语言级 → 本仓库 `skills/apple/swift/swift-concurrency`

## 本仓库分类结构

- `apple/official/` — Apple 官方（Xcode 导出）
- `apple/ios/` — iOS 开发（OpenAI build-ios-apps）
- `apple/macos/` — macOS 开发（OpenAI build-macos-apps）
- `apple/swiftui/` — SwiftUI 跨平台（twostraws）
- `apple/swift/` — Swift 语言级（AvdLee）

## 注意事项

- Apple 官方 skill 的 description 由本仓库译为中文（API 名保留英文原型），正文保持 Apple 英文原文一字不动。
- 导出的官方文件带只读权限，修改前需 `chmod -R u+w`。
- 部分官方 skill 面向 iOS 27/macOS 27 新 API，需 Xcode 27+ SDK 才能实际编译验证。
