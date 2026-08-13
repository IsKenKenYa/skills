---
name: hmos-account-kit-minorsprotection-app-turnoff
description: 验证家长身份并关闭应用的未成年人模式，支持系统未成年人模式开启状态下单独关闭应用未成年人模式，需要密码验证通过，适用于需要暂时关闭应用未成年人保护功能的场景
---

# 关闭应用的未成年人模式技能

## 功能描述

本技能实现HarmonyOS应用内关闭未成年人模式的功能。当系统未成年人模式已开启时，应用可调用此技能验证家长身份密码，验证通过后可关闭应用的未成年人模式，而系统未成年人模式仍保持开启状态。开发者需要在应用侧记录单独关闭状态（userTurnOffFlag），便于后续与系统重新联动。

**核心能力**：
- 验证未成年人模式密码
- 获取系统未成年人模式状态和年龄段信息
- 订阅系统未成年人模式公共事件
- 管理应用内未成年人模式状态

**技术特点**：
- 需要在页面或自定义组件生命周期内调用
- 需要系统未成年人模式已开启
- 支持同步/异步两种获取模式状态的方式
- 建议缓存未成年人模式状态，避免重复查询

**版本要求**：
- 起始版本：5.0.0(12)
- 系统能力：SystemCapability.AuthenticationServices.HuaweiID.MinorsProtection
- 模型约束：仅可在Stage模型下使用
- 元服务API：支持在元服务中使用

## 使用场景

### 触发词
- "关闭应用的未成年人模式"
- "关闭应用未成年人模式"
- "验证家长密码关闭未成年人模式"
- "暂时关闭应用的未成年人保护"
- "应用内关闭未成年人模式"

### 能做
- 在系统未成年人模式已开启时，验证家长密码后关闭应用的未成年人模式
- 获取系统未成年人模式状态（开启/关闭）和年龄段信息
- 订阅系统未成年人模式开启/关闭事件，实时感知状态变化
- 在应用侧记录和管理单独关闭状态标记
- 判断当前设备环境是否支持未成年人模式

### 绝不做
- 不在未成年人模式未开启时调用验证接口
- 不在页面或自定义组件生命周期外调用验证接口
- 不在半模态、弹出框、子窗口等非全页面组件中使用UIExtensionContext调用
- 不关闭系统的未成年人模式（仅关闭应用的未成年人模式）
- 不绕过密码验证直接关闭未成年人模式

### 补充
- 当前场景为关闭未成年人模式的推荐方案，相较于关闭系统的未成年人模式更为灵活
- 验证接口返回错误码1009900002表示未成年人模式未开启，需先检查模式状态
- 当设备处于开机未解锁状态下，getMinorsProtectionInfoSync返回的minorsProtectionMode字段为false
- 如开发者重新开启USB调试开关后，发现hilog日志未恢复，可执行"hdc shell hilog -G 16M"扩大日志缓存区

## 调用规范和规则

### 输入约束
- Context上下文：必须是UIAbilityContext或UIExtensionContext
- 元服务仅支持UIAbilityContext
- 不支持在半模态、弹出框、子窗口等非全页面组件中使用UIExtensionContext
- 调用验证接口前必须确认未成年人模式已开启

### 执行约束
- 最大验证等待时间：由用户操作决定
- 异步接口调用：使用Promise异步回调
- 必须在页面或自定义组件生命周期内调用验证接口
- 建议缓存未成年人模式状态，避免重复查询
- 需订阅系统未成年人模式公共事件以刷新状态

### 内容约束
- 禁止伪造或绕过密码验证流程
- 禁止在未成年人模式未开启时调用验证接口
- 禁止在非页面生命周期调用验证接口
- 禁止使用高危函数操作敏感数据
- 必须在应用侧维护单独关闭状态标记

### 降级约束
- 未成年人模式未开启：提示用户先开启系统未成年人模式
- 设备不支持未成年人模式：提示用户当前设备环境不支持
- 服务不可用：提示用户稍后重试或使用其他验证方式
- 用户取消操作：正常返回，不执行后续关闭流程
- 密码验证失败：提示用户重新输入密码

## 调用流程和步骤

### 步骤1：开发准备

**前置校验**：
1. 配置签名和指纹，完成签名信息配置
2. 确认无需配置公钥指纹、Client ID，无需申请账号权限
3. 确认系统能力支持：SystemCapability.AuthenticationServices.HuaweiID.MinorsProtection
4. 确认API版本：5.0.0(12)及以上

**参数准备**：
```typescript
import { minorsProtection } from '@kit.AccountKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';

// 应用侧维护的单独关闭标记
let userTurnOffFlag: boolean = false;
```

### 步骤2：订阅系统未成年人模式事件

