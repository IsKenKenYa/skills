#include "NetworkBoostKit/network_boost_handover.h"
#include <cstdio>
#include <cstring>

int32_t GetMultiPathQuotaStats()
{
    NetworkBoost_MultiPathQuota quota = { 0 };
    
    int32_t ret = HMS_NetworkBoost_GetMultiPathQuotaStats(&quota);
    
    if (ret == 0) {
        printf("获取多网配额信息成功\n");
        printf("已使用时长: %d秒\n", quota.used.duration);
        printf("已使用次数: %d次\n", quota.used.count);
        printf("剩余总时长: %d秒\n", quota.remaining.duration);
        printf("剩余总次数: %d次\n", quota.remaining.count);
    } else {
        printf("获取多网配额信息失败，错误码: %d\n", ret);
    }
    
    return ret;
}

int32_t QueryQuotaWithErrorHandling()
{
    NetworkBoost_MultiPathQuota quota = { 0 };
    
    if (!memset(&quota, 0, sizeof(NetworkBoost_MultiPathQuota))) {
        printf("结构体初始化失败\n");
        return -1;
    }
    
    int32_t ret = HMS_NetworkBoost_GetMultiPathQuotaStats(&quota);
    
    switch (ret) {
        case 0:
            printf("配额查询成功\n");
            printf("已使用次数: %d, 已使用时长: %d秒\n", 
                   quota.used.count, quota.used.duration);
            printf("剩余次数: %d, 剩余时长: %d秒\n", 
                   quota.remaining.count, quota.remaining.duration);
            break;
        case 201:
            printf("权限不足，请申请ohos.permission.LINKTURBO权限\n");
            return -1;
        case 1013600001:
            printf("内部错误，建议稍后重试\n");
            return -1;
        case 1013600002:
            printf("系统处理异常，IPC调用失败或服务启动失败\n");
            return -1;
        case 1013600041:
            printf("参数错误，请检查结构体初始化\n");
            return -1;
        default:
            printf("未知错误: %d\n", ret);
            return -1;
    }
    
    return ret;
}

void HandleQuotaExhausted()
{
    NetworkBoost_MultiPathQuota quota = { 0 };
    int32_t ret = HMS_NetworkBoost_GetMultiPathQuotaStats(&quota);
    
    if (ret == 0) {
        if (quota.remaining.count <= 0 || quota.remaining.duration <= 0) {
            printf("配额已耗尽，24小时后将重新分配\n");
            printf("建议：使用单网模式或等待配额刷新\n");
        } else if (quota.remaining.count <= 5 || quota.remaining.duration <= 60) {
            printf("配额即将耗尽，建议谨慎使用\n");
            printf("剩余次数: %d, 剩余时长: %d秒\n", 
                   quota.remaining.count, quota.remaining.duration);
        } else {
            printf("配额充足，可以发起多网请求\n");
            printf("剩余次数: %d, 剩余时长: %d秒\n", 
                   quota.remaining.count, quota.remaining.duration);
        }
    } else {
        printf("无法获取配额信息（错误码: %d），降级为单网模式\n", ret);
    }
}

bool CanRequestMultiPath()
{
    NetworkBoost_MultiPathQuota quota = { 0 };
    int32_t ret = HMS_NetworkBoost_GetMultiPathQuotaStats(&quota);
    
    if (ret != 0) {
        printf("配额查询失败，无法发起多网请求\n");
        return false;
    }
    
    if (quota.remaining.count <= 0) {
        printf("剩余次数不足（剩余: %d次）\n", quota.remaining.count);
        return false;
    }
    
    if (quota.remaining.duration <= 0) {
        printf("剩余时长不足（剩余: %d秒）\n", quota.remaining.duration);
        return false;
    }
    
    printf("配额充足，可以发起多网请求\n");
    printf("剩余次数: %d次, 剩余时长: %d秒\n", 
           quota.remaining.count, quota.remaining.duration);
    return true;
}

void PrintQuotaStatistics()
{
    NetworkBoost_MultiPathQuota quota = { 0 };
    int32_t ret = HMS_NetworkBoost_GetMultiPathQuotaStats(&quota);
    
    if (ret != 0) {
        printf("配额统计获取失败\n");
        return;
    }
    
    printf("========== 多网配额统计 ==========\n");
    printf("已使用配额:\n");
    printf("  - 次数: %d次\n", quota.used.count);
    printf("  - 时长: %d秒\n", quota.used.duration);
    printf("剩余配额:\n");
    printf("  - 次数: %d次\n", quota.remaining.count);
    printf("  - 时长: %d秒\n", quota.remaining.duration);
    if (quota.used.count + quota.remaining.count > 0) {
        float usedPercentage = (float)quota.used.count / 
                               (quota.used.count + quota.remaining.count) * 100;
        printf("使用率: %.2f%%\n", usedPercentage);
    }
    printf("==================================\n");
}

int main()
{
    printf("测试多网配额查询功能\n");
    
    printf("\n1. 基本配额查询:\n");
    GetMultiPathQuotaStats();
    
    printf("\n2. 带错误处理的配额查询:\n");
    QueryQuotaWithErrorHandling();
    
    printf("\n3. 配额耗尽处理:\n");
    HandleQuotaExhausted();
    
    printf("\n4. 判断是否可发起多网请求:\n");
    bool canRequest = CanRequestMultiPath();
    printf("判断结果: %s\n", canRequest ? "可以发起" : "不能发起");
    
    printf("\n5. 配额统计信息:\n");
    PrintQuotaStatistics();
    
    return 0;
}