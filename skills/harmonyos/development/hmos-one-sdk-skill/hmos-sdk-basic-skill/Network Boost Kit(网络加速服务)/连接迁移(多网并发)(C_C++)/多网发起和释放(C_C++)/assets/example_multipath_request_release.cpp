/**
 * 多网发起和释放完整示例代码
 * 
 * 本示例演示如何使用HarmonyOS Network Boost Kit的C API
 * 发起和释放多网并发请求
 * 
 * API版本：6.0.2(22)
 * 权限要求：ohos.permission.LINKTURBO（受限权限）
 */

#include "NetworkBoostKit/network_boost_handover.h"
#include <cstdio>
#include <cstring>
#include <unistd.h>

// 全局变量：多网请求状态
static bool g_multiPathRequested = false;
static bool g_multiPathCreated = false;

/**
 * 多网请求结果回调函数
 * 
 * @param result 多网请求结果信息
 */
void onMultiPathRequestResultCallback(NetworkBoost_MultiPathRequestResult* result) {
    if (result == nullptr) {
        printf("[ERROR] 多网请求结果回调参数为空\n");
        return;
    }
    
    printf("[INFO] 多网请求结果回调触发\n");
    
    // 根据结果处理多网请求成功或失败
    switch (result->result) {
        case NB_MULTIPATH_ERROR_NONE:
            printf("[SUCCESS] 多网请求成功\n");
            g_multiPathCreated = true;
            break;
        case NB_MULTIPATH_ERROR_NETWORK_REFUSED:
            printf("[ERROR] 多网请求被网络拒绝\n");
            break;
        case NB_MULTIPATH_ERROR_TIMEOUT:
            printf("[ERROR] 多网建立超时\n");
            break;
        case NB_MULTIPATH_ERROR_LOCAL:
            printf("[ERROR] 多网建立过程中本地释放\n");
            break;
        default:
            printf("[ERROR] 未知错误：%d\n", result->result);
            break;
    }
}

/**
 * 多网状态变化回调函数
 * 
 * @param multiPathState 多网状态变化信息
 */
void onMultiPathStateChangeCallback(NetworkBoost_MultiPathStateChange* multiPathState) {
    if (multiPathState == nullptr) {
        printf("[ERROR] 多网状态变化回调参数为空\n");
        return;
    }
    
    printf("[INFO] 多网状态变化回调触发\n");
    
    // 解析多网状态
    const char* stateStr = "";
    switch (multiPathState->multiPathState) {
        case NB_MULTIPATH_IDLE:
            stateStr = "空闲状态";
            g_multiPathCreated = false;
            break;
        case NB_MULTIPATH_CREATEING:
            stateStr = "建立中";
            break;
        case NB_MULTIPATH_CREATED:
            stateStr = "已建立";
            g_multiPathCreated = true;
            break;
        case NB_MULTIPATH_RELEASING:
            stateStr = "释放中";
            break;
        default:
            stateStr = "未知状态";
            break;
    }
    
    // 解析链路类型
    const char* pathTypeStr = "";
    switch (multiPathState->pathType) {
        case NB_PATH_CELLULAR_PRIMARY:
            pathTypeStr = "蜂窝主卡";
            break;
        case NB_PATH_CELLULAR_SECONDARY:
            pathTypeStr = "蜂窝副卡";
            break;
        case NB_PATH_WIFI_PRIMARY:
            pathTypeStr = "主Wi-Fi";
            break;
        case NB_PATH_WIFI_SECONDARY:
            pathTypeStr = "辅Wi-Fi";
            break;
        default:
            pathTypeStr = "未知链路";
            break;
    }
    
    // 解析链路状态
    const char* pathStateStr = "";
    switch (multiPathState->pathState) {
        case NB_PATH_IDLE:
            pathStateStr = "空闲";
            break;
        case NB_PATH_CONNECTED:
            pathStateStr = "已连接";
            break;
        case NB_PATH_SUSPENDED:
            pathStateStr = "挂起";
            break;
        default:
            pathStateStr = "未知状态";
            break;
    }
    
    // 解析变化原因
    const char* causeStr = "";
    switch (multiPathState->changeCause) {
        case NB_MULTIPATH_CAUSE_REQUEST_NORMAL:
            causeStr = "正常发起多网请求";
            break;
        case NB_MULTIPATH_CAUSE_RELEASE_NORMAL:
            causeStr = "正常释放多网请求";
            g_multiPathCreated = false;
            break;
        case NB_MULTIPATH_CHANGE_CAUSE_RELEASE_NETWORK:
            causeStr = "网络原因释放多网";
            g_multiPathCreated = false;
            break;
        case NB_MULTIPATH_CHANGE_CAUSE_RELEASE_USER_REFUSED:
            causeStr = "用户操作开关释放多网";
            g_multiPathCreated = false;
            break;
        case NB_MULTIPATH_CAUSE_RELEASE_NO_QUOTA:
            causeStr = "配额耗尽释放多网";
            g_multiPathCreated = false;
            break;
        case NB_MULTIPATH_CHANGE_CAUSE_RELEASE_SYS_FUSING:
            causeStr = "应用使用不规范，系统释放多网";
            g_multiPathCreated = false;
            break;
        default:
            causeStr = "其他原因";
            break;
    }
    
    printf("[INFO] 多网状态：%s，链路类型：%s，链路状态：%s，变化原因：%s\n",
           stateStr, pathTypeStr, pathStateStr, causeStr);
}

