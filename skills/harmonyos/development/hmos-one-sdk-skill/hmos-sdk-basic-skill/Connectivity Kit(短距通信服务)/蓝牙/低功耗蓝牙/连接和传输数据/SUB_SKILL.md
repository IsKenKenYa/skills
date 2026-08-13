---
name: hmos-connectivity-kit-gatt-connection
description: 实现BLE设备间基于GATT协议的连接和数据传输,支持客户端和服务端两种角色,包含服务发现、特征值读写、描述符读写、通知/指示机制,适用于智能穿戴、健康监测、智能家居、传感器数据采集场景
---

# GATT连接和数据传输技能

## 功能描述

本技能提供基于通用属性协议（Generic Attribute Profile，GATT）实现BLE设备间连接和传输数据的完整开发指导。支持两种角色：
- **客户端（Client）**：主动发起连接，查询服务端支持的服务能力，读写特征值和描述符，接收服务端的通知或指示
- **服务端（Server）**：提供特定服务，等待客户端连接，响应客户端的读写请求，主动发送特征值变化通知或指示

核心功能包括：
1. 创建GATT客户端/服务端实例
2. 订阅连接状态变化事件
3. 发起连接（客户端）或添加服务（服务端）
4. 服务发现（客户端）获取服务端支持的所有服务能力
5. 读写特征值和描述符，实现双向数据传输
6. 接收/发送特征值变化通知或指示，实现实时数据更新
7. 断开连接并释放资源

## 使用场景

### 触发词
- "GATT连接"
- "BLE数据传输"
- "低功耗蓝牙通信"
- "蓝牙特征值读写"
- "BLE服务发现"
- "蓝牙通知/指示"
- "BLE客户端/服务端"
- "智能穿戴设备连接"
- "健康监测数据传输"
- "智能家居设备通信"

### 能做
- 实现BLE设备间的GATT连接建立和断开
- 实现客户端主动发现服务端的服务能力
- 实现客户端读写服务端的特征值和描述符
- 实现服务端响应客户端的读写请求
- 实现客户端接收服务端的特征值变化通知或指示
- 实现服务端主动发送特征值变化通知或指示
- 实现双向数据传输和实时数据更新
- 提供完整的客户端和服务端实现示例

### 绝不做
- 不处理非BLE蓝牙协议（如经典蓝牙）
- 不处理BLE扫描和广播流程（需要使用查找设备技能）
- 不处理配对和绑定流程
- 不提供加密和安全连接的实现
- 不处理超出GATT协议范围的数据传输方式

### 补充
- 需要申请ohos.permission.ACCESS_BLUETOOTH权限
- 客户端需要通过BLE扫描获取服务端设备地址
- 服务端需要发送BLE广播才能被客户端发现
- 特征值变化通知/指示需要包含Client Characteristic Configuration描述符（UUID: 00002902-0000-1000-8000-00805f9b34fb）
- 读写操作必须在服务发现完成后进行
- 所有异步操作需要等待回调结果后才能进行下一次操作

## 调用规范和规则

### 输入约束
- 设备地址格式：必须是有效的BLE设备地址格式（如"XX:XX:XX:XX:XX:XX")
- UUID格式：必须符合蓝牙UUID标准格式（如"00001810-0000-1000-8000-00805F9B34FB")
- 特征值/描述符数据：必须是ArrayBuffer类型
- 服务发现：必须在连接成功后调用getServices()
- 读写操作：必须确保特征值/描述符在服务发现结果中存在

### 执行约束
- 最大连接耗时：30秒（建议超时设置）
- 最大服务发现耗时：10秒
- 最大单次读写耗时：5秒
- 异步操作等待：必须等待异步回调完成才能进行下一次操作
- 连接状态检查：所有操作必须在STATE_CONNECTED状态下进行（客户端）
- 订阅事件：必须在连接前订阅连接状态变化事件

### 内容约束
- 禁止伪造设备地址：必须使用真实的BLE设备地址
- 禁止伪造UUID：必须使用真实的蓝牙UUID或自定义UUID
- 禁止跳过服务发现：读写操作前必须先调用getServices()
- 禁止并发读写：必须等待上一次读写操作完成
- 禁止使用高危函数：禁止使用eval、exec等高危函数
- 禁止硬编码敏感信息：禁止在代码中硬编码设备地址、UUID等敏感信息

### 降级约束
- 连接失败：提示用户检查设备是否开启蓝牙、设备地址是否正确，建议重新扫描设备
- 服务发现失败：提示用户服务端可能不支持所需服务，建议检查服务端配置
- 读写失败：提示用户特征值/描述符可能不存在或权限不足，建议重新进行服务发现
- 通知/指示失败：提示用户检查Client Characteristic Configuration描述符是否存在，建议重新订阅
- 超时处理：建议设置合理的超时时间，超时后自动断开连接并释放资源

## 调用流程和步骤

### 客户端实现流程

#### 步骤1：申请蓝牙权限

**前置校验**：
1. 检查应用是否已申请ohos.permission.ACCESS_BLUETOOTH权限
2. 检查用户是否已授权该权限

**权限申请代码**：
```typescript
// 在module.json5中声明权限
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.ACCESS_BLUETOOTH",
        "reason": "用于BLE设备连接和数据传输",
        "usedScene": {
          "abilities": ["EntryAbility"],
          "when": "inuse"
        }
      }
    ]
  }
}
```

#### 步骤2：导入所需API模块

```typescript
import { ble, constant } from '@kit.ConnectivityKit';
import { BusinessError } from '@kit.BasicServicesKit';
```

#### 步骤3：创建客户端实例并订阅连接状态

**示例代码**：
```typescript
let device = 'XX:XX:XX:XX:XX:XX'; // 服务端设备地址，通过BLE扫描获取

// 定义连接状态变化回调函数
function clientConnectStateChanged(state: ble.BLEConnectionChangeState) {
  console.info('bluetooth connect state changed');
  let connectState: ble.ProfileConnectionState = state.state;
  
  switch (connectState) {
    case constant.ProfileConnectionState.STATE_CONNECTED:
      console.info('Device connected');
      // 连接成功后进行服务发现
      discoverServices();
      break;
    case constant.ProfileConnectionState.STATE_DISCONNECTED:
      console.info('Device disconnected');
      // 断连后清理资源
      cleanupResources();
      break;
    case constant.ProfileConnectionState.STATE_CONNECTING:
      console.info('Device connecting');
      break;
    case constant.ProfileConnectionState.STATE_DISCONNECTING:
      console.info('Device disconnecting');
      break;
  }
}

try {
  let gattClient: ble.GattClientDevice = ble.createGattClientDevice(device);
  // 订阅连接状态变化事件
  gattClient.on('BLEConnectionStateChange', clientConnectStateChanged);
} catch (err) {
  console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
}
```

#### 步骤4：发起连接

```typescript
try {
  let gattClient: ble.GattClientDevice = ble.createGattClientDevice(device);
  gattClient.connect();
} catch (err) {
  console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
}
```

#### 步骤5：服务发现

**说明**：
- 必须在连接成功后调用getServices()
- 服务发现结果用于后续的读写操作
- 必须确保服务端存在所需的服务、特征值和描述符

```typescript
function discoverServices() {
  try {
    gattClient.getServices().then((result: Array<ble.GattService>) => {
      console.info('getServices successfully:' + JSON.stringify(result));
      // 检查服务端是否支持所需的服务
      checkServices(result);
    });
  } catch (err) {
    console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
  }
}

function checkServices(services: Array<ble.GattService>) {
  const myServiceUuid = '00001810-0000-1000-8000-00805F9B34FB';
  const myCharacteristicUuid = '00001820-0000-1000-8000-00805F9B34FB';
  
  for (let service of services) {
    if (service.serviceUuid === myServiceUuid) {
      for (let char of service.characteristics) {
        if (char.characteristicUuid === myCharacteristicUuid) {
          console.info('Found required service and characteristic');
          // 保存特征值对象，用于后续读写操作
          myCharacteristic = char;
          return;
        }
      }
    }
  }
  console.error('Required service or characteristic not found');
}
```

#### 步骤6：传输数据

**6.1 读取特征值**

```typescript
function readCharacteristicValue() {
  if (!myCharacteristic) {
    console.error('Characteristic not found');
    return;
  }
  
  try {
    gattClient.readCharacteristicValue(myCharacteristic).then((outData: ble.BLECharacteristic) => {
      console.info('readCharacteristicValue successfully');
      let value = new Uint8Array(outData.characteristicValue);
      console.info('Characteristic value: ' + JSON.stringify(value));
    });
  } catch (err) {
    console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
  }
}
```

**6.2 写入特征值**

```typescript
function writeCharacteristicValue() {
  if (!myCharacteristic) {
    console.error('Characteristic not found');
    return;
  }
  
  // 构造写入数据
  let bufferCCC = new ArrayBuffer(2);
  let cccV = new Uint8Array(bufferCCC);
  cccV[0] = 1;
  cccV[1] = 2;
  
  myCharacteristic.characteristicValue = bufferCCC;
  
  try {
    gattClient.writeCharacteristicValue(myCharacteristic, ble.GattWriteType.WRITE, (err) => {
      if (err) {
        console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
        return;
      }
      console.info('writeCharacteristicValue success');
    });
  } catch (err) {
    console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
  }
}
```

**6.3 读取描述符**

```typescript
function readDescriptorValue(descriptor: ble.BLEDescriptor) {
  try {
    gattClient.readDescriptorValue(descriptor).then((outData: ble.BLEDescriptor) => {
      console.info('readDescriptorValue successfully');
      let value = new Uint8Array(outData.descriptorValue);
      console.info('Descriptor value: ' + JSON.stringify(value));
    });
  } catch (err) {
    console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
  }
}
```

**6.4 写入描述符**

```typescript
function writeDescriptorValue(descriptor: ble.BLEDescriptor) {
  // 构造写入数据
  let bufferDesc = new ArrayBuffer(2);
  let descV = new Uint8Array(bufferDesc);
  descV[0] = 11;
  descV[1] = 12;
  
  descriptor.descriptorValue = bufferDesc;
  
  try {
    gattClient.writeDescriptorValue(descriptor, (err) => {
      if (err) {
        console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
        return;
      }
      console.info('writeDescriptorValue success');
    });
  } catch (err) {
    console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
  }
}
```

**6.5 接收特征值变化通知或指示**

```typescript
// 定义特征值变化回调函数
function characteristicChange(characteristicChangeReq: ble.BLECharacteristic) {
  let serviceUuid: string = characteristicChangeReq.serviceUuid;
  let characteristicUuid: string = characteristicChangeReq.characteristicUuid;
  let value: Uint8Array = new Uint8Array(characteristicChangeReq.characteristicValue);
  console.info('Characteristic changed: uuid=' + characteristicUuid + ', value=' + JSON.stringify(value));
}

// 订阅特征值变化事件
try {
  gattClient.on('BLECharacteristicChange', characteristicChange);
} catch (err) {
  console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
}

// 设置特征值变化通知能力（二选一）
try {
  // enable: true表示启用，false表示禁用
  gattClient.setCharacteristicChangeNotification(myCharacteristic, true, (err: BusinessError) => {
    if (err) {
      console.error('setCharacteristicChangeNotification failed');
    } else {
      console.info('setCharacteristicChangeNotification success');
    }
  });
} catch (err) {
  console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
}

// 或者设置特征值变化指示能力（二选一）
try {
  gattClient.setCharacteristicChangeIndication(myCharacteristic, true, (err: BusinessError) => {
    if (err) {
      console.error('setCharacteristicChangeIndication failed');
    } else {
      console.info('setCharacteristicChangeIndication success');
    }
  });
} catch (err) {
  console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
}
```

#### 步骤7：断开连接

```typescript
function disconnect() {
  try {
    // 断开连接
    gattClient.disconnect();
    // 取消订阅事件
    gattClient.off('BLEConnectionStateChange', clientConnectStateChanged);
    gattClient.off('BLECharacteristicChange', characteristicChange);
    // 关闭客户端实例，释放资源
    gattClient.close();
  } catch (err) {
    console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
  }
}
```

