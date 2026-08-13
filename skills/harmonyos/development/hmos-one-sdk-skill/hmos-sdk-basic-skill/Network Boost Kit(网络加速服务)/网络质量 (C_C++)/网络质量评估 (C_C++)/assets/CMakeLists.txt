cmake_minimum_required(VERSION 3.4.1)
project(network_quality_demo)

set(CMAKE_CXX_STANDARD 11)

add_library(network_quality_demo SHARED
    network_quality_demo.cpp
)

target_include_directories(network_quality_demo PUBLIC
    ${OHOS_SDK_PATH}/native/sysroot/usr/include
)

target_link_libraries(network_quality_demo
    libnetwork_boost.so
    libhilog.so
)

set_target_properties(network_quality_demo PROPERTIES
    OUTPUT_NAME "network_quality_demo"
    INSTALL_RPATH "${OHOS_SDK_PATH}/native/sysroot/usr/lib"
)