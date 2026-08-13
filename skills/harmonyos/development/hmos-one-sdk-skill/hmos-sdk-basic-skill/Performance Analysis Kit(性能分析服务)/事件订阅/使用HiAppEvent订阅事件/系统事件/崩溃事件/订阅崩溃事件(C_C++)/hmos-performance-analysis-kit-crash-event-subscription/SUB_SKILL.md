---
name: hmos-performance-analysis-kit-crash-event-subscription
description: 订阅应用崩溃事件(JsError和NativeCrash),支持C/C++接口,支持实时订阅和延迟上报,适用于故障监控、性能分析场景
---

# 订阅崩溃事件(C/C++)技能

## 功能描述

本技能用于使用HiAppEvent提供的C/C++接口订阅应用崩溃事件,包括JsError类型和NativeCrash类型的崩溃事件。通过注册观察者,开发者可以实时接收崩溃事件信息,包括崩溃时间、崩溃类型、进程信息、内存状态、异常堆栈等详细信息,帮助开发者快速定位和修复应用崩溃问题。

### 核心功能

- 创建和管理崩溃事件观察者
- 订阅系统崩溃事件(EVENT_APP_CRASH)
- 配置崩溃事件采集参数(寄存器扩展内存打印、日志截断、VMA映射信息、应用日志拼接、minidump等)
- 处理崩溃事件回调(onReceive和onTrigger两种模式)
- 解析崩溃事件参数(包括time、crash_type、foreground、exception、memory、hilog等)

### API版本要求

- 起始版本: API version 12
- 系统能力: SystemCapability.HiviewDFX.HiAppEvent
- 支持语言: C/C++
- 依赖库: libhiappevent_ndk.z.so, libhilog_ndk.z.so

## 使用场景

### 触发词

- "订阅崩溃事件"
- "监听应用崩溃"
- "捕获JsError"
- "捕获NativeCrash"
- "崩溃事件订阅(C/C++)"
- "HiAppEvent订阅崩溃"
- "性能分析崩溃监控"

### 能做

- 订阅系统崩溃事件(EVENT_APP_CRASH),包括JsError和NativeCrash类型
- 实时接收崩溃事件信息,包括崩溃类型、时间、进程信息、内存状态等
- 配置崩溃事件采集参数,如寄存器扩展内存打印、日志截断大小、VMA映射信息简化等
- 提供两种观察者模式:onReceive(实时回调)和onTrigger(条件触发回调)
- 在应用未主动捕获崩溃异常场景下,下次启动时上报崩溃事件
- 在应用主动捕获崩溃异常场景下,应用退出前触发崩溃事件回调
- 解析崩溃事件的JSON参数,提取关键信息进行日志记录和问题分析

### 绝不做

- 不订阅非崩溃类型的系统事件(如应用冻屏事件、主线程超时事件)
- 不处理ArkTS/Java层的崩溃事件(仅支持C/C++接口)
- 不替代FaultLogExtensionAbility的延迟上报功能(需API version 21及以上)
- 不在崩溃事件回调中执行耗时操作(可能导致应用退出延迟)
- 不在回调函数外直接使用回调中的指针(需进行深拷贝)

### 补充

- 必须在应用启动后、执行业务逻辑前添加事件观察者,否则可能因崩溃退出而无法订阅
- JsError崩溃事件通过进程内采集故障信息触发回调,速度快
- NativeCrash崩溃事件采取进程外采集故障信息,平均耗时约2秒,受业务线程数量和进程间通信影响
- 订阅崩溃事件后,故障信息采集完成会异步上报,不阻塞当前业务
- 订阅接口OH_HiAppEvent_AddWatcher传入的名称name是唯一的,相同name会覆盖前一次订阅
- 建议在DevEco Studio的HiLog窗口查看订阅的崩溃事件内容

## 调用规范和规则

### 输入约束

