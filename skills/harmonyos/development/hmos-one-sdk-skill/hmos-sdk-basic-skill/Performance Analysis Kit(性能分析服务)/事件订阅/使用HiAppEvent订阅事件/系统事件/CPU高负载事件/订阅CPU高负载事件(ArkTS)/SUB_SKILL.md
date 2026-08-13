---
name: hmos-performance-analysis-kit-cpu-usage-high-watcher
description: 订阅应用CPU高负载事件，实时监听应用前台、后台及线程的CPU负载异常，支持自定义阈值配置和采样栈采集策略，适用于性能调优、异常排查场景
---

# 订阅CPU高负载事件技能

## 功能描述

本技能用于订阅HarmonyOS应用的CPU高负载系统事件。通过HiAppEvent提供的观察者机制，实时监听应用运行过程中产生的CPU高负载异常事件，包括前台CPU负载异常、后台CPU负载异常以及线程级CPU负载异常。支持自定义事件配置策略，可灵活设置CPU负载阈值、采样栈采集次数等参数，帮助开发者快速定位和解决性能问题。

### 核心能力

- **实时事件订阅**：通过addWatcher添加观察者，实时监听CPU_USAGE_HIGH系统事件
- **事件数据解析**：获取CPU高负载事件的详细信息，包括异常线程、CPU占用率、采样栈日志等
- **自定义配置策略**：通过configEventPolicy自定义CPU负载阈值和采样栈采集参数
- **多场景监控**：支持监控前台、后台、线程级CPU高负载异常

### 适用范围

- API版本：hiAppEvent.event.CPU_USAGE_HIGH从API version 12开始支持
- configEventPolicy接口从API version 22开始支持
- 语言：ArkTS
- Kit：PerformanceAnalysisKit

### 限制条件

- Debug版本应用，采样栈每日采集次数阈值范围：[-1, 100]
- Release版本应用，采样栈每日采集次数阈值范围：[0, 20]
- 抓取采样栈有内存开销，影响功耗性能，只建议在本地调试时使用自定义参数功能
- CPU高负载事件抓取次数存在限制，默认每日采集次数上限为1次

### 典型场景

- 性能调优：监控应用运行时的CPU负载情况，定位性能瓶颈
- 异常排查：捕获CPU异常峰值事件，分析导致高负载的线程和代码路径
- 功耗优化：识别后台高CPU占用场景，优化功耗表现
- 多线程优化：监控各线程CPU负载分布，优化线程调度策略

## 使用场景

### 触发词

- "订阅CPU高负载事件"
- "监控CPU负载异常"
- "CPU使用率过高"
- "CPU高负载监控"
- "线程CPU占用监控"
- "后台CPU异常"
- "性能分析CPU"

### 能做

- 添加观察者订阅CPU高负载系统事件
- 实时接收并解析CPU高负载事件数据
- 自定义CPU负载阈值和采样栈采集策略
- 移除观察者取消事件订阅
- 处理事件回调数据并打印日志信息
- 获取CPU异常事件的external_log采样栈文件路径

### 绝不做

- 不订阅非CPU高负载的其他系统事件（如崩溃、冻屏事件需使用其他技能）
- 不修改系统默认的CPU监控机制
- 不直接处理采样栈文件内容（仅获取文件路径）
- 不在Release版本应用中过度采集采样栈（会影响性能）
- 不在主线程执行耗时的事件处理逻辑

### 补充

- CPU高负载事件默认抓取次数存在限制，未抓取到事件时可尝试重启设备或调整配置策略
- 采样栈文件存储在应用沙箱路径/data/storage/el2/log/hiappevent/目录下
- CPU高负载事件检测周期可自定义，默认60秒
- 建议在后台线程处理事件回调，避免阻塞主线程

## 调用规范和规则

### 输入约束

