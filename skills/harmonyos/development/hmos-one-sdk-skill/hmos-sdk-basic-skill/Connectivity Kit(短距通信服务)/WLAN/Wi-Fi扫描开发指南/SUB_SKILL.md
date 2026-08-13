---
name: hmos-connectivity-kit-wifi-scan
description: 扫描周围可用Wi-Fi网络并获取扫描结果，支持获取SSID、BSSID、信号强度、加密方式等信息，需要GET_WIFI_INFO权限和WiFi使能状态，适用于WiFi连接、网络分析场景
---

# Wi-Fi扫描技能

## 功能描述

Wi-Fi扫描是指设备搜索周围可用Wi-Fi网络的过程。通过扫描，设备可以获取附近网络的基本信息（如网络名称、信号强度、加密方式等），从而实现连接、管理或分析周围网络。本技能提供完整的Wi-Fi扫描功能实现，包括扫描状态监听、扫描结果获取、结果解析等功能。

本技能支持以下功能：
- 检查WiFi是否已启用
- 注册和取消扫描状态监听
- 启动WiFi扫描
- 获取扫描结果列表
- 解析扫描结果（SSID、BSSID、RSSI、加密类型等）

## 使用场景

### 触发词
- "WiFi扫描"
- "扫描WiFi"
- "获取WiFi列表"
- "搜索附近WiFi"
- "WiFi信号扫描"
- "查看可用WiFi"
- "WiFi网络扫描"

### 能做
- 扫描周围可用的WiFi网络
- 获取WiFi网络详细信息（SSID、BSSID、信号强度、频段、加密方式等）
- 监听WiFi扫描状态变化（扫描成功/失败）
- 判断WiFi功能是否已启用
- 获取WiFi支持的类别（WiFi 6/6+/7等）
- 判断是否为HiLink网络

### 绝不做
- 不执行WiFi连接操作（需要使用WiFi连接技能）
- 不修改WiFi配置信息
- 不执行WiFi热点功能
- 不处理WiFi P2P相关操作
- 不执行主动扫描接口scan()（已废弃，使用startScan()）

### 补充
- API version 10开始，主动扫描接口scan()已废弃，推荐使用startScan()
- 扫描接口在前台应用中2分钟内最多发起4次，后台应用30分钟内最多1次
- 扫描结果获取真实bssid需要申请ohos.permission.GET_WIFI_PEERS_MAC权限
- 扫描管控：WiFi关闭时不触发扫描，WiFi连接过程中不允许扫描

## 调用规范和规则

### 输入约束
- 无需输入参数
- 调用前必须确保WiFi功能已启用
- 需要申请ohos.permission.GET_WIFI_INFO权限
- 如需获取真实bssid，需申请ohos.permission.GET_WIFI_PEERS_MAC权限

### 执行约束
- 扫描频次限制：
  - 前台应用：2分钟内最多4次
  - 后台应用：30分钟内最多1次
- 扫描结果缓存时间：当前时间点前30秒内
- 扫描状态回调：0表示扫描失败，1表示扫描成功
- 必须在WiFi已启用状态下执行扫描

### 内容约束
- 禁止使用已废弃的scan()接口
- 禁止在WiFi连接过程中触发扫描
- 禁止忽略扫描状态回调结果
- 必须处理WiFi未启用的情况

### 降级约束
- WiFi未启用：提示用户手动开启WiFi并退出
- 扫描失败：记录错误日志并返回空列表
- 权限不足：提示用户授予相应权限
- 扫描频次超限：等待扫描限制时间后重试或使用缓存结果

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 检查是否已申请ohos.permission.GET_WIFI_INFO权限
2. 检查WiFi功能是否已启用
3. 检查设备是否支持SystemCapability.Communication.WiFi.STA系统能力

**权限配置**：
```json
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.GET_WIFI_INFO"
      },
      {
        "name": "ohos.permission.SET_WIFI_INFO"
      },
      {
        "name": "ohos.permission.GET_WIFI_PEERS_MAC"
      }
    ]
  }
}
```

