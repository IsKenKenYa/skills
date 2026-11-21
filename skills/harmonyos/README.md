# HarmonyOS Agent Skills

## 项目简介

**HarmonyOS Agent Skills** 是专为 HarmonyOS 应用开发设计的 Agent Skills 集合，整合了 HarmonyOS 应用开发全生命周期的最佳实践，为 AI 助手提供结构化的技能支持，覆盖从设计、开发、测试到发布的完整流程。

### 核心特性

- **🤖 AI 驱动**：为 AI 助手提供专业的 HarmonyOS 开发技能
- **📚 知识体系化**：结构化的参考文档和最佳实践
- **✅ 质量保障**：完整的测试用例和验收标准
- **🔄 持续演进**：跟随 HarmonyOS 版本持续更新

## 快速开始

```bash
# 克隆仓库
git clone https://gitcode.com/HarmonyOS_Skills/harmonyos-agent-skills.git

# 查看技能列表
ls -la */

# 在 AI 助手中引用对应的 SKILL.md 即可使用该技能
```

## Skills 目录

> 按类别分组，点击技能名可直达其 `SKILL.md`。

### 设计

| 技能 | 说明 |
| --- | --- |
| [hmos-design-visual-mobile](01-design/mobile/hmos-design-visual-mobile/SKILL.md) | HarmonyOS 移动端页面视觉还原，基于设计规范与组件模板生成高保真 HTML 页面 |

### 开发框架

| 技能 | 说明 |
| --- | --- |
| [hmos-arkui-performance-analysis](02-development/arkui/hmos-arkui-performance-analysis/SKILL.md) | 只读分析 ArkUI 组件刷新与复用、滑动、启动、动画和转场性能，提供代码证据、修改建议及验证方法 |
| [arkui-memory-analysis](02-development/arkui/arkui-memory-analysis/SKILL.md) | ArkUI 内存热点静态分析：检测 16 类内存反模式（不可见页面/Tabs缓存/非懒加载/布局冗余等），支持源码+dump双输入 |
| [hmos-arkui-v1-v2-migration-and-mixusage](02-development/arkui/hmos-arkui-v1-v2-migration-and-mixusage/SKILL.md) | ArkUI 状态管理 V1/V2 迁移和混用，覆盖整仓/组件迁移、跨版本数据流、Storage、渲染复用、依赖与构建验证 |
| [hmos-arkui-dark-light-adaptation](02-development/arkui/hmos-arkui-dark-light-adaptation/SKILL.md) | 深浅色适配、颜色资源精简、WithTheme 局部主题及高性能切换，包含 V1/V2 兼容性检查 |
| [hmos-arkui-develop-skill](02-development/arkui/hmos-arkui-develop-skill/SKILL.md) | ArkUI 代码开发助手，调用知识检索获取 API 证据后完成编码和验证 |
| [hmos-arkui-knowledge-retriever](02-development/arkui/hmos-arkui-knowledge-retriever/SKILL.md) | ArkUI 知识检索层，提供基于本地知识库的精准检索，不涉及代码生成 |
| [hmos-arkui-kit-window-floatwindow](02-development/arkui/hmos-arkui-kit-window-floatwindow/SKILL.md) | 悬浮类需求开发：画中画（PiPWindow）、闪控窗（floatView）、闪控球（floatingBall），覆盖分流、接口、查错与写程序 |
| [hmos-arkui-longtake-transition](02-development/arkui/hmos-arkui-longtake-transition/SKILL.md) | ArkUI 一镜到底转场效果开发 |
| [hmos-arkui-mvvm-pattern](02-development/arkui/hmos-arkui-mvvm-pattern/SKILL.md) | HarmonyOS ArkUI 的 MVVM 架构技能，指导项目分层设计与数据流规范 |
| [hmos-arkui-scenario-development](02-development/arkui/hmos-arkui-scenario-development/SKILL.md) | ArkUI 场景化开发 |
| [hmos-arkui-statemgt-migration](02-development/arkui/hmos-arkui-statemgt-migration/SKILL.md) | 帮助开发者将 ArkUI 状态管理从 V1 迁移到 V2 |
| [hmos-arkts-deprecated-interface-checker](02-development/arkts/hmos-arkts-deprecated-interface-checker/SKILL.md) | 检查 HarmonyOS 项目中的废弃 SDK 接口并提供修复建议 |
| [hmos-arkts-knowledge-retriever](02-development/arkts/hmos-arkts-knowledge-retriever/SKILL.md) | 检索 ArkTS 语言指南文档，为代码开发、审查和调试提供语法参考 |
| [hmos-ability-insight-intent-generator](02-development/ability/hmos-ability-insight-intent-generator/SKILL.md) | HarmonyOS 意图装饰器代码生成器，根据用户需求自动选择装饰器并生成代码 |
| [hmos-atomicservice-assistant](02-development/atomic-service/hmos-atomicservice-assistant/SKILL.md) | 为元服务开发提供指导和建议 |
| [hmos-ascf-assistant](02-development/atomic-service/hmos-ascf-assistant/SKILL.md) | 为ASCF元服务开发提供指导和建议 |
| [hmos-ascf-convert-taro](02-development/atomic-service/hmos-ascf-convert-taro/SKILL.md) | Taro 小程序转 ASCF 元服务 |
| [hmos-ascf-convert-uniapp](02-development/atomic-service/hmos-ascf-convert-uniapp/SKILL.md) | uni-app 转 ASCF 元服务 |
| [arkuix-interface-scan](02-development/arkui-x/arkuix-interface-scan/SKILL.md) | 扫描 OpenHarmony 工程接口引用，判定 ArkUI-X 适配性并产出迁移建议报告 |
| [arkuix-migration-skeleton](02-development/arkui-x/arkuix-migration-skeleton/SKILL.md) | 为 OpenHarmony 工程生成 ArkUI-X 跨平台骨架 |
| [arkuix-bridge-codegen](02-development/arkui-x/arkuix-bridge-codegen/SKILL.md) | 为需桥接的接口生成 ArkUI-X Bridge 五件套（契约/转发/双平台 BridgePlugin），围栏保护增量再生成 |
| [arkuix-migration-orchestrator](02-development/arkui-x/arkuix-migration-orchestrator/SKILL.md) | 单命令编排 扫描→骨架→桥接→报告 全链，断点续跑/决策裁决/源码改写一体化 |

