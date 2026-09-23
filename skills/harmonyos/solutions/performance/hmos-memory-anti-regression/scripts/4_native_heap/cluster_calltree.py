"""
调用栈聚类：对指定 SO 生成前缀树聚类树（JSON）

用法:
    python cluster_calltree.py --db <版本.db> --so <so_name> [--output <path>]

功能:
    1. 从 SQLite db 查询所有调用栈及其帧
    2. 筛选包含指定 SO 帧的调用栈
    3. 对筛选后的调用栈做前缀树聚类
    4. 输出 JSON 格式的聚类树

输出:
    <so_name>_tree.json — 聚类树（含 string_table + tree）
"""

import json
import re
import sqlite3
import argparse
import sys
from pathlib import Path
from collections import OrderedDict

# Force UTF-8 output (fixes Windows GBK garbled text)
sys.path.insert(0, str(Path(__file__).resolve().parent / "../_lib"))
from encoding import *  # noqa: E402

HOOK_SO_DEFAULT = ['libnative_hook']

# hook 机制注入的帧（非原始调用路径的一部分），始终排除
HOOK_NOISE_PATTERNS = [
    'libnative_hook.z.so',
]

# 基础设施库（真实调用路径的组成部分），不排除
# 排除这些帧会导致仅在这些库上不同的调用栈被错误合并，丢失聚类信息
# 保留列表供未来可选的 --exclude-infra 参数使用
INFRA_SO_PATTERNS = [
    'libuv.so',
    'libc++.so',
    'libc++_shared.so',
    'ld-musl-aarch64.so.1',
    'libc.so',
    'libm.so',
    'libdl.so',
    'libpthread.so',
]


def _is_excluded_so(so_name):
    """仅排除 hook 机制注入的噪声帧，不排除基础设施库的真实调用路径帧"""
    if not so_name:
        return True
    return any(p in so_name for p in HOOK_NOISE_PATTERNS)


def normalize_symbol(name):
    """Strip /proc/<PID>/root/ prefix so app-bundle SO names match across captures."""
    if not name:
        return name
    return re.sub(r'^/proc/\d+/root/', '', name)


# ── 从 DB 查询调用栈 + 帧 ─────────────────────────────────────
#
# DB 中的核心表（trace_streamer 转换 htrace 时生成，一定存在）：
#   native_hook          — 每条 AllocEvent/FreeEvent 的原始记录（addr, heap_size, callchain_id 等）
#   native_hook_frame    — 每条调用栈的帧序列（callchain_id, depth, symbol_id, file_id）
#   data_dict            — 字符串映射表（id → 函数名/文件路径），symbol_id/file_id 指向此表
#
# 可能存在的表（不一定有，取决于 trace_streamer 版本和前置流程）：
#   native_hook_statistic — 按 callchain_id 预聚合的统计表（apply_size, release_size 等）
#   native_hook_agg       — 帧聚合中间表（native_hook 库的统计流程生成，列名 result_json）
#
# 本函数的逻辑：
#   1. 确定帧聚合中间表（native_hook_agg / _cc_agg，都没有则现场构建 _cc_agg）
#   2. 判断用统计模式还是明细模式查存活内存
#   3. 通过 data_dict 将 symbol_id/file_id 还原为可读字符串
#   4. 只保留存活内存 > 0 的调用栈（已完全释放的不参与聚类）

