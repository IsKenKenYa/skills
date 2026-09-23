#!/usr/bin/env python3
"""对比报告 md → html：保留 <iframe>(火焰图)，浏览器可渲染。

iframe 自适应高度（无滚动条），通过同源 onload 读取 contentDocument.scrollHeight，
只设一次不循环，避免 postMessage 正反馈。

用法:
    python scripts/2_analysis/report_md_to_html.py <报告.md> [-o <报告.html>]

依赖: pip install markdown
"""
import argparse
import os
import re
import sys

try:
    import markdown
except ImportError:
    print("缺少 markdown 库，请安装: python -m pip install markdown", file=sys.stderr)
    sys.exit(1)

CSS = """\
body{max-width:1180px;margin:24px auto;padding:0 16px;
font-family:system-ui,-apple-system,'Segoe UI',Roboto,sans-serif;
line-height:1.65;color:#222}
table{border-collapse:collapse;margin:1em 0;width:100%;table-layout:auto}
th,td{border:1px solid #ccc;padding:6px 10px;white-space:nowrap}
th{background:#f5f5f5}
blockquote{color:#555;border-left:4px solid #ddd;margin:0;padding-left:12px}
iframe{border:none;width:100%;display:block}
code{background:#f4f4f4;padding:1px 4px;border-radius:3px;font-size:0.9em}
pre{background:#f6f6f6;padding:12px;overflow-x:auto;border-radius:4px}
h1,h2,h3{margin-top:1.2em;margin-bottom:0.4em}
img{max-width:100%;height:auto}
"""


def _postprocess(html: str) -> str:
    """修复 markdown 生成 HTML 的问题。"""
    html = re.sub(r'<p>\s*</p>', '', html)
    html = re.sub(r'(<br\s*/?>\s*){2,}', '<br>', html)
    # 移除 iframe 内联 style 和 scrolling="no"
    html = re.sub(r'(<iframe\b[^>]*?)\s+style="[^"]*"', r'\1', html)
    html = html.replace('scrolling="no"', '')
    return html


def _inject_step4_flames(html: str, flame_dir_abs: str, flame_dir_src: str) -> str:
    """扫 flame_dir_abs 下 *_compare_flame.html, 把步骤4前后对比火焰图 iframe 注入到 html。

    flame_dir_abs: 用于文件系统扫描的绝对路径
    flame_dir_src: 用于 iframe src 的路径 (相对路径, 便于移植)
    策略: 每个 SO 的 iframe 注入到该 SO 归因文本之后（匹配 SO 名称出现的段落）。
    无匹配位置时兜底集中追加。
    """
    # 收集已生成的火焰图 SO 列表
    so_with_flame = set()
    if flame_dir_abs and os.path.isdir(flame_dir_abs):
        for fn in os.listdir(flame_dir_abs):
            m = re.match(r'(.+)_compare_flame\.html$', fn)
            if m:
                so_with_flame.add(m.group(1))
    if not so_with_flame:
        return html

    # 逐个 SO 注入链接: 在该 SO 的归因块最后插入火焰图链接（1.2 Native Heap 小节内）
    injected = set()
    iframe_tpl = (
        f'<p><a href="{flame_dir_src}/{{so}}_compare_flame.html" target="_blank">'
        f'📊 查看 {{so}} 前后对比火焰图</a></p>'
    )

    # 限定搜索范围: 1.2 Native Heap 标题之后、1.3 SO_SIZE 标题之前
    # 避免匹配到 Top10/smaps/DMA 等后续章节中的 SO 名
    nh_start = re.search(r'<h[234][^>]*>[^<]*Native\s*Heap[^<]*</h[234]>', html, re.IGNORECASE)
    smaps_start = re.search(r'<h[234][^>]*>[^<]*SO_SIZE[^<]*</h[234]>', html, re.IGNORECASE)
    if nh_start and smaps_start:
        search_region = html[nh_start.end():smaps_start.start()]
        search_offset = nh_start.end()
    else:
        search_region = html
        search_offset = 0

    for so in sorted(so_with_flame, key=len, reverse=True):
        so_esc = re.escape(so)
        # 该 SO 的归因块范围：从含 SO 名的标题行（<li> 或 <p><b>）开始，到下一个编号 SO 标题行结束
        # 在该范围的最后一个 </p>（或 </li>）之后插入 iframe
        so_title_pat = re.compile(
            rf'<(?:li|p)[^>]*>{so_esc}',
            re.IGNORECASE,
        )
        title_match = so_title_pat.search(search_region)
        if not title_match:
            continue
        block_start = title_match.end()
        # 找下一个 SO 标题行（<li>so_name 格式，编号在 <ol start="N"> 上）
        next_title_pat = re.compile(
            r'<li[^>]*>(?:<b>)?[a-zA-Z_lib]',
            re.IGNORECASE,
        )
        next_match = next_title_pat.search(search_region, block_start)
        block_end = next_match.start() if next_match else len(search_region)
        # 在 block_end 之前找最后一个 </p> 或 </li>
        block_text = search_region[block_start:block_end]
        last_p_close = max(block_text.rfind('</p>'), block_text.rfind('</li>'))
        if last_p_close >= 0:
            close_tag = '</p>' if last_p_close == block_text.rfind('</p>') else '</li>'
            abs_pos = search_offset + block_start + last_p_close + len(close_tag)
            iframe = '\n' + iframe_tpl.format(so=so)
            html = html[:abs_pos] + iframe + html[abs_pos:]
            injected.add(so)
            # 更新搜索区域（iframe 插入后偏移变化）
            inserted_len = len(iframe)
            if smaps_start:
                smaps_start_new = re.search(r'<h[234][^>]*>[^<]*SO_SIZE[^<]*</h[234]>', html, re.IGNORECASE)
                if smaps_start_new:
                    search_region = html[nh_start.end():smaps_start_new.start()]
                    search_offset = nh_start.end()

    # 未注入的 SO 兜底集中追加
    remaining = so_with_flame - injected
    if remaining:
        parts = ['<h3>步骤 4 Native Heap 前后对比火焰图</h3>']
        for so in sorted(remaining):
            parts.append(f'<p><b>{so}</b></p>')
            parts.append(f'<p><a href="{flame_dir_src}/{so}_compare_flame.html" target="_blank">📊 查看 {so} 前后对比火焰图</a></p>')
        block = "\n".join(parts)

        # 替换占位符
        placeholder = "（深度分析结果将在步骤 3/4/5 执行后填充）"
        pat = re.compile(rf'<p>\s*{re.escape(placeholder)}\s*</p>')
        if pat.search(html):
            return pat.sub(lambda m: block, html, count=1)

        # 占位符不存在: 在「步骤 4」标题后追加
        step4_pat = re.compile(r'(<h\d[^>]*>[^<]*步骤\s*4[^<]*</h\d>)', re.IGNORECASE)
        m = step4_pat.search(html)
        if m:
            return html[:m.end()] + "\n" + block + "\n" + html[m.end():]

        # 兜底: 匹配含 "Native Heap" 的标题(h2/h3/h4均可)
        nh_pat = re.compile(r'(<h[234][^>]*>[^<]*Native\s*Heap[^<]*</h[234]>)', re.IGNORECASE)
        m = nh_pat.search(html)
        if m:
            return html[:m.end()] + "\n" + block + "\n" + html[m.end():]

        # 兜底: 匹配含 "深度分析" 的一级标题(h2)后追加
        deep_pat = re.compile(r'(<h2[^>]*>[^<]*深度分析[^<]*</h2>)', re.IGNORECASE)
        m = deep_pat.search(html)
        if m:
            return html[:m.end()] + "\n" + block + "\n" + html[m.end():]

    return html


def convert(md_path: str, out_path: str | None = None,
            flame_dir: str = "flame_compare") -> str:
    """md → html，保留 raw HTML(含 iframe)。返回输出路径。

    扫 flame_dir 下 *_compare_flame.html, 把步骤4前后对比火焰图 iframe
    注入到 html 占位处或步骤4标题后（md 源文件不含 iframe, 仅 html 含）。
    """
    md_text = open(md_path, encoding="utf-8").read()
    body = markdown.markdown(
        md_text,
        extensions=["tables", "fenced_code", "md_in_html", "sane_lists", "attr_list"],
    )
    body = _postprocess(body)
    # flame_dir 相对于 md 文件所在目录解析
    md_dir = os.path.dirname(os.path.abspath(md_path))
    flame_dir_abs = flame_dir if os.path.isabs(flame_dir) else os.path.join(md_dir, flame_dir)
    body = _inject_step4_flames(body, flame_dir_abs, flame_dir)

    title = os.path.basename(md_path)
    # 自适应高度：同源读取 contentDocument.scrollHeight，只设一次
    # postMessage 作退路（file:// 跨域时），每 iframe 只接受一次
    html = (
        "<!DOCTYPE html><html lang='zh-CN'><head><meta charset='utf-8'>"
        f"<title>{title}</title><style>{CSS}</style></head>"
        f"<body>{body}"
        "<script>(function(){"
        "function fit(iframe){"
        "try{var h=iframe.contentDocument.documentElement.scrollHeight;"
        "if(h>0){iframe.style.height=h+'px';return true;}}catch(e){}"
        "return false;}"
        "var done={};"
        "window.addEventListener('message',function(e){"
        "if(e.data&&e.data.height){"
        "document.querySelectorAll('iframe').forEach(function(f){"
        "if(f.contentWindow===e.source&&!done[f.src]){"
        "done[f.src]=1;f.style.height=e.data.height+'px';"
        "}});}});"
        "window.addEventListener('load',function(){"
        "document.querySelectorAll('iframe').forEach(function(f){"
        "setTimeout(function(){if(!fit(f)){f.src=f.src;}},500);"
        "});});"
        "})();</script>"
        "</body></html>"
    )
    if out_path is None:
        out_path = os.path.splitext(md_path)[0] + ".html"
    open(out_path, "w", encoding="utf-8").write(html)
    print(f"{md_path} -> {out_path} ({len(html)} bytes)")
    return out_path


def main():
    ap = argparse.ArgumentParser(description="对比报告 md→html (保留 iframe; 扫 flame_dir 注入步骤4火焰图)")
    ap.add_argument("md", help="报告 .md 路径")
    ap.add_argument("-o", "--output", help="输出 .html 路径 (默认同名 .html)")
    ap.add_argument("--flame-dir", default="flame_compare", help="火焰图 HTML 目录 (相对报告, 默认 flame_compare)")
    args = ap.parse_args()
    convert(args.md, args.output, args.flame_dir)


if __name__ == "__main__":
    main()