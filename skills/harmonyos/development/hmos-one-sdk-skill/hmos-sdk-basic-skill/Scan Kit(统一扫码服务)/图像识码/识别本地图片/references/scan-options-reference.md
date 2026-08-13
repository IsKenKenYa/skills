# scanBarcode (榛樿鐣岄潰鎵爜)
---
# scanBarcode (榛樿鐣岄潰鎵爜)
鏈ā鍧楁彁渚涢粯璁ょ晫闈㈡壂鐮佽兘鍔涖€?
涓轰簡鏂逛究寮€鍙戣€呮帴鍏ワ紝鎴戜滑鎻愪緵浜嗚缁嗙殑鏍蜂緥宸ョ▼渚涘弬鑰冿紝鎺ㄨ崘鍙傝€?[绀轰緥宸ョ▼](https://gitcode.com/HarmonyOS_Samples/scan-kit_-sample-code_-clientdemo_-arkts) 鎺ュ叆銆?
**璧峰鐗堟湰锛?* 4.0.0(10)
#### 瀵煎叆妯″潡
```typescript
import { scanBarcode } from '@kit.ScanKit';
```
#### ScanResult
鎵爜缁撴灉銆?
**绯荤粺鑳藉姏锛?* SystemCapability.Multimedia.Scan.ScanBarcode
**璧峰鐗堟湰锛?* 4.0.0(10)
| **鍚嶇О** | **绫诲瀷** | 鍙 | **鍙€?* | **璇存槑** |
| --- | --- | --- | --- | --- |
| scanType | scanCore.[ScanType](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/scan-scancore) | 鍚?| 鍚?| 鐮佺被鍨嬨€?*鍏冩湇鍔PI锛?*浠庣増鏈?.1.0(11)寮€濮嬶紝璇ユ帴鍙ｆ敮鎸佸湪鍏冩湇鍔′腑浣跨敤銆?|
| originalValue | string | 鍚?| 鍚?| 鐮佽瘑鍒唴瀹圭粨鏋溿€?*鍏冩湇鍔PI锛?*浠庣増鏈?.1.0(11)寮€濮嬶紝璇ユ帴鍙ｆ敮鎸佸湪鍏冩湇鍔′腑浣跨敤銆?|
| scanCodeRect | [ScanCodeRect](#section1456184716188) | 鍚?| 鏄?| 鐮佽瘑鍒綅缃俊鎭€?*璧峰鐗堟湰锛?*4.1.0(11) |
| cornerPoints | Array<[Point](#section9634457911)> | 鍚?| 鏄?| 鐮佽瘑鍒鐐逛綅缃俊鎭紝杩斿洖QR Code鍥涗釜瑙掔偣銆傛鍙傛暟浠呭浘鍍忚瘑鐮佹帴鍙detectBarcode.decodeImage](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/scan-imagedecode)杩斿洖銆?*璧峰鐗堟湰锛?*5.0.0(12) |
| isGS1 | boolean | 鍚?| 鏄?| 鐮佸浘鏄惁鎼哄甫GS1锛圙lobal Standards 1锛夋暟鎹€倀rue琛ㄧず鐮佸浘鎼哄甫GS1鏁版嵁锛沠alse琛ㄧず鐮佸浘涓嶆惡甯S1鏁版嵁銆傞粯璁ゅ€兼槸false銆?*鍏冩湇鍔PI锛?*浠庣増鏈?.0.2(22)寮€濮嬶紝璇ユ帴鍙ｆ敮鎸佸湪鍏冩湇鍔′腑浣跨敤銆?*璧峰鐗堟湰锛?*6.0.2(22) |
| source | scanCore.[ScanSource](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/scan-scancore) | 鍚?| 鏄?| 鎵爜缁撴灉鏉ユ簮銆傛鍙傛暟浠呴粯璁ょ晫闈㈡壂鐮佹帴鍙ｈ繑鍥炪€?*妯″瀷绾︽潫锛?*姝ゆ帴鍙ｄ粎鍙湪Stage妯″瀷涓嬩娇鐢ㄣ€?*鍏冩湇鍔PI锛?*浠庣増鏈?.0.2(22)寮€濮嬶紝璇ユ帴鍙ｆ敮鎸佸湪鍏冩湇鍔′腑浣跨敤銆?*璧峰鐗堟湰锛?*6.0.2(22) |
#### ScanCodeRect
鐮佺殑浣嶇疆淇℃伅銆備娇鐢ㄩ粯璁ゆ壂鐮佹帴鍙ｏ紙startScan鍜宻tartScanForResult锛変笉杩斿洖鐮佷綅缃€?
**绯荤粺鑳藉姏锛?* SystemCapability.Multimedia.Scan.ScanBarcode
**璧峰鐗堟湰锛?* 4.1.0(11)
| **鍚嶇О** | **绫诲瀷** | 鍙 | **鍙€?* | **璇存槑** |
| --- | --- | --- | --- | --- |
| left | number | 鍚?| 鍚?| 鐮佸鎺ョ煩褰㈠乏涓婅鐨剎鍧愭爣銆傚崟浣嶏細px銆?|
| top | number | 鍚?| 鍚?| 鐮佸鎺ョ煩褰㈠乏涓婅鐨剏鍧愭爣銆傚崟浣嶏細px銆?|
| right | number | 鍚?| 鍚?| 鐮佸鎺ョ煩褰㈠彸涓嬭鐨剎鍧愭爣銆傚崟浣嶏細px銆?|
| bottom | number | 鍚?| 鍚?| 鐮佸鎺ョ煩褰㈠彸涓嬭鐨剏鍧愭爣銆傚崟浣嶏細px銆?|
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/c9/v3/2lASvKPcRMq6geX1N4wCUA/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093647Z&HW-CC-Expire=86400&HW-CC-Sign=9B700A85DFC02AE5D8C6EA209556417D297FFFD7EC434233A51E4466844B5554)
鑷畾涔夌晫闈㈡壂鐮佽繑鍥炵殑鍧愭爣鍗曚綅涓庝紶鍏ュ弬鏁?[ViewControl](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/scan-customscan-api) 涓瓀idth銆乭eight鍗曚綅涓€鑷淬€?
#### Point
鐐瑰潗鏍囷紝璇ュ潗鏍囩郴宸︿笂瑙掍负{0锛?}锛屾鍧愭爣绯绘槸浠ヨ澶囧厖鐢靛彛鍦ㄥ彸渚ф椂鐨勬í鍚戣澶囨柟鍚戜负鍩哄噯鐨勩€?
**绯荤粺鑳藉姏锛?* SystemCapability.Multimedia.Scan.ScanBarcode
**璧峰鐗堟湰锛?* 5.0.0(12)
| **鍚嶇О** | **绫诲瀷** | 鍙 | **鍙€?* | **璇存槑** |
| --- | --- | --- | --- | --- |
| x | number | 鍚?| 鍚?| X杞村潗鏍囷紝鍗曚綅锛歱x銆?|
| y | number | 鍚?| 鍚?| Y杞村潗鏍囷紝鍗曚綅锛歱x銆?|
#### ScanOptions
鎵爜銆佽瘑鐮佸弬鏁般€?
**鍏冩湇鍔PI锛?* 浠庣増鏈?.1.0(11)寮€濮嬶紝璇ユ帴鍙ｆ敮鎸佸湪鍏冩湇鍔′腑浣跨敤銆?
**绯荤粺鑳藉姏锛?* SystemCapability.Multimedia.Scan.ScanBarcode
**璧峰鐗堟湰锛?* 4.0.0(10)
| **鍚嶇О** | **绫诲瀷** | 鍙 | **鍙€?* | **璇存槑** |
| --- | --- | --- | --- | --- |
| scanTypes | Array<scanCore.[ScanType](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/scan-scancore)> | 鍚?| 鏄?| 璁剧疆鎵爜绫诲瀷锛岄粯璁ゆ壂鐮丄LL锛堝叏閮ㄧ爜绫诲瀷锛夈€?|
| enableMultiMode | boolean | 鍚?| 鏄?| 鏄惁寮€鍚鐮佽瘑鍒紝榛樿false銆倀rue锛氬鐮佽瘑鍒€俧alse锛氬崟鐮佽瘑鍒€?|
| enableAlbum | boolean | 鍚?| 鏄?| 鏄惁寮€鍚浉鍐岋紝榛樿true銆倀rue锛氬紑鍚浉鍐屾壂鐮併€俧alse锛氬叧闂浉鍐屾壂鐮併€傛鍙傛暟鍙帶鍒堕粯璁ょ晫闈㈡壂鐮佽兘鍔涗腑鐨勭浉鍐岃瘑鐮佷笖鐩稿唽璇嗙爜鍙敮鎸佸崟鐮佽瘑鍒€?|
**绀轰緥锛?*
```typescript
import { scanBarcode, scanCore } from '@kit.ScanKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
// 瀹氫箟鎵爜鍙傛暟options
let options: scanBarcode.ScanOptions = { scanTypes: [scanCore.ScanType.ALL], enableMultiMode: true, enableAlbum: true };
function loadPage(uiContext : UIContext) {
  try {
    scanBarcode.startScanForResult(uiContext.getHostContext(), options).then((result: scanBarcode.ScanResult) => {
      hilog.info(0x0001, '[Scan Sample]',
        `Succeeded in getting ScanResult by promise with options, result is ${JSON.stringify(result)}`);
    }).catch((error: BusinessError) => {
      hilog.error(0x0001, '[Scan Sample]',
        `Failed to get ScanResult by promise with options. Code: ${error.code}, message: ${error.message}`);
    });
  } catch (error) {
    hilog.error(0x0001, '[Scan Sample]',
      `Failed to startScanForResult. Code: ${error.code}, message: ${error.message}`);
  }
}
```
#### scanBarcode.startScanForResult
startScanForResult(context: common.Context, options?: ScanOptions): Promise<ScanResult>
閫氳繃閰嶇疆鍙傛暟璋冪敤榛樿鐣岄潰鎵爜锛屼娇鐢≒romise寮傛鍥炶皟杩斿洖瑙ｇ爜缁撴灉銆傞渶瑕佸湪椤甸潰鍜岀粍浠剁殑鐢熷懡鍛ㄦ湡鍐呰皟鐢ㄣ€?
**妯″瀷绾︽潫锛?* 姝ゆ帴鍙ｄ粎鍙湪Stage妯″瀷涓嬩娇鐢ㄣ€?
**鍏冩湇鍔PI锛?* 浠庣増鏈?.1.0(11)寮€濮嬶紝璇ユ帴鍙ｆ敮鎸佸湪鍏冩湇鍔′腑浣跨敤銆?
**绯荤粺鑳藉姏锛?* SystemCapability.Multimedia.Scan.ScanBarcode
**璧峰鐗堟湰锛?* 4.1.0(11)
**鍙傛暟锛?*
| **鍙傛暟鍚?* | **绫诲瀷** | 蹇呭～ | **璇存槑** |
| --- | --- | --- | --- |
| context | [common.Context](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/Stage妯″瀷鑳藉姏鐨勬帴鍙?js-apis-app-ability-common) | 鏄?| 搴旂敤涓婁笅鏂囥€?|
| options | [ScanOptions](#section1285191073117) | 鍚?| 鍚姩鎵爜鍙傛暟銆?|
**杩斿洖鍊硷細**
| **绫诲瀷** | **璇存槑** |
| --- | --- |
| Promise<[ScanResult](#section10614317162112)> | Promise瀵硅薄锛岃繑鍥炴壂鐮佺粨鏋滃璞°€?|
**閿欒鐮侊細**
浠ヤ笅閿欒鐮佺殑璇︾粏浠嬬粛璇峰弬瑙?[ArkTS API閿欒鐮乚(https://developer.huawei.com/consumer/cn/doc/harmonyos-references/scan-error-code) 銆?
| 閿欒鐮両D | 閿欒淇℃伅 |
| --- | --- |
| 401 | Parameter error. Possible causes: 1. Incorrect parameter types; 2. Parameter verification failed. |
| 1000500001 | Internal error. |
| 1000500002 | The user canceled the barcode scanning. |
**绀轰緥锛?*
```typescript
import { scanBarcode, scanCore } from '@kit.ScanKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
// 瀹氫箟鎵爜鍙傛暟options
let options: scanBarcode.ScanOptions = { scanTypes: [scanCore.ScanType.ALL], enableMultiMode: true, enableAlbum: true };
function loadPage(uiContext : UIContext) {
  try {
    scanBarcode.startScanForResult(uiContext.getHostContext(), options).then((result: scanBarcode.ScanResult) => {
      hilog.info(0x0001, '[Scan Sample]',
        `Succeeded in getting ScanResult by promise with options, result is ${JSON.stringify(result)}`);
    }).catch((error: BusinessError) => {
      hilog.error(0x0001, '[Scan Sample]',
        `Failed to get ScanResult by promise with options. Code: ${error.code}, message: ${error.message}`);
    });
  } catch (error) {
    hilog.error(0x0001, '[Scan Sample]',
      `Failed to startScanForResult. Code: ${error.code}, message: ${error.message}`);
  }
}
```
#### scanBarcode.startScanForResult
startScanForResult(context: common.Context, callback: AsyncCallback<ScanResult>): void
鍚姩榛樿鐣岄潰鎵爜锛屼娇鐢–allback寮傛鍥炶皟杩斿洖瑙ｇ爜缁撴灉銆傞渶瑕佸湪椤甸潰鍜岀粍浠剁殑鐢熷懡鍛ㄦ湡鍐呰皟鐢ㄣ€?
**妯″瀷绾︽潫锛?* 姝ゆ帴鍙ｄ粎鍙湪Stage妯″瀷涓嬩娇鐢ㄣ€?
**鍏冩湇鍔PI锛?* 浠庣増鏈?.1.0(11)寮€濮嬶紝璇ユ帴鍙ｆ敮鎸佸湪鍏冩湇鍔′腑浣跨敤銆?
**绯荤粺鑳藉姏锛?* SystemCapability.Multimedia.Scan.ScanBarcode
**璧峰鐗堟湰锛?* 4.1.0(11)
**鍙傛暟锛?*
| **鍙傛暟鍚?* | **绫诲瀷** | **蹇呭～** | **璇存槑** |
| --- | --- | --- | --- |
| context | [common.Context](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/Stage妯″瀷鑳藉姏鐨勬帴鍙?js-apis-app-ability-common) | 鏄?| 搴旂敤涓婁笅鏂囥€?|
| callback | AsyncCallback<[ScanResult](#section10614317162112)> | 鏄?| 鍥炶皟鍑芥暟銆傚綋鎵爜杩斿洖鎴愬姛锛宔rr涓簎ndefined锛宒ata涓鸿幏鍙栧埌鐨勬壂鐮佺粨鏋滃璞ScanResult](#section10614317162112)锛涘惁鍒欎负閿欒瀵硅薄銆?|
**閿欒鐮侊細**
浠ヤ笅閿欒鐮佺殑璇︾粏浠嬬粛璇峰弬瑙?[ArkTS API閿欒鐮乚(https://developer.huawei.com/consumer/cn/doc/harmonyos-references/scan-error-code) 銆?
| 閿欒鐮両D | 閿欒淇℃伅 |
| --- | --- |
| 401 | Parameter error. Possible causes: 1. Incorrect parameter types; 2. Parameter verification failed. |
| 1000500001 | Internal error. |
| 1000500002 | The user canceled the barcode scanning. |
**绀轰緥锛?*
```typescript
import { scanBarcode } from '@kit.ScanKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
// 鍚姩鎵爜锛屾媺璧锋壂鐮佺晫闈?
function loadPage(uiContext : UIContext) {
  try {
    scanBarcode.startScanForResult(uiContext.getHostContext(), (error: BusinessError, result: scanBarcode.ScanResult) => {
      if (error) {
        hilog.error(0x0001, '[Scan Sample]',
          `Failed to get ScanResult by callback. Code: ${error.code}, message: ${error.message}`);
        return;
      }
      hilog.info(0x0001, '[Scan Sample]',
        `Succeeded in getting ScanResult by callback, result is ${JSON.stringify(result)}`);
    });
  } catch (error) {
    hilog.error(0x0001, '[Scan Sample]', `Failed to startScanForResult. Code: ${error.code}, message: ${error.message}`);
  }
}
```
#### scanBarcode.startScanForResult
startScanForResult(context: common.Context, options: ScanOptions, callback: AsyncCallback<ScanResult>): void
閫氳繃閰嶇疆鍙傛暟璋冪敤榛樿鐣岄潰鎵爜锛屼娇鐢–allback寮傛鍥炶皟杩斿洖瑙ｇ爜缁撴灉銆傞渶瑕佸湪椤甸潰鍜岀粍浠剁殑鐢熷懡鍛ㄦ湡鍐呰皟鐢ㄣ€?
**妯″瀷绾︽潫锛?* 姝ゆ帴鍙ｄ粎鍙湪Stage妯″瀷涓嬩娇鐢ㄣ€?
**鍏冩湇鍔PI锛?* 浠庣増鏈?.1.0(11)寮€濮嬶紝璇ユ帴鍙ｆ敮鎸佸湪鍏冩湇鍔′腑浣跨敤銆?
**绯荤粺鑳藉姏锛?* SystemCapability.Multimedia.Scan.ScanBarcode
**璧峰鐗堟湰锛?* 4.1.0(11)
**鍙傛暟锛?*
| **鍙傛暟鍚?* | **绫诲瀷** | **蹇呭～** | **璇存槑** |
| --- | --- | --- | --- |
| context | [common.Context](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/Stage妯″瀷鑳藉姏鐨勬帴鍙?js-apis-app-ability-common) | 鏄?| 搴旂敤涓婁笅鏂囥€?|
| options | [ScanOptions](#section1285191073117) | 鏄?| 鍚姩鎵爜鍙傛暟銆?|
| callback | AsyncCallback<[ScanResult](#section10614317162112)> | 鏄?| 鍥炶皟鍑芥暟銆傚綋鎵爜杩斿洖鎴愬姛锛宔rr涓簎ndefined锛宒ata涓鸿幏鍙栧埌鐨勬壂鐮佺粨鏋滃璞ScanResult](#section10614317162112)锛涘惁鍒欎负閿欒瀵硅薄銆?|
**閿欒鐮?*
浠ヤ笅閿欒鐮佺殑璇︾粏浠嬬粛璇峰弬瑙?[ArkTS API閿欒鐮乚(https://developer.huawei.com/consumer/cn/doc/harmonyos-references/scan-error-code) 銆?
| 閿欒鐮両D | 閿欒淇℃伅 |
| --- | --- |
| 401 | Parameter error. Possible causes: 1. Incorrect parameter types; 2. Parameter verification failed. |
| 1000500001 | Internal error. |
| 1000500002 | The user canceled the barcode scanning. |
**绀轰緥锛?*
```typescript
import { scanCore, scanBarcode } from '@kit.ScanKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
// 瀹氫箟鎵爜鍙傛暟options
let options: scanBarcode.ScanOptions = { scanTypes: [scanCore.ScanType.ALL], enableMultiMode: true, enableAlbum: true };
// 鍚姩鎵爜锛屾媺璧锋壂鐮佺晫闈?
function loadPage(uiContext : UIContext) {
  try {
    scanBarcode.startScanForResult(uiContext.getHostContext(), options, (error: BusinessError, result: scanBarcode.ScanResult) => {
      if (error) {
        hilog.error(0x0001, '[Scan Sample]',
          `Failed to get ScanResult by callback with options. Code: ${error.code}, message: ${error.message}`);
        return;
      }
      hilog.info(0x0001, '[Scan Sample]',
        `Succeeded in getting ScanResult by callback with options, result is ${JSON.stringify(result)}`);
    });
  } catch (error) {
    hilog.error(0x0001, '[Scan Sample]', `Failed to startScanForResult. Code: ${error.code}, message: ${error.message}`);
  }
}
```
#### scanBarcode.startScan(deprecated)
startScan(options?: ScanOptions): Promise<ScanResult>
閫氳繃閰嶇疆鍙傛暟璋冪敤榛樿鐣岄潰鎵爜锛屼娇鐢≒romise寮傛鍥炶皟杩斿洖鎵爜缁撴灉銆?
**搴熷純璇存槑锛?* 浠庣増鏈?.1.0(11)寮€濮嬪簾寮冿紝寤鸿浣跨敤 [startScanForResult](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/scan-scanbarcode-api) 鏇夸唬銆?
**绯荤粺鑳藉姏锛?* SystemCapability.Multimedia.Scan.ScanBarcode
**璧峰鐗堟湰锛?* 4.0.0(10)
**鍙傛暟锛?*
| **鍙傛暟鍚?* | **绫诲瀷** | 蹇呭～ | **璇存槑** |
| --- | --- | --- | --- |
| options | [ScanOptions](#section1285191073117) | 鍚?| 鍚姩鎵爜鍙傛暟銆?|
**杩斿洖鍊硷細**
| **绫诲瀷** | **璇存槑** |
| --- | --- |
| Promise<[ScanResult](#section10614317162112)> | Promise瀵硅薄锛岃繑鍥炴壂鐮佺粨鏋滃璞°€?|
**閿欒鐮侊細**
浠ヤ笅閿欒鐮佺殑璇︾粏浠嬬粛璇峰弬瑙?[ArkTS API閿欒鐮乚(https://developer.huawei.com/consumer/cn/doc/harmonyos-references/scan-error-code) 銆?
| 閿欒鐮両D | 閿欒淇℃伅 |
| --- | --- |
| 401 | Parameter error. Possible causes: 1. Incorrect parameter types; 2. Parameter verification failed. |
**绀轰緥锛?*
```typescript
import { scanCore, scanBarcode } from '@kit.ScanKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
// 鏋勯€犲惎鍔ㄦ壂鐮佺殑鍏ュ弬options
let options: scanBarcode.ScanOptions = { scanTypes: [scanCore.ScanType.ALL], enableMultiMode: true, enableAlbum: true };
try {
  scanBarcode.startScan(options).then((result: scanBarcode.ScanResult) => {
    hilog.info(0x0001, '[Scan Sample]',
      `Succeeded in getting ScanResult by promise with options, result is ${JSON.stringify(result)}`);
  }).catch((error: BusinessError) => {
    // 褰撴壂鐮佽繃绋嬩腑鍑虹幇閿欒鎵撳嵃鎶ラ敊骞惰繑鍥?
    hilog.error(0x0001, '[Scan Sample]',
      `Failed to get ScanResult by promise with options. Code: ${error.code}, message: ${error.message}`);
  });
} catch (error) {
  hilog.error(0x0001, '[Scan Sample]', `Failed to startScan. Code: ${error.code}, message: ${error.message}`);
}
```
#### scanBarcode.startScan(deprecated)
startScan(callback: AsyncCallback<ScanResult>): void
鍚姩榛樿鐣岄潰鎵爜锛屼娇鐢–allback寮傛鍥炶皟杩斿洖鎵爜缁撴灉銆?
**搴熷純璇存槑锛?* 浠庣増鏈?.1.0(11)寮€濮嬪簾寮冿紝寤鸿浣跨敤 [startScanForResult](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/scan-scanbarcode-api) 鏇夸唬銆?
**绯荤粺鑳藉姏锛?* SystemCapability.Multimedia.Scan.ScanBarcode
**璧峰鐗堟湰锛?* 4.0.0(10)
**鍙傛暟锛?*
| **鍙傛暟鍚?* | **绫诲瀷** | 蹇呭～ | **璇存槑** |
| --- | --- | --- | --- |
| callback | AsyncCallback<[ScanResult](#section10614317162112)> | 鏄?| 鍥炶皟鍑芥暟銆傚綋鎵爜杩斿洖鎴愬姛锛宔rr涓簎ndefined锛宒ata涓鸿幏鍙栧埌鐨勬壂鐮佺粨鏋滃璞ScanResult](#section10614317162112)锛涘惁鍒欎负閿欒瀵硅薄銆?|
**閿欒鐮侊細**
浠ヤ笅閿欒鐮佺殑璇︾粏浠嬬粛璇峰弬瑙?[ArkTS API閿欒鐮乚(https://developer.huawei.com/consumer/cn/doc/harmonyos-references/scan-error-code) 銆?
| 閿欒鐮両D | 閿欒淇℃伅 |
| --- | --- |
| 401 | Parameter error. Possible causes: 1. Incorrect parameter types; 2. Parameter verification failed. |
**绀轰緥锛?*
```typescript
import { scanBarcode } from '@kit.ScanKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
try {
  scanBarcode.startScan((error: BusinessError, result: scanBarcode.ScanResult) => {
    // error鍥炶皟鐩戝惉锛屽綋鎵爜杩囩▼涓嚭鐜伴敊璇墦鍗版姤閿欏苟杩斿洖
    if (error) {
      hilog.error(0x0001, '[Scan Sample]',
        `Failed to get ScanResult by callback. Code: ${error.code}, message: ${error.message}`);
      return;
    }
    hilog.info(0x0001, '[Scan Sample]',
      `Succeeded in getting ScanResult by callback, result is ${JSON.stringify(result)}`);
  });
} catch (error) {
  hilog.error(0x0001, '[Scan Sample]', `Failed to startScan. Code: ${error.code}, message: ${error.message}`);
}
```
#### scanBarcode.startScan(deprecated)
startScan(options: ScanOptions, callback: AsyncCallback<ScanResult>): void
閫氳繃閰嶇疆鍙傛暟璋冪敤榛樿鐣岄潰鎵爜锛屼娇鐢–allback寮傛鍥炶皟杩斿洖鎵爜缁撴灉銆?
**搴熷純璇存槑锛?* 浠庣増鏈?.1.0(11)寮€濮嬪簾寮冿紝寤鸿浣跨敤 [startScanForResult](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/scan-scanbarcode-api) 鏇夸唬銆?
**绯荤粺鑳藉姏锛?* SystemCapability.Multimedia.Scan.ScanBarcode
**璧峰鐗堟湰锛?* 4.0.0(10)
**鍙傛暟锛?*
| **鍙傛暟鍚?* | **绫诲瀷** | **蹇呭～** | **璇存槑** |
| --- | --- | --- | --- |
| options | [ScanOptions](#section1285191073117) | 鏄?| 鍚姩鎵爜鍙傛暟銆?|
| callback | AsyncCallback<[ScanResult](#section10614317162112)> | 鏄?| 鍥炶皟鍑芥暟锛屽綋鎵爜杩斿洖鎴愬姛锛宔rr涓簎ndefined锛宒ata涓鸿幏鍙栧埌鐨勬壂鐮佺粨鏋滃璞ScanResult](#section10614317162112)锛涘惁鍒欎负閿欒瀵硅薄銆?|
**閿欒鐮侊細**
浠ヤ笅閿欒鐮佺殑璇︾粏浠嬬粛璇峰弬瑙?[ArkTS API閿欒鐮乚(https://developer.huawei.com/consumer/cn/doc/harmonyos-references/scan-error-code) 銆?
| 閿欒鐮両D | 閿欒淇℃伅 |
| --- | --- |
| 401 | Parameter error. Possible causes: 1. Incorrect parameter types; 2. Parameter verification failed. |
**绀轰緥锛?*
```typescript
import { scanCore, scanBarcode } from '@kit.ScanKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
// 鏋勯€犲惎鍔ㄦ壂鐮佺殑鍏ュ弬options
let options: scanBarcode.ScanOptions = { scanTypes: [scanCore.ScanType.ALL], enableMultiMode: true, enableAlbum: true };
try {
  scanBarcode.startScan(options, (error: BusinessError, result: scanBarcode.ScanResult) => {
    // error鍥炶皟鐩戝惉锛屽綋鎵爜杩囩▼涓嚭鐜伴敊璇墦鍗版姤閿欏苟杩斿洖
    if (error) {
      hilog.error(0x0001, '[Scan Sample]',
        `Failed to get ScanResult by callback with options. Code: ${error.code}, message: ${error.message}`);
      return;
    }
    hilog.info(0x0001, '[Scan Sample]',
      `Succeeded in getting ScanResult by callback with options, result is ${JSON.stringify(result)}`);
  });
} catch (error) {
  hilog.error(0x0001, '[Scan Sample]', `Failed to startScan. Code: ${error.code}, message: ${error.message}`);
}
```
