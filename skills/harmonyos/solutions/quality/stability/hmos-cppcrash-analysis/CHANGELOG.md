# 更新日志

## [1.1.0] - 2026-07-15

### 新增
- 新增变更日志：
  - `CHANGELOG.md`：记录版本变更信息

## [1.0.0] - 2026-06-10

### 新增
- 初始版本发布，新增 `hmos-cppcrash-analysis` Skill
- 支持 HarmonyOS/OpenHarmony Native 层（C/C++）崩溃故障分析
- 支持 SIGSEGV/SIGABRT/SIGILL/SIGBUS 等信号分类与寄存器分析
- 内置八步分析流程：关键日志提取 → 信号分类 → 崩溃地址分析 → Hilog 流水日志 → 调用栈解析 → 反汇编分析 → 业务代码分析 → 地址越界专项分析
- 新增分析工具：
  - `scripts/windows/llvm-addr2line.exe`：地址到函数名/行号解析
  - `scripts/windows/llvm-objdump.exe`：SO 文件反汇编
  - `scripts/windows/reliability_analyze.exe`：关键日志提取
  - `scripts/windows/extract_hilog.exe`：流水日志提取
- 新增参考资料：
  - `references/fault_mode.md`：CPP_CRASH 故障模式库
  - `references/arkui.md` / `arkdata.md` / `arkweb.md` / `jsruntime.md` / `render_service.md` / `jsvm.md` / `rosen_text.md`：各模块参考文档
- 内置 9 种常见崩溃类型速查（空指针、UAF、栈溢出、数据竞争、越界访问、死锁、除零、对齐错误、二进制不匹配）
