/**
 * @file test_null_pointer.cpp
 * @brief 测试用例：空指针参数测试
 * @details 验证空指针参数的错误处理
 */

#include "NetworkBoostKit/network_boost_handover.h"
#include <cstdio>
#include <cassert>

/**
 * @brief 测试回调函数为空指针
 */
void TestNullCallback() {
    printf("=== 测试：回调函数为空指针 ===\n");
    
    uint32_t callbackId = 0;
    
    // 尝试使用空指针回调函数注册
    int32_t ret = HMS_NetworkBoost_RegisterMultiPathRecommendationCallback(
        nullptr,  // 空指针
        &callbackId
    );
    
    printf("返回值: %d\n", ret);
    
    // 验证返回值（应为错误码1013600041）
    assert(ret == 1013600041);
    
    printf("✓ 测试通过：正确处理空回调函数指针\n\n");
}

/**
 * @brief 测试callbackId指针为空指针
 */
void TestNullCallbackId() {
    printf("=== 测试：callbackId指针为空指针 ===\n");
    
    // 定义临时回调函数
    void tempCallback(NetworkBoost_MultiPathRecommendation* recommendation) {
        printf("Temp callback\n");
    }
    
    // 尝试使用空指针callbackId注册
    int32_t ret = HMS_NetworkBoost_RegisterMultiPathRecommendationCallback(
        tempCallback,
        nullptr  // 空指针
    );
    
    printf("返回值: %d\n", ret);
    
    // 验证返回值（应为错误码1013600041）
    assert(ret == 1013600041);
    
    printf("✓ 测试通过：正确处理空callbackId指针\n\n");
}

/**
 * @brief 测试两个指针都为空
 */
void TestBothNull() {
    printf("=== 测试：两个指针都为空 ===\n");
    
    int32_t ret = HMS_NetworkBoost_RegisterMultiPathRecommendationCallback(
        nullptr,
        nullptr
    );
    
    printf("返回值: %d\n", ret);
    
    // 验证返回值（应为错误码1013600041）
    assert(ret == 1013600041);
    
    printf("✓ 测试通过：正确处理双空指针\n\n");
}

int main() {
    printf("========================================\n");
    printf("测试用例：空指针参数测试\n");
    printf("========================================\n\n");
    
    TestNullCallback();
    TestNullCallbackId();
    TestBothNull();
    
    printf("\n========================================\n");
    printf("所有测试通过\n");
    printf("========================================\n");
    
    return 0;
}