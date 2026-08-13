# 11. 导航与路由约束

## 规则

| 规则 | 说明 | 错误码 |
|------|------|--------|
| 推荐使用 Navigation + NavDestination | 替代 @ohos.router 和 pageTransition | — |
| Router 页面栈上限 32 | 超过 32 页报错 | **100003** |
| Navigation 默认转场时长不可控 | 弹簧曲线，时长因设备而异。**不要将业务逻辑耦合到默认转场时长** | — |
| 共享元素转场需禁用默认转场 | geometryTransition 时**必须禁用**系统默认转场动画 | — |
| customNavContentTransition 优先级更高 | 同时设置 Navigation 级和 NavDestination 级转场时，Navigation 级优先 | — |
| 未注册 builder 函数 | Navigation 跳转未注册 builder 的页面 | **100005** |
| 无 NavDestination 组件 | Navigation 跳转未包含 NavDestination 的页面 | **100006** |
| pushPath/pushDestination param 禁内联字面量 | `param: { id: 1 }` 是无类型字面量 → **10605038** | **10605038** |
| NavDestination 无 titleMode | titleMode 是 Navigation 专属属性，NavDestination 只有 `.title()` | **10505001** |
| 路由栈读取 | 从 `NavDestinationContext.pathStack` 读取，非 `getPathStack()` | — |
| Dialog 类型 NavDestination 无默认转场 | API 13 前无默认转场动画 | — |

### 参数传递

```ts
// ❌ WRONG -- param 内联字面量
this.stack.pushPath({ name: 'first', param: { id: 1 } })   // 10605038

// ✅ RIGHT -- param 先声明类型再传变量
interface PageParam { id: number }
const p: PageParam = { id: 1 }
this.stack.pushPath({ name: 'first', param: p })
```

### 转场动画约束

| 规则 | 说明 |
|------|------|
| 默认转场时长不可控 | 弹簧曲线，因设备而异，不要把业务逻辑耦合到默认转场时长 |
| geometryTransition 须禁用默认转场 | 否则叠加产生视觉异常 |
| 同时设置 Navigation 级和 NavDestination 级转场 | Navigation 级（customNavContentTransition）优先 |
| pageTransition 已废弃 | 用 Navigation 转场和 Modal 转场 |

---

## 多文件 Navigation 路由架构

**不要把所有页面放在一个文件**。`@ComponentV2 export struct` 支持跨文件导出。

### 方案一：自定义路由表（静态 import，简单项目推荐）

```ts
// PageA.ets
@ComponentV2 export struct PageA {
  @Param navPathStack: NavPathStack = new NavPathStack()
  @Param goodsIdValue: string = ''
  build() { NavDestination() { /* ... */ } }
}

// MainHost.ets
import { PageA } from './PageA'
@Entry @ComponentV2 struct MainHost {
  @Local navPathStackValue: NavPathStack = new NavPathStack()
  @Builder pageMap(name: string, param: Object) {
    if (name === 'PageA') { PageA({ navPathStack: this.navPathStackValue, goodsIdValue: '123' }) }
  }
  build() {
    Navigation(this.navPathStackValue) { /* 首页 */ }.navDestination(this.pageMap)
  }
}
```

### 方案二：系统路由表（无需 import，跨模块项目）

- 配置 `resources/base/profile/router_map.json`
- `module.json5` 添加 `"routerMap": "$profile:router_map"`
- 页面文件导出 `@Builder export function XxxBuilder(): void { XxxPage() }`
- 主文件用 `pushPathByName('PageName', param)` 跳转

**V2 传递 navPathStack**：用 `@Param` 接收父组件传入（非 @Consume）。`@Builder pageMap` 中 `if/else if` 做路由映射合法。

---

## 常见错误对比

| ❌ 错误写法 | ✅ 正确写法 | 说明 |
|------------|-----------|------|
| 使用 `@ohos.router` 做页面跳转 | Navigation + NavDestination | Router 不推荐 |
| 多个页面各自 `@Entry` | 单 Page 应用只有一个 @Entry | 多页面通过 Navigation 管理 |
| Navigation 跳转未注册 builder | 必须在 Navigation 中注册 destination builder | 100005 |
| 使用 `pageTransition` 做页面转场 | Navigation 转场或 Modal 转场 | pageTransition 已废弃 |
| pushPath 的 param 内联字面量 | 先声明 interface 再用 interface 类型变量传递 | 10605038 |
| NavDestination 调用 titleMode | NavDestination 只用 `.title()`，`.titleMode()` 只挂 Navigation | 10505001 |

## 参考

- 废弃接口替换见 [19-deprecated](14-deprecated.md)
- 对话框与半模态见 [12-dialog](09-dialog.md)