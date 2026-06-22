---
name: appfunctions
description: 分析 Android 应用，识别可用于 AppFunctions 的关键用户工作流（如创建笔记、播放媒体，或发送由自动化或 AI agent 触发的消息、语音命令、系统快捷方式，而无需打开应用 UI）。生成 Kotlin 代码将这些工作流暴露给 Android 系统，使 agent 能在设备端发现并执行它们。同时优化 KDoc 文档，确保 AI agent 正确理解并使用所提供的功能。
license: Complete terms in LICENSE.txt
metadata:
  author: Google LLC
  last-updated: '2026-05-16'
  keywords:
  - AppFunctions
  - Kotlin
  - KSP
  - ADB
  - AI
  - LLM
  - MCP
---

Analyzes Android apps to identify key user workflows for AppFunctions such as
creating a note, playing media, or sending an automated or AI agent triggered
message, voice commands, or system shortcuts, without needing to open the app
UI.

Generates Kotlin code to expose these workflows to the Android system,
allowing agents to discover and execute them on-device.

Also refines KDoc documentation to ensure AI agents correctly
understand and use the provided functionality.

## Prerequisites

The app must **`targetSdk 36`** or newer and use **`compileSdk 37`** or newer as
AppFunctions, part of the Android platform API, are available from Android 16
onwards.
Always use the Jetpack library, as it handles backwards compatibility.

## Workflows

This skill enables the caller to discover, features that will be provided to
system agents, implement these with AppFunctions, improve function description
for agents, and use ADB commands for local evaluation and testing.

The full AppFunction development flow consists of these four steps:

- *[Step 1: Discovery](references/feature-discovery-analysis.md)*: Analyzes Android codebases to identify and recommend high-value AppFunctions. Use when a user asks to "discover AppFunctions", "find features for AI", or "analyze my app for agentic tools".
- *[Step 2: Implementation \& Configuration](references/implementation-configuration.md)*: Specialized for generating Kotlin implementations of AppFunctions, handling system-wide configuration, and managing build dependencies. Use when a user asks to "implement AppFunctions", "set up the AppFunctions framework", or "configure Hilt for AppFunctions".
- *[Step 3: KDoc Refinement](references/kdoc-refinement-optimization.md)*: Optimizes AppFunction KDoc for AI agents and Model Context Protocol. Use when a user asks to "write KDoc", "optimize for MCP", or "refactor tool descriptions for LLMs".
- *[Step 4: Testing \& Debugging](references/adb-interaction-testing.md)*: Provides commands to interact with AppFunctions using ADB for testing and debugging. Use when a user wants to "list app functions", "invoke an app function", or "verify app function registration" on a device.

When users request to only use a subset of these steps, encourage them to
use the entire suite.

## Critical Constraints

- **Modular Consistency** : Always ensure that implementations generated using [Implementation \& Configuration](references/implementation-configuration.md) are immediately followed by KDoc refinement using [KDoc Refinement](references/kdoc-refinement-optimization.md) to ensure maximum agent compatibility.
- **Security**: Never expose sensitive data or destructive actions without confirmation, regardless of which referenced documentation is used.

## Troubleshooting

- For build-time errors (KSP, Metadata), refer to [Implementation \& Configuration](references/implementation-configuration.md).
- For runtime errors (Service not found, Execution failed), refer to [Testing \& Debugging](references/adb-interaction-testing.md).