- **观察者名称**：首字符必须为字母字符，中间字符必须为数字字符、字母字符或下划线字符，结尾字符必须为数字字符或字母字符，长度非空且不超过32个字符
- **事件领域**：必须使用hiAppEvent.domain.OS系统领域
- **事件名称**：必须使用hiAppEvent.event.CPU_USAGE_HIGH系统事件名称
- **配置策略参数**：
  - foregroundLoadThreshold：阈值范围[1, 100]，单位%，建议值<30
  - backgroundLoadThreshold：阈值范围[1, 100]，单位%，建议值<10
  - threadLoadThreshold：阈值范围[15, 100]，单位%，默认70
  - perfLogCaptureCount：Debug版本[-1, 100]，Release版本[0, 20]，单位次
  - threadLoadInterval：阈值范围[5, 3600]，单位秒

### 执行约束

- **最大耗时**：事件回调处理建议不超过100ms，避免阻塞事件分发
- **回调时机**：CPU高负载事件触发后，系统捕获维测日志耗时典型30s内，极端情况2min
- **API调用频次**：addWatcher传入的name必须唯一，相同name会覆盖前一次订阅
- **事件采集限制**：每日采样栈采集次数受perfLogCaptureCount参数限制，超过次数后external_log字段为空

### 内容约束

- **禁止高危操作**：事件回调中禁止执行文件I/O、网络请求等耗时操作
- **禁止阻塞操作**：禁止在回调函数中调用removeWatcher移除当前观察者
- **禁止主线程耗时处理**：事件数据处理逻辑应下沉到Worker线程
- **禁止无限采集**：Release版本应用perfLogCaptureCount不得超过20次

### 降级约束

- **未抓取到事件**：重启测试设备重新抓取或自定义配置策略降低阈值
- **采样栈超限**：external_log字段为空时，仅获取事件基本信息，无法定位代码路径
- **回调失败**：检查观察者名称是否唯一，检查事件过滤条件是否正确
- **配置失败**：检查参数是否在阈值范围内，参数错误时系统使用默认值

## 调用流程和步骤

### 步骤1：导入依赖模块

**前置校验**：
1. 确认项目已配置PerformanceAnalysisKit依赖
2. 确认应用API版本>=12（CPU_USAGE_HIGH事件要求）
3. 确认开发环境为DevEco Studio

**导入模块**：
```typescript
import { hiAppEvent, hilog } from '@kit.PerformanceAnalysisKit';
```

### 步骤2：添加观察者订阅CPU高负载事件

**示例代码**：
```typescript
hiAppEvent.addWatcher({
  // 观察者名称，用于唯一标识观察者
  name: "cpuWatcher",
  // 订阅过滤条件，订阅系统领域的CPU高负载事件
  appEventFilters: [
    {
      domain: hiAppEvent.domain.OS,
      names: [hiAppEvent.event.CPU_USAGE_HIGH]
    }
  ],
  // 实现订阅实时回调函数，处理事件数据
  onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
    hilog.info(0x0000, 'CpuWatcher', `onReceive: domain=${domain}`);
    for (const eventGroup of appEventGroups) {
      hilog.info(0x0000, 'CpuWatcher', `eventName=${eventGroup.name}`);
      for (const eventInfo of eventGroup.appEventInfos) {
        // 解析事件数据：domain、eventType、name、params
        hilog.info(0x0000, 'CpuWatcher', `eventInfo=${JSON.stringify(eventInfo)}`);
        // 提取关键信息：CPU占用率、异常线程列表、采样栈路径
        const params = eventInfo.params;
        hilog.info(0x0000, 'CpuWatcher', `CPU usage: ${params.usage}%`);
        hilog.info(0x0000, 'CpuWatcher', `Threads: ${JSON.stringify(params.threads)}`);
        hilog.info(0x0000, 'CpuWatcher', `Log files: ${JSON.stringify(params.external_log)}`);
      }
    }
  }
});
```

### 步骤3：（可选）自定义CPU高负载事件配置策略

**前置条件**：API version >= 22

