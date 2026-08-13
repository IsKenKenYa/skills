---
name: hmos-scan-kit-detect-barcode
description: 识别本地图片中的条形码/二维码/MULTIFUNCTIONAL CODE,返回码类型、码值、码位置信息,支持单码和多码识别模式,适用于图库扫码、付款码识别等场景
---

# 识别本地图片技能

## 功能描述

本技能通过调用Scan Kit的detectBarcode.decode接口,实现对本地图片中的条形码、二维码、MULTIFUNCTIONAL CODE的识别。支持一图单码和一图多码识别模式,可获取码类型、码值、码位置(码图最小外接矩形左上角和右下角的坐标)等详细信息。

**核心能力**:
- 识别图库中的条形码、二维码、MULTIFUNCTIONAL CODE
- 获取码类型、码值、码位置信息
- 支持单码和多码识别模式
- 支持通过PhotoPicker选择图片

**API版本**: 4.1.0(11)起支持

## 使用场景

### 触发词
- "识别本地图片"
- "图片识码"
- "识别图库中的码"
- "扫描本地二维码"
- "识别本地条形码"
- "图库扫码"

### 能做
- 识别本地图片中的条形码、二维码、MULTIFUNCTIONAL CODE
- 返回码类型(scanType)、码值(originalValue)、码位置(scanCodeRect)等信息
- 支持单码识别和多码识别模式切换
- 通过PhotoPicker从图库选择图片进行识别
- 返回码图四个角点位置信息(cornerPoints)

### 绝不做
- 不识别相机实时流数据(使用自定义扫码接口)
- 不启动默认扫码界面(使用scanBarcode.startScanForResult)
- 不识别非图片格式的文件
- 不处理网络图片URL(仅支持本地图片路径)
- 不并行调用多次识码接口

### 补充
- 推荐使用PhotoPicker获取图片路径
- 图片路径格式必须为file://协议(例如file://media/Photo/x/xxx.jpg)
- 多码识别时返回结果数组,单码识别返回单个结果
- 错误处理必须捕获BusinessError异常
- 不支持并行调用decode接口

## 调用规范和规则

### 输入约束
- 图片格式: 支持常见图片格式(JPG、PNG等)
- 图片路径: 必须为file://协议的本地路径
- 图片数量: 每次识别1张图片
- 图片大小: 无明确限制,建议不超过10MB

### 执行约束
- 最大耗时: 建议5秒内完成识别
- API调用频次: 不支持并行调用,需串行执行
- 异步模式: 支持Promise和Callback两种异步回调方式

### 内容约束
- 禁止使用: 非file://协议的路径
- 禁止操作: 并行调用多个decode接口
- 禁止参数: 不支持网络URL路径

### 降级约束
- 图片路径无效: 提示用户重新选择图片
- 识别失败: 返回空数组或错误信息
- 参数错误: 捕获401错误码并提示参数校验失败
- 内部错误: 捕获1000500001错误码并提示系统内部错误

## 调用流程和步骤

### 步骤1: 导入模块和准备参数

**导入必要模块**:
```typescript
import { scanCore, scanBarcode, detectBarcode } from '@kit.ScanKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
```

**定义识码参数options**:
```typescript
let options: scanBarcode.ScanOptions = {
  scanTypes: [scanCore.ScanType.ALL],  // 识别所有码类型
  enableMultiMode: true,                // 开启多码识别模式
  enableAlbum: true                     // 开启相册识码
};
```

### 步骤2: 通过PhotoPicker选择图片

**使用PhotoPicker拉起图库**:
```typescript
let photoOption = new photoAccessHelper.PhotoSelectOptions();
photoOption.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
photoOption.maxSelectNumber = 1;
photoOption.isPhotoTakingSupported = false;
photoOption.isEditSupported = false;

let photoPicker = new photoAccessHelper.PhotoViewPicker();
photoPicker.select(photoOption).then((result: photoAccessHelper.PhotoSelectResult) => {
  if (!result || (result.photoUris && result.photoUris.length === 0)) {
    hilog.error(0x0001, '[Scan Sample]', 'Failed to get PhotoSelectResult');
    return;
  }
  
  let inputImage: detectBarcode.InputImage = { 
    uri: result.photoUris[0] 
  };
  
  // 继续调用识码接口...
}).catch((error: BusinessError) => {
  hilog.error(0x0001, '[Scan Sample]', 
    `Failed to select photo. Code: ${error.code}, message: ${error.message}`);
});
```