- 观察者名称: 字符串类型,长度非空且不超过256字符,不能为nullptr
- 事件名称: 必须为EVENT_APP_CRASH(系统崩溃事件名称)
- 事件领域: 必须为DOMAIN_OS(系统事件领域)
- 配置参数: 
  - OH_APP_CRASH_PARAM_EXTEND_PC_LR_PRINTING: "true"或"false"
  - OH_APP_CRASH_PARAM_LOG_FILE_CUTOFF_SZ_BYTES: 数字字符串(如"2097152")
  - OH_APP_CRASH_PARAM_SIMPLIFY_VMA_PRINTING: "true"或"false"
  - OH_APP_CRASH_PARAM_MERGE_CPPCRASH_APP_LOG: "true"或"false"
  - OH_APP_CRASH_PARAM_COLLECT_MINIDUMP: "true"或"false"

### 执行约束

- 最大回调耗时: 建议不超过100ms(避免应用退出延迟)
- 最大事件保存数量: 由OH_HiAppEvent_SetTriggerCondition设置
- 最大事件保存大小: 由OH_HiAppEvent_SetTriggerCondition设置
- 最大超时时间: 由OH_HiAppEvent_SetTriggerCondition设置(单位秒)
- API调用顺序: CreateWatcher -> SetAppEventFilter -> SetWatcherOnReceive/SetWatcherOnTrigger -> AddWatcher
- 销毁顺序: RemoveWatcher -> DestroyWatcher

### 内容约束

- 禁止在回调函数外直接使用回调中的指针(生命周期仅限于回调函数内)
- 禁止在回调函数中执行阻塞操作或耗时操作
- 禁止使用已销毁的观察者指针
- 禁止重复调用AddWatcher添加同名观察者(会覆盖前一次订阅)
- 禁止在不调用RemoveWatcher的情况下直接DestroyWatcher

### 降级约束

- 观察者创建失败: 返回nullptr,检查名称参数是否合法
- AddWatcher失败: 返回-5(watcher空指针),检查观察者指针是否有效
- 配置设置失败: 返回非0错误码,检查配置参数是否合法
- 崩溃事件未订阅: 提示用户在应用启动时注册观察者
- 回调未触发: 检查是否正确设置过滤条件和回调函数

## 调用流程和步骤

### 步骤1: 准备阶段

**前置校验**:
1. 检查API版本是否满足要求(API version 12及以上)
2. 检查系统能力是否支持(SystemCapability.HiviewDFX.HiAppEvent)
3. 确认依赖库已正确链接(libhiappevent_ndk.z.so, libhilog_ndk.z.so)
4. 准备jsoncpp库用于解析崩溃事件JSON参数(可选,如需解析事件参数)

**参数准备**:
```cpp
// C++示例:准备观察者名称和事件过滤参数
const char* watcherName = "AppCrashWatcherR"; // 观察者名称
const char* domain = DOMAIN_OS; // 系统事件领域
const char* names[] = {EVENT_APP_CRASH}; // 崩溃事件名称
int namesLen = 1; // 事件名称数量
```

### 步骤2: 创建观察者并设置过滤条件

**示例代码(onReceive模式)**:
```cpp
// 导入必要头文件
#include "hiappevent/hiappevent.h"
#include "hiappevent/hiappevent_param.h"
#include "hilog/log.h"

// 定义观察者指针缓存
static HiAppEvent_Watcher* systemEventWatcherR = nullptr;

// 创建观察者
systemEventWatcherR = OH_HiAppEvent_CreateWatcher("AppCrashWatcherR");
if (systemEventWatcherR == nullptr) {
    OH_LOG_ERROR(LOG_APP, "Failed to create watcher");
    return;
}

// 设置订阅的事件为EVENT_APP_CRASH(崩溃事件)
int ret = OH_HiAppEvent_SetAppEventFilter(systemEventWatcherR, DOMAIN_OS, 0, names, namesLen);
if (ret != 0) {
    OH_LOG_ERROR(LOG_APP, "Failed to set app event filter: %{public}d", ret);
    OH_HiAppEvent_DestroyWatcher(systemEventWatcherR);
    systemEventWatcherR = nullptr;
    return;
}
```

