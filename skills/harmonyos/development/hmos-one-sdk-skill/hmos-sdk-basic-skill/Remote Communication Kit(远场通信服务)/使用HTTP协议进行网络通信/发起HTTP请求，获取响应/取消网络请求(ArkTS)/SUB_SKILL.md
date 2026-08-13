---
name: hmos-remote-communication-kit-cancel-request
description: 取消HTTP网络请求，支持取消指定Request或取消所有正在进行的请求，适用于请求中断、资源释放场景
---

# 取消网络请求技能

## 功能描述

本技能提供取消HTTP网络请求的能力，通过Remote Communication Kit的session.cancel方法实现。开发者可以取消特定的网络请求或取消所有正在进行的网络请求，灵活管理和控制网络请求的执行，适用于需要中断请求、释放资源的场景。

**核心能力**：
- 取消指定的单个网络请求
- 取消指定的多个网络请求（通过传入Request数组）
- 取消所有正在进行的网络请求（不传参数）

**适用范围**：
- 支持Phone、2in1、Tablet、Wearable设备
- 从API 5.1.1(19)开始支持TV设备
- 从API 6.1.0(23)开始支持Car设备

## 使用场景

### 触发词
- "取消网络请求"
- "中断HTTP请求"
- "停止网络请求"
- "取消Request"
- "取消所有请求"

### 能做
- 取消正在进行的HTTP请求
- 取消指定的单个或多个Request对象
- 取消session中所有正在进行的请求
- 释放网络资源和连接
- 响应用户主动中断请求的需求

### 绝不做
- 不取消已完成或已失败的请求
- 不取消其他session的请求（仅取消当前session的请求）
- 不替代session.close()方法（cancel仅取消请求，不关闭会话）
- 不在请求未发起时使用cancel

### 补充
- cancel操作是立即生效的，无法恢复已取消的请求
- 建议在请求完成后及时关闭session以释放资源
- 取消请求可能导致Promise.reject，需要正确处理错误

## 调用规范和规则

### 输入约束
- Request对象：必须是有效的rcp.Request实例，已通过session发起请求
- Request数组：数组中的每个Request必须是有效实例
- Session对象：必须是已创建的rcp.Session实例
- 无参数调用：仅取消当前session的所有请求

### 执行约束
- 最大耗时：< 100ms（立即执行）
- 执行时机：必须在请求发起后调用
- 调用频次：无限制，按需调用
- 并发安全：支持在请求进行中并发调用

### 内容约束
- 禁止生成：不生成新的Request对象，仅取消现有请求
- 禁止操作：不执行网络请求发送操作，仅执行取消操作
- 参数校验：必须校验Request对象的session归属

### 降级约束
- Request不存在：静默失败，不抛出异常（API特性）
- Session已关闭：不执行取消操作，记录警告日志
- 请求已完成：不执行取消操作，无影响
- 多次取消：第一次取消生效，后续无影响

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 确认session已创建并有效
2. 确认Request对象已发起请求（通过fetch、get、post等方法）
3. 确认需要取消的请求仍在进行中（可选，cancel对已完成请求无影响）

**参数准备**：
```typescript
// ArkTS示例 - 创建会话和请求
import { rcp } from '@kit.RemoteCommunicationKit';
import { BusinessError } from '@kit.BasicServicesKit';

// 创建会话
const session = rcp.createSession();

// 创建Request对象
let request1 = new rcp.Request("https://www.example.com");
let request2 = new rcp.Request("https://www.example.com");

// 发起请求
session.fetch(request1).then((response: rcp.Response) => {
  console.info(`The response1 code is ${response.statusCode}`);
}).catch((err: BusinessError) => {
  console.error(`Request1 error code is ${err.code}, error data is ${err.data}`);
});

session.fetch(request2).then((response: rcp.Response) => {
  console.info(`The response2 code is ${response.statusCode}`);
}).catch((err: BusinessError) => {
  console.error(`Request2 error code is ${err.code}, error data is ${err.data}`);
});
```

### 步骤2：调用API

**示例代码 - 取消指定请求**：
```typescript
// 导入必要模块
import { rcp } from '@kit.RemoteCommunicationKit';
import { BusinessError } from '@kit.BasicServicesKit';

// 取消单个网络请求
function cancelSingleRequest(session: rcp.Session, request: rcp.Request): void {
  try {
    // 校验session是否有效
    if (!session || !session.id) {
      console.warn('Session is invalid or closed');
      return;
    }
    
    // 取消指定请求
    session.cancel(request);
    console.info(`Request ${request.id} has been canceled`);
  } catch (error) {
    console.error('Cancel request failed:', error);
  }
}

// 取消多个网络请求
function cancelMultipleRequests(session: rcp.Session, requests: rcp.Request[]): void {
  try {
    // 校验session是否有效
    if (!session || !session.id) {
      console.warn('Session is invalid or closed');
      return;
    }
    
    // 校验requests数组
    if (!requests || requests.length === 0) {
      console.warn('Requests array is empty');
      return;
    }
    
    // 取消多个请求
    session.cancel(requests);
    console.info(`${requests.length} requests have been canceled`);
  } catch (error) {
    console.error('Cancel requests failed:', error);
  }
}

// 使用示例
const session = rcp.createSession();
let request1 = new rcp.Request("https://www.example.com");
let request2 = new rcp.Request("https://www.example.com");

// 发起请求后取消
session.fetch(request1);
session.fetch(request2);

// 取消单个请求
cancelSingleRequest(session, request1);

// 或取消多个请求
cancelMultipleRequests(session, [request1, request2]);
```

