#!/usr/bin/env python3
"""检查 RV64 Core 学习讲义是否覆盖全部 vsrc 文件、链接和 WaveDrom。

这个脚本只读工作区。它把“每个文件都讲到”变成 fail-closed 的机械门：
只要新增或漏写一个 vsrc 文件、写坏一个本地链接，或者 WaveDrom 不是合法
JSON，或者重复电平会被 WaveDrom 画成伪毛刺，进程就返回非零。
"""

from __future__ import annotations

import json
import re
import sys
from collections import Counter
from pathlib import Path


SCRIPT = Path(__file__).resolve()
STUDY_ROOT = SCRIPT.parents[1]
REPO_ROOT = SCRIPT.parents[4]
VSRC_ROOT = REPO_ROOT / "npc" / "rv64" / "vsrc"
ATLAS_PATH = STUDY_ROOT / "11-逐文件源码地图.md"

WAVEDROM_RE = re.compile(r"```wavedrom\s*\n(.*?)\n```", re.DOTALL)
LINK_RE = re.compile(r"!?\[[^\]]*\]\(([^)]+)\)")
ATLAS_ROW_RE = re.compile(
    r"^\|\s*`(?P<path>npc/rv64/vsrc/[^`]+)`\s*"
    r"\|\s*(?P<status>[^|]+?)\s*"
    r"\|\s*(?P<description>.*?)\s*\|\s*$"
)
ALLOWED_ATLAS_STATUSES = {"Top", "Sim", "Check", "Catalog", "Header", "Doc/Build"}
EXPECTED_ATLAS_STATUS_COUNTS = {
    "Top": 124,
    "Sim": 6,
    "Check": 3,
    "Catalog": 3,
    "Header": 9,
    "Doc/Build": 5,
}


def markdown_files() -> list[Path]:
    return sorted(STUDY_ROOT.rglob("*.md"))


def vsrc_files() -> list[Path]:
    return sorted(path for path in VSRC_ROOT.rglob("*") if path.is_file())


def normalize_binary_holds(wave: str) -> str:
    """把重复的显式 0/1 改为 WaveDrom 的保持符 ``.``。"""

    normalized: list[str] = []
    active_level: str | None = None
    for token in wave:
        if token in {"0", "1"}:
            if token == active_level:
                normalized.append(".")
            else:
                normalized.append(token)
                active_level = token
        else:
            normalized.append(token)
            if token != ".":
                active_level = None
    return "".join(normalized)


def iter_wave_signals(items: object):
    """递归遍历 WaveDrom signal/group 数组中的 signal object。"""

    if not isinstance(items, list):
        return
    for item in items:
        if isinstance(item, dict):
            yield item
        elif isinstance(item, list):
            yield from iter_wave_signals(item)


def check_file_atlas() -> tuple[int, int, list[str]]:
    """验证逐文件地图是一对一、带合法身份和非空解释的结构化表。"""

    text = ATLAS_PATH.read_text(encoding="utf-8")
    begin = "<!-- FILE_ATLAS_BEGIN -->"
    end = "<!-- FILE_ATLAS_END -->"
    errors: list[str] = []
    if text.count(begin) != 1 or text.count(end) != 1:
        return 0, 0, ["FILE_ATLAS_BEGIN/END 必须各出现一次"]
    body = text.split(begin, 1)[1].split(end, 1)[0]

    rows: list[tuple[str, str, str, int]] = []
    for line_number, line in enumerate(body.splitlines(), start=1):
        match = ATLAS_ROW_RE.match(line)
        if match:
            rows.append(
                (
                    match.group("path"),
                    match.group("status").strip(),
                    match.group("description").strip(),
                    line_number,
                )
            )
        elif "`npc/rv64/vsrc/" in line:
            errors.append(f"atlas line {line_number}: 路径行不是合法三列表格")

    source_paths = {
        path.relative_to(REPO_ROOT).as_posix() for path in vsrc_files()
    }
    row_counts = Counter(path for path, _, _, _ in rows)
    covered = len(source_paths.intersection(row_counts))

    for path in sorted(source_paths):
        count = row_counts[path]
        if count == 0:
            errors.append(f"{path}: 逐文件地图缺失")
        elif count != 1:
            errors.append(f"{path}: 逐文件地图出现 {count} 次，要求恰好一次")
    for path in sorted(set(row_counts).difference(source_paths)):
        errors.append(f"{path}: 逐文件地图引用了不存在的 vsrc 文件")

    status_counts: Counter[str] = Counter()
    for path, status, description, line_number in rows:
        if status not in ALLOWED_ATLAS_STATUSES:
            errors.append(
                f"atlas line {line_number} {path}: 非法身份标签 {status!r}"
            )
        else:
            status_counts[status] += 1
        if len(description) < 12 or description in {"-", "TODO", "TBD"}:
            errors.append(
                f"atlas line {line_number} {path}: 教学解释为空或过短"
            )

    if dict(status_counts) != EXPECTED_ATLAS_STATUS_COUNTS:
        errors.append(
            "身份计数不匹配："
            f"actual={dict(status_counts)} "
            f"expected={EXPECTED_ATLAS_STATUS_COUNTS}"
        )
    return len(rows), covered, errors