### 步骤3: 设置回调函数

**onReceive回调示例(实时接收崩溃事件)**:
```cpp
// 定义onReceive类型观察者的回调方法
static void OnReceiveCrashEvent(const char* domain, const struct HiAppEvent_AppEventGroup* appEventGroups, uint32_t groupLen)
{
    for (int i = 0; i < groupLen; ++i) {
        for (int j = 0; j < appEventGroups[i].infoLen; ++j) {
            const struct HiAppEvent_AppEventInfo& appEventInfo = appEventGroups[i].appEventInfos[j];
            OH_LOG_INFO(LOG_APP, "HiAppEvent eventInfo.domain=%{public}s", appEventInfo.domain);
            OH_LOG_INFO(LOG_APP, "HiAppEvent eventInfo.name=%{public}s", appEventInfo.name);
            OH_LOG_INFO(LOG_APP, "HiAppEvent eventInfo.eventType=%{public}d", appEventInfo.type);
            
            // 检查是否为崩溃事件
            if (strcmp(appEventInfo.domain, DOMAIN_OS) != 0 || strcmp(appEventInfo.name, EVENT_APP_CRASH) != 0) {
                continue;
            }
            
            // 解析崩溃事件参数(JSON格式)
            Json::Value params;
            Json::Reader reader(Json::Features::strictMode());
            if (reader.parse(appEventInfo.params, params)) {
                OH_LOG_INFO(LOG_APP, "HiAppEvent eventInfo.params.time=%{public}lld", params["time"].asInt64());
                OH_LOG_INFO(LOG_APP, "HiAppEvent eventInfo.params.crash_type=%{public}s", params["crash_type"].asString().c_str());
                OH_LOG_INFO(LOG_APP, "HiAppEvent eventInfo.params.foreground=%{public}d", params["foreground"].asBool());
                OH_LOG_INFO(LOG_APP, "HiAppEvent eventInfo.params.exception=%{public}s", params["exception"].asString().c_str());
                // 更多参数解析...
            }
        }
    }
}

// 设置onReceive回调
ret = OH_HiAppEvent_SetWatcherOnReceive(systemEventWatcherR, OnReceiveCrashEvent);
if (ret != 0) {
    OH_LOG_ERROR(LOG_APP, "Failed to set watcher on receive: %{public}d", ret);
    OH_HiAppEvent_DestroyWatcher(systemEventWatcherR);
    systemEventWatcherR = nullptr;
    return;
}
```

**onTrigger回调示例(条件触发)**:
```cpp
// 定义OnTake回调,获取保存的事件
static void OnTakeCrash(const char* const* events, uint32_t eventLen)
{
    Json::Reader reader(Json::Features::strictMode());
    for (int i = 0; i < eventLen; ++i) {
        Json::Value eventInfo;
        if (reader.parse(events[i], eventInfo)) {
            auto domain = eventInfo["domain_"].asString();
            auto name = eventInfo["name_"].asString();
            if (domain == DOMAIN_OS && name == EVENT_APP_CRASH) {
                OH_LOG_INFO(LOG_APP, "Crash event received: %{public}s", events[i]);
                // 处理崩溃事件...
            }
        }
    }
}

// 定义OnTrigger回调
static void OnTriggerCrash(int row, int size)
{
    // 接收回调后,获取指定数量的已接收事件
    OH_HiAppEvent_TakeWatcherData(systemEventWatcherT, row, OnTakeCrash);
}

// 定义观察者指针缓存
static HiAppEvent_Watcher* systemEventWatcherT = nullptr;

// 创建观察者
systemEventWatcherT = OH_HiAppEvent_CreateWatcher("AppCrashWatcherT");

// 设置过滤条件
OH_HiAppEvent_SetAppEventFilter(systemEventWatcherT, DOMAIN_OS, 0, names, namesLen);

// 设置onTrigger回调
OH_HiAppEvent_SetWatcherOnTrigger(systemEventWatcherT, OnTriggerCrash);

// 设置触发条件(新增事件数量为1时触发回调)
OH_HiAppEvent_SetTriggerCondition(systemEventWatcherT, 1, 0, 0);
```

