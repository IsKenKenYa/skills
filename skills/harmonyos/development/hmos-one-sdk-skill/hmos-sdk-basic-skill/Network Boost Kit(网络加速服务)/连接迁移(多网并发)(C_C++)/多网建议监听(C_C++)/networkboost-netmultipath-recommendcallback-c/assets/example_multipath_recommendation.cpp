/**
 * 多网建议监听完整示例代码
 * 
 * 本示例展示如何使用 Network Boost Kit 的多网建议监听功能:
 * 1. 注册多网建议变化事件回调
 * 2. 接收和处理多网建议信息
 * 3. 根据建议动作决策发起或释放多网请求
 * 4. 取消注册多网建议监听回调
 */

#include "NetworkBoostKit/network_boost_handover.h"
#include <cstdio>
#include <cstring>
#include <thread>
#include <mutex>
#include <atomic>

// 全局变量
static uint32_t g_callbackId = 0;
static std::atomic<bool> g_isRegistered{false};
static std::mutex g_mutex;
static NetworkBoost_MultiPathAction g_lastRecommendationAction = NB_MULTIPATH_ACTION_REQUEST;

/**
 * 多网建议回调函数
 * 系统在感知到弱网或网络切换场景时,会通过此回调推送多网建议
 */
void onMultiPathRecommendationCallback(NetworkBoost_MultiPathRecommendation* recommendation) {
    if (recommendation == nullptr) {
        printf("[ERROR] 多网建议信息指针为空\n");
        return;
    }
    
    // 记录建议动作
    g_lastRecommendationAction = recommendation->action;
    
    // 处理多网建议
    switch (recommendation->action) {
        case NB_MULTIPATH_ACTION_REQUEST:
            printf("[INFO] 系统建议: 发起多网请求\n");
            printf("[INFO] 当前场景可能需要多网加速(弱网/网络切换)\n");
            // 应用可在此处决策是否发起多网请求
            // 注意: 不要在回调中直接调用 HMS_NetworkBoost_RequestMultiPath
            // 应通知主线程,由主线程发起请求
            break;
            
        case NB_MULTIPATH_ACTION_RELEASE:
            printf("[INFO] 系统建议: 释放多网请求\n");
            printf("[INFO] 当前场景不再需要多网加速\n");
            // 应用可在此处决策是否释放多网请求
            // 注意: 不要在回调中直接调用 HMS_NetworkBoost_ReleaseMultiPath
            // 应通知主线程,由主线程释放请求
            break;
            
        default:
            printf("[WARN] 未知的建议动作: %d\n", recommendation->action);
            break;
    }
}

/**
 * 注册多网建议监听回调
 * 
 * @return 0:成功, 其他:错误码
 */
int32_t RegisterMultiPathRecommendation() {
    // 参数校验
    if (onMultiPathRecommendationCallback == nullptr) {
        printf("[ERROR] 回调函数指针为空\n");
        return 1013600041;  // 参数错误
    }
    
    // 检查是否已注册
    if (g_isRegistered.load()) {
        printf("[WARN] 多网建议回调已注册,回调ID: %u\n", g_callbackId);
        return 0;
    }
    
    // 注册回调
    int32_t ret = HMS_NetworkBoost_RegisterMultiPathRecommendationCallback(
        onMultiPathRecommendationCallback, 
        &g_callbackId
    );
    
    // 处理返回结果
    if (ret == 0) {
        g_isRegistered.store(true);
        printf("[SUCCESS] 注册多网建议监听回调成功\n");
        printf("[INFO] 回调ID: %u\n", g_callbackId);
        printf("[INFO] 等待系统推送多网建议...\n");
    } else {
        printf("[FAILED] 注册多网建议监听回调失败\n");
        HandleRegisterError(ret);
    }
    
    return ret;
}

/**
 * 处理注册错误
 * 
 * @param errorCode 错误码
 */
void HandleRegisterError(int32_t errorCode) {
    switch (errorCode) {
        case 201:
            printf("[ERROR] 权限不足\n");
            printf("[SOLUTION] 请检查以下配置:\n");
            printf("  1. module.json5 中是否声明 ohos.permission.LINKTURBO 权限\n");
            printf("  2. 是否通过 AGC 申请并配置了受限 ACL 权限签名\n");
            break;
            
        case 1013600001:
            printf("[ERROR] 内部处理异常\n");
            printf("[SOLUTION] 系统状态机或消息队列异常,建议稍后重试\n");
            break;
            
        case 1013600002:
            printf("[ERROR] 系统服务异常\n");
            printf("[SOLUTION] IPC调用失败或网络管理服务未启动\n");
            printf("  建议: 检查系统服务状态并重试\n");
            break;
            
        case 1013600041:
            printf("[ERROR] 参数错误\n");
            printf("[SOLUTION] 回调函数指针或 callbackId 指针为空\n");
            break;
            
        case 62100003:
            printf("[ERROR] 注册请求达到上限\n");
            printf("[SOLUTION] 请先取消旧的回调后再重新注册\n");
            break;
            
        default:
            printf("[ERROR] 未知错误码: %d\n", errorCode);
            break;
    }
}

/**
 * 取消注册多网建议监听回调
 * 
 * @return 0:成功, 其他:错误码
 */
