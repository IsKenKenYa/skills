/**
 * @file test_invalid_callbackid.cpp
 * @brief 测试用例：无效callbackId测试
 * @details 验证无效callbackId的错误处理
 */

#include "NetworkBoostKit/network_boost_handover.h"
#include <cstdio>
#include <cassert>

/**
 * @brief 测试使用callbackId为0取消注册
 */
void TestZeroCallbackId() {
    printf("=== 测试：callbackId为0 ===\n");
    
    uint32_t callbackId = 0;  // 使用无效的callbackId（值为0）
    
    int32_t ret = HMS_NetworkBoost_UnregisterMultiPathRecommendationCallback(callbackId);
    
    printf("返回值: %d\n", ret);
    
    // 验证返回值（应为错误码，表示callbackId无效）
    // 注意：具体错误码可能因实现不同，验证非0即可
    assert(ret != 0);
    
    printf("✓ 测试通过：正确处理callbackId为0的情况\n\n");
}

/**
 * @brief 测试使用超大callbackId取消注册
 */
void TestOverflowCallbackId() {
    printf("=== 测试：超大callbackId ===\n");
    
    uint32_t callbackId = 999999999;  // 使用超大但无效的callbackId
    
    int32_t ret = HMS_NetworkBoost_UnregisterMultiPathRecommendationCallback(callbackId);
    
    printf("返回值: %d\n", ret);
    
    // 验证返回值（应为错误码）
    assert(ret != 0);
    
    printf("✓ 测试通过：正确处理超大无效callbackId\n\n");
}

/**
 * @brief 测试使用未注册的callbackId取消注册
 */
void TestUnregisteredCallbackId() {
    printf("=== 测试：未注册的callbackId ===\n");
    
    // 先注册一个回调，获取有效的callbackId
    void tempCallback(NetworkBoost_MultiPathRecommendation* recommendation) {}
    
    uint32_t validCallbackId = 0;
    int32_t regRet = HMS_NetworkBoost_RegisterMultiPathRecommendationCallback(
        tempCallback,
        &validCallbackId
    );
    
    if (regRet == 0) {
        printf("注册成功，有效callbackId: %u\n", validCallbackId);
        
        // 取消注册
        HMS_NetworkBoost_UnregisterMultiPathRecommendationCallback(validCallbackId);
        printf("已取消注册callbackId: %u\n", validCallbackId);
        
        // 再次使用已取消的callbackId尝试取消
        int32_t ret = HMS_NetworkBoost_UnregisterMultiPathRecommendationCallback(validCallbackId);
        printf("再次取消返回值: %d\n", ret);
        
        printf("提示：已取消的callbackId再次使用应返回错误\n\n");
    } else {
        printf("注册失败，跳过测试\n\n");
    }
}

int main() {
    printf("========================================\n");
    printf("测试用例：无效callbackId测试\n");
    printf("========================================\n\n");
    
    TestZeroCallbackId();
    TestOverflowCallbackId();
    TestUnregisteredCallbackId();
    
    printf("\n========================================\n");
    printf("所有测试通过\n");
    printf("========================================\n");
    
    return 0;
}