### 步骤4: 配置崩溃事件采集参数

**示例代码(可选配置)**:
```cpp
// 创建配置对象
HiAppEvent_Config* config = OH_HiAppEvent_CreateConfig();
if (config == nullptr) {
    OH_LOG_ERROR(LOG_APP, "Failed to create config");
    return;
}

// 设置配置参数
// 开启寄存器扩展内存打印
OH_HiAppEvent_SetConfigItem(config, OH_APP_CRASH_PARAM_EXTEND_PC_LR_PRINTING, "true");

// 设置日志截断大小为2MB
OH_HiAppEvent_SetConfigItem(config, OH_APP_CRASH_PARAM_LOG_FILE_CUTOFF_SZ_BYTES, "2097152");

// 开启简化VMA映射信息打印
OH_HiAppEvent_SetConfigItem(config, OH_APP_CRASH_PARAM_SIMPLIFY_VMA_PRINTING, "true");

// 开启拼接应用日志
OH_HiAppEvent_SetConfigItem(config, OH_APP_CRASH_PARAM_MERGE_CPPCRASH_APP_LOG, "true");

// Native崩溃场景,使能minidump
OH_HiAppEvent_SetConfigItem(config, OH_APP_CRASH_PARAM_COLLECT_MINIDUMP, "true");

// 应用配置到EVENT_APP_CRASH事件
int ret = OH_HiAppEvent_SetEventConfig(EVENT_APP_CRASH, config);
if (ret == HIAPPEVENT_SUCCESS) {
    OH_LOG_INFO(LOG_APP, "Successfully set APP_CRASH event configurations.");
} else {
    OH_LOG_ERROR(LOG_APP, "Failed to set event config: %{public}d", ret);
}

// 销毁配置对象
OH_HiAppEvent_DestroyConfig(config);
```

### 步骤5: 添加观察者并开始监听

**示例代码**:
```cpp
// 使观察者开始监听订阅的事件
ret = OH_HiAppEvent_AddWatcher(systemEventWatcherR);
if (ret != 0) {
    OH_LOG_ERROR(LOG_APP, "Failed to add watcher: %{public}d", ret);
    OH_HiAppEvent_DestroyWatcher(systemEventWatcherR);
    systemEventWatcherR = nullptr;
    return;
}

OH_LOG_INFO(LOG_APP, "Watcher added successfully, start monitoring crash events");
```

### 步骤6: 错误处理

**错误码处理示例**:
```cpp
// 错误处理代码
if (ret == -5) {
    OH_LOG_ERROR(LOG_APP, "Watcher is null pointer");
} else if (ret == -1) {
    OH_LOG_ERROR(LOG_APP, "Invalid event names parameter");
} else if (ret == -4) {
    OH_LOG_ERROR(LOG_APP, "Invalid domain parameter");
} else if (ret == HIAPPEVENT_EVENT_CONFIG_IS_NULL) {
    OH_LOG_ERROR(LOG_APP, "Event config is null");
} else if (ret == HIAPPEVENT_INVALID_PARAM_VALUE) {
    OH_LOG_ERROR(LOG_APP, "Invalid config parameter value");
} else if (ret == HIAPPEVENT_OPERATE_FAILED) {
    OH_LOG_ERROR(LOG_APP, "Operation failed");
} else {
    OH_LOG_ERROR(LOG_APP, "Unknown error: %{public}d", ret);
}
```

### 步骤7: 移除并销毁观察者