### HarmonyOS SDK

| 技能 | 说明                                                                  |
| --- |---------------------------------------------------------------------|
| [hmos-one-sdk-skill](02-development/sdk/hmos-one-sdk-skill/SKILL.md) | 鸿蒙SDK高频场景 SKILL集合                                                   |
| [hmos-account-kit-quicklogin-client](02-development/account-kit/hmos-account-kit-quicklogin-client/SKILL.md) | 基于 HarmonyOS Account Kit 提供华为账号一键登录客户端接入指引，实现获取匿名手机号接口与华为账号一键登录组件集成 |
|[hmos-account-kit-login-api-client](02-development/account-kit/hmos-account-kit-login-api-client/SKILL.md)| 基于 HarmonyOS Account Kit 提供华为自定义按钮登录客户端接入指引                         |
|[hmos-account-kit-login-button-client](02-development/account-kit/hmos-account-kit-login-button-client/SKILL.md)| 华为 Account Kit "华为账号登录"功能接入技能                                       |
| [hmos-ads-kit-access](02-development/ads-kit/hmos-ads-kit-access/SKILL.md) | HarmonyOS Ads Kit (广告服务) 开发指南                                       |
| [hmos-live-view-kit-build-location](02-development/live-view-kit/hmos-live-view-kit-build-location/SKILL.md) | HarmonyOS实况窗（LiveView）代码生成助手                                        |
| [hmos-map-kit-map-creation](02-development/map-kit/hmos-map-kit-map-creation/SKILL.md) | HarmonyOS Map Kit地图创建开发指南，支持地图组件创建、覆盖物管理、相机控制、图层配置等能力               |
| [hmos-map-kit-poi-search](02-development/map-kit/hmos-map-kit-poi-search/SKILL.md) | Map Kit位置搜索与POI检索开发指南，适用于直接调用本地SDK接口获取地图元素的场景                       |
| [hmos-map-kit-route-planning](02-development/map-kit/hmos-map-kit-route-planning/SKILL.md) | Map Kit路径规划开发指南                                                     |
| [hmos-payment-kit-huawei-payment-integration](02-development/payment-kit/hmos-payment-kit-huawei-payment-integration/SKILL.md) | 华为支付 / 鸿蒙支付服务接入指引                                                   |
| [hmos-push-kit](02-development/push-kit/hmos-push-kit/SKILL.md) | 华为Push Kit推送服务集成助手（Master Skill/大路由）                                |
| [hmos-push-kit-background](02-development/push-kit/hmos-push-kit/hmos-push-kit-background/SKILL.md) | 推送后台消息助手                                                            |
| [hmos-push-kit-notification](02-development/push-kit/hmos-push-kit/hmos-push-kit-notification/SKILL.md) | 发送通知消息助手                                                            |
| [hmos-push-kit-token](02-development/push-kit/hmos-push-kit/hmos-push-kit-token/SKILL.md) | Push Token 获取助手                                                     |
| [hmos-push-kit-voip](02-development/push-kit/hmos-push-kit/hmos-push-kit-voip/SKILL.md) | 推送应用内通话消息助手（VOIP）                                                   |
| [hmos-scan-kit-defaultscan](02-development/scan-kit/hmos-scan-kit-defaultscan/SKILL.md) | 接入华为 Scan Kit 默认界面扫码能力                                              |
| [hmos-scan-kit-customscan](02-development/scan-kit/hmos-scan-kit-customscan/SKILL.md) | 帮助开发者快速接入华为 Scan Kit 自定义界面扫码能力                                      |
| [hmos-window-smart-orientation](02-development/window/hmos-window-smart-orientation/SKILL.md) | 窗口旋转策略接入与智感旋转适配，覆盖策略选型、两种设置方式与存量固定策略改造 |
| [hmos-window-immersive](02-development/window/hmos-window-immersive/SKILL.md) | 窗口沉浸式效果接入，覆盖三种沉浸式方案选型、安全区域避让、系统栏显隐、挖孔避让与自由窗口标题栏沉浸 |
| [hmos-window-hover-state](02-development/window/hmos-window-hover-state/SKILL.md) | 折叠屏窗口悬停态适配，覆盖悬停监听接入、折痕避让几何、固定操作坞布局、旋转优先级与降级方案 |
| [hmos-share-kit-gestures-share](02-development/share-kit/hmos-share-kit-gestures-share/SKILL.md) | HarmonyOS 工程接入隔空传送（gesturesShare）的助手 |
| [hmos-share-kit-knock-share](02-development/share-kit/hmos-share-kit-knock-share/SKILL.md) | Share Kit 碰一碰接入助手 |

