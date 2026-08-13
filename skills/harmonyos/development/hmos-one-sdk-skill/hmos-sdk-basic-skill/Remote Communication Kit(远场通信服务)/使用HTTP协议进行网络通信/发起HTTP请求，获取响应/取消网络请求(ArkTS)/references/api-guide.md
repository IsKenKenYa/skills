# 取消网络请求开发指南

## 原始文档

本文档是从华为开发者网站获取的API开发指南文档。

**文档来源**：[取消网络请求（ArkTS）](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/remote-communication-netcancle-arkts)

## 功能概述

在远场通信服务的框架中，通过调用session.cancel方法，可以取消网络请求：

- **取消所有请求**：不指定request参数，取消所有正在进行的网络请求
- **取消指定请求**：传入需要取消的Request对象，取消特定的网络请求

开发者可以根据具体需求，灵活地管理和控制网络请求的执行。

## 约束与限制

### 设备支持

取消网络请求能力支持以下设备类型：

| 设备类型 | 支持起始版本 |
|---------|-------------|
| Phone | 4.1.0(11) |
| 2in1 | 4.1.0(11) |
| Tablet | 4.1.0(11) |
| Wearable | 4.1.0(11) |
| TV | 5.1.1(19) |
| Car | 6.1.0(23) |

## 接口说明

### API定义

```typescript
cancel(requestToCancel?: Request | Request[]): void
```

**参数说明**：

| 参数名 | 类型 | 必填 | 说明 |
|-------|------|-----|------|
| requestToCancel | Request \| Request[] | 否 | 要取消的请求或请求数组。不指定时默认取消所有请求。 |

**返回值**：void（无返回值）

### 功能说明

- **取消指定网络请求**：传入需要取消的Request对象，返回值为空
- **取消所有网络请求**：无需传入参数，直接调用，返回值为空

## 使用示例

### 示例1：取消单个请求

```typescript
// 导入模块
import { rcp } from '@kit.RemoteCommunicationKit';
import { BusinessError } from '@kit.BasicServicesKit';

// 创建会话
const session = rcp.createSession();

// 创建request1、request2
let request1 = new rcp.Request("https://www.example.com");
let request2 = new rcp.Request("https://www.example.com");

// 分别发起请求
session.fetch(request1).then((response: rcp.Response) => {
  console.info(`The response1 code is ${response.statusCode}`);
}).catch((err: BusinessError) => {
  console.error(`Request1 error code is ${err.code}, error data is ${err.data}`);
})

session.fetch(request2).then((response: rcp.Response) => {
  console.info(`The response2 code is ${response.statusCode}`);
}).catch((err: BusinessError) => {
  console.error(`Request2 error code is ${err.code}, error data is ${err.data}`);
})

// 单独取消Request1、request2
session.cancel(request1);
session.cancel(request2);
```

### 示例2：取消所有请求

```typescript
// 导入模块
import { rcp } from '@kit.RemoteCommunicationKit';
import { BusinessError } from '@kit.BasicServicesKit';

// 创建会话
const session = rcp.createSession();

// 创建request1、request2
let request1 = new rcp.Request("https://www.example.com");
let request2 = new rcp.Request("https://www.example.com");

// 分别发起请求
session.fetch(request1).then((response: rcp.Response) => {
  console.info(`The response1 code is ${response.statusCode}`);
}).catch((err: BusinessError) => {
  console.error(`Request1 error code is ${err.code}, error data is ${err.data}`);
})

session.fetch(request2).then((response: rcp.Response) => {
  console.info(`The response2 code is ${response.statusCode}`);
}).catch((err: BusinessError) => {
  console.error(`Request2 error code is ${err.code}, error data is ${err.data}`);
})

// 取消全部request
session.cancel();
```

## 最佳实践

### 1. 及时取消不需要的请求

当用户退出页面或取消操作时，应及时取消pending的网络请求，避免资源浪费。

### 2. 合理使用cancel和close

- `session.cancel()`：仅取消请求，session仍可用
- `session.close()`：关闭session，释放所有资源

建议在不再使用session时调用close()方法。

### 3. 处理取消导致的错误

取消请求会导致fetch的Promise进入reject状态，需要在catch分支中正确处理。

### 4. 批量取消的效率

取消多个请求时，建议使用Request数组参数，而不是逐个调用cancel。

## 相关文档

- [Remote Communication Kit API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/remote-communication-rcp)