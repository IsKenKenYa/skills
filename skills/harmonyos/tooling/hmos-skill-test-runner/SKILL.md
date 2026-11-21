---
name: hmos-skill-test-runner
description: "Discovers and executes test cases for Agent Skills changed in the current pull request. Use when a PR touches a skill that has test-cases, and the pipeline must run each case prompt in a separate model call, compare the answer with expected output, and publish summary findings. Supports three standard test case formats: trigger verification, smoke (routing), and functional testing."

license: MIT
enable: true
publish: summary
metadata:
  author: harmonyos-dev-skills
  version: "3.0.0"
  created: "2026-09-28"
  updated: "2026-10-12"
  keywords: ["test-runner", "test-cases", "pipeline", "quality-assurance", "agent-skills"]
compatibility: Designed for the agentic-workflow summary pipeline and Claude Code. Requires the claude CLI. The pipeline agent does not need a HarmonyOS SDK; a missing compile command is a skip, not a failure.
---

# Skill 测试用例运行

## 快速开始

本技能在智能检视流水线里，对**本次 PR 改到的 skill** 做测试用例执行。它接在规范性检视（`hmos-skill-reviewer`）之后。

流水线只启动一次本技能。阶段 3 的每一条用例必须再启动一次独立的 `claude -p`，由那次调用扮演被测 skill。本会话只负责发现、读取、拉起子进程、比对和写报告，禁止在本会话里代答用例。

**核心能力:**

1. 从 PR diff 定位被改到的 skill，并确认 `test-cases/` 是否存在。
2. 直接读取 Markdown 格式的测试用例文件（无需脚本解析）。
3. 对每条用例另起模型，只给它被测 `SKILL.md` 和该条提示词，再按预期判定 PASS / FAIL / ERROR / SKIP。
4. 把会挡住 PR 的问题写成流水线 `report.json`。

---

## 输出

门禁产物只有流水线注入的报告文件 `report.json`。用 Node `JSON.stringify` 写入，禁止手拼 JSON 字符串。`skill` 必须正好是 `hmos-skill-test-runner`。没有问题就写空数组。

`title`、`message`、`suggestion`、`rationale` 用中文。路径、枚举、字段名保持原样。

```json
{
  "schema_version": "1.0",
  "skill": "hmos-skill-test-runner",
  "findings": [
    {
      "severity": "blocker",
      "file_path": "被测 skill 内用例文件的仓库相对路径",
      "line_number": 1,
      "title": "问题标题",
      "message": "未满足的预期，以及实际输出摘录",
      "suggestion": "修复建议",
      "rationale": "阶段3判定依据。FAIL/ERROR 必须写明执行记录的绝对路径"
    }
  ]
}
```

`severity` 只能是 `blocker`。

只允许这两类 finding：

| 类型 | 条件 | file_path |
|---|---|---|
| 结构问题 | 没有用例目录、目录里没有任何用例文件、用例总数为 0、某条用例没有可发送的提示词 | 被测 skill 的 `SKILL.md`，或该用例源文件 |
| 执行问题 | 阶段 3 判定为 FAIL 或 ERROR | 该用例源文件的仓库相对路径 |

下面这些只写进 run 目录里的 `test-report.md` 汇总，**不要**写进 `findings`：

- 用例 PASS
- SKIP（前置条件不满足、编译命令不存在、没有预期可比对）
- 用例少于 3 条

可选的 Markdown 报告写到当前 run 工作目录的 `test-report.md`，模板见 [assets/report-template.md](assets/report-template.md)。不要把 `test-report.md` 写回 PR 仓库。

---

## 工作流程

### 阶段 1: 发现本次要测的 skill

用下面的 diff 列出变更文件。分支名由流水线在准备 prompt 时填入。

```bash
git diff ${target_branch}...pr_${pr_number} --name-only
```

对每个变更路径向上查找，直到某个目录里有 `SKILL.md`。这些目录就是被测 skill，去重。变更没有碰到任何 skill 时，直接写 `"findings": []` 并结束。

用例目录只认：

- `<skill>/test-cases/`

不存在：记一条结构 blocker，`file_path` 用该 skill 的 `SKILL.md`，`line_number` 用 1。不要继续这个 skill 的阶段 2、阶段 3。

### 阶段 2: 读取用例

直接读取 `test-cases/` 目录下的 Markdown 文件。**只识别以下三个固定文件名，其他 `.md` 文件一律忽略，不执行。**

三种文件：

| 文件 | 类型 | 必需性 |
|------|------|--------|
| `trigger.md` | 触发验证 | 必需 |
| `smoke.md` | 冒烟测试（路由型 skill 才有） | 可选 |
| `functional.md` | 功能性测试 | 必需 |

