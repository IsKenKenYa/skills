---
name: arkuix-interface-scan
description: 扫描 OpenHarmony Stage 工程全部 @ohos.*/@hms.* 接口引用与 Native NDK C-API 引用（头文件包含与 OH_* 符号），按 ArkUI-X 适配性六分类（完整直用/有损直用/等价桥接/降级桥接/平台裁剪/业务决策，unknown 兜底）产出 ScanReport(JSON) 与迁移建议报告(Markdown)。开发者在评估 OH 应用迁移 ArkUI-X、需要接口适配清单或迁移画像时使用；FA 模型工程将被告知不支持。
license: MIT
metadata:
  author: ArkUI-X 团队
  version: "1.2.0"
  created: "2026-09-10"
  updated: "2026-09-19"
  keywords: ["arkui-x", "interface-scan", "cross-platform", "migration", "scan-report", "ndk", "c-api"]
compatibility: Requires Node.js >= 18. Fully offline (no network access); zero third-party dependencies.
---

# ArkUI-X 接口适配性扫描 Skill

当开发者需要评估 OpenHarmony 应用迁移到 ArkUI-X 的接口适配性时，使用本 Skill 全量扫描工程引用并产出结构化结论。

## 能力与边界

**做：**
- 扫描 Stage 工程（module.json5 + 全部 .ets/.ts + resources + 构建配置）中的 @ohos.*/@hms.* 引用
- 扫描 Native 源码（.cpp/.cc/.cxx/.h/.hpp）中的 NDK C-API 引用（#include 的 NDK 头文件与 OH_* 符号；v1.2）
- 动态加载边界（R-1）：`import('@ohos.x')` 与 `dlopen("libxxx.z.so")` 的字符串字面量计入清单；变量/拼接形式静态不可解析，不计入并在报告提示
- @ohos.* 双源交叉判定：本地 OpenHarmony SDK `@crossplatform` 标记（优先机器源）× 内置策展规则表；双源冲突归 unknown 待人工确认
- NDK C-API（source=ndk）判定：规则表单源（SDK C-API 头文件暂无跨平台标记体系，design 核验固化）
- @hms.* 默认归"业务决策"，附建议 OH 开源替代项（规则表已知时）
- 未展开的华为闭源 @kit.*（OH SDK kits 不含，如 PushKit/UIDesignKit）同归"业务决策"（RD7 口径：类比 @hms 处理，给 HMS Core 跨平台/平台原生替代指引；source=unknown 如实透传不虚计归属）
- 报告含单平台支持接口占比统计（规则表符号级 platform 条目命中情况，渲染时实时计算）
- 产出 `scan-report.json`（共享契约 schema_version=1，source 枚举 ohos/hms/ndk，供 F1/F3/F4 Skill 消费）与 `migration-advice.md`（人类可读报告）

**不做：**
- 工程结构转换（F1 骨架生成）、桥接代码生成（F3）、流程编排（F4）
- 源码内容改写；FA 模型工程仅提示不支持（project_model=fa）
- ArkTS/ECMAScript 语言内置对象（非 @ohos.* 命名空间）不在扫描范围

## 使用流程

1. **SDK 确认（必经，SD32 强化）**：Skill 探测**使用者本机**的 OpenHarmony SDK 候选后展示目录/版本/来源，由使用者确认或改指（改指目录须含 `ets/api/@ohos.*.d.ts`）。**未经确认不产出判定**：
   - **TTY**：逐候选交互确认（Y=确认 / n=输入其他目录 / r=切换候选 / q=中止）
   - **非 TTY（agent/CI 驱动）**：探测到候选但缺 `--sdk-dir` 与 `--yes` 时**退出码 4 零产出**并列出候选清单——**agent 必须将候选呈报用户确认后，以 `--sdk-dir <目录>` 重跑**（SDK 是双源判定的机器源，选错版本判定全错，不可默默选）；`--yes` 为 CI 授权语义（接受自动探测最佳候选，scan-report `sdk.origin=auto:*` 可追溯）
   - 未检出 SDK：交互环境可输入目录或回车降级；非交互自动降级为规则表单源判定并在报告标注
   - scan-report.json `sdk` 段记录 `path/version/confirmed/origin`（explicit/interactive/auto:*），migration-advice.md 判定 SDK 行同步呈现确认状态
