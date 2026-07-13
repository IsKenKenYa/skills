# 更新日志

本文件记录 KenKenSkills 的上游同步与本土化变更。

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
