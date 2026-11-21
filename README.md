# KenKenSkills

> 收集好用的 agent skills，把介绍（description）本地化为简体中文，统一管理、方便更新。

本仓库整合多个上游的优秀 agent skills：
- [mattpocock/skills](https://github.com/mattpocock/skills)（MIT）— 通用编码/生产力 skill，description 已译为中文
- [HarmonyOS_Skills/harmonyos-agent-skills](https://gitcode.com/HarmonyOS_Skills/harmonyos-agent-skills.git) — 鸿蒙开发 skill，上游原生中文，原样保留
- [android/skills](https://github.com/android/skills)（Apache 2.0）— Android 官方开发 skill，description 已译为中文
- [openai/plugins](https://github.com/openai/plugins) — build-ios-apps / build-macos-apps（Apple 平台，description 已译为中文）
- [twostraws/SwiftUI-Agent-Skill](https://github.com/twostraws/SwiftUI-Agent-Skill)、[AvdLee/Swift-Concurrency-Agent-Skill](https://github.com/AvdLee/Swift-Concurrency-Agent-Skill) — Apple 生态社区精品，description 已译为中文
- **Apple 官方 11 个**（Xcode 27.2 `xcrun agent skills export` 导出，来源 WWDC26 session 269）— description 已译为中文

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

## Skill 清单（共 203 个）

## 一、mattpocock 通用 Skills（39 个，description 已中文化）

### Engineering — 工程类（20）

*日常编码工作*


| skill | 调用方式 | 中文介绍 |
|-------|---------|---------|
| [`/ask-matt`](./skills/engineering/ask-matt/SKILL.md) | 用户调用 | 询问哪种 skill 或流程适合你的场景。是本仓库中全部 skill 的路由器。 |
| [`/code-review`](./skills/engineering/code-review/SKILL.md) | 模型/用户调用 | 沿两条轴线审查自某个固定点（提交、分支、标签或 merge-base）以来的变更——标准（代码是否遵循本仓库文档化的编码规范？）与规格（代码是否符合原始 issue/spec 的要求？）。两个审查由并行子代理执行并并排汇报。当用户想审查一个分支、PR、进行中的改动，或要求“自 X 起审查”（review since X）时使用。 |
| [`/codebase-design`](./skills/engineering/codebase-design/SKILL.md) | 模型/用户调用 | 设计深层模块（deep module）的共享词汇。当用户想设计或改进模块接口、寻找深化机会、决定接缝（seam）位置、让代码更易测试或更易被 AI 导航，或当其他 skill 需要深层模块词汇时使用。 |
| [`/diagnosing-bugs`](./skills/engineering/diagnosing-bugs/SKILL.md) | 模型/用户调用 | 针对疑难 bug 和性能回归的诊断循环。当用户说"诊断"/"调试这个"，或报告某东西坏了/抛异常/失败/变慢时使用。 |
| [`/domain-modeling`](./skills/engineering/domain-modeling/SKILL.md) | 模型/用户调用 | 构建并打磨项目的领域模型。当讨论代码库术语、撰写或编辑 GLOSSARY.md 术语表、记录或编辑 ADR 时使用。 |
| [`/grill-with-docs`](./skills/engineering/grill-with-docs/SKILL.md) | 用户调用 | 一场无情的访谈，用来打磨计划或设计，同时会顺势产出文档（ADR 和术语表）。 |
| [`/implement`](./skills/engineering/implement/SKILL.md) | 用户调用 | 基于规格（spec）或一组 ticket 实现一项工作。 |
| [`/implement-spec`](./skills/engineering/implement-spec/SKILL.md) | 用户调用 | 把 /to-spec 和 /to-tickets 的产出实现为代码。 |
| [`/improve-codebase-architecture`](./skills/engineering/improve-codebase-architecture/SKILL.md) | 用户调用 | 扫描代码库寻找深化机会，以可视化 HTML 报告呈现，然后针对你选中的那一个进行 grill 访谈。 |
| [`/pr`](./skills/engineering/pr/SKILL.md) | 模型/用户调用 | 撰写 PR 描述（PR body）时使用。 |
| [`/prototype`](./skills/engineering/prototype/SKILL.md) | 模型/用户调用 | 构建一次性原型来回答设计问题。当用户想验证状态模型或逻辑是否合理，或探索 UI 应该长什么样时使用。 |
| [`/research`](./skills/engineering/research/SKILL.md) | 模型/用户调用 | 针对一个问题调研高可信度的一手资料，并把发现整理为仓库中的 Markdown 文件。当用户想调研某个主题、收集文档或 API 事实，或把阅读跑腿工作交给后台代理时使用。 |
| [`/retro`](./skills/engineering/retro/SKILL.md) | 用户调用 | 对一次编码会话进行复盘（retrospective）。 |
| [`/setup-matt-pocock-skills`](./skills/engineering/setup-matt-pocock-skills/SKILL.md) | 用户调用 | 为工程类 skill 配置本仓库：设置 issue 追踪器、triage 标签词汇和领域文档布局。在其他工程类 skill 首次使用前运行一次。 |
| [`/tdd`](./skills/engineering/tdd/SKILL.md) | 模型/用户调用 | 测试驱动开发（TDD）。当用户想以测试优先的方式构建功能或修 bug、提到"red-green-refactor"，或想要集成测试时使用。 |
| [`/to-spec`](./skills/engineering/to-spec/SKILL.md) | 用户调用 | 把当前对话转化为规格（spec）并发布到项目 issue 追踪器：无需访谈，只是对已讨论内容的综合提炼。 |
| [`/to-tickets`](./skills/engineering/to-tickets/SKILL.md) | 用户调用 | 把计划、规格或当前对话拆解为一组示踪子弹（tracer-bullet）ticket，每个 ticket 声明自己的阻塞关系，发布到配置好的追踪器（本地模式下阻塞关系以文本写在每个 ticket 文件里，真实追踪器上则用原生的阻塞链接）。 |
| [`/triage`](./skills/engineering/triage/SKILL.md) | 用户调用 | 让 issue 和外部 PR 经过一组 triage 角色的状态机——分类、验证、必要时 grill 访谈，并撰写代理可直接执行的简报（brief）。 |
| [`/wayfinder`](./skills/engineering/wayfinder/SKILL.md) | 用户调用 | 把一大块工作（单次 agent 会话装不下的规模）规划为 issue 追踪器上的决策 ticket 共享地图，然后逐个解决，直到通往终点的路径清晰。 |
| [`/wizard`](./skills/engineering/wizard/SKILL.md) | 模型/用户调用 | 生成一个交互式 bash 向导，引导人类逐步完成只有他们才能执行的操作。当需要开通基础设施、设置凭证或 CI secrets、走查陌生的第三方控制台，或执行一次性迁移/切换时使用。代理自己能完成的步骤不要调用此 skill。 |

### Productivity — 生产力类（7）

*日常非编码工作流工具*


| skill | 调用方式 | 中文介绍 |
|-------|---------|---------|
| [`/grill-me`](./skills/productivity/grill-me/SKILL.md) | 用户调用 | 一场无情的访谈，用来打磨计划或设计。 |
| [`/grilling`](./skills/productivity/grilling/SKILL.md) | 模型/用户调用 | 就一个计划、决策或想法对用户进行无情的访谈。当用户想压力测试自己的思路，或使用任何 'grill' 触发短语时使用。 |
| [`/handoff`](./skills/productivity/handoff/SKILL.md) | 用户调用 | 把当前对话压缩成一份交接（handoff）文档，供另一个代理接手。 |
| [`/teach`](./skills/productivity/teach/SKILL.md) | 用户调用 | 在当前工作区内，教会用户一项新 skill 或概念。 |
| [`/to-questionnaire`](./skills/productivity/to-questionnaire/SKILL.md) | 用户调用 | 把你无法独自回答的决策转化成一份问卷，交给别人填写。 |
| [`/wait-what`](./skills/productivity/wait-what/SKILL.md) | 用户调用 | 停。上一条消息没讲明白：换个说法再讲一遍。 |
| [`/writing-for-agents`](./skills/productivity/writing-for-agents/SKILL.md) | 模型/用户调用 | 为 agent 撰写文档。当创建或编辑 skill、修改 AGENTS.md 或 CLAUDE.md 时使用。 |

### Misc — 杂项（4）

*保留但较少使用*


| skill | 调用方式 | 中文介绍 |
|-------|---------|---------|
| [`/git-guardrails-claude-code`](./skills/misc/git-guardrails-claude-code/SKILL.md) | 模型/用户调用 | 设置 Claude Code 钩子，在危险的 git 命令（push、reset --hard、clean、branch -D 等）执行前拦截。当用户想防止破坏性 git 操作、添加 git 安全钩子，或在 Claude Code 中阻止 git push/reset 时使用。 |
| [`/migrate-to-shoehorn`](./skills/misc/migrate-to-shoehorn/SKILL.md) | 模型/用户调用 | 把测试文件从 `as` 类型断言迁移到 @total-typescript/shoehorn。当用户提到 shoehorn、想替换测试里的 `as`，或需要部分测试数据时使用。 |
| [`/scaffold-exercises`](./skills/misc/scaffold-exercises/SKILL.md) | 模型/用户调用 | 创建带章节、题目、解答和讲解的练习目录结构，且能通过 lint。当用户想脚手架化练习、创建练习桩，或搭建新课程章节时使用。 |
| [`/setup-pre-commit`](./skills/misc/setup-pre-commit/SKILL.md) | 模型/用户调用 | 在当前仓库设置带 lint-staged（Prettier）、类型检查和测试的 Husky pre-commit 钩子。当用户想添加 pre-commit 钩子、设置 Husky、配置 lint-staged，或在提交时加入格式化/类型检查/测试时使用。 |

### In-progress — 进行中（8）

*尚未定稿的草稿*


| skill | 调用方式 | 中文介绍 |
|-------|---------|---------|
| [`/chief-of-staff`](./skills/in-progress/chief-of-staff/SKILL.md) | 用户调用 | 在单次会话中通过协调多个子代理（subagent），持续推进一个长期目标。 |
| [`/claude-handoff`](./skills/in-progress/claude-handoff/SKILL.md) | 用户调用 | 把当前对话移交给一个全新的后台代理，让它立即接手工作。 |
| [`/loop-me`](./skills/in-progress/loop-me/SKILL.md) | 用户调用 | 在本工作区内，就我想构建的工作流的规格（spec）对我进行 grill 访谈。 |
| [`/setup-ts-deep-modules`](./skills/in-progress/setup-ts-deep-modules/SKILL.md) | 用户调用 | 把 dependency-cruiser 接入 TypeScript 仓库，让每个包都成为深层模块（deep module）——实现隐藏在子文件夹中，只能通过入口文件访问。用户调用。 |
| [`/software-factory`](./skills/in-progress/software-factory/SKILL.md) | 用户调用 | 设计「软件工厂」（software factory）的共享语言：它运行的任务与接入的服务。 |
| [`/writing-beats`](./skills/in-progress/writing-beats/SKILL.md) | 用户调用 | 写作·利用（exploit）：把原始素材组装成一段节拍（beat）之旅，在每个节拍依赖某个术语之前先把它讲透。 |
| [`/writing-fragments`](./skills/in-progress/writing-fragments/SKILL.md) | 用户调用 | 写作·探索（explore）：挖掘原始片段，暂不构建结构。 |
| [`/writing-shape`](./skills/in-progress/writing-shape/SKILL.md) | 用户调用 | 写作·利用（exploit）：把原始素材逐段塑造成文章。 |

## 二、HarmonyOS（鸿蒙）Skills（91 个，上游原生中文原样保留）

### design — 设计（1）


| skill | 中文介绍 |
|-------|---------|
| [`/hmos-design-visual-mobile`](./skills/harmonyos/design/mobile/hmos-design-visual-mobile/SKILL.md) | HarmonyOS 移动端页面视觉还原技能。基于仓库内设计规范文档与组件模板，生成符合 HarmonyOS Design Token 标准的高保真移动端 HTML 页面。触发场景：(1) 用户要求生成/还原 HarmonyOS 移动端页面 (2) 用户提供设计稿/截图/参考图，要求还原为 HarmonyOS 风格 HTML 页面 (3) 用户提到"视觉还原"/"高保真页面"/"移动端页面"并涉及 HarmonyOS，用于需要生成符合鸿蒙规范的移动端设计稿的场景 |

### solutions — 解决方案（22）


| skill | 中文介绍 |
|-------|---------|
| [`/hmos-app-continuity-skill`](./skills/harmonyos/solutions/feature-integration/hmos-app-continuity-skill/SKILL.md) | This guide directs the incremental integration of HarmonyOS (鸿蒙 / ArkTS) app continuation (应用接续 / App Continuity), enabling users to resume the same task on a different device. It is applicable when planning, adding, extending, or fixing cross-device state migration for pages, navigation stacks, forms, editors, or large data, as well as when assessing the completeness of an existing implementation or identifying where it fails. |
| [`/hmos-share-kit-gestures-share`](./skills/harmonyos/solutions/feature-integration/hmos-share-kit-gestures-share/SKILL.md) | 为 HarmonyOS 工程接入 Share Kit 隔空传送文件 / App Linking 链接，支持首次接入与增量升级。用户提到隔空传送、gesturesShare、一抓一放或要求接入时使用。 |
| [`/hmos-share-kit-knock-share`](./skills/harmonyos/solutions/feature-integration/hmos-share-kit-knock-share/SKILL.md) | Entry skill for HarmonyOS Share Kit knock share. Use when requests involve knock share, touch-to-share file or link transfer. This skill helps project quickly integrate knockShare, inject manager file, register lifecycle listener, build SharedData for files or App Linking, and judge compatible API versions. |
| [`/hmos-multidevice-avoid-areas`](./skills/harmonyos/solutions/multi-device/hmos-multidevice-avoid-areas/SKILL.md) | Handle HarmonyOS avoid-area adaptation through a declarative scene and resource index. Use when the task involves safe area expansion, status bar or navigation bar avoidance, notch or cutout handling, immersive full-screen layouts, or soft keyboard overlap handling. |
| [`/hmos-multidevice-fold-state`](./skills/harmonyos/solutions/multi-device/hmos-multidevice-fold-state/SKILL.md) | HarmonyOS foldable-device adaptation skill for requirements, development, bug-fix, and verification phases. Activate when the task involves fold status detection, hover-mode split-screen layouts, crease avoidance, fold continuity, multi-fold form-factor mapping (e.g. F/M/G), inner/outer screen ratio differences, or fold-related issue remediation. |
| [`/hmos-multidevice-hardware-access`](./skills/harmonyos/solutions/multi-device/hmos-multidevice-hardware-access/SKILL.md) | Handle HarmonyOS hardware-capability adaptation through a declarative scene and resource index. Use when the task involves camera selection, camera rotation/stride/foldable adaptation, canIUse or SysCap checks, hardware fallback strategy, or multi-device hardware behavior differences. |
| [`/hmos-multidevice-interaction-methods`](./skills/harmonyos/solutions/multi-device/hmos-multidevice-interaction-methods/SKILL.md) | HarmonyOS应用多设备交互适配开发方案skill，提供触摸、鼠标、键盘、手写笔等多输入方式的交互方案和事件归一策略。当涉及触摸、鼠标、键盘、手写笔等设备的交互以及实现交互归一化、悬停效果、右键菜单、焦点导航、键盘快捷键、手写板输入和压感等功能时调用。 |
| [`/hmos-multidevice-natural-orientation`](./skills/harmonyos/solutions/multi-device/hmos-multidevice-natural-orientation/SKILL.md) | 鸿蒙 HarmonyOS 屏幕方向与旋转相关的需求分析、开发实现、问题修复和功能验证。当任务涉及以下场景时使用：setPreferredOrientation、屏幕旋转(rotation)、屏幕方向(orientation)、自然方向、折叠屏方向、三折叠G态、follow_desktop、视频横竖屏切换、短视频自适应旋转、多设备方向策略、module.json5方向配置、方向监听、旋转检测、分屏旋转、折叠屏展开态方向、窗口方向设置、方向Bug修复。 |
| [`/hmos-multidevice-scenario-entry`](./skills/harmonyos/solutions/multi-device/hmos-multidevice-scenario-entry/SKILL.md) | Entry skill for HarmonyOS multi-device adaptation. Use when the task broadly concerns HarmonyOS multi-device adaptation, the task involves foldable device verification or when the correct scenario is still unclear. This skill classifies the request by phase and scenario type, then routes to one or more scenario files for screen and window size, fold state, avoid areas, interaction methods, natural orientation, or hardware access. |
| [`/hmos-multidevice-screen-window-size`](./skills/harmonyos/solutions/multi-device/hmos-multidevice-screen-window-size/SKILL.md) | HarmonyOS 多设备屏幕窗口尺寸适配。当任务涉及以下任一场景时必须调用：（1）比价与分屏：比价/比价场景/比价窗口/价格对比/创建新窗口/多窗口并行/双窗口；（2）平行视界与分栏：平行视界/EasyGo/easy_go.json/分栏效果/分栏布局/列表详情分栏/navigationSplit/routerSplit/Navigation分栏；（3）响应式与自适应布局：响应式布局/自适应布局/断点/GridRow/GridCol/WidthBreakpoint/HeightBreakpoint/重复布局/分栏布局/挪移布局/缩进布局；（4）窗口监听：windowSizeChange/窗口尺寸变化/布局未同步更新；（5）组件自适应：layoutWeight/Blank/aspectRatio/displayPriority/FlexWrap/拉伸/均分/隐藏/折行/缩放/占比/百分比宽度；（6）多设备适配：手机/平板/2in1/穿戴/折叠屏/双折/三折/大屏/横竖屏/密度/字体缩放/滚动延伸；（7）布局异常：截断/留白/溢出/遮挡/错位/对齐异常/GridRow不降列/断点不切换/图片变形/压缩。不适用于：FoldStatus、hover、折痕、安全区、与尺寸无关的调整。 |
| [`/harmonyos-memory-optimization-solution`](./skills/harmonyos/solutions/performance/harmonyos-memory-optimization-solution/SKILL.md) | 优化 HarmonyOS 应用内存以降低内存峰值与冗余占用，覆盖四大类场景：① 离线 Web 组件（预渲染停止、离开页面复用、退后台释放、低端机预创建控制）；② ArkUI 组件（Image 降采样、长列表懒加载、LazyForEach/Repeat/@Reusable 内存优化策略、Navigation 路由栈、Tabs 预加载、cachedCount、容器嵌套、XComponent Surface 释放）；③ SO/HAP 包体积（编译选项裁剪、abc 字节码去冗余）；④ 并发（Worker 收敛复用、taskpool 共享传输）。当涉及 Web 组件预渲染或内存释放、图片/长列表内存峰值高、缓存池或复用池内存过高、so Pss 增长、hap/abc 体积增长、worker 实例过多、taskpool 大数据拷贝翻倍等场景时调用。 |
| [`/hmos-memory-anti-regression`](./skills/harmonyos/solutions/performance/hmos-memory-anti-regression/SKILL.md) | HarmonyOS 应用内存防劣化分析。对同一应用的两个版本分别执行数据采集和归因分析，通过 topdown 对比识别劣化源，对 Top10 劣化 SO 按 type_name 分发 ArkTS Heap / Native Heap / SO_SIZE 三类深度分析，综合输出防劣化报告并匹配案例库。当用户提到 htrace 采集、内存对比、防劣化、topdown、smaps、hidumper、hiprofiler、heapsnapshot、native heap、arkts heap、版本对比等场景时使用此技能。 |
| [`/hmos-memory-tier-optimizer`](./skills/harmonyos/solutions/performance/hmos-memory-tier-optimizer/SKILL.md) | HarmonyOS 应用低端机内存分档优化 Skill，覆盖内存采集、数据分析、分档候选方案、用户确认、代码修改与审查、构建安装、优化后复测、patch 与报告生成全闭环。当用户提供 HarmonyOS 应用内存占用过高、需要在低端机上做内存分档降级、要求优化前后内存对比、或需要执行完整内存优化闭环时，必须使用此技能。即使用户只说"帮我优化这个应用的内存"、"低端机内存超标怎么降"、"做个内存前后对比"，也应立即触发此技能。 |
| [`/hmos-apifault-analysis`](./skills/harmonyos/solutions/stability/hmos-apifault-analysis/SKILL.md) | 定位开发者问题。当遇到 API 调用失败或报错、错误码（如 5400xxx、801、9200 等）、crash/freeze 日志（hilog、HiviewDFX）、或需要根据日志与源码定位问题根因时使用——即使用户没明说要做诊断也应触发。输出结构化诊断报告（错误码映射 + 根因候选 + 代码修改建议）。 |
| [`/hmos-appfreeze-analysis`](./skills/harmonyos/solutions/stability/hmos-appfreeze-analysis/SKILL.md) | DFX Skills，自动分析 HarmonyOS / OpenHarmony Freeze（冻屏/卡死）故障日志，定位根因并输出完整证据链。 当用户提供完整的faultlog 文件和采样栈文件、询问应用无响应/卡死/ANR 问题的根因， 或上传包含 APPFREEZE / INPUT_BLOCK / LIFECYCLE_TIMEOUT / THREAD_BLOCK_6S / BUSSINESS_THREAD_BLOCK_6S / BUSINESS_THREAD_BLOCK_6S 等关键字的日志时，必须使用此技能。 即使用户只说"帮我分析这个 freeze 日志"、"应用卡死了是什么原因"，也应立即触发此技能。 技能会按优先级逐步排除整机低内存、高负载、热限频等系统级异常，再深入分析线程堆栈、 Binder 通信链路、EventHandler 队列，最终输出唯一根因模块与修复建议。  |
| [`/hmos-cppcrash-analysis`](./skills/harmonyos/solutions/stability/hmos-cppcrash-analysis/SKILL.md) | DFX Skills，分析 HarmonyOS/OpenHarmony 应用的 CppCrash（Native 层崩溃）日志， 基于信号、寄存器、Native 调用栈、符号和内存证据定位根因并给出修复建议。 当输入包含 cppcrash、NativeCrash、Reason:Signal、Fault thread info、Registers、 Memory near registers、Native .so 调用栈、SIGSEGV/SIGABRT/SIGILL/SIGBUS/SIGFPE， 或 GWP-ASan 报告时使用。若用户只说“应用崩溃/闪退”但没有 JS 或 Native 证据， 先识别日志类型；仅在确认是 Native Crash 后使用本技能。 |
| [`/hmos-dfx-analyzer`](./skills/harmonyos/solutions/stability/hmos-dfx-analyzer/SKILL.md) | DFX 故障分析主 Skill：输入归一化、确定性故障分诊、候选仲裁、专项 Analyzer 路由与报告交付。 由 dfx subagent 在隔离子会话中加载执行（显式 /analyze 命令或主 Agent 自然语言委派两个入口）， 也供第三方宿主直接加载。受理：HarmonyOS 应用故障——闪退/崩溃/白屏（含进程未退出的 非崩溃型白屏/空白页）/冻屏/卡死/无响应/ANR，CppCrash、JSCrash、AppFreeze，faultlog/崩溃日志 ——无论要求修复、分析还是仅描述症状，有日志与否。一般编译错误、常规功能开发、静态检查问题、 HiLog 流水、内存泄漏/OOM/性能问题不适用。  |
| [`/hmos-fdleak-analysis`](./skills/harmonyos/solutions/stability/hmos-fdleak-analysis/SKILL.md) | DFX Skills，分析 FD Leak、句柄泄漏和文件描述符泄漏日志，提取泄漏快照、句柄类型与目录分布、专项维测明细及 FdTrack 申请栈热点，并依据证据链定位根因。当用户提供 `[pid]_fd_leak.txt`、`RESOURCE_OVERLIMIT_[TIMESTAMP]_[PID].log`，或输入包含 `leaked fd nums`、`Leaked fd Top 10`、`LOGGER_MEMCHECK_FD_STACK_INFO`、`FdTrack Stack` 时使用。 |
| [`/hmos-jscrash-analysis`](./skills/harmonyos/solutions/stability/hmos-jscrash-analysis/SKILL.md) | DFX Skills，分析 HarmonyOS/OpenHarmony 应用的 JS Crash（ArkTS/JS 层闪退）faultlogger 日志， 按 Reason、Error name、Error message、Error code 和 Stacktrace 定位根因，支持使用 SourceMap 反解 release/混淆堆栈并给出修复建议。 当用户提供包含 JS Crash、Reason:Error/TypeError/SyntaxError/ReferenceError/RangeError/ BusinessError/OutOfMemoryError/URIError/TerminationError/AggregateError、Error message、 Stacktrace、HybridStack、faultlogger、Cannot get SourceMap info 等字段的日志， 或询问 HarmonyOS 应用启动/点击后闪退、ArkTS 崩溃、JS Crash 怎么定位、OOM 闪退原因时， 必须使用此技能。确认崩溃原因为 OOM 且用户同时提供 rawheap 或 heapsnapshot 快照时， 必须继续调用 jsleak-analysis Skill 分析快照。即使用户只说“帮分析这个 JS Crash 日志” “应用闪退了是什么原因”“ArkTS 报错导致崩溃怎么修”，也应立即触发此技能；如果日志是 cppcrash、 freeze，或者用户询问的是原生/C++ 层崩溃，且没有 JS/ArkTS 错误字段，则不该调用此技能。  |
| [`/hmos-jsleak-analysis`](./skills/harmonyos/solutions/stability/hmos-jsleak-analysis/SKILL.md) | DFX Skills，分析 HarmonyOS/ArkTS rawheap、heapsnapshot 和 Heap Cluster 报告，识别疑似 JS 内存泄漏；支持 rawheap 转换、单快照聚类、目录批处理、多快照总榜、双版本增长对比、测试版对象差值对比，以及 GlobalHandler对象关联native堆栈。当用户提供 .rawheap、.heapsnapshot、聚类报告、native hook DB，或 rawheap + htrace + js_map 三合一日志，要求运行 heap_cluster、多快照、版本对比或 GlobalHandler对象关联native堆栈，或询问哪些对象未释放、内存为何增长时使用。 |
| [`/hmos-memleak-analysis`](./skills/harmonyos/solutions/stability/hmos-memleak-analysis/SKILL.md) | Analyzes HarmonyOS source code (ArkTS, JS, C/C++) to detect memory leaks.Use when (1) Performing static code analysis to catch potential leaks before deployment, (2) Reviewing PRs involving complex UI lifecycles or NAPI implementations,(3) Developing NAPI bridges between ArkTS and C++. Maps code to official specifications and applies heuristics for NAPI reference management and lifecycle synchronization. |
| [`/hmos-native-memleak-analysis`](./skills/harmonyos/solutions/stability/hmos-native-memleak-analysis/SKILL.md) | 自动分析 HarmonyOS / OpenHarmony Native内存泄漏问题，基于 sample 采样文件、smaps 文件、profiler 火焰图等信息定位泄漏根因并输出完整证据链。 当用户提供 sample 采样文件、smaps 文件、profiler 火焰图、NMD 数据，或询问应用内存泄漏/内存增长/OOM问题的根因 即使用户只说"帮我分析这个内存泄漏"、"应用内存一直涨"、"native泄漏分析"、"PSS泄漏"、"DMA泄漏"、"GPU泄漏"，也应立即触发此技能。  |

### development — 开发（51）


| skill | 中文介绍 |
|-------|---------|
| [`/hmos-ability-insight-intent-generator`](./skills/harmonyos/development/ability/hmos-ability-insight-intent-generator/SKILL.md) | Generates OpenHarmony intent decorator code from user requirements with automatic decorator selection. Use when the user mentions "intent", "@InsightIntent", or needs to integrate app functionality with AI entry points. Provides decorator selection decision tree, parameter validation, build config checking, and compilation verification with auto-fix.  |
| [`/hmos-account-kit-login-api-client`](./skills/harmonyos/development/account-kit/hmos-account-kit-login-api-client/SKILL.md) | 基于 HarmonyOS Account Kit 提供华为自定义按钮登录客户端接入指引。提供自定义登录按钮（纯图标/纯文本/图文三种模式）、Authorization Code 获取及 Union ID 服务端请求框架。**当用户需要在现有登录页嵌入华为登录自定义按钮（非标准按钮，需自定义按钮外观）时使用。** |
| [`/hmos-account-kit-login-button-client`](./skills/harmonyos/development/account-kit/hmos-account-kit-login-button-client/SKILL.md) | 为尚未接入华为账号登录功能的原生 ArkTS HarmonyOS 应用接入华为 Account Kit"华为账号登录"/"华为按钮登录"功能，提供登录按钮入口、账号登录页面和用户协议页面，在获得授权码后请求应用服务端获取 Union ID，并支持根据 Prompt 配置服务端域名、登录按钮样式、颜色及应用图标。**当用户需要为 HarmonyOS 应用接入华为账号标准按钮登录（使用华为提供的标准登录按钮组件，而非自定义按钮）时使用；纯图标按钮不适用。** |
| [`/hmos-account-kit-quicklogin-client`](./skills/harmonyos/development/account-kit/hmos-account-kit-quicklogin-client/SKILL.md) | 基于 HarmonyOS Account Kit 提供华为账号一键登录客户端接入指引，实现获取匿名手机号接口与华为账号一键登录组件集成。支持获取匿名手机号后一键登录页面跳转、失败Toast提示等。在用户提及"接入华为账号一键登录"、"Account Kit一键登录"或要求实现华为账号一键登录功能时使用（当前仅支持原生ArkTS框架） |
| [`/hmos-ads-kit-access`](./skills/harmonyos/development/ads-kit/hmos-ads-kit-access/SKILL.md) | HarmonyOS Ads Kit 广告服务开发指南 — 涵盖6种广告形式(横幅/原生/激励/插屏/开屏/贴片)的完整接入文档、代码模板、自动化场景识别与植入决策引擎。触发关键词：广告接入, Ads Kit, 流量变现, 横幅广告, 原生广告, 激励广告, 插屏广告, 开屏广告, 贴片广告, OAID, 广告自动化接入, 广告植入, RTB, 广告错误排查 |
| [`/hmos-arkts-deprecated-interface-checker`](./skills/harmonyos/development/arkts/hmos-arkts-deprecated-interface-checker/SKILL.md) | 检查 HarmonyOS 项目中的废弃 SDK 接口并提供修复建议。当需要清理废弃 API、升级 API 版本、优化代码质量或进行静态语法检查时使用。提供详细的迁移方案、修复优先级分类和代码示例。 |
| [`/hmos-arkts-knowledge-retriever`](./skills/harmonyos/development/arkts/hmos-arkts-knowledge-retriever/SKILL.md) | Retrieve grounded ArkTS references for pure non-UI ArkTS work and ArkTS API usage. Use this skill whenever the user is writing, reviewing, testing, validating, running, or debugging ArkTS code and the answer should be backed by repository sources such as `docs/ArkTS-Language-Guide/`, `docs/ArkTS-API-Reference/`, the linter-derived `docs/linter/ArkTS_Syntax_Knowledge_From_Linter.md`, and the bundled lightweight lint tool docs `docs/linter/linter-cli.md` plus `linter-cli/` instead of model memory. This skill is especially useful for syntax rules, ArkTS-specific restrictions, API/module/member lookup, common-library usage, lightweight lint workflow lookup, runnable example lookup, snippet validation context, and figuring out which repository section to trust before suggesting code or fixes. |
| [`/hmos-arkts-napi-side-effect-fixer`](./skills/harmonyos/development/arkts/hmos-arkts-napi-side-effect-fixer/SKILL.md) | 鸿蒙 ArkTS NAPI 模块 import（dlopen）副作用端到端技能：扫描识别（prescan 初筛/深析 + rulebook 语义判定，输出问题行号、白话判定原因）＋ 整改落地（类别2 加载期重初始化全局单例改惰性访问器；类别1 注册函数违规业务逻辑迁显式 init() 导出）＋ 回归验证（残留清零 + 编译运行验证）。当需要审查 NAPI so import 副作用、排查启动耗时劣化/多页面全局状态不一致、检出的副作用问题需要整改、或整改后回归验证时使用。 |
| [`/hmos-arkts-syntax-checker`](./skills/harmonyos/development/arkts/hmos-arkts-syntax-checker/SKILL.md) | 检查并修复 HarmonyOS 项目的 ArkTS 语法错误，自动化构建项目。当需要编译项目、修复编译错误、生成 HAP/App 产物时使用。提供静态语法检查、错误自动修复、循环构建直到成功的完整工作流程。支持错误优先级分类（P0/P1/P2）、最大重试机制、构建产物自动定位。 |
| [`/arkuix-bridge-codegen`](./skills/harmonyos/development/arkui-x/arkuix-bridge-codegen/SKILL.md) | 消费 F2 ScanReport 的 ③/④ 分类，为每个需桥接接口生成六件套（①Interface 契约 ②Local HarmonyOS class ③ArkUIX 桥接 class ④Android BridgePlugin ⑤iOS BridgePlugin ⑥Impl 平台分发器——一码三平台）与 BridgeArtifact(JSON)+报告(MD)。OH 应用迁移 ArkUI-X 完成扫描后需生成跨平台桥接骨架时使用；只生成骨架/胶水，平台业务以 TODO 占位待补，增量再生成不覆盖手改区。 |
| [`/arkuix-flowlog-diagnose-skill`](./skills/harmonyos/development/arkui-x/arkuix-flowlog-diagnose-skill/SKILL.md) | Use when diagnosing ArkUI-X (Android/iOS) white screen, jank, startup slowness, or crash from developer logcat/os_log/hilog. Analyzes 4 dimensions — lifecycle anchor coverage (22 anchors across Java/JNI/native/shared) / FAQ pattern grep (12 log signatures + 4 config fallbacks) / first-frame presence (F1 request + vsync) / timestamp gaps-duplicates — and outputs symptom classification → stall stage → evidence → FAQ root cause → remediation. Triggers on "白屏", "卡顿", "闪退", "启动慢", "ArkUI-X 日志排查", "flowlog diagnose", or when a developer pastes ArkUI-X log fragments for triage. |
| [`/arkuix-interface-scan`](./skills/harmonyos/development/arkui-x/arkuix-interface-scan/SKILL.md) | 扫描 OpenHarmony Stage 工程的 @ohos.*/@hms.* 接口引用与 Native NDK C-API 引用（#include 头文件 + OH_* 符号），按六分类（完整直用/有损直用/等价桥接/降级桥接/平台裁剪/业务决策，unknown 兜底）产出 scan-report.json 与 migration-advice.md。评估 OH 应用迁移 ArkUI-X 接口适配性时使用；FA 模型不支持。 |
| [`/arkuix-migration-orchestrator`](./skills/harmonyos/development/arkui-x/arkuix-migration-orchestrator/SKILL.md) | 编排 ArkUI-X 迁移全流程：按 扫描(F2)→骨架(F1)→桥接(F3)→报告 顺序调度三 Skill，在关键决策点（骨架模式/配置迁移/new 选项/覆盖确认）与⑥业务决策项（@ohos.* 独有→删除/重新设计；@hms.*/闭源 kit→降级 OH 替代/降级平台原生桥接/自行实现/裁剪）引导开发者确认，管理 MigrationState（断点续跑/回滚，checkpoint 快照），汇总迁移报告（含源码改写工单/适用版本与环境要求+安全声明）。需端到端完成 OH 应用迁移 ArkUI-X 而非手工串联 Skill 时使用；三 Skill 各自仍可独立运行，编排器为可选增强，全程离线。 |
| [`/arkuix-migration-skeleton`](./skills/harmonyos/development/arkui-x/arkuix-migration-skeleton/SKILL.md) | 为 OpenHarmony Stage 工程生成 ArkUI-X 跨平台骨架（Android/iOS 壳+共享 ArkTS）。modify（内置归档自修改，零 ace 依赖）/ new（归档物化或 ace create）双模式；FA 拒绝；检测编译环境。搭建跨平台工程结构时使用。 |
| [`/arkui-imperative-node`](./skills/harmonyos/development/arkui/arkui-imperative-node/SKILL.md) | 指导开发者快速接入 ArkUI 命令式节点（BuilderNode/FrameNode/RenderNode）。当用户提到"命令式节点""BuilderNode""FrameNode""RenderNode""动态挂载""预创建组件""命令式框架""NodeContainer""NodeController""节点不显示""dispose""内存释放""@Reusable 联用""aboutToDisappear 不触发""冻结 update""文件路径""组件信息"等关键词时使用此 Skill。覆盖场景判断、API 选型、骨架代码生成、文件路径输入与上下文感知方案生成和常见问题排障五个能力。 |
| [`/arkui-memory-analysis`](./skills/harmonyos/development/arkui/arkui-memory-analysis/SKILL.md) | 检查 ArkUI 应用源码和 inspector dump 中的 18 类内存反模式（不可见页面、Tabs 缓存/预加载/动画、长列表非懒加载、布局冗余、页面栈过深、缓存池未释放、XComponent/命令式节点未释放、Image 超大图、Canvas 渐变、ImageAnimator/Video 常驻、ArkWeb 过多、BuilderNode 销毁流程不完整、缓存池清空使能未设置）。通过关键词/正则 + 反模式匹配分析 .ets 源码，通过节点树结构分析 dump 文件，输出定性报告（Markdown）+ 标准化 schema（JSON）+ 内存测试用例构造指南。适用于内存劣化排查、不可见页面检测、缓存池泄漏诊断、组件树优化等诉求。 |
| [`/arkui-ndk-ui-node-skill`](./skills/harmonyos/development/arkui/arkui-ndk-ui-node-skill/SKILL.md) | 识别 CAPI 混合开发方向（P1 ArkTS→C 或 P2 C→ArkTS）并生成可运行工程骨架，同时检测七类常见坑点（handle 只能当 child、napi 引用成对、dispose 防泄漏、节点类型混乱、子线程调用、descriptor 字段顺序、ComponentContent 构造签名）。适用于"ArkTS 挂 Native""Native 挂 ArkTS""CAPI 混合""NodeContent""ContentSlot""ComponentContent""OH_ArkUI_GetNodeHandleFromNapiValue""addChild""ArkUI_NodeHandle""ArkUI_NodeContentHandle"等关键词触发的跨语言 UI 节点接入场景。 |
| [`/hmos-arkui-accessibility-skill`](./skills/harmonyos/development/arkui/hmos-arkui-accessibility-skill/SKILL.md) | Guides ArkUI/HarmonyOS screen-reader accessibility adaptation — routes demands to accessibility/focus attributes with semantic guardrails and build-profile.json5 version gating; answers knowledge-only questions (零代码). Use when the user mentions 接入/适配无障碍, 读屏/屏幕朗读, 播报文本, 聚合播报, 自定义走焦/首焦点, Canvas 自绘读不到, 支持哪些无障碍能力/默认使能/接口是什么（问答）, accessibility 编译报错, or edits .ets involving accessibility* attributes. |
| [`/hmos-arkui-dark-light-adaptation`](./skills/harmonyos/development/arkui/hmos-arkui-dark-light-adaptation/SKILL.md) | 为 HarmonyOS/OpenHarmony ArkUI 应用接入深浅色、配置颜色资源、减少 color.json 维护、设置 WithTheme 局部主题，并检查和启用高性能深浅色切换。适用于“协助适配深色模式”“深浅色切换卡顿”“局部设置深浅色”“缩减 color.json”“减少后续颜色资源适配”等需求。 |
| [`/hmos-arkui-develop-skill`](./skills/harmonyos/development/arkui/hmos-arkui-develop-skill/SKILL.md) | REQUIRED before writing the first .ets file of a session. Fatal gotchas list + API quick-reference for HarmonyOS ArkTS/ArkUI development. Load this skill when writing or modifying .ets files, porting TypeScript to ArkTS, or building any ArkUI page, component, layout, navigation, dialog, state-driven UI, or animation. Covers ArkTS linter rules, forbidden syntax, null safety, struct/@Component constraints, V1/V2 state management, rendering control, API parameter correctness, and UI quality. Triggers — .ets, ArkTS, ArkUI, HarmonyOS, struct, @Component, TS-to-ArkTS migration, ArkUI build error, runtime crash. |
| [`/hmos-arkui-kit-window-floatwindow`](./skills/harmonyos/development/arkui/hmos-arkui-kit-window-floatwindow/SKILL.md) | 辅助 OpenHarmony 悬浮类需求开发：画中画（PiPWindow）、闪控窗（floatView）、闪控球（floatingBall）。覆盖能力分流、接口指南、代码查错（指出文件/行/错在哪并直接改）、按需求改用户工程里的 ArkTS、按评审稿写需求设计。Use when the user mentions 画中画、PiP、PiPWindow、闪控窗、floatView、闪控球、floatingBall、悬浮小窗、球窗绑定、防窥保护组合，或要为这三类写代码/查误用/写需求。不覆盖子窗口 createSubWindow、全局悬浮窗 TYPE_FLOAT、模态窗 TYPE_DIALOG。 |
| [`/hmos-arkui-knowledge-retriever`](./skills/harmonyos/development/arkui/hmos-arkui-knowledge-retriever/SKILL.md) | ArkUI 知识检索层，按问题语境自动路由到 ArkTS 声明式或 NDK(C-API)知识库进行精准检索，不涉及代码生成或修改。触发场景：(1) 用户查询 ArkUI/ArkTS API 用法、参数细节或版本支持 (2) 验证组件/装饰器的正确用法 (3) 排查 ArkUI 编译错误码或运行时异常 (4) 询问状态管理 V1/V2 差异或迁移 (5) 查询 NDK / Native / C-API 接口或头文件 (6) 其他 skill 调用检索获取 API 证据。 |
| [`/hmos-arkui-longtake-transition`](./skills/harmonyos/development/arkui/hmos-arkui-longtake-transition/SKILL.md) | 为鸿蒙(HarmonyOS)应用添加一镜到底转场效果。当用户提到一镜到底、转场动画、页面跳转动画、Navigation转场、卡片展开动画、图片查看大图动画、ezcustomtransition、自定义NavContentTransition、longtake、连续转场、沉浸式转场等关键词时，务必使用此skill。也适用于用户想要在鸿蒙应用中实现类似iOS的卡片展开、图片预览等流畅过渡效果的场景，即使他们没有明确提到"一镜到底"这个术语。 |
| [`/hmos-arkui-mvvm-pattern`](./skills/harmonyos/development/arkui/hmos-arkui-mvvm-pattern/SKILL.md) | HarmonyOS ArkUI MVVM 架构技能。适用于：(1) 项目分层设计 Model/ViewModel/View (2) 目录结构规划 (3) 组件职责与数据流规范 (4) 视图架构检视以及整改项目为MVVM模式等场景。在有以下请求时触发：1.在ArkUI中明确要求使用MVVM架构来添加或重构功能，并要求保持架构简洁。2.明确要求使用MVVM架构创建或改进视图模型，并将逻辑从视图中移出。3.修复状态管理混乱的问题。4.提升项目可测试性，通过拆分结构降低复杂度。5.将已有项目整改为 MVVM 架构。 |
| [`/hmos-arkui-navigation-transition`](./skills/harmonyos/development/arkui/hmos-arkui-navigation-transition/SKILL.md) | 指导开发者为 ArkUI Navigation/NavDestination 配置转场动画（systemTransition/customTransition/customNavContentTransition/disableAnimation 四类方案）。当用户提到 Navigation 转场、NavDestination 转场、转场动画、systemTransition、customTransition、customNavContentTransition、disableAnimation、禁用转场、自定义转场、可交互转场、系统转场等关键词时，务必使用此 skill。也适用于用户想要在鸿蒙应用中实现页面切换转场动画效果的场景，即使没有明确提到具体 API 名称。不适用于纯路由跳转/路由配置问题（如 pushPath、pop、NavPathStack 路由管理、路由表配置），这类需求不在本 skill 范围内。 |
| [`/hmos-arkui-performance-analysis`](./skills/harmonyos/development/arkui/hmos-arkui-performance-analysis/SKILL.md) | 基于真实 ArkTS 代码，只读分析 ArkUI 组件刷新与复用、列表滑动、页面转场、首页启动和动画性能问题。适用于刷新范围过大、重复创建、Swiper 翻页卡顿、页签或路由进入慢、转场集中构建、滑动或动画掉帧、首页首帧及内容显示慢，输出问题位置、原因、修改建议和验证方法。 |
| [`/hmos-arkui-scenario-development`](./skills/harmonyos/development/arkui/hmos-arkui-scenario-development/SKILL.md) | HarmonyOS/鸿蒙 ArkUI 场景化开发技能，用于实现、排查或验证 ArkUI(.ets) 功能，并按需求(REQ)/开发(DEV)/修复(FIX)/验证(VAL)四阶段路由到4个一级场景：ARKUI-01 ArkUI基础语法（声明式UI、条件渲染、自定义组件、Builder/BuilderParam、AttributeModifier、组件复用）;ARKUI-02 基于UI框架构建基础代码逻辑（手势/键盘交互、路由导航、组件页面、弹窗菜单、动画转场、焦点走焦、综合应用页面骨架、自定义组件FrameNode/Modifier、弹窗进阶、布局组件、图形图像、滚动列表、文本组件）;ARKUI-03 状态管理（组件状态同步，V1/V2使用、V1/V2混用、状态变量相关扩展能力）;ARKUI-04 编译与运行时（编译构建失败、ANR、AppFreeze异常卡死、白屏、崩溃闪退，长列表卡顿丢帧、不跟手、资源加载慢等问题）。不适用：与 ArkUI 无关的原生开发、非 HarmonyOS 平台、CI/CD。 |
| [`/hmos-arkui-statemgt-migration`](./skills/harmonyos/development/arkui/hmos-arkui-statemgt-migration/SKILL.md) | 帮助开发者将ArkUI状态管理从V1迁移到V2。触发场景：(1) V1项目升级到V2；(2) 迁移@Component/@State/@Prop/@Link/@Observed/@ObjectLink/@Provide/@Consume/@Watch/@Reusable装饰器；(3) 迁移LocalStorage/AppStorage/PersistentStorage/Environment应用级状态；(4) 将ForEach/LazyForEach迁移到Repeat；(5) 解决animateTo在V2中的兼容问题；(6) 处理V1与V2混用场景；(7) 询问V1和V2装饰器对应关系或差异。 |
| [`/hmos-arkui-v1-v2-migration-and-mixusage`](./skills/harmonyos/development/arkui/hmos-arkui-v1-v2-migration-and-mixusage/SKILL.md) | 分析并实施 ArkUI 状态管理 V1/V2 迁移或混用，覆盖整仓/组件迁移、V1/V2 共存、跨版本数据流、storage、渲染复用、依赖和构建验证。用于迁移规划与改造、混用方案设计、兼容边界实现或问题诊断；不用于普通的纯 V2 功能开发。 |
| [`/hmos-ascf-assistant`](./skills/harmonyos/development/atomic-service/hmos-ascf-assistant/SKILL.md) | 辅助开发者使用 ASCF 工具链开发 HarmonyOS 元服务。触发场景：(1) 任何提到 ASCF 的问题；(2) 检测到项目包含 ascf/ascf_src 目录（即 ASCF 项目）；(3) 需要生成元服务睫毛图；(4) 将小程序转换为 ASCF 元服务；(5) 开发ASCF元服务页面/组件/平台能力（华为账号登录、隐私托管、授权、支付、分享、web-view、定位等）；(6) 将 Taro/uni-app 项目适配为 ASCF 元服务；(7) HarmonyOS 4及以下版本元服务适配与发布。 |
| [`/hmos-ascf-convert-taro`](./skills/harmonyos/development/atomic-service/hmos-ascf-convert-taro/SKILL.md) | 辅助开发者将 Taro 项目适配（转换）为 ASCF 元服务。当需要在 Taro（React/Vue）项目中支持 ASCF 元服务平台，或将现有 Taro 项目迁移到 ASCF 时使用此技能。提供完整的环境搭建、项目配置、package.json 脚本、常见问题排查和发布流程。 |
| [`/hmos-ascf-convert-uniapp`](./skills/harmonyos/development/atomic-service/hmos-ascf-convert-uniapp/SKILL.md) | 辅助开发者将 uni-app 项目适配(转换)为 ASCF 元服务。当需要使用 uni-app（HBuilderX 或 CLI）开发 HarmonyOS 元服务（MP-HARMONY），或将现有 uni-app 项目迁移(转换)到 ASCF 时使用此技能。提供完整的环境搭建、HBuilderX 开发流程、CLI 配置、常见问题排查和上架审核指引。 |
| [`/hmos-atomicservice-assistant`](./skills/harmonyos/development/atomic-service/hmos-atomicservice-assistant/SKILL.md) | 辅助鸿蒙开发者构建元服务（Atomic Service / 免安装应用）。只要用户提到元服务、atomicService、免安装、atomic service，或遇到以下任意问题，都必须使用本 Skill：创建/改造元服务项目、@atomicservice API 报错、配置隐私托管、设置可信域名、静默登录/免密登录、接入鸿蒙支付、包大小超限、AtomicServiceEnhancedWeb vs ArkWeb、Navigation 分包路由、睫毛图标、ICP备案、上架审核被拒。提供规范说明、合规检查清单、代码示例和上架最佳实践。 |
| [`/hmos-live-view-kit-build-location`](./skills/harmonyos/development/live-view-kit/hmos-live-view-kit-build-location/SKILL.md) | HarmonyOS实况窗（LiveView）代码生成助手，支持创建、更新、停止实况窗。用户输入创建/更新/结束/完整/补全实况窗代码时触发，覆盖即时配送、打车、排队、计时、航班、高铁、共享租赁、运动锻炼、导航九大场景。 |
| [`/hmos-map-kit-map-creation`](./skills/harmonyos/development/map-kit/hmos-map-kit-map-creation/SKILL.md) | HarmonyOS Map Kit地图创建开发指南，支持地图组件创建、覆盖物管理、相机控制、图层配置等能力。 适用情形：用户要求创建/绘制/展示地图、添加地图标记、绘制图形、管理覆盖物交互、控制相机位置等。  |
| [`/hmos-map-kit-poi-search`](./skills/harmonyos/development/map-kit/hmos-map-kit-poi-search/SKILL.md) | HarmonyOS Map Kit位置搜索与POI检索开发指南。当用户明确要求开发实现（如"编写代码"、"开发功能"等）位置搜索、POI检索、地理编码、逆地理编码等功能代码时触发。适用于直接调用本地SDK接口获取地图元素的场景。 适用情形：关键字搜索地点、周边地点检索、地点详情查询、地址与坐标转换。  |
| [`/hmos-map-kit-route-planning`](./skills/harmonyos/development/map-kit/hmos-map-kit-route-planning/SKILL.md) | HarmonyOS Map Kit路径规划开发指南。 适用情形：用户明确要求开发实现（如"编写代码"、"开发功能"等）路径规划、批量算路、轨迹纠偏等功能代码时触发。  |
| [`/hmos-payment-kit-huawei-payment-integration`](./skills/harmonyos/development/payment-kit/hmos-payment-kit-huawei-payment-integration/SKILL.md) | 本技能面向 HarmonyOS Payment Kit 华为 / 鸿蒙支付接入排障，覆盖基础支付、签约代扣、平台合单、回调验签、沙盒联调、SpringBoot 服务端与 ArkTS 客户端适配，包含官方 Java‑SDK、Maven 构建、配置校验、常见报错排查，命中指定关键词即启用，输出接入指引与问题修复方案。 |
| [`/hmos-push-kit`](./skills/harmonyos/development/push-kit/hmos-push-kit/SKILL.md) | 华为Push Kit推送服务集成助手（Master Skill/大路由）。帮助开发者快速集成HarmonyOS推送功能，获取Push Token， 配置推送服务，开通场景化消息权益。支持发送通知消息、应用内通话消息、后台消息等场景。  ============================================================ 触发条件（只有满足以下意图时才触发）： ============================================================  ✅ 正确触发场景（开发者需要接入/开发推送功能）： - "帮我在项目中接入华为推送" - "我要实现推送通知功能" - "如何接入push kit" - "帮我接入voip消息" - "接入后台消息" - "发送推送通知" - "获取push token" - "配置推送服务" - "开通推送消息权益"  ❌ 不触发场景（仅为询问、比较、测试、排查等）： - 询问对比/优缺点："鸿蒙push和苹果push区别"、"推送有什么优点" - 否定意图："我不想接入推送"、"不需要推送" - 仅输入关键词："推送"、"消息"、"后台" - 测试/调试："push通知测试"、"push调试" - 问题排查："push失败"、"推送异常" - 配置咨询："token怎么配置" - 带引号输入："push通知"、"推送消息"  路由规则： - 若开发者需要单独获取Push Token → 路由到 hmos-push-kit-token - 若开发者需要发送通知消息 → 路由到 hmos-push-kit-notification（先检查Token状态） - 若开发者需要实现voip/应用内通话 → 路由到 hmos-push-kit-voip（先检查Token状态） - 若开发者需要接入后台消息 → 路由到 hmos-push-kit-background（先检查Token状态） - 若开发者请求模糊（未明确场景）→ 必须先询问具体场景，再路由到对应子Skill  ⚠️ 重要：主Skill不生成任何场景化消息的具体代码！当开发者请求模糊时，必须先询问具体场景，再路由到对应子Skill生成完整代码。  此技能能够为开发者生成可直接编译通过的ArkTS代码，没有语法错误。 |
| [`/hmos-push-kit-background`](./skills/harmonyos/development/push-kit/hmos-push-kit/hmos-push-kit-background/SKILL.md) | 推送后台消息助手。当开发者需要实现后台消息接收、数据静默更新、或消息缓存功能时触发。  ============================================================ 触发条件（只有满足以下意图时才触发）： ============================================================  ✅ 正确触发场景： - "帮接入后台消息" - "实现数据静默更新" - "添加推送后台消息功能" - "推送后台消息" - "消息缓存到数据库" - "进程不在前台接收消息" - "需要接入后台消息功能"  ❌ 不触发场景： - 询问/概念："后台消息是什么" - 否定意图："不需要后台消息" - 仅输入关键词："后台"、"消息" - 测试/调试："后台消息测试" - 带引号输入："后台消息" - 配置咨询："后台消息怎么配置"  ⚠️ 重要提醒： - 只要需要接入后台消息功能，**必须加载本 skill** - 本 skill 提供完整的后台消息接入指导，包括消息接收、数据处理、缓存策略等 - 后台消息接入涉及数据静默更新、缓存策略等完整流程，不能凭其他 skill 的通用说明（如"同一 ability 接收多种消息类型"）自行编写  此 Skill 专注于帮助开发者实现推送后台消息的接收和配置。  前置检查： - 在继续之前，会自动检查开发者是否已接入Push Token - 如果未接入Token，会引导开发者先使用 hmos-push-kit-token Skill |
| [`/hmos-push-kit-notification`](./skills/harmonyos/development/push-kit/hmos-push-kit/hmos-push-kit-notification/SKILL.md) | 发送通知消息助手。当开发者需要实现推送通知功能、发送消息提醒、配置通知样式或点击动作时触发。  ============================================================ 触发条件（只有满足以下意图时才触发）： ============================================================  ✅ 正确触发场景： - "帮我在项目中接入推送通知" - "实现推送消息功能" - "添加推送消息功能" - "接入通知消息" - "发送通知消息" - "配置推送前台接收"  ❌ 不触发场景： - 询问/概念："通知消息是什么"、"推送有啥优点" - 否定意图："不需要通知消息" - 仅输入关键词："通知"、"推送消息" - 测试/调试："测试推送通知" - 问题排查："推送失败"、"通知异常" - 带引号输入："推送通知" - 配置咨询："通知怎么配置"  此 Skill 专注于帮助开发者实现通知消息的发送和配置。  前置检查： - 在继续之前，会自动检查开发者是否已接入Push Token - 如果未接入Token，会引导开发者先使用 hmos-push-kit-token Skill |
| [`/hmos-push-kit-token`](./skills/harmonyos/development/push-kit/hmos-push-kit/hmos-push-kit-token/SKILL.md) | Push Token 获取助手。可作为单独接入能力使用。当开发者需要集成华为推送服务、首次获取 Push Token、或 Token 获取失败时触发。  ============================================================ 触发条件（只有满足以下意图时才触发）： ============================================================  ✅ 正确触发场景： - "帮我接入push token" - "获取push token" - "首次集成推送功能" - "getToken调用失败" - "token获取报错1000900010" - 需要在项目中添加getToken代码  ❌ 不触发场景： - 询问/概念："token是什么"、"为什么需要token" - 对比问题："华为push和苹果push区别" - 仅输入关键词："token"、"push" - 否定意图："不想接入token" - 带引号输入："push token" - 配置咨询："token怎么配置"  此 Skill 专注于帮助开发者正确实现 Push Token 的获取。  重要说明： - 此 Skill 可作为单独接入能力使用 - hmos-push-kit-notification 和 hmos-push-kit-voip 在接入前会先检查 Token 状态 - 如果未接入 Token，会引导开发者先使用此 Skill |
| [`/hmos-push-kit-voip`](./skills/harmonyos/development/push-kit/hmos-push-kit/hmos-push-kit-voip/SKILL.md) | 推送应用内通话消息助手（VOIP）。当开发者需要实现语音/视频来电通知、voip功能、或呼叫接听界面时触发。  ============================================================ 触发条件（只有满足以下意图时才触发）： ============================================================  ✅ 正确触发场景： - "帮接入voip消息" - "实现语音来电通知" - "添加推送应用内通话消息功能" - "接入视频通话功能" - "应用内通话消息" - "voip呼叫接听界面" - "需要接入voip功能"  ❌ 不触发场景： - 询问/概念："voip是什么"、"语音通话怎么实现" - 否定意图："不需要voip" - 仅输入关键词："voip"、"通话" - 测试/调试："voip测试" - 带引号输入："voip"、"语音通话" - 配置咨询："voip怎么配置"  ⚠️ 重要提醒： - 只要需要接入 voip 功能，**必须加载本 skill** - 本 skill 提供完整的 voip 接入指导，包括 VoipCallService、CalleePage、CallComponent 等组件的创建 - voip 接入涉及来电处理、呼叫界面、状态上报等完整流程，不能凭其他 skill 的通用说明（如"同一 ability 接收多种消息类型"）自行编写  此 Skill 专注于帮助开发者实现应用内通话消息的推送功能。 |
| [`/hmos-scan-kit-customscan`](./skills/harmonyos/development/scan-kit/hmos-scan-kit-customscan/SKILL.md) | 帮助开发者快速接入华为 Scan Kit 自定义界面扫码能力，仅在需要支持完全自定义相机预览流 UI 界面、闪光灯控制、变焦、对焦等功能的场景使用 |
| [`/hmos-scan-kit-defaultscan`](./skills/harmonyos/development/scan-kit/hmos-scan-kit-defaultscan/SKILL.md) | 帮助开发者快速接入华为 Scan Kit 默认界面扫码能力，在不需要完全自定义相机界面、闪光灯控制、变焦、对焦等高级功能时优先使用 |
| [`/hmos-one-sdk-skill`](./skills/harmonyos/development/sdk/hmos-one-sdk-skill/SKILL.md) | ⚠️ MUST LOAD before writing first .ets file that imports from @kit.*. This skill provides verified API signatures, import paths, error codes, permission requirements, and example code for 25 Kits (AccountKit, MediaKit, NetworkKit, ScanKit, LocationKit, PushKit etc.). Even if you have partial API info from other sources, this skill covers complete error codes and permission requirements they lack. Load when — (1) writing ANY @kit.* import; (2) calling Kit APIs like vibrator, Bluetooth, location, scan, account, push, network, health, wear, map, IAP, accessibility, i18n, form, widget, card, cross-device collaboration; (3) @kit.* compile errors (wrong namespace, missing exported member, type mismatch) — load BEFORE attempting fixes; |
| [`/hmos-share-kit-gestures-share`](./skills/harmonyos/development/share-kit/hmos-share-kit-gestures-share/SKILL.md) | 为 HarmonyOS 工程接入 Share Kit 隔空传送文件 / App Linking 链接，支持首次接入与增量升级。当开发者提到隔空传送、gesturesShare、一抓一放或要求接入时使用。提供首次接入模板注入、生命周期接线、入口 Ability 加载检测、App Linking 端侧合并、异构实现迁移、两阶段骨架回填等能力。 |
| [`/hmos-share-kit-knock-share`](./skills/harmonyos/development/share-kit/hmos-share-kit-knock-share/SKILL.md) | Integrating HarmonyOS Share Kit knock share into projects. Use when requests involve knock share, touch-to-share file or link transfer. Provides manager injection, lifecycle listener registration, SharedData construction for files or App Linking, and API version compatibility checks. |
| [`/hmos-window-hover-state`](./skills/harmonyos/development/window/hmos-window-hover-state/SKILL.md) | 为鸿蒙（HarmonyOS/OpenHarmony）折叠屏应用提供窗口悬停态适配：折痕避让几何、上半屏内容 + 下半屏固定操作坞布局、悬停监听接入、SDK 未声明时的降级方案、系统栏避让与旋转策略。当任务涉及悬停态/半折叠（HALF_FOLD 笔记本形态）适配、悬停拍摄、悬停视频布局、折痕避让、onWindowPostureModeChange / isInWindowPostureMode 悬停监听时使用。Use when adapting apps to foldable hover state, listening for window posture mode changes, or avoiding fold crease regions. 不适用于 PC 沉浸式 title/dock hover、鼠标指针 hover 效果与 WMS 系统服务侧功能开发。 |
| [`/hmos-window-immersive`](./skills/harmonyos/development/window/hmos-window-immersive/SKILL.md) | 为鸿蒙（HarmonyOS/OpenHarmony）应用提供窗口沉浸式效果接入指引，覆盖 @ohos.window（ArkTS，Stage 模型）与 ArkUI 组件级属性。当任务涉及以下场景时使用：沉浸式状态栏/导航条隐藏与显示、安全区域避让（avoidArea 查询与监听）、扩展沉浸式（内容延伸到状态栏/导航条/挖孔区）、系统栏样式定制（颜色、透明度、内容色）、沉浸式状态切换（进入/退出/动态切换）、多设备适配（直板机/平板/折叠屏/自由窗口标题栏沉浸）。提供三种沉浸式方案对比选型、方案选型决策树、避让区类型映射表、核心接口速查表和实战场景代码。 |
| [`/hmos-window-smart-orientation`](./skills/harmonyos/development/window/hmos-window-smart-orientation/SKILL.md) | 为鸿蒙（HarmonyOS/OpenHarmony）应用提供窗口旋转策略接入与智感旋转适配指引，覆盖 @ohos.window（ArkTS，Stage 模型）。当任务涉及以下场景时使用：智感旋转接入与机制说明、旋转策略选择（AUTO_ROTATION、USER_ROTATION、FOLLOW_DESKTOP、UNSPECIFIED 等 18 种 Orientation 枚举）、setPreferredOrientation 运行时设置、module.json5 orientation 静态配置、视频类横竖屏切换、直板机/平板/折叠屏多设备方向适配、旋转锁定、rotationChange 旋转监听、convertOrientationAndRotation 屏幕方向与窗口方向互转、扫描项目并将固定方向策略改造为支持智感旋转的策略。提供智感旋转机制说明、两种设置方式对比、18 种策略映射表、策略选型决策树和「扫描→评估→改造→验证」迁移流程。 |

### test — 测试（2）


| skill | 中文介绍 |
|-------|---------|
| [`/hmos-instrument-test`](./skills/harmonyos/test/hmos-instrument-test/SKILL.md) | 在 HarmonyOS 应用/服务开发中执行模块的 Instrument Test（包括 ArkTS/JS 和 C++ 测试），支持运行、覆盖率统计、ASan 检测等模式，并可指定测试范围（模块、测试套件、单个用例）。 |
| [`/hmos-local-test`](./skills/harmonyos/test/hmos-local-test/SKILL.md) | 在 HarmonyOS 应用/服务开发中执行模块的 Local Test（ArkTS/JS 单元测试），支持运行、覆盖率统计等模式，并可指定测试范围（模块、测试套件、单个用例）。 |

### tools — DevEco 工具（11）


| skill | 中文介绍 |
|-------|---------|
| [`/deveco-autobugfix`](./skills/harmonyos/tools/deveco/deveco-autobugfix/SKILL.md) | 自动执行鸿蒙应用 Bug 全流程修复，涵盖问题复现、根因分析、最小化代码修复、构建编译与运行验证。 依赖 deveco-mcp 提供 verify_ui/build_project/start_app 等能力。 使用场景：用户要求自动修复鸿蒙项目 Bug，或输入触发词：自动修复、auto fix、auto-fix、自动bug修复、autofix。 提供熔断保护、3 次构建重试上限、修复经验沉淀机制。  |
| [`/deveco-native-flow`](./skills/harmonyos/tools/deveco/deveco-native-flow/SKILL.md) | 三端一致开发流水线（HarmonyOS/Android/iOS）：analyse → plan → coding → build → verify。 自包含：内嵌 HarmonyOS ArkTS 知识路由，无需外部 skill 依赖。 支持正向开发和翻译开发两种模式。  执行流程： 1. 自动检测项目类型和平台 2. 执行 analyse 阶段生成跨端技术方案（读取 references/native-analyse/SKILL.md） 3. 逐端执行 plan 阶段生成实施计划（读取 references/native-plan/SKILL.md） 4. 逐端执行 coding 阶段完成编码（读取 references/native-coding/SKILL.md） 5. 构建验证 + UI 验证  Triggers: 三端开发, native pipeline, deveco pipeline, cross-platform, 跨端开发, 技术方案, 实施计划, 编码实施  |
| [`/deveco-requirement-development`](./skills/harmonyos/tools/deveco/deveco-requirement-development/SKILL.md) | 覆盖鸿蒙/HarmonyOS/ArkTS 应用需求开发流程。在用户要落地新功能/新页面/新模块、PRD、端到端需求开发或鸿蒙应用开发时使用。不用于仅询问 API 语法用法、或未声明走完整链路的单文件 Bug 修复。用户意图模糊时先澄清是否需要端到端交付。 |
| [`/deveco-studio-codelinter`](./skills/harmonyos/tools/deveco/deveco-studio-codelinter/SKILL.md) | 对 HarmonyOS（鸿蒙）项目运行 DevEco Studio CodeLinter 静态代码检查，解读检查结果并提供修复建议。支持 ArkTS、TS、JS 文件，涵盖性能、安全、代码规范、正确性、跨设备适配、API 兼容性等规则集。当用户提到 codelinter、code linting、鸿蒙代码检查、鸿蒙应用质量、HarmonyOS 代码质量检查、静态代码分析、规范扫描、性能检查、安全扫描、代码审查、规则检查、规则集、lint 报告时使用。 |
| [`/deveco-studio-codescanner`](./skills/harmonyos/tools/deveco/deveco-studio-codescanner/SKILL.md) | 指导使用 codescanner 命令行工具扫描 HarmonyOS 工程（ArkTS 23 条 + C++ 27 条资源泄漏规则），覆盖参数用法、SDK 解析、规则配置（-c 白名单）、输出产物与退出码，解读 SARIF/HTML 扫描结果，并按权限/路径/JSON/引擎分类排查扫描问题。当用户提到 codescanner、code-scanner、code scanner、代码扫描，询问如何运行扫描或指定 SDK/输出/格式/规则配置，报告扫描报错、日志或退出码问题，询问结果解读或规则含义（如 WindowListenerNotOff、NapiWrap API Not Paired），或 codescanner 命令找不到、command line tools 在哪下载（tool-availability：仅 26.0.1+ 支持 codescanner 扫描）时使用。 |
| [`/deveco-studio-emulator`](./skills/harmonyos/tools/deveco/deveco-studio-emulator/SKILL.md) | HarmonyOS模拟器管理助手。**首次使用必须先运行 `node scripts/setup.js --force` 配置路径**，然后才能执行模拟器启动、应用安装调试等操作。包含完整的场景化设备控制命令（旋转、电源、截屏、音量、摇一摇、折叠）。支持Windows/macOS/Linux。触发词：模拟器、emulator、hdc、推包、安装应用、启动模拟器、构建推包。 |
| [`/deveco-studio-hilog`](./skills/harmonyos/tools/deveco/deveco-studio-hilog/SKILL.md) | HarmonyOS日志分析助手，专注于hilog日志查看、崩溃日志分析、日志导出(-logZip)、手动日志分析。包含完整的hilog命令、hidumper堆栈转储、崩溃日志自动解压分析功能。支持Windows/macOS/Linux跨平台。 |
| [`/deveco-studio-hvigor`](./skills/harmonyos/tools/deveco/deveco-studio-hvigor/SKILL.md) | HarmonyOS应用构建工具助手，专注于使用Hvigor命令行工具构建HarmonyOS应用。包含完整的构建命令、参数说明、清理操作和CI/CD集成指南。触发词：hvigor、构建、编译、assembleHap、clean、build。 |
| [`/deveco-studio-verify`](./skills/harmonyos/tools/deveco/deveco-studio-verify/SKILL.md) | HarmonyOS 设备验证工具 - 支持多设备类型验证（手机/折叠屏/平板）、应用安装、UI自动化操作、截图验证、日志收集和 Journey 测试框架。使用 hdc 命令行工具直接操作设备。适用于测试 HarmonyOS 应用在不同设备类型上的表现、验证 UI 在不同屏幕尺寸下的适配、执行 Journey 自动化测试、收集设备日志进行调试、构建产物发布前的完整验证。 |
| [`/hmos-lazy-import-analysis`](./skills/harmonyos/tools/lazy-import/hmos-lazy-import-analysis/SKILL.md) | 分析鸿蒙/OpenHarmony 应用源码与 redundant file 报告，识别可安全 import lazy 懒加载的模块，产出带完整证据链的修改建议，经 diff 预览确认后可机械应用改写。Use when 用户提供鸿蒙/OpenHarmony 应用源码和 redundant file 报告（hdc 从设备导出或本地 txt），要求识别哪些模块可以改为 import lazy 懒加载、分析模块顶层副作用、索取 lazy-import 修改建议、或在确认后应用这些修改。触发词：lazy import、lazy-import、模块懒加载、redundant file、冗余文件分析、启动耗时优化、模块加载开销、内存优化、应用 lazy 修改。 |
| [`/hmos-module-dependency-visualizer`](./skills/harmonyos/tools/modtree/hmos-module-dependency-visualizer/SKILL.md) | 采集并可视化 HarmonyOS/OpenHarmony 应用 ArkTS 模块的依赖关系，聚合文件级依赖为模块级，产出含循环依赖检测与扇入/扇出排行的交互式 HTML 依赖图和 Markdown 分析报告。支持 hdc 真机一键采集与本地 *_dependency_graph.txt 日志解析两种模式（工具为 skill 内嵌单文件，详见正文命令表）。Use when 用户提到 模块依赖、依赖图、依赖可视化、循环依赖、被依赖排行、dependency_graph.txt、modtree、采集应用依赖、分析抖音/头条等鸿蒙应用的模块结构。不处理启动性能、卡顿、内存、功耗等性能优化问题——「冷启动」仅指采集所需的完全重启，与启动速度无关。 |

### tooling — 审查工具（2）


| skill | 中文介绍 |
|-------|---------|
| [`/hmos-skill-reviewer`](./skills/harmonyos/tooling/hmos-skill-reviewer/SKILL.md) | Review and validate Agent Skills for compliance with Claude Skills specification. Use when evaluating SKILL.md files, checking naming conventions, validating content structure, or ensuring skills follow best practices. Provides comprehensive analysis of metadata format, content organization, progressive disclosure, and actionable vs knowledge-based content. |
| [`/hmos-skill-test-runner`](./skills/harmonyos/tooling/hmos-skill-test-runner/SKILL.md) | Discovers and executes test cases for Agent Skills changed in the current pull request. Use when a PR touches a skill that has test-cases, and the pipeline must run each case prompt in a separate model call, compare the answer with expected output, and publish summary findings. Supports three standard test case formats: trigger verification, smoke (routing), and functional testing. |

### launch-and-distribute — 发布与分发（2）


| skill | 中文介绍 |
|-------|---------|
| [`/app-metadata-audit-skill`](./skills/harmonyos/launch-and-distribute/app-metadata-audit-skill/SKILL.md) | 开发者在app开发提交agc前，可利用该skill规范对应用市场的元数据（名称、描述、关键词、隐私链接等）进行自动化合规性审查。支持华为应用市场审核规范，防止因低级错误导致被拒。 |
| [`/hmos-connect-api-cli-skill`](./skills/harmonyos/launch-and-distribute/hmos-connect-api-cli-skill/SKILL.md) | 用本 skill 内嵌的 connect-api-cli 脚本（scripts/，无需 npm 安装）操作华为 AppGallery Connect / AGC：登录登出、创建应用/元服务、查询 App ID、上传 APP（非 HAP）/APK、发布审核、邀请/公开测试、证书与 Profile、ACL、域名，以及 CSR/P12、assembleApp/assembleHap、encrypt-pwd、真机 hdc 安装。Use when 用户提到 AGC、AppGallery Connect、华为应用市场、hmos-connect-api-cli-skill、connect-api-cli、登录、退出登录、创建应用、创建元服务、上架、上传 APP、构建 app/release/debug 包、assembleApp、assembleHap、运行到手机、真机运行、hdc、发布/调试证书、Profile、p7b、csr、encrypt-pwd、ACL、邀请测试或公开测试。 |

## 三、Android Skills（37 个，description 已中文化）

### build-system（1）


| skill | 中文介绍 |
|-------|---------|
| [`/agp-9-upgrade`](./skills/android/build-system/agp/agp-9-upgrade/SKILL.md) | 升级或迁移 Android 项目以使用 Android Gradle Plugin (AGP) 版本 9。不要用此 skill 迁移 Kotlin Multiplatform (KMP) 项目。 |

### camera（1）


| skill | 中文介绍 |
|-------|---------|
| [`/camerax`](./skills/android/camera/camerax/SKILL.md) | 提供 Android CameraX 相机开发的技术指导。当实现相机功能、处理异步录制生命周期、使用 CameraX 对接底层硬件互操作（hardware interop），或集成 ML Kit 或 Media3 特效时使用。 |

### cars（1）


| skill | 中文介绍 |
|-------|---------|
| [`/android-for-cars-parked-apps`](./skills/android/cars/android-for-cars-parked-apps/SKILL.md) | 把现有 Android 视频流媒体应用、游戏和浏览器改造为可在 Android Auto 和 Android Automotive OS 上运行的 parked apps（驻车应用）。涵盖 manifest 配置、Google Play 硬件特性声明、兼容模式、返回导航、方向与显示连续性、可控系统栏 insets、异形挖孔屏、驾驶员分心生命周期处理、基于 CarUxRestrictions 的 MediaSession 播放限制。 |

### device-ai（5）


| skill | 中文介绍 |
|-------|---------|
| [`/appfunctions`](./skills/android/device-ai/appfunctions/SKILL.md) | 分析 Android 应用，发现可暴露为 AppFunctions 的用户工作流，如创建笔记、播放媒体或发送消息——AI agent、语音命令和系统快捷方式随后无需打开应用 UI 即可执行它们。使用 androidx.appfunctions 库生成 Kotlin 代码，并优化 KDoc 与应用描述，让 agent 能正确选择和调用函数。当需要发现、实现、文档化或测试 AppFunctions 时使用此 skill。 |
| [`/litert-lm`](./skills/android/device-ai/litert/litert-lm/SKILL.md) | 构建在设备端 CPU 或 GPU 上运行开放文本 LLM 的 Android 应用，使用 LiteRT-LM Kotlin API（com.google.ai.edge.litertlm:litertlm-android）。当用来自 Hugging Face litert-community 的 .litertlm 模型（Gemma、Qwen、Llama、Phi）创建聊天、摘要或提取功能时使用，包括 Gradle 依赖、GPU manifest 条目、模型文件落盘、Engine 初始化与推理循环。 |
| [`/litert-runtime`](./skills/android/device-ai/litert/litert-runtime/SKILL.md) | 使用 CompiledModel API 在 Android 上以 Kotlin 配置和实现 LiteRT（.tflite）设备端推理（CPU 与 GPU）。适用于任何 Android LiteRT 或 .tflite 任务，包括 Gradle 配置、图像分类或视觉/音频/embedding 辅助、TensorBuffer 复用、CPU 内存优化、Bitmap 预处理、AndroidViewModel 的 GPU 到 CPU 降级回退（单线程 dispatcher 上预热）以及 Google Play Services 中的 LiteRT。 |
| [`/ml-kit-genai-prompt-api`](./skills/android/device-ai/ml-kit-genai-prompt-api/SKILL.md) | 分析 Android 代码库以实现 ML Kit GenAI Prompt API。使用此 skill 在设备端向 Gemini Nano 发送自然语言请求、使用 Prompt API 的结构化输出、实现前缀缓存、优化当前提示词，或应用最佳实践。 |
| [`/mlkit-agent-api`](./skills/android/device-ai/mlkit-agent-api/SKILL.md) | 使用由 Gemini Nano 和 AICore 驱动的 ML Kit GenAI Agent API，在 Android 应用中构建自主的设备端 agentic 工作流。当实现会话式 agent、ViewModel 中基于 AgentSession 的多轮对话、通过 Android AppFunctions 的自主工具调用（@AppFunctionDeclaration 与 AppFunctionAgentTools.discover）、用 runner.runSingleTurnAsync 执行单次临时任务，或处理 GenAiException 时使用。 |

### devtools（1）


| skill | 中文介绍 |
|-------|---------|
| [`/android-cli`](./skills/android/devtools/android-cli/SKILL.md) | 提供安装和使用 `android` CLI 的说明。`android` 命令行工具是 Android 开发的关键工具，帮助你创建新 Android 项目、把 APK 安装到设备和模拟器并在其上启动运行应用、管理和交互 Android 虚拟设备（含截图和 UI 检查）、管理 Android SDK 组件、检查构建产物（APK、AAB、JAR、AAR）的构建与优化问题、查询官方 Android 文档，以及发现和安装官方 Android skills。 |

### identity（2）


| skill | 中文介绍 |
|-------|---------|
| [`/restore-credentials`](./skills/android/identity/restore-credentials/SKILL.md) | 提供使用 androidx.credentials 库实现 Android 恢复凭证（Restore Credentials）功能的知识与工作流。使用此 skill 创建恢复密钥、用其登录、删除恢复密钥，在设备恢复后实现新设备上的静默登录。涵盖版本兼容性、依赖、服务端前提条件，以及创建、读取、清除恢复密钥的完整客户端实现。 |
| [`/verified-email`](./skills/android/identity/verified-email/SKILL.md) | 提供基于 Android Credential Manager API 实现已验证邮箱获取的完整工作流。使用此 skill 向 Android 应用集成安全、免 OTP 的邮箱验证流程。该 skill 利用来自 Google 等可信提供商的加密验证凭证，解决注册流程摩擦过大的问题。 |

### jetpack-compose（5）


| skill | 中文介绍 |
|-------|---------|
| [`/adaptive`](./skills/android/jetpack-compose/adaptive/SKILL.md) | 提供让应用 UI 适配不同 Android 设备（手机、平板、折叠屏、笔记本、桌面、TV、Auto 和 XR）的说明。涵盖使用 Compose MediaQuery API 处理不同窗口尺寸、指针设备（如鼠标）和文本输入设备（如键盘），以及在配置变化（如折叠/展开、旋转、分屏）时保留 UI、导航、滚动和媒体播放状态。 |
| [`/ink-app-builder`](./skills/android/jetpack-compose/ink/ink-app-builder/SKILL.md) | 使用 Jetpack Ink（androidx.ink）和 Compose 为 Android 应用添加手写墨迹与自由绘制能力。当实现触控笔或触摸绘制表面、渲染湿墨/干墨笔画、配置内置笔刷（压感笔、马克笔、荧光笔）、实现基于几何的擦除、线性撤销重做历史，或用 Room 持久化笔画时使用。交付可直接运行的 Compose 与 ViewModel 实现。 |
| [`/ink-custom-brush-builder`](./skills/android/jetpack-compose/ink/ink-custom-brush-builder/SKILL.md) | 使用 Jetpack Ink（androidx.ink 1.1.0-alpha03 及以上）为 Android 应用创建自定义 BrushFamily 笔刷定义。当配置自定义 BrushTip 形状、用 BrushBehavior 节点图添加压感/倾斜/速度/噪声敏感度、创建多层涂层笔刷、应用平铺或粒子盖章纹理、配置 SlidingWindowModel 输入平滑，或序列化笔刷时使用。 |
| [`/jetpack-compose-performance`](./skills/android/jetpack-compose/jetpack-compose-performance/SKILL.md) | 诊断并优化 Android Jetpack Compose UI 代码。当分析现有代码的性能瓶颈，以减少重组（recomposition）开销、防止掉帧和 UI 卡顿时使用。 |
| [`/migrate-xml-views-to-jetpack-compose`](./skills/android/jetpack-compose/migration/migrate-xml-views-to-jetpack-compose/SKILL.md) | 提供将 Android XML View 迁移到 Jetpack Compose 的结构化工作流。该 skill 详述从规划和依赖设置，到主题和布局迁移、验证及 XML 清理的分步流程。当需要在 Android 项目中把 XML View 迁移到 Jetpack Compose 时使用。它解决将旧版 XML View 的 UI 转换为现代声明式 Compose 组件、同时保持互操作性的问题。 |

### media（1）


| skill | 中文介绍 |
|-------|---------|
| [`/media3-cast-integration`](./skills/android/media/media3-cast-integration/SKILL.md) | 使用 Jetpack Media3 在 Android 应用中实现 Google Cast 支持。处理添加构建依赖、更新 manifest、配置 OptionsProvider，以及在 Compose 和 View 两种 UI 中管理 CastPlayer 或 RemoteCastPlayer 播放。当添加 Cast 功能或从旧版 Cast SDK 迁移到 Media3 Cast 时使用。 |

### migration（1）


| skill | 中文介绍 |
|-------|---------|
| [`/ios-to-android`](./skills/android/migration/ios-to-android/SKILL.md) | 用于任何从 iOS/Swift 代码库移植或实现 Android 功能的任务——包括单特性任务（BLE 扫描、定位/GPS 追踪、支付、Health Connect、后台任务、数据库、单个页面），而不仅是整应用迁移。是把 iOS 应用与子系统迁移到 Android（Jetpack Compose、Room、Kotlin Coroutines 与 Flow、Architecture Components）的主协调 skill。 |

### navigation（2）


| skill | 中文介绍 |
|-------|---------|
| [`/navigation-3`](./skills/android/navigation/navigation-3/SKILL.md) | 学习如何安装并迁移到 Jetpack Navigation 3，以及如何实现 deep links、多个 backstack、scenes（对话框、底部表、list-detail、two-pane、supporting pane）、条件导航（如已登录导航与匿名导航的区别）、从流程返回结果、与 Hilt/ViewModel/Kotlin/View 互操作集成等功能和模式。 |
| [`/navigation-event`](./skills/android/navigation/navigation-event/SKILL.md) | 在 Compose Android 中使用 NavigationEvent（androidx.navigationevent）库拦截返回手势并运行预测性返回（Predictive Back）动画。处理 Activity 配置、`ViewPagers` 或标签页中的父子分发器作用域、Compose `NavigationBackHandler`，以及 SDK 36+ 上从旧版 `BackHandler` 的迁移。 |

### performance（2）


| skill | 中文介绍 |
|-------|---------|
| [`/anr-audit-and-fix`](./skills/android/performance/anr-audit-and-fix/SKILL.md) | 审计 Android 代码库中的 ANR（应用无响应）风险并诊断 ANR 堆栈转储。当扫描 Android 代码查找 ANR 风险或分诊 ANR 堆栈转储时使用。不要用于非 ANR 崩溃、掉帧、一般 CPU 剖析或 Perfetto 系统 trace。 |
| [`/r8-analyzer`](./skills/android/performance/r8-analyzer/SKILL.md) | 分析 Android 构建文件和 R8 keep 规则，识别冗余、过宽的包级规则，以及吞没了库消费者 keep 规则的规则。当开发者想优化 Android 应用体积、移除冗余或过宽的 keep 规则，或排查 ProGuard 配置时使用。不要用于一般 Gradle 构建错误、Compose UI 性能或运行时 CPU 剖析。 |

### play（3）


| skill | 中文介绍 |
|-------|---------|
| [`/engage-sdk-integration`](./skills/android/play/engage-sdk-integration/SKILL.md) | 帮助开发者集成、调试和解决 Play Engage SDK 实现问题。当添加 Engage SDK 支持、生成发布代码、将数据类映射到实体，或修复 SDK 相关错误时使用。 |
| [`/play-billing-library-version-upgrade`](./skills/android/play/play-billing-library-version-upgrade/SKILL.md) | 当从任意旧版 Google Play Billing Library (PBL) 升级或迁移 Android 项目到最新稳定版 PBL 时使用此 skill。 |
| [`/play-policy-insights`](./skills/android/play/play-policy-insights/SKILL.md) | 自动化审计器，用于对照 Google Play 政策域验证 Android 应用。它将静态代码分析与 Play Store 声明交叉核对，生成确定性的合规报告，在权限与 API 卫生（Permissions and APIs Hygiene）、用户账号与身份（User Account and Identity）、数据安全与隐私（Data Safety and Privacy）三个域中识别未声明的数据收集、架构风险和缺失披露。 |

### profilers（1）


| skill | 中文介绍 |
|-------|---------|
| [`/android-profiler`](./skills/android/profilers/android-profiler/SKILL.md) | 记录并分析 Android 性能数据，诊断用户应用、系统应用和系统服务的性能瓶颈——即使用户没有明确提到 profiling 或 traces。适用场景：录制系统 trace、CPU 调用栈、Vulkan GPU/DRM 内存或 Java/native 堆剖析；分析 Perfetto trace 定位 UI 卡顿、掉帧、ANR 或应用启动延迟问题；排查 CPU 瓶颈、IPC/Binder 链路问题。 |

### security（2）


| skill | 中文介绍 |
|-------|---------|
| [`/android-intent-security`](./skills/android/security/android-intent-security/SKILL.md) | 审计、发现并修复 Android Intent 与组件安全漏洞。当审计 AndroidManifest.xml 中的组件配置（activities、services、receivers）或处理传入 Intent 的源码（getIntent、getParcelableExtra）以防止 Intent 重定向（Intent Redirection）和未授权访问时使用。不要用于网络安全、TLS 配置或一般运行时权限请求流程。 |
| [`/android-permissions-security`](./skills/android/security/android-permissions-security/SKILL.md) | 审计、发现缺口并修复 Android 权限与 IPC 组件安全漏洞。当审查 AndroidManifest.xml、定义权限、暴露组件（activity/service/receiver/provider）或加固 IPC 攻击面时使用。 |

### system（3）


| skill | 中文介绍 |
|-------|---------|
| [`/edge-to-edge`](./skills/android/system/edge-to-edge/SKILL.md) | 使用此 skill 迁移 Jetpack Compose 应用以添加自适应 edge-to-edge 支持，并排查常见问题。用于修复被导航栏或状态栏遮挡/重叠的 UI 组件（如按钮或列表）、修复 IME insets、以及修复系统栏可读性。 |
| [`/glance-appwidget-updates-and-memory`](./skills/android/system/glance-appwidget-updates-and-memory/SKILL.md) | 使用 Jetpack Glance（androidx.glance:glance-appwidget）和 Android 17（API 37）上的 AppWidgetProvider receiver，管理 Android AppWidget 的状态更新、后台同步与 RemoteViews 位图内存上限。当配置 Android 17（API level 37）的 compileSdk/targetSdk 与 AndroidManifest.xml widget receiver、在 CoroutineWorker 更新 DataStore 偏好后刷新冻结或过期的 Glance widget UI 时使用。 |
| [`/glance-canonical-layouts`](./skills/android/system/glance-canonical-layouts/SKILL.md) | 使用来自 Android Platform Samples 项目的 Jetpack Glance Canonical Layouts 创建主屏幕小组件；或当被要求实现标准 widget 布局模式（Check List、Image Grid、Snap Scrolling、Standard Toolbar）时使用。 |

### testing（1）


| skill | 中文介绍 |
|-------|---------|
| [`/testing-setup`](./skills/android/testing/testing-setup/SKILL.md) | 为 Android 应用分析并制定测试策略——安装测试库、搭建测试基础设施、创建测试桩。 |

### tv（1）


| skill | 中文介绍 |
|-------|---------|
| [`/leanback-to-compose-tv-migration`](./skills/android/tv/leanback-to-compose-tv-migration/SKILL.md) | 提供把 Android TV 应用从旧版 Leanback UI Toolkit、Android Views 或 Support Fragments 迁移到 Jetpack Compose for TV（androidx.tv）的说明与架构模式。用于 Leanback 到 Compose 的迁移，包括浏览页、设置页、认证页、登录页或视频播放页迁移，或用现代 Compose 等价物替换 BrowseSupportFragment、LeanbackSettingsFragment、PreferenceFragment、VideoSupportFragment、GuidedStepSupportFragment、SearchSupportFragment、VerticalGridSupportFragment、Presenter、ArrayObjectAdapter、CursorMapper 等，实现带焦点记忆的沉浸式轮播、使用 PlayerSurface 的 Media3 视频播放，或自定义 10 英尺 hero 布局。 |

### wear（2）


| skill | 中文介绍 |
|-------|---------|
| [`/wear-compose-m3`](./skills/android/wear/wear-compose-m3/SKILL.md) | 使用 Wear OS Compose Material3 的专家指导。当创建、更新或迁移 Wear OS 项目时使用。涵盖 androidx.wear.compose.material3、androidx.wear.compose.foundation 和 androidx.wear.compose.navigation3 库，AppScaffold、ScreenScaffold、TransformingLazyColumn 等核心组件，以及 ambient mode 等 Wear OS 核心概念。含从早期版本（如 Material 2.5 和 Horologist）的迁移。 |
| [`/wear-widgets`](./skills/android/wear/wear-widgets/SKILL.md) | 在 Android 项目中使用 Glance Wear 和 Remote Compose 创建、迁移、更新和验证 Wear OS 小组件。当实现 GlanceWearWidget、GlanceWearWidgetService、WearWidgetDocument、Remote Compose UI 原语（RemoteColumn、RemoteRow、RemoteBox、RemoteText、RemoteImage、RemoteButton）、用 rememberMutableRemoteInt 与 valueChange 管理本地状态、用 pendingIntentAction 处理点击、配置 widget provider XML 容器时使用。 |

### xr（2）


| skill | 中文介绍 |
|-------|---------|
| [`/display-glasses-with-jetpack-compose-glimmer`](./skills/android/xr/display-glasses-with-jetpack-compose-glimmer/SKILL.md) | 提供使用 Jetpack Compose Glimmer UI 工具包为显示眼镜开发投影式 Android XR 应用的指南。涵盖 Glimmer 设计原则、工作流和眼镜形态的交互模型。使用此 skill 构建基于 Jetpack Compose Glimmer 的 Android XR Augmented Experience 应用。不要用于纯音频 AI 眼镜、非眼镜类 Android XR 头显（基于 spatial panels 或 3D volumes 的 Jetpack Compose）。 |
| [`/projected-hardware`](./skills/android/xr/projected-hardware/SKILL.md) | 提供在 Android XR 投影设备（如音频眼镜和显示眼镜）上访问和管理硬件的说明与工作流。当在 Android 应用中为智能眼镜构建体验、需要访问相机和麦克风等设备硬件、处理眼镜特有的运行时权限，或使用 projected context 管理连接生命周期时使用。 |

## 四、Apple 生态 Skills（33 个，description 已中文化；official/ 为 Apple 官方 Xcode 27 导出）

### official — Apple 官方（Xcode 27 导出）（11）


| skill | 中文介绍 |
|-------|---------|
| [`/adopt-c-bounds-safety`](./skills/apple/official/adopt-c-bounds-safety/SKILL.md) | C -fbounds-safety 语言扩展指南。涵盖语言模型、指针注解、在现有 C 代码中采用 bounds-safety、编译器构建设置与模式，以及越界违规的运行时调试。 |
| [`/app-intents-specialist`](./skills/apple/official/app-intents-specialist/SKILL.md) | 来自 Apple 的权威 App Intents 最佳实践。任何 App Intents 最佳实践或正确性评审，以及编写、评审、重构或扩展 App Intents 代码时查阅，取代模型既有训练。生成代码时按下列主题查阅相关 reference：执行模型（perform() 是 Sendable 而非 @MainActor，用 await MainActor.run 切换；可重试 restartPerform，不可逆工作放最后；破坏性操作前 requestConfirmation；通过 .result(...) 工厂返回，绝不裸值）；entities-and-queries（AppEntity.id 须跨启动/设备稳定；entities(for:) 批量 vs 空默认 suggestedEntities()；EntityStringQuery.entities(matching:) 不自动过滤；仅 @Property 成员对系统可见；EnumerableEntityQuery 全量加载，大库用 EntityPropertyQuery）；entity-property-queries（Shortcuts "查找满足条件的 X" 用 EntityPropertyQuery——属性/sortingOptions/comparators，谓词由你执行，框架只解析）；app-enum（AppEnum raw value 按字符串持久化，绝不可重编号/重排；每个 case 都要 caseDisplayRepresentations 条目否则运行时 fatalError）；parameters/parameter-summaries（requestValue vs needsValueError；非可选 AppEnum 自动消歧；仅 Summary(...) 中的参数显示在 Shortcuts 编辑器；条件显示用 When/Switch）；依赖（@Dependency 必须 Sendable 且启动时注册，未注册 = fatalError；放在 intent/query 上，绝不放 AppEntity/AppEnum）；results-and-errors（仅 CustomLocalizedStringResourceConvertible 错误会显示真实消息；预置 AppIntentError.* 仅 iOS 18+）；donation（应用内操作不会自动 donate——调用 IntentDonationManager.shared.donate；PredictableIntent 仅用于描述）；本地化（面向用户的字符串必须是字面量 LocalizedStringResource，运行期 String 产生不了可提取的 key）；app-shortcut-phrases（提供 shortTitle/systemImageName；包含 \(\.applicationName) 否则运行时索引静默丢弃短语）；url-representation（OpenIntent/OpenURLIntent/URLRepresentableEntity 用于打开与通用链接）；configuration-intents（WidgetConfigurationIntent/ControlConfigurationIntent 仅参数化——无 perform()）；拆分（AppEnum 固定集合 vs AppEntity+query 动态 vs 纯 @Parameter；一个 intent 一个原子任务）。iOS 26/27 新 API 采用请改用 app-intents-whats-new-27 skill。 |
| [`/app-intents-whats-new-27`](./skills/apple/official/app-intents-whats-new-27/SKILL.md) | iOS 26（2025）与 iOS 27（2026）版本（及其 macOS/watchOS/tvOS/visionOS 同胞）引入的 App Intents 新 API、行为与废弃项。当采用、迁移或被问及以下内容时使用：用 supportedModes / IntentModes（.background/.foreground）声明 intent 运行位置或迁移废弃的 openAppWhenRun；用 continueInForeground / needsToContinueInForegroundError 把后台运行拉到前台；UndoableIntent；用 requestChoice / IntentChoiceOption 让用户在 perform 中途从少量选项中选择；用 CancellableIntent / IntentCancellationReason 取消；用 LongRunningIntent / performBackgroundTask 长时间或后台工作；用 IntentExecutionTargets / allowedExecutionTargets 限制 intent 运行位置；用 SnippetIntent 和 Button(intent:) 返回交互式片段；用 IntentValueQuery + SemanticContentDescriptor（import VisualIntelligence）+ @UnionValue 做 Visual Intelligence 相机/屏上搜索；用 appEntityIdentifier 关联屏上内容与 entity；用 @Property / @ComputedProperty / @DeferredProperty(indexingKey:) 把 entity 值映射进 Spotlight；用 IndexedEntityQuery 做系统驱动的 Spotlight 重建索引；用 relatedAppEntityIdentifier 把 CSSearchableItem 链接到 entity；用 RelevantEntities + AppEntityContext 主动呈现 entity；用 SyncableEntity / SyncableEntityIdentifier 与 EntityOwnership / OwnershipProvidingEntity 做跨设备 entity；@ComputedProperty / @DeferredProperty 便捷属性；用 SystemShortcut / RunSystemShortcutIntent 运行系统快捷方式；用 EntityCollection 廉价传递大 entity 集；用 @AppIntent(schema:) / @AppEntity(schema:) / @AppEnum(schema:) 采用 Apple Intelligence schema（迁移废弃的 @AssistantIntent）；用 AppIntentsTesting 做单元测试；或询问"iOS 26 / iOS 27 的 App Intents 有什么新东西"。永续（非版本相关）的 App Intents 最佳实践请改用 app-intents-specialist skill。 |
| [`/app-resizability`](./skills/apple/official/app-resizability/SKILL.md) | 当应用布局必须适应运行中变化的窗口尺寸，或应用需支持多窗口时使用。包括被要求让应用可调大小或支持可调整窗口、布局在窗口缩放时破损或不适配，以及为可折叠 iPhone Duo、分屏多任务或 Stage Manager 做准备与优化。通过用符合上下文的替代方案替换旧式共享状态 API（mainScreen、interfaceOrientation、userInterfaceIdiom、application/scene 生命周期、safe area insets）来现代化应用。 |
| [`/audit-xcode-security-settings`](./skills/apple/official/audit-xcode-security-settings/SKILL.md) | 审计并启用面向安全的 Xcode 构建设置。渐进启用编译器警告、静态分析器检查器和 Enhanced Security 特性。适用：加固 Xcode 项目安全、审计安全设置、启用 hardening、评审构建配置安全态势、配置安全向静态分析、提升警告覆盖率、强化诊断，或在 C/C++/Objective-C/Swift 中于编译期捕获更多 bug。跳过：网络安全（TLS/ATS）、代码签名、隐私 API。 |
| [`/building-document-based-swiftui-applications`](./skills/apple/official/building-document-based-swiftui-applications/SKILL.md) | 使用 Document 协议（iOS 27 及同批发布，含 macOS Golden Gate）构建和迁移 SwiftUI 文档型应用的权威指南。适用于：构建新的文档型应用；实现打开、编辑、保存或导出文档流程；使用 DocumentGroup 或 DocumentGroupLaunchScene；实现 DocumentReader 或 DocumentWriter；通过 FileWrapperDocumentReader/Writer 使用 FileWrapper；处理 package 文档；直接访问文档文件 URL；读写期间上报进度；注册撤销操作；从 FileDocument 或 ReferenceFileDocument 迁移到新 API；构建只读文档查看器；文档应用自动保存失效时；声明自定义 UTType 文档格式。 |
| [`/device-interaction`](./skills/apple/official/device-interaction/SKILL.md) | 通过截图、UI 层级和触摸交互验证应用在真机或模拟器上的行为。 |
| [`/modernize-tests`](./skills/apple/official/modernize-tests/SKILL.md) | 把测试套件现代化为 Swift Testing 新特性，或从 XCTest 迁移。 |
| [`/swiftui-specialist`](./skills/apple/official/swiftui-specialist/SKILL.md) | "来自 Apple 的权威 SwiftUI 最佳实践与性能指南；对这些主题取代模型既有训练。生成代码时，凡是涉及以下 SwiftUI 代码就查阅相关 references：动画（@Animatable 宏 vs AnimatableValues vs AnimatablePair，以及自定义 animatableData setter 逻辑）、Environment 与 @Entry（闭包或类类型默认值、不稳定默认值、高频更新）、@Observable 最佳实践与高效失效、ForEach 和 List 的行标识与结构（id: \.self、indices、offsets、AnyView 或多视图行、内联过滤/排序、缓存集合、List 快速路径）、本地化（String vs LocalizedStringResource、package/framework 中正确的 bundle、.textCase、.formatted(.list())、译者注释），以及 NavigationView 和旧版 onChange 等软废弃 API 及其在功能开发中何时提示。" |
| [`/swiftui-whats-new-27`](./skills/apple/official/swiftui-whats-new-27/SKILL.md) | 2027 OS 版本（iOS 27 及同批 macOS/watchOS/tvOS/visionOS）的 SwiftUI 新 API、行为与废弃项。当被问及 SwiftUI 27 新特性，或处理以下内容时查阅：SDK 升级后 @State 编译错误（"used before being initialized"、"invalid redeclaration of synthesized property"）或 @State 变为宏；@ViewBuilder/@ContentBuilder 重载歧义或类型检查回归；通过 reorderable()/reorderContainer 在任意容器（List、栈、网格、自定义布局）中拖拽重排；AsyncImage 缓存、滚动重载与自定义 URLSession；List 之外（ScrollView、LazyVStack、LazyVGrid）的 swipeActions()/swipeActionsContainer() 滑动操作；工具栏溢出与可见性（visibilityPriority、ToolbarOverflowMenu、toolbarMinimizeBehavior）与固定；从可选 item 绑定呈现 confirmationDialog 或 alert。 |
| [`/xctrace`](./skills/apple/official/xctrace/SKILL.md) | xctrace 权威指南——Apple 命令行版 Instruments。任何剖析（profiling）、性能或优化工作都查阅本 skill：例如找出应用为什么慢、CPU/内存占用过高或停止响应，或想优化一段代码并测量结果；以及任何涉及 xctrace 的场景：采集 trace，或从命令行打开读取 .trace 与 .atrc（Apple Trace）文件。 |

### ios — iOS 开发（OpenAI build-ios-apps）（9）


| skill | 中文介绍 |
|-------|---------|
| [`/ios-app-intents`](./skills/apple/ios/ios-app-intents/SKILL.md) | 为 iOS 系统界面设计 App Intents、app entity 和 App Shortcuts。当需要把应用操作或内容暴露给 Shortcuts、Siri、Spotlight、小组件或控制中心时使用。 |
| [`/ios-debugger-agent`](./skills/apple/ios/ios-debugger-agent/SKILL.md) | 使用 XcodeBuildMCP 在模拟器上构建、运行和调试 iOS 应用。当需要启动应用、检查模拟器 UI 或日志，或诊断运行时行为时使用。 |
| [`/ios-ettrace-performance`](./skills/apple/ios/ios-ettrace-performance/SKILL.md) | 采集并解读 iOS Simulator 的 ETTrace 剖析。当需要分析启动或运行时延迟、对比 trace、或找出 CPU 热点栈时使用。 |
| [`/ios-memgraph-leaks`](./skills/apple/ios/ios-memgraph-leaks/SKILL.md) | 采集并检查 iOS 泄漏与 memgraph。当调试泄漏对象、保留环（retain cycle）、内存增长，或做泄漏前后证据对比时使用。 |
| [`/ios-simulator-browser`](./skills/apple/ios/ios-simulator-browser/SKILL.md) | 把 iOS Simulator 镜像到 Codex 内置浏览器，并通过可导入的 Swift 包在该模拟器中渲染 SwiftUI 预览（支持热重载）。当用户想观看或交互 iOS 应用的实时预览时使用。 |
| [`/swiftui-liquid-glass`](./skills/apple/ios/swiftui-liquid-glass/SKILL.md) | 实现和评审 iOS 26+ 的 SwiftUI Liquid Glass UI。当采用 Liquid Glass，或检查其正确性、性能与设计契合度时使用。 |
| [`/swiftui-performance-audit`](./skills/apple/ios/swiftui-performance-audit/SKILL.md) | 从代码层面优先审计 SwiftUI 运行时性能。当诊断渲染缓慢、滚动卡顿、昂贵更新或需要剖析时使用。 |
| [`/swiftui-ui-patterns`](./skills/apple/ios/swiftui-ui-patterns/SKILL.md) | 用组件模式和示例构建并重构 SwiftUI UI。当设计导航、状态、布局、控件或页面组合时使用。 |
| [`/swiftui-view-refactor`](./skills/apple/ios/swiftui-view-refactor/SKILL.md) | 把 SwiftUI 视图文件重构为稳定、可测试的结构。当拆分大视图、收紧数据流，或清理 Observation 所有权时使用。 |

### macos — macOS 开发（OpenAI build-macos-apps）（11）


| skill | 中文介绍 |
|-------|---------|
| [`/appkit-interop`](./skills/apple/macos/appkit-interop/SKILL.md) | 把 macOS SwiftUI 窄桥接到 AppKit。当实现 representable、访问 NSWindow 或 panel、处理菜单，或使用 responder chain 时使用。 |
| [`/build-run-debug`](./skills/apple/macos/build-run-debug/SKILL.md) | 用 shell 优先的 Xcode 与 Swift 工作流构建、运行和调试 macOS 应用。当启动应用或诊断构建、启动、运行时故障时使用。 |
| [`/liquid-glass`](./skills/apple/macos/liquid-glass/SKILL.md) | 实现和评审 macOS SwiftUI Liquid Glass UI。当采用系统玻璃效果、移除冲突的自定义 chrome，或构建玻璃表面时使用。 |
| [`/packaging-notarization`](./skills/apple/macos/packaging-notarization/SKILL.md) | 准备 macOS 打包与公证（notarization）工作流。当归档应用、校验 bundle，或解释仅分发阶段的失败时使用。 |
| [`/signing-entitlements`](./skills/apple/macos/signing-entitlements/SKILL.md) | 检查 macOS 签名、entitlements 与 Gatekeeper 问题。当诊断代码签名、沙盒、hardened runtime 或信任失败时使用。 |
| [`/swiftpm-macos`](./skills/apple/macos/swiftpm-macos/SKILL.md) | 构建、运行和测试 SwiftPM macOS 包与可执行文件。当仓库是 package-first 或没有 Xcode 工程时使用。 |
| [`/swiftui-patterns`](./skills/apple/macos/swiftui-patterns/SKILL.md) | 用桌面模式构建 macOS SwiftUI scene 与组件。当设计窗口、命令、工具栏、设置、split view 或 inspector 时使用。 |
| [`/telemetry`](./skills/apple/macos/telemetry/SKILL.md) | 添加并验证轻量 macOS 运行时遥测。当接入 Logger 事件，或检查窗口、侧栏、菜单和操作的日志时使用。 |
| [`/test-triage`](./skills/apple/macos/test-triage/SKILL.md) | 在 Xcode 与 SwiftPM 间分诊 macOS 测试。当缩小失败范围、解释断言或崩溃，或区分环境问题与回归时使用。 |
| [`/view-refactor`](./skills/apple/macos/view-refactor/SKILL.md) | 把 macOS SwiftUI 视图与 scene 重构为稳定结构。当拆分大视图、收紧 scene 状态，或减少 AppKit 逃逸时使用。 |
| [`/window-management`](./skills/apple/macos/window-management/SKILL.md) | 定制 macOS SwiftUI 窗口与 scene 行为。当调优窗口 chrome、拖拽区域、位置、恢复、启动行为或无边框窗口时使用。 |

### swiftui — SwiftUI 跨平台（twostraws）（1）


| skill | 中文介绍 |
|-------|---------|
| [`/swiftui-pro`](./skills/apple/swiftui/swiftui-pro/SKILL.md) | 全面评审 SwiftUI 代码的现代 API 使用、可维护性与性能最佳实践。当阅读、编写或评审 SwiftUI 项目时使用。 |

### swift — Swift 语言级（AvdLee）（1）


| skill | 中文介绍 |
|-------|---------|
| [`/swift-concurrency`](./skills/apple/swift/swift-concurrency/SKILL.md) | 诊断 Swift Concurrency 问题、把基于回调的代码重构为 async/await，并在处理 Task、Actor、@MainActor、Sendable、数据竞争、线程安全或并发架构时指导 Swift 6 迁移。 |

## 五、安装指导 Skills（3 个）

| skill | 中文介绍 |
|-------|---------|
| [`/install-android-skills`](./skills/meta/install-android-skills/SKILL.md) | 介绍 Android agent skills 并指导安装。当用户想获取 Android 开发技能、询问 Android skills 怎么装、或提到 Jetpack Compose/CameraX/AGP/Perfetto/R8/Play Billing/Wear OS/Android XR 等 Android 开发场景时使用。涵盖官方 `android` CLI 安装、`android skills add` 用法、以及本仓库中文化版的获取途径。 |
| [`/install-apple-skills`](./skills/meta/install-apple-skills/SKILL.md) | 介绍 Apple 生态（iOS/macOS/Swift/SwiftUI）的 agent skills 并指导安装。当用户想获取 Apple/Xcode 开发技能、询问 iOS/macOS/SwiftUI/Swift skills 怎么装、提到 WWDC26 session 269、Apple 官方 skill 导出（xcrun agent skills export）、OpenAI build-ios-apps / build-macos-apps 插件，或要做 iOS/Swift 开发时使用。涵盖 Apple 官方导出、三个 GitHub 上游、以及本仓库中文化版的获取途径。 |
| [`/install-harmonyos-skills`](./skills/meta/install-harmonyos-skills/SKILL.md) | 介绍 HarmonyOS（鸿蒙）agent skills 并指导安装。当用户想获取鸿蒙开发技能、询问 HarmonyOS/OpenHarmony/ArkTS/ArkUI/DevEco skills 怎么装、或提到鸿蒙应用开发、多设备适配、稳定性分析等场景时使用。涵盖上游来源、官方安装方式、以及本仓库中文化版的获取途径。 |

## 致谢与许可

本仓库整合自以下上游，在此致谢并保留其版权声明：

- **mattpocock/skills**（MIT）— Copyright (c) 2026 Matt Pocock。MIT 许可证要求保留版权声明，全文见上游 [LICENSE](https://github.com/mattpocock/skills/blob/main/LICENSE)。
- **android/skills**（Apache License 2.0）— Copyright Google LLC。详见上游 [LICENSE](https://github.com/android/skills/blob/main/LICENSE.txt)。
- **HarmonyOS_Skills/harmonyos-agent-skills** — 遵循其原有许可声明。

本仓库整体采用 GPL v3 许可证（见 [LICENSE](./LICENSE)）。中文翻译与整合工作为 KenKenSkills 项目的贡献。

## 维护

如需同步上游更新或新增其他优秀 skills 仓库，请参见 [MAINTENANCE.md](./MAINTENANCE.md)。
