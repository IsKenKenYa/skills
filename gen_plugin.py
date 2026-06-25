#!/usr/bin/env python3
"""Generate .claude-plugin/plugin.json from public skills."""

from __future__ import annotations

import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parent
SKILLS_ROOT = ROOT / "skills"
PLUGIN_PATH = ROOT / ".claude-plugin" / "plugin.json"


def frontmatter(path: Path) -> str:
    text = path.read_text(encoding="utf-8")
    match = re.match(r"^---\n(.*?)\n---\n", text, re.DOTALL)
    return match.group(1) if match else ""


def is_internal(path: Path) -> bool:
    fm = frontmatter(path)
    in_metadata = False
    for line in fm.splitlines():
        if line.startswith((" ", "\t")):
            if in_metadata and line.strip() == "internal: true":
                return True
            continue
        in_metadata = line.strip() == "metadata:"
    return False


def main() -> None:
    skills = []
    for skill_md in sorted(SKILLS_ROOT.rglob("SKILL.md")):
        if is_internal(skill_md):
            continue
        skills.append("./" + skill_md.parent.relative_to(ROOT).as_posix())

    PLUGIN_PATH.parent.mkdir(parents=True, exist_ok=True)
    PLUGIN_PATH.write_text(
        json.dumps({"name": "kenken-skills", "skills": skills}, ensure_ascii=False, indent=2)
        + "\n",
        encoding="utf-8",
    )
    print(f"Wrote {PLUGIN_PATH.relative_to(ROOT)} with {len(skills)} skills")


if __name__ == "__main__":
    main()
