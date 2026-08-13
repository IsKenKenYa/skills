import { scanCore, scanBarcode, detectBarcode } from '@kit.ScanKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';

@Entry
@Component
struct DetectBarcodePromisePage {
  @State scanResults: Array<scanBarcode.ScanResult> = [];
  @State errorMessage: string = '';

  build() {
    Column() {
      Button('识别本地图片(Promise方式)')
        .backgroundColor('#0D9FFB')
        .fontSize(20)
        .fontColor($r('sys.color.comp_background_list_card'))
        .fontWeight(FontWeight.Normal)
        .align(Alignment.Center)
        .type(ButtonType.Capsule)
        .width('90%')
        .height(40)
        .margin({ top: 20, bottom: 10 })
        .onClick(() => {
          this.detectBarcodeWithPromise();
        })

      if (this.scanResults.length > 0) {
        List() {
          ForEach(this.scanResults, (result: scanBarcode.ScanResult, index: number) => {
            ListItem() {
              Column() {
                Text(`码类型: ${this.getScanTypeName(result.scanType)}`)
                  .fontSize(16)
                  .margin({ top: 5, bottom: 5 })
                
                Text(`码值: ${result.originalValue}`)
                  .fontSize(14)
                  .margin({ bottom: 5 })
                  .maxLines(3)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                
                if (result.scanCodeRect) {
                  Text(`位置: left=${result.scanCodeRect.left}, top=${result.scanCodeRect.top}, right=${result.scanCodeRect.right}, bottom=${result.scanCodeRect.bottom}`)
                    .fontSize(12)
                    .margin({ bottom: 5 })
                }
              }
              .width('90%')
              .padding(10)
              .backgroundColor('#F0F0F0')
              .borderRadius(8)
              .margin({ top: 5, bottom: 5 })
            }
          }, (result: scanBarcode.ScanResult, index: number) => index.toString())
        }
        .width('90%')
        .height('60%')
        .margin({ top: 10 })
      }

      if (this.errorMessage) {
        Text(this.errorMessage)
          .fontSize(14)
          .fontColor(Color.Red)
          .margin({ top: 10 })
          .width('90%')
      }
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Start)
  }

  private detectBarcodeWithPromise(): void {
    this.scanResults = [];
    this.errorMessage = '';

    let options: scanBarcode.ScanOptions = {
      scanTypes: [scanCore.ScanType.ALL],
      enableMultiMode: true,
      enableAlbum: true
    };

    let photoOption = new photoAccessHelper.PhotoSelectOptions();
    photoOption.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
    photoOption.maxSelectNumber = 1;
    photoOption.isPhotoTakingSupported = false;
    photoOption.isEditSupported = false;

    let photoPicker = new photoAccessHelper.PhotoViewPicker();
    photoPicker.select(photoOption).then((result: photoAccessHelper.PhotoSelectResult) => {
      if (!result || (result.photoUris && result.photoUris.length === 0)) {
        this.errorMessage = '未选择图片';
        hilog.error(0x0001, '[Scan Sample]', 'Failed to get PhotoSelectResult by promise');
        return;
      }

      hilog.info(0x0001, '[Scan Sample]', `Selected photo: ${result.photoUris[0]}`);

      let inputImage: detectBarcode.InputImage = { 
        uri: result.photoUris[0] 
      };

      try {
        detectBarcode.decode(inputImage, options).then((data: Array<scanBarcode.ScanResult>) => {
          hilog.info(0x0001, '[Scan Sample]', 
            `Succeeded in getting ScanResult by promise. result is ${JSON.stringify(data)}`);
          
          if (data && data.length > 0) {
            this.scanResults = data;
            hilog.info(0x0001, '[Scan Sample]', `识别到 ${data.length} 个码`);
          } else {
            this.errorMessage = '未识别到码图';
          }
        }).catch((err: BusinessError) => {
          hilog.error(0x0001, '[Scan Sample]', 
            `Failed to get ScanResult by promise. Code: ${err.code}, message: ${err.message}`);
          this.errorMessage = `识别失败: ${err.message}`;
        });
      } catch (error) {
        hilog.error(0x0001, '[Scan Sample]', 
          `Failed to detectBarcode. Code: ${error.code}, message: ${error.message}`);
        this.errorMessage = `调用失败: ${error.message}`;
      }
    }).catch((err: BusinessError) => {
      hilog.error(0x0001, '[Scan Sample]', 
        `Failed to select photo. Code: ${err.code}, message: ${err.message}`);
      this.errorMessage = `选择图片失败: ${err.message}`;
    });
  }

  private getScanTypeName(scanType: scanCore.ScanType): string {
    switch (scanType) {
      case scanCore.ScanType.QR_CODE:
        return 'QR码';
      case scanCore.ScanType.AZTEC:
        return 'Aztec码';
      case scanCore.ScanType.DATA_MATRIX:
        return 'Data Matrix码';
      case scanCore.ScanType.PDF_417:
        return 'PDF417码';
      case scanCore.ScanType.BARCODE:
        return '条形码';
      case scanCore.ScanType.EAN_13:
        return 'EAN-13码';
      case scanCore.ScanType.EAN_8:
        return 'EAN-8码';
      case scanCore.ScanType.UPC_A:
        return 'UPC-A码';
      case scanCore.ScanType.UPC_E:
        return 'UPC-E码';
      case scanCore.ScanType.CODE_39:
        return 'Code 39码';
      case scanCore.ScanType.CODE_93:
        return 'Code 93码';
      case scanCore.ScanType.CODE_128:
        return 'Code 128码';
      case scanCore.ScanType.CODABAR:
        return 'Codabar码';
      case scanCore.ScanType.ITF_14:
        return 'ITF-14码';
      case scanCore.ScanType.MULTIFUNCTIONAL_CODE:
        return '多功能码';
      case scanCore.ScanType.ALL:
        return '全部码类型';
      default:
        return '未知码类型';
    }
  }
}