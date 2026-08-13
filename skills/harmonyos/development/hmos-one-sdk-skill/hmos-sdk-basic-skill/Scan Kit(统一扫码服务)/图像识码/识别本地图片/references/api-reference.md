# detectBarcode (鍥惧儚璇嗙爜)
---
# detectBarcode (鍥惧儚璇嗙爜)
鏈ā鍧楁彁渚涙湰鍦板浘鐗囪瘑鐮佸拰鍥惧儚鏁版嵁璇嗙爜鑳藉姏锛屾敮鎸佸鍥惧儚涓殑鏉″舰鐮併€佷簩缁寸爜銆丮ULTIFUNCTIONAL CODE杩涜璇嗗埆銆?
涓轰簡鏂逛究寮€鍙戣€呮帴鍏ワ紝鎴戜滑鎻愪緵浜嗚缁嗙殑鏍蜂緥宸ョ▼渚涘弬鑰冿紝鎺ㄨ崘鍙傝€?[绀轰緥宸ョ▼](https://gitcode.com/HarmonyOS_Samples/scan-kit_-sample-code_-clientdemo_-arkts) 鎺ュ叆銆?
**璧峰鐗堟湰锛?* 4.1.0(11)
#### 瀵煎叆妯″潡
```typescript
import { detectBarcode } from '@kit.ScanKit';
```
#### InputImage
寰呰瘑鍒殑鍥剧墖淇℃伅銆?
**绯荤粺鑳藉姏锛?* SystemCapability.Multimedia.Scan.ScanBarcode
**璧峰鐗堟湰锛?* 4.1.0(11)
| 鍚嶇О | 绫诲瀷 | 鍙 | 鍙€?| 璇存槑 |
| --- | --- | --- | --- | --- |
| uri | string | 鍚?| 鍚?| 鍥剧墖璺緞锛屼緥濡俧ile://media/Photo/x/xxx.jpg銆?|
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/82/v3/QsA8L6kwQaetoWov8M3iWQ/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093647Z&HW-CC-Expire=86400&HW-CC-Sign=5093335AB3DB73EF21FDF10F8A2FB19EEE9B4DCD3B362AAC82FE65037DB7F590)
鎺ㄨ崘浣跨敤
[picker](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/浣跨敤Picker閫夋嫨濯掍綋搴撹祫婧?photoaccesshelper-photoviewpicker)
鑾峰彇鍥剧墖璺緞銆?
```typescript
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
let photoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
photoSelectOptions.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
photoSelectOptions.maxSelectNumber = 1;
photoSelectOptions.isPhotoTakingSupported = false;
photoSelectOptions.isEditSupported = false;
let photoPicker = new photoAccessHelper.PhotoViewPicker();
photoPicker.select(photoSelectOptions).then((result: photoAccessHelper.PhotoSelectResult) => {
  if (!result || (result.photoUris && result.photoUris.length === 0)) {
    hilog.error(0x0001, 'picker', 'Failed to get PhotoSelectResult by promise');
    return;
  }
  hilog.info(0x0001, 'picker', `Succeeded in getting PhotoSelectResult by promise.`);
}).catch((error: BusinessError) => {
  hilog.error(0x0001, 'picker', `Failed to get PhotoSelectResult by promise. Code: ${error.code}`);
});
```
#### detectBarcode.decode
decode(inputImage: InputImage, options?: scanBarcode.ScanOptions): Promise<Array<scanBarcode.ScanResult>>
閫氳繃閰嶇疆鍙傛暟璋冪敤鍥剧墖璇嗙爜锛屼娇鐢≒romise寮傛鍥炶皟杩斿洖璇嗙爜缁撴灉銆?
**绯荤粺鑳藉姏锛?* SystemCapability.Multimedia.Scan.ScanBarcode
**璧峰鐗堟湰锛?* 4.1.0(11)
**鍙傛暟锛?*
| 鍙傛暟鍚?| 绫诲瀷 | 蹇呭～ | 璇存槑 |
| --- | --- | --- | --- |
| inputImage | [InputImage](#section2194164873812) | 鏄?| 寰呰瘑鍒殑鍥剧墖淇℃伅銆?|
| options | scanBarcode.[ScanOptions](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/scan-scanbarcode-api) | 鍚?| 鍚姩鍥剧墖璇嗙爜鍙傛暟銆?|
**杩斿洖鍊硷細**
| **绫诲瀷** | **璇存槑** |
| --- | --- |
| Promise<Array<scanBarcode.[ScanResult](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/scan-scanbarcode-api)>> | Promise瀵硅薄锛岃繑鍥炶瘑鐮佺粨鏋滃璞°€?|
**閿欒鐮侊細**
浠ヤ笅閿欒鐮佺殑璇︾粏浠嬬粛璇峰弬瑙?[ArkTS API閿欒鐮乚(https://developer.huawei.com/consumer/cn/doc/harmonyos-references/scan-error-code) 銆?
| 閿欒鐮両D | 閿欒淇℃伅 |
| --- | --- |
| 401 | Parameter error. Possible causes: 1. Incorrect parameter types; 2. Parameter verification failed. |
| 1000500001 | Internal error. |
**绀轰緥锛?*
```typescript
import { scanCore, scanBarcode, detectBarcode } from '@kit.ScanKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
// 瀹氫箟璇嗙爜鍙傛暟options
let options: scanBarcode.ScanOptions = { scanTypes: [scanCore.ScanType.ALL], enableMultiMode: true, enableAlbum: true };
// 閫氳繃picker鎷夎捣鍥惧簱骞堕€夋嫨鍥剧墖
let photoOption = new photoAccessHelper.PhotoSelectOptions();
photoOption.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
photoOption.maxSelectNumber = 1;
let photoPicker = new photoAccessHelper.PhotoViewPicker();
photoPicker.select(photoOption).then((result) => {
  // 瀹氫箟璇嗙爜鍙傛暟inputImage锛屽叾涓璾ri涓簆icker閫夋嫨鍥剧墖
  let inputImage: detectBarcode.InputImage = { uri: result.photoUris[0] };
  try {
    // 璋冪敤鍥剧墖璇嗙爜鎺ュ彛
    detectBarcode.decode(inputImage, options).then((result: Array<scanBarcode.ScanResult>) => {
      hilog.info(0x0001, '[Scan Sample]',
        `Succeeded in getting ScanResult by promise with options, result is ${JSON.stringify(result)}`);
    }).catch((error: BusinessError) => {
      hilog.error(0x0001, '[Scan Sample]',
        `Failed to get ScanResult by promise with options. Code: ${error.code}, message: ${error.message}`);
    });
  } catch (error) {
    hilog.error(0x0001, '[Scan Sample]',
      `Failed to detect Barcode. Code: ${error.code}, message: ${error.message}`);
  }
}).catch((error: BusinessError) => {
  hilog.error(0x0001, 'picker', `Failed to get PhotoSelectResult by promise. Code: ${error.code}.`);
});
```
#### detectBarcode.decode
decode(inputImage: InputImage, options: scanBarcode.ScanOptions, callback: AsyncCallback<Array<scanBarcode.ScanResult>>): void
閫氳繃閰嶇疆鍙傛暟璋冪敤鍥剧墖璇嗙爜锛屼娇鐢–allback寮傛鍥炶皟杩斿洖璇嗙爜缁撴灉銆?
**绯荤粺鑳藉姏锛?* SystemCapability.Multimedia.Scan.ScanBarcode
**璧峰鐗堟湰锛?* 4.1.0(11)
**鍙傛暟锛?*
| 鍙傛暟鍚?| 绫诲瀷 | 蹇呭～ | 璇存槑 |
| --- | --- | --- | --- |
| inputImage | [InputImage](#section2194164873812) | 鏄?| 寰呰瘑鍒殑鍥剧墖淇℃伅銆?|
| options | scanBarcode.[ScanOptions](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/scan-scanbarcode-api) | 鏄?| 鍚姩鍥剧墖璇嗙爜鍙傛暟銆?|
| callback | AsyncCallback<Array<scanBarcode.[ScanResult](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/scan-scanbarcode-api)>> | 鏄?| 鍥炶皟鍑芥暟锛屽綋鍥剧墖璇嗙爜鎴愬姛锛宔rr涓簎ndefined锛宒ata涓鸿幏鍙栧埌鐨勮瘑鐮佺粨鏋淎rray<scanBarcode.[ScanResult](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/scan-scanbarcode-api)>锛屽惁鍒欎负閿欒瀵硅薄銆?|
**閿欒鐮侊細**
浠ヤ笅閿欒鐮佺殑璇︾粏浠嬬粛璇峰弬瑙?[ArkTS API閿欒鐮乚(https://developer.huawei.com/consumer/cn/doc/harmonyos-references/scan-error-code) 銆?
| 閿欒鐮両D | 閿欒淇℃伅 |
| --- | --- |
| 401 | Parameter error. Possible causes: 1. Incorrect parameter types; 2. Parameter verification failed. |
| 1000500001 | Internal error. |
**绀轰緥锛?*
```typescript
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { scanCore, scanBarcode, detectBarcode } from '@kit.ScanKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
// 瀹氫箟璇嗙爜鍙傛暟options
let options: scanBarcode.ScanOptions = { scanTypes: [scanCore.ScanType.ALL], enableMultiMode: true, enableAlbum: true }
// 閫氳繃閫夋嫨妯″紡鎷夎捣photoPicker鐣岄潰锛岀敤鎴峰彲浠ラ€夋嫨涓€涓浘鐗?
let photoOption = new photoAccessHelper.PhotoSelectOptions();
photoOption.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
photoOption.maxSelectNumber = 1;
let photoPicker = new photoAccessHelper.PhotoViewPicker();
photoPicker.select(photoOption).then((result) => {
  // 瀹氫箟璇嗙爜鍙傛暟inputImage锛屽叾涓璾ri涓簆icker閫夋嫨鍥剧墖
  let inputImage: detectBarcode.InputImage = { uri: result.photoUris[0] };
  try {
    // 璋冪敤鍥剧墖璇嗙爜鎺ュ彛
    detectBarcode.decode(inputImage, options, (error: BusinessError, result: Array<scanBarcode.ScanResult>) => {
      if (error && error.code) {
        hilog.error(0x0001, '[Scan Sample]',
          `Failed to get ScanResult by callback with options. Code: ${error.code}, message: ${error.message}`);
        return;
      }
      hilog.info(0x0001, '[Scan Sample]',
        `Succeeded in getting ScanResult by callback with options, result is ${JSON.stringify(result)}`);
    });
  } catch (error) {
    hilog.error(0x0001, '[Scan Sample]',
      `Failed to detect Barcode. Code: ${error.code}, message: ${error.message}`);
  }
}).catch((error: BusinessError) => {
  hilog.error(0x0001, 'picker', `Failed to get PhotoSelectResult by promise. Code: ${error.code}`);
});
```
#### detectBarcode.decode
decode(inputImage: InputImage, callback: AsyncCallback<Array<scanBarcode.ScanResult>>): void
鍥剧墖璇嗙爜锛屼娇鐢–allback寮傛鍥炶皟杩斿洖璇嗙爜缁撴灉銆?
**绯荤粺鑳藉姏锛?* SystemCapability.Multimedia.Scan.ScanBarcode
**璧峰鐗堟湰锛?* 4.1.0(11)
**鍙傛暟锛?*
| 鍙傛暟鍚?| 绫诲瀷 | 蹇呭～ | 璇存槑 |
| --- | --- | --- | --- |
| inputImage | [InputImage](#section2194164873812) | 鏄?| 寰呰瘑鍒殑鍥剧墖淇℃伅銆?|
| callback | AsyncCallback<Array<scanBarcode.[ScanResult](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/scan-scanbarcode-api)>> | 鏄?| 鍥炶皟鍑芥暟锛屽綋鍥剧墖璇嗙爜鎴愬姛锛宔rr涓簎ndefined锛宒ata涓鸿幏鍙栧埌鐨勮瘑鐮佺粨鏋淎rray<scanBarcode.[ScanResult](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/scan-scanbarcode-api)>锛屽惁鍒欎负閿欒瀵硅薄銆?|
**閿欒鐮侊細**
浠ヤ笅閿欒鐮佺殑璇︾粏浠嬬粛璇峰弬瑙?[ArkTS API閿欒鐮乚(https://developer.huawei.com/consumer/cn/doc/harmonyos-references/scan-error-code) 銆?
| 閿欒鐮両D | 閿欒淇℃伅 |
| --- | --- |
| 401 | Parameter error. Possible causes: 1. Incorrect parameter types; 2. Parameter verification failed. |
| 1000500001 | Internal error. |
**绀轰緥锛?*
```typescript
import { scanBarcode, detectBarcode } from '@kit.ScanKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
// 閫氳繃picker鎷夎捣鍥惧簱骞堕€夋嫨鍥剧墖
let photoOption = new photoAccessHelper.PhotoSelectOptions();
photoOption.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
photoOption.maxSelectNumber = 1;
let photoPicker = new photoAccessHelper.PhotoViewPicker();
photoPicker.select(photoOption).then((result) => {
  // 瀹氫箟璇嗙爜鍙傛暟inputImage锛屽叾涓璾ri涓簆icker閫夋嫨鍥剧墖
  let inputImage: detectBarcode.InputImage = { uri: result.photoUris[0] };
  try {
    // 璋冪敤鍥剧墖璇嗙爜鎺ュ彛
    detectBarcode.decode(inputImage, (error: BusinessError, result: Array<scanBarcode.ScanResult>) => {
      if (error && error.code) {
        hilog.error(0x0001, '[Scan Sample]',
          `Failed to get ScanResult by callback. Code: ${error.code}, message: ${error.message}`);
        return;
      }
      hilog.info(0x0001, '[Scan Sample]',
        `Succeeded in getting ScanResult by callback, result is ${JSON.stringify(result)}`);
    });
  } catch (error) {
    hilog.error(0x0001, '[Scan Sample]',
      `Failed to detect Barcode. Code: ${error.code}, message: ${error.message}`);
  }
}).catch((error: BusinessError) => {
  hilog.error(0x0001, 'picker', `Failed to get PhotoSelectResult by promise. Code: ${error.code}`);
});
```
#### ByteImage
寰呰瘑鍒殑鍥惧儚鏁版嵁銆?
**绯荤粺鑳藉姏锛?* SystemCapability.Multimedia.Scan.ScanBarcode
**璧峰鐗堟湰锛?* 5.0.0(12)
| 鍚嶇О | 绫诲瀷 | 鍙 | 鍙€?| 璇存槑 |
| --- | --- | --- | --- | --- |
| byteBuffer | ArrayBuffer | 鍚?| 鍚?| 鍥惧儚鏁版嵁銆?|
| width | number | 鍚?| 鍚?| 鍥惧儚瀹藉害锛屽崟浣嶏細px銆?|
| height | number | 鍚?| 鍚?| 鍥惧儚楂樺害锛屽崟浣嶏細px銆?|
| format | [ImageFormat](#section326142720394) | 鍚?| 鍚?| 鍥惧儚鏁版嵁绫诲瀷銆?|
**绀轰緥锛?*
```typescript
import { detectBarcode } from '@kit.ScanKit';
// YUV鍥惧儚鐨刡uffer, height, width鏁版嵁锛屽彲閫氳繃鐩告満棰勮娴佹暟鎹幏鍙栵紝姣斿鑾峰彇瀹介珮鏄?920*1080鏃?
let byteImg: detectBarcode.ByteImage = {
  byteBuffer: buffer,
  width: 1920,
  height: 1080,
  format: detectBarcode.ImageFormat.NV21
};
```
#### ImageFormat
鏋氫妇锛屽浘鍍忔暟鎹被鍨嬨€?
**绯荤粺鑳藉姏锛?* SystemCapability.Multimedia.Scan.ScanBarcode
**璧峰鐗堟湰锛?* 5.0.0(12)
| **鍚嶇О** | **鍊?* | **璇存槑** |
| --- | --- | --- |
| NV21 | 0 | 鍥惧儚鏍煎紡涓篘V21銆?|
#### DetectResult
璇嗗埆缁撴灉銆?
**绯荤粺鑳藉姏锛?* SystemCapability.Multimedia.Scan.ScanBarcode
**璧峰鐗堟湰锛?* 5.0.0(12)
| 鍚嶇О | 绫诲瀷 | 鍙 | 鍙€?| 璇存槑 |
| --- | --- | --- | --- | --- |
| scanResults | Array<scanBarcode.[ScanResult](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/scan-scanbarcode-api)> | 鍚?| 鍚?| 鎵爜缁撴灉銆?|
| zoomValue | number | 鍚?| 鍚?| 鐩告満鍙彉鐒﹁窛姣旓紝閫氳繃[setZoomRatio](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/@ohos.multimedia.camera (鐩告満绠＄悊)/arkts-apis-camera-zoom)鎺у埗鐩告満瀹炵幇鍙樼劍鍔熻兘銆?*璇存槑锛?*浣跨敤Camera Kit[getZoomRatio](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/@ohos.multimedia.camera (鐩告満绠＄悊)/arkts-apis-camera-zoom)鎺ュ彛鑾峰彇鐩告満褰撳墠鍙樼劍姣攝oomRatio銆備娇鐢–amera Kit[setZoomRatio](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/@ohos.multimedia.camera (鐩告満绠＄悊)/arkts-apis-camera-zoom)鎺ュ彛璁剧疆targetRatio锛岀洰鏍囧€间负zoomRatio * zoomValue銆?|
#### detectBarcode.decodeImage
decodeImage(image: ByteImage, options?: scanBarcode.ScanOptions): Promise<DetectResult>
閫氳繃閰嶇疆鍙傛暟璋冪敤鍥惧儚鏁版嵁璇嗙爜鑳藉姏锛屼娇鐢≒romise寮傛鍥炶皟杩斿洖璇嗙爜缁撴灉銆?
**绯荤粺鑳藉姏锛?* SystemCapability.Multimedia.Scan.ScanBarcode
**璧峰鐗堟湰锛?* 5.0.0(12)
**鍙傛暟锛?*
| 鍙傛暟鍚?| 绫诲瀷 | 蹇呭～ | 璇存槑 |
| --- | --- | --- | --- |
| image | [ByteImage](#section596225419382) | 鏄?| 寰呰瘑鍒殑鍥惧儚鏁版嵁銆?|
| options | scanBarcode.[ScanOptions](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/scan-scanbarcode-api) | 鍚?| 鍚姩鍥惧儚鏁版嵁璇嗙爜鍙傛暟銆?|
**杩斿洖鍊硷細**
| **绫诲瀷** | **璇存槑** |
| --- | --- |
| Promise<[DetectResult](#section655375703713)> | Promise瀵硅薄锛岃繑鍥炲浘鍍忔暟鎹瘑鐮佺粨鏋滃璞°€?|
**閿欒鐮侊細**
浠ヤ笅閿欒鐮佺殑璇︾粏浠嬬粛璇峰弬瑙?[ArkTS API閿欒鐮乚(https://developer.huawei.com/consumer/cn/doc/harmonyos-references/scan-error-code) 銆?
| 閿欒鐮両D | 閿欒淇℃伅 |
| --- | --- |
| 401 | Parameter error. Possible causes: 1. Incorrect parameter types; 2. Parameter verification failed. |
| 1000500001 | Internal error. |
**绀轰緥锛?*
```typescript
import { scanCore, scanBarcode, detectBarcode } from '@kit.ScanKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
// 浼樺厛鑾峰彇鍥惧儚鐨刌UVByteBuffer, YUVHeight, YUVWidth鏁版嵁锛屾瘮濡傝幏鍙栧楂樻槸1920*1080鏃?
let byteImg: detectBarcode.ByteImage = {
  byteBuffer: YUVByteBuffer,
  width: 1920,
  height: 1080,
  format: detectBarcode.ImageFormat.NV21
};
let options: scanBarcode.ScanOptions = {
  scanTypes: [scanCore.ScanType.ALL],
  enableMultiMode: true,
  enableAlbum: false
};
try {
  detectBarcode.decodeImage(byteImg, options).then((result: detectBarcode.DetectResult) => {
    hilog.info(0x0001, '[Scan Sample]',
      `Succeeded in getting DetectResult by promise with options, result is ${JSON.stringify(result)}`);
  }).catch((error: BusinessError) => {
    hilog.error(0x0001, '[Scan Sample]',
      `Failed to get DetectResult by promise with options. Code: ${error.code}, message: ${error.message}`);
  });
} catch (error) {
  hilog.error(0x0001, '[Scan Sample]', `Failed to decode Image. Code: ${error.code}, message: ${error.message}`);
}
```
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/14/v3/TM3osXRqTRmub4tv9ZkDZA/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093647Z&HW-CC-Expire=86400&HW-CC-Sign=8261CEC2D55899E30237C547B549C6C2F9799E311A9B8AB8F5B0DE9F377939F0)
涓嶆敮鎸佸苟琛岃皟鐢ㄣ€
