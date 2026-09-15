#!/usr/bin/env python3
"""重新生成 .claude-plugin/plugin.json 与 README.md 的 skill 清单。

用途：每次上游同步/新增/删除 skill 后运行，保证清单与 skills/ 实际内容一致。
规则：扫描 skills/ 下全部 SKILL.md，跳过 metadata.internal: true 的内部子 skill。
用法：python3 scripts/gen_manifests.py
依赖：pip install pyyaml
"""
import os, re, json, yaml

def load_fm(path):
    text = open(path, encoding='utf-8').read()
    m = re.match(r'^---\n(.*?)\n---', text, re.DOTALL)
    if not m: return None
    return yaml.safe_load(m.group(1)) or {}

# ===== plugin.json =====
skills = []
for root, dirs, files in os.walk('skills'):
    if 'SKILL.md' not in files: continue
    fm = load_fm(os.path.join(root,'SKILL.md'))
    if not fm or fm.get('metadata',{}).get('internal') is True: continue
    if not fm.get('name') or not fm.get('description'): continue
    skills.append('./' + os.path.relpath(root,'.'))
skills.sort()
os.makedirs('.claude-plugin', exist_ok=True)
with open('.claude-plugin/plugin.json','w',encoding='utf-8') as f:
    json.dump({"name":"kenken-skills","skills":skills}, f, ensure_ascii=False, indent=2)
    f.write('\n')
print(f"plugin.json: {len(skills)} 个")

# ===== README =====
def walk(base):
    out=[]
    for root, dirs, files in os.walk(base):
        if 'SKILL.md' not in files: continue
        fm = load_fm(os.path.join(root,'SKILL.md'))
        if not fm or fm.get('metadata',{}).get('internal') is True: continue
        out.append((os.path.relpath(root,'.'), fm))
    out.sort()
    return out

def tbl(rows, with_invoke=False):
    if with_invoke:
        lines=["| skill | 调用方式 | 中文介绍 |","|-------|---------|---------|"]
    else:
        lines=["| skill | 中文介绍 |","|-------|---------|"]
    for rel,fm in rows:
        name=fm['name']; desc=str(fm['description']).replace('|','\\|').replace('\n',' ')
        link=f"./{rel}/SKILL.md"
        if with_invoke:
            kind='用户调用' if (fm.get('disable-model-invocation') or fm.get('user-invocable') is False) else '模型/用户调用'
            lines.append(f"| [`/{name}`]({link}) | {kind} | {desc} |")
        else:
            lines.append(f"| [`/{name}`]({link}) | {desc} |")
    return '\n'.join(lines)

mp_cats=[('engineering','Engineering — 工程类','日常编码工作'),
         ('productivity','Productivity — 生产力类','日常非编码工作流工具'),
         ('misc','Misc — 杂项','保留但较少使用'),
         ('in-progress','In-progress — 进行中','尚未定稿的草稿'),
         ('personal','Personal — 个人专用','与原作者个人设置绑定'),
         ('deprecated','Deprecated — 已废弃','原作者不再使用，保留供参考')]
mp_all=[]; mp_sec=[]
for cat,title,sub in mp_cats:
    d=f'skills/{cat}'
    if not os.path.isdir(d): continue
    rows=walk(d)
    if not rows: continue
    mp_all+=rows
    mp_sec.append(f"### {title}（{len(rows)}）\n\n*{sub}*\n")
    mp_sec.append(tbl(rows, with_invoke=True))

hmos_all=walk('skills/harmonyos')
hmos_by={}
for rel,fm in hmos_all: hmos_by.setdefault(rel.split('/')[2],[]).append((rel,fm))
hmos_zh={'design':'设计','solutions':'解决方案','development':'开发','test':'测试','tools':'DevEco 工具','tooling':'审查工具','launch-and-distribute':'发布与分发','rules':'规则','overview-and-learn':'学习资源'}
hmos_sec=[]
for cat in ['design','solutions','development','test','tools','tooling','launch-and-distribute','rules','overview-and-learn']:
    if cat not in hmos_by: continue
    rows=hmos_by[cat]
    hmos_sec.append(f"### {cat} — {hmos_zh.get(cat,cat)}（{len(rows)}）\n")
    hmos_sec.append(tbl(rows))

andr_all=walk('skills/android')
andr_by={}
for rel,fm in andr_all: andr_by.setdefault(rel.split('/')[2],[]).append((rel,fm))
andr_sec=[]
for cat in sorted(andr_by):
    rows=andr_by[cat]
    andr_sec.append(f"### {cat}（{len(rows)}）\n")
    andr_sec.append(tbl(rows))

