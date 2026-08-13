---
name: hmos-remote-communication-kit-pause-resume
description: 实现HTTP请求暂停、恢复与断点续传功能，支持通过暂停策略控制请求发送和接收，通过TransferRange实现文件分片下载，适用于大文件下载、网络不稳定、流量控制场景，支持Phone/Tablet/Wearable设备（API 5.1.0(19)+支持TV，6.1.0(23)+支持Car）
---

# 实现请求暂停、恢复与断点续传技能

## 功能描述

本技能提供 Remote Communication Kit 的请求暂停、恢复与断点续传功能，包含两个核心场景：

1. **请求暂停与恢复**：通过配置 PausePolicy（暂停策略）实现请求发送和接收的暂停控制，包括发送暂停（SendingPausePolicy）和接收暂停（ReceivingPausePolicy），支持基于超时时间的自动暂停机制。

2. **断点续传**：通过 TransferRange（传输范围）对象控制数据截取范围，实现文件分片下载，支持暂停、继续和停止操作，确保数据完整性和一致性。

**系统能力**：SystemCapability.Collaboration.RemoteCommunication  
**起始版本**：API 4.1.0(11)，暂停策略从 API 5.0.0(12) 开始支持  
**设备支持**：Phone、2in1、Tablet、Wearable；从 API 5.1.0(19) 开始支持 TV；从 API 6.1.0(23) 开始支持 Car

## 使用场景

### 触发词
- "实现请求暂停" - 配置暂停策略控制请求发送/接收
- "实现断点续传" - 分片下载大文件，支持暂停恢复
- "HTTP请求暂停恢复" - 控制网络请求的暂停和恢复
- "文件分片下载" - 通过 TransferRange 实现分片下载
- "下载暂停继续" - 实现下载任务的暂停和继续功能
- "网络请求控制" - 控制请求发送和接收流程

### 能做
- 配置发送暂停策略（SendingPausePolicy），基于超时时间控制请求发送
- 配置接收暂停策略（ReceivingPausePolicy），基于超时或缓存大小控制数据接收
- 实现 HTTP 请求的暂停和恢复功能
- 通过 TransferRange 设置传输范围，实现文件分片下载
- 获取文件总大小并计算分片范围
- 实现下载任务的暂停、继续和停止操作
- 通过调试信息（DebugInfo）监控暂停和恢复事件

### 绝不做
- 不处理超出 Remote Communication Kit 能力范围的网络请求
- 不替代文件系统操作（需配合 fs 模块使用）
- 不处理超出设备限制的文件大小（默认最大 50MB，需流式接收超出部分）
- 不实现超出 API 版本限制的功能（暂停策略需 API 5.0.0(12)+）
- 不处理非 HTTP 协议的传输控制

### 补充
- 需要申请 ohos.permission.INTERNET 权限
- 暂停策略分为发送暂停和接收暂停两类
- TransferRange 支持单个或数组形式，可设置多个传输范围
- 断点续传需要服务器支持 HTTP Range 请求
- 调试信息需要配置 tracing.infoToCollect.textual 为 true
- 响应体默认最大 50MB，超出需使用 OnDataReceive 流式接收

## 调用规范和规则

### 输入约束
- URL 格式：必须是有效的 HTTP/HTTPS URL
- 超时时间：timeoutMs 参数范围 [1, 3600000] 毫秒
- 传输范围：from 和 to 参数必须为有效字节位置，from <= to
- 缓存大小：ReceivingPausePolicy 的 size 参数范围 [0, 1048576] 字节
- 文件大小：默认响应体最大 50MB，超出需流式接收
- Session 数量：最多可创建 1024 个 session（API 5.1.0(18)+）

### 执行约束
- 最大耗时：根据 timeoutMs 设置，建议 connectMs 5000ms，transferMs 10000ms
- 最大迭代次数：断点续传递归调用次数根据文件大小和分片大小决定
- API 调用频次：避免频繁创建和关闭 Session，建议复用 Session
- 请求暂停策略：仅在配置后生效，不配置则不暂停

