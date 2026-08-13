---
name: hmos-performance-analysis-kit-address-sanitizer-watcher
description: 订阅地址越界事件+支持Native C++代码内存错误检测+API version 12+、适用于调试数组越界、内存访问错误场景
---

# 订阅地址越界事件技能

## 功能描述

通过HiAppEvent订阅地址越界事件(ADDRESS_SANITIZER),实时监听Native C++代码中的内存访问错误。地址越界事件包括数组越界、堆栈溢出等内存安全问题,系统会自动捕获错误信息并提供详细的堆栈日志和页面切换日志。

**核心能力**:
- 订阅系统事件领域的ADDRESS_SANITIZER事件
- 实时接收地址越界事件的详细信息
- 获取错误类型、堆栈日志、页面切换日志等关键数据
- 支持配置页面切换日志开关(API version 24+)

**适用范围**:
- Native C++工程中的内存错误检测
- 数组越界写入/读取场景
- 堆栈缓冲区溢出场景
- 需要详细错误日志的调试场景

**限制条件**:
- 仅支持Native C++代码的内存错误检测
- 需在DevEco Studio中启用Address Sanitizer
- API version 12+开始支持ADDRESS_SANITIZER事件
- API version 24+开始支持页面切换日志配置

**典型场景**:
- 调试Native C++代码中的数组越界问题
- 检测内存访问错误并获取详细日志
- 分析应用崩溃原因和堆栈信息
- 性能分析和内存安全检查

## 使用场景

### 触发词
- "订阅地址越界事件"
- "监听ADDRESS_SANITIZER事件"
- "检测数组越界"
- "Native C++内存错误"
- "地址越界日志"
- "内存访问错误调试"

### 能做
- 订阅系统事件领域的ADDRESS_SANITIZER事件
- 实时接收地址越界事件的回调通知
- 获取事件的详细参数信息(错误类型、堆栈日志、页面切换日志)
- 配置页面切换日志开关(需要API version 24+)
- 移除事件观察者取消订阅

### 绝不做
- 不用于应用事件(非系统事件)的订阅
- 不用于其他系统事件的订阅(如崩溃事件、冻屏事件等)
- 不在回调函数中移除观察者(watcher移除会导致订阅失效)
- 不在主线程中调用耗时的I/O操作

### 补充
- 需要在DevEco Studio的Edit Configurations中启用Address Sanitizer
- 地址越界事件会导致应用崩溃,需要重新运行应用查看日志
- 页面切换日志功能需要API version 24+
- 观察者名称需要唯一,重复名称会覆盖之前的订阅

## 调用规范和规则

### 输入约束
- 观察者名称:首字符必须为字母,中间字符为数字/字母/下划线,结尾字符为数字/字母,长度不超过32字符
- 事件领域:必须使用hiAppEvent.domain.OS(系统事件领域)
- 事件名称:必须使用hiAppEvent.event.ADDRESS_SANITIZER常量
- 配置参数(API version 24+):pageSwitchLogEnable为boolean类型

### 执行约束
- 最大回调处理时间:建议不超过100ms(避免阻塞主线程)
- 日志处理:建议使用hilog输出关键信息
- 错误处理:必须捕获BusinessError异常
- API版本检查:配置页面切换日志前需检查deviceInfo.sdkApiVersion >= 24

### 内容约束
- 禁止生成:非系统事件领域的订阅代码
- 禁止使用高危函数:eval、exec等
- 禁止操作:在回调中移除观察者
- 必须包含:错误处理代码、API版本检查代码

### 降级约束
- API版本不足:提示用户当前API版本不支持该功能
- 配置失败:提示配置错误原因并继续订阅事件
- 观察者添加失败:检查名称格式和事件参数是否正确
- 回调未触发:检查事件是否正确触发和DevEco Studio配置

## 调用流程和步骤

### 步骤1:准备阶段

**前置校验**:
1. 检查API版本是否支持ADDRESS_SANITIZER事件(API version 12+)
2. 检查是否为Native C++工程
3. 检查DevEco Studio是否启用Address Sanitizer
4. 检查工程目录结构是否完整

