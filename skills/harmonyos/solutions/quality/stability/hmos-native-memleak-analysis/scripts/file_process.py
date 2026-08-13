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
import os
import re

from tools.common_tools import print_table_info

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument("-p", "--path", required=True, help="文件路径")
    args = parser.parse_args()
    native_dict = {}
    kernel_dict = {}
    pid_process = {}
    regex_dict = {'sample': re.compile(r'memleak-native-(?P<process_name>[0-9a-zA-Z_.]+)-(?P<pid>\d+)-sample.txt'),
                  'smaps': re.compile(r'memleak-native-(?P<process_name>[0-9a-zA-Z_.]+)-(?P<pid>\d+)-smaps.txt'),
                  'profile': re.compile(r'memleak-native-(?P<process_name>[0-9a-zA-Z_.]+)-(?P<pid>\d+)-\d+.txt')
                  }
    kernel_res = re.compile(r'memleak-kernel-(?P<process_name>[0-9a-zA-Z_.]+)-0-\d+.txt')
    for root, _, files in os.walk(args.path):
        for file_name in files:
            file_path = os.path.join(root, file_name)
            for key, regex in regex_dict.items():
                match = re.search(regex, file_name)
                if not match:
                    continue
                pid = match.group('pid')
                pid_process[pid] = match.group('process_name')
                if pid in native_dict:
                    native_dict[pid] = {key: file_path}
                else:
                    native_dict[pid][key] = file_path
                break
            kernel_match = kernel_res.search(file_name)
            if kernel_match:
                kernel_dict[kernel_match.group('process_name')] = file_path
    sorted_native_list = sorted(native_dict.items(), key=lambda x: len(x[1]), reverse=True)
    list_ = [('文件类型', '文件路径')]
    if sorted_native_list and len(sorted_native_list[0][1]) >= 2:
        native_file_dict = sorted_native_list[0][1]
        kernel_file = kernel_dict.get(pid_process.get(sorted_native_list[0][0]), None)
        list_.append(('sample', native_file_dict.get('sample', None)))
        list_.append(('smaps', native_file_dict.get('smaps', None)))
        list_.append(('profile', native_file_dict.get('profile', None)))
        list_.append(('kernel', kernel_file))
    elif not sorted_native_list and kernel_dict:
        list_.append(('kernel', list(kernel_dict.values())[0]))
    print(print_table_info(list_))
