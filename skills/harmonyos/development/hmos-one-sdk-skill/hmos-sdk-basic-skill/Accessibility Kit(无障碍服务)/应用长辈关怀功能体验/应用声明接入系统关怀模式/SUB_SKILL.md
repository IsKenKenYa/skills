---
name: hmos-accessibility-kit-eldercare-appconfig
description: 配置应用接入系统关怀模式，在module.json5声明metadata实现用户可在设置中管理关怀模式开关，支持API version 26.0.0+，适用于长辈关怀应用开发场景
---

# 应用声明接入系统关怀模式技能

## 功能描述

本技能用于配置应用接入系统关怀模式功能。通过在应用工程的 module.json5 配置文件中声明特定的 metadata，让应用可以出现在设备的"设置 > 关怀和无障碍 > 关怀模式 > 应用管理"页面，用户可以在此自由切换应用的关怀模式开关状态。

**核心功能**：
- 配置 module.json5 的 metadata 声明
- 实现应用内关怀模式与系统设置页面的同步
- 支持独立关怀模式功能应用接入系统关怀模式管理

**技术要点**：
- API版本要求：26.0.0及以上
- 配置项：metadata 的 name 和 value 字段
- 同步机制：系统关怀模式与应用内关怀模式实时同步
- 关闭系统关怀模式会同步关闭应用内关怀模式

## 使用场景

### 触发词
- "应用接入关怀模式"
- "长辈模式配置"
- "关怀模式metadata配置"
- "module.json5关怀模式"
- "系统关怀模式接入"
- "长辈关怀功能"

### 能做
- 在 module.json5 中配置 metadata 声明接入系统关怀模式
- 实现应用出现在系统关怀模式应用管理列表
- 支持用户在设置中管理应用关怀模式开关
- 实现应用内关怀模式与系统设置同步

### 绝不做
- 不处理应用内关怀模式的UI实现细节
- 不处理关怀模式的具体功能逻辑实现
- 不配置关怀模式的权限申请（除非相关）
- 不处理非HarmonyOS平台的相关配置

### 补充
- 仅适用于已实现独立关怀模式功能的应用
- 需要API version 26.0.0及以上支持
- 关怀模式功能又称：长辈模式、长辈版、关爱版、关怀版、大字版、敬老版等
- 如果用户关闭系统关怀模式，应用内关怀模式也会随之关闭

## 调用规范和规则

### 输入约束
- 应用工程路径：必须包含有效的 module.json5 文件
- API版本：必须为 26.0.0及以上
- module名称：必须为有效的 module 配置项名称
- metadata配置：必须包含 name 和 value 两个必需字段

### 执行约束
- 配置验证：执行前验证 module.json5 文件是否存在且格式正确
- metadata检查：检查是否已存在 senior_mode 相关 metadata 配置
- 最大迭代次数：配置修改最多尝试3次
- 编译验证：配置完成后需执行编译验证

### 内容约束
- 禁止修改：不修改 module.json5 中的其他配置项（除非用户明确要求）
- 禁止删除：不删除已存在的其他 metadata 配置
- 禁止推测：不推测或假想不存在的API或配置项
- 配置规范：严格按照HarmonyOS官方文档要求配置

### 降级约束
- 文件不存在：提示用户提供正确的 module.json5 路径
- API版本不满足：提示用户升级API版本或使用其他方案
- 配置失败：提供手动配置指南并建议用户检查配置文件格式
- 编译失败：提供常见编译错误解决方案

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 验证应用工程路径是否包含 module.json5 文件
2. 验证 module.json5 文件格式是否符合JSON5规范
3. 验证当前 API 版本是否为 26.0.0及以上
4. 检查 module 配置项是否存在

**参数准备**：
```typescript
// module.json5 配置参数
interface MetadataConfig {
  name: string;  // 固定值: "senior_mode"
  value: string; // 固定值: "independent_control"
}

// 配置示例
const seniorModeMetadata: MetadataConfig = {
  name: "senior_mode",
  value: "independent_control"
};
```

### 步骤2：配置 module.json5

**示例代码**：
```typescript
// module.json5 配置示例
{
  "module": {
    "name": "entry",
    "type": "entry",
    "description": "$string:module_desc",
    "mainElement": "EntryAbility",
    "deviceTypes": [
      "phone",
      "tablet"
    ],
    "deliveryWithInstall": true,
    "installationFree": false,
    "pages": "$profile:main_pages",
    "abilities": [
      {
        "name": "EntryAbility",
        "srcEntry": "./ets/entryability/EntryAbility.ts",
        "description": "$string:EntryAbility_desc",
        "icon": "$media:icon",
        "label": "$string:EntryAbility_label",
        "startWindowIcon": "$media:startWindowIcon",
        "startWindowBackground": "$color:startWindowBackground",
        "exported": true,
        "skills": [
          {
            "entities": [
              "entity.system.home"
            ],
            "actions": [
              "action.system.home"
            ]
          }
        ]
      }
    ],
    // 关怀模式 metadata 配置（新增部分）
    "metadata": [
      {
        "name": "senior_mode",
        "value": "independent_control"
      }
    ]
  }
}
```

**配置说明**：
1. 在 module 配置项中添加 metadata 数组
2. metadata 数组中添加 senior_mode 配置对象
3. name 字段固定为 "senior_mode"
4. value 字段固定为 "independent_control"
5. 如果 metadata 数组已存在其他配置，在数组末尾追加即可

### 步骤3：验证配置

**验证步骤**：
```typescript
// 验证配置示例代码
import { BusinessError } from '@kit.BasicServicesKit';

function validateMetadataConfig(moduleJsonPath: string): boolean {
  try {
    // 1. 读取 module.json5 文件
    const moduleConfig = readModuleJson5(moduleJsonPath);
    
    // 2. 验证 metadata 配置是否存在
    if (!moduleConfig.module || !moduleConfig.module.metadata) {
      console.error('metadata configuration not found');
      return false;
    }
    
    // 3. 查找 senior_mode 配置
    const seniorModeConfig = moduleConfig.module.metadata.find(
      (item: any) => item.name === 'senior_mode'
    );
    
    if (!seniorModeConfig) {
      console.error('senior_mode metadata not found');
      return false;
    }
    
    // 4. 验证配置值
    if (seniorModeConfig.value !== 'independent_control') {
      console.error('invalid senior_mode value');
      return false;
    }
    
    console.info('metadata configuration validated successfully');
    return true;
  } catch (error) {
    const err = error as BusinessError;
    console.error(`validation failed: ${err.message}`);
    return false;
  }
}
```

### 步骤4：实现关怀模式同步（可选）

如果需要实现应用内关怀模式与系统设置同步，可参考以下步骤：

**监听关怀模式状态变化**：
```typescript
import accessibility from '@ohos.accessibility';

@Entry
@Component
struct ElderCarePage {
  @State seniorModeState: boolean = false;
  
  // 关怀模式状态变化回调
  seniorModeCallback = (state: boolean) => {
    console.info(`Senior mode state changed: ${state}`);
    this.seniorModeState = state;
    // 根据状态更新应用内关怀模式UI
    this.updateElderCareUI(state);
  };
  
  aboutToAppear(): void {
    // 注册关怀模式状态监听
    accessibility.onSeniorModeStateChangeForSelf(this.seniorModeCallback);
  }
  
  aboutToDisappear(): void {
    // 取消关怀模式状态监听
    accessibility.offSeniorModeStateChangeForSelf(this.seniorModeCallback);
  }
  
  build() {
    Column() {
      Text(`关怀模式: ${this.seniorModeState ? '开启' : '关闭'}`)
        .fontSize(20)
      
      Toggle({ type: ToggleType.Switch, isOn: this.seniorModeState })
        .onChange(async (isOn: boolean) => {
          if (isOn !== this.seniorModeState) {
            this.seniorModeState = isOn;
            // 设置关怀模式状态
            await accessibility.setSeniorModeStateForSelf(isOn);
          }
        })
    }
  }
  
  updateElderCareUI(state: boolean): void {
    // 更新应用内关怀模式UI逻辑
    // 例如：调整字体大小、图标大小、布局等
  }
}
```

