---
name: hmos-memory-anti-regression
description: HarmonyOS 应用内存防劣化分析。对同一应用的两个版本分别执行数据采集和归因分析，通过 topdown 对比识别劣化源，对 Top10 劣化 SO 逐个按其 type_name 分发深度分析步骤 3/4/5（该 SO 含 ARKTS_HEAP→3+4，不全是 SO_SIZE/HAP→4，含 SO_SIZE/HAP→5，全是 SO_SIZE/HAP→仅5），综合输出总体防劣化分析报告。当用户提到采集htrace、分析内存、冷启动、内存对比、防劣化、topdown、汇总表、showmap、smaps、hidumper、hiprofiler、内存归因、内存劣化、heapsnapshot、nativehook、arkts heap、native heap、版本对比时使用此技能。
---

# hmos-memory-anti-regression Skill

HarmonyOS 应用内存防劣化分析：双版本采集 → 对比分析 → 深度归因 → 综合报告

## 防劣化分析总流程

```
0. 环境检查
1. 对旧版、新版分别执行数据采集（采完旧版 → 装新版 → 再采新版，顺序见步骤 1）
2. 对两个版本分别执行归因分析，各自生成 topdown + 汇总表
   → 根据两个版本的 topdown 对比结果，生成对比报告
   → 根据 Top10 劣化 SO 的 type_name 判断触发哪些深度分析（判定规则见下方「步骤 3/4/5 触发逻辑」）
3. ArkTS Heap 深度分析（Top10 劣化 SO 中存在 type_name 含 ARKTS_HEAP 的 SO 时触发，归因聚焦这些 SO）
4. Native Heap 深度分析（Top10 劣化 SO 中存在 type_name 不全是 SO_SIZE/HAP 的 SO 时触发，仅差分这些 SO）
5. SO_SIZE/HAP smaps 对比分析（Top10 劣化 SO 中存在 type_name 含 SO_SIZE/HAP 的 SO 时触发，仅对比这些 SO）
6. 综合 2 的对比报告 + 3/4/5 的深度分析结果，输出总体防劣化分析报告
```

- **排序规则**：分配器碎片、未覆盖、空服务、其他、(未命名)属于无法进一步分析的内存，通篇排序中一律放在对应类别最后
- **步骤 2 自身产出**：对比报告（topdown 总览 + 汇总表一层领域对比 + 汇总表层级结构 + Top10 劣化 SO + DMA 对比分析）
- **步骤 3/4/5 触发逻辑**（唯一定义，references 中各处相关描述均以此为准）：
  - **判据来源**：步骤 2 对比报告中的 Top10 劣化 SO（按新旧版本差值降序，排除分配器碎片/空服务/未覆盖/其他/(未命名) 等虚拟分类）
  - **分发方式**：对 Top10 中**每个 SO 单独**检查其在汇总表中挂载的 type_name 明细（一个 SO 可挂多个 type_name），按下表将该 SO 分发到对应深度分析步骤（同一 SO 可命中多个步骤）：

    | 该 SO 的 type_name 明细 | 分发步骤 |
    |------------------------|---------|
    | 包含 ARKTS_HEAP | 步骤 3 + 步骤 4 |
    | 不含 ARKTS_HEAP，且不全是 SO_SIZE / HAP | 步骤 4 |
    | 全是 SO_SIZE / HAP | 不分发到步骤 3/4（这些类型不是运行时堆分配，htrace .db 中无对应数据） |
    | 包含 SO_SIZE / HAP | 步骤 5（独立于上述三行，可叠加） |

  - **步骤执行范围**：每个深度分析步骤只针对被分发到它的 SO 执行——步骤 4 只差分这些 SO 的调用栈，步骤 5 只对比这些 SO 的 smaps 项，步骤 3 为全堆分析但归因重点是含 ARKTS_HEAP 的被分发 SO；某步骤没有任何 SO 被分发时跳过该步骤。报告中须注明每个步骤针对的 SO 列表。

