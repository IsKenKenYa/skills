# FIDO免密身份认证相关文档链接

本文档汇总了FIDO免密身份认证技能相关的所有参考文档链接。

## 开发指南

- [FIDO免密身份认证开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/onlineauthentication-fido)
  - 详细介绍了FIDO免密身份认证的场景、基本概念、开发步骤和示例代码

- [个人数据处理说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/onlineauthentication-personal-data-processing-description)
  - 说明FIDO服务如何处理个人数据，包括指纹ID和面容ID等敏感信息

## API参考文档

- [FIDO API参考文档](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/onlineauthentication-fido-api)
  - 提供完整的FIDO接口定义、参数说明、返回值和错误码
  - 包含接口：discover、checkPolicy、processUAFOperation、notifyUAFResult
  - 包含数据结构：ChannelBinding、UAFMessage、DiscoveryData、Authenticator等

- [FIDO错误码参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/onlineauthentication-error-code-fido)
  - 详细说明所有FIDO相关错误码及其处理方法

## 相关接口文档

- [Context接口参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-inner-application-context)
  - ability的context接口定义

- [BundleManager接口参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-bundlemanager)
  - 用于获取应用签名信息，计算facet id

- [通用错误码](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/errorcode-universal)
  - HarmonyOS通用错误码说明

## FIDO协议规范

- [FIDO Alliance官方网站](https://fidoalliance.org/)
  - FIDO联盟官方技术规范和标准文档

- [UAF协议规范](https://fidoalliance.org/specifications/download/)
  - Universal Authentication Framework协议详细规范

## 本技能文档

- [FIDO免密身份认证技能主文档](../SKILL.md)
  - 本技能的完整定义、调用流程、示例代码和测试用例

- [完整示例代码目录](../assets/)
  - 包含开通、使用、关闭FIDO认证的完整ArkTS示例代码

- [测试用例目录](../tests/)
  - 包含正向、边界、异常测试用例