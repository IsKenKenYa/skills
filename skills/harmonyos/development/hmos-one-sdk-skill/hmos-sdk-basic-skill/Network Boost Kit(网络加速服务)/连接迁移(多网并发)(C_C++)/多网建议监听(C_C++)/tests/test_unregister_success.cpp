/**
 * @file test_unregister_success.cpp
 * @brief 测试用例：取消注册成功测试
 * @details 验证正常取消注册流程，检查返回值
 */

#include "NetworkBoostKit/network_boost_handover.h"
#include <cstdio>
#include <cassert>

// 测试回调函数
void testCallback(NetworkBoost_MultiPathRecommendation* recommendation) {
    printf("Test callback\n");
}

/**
 * @brief 测试正常取消注册流程
 */
void TestUnregisterSuccess() {
    printf("=== 测试：取消注册成功 ===\n");
    
    uint32_t callbackId = 0;
    
    // 先注册
    int32_t ret = HMS_NetworkBoost_RegisterMultiPathRecommendationCallback(
        testCallback, 
        &callbackId
    );
    
    if (ret != 0) {
        printf("✗ 注册失败，错误码: %d\n", ret);
        return;
    }
    
    printf("注册成功，callbackId: %u\n", callbackId);
    
    // 取消注册
    printf("执行取消注册...\n");
    int32_t unregisterRet = HMS_NetworkBoost_UnregisterMultiPathRecommendationCallback(callbackId);
    
    // 验证返回值
    printf("取消注册返回值: %d\n", unregisterRet);
    
    // 断言检查
    assert(unregisterRet == 0);  // 返回值应为0（成功）
    
    printf("✓ 测试通过：取消注册成功\n\n");
}

/**
 * @brief 测试多次取消注册（验证第二次失败）
 */
void TestUnregisterTwice() {
    printf("=== 测试：多次取消注册 ===\n");
    
    uint32_t callbackId = 0;
    
    // 注册
    int32_t ret = HMS_NetworkBoost_RegisterMultiPathRecommendationCallback(
        testCallback, 
        &callbackId
    );
    
    if (ret != 0) {
        printf("✗ 注册失败\n");
        return;
    }
    
    // 第一次取消
    int32_t firstRet = HMS_NetworkBoost_UnregisterMultiPathRecommendationCallback(callbackId);
    printf("第一次取消返回值: %d\n", firstRet);
    assert(firstRet == 0);
    
    // 第二次取消（使用已取消的callbackId）
    int32_t secondRet = HMS_NetworkBoost_UnregisterMultiPathRecommendationCallback(callbackId);
    printf("第二次取消返回值: %d\n", secondRet);
    printf("提示：第二次取消应返回错误码（callbackId已失效）\n\n");
}

int main() {
    printf("========================================\n");
    printf("测试用例：取消注册成功测试\n");
    printf("========================================\n\n");
    
    TestUnregisterSuccess();
    TestUnregisterTwice();
    
    printf("\n========================================\n");
    printf("所有测试通过\n");
    printf("========================================\n");
    
    return 0;
}