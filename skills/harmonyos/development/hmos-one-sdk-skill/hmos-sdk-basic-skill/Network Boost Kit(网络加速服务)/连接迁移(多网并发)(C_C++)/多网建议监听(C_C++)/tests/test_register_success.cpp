/**
 * @file test_register_success.cpp
 * @brief 测试用例：注册回调成功测试
 * @details 验证正常注册流程，检查返回值和callbackId
 */

#include "NetworkBoostKit/network_boost_handover.h"
#include <cstdio>
#include <cassert>

// 测试回调函数
void testCallback(NetworkBoost_MultiPathRecommendation* recommendation) {
    printf("Test callback invoked\n");
}

/**
 * @brief 测试正常注册流程
 */
void TestRegisterSuccess() {
    printf("=== 测试：注册回调成功 ===\n");
    
    uint32_t callbackId = 0;
    
    // 执行注册
    int32_t ret = HMS_NetworkBoost_RegisterMultiPathRecommendationCallback(
        testCallback, 
        &callbackId
    );
    
    // 验证返回值
    printf("返回值: %d\n", ret);
    printf("callbackId: %u\n", callbackId);
    
    // 断言检查
    assert(ret == 0);  // 返回值应为0（成功）
    assert(callbackId > 0);  // callbackId应大于0
    
    printf("✓ 测试通过：注册成功\n\n");
    
    // 清理：取消注册
    if (callbackId > 0) {
        HMS_NetworkBoost_UnregisterMultiPathRecommendationCallback(callbackId);
        printf("清理完成：已取消注册\n");
    }
}

int main() {
    printf("========================================\n");
    printf("测试用例：注册回调成功测试\n");
    printf("========================================\n\n");
    
    TestRegisterSuccess();
    
    printf("\n========================================\n");
    printf("所有测试通过\n");
    printf("========================================\n");
    
    return 0;
}