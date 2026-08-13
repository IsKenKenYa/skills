---
name: hmos-connectivity-kit-p2p-mode
description: 实现WLAN P2P设备点对点连接，支持创建/删除群组、发现设备、建立连接、获取连接信息，最大支持2个设备直连，适用于设备互联、数据传输场景
---

# P2P模式开发技能

## 功能描述

本技能提供HarmonyOS WLAN P2P（Peer-to-Peer）点对点连接开发能力，允许两台STA设备之间直接建立TCP/IP连接，无需AP参与。支持创建临时或永久群组、发现周边P2P设备、建立P2P连接、获取连接信息和群组信息，适用于设备间直连通信、数据传输、文件共享等场景。

## 使用场景

### 触发词
- "P2P连接"
- "创建P2P群组"
- "删除P2P群组"
- "发现P2P设备"
- "建立P2P连接"
- "获取P2P连接信息"
- "WLAN点对点连接"
- "设备直连"

### 能做
- 创建临时P2P群组（netId: -1）
- 创建永久P2P群组（netId: -2）
- 删除已创建的P2P群组
- 启动P2P设备发现扫描
- 获取扫描到的对端设备列表
- 建立P2P设备连接
- 获取P2P连接状态和连接信息
- 获取群组信息和群组IP地址
- 注册/取消注册P2P事件回调

### 绝不做
- 不处理超出P2P范围的WLAN基础功能（如普通WiFi连接）
- 不替代Socket通信的具体实现
- 不处理超出2个设备的群组场景
- 不执行网络层以上的协议处理

### 补充
- 作为GO（Group Owner）时不能主动发起连接
- P2P连接前必须确保WiFi已开启
- 需要申请ohos.permission.GET_WIFI_INFO权限
- 永久组下次连接无需重新GO和WPS密钥协商
- 临时组每次连接需要重新GO和WPS密钥协商

## 调用规范和规则

### 输入约束
- 设备地址格式：符合MAC地址格式（如"00:11:22:33:44:55"）
- 网络ID取值：-1（临时组）或-2（永久组）
- 群组名称长度：最大32字节，UTF-8编码
- 群组密钥长度：8-64字节
- 群组带宽：GO_BAND_AUTO(0)、GO_BAND_2GHZ(1)、GO_BAND_5GHZ(2)

### 执行约束
- P2P设备发现最长耗时：120秒
- P2P连接建立最长耗时：30秒
- 事件回调注册后必须及时取消注册
- WiFi必须保持开启状态
- 最大迭代次数：发现设备阶段最多扫描10次

### 内容约束
- 禁止使用未授权的MAC地址
- 禁止创建超过2个设备的群组
- 禁止在未开启WiFi时执行P2P操作
- 禁止作为GO主动发起连接

### 降级约束
- WiFi未开启：提示用户开启WiFi并终止操作
- 设备发现失败：提示未发现设备并建议重新扫描
- 连接建立失败：检查权限配置并提示重新连接
- 权限不足：提示申请必要权限并终止操作

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 检查WiFi是否已开启：`wifiManager.isWifiActive()`
2. 检查系统是否支持P2P能力：`SystemCapability.Communication.WiFi.P2P`
3. 础认已申请必要权限：`ohos.permission.GET_WIFI_INFO`

**参数准备**：
```typescript
import { wifiManager } from '@kit.ConnectivityKit';

const p2pConfig: wifiManager.WifiP2PConfig = {
  deviceAddress: "00:11:22:33:44:55",
  deviceAddressType: 1,
  netId: -2,
  passphrase: "12345678",
  groupName: "testGroup",
  goBand: 0
};
```

### 步骤2：创建P2P群组

