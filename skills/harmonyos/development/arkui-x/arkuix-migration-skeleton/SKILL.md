---
name: arkuix-migration-skeleton
description: "为 OpenHarmony Stage 工程生成 ArkUI-X 跨平台骨架（按平台选项的 Android/iOS 壳 + 共享 ArkTS）。提供 modify（经 ace tool modify 就地改造原工程）与 new（ace create 新建 scaffold 后迁入源码）双模式；消费 F2 ScanReport 判定工程模型（FA 直接拒绝）；检测 Android/iOS 编译环境与 ArkUI-X SDK（API 24+ 门槛）并生成编译验证辅助。开发者在 OH 应用迁移 ArkUI-X 需要搭建跨平台工程结构时使用。"

license: MIT
metadata:
  author: ArkUI-X 团队
  version: "1.1.0"
  created: "2026-09-10"
  updated: "2026-09-19"
  keywords: ["arkui-x", "skeleton", "cross-platform", "migration", "ace-tool", "platform-option"]
compatibility: "Requires Node.js >= 18 and ArkUI-X SDK toolchains (ace command). Fully offline; zero third-party dependencies. Windows: ace.cmd is launched via shell (Node CVE-2024-27980 policy rejects direct .cmd spawn with EINVAL); mock (.js) is always launched via node executable."

---

# ArkUI-X 迁移骨架生成 Skill

当开发者需要把 OpenHarmony Stage 工程改造/迁移为 ArkUI-X 跨平台工程（Android 壳 + iOS 壳 + 共享 ArkTS）时，使用本 Skill。

## 能力与边界

**做：**
- 消费 F2 ScanReport 的 project_model：fa → 直接提示不支持并停止（零写操作）；缺失/unknown → 引导先运行 F2 扫描
- **平台选项（v1.1）**：骨架生成（改造）前询问平台——双平台（默认）/仅 Android/仅 iOS；modify 将平台选项映射为 ace 交互应答（1=双平台/2=Android/3=iOS），new 按所选平台生成对应壳（未选平台壳裁剪）
- **modify 模式**：校验工程完整性（build-profile.json5 / oh-package.json5 / hvigorfile.ts 三件套）与 ArkUI-X SDK 门槛（API 24+）后，展示三组计划改动清单并确认，再调用 `ace modify --project`，在原工程注入所选平台壳（`.arkui-x/android` / `.arkui-x/ios`），原工程结构保留（共享 ArkTS = 原 entry）；执行后输出实际改动文件清单（成功与失败路径均输出）
- **new 模式**：经 `ace create -t app` 新建跨平台 scaffold（按所选平台裁剪壳），再把源工程 entry 源码**原样搬移**（不改写，改写属 F3）到共享 ArkTS 目录；输出目录非空时先请求确认（跳过/覆盖/中止）
- 环境检测（Android SDK/Gradle/JDK、Xcode/CocoaPods、ArkUI-X SDK 检出与版本）：只决定编译验证辅助与报告标注，**不阻断骨架生成**（例外：SDK < API 24 且模式=modify → 拒绝执行，退出码 4）
- 产出 `skeleton-result.json`（SKRS-1 v1.1 契约 schema_version=1：mode + platform + 条件必填壳字段 + environment 含 arkui_x_sdk；壳路径为相对路径——modify 相对工程根、new 相对输出目录）+ 骨架报告 + 编译验证辅助（命令文本与脚本，不直接执行编译）

**不做：** 接口适配分析（F2）、桥接代码生成与 @ohos.* 改写（F3）、流程编排（F4）、直接执行编译验证、自动回滚（ace tool 无事务性；以工程版本控制为恢复手段）。

## 使用流程

