---
name: hmos-connectivity-kit-bluetooth-discovery
description: 扫描周边蓝牙设备获取设备信息，支持传统蓝牙和BLE设备，需ACCESS_BLUETOOTH权限，最大扫描12秒，适用于设备发现、配对连接场景
---

# 蓝牙设备查找技能

## 功能描述

本技能用于扫描周边蓝牙设备并获取设备信息。支持扫描传统蓝牙设备（BR/EDR）和低功耗蓝牙设备（BLE），可获取设备地址、设备名称、设备类型、设备信号强度等详细信息。扫描过程大约持续12秒，需要设备处于可被发现状态才能被扫描到。扫描结果可用于后续的配对、连接和传输数据流程。

**核心能力**：
- 开启/停止蓝牙设备扫描
- 订阅扫描结果上报事件
- 获取设备详细信息（地址、名称、类型、信号强度）
- 查询已配对设备信息
- 获取设备配对状态

**技术特点**：
- API version 18+推荐使用`connection.on('discoveryResult')`，支持获取完整设备信息
- API version 10支持`connection.on('bluetoothDeviceFind')`，仅获取设备地址
- 扫描过程持续约12秒，消耗蓝牙硬件资源
- 获取的设备地址为虚拟MAC地址（基于信息安全考虑）

## 使用场景

### 触发词
- "查找设备" - 扫描周边蓝牙设备
- "扫描蓝牙" - 开启蓝牙扫描
- "发现设备" - 发现周边蓝牙设备
- "搜索蓝牙" - 搜索蓝牙设备
- "查询已配对设备" - 获取已配对设备列表
- "蓝牙发现" - 蓝牙设备发现流程

### 能做
- 扫描周边支持蓝牙能力的设备
- 获取蓝牙设备地址、名称、类型、信号强度信息
- 判断本机设备是否正在进行扫描
- 查询已配对设备信息列表
- 获取指定设备的配对状态
- 设置本机蓝牙扫描模式（可被发现、可被连接）

### 绝不做
- 不直接配对或连接设备（需要使用配对连接技能）
- 不传输数据（需要使用数据传输技能）
- 不扫描非蓝牙设备
- 不修改其他应用的扫描状态
- 不持久化保存扫描结果（需要使用`access.addPersistentDeviceId`）

### 补充
- 必须先申请`ohos.permission.ACCESS_BLUETOOTH`权限
- 目标设备必须处于可被发现状态
- 扫描过程消耗蓝牙硬件资源，完成后必须停止扫描
- 扫描期间无法启动新的扫描流程
- 获取的设备地址为虚拟MAC地址，可能随蓝牙开关重启而变更
- 已配对设备的虚拟地址不会变更

## 调用规范和规则

### 输入约束
- **权限要求**：必须申请`ohos.permission.ACCESS_BLUETOOTH`权限
- **API版本**：基础功能API version 10+，推荐使用API version 18+获取完整设备信息
- **系统要求**：SystemCapability.Communication.Bluetooth.Core
- **蓝牙状态**：本机蓝牙必须开启
- **目标状态**：目标设备必须处于可被发现状态

### 执行约束
- **扫描时长**：扫描过程大约持续12秒
- **扫描状态**：扫描期间不能重复调用`startBluetoothDiscovery`
- **资源消耗**：扫描消耗蓝牙硬件资源，完成后必须停止
- **最大频次**：必须停止当前扫描才能开始新的扫描
- **并发限制**：同一时间只能有一个扫描流程

### 内容约束
- **禁止重复调用**：扫描过程中禁止再次调用`startBluetoothDiscovery`
- **禁止直接配对**：扫描技能不执行配对操作
- **禁止持久化地址**：不直接持久化虚拟MAC地址（需使用`access.addPersistentDeviceId`）
- **禁止修改其他应用状态**：不干扰其他应用的扫描流程

### 降级约束
- **权限不足**：提示用户申请权限，引导用户查看[声明权限](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/declare-permissions)和[向用户申请授权](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/request-user-authorization)
- **蓝牙未开启**：提示用户开启蓝牙，返回错误码2900003
- **找不到设备**：提示用户目标设备未处于可被发现状态，建议检查目标设备设置
- **扫描失败**：返回错误信息，提供错误码和解决方法

## 调用流程和步骤