### 服务端实现流程

#### 步骤1：创建服务端实例

```typescript
try {
  let gattServer: ble.GattServer = ble.createGattServer();
} catch (err) {
  console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
}
```

#### 步骤2：添加服务

**说明**：
- 添加应用需要的服务，将在蓝牙子系统中注册指定的UUID服务
- 服务包含特征值和描述符
- 必须添加Client Characteristic Configuration描述符以支持通知/指示能力

```typescript
// 创建描述符
let descriptors: Array<ble.BLEDescriptor> = [];
let arrayBuffer = new ArrayBuffer(2);
let descV = new Uint8Array(arrayBuffer);
descV[0] = 11;

// Client Characteristic Configuration描述符（用于通知/指示）
let descriptor: ble.BLEDescriptor = {
  serviceUuid: '00001810-0000-1000-8000-00805F9B34FB',
  characteristicUuid: '00001820-0000-1000-8000-00805F9B34FB',
  descriptorUuid: '00002902-0000-1000-8000-00805F9B34FB',
  descriptorValue: arrayBuffer
};
descriptors[0] = descriptor;

// 创建特征值
let characteristics: Array<ble.BLECharacteristic> = [];
let arrayBufferC = new ArrayBuffer(2);
let cccV = new Uint8Array(arrayBufferC);
cccV[0] = 1;

let characteristic: ble.BLECharacteristic = {
  serviceUuid: '00001810-0000-1000-8000-00805F9B34FB',
  characteristicUuid: '00001820-0000-1000-8000-00805F9B34FB',
  characteristicValue: arrayBufferC,
  descriptors: descriptors
};
characteristics[0] = characteristic;

// 创建服务
let gattService: ble.GattService = {
  serviceUuid: '00001810-0000-1000-8000-00805F9B34FB',
  isPrimary: true,
  characteristics: characteristics,
  includeServices: []
};

try {
  gattServer.addService(gattService);
} catch (err) {
  console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
}
```

#### 步骤3：订阅连接状态变化事件

```typescript
function ServerConnectStateChanged(state: ble.BLEConnectionChangeState) {
  console.info('bluetooth connect state changed');
  let connectState: ble.ProfileConnectionState = state.state;
  let device = state.deviceId; // 客户端设备地址
  
  switch (connectState) {
    case constant.ProfileConnectionState.STATE_CONNECTED:
      console.info('Client connected: ' + device);
      // 保存客户端设备地址，用于发送通知/指示
      clientDevice = device;
      break;
    case constant.ProfileConnectionState.STATE_DISCONNECTED:
      console.info('Client disconnected');
      // 清理客户端设备地址
      clientDevice = '';
      break;
  }
}

try {
  gattServer.on('connectionStateChange', ServerConnectStateChanged);
} catch (err) {
  console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
}
```

#### 步骤4：订阅读写事件并响应客户端请求

**4.1 订阅特征值读取事件**

```typescript
let charBuffer = new ArrayBuffer(2);
let charValue = new Uint8Array(charBuffer);
charValue[0] = 1;
charValue[1] = 2;

function readCharacteristicReq(characteristicReadRequest: ble.CharacteristicReadRequest) {
  let deviceId: string = characteristicReadRequest.deviceId;
  let transId: number = characteristicReadRequest.transId;
  let offset: number = characteristicReadRequest.offset;
  let characteristicUuid: string = characteristicReadRequest.characteristicUuid;
  
  console.info('receive characteristicRead: uuid=' + characteristicUuid);
  
  // 构造响应
  let serverResponse: ble.ServerResponse = {
    deviceId: deviceId,
    transId: transId,
    status: 0, // 0表示成功
    offset: offset,
    value: charBuffer // 传入特征值的数据内容
  };
  
  try {
    gattServer.sendResponse(serverResponse);
  } catch (err) {
    console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
  }
}

gattServer.on('characteristicRead', readCharacteristicReq);
```

**4.2 订阅特征值写入事件**

