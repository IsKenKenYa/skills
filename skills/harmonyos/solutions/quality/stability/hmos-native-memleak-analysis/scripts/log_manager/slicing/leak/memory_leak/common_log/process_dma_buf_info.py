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


class ProcessDmaBuf(FormatUnitHandler):

    def __init__(self):
        super().__init__()
        self.process_dma_buf_info_list: List[ProcessDmaBufInfo] = []

    def log_format(self):
        dma_buf_dict = {'process': 'process_name',
                        'pid': 'pid',
                        'fd': 'fd',
                        'size_bytes': 'size_bytes',
                        'ino': 'ino',
                        'exp_pid': 'exp_pid',
                        'exp_task_comm': 'exp_task_comm',
                        'buf_name': 'buf_name',
                        'exp_name': 'exp_name',
                        'buf_type': 'buf_type'
                        }
        member_str_list = re.split(r'Size\s+Rss\s+Pss\s+Clean]\s+', self.sub_context[0].strip())
        member_index_dict = dict()
        for index, member_str in enumerate(member_str_list):
            if member_str in dma_buf_dict.keys():
                member_index_dict[dma_buf_dict[member_str]] = index
        for line in self.sub_context[1:]:
            member_list = line.strip().split()
            if 'Total' in member_list:
                continue
            for member in member_index_dict.keys():
                process_dma_buf_info = ProcessDmaBufInfo()
                index = member_index_dict[member]
                exec(f'process_dma_buf_info.{member} = {member_list[index]}')
                self.process_dma_buf_info_list.append(process_dma_buf_info)

    def log_split(self, context: List[str]):
        start_index = 0
        end_index = 0
        for index, line in enumerate(context):
            if "LOGGER_PROCESS_DMABUF_INFO" in line:
                start_index = index
            if re.search(r'\*+', line):
                end_index = index
        if start_index >= end_index:
            return
        self.sub_context = context[start_index:end_index]


class ProcessDmaBufInfo:

    def __init__(self):
        self.process_name = ''
        self.pid = ''
        self.fd = ''
        self.size_bytes = ''
        self.ino = ''
        self.exp_pid = ''
        self.exp_task_comm = ''
        self.buf_name = ''
        self.exp_name = ''
        self.can_reclaim = False
        self.is_reclaim = False
        self.buf_type = ''

    def build(self):
        pass