def query_callchains(db_path):
    """查询 DB 中所有存活调用栈，返回 [{callchain_id, heap_size, frames, ...}]"""
    conn = sqlite3.connect(db_path)
    cur = conn.cursor()

    # 帧聚合中间表：将 native_hook_frame 按 callchain_id 聚合成 JSON 数组
    # 优先复用已有的 native_hook_agg（列名 result_json），其次复用 _cc_agg（列名 frames_json）
    # 都没有则现场构建 _cc_agg（首次运行耗时较长，后续复用）
    agg_table = None
    agg_col = None
    cur.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='native_hook_agg'")
    if cur.fetchone():
        agg_table = 'native_hook_agg'
        agg_col = 'result_json'
    else:
        cur.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='_cc_agg'")
        if cur.fetchone():
            agg_table = '_cc_agg'
            agg_col = 'frames_json'
    if agg_table is None:
        print('  构建帧聚合中间表（首次运行，耗时较长）...')
        cur.execute('''
            CREATE TABLE _cc_agg AS
            SELECT nhf.callchain_id,
                json_group_array(
                    json_object('depth', nhf.depth, 'symbol_id', nhf.symbol_id, 'file_id', nhf.file_id)
                ) AS frames_json
            FROM native_hook_frame nhf
            WHERE nhf.callchain_id > 0
            GROUP BY nhf.callchain_id
        ''')
        cur.execute("CREATE INDEX idx_cc_agg ON _cc_agg(callchain_id)")
        agg_table = '_cc_agg'
        agg_col = 'frames_json'
        print('  帧聚合中间表构建完成')

    # 统计模式 vs 明细模式：
    #   有 native_hook_statistic 且有数据 → 统计模式（直接查聚合表，快）
    #   否则 → 明细模式（从 native_hook 自行 GROUP BY 计算 heap_size，慢但结果等价）
    cur.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='native_hook_statistic'")
    has_statistic = False
    if cur.fetchone():
        cur.execute("SELECT count(*) FROM native_hook_statistic")
        has_statistic = cur.fetchone()[0] > 0

    if has_statistic:
        cur.execute(f'''
            SELECT nh.callchain_id,
                   MAX(nh.apply_size) - MAX(nh.release_size) AS heap_size,
                   MAX(nh.apply_count) AS apply_count,
                   MAX(nh.release_count) AS release_count,
                   agg.{agg_col}
            FROM native_hook_statistic nh
            LEFT JOIN {agg_table} agg ON nh.callchain_id = agg.callchain_id
            WHERE nh.type = 0
            GROUP BY nh.callchain_id
            HAVING heap_size > 0
        ''')
    else:
        # 明细模式：trace_streamer 已在 htrace→SQLite 转换时完成 alloc/free 配对，
        # AllocEvent 的 end_ts 字段记录释放时刻（未释放则为 NULL）。
        # 直接用 end_ts IS NULL 筛选存活分配，按 callchain_id 聚合。
        cur.execute(f'''
            SELECT nh.callchain_id,
                   SUM(nh.heap_size) AS heap_size,
                   COUNT(*) AS apply_count,
                   0 AS release_count,
                   agg.{agg_col}
            FROM native_hook nh
            LEFT JOIN {agg_table} agg ON nh.callchain_id = agg.callchain_id
            WHERE nh.event_type = 'AllocEvent'
              AND nh.callchain_id > 0
              AND nh.end_ts IS NULL
            GROUP BY nh.callchain_id
            HAVING heap_size > 0
        ''')

    # 先保存主查询结果
    rows = cur.fetchall()

    # 用单独 cursor 加载字符串表
    cur2 = conn.cursor()
    cur2.execute("SELECT id, data FROM data_dict")
    string_table = {r[0]: r[1] for r in cur2.fetchall()}

    callchains = []
    for row in rows:
        cc_id, heap_size, apply_count, release_count, frames_json = row
        if heap_size is None or heap_size <= 0:
            continue
        frames_raw = json.loads(frames_json) if frames_json else []
        frames = []
        for f in frames_raw:
            sym = string_table.get(f.get('symbol_id'), '') or ''
            filepath = string_table.get(f.get('file_id'), '') or ''
            frames.append({
                'depth': f.get('depth', 0),
                'symbol_data': sym,
                'file_data': filepath,
            })
        callchains.append({
            'callchain_id': cc_id,
            'heap_size': heap_size,
            'apply_count': apply_count or 0,
            'release_count': release_count or 0,
            'frames': frames,
        })

    conn.close()
    print(f'[OK] 从 {db_path} 查询到 {len(callchains)} 条存活调用栈')
    return callchains


# ── SO 帧筛选 ──────────────────────────────────────────────────

def filter_by_so(callchains, so_name):
    """筛选包含指定 SO 帧的调用栈（帧的 file_data 或 symbol_data 包含 so_name 即匹配）"""
    matched = []
    for cc in callchains:
        for frame in cc['frames']:
            file_data = frame.get('file_data', '')
            symbol_data = frame.get('symbol_data', '')
            if so_name in file_data or so_name in symbol_data:
                matched.append(cc)
                break
    return matched


# ── 聚类树构建 ─────────────────────────────────────────────────

class StringTable:
    """字符串去重编号表"""

    def __init__(self):
        self._table = OrderedDict()

    def intern(self, s):
        if s not in self._table:
            self._table[s] = len(self._table)
        return self._table[s]

    def dump(self):
        return list(self._table.keys())


