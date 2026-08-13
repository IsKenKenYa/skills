---
name: hmos-networkboost-kit-multipath-recommendation
description: 监听系统多网建议变化事件+获取多网建议动作+支持注册和取消注册回调+适用于弱网和网络切换等多网加速场景+需要 ohos.permission.LINKTURBO 权限+API版本 6.0.2(22)+
---

# 多网建议监听(C/C++)技能

## 功能描述

本技能提供系统多网建议变化事件的监听能力。系统感知到应用可能需要使用多网络加速的场景时,如弱网、网络切换等特定场景,会给出建议。应用通过监听多网络加速的建议,决策发起多网络加速的请求。

**核心能力**:
- 注册系统多网建议变化事件回调
- 接收多网推荐动作(发起或释放多网请求)
- 取消注册多网建议监听回调

**适用范围**:
- Network Boost Kit 的多网并发场景
- C/C++ API 开发环境
- HarmonyOS API 6.0.2(22) 及以上版本

**关键限制**:
- 需要 ohos.permission.LINKTURBO 受限权限
- 需要正确配置签名和权限申请
- 回调函数必须有效且不为空

## 使用场景

### 触发词
- "多网建议监听" - 监听系统多网建议变化
- "监听多网推荐" - 获取多网推荐动作
- "NetworkBoost多网建议" - Network Boost Kit多网建议功能
- "多网并发建议" - 多网并发场景的建议监听
- "注册多网建议回调" - 注册多网建议变化事件

### 能做
- 注册多网建议变化事件回调,获取回调ID
- 接收系统多网建议信息(NetworkBoost_MultiPathRecommendation)
- 根据建议动作(NB_MULTIPATH_ACTION_REQUEST/NB_MULTIPATH_ACTION_RELEASE)决策发起或释放多网请求
- 取消注册多网建议监听回调
- 处理多网建议相关的错误码和异常情况

### 绝不做
- 直接发起多网请求(需使用 HMS_NetworkBoost_RequestMultiPath)
- 替代多网状态监听(需使用 HMS_NetworkBoost_RegisterMultiPathStateChangeCallback)
- 处理非多网建议相关的网络事件
- 在回调函数中执行耗时操作或阻塞操作
- 绕过权限检查直接调用 API

### 补充
- 需要申请 ohos.permission.LINKTURBO 受限权限,需要通过 AGC 申请并配置签名
- API 版本要求: 6.0.2(22) 及以上
- 需要在 CMakeLists.txt 中配置 libnetwork_boost.so 动态库链接
- 回调函数在系统线程中执行,需要注意线程安全
- 注册回调后,系统会在合适的场景下主动推送多网建议

## 调用规范和规则

### 输入约束
- 回调函数指针: 必须有效,不能为 NULL
- callbackId 参数: 必须为有效的 uint32_t* 指针,用于接收系统分配的回调ID
- 函数签名: 必须符合 HMS_NetworkBoost_OnMultiPathRecommendation 类型定义
- 权限配置: module.json5 中必须声明 ohos.permission.LINKTURBO 权限
- 签名配置: 必须通过 AGC 申请受限 ACL 权限并配置签名

### 执行约束
- 注册回调耗时: 通常 < 100ms,异常情况可能达到数秒
- 最大注册次数: 单个应用最多注册有限数量的回调(系统限制)
- 回调执行频率: 取决于系统多网建议触发频率,通常在弱网或网络切换场景
- 取消注册耗时: 通常 < 50ms
- 最大迭代次数: 注册失败时最多重试 3 次

### 内容约束
- 禁止在回调函数中: 执行耗时操作(>100ms)、阻塞操作、调用同步网络请求、修改全局状态
- 禁止使用高危函数: system()、exec()、eval() 等系统调用
- 禁止操作: 绕过权限检查、伪造多网建议事件、恶意占用回调资源
- 回调函数必须: 快速处理建议、记录日志、通知应用主线程、及时返回

### 降级约束
- 网络服务失败: 记录错误日志,返回错误码 1013600002,提示用户检查系统服务状态
- 权限不足: 返回错误码 201,提示用户检查权限配置和签名
- 参数错误: 返回错误码 1013600041,立即停止执行并提示参数无效
- 注册达到上限: 返回错误码 62100003,建议取消旧回调后再注册
- 系统内部错误: 记录错误码 1013600001,尝试重新注册(最多3次),持续失败则提示用户