### 测试

| 技能 | 说明 |
| --- | --- |
| [hmos-arkts-syntax-checker](02-development/arkts/hmos-arkts-syntax-checker/SKILL.md) | 检查并修复 HarmonyOS 项目的 ArkTS 语法错误，自动化构建项目 |
| [hmos-local-test](03-test/hmos-local-test/SKILL.md) | 在 HarmonyOS 应用/服务开发中执行模块的 Local Test（ArkTS/JS 单元测试） |
| [hmos-instrument-test](03-test/hmos-instrument-test/SKILL.md) | 在 HarmonyOS 应用/服务开发中执行模块的 Instrument Test（包括 ArkTS/JS 和 C++ 测试） |

### 工具

| 技能 | 说明 |
| --- | --- |
| [deveco-autobugfix](04-tools/deveco/deveco-autobugfix/SKILL.md) | 自动执行鸿蒙应用 Bug 全流程修复，涵盖问题复现、根因分析、最小化代码修复、构建编译与运行验证（依赖 deveco-mcp） |
| [deveco-native-flow](04-tools/deveco/deveco-native-flow/SKILL.md) | 三端一致开发流水线（HarmonyOS/Android/iOS），支持 analyse → plan → coding → build → verify |
| [deveco-requirement-development](04-tools/deveco/deveco-requirement-development/SKILL.md) | 覆盖鸿蒙应用需求开发全链路（需求调研与 PRD、编码与联调、代码评审） |
| [deveco-studio-codelinter](04-tools/deveco/deveco-studio-codelinter/SKILL.md) | 对 HarmonyOS 项目运行 DevEco Studio CodeLinter 静态代码检查，解读检查结果并提供修复建议 |
| [deveco-studio-codescanner](04-tools/deveco/deveco-studio-codescanner/SKILL.md) | 指导使用 codescanner 命令行扫描（ArkTS 23 条 + C++ 27 条资源泄漏规则），覆盖参数与规则配置、SARIF/HTML 结果解读、错误排查与工具安装引导 |
| [deveco-studio-emulator](04-tools/deveco/deveco-studio-emulator/SKILL.md) | HarmonyOS 模拟器管理助手，专注于模拟器的创建、启动、停止、应用安装调试、场景化设备控制 |
| [deveco-studio-hilog](04-tools/deveco/deveco-studio-hilog/SKILL.md) | HarmonyOS 日志分析助手，专注于 hilog 日志查看、崩溃日志分析、日志导出 |
| [deveco-studio-hvigor](04-tools/deveco/deveco-studio-hvigor/SKILL.md) | HarmonyOS 应用构建工具助手，专注于使用 Hvigor 命令行工具构建 HarmonyOS 应用 |
| [deveco-studio-verify](04-tools/deveco/deveco-studio-verify/SKILL.md) | HarmonyOS 设备验证工具，支持多设备类型验证、应用安装、UI 自动化操作、截图验证、日志收集 |
| [hmos-module-dependency-visualizer](04-tools/modtree/hmos-module-dependency-visualizer/SKILL.md) | 模块依赖关系采集与可视化：内嵌 modtree 工具，hdc 真机一键采集或解析本地依赖日志，生成交互式 HTML 依赖图与 Markdown 报告（含循环依赖检测、扇入/扇出排行） |
| [hmos-lazy-import-analysis](04-tools/lazy-import/hmos-lazy-import-analysis/SKILL.md) | 鸿蒙应用 import lazy 懒加载分析：解析 redundant file 报告（hdc 拉取或本地 txt）定位高耗模块，脚本检测顶层代码 + agent 预判副作用，批量确认后产出带完整证据链的修改建议报告，可选 diff 预览确认后机械改写 `import lazy` |