**示例代码**：
```typescript
import { BusinessError } from '@kit.BasicServicesKit';

// 定义CPU高负载事件配置策略
let policy: hiAppEvent.EventPolicy = {
  "cpuUsageHighPolicy": {
    "foregroundLoadThreshold": 10,   // 应用前台CPU负载异常阈值10%
    "backgroundLoadThreshold": 5,    // 应用后台CPU负载异常阈值5%
    "threadLoadThreshold": 50,       // 应用线程CPU负载异常阈值50%
    "perfLogCaptureCount": 3,        // 采样栈每日采集次数上限3次
    "threadLoadInterval": 30,        // 线程负载异常检测周期30秒
  }
};

// 配置事件策略
hiAppEvent.configEventPolicy(policy).then(() => {
  hilog.info(0x0000, 'CpuWatcher', 'Successfully set cpu usage high event policy.');
}).catch((err: BusinessError) => {
  hilog.error(0x0000, 'CpuWatcher', `Failed to set policy. Code: ${err?.code}, message: ${err?.message}`);
});
```

### 步骤4：移除观察者取消订阅

**示例代码**：
```typescript
let watcher: hiAppEvent.Watcher = {
  name: "cpuWatcher",
};

// 添加观察者
hiAppEvent.addWatcher(watcher);

// 移除观察者（取消订阅）
hiAppEvent.removeWatcher(watcher);
```

### 步骤5：错误处理

**错误码处理**：
```typescript
import { BusinessError } from '@kit.BasicServicesKit';

try {
  hiAppEvent.addWatcher({
    name: "cpuWatcher",
    appEventFilters: [
      {
        domain: hiAppEvent.domain.OS,
        names: [hiAppEvent.event.CPU_USAGE_HIGH]
      }
    ],
    onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
      // 处理事件数据
    }
  });
} catch (error) {
  const err: BusinessError = error as BusinessError;
  switch (err.code) {
    case 401:
      hilog.error(0x0000, 'CpuWatcher', 'Parameter error. Check watcher name format.');
      break;
    case 11102001:
      hilog.error(0x0000, 'CpuWatcher', 'Invalid watcher name. Name contains invalid chars or length invalid.');
      break;
    case 11102002:
      hilog.error(0x0000, 'CpuWatcher', 'Invalid filtering event domain.');
      break;
    default:
      hilog.error(0x0000, 'CpuWatcher', `Unknown error: ${err.code}, ${err.message}`);
  }
}
```

### 步骤6：降级处理

