---
name: hmos-network-boost-kit-multipath-recommendation-listener
description: 监听系统多网建议变化事件，支持注册和取消注册回调，适用于弱网、网络切换等场景下的多网加速决策
---

# 多网建议监听(C/C++)

## 功能描述

本技能用于监听系统多网建议变化事件。当系统感知到应用可能需要使用多网络加速的场景时（如弱网、网络切换等），会给出建议。应用通过监听多网络加速的建议，决策发起多网络加速的请求。

**核心能力**：
- 注册系统多网建议变化回调
- 接收系统多网建议（建议发起多网请求或释放多网请求）
- 取消注册多网建议监听回调

**适用范围**：
- HarmonyOS 6.0.2(22)及以上版本
- C/C++原生应用开发
- Network Boost Kit多网并发场景

**限制条件**：
- 需要申请ohos.permission.LINKTURBO权限
- 最大注册回调数量有限制
- 需要在业务流程结束时取消注册

**典型场景**：
- 弱网环境下多网加速决策
- 网络切换场景下的多网并发优化
- 实时音视频、游戏等对网络质量要求高的业务

## 使用场景

### 触发词
- "监听多网建议"
- "多网建议变化回调"
- "注册多网建议监听"
- "系统多网推荐事件"
- "Network Boost多网建议"
- "多网并发建议监听"

### 能做
- 注册系统多网建议变化事件回调
- 实时接收系统的多网建议（建议发起多网请求或释放多网请求）
- 根据系统建议决策是否发起多网加速
- 在业务流程结束时取消注册监听回调
- 处理多网建议变化事件的应用逻辑

### 绝不做
- 不直接发起或释放多网请求（仅监听建议）
- 不替代应用自身的多网决策逻辑
- 不处理网络质量检测或连接迁移
- 不处理超出Network Boost Kit范围的请求
- 不在无权限环境下强行注册回调

### 补充
- 回调函数必须定义且不能为空指针
- 注册成功后系统会分配callbackId，需保存用于取消注册
- 多网建议包含推荐动作（NB_MULTIPATH_ACTION_REQUEST或NB_MULTIPATH_ACTION_RELEASE）
- 需配合HMS_NetworkBoost_RequestMultiPath和HMS_NetworkBoost_ReleaseMultiPath使用
- 建议在应用前台活跃场景下使用，后台场景可能被系统限制

## 调用规范和规则

### 输入约束
- 回调函数指针：必须为有效的函数指针，不能为NULL
- callbackId指针：必须为有效的uint32_t指针，用于接收系统分配的ID
- 取消注册时的callbackId：必须为注册时系统分配的有效ID

### 执行约束
- 注册回调最大耗时：应在100ms内完成
- 最大注册次数：受系统限制（返回错误码1013600041时表示达到上限）
- 回调执行时间：应在50ms内完成，避免阻塞系统回调线程
- 取消注册应在业务流程结束时立即执行

### 内容约束
- 禁止在回调函数中执行耗时操作（如文件IO、网络请求）
- 禁止在回调函数中阻塞或睡眠
- 禁止使用已取消注册的callbackId再次取消注册
- 禁止在回调函数中直接调用系统API（可能导致死锁）
- 禁止忽略错误码，必须对返回值进行检查和处理

### 降级约束
- 注册失败：记录日志，提示用户无法监听多网建议，应用自主决策多网使用
- 回调执行异常：记录异常日志，不影响后续回调
- 取消注册失败：记录日志，尝试再次取消，若持续失败可忽略（系统会自动清理）
- 权限不足：提示用户申请权限，降级为不监听多网建议的场景
- 系统服务异常：降级为应用自主网络策略，不依赖系统建议

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 检查HarmonyOS版本是否>=6.0.2(22)
2. 确认已申请ohos.permission.LINKTURBO权限
3. 确认CMakeLists.txt已添加libnetwork_boost.so依赖
4. 确认头文件路径正确

**参数准备**：
```cpp
// 定义回调函数
void onMultiPathRecommendationCallback(NetworkBoost_MultiPathRecommendation* recommendation) {
    // 回调处理逻辑
}

// 定义callbackId变量
uint32_t callbackId = 0;
```

### 步骤2：注册回调

