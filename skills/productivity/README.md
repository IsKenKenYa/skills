# Productivity（生产力类）

不局限于编码的通用工作流工具。

## 用户调用

仅在你明确输入调用时可用（Claude Code：`disable-model-invocation: true`；Codex：`agents/openai.yaml` 中的 `policy.allow_implicit_invocation: false`）。

- **[grill-me](./grill-me/SKILL.md)**：围绕计划或设计持续追问，直到设计树的每个分支都得到解决。
- **[handoff](./handoff/SKILL.md)**：把当前对话压缩成交接文档，让另一个 agent 可以继续工作。
- **[teach](./teach/SKILL.md)**：把当前目录作为有状态的教学工作区，跨多个会话教授新技能或概念。
- **[to-questionnaire](./to-questionnaire/SKILL.md)**：把你无法独自回答的决策整理成 Markdown 问卷，交给真正掌握答案的人异步填写，或在会议中共同完成。
- **[wait-what](./wait-what/SKILL.md)**：当某条消息没有讲清楚时立即调用；agent 会补足缺失的上下文，用清晰英语和 `CONTEXT.md` 中的通用语言重新说明。

## 模型调用

模型或用户都可调用；description 中包含充分的触发线索，便于模型主动选择。

- **[grilling](./grilling/SKILL.md)**：就计划、决策或想法持续追问，直到设计树的每个分支都得到解决。
- **[writing-for-agents](./writing-for-agents/SKILL.md)**：编写供 agent 使用的文档，包括 skills、`AGENTS.md`、`CLAUDE.md`，以及 agent 通过指针访问的其他文档。