读取每个文件，按 `---` 分割用例，每个用例以 `### 测试用例：` 开头。从每个用例中提取：

- **基本信息**：skill 名称、类型、阶段（如有）
- **输入**：prompt 内容
- **预期输出**：按类型不同提取不同字段

**触发验证**：提取 `应触发` 字段（`是` 或 `否`）

**冒烟测试**：提取 `应命中场景`、`禁止命中场景`、`阶段`（如有）

**功能性测试**：提取 `验证标准`（列表）、`应包含`（可选）、`不应包含`（可选）、`格式`（可选）、`应生成文件`（可选）

用例的提示词为空时：记结构 blocker，指向该用例源文件，不启动模型。

### 阶段 3: 执行

#### 步骤 1: 准备隔离后的被测 skill

为每个被测 skill 在 run 目录下复制一份，并删掉 `test-cases/` 目录，避免子进程读到预期答案。

#### 步骤 2: 每条用例单独开模型

禁止在本会话回答用例。对每条有提示词的用例，把提示词写入 `<run-dir>/prompts/<case-id>.txt`，再执行：

```bash
timeout 180 claude -p "$(cat <run-dir>/prompts/<case-id>.txt)" \
  --system-prompt "$(cat <隔离副本>/SKILL.md)" \
  --tools Read \
  --add-dir <隔离副本> \
  --dangerously-skip-permissions \
  --no-session-persistence \
  --output-format text
```

约束：

- 子进程的系统提示和用户消息里不得出现预期输出内容（验证标准、应包含、不应包含等）或本技能的说明。
- `--add-dir` 只能指向隔离副本。不要把 PR 仓库、用例目录、run 目录里的预期文件加进去。
- 同时运行的子进程最多 3 个。单条超过 180 秒，或进程退出码非 0，该用例记 ERROR。
- 标准输出写入 `<run-dir>/exec/<case-id>.txt`。

#### 步骤 3: 比对

子进程结束后，本会话对照预期逐条判定。

**触发验证**：

| 应触发 | 实际结果 | 判定 |
|--------|---------|------|
| 是 | 子进程输出体现了该 skill 的能力 | PASS |
| 是 | 子进程输出未体现该 skill 的能力 | FAIL |
| 否 | 子进程输出未触发该 skill | PASS |
| 否 | 子进程输出触发了该 skill | FAIL |

**冒烟测试**：

逐条检查输出中是否体现：
- 应命中场景：输出中是否提到了该场景
- 禁止命中场景：输出中是否提到了这些场景（任一出现即 FAIL）

判定：所有项满足 → PASS，任一不满足 → FAIL

**功能性测试**：

先检查可选字段：
- `应包含`：每项是否出现在输出中
- `不应包含`：每项是否未出现在输出中
- `格式`：输出是否符合指定格式
- `应生成文件`：指定文件是否存在

再逐条判断 `验证标准` 列表：
- **PASS**：输出明确满足该验证点
- **FAIL**：输出不满足，或与验证点矛盾

用例结论：

```
所有验证点均为 PASS                        → PASS
任意验证点 FAIL，或可选字段检查不通过       → FAIL
子进程超时、非 0 退出、没有产出回答         → ERROR
前置条件不满足                             → SKIP
```

每条执行过或 SKIP 的用例都要留下记录文件 `<run-dir>/exec/<case-id>.txt`，至少包含：用例 id、源文件相对路径、结论、完整预期、实际输出、逐条判定。FAIL / ERROR 的 `rationale` 必须写这个文件的绝对路径。

### 阶段 4: 写 report.json

汇总阶段 1 到阶段 3。先保证 `report.json` 写完，再写可选的 `test-report.md`。

结构 blocker 与执行 FAIL / ERROR 进入 `findings`。`message` 写明哪一条预期没满足，并摘录不超过 400 字的实际输出。`suggestion` 写该用例或被测 skill 应如何修改。`line_number` 用用例标题在源文件中的行号，找不到就写 1。

---

## 检查清单

### 要写入 findings 的 blocker

- [ ] 被改到的 skill 没有 `test-cases/` 目录
- [ ] 目录存在但没有任何用例文件，或用例总数为 0
- [ ] 用例没有可发送的提示词
- [ ] 阶段 3 结论为 FAIL 或 ERROR

### 只进 Markdown 汇总

- [ ] PASS、SKIP
- [ ] 缺少预期
- [ ] 用例总数少于 3

---

## 参考

- [触发验证模板](references/trigger-test-template.md)
- [冒烟测试模板](references/smoke-test-template.md)
- [功能性测试模板](references/functional-test-template.md)
- [测试报告模板](assets/report-template.md)
- [hmos-skill-reviewer](../hmos-skill-reviewer/SKILL.md) 是规范性检视，本技能只做用例执行。
