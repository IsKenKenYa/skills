---
name: appfunctions
description: 分析 Android 应用，发现可暴露为 AppFunctions 的用户工作流，如创建笔记、播放媒体或发送消息——AI agent、语音命令和系统快捷方式随后无需打开应用 UI 即可执行它们。使用 androidx.appfunctions 库生成 Kotlin 代码，并优化 KDoc 与应用描述，让 agent 能正确选择和调用函数。当需要发现、实现、文档化或测试 AppFunctions 时使用此 skill。

license: Complete terms in LICENSE.txt
metadata:
  author: Google LLC
  last-updated: '2026-11-10'
  keywords:
  - AppFunctions
  - Kotlin
  - KSP
  - ADB
  - AI
  - LLM
  - MCP
---

Analyzes Android apps to identify key user workflows to expose as AppFunctions,
such as creating a note, playing media, or sending a message, for AI agents,
voice commands, and system shortcuts to run without opening the app UI.

Generates Kotlin code to expose these workflows to the Android system,
allowing agents to discover and execute them on-device.

Also refines KDoc documentation and the app description so AI agents correctly
understand and use the provided functionality.

## Prerequisites

The app must **`targetSdk 36`** or newer and use **`compileSdk 37`** or newer as
AppFunctions, part of the Android platform API, are available from Android 16
onwards.
Always use the Jetpack library because it handles backward compatibility.
Use `androidx.appfunctions:appfunctions` and the KSP compiler
`androidx.appfunctions:appfunctions-compiler`, version 1.0.0-beta01 or later.

## Workflows

This skill enables the caller to discover features that will be provided to
system agents, implement these with AppFunctions, improve function description
for agents, and use ADB commands for local evaluation and testing.

The full AppFunction development flow consists of these four steps:

- *[Step 1: Discovery](references/feature-discovery-analysis.md)*: Analyze Android codebases to identify and recommend potential AppFunctions. Use this step when a user asks to "discover AppFunctions," "find features for AI," or "analyze my app for agentic tools."
- *[Step 2: Implementation and configuration](references/implementation-configuration.md)*: Generate Kotlin implementations of AppFunctions, manage system-wide configuration, and configure build dependencies. Use this step when a user asks to "implement AppFunctions," "set up the AppFunctions framework," or "configure Hilt for AppFunctions."
- *[Step 3: KDoc refinement](references/kdoc-refinement-optimization.md)*: Optimize AppFunction KDoc and the app description for AI agents and Model Context Protocol. If a user asks to "write KDoc", "optimize for MCP", or "refactor tool descriptions for LLMs", use this step.
- *[Step 4: Testing and debugging](references/adb-interaction-testing.md)*: Provide commands to interact with AppFunctions using ADB for testing and debugging. If a user wants to "list app functions", "invoke an app function", or "verify app function registration" on a device, use this step.

When the user asks for a subset of the steps, run those steps and any step
that the critical constraints require. Then list the skipped steps and ask
whether to run them.

If they apply, you must load the following references:

- *[Context and terminology](references/context.md)*: Defines the ubiquitous language, architecture definitions, and design patterns across the AppFunctions skill suite. Load when you need to understand core architecture terminology or check the distinctions between modern and legacy AppFunctions APIs.
- *[Migration to service entry point](references/migrate-to-service-entry-point.md)* : Migrates apps on AppFunctions 1.0.0-alpha09 or lower to the `AppFunctionServiceEntryPoint` architecture from 1.0.0-alpha10, and upgrades apps to 1.0.0-beta01. Load it when a user asks to migrate or upgrade existing AppFunctions code. When you find legacy `AppFunctionConfiguration.Provider` implementations, `@AppFunction` annotations, or `appfn:description` attributes, load it and ask the user before you migrate.

## Critical constraints

- **Modular consistency**: You must refine KDocs immediately after you generate AppFunction implementations.
- **Security**: Expose only safe, non-destructive tasks that the app's UI already offers on that form factor. Never give agents wide-ranging access to user data or system resources. Never require or return passwords, financial details, private keys, or other highly sensitive personal information.
- **Descriptions**: Describe what each function does, never how an agent must behave. Put call order across functions in the app description, not in function KDoc.

## Troubleshooting

- If you encounter build-time errors such as Kotlin Symbol Processing (KSP) issues, see [Implementation and configuration](references/implementation-configuration.md).
- If you encounter runtime errors such as missing services or execution failures, see [Testing and debugging](references/adb-interaction-testing.md).
- If you need architecture definitions and vocabulary, see [Context and terminology](references/context.md).
- If you encounter issues when upgrading AppFunctions, such as errors on `@AppFunction`, which is no longer an annotation, see [Migration to service entry point](references/migrate-to-service-entry-point.md).
