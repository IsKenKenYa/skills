---
name: hmos-wear-engine-kit-p2p-communication
description: 实现手机与穿戴设备应用间的点对点消息通信，支持消息和文件收发，最大消息4096字节/文件100MB，适用于分布式场景应用交互
---

# 应用间消息通信技能

## 功能描述

本技能提供手机侧应用与穿戴设备侧应用之间的点对点消息通信能力，包括：
- 检测穿戴设备侧应用是否安装
- 获取穿戴设备侧应用的版本号
- 拉起穿戴设备侧应用
- 发送点对点消息到穿戴设备侧应用
- 发送文件到穿戴设备侧应用
- 取消文件传输
- 订阅接收穿戴设备侧应用发送的消息
- 订阅接收穿戴设备侧应用发送的文件
- 订阅接收文件传输进度

通过构建手机应用和穿戴设备应用之间的通信隧道，实现应用自定义报文消息和文件的收发，为用户提供分布式场景体验。

## 使用场景

### 触发词
- "手机应用发送消息到穿戴设备"
- "手机应用发送文件到手表"
- "手机应用接收穿戴设备消息"
- "检测穿戴设备应用是否安装"
- "拉起穿戴设备侧应用"
- "穿戴设备应用间通信"
- "P2P消息通信"
- "点对点消息发送"

### 能做
- 检测穿戴设备侧应用是否已安装
- 获取穿戴设备侧应用的版本号
- 拉起穿戴设备侧应用（当手机App启动但穿戴设备App未启动时）
- 发送点对点消息到穿戴设备侧应用（最大4096字节）
- 发送文件到穿戴设备侧应用（最大100MB）
- 取消正在进行的文件传输
- 订阅接收穿戴设备侧应用发送的消息
- 订阅接收穿戴设备侧应用发送的文件
- 订阅接收文件传输进度信息

### 绝不做
- 不支持超过4096字节的消息发送（需改用文件传输或消息分包）
- 不支持超过100MB的文件传输
- 不支持向未授权的设备发送消息或文件
- 不支持向未安装目标应用的设备发送消息
- 不执行超出Wear Engine Kit范围的通信操作

### 补充
- 使用前需在开发者联盟申请设备基础信息权限，否则接口调用将失败
- 需确保穿戴设备支持应用安装能力
- 需确保穿戴设备侧已有对应的应用
- 手机App和穿戴设备App必须同时处于启动状态
- API版本要求：5.0.0(12)及以上

## 调用规范和规则

### 输入约束
- 消息大小：1-4096字节
- 文件大小：最大100MB
- 设备ID：必须是有效的Device.randomId
- 应用包名：必须提供正确的bundleName和fingerprint
- 文件路径：不能包含'..'路径遍历字符

### 执行约束
- 最大传输耗时：文件传输根据大小动态调整，建议不超过5分钟
- 最大并发订阅：同一类型回调最多注册一次（错误码1008500012）
- API调用频次：遵循系统限制，避免频繁调用
- 网络要求：需保持设备连接状态

### 内容约束
- 禁止发送非法或违规内容
- 禁止使用不安全的文件路径（包含'..')
- 禁止发送超大文件（超过100MB）
- 禁止传输敏感或隐私数据未加密

### 降级约束
- 网络失败：提示网络不可用，建议检查网络连接后重试
- 设备断开：提示设备已断开，建议重新连接设备
- 应用未安装：提示目标应用未安装，建议先安装应用
- 权限未授权：提示权限未授权，建议先申请权限
- 文件过大：提示文件超过100MB限制，建议压缩或拆分文件

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 确认已在开发者联盟申请设备基础信息权限
2. 确认穿戴设备已连接且支持应用安装能力
3. 确认穿戴设备侧已安装目标应用
4. 获取已连接设备列表并选择目标设备
5. 获取P2pClient客户端对象

