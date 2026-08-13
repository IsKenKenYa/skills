---
name: hmos-remote-communication-kit-file-transfer-fast
description: 实现基于HTTP协议的文件上传下载功能，支持单个文件和目录的快速传输，需要ohos.permission.INTERNET权限，支持Phone/2in1/Tablet/Wearable/TV/Car设备（5.1.1(19)起支持TV，6.1.0(23)起支持Car），适用于应用文件上传、图片下载、文档传输等场景
---

# 快速实现文件上传下载技能

## 功能描述

本技能基于Remote Communication Kit和Core File Kit实现文件、目录、对象的快速上传和下载功能。Remote Communication Kit提供HTTP远程通信能力，Core File Kit提供高效的文件处理能力，两者结合可实现高性能的文件传输操作。

**核心能力**：
- HTTP协议文件下载到本地目录
- HTTP协议文件上传到远程服务器
- 支持文件夹和单文件两种传输方式
- 支持传输超时、安全验证等配置

**技术特点**：
- 使用Promise异步回调机制
- 支持传输进度监控
- 支持自定义安全配置和超时设置
- 支持大文件分片传输

## 使用场景

### 触发词
- "文件上传"
- "文件下载"
- "上传文件到服务器"
- "从URL下载文件"
- "HTTP文件传输"
- "快速上传下载"

### 能做
- 从指定URL下载文件到本地目录
- 将本地文件上传到远程服务器
- 配置传输超时和连接参数
- 配置安全验证和TLS选项
- 处理文件路径检查和清理
- 监控传输进度和状态

### 绝不做
- 不处理非HTTP/HTTPS协议的文件传输（如FTP、SFTP）
- 不实现文件压缩或解压缩功能
- 不处理文件格式转换
- 不实现断点续传功能（需要使用其他API）
- 不处理文件加密或解密

### 补充
- 需要ohos.permission.INTERNET权限
- 如使用PathPreference的'cellular'模式，额外需要ohos.permission.GET_NETWORK_INFO权限
- 建议传输完成后及时关闭Session释放资源
- 从5.1.0(18)版本起，可创建的Session实例数量从16个增加到1024个

## 调用规范和规则

### 输入约束
- URL格式：必须是有效的HTTP/HTTPS URL字符串
- 文件路径：必须使用应用沙箱路径，路径长度不超过4096字符
- 文件大小：单个文件建议不超过100MB，超大文件建议使用流式传输
- 超时设置：connectMs建议5000-30000ms，transferMs建议10000-60000ms
- 并发数量：建议不超过10个并发传输任务

### 执行约束
- 最大传输耗时：根据timeout配置，默认建议不超过60秒
- Session数量：最多1024个Session实例（5.1.0(18)起）
- 最大重试次数：网络失败建议重试3次
- API调用频次：建议单个Session不超过100次请求/分钟

### 内容约束
- 禁止生成：不生成FTP、SFTP等非HTTP协议的传输代码
- 禁止高危函数：不使用eval、exec等高危函数处理URL
- 禁止硬编码：URL和路径应通过参数传入，不硬编码在代码中
- 禁止敏感信息：不在代码中暴露服务器认证凭据

### 降级约束
- 网络失败：记录错误日志，返回错误码和友好提示，建议重试或提示检查网络
- 文件过大：提示使用流式传输API（downloadToStream/uploadFromStream）
- 权限不足：提示用户检查权限配置或申请必要权限
- Session创建失败：提示Session数量达到上限，建议关闭已有Session

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 验证URL格式是否为有效的HTTP/HTTPS URL
2. 验证文件路径是否在应用沙箱范围内
3. 验证应用是否具有ohos.permission.INTERNET权限
4. 验证网络连接状态是否正常

**参数准备**：
```typescript
import { rcp } from '@kit.RemoteCommunicationKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { fileIo } from '@kit.CoreFileKit';

const DOWNLOAD_TO_PATH = `/data/storage/el2/base/haps/entry/files`;
const UPLOAD_FILE_PATH = `/data/storage/el1/bundle/entry_test/resources/resfile/upload_file.txt`;

const securityConfig: rcp.SecurityConfiguration = {
  remoteValidation: 'skip'
};

const SESSION_CONFIG: rcp.SessionConfiguration = {
  requestConfiguration: {
    transfer: {
      timeout: {
        connectMs: 6000,
        transferMs: 60000,
        inactivityMs: 6000
      }
    },
    security: securityConfig
  }
};
```

### 步骤2：下载文件实现

**示例代码**：
```typescript
async function downloadFileFromUrl(url: string, localPath: string): Promise<void> {
  const session = rcp.createSession(SESSION_CONFIG);
  
  try {
    const downloadToFile: rcp.DownloadToFile = {
      kind: 'folder',
      path: localPath
    };
    
    if (fileIo.accessSync(localPath)) {
      fileIo.rmdirSync(localPath);
    }
    
    const response = await session.downloadToFile(url, downloadToFile);
    console.info(`Download succeeded, statusCode: ${response.statusCode}`);
    
  } catch (error) {
    const err = error as BusinessError;
    console.error(`Download failed: code ${err.code}, data ${err.data}`);
    throw error;
  } finally {
    session.close();
  }
}
```