**未抓取到事件的降级方案**：
```typescript
// 方案1：降低CPU负载阈值
let policy: hiAppEvent.EventPolicy = {
  "cpuUsageHighPolicy": {
    "foregroundLoadThreshold": 5,    // 降低前台阈值到5%
    "backgroundLoadThreshold": 3,    // 降低后台阈值到3%
    "threadLoadThreshold": 30,       // 降低线程阈值到30%
    "perfLogCaptureCount": 10,       // 增加采集次数
    "threadLoadInterval": 10,        // 缩短检测周期到10秒
  }
};

// 方案2：重启设备重新抓取
hilog.warn(0x0000, 'CpuWatcher', 'No event captured. Try restart device or adjust policy.');

// 方案3：使用默认策略（不调用configEventPolicy）
// 系统使用默认阈值：前台30%、后台10%、线程70%
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误。必填参数未指定或参数类型错误 | 检查watcher对象参数，确保name、domain、names字段正确 |
| 11102001 | 观察者名称无效。包含非法字符或长度无效 | 检查name格式：首字符字母、中间字符数字字母下划线、结尾字符数字字母、长度<=32 |
| 11102002 | 事件领域过滤无效。包含非法字符或长度无效 | 确保使用hiAppEvent.domain.OS系统领域常量 |
| 11102003 | row值无效。row值小于零 | 检查triggerCondition.row参数，必须为正整数 |
| 11102004 | size值无效。size值小于零 | 检查triggerCondition.size参数，必须为正整数 |
| 11102005 | timeout值无效。timeout值小于零 | 检查triggerCondition.timeOut参数，必须为正整数 |

## 编译和修复问题

### 依赖声明

**module.json5配置**：
```json
{
  "module": {
    "name": "entry",
    "type": "entry",
    "deviceTypes": ["default", "tablet"],
    "deliveryWithInstall": true,
    "installationFree": false,
    "pages": "$media:pages_config",
    "abilities": [...]
  }
}
```

**package.json依赖**：
```json
{
  "dependencies": {
    "@kit.PerformanceAnalysisKit": "系统内置Kit，无需额外安装",
    "@kit.BasicServicesKit": "系统内置Kit，用于BusinessError类型"
  }
}
```

### 环境要求

- **DevEco Studio**：版本 >= 3.1
- **HarmonyOS SDK**：API version >= 12（CPU_USAGE_HIGH事件）
- **API version >= 22**：configEventPolicy接口要求
- **应用类型**：支持普通应用和元服务（API version 11+）

### 常见编译问题

**问题1：导入模块失败**
```
Error: Cannot find module '@kit.PerformanceAnalysisKit'
```
**解决方法**：确保DevEco Studio版本>=3.1，API version配置正确，PerformanceAnalysisKit为系统内置Kit无需额外安装。

**问题2：CPU_USAGE_HIGH常量未定义**
```
Error: Property 'CPU_USAGE_HIGH' does not exist on type 'event'
```
**解决方法**：确认API version >= 12，在module.json5中配置正确的minAPIVersion。

**问题3：configEventPolicy接口不存在**
```
Error: Property 'configEventPolicy' does not exist on type 'hiAppEvent'
```
**解决方法**：configEventPolicy从API version 22开始支持，确认API version配置。

**问题4：事件回调无响应**
```
运行应用后点击CPU加压按钮，无事件回调触发
```
**解决方法**：检查观察者name是否唯一，检查事件过滤条件domain和names是否正确，检查应用是否在前台亮屏状态。

## 常见问题与解决方法

### Q1：应用运行后未抓取到CPU高负载事件

**原因**：
- CPU负载未达到默认阈值（前台30%、后台10%、线程70%）
- 事件采集次数已达每日上限
- 应用不在前台或屏幕未亮屏
- 系统捕获维测日志耗时较长（典型30s，极端2min）

**解决方法**：
- 降低CPU负载阈值，调用configEventPolicy设置更低的foregroundLoadThreshold、backgroundLoadThreshold、threadLoadThreshold
- 增加perfLogCaptureCount参数提高每日采集次数上限
- 确保应用在前台运行且屏幕亮屏状态
- 增加CPU压力测试强度，创建更多Worker线程执行死循环
- 延长等待时间，CPU高负载事件触发后需等待系统捕获维测日志

### Q2：事件数据中external_log字段为空

**原因**：
- 采样栈每日采集次数已达上限（perfLogCaptureCount）
- Release版本应用采集次数限制为[0, 20]
- 日志文件存储空间不足

**解决方法**：
- Debug版本设置perfLogCaptureCount为-1表示不限制采集次数
- Release版本增加perfLogCaptureCount参数值（最大20）
- 检查应用沙箱路径/data/storage/el2/log/hiappevent/是否有写入权限
- 清理历史日志文件释放存储空间

### Q3：观察者回调触发但无法获取事件详情

**原因**：
- onReceive回调函数实现错误
- 事件数据解析逻辑异常
- hilog日志输出配置错误

**解决方法**：
- 检查onReceive回调函数参数类型是否正确
- 使用JSON.stringify打印完整事件数据结构
- 确认hilog日志domain和tag配置正确（domain范围0x0000-0xFFFF）
- 参考API文档中AppEventGroup和AppEventInfo数据结构

### Q4：配置策略后仍然使用默认阈值

**原因**：
- configEventPolicy参数值超出阈值范围
- API version < 22不支持configEventPolicy
- 参数名称拼写错误（如foregroundLoadThreshold拼写错误）

**解决方法**：
- 检查参数值是否在阈值范围内：
  - foregroundLoadThreshold: [1, 100]
  - backgroundLoadThreshold: [1, 100]
  - threadLoadThreshold: [15, 100]
  - perfLogCaptureCount: Debug[-1, 100], Release[0, 20]
  - threadLoadInterval: [5, 3600]
- 确认API version >= 22
- 检查参数名称拼写是否与CpuUsageHighPolicy定义一致

### Q5：移除观察者后仍然收到事件回调

**原因**：
- removeWatcher调用时机错误
- 观察者name参数不匹配
- 回调函数中异步处理未完成

**解决方法**：
- 确保removeWatcher传入的watcher对象与addWatcher一致
- 不要在onReceive回调函数中调用removeWatcher
- removeWatcher调用后等待系统清理观察者状态

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "watcherName": "cpuWatcher",
  "subscribedEvent": "CPU_USAGE_HIGH",
  "eventData": {
    "domain": "OS",
    "eventType": 1,
    "name": "CPU_USAGE_HIGH",
    "params": {
      "begin_time": 1723725541352,
      "bundle_name": "com.example.app",
      "bundle_version": "1.0.0",
      "end_time": 1723725843413,
      "external_log": [
        "/data/storage/el2/log/hiappevent/CPU_USAGE_HIGH_1723725950017_0.log",
        "/data/storage/el2/log/hiappevent/CPU_USAGE_HIGH_1723725950197_0.log"
      ],
      "fault_type": 1,
      "foreground": false,
      "log_over_limit": false,
      "threads": [
        {"name": "main", "tid": 60677, "usage": 0.07},
        {"name": "WorkerThread", "tid": 60856, "usage": 7.43}
      ],
      "time": 1723725949836,
      "usage": 25
    }
  },
  "apiUsed": [
    "hiAppEvent.addWatcher",
    "hiAppEvent.event.CPU_USAGE_HIGH",
    "hiAppEvent.domain.OS"
  ]
}
```