class Node:
    """聚类树节点"""
    __slots__ = (
        'name', 'lib', 'value', 'apply_count', 'release_count',
        'children', 'is_leaf', 'callchain_id',
    )

    def __init__(self, name, lib):
        self.name = name
        self.lib = lib
        self.value = 0
        self.apply_count = 0
        self.release_count = 0
        self.children = {}
        self.is_leaf = False
        self.callchain_id = None


def insert_stack(root, st, frames, heap_size, apply_count, release_count, callchain_id):
    """逐帧插入聚类树（前缀树聚类核心）"""
    # 过滤掉 hook 库等排除 SO 的帧
    frames = [f for f in frames if not _is_excluded_so(f.get('file_data', ''))]
    node = root
    node.value += heap_size

    for frame in frames:
        sym = st.intern(normalize_symbol(frame.get('symbol_data', '')))
        lib = st.intern(normalize_symbol(frame.get('file_data', '')))

        child = node.children.get(sym)
        if child is None:
            child = Node(sym, lib)
            node.children[sym] = child

        child.value += heap_size
        child.apply_count += apply_count
        child.release_count += release_count
        node = child

    # 挂叶子节点，保留原始 callchain_id
    leaf_name = st.intern(f'meta:{callchain_id}')
    leaf = Node(leaf_name, st.intern(''))
    leaf.value = heap_size
    leaf.apply_count = apply_count
    leaf.release_count = release_count
    leaf.is_leaf = True
    leaf.callchain_id = callchain_id
    node.children[leaf_name] = leaf


def tree_to_json(node, st, threshold=0.0):
    """将聚类树转为可序列化的 dict（阈值剪枝）"""
    str_table = st.dump()

    def _convert(n):
        res = {
            'name': str_table[n.name],
            'value': n.value,
            'value_mb': round(n.value / 1048576, 2),
        }
        if n.apply_count:
            res['apply_count'] = n.apply_count
        if n.release_count:
            res['release_count'] = n.release_count
        if n.is_leaf:
            res['is_leaf'] = True
            if n.callchain_id is not None:
                res['callchain_id'] = n.callchain_id
        if n.children:
            visible = []
            for ch in n.children.values():
                if ch.is_leaf or ch.value > threshold:
                    visible.append(_convert(ch))
            if visible:
                res['children'] = visible
        return res

    return _convert(node)


def build_cluster_tree(callchains):
    """对调用栈列表构建聚类树，返回 (string_table, tree_dict)"""
    st = StringTable()
    root = Node(st.intern('root'), st.intern('root'))

    for cc in callchains:
        insert_stack(root, st, cc['frames'], cc['heap_size'],
                     cc['apply_count'], cc['release_count'], cc['callchain_id'])

    threshold = root.value * 0.00001  # 0.001% 剪枝
    tree = tree_to_json(root, st, threshold)
    return st.dump(), tree


# ── 主流程 ──────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description='调用栈聚类：对指定 SO 生成前缀树聚类树（JSON）')
    parser.add_argument('--db', required=True, help='SQLite db 路径')
    parser.add_argument('--so', required=True, help='目标 SO 名称（如 libentry.so）')
    parser.add_argument('--output', default='', help='输出文件路径（默认 db 同级目录下 <so_name>_tree.json）')
    args = parser.parse_args()

    db_path = Path(args.db)
    if not db_path.exists():
        print(f'错误: 数据库不存在: {db_path}')
        return

    print(f'分析数据库: {db_path}')
    callchains = query_callchains(str(db_path))

    matched = filter_by_so(callchains, args.so)
    if not matched:
        print(f'错误: SO "{args.so}" 无匹配调用栈')
        return

    print(f'[OK] 筛选到 {len(matched)} 条包含 {args.so} 的调用栈')

    str_table, tree = build_cluster_tree(matched)

    # 输出路径
    if args.output:
        out_path = Path(args.output)
    else:
        _dangerous = set('/\\<>:"|?*')
        safe_name = ''.join('_' if (c in _dangerous or ord(c) < 32) else c for c in args.so)
        out_path = db_path.parent / f'{safe_name}_tree.json'
    out_path.parent.mkdir(parents=True, exist_ok=True)

    out_path.write_text(
        json.dumps({'string_table': str_table, 'tree': tree}, indent=2, ensure_ascii=False),
        encoding='utf-8')
    print(f'[OK] {args.so}: 聚类树已保存 ({tree["value_mb"]}MB, {out_path})')


if __name__ == '__main__':
    main()