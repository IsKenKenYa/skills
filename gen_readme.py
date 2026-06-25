#!/usr/bin/env python3
"""Regenerate the README skill catalog while preserving intro and license text."""

from __future__ import annotations

import re
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parent
README = ROOT / "README.md"
SKILLS_ROOT = ROOT / "skills"


@dataclass(frozen=True)
class Group:
    title: str
    subtitle: str | None
    paths: tuple[str, ...]
    invocation: bool = False


MATTPocock_GROUPS = [
    Group("Engineering — 工程类", "日常编码工作", ("engineering",), True),
    Group("Productivity — 生产力类", "日常非编码工作流工具", ("productivity",), True),
    Group("Misc — 杂项", "保留但较少使用", ("misc",), True),
    Group("Personal — 个人专用", "与原作者个人设置绑定", ("personal",), True),
    Group("In-progress — 进行中", "尚未定稿的草稿", ("in-progress",), True),
    Group("Deprecated — 已废弃", "原作者不再使用，保留供参考", ("deprecated",), True),
]

HARMONY_GROUPS = [
    Group("design — 设计", None, ("harmonyos/design",)),
    Group("solutions — 解决方案", None, ("harmonyos/solutions",)),
    Group("development — 开发", None, ("harmonyos/development",)),
    Group("test — 测试", None, ("harmonyos/test",)),
    Group("tools — DevEco 工具", None, ("harmonyos/tools",)),
    Group("tooling — 审查工具", None, ("harmonyos/tooling",)),
]

ANDROID_GROUPS = [Group("android", None, ("android",))]
META_GROUPS = [Group("", None, ("meta",))]


def frontmatter(path: Path) -> dict[str, str | bool]:
    text = path.read_text(encoding="utf-8")
    match = re.match(r"^---\n(.*?)\n---\n", text, re.DOTALL)
    if not match:
        return {}

    result: dict[str, str | bool] = {}
    lines = match.group(1).splitlines()
    in_metadata = False
    index = 0
    while index < len(lines):
        line = lines[index]
        if not line.strip():
            index += 1
            continue
        if re.match(r"^\S[^:]*:\s*$", line):
            in_metadata = line.startswith("metadata:")
            index += 1
            continue
        if in_metadata and re.match(r"^\s+internal:\s*true\s*$", line):
            result["internal"] = True
            index += 1
            continue
        if line.startswith((" ", "\t")):
            index += 1
            continue
        key, sep, value = line.partition(":")
        if sep:
            key = key.strip()
            value = value.strip()
            if value in {">", "|", ">-", "|-"}:
                block: list[str] = []
                index += 1
                while index < len(lines) and (not lines[index].strip() or lines[index].startswith((" ", "\t"))):
                    if lines[index].strip():
                        block.append(lines[index].strip())
                    index += 1
                result[key] = " ".join(block)
                continue
            result[key] = value.strip("\"'")
        index += 1
    return result


def public_skill_paths() -> list[Path]:
    paths = []
    for skill_md in SKILLS_ROOT.rglob("SKILL.md"):
        if frontmatter(skill_md).get("internal") is True:
            continue
        paths.append(skill_md)
    return sorted(paths)


def in_group(path: Path, group: Group) -> bool:
    rel = path.parent.relative_to(SKILLS_ROOT).as_posix()
    return any(rel == prefix or rel.startswith(prefix + "/") for prefix in group.paths)


def render_group(group: Group, skill_paths: list[Path], include_heading: bool = True) -> list[str]:
    rows = [p for p in skill_paths if in_group(p, group)]
    lines: list[str] = []
    if include_heading:
        lines.append(f"### {group.title}（{len(rows)}）")
        lines.append("")
    if group.subtitle:
        lines.append(f"*{group.subtitle}*")
        lines.append("")
    lines.append("| skill | 调用方式 | 中文介绍 |" if group.invocation else "| skill | 中文介绍 |")
    lines.append("|-------|---------|---------|" if group.invocation else "|-------|---------|")
    for path in rows:
        fm = frontmatter(path)
        rel = path.relative_to(ROOT).as_posix()
        name = str(fm.get("name", path.parent.name))
        description = str(fm.get("description", "")).replace("\n", " ").strip()
        if group.invocation:
            invocation = "用户调用" if fm.get("disable-model-invocation") == "true" else "模型/用户调用"
            lines.append(f"| [`/{name}`](./{rel}) | {invocation} | {description} |")
        else:
            lines.append(f"| [`/{name}`](./{rel}) | {description} |")
    lines.append("")
    return lines


def render_catalog() -> str:
    skills = public_skill_paths()
    matt_paths = [p for p in skills if p.relative_to(SKILLS_ROOT).parts[0] in {"engineering", "productivity", "misc", "personal", "in-progress", "deprecated"}]
    harmony_paths = [p for p in skills if p.relative_to(SKILLS_ROOT).parts[0] == "harmonyos"]
    android_paths = [p for p in skills if p.relative_to(SKILLS_ROOT).parts[0] == "android"]
    meta_paths = [p for p in skills if p.relative_to(SKILLS_ROOT).parts[0] == "meta"]

    lines = [
        f"## Skill 清单（共 {len(skills)} 个）",
        "",
        f"## 一、mattpocock 通用 Skills（{len(matt_paths)} 个，description 已中文化）",
        "",
    ]
    for group in MATTPocock_GROUPS:
        lines.extend(render_group(group, matt_paths))
    lines.extend([f"## 二、HarmonyOS（鸿蒙）Skills（{len(harmony_paths)} 个，上游原生中文原样保留）", ""])
    for group in HARMONY_GROUPS:
        lines.extend(render_group(group, harmony_paths))
    lines.extend([f"## 三、Android Skills（{len(android_paths)} 个，description 已中文化）", ""])
    for group in ANDROID_GROUPS:
        lines.extend(render_group(group, android_paths))
    lines.extend([f"## 四、安装指导 Skills（{len(meta_paths)} 个）", ""])
    for group in META_GROUPS:
        lines.extend(render_group(group, meta_paths, include_heading=False))
    return "\n".join(lines).rstrip() + "\n"


def main() -> None:
    text = README.read_text(encoding="utf-8")
    start = text.index("## Skill 清单")
    end = text.index("## 致谢与许可")
    new_text = text[:start] + render_catalog() + "\n" + text[end:]
    README.write_text(new_text, encoding="utf-8")
    print("Regenerated README skill catalog")


if __name__ == "__main__":
    main()
