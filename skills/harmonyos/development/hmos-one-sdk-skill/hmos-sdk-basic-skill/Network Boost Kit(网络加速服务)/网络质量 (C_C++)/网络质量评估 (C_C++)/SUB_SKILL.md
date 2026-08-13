---
name: hmos-network-boost-kit-network-quality-qos-callback
description: 注册网络质量QoS回调监听网络质量变化，获取实时网络质量评估信息包括链路类型上下行带宽速率RTT时延等，支持C/C++开发，适用于实时音视频游戏直播等需网络自适应场景
---

# 网络质量评估 (C/C++)

## 功能描述

本技能实现Network Boost Kit的网络质量评估功能，通过注册回调监听网络质量变化。系统按周期或QoS变化时回调网络质量信息，包括：
- 数据传输链路类型（蜂窝主卡/副卡、Wi-Fi主/辅）
- 上下行空口实时带宽（bps）
- 上下行空口实时速率（bps）
- RTT时延（ms）
- 上行发送空口缓冲时延（ms）

应用可基于这些信息实现网络自适应策略调整（缓存、码率、帧率、分辨率等）。

**起始版本**：5.1.0(18)

## 使用场景

### 触发词
- "注册网络质量回调"
- "监听网络质量"
- "获取网络质量信息"
- "网络质量评估"
- "QoS回调"
- "网络自适应"

### 能做
- 注册网络质量变化回调函数
- 实时获取网络质量评估信息
- 处理回调中的网络质量数据
- 取消注册网络质量回调
- 支持多条路径网络质量信息处理（最多4条）

### 绝不做
- 不处理连接迁移功能（使用连接迁移技能）
- 不实现多网并发功能（使用多网并发技能）
- 不直接发起网络加速（使用网络加速技能）
- 不支持ArkTS语言开发（仅支持C/C++）

### 补充
- 需要权限：ohos.permission.GET_NETWORK_INFO
- 依赖库：libnetwork_boost.so
- 系统能力：SystemCapability.Communication.NetworkBoost.Core
- 最大回调注册数量受限，建议及时取消注册

## 调用规范和规则

### 输入约束
- 回调函数必须不为空指针
- callbackId指针必须有效且可写入
- 回调函数类型必须匹配HMS_NetworkBoost_NetQosChange签名

### 执行约束
- 注册回调耗时：≤100ms
- 回调触发周期：系统按周期或QoS变化触发
- 最大注册数量：系统限制（具体上限见错误码62100003）
- 取消注册必须在注册成功后执行

### 内容约束
- 禁止在回调中执行阻塞操作
- 禁止在回调中再次注册/取消注册回调
- 回调数据单位：
  - 带宽/速率：bps（若需转换为B/s需除以8）
  - 时延：ms
- pathNum范围：[1, 4]

### 降级约束
- 权限不足：提示用户申请权限并退出
- 注册失败：记录错误码并提示用户
- 回调数据异常：使用默认值或上次有效数据
- 系统服务异常：提示系统服务不可用

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 确认已申请ohos.permission.GET_NETWORK_INFO权限
2. 确认系统能力支持SystemCapability.Communication.NetworkBoost.Core
3. 确认HarmonyOS版本≥5.1.0(18)

**参数准备**：
```cpp
#include "NetworkBoostKit/network_boost_quality.h"
#include <cstdio>

uint32_t callbackId = 0;
```

### 步骤2：实现回调函数

**示例代码**：
```cpp
void onNetworkQoSChanged(NetworkBoost_NetworkQosArray *msg)
{
    if (msg == nullptr) {
        printf("回调数据为空\n");
        return;
    }
    
    for (uint32_t i = 0; i < msg->pathNum && i < NETBOOST_MAX_PATH_NUM; i++) {
        NetworkBoost_NetworkQos *qos = &msg->networkQos[i];
        
        printf("路径%d网络质量信息:\n", i);
        printf("  数据链路类型: %d\n", qos->pathType);
        printf("  上行带宽: %llu bps\n", qos->linkUpBandwidth);
        printf("  下行带宽: %llu bps\n", qos->linkDownBandwidth);
        printf("  上行速率: %llu bps (%llu B/s)\n", 
               qos->linkUpRate, qos->linkUpRate / 8);
        printf("  下行速率: %llu bps (%llu B/s)\n", 
               qos->linkDownRate, qos->linkDownRate / 8);
        printf("  实时速率: %llu B/s\n", 
               (qos->linkUpRate + qos->linkDownRate) / 8);
        printf("  RTT时延: %u ms\n", qos->rttMs);
        printf("  上行空口缓冲时延: %u ms\n", qos->linkUpBufferDelayMs);
    }
}
```

