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
from collections import defaultdict

from typing import List, Dict

from log_manager.common.handler.format_unit_handler import FormatUnitHandler

low_priority_process = [
    'surfaceflinger',
    'composer@2.1-se', 'anco_service_br', 'render_service', 'composer_host', 'mhcserver',
    'CameraDaemon', 'hiaiserver', 'av_codec_servic', 'media_service', 'codec_host', 'allocator_host',
    'mediaswcodec', 'media_analysis_', 'app.hiai.vision', 'camera_service', 'large_model_eng',
    'video_processin', 'mhcserv', 'CameraDaemon', 'face_auth_host',
    'stat', 'sh', 'ping', 'mount', 'process_dump', 'pm', 'getprop', 'wm', 'cmd', 'cat', 'am'
]
priority_dict = {
    'surfaceflinger': ['surfaceflinger', 'composer@2.1-se', 'anco_service_br', 'render_service', 'composer_host',
                       'mhcserver', 'allocator_host'],
    'CameraDaemon1': ['CameraDaemon', 'face_auth_host', 'hiaiserver', 'allocator_host'],
    'av_codec_servic1': ['av_codec_servic', 'media_service', 'render_service', 'allocator_host'],
    'codec_host': ['codec_host', 'allocator_host'],
    'mediaswcodec': ['mediaswcodec', 'allocator_host'],
    'CameraDaemon2': ['CameraDaemon', 'camera_service', 'av_codec_servic', 'render_service', 'allocator_host'],
    'large_model_eng': ['large_model_eng', 'hiaiserver', 'allocator_host'],
    'av_codec_servic2': ['av_codec_servic', 'media_analysis_', 'app.hiai.vision', 'video_processin', 'mhcserver',
                         'hiaiserver', 'allocator_host'],
    'CameraDaemon3': ['CameraDaemon', 'face_auth_host', 'allocator_host'],
}
buf_type_set = {'xcomponent', 'pixelmap', 'web', 'last_buffer', 'hpae_memory_hdrhetero', 'asynscaling_hape_memory'}


class ProcessAshmemOverviewInfo:

    def __init__(self):
        self.process_name = ''
        self.virtual_size = 0
        self.physical_size = 0

    def build(self):
        pass


class ProcessAshmemDetailInfo:

    def __init__(self):
        self.process_name = ''
        self.pid = ''
        self.fd = ''
        self.cnode_index = ''
        self.applicant_pid = ''
        self.ashmem_name = ''
        self.handle_name = ''
        self.virtual_size = ''
        self.physical_size = ''
        self.magic = ''

    def build(self):
        pass


class DmaHeap:
    def __init__(self):
        self.unique_key = ''
        self.process_name = ''
        self.pid = ''
        self.fd = ''
        self.size = ''
        self.magic = ''
        self.buf_to_pid = ''
        self.buf_to_task_comm = ''
        self.buf_name = ''
        self.exp_name = ''
        self.buf_type = ''
        self.leak_type = ''
        self.can_reclaim = ''
        self.is_reclaim = ''

    def build(self):
        pass


