---
feature: skill-sync-2026-07-09
status: delivered
specs: []
plans: []
branch: main
commits: 687a3c0..(pending)
---

# Skill 同步更新 — 最终报告

## What Was Built

完成三上游仓库（mattpocock、android、HarmonyOS）的定期同步，将本地 skill 库从 102 个更新至 103 个。翻译了 5 个 HarmonyOS skill 的英文 description 为中文，同步了 mattpocock v1.1 重大变更（to-prd→to-spec、to-issues 删除、to-tickets 新增、wayfinder 毕业），以及 android 的 camera1-to-camerax→camerax 替换。

## Architecture

### mattpocock v1.1 变更

| 操作 | Skill | 说明 |
|------|-------|------|
| 重命名 | to-prd → to-spec | 规格说明（spec）取代 PRD |
| 删除 | to-issues | 合并入 to-tickets |
| 新增 | to-tickets | 支持顺序计划和并行 DAG 两种模式 |
| 毕业 | wayfinder | 从 in-progress 移至 engineering |

### android 变更

| 操作 | Skill | 说明 |
|------|-------|------|
| 删除 | camera1-to-camerax | 旧版迁移 skill |
| 新增 | camerax | 更广泛的 CameraX 开发指导，含 10 个参考文档 |
| 更新 | agp-9-upgrade | 元数据日期更新 |

### HarmonyOS description 翻译

5 个英文 description 已翻译为中文：
- `hmos-multidevice-avoid-areas` — 避让区适配
- `hmos-multidevice-hardware-access` — 硬件能力适配
- `hmos-multidevice-scenario-entry` — 多设备场景入口
- `hmos-skill-reviewer` — Skill 审查验证
- `hmos-arkts-knowledge-retriever` — ArkTS 引用检索

## Verification

- SKILL.md 文件数：103（排除 internal refs）
- plugin.json 条目数：103
- README 总数：103
- 交叉检查：所有 103 个 plugin.json 条目均有对应 SKILL.md
- 4 个新增 skill 文件全部存在

## Journey Log

- [lesson] HarmonyOS 上游部分 skill 的 description 是英文，需按 MAINTENANCE.md 规则翻译为中文
- [lesson] mattpocock v1.1 是 breaking change，to-prd 重命名为 to-spec，to-issues 合并入 to-tickets
