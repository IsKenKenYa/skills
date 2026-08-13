---
name: hmos-performance-analysis-kit-mainthreadjank-watcher
description: 订阅主线程超时事件，通过HiAppEvent C API实现事件监听和订阅，支持onReceive回调实时接收事件数据，适用于性能分析、故障检测、主线程卡顿监控场景
---

# 订阅主线程超时事件技能

## 功能描述

本技能实现HarmonyOS主线程超时事件的订阅功能，通过HiAppEvent提供的C/C++接口创建事件观察者，监听并处理主线程超时事件。主线程超时事件（MAIN_THREAD_JANK）用于检测应用主线程执行耗时超过阈值的情况，帮助开发者及时发现和定位性能问题。

**核心能力**：
- 创建事件观察者并订阅主线程超时事件
- 实时接收事件数据并解析事件参数
- 提供事件数据的完整处理流程
- 支持观察者的移除和销毁

**技术特点**：
- 使用C API实现，适合Native C++工程
- 支持onReceive回调实时处理事件
- 事件数据包含完整的超时信息（时间、PID、UID、日志路径等）
- 需配合jsoncpp库解析事件参数JSON字符串

## 使用场景

### 触发词
- "订阅主线程超时事件" - 创建观察者订阅MAIN_THREAD_JANK事件
- "监听主线程卡顿" - 实时监控主线程执行耗时
- "性能分析订阅" - 设置性能事件观察者
- "主线程超时检测" - 配置主线程超时事件监听
- "HiAppEvent事件订阅" - 使用HiAppEvent接口订阅系统事件

### 能做
- 创建并配置事件观察者订阅MAIN_THREAD_JANK事件
- 实时接收主线程超时事件数据
- 解析事件参数获取超时详细信息
- 输出事件日志到HiLog进行调试
- 移除和销毁观察者释放资源
- 在Native C++工程中集成事件订阅功能

### 绝不做
- 不订阅其他非主线程超时相关的系统事件
- 不直接修改系统事件触发阈值配置
- 不替代系统的事件收集机制
- 不处理ArkTS或Java层的实现（仅支持C/C++）
- 不在未导入jsoncpp依赖的情况下直接运行

### 补充
- 必须使用Native C++工程模板
- 需导入jsoncpp开源库解析事件参数
- 观察者名称必须唯一，相同名称会覆盖前一次订阅
- OH_HiAppEvent_AddWatcher涉及I/O操作，性能敏感场景需考虑线程选择
- 回调函数中的指针生命周期仅限于回调函数内，需深拷贝缓存数据
- 主线程超时事件默认规格可参考官方文档配置

## 调用规范和规则

### 输入约束
- 观察者名称：字符串类型，长度不超过48字符，必须唯一
- 事件领域：DOMAIN_OS（"OS"）
- 事件名称：EVENT_MAIN_THREAD_JANK（"MAIN_THREAD_JANK"）
- 开发环境：DevEco Studio，Native C++工程
- 依赖库：libhiappevent_ndk.z.so、libhilog_ndk.z.so、jsoncpp

### 执行约束
- 最大观察者数量：无明确限制，但建议及时销毁不使用的观察者
- 回调处理时间：应在回调函数内快速处理，避免阻塞
- API调用顺序：CreateWatcher -> SetAppEventFilter -> SetWatcherOnReceive -> AddWatcher
- 销毁顺序：RemoveWatcher -> DestroyWatcher
- 观察者名称唯一性：相同名称后一次调用会覆盖前一次订阅

### 内容约束
- 禁止在回调函数外直接使用回调指针数据（需深拷贝）
- 禁止省略jsoncpp依赖（必须解析事件参数JSON字符串）
- 禁止在回调中进行耗时操作（避免阻塞事件处理）
- 禁止忘记销毁观察者（会导致内存泄漏）
- 禁止使用高危函数（如sprintf、strcpy等不安全函数）

### 降级约束
- jsoncpp库不可用：提示用户下载并导入开源库
- 观察者创建失败：检查名称参数是否合法，返回nullptr处理
- 事件解析失败：记录错误日志，跳过该事件处理
- 内存不足：优先销毁已创建的观察者释放资源
- API调用失败：根据返回值判断错误类型并提示用户

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 确认使用Native C++工程模板
2. 确认已导入jsoncpp开源库（jsoncpp.cpp、json.h、json-forwards.h）
3. 确认CMakeLists.txt已添加必要的源文件和动态库依赖
4. 确认已导入必要的头文件（hiappevent.h、hiappevent_event.h、hilog/log.h）

