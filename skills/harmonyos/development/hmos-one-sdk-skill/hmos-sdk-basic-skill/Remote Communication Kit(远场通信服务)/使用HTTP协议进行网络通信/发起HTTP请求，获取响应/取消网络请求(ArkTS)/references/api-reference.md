# Remote Communication Kit API参考

## API概述

本文档提供Remote Communication Kit中取消网络请求相关的API参考信息。

**完整API文档**：[remote-communication-rcp](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/remote-communication-rcp)

## 核心API

### rcp模块

**起始版本**：4.1.0(11)

**系统能力**：SystemCapability.Collaboration.RemoteCommunication

**导入模块**：
```typescript
import { rcp } from '@kit.RemoteCommunicationKit';
```

### createSession

```typescript
createSession(sessionConfiguration?: SessionConfiguration): Session
```

**功能**：创建HTTP会话，这是启动HTTP交互的主要方法。

**参数**：
- sessionConfiguration（可选）：会话配置

**返回值**：Session对象

**错误码**：
- 401：参数错误
- 1007900994：Session数量达到上限（最大1024个）

**示例**：
```typescript
const session = rcp.createSession();
```

### Session类

Session类表示可用于发出HTTP请求的通信会话。

**属性**：
- id（string，只读）：会话标识符
- configuration（SessionConfiguration，可选，只读）：会话配置

### Session.cancel

```typescript
cancel(requestToCancel?: Request | Request[]): void
```

**功能**：取消指定或正在进行的会话请求。

**起始版本**：4.1.0(11)

**系统能力**：SystemCapability.Collaboration.RemoteCommunication

**参数**：
| 参数名 | 类型 | 必填 | 说明 |
|-------|------|-----|------|
| requestToCancel | Request \| Request[] | 否 | 要取消的请求或请求数组。不指定时取消所有请求。 |

**返回值**：void

**错误码**：
- 401：参数错误

**示例**：
```typescript
import { BusinessError } from '@kit.BasicServicesKit';
import { rcp } from '@kit.RemoteCommunicationKit';

const session = rcp.createSession();
let req = new rcp.Request("http://example.com/fetch", "GET");

session.fetch(req).then((response) => {
  console.info(`Succeeded in getting the response ${response}`);
  session.cancel(req);
}).catch((err: BusinessError) => {
  console.error(`err: err code is ${err.code}, err message is ${JSON.stringify(err)}`);
});
```

### Session.fetch

```typescript
fetch(request: Request): Promise<Response>
```

**功能**：发送HTTP请求并返回响应。

**需要权限**：ohos.permission.INTERNET

**参数**：
- request（必填）：要发送的请求

**返回值**：Promise<Response>

### Session.close

```typescript
close(): void
```

**功能**：关闭会话，释放与此会话关联的资源。

**示例**：
```typescript
const session = rcp.createSession();
session.close();
```

### Request类

HTTP请求对象。

**属性**：
- id（string，只读）：请求唯一标识符
- url（URL）：HTTP请求URL
- method（HttpMethod）：HTTP方法，默认'GET'
- headers（RequestHeaders，可选）：HTTP请求头
- content（RequestContent，可选）：HTTP请求内容
- cookies（RequestCookies，可选）：HTTP请求Cookie
- transferRange（TransferRange，可选）：HTTP传输范围
- configuration（Configuration，可选）：HTTP请求配置

**构造函数**：
```typescript
constructor(url: URLOrString, method?: HttpMethod, headers?: RequestHeaders, content?: RequestContent, cookies?: RequestCookies, transferRange?: TransferRange | TransferRange[], configuration?: Configuration)
```

**示例**：
```typescript
let req = new rcp.Request("http://example.com", "POST");
```

## 类型定义

### URLOrString

```typescript
type URLOrString = URL | string
```

请求的地址类型。

### HttpMethod

HTTP请求方法类型，包括：
- 'GET'
- 'POST'
- 'PUT'
- 'DELETE'
- 'HEAD'
- 'PATCH'
- 'OPTIONS'

### RequestHeaders

```typescript
type RequestHeaders = Record<string, string>
```

HTTP请求头，键值对形式。

### RequestContent

请求内容类型：
- string
- ArrayBuffer
- RequestContentMultipart

### Response

HTTP响应对象。

**属性**：
- statusCode（number）：HTTP状态码
- headers（ResponseHeaders）：响应头
- body（ArrayBuffer，可选）：响应体
- request（Request）：关联的请求对象
- downloadedTo（DownloadedTo，可选）：下载信息

### BusinessError

业务错误对象，来自@kit.BasicServicesKit。

**属性**：
- code（number）：错误码
- message（string）：错误消息
- data（any，可选）：错误数据

## 设备支持

| 设备类型 | 支持起始版本 |
|---------|-------------|
| Phone | 4.1.0(11) |
| 2in1 | 4.1.0(11) |
| Tablet | 4.1.0(11) |
| Wearable | 4.1.0(11) |
| TV | 5.1.1(19) |
| Car | 6.1.0(23) |

## 错误码参考

### 常见错误码

| 错误码 | 说明 |
|-------|------|
| 401 | 参数错误 |
| 1007900994 | Session数量达到上限 |

完整错误码参考：[ArkTS API错误码](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/remote-communication-error-code)

## 相关链接

- [取消网络请求开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/remote-communication-netcancle-arkts)
- [Remote Communication Kit完整API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/remote-communication-rcp)