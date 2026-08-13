## 12. 导航与路由


> **组件索引**：`Navigation`、`NavPathStack 操作`、`NavDestination`、`Router`

### Navigation

**构造：** `Navigation()`

**属性方法：**

| 方法 | 签名 | 默认值 | 说明 |
|------|------|--------|------|
| .navDestination | `.navDestination(builder)` | — | 路由目标映射 |
| .title | `.title(string \| NavigationCommonTitle \| NavigationCustomTitle)` | — | 标题 |
| .subtitle | `.subtitle(string)` | — | 副标题 |
| .mode | `.mode(NavigationMode)` | Auto | Stack/Split/Auto |
| .navBarHidden | `.navBarHidden(value: boolean)` | false | 隐藏导航栏 |
| .hideTitleBar | `.hideTitleBar(value: boolean)` | false | 隐藏标题栏 |
| .hideToolBar | `.hideToolBar(value: boolean)` | false | 隐藏工具栏 |
| .toolBar | `.toolBar(value: ToolbarConfiguration)` | — | 工具栏 |
| .navBarWidth | `.navBarWidth(value: Length)` | 240vp | 导航栏宽度 |
| .navBarPosition | `.navBarPosition(value: NavBarPosition)` | Start | 导航栏位置 |
| .splitResizable | `.splitResizable(value: boolean)` | false | 分栏可调 |

### NavPathStack 操作

| 方法 | 签名 | 说明 |
|------|------|------|
| pushPath | `pushPath(info: NavPathInfo, options?)` | 压入页面 |
| pushName | `pushName(name, param?, options?)` | 按名称压入 |
| pop | `pop(result?, options?)` | 弹出 |
| replacePath | `replacePath(info, options?)` | 替换 |
| clear | `clear()` | 清空 |
| size | `size: number` | 栈大小 |
| getParent | `getParent(): NavPathStack \| undefined` | 获取父栈 |

### NavDestination

**构造：** `NavDestination()`

**属性方法：**

| 方法 | 签名 | 默认值 | 说明 |
|------|------|--------|------|
| .title | `.title(string \| CustomBuilder)` | — | 标题 |
| .hideTitleBar | `.hideTitleBar(boolean)` | false | 隐藏标题栏 |
| .hideBackButton | `.hideBackButton(boolean)` | false | 隐藏返回键 |
| .backgroundColor | `.backgroundColor(ResourceColor)` | — | 背景色 |

**事件：** `.onShown()` `.onHidden()` `.onBackPressed()`

### Router

| 方法 | 签名 | 说明 |
|------|------|------|
| pushUrl | `router.pushUrl({url, params?})` | 压入页面 |
| replaceUrl | `router.replaceUrl({url, params?})` | 替换当前页 |
| back | `router.back(url?)` | 返回 |
| clear | `router.clear()` | 清空栈 |
| getLength | `router.getLength(): number` | 栈大小 |
| getState | `router.getState(): RouterState` | 当前状态 |

### 典型用法

#### 页面生命周期选择

| 回调 | Pop 回来触发 | 前后台切换触发 | 适用场景 |
|------|:----------:|:-----------:|---------|
| `onWillShow` | ✅ | ❌ | 页面即将显示前的初始化 |
| `onShown` | ✅ | ✅ | **前后台刷新、Pop 回来刷新** |
| `onActive` | ✅ | ❌ | overlay/Sheet 遮挡后恢复 |

> `onPageShow` 是 `@Entry` 根页面回调，感知不到 NavDestination 子页面的 push/pop，从详情页 Pop 返回时不会触发。子页面可见性用 `onShown`。

#### 参数传递与接收

```ts
// 1. 声明参数类型（禁内联字面量 → 10605038）
export interface DetailParams { capsuleId: string }

// 2. 跳转
const p: DetailParams = { capsuleId: '123' }
stack.pushPath({ name: 'Detail', param: p })

// 3. 目标页面接收
@Param navPathStack: NavPathStack = new NavPathStack()
build() {
  NavDestination()
    .onReady((ctx: NavDestinationContext) => {
      const param = ctx.pathInfo.param as DetailParams  // 取参
    })
}
```

#### 编辑页返回确认

```ts
NavDestination()
  .onBackPressed(() => {
    if (this.hasUnsavedChanges) {
      // 拦截返回，弹出确认
      this.getUIContext().showAlertDialog({
        message: '有未保存的修改，确定返回吗？',
        primaryButton: { value: '取消', action: () => {} },
        secondaryButton: { value: '确定返回', action: () => this.navStack.pop() }
      })
      return true
    }
    return false
  })
```