1. **前置**：先运行 F2 扫描获得 ScanReport（本 Skill 的模型判定输入）。
2. **执行**：
   ```bash
   node scripts/skeleton.js <工程根目录> --scan-report <F2 scan-report.json 路径> \
     [--mode modify|new] [--platform both|android|ios] [--out <输出目录>] \
     [--confirm-overwrite skip|overwrite|abort] [--yes] [--ace-bin <ace 命令路径>] [--timeout-ms <毫秒>]
   ```
   - 交互定序：模式引导询问 → 平台选项引导询问（默认 both）→（new）输出目录非空覆盖确认 → 生成执行
   - `--mode` 未指定时交互引导选择（默认建议 **modify**，改动小）；非交互环境须显式指定（缺失→退出码 2）
   - `--platform` 未指定时交互引导（默认 both）；非交互缺省 both；非法值→退出码 2
   - `--confirm-overwrite` 输出目录非空确认的非交互等价参数（skip/overwrite/abort）；非 TTY 缺省 abort
   - `--yes` 跳过 modify 计划改动清单确认（非 TTY 无则按用户中止，退出码 6）
   - `--timeout-ms <毫秒>` ace 子进程超时阈值（**默认 300000ms（5 分钟）**；环境变量 `ARKUIX_ACE_TIMEOUT_MS` 可覆盖：显式参数 > 环境变量 > 默认，非法环境值警告后回默认）
3. **产物**：`skeleton-result.json` + `migration-skeleton-report.md` +（所选平台环境就绪时）`verification/` 编译命令与验证脚本（结果留白，由开发者执行后确认）。

## 退出码

| 码 | 语义 |
|----|------|
| 0 | 正常结束：完成并产出；或用户跳过（不产出，stdout 明示"已跳过本次骨架生成"） |
| 1 | 内部错误（未预期异常） |
| 2 | 输入无效（根目录不存在/不可读、参数非法值、工程缺构建三件套） |
| 3 | 模型拒绝（project_model=fa；ScanReport 缺失/不可解析/unknown） |
| 4 | 环境不满足（ArkUI-X SDK < API 24 且模式=modify；含检出版本与升级/改用 new 建议） |
| 5 | 工具失败（ace tool 非零退出或超时） |
| 6 | 用户中止（交互无效输入连续 3 次或流结束、覆盖确认中止、计划确认未 --yes） |

## 关键行为

- **modify 失败**（工具非零退出/**超时**/产物断言不过）：输出失败原因（含实际超时阈值）+ 实际改动文件清单 + "建议改用 new 模式"，不静默继续（AC-2.2）
- **FA / 模型未知**：提示并停止，工程目录零新增/零变更（AC-4.1/4.2）
- **源码迁入完整性**：new 模式迁入后做文件集合 + 内容哈希校验（AC-3.1）
- **确定性**：同输入同产物（排除时间戳类字段）

## 已知限制与实测行为（ArkUI-X SDK 26.0.0，r3 修订）

- `ace create` 为 **5~6 题交互**（项目名→bundleName→runtimeOS→Compile SDK 菜单→平台→[双平台时] Framework 集成方式；Android-only 流第 6 题不出现）。
  - **TTY 环境**：进入前打印完整题面预告+建议答案，然后透传终端作答
  - **非 TTY + 真 ace**：直接给出可执行指引（A.手动命令+建议答案 B.手动后重跑跳过 C.TTY 重跑），**不再浪费一次必崩的管道尝试**
  - **非 TTY + mock/benchmark**：管道预喂正常工作**TTY 环境**：Skill 主动透传终端由用户作答（启动前打印建议答案：默认/默认/1(OpenHarmony)/16(最大项 SDK)/平台应答/2(CocoaPods)——Native Manual(1) 实测挂起，恒建议 2）；**非 TTY**：固定 6 答预喂（mock 与修复版 ace 可用）——真 ace 26.0.0 管道模式实测必崩（答毕仍 ERR_USE_AFTER_CLOSE），此时走官方回退：手动 `ace create` 后重跑（scaffold 在场自动跳过 create）
  - **Compile SDK 为 input 文本提示**（SD28 实证：ace_tools.js 中 `type:"input"`，validate 接受 "1".."16" 整串）：输最大项编号（如 16 = 26.0.0）后回车；`scripts/ace-ci-create.exp` 为 CI 包装——**注意 ace 26.0.0 的 prompts 渲染时序在 PTY 下不稳定**（重绘帧可冲掉 stdin 未读字符，送键可被串位），脚本内置 create 后落盘校验 compileSdkVersion，不符即清理产物并非零退出（宁可显式失败重跑，绝不让错版脚手架静默流出）。**CI 高频场景推荐**：真终端手动 create 成功一次后，后续以 scaffold 目录复制替代 ace create（Skill 对在场 scaffold 自动跳过 create）
