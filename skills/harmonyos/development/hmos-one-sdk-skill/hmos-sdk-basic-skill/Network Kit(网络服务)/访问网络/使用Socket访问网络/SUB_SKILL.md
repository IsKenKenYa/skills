---
name: hmos-network-kit-socket-connection
description: 通过Socket进行数据传输，支持TCP/UDP/Multicast/LocalSocket/TLS协议，适用于网络通信、进程间通信、加密传输场景
---

# 使用Socket访问网络技能

## 功能描述

本技能提供HarmonyOS Socket网络通信能力，支持TCP、UDP、Multicast、LocalSocket、TLS等多种协议的数据传输。涵盖客户端和服务端场景，支持普通通信、多播通信、本地进程间通信以及加密通信等多种使用场景。

**核心能力**：
- TCP/UDP客户端通信
- TCP/UDP服务端通信
- Multicast多播通信
- LocalSocket本地进程间通信
- TLS加密通信（单向/双向认证）
- TCP Socket升级为TLS Socket

**技术特点**：
- 支持多种协议（TCP、UDP、Multicast、TLS）
- 支持客户端和服务端模式
- 支持本地进程间通信（LocalSocket）
- 支持数据加密传输（TLS）
- 异步API设计，支持Promise和callback两种调用方式

## 使用场景

### 触发词
- "Socket通信"
- "TCP连接"
- "UDP通信"
- "网络传输"
- "Socket服务端"
- "多播通信"
- "本地进程通信"
- "加密传输"
- "TLS连接"
- "网络编程"

### 能做
- 创建TCP/UDP客户端连接进行数据传输
- 创建TCP/UDP服务端监听客户端连接
- 实现多播组通信
- 实现本地进程间通信
- 实现TLS加密数据传输
- 实现TCP Socket升级为TLS Socket
- 处理Socket连接的生命周期管理
- 处理Socket通信的错误和异常

### 绝不做
- 不处理HTTP/HTTPS协议通信（应使用http模块）
- 不处理WebSocket协议（应使用专门的WebSocket模块）
- 不处理非网络相关的IPC通信
- 不实现自定义协议解析
- 不处理应用层业务逻辑

### 补充
- 应用退后台后，Socket可能会断开，当应用重新回到前台，发生通信失败时，需匹配错误码并重新创建新的TCP/UDP Socket
- 建议在worker线程或taskpool中执行网络操作，避免UI线程卡顿
- 需要申请ohos.permission.INTERNET权限

## 调用规范和规则

### 输入约束
- IP地址格式：IPv4（如192.168.1.1）或IPv6格式
- 端口号范围：1-65535
- 数据大小：单个数据包建议不超过64KB
- 连接超时：默认6000ms，可自定义
- TLS证书：需要有效的CA证书和数字证书

### 执行约束
- 最大连接时长：无限制，建议设置合理超时
- 最大并发连接数：根据系统资源确定
- API调用模式：异步调用（Promise/callback）
- 网络操作：建议在Worker线程或TaskPool执行

### 内容约束
- 禁止在主线程执行耗时网络操作
- 禁止使用硬编码的IP地址和端口（应使用配置文件）
- 禁止在代码中明文存储证书密钥
- 禁止忽略SSL/TLS证书验证错误

### 降级约束
- 网络连接失败：提示用户检查网络设置，重试连接
- DNS解析失败：使用备用IP地址或提示用户
- TLS握手失败：检查证书配置，降级为普通TCP（需用户确认）
- 连接超时：提供重试机制，最多重试3次
- 权限不足：提示用户授予网络权限

## 调用流程和步骤

### 场景1：TCP客户端通信

#### 步骤1：导入模块和创建Socket对象

**示例代码**：
```typescript
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

// 创建TCP Socket客户端对象
let tcpClient: socket.TCPSocket = socket.constructTCPSocketInstance();
```

#### 步骤2：订阅Socket事件（可选）