### 步骤3: 调用图片识码接口(Promise方式)

**调用detectBarcode.decode接口**:
```typescript
try {
  detectBarcode.decode(inputImage, options).then((data: Array<scanBarcode.ScanResult>) => {
    hilog.info(0x0001, '[Scan Sample]', 
      `Succeeded in getting ScanResult. result is ${JSON.stringify(data)}`);
    
    // 处理识码结果
    if (data && data.length > 0) {
      for (let result of data) {
        hilog.info(0x0001, '[Scan Sample]', 
          `scanType: ${result.scanType}, originalValue: ${result.originalValue}`);
        
        if (result.scanCodeRect) {
          hilog.info(0x0001, '[Scan Sample]', 
            `position: left=${result.scanCodeRect.left}, top=${result.scanCodeRect.top}, 
             right=${result.scanCodeRect.right}, bottom=${result.scanCodeRect.bottom}`);
        }
      }
    }
  }).catch((err: BusinessError) => {
    hilog.error(0x0001, '[Scan Sample]', 
      `Failed to get ScanResult. Code: ${err.code}, message: ${err.message}`);
  });
} catch (error) {
  hilog.error(0x0001, '[Scan Sample]', 
    `Failed to detectBarcode. Code: ${error.code}, message: ${error.message}`);
}
```

### 步骤4: 调用图片识码接口(Callback方式)

**使用Callback异步回调**:
```typescript
try {
  detectBarcode.decode(inputImage, options, 
    (err: BusinessError, data: Array<scanBarcode.ScanResult>) => {
      if (err && err.code) {
        hilog.error(0x0001, '[Scan Sample]', 
          `Failed to get ScanResult. Code: ${err.code}, message: ${err.message}`);
        return;
      }
      
      hilog.info(0x0001, '[Scan Sample]', 
        `Succeeded in getting ScanResult. result is ${JSON.stringify(data)}`);
      
      // 处理识码结果
      if (data && data.length > 0) {
        for (let result of data) {
          hilog.info(0x0001, '[Scan Sample]', 
            `scanType: ${result.scanType}, originalValue: ${result.originalValue}`);
        }
      }
    });
} catch (error) {
  hilog.error(0x0001, '[Scan Sample]', 
    `Failed to detectBarcode. Code: ${error.code}, message: ${error.message}`);
}
```

### 步骤5: 错误处理

**捕获和处理错误码**:
```typescript
catch((error: BusinessError) => {
  switch (error.code) {
    case 401:
      hilog.error(0x0001, '[Scan Sample]', 
        'Parameter error. Possible causes: 1. Incorrect parameter types; 2. Parameter verification failed.');
      break;
    case 1000500001:
      hilog.error(0x0001, '[Scan Sample]', 'Internal error.');
      break;
    default:
      hilog.error(0x0001, '[Scan Sample]', 
        `Unknown error. Code: ${error.code}, message: ${error.message}`);
  }
})
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误。可能原因:1.参数类型错误;2.参数校验失败 | 检查inputImage.uri路径格式是否为file://协议,检查options参数类型 |
| 1000500001 | 内部错误 | 检查系统状态,重启应用或设备,如持续出现请联系技术支持 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.ScanKit": "系统Kit,无需额外安装",
    "@kit.MediaLibraryKit": "系统Kit,无需额外安装",
    "@kit.PerformanceAnalysisKit": "系统Kit,无需额外安装",
    "@kit.BasicServicesKit": "系统Kit,无需额外安装"
  }
}
```

### 环境要求
- HarmonyOS API版本: 最低4.1.0(11)
- 开发环境: DevEco Studio
- 运行环境: HarmonyOS设备或模拟器