- **scaffold 已在场**（`.arkui-x/` 在场）时自动跳过 ace create 直接迁入——"手动 create 后重跑"回退路径可用；目录已存在但需重建时 ace 会追加第 7 题（repair y/n），预喂不覆盖该场景，请清理目录后重跑
- **modify 幂等**：`.arkui-x/arkui-x-config.json5` 在场时跳过 ace 调用直接产出结果（重跑不二次注入）
- **多模块工程**：`ace modify` 对多 entry 模块会追加二级交互（选择跨平台 entry 模块）
  - **TTY + 多模块**：前置检测 → **跳过管道直接透传**（已知必崩不浪费时间），进入前打印题面预告
  - **管道崩溃截获**：`ERR_USE_AFTER_CLOSE` 堆栈替换为一句人话 + 三条解决路径（TTY/手动/改 new）
  - 纯管道环境请改用 new 模式，或使用 CI 包装脚本（`scripts/ace-ci-*.exp`，可选交付物）
- **多模块/业务名 entry 布局**（如 products/default、veditor）：new 模式按 build-profile `modules[].srcPath` 逐模块迁入，**迁入后自动回写输出工程 build-profile 注册各模块**（不存在时创建骨架）。
  - **名为 entry 的模块** → 合入 scaffold `entry/`（覆盖 Hello World 模板页）
  - **业务名模块**（如 musichomesample/veditor） → 迁入 `<outDir>/<模块名>/src/main`（与 entry/ 平级，符合 hvigor 多模块布局）
  - **无 entry 命名模块时**：scaffold entry/ 保留模板页，各业务模块按模块名平级落位；SkeletonResult（skeleton-result.json）含 `migrated_modules` 数组如实记录各模块落点（条目 `{name, target, files}`；entry→`<out>/entry/src/main`，其余→`<out>/<模块名>/src/main`；modify 模式不迁入→不输出该字段）；**零迁入=退出码 2 显式失败**（不再静默伪成功）