**示例代码**：
```typescript
class SocketInfo {
  public message: ArrayBuffer = new ArrayBuffer(1);
  public remoteInfo: socket.SocketRemoteInfo = {} as socket.SocketRemoteInfo;
}

// 订阅消息事件
tcpClient.on('message', (value: SocketInfo) => {
  hilog.info(0x0000, 'testTag', 'on message');
  let buffer = value.message;
  let dataView = new DataView(buffer);
  let str = '';
  for (let i = 0; i < dataView.byteLength; ++i) {
    str += String.fromCharCode(dataView.getUint8(i));
  }
  hilog.info(0x0000, 'testTag', 'on connect received:' + str);
});

// 订阅连接事件
tcpClient.on('connect', () => {
  hilog.info(0x0000, 'testTag', 'on connect');
});

// 订阅关闭事件
tcpClient.on('close', () => {
  hilog.info(0x0000, 'testTag', 'on close');
});
```

#### 步骤3：绑定本地地址并连接服务器

**示例代码**：
```typescript
// 绑定本地IP地址和端口（可选）
let ipAddress: socket.NetAddress = {} as socket.NetAddress;
ipAddress.address = "192.168.1.100";  // 本地IP
ipAddress.port = 1234;                  // 本地端口

// 服务器地址和端口
let serverAddress: socket.NetAddress = {} as socket.NetAddress;
serverAddress.address = "192.168.1.200";  // 服务器IP
serverAddress.port = 5678;                // 服务器端口

// 绑定本地地址
tcpClient.bind(ipAddress, (err: BusinessError) => {
  if (err) {
    hilog.error(0x0000, 'testTag', 'bind fail: ' + JSON.stringify(err));
    return;
  }
  hilog.info(0x0000, 'testTag', 'bind success');
  
  // 连接服务器
  let tcpConnect: socket.TCPConnectOptions = {
    address: serverAddress,
    timeout: 6000  // 超时时间6秒
  };
  
  tcpClient.connect(tcpConnect).then(() => {
    hilog.info(0x0000, 'testTag', 'connect success');
    
    // 发送数据
    let tcpSendOptions: socket.TCPSendOptions = {
      data: 'Hello, Server!'
    };
    
    tcpClient.send(tcpSendOptions).then(() => {
      hilog.info(0x0000, 'testTag', 'send success');
    }).catch((err: BusinessError) => {
      hilog.error(0x0000, 'testTag', 'send fail: ' + JSON.stringify(err));
    });
    
  }).catch((err: BusinessError) => {
    hilog.error(0x0000, 'testTag', 'connect fail: ' + JSON.stringify(err));
  });
});
```

#### 步骤4：关闭连接并取消订阅

**示例代码**：
```typescript
// 连接使用完毕后，主动关闭并取消订阅
setTimeout(() => {
  tcpClient.close().then(() => {
    hilog.info(0x0000, 'testTag', 'close success');
  }).catch((err: BusinessError) => {
    hilog.error(0x0000, 'testTag', 'close fail: ' + JSON.stringify(err));
  });
  
  // 取消事件订阅
  tcpClient.off('message');
  tcpClient.off('connect');
  tcpClient.off('close');
}, 30 * 1000);  // 30秒后关闭
```

### 场景2：TCP服务端通信

#### 步骤1：创建TCP Socket Server对象

**示例代码**：
```typescript
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

// 创建TCP Socket Server对象
let tcpServer: socket.TCPSocketServer = socket.constructTCPSocketServerInstance();
```

#### 步骤2：绑定地址并开始监听

**示例代码**：
```typescript
// 绑定本地IP地址和端口，进行监听
let ipAddress: socket.NetAddress = {} as socket.NetAddress;
ipAddress.address = "192.168.1.100";
ipAddress.port = 4651;

tcpServer.listen(ipAddress).then(() => {
  hilog.info(0x0000, 'testTag', 'listen success');
}).catch((err: BusinessError) => {
  hilog.error(0x0000, 'testTag', 'listen fail: ' + JSON.stringify(err));
});
```

#### 步骤3：订阅客户端连接事件