- **步骤 3/4/5 并行执行**（关键优化）：三步互相独立，只共同依赖步骤 2 的 Top10 分发结果。分发完成后，使用 Task 工具同时启动最多 3 个 `general` agent 并行执行：

  | Agent | 步骤 | 输入文件 | 脚本 | 返回内容 |
  |-------|------|---------|------|---------|
  | Agent 1 | 步骤 3 ArkTS Heap | 两版本 .heapsnapshot | `shortest-path.mjs` → `compare_diff.py` | GROWN/NEW 链 + 责任侧分类 + delta_kb + count（对象数） |
  | Agent 2 | 步骤 4 Native Heap | 两版本 .db + 分发 SO 列表 | `cluster_calltree.py`（每 SO 一对 tree）→ `diff_cluster_tree.py` → `build_flame_summary.py`（前后对比火焰图） | 每 SO 差分树 root delta + Top N 劣化叶子调用链 + `<so>_compare_flame.html` |
  | Agent 3 | 步骤 5 SO_SIZE/HAP smaps | 两版本 smaps | `diff_smaps.py` | smaps_diff.json + Top N 劣化 SO/HAP + root_cause/suggestion |

  **并行执行规则**：
  1. 步骤 2 生成对比报告后，从中提取 Top10 劣化 SO 及其 type_name 明细，完成分发判定
  2. 在**单条消息**中同时发起所有触发的步骤 agent（未触发的步骤不启动 agent）
  3. 每个 agent 的 prompt 必须包含：分发到该步骤的 SO 列表、输入文件路径、脚本路径、输出格式要求
  4. 步骤 4 内部可进一步并行：多个 SO 的 `cluster_calltree.py` 可在同一 agent 内批量执行或启动子 agent
  5. **步骤 3 的 sourceMap 硬门控**在 agent 内独立处理：agent 先运行 shortest-path + compare_diff，拿到 `--json` 差异后停下来索要 sourceMap；sourceMap 未到手时返回 .ts 行号结果并标注"需 sourceMap 精确到 .ets"
  6. **步骤 4 的 debug SO 硬门控**在 agent 内独立处理：agent 先运行 cluster_calltree + diff_cluster_tree 拿到差分树，**到行号解析前（native-heap-workflow.md §3.1）停下来**，由主 agent 显式向用户索要 A/B 版本归因 SO 的带符号版本路径或目录（用户可拒绝）；未索要前**阻塞**不得静默解析，用户提供路径后须用 `readelf` 校验未 strip，用户拒绝时按 `native-heap-workflow.md`「调用链回溯完整性限制」保留未解析帧出报告并标注"待补充符号"
  7. 所有 agent 返回后，主 agent 汇总结果写入对比报告第一章（深度分析），再执行步骤 6 综合报告

- **步骤 6 的综合**：将步骤 2 的对比报告与步骤 3/4/5 的深度分析结果合并，输出总体报告

## 当前能力

| 阶段 | 状态 | 说明 |
|------|------|------|
| 0 环境检查 | 已完成 | hdc/trace_streamer/设备连接/依赖检查 |
| 1 数据采集 | 已完成 | 冷启动/运行态 htrace + 瞬时快照（对两个版本分别执行） |
| 2 归因分析 + 对比报告 | 已完成 | 两个版本各自 topdown + 汇总表 + 对比报告 |
| 3 ArkTS Heap 深度分析 | 已完成 | heapsnapshot 对比 + GC Root 最短路径 + sourceMap 行号解析 |
| 4 Native Heap 深度分析 | 已完成 | A/B 差分 + addr2line 行号解析 + 泄露/延时释放诊断 |
| 5 SO_SIZE/HAP smaps 对比 | 已完成 | A/B smaps 对比 + Pss 差值 + 劣化 SO/HAP 定位 + 根因推测 |
| 6 综合报告 | 计划中 | 合并 2 + 3 + 4 + 5 的结果输出总体防劣化分析报告 |

## 步骤 0：环境检查

检查 hdc/设备连接/应用包名/trace_streamer 可用性。如果应用未安装但用户提供了安装包路径，则执行 hdc install。