### 内容约束
- 禁止生成：不生成超出 API 定义范围的参数和接口
- 禁止使用高危函数：不使用 eval、exec 等高危函数
- 禁止操作：不操作超出权限范围的文件和路径
- 代码规范：遵循 ArkTS 语法规范，使用 try-catch 捕获异常

### 降级约束
- 网络失败：捕获错误并提供重试机制或错误提示
- 文件过大：使用流式接收（OnDataReceive）替代一次性接收
- 权限不足：提示用户申请 ohos.permission.INTERNET 权限
- 服务器不支持 Range：提示用户服务器需支持 HTTP Range 请求
- API 版本不足：提示用户暂停策略需要 API 5.0.0(12) 或更高版本

## 调用流程和步骤

### 场景一：请求暂停与恢复

#### 步骤 1：导入模块和定义调试信息接口

**前置校验**：
1. 检查 API 版本是否 >= 5.0.0(12)
2. 确认设备支持（Phone/Tablet/Wearable 等）
3. 确认已申请 ohos.permission.INTERNET 权限

**代码实现**：
```typescript
import { rcp } from '@kit.RemoteCommunicationKit';
import { util } from '@kit.ArkTS';

// 定义调试信息接口
interface StringifiedDebugInfo {
  type: rcp.DebugEvent;
  data: string;
}

// 定义调试信息源类型
type DebugInfoSource = undefined | rcp.DebugInfo[] | rcp.Response;

// 定义调试信息序列化函数
function debugInfoStringify(infoSource: DebugInfoSource): StringifiedDebugInfo[] {
  const debugInfo = Array.isArray(infoSource)
    ? (infoSource as rcp.DebugInfo[])
    : (infoSource as rcp.Response).debugInfo;
  if (!debugInfo) {
    return [];
  }
  const decoder = util.TextDecoder.create('utf-8');
  return debugInfo.map((i: rcp.DebugInfo): StringifiedDebugInfo => {
    return {
      type: i.type,
      data: decoder.decodeToString(new Uint8Array(i.data)).trim(),
    };
  });
}

// 获取发送暂停和恢复事件
function getSendPausedEvents(debugInfo: DebugInfoSource) {
  return debugInfoStringify(debugInfo).filter((i) => i.data.startsWith('[[RCP]]: Pause sending'));
}

function getSendResumedEvents(debugInfo: DebugInfoSource) {
  return debugInfoStringify(debugInfo).filter((i) => i.data.startsWith('[[RCP]]: Resume sending'));
}
```

#### 步骤 2：创建 Session 和 Request 对象

**参数准备**：
```typescript
const HTTP_SERVER_POST: string = 'https://example.org/anything';

// 创建会话
const session = rcp.createSession();

// 创建请求对象
const request = new rcp.Request(HTTP_SERVER_POST);
```

#### 步骤 3：配置暂停策略和请求参数

**配置暂停策略**：
```typescript
// 定义发送暂停策略（基于超时）
const sendPolicy: rcp.SendingPausePolicy = {
  kind: 'timeout',
  timeoutMs: 1, // 1毫秒超时
};

// 定义暂停策略（包含发送暂停）
const pausePolicy: rcp.PausePolicy = {
  sending: sendPolicy, // 可选：添加 receiving 接收暂停策略
};

// 设置请求配置
request.configuration = {
  transfer: {
    pausePolicy: pausePolicy, // 设置暂停策略
  },
  tracing: {
    infoToCollect: {
      textual: true, // 启用文本调试信息收集
    },
  },
};
```

#### 步骤 4：设置请求方法和请求体

**请求参数设置**：
```typescript
// 定义请求体数据
const data = 'TestData';

// 设置请求头（Content-Length）
request.headers = {
  'Content-Length': data.length.toString(),
};

// 定义请求体内容生成函数
let isReadCompleted = false;
request.content = (maxSize) => {
  if (isReadCompleted) {
    return new ArrayBuffer(0);
  }
  isReadCompleted = true;
  const buffer = new ArrayBuffer(data.length);
  util.TextEncoder.create('utf-8').encodeIntoUint8Array(data, new Uint8Array(buffer));
  return buffer;
};

// 设置请求方法为 POST
request.method = 'POST';
```

