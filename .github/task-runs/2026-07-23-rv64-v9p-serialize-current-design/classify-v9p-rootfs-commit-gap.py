#!/usr/bin/env python3
"""Classify one local RV64 rootfs commit-gap diagnostic log."""

from __future__ import annotations

import argparse
import json
import pathlib
import re
import sys
import tempfile


PROGRESS_RE = re.compile(
    r"^\[progress\]\s+(?P<commits>[0-9]+)\s+insts,\s+"
    r"pc=(?P<pc>0x[0-9a-fA-F]+),\s+(?P<rate>[0-9]+)\s+inst/s$",
    re.MULTILINE,
)
USER_PROGRESS_RE = re.compile(
    r"user_progress\]\s+sample=(?P<sample>[0-9]+)\s+"
    r"commit=(?P<commits>[0-9]+)\s+pc=(?P<pc>0x[0-9a-fA-F]+)",
)
INTERRUPTED_RE = re.compile(
    r"\[npc\]\s+execution interrupted at pc=(?P<pc>0x[0-9a-fA-F]+)\s+"
    r"after (?P<cycles>[0-9]+) cycles"
)


def last_match(pattern: re.Pattern[str], text: str) -> re.Match[str] | None:
    matches = list(pattern.finditer(text))
    return matches[-1] if matches else None


def classify(
    text: str,
    *,
    sim_rc: int,
    sim_rc_source: str,
    host_timeout_seconds: int,
    commit_gap_limit_cycles: int,
    rtl_design_id: str,
    simulator_sha256: str,
    harness_status: str,
    log_path: str,
) -> dict[str, object]:
    enabled = "commit-gap] enabled" in text
    expired = "commit-gap] expired" in text
    recent_commits = "recent commits before stop:" in text
    recent_cycles = "recent debug cycles before stop:" in text
    memdiag = "memdiag=" in text
    progress = last_match(PROGRESS_RE, text)
    user_progress = last_match(USER_PROGRESS_RE, text)
    interrupted = last_match(INTERRUPTED_RE, text)

    errors: list[str] = []
    if not enabled:
        errors.append("commit-gap observer enable marker is missing")

    if sim_rc == 3:
        outcome = "commit_gap_captured"
        for present, description in (
            (expired, "commit-gap expiration marker"),
            (recent_commits, "recent commit window"),
            (recent_cycles, "recent RTL cycle window"),
            (memdiag, "memory diagnostic packet"),
        ):
            if not present:
                errors.append(f"{description} is missing")
    elif sim_rc == 124:
        outcome = "no_commit_gap_within_host_budget"
        if expired:
            errors.append("commit-gap expiration marker contradicts host-budget outcome")
        if progress is None:
            errors.append("architectural commit progress marker is missing")
        if interrupted is None:
            errors.append("host-budget interrupt marker is missing")
    else:
        outcome = "unexpected_simulator_exit"
        errors.append(f"unexpected simulator return code {sim_rc}")

    payload: dict[str, object] = {
        "schema_version": 1,
        "scope": "local_rv64_rootfs_commit_continuity_diagnostic",
        "diagnostic_status": "PASS" if not errors else "FAIL",
        "diagnostic_outcome": outcome,
        "rootfs_gate_status": "UNRESOLVED",
        "rootfs_promotion_eligible": False,
        "sim_rc": sim_rc,
        "sim_rc_source": sim_rc_source,
        "harness_status": harness_status,
        "rtl_design_id": rtl_design_id,
        "simulator_sha256": simulator_sha256,
        "host_timeout_seconds": host_timeout_seconds,
        "commit_gap_limit_cycles": commit_gap_limit_cycles,
        "markers": {
            "observer_enabled": enabled,
            "observer_expired": expired,
            "wrapper_preflight_pass": "__NPC_CHECK_PASS__:systemd-wrapper-preflight" in text,
            "systemd_exec": "exec systemd: /lib/systemd/systemd" in text,
            "ubuntu_banner": "Welcome to " in text and "Ubuntu 22.04.5 LTS" in text,
            "hostname_set": "Hostname set to <ysyx-ubuntu2204>" in text,
            "shell_ready": "__NPC_CONSOLE_SHELL_READY__" in text,
            "natural_poweroff": "reset-syscon" in text,
        },
        "last_progress": (
            {
                "commits": int(progress.group("commits")),
                "pc": progress.group("pc"),
                "inst_per_second": int(progress.group("rate")),
            }
            if progress is not None
            else None
        ),
        "last_user_progress": (
            {
                "sample": int(user_progress.group("sample")),
                "commits": int(user_progress.group("commits")),
                "pc": user_progress.group("pc"),
            }
            if user_progress is not None
            else None
        ),
        "terminal_observation": (
            {
                "cycles": int(interrupted.group("cycles")),
                "pc": interrupted.group("pc"),
                "reason": "host_budget_interrupt",
            }
            if interrupted is not None
            else None
        ),
        "evidence": {"npc_log": log_path},
        "errors": errors,
    }
    return payload