**应用安装后，通过 `--login-scenario` + `--login-scenario-dir` 自动执行 Hypium 登录预制脚本（如 `python main.py KuaishouPrerequisiteSetup`），脚本执行成功（退出码 0 + xdevice 报告校验通过）后自动继续采集流程，无需人工登录确认。未提供时回退为人工确认：等待用户完成登录等前置操作并确认应用处于正常使用状态后，才能继续采集流程。**

**工具路径查找**：所有工具路径通过 `scripts/_lib/tool_finder.py` 自动查找，按优先级：环境变量（`HDC_PATH`/`TRACE_STREAMER_PATH`/`ADDR2LINE_PATH`/`DEVECO_HOME`）→ DevEco Studio 安装目录 → 系统 PATH。

**trace_streamer**：通过 `tool_finder.py` 自动查找（`TRACE_STREAMER_PATH` → DevEco Studio → PATH）。若本机未找到，可下载：`https://gitcode.com/openharmony/developtools_smartperf_host/releases/download/HiSmartPerf_20260730/trace_streamer_binary.zip`（兜底：`https://gitcode.com/openharmony/developtools_smartperf_host/releases`）。zip 包含全平台二进制，解压后按平台选择对应可执行文件，设置 `TRACE_STREAMER_PATH` 或加入 PATH。→ 详见 references/environment.md

**环境要求**：推荐 Python 3.10（hypium 依赖推荐 3.10 版本；>= 3.10 可满足 `DataFrame.map()` 需求）；修改代码后需清除 `__pycache__`：`find scripts -name '__pycache__' -type d -exec rm -rf {} +`

**hypium 依赖检查**：采集流程依赖 hypium（场景复现 + 登录预制脚本通过 Hypium 工程执行）。`check_env.py` 自动检查 hypium 是否安装，未安装时自动执行 `pip install hypium -U --trusted-host mirrors.huaweicloud.com -i https://mirrors.huaweicloud.com/repository/pypi/simple`（**推荐 Python 3.10 环境下安装**）。

## 步骤 1：数据采集

**htrace 采集前必须通知用户并等待确认，不可自动执行。** 确认内容包括：
1. 告知即将执行的采集步骤（杀应用 → 重启 → htrace → 瞬时数据）
2. 告知采集时长
3. 提醒用户确保应用已登录并处于正常使用状态
4. 等待用户明确确认后才开始 htrace 采集

**通知确认由 AI 在调用 collect.py 之前自行完成，不得依赖 collect.py 内部的确认。** collect.py 以非交互子进程方式被调用，其 `prompt_confirm` 在非 TTY 且无 `--yes` 时直接报错退出；AI 的 Bash 工具在命令结束前拿不到交互输入。因此 AI 必须：① 先向用户发出采集通知（步骤/时长/复现时机/登录状态）并用 question 工具或文本取得明确确认；② 确认后再运行 `python scripts/1_collection/collect.py --yes ...`（`--yes` 跳过确认门禁，前提是 AI 已与用户确认）。未传 `--yes` 的非交互调用 collect.py 会直接报错退出，杜绝静默采集。

**未经用户确认，不得执行杀应用、启动 profiler 等 htrace 采集操作。** 瞬时数据采集（showmap/smaps/heapsnapshot 等）在 htrace 结束后自动执行，无需额外确认。

**场景复现自动化**（`--scenario` + `--scenario-dir` 参数）：当外部 Hypium 场景复现工程可用时，使用 `--scenario <xdevice测试用例名> --scenario-dir <工程路径>` 可在 htrace 采集期间自动执行 UI 操作，替代手动复现：
- `collect.py` 在 htrace 启动后自动后台运行 `<工程路径>/main.py <测试用例名> --skip-launch`
- `--skip-launch` 跳过场景脚本的 step1（启动应用），因为 `collect.py` 已通过 `aa start` 拉起应用
- **场景执行结果校验**：场景脚本退出后，`collect.py` 解析 xdevice 报告（`reports/<timestamp>/report_data.json`），通过时间窗口+场景名匹配定位当前场景报告，判断 pass/fail；失败时提示用户选择是否重新采集
- **htrace 采集时长自动调整**：当 `--scenario` 指定时，`collect.py` 优先从历史 xdevice 报告读取实际耗时，无历史报告时使用保守默认值（180s）；若用户指定时长不足，自动上调
- Hypium 工程为外部依赖，不包含在本 skill 内，需调用方提供路径