### 步骤3：注册回调

**示例代码**：
```cpp
int32_t RegisterNetQualityCallback()
{
    HMS_NetworkBoost_NetQosChange callback = onNetworkQoSChanged;
    
    int32_t ret = HMS_NetworkBoost_RegisterNetQosCallback(callback, &callbackId);
    
    if (ret == 0) {
        printf("注册成功，回调ID: %u\n", callbackId);
    } else {
        printf("注册失败，错误码: %d\n", ret);
    }
    
    return ret;
}
```

### 步骤4：错误处理

```cpp
void HandleRegisterError(int32_t errorCode)
{
    switch (errorCode) {
        case 0:
            printf("成功\n");
            break;
        case 201:
            printf("权限不足，请申请ohos.permission.GET_NETWORK_INFO权限\n");
            break;
        case 401:
            printf("参数错误，请检查回调函数和callbackId指针\n");
            break;
        case 801:
            printf("系统能力不支持\n");
            break;
        case 62100001:
            printf("内部错误\n");
            break;
        case 62100002:
            printf("系统服务操作失败\n");
            break;
        case 62100003:
            printf("注册请求达到上限\n");
            break;
        default:
            printf("未知错误: %d\n", errorCode);
    }
}
```

### 步骤5：取消注册回调

**示例代码**：
```cpp
int32_t UnregisterNetQualityCallback()
{
    if (callbackId == 0) {
        printf("未注册回调，无需取消\n");
        return -1;
    }
    
    int32_t ret = HMS_NetworkBoost_UnregisterNetQosCallback(callbackId);
    
    if (ret == 0) {
        printf("取消注册成功\n");
        callbackId = 0;
    } else {
        printf("取消注册失败，错误码: %d\n", ret);
    }
    
    return ret;
}
```

### 步骤6：降级处理

```cpp
int32_t RegisterWithFallback()
{
    int32_t ret = RegisterNetQualityCallback();
    
    if (ret == 201) {
        printf("降级方案：提示用户申请权限，功能暂不可用\n");
        return ret;
    } else if (ret == 801) {
        printf("降级方案：系统不支持，使用其他网络监测方案\n");
        return ret;
    } else if (ret != 0) {
        printf("降级方案：记录错误，使用固定网络参数\n");
        return ret;
    }
    
    return 0;
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 0 | 成功 | 正常处理回调数据 |
| 201 | 权限不足 | 申请ohos.permission.GET_NETWORK_INFO权限 |
| 401 | 参数错误 | 检查回调函数和callbackId指针是否有效 |
| 801 | 系统能力不支持 | 检查设备是否支持SystemCapability.Communication.NetworkBoost.Core |
| 62100001 | 内部错误 | 检查系统状态，重试或重启应用 |
| 62100002 | 系统服务操作失败 | 检查NetworkBoost服务状态，重试或重启设备 |
| 62100003 | 注册请求达到上限 | 取消其他回调注册后再尝试 |

## 编译和修复问题

### 依赖声明

**CMakeLists.txt配置**：
```cmake
cmake_minimum_required(VERSION 3.4.1)
project(network_quality_demo)

add_library(network_quality_demo SHARED
    network_quality_demo.cpp
)

