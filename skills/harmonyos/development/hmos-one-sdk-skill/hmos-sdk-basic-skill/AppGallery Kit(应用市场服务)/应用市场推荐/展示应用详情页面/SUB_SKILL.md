---
name: hmos-appgallery-kit-productview-loadproduct
description: 展示应用详情页面,支持应用内调用loadProduct接口或在网页嵌入跳转链接,用户可直接进入应用详情页下载应用,仅支持真机调试,适用于Phone/Tablet/PC/2in1/TV设备,适用于应用推荐、应用下载场景
---

# 展示应用详情页面技能

## 功能描述

通过应用内调用loadProduct接口或在网页嵌入跳转链接的方式,展示应用详情页面,用户可直接进入应用详情页,简化应用下载流程,增加应用的下载量和用户活跃度。支持应用内打开应用市场App(loadProduct方式)和Web页面打开应用市场App(App Linking链接方式)。

**核心能力**:
- 展示指定应用的详情页面
- 支持应用归因数据传递(SKExposure)
- 提供页面打开/关闭状态回调
- 支持Deep Linking和App Linking两种跳转方式

**技术特点**:
- 仅支持Stage模型
- 不支持模拟器,必须使用真机调试
- 支持Phone/Tablet/PC/2in1设备,6.0.2(22)版本开始支持TV设备
- API起始版本:4.1.0(11)

## 使用场景

### 触发词
- "展示应用详情页" - 打开应用市场应用详情页面
- "loadProduct" - 使用loadProduct接口展示应用详情
- "应用市场详情页" - 拉起应用市场查看应用详情
- "AppGallery详情页" - 打开AppGallery应用详情页面
- "应用推荐下载" - 推荐应用并引导用户下载

### 能做
- 展示指定包名的应用详情页面
- 传递应用归因来源数据(SKExposure)用于广告归因分析
- 监听应用详情页的打开、关闭、错误状态
- 通过Deep Linking或App Linking方式拉起应用市场
- 简化应用下载流程,提升用户转化率

### 绝不做
- 不支持在模拟器上运行(会提示"无法获取内容,请点击屏幕重试")
- 不支持拉起非应用市场的应用详情页
- 不支持在API version < 4.1.0(11)的环境中使用
- 不支持在非Stage模型中使用
- 不处理应用安装后的后续逻辑(仅展示详情页)

### 补充
- 推荐应用场景优先使用loadProduct方式,Web页面场景推荐使用App Linking链接方式
- 从6.0.2(22)版本开始新增支持TV设备
- 如果需要传递归因数据,必须提供完整的SKExposure对象
- 真机调试时确保已安装华为应用市场App

## 调用规范和规则

### 输入约束
- **bundleName**:必填,应用包名,字符串类型,格式为'com.xxx.xxx'
- **context**:必填,UIAbilityContext对象,通过getUIContext().getHostContext()获取
- **want**:必填,Want对象,parameters中必须包含bundleName字段
- **callback**:可选,ProductViewCallback对象,包含onError/onAppear/onDisappear回调
- **skExposure**:可选,SKExposure对象,用于传递归因数据(广告场景必填)

### 执行约束
- 最大耗时:无明确限制,依赖应用市场响应速度
- 最大迭代次数:单次调用,无迭代
- API调用频次:无明确限制
- 必须在主线程调用
- 必须使用真机调试

### 内容约束
- 禁止生成:非应用市场的应用详情页跳转逻辑
- 禁止使用高危函数:无
- 禁止操作:在模拟器环境调用、在API version < 4.1.0环境调用
- bundleName必须是真实存在的应用包名

### 降级约束
- 真机调试失败:提示用户"无法获取内容,请点击屏幕重试"
- 参数错误(401):检查bundleName、context、want参数是否正确
- 设备不支持:检查设备类型是否为Phone/Tablet/PC/2in1/TV
- 应用市场未安装:提示用户安装华为应用市场App
- Deep Linking失败:降级使用App Linking方式

## 调用流程和步骤

### 步骤1:准备阶段

**前置校验**:
1. 验证设备类型是否支持(Phone/Tablet/PC/2in1/TV)
2. 验证API版本 >= 4.1.0(11)
3. 验证运行环境为真机(非模拟器)
4. 验证应用市场App已安装