```typescript
function writeCharacteristicReq(characteristicWriteRequest: ble.CharacteristicWriteRequest) {
  let deviceId: string = characteristicWriteRequest.deviceId;
  let transId: number = characteristicWriteRequest.transId;
  let offset: number = characteristicWriteRequest.offset;
  let needRsp: boolean = characteristicWriteRequest.needRsp;
  let value: Uint8Array = new Uint8Array(characteristicWriteRequest.value);
  
  console.info('receive characteristicWrite: value=' + JSON.stringify(value));
  
  // 保存写入的数据内容
  charValue[0] = value[0];
  charValue[1] = value[1];
  
  // 根据needRsp判断是否需要回复
  if (!needRsp) {
    return;
  }
  
  // 构造响应
  let rspBuffer = new ArrayBuffer(0);
  let serverResponse: ble.ServerResponse = {
    deviceId: deviceId,
    transId: transId,
    status: 0,
    offset: offset,
    value: rspBuffer
  };
  
  try {
    gattServer.sendResponse(serverResponse);
    // 特征值变化了，可以主动发送变化通知或指示
    sendCharacteristicChange();
  } catch (err) {
    console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
  }
}

gattServer.on('characteristicWrite', writeCharacteristicReq);
```

**4.3 订阅描述符读取事件**

```typescript
let descBuffer = new ArrayBuffer(2);
let descValue = new Uint8Array(descBuffer);
descValue[0] = 1;

function readDescriptorReq(descriptorReadRequest: ble.DescriptorReadRequest) {
  let deviceId: string = descriptorReadRequest.deviceId;
  let transId: number = descriptorReadRequest.transId;
  let offset: number = descriptorReadRequest.offset;
  let descriptorUuid: string = descriptorReadRequest.descriptorUuid;
  
  console.info('receive descriptorRead: uuid=' + descriptorUuid);
  
  // 构造响应
  let serverResponse: ble.ServerResponse = {
    deviceId: deviceId,
    transId: transId,
    status: 0,
    offset: offset,
    value: descBuffer
  };
  
  try {
    gattServer.sendResponse(serverResponse);
  } catch (err) {
    console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
  }
}

gattServer.on('descriptorRead', readDescriptorReq);
```

**4.4 订阅描述符写入事件**

```typescript
function writeDescriptorReq(descriptorWriteRequest: ble.DescriptorWriteRequest) {
  let deviceId: string = descriptorWriteRequest.deviceId;
  let transId: number = descriptorWriteRequest.transId;
  let offset: number = descriptorWriteRequest.offset;
  let needRsp: boolean = descriptorWriteRequest.needRsp;
  let value: Uint8Array = new Uint8Array(descriptorWriteRequest.value);
  
  console.info('receive descriptorWrite: value=' + JSON.stringify(value));
  
  // 保存写入的数据内容
  descValue[0] = value[0];
  descValue[1] = value[1];
  
  // 根据needRsp判断是否需要回复
  if (!needRsp) {
    return;
  }
  
  // 构造响应
  let rspBuffer = new ArrayBuffer(0);
  let serverResponse: ble.ServerResponse = {
    deviceId: deviceId,
    transId: transId,
    status: 0,
    offset: offset,
    value: rspBuffer
  };
  
  try {
    gattServer.sendResponse(serverResponse);
  } catch (err) {
    console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
  }
}

gattServer.on('descriptorWrite', writeDescriptorReq);
```

#### 步骤5：发送特征值变化通知或指示

**说明**：
- 当服务端的特征值数据内容发生变化时，可以通过通知或指示主动知会到客户端
- 发送通知时，不需要客户端回复确认
- 发送指示时，需要客户端回复确认
- 该特征值需包含Client Characteristic Configuration描述符（UUID: 00002902-0000-1000-8000-00805f9b34fb）