- build-profile.json5 解析支持**无引号键/注释/尾逗号**（官方样例常态写法，宽松 JSON5）
- modify"实际改动文件清单"为**全工程前后哈希 diff**（+/~/- 标记，含既有构建文件改写）
- **ace WARN 沉淀**：modify 成功路径将 ace 输出中的 WARN 级提示（如 `useNormalizedOHMUrl` 必办删除项）归档至 skeleton-result.json `ace_warnings` 字段与 migration-skeleton-report.md"ace 迁移提示（编译前必办）"段；TTY 透传模式无法捕获 stdout 时按 build-profile.json5 静态复核兜底
- **F2 分类结果逐桶确认（SD31，交互序修正版）**：通过模型门后、**骨架生成方式（mode/platform）询问之前**，按**风险序**（unknown→业务决策→有损直用→降级桥接→等价桥接→平台裁剪→完整直用）逐桶展示计数与示例条目并由用户确认——`y`=确认本桶 / `a`=剩余全部确认 / `n`=中止复核（码 6，零写）；空桶跳过。完整决策链：**SDK 确认（F2/SD32）→ 分类确认（本关口）→ 骨架生成方式 → 计划/目录确认 → 执行**。**TTY 逐桶交互必经**；**非 TTY（agent/CI）未确认（`--yes`）即停**——exit 6 零产出 + **预格式化逐桶呈报块**（风险序/计数/Top3 示例，随 stderr 一次性输出）；**agent 标准动作：将呈报块完整转述给用户（逐桶读出或整块粘贴），收集逐桶确认或异议后再带 `--yes` 重跑**——不得跳过呈报直接问“结果 OK 吗”（与 SD32 SDK 确认同款强制语义）
- **Windows ace 启动（SD30）**：ace 子进程统一经 spawnAce 封装——`.js`（mock）经 node 可执行启动；win32（ace.cmd/裸 ace）经 `shell:true` 启动（Node 安全策略不允许无 shell 直接执行 .cmd/.bat，CVE-2024-27980），含空格参数自动加引号
- 所有失败出口附**"下一步建议"指引块**（A/B/C 三条可执行路径）
- modify 失败产生的部分产物**保留供排查**（不自动清理），可手动删除工程内 `.arkui-x/` 后重试
- **CI 辅助脚本**：`scripts/ace-ci-create.exp` / `scripts/ace-ci-modify.exp`（expect PTY 包装，Linux/macOS 预装）
- **归档 scaffold 物化（SD28 根治，推荐 CI 路径）**：`--scaffold-from [目录]`（缺省内置 `assets/scaffold-26.0.0`）——从归档复制标准答案 scaffold（26.0.0/OpenHarmony/双平台/CocoaPods，行为等价 ace create，经与 ace 直出产物逐文件等价性验证），**零交互、零 ace 依赖、SDK 版本确定性**。运行时仅替换项目名（`--project-name`）与 bundleName（`--bundle-name`，含 java 包目录重组）、注入 buildArkTS 环境路径、按 `--platform` 裁剪壳。归档再生成：`node scripts/make-scaffold-archive.js <ace_tools目录> <输出> [26.0.0参照产物]`
- **归档物化未对标 ace create 的边界（出现需要时按下述路径扩展，勿重新走交互 ace）**：
  1. **iOS 签名**：归档保留模板默认（Manual，无 DEVELOPMENT_TEAM）；ace 会用本机证书写 pbxproj。→ 扩展路径：materialize 增加 `--ios-team <id>` 参数，替换 pbxproj 签名段（CODE_SIGN_STYLE=Automatic + DEVELOPMENT_TEAM，与 ace signIOS 同款三行替换，10 行级改动）
  2. **参数集固定**：归档仅覆盖 26.0.0/OpenHarmony/双平台/CocoaPods/app 模板。需要的形态与扩展路径：
     - runtimeOS=HarmonyOS → make-scaffold-archive 走 PM 分支（runtimeOS/compatibleSdkVersion 形态不同），另存 `scaffold-26.0.0-hm`
     - 其他 SDK 版本（如 API 24）→ build-profile/hvigor 六元组按 ace ON() 映射表取值，归档按版本命名 `scaffold-<ver>`
     - Framework=Native Manual（1）→ iOS 模板改取 `templates/ios`（非 cocoapods/），去 Podfile
     - library / plugin_napi 模板 → KM 分支不同（ets_stage→cpp_ets_stage + cpp 目录），make-scaffold-archive 加 `--template` 开关
     - 以上均为组装工具参数化再生成，物化引擎不变
  3. **pod init**：ace create 时现场校验/初始化 CocoaPods；归档固化了 Podfile 内容，编译期 `pod install` 才需要 pod。→ 扩展路径：materialize 可选跑 `pod --version` 探测，未装则 envNote 提示（与 buildArkTS 占位符提示同款）
  4. **buildArkTS moduleLists** 固定 entry（ace 默认同值）；多模块编译按需手改。→ 扩展路径：materialize 后按迁入模块清单回写 moduleLists

## 测试

```bash
node --test scripts/          # 全部单测（mock-ace 替身）
node benchmark/compare.js     # 端到端验收（fixture + mock-ace + 平台三取值 + 退出码全映射 + 3 次一致性）
```