**参数准备**：
```typescript
import { wearEngine } from '@kit.WearEngine';
import { BusinessError } from '@kit.BasicServicesKit';
import { util } from '@kit.ArkTS';
import { fileIo } from '@kit.CoreFileKit';

// 获取设备客户端和P2p客户端
let deviceClient: wearEngine.DeviceClient = wearEngine.getDeviceClient(this.getUIContext().getHostContext());
let p2pClient: wearEngine.P2pClient = wearEngine.getP2pClient(this.getUIContext().getHostContext());

// 获取已连接设备列表
let deviceList: wearEngine.Device[] = await deviceClient.getConnectedDevices();
```

### 步骤2：检测应用安装状态

**示例代码**：
```typescript
// 步骤1：选择支持应用安装的目标设备
let targetDevice: wearEngine.Device | null = null;
for (let device of deviceList) {
  let isSupported = await device.isDeviceCapabilitySupported(wearEngine.DeviceCapability.APP_INSTALLATION);
  if (isSupported) {
    targetDevice = device;
    break;
  }
}

if (!targetDevice) {
  console.error('Cannot find target device with app installation capability');
  return;
}

// 步骤2：检测应用是否安装
let remoteBundleName: string = 'com.example.wearapp'; // 穿戴设备侧应用包名
try {
  let isInstall = await p2pClient.isRemoteAppInstalled(targetDevice.randomId, remoteBundleName);
  if (isInstall) {
    console.info('Remote app is installed');
  } else {
    console.warn('Remote app is not installed, please install first');
  }
} catch (error) {
  let err: BusinessError = error as BusinessError;
  console.error(`Failed to check remote app install. Code: ${err.code}, message: ${err.message}`);
}
```

### 步骤3：获取应用版本号

**示例代码**：
```typescript
// 获取穿戴设备侧应用的版本号
try {
  let version = await p2pClient.getRemoteAppVersion(targetDevice.randomId, remoteBundleName);
  console.info(`Remote app version: ${version}`);
} catch (error) {
  let err: BusinessError = error as BusinessError;
  console.error(`Failed to get remote app version. Code: ${err.code}, message: ${err.message}`);
}
```

### 步骤4：拉起设备侧应用

**示例代码**：
```typescript
// 拉起穿戴设备侧应用
try {
  let p2pResult = await p2pClient.startRemoteApp(targetDevice.randomId, remoteBundleName);
  if (p2pResult.code === wearEngine.P2pResultCode.COMMUNICATION_SUCCESS) {
    console.info('Succeeded in starting remote app');
  } else {
    console.error(`Failed to start remote app, result code: ${p2pResult.code}`);
  }
} catch (error) {
  let err: BusinessError = error as BusinessError;
  console.error(`Failed to start remote app. Code: ${err.code}, message: ${err.message}`);
}
```

### 步骤5：发送点对点消息

**示例代码**：
```typescript
// 构造设备侧应用参数
let appInfo: wearEngine.AppInfo = {
  bundleName: remoteBundleName,
  fingerprint: 'your_app_fingerprint' // 应用指纹
};

let appParam: wearEngine.P2pAppParam = {
  remoteApp: appInfo
  // transformLocalAppInfo默认为false，不转换包名指纹
};

// 构造消息内容（最大4096字节）
let messageContent: string = 'Hello from phone app';
let textEncoder: util.TextEncoder = new util.TextEncoder();
let message: wearEngine.P2pMessage = {
  content: textEncoder.encodeInto(messageContent)
};

// 发送消息
try {
  let p2pResult = await p2pClient.sendMessage(targetDevice.randomId, appParam, message);
  if (p2pResult.code === wearEngine.P2pResultCode.COMMUNICATION_SUCCESS) {
    console.info('Succeeded in sending message');
  } else {
    console.error(`Failed to send message, result code: ${p2pResult.code}`);
  }
} catch (error) {
  let err: BusinessError = error as BusinessError;
  console.error(`Failed to send message. Code: ${err.code}, message: ${err.message}`);
}
```

### 步骤6：发送文件

**示例代码**：
```typescript
// 构造文件对象（最大100MB，路径不能包含'..'）
let filePath: string = '/data/local/tmp/test.txt'; // 文件路径
let p2pFile: wearEngine.P2pFile;

try {
  p2pFile = {
    file: fileIo.openSync(filePath, fileIo.OpenMode.READ_ONLY)
  };
  
  // 发送文件并监听传输进度
  p2pClient.transferFile(targetDevice.randomId, appParam, p2pFile, 
    (error: BusinessError, p2pResult: wearEngine.P2pResult) => {
      if (error) {
        console.error(`Failed to transfer file. Code: ${error.code}, message: ${error.message}`);
        return;
      }
      
      if (p2pResult.code) {
        if (p2pResult.code === wearEngine.P2pResultCode.COMMUNICATION_SUCCESS) {
          console.info('Succeeded in transferring file');
        } else {
          console.error(`Failed to transfer file, result code: ${p2pResult.code}`);
        }
      }
      
      if (p2pResult.progress) {
        console.info(`Transfer progress: ${p2pResult.progress}%`);
      }
    });
} catch (error) {
  let err: BusinessError = error as BusinessError;
  console.error(`Failed to open file. Code: ${err.code}, message: ${err.message}`);
}

// 完成后关闭文件
try {
  if (p2pFile && p2pFile.file) {
    fileIo.close(p2pFile.file);
  }
} catch (error) {
  console.error('Failed to close file');
}
```

### 步骤7：取消文件传输

**示例代码**：
```typescript
// 取消正在进行的文件传输
try {
  let p2pResult = await p2pClient.cancelFileTransfer(targetDevice.randomId, appParam, p2pFile);
  if (p2pResult.code === wearEngine.P2pResultCode.COMMUNICATION_SUCCESS) {
    console.info('Succeeded in cancelling file transfer');
  }
} catch (error) {
  let err: BusinessError = error as BusinessError;
  console.error(`Failed to cancel file transfer. Code: ${err.code}, message: ${err.message}`);
}
```

### 步骤8：订阅接收消息

**示例代码**：
```typescript
// 定义消息接收回调函数
let messageCallback = (p2pMessage: wearEngine.P2pMessage) => {
  console.info('Received message from wear device');
  // 处理接收到的消息
  if (p2pMessage.content) {
    let textDecoder = util.TextDecoder.create('utf-8');
    let messageStr = textDecoder.decodeToString(p2pMessage.content);
    console.info(`Message content: ${messageStr}`);
  }
};

// 注册消息接收监听
try {
  await p2pClient.registerMessageReceiver(targetDevice.randomId, appParam, messageCallback);
  console.info('Succeeded in registering message receiver');
} catch (error) {
  let err: BusinessError = error as BusinessError;
  console.error(`Failed to register message receiver. Code: ${err.code}, message: ${err.message}`);
}

// 取消消息接收监听（需传入同一个回调函数对象）
try {
  await p2pClient.unregisterMessageReceiver(targetDevice.randomId, appParam, messageCallback);
  console.info('Succeeded in unregistering message receiver');
} catch (error) {
  let err: BusinessError = error as BusinessError;
  console.error(`Failed to unregister message receiver. Code: ${err.code}, message: ${err.message}`);
}
```

### 步骤9：订阅接收文件

**示例代码**：
```typescript
// 定义文件接收回调函数
let fileCallback = (p2pFile: wearEngine.P2pFile) => {
  console.info('Received file from wear device');
  // 处理接收到的文件
  if (p2pFile.file) {
    console.info('File received successfully');
  }
};

// 注册文件接收监听
try {
  await p2pClient.registerFileReceiver(targetDevice.randomId, appParam, fileCallback);
  console.info('Succeeded in registering file receiver');
} catch (error) {
  let err: BusinessError = error as BusinessError;
  console.error(`Failed to register file receiver. Code: ${err.code}, message: ${err.message}`);
}

// 取消文件接收监听
try {
  await p2pClient.unregisterFileReceiver(targetDevice.randomId, appParam, fileCallback);
  console.info('Succeeded in unregistering file receiver');
} catch (error) {
  let err: BusinessError = error as BusinessError;
  console.error(`Failed to unregister file receiver. Code: ${err.code}, message: ${err.message}`);
}
```

### 步骤10：订阅接收文件和传输进度

**示例代码**：
```typescript
// 定义文件接收和进度回调函数
let fileWithProgressCallback = (p2pFile: wearEngine.P2pFile) => {
  if (!p2pFile.file) {
    // 接收到传输进度
    console.info(`File transfer progress: ${p2pFile.progress}%`);
  } else {
    // 接收到完整文件
    console.info('File received successfully');
  }
};

// 注册文件接收和进度监听
try {
  await p2pClient.registerFileReceiverWithProgress(targetDevice.randomId, appParam, fileWithProgressCallback);
  console.info('Succeeded in registering file receiver with progress');
} catch (error) {
  let err: BusinessError = error as BusinessError;
  console.error(`Failed to register file receiver with progress. Code: ${err.code}, message: ${err.message}`);
}
```

### 步骤11：错误处理

```typescript
// 通用错误处理函数
function handleP2pError(error: BusinessError): void {
  switch (error.code) {
    case 401:
      console.error('Parameter error: Mandatory parameters left unspecified or incorrect parameter types');
      break;
    case 1008500001:
      console.error('Network error: The network is unavailable');
      break;
    case 1008500002:
      console.error('No device is bound');
      break;
    case 1008500003:
      console.error('Device disconnected');
      break;
    case 1008500004:
      console.error('App has not applied for the Wear Engine service');
      break;
    case 1008500005:
      console.error('The HUAWEI ID is not authorized');
      break;
    case 1008500006:
      console.error('User privacy is not agreed');
      break;
    case 1008500007:
      console.error('The device capability is not supported');
      break;
    case 1008500008:
      console.error('Account error: The user has not logged in with HUAWEI ID');
      break;
    case 1008500009:
      console.error('Account error: Failed to obtain account information with HUAWEI ID');
      break;
    case 1008500010:
      console.error('Device ID is invalid');
      break;
    case 1008500011:
      console.error('File is invalid');
      break;
    case 1008500012:
      console.error('Too many callbacks of the same type');
      break;
    case 1008509999:
      console.error('Internal error');
      break;
    default:
      console.error(`Unknown error: Code ${error.code}, message: ${error.message}`);
  }
}
```

### 步骤12：降级处理

```typescript
// 文件过大降级处理示例
async function sendLargeFile(filePath: string): Promise<void> {
  try {
    // 检查文件大小
    let stat = fileIo.statSync(filePath);
    let fileSize = stat.size;
    
    if (fileSize > 100 * 1024 * 1024) { // 100MB
      console.warn('File size exceeds 100MB limit');
      // 降级方案1：压缩文件
      // 降级方案2：拆分文件为多个小文件
      // 降级方案3：提示用户选择其他文件
      throw new Error('File too large, please compress or select a smaller file');
    }
    
    // 正常发送文件
    let p2pFile: wearEngine.P2pFile = {
      file: fileIo.openSync(filePath, fileIo.OpenMode.READ_ONLY)
    };
    
    await p2pClient.transferFile(targetDevice.randomId, appParam, p2pFile, 
      (error, result) => {
        if (error) handleP2pError(error);
        else console.info('File sent successfully');
      });
      
  } catch (error) {
    console.error('Failed to send file:', error.message);
  }
}

// 设备断开降级处理示例
async function handleDeviceDisconnected(): Promise<void> {
  console.warn('Device disconnected, attempting to reconnect...');
  
  try {
    // 尝试重新获取设备列表
    let newDeviceList = await deviceClient.getConnectedDevices();
    
    if (newDeviceList.length > 0) {
      // 找到新的目标设备
      targetDevice = newDeviceList[0];
      console.info('Reconnected to device');
    } else {
      // 无可用设备，提示用户
      console.error('No connected devices available');
    }
  } catch (error) {
    console.error('Failed to reconnect:', error.message);
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误：必填参数未指定或参数类型错误 | 检查参数是否正确填写，确认参数类型匹配 |
| 801 | 能力不支持：设备不支持此系统能力 | 确认设备支持该能力，或更换支持的设备 |
| 1008500001 | 网络错误：网络不可用 | 检查网络连接，确保网络可用后重试 |
| 1008500002 | 无设备绑定：没有绑定设备 | 先绑定设备后再进行通信 |
| 1008500003 | 设备断开：设备已断开连接 | 重新连接设备后重试 |
| 1008500004 | 应用未申请服务：应用未申请Wear Engine服务 | 在开发者联盟申请Wear Engine服务权限 |
| 1008500005 | 华为账号未授权：华为账号未授权 | 确认华为账号已授权相关权限 |
| 1008500006 | 用户隐私未同意：用户隐私协议未同意 | 确认用户已同意隐私协议 |
| 1008500007 | 设备能力不支持：设备不支持该能力 | 确认设备支持应用安装能力 |
| 1008500008 | 账号错误：用户未登录华为账号 | 登录华为账号后重试 |
| 1008500009 | 账号错误：获取华为账号信息失败 | 检查账号状态，重新登录后重试 |
| 1008500010 | 设备ID无效：设备ID不正确 | 使用正确的设备randomId |
| 1008500011 | 文件无效：文件不正确或不存在 | 检查文件路径和文件状态 |
| 1008500012 | 回调过多：同一类型回调注册次数过多 | 同类型回调最多注册一次 |
| 1008509999 | 内部错误：系统内部错误 | 稍后重试，或联系技术支持 |

## 编译和修复问题

### 依赖声明

在`oh-package.json5`中添加依赖：
```json
{
  "dependencies": {
    "@kit.WearEngine": "^5.0.0",
    "@kit.ArkTS": "^5.0.0",
    "@kit.CoreFileKit": "^5.0.0",
    "@kit.BasicServicesKit": "^5.0.0"
  }
}
```

### 导入模块

```typescript
import { wearEngine } from '@kit.WearEngine';
import { BusinessError } from '@kit.BasicServicesKit';
import { util } from '@kit.ArkTS';
import { fileIo } from '@kit.CoreFileKit';
```

### 环境要求
- HarmonyOS API版本：5.0.0(12)及以上
- 设备类型：Phone、Tablet（其他设备返回801错误码）
- 模型约束：仅支持Stage模型

### 常见编译问题

**问题1：找不到wearEngine模块**
```
Error: Cannot find module '@kit.WearEngine'
```
**解决方法**：确认API版本>=5.0.0(12)，在`oh-package.json5`中添加依赖声明

**问题2：P2pClient类型错误**
```
Error: Property 'sendMessage' does not exist on type 'P2pClient'
```
**解决方法**：确认已正确导入wearEngine模块，使用完整类型`wearEngine.P2pClient`

**问题3：文件操作权限错误**
```
Error: Permission denied when opening file
```
**解决方法**：检查文件路径权限，确保应用有文件访问权限

**问题4：Context类型错误**
```
Error: Argument of type 'UIAbilityContext' is not assignable to parameter of type 'common.Context'
```
**解决方法**：使用`this.getUIContext().getHostContext()`获取正确的Context对象

## 常见问题与解决方法

### Q1：发送消息时提示设备断开连接
**原因**：设备连接状态不稳定或网络中断
**解决方法**：
- 检查设备连接状态
- 重新获取设备列表确认设备在线
- 增加重连机制，在设备断开时自动重连
- 提示用户检查设备连接

### Q2：文件传输中断或失败
**原因**：网络不稳定、文件过大、权限不足
**解决方法**：
- 确认文件大小不超过100MB
- 检查文件路径不包含'..'
- 监听传输进度，发现中断时重试
- 实现取消传输功能，允许用户中断

### Q3：无法接收穿戴设备发送的消息
**原因**：未注册消息接收监听或回调函数错误
**解决方法**：
- 确认已调用`registerMessageReceiver`注册监听
- 确认回调函数定义正确
- 检查设备连接状态
- 确认应用包名和指纹匹配

### Q4：提示应用未申请Wear Engine服务
**原因**：未在开发者联盟申请设备基础信息权限
**解决方法**：
- 登录开发者联盟
- 申请Wear Engine服务权限
- 配置应用权限声明
- 重新打包应用

### Q5：发送消息长度超过限制
**原因**：消息内容超过4096字节
**解决方法**：
- 使用文件传输代替消息发送
- 实现消息分包逻辑，将长消息拆分为多个短消息
- 压缩消息内容减少长度
- 提示用户精简消息内容

### Q6：同一回调注册多次导致错误
**原因**：相同类型的回调重复注册（错误码1008500012）
**解决方法**：
- 同类型回调只注册一次
- 先调用`unregister`取消旧的监听再注册新监听
- 使用全局回调函数对象，避免重复注册

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "operation": "p2p_communication",
  "targetDevice": "device_random_id",
  "remoteApp": "com.example.wearapp",
  "result": {
    "isInstalled": true,
    "appVersion": 100,
    "messageSent": true,
    "fileSent": false,
    "messageReceived": true
  },
  "apiUsed": [
    "wearEngine.getP2pClient",
    "P2pClient.isRemoteAppInstalled",
    "P2pClient.getRemoteAppVersion",
    "P2pClient.startRemoteApp",
    "P2pClient.sendMessage",
    "P2pClient.registerMessageReceiver"
  ],
  "timestamp": "2026-07-03T20:37:00Z"
}
```

## 参考文档

- [应用间消息通信开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/p2p_communication)
- [申请接入Wear Engine服务](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/wearengine_apply)
- [已连接穿戴设备查询](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/query_connected_devices)
- [目标设备选择](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/we-device-selection)
- [wearEngine API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/wearengine_api)
- [Wear Engine错误码](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/wearengine_api_error_code)

## 完整示例代码

- [ArkTS完整示例](assets/p2p_communication_example.ets) - 包含消息和文件收发的完整实现
- [消息发送示例](assets/send_message_example.ets) - 仅消息发送功能
- [文件传输示例](assets/transfer_file_example.ets) - 仅文件传输功能
- [消息接收示例](assets/receive_message_example.ets) - 仅消息接收功能

## 测试用例

### 正向测试用例
- [消息发送测试](tests/test_send_message.py) - 测试正常消息发送流程
- [文件传输测试](tests/test_transfer_file.py) - 测试正常文件传输流程
- [应用安装检测测试](tests/test_app_installed.py) - 测试应用安装状态检测

### 边界测试用例
- [最大消息长度测试](tests/test_max_message_length.py) - 测试4096字节消息发送
- [最大文件大小测试](tests/test_max_file_size.py) - 测试100MB文件传输
- [多设备通信测试](tests/test_multi_device.py) - 测试与多个设备通信

### 异常测试用例
- [设备断开测试](tests/test_device_disconnected.py) - 测试设备断开场景处理
- [应用未安装测试](tests/test_app_not_installed.py) - 测试应用未安装场景
- [权限未授权测试](tests/test_permission_denied.py) - 测试权限未授权场景
- [超大文件测试](tests/test_large_file.py) - 测试超过100MB文件处理
- [无效参数测试](tests/test_invalid_params.py) - 测试无效参数处理