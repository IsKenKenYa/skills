# 参考文档链接转换说明

原始文档中的链接需要进行以下转换:

## 转换规则

1. **harmonyos-guides目录链接**:
   - 原链接: `D:/code/APIDevice/output/md_output/harmonyos-guides/{path}/{filename}.md`
   - 转换后: `https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/{filename}`
   - 示例: `fault-log-extension-app-events-arkts` -> `https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/fault-log-extension-app-events-arkts`

2. **harmonyos-references目录链接**:
   - 原链接: `D:/code/APIDevice/output/md_output/harmonyos-references/{path}/{filename}.md`
   - 转换后: `https://developer.huawei.com/consumer/cn/doc/harmonyos-references/{filename}`
   - 示例: `capi-hiappevent-h` -> `https://developer.huawei.com/consumer/cn/doc/harmonyos-references/capi-hiappevent-h`

3. **去掉.md后缀**: 所有链接中的`.md`后缀需要去掉

4. **保留md文件名**: 在SKILL.md中引用时,只保留md文件名部分(不含路径)

## 需要转换的文档列表

### 开发指南文档(harmonyos-guides)

- hiappevent-watcher-crash-events-ndk.md (原始开发指南)
  - 转换为: https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/hiappevent-watcher-crash-events-ndk

- fault-log-extension-app-events-arkts.md
  - 转换为: https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/fault-log-extension-app-events-arkts

- cppcrash-guidelines.md
  - 转换为: https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/cppcrash-guidelines

### API参考文档(harmonyos-references)

- capi-hiappevent-h.md
  - 转换为: https://developer.huawei.com/consumer/cn/doc/harmonyos-references/capi-hiappevent-h

- capi-hiappevent.md
  - 转换为: https://developer.huawei.com/consumer/cn/doc/harmonyos-references/capi-hiappevent

- js-apis-app-ability-errormanager.md
  - 转换为: https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-app-ability-errormanager

## 外部链接保留规则

以下外部链接保持不变:

- https://gitcode.com/openharmony/applications_app_samples/tree/master/code/DocsSample/PerformanceAnalysisKit/HiAppEvent/EventSub
- https://github.com/open-source-parsers/jsoncpp/archive/refs/tags/1.9.6.tar.gz
- 图片链接(如 https://contentcenter-vali-drcn.dbankcdn.cn/...)