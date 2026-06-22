---
name: install-harmonyos-skills
description: 介绍 HarmonyOS（鸿蒙）agent skills 并指导安装。当用户想获取鸿蒙开发技能、询问 HarmonyOS/OpenHarmony/ArkTS/ArkUI/DevEco skills 怎么装、或提到鸿蒙应用开发、多设备适配、稳定性分析等场景时使用。涵盖上游来源、官方安装方式、以及本仓库中文化版的获取途径。
---

# 安装 HarmonyOS（鸿蒙）Skills 指南

本 skill 帮你把 HarmonyOS agent skills 装到当前环境。HarmonyOS skills 是面向鸿蒙应用开发（ArkTS/ArkUI/多设备/稳定性/DevEco 工具等）的模块化 AI 技能集。

## 上游来源

- 上游仓库：`https://gitcode.com/HarmonyOS_Skills/harmonyos-agent-skills.git`
- 原生中文：上游 skill 本身就是中文撰写的，无需翻译。
- 上游无专门 CLI，安装方式是 git clone。

## 两种安装方式

### 方式一：通过本仓库（推荐，带中文化整合 + 统一更新）

本仓库（`IsKenKenYa/skills`）整合了 HarmonyOS 上游的全部 skills，并做了分类整理：

```bash
npx skills@latest add IsKenKenYa/skills
```

然后挑选 `harmonyos/` 分类下的 skills 和目标编码代理。本仓库的 HarmonyOS skills 与上游保持同步更新。

### 方式二：直接从上游安装（获取原版）

```bash
git clone https://gitcode.com/HarmonyOS_Skills/harmonyos-agent-skills.git
```

克隆后把所需 skill 目录复制到你的代理 skills 目录（如 `.zcode/skills/`、`.agents/skills/`、`.claude/skills/` 等）。

## 分类概览（本仓库 skills/harmonyos/ 下）

- `design/` — 设计阶段（移动端视觉还原等）
- `solutions/` — 解决方案（多设备适配、稳定性故障分析等）
- `development/` — 开发阶段（ArkUI/ArkTS/原子化服务/媒体/推送等应用框架与服务）
- `test/` — 测试阶段（本地测试、仪器测试）
- `tools/` — DevEco Studio 工具集（构建、模拟器、日志、验证等）
- `tooling/` — skill 审查工具

## 特殊依赖说明

`development/application-framework/ArkTS/hmos-arkts-knowledge-retriever` 下的 `linter-cli` 需要运行时依赖。首次使用前在该 skill 的 `linter-cli/` 目录执行：

```bash
cd linter-cli && npm install --force && npm run install-runtime-deps
```

- `npm install --force`：装回标准依赖（fs-extra/json5/uglify-js 等）。`--force` 用于绕过上游 package.json 中 `"cpu": ["x64"]` 的平台限制。
- `npm run install-runtime-deps`：从 `gitcode.com/openharmony/third_party_typescript.git` clone OpenHarmony 定制版 TypeScript（`4.9.5-r4`，标准 npm 上没有此版本），装到 `node_modules/typescript/`。

node_modules 不随仓库入库，按上述命令还原即可。

## 引用与许可

HarmonyOS skills 源自 [HarmonyOS_Skills/harmonyos-agent-skills](https://gitcode.com/HarmonyOS_Skills/harmonyos-agent-skills.git)。遵循其原有许可声明。
