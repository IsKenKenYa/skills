# NetworkBoost_NetworkQosArray
---
# NetworkBoost_NetworkQosArray
#### 概述
网络质量变化的详细信息。
**起始版本：** 5.1.0(18)
**相关模块：**  [NetworkBoost](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/模块/network-boost-c-overview.md)
#### 汇总
#### 成员变量
| 名称 | 描述 |
| --- | --- |
| uint32_t[pathNum](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/头文件和结构体/结构体/network-boost-c-struct-network_qos_array.md) | 网络质量信息中的路径数量，取值范围 [1, 4]。 |
| [NetworkBoost_NetworkQos](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/头文件和结构体/结构体/network-boost-c-struct-network_qos.md)[networkQos](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/头文件和结构体/结构体/network-boost-c-struct-network_qos_array.md)[[NETBOOST_MAX_PATH_NUM](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/模块/network-boost-c-overview.md)] | 多条路径的网络质量信息，每一项为一条路径的网络质量信息，取值范围 [0, pathNum-1]。 |
#### 结构体成员变量说明
#### networkQos
```
NetworkBoost_NetworkQos NetworkBoost_NetworkQosArray::networkQos[NETBOOST_MAX_PATH_NUM]
```
**描述**
多条路径的网络质量信息，每一项为一条路径的网络质量信息，取值范围 [0, pathNum-1]。
#### pathNum
```
uint32_t NetworkBoost_NetworkQosArray::pathNum
```
**描述**
网络质量信息中的路径数量，取值范围 [1, 4]。