### 发布

| 技能 | 说明 |
| --- | --- |
| [hmos-connect-api-cli-skill](05-launch-and-distribute/hmos-connect-api-cli-skill/SKILL.md) | 用内嵌 connect-api-cli 操作 AppGallery Connect：登录登出、创建应用/元服务、上传 APP、证书/Profile、ACL、真机调试安装等 |
| [app-metadata-audit-skill](05-launch-and-distribute/app-metadata-audit-skill/SKILL.md) | 上架元数据预审 |

### HMOS核心技术

| 技能 | 说明 |
| --- | --- |
| [hmos-multidevice-scenario-entry](06-solutions/multi-device/hmos-multidevice-scenario-entry/SKILL.md) | 鸿蒙多设备适配总场景入口 |
| [hmos-multidevice-avoid-areas](06-solutions/multi-device/hmos-multidevice-avoid-areas/SKILL.md) | 为系统栏、挖孔区、软键盘和沉浸式布局提供统一避让策略 |
| [hmos-multidevice-fold-state](06-solutions/multi-device/hmos-multidevice-fold-state/SKILL.md) | 为折叠屏多形态设备提供悬停适配、折痕避让、开合连续性的适配方案 |
| [hmos-multidevice-hardware-access](06-solutions/multi-device/hmos-multidevice-hardware-access/SKILL.md) | 为硬件能力检测、相机、传感器和外接设备提供统一接入与降级策略 |
| [hmos-multidevice-interaction-methods](06-solutions/multi-device/hmos-multidevice-interaction-methods/SKILL.md) | 为触摸、鼠标、键盘、手写笔等多输入方式提供交互方案和统一交互策略 |
| [hmos-multidevice-natural-orientation](06-solutions/multi-device/hmos-multidevice-natural-orientation/SKILL.md) | 为横竖屏和特殊折叠态提供统一方向判定与更新策略 |
| [hmos-multidevice-screen-window-size](06-solutions/multi-device/hmos-multidevice-screen-window-size/SKILL.md) | 为多设备布局提供断点策略、结构切换策略和窗口监听策略 |

