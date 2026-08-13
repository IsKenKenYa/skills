---
name: hmos-accessibility-kit-multidimensional-nesting
description: 处理多维嵌套场景下的无障碍访问问题，避免嵌套组件中重复朗读，支持accessibilityGroup和accessibilityText属性设置，适用于卡片、列表项、复合组件的无障碍优化场景
---

# 多维嵌套场景无障碍优化技能

## 功能描述

本技能用于处理HarmonyOS应用中多维嵌套组件的无障碍访问优化问题。在嵌套组中，通过合理设置accessibilityGroup和accessibilityText属性，避免两个可获焦对象的功能或朗读内容产生重复，确保屏幕朗读用户能够清晰、高效地理解组件内容，减少不必要的操作步骤。

**核心能力**：
- 识别嵌套组件中的重复朗读问题
- 使用accessibilityGroup将父子组件合并为一个可聚焦单元
- 使用accessibilityText提供统一的朗读文本
- 防止子组件重复朗读父组件的信息

**适用范围**：
- 包含多个子组件的复合组件（如卡片、列表项）
- 时间+位置、图片+标题等多维信息展示场景
- 具有层级结构的嵌套组件

**技术限制**：
- 仅支持ArkTS开发语言
- 需要API version 10及以上版本
- accessibilityGroup从API version 12开始支持在ArkTS卡片中使用

**典型场景**：
- 天气卡片：时间信息+位置信息合并朗读
- 新闻卡片：标题+来源合并朗读
- 商品卡片：价格+规格合并朗读
- 通知消息：时间+内容合并朗读

## 使用场景

### 触发词
- "多维嵌套无障碍"
- "嵌套组件重复朗读"
- "accessibilityGroup使用"
- "卡片无障碍优化"
- "复合组件无障碍"
- "避免重复播报"
- "合并朗读"

### 能做
- 分析嵌套组件结构，识别重复朗读问题
- 为父组件设置accessibilityGroup(true)合并子组件
- 为父组件设置accessibilityText提供统一朗读文本
- 确保子组件不再单独可聚焦和朗读
- 提供完整的ArkTS代码示例和最佳实践

### 绝不做
- 不处理单一组件的无障碍设置（应使用基础无障碍属性技能）
- 不处理跨进程嵌入式组件的无障碍问题（应使用accessibilityUseSamePage技能）
- 不处理滚动容器的无障碍优化（应使用accessibilityScrollTriggerable技能）
- 不处理虚拟节点的无障碍设置（应使用accessibilityVirtualNode技能）
- 不推荐在未分析组件结构的情况下直接设置accessibilityGroup

### 补充
- 当子组件accessibilityLevel设置为"yes"时，不受accessibilityGroup约束，可单独聚焦
- 若父组件既无文本属性也无accessibilityText，会自动拼接子组件文本（深度优先）
- 使用accessibilityGroup(true, { accessibilityPreferred: true })可优先拼接子组件的accessibilityText
- 需要在实际设备上测试屏幕朗读效果，确保优化符合预期

## 调用规范和规则

### 输入约束
- 组件结构：必须包含至少一个父组件和多个子组件
- 代码格式：必须为ArkTS代码片段
- 组件类型：支持所有ArkUI基础组件
- 参数类型：accessibilityGroup参数为boolean，accessibilityText参数为string或Resource

### 执行约束
- 最大嵌套层级：建议不超过3层
- 最大子组件数：建议不超过10个子组件
- API版本要求：accessibilityGroup需API version 10+，卡片使用需API version 12+
- 系统能力：SystemCapability.ArkUI.ArkUI.Full

### 内容约束
- 禁止在accessibilityGroup(true)后仍让子组件可聚焦（除非accessibilityLevel为"yes"）
- 禁止为合并后的父组件设置重复或矛盾的accessibilityText
- 禁止在未分析组件功能的情况下盲目合并所有子组件
- 禁止使用accessibilityGroup替代合理的组件结构设计

### 降级约束
- 若无法使用accessibilityGroup（API version < 10）：建议使用accessibilityLevel("no-hide-descendants")隐藏子组件
- 若组件结构过于复杂：建议拆分为多个独立的复合组件
- 若屏幕朗读测试失败：提供调试方案和替代实现方式
- 若用户需求不明确：提供多个优化方案供选择

## 调用流程和步骤

### 步骤1：分析组件结构

**前置校验**：
1. 确认组件是否为多维嵌套结构（包含父组件和多个子组件）
2. 识别子组件是否包含可朗读的文本内容
3. 分析是否存在重复朗读的风险（父子组件朗读内容重叠）

**参数准备**：
```typescript
// 组件结构分析示例
interface ComponentAnalysis {
  hasParent: boolean;          // 是否有父容器
  childCount: number;          // 子组件数量
  hasTextOverlap: boolean;     // 是否有文本重叠
  needsMerge: boolean;         // 是否需要合并
}
```

### 步骤2：设置accessibilityGroup