### 步骤2：检查WiFi状态并注册扫描监听

**示例代码**：
```typescript
import { wifiManager } from '@kit.ConnectivityKit';

// 检查WiFi是否已启用
function checkWifiEnabled(): boolean {
  try {
    const isWifiActive = wifiManager.isWifiActive();
    if (!isWifiActive) {
      console.error('WiFi is not enabled');
      return false;
    }
    console.info('WiFi is enabled');
    return true;
  } catch (error) {
    console.error(`Check WiFi status failed: ${error.message}`);
    return false;
  }
}

// 注册扫描状态监听
let scanStateChangeCallback = (result: number) => {
  if (result === 1) {
    console.info('WiFi scan completed successfully');
  } else {
    console.error('WiFi scan failed');
  }
};

function registerScanListener(): void {
  try {
    wifiManager.on('wifiScanStateChange', scanStateChangeCallback);
    console.info('Scan state listener registered');
  } catch (error) {
    console.error(`Register scan listener failed: ${error.message}`);
  }
}

// 取消注册扫描状态监听
function unregisterScanListener(): void {
  try {
    wifiManager.off('wifiScanStateChange', scanStateChangeCallback);
    console.info('Scan state listener unregistered');
  } catch (error) {
    console.error(`Unregister scan listener failed: ${error.message}`);
  }
}
```

### 步骤3：启动WiFi扫描

**示例代码**：
```typescript
import { wifiManager } from '@kit.ConnectivityKit';

// 启动WiFi扫描
function startWifiScan(): boolean {
  try {
    wifiManager.startScan();
    console.info('WiFi scan started successfully');
    return true;
  } catch (error) {
    console.error(`Start WiFi scan failed: ${error.message}`);
    return false;
  }
}
```

### 步骤4：获取扫描结果

**示例代码**：
```typescript
import { wifiManager } from '@kit.ConnectivityKit';

interface WifiScanResult {
  ssid: string;
  bssid: string;
  rssi: number;
  band: number;
  frequency: number;
  channelWidth: number;
  securityType: number;
  capabilities: string;
  timestamp: number;
  supportedWifiCategory?: number;
  isHiLinkNetwork?: boolean;
}

// 获取扫描结果列表
function getWifiScanResults(): WifiScanResult[] {
  try {
    const scanInfoList = wifiManager.getScanInfoList();
    console.info(`Found ${scanInfoList.length} WiFi networks`);
    
    const results: WifiScanResult[] = [];
    for (let i = 0; i < scanInfoList.length; i++) {
      const info = scanInfoList[i];
      results.push({
        ssid: info.ssid,
        bssid: info.bssid,
        rssi: info.rssi,
        band: info.band,
        frequency: info.frequency,
        channelWidth: info.channelWidth,
        securityType: info.securityType,
        capabilities: info.capabilities,
        timestamp: info.timestamp,
        supportedWifiCategory: info.supportedWifiCategory,
        isHiLinkNetwork: info.isHiLinkNetwork
      });
      
      console.info(`Network ${i + 1}:`);
      console.info(`  SSID: ${info.ssid}`);
      console.info(`  BSSID: ${info.bssid}`);
      console.info(`  RSSI: ${info.rssi} dBm`);
      console.info(`  Band: ${info.band === 1 ? '2.4GHz' : '5GHz'}`);
      console.info(`  Frequency: ${info.frequency} MHz`);
      console.info(`  Channel Width: ${info.channelWidth}`);
      console.info(`  Security Type: ${info.securityType}`);
      console.info(`  WiFi Category: ${info.supportedWifiCategory}`);
      console.info(`  HiLink: ${info.isHiLinkNetwork}`);
    }
    
    return results;
  } catch (error) {
    console.error(`Get scan results failed: ${error.message}`);
    return [];
  }
}
```

### 步骤5：完整流程示例

