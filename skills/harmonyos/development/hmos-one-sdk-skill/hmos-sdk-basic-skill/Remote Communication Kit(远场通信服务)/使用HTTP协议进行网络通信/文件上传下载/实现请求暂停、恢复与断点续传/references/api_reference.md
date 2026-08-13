# API 参考说明

本文件包含关键 API 接口的定义和说明。

## 原始文档

- **文档路径**: `D:\z00810349\APIDevice\output\md_output\harmonyos-references\系统\网络\Remote Communication Kit（远场通信服务）\ArkTS API\remote-communication-rcp.md`
- **在线链接**: [Remote Communication Kit API 参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/remote-communication-rcp)

## 核心 API 定义

### rcp.createSession

```typescript
createSession(sessionConfiguration?: SessionConfiguration): Session
```

创建 HTTP 会话。这是启动 HTTP 交互的主要方法。

**参数**:
- sessionConfiguration: SessionConfiguration（可选）- 会话配置

**返回值**: Session - 代表一个会话，用于发送 HTTP 请求

**起始版本**: API 4.1.0(11)

### Session.fetch

```typescript
fetch(request: Request): Promise<Response>
```

发送一个 HTTP 请求，并返回来自服务器的 HTTP 响应。

**参数**:
- request: Request（必填）- 要发送的请求

**返回值**: Promise<Response> - Promise 对象，返回响应对象

**需要权限**: ohos.permission.INTERNET

### Session.cancel

```typescript
cancel(requestToCancel?: Request | Request[]): void
```

取消指定或正在进行的会话请求。

**参数**:
- requestToCancel: Request | Request[]（可选）- 要取消的请求

### Session.close

```typescript
close(): void
```

关闭会话，释放资源。

### Request 类

HTTP 请求对象。

**属性**:
- url: URL - HTTP 请求的 URL
- method: HttpMethod - HTTP 方法（默认 GET）
- headers: RequestHeaders - HTTP 请求头
- content: RequestContent - HTTP 请求内容
- cookies: RequestCookies - HTTP 请求的 Cookie
- transferRange: TransferRange | TransferRange[] - HTTP 传输范围（转换为 Range 头）
- configuration: Configuration - HTTP 请求配置

**构造函数**:
```typescript
constructor(
  url: URLOrString,
  method?: HttpMethod,
  headers?: RequestHeaders,
  content?: RequestContent,
  cookies?: RequestCookies,
  transferRange?: TransferRange | TransferRange[],
  configuration?: Configuration
)
```

**起始版本**: API 4.1.0(11)

### TransferRange

设置传输数据范围。HTTP 范围请求要求服务器只将 HTTP 消息的一部分发回客户端。

**属性**:
- from: number（可选）- 传输数据的起始字节
- to: number（可选）- 传输数据的结束字节

**起始版本**: API 4.1.0(11)

**示例**:
```typescript
let transferRange: rcp.TransferRange = { from: 100, to: 200 };
```

### PausePolicy

请求的暂停策略。

**属性**:
- receiving: ReceivingPausePolicy（可选）- 设置暂停响应体接收的策略
- sending: SendingPausePolicy（可选）- 设置暂停请求体发送的策略

**起始版本**: API 5.0.0(12)

### SendingPausePolicy

暂停发送流程的策略。

**属性**:
- kind: 'timeout' - 策略类型（固定值）
- timeoutMs: number - 超时时间（毫秒），如果超过该时间应用还没有给框架数据，就会暂停请求

**起始版本**: API 5.0.0(12)

**示例**:
```typescript
const sendPolicy: rcp.SendingPausePolicy = {
  kind: 'timeout',
  timeoutMs: 1,
};
```

### ReceivingPausePolicy

接收流程的暂停策略。

类型定义: `type ReceivingPausePolicy = ReceivingPauseByCache | ReceivingPauseByTimeout`

#### ReceivingPauseByTimeout

**属性**:
- kind: 'timeout' - 策略类型
- timeoutMs: number - 超时时间（毫秒）

#### ReceivingPauseByCache

**属性**:
- kind: 'cacheSize' - 策略类型
- size: number - 缓存策略的最大值（字节），范围 [0, 1048576]

### Configuration

配置接口，包含一组配置参数。

**属性**:
- transfer: TransferConfiguration（可选）- 传输配置
- tracing: TracingConfiguration（可选）- 跟踪配置

### TransferConfiguration

传输配置接口。

**属性**:
- pausePolicy: PausePolicy（可选）- 请求暂停策略（起始版本 5.0.0(12)）
- timeout: Timeout（可选）- 超时配置

### TracingConfiguration

跟踪配置接口。

**属性**:
- verbose: boolean（可选）- 启用详细跟踪
- infoToCollect: InfoToCollect（可选）- 配置要收集的信息类型

### InfoToCollect

要收集的信息类型配置。

**属性**:
- textual: boolean - 是否收集文本调试信息

### DebugInfo

请求/响应处理调试信息的接口。

**属性**:
- type: DebugEvent - 调试信息的类型
- data: ArrayBuffer - 调试信息的数据

**起始版本**: API 4.1.0(11)

### Response

HTTP 请求的响应数据。

**属性**:
- request: Request - 对应的 HTTP 请求
- statusCode: number - HTTP 状态码
- headers: ResponseHeaders - 响应头
- body: ArrayBuffer（可选）- 响应内容（最大 50MB）
- debugInfo: DebugInfo[]（可选）- 调试信息

## 使用示例

详见 SKILL.md 中的调用流程和步骤章节。