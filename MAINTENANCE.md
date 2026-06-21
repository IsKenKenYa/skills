# 维护指南

本仓库采用**双轨结构**：

- `main` 分支：只含中文化的 skills（description 译为中文，其余原样），是 `npx skills add IsKenKenYa/skills` 扫描的分支。
- `upstream-refs` 分支：把各上游仓库作为 git submodule 放在 `references/` 下，用于追踪上游更新。

> 为什么要分两个分支？`skills` CLI 会递归扫描整个仓库找 `SKILL.md`，只跳过 `node_modules/.git/dist/build/__pycache__`。如果 submodule（含英文 SKILL.md）和 main 在同一分支，英文原版会被误扫，和中文化版本产生同名冲突。隔离到独立分支后，main 保持干净。

## 同步上游更新（mattpocock/skills）

当想拉取上游的最新改动时：

```bash
# 1. 切到 upstream-refs 分支
git checkout upstream-refs

# 2. 初始化并更新 submodule 到各自远程的最新 commit
git submodule update --init --remote

# 3. 查看 submodule 指针变化
git diff

# 4. 提交新的 submodule 指针
git add references/mattpocock-skills
git commit -m "chore: bump mattpocock-skills upstream"

# 5. 切回 main，对照上游 diff 同步变更
git checkout main
```

对照方式：在 `upstream-refs` 分支里进入 `references/mattpocock-skills/skills/`，与 main 的 `skills/` 逐个 diff。同步规则：

- **上游改了正文 / 非 description 字段 / 新增文件**：把改动原样同步到 main 对应的 skill。
- **上游改了 description**：重新翻译成中文，替换 main 里对应的中文 description。
- **上游新增了 skill**：复制到 main 的对应分类目录，翻译 description，并在 `.claude-plugin/plugin.json` 和 `README.md` 清单中补上。
- **上游删除了 skill**：从 main、plugin.json、README 清单中一并移除。

完成后在 main 分支提交。

## 新增一个上游 skills 仓库

以 `https://github.com/example/awesome-skills` 为例：

```bash
# 1. 在 upstream-refs 分支添加 submodule
git checkout upstream-refs
git submodule add https://github.com/example/awesome-skills.git references/example-skills
git commit -m "chore: add example-skills upstream"

# 2. 切回 main，把想纳入的 skills 复制到 skills/<分类>/ 下
git checkout main
# 复制后翻译 description，更新 plugin.json 和 README 清单
```

约定：每个上游在 `references/` 下用 `<来源>-skills` 命名（如 `mattpocock-skills`、`example-skills`）。

## description 翻译规范

- **翻译对象**：仅 frontmatter 的 `description` 字段。
- **保持不变**：`name`、`disable-model-invocation`、`argument-hint`、`metadata` 等其他 frontmatter 字段，以及全部正文内容。
- **触发词保留原型**：`grill`、`tdd`、`triage`、`shoehorn`、`Husky`、`Obsidian`、`PRD`、`ADR`、`DDD` 等关键词不翻译；首次出现时可加中文括注，如「测试驱动开发（TDD）」。
- **本土化**：把 "stress-test a plan" 这类表达译为「压力测试计划」等自然中文。
- **保留调用线索**：description 里 "Use when user..." 的触发条件要译清楚，这是模型/用户判断何时用该 skill 的依据。