def check_wavedrom(markdowns: list[Path]) -> tuple[int, list[str]]:
    count = 0
    errors: list[str] = []
    for path in markdowns:
        text = path.read_text(encoding="utf-8")
        for index, block in enumerate(WAVEDROM_RE.findall(text), start=1):
            count += 1
            try:
                diagram = json.loads(block)
            except json.JSONDecodeError as exc:
                errors.append(
                    f"{path.relative_to(REPO_ROOT)} WaveDrom#{index}: JSON {exc}"
                )
                continue
            if not isinstance(diagram, dict):
                errors.append(
                    f"{path.relative_to(REPO_ROOT)} WaveDrom#{index}: 顶层必须是 object"
                )
            elif "signal" not in diagram and "edge" not in diagram:
                errors.append(
                    f"{path.relative_to(REPO_ROOT)} WaveDrom#{index}: "
                    "缺少 signal/edge"
                )
            else:
                for signal in iter_wave_signals(diagram.get("signal", [])):
                    wave = signal.get("wave")
                    if not isinstance(wave, str):
                        continue
                    normalized = normalize_binary_holds(wave)
                    if normalized != wave:
                        errors.append(
                            f"{path.relative_to(REPO_ROOT)} WaveDrom#{index} "
                            f"{signal.get('name', '<unnamed>')}: "
                            f"重复电平会形成伪毛刺 {wave!r}，应写为 {normalized!r}"
                        )
    return count, errors


def clean_link_target(raw_target: str) -> str:
    target = raw_target.strip()
    if target.startswith("<") and target.endswith(">"):
        target = target[1:-1]
    return target.split("#", 1)[0]


def check_links(markdowns: list[Path]) -> list[str]:
    errors: list[str] = []
    for path in markdowns:
        text = path.read_text(encoding="utf-8")
        for raw_target in LINK_RE.findall(text):
            target = clean_link_target(raw_target)
            if (
                not target
                or target.startswith(("http://", "https://", "mailto:", "#"))
            ):
                continue
            resolved = (
                REPO_ROOT / target.lstrip("/")
                if target.startswith("/")
                else path.parent / target
            ).resolve()
            if not resolved.exists():
                errors.append(
                    f"{path.relative_to(REPO_ROOT)} -> {raw_target}: 目标不存在"
                )
    return errors


def main() -> int:
    markdowns = markdown_files()
    sources = vsrc_files()
    atlas_rows, covered, atlas_errors = check_file_atlas()
    wave_count, wave_errors = check_wavedrom(markdowns)
    link_errors = check_links(markdowns)

    print(f"[study-audit] markdown_files={len(markdowns)}")
    print(f"[study-audit] vsrc_files={len(sources)}")
    print(f"[study-audit] atlas_rows={atlas_rows}")
    print(f"[study-audit] covered_vsrc_files={covered}")
    print(f"[study-audit] wavedrom_blocks={wave_count}")

    for item in atlas_errors:
        print(f"[study-audit][BAD_ATLAS] {item}")
    for item in wave_errors:
        print(f"[study-audit][BAD_WAVEDROM] {item}")
    for item in link_errors:
        print(f"[study-audit][BAD_LINK] {item}")

    if atlas_errors or wave_errors or link_errors:
        print("[study-audit] FAIL")
        return 1
    if wave_count == 0:
        print("[study-audit][BAD_WAVEDROM] 没有发现 WaveDrom 时序图")
        print("[study-audit] FAIL")
        return 1

    print("[study-audit] PASS")
    return 0


if __name__ == "__main__":
    sys.exit(main())