**参数准备**:
```typescript
// 导入必要模块
import { productViewManager } from '@kit.AppGalleryKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import type { common, Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

// 准备归因数据(可选,广告场景必填)
const exposureData: productViewManager.SKExposure = {
  adTechId: '20****e8',        // 分发平台归因角色ID,长度固定8字符
  campaignId: '123456',         // 营销任务ID,长度不超过9字符
  destinationId: '10******',    // 应用AppId,长度不超过64字符
  mmpIds: ['2f****5', '2f7***5'], // 归因监测平台ID,最多2个,每个8字符
  serviceTag: '123***2',        // 业务信息,长度不超过32字符
  nonce: '123***2',             // 随机数,长度固定32字符,不带'-'
  timestamp: 1705536488,        // unix时间戳,单位毫秒
  signature: 'MEQCIEQlmZ****'   // 签名值,长度不超过800字符
};

// 准备Want参数
const wantParam: Want = {
  parameters: {
    bundleName: 'com.xxx',      // 必填,应用包名
    skExposure: exposureData     // 可选,归因数据
  }
};

// 准备回调函数
const callback: productViewManager.ProductViewCallback = {
  onError: (error: BusinessError) => {
    hilog.error(0, 'TAG', `loadProduct onError.code is ${error.code}, message is ${error.message}`);
  },
  onAppear: () => {
    hilog.info(0, 'TAG', `loadProduct onAppear.`);
  },
  onDisappear: () => {
    hilog.info(0, 'TAG', `loadProduct onDisappear.`);
  }
};
```

### 步骤2:调用API

**示例代码(loadProduct方式)**:
```typescript
@Entry
@Component
struct LoadProductView {
  @State message: string = '拉起应用市场详情页';
  
  build() {
    Row() {
      Column() {
        Button(this.message)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .onClick(() => {
            try {
              // 获取UIAbilityContext
              const uiContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
              
              // 构造Want参数
              const wantParam: Want = {
                parameters: {
                  bundleName: 'com.xxx',  // 必填,应用包名,如'com.huawei.hmsapp.books'
                  skExposure: exposureData // 可选,归因数据
                }
              };
              
              // 构造回调函数
              const callback: productViewManager.ProductViewCallback = {
                onError: (error: BusinessError) => {
                  hilog.error(0, 'TAG', `loadProduct onError.code is ${error.code}, message is ${error.message}`);
                },
                onAppear: () => {
                  hilog.info(0, 'TAG', `loadProduct onAppear.`);
                },
                onDisappear: () => {
                  hilog.info(0, 'TAG', `loadProduct onDisappear.`);
                }
              };
              
              // 调用loadProduct接口
              productViewManager.loadProduct(uiContext, wantParam, callback);
            } catch (err) {
              hilog.error(0, 'TAG', `loadProduct failed.code is ${err.code}, message is ${err.message}`);
            }
          })
          .width('100%')
      }
      .height('100%')
    }
  }
}
```

**示例代码(Deep Linking方式)**:
```typescript
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import type { common, Want } from '@kit.AbilityKit';

// 拉起应用市场对应的应用详情页面
function startAppGalleryDetailAbility(context: common.UIAbilityContext, bundleName: string): void {
  let want: Want = {
    action: 'ohos.want.action.appdetail',  // 隐式指定action
    uri: 'store://appgallery.huawei.com/app/detail?id=' + bundleName,  // bundleName为应用包名
  };
  
  context.startAbility(want).then(() => {
    hilog.info(0x0001, 'TAG', "Succeeded in starting Ability successfully.");
  }).catch((error: BusinessError) => {
    hilog.error(0x0001, 'TAG', `Failed to startAbility.Code: ${error.code}, message is ${error.message}`);
  });
}

@Entry
@Component
struct StartAppGalleryDetailAbilityView {
  @State message: string = '拉起应用市场详情页';
  
  build() {
    Row() {
      Column() {
        Button(this.message)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .onClick(() => {
            const context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
            const bundleName = 'com.xxx';  // 应用包名,如'com.huawei.hmsapp.books'
            startAppGalleryDetailAbility(context, bundleName);
          })
      }
      .width('100%')
    }
    .height('100%')
  }
}
```

