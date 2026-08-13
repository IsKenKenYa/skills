# KenKenSkills

> 收集好用的 agent skills，把介绍（description）本地化为简体中文，统一管理、方便更新。

本仓库整合多个上游的优秀 agent skills：
- [mattpocock/skills](https://github.com/mattpocock/skills)（MIT）— 通用编码/生产力 skill，description 已译为中文
- [HarmonyOS_Skills/harmonyos-agent-skills](https://gitcode.com/HarmonyOS_Skills/harmonyos-agent-skills.git) — 鸿蒙开发 skill，上游原生中文，原样保留
- [android/skills](https://github.com/android/skills)（Apache 2.0）— Android 官方开发 skill，description 已译为中文

另有 2 个自建的安装指导 skill（`skills/meta/`），介绍各上游及官方 CLI 安装方式。

## 安装

推荐使用 GitHub CLI 的 `gh skill`，它能记录来源、支持 pin 到版本/提交，并可做更新检测：

```bash
gh skill install IsKenKenYa/skills skills/<分类>/<skill> --agent codex --scope user
```

请使用仓库内的完整 skill 路径，例如 `skills/engineering/tdd`。`--scope user` 会安装到用户级目录；在项目目录中省略它时，`gh skill` 会默认使用项目级位置。分类路径也能避免 `gh skill` 将嵌套目录当作不完整安装目标。

如果你想交互式浏览并一次性选择多个 agent，也可以继续使用 `skills` CLI：

```bash
npx skills@latest add IsKenKenYa/skills
```

然后挑选你想要的 skill 和目标编码代理即可。注意：`npx skills` 的交互树可能把本仓库显示成一个根节点（如 “KenKen Skills”），这只是安装器展示方式；仓库内仍按 `engineering`、`productivity`、`android`、`harmonyos` 等目录分类。也可按上游官方方式安装，详见 [`/install-harmonyos-skills`](./skills/meta/install-harmonyos-skills/SKILL.md) 和 [`/install-android-skills`](./skills/meta/install-android-skills/SKILL.md)。

## 设计原则

- **专用 skill 按平台大类隔离**：通用 skill（mattpocock）放 `skills/<分类>/`；专用 skill 放 `skills/<平台>/`（`harmonyos/`、`android/`），平台内再按技术域细分，避免专用与通用混淆。
- **翻译对象仅限 description**：`name`、`disable-model-invocation`、`metadata`、`license` 等字段，以及全部正文指令，一律保持原样，不改变 skill 语义、不破坏 AI 执行完整性。
- **触发词保留原型**：`grill`/`tdd`/`triage`/`Jetpack Compose`/`CameraX`/`R8`/`Perfetto`/`ArkTS`/`ArkUI` 等关键词不翻译，必要时加中文括注。
- **HarmonyOS 原生中文不翻译**：上游 skill 本身就是中文（含中英混合），原样保留。
- **上游引用隔离**：原版上游仓库作为 git submodule 放在独立的 `upstream-refs` 分支，主分支保持干净——`npx skills add` 只会扫到中文化版本，不会被原版污染。
- **内部子 skill 用官方机制隔离**：部分 skill（如 HarmonyOS 的 `deveco-native-flow`）内含 `references/` 子 skill 作为父 skill 的知识库，带 `metadata.internal: true`，扫描时跳过但安装父 skill 时递归复制带走。
- **已删除上游不复活**：`mattpocock/skills` 已在 2026-06-17 删除 `zoom-out`，理由是实际使用率低。本仓库按最新版上游同步，不把它作为漏同步项；若未来要保留历史 skill，应先放入明确的 archived/legacy 区域并单独决策。

调用方式说明：标记为「用户调用」的 skill 只能用 `/skill名` 手动触发；「模型/用户调用」的 skill 还能被模型根据上下文语义自动触发。

## Skill 清单（共 112 个）

## 一、mattpocock 通用 Skills（35 个，description 已中文化）

### Engineering — 工程类（18）

*日常编码工作*

| skill | 调用方式 | 中文介绍 |
|-------|---------|---------|
| [`/ask-matt`](./skills/engineering/ask-matt/SKILL.md) | 用户调用 | 询问哪种 skill 或流程适合你的场景。是本仓库中 skill 的路由器。 |
| [`/code-review`](./skills/engineering/code-review/SKILL.md) | 模型/用户调用 | 沿两个轴线审查从固定点（commit、branch、tag 或 merge-base）开始的变更：标准（代码是否遵循仓库记录的编码规范）和规格（代码是否符合原始 issue/spec 的要求）。并行运行两个子 agent 的审查并并列报告结果。适用于用户要求审查分支、PR、进行中的变更，或要求‘review since X’时。 |
| [`/codebase-design`](./skills/engineering/codebase-design/SKILL.md) | 模型/用户调用 | 设计深层模块（deep module）的共享词汇。当用户想设计或改进模块接口、寻找深化机会、决定接缝（seam）位置、让代码更易测试或更易被 AI 导航，或当其他 skill 需要深层模块词汇时使用。 |
| [`/diagnosing-bugs`](./skills/engineering/diagnosing-bugs/SKILL.md) | 模型/用户调用 | 针对疑难 bug 和性能回归的诊断循环。当用户说"诊断"/"调试这个"，或报告某东西坏了/抛异常/失败/变慢时使用。 |
| [`/domain-modeling`](./skills/engineering/domain-modeling/SKILL.md) | 模型/用户调用 | 构建并打磨项目的领域模型。当用户想敲定领域术语或统一语言、记录架构决策（ADR），或当其他 skill 需要维护领域模型时使用。 |
| [`/grill-with-docs`](./skills/engineering/grill-with-docs/SKILL.md) | 用户调用 | 一场无情的访谈，用来打磨计划或设计，同时会顺势产出文档（ADR 和术语表）。 |
| [`/implement`](./skills/engineering/implement/SKILL.md) | 用户调用 | 基于规格说明或一组工单实现一项工作。 |
| [`/improve-codebase-architecture`](./skills/engineering/improve-codebase-architecture/SKILL.md) | 用户调用 | 扫描代码库寻找深化机会，以可视化 HTML 报告呈现，然后针对你选中的那一个进行 grill 访谈。 |
| [`/prototype`](./skills/engineering/prototype/SKILL.md) | 模型/用户调用 | 构建一次性原型来回答设计问题。当用户想检查状态模型或逻辑是否合理，或探索 UI 应该是什么样子时使用。 |
| [`/research`](./skills/engineering/research/SKILL.md) | 模型/用户调用 | 基于高可信度的一手来源调查问题，并将发现以 Markdown 文件形式保存到仓库中。当用户需要研究某个主题、收集文档或 API 事实，或将阅读调研工作委托给后台代理时使用。 |
| [`/resolving-merge-conflicts`](./skills/engineering/resolving-merge-conflicts/SKILL.md) | 模型/用户调用 | 当你需要解决进行中的 git merge/rebase 冲突时使用。 |
| [`/setup-matt-pocock-skills`](./skills/engineering/setup-matt-pocock-skills/SKILL.md) | 用户调用 | 为工程类 skill 配置本仓库——设置 issue 追踪器、triage 标签词汇和领域文档布局。在其他工程类 skill 首次使用前运行一次。 |
| [`/tdd`](./skills/engineering/tdd/SKILL.md) | 模型/用户调用 | 测试驱动开发（TDD）。当用户想以测试优先的方式构建功能或修 bug、提到"red-green-refactor"，或想要集成测试时使用。 |
| [`/to-spec`](./skills/engineering/to-spec/SKILL.md) | 用户调用 | 把当前对话转化为规格说明并发布到项目 issue 追踪器——无需访谈，只是对已讨论内容的综合提炼。 |
| [`/to-tickets`](./skills/engineering/to-tickets/SKILL.md) | 用户调用 | 把计划、规格说明或当前对话拆解为一组示踪子弹（tracer-bullet）工单，每个工单声明其阻塞边，发布到配置好的追踪器——阻塞边可以是本地文件中的文本，也可以是真实追踪器上的原生阻塞链接。 |
| [`/triage`](./skills/engineering/triage/SKILL.md) | 用户调用 | 让 issue 和外部 PR 经过一组 triage 角色的状态机——分类、验证、必要时 grill 访谈，并撰写代理可直接执行的简报（brief）。 |
| [`/wayfinder`](./skills/engineering/wayfinder/SKILL.md) | 用户调用 | 把超出单个 agent 会话容量的大型工作规划为 issue 跟踪器上的共享决策工单地图，并逐一解决，直到通往目标的路径清晰。 |
| [`/wizard`](./skills/engineering/wizard/SKILL.md) | 模型/用户调用 | 生成交互式 bash 向导，引导人类完成只有他们才能执行的步骤。适用于配置基础设施、设置凭据或 CI secret、操作陌生的第三方控制台，或执行一次性迁移与切换。不要用于 agent 自己能够完成的步骤。 |

### Productivity — 生产力类（7）

*日常非编码工作流工具*

| skill | 调用方式 | 中文介绍 |
|-------|---------|---------|
| [`/grill-me`](./skills/productivity/grill-me/SKILL.md) | 用户调用 | 一场无情的访谈，用来打磨计划或设计。 |
| [`/grilling`](./skills/productivity/grilling/SKILL.md) | 模型/用户调用 | 就一个计划、决策或想法对用户进行不留情面的追问。适用于用户希望压力测试自己的思路，或使用任何 ‘grill’ 触发语时。 |
| [`/handoff`](./skills/productivity/handoff/SKILL.md) | 用户调用 | 把当前对话压缩成一份交接（handoff）文档，供另一个代理接手。 |
| [`/teach`](./skills/productivity/teach/SKILL.md) | 用户调用 | 在当前工作区内，教会用户一项新 skill 或概念。 |
| [`/to-questionnaire`](./skills/productivity/to-questionnaire/SKILL.md) | 用户调用 | 把你无法完全回答的决策转化为供他人填写的问卷。 |
| [`/wait-what`](./skills/productivity/wait-what/SKILL.md) | 用户调用 | 停一下。上一条消息没有讲清楚，请换一种方式重新说明。 |
| [`/writing-for-agents`](./skills/productivity/writing-for-agents/SKILL.md) | 模型/用户调用 | 为 agent 编写文档。适用于创建或编辑 skill，或修改 AGENTS.md、CLAUDE.md。 |

### Misc — 杂项（4）

*保留但较少使用*

| skill | 调用方式 | 中文介绍 |
|-------|---------|---------|
| [`/git-guardrails-claude-code`](./skills/misc/git-guardrails-claude-code/SKILL.md) | 模型/用户调用 | 设置 Claude Code 钩子，在危险的 git 命令（push、reset --hard、clean、branch -D 等）执行前拦截。当用户想防止破坏性 git 操作、添加 git 安全钩子，或在 Claude Code 中阻止 git push/reset 时使用。 |
| [`/migrate-to-shoehorn`](./skills/misc/migrate-to-shoehorn/SKILL.md) | 模型/用户调用 | 把测试文件从 `as` 类型断言迁移到 @total-typescript/shoehorn。当用户提到 shoehorn、想替换测试里的 `as`，或需要部分测试数据时使用。 |
| [`/scaffold-exercises`](./skills/misc/scaffold-exercises/SKILL.md) | 模型/用户调用 | 创建带章节、题目、解答和讲解的练习目录结构，且能通过 lint。当用户想脚手架化练习、创建练习桩，或搭建新课程章节时使用。 |
| [`/setup-pre-commit`](./skills/misc/setup-pre-commit/SKILL.md) | 模型/用户调用 | 在当前仓库设置带 lint-staged（Prettier）、类型检查和测试的 Husky pre-commit 钩子。当用户想添加 pre-commit 钩子、设置 Husky、配置 lint-staged，或在提交时加入格式化/类型检查/测试时使用。 |

### In-progress — 进行中（6）

*上游公开的 Beta skills*

| skill | 调用方式 | 中文介绍 |
|-------|---------|---------|
| [`/claude-handoff`](./skills/in-progress/claude-handoff/SKILL.md) | 用户调用 | 把当前对话交接给一个新的后台代理，由其立即接手后续工作。 |
| [`/loop-me`](./skills/in-progress/loop-me/SKILL.md) | 用户调用 | 在当前工作区内，通过 grilling 访谈把你想构建的重复工作流打磨成可实现的规格说明。 |
| [`/setup-ts-deep-modules`](./skills/in-progress/setup-ts-deep-modules/SKILL.md) | 用户调用 | 为 TypeScript 仓库接入 dependency-cruiser，让每个包成为深层模块（deep module）：实现隐藏在子目录中，只能通过入口文件访问。仅用户调用。 |
| [`/writing-beats`](./skills/in-progress/writing-beats/SKILL.md) | 用户调用 | 写作，深入利用（exploit）：将原始素材组织成一段节拍之旅，并在每个节拍依赖术语前先把该术语讲清。 |
| [`/writing-fragments`](./skills/in-progress/writing-fragments/SKILL.md) | 用户调用 | 写作，探索：挖掘原始片段，暂不施加结构。 |
| [`/writing-shape`](./skills/in-progress/writing-shape/SKILL.md) | 用户调用 | 写作，深入利用（exploit）：逐段把原始素材塑造成文章。 |

## 二、HarmonyOS（鸿蒙）Skills（53 个，上游原生中文原样保留）

### design — 设计（1）

| skill | 中文介绍 |
|-------|---------|
| [`/hmos-design-visual-mobile`](./skills/harmonyos/design/mobile/hmos-design-visual-mobile/SKILL.md) | HarmonyOS 移动端页面视觉还原技能。基于仓库内设计规范文档与组件模板，生成符合 HarmonyOS Design Token 标准的高保真移动端 HTML 页面。触发场景：(1) 用户要求生成/还原 HarmonyOS 移动端页面 (2) 用户提供设计稿/截图/参考图，要求还原为 HarmonyOS 风格 HTML 页面 (3) 用户提到"视觉还原"/"高保真页面"/"移动端页面"并涉及 HarmonyOS，用于需要生成符合鸿蒙规范的移动端设计稿的场景 |

### solutions — 解决方案（16）

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
| [`/hmos-appfreeze-analysis`](./skills/harmonyos/solutions/quality/stability/hmos-appfreeze-analysis/SKILL.md) | DFX Skills，自动分析 HarmonyOS / OpenHarmony Freeze（冻屏/卡死）故障日志，定位根因并输出完整证据链。 当用户提供完整的faultlog 文件和采样栈文件、询问应用无响应/卡死/ANR 问题的根因， 或上传包含 APPFREEZE / INPUT_BLOCK / LIFECYCLE_TIMEOUT 等关键字的日志时，必须使用此技能。 即使用户只说"帮我分析这个 freeze 日志"、"应用卡死了是什么原因"，也应立即触发此技能。 技能会按优先级逐步排除整机低内存、高负载、热限频等系统级异常，再深入分析线程堆栈、 Binder 通信链路、EventHandler 队列，最终输出唯一根因模块与修复建议。 |
| [`/hmos-cppcrash-analysis`](./skills/harmonyos/solutions/quality/stability/hmos-cppcrash-analysis/SKILL.md) | DFX Skills，分析 HarmonyOS/OpenHarmony 应用的 CppCrash（Native 层崩溃）故障日志，定位根因并给出修复建议。当用户提供 cppcrash 日志、粘贴 Native 崩溃堆栈、询问 SIGSEGV/SIGABRT/SIGILL/SIGBUS 崩溃原因、或上传含有信号值/寄存器/调用栈的故障日志时，必须使用此技能。即使用户只说"帮我分析这个崩溃日志"、"应用崩溃了是什么原因"、"空指针崩溃怎么排查"，也应立即触发此技能。 |
| [`/hmos-jscrash-analysis`](./skills/harmonyos/solutions/quality/stability/hmos-jscrash-analysis/SKILL.md) | DFX Skills，分析 HarmonyOS/OpenHarmony 应用的 JS Crash（ArkTS/JS 层闪退）faultlogger 日志， 按 Reason、Error name、Error message、Error code 和 Stacktrace 定位根因并给出修复建议。 当用户提供包含 JS Crash、Reason:Error/TypeError/SyntaxError/ReferenceError/RangeError/ BusinessError/OutOfMemoryError/URIError/TerminationError/AggregateError、Error message、 Stacktrace、HybridStack、faultlogger、Cannot get SourceMap info 等字段的日志， 或询问 HarmonyOS 应用启动/点击后闪退、ArkTS 崩溃、JS Crash 怎么定位、OOM 闪退原因时， 必须使用此技能。即使用户只说“帮分析这个 JS Crash 日志”“应用闪退了是什么原因” “ArkTS 报错导致崩溃怎么修”，也应立即触发此技能。 |
| [`/hmos-jsleak-analysis`](./skills/harmonyos/solutions/quality/stability/hmos-jsleak-analysis/SKILL.md) | DFX Skills，分析 rawheap / heapsnapshot 聚类后的内存对象数据，识别疑似内存泄漏。当用户提供 .rawheap 文件、.heapsnapshot 文件、堆内存聚类报告、heap_cluster.mjs 输出结果，或询问"哪些对象在泄漏""哪些对象没有释放""分析这份内存报告""帮看下内存泄漏""为什么内存涨这么多"时，必须使用此技能。即使用户只贴出一段包含"引用链 / Retainer Chain / Retained Size / 聚类 / GC Root"的报告或表格，也应立即触发此技能。技能内置 rawheap_translator 与 heap_cluster 聚类脚本，能先把 .rawheap 转成 .heapsnapshot，再处理 .heapsnapshot 原始文件，并按 Detached、全局引用、闭包、异常大小四类规则进行根因定位，输出结构化的泄漏嫌疑清单。 |
| [`/hmos-memleak-analysis`](./skills/harmonyos/solutions/quality/stability/hmos-memleak-analysis/SKILL.md) | Analyzes HarmonyOS source code (ArkTS, JS, C/C++) to detect memory leaks.Use when (1) Performing static code analysis to catch potential leaks before deployment, (2) Reviewing PRs involving complex UI lifecycles or NAPI implementations,(3) Developing NAPI bridges between ArkTS and C++. Maps code to official specifications and applies heuristics for NAPI reference management and lifecycle synchronization. |
| [`/hmos-native-memleak-analysis`](./skills/harmonyos/solutions/quality/stability/hmos-native-memleak-analysis/SKILL.md) | 自动分析 HarmonyOS / OpenHarmony Native内存泄漏问题，基于 sample 采样文件、smaps 文件、profiler 火焰图等信息定位泄漏根因并输出完整证据链。 当用户提供 sample 采样文件、smaps 文件、profiler 火焰图、NMD 数据，或询问应用内存泄漏/内存增长/OOM问题的根因 即使用户只说"帮我分析这个内存泄漏"、"应用内存一直涨"、"native泄漏分析"、"PSS泄漏"、"DMA泄漏"、"GPU泄漏"，也应立即触发此技能。 |
| [`/hmos-runtime-fix-skill`](./skills/harmonyos/solutions/quality/stability/hmos-runtime-fix-skill/SKILL.md) | Load for ArkTS/JavaScript jscrash, runtime crash, uncaught exception, stack trace, faultlog, or hilog diagnosis. Also load when the app 闪退/崩溃/白屏, exits after 点击/启动/launch, or build succeeds but runtime fails (no compile error). Use before broad Read/Glob on crash-only tasks. |

### development — 开发（24）

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
| [`/hmos-ability-insight-intent-generator`](./skills/harmonyos/development/application-framework/ability/hmos-ability-insight-intent-generator/SKILL.md) | Generates OpenHarmony intent decorator code from user requirements with automatic decorator selection. Use when the user mentions "intent", "@InsightIntent", or needs to integrate app functionality with AI entry points. Provides decorator selection decision tree, parameter validation, build config checking, and compilation verification with auto-fix. |
| [`/hmos-ascf-assistant`](./skills/harmonyos/development/application-framework/atomic-service/hmos-ascf-assistant/SKILL.md) | 辅助开发者使用 ASCF 工具链开发 HarmonyOS 元服务。触发场景：(1) 任何提到 ASCF 的问题；(2) 检测到项目包含 ascf/ascf_src 目录（即 ASCF 项目）；(3) 需要生成元服务睫毛图；(4) 将小程序转换为 ASCF 元服务；(5) 开发ASCF元服务页面/组件/平台能力（华为账号登录、隐私托管、授权、支付、分享、web-view、定位等）；(6) 将 Taro/uni-app 项目适配为 ASCF 元服务；(7) HarmonyOS 4及以下版本元服务适配与发布。 |
| [`/hmos-ascf-convert-taro`](./skills/harmonyos/development/application-framework/atomic-service/hmos-ascf-convert-taro/SKILL.md) | 辅助开发者将 Taro 项目适配（转换）为 ASCF 元服务。当需要在 Taro（React/Vue）项目中支持 ASCF 元服务平台，或将现有 Taro 项目迁移到 ASCF 时使用此技能。提供完整的环境搭建、项目配置、package.json 脚本、常见问题排查和发布流程。 |
| [`/hmos-ascf-convert-uniapp`](./skills/harmonyos/development/application-framework/atomic-service/hmos-ascf-convert-uniapp/SKILL.md) | 辅助开发者将 uni-app 项目适配(转换)为 ASCF 元服务。当需要使用 uni-app（HBuilderX 或 CLI）开发 HarmonyOS 元服务（MP-HARMONY），或将现有 uni-app 项目迁移(转换)到 ASCF 时使用此技能。提供完整的环境搭建、HBuilderX 开发流程、CLI 配置、常见问题排查和上架审核指引。 |
| [`/hmos-atomicservice-assistant`](./skills/harmonyos/development/application-framework/atomic-service/hmos-atomicservice-assistant/SKILL.md) | 辅助鸿蒙开发者构建元服务（Atomic Service / 免安装应用）。只要用户提到元服务、atomicService、免安装、atomic service，或遇到以下任意问题，都必须使用本 Skill：创建/改造元服务项目、@atomicservice API 报错、配置隐私托管、设置可信域名、静默登录/免密登录、接入鸿蒙支付、包大小超限、AtomicServiceEnhancedWeb vs ArkWeb、Navigation 分包路由、睫毛图标、ICP备案、上架审核被拒。提供规范说明、合规检查清单、代码示例和上架最佳实践。 |
| [`/hmos-account-kit-quicklogin-client`](./skills/harmonyos/development/application-services/account-kit/hmos-account-kit-quicklogin-client/SKILL.md) | 基于 HarmonyOS Account Kit 提供华为账号一键登录客户端接入指引，实现获取匿名手机号接口与华为账号一键登录组件集成。支持获取匿名手机号后一键登录页面跳转、失败Toast提示等。在用户提及"华为账号一键登录"、"接入华为账号一键登录"、"Account Kit一键登录"或要求实现华为账号一键登录功能时使用（当前仅支持原生ArkTS框架） |
| [`/hmos-live-view-kit-build-location`](./skills/harmonyos/development/application-services/live-view-kit/hmos-live-view-kit-build-location/SKILL.md) | HarmonyOS实况窗（LiveView）代码生成助手，支持创建、更新、停止实况窗。用户输入创建/更新/结束/完整/补全实况窗代码时触发，覆盖即时配送、打车、排队、计时、航班、高铁、共享租赁、运动锻炼、导航九大场景。 |
| [`/hmos-push-kit`](./skills/harmonyos/development/application-services/push-kit/hmos-push-kit/SKILL.md) | 华为Push Kit推送服务集成助手（Master Skill/大路由）。帮助开发者快速集成HarmonyOS推送功能，获取Push Token， 配置推送服务，开通场景化消息权益。支持发送通知消息、应用内通话消息、后台消息等场景。 ============================================================ 触发条件（只有满足以下意图时才触发）： ============================================================ ✅ 正确触发场景（开发者需要接入/开发推送功能）： - "帮我在项目中接入华为推送" - "我要实现推送通知功能" - "如何接入push kit" - "帮我接入voip消息" - "接入后台消息" - "发送推送通知" - "获取push token" - "配置推送服务" - "开通推送消息权益" ❌ 不触发场景（仅为询问、比较、测试、排查等）： - 询问对比/优缺点："鸿蒙push和苹果push区别"、"推送有什么优点" - 否定意图："我不想接入推送"、"不需要推送" - 仅输入关键词："推送"、"消息"、"后台" - 测试/调试："push通知测试"、"push调试" - 问题排查："push失败"、"推送异常" - 配置咨询："token怎么配置" - 带引号输入："push通知"、"推送消息" 路由规则： - 若开发者需要单独获取Push Token → 路由到 hmos-push-kit-token - 若开发者需要发送通知消息 → 路由到 hmos-push-kit-notification（先检查Token状态） - 若开发者需要实现voip/应用内通话 → 路由到 hmos-push-kit-voip（先检查Token状态） - 若开发者需要接入后台消息 → 路由到 hmos-push-kit-background（先检查Token状态） - 若开发者请求模糊（未明确场景）→ 必须先询问具体场景，再路由到对应子Skill ⚠️ 重要：主Skill不生成任何场景化消息的具体代码！当开发者请求模糊时，必须先询问具体场景，再路由到对应子Skill生成完整代码。 此技能能够为开发者生成可直接编译通过的ArkTS代码，没有语法错误。 |
| [`/hmos-push-kit-background`](./skills/harmonyos/development/application-services/push-kit/hmos-push-kit/hmos-push-kit-background/SKILL.md) | 推送后台消息助手。当开发者需要实现后台消息接收、数据静默更新、或消息缓存功能时触发。 ============================================================ 触发条件（只有满足以下意图时才触发）： ============================================================ ✅ 正确触发场景： - "帮接入后台消息" - "实现数据静默更新" - "添加推送后台消息功能" - "推送后台消息" - "消息缓存到数据库" - "进程不在前台接收消息" - "需要接入后台消息功能" ❌ 不触发场景： - 询问/概念："后台消息是什么" - 否定意图："不需要后台消息" - 仅输入关键词："后台"、"消息" - 测试/调试："后台消息测试" - 带引号输入："后台消息" - 配置咨询："后台消息怎么配置" ⚠️ 重要提醒： - 只要需要接入后台消息功能，**必须加载本 skill** - 本 skill 提供完整的后台消息接入指导，包括消息接收、数据处理、缓存策略等 - 后台消息接入涉及数据静默更新、缓存策略等完整流程，不能凭其他 skill 的通用说明（如"同一 ability 接收多种消息类型"）自行编写 此 Skill 专注于帮助开发者实现推送后台消息的接收和配置。 前置检查： - 在继续之前，会自动检查开发者是否已接入Push Token - 如果未接入Token，会引导开发者先使用 hmos-push-kit-token Skill |
| [`/hmos-push-kit-notification`](./skills/harmonyos/development/application-services/push-kit/hmos-push-kit/hmos-push-kit-notification/SKILL.md) | 发送通知消息助手。当开发者需要实现推送通知功能、发送消息提醒、配置通知样式或点击动作时触发。 ============================================================ 触发条件（只有满足以下意图时才触发）： ============================================================ ✅ 正确触发场景： - "帮我在项目中接入推送通知" - "实现推送消息功能" - "添加推送消息功能" - "接入通知消息" - "发送通知消息" - "配置推送前台接收" ❌ 不触发场景： - 询问/概念："通知消息是什么"、"推送有啥优点" - 否定意图："不需要通知消息" - 仅输入关键词："通知"、"推送消息" - 测试/调试："测试推送通知" - 问题排查："推送失败"、"通知异常" - 带引号输入："推送通知" - 配置咨询："通知怎么配置" 此 Skill 专注于帮助开发者实现通知消息的发送和配置。 前置检查： - 在继续之前，会自动检查开发者是否已接入Push Token - 如果未接入Token，会引导开发者先使用 hmos-push-kit-token Skill |
| [`/hmos-push-kit-token`](./skills/harmonyos/development/application-services/push-kit/hmos-push-kit/hmos-push-kit-token/SKILL.md) | Push Token 获取助手。可作为单独接入能力使用。当开发者需要集成华为推送服务、首次获取 Push Token、或 Token 获取失败时触发。 ============================================================ 触发条件（只有满足以下意图时才触发）： ============================================================ ✅ 正确触发场景： - "帮我接入push token" - "获取push token" - "首次集成推送功能" - "getToken调用失败" - "token获取报错1000900010" - 需要在项目中添加getToken代码 ❌ 不触发场景： - 询问/概念："token是什么"、"为什么需要token" - 对比问题："华为push和苹果push区别" - 仅输入关键词："token"、"push" - 否定意图："不想接入token" - 带引号输入："push token" - 配置咨询："token怎么配置" 此 Skill 专注于帮助开发者正确实现 Push Token 的获取。 重要说明： - 此 Skill 可作为单独接入能力使用 - hmos-push-kit-notification 和 hmos-push-kit-voip 在接入前会先检查 Token 状态 - 如果未接入 Token，会引导开发者先使用此 Skill |
| [`/hmos-push-kit-voip`](./skills/harmonyos/development/application-services/push-kit/hmos-push-kit/hmos-push-kit-voip/SKILL.md) | 推送应用内通话消息助手（VOIP）。当开发者需要实现语音/视频来电通知、voip功能、或呼叫接听界面时触发。 ============================================================ 触发条件（只有满足以下意图时才触发）： ============================================================ ✅ 正确触发场景： - "帮接入voip消息" - "实现语音来电通知" - "添加推送应用内通话消息功能" - "接入视频通话功能" - "应用内通话消息" - "voip呼叫接听界面" - "需要接入voip功能" ❌ 不触发场景： - 询问/概念："voip是什么"、"语音通话怎么实现" - 否定意图："不需要voip" - 仅输入关键词："voip"、"通话" - 测试/调试："voip测试" - 带引号输入："voip"、"语音通话" - 配置咨询："voip怎么配置" ⚠️ 重要提醒： - 只要需要接入 voip 功能，**必须加载本 skill** - 本 skill 提供完整的 voip 接入指导，包括 VoipCallService、CalleePage、CallComponent 等组件的创建 - voip 接入涉及来电处理、呼叫界面、状态上报等完整流程，不能凭其他 skill 的通用说明（如"同一 ability 接收多种消息类型"）自行编写 此 Skill 专注于帮助开发者实现应用内通话消息的推送功能。 |
| [`/hmos-one-sdk-skill`](./skills/harmonyos/development/hmos-one-sdk-skill/SKILL.md) | ⚠️ MUST LOAD before writing first .ets file that imports from @kit.*. This skill provides verified API signatures, import paths, error codes, permission requirements, and example code for 25 Kits (AccountKit, MediaKit, NetworkKit, ScanKit, LocationKit, PushKit etc.). Even if you have partial API info from other sources, this skill covers complete error codes and permission requirements they lack. Load when — (1) writing ANY @kit.* import; (2) calling Kit APIs like vibrator, Bluetooth, location, scan, account, push, network, health, wear, map, IAP, accessibility, i18n, form, widget, card, cross-device collaboration; (3) @kit.* compile errors (wrong namespace, missing exported member, type mismatch) — load BEFORE attempting fixes; |
| [`/hmos-scan-kit-customscan`](./skills/harmonyos/development/media/scan-kit/hmos-scan-kit-customscan/SKILL.md) | 帮助开发者快速接入华为 Scan Kit 自定义界面扫码能力，仅在需要支持完全自定义相机预览流 UI 界面、闪光灯控制、变焦、对焦等功能的场景使用 |
| [`/hmos-scan-kit-defaultscan`](./skills/harmonyos/development/media/scan-kit/hmos-scan-kit-defaultscan/SKILL.md) | 帮助开发者快速接入华为 Scan Kit 默认界面扫码能力，在不需要完全自定义相机界面、闪光灯控制、变焦、对焦等高级功能时优先使用 |

### test — 测试（2）

| skill | 中文介绍 |
|-------|---------|
| [`/hmos-instrument-test`](./skills/harmonyos/test/hmos-instrument-test/SKILL.md) | 在 HarmonyOS 应用/服务开发中执行模块的 Instrument Test（包括 ArkTS/JS 和 C++ 测试），支持运行、覆盖率统计、ASan 检测等模式，并可指定测试范围（模块、测试套件、单个用例）。 |
| [`/hmos-local-test`](./skills/harmonyos/test/hmos-local-test/SKILL.md) | 在 HarmonyOS 应用/服务开发中执行模块的 Local Test（ArkTS/JS 单元测试），支持运行、覆盖率统计等模式，并可指定测试范围（模块、测试套件、单个用例）。 |

### launch-and-distribute — 发布与分发（1）

| skill | 中文介绍 |
|-------|---------|
| [`/app-metadata-audit-skill`](./skills/harmonyos/launch-and-distribute/app-metadata-audit-skill/SKILL.md) | 开发者在app开发提交agc前，可利用该skill规范对应用市场的元数据（名称、描述、关键词、隐私链接等）进行自动化合规性审查。支持华为应用市场审核规范，防止因低级错误导致被拒。 |

### tools — DevEco 工具（8）

| skill | 中文介绍 |
|-------|---------|
| [`/deveco-autobugfix`](./skills/harmonyos/tools/deveco-studio/deveco-autobugfix/SKILL.md) | 自动执行鸿蒙应用 Bug 全流程修复，涵盖问题复现、根因分析、最小化代码修复、构建编译与运行验证。 依赖 deveco-mcp 提供 verify_ui/build_project/start_app 等能力。 使用场景：用户要求自动修复鸿蒙项目 Bug，或输入触发词：自动修复、auto fix、auto-fix、自动bug修复、autofix。 提供熔断保护、3 次构建重试上限、修复经验沉淀机制。 |
| [`/deveco-native-flow`](./skills/harmonyos/tools/deveco-studio/deveco-native-flow/SKILL.md) | 三端一致开发流水线（HarmonyOS/Android/iOS）：analyse → plan → coding → build → verify。 自包含：内嵌 HarmonyOS ArkTS 知识路由，无需外部 skill 依赖。 支持正向开发和翻译开发两种模式。 执行流程： 1. 自动检测项目类型和平台 2. 执行 analyse 阶段生成跨端技术方案（读取 references/native-analyse/SKILL.md） 3. 逐端执行 plan 阶段生成实施计划（读取 references/native-plan/SKILL.md） 4. 逐端执行 coding 阶段完成编码（读取 references/native-coding/SKILL.md） 5. 构建验证 + UI 验证 Triggers: 三端开发, native pipeline, deveco pipeline, cross-platform, 跨端开发, 技术方案, 实施计划, 编码实施 |
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

## 三、Android Skills（22 个，description 已中文化）

### android（22）

| skill | 中文介绍 |
|-------|---------|
| [`/agp-9-upgrade`](./skills/android/build-system/agp/agp-9-upgrade/SKILL.md) | 升级或迁移 Android 项目以使用 Android Gradle Plugin (AGP) 版本 9。不要用此 skill 迁移 Kotlin Multiplatform (KMP) 项目。 |
| [`/camerax`](./skills/android/camera/camerax/SKILL.md) | 提供使用 CameraX 进行 Android 相机开发的技术指导。当实现相机功能、处理异步录制生命周期、使用 CameraX 进行底层硬件互操作，或集成 ML Kit 或 Media3 特效时使用。 |
| [`/appfunctions`](./skills/android/device-ai/appfunctions/SKILL.md) | 分析 Android 应用，识别可用于 AppFunctions 的关键用户工作流（如创建笔记、播放媒体，或发送由自动化或 AI agent 触发的消息、语音命令、系统快捷方式，而无需打开应用 UI）。生成 Kotlin 代码将这些工作流暴露给 Android 系统，使 agent 能在设备端发现并执行它们。同时优化 KDoc 文档，确保 AI agent 正确理解并使用所提供的功能。 |
| [`/android-cli`](./skills/android/devtools/android-cli/SKILL.md) | 提供安装和使用 `android` CLI 的说明。`android` 命令行工具是 Android 开发的关键工具，帮助你创建新 Android 项目、在设备上运行 Android 应用、管理和交互 Android 虚拟设备（含截图和 UI 检查）、管理 Android SDK 组件、查询官方 Android 文档，以及发现和安装官方 Android skills。 |
| [`/verified-email`](./skills/android/identity/verified-email/SKILL.md) | 提供基于 Android Credential Manager API 实现已验证邮箱获取的完整工作流。使用此 skill 向 Android 应用集成安全、免 OTP 的邮箱验证流程。该 skill 利用来自 Google 等可信提供商的加密验证凭证，解决注册流程摩擦过大的问题。 |
| [`/adaptive`](./skills/android/jetpack-compose/adaptive/SKILL.md) | 提供让应用 UI 适配不同 Android 设备（手机、平板、折叠屏、笔记本、桌面、TV、Auto 和 XR）的说明。涵盖使用 Compose MediaQuery API 处理不同窗口尺寸、指针设备（如鼠标）和文本输入设备（如键盘）；使用 Navigation3 Scenes 实现多窗格布局；使用 Compose Grid 和 FlexBox API 实现随目标尺寸变化的自适应 UI 组件（如按钮）和自适应布局（含导航区——nav rails 和 nav bars）。 |
| [`/migrate-xml-views-to-jetpack-compose`](./skills/android/jetpack-compose/migration/migrate-xml-views-to-jetpack-compose/SKILL.md) | 提供将 Android XML View 迁移到 Jetpack Compose 的结构化工作流。该 skill 详述从规划和依赖设置，到主题和布局迁移、验证及 XML 清理的分步流程。当需要在 Android 项目中把 XML View 迁移到 Jetpack Compose 时使用。它解决将旧版 XML View 的 UI 转换为现代声明式 Compose 组件、同时保持互操作性的问题。 |
| [`/styles`](./skills/android/jetpack-compose/theming/styles/SKILL.md) | 使用此 skill 将 Jetpack Compose Styles API 集成到 Android 项目。引导你升级依赖、设置组件主题、让自定义组件可样式化，以及将现有布局属性迁移到统一样式。迁移自定义设计系统组件、用 Style 属性替换硬编码参数、使用 Modifier.styleable 处理交互状态。 |
| [`/media3-cast-integration`](./skills/android/media/media3-cast-integration/SKILL.md) | 使用 Jetpack Media3 在 Android 应用中实现 Google Cast 支持。涵盖添加构建依赖、更新清单、配置 OptionsProvider，以及在 Compose 和基于 View 的 UI 中使用 CastPlayer 或 RemoteCastPlayer 管理播放。适用于添加 Cast 功能，或从旧版 Cast SDK 迁移到 Media3 Cast。 |
| [`/navigation-3`](./skills/android/navigation/navigation-3/SKILL.md) | 学习如何安装并迁移到 Jetpack Navigation 3，以及如何实现 deep links、多个 backstack、scenes（对话框、底部表、list-detail、two-pane、supporting pane）、条件导航（如已登录导航 vs 匿名导航）、从流程返回结果、与 Hilt/ViewModel/Kotlin/View 互操作集成等功能和模式。 |
| [`/r8-analyzer`](./skills/android/performance/r8-analyzer/SKILL.md) | 分析 Android 构建文件和 R8 keep 规则，识别冗余、过宽的包级规则，以及吞没了库消费者 keep 规则的规则。当开发者想优化应用体积、移除冗余或过宽的 keep 规则，或排查 Proguard 配置时使用。 |
| [`/engage-sdk-integration`](./skills/android/play/engage-sdk-integration/SKILL.md) | 帮助开发者集成、调试和解决 Play Engage SDK 实现问题。当添加 Engage SDK 支持、生成发布代码、将数据类映射到实体，或修复 SDK 相关错误时使用。 |
| [`/play-billing-library-version-upgrade`](./skills/android/play/play-billing-library-version-upgrade/SKILL.md) | 当从任意旧版 Google Play Billing Library (PBL) 升级或迁移 Android 项目到最新稳定版 PBL 时使用此 skill。 |
| [`/play-policy-insights`](./skills/android/play/play-policy-insights/SKILL.md) | 用于核查 Android 应用是否符合 Google Play 政策域的自动化审计器。它交叉比对静态代码分析与 Play 商店声明，生成确定性的合规报告，识别权限与 API 卫生、用户账号与身份、数据安全与隐私领域中未声明的数据收集、架构风险和缺失披露。 |
| [`/perfetto-sql`](./skills/android/profilers/perfetto-sql/SKILL.md) | 将自然语言数据意图翻译成语法正确的 Perfetto SQL 查询，并在本地 trace 文件上执行。使用此 skill 通过 trace_processor 从 Android Perfetto trace 中提取 slice、thread 或内存数据。 |
| [`/perfetto-trace-analysis`](./skills/android/profilers/perfetto-trace-analysis/SKILL.md) | 分析 Perfetto trace 以找出 Android 应用中延迟、内存或卡顿问题的根因。当用户提供 Perfetto trace 文件并要求分析其内容的任何问题、进行中的排查或开放式请求时使用。 |
| [`/android-intent-security`](./skills/android/security/android-intent-security/SKILL.md) | Android Intent 安全最佳实践。当审计 AndroidManifest.xml 中的组件配置（activity、service、receiver），或审计处理传入 Intent（getIntent、getParcelableExtra）的源代码以防止 Intent 重定向和未授权访问时使用。 |
| [`/edge-to-edge`](./skills/android/system/edge-to-edge/SKILL.md) | 使用此 skill 迁移 Jetpack Compose 应用以添加自适应 edge-to-edge 支持，并排查常见问题。用于修复被导航栏或状态栏遮挡/重叠的 UI 组件（如按钮或列表）、修复 IME insets、以及修复系统栏可读性。 |
| [`/testing-setup`](./skills/android/testing/testing-setup/SKILL.md) | 为原生 Android 应用分析并制定测试策略——安装测试库、搭建测试基础设施、为单元测试、UI 测试、截图测试和端到端测试创建测试桩。 |
| [`/leanback-to-compose-tv-migration`](./skills/android/tv/leanback-to-compose-tv-migration/SKILL.md) | 提供将 Android TV 应用从旧版 Leanback UI Toolkit、Android View 或 Support Fragment 迁移到 Jetpack Compose for TV（androidx.tv）的说明和架构模式。适用于 Leanback 到 Compose 的迁移，包括浏览、设置、认证、登录或视频播放界面；也适用于替换 BrowseSupportFragment、LeanbackSettingsFragment、PreferenceFragment、BaseLeanbackPreferenceFragmentCompat、VideoSupportFragment、GuidedStepSupportFragment、SearchSupportFragment、VerticalGridSupportFragment、Presenter、ArrayObjectAdapter、CursorMapper，使用 PlayerSurface 实现 Media3 视频播放、带焦点记忆的沉浸式轮播或自定义十英尺大屏布局。 |
| [`/wear-compose-m3`](./skills/android/wear/wear-compose-m3/SKILL.md) | 使用 Wear OS Compose Material3 的专家指导。当创建、更新或迁移 Wear OS 项目时使用。涵盖 androidx.wear.compose.material3、androidx.wear.compose.foundation、androidx.wear.compose.navigation3，以及 AppScaffold、ScreenScaffold、TransformingLazyColumn 和 ambient mode 等核心组件与概念，也包括从 Material 2.5 和 Horologist 等早期版本迁移。 |
| [`/display-glasses-with-jetpack-compose-glimmer`](./skills/android/xr/display-glasses-with-jetpack-compose-glimmer/SKILL.md) | 提供使用 Jetpack Compose Glimmer UI 工具包为显示眼镜开发投影式 Android XR 应用的指南。涵盖 Glimmer 基础设计原则、实现 Jetpack Compose Glimmer 的工作流，以及眼镜形态的交互模型。使用此 skill 构建遵循 Glimmer 设计系统、针对眼镜样式优化的 Android XR Augmented Experience 应用。 |

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
