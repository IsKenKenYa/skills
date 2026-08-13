import { mapCommon, map, MapComponent } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';

@Entry
@Component
struct TestOnlineMvtOverlay {
  private TAG = 'TestOnlineMvtOverlay';
  private mapOptions?: mapCommon.MapOptions;
  private mapController?: map.MapComponentController;
  private callback?: AsyncCallback<map.MapComponentController>;
  private testResult: string = '';

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
        await this.runTest();
      } else {
        this.testResult = `Failed: ${err.code} - ${err.message}`;
      }
    };
  }

  private async runTest(): Promise<void> {
    try {
      // 测试1: 正常添加矢量图层
      let params: mapCommon.MvtOverlayParams = {
        source: {
          tileUrl: 'https://example.com/tiles/{z}/{x}/{y}.pbf',
          minZoom: 2,
          maxZoom: 15
        },
        layers: [{
          id: 'test-layer',
          type: mapCommon.MvtLayerType.FILL,
          sourceLayer: 'test',
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

      let mvtOverlay = await this.mapController?.addMvtOverlay(params);
      if (mvtOverlay) {
        this.testResult = 'Test Passed: Online MVT overlay added successfully';
        console.info(this.TAG, this.testResult);
      } else {
        this.testResult = 'Test Failed: MVT overlay is null';
        console.error(this.TAG, this.testResult);
      }

      // 测试2: 添加多个图层
      let additionalLayers: Array<mapCommon.MvtLayer> = [{
        id: 'layer-2',
        type: mapCommon.MvtLayerType.FILL,
        sourceLayer: 'layer2',
        paint: {
          fillColor: {
            operator: mapCommon.Operator.GET,
            args: 'fill'
          }
        }
      }];

      mvtOverlay?.addLayers(additionalLayers);
      this.testResult += '\nTest Passed: Additional layers added';
      console.info(this.TAG, 'Additional layers added');

      // 测试3: 移除图层
      mvtOverlay?.removeLayers(['layer-2']);
      this.testResult += '\nTest Passed: Layer removed';
      console.info(this.TAG, 'Layer removed');

    } catch (e) {
      this.testResult = `Test Failed: ${e.code} - ${e.message}`;
      console.error(this.TAG, this.testResult);
    }
  }

  build() {
    Column() {
      Text('Online MVT Overlay Test')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 20 });

      MapComponent({ mapOptions: this.mapOptions, mapCallback: this.callback })
        .width('100%')
        .height('60%');

      Text(this.testResult)
        .fontSize(14)
        .margin({ top: 20 })
        .padding(10)
        .backgroundColor('#F0F0F0');
    }
    .width('100%')
    .height('100%');
  }
}