def run_self_test() -> int:
    common = {
        "sim_rc_source": "self_test",
        "host_timeout_seconds": 7200,
        "commit_gap_limit_cycles": 1_000_000,
        "rtl_design_id": "sha256:self-test",
        "simulator_sha256": "self-test",
        "harness_status": "self-test",
        "log_path": "self-test.log",
    }
    no_gap_log = "\n".join(
        (
            "[cpu-exec.cpp:2452 commit-gap] enabled limit_cycles=1000000",
            "[guest] __NPC_CHECK_PASS__:systemd-wrapper-preflight",
            "[progress] 145000001 insts, pc=0x0000003fbdba3426, 27098 inst/s",
            "[cpu-exec.cpp:747 user_progress] sample=18 commit=146027279 "
            "pc=0x0000003fbdba25c2",
            "[npc] execution interrupted at pc=0x0000003fbdba3808 after 560316484 cycles",
        )
    )
    no_gap = classify(no_gap_log, sim_rc=124, **common)
    assert no_gap["diagnostic_status"] == "PASS"
    assert no_gap["diagnostic_outcome"] == "no_commit_gap_within_host_budget"

    gap_log = "\n".join(
        (
            "[cpu-exec.cpp:2452 commit-gap] enabled limit_cycles=1000000",
            "[cpu-exec.cpp:2500 commit-gap] expired gap_cycles=1000000",
            "recent commits before stop:",
            "recent debug cycles before stop:",
            "memdiag=0x1",
        )
    )
    gap = classify(gap_log, sim_rc=3, **common)
    assert gap["diagnostic_status"] == "PASS"
    assert gap["diagnostic_outcome"] == "commit_gap_captured"

    invalid = classify(no_gap_log, sim_rc=3, **common)
    assert invalid["diagnostic_status"] == "FAIL"
    assert invalid["errors"]

    with tempfile.TemporaryDirectory() as tmpdir:
        output = pathlib.Path(tmpdir) / "classification.json"
        output.write_text(json.dumps(no_gap, indent=2) + "\n", encoding="utf-8")
        round_trip = json.loads(output.read_text(encoding="utf-8"))
        assert round_trip["last_user_progress"]["commits"] == 146027279

    print("[V9P-ROOTFS-COMMIT-GAP-CLASSIFIER] self-test PASS")
    return 0


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--self-test", action="store_true")
    parser.add_argument("--log", type=pathlib.Path)
    parser.add_argument("--output", type=pathlib.Path)
    parser.add_argument("--sim-rc", type=int)
    parser.add_argument("--sim-rc-source")
    parser.add_argument("--host-timeout-seconds", type=int)
    parser.add_argument("--commit-gap-limit-cycles", type=int)
    parser.add_argument("--rtl-design-id")
    parser.add_argument("--simulator-sha256")
    parser.add_argument("--harness-status", default="")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if args.self_test:
        return run_self_test()

    required = {
        "--log": args.log,
        "--output": args.output,
        "--sim-rc": args.sim_rc,
        "--sim-rc-source": args.sim_rc_source,
        "--host-timeout-seconds": args.host_timeout_seconds,
        "--commit-gap-limit-cycles": args.commit_gap_limit_cycles,
        "--rtl-design-id": args.rtl_design_id,
        "--simulator-sha256": args.simulator_sha256,
    }
    missing = [
        name
        for name, value in required.items()
        if value is None or (isinstance(value, str) and not value)
    ]
    if missing:
        raise SystemExit(f"missing required arguments: {', '.join(missing)}")

    text = args.log.read_text(encoding="utf-8", errors="replace")
    payload = classify(
        text,
        sim_rc=args.sim_rc,
        sim_rc_source=args.sim_rc_source,
        host_timeout_seconds=args.host_timeout_seconds,
        commit_gap_limit_cycles=args.commit_gap_limit_cycles,
        rtl_design_id=args.rtl_design_id,
        simulator_sha256=args.simulator_sha256,
        harness_status=args.harness_status,
        log_path=str(args.log),
    )
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    print(
        "[V9P-ROOTFS-COMMIT-GAP-CLASSIFIER] "
        f"{payload['diagnostic_status']} outcome={payload['diagnostic_outcome']}"
    )
    return 0 if payload["diagnostic_status"] == "PASS" else 1


if __name__ == "__main__":
    sys.exit(main())
