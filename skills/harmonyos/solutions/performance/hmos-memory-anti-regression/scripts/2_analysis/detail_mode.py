
import sys
from pathlib import Path
import logging
from collections import defaultdict

import pandas as pd

sys.path.insert(0, str(Path(__file__).resolve().parent / "../_lib"))
from encoding import *  # noqa: E402  # Force UTF-8 output (fixes Windows GBK garbled text)
sys.path.insert(0, str(Path(__file__).resolve().parent / "."))
sys.path.insert(0, str(Path(__file__).resolve().parent / "so_field"))
from tracedbs import query_native_hook
from callchain import OptimizedCallChain
from config import TraceType, config_data

logger = logging.getLogger(__name__)

EVENT_TYPE_MAPPING = {
    TraceType.NATIVE_HEAP: "AllocEvent",
    TraceType.ARKTS_HEAP: "ARKTS_HEAP_Alloc_Event",
    TraceType.GPU_CL: "GPU_CL_Alloc_Event",
    TraceType.GPU_VK: "GPU_VK_Alloc_Event",
    TraceType.GPU_GLES: "GPU_GLES_Alloc_Event",
    TraceType.ASHMEM: "ASHMEM_Alloc_Event",
    TraceType.DMA: "ION_Alloc_Event"
}
EVENT_TYPE_MAPPING_REVERSE = {v: k.name for k, v in EVENT_TYPE_MAPPING.items()}


# noinspection DuplicatedCode
def add_detail_data(_types: list[TraceType]):
    callchains = OptimizedCallChain()
    types_value = [_t.value for _t in _types]
    print(f"添加 {types_value} 数据")
    startts = config_data["startts"]
    endts = config_data["endts"]

    event_types = [EVENT_TYPE_MAPPING[_t] for _t in _types]
    detail_data_list = query_native_hook(config_data["htrace_dir"], event_types=event_types, startts=startts, endts=endts)
    for data in detail_data_list:
        data["type"] = EVENT_TYPE_MAPPING_REVERSE[data["event_type"]]
    df = pd.DataFrame(detail_data_list)
    df.fillna("N/A", inplace=True)

    aggregated_data = defaultdict(lambda: {
        "pid": None,
        "process_name": None,
        "callchain_id": None,
        "ts": None,
        "type": None,
        "heap_size": 0,
        "frames": None,
        "apply_count": 0,
        "release_count": 0,
        "apply_size": 0,
        "release_size": 0,
        "filed": None
    })
    for item in detail_data_list:
        callchain_id = item["callchain_id"]
        aggregated_data[callchain_id]["heap_size"] += item["heap_size"]
        if aggregated_data[callchain_id]["frames"] is None:
            aggregated_data[callchain_id]["frames"] = item["frames"]
            aggregated_data[callchain_id]["type"] = item["type"]
            aggregated_data[callchain_id]["pid"] = item["pid"]
            aggregated_data[callchain_id]["process_name"] = item["process_name"]
            aggregated_data[callchain_id]["callchain_id"] = item["callchain_id"]
        if aggregated_data[callchain_id]["ts"] is None:
            aggregated_data[callchain_id]["ts"] = item["ts"]
        else:
            aggregated_data[callchain_id]["ts"] = max(aggregated_data[callchain_id]["ts"], item["ts"])
        aggregated_data[callchain_id]["apply_count"] += 1

    for item in aggregated_data.values():
        callchains.append(item)
    return callchains