# KenKenSkills

> 收集好用的 agent skills，把介绍（description）本地化为简体中文，统一管理、方便更新。

本仓库整合多个上游的优秀 agent skills：
- [mattpocock/skills](https://github.com/mattpocock/skills)（MIT）— 通用编码/生产力 skill，description 已译为中文
- [HarmonyOS_Skills/harmonyos-agent-skills](https://gitcode.com/HarmonyOS_Skills/harmonyos-agent-skills.git) — 鸿蒙开发 skill，上游原生中文，原样保留
- [android/skills](https://github.com/android/skills)（Apache 2.0）— Android 官方开发 skill，description 已译为中文

另有 2 个自建的安装指导 skill（`skills/meta/`），介绍各上游及官方 CLI 安装方式。`engineering/`、`in-progress/` 下另有若干自建/本土化 skill（code-review、research、wizard、loop-me 等）。

## 安装

```bash
npx skills@latest add IsKenKenYa/skills
```

然后挑选你想要的 skill 和目标编码代理即可。也可按上游官方方式安装，详见 [`/install-harmonyos-skills`](./skills/meta/install-harmonyos-skills/SKILL.md) 和 [`/install-android-skills`](./skills/meta/install-android-skills/SKILL.md)。

## 设计原则

- **专用 skill 按平台大类隔离**：通用 skill（mattpocock）放 `skills/<分类>/`；专用 skill 放 `skills/<平台>/`（`harmonyos/`、`android/`），平台内再按技术域细分，避免专用与通用混淆。
- **翻译对象仅限 description**：`name`、`disable-model-invocation`、`metadata`、`license` 等字段，以及全部正文指令，一律保持原样，不改变 skill 语义、不破坏 AI 执行完整性。
- **触发词保留原型**：`grill`/`tdd`/`triage`/`Jetpack Compose`/`CameraX`/`R8`/`Perfetto`/`ArkTS`/`ArkUI` 等关键词不翻译，必要时加中文括注。
- **HarmonyOS 原生中文不翻译**：上游 skill 本身就是中文（含中英混合），原样保留。
- **上游引用隔离**：原版上游仓库作为 git submodule 放在独立的 `upstream-refs` 分支，主分支保持干净——`npx skills add` 只会扫到中文化版本，不会被原版污染。
- **内部子 skill 用官方机制隔离**：部分 skill（如 HarmonyOS 的 `deveco-native-flow`）内含 `references/` 子 skill 作为父 skill 的知识库，带 `metadata.internal: true`，扫描时跳过但安装父 skill 时递归复制带走。

调用方式说明：标记为「用户调用」的 skill 只能用 `/skill名` 手动触发；「模型/用户调用」的 skill 还能被模型根据上下文语义自动触发。

## Skill 清单（共 118 个）

## 一、mattpocock 通用 Skills（37 个，description 已中文化）

### Engineering — 工程类（18）

*日常编码工作*


| skill | 调用方式 | 中文介绍 |
|-------|---------|---------|
| [`/ask-matt`](./skills/engineering/ask-matt/SKILL.md) | 用户调用 | 询问哪种 skill 或流程适合你的场景。是本仓库中全部 skill 的路由器。 |
| [`/code-review`](./skills/engineering/code-review/SKILL.md) | 模型/用户调用 | 沿两条轴线审查自某个固定点（提交、分支、标签或 merge-base）以来的变更——标准（代码是否遵循本仓库文档化的编码规范？）与规格（代码是否符合原始 issue/spec 的要求？）。两个审查由并行子代理执行并并排汇报。当用户想审查一个分支、PR、进行中的改动，或要求“自 X 起审查”（review since X）时使用。 |
| [`/codebase-design`](./skills/engineering/codebase-design/SKILL.md) | 模型/用户调用 | Shared vocabulary for designing deep modules. Use when the user wants to design or improve a module's interface, find deepening opportunities, decide where a seam goes, make code more testable or AI-navigable, or when another skill needs the deep-module vocabulary. |
| [`/diagnosing-bugs`](./skills/engineering/diagnosing-bugs/SKILL.md) | 模型/用户调用 | Diagnosis loop for hard bugs and performance regressions. Use when the user says "diagnose"/"debug this", or reports something broken/throwing/failing/slow. |
| [`/domain-modeling`](./skills/engineering/domain-modeling/SKILL.md) | 模型/用户调用 | 构建并打磨项目的领域模型。当讨论代码库术语、撰写或编辑 CONTEXT.md、记录或编辑 ADR 时使用。 |
| [`/grill-with-docs`](./skills/engineering/grill-with-docs/SKILL.md) | 用户调用 | A relentless interview to sharpen a plan or design, which also creates docs (ADR's and glossary) as we go. |
| [`/implement`](./skills/engineering/implement/SKILL.md) | 用户调用 | 基于规格（spec）或一组 ticket 实现一项工作。 |
| [`/improve-codebase-architecture`](./skills/engineering/improve-codebase-architecture/SKILL.md) | 用户调用 | Scan a codebase for deepening opportunities, present them as a visual HTML report, then grill through whichever one you pick. |
| [`/prototype`](./skills/engineering/prototype/SKILL.md) | 模型/用户调用 | 构建一次性原型来回答设计问题。当用户想验证状态模型或逻辑是否合理，或探索 UI 应该长什么样时使用。 |
| [`/research`](./skills/engineering/research/SKILL.md) | 模型/用户调用 | 针对一个问题调研高可信度的一手资料，并把发现整理为仓库中的 Markdown 文件。当用户想调研某个主题、收集文档或 API 事实，或把阅读跑腿工作交给后台代理时使用。 |
| [`/resolving-merge-conflicts`](./skills/engineering/resolving-merge-conflicts/SKILL.md) | 模型/用户调用 | Use when you need to resolve an in-progress git merge/rebase conflict. |
| [`/setup-matt-pocock-skills`](./skills/engineering/setup-matt-pocock-skills/SKILL.md) | 用户调用 | 为工程类 skill 配置本仓库：设置 issue 追踪器、triage 标签词汇和领域文档布局。在其他工程类 skill 首次使用前运行一次。 |
| [`/tdd`](./skills/engineering/tdd/SKILL.md) | 模型/用户调用 | Test-driven development. Use when the user wants to build features or fix bugs test-first, mentions "red-green-refactor", or wants integration tests. |
| [`/to-spec`](./skills/engineering/to-spec/SKILL.md) | 用户调用 | 把当前对话转化为规格（spec）并发布到项目 issue 追踪器：无需访谈，只是对已讨论内容的综合提炼。 |
| [`/to-tickets`](./skills/engineering/to-tickets/SKILL.md) | 用户调用 | 把计划、规格或当前对话拆解为一组示踪子弹（tracer-bullet）ticket，每个 ticket 声明自己的阻塞关系，发布到配置好的追踪器（本地模式下阻塞关系以文本写在每个 ticket 文件里，真实追踪器上则用原生的阻塞链接）。 |
| [`/triage`](./skills/engineering/triage/SKILL.md) | 用户调用 | 让 issue 和外部 PR 经过一组 triage 角色的状态机——分类、验证、必要时 grill 访谈，并撰写代理可直接执行的简报（brief）。 |
| [`/wayfinder`](./skills/engineering/wayfinder/SKILL.md) | 用户调用 | 把一大块工作（单次 agent 会话装不下的规模）规划为 issue 追踪器上的决策 ticket 共享地图，然后逐个解决，直到通往终点的路径清晰。 |
| [`/wizard`](./skills/engineering/wizard/SKILL.md) | 模型/用户调用 | 生成一个交互式 bash 向导，引导人类逐步完成只有他们才能执行的操作。当需要开通基础设施、设置凭证或 CI secrets、走查陌生的第三方控制台，或执行一次性迁移/切换时使用。代理自己能完成的步骤不要调用此 skill。 |

### Productivity — 生产力类（7）

*日常非编码工作流工具*


| skill | 调用方式 | 中文介绍 |
|-------|---------|---------|
| [`/grill-me`](./skills/productivity/grill-me/SKILL.md) | 用户调用 | A relentless interview to sharpen a plan or design. |
| [`/grilling`](./skills/productivity/grilling/SKILL.md) | 模型/用户调用 | 就一个计划、决策或想法对用户进行无情的访谈。当用户想压力测试自己的思路，或使用任何 'grill' 触发短语时使用。 |
| [`/handoff`](./skills/productivity/handoff/SKILL.md) | 用户调用 | Compact the current conversation into a handoff document for another agent to pick up. |
| [`/teach`](./skills/productivity/teach/SKILL.md) | 用户调用 | Teach the user a new skill or concept, within this workspace. |
| [`/to-questionnaire`](./skills/productivity/to-questionnaire/SKILL.md) | 用户调用 | 把你无法独自回答的决策转化成一份问卷，交给别人填写。 |
| [`/wait-what`](./skills/productivity/wait-what/SKILL.md) | 用户调用 | 停。上一条消息没讲明白：换个说法再讲一遍。 |
| [`/writing-for-agents`](./skills/productivity/writing-for-agents/SKILL.md) | 模型/用户调用 | 为 agent 撰写文档。当创建或编辑 skill、修改 AGENTS.md 或 CLAUDE.md 时使用。 |

### Misc — 杂项（4）

*保留但较少使用*


| skill | 调用方式 | 中文介绍 |
|-------|---------|---------|
| [`/git-guardrails-claude-code`](./skills/misc/git-guardrails-claude-code/SKILL.md) | 模型/用户调用 | Set up Claude Code hooks to block dangerous git commands (push, reset --hard, clean, branch -D, etc.) before they execute. Use when user wants to prevent destructive git operations, add git safety hooks, or block git push/reset in Claude Code. |
| [`/migrate-to-shoehorn`](./skills/misc/migrate-to-shoehorn/SKILL.md) | 模型/用户调用 | Migrate test files from `as` type assertions to @total-typescript/shoehorn. Use when user mentions shoehorn, wants to replace `as` in tests, or needs partial test data. |
| [`/scaffold-exercises`](./skills/misc/scaffold-exercises/SKILL.md) | 模型/用户调用 | Create exercise directory structures with sections, problems, solutions, and explainers that pass linting. Use when user wants to scaffold exercises, create exercise stubs, or set up a new course section. |
| [`/setup-pre-commit`](./skills/misc/setup-pre-commit/SKILL.md) | 模型/用户调用 | Set up Husky pre-commit hooks with lint-staged (Prettier), type checking, and tests in the current repo. Use when user wants to add pre-commit hooks, set up Husky, configure lint-staged, or add commit-time formatting/typechecking/testing. |

### In-progress — 进行中（8）

*尚未定稿的草稿*


| skill | 调用方式 | 中文介绍 |
|-------|---------|---------|
| [`/claude-handoff`](./skills/in-progress/claude-handoff/SKILL.md) | 用户调用 | 把当前对话移交给一个全新的后台代理，让它立即接手工作。 |
| [`/implement-spec`](./skills/in-progress/implement-spec/SKILL.md) | 用户调用 | 把规格（spec）实现为代码。 |
| [`/loop-me`](./skills/in-progress/loop-me/SKILL.md) | 用户调用 | 在本工作区内，就我想构建的工作流的规格（spec）对我进行 grill 访谈。 |
| [`/retro`](./skills/in-progress/retro/SKILL.md) | 用户调用 | 对一次编码会话进行复盘（retrospective）。 |
| [`/setup-ts-deep-modules`](./skills/in-progress/setup-ts-deep-modules/SKILL.md) | 用户调用 | 把 dependency-cruiser 接入 TypeScript 仓库，让每个包都成为深层模块（deep module）——实现隐藏在子文件夹中，只能通过入口文件访问。用户调用。 |
| [`/writing-beats`](./skills/in-progress/writing-beats/SKILL.md) | 用户调用 | 写作·利用（exploit）：把原始素材组装成一段节拍（beat）之旅，在每个节拍依赖某个术语之前先把它讲透。 |
| [`/writing-fragments`](./skills/in-progress/writing-fragments/SKILL.md) | 用户调用 | 写作·探索（explore）：挖掘原始片段，暂不构建结构。 |
| [`/writing-shape`](./skills/in-progress/writing-shape/SKILL.md) | 用户调用 | 写作·利用（exploit）：把原始素材逐段塑造成文章。 |

## 二、HarmonyOS（鸿蒙）Skills（57 个，上游原生中文原样保留）

### design — 设计（1）


| skill | 中文介绍 |
|-------|---------|
| [`/hmos-design-visual-mobile`](./skills/harmonyos/design/mobile/hmos-design-visual-mobile/SKILL.md) | HarmonyOS 移动端页面视觉还原技能。基于仓库内设计规范文档与组件模板，生成符合 HarmonyOS Design Token 标准的高保真移动端 HTML 页面。触发场景：(1) 用户要求生成/还原 HarmonyOS 移动端页面 (2) 用户提供设计稿/截图/参考图，要求还原为 HarmonyOS 风格 HTML 页面 (3) 用户提到"视觉还原"/"高保真页面"/"移动端页面"并涉及 HarmonyOS，用于需要生成符合鸿蒙规范的移动端设计稿的场景 |

### solutions — 解决方案（17）


| skill | 中文介绍 |
|-------|---------|
| [`/hmos-multidevice-avoid-areas`](./skills/harmonyos/solutions/HMOS-technologies/multi-device/hmos-multidevice-avoid-areas/SKILL.md) | Handle HarmonyOS avoid-area adaptation through a declarative scene and resource index. Use when the task involves safe area expansion, status bar or navigation bar avoidance, notch or cutout handling, immersive full-screen layouts, or soft keyboard overlap handling. |
| [`/hmos-multidevice-fold-state`](./skills/harmonyos/solutions/HMOS-technologies/multi-device/hmos-multidevice-fold-state/SKILL.md) | HarmonyOS foldable-device adaptation skill for requirements, development, bug-fix, and verification phases. Activate when the task involves fold status detection, hover-mode split-screen layouts, crease avoidance, fold continuity, multi-fold form-factor mapping (e.g. F/M/G), inner/outer screen ratio differences, or fold-related issue remediation. |
| [`/hmos-multidevice-hardware-access`](./skills/harmonyos/solutions/HMOS-technologies/multi-device/hmos-multidevice-hardware-access/SKILL.md) | Handle HarmonyOS hardware-capability adaptation through a declarative scene and resource index. Use when the task involves camera selection, camera rotation/stride/foldable adaptation, canIUse or SysCap checks, hardware fallback strategy, or multi-device hardware behavior differences. |
| [`/hmos-multidevice-interaction-methods`](./skills/harmonyos/solutions/HMOS-technologies/multi-device/hmos-multidevice-interaction-methods/SKILL.md) | HarmonyOS应用多设备交互适配开发方案skill，提供触摸、鼠标、键盘、手写笔等多输入方式的交互方案和事件归一策略。当涉及触摸、鼠标、键盘、手写笔等设备的交互以及实现交互归一化、悬停效果、右键菜单、焦点导航、键盘快捷键、手写板输入和压感等功能时调用。 |
| [`/hmos-multidevice-natural-orientation`](./skills/harmonyos/solutions/HMOS-technologies/multi-device/hmos-multidevice-natural-orientation/SKILL.md) | 鸿蒙 HarmonyOS 屏幕方向与旋转相关的需求分析、开发实现、问题修复和功能验证。当任务涉及以下场景时使用：setPreferredOrientation、屏幕旋转(rotation)、屏幕方向(orientation)、自然方向、折叠屏方向、三折叠G态、follow_desktop、视频横竖屏切换、短视频自适应旋转、多设备方向策略、module.json5方向配置、方向监听、旋转检测、分屏旋转、折叠屏展开态方向、窗口方向设置、方向Bug修复。 |
| [`/hmos-multidevice-scenario-entry`](./skills/harmonyos/solutions/HMOS-technologies/multi-device/hmos-multidevice-scenario-entry/SKILL.md) | Entry skill for HarmonyOS multi-device adaptation. Use when the task broadly concerns HarmonyOS multi-device adaptation, the task involves foldable device verification or when the correct scenario is still unclear. This skill classifies the request by phase and scenario type, then routes to one or more scenario files for screen and window size, fold state, avoid areas, interaction methods, natural orientation, or hardware access. |
| [`/hmos-multidevice-screen-window-size`](./skills/harmonyos/solutions/HMOS-technologies/multi-device/hmos-multidevice-screen-window-size/SKILL.md) | HarmonyOS 多设备屏幕窗口尺寸适配。当任务涉及以下任一场景时必须调用：（1）比价与分屏：比价/比价场景/比价窗口/价格对比/创建新窗口/多窗口并行/双窗口；（2）平行视界与分栏：平行视界/EasyGo/easy_go.json/分栏效果/分栏布局/列表详情分栏/navigationSplit/routerSplit/Navigation分栏；（3）响应式与自适应布局：响应式布局/自适应布局/断点/GridRow/GridCol/WidthBreakpoint/HeightBreakpoint/重复布局/分栏布局/挪移布局/缩进布局；（4）窗口监听：windowSizeChange/窗口尺寸变化/布局未同步更新；（5）组件自适应：layoutWeight/Blank/aspectRatio/displayPriority/FlexWrap/拉伸/均分/隐藏/折行/缩放/占比/百分比宽度；（6）多设备适配：手机/平板/2in1/穿戴/折叠屏/双折/三折/大屏/横竖屏/密度/字体缩放/滚动延伸；（7）布局异常：截断/留白/溢出/遮挡/错位/对齐异常/GridRow不降列/断点不切换/图片变形/压缩。不适用于：FoldStatus、hover、折痕、安全区、与尺寸无关的调整。 |
| [`/hmos-memory-tier-optimizer`](./skills/harmonyos/solutions/quality/performance/hmos-memory-tier-optimizer/SKILL.md) | HarmonyOS 应用低端机内存分档优化 Skill，覆盖内存采集、数据分析、分档候选方案、用户确认、代码修改与审查、构建安装、优化后复测、patch 与报告生成全闭环。当用户提供 HarmonyOS 应用内存占用过高、需要在低端机上做内存分档降级、要求优化前后内存对比、或需要执行完整内存优化闭环时，必须使用此技能。即使用户只说"帮我优化这个应用的内存"、"低端机内存超标怎么降"、"做个内存前后对比"，也应立即触发此技能。 |
| [`/hmos-apifault-analysis`](./skills/harmonyos/solutions/quality/stability/hmos-apifault-analysis/SKILL.md) | 定位开发者问题。当遇到 API 调用失败或报错、错误码（如 5400xxx、801、9200 等）、crash/freeze 日志（hilog、HiviewDFX）、或需要根据日志与源码定位问题根因时使用——即使用户没明说要做诊断也应触发。输出结构化诊断报告（错误码映射 + 根因候选 + 代码修改建议）。 |
| [`/hmos-appfreeze-analysis`](./skills/harmonyos/solutions/quality/stability/hmos-appfreeze-analysis/SKILL.md) | DFX Skills，自动分析 HarmonyOS / OpenHarmony Freeze（冻屏/卡死）故障日志，定位根因并输出完整证据链。 当用户提供完整的faultlog 文件和采样栈文件、询问应用无响应/卡死/ANR 问题的根因， 或上传包含 APPFREEZE / INPUT_BLOCK / LIFECYCLE_TIMEOUT / THREAD_BLOCK_6S / BUSSINESS_THREAD_BLOCK_6S / BUSINESS_THREAD_BLOCK_6S 等关键字的日志时，必须使用此技能。 即使用户只说"帮我分析这个 freeze 日志"、"应用卡死了是什么原因"，也应立即触发此技能。 技能会按优先级逐步排除整机低内存、高负载、热限频等系统级异常，再深入分析线程堆栈、 Binder 通信链路、EventHandler 队列，最终输出唯一根因模块与修复建议。  |
| [`/hmos-cppcrash-analysis`](./skills/harmonyos/solutions/quality/stability/hmos-cppcrash-analysis/SKILL.md) | DFX Skills，分析 HarmonyOS/OpenHarmony 应用的 CppCrash（Native 层崩溃）日志， 基于信号、寄存器、Native 调用栈、符号和内存证据定位根因并给出修复建议。 当输入包含 cppcrash、NativeCrash、Reason:Signal、Fault thread info、Registers、 Memory near registers、Native .so 调用栈、SIGSEGV/SIGABRT/SIGILL/SIGBUS/SIGFPE， 或 GWP-ASan 报告时使用。若用户只说“应用崩溃/闪退”但没有 JS 或 Native 证据， 先识别日志类型；仅在确认是 Native Crash 后使用本技能。 |
| [`/hmos-fdleak-analysis`](./skills/harmonyos/solutions/quality/stability/hmos-fdleak-analysis/SKILL.md) | DFX Skills，分析 FD Leak、句柄泄漏和文件描述符泄漏日志，提取泄漏快照、句柄类型与目录分布、专项维测明细及 FdTrack 申请栈热点，并依据证据链定位根因。当用户提供 `[pid]_fd_leak.txt`、`RESOURCE_OVERLIMIT_[TIMESTAMP]_[PID].log`，或输入包含 `leaked fd nums`、`Leaked fd Top 10`、`LOGGER_MEMCHECK_FD_STACK_INFO`、`FdTrack Stack` 时使用。 |
| [`/hmos-jscrash-analysis`](./skills/harmonyos/solutions/quality/stability/hmos-jscrash-analysis/SKILL.md) | DFX Skills，分析 HarmonyOS/OpenHarmony 应用的 JS Crash（ArkTS/JS 层闪退）faultlogger 日志， 按 Reason、Error name、Error message、Error code 和 Stacktrace 定位根因，支持使用 SourceMap 反解 release/混淆堆栈并给出修复建议。 当用户提供包含 JS Crash、Reason:Error/TypeError/SyntaxError/ReferenceError/RangeError/ BusinessError/OutOfMemoryError/URIError/TerminationError/AggregateError、Error message、 Stacktrace、HybridStack、faultlogger、Cannot get SourceMap info 等字段的日志， 或询问 HarmonyOS 应用启动/点击后闪退、ArkTS 崩溃、JS Crash 怎么定位、OOM 闪退原因时， 必须使用此技能。确认崩溃原因为 OOM 且用户同时提供 rawheap 或 heapsnapshot 快照时， 必须继续调用 jsleak-analysis Skill 分析快照。即使用户只说“帮分析这个 JS Crash 日志” “应用闪退了是什么原因”“ArkTS 报错导致崩溃怎么修”，也应立即触发此技能；如果日志是 cppcrash、 freeze，或者用户询问的是原生/C++ 层崩溃，且没有 JS/ArkTS 错误字段，则不该调用此技能。  |
| [`/hmos-jsleak-analysis`](./skills/harmonyos/solutions/quality/stability/hmos-jsleak-analysis/SKILL.md) | DFX Skills，分析 HarmonyOS/ArkTS rawheap、heapsnapshot 和 Heap Cluster 报告，识别疑似 JS 内存泄漏；支持 rawheap 转换、单快照聚类、目录批处理、多快照总榜、双版本增长对比、测试版对象差值对比，以及 GlobalHandler对象关联native堆栈。当用户提供 .rawheap、.heapsnapshot、聚类报告、native hook DB，或 rawheap + htrace + js_map 三合一日志，要求运行 heap_cluster、多快照、版本对比或 GlobalHandler对象关联native堆栈，或询问哪些对象未释放、内存为何增长时使用。 |
| [`/hmos-memleak-analysis`](./skills/harmonyos/solutions/quality/stability/hmos-memleak-analysis/SKILL.md) | Analyzes HarmonyOS source code (ArkTS, JS, C/C++) to detect memory leaks.Use when (1) Performing static code analysis to catch potential leaks before deployment, (2) Reviewing PRs involving complex UI lifecycles or NAPI implementations,(3) Developing NAPI bridges between ArkTS and C++. Maps code to official specifications and applies heuristics for NAPI reference management and lifecycle synchronization. |
| [`/hmos-native-memleak-analysis`](./skills/harmonyos/solutions/quality/stability/hmos-native-memleak-analysis/SKILL.md) | 自动分析 HarmonyOS / OpenHarmony Native内存泄漏问题，基于 sample 采样文件、smaps 文件、profiler 火焰图等信息定位泄漏根因并输出完整证据链。 当用户提供 sample 采样文件、smaps 文件、profiler 火焰图、NMD 数据，或询问应用内存泄漏/内存增长/OOM问题的根因 即使用户只说"帮我分析这个内存泄漏"、"应用内存一直涨"、"native泄漏分析"、"PSS泄漏"、"DMA泄漏"、"GPU泄漏"，也应立即触发此技能。  |
| [`/hmos-runtime-fix-skill`](./skills/harmonyos/solutions/quality/stability/hmos-runtime-fix-skill/SKILL.md) | Load for ArkTS/JavaScript jscrash, runtime crash, uncaught exception, stack trace, faultlog, or hilog diagnosis. Also load when the app 闪退/崩溃/白屏, exits after 点击/启动/launch, or build succeeds but runtime fails (no compile error). Use before broad Read/Glob on crash-only tasks. |

### development — 开发（27）


| skill | 中文介绍 |
|-------|---------|
| [`/hmos-arkts-deprecated-interface-checker`](./skills/harmonyos/development/application-framework/ArkTS/hmos-arkts-deprecated-interface-checker/SKILL.md) | 检查 HarmonyOS 项目中的废弃 SDK 接口并提供修复建议。当需要清理废弃 API、升级 API 版本、优化代码质量或进行静态语法检查时使用。提供详细的迁移方案、修复优先级分类和代码示例。 |
| [`/hmos-arkts-knowledge-retriever`](./skills/harmonyos/development/application-framework/ArkTS/hmos-arkts-knowledge-retriever/SKILL.md) | Retrieve grounded ArkTS references for pure non-UI ArkTS work and ArkTS API usage. Use this skill whenever the user is writing, reviewing, testing, validating, running, or debugging ArkTS code and the answer should be backed by repository sources such as `docs/ArkTS-Language-Guide/`, `docs/ArkTS-API-Reference/`, the linter-derived `docs/linter/ArkTS_Syntax_Knowledge_From_Linter.md`, and the bundled lightweight lint tool docs `docs/linter/linter-cli.md` plus `linter-cli/` instead of model memory. This skill is especially useful for syntax rules, ArkTS-specific restrictions, API/module/member lookup, common-library usage, lightweight lint workflow lookup, runnable example lookup, snippet validation context, and figuring out which repository section to trust before suggesting code or fixes. |
| [`/hmos-arkts-syntax-checker`](./skills/harmonyos/development/application-framework/ArkTS/hmos-arkts-syntax-checker/SKILL.md) | 检查并修复 HarmonyOS 项目的 ArkTS 语法错误，自动化构建项目。当需要编译项目、修复编译错误、生成 HAP/App 产物时使用。提供静态语法检查、错误自动修复、循环构建直到成功的完整工作流程。支持错误优先级分类（P0/P1/P2）、最大重试机制、构建产物自动定位。 |
| [`/hmos-arkui-develop-skill`](./skills/harmonyos/development/application-framework/ArkUI/hmos-arkui-develop-skill/SKILL.md) | REQUIRED before writing the first .ets file of a session. Fatal gotchas list + API quick-reference for HarmonyOS ArkTS/ArkUI development. Load this skill when writing or modifying .ets files, porting TypeScript to ArkTS, or building any ArkUI page, component, layout, navigation, dialog, state-driven UI, or animation. Covers ArkTS linter rules, forbidden syntax, null safety, struct/@Component constraints, V1/V2 state management, rendering control, API parameter correctness, and UI quality. Triggers — .ets, ArkTS, ArkUI, HarmonyOS, struct, @Component, TS-to-ArkTS migration, ArkUI build error, runtime crash. |
| [`/hmos-arkui-knowledge-retriever`](./skills/harmonyos/development/application-framework/ArkUI/hmos-arkui-knowledge-retriever/SKILL.md) | ArkUI 知识检索层，按问题语境自动路由到 ArkTS 声明式或 NDK(C-API)知识库进行精准检索，不涉及代码生成或修改。触发场景：(1) 用户查询 ArkUI/ArkTS API 用法、参数细节或版本支持 (2) 验证组件/装饰器的正确用法 (3) 排查 ArkUI 编译错误码或运行时异常 (4) 询问状态管理 V1/V2 差异或迁移 (5) 查询 NDK / Native / C-API 接口或头文件 (6) 其他 skill 调用检索获取 API 证据。 |
| [`/hmos-arkui-longtake-transition`](./skills/harmonyos/development/application-framework/ArkUI/hmos-arkui-longtake-transition/SKILL.md) | 为鸿蒙(HarmonyOS)应用添加一镜到底转场效果。当用户提到一镜到底、转场动画、页面跳转动画、Navigation转场、卡片展开动画、图片查看大图动画、ezcustomtransition、自定义NavContentTransition、longtake、连续转场、沉浸式转场等关键词时，务必使用此skill。也适用于用户想要在鸿蒙应用中实现类似iOS的卡片展开、图片预览等流畅过渡效果的场景，即使他们没有明确提到"一镜到底"这个术语。 |
| [`/hmos-arkui-mvvm-pattern`](./skills/harmonyos/development/application-framework/ArkUI/hmos-arkui-mvvm-pattern/SKILL.md) | HarmonyOS ArkUI MVVM 架构技能。适用于：(1) 项目分层设计 Model/ViewModel/View (2) 目录结构规划 (3) 组件职责与数据流规范 (4) 视图架构检视以及整改项目为MVVM模式等场景。在有以下请求时触发：1.在ArkUI中明确要求使用MVVM架构来添加或重构功能，并要求保持架构简洁。2.明确要求使用MVVM架构创建或改进视图模型，并将逻辑从视图中移出。3.修复状态管理混乱的问题。4.提升项目可测试性，通过拆分结构降低复杂度。5.将已有项目整改为 MVVM 架构。 |
| [`/hmos-arkui-scenario-development`](./skills/harmonyos/development/application-framework/ArkUI/hmos-arkui-scenario-development/SKILL.md) | HarmonyOS/鸿蒙 ArkUI 场景化开发技能，用于实现、排查或验证 ArkUI(.ets) 功能，并按需求(REQ)/开发(DEV)/修复(FIX)/验证(VAL)四阶段路由到4个一级场景：ARKUI-01 ArkUI基础语法（声明式UI、条件渲染、自定义组件、Builder/BuilderParam、AttributeModifier、组件复用）;ARKUI-02 基于UI框架构建基础代码逻辑（手势/键盘交互、路由导航、组件页面、弹窗菜单、动画转场、焦点走焦、综合应用页面骨架、自定义组件FrameNode/Modifier、弹窗进阶、布局组件、图形图像、滚动列表、文本组件）;ARKUI-03 状态管理（组件状态同步，V1/V2使用、V1/V2混用、状态变量相关扩展能力）;ARKUI-04 编译与运行时（编译构建失败、ANR、AppFreeze异常卡死、白屏、崩溃闪退，长列表卡顿丢帧、不跟手、资源加载慢等问题）。不适用：与 ArkUI 无关的原生开发、非 HarmonyOS 平台、CI/CD。 |
| [`/hmos-arkui-statemgt-migration`](./skills/harmonyos/development/application-framework/ArkUI/hmos-arkui-statemgt-migration/SKILL.md) | 帮助开发者将ArkUI状态管理从V1迁移到V2。触发场景：(1) V1项目升级到V2；(2) 迁移@Component/@State/@Prop/@Link/@Observed/@ObjectLink/@Provide/@Consume/@Watch/@Reusable装饰器；(3) 迁移LocalStorage/AppStorage/PersistentStorage/Environment应用级状态；(4) 将ForEach/LazyForEach迁移到Repeat；(5) 解决animateTo在V2中的兼容问题；(6) 处理V1与V2混用场景；(7) 询问V1和V2装饰器对应关系或差异。 |
| [`/hmos-ability-insight-intent-generator`](./skills/harmonyos/development/application-framework/ability/hmos-ability-insight-intent-generator/SKILL.md) | Generates OpenHarmony intent decorator code from user requirements with automatic decorator selection. Use when the user mentions "intent", "@InsightIntent", or needs to integrate app functionality with AI entry points. Provides decorator selection decision tree, parameter validation, build config checking, and compilation verification with auto-fix.  |
| [`/hmos-ascf-assistant`](./skills/harmonyos/development/application-framework/atomic-service/hmos-ascf-assistant/SKILL.md) | 辅助开发者使用 ASCF 工具链开发 HarmonyOS 元服务。触发场景：(1) 任何提到 ASCF 的问题；(2) 检测到项目包含 ascf/ascf_src 目录（即 ASCF 项目）；(3) 需要生成元服务睫毛图；(4) 将小程序转换为 ASCF 元服务；(5) 开发ASCF元服务页面/组件/平台能力（华为账号登录、隐私托管、授权、支付、分享、web-view、定位等）；(6) 将 Taro/uni-app 项目适配为 ASCF 元服务；(7) HarmonyOS 4及以下版本元服务适配与发布。 |
| [`/hmos-ascf-convert-taro`](./skills/harmonyos/development/application-framework/atomic-service/hmos-ascf-convert-taro/SKILL.md) | 辅助开发者将 Taro 项目适配（转换）为 ASCF 元服务。当需要在 Taro（React/Vue）项目中支持 ASCF 元服务平台，或将现有 Taro 项目迁移到 ASCF 时使用此技能。提供完整的环境搭建、项目配置、package.json 脚本、常见问题排查和发布流程。 |
| [`/hmos-ascf-convert-uniapp`](./skills/harmonyos/development/application-framework/atomic-service/hmos-ascf-convert-uniapp/SKILL.md) | 辅助开发者将 uni-app 项目适配(转换)为 ASCF 元服务。当需要使用 uni-app（HBuilderX 或 CLI）开发 HarmonyOS 元服务（MP-HARMONY），或将现有 uni-app 项目迁移(转换)到 ASCF 时使用此技能。提供完整的环境搭建、HBuilderX 开发流程、CLI 配置、常见问题排查和上架审核指引。 |
| [`/hmos-atomicservice-assistant`](./skills/harmonyos/development/application-framework/atomic-service/hmos-atomicservice-assistant/SKILL.md) | 辅助鸿蒙开发者构建元服务（Atomic Service / 免安装应用）。只要用户提到元服务、atomicService、免安装、atomic service，或遇到以下任意问题，都必须使用本 Skill：创建/改造元服务项目、@atomicservice API 报错、配置隐私托管、设置可信域名、静默登录/免密登录、接入鸿蒙支付、包大小超限、AtomicServiceEnhancedWeb vs ArkWeb、Navigation 分包路由、睫毛图标、ICP备案、上架审核被拒。提供规范说明、合规检查清单、代码示例和上架最佳实践。 |
| [`/hmos-account-kit-quicklogin-client`](./skills/harmonyos/development/application-services/account-kit/hmos-account-kit-quicklogin-client/SKILL.md) | 基于 HarmonyOS Account Kit 提供华为账号一键登录客户端接入指引，实现获取匿名手机号接口与华为账号一键登录组件集成。支持获取匿名手机号后一键登录页面跳转、失败Toast提示等。在用户提及"华为账号一键登录"、"接入华为账号一键登录"、"Account Kit一键登录"或要求实现华为账号一键登录功能时使用（当前仅支持原生ArkTS框架） |
| [`/hmos-live-view-kit-build-location`](./skills/harmonyos/development/application-services/live-view-kit/hmos-live-view-kit-build-location/SKILL.md) | HarmonyOS实况窗（LiveView）代码生成助手，支持创建、更新、停止实况窗。用户输入创建/更新/结束/完整/补全实况窗代码时触发，覆盖即时配送、打车、排队、计时、航班、高铁、共享租赁、运动锻炼、导航九大场景。 |
| [`/hmos-map-kit-map-creation`](./skills/harmonyos/development/application-services/map-kit/hmos-map-kit-map-creation/SKILL.md) | HarmonyOS Map Kit地图创建开发指南，支持地图组件创建、覆盖物管理、相机控制、图层配置等能力。 适用情形：用户要求创建/绘制/展示地图、添加地图标记、绘制图形、管理覆盖物交互、控制相机位置等。  |
| [`/hmos-map-kit-poi-search`](./skills/harmonyos/development/application-services/map-kit/hmos-map-kit-poi-search/SKILL.md) | HarmonyOS Map Kit位置搜索与POI检索开发指南。当用户明确要求开发实现（如"编写代码"、"开发功能"等）位置搜索、POI检索、地理编码、逆地理编码等功能代码时触发。适用于直接调用本地SDK接口获取地图元素的场景。 适用情形：关键字搜索地点、周边地点检索、地点详情查询、地址与坐标转换。  |
| [`/hmos-map-kit-route-planning`](./skills/harmonyos/development/application-services/map-kit/hmos-map-kit-route-planning/SKILL.md) | HarmonyOS Map Kit路径规划开发指南。 适用情形：用户明确要求开发实现（如"编写代码"、"开发功能"等）路径规划、批量算路、轨迹纠偏等功能代码时触发。  |
| [`/hmos-push-kit`](./skills/harmonyos/development/application-services/push-kit/hmos-push-kit/SKILL.md) | 华为Push Kit推送服务集成助手（Master Skill/大路由）。帮助开发者快速集成HarmonyOS推送功能，获取Push Token， 配置推送服务，开通场景化消息权益。支持发送通知消息、应用内通话消息、后台消息等场景。  ============================================================ 触发条件（只有满足以下意图时才触发）： ============================================================  ✅ 正确触发场景（开发者需要接入/开发推送功能）： - "帮我在项目中接入华为推送" - "我要实现推送通知功能" - "如何接入push kit" - "帮我接入voip消息" - "接入后台消息" - "发送推送通知" - "获取push token" - "配置推送服务" - "开通推送消息权益"  ❌ 不触发场景（仅为询问、比较、测试、排查等）： - 询问对比/优缺点："鸿蒙push和苹果push区别"、"推送有什么优点" - 否定意图："我不想接入推送"、"不需要推送" - 仅输入关键词："推送"、"消息"、"后台" - 测试/调试："push通知测试"、"push调试" - 问题排查："push失败"、"推送异常" - 配置咨询："token怎么配置" - 带引号输入："push通知"、"推送消息"  路由规则： - 若开发者需要单独获取Push Token → 路由到 hmos-push-kit-token - 若开发者需要发送通知消息 → 路由到 hmos-push-kit-notification（先检查Token状态） - 若开发者需要实现voip/应用内通话 → 路由到 hmos-push-kit-voip（先检查Token状态） - 若开发者需要接入后台消息 → 路由到 hmos-push-kit-background（先检查Token状态） - 若开发者请求模糊（未明确场景）→ 必须先询问具体场景，再路由到对应子Skill  ⚠️ 重要：主Skill不生成任何场景化消息的具体代码！当开发者请求模糊时，必须先询问具体场景，再路由到对应子Skill生成完整代码。  此技能能够为开发者生成可直接编译通过的ArkTS代码，没有语法错误。 |
| [`/hmos-push-kit-background`](./skills/harmonyos/development/application-services/push-kit/hmos-push-kit/hmos-push-kit-background/SKILL.md) | 推送后台消息助手。当开发者需要实现后台消息接收、数据静默更新、或消息缓存功能时触发。  ============================================================ 触发条件（只有满足以下意图时才触发）： ============================================================  ✅ 正确触发场景： - "帮接入后台消息" - "实现数据静默更新" - "添加推送后台消息功能" - "推送后台消息" - "消息缓存到数据库" - "进程不在前台接收消息" - "需要接入后台消息功能"  ❌ 不触发场景： - 询问/概念："后台消息是什么" - 否定意图："不需要后台消息" - 仅输入关键词："后台"、"消息" - 测试/调试："后台消息测试" - 带引号输入："后台消息" - 配置咨询："后台消息怎么配置"  ⚠️ 重要提醒： - 只要需要接入后台消息功能，**必须加载本 skill** - 本 skill 提供完整的后台消息接入指导，包括消息接收、数据处理、缓存策略等 - 后台消息接入涉及数据静默更新、缓存策略等完整流程，不能凭其他 skill 的通用说明（如"同一 ability 接收多种消息类型"）自行编写  此 Skill 专注于帮助开发者实现推送后台消息的接收和配置。  前置检查： - 在继续之前，会自动检查开发者是否已接入Push Token - 如果未接入Token，会引导开发者先使用 hmos-push-kit-token Skill |
| [`/hmos-push-kit-notification`](./skills/harmonyos/development/application-services/push-kit/hmos-push-kit/hmos-push-kit-notification/SKILL.md) | 发送通知消息助手。当开发者需要实现推送通知功能、发送消息提醒、配置通知样式或点击动作时触发。  ============================================================ 触发条件（只有满足以下意图时才触发）： ============================================================  ✅ 正确触发场景： - "帮我在项目中接入推送通知" - "实现推送消息功能" - "添加推送消息功能" - "接入通知消息" - "发送通知消息" - "配置推送前台接收"  ❌ 不触发场景： - 询问/概念："通知消息是什么"、"推送有啥优点" - 否定意图："不需要通知消息" - 仅输入关键词："通知"、"推送消息" - 测试/调试："测试推送通知" - 问题排查："推送失败"、"通知异常" - 带引号输入："推送通知" - 配置咨询："通知怎么配置"  此 Skill 专注于帮助开发者实现通知消息的发送和配置。  前置检查： - 在继续之前，会自动检查开发者是否已接入Push Token - 如果未接入Token，会引导开发者先使用 hmos-push-kit-token Skill |
| [`/hmos-push-kit-token`](./skills/harmonyos/development/application-services/push-kit/hmos-push-kit/hmos-push-kit-token/SKILL.md) | Push Token 获取助手。可作为单独接入能力使用。当开发者需要集成华为推送服务、首次获取 Push Token、或 Token 获取失败时触发。  ============================================================ 触发条件（只有满足以下意图时才触发）： ============================================================  ✅ 正确触发场景： - "帮我接入push token" - "获取push token" - "首次集成推送功能" - "getToken调用失败" - "token获取报错1000900010" - 需要在项目中添加getToken代码  ❌ 不触发场景： - 询问/概念："token是什么"、"为什么需要token" - 对比问题："华为push和苹果push区别" - 仅输入关键词："token"、"push" - 否定意图："不想接入token" - 带引号输入："push token" - 配置咨询："token怎么配置"  此 Skill 专注于帮助开发者正确实现 Push Token 的获取。  重要说明： - 此 Skill 可作为单独接入能力使用 - hmos-push-kit-notification 和 hmos-push-kit-voip 在接入前会先检查 Token 状态 - 如果未接入 Token，会引导开发者先使用此 Skill |
| [`/hmos-push-kit-voip`](./skills/harmonyos/development/application-services/push-kit/hmos-push-kit/hmos-push-kit-voip/SKILL.md) | 推送应用内通话消息助手（VOIP）。当开发者需要实现语音/视频来电通知、voip功能、或呼叫接听界面时触发。  ============================================================ 触发条件（只有满足以下意图时才触发）： ============================================================  ✅ 正确触发场景： - "帮接入voip消息" - "实现语音来电通知" - "添加推送应用内通话消息功能" - "接入视频通话功能" - "应用内通话消息" - "voip呼叫接听界面" - "需要接入voip功能"  ❌ 不触发场景： - 询问/概念："voip是什么"、"语音通话怎么实现" - 否定意图："不需要voip" - 仅输入关键词："voip"、"通话" - 测试/调试："voip测试" - 带引号输入："voip"、"语音通话" - 配置咨询："voip怎么配置"  ⚠️ 重要提醒： - 只要需要接入 voip 功能，**必须加载本 skill** - 本 skill 提供完整的 voip 接入指导，包括 VoipCallService、CalleePage、CallComponent 等组件的创建 - voip 接入涉及来电处理、呼叫界面、状态上报等完整流程，不能凭其他 skill 的通用说明（如"同一 ability 接收多种消息类型"）自行编写  此 Skill 专注于帮助开发者实现应用内通话消息的推送功能。 |
| [`/hmos-one-sdk-skill`](./skills/harmonyos/development/hmos-one-sdk-skill/SKILL.md) | ⚠️ MUST LOAD before writing first .ets file that imports from @kit.*. This skill provides verified API signatures, import paths, error codes, permission requirements, and example code for 25 Kits (AccountKit, MediaKit, NetworkKit, ScanKit, LocationKit, PushKit etc.). Even if you have partial API info from other sources, this skill covers complete error codes and permission requirements they lack. Load when — (1) writing ANY @kit.* import; (2) calling Kit APIs like vibrator, Bluetooth, location, scan, account, push, network, health, wear, map, IAP, accessibility, i18n, form, widget, card, cross-device collaboration; (3) @kit.* compile errors (wrong namespace, missing exported member, type mismatch) — load BEFORE attempting fixes; |
| [`/hmos-scan-kit-customscan`](./skills/harmonyos/development/media/scan-kit/hmos-scan-kit-customscan/SKILL.md) | 帮助开发者快速接入华为 Scan Kit 自定义界面扫码能力，仅在需要支持完全自定义相机预览流 UI 界面、闪光灯控制、变焦、对焦等功能的场景使用 |
| [`/hmos-scan-kit-defaultscan`](./skills/harmonyos/development/media/scan-kit/hmos-scan-kit-defaultscan/SKILL.md) | 帮助开发者快速接入华为 Scan Kit 默认界面扫码能力，在不需要完全自定义相机界面、闪光灯控制、变焦、对焦等高级功能时优先使用 |

### test — 测试（2）


| skill | 中文介绍 |
|-------|---------|
| [`/hmos-instrument-test`](./skills/harmonyos/test/hmos-instrument-test/SKILL.md) | 在 HarmonyOS 应用/服务开发中执行模块的 Instrument Test（包括 ArkTS/JS 和 C++ 测试），支持运行、覆盖率统计、ASan 检测等模式，并可指定测试范围（模块、测试套件、单个用例）。 |
| [`/hmos-local-test`](./skills/harmonyos/test/hmos-local-test/SKILL.md) | 在 HarmonyOS 应用/服务开发中执行模块的 Local Test（ArkTS/JS 单元测试），支持运行、覆盖率统计等模式，并可指定测试范围（模块、测试套件、单个用例）。 |

### tools — DevEco 工具（8）


| skill | 中文介绍 |
|-------|---------|
| [`/deveco-autobugfix`](./skills/harmonyos/tools/deveco-studio/deveco-autobugfix/SKILL.md) | 自动执行鸿蒙应用 Bug 全流程修复，涵盖问题复现、根因分析、最小化代码修复、构建编译与运行验证。 依赖 deveco-mcp 提供 verify_ui/build_project/start_app 等能力。 使用场景：用户要求自动修复鸿蒙项目 Bug，或输入触发词：自动修复、auto fix、auto-fix、自动bug修复、autofix。 提供熔断保护、3 次构建重试上限、修复经验沉淀机制。  |
| [`/deveco-native-flow`](./skills/harmonyos/tools/deveco-studio/deveco-native-flow/SKILL.md) | 三端一致开发流水线（HarmonyOS/Android/iOS）：analyse → plan → coding → build → verify。 自包含：内嵌 HarmonyOS ArkTS 知识路由，无需外部 skill 依赖。 支持正向开发和翻译开发两种模式。  执行流程： 1. 自动检测项目类型和平台 2. 执行 analyse 阶段生成跨端技术方案（读取 references/native-analyse/SKILL.md） 3. 逐端执行 plan 阶段生成实施计划（读取 references/native-plan/SKILL.md） 4. 逐端执行 coding 阶段完成编码（读取 references/native-coding/SKILL.md） 5. 构建验证 + UI 验证  Triggers: 三端开发, native pipeline, deveco pipeline, cross-platform, 跨端开发, 技术方案, 实施计划, 编码实施  |
| [`/deveco-requirement-development`](./skills/harmonyos/tools/deveco-studio/deveco-requirement-development/SKILL.md) | 覆盖鸿蒙/HarmonyOS/ArkTS 应用需求开发流程。在用户要落地新功能/新页面/新模块、PRD、端到端需求开发或鸿蒙应用开发时使用。不用于仅询问 API 语法用法、或未声明走完整链路的单文件 Bug 修复。用户意图模糊时先澄清是否需要端到端交付。 |
| [`/deveco-studio-codelinter`](./skills/harmonyos/tools/deveco-studio/deveco-studio-codelinter/SKILL.md) | 对 HarmonyOS（鸿蒙）项目运行 DevEco Studio CodeLinter 静态代码检查，解读检查结果并提供修复建议。支持 ArkTS、TS、JS 文件，涵盖性能、安全、代码规范、正确性、跨设备适配、API 兼容性等规则集。当用户提到 codelinter、code linting、鸿蒙代码检查、鸿蒙应用质量、HarmonyOS 代码质量检查、静态代码分析、规范扫描、性能检查、安全扫描、代码审查、规则检查、lint 报告时使用。 |
| [`/deveco-studio-emulator`](./skills/harmonyos/tools/deveco-studio/deveco-studio-emulator/SKILL.md) | HarmonyOS模拟器管理助手。**首次使用必须先运行 `node scripts/setup.js --force` 配置路径**，然后才能执行模拟器启动、应用安装调试等操作。包含完整的场景化设备控制命令（旋转、电源、截屏、音量、摇一摇、折叠）。支持Windows/macOS/Linux。触发词：模拟器、emulator、hdc、推包、安装应用、启动模拟器、构建推包。 |
| [`/deveco-studio-hilog`](./skills/harmonyos/tools/deveco-studio/deveco-studio-hilog/SKILL.md) | HarmonyOS日志分析助手，专注于hilog日志查看、崩溃日志分析、日志导出(-logZip)、手动日志分析。包含完整的hilog命令、hidumper堆栈转储、崩溃日志自动解压分析功能。支持Windows/macOS/Linux跨平台。 |
| [`/deveco-studio-hvigor`](./skills/harmonyos/tools/deveco-studio/deveco-studio-hvigor/SKILL.md) | HarmonyOS应用构建工具助手，专注于使用Hvigor命令行工具构建HarmonyOS应用。包含完整的构建命令、参数说明、清理操作和CI/CD集成指南。触发词：hvigor、构建、编译、assembleHap、clean、build。 |
| [`/deveco-studio-verify`](./skills/harmonyos/tools/deveco-studio/deveco-studio-verify/SKILL.md) | HarmonyOS 设备验证工具 - 支持多设备类型验证（手机/折叠屏/平板）、应用安装、UI自动化操作、截图验证、日志收集和 Journey 测试框架。使用 hdc 命令行工具直接操作设备。适用于测试 HarmonyOS 应用在不同设备类型上的表现、验证 UI 在不同屏幕尺寸下的适配、执行 Journey 自动化测试、收集设备日志进行调试、构建产物发布前的完整验证。 |

### tooling — 审查工具（1）


| skill | 中文介绍 |
|-------|---------|
| [`/hmos-skill-reviewer`](./skills/harmonyos/tooling/hmos-skill-reviewer/SKILL.md) | Review and validate Agent Skills for compliance with Claude Skills specification. Use when evaluating SKILL.md files, checking naming conventions, validating content structure, or ensuring skills follow best practices. Provides comprehensive analysis of metadata format, content organization, progressive disclosure, and actionable vs knowledge-based content. |

### launch-and-distribute — 发布与分发（1）


| skill | 中文介绍 |
|-------|---------|
| [`/app-metadata-audit-skill`](./skills/harmonyos/launch-and-distribute/app-metadata-audit-skill/SKILL.md) | 开发者在app开发提交agc前，可利用该skill规范对应用市场的元数据（名称、描述、关键词、隐私链接等）进行自动化合规性审查。支持华为应用市场审核规范，防止因低级错误导致被拒。 |

## 三、Android Skills（22 个，description 已中文化）

### android（22）


| skill | 中文介绍 |
|-------|---------|
| [`/agp-9-upgrade`](./skills/android/build-system/agp/agp-9-upgrade/SKILL.md) | Upgrades, or migrates, an Android project to use Android Gradle Plugin (AGP) version 9. Do not use this skill for migrating Kotlin Multiplatform (KMP) projects. |
| [`/camerax`](./skills/android/camera/camerax/SKILL.md) | Provide technical guidance for Android camera development with CameraX. Use when implementing camera features, handling asynchronous recording lifecycles, wiring low-level hardware interop using CameraX, or integrating ML Kit or Media3 effects. |
| [`/appfunctions`](./skills/android/device-ai/appfunctions/SKILL.md) | Analyzes Android apps to identify key user workflows for AppFunctions such as creating a note, playing media, or sending an automated or AI agent triggered message, voice commands, or system shortcuts, without needing to open the app UI. Generates Kotlin code to expose these workflows to the Android system, allowing agents to discover and execute them on-device. Also refines KDoc documentation to ensure AI agents correctly understand and use the provided functionality. |
| [`/android-cli`](./skills/android/devtools/android-cli/SKILL.md) | Provides instructions for installing and using the `android` CLI. The `android` command-line tool is a critical tool for Android development and helps you create new Android projects, run Android apps on devices, manage and interact with Android virtual devices (including screenshots and UI inspection), manage Android SDK components, look up official Android documentation, and discover and install official Android skills. |
| [`/restore-credentials`](./skills/android/identity/restore-credentials/SKILL.md) | Provides knowledge and workflows to implement Android's Restore Credentials feature using the androidx.credentials library. Use this skill to create, sign in with, and delete restore keys, enabling silent user sign-in on new devices after a restore. It covers version compatibility, dependencies, server-side prerequisites, and the complete client-side implementation for creating, retrieving, and clearing restore keys. |
| [`/verified-email`](./skills/android/identity/verified-email/SKILL.md) | Provides a complete workflow for implementing verified email retrieval on Android Credential Manager API. Use this skill to integrate a secure, OTP-less email verification flow into an Android app. This skill solves the problem of high-friction sign-up processes by leveraging cryptographically verified credentials from trusted providers like Google. |
| [`/adaptive`](./skills/android/jetpack-compose/adaptive/SKILL.md) | Instructions to make or update an app's UI so that it adapts to different Android devices including phones, tablets, foldables, laptops, desktop, TV, Auto and XR. It includes how to handle different window sizes, pointing devices (such as mouse) and text entry devices (such as keyboard) using the Compose MediaQuery API. It also covers multi-pane layouts using Navigation3 Scenes, adaptive UI components (such as buttons) with varying target sizes, and adaptive layouts (including navigation areas - nav rails and nav bars) using the Compose Grid and FlexBox APIs. |
| [`/migrate-xml-views-to-jetpack-compose`](./skills/android/jetpack-compose/migration/migrate-xml-views-to-jetpack-compose/SKILL.md) | Provides a structured workflow for migrating an Android XML View to Jetpack Compose. This skill details the step-by-step process, from planning and dependency setup, to theming and layout migration, validation and XML cleanup. Use this skill when you need to migrate an XML View to Jetpack Compose in an Android project. It solves the problem of converting the UI of a legacy XML View into modern, declarative Compose components while maintaining interoperability. |
| [`/styles`](./skills/android/jetpack-compose/theming/styles/SKILL.md) | Use this skill to integrate the Jetpack Compose Styles API into an Android project. This skill guides you through upgrading dependencies, setting up component themes, making custom components styleable, and migrating existing layout properties to use unified styles. Migrate custom design system components, replace hard coded parameters with Style attributes, and use Modifier.styleable for interaction states. |
| [`/media3-cast-integration`](./skills/android/media/media3-cast-integration/SKILL.md) | Implements Google Cast support in Android apps using Jetpack Media3. Handles adding build dependencies, updating manifest, configuring OptionsProvider, and managing CastPlayer or RemoteCastPlayer for playback in both Compose and View-based UIs. Use when adding Cast functionality or migrating from legacy Cast SDK to Media3 Cast. |
| [`/navigation-3`](./skills/android/navigation/navigation-3/SKILL.md) | Learn how to install and migrate to Jetpack Navigation 3, and how to implement features and patterns such as deep links, multiple backstacks, scenes (dialogs, bottom sheets, list-detail, two-pane, supporting pane), conditional navigation (such as logged-in navigation versus anonymous), returning results from flows, integration with Hilt, ViewModel, Kotlin, and view interoperability. |
| [`/r8-analyzer`](./skills/android/performance/r8-analyzer/SKILL.md) | Analyzes Android build files and R8 keep rules to identify redundancies, broad package-wide rules, and rules that subsume library consumer keep rules. Use when developers want to optimize their app's size, remove redundant or overly broad keep rules, or troubleshoot Proguard configurations. |
| [`/engage-sdk-integration`](./skills/android/play/engage-sdk-integration/SKILL.md) | Helps developers integrate, debug, and resolve Play Engage SDK implementation issues. Use when adding Engage SDK support, generating publishing code, mapping data classes to entities, or fixing SDK-related errors. |
| [`/play-billing-library-version-upgrade`](./skills/android/play/play-billing-library-version-upgrade/SKILL.md) | Use this skill when upgrading or migrating an Android project from any legacy Google Play Billing Library (PBL) version to the latest stable version of PBL. |
| [`/play-policy-insights`](./skills/android/play/play-policy-insights/SKILL.md) | Automated auditor designed to verify Android applications against Google Play Policy domains. It cross-references static code analysis with Play Store declarations to generate deterministic compliance reports, identifying undeclared data collection, architectural risks, and missing disclosures across Permissions and APIs Hygiene, User Account and Identity, and Data Safety and Privacy domains. |
| [`/android-profiler`](./skills/android/profilers/android-profiler/SKILL.md) | Manages Android performance profiling and debugging. Triggers when the user asks to record or analyze Android performance data, such as system traces, heap dumps, method recordings, callstack samples, memory allocations, or investigate bottlenecks, jank, memory leaks, and app startup issues on Android, or when the user asks to write, debug, or execute ad-hoc SQL queries. Applies to both user and system apps or services.  |
| [`/android-intent-security`](./skills/android/security/android-intent-security/SKILL.md) | Best practices for Android Intent security. Use this skill when auditing component configurations in AndroidManifest.xml activities, services, receivers) or source code handling incoming Intents (getIntent, getParcelableExtra) to prevent Intent Redirection and unauthorized access. |
| [`/edge-to-edge`](./skills/android/system/edge-to-edge/SKILL.md) | Use this skill to migrate your Jetpack Compose app to add adaptive edge-to-edge support and troubleshoot common issues. Use this skill to fix UI components (like buttons or lists) that are obscured by or overlapping with the navigation bar or status bar, fix IME insets, and fix system bar legibility. |
| [`/testing-setup`](./skills/android/testing/testing-setup/SKILL.md) | Analyze and create a testing strategy for native Android apps - install testing libraries, set up test infrastructure, create harnesses for unit tests, UI tests, screenshot tests, and end-to-end tests. |
| [`/leanback-to-compose-tv-migration`](./skills/android/tv/leanback-to-compose-tv-migration/SKILL.md) | Provides instructions and architectural patterns for migrating Android TV applications from legacy Leanback UI Toolkit, Android Views, or Support Fragments to Jetpack Compose for TV (androidx.tv). Use this skill for Leanback to Compose migrations, including browse screen, settings screen, authentication screen, login screen, or video playback screen migrations, or when replacing BrowseSupportFragment, LeanbackSettingsFragment, PreferenceFragment, BaseLeanbackPreferenceFragmentCompat, VideoSupportFragment, GuidedStepSupportFragment, SearchSupportFragment, VerticalGridSupportFragment, Presenter, ArrayObjectAdapter, or CursorMapper with modern Compose equivalents, implementing immersive carousels with focus memory, Media3 video playback with PlayerSurface, or custom 10-foot hero layouts. |
| [`/wear-compose-m3`](./skills/android/wear/wear-compose-m3/SKILL.md) | Expert guidance for working with Wear OS Compose Material3. Use this skill when creating, updating, or migrating Wear OS projects. This includes the androidx.wear.compose.material3, androidx.wear.compose.foundation, and androidx.wear.compose.navigation3 libraries. Also working with core components such as AppScaffold, ScreenScaffold, and TransformingLazyColumn, and core Wear OS concepts such as ambient mode. Migration from lower versions such as Material 2.5 and Horologist. |
| [`/display-glasses-with-jetpack-compose-glimmer`](./skills/android/xr/display-glasses-with-jetpack-compose-glimmer/SKILL.md) | Provides guidelines for developing projected Android XR apps for display glasses using the Jetpack Compose Glimmer UI toolkit. This skill covers foundational Glimmer design principles, workflows for implementing Jetpack Compose Glimmer, and interaction models for the glasses form factor. Use this skill to build an Android XR Augmented Experience app with Jetpack Compose Glimmer that adheres to the Glimmer design system for optimized glasses styling. |

## 四、安装指导 Skills（2 个）

| skill | 中文介绍 |
|-------|---------|
| [`/install-android-skills`](./skills/meta/install-android-skills/SKILL.md) | 介绍 Android agent skills 并指导安装。当用户想获取 Android 开发技能、询问 Android skills 怎么装、或提到 Jetpack Compose/CameraX/AGP/Perfetto/R8/Play Billing/Wear OS/Android XR 等 Android 开发场景时使用。涵盖官方 `android` CLI 安装、`android skills add` 用法、以及本仓库中文化版的获取途径。 |
| [`/install-harmonyos-skills`](./skills/meta/install-harmonyos-skills/SKILL.md) | 介绍 HarmonyOS（鸿蒙）agent skills 并指导安装。当用户想获取鸿蒙开发技能、询问 HarmonyOS/OpenHarmony/ArkTS/ArkUI/DevEco skills 怎么装、或提到鸿蒙应用开发、多设备适配、稳定性分析等场景时使用。涵盖上游来源、官方安装方式、以及本仓库中文化版的获取途径。 |

## 致谢与许可

本仓库整合自以下上游，在此致谢并保留其版权声明：

- **mattpocock/skills**（MIT）— Copyright (c) 2026 Matt Pocock。MIT 许可证要求保留版权声明，全文见上游 [LICENSE](https://github.com/mattpocock/skills/blob/main/LICENSE)。
- **android/skills**（Apache License 2.0）— Copyright Google LLC。详见上游 [LICENSE](https://github.com/android/skills/blob/main/LICENSE.txt)。
- **HarmonyOS_Skills/harmonyos-agent-skills** — 遵循其原有许可声明。

本仓库整体采用 GPL v3 许可证（见 [LICENSE](./LICENSE)）。中文翻译与整合工作为 KenKenSkills 项目的贡献。

## 维护

如需同步上游更新或新增其他优秀 skills 仓库，请参见 [MAINTENANCE.md](./MAINTENANCE.md)。
