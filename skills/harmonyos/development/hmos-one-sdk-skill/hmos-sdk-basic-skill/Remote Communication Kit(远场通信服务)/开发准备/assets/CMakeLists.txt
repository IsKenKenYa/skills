cmake_minimum_required(VERSION 3.4.1)
project(entry)

# 设置头文件路径
target_include_directories(entry PUBLIC 
    ${HMOS_SDK_NATIVE}/sysroot/usr/include
)

# 设置动态库路径
target_link_directories(entry PUBLIC 
    ${HMOS_SDK_NATIVE}/sysroot/usr/lib/aarch64-linux-ohos
)

# 链接librcp_c.so及其他依赖的so
target_link_libraries(entry PUBLIC 
    librcp_c.so
)