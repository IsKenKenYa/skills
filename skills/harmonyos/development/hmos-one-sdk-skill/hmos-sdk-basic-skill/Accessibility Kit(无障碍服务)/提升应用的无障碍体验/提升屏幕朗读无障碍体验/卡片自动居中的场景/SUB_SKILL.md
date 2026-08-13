---
name: hmos-accessibility-kit-card-auto-center
description: 实现卡片自动居中显示功能,通过LazyForEach或ForEach获取索引并在无障碍聚焦回调中调用scrollToIndex实现居中滚动,支持横向滚动容器,适用于屏幕朗读无障碍场景,最大支持1000个卡片项
---

# 卡片自动居中技能

## 功能描述

本技能实现横向滚动容器中卡片的无障碍自动居中显示功能。当使用屏幕朗读模式时,卡片获得焦点后会自动居中显示,以凸显其重要性并提供更好的无障碍体验。通过LazyForEach或ForEach获取卡片索引,在可聚焦的卡片控件上注册无障碍聚焦回调函数onAccessibilityFocus,在回调函数中调用滚动容器的scrollToIndex接口并指定卡片索引和居中对齐方式ScrollAlign.CENTER,将聚焦的卡片控件居中显示。

## 使用场景

### 触发词
- "卡片自动居中"
- "无障碍卡片居中"
- "屏幕朗读卡片聚焦"
- "横向滚动卡片居中"
- "无障碍滚动定位"

### 能做
- 实现横向滚动容器中卡片的无障碍自动居中显示
- 通过LazyForEach或ForEach获取卡片索引
- 注册无障碍聚焦回调函数onAccessibilityFocus
- 调用scrollToIndex接口实现卡片居中滚动
- 支持设置scrollSnapAlign为居中对齐
- 支持屏幕朗读模式下的无障碍体验优化

### 绝不做
- 不处理竖向滚动容器的卡片居中(仅支持横向)
- 不处理非无障碍模式下的卡片聚焦
- 不实现卡片的自动选中或自动点击功能
- 不处理卡片内容的动态加载逻辑
- 不处理卡片的拖拽排序功能

### 补充
- 需要配合LazyForEach或ForEach使用以获取卡片索引
- 需要设置scrollSnapAlign为ScrollSnapAlign.CENTER以实现居中限位
- scrollToIndex的align参数需要设置为ScrollAlign.CENTER
- 卡片需要设置onClick事件以保证可被无障碍聚焦
- 建议卡片宽度设置为百分比(如'60%')以突出显示效果

## 调用规范和规则

### 输入约束
- 卡片数量:最大1000个卡片项
- 卡片宽度:建议设置为'60%'到'80%'
- List组件宽度:建议设置为'90%'
- 滚动方向:必须设置为Axis.Horizontal(横向)
- space参数:建议设置为20vp

### 执行约束
- 最大耗时:scrollToIndex调用耗时不超过500ms
- 最大迭代次数:LazyForEach或ForEach循环次数不超过1000次
- API调用频次:无障碍聚焦回调函数调用频次不超过每秒10次
- smooth参数:建议设置为false以提高性能

### 内容约束
- 禁止生成:不生成竖向滚动容器代码
- 禁止使用高危函数:不使用JSON.stringify(可能导致性能问题)
- 禁止操作:不直接操作DOM或修改原生组件结构
- 禁止省略:keyGenerator函数不能省略(建议提供唯一键值)

### 降级约束
- 网络失败:不适用(本地组件操作)
- 文件过大:卡片数量超过1000时提示用户减少卡片数量
- 权限不足:无障碍功能需要在系统设置中开启,未开启时提示用户开启无障碍模式
- API版本不支持:onAccessibilityFocus需要API version 18及以上,低于该版本时提示用户升级系统

## 调用流程和步骤

### 步骤1:准备阶段

**前置校验**:
1. 确认系统API版本是否支持onAccessibilityFocus(API version 18及以上)
2. 确认滚动容器方向是否为横向(Axis.Horizontal)
3. 确认scrollSnapAlign是否设置为ScrollSnapAlign.CENTER
4. 确认卡片是否设置了onClick事件以确保可聚焦

**参数准备**:
```typescript
// ArkTS示例
class ListDataSource implements IDataSource {
  private list: number[] = [];
  constructor(list: number[]) {
    this.list = list;
  }
  totalCount(): number {
    return this.list.length;
  }
  getData(index: number): number {
    return this.list[index];
  }
  registerDataChangeListener(listener: DataChangeListener): void {
  }
  unregisterDataChangeListener(listener: DataChangeListener): void {
  }
}

@Entry
@Component
struct CardAutoCenterComponent {
  private arr: ListDataSource = new ListDataSource([0, 1, 2, 3, 4, 5, 6, 7, 8, 9]);
  private scrollerForList: Scroller = new Scroller();
}
```

