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
import argparse

import dill

from common.enum.common_enum import NativeMemoryType
from tools.common_tools import print_table_info


def get_jemalloc_leak_info(native_leak):
    def bin_parser():
        bin_list = native_leak.mem_check_detial_info.bin_list
        large_list = native_leak.mem_check_detial_info.large_list
        total_allocated = native_leak.mem_check_detial_info.total_allocated
        total_list = bin_list + large_list
        # 按照分配大小从大到小排序
        sorted_total_list = sorted(total_list, key=lambda x: x.allocated, reverse=True)
        if not sorted_total_list:
            return ''
        sorted_total_list = sorted_total_list[:3] if len(sorted_total_list) > 3 else sorted_total_list
        allocated = 0
        nmd_info_list = [('size(B)', 'allocated(B)', 'rate')]
        for info in sorted_total_list:
            allocated += info.allocated
            rate = '{:.2f}%'.format(float(info.allocated) * 100 / total_allocated)
            nmd_info_list.append((info.size, info.allocated, rate))
            native_leak.nmd_set.add(info.size)
        return print_table_info(nmd_info_list)

    def top3_nmd_use_parser():
        nmd_map2 = native_leak.mem_check_nmd_info.nmd_map2
        sorted_allocated = sorted(nmd_map2.items(), key=lambda x: x[1], reverse=True)
        nmd_list = sorted_allocated[:3] if len(sorted_allocated) > 3 else sorted_allocated
        total_allocated_size = sum(nmd_map2.values())
        nmd_info_list = [('size(B)', 'allocated(B)', 'rate')]
        for size, allocated in nmd_list:
            rate = '{:.2f}%'.format((float(allocated) / total_allocated_size) * 100)
            nmd_info_list.append((size, allocated, rate))
            native_leak.nmd_set.add(size)
        return print_table_info(nmd_info_list)

    def top3_nmd_change_parser():
        nmd_map1 = native_leak.mem_check_nmd_info.nmd_map1
        nmd_map2 = native_leak.mem_check_nmd_info.nmd_map2
        if len(nmd_map1) == 0 or len(nmd_map2) == 0:
            return ''
        allocated_change = {}
        for size, allocated in nmd_map2.items():
            allocated_change[size] = allocated - nmd_map1.get(size, 0)
        sort_allocated_change = sorted(allocated_change.items(), key=lambda x: x[1], reverse=True)
        nmd_list = sort_allocated_change[:3] if len(sort_allocated_change) > 3 else sort_allocated_change
        nmd_info_list = [('size(B)', 'allocated(B)', '增长内存')]
        for size, change in nmd_list:
            nmd_info_list.append((f'{size}', f'{nmd_map2[size]}', f'{change}'))
            native_leak.nmd_set.add(size)
        return print_table_info(nmd_info_list)

    top3_nmd_use = top3_nmd_use_parser()
    top3_nmd_change = top3_nmd_change_parser()
    bin_str = bin_parser()
    nmd_info = ''
    if top3_nmd_use:
        nmd_info += f'堆内存快照占用Top3 size：\n' + top3_nmd_use
    if top3_nmd_change:
        nmd_info += f'堆内存增长Top3 size：\n' + top3_nmd_change
    if bin_str:
        nmd_info += '堆内存快照占用Top3 size：\n' + bin_str
    return nmd_info


def get_ashmem_leak_info(native_leak):
    pss = native_leak.rate_dict[NativeMemoryType.ASHMEM_LEAK]['pss']
    ashmem_list = native_leak.rate_dict[NativeMemoryType.ASHMEM_LEAK]['swap_list']
    sorted_ashmem_list = sorted(ashmem_list, key=lambda x: x.pss + x.swap_pss, reverse=True)
    info = ''
    total_rate = 0
    for swap_info in sorted_ashmem_list:
        rate = ((swap_info.pss + swap_info.swap_pss) / pss)
        handle_name = swap_info.name.split(':')[-1]
        info += f'ashmem内存块：{handle_name} 占比：{rate :.2f}%\n'
        total_rate += rate
        if total_rate >= 0.5:
            break
    return info


def get_arkts_leak_info():
    return '抓取heapsnapshot进一步分析arkts内存占用'


def get_anon_leak_info():
    return ''


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument("-p", "--path", required=True, help="文件路径")
    parser.add_argument("-t", "--type", required=True, help="泄漏类型")
    args = parser.parse_args()
    native_path = args.path.replace('.txt', '.pkl')
    sample_path = native_path.replace('smaps', 'sample')
    with open(native_path, 'rb') as f:
        native_obj_ = dill.load(f)
    with open(sample_path, 'rb') as f:
        sample_obj_ = dill.load(f)
    if args.type == 'jemalloc':
        info_ = get_jemalloc_leak_info(native_obj_)
    elif args.type == 'ashmem':
        info_ = get_ashmem_leak_info(native_obj_)
    elif args.type == 'arkts':
        info_ = get_arkts_leak_info()
    elif args.type == 'anon':
        info_ = get_anon_leak_info()
    else:
        info_ = '未知的泄漏类型'
    with open(native_path, 'wb') as f:
        dill.dump(native_obj_, f)
    print(info_)