2. **执行扫描**：
   ```bash
   node scripts/scan.js <工程根目录> [--out <输出目录>] [--sdk-dir <OpenHarmony SDK 目录>] [--yes] [--no-sdk] [--rules <规则表路径>]
   <!-- 产物目录（SD33）：缺省 <工程根>/arkuix-scan-output（锚定工程根，不随执行目录漂移）；重跑覆盖旧产物时 TTY 询问、非 TTY 警示后继续，如需保留请 --out 指定新目录 -->
   ```
   - `--sdk-dir` 显式指定 SDK 目录（视同确认，适用于 CI/脚本场景；`--sdk-path` 为兼容别名）
   - `--yes` 跳过交互确认（采纳探测结果）
   - `--no-sdk` 显式降级为规则表单源判定（报告中显著标注）
3. **解读产物**：
   - `scan-report.json`：inventory（引用清单，含 ndk 项）+ adaptation 七桶（六分类 + unknown）
   - `migration-advice.md`：按六分类组织的迁移建议；③/④ 类标注"将由 F3 生成桥接"；含单平台占比统计节与动态加载提示

## 退出码

| 码 | 语义 |
|----|------|
| 0 | 成功（含 SDK 未检出单源降级的成功产出） |
| 1 | 内部错误（未预期异常） |
| 2 | 输入无效（根目录不存在/不可读、参数非法值） |
| 3 | 模型不支持（project_model=fa/unknown；产物照常写出） |
| 4 | 用户中止（SDK 目录确认环节中止/输入流结束） |

## 判定规则（双源交叉）

| SDK `@crossplatform` 标记 | 规则表 | 结论 |
|---|---|---|
| 支持标记 | ①/②（支持向） | 采规则表细分，reason 注明双源一致 |
| 支持标记 | ③/④/⑤（不支持向） | **冲突 → unknown**（列出两源结论） |
| 支持标记 | 未覆盖 | ① 完整直用（单源：SDK） |
| 无标记 | ③/④/⑤ | 采规则表，双源一致 |
| 无标记 | ①/② | **冲突 → unknown** |
| 无标记 | 未覆盖 | unknown（判定依据未覆盖） |
| SDK 未检出 | 任意 | 规则表单源采信 + 报告显著标注 |

NDK C-API（source=ndk）：一律规则表单源判定（覆盖→分类；未覆盖→unknown）。
@hms.*（闭源）不走自动分类：一律"业务决策"，规则表已知时附建议替代项。

## 规则表演进

`rules/adaptation.json` 为版本化策展规则表（来源：OpenHarmony SDK `@crossplatform` 标记 + arkui-x docs 仓 API 参考 + NDK sysroot 核验，来源版本记录于表内 `meta` 字段）。符号级条目可携带 `platform: "android"|"ios"` 标注单平台支持（命中计入报告占比统计）。v1.2.0 按 arkui-x docs 普查策展单平台条目 10 项（@ohos.file.picker 安卓 5、@ohos.window iOS 3）。**v1.3.0 纳入 C-API 跨平台清单 23 项**（arkui/ 16 头官方收录 + rawfile 3 头 + Node-API 2 + plugin_utils，均 docs 实证；撤下无佐证的 native_drawing/ohos_init 2 条——扫描落 unknown 待人工，宁缺毋错）。发现误判请更新规则表并递增 `meta.rules_version`。

**SDK 播种器**：`node scripts/curator-seed.js --sdk-dir <OH SDK 目录>`——将 SDK 中"模块级整标"（整个 d.ts 声明跨平台）的模块自动播种为 full_direct 条目（v1.4.0 已播种 24 条，机器源出处记于条目 reason 与 meta.sources；人工策展条目优先、幂等可随 SDK 版本重跑）；符号级部分标记的模块只统计不播种（打印清单供人工策展）。

## 验收与测试

```bash
node --test scripts/          # 全部单测
node benchmark/compare.js     # 端到端验收（fixture + mini-sdk + C-API + 3 次一致性 + VM-16 demo 采样）
```
