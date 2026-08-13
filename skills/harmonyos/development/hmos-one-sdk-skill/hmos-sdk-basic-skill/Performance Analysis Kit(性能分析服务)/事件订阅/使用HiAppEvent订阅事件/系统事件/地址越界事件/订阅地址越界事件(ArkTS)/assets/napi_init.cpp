#include "napi/native_api.h"

/**
 * 测试函数:构造地址越界错误
 * 该函数故意构造一个数组越界写入的场景
 * 用于触发Address Sanitizer检测并生成ADDRESS_SANITIZER事件
 */
static napi_value Test(napi_env env, napi_callback_info info)
{
    // 定义一个长度为10的数组
    int a[10];
    
    // 故意进行数组越界写入(访问索引10,超出数组范围)
    // 这会触发Address Sanitizer的检测机制
    a[10] = 1;
    
    return {};
}

/**
 * 模块初始化函数
 * 注册NAPI接口到exports对象
 */
EXTERN_C_START
static napi_value Init(napi_env env, napi_value exports)
{
    // 定义接口属性
    napi_property_descriptor desc[] = {
        { "test", nullptr, Test, nullptr, nullptr, nullptr, napi_default, nullptr }
    };
    
    // 将接口属性添加到exports对象
    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    
    return exports;
}
EXTERN_C_END

/**
 * NAPI模块定义
 * 定义模块名称为"entry"
 */
static napi_module demoModule = {
    .nm_version = 1,
    .nm_flags = 0,
    .nm_filename = nullptr,
    .nm_register_func = Init,
    .nm_modname = "entry",
    .nm_priv = ((void*)0),
    .reserved = { 0 }
};

/**
 * 模块注册函数
 * 在模块加载时自动调用,注册NAPI模块
 */
extern "C" __attribute__((constructor)) void RegisterEntryModule(void)
{
    napi_module_register(&demoModule);
}