/**
 * @file test_permission_denied.cpp
 * @brief 测试用例：权限不足测试
 * @details 验证无权限时的错误处理和降级方案
 * @note 此测试需要在无权限环境下运行
 */

#include "NetworkBoostKit/network_boost_handover.h"
#include <cstdio>

// 测试回调函数
void testCallback(NetworkBoost_MultiPathRecommendation* recommendation) {
    printf("Test callback\n");
}

/**
 * @brief 测试无权限时注册回调
 * @note 需要移除ohos.permission.LINKTURBO权限才能测试
 */
void TestPermissionDenied() {
    printf("=== 测试：权限不足 ===\n");
    printf("提示：此测试需要移除ohos.permission.LINKTURBO权限\n");
    
    uint32_t callbackId = 0;
    
    // 尝试注册（应返回权限错误）
    int32_t ret = HMS_NetworkBoost_RegisterMultiPathRecommendationCallback(
        testCallback,
        &callbackId
    );
    
    printf("返回值: %d\n", ret);
    
    if (ret == 201) {
        printf("✓ 测试通过：正确返回权限不足错误码（201）\n");
        
        // 降级处理
        printf("降级方案：应用自主决策网络策略，不监听多网建议\n");
    } else if (ret == 0) {
        printf("提示：权限已申请，无法测试权限不足场景\n");
        printf("建议：移除权限后重新测试\n");
        
        // 清理
        HMS_NetworkBoost_UnregisterMultiPathRecommendationCallback(callbackId);
    } else {
        printf("提示：其他错误: %d\n", ret);
    }
    
    printf("\n");
}

/**
 * @brief 测试无权限时取消注册
 */
void TestPermissionDeniedUnregister() {
    printf("=== 测试：权限不足（取消注册） ===\n");
    
    // 使用随机callbackId尝试取消
    uint32_t callbackId = 12345;
    
    int32_t ret = HMS_NetworkBoost_UnregisterMultiPathRecommendationCallback(callbackId);
    
    printf("返回值: %d\n", ret);
    
    if (ret == 201) {
        printf("✓ 测试通过：取消注册也返回权限不足\n\n");
    } else {
        printf("提示：返回其他错误码: %d\n\n", ret);
    }
}

/**
 * @brief 降级方案示例
 */
void DemonstrateFallback() {
    printf("=== 降级方案演示 ===\n");
    printf("当无法监听多网建议时，应用可采取的策略：\n");
    printf("1. 自主检测网络质量（使用网络质量API）\n");
    printf("2. 根据业务场景自主决策是否使用多网\n");
    printf("3. 监听网络状态变化事件\n");
    printf("4. 用户手动触发多网加速\n");
    printf("\n");
}

int main() {
    printf("========================================\n");
    printf("测试用例：权限不足测试\n");
    printf("========================================\n\n");
    
    TestPermissionDenied();
    TestPermissionDeniedUnregister();
    DemonstrateFallback();
    
    printf("\n========================================\n");
    printf("测试结束\n");
    printf("========================================\n");
    
    return 0;
}