### 步骤1：准备阶段（申请权限和导入模块）

**前置校验**：
1. 检查是否已申请`ohos.permission.ACCESS_BLUETOOTH`权限
2. 检查本机蓝牙是否已开启
3. 检查系统是否支持SystemCapability.Communication.Bluetooth.Core

**参数准备**：
```typescript
// 导入必要模块
import { connection } from '@kit.ConnectivityKit';
import { BusinessError } from '@kit.BasicServicesKit';

// 配置参数（可选）
const discoveryConfig = {
  maxDuration: 12000, // 最大扫描时长12秒
  reportInterval: 1000 // 结果上报间隔（系统默认）
};
```

### 步骤2：订阅扫描结果上报事件

**API版本选择**：
- **API version 18+（推荐）**：使用`connection.on('discoveryResult')`，可获取设备地址、名称、类型、信号强度
- **API version 10-17**：使用`connection.on('bluetoothDeviceFind')`，仅获取设备地址

**示例代码（API 18+推荐方式）**：
```typescript
// 定义扫描结果上报回调函数
function onDiscoveryResult(data: Array<connection.DiscoveryResult>) {
  console.info('发现蓝牙设备: ' + JSON.stringify(data));
  // 处理扫描结果
  for (const device of data) {
    console.info(`设备地址: ${device.deviceId}`);
    console.info(`设备名称: ${device.deviceName}`);
    console.info(`设备类型: ${device.majorClass}`);
    console.info(`信号强度: ${device.rssi}`);
  }
}

try {
  // 发起订阅（API 18+）
  connection.on('discoveryResult', onDiscoveryResult);
  console.info('已订阅扫描结果上报事件');
} catch (err) {
  const error = err as BusinessError;
  console.error('订阅失败: errCode=' + error.code + ', errMessage=' + error.message);
}
```

**示例代码（API 10兼容方式）**：
```typescript
// 定义扫描结果上报回调函数（仅获取地址）
function onBluetoothDeviceFind(data: Array<string>) {
  console.info('发现蓝牙设备地址: ' + JSON.stringify(data));
}

try {
  // 发起订阅（API 10）
  connection.on('bluetoothDeviceFind', onBluetoothDeviceFind);
  console.info('已订阅扫描结果上报事件');
} catch (err) {
  const error = err as BusinessError;
  console.error('订阅失败: errCode=' + error.code + ', errMessage=' + error.message);
}
```

### 步骤3：发起设备扫描

**示例代码**：
```typescript
try {
  // 判断本机设备是否正在进行扫描
  const isDiscovering = connection.isBluetoothDiscovering();
  console.info('当前扫描状态: ' + isDiscovering);
  
  if (!isDiscovering) {
    // 若当前不处于扫描过程，则开始扫描设备
    connection.startBluetoothDiscovery();
    console.info('已开始蓝牙设备扫描，扫描将持续约12秒');
  } else {
    console.warn('当前正在进行扫描，无法启动新的扫描');
  }
} catch (err) {
  const error = err as BusinessError;
  console.error('扫描启动失败: errCode=' + error.code + ', errMessage=' + error.message);
  
  // 错误处理
  switch (error.code) {
    case 201:
      console.error('权限不足，请申请ACCESS_BLUETOOTH权限');
      break;
    case 2900003:
      console.error('蓝牙未开启，请先开启蓝牙');
      break;
    case 2900001:
      console.error('蓝牙服务已停止');
      break;
    default:
      console.error('扫描失败: ' + error.message);
  }
}
```

### 步骤4：处理扫描结果

**示例代码**：
```typescript
// 扫描结果处理函数（在回调中实现）
function processDiscoveryResults(devices: Array<connection.DiscoveryResult>) {
  // 筛选需要的设备
  const targetDevices = devices.filter(device => {
    // 根据设备类型筛选（例如：只查找音频设备）
    return device.majorClass === connection.MajorClass.AUDIO_VIDEO;
  });
  
  // 排序设备（按信号强度排序）
  targetDevices.sort((a, b) => b.rssi - a.rssi);
  
  // 提取设备信息
  const deviceList = targetDevices.map(device => ({
    address: device.deviceId,
    name: device.deviceName || '未知设备',
    type: device.majorClass,
    signalStrength: device.rssi
  }));
  
  console.info('筛选后的设备列表: ' + JSON.stringify(deviceList));
  return deviceList;
}
```