meta_all=walk('skills/meta')
total=len(mp_all)+len(hmos_all)+len(andr_all)+len(meta_all)

readme=f"""# KenKenSkills

> 收集好用的 agent skills，把介绍（description）本地化为简体中文，统一管理、方便更新。

本仓库整合多个上游的优秀 agent skills：
- [mattpocock/skills](https://github.com/mattpocock/skills)（MIT）— 通用编码/生产力 skill，description 已译为中文
- [HarmonyOS_Skills/harmonyos-agent-skills](https://gitcode.com/HarmonyOS_Skills/harmonyos-agent-skills.git) — 鸿蒙开发 skill，上游原生中文，原样保留
- [android/skills](https://github.com/android/skills)（Apache 2.0）— Android 官方开发 skill，description 已译为中文

另有 2 个自建的安装指导 skill（`skills/meta/`），介绍各上游及官方 CLI 安装方式。`engineering/`、`in-progress/` 下另有若干自建/本土化 skill（code-review、research、wizard、loop-me 等）。

## 安装

```bash
npx skills@latest add IsKenKenYa/skills
```

然后挑选你想要的 skill 和目标编码代理即可。也可按上游官方方式安装，详见 [`/install-harmonyos-skills`](./skills/meta/install-harmonyos-skills/SKILL.md) 和 [`/install-android-skills`](./skills/meta/install-android-skills/SKILL.md)。

## 设计原则

- **专用 skill 按平台大类隔离**：通用 skill（mattpocock）放 `skills/<分类>/`；专用 skill 放 `skills/<平台>/`（`harmonyos/`、`android/`），平台内再按技术域细分，避免专用与通用混淆。
- **翻译对象仅限 description**：`name`、`disable-model-invocation`、`metadata`、`license` 等字段，以及全部正文指令，一律保持原样，不改变 skill 语义、不破坏 AI 执行完整性。
- **触发词保留原型**：`grill`/`tdd`/`triage`/`Jetpack Compose`/`CameraX`/`R8`/`Perfetto`/`ArkTS`/`ArkUI` 等关键词不翻译，必要时加中文括注。
- **HarmonyOS 原生中文不翻译**：上游 skill 本身就是中文（含中英混合），原样保留。
- **上游引用隔离**：原版上游仓库作为 git submodule 放在独立的 `upstream-refs` 分支，主分支保持干净——`npx skills add` 只会扫到中文化版本，不会被原版污染。
- **内部子 skill 用官方机制隔离**：部分 skill（如 HarmonyOS 的 `deveco-native-flow`）内含 `references/` 子 skill 作为父 skill 的知识库，带 `metadata.internal: true`，扫描时跳过但安装父 skill 时递归复制带走。

调用方式说明：标记为「用户调用」的 skill 只能用 `/skill名` 手动触发；「模型/用户调用」的 skill 还能被模型根据上下文语义自动触发。

## Skill 清单（共 {total} 个）

## 一、mattpocock 通用 Skills（{len(mp_all)} 个，description 已中文化）

""" + "\n\n".join(mp_sec) + f"""

## 二、HarmonyOS（鸿蒙）Skills（{len(hmos_all)} 个，上游原生中文原样保留）

""" + "\n\n".join(hmos_sec) + f"""

## 三、Android Skills（{len(andr_all)} 个，description 已中文化）

""" + "\n\n".join(andr_sec) + f"""

## 四、安装指导 Skills（{len(meta_all)} 个）

""" + tbl(meta_all) + f"""

## 致谢与许可

本仓库整合自以下上游，在此致谢并保留其版权声明：

- **mattpocock/skills**（MIT）— Copyright (c) 2026 Matt Pocock。MIT 许可证要求保留版权声明，全文见上游 [LICENSE](https://github.com/mattpocock/skills/blob/main/LICENSE)。
- **android/skills**（Apache License 2.0）— Copyright Google LLC。详见上游 [LICENSE](https://github.com/android/skills/blob/main/LICENSE.txt)。
- **HarmonyOS_Skills/harmonyos-agent-skills** — 遵循其原有许可声明。

本仓库整体采用 GPL v3 许可证（见 [LICENSE](./LICENSE)）。中文翻译与整合工作为 KenKenSkills 项目的贡献。

## 维护

如需同步上游更新或新增其他优秀 skills 仓库，请参见 [MAINTENANCE.md](./MAINTENANCE.md)。
"""
open('README.md','w',encoding='utf-8').write(readme)
print(f"README: {total} 个（mattpocock {len(mp_all)} / harmonyos {len(hmos_all)} / android {len(andr_all)} / meta {len(meta_all)}）")