**创建永久群组示例代码**：
```typescript
import { wifiManager } from '@kit.ConnectivityKit';

async function createP2PGroup(): Promise<void> {
  try {
    if (!wifiManager.isWifiActive()) {
      console.error("WiFi is not active, please enable WiFi first");
      return;
    }
    
    const recvP2pPersistentGroupChangeFunc = () => {
      console.info("p2p persistent group change receive event");
      wifiManager.getCurrentGroup((err, data) => {
        if (err) {
          console.error("failed to get current group: " + JSON.stringify(err));
          return;
        }
        console.info("get current group: " + JSON.stringify(data));
      });
    };
    
    wifiManager.on("p2pPersistentGroupChange", recvP2pPersistentGroupChangeFunc);
    
    const config: wifiManager.WifiP2PConfig = {
      deviceAddress: "00:11:22:33:44:55",
      deviceAddressType: 1,
      netId: -2,
      passphrase: "12345678",
      groupName: "testGroup",
      goBand: 0
    };
    
    wifiManager.createGroup(config);
    console.info("P2P group created successfully");
    
    setTimeout(() => {
      wifiManager.off("p2pPersistentGroupChange", recvP2pPersistentGroupChangeFunc);
    }, 125 * 1000);
    
  } catch (error) {
    console.error("createGroup failed: " + JSON.stringify(error));
  }
}
```

### 步骤3：发现P2P设备

**设备发现示例代码**：
```typescript
import { wifiManager } from '@kit.ConnectivityKit';

async function discoverP2PDevices(): Promise<void> {
  try {
    if (!wifiManager.isWifiActive()) {
      console.error("WiFi is not active, please enable WiFi first");
      return;
    }
    
    const recvP2pPeerDeviceChangeFunc = (result: wifiManager.WifiP2pDevice[]) => {
      console.info("p2p peer device change receive event: " + JSON.stringify(result));
      
      wifiManager.getP2pPeerDevices((err, data) => {
        if (err) {
          console.error("failed to get peer devices: " + JSON.stringify(err));
          return;
        }
        
        console.info("get peer devices: " + JSON.stringify(data));
        const len = data.length;
        
        for (let i = 0; i < len; ++i) {
          if (data[i].deviceName === "my_test_device") {
            console.info("found target device: " + data[i].deviceAddress);
          }
        }
      });
    };
    
    wifiManager.on("p2pPeerDeviceChange", recvP2pPeerDeviceChangeFunc);
    
    wifiManager.startDiscoverDevices();
    console.info("P2P device discovery started");
    
    setTimeout(() => {
      wifiManager.off("p2pPeerDeviceChange", recvP2pPeerDeviceChangeFunc);
    }, 125 * 1000);
    
  } catch (error) {
    console.error("discover devices failed: " + JSON.stringify(error));
  }
}
```

### 步骤4：建立P2P连接

**连接示例代码**：
```typescript
import { wifiManager } from '@kit.ConnectivityKit';

async function connectP2PDevice(deviceAddress: string): Promise<void> {
  try {
    if (!wifiManager.isWifiActive()) {
      console.error("WiFi is not active, please enable WiFi first");
      return;
    }
    
    const recvP2pConnectionChangeFunc = (result: wifiManager.WifiP2pLinkedInfo) => {
      console.info("p2p connection change receive event: " + JSON.stringify(result));
      
      wifiManager.getP2pLinkedInfo((err, data) => {
        if (err) {
          console.error("failed to get P2pLinkedInfo: " + JSON.stringify(err));
          return;
        }
        
        console.info("get P2pLinkedInfo: " + JSON.stringify(data));
        
        if (data.connectState === wifiManager.P2pConnectState.CONNECTED) {
          console.info("P2P connection established successfully");
        }
      });
    };
    
    wifiManager.on("p2pConnectionChange", recvP2pConnectionChangeFunc);
    
    const config: wifiManager.WifiP2PConfig = {
      deviceAddress: deviceAddress,
      deviceAddressType: 1,
      netId: -2,
      passphrase: "",
      groupName: "",
      goBand: 0
    };
    
    wifiManager.p2pConnect(config);
    console.info("P2P connect request sent");
    
    setTimeout(() => {
      wifiManager.off("p2pConnectionChange", recvP2pConnectionChangeFunc);
    }, 125 * 1000);
    
  } catch (error) {
    console.error("p2pConnect failed: " + JSON.stringify(error));
  }
}
```