**示例代码**：
```typescript
// 导入必要模块（无需额外导入，accessibilityGroup为通用属性）

// 设置accessibilityGroup合并子组件
@Component
export struct WeatherCardExample {
  build() {
    // 正确示例：使用accessibilityGroup合并
    Row() {
      Text('07:05')  // 时间信息
        .fontSize(32)
        .fontColor(Color.Red)
        .fontWeight(FontWeight.Bold)
        .textAlign(TextAlign.Center)
        .margin({ right: 20 })
      
      Text('Moscow')  // 位置信息
        .fontSize(20)
        .fontColor(Color.Green)
        .fontWeight(FontWeight.Bold)
        .textAlign(TextAlign.Center)
    }
    .height(50)
    .accessibilityGroup(true)  // 启用无障碍分组，子组件不再单独聚焦
    // 父组件获得焦点时，会朗读拼接的子组件文本："07:05 Moscow"
    
    // 错误示例：未使用accessibilityGroup导致重复朗读
    Row() {
      Text('12:05')
        .fontSize(32)
        .fontColor(Color.Red)
        .fontWeight(FontWeight.Bold)
        .margin({ right: 20 })
      
      Text('Beijing')
        .fontSize(20)
        .fontColor(Color.Green)
        .fontWeight(FontWeight.Bold)
    }
    .height(50)
    .accessibilityText('Time Group')  // 仅设置文本，子组件仍可单独聚焦
    // 会导致重复朗读："Time Group 12:05 Beijing" + "12:05" + "Beijing"
  }
}
```

### 步骤3：设置accessibilityText（可选）

**示例代码**：
```typescript
// 为合并后的组件提供自定义朗读文本
@Component
export struct CustomAccessibilityTextExample {
  build() {
    Row() {
      Text('￥99')
        .fontSize(24)
        .fontColor(Color.Orange)
      
      Text('会员专享')
        .fontSize(16)
        .fontColor(Color.Gray)
    }
    .height(50)
    .accessibilityGroup(true)
    .accessibilityText('会员价格99元')  // 自定义朗读文本，优先级高于拼接文本
    // 屏幕朗读时只播报："会员价格99元"，不播报拼接的"￥99 会员专享"
  }
}
```

### 步骤4：错误处理

```typescript
// 错误处理和验证代码
@Component
export struct AccessibilityValidationExample {
  @State hasError: boolean = false;
  @State errorMessage: string = '';
  
  validateAccessibility(): boolean {
    try {
      // 验证API版本
      const apiVersion = 10;  // 实际应从设备获取
      if (apiVersion < 10) {
        this.hasError = true;
        this.errorMessage = 'accessibilityGroup需要API version 10+';
        return false;
      }
      
      // 验证组件结构
      // （在实际开发中，应检查组件是否有子组件）
      
      return true;
    } catch (error) {
      this.hasError = true;
      this.errorMessage = `验证失败: ${error.message}`;
      return false;
    }
  }
  
  build() {
    Column() {
      if (this.hasError) {
        Text(`错误: ${this.errorMessage}`)
          .fontColor(Color.Red)
          .fontSize(14)
      } else {
        // 正常组件
        Row() {
          Text('正常内容')
        }
        .accessibilityGroup(true)
      }
    }
  }
}
```

### 步骤5：降级处理

```typescript
// 降级方案：使用accessibilityLevel隐藏子组件
@Component
export struct FallbackAccessibilityExample {
  @State useFallback: boolean = false;  // 根据API版本或设备能力动态设置
  
  build() {
    Column() {
      if (this.useFallback) {
        // 降级方案：accessibilityLevel
        Row() {
          Text('时间')
            .accessibilityLevel('no')  // 隐藏子组件
          
          Text('地点')
            .accessibilityLevel('no')  // 隐藏子组件
        }
        .accessibilityText('时间地点信息')
        .accessibilityLevel('yes')  // 父组件可聚焦
      } else {
        // 标准方案：accessibilityGroup
        Row() {
          Text('时间')
          Text('地点')
        }
        .accessibilityGroup(true)
        .accessibilityText('时间地点信息')
      }
    }
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| API_VERSION_ERROR | API版本低于10，不支持accessibilityGroup | 检查设备API版本，使用降级方案accessibilityLevel |
| COMPONENT_STRUCTURE_ERROR | 组件结构不符合要求（无子组件） | 确认组件包含多个子组件后再设置accessibilityGroup |
| TEXT_CONFLICT_ERROR | accessibilityText与子组件文本冲突 | 明确朗读需求，选择拼接文本或自定义文本 |
| ACCESSIBILITY_LEVEL_CONFLICT | 子组件accessibilityLevel为"yes"导致无法合并 | 移除子组件的accessibilityLevel设置，或设置为"auto"/"no" |
| SYSTEM_CAPABILITY_ERROR | 设备不支持SystemCapability.ArkUI.ArkUI.Full | 检查设备系统能力，使用替代方案 |
| FOCUS_BEHAVIOR_ERROR | 屏幕朗读焦点行为不符合预期 | 在真机上测试，调整accessibilityGroup和accessibilityText设置 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    // 无需额外依赖，accessibilityGroup和accessibilityText为ArkUI内置属性
  }
}
```

