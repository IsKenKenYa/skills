# 更新日志

## [1.3.0] - 2026-09-01

### 变更
- skill版本号升级至 v1.3.0

## [1.2.0] - 2026-08-14

### 新增
- 新增 HSP 加载失败定界规则，支持识别 `[LoadJSPandaFile] load hsp failed`、提取 `hsp name` 和 `errorMsg`。
- 新增 NAPI `ProcessAll` 回调崩溃定界规则，支持将十进制回调地址转换为十六进制并通过 `Maps` 定位所属模块。
- 新增符号表反解状态门禁，统一判断 BuildID、裸地址、`so+offset` 和 `unknown` 栈帧的反解状态。

### 变更
- 重写 NAPI 浅栈定界规则，区分 `libace_napi.z.so` 直接崩溃和经 `libark_jsruntime.so` 调用的场景，并将跳过运行时后的第一帧作为首个分析对象。
- 补充 `env`、`napi_value`、`napi_ref`、`napi_async_work` 和 `napi_threadsafe_function` 的生命周期、跨线程及内存破坏排查方向。
- 常规 CppCrash、踩内存第2现场和 GWP-ASan 在未完成符号表反解时，【修复建议】或【下一步建议】第 1 项优先要求使用匹配 BuildID 的符号文件反解后重新分析。
- README 中的 CppCrash 命令路径适配 `01-fault-analysis/cppcrash-analysis/` 新目录结构。
- 新增责任领域与修复建议对齐规则：系统侧根因只输出系统模块修改，应用侧根因只输出应用修改，混合责任分开输出，责任未定时只给继续定界建议。
- 符号表门禁、GWP-ASan 和 libuv 专项规则改为面向实际责任候选模块，不再默认要求应用承担系统侧根因的修改。

### 修复
- 补充 `_first_frame()` 辅助函数，修复生成提示时 `first frame is not defined` 的解析异常。


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
