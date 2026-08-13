# 更新日志

## [1.1.0] - 2026-07-15

### 新增
- 新增变更日志：
  - `CHANGELOG.md`：记录版本变更信息

## [1.0.0] - 2026-06-10

### 新增
- 初始版本发布，新增 `hmos-jsleak-analysis` Skill
- 支持 .rawheap / .heapsnapshot 内存对象数据泄漏分析
- 内置 rawheap_translator 转换工具（支持 Windows/Linux/MacOS 多平台）
- 内置 heap_cluster 聚类脚本（`scripts/windows/heap_cluster.exe`）
- 支持四类泄漏规则检测：
  - Detached DOM 泄漏
  - 全局引用泄漏（window/Global/Cache/Map）
  - 闭包泄漏（context/system Context）
  - 异常大小对象泄漏
- 支持故障模式库匹配（ROOT_VM / ROOT_FRAME / ROOT_LOCAL_HANDLE / ROOT_GLOBAL_HANDLE / Unknown）
- 新增参考资料：
  - `references/fault-modes.md`：故障模式库
  - `references/ArkTS_OOM_故障模式库.md`：ArkTS OOM 故障模式库
- 输出结构化泄漏嫌疑清单（含引用链、根因分析、修复建议）