**参数准备**：
```cpp
// 导入必要模块
#include "napi/native_api.h"
#include "json/json.h"
#include "hilog/log.h"
#include "hiappevent/hiappevent.h"
#include "hiappevent/hiappevent_event.h"

// 定义日志标签
#undef LOG_TAG
#define LOG_TAG "MainThreadJankWatcher"

// 定义观察者指针缓存变量
static HiAppEvent_Watcher *systemEventWatcher = nullptr;
```

**依赖配置**：
```cmake
# CMakeLists.txt配置
# 新增jsoncpp.cpp源文件（解析订阅事件中的json字符串）
add_library(entry SHARED napi_init.cpp jsoncpp.cpp)

# 新增动态库依赖
target_link_libraries(entry PUBLIC 
    libace_napi.z.so 
    libhilog_ndk.z.so 
    libhiappevent_ndk.z.so
)
```

### 步骤2：定义回调函数

**onReceive回调实现**：
```cpp
static void OnReceive(const char *domain, const struct HiAppEvent_AppEventGroup *appEventGroups, uint32_t groupLen) {
    for (int i = 0; i < groupLen; ++i) {
        for (int j = 0; j < appEventGroups[i].infoLen; ++j) {
            // 输出事件基本信息
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.domain=%{public}s",
                        appEventGroups[i].appEventInfos[j].domain);
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.name=%{public}s",
                        appEventGroups[i].appEventInfos[j].name);
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.eventType=%{public}d",
                        appEventGroups[i].appEventInfos[j].type);
            
            // 判断是否为主线程超时事件
            if (strcmp(appEventGroups[i].appEventInfos[j].domain, DOMAIN_OS) == 0 &&
                strcmp(appEventGroups[i].appEventInfos[j].name, EVENT_MAIN_THREAD_JANK) == 0) {
                
                // 解析事件参数JSON字符串
                Json::Value params;
                Json::Reader reader(Json::Features::strictMode());
                Json::FastWriter writer;
                
                if (reader.parse(appEventGroups[i].appEventInfos[j].params, params)) {
                    // 提取事件参数
                    auto time = params["time"].asInt64();
                    auto pid = params["pid"].asInt();
                    auto uid = params["uid"].asInt();
                    auto bundleName = params["bundle_name"].asString();
                    auto bundleVersion = params["bundle_version"].asString();
                    auto beginTime = params["begin_time"].asInt64();
                    auto endTime = params["end_time"].asInt64();
                    auto externalLog = writer.write(params["external_log"]);
                    auto logOverLimit = params["logOverLimit"].asBool();
                    
                    // 输出事件详细信息
                    OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.time=%{public}lld", time);
                    OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.pid=%{public}d", pid);
                    OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.uid=%{public}d", uid);
                    OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.bundle_name=%{public}s",
                                bundleName.c_str());
                    OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.bundle_version=%{public}s",
                                bundleVersion.c_str());
                    OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.begin_time=%{public}lld", beginTime);
                    OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.end_time=%{public}lld", endTime);
                    OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.external_log=%{public}s", 
                                externalLog.c_str());
                    OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.log_over_limit=%{public}d",
                                logOverLimit);
                }
            }
        }
    }
}
```

### 步骤3：创建和配置观察者

**注册观察者函数**：
```cpp
static napi_value RegisterWatcher(napi_env env, napi_callback_info info) {
    OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent RegisterWatcher");
    
    // 步骤3.1：创建观察者（自定义观察者名称）
    systemEventWatcher = OH_HiAppEvent_CreateWatcher("MainThreadJankWatcher");
    if (systemEventWatcher == nullptr) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to create watcher");
        return {};
    }
    
    // 步骤3.2：设置订阅的事件过滤器
    const char *names[] = {EVENT_MAIN_THREAD_JANK};
    int result = OH_HiAppEvent_SetAppEventFilter(systemEventWatcher, DOMAIN_OS, 0, names, 1);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to set app event filter, error code: %{public}d", result);
        OH_HiAppEvent_DestroyWatcher(systemEventWatcher);
        systemEventWatcher = nullptr;
        return {};
    }
    
    // 步骤3.3：设置onReceive回调函数
    result = OH_HiAppEvent_SetWatcherOnReceive(systemEventWatcher, OnReceive);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to set watcher onReceive, error code: %{public}d", result);
        OH_HiAppEvent_DestroyWatcher(systemEventWatcher);
        systemEventWatcher = nullptr;
        return {};
    }
    
    // 步骤3.4：添加观察者开始监听
    result = OH_HiAppEvent_AddWatcher(systemEventWatcher);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to add watcher, error code: %{public}d", result);
        OH_HiAppEvent_DestroyWatcher(systemEventWatcher);
        systemEventWatcher = nullptr;
        return {};
    }
    
    OH_LOG_INFO(LogType::LOG_APP, "Watcher registered successfully");
    return {};
}
```

