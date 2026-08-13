---
name: hmos-networkboost-kit-multipath-request-release
description: 发起和释放多网并发请求，支持WiFi蜂窝并发及主卡副卡并发，系统决定并发组合，最大支持配额限制，适用于网络加速场景
---

# 多网发起和释放技能

## 功能描述

本技能提供HarmonyOS多网并发请求的发起和释放功能。应用可根据自身业务需要以及系统的建议来发起多网络加速请求，并在使用结束后及时释放。支持WiFi和蜂窝并发以及主卡和副卡并发，不支持开发者指定并发组合，并发组合由系统决定。

**核心功能**：
- 发起多网请求：通过HMS_NetworkBoost_RequestMultiPath发起多网络并发请求
- 释放多网请求：通过HMS_NetworkBoost_ReleaseMultiPath释放多网络并发请求
- 监听多网状态：通过注册回调函数监听多网请求结果和状态变化

**技术特点**：
- API版本：6.0.2(22)及以上
- 编程语言：C/C++
- 权限要求：ohos.permission.LINKTURBO（受限权限）
- 系统管控：并发组合由系统决定，应用申请（受限权限）、系统管控、最小化使用

## 使用场景

### 触发词
- "发起多网请求"
- "释放多网请求"
- "多网并发"
- "网络加速"
- "WiFi蜂窝并发"
- "主卡副卡并发"
- "多网发起和释放"

### 能做
- 发起多网并发请求，支持WiFi和蜂窝并发以及主卡和副卡并发
- 释放多网并发请求，及时释放网络资源
- 监听多网请求结果，获取请求成功或失败状态
- 监听多网状态变化，获取多网链路状态、类型等信息
- 获取多网配额信息，了解当前应用多网使用的配额情况

### 绝不做
- 不支持开发者指定并发组合（并发组合由系统决定）
- 不支持在未开启网络加速开关的情况下发起多网请求
- 不支持在不满足并发条件的情况下发起多网请求（如主副卡插入同运营商卡场景）
- 不支持在不支持双卡场景的设备上发起多网并发
- 不支持在传输协议接口不支持指定网络的情况下使用多网

### 补充
- 主卡和副卡并发需要开启智能切换上网卡开关，并依赖主卡和副卡驻留网络的频点
- 受限于硬件，部分设备不支持双卡场景下的多网并发
- 多网发起需要开启网络加速开关：设置->移动网络->网络加速->允许使用移动数据加速网络
- 如果没有该开关，说明当前设备/ROM不支持多网并发能力
- HTTP当前只支持默认网络传输，不支持指定网络，所以无法使用多网并发

## 调用规范和规则

### 输入约束
- 权限要求：必须申请ohos.permission.LINKTURBO权限（受限ACL权限）
- 设备要求：设备必须支持多网并发能力（可通过错误码1013620009排查）
- 开关状态：必须开启网络加速开关
- 频次限制：多网发起不能太频繁（错误码1013620006）
- 配额限制：应用多网请求有配额限制（错误码1013620002）
- API版本：必须使用6.0.2(22)及以上版本

### 执行约束
- 最大耗时：多网建立可能耗时，需设置合理的超时处理
- 回调注册：发起多网请求前需注册回调函数监听结果
- 及时释放：业务流程结束后必须及时释放多网请求
- 系统管控：应用发起多网请求后，系统决定并发组合和实施相应的并发管控

### 内容约束
- 禁止生成：不生成指定并发组合的代码
- 禁止操作：不绕过系统管控直接操作网络
- 禁止高频请求：不频繁发起和释放多网请求
- 禁止长时间占用：不长时间拉起多网不释放（系统可能释放多网）

### 降级约束
- 多网请求失败：提示用户网络条件不满足或设备不支持
- 权限不足：提示用户申请LINKTURBO权限
- 设备不支持：提示用户当前设备不支持多网并发能力
- 开关未开启：提示用户开启网络加速开关
- 配额耗尽：提示用户配额已耗尽，等待配额恢复

## 调用流程和步骤

### 步骤1：准备阶段

**权限申请**：
1. 在module.json5中申请ohos.permission.LINKTURBO权限（受限ACL权限）
2. 在AGC中申请LINKTURBO受限权限（调试和发布Profile）
3. 配置签名信息

