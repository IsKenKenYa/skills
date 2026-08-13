# API开发指南:展示应用详情页面

通过应用内调用loadProduct接口或者在网页嵌入跳转链接的方式,用户可直接进入应用详情页,简化应用下载流程,增加应用的下载量和用户活跃度。

应用内打开应用市场App,通过应用市场下载推荐应用,推荐使用loadProduct方式;Web页面打开应用市场App,推荐使用App Linking链接方式。

## 业务流程

1. 用户使用打开应用详情页功能。
2. 应用调用AppGallery Kit的loadProduct接口。
3. AppGallery Kit API获取应用传入的信息,生成展示页面。
4. 展示生成的页面给用户使用。

## 约束与限制

- 应用市场推荐服务不支持模拟器,请使用真机调试。在模拟器中使用该服务将会提示:无法获取内容,请点击屏幕重试。
- 应用市场推荐服务支持Phone、Tablet、PC/2in1设备。并且从6.0.2(22)版本开始,新增支持TV设备。

## 接口说明

详细接口说明可参考[接口文档](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/store-productviewmanager)。

| 接口名 | 描述 |
| --- | --- |
| loadProduct(context:common.UIAbilityContext, want:Want, callback?:ProductViewCallback): void | 加载应用详情页面接口。 |

## 开发步骤

### loadProduct接口调用

1. 导入productViewManager模块及相关公共模块。
```typescript
import { productViewManager } from '@kit.AppGalleryKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import type { common, Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
```

2. 构造应用详情页参数。
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
              const exposureData: productViewManager.SKExposure = {
                adTechId: '20****e8',
                campaignId: '123456',
                destinationId: '10******',
                mmpIds: ['2f****5', '2f7***5'],
                serviceTag: '123***2',
                nonce: '123***2',
                timestamp: 1705536488,
                signature: 'MEQCIEQlmZ****zKBSE8QnhLTIHZZZ****ZpRqRxHss65Ko****JgJKjdrWdkL****juEx2RmFS7da****ZRVZ8RyMyUXg=='
              };
              const uiContext = this.getUIContext().getHostContext() as common.UIAbilityContext
              const wantParam: Want = {
                parameters: {
                  bundleName: 'com.xxx',
                  skExposure: exposureData
                }
              }
              const callback: productViewManager.ProductViewCallback = {
                onError: (error: BusinessError) => {
                  hilog.error(0, 'TAG',
                    `loadProduct onError.code is ${error.code}, message is ${error.message}`)
                },
                onAppear: () => {
                  hilog.info(0, 'TAG', `loadProduct onAppear.`);
                },
                onDisappear: () => {
                  hilog.info(0, 'TAG', `loadProduct onDisappear.`);
                }
              }
            })
            .width('100%')
        }
        .height('100%')
    }
  }
}
```

3. 调用loadProduct方法,将步骤2中构造的参数依次传入接口中。
```typescript
productViewManager.loadProduct(uiContext, wantParam, callback);
```

### Deep Linking方式

1.
```typescript
uri: 'store://appgallery.huawei.com/app/detail?id=' + bundleName,
```

2. startAbility
```typescript
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import type { common, Want } from '@kit.AbilityKit';

function startAppGalleryDetailAbility(context: common.UIAbilityContext, bundleName: string): void {
  let want: Want = {
    action: 'ohos.want.action.appdetail',
    uri: 'store://appgallery.huawei.com/app/detail?id=' + bundleName,
  };
  context.startAbility(want).then(() => {
    hilog.info(0x0001, 'TAG', "Succeeded in starting Ability successfully.")
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
            const bundleName = 'xxxx';
            startAppGalleryDetailAbility(context, bundleName);
          })
      }
      .width('100%')
    }
    .height('100%')
  }
}
```

### App Linking方式

1.
```typescript
let link: string = 'https://appgallery.huawei.com/app/detail?id=' + bundleName;
```

2. openLink
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
        let bundleName: string = 'xxxx';
        let link: string = 'https://appgallery.huawei.com/app/detail?id=' + bundleName;
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