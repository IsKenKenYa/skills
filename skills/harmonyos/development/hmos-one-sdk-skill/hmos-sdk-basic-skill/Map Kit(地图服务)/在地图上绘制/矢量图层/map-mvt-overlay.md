---
name: hmos-map-kit-mvt-overlay
description: 在地图上添加矢量图层，支持在线下载和本地加载两种方式，用于展示降雨、台风、温度等天气状况数据，适用于天气可视化、地理数据展示场景，API版本6.0.0(20)及以上
---

# 矢量图层技能

## 功能描述

矢量图层功能用于在基础地图之上叠加矢量数据，实时展示全球或区域的天气状况，如降雨、台风、温度等。支持两种数据加载方式：在线下载和本地加载，数据源类型为通用矢量瓦片格式（PBF/MVT）。

## 使用场景

### 触发词
- "添加矢量图层"
- "绘制矢量图层"
- "MVT图层"
- "矢量瓦片"
- "天气数据展示"
- "降雨雷达图层"

### 能做
- 在地图上添加矢量图层（在线下载方式）
- 在地图上添加矢量图层（本地加载方式）
- 支持PBF/MVT格式的矢量瓦片数据
- 实时展示天气状况数据（降雨、台风、温度等）
- 支持多图层叠加显示
- 支持图层样式自定义（填充颜色、透明度等）

### 绝不做
- 不支持非PBF/MVT格式的矢量数据
- 不支持离线地图基础底图（必须已有地图组件）
- 不处理矢量数据生成（仅加载已有数据）
- 不支持非HTTP/HTTPS协议的在线数据源

### 补充
- API版本要求：6.0.0(20)及以上
- 在线下载方式需要网络权限
- 本地加载方式需要开发者自行实现tileProvider方法
- 矢量图层URL必须包含占位符{x}、{y}和{z}

## 调用规范和规则

### 输入约束
- 矢量图层URL：必须以http或https开头，包含占位符{x}、{y}和{z}
- 缩放级别范围：minZoom和maxZoom需在[2, 20]范围内
- 图层ID：字符串类型，唯一标识
- sourceLayer：对应矢量数据中图层的name字段
- 填充颜色：ARGB格式，范围[0x00000000, 0xFFFFFFFF]
- 填充透明度：范围[0, 1]

### 执行约束
- 最大图层数量：建议少于2000层，确保流畅度
- 异步调用：使用Promise异步回调
- 权限要求：在线下载需配置网络权限（ohos.permission.INTERNET）
- 位置权限：需要LOCATION和APPROXIMATELY_LOCATION权限

### 内容约束
- 禁止生成：非矢量图层的地图覆盖物
- 禁止操作：修改基础地图底图样式
- 禁止使用：非PBF/MVT格式的数据源

### 降级约束
- 网络失败：提示用户检查网络连接，切换到本地加载方式
- 数据加载失败：显示错误信息，建议检查数据源URL和格式
- 权限不足：提示用户授予必要权限（位置、网络）

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 检查API版本是否为6.0.0(20)及以上
2. 验证是否已导入必要的模块（mapCommon, map, MapComponent）
3. 确认地图组件已正确初始化
4. 检查权限配置（LOCATION、APPROXIMATELY_LOCATION、INTERNET）

**参数准备**：
```typescript
// 导入必要模块
import { mapCommon, map, MapComponent } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';

// 地图初始化参数
let mapOptions: mapCommon.MapOptions = {
  position: {
    target: {
      latitude: 35.899780,
      longitude: 107.766172
    },
    zoom: 6
  },
  scaleControlsEnabled: true
};
```

### 步骤2：配置权限（在线下载方式）

**module.json5配置**：
```json
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.LOCATION",
        "reason": "$string:location_permission",
        "usedScene": {
          "abilities": ["EntryAbility"],
          "when": "inuse"
        }
      },
      {
        "name": "ohos.permission.APPROXIMATELY_LOCATION",
        "reason": "$string:fuzzy_location_permission",
        "usedScene": {
          "abilities": ["EntryAbility"],
          "when": "inuse"
        }
      },
      {
        "name": "ohos.permission.INTERNET",
        "reason": "$string:internet_permission",
        "usedScene": {
          "abilities": ["EntryAbility"],
          "when": "inuse"
        }
      }
    ]
  }
}
```

### 步骤3：在线下载方式添加矢量图层

