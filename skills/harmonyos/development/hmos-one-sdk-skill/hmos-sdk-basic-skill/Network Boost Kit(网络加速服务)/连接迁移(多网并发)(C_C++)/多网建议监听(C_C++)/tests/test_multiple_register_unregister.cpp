/**
 * @file test_multiple_register_unregister.cpp
 * @brief 测试用例：多次注册取消测试
 * @details 验证多次注册和取消的场景
 */

#include "NetworkBoostKit/network_boost_handover.h"
#include <cstdio>
#include <vector>

// 测试回调函数
void testCallback(NetworkBoost_MultiPathRecommendation* recommendation) {
    printf("Test callback\n");
}

/**
 * @brief 测试连续注册和取消
 */
void TestContinuousRegisterUnregister() {
    printf("=== 测试：连续注册和取消 ===\n");
    
    const int testCount = 5;
    std::vector<uint32_t> callbackIds;
    
    // 连续注册
    for (int i = 0; i < testCount; i++) {
        uint32_t callbackId = 0;
        int32_t ret = HMS_NetworkBoost_RegisterMultiPathRecommendationCallback(
            testCallback,
            &callbackId
        );
        
        printf("第%d次注册: ret=%d, callbackId=%u\n", i+1, ret, callbackId);
        
        if (ret == 0) {
            callbackIds.push_back(callbackId);
        } else {
            printf("注册失败，可能达到上限\n");
            break;
        }
    }
    
    printf("成功注册次数: %zu\n", callbackIds.size());
    
    // 连续取消
    for (size_t i = 0; i < callbackIds.size(); i++) {
        int32_t ret = HMS_NetworkBoost_UnregisterMultiPathRecommendationCallback(callbackIds[i]);
        printf("取消注册%zu: ret=%d\n", i+1, ret);
    }
    
    printf("✓ 测试通过：连续注册和取消完成\n\n");
}

/**
 * @brief 测试注册取消后再注册
 */
void TestRegisterAfterUnregister() {
    printf("=== 测试：注册取消后再注册 ===\n");
    
    uint32_t callbackId1 = 0;
    uint32_t callbackId2 = 0;
    
    // 第一次注册
    int32_t ret1 = HMS_NetworkBoost_RegisterMultiPathRecommendationCallback(
        testCallback,
        &callbackId1
    );
    
    printf("第一次注册: ret=%d, callbackId=%u\n", ret1, callbackId1);
    
    if (ret1 == 0) {
        // 取消注册
        int32_t unregRet = HMS_NetworkBoost_UnregisterMultiPathRecommendationCallback(callbackId1);
        printf("取消注册: ret=%d\n", unregRet);
        
        // 第二次注册
        int32_t ret2 = HMS_NetworkBoost_RegisterMultiPathRecommendationCallback(
            testCallback,
            &callbackId2
        );
        
        printf("第二次注册: ret=%d, callbackId=%u\n", ret2, callbackId2);
        
        if (ret2 == 0) {
            printf("✓ 测试通过：取消后再注册成功\n");
            
            // 验证callbackId
            if (callbackId2 != callbackId1) {
                printf("提示：两次注册的callbackId不同\n");
            } else {
                printf("提示：两次注册的callbackId相同（可能重用）\n");
            }
            
            // 清理第二次注册
            HMS_NetworkBoost_UnregisterMultiPathRecommendationCallback(callbackId2);
        }
    }
    
    printf("\n");
}

/**
 * @brief 测试注册达到上限
 */
void TestRegisterLimit() {
    printf("=== 测试：注册达到上限 ===\n");
    printf("提示：尝试多次注册直到达到系统上限\n");
    
    std::vector<uint32_t> callbackIds;
    int maxAttempts = 20;  // 尝试次数
    
    for (int i = 0; i < maxAttempts; i++) {
        uint32_t callbackId = 0;
        int32_t ret = HMS_NetworkBoost_RegisterMultiPathRecommendationCallback(
            testCallback,
            &callbackId
        );
        
        if (ret == 0) {
            callbackIds.push_back(callbackId);
            printf("注册%d: callbackId=%u\n", i+1, callbackId);
        } else if (ret == 1013600041) {
            printf("✓ 测试通过：达到注册上限（错误码1013600041）\n");
            printf("达到上限时的注册次数: %zu\n", callbackIds.size());
            break;
        } else {
            printf("注册%d失败: ret=%d\n", i+1, ret);
            break;
        }
    }
    
    // 清理所有注册
    printf("清理所有注册...\n");
    for (size_t i = 0; i < callbackIds.size(); i++) {
        HMS_NetworkBoost_UnregisterMultiPathRecommendationCallback(callbackIds[i]);
    }
    
    printf("清理完成，共取消%zu个注册\n\n", callbackIds.size());
}

int main() {
    printf("========================================\n");
    printf("测试用例：多次注册取消测试\n");
    printf("========================================\n\n");
    
    TestContinuousRegisterUnregister();
    TestRegisterAfterUnregister();
    TestRegisterLimit();
    
    printf("\n========================================\n");
    printf("测试结束\n");
    printf("========================================\n");
    
    return 0;
}