### 步骤2:调用API

**示例代码**:
```typescript
// 导入必要模块(已在ArkTS环境中)
// 实现卡片自动居中功能
build() {
  NavDestination() {
    Column() {
      List({ space: 20, initialIndex: 0, scroller: this.scrollerForList }) {
        LazyForEach(this.arr, (index: number) => {
          ListItem() {
            Text('' + index)
              .width('100%')
              .height(100)
              .fontSize(16)
              .textAlign(TextAlign.Center)
              .borderRadius(10)
              .backgroundColor(0xFFFFFF)
          }
          .width('60%') // 设置卡片宽度占比
          .onClick(() => {
            // 设置点击事件,使组件可被无障碍聚焦
          })
          // 设置无障碍聚焦回调
          .onAccessibilityFocus((isFocus: boolean) => {
            if (isFocus) {
              // 如果聚焦则滚动List,使当前的ListItem居中
              this.scrollerForList.scrollToIndex(index, false, ScrollAlign.CENTER)
            }
          })
        }, (item: string) => item)
      }
      .width('90%')
      .scrollBar(BarState.Off)
      .scrollSnapAlign(ScrollSnapAlign.CENTER) // 设置居中对齐
      .listDirection(Axis.Horizontal) // 设置横向List
    }
    .width('100%')
    .height('100%')
    .backgroundColor(0xDCDCDC)
    .padding({ top: 5 })
  }
}
```

### 步骤3:错误处理

```typescript
// 错误处理代码
.onAccessibilityFocus((isFocus: boolean) => {
  try {
    if (isFocus) {
      // 校验索引是否有效
      if (index >= 0 && index < this.arr.totalCount()) {
        this.scrollerForList.scrollToIndex(index, false, ScrollAlign.CENTER)
      } else {
        console.error('Invalid card index: ' + index)
      }
    }
  } catch (error) {
    console.error('scrollToIndex failed:', error.message)
  }
})
```

### 步骤4:降级处理

```typescript
// 降级处理代码
.onAccessibilityFocus((isFocus: boolean) => {
  if (isFocus) {
    try {
      // 尝试居中滚动
      this.scrollerForList.scrollToIndex(index, false, ScrollAlign.CENTER)
    } catch (error) {
      // 降级方案:使用START对齐方式
      console.warn('CENTER alignment failed, fallback to START alignment')
      this.scrollerForList.scrollToIndex(index, false, ScrollAlign.START)
    }
  }
})
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| INVALID_INDEX | 索引值超出范围(负数或大于最大索引) | 校验索引值在[0, totalCount()-1]范围内 |
| SCROLL_FAILED | scrollToIndex调用失败 | 检查Scroller是否正确绑定到List组件 |
| API_NOT_SUPPORTED | API版本不支持onAccessibilityFocus | 升级系统到API version 18及以上 |
| ALIGNMENT_FAILED | 居中对齐失败 | 降级使用ScrollAlign.START对齐方式 |
| COMPONENT_NOT_FOCUSABLE | 卡片组件不可聚焦 | 确保卡片设置了onClick事件 |
| SCROLLER_NOT_BOUND | Scroller未绑定到List组件 | 在List构造函数中传入scroller参数 |
| LAZYFOREACH_ERROR | LazyForEach数据源错误 | 检查IDataSource接口实现是否正确 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@ohos/arkui": "^1.0.0"
  }
}
```

### 环境要求
- HarmonyOS系统:API version 18及以上
- DevEco Studio:最新版本
- ArkTS编译器:支持ArkUI组件

### 常见编译问题

**问题1:找不到IDataSource接口定义**
```
Error: Cannot find name 'IDataSource'
```
**解决方法**:确保项目中已导入@ohos/arkui模块,IDataSource接口在ArkUI框架中定义

**问题2:onAccessibilityFocus未定义**
```
Error: Property 'onAccessibilityFocus' does not exist on type 'ListItem'
```
**解决方法**:升级系统到API version 18及以上,onAccessibilityFocus从API version 18开始支持

**问题3:ScrollAlign.CENTER未定义**
```
Error: Cannot find name 'ScrollAlign'
```
**解决方法**:导入ScrollAlign枚举,或使用完整路径ScrollAlign.CENTER