**示例代码**：
```typescript
@Entry
@Component
struct MapMvtOverlayDemo {
  private TAG = 'OHMapSDK_MvtOverlayDemo';
  private mapOptions?: mapCommon.MapOptions;
  private mapController?: map.MapComponentController;
  private callback?: AsyncCallback<map.MapComponentController>;

  aboutToAppear(): void {
    this.mapOptions = {
      position: {
        target: {
          latitude: 35.899780,
          longitude: 107.766172
        },
        zoom: 6
      },
      scaleControlsEnabled: true
    };

    this.callback = async (err, mapController) => {
      if (!err) {
        this.mapController = mapController;
        
        // 配置矢量图层参数
        let params: mapCommon.MvtOverlayParams = {
          source: {
            // 设置矢量图层的地址，必须包含{x}、{y}、{z}占位符
            tileUrl: 'http://xxx/tiles/{z}/{x}/{y}.pbf',
            minZoom: 2,
            maxZoom: 15
          },
          layers: [{
            id: 'layer-map',
            type: mapCommon.MvtLayerType.FILL,
            sourceLayer: 'XX', // 对应矢量数据中图层的name字段
            paint: {
              fillColor: {
                operator: mapCommon.Operator.GET,
                args: 'fill'
              },
              fillOpacity: {
                operator: mapCommon.Operator.GET,
                args: 'fill-opacity'
              }
            }
          }]
        };

        try {
          // 添加矢量图层
          this.mapController?.addMvtOverlay(params);
          console.info(this.TAG, 'MVT overlay added successfully');
        } catch (e) {
          console.error(this.TAG, `code:${e.code}, message:${e.message}`);
        }
      } else {
        console.error(this.TAG, `Failed to initialize the map, code:${err.code}, message:${err.message}`);
      }
    };
  }

  build() {
    Stack() {
      Column() {
        MapComponent({ mapOptions: this.mapOptions, mapCallback: this.callback });
      }.width('100%')
    }.height('100%')
  }
}
```

### 步骤4：本地加载方式添加矢量图层

**示例代码**：
```typescript
@Entry
@Component
struct MapMvtOverlayLocalDemo {
  private TAG = 'OHMapSDK_MvtOverlayLocalDemo';
  private mapOptions?: mapCommon.MapOptions;
  private mapController?: map.MapComponentController;
  private callback?: AsyncCallback<map.MapComponentController>;

  aboutToAppear(): void {
    this.mapOptions = {
      position: {
        target: {
          latitude: 35.899780,
          longitude: 107.766172
        },
        zoom: 6
      },
      scaleControlsEnabled: true
    };

    this.callback = async (err, mapController) => {
      if (!err) {
        this.mapController = mapController;
        
        let params: mapCommon.MvtOverlayParams = {
          source: {
            // 使用本地矢量图层，需要开发者自行实现tileProvider方法
            tileProvider: this.tileProviderMethod,
            minZoom: 2,
            maxZoom: 15
          },
          layers: [{
            id: 'layer-map',
            type: mapCommon.MvtLayerType.FILL,
            sourceLayer: 'XX',
            paint: {
              fillColor: {
                operator: mapCommon.Operator.GET,
                args: 'fill'
              },
              fillOpacity: {
                operator: mapCommon.Operator.GET,
                args: 'fill-opacity'
              }
            }
          }]
        };

        try {
          this.mapController?.addMvtOverlay(params);
          console.info(this.TAG, 'Local MVT overlay added successfully');
        } catch (e) {
          console.error(this.TAG, `code:${e.code}, message:${e.message}`);
        }
      } else {
        console.error(this.TAG, `Failed to initialize the map, code:${err.code}, message:${err.message}`);
      }
    };
  }

  // 本地矢量图层加载方法（开发者需自行实现）
  private tileProviderMethod(x: number, y: number, z: number): Promise<ArrayBuffer> {
    return new Promise((resolve, reject) => {
      // 实现本地矢量图层资源加载逻辑
      // 示例：从本地文件系统或数据库读取PBF/MVT数据
      try {
        // 根据x、y、z坐标查找对应的矢量瓦片数据
        // 返回ArrayBuffer格式的数据
        resolve(/* 矢量数据 */);
      } catch (error) {
        reject(error);
      }
    });
  }

  build() {
    Stack() {
      Column() {
        MapComponent({ mapOptions: this.mapOptions, mapCallback: this.callback });
      }.width('100%')
    }.height('100%')
  }
}
```

### 步骤5：错误处理

```typescript
try {
  let mvtOverlay = await this.mapController?.addMvtOverlay(params);
  console.info('MVT overlay added successfully');
} catch (error) {
  switch (error.code) {
    case 401:
      console.error('Invalid input parameter');
      // 检查参数格式和取值范围
      break;
    case 1002601001:
      console.error('The object to be operated does not exist');
      // 检查地图控制器是否已初始化
      break;
    default:
      console.error('Unknown error:', error.message);
      // 提示用户检查网络或数据源
  }
}
```

### 步骤6：图层管理

