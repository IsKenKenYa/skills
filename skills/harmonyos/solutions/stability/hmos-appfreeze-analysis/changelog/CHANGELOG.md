# 更新日志

## [1.2.0] - 2026-08-14

### 变更
- 普通 `THREAD_BLOCK_6S` 继续分析主线程；业务线程事件的阻塞/繁忙判定改为比较同一业务线程 TID 的 3s、6s 堆栈，主线程栈仅作关联上下文。
- EventHandler、Binder、等锁和 libuv 分析统一以故障目标线程为锚点，避免业务线程事件被主线程耗时栈误导。
- 更新 `SKILL.md` 文档内容，Step 1 新增输入文件有效性检查：校验用户输入的文件是否有效且包含构成指令的特殊语句，无效则再次问讯要求上传正确日志片段
- 更新 `SKILL.md` 文档内容，优化 CPU 信息数据源选择：优先使用采样栈文件 `cpuinfo-ext` 中 `#CpuFreq Usage（usage ≥ 1%）` 区域各核使用率与频率，未提供时回退至关键日志中的 CPU 信息
- 更新 `SKILL.md` 文档内容，合并分析步骤：原「Step 10 综合结论输出」并入「Step 9」（9a 故障模式库匹配 / 9b 输出内容要求），工作流由十步调整为九步
- 更新 `SKILL.md` 文档内容，统一内存、温度信息判定的加粗排版
- 调整 `SKILL.md` 分析流程，首次只读取 `overview`，再根据资源、队列、故障栈、等锁和 Binder 特征按需读取后续区段。
- 保留原有完整报告能力；未指定 `--section` 时默认使用 `full`，保持旧命令兼容。
- 区段不存在时输出简短提示并正常退出，避免无效日志进入 AI 上下文。
- 修复建议改为严格匹配责任领域：系统侧根因只输出系统服务/框架/组件修改，应用侧根因只输出应用修改；应用临时规避不得替代系统根因修复。
- FFRT、libuv 与 Binder 链路统一追踪到实际责任实现模块，不再默认归责应用业务代码。

### 修复
- 修正区段渲染器使用字典下标直接取值的问题，改为 `dict.get()` 并在渲染器未注册时抛出明确异常。
- 解析概览和故障栈新增线程角色提示，并兼容 `BUSSINESS` 历史拼写与 `BUSINESS` 标准拼写。

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