### 质量保障

| 技能 | 说明 |
| --- | --- |
| [hmos-memory-tier-optimizer](06-solutions/performance/hmos-memory-tier-optimizer/SKILL.md) | HarmonyOS 应用低端机内存分档优化，覆盖内存采集、数据分析、分档候选方案、代码修改审查、构建安装、优化后复测、patch 与报告生成全闭环 |
| [hmos-apifault-analysis](06-solutions/stability/hmos-apifault-analysis/SKILL.md) | 定位开发者问题，回答开发者疑问、分析定位故障日志 |
| [hmos-appfreeze-analysis](06-solutions/stability/hmos-appfreeze-analysis/SKILL.md) | 自动分析 HarmonyOS / OpenHarmony Freeze（冻屏/卡死）故障日志，定位根因并输出完整证据链 |
| [hmos-cppcrash-analysis](06-solutions/stability/hmos-cppcrash-analysis/SKILL.md) | 分析 HarmonyOS/OpenHarmony 应用的 CppCrash（Native 层崩溃）故障日志，定位根因并给出修复建议 |
| [hmos-fdleak-analysis](06-solutions/stability/hmos-fdleak-analysis/SKILL.md) | 分析 FD Leak / 句柄泄漏 / 文件描述符泄漏日志，提取泄漏快照与 FdTrack 申请栈热点，依据证据链定位根因 |
| [hmos-jscrash-analysis](06-solutions/stability/hmos-jscrash-analysis/SKILL.md) | 分析 HarmonyOS/OpenHarmony 应用的 JS Crash（ArkTS/JS 层闪退）faultlogger 日志 |
| [hmos-jsleak-analysis](06-solutions/stability/hmos-jsleak-analysis/SKILL.md) | 分析 rawheap / heapsnapshot 聚类后的内存对象数据，识别疑似内存泄漏 |
| [hmos-memleak-analysis](06-solutions/stability/hmos-memleak-analysis/SKILL.md) | 分析 HarmonyOS 源代码（ArkTS、JS、C/C++）以检测内存泄漏 |
| [hmos-native-memleak-analysis](06-solutions/stability/hmos-native-memleak-analysis/SKILL.md) | 分析 HarmonyOS / OpenHarmony Native内存泄漏问题，定位泄漏根因并输出完整证据链 |
| [hmos-dfx-analyzer](06-solutions/stability/hmos-dfx-analyzer/SKILL.md) | DFX 故障分析：确定性分诊（AppFreeze / CppCrash / JSCrash）+ 非崩溃白屏 source-first 分析，HTML 报告落盘与批量合并分析，融合并替代原 hmos-runtime-fix-skill |

### 特性集成
| 技能 | 说明 |
| --- | --- |
| [hmos-app-continuity-skill](06-solutions/feature-integration/hmos-app-continuity-skill/SKILL.md) | 为现有项目快速接入应用接续能力 |

### 审查

| 技能 | 说明 |
| --- | --- |
| [hmos-skill-reviewer](.aw-skills/hmos-skill-reviewer/SKILL.md) | 审查和验证 Agent Skills 是否符合 Claude Skills 规范 |
| [hmos-skill-test-runner](.aw-skills/hmos-skill-test-runner/SKILL.md) | 加载并执行 Skill 的测试用例，逐条比对预期输出，输出测试报告 |

## 开发指南

本指南覆盖从 Fork 到合入的完整流程。

### 提交规范

提交信息遵循 Conventional Commits 约定：

| 前缀 | 用途 | 示例 |
| --- | --- | --- |
| `feat` | 新增技能/功能 | `feat: add hmos-xxx-skill` |
| `fix` | 修复问题 | `fix: 修复 xxx 问题` |
| `docs` | 文档更新 | `docs: README 补充 xxx` |
| `chore` | 杂务/维护 | `chore: 扁平化目录结构` |

### 交付件清单

每个 Skill 合入前必须提供以下交付件：

#### 必需交付件