**参数准备**:
```typescript
import { hiAppEvent, hilog } from '@kit.PerformanceAnalysisKit';
import { deviceInfo, BusinessError } from '@kit.BasicServicesKit';

// 观察者配置
const watcherConfig = {
  name: "watcher",  // 观察者名称
  appEventFilters: [
    {
      domain: hiAppEvent.domain.OS,
      names: [hiAppEvent.event.ADDRESS_SANITIZER]
    }
  ]
};
```

### 步骤2:配置页面切换日志(可选,API version 24+)

**示例代码**:
```typescript
if (deviceInfo.sdkApiVersion >= 24) {
  // 配置页面切换日志
  let switchLogPolicy: hiAppEvent.EventPolicy = {
    "addressSanitizerPolicy": {
      "pageSwitchLogEnable": true
    }
  };
  
  // 设置地址越界日志配置参数
  hiAppEvent.configEventPolicy(switchLogPolicy).then(() => {
    hilog.info(0x0000, 'testTag', `HiAppEvent success to config event policy.`);
  }).catch((err: BusinessError) => {
    hilog.error(0x0000, 'testTag', `HiAppEvent code: ${err.code}, message: ${err.message}`);
  });
}
```

### 步骤3:添加事件观察者订阅

**示例代码**:
```typescript
hiAppEvent.addWatcher({
  // 开发者可以自定义观察者名称,系统会使用名称来标识不同的观察者
  name: "watcher",
  // 开发者可以订阅感兴趣的系统事件,此处是订阅了地址越界事件
  appEventFilters: [
    {
      domain: hiAppEvent.domain.OS,
      names: [hiAppEvent.event.ADDRESS_SANITIZER]
    }
  ],
  // 开发者可以自行实现订阅系统事件回调函数,以便对订阅获取到的事件数据进行自定义处理
  onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
    hilog.info(0x0000, 'testTag', `HiAppEvent onReceive: domain=${domain}`);
    for (const eventGroup of appEventGroups) {
      // 开发者可以根据事件集合中的事件名称区分不同的系统事件
      hilog.info(0x0000, 'testTag', `HiAppEvent eventName=${eventGroup.name}`);
      for (const eventInfo of eventGroup.appEventInfos) {
        // 开发者可以对事件集合中的事件数据进行自定义处理,此处是将事件数据打印在日志中
        hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.domain=${eventInfo.domain}`);
        hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.name=${eventInfo.name}`);
        hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.eventType=${eventInfo.eventType}`);
        hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.time=${eventInfo.params['time']}`);
        hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.bundle_version=${eventInfo.params['bundle_version']}`);
        hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.bundle_name=${eventInfo.params['bundle_name']}`);
        hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.pid=${eventInfo.params['pid']}`);
        hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.uid=${eventInfo.params['uid']}`);
        hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.type=${eventInfo.params['type']}`);
        hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.external_log=${JSON.stringify(eventInfo.params['external_log'])}`);
        hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.log_over_limit=${eventInfo.params['log_over_limit']}`);
        // 开发者可以获取到地址越界事件的页面切换日志
        hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.page_switch_log=${JSON.stringify(eventInfo.params['page_switch_log'])}`);
      }
    }
  }
});
```

### 步骤4:构造地址越界错误(测试场景)

**Native C++代码示例(napi_init.cpp)**:
```cpp
#include "napi/native_api.h"

static napi_value Test(napi_env env, napi_callback_info info)
{
    int a[10];
    // 构造数组越界写入
    a[10] = 1;
    return {};
}

EXTERN_C_START
static napi_value Init(napi_env env, napi_value exports)
{
    napi_property_descriptor desc[] = {
        { "test", nullptr, Test, nullptr, nullptr, nullptr, napi_default, nullptr }
    };
    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    return exports;
}
EXTERN_C_END

static napi_module demoModule = {
    .nm_version = 1,
    .nm_flags = 0,
    .nm_filename = nullptr,
    .nm_register_func = Init,
    .nm_modname = "entry",
    .nm_priv = ((void*)0),
    .reserved = { 0 }
};

extern "C" __attribute__((constructor)) void RegisterEntryModule(void)
{
    napi_module_register(&demoModule);
}
```