## 调用流程和步骤

### 步骤1: 准备阶段

**权限配置校验**:
1. 检查 module.json5 中是否已声明 ohos.permission.LINKTURBO 权限
2. 检查是否已通过 AGC 申请并配置了受限 ACL 权限签名
3. 验证应用是否已获得 ohos.permission.LINKTURBO 权限授权

**开发环境准备**:
```cpp
// CMakeLists.txt 配置
target_include_directories(entry PUBLIC ${HMOS_SDK_NATIVE}/sysroot/usr/include)
target_link_directories(entry PUBLIC ${HMOS_SDK_NATIVE}/sysroot/usr/lib/aarch64-linux-ohos)
target_link_libraries(entry PUBLIC libnetwork_boost.so)
```

**头文件导入**:
```cpp
#include "NetworkBoostKit/network_boost_handover.h"
#include <cstdio>
#include <cstring>
```

### 步骤2: 定义回调函数

**回调函数定义**:
```cpp
// 定义多网建议回调函数
void onMultiPathRecommendationCallback(NetworkBoost_MultiPathRecommendation* recommendation) {
    if (recommendation == nullptr) {
        printf("错误: 多网建议信息为空\n");
        return;
    }
    
    // 处理多网建议动作
    switch (recommendation->action) {
        case NB_MULTIPATH_ACTION_REQUEST:
            printf("系统建议: 发起多网请求\n");
            // 应用可根据此建议调用 HMS_NetworkBoost_RequestMultiPath 发起多网请求
            break;
        case NB_MULTIPATH_ACTION_RELEASE:
            printf("系统建议: 释放多网请求\n");
            // 应用可根据此建议调用 HMS_NetworkBoost_ReleaseMultiPath 释放多网请求
            break;
        default:
            printf("未知的多网建议动作: %d\n", recommendation->action);
            break;
    }
}
```

### 步骤3: 注册多网建议回调

**注册回调示例代码**:
```cpp
uint32_t callbackId = 0;

int32_t RegisterMultiPathRecommendation() {
    // 参数校验
    if (onMultiPathRecommendationCallback == nullptr) {
        printf("错误: 回调函数指针为空\n");
        return 1013600041;  // 参数错误
    }
    
    // 注册回调,获取回调Id
    int32_t ret = HMS_NetworkBoost_RegisterMultiPathRecommendationCallback(
        onMultiPathRecommendationCallback, 
        &callbackId
    );
    
    // 处理返回结果
    if (ret == 0) {
        printf("注册多网建议监听回调成功, 回调ID: %u\n", callbackId);
        return 0;
    } else {
        printf("注册多网建议监听回调失败, 错误码: %d\n", ret);
        return ret;
    }
}
```

### 步骤4: 错误处理

**错误处理代码**:
```cpp
void HandleRegisterError(int32_t errorCode) {
    switch (errorCode) {
        case 0:
            printf("成功: 多网建议回调注册成功\n");
            break;
        case 201:
            printf("错误: 权限不足, 请检查 ohos.permission.LINKTURBO 权限配置和签名\n");
            break;
        case 1013600001:
            printf("错误: 内部处理异常, 系统状态机或消息队列异常\n");
            break;
        case 1013600002:
            printf("错误: 系统服务异常, IPC调用失败或网络管理服务未启动\n");
            break;
        case 1013600041:
            printf("错误: 参数错误, 回调函数指针或 callbackId 指针为空\n");
            break;
        case 62100003:
            printf("错误: 注册请求达到上限, 请先取消旧回调\n");
            break;
        default:
            printf("错误: 未知错误码 %d\n", errorCode);
            break;
    }
}
```

### 步骤5: 取消注册回调

**取消注册示例代码**:
```cpp
int32_t UnregisterMultiPathRecommendation() {
    // 参数校验
    if (callbackId == 0) {
        printf("警告: 回调ID为0, 可能未注册或已取消注册\n");
        return 1013600041;
    }
    
    // 使用注册时获取的回调Id取消注册
    int32_t ret = HMS_NetworkBoost_UnregisterMultiPathRecommendationCallback(callbackId);
    
    // 处理返回结果
    if (ret == 0) {
        printf("取消多网建议监听回调成功\n");
        callbackId = 0;  // 清空回调ID
        return 0;
    } else {
        printf("取消多网建议监听回调失败, 错误码: %d\n", ret);
        return ret;
    }
}
```