| 交付件 | 路径 | 说明 |
| --- | --- | --- |
| **SKILL.md** | `<skill-name>/SKILL.md` | Skill 主文件，包含元数据、工作流程、检查清单等 |
| **测试用例** | `<skill-name>/test-cases/` | 覆盖主要使用场景的测试用例 |
| **测试提示词** | `<skill-name>/test-cases/test-prompts.md` | 用于验证 Skill 功能的典型提示词 |

#### 推荐交付件

| 交付件 | 路径 | 说明 |
| --- | --- | --- |
| **参考文档** | `<skill-name>/references/` | 详细的技术文档、API 参考、最佳实践等 |
| **脚本工具** | `<skill-name>/scripts/` | 自动化脚本、辅助工具 |
| **资源文件** | `<skill-name>/assets/` | 模板文件、示例代码、配置文件等 |
| **使用指南** | `<skill-name>/README.md` | 详细的使用说明和快速开始指南（可选） |

#### 测试提示词模板

每个 Skill 应在 `test-cases/test-prompts.md` 中提供测试提示词，模板如下：

```text
# 测试提示词

## 基础功能测试
### 测试场景 1：[场景名称]
**提示词**：[用户输入的提示词]
**预期输出**：
- [期望的行为或输出]

### 测试场景 2：[场景名称]
**提示词**：[用户输入的提示词]
**预期输出**：
- [期望的行为或输出]

## 边界条件测试
### 测试场景 3：[边界场景]
**提示词**：[用户输入的提示词]
**预期输出**：
- [期望的行为或输出]

## 错误处理测试
### 测试场景 4：[错误场景]
**提示词**：[用户输入的提示词]
**预期输出**：
- [期望的错误处理行为]
```

#### Skill 目录结构模板

```text
skill-name/
├── SKILL.md                    # 必需：Skill 主文件
├── test-cases/                 # 必需：测试用例目录
│   ├── test-prompts.md         # 必需：测试提示词
│   ├── test-case-1.md          # 测试用例 1
│   └── test-case-2.md          # 测试用例 2
├── references/                 # 推荐：参考文档目录
│   ├── concept.md              # 概念说明
│   ├── api-reference.md        # API 参考
│   └── best-practices.md       # 最佳实践
├── scripts/                    # 推荐：脚本工具目录
│   ├── main.py                 # 主脚本
│   └── helper.py               # 辅助脚本
└── assets/                     # 推荐：资源文件目录
    ├── templates/              # 模板文件
    └── examples/               # 示例代码
```

### 开发流程

1. **Fork 本仓库**

   ```bash
   git clone https://gitcode.com/HarmonyOS_Skills/harmonyos-agent-skills.git
   ```

2. **创建特性分支**（命名：`feature/<skill-name>` 或 `fix/<skill-name>`）：

   ```bash
   git checkout -b feature/new-skill-name
   ```

3. **开发 Skill**：
   - 遵循 [格式规范](.aw-skills/hmos-skill-reviewer/references/format-rules.md)
   - 每个技能包含 `SKILL.md`（`name` 与目录名一致，`description` 用第三人称写清触发场景）
   - 补充 `references/`（详细文档）、`test-cases/`（测试用例）

4. **本地验证**：

   ```bash
   # 运行格式检查
   .aw-skills/hmos-skill-reviewer/scripts/check-skill-format.sh your-skill/SKILL.md
   # 在 AI 助手中使用测试提示词验证功能
   ```

5. **提交更改**（遵循上方提交规范）：

   ```bash
   git add .
   git commit -m "feat: add new skill for [功能描述]"
   ```

6. **推送到你的 Fork**：

   ```bash
   git push origin feature/new-skill-name
   ```

7. **发起 Pull Request**：
   - PR 需先提交到 `main` 分支，通过后再提交到 `release` 分支；`release` 为上架发布分支（需要有正式的测试验收结论才能合入）
   - 填写 PR 模板，说明改动内容与测试情况
   - 关联相关 Issue

8. **触发智能检视门禁**：
   - 在 PR 下方评论 `start ai check` 触发智能检视流水线
   - 流水线执行两维度检视：
     - **维度一（规范性检查）**：由 `.aw-skills/hmos-skill-reviewer` 对 SKILL.md 进行格式规范性、内容职责、组织结构审查
     - **维度二（测试用例执行）**：由 `.aw-skills/hmos-skill-test-runner` 加载 skill 的 `test-cases/` 测试用例并执行，验证功能正确性
   - 两维度均通过 → 准入通过；任一不通过 → PR 被阻塞
   - 流水线通过后等待仓库管理员审查合入