**示例代码**：
```cpp
#include "NetworkBoostKit/network_boost_handover.h"
#include <cstdio>
#include <cstring>

// 全局变量保存callbackId
static uint32_t g_callbackId = 0;

// 多网建议变化回调函数
void onMultiPathRecommendationCallback(NetworkBoost_MultiPathRecommendation* recommendation) {
    if (recommendation == nullptr) {
        printf("错误：recommendation指针为空\n");
        return;
    }
    
    // 处理多网建议
    if (recommendation->action == NB_MULTIPATH_ACTION_REQUEST) {
        printf("系统建议发起多网请求\n");
        // 应用可根据此建议调用HMS_NetworkBoost_RequestMultiPath
    } else if (recommendation->action == NB_MULTIPATH_ACTION_RELEASE) {
        printf("系统建议释放多网请求\n");
        // 应用可根据此建议调用HMS_NetworkBoost_ReleaseMultiPath
    }
}

// 注册多网建议监听
int32_t RegisterMultiPathRecommendation() {
    // 检查参数有效性
    if (onMultiPathRecommendationCallback == nullptr) {
        printf("错误：回调函数指针为空\n");
        return 1013600041;
    }
    
    // 注册回调
    int32_t ret = HMS_NetworkBoost_RegisterMultiPathRecommendationCallback(
        onMultiPathRecommendationCallback, 
        &g_callbackId
    );
    
    // 检查返回值
    if (ret == 0) {
        printf("注册多网建议监听成功，callbackId: %u\n", g_callbackId);
    } else {
        printf("注册多网建议监听失败，错误码: %d\n", ret);
        HandleRegisterError(ret);
    }
    
    return ret;
}

// 错误处理
void HandleRegisterError(int32_t errorCode) {
    switch (errorCode) {
        case 201:
            printf("权限不足，请申请ohos.permission.LINKTURBO权限\n");
            break;
        case 1013600001:
            printf("内部处理异常，请稍后重试\n");
            break;
        case 1013600002:
            printf("系统服务异常，网络管理服务可能未启动\n");
            break;
        case 1013600041:
            printf("参数错误或注册请求达到上限\n");
            break;
        default:
            printf("未知错误: %d\n", errorCode);
    }
}
```

### 步骤3：业务逻辑处理

在回调函数中根据系统建议决策：

```cpp
// 应用业务逻辑
void ProcessRecommendation(NetworkBoost_MultiPathRecommendation* recommendation) {
    // 参数校验
    if (recommendation == nullptr) {
        return;
    }
    
    // 根据建议动作处理
    switch (recommendation->action) {
        case NB_MULTIPATH_ACTION_REQUEST:
            // 系统建议发起多网请求
            // 应用可根据业务场景决定是否发起
            if (IsInHighQoSScene()) {
                printf("高QoS场景，响应系统建议发起多网请求\n");
                int32_t result = HMS_NetworkBoost_RequestMultiPath(nullptr);
                if (result != 0) {
                    printf("发起多网请求失败: %d\n", result);
                }
            } else {
                printf("当前场景无需多网，忽略建议\n");
            }
            break;
            
        case NB_MULTIPATH_ACTION_RELEASE:
            // 系统建议释放多网请求
            printf("响应系统建议释放多网请求\n");
            int32_t result = HMS_NetworkBoost_ReleaseMultiPath();
            if (result != 0) {
                printf("释放多网请求失败: %d\n", result);
            }
            break;
            
        default:
            printf("未知的建议动作: %d\n", recommendation->action);
    }
}

// 判断是否在高QoS场景
bool IsInHighQoSScene() {
    // 应用自行判断当前业务场景
    // 例如：实时视频、实时游戏、直播等
    return true;
}
```

### 步骤4：取消注册回调

**示例代码**：
```cpp
// 取消多网建议监听
int32_t UnregisterMultiPathRecommendation() {
    // 检查callbackId有效性
    if (g_callbackId == 0) {
        printf("警告：callbackId为0，可能未注册或已取消\n");
        return 1013600041;
    }
    
    // 取消注册
    int32_t ret = HMS_NetworkBoost_UnregisterMultiPathRecommendationCallback(g_callbackId);
    
    // 检查返回值
    if (ret == 0) {
        printf("取消多网建议监听成功\n");
        g_callbackId = 0;  // 重置callbackId
    } else {
        printf("取消多网建议监听失败，错误码: %d\n", ret);
        HandleUnregisterError(ret);
    }
    
    return ret;
}

// 取消注册错误处理
void HandleUnregisterError(int32_t errorCode) {
    switch (errorCode) {
        case 201:
            printf("权限不足\n");
            break;
        case 1013600001:
            printf("内部处理异常\n");
            break;
        case 1013600002:
            printf("系统服务异常\n");
            break;
        default:
            printf("未知错误: %d\n", errorCode);
    }
}
```

### 步骤5：完整生命周期管理

```cpp
// 应用启动时注册
void OnAppStart() {
    int32_t ret = RegisterMultiPathRecommendation();
    if (ret != 0) {
        // 注册失败，降级处理
        printf("多网建议监听不可用，应用自主决策网络策略\n");
    }
}

// 应用退出时取消注册
void OnAppExit() {
    if (g_callbackId != 0) {
        UnregisterMultiPathRecommendation();
    }
}

// 主函数示例
int main() {
    // 应用启动
    OnAppStart();
    
    // 业务逻辑执行
    // ...
    
    // 应用退出
    OnAppExit();
    
    return 0;
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 0 | 成功 | 无需处理 |
| 201 | 权限不足 | 在module.json5中申请ohos.permission.LINKTURBO权限 |
| 1013600001 | 内部处理异常（状态机异常、消息队列阻塞） | 稍后重试，记录日志，联系系统排查 |
| 1013600002 | 系统处理异常（IPC失败、服务未启动） | 检查系统服务状态，重启应用或设备 |
| 1013600041 | 传入参数有误（空指针）或注册达到上限 | 检查参数有效性，减少注册次数 |

## 编译和修复问题

### 依赖声明

**CMakeLists.txt配置**：
```cmake
cmake_minimum_required(VERSION 3.10)
project(networkboost_example)

