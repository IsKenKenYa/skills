#include "NetworkBoostKit/network_boost_quality.h"
#include <cstdio>
#include <cstring>

static uint32_t g_callbackId = 0;

void onNetworkQoSChanged(NetworkBoost_NetworkQosArray *msg)
{
    if (msg == nullptr) {
        printf("[ERROR] 回调数据为空\n");
        return;
    }
    
    printf("[INFO] 收到网络质量回调，路径数量: %u\n", msg->pathNum);
    
    for (uint32_t i = 0; i < msg->pathNum && i < NETBOOST_MAX_PATH_NUM; i++) {
        NetworkBoost_NetworkQos *qos = &msg->networkQos[i];
        
        printf("\n=== 路径%d网络质量信息 ===\n", i);
        
        const char* pathTypeName = "";
        switch (qos->pathType) {
            case NB_PATH_CELLULAR_PRIMARY: pathTypeName = "蜂窝主卡"; break;
            case NB_PATH_CELLULAR_SECONDARY: pathTypeName = "蜂窝副卡"; break;
            case NB_PATH_WIFI_PRIMARY: pathTypeName = "主Wi-Fi"; break;
            case NB_PATH_WIFI_SECONDARY: pathTypeName = "辅Wi-Fi"; break;
            default: pathTypeName = "未知类型"; break;
        }
        
        printf("数据链路类型: %s (%d)\n", pathTypeName, qos->pathType);
        printf("上行带宽: %llu bps (%llu KB/s)\n", 
               qos->linkUpBandwidth, qos->linkUpBandwidth / 8 / 1024);
        printf("下行带宽: %llu bps (%llu KB/s)\n", 
               qos->linkDownBandwidth, qos->linkDownBandwidth / 8 / 1024);
        printf("上行速率: %llu bps (%llu KB/s)\n", 
               qos->linkUpRate, qos->linkUpRate / 8 / 1024);
        printf("下行速率: %llu bps (%llu KB/s)\n", 
               qos->linkDownRate, qos->linkDownRate / 8 / 1024);
        printf("实时总速率: %llu B/s (%llu KB/s)\n", 
               (qos->linkUpRate + qos->linkDownRate) / 8,
               (qos->linkUpRate + qos->linkDownRate) / 8 / 1024);
        printf("RTT时延: %u ms\n", qos->rttMs);
        printf("上行空口缓冲时延: %u ms\n", qos->linkUpBufferDelayMs);
        printf("上行缓冲拥塞比例: %u%%\n", qos->linkUpBufferCongestionPercent);
        
        if (qos->rttMs > 100) {
            printf("[WARNING] 网络延迟较高，建议降低码率\n");
        }
        if (qos->linkDownBandwidth < 1000000) {
            printf("[WARNING] 下行带宽低于1Mbps，建议启用缓存\n");
        }
    }
}

void HandleRegisterError(int32_t errorCode)
{
    switch (errorCode) {
        case 0:
            printf("[SUCCESS] 注册成功\n");
            break;
        case 201:
            printf("[ERROR] 权限不足，请申请ohos.permission.GET_NETWORK_INFO权限\n");
            break;
        case 401:
            printf("[ERROR] 参数错误，请检查回调函数和callbackId指针\n");
            break;
        case 801:
            printf("[ERROR] 系统能力不支持\n");
            break;
        case 62100001:
            printf("[ERROR] 内部错误\n");
            break;
        case 62100002:
            printf("[ERROR] 系统服务操作失败\n");
            break;
        case 62100003:
            printf("[ERROR] 注册请求达到上限\n");
            break;
        default:
            printf("[ERROR] 未知错误码: %d\n", errorCode);
    }
}

int32_t RegisterNetQualityCallback()
{
    if (g_callbackId != 0) {
        printf("[WARNING] 已注册回调，ID: %u\n", g_callbackId);
        return 0;
    }
    
    HMS_NetworkBoost_NetQosChange callback = onNetworkQoSChanged;
    
    printf("[INFO] 开始注册网络质量回调...\n");
    int32_t ret = HMS_NetworkBoost_RegisterNetQosCallback(callback, &g_callbackId);
    
    HandleRegisterError(ret);
    
    if (ret == 0) {
        printf("[INFO] 回调ID: %u\n", g_callbackId);
    }
    
    return ret;
}

int32_t UnregisterNetQualityCallback()
{
    if (g_callbackId == 0) {
        printf("[WARNING] 未注册回调，无需取消\n");
        return -1;
    }
    
    printf("[INFO] 开始取消注册网络质量回调，ID: %u\n", g_callbackId);
    int32_t ret = HMS_NetworkBoost_UnregisterNetQosCallback(g_callbackId);
    
    if (ret == 0) {
        printf("[SUCCESS] 取消注册成功\n");
        g_callbackId = 0;
    } else {
        HandleRegisterError(ret);
    }
    
    return ret;
}

int32_t RegisterWithFallback()
{
    int32_t ret = RegisterNetQualityCallback();
    
    if (ret == 201) {
        printf("[FALLBACK] 权限不足，提示用户申请权限，功能暂不可用\n");
        return ret;
    } else if (ret == 801) {
        printf("[FALLBACK] 系统不支持，建议使用其他网络监测方案\n");
        return ret;
    } else if (ret == 62100003) {
        printf("[FALLBACK] 注册达到上限，建议取消其他回调后再尝试\n");
        return ret;
    } else if (ret != 0) {
        printf("[FALLBACK] 注册失败，记录错误，使用固定网络参数\n");
        return ret;
    }
    
    return 0;
}

void PrintUsage()
{
    printf("\n=== 网络质量评估示例程序 ===\n");
    printf("使用方法:\n");
    printf("  1 - 注册网络质量回调\n");
    printf("  2 - 取消注册网络质量回调\n");
    printf("  3 - 注册回调（带降级处理）\n");
    printf("  4 - 查看当前回调ID\n");
    printf("  0 - 退出程序\n");
    printf("========================\n\n");
}

int main()
{
    printf("=== Network Boost Kit - 网络质量评估示例 ===\n");
    printf("起始版本: 5.1.0(18)\n");
    printf("系统能力: SystemCapability.Communication.NetworkBoost.Core\n");
    printf("所需权限: ohos.permission.GET_NETWORK_INFO\n\n");
    
    int choice = 0;
    
    while (true) {
        PrintUsage();
        printf("请输入选项: ");
        scanf("%d", &choice);
        
        switch (choice) {
            case 1:
                RegisterNetQualityCallback();
                break;
            case 2:
                UnregisterNetQualityCallback();
                break;
            case 3:
                RegisterWithFallback();
                break;
            case 4:
                printf("[INFO] 当前回调ID: %u\n", g_callbackId);
                if (g_callbackId == 0) {
                    printf("[INFO] 未注册回调\n");
                }
                break;
            case 0:
                printf("[INFO] 退出程序\n");
                if (g_callbackId != 0) {
                    printf("[INFO] 自动取消注册回调...\n");
                    UnregisterNetQualityCallback();
                }
                return 0;
            default:
                printf("[ERROR] 无效选项，请重新输入\n");
        }
        
        printf("\n");
    }
    
    return 0;
}