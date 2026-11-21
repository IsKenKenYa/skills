# 测试报告模板

这是 run 目录里的可选附件，路径为当前 run 工作目录下的 `test-report.md`。流水线门禁只读 `report.json`，不读本文件。

不要把本报告写进被测 skill 的仓库目录。

## 模板

```markdown
# Skill 测试报告

## 基本信息

| 项目 | 值 |
|------|-----|
| Skill 名称 | [skill-name] |
| Skill 路径 | [仓库相对路径] |
| 执行时间 | YYYY-MM-DD HH:MM:SS |

## 汇总

| 指标 | 数量 |
|------|------|
| 用例总数 | [N] |
| PASS | [N] |
| FAIL | [N] |
| SKIP | [N] |
| ERROR | [N] |

## 按类型统计

| 测试类型 | 总数 | PASS | FAIL | SKIP | ERROR |
|----------|------|------|------|------|-------|
| 触发验证 | [N] | [N] | [N] | [N] | [N] |
| 冒烟测试 | [N] | [N] | [N] | [N] | [N] |
| 功能性测试 | [N] | [N] | [N] | [N] | [N] |

## 未写入 findings 的提示

用例少于 3 条等不阻塞 PR 的建议写在这里。

## 执行明细

| 用例 | 类型 | 结论 | 源文件 | 执行记录 |
|------|------|------|--------|----------|
| [id] | trigger/smoke/functional | PASS / FAIL / SKIP / ERROR | [仓库相对路径] | [exec 文件绝对路径] |
```

## 和 report.json 的对应关系

| 结论或结构问题 | report.json |
|---|---|
| 无用例目录、无用例文件、用例数为 0、提示词为空 | `blocker` |
| FAIL、ERROR | `blocker` |
| PASS、SKIP | 不写入 |