**订阅开启事件**：
```typescript
import { commonEventManager } from '@kit.BasicServicesKit';

// 订阅未成年人模式开启事件
const onSubscriber = await commonEventManager.subscribeCommonEvent(
  {
    events: [commonEventManager.Support.COMMON_EVENT_MINORSMODE_ON]
  },
  (err, data) => {
    if (err) {
      hilog.error(0x0000, 'testTag', `Failed to subscribe COMMON_EVENT_MINORSMODE_ON. Code: ${err.code}`);
      return;
    }
    hilog.info(0x0000, 'testTag', 'Succeeded in subscribing COMMON_EVENT_MINORSMODE_ON');
    // 未成年人模式已开启，根据业务逻辑处理
    userTurnOffFlag = false; // 重置单独关闭标记
  }
);
```

**订阅关闭事件**：
```typescript
// 订阅未成年人模式关闭事件
const offSubscriber = await commonEventManager.subscribeCommonEvent(
  {
    events: [commonEventManager.Support.COMMON_EVENT_MINORSMODE_OFF]
  },
  (err, data) => {
    if (err) {
      hilog.error(0x0000, 'testTag', `Failed to subscribe COMMON_EVENT_MINORSMODE_OFF. Code: ${err.code}`);
      return;
    }
    hilog.info(0x0000, 'testTag', 'Succeeded in subscribing COMMON_EVENT_MINORSMODE_OFF');
    // 未成年人模式已关闭，应用需跟随系统状态
    userTurnOffFlag = false; // 重置单独关闭标记
  }
);
```

### 步骤3：获取系统未成年人模式状态

**同步方式获取**：
```typescript
function getMinorsModeStatusSync(): void {
  if (!canIUse('SystemCapability.AuthenticationServices.HuaweiID.MinorsProtection')) {
    hilog.info(0x0000, 'testTag', 'The current device does not support minors protection');
    return;
  }
  
  try {
    // 查询是否支持系统未成年人模式
    if (!minorsProtection.supportMinorsMode()) {
      hilog.info(0x0000, 'testTag', 'The current device environment does not support minors mode');
      return;
    }
    
    // 同步获取未成年人模式信息
    const minorsProtectionInfo = minorsProtection.getMinorsProtectionInfoSync();
    const minorsProtectionMode = minorsProtectionInfo.minorsProtectionMode;
    
    hilog.info(0x0000, 'testTag', `Minors protection mode: ${minorsProtectionMode}`);
    
    // 如有频繁使用，需缓存未成年人模式开启状态
    if (minorsProtectionMode) {
      // 未成年人模式已开启，获取年龄段信息
      const ageGroup = minorsProtectionInfo.ageGroup;
      if (ageGroup) {
        hilog.info(0x0000, 'testTag', `Age group: [${ageGroup.lowerAge}, ${ageGroup.upperAge})`);
        // 根据年龄段刷新内容展示，建议缓存年龄段信息
      }
    } else {
      // 未成年人模式未关闭，重置单独关闭标记
      userTurnOffFlag = false;
    }
  } catch (error) {
    hilog.error(0x0000, 'testTag', 
      `Failed to get minors protection info. Code: ${error.code}, Message: ${error.message}`);
  }
}
```

**异步方式获取**：
```typescript
async function getMinorsModeStatusAsync(): Promise<void> {
  if (!canIUse('SystemCapability.AuthenticationServices.HuaweiID.MinorsProtection')) {
    hilog.info(0x0000, 'testTag', 'The current device does not support minors protection');
    return;
  }
  
  try {
    // 查询是否支持系统未成年人模式
    if (!minorsProtection.supportMinorsMode()) {
      hilog.info(0x0000, 'testTag', 'The current device environment does not support minors mode');
      return;
    }
    
    // 异步获取未成年人模式信息
    const minorsProtectionInfo = await minorsProtection.getMinorsProtectionInfo();
    const minorsProtectionMode = minorsProtectionInfo.minorsProtectionMode;
    
    hilog.info(0x0000, 'testTag', `Minors protection mode: ${minorsProtectionMode}`);
    
    // 如有频繁使用，需缓存未成年人模式开启状态
    if (minorsProtectionMode) {
      // 未成年人模式已开启，获取年龄段信息
      const ageGroup = minorsProtectionInfo.ageGroup;
      if (ageGroup) {
        hilog.info(0x0000, 'testTag', `Age group: [${ageGroup.lowerAge}, ${ageGroup.upperAge})`);
        // 根据年龄段刷新内容展示，建议缓存年龄段信息
      }
    } else {
      // 未成年人模式未关闭，重置单独关闭标记
      userTurnOffFlag = false;
    }
  } catch (error) {
    hilog.error(0x0000, 'testTag', 
      `Failed to get minors protection info. Code: ${error.code}, Message: ${error.message}`);
  }
}
```

### 步骤4：验证家长身份并关闭应用未成年人模式

**验证密码并关闭**：
```typescript
async function verifyAndTurnOffAppMinorsMode(context: common.Context): Promise<boolean> {
  if (!canIUse('SystemCapability.AuthenticationServices.HuaweiID.MinorsProtection')) {
    hilog.info(0x0000, 'testTag', 'The current device does not support minors protection');
    return false;
  }
  
  try {
    // 查询是否支持系统未成年人模式
    if (!minorsProtection.supportMinorsMode()) {
      hilog.info(0x0000, 'testTag', 'The current device environment does not support minors mode');
      return false;
    }
    
    // 先获取未成年人模式状态，确认已开启
    const minorsProtectionInfo = minorsProtection.getMinorsProtectionInfoSync();
    if (!minorsProtectionInfo.minorsProtectionMode) {
      hilog.warn(0x0000, 'testTag', 'Minors mode is not enabled, cannot verify credential');
      return false;
    }
    
    // 调用验证接口，拉起密码验证页面
    const verifyResult = await minorsProtection.verifyMinorsProtectionCredential(context);
    
    hilog.info(0x0000, 'testTag', `Verify result: ${verifyResult}`);
    
    if (verifyResult) {
      // 验证成功，关闭应用的未成年人模式
      userTurnOffFlag = true; // 记录单独关闭标记
      hilog.info(0x0000, 'testTag', 'App minors mode turned off successfully');
      return true;
    } else {
      // 验证失败
      hilog.warn(0x0000, 'testTag', 'Password verification failed');
      return false;
    }
  } catch (error) {
    const businessError = error as BusinessError<Object>;
    handleVerifyError(businessError);
    return false;
  }
}

// 错误处理函数
function handleVerifyError(error: BusinessError<Object>): void {
  hilog.error(0x0000, 'testTag', `Failed to verify. Code: ${error.code}, message: ${error.message}`);
  
  switch (error.code) {
    case 1009900002:
      hilog.error(0x0000, 'testTag', 'Minors mode is not enabled');
      // 提示用户先开启系统未成年人模式
      break;
    case 1009900003:
      hilog.error(0x0000, 'testTag', 'User canceled the operation');
      // 用户取消操作，正常返回
      break;
    case 401:
      hilog.error(0x0000, 'testTag', 'Parameter error');
      // 检查参数是否正确
      break;
    case 1001502009:
      hilog.error(0x0000, 'testTag', 'Internal error');
      // 提示用户稍后重试
      break;
    default:
      hilog.error(0x0000, 'testTag', 'Unknown error occurred');
  }
}
```

### 步骤5：应用启动时恢复状态

**恢复未成年人模式状态**：
```typescript
function restoreMinorsModeStatusOnStartup(): void {
  if (!canIUse('SystemCapability.AuthenticationServices.HuaweiID.MinorsProtection')) {
    return;
  }
  
  try {
    if (!minorsProtection.supportMinorsMode()) {
      return;
    }
    
    const minorsProtectionInfo = minorsProtection.getMinorsProtectionInfoSync();
    const minorsProtectionMode = minorsProtectionInfo.minorsProtectionMode;
    
    if (userTurnOffFlag) {
      // 用户之前单独关闭了应用的未成年人模式，保持关闭状态
      hilog.info(0x0000, 'testTag', 'App minors mode remains off as user requested');
    } else {
      // 应用需与系统进行联动
      if (minorsProtectionMode) {
        // 系统未成年人模式已开启，应用也开启
        hilog.info(0x0000, 'testTag', 'Syncing with system: minors mode is on');
        // 根据年龄段信息展示适龄内容
        const ageGroup = minorsProtectionInfo.ageGroup;
        if (ageGroup) {
          hilog.info(0x0000, 'testTag', `Displaying content for age group: [${ageGroup.lowerAge}, ${ageGroup.upperAge})`);
        }
      } else {
        // 系统未成年人模式已关闭，应用也关闭
        hilog.info(0x0000, 'testTag', 'Syncing with system: minors mode is off');
      }
    }
  } catch (error) {
    hilog.error(0x0000, 'testTag', 
      `Failed to restore minors mode status. Code: ${error.code}, Message: ${error.message}`);
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 1009900002 | 未成年人模式未开启 | 调用验证接口前，先检查未成年人模式是否已开启 |
| 1009900003 | 用户取消操作 | 正常处理，不执行后续关闭流程 |
| 401 | 参数错误 | 检查Context参数是否正确传入 |
| 1001502009 | 内部错误 | 提示用户稍后重试 |
| 1009900007 | 不支持的账号 | 检查当前登录的账号类型 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.AccountKit": "^5.0.0",
    "@kit.PerformanceAnalysisKit": "^5.0.0",
    "@kit.BasicServicesKit": "^5.0.0"
  }
}
```

