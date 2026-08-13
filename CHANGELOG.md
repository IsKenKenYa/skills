# 更新日志

本文件记录 KenKenSkills 的上游同步与本土化变更。

## 2026-08-13

### mattpocock/skills (`84fdeff`)

- 新增生产力 skills `to-questionnaire`、`wait-what`，并将 `writing-great-skills` 替换为上游重构后的 `writing-for-agents` 及其 Agent Skills 编写参考资料。
- 将 `wizard` 从 `in-progress` 迁移到 `engineering`，同步新的交互式向导模板与调用规则。
- 跟随上游删除 `personal` 下的 `edit-article`、`obsidian-vault`，以及原 `deprecated` 下的 `design-an-interface`、`qa`、`request-refactor-plan`、`ubiquitous-language`；`deprecated` 现仅保留空分类说明。
- 同步 35 个 skill 的正文、脚本、参考资料和 `agents/openai.yaml` 调用策略；重新翻译 `code-review`、`wayfinder`、`wizard`、`grilling` 等已变化 description。

### android/skills (`1e5e7ae`)

- 新增 `media3-cast-integration` 与 `leanback-to-compose-tv-migration`，并将 description 本土化为中文。
- 将 `build/agp/agp-9-upgrade` 迁移到上游新路径 `build-system/agp/agp-9-upgrade`。
- 同步 CameraX、AppFunctions、Compose、Navigation、Play、Perfetto、测试、Wear OS 与 XR 等 skill 的正文和完整参考资料，包含上游新增与删除的附属文件。
- 同步 Android 上游的 Agent、Claude 与 Codex 插件元数据；根 README 继续提供完整中文版本。

### HarmonyOS skills (`57a858e`)

- 新增性能优化 skill `hmos-memory-tier-optimizer`，以及稳定性 skills `hmos-native-memleak-analysis`、`hmos-runtime-fix-skill`。
- 新增开发 skill `hmos-one-sdk-skill`，完整同步其 One SDK 知识库、脚本和模板资源。
- 同步 ArkUI、稳定性分析、测试与 DevEco 等已有 skill 的正文、知识库、脚本和资源；继续为 `deveco-native-flow/references/` 下 36 个子 skill 添加 `metadata.internal: true`。
- 从上游 LFS 存储取回并校验原生内存泄漏分析所需的真实脚本与三平台 `trace_streamer`，未把 LFS 指针作为资源提交；`heap_cluster*` 仍按既定策略排除。
- `hmos-arkts-knowledge-retriever/linter-cli/node_modules` 继续按仓库既定策略不入库，运行时依赖仍通过 `MAINTENANCE.md` 记录的安装命令还原。

### 仓库维护

- README 与 Claude plugin 清单改为 112 个公开 skill；HarmonyOS 内部子 skill 仍为 36 个。
- 本土化 mattpocock 分类 README 和 Android 根 README，并修正本镜像对 `in-progress` skills 的收录说明。
- 更新 mattpocock 当前分类、HarmonyOS LFS 同步校验流程及三个上游追踪提交。

## 2026-07-13

### mattpocock/skills (`391a270`)

- 新增 `setup-ts-deep-modules`，包含 dependency-cruiser 配置模板。
- 跟随上游移除 `decision-mapping` 与 `review`；`zoom-out` 仍按既有策略不恢复。
- 同步工程、进行中和生产力 skills 的正文、参考文件及分类索引更新；对发生变化的 description 重新本土化为中文。

### android/skills (`57ff3c7`)

- 新增 `play-policy-insights`（含合规审计脚本与资源）和 `android-intent-security`。
- 将 Wear OS Compose Material3 skill 从 `jetpack-compose-m3` 迁移为上游名称 `wear-compose-m3`。
- 同步 CameraX、Compose、Navigation、Play、测试与 XR skill 的正文和参考资料；新增及变更的 description 均保持中文。

### HarmonyOS skills (`f21b4b0`)

- 新增 ArkUI 场景化开发 skill `hmos-arkui-scenario-development`。
- 新增发布与分发分类及 `app-metadata-audit-skill`。
- 同步多设备适配、稳定性分析、ArkUI、DevEco 等目录的正文、知识库、脚本和资源；继续将 `deveco-native-flow/references/` 标记为内部子 skill。
- 不提交超出 GitHub 文件限制的 `heap_cluster` 二进制；保留现有获取指引。

### 仓库维护

- README 清单和 Claude plugin 清单改由当前公开 skill 自动生成，公开 skill 总数更新为 110。
- 完善 HarmonyOS 路径压平规则、日期式 changelog 规范，以及 `gh skill` 的完整分类路径安装示例。