**问题4:Scroller.scrollToIndex参数错误**
```
Error: Expected 1-2 arguments, but got 3
```
**解决方法**:scrollToIndex从API version 7开始支持3个参数(value, smooth, align),确保使用正确的API版本

## 常见问题与解决方法

### Q1:卡片聚焦后没有自动居中
**原因**:scrollToIndex未调用或参数设置错误
**解决方法**:
- 检查onAccessibilityFocus回调是否正确注册
- 确认isFocus参数为true时才调用scrollToIndex
- 校验scrollToIndex的align参数设置为ScrollAlign.CENTER
- 确认Scroller已正确绑定到List组件

### Q2:卡片居中位置不准确
**原因**:卡片宽度设置不合理或scrollSnapAlign未设置
**解决方法**:
- 设置卡片宽度为'60%'以突出居中效果
- 设置List的scrollSnapAlign为ScrollSnapAlign.CENTER
- 调整List的space参数(建议20vp)
- 确认List组件宽度设置为'90%'

### Q3:LazyForEach性能问题导致滚动卡顿
**原因**:getData或keyGenerator函数执行耗时操作
**解决方法**:
- 避免在getData函数中使用JSON.stringify
- 提供高效的keyGenerator函数(使用简单字符串拼接)
- 控制卡片数量不超过1000个
- 使用组件复用机制优化性能

### Q4:无障碍模式下卡片无法聚焦
**原因**:卡片未设置onClick事件或系统未开启无障碍模式
**解决方法**:
- 确保ListItem设置了onClick事件
- 检查系统设置中无障碍模式是否开启
- 使用accessibilityLevel属性设置为"auto"或"important"
- 检查组件的enabled属性是否为true

### Q5:scrollToIndex调用失败导致卡片不滚动
**原因**:索引值超出范围或Scroller未正确绑定
**解决方法**:
- 校验索引值在[0, totalCount()-1]范围内
- 确保Scroller在List构造函数中正确传入
- 检查List组件是否正确创建和布局
- 使用try-catch捕获错误并降级处理

## 输出结果报告

执行完成后输出以下信息:

```json
{
  "status": "success",
  "componentType": "List",
  "scrollDirection": "Axis.Horizontal",
  "alignmentMode": "ScrollAlign.CENTER",
  "snapAlignment": "ScrollSnapAlign.CENTER",
  "cardCount": "number",
  "apiUsed": [
    "LazyForEach",
    "IDataSource",
    "Scroller.scrollToIndex",
    "onAccessibilityFocus",
    "ScrollAlign.CENTER",
    "ScrollSnapAlign.CENTER"
  ],
  "apiVersion": "API version 18+",
  "accessibilityEnabled": "boolean"
}
```

## 参考文档

- [卡片自动居中的场景](references/scenario-card-automatically-centered.md)
- [ForEach API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-rendering-control-foreach)
- [LazyForEach API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-rendering-control-lazyforeach)
- [onAccessibilityFocus API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-universal-accessibility-event)
- [Scroller.scrollToIndex API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-container-scroll#scrolltoindex)
- [List组件参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-container-list)

## 完整示例代码

- [ArkTS示例代码](assets/card-auto-center-example.ets)
- [IDataSource实现示例](assets/list-datasource-example.ets)
- [完整组件示例](assets/card-auto-center-component.ets)

## 测试用例

### 正向测试用例
- [卡片聚焦自动居中](tests/test_card_focus_center.ets):测试卡片获得焦点后是否自动居中显示
- [多卡片连续聚焦](tests/test_multi_card_focus.ets):测试多个卡片连续聚焦时的居中滚动效果
- [边界卡片聚焦](tests/test_boundary_card_focus.ets):测试第一个和最后一个卡片聚焦时的居中效果

### 边界测试用例
- [最大卡片数量测试](tests/test_max_card_count.ets):测试1000个卡片时的性能和居中效果
- [索引边界测试](tests/test_index_boundary.ets):测试索引值为0和最大值时的scrollToIndex调用
- [最小卡片数量测试](tests/test_min_card_count.ets):测试只有1个卡片时的聚焦和居中效果

### 异常测试用例
- [无效索引测试](tests/test_invalid_index.ets):测试索引值为负数或超出范围时的错误处理
- [API版本不兼容测试](tests/test_api_version_incompatible.ets):测试API version低于18时的降级处理
- [Scroller未绑定测试](tests/test_scroller_not_bound.ets):测试Scroller未正确绑定时的错误处理