**ArkTS调用代码(Index.ets)**:
```typescript
import testNapi from 'libentry.so';

@Entry
@Component
struct Index {
  build() {
    Row() {
      Column() {
        Button("address-sanitizer").onClick(() => {
          testNapi.test();
        })
      }
      .width('100%')
    }
    .height('100%')
  }
}
```

### 步骤5:错误处理

```typescript
// 错误处理代码
try {
  hiAppEvent.addWatcher({
    name: "watcher",
    appEventFilters: [
      {
        domain: hiAppEvent.domain.OS,
        names: [hiAppEvent.event.ADDRESS_SANITIZER]
      }
    ],
    onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
      // 处理事件数据
    }
  });
} catch (error) {
  const err = error as BusinessError;
  switch (err.code) {
    case 401:
      hilog.error(0x0000, 'testTag', 'Parameter error. Please check watcher name and event filters.');
      break;
    case 11102001:
      hilog.error(0x0000, 'testTag', 'Invalid watcher name. Check name format and length.');
      break;
    case 11102002:
      hilog.error(0x0000, 'testTag', 'Invalid filtering event domain. Check domain format.');
      break;
    default:
      hilog.error(0x0000, 'testTag', `Unknown error: code=${err.code}, message=${err.message}`);
  }
}
```

### 步骤6:移除观察者(可选)

```typescript
// 移除观察者取消订阅
const watcher: hiAppEvent.Watcher = {
  name: "watcher",
};

// 先添加观察者
hiAppEvent.addWatcher(watcher);

// 需要取消订阅时移除观察者
hiAppEvent.removeWatcher(watcher);
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | Parameter error. Possible causes: 1. Mandatory parameters are left unspecified; 2. Incorrect parameter types. | 检查必填参数是否填写,参数类型是否正确 |
| 11102001 | Invalid watcher name. Possible causes: 1. Contain invalid characters; 2. Length is invalid. | 观察者名称首字符必须为字母,中间字符为数字/字母/下划线,结尾字符为数字/字母,长度不超过32字符 |
| 11102002 | Invalid filtering event domain. Possible causes: 1. Contain invalid characters; 2. Length is invalid. | 使用hiAppEvent.domain.OS系统事件领域常量 |
| 11102003 | Invalid row value. Possible caused by the row value is less than zero. | triggerCondition.row必须为正整数 |
| 11102004 | Invalid size value. Possible caused by the size value is less than zero. | triggerCondition.size必须为正整数 |
| 11102005 | Invalid timeout value. Possible caused by the timeout value is less than zero. | triggerCondition.timeOut必须为正整数 |

## 编译和修复问题

### 依赖声明

**oh-package.json5**:
```json
{
  "dependencies": {
    "@kit.PerformanceAnalysisKit": "^1.0.0",
    "@kit.BasicServicesKit": "^1.0.0"
  }
}
```

**CMakeLists.txt**:
```cmake
cmake_minimum_required(VERSION 3.4.1)
project(entry)

set(CMAKE_CXX_STANDARD 17)

add_library(entry SHARED napi_init.cpp)