#### 步骤 5：发送请求并获取调试信息

**发送请求**：
```typescript
async function SendingPauseByTimeout(): Promise<void> {
  try {
    // 发送请求并等待响应
    const response = await session.fetch(request);
    
    // 从响应的调试信息中获取发送暂停和恢复事件
    const pausedEvents = getSendPausedEvents(response);
    const resumedEvents = getSendResumedEvents(response);
    
    console.info(`发送暂停事件数量: ${pausedEvents.length}`);
    console.info(`发送恢复事件数量: ${resumedEvents.length}`);
    
    // 处理响应数据
    if (response.body) {
      const decoder = util.TextDecoder.create('utf-8');
      const responseBody = decoder.decodeToString(new Uint8Array(response.body));
      console.info(`响应内容: ${responseBody}`);
    }
  } catch (error) {
    console.error(`请求失败: ${JSON.stringify(error)}`);
  } finally {
    // 关闭会话
    session.close();
  }
}
```

#### 步骤 6：错误处理

**错误处理代码**：
```typescript
try {
  await SendingPauseByTimeout();
} catch (error) {
  const err = error as BusinessError;
  switch (err.code) {
    case 401:
      console.error('参数错误: 请检查请求参数');
      break;
    case 1007900994:
      console.error('会话数量达到上限: 最多1024个会话');
      break;
    default:
      console.error(`未知错误: ${err.code}, ${err.message}`);
  }
}
```

### 场景二：断点续传

#### 步骤 1：导入模块和创建 Session

**导入模块**：
```typescript
import { rcp } from '@kit.RemoteCommunicationKit';
import { BusinessError } from '@kit.BasicServicesKit';

// 创建会话
let session: rcp.Session | null = rcp.createSession();

// 定义服务器地址
const kHttpServerAddress = 'http://www.example.com/fetch';

// 创建请求
const request = new rcp.Request(kHttpServerAddress, 'GET');

// 定义变量记录下载文件的大小和传输位置
let totalSize = 0;
let lastTransferPosition = 0;
```

#### 步骤 2：获取文件总大小

**获取文件大小函数**：
```typescript
async function getTotalSize(): Promise<number> {
  // 设置传输范围为前2个字节
  request.transferRange = { from: 0, to: 1 };
  
  try {
    let rep = await session?.fetch(request);
    if (rep) {
      // 从响应头的 content-range 字段提取文件大小
      let contentRange = rep.headers['content-range'];
      if (contentRange) {
        let sizeStr = contentRange.substring(contentRange.indexOf('/') + 1, contentRange.length);
        totalSize = Number(sizeStr);
        console.info(`文件总大小: ${totalSize} 字节`);
      } else {
        console.warn('响应头未包含 content-range，服务器可能不支持 Range 请求');
        totalSize = 0;
      }
    }
  } catch (err) {
    console.error(`获取文件大小失败: code=${err.code}, data=${err.data}`);
  }
  
  return totalSize;
}
```

#### 步骤 3：实现分片下载函数

**分片下载函数**：
```typescript
function downloadTransfer(from: number, to: number): void {
  // 设置请求的数据传输范围
  request.transferRange = { from: from, to: to };
  
  session?.fetch(request).then((rep) => {
    if (rep.body) {
      // 处理响应数据（此处可保存到本地文件）
      console.info(`下载成功: ${JSON.stringify(rep.headers)}`);
      
      // 更新传输位置
      lastTransferPosition += rep.body.byteLength;
      
      // 检查是否完成下载
      if (lastTransferPosition < totalSize) {
        // 计算下一次传输范围的结束位置（每次下载100字节）
        const nextTo = Math.min(lastTransferPosition + 100, totalSize);
        
        // 递归调用继续下载下一段数据
        downloadTransfer(lastTransferPosition, nextTo);
      } else {
        console.info('下载完成');
      }
    }
  }).catch((err: BusinessError) => {
    console.error(`分片下载失败: code=${err.code}, message=${err.message}`);
  });
}
```

