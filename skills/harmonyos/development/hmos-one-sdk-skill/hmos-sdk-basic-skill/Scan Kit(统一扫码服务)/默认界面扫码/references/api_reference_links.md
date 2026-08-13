# 默认界面扫码技能参考文档索引

本文档列出技能相关的所有参考文档链接和本地文档路径。

## 在线参考文档

### 开发指南文档
- [默认界面扫码开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/scan-scanbarcode) - HarmonyOS官方开发指南，包含完整的开发流程和示例代码

### API参考文档
- [scanBarcode API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/scan-scanbarcode-api) - 默认界面扫码模块API详细说明
- [scanCore API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/scan-scancore) - 扫码公共信息模块API说明
- [扫码错误码说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/scan-error-code) - 扫码API错误码详细说明

### 相关开发指南
- [接入"扫码直达"服务](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/scan-directservice) - 推荐同时接入扫码直达服务
- [开发应用沉浸式效果](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-develop-apply-immersive-effects) - 设置扫码页面为全屏或沉浸式
- [使用模拟器运行应用](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ide-run-emulator) - 模拟器开发指导

## 本地文档路径

### API开发指南
- **路径**: `D:\z00810349\APIDevice\output\md_output\harmonyos-guides\媒体\Scan Kit（统一扫码服务）\默认界面扫码\scan-scanbarcode.md`
- **用途**: 本技能的主要开发指南文档，包含场景介绍、约束限制、业务流程、接口说明、开发步骤等内容

### API参考文档
- **scanBarcode API**: `D:\z00810349\APIDevice\output\md_output\harmonyos-references\媒体\Scan Kit（统一扫码服务）\ArkTS API\scan-scanbarcode-api.md`
  - 包含：ScanResult, ScanCodeRect, Point, ScanOptions接口定义
  - 包含：startScanForResult API详细说明（Promise和Callback方式）

- **scanCore API**: `D:\z00810349\APIDevice\output\md_output\harmonyos-references\媒体\Scan Kit（统一扫码服务）\ArkTS API\scan-scancore.md`
  - 包含：ScanType枚举定义（QR_CODE, ALL等码类型）
  - 包含：ScanErrorCode枚举定义（错误码类型）
  - 包含：ScanSource枚举定义（扫码来源）

- **错误码文档**: `D:\z00810349\APIDevice\output\md_output\harmonyos-references\媒体\Scan Kit（统一扫码服务）\ArkTS API\scan-error-code.md`
  - 包含：所有扫码相关错误码的详细说明

## 官方示例工程

- [Scan Kit示例工程](https://gitcode.com/HarmonyOS_Samples/scankit-samplecode-clientdemo-arkts) - HarmonyOS官方提供的完整示例代码工程

## API版本信息

| API | 起始版本 | 废弃版本 | 元服务支持 | 备注 |
|-----|---------|---------|----------|------|
| scanBarcode.startScanForResult | 4.1.0(11) | - | 4.1.0(11)+ | 推荐使用 |
| scanBarcode.startScan | 4.0.0(10) | 4.1.0(11) | 4.1.0(11)+ | 已废弃，不建议使用 |
| scanCore.ScanType | 4.0.0(10) | - | 4.1.0(11)+ | 码类型枚举 |
| scanCore.ScanErrorCode | 4.1.0(11) | - | 4.1.0(11)+ | 错误码枚举 |
| scanCore.ScanSource | 6.0.2(22) | - | 6.0.2(22)+ | 扫码来源枚举 |
| scanCore.isDefaultScanSupported | 26.0.0 | - | - | 设备支持检查（仅Stage模型） |

## 设备和版本兼容性

### 设备要求
- 带相机的设备（Phone, Tablet）
- Wearable设备：需带后置相机（API 6.1.0(23)及以上）
- 模拟器：支持默认界面扫码开发（API 6.0.0(20)及以上）

### 版本特性
- **4.0.0(10)**: 基础默认界面扫码能力
- **4.1.0(11)**: 新增startScanForResult接口，支持元服务
- **5.0.0(12)**: 新增cornerPoints参数
- **6.0.0(20)**: 支持悬浮屏、分屏场景，模拟器支持
- **6.0.2(22)**: 新增ScanSource参数，支持元服务
- **6.1.0(23)**: Wearable支持，标题动态显示
- **26.0.0**: 新增isDefaultScanSupported设备检查接口