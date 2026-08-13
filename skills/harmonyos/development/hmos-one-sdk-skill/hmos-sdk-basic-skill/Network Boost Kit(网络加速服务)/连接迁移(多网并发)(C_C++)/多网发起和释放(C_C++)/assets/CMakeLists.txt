cmake_minimum_required(VERSION 3.4.1)
project(NetworkBoostMultiPathExample)

# 设置HarmonyOS SDK Native路径
# 请根据实际SDK路径设置HMOS_SDK_NATIVE环境变量
if(NOT DEFINED HMOS_SDK_NATIVE)
    message(FATAL_ERROR "HMOS_SDK_NATIVE环境变量未设置，请设置HarmonyOS SDK Native路径")
endif()

# 添加头文件路径
target_include_directories(entry PUBLIC 
    ${HMOS_SDK_NATIVE}/sysroot/usr/include
)

# 添加动态库路径
target_link_directories(entry PUBLIC 
    ${HMOS_SDK_NATIVE}/sysroot/usr/lib/aarch64-linux-ohos
)

# 链接Network Boost Kit动态库
target_link_libraries(entry PUBLIC 
    libnetwork_boost.so
)

# 编译示例代码
add_executable(multipath_example 
    example_multipath_request_release.cpp
)

# 设置输出目录
set_target_properties(multipath_example PROPERTIES 
    OUTPUT_DIR "build/bin"
)