### 环境要求
- HarmonyOS SDK：5.0.0(12)及以上
- DevEco Studio：最新版本
- 模型：Stage模型
- 系统能力：SystemCapability.AuthenticationServices.HuaweiID.MinorsProtection

### 常见编译问题

**问题1：系统能力检查失败**
```
Error: SystemCapability 'SystemCapability.AuthenticationServices.HuaweiID.MinorsProtection' not found
```
**解决方法**：确保HarmonyOS SDK版本为5.0.0(12)及以上，并在代码中使用canIUse进行系统能力检查

**问题2：导入模块失败**
```
Error: Cannot find module '@kit.AccountKit'
```
**解决方法**：检查项目依赖配置，确保已添加@kit.AccountKit依赖

**问题3：Context参数类型错误**
```
Error: Parameter error. Incorrect parameter types.
```
**解决方法**：确保传入的Context参数为UIAbilityContext或UIExtensionContext，且在页面或自定义组件生命周期内调用

**问题4：hilog日志未显示**
```
Warning: hilog logs not visible in DevEco Studio
```
**解决方法**：执行"hdc shell hilog -G 16M"扩大hilog日志缓存区，或检查日志过滤设置

## 常见问题与解决方法

### Q1：未成年人模式未开启时调用验证接口会怎样？
**原因**：验证接口需要在未成年人模式已开启状态下调用
**解决方法**：
- 调用验证接口前，先使用getMinorsProtectionInfoSync或getMinorsProtectionInfo检查未成年人模式状态
- 如果未成年人模式未开启，提示用户先开启系统未成年人模式
- 订阅系统未成年人模式开启事件，实时感知状态变化

### Q2：用户取消密码验证后如何处理？
**原因**：用户主动取消操作会返回错误码1009900003
**解决方法**：
- 正常处理取消操作，不视为错误
- 不执行后续的关闭应用未成年人模式流程
- 可根据业务需求提示用户操作已取消

### Q3：如何判断当前设备是否支持未成年人模式？
**原因**：部分设备或账号类型不支持未成年人模式
**解决方法**：
- 调用supportMinorsMode()方法判断当前设备环境是否支持
- 登录海外华为账号、隐私空间会返回false
- 其他场景返回true

### Q4：如何维护应用内未成年人模式的单独关闭状态？
**原因**：需要记录用户是否主动关闭了应用的未成年人模式
**解决方法**：
- 在应用侧维护userTurnOffFlag标记，记录用户是否主动关闭
- 应用重新启动时，查询userTurnOffFlag：
  - 为True：保持应用的未成年人模式为关闭状态
  - 为False：应用需与系统进行联动
- 当系统未成年人模式关闭或订阅到关闭事件时，重置标记为false

### Q5：在半模态、弹出框等非全页面组件中能否调用验证接口？
**原因**：验证接口需要在全页面组件的生命周期内调用
**解决方法**：
- 验证接口不支持在半模态、弹出框、子窗口等非全页面组件中使用UIExtensionContext调用
- 必须在全页面组件中使用UIAbilityContext或UIExtensionContext调用
- 建议在页面或自定义组件的生命周期内调用

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "action": "turn_off_app_minors_mode",
  "userTurnOffFlag": true,
  "verifyResult": true,
  "apiUsed": [
    "supportMinorsMode",
    "getMinorsProtectionInfoSync",
    "verifyMinorsProtectionCredential"
  ],
  "systemMinorsMode": true,
  "appMinorsMode": false,
  "message": "应用未成年人模式已关闭，系统未成年人模式保持开启"
}
```

## 参考文档

- [API开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/account-appself-turn-off-minorsprotection)
- [API参考说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/account-api-minorsprotection)

## 完整示例代码

- [ArkTS示例](assets/example_minors_protection_turnoff.ets)

## 测试用例

### 正向测试用例
- [正常关闭应用未成年人模式](tests/test_positive.py)：未成年人模式已开启，密码验证通过，成功关闭应用未成年人模式
- [同步获取模式状态](tests/test_positive.py)：成功同步获取未成年人模式状态和年龄段信息
- [异步获取模式状态](tests/test_positive.py)：成功异步获取未成年人模式状态和年龄段信息

### 边界测试用例
- [设备不支持未成年人模式](tests/test_boundary.py)：调用supportMinorsMode返回false的场景
- [未成年人模式未开启](tests/test_boundary.py)：在未成年人模式未开启时调用验证接口返回错误码1009900002
- [设备开机未解锁](tests/test_boundary.py)：开机未解锁状态下getMinorsProtectionInfoSync返回minorsProtectionMode为false

### 异常测试用例
- [用户取消验证](tests/test_exception.py)：用户取消密码验证操作，返回错误码1009900003
- [参数错误](tests/test_exception.py)：Context参数类型错误或未传入，返回错误码401
- [内部错误](tests/test_exception.py)：服务内部错误，返回错误码1001502009