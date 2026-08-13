import { mapCommon, map, MapComponent } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';

@Entry
@Component
struct MapMvtOverlayOnlineDemo {
  private TAG = 'MapMvtOverlayOnlineDemo';
  private mapOptions?: mapCommon.MapOptions;
  private mapController?: map.MapComponentController;
  private callback?: AsyncCallback<map.MapComponentController>;
  private mvtOverlay?: map.MvtOverlay;

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
        this.addMvtOverlayOnline();
      } else {
        console.error(this.TAG, `Failed to initialize map: code=${err.code}, message=${err.message}`);
      }
    };
  }

  private async addMvtOverlayOnline(): Promise<void> {
    let params: mapCommon.MvtOverlayParams = {
      source: {
        tileUrl: 'http://xxx/tiles/{z}/{x}/{y}.pbf',
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
      this.mvtOverlay = await this.mapController?.addMvtOverlay(params);
      console.info(this.TAG, 'MVT overlay added successfully');
    } catch (e) {
      console.error(this.TAG, `Failed to add MVT overlay: code=${e.code}, message=${e.message}`);
    }
  }

  build() {
    Stack() {
      Column() {
        MapComponent({ mapOptions: this.mapOptions, mapCallback: this.callback });
      }.width('100%')
    }.height('100%')
  }
}