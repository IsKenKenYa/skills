# 测试用例：多维嵌套场景无障碍优化

## 正向测试用例

### 测试1：天气卡片合并朗读测试

**测试目的**：验证accessibilityGroup(true)能够正确合并子组件，避免重复朗读

**测试步骤**：
1. 创建包含时间信息和位置信息的天气卡片组件
2. 为Row容器设置accessibilityGroup(true)
3. 启用屏幕朗读功能
4. 导航至天气卡片
5. 观察焦点行为和朗读内容

**预期结果**：
- Row容器获得焦点时，朗读内容为："07:05 Moscow"（拼接子组件文本）
- 子组件Text不再单独可聚焦
- 无重复朗读现象

**测试代码**：
```typescript
Row() {
  Text('07:05')
    .fontSize(32)
    .fontColor(Color.Red)
    .fontWeight(FontWeight.Bold)
    .margin({ right: 20 })
  
  Text('Moscow')
    .fontSize(20)
    .fontColor(Color.Green)
    .fontWeight(FontWeight.Bold)
}
.accessibilityGroup(true)
```

**验证方法**：
- 使用屏幕朗读服务（如TalkBack）进行手动测试
- 记录朗读内容和焦点切换顺序
- 确认无重复朗读

### 测试2：自定义accessibilityText优先级测试

**测试目的**：验证accessibilityText优先级高于拼接文本

**测试步骤**：
1. 创建复合组件，包含多个子组件文本
2. 设置accessibilityGroup(true)
3. 设置accessibilityText为自定义文本
4. 启用屏幕朗读功能
5. 观察朗读内容

**预期结果**：
- 父组件获得焦点时，朗读内容为accessibilityText设置的文本
- 不朗读子组件拼接文本
- 自定义文本优先级最高

**测试代码**：
```typescript
Row() {
  Text('￥99')
    .fontSize(24)
    .fontColor(Color.Orange)
  
  Text('会员专享')
    .fontSize(16)
    .fontColor(Color.Gray)
}
.accessibilityGroup(true)
.accessibilityText('会员价格99元')
```

**验证方法**：
- 屏幕朗读应播报："会员价格99元"
- 不播报"￥99 会员专享"

### 测试3：新闻卡片复合信息测试

**测试目的**：验证复杂嵌套组件的合并朗读效果

**测试步骤**：
1. 创建新闻卡片，包含标题、来源、时间、摘要
2. 使用Column作为容器，设置accessibilityGroup(true)
3. 设置accessibilityText为完整描述
4. 测试屏幕朗读效果

**预期结果**：
- 新闻卡片作为一个整体获得焦点
- 朗读内容清晰、完整
- 无冗余信息重复朗读

**测试代码**：
```typescript
Column() {
  Text('HarmonyOS 5.0 Released')
    .fontSize(18)
    .fontWeight(FontWeight.Bold)
  
  Row() {
    Text('TechNews')
      .fontSize(14)
      .fontColor(Color.Gray)
    
    Text('2026-07-02')
      .fontSize(14)
      .fontColor(Color.Gray)
  }
  
  Text('Huawei announced...')
    .fontSize(14)
}
.accessibilityGroup(true)
.accessibilityText('News: HarmonyOS 5.0 Released by TechNews on 2026-07-02')
```

## 边界测试用例

### 测试4：空子组件测试

**测试目的**：验证无子组件时accessibilityGroup的行为

**测试步骤**：
1. 创建不包含子组件的容器
2. 设置accessibilityGroup(true)
3. 测试屏幕朗读焦点行为

**预期结果**：
- 容器可获得焦点
- 若有accessibilityText，朗读该文本
- 若无文本和accessibilityText，不朗读任何内容

**测试代码**：
```typescript
Row()
  .height(50)
  .accessibilityGroup(true)
  .accessibilityText('Empty container')
```

### 测试5：多层级嵌套测试

**测试目的**：验证超过3层嵌套的性能和朗读效果

**测试步骤**：
1. 创建4层嵌套的组件结构
2. 在最外层设置accessibilityGroup(true)
3. 测试焦点行为和朗读性能

**预期结果**：
- 最外层容器获得焦点
- 所有嵌套子组件文本被正确拼接
- 朗读流畅，无明显延迟

**测试代码**：
```typescript
Column() {
  Row() {
    Column() {
      Text('Level 4')
      Text('Level 4-2')
    }
    Text('Level 3')
  }
  Text('Level 2')
}
.accessibilityGroup(true)
```

**注意事项**：
- 嵌套层级过深可能导致性能问题
- 建议控制在3层以内

### 测试6：大量子组件测试

**测试目的**：验证超过10个子组件的性能表现

**测试步骤**：
1. 创建包含15个子组件的容器
2. 设置accessibilityGroup(true)
3. 测试文本拼接和朗读性能

