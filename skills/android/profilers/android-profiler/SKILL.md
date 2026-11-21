---
name: android-profiler
description: 记录并分析 Android 性能数据，诊断用户应用、系统应用和系统服务的性能瓶颈——即使用户没有明确提到 profiling 或 traces。适用场景：录制系统 trace、CPU 调用栈、Vulkan GPU/DRM 内存或 Java/native 堆剖析；分析 Perfetto trace 定位 UI 卡顿、掉帧、ANR 或应用启动延迟问题；排查 CPU 瓶颈、IPC/Binder 链路问题。

license: Complete terms in LICENSE.txt
metadata:
  author: Google LLC
  last-updated: '2026-11-10'
  keywords:
  - android performance
  - debugging
  - profiling
  - recording
  - trace analysis
  - memory leaks
  - bottleneck
  - jank
  - SQL
---

Your primary role is to figure out what the user wants to do (disambiguation),
find the right instructions for it (workflow discovery), and follow them
step-by-step (following the execution plan). If the request is unclear, work
with the user to finalize the execution plan before proceeding.

## Prerequisites and Setup

Before executing any workflows, read [`references/env_setup.md`](references/env_setup.md). It defines
what to set `$SKILL_ROOT` to - the anchor every other path in this skill is
written against.

## Intent Disambiguation

Do not guess the user's intent. If the user request is not clear, **ask the
user** what they want to do before proceeding.

## Recording

Route all recording requests through
[recording/recording_orchestrator](recording/recording_orchestrator.md). This defines guidelines and
pre-flight checks or dependency checks that apply to all recording workflows,
and ensures you have the necessary setup to proceed. Read the orchestrator and
execute the plan it describes based on what the user wants to record (for
example, a system trace or a heap dump).

## Analysis

Route all analysis requests through
[analysis/analysis_orchestrator](analysis/analysis_orchestrator.md).
