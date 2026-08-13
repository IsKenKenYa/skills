# 参考文档索引

本技能相关的 HarmonyOS 官方文档链接。

## API 开发指南

- [应用声明接入系统关怀模式](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/eldercare-appconfig)
  - 原始文件：eldercare-appconfig.md
  - 文档位置：harmonyos-guides
  
- [应用内关怀模式与系统设置同步](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/eldercare-senior-mode-description)
  - 原始文件：eldercare-senior-mode-description.md
  - 文档位置：harmonyos-guides
  
- [获取系统关怀模式状态](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/eldercare-description)
  - 原始文件：eldercare-description.md
  - 文档位置：harmonyos-guides

## API 参考文档

- [@ohos.accessibility (辅助功能)](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-accessibility)
  - 原始文件：js-apis-accessibility.md
  - 文档位置：harmonyos-references

## 相关 API 接口

### 应用内关怀模式与系统设置同步相关 API

| 接口名 | 描述 | API版本 |
|-------|------|---------|
| getSeniorModeStateForSelf(): Promise<boolean> | 获取"设置"中应用管理页面关怀模式的开关状态 | 26.0.0+ |
| setSeniorModeStateForSelf(state: boolean): Promise<void> | 设置设备"设置"中应用管理页面内关怀模式开关状态 | 26.0.0+ |
| onSeniorModeStateChangeForSelf(callback: Callback<boolean>): void | 注册设备"设置"中应用管理页面内关怀模式开关状态监听 | 26.0.0+ |
| offSeniorModeStateChangeForSelf(callback?: Callback<boolean>): void | 取消注册设备"设置"中应用管理页面内关怀模式开关状态监听 | 26.0.0+ |

### 获取系统关怀模式状态相关 API

| 接口名 | 描述 | API版本 |
|-------|------|---------|
| isSeniorModeEnabled(): Promise<boolean> | 异步接口，获取关怀模式的开关状态 | 26.0.0+ |
| onSeniorModeStateChange(callback: Callback<boolean>): void | 注册系统关怀模式状态变化事件的监听回调 | 26.0.0+ |
| offSeniorModeStateChange(callback?: Callback<boolean>): void | 取消注册系统关怀模式状态变化事件的监听回调 | 26.0.0+ |

## 文档转换说明

根据用户要求，原始 Markdown 文件链接已转换为 HarmonyOS 官方文档链接：
- harmonyos-guides 目录下的文档转换为：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/
- harmonyos-references 目录下的文档转换为：https://developer.huawei.com/consumer/cn/doc/harmonyos-references/
- 所有链接已去除 .md 后缀