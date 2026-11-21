---
name: anr-audit-and-fix
description: 审计 Android 代码库中的 ANR（应用无响应）风险并诊断 ANR 堆栈转储。当扫描 Android 代码查找 ANR 风险或分诊 ANR 堆栈转储时使用。不要用于非 ANR 崩溃、掉帧、一般 CPU 剖析或 Perfetto 系统 trace。

license: Complete terms in LICENSE.txt
metadata:
  author: Google LLC
  last-updated: '2026-11-10'
  keywords:
  - Android
  - ANR
  - Application Not Responding
  - responsiveness
  - main thread
  - ANR stack dump
  - Sync Barrier Leak
---

Select the execution path matching the user's request:

## 1. Path A: Static codebase ANR risk audit

When auditing source files or scanning for thread-blocking operations:

- Follow [references/risk_analysis_guide.md](references/risk_analysis_guide.md) step by step: list candidates, **prove the executing thread** (trace callers when the thread depends on them), **prove the call blocks**, then attribute and grade. Report only candidates that pass these checks; list the dismissed ones separately with a one-line reason.
- Evaluate off-main-thread mutations of attached Views not merely as crash risks (`CalledFromWrongThreadException`), but as **Sync Barrier Leak ANR** risks with their own proof (off-main execution plus an attached View).

## 2. Path B: Trace-driven diagnosis and remediation

When analyzing ANR traces or stack dumps:

- Diagnose systematically using [references/trace_analysis_guide.md](references/trace_analysis_guide.md) and format the report with [references/anr_trace_report_template.md](references/anr_trace_report_template.md).
- Base findings strictly on log evidence. Propose application fixes **only** for `APP_DEFECT` or `APP_RESOURCE_OVERLOAD` (never for `EXTERNAL_BOTTLENECK`).