#### 步骤 4：实现开始下载函数

**开始下载函数**：
```typescript
async function startDownload(): Promise<void> {
  if (!session) {
    session = rcp.createSession();
  }
  
  // 传输位置归零
  lastTransferPosition = 0;
  
  // 获取要下载文件的总大小
  totalSize = await getTotalSize();
  
  if (totalSize === 0) {
    console.error('无法获取文件大小，请检查服务器是否支持 Range 请求');
    return;
  }
  
  // 计算传输范围的结束位置（首次下载100字节）
  const nextTo = Math.min(lastTransferPosition + 100, totalSize);
  
  // 开始下载
  downloadTransfer(lastTransferPosition, nextTo);
}
```

#### 步骤 5：实现暂停下载函数

**暂停下载函数**：
```typescript
function pauseDownload(): void {
  // 取消下载请求
  session?.cancel(request);
  console.info(`下载已暂停，当前位置: ${lastTransferPosition} 字节`);
}
```

#### 步骤 6：实现继续下载函数

**继续下载函数**：
```typescript
function resumeDownload(): void {
  // 检查是否已暂停
  if (lastTransferPosition === 0) {
    console.warn('下载未开始，请先调用 startDownload');
    return;
  }
  
  // 计算传输范围的结束位置
  const nextTo = Math.min(lastTransferPosition + 100, totalSize);
  
  // 继续下载
  downloadTransfer(lastTransferPosition, nextTo);
  console.info(`继续下载，从 ${lastTransferPosition} 到 ${nextTo} 字节`);
}
```

#### 步骤 7：实现停止下载函数

**停止下载函数**：
```typescript
function stopDownload(): void {
  // 取消下载请求
  session?.cancel(request);
  
  // 关闭 session
  session?.close();
  session = null;
  
  console.info('下载已停止，Session 已关闭');
}
```

#### 步骤 8：错误处理和降级

**错误处理**：
```typescript
async function downloadWithErrorHandling(): Promise<void> {
  try {
    await startDownload();
  } catch (error) {
    const err = error as BusinessError;
    
    switch (err.code) {
      case 401:
        console.error('参数错误: 请检查 URL 和请求参数');
        break;
      case 1007900994:
        console.error('会话数量达到上限');
        break;
      case 1007900001:
        console.error('网络错误: 请检查网络连接');
        // 降级方案：提示用户检查网络后重试
        console.info('建议：检查网络连接后调用 resumeDownload 继续下载');
        break;
      default:
        console.error(`下载失败: ${err.code}, ${err.message}`);
        // 降级方案：保存当前位置，支持后续恢复
        console.info(`当前位置已保存: ${lastTransferPosition} 字节，可稍后恢复`);
    }
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误 | 检查请求参数、URL 格式、transferRange 设置等 |
| 1007900994 | 会话数量达到上限 | 关闭不必要的 Session，最多支持 1024 个会话 |
| 1007900001 | 网络连接错误 | 检查网络连接，确认 URL 可访问，申请 INTERNET 权限 |
| 1007900002 | 超时错误 | 调整 timeoutMs 参数，检查服务器响应速度 |
| 1007900003 | 服务器不支持 Range | 确认服务器支持 HTTP Range 请求，否则无法实现断点续传 |
| 1007900004 | SSL/TLS 错误 | 检查证书配置，确认 HTTPS 连接安全 |
| 1007900005 | 权限不足 | 申请 ohos.permission.INTERNET 权限 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.RemoteCommunicationKit": "API 4.1.0(11)+",
    "@kit.ArkTS": "API 4.1.0(11)+",
    "@kit.BasicServicesKit": "API 4.1.0(11)+"
  }
}
```

### 环境要求
- DevEco Studio: 4.0 或更高版本
- HarmonyOS SDK: API 11 (4.1.0) 或更高版本
- 暂停策略功能: API 12 (5.0.0) 或更高版本
- 设备支持: Phone、Tablet、Wearable、2in1；API 18 (5.1.0) 支持 TV；API 23 (6.1.0) 支持 Car

### 常见编译问题

**问题1：暂停策略类型错误**
```
Type 'SendingPausePolicy' is not assignable to type 'PausePolicy'
```
**解决方法**：确保 PausePolicy 对象包含 sending 或 receiving 字段，不能直接赋值 SendingPausePolicy

**问题2：transferRange 参数错误**
```
Parameter error: transferRange must be TransferRange or TransferRange[]
```
**解决方法**：确保 transferRange 为对象 { from: number, to: number } 或数组形式

**问题3：调试信息未收集**
```
debugInfo is undefined
```
**解决方法**：配置 tracing.infoToCollect.textual = true，启用调试信息收集

**问题4：Session 数量超限**
```
Sessions number reached limit (1007900994)
```
**解决方法**：及时关闭不使用的 Session，调用 session.close() 释放资源

## 常见问题与解决方法

### Q1：如何判断服务器是否支持断点续传？
**原因**：服务器需支持 HTTP Range 请求才能实现断点续传
**解决方法**：
- 发送带 Range 头的请求，检查响应头是否包含 content-range
- 响应状态码应为 206 Partial Content（部分内容）
- 如果响应为 200 OK，则服务器可能不支持 Range 请求

### Q2：暂停策略设置后未生效？
**原因**：暂停策略需要正确配置并启用调试信息收集
**解决方法**：
- 确保 pausePolicy 包含 sending 或 receiving 字段
- 配置 tracing.infoToCollect.textual = true
- 检查 timeoutMs 参数是否设置合理（建议 >= 1ms）

### Q3：下载过程中网络中断如何处理？
**原因**：网络不稳定导致下载失败
**解决方法**：
- 捕获错误并保存当前位置 lastTransferPosition
- 等待网络恢复后调用 resumeDownload 继续
- 实现自动重试机制，设置最大重试次数

### Q4：如何处理超大文件下载？
**原因**：响应体默认最大 50MB，超出会导致内存溢出
**解决方法**：
- 使用 OnDataReceive 流式接收数据（配置 HttpEventsHandler）
- 将接收的数据实时写入本地文件
- 使用分片下载，每次下载较小的数据块

### Q5：多个并发下载如何管理？
**原因**：Session 数量有上限（1024），需要合理管理资源
**解决方法**：
- 使用单个 Session 处理多个请求
- 实现下载队列管理，避免同时创建过多 Session
- 及时关闭已完成的 Session

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "feature": "请求暂停与恢复 / 断点续传",
  "totalSize": "文件总大小（字节）",
  "transferredSize": "已传输大小（字节）",
  "pausedCount": "暂停事件数量",
  "resumedCount": "恢复事件数量",
  "apiUsed": [
    "rcp.createSession",
    "Session.fetch",
    "Session.cancel",
    "Session.close",
    "Request.transferRange",
    "Request.configuration",
    "TransferRange",
    "PausePolicy",
    "SendingPausePolicy",
    "DebugInfo"
  ]
}
```

## 参考文档

- [实现请求暂停、恢复与断点续传开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/remote-communication-pauseresume)
- [Remote Communication Kit API 参考 - rcp](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/remote-communication-rcp)

## 完整示例代码

- [请求暂停恢复示例](assets/pause_resume_example.ets)
- [断点续传示例](assets/resumable_download_example.ets)

## 测试用例

### 正向测试用例
- [测试请求暂停策略](tests/test_pause_policy.py)：验证发送暂停和恢复事件
- [测试断点续传下载](tests/test_resumable_download.py)：验证文件分片下载和恢复功能

### 边界测试用例
- [测试超大文件下载](tests/test_large_file_download.py)：验证超出 50MB 的文件处理
- [测试最小传输范围](tests/test_min_transfer_range.py)：验证 from=0, to=1 的范围设置

### 异常测试用例
- [测试服务器不支持 Range](tests/test_server_no_range.py)：验证服务器不支持断点续传的处理
- [测试网络中断恢复](tests/test_network_interrupt.py)：验证网络中断后的恢复机制
- [测试权限不足](tests/test_permission_denied.py)：验证无 INTERNET 权限的错误处理