**错误处理**：
```typescript
try {
  await downloadFileFromUrl('https://example.com/test.png', DOWNLOAD_TO_PATH);
} catch (error) {
  const err = error as BusinessError;
  switch (err.code) {
    case 1007900006:
      console.error('域名解析失败，请检查URL和网络连接');
      break;
    case 1007900007:
      console.error('无法连接到服务器，请检查网络状态');
      break;
    case 1007900028:
      console.error('操作超时，建议关闭Session后重新创建');
      break;
    case 1007900985:
      console.error('文件系统IO错误，请检查路径权限');
      break;
    default:
      console.error(`下载失败: ${err.message}`);
  }
}
```

### 步骤3：上传文件实现

**示例代码**：
```typescript
class FdReadFile {
  readonly fd: number;
  
  constructor(fd: number) {
    this.fd = fd;
  }
  
  async read(buffer: ArrayBuffer): Promise<number> {
    return fileIo.read(this.fd, buffer);
  }
}

async function uploadFileToServer(filePath: string, serverUrl: string): Promise<void> {
  const session = rcp.createSession(SESSION_CONFIG);
  
  try {
    const file = fileIo.openSync(filePath, fileIo.OpenMode.READ_ONLY);
    if (!file) {
      console.error('Failed to open file');
      return;
    }
    
    const fdReadFile = new FdReadFile(file.fd);
    const buffer = new ArrayBuffer(1024 * 1024);
    await fdReadFile.read(buffer);
    
    const response = await session.uploadFromFile(serverUrl, new rcp.UploadFromFile(fdReadFile));
    console.info(`Upload succeeded: ${response.statusCode}`);
    
    fileIo.closeSync(file.fd);
    
  } catch (error) {
    const err = error as BusinessError;
    console.error(`Upload failed: code ${err.code}, data ${err.data}`);
    throw error;
  } finally {
    session.close();
  }
}
```

**错误处理**：
```typescript
try {
  await uploadFileToServer(UPLOAD_FILE_PATH, 'https://httpbin.org/anything');
} catch (error) {
  const err = error as BusinessError;
  switch (err.code) {
    case 1007900025:
      console.error('上传失败，可能文件过大或网络问题');
      break;
    case 1007900026:
      console.error('无法读取文件，请检查应用文件读取权限');
      break;
    case 1007900988:
      console.error('文件打开失败，请检查路径和权限');
      break;
    default:
      console.error(`上传失败: ${err.message}`);
  }
}
```

### 步骤4：降级处理

**超大文件降级方案**：
```typescript
async function handleLargeFile(url: string, fileSize: number): Promise<void> {
  if (fileSize > 100 * 1024 * 1024) {
    console.warn('文件超过100MB，建议使用流式传输');
    const streamData: rcp.WriteStream = {
      write(buffer: ArrayBuffer): Promise<void | number> {
        return Promise.resolve(buffer.byteLength);
      }
    };
    
    const downloadToStream: rcp.DownloadToStream = {
      kind: 'stream',
      stream: streamData
    };
    
    const session = rcp.createSession();
    await session.downloadToStream(url, downloadToStream);
    session.close();
  } else {
    await downloadFileFromUrl(url, DOWNLOAD_TO_PATH);
  }
}
```

**网络失败降级方案**：
```typescript
async function downloadWithRetry(url: string, localPath: string, maxRetries: number = 3): Promise<void> {
  let retryCount = 0;
  
  while (retryCount < maxRetries) {
    try {
      await downloadFileFromUrl(url, localPath);
      return;
    } catch (error) {
      retryCount++;
      const err = error as BusinessError;
      
      if (err.code === 1007900007 || err.code === 1007900028) {
        console.warn(`网络问题，第${retryCount}次重试...`);
        await new Promise(resolve => setTimeout(resolve, 2000));
      } else {
        throw error;
      }
    }
  }
  
  throw new Error('网络连接失败，已达到最大重试次数');
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 1007900001 | 不支持的协议 | 检查URL协议是否为HTTP/HTTPS |
| 1007900003 | URL格式错误 | 检查URL格式是否正确 |
| 1007900006 | 域名解析失败 | 检查URL和网络连接状态 |
| 1007900007 | 无法连接到服务器 | 检查网络连接和服务器状态 |
| 1007900023 | 写入数据到磁盘失败 | 检查磁盘空间和文件路径权限，超大文件建议使用流式传输 |
| 1007900025 | 上传失败 | 检查文件大小和网络状况 |
| 1007900026 | 无法读取本地文件 | 检查应用文件读取权限 |
| 1007900028 | 操作超时 | 建议关闭Session后重新创建Session |
| 1007900035 | SSL连接错误 | 检查TLS版本和加密套件配置 |
| 1007900037 | 无法读取文件 | 检查文件路径、权限和格式 |
| 1007900985 | 文件系统IO错误 | 检查文件路径访问权限和路径合法性 |
| 1007900988 | 文件打开失败 | 检查应用是否有该路径文件的读写权限 |
| 1007900994 | Session数量达到限制 | 减少Session创建数量，不超过1024个 |
| 1007900993 | Session已关闭 | 重新打开Session或创建新Session |
| 1007900992 | 请求已被取消 | 检查请求超时和网络连接状态 |
| 201 | 权限被拒绝 | 检查应用权限配置是否正确 |
| 401 | 参数错误 | 检查传入参数是否合理 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.RemoteCommunicationKit": ">=4.1.0(11)",
    "@kit.CoreFileKit": ">=9.0.0",
    "@kit.BasicServicesKit": ">=9.0.0"
  }
}
```