**参数准备**：
```cpp
// CMakeLists.txt配置
target_include_directories(entry PUBLIC ${HMOS_SDK_NATIVE}/sysroot/usr/include)
target_link_directories(entry PUBLIC ${HMOS_SDK_NATIVE}/sysroot/usr/lib/aarch64-linux-ohos)
target_link_libraries(entry PUBLIC libnetwork_boost.so)
```

**权限配置**：
```json
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.GET_NETWORK_INFO"
      },
      {
        "name": "ohos.permission.INTERNET"
      },
      {
        "name": "ohos.permission.LINKTURBO"
      }
    ]
  }
}
```

### 步骤2：导入模块和定义回调函数

**导入模块**：
```cpp
#include "NetworkBoostKit/network_boost_handover.h"
#include <cstdio>
#include <cstring>
```

**定义回调函数**：
```cpp
// 多网请求结果回调
void onMultiPathRequestResultCallback(NetworkBoost_MultiPathRequestResult* result) {
    if (result == nullptr) {
        printf("多网请求结果回调参数为空\n");
        return;
    }
    
    // 根据结果处理多网请求成功或失败
    switch (result->result) {
        case NB_MULTIPATH_ERROR_NONE:
            printf("多网请求成功\n");
            break;
        case NB_MULTIPATH_ERROR_NETWORK_REFUSED:
            printf("多网请求被网络拒绝\n");
            break;
        case NB_MULTIPATH_ERROR_TIMEOUT:
            printf("多网建立超时\n");
            break;
        case NB_MULTIPATH_ERROR_LOCAL:
            printf("多网建立过程中本地释放\n");
            break;
        default:
            printf("未知错误：%d\n", result->result);
            break;
    }
}

// 多网状态变化回调
void onMultiPathStateChangeCallback(NetworkBoost_MultiPathStateChange* multiPathState) {
    if (multiPathState == nullptr) {
        printf("多网状态变化回调参数为空\n");
        return;
    }
    
    // 处理多网状态变化
    printf("多网状态：%d，变化原因：%d，链路类型：%d，链路状态：%d\n",
           multiPathState->multiPathState,
           multiPathState->changeCause,
           multiPathState->pathType,
           multiPathState->pathState);
    
    switch (multiPathState->multiPathState) {
        case NB_MULTIPATH_IDLE:
            printf("多网处于空闲状态\n");
            break;
        case NB_MULTIPATH_CREATEING:
            printf("多网正在建立中\n");
            break;
        case NB_MULTIPATH_CREATED:
            printf("多网已建立\n");
            break;
        case NB_MULTIPATH_RELEASING:
            printf("多网正在释放中\n");
            break;
    }
}
```

### 步骤3：发起多网请求

**示例代码**：
```cpp
#include "NetworkBoostKit/network_boost_handover.h"
#include <cstdio>

// 发起多网请求
int32_t RequestMultiPath() {
    // 发起多网请求，注册回调监听请求结果
    int32_t ret = HMS_NetworkBoost_RequestMultiPath(onMultiPathRequestResultCallback);
    
    if (ret != 0) {
        printf("发起多网请求失败，错误码：%d\n", ret);
        return ret;
    }
    
    printf("发起多网请求成功，等待回调结果\n");
    return ret;
}
```

### 步骤4：释放多网请求

**示例代码**：
```cpp
#include "NetworkBoostKit/network_boost_handover.h"
#include <cstdio>

// 释放多网请求
int32_t ReleaseMultiPath() {
    // 释放多网请求
    int32_t ret = HMS_NetworkBoost_ReleaseMultiPath();
    
    if (ret != 0) {
        printf("释放多网请求失败，错误码：%d\n", ret);
        return ret;
    }
    
    printf("释放多网请求成功\n");
    return ret;
}
```

### 步骤5：错误处理