**示例代码**:
```cpp
// 移除观察者(停止监听)
int ret = OH_HiAppEvent_RemoveWatcher(systemEventWatcherR);
if (ret != 0) {
    OH_LOG_ERROR(LOG_APP, "Failed to remove watcher: %{public}d", ret);
}

// 销毁观察者(释放内存)
OH_HiAppEvent_DestroyWatcher(systemEventWatcherR);
systemEventWatcherR = nullptr; // 置空指针防止内存泄漏

OH_LOG_INFO(LOG_APP, "Watcher destroyed successfully");
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 0 | 操作成功 | 无需处理 |
| -1 | names参数异常(非法的事件名称) | 检查事件名称是否为EVENT_APP_CRASH |
| -4 | domain参数异常(非法的事件领域) | 检查事件领域是否为DOMAIN_OS |
| -5 | watcher入参空指针 | 检查观察者指针是否有效,是否已创建 |
| -6 | 还未调用OH_HiAppEvent_AddWatcher,操作顺序有误 | 先调用AddWatcher后再调用TakeWatcherData |
| HIAPPEVENT_SUCCESS(0) | 配置设置成功 | 无需处理 |
| HIAPPEVENT_INVALID_PARAM_VALUE_LENGTH(4) | 参数值长度无效 | 检查配置参数值长度 |
| HIAPPEVENT_PROCESSOR_IS_NULL(-7) | 事件处理者为空 | 检查处理者指针 |
| HIAPPEVENT_PROCESSOR_NOT_FOUND(-8) | 事件处理者不存在 | 检查处理者是否已创建 |
| HIAPPEVENT_INVALID_PARAM_VALUE(-9) | 参数值无效 | 检查配置参数值格式 |
| HIAPPEVENT_EVENT_CONFIG_IS_NULL(-10) | 事件配置为空 | 检查配置对象是否已创建 |
| HIAPPEVENT_OPERATE_FAILED(-100) | 操作失败 | 检查API调用顺序和参数 |
| HIAPPEVENT_INVALID_UID(-200) | 无效的用户标识 | 检查用户权限 |

## 编译和修复问题

### 依赖声明

**CMakeLists.txt配置**:
```cmake
# 添加源文件和动态库
add_library(entry SHARED napi_init.cpp)

# 新增动态库依赖libhiappevent_ndk.z.so和libhilog_ndk.z.so(日志输出)
target_link_libraries(entry PUBLIC 
    libace_napi.z.so 
    libhilog_ndk.z.so 
    libhiappevent_ndk.z.so
)