```typescript
function sendCharacteristicChange() {
  if (!clientDevice) {
    console.error('No client connected');
    return;
  }
  
  // 构造通知特征值
  let notifyCharacter: ble.NotifyCharacteristic = {
    serviceUuid: '00001810-0000-1000-8000-00805F9B34FB',
    characteristicUuid: '00001820-0000-1000-8000-00805F9B34FB',
    characteristicValue: charBuffer,
    confirm: false // false表示通知，true表示指示
  };
  
  try {
    gattServer.notifyCharacteristicChanged(clientDevice, notifyCharacter, (err: BusinessError) => {
      if (err) {
        console.error('notifyCharacteristicChanged failed');
      } else {
        console.info('notifyCharacteristicChanged success');
      }
    });
  } catch (err) {
    console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
  }
}
```

#### 步骤6：关闭服务端实例

```typescript
function closeServer() {
  try {
    // 删除此前注册的服务
    gattServer.removeService('00001810-0000-1000-8000-00805F9B34FB');
    // 取消订阅事件
    gattServer.off('connectionStateChange', ServerConnectStateChanged);
    gattServer.off('characteristicRead', readCharacteristicReq);
    gattServer.off('characteristicWrite', writeCharacteristicReq);
    gattServer.off('descriptorRead', readDescriptorReq);
    gattServer.off('descriptorWrite', writeDescriptorReq);
    // 关闭服务端实例，释放资源
    gattServer.close();
  } catch (err) {
    console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | Invalid parameter | 检查参数类型和取值范围是否正确，确保必填参数已指定 |
| 801 | Capability not supported | 检查设备是否支持BLE功能，确保API版本正确 |
| 201 | Permission denied | 检查是否已申请ohos.permission.ACCESS_BLUETOOTH权限并获得用户授权 |
| 2900001 | Service stopped | 检查蓝牙服务是否正常启动，建议重启蓝牙 |
| 2900003 | Bluetooth disabled | 检查蓝牙是否已开启，建议提示用户开启蓝牙 |
| 2900099 | Operation failed | 检查操作流程是否正确，建议重新执行操作 |
| 2900004 | Profile not supported | 检查设备是否支持GATT Profile |
| 2900005 | Device not found | 检查设备地址是否正确，建议重新扫描设备 |
| 2900006 | Device not connected | 检查设备连接状态，确保在STATE_CONNECTED状态下操作 |
| 2900007 | Service not found | 检查服务UUID是否正确，建议重新进行服务发现 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.ConnectivityKit": "最新版本",
    "@kit.BasicServicesKit": "最新版本"
  }
}
```

### 环境要求
- HarmonyOS API version: 10+
- 设备支持: BLE功能正常
- 开发环境: DevEco Studio最新版本

### 常见编译问题

**问题1：导入模块失败**
```
Error: Cannot find module '@kit.ConnectivityKit'
```
**解决方法**：
1. 检查API version是否>=10
2. 检查项目配置是否正确
3. 更新DevEco Studio到最新版本

**问题2：权限申请失败**
```
Error: Permission denied
```
**解决方法**：
1. 在module.json5中正确声明权限
2. 运行时向用户申请授权
3. 检查用户是否已授权

**问题3：类型定义错误**
```
Error: Property 'connect' does not exist on type 'GattClientDevice'
```
**解决方法**：
1. 检查导入的模块是否正确
2. 检查API version是否支持该方法
3. 更新SDK版本

**问题4：异步操作未等待**
```
Error: Operation failed because previous operation not completed
```
**解决方法**：
1. 确保异步操作等待回调完成
2. 使用Promise或async/await处理异步流程
3. 添加状态检查逻辑

## 常见问题与解决方法

### Q1：连接失败或超时
**原因**：
- 设备地址不正确
- 服务端未发送BLE广播
- 蓝牙未开启
- 超时时间设置不合理

**解决方法**：
- 使用BLE扫描获取正确的设备地址
- 确保服务端已发送BLE广播
- 提示用户开启蓝牙
- 设置合理的超时时间（建议30秒）
- 添加连接失败重试逻辑

### Q2：服务发现失败
**原因**：
- 服务端未添加所需服务
- 服务UUID不匹配
- 连接状态不正确

**解决方法**：
- 检查服务端是否已添加所需服务
- 确保服务UUID格式正确且匹配
- 在STATE_CONNECTED状态下调用getServices()
- 重新进行服务发现