int32_t UnregisterMultiPathRecommendation() {
    // 参数校验
    if (!g_isRegistered.load()) {
        printf("[WARN] 多网建议回调未注册或已取消注册\n");
        return 0;
    }
    
    if (g_callbackId == 0) {
        printf("[WARN] 回调ID为0,可能未注册或已取消注册\n");
        return 1013600041;
    }
    
    // 取消注册
    int32_t ret = HMS_NetworkBoost_UnregisterMultiPathRecommendationCallback(g_callbackId);
    
    // 处理返回结果
    if (ret == 0) {
        g_isRegistered.store(false);
        g_callbackId = 0;
        printf("[SUCCESS] 取消多网建议监听回调成功\n");
    } else {
        printf("[FAILED] 取消多网建议监听回调失败,错误码: %d\n", ret);
        HandleUnregisterError(ret);
    }
    
    return ret;
}

/**
 * 处理取消注册错误
 * 
 * @param errorCode 错误码
 */
void HandleUnregisterError(int32_t errorCode) {
    switch (errorCode) {
        case 201:
            printf("[ERROR] 权限不足\n");
            break;
            
        case 1013600001:
            printf("[ERROR] 内部处理异常\n");
            break;
            
        case 1013600002:
            printf("[ERROR] 系统服务异常\n");
            break;
            
        default:
            printf("[ERROR] 未知错误码: %d\n", errorCode);
            break;
    }
}

/**
 * 注册失败时的降级处理
 * 
 * @return 0:成功, 其他:错误码
 */
int32_t RegisterWithFallback() {
    int32_t ret = RegisterMultiPathRecommendation();
    
    if (ret != 0) {
        printf("[FALLBACK] 尝试降级方案...\n");
        
        // 降级方案1: 权限不足时提示用户
        if (ret == 201) {
            printf("[FALLBACK1] 提示用户检查权限配置\n");
            printf("[INFO] 需要申请 ohos.permission.LINKTURBO 受限权限\n");
            return ret;
        }
        
        // 降级方案2: 系统服务异常时重试(最多3次)
        if (ret == 1013600002) {
            printf("[FALLBACK2] 系统服务异常,尝试重试...\n");
            for (int i = 0; i < 3; i++) {
                printf("[INFO] 第%d次重试...\n", i + 1);
                // 实际应用中可添加延时: std::this_thread::sleep_for(std::chrono::seconds(1));
                ret = RegisterMultiPathRecommendation();
                if (ret == 0) {
                    printf("[SUCCESS] 重试注册成功\n");
                    return 0;
                }
            }
            printf("[FAILED] 重试3次后仍失败\n");
        }
        
        // 降级方案3: 注册达到上限时取消旧回调
        if (ret == 62100003) {
            printf("[FALLBACK3] 注册达到上限,尝试取消旧回调\n");
            // 实际应用中可先取消其他回调,然后重新注册
            // 这里仅作示例
            ret = RegisterMultiPathRecommendation();
        }
        
        // 最终降级: 无法注册时提示用户
        if (ret != 0) {
            printf("[FINAL_FALLBACK] 无法注册多网建议回调\n");
            printf("[INFO] 请检查以下配置:\n");
            printf("  1. 权限配置是否正确\n");
            printf("  2. 系统服务是否正常运行\n");
            printf("  3. 是否已注册过多回调\n");
        }
    }
    
    return ret;
}

/**
 * 查询最后一次收到的多网建议动作
 * 
 * @return 多网建议动作
 */
NetworkBoost_MultiPathAction GetLastRecommendationAction() {
    return g_lastRecommendationAction;
}

/**
 * 检查回调是否已注册
 * 
 * @return true:已注册, false:未注册
 */
bool IsCallbackRegistered() {
    return g_isRegistered.load();
}

/**
 * 主函数示例
 */
int main() {
    printf("=== 多网建议监听示例 ===\n\n");
    
    // 1. 注册多网建议回调
    printf("步骤1: 注册多网建议监听回调\n");
    int32_t ret = RegisterWithFallback();
    if (ret != 0) {
        printf("[ERROR] 注册失败,示例终止\n");
        return ret;
    }
    
    // 2. 等待系统推送多网建议
    printf("\n步骤2: 等待系统推送多网建议...\n");
    printf("[INFO] 系统会在弱网或网络切换场景下推送建议\n");
    printf("[INFO] 应用可在此处执行其他业务逻辑\n");
    
    // 实际应用中可在此处:
    // - 根据建议动作(NB_MULTIPATH_ACTION_REQUEST)发起多网请求
    // - 根据建议动作(NB_MULTIPATH_ACTION_RELEASE)释放多网请求
    // - 查询建议动作: GetLastRecommendationAction()
    
    // 模拟等待一段时间
    printf("[INFO] 模拟运行10秒...\n");
    // std::this_thread::sleep_for(std::chrono::seconds(10));
    
    // 3. 取消注册回调
    printf("\n步骤3: 取消注册多网建议监听回调\n");
    ret = UnregisterMultiPathRecommendation();
    if (ret != 0) {
        printf("[ERROR] 取消注册失败\n");
        return ret;
    }
    
    printf("\n=== 示例完成 ===\n");
    return 0;
}