**示例代码(App Linking方式)**:
```typescript
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import type { common } from '@kit.AbilityKit';

@Entry
@Component
struct Index {
  build() {
    Button('start app linking', { type: ButtonType.Capsule, stateEffect: true })
      .width('87%')
      .height('5%')
      .margin({ bottom: '12vp' })
      .onClick(() => {
        let context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
        let bundleName: string = 'com.xxx';  // 应用包名,如'com.huawei.hmsapp.books'
        let link: string = 'https://appgallery.huawei.com/app/detail?id=' + bundleName;
        
        // 以App Linking优先的方式在应用市场打开指定包名的应用详情页
        context.openLink(link, { appLinkingOnly: false })
          .then(() => {
            hilog.info(0x0001, 'TAG', 'openlink success.');
          })
          .catch((error: BusinessError) => {
            hilog.error(0x0001, 'TAG', `openlink failed. Code: ${error.code}, message is ${error.message}`);
          });
      })
  }
}
```

### 步骤3:错误处理

```typescript
try {
  productViewManager.loadProduct(uiContext, wantParam, callback);
} catch (error) {
  const err = error as BusinessError;
  switch (err.code) {
    case 401:
      hilog.error(0, 'TAG', 'Parameter error. Possible causes: 1.Mandatory parameters are left unspecified. 2.Incorrect parameter types.');
      break;
    case 1011:
      hilog.error(0, 'TAG', '拉起/切前台失败');
      break;
    case 1012:
      hilog.error(0, 'TAG', '切后台失败');
      break;
    case 1013:
      hilog.error(0, 'TAG', '销毁失败');
      break;
    default:
      hilog.error(0, 'TAG', `Unknown error: code ${err.code}, message ${err.message}`);
  }
}
```

### 步骤4:降级处理

```typescript
// 方案1:loadProduct失败时降级使用Deep Linking
async function showAppDetailWithFallback(context: common.UIAbilityContext, bundleName: string): void {
  try {
    // 优先使用loadProduct方式
    const wantParam: Want = {
      parameters: {
        bundleName: bundleName
      }
    };
    productViewManager.loadProduct(context, wantParam, {
      onError: (error: BusinessError) => {
        // loadProduct失败,降级使用Deep Linking
        hilog.warn(0, 'TAG', `loadProduct failed, fallback to Deep Linking`);
        const want: Want = {
          action: 'ohos.want.action.appdetail',
          uri: 'store://appgallery.huawei.com/app/detail?id=' + bundleName,
        };
        context.startAbility(want);
      }
    });
  } catch (err) {
    // loadProduct异常,降级使用App Linking
    hilog.warn(0, 'TAG', `loadProduct exception, fallback to App Linking`);
    let link: string = 'https://appgallery.huawei.com/app/detail?id=' + bundleName;
    context.openLink(link, { appLinkingOnly: false });
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | Parameter error. 参数错误。 | 检查bundleName、context、want参数是否正确填写。bundleName必填,context必须为UIAbilityContext。 |
| 1011 | 拉起/切前台失败。应用详情页拉起失败。 | 检查应用市场App是否已安装,检查bundleName是否正确,检查设备是否支持。 |
| 1012 | 切后台失败。应用详情页切后台失败。 | 检查应用市场App运行状态,尝试重新调用。 |
| 1013 | 销毁失败。应用详情页销毁失败。 | 检查应用市场App运行状态,无需特殊处理。 |
| 16000001 | The specified ability does not exist. Ability不存在。 | 检查bundleName是否为真实存在的应用包名。 |
| 16000011 | The context does not exist. Context不存在。 | 检查UIAbilityContext是否正确获取,确保在UIAbility生命周期内调用。 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.AppGalleryKit": "latest",
    "@kit.AbilityKit": "latest",
    "@kit.BasicServicesKit": "latest",
    "@kit.PerformanceAnalysisKit": "latest"
  }
}
```

### 环境要求
- HarmonyOS API version >= 4.1.0(11)
- Stage模型应用
- 真机设备(Phone/Tablet/PC/2in1/TV)
- 已安装华为应用市场App

### 常见编译问题

**问题1:导入模块失败**
```
Error: Cannot find module '@kit.AppGalleryKit'
```
**解决方法**:确保DevEco Studio版本支持HarmonyOS API 4.1.0(11)及以上,检查sdk版本配置。

**问题2:类型定义错误**
```
Error: Property 'loadProduct' does not exist on type 'productViewManager'
```
**解决方法**:检查API version配置,确保>=4.1.0(11),重新同步项目。

**问题3:UIAbilityContext获取失败**
```
Error: Cannot read property 'getHostContext' of undefined
```
**解决方法**:确保在UIAbility组件的build方法内调用,使用`this.getUIContext().getHostContext()`正确获取context。

## 常见问题与解决方法

### Q1:在模拟器上调用loadProduct提示"无法获取内容,请点击屏幕重试"
**原因**:应用市场推荐服务不支持模拟器,必须使用真机调试。
**解决方法**:
- 使用真机设备进行调试
- 确保真机已安装华为应用市场App
- 检查真机设备类型是否为Phone/Tablet/PC/2in1/TV

### Q2:调用loadProduct返回错误码401
**原因**:参数错误,可能缺少必填参数或参数类型不正确。
**解决方法**:
- 检查bundleName参数是否填写,格式是否正确(如'com.xxx.xxx')
- 检查context参数是否为UIAbilityContext类型
- 检查want.parameters是否包含bundleName字段
- 检查skExposure参数格式是否符合规范(如果传递了归因数据)

### Q3:应用详情页无法打开
**原因**:可能bundleName不存在,或应用市场App未安装。
**解决方法**:
- 确认bundleName是真实存在的应用包名(如'com.huawei.hmsapp.books')
- 确认真机已安装华为应用市场App
- 尝试降级使用Deep Linking或App Linking方式

### Q4:TV设备调用loadProduct无响应
**原因**:6.0.1(21)及之前版本不支持TV设备,会返回401错误码。
**解决方法**:
- 确保系统版本>=6.0.2(22)
- 检查设备类型是否为TV
- 如果版本不支持,提示用户升级系统版本

### Q5:归因数据SKExposure传递失败
**原因**:归因数据格式不符合规范,或缺少必填字段。
**解决方法**:
- 检查adTechId长度是否为8字符
- 检查campaignId长度是否不超过9字符
- 检查destinationId长度是否不超过64字符
- 检查nonce长度是否为32字符,不带'-'
- 检查timestamp是否为unix时间戳(毫秒)
- 检查signature长度是否不超过800字符
- 确保timestamp与当前时间偏差不超过10分钟

## 输出结果报告

执行完成后输出以下信息:

```json
{
  "status": "success",
  "function": "展示应用详情页面",
  "method": "loadProduct",
  "bundleName": "com.xxx",
  "apiUsed": [
    "productViewManager.loadProduct",
    "ProductViewCallback.onError",
    "ProductViewCallback.onAppear",
    "ProductViewCallback.onDisappear"
  ],
  "deviceType": "Phone/Tablet/PC/2in1/TV",
  "apiVersion": "4.1.0(11)"
}
```

## 参考文档

- [API开发指南:展示应用详情页面](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/appgallery-productview-loadproduct)
- [API参考说明:productViewManager](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/store-productviewmanager)
- [API参考说明:UIAbilityContext](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-inner-application-uiabilitycontext)
- [API参考说明:Want](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-app-ability-want)

## 完整示例代码

- [ArkTS示例:loadProduct方式](assets/loadproduct_example.ets)
- [ArkTS示例:Deep Linking方式](assets/deeplinking_example.ets)
- [ArkTS示例:App Linking方式](assets/applinking_example.ets)

## 测试用例

### 正向测试用例
- [测试:正常展示应用详情页](tests/test_positive.ets) - 使用正确的bundleName参数调用loadProduct,验证应用详情页正常打开
- [测试:传递归因数据](tests/test_positive_with_exposure.ets) - 传递完整的SKExposure归因数据,验证归因数据正常传递

### 边界测试用例
- [测试:TV设备支持](tests/test_boundary_tv.ets) - 在TV设备上调用loadProduct,验证6.0.2(22)版本支持TV
- [测试:最小API版本](tests/test_boundary_api_version.ets) - 在API version 4.1.0(11)环境调用,验证最小版本支持

### 异常测试用例
- [测试:参数错误](tests/test_exception_parameter.ets) - 缺少bundleName参数或参数类型错误,验证返回401错误码
- [测试:模拟器环境](tests/test_exception_emulator.ets) - 在模拟器环境调用loadProduct,验证提示"无法获取内容"
- [测试:bundleName不存在](tests/test_exception_invalid_bundlename.ets) - 使用不存在的bundleName,验证错误处理