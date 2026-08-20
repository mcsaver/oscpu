#!/usr/bin/env python3
"""Fail-closed recovery for the single timed-out FP mapped run.

``--plan`` is non-destructive: it seals the exact process ownership set,
partial-diagnostic candidates, and runtime delete target for review.
``--apply`` consumes that immutable plan, preserves only bounded diagnostics,
terminates only the approved process set, removes only the exact runtime base,
and rewrites the original task status through scripts/task-run-status.sh.

This script never launches synthesis, OpenSTA, the mapped parser, or tests.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import pathlib
import re
import shutil
import signal
import stat
import subprocess
import sys
import time
from collections import defaultdict, deque
from typing import Any


RUN_ID = "2026-08-10-rv64-fp-arith-children-ppa-9d8b-a1"
EVIDENCE_ID = "traceable-9d8b-fp-arith-children-a1"
EXPECTED_REPO_ROOT = pathlib.Path("/home/lyg/PA/ysyx-workbench")
RECOVERY_CONTRACT_SHA256 = (
    "ee6988b5dfae7688fa86fa7d97a47256bbfa74217685a3f56ee620845f3dff51"
)
ORIGINAL_CONTRACT_SHA256 = (
    "843577761a20694d24ef411ee6a86262ae6eaee95b3176239d9d89ecc4f1d6c1"
)

SCRIPT_PATH = pathlib.Path(__file__).resolve()
REPO_ROOT = SCRIPT_PATH.parents[3]
TASK_RUN_ROOT = REPO_ROOT / ".github/task-runs"
RUN_DIR = TASK_RUN_ROOT / RUN_ID
REL_RUN_DIR = f".github/task-runs/{RUN_ID}"
RUNTIME_ROOT = REPO_ROOT / ".github/runtime-artifacts"
RUNTIME_BASE = RUNTIME_ROOT / RUN_ID
STATUS_PATH = RUN_DIR / f"{EVIDENCE_ID}.status"
EVIDENCE_DIR = RUN_DIR / "evidence" / EVIDENCE_ID
DIAGNOSTIC_DIR = EVIDENCE_DIR / "host-timeout-partial-diagnostic-v1"
RUNNER_PATH = REPO_ROOT / "npc/rv64/eval/ppa/run-traceable-mapped-current.sh"
STATUS_HELPER = REPO_ROOT / "scripts/task-run-status.sh"
ORIGINAL_CONTRACT = (
    REPO_ROOT
    / ".github/task-runs/2026-08-09-rv64-bpu-inline-ppa-d3f3-a1/"
    "subagent-contracts/fp-arith-production-children-ppa-9d8b-a1.json"
)
RECOVERY_CONTRACT = (
    REPO_ROOT
    / ".github/task-runs/2026-08-09-rv64-bpu-inline-ppa-d3f3-a1/"
    "subagent-contracts/"
    "fp-arith-production-children-ppa-9d8b-a1-host-timeout-recovery-v1.json"
)
WRAPPER_PATH = RUN_DIR / "host-timeout-recovery-v1.sh"
PLAN_PATH = RUN_DIR / "host-timeout-recovery-plan-v1.json"
PROCESS_BEFORE_PATH = RUN_DIR / "host-timeout-process-before-v1.json"
PROCESS_AFTER_PATH = RUN_DIR / "host-timeout-process-after-v1.json"
PARTIAL_MANIFEST_PATH = RUN_DIR / "host-timeout-partial-artifacts-v1.json"
RESULT_PATH = RUN_DIR / "host-timeout-recovery-v1.json"
MARKER_PATH = RUN_DIR / "host-timeout-recovery-v1.marker"

ALLOWED_PARTIAL_BASENAMES = {
    "synth-console.full.log",
    "synth-console.log",
    "yosys.log",
    "synth_stat.txt",
    "synth_check.txt",
    "sta_export_check.txt",
    "sta-netlist-compatibility.txt",
    "sta-netlist-unsupported-syntax.txt",
    "opensta-console.log",
    "opensta-top40.rpt",
    "opensta-check-setup.txt",
    "opensta-power.rpt",
    "opensta-fp-negative-slack.tsv",
    "opensta-fp-internal-paths.rpt",
}
MAX_COMPLETE_DIAGNOSTIC_BYTES = 512 * 1024
BOUNDED_EDGE_BYTES = 128 * 1024


class RecoveryError(RuntimeError):
    """A fail-closed recovery ownership, path, or cleanup error."""


def sha256_file(path: pathlib.Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def canonical_json_bytes(value: Any) -> bytes:
    return json.dumps(
        value,
        allow_nan=False,
        ensure_ascii=False,
        separators=(",", ":"),
        sort_keys=True,
    ).encode("utf-8")


def atomic_write_bytes(path: pathlib.Path, payload: bytes, *, new_only: bool) -> None:
    if path.is_symlink() or (new_only and path.exists()):
        raise RecoveryError(f"refusing existing/symlink output: {path}")
    path.parent.mkdir(parents=True, exist_ok=True)
    resolved_parent = path.parent.resolve(strict=True)
    if path.parent != resolved_parent:
        raise RecoveryError(f"output parent is aliased: {path.parent}")
    temporary = resolved_parent / f".{path.name}.tmp.{os.getpid()}"
    flags = os.O_WRONLY | os.O_CREAT | os.O_EXCL
    descriptor = os.open(temporary, flags, 0o644)
    try:
        with os.fdopen(descriptor, "wb") as stream:
            stream.write(payload)
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(temporary, resolved_parent / path.name)
    finally:
        try:
            temporary.unlink()
        except FileNotFoundError:
            pass


def atomic_write_json(path: pathlib.Path, value: dict[str, Any], *, new_only: bool) -> None:
    payload = json.dumps(
        value, allow_nan=False, ensure_ascii=False, indent=2, sort_keys=True
    ).encode("utf-8") + b"\n"
    atomic_write_bytes(path, payload, new_only=new_only)


def strict_regular_file(path: pathlib.Path, label: str) -> pathlib.Path:
    if path.is_symlink():
        raise RecoveryError(f"{label} is a symlink: {path}")
    resolved = path.resolve(strict=True)
    if path != resolved or not resolved.is_file():
        raise RecoveryError(f"{label} is not a canonical regular file: {path}")
    return resolved


def verify_static_roots(*, require_runtime: bool) -> None:
    if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._-]*", RUN_ID):
        raise RecoveryError("invalid fixed run-id")
    if REPO_ROOT != EXPECTED_REPO_ROOT.resolve(strict=True):
        raise RecoveryError(f"unexpected repository root: {REPO_ROOT}")
    if SCRIPT_PATH != RUN_DIR / SCRIPT_PATH.name:
        raise RecoveryError(f"recovery script is outside exact run-dir: {SCRIPT_PATH}")
    for directory, label in (
        (TASK_RUN_ROOT, "task-run root"),
        (RUN_DIR, "exact run-dir"),
        (RUNTIME_ROOT, "runtime root"),
        (EVIDENCE_DIR, "evidence directory"),
    ):
        if directory.is_symlink() or directory.resolve(strict=True) != directory:
            raise RecoveryError(f"{label} is missing, symlinked, or aliased: {directory}")
    if RUN_DIR.parent != TASK_RUN_ROOT or RUNTIME_BASE.parent != RUNTIME_ROOT:
        raise RecoveryError("run/runtime parent identity drifted")
    if require_runtime:
        if RUNTIME_BASE.is_symlink() or RUNTIME_BASE.resolve(strict=True) != RUNTIME_BASE:
            raise RecoveryError(f"runtime base is missing/symlinked/aliased: {RUNTIME_BASE}")
        if not RUNTIME_BASE.is_dir():
            raise RecoveryError(f"runtime base is not a directory: {RUNTIME_BASE}")
    elif RUNTIME_BASE.exists() or RUNTIME_BASE.is_symlink():
        if RUNTIME_BASE.is_symlink() or RUNTIME_BASE.resolve(strict=True) != RUNTIME_BASE:
            raise RecoveryError(f"runtime base became unsafe: {RUNTIME_BASE}")
    for path, label in (
        (STATUS_PATH, "task status"),
        (RUNNER_PATH, "mapped runner"),
        (STATUS_HELPER, "status helper"),
        (ORIGINAL_CONTRACT, "original PPA contract"),
        (RECOVERY_CONTRACT, "recovery contract"),
        (SCRIPT_PATH, "recovery script"),
        (WRAPPER_PATH, "recovery wrapper"),
    ):
        strict_regular_file(path, label)
    if sha256_file(ORIGINAL_CONTRACT) != ORIGINAL_CONTRACT_SHA256:
        raise RecoveryError("original PPA contract SHA drifted")
    if sha256_file(RECOVERY_CONTRACT) != RECOVERY_CONTRACT_SHA256:
        raise RecoveryError("recovery contract SHA drifted")


def read_status() -> str:
    status = strict_regular_file(STATUS_PATH, "task status").read_text(
        encoding="utf-8"
    )
    if not status.endswith("\n") or status.count("\n") != 1:
        raise RecoveryError("task status is not one canonical line")
    return status[:-1]


def process_record(pid: int) -> dict[str, Any] | None:
    proc = pathlib.Path("/proc") / str(pid)
    try:
        stat_text = (proc / "stat").read_text(encoding="utf-8")
        close = stat_text.rfind(")")
        if close < 0:
            return None
        comm = stat_text[stat_text.find("(") + 1 : close]
        fields = stat_text[close + 2 :].split()
        ppid = int(fields[1])
        pgrp = int(fields[2])
        session = int(fields[3])
        start_ticks = int(fields[19])
        raw_cmdline = (proc / "cmdline").read_bytes()
        argv = [
            token.decode("utf-8", errors="surrogateescape")
            for token in raw_cmdline.split(b"\0")
            if token
        ]
        try:
            cwd = os.readlink(proc / "cwd")
        except OSError:
            cwd = None
        try:
            executable = os.readlink(proc / "exe")
        except OSError:
            executable = None
        return {
            "pid": pid,
            "ppid": ppid,
            "pgrp": pgrp,
            "session": session,
            "start_ticks": start_ticks,
            "comm": comm,
            "argv": argv,
            "cwd": cwd,
            "executable": executable,
        }
    except (FileNotFoundError, ProcessLookupError, PermissionError, ValueError):
        return None


def process_snapshot() -> dict[int, dict[str, Any]]:
    result: dict[int, dict[str, Any]] = {}
    for entry in pathlib.Path("/proc").iterdir():
        if not entry.name.isdecimal():
            continue
        record = process_record(int(entry.name))
        if record is not None:
            result[record["pid"]] = record
    return result


def ancestor_set(snapshot: dict[int, dict[str, Any]], pid: int) -> set[int]:
    ancestors: set[int] = set()
    cursor = pid
    while cursor in snapshot:
        parent = int(snapshot[cursor]["ppid"])
        if parent <= 0 or parent in ancestors:
            break
        ancestors.add(parent)
        cursor = parent
    return ancestors


def seed_reasons(record: dict[str, Any]) -> list[str]:
    argv = record["argv"]
    reasons: list[str] = []
    runtime_prefix = f"{RUNTIME_BASE}/"
    runner_spellings = {
        str(RUNNER_PATH),
        "npc/rv64/eval/ppa/run-traceable-mapped-current.sh",
    }
    for index, argument in enumerate(argv):
        if argument == RUN_ID:
            reasons.append("exact-run-id-token")
        if argument in {REL_RUN_DIR, str(RUN_DIR)}:
            reasons.append("exact-run-dir-token")
        if argument == str(RUNTIME_BASE) or argument.startswith(runtime_prefix):
            reasons.append("exact-runtime-base-token")
        if (
            argument == "--run-dir"
            and index + 1 < len(argv)
            and argv[index + 1] in {REL_RUN_DIR, str(RUN_DIR)}
        ):
            reasons.append("exact-runner-run-dir-argument")
        if argument in runner_spellings:
            reasons.append("exact-runner-path-token")
    return sorted(set(reasons))


def classify_processes(snapshot: dict[int, dict[str, Any]]) -> dict[str, Any]:
    excluded = ancestor_set(snapshot, os.getpid()) | {os.getpid()}
    seeds: dict[int, list[str]] = {}
    for pid, record in snapshot.items():
        if pid in excluded:
            continue
        reasons = seed_reasons(record)
        if reasons:
            seeds[pid] = reasons

    children: dict[int, list[int]] = defaultdict(list)
    for pid, record in snapshot.items():
        children[int(record["ppid"])].append(pid)
    targets: set[int] = set()
    queue: deque[int] = deque(seeds)
    while queue:
        pid = queue.popleft()
        if pid in targets or pid in excluded:
            continue
        targets.add(pid)
        queue.extend(children.get(pid, []))

    roots = sorted(
        pid for pid in targets if int(snapshot[pid]["ppid"]) not in targets
    )
    ambiguity: list[str] = []
    if len(roots) > 1:
        ambiguity.append(
            "matching process ownership has multiple independent roots: "
            + ",".join(str(pid) for pid in roots)
        )
    records: list[dict[str, Any]] = []
    for pid in sorted(targets):
        item = dict(snapshot[pid])
        item["seed_reasons"] = seeds.get(pid, [])
        item["ownership"] = "exact-seed" if pid in seeds else "seed-descendant"
        records.append(item)
    return {
        "scanned_process_count": len(snapshot),
        "excluded_self_and_ancestor_pids": sorted(excluded),
        "seed_pids": sorted(seeds),
        "target_root_pids": roots,
        "target_processes": records,
        "target_process_count": len(records),
        "ownership_ambiguous": bool(ambiguity),
        "ambiguity_reasons": ambiguity,
    }


def tree_size_bytes(root: pathlib.Path) -> int:
    total = 0
    for directory, names, files in os.walk(root, topdown=True, followlinks=False):
        directory_path = pathlib.Path(directory)
        for name in names + files:
            path = directory_path / name
            try:
                total += path.lstat().st_size
            except FileNotFoundError:
                pass
    try:
        total += root.lstat().st_size
    except FileNotFoundError:
        pass
    return total


def stable_diagnostic_capture(
    path: pathlib.Path, *, include_payload: bool
) -> dict[str, Any]:
    """Read one growing log only when inode/size/mtime stay stable for the read."""

    for _attempt in range(20):
        digest = hashlib.sha256()
        total = 0
        head = bytearray()
        tail = bytearray()
        complete_chunks: list[bytes] = []
        with path.open("rb") as stream:
            before = os.fstat(stream.fileno())
            if not stat.S_ISREG(before.st_mode):
                raise RecoveryError(f"partial diagnostic is not regular: {path}")
            keep_complete = include_payload and before.st_size <= MAX_COMPLETE_DIAGNOSTIC_BYTES
            while True:
                chunk = stream.read(1024 * 1024)
                if not chunk:
                    break
                digest.update(chunk)
                total += len(chunk)
                if len(head) < BOUNDED_EDGE_BYTES:
                    needed = BOUNDED_EDGE_BYTES - len(head)
                    head.extend(chunk[:needed])
                tail.extend(chunk)
                if len(tail) > BOUNDED_EDGE_BYTES:
                    del tail[:-BOUNDED_EDGE_BYTES]
                if keep_complete:
                    complete_chunks.append(chunk)
            after = os.fstat(stream.fileno())
        identity_before = (
            before.st_dev,
            before.st_ino,
            before.st_size,
            before.st_mtime_ns,
        )
        identity_after = (
            after.st_dev,
            after.st_ino,
            after.st_size,
            after.st_mtime_ns,
        )
        if identity_before == identity_after and total == before.st_size:
            result: dict[str, Any] = {
                "source_device": before.st_dev,
                "source_inode": before.st_ino,
                "source_mtime_ns": before.st_mtime_ns,
                "source_size_bytes": before.st_size,
                "source_sha256": digest.hexdigest(),
                "preservation_mode": (
                    "complete-small-copy"
                    if before.st_size <= MAX_COMPLETE_DIAGNOSTIC_BYTES
                    else "bounded-head-tail"
                ),
            }
            if include_payload:
                result["payload"] = (
                    b"".join(complete_chunks)
                    if keep_complete
                    else bytes(head)
                    + b"\n[HOST_TIMEOUT_PARTIAL_DIAGNOSTIC: bounded middle omitted]\n"
                    + bytes(tail)
                )
            return result
        time.sleep(0.05)
    raise RecoveryError(f"partial diagnostic did not reach a stable read point: {path}")


def partial_candidates() -> list[dict[str, Any]]:
    candidates: list[dict[str, Any]] = []
    for directory, names, files in os.walk(
        RUNTIME_BASE, topdown=True, followlinks=False
    ):
        names[:] = sorted(names)
        for filename in sorted(files):
            if filename not in ALLOWED_PARTIAL_BASENAMES:
                continue
            source = pathlib.Path(directory) / filename
            source_stat = source.lstat()
            if not stat.S_ISREG(source_stat.st_mode) or source.is_symlink():
                raise RecoveryError(f"partial diagnostic is not a regular file: {source}")
            resolved = source.resolve(strict=True)
            try:
                relative = resolved.relative_to(RUNTIME_BASE).as_posix()
            except ValueError as exc:
                raise RecoveryError(f"partial diagnostic escapes runtime: {source}") from exc
            if source != resolved:
                raise RecoveryError(f"partial diagnostic path is aliased: {source}")
            captured = stable_diagnostic_capture(source, include_payload=False)
            destination = DIAGNOSTIC_DIR / relative
            candidates.append(
                {
                    "source_path": str(source),
                    "source_relative_to_runtime": relative,
                    **captured,
                    "destination_path": destination.relative_to(REPO_ROOT).as_posix(),
                    "qualification": "HOST_TIMEOUT_PARTIAL_DIAGNOSTIC",
                    "complete": False,
                    "ppa_eligible": False,
                }
            )
    return candidates


def artifact_receipt(path: pathlib.Path) -> dict[str, Any]:
    strict_regular_file(path, f"artifact {path.name}")
    return {
        "path": path.relative_to(REPO_ROOT).as_posix(),
        "size_bytes": path.stat().st_size,
        "sha256": sha256_file(path),
    }


def make_plan() -> int:
    verify_static_roots(require_runtime=True)
    if read_status() != "RUNNING":
        raise RecoveryError("original status is not exactly RUNNING at plan time")
    for output in (
        PLAN_PATH,
        PROCESS_BEFORE_PATH,
        PROCESS_AFTER_PATH,
        PARTIAL_MANIFEST_PATH,
        RESULT_PATH,
        MARKER_PATH,
    ):
        if output.exists() or output.is_symlink():
            raise RecoveryError(f"recovery output already exists: {output}")
    snapshot = process_snapshot()
    classification = classify_processes(snapshot)
    partial = partial_candidates()
    before = {
        "schema": "npc-rv64-host-timeout-process-snapshot-v1",
        "phase": "before",
        "run_id": RUN_ID,
        **classification,
    }
    atomic_write_json(PROCESS_BEFORE_PATH, before, new_only=True)
    plan_core = {
        "schema": "npc-rv64-host-timeout-recovery-plan-v1",
        "status": "BLOCKED_AMBIGUOUS" if classification["ownership_ambiguous"] else "READY",
        "run_id": RUN_ID,
        "evidence_id": EVIDENCE_ID,
        "original_status": "RUNNING",
        "outer_host_timeout_rc": 124,
        "target_runtime_base": str(RUNTIME_BASE),
        "target_runtime_parent": str(RUNTIME_ROOT),
        "runtime_size_bytes_at_plan": tree_size_bytes(RUNTIME_BASE),
        "process_before": artifact_receipt(PROCESS_BEFORE_PATH),
        "target_processes": classification["target_processes"],
        "target_root_pids": classification["target_root_pids"],
        "ownership_ambiguous": classification["ownership_ambiguous"],
        "ambiguity_reasons": classification["ambiguity_reasons"],
        "partial_artifact_candidates": partial,
        "bound_inputs": {
            "original_contract": artifact_receipt(ORIGINAL_CONTRACT),
            "recovery_contract": artifact_receipt(RECOVERY_CONTRACT),
            "runner": artifact_receipt(RUNNER_PATH),
            "status_helper": artifact_receipt(STATUS_HELPER),
            "recovery_script": artifact_receipt(SCRIPT_PATH),
            "recovery_wrapper": artifact_receipt(WRAPPER_PATH),
        },
        "destructive_actions_executed": False,
    }
    plan = {
        **plan_core,
        "plan_id": f"sha256:{hashlib.sha256(canonical_json_bytes(plan_core)).hexdigest()}",
    }
    atomic_write_json(PLAN_PATH, plan, new_only=True)
    print(
        "[HOST-TIMEOUT-RECOVERY][PLAN] "
        f"status={plan['status']} targets={len(plan['target_processes'])} "
        f"partial={len(plan['partial_artifact_candidates'])} "
        f"runtime={plan['target_runtime_base']}"
    )
    return 3 if classification["ownership_ambiguous"] else 0


def load_json(path: pathlib.Path) -> dict[str, Any]:
    strict_regular_file(path, path.name)
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise RecoveryError(f"JSON root is not an object: {path}")
    return value


def record_identity(record: dict[str, Any]) -> tuple[Any, ...]:
    return (
        record["pid"],
        record["ppid"],
        record["start_ticks"],
        tuple(record["argv"]),
    )


def live_process_identity(record: dict[str, Any]) -> tuple[Any, ...]:
    """Identity stable across reparenting while a signaled tree exits."""

    return (
        record["pid"],
        record["start_ticks"],
        tuple(record["argv"]),
    )


def process_is_same(record: dict[str, Any]) -> bool:
    current = process_record(int(record["pid"]))
    return (
        current is not None
        and live_process_identity(current) == live_process_identity(record)
    )


def preserve_partial(candidate: dict[str, Any]) -> dict[str, Any]:
    source = pathlib.Path(candidate["source_path"])
    expected_relative = candidate["source_relative_to_runtime"]
    if source.is_symlink() or source.resolve(strict=True) != source:
        raise RecoveryError(f"partial diagnostic source became unsafe: {source}")
    if source.relative_to(RUNTIME_BASE).as_posix() != expected_relative:
        raise RecoveryError(f"partial diagnostic source identity drifted: {source}")
    current_stat = source.stat()
    if (
        current_stat.st_dev != candidate["source_device"]
        or current_stat.st_ino != candidate["source_inode"]
    ):
        raise RecoveryError(f"partial diagnostic inode drifted: {source}")
    if current_stat.st_size < candidate["source_size_bytes"]:
        raise RecoveryError(f"partial diagnostic shrank after plan: {source}")
    captured = stable_diagnostic_capture(source, include_payload=True)
    if (
        captured["source_device"] != candidate["source_device"]
        or captured["source_inode"] != candidate["source_inode"]
    ):
        raise RecoveryError(f"partial diagnostic changed inode while copying: {source}")
    destination = REPO_ROOT / candidate["destination_path"]
    payload = captured.pop("payload")
    atomic_write_bytes(destination, payload, new_only=True)
    return {
        **candidate,
        "source_at_preservation": captured,
        "preserved_artifact": artifact_receipt(destination),
    }


def depth(pid: int, records: dict[int, dict[str, Any]]) -> int:
    value = 0
    cursor = pid
    seen: set[int] = set()
    while cursor in records and cursor not in seen:
        seen.add(cursor)
        parent = int(records[cursor]["ppid"])
        if parent not in records:
            break
        value += 1
        cursor = parent
    return value


def signal_targets(
    planned: list[dict[str, Any]], signal_value: signal.Signals
) -> list[dict[str, Any]]:
    records = {int(record["pid"]): record for record in planned}
    attempts: list[dict[str, Any]] = []
    for pid in sorted(records, key=lambda item: (depth(item, records), item), reverse=True):
        record = records[pid]
        if not process_is_same(record):
            attempts.append({"pid": pid, "signal": signal_value.name, "state": "already-exited"})
            continue
        try:
            os.kill(pid, signal_value)
            attempts.append({"pid": pid, "signal": signal_value.name, "state": "sent"})
        except ProcessLookupError:
            attempts.append({"pid": pid, "signal": signal_value.name, "state": "already-exited"})
        except PermissionError as exc:
            raise RecoveryError(f"permission denied signaling exact target pid={pid}") from exc
    return attempts


def wait_for_targets(planned: list[dict[str, Any]], seconds: float) -> list[int]:
    deadline = time.monotonic() + seconds
    while time.monotonic() < deadline:
        remaining = [
            int(record["pid"]) for record in planned if process_is_same(record)
        ]
        if not remaining:
            return []
        time.sleep(0.1)
    return [int(record["pid"]) for record in planned if process_is_same(record)]


def write_status_with_helper(cleanup_rc: int) -> None:
    command = r'''
source "$1" || exit 90
TASK_RUN_STATUS_PATH="$2"
TASK_RUN_STATUS_STAGE="host-shell-timeout"
TASK_RUN_STATUS_SIGNAL="HOST_TIMEOUT"
TASK_RUN_STATUS_EVIDENCE_COMPLETE=0
task_run_status_finalize 124 "$3"
finalize_rc=$?
[[ "${finalize_rc}" -eq 124 ]]
'''
    completed = subprocess.run(
        [
            "bash",
            "-c",
            command,
            "host-timeout-recovery-status",
            str(STATUS_HELPER),
            str(STATUS_PATH),
            str(cleanup_rc),
        ],
        check=False,
    )
    if completed.returncode != 0:
        raise RecoveryError(
            f"task-run-status helper failed: rc={completed.returncode}"
        )


def make_after_snapshot() -> dict[str, Any]:
    classification = classify_processes(process_snapshot())
    return {
        "schema": "npc-rv64-host-timeout-process-snapshot-v1",
        "phase": "after",
        "run_id": RUN_ID,
        **classification,
    }


def apply_recovery() -> int:
    verify_static_roots(require_runtime=True)
    if read_status() != "RUNNING":
        raise RecoveryError("original status is not exactly RUNNING at apply time")
    for output in (PROCESS_AFTER_PATH, PARTIAL_MANIFEST_PATH, RESULT_PATH, MARKER_PATH):
        if output.exists() or output.is_symlink():
            raise RecoveryError(f"apply output already exists: {output}")

    plan = load_json(PLAN_PATH)
    if plan.get("schema") != "npc-rv64-host-timeout-recovery-plan-v1":
        raise RecoveryError("recovery plan schema mismatch")
    if plan.get("status") != "READY" or plan.get("ownership_ambiguous") is not False:
        raise RecoveryError("recovery plan is not uniquely owned/ready")
    if plan.get("run_id") != RUN_ID or plan.get("target_runtime_base") != str(RUNTIME_BASE):
        raise RecoveryError("recovery plan run/runtime identity drifted")
    expected_core = {key: value for key, value in plan.items() if key != "plan_id"}
    expected_plan_id = f"sha256:{hashlib.sha256(canonical_json_bytes(expected_core)).hexdigest()}"
    if plan.get("plan_id") != expected_plan_id:
        raise RecoveryError("recovery plan ID drifted")
    for name, receipt in plan["bound_inputs"].items():
        path = REPO_ROOT / receipt["path"]
        if artifact_receipt(path) != receipt:
            raise RecoveryError(f"bound recovery input drifted: {name}")
    if artifact_receipt(PROCESS_BEFORE_PATH) != plan["process_before"]:
        raise RecoveryError("process-before receipt drifted")

    current_classification = classify_processes(process_snapshot())
    if current_classification["ownership_ambiguous"]:
        raise RecoveryError("process ownership became ambiguous before apply")
    planned_records = {
        int(record["pid"]): record for record in plan["target_processes"]
    }
    current_records = {
        int(record["pid"]): record
        for record in current_classification["target_processes"]
    }
    unexpected = sorted(set(current_records) - set(planned_records))
    if unexpected:
        raise RecoveryError(
            "new unapproved run-owned processes appeared after plan: "
            + ",".join(str(pid) for pid in unexpected)
        )
    for pid, current in current_records.items():
        if record_identity(current) != record_identity(planned_records[pid]):
            raise RecoveryError(f"planned process identity drifted/reused: pid={pid}")

    preserved = [preserve_partial(item) for item in plan["partial_artifact_candidates"]]
    partial_manifest = {
        "schema": "npc-rv64-host-timeout-partial-artifact-manifest-v1",
        "run_id": RUN_ID,
        "qualification": "HOST_TIMEOUT_PARTIAL_DIAGNOSTIC",
        "complete": False,
        "ppa_eligible": False,
        "artifacts": preserved,
    }
    atomic_write_json(PARTIAL_MANIFEST_PATH, partial_manifest, new_only=True)

    runtime_bytes_before = tree_size_bytes(RUNTIME_BASE)
    live_planned = [planned_records[pid] for pid in sorted(current_records)]
    term_attempts = signal_targets(live_planned, signal.SIGTERM)
    remaining_after_term = wait_for_targets(live_planned, 10.0)
    kill_records = [planned_records[pid] for pid in remaining_after_term]
    kill_attempts = signal_targets(kill_records, signal.SIGKILL)
    remaining_after_kill = wait_for_targets(kill_records, 5.0)

    cleanup_errors: list[str] = []
    if remaining_after_kill:
        cleanup_errors.append(
            "approved processes survived SIGKILL: "
            + ",".join(str(pid) for pid in remaining_after_kill)
        )
    after = make_after_snapshot()
    if after["target_process_count"] != 0:
        cleanup_errors.append("run-owned process set is not empty after signaling")

    recovery_removed_runtime = False
    runtime_bytes_before_delete = 0
    recovery_deleted_bytes = 0
    if not cleanup_errors and (RUNTIME_BASE.exists() or RUNTIME_BASE.is_symlink()):
        if RUNTIME_BASE.is_symlink() or RUNTIME_BASE.resolve(strict=True) != RUNTIME_BASE:
            cleanup_errors.append("runtime base became unsafe before deletion")
        elif RUNTIME_BASE.parent != RUNTIME_ROOT:
            cleanup_errors.append("runtime delete target parent drifted")
        else:
            try:
                runtime_bytes_before_delete = tree_size_bytes(RUNTIME_BASE)
                shutil.rmtree(RUNTIME_BASE)
                recovery_removed_runtime = True
                recovery_deleted_bytes = runtime_bytes_before_delete
            except OSError as exc:
                cleanup_errors.append(f"runtime deletion failed: {exc}")
    runtime_absent = not RUNTIME_BASE.exists() and not RUNTIME_BASE.is_symlink()
    if not runtime_absent:
        cleanup_errors.append("exact runtime base remains after cleanup")

    after.update(
        {
            "term_attempts": term_attempts,
            "kill_attempts": kill_attempts,
            "remaining_after_term": remaining_after_term,
            "remaining_after_kill": remaining_after_kill,
        }
    )
    atomic_write_json(PROCESS_AFTER_PATH, after, new_only=True)

    cleanup_rc = 0 if not cleanup_errors else 1
    status_before_rewrite = read_status()
    if status_before_rewrite == "PASS":
        raise RecoveryError("refusing to overwrite a late PASS status")
    write_status_with_helper(cleanup_rc)
    expected_status = (
        "FAIL rc=124 stage=host-shell-timeout evidence_complete=0 "
        f"cleanup_rc={cleanup_rc} signal=HOST_TIMEOUT"
    )
    status_after_rewrite = read_status()
    if status_after_rewrite != expected_status:
        raise RecoveryError(
            "task status rewrite mismatch: "
            f"expected={expected_status!r} actual={status_after_rewrite!r}"
        )

    pass_recovery = cleanup_rc == 0 and runtime_absent and after["target_process_count"] == 0
    result = {
        "schema": "npc-rv64-host-timeout-recovery-result-v1",
        "status": "PASS" if pass_recovery else "FAIL",
        "scope": "RECOVERY_ONLY_NOT_PPA",
        "run_id": RUN_ID,
        "outer_host_timeout_rc": 124,
        "production_rerun_count": 0,
        "status_before_rewrite": status_before_rewrite,
        "status_after_rewrite": status_after_rewrite,
        "process_before": artifact_receipt(PROCESS_BEFORE_PATH),
        "process_after": artifact_receipt(PROCESS_AFTER_PATH),
        "partial_artifacts": artifact_receipt(PARTIAL_MANIFEST_PATH),
        "runtime_base": str(RUNTIME_BASE),
        "runtime_bytes_before_cleanup": runtime_bytes_before,
        "runtime_bytes_before_delete": runtime_bytes_before_delete,
        "recovery_deleted_bytes": recovery_deleted_bytes,
        "runtime_absent": runtime_absent,
        "recovery_removed_runtime": recovery_removed_runtime,
        "cleanup_rc": cleanup_rc,
        "cleanup_errors": cleanup_errors,
        "evidence_complete": False,
        "ppa_eligible": False,
        "summary_created": False,
        "binding_created": False,
        "command_status_pass_created": False,
    }
    atomic_write_json(RESULT_PATH, result, new_only=True)
    marker = (
        "[HOST-TIMEOUT-RECOVERY][PASS] RECOVERY_ONLY_NOT_PPA\n"
        if pass_recovery
        else "[HOST-TIMEOUT-RECOVERY][FAIL] RECOVERY_ONLY_NOT_PPA\n"
    )
    atomic_write_bytes(MARKER_PATH, marker.encode("utf-8"), new_only=True)
    print(marker, end="")
    return 0 if pass_recovery else 1


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser()
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--plan", action="store_true")
    mode.add_argument("--apply", action="store_true")
    return parser


def main() -> int:
    args = build_parser().parse_args()
    try:
        return make_plan() if args.plan else apply_recovery()
    except (RecoveryError, OSError, UnicodeError, ValueError, json.JSONDecodeError) as exc:
        print(f"[HOST-TIMEOUT-RECOVERY][FAIL] {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
