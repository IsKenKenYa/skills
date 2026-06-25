#!/usr/bin/env python3
"""Compare local mattpocock mirrored skills with github.com/mattpocock/skills."""

from __future__ import annotations

import shutil
import subprocess
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parent
LOCAL_PREFIXES = ("engineering", "productivity", "misc", "personal", "in-progress", "deprecated")
REMOTE = "https://github.com/mattpocock/skills.git"


def skill_set(base: Path) -> set[str]:
    result: set[str] = set()
    for path in base.rglob("SKILL.md"):
        result.add(path.parent.relative_to(base).as_posix())
    return result


def main() -> int:
    local = set()
    for prefix in LOCAL_PREFIXES:
        root = ROOT / "skills" / prefix
        if root.exists():
            local.update(f"{prefix}/{item}" for item in skill_set(root))

    with tempfile.TemporaryDirectory() as tmp:
        checkout = Path(tmp) / "skills"
        subprocess.run(["git", "clone", "--depth", "1", REMOTE, str(checkout)], check=True, stdout=subprocess.DEVNULL)
        remote = skill_set(checkout / "skills")

    missing = sorted(remote - local)
    extra = sorted(local - remote)

    print(f"local={len(local)} remote={len(remote)}")
    if missing:
        print("\nMissing locally:")
        for item in missing:
            print(f"  {item}")
    if extra:
        print("\nExtra locally:")
        for item in extra:
            print(f"  {item}")
    if not missing and not extra:
        print("mattpocock mirror is in sync")
        return 0
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
