#include "napi/native_api.h"
#include "json/json.h"
#include "hilog/log.h"
#include "hiappevent/hiappevent.h"
#include "hiappevent/hiappevent_event.h"

#undef LOG_TAG
#define LOG_TAG "ScrollJankWatcher"

static HiAppEvent_Watcher *scrollJankWatcherT = nullptr;

static void OnTake(const char *const *events, uint32_t eventLen)
{
    Json::Reader reader(Json::Features::strictMode());
    
    for (int i = 0; i < eventLen; ++i) {
        Json::Value eventInfo;
        if (reader.parse(events[i], eventInfo)) {
            auto domain = eventInfo["domain_"].asString();
            auto name = eventInfo["name_"].asString();
            
            if (domain == DOMAIN_OS && name == EVENT_SCROLL_JANK) {
                OH_LOG_INFO(LogType::LOG_APP, "WatcherType=OnTrigger");
                OH_LOG_INFO(LogType::LOG_APP, "time=%{public}lld", eventInfo["time"].asInt64());
                OH_LOG_INFO(LogType::LOG_APP, "bundle_name=%{public}s", eventInfo["bundle_name"].asString().c_str());
                OH_LOG_INFO(LogType::LOG_APP, "total_app_frames=%{public}d", eventInfo["total_app_frames"].asInt());
                OH_LOG_INFO(LogType::LOG_APP, "total_app_missed_frames=%{public}d", eventInfo["total_app_missed_frames"].asInt());
                OH_LOG_INFO(LogType::LOG_APP, "max_app_frametime=%{public}d", eventInfo["max_app_frametime"].asInt());
                OH_LOG_INFO(LogType::LOG_APP, "max_app_seq_frames=%{public}d", eventInfo["max_app_seq_frames"].asInt());
            }
        }
    }
}

static void OnTrigger(int row, int size)
{
    OH_HiAppEvent_TakeWatcherData(scrollJankWatcherT, row, OnTake);
}

static napi_value RegisterWatcherTrigger(napi_env env, napi_callback_info info)
{
    scrollJankWatcherT = OH_HiAppEvent_CreateWatcher("ScrollJankWatcherT");
    if (scrollJankWatcherT == nullptr) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to create watcher");
        return {};
    }
    
    const char *names[] = {EVENT_SCROLL_JANK};
    int result = OH_HiAppEvent_SetAppEventFilter(scrollJankWatcherT, DOMAIN_OS, 0, names, 1);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to set filter: %{public}d", result);
        OH_HiAppEvent_DestroyWatcher(scrollJankWatcherT);
        scrollJankWatcherT = nullptr;
        return {};
    }
    
    result = OH_HiAppEvent_SetWatcherOnTrigger(scrollJankWatcherT, OnTrigger);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to set trigger callback: %{public}d", result);
        OH_HiAppEvent_DestroyWatcher(scrollJankWatcherT);
        scrollJankWatcherT = nullptr;
        return {};
    }
    
    result = OH_HiAppEvent_SetTriggerCondition(scrollJankWatcherT, 1, 0, 0);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to set condition: %{public}d", result);
        OH_HiAppEvent_DestroyWatcher(scrollJankWatcherT);
        scrollJankWatcherT = nullptr;
        return {};
    }
    
    result = OH_HiAppEvent_AddWatcher(scrollJankWatcherT);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to add watcher: %{public}d", result);
        OH_HiAppEvent_DestroyWatcher(scrollJankWatcherT);
        scrollJankWatcherT = nullptr;
        return {};
    }
    
    OH_LOG_INFO(LogType::LOG_APP, "Trigger watcher registered successfully");
    return {};
}

static napi_value Init(napi_env env, napi_value exports)
{
    napi_property_descriptor desc[] = {
        { "registerWatcherTrigger", nullptr, RegisterWatcherTrigger, nullptr, nullptr, nullptr, napi_default, nullptr },
    };
    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    return exports;
}