### 步骤6: 降级处理

**降级处理代码**:
```cpp
int32_t RegisterWithFallback() {
    int32_t ret = RegisterMultiPathRecommendation();
    
    // 如果注册失败,尝试降级方案
    if (ret != 0) {
        printf("首次注册失败,尝试降级方案...\n");
        
        // 降级方案1: 检查并重新配置权限
        if (ret == 201) {
            printf("降级方案: 提示用户检查权限配置\n");
            return ret;
        }
        
        // 降级方案2: 系统服务异常时重试
        if (ret == 1013600002) {
            printf("降级方案: 系统服务异常,等待1秒后重试\n");
            // sleep(1);  // 实际应用中可使用延时
            ret = RegisterMultiPathRecommendation();
            if (ret == 0) {
                printf("重试注册成功\n");
                return 0;
            }
        }
        
        // 降级方案3: 注册达到上限时取消旧回调
        if (ret == 62100003) {
            printf("降级方案: 注册达到上限,尝试取消旧回调\n");
            // 实际应用中可先取消其他回调
            ret = RegisterMultiPathRecommendation();
        }
        
        // 最终降级: 无法注册时提示用户
        if (ret != 0) {
            printf("最终降级: 无法注册多网建议回调,请检查系统状态\n");
        }
    }
    
    return ret;
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 0 | 成功 | 无需处理 |
| 201 | 权限不足 | 检查 module.json5 中是否声明 ohos.permission.LINKTURBO 权限,并通过 AGC 申请受限 ACL 权限 |
| 1013600001 | 内部处理异常 | 系统状态机或消息队列异常,记录日志并稍后重试 |
| 1013600002 | 系统服务异常 | IPC跨进程调用失败或网络管理服务未启动,检查系统服务状态并重试 |
| 1013600041 | 参数错误 | 检查回调函数指针和 callbackId 指针是否为有效指针 |
| 62100003 | 注册请求达到上限 | 取消旧的回调后再重新注册 |

## 编译和修复问题

### 依赖声明

**CMakeLists.txt 配置**:
```cmake
cmake_minimum_required(VERSION 3.4.1)
project(NetworkBoostExample)

# 设置 HMOS SDK Native 路径(需根据实际环境配置)
set(HMOS_SDK_NATIVE "/path/to/hmos/sdk/native")

# 添加头文件路径
target_include_directories(entry PUBLIC ${HMOS_SDK_NATIVE}/sysroot/usr/include)

# 添加动态库路径
target_link_directories(entry PUBLIC ${HMOS_SDK_NATIVE}/sysroot/usr/lib/aarch64-linux-ohos)

