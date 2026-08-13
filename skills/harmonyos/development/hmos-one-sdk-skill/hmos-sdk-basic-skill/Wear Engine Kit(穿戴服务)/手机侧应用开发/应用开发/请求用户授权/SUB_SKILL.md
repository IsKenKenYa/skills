---
name: hmos-wear-engine-kit-request-authorization
description: 请求Wear Engine用户授权+支持USER_STATUS/MOTION_SENSOR/HEALTH_SENSOR/DEVICE_IDENTIFIER权限+仅支持Phone/Tablet设备Stage模型API12+适用于穿戴设备数据访问前获取用户授权场景
---

# 请求用户授权技能

## 功能描述

本技能实现Wear Engine Kit的用户授权功能，用于在访问穿戴设备数据前向用户申请相应权限。通过调用wearEngine API，应用可以拉起华为账号登录和授权界面，由用户自主选择授权的数据类型。支持申请和查询两种操作：申请用户穿戴设备权限（requestAuthorization）和查询用户授权结果（getAuthorization）。

### 核心能力
- 向用户申请指定的穿戴设备数据访问权限
- 查询应用已获得的用户授权权限列表
- 处理用户授权结果和权限状态

### 支持的权限类型
- **USER_STATUS** (2)：获取用户状态权限，如穿戴设备的佩戴状态
- **MOTION_SENSOR** (3)：获取对端设备运动传感器数据权限，如加速度传感器数据
- **HEALTH_SENSOR** (4)：获取对端设备人体传感器数据权限，如心率传感器数据
- **DEVICE_IDENTIFIER** (6)：获取已连接穿戴设备的序列号

### 技术特性
- **应用场景**：手机侧应用开发，首次调用Wear Engine开放能力时执行
- **平台支持**：仅支持Phone、Tablet设备
- **模型约束**：仅可在Stage模型下使用
- **起始版本**：API 5.0.0(12)
- **系统能力**：SystemCapability.Health.WearEngine

## 使用场景

### 触发词
- "请求用户授权" - 申请Wear Engine权限
- "申请穿戴设备权限" - 获取穿戴设备数据访问权限
- "查询用户授权结果" - 查看已授权的权限列表
- "Wear Engine授权" - Wear Engine Kit权限管理
- "获取用户状态权限" - 申请佩戴状态等用户状态权限
- "获取传感器数据权限" - 申请运动或健康传感器数据权限
- "获取设备标识符权限" - 申请设备序列号权限

### 能做
- 向用户申请USER_STATUS、MOTION_SENSOR、HEALTH_SENSOR、DEVICE_IDENTIFIER权限
- 查询应用已获得的用户授权权限列表
- 处理用户授权成功或拒绝的结果
- 处理授权相关的错误和异常情况

### 绝不做
- 不处理超出Wear Engine Kit范围的权限请求
- 不在未登录华为账号的情况下强制授权
- 不绕过用户授权直接访问穿戴设备数据
- 不处理非Phone/Tablet设备的授权请求
- 不在FA模型下执行授权操作

### 补充
- 建议在首次调用Wear Engine开放能力时执行授权操作
- 用户可以自主选择授权的数据类型，可只授权部分权限
- 申请的权限必须已在申请接入Wear Engine服务中审批通过，否则会遇到错误码1008500004
- 该功能可多次调用，已授权的权限不会重复弹出授权页面
- 未登录华为账号时会先弹出登录界面，再进行授权

## 调用规范和规则

### 输入约束
- **权限类型**：必须是有效的Permission枚举值（USER_STATUS/MOTION_SENSOR/HEALTH_SENSOR/DEVICE_IDENTIFIER）
- **权限数量**：单次请求可申请一个或多个权限
- **Context类型**：必须传入包含connectServiceExtensionAbility方法的Context（如UIAbilityContext）
- **前置条件**：权限必须在申请接入Wear Engine服务中审批通过

### 执行约束
- **设备限制**：仅支持Phone、Tablet设备，其他设备返回801错误码
- **模型限制**：仅可在Stage模型下使用
- **账号要求**：用户必须登录华为账号（未登录会先弹出登录界面）
- **网络要求**：需要网络连接（网络不可用返回1008500001错误码）
- **隐私授权**：用户必须已同意运动健康隐私授权（未同意返回1008500006错误码）

### 内容约束
- **禁止操作**：禁止绕过用户授权直接访问数据
- **禁止权限**：禁止申请未在Wear Engine服务审批通过的权限
- **禁止场景**：禁止在FA模型、非Phone/Tablet设备上调用
- **禁止方式**：禁止强制用户授权或隐藏授权界面

### 降级约束
- **网络失败**：提示用户检查网络连接，稍后重试
- **账号未登录**：提示用户登录华为账号后重试
- **权限未审批**：提示开发者先申请接入Wear Engine服务
- **隐私未同意**：引导用户启动运动健康App进行隐私授权
- **用户拒绝授权**：提示用户权限必要性，提供功能受限说明

## 调用流程和步骤

### 流程图

```
开始
  ↓
检查前置条件（设备、模型、账号、隐私）
  ↓
获取AuthClient对象
  ↓
【分支1：申请授权】          【分支2：查询授权】
定义AuthorizationRequest     直接调用getAuthorization
  ↓                          ↓
调用requestAuthorization     处理返回结果
  ↓                          ↓
处理授权结果                 显示已授权权限
  ↓                          ↓
【成功】继续业务逻辑         【结束】
  ↓
【失败】错误处理和降级
  ↓
结束
```

### 步骤1：准备阶段（前置校验）

**校验清单**：
1. **设备检查**：确认当前设备为Phone或Tablet
2. **模型检查**：确认应用使用Stage模型
3. **账号检查**：确认用户已登录华为账号（可选，未登录会自动弹出登录界面）
4. **隐私检查**：确认用户已同意运动健康隐私授权（可选，未同意返回错误码）
5. **权限审批检查**：确认申请的权限已在Wear Engine服务中审批通过

**参数准备**：
```typescript
// 导入必要模块
import { wearEngine } from '@kit.WearEngine';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';

// 定义需要的权限类型
const REQUIRED_PERMISSIONS: wearEngine.Permission[] = [
  wearEngine.Permission.USER_STATUS,
  wearEngine.Permission.MOTION_SENSOR
];
```

### 步骤2：获取AuthClient对象

**API调用**：
```typescript
/**
 * 获取权限管理客户端
 * @param context - UIAbilityContext或其他支持connectServiceExtensionAbility的Context
 * @returns AuthClient - 权限管理客户端对象
 */
function getAuthClient(context: common.Context): wearEngine.AuthClient {
  try {
    const authClient: wearEngine.AuthClient = wearEngine.getAuthClient(context);
    console.info('Succeeded in getting auth client');
    return authClient;
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`Failed to get auth client. Code: ${err.code}, Message: ${err.message}`);
    throw err;
  }
}
```

**错误处理**：
```typescript
// 错误码处理
switch (error.code) {
  case 401:
    console.error('参数错误：Context参数缺失或类型错误');
    break;
  case 801:
    console.error('设备不支持：当前设备非Phone/Tablet');
    break;
  case 1008509999:
    console.error('内部错误：请检查应用签名证书、clientId配置');
    break;
}
```

### 步骤3：申请用户授权（requestAuthorization）

**示例代码**：
```typescript
/**
 * 向用户申请穿戴设备权限
 * @param authClient - 权限管理客户端
 * @param permissions - 需要申请的权限列表
 * @returns Promise<wearEngine.Permission[]> - 已授权的权限列表
 */
async function requestUserAuthorization(
  authClient: wearEngine.AuthClient,
  permissions: wearEngine.Permission[]
): Promise<wearEngine.Permission[]> {
  try {
    // 定义权限请求
    const request: wearEngine.AuthorizationRequest = {
      permissions: permissions
    };
    
    // 调用requestAuthorization
    const response: wearEngine.AuthorizationResponse = 
      await authClient.requestAuthorization(request);
    
    console.info(`Succeeded in requesting authorization. Authorized permissions: ${response.permissions}`);
    return response.permissions;
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`Failed to request authorization. Code: ${err.code}, Message: ${err.message}`);
    throw err;
  }
}
```

**完整调用示例**：
```typescript
// 在UIAbility中使用
export class EntryAbility extends UIAbility {
  async onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    // 步骤1：获取AuthClient
    const authClient = getAuthClient(this.context);
    
    // 步骤2：申请用户授权
    try {
      const authorizedPermissions = await requestUserAuthorization(
        authClient,
        [wearEngine.Permission.USER_STATUS]
      );
      
      // 检查是否获得了所需权限
      if (authorizedPermissions.includes(wearEngine.Permission.USER_STATUS)) {
        console.info('User status permission granted. Can proceed with Wear Engine APIs.');
        // 继续业务逻辑...
      } else {
        console.warn('User status permission denied. Some features will be limited.');
        // 提示用户功能受限...
      }
    } catch (error) {
      handleError(error as BusinessError);
    }
  }
}
```

### 步骤4：查询用户授权结果（getAuthorization）

**示例代码**：
```typescript
/**
 * 查询用户已授权的权限
 * @param authClient - 权限管理客户端
 * @returns Promise<wearEngine.Permission[]> - 已授权的权限列表
 */
async function getAuthorizationStatus(
  authClient: wearEngine.AuthClient
): Promise<wearEngine.Permission[]> {
  try {
    const response: wearEngine.AuthorizationResponse = 
      await authClient.getAuthorization();
    
    console.info(`Current authorized permissions: ${response.permissions}`);
    return response.permissions;
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`Failed to get authorization. Code: ${err.code}, Message: ${err.message}`);
    throw err;
  }
}
```

**使用示例**：
```typescript
// 在使用Wear Engine功能前查询授权状态
async function checkAndRequestPermission(): Promise<void> {
  const authClient = getAuthClient(this.context);
  
  // 先查询已授权的权限
  const currentPermissions = await getAuthorizationStatus(authClient);
  
  // 检查是否已有所需权限
  if (!currentPermissions.includes(wearEngine.Permission.USER_STATUS)) {
    // 未授权，向用户申请
    console.info('USER_STATUS permission not granted. Requesting authorization...');
    await requestUserAuthorization(authClient, [wearEngine.Permission.USER_STATUS]);
  } else {
    console.info('USER_STATUS permission already granted. Proceeding...');
  }
}
```

### 步骤5：错误处理和降级方案

**统一错误处理函数**：
```typescript
/**
 * 处理授权相关错误
 * @param error - BusinessError错误对象
 */
function handleAuthorizationError(error: BusinessError): void {
  switch (error.code) {
    case 401:
      console.error('参数错误：请检查AuthorizationRequest参数是否正确');
      // 降级方案：检查参数类型和必填字段
      break;
      
    case 801:
      console.error('设备不支持：当前设备非Phone/Tablet，无法使用Wear Engine');
      // 降级方案：提示用户更换设备或禁用相关功能
      break;
      
    case 1008500001:
      console.error('网络错误：网络不可用');
      // 降级方案：提示用户检查网络连接，稍后重试
      break;
      
    case 1008500004:
      console.error('应用未申请Wear Engine服务');
      // 降级方案：开发者需先在开发者联盟申请Wear Engine服务
      break;
      
    case 1008500006:
      console.error('用户未同意隐私授权');
      // 降级方案：引导用户启动运动健康App进行隐私授权
      break;
      
    case 1008500007:
      console.error('设备能力不支持');
      // 降级方案：提示用户该穿戴设备不支持此能力
      break;
      
    case 1008500008:
      console.error('账号未登录：用户未登录华为账号');
      // 降级方案：提示用户登录华为账号（会自动弹出登录界面）
      break;
      
    case 1008500009:
      console.error('账号异常：华为账号注册地非中国境内');
      // 降级方案：提示用户使用中国境内注册的华为账号
      break;
      
    case 1008509999:
      console.error('内部错误：请检查应用签名证书、clientId配置');
      // 降级方案：检查metadata中clientId配置，检查签名证书一致性
      break;
      
    default:
      console.error(`未知错误：Code ${error.code}, Message ${error.message}`);
      // 降级方案：联系华为技术支持
      break;
  }
}
```

**降级处理示例**：
```typescript
async function requestPermissionWithFallback(): Promise<void> {
  const authClient = getAuthClient(this.context);
  
  try {
    // 尝试申请权限
    const permissions = await requestUserAuthorization(
      authClient,
      [wearEngine.Permission.USER_STATUS]
    );
    
    // 成功，继续业务逻辑
    proceedWithWearEngineFeatures(permissions);
    
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    handleAuthorizationError(err);
    
    // 根据错误类型提供降级功能
    if (err.code === 1008500001) {
      // 网络错误降级方案
      showOfflineModeFeatures();
    } else if (err.code === 1008500008) {
      // 未登录降级方案
      showLoginPrompt();
    } else {
      // 其他错误降级方案
      showLimitedFeatures();
    }
  }
}
```

## 错误码说明

| 错误码 | 说明 | 可能原因 | 解决方法 |
|-------|------|---------|---------|
| 401 | 参数错误 | 1. 必选参数未传入<br>2. 参数类型错误<br>3. 参数验证失败 | 检查AuthorizationRequest参数是否正确，确保permissions字段为有效的Permission枚举数组 |
| 801 | 设备不支持 | 当前设备非Phone/Tablet | 确认设备类型，仅在Phone/Tablet上调用 |
| 1008500001 | 网络错误 | 网络未连接 | 检查网络配置，确保网络可用 |
| 1008500004 | 应用未申请服务 | 1. 申请时未配置兼容选项<br>2. 未在开发者联盟申请服务 | 在开发者联盟申请Wear Engine服务并勾选兼容选项 |
| 1008500006 | 用户未同意隐私授权 | 用户未打开运动健康App | 引导用户启动运动健康App进行隐私授权 |
| 1008500007 | 设备能力不支持 | 穿戴设备不支持对应能力 | 核查设备能力集，确认设备支持所需能力 |
| 1008500008 | 账号未登录 | 用户未登录华为账号 | 登录华为账号后重新调用（会自动弹出登录界面） |
| 1008500009 | 账号异常 | 华为账号注册地非中国境内 | 使用中国境内注册的华为账号（不含港澳台） |
| 1008509999 | 内部错误 | 1. 签名证书不一致<br>2. randomId错误<br>3. 未配置clientId<br>4. WearEngine未知错误 | 1. 检查签名证书与开发者联盟一致性<br>2. 断开重连设备<br>3. 在metadata中配置clientId<br>4. 联系华为技术支持 |

## 编译和修复问题

### 依赖声明

**oh-package.json5配置**：
```json
{
  "dependencies": {
    "@kit.WearEngine": "5.0.0(12)",
    "@kit.BasicServicesKit": "5.0.0(12)",
    "@kit.AbilityKit": "5.0.0(12)"
  }
}
```

**module.json5配置**：
```json
{
  "module": {
    "name": "entry",
    "type": "entry",
    "deviceTypes": ["phone", "tablet"],
    "abilities": [
      {
        "name": "EntryAbility",
        "srcEntry": "./ets/entryability/EntryAbility.ets",
        "launchType": "standard"
      }
    ]
  }
}
```

**metadata配置（可选，用于clientId）**：
```json
{
  "module": {
    "metadata": [
      {
        "name": "client_id",
        "value": "your_client_id_here"
      }
    ]
  }
}
```

### 环境要求
- **HarmonyOS SDK**：API 5.0.0(12)及以上
- **DevEco Studio**：5.0及以上版本
- **设备类型**：Phone、Tablet
- **运行模型**：Stage模型
- **系统能力**：SystemCapability.Health.WearEngine

### 常见编译问题

**问题1：导入wearEngine失败**
```
Error: Cannot find module '@kit.WearEngine'
```
**解决方法**：
1. 检查oh-package.json5中是否配置了`@kit.WearEngine`依赖
2. 确认HarmonyOS SDK版本为5.0.0(12)及以上
3. 执行`ohpm install`安装依赖

**问题2：Context类型错误**
```
Error: Parameter error. Incorrect parameter types.
```
**解决方法**：
1. 确认传入的Context为UIAbilityContext或其他支持connectServiceExtensionAbility的Context
2. 在UIAbility中使用`this.context`
3. 在UI组件中使用`this.getUIContext().getHostContext()`

**问题3：设备类型不支持**
```
Error: Capability not supported. (801)
```
**解决方法**：
1. 检查module.json5中deviceTypes是否包含"phone"、"tablet"
2. 确认测试设备为Phone或Tablet
3. 使用canIUse()接口检查设备能力支持

**问题4：clientId未配置导致内部错误**
```
Error: Internal error. (1008509999)
```
**解决方法**：
1. 在module.json5的metadata中配置client_id
2. 确认client_id与开发者联盟申请的一致
3. 检查应用签名证书与开发者联盟配置一致

**问题5：权限未审批导致错误**
```
Error: App has not applied for the Wear Engine service. (1008500004)
```
**解决方法**：
1. 在开发者联盟申请接入Wear Engine服务
2. 申请时勾选兼容选项
3. 确认申请的权限类型已审批通过

## 常见问题与解决方法

### Q1：为什么调用requestAuthorization没有弹出授权界面？
**原因**：
1. 用户已授权过相同权限（不会重复弹出）
2. 用户未登录华为账号（会先弹出登录界面）
3. 网络不可用导致无法拉起授权界面

**解决方法**：
- 先调用getAuthorization查询已授权权限，避免重复申请
- 确认网络连接正常
- 查看错误码，根据错误类型处理

### Q2：用户拒绝授权后如何处理？
**原因**：用户自主选择不授权部分或全部权限

**解决方法**：
- 检查AuthorizationResponse.permissions，确认哪些权限被授权
- 对于未授权的权限，向用户说明功能必要性
- 提供功能受限的使用体验或替代方案
- 可再次调用requestAuthorization引导用户授权

### Q3：如何判断设备是否支持Wear Engine能力？
**原因**：需要确认设备能力支持情况

**解决方法**：
```typescript
// 使用canIUse检查系统能力
import { canIUse } from '@kit.Syscap';

if (canIUse('SystemCapability.Health.WearEngine')) {
  console.info('Device supports Wear Engine');
} else {
  console.warn('Device does not support Wear Engine');
}
```

### Q4：为什么会出现账号异常错误（1008500009）？
**原因**：使用的华为账号注册地非中国境内（不含港澳台）

**解决方法**：
- 提示用户使用中国境内注册的华为账号
- 更换账号后重新调用授权接口
- 说明Wear Engine服务仅支持中国境内账号

### Q5：如何配置clientId避免内部错误？
**原因**：metadata中未配置clientId或配置错误

**解决方法**：
1. 在开发者联盟获取正确的clientId
2. 在module.json5的metadata中配置：
```json
{
  "module": {
    "metadata": [
      {
        "name": "client_id",
        "value": "your_actual_client_id"
      }
    ]
  }
}
```
3. 确认clientId与开发者联盟申请的一致

### Q6：用户未同意隐私授权（1008500006）如何处理？
**原因**：用户从未打开过运动健康App

**解决方法**：
- 引导用户启动运动健康App
- 在运动健康App中完成隐私授权流程
- 授权完成后重新调用Wear Engine接口

### Q7：如何处理多次申请权限的场景？
**原因**：用户可能在不同场景下申请不同权限

**解决方法**：
- 使用getAuthorization先查询已授权权限
- 只申请尚未授权的新权限
- 已授权的权限不会重复弹出授权界面
- 示例代码：
```typescript
async function requestNewPermissions(newPermissions: wearEngine.Permission[]): void {
  const authClient = getAuthClient(this.context);
  const currentPermissions = await authClient.getAuthorization();
  
  // 过滤出未授权的权限
  const permissionsToRequest = newPermissions.filter(
    perm => !currentPermissions.includes(perm)
  );
  
  if (permissionsToRequest.length > 0) {
    await authClient.requestAuthorization({ permissions: permissionsToRequest });
  }
}
```

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "operation": "requestAuthorization | getAuthorization",
  "authorized_permissions": [
    "USER_STATUS",
    "MOTION_SENSOR"
  ],
  "apiUsed": [
    "wearEngine.getAuthClient",
    "AuthClient.requestAuthorization",
    "AuthClient.getAuthorization"
  ],
  "platform": "Phone | Tablet",
  "model": "Stage",
  "apiVersion": "5.0.0(12)"
}
```

**输出字段说明**：
- **status**：执行状态（success/failed）
- **operation**：执行的操作类型
- **authorized_permissions**：已授权的权限列表
- **apiUsed**：调用的API列表
- **platform**：运行平台
- **model**：运行模型
- **apiVersion**：API版本

## 参考文档

- [请求用户授权开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/request_user_authorization)
- [Wear Engine API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/wearengine_api)
- [Wear Engine错误码参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/wearengine_api_error_code)
- [申请接入Wear Engine服务](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/wearengine_apply)

## 完整示例代码

- [ArkTS申请授权示例](assets/request_authorization_example.ets)
- [ArkTS查询授权示例](assets/get_authorization_example.ets)
- [完整授权流程示例](assets/complete_authorization_flow.ets)
- [错误处理示例](assets/error_handling_example.ets)

## 测试用例

### 正向测试用例
- [申请单个权限成功](tests/test_request_single_permission.py)：测试申请USER_STATUS权限成功场景
- [申请多个权限成功](tests/test_request_multiple_permissions.py)：测试申请多个权限成功场景
- [查询已授权权限成功](tests/test_get_authorization_success.py)：测试查询已授权权限列表成功
- [重复申请已授权权限](tests/test_request_authorized_permission.py)：测试申请已授权权限不重复弹窗

### 边界测试用例
- [申请所有支持的权限](tests/test_request_all_permissions.py)：测试申请全部支持的权限类型
- [空权限列表请求](tests/test_request_empty_permissions.py)：测试请求空权限列表的处理
- [部分权限授权](tests/test_partial_permission_grant.py)：测试用户只授权部分权限的场景

### 异常测试用例
- [参数错误处理](tests/test_parameter_error.py)：测试Context参数错误场景
- [设备不支持处理](tests/test_device_not_support.py)：测试非Phone/Tablet设备调用
- [网络错误处理](tests/test_network_error.py)：测试网络不可用场景
- [应用未申请服务](tests/test_service_not_applied.py)：测试未申请Wear Engine服务场景
- [账号未登录处理](tests/test_account_not_login.py)：测试未登录华为账号场景
- [隐私未授权处理](tests/test_privacy_not_agreed.py)：测试用户未同意隐私授权场景
- [用户拒绝授权处理](tests/test_user_reject_authorization.py)：测试用户拒绝授权场景