### 步骤5：获取群组信息和IP地址

**获取群组信息示例代码**：
```typescript
import { wifiManager } from '@kit.ConnectivityKit';

async function getP2PGroupInfo(): Promise<void> {
  try {
    wifiManager.getCurrentGroup((err, data) => {
      if (err) {
        console.error("failed to get current group: " + JSON.stringify(err));
        return;
      }
      
      console.info("current group info: " + JSON.stringify(data));
      
      if (data.goIpAddress) {
        console.info("Group Owner IP Address: " + data.goIpAddress);
      }
      
      if (data.isP2pGo) {
        console.info("Current device is Group Owner");
      } else {
        console.info("Current device is Group Client");
      }
    });
  } catch (error) {
    console.error("getCurrentGroup failed: " + JSON.stringify(error));
  }
}
```

### 步骤6：删除P2P群组

**删除群组示例代码**：
```typescript
import { wifiManager } from '@kit.ConnectivityKit';

async function removeP2PGroup(): Promise<void> {
  try {
    wifiManager.removeGroup();
    console.info("P2P group removed successfully");
  } catch (error) {
    console.error("removeGroup failed: " + JSON.stringify(error));
  }
}
```

### 步骤7：错误处理

**错误处理代码**：
```typescript
import { wifiManager } from '@kit.ConnectivityKit';

async function handleP2PError(error: any): Promise<void> {
  switch (error.code) {
    case 201:
      console.error("Permission denied. Please request ohos.permission.GET_WIFI_INFO");
      break;
    case 401:
      console.error("Invalid parameters. Please check deviceAddress, netId, passphrase format");
      break;
    case 801:
      console.error("Capability not supported. System does not support P2P");
      break;
    case 2801000:
      console.error("Operation failed. Please retry the operation");
      break;
    case 2801001:
      console.error("Wi-Fi STA disabled. Please enable WiFi first");
      break;
    default:
      console.error("Unknown error: " + JSON.stringify(error));
  }
}
```

### 步骤8：降级处理

**降级处理代码**：
```typescript
import { wifiManager } from '@kit.ConnectivityKit';

async function fallbackP2PConnection(): Promise<void> {
  try {
    const linkedInfo = await wifiManager.getP2pLinkedInfo();
    
    if (linkedInfo.connectState === wifiManager.P2pConnectState.DISCONNECTED) {
      console.warn("P2P connection failed, falling back to WiFi connection");
    }
  } catch (error) {
    console.warn("P2P operation failed, please check WiFi status and permissions");
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 201 | Permission denied | 申请ohos.permission.GET_WIFI_INFO权限 |
| 401 | Invalid parameters | 检查deviceAddress格式、netId取值、passphrase长度 |
| 801 | Capability not supported | 系统不支持P2P能力，使用其他连接方式 |
| 2801000 | Operation failed | 重试操作或检查网络状态 |
| 2801001 | Wi-Fi STA disabled | 开启WiFi后再执行P2P操作 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.ConnectivityKit": "^1.0.0"
  }
}
```

### 环境要求
- HarmonyOS API Version: 9+
- SystemCapability: SystemCapability.Communication.WiFi.P2P
- 权限配置：ohos.permission.GET_WIFI_INFO

### 常见编译问题

**问题1：导入模块错误**
```
Cannot find module '@kit.ConnectivityKit'
```
**解决方法**：确保已安装HarmonyOS SDK，在module.json5中配置依赖

**问题2：权限配置缺失**
```
Permission denied error
```
**解决方法**：在module.json5的requestPermissions中添加ohos.permission.GET_WIFI_INFO

**问题3：WiFi未开启**
```
Wi-Fi STA disabled error
```
**解决方法**：调用wifiManager.enableWifi()开启WiFi后再执行P2P操作

## 常见问题与解决方法

