#!/usr/bin/env python3

from __future__ import annotations

import argparse
import hashlib
import json
import pathlib
import re
import subprocess
import sys
from typing import Any


SCHEMA = "npc-rv64-a3-checker-replay/v2"
EXPECTED_SOURCE_STATUS = (
    "FAIL rc=1 stage=systemd-strict-guest "
    "evidence_complete=0 cleanup_rc=0"
)
EXPECTED_CHECKER_PATH = (
    "/usr/local/sbin/ysyx-npc-systemd-strict-check"
)
EXPECTED_LEGACY_REGEX = (
    "kernel panic|oops|BUG:|bad trap|illegal instruction|segfault|"
    "I/O error|Buffer I/O error|EXT4-fs error"
)
BOUNDED_BUG_TOKEN = "(^|[^[:alnum:]_])BUG:"
DEBUG_WITNESS = "[    0.000000] printk: debug: ignoring loglevel setting."
REAL_BUG_FIXTURE = "[   12.300000] BUG: unable to handle page fault"


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def sha256_file(path: pathlib.Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8", errors="replace")


def parse_key_values(path: pathlib.Path) -> dict[str, str]:
    values: dict[str, str] = {}
    for raw_line in read_text(path).splitlines():
        if "=" not in raw_line:
            continue
        key, value = raw_line.split("=", 1)
        if re.fullmatch(r"[A-Za-z0-9_]+", key):
            values[key] = value
    return values


def grep_probe(regex: str, text: str) -> tuple[int, list[str]]:
    result = subprocess.run(
        ["grep", "-i", "-E", regex],
        input=text,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    require(
        result.returncode in (0, 1),
        f"grep query failed rc={result.returncode}: {result.stderr}",
    )
    return result.returncode, result.stdout.splitlines()


def extract_embedded_checker(rootfs: pathlib.Path) -> tuple[bytes, str]:
    result = subprocess.run(
        ["debugfs", "-R", f"cat {EXPECTED_CHECKER_PATH}", str(rootfs)],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    stderr = result.stderr.decode("utf-8", errors="replace")
    require(result.returncode == 0, f"debugfs extraction failed: {stderr}")
    require(result.stdout.startswith(b"#!/bin/sh\n"), "embedded checker missing")
    return result.stdout, stderr.strip()


def embedded_regex(checker_bytes: bytes) -> str:
    checker_text = checker_bytes.decode("utf-8", errors="strict")
    matches = re.findall(r"grep -i -E '([^']+)'", checker_text)
    require(len(matches) == 1, f"embedded regex count={len(matches)}")
    return matches[0]


def run_base_replay(
    base_script: pathlib.Path,
    base_output: pathlib.Path,
) -> tuple[dict[str, Any], str]:
    result = subprocess.run(
        [sys.executable, str(base_script), "--out", str(base_output)],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        check=False,
    )
    require(
        result.returncode == 0,
        f"base replay failed rc={result.returncode}: {result.stderr}",
    )
    require(
        "[V10F-A3-CHECKER-REPLAY]" in result.stdout,
        "base replay PASS marker missing",
    )
    return json.loads(read_text(base_output)), result.stdout.strip()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--out", required=True, type=pathlib.Path)
    parser.add_argument("--base-out", required=True, type=pathlib.Path)
    parser.add_argument("--embedded-out", required=True, type=pathlib.Path)
    args = parser.parse_args()

    repo_root = pathlib.Path(__file__).resolve().parents[3]
    task_root = (
        repo_root
        / ".github/task-runs/2026-07-27-rv64-v10e-current-design-system-recert"
    )
    a3 = task_root / "rootfs-c1b531-systemd-strict-6b-a3"
    runtime_root = (
        repo_root
        / ".github/runtime-artifacts/rv64-systemd-strict"
        / "rootfs-c1b531-systemd-strict-6b-a3"
    )
    rootfs = runtime_root / "rootfs.ext4"
    status_path = task_root / "rootfs-c1b531-systemd-strict-6b-a3.status"
    binding_path = a3 / "binding.txt"
    rootfs_binding_path = a3 / "guest/rootfs-binding.txt"
    console_path = a3 / "guest/console.log"
    current_checker = repo_root / "Linux/scripts/npc-systemd-strict-check.sh"
    base_script = (
        repo_root
        / ".github/task-runs/2026-07-28-rv64-v10f-a3-checker-replay"
        / "replay-a3-checker.py"
    )

    for required_path in (
        rootfs,
        status_path,
        binding_path,
        rootfs_binding_path,
        console_path,
        current_checker,
        base_script,
    ):
        require(required_path.is_file(), f"missing input: {required_path}")

    source_status = read_text(status_path).strip()
    require(
        source_status == EXPECTED_SOURCE_STATUS,
        "A3 original FAIL status changed",
    )

    binding = parse_key_values(binding_path)
    rootfs_binding = parse_key_values(rootfs_binding_path)
    expected_checker_sha = binding.get("strict_checker_sha256", "")
    require(
        re.fullmatch(r"[0-9a-f]{64}", expected_checker_sha) is not None,
        "A3 strict_checker_sha256 missing",
    )
    require(
        rootfs_binding.get("rootfs_run_image") == str(rootfs),
        "A3 run-image path binding mismatch",
    )
    require(
        rootfs_binding.get("rootfs_template_sha256_pre")
        == rootfs_binding.get("rootfs_run_image_sha256_pre"),
        "A3 template/run-image pre-hash mismatch",
    )

    checker_bytes, debugfs_stderr = extract_embedded_checker(rootfs)
    extracted_checker_sha = sha256_bytes(checker_bytes)
    require(
        extracted_checker_sha == expected_checker_sha,
        "embedded checker differs from A3 launch binding",
    )
    legacy_regex = embedded_regex(checker_bytes)
    require(
        legacy_regex == EXPECTED_LEGACY_REGEX,
        "embedded checker is not the expected legacy oracle",
    )

    base_evidence, base_marker = run_base_replay(base_script, args.base_out)
    require(base_evidence.get("status") == "PASS", "base replay status is not PASS")
    require(
        base_evidence.get("conclusion")
        == "A3_SYSTEM_TRANSACTION_COMPLETE_LEGACY_ORACLE_FALSE_POSITIVE",
        "base replay conclusion changed",
    )
    oracle = base_evidence["oracle_replay"]
    current_regex = oracle["current_regex"]
    require(
        BOUNDED_BUG_TOKEN in current_regex,
        "current checker lacks bounded BUG token",
    )
    require(
        current_regex.replace(BOUNDED_BUG_TOKEN, "BUG:") == legacy_regex,
        "current checker contains a change beyond BUG token bounding",
    )

    console_text = read_text(console_path)
    legacy_rc, legacy_hits = grep_probe(legacy_regex, console_text)
    current_rc, current_hits = grep_probe(current_regex, console_text)
    debug_legacy_rc, debug_legacy_hits = grep_probe(
        legacy_regex, DEBUG_WITNESS + "\n"
    )
    debug_current_rc, debug_current_hits = grep_probe(
        current_regex, DEBUG_WITNESS + "\n"
    )
    bug_current_rc, bug_current_hits = grep_probe(
        current_regex, REAL_BUG_FIXTURE + "\n"
    )

    require(legacy_rc == 0 and legacy_hits, "embedded legacy replay did not fail")
    require(
        all("printk: debug:" in line for line in legacy_hits),
        "embedded legacy checker matched a competing critical marker",
    )
    require(current_rc == 1 and not current_hits, "current A3 replay is RED")
    require(
        debug_legacy_rc == 0 and debug_legacy_hits,
        "legacy checker missed printk debug witness",
    )
    require(
        debug_current_rc == 1 and not debug_current_hits,
        "current checker rejected printk debug witness",
    )
    require(
        bug_current_rc == 0 and bug_current_hits,
        "current checker accepted real BUG fixture",
    )

    extracted_tmp = args.embedded_out.with_suffix(".tmp")
    extracted_tmp.write_bytes(checker_bytes)
    extracted_tmp.replace(args.embedded_out)

    evidence = {
        "schema": SCHEMA,
        "status": "PASS",
        "classification": "verification-checker-replay",
        "source_run": {
            "path": str(a3.relative_to(repo_root)),
            "original_status": source_status,
            "original_status_preserved": True,
            "rootfs_binding_path": str(rootfs_binding_path.relative_to(repo_root)),
            "rootfs_binding_sha256": sha256_file(rootfs_binding_path),
            "rootfs_logical_bytes": int(rootfs_binding["rootfs_logical_bytes"]),
            "rootfs_template_sha256_pre": rootfs_binding[
                "rootfs_template_sha256_pre"
            ],
            "rootfs_run_image_sha256_pre": rootfs_binding[
                "rootfs_run_image_sha256_pre"
            ],
        },
        "embedded_checker": {
            "rootfs_path": str(rootfs.relative_to(repo_root)),
            "guest_path": EXPECTED_CHECKER_PATH,
            "extracted_path": str(args.embedded_out.relative_to(repo_root)),
            "sha256": extracted_checker_sha,
            "binding_sha256": expected_checker_sha,
            "binding_match": True,
            "legacy_regex": legacy_regex,
            "debugfs_diagnostic": debugfs_stderr,
        },
        "oracle_replay": {
            "current_checker": str(current_checker.relative_to(repo_root)),
            "current_checker_sha256": sha256_file(current_checker),
            "current_regex": current_regex,
            "only_regex_change": "bounded BUG token",
            "a3_console_sha256": sha256_file(console_path),
            "legacy_a3_match_count": len(legacy_hits),
            "legacy_a3_matches": legacy_hits,
            "current_a3_match_count": len(current_hits),
            "current_a3_matches": current_hits,
            "printk_debug_fixture": {
                "text": DEBUG_WITNESS,
                "legacy_match": True,
                "current_match": False,
            },
            "real_bug_fixture": {
                "text": REAL_BUG_FIXTURE,
                "current_match": True,
            },
        },
        "base_replay": {
            "script": str(base_script.relative_to(repo_root)),
            "script_sha256": sha256_file(base_script),
            "evidence": str(args.base_out.relative_to(repo_root)),
            "evidence_sha256": sha256_file(args.base_out),
            "marker": base_marker,
            "system_transaction": base_evidence["system_transaction"],
            "binding": base_evidence["binding"],
            "full_system_rerun_gate": base_evidence[
                "full_system_rerun_gate"
            ],
        },
        "conclusion": (
            "A3_SYSTEM_TRANSACTION_COMPLETE_LEGACY_ORACLE_FALSE_POSITIVE"
        ),
        "promotion": {
            "eligible": False,
            "reason": "checker replay does not qualify architecture or PPA",
        },
    }

    args.out.parent.mkdir(parents=True, exist_ok=True)
    output_tmp = args.out.with_suffix(args.out.suffix + ".tmp")
    output_tmp.write_text(
        json.dumps(evidence, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    output_tmp.replace(args.out)
    print(
        "[V10F-A3-CHECKER-REPLAY-V2] "
        f"embedded_sha={extracted_checker_sha} "
        f"legacy_matches={len(legacy_hits)} current_matches=0 "
        "printk_debug=ACCEPT real_bug=REJECT "
        "terminal=6/6 cycles=5071521696 commits=1223536213 PASS"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
