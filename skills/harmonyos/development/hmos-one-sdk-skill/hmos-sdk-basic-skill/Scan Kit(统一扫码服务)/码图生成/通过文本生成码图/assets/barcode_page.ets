import { scanCore, generateBarcode } from '@kit.ScanKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { image } from '@kit.ImageKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { buffer } from '@kit.ArkTS';

const TAG = 'BarcodePage';
const DOMAIN = 0x0001;

@Entry
@Component
struct BarcodePage {
  @State pixelMap: image.PixelMap | undefined = undefined;
  @State inputContent: string = 'Huawei';
  @State selectedScanType: number = scanCore.ScanType.QR_CODE;
  @State widthInput: string = '300';
  @State heightInput: string = '300';
  @State errorMessage: string = '';
  @State isSuccess: boolean = false;
  
  aboutToDisappear() {
    if (this.pixelMap) {
      this.pixelMap.release();
      this.pixelMap = undefined;
    }
  }
  
  async generateBarcode() {
    this.errorMessage = '';
    this.isSuccess = false;
    
    if (this.pixelMap) {
      this.pixelMap.release();
      this.pixelMap = undefined;
    }
    
    const width = parseInt(this.widthInput);
    const height = parseInt(this.heightInput);
    
    if (isNaN(width) || width < 200 || width > 4096) {
      this.errorMessage = 'Width must be between 200 and 4096';
      return;
    }
    
    if (isNaN(height) || height < 200 || height > 4096) {
      this.errorMessage = 'Height must be between 200 and 4096';
      return;
    }
    
    if (!this.inputContent || this.inputContent.length === 0) {
      this.errorMessage = 'Content cannot be empty';
      return;
    }
    
    let options: generateBarcode.CreateOptions = {
      scanType: this.selectedScanType,
      height: height,
      width: width,
      backgroundColor: 0xFFFFFF,
      pixelMapColor: 0x000000,
      margin: 1
    };
    
    if (this.selectedScanType === scanCore.ScanType.QR_CODE) {
      if (this.inputContent.length > 512) {
        this.errorMessage = 'QR Code content exceeds 512 characters';
        return;
      }
      options.level = generateBarcode.ErrorCorrectionLevel.LEVEL_H;
    }
    
    try {
      this.pixelMap = await generateBarcode.createBarcode(this.inputContent, options);
      this.isSuccess = true;
      hilog.info(DOMAIN, TAG, 'Succeeded in generating barcode');
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      this.errorMessage = `Error: ${err.code} - ${err.message}`;
      hilog.error(DOMAIN, TAG, `Failed to generate barcode. Code: ${err.code}, message: ${err.message}`);
    }
  }
  
  build() {
    Column() {
      Text('Barcode Generator')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 20 })
      
      TextInput({ placeholder: 'Enter content', text: this.inputContent })
        .width('80%')
        .height(50)
        .onChange((value: string) => {
          this.inputContent = value;
        })
        .margin({ bottom: 10 })
      
      Row() {
        Text('Type:')
          .fontSize(16)
          .width(60)
        
        Select([
          { value: 'QR Code', icon: '' },
          { value: 'EAN-13', icon: '' },
          { value: 'UPC-A', icon: '' },
          { value: 'Code 128', icon: '' }
        ])
          .selected(this.selectedScanType === scanCore.ScanType.QR_CODE ? 0 : 
                    this.selectedScanType === scanCore.ScanType.EAN13_CODE ? 1 : 
                    this.selectedScanType === scanCore.ScanType.UPC_A_CODE ? 2 : 3)
          .value('QR Code')
          .width(150)
          .onSelect((index: number) => {
            if (index === 0) this.selectedScanType = scanCore.ScanType.QR_CODE;
            else if (index === 1) this.selectedScanType = scanCore.ScanType.EAN13_CODE;
            else if (index === 2) this.selectedScanType = scanCore.ScanType.UPC_A_CODE;
            else this.selectedScanType = scanCore.ScanType.CODE128_CODE;
          })
      }
      .width('80%')
      .margin({ bottom: 10 })
      
      Row() {
        TextInput({ placeholder: 'Width', text: this.widthInput })
          .width('35%')
          .height(50)
          .type(InputType.Number)
          .onChange((value: string) => {
            this.widthInput = value;
          })
        
        Blank().width(10)
        
        TextInput({ placeholder: 'Height', text: this.heightInput })
          .width('35%')
          .height(50)
          .type(InputType.Number)
          .onChange((value: string) => {
            this.heightInput = value;
          })
      }
      .width('80%')
      .margin({ bottom: 20 })
      
      Button('Generate Barcode')
        .width('80%')
        .height(50)
        .onClick(() => {
          this.generateBarcode();
        })
        .margin({ bottom: 20 })
      
      if (this.errorMessage) {
        Text(this.errorMessage)
          .fontSize(14)
          .fontColor(Color.Red)
          .width('80%')
          .margin({ bottom: 10 })
      }
      
      if (this.isSuccess && this.pixelMap) {
        Image(this.pixelMap)
          .width(300)
          .height(300)
          .objectFit(ImageFit.Contain)
          .border({ width: 1, color: Color.Gray })
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}