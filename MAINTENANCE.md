# 维护指南

本仓库采用**双轨结构**：

- `main` 分支：只含面向用户的 skills（中文化的 / 原生中文的 / 自建的），是 `npx skills add IsKenKenYa/skills` 扫描的分支。
- `upstream-refs` 分支：把各上游仓库作为 git submodule 放在 `references/` 下，用于追踪上游更新。

> 为什么要分两个分支？`skills` CLI 会递归扫描整个仓库找 `SKILL.md`，只跳过 `node_modules/.git/dist/build/__pycache__`。如果 submodule（含原版 SKILL.md）和 main 在同一分支，原版会被误扫，和本仓库的版本产生同名冲突。隔离到独立分支后，main 保持干净。

## 已整合的上游

| 上游 | submodule 路径 | main 下镜像位置 | 翻译策略 |
|------|---------------|----------------|----------|
| [mattpocock/skills](https://github.com/mattpocock/skills) | `references/mattpocock-skills` | `skills/{engineering,productivity,misc,personal,in-progress,deprecated}/` | description 译为中文，正文不动 |
| [HarmonyOS_Skills/harmonyos-agent-skills](https://gitcode.com/HarmonyOS_Skills/harmonyos-agent-skills.git) | `references/harmonyos-skills` | `skills/harmonyos/{design,solutions,development,test,tools,tooling}/` | 上游原生中文，不翻译；数字前缀目录压平 |
| [android/skills](https://github.com/android/skills) | `references/android-skills` | `skills/android/<技术域>/` | description 译为中文，正文不动 |

自建 skill（非上游）：
- `skills/meta/install-harmonyos-skills` — HarmonyOS skills 安装指导
- `skills/meta/install-android-skills` — Android skills 安装指导

## 同步上游更新

以 mattpocock 为例（其他上游同理）：

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

对照方式：在 `upstream-refs` 分支里进入对应 `references/<上游>/`，与 main 的 `skills/` 逐个 diff。同步规则因上游而异：

### mattpocock / Android（翻译型上游）

- 上游改了正文 / 非 description 字段 / 新增文件 → 原样同步到 main 对应位置。
- 上游改了 description → 重新翻译成中文，替换 main 里对应的中文 description。
- 上游新增 skill → 复制到 main 对应分类，翻译 description，并在 `.claude-plugin/plugin.json` 和 `README.md` 清单中补上。
- 上游删除 skill → 从 main、plugin.json、README 清单中一并移除。

已知上游删除项：
- `mattpocock/skills` 在 2026-06-17 删除了 `zoom-out`（上游说明：实际使用率低）。本仓库按最新版上游同步，不把 `zoom-out` 当作漏同步项；如果未来要保留历史 skill，先建立明确的 archived/legacy 区域并单独决策。

### HarmonyOS（原生中文上游，不翻译）

- 直接把上游变更原样同步到 main 的 `skills/harmonyos/` 下对应位置。
- 注意目录映射：上游用数字编号阶段分类（`02-design/`、`04-development/01-application-framework/` 等），main 下压平为 `design/`、`development/application-framework/` 等。同步时按映射表转换路径。
- 新增 skill → 同步到对应分类，补 plugin.json 和 README。
- HarmonyOS 的 `deveco-native-flow/references/` 下子 skill 必须带 `metadata.internal: true`（见下文「内部子 skill」）。上游若新增此类子 skill，同步时要补上该字段。

## 新增一个上游 skills 仓库

以 `https://github.com/example/awesome-skills` 为例：

```bash
# 1. 在 upstream-refs 分支添加 submodule
git checkout upstream-refs
git submodule add https://github.com/example/awesome-skills.git references/example-skills
git commit -m "chore: add example-skills upstream"

# 2. 切回 main，把想纳入的 skills 复制到对应位置
git checkout main
# 通用 skill → skills/<分类>/
# 专用 skill（某平台/某框架） → skills/<平台或框架>/
# 复制后按需翻译 description，更新 plugin.json 和 README 清单
```

约定：每个上游在 `references/` 下用 `<来源>-skills` 命名（如 `mattpocock-skills`、`harmonyos-skills`、`android-skills`）。

## 专用 skill 的分类原则

- **通用 skill**（不绑定特定平台/框架，如 tdd、grill-me、triage）→ 放 `skills/<上游的分类>/`。
- **专用 skill**（绑定特定平台/框架，如 HarmonyOS、Android、iOS）→ 放 `skills/<平台>/`，平台内再按技术域细分。例如 Android 的 `r8-analyzer` 放 `skills/android/performance/r8-analyzer/`，不放进通用 `engineering/`。
- 即使专用上游里有看起来通用的 skill（如某平台的 tdd 变体），也留在该平台大类下（如 `skills/android/tdd/`），不与通用 skill 混淆。

## 内部子 skill（metadata.internal）

部分 skill 内含 `references/` 子 SKILL.md，作为父 skill 的知识库，不应被全局独立调用。例子：HarmonyOS 的 `deveco-native-flow` 下有 36 个子 skill（`kits_arkts`、`native-coding` 等）。

处理方式：给子 skill 的 frontmatter 加 `metadata.internal: true`：

```yaml
---
name: kits_arkts
description: "..."
user-invocable: false
metadata:
  internal: true
---
```

效果（已从 skills CLI 源码验证）：
- `npx skills --list` 扫描时跳过这些子 skill，清单干净。
- 安装父 skill 时，CLI 的 `copySkillDirectory` 递归复制整个目录，子 skill 会随父 skill 一起被装走。
- 环境变量 `INSTALL_INTERNAL_SKILLS=1` 可强制让 CLI 扫描内部 skill（一般用不到）。

## HarmonyOS linter-cli 运行时依赖

`skills/harmonyos/development/application-framework/ArkTS/hmos-arkts-knowledge-retriever/linter-cli` 需要 Node 运行时依赖，但 node_modules **不入库**（见 `.gitignore`）。首次使用前在该目录执行：

```bash
cd linter-cli
npm install --force            # 装标准依赖（fs-extra/json5/uglify-js 等）
npm run install-runtime-deps   # clone OpenHarmony 定制版 TypeScript 4.9.5-r4
```

说明：
- `--force` 用于绕过上游 `package.json` 中 `"cpu": ["x64"]` 的平台限制（在 Apple Silicon / arm64 上必需）。
- `install-runtime-deps` 脚本从 `gitcode.com/openharmony/third_party_typescript.git` clone 定制版 TypeScript（标准 npm 上没有 `4.9.5-r4` 这个版本），装到 `node_modules/typescript/`。这是上游的官方还原流程，不要把 typescript 塞进 package.json 的 dependencies。
- 已验证：上述两步能完整还原 linter-cli 的运行环境。

## HarmonyOS hmos-jsleak-analysis 的 heap_cluster 二进制

`skills/harmonyos/solutions/quality/stability/hmos-jsleak-analysis/scripts/<平台>/heap_cluster*`（4 个平台二进制，93–116MB）**未入库**，原因：单文件超过 GitHub 100MB 硬限制，push 会被拒。

处理方式：
- 这些二进制在 `.gitignore` 中排除，不会进入仓库。
- skill 的 `scripts/` 下保留了体积较小的 `rawheap_translator*`（<1MB，入库）。
- `hmos-jsleak-analysis/SKILL.md` 的 Step 0 已说明：若 `heap_cluster` 缺失，从上游 [harmonyos-agent-skills](https://gitcode.com/HarmonyOS_Skills/harmonyos-agent-skills.git) 的 `03-solutions/quality/stability/hmos-jsleak-analysis/scripts/<平台>/` 获取并放回本 skill 同名目录。

同步上游更新时注意：若上游的 heap_cluster 二进制有更新，不要复制进本仓库（会触发 GitHub 大文件拒绝），保持 .gitignore 排除即可，文档指引不变。

## description 翻译规范

- **翻译对象**：仅 frontmatter 的 `description` 字段。
- **保持不变**：`name`、`disable-model-invocation`、`user-invocable`、`argument-hint`、`metadata`、`license` 等其他 frontmatter 字段，以及全部正文内容。
- **触发词保留原型**：`grill`、`tdd`、`triage`、`shoehorn`、`Husky`、`Obsidian`、`PRD`、`ADR`、`DDD`、`Jetpack Compose`、`CameraX`、`R8`、`Perfetto`、`ArkTS`、`ArkUI` 等关键词不翻译；首次出现时可加中文括注，如「测试驱动开发（TDD）」。
- **本土化**：把 "stress-test a plan" 这类表达译为「压力测试计划」等自然中文。
- **保留调用线索**：description 里 "Use when user..." 的触发条件要译清楚，这是模型/用户判断何时用该 skill 的依据。
- **HarmonyOS 例外**：上游已是中文（含中英混合），不翻译，原样保留。

## 重新生成 plugin.json 和 README 清单

新增/删除 skill 后，两者都要更新。生成脚本逻辑：

- `plugin.json`：扫描 `skills/` 下所有 SKILL.md，**排除 `metadata.internal: true` 的**，收集相对路径。name 字段为 `kenken-skills`。
- `README.md`：按上游分组（mattpocock 按 6 类、HarmonyOS 按 design/solutions/.../tooling、Android 按技术域、meta），每组列 skill 名 + 中文 description 的表格。

生成命令：

```bash
python3 gen_plugin.py     # 生成 .claude-plugin/plugin.json
python3 gen_readme.py     # 生成 README.md 的清单部分
```

同步 mattpocock 后，可运行审计脚本确认本地镜像与当前上游 `main` 对齐：

```bash
python3 audit_mattpocock_sync.py
```
