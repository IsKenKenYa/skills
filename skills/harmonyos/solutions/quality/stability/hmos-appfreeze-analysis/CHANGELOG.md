# 更新日志

## [1.1.0] - 2026-07-15

### 新增
- 新增 `scripts/freeze/` 目录及 Python 脚本（代替原来的可执行文件），可供开发者针对不同的开发环境灵活修改
- 新增 `scripts/sample_stack_analyzer.py` 脚本，用于分析 应用卡顿（Freeze）期间堆栈采样数据，实现跨平台的堆栈分析能力。

### 变更
- 更新 `SKILL.md` 文档内容，加入了对python脚本的使用工作流以及各类依赖的检查

### 移除
- 移除 `scripts/`下的可执行文件

## [1.0.0] - 2026-06-10

### 新增
- 初始版本发布，新增 `hmos-appfreeze-analysis` Skill
- 支持 HarmonyOS/OpenHarmony Freeze（冻屏/卡死/ANR）故障日志自动分析
- 内置十步分析工作流：环境检查 → 关键日志提取 → 整机资源评估 → EventHandler 队列分析 → 线程堆栈分析 → Binder 通信链路分析 → IPC 对端堆栈分析 → Trace 分析 → 热点函数采样分析 → 综合结论输出
- 支持故障模式库三级根因匹配（FML-001 主线程卡死超时）
- 新增跨平台二进制分析脚本：
  - `scripts/linux/reliability_analyze.run` / `sample_stack_analyzer.run`
  - `scripts/macos/reliability_analyze` / `sample_stack_analyzer`
  - `scripts/windows/reliability_analyze.exe` / `sample_stack_analyzer.exe`
- 新增参考资料 `references/fault-mode-library.md`