### Q1：创建群组失败
**原因**：WiFi未开启、权限不足、参数格式错误
**解决方法**：
- 调用isWifiActive()检查WiFi状态
- 申请ohos.permission.GET_WIFI_INFO权限
- 检查deviceAddress、passphrase格式是否正确

### Q2：无法发现周边设备
**原因**：P2P扫描未启动、周边无P2P设备、WiFi未开启
**解决方法**：
- 调用startDiscoverDevices()启动扫描
- 确保WiFi已开启
- 确认周边存在支持P2P的设备

### Q3：P2P连接建立失败
**原因**：作为GO主动发起连接、目标设备未响应、权限不足
**解决方法**：
- 作为GO不能主动发起连接，需等待对端连接
- 检查目标设备是否已启动P2P
- 确认已申请必要权限

### Q4：无法获取群组IP地址
**原因**：群组未成功创建、权限不足（需GET_WIFI_LOCAL_MAC）
**解决方法**：
- 检查群组创建是否成功
- 申请ohos.permission.GET_WIFI_LOCAL_MAC权限（仅系统应用）

### Q5：永久组下次连接失败
**原因**：netId设置错误、群组信息未保存
**解决方法**：
- 创建永久组时使用netId: -2
- 检查群组信息是否已保存到系统

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "operation": "P2P连接操作",
  "deviceAddress": "00:11:22:33:44:55",
  "groupName": "testGroup",
  "groupOwnerIp": "192.168.1.1",
  "connectState": "CONNECTED",
  "isGroupOwner": true,
  "apiUsed": [
    "wifiManager.isWifiActive()",
    "wifiManager.createGroup()",
    "wifiManager.startDiscoverDevices()",
    "wifiManager.getP2pPeerDevices()",
    "wifiManager.p2pConnect()",
    "wifiManager.getP2pLinkedInfo()",
    "wifiManager.getCurrentGroup()",
    "wifiManager.removeGroup()",
    "wifiManager.on('p2pConnectionChange')",
    "wifiManager.off('p2pConnectionChange')"
  ]
}
```

## 参考文档

- [P2P模式开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/p2p-development-guide)
- [P2P接口参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-wifimanager)
- [WIFI错误码](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/errorcode-wifi)
- [使用Socket访问网络](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/socket-connection)

## 完整示例代码

- [ArkTS示例 - 创建永久群组](assets/create_permanent_group.ets)
- [ArkTS示例 - 发现并连接设备](assets/discover_and_connect.ets)
- [ArkTS示例 - 获取群组信息](assets/get_group_info.ets)
- [ArkTS示例 - 删除群组](assets/remove_group.ets)
- [配置文件示例](assets/module.json5)

## 测试用例

### 正向测试用例
- [创建临时P2P群组](tests/test_create_temporary_group.ets)：验证临时群组创建成功
- [创建永久P2P群组](tests/test_create_permanent_group.ets)：验证永久群组创建成功
- [发现P2P设备](tests/test_discover_devices.ets)：验证设备发现功能正常
- [建立P2P连接](tests/test_p2p_connect.ets)：验证连接建立成功
- [获取P2P连接信息](tests/test_get_linked_info.ets)：验证连接信息获取正确
- [获取群组信息](tests/test_get_group_info.ets)：验证群组信息获取正确

### 边界测试用例
- [群组名称超长测试](tests/test_group_name_max_length.ets)：验证群组名称32字节限制
- [密钥长度边界测试](tests/test_passphrase_length.ets)：验证密钥8-64字节范围
- [设备地址格式测试](tests/test_device_address_format.ets)：验证MAC地址格式校验

### 异常测试用例
- [WiFi未开启测试](tests/test_wifi_disabled.ets)：验证WiFi未开启时的错误处理
- [权限不足测试](tests/test_permission_denied.ets)：验证权限不足时的错误处理
- [参数格式错误测试](tests/test_invalid_parameters.ets)：验证参数格式错误时的处理
- [设备不存在测试](tests/test_device_not_found.ets)：验证目标设备不存在时的处理
- [连接超时测试](tests/test_connection_timeout.ets)：验证连接超时时的降级处理