**错误处理代码**：
```cpp
#include "NetworkBoostKit/network_boost_handover.h"
#include <cstdio>

// 发起多网请求并处理错误
int32_t RequestMultiPathWithErrorHandling() {
    int32_t ret = HMS_NetworkBoost_RequestMultiPath(onMultiPathRequestResultCallback);
    
    switch (ret) {
        case 0:
            printf("发起多网请求成功\n");
            break;
        case 201:
            printf("权限不足，请申请ohos.permission.LINKTURBO权限\n");
            break;
        case 1013600001:
            printf("内部处理异常\n");
            break;
        case 1013600002:
            printf("系统处理异常，IPC跨进程调用失败\n");
            break;
        case 1013600041:
            printf("传入参数有误，回调函数为空\n");
            break;
        case 1013620000:
            printf("多网功能没有使能，请开启网络加速开关\n");
            break;
        case 1013620001:
            printf("多网已经激活或者在激活过程中\n");
            break;
        case 1013620002:
            printf("应用多网请求已经达到上限\n");
            break;
        case 1013620003:
            printf("功耗限制不允许发起多网\n");
            break;
        case 1013620004:
            printf("限额耗尽\n");
            break;
        case 1013620005:
            printf("多网请求场景的冲突\n");
            break;
        case 1013620006:
            printf("多网发起太频繁，请稍后再试\n");
            break;
        case 1013620007:
            printf("没有合适的多网链路可用\n");
            break;
        case 1013620008:
            printf("流量不足\n");
            break;
        case 1013620009:
            printf("不支持并发，当前设备不支持多网并发能力\n");
            break;
        default:
            printf("未知错误：%d\n", ret);
            break;
    }
    
    return ret;
}

// 释放多网请求并处理错误
int32_t ReleaseMultiPathWithErrorHandling() {
    int32_t ret = HMS_NetworkBoost_ReleaseMultiPath();
    
    switch (ret) {
        case 0:
            printf("释放多网请求成功\n");
            break;
        case 201:
            printf("权限不足，请申请ohos.permission.LINKTURBO权限\n");
            break;
        case 1013600001:
            printf("内部处理异常\n");
            break;
        case 1013600002:
            printf("系统处理异常，IPC跨进程调用失败\n");
            break;
        case 1013620100:
            printf("多网已经激活状态，但不是当前应用拉起的\n");
            break;
        case 1013620101:
            printf("多网不在激活态\n");
            break;
        default:
            printf("未知错误：%d\n", ret);
            break;
    }
    
    return ret;
}
```

### 步骤6：降级处理

**降级处理代码**：
```cpp
#include "NetworkBoostKit/network_boost_handover.h"
#include <cstdio>

// 降级处理：多网请求失败后的处理
void handleMultiPathRequestFailure(int32_t errorCode) {
    switch (errorCode) {
        case 1013620009:
            // 设备不支持多网并发，使用单网传输
            printf("降级方案：当前设备不支持多网并发，使用单网传输\n");
            break;
        case 1013620000:
            // 网络加速开关未开启，提示用户开启
            printf("降级方案：请前往设置->移动网络->网络加速->允许使用移动数据加速网络，开启开关\n");
            break;
        case 1013620004:
            // 配额耗尽，等待配额恢复
            printf("降级方案：配额已耗尽，等待配额恢复或使用单网传输\n");
            break;
        case 1013620007:
            // 没有合适的多网链路，使用单网传输
            printf("降级方案：没有合适的多网链路，使用单网传输\n");
            break;
        case 1013620008:
            // 流量不足，使用WiFi传输
            printf("降级方案：流量不足，建议使用WiFi传输\n");
            break;
        default:
            printf("降级方案：使用单网传输\n");
            break;
    }
}

// 完整的多网请求流程（带降级处理）
int32_t requestMultiPathWithFallback() {
    int32_t ret = HMS_NetworkBoost_RequestMultiPath(onMultiPathRequestResultCallback);
    
    if (ret != 0) {
        // 多网请求失败，执行降级处理
        handleMultiPathRequestFailure(ret);
        return ret;
    }
    
    // 等待回调结果
    printf("多网请求已发起，等待回调结果\n");
    return 0;
}
```

## 错误码说明

