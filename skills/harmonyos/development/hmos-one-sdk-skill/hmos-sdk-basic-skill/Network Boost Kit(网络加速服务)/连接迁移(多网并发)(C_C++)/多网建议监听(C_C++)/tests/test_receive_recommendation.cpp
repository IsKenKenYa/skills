/**
 * @file test_receive_recommendation.cpp
 * @brief 测试用例：接收建议回调测试
 * @details 验证回调函数正确接收建议并处理
 */

#include "NetworkBoostKit/network_boost_handover.h"
#include <cstdio>
#include <cstring>

// 测试数据
static bool g_callbackReceived = false;
static NetworkBoost_MultiPathAction g_receivedAction = NB_MULTIPATH_ACTION_REQUEST;

/**
 * @brief 测试回调函数
 * @param recommendation 多网推荐信息
 */
void testReceiveCallback(NetworkBoost_MultiPathRecommendation* recommendation) {
    if (recommendation == nullptr) {
        printf("[Callback] 错误：recommendation为空\n");
        return;
    }
    
    printf("[Callback] 收到多网建议\n");
    printf("[Callback] action: %d\n", recommendation->action);
    
    g_callbackReceived = true;
    g_receivedAction = recommendation->action;
    
    // 验证action值
    if (recommendation->action == NB_MULTIPATH_ACTION_REQUEST) {
        printf("[Callback] ✓ 建议发起多网请求\n");
    } else if (recommendation->action == NB_MULTIPATH_ACTION_RELEASE) {
        printf("[Callback] ✓ 建议释放多网请求\n");
    } else {
        printf("[Callback] ✗ 未知的action值\n");
    }
}

/**
 * @brief 测试接收建议回调
 */
void TestReceiveRecommendation() {
    printf("=== 测试：接收建议回调 ===\n");
    
    uint32_t callbackId = 0;
    
    // 注册回调
    int32_t ret = HMS_NetworkBoost_RegisterMultiPathRecommendationCallback(
        testReceiveCallback, 
        &callbackId
    );
    
    if (ret != 0) {
        printf("✗ 注册失败，错误码: %d\n", ret);
        return;
    }
    
    printf("注册成功，callbackId: %u\n", callbackId);
    printf("等待系统触发多网建议变化事件...\n");
    printf("提示：在弱网或网络切换场景下系统会触发回调\n");
    
    // 模拟等待回调
    // 实际测试中需要手动触发弱网或网络切换场景
    sleep(10);
    
    // 检查是否收到回调
    if (g_callbackReceived) {
        printf("✓ 已收到回调，action: %d\n", g_receivedAction);
    } else {
        printf("提示：未收到回调，可能未触发多网建议变化事件\n");
        printf("建议在弱网或网络切换场景下测试\n");
    }
    
    // 清理
    HMS_NetworkBoost_UnregisterMultiPathRecommendationCallback(callbackId);
    printf("清理完成\n\n");
}

int main() {
    printf("========================================\n");
    printf("测试用例：接收建议回调测试\n");
    printf("========================================\n\n");
    
    TestReceiveRecommendation();
    
    printf("\n========================================\n");
    printf("测试结束\n");
    printf("========================================\n");
    
    return 0;
}