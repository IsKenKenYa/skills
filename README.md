# KenKenSkills

> 收集好用的 agent skills，把介绍（description）本地化为简体中文，统一管理、方便更新。

本仓库是 [mattpocock/skills](https://github.com/mattpocock/skills) 的中文化镜像：完整保留原作者的全部 skill 内容，只把每个 skill 的 `description`（即加载器和用户最先看到的那句介绍）翻译成中文，方便中文用户快速理解每个 skill 是干嘛的、何时该用。

## 安装

```bash
npx skills@latest add IsKenKenYa/skills
```

然后挑选你想要的 skill 和目标编码代理即可。

## 设计原则

- **只翻译 `description`**：frontmatter 里的 `name`、`disable-model-invocation`、`argument-hint` 等字段，以及正文全部指令，**一律保持英文原样**。这样既不改变 skill 的语义，也不破坏 AI 执行时的指令完整性。
- **触发词保留原型**：`grill`、`tdd`、`triage`、`shoehorn`、`Husky`、`Obsidian` 等关键词不翻译，必要时加中文括注，保证技能名和触发短语可被正确识别。
- **镜像上游结构**：`skills/` 下的分类与目录与上游一一对应，方便对照和同步更新。
- **上游引用隔离**：原版英文仓库作为 git submodule 放在独立的 `upstream-refs` 分支，主分支保持干净——`npx skills add` 只会扫到中文化版本，不会被英文原版污染。

调用方式说明：标记为「用户调用」的 skill 只能用 `/skill名` 手动触发；「模型/用户调用」的 skill 还能被模型根据上下文语义自动触发。

## Skill 清单（共 34 个）

### Engineering — 工程类（14）

*日常编码工作*

| skill | 调用方式 | 中文介绍 |
|-------|---------|---------|
| [`/ask-matt`](./skills/engineering/ask-matt/SKILL.md) | 用户调用 | 询问哪种 skill 或流程适合你的场景。是本仓库中用户调用类 skill 的路由器。 |
| [`/codebase-design`](./skills/engineering/codebase-design/SKILL.md) | 模型/用户调用 | 设计深层模块（deep module）的共享词汇。当用户想设计或改进模块接口、寻找深化机会、决定接缝（seam）位置、让代码更易测试或更易被 AI 导航，或当其他 skill 需要深层模块词汇时使用。 |
| [`/diagnosing-bugs`](./skills/engineering/diagnosing-bugs/SKILL.md) | 模型/用户调用 | 针对疑难 bug 和性能回归的诊断循环。当用户说"诊断"/"调试这个"，或报告某东西坏了/抛异常/失败/变慢时使用。 |
| [`/domain-modeling`](./skills/engineering/domain-modeling/SKILL.md) | 模型/用户调用 | 构建并打磨项目的领域模型。当用户想敲定领域术语或统一语言、记录架构决策（ADR），或当其他 skill 需要维护领域模型时使用。 |
| [`/grill-with-docs`](./skills/engineering/grill-with-docs/SKILL.md) | 用户调用 | 一场无情的访谈，用来打磨计划或设计，同时会顺势产出文档（ADR 和术语表）。 |
| [`/implement`](./skills/engineering/implement/SKILL.md) | 用户调用 | 基于 PRD 或一组 issue 实现一项工作。 |
| [`/improve-codebase-architecture`](./skills/engineering/improve-codebase-architecture/SKILL.md) | 用户调用 | 扫描代码库寻找深化机会，以可视化 HTML 报告呈现，然后针对你选中的那一个进行 grill 访谈。 |
| [`/prototype`](./skills/engineering/prototype/SKILL.md) | 用户调用 | 构建一次性原型来充实设计——针对状态/业务逻辑问题做一个可运行的终端应用，或做几套截然不同、可从同一路由切换的 UI 变体。 |
| [`/resolving-merge-conflicts`](./skills/engineering/resolving-merge-conflicts/SKILL.md) | 模型/用户调用 | 当你需要解决进行中的 git merge/rebase 冲突时使用。 |
| [`/setup-matt-pocock-skills`](./skills/engineering/setup-matt-pocock-skills/SKILL.md) | 用户调用 | 为工程类 skill 配置本仓库——设置 issue 追踪器、triage 标签词汇和领域文档布局。在其他工程类 skill 首次使用前运行一次。 |
| [`/tdd`](./skills/engineering/tdd/SKILL.md) | 模型/用户调用 | 测试驱动开发（TDD）。当用户想以测试优先的方式构建功能或修 bug、提到"red-green-refactor"，或想要集成测试时使用。 |
| [`/to-issues`](./skills/engineering/to-issues/SKILL.md) | 用户调用 | 用示踪子弹（tracer-bullet）垂直切片，把计划、规格说明或 PRD 拆解为项目 issue 追踪器上可独立认领的 issue。 |
| [`/to-prd`](./skills/engineering/to-prd/SKILL.md) | 用户调用 | 把当前对话转化为 PRD 并发布到项目 issue 追踪器——无需访谈，只是对已讨论内容的综合提炼。 |
| [`/triage`](./skills/engineering/triage/SKILL.md) | 用户调用 | 让 issue 和外部 PR 经过一组 triage 角色的状态机——分类、验证、必要时 grill 访谈，并撰写代理可直接执行的简报（brief）。 |

### Productivity — 生产力类（5）

*日常非编码工作流工具*

| skill | 调用方式 | 中文介绍 |
|-------|---------|---------|
| [`/grill-me`](./skills/productivity/grill-me/SKILL.md) | 用户调用 | 一场无情的访谈，用来打磨计划或设计。 |
| [`/grilling`](./skills/productivity/grilling/SKILL.md) | 模型/用户调用 | 就一个计划或设计对用户进行无情的访谈。当用户想在动手构建前压力测试一个计划，或使用任何 'grill' 触发短语时使用。 |
| [`/handoff`](./skills/productivity/handoff/SKILL.md) | 用户调用 | 把当前对话压缩成一份交接（handoff）文档，供另一个代理接手。 |
| [`/teach`](./skills/productivity/teach/SKILL.md) | 用户调用 | 在当前工作区内，教会用户一项新 skill 或概念。 |
| [`/writing-great-skills`](./skills/productivity/writing-great-skills/SKILL.md) | 用户调用 | 写好和编辑好 skill 的参考——让 skill 行为可预测所需的词汇与原则。 |

### Misc — 杂项（4）

*保留但较少使用*

| skill | 调用方式 | 中文介绍 |
|-------|---------|---------|
| [`/git-guardrails-claude-code`](./skills/misc/git-guardrails-claude-code/SKILL.md) | 模型/用户调用 | 设置 Claude Code 钩子，在危险的 git 命令（push、reset --hard、clean、branch -D 等）执行前拦截。当用户想防止破坏性 git 操作、添加 git 安全钩子，或在 Claude Code 中阻止 git push/reset 时使用。 |
| [`/migrate-to-shoehorn`](./skills/misc/migrate-to-shoehorn/SKILL.md) | 模型/用户调用 | 把测试文件从 `as` 类型断言迁移到 @total-typescript/shoehorn。当用户提到 shoehorn、想替换测试里的 `as`，或需要部分测试数据时使用。 |
| [`/scaffold-exercises`](./skills/misc/scaffold-exercises/SKILL.md) | 模型/用户调用 | 创建带章节、题目、解答和讲解的练习目录结构，且能通过 lint。当用户想脚手架化练习、创建练习桩，或搭建新课程章节时使用。 |
| [`/setup-pre-commit`](./skills/misc/setup-pre-commit/SKILL.md) | 模型/用户调用 | 在当前仓库设置带 lint-staged（Prettier）、类型检查和测试的 Husky pre-commit 钩子。当用户想添加 pre-commit 钩子、设置 Husky、配置 lint-staged，或在提交时加入格式化/类型检查/测试时使用。 |

### Personal — 个人专用（2）

*与原作者个人设置绑定*

| skill | 调用方式 | 中文介绍 |
|-------|---------|---------|
| [`/edit-article`](./skills/personal/edit-article/SKILL.md) | 用户调用 | 通过重组章节、提升清晰度、收紧文字来编辑和改进文章。当用户想编辑、修订或改进一篇文章草稿时使用。 |
| [`/obsidian-vault`](./skills/personal/obsidian-vault/SKILL.md) | 模型/用户调用 | 用 wikilinks 和索引笔记在 Obsidian 知识库中搜索、创建和管理笔记。当用户想在 Obsidian 中查找、创建或组织笔记时使用。 |

### In-progress — 进行中（5）

*尚未定稿的草稿*

| skill | 调用方式 | 中文介绍 |
|-------|---------|---------|
| [`/decision-mapping`](./skills/in-progress/decision-mapping/SKILL.md) | 用户调用 | 把一个松散的想法转化为按顺序排列的调研工单地图，然后逐个推进直到解决。 |
| [`/review`](./skills/in-progress/review/SKILL.md) | 模型/用户调用 | 沿两条轴线审查自某个固定点（提交、分支、标签或 merge-base）以来的变更——标准（代码是否遵循本仓库文档化的编码规范？）和规格（代码是否符合原始 issue/PRD 的要求？）。两个审查由并行子代理执行并并排汇报。当用户想审查一个分支、PR、进行中的改动，或要求"自 X 起审查"时使用。 |
| [`/writing-beats`](./skills/in-progress/writing-beats/SKILL.md) | 模型/用户调用 | 像选择你自己的冒险那样，把文章塑造为一段节拍（beat）之旅。用户从原始素材中选一个起始节拍，你只写那一个节拍，然后给出下一步走向的选项，逐拍推进，直到文章自然收尾。当用户手头有原始素材、想把它组织成叙事而非论证时使用。 |
| [`/writing-fragments`](./skills/in-progress/writing-fragments/SKILL.md) | 模型/用户调用 | 一种 grilling 会话，从用户身上挖掘片段（fragments）——各种异质的写作 nugget（论断、小故事、犀利的句子、半成形的想法）——并把它们追加到同一个文档中，作为未来文章的原始素材。当用户想在强加结构之前先发展想法，或提到写作的"fragments"、"ideate"、"raw material"时使用。 |
| [`/writing-shape`](./skills/in-progress/writing-shape/SKILL.md) | 模型/用户调用 | 通过一场对话式会话，把一份原始素材的 markdown 文件塑造成文章——起草候选开篇，逐段生长全文，在每一步就格式（列表、表格、标注、引用）展开讨论。当用户手头有一堆笔记、片段或粗糙草稿，想把它变成可发布的东西时使用。 |

### Deprecated — 已废弃（4）

*原作者不再使用，保留供参考*

| skill | 调用方式 | 中文介绍 |
|-------|---------|---------|
| [`/design-an-interface`](./skills/deprecated/design-an-interface/SKILL.md) | 模型/用户调用 | 使用并行子代理为一个模块生成多套截然不同的接口设计。当用户想设计 API、探索接口选项、对比模块形态，或提到"design it twice"时使用。 |
| [`/qa`](./skills/deprecated/qa/SKILL.md) | 模型/用户调用 | 交互式 QA 会话，用户以对话方式报告 bug 或问题，由代理创建 GitHub issue。后台会探索代码库以获取上下文和领域语言。当用户想报告 bug、做 QA、以对话方式创建 issue，或提到"QA session"时使用。 |
| [`/request-refactor-plan`](./skills/deprecated/request-refactor-plan/SKILL.md) | 模型/用户调用 | 通过用户访谈制定带细粒度提交的详细重构计划，然后作为 GitHub issue 提交。当用户想规划重构、撰写重构 RFC，或将重构拆解为安全的增量步骤时使用。 |
| [`/ubiquitous-language`](./skills/deprecated/ubiquitous-language/SKILL.md) | 用户调用 | 从当前对话中提取 DDD 风格的统一语言（ubiquitous language）术语表，标记歧义并提议规范术语。结果保存到 UBIQUITOUS_LANGUAGE.md。当用户想定义领域术语、构建术语表、加固术语体系、创建统一语言，或提到"domain model"或"DDD"时使用。 |

## 致谢与许可

本仓库的 skills 源自 [Matt Pocock](https://github.com/mattpocock) 的 [mattpocock/skills](https://github.com/mattpocock/skills)（MIT 许可证），在此致谢。

> Copyright (c) 2026 Matt Pocock
>
> Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
>
> The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
>
> THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND.

本仓库整体采用 GPL v3 许可证（见 [LICENSE](./LICENSE)）。中文翻译部分为 KenKenSkills 项目的贡献。

## 维护

如需同步上游更新或新增其他优秀 skills 仓库，请参见 [MAINTENANCE.md](./MAINTENANCE.md)。
