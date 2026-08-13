#include "napi/native_api.h"
#include "json/json.h"
#include "hilog/log.h"
#include "hiappevent/hiappevent.h"
#include "hiappevent/hiappevent_event.h"

#undef LOG_TAG
#define LOG_TAG "ScrollJankWatcher"

static HiAppEvent_Watcher *scrollJankWatcherR = nullptr;

static void OnReceive(const char *domain, const struct HiAppEvent_AppEventGroup *appEventGroups, uint32_t groupLen)
{
    for (int i = 0; i < groupLen; ++i) {
        for (int j = 0; j < appEventGroups[i].infoLen; ++j) {
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.WatcherType=OnReceive");
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.domain=%{public}s", appEventGroups[i].appEventInfos[j].domain);
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.name=%{public}s", appEventGroups[i].appEventInfos[j].name);
            
            if (strcmp(appEventGroups[i].appEventInfos[j].domain, DOMAIN_OS) != 0 || 
                strcmp(appEventGroups[i].appEventInfos[j].name, EVENT_SCROLL_JANK) != 0) {
                continue;
            }
            
            Json::Value params;
            Json::Reader reader(Json::Features::strictMode());
            Json::FastWriter writer;
            
            if (reader.parse(appEventGroups[i].appEventInfos[j].params, params)) {
                OH_LOG_INFO(LogType::LOG_APP, "time=%{public}lld", params["time"].asInt64());
                OH_LOG_INFO(LogType::LOG_APP, "bundle_name=%{public}s", params["bundle_name"].asString().c_str());
                OH_LOG_INFO(LogType::LOG_APP, "total_app_frames=%{public}d", params["total_app_frames"].asInt());
                OH_LOG_INFO(LogType::LOG_APP, "total_app_missed_frames=%{public}d", params["total_app_missed_frames"].asInt());
                OH_LOG_INFO(LogType::LOG_APP, "max_app_frametime=%{public}d", params["max_app_frametime"].asInt());
                OH_LOG_INFO(LogType::LOG_APP, "max_app_seq_frames=%{public}d", params["max_app_seq_frames"].asInt());
            }
        }
    }
}

static napi_value RegisterWatcherReceive(napi_env env, napi_callback_info info)
{
    scrollJankWatcherR = OH_HiAppEvent_CreateWatcher("ScrollJankWatcherR");
    if (scrollJankWatcherR == nullptr) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to create watcher");
        return {};
    }
    
    const char *names[] = {EVENT_SCROLL_JANK};
    int result = OH_HiAppEvent_SetAppEventFilter(scrollJankWatcherR, DOMAIN_OS, 0, names, 1);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to set filter: %{public}d", result);
        OH_HiAppEvent_DestroyWatcher(scrollJankWatcherR);
        scrollJankWatcherR = nullptr;
        return {};
    }
    
    result = OH_HiAppEvent_SetWatcherOnReceive(scrollJankWatcherR, OnReceive);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to set callback: %{public}d", result);
        OH_HiAppEvent_DestroyWatcher(scrollJankWatcherR);
        scrollJankWatcherR = nullptr;
        return {};
    }
    
    result = OH_HiAppEvent_AddWatcher(scrollJankWatcherR);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to add watcher: %{public}d", result);
        OH_HiAppEvent_DestroyWatcher(scrollJankWatcherR);
        scrollJankWatcherR = nullptr;
        return {};
    }
    
    OH_LOG_INFO(LogType::LOG_APP, "Watcher registered successfully");
    return {};
}

static napi_value Init(napi_env env, napi_value exports)
{
    napi_property_descriptor desc[] = {
        { "registerWatcherReceive", nullptr, RegisterWatcherReceive, nullptr, nullptr, nullptr, napi_default, nullptr },
    };
    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    return exports;
}