class DmaHeapInfo:
    def __init__(self):
        self.dma_heap_list: List[DmaHeap] = []
        self.process_to_total_ion = dict()
        self.ion_to_process_dict: Dict[str, DmaHeap] = dict()
        self.magic_to_dma_heap: Dict[str, DmaHeap] = dict()
        self.magic_dma_dict: Dict[str, List[DmaHeap]] = defaultdict(list)
        self.pid_dma_dict: Dict[str, List[DmaHeap]] = defaultdict(list)
        self.pid_magic_dict: Dict[str, Dict[str, DmaHeap]] = defaultdict(dict)
        self.pid_to_dma_in_ddr = {}
        self.pid_to_dma_in_ufs = {}
        self.dma_in_ddr_type_dict = {}
        self.pid_names = {}
        self.magic_to_pids = {}

    @staticmethod
    def add_to_dict(dictionary, key, value):
        if key in dictionary:
            dictionary[key] += value
        else:
            dictionary[key] = value

    @staticmethod
    def dma_heap_index_build(context: List[str]):
        # 6.0维测
        if 'MM_DMABUF_INFO\n' in context or 'LOGGER_PROCESS_DMABUF_INFO\n' in context:
            dma_dict = {'Process': 'process_name',
                        'pid': 'pid',
                        'fd': 'fd',
                        'size_bytes': 'size',
                        'ino': 'magic',
                        'exp_pid': 'exp_pid',
                        'exp_task_comm': 'exp_task_comm',
                        'buf_name': 'buf_name',
                        'exp_name': 'exp_name',
                        'buf_type': 'buf_type',
                        'can_reclaim': 'can_reclaim',
                        'is_reclaim': 'is_reclaim',
                        'leak_type': 'leak_type'
                        }
            heap_patten = r'Process\s+pid\s+fd'
        # 5.x维测
        else:
            dma_dict = {
                'Process name': 'process_name',
                'Process ID': 'pid',
                'fd': 'fd',
                'size': 'size',
                'magic': 'magic',
                'buf->pid': 'buf_to_pid',
                'buf->task_comm': 'buf_to_task_comm'
            }
            heap_patten = r'Process\s+name\s+Process\s+ID\s+fd\s+size'

        start_index = 0
        for index, line in enumerate(context):
            if re.search(heap_patten, line):
                start_index = index
                break
        if start_index == 0:
            return {}, 0
        member_index_dict = dict()
        member_str_list = re.split(r'\t', context[start_index].strip())
        if len(member_str_list) < 3:
            member_str_list = re.split(r'\s{2,}', context[start_index].strip())
        for index, member_str in enumerate(member_str_list):
            if member_str.strip() in dma_dict.keys():
                member_index_dict[dma_dict[member_str.strip()]] = index
        return member_index_dict, start_index

    def build(self, context: List[str]):
        self.dma_build(context)
        self.ion_deduplicate()

    def dma_build(self, context: List[str]):
        member_index_dict, start_index = self.dma_heap_index_build(context)
        if len(member_index_dict) == 0:
            return
        self.dma_buf_list_build(start_index, member_index_dict, context)

    def dma_buf_list_build(self, start_index: int, member_index_dict: Dict[str, int], context: List[str]):
        for line in context[start_index + 1:]:
            if re.search(r'^\*{5,10}', line):
                break
            member_list = line.strip().split()
            if len(member_list) < len(member_index_dict):
                continue
            if 'Total' in member_list:
                continue
            dma_heap = DmaHeap()
            for member in member_index_dict.keys():
                index = member_index_dict[member]
                member_value = member_list[index].strip()
                if member == 'buf_type' and not member_value:
                    member_value = 'NULL'
                setattr(dma_heap, member, member_value)
                if member == 'leak_type' and member_value in ['hpae_memory_hdrhetero', 'asynscaling_hpae_memory']:
                    dma_heap.buf_type = member
            if dma_heap.pid not in self.pid_names:
                self.pid_names[dma_heap.pid] = dma_heap.process_name
            if dma_heap.magic not in self.magic_to_pids:
                self.magic_to_pids[dma_heap.magic] = [dma_heap.pid]
            else:
                if dma_heap.pid not in self.magic_to_pids[dma_heap.magic]:
                    self.magic_to_pids[dma_heap.magic].append(dma_heap.pid)
            if dma_heap.buf_type not in self.magic_to_dma_heap:
                self.magic_to_dma_heap[dma_heap.magic] = dma_heap
            self.dma_heap_list.append(dma_heap)
            self.magic_dma_dict[dma_heap.magic].append(dma_heap)
            self.pid_magic_dict[dma_heap.pid][dma_heap.magic] = dma_heap
            self.pid_dma_dict[dma_heap.pid].append(dma_heap)

    def dma_heap_list_build(self, context: List[str]):
        dma_buf_dict = {'Process name': 'process_name',
                        'Process ID': 'pid',
                        'fd': 'fd',
                        'size': 'size',
                        'magic': 'magic',
                        'buf->pid': 'buf_to_pid',
                        'buf->task_comm': 'buf_to_task_comm'}
        start_index = 0
        for index, line in enumerate(context):
            if re.search(r'Process\s+name\s+Process\s+ID\s+fd\s+size', line):
                start_index = index
                break
        if start_index == 0:
            return
        member_index_dict = dict()
        member_str_list = re.split(r'\s{2,}', context[start_index].strip())
        for index, member_str in enumerate(member_str_list):
            if member_str.strip() in dma_buf_dict.keys():
                member_index_dict[dma_buf_dict[member_str.strip()]] = index
        for line in context[start_index + 1:]:
            if re.search('^-{5,10}', line):
                break
            member_list = re.split(r'\s{2,}', line.strip())
            if 'Total' in member_list:
                continue
            if len(member_list) < len(member_index_dict):
                continue
            dma_heap = DmaHeap()
            for member in member_index_dict.keys():
                index = member_index_dict[member]
                setattr(dma_heap, member, member_list[index].strip())
            self.dma_heap_list.append(dma_heap)

    def ion_deduplicate(self):
        magic_to_owner = dict()
        for magic, heap in self.magic_to_dma_heap.items():
            pids = self.magic_to_pids[magic]
            if len(pids) == 1:
                magic_to_owner[magic] = pids
            process_name_list = [self.pid_names[pid] for pid in pids]
            # 查找进程列表中是否包含低优先级进程
            high_priority_process_list = [process_name for process_name in process_name_list if
                                          process_name not in low_priority_process]
            if high_priority_process_list:
                owners = [pid for pid in pids if self.pid_names[pid] in high_priority_process_list]
                magic_to_owner[magic] = owners
                continue
            # 按照进程优先级规则
            new_process_list = []
            for key, priority_list in priority_dict.items():
                process_list = [process_name for process_name in process_name_list if process_name not in priority_list]
                if not process_list:
                    continue
                # 找出优先级最高的进程
                new_process_list.append(process_list[0])
            # 去重后再次进行剔除
            new_process_list = list(set(new_process_list))
            for key, priority_list in priority_dict.items():
                if len(new_process_list) == 1:
                    break
                process_list = [process_name for process_name in priority_list if process_name in new_process_list]
                if len(process_list) <= 1:
                    continue
                # 找出优先级最高的进程
                del_process_list = [process_name for process_name in process_list if process_name != priority_list[0]]
                new_process_list = [process for process in new_process_list if process not in del_process_list]
            if len(new_process_list) == 1:
                if new_process_list[0] == 'hiaiserver':
                    if isinstance(heap.leak_type, int):
                        owners = [heap.leak_type]
                        magic_to_owner[magic] = owners
                        continue
            owners = [pid for pid in pids if self.pid_names[pid] in new_process_list]
            magic_to_owner[magic] = owners
        for magic, owners in magic_to_owner.items():
            size = int(self.magic_to_dma_heap[magic].size) if self.magic_to_dma_heap[magic].size else 0
            is_reclaim = self.magic_to_dma_heap[magic]
            buf_type = self.magic_to_dma_heap[magic].buf_type
            if buf_type not in buf_type_set:
                buf_type = 'NULL'
            for pid in owners:
                if is_reclaim == '1':
                    self.add_to_dict(self.pid_to_dma_in_ufs, pid, int(size / len(owners)))
                else:
                    self.add_to_dict(self.pid_to_dma_in_ddr, pid, int(size / len(owners)))
                    if pid not in self.dma_in_ddr_type_dict:
                        self.dma_in_ddr_type_dict[pid] = {}
                    self.add_to_dict(self.dma_in_ddr_type_dict[pid], buf_type, int(size / len(owners)))