## 本地检视

> **为什么需要本地检视？** 当前大量上库的 Skill 未在本地提前做检视，导致门禁流水线反复报错、PR 往返修改次数多。建议开发者在提交 PR 前先在本地完成以下两步检视，一次性通过门禁。

### 步骤一：规范性检视（hmos-skill-reviewer）

使用 Claude Code 或 opencode 加载 `.aw-skills/hmos-skill-reviewer/SKILL.md`，对你新建或修改的 Skill 执行规范性审查。

**检查什么：**

| 维度 | 检查项 |
|------|--------|
| 格式规范性 | YAML frontmatter 是否合法、name 与目录名是否一致、description 长度与人称 |
| 内容职责 | SKILL.md 是否聚焦"如何做"而非知识科普、详细内容是否已移至 references/ |
| 组织结构 | 文件是否 < 500 行、引用的 references 文件是否存在、是否避免深层嵌套 |
| 可操作性 | 是否有工作流程、检查清单、决策树 |

**快速执行：**

```bash
# 方式 1：脚本快速检查（仅格式）
.aw-skills/hmos-skill-reviewer/scripts/check-skill-format.sh your-skill/SKILL.md

# 方式 2：Python 深度验证（YAML frontmatter）
python .aw-skills/hmos-skill-reviewer/scripts/validate-frontmatter.py your-skill/SKILL.md

# 方式 3：AI 助手全量审查（格式 + 内容 + 结构 + 可操作性）
# 在 Claude Code / opencode 中加载 .aw-skills/hmos-skill-reviewer/SKILL.md
# 然后输入：审查 your-skill/SKILL.md
```

**通过标准：** 无 Critical 问题、Warning ≤ 3 个。

### 步骤二：测试用例执行（hmos-skill-test-runner）

使用 AI 助手加载 `.aw-skills/hmos-skill-test-runner/SKILL.md`，对你 Skill 的 `test-cases/` 目录执行测试用例。

**检查什么：**

| 维度 | 检查项 |
|------|--------|
| 用例发现 | `test-cases/` 目录是否存在、是否含至少一种格式的用例文件 |
| 用例解析 | 提示词是否非空、预期输出是否至少 1 条 |
| 用例执行 | 逐条发送提示词、对比实际输出与预期输出（PASS / FAIL / PARTIAL） |
| 报告输出 | 汇总统计 + 问题明细表（序号 / 严重度 / Skill / 位置 / 标题 / 说明 / 建议 / 依据 / 反馈） |

**快速执行：**

```bash
# 在 Claude Code / opencode 中操作：
# 1. 加载 .aw-skills/hmos-skill-test-runner/SKILL.md
# 2. 输入：对 your-skill 执行测试用例
# 3. 等待逐条执行完成，查看测试报告
```

**支持的用例格式：** `test-prompts.md`、`test-promts.md`、`test-case-N.md`、`test-cases.md`、`test-scene-cases.md`、通用 Markdown 兜底、JSON 三层（smoke/scene-functional/real-world）、JSON 根级自定义。

**通过标准：** 所有用例 PASS（允许 SKIP 但不允许 FAIL）。

### 本地检视 Checklist

提交 PR 前逐项确认：

- [ ] **SKILL.md 格式检查通过**（脚本 + AI 审查，无 Critical）
- [ ] **SKILL.md 行数 < 500**（超长应拆分至 references/）
- [ ] **name 与目录名一致**（全小写、连字符分隔）
- [ ] **description 包含 what + when**（第三人称、≥ 50 字符）
- [ ] **test-cases/ 目录存在**（含至少一种格式的用例文件）
- [ ] **测试用例覆盖三大类别**（基础功能 / 边界条件 / 错误处理）
- [ ] **每个用例有非空提示词**（有 prompt 可执行）
- [ ] **每个用例至少 1 条预期输出**（有 expected_output 可比对）
- [ ] **测试用例全部 PASS**（在 AI 助手中执行通过）

## License

详见 [LICENSE](LICENSE) 文件。