### HMS_NetworkBoost_RequestMultiPath 错误码

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 0 | 成功 | 无需处理 |
| 201 | 权限不足 | 申请ohos.permission.LINKTURBO权限 |
| 1013600001 | 内部处理异常 | 检查系统状态，重启应用或设备 |
| 1013600002 | 系统处理异常 | 检查网络管理服务是否正常，重启设备 |
| 1013600041 | 传入参数有误 | 确保回调函数不为空指针 |
| 1013620000 | 多网功能没有使能 | 开启网络加速开关：设置->移动网络->网络加速 |
| 1013620001 | 多网已经激活或正在激活 | 检查是否已经发起多网请求，避免重复请求 |
| 1013620002 | 应用多网请求已达上限 | 等待配额恢复或释放其他多网请求 |
| 1013620003 | 功耗限制不允许发起多网 | 降低功耗需求或等待功耗限制解除 |
| 1013620004 | 限额耗尽 | 等待配额恢复或申请更多配额 |
| 1013620005 | 多网请求场景冲突 | 检查是否有其他场景冲突，调整业务场景 |
| 1013620006 | 多网发起太频繁 | 降低发起频率，避免频繁请求 |
| 1013620007 | 没有合适的多网链路可用 | 检查网络条件，使用单网传输 |
| 1013620008 | 流量不足 | 检查流量余额，使用WiFi传输 |
| 1013620009 | 不支持并发 | 设备不支持多网并发，使用单网传输 |

### HMS_NetworkBoost_ReleaseMultiPath 错误码

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 0 | 成功 | 无需处理 |
| 201 | 权限不足 | 申请ohos.permission.LINKTURBO权限 |
| 1013600001 | 内部处理异常 | 检查系统状态，重启应用或设备 |
| 1013600002 | 系统处理异常 | 检查网络管理服务是否正常，重启设备 |
| 1013620100 | 多网已激活但不是当前应用拉起 | 检查多网状态，避免释放其他应用的多网 |
| 1013620101 | 多网不在激活态 | 检查多网状态，确保多网已建立后再释放 |

### 多网请求结果回调错误码（NetworkBoost_MultiPathErrorResult）

| 枚举值 | 说明 | 解决方法 |
|-------|------|---------|
| NB_MULTIPATH_ERROR_NONE | 多网建立成功 | 无需处理 |
| NB_MULTIPATH_ERROR_NETWORK_REFUSED | 多网请求被网络拒绝 | 检查网络条件，使用单网传输 |
| NB_MULTIPATH_ERROR_TIMEOUT | 多网建立超时 | 检查网络状态，重试或使用单网传输 |
| NB_MULTIPATH_ERROR_LOCAL | 本地释放 | 检查本地状态，重新发起请求 |

## 编译和修复问题

### 依赖声明

**CMakeLists.txt配置**：
```cmake
cmake_minimum_required(VERSION 3.4.1)
project(NetworkBoostMultiPath)

# 设置SDK路径
set(HMOS_SDK_NATIVE ${HMOS_SDK_NATIVE})

# 添加头文件路径
target_include_directories(entry PUBLIC 
    ${HMOS_SDK_NATIVE}/sysroot/usr/include
)

# 添加动态库路径
target_link_directories(entry PUBLIC 
    ${HMOS_SDK_NATIVE}/sysroot/usr/lib/aarch64-linux-ohos
)

# 链接动态库
target_link_libraries(entry PUBLIC 
    libnetwork_boost.so
)
```

### 环境要求

- HarmonyOS SDK：必须包含Network Boost Kit C API
- API版本：6.0.2(22)及以上
- 编译工具：CMake 3.4.1及以上
- 目标架构：aarch64-linux-ohos

### 常见编译问题

**问题1：找不到头文件**
```
fatal error: NetworkBoostKit/network_boost_handover.h: No such file or directory
```
**解决方法**：
- 确保HMOS_SDK_NATIVE环境变量正确设置
- 检查SDK路径是否包含sysroot/usr/include目录
- 确认SDK版本包含Network Boost Kit C API（6.0.2及以上）