# 添加Network Boost Kit依赖
find_library(network_boost_lib libnetwork_boost.so)

add_executable(networkboost_example
    src/main.cpp
)

target_link_libraries(networkboost_example
    ${network_boost_lib}
)

# 添加头文件路径
target_include_directories(networkboost_example
    PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/include
)
```

### 环境要求
- HarmonyOS版本：>= 6.0.2(22)
- SDK版本：包含Network Boost Kit
- 编译工具：支持C/C++的HarmonyOS编译工具链

### 常见编译问题

**问题1：找不到头文件**
```
fatal error: NetworkBoostKit/network_boost_handover.h: No such file or directory
```
**解决方法**：
- 确认SDK已安装Network Boost Kit
- 检查头文件路径是否正确
- 在CMakeLists.txt中添加正确的include路径

**问题2：链接失败**
```
undefined reference to 'HMS_NetworkBoost_RegisterMultiPathRecommendationCallback'
```
**解决方法**：
- 确认CMakeLists.txt中已添加libnetwork_boost.so
- 检查库文件路径是否正确
- 确认使用find_library正确链接

**问题3：权限错误**
```
运行时报错：201 Permission denied
```
**解决方法**：
- 在module.json5中添加权限声明：
```json
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.LINKTURBO"
      }
    ]
  }
}
```

**问题4：API版本不匹配**
```
调用返回801系统能力不支持
```
**解决方法**：
- 检查设备HarmonyOS版本是否>=6.0.2(22)
- 检查SystemCapability是否包含SystemCapability.Communication.NetworkBoost.Core

## 常见问题与解决方法

### Q1：注册回调返回1013600041
**原因**：参数错误或注册请求达到上限
**解决方法**：
- 检查回调函数指针是否为有效指针（非NULL）
- 检查callbackId指针是否为有效指针（非NULL）
- 检查是否已注册过多回调，尝试取消之前的注册

### Q2：回调函数未被执行
**原因**：系统未触发多网建议变化事件
**解决方法**：
- 确认注册成功（返回值为0）
- 确认设备处于多网场景（弱网、网络切换）
- 系统仅在感知到需要多网加速的场景时才会触发回调

### Q3：取消注册返回1013600002
**原因**：系统服务异常
**解决方法**：
- 检查网络管理服务是否正常运行
- 尝试重启应用或设备
- 若持续失败，系统会自动清理资源，可忽略错误

### Q4：callbackId为0或无效
**原因**：未正确保存注册时的callbackId
**解决方法**：
- 确保使用全局变量或持久化存储保存callbackId
- 注册成功后立即检查callbackId是否为有效值（>0）
- 取消注册前检查callbackId有效性

### Q5：回调函数中调用API导致死锁
**原因**：回调函数中直接调用系统API
**解决方法**：
- 回调函数中仅记录建议，不直接调用API
- 使用队列或事件机制异步处理建议
- 在非回调线程中调用HMS_NetworkBoost_RequestMultiPath或HMS_NetworkBoost_ReleaseMultiPath

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "operation": "multipath_recommendation_listener",
  "callbackId": 12345,
  "apiUsed": [
    "HMS_NetworkBoost_RegisterMultiPathRecommendationCallback",
    "HMS_NetworkBoost_UnregisterMultiPathRecommendationCallback"
  ],
  "timestamp": "2026-07-03T22:46:00Z"
}
```

## 参考文档

- [API开发指南：多网建议监听(C/C++)](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/networkboost-netmultipath-recommendcallback-c)
- [API参考说明：NetworkBoost模块](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/network-boost-c-overview)
- [API参考说明：NetworkBoost_MultiPathRecommendation结构体](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/network-boost-c-struct-multipath_reco)
- [开发准备：C API开发准备](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/networkboost-preparations)

## 完整示例代码

- [C++示例：多网建议监听完整示例](assets/multipath_recommendation_listener_example.cpp)
- [CMake配置示例](assets/cmake_example.txt)

## 测试用例

### 正向测试用例
- [注册回调成功测试](tests/test_register_success.cpp)：验证正常注册流程
- [接收建议回调测试](tests/test_receive_recommendation.cpp)：验证回调函数正确接收建议
- [取消注册成功测试](tests/test_unregister_success.cpp)：验证正常取消注册流程

### 边界测试用例
- [callbackId边界测试](tests/test_callbackid_boundary.cpp)：验证callbackId最大值和最小值
- [多次注册取消测试](tests/test_multiple_register_unregister.cpp)：验证多次注册和取消的场景

### 异常测试用例
- [空指针参数测试](tests/test_null_pointer.cpp)：验证空指针参数的错误处理
- [无效callbackId测试](tests/test_invalid_callbackid.cpp)：验证无效callbackId的错误处理
- [权限不足测试](tests/test_permission_denied.cpp)：验证无权限时的降级处理
- [系统服务异常测试](tests/test_service_exception.cpp)：验证系统服务异常时的处理