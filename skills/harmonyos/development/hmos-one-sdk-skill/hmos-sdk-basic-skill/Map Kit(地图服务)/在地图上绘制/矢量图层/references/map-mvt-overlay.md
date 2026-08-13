# 矢量图层
---
# 矢量图层
#### 场景介绍
新增矢量图层，用于在基础地图之上叠加矢量数据，实时展示全球或区域的天气状况，如降雨、台风、温度等。
6.0.0(20)开始，支持矢量图层功能。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/11/v3/JYUiDM9vRJi0VCHZgXPSQg/zh-cn_image_0000002628701842.gif?HW-CC-KV=V1&HW-CC-Date=20260701T105234Z&HW-CC-Expire=86400&HW-CC-Sign=BEBEB4F851399ED0372E54CBA8A7114562BD450D3CCFADE25A23E70E17208DCA)
#### 接口说明
矢量图层功能主要由 [MvtOverlayParams](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-common) 、 [addMvtOverlay](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-map-mapcomponentcontroller) 和 [MvtOverlay](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-map-mvtoverlay) 提供，更多接口及使用方法请参见 [接口文档](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-map-mvtoverlay) 。
| 接口名 | 描述 |
| --- | --- |
| [MvtOverlayParams](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-common) | 矢量图层的参数。 |
| [addMvtOverlay](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-map-mapcomponentcontroller)(params:[mapCommon.MvtOverlayParams](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-common)):[MvtOverlay](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-map-mvtoverlay) | 添加矢量图层。 |
| [MvtOverlay](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-map-mvtoverlay) | 矢量图层管理对象，支持添加和删除图层。 |
#### 开发步骤
矢量图层的绘制方式提供两种方式：在线下载和本地加载。
#### 在线下载
1.
在开发过程中，开发者需要在应用的module.json5文件中配置网络访问权限以支持在线下载矢量图层。具体操作如下：打开module.json5文件，在requestPermissions数组中添加如下配置项：允许应用使用Internet网络。
```
{
  "module": {
    // ...
    // ...
    "requestPermissions":[
      {
        // 允许应用在前台运行时获取位置信息
        "name" : "ohos.permission.LOCATION",
        // reason需要在/resources/base/element/string.json中新建
        "reason": "$string:location_permission",
        "usedScene": {
          "abilities": [
            "EntryAbility"
          ],
          "when":"inuse"
        }
      },
      {
        // 允许应用获取设备模糊位置信息
        "name" : "ohos.permission.APPROXIMATELY_LOCATION",
        // reason需要在/resources/base/element/string.json中新建
        "reason": "$string:fuzzy_location_permission",
        "usedScene": {
          "abilities": [
            "EntryAbility"
          ],
          "when":"inuse"
        }
      }
    ]
  }
}
```
2.
导入相关模块。
```typescript
import { mapCommon, map, MapComponent } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';
```
3.
绘制矢量图层。
矢量图层支持的数据源类型为通用矢量瓦片格式（PBF/MVT）。 [MvtOverlayParams](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-common) 类中的layers参数，其中sourceLayer、fillColor/fillOpacity默认值从矢量数据里获取，也可自己设置。
```
@Entry
@Component
struct MapMvtOverlayDemo {
  // ...
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
    }
    this.callback = async (err, mapController) => {
      if (!err) {
        this.mapController = mapController;
        let params: mapCommon.MvtOverlayParams = {
          source: {
            // 设置矢量图层的地址,必须是以http或者https开头的URL且包含占位符{x}、{y}和{z}
            tileUrl: 'http://xxx/tiles/{z}/{x}/{y}.pbf',
            minZoom: 2,
            maxZoom: 15
          },
          layers: [{
            id: 'layer-map',
            type: mapCommon.MvtLayerType.FILL,
            // 对应矢量图层数据中图层的name字段
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
        }
        try {
          this.mapController?.addMvtOverlay(params);
        } catch (e) {
          console.error(this.TAG, `code:${e.code}, message:${e.message}`);
        }
      } else {
        console.error(`Failed to initialize the map, code is：${err.code}, message is ${err.message}`);
      }
    }
  }
  build() {
    // ...
      Stack() {
        Column() {
          MapComponent({ mapOptions: this.mapOptions, mapCallback: this.callback });
        }.width('100%')
      }.height('100%')
      // ...
  }
}
```
#### 本地加载
1.
导入相关模块。
```typescript
import { mapCommon, map, MapComponent } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';
```
2.
增加本地矢量图层。
```
@Entry
@Component
struct MapMvtOverlayDemo {
  // ...
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
    }
    this.callback = async (err, mapController) => {
      if (!err) {
        this.mapController = mapController;
        let params: mapCommon.MvtOverlayParams = {
          source: {
            // 根据矢量坐标获取矢量图层，本地获取矢量图层方式需开发者自行实现tileProvider方法
            tileProvider: this.tileProviderMethod,
            minZoom: 2,
            maxZoom: 15
          },
          layers: [{
            id: 'layer-map',
            type: mapCommon.MvtLayerType.FILL,
            // 对应矢量图层数据中图层的name字段
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
        }
        try {
          this.mapController?.addMvtOverlay(params);
        } catch (e) {
          console.error(this.TAG, `code:${e.code}, message:${e.message}`);
        }
      } else {
        console.error(`Failed to initialize the map, code is：${err.code}, message is ${err.message}`);
      }
    }
  }
  // 需要开发者自行实现tileProviderMethod方法，负责加载本地项目中的矢量图层资源
  private tileProviderMethod(x: number, y: number, z: number): Promise<ArrayBuffer> {
    return new Promise((resolve, reject) => {
    });
  }
  build() {
    // ...
      Stack() {
        Column() {
          MapComponent({ mapOptions: this.mapOptions, mapCallback: this.callback });
        }.width('100%')
      }.height('100%')
      // ...
  }
}
```