# 链接动态库
target_link_libraries(entry PUBLIC libnetwork_boost.so)
```

### 环境要求

- HarmonyOS SDK: API 6.0.2(22) 及以上
- 开发环境: DevEco Studio 3.1 及以上
- 编译工具: CMake 3.4.1 及以上
- 目标架构: aarch64-linux-ohos

### 常见编译问题

**问题1: 找不到头文件**
```
fatal error: NetworkBoostKit/network_boost_handover.h: No such file or directory
```
**解决方法**: 检查 HMOS_SDK_NATIVE 路径是否正确配置,确保 SDK 已正确安装

**问题2: 链接动态库失败**
```
cannot find -lnetwork_boost
```
**解决方法**: 检查 target_link_directories 和 target_link_libraries 配置是否正确,确保 libnetwork_boost.so 文件存在

**问题3: 权限未配置**
```
应用运行时返回错误码 201
```
**解决方法**: 在 module.json5 中添加 ohos.permission.LINKTURBO 权限声明,并通过 AGC 申请受限 ACL 权限并配置签名

**问题4: 签名配置错误**
```
应用无法启动或权限被拒绝
```
**解决方法**: 参考 [开发准备](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/networkboost-preparations) 完成签名配置和受限 ACL 权限申请

## 常见问题与解决方法

### Q1: 如何申请 ohos.permission.LINKTURBO 受限权限?

**原因**: LINKTURBO 是受限 ACL 权限,需要特别申请和配置

**解决方法**:
1. 在 AGC 中申请调试 Profile 或发布 Profile
2. 在权限申请页面选择"受限ACL权限"
3. 在权限搜索框中输入"ohos.permission.LINKTURBO"并勾选
4. 填写申请原因并提交(1个工作日内回复)
5. 权限申请通过后,下载新的 Profile 文件并配置签名
6. 在 module.json5 中声明权限

### Q2: 回调函数没有被触发怎么办?

**原因**: 多网建议回调只在特定场景下触发(弱网、网络切换等)

**解决方法**:
- 检查回调是否注册成功(返回码为0)
- 确认系统处于弱网或网络切换场景
- 检查是否已发起多网请求(某些场景需要先请求)
- 查看系统日志确认是否有多网建议事件
- 确认回调函数指针是否有效

### Q3: 注册回调返回 62100003 错误码怎么办?

**原因**: 注册请求达到系统上限

**解决方法**:
- 取消已注册的旧回调: `HMS_NetworkBoost_UnregisterMultiPathRecommendationCallback(oldCallbackId)`
- 重新注册新的回调
- 避免频繁注册和取消注册
- 检查是否有其他模块也注册了多网建议回调

### Q4: 回调函数中可以执行哪些操作?

**原因**: 回调函数在系统线程中执行,需要注意性能和线程安全

**解决方法**:
- 回调函数应快速处理建议(耗时<100ms)
- 可以记录日志、更新标志位、通知主线程
- 避免执行耗时操作、阻塞操作、同步网络请求
- 避免修改全局状态或调用其他系统 API
- 使用异步方式通知应用主线程(如消息队列、事件通知)

### Q5: 如何区分多网建议和多网状态监听?

**原因**: 两个功能相似但用途不同

**解决方法**:
- **多网建议监听**(本技能): 系统主动推送建议,告诉应用何时发起或释放多网请求
- **多网状态监听**(HMS_NetworkBoost_RegisterMultiPathStateChangeCallback): 监听多网链路的状态变化(建立、释放、挂起等)
- 根据业务需求选择合适的功能,或同时使用两个功能

## 输出结果报告

执行完成后输出以下信息:

```json
{
  "status": "success|failed",
  "callbackId": "uint32_t 回调ID(注册成功时)",
  "errorCode": "int32_t 错误码",
  "apiUsed": [
    "HMS_NetworkBoost_RegisterMultiPathRecommendationCallback",
    "HMS_NetworkBoost_UnregisterMultiPathRecommendationCallback"
  ],
  "recommendationReceived": "bool 是否收到多网建议",
  "recommendationAction": "NB_MULTIPATH_ACTION_REQUEST|NB_MULTIPATH_ACTION_RELEASE"
}
```

## 参考文档

- [多网建议监听开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/networkboost-netmultipath-recommendcallback-c)
- [Network Boost Kit API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/network-boost-c-overview)
- [Network Boost Kit开发准备](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/networkboost-preparations)
- [NetworkBoost_MultiPathRecommendation结构体](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/network-boost-c-struct-multipath_reco)

## 完整示例代码

- [C++示例代码](assets/example_multipath_recommendation.cpp): 完整的多网建议监听示例
- [CMake配置示例](assets/example_cmake.txt): CMakeLists.txt配置示例

## 测试用例

### 正向测试用例
- [注册多网建议回调成功](tests/test_positive.cpp): 验证正常注册流程
- [接收多网建议并处理](tests/test_positive.cpp): 验证回调函数正确处理建议动作
- [取消注册回调成功](tests/test_positive.cpp): 验证取消注册流程

### 边界测试用例
- [多次注册和取消注册](tests/test_boundary.cpp): 验证注册上限和取消后重新注册
- [回调函数快速返回](tests/test_boundary.cpp): 验证回调函数性能要求
- [长时间监听](tests/test_boundary.cpp): 验证长时间运行稳定性

### 异常测试用例
- [权限未配置](tests/test_exception.cpp): 验证权限不足场景处理
- [参数为空指针](tests/test_exception.cpp): 验证参数校验和错误处理
- [系统服务异常](tests/test_exception.cpp): 验证系统异常降级处理
- [回调函数异常](tests/test_exception.cpp): 验证回调函数异常场景处理