---
name: research
description: 基于高可信度的一手来源调查问题，并将发现以 Markdown 文件形式保存到仓库中。当用户需要研究某个主题、收集文档或 API 事实，或将阅读调研工作委托给后台代理时使用。
---

Spin up a **background agent** to do the research, so you keep working while it reads.

Its job:

1. Investigate the question against **primary sources** — official docs, source code, specs, first-party APIs — not a secondary write-up of them. Follow every claim back to the source that owns it.
2. Write the findings to a single Markdown file, citing each claim's source.
3. Save it where the repo already keeps such notes; match the existing convention, and if there is none, put it somewhere sensible and say where.