**示例代码**：
```typescript
import { wifiManager } from '@kit.ConnectivityKit';

// 完整WiFi扫描流程
async function performWifiScan(): Promise<void> {
  try {
    // 1. 检查WiFi是否已启用
    const isWifiActive = wifiManager.isWifiActive();
    if (!isWifiActive) {
      console.error('WiFi is not enabled, please enable WiFi first');
      return;
    }
    
    // 2. 注册扫描状态监听
    let scanCompleted = false;
    const scanCallback = (result: number) => {
      scanCompleted = true;
      if (result === 1) {
        console.info('Scan completed successfully');
      } else {
        console.error('Scan failed');
      }
    };
    
    wifiManager.on('wifiScanStateChange', scanCallback);
    
    // 3. 启动扫描
    console.info('Starting WiFi scan...');
    wifiManager.startScan();
    
    // 4. 等待扫描完成（实际应用中可以使用Promise或回调）
    await new Promise(resolve => setTimeout(resolve, 3000));
    
    // 5. 获取扫描结果
    if (scanCompleted) {
      const scanResults = wifiManager.getScanInfoList();
      console.info(`Found ${scanResults.length} WiFi networks`);
      
      // 处理扫描结果
      for (const network of scanResults) {
        console.info(`SSID: ${network.ssid}, Signal: ${network.rssi} dBm`);
      }
    }
    
    // 6. 取消注册监听
    wifiManager.off('wifiScanStateChange', scanCallback);
    
  } catch (error) {
    console.error(`WiFi scan error: ${error.message}`);
  }
}
```

### 步骤6：错误处理

```typescript
import { wifiManager } from '@kit.ConnectivityKit';

// 错误处理示例
function handleWifiScanError(error: any): void {
  const errorCode = error.code;
  
  switch (errorCode) {
    case 201:
      console.error('Permission denied. Please grant GET_WIFI_INFO permission');
      break;
    case 801:
      console.error('Capability not supported. Device does not support WiFi');
      break;
    case 2501000:
      console.error('Operation failed. WiFi service internal error');
      break;
    case 2501001:
      console.error('WiFi STA disabled. Please enable WiFi');
      break;
    default:
      console.error(`Unknown error: ${error.message}`);
  }
}

// 带错误处理的扫描函数
function safeWifiScan(): void {
  try {
    if (!wifiManager.isWifiActive()) {
      console.error('WiFi is not enabled');
      return;
    }
    
    wifiManager.startScan();
    console.info('Scan started');
  } catch (error) {
    handleWifiScanError(error);
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 201 | 权限被拒绝 | 在module.json5中申请ohos.permission.GET_WIFI_INFO和ohos.permission.SET_WIFI_INFO权限 |
| 801 | 能力不支持 | 设备不支持WiFi功能，无法使用此功能 |
| 2501000 | 操作失败 | WiFi服务内部异常，尝试重新打开WiFi或重启设备 |
| 2501001 | WiFi STA未启用 | 先调用enableWifi()或手动打开WiFi开关 |
| 2501003 | 服务正在关闭 | 等待服务完全关闭后重新尝试 |
| 2501004 | 服务正在打开 | 等待服务完全打开后重新尝试 |

## 编译和修复问题

### 依赖声明
```json
{
  "name": "wifiscan",
  "version": "1.0.0",
  "description": "WiFi scan demo",
  "main": "",
  "author": "",
  "license": "ISC",
  "dependencies": {}
}
```

### module.json5配置
```json
{
  "module": {
    "name": "entry",
    "type": "entry",
    "deviceTypes": [
      "default",
      "tablet"
    ],
    "abilities": [
      {
        "name": "EntryAbility",
        "srcEntry": "./ets/entryability/EntryAbility.ts",
        "description": "$string:EntryAbility_desc",
        "icon": "$media:icon",
        "label": "$string:EntryAbility_label",
        "startWindowIcon": "$media:startIcon",
        "startWindowBackground": "$color:start_window_background"
      }
    ],
    "requestPermissions": [
      {
        "name": "ohos.permission.GET_WIFI_INFO"
      },
      {
        "name": "ohos.permission.SET_WIFI_INFO"
      },
      {
        "name": "ohos.permission.GET_WIFI_PEERS_MAC"
      }
    ]
  }
}
```

### 环境要求
- HarmonyOS SDK: API version 9及以上
- Device Types: default, tablet
- 系统能力: SystemCapability.Communication.WiFi.STA

### 常见编译问题

**问题1：导入模块失败**
```
Error: Cannot find module '@kit.ConnectivityKit' or its corresponding type declarations.
```
**解决方法**：
- 确保HarmonyOS SDK版本为API 9及以上
- 检查build-profile.json5中的compileSdkVersion是否正确
- 确保项目依赖配置正确

**问题2：权限未声明**
```
Error: Permission denied. Need permission: ohos.permission.GET_WIFI_INFO
```
**解决方法**：
- 在module.json5的requestPermissions中添加相应权限
- 重新编译并安装应用

**问题3：API不存在**
```
Error: Property 'startScan' does not exist on type 'typeof wifiManager'.
```
**解决方法**：
- 检查API version，startScan从API 21开始支持
- 使用对应的API版本接口

## 常见问题与解决方法

### Q1：扫描结果为空
**原因**：
- WiFi未启用
- 扫描未完成就获取结果
- 权限未授予
- 设备不支持WiFi

**解决方法**：
- 先调用isWifiActive()检查WiFi状态
- 等待扫描完成后再获取结果
- 检查并申请必要权限
- 检查设备是否支持WiFi功能

### Q2：扫描频率受限
**原因**：
- 前台应用2分钟内最多扫描4次
- 后台应用30分钟内最多扫描1次

**解决方法**：
- 合理控制扫描频率
- 使用缓存结果减少扫描次数
- 避免在后台频繁扫描

### Q3：无法获取真实BSSID
**原因**：
- 未申请ohos.permission.GET_WIFI_PEERS_MAC权限
- 未授予该权限

**解决方法**：
- 在module.json5中添加ohos.permission.GET_WIFI_PEERS_MAC权限
- 引导用户授予该权限
- 不申请该权限时，BSSID为随机设备地址

### Q4：扫描失败
**原因**：
- WiFi正在连接中
- WiFi正在关闭/打开
- WiFi服务内部异常

**解决方法**：
- 避免在WiFi连接过程中扫描
- 等待WiFi状态稳定后再扫描
- 重启WiFi或重启设备

### Q5：startScan()接口不存在
**原因**：
- API version低于21

**解决方法**：
- 升级HarmonyOS SDK至API 21及以上
- 或使用已废弃的scan()接口（不推荐）

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "scanTime": "2026-07-03T10:30:00Z",
  "networkCount": 15,
  "networks": [
    {
      "ssid": "Network1",
      "bssid": "00:11:22:33:44:55",
      "rssi": -45,
      "band": 1,
      "frequency": 2412,
      "securityType": 3
    }
  ],
  "apiUsed": [
    "wifiManager.isWifiActive()",
    "wifiManager.on('wifiScanStateChange')",
    "wifiManager.startScan()",
    "wifiManager.getScanInfoList()",
    "wifiManager.off('wifiScanStateChange')"
  ]
}
```

## 参考文档

- [Wi-Fi扫描开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/scan-development-guide)
- [WLAN API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-wifimanager)
- [WIFI错误码](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/errorcode-wifi)

## 完整示例代码

- [ArkTS完整示例](assets/wifi_scan_example.ets)
- [配置文件示例](assets/module.json5)

## 测试用例

### 正向测试用例
- [WiFi扫描成功测试](tests/test_positive.ets)：测试正常WiFi扫描流程
- [获取扫描结果测试](tests/test_positive.ets)：测试获取扫描结果列表

### 边界测试用例
- [WiFi未启用测试](tests/test_boundary.ets)：测试WiFi未启用时的处理
- [空扫描结果测试](tests/test_boundary.ets)：测试无可用网络时的处理

### 异常测试用例
- [权限不足测试](tests/test_exception.ets)：测试权限未授予时的错误处理
- [扫描失败测试](tests/test_exception.ets)：测试扫描失败时的错误处理