**示例代码**：
```typescript
class SocketInfo {
  public message: ArrayBuffer = new ArrayBuffer(1);
  public remoteInfo: socket.SocketRemoteInfo = {} as socket.SocketRemoteInfo;
}

// 订阅客户端连接事件
tcpServer.on('connect', (client: socket.TCPSocketConnection) => {
  hilog.info(0x0000, 'testTag', 'client connected');
  
  // 订阅客户端关闭事件
  client.on('close', () => {
    hilog.info(0x0000, 'testTag', 'client on close success');
  });
  
  // 订阅客户端消息事件
  client.on('message', (value: SocketInfo) => {
    let buffer = value.message;
    let dataView = new DataView(buffer);
    let str = '';
    for (let i = 0; i < dataView.byteLength; ++i) {
      str += String.fromCharCode(dataView.getUint8(i));
    }
    hilog.info(0x0000, 'testTag', 'received message: ' + str);
    hilog.info(0x0000, 'testTag', 'from address: ' + value.remoteInfo.address);
    hilog.info(0x0000, 'testTag', 'from port: ' + value.remoteInfo.port);
    
    // 向客户端发送响应
    let tcpSendOptions: socket.TCPSendOptions = {} as socket.TCPSendOptions;
    tcpSendOptions.data = 'Hello, Client!';
    
    client.send(tcpSendOptions).then(() => {
      hilog.info(0x0000, 'testTag', 'send success');
    }).catch((err: BusinessError) => {
      hilog.error(0x0000, 'testTag', 'send fail: ' + JSON.stringify(err));
    });
  });
  
  // 关闭与客户端的连接（可选）
  setTimeout(() => {
    client.close().then(() => {
      hilog.info(0x0000, 'testTag', 'client close success');
    }).catch((err: BusinessError) => {
      hilog.error(0x0000, 'testTag', 'client close fail: ' + JSON.stringify(err));
    });
    
    // 取消事件订阅
    client.off('message');
    client.off('close');
  }, 10 * 1000);  // 10秒后关闭客户端连接
});
```

#### 步骤4：取消服务端事件订阅

**示例代码**：
```typescript
// 设置连接超时（例如30秒后取消连接）
setTimeout(() => {
  tcpServer.off('connect');
}, 30 * 1000);
```

### 场景3：Multicast多播通信

#### 步骤1：创建Multicast Socket对象

**示例代码**：
```typescript
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

// 创建Multicast对象
let multicast: socket.MulticastSocket = socket.constructMulticastSocketInstance();
```

#### 步骤2：加入多播组

**示例代码**：
```typescript
// 构造多播组地址
let addr: socket.NetAddress = {
  address: '239.255.0.1',  // 多播组地址
  port: 32123,
  family: 1
};

// 加入多播组
multicast.addMembership(addr).then(() => {
  hilog.info(0x0000, 'testTag', 'addMembership success');
}).catch((err: BusinessError) => {
  hilog.error(0x0000, 'testTag', 'addMembership fail: ' + JSON.stringify(err));
});
```

#### 步骤3：订阅消息事件

**示例代码**：
```typescript
class SocketInfo {
  public message: ArrayBuffer = new ArrayBuffer(1);
  public remoteInfo: socket.SocketRemoteInfo = {} as socket.SocketRemoteInfo;
}

// 开启监听消息数据
multicast.on('message', (data: SocketInfo) => {
  hilog.info(0x0000, 'testTag', '接收的数据: ' + JSON.stringify(data));
  
  const uintArray = new Uint8Array(data.message);
  let str = '';
  for (let i = 0; i < uintArray.length; ++i) {
    str += String.fromCharCode(uintArray[i]);
  }
  hilog.info(0x0000, 'testTag', 'message content: ' + str);
});
```

#### 步骤4：发送多播消息

**示例代码**：
```typescript
// 发送多播消息
multicast.send({ data: 'Hello multicast group!', address: addr }).then(() => {
  hilog.info(0x0000, 'testTag', 'Multicast: Message sent successfully');
}).catch((err: BusinessError) => {
  hilog.error(0x0000, 'testTag', 'Multicast: Failed to send message - ' + JSON.stringify(err));
});
```

#### 步骤5：退出多播组

