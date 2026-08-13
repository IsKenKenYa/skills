# jsoncpp集成指南

## 下载jsoncpp源码

从GitHub下载jsoncpp源码压缩包：
https://github.com/open-source-parsers/jsoncpp

## 生成Amalgamated源文件

按照README中的Amalgamated source操作步骤，生成以下三个文件：
- jsoncpp.cpp
- json.h
- json-forwards.h

## 目录结构

将生成的文件放在Native C++工程的cpp目录下：

```
entry/
  src/
    main/
      cpp/
        - json/
            - json.h
            - json-forwards.h
        - CMakeLists.txt
        - napi_init.cpp
        - jsoncpp.cpp
```

## CMake配置

在CMakeLists.txt中添加jsoncpp源文件：

```cmake
add_library(entry SHARED napi_init.cpp jsoncpp.cpp)
```

## 头文件引用

在napi_init.cpp中引用json头文件：

```cpp
#include "json/json.h"
```

## 使用示例

```cpp
Json::Value params;
Json::Reader reader(Json::Features::strictMode());

if (reader.parse(jsonString, params)) {
    int64_t time = params["time"].asInt64();
    std::string name = params["bundle_name"].asString();
}
```