### Q3：读写操作失败
**原因**：
- 特征值/描述符不存在
- 未完成服务发现
- 权限不足
- 数据格式不正确

**解决方法**：
- 确保特征值/描述符在服务发现结果中存在
- 在服务发现完成后进行读写操作
- 检查特征值/描述符的权限属性
- 确保数据为ArrayBuffer类型
- 检查数据长度是否符合要求

### Q4：通知/指示失败
**原因**：
- 未包含Client Characteristic Configuration描述符
- 客户端未订阅特征值变化事件
- 客户端未使能通知/指示能力
- 连接状态不正确

**解决方法**：
- 添加Client Characteristic Configuration描述符（UUID: 00002902-0000-1000-8000-00805f9b34fb）
- 客户端订阅'BLECharacteristicChange'事件
- 客户端调用setCharacteristicChangeNotification或setCharacteristicChangeIndication
- 在STATE_CONNECTED状态下操作

### Q5：资源未释放导致内存泄漏
**原因**：
- 未调用disconnect()
- 未调用close()
- 未取消订阅事件

**解决方法**：
- 在不再使用时主动调用disconnect()断开连接
- 调用close()销毁实例并释放资源
- 使用off()取消订阅所有事件
- 在应用退出时清理所有资源

### Q6：并发读写操作导致失败
**原因**：
- 未等待上一次操作完成
- 未遵循异步操作等待规则

**解决方法**：
- 使用Promise或async/await等待异步操作完成
- 添加操作状态管理逻辑
- 确保每次操作完成后才进行下一次操作
- 使用队列管理读写操作顺序

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "device": "XX:XX:XX:XX:XX:XX",
  "connectionState": "STATE_CONNECTED",
  "services": [
    {
      "serviceUuid": "00001810-0000-1000-8000-00805F9B34FB",
      "characteristics": [
        {
          "characteristicUuid": "00001820-0000-1000-8000-00805F9B34FB",
          "properties": ["read", "write", "notify"]
        }
      ]
    }
  ],
  "dataTransferred": {
    "readOperations": 5,
    "writeOperations": 3,
    "notificationsReceived": 10
  },
  "apiUsed": [
    "ble.createGattClientDevice",
    "gattClient.connect",
    "gattClient.getServices",
    "gattClient.readCharacteristicValue",
    "gattClient.writeCharacteristicValue",
    "gattClient.setCharacteristicChangeNotification",
    "gattClient.disconnect",
    "gattClient.close"
  ]
}
```

## 参考文档

- [API开发指南](references/gatt-development-guide.md)
- [BLE API参考说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-bluetooth-ble)
- [蓝牙常量定义](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-bluetooth-constant)
- [Connectivity Kit术语](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/terminology)
- [查找设备指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ble-development-guide)
- [声明权限](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/declare-permissions)
- [向用户申请授权](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/request-user-authorization)

## 完整示例代码

- [客户端完整示例](assets/gatt_client_example.ets)
- [服务端完整示例](assets/gatt_server_example.ets)
- [配置文件示例](assets/module.json5)

## 测试用例

### 正向测试用例
- [客户端连接和读写测试](tests/test_client_connection.py)：测试客户端正常连接、服务发现、读写操作流程
- [服务端响应测试](tests/test_server_response.py)：测试服务端正常响应客户端读写请求
- [通知/指示测试](tests/test_notification.py)：测试特征值变化通知和指示机制

### 边界测试用例
- [大数据量传输测试](tests/test_large_data.py)：测试大数据量读写操作的稳定性
- [多服务支持测试](tests/test_multiple_services.py)：测试服务端支持多个服务的场景
- [长时间连接测试](tests/test_long_connection.py)：测试长时间连接的稳定性

### 异常测试用例
- [连接失败测试](tests/test_connection_failure.py)：测试连接失败、超时等异常场景的处理
- [读写失败测试](tests/test_read_write_failure.py)：测试特征值/描述符不存在、权限不足等异常场景
- [资源释放测试](tests/test_resource_cleanup.py)：测试未释放资源导致的内存泄漏问题
- [并发操作测试](tests/test_concurrent_operations.py)：测试并发读写操作的冲突处理