/**
 * 发起多网请求
 * 
 * @return 0表示成功，其他表示错误码
 */
int32_t requestMultiPath() {
    printf("[INFO] 开始发起多网请求\n");
    
    // 发起多网请求，注册回调监听请求结果
    int32_t ret = HMS_NetworkBoost_RequestMultiPath(onMultiPathRequestResultCallback);
    
    if (ret != 0) {
        printf("[ERROR] 发起多网请求失败，错误码：%d\n", ret);
        handleRequestError(ret);
        return ret;
    }
    
    g_multiPathRequested = true;
    printf("[SUCCESS] 发起多网请求成功，等待回调结果\n");
    return 0;
}

/**
 * 释放多网请求
 * 
 * @return 0表示成功，其他表示错误码
 */
int32_t releaseMultiPath() {
    printf("[INFO] 开始释放多网请求\n");
    
    if (!g_multiPathRequested) {
        printf("[WARN] 未发起多网请求，无需释放\n");
        return 0;
    }
    
    // 释放多网请求
    int32_t ret = HMS_NetworkBoost_ReleaseMultiPath();
    
    if (ret != 0) {
        printf("[ERROR] 释放多网请求失败，错误码：%d\n", ret);
        handleReleaseError(ret);
        return ret;
    }
    
    g_multiPathRequested = false;
    g_multiPathCreated = false;
    printf("[SUCCESS] 释放多网请求成功\n");
    return 0;
}

/**
 * 处理多网请求错误
 * 
 * @param errorCode 错误码
 */
void handleRequestError(int32_t errorCode) {
    switch (errorCode) {
        case 201:
            printf("[ERROR] 权限不足，请申请ohos.permission.LINKTURBO权限\n");
            printf("[SOLUTION] 在module.json5中添加权限，并在AGC中申请LINKTURBO权限\n");
            break;
        case 1013600001:
            printf("[ERROR] 内部处理异常\n");
            printf("[SOLUTION] 检查系统状态，重启应用或设备\n");
            break;
        case 1013600002:
            printf("[ERROR] 系统处理异常\n");
            printf("[SOLUTION] 检查网络管理服务，重启设备\n");
            break;
        case 1013600041:
            printf("[ERROR] 传入参数有误\n");
            printf("[SOLUTION] 确保回调函数不为空指针\n");
            break;
        case 1013620000:
            printf("[ERROR] 多网功能没有使能\n");
            printf("[SOLUTION] 开启网络加速开关：设置->移动网络->网络加速\n");
            break;
        case 1013620001:
            printf("[ERROR] 多网已经激活\n");
            printf("[SOLUTION] 检查是否已发起多网请求，避免重复请求\n");
            break;
        case 1013620002:
            printf("[ERROR] 应用多网请求已达上限\n");
            printf("[SOLUTION] 等待配额恢复或释放其他多网请求\n");
            break;
        case 1013620003:
            printf("[ERROR] 功耗限制不允许发起多网\n");
            printf("[SOLUTION] 降低功耗需求或等待功耗限制解除\n");
            break;
        case 1013620004:
            printf("[ERROR] 限额耗尽\n");
            printf("[SOLUTION] 等待配额恢复或申请更多配额\n");
            break;
        case 1013620005:
            printf("[ERROR] 多网请求场景冲突\n");
            printf("[SOLUTION] 检查场景冲突，调整业务场景\n");
            break;
        case 1013620006:
            printf("[ERROR] 多网发起太频繁\n");
            printf("[SOLUTION] 降低发起频率，避免频繁请求\n");
            break;
        case 1013620007:
            printf("[ERROR] 没有合适的多网链路可用\n");
            printf("[SOLUTION] 检查网络条件，使用单网传输\n");
            break;
        case 1013620008:
            printf("[ERROR] 流量不足\n");
            printf("[SOLUTION] 检查流量余额，使用WiFi传输\n");
            break;
        case 1013620009:
            printf("[ERROR] 不支持并发\n");
            printf("[SOLUTION] 设备不支持多网并发，使用单网传输\n");
            break;
        default:
            printf("[ERROR] 未知错误：%d\n", errorCode);
            printf("[SOLUTION] 使用单网传输作为降级方案\n");
            break;
    }
}

