---
name: hmos-performance-analysis-kit-scroll-jank-watcher
description: 使用C/C++ API订阅滑动丢帧事件，支持onReceive和onTrigger两种观察者模式，最大支持200MB事件文件存储，适用于性能监控、滑动卡顿检测场景
---

# 订阅滑动丢帧事件（C/C++）技能

## 功能描述

本技能实现使用HiAppEvent提供的C/C++接口订阅系统滑动丢帧事件（SCROLL_JANK）。当应用发生滑动卡顿超过50ms时，系统会自动触发该事件，开发者可以通过两种观察者模式（onReceive和onTrigger）接收事件数据并进行处理。事件包含完整的性能指标信息，如丢帧数量、帧渲染时间、最大连续丢帧数等，帮助开发者定位和优化滑动性能问题。

**核心能力**：
- 实时监听系统滑动丢帧事件
- 支持两种观察者回调模式（实时接收onReceive和批量触发onTrigger）
- 提供完整的性能指标数据（丢帧数、渲染时间、连续丢帧等）
- 支持自定义事件过滤和处理逻辑

## 使用场景

### 触发词
- "订阅滑动丢帧事件"
- "监听滑动卡顿"
- "检测滑动丢帧"
- "滑动性能监控"
- "SCROLL_JANK事件订阅"
- "HiAppEvent滑动事件"

### 能做
- 创建并配置滑动丢帧事件观察者
- 实现onReceive回调实时接收丢帧事件
- 实现onTrigger回调批量处理丢帧事件
- 解析事件参数获取性能指标数据
- 自定义事件过滤和处理逻辑
- 注册和移除事件观察者

### 绝不做
- 不用于订阅非滑动丢帧事件（如崩溃、冻屏等）
- 不直接修改系统事件参数结构
- 不在回调函数外直接使用回调指针数据（需深拷贝）
- 不创建重复名称的观察者（后创建会覆盖前一个）

### 补充
- 滑动丢帧事件触发条件：单次滑动操作发生超过50ms卡顿，间隔5~35秒
- 需在Native C++工程中使用，依赖libhiappevent_ndk.z.so库
- 需要额外依赖jsoncpp库用于解析事件JSON参数
- API起始版本：API Version 12

## 调用规范和规则

### 输入约束
- 观察者名称：字符串类型，长度不超过32字符，必须唯一
- 事件领域：固定为"DOMAIN_OS"（OS作用域）
- 事件名称：固定为"EVENT_SCROLL_JANK"（SCROLL_JANK）
- 事件类型过滤：建议设置为0或15（支持所有类型）
- 触发条件参数：row、size、timeOut需至少设置一个大于0

### 执行约束
- 最大耗时：OH_HiAppEvent_AddWatcher涉及I/O操作，性能敏感场景应考虑在子线程调用
- 最大迭代次数：观察者回调循环次数取决于事件组数量（groupLen）
- API调用频次：无硬限制，但相同名称的观察者会被覆盖
- 内存管理：创建的观察者必须调用OH_HiAppEvent_DestroyWatcher销毁

### 内容约束
- 禁止生成：禁止生成包含高危函数（eval、exec、system）的代码
- 禁止操作：禁止在回调函数外直接使用回调指针数据（生命周期仅限回调函数内）
- 数据限制：事件参数字符串最大长度8*1024字符，参数个数最大32个

### 降级约束
- 观察者创建失败：返回nullptr，需检查name参数有效性
- 事件订阅失败：返回错误码，需根据错误码进行对应处理
- JSON解析失败：需捕获异常并记录日志，不影响后续事件处理
- 内存不足：优先销毁旧观察者释放内存，再重新创建

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 确认使用Native C++工程
2. 确认已下载并导入jsoncpp库（json.h、json-forwards.h、jsoncpp.cpp）
3. 确认工程目录结构正确（json头文件在cpp/json/目录）
4. 确认已添加必要的动态库依赖（libhiappevent_ndk.z.so、libhilog_ndk.z.so）

**参数准备**：
```cpp
// C++示例 - 导入必要头文件
#include "napi/native_api.h"
#include "json/json.h"
#include "hilog/log.h"
#include "hiappevent/hiappevent.h"
#include "hiappevent/hiappevent_event.h"

#undef LOG_TAG
#define LOG_TAG "ScrollJankWatcher"

// 定义观察者指针缓存变量
static HiAppEvent_Watcher *scrollJankWatcherR = nullptr;
static HiAppEvent_Watcher *scrollJankWatcherT = nullptr;
```

### 步骤2：实现onReceive回调函数

**示例代码**：
```cpp
// 定义onReceive类型观察者的回调函数
static void OnReceive(const char *domain, const struct HiAppEvent_AppEventGroup *appEventGroups, uint32_t groupLen)
{
    for (int i = 0; i < groupLen; ++i) {
        for (int j = 0; j < appEventGroups[i].infoLen; ++j) {
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.WatcherType=OnReceive");
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.domain=%{public}s", appEventGroups[i].appEventInfos[j].domain);
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.name=%{public}s", appEventGroups[i].appEventInfos[j].name);
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.eventType=%{public}d", appEventGroups[i].appEventInfos[j].type);
            
            // 过滤滑动丢帧事件
            if (strcmp(appEventGroups[i].appEventInfos[j].domain, DOMAIN_OS) != 0 || 
                strcmp(appEventGroups[i].appEventInfos[j].name, EVENT_SCROLL_JANK) != 0) {
                continue;
            }
            
            // 解析事件参数
            Json::Value params;
            Json::Reader reader(Json::Features::strictMode());
            Json::FastWriter writer;
            
            if (reader.parse(appEventGroups[i].appEventInfos[j].params, params)) {
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.time=%{public}lld", params["time"].asInt64());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.bundle_version=%{public}s", params["bundle_version"].asString().c_str());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.bundle_name=%{public}s", params["bundle_name"].asString().c_str());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.process_name=%{public}s", params["process_name"].asString().c_str());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.ability_name=%{public}s", params["ability_name"].asString().c_str());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.begin_time=%{public}lld", params["begin_time"].asInt64());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.duration=%{public}d", params["duration"].asInt());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.total_app_frames=%{public}d", params["total_app_frames"].asInt());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.total_app_missed_frames=%{public}d", params["total_app_missed_frames"].asInt());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.max_app_frametime=%{public}d", params["max_app_frametime"].asInt());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.max_app_seq_frames=%{public}d", params["max_app_seq_frames"].asInt());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.total_render_frames=%{public}d", params["total_render_frames"].asInt());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.total_render_missed_frames=%{public}d", params["total_render_missed_frames"].asInt());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.max_render_frametime=%{public}d", params["max_render_frametime"].asInt());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.max_render_seq_frames=%{public}d", params["max_render_seq_frames"].asInt());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.external_log=%{public}s", writer.write(params["external_log"]).c_str());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.log_over_limit=%{public}d", params["log_over_limit"].asBool());
            }
        }
    }
}
```

### 步骤3：创建并配置onReceive观察者

**示例代码**：
```cpp
static napi_value RegisterWatcherReceive(napi_env env, napi_callback_info info)
{
    // 创建观察者（名称必须唯一）
    scrollJankWatcherR = OH_HiAppEvent_CreateWatcher("ScrollJankWatcherR");
    if (scrollJankWatcherR == nullptr) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to create watcher");
        return {};
    }
    
    // 设置订阅的事件过滤器
    const char *names[] = {EVENT_SCROLL_JANK};  // 滑动丢帧事件名称
    int result = OH_HiAppEvent_SetAppEventFilter(scrollJankWatcherR, DOMAIN_OS, 0, names, 1);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to set event filter: %{public}d", result);
        OH_HiAppEvent_DestroyWatcher(scrollJankWatcherR);
        scrollJankWatcherR = nullptr;
        return {};
    }
    
    // 设置回调函数
    result = OH_HiAppEvent_SetWatcherOnReceive(scrollJankWatcherR, OnReceive);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to set onReceive callback: %{public}d", result);
        OH_HiAppEvent_DestroyWatcher(scrollJankWatcherR);
        scrollJankWatcherR = nullptr;
        return {};
    }
    
    // 开始监听事件
    result = OH_HiAppEvent_AddWatcher(scrollJankWatcherR);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to add watcher: %{public}d", result);
        OH_HiAppEvent_DestroyWatcher(scrollJankWatcherR);
        scrollJankWatcherR = nullptr;
        return {};
    }
    
    OH_LOG_INFO(LogType::LOG_APP, "Scroll jank watcher registered successfully");
    return {};
}
```

### 步骤4：实现onTrigger回调函数

