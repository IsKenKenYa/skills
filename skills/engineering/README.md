# Engineering（工程类）

日常编码工作中使用的 skills。

## 用户调用

仅在你明确输入调用时可用（Claude Code：`disable-model-invocation: true`；Codex：`agents/openai.yaml` 中的 `policy.allow_implicit_invocation: false`）。

- **[ask-matt](./ask-matt/SKILL.md)**：询问当前情境适合哪个 skill 或工作流，是本仓库用户调用型 skills 的路由器。
- **[grill-with-docs](./grill-with-docs/SKILL.md)**：在追问过程中同步构建项目领域模型，打磨术语，并直接更新 `CONTEXT.md` 与 ADR。
- **[triage](./triage/SKILL.md)**：通过一组分诊角色组成的状态机推进 issue。
- **[improve-codebase-architecture](./improve-codebase-architecture/SKILL.md)**：扫描代码库中可深化模块的机会，生成可视化 HTML 报告，再围绕选中的方向展开追问。
- **[setup-matt-pocock-skills](./setup-matt-pocock-skills/SKILL.md)**：为工程类 skills 配置仓库，包括 issue 跟踪器、分诊标签与领域文档布局；每个仓库执行一次。
- **[to-spec](./to-spec/SKILL.md)**：把当前对话整理成规格，并发布到 issue 跟踪器。
- **[to-tickets](./to-tickets/SKILL.md)**：把计划、规格或对话拆成一组示踪弹工单，每个工单都声明阻塞关系；可写入本地文本文件，也可使用真实跟踪器的原生阻塞链接。
- **[implement](./implement/SKILL.md)**：实现规格或工单描述的工作，在预先约定的边界使用 `/tdd`，并在提交前通过 `/code-review` 收尾。
- **[wayfinder](./wayfinder/SKILL.md)**：把超出单个 agent 会话容量的大型工作规划为 issue 跟踪器上的共享决策工单地图，逐一解决，直到目标路径清晰。

## 模型调用

模型或用户都可调用；description 中包含充分的触发线索，便于模型主动选择。

- **[prototype](./prototype/SKILL.md)**：构建一次性原型来回答设计问题，可以是验证状态/逻辑的单个可分享 HTML 文件，也可以是多组可切换的 UI 方案。
- **[diagnosing-bugs](./diagnosing-bugs/SKILL.md)**：用于疑难 bug 与性能回退的严谨诊断循环：建立能稳定复现问题的反馈回路，然后最小化、提出假设、插桩、修复并补回归测试。
- **[research](./research/SKILL.md)**：基于高可信度一手资料调查问题，并由后台 agent 将带引用的结论写成仓库内 Markdown 文件。
- **[tdd](./tdd/SKILL.md)**：使用红、绿、重构循环进行测试驱动开发，按垂直切片逐步实现功能或修复 bug。
- **[domain-modeling](./domain-modeling/SKILL.md)**：主动构建并打磨项目领域模型，质疑术语、用场景进行压力测试，并直接更新 `CONTEXT.md` 与 ADR。
- **[codebase-design](./codebase-design/SKILL.md)**：设计深层模块的共同准则与术语：小接口、清晰边界，并通过接口进行测试。
- **[code-review](./code-review/SKILL.md)**：沿两个轴线并行审查固定点之后的差异：**标准**（是否符合仓库编码规范及 Fowler 代码异味基线）和**规格**（是否忠实实现原始 issue/spec）。
- **[resolving-merge-conflicts](./resolving-merge-conflicts/SKILL.md)**：逐个冲突块处理正在进行的 git merge 或 rebase，追溯双方一手来源并按意图解决，最后完成操作，而不是执行 `--abort`。
- **[wizard](./wizard/SKILL.md)**：生成交互式 bash 向导，引导人类完成只有他们能执行的步骤，例如配置基础设施、凭据或 CI secret，操作陌生的第三方控制台，以及执行一次性迁移或切换。
