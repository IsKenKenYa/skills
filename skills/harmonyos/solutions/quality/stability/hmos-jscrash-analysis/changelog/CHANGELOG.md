# 更新日志

## [1.3.0] - 2026-09-01

### 新增
- 新增 SourceMap 反解门禁：关键业务栈未还原时，优先使用匹配版本的 `sourceMaps.json` 和 `hstack` 还原源码位置；启用名称混淆时同时使用 `nameCache.json`。
- 新增 `references/sourcemap-symbolication.md`，说明反解输入、命令、结果校验和失败降级规则。
- 内置跨平台 `hstack` 工具包，提供 Windows、Linux 和 macOS 启动入口，用户无需另行下载 DevEco Studio 命令行工具。

### 变更
- 报告增加 SourceMap 反解状态、映射输入和原始栈到源码栈的映射证据；未反解时将补充匹配构建产物并重新分析作为第一项建议。
- SourceMap 反解流程增加 Node.js 与内置工具完整性检查，`mappings.wasm` 作为完整二进制随仓库发布，不依赖 Git LFS 拉取。
- skill版本号升级至 v1.3.0

## [1.2.0] - 2026-08-14

### 新增
- 新增 OOM 快照联动分析：当 JS Crash 明确定性为 `OutOfMemoryError` / OOM 且用户提供 `.rawheap` 或 `.heapsnapshot` 时，自动调用 `jsleak-analysis` Skill 继续定位疑似泄漏对象。
- 联合报告新增 OOM 快照分析部分，输出最严重疑似泄漏对象、Retained Size、最短强引用链、JS Leak 三级根因及其与本次 OOM 的关联可信度。

### 变更
- 明确先完成 JS Crash 定性，再执行 JS Leak 快照流程；日志与快照无法确认属于同一场景时，不将疑似泄漏对象直接认定为 OOM 根因。
- 同步更新 OOM 故障模式库和错误模式表，统一要求在已有快照时执行 JS Leak 分析。
- 更新 `SKILL.md` 文档内容，完善技能触发条件：新增排除规则，当日志为 cppcrash/freeze 或用户询问原生/C++层崩溃且无 JS/ArkTS 错误字段时，不应调用此技能
- 更新 `references/fault-mode-library.md` 故障模式库，大幅扩充三级根因条目：新增 `TypeError`（12 条）、`SyntaxError`（16 条）、`RangeError`（9 条）二级根因及对应三级根因，移除 `AggregateError`，重构表格格式

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