**示例代码**：
```cpp
// OnTake回调：处理获取到的保存事件
static void OnTake(const char *const *events, uint32_t eventLen)
{
    Json::Reader reader(Json::Features::strictMode());
    Json::FastWriter writer;
    
    for (int i = 0; i < eventLen; ++i) {
        Json::Value eventInfo;
        if (reader.parse(events[i], eventInfo)) {
            auto domain = eventInfo["domain_"].asString();
            auto name = eventInfo["name_"].asString();
            auto type = eventInfo["type_"].asInt();
            
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.WatcherType=OnTrigger");
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.domain=%{public}s", domain.c_str());
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.name=%{public}s", name.c_str());
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.eventType=%{public}d", type);
            
            if (domain == DOMAIN_OS && name == EVENT_SCROLL_JANK) {
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.time=%{public}lld", eventInfo["time"].asInt64());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.bundle_version=%{public}s", eventInfo["bundle_version"].asString().c_str());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.bundle_name=%{public}s", eventInfo["bundle_name"].asString().c_str());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.process_name=%{public}s", eventInfo["process_name"].asString().c_str());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.ability_name=%{public}s", eventInfo["ability_name"].asString().c_str());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.begin_time=%{public}lld", eventInfo["begin_time"].asInt64());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.duration=%{public}d", eventInfo["duration"].asInt());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.total_app_frames=%{public}d", eventInfo["total_app_frames"].asInt());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.total_app_missed_frames=%{public}d", eventInfo["total_app_missed_frames"].asInt());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.max_app_frametime=%{public}d", eventInfo["max_app_frametime"].asInt());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.max_app_seq_frames=%{public}d", eventInfo["max_app_seq_frames"].asInt());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.total_render_frames=%{public}d", eventInfo["total_render_frames"].asInt());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.total_render_missed_frames=%{public}d", eventInfo["total_render_missed_frames"].asInt());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.max_render_frametime=%{public}d", eventInfo["max_render_frametime"].asInt());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.max_render_seq_frames=%{public}d", eventInfo["max_render_seq_frames"].asInt());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.external_log=%{public}s", writer.write(eventInfo["external_log"]).c_str());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.log_over_limit=%{public}d", eventInfo["log_over_limit"].asBool());
            }
        }
    }
}

// OnTrigger回调：满足触发条件时调用
static void OnTrigger(int row, int size)
{
    // 获取指定数量的已接收事件
    OH_HiAppEvent_TakeWatcherData(scrollJankWatcherT, row, OnTake);
}

static napi_value RegisterWatcherTrigger(napi_env env, napi_callback_info info)
{
    // 创建观察者
    scrollJankWatcherT = OH_HiAppEvent_CreateWatcher("ScrollJankWatcherT");
    if (scrollJankWatcherT == nullptr) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to create watcher");
        return {};
    }
    
    // 设置事件过滤器
    const char *names[] = {EVENT_SCROLL_JANK};
    int result = OH_HiAppEvent_SetAppEventFilter(scrollJankWatcherT, DOMAIN_OS, 0, names, 1);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to set event filter: %{public}d", result);
        OH_HiAppEvent_DestroyWatcher(scrollJankWatcherT);
        scrollJankWatcherT = nullptr;
        return {};
    }
    
    // 设置onTrigger回调
    result = OH_HiAppEvent_SetWatcherOnTrigger(scrollJankWatcherT, OnTrigger);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to set onTrigger callback: %{public}d", result);
        OH_HiAppEvent_DestroyWatcher(scrollJankWatcherT);
        scrollJankWatcherT = nullptr;
        return {};
    }
    
    // 设置触发条件：新增1个事件时触发回调
    result = OH_HiAppEvent_SetTriggerCondition(scrollJankWatcherT, 1, 0, 0);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to set trigger condition: %{public}d", result);
        OH_HiAppEvent_DestroyWatcher(scrollJankWatcherT);
        scrollJankWatcherT = nullptr;
        return {};
    }
    
    // 开始监听
    result = OH_HiAppEvent_AddWatcher(scrollJankWatcherT);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to add watcher: %{public}d", result);
        OH_HiAppEvent_DestroyWatcher(scrollJankWatcherT);
        scrollJankWatcherT = nullptr;
        return {};
    }
    
    OH_LOG_INFO(LogType::LOG_APP, "Scroll jank trigger watcher registered successfully");
    return {};
}
```

### 步骤5：注册为ArkTS接口

