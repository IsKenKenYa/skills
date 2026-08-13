# In Progress（进行中）

这些是上游有意公开的 Beta skills，可供试用和反馈，但可能随时变化或消失。与上游插件默认排除该目录的策略不同，本仓库以“完整镜像”为原则，仍会把它们列入顶层清单和生成的插件配置。

- **[loop-me](./loop-me/SKILL.md)**：以当前目录为有状态工作区，在多个会话中通过自我追问形成可实施的工作流规格；由用户调用。
- **[writing-beats](./writing-beats/SKILL.md)**：把文章塑造成一段段旅程式节拍；选择起点、只写当前节拍，再转向下一节拍，直到文章自然结束。
- **[writing-fragments](./writing-fragments/SKILL.md)**：通过追问挖掘异构的写作片段，并追加到一个文档中，作为未来文章的原材料。
- **[writing-shape](./writing-shape/SKILL.md)**：把装有原始素材的 Markdown 文件逐段塑造成文章，并在每一步讨论格式选择。
- **[claude-handoff](./claude-handoff/SKILL.md)**：通过 `claude --bg` 把当前对话交接给新的后台 agent，并用交接摘要让它立即继续工作；由用户调用。
- **[setup-ts-deep-modules](./setup-ts-deep-modules/SKILL.md)**：把 dependency-cruiser 接入 TypeScript 仓库，使每个 package 成为深层模块：实现隐藏在子目录中，只能通过入口文件访问，测试也通过入口执行；由用户调用。