### 步骤5：错误处理

```typescript
// 错误处理代码
import { BusinessError } from '@kit.BasicServicesKit';

async function configureElderCareWithErrorHandling(): Promise<void> {
  try {
    // 验证配置
    const isValid = validateMetadataConfig('entry/src/main/module.json5');
    
    if (!isValid) {
      console.error('Configuration validation failed');
      return;
    }
    
    // 配置成功
    console.info('Elder care mode configuration completed successfully');
    
  } catch (error) {
    const err = error as BusinessError;
    
    switch (err.code) {
      case 401:
        console.error('Parameter error: Invalid configuration format');
        break;
      case 201:
        console.error('Permission denied: Check module permissions');
        break;
      default:
        console.error(`Unknown error: Code ${err.code}, Message ${err.message}`);
    }
  }
}
```

### 步骤6：降级处理

```typescript
// 降级处理代码
function fallbackConfiguration(): void {
  try {
    // 主配置方案：使用 metadata 配置
    configureMetadata();
  } catch (error) {
    console.warn('Metadata configuration failed, using fallback solution');
    
    // 降级方案1：提示用户手动配置
    console.info('Please manually add metadata configuration in module.json5:');
    console.info('{"name": "senior_mode", "value": "independent_control"}');
    
    // 降级方案2：使用应用内独立关怀模式开关
    // 不依赖系统关怀模式，应用内独立实现
    implementIndependentElderCareMode();
  }
}

function implementIndependentElderCareMode(): void {
  // 应用内独立实现关怀模式开关
  // 不与系统设置同步
  console.info('Implementing independent elder care mode within application');
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误，配置格式不正确 | 检查 module.json5 文件格式，确保 JSON5 规范正确 |
| 201 | 权限拒绝，无法修改配置文件 | 检查文件权限，确保有写入权限 |
| 202 | 系统能力不支持，API版本过低 | 升级到 API version 26.0.0及以上 |
| FILE_NOT_FOUND | module.json5 文件不存在 | 提供正确的应用工程路径 |
| INVALID_FORMAT | 配置文件格式错误 | 检查 JSON5 格式，修复语法错误 |
| DUPLICATE_METADATA | metadata 配置已存在 | 检查是否已配置，避免重复添加 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.AccessibilityKit": "^1.0.0"
  }
}
```

### 环境要求
- HarmonyOS SDK: API version 26.0.0及以上
- DevEco Studio: 3.1及以上版本
- Node.js: 14.x及以上版本

### 常见编译问题

**问题1：metadata 配置格式错误**
```
Error: Invalid JSON5 format in module.json5
```
**解决方法**：
- 检查 JSON5 语法是否正确
- 确保 metadata 数组格式正确
- 检查是否有多余的逗号或缺少的逗号
- 验证 JSON5 文件编码为 UTF-8

**问题2：API版本不支持**
```
Error: API version 25.0.0 does not support senior_mode
```
**解决方法**：
- 在 build-profile.json5 中升级 compileSdkVersion
- 设置 compileSdkVersion 为 26.0.0及以上
- 更新 HarmonyOS SDK 到最新版本

**问题3：编译找不到 metadata 配置**
```
Error: Cannot resolve metadata configuration
```
**解决方法**：
- 确保 metadata 配置在正确的 module 节点下
- 检查 metadata 数组是否正确闭合
- 验证 name 和 value 字段是否正确填写

**问题4：关怀模式 API 调用失败**
```
Error: accessibility.setSeniorModeStateForSelf is not defined
```
**解决方法**：
- 检查导入语句：`import accessibility from '@ohos.accessibility'`
- 或使用：`import { accessibility } from '@kit.AccessibilityKit'`
- 确保 API version 为 26.0.0及以上

## 常见问题与解决方法

### Q1：配置后应用没有出现在系统关怀模式列表中
**原因**：
- API版本不满足要求
- metadata 配置位置错误
- 应用未重新编译安装