**手动复现（无 --scenario 时）**：hiprofiler_cmd 一旦启动即进入 trace 采集状态，必须在紧邻 hiprofiler_cmd 执行前后显式提醒用户开始复现操作：
- **冷启动场景**：profiler 启动 → sleep 3 → 应用拉起，**应用拉起后即可开始复现问题**
- **运行态场景**：profiler 启动后**立即**开始复现问题，提示与 hiprofiler_cmd 执行间隔越短越好

对旧版、新版分别执行 htrace + 瞬时快照采集。单版本采集流程：杀应用 → 启动 profiler → sleep 3 → 启动应用 → [场景复现 or 手动操作] → wait → 瞬时数据（showmap/smaps/heapsnapshot）→ 拉取 htrace 及其余产物。

**产物目录命名规则（关键）**：`collect.py` 的产物目录名格式为 `<app>_<version>[_<scenario>]`——`version` 为应用真实版本号（如 `14.8.10`），`scenario` 为可选的场景标签（如 `KuaishouScenarioReplay`）。版本号来源优先级：`--version_tag` 显式传入 > HAP 文件 versionName > 设备已装 versionName。**禁止使用 `old`/`new` 等无版本信息的泛化标签**，必须使用真实版本号，确保产物目录可追溯。示例：`hmapp_14.8.10/`、`hmapp_14.8.30_KuaishouScenarioReplay/`。

**双版本采集顺序（关键，不可逆）**：

> 产物输出目录 = 运行 `collect.py` 时工作目录下的 `output/`（`collect.py` 默认 `--output-base ./output`，相对当前运行目录，**非 skill 安装目录**）。AI 调用时工作目录通常为 workspace 根目录，产物落到 `<workspace>/output/<app>_<version>[_<scenario>]/`。

1. 安装旧版 → **登录前置**（`--login-scenario` + `--login-scenario-dir` 自动执行 Hypium 登录脚本，或人工登录确认）→ **阶段一确认（采集方案）→ 阶段二确认（复现时机）** → 执行采集 → 产物归置到 `<工作目录>/output/<app>_<旧版本号>[_<scenario>]/`
2. **确认旧版产物已全部拉取并归置完成**（heapsnapshot/smaps 等瞬时数据切换版本后无法补采）→ 覆盖安装新版 → **登录前置**（`--login-scenario` 自动执行，或人工登录确认）→ **阶段一确认 → 阶段二确认** → 执行采集 → 产物归置到 `<工作目录>/output/<app>_<新版本号>[_<scenario>]/`

→ 详见 references/collection-workflow.md

## 步骤 2：归因分析 + 总报告(数据部分)

对两个版本分别执行：
① meminfo 生成（harmonyos_pipeline.py，从 dynamic_showmap/meminfo/dmabuf_info 聚合 → meminfo.xlsx）
② htrace→db 转换 → 归因分析（main_analysis_all_mem.py，归因需 meminfo）

每个版本输出：meminfo.xlsx + 汇总.xlsx + topdown报告 + 详细数据 + dma_detail。

```bash
# ① meminfo 生成（归因前置）
python -c "
import sys; sys.path.insert(0, 'scripts/2_analysis'); sys.path.insert(0, 'scripts/_lib')
from harmonyos_pipeline import HarmonyLayer1MaPipeline
HarmonyLayer1MaPipeline(test_case_dir='output/<app>_<版本号>[_<scenario>]/').analyze()
"
# ② 归因分析
python scripts/2_analysis/main_analysis_all_mem.py \
  -p output/<app>_<版本号>[_<scenario>]/ -o output/<app>_<版本号>[_<scenario>]/analysis \
  --mm-dmabuf output/<app>_<版本号>[_<scenario>]/mm_dmabuf_info_<pid>.txt \
  --detail -l 10,0,5
```

