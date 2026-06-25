# Engineering

原作者日常编码工作中使用的 skills。

## 用户调用

只有在你手动输入时才会触发（`disable-model-invocation: true`）。

- **[ask-matt](./ask-matt/SKILL.md)** — 询问哪种 skill 或流程适合当前场景。本仓库用户调用类 skills 的路由器。
- **[grill-with-docs](./grill-with-docs/SKILL.md)** — 一场 grilling 访谈，同时构建项目领域模型、打磨术语，并即时更新 `CONTEXT.md` 和 ADR。
- **[triage](./triage/SKILL.md)** — 让 issue 经过一组 triage 角色的状态机。
- **[improve-codebase-architecture](./improve-codebase-architecture/SKILL.md)** — 扫描代码库寻找深化机会，用可视化 HTML 报告呈现，然后针对你选中的项继续 grilling。
- **[setup-matt-pocock-skills](./setup-matt-pocock-skills/SKILL.md)** — 为工程类 skills 配置仓库（issue 追踪器、triage 标签、领域文档布局）。每个仓库运行一次。
- **[to-issues](./to-issues/SKILL.md)** — 使用垂直切片把任意计划、规格说明或 PRD 拆成可独立认领的 issue。
- **[to-prd](./to-prd/SKILL.md)** — 把当前对话转化为 PRD，并发布到 issue 追踪器。
- **[prototype](./prototype/SKILL.md)** — 构建一次性原型：可以是用于状态/业务逻辑问题的可运行终端应用，也可以是多套可切换的 UI 变体。

## 模型/用户调用

模型和用户都可以触发（description 中包含足够丰富的触发线索，方便模型主动使用）。

- **[diagnosing-bugs](./diagnosing-bugs/SKILL.md)** — 面向疑难 bug 和性能回归的纪律化诊断循环：复现 → 最小化 → 假设 → 插桩 → 修复 → 回归测试。
- **[tdd](./tdd/SKILL.md)** — 使用 red-green-refactor 循环进行测试驱动开发，一次一个垂直切片地构建功能或修复 bug。
- **[domain-modeling](./domain-modeling/SKILL.md)** — 主动构建和打磨项目领域模型：挑战术语、用场景压力测试，并即时更新 `CONTEXT.md` 与 ADR。
- **[codebase-design](./codebase-design/SKILL.md)** — 设计深层模块的共享纪律和词汇：小接口、清晰接缝、通过接口测试。