### 步骤4：注册ArkTS接口

**napi初始化函数**：
```cpp
static napi_value Init(napi_env env, napi_value exports) {
    napi_property_descriptor desc[] = {
        { "registerWatcher", nullptr, RegisterWatcher, nullptr, nullptr, nullptr, napi_default, nullptr }
    };
    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    return exports;
}
```

**ArkTS接口定义**（index.d.ts）：
```typescript
export const registerWatcher: () => void;
```

**ArkTS调用示例**（EntryAbility.ets）：
```typescript
// 导入依赖模块
import testNapi from 'libentry.so';

// 在onCreate()函数中调用
export default class EntryAbility extends UIAbility {
    onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
        // 启动时，注册系统事件观察者
        testNapi.registerWatcher();
    }
}
```

### 步骤5：触发测试事件

**模拟主线程超时**（Index.ets）：
```typescript
@Entry
@Component
struct Index {
    build() {
        Column() {
            Button("触发主线程超时350ms")
                .fontSize(50)
                .fontWeight(FontWeight.Bold)
                .onClick(() => {
                    // 模拟主线程超时场景
                    let t = Date.now();
                    while (Date.now() - t <= 350) {}
                })
        }
        .width('100%')
        .height('100%')
    }
}
```

### 步骤6：移除和销毁观察者

**移除观察者**：
```cpp
static napi_value RemoveWatcher(napi_env env, napi_callback_info info) {
    if (systemEventWatcher != nullptr) {
        // 使观察者停止监听事件
        int result = OH_HiAppEvent_RemoveWatcher(systemEventWatcher);
        if (result != 0) {
            OH_LOG_ERROR(LogType::LOG_APP, "Failed to remove watcher, error code: %{public}d", result);
        } else {
            OH_LOG_INFO(LogType::LOG_APP, "Watcher removed successfully");
        }
    }
    return {};
}
```

**销毁观察者**：
```cpp
static napi_value DestroyWatcher(napi_env env, napi_callback_info info) {
    if (systemEventWatcher != nullptr) {
        // 销毁创建的观察者，释放内存
        OH_HiAppEvent_DestroyWatcher(systemEventWatcher);
        systemEventWatcher = nullptr;
        OH_LOG_INFO(LogType::LOG_APP, "Watcher destroyed successfully");
    }
    return {};
}
```

**注册移除和销毁接口**：
```cpp
static napi_value Init(napi_env env, napi_value exports) {
    napi_property_descriptor desc[] = {
        { "registerWatcher", nullptr, RegisterWatcher, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "removeWatcher", nullptr, RemoveWatcher, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "destroyWatcher", nullptr, DestroyWatcher, nullptr, nullptr, nullptr, napi_default, nullptr }
    };
    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    return exports;
}
```

### 步骤7：错误处理

**错误码判断**：
```cpp
// 在API调用后判断返回值
int result = OH_HiAppEvent_CreateWatcher("watcher_name");
if (result == nullptr) {
    // 观察者创建失败，名称参数异常
    OH_LOG_ERROR(LogType::LOG_APP, "Watcher creation failed: name parameter invalid");
    return;
}

result = OH_HiAppEvent_SetAppEventFilter(watcher, domain, eventTypes, names, namesLen);
if (result == -1) {
    // names参数异常
    OH_LOG_ERROR(LogType::LOG_APP, "SetAppEventFilter failed: names parameter invalid");
} else if (result == -4) {
    // domain参数异常
    OH_LOG_ERROR(LogType::LOG_APP, "SetAppEventFilter failed: domain parameter invalid");
} else if (result == -5) {
    // watcher空指针
    OH_LOG_ERROR(LogType::LOG_APP, "SetAppEventFilter failed: watcher is null pointer");
}

result = OH_HiAppEvent_AddWatcher(watcher);
if (result == -5) {
    // watcher空指针
    OH_LOG_ERROR(LogType::LOG_APP, "AddWatcher failed: watcher is null pointer");
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 0 | 接口调用成功 | 正常处理流程 |
| -1 | names参数异常（事件名称数组参数无效） | 检查事件名称数组参数格式和长度 |
| -4 | domain参数异常（事件领域参数无效） | 检查domain参数是否为有效字符串（如DOMAIN_OS） |
| -5 | watcher空指针（观察者指针为null） | 确认OH_HiAppEvent_CreateWatcher返回值不为nullptr |
| -6 | 操作顺序有误（未调用AddWatcher就调用TakeWatcherData） | 确保调用顺序：CreateWatcher -> AddWatcher -> TakeWatcherData |
| nullptr | CreateWatcher返回nullptr（观察者名称参数异常） | 检查观察者名称是否符合规范（长度不超过48字符，首字符必须为字母或$） |

## 编译和修复问题

### 依赖声明

**CMakeLists.txt配置**：
```cmake
cmake_minimum_required(VERSION 3.4.1)
project(entry)

