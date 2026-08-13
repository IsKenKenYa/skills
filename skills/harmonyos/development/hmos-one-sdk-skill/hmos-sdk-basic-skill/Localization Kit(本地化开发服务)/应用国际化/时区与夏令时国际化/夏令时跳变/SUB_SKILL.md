---
name: hmos-localization-kit-dst-transition
description: 计算夏令时跳变时间差+处理时区时间转换+支持多时区场景+适用于国际化应用的时间处理场景
---

# 夏令时跳变技能

## 功能描述

本技能提供夏令时跳变相关的计算和处理能力。夏令时（Daylight Saving Time，DST）是一种为节约能源而规定的地方时间制度，在天亮早的夏季人为将时间调快一段时间。系统会自动处理夏令时跳变，应用需要正确计算和处理夏令时跳变带来的时间差异。

主要功能包括：
- 计算夏令时跳变前后的小时数差异
- 处理夏令时跳入导致的时间空缺
- 处理夏令时跳出导致的时间重复
- 按当地夏令时规则存储和显示时间数据
- 使用UTC/GMT标准时间存储和传输时间数据

## 使用场景

### 触发词
- "夏令时跳变"
- "DST计算"
- "夏令时时间差"
- "时区转换"
- "夏令时处理"
- "时间空缺处理"
- "时间重复处理"

### 能做
- 计算夏令时跳变当天的小时数差异（通常为23小时或25小时）
- 设置指定时区的日历对象并进行时间计算
- 获取时间戳用于精确的时间差计算
- 处理跨夏令时的时间显示和存储
- 支持多时区场景的时间转换

### 绝不做
- 不处理闰秒相关的时间调整
- 不处理历史夏令时规则的变更（使用当前系统规则）
- 不修改系统时区设置
- 不处理不存在的时区ID
- 不进行跨历法的时间转换

### 补充
- 夏令时跳变当天的小时数不是24小时
- 夏令时开始当天通常为23小时（时间向前拨快）
- 夏令时结束当天通常为25小时（时间向后拨慢）
- 建议使用UTC/GMT存储和传输时间数据避免夏令时问题
- 在夏令时内显示时间时建议添加夏令时标识

## 调用规范和规则

### 输入约束
- 时区ID：必须是合法的时区ID字符串（如"Europe/London"、"Asia/Shanghai"）
- 时间参数：year、month、date为必填，hour、minute、second为可选
- 月份取值：月份从0开始计数，0表示一月，11表示十二月
- 时间戳范围：有效的Unix时间戳（毫秒级）

### 执行约束
- 最大计算次数：单次计算不超过100次时间操作
- 时区设置：每次计算前必须明确设置时区
- 时间精度：毫秒级精度，误差不超过1毫秒
- API调用频次：无限制，但建议避免频繁创建Calendar对象

### 内容约束
- 禁止使用硬编码的时区偏移量（应使用时区ID）
- 禁止假设所有时区都有夏令时
- 禁止假设夏令时规则固定不变
- 禁止忽略时区转换错误

### 降级约束
- 时区ID无效：提示用户使用合法时区ID，提供常见时区ID列表
- 计算结果异常：使用UTC时间作为基准重新计算
- API调用失败：返回错误信息并建议检查系统时区设置

## 调用流程和步骤

### 步骤1：导入模块和创建日历对象

**前置校验**：
1. 检查系统是否支持i18n模块
2. 验证时区ID是否合法
3. 确认API版本兼容性（API version 7+）

**参数准备**：
```typescript
import { i18n } from '@kit.LocalizationKit';

const locale = 'zh-Hans';
const timezone = 'Europe/London';
```

### 步骤2：计算夏令时跳变时间差

**示例代码**：
```typescript
import { i18n } from '@kit.BasicServicesKit';

function calculateDSTHoursDifference(
  timezone: string,
  year: number,
  startMonth: number,
  startDay: number,
  endMonth: number,
  endDay: number
): number {
  try {
    const calendar: i18n.Calendar = i18n.getCalendar('zh-Hans');
    calendar.setTimeZone(timezone);
    
    calendar.set(year, startMonth, startDay, 16, 0, 0);
    const startTime = calendar.getTimeInMillis();
    
    calendar.set(year, endMonth, endDay, 16, 0, 0);
    const finishTime = calendar.getTimeInMillis();
    
    const hours = (finishTime - startTime) / (3600 * 1000);
    
    console.log(`夏令时跳变时间差: ${hours}小时`);
    return hours;
  } catch (error) {
    console.error(`计算夏令时时间差失败: ${error.message}`);
    throw error;
  }
}

const hours = calculateDSTHoursDifference('Europe/London', 2021, 2, 27, 2, 28);
```

### 步骤3：处理夏令时时间显示

**示例代码**：
```typescript
import { i18n } from '@kit.LocalizationKit';

function getDSTTimeInfo(timezone: string, timestamp: number): object {
  try {
    const calendar: i18n.Calendar = i18n.getCalendar('zh-Hans');
    calendar.setTimeZone(timezone);
    calendar.setTime(timestamp);
    
    const dstOffset = calendar.get('dst_offset');
    const isDST = dstOffset !== 0;
    
    return {
      timestamp: timestamp,
      timezone: timezone,
      isDST: isDST,
      dstOffset: dstOffset,
      displayTime: new Date(timestamp).toLocaleString('zh-CN', { timeZone: timezone })
    };
  } catch (error) {
    console.error(`获取夏令时信息失败: ${error.message}`);
    throw error;
  }
}

const timeInfo = getDSTTimeInfo('Europe/London', 1616956800000);
console.log(timeInfo);
```

### 步骤4：使用UTC时间避免夏令时问题

**示例代码**：
```typescript
import { i18n } from '@kit.LocalizationKit';

function storeTimeInUTC(localTime: Date, timezone: string): number {
  try {
    const calendar: i18n.Calendar = i18n.getCalendar('zh-Hans');
    calendar.setTimeZone(timezone);
    calendar.set(
      localTime.getFullYear(),
      localTime.getMonth(),
      localTime.getDate(),
      localTime.getHours(),
      localTime.getMinutes(),
      localTime.getSeconds()
    );
    
    const utcTimestamp = calendar.getTimeInMillis();
    
    console.log(`本地时间已转换为UTC时间戳: ${utcTimestamp}`);
    return utcTimestamp;
  } catch (error) {
    console.error(`UTC时间转换失败: ${error.message}`);
    throw error;
  }
}

const utcTime = storeTimeInUTC(new Date(2021, 2, 28, 3, 30, 0), 'Europe/London');
```

### 步骤5：错误处理和降级

