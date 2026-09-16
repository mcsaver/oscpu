#!/usr/bin/env python3
"""Current-design adapter for the immutable V8S dual-memory F2 checker.

The historical checker remains byte-for-byte auditable.  This adapter keeps
all of its checks and extends only the singleton-exclusion predicate for the
registered request-hold topology used by the current RTL.
"""

from __future__ import annotations

import argparse
from dataclasses import asdict
import importlib.util
import json
import pathlib
import re
import sys
from typing import Any


ROOT = pathlib.Path(__file__).resolve().parents[5]
LEGACY_PATH = (
    ROOT
    / ".github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration"
    / "check-v8s-dual-memory-core.py"
)
SPEC = importlib.util.spec_from_file_location("v8s_legacy_checker", LEGACY_PATH)
if SPEC is None or SPEC.loader is None:
    raise RuntimeError(f"cannot load immutable V8S checker: {LEGACY_PATH}")
LEGACY = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = LEGACY
SPEC.loader.exec_module(LEGACY)

Check = LEGACY.Check
load_sources = LEGACY.load_sources
terminal_topology = LEGACY.terminal_topology


def _match(text: str, pattern: str) -> bool:
    return bool(re.search(pattern, text, flags=re.DOTALL | re.MULTILINE))


def _hold_aware_singleton_exclusion(backend: str) -> tuple[bool, dict[str, bool]]:
    facts = {
        "singleton_wait_from_bank1_hold": _match(
            backend,
            r"\bwire\s+mem_req_singleton_wait_w\s*=\s*ENABLE_DUAL_MEM\s*&&"
            r".*?mem1_req_hold_valid_q\s*&&.*?"
            r"\(\s*sq_drain_req_valid_w\s*\|\|\s*"
            r"mem_amo_write_req_valid_w\s*\|\|.*?mem_buffer_req_valid_w\s*\)+\s*;",
        ),
        "sq_wait_gate": _match(
            backend,
            r"\bwire\s+live_grant_sq_w\s*=\s*!mem_req_singleton_wait_w\s*&&",
        ),
        "amo_wait_gate": _match(
            backend,
            r"\bwire\s+live_grant_amo_write_w\s*=\s*!mem_req_singleton_wait_w\s*&&",
        ),
        "buffer_wait_gate": _match(
            backend,
            r"\bwire\s+live_grant_buffer_w\s*=\s*!mem_req_singleton_wait_w\s*&&",
        ),
        "effective_singleton": _match(
            backend,
            r"\bwire\s+mem_req_effective_singleton_w\s*=\s*"
            r"grant_sq_w\s*\|\|\s*grant_amo_write_w\s*\|\|\s*"
            r"grant_buffer_w\s*\|\|\s*"
            r"\(\s*grant_issue0_w\s*&&\s*issue0_is_amo_w\s*\)\s*;",
        ),
        "bank1_retry_excludes_singleton": _match(
            backend,
            r"\bwire\s+live_grant_retry1_w\s*=.*?"
            r"!mem_req_effective_singleton_w\s*&&.*?mem_retry1_req_valid_w\s*;",
        ),
        "bank1_issue0_excludes_singleton": _match(
            backend,
            r"\bwire\s+live_grant_mem1_issue0_w\s*=.*?"
            r"!mem_req_effective_singleton_w\s*&&.*?issue0_dual_selected_w\s*&&",
        ),
        "bank1_issue1_excludes_singleton": _match(
            backend,
            r"\bwire\s+live_grant_mem1_issue1_w\s*=.*?"
            r"!mem_req_effective_singleton_w\s*&&.*?issue1_dual_selected_w\s*&&",
        ),
    }
    return all(facts.values()), facts


def _dual_sq_common(backend: str) -> tuple[bool, dict[str, int]]:
    counts = {
        "fill1": len(re.findall(
            r"\.fill1_valid_i\s*\(\s*sq_fill1_valid_w\s*\)", backend)),
        "terminal1": len(re.findall(
            r"\.terminal1_valid_i\s*\(\s*sq_terminal1_valid_w\s*\)",
            backend,
        )),
        "both_miq_empty": len(re.findall(
            r"mem_legacy_slot_open_w\s*&&\s*miq_empty_w\s*&&\s*miq1_empty_w",
            backend,
        )),
        "dual_release_no_lookthrough": len(re.findall(
            r"wire\s+mem_legacy_slot_open_w\s*=\s*ENABLE_DUAL_MEM\s*\?\s*"
            r"!mem_pending_q\s*:",
            backend,
            flags=re.DOTALL | re.MULTILINE,
        )),
    }
    return all(value == 1 for value in counts.values()), counts


def evaluate(sources: dict[str, str]) -> list[Any]:
    checks = list(LEGACY.evaluate(sources))
    target = "backend.dual_sq_ports_and_singleton_exclusion"
    indexes = [index for index, item in enumerate(checks) if item.check_id == target]
    if len(indexes) != 1:
        raise RuntimeError(f"immutable V8S checker target inventory drifted: {indexes}")
    index = indexes[0]
    legacy = checks[index]
    common_passed, common = _dual_sq_common(sources["backend"])
    current_passed, facts = _hold_aware_singleton_exclusion(sources["backend"])
    checks[index] = Check(
        target,
        legacy.passed or (common_passed and current_passed),
        f"legacy={legacy.passed} common={common} hold_aware={facts}",
    )
    return checks


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo-root", type=pathlib.Path, required=True)
    parser.add_argument("--json-out", type=pathlib.Path)
    args = parser.parse_args()

    sources = load_sources(args.repo_root)
    checks = evaluate(sources)
    terminal_stage, terminal_fragments = terminal_topology(sources["backend"])
    payload = {
        "schema": "rv64-v8s-f2-source-check-v1",
        "passed": all(item.passed for item in checks),
        "detected_extension_stage": terminal_stage,
        "terminal_topology": terminal_fragments,
        "current_adapter": "registered-request-hold-v1",
        "checks": [asdict(item) for item in checks],
    }
    if args.json_out:
        args.json_out.parent.mkdir(parents=True, exist_ok=True)
        args.json_out.write_text(
            json.dumps(payload, indent=2, sort_keys=True) + "\n",
            encoding="utf-8",
        )
    for item in checks:
        status = "PASS" if item.passed else "FAIL"
        print(f"[V8S-CURRENT-CHECK][{status}] {item.check_id}: {item.detail}")
    if payload["passed"]:
        print("[V8S-CURRENT-CHECK][PASS] registered-request-hold source closure")
        return 0
    print("[V8S-CURRENT-CHECK][FAIL] source closure rejected", file=sys.stderr)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
