# API参考文档

## MvtOverlayParams

矢量图层的参数定义。

**模块导入**：
```typescript
import { mapCommon } from '@kit.MapKit';
```

**属性说明**：

| 属性名 | 类型 | 必填 | 说明 |
|-------|------|------|------|
| source | [MvtOverlaySource](#mvtoverlaysource) | 是 | 矢量图层的源定义 |
| layers | Array<[MvtLayer](#mvtlayer)> | 是 | 矢量图层列表 |

**起始版本**：6.0.0(20)

### MvtOverlaySource

矢量图层的源定义。

| 属性名 | 类型 | 必填 | 说明 |
|-------|------|------|------|
| tileUrl | string | 否 | 矢量瓦片URL，必须包含{x}、{y}、{z}占位符 |
| tileProvider | (x: number, y: number, z: number) => Promise<ArrayBuffer> | 否 | 本地矢量瓦片提供函数 |
| minZoom | number | 是 | 最小缩放级别，范围[2, 20] |
| maxZoom | number | 是 | 最大缩放级别，范围[2, 20] |

### MvtLayer

矢量图层定义。

| 属性名 | 类型 | 必填 | 说明 |
|-------|------|------|------|
| id | string | 是 | 图层唯一标识 |
| type | [MvtLayerType](#mvtlayertype) | 是 | 图层类型 |
| sourceLayer | string | 是 | 对应矢量数据中的图层name字段 |
| paint | [MvtPaint](#mvtpaint) | 否 | 图层绘制样式 |

### MvtLayerType

图层类型枚举。

| 值 | 说明 |
|----|------|
| FILL | 填充图层 |
| LINE | 线图层 |
| SYMBOL | 符号图层 |

### MvtPaint

图层绘制样式。

| 属性名 | 类型 | 说明 |
|-------|------|------|
| fillColor | [PaintProperty](#paintproperty) | 填充颜色 |
| fillOpacity | [PaintProperty](#paintproperty) | 填充透明度 |
| lineColor | [PaintProperty](#paintproperty) | 线条颜色 |
| lineWidth | [PaintProperty](#paintproperty) | 线条宽度 |

### PaintProperty

绘制属性定义。

| 属性名 | 类型 | 说明 |
|-------|------|------|
| operator | [Operator](#operator) | 操作类型 |
| args | string \| number | 参数值 |

### Operator

操作类型枚举。

| 值 | 说明 |
|----|------|
| GET | 从矢量数据中获取属性值 |
| CONSTANT | 使用常量值 |

---

## addMvtOverlay

添加矢量图层到地图上。

**方法签名**：
```typescript
addMvtOverlay(params: mapCommon.MvtOverlayParams): Promise<MvtOverlay>
```

**参数说明**：

| 参数名 | 类型 | 必填 | 说明 |
|-------|------|------|------|
| params | mapCommon.MvtOverlayParams | 是 | 矢量图层参数 |

**返回值**：
- Promise<[MvtOverlay](#mvtoverlay)>：返回矢量图层管理对象

**错误码**：

| 错误码ID | 错误信息 |
|---------|---------|
| 401 | Invalid input parameter |
| 1002601001 | The object to be operated does not exist |

**起始版本**：6.0.0(20)

---

## MvtOverlay

矢量图层管理对象，继承自[BaseOverlay](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-map-baseoverlay)。

**模块导入**：
```typescript
import { map } from '@kit.MapKit';
```

**起始版本**：6.0.0(20)

### 方法列表

#### addLayers

添加新矢量图层。

```typescript
addLayers(layers: mapCommon.MvtLayer[]): void
```

**参数说明**：

| 参数名 | 类型 | 必填 | 说明 |
|-------|------|------|------|
| layers | mapCommon.MvtLayer[] | 是 | 矢量图层列表，建议少于2000层 |

#### removeLayers

移除指定图层。

```typescript
removeLayers(layerIds: string[]): void
```

**参数说明**：

| 参数名 | 类型 | 必填 | 说明 |
|-------|------|------|------|
| layerIds | string[] | 是 | 需要删除的图层ID列表 |

#### changeLayers

新增并删除图层。

```typescript
changeLayers(addedLayers: mapCommon.MvtLayer[], removedLayerIds: string[]): void
```

**参数说明**：

| 参数名 | 类型 | 必填 | 说明 |
|-------|------|------|------|
| addedLayers | mapCommon.MvtLayer[] | 是 | 新增的矢量图层 |
| removedLayerIds | string[] | 是 | 需要删除的图层ID列表 |

#### setBlur

设置矢量图层模糊度。

```typescript
setBlur(blurIntensity: number | Record<number, number>): void
```

**参数说明**：

| 参数名 | 类型 | 必填 | 说明 |
|-------|------|------|------|
| blurIntensity | number \| Record<number, number> | 是 | 模糊度，范围[0, 20] |

**起始版本**：6.0.2(22)

#### getBlur

获取矢量图层模糊度。

```typescript
getBlur(): number | Record<number, number>
```

**返回值**：
- number \| Record<number, number>：矢量图层模糊度

**起始版本**：6.0.2(22)

---

## 参考链接

- [map-common API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-common)
- [map-map-componentcontroller API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-map-mapcomponentcontroller)
- [map-map-mvtoverlay API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-map-mvtoverlay)