# Copyright (c) 2021-2026 Huawei Device Co., Ltd.
# SPDX-License-Identifier: Apache-2.0
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
import re
from typing import List

from log_manager.common.handler.format_unit_handler import FormatUnitHandler


class MemCheckMemInfo(FormatUnitHandler):

    def __init__(self):
        super().__init__()
        self.mem_total: int = 0
        self.mem_free: int = 0
        self.ion_total_use: int = 0
        self.gpu_total_used: int = 0

    def log_format(self):
        re_str_dict = {
            "mem_total": r"MemTotal:\s+(\d+)",
            "mem_free": r"MemFree:\s+(\d+)",
            "ion_total_use": r"IonTotalUsed:\s+(\d+)",
        }
        for line in self.sub_context:
            for key, re_str in re_str_dict.items():
                match = re.search(re_str, line)
                if match:
                    value = match.group(1)
                    setattr(self, key, int(value))
                    del re_str_dict[key]
                    break

    def log_split(self, context: List[str]):
        start_index = 0
        end_index = 0
        for index, line in enumerate(context):
            if "LOGGER_MEMCHECK_MEMINFO" in line:
                start_index = index + 1
            if re.search(r'\*+', line) and start_index != 0:
                end_index = index - 1
                break
        if end_index == 0:
            return
        self.sub_context = context[start_index:end_index]
        del context[:end_index]
