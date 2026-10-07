# arkuix-migration-skeleton 测试提示词

> 运行前提：Node.js ≥ 18；modify/new 依赖 ArkUI-X SDK 的 ace 工具（API 24+；`--ace-bin` 可指定路径），测试可用 `benchmark/mock-ace/ace.js` 替身。
> 消费前置：建议先运行 arkuix-interface-scan 产出 ScanReport（`--scan-report`）。

---

## 基础功能测试

### 测试场景 1：modify 模式就地改造
**提示词**：
```
把我的 Stage 工程改造成 ArkUI-X 跨平台工程，工程路径 /path/to/project，双平台，scan-report 在 /path/to/f2-out/scan-report.json
```

**预期输出**：
- 命令形态：`node scripts/skeleton.js <工程> --scan-report <F2产物> --mode modify --platform both --yes`
- 调用 `ace modify --project` 注入 `.arkui-x/android/` 与 `.arkui-x/ios/`，INV-2 断言所选平台壳在场
- 产出 skeleton-result.json + migration-skeleton-report.md：全工程前后哈希 diff 改动清单（+/~/-）
- ace 输出中的 WARN（如 useNormalizedOHMUrl 必办删除项）沉淀至 `ace_warnings` 字段与报告"ace 迁移提示（编译前必办）"段
- 编译验证辅助（verification/）按环境就绪情况生成

### 测试场景 2：new 模式新建工程并迁入多模块源码
**提示词**：
```
新建一个 ArkUI-X 工程并把我的多模块工程源码迁进去，工程路径 /path/to/multi-module-project
```

**预期输出**：
- `--mode new`：ace create 产 scaffold 后按 build-profile `modules[].srcPath` 逐模块迁入（内容哈希校验一致）
- 名为 entry 的模块合入 `entry/`（覆盖 Hello World 模板）；业务名模块按模块名平级落位
- 迁入后回写输出工程 build-profile 注册全部模块（SD18 链路）；skeleton-result.json 含 `migrated_modules` 数组（{name, target, files}）
- build-profile 解析支持无引号键/注释/尾逗号（官方样例常态写法）

### 测试场景 3：Compile SDK 单键菜单交互（TTY 透传）
**提示词**：
```
在终端里交互式创建，告诉我每题怎么答
```

**预期输出**：
- TTY 环境进入前打印完整题面预告+建议答案（默认/默认/1(OpenHarmony)/↓方向键选最大项回车/平台应答/2(CocoaPods)）
- Compile SDK 菜单为单键消费：两位数编号（如 16）首键即被接受（1=SDK 10）——必须方向键选最大项后回车
- 纯管道 CI 场景提供 `scripts/ace-ci-create.exp` / `ace-ci-modify.exp` expect 包装（方向键 ↓×20 钳制到底部=最大项）

---

## 边界条件测试

### 测试场景 4：幂等重跑
**提示词**：
```
上次 modify 中断了，重新跑一遍会重复注入吗
```

**预期输出**：
- `.arkui-x/arkui-x-config.json5` 在场 → 检测到已 modify，跳过 ace 调用（幂等），直接产出结果
- 已 modify 工程缺少所选平台壳时报错并给出处理指引（移除 .arkui-x/ 后重跑）

### 测试场景 5：非 TTY + 真 ace 短路指引
**提示词**：
```
在 CI（无终端交互）里直接跑 new 模式
```

**预期输出**：
- 非 TTY + 真 ace：不浪费必崩的管道尝试，直接给 A/B/C 指引块（手动 create 命令+逐题建议答案 / 手动后重跑跳过 / TTY 重跑）
- 建议答案第 4 题为方向键选最大项（单键截断警示）

---

## 错误处理测试

### 测试场景 6：缺 ScanReport 拒绝
**提示词**：
```
不跑 F2 扫描，直接生成骨架
```

**预期输出**：
- `--scan-report` 缺失或 project_model=unknown → 退出码 3，引导先运行 arkuix-interface-scan

### 测试场景 7：FA 模型工程拒绝
**提示词**：
```
这是 FA 工程，帮我生成跨平台骨架
```

**预期输出**：
- ScanReport 判定 fa → 直接拒绝（FA 不支持），提示改用 Stage 工程

### 测试场景 8：零迁入显式失败
**提示词**：
```
new 模式跑完提示"未发现任何模块的 src/main"
```

**预期输出**：
- 零迁入 = 退出码 2 显式失败（不静默伪成功），列出迁入失败常见原因与下一步建议（A/B/C 指引块）
