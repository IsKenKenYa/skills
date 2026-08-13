# 参考文档

本文档列出了Wear Engine Kit请求用户授权技能相关的参考文档链接。

## 开发指南文档

### 请求用户授权
- **文档名称**: request_user_authorization.md
- **原始路径**: D:\code\APIDevice\output\md_output\harmonyos-guides\系统\硬件\Wear Engine Kit（穿戴服务）\手机侧应用开发\应用开发\请求用户授权\request_user_authorization.md
- **在线链接**: https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/request_user_authorization
- **说明**: Wear Engine Kit请求用户授权的开发指南，包含申请用户穿戴设备权限和查询用户授权结果的详细流程

### 申请接入Wear Engine服务
- **文档名称**: wearengine_apply.md
- **原始路径**: D:\code\APIDevice\output\md_output\harmonyos-guides\系统\硬件\Wear Engine Kit（穿戴服务）\手机侧应用开发\接入准备\申请接入Wear Engine服务\wearengine_apply.md
- **在线链接**: https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/wearengine_apply
- **说明**: 如何申请接入Wear Engine服务的指南，包括权限审批流程

### 配置Client ID
- **文档名称**: configuration_client_id.md
- **原始路径**: D:\code\APIDevice\output\md_output\harmonyos-guides\系统\硬件\Wear Engine Kit（穿戴服务）\手机侧应用开发\接入准备\配置Client ID\configuration_client_id.md
- **在线链接**: https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/configuration_client_id
- **说明**: 如何在应用中配置Client ID以使用Wear Engine服务

## API参考文档

### Wear Engine API参考
- **文档名称**: wearengine_api.md
- **原始路径**: D:\code\APIDevice\output\md_output\harmonyos-references\系统\硬件\Wear Engine Kit（穿戴服务）\ArkTS API\wearengine_api.md
- **在线链接**: https://developer.huawei.com/consumer/cn/doc/harmonyos-references/wearengine_api
- **说明**: Wear Engine Kit的完整API参考文档，包含所有接口定义、参数说明、返回值、错误码等

### Wear Engine错误码参考
- **文档名称**: wearengine_api_error_code.md
- **原始路径**: D:\code\APIDevice\output\md_output\harmonyos-references\系统\硬件\Wear Engine Kit（穿戴服务）\wearengine_api_error_code.md
- **在线链接**: https://developer.huawei.com/consumer/cn/doc/harmonyos-references/wearengine_api_error_code
- **说明**: Wear Engine API的错误码详细说明，包含错误原因和处理步骤

## 关键API接口

### wearEngine.getAuthClient
- **接口名称**: getAuthClient(context: common.Context): AuthClient
- **功能**: 用于获取权限管理的客户端
- **参数**: context - Context上下文（UIAbilityContext）
- **返回**: AuthClient - 权限管理客户端对象
- **错误码**: 401、801、1008509999
- **起始版本**: 5.0.0(12)

### AuthClient.requestAuthorization
- **接口名称**: requestAuthorization(request: AuthorizationRequest): Promise<AuthorizationResponse>
- **功能**: 向用户申请需要授权的权限
- **参数**: request - AuthorizationRequest权限请求类
- **返回**: Promise<AuthorizationResponse> - 权限响应类
- **错误码**: 401、1008500001、1008500004、1008500006、1008500007、1008500008、1008500009、1008509999
- **起始版本**: 5.0.0(12)

### AuthClient.getAuthorization
- **接口名称**: getAuthorization(): Promise<AuthorizationResponse>
- **功能**: 获取用户已授权的权限
- **返回**: Promise<AuthorizationResponse> - 权限响应类
- **错误码**: 1008500001、1008500004、1008500006、1008500007、1008500008、1008500009、1008509999
- **起始版本**: 5.0.0(12)

## 权限类型说明

### Permission枚举
| 名称 | 值 | 说明 |
|------|---|------|
| USER_STATUS | 2 | 获取用户状态权限，如穿戴设备的佩戴状态 |
| MOTION_SENSOR | 3 | 获取对端设备运动传感器数据权限，如加速度传感器数据 |
| HEALTH_SENSOR | 4 | 获取对端设备人体传感器数据权限，如心率传感器数据 |
| DEVICE_IDENTIFIER | 6 | 获取已连接穿戴设备的序列号 |

## 相关接口和类

### AuthorizationRequest
- **说明**: 权限请求类，继承自AuthorizationBase
- **字段**: permissions - Permission[]权限枚举类型的数组

### AuthorizationResponse
- **说明**: 权限响应类，继承自AuthorizationBase
- **字段**: permissions - Permission[]权限枚举类型的数组

### AuthorizationBase
- **说明**: 权限控制模块输入输出的基类
- **字段**: permissions - Permission[]权限枚举类型的数组

## 系统要求和限制

### 设备类型
- 支持设备: Phone、Tablet
- 不支持设备: Watch、TV、其他设备（返回801错误码）

### 模型约束
- 仅支持: Stage模型
- 不支持: FA模型

### API版本
- 起始版本: 5.0.0(12)
- 系统能力: SystemCapability.Health.WearEngine

### 前置条件
1. 用户必须登录华为账号（中国境内注册）
2. 用户必须同意运动健康隐私授权
3. 应用必须在开发者联盟申请Wear Engine服务
4. 申请的权限必须在服务申请中审批通过

## 其他参考资源

### HarmonyOS官方文档
- HarmonyOS开发者文档: https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/
- HarmonyOS API参考: https://developer.huawei.com/consumer/cn/doc/harmonyos-references/

### 相关Kit文档
- Ability Kit文档: https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/application-dev-guide
- Basic Services Kit文档: https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/basic-services-kit

### 技术支持
- 在线提单: https://developer.huawei.com/consumer/cn/support/feedback/
- 开发者论坛: https://developer.huawei.com/consumer/cn/forum/

## 文档版本信息

- **文档版本**: v1.0
- **更新时间**: 2026-07-03
- **API版本**: 5.0.0(12)
- **文档状态**: 正式发布