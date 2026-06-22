---
name: install-android-skills
description: 介绍 Android agent skills 并指导安装。当用户想获取 Android 开发技能、询问 Android skills 怎么装、或提到 Jetpack Compose/CameraX/AGP/Perfetto/R8/Play Billing/Wear OS/Android XR 等 Android 开发场景时使用。涵盖官方 `android` CLI 安装、`android skills add` 用法、以及本仓库中文化版的获取途径。
---

# 安装 Android Skills 指南

本 skill 帮你把 Android agent skills 装到当前环境。Android skills 是 Google 官方维护的、面向 Android 开发的模块化 AI 技能集，遵循开放标准的 agent skills 规范（SKILL.md）。

## 上游来源

- 上游仓库：`https://github.com/android/skills`
- 许可证：Apache License 2.0
- 官方 CLI：`android`（Google 提供的 Android 命令行工具，兼管 skills 安装）

## 安装 `android` CLI（前提）

若 `android` 命令不在 PATH 中，先按平台安装：

```bash
# Linux
curl -fsSL https://dl.google.com/android/cli/latest/linux_x86_64/install.sh | bash
# Mac (Apple Silicon)
curl -fsSL https://dl.google.com/android/cli/latest/darwin_arm64/install.sh | bash
# Mac (Intel)
curl -fsSL https://dl.google.com/android/cli/latest/darwin_x86_64/install.sh | bash
# Windows
curl -fsSL https://dl.google.com/android/cli/latest/windows_x86_64/install.cmd -o "%TEMP%\i.cmd" && "%TEMP%\i.cmd"
```

## 三种 skills 安装方式

### 方式一：通过本仓库（推荐，带中文化 description + 统一更新）

本仓库（`IsKenKenYa/skills`）整合了 Android 上游全部 skills，把每个 skill 的 description 翻译成中文（正文与官方指令保持英文原样，触发词保留原型）：

```bash
npx skills@latest add IsKenKenYa/skills
```

然后挑选 `android/` 分类下的 skills 和目标编码代理。

### 方式二：用官方 `android` CLI 安装单个 skill

```bash
# 安装特定 skill 到当前目录
android skills add --skill=r8-analyzer --project=.

# 安装全部 Android skills 到检测到的代理目录
android skills add --all
```

若没有任何已有代理目录且未指定 `--agent`，skills 默认装到 Gemini 和 Antigravity 的 `~/.gemini/antigravity/skills`。

常用选项：
- `--all` — 安装全部 Android skills。省略且未指定 `--skill` 时，只装 android-cli skill。
- `--agent` — 逗号分隔的代理列表，省略则装给所有检测到的代理。
- `--skill` — 指定要装的 skill。省略且未指定 `--all` 时，只装 android-cli skill。
- `--project` — skill 安装目标的项目根路径。

### 方式三：直接从上游 clone

```bash
git clone https://github.com/android/skills.git
```

克隆后把所需 skill 目录复制到你的代理 skills 目录。

## 分类概览（本仓库 skills/android/ 下）

- `build/agp/` — Android Gradle Plugin 升级迁移
- `camera/` — Camera1 到 CameraX 迁移
- `device-ai/` — AppFunctions（AI agent 工作流暴露）
- `devtools/` — `android` CLI 本身
- `identity/` — Credential Manager 已验证邮箱
- `jetpack-compose/` — Compose 自适应、XML 迁移、样式主题
- `navigation/` — Jetpack Navigation 3
- `performance/` — R8 keep 规则分析
- `play/` — Engage SDK、Play Billing 升级
- `profilers/` — Perfetto SQL 与 trace 分析
- `system/` — edge-to-edge 适配
- `testing/` — 测试策略搭建
- `wear/` — Wear OS Compose Material3
- `xr/` — Android XR 显示眼镜（Jetpack Compose Glimmer）

## 引用与许可

Android skills 源自 [android/skills](https://github.com/android/skills)，遵循 Apache License 2.0。本仓库仅翻译其 description 用于中文展示，正文保持原样。