**预期结果**：
- 所有子组件文本被正确拼接
- 朗读时长合理（不超过10秒）
- 无明显性能下降

**测试代码**：
```typescript
Column() {
  ForEach([1, 2, 3, ..., 15], (item: number) => {
    Text(`Item ${item}`)
  })
}
.accessibilityGroup(true)
```

**注意事项**：
- 子组件过多可能导致朗读时长过长
- 建议使用accessibilityText提供精简描述

## 异常测试用例

### 测试7：API版本不足测试

**测试目的**：验证API version < 10时的降级处理

**测试步骤**：
1. 在API version < 10的环境中编译代码
2. 使用accessibilityGroup属性
3. 观察编译错误和运行行为

**预期结果**：
- 编译报错：Property 'accessibilityGroup' does not exist
- 需要使用降级方案：accessibilityLevel

**降级方案代码**：
```typescript
Row() {
  Text('Time')
    .accessibilityLevel('no')
  
  Text('Location')
    .accessibilityLevel('no')
}
.accessibilityText('Time and Location')
.accessibilityLevel('yes')
```

### 测试8：子组件独立聚焦冲突测试

**测试目的**：验证子组件accessibilityLevel("yes")导致的合并失败

**测试步骤**：
1. 创建父组件，设置accessibilityGroup(true)
2. 子组件设置accessibilityLevel("yes")
3. 测试屏幕朗读焦点行为

**预期结果**：
- 子组件仍然可单独聚焦
- 父组件也可聚焦，朗读拼接文本
- 存在重复朗读风险

**测试代码**：
```typescript
Row() {
  Text('Time')
    .accessibilityLevel('yes')  // 冲突设置
  
  Text('Location')
}
.accessibilityGroup(true)
```

**解决方法**：
- 移除子组件的accessibilityLevel设置
- 或设置accessibilityLevel为"auto"/"no"

### 测试9：文本冲突处理测试

**测试目的**：验证accessibilityText与子组件文本的优先级关系

**测试步骤**：
1. 创建包含文本属性的组件
2. 设置accessibilityGroup(true)
3. 同时设置accessibilityText
4. 测试朗读内容

**预期结果**：
- accessibilityText优先级最高
- 不朗读组件原有文本属性
- 只朗读accessibilityText内容

**测试代码**：
```typescript
Text('Original Text')
  .accessibilityGroup(true)
  .accessibilityText('Override Text')
```

**验证方法**：
- 屏幕朗读应播报："Override Text"
- 不播报"Original Text"

### 测试10：卡片环境兼容性测试

**测试目的**：验证ArkTS卡片中accessibilityGroup的可用性

**测试步骤**：
1. 创建ArkTS卡片项目
2. 使用accessibilityGroup属性
3. 测试API version 12+和12-的行为差异

**预期结果**：
- API version 12+：正常使用accessibilityGroup
- API version 12-：编译错误，需使用降级方案

**测试代码**：
```typescript
// API version 12+
Row() {
  Text('Card Content')
}
.accessibilityGroup(true)

// API version 12- 降级方案
Row() {
  Text('Card Content')
    .accessibilityLevel('no')
}
.accessibilityText('Card Content')
```

## 测试报告模板

### 测试执行记录

```json
{
  "testId": "test_weather_card",
  "testType": "positive",
  "testDate": "2026-07-02",
  "deviceInfo": {
    "model": "Huawei Mate 60",
    "apiVersion": 12,
    "systemCapability": "SystemCapability.ArkUI.ArkUI.Full"
  },
  "testSteps": [
    "1. 创建天气卡片组件",
    "2. 设置accessibilityGroup(true)",
    "3. 启用屏幕朗读",
    "4. 导航至组件",
    "5. 观察朗读行为"
  ],
  "actualResult": {
    "focusBehavior": "父组件获得焦点",
    "speechContent": "07:05 Moscow",
    "childFocusable": false,
    "noDuplication": true
  },
  "expectedResult": {
    "focusBehavior": "父组件获得焦点",
    "speechContent": "07:05 Moscow",
    "childFocusable": false,
    "noDuplication": true
  },
  "testStatus": "pass",
  "notes": "测试通过，无重复朗读现象"
}
```

## 测试环境要求

- HarmonyOS设备（API version 10+）
- 屏幕朗读服务（TalkBack或类似服务）
- ArkTS开发环境（DevEco Studio）
- 真机测试设备（避免仅使用模拟器）

## 测试注意事项

1. 所有测试应在真机上进行，模拟器的屏幕朗读功能可能不准确
2. 测试前需启用设备的屏幕朗读服务
3. 记录详细的朗读内容和焦点切换顺序
4. 测试不同API版本的行为差异
5. 测试不同组件类型的表现
6. 关注性能指标，如朗读时长、焦点切换速度