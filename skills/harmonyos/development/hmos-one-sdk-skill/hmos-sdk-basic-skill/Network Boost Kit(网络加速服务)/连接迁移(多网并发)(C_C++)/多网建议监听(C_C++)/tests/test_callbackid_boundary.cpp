/**
 * @file test_callbackid_boundary.cpp
 * @brief 测试用例：callbackId边界测试
 * @details 验证callbackId的最大值和最小值边界
 */

#include "NetworkBoostKit/network_boost_handover.h"
#include <cstdio>
#include <cstdint>

// 测试回调函数
void testCallback(NetworkBoost_MultiPathRecommendation* recommendation) {
    printf("Test callback\n");
}

/**
 * @brief 测试callbackId最小值
 */
void TestCallbackIdMinBoundary() {
    printf("=== 测试：callbackId最小值边界 ===\n");
    
    uint32_t callbackId = 0;
    
    // 注册
    int32_t ret = HMS_NetworkBoost_RegisterMultiPathRecommendationCallback(
        testCallback,
        &callbackId
    );
    
    if (ret == 0) {
        printf("注册成功，callbackId: %u\n", callbackId);
        
        // 验证callbackId最小值（应为>=1）
        if (callbackId >= 1) {
            printf("✓ 测试通过：callbackId最小值有效（>=1）\n");
        } else {
            printf("✗ 测试失败：callbackId无效（值为0）\n");
        }
        
        // 清理
        HMS_NetworkBoost_UnregisterMultiPathRecommendationCallback(callbackId);
    } else {
        printf("注册失败，错误码: %d\n", ret);
    }
    
    printf("\n");
}

/**
 * @brief 测试callbackId最大值
 */
void TestCallbackIdMaxBoundary() {
    printf("=== 测试：callbackId最大值边界 ===\n");
    
    uint32_t callbackId = 0;
    
    // 注册
    int32_t ret = HMS_NetworkBoost_RegisterMultiPathRecommendationCallback(
        testCallback,
        &callbackId
    );
    
    if (ret == 0) {
        printf("注册成功，callbackId: %u\n", callbackId);
        
        // 验证callbackId最大值（应小于uint32_t最大值）
        uint32_t maxValue = UINT32_MAX;
        if (callbackId < maxValue) {
            printf("✓ 测试通过：callbackId未溢出（< %u）\n", maxValue);
        } else {
            printf("✗ 测试失败：callbackId可能溢出\n");
        }
        
        // 清理
        HMS_NetworkBoost_UnregisterMultiPathRecommendationCallback(callbackId);
    } else {
        printf("注册失败，错误码: %d\n", ret);
    }
    
    printf("\n");
}

/**
 * @brief 测试多次注册callbackId递增
 */
void TestCallbackIdIncrement() {
    printf("=== 测试：多次注册callbackId递增 ===\n");
    
    uint32_t callbackId1 = 0;
    uint32_t callbackId2 = 0;
    uint32_t callbackId3 = 0;
    
    // 定义不同的回调函数
    void callback1(NetworkBoost_MultiPathRecommendation* r) {}
    void callback2(NetworkBoost_MultiPathRecommendation* r) {}
    void callback3(NetworkBoost_MultiPathRecommendation* r) {}
    
    // 第一次注册
    int32_t ret1 = HMS_NetworkBoost_RegisterMultiPathRecommendationCallback(callback1, &callbackId1);
    
    if (ret1 == 0) {
        printf("第1次注册成功，callbackId: %u\n", callbackId1);
    } else {
        printf("第1次注册失败: %d\n", ret1);
        return;
    }
    
    // 第二次注册
    int32_t ret2 = HMS_NetworkBoost_RegisterMultiPathRecommendationCallback(callback2, &callbackId2);
    
    if (ret2 == 0) {
        printf("第2次注册成功，callbackId: %u\n", callbackId2);
        
        // 验证callbackId递增
        if (callbackId2 > callbackId1) {
            printf("✓ 测试通过：callbackId递增（%u > %u）\n", callbackId2, callbackId1);
        } else if (callbackId2 == callbackId1) {
            printf("提示：callbackId相同（可能重用）\n");
        } else {
            printf("提示：callbackId未递增（可能随机分配）\n");
        }
    } else {
        printf("第2次注册失败: %d\n", ret2);
    }
    
    // 第三次注册
    int32_t ret3 = HMS_NetworkBoost_RegisterMultiPathRecommendationCallback(callback3, &callbackId3);
    
    if (ret3 == 0) {
        printf("第3次注册成功，callbackId: %u\n", callbackId3);
    } else {
        printf("第3次注册失败: %d（可能达到注册上限）\n", ret3);
    }
    
    // 清理所有注册
    if (ret1 == 0) HMS_NetworkBoost_UnregisterMultiPathRecommendationCallback(callbackId1);
    if (ret2 == 0) HMS_NetworkBoost_UnregisterMultiPathRecommendationCallback(callbackId2);
    if (ret3 == 0) HMS_NetworkBoost_UnregisterMultiPathRecommendationCallback(callbackId3);
    
    printf("清理完成\n\n");
}

int main() {
    printf("========================================\n");
    printf("测试用例：callbackId边界测试\n");
    printf("========================================\n\n");
    
    TestCallbackIdMinBoundary();
    TestCallbackIdMaxBoundary();
    TestCallbackIdIncrement();
    
    printf("\n========================================\n");
    printf("测试结束\n");
    printf("========================================\n");
    
    return 0;
}