### 步骤5：停止设备扫描

**示例代码**：
```typescript
try {
  // 判断本机设备是否正在进行扫描
  const isDiscovering = connection.isBluetoothDiscovering();
  
  if (isDiscovering) {
    // 若当前处于扫描过程，则停止扫描设备
    connection.stopBluetoothDiscovery();
    console.info('已停止蓝牙设备扫描');
  }
  
  // 若不再需要使用扫描，取消订阅扫描上报结果
  connection.off('discoveryResult', onDiscoveryResult);
  console.info('已取消订阅扫描结果上报事件');
} catch (err) {
  const error = err as BusinessError;
  console.error('停止扫描失败: errCode=' + error.code + ', errMessage=' + error.message);
}
```

### 步骤6：查询已配对设备（可选）

**示例代码**：
```typescript
try {
  // 获取已配对设备信息
  const pairedDevices = connection.getPairedDevices();
  console.info('已配对设备列表: ' + JSON.stringify(pairedDevices));
  
  // 若已知设备地址，查询该设备是否已配对
  if (pairedDevices.length > 0) {
    const deviceAddress = pairedDevices[0];
    const pairState = connection.getPairState(deviceAddress);
    console.info('设备 ' + deviceAddress + ' 配对状态: ' + pairState);
    
    // 配对状态说明
    switch (pairState) {
      case connection.BondState.BOND_STATE_BONDED:
        console.info('设备已配对');
        break;
      case connection.BondState.BOND_STATE_BONDING:
        console.info('设备正在配对');
        break;
      case connection.BondState.BOND_STATE_INVALID:
        console.info('设备未配对');
        break;
    }
  }
} catch (err) {
  const error = err as BusinessError;
  console.error('查询已配对设备失败: errCode=' + error.code + ', errMessage=' + error.message);
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 201 | Permission denied | 申请`ohos.permission.ACCESS_BLUETOOTH`权限，参考[声明权限](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/declare-permissions)和[向用户申请授权](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/request-user-authorization) |
| 401 | Invalid parameter | 检查参数是否正确，确保参数类型匹配、必填参数已指定 |
| 801 | Capability not supported | 当前设备不支持蓝牙能力，请检查设备是否支持SystemCapability.Communication.Bluetooth.Core |
| 2900001 | Service stopped | 蓝牙服务已停止，请重启蓝牙服务 |
| 2900003 | Bluetooth disabled | 蓝牙未开启，请先开启蓝牙 |
| 2900099 | Operation failed | 操作失败，请检查蓝牙状态、设备状态，重试操作 |

## 编译和修复问题

### 依赖声明

**oh-package.json5配置**：
```json
{
  "dependencies": {
    "@kit.ConnectivityKit": "^1.0.0",
    "@kit.BasicServicesKit": "^1.0.0"
  }
}
```

**模块导入**：
```typescript
import { connection } from '@kit.ConnectivityKit';
import { BusinessError } from '@kit.BasicServicesKit';
```

### 环境要求
- **API版本**：API version 10+（基础功能），推荐API version 18+（完整设备信息）
- **系统能力**：SystemCapability.Communication.Bluetooth.Core
- **HarmonyOS版本**：HarmonyOS 4.0+
- **设备要求**：支持蓝牙功能的设备

### 常见编译问题

**问题1：导入模块错误**
```
Error: Cannot find module '@kit.ConnectivityKit'
```
**解决方法**：检查oh-package.json5配置，确保已添加`@kit.ConnectivityKit`依赖，运行`ohpm install`安装依赖

**问题2：API不存在错误**
```
Error: connection.on('discoveryResult') is not defined
```
**解决方法**：检查API版本，`discoveryResult`需要API version 18+，使用`bluetoothDeviceFind`作为降级方案

**问题3：权限错误**
```
Error: Permission denied (code: 201)
```
**解决方法**：在module.json5中声明权限：
```json
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.ACCESS_BLUETOOTH"
      }
    ]
  }
}
```

**问题4：类型定义错误**
```
Error: DiscoveryResult type is not defined
```
**解决方法**：确保使用API version 18+，导入connection模块后类型自动可用

## 常见问题与解决方法

### Q1：扫描不到周边蓝牙设备
**原因**：
- 目标设备未处于可被发现状态
- 目标设备蓝牙未开启
- 距离过远或信号干扰
- 本机蓝牙未开启

**解决方法**：
- 检查目标设备是否开启蓝牙并设置为可被发现状态
- 检查本机蓝牙是否已开启
- 确认设备距离在蓝牙有效范围内（通常10米内）
- 检查周围是否有干扰源

### Q2：扫描结果重复上报设备
**原因**：扫描过程持续12秒，同一设备可能被多次扫描到

**解决方法**：
- 在回调函数中使用设备地址作为唯一标识进行去重
- 使用Map或Set存储已发现的设备地址

```typescript
const discoveredDevices = new Map<string, connection.DiscoveryResult>();
function onDiscoveryResult(data: Array<connection.DiscoveryResult>) {
  for (const device of data) {
    if (!discoveredDevices.has(device.deviceId)) {
      discoveredDevices.set(device.deviceId, device);
      console.info('发现新设备: ' + device.deviceId);
    }
  }
}
```

### Q3：无法停止扫描
**原因**：
- 扫描流程已完成自动停止
- 未正确判断扫描状态

**解决方法**：
- 使用`isBluetoothDiscovering()`判断当前扫描状态
- 只有在扫描过程中才调用`stopBluetoothDiscovery()`

### Q4：获取的设备地址会变化
**原因**：基于信息安全考虑，系统返回的是虚拟MAC地址

**解决方法**：
- 已配对设备的虚拟地址不会变更
- 若需要持久化保存设备地址，使用`access.addPersistentDeviceId`方法
- 重启蓝牙开关后，虚拟地址可能变更，需要重新扫描

### Q5：权限申请失败
**原因**：
- 未在module.json5中声明权限
- 用户拒绝授权

**解决方法**：
- 确保在module.json5中正确声明`ohos.permission.ACCESS_BLUETOOTH`权限
- 参考[向用户申请授权](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/request-user-authorization)引导用户授权
- 提供友好的用户提示，说明权限用途

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "operation": "bluetooth_discovery",
  "discoveredDevices": [
    {
      "address": "XX:XX:XX:XX:XX:XX",
      "name": "设备名称",
      "type": "AUDIO_VIDEO",
      "signalStrength": -50
    }
  ],
  "pairedDevices": [
    "YY:YY:YY:YY:YY:YY",
    "ZZ:ZZ:ZZ:ZZ:ZZ:ZZ"
  ],
  "scanDuration": 12000,
  "apiUsed": [
    "connection.startBluetoothDiscovery",
    "connection.on('discoveryResult')",
    "connection.stopBluetoothDiscovery",
    "connection.getPairedDevices"
  ],
  "apiVersion": "18+",
  "permission": "ohos.permission.ACCESS_BLUETOOTH"
}
```