**示例代码**：
```cpp
// napi_init.cpp
static napi_value Init(napi_env env, napi_value exports)
{
    napi_property_descriptor desc[] = {
        { "registerWatcherReceive", nullptr, RegisterWatcherReceive, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "registerWatcherTrigger", nullptr, RegisterWatcherTrigger, nullptr, nullptr, nullptr, napi_default, nullptr },
    };
    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    return exports;
}
```

**ArkTS接口定义**：
```typescript
// index.d.ts
export const registerWatcherReceive: () => void;
export const registerWatcherTrigger: () => void;
```

### 步骤6：在应用中调用

**示例代码**：
```typescript
// EntryAbility.ets
import testNapi from 'libentry.so';

export default class EntryAbility {
    onCreate() {
        // 启动时注册滑动丢帧事件观察者
        testNapi.registerWatcherReceive();
        testNapi.registerWatcherTrigger();
    }
}
```

### 步骤7：错误处理

```cpp
// 错误处理代码示例
static napi_value SafeRegisterWatcher(napi_env env, napi_callback_info info)
{
    HiAppEvent_Watcher* watcher = OH_HiAppEvent_CreateWatcher("TestWatcher");
    
    if (watcher == nullptr) {
        OH_LOG_ERROR(LogType::LOG_APP, "Error: Watcher creation failed - name parameter invalid");
        return {};
    }
    
    const char *names[] = {EVENT_SCROLL_JANK};
    int result = OH_HiAppEvent_SetAppEventFilter(watcher, DOMAIN_OS, 0, names, 1);
    
    switch (result) {
        case -1:
            OH_LOG_ERROR(LogType::LOG_APP, "Error: Invalid names parameter");
            break;
        case -4:
            OH_LOG_ERROR(LogType::LOG_APP, "Error: Invalid domain parameter");
            break;
        case -5:
            OH_LOG_ERROR(LogType::LOG_APP, "Error: Watcher is null pointer");
            break;
        case 0:
            OH_LOG_INFO(LogType::LOG_APP, "Filter set successfully");
            break;
        default:
            OH_LOG_ERROR(LogType::LOG_APP, "Unknown error: %{public}d", result);
            break;
    }
    
    if (result != 0) {
        OH_HiAppEvent_DestroyWatcher(watcher);
        return {};
    }
    
    // ...后续处理
    
    return {};
}
```

### 步骤8：降级处理

```cpp
// 降级处理：销毁旧观察者释放内存
static void CleanupOldWatcher(HiAppEvent_Watcher** oldWatcher)
{
    if (*oldWatcher != nullptr) {
        OH_HiAppEvent_RemoveWatcher(*oldWatcher);
        OH_HiAppEvent_DestroyWatcher(*oldWatcher);
        *oldWatcher = nullptr;
        OH_LOG_INFO(LogType::LOG_APP, "Old watcher destroyed successfully");
    }
}

static napi_value ReRegisterWatcher(napi_env env, napi_callback_info info)
{
    // 先清理旧观察者
    CleanupOldWatcher(&scrollJankWatcherR);
    
    // 重新创建观察者
    scrollJankWatcherR = OH_HiAppEvent_CreateWatcher("ScrollJankWatcherR");
    if (scrollJankWatcherR == nullptr) {
        OH_LOG_ERROR(LogType::LOG_APP, "Fallback: Failed to create new watcher, old watcher already destroyed");
        return {};
    }
    
    // ...后续配置
    
    return {};
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 0 | 操作成功 | 正常流程继续执行 |
| -1 | names参数异常（事件名称数组无效） | 检查事件名称是否符合规范（首字符字母或$，中间字符数字/字母/下划线，结尾字符数字或字母，长度≤48） |
| -4 | domain参数异常（事件领域无效） | 检查domain参数，滑动丢帧事件应使用DOMAIN_OS（"OS"） |
| -5 | watcher空指针 | 检查OH_HiAppEvent_CreateWatcher返回值是否为nullptr，确认name参数有效 |
| -6 | 操作顺序有误（未调用OH_HiAppEvent_AddWatcher） | 先调用OH_HiAppEvent_AddWatcher添加观察者，再调用OH_HiAppEvent_TakeWatcherData |
| HIAPPEVENT_INVALID_PARAM_VALUE = -9 | 参数值无效 | 检查参数值类型和范围是否符合规范 |
| HIAPPEVENT_EVENT_CONFIG_IS_NULL = -10 | 事件配置为空 | 检查配置对象是否正确创建 |
| HIAPPEVENT_OPERATE_FAILED = -100 | 操作失败 | 查看详细日志，检查系统状态和权限 |
| HIAPPEVENT_INVALID_UID = -200 | 无效的用户标识 | 检查应用权限和用户身份 |

## 编译和修复问题

### 依赖声明

**CMakeLists.txt配置**：
```cmake
# 添加jsoncpp源文件（用于解析事件JSON参数）
add_library(entry SHARED napi_init.cpp jsoncpp.cpp)

