# Network Boost Kit C API 参考

## 概述

提供网络质量与网络连接迁移相关接口。
- 网络质量模块提供网络质量实时评估、网络场景识别以及弱信号预测等能力
- 连接迁移模块提供网络连接迁移能力
- 多网并发是系统提供接口可以建立多个网络通路

**起始版本**: 5.1.0(18)

## 多网建议相关接口

### HMS_NetworkBoost_RegisterMultiPathRecommendationCallback()

```cpp
int32_t HMS_NetworkBoost_RegisterMultiPathRecommendationCallback(
    HMS_NetworkBoost_OnMultiPathRecommendation callback, 
    uint32_t* callbackId
)
```

**描述**: 注册系统多网建议变化事件

**起始版本**: 6.0.2(22)

**参数**:
| 名称 | 描述 |
| --- | --- |
| callback | 系统多网建议变化回调函数 |
| callbackId | 回调的ID,注册多网状态时由系统分配 |

**返回值**:
- 0 - 成功
- 201 - 权限不足
- 1013600001 - 内部处理异常
- 1013600002 - 系统处理异常
- 1013600041 - 传入参数有误

**权限**: ohos.permission.LINKTURBO

### HMS_NetworkBoost_UnregisterMultiPathRecommendationCallback()

```cpp
int32_t HMS_NetworkBoost_UnregisterMultiPathRecommendationCallback(uint32_t callbackId)
```

**描述**: 去注册系统多网建议变化事件

**起始版本**: 6.0.2(22)

**参数**:
| 名称 | 描述 |
| --- | --- |
| callbackId | 回调的ID,注册多网状态时由系统分配 |

**返回值**:
- 0 - 成功
- 201 - 权限不足
- 1013600001 - 内部处理异常
- 1013600002 - 系统处理异常

**权限**: ohos.permission.LINKTURBO

### HMS_NetworkBoost_OnMultiPathRecommendation

```cpp
typedef void (*HMS_NetworkBoost_OnMultiPathRecommendation)(
    NetworkBoost_MultiPathRecommendation* recommendation
)
```

**描述**: 系统多网建议变化回调函数原型

**起始版本**: 6.0.2(22)

**参数**:
| 名称 | 描述 |
| --- | --- |
| recommendation | 多网推荐信息 |

## 相关数据结构

### NetworkBoost_MultiPathRecommendation

**描述**: 多网推荐信息,用于注册多网推荐变化事件回调后,系统多网推荐状态发生变化的事件通知

**起始版本**: 6.0.2(22)

**成员变量**:
| 名称 | 描述 |
| --- | --- |
| NetworkBoost_MultiPathAction action | 多网推荐动作 |

### NetworkBoost_MultiPathAction

**描述**: 多网推荐动作的枚举

**起始版本**: 6.0.2(22)

**枚举值**:
| 枚举值 | 描述 |
| --- | --- |
| NB_MULTIPATH_ACTION_REQUEST | 建议发起多网请求 |
| NB_MULTIPATH_ACTION_RELEASE | 建议释放多网请求 |

## 参考文档

- [NetworkBoost模块概述](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/network-boost-c-overview)
- [NetworkBoost_MultiPathRecommendation结构体](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/network-boost-c-struct-multipath_reco)