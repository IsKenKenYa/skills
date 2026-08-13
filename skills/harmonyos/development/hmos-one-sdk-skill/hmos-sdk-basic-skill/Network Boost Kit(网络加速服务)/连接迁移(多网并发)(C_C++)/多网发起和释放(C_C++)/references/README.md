# 参考文档列表

本文档列出了多网发起和释放技能相关的所有参考文档链接。

## API开发指南

- [多网发起和释放(C/C++)](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/networkboost-netmultipath-request-release-c)
  - 场景介绍、开发准备、接口说明、开发步骤等完整开发指南

- [开发准备](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/networkboost-preparations)
  - Network Boost Kit的开发准备、权限配置、依赖说明等

## API参考说明

- [NetworkBoost模块](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/network-boost-c-overview)
  - Network Boost Kit C API模块概述，包含所有接口、结构体、枚举、宏定义的汇总

- [network_boost_handover.h](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/network-boost-c-files-handover)
  - 连接迁移模块头文件，声明用于连接迁移和多网并发的API

### 结构体定义

- [NetworkBoost_MultiPathRequestResult](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/network-boost-c-struct-multipath-req-result)
  - 多网请求结果结构体

- [NetworkBoost_MultiPathStateChange](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/network-boost-c-struct-multipath-statechange)
  - 多网状态信息结构体

- [NetworkBoost_MultiPathQuota](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/network-boost-c-struct-multipath_quota)
  - 应用配额使用信息结构体

- [NetworkBoost_NetHandle](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/network-boost-c-struct-net_handle)
  - NetHandle信息结构体

### 枚举定义

- NetworkBoost_MultiPathErrorResult - 多网建立结果枚举
- NetworkBoost_MultiPathState - 多网状态枚举
- NetworkBoost_MultiPathChangeCause - 多网变化原因枚举
- NetworkBoost_PathState - 多网链路状态枚举
- NetworkBoost_PathType - 数据路径类型枚举

以上枚举详见 [NetworkBoost模块](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/network-boost-c-overview)

## 相关模块

- [Network Kit（网络服务）](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/network-kit-overview)
  - 网络服务基础能力，提供HTTP、Socket等网络传输接口

- [连接迁移(多网并发)](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/networkboost-handover-c)
  - Network Boost Kit连接迁移功能，包括多网迁移和并发能力

## 文档版本

- API起始版本：6.0.2(22)
- 文档更新时间：2026年7月3日
- HarmonyOS版本：HarmonyOS Next