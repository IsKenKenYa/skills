---
name: apifault-analysis
description: "定位开发者问题。当用户输入错误码、错误信息、错误日志、执行失败或需要定位问题时使用。"
---
# 问题定位 Skill（CodeGenie / 终端 Agent 通用版）

帮助开发者诊断问题的 Agent Skill。接收问题描述和故障日志，通过环境发现 + 项目代码分析 + 两阶段分级诊断，输出结构化诊断报告。

本 Skill 同时适用于 DevEco Studio CodeGenie 与终端 Agent（如 Claude Code、OpenCode 等 CLI）两种环境，支持 Windows 与 macOS 宿主平台。阶段 0 自动探测宿主 OS 与 shell，后续平台相关命令按 shell 分支执行。知识库内嵌于 `references/knowledge/`。

工具名映射、选择原则与降级方案（W/E）见 `references/tool_mapping.md`。下文统一用 CodeGenie 的 `builtin_*` 工具名描述；终端 Agent（如 Claude Code、OpenCode 等 CLI）执行时按该表替换为对应工具。

## 参数

| 参数                    | 必填 | 说明                                              |
| ----------------------- | ---- | ------------------------------------------------- |
| `problem_description` | 是   | 开发者对问题的文字描述                            |
| `log_content`         | 否   | 故障日志原文（hilog、HiviewDFX crash/freeze 等）  |
| `log_content_file`    | 否   | 日志文件路径（当日志较长时优先于`log_content`） |
| `code_snippet`        | 否   | 相关代码片段                                      |

## 参考文件

- 日志解析模式参考：`references/log_patterns.md`
- 模块映射表参考：`references/module_mapping.md`（含代码仓/文档仓 URL）
- 知识库：`references/knowledge/{module_name}/`（error_codes.json、api_chain.json、common_issues.md、overview.md、file_corruption_patterns.md）
- 媒体文件分析脚本：`references/scripts/media_file_analyzer.py`
- hilog 日志采集脚本：`references/scripts/hilog_collector.py`

## 执行阶段

按顺序执行以下阶段。

### 阶段 0：环境发现

**目标：** 探测宿主平台与运行环境，确定项目根目录、SDK 路径，发现 hilogtool，创建输出目录。