target_include_directories(entry PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/types/libentry)
```

### 环境要求
- DevEco Studio: 3.1+版本
- HarmonyOS SDK: API version 12+版本
- Address Sanitizer:需要在Edit Configurations中启用

### 常见编译问题

**问题1:找不到libentry.so模块**
```
Error: Cannot find module 'libentry.so'
```
**解决方法**:
1. 检查CMakeLists.txt是否正确配置
2. 检查napi_init.cpp是否正确导出模块
3. 检查index.d.ts是否正确声明接口

**问题2:Address Sanitizer未启用**
```
Address Sanitizer events not triggered
```
**解决方法**:
1. 点击DevEco Studio界面中的"entry"
2. 点击"Edit Configurations"
3. 点击"Diagnostics"
4. 勾选"Address Sanitizer"
5. 保存设置并重新运行

**问题3:API版本不支持页面切换日志**
```
Property 'pageSwitchLogEnable' does not exist
```
**解决方法**:
1. 检查deviceInfo.sdkApiVersion >= 24
2. 在API version 24+版本中使用该功能
3. 低版本跳过页面切换日志配置

**问题4:观察者添加失败**
```
Error code: 11102001
```
**解决方法**:
1. 检查观察者名称格式(首字母、中间字符、结尾字符)
2. 检查名称长度不超过32字符
3. 避免使用特殊字符

## 常见问题与解决方法

### Q1:订阅后没有触发回调?
**原因**:
- DevEco Studio未启用Address Sanitizer
- Native C++代码未触发地址越界错误
- 观察者名称重复被覆盖

**解决方法**:
- 在Edit Configurations中启用Address Sanitizer
- 确保Native C++代码包含地址越界操作(如数组越界)
- 使用唯一的观察者名称

### Q2:地址越界事件导致应用崩溃?
**原因**:地址越界是严重的内存错误,会导致应用崩溃

**解决方法**:
- 地址越界事件会触发应用崩溃,这是正常现象
- 崩溃后重新运行应用查看日志
- 日志中会包含完整的错误信息和堆栈

### Q3:无法获取页面切换日志?
**原因**:
- API版本低于24
- 未配置pageSwitchLogEnable参数
- 事件参数中未包含page_switch_log字段

**解决方法**:
- 检查API版本是否>=24
- 使用configEventPolicy配置pageSwitchLogEnable为true
- 在回调中检查eventInfo.params['page_switch_log']字段

### Q4:如何解析external_log日志文件?
**原因**:external_log字段包含日志文件路径数组

**解决方法**:
- 日志文件存储在应用数据目录
- 可以读取日志文件获取详细堆栈信息
- 使用JSON.stringify输出日志路径

### Q5:如何在生产环境中使用?
**原因**:Address Sanitizer主要用于调试阶段

**解决方法**:
- Address Sanitizer适用于开发调试阶段
- 生产环境应关闭Address Sanitizer
- 建议仅在测试版本中启用该功能

## 输出结果报告

执行完成后输出以下信息:

```json
{
  "status": "success",
  "watcherName": "watcher",
  "eventDomain": "OS",
  "eventName": "ADDRESS_SANITIZER",
  "apiUsed": [
    "hiAppEvent.addWatcher",
    "hiAppEvent.configEventPolicy",
    "hiAppEvent.event.ADDRESS_SANITIZER",
    "hiAppEvent.domain.OS"
  ],
  "eventInfo": {
    "domain": "OS",
    "name": "ADDRESS_SANITIZER",
    "eventType": 1,
    "params": {
      "time": 1713161197957,
      "bundle_version": "1.0.0",
      "bundle_name": "com.example.myapplication",
      "pid": 12889,
      "uid": 20020140,
      "type": "stack-buffer-overflow",
      "external_log": "[\"/data/storage/el2/log/hiappevent/ADDRESS_SANITIZER_1713161197960_12889.log\"]",
      "log_over_limit": false,
      "page_switch_log": "页面切换日志信息"
    }
  }
}
```

## 参考文档

- [API开发指南](references/hiappevent-watcher-address-sanitizer-events-arkts.md)
- [API参考说明](references/js-apis-hiviewdfx-hiappevent.md)

## 完整示例代码

- [ArkTS示例代码](assets/entry_ability.ets)
- [Native C++示例代码](assets/napi_init.cpp)
- [工程配置示例](assets/cmake_lists.txt)

## 测试用例

### 正向测试用例
- [订阅地址越界事件成功](tests/test_positive.ets):正常订阅ADDRESS_SANITIZER事件并接收回调
- [配置页面切换日志成功](tests/test_positive.ets):API version 24+配置pageSwitchLogEnable
- [解析事件参数成功](tests/test_positive.ets):正确解析事件参数信息

### 边界测试用例
- [观察者名称最大长度](tests/test_boundary.ets):测试32字符长度的观察者名称
- [API版本边界检查](tests/test_boundary.ets):测试API version 24的边界条件
- [多个观察者订阅](tests/test_boundary.ets):测试多个观察者同时订阅

### 异常测试用例
- [观察者名称格式错误](tests/test_exception.ets):测试包含特殊字符的名称
- [事件领域错误](tests/test_exception.ets):测试非系统事件领域
- [API版本不足](tests/test_exception.ets):测试低API版本调用高版本接口