# 设置源文件
add_library(entry SHARED 
    napi_init.cpp 
    jsoncpp.cpp  # 必须导入jsoncpp.cpp
)

# 设置头文件路径
include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}/json  # jsoncpp头文件路径
)

# 链接动态库
target_link_libraries(entry PUBLIC 
    libace_napi.z.so       # NAPI接口库
    libhilog_ndk.z.so      # HiLog日志库
    libhiappevent_ndk.z.so # HiAppEvent事件库
)
```

**jsoncpp库导入**：
从 [三方开源库jsoncpp代码仓](https://github.com/open-source-parsers/jsoncpp) 下载源码压缩包，按照README的 **Amalgamated source** 操作步骤生成：
- jsoncpp.cpp
- json.h
- json-forwards.h

### 环境要求
- DevEco Studio：最新版本
- HarmonyOS SDK：API Version 12或更高（支持HiAppEvent C API）
- 编译工具：CMake 3.4.1+
- 语言标准：C++11或更高

### 常见编译问题

**问题1：找不到json/json.h头文件**
```
fatal error: json/json.h: No such file or directory
```
**解决方法**：
- 确认已下载jsoncpp开源库
- 将json.h和json-forwards.h放在cpp/json/目录下
- 在CMakeLists.txt中添加include_directories路径

**问题2：找不到libhiappevent_ndk.z.so动态库**
```
undefined reference to `OH_HiAppEvent_CreateWatcher'
```
**解决方法**：
- 确认HarmonyOS SDK版本 >= API 12
- 在CMakeLists.txt中添加libhiappevent_ndk.z.so链接
- 检查DevEco Studio是否正确配置SDK路径

**问题3：回调函数指针生命周期问题**
```
访问已释放的内存导致崩溃
```
**解决方法**：
- 在回调函数内深拷贝指针数据
- 不要在回调函数外直接使用回调中的指针
- 使用JSON解析提取参数后存储到局部变量

**问题4：观察者名称冲突**
```
相同名称的观察者覆盖了前一次订阅
```
**解决方法**：
- 使用唯一的观察者名称
- 在移除观察者后再创建新的观察者
- 遵循"先移除后销毁"的资源管理原则

## 常见问题与解决方法

### Q1：如何获取主线程超时事件的详细信息？
**原因**：事件参数以JSON字符串格式传递，需要解析提取。
**解决方法**：
- 导入jsoncpp库
- 使用Json::Reader解析params字符串
- 通过参数名提取具体值（time、pid、uid、bundle_name等）
- 参考：OnReceive回调函数实现

### Q2：观察者创建返回nullptr怎么办？
**原因**：观察者名称参数不符合规范或内存不足。
**解决方法**：
- 检查名称长度不超过48字符
- 确保首字符为字母或$
- 确保中间字符为数字、字母或下划线
- 确保结尾字符为数字或字母
- 检查系统内存是否充足

### Q3：如何确认订阅成功？
**原因**：需要验证观察者是否正确监听事件。
**解决方法**：
- 检查所有API调用返回值为0
- 添加OH_LOG_INFO日志输出订阅成功信息
- 触发测试事件（模拟主线程超时）验证回调是否触发
- 在DevEco Studio Log窗口查看事件日志

### Q4：回调函数中的指针可以直接保存吗？
**原因**：回调中的指针生命周期仅限于回调函数内。
**解决方法**：
- 不能直接保存指针引用
- 必须对指针指向的内容进行深拷贝
- 使用JSON解析提取数据到局部变量
- 将需要缓存的数据复制到自定义数据结构

### Q5：如何配置主线程超时阈值？
**原因**：系统有默认的超时阈值配置。
**解决方法**：
- 参考官方文档：[主线程超时事件默认时间规格](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/apptask-timeout-guidelines)
- 参考官方文档：[主线程超时事件日志规格](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/apptask-timeout-guidelines)
- 使用OH_HiAppEvent_SetEventConfig配置事件触发条件（需要HiAppEvent_Config对象）