### 常见编译问题

**问题1: 导入模块失败**
```
Cannot find module '@kit.ScanKit' or its corresponding type declarations.
```
**解决方法**: 确保项目API版本不低于4.1.0(11),在module.json5中配置正确的compileSdkVersion

**问题2: PhotoPicker选择失败**
```
Failed to get PhotoSelectResult by promise. Code: xxx
```
**解决方法**: 检查应用是否申请了媒体库权限(ohos.permission.READ_MEDIA),在module.json5中添加权限声明

**问题3: 图片路径格式错误**
```
Parameter error. Possible causes: 1. Incorrect parameter types
```
**解决方法**: 确保inputImage.uri使用file://协议格式,例如file://media/Photo/x/xxx.jpg

## 常见问题与解决方法

### Q1: 如何判断识别结果是单码还是多码?
**原因**: enableMultiMode参数控制识别模式
**解决方法**:
- 设置enableMultiMode为true开启多码识别,返回结果数组
- 设置enableMultiMode为false或默认值,单码识别返回单个结果

### Q2: 识别结果中的scanCodeRect坐标是什么含义?
**原因**: scanCodeRect表示码图的外接矩形位置
**解决方法**:
- left: 码外接矩形左上角的x坐标(单位px)
- top: 码外接矩形左上角的y坐标(单位px)
- right: 码外接矩形右下角的x坐标(单位px)
- bottom: 码外接矩形右下角的y坐标(单位px)

### Q3: 为什么无法识别某些二维码?
**原因**: 可能图片质量问题或码类型限制
**解决方法**:
- 检查图片清晰度和光线条件
- 确认scanTypes参数包含需要识别的码类型
- 使用scanCore.ScanType.ALL识别所有码类型

### Q4: PhotoPicker返回的路径格式是什么?
**原因**: PhotoPicker返回file://协议路径
**解决方法**:
- PhotoPicker返回路径格式为: file://media/Photo/xxx/filename.jpg
- 直接将photoUris[0]赋值给inputImage.uri即可

### Q5: 如何处理识别失败的情况?
**原因**: 图片中可能没有码或识别算法失败
**解决方法**:
- 检查返回的ScanResult数组长度
- 如果数组为空或长度为0,表示未识别到码
- 通过error回调捕获错误码并处理异常

## 输出结果报告

执行完成后输出以下信息:

```json
{
  "status": "success",
  "scanResults": [
    {
      "scanType": "QR_CODE",
      "originalValue": "https://example.com",
      "scanCodeRect": {
        "left": 100,
        "top": 150,
        "right": 300,
        "bottom": 350
      }
    }
  ],
  "resultCount": 1,
  "apiUsed": [
    "detectBarcode.decode",
    "photoAccessHelper.PhotoViewPicker.select"
  ]
}
```

## 参考文档

- [API开发指南-识别本地图片](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/scan-detectbarcode)
- [API参考说明-detectBarcode](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/scan-imagedecode)
- [API参考说明-scanBarcode.ScanOptions](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/scan-scanbarcode-api)
- [PhotoPicker使用说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/photoaccesshelper-photoviewpicker)

## 完整示例代码

- [ArkTS完整示例(Promise方式)](assets/detect_barcode_promise.ets)
- [ArkTS完整示例(Callback方式)](assets/detect_barcode_callback.ets)

## 测试用例

### 正向测试用例
- [识别单码图片](tests/test_positive.py): 识别包含单个二维码的图片
- [识别多码图片](tests/test_positive.py): 识别包含多个条形码的图片
- [识别QR_CODE](tests/test_positive.py): 识别特定类型的二维码

### 边界测试用例
- [识别模糊图片](tests/test_boundary.py): 识别低清晰度的码图
- [识别小尺寸码图](tests/test_boundary.py): 识别尺寸较小的码图

### 异常测试用例
- [无效图片路径](tests/test_exception.py): 使用非file://协议路径
- [空图片路径](tests/test_exception.py): inputImage.uri为空字符串
- [无码图片](tests/test_exception.py): 识别不包含码图的图片