### 环境要求
- HarmonyOS API版本：>=4.1.0(11)
- 文件上传下载功能：>=5.0.0(12)
- TV设备支持：>=5.1.1(19)
- Car设备支持：>=6.1.0(23)
- DevEco Studio：>=3.1

### 常见编译问题

**问题1：导入模块错误**
```
Cannot find module '@kit.RemoteCommunicationKit' or its corresponding type declarations.
```
**解决方法**：确保项目API版本>=4.1.0(11)，在build-profile.json5中配置正确的兼容API版本。

**问题2：权限配置错误**
```
Permission denied: ohos.permission.INTERNET
```
**解决方法**：在module.json5中添加权限声明：
```json
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.INTERNET"
      }
    ]
  }
}
```

**问题3：Session创建失败**
```
Sessions number reached limit (1007900994)
```
**解决方法**：确保Session数量不超过1024个，及时关闭已使用的Session。

## 常见问题与解决方法

### Q1：下载的文件保存路径如何确定？
**原因**：需要使用应用沙箱路径，不能使用系统路径
**解决方法**：
- 使用context.filesDir获取应用文件目录
- 使用context.cacheDir获取缓存目录
- 参考[应用文件](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/app-file)

### Q2：上传大文件时出现内存不足怎么办？
**原因**：一次性读取大文件导致内存占用过高
**解决方法**：
- 使用流式传输API（uploadFromStream）
- 分片读取文件，每次读取不超过1MB
- 使用FdReadFile类逐块读取文件

### Q3：如何处理SSL证书验证失败？
**原因**：服务器证书配置不正确或证书过期
**解决方法**：
- 检查服务器证书有效性
- 配置security.remoteValidation为'skip'跳过验证（仅测试环境）
- 配置正确的TLS版本（建议TlsV1.3）

### Q4：传输过程中网络断开如何恢复？
**原因**：网络不稳定导致传输中断
**解决方法**：
- 实现重试机制，建议重试3次
- 记录传输进度，支持断点续传需要使用其他API
- 网络恢复后重新发起传输请求

### Q5：如何监控传输进度？
**原因**：需要实时了解传输进度和状态
**解决方法**：
- 配置TracingConfiguration的httpEventsHandler
- 使用onDownloadProgress和onUploadProgress回调
- 使用onDataReceive回调监控数据接收情况

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "operation": "file_transfer",
  "url": "https://example.com/test.png",
  "localPath": "/data/storage/el2/base/haps/entry/files",
  "statusCode": 200,
  "fileSize": 102400,
  "transferTime": 3500,
  "apiUsed": [
    "rcp.createSession",
    "session.downloadToFile",
    "session.uploadFromFile",
    "fileIo.accessSync",
    "fileIo.openSync",
    "fileIo.read",
    "fileIo.closeSync"
  ]
}
```

## 参考文档

- [API开发指南 - 快速实现上传下载](references/remote-communication-filetransferfast.md)
- [API参考 - Remote Communication Kit](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/remote-communication-rcp)
- [API参考 - 错误码说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/remote-communication-error-code)
- [应用文件访问指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/app-file)

## 完整示例代码

- [ArkTS下载示例](assets/download_file_example.ets)
- [ArkTS上传示例](assets/upload_file_example.ets)
- [Session配置示例](assets/session_config.json)
- [错误处理示例](assets/error_handling_example.ets)

## 测试用例

### 正向测试用例
- [下载小文件测试](tests/test_download_small_file.py)：验证小文件（<10MB）下载功能
- [上传文本文件测试](tests/test_upload_text_file.py)：验证文本文件上传功能
- [配置传输超时测试](tests/test_timeout_config.py)：验证超时配置功能

### 边界测试用例
- [大文件下载测试](tests/test_download_large_file.py)：验证100MB文件下载性能
- [并发传输测试](tests/test_concurrent_transfer.py)：验证多个并发传输场景
- [超时边界测试](tests/test_timeout_boundary.py)：验证超时边界值处理

### 异常测试用例
- [URL格式错误测试](tests/test_invalid_url.py)：验证无效URL处理
- [文件路径错误测试](tests/test_invalid_path.py)：验证无效路径处理
- [权限不足测试](tests/test_permission_denied.py)：验证权限不足场景
- [网络断开测试](tests/test_network_disconnect.py)：验证网络异常处理