### 环境要求
- HarmonyOS API version：10及以上（accessibilityGroup）
- ArkTS卡片支持：API version 12及以上
- 元服务支持：API version 11及以上
- 系统能力：SystemCapability.ArkUI.ArkUI.Full

### 常见编译问题

**问题1：API版本不兼容**
```
ERROR: Property 'accessibilityGroup' does not exist on type 'Row'
```
**解决方法**：检查项目API版本配置，确保build-profile.json5中的compileSdkVersion >= 10

**问题2：子组件仍可单独聚焦**
```
屏幕朗读时，子组件仍然可以获得焦点并单独朗读
```
**解决方法**：确认accessibilityGroup(true)已正确设置，检查子组件是否设置了accessibilityLevel("yes")

**问题3：重复朗读问题未解决**
```
设置accessibilityGroup后，朗读内容仍然重复
```
**解决方法**：检查是否同时设置了accessibilityText和子组件文本，确认朗读优先级规则

**问题4：卡片中使用报错**
```
ERROR: accessibilityGroup is not supported in ArkTS Card
```
**解决方法**：升级API version至12以上，或使用降级方案

## 常见问题与解决方法

### Q1：如何判断是否需要使用accessibilityGroup？
**原因**：并非所有嵌套组件都需要合并
**解决方法**：
- 分析子组件是否独立可交互（如按钮、链接）
- 判断子组件朗读内容是否与父组件重复或互补
- 若子组件独立有意义（如列表项），不建议合并
- 若子组件仅为父组件的信息补充（如时间+地点），建议合并

### Q2：子组件设置了accessibilityLevel("yes")，为什么还能单独聚焦？
**原因**：accessibilityLevel("yes")会覆盖accessibilityGroup的约束
**解决方法**：
- 若希望子组件不单独聚焦，移除accessibilityLevel设置或设置为"auto"/"no"
- 若子组件确实需要独立聚焦（如卡片中的操作按钮），保持accessibilityLevel("yes")

### Q3：设置了accessibilityText，为什么屏幕朗读不播报？
**原因**：可能存在配置冲突或API版本问题
**解决方法**：
- 确认accessibilityGroup(true)已设置（否则accessibilityText不会生效）
- 确认组件没有文本属性（若有文本属性，accessibilityText优先级更高）
- 检查API版本是否支持（API version 10+）
- 在真机上测试屏幕朗读功能

### Q4：如何优先拼接子组件的accessibilityText？
**原因**：默认拼接子组件的文本属性，不拼接accessibilityText
**解决方法**：
- 使用accessibilityGroup(true, { accessibilityPreferred: true })
- 为子组件设置accessibilityText
- API version 14+支持此功能

### Q5：accessibilityGroup在卡片中无法使用怎么办？
**原因**：卡片环境可能API版本较低
**解决方法**：
- 检查卡片API版本，确保 >= 12
- 若版本较低，使用降级方案：
  - 父组件设置accessibilityText
  - 子组件设置accessibilityLevel("no")

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "optimizationType": "multidimensional-nesting",
  "componentStructure": {
    "parentComponent": "Row",
    "childComponents": ["Text", "Text"],
    "merged": true
  },
  "accessibilitySettings": {
    "accessibilityGroup": true,
    "accessibilityText": "自定义文本或拼接文本",
    "childAccessibilityLevel": "auto"
  },
  "expectedBehavior": "父组件获得焦点，朗读合并内容，子组件不再单独聚焦",
  "apiUsed": [
    "accessibilityGroup",
    "accessibilityText"
  ],
  "apiVersion": "10+",
  "recommendations": [
    "在真机上测试屏幕朗读效果",
    "根据实际需求调整accessibilityText内容",
    "确保子组件没有独立的交互需求"
  ]
}
```

## 参考文档

- [多维嵌套场景开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/scenario-multidimensional-nesting)
- [无障碍属性API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-universal-attributes-accessibility)

## 完整示例代码

- [天气卡片示例](assets/weather-card-example.ets)
- [新闻卡片示例](assets/news-card-example.ets)
- [商品卡片示例](assets/product-card-example.ets)

## 测试用例

### 正向测试用例
- [天气卡片合并朗读](tests/test_weather_card.py)：测试时间+地点信息合并朗读
- [新闻卡片优化](tests/test_news_card.py)：测试标题+来源合并朗读
- [自定义文本设置](tests/test_custom_text.py)：测试accessibilityText优先级

### 边界测试用例
- [空子组件测试](tests/test_empty_children.py)：测试无子组件时的行为
- [多层级嵌套](tests/test_multi_level.py)：测试超过3层嵌套的性能
- [大量子组件](tests/test_many_children.py)：测试超过10个子组件的表现

### 异常测试用例
- [API版本不足](tests/test_low_api_version.py)：测试API version < 10的降级方案
- [子组件独立聚焦](tests/test_independent_child.py)：测试子组件需要独立交互的场景
- [文本冲突处理](tests/test_text_conflict.py)：测试accessibilityText与子组件文本冲突的处理