## 参考文档

- [订阅CPU高负载事件（ArkTS）开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/hiappevent-watcher-cpu-usage-high-arkts)
- [@ohos.hiviewdfx.hiAppEvent API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-hiviewdfx-hiappevent)

## 完整示例代码

- [ArkTS完整示例](assets/example_cpu_usage_high.ets)
- [配置文件示例](assets/module.json5)
- [Worker线程示例](assets/worker.ets)
- [CPU压力测试类](assets/CpuTester.ets)

## 测试用例

### 正向测试用例

- [正常订阅CPU高负载事件](tests/test_positive.ets)：添加观察者成功订阅事件并收到回调
- [自定义配置策略测试](tests/test_positive.ets)：设置自定义阈值并成功触发事件
- [事件数据解析测试](tests/test_positive.ets)：正确解析事件数据中的threads、usage、external_log字段

### 边界测试用例

- [阈值边界测试](tests/test_boundary.ets)：设置foregroundLoadThreshold=1、backgroundLoadThreshold=1、threadLoadThreshold=15
- [采集次数上限测试](tests/test_boundary.ets)：Debug版本设置perfLogCaptureCount=100，Release版本设置perfLogCaptureCount=20
- [观察者名称边界测试](tests/test_boundary.ets)：name长度=32字符、包含字母数字下划线

### 异常测试用例

- [参数错误测试](tests/test_exception.ets)：name包含非法字符、长度>32、domain错误
- [重复订阅测试](tests/test_exception.ets)：相同name多次调用addWatcher覆盖订阅
- [移除观察者测试](tests/test_exception.ets)：移除未添加的观察者、在回调中移除观察者
- [配置策略错误测试](tests/test_exception.ets)：参数超出阈值范围、API version < 22