# 添加动态库依赖
target_link_libraries(entry PUBLIC 
    libace_napi.z.so 
    libhilog_ndk.z.so 
    libhiappevent_ndk.z.so
)
```

**package.json依赖**：
```json
{
  "dependencies": {
    "jsoncpp": "1.9.5"
  }
}
```

### 环境要求
- HarmonyOS API Version：≥ 12
- 开发工具：DevEco Studio ≥ 3.1
- 编译工具：cmake ≥ 3.10
- C++标准：C++17及以上

### 常见编译问题

**问题1：找不到json头文件**
```
error: 'json/json.h' file not found
```
**解决方法**：
1. 从https://github.com/open-source-parsers/jsoncpp下载源码
2. 按README中Amalgamated source步骤生成json.h、json-forwards.h、jsoncpp.cpp
3. 将文件放在cpp/json/目录下

**问题2：libhiappevent_ndk.z.so链接失败**
```
error: undefined reference to 'OH_HiAppEvent_CreateWatcher'
```
**解决方法**：
在CMakeLists.txt中添加libhiappevent_ndk.z.so依赖：
```cmake
target_link_libraries(entry PUBLIC libhiappevent_ndk.z.so)
```

**问题3：观察者创建失败返回nullptr**
```
scrollJankWatcherR = OH_HiAppEvent_CreateWatcher("TestWatcher"); // 返回nullptr
```
**解决方法**：
检查观察者名称是否符合规范：
- 长度不超过32字符
- 不能包含特殊字符
- 必须唯一（相同名称会被覆盖）

**问题4：回调函数中使用指针导致崩溃**
```
Access violation in OnReceive callback
```
**解决方法**：
回调中的指针生命周期仅限于回调函数内，切勿在函数外直接使用。若需缓存数据，必须进行深拷贝：
```cpp
// 错误示例：直接缓存指针
static const char* cachedParams; // ❌危险
cachedParams = appEventGroups[i].appEventInfos[j].params;

// 正确示例：深拷贝数据
static std::string cachedParams; // ✅安全
cachedParams = std::string(appEventGroups[i].appEventInfos[j].params);
```

## 常见问题与解决方法

### Q1：滑动丢帧事件不触发？
**原因**：
- 应用未发生超过50ms的滑动卡顿
- 事件触发间隔为5~35秒，未满足间隔条件
- 观察者未成功添加或被覆盖

**解决方法**：
- 在List组件的onScrollIndex中添加耗时操作模拟卡顿：
```typescript
.onScrollIndex((firstIndex: number) => {
  let i = 1;
  while (i < 20000) {
    console.info("do something");
    i++;
  }
})
```
- 检查OH_HiAppEvent_AddWatcher返回值是否为0
- 确认观察者名称唯一，避免被后创建的同名观察者覆盖

### Q2：JSON解析失败导致参数读取错误？
**原因**：
- eventInfo.params字符串格式不符合JSON规范
- jsoncpp库版本不兼容

**解决方法**：
```cpp
Json::Reader reader(Json::Features::strictMode());
Json::Value params;
if (!reader.parse(appEventGroups[i].appEventInfos[j].params, params)) {
    OH_LOG_ERROR(LogType::LOG_APP, "JSON parse failed: %{public}s", 
                 reader.getFormattedErrorMessages().c_str());
    // 降级处理：记录原始参数字符串
    OH_LOG_INFO(LogType::LOG_APP, "Raw params: %{public}s", 
                appEventGroups[i].appEventInfos[j].params);
    continue;
}
```

### Q3：观察者内存泄漏？
**原因**：
- 创建观察者后未调用OH_HiAppEvent_DestroyWatcher销毁
- 移除观察者后未销毁，观察者仍常驻内存

**解决方法**：
```cpp
// 正确的清理流程
static void CleanupWatcher()
{
    if (scrollJankWatcherR != nullptr) {
        // 1. 移除观察者（停止监听）
        OH_HiAppEvent_RemoveWatcher(scrollJankWatcherR);
        // 2. 销毁观察者（释放内存）
        OH_HiAppEvent_DestroyWatcher(scrollJankWatcherR);
        // 3. 置空指针
        scrollJankWatcherR = nullptr;
    }
}
```

### Q4：性能敏感场景下订阅接口影响性能？
**原因**：
- OH_HiAppEvent_AddWatcher涉及I/O操作
- 在主线程调用可能阻塞UI渲染

**解决方法**：
在子线程调用订阅接口：
```cpp
// 使用std::thread在子线程注册观察者
std::thread watcherThread([]() {
    RegisterWatcherReceive(nullptr, nullptr);
});
watcherThread.detach();
```

### Q5：获取到的事件数据如何持久化存储？
**原因**：
回调函数中的指针数据生命周期短暂，需要深拷贝并持久化

**解决方法**：
```cpp
static std::vector<std::string> savedEvents;