然后对比两个版本的 topdown 和汇总表，由 `generate_comparison_report.py` 生成**总报告的数据部分**(一章深度分析占位 + 二~六章: topdown 总览/汇总表/Top10/DMA):

```bash
python scripts/2_analysis/generate_comparison_report.py \
  --old-dir output/<app>_<旧版本号> --new-dir output/<app>_<新版本号> \
  --old-label <旧版本号> --new-label <新版本号> \
  -o output/对比报告_<旧版本号>_vs_<新版本号>.md
```

> **路径固定（不可改动）**：对比报告 `.md` 固定输出到 `output/对比报告_<旧版本号>_vs_<新版本号>.md`，`report_md_to_html.py` 生成的 `.html` 同级（`output/对比报告_<旧版本号>_vs_<新版本号>.html`）；步骤 4 火焰图固定输出到 `output/flame_compare/`。报告 `.html` 与 `flame_compare/` 均在 `output/` 下同级，iframe 使用相对路径 `flame_compare/<so>_compare_flame.html` 可正确解析。**不得用 `-o` 改到其他目录，否则 iframe 相对路径失效。**

步骤 3/4/5 填入一章深度分析，DMA 填入六章，步骤 6 填入第八章(劣化汇总/优化建议/不确定性)，最终产出**一份总报告**。

→ 详见 references/analysis-workflow.md
→ 总报告格式参考 references/comparison-report-guide.md

## 步骤 3：ArkTS Heap 深度分析

**条件触发**：Top10 劣化 SO 中存在 type_name 明细包含 ARKTS_HEAP 的 SO 时触发；归因重点为这些 SO（分发规则详见上方「步骤 3/4/5 触发逻辑」）
**输入**：A/B 两个版本的 .heapsnapshot 文件 + sourceMap
**输出**：retained-size 增量报告（GROWN/NEW 链 + delta_kb + count 对象数 + 责任侧分类）、源码行号归因、**优化方向（章节级总体建议，置于 ArkTS Heap 小节开头，仅一条，不按引用链逐条补充）**
**关键约束**：sourceMap 必须开发者实际提供，不能自动推测

**⚠️ 优化方向是章节级总体建议，不按引用链逐条补充**：对比报告第一章 ArkTS Heap 小节**开头放一条总体优化方向**即可，不在每条 GROWN/NEW 链归因项下重复。该总体建议基于以下规则：

> **减少 retainedSize 的优化方向（引用链拆解规则）**：
> - **链上任意中间对象**：减少它对下一对象的持有关系（断开该 edge），其后继子树不再被该路径锚定，retainedSize 随之回落。
> - **最后一个对象**：可减少它对任一下一对象（任一出边）的持有关系，直接释放其引用的子对象。
> - **仅需断开链上任一边即可生效，不必整链清除**；优先断开开发者可控对象（带 `[entry]` / 应用源码行号）的出边，框架/VM 内部对象不可控则不单独处理。

→ 详见 references/arkts-heap-workflow.md

## 步骤 4：Native Heap 深度分析

**条件触发**：Top10 劣化 SO 中存在 type_name 不全是 SO_SIZE / HAP 的 SO 时触发；仅差分这些 SO 的调用栈（分发规则详见上方「步骤 3/4/5 触发逻辑」）  
**不触发**：某 SO 的 type_name 全是 SO_SIZE / HAP 时，该 SO 不分发到步骤 4（这些类型不是运行时堆分配，htrace .db 中无对应数据）    
**输入**：A/B 两个版本的 .db 文件 + 劣化SO名称 + debug SO 目录(可选) + 源码工程目录(可选) + addr2line路径  
**输出**：native heap 劣化诊断报告 + 前后对比火焰图（固定输出到 `output/flame_compare/<so>_compare_flame.html`，见 `native-heap-workflow.md` 步骤 5；报告 iframe 用相对路径 `flame_compare/<so>_compare_flame.html` 引用，与报告 `.html` 同级可解析）