**示例代码**：
```typescript
// 关闭消息监听
multicast.off('message');

// 退出多播组
multicast.dropMembership(addr).then(() => {
  hilog.info(0x0000, 'testTag', 'Multicast: Dropped membership successfully');
}).catch((err: BusinessError) => {
  hilog.error(0x0000, 'testTag', 'Multicast: Failed to drop membership - ' + JSON.stringify(err));
});
```

### 场景4：LocalSocket本地进程通信（客户端）

#### 步骤1：创建LocalSocket对象

**示例代码**：
```typescript
import { socket } from '@kit.NetworkKit';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

// 创建LocalSocket客户端对象
let client: socket.LocalSocket = socket.constructLocalSocketInstance();
```

#### 步骤2：订阅事件

**示例代码**：
```typescript
// 订阅消息事件
client.on('message', (value: socket.LocalSocketMessageInfo) => {
  const uintArray = new Uint8Array(value.message);
  let messageView = '';
  for (let i = 0; i < uintArray.length; i++) {
    messageView += String.fromCharCode(uintArray[i]);
  }
  hilog.info(0x0000, 'testTag', 'message information: ' + messageView);
});

// 订阅连接事件
client.on('connect', () => {
  hilog.info(0x0000, 'testTag', 'Client connected');
});

// 订阅关闭事件
client.on('close', () => {
  hilog.info(0x0000, 'testTag', 'Client closed');
});
```

#### 步骤3：连接服务端并发送数据

**示例代码**：
```typescript
// 获取上下文
let context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
let sandboxPath: string = context.filesDir + '/testSocket';

let localAddress: socket.LocalAddress = {
  address: sandboxPath
};

let connectOpt: socket.LocalConnectOptions = {
  address: localAddress,
  timeout: 6000
};

let sendOpt: socket.LocalSendOptions = {
  data: 'Hello world!'
};

// 连接服务端
client.connect(connectOpt).then(() => {
  hilog.info(0x0000, 'testTag', 'connect success');
  
  // 发送数据
  client.send(sendOpt).then(() => {
    hilog.info(0x0000, 'testTag', 'send success');
  }).catch((err: BusinessError) => {
    hilog.error(0x0000, 'testTag', 'send failed: ' + JSON.stringify(err));
  });
}).catch((err: BusinessError) => {
  hilog.error(0x0000, 'testTag', 'connect fail: ' + JSON.stringify(err));
});
```

#### 步骤4：关闭连接并取消订阅

**示例代码**：
```typescript
// 断开连接并取消事件监听
client.off('message');
client.off('connect');
client.off('close');

client.close().then(() => {
  hilog.info(0x0000, 'testTag', 'close client success');
}).catch((err: BusinessError) => {
  hilog.error(0x0000, 'testTag', 'close client err: ' + JSON.stringify(err));
});
```

### 场景5：LocalSocket Server本地进程通信（服务端）

#### 步骤1：创建LocalSocket Server对象

**示例代码**：
```typescript
import { socket } from '@kit.NetworkKit';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

// 创建LocalSocketServer对象
let server: socket.LocalSocketServer = socket.constructLocalSocketServerInstance();
```

#### 步骤2：绑定本地套接字路径并监听

**示例代码**：
```typescript
// 获取上下文
let context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
let sandboxPath: string = context.filesDir + '/testSocket';

let listenAddr: socket.LocalAddress = {
  address: sandboxPath
};

// 开始监听
server.listen(listenAddr).then(() => {
  hilog.info(0x0000, 'testTag', 'Server listening on ' + sandboxPath);
}).catch((err: BusinessError) => {
  hilog.error(0x0000, 'testTag', 'Server listen error: ' + JSON.stringify(err));
});
```

#### 步骤3：订阅客户端连接事件