class MemCheckBase(FormatUnitHandler):
    def __init__(self):
        super().__init__()
        self.process_ashmem_overview_list: List[ProcessAshmemOverviewInfo] = []
        self.process_ashmem_detail_list: List[ProcessAshmemDetailInfo] = []
        self.dma_heap_info = DmaHeapInfo()
        self.reason = ''

    def ashmem_build(self, context: List[str]):
        overview_start_index = 0
        overview_end_index = 0
        detail_start_index = 0
        detail_end_index = 0
        for index, line in enumerate(context):
            if re.search('Process_name Virtual_size Physical_size', line):
                overview_start_index = index + 1
            if re.search(r'Process_name\s+Process_ID\s+Fd\s+', line):
                overview_end_index = index - 1
                detail_start_index = index
            if re.search('^-+', line) and detail_start_index != 0 and index - detail_start_index > 2:
                detail_end_index = index - 1
                break
        self.process_ashmem_overview_list_build(context[overview_start_index:overview_end_index])
        self.process_ashmem_detail_list_build(context[detail_start_index:detail_end_index])

    def process_ashmem_overview_list_build(self, context: List[str]):
        overview_match = re.compile(r'Total\s+ashmem\s+of\s+\[(?P<process_name>[a-zA-Z0-9_.]+)]\s+virtual\s+size\s+is'
                                    r'\s+(?P<virtual_size>\d+),\s+physical\s+size\s+is\s+(?P<physical_size>\d+)')
        for line in context:
            match = overview_match.search(line)
            if match:
                process_ashmem_overview = ProcessAshmemOverviewInfo()
                process_ashmem_overview.process_name = match.group('process_name')
                process_ashmem_overview.process_name = self.truncate_process_name(process_ashmem_overview.process_name)
                process_ashmem_overview.virtual_size = match.group('virtual_size')
                process_ashmem_overview.physical_size = match.group('physical_size')
                self.process_ashmem_overview_list.append(process_ashmem_overview)

    def process_ashmem_detail_list_build(self, context: List[str]):
        ashmem_detail_member_dict = {'Process_name': 'process_name',
                                     'Process_ID': 'pid',
                                     'Fd': 'fd',
                                     'Cnode_idx': 'cnode_index',
                                     'Applicant_Pid': 'applicant_pid',
                                     'Ashmem_name': 'ashmem_name',
                                     'Virtual_size': 'virtual_size',
                                     'Physical_size': 'physical_size',
                                     'Magic': 'magic'
                                     }
        member_str_list = re.split(r'\s+', context[0].strip())
        member_index_dict = dict()
        for index, member_str in enumerate(member_str_list):
            if member_str in ashmem_detail_member_dict.keys():
                member_index_dict[ashmem_detail_member_dict[member_str]] = index
        for line in context[1:]:
            process_ashmem_detail = ProcessAshmemDetailInfo()
            member_list = re.split(r'\s+', line.strip())
            for member in member_index_dict.keys():
                index = member_index_dict[member]
                member_value = member_list[index]
                setattr(process_ashmem_detail, member, member_value)
            process_name = member_list[member_index_dict.get('process_name', 0)]
            process_name = self.truncate_process_name(process_name)
            process_ashmem_detail.process_name = process_name
            process_ashmem_detail.handle_name = re.sub(r'\d+$', 'xxx', process_ashmem_detail.ashmem_name)
            if len(member_list) > len(member_str_list):
                ashmem_name = member_list[member_index_dict.get('ashmem_name', 0)]
                process_ashmem_detail.handle_name = \
                    ashmem_name + " " + member_list[member_index_dict.get('ashmem_name', 0) + 1]
                process_ashmem_detail.virtual_size = \
                    member_list[member_index_dict.get('virtual_size', 0) + 1]
                process_ashmem_detail.physical_size = \
                    member_list[member_index_dict.get('physical_size', 0) + 1]
                process_ashmem_detail.magic = \
                    member_list[member_index_dict.get('magic', 0) + 1]
            self.process_ashmem_detail_list.append(process_ashmem_detail)

    def truncate_process_name(self, process_name: str) -> str:
        if process_name.startswith('com'):
            if len(process_name) >= 15:
                return process_name[-15:]
            else:
                return process_name
        else:
            if len(process_name) >= 15:
                return process_name[:15]
            else:
                return process_name

    def log_format(self):
        pass

    def log_split(self, context: List[str]):
        pass