→ 详见 references/native-heap-workflow.md

## 步骤 5：SO_SIZE/HAP smaps 对比分析

**条件触发**：Top10 劣化 SO 中存在 type_name 明细含 SO_SIZE 或 HAP 的 SO 时触发；仅对比这些 SO 的 smaps 项（分发规则详见上方「步骤 3/4/5 触发逻辑」）
**输入**：A/B 两个版本的 smaps 文件（`hidumper --mem-smaps <pid>` 或 `cat /proc/<pid>/smaps`）
**输出**：smaps_diff.json（按 Pss 差值降序）+ 劣化 SO/HAP 名称 + 根因推测 + 修复建议
**说明**：SO_SIZE/HAP 类型不是运行时堆分配，htrace .db 中无对应数据，步骤 3/4 无法分析。本步骤通过 smaps 对比直接分析 SO/HAP 的内存变化，填补步骤 3/4 的盲区。

→ 详见 references/so-size-hap-workflow.md

## 步骤 6：综合报告

综合步骤 2 的对比报告 + 步骤 3/4/5 的深度分析结果，输出总体报告：
- 两个版本的内存总览对比
- 各内存类别变化详情
- ArkTS Heap / Native Heap / SO_SIZE/HAP smaps 深度归因结果（如有），**其中 ArkTS Heap 小节开头放一条总体优化方向（引用链拆解），不按引用链逐条补充**（规则见步骤 3）
- 劣化点汇总 + 优化建议（第八章，受下方根因/建议限制约束）
- 不确定性说明（如分配器碎片波动范围）

### 第八章：综合劣化点汇总与优化建议（根因/建议限制）

第八章分两节：**8.1 劣化源汇总**（排名 / 劣化源 / 差值(MB) / 根因 / 分析步骤）+ **8.2 优化建议**（按优先级排序）。

**⚠️ 根因与修改建议限制（关键）**：综合劣化点汇总与优化建议中的根因和修改建议，**除非在案例库中找到对应的案例和解决方法，否则不随意给出**。

- **案例库范围**：
  - `references/arkts-leak-cases-and-faq.md`（ArkTS 泄漏案例 1.1/1.2/1.3 + FAQ 9/14 等）
  - 各 workflow 的「真实案例 / 根因推断表 / 修复建议方向」：`arkts-heap-workflow.md` 步骤 3.3 劣化类型表、`native-heap-workflow.md` 步骤 3.3 劣化类型表、`so-size-hap-workflow.md` 脚本 `suggestion` 字段
- **匹配到案例时**：可引用案例的根因推断与修复方向，并标注出处（如「见 arkts-leak-cases-and-faq.md 案例 1.3」「同 native-heap-workflow.md 泄露类型」）。
- **未匹配到案例时**：8.1 根因列写「未匹配案例库，需人工核查」，8.2 不给修改建议，仅保留劣化源数据（差值/分析步骤）。**禁止臆测根因、禁止泛化建议**（如「建议优化」「检查代码」等空话不得出现）。
- **可引用的既有结论**：步骤 2 对比报告里脚本 `suggestion` 字段、各 workflow per-SO 归因模板的结论可直接引用；其余发散分析（共性根因/关键发现/总体结论）不写入第八章，保持纯净性（见 `comparison-report-guide.md`「报告纯净性」）。

> 步骤 2 的对比报告 `.md`（`output/对比报告_<旧>_vs_<新>.md`）嵌入了步骤 4 的前后对比火焰图（iframe，相对路径 `flame_compare/<so>_compare_flame.html`，火焰图在 `output/flame_compare/`）；md 预览器过滤 iframe，查看火焰图需 `python scripts/2_analysis/report_md_to_html.py output/对比报告_<旧>_vs_<新>.md` 生成同级 `.html`（`output/对比报告_<旧>_vs_<新>.html`）后用浏览器打开（见 `comparison-report-guide.md`「报告 HTML 生成」）。

