## Android skills

**Android skills** 是一组专门面向 Android 开发的、模块化的 AI 优化指令与资源，帮助 LLM 更好地理解并执行符合 [developer.android.com](https://developer.android.com) 最佳实践与官方指导的开发模式。

Android skills 遵循 [open-standard agent skills](https://agentskills.io/home)：每个 skill 都是一个 Markdown 文件（`SKILL.md`），用于描述任务的技术规格，并用特定领域和工作流的信息为 LLM 提供上下文。

Android skill 的开发重点放在**评测显示 LLM 表现不足的用例和工作流**上。对于 LLM 已经较擅长的成熟领域，例如基础 Jetpack Compose 最佳实践，不会优先覆盖。

更多信息请阅读官方文档：

- [Android skills](https://developer.android.com/tools/agents/android-skills)
- [Android CLI](https://developer.android.com/tools/agents/android-cli)
- [Android Studio](https://developer.android.com/studio/gemini/skills)

### 安装 Android skills

使用 Android CLI 将某个指定 skill 安装到当前目录：

```bash
android skills add --skill=r8-analyzer --project=.
```

使用 Android CLI 将全部 Android skills 安装到检测到的所有 agent 目录：

```bash
android skills add --all
```

如果你没有任何已有 agent 目录，也没有指定特定 agent，skills 会安装到 Gemini 和 Antigravity 使用的 `~/.gemini/antigravity/skills`。

**选项：**

- `--all` - 添加全部 Android skills。如果省略该选项且未指定 `--skill`，只会安装 `android-cli` skill。
- `--agent` - 要安装到的 agent 列表，用逗号分隔。如果省略，会安装到所有检测到的 agent。
- `--skill` - 要安装的指定 skill。如果省略该选项且未指定 `--all`，只会安装 `android-cli` skill。
- `--project` - 要安装 skills 的项目根目录路径。

## 免责声明

AI 可能会犯错，因此请始终复核结果。

## 贡献

如需反馈、报告问题，或提出新的 skill 请求与修改建议，请提交 GitHub issue。

当前暂不接受公开贡献。

## 许可证

Android Skills 使用 [Apache License 2.0](LICENSE.txt) 授权。详情见 `LICENSE.txt` 文件。

## 社区准则

本项目遵循 [Google Open Source Community Guidelines](https://opensource.google/conduct/)。
