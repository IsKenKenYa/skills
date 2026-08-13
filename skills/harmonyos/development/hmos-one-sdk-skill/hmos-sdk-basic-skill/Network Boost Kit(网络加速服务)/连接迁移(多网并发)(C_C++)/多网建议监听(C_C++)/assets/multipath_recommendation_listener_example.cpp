/**
 * @file multipath_recommendation_listener_example.cpp
 * @brief 多网建议监听完整示例代码
 * @details 演示如何注册和取消注册多网建议变化回调
 */

#include "NetworkBoostKit/network_boost_handover.h"
#include <cstdio>
#include <cstring>
#include <unistd.h>

// 全局变量保存callbackId
static uint32_t g_callbackId = 0;
static bool g_isRunning = true;

/**
 * @brief 多网建议变化回调函数
 * @param recommendation 多网推荐信息
 */
void onMultiPathRecommendationCallback(NetworkBoost_MultiPathRecommendation* recommendation) {
    if (recommendation == nullptr) {
        printf("[Callback] 错误：recommendation指针为空\n");
        return;
    }
    
    printf("[Callback] 收到多网建议变化事件\n");
    
    // 处理多网建议
    switch (recommendation->action) {
        case NB_MULTIPATH_ACTION_REQUEST:
            printf("[Callback] 系统建议发起多网请求\n");
            // 应用可根据业务场景决定是否发起多网请求
            // 注意：回调函数中不建议直接调用API，建议异步处理
            break;
            
        case NB_MULTIPATH_ACTION_RELEASE:
            printf("[Callback] 系统建议释放多网请求\n");
            // 应用可根据业务场景决定是否释放多网请求
            break;
            
        default:
            printf("[Callback] 未知的建议动作: %d\n", recommendation->action);
    }
}

/**
 * @brief 错误处理函数
 * @param errorCode 错误码
 * @param operation 操作名称
 */
void HandleError(int32_t errorCode, const char* operation) {
    printf("[%s] 错误码: %d\n", operation, errorCode);
    
    switch (errorCode) {
        case 0:
            printf("[%s] 成功\n", operation);
            break;
        case 201:
            printf("[%s] 权限不足，请申请ohos.permission.LINKTURBO权限\n", operation);
            break;
        case 1013600001:
            printf("[%s] 内部处理异常，请稍后重试\n", operation);
            break;
        case 1013600002:
            printf("[%s] 系统服务异常，网络管理服务可能未启动\n", operation);
            break;
        case 1013600041:
            printf("[%s] 参数错误或注册请求达到上限\n", operation);
            break;
        default:
            printf("[%s] 未知错误: %d\n", operation, errorCode);
    }
}

/**
 * @brief 注册多网建议监听
 * @return 0表示成功，其他表示失败
 */
int32_t RegisterMultiPathRecommendation() {
    printf("[Register] 开始注册多网建议监听\n");
    
    // 检查回调函数有效性
    if (onMultiPathRecommendationCallback == nullptr) {
        printf("[Register] 错误：回调函数指针为空\n");
        return 1013600041;
    }
    
    // 注册回调
    int32_t ret = HMS_NetworkBoost_RegisterMultiPathRecommendationCallback(
        onMultiPathRecommendationCallback, 
        &g_callbackId
    );
    
    HandleError(ret, "Register");
    
    if (ret == 0) {
        printf("[Register] callbackId: %u\n", g_callbackId);
    }
    
    return ret;
}

/**
 * @brief 取消多网建议监听
 * @return 0表示成功，其他表示失败
 */
int32_t UnregisterMultiPathRecommendation() {
    printf("[Unregister] 开始取消多网建议监听\n");
    
    // 检查callbackId有效性
    if (g_callbackId == 0) {
        printf("[Unregister] 警告：callbackId为0，可能未注册或已取消\n");
        return 1013600041;
    }
    
    printf("[Unregister] 使用callbackId: %u取消注册\n", g_callbackId);
    
    // 取消注册
    int32_t ret = HMS_NetworkBoost_UnregisterMultiPathRecommendationCallback(g_callbackId);
    
    HandleError(ret, "Unregister");
    
    if (ret == 0) {
        printf("[Unregister] 取消注册成功\n");
        g_callbackId = 0;  // 重置callbackId
    }
    
    return ret;
}

/**
 * @brief 应用启动初始化
 */
void OnAppStart() {
    printf("[App] 应用启动\n");
    
    int32_t ret = RegisterMultiPathRecommendation();
    if (ret != 0) {
        printf("[App] 多网建议监听不可用，应用自主决策网络策略\n");
    }
}

/**
 * @brief 应用退出清理
 */
void OnAppExit() {
    printf("[App] 应用退出\n");
    
    if (g_callbackId != 0) {
        UnregisterMultiPathRecommendation();
    }
    
    g_isRunning = false;
}

/**
 * @brief 主函数
 */
int main() {
    printf("========================================\n");
    printf("多网建议监听示例程序\n");
    printf("========================================\n\n");
    
    // 应用启动初始化
    OnAppStart();
    
    // 模拟应用运行
    printf("[App] 应用运行中，等待多网建议变化...\n");
    
    int loopCount = 0;
    while (g_isRunning && loopCount < 10) {
        printf("[App] 运行第 %d 秒\n", loopCount + 1);
        sleep(1);
        loopCount++;
        
        // 模拟业务场景
        if (loopCount == 5) {
            printf("[App] 模拟业务场景：切换到前台活跃状态\n");
        }
        
        if (loopCount == 8) {
            printf("[App] 模拟业务场景：准备退出\n");
            break;
        }
    }
    
    // 应用退出清理
    OnAppExit();
    
    printf("\n========================================\n");
    printf("示例程序结束\n");
    printf("========================================\n");
    
    return 0;
}