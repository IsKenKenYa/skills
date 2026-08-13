# NetworkBoost_NetworkQos
---
# NetworkBoost_NetworkQos
#### 概述
网络质量回调信息。
**起始版本：** 5.1.0(18)
**相关模块：**  [NetworkBoost](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/模块/network-boost-c-overview.md)
#### 汇总
#### 成员变量
| 名称 | 描述 |
| --- | --- |
| [NetworkBoost_PathType](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/模块/network-boost-c-overview.md)[pathType](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/头文件和结构体/结构体/network-boost-c-struct-network_qos.md) | 相应的数据路径上的网络质量信息。 |
| uint64_t[linkUpBandwidth](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/头文件和结构体/结构体/network-boost-c-struct-network_qos.md) | 上行带宽信息，单位为bps。 |
| uint64_t[linkDownBandwidth](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/头文件和结构体/结构体/network-boost-c-struct-network_qos.md) | 下行带宽信息，单位为bps。 |
| uint64_t[linkUpRate](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/头文件和结构体/结构体/network-boost-c-struct-network_qos.md) | 上行速率，单位为bps。 |
| uint64_t[linkDownRate](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/头文件和结构体/结构体/network-boost-c-struct-network_qos.md) | 下行速率，单位为bps。 |
| uint32_t[rttMs](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/头文件和结构体/结构体/network-boost-c-struct-network_qos.md) | RTT时延，单位为ms，取值范围是任意正数。 |
| uint32_t[linkUpBufferDelayMs](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/头文件和结构体/结构体/network-boost-c-struct-network_qos.md) | 上行发送空口缓冲时延，单位为ms，取值范围是任意正数。 |
| uint32_t[linkUpBufferCongestionPercent](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/头文件和结构体/结构体/network-boost-c-struct-network_qos.md) | 上行发送空口缓冲时延占总缓冲时间的比例，取值范围[0, 100]。 |
#### 结构体成员变量说明
#### linkDownBandwidth
```
uint64_t NetworkBoost_NetworkQos::linkDownBandwidth
```
**描述**
下行带宽信息，单位为bps。
#### linkDownRate
```
uint64_t NetworkBoost_NetworkQos::linkDownRate
```
**描述**
下行速率，单位为bps。
#### linkUpBandwidth
```
uint64_t NetworkBoost_NetworkQos::linkUpBandwidth
```
**描述**
上行带宽信息，单位为bps。
#### linkUpBufferCongestionPercent
```
uint32_t NetworkBoost_NetworkQos::linkUpBufferCongestionPercent
```
**描述**
上行发送空口缓冲时延占总缓冲时间的比例，取值范围[0, 100]。
#### linkUpBufferDelayMs
```
uint32_t NetworkBoost_NetworkQos::linkUpBufferDelayMs
```
**描述**
上行发送空口缓冲时延（单位ms），取值范围是任意正数。
#### linkUpRate
```
uint64_t NetworkBoost_NetworkQos::linkUpRate
```
**描述**
上行速率，单位为bps。
#### pathType
```
NetworkBoost_PathType NetworkBoost_NetworkQos::pathType
```
**描述**
相应的数据路径上的网络质量信息。
#### rttMs
```
uint32_t NetworkBoost_NetworkQos::rttMs
```
**描述**
RTT时延（单位ms），取值范围是任意正数。