1. **平台与运行环境检测**：探测宿主 OS、可用 Python 命令与 shell 类型，后续平台相关命令按 shell 分支执行。

   - **OS 探测**：使用 `builtin_execute_command` 执行 `python3 -c "import platform; print(platform.system())"`；若 `python3` 不可用（返回非零退出码），改执行 `python -c "import platform; print(platform.system())"`：
     - 输出 `Windows` → `host_os = windows`（SDK 路径分隔符 `\`，hilogtool 二进制名带 `.exe`）
     - 输出 `Darwin` → `host_os = macos`（路径分隔符 `/`，hilogtool 无后缀）
   - **shell 探测**：使用 `builtin_execute_command` 执行 `uname -s`：
     - 退出码 0 → `host_shell = bash`（POSIX，覆盖 macOS bash/zsh 与 Windows Git Bash / 终端 Agent）
     - 退出码非 0 → `host_shell = powershell`（CodeGenie on Windows 默认）
   - `py_cmd` 记录本次成功的 Python 命令（`python3` 或 `python`），后续所有脚本调用统一使用它
   - 脚本要求 Python ≥3.7；若探测到的版本低于 3.7，在诊断报告中标注并提示用户升级 Python
   - **平台相关的 shell 命令按 `host_shell` 取值分支**（bash 分支的 POSIX 命令在 Windows Git Bash 与 macOS 均可用；powershell 分支用 cmdlet）
2. **确定项目根目录**：当前工作目录即为项目根目录。通过 `builtin_read_file` 读取 `local.properties`，提取 `sdk.dir=` 行获取 SDK 路径（Windows 路径分隔符为 `\`，macOS 为 `/`）。若文件不存在或无 `sdk.dir`，尝试 `builtin_read_file` 读取 `build-profile.json5` 获取 API 版本信息。若均不可用，在对话中询问用户 SDK 路径。
3. **创建输出目录**：在项目根目录下创建诊断报告输出目录，按 `host_shell` 分支：

   - `host_shell == bash`：`builtin_execute_command` 执行 `mkdir -p diagnosis`
   - `host_shell == powershell`：`builtin_execute_command` 执行 `New-Item -ItemType Directory -Force -Path diagnosis | Out-Null`
4. **发现 hilogtool**：在 SDK 路径下查找 hilogtool（用于解析二进制 hilog 日志）。候选二进制名按平台区分，候选目录两平台一致：

   - 候选二进制名按 `host_os` 区分：`host_os == windows` → `hilogtool.exe`；`host_os == macos` → `hilogtool`（无后缀）
   - 存在性检查按 `host_shell` 区分：`host_shell == bash` → `builtin_execute_command` 执行 `test -f "{路径}"`；`host_shell == powershell` → 执行 `Test-Path "{路径}"`
   - 候选路径按顺序查找：
     1. `{sdk_path}/hms/toolchains/{候选名}`
     2. 若不存在，尝试 `{sdk_path}/default/hms/toolchains/{候选名}`
   - 查到任意一个即记录 `hilogtool_path`（完整路径）并停止查找
   - 若均未找到：记录 `hilogtool_path = null`，后续日志采集将使用 gzip 降级方案
5. **记录路径**：`host_os`（windows/macos）、`host_shell`（bash/powershell）、`py_cmd`（python3 或 python）、`project_root`（当前工作目录）、`sdk_path`（SDK 路径）、`hilogtool_path`（hilogtool 完整路径或 null）、`output_dir`（`diagnosis/`）。

### 阶段 1：线索提取与模块识别

**目标：** 从输入中提取所有可用线索，识别涉及的模块。

1. **解析输入**：根据输入类型采用不同解析策略：

   - 若有 `log_content_file`：先使用 `builtin_read_file` 读取该文件（大文件使用 offset/limit 分页），再按 `references/log_patterns.md` 中定义的格式解析
   - 若有 `log_content`（无 `log_content_file` 时）：按 `references/log_patterns.md` 解析，提取错误码、事件名、DOMAIN、调用栈（含 .so 库名）、hilog domain_id
   - 若仅有 `problem_description`：提取错误码数字、API 名称、功能关键词、错误现象描述
   - 若有 `code_snippet`：提取涉及的 API 调用和错误处理逻辑
2. **模块识别**：使用 `builtin_read_file` 读取 `references/module_mapping.md`，用提取的线索匹配模块：

   - 按错误码前缀匹配（如 6600xxx → multimedia_av_session）
   - 按 DOMAIN 标识匹配（如 AAFWK → ability 相关）
   - 按 .so 库名匹配（如 libavsession.so → multimedia_av_session）
   - 按 API 名称前缀匹配（如 avsession.create* → multimedia_av_session）
   - 按 hilog domain_id 匹配

   2.1 **Kit名推断**：根据识别结果推断 Kit名：

   - 若错误码前缀匹配成功 → 从表1"Kit名"列提取
   - 若模块名识别成功 → 用模块名在表1"模块名"列反查对应行的"Kit名"列提取
   - 将推断的 Kit名记录到 `clues.kit_names`
3. **线索汇总**：将所有提取的线索以结构化格式记录：

   ```
   clues = {
     error_codes: [],
     event_names: [],
     domains: [],
     call_stack_highlights: [],
     so_libraries: [],
     modules: [],
     api_names: [],
     hilog_domain_ids: [],
     kit_names: [],
   }
   ```
4. **模块识别失败处理**：若所有线索均无法匹配到已知模块，标注 `module_identified = "未识别"`。
5. **日志采集与解析**（**强制执行，不可跳过**）：日志是诊断的核心依据，必须优先获取和解析。**除非用户明确要求跳过日志采集，否则必须执行本步骤，不得以任何理由省略**（包括但不限于：模块未识别、问题描述看似简单、用户未提供日志等）。按以下优先级获取：

   **优先级 1 — 使用用户提供的日志**：若已有 `log_content` 或 `log_content_file`，直接使用，跳过采集步骤。

   **优先级 2 — 通过 hdc 读取设备落盘日志**：若无用户提供的日志，按以下流程获取设备落盘日志。

   **步骤 A — 使用脚本采集并解析设备落盘日志**：

   执行 `references/scripts/hilog_collector.py` 脚本，自动完成设备日志拉取和解析：

   ```
   builtin_execute_command: {py_cmd} "{skill_dir}/references/scripts/hilog_collector.py" --output-dir diagnosis {若 hilogtool_path 不为 null 则添加: --hilogtool "{hilogtool_path}"} --time-window 10
   ```

   参数说明：

   - `--hilogtool`：阶段 0 发现的 hilogtool 路径。若 `hilogtool_path` 为 null，省略此参数，脚本将使用 gzip 降级方案
   - `--time-window`：筛选创建时间在指定分钟数以内的日志文件

   脚本输出 JSON 结果到 stdout：

   - `status`：`success`（成功）、`partial`（部分采集/解析：时间预算耗尽或部分文件失败，已按"最新优先"尽力返回日志）、`no_logs`（设备无日志）、`no_device`（设备未连接）、`error`（未捕获异常）
   - `parsed_files`：解析后的文本文件路径列表（按时间从旧到新排序）
   - `hilogtool_used`：是否使用了 hilogtool
   - 其余字段仅供参考：`partial`（是否部分结果）、`failed_files`（拉取失败/被跳过的文件）、`cached_files`（命中缓存未重拉的文件）、`reason`（部分原因）、`timed_out`（是否触达时间预算）、`elapsed_s`（耗时秒）

   **脚本执行后，使用 `builtin_read_file` 按 `parsed_files` 列表顺序（从旧到新）逐个读取解析后的日志文件，执行问题相关性检查：**

   **时间顺序判断**：`parsed_files` 列表已按文件名时间戳从旧到新排序。文件名中包含时间戳（格式如 `hilog.305.20260524-152948.log` → `2026-05-24 15:29:48`，设备本地时间）。skill 按列表顺序从旧到新逐个读取和分析。

   * **精确匹配**：在日志中搜索 `clues.error_codes`、`clues.api_names`、`clues.so_libraries`、`clues.domains` 中的已知值
   * **模糊匹配**：在 hilog Error/Fatal 行中搜索 `problem_description` 提取的功能关键词
   * **崩溃标记**：检查是否包含 `Generated by HiviewDFX@OpenHarmony`

   **若 status 为 no_device 或 error**：在诊断报告中标注"hdc 日志采集失败（{message}）"，继续后续阶段。
   **若 status 为 partial**：脚本在时间预算内尽力采集，`parsed_files` 仍可按时间顺序读取（可能少于完整集合，或为 gzip 降级后的文本）。在诊断报告中注明"日志采集部分超时/不完整（{reason}）"后，继续按 `parsed_files` 执行问题相关性检查——**不得因 partial 而跳过日志分析**。
   **若 status 为 no_logs**：进入步骤 B 开启落盘。
   **若 hilogtool_used 为 false**：在诊断报告中注明"hilogtool 不可用，日志可能包含乱码"。

   **步骤 B — 无落盘日志时，开启落盘并等待用户触发：**

   a. 执行以下命令开启日志落盘（单文件 5M，最大 10 个文件，zlib 压缩）：

   ```
   builtin_execute_command: hdc shell "hilog -w start -f diag -l 5M -n 10 -m zlib -j 11"
   ```

   b. **立即中断当前执行**，向用户输出以下提示（不生成诊断报告）：

   > 日志落盘已开启。请在设备上操作触发错误，完成后回复 **"OK"** 继续诊断。
   >

   c. **当用户回复"OK"后**，停止落盘并拉取日志：

   i. 停止落盘：

   ```
   builtin_execute_command: hdc shell "hilog -w stop -j 11"
   ```

   ii. 重新执行步骤 A 的脚本命令拉取并解析新生成的日志文件，然后按步骤 A 相同规则执行问题相关性检查。

   **采集失败处理**：

   - 若 hdc 命令执行失败（设备未连接、hdc 不可用等），在诊断报告中标注"hdc 日志采集失败（{失败原因}）"，继续后续阶段

   **关键注意事项：**

   - **日志采集脚本**：`references/scripts/hilog_collector.py`，封装了设备检查、文件拉取、hilogtool/gzip 解析。脚本仅负责拉取和解析，不合并、不做相关性检查，由 skill 按时间顺序逐个读取和分析
   - **时间预算与防超时**：脚本默认 25s 内尽力完成（`--collect-timeout`），触达预算时返回 `partial` 状态而非挂起——即便外层 `builtin_execute_command` 有 30s 硬超时，也不会被强杀而零输出。可调选项（默认值已对 30s 超时安全，SKILL 调用无需改动）：`--max-files`（默认 6，窗口内 `.gz` 按最新优先截断）、`--max-bytes`/`--max-bytes-per-file`（字节上限）、`--workers`（并行拉取，默认 4）、`--fresh`（禁用缓存强制重拉）、`--include-untimestamped-gz`（默认不拉无时间戳的 `.gz`）。重复采集（如步骤 B 二次拉取）默认命中缓存、跳过已拉文件
   - **用应用名过滤而非 PID**：PID 每次启动会变，应用名更稳定。多媒体框架错误日志来自媒体服务进程（通常 PID 737），不在 app 进程中
   - **python 命令统一**：脚本调用统一使用阶段 0 探测出的 `py_cmd`（Windows 通常 `python`、macOS 通常 `python3`）
   - **问题相关性检查**：有用性判定基于步骤 1-4 提取的 `clues`（错误码、API 名称、模块、.so 库等），确保读取的日志与用户报告的具体问题相关，而非泛泛匹配任何错误
6. **状态机转换序列追踪**（日志分析时必须执行，基于上一步已就绪的日志）：

   - 当日志中包含 `stateChange`、`reset`、`stop`、`prepare` 等状态相关事件时，按时间轴排列所有状态转换事件
   - 计数关键操作（如 reset、stop、prepare）的调用次数
   - 标记状态转换异常：如连续多次 reset、在已停止状态下再次 stop 等
   - 将状态转换时间线记录到 `clues` 中（新增字段 `state_transitions`）

### 阶段 2：分诊查询

**目标：** 快速查询知识库和文档，评估是否可以直接给出诊断。

#### 2.1 知识库查询

若阶段 1 识别到了模块，使用 `builtin_read_file` 读取 `references/knowledge/{module_name}/` 下的文件（下列步骤 1–4 均在此前提下执行）：

1. **错误码精确匹配**：读取 `error_codes.json`，按提取到的错误码查找匹配项
2. **API 调用链匹配**：读取 `api_chain.json`，按提取到的 API 名称查找调用链
3. **故障案例匹配**（**强制执行，不得因 glob 失败而跳过**）：若阶段1提取的 `clues.kit_names` 不为空，对其中每个 KitName 在 `references/knowledge/fault-cases/` 目录下查找案例文件。

   **关键陷阱——用 `{skill_dir}` absolute path定位，别靠 cwd 裸 glob：** fault-cases 目录位于 skill 目录内（`{skill_dir}/references/knowledge/fault-cases/`，`{skill_dir}` 即 SKILL.md 所在目录的absolute path）。`{skill_dir}` 与被诊断项目 cwd 的相对关系**不固定**：skill 通常装在项目之外（如 `~/.claude/skills/` 或插件缓存目录），但也可能被 vendoring 进项目仓库内部。因此对 cwd 的裸 glob（如 `{KitName}-Fault-Cases-*.md`）不可靠——裸 glob 默认锚定 cwd，而 skill 目录相对 cwd 的偏移未知，极易 0 命中、被误判为"无案例"而跳过本步（这正是此前 2.1.3 被跳过的原因）。正确做法：以 `{skill_dir}` absolute path为搜索根——`builtin_execute_command`（shell）的 `ls`/`find`，或把 `builtin_glob`/`builtin_grep` 的 `path` 显式设为该absolute path：

   - **列举 fault-cases 目录**：使用 `builtin_execute_command` 列举absolute path目录内容（按 `host_shell` 分支）：
     - `host_shell == bash`：`ls "{skill_dir}/references/knowledge/fault-cases/"`
     - `host_shell == powershell`：`Get-ChildItem "{skill_dir}/references/knowledge/fault-cases/" -Name`
   - **按 KitName 过滤**：从列举结果中筛出文件名匹配 `{KitName}-Fault-Cases-*.md` 的文件（如 `CoreFileKit-Fault-Cases-0.md`、`ArkData-Fault-Cases-1.md`）。匹配**忽略大小写**；多个 KitName 各自独立匹配；同一 Kit 的多个案例文件（`-0`、`-1`…）全部纳入。
   - **读取案例文件**：对每个匹配文件，使用 `builtin_read_file` 读取其**absolute path** `"{skill_dir}/references/knowledge/fault-cases/{文件名}"`（用absolute path，避免再次落入 cwd 相对解析）。
   - **搜索案例内容**：在已读取内容中按阶段1提取的错误码、问题现象关键词检索；也可用 `builtin_grep` 对上述**absolute path**文件/目录执行关键词搜索。
   - **提取**匹配案例的根因分析与修复建议。
   - **不得跳过**：仅当目录确实不存在或无任何 `{KitName}-Fault-Cases-*` 文件命中时，才标注"无该 Kit 的故障案例"并继续后续步骤——**严禁因 glob 失败、列举命令报错或某 Kit 0 命中而整体跳过 2.1.3**；若列举命令本身失败，先用 `builtin_read_file` 读取目录absolute path重试，仍失败则在报告中注明原因后继续。
4. **常见问题匹配**：读取 `common_issues.md`，搜索与问题现象匹配的模式
5. **额外知识文件搜索（条件执行）**：当「模块已识别但步骤 1–4 不足以支撑问题定位」或「模块未识别（阶段 1 `module_identified = "未识别"`）」时执行。两种情况搜索范围一致，均为整个 `references/knowledge/`，以阶段 1 提取的 `clues`（错误码、API 名称、.so 库、DOMAIN、功能关键词）作为关键词。

   **absolute path定位（同 2.1.3）**：本步搜索整个 `references/knowledge/`，同样在 skill 目录内、与项目 cwd 相对关系不固定——用 `{skill_dir}` absolute path列举与搜索，不要靠 cwd 裸 glob。

   - **列举全部知识文件**（按 `host_shell` 分支）：
     - `host_shell == bash`：`find "{skill_dir}/references/knowledge/" -type f`
     - `host_shell == powershell`：`Get-ChildItem -Path "{skill_dir}/references/knowledge/" -Recurse -File | Select-Object -ExpandProperty FullName`
   - **关键词递归搜索**：用 `clues` 关键词对上述absolute path目录递归搜索，聚焦步骤 1–4 未覆盖到的文件（按 `host_shell` 分支）：
     - `host_shell == bash`：`grep -rEn "关键词1|关键词2|…" "{skill_dir}/references/knowledge/"`（`-r` 递归、`-E` 扩展正则、`-n` 带行号；用 `|` 连接多个关键词）
     - `host_shell == powershell`：`Get-ChildItem "{skill_dir}/references/knowledge/" -Recurse -File | Select-String -Pattern "关键词1","关键词2" | Select-Object -ExpandProperty Path -Unique`
   - 若改用 `builtin_grep`（Grep 工具），把 `path` 显式设为 `"{skill_dir}/references/knowledge/"` absolute path。
   - 命中文件后用 `builtin_read_file` 读其**absolute path**定位证据。若命中某模块的知识库内容，可将其回填为候选模块，并照常汇入 2.3 置信度评估。

#### 2.1.6 媒体文件分析（条件执行）

**触发条件：** 错误码包含 5400103、5400106 或 5400102（仅当日志涉及文件路径/URI 时）

**参考文件：** `references/knowledge/multimedia_player_framework/file_corruption_patterns.md`

1. **确认文件路径**：

   - 若 `problem_description` 或 `code_snippet` 中包含可识别的媒体文件路径 → 使用提取的路径
   - 从问题描述提取文件名 → `builtin_glob` 在项目目录搜索：`**/*{filename}*`
   - 无明确文件名 → `builtin_glob` 搜索项目中的媒体文件：`**/*.{mp4,mkv,ts,m4a,aac,mp3,flac,wav,ogg,amr}`
   - 搜索结果多于一个 → 在对话中询问用户确认具体文件
   - 无文件路径且搜索无结果 → 在对话中询问用户提供媒体文件路径
   - 用户无法提供 → 跳过本步骤，在诊断结果中标注"未执行文件分析"
2. **执行文件分析脚本**：

   - 使用 `builtin_execute_command` 运行：
     ```
     {py_cmd} "{skill_dir}/references/scripts/media_file_analyzer.py" --file "{media_file_path}" --json
     ```
   - 使用阶段 0 探测出的 `py_cmd`；若 `python3`/`python` 均不可用，则降级为基于 `file_corruption_patterns.md` 的手动日志模式匹配
3. **解析脚本结果并交叉验证 hilog**：

   - 解析 JSON 输出中的 `overall_assessment`、`issues`、`error_code_correlation`
   - 同时使用 `builtin_read_file` 读取 `file_corruption_patterns.md` 第 3 节速查表，用阶段 1 提取的 hilog 关键字匹配损坏模式
   - 交叉验证脚本结论与 hilog 模式匹配结果
4. **结果处理**：

   - `unsupported_format` → 直接以高置信度返回结论
   - `likely_corrupt` / `possibly_corrupt` → 将文件损坏作为 rank 1 根因候选
   - `healthy` → 文件无问题，需深入排查其它原因
   - `unknown_format` → 文件可能严重损坏，中置信度
   - `analysis_error` → 文件不可达，中置信度

#### 2.2 文档仓查询

1. **优先使用 builtin_web_rag**：查询官方文档中的错误码说明和相关 API 用法（终端 Agent 见 `references/tool_mapping.md` 降级方案 W）
2. **映射表定位**：若 `references/module_mapping.md` 中有该模块的 errorcode 文档路径，使用 `builtin_execute_command` + `curl` 获取：`curl -sL "https://gitee.com/openharmony/docs/raw/master/{errorcode_path}"`
3. **兜底搜索**：若 builtin_web_rag（或终端降级方案 W）和 curl 均未命中，在对话中说明并基于已有信息继续

#### 2.3 置信度评估

**高置信度（跳过阶段 3 深潜分析，经阶段 4 进入阶段 5 输出）：**

- 故障案例匹配成功（相同错误码 + 相似问题现象）
- 找到了模块特定的错误码精确匹配，且知识库或文档提供了充分的排查信息
- 媒体文件分析确认文件为不支持的格式 + 错误码 5400106
- 媒体文件分析确认文件损坏 + 错误码匹配

**低置信度（进入阶段 3 深潜分析）：**

- 仅有通用错误码，无模块特定信息
- 知识库和文档均未提供足够的排查信息
- 模块未识别
- 媒体文件分析显示文件正常 + 错误码 5400103/5400106

**如果置信度为高，跳过阶段 3 深潜分析，直接进入阶段 4（项目源码分析与修复建议），再进入阶段 5 输出。阶段 4 与阶段 5 无论置信度都必须执行。**

### 阶段 3：深潜分析（仅低置信度时执行）

**目标：** 深入分析代码实现和文档，构建完整的证据链。

**执行方式（按运行环境分流）：** 阶段 3 的执行方式因环境而异——

- **终端 Agent（如 Claude Code、OpenCode 等 CLI）**：由主 Agent 用 `Agent` 工具**委派子 Agent** 整体执行（3.1→3.5 为子 Agent 内部步骤，合成留在子 Agent 内）；大块原始抓取不进入主上下文，主 Agent 仅派发并接收结构化结论。报告「根因分析」处无需额外标注。
  - **传入（主 Agent → 子 Agent）**：`clues`、阶段 2 分诊结论与判低置信的原因、`module_identified` 与 `references/knowledge/{module}/` 路径、`references/module_mapping.md`、宿主变量（`host_os`/`host_shell`/`py_cmd`/`project_root`/`sdk_path`/`hilogtool_path`/`output_dir`）；子 Agent 按 `references/tool_mapping.md` 选用工具。
  - **返回契约（子 Agent → 主 Agent，仅结构化结论）**：
    ```
    { diagnostic_depth: "deep_dive",
      root_cause_candidates: [
        { rank, confidence, description（追溯到应用侧行为）,
          evidence: [ { finding, source_type: knowledge_base|documentation|code, source_path } ],
          fix_hint（可选） } ],
      api_chain_findings（可选）, notes（可选） }
    ```
- **CodeGenie**：无子 Agent 能力 → 阶段 3 在**主上下文内顺序执行 3.1→3.5**（即按下文原样执行），在报告「根因分析」处标注"阶段3未隔离/CodeGenie 内联"。

（终端：子 Agent 返回结论；CodeGenie：主 Agent 内联执行后即得结论）随后进入阶段 4。

#### 3.1 API 链路追踪（条件执行）

**仅当模块有知识库时执行。** 使用 `builtin_read_file` 读取 `references/knowledge/{module_name}/api_chain.json`，按调用栈中的 C++ 函数名反向追踪。无知识库的模块跳过此步骤。

#### 3.2 代码仓搜索

1. **范围限定**：使用 `builtin_read_file` 读取 `references/module_mapping.md` 表 6 获取代码仓 URL
2. **搜索策略**：
   - 使用 `builtin_execute_command` + `curl` 从 Gitee 代码仓获取源文件
   - 搜索错误头文件（`*_errors.h`、`*_error_code.h`）获取错误码定义
3. **SDK 声明查询**：使用 `builtin_glob` 在 SDK 路径中搜索相关 `.d.ts` 文件，使用 `builtin_grep` 搜索错误码定义

#### 3.3 文档深度查询

1. 使用 `builtin_web_rag` 查询开发指南和 FAQ（终端 Agent 见 `references/tool_mapping.md` 降级方案 W）
2. 使用 `builtin_execute_command` + `curl` 读取 Gitee 文档仓的开发指南目录

#### 3.4 证据交叉验证

1. 对比知识库匹配、文档参考、代码仓/API 链路分析的结果（项目源码交叉验证移至阶段 4）
2. **当不同来源的信息矛盾时，以代码仓实际实现为准**
3. 为每个根因候选构建证据链，标注证据来源
4. 按证据充分程度排序根因候选

#### 3.5 根因层级追溯（必须执行）

**核心原则：不停留在框架机制层，必须追溯到应用行为根因。** 框架的拦截/防御代码通常是正确的系统行为——根因若停在那里，开发者只会拿到"修改框架"这种无从下手的建议，而非自己代码里可改的一行。

当分析定位到某个框架层的拦截/阻断点时，**必须继续追问**：是什么应用侧操作触发了这个拦截？追溯链路示例：

```
现象：seekDone 回调未送达 JS 层
  <- 框架机制：isloaded_ == false 导致回调被拦截
    <- 为什么 isloaded_ 为 false？因为 ResetTask() 被调用
      <- 为什么 ResetTask 被调用？因为开发者调用了 reset()
        <- 真正的根因：开发者多次调用 reset()
```

**追溯规则：**

- 框架层的防御性代码本身不是 bug，不应作为最终根因
- 最终根因必须是**应用侧的具体操作**
- 在证据链中明确区分"拦截机制"和"触发行为"
- 结合阶段 1 的状态转换时间线确认异常操作

### 阶段 4：项目源码分析与修复建议（始终执行）

**目标：** 基于阶段 2 的分诊结论与阶段 3 的根因结论（终端：子 Agent 返回；CodeGenie：主 Agent 内联执行所得），分析项目源码，定位具体代码问题并给出修改建议。

1. **扫描项目源码文件**：使用 `builtin_glob` 按模式搜索源码文件：

   ```
   builtin_glob: **/*.ets
   builtin_glob: **/*.ts
   builtin_glob: **/*.c
   builtin_glob: **/*.cpp
   builtin_glob: **/*.h
   ```

   汇总项目源码文件分布。
2. **读取项目配置**：

   - `builtin_read_file` 读取 `entry/src/main/module.json5`（权限声明）
   - `builtin_read_file` 读取 `build-profile.json5`（SDK 版本）
   - 记录已声明的权限列表、target API 版本
3. **定位问题相关源码**：根据诊断结论中涉及的 API 名称、问题模式以及调用栈中的 C++ 函数名，使用 `builtin_grep` 搜索相关代码文件，使用 `builtin_read_file` 读取相关代码段。
4. **源码问题分析**：

   - 对照 `api_chain.json` 检查 API 调用时序是否正确
   - 检查权限声明是否完整（对照 `module.json5`），并对照 API 要求确认是否匹配
   - 使用 `builtin_check_editor_errors` 检查相关源码文件语法问题（终端 Agent 见 `references/tool_mapping.md` 降级方案 E）
   - 结合诊断结论，在源码中定位具体的错误用法（如错误的 fdSrc 参数、缺失的状态检查等）
   - 确保 rank-1 根因表述为开发者的具体操作，明确区分"框架拦截机制"与"应用侧触发行为"（承自根因层级追溯原则，保证高置信路径也满足报告全局要求）
5. **生成具体修改建议**：针对定位到的代码问题，给出可直接应用的代码修改方案，写入诊断报告的"修复建议"章节。
6. **汇总源码分析结果**：记录到报告中"项目上下文"章节。

### 阶段 5：结果输出（始终执行）

**目标：** 构建诊断报告并写入文件。

1. 使用 `builtin_execute_command` 获取时间戳，按 `host_shell` 分支：

   - `host_shell == bash`：`date +%Y%m%d_%H%M%S`
   - `host_shell == powershell`：`Get-Date -Format 'yyyyMMdd_HHmmss'`
2. 使用 `builtin_write_file` 将诊断报告写入 `diagnosis/diagnosis_{timestamp}.md`

报告严格遵循 `references/report_template.md` 的 Markdown 模板、诊断置信度标准与关键要求。阶段 5 输出时读取该文件，按字段填充后写入 `diagnosis/diagnosis_{timestamp}.md`。