**问题2：链接失败**
```
undefined reference to `HMS_NetworkBoost_RequestMultiPath'
```
**解决方法**：
- 确保CMakeLists.txt中添加了libnetwork_boost.so链接
- 检查动态库路径是否正确（aarch64-linux-ohos）
- 确认SDK版本包含libnetwork_boost.so

**问题3：权限配置错误**
```
应用启动失败，缺少ohos.permission.LINKTURBO权限
```
**解决方法**：
- 在module.json5中添加ohos.permission.LINKTURBO权限
- 在AGC中申请LINKTURBO受限权限（调试和发布Profile）
- 配置签名信息

**问题4：API版本不匹配**
```
调用HMS_NetworkBoost_RequestMultiPath返回错误码801
```
**解决方法**：
- 检查设备API版本是否为6.0.2(22)及以上
- 确认SDK版本与设备API版本匹配
- 升级设备或SDK版本

## 常见问题与解决方法

### Q1：多网请求失败，返回错误码1013620009

**原因**：当前设备不支持多网并发能力，可能受限于硬件或ROM版本。

**解决方法**：
- 检查设备是否支持双卡场景下的多网并发
- 检查设备ROM版本是否为6.0.2(22)及以上
- 检查是否有网络加速开关（设置->移动网络->网络加速）
- 如果设备不支持，使用单网传输作为降级方案

### Q2：多网请求失败，返回错误码1013620000

**原因**：网络加速开关未开启。

**解决方法**：
- 前往设置->移动网络->网络加速->允许使用移动数据加速网络，开启开关
- 如果没有该开关，说明当前设备/ROM不支持多网并发能力

### Q3：多网请求失败，返回错误码201

**原因**：权限不足，未申请ohos.permission.LINKTURBO权限。

**解决方法**：
- 在module.json5中添加ohos.permission.LINKTURBO权限
- 在AGC中申请LINKTURBO受限权限（调试和发布Profile）
- 配置签名信息，使用包含LINKTURBO权限的Profile文件

### Q4：多网请求成功但实际无法传输数据

**原因**：传输协议接口不支持指定网络。

**解决方法**：
- 检查传输协议接口是否支持指定网络（如HTTP当前只支持默认网络传输）
- 使用支持指定网络的传输协议接口
- 或者使用单网传输

### Q5：多网长时间占用被系统释放

**原因**：应用长时间拉起多网不释放，系统自动释放多网（错误码NB_MULTIPATH_CHANGE_CAUSE_RELEASE_SYS_FUSING）。

**解决方法**：
- 业务流程结束后及时释放多网请求
- 避免长时间占用多网资源
- 监听多网状态变化回调，及时处理系统释放事件

### Q6：主卡和副卡并发失败

**原因**：主卡和副卡并发需要满足特定条件。

**解决方法**：
- 开启智能切换上网卡开关
- 检查主卡和副卡是否为不同运营商
- 检查主卡和副卡驻留网络的频点是否满足并发条件
- 如果不满足并发条件，使用单网传输

### Q7：多网配额耗尽

**原因**：应用多网请求配额已耗尽。

**解决方法**：
- 等待配额恢复
- 申请更多配额
- 使用单网传输作为降级方案
- 及时释放不必要的多网请求

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "operation": "多网发起和释放",
  "apiUsed": [
    "HMS_NetworkBoost_RequestMultiPath",
    "HMS_NetworkBoost_ReleaseMultiPath"
  ],
  "result": {
    "requestResult": "NB_MULTIPATH_ERROR_NONE",
    "multiPathState": "NB_MULTIPATH_CREATED",
    "pathType": "NB_PATH_CELLULAR_SECONDARY",
    "pathState": "NB_PATH_CONNECTED"
  },
  "timestamp": "2026-07-03T10:30:00Z"
}
```

## 参考文档

- [API开发指南 - 多网发起和释放(C/C++)](references/networkboost-netmultipath-request-release-c.md)
- [API参考说明 - NetworkBoost模块](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/network-boost-c-overview)
- [开发准备 - Network Boost Kit](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/networkboost-preparations)
- [多网请求结果结构体](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/network-boost-c-struct-multipath_req_result)
- [多网状态变化结构体](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/network-boost-c-struct-multipath_statechange)

## 完整示例代码

- [C++示例代码](assets/example_multipath_request_release.cpp) - 包含完整的多网发起和释放流程
- [CMakeLists.txt示例](assets/CMakeLists.txt) - 包含依赖配置
- [module.json5示例](assets/module.json5) - 包含权限配置

## 测试用例

### 正向测试用例
- [正向测试](tests/test_positive.cpp) - 测试正常发起和释放多网请求

### 边界测试用例
- [边界测试](tests/test_boundary.cpp) - 测试配额限制和并发限制

### 异常测试用例
- [异常测试](tests/test_exception.cpp) - 测试权限、开关、设备支持等异常场景