**添加图层**：
```typescript
let newLayers: Array<mapCommon.MvtLayer> = [{
  id: 'new-layer',
  type: mapCommon.MvtLayerType.FILL,
  sourceLayer: 'weather',
  paint: {
    fillColor: {
      operator: mapCommon.Operator.GET,
      args: 'fill'
    }
  }
}];
mvtOverlay.addLayers(newLayers);
```

**删除图层**：
```typescript
let layerIds = ['layer-map'];
mvtOverlay.removeLayers(layerIds);
```

**更新图层**：
```typescript
let addedLayers: Array<mapCommon.MvtLayer> = [{ id: 'updated-layer', ... }];
let removedLayerIds = ['old-layer'];
mvtOverlay.changeLayers(addedLayers, removedLayerIds);
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | Invalid input parameter | 检查参数格式和取值范围，确保tileUrl格式正确 |
| 1002601001 | The object to be operated does not exist | 确认地图控制器已正确初始化 |
| 网络错误 | 无法访问在线矢量数据源 | 检查网络连接，确认URL可访问，切换本地加载方式 |
| 数据格式错误 | 矢量数据格式不正确 | 确保数据为PBF/MVT格式，检查数据源 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.MapKit": "^6.0.0",
    "@kit.BasicServicesKit": "^6.0.0"
  }
}
```

### 环境要求
- HarmonyOS API版本：6.0.0(20)及以上
- DevEco Studio版本：支持HarmonyOS 6.0.0开发
- 设备支持：支持SystemCapability.Map.Core.EnhancedOverlay

### 常见编译问题

**问题1：权限未配置**
```
Error: Permission denied
```
**解决方法**：在module.json5中添加LOCATION、APPROXIMATELY_LOCATION和INTERNET权限

**问题2：模块导入失败**
```
Error: Cannot find module '@kit.MapKit'
```
**解决方法**：确保API版本为6.0.0(20)及以上，检查项目配置

**问题3：地图未初始化**
```
Error: mapController is undefined
```
**解决方法**：确保在地图初始化回调中调用addMvtOverlay方法

## 常见问题与解决方法

### Q1：矢量图层不显示
**原因**：数据源URL错误或数据格式不正确
**解决方法**：
- 检查tileUrl是否包含{x}、{y}、{z}占位符
- 验证URL是否可访问
- 确认数据为PBF/MVT格式
- 检查sourceLayer是否与数据中的name字段匹配

### Q2：图层加载速度慢
**原因**：网络连接慢或图层数量过多
**解决方法**：
- 使用本地加载方式替代在线下载
- 减少图层数量（建议少于2000层）
- 调整minZoom和maxZoom范围，避免加载过多瓦片

### Q3：图层样式不生效
**原因**：paint参数配置错误
**解决方法**：
- 检查fillColor和fillOpacity配置
- 确认Operator.GET和args参数正确
- 验证颜色值为ARGB格式

### Q4：权限申请失败
**原因**：权限配置不完整
**解决方法**：
- 在module.json5中完整配置LOCATION、APPROXIMATELY_LOCATION、INTERNET权限
- 在string.json中添加权限说明文本
- 确保usedScene配置正确

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "layerId": "layer-map",
  "layerType": "FILL",
  "sourceType": "online/local",
  "minZoom": 2,
  "maxZoom": 15,
  "apiUsed": [
    "mapCommon.MvtOverlayParams",
    "map.MapComponentController.addMvtOverlay",
    "map.MvtOverlay"
  ],
  "message": "矢量图层已成功添加到地图上"
}
```

## 参考文档

- [矢量图层开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/map-mvt-overlay)
- [MvtOverlayParams API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-common)
- [addMvtOverlay API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-map-mapcomponentcontroller)
- [MvtOverlay API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-map-mvtoverlay)

## 完整示例代码

- [在线下载示例](assets/map_mvt_overlay_online.ets)
- [本地加载示例](assets/map_mvt_overlay_local.ets)
- [权限配置示例](assets/module.json5)

## 测试用例

### 正向测试用例
- [添加在线矢量图层](tests/test_online_mvt_overlay.ets)：验证在线下载方式正常工作
- [添加本地矢量图层](tests/test_local_mvt_overlay.ets)：验证本地加载方式正常工作
- [多图层叠加](tests/test_multi_layers.ets)：验证多个图层叠加显示

### 边界测试用例
- [最小缩放级别](tests/test_min_zoom.ets)：验证minZoom为2时的效果
- [最大缩放级别](tests/test_max_zoom.ets)：验证maxZoom为20时的效果
- [大量图层](tests/test_large_layers.ets)：验证添加2000个图层的性能

### 异常测试用例
- [无效URL](tests/test_invalid_url.ets)：验证tileUrl格式错误时的错误处理
- [权限缺失](tests/test_missing_permission.ets)：验证权限未配置时的错误提示
- [数据格式错误](tests/test_invalid_format.ets)：验证非PBF/MVT格式数据的处理