/**
 * 处理多网释放错误
 * 
 * @param errorCode 错误码
 */
void handleReleaseError(int32_t errorCode) {
    switch (errorCode) {
        case 201:
            printf("[ERROR] 权限不足\n");
            printf("[SOLUTION] 申请ohos.permission.LINKTURBO权限\n");
            break;
        case 1013600001:
            printf("[ERROR] 内部处理异常\n");
            printf("[SOLUTION] 检查系统状态，重启应用或设备\n");
            break;
        case 1013600002:
            printf("[ERROR] 系统处理异常\n");
            printf("[SOLUTION] 检查网络管理服务，重启设备\n");
            break;
        case 1013620100:
            printf("[ERROR] 多网已激活但不是当前应用拉起\n");
            printf("[SOLUTION] 检查多网状态，避免释放其他应用的多网\n");
            break;
        case 1013620101:
            printf("[ERROR] 多网不在激活态\n");
            printf("[SOLUTION] 检查多网状态，确保多网已建立后再释放\n");
            break;
        default:
            printf("[ERROR] 未知错误：%d\n", errorCode);
            break;
    }
}

/**
 * 获取多网配额信息
 * 
 * @return 0表示成功，其他表示错误码
 */
int32_t getMultiPathQuotaStats() {
    printf("[INFO] 开始获取多网配额信息\n");
    
    NetworkBoost_MultiPathQuota quota;
    memset(&quota, 0, sizeof(quota));
    
    int32_t ret = HMS_NetworkBoost_GetMultiPathQuotaStats(&quota);
    
    if (ret != 0) {
        printf("[ERROR] 获取多网配额失败，错误码：%d\n", ret);
        return ret;
    }
    
    printf("[SUCCESS] 多网配额信息：已使用配额=%llu，剩余配额=%llu\n",
           quota.usedQuota, quota.remainingQuota);
    
    return 0;
}

/**
 * 主函数：演示完整的多网发起和释放流程
 */
int main() {
    printf("========================================\n");
    printf("HarmonyOS 多网发起和释放示例\n");
    printf("API版本：6.0.2(22)\n");
    printf("========================================\n\n");
    
    // 步骤1：获取多网配额信息（可选）
    printf("步骤1：获取多网配额信息\n");
    getMultiPathQuotaStats();
    printf("\n");
    
    // 步骤2：发起多网请求
    printf("步骤2：发起多网请求\n");
    int32_t ret = requestMultiPath();
    if (ret != 0) {
        printf("[ERROR] 多网请求失败，示例终止\n");
        return -1;
    }
    printf("\n");
    
    // 步骤3：等待多网建立（模拟等待回调）
    printf("步骤3：等待多网建立结果\n");
    sleep(2);  // 等待2秒，实际应用中通过回调处理
    
    if (!g_multiPathCreated) {
        printf("[ERROR] 多网未成功建立\n");
        // 降级处理：使用单网传输
        printf("[FALLBACK] 使用单网传输\n");
        return -1;
    }
    printf("[SUCCESS] 多网已成功建立，可以开始使用\n");
    printf("\n");
    
    // 步骤4：使用多网进行数据传输（模拟）
    printf("步骤4：使用多网进行数据传输\n");
    printf("[INFO] 多网已建立，可以进行数据传输\n");
    printf("[INFO] 链路类型由系统决定（WiFi/蜂窝/主卡/副卡）\n");
    sleep(5);  // 模拟使用多网传输5秒
    printf("\n");
    
    // 步骤5：释放多网请求
    printf("步骤5：释放多网请求\n");
    ret = releaseMultiPath();
    if (ret != 0) {
        printf("[ERROR] 释放多网失败\n");
        return -1;
    }
    printf("\n");
    
    printf("========================================\n");
    printf("[SUCCESS] 多网发起和释放流程完成\n");
    printf("========================================\n");
    
    return 0;
}