**解决方法**：
- 检查 API version 是否为 26.0.0及以上
- 确保 metadata 配置在正确的 module.json5 文件中
- 重新编译并安装应用
- 在设备设置中刷新应用列表

### Q2：应用内关怀模式与系统设置不同步
**原因**：
- 未实现状态监听
- 未调用同步API
- 监听回调未正确处理

**解决方法**：
- 使用 `accessibility.onSeniorModeStateChangeForSelf()` 监听状态变化
- 使用 `accessibility.setSeniorModeStateForSelf()` 设置状态
- 确保回调函数正确处理状态更新
- 参考：[应用内关怀模式与系统设置同步](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/eldercare-senior-mode-description)

### Q3：关闭系统关怀模式后应用内关怀模式未关闭
**原因**：
- 未监听系统关怀模式关闭事件
- 应用内关怀模式逻辑未同步

**解决方法**：
- 监听系统关怀模式状态变化
- 在回调中同步更新应用内关怀模式状态
- 确保应用内关怀模式逻辑与系统状态一致

### Q4：应用内没有独立关怀模式开关，想跟随系统关怀模式
**原因**：
- 应用未实现独立关怀模式功能
- 需要直接跟随系统关怀模式状态

**解决方法**：
- 使用 `accessibility.isSeniorModeEnabled()` 查询系统关怀模式状态
- 使用 `accessibility.onSeniorModeStateChange()` 监听系统状态变化
- 根据系统状态调整应用UI和功能
- 参考：[获取系统关怀模式状态](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/eldercare-description)

### Q5：metadata 配置添加位置不确定
**原因**：
- module.json5 文件结构复杂
- metadata 配置位置不明确

**解决方法**：
- metadata 应配置在 module 对象的顶层
- 如果 metadata 数组已存在，追加到数组末尾
- 如果不存在，创建新的 metadata 数组
- 确保 metadata 与 abilities、pages 等配置同级

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "configuration": {
    "module": "entry",
    "metadata": {
      "name": "senior_mode",
      "value": "independent_control",
      "status": "configured"
    },
    "apiVersion": "26.0.0",
    "validation": "passed"
  },
  "message": "应用已成功接入系统关怀模式，用户可在设置中管理关怀模式开关",
  "apiUsed": [
    "accessibility.onSeniorModeStateChangeForSelf",
    "accessibility.offSeniorModeStateChangeForSelf",
    "accessibility.getSeniorModeStateForSelf",
    "accessibility.setSeniorModeStateForSelf"
  ],
  "nextSteps": [
    "实现应用内关怀模式与系统设置同步",
    "测试关怀模式开关同步功能",
    "优化应用内关怀模式UI体验"
  ]
}
```

## 参考文档

- [应用声明接入系统关怀模式](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/eldercare-appconfig)
- [应用内关怀模式与系统设置同步](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/eldercare-senior-mode-description)
- [获取系统关怀模式状态](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/eldercare-description)
- [@ohos.accessibility API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-accessibility)

## 完整示例代码

- [module.json5配置示例](assets/module_json5_example.json5)
- [关怀模式状态监听示例](assets/elder_care_monitor.ets)
- [关怀模式同步示例](assets/elder_care_sync.ets)
- [完整应用示例](assets/elder_care_app.ets)

## 测试用例

### 正向测试用例
- [metadata配置验证测试](tests/test_metadata_config.py)：验证 metadata 配置格式正确性
- [API版本验证测试](tests/test_api_version.py)：验证 API version 是否满足要求
- [关怀模式同步测试](tests/test_senior_mode_sync.py)：验证应用内关怀模式与系统设置同步

### 边界测试用例
- [最低API版本测试](tests/test_min_api_version.py)：测试 API version 26.0.0 最低要求
- [metadata数组边界测试](tests/test_metadata_array.py)：测试 metadata 数组边界情况

### 异常测试用例
- [配置文件不存在测试](tests/test_file_not_found.py)：测试 module.json5 文件不存在情况
- [配置格式错误测试](tests/test_invalid_format.py)：测试 JSON5 格式错误情况
- [权限不足测试](tests/test_permission_denied.py)：测试文件权限不足情况