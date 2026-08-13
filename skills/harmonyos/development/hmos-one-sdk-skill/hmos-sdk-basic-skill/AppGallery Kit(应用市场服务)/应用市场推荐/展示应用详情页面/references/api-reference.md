# API参考说明:productViewManager (应用市场推荐)

提供展示应用/元服务详情页、应用内快捷方式加桌的能力。

调用接口需捕获异常。

**起始版本:** 4.1.0(11)

## 导入模块

```typescript
import { productViewManager } from '@kit.AppGalleryKit';
```

## ProductViewCallback

在加载应用详情页面时作为入参用于接收加载过程中的状态变化。

**模型约束:** 此接口仅可在Stage模型下使用。

**系统能力:** SystemCapability.AppGalleryService.Distribution.Recommendations

**起始版本:** 4.1.0(11)

| 名称 | 类型 | 只读 | 可选 | 说明 |
| --- | --- | --- | --- | --- |
| onError | ErrorCallback | 否 | 是 | 回调函数,接收应用详情页加载失败的错误码。1011表示拉起/切前台失败。1012表示切后台失败。1013表示销毁失败。 |
| onAppear | Callback<void> | 否 | 是 | 回调函数,当应用详情页成功打开时回调该方法。说明:**起始版本:**5.0.2(14)。 |
| onDisappear | Callback<void> | 否 | 是 | 回调函数,当应用详情页关闭时回调该方法。说明:**起始版本:**5.0.2(14)。 |

## SKExposure

登记归因来源的广告曝光数据。

**模型约束:** 此接口仅可在Stage模型下使用。

**系统能力:** SystemCapability.AppGalleryService.Distribution.Recommendations

**起始版本:** 5.0.2(14)

**参数:**

| 名称 | 类型 | 只读 | 可选 | 说明 |
| --- | --- | --- | --- | --- |
| adTechId | string | 否 | 否 | 分发平台对应的归因角色ID,长度固定为8字符。 |
| campaignId | string | 否 | 否 | 营销任务ID,长度不超过9个字符。 |
| destinationId | string | 否 | 否 | 应用上架华为应用市场的AppId,长度不超过64个字符。 |
| mmpIds | string[] | 否 | 是 | 归因监测平台ID。最大数量2个,每个ID字符串长度固定为8个字符。 |
| serviceTag | string | 否 | 是 | 分发平台关注的业务信息,长度不超过32字符。 |
| nonce | string | 否 | 否 | 用于计算签名的随机数,不带'-',长度固定为32字符。 |
| timestamp | number | 否 | 否 | unix时间戳,单位:毫秒。 |
| signature | string | 否 | 否 | 签名值,长度不超过800个字符。 |

## productViewManager.loadProduct

loadProduct(context: common.UIAbilityContext, want: Want, callback?: ProductViewCallback): void

展示应用详情页,下载安装目标应用。使用Callback回调。

**模型约束:** 此接口仅可在Stage模型下使用。

**系统能力:** SystemCapability.AppGalleryService.Distribution.Recommendations

**设备行为差异:** 对于6.0.1(21)及之前版本,该接口在Phone、Tablet、PC/2in1中可正常使用,在其他设备类型中返回401错误码。对于6.0.2(22)及之后版本,该接口在Phone、Tablet、PC/2in1、TV中均可正常使用,在其他设备类型中返回401错误码。

**起始版本:** 4.1.0(11)

**参数:**

| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| context | common.UIAbilityContext | 是 | 调用方应用的上下文。 |
| want | Want | 是 | 展示应用详情页的请求参数。parameters是该参数中的必填属性,为一个结构体。该结构体包含两个属性:bundleName,必填,表示需要展示详情页的应用包名。skExposure,可选,表示需要传递登记归因来源的广告曝光数据。 |
| callback | ProductViewCallback | 否 | 在加载应用详情页面时作为入参用于接收加载过程中的状态变化。 |

**错误码:**

以下错误码的详细介绍请参见通用错误码。

| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |