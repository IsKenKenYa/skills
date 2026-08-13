# 更新日志

## [1.1.0] - 2026-07-15

### 新增
- 初始版本发布，新增 `hmos-native-memleak-analysis` Skill
- 支持 HarmonyOS/OpenHarmony Native 层内存泄漏自动化分析，覆盖 PSS、DMA、GPU、Kernel 等多种泄漏类型
- 内置智能场景判定：自动识别统一管控与非统一管控场景，并据此切换分析策略
- 支持多维度泄漏细分：
  - **PSS 泄漏**：自动细分 Jemalloc（堆内存）、ArkTS（虚拟机对象）、Ashmem（共享内存）、Anon（匿名内存）子类型
  - **DMA/GPU 泄漏**：分析 Top5 进程内存占用，定位未释放的 buffer 与渲染组件
  - **Kernel 泄漏**：解析内核侧内存分配，识别 SLAB、DMA 等内核态泄漏
- 提供完整的分析工具链：
  - `sample.py`：分析内存增长趋势与泄漏类型占比
  - `native_rate_parser.py`：解析 smaps 文件进行 PSS 子类型判定
  - `native_parser.py`：深入分析 jemalloc/ashmem 内存块分布
  - `flame_analyzer.py`：解析 profiler/trace 火焰图，定位泄漏模块与函数调用路径
  - `kernel_leak.py`：提取并分析 kernel 侧内存数据
- 支持故障模式库三级根因匹配（RSS 泄漏、进程泛 PSS 泄漏等）
- 输出结构化综合分析报告（含内存趋势表、泄漏点定位、证据链、根因模块与修复建议）
- 新增参考资料：`references/fault-mode-library.md`、`references/dma.md`、`references/dma_template.md`、`references/native_template.md`
- 新增变更日志：
  - `CHANGELOG.md`：记录版本变更信息