## 目录结构

```
hmos-memory-anti-regression/
├── SKILL.md                          # Skill 入口：流程骨架 + 决策逻辑
├── references/                       # 详细参考资料（AI 执行时按需查阅）
│   ├── environment.md               # 环境搭建指南（工具下载/安装/配置）
│   ├── collection-workflow.md        # 采集工作流
│   ├── analysis-workflow.md          # 分析工作流 + 归因规则
│   ├── comparison-report-guide.md    # 对比报告格式和注意事项
│   ├── arkts-heap-workflow.md        # ArkTS Heap 深度分析工作流
│   ├── native-heap-workflow.md       # Native Heap 深度分析工作流
│   ├── so-size-hap-workflow.md      # SO_SIZE/HAP smaps 对比分析工作流
│   ├── snapshot-object-guide.md      # 快照对象类型/属性参考
│   ├── arkts-leak-cases-and-faq.md   # 泄漏案例和 FAQ
│   ├── hidumper_commands.md          # hidumper 命令完整参考
│   ├── hiprofiler_config.md          # hiprofiler_cmd 配置参考
│   └── 对比报告.md                 # 对比报告模板
├── scripts/
│   ├── 0_prerequisites/              # 环境检查
│   │   └── check_env.py
│   ├── 1_collection/                 # 数据采集
│   │   ├── collect.py                # 主采集脚本 (支持 --scenario --scenario-dir 自动场景复现)
│   │   ├── dump_mem.py
│   │   ├── convert_htrace.py
│   │   └── convert_htrace_to_sqlitedb.py
│   ├── 2_analysis/                   # 归因分析
│   │   ├── harmonyos_pipeline.py    # meminfo 生成(showmap/gpu/dma → meminfo.xlsx)
│   │   ├── base_pipeline.py          # meminfo 生成基类(Layer1MaPipeline)
│   │   ├── main_analysis_all_mem.py  # 归因分析主入口
│   │   ├── analyze.py
│   │   ├── statistic_htrace_analysis.py
│   │   ├── first_kind_proc.py
│   │   ├── third_kind_proc.py
│   │   ├── topdown.py
│   │   ├── hidumper.py
│   │   ├── hybrid_mod.py
│   │   ├── callchain.py
│   │   ├── detail_mode.py
│   │   ├── rule.py
│   │   ├── tracedbs.py
│   │   ├── analysis_utils.py
│   │   ├── generate_comparison_report.py  # 对比报告生成(topdown/汇总/Top10/DMA)
│   │   ├── report_md_to_html.py      # 对比报告 md→html(渲染嵌入的火焰图 iframe)
│   │   └── so_field/                 # SO 归因规则
│   ├── 3_arkts_heap/                 # ArkTS Heap 深度分析
│   │   ├── shortest-path.mjs
│   │   ├── compare_diff.py
│   │   └── resolve-lines.py
│   ├── 4_native_heap/                # Native Heap 深度分析
│   │   ├── cluster_calltree.py      # 聚类树(<so>_tree.json)
│   │   ├── diff_cluster_tree.py     # 差分树(<so>_diff.json)
│   │   ├── build_flame_summary.py  # 火焰图(单版本/前后对比, bs4 单文件)
│   │   └── statics/                 # d3 火焰图模板+资源(flame/flame-c/example.template)
│   ├── 5_so_size_hap/                 # SO_SIZE/HAP smaps 对比分析
│   │   └── diff_smaps.py
│   └── _lib/                         # 公共库
│       ├── config.py
│       ├── cmd_runner.py
│       ├── hidumper_cmd_runner.py
│       └── file_utils.py
```

## 验证门槛

1. **采集后**: htrace > 100MB (冷启动60s) 表示有数据
2. **转换后**: .db > 50MB，native_hook 表有数据
3. **分析后**: 汇总.xlsx 行数 > 50，topdown 报告覆盖率 > 75%
4. **对比报告**: 总内存差值合理（同版本两次冷启动波动约 ±40 MB）
