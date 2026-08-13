# 技能生成的API文档

本技能已根据以下原始API开发指南文档生成:

## 原始开发指南文档

**文档标题**: 订阅崩溃事件(C/C++)

**原始路径**: D:\z00810349\APIDevice\output\md_output\harmonyos-guides\系统\调测调优\Performance Analysis Kit（性能分析服务）\事件订阅\使用HiAppEvent订阅事件\系统事件\崩溃事件\订阅崩溃事件（C_C++）\hiappevent-watcher-crash-events-ndk.md

**华为官方文档链接**: https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/hiappevent-watcher-crash-events-ndk

## 相关API参考文档

### HiAppEvent C API

- **头文件**: hiappevent.h
  - 官方链接: https://developer.huawei.com/consumer/cn/doc/harmonyos-references/capi-hiappevent-h
  - 本技能引用: [HiAppEvent C API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/capi-hiappevent-h)

- **模块说明**: HiAppEvent模块
  - 官方链接: https://developer.huawei.com/consumer/cn/doc/harmonyos-references/capi-hiappevent
  - 本技能引用: [HiAppEvent模块说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/capi-hiappevent)

### 错误管理API

- **errorManager.on**: 应用错误管理接口
  - 官方链接: https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-app-ability-errormanager
  - 本技能引用: [errorManager.on API](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-app-ability-errormanager)

## 相关开发指南文档

### 崩溃检测相关

- **使用FaultLogExtensionAbility订阅事件**: 延迟上报崩溃事件
  - 官方链接: https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/fault-log-extension-app-events-arkts
  - 本技能引用: [使用FaultLogExtensionAbility订阅事件](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/fault-log-extension-app-events-arkts)

- **Cpp Crash（进程崩溃）检测**: 崩溃信号处理
  - 官方链接: https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/cppcrash-guidelines
  - 本技能引用: [崩溃信号处理](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/cppcrash-guidelines)

## 示例工程

- **HiAppEvent示例工程EventSub**: 官方示例代码
  - 官方链接: https://gitcode.com/openharmony/applications_app_samples/tree/master/code/DocsSample/PerformanceAnalysisKit/HiAppEvent/EventSub

## 第三方依赖

- **jsoncpp开源库**: JSON解析库
  - 官方链接: https://github.com/open-source-parsers/jsoncpp/archive/refs/tags/1.9.6.tar.gz
  - 版本: 1.9.6
  - 用途: 解析崩溃事件的JSON参数

## 文档结构

本技能的文档结构已按照SDK编码规范组织:

- **SKILL.md**: 主技能定义文件
- **assets/**: 完整示例代码和配置文件
- **tests/**: 测试用例(正向、边界、异常)
- **references/**: 参考文档和链接转换说明

## 注意事项

1. 所有md链接已转换为华为官方文档链接
2. 保留了原始文档中的外部链接(如GitHub、GitCode等)
3. 去掉了所有链接中的.md后缀
4. 在SKILL.md中引用时只保留文件名部分