### Q6：观察者不销毁会有什么问题？
**原因**：观察者对象常驻内存不释放。
**解决方法**：
- 会导致内存泄漏
- 必须调用OH_HiAppEvent_RemoveWatcher停止监听
- 必须调用OH_HiAppEvent_DestroyWatcher销毁对象
- 销毁后将指针置为nullptr防止重复销毁

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "watcherName": "MainThreadJankWatcher",
  "subscribedEvent": "MAIN_THREAD_JANK",
  "eventDomain": "OS",
  "callbackType": "onReceive",
  "apiUsed": [
    "OH_HiAppEvent_CreateWatcher",
    "OH_HiAppEvent_SetAppEventFilter",
    "OH_HiAppEvent_SetWatcherOnReceive",
    "OH_HiAppEvent_AddWatcher",
    "OH_HiAppEvent_RemoveWatcher",
    "OH_HiAppEvent_DestroyWatcher"
  ],
  "eventParams": [
    "time",
    "pid",
    "uid",
    "bundle_name",
    "bundle_version",
    "begin_time",
    "end_time",
    "external_log",
    "logOverLimit"
  ]
}
```

**事件日志输出示例**：
```
HiAppEvent eventInfo.domain=OS
HiAppEvent eventInfo.name=MAIN_THREAD_JANK
HiAppEvent eventInfo.eventType=1
HiAppEvent eventInfo.params.time=1717597063727
HiAppEvent eventInfo.params.pid=45572
HiAppEvent eventInfo.params.uid=20020151
HiAppEvent eventInfo.params.bundle_name=com.example.nativemainthread
HiAppEvent eventInfo.params.bundle_version=1.0.0
HiAppEvent eventInfo.params.begin_time=1717597063225
HiAppEvent eventInfo.params.end_time=1717597063727
HiAppEvent eventInfo.params.external_log=["/data/storage/el2/log/watchdog/MAIN_THREAD_JANK_20240613221239_45572.txt"]
HiAppEvent eventInfo.params.log_over_limit=0
```

## 参考文档

- [API开发指南：订阅主线程超时事件（C/C++）](references/hiappevent-watcher-mainthreadjank-events-ndk.md)
- [API参考说明：hiappevent.h](references/capi-hiappevent-h.md)
- [API参考说明：hiappevent_event.h](references/capi-hiappevent-event-h.md)
- [主线程超时事件默认时间规格](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/apptask-timeout-guidelines)
- [主线程超时事件日志规格](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/apptask-timeout-guidelines)

## 完整示例代码

- [C++完整示例：napi_init.cpp](assets/napi_init.cpp)
- [ArkTS接口定义：index.d.ts](assets/index.d.ts)
- [ArkTS调用示例：EntryAbility.ets](assets/EntryAbility.ets)
- [测试页面：Index.ets](assets/Index.ets)
- [构建配置：CMakeLists.txt](assets/CMakeLists.txt)

## 测试用例

### 正向测试用例
- [测试1：成功创建观察者并订阅事件](tests/test_positive.cpp)：验证观察者创建、过滤器设置、回调配置、添加观察者的完整流程
- [测试2：成功接收主线程超时事件](tests/test_positive.cpp)：验证触发主线程超时后回调函数正确接收事件数据
- [测试3：成功解析事件参数](tests/test_positive.cpp)：验证JSON解析正确提取所有事件参数字段

### 边界测试用例
- [测试1：观察者名称长度边界](tests/test_boundary.cpp)：测试48字符长度名称和超长名称的处理
- [测试2：事件参数数组边界](tests/test_boundary.cpp)：测试参数数组为空和多参数情况
- [测试3：回调函数处理时间边界](tests/test_boundary.cpp)：测试大量事件同时到达的处理性能

### 异常测试用例
- [测试1：观察者名称非法字符](tests/test_exception.cpp)：测试包含非法字符的名称处理
- [测试2：空指针参数](tests/test_exception.cpp)：测试watcher为nullptr时的API返回值
- [测试3：jsoncpp库缺失](tests/test_exception.cpp)：测试未导入jsoncpp时的编译错误
- [测试4：未调用AddWatcher直接调用TakeWatcherData](tests/test_exception.cpp)：测试操作顺序错误时的返回值
- [测试5：重复创建相同名称观察者](tests/test_exception.cpp)：测试相同名称覆盖问题