# 如果需要解析JSON参数,添加jsoncpp库依赖
set(GZ_FILE "${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/jsoncpp/src/jsoncpp-1.9.6.tar.gz")
set(DEST_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../../../build")
execute_process(COMMAND ${CMAKE_COMMAND} -E make_directory ${DEST_DIR})
execute_process(COMMAND tar -xzf ${GZ_FILE} -C ${DEST_DIR} WORKING_DIRECTORY ${DEST_DIR})

target_link_libraries(entry PRIVATE 
    ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/jsoncpp/${OHOS_ARCH}/lib/libjsoncpp.so
)
target_include_directories(entry PRIVATE 
    ${DEST_DIR}/jsoncpp-1.9.6/include/json
)
```

**源文件导入**:
```cpp
#include "napi/native_api.h"
#include "hiappevent/hiappevent.h"
#include "hiappevent/hiappevent_param.h"
#include "hilog/log.h"
#include "../../../build/jsoncpp-1.9.6/include/json/json.h" // jsoncpp库
```

### 环境要求

- HarmonyOS API version: 12及以上
- 开发环境: DevEco Studio
- 系统能力: SystemCapability.HiviewDFX.HiAppEvent
- 依赖库版本: libhiappevent_ndk.z.so, libhilog_ndk.z.so

### 常见编译问题

**问题1: 找不到hiappevent.h头文件**
```
fatal error: 'hiappevent/hiappevent.h' file not found
```
**解决方法**: 检查HarmonyOS SDK是否正确安装,API version是否满足12及以上要求

**问题2: 链接libhiappevent_ndk.z.so失败**
```
undefined reference to 'OH_HiAppEvent_CreateWatcher'
```
**解决方法**: 在CMakeLists.txt中添加动态库依赖: `target_link_libraries(entry PUBLIC libhiappevent_ndk.z.so)`

**问题3: jsoncpp库链接失败**
```
undefined reference to 'Json::Reader::parse'
```
**解决方法**: 下载jsoncpp源码并正确配置CMakeLists.txt,参考示例工程HiAppEvent示例工程EventSub

**问题4: NAPI接口注册失败**
```
TypeError: testNapi.registerWatcherCrashEvent is not a function
```
**解决方法**: 检查napi_init.cpp中的Init函数是否正确注册了ArkTS接口

## 常见问题与解决方法

### Q1: 崩溃事件未触发回调

**原因**: 
- 观察者未在应用启动时添加
- 未正确设置过滤条件和回调函数
- 应用崩溃时观察者已被移除或销毁

**解决方法**:
- 在EntryAbility.onCreate()中注册观察者
- 检查SetAppEventFilter是否设置DOMAIN_OS和EVENT_APP_CRASH
- 检查SetWatcherOnReceive或SetWatcherOnTrigger是否设置回调
- 确保应用崩溃前观察者处于监听状态

### Q2: 回调中的指针使用错误

**原因**: 回调中的指针生命周期仅限于回调函数内,回调结束后指针失效

**解决方法**:
- 在回调函数内对指针指向的内容进行深拷贝
- 不要在回调函数外直接使用回调中的指针
- 如需缓存事件信息,复制JSON字符串到本地变量

### Q3: NativeCrash崩溃事件回调延迟约2秒

**原因**: NativeCrash采取进程外采集故障信息,需要时间采集和处理

**解决方法**:
- 接受NativeCrash的平均耗时约2秒的特性
- 故障信息采集完成后会异步上报,不阻塞当前业务
- 调整业务逻辑以适应延迟上报的特性

### Q4: 应用崩溃后未立即退出,回调触发时机异常

**原因**: 
- 应用主动捕获崩溃异常但未主动退出
- 异常处理耗时过长导致应用退出延迟

**解决方法**:
- 在异常处理中主动调用exit()退出应用
- 减少异常处理逻辑的耗时操作
- 使用errorManager.on或崩溃信号处理函数时注意退出时机

### Q5: 订阅崩溃事件后无法获取崩溃日志

**原因**: 
- 未开启日志拼接配置(OH_APP_CRASH_PARAM_MERGE_CPPCRASH_APP_LOG)
- 日志截断大小设置过小
- external_log路径不存在

**解决方法**:
- 调用OH_HiAppEvent_SetConfigItem开启日志拼接配置
- 设置合理的日志截断大小(如2MB)
- 检查/data/storage/el2/log/目录权限

### Q6: 多次订阅同名观察者导致前一次订阅失效

**原因**: OH_HiAppEvent_AddWatcher传入的名称name是唯一的,相同name会覆盖前一次订阅

**解决方法**:
- 使用不同的观察者名称(如"AppCrashWatcher1"、"AppCrashWatcher2")
- 在重新订阅前先移除并销毁旧的观察者
- 检查观察者名称是否唯一

## 输出结果报告

执行完成后输出以下信息:

```json
{
  "status": "success",
  "watcherName": "AppCrashWatcherR",
  "eventType": "EVENT_APP_CRASH",
  "eventDomain": "DOMAIN_OS",
  "crashType": "JsError或NativeCrash",
  "crashTime": "1503045716054",
  "crashParams": {
    "time": "1503045716054",
    "crash_type": "JsError",
    "foreground": true,
    "bundle_name": "com.samples.eventsub",
    "bundle_version": "1.0.0",
    "pid": 2610,
    "uid": 20010044,
    "uuid": "7c3b1579c8ca8629af3858f8145254c2867ee402dc16ee18034337aae258620b",
    "exception": {
      "message": "Unexpected Text in JSON: Empty Text",
      "name": "SyntaxError",
      "stack": "at anonymous (entry|entry|1.0.0|src/main/ets/pages/Index.ts:163:22)"
    },
    "hilog": ["..."],
    "memory": {
      "rss": 181964,
      "sys_avail_mem": 1230456,
      "sys_free_mem": 676940,
      "sys_total_mem": 2001932
    },
    "external_log": [
      "/data/storage/el2/log/hiappevent/APP_CRASH_1503045716408_2610.log",
      "/data/storage/el2/log/hiappevent/APP_CRASH_1503045716409_2610.dmp"
    ],
    "log_over_limit": false
  },
  "apiUsed": [
    "OH_HiAppEvent_CreateWatcher",
    "OH_HiAppEvent_SetAppEventFilter",
    "OH_HiAppEvent_SetWatcherOnReceive",
    "OH_HiAppEvent_AddWatcher",
    "OH_HiAppEvent_CreateConfig",
    "OH_HiAppEvent_SetConfigItem",
    "OH_HiAppEvent_SetEventConfig",
    "OH_HiAppEvent_DestroyConfig"
  ]
}
```

## 参考文档

- [订阅崩溃事件(C/C++)开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/hiappevent-watcher-crash-events-ndk)
- [HiAppEvent C API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/capi-hiappevent-h)
- [HiAppEvent模块说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/capi-hiappevent)
- [使用FaultLogExtensionAbility订阅事件](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/fault-log-extension-app-events-arkts)
- [崩溃信号处理](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/cppcrash-guidelines)
- [errorManager.on API](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-app-ability-errormanager)

## 完整示例代码

- [C++完整示例(onReceive模式)](assets/example_crash_event_receiver.cpp)
- [C++完整示例(onTrigger模式)](assets/example_crash_event_trigger.cpp)
- [CMakeLists.txt配置示例](assets/CMakeLists.txt)
- [NAPI接口注册示例](assets/napi_init.cpp)
- [ArkTS接口定义示例](assets/index.d.ts)
- [EntryAbility调用示例](assets/EntryAbility.ets)

## 测试用例

### 正向测试用例

- [测试订阅JsError崩溃事件](tests/test_jserror_subscription.cpp): 正常订阅并触发JsError崩溃事件
- [测试订阅NativeCrash崩溃事件](tests/test_nativecrash_subscription.cpp): 正常订阅并触发NativeCrash崩溃事件
- [测试配置崩溃事件采集参数](tests/test_crash_config.cpp): 正常配置寄存器扩展内存打印等参数
- [测试解析崩溃事件参数](tests/test_parse_crash_params.cpp): 正常解析崩溃事件的JSON参数

### 边界测试用例

- [测试观察者名称长度限制](tests/test_watcher_name_length.cpp): 测试观察者名称256字符限制
- [测试日志截断大小边界](tests/test_log_cutoff_size.cpp): 测试日志截断大小2MB边界
- [测试多次订阅同名观察者](tests/test_duplicate_watcher.cpp): 测试同名观察者覆盖前一次订阅
- [测试回调触发条件边界](tests/test_trigger_condition.cpp): 测试事件数量和大小触发条件

### 异常测试用例

- [测试空指针观察者](tests/test_null_watcher.cpp): 测试传入nullptr观察者指针
- [测试非法事件名称](tests/test_invalid_event_name.cpp): 测试传入非法的事件名称
- [测试非法事件领域](tests/test_invalid_domain.cpp): 测试传入非法的事件领域
- [测试回调函数外使用指针](tests/test_pointer_outside_callback.cpp): 测试在回调外使用回调中的指针
- [测试销毁未移除的观察者](tests/test_destroy_without_remove.cpp): 测试直接销毁未移除的观察者
- [测试配置参数值无效](tests/test_invalid_config_value.cpp): 测试传入无效的配置参数值