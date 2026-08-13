# 更新日志

## [1.1.0] - 2026-07-15

### 新增
- 新增变更日志：
  - `CHANGELOG.md`：记录版本变更信息

## [1.0.0] - 2026-06-10

### 新增
- 初始版本发布，新增 `hmos-jscrash-analysis` Skill
- 支持 HarmonyOS/OpenHarmony JS/ArkTS 层闪退故障分析
- 支持 Reason/Error name/Error message/Error code 多维度分类
- 内置五步工作流：关键信息提取 → 故障类型分类 → 错误模式匹配 → 堆栈分析 → 根因形成
- 支持 JSError 三级根因匹配（ReferenceError、TypeError、Error、BusinessError、OutOfMemoryError 等）
- 新增参考资料：
  - `references/fault-mode-library.md`：JSError 一级/二级/三级根因库
  - `references/jscrash-patterns.md`：JS Crash 错误模式与修复建议矩阵
- 支持 SourceMap 缺失时的 raw stack 分析
- 支持 HybridStack / NAPI / libark_jsruntime 桥接证据分析