**示例代码**：
```typescript
import { BusinessError } from '@kit.BasicServicesKit';
import { i18n } from '@kit.LocalizationKit';

function safeCalculateDST(timezone: string): number | null {
  try {
    const validTimezones = [
      'Europe/London', 'Europe/Paris', 'America/New_York', 
      'America/Los_Angeles', 'Asia/Shanghai', 'Asia/Tokyo'
    ];
    
    if (!validTimezones.includes(timezone)) {
      console.warn(`时区ID "${timezone}"可能不支持夏令时，使用UTC时间计算`);
      return 24;
    }
    
    const calendar: i18n.Calendar = i18n.getCalendar('zh-Hans');
    calendar.setTimeZone(timezone);
    calendar.set(2021, 2, 27, 16, 0, 0);
    const startTime = calendar.getTimeInMillis();
    
    calendar.set(2021, 2, 28, 16, 0, 0);
    const finishTime = calendar.getTimeInMillis();
    
    return (finishTime - startTime) / (3600 * 1000);
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`计算失败 [错误码: ${err.code}]: ${err.message}`);
    return 24;
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误：必填参数未指定或参数类型不正确 | 检查参数类型和必填参数是否完整 |
| 890001 | 无效参数：参数验证失败 | 检查时区ID是否合法，月份是否在0-11范围内 |
| - | 时区ID不存在 | 使用IANA标准时区ID，如"Europe/London" |
| - | 时间戳溢出 | 确保时间戳在有效范围内（1970年后） |

## 编译和修复问题

### 依赖声明
```json
{
  "name": "dst-transition-example",
  "version": "1.0.0",
  "dependencies": {
    "@kit.LocalizationKit": "^1.0.0",
    "@kit.BasicServicesKit": "^1.0.0"
  }
}
```

### 环境要求
- HarmonyOS API version: 7+（基础功能）、11+（getTimeInMillis）、12+（元服务）
- 开发环境：DevEco Studio 3.0+
- ArkTS版本：兼容ArkTS 1.0+

### 常见编译问题

**问题1：模块导入失败**
```
Error: Cannot find module '@kit.LocalizationKit'
```
**解决方法**：确保项目依赖中已正确配置LocalizationKit，检查module.json5中的依赖声明

**问题2：时区ID无效**
```
Error: Invalid timezone ID: "London"
```
**解决方法**：使用完整的IANA时区ID，如"Europe/London"而不是"London"

**问题3：月份参数错误**
```
Error: Month value out of range
```
**解决方法**：月份从0开始计数，0表示一月，11表示十二月

## 常见问题与解决方法

### Q1：如何判断某个时区是否有夏令时？
**原因**：并非所有时区都使用夏令时制度
**解决方法**：
- 使用calendar.get('dst_offset')获取夏令时偏移量
- 如果偏移量为0，则当前时间不在夏令时期间
- 查询时区数据库确认该时区是否支持夏令时

### Q2：夏令时跳变当天如何处理重复时间？
**原因**：夏令时结束时会将时钟拨慢，导致同一时间重复出现
**解决方法**：
- 使用UTC时间戳存储和传输时间数据
- 在显示时标注是否为夏令时时间
- 对于关键业务时间，使用时间戳而非本地时间字符串

### Q3：夏令时跳入时如何处理时间空缺？
**原因**：夏令时开始时会将时钟拨快，导致某些时间不存在
**解决方法**：
- 检查用户输入的时间是否存在
- 对于不存在的时间，提示用户选择有效时间
- 使用UTC时间进行计算，避免本地时间空缺

### Q4：如何获取夏令时的跳变时间点？
**原因**：不同地区的夏令时规则不同
**解决方法**：
- 使用TimeZone API查询时区规则
- 参考当地政府发布的夏令时时间表
- 使用Calendar API计算具体跳变时间

### Q5：应用如何自动适应夏令时变化？
**原因**：系统会自动处理夏令时跳变
**解决方法**：
- 使用标准Date对象或Calendar API获取时间
- 系统会在跳变时自动调整时间显示
- 监听系统时间变化事件进行相应更新

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "calculationResult": {
    "timezone": "Europe/London",
    "hoursDifference": 23,
    "isDST": true,
    "utcTimestamp": 1616956800000,
    "localTime": "2021-03-28 16:00:00 GMT"
  },
  "apiUsed": [
    "i18n.getCalendar",
    "Calendar.setTimeZone",
    "Calendar.set",
    "Calendar.getTimeInMillis",
    "Calendar.get"
  ],
  "warnings": [],
  "recommendations": [
    "建议使用UTC时间存储和传输时间数据",
    "在显示时标注是否为夏令时时间"
  ]
}
```

## 参考文档

- [夏令时跳变开发指南](references/i18n-dst-transition.md)
- [@ohos.i18n API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-i18n)
- [时区与夏令时国际化](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/i18n-dst-transition)

## 完整示例代码

- [ArkTS示例：夏令时跳变计算](assets/dst-transition-example.ets)
- [ArkTS示例：时区转换处理](assets/timezone-conversion.ets)
- [配置文件示例](assets/dst-config.json)

## 测试用例

### 正向测试用例
- [夏令时开始跳变计算](tests/test_positive.py)：验证夏令时开始当天为23小时
- [夏令时结束跳变计算](tests/test_positive.py)：验证夏令时结束当天为25小时
- [多时区计算](tests/test_positive.py)：验证不同时区的夏令时计算

### 边界测试用例
- [临界时间点测试](tests/test_boundary.py)：测试夏令时跳变临界点的时间计算
- [不支持夏令时的时区](tests/test_boundary.py)：测试无夏令时时区的处理
- [跨年夏令时计算](tests/test_boundary.py)：测试跨年度的夏令时计算

### 异常测试用例
- [无效时区ID测试](tests/test_exception.py)：测试非法时区ID的错误处理
- [参数类型错误测试](tests/test_exception.py)：测试错误参数类型的异常捕获
- [时间戳溢出测试](tests/test_exception.py)：测试超大时间戳的处理