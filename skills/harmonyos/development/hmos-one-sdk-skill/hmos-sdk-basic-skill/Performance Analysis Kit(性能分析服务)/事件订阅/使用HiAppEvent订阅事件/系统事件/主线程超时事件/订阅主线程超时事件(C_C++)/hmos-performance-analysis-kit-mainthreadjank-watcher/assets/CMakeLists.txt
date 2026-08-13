cmake_minimum_required(VERSION 3.4.1)
project(entry)

set(NAPI_LIB_NAME entry)

add_library(${NAPI_LIB_NAME} SHARED
    napi_init.cpp
    jsoncpp.cpp
)

include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}/json
)

target_link_libraries(${NAPI_LIB_NAME} PUBLIC
    libace_napi.z.so
    libhilog_ndk.z.so
    libhiappevent_ndk.z.so
)