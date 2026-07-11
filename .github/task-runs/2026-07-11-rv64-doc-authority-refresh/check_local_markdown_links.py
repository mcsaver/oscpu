#!/usr/bin/env python3
"""Check local targets in Markdown files hand-authored by this task."""

from __future__ import annotations

import pathlib
import re
import subprocess
import sys
import urllib.parse


REPO = pathlib.Path(__file__).resolve().parents[3]
LINK_RE = re.compile(r"!?\[[^\]]*\]\(([^)]+)\)")
SKIP_PREFIXES = ("http://", "https://", "mailto:", "data:", "javascript:")
TASK_RUN_PREFIX = ".github/task-runs/2026-07-11-rv64-doc-authority-refresh/"
NEW_CURRENT_SNAPSHOT = "npc/rv64/design/arch/rtl-ground-truth-2026-07-11.md"


def git_paths(*args: str) -> set[str]:
    output = subprocess.check_output(
        ["git", *args], cwd=REPO, text=True, encoding="utf-8"
    )
    return {line.strip() for line in output.splitlines() if line.strip()}


def markdown_paths() -> list[pathlib.Path]:
    tracked = git_paths("diff", "--name-only", "--diff-filter=ACMRTUXB", "--", "*.md")
    untracked = {
        path
        for path in git_paths("ls-files", "--others", "--exclude-standard", "--", "*.md")
        if path == NEW_CURRENT_SNAPSHOT or path.startswith(TASK_RUN_PREFIX)
    }
    return sorted(REPO / path for path in tracked | untracked)


def target_path(source: pathlib.Path, raw: str) -> pathlib.Path | None:
    target = raw.strip()
    if target.startswith("<") and ">" in target:
        target = target[1 : target.index(">")]
    else:
        target = target.split(maxsplit=1)[0]
    target = urllib.parse.unquote(target).split("#", 1)[0]
    if not target or target.startswith(SKIP_PREFIXES):
        return None
    if target.startswith("/"):
        return pathlib.Path(target)
    return (source.parent / target).resolve()


def main() -> int:
    failures: list[str] = []
    checked_links = 0
    files = markdown_paths()
    for source in files:
        text = source.read_text(encoding="utf-8")
        for line_no, line in enumerate(text.splitlines(), start=1):
            for match in LINK_RE.finditer(line):
                resolved = target_path(source, match.group(1))
                if resolved is None:
                    continue
                checked_links += 1
                if not resolved.exists():
                    failures.append(
                        f"{source.relative_to(REPO)}:{line_no}: missing {match.group(1)}"
                    )
    print(f"checked_files={len(files)} checked_local_links={checked_links}")
    if failures:
        print("\n".join(failures))
        return 1
    print("PASS local Markdown targets exist")
    return 0


if __name__ == "__main__":
    sys.exit(main())