static void OnReceive(const char *domain, const struct HiAppEvent_AppEventGroup *appEventGroups, uint32_t groupLen)
{
    for (int i = 0; i < groupLen; ++i) {
        for (int j = 0; j < appEventGroups[i].infoLen; ++j) {
            // 深拷贝事件数据
            std::string eventParams(appEventGroups[i].appEventInfos[j].params);
            savedEvents.push_back(eventParams);
        }
    }
}
```

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "watcherRegistered": true,
  "eventDomain": "OS",
  "eventName": "SCROLL_JANK",
  "apiUsed": [
    "OH_HiAppEvent_CreateWatcher",
    "OH_HiAppEvent_SetAppEventFilter",
    "OH_HiAppEvent_SetWatcherOnReceive",
    "OH_HiAppEvent_SetWatcherOnTrigger",
    "OH_HiAppEvent_SetTriggerCondition",
    "OH_HiAppEvent_AddWatcher",
    "OH_HiAppEvent_TakeWatcherData"
  ],
  "performanceMetrics": {
    "total_app_frames": "25",
    "total_app_missed_frames": "47",
    "max_app_frametime": "67ms",
    "max_app_seq_frames": "38",
    "duration": "984ms"
  },
  "dependencies": [
    "libhiappevent_ndk.z.so",
    "libhilog_ndk.z.so",
    "jsoncpp"
  ]
}
```

## 参考文档

- [API开发指南 - 订阅滑动丢帧事件（C/C++）](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/hiappevent-watcher-scroll-jank-c)
- [API参考说明 - hiappevent.h](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/capi-hiappevent-h)
- [API参考说明 - hiappevent_event.h](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/capi-hiappevent-event-h)

## 完整示例代码

- [C++完整示例 - onReceive观察者](assets/scroll_jank_watcher_receive.cpp)
- [C++完整示例 - onTrigger观察者](assets/scroll_jank_watcher_trigger.cpp)
- [ArkTS调用示例](assets/entry_ability.ets)
- [CMakeLists配置示例](assets/CMakeLists.txt)
- [jsoncpp集成示例](assets/jsoncpp_integration.md)

## 测试用例

### 正向测试用例
- [正常订阅滑动丢帧事件](tests/test_positive_register.cpp)：验证观察者创建和事件订阅成功
- [接收真实丢帧事件](tests/test_positive_receive_event.cpp)：验证回调函数正确接收并解析事件数据
- [批量触发模式测试](tests/test_positive_trigger_mode.cpp)：验证onTrigger回调在满足条件时触发

### 边界测试用例
- [观察者名称长度测试](tests/test_boundary_watcher_name.cpp)：测试名称32字符上限
- [触发条件参数测试](tests/test_boundary_trigger_condition.cpp)：测试row、size、timeOut参数边界值
- [事件参数数量测试](tests/test_boundary_param_count.cpp)：测试最多32个参数限制

### 异常测试用例
- [观察者名称无效测试](tests/test_exception_invalid_name.cpp)：测试nullptr返回和错误处理
- [重复观察者覆盖测试](tests/test_exception_duplicate_watcher.cpp)：测试相同名称观察者的覆盖行为
- [回调函数指针误用测试](tests/test_exception_callback_pointer.cpp)：测试在回调外使用指针的错误处理
- [JSON解析失败测试](tests/test_exception_json_parse.cpp)：测试异常事件参数的降级处理