## 参考文档

- [开发指南 - 查找设备](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/br-discovery-development-guide)
- [API参考 - 蓝牙connection模块](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-bluetooth-connection)
- [权限申请 - 声明权限](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/declare-permissions)
- [权限申请 - 向用户申请授权](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/request-user-authorization)
- [配对与连接设备](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/br-pair-device-development-guide)
- [连接和传输数据](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/spp-development-guide)

## 完整示例代码

- [ArkTS示例 - 蓝牙设备查找完整实现](assets/discovery_device_manager.ets)
- [配置示例 - 权限配置](assets/module.json5)

## 测试用例

### 正向测试用例
- [测试正常扫描流程](tests/test_normal_discovery.ets)：测试完整的扫描流程，包括订阅、扫描、停止、取消订阅
- [测试查询已配对设备](tests/test_get_paired_devices.ets)：测试获取已配对设备列表和配对状态

### 边界测试用例
- [测试扫描状态判断](tests/test_discovery_state.ets)：测试isBluetoothDiscovering状态判断
- [测试重复扫描处理](tests/test_duplicate_discovery.ets)：测试扫描过程中重复调用startBluetoothDiscovery的处理

### 异常测试用例
- [测试权限不足](tests/test_permission_denied.ets)：测试未申请权限时的错误处理
- [测试蓝牙未开启](tests/test_bluetooth_disabled.ets)：测试蓝牙未开启时的错误处理
- [测试目标设备不可见](tests/test_device_not_discoverable.ets)：测试目标设备不可被发现时的处理