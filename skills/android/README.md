## Android skills

**Android skills** 是一套面向 AI 优化的模块化说明与资源，帮助 agent 更准确地理解和执行 Android 开发中的特定模式，并遵循 [developer.android.com](https://developer.android.com) 的最佳实践与指导。

Android skills 遵循[开放的 Agent Skills 标准](https://agentskills.io/home)：通过 Markdown 文件（`SKILL.md`）为任务提供技术规格，并为大语言模型补充专业领域与工作流知识。

Android skill 的开发重点是评测显示大语言模型表现不足的用例和工作流。对于模型已经熟练掌握的成熟领域，例如 Jetpack Compose 基础最佳实践，目前不会优先补充。

更多信息请参阅官方文档：

- [Android skills](https://developer.android.com/tools/agents/android-skills)
- [Android CLI](https://developer.android.com/tools/agents/android-cli)
- [Android Studio](https://developer.android.com/studio/gemini/skills)

### 安装 Android skills

使用 Android CLI 将指定 skill 安装到当前目录：

```bash
android skills add --skill=r8-analyzer --project=.
```

使用 Android CLI 将全部 Android skills 安装到所有检测到的 agent 目录：

```bash
android skills add --all
```

如果尚不存在任何 agent 目录，并且未指定具体 agent，skills 会安装到 Gemini 和 Antigravity 共用的 `~/.gemini/antigravity/skills`。

**选项：**

- `--all`：添加全部 Android skills。省略时（且未指定 `--skill`），只安装 `android-cli` skill。
- `--agent`：要安装到的 agent 列表，以逗号分隔。省略时安装到所有检测到的 agent。
- `--skill`：要安装的指定 skill。省略时（且未指定 `--all`），只安装 `android-cli` skill。
- `--project`：要安装 skills 的项目根目录路径。

### 激活 skills

Agent 会自动激活与当前任务相关的 skills。要使用某个 skill，只需让 agent 完成与之相关的任务，例如“让我的应用 UI 支持 edge-to-edge”。如果已安装对应 skill，agent 应当能够自动发现并使用它。

## 免责声明

AI 可能出错，请始终复核结果。

## 参与贡献

请提交 GitHub issue 来提供反馈、报告问题，或提出新的 skill 请求与变更。

目前暂不接受公开代码贡献。

## 许可证

Android Skills 使用 [Apache License 2.0](LICENSE.txt)，详情请参阅 `LICENSE.txt`。

## 社区准则

本项目遵循 [Google 开源社区准则](https://opensource.google/conduct/)。