target_link_libraries(network_quality_demo
    libnetwork_boost.so
)
```

### 环境要求
- HarmonyOS SDK：≥5.1.0(18)
- 编译工具：CMake ≥3.4.1
- 开发语言：C/C++
- 目标平台：支持SystemCapability.Communication.NetworkBoost.Core的设备

### 常见编译问题

**问题1：找不到头文件**
```
fatal error: NetworkBoostKit/network_boost_quality.h: No such file or directory
```
**解决方法**：
- 确认HarmonyOS SDK已安装Network Boost Kit
- 检查头文件路径是否包含在编译配置中

**问题2：链接库失败**
```
undefined reference to 'HMS_NetworkBoost_RegisterNetQosCallback'
```
**解决方法**：
- 在CMakeLists.txt中添加libnetwork_boost.so链接
- 确认库文件存在于SDK中

**问题3：权限配置缺失**
```
运行时错误：Permission denied
```
**解决方法**：
- 在应用配置文件中添加权限声明：
```json
{
  "reqPermissions": [
    {
      "name": "ohos.permission.GET_NETWORK_INFO",
      "reason": "监听网络质量变化"
    }
  ]
}
```

## 常见问题与解决方法

### Q1：回调数据pathNum为0怎么办？
**原因**：网络质量信息暂未获取或网络状态异常
**解决方法**：
- 检查网络连接状态
- 等待下次回调触发
- 使用默认值或上次有效数据

### Q2：回调触发频率过高怎么办？
**原因**：网络质量变化频繁
**解决方法**：
- 在回调中增加时间过滤逻辑
- 仅处理关键质量变化
- 避免在回调中执行耗时操作

### Q3：带宽/速率单位转换问题
**原因**：API返回bps单位，应用需要B/s
**解决方法**：
```cpp
uint64_t bytesPerSecond = qos->linkDownRate / 8;
```

### Q4：取消注册失败怎么办？
**原因**：callbackId无效或系统服务异常
**解决方法**：
- 确认callbackId是注册时系统分配的值
- 检查系统服务状态
- 重试取消注册操作

### Q5：多条路径如何处理？
**原因**：设备支持多网并发，返回多条路径信息
**解决方法**：
- 根据业务需求选择合适路径
- 使用pathType区分不同链路类型
- 实现路径选择策略

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success/failed",
  "callbackId": "系统分配的回调ID",
  "registerResult": "注册结果（错误码）",
  "unregisterResult": "取消注册结果（错误码）",
  "apiUsed": [
    "HMS_NetworkBoost_RegisterNetQosCallback",
    "HMS_NetworkBoost_UnregisterNetQosCallback"
  ],
  "networkQualityInfo": {
    "pathNum": "路径数量",
    "paths": [
      {
        "pathType": "链路类型",
        "linkUpBandwidth": "上行带宽(bps)",
        "linkDownBandwidth": "下行带宽(bps)",
        "linkUpRate": "上行速率(bps)",
        "linkDownRate": "下行速率(bps)",
        "rttMs": "RTT时延(ms)",
        "linkUpBufferDelayMs": "上行缓冲时延(ms)"
      }
    ]
  }
}
```

## 参考文档

- [API开发指南](references/networkboost-qoscallback-c.md)
- [API参考说明](references/network-boost-c-overview.md)
- [头文件说明](references/network-boost-c-files-quality.md)
- [结构体说明](references/network-boost-c-struct-network_qos.md)
- [开发准备](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/networkboost-preparations)

## 完整示例代码

- [C++示例代码](assets/network_quality_demo.cpp)
- [CMake配置](assets/CMakeLists.txt)

## 测试用例

### 正向测试用例
- [注册回调成功测试](tests/test_register_success.cpp)：正常注册回调并接收数据
- [取消注册成功测试](tests/test_unregister_success.cpp)：正常取消注册
- [多路径数据处理测试](tests/test_multi_path.cpp)：处理多条路径网络质量信息

### 边界测试用例
- [最大路径数量测试](tests/test_max_path_num.cpp)：测试pathNum=4的情况
- [最小路径数量测试](tests/test_min_path_num.cpp)：测试pathNum=1的情况
- [带宽速率最大值测试](tests/test_max_bandwidth.cpp)：测试uint64_t最大值

### 异常测试用例
- [权限不足测试](tests/test_permission_denied.cpp)：测试权限缺失场景
- [参数错误测试](tests/test_param_error.cpp)：测试空指针等错误参数
- [系统服务异常测试](tests/test_service_error.cpp)：测试系统服务不可用场景
- [注册上限测试](tests/test_register_limit.cpp)：测试注册次数达到上限