**示例代码**：
```typescript
// 订阅客户端连接事件
server.on('connect', (connection: socket.LocalSocketConnection) => {
  hilog.info(0x0000, 'testTag', 'Client connected');
  
  // 订阅错误事件
  connection.on('error', (err: BusinessError) => {
    hilog.error(0x0000, 'testTag', 'connection error: ' + JSON.stringify(err));
  });
  
  // 订阅消息事件
  connection.on('message', (value: socket.LocalSocketMessageInfo) => {
    const uintArray = new Uint8Array(value.message);
    let messageView = '';
    for (let i = 0; i < uintArray.length; i++) {
      messageView += String.fromCharCode(uintArray[i]);
    }
    hilog.info(0x0000, 'testTag', 'Server received: ' + messageView);
    
    // 向客户端发送响应
    let sendOpt: socket.LocalSendOptions = {
      data: 'Hello world!'
    };
    
    connection.send(sendOpt).then(() => {
      hilog.info(0x0000, 'testTag', 'Server send success');
    }).catch((err: BusinessError) => {
      hilog.error(0x0000, 'testTag', 'Server send failed: ' + JSON.stringify(err));
    });
  });
  
  // 关闭与客户端的连接（可选）
  setTimeout(() => {
    connection.close().then(() => {
      hilog.info(0x0000, 'testTag', 'close success');
    }).catch((err: BusinessError) => {
      hilog.error(0x0000, 'testTag', 'close failed: ' + JSON.stringify(err));
    });
    
    // 取消事件订阅
    connection.off('message');
    connection.off('error');
  }, 10 * 1000);
});
```

#### 步骤4：取消服务端事件订阅

**示例代码**：
```typescript
// 取消服务端事件订阅
server.off('connect');
server.off('error');
```

### 场景6：TLS Socket加密通信（双向认证）

#### 步骤1：创建TLS Socket对象

**示例代码**：
```typescript
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

// 创建TLS Socket对象
let tlsSocket: socket.TLSSocket | null = socket.constructTLSSocketInstance();
```

#### 步骤2：配置TLS安全选项并连接

**示例代码**：
```typescript
// 本地地址
let ipAddress: socket.NetAddress = {} as socket.NetAddress;
ipAddress.address = "192.168.1.100";
ipAddress.port = 4512;

// 服务器地址
let serverAddress: socket.NetAddress = {} as socket.NetAddress;
serverAddress.address = "192.168.1.200";
serverAddress.port = 1234;

// TLS安全选项（双向认证）
let tlsSecureOption: socket.TLSSecureOptions = {} as socket.TLSSecureOptions;
tlsSecureOption.key = "xxxx";          // 客户端私钥
tlsSecureOption.cert = "xxxx";         // 客户端证书
tlsSecureOption.ca = ["xxxx"];         // CA证书
tlsSecureOption.password = "xxxx";     // 私钥密码
tlsSecureOption.protocols = [socket.Protocol.TLSv12];  // TLS协议版本
tlsSecureOption.useRemoteCipherPrefer = true;
tlsSecureOption.signatureAlgorithms = "rsa_pss_rsae_sha256:ECDSA+SHA256";
tlsSecureOption.cipherSuite = "AES256-SHA256";

let tlsConnectOption: socket.TLSConnectOptions = {} as socket.TLSConnectOptions;
tlsConnectOption.address = serverAddress;
tlsConnectOption.secureOptions = tlsSecureOption;
tlsConnectOption.ALPNProtocols = ["spdy/1", "http/1.1"];
```

#### 步骤3：绑定地址、订阅事件并连接

**示例代码**：
```typescript
class SocketInfo {
  public message: ArrayBuffer = new ArrayBuffer(1);
  public remoteInfo: socket.SocketRemoteInfo = {} as socket.SocketRemoteInfo;
}

// 绑定本地地址
tlsSocket!.bind(ipAddress).then(() => {
  hilog.info(0x0000, 'testTag', 'bind success');
  
  // 订阅消息事件
  tlsSocket!.on('message', (value: SocketInfo) => {
    hilog.info(0x0000, 'testTag', 'on message');
    let buffer = value.message;
    let dataView = new DataView(buffer);
    let str = '';
    for (let i = 0; i < dataView.byteLength; ++i) {
      str += String.fromCharCode(dataView.getUint8(i));
    }
    hilog.info(0x0000, 'testTag', 'received: ' + str);
  });
  
  // 订阅连接事件
  tlsSocket!.on('connect', () => {
    hilog.info(0x0000, 'testTag', 'on connect');
  });
  
  // 订阅关闭事件
  tlsSocket!.on('close', () => {
    hilog.info(0x0000, 'testTag', 'on close');
  });
  
  // 建立TLS连接
  tlsSocket!.connect(tlsConnectOption).then(() => {
    hilog.info(0x0000, 'testTag', 'Connected successfully');
    
    // 发送数据
    tlsSocket!.send('Hello, TLS Server!').then(() => {
      hilog.info(0x0000, 'testTag', 'send successfully');
    }).catch((err: BusinessError) => {
      hilog.error(0x0000, 'testTag', 'send failed: ' + JSON.stringify(err));
    });
    
  }).catch((err: BusinessError) => {
    hilog.error(0x0000, 'testTag', 'Failed to connect: ' + err.message);
  });
  
}).catch((err: BusinessError) => {
  hilog.error(0x0000, 'testTag', 'bind fail: ' + JSON.stringify(err));
});
```

#### 步骤4：关闭连接并取消订阅

**示例代码**：
```typescript
// 关闭连接并取消事件订阅
tlsSocket!.close((err: BusinessError) => {
  if (err) {
    hilog.error(0x0000, 'testTag', 'close callback error = ' + err);
  } else {
    hilog.info(0x0000, 'testTag', 'close success');
  }
  
  tlsSocket!.off('message');
  tlsSocket!.off('connect');
  tlsSocket!.off('close');
});
```

### 场景7：TLS Socket Server加密通信（服务端）

#### 步骤1：创建TLS Socket Server对象

**示例代码**：
```typescript
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

// 创建TLS Socket Server对象
let tlsServer: socket.TLSSocketServer = socket.constructTLSSocketServerInstance();
```

#### 步骤2：配置TLS并开始监听

**示例代码**：
```typescript
let netAddress: socket.NetAddress = {
  address: '192.168.1.100',
  port: 8080
};

let tlsSecureOptions: socket.TLSSecureOptions = {
  key: "xxxx",          // 服务端私钥
  cert: "xxxx",         // 服务端证书
  ca: ["xxxx"],         // CA证书
  password: "xxxx",     // 私钥密码
  protocols: socket.Protocol.TLSv12,
  useRemoteCipherPrefer: true,
  signatureAlgorithms: "rsa_pss_rsae_sha256:ECDSA+SHA256",
  cipherSuite: "AES256-SHA256"
};

let tlsConnectOptions: socket.TLSConnectOptions = {
  address: netAddress,
  secureOptions: tlsSecureOptions,
  ALPNProtocols: ["spdy/1", "http/1.1"]
};

// 开始监听
tlsServer.listen(tlsConnectOptions).then(() => {
  hilog.info(0x0000, 'testTag', 'listen callback success');
}).catch((err: BusinessError) => {
  hilog.error(0x0000, 'testTag', 'failed: ' + JSON.stringify(err));
});
```

#### 步骤3：订阅客户端连接事件

**示例代码**：
```typescript
class SocketInfo {
  public message: ArrayBuffer = new ArrayBuffer(1);
  public remoteInfo: socket.SocketRemoteInfo = {} as socket.SocketRemoteInfo;
}

let callback = (value: SocketInfo) => {
  let messageView = '';
  for (let i: number = 0; i < value.message.byteLength; i++) {
    let uint8Array = new Uint8Array(value.message);
    let messages = uint8Array[i];
    let message = String.fromCharCode(messages);
    messageView += message;
  }
  hilog.info(0x0000, 'testTag', 'received message: ' + messageView);
  hilog.info(0x0000, 'testTag', 'from remoteInfo: ' + JSON.stringify(value.remoteInfo));
};

// 订阅客户端连接事件
tlsServer.on('connect', (client: socket.TLSSocketConnection) => {
  hilog.info(0x0000, 'testTag', 'client connected');
  
  // 订阅客户端消息事件
  client.on('message', callback);
  
  // 向客户端发送数据
  client.send('Hello, client!').then(() => {
    hilog.info(0x0000, 'testTag', 'send success');
  }).catch((err: BusinessError) => {
    hilog.error(0x0000, 'testTag', 'send fail: ' + JSON.stringify(err));
  });
  
  // 关闭连接（可选）
  setTimeout(() => {
    client.close().then(() => {
      hilog.info(0x0000, 'testTag', 'close success');
    }).catch((err: BusinessError) => {
      hilog.error(0x0000, 'testTag', 'close fail: ' + JSON.stringify(err));
    });
    
    // 取消事件订阅
    client.off('message', callback);
    client.off('message');
  }, 10 * 1000);
});
```

#### 步骤4：关闭服务端并取消订阅

**示例代码**：
```typescript
// 关闭服务端
tlsServer.close();

// 取消订阅服务端事件
tlsServer.off('connect');
```

## 错误码说明

### Socket错误码

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | Parameter error | 检查参数类型和格式是否正确 |
| 201 | Permission denied | 在module.json5中申请ohos.permission.INTERNET权限 |
| 2300000 | System internal error | 检查系统状态，重试操作 |
| 2301001 | Socket is closed | Socket已关闭，需要重新创建 |
| 2301002 | Socket is busy | Socket正在使用中，等待操作完成 |
| 2301003 | Socket is not connected | Socket未连接，需要先调用connect |
| 2302001 | DNS resolve failed | 检查域名是否正确，检查网络连接 |
| 2303001 | Connection refused | 检查服务器是否启动，检查端口是否正确 |
| 2303002 | Network unreachable | 检查网络连接状态 |
| 2303003 | Connection timeout | 增加超时时间或检查网络状态 |
| 2301206 | Socks5 failed to connect to the proxy server | 检查代理服务器配置 |
| 2301207 | Socks5 username or password is invalid | 检查代理认证信息 |
| 2301208 | Socks5 failed to connect to the remote server | 检查代理和目标服务器连接 |
| 2301209 | Socks5 failed to negotiate the authentication method | 检查代理认证方法 |
| 2301210 | Socks5 failed to send the message | 检查代理服务器状态 |
| 2301211 | Socks5 failed to receive the message | 检查代理服务器状态 |
| 2301212 | Socks5 serialization error | 检查数据格式 |
| 2301213 | Socks5 deserialization error | 检查数据格式 |

### TLS错误码

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 2305001 | TLS handshake failed | 检查证书配置，检查TLS协议版本 |
| 2305002 | Certificate verification failed | 检查CA证书和客户端证书 |
| 2305003 | Cipher suite not supported | 更换支持的加密套件 |
| 2305004 | Protocol not supported | 更换支持的TLS协议版本 |

## 编译和修复问题

### 依赖声明

**module.json5权限配置**：
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

**导入模块**：
```typescript
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { common } from '@kit.AbilityKit';  // LocalSocket需要
```

### 环境要求
- HarmonyOS API Version 7+
- DevEco Studio 3.1+
- Node.js 14.19.1+

### 常见编译问题

**问题1：权限未声明**
```
Error: Permission denied
```
**解决方法**：在module.json5中添加ohos.permission.INTERNET权限

**问题2：导入模块失败**
```
Error: Cannot find module '@kit.NetworkKit'
```
**解决方法**：检查HarmonyOS SDK版本，确保API Version >= 7

**问题3：网络操作导致UI卡顿**
```
Warning: Network operation on main thread
```
**解决方法**：将网络操作移到Worker线程或TaskPool中执行

**问题4：证书文件读取失败**
```
Error: Failed to read certificate file
```
**解决方法**：确保证书文件路径正确，文件格式为PEM或DER

## 常见问题与解决方法

### Q1：Socket连接超时
**原因**：网络不稳定或服务器未响应
**解决方法**：
- 检查网络连接状态
- 增加连接超时时间
- 实现重连机制，最多重试3次
- 检查服务器是否正常运行

### Q2：TLS握手失败
**原因**：证书配置错误或协议版本不匹配
**解决方法**：
- 检查CA证书、客户端证书、私钥文件路径
- 确认证书格式正确（PEM/DER）
- 检查TLS协议版本是否匹配
- 检查加密套件配置

### Q3：多播组加入失败
**原因**：多播地址不正确或网络不支持多播
**解决方法**：
- 确认多播地址在有效范围（224.0.0.0-239.255.255.255）
- 检查网络是否支持多播
- 确认端口未被占用

### Q4：LocalSocket路径冲突
**原因**：套接字文件已存在
**解决方法**：
- 使用唯一的套接字文件名
- 在应用启动时清理旧的套接字文件
- 使用context.filesDir下的路径

### Q5：数据接收不完整
**原因**：数据包分片或缓冲区设置不当
**解决方法**：
- 增加接收缓冲区大小
- 实现数据包重组逻辑
- 设置合理的socket超时时间

### Q6：应用退后台Socket断开
**原因**：系统资源回收
**解决方法**：
- 应用回到前台时检查Socket状态
- 实现自动重连机制
- 匹配错误码并重新创建Socket

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "connectionType": "TCP/UDP/Multicast/LocalSocket/TLS",
  "localAddress": "192.168.1.100:1234",
  "remoteAddress": "192.168.1.200:5678",
  "bytesSent": 1024,
  "bytesReceived": 2048,
  "connectionDuration": "30s",
  "apiUsed": [
    "socket.constructTCPSocketInstance",
    "socket.bind",
    "socket.connect",
    "socket.send",
    "socket.on",
    "socket.off",
    "socket.close"
  ]
}
```

## 参考文档

- [API开发指南：使用Socket访问网络](references/socket-connection-guide.md)
- [API参考：@ohos.net.socket (Socket连接)](references/js-apis-socket-reference.md)
- [获取UIAbility的上下文信息](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/uiability-usage)
- [通用错误码](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/errorcode-universal)
- [Socket错误码](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/errorcode-net-socket)

## 完整示例代码

- [TCP客户端完整示例](assets/tcp_client_example.ets)
- [TCP服务端完整示例](assets/tcp_server_example.ets)
- [UDP通信完整示例](assets/udp_example.ets)
- [Multicast多播完整示例](assets/multicast_example.ets)
- [LocalSocket客户端完整示例](assets/localsocket_client_example.ets)
- [LocalSocket服务端完整示例](assets/localsocket_server_example.ets)
- [TLS客户端完整示例](assets/tls_client_example.ets)
- [TLS服务端完整示例](assets/tls_server_example.ets)
- [配置文件示例](assets/module.json5)

## 测试用例

### 正向测试用例
- [TCP客户端连接测试](tests/test_tcp_client_positive.py)：测试TCP客户端正常连接和数据传输
- [TCP服务端监听测试](tests/test_tcp_server_positive.py)：测试TCP服务端正常监听和接受连接
- [UDP通信测试](tests/test_udp_positive.py)：测试UDP正常数据收发
- [Multicast多播测试](tests/test_multicast_positive.py)：测试多播组正常加入和通信
- [LocalSocket通信测试](tests/test_localsocket_positive.py)：测试本地进程间正常通信
- [TLS加密通信测试](tests/test_tls_positive.py)：测试TLS正常加密通信

### 边界测试用例
- [最大连接数测试](tests/test_connection_limit.py)：测试服务端最大并发连接数
- [大数据包测试](tests/test_large_data.py)：测试发送和接收大数据包（接近64KB）
- [超时测试](tests/test_timeout.py)：测试各种超时场景
- [端口范围测试](tests/test_port_range.py)：测试端口边界值（1和65535）

### 异常测试用例
- [无效IP地址测试](tests/test_invalid_ip.py)：测试无效IP地址的错误处理
- [端口被占用测试](tests/test_port_occupied.py)：测试端口被占用的错误处理
- [网络断开测试](tests/test_network_disconnect.py)：测试网络断开的错误处理
- [证书错误测试](tests/test_certificate_error.py)：测试TLS证书错误的处理
- [权限不足测试](tests/test_permission_denied.py)：测试未申请权限的错误处理
- [DNS解析失败测试](tests/test_dns_failure.py)：测试DNS解析失败的处理