**示例代码 - 取消所有请求**：
```typescript
// 导入必要模块
import { rcp } from '@kit.RemoteCommunicationKit';
import { BusinessError } from '@kit.BasicServicesKit';

// 取消所有网络请求
function cancelAllRequests(session: rcp.Session): void {
  try {
    // 校验session是否有效
    if (!session || !session.id) {
      console.warn('Session is invalid or closed');
      return;
    }
    
    // 取消所有请求（不传参数）
    session.cancel();
    console.info('All requests in session have been canceled');
  } catch (error) {
    console.error('Cancel all requests failed:', error);
  }
}

// 使用示例
const session = rcp.createSession();
let request1 = new rcp.Request("https://www.example.com");
let request2 = new rcp.Request("https://www.example.com");

// 发起请求
session.fetch(request1);
session.fetch(request2);

// 取消所有请求
cancelAllRequests(session);
```

### 步骤3：错误处理

```typescript
// 错误处理代码
import { rcp } from '@kit.RemoteCommunicationKit';
import { BusinessError } from '@kit.BasicServicesKit';

async function handleRequestWithCancel(session: rcp.Session, request: rcp.Request): Promise<void> {
  try {
    // 发起请求
    const response = await session.fetch(request);
    console.info(`Request succeeded: ${response.statusCode}`);
  } catch (error) {
    const err = error as BusinessError;
    
    switch (err.code) {
      case 401:
        console.error('Parameter error: invalid request or session');
        break;
      case 1007900994:
        console.error('Sessions number reached limit');
        break;
      default:
        // 可能是取消导致的错误
        if (err.message && err.message.includes('cancel')) {
          console.warn('Request was canceled by user');
        } else {
          console.error(`Request failed: code=${err.code}, message=${err.message}`);
        }
    }
  }
}

// 使用示例
const session = rcp.createSession();
let request = new rcp.Request("https://www.example.com");

// 发起请求并设置取消条件
handleRequestWithCancel(session, request);

// 在需要时取消请求
setTimeout(() => {
  session.cancel(request);
}, 1000);
```

### 步骤4：降级处理

```typescript
// 降级处理代码
import { rcp } from '@kit.RemoteCommunicationKit';

function safeCancelRequest(session: rcp.Session | null | undefined, request?: rcp.Request | rcp.Request[]): void {
  // 降级方案1：session无效时的处理
  if (!session) {
    console.warn('Session is null or undefined, skip cancel operation');
    return;
  }
  
  try {
    // 检查session是否已关闭（通过id属性）
    if (!session.id) {
      console.warn('Session has been closed, cannot cancel requests');
      return;
    }
    
    // 降级方案2：无request参数时的处理（取消所有）
    if (!request) {
      session.cancel();
      console.info('Canceled all requests in session');
      return;
    }
    
    // 降级方案3：request数组为空时的处理
    if (Array.isArray(request) && request.length === 0) {
      console.warn('Request array is empty, skip cancel operation');
      return;
    }
    
    // 执行取消操作
    session.cancel(request);
    console.info('Cancel operation executed successfully');
  } catch (error) {
    // 降级方案4：异常时的处理
    console.error('Cancel operation failed with exception:', error);
    // 记录错误但不抛出，保证程序继续运行
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误，Request对象无效或session无效 | 检查Request对象是否正确创建，检查session是否有效 |
| 1007900994 | Session数量达到上限（最大1024个） | 关闭不需要的session以释放资源 |

**说明**：
- cancel方法本身不抛出错误码，错误主要出现在Request的fetch等方法的Promise.reject中
- 取消请求可能导致fetch等方法的Promise进入catch分支，需要正确处理
- Request不存在或已完成时，cancel静默失败，不抛出异常

## 编译和修复问题

### 依赖声明

**模块导入**：
```typescript
import { rcp } from '@kit.RemoteCommunicationKit';
import { BusinessError } from '@kit.BasicServicesKit';
```

**模块说明**：
- `@kit.RemoteCommunicationKit`：提供HTTP网络请求能力
- `@kit.BasicServicesKit`：提供BusinessError类型用于错误处理

### 环境要求
- HarmonyOS API版本：>= 4.1.0(11)
- 设备类型：Phone、2in1、Tablet、Wearable、TV(>=5.1.1(19))、Car(>=6.1.0(23))
- 开发工具：DevEco Studio >= 3.1

### 常见编译问题

**问题1：模块导入失败**
```
Error: Cannot find module '@kit.RemoteCommunicationKit'
```
**解决方法**：
- 检查DevEco Studio版本 >= 3.1
- 检查项目配置的compileSdkVersion >= 11
- 在build-profile.json5中添加依赖配置

**问题2：Request类型错误**
```
Error: Type 'Request' is not defined
```
**解决方法**：
- 使用`new rcp.Request()`创建Request对象
- 确保正确导入rcp模块

**问题3：cancel方法参数错误**
```
Error: Argument of type 'X' is not assignable to parameter of type 'Request | Request[]'
```
**解决方法**：
- 检查参数类型，必须是Request对象或Request数组
- 不能传入字符串或其他类型

## 常见问题与解决方法

### Q1：取消请求后，fetch的Promise如何处理？
**原因**：取消请求会导致fetch方法的Promise进入reject状态
**解决方法**：
- 在fetch的catch分支中判断错误是否由cancel导致
- 检查error.message是否包含'cancel'关键字
- 区分取消错误和其他网络错误

### Q2：能否取消其他session的请求？
**原因**：cancel方法仅能取消当前session中的请求
**解决方法**：
- 仅对当前session的request执行cancel
- 需要取消其他session的请求时，需调用对应session的cancel方法

### Q3：取消请求后是否需要关闭session？
**原因**：cancel仅取消请求，不释放session资源
**解决方法**：
- cancel后根据业务需求决定是否关闭session
- 如果不再使用session，建议调用session.close()释放资源
- 如果继续发起新请求，可以保持session打开

### Q4：能否恢复已取消的请求？
**原因**：cancel是立即生效的，无法恢复
**解决方法**：
- 无法恢复已取消的请求
- 需要重新创建Request并发起请求
- 建议在取消前确认业务需求

### Q5：如何判断请求是否仍在进行中？
**原因**：API不提供请求状态的查询接口
**解决方法**：
- 通过fetch的Promise状态判断（pending表示进行中）
- 自定义请求状态管理（记录Request和Promise的映射）
- cancel对已完成请求无影响，可安全调用

## 输出结果报告

执行取消请求后输出以下信息：

```json
{
  "status": "success",
  "operation": "cancel",
  "session_id": "<session.id>",
  "canceled_requests": [
    "<request1.id>",
    "<request2.id>"
  ],
  "cancel_type": "single | multiple | all",
  "message": "请求已成功取消",
  "apiUsed": [
    "rcp.createSession",
    "rcp.Request",
    "session.cancel"
  ]
}
```

**说明**：
- `status`: 操作状态（success/failed）
- `operation`: 操作类型（cancel）
- `session_id`: 会话标识符
- `canceled_requests`: 已取消的请求ID列表
- `cancel_type`: 取消类型（single单个/multiple多个/all所有）
- `apiUsed`: 使用到的API列表

## 参考文档

- [取消网络请求开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/remote-communication-netcancle-arkts)
- [Remote Communication Kit API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/remote-communication-rcp)

## 完整示例代码

- [ArkTS完整示例 - 取消单个请求](assets/cancel-single-request.ets)
- [ArkTS完整示例 - 取消多个请求](assets/cancel-multiple-requests.ets)
- [ArkTS完整示例 - 取消所有请求](assets/cancel-all-requests.ets)
- [ArkTS完整示例 - 完整流程](assets/cancel-request-full-example.ets)

## 测试用例

### 正向测试用例
- [取消单个正在进行的请求](tests/test_cancel_single_request.ets)：验证取消单个Request的功能
- [取消多个正在进行的请求](tests/test_cancel_multiple_requests.ets)：验证取消Request数组的功能
- [取消所有正在进行的请求](tests/test_cancel_all_requests.ets)：验证无参数取消所有请求的功能

### 边界测试用例
- [取消已完成的请求](tests/test_cancel_completed_request.ets)：验证取消已完成请求的处理
- [取消不存在的请求](tests/test_cancel_nonexistent_request.ets)：验证取消不存在请求的处理
- [取消空数组请求](tests/test_cancel_empty_array.ets)：验证取消空Request数组的处理
- [多次取消同一请求](tests/test_cancel_duplicate.ets)：验证多次取消同一请求的处理

### 异常测试用例
- [session已关闭时取消请求](tests/test_cancel_after_session_close.ets)：验证session关闭后取消请求的处理
- [session为null时取消请求](tests/test_cancel_null_session.ets)：验证session为null时的处理
- [Request为null时取消请求](tests/test_cancel_null_request.ets)：验证Request为null时的处理
- [取消请求后继续fetch](tests/test_cancel_and_fetch_again.ets)：验证取消后重新发起请求的功能