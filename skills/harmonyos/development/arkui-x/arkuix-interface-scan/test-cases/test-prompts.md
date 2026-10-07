# arkuix-interface-scan 测试提示词

> 运行前提：Node.js ≥ 18（零第三方依赖）；可选 OpenHarmony SDK（无则 `--no-sdk` 降级模式）。
> 环境变量基线：`OH_SDK_DIR`、`OHOS_SDK_HOME`、`DEVECO_SDK_HOME` 置空以复现确定性路径。

---

## 基础功能测试

### 测试场景 1：Stage 工程全量扫描（双源判定）
**提示词**：
```
扫描我的 OpenHarmony 工程接口适配性，工程路径 /path/to/stage-project，OH SDK 在 /path/to/ohos-sdk
```

**预期输出**：
- 命令形态：`node scripts/scan.js <工程> --sdk-dir <OH SDK> --out <输出目录>`
- 产出 `scan-report.json`（schema_version=1，含 inventory/adaptation 七桶）与 `migration-advice.md`
- @ohos.* 模块按 SDK @crossplatform 标记 × 规则表双源交叉判定；双源一致 → 确定桶，冲突 → unknown（宁缺毋错）
- 报告含分桶统计、unknown 归因与逐条 reason/advice

### 测试场景 2：@kit 导入展开与符号级判定
**提示词**：
```
我的工程用 @kit.ArkUI 导入了一批符号，扫描它们在 ArkUI-X 下的适配性
```

**预期输出**：
- @kit.* 命中 SDK `ets/kits/@kit.*.d.ts` 映射展开为 @ohos.* 成员模块后再判定
- 符号级条目（`@ohos.模块 | 符号`）按声明处标记判定；规则表符号级条目可覆盖模块级结论
- kit 无映射或成员缺失 → 显式 unknown（不猜测）

### 测试场景 3：C++ 工程 C-API 扫描
**提示词**：
```
扫描这个 C++ 工程的 NDK C-API 适配性，路径 /path/to/native-project
```

**预期输出**：
- 提取 `#include` 头文件路径（sysroot 相对形态，如 `multimedia/player_framework/native_avcodec_base.h`）与 `OH_*` 符号引用
- 符号归属按定义头打分；C-API 判定为规则表单源（SDK 头文件无跨平台标注）
- 规则表未覆盖的头 → unknown 并给出"人工确认"指引

---

## 边界条件测试

### 测试场景 4：无 SDK 降级模式
**提示词**：
```
我这台机器没装 OpenHarmony SDK，直接扫描 /path/to/stage-project
```

**预期输出**：
- 使用 `--no-sdk`（或环境无 SDK 自动降级）时仅规则表单源判定
- 降级状态在报告 `sdk` 段如实记录（confirmed=false），不伪造 SDK 结论

### 测试场景 5：混合 ArkTS + Native 工程
**提示词**：
```
工程里既有 ets 页面也有 entry/src/main/cpp 原生代码，一起扫
```

**预期输出**：
- @ohos/@kit 引用与 C-API 引用同报告分列；project_model 判定为 stage
- 两类引用各自进入七桶，统计互不污染

---

## 错误处理测试

### 测试场景 6：FA 模型工程拒绝
**提示词**：
```
扫描这个 FA 工程 /path/to/fa-project（根目录只有 config.json）
```

**预期输出**：
- 判定 project_model=fa → 明确拒绝并引导（退出码 3，不产出半截报告）
- 提示本 Skill 仅支持 Stage 模型

### 测试场景 7：消费方报告缺失引导
**提示词**：
```
跳过扫描直接给我迁移建议
```

**预期输出**：
- 无输入工程/参数无效 → 退出码 2 与用法说明
- 明确告知需要工程路径（以及可选 SDK 目录或 --no-sdk）
