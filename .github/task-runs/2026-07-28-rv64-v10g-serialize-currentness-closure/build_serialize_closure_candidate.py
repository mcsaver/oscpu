#!/usr/bin/env python3
"""Build the current-design SERIALIZE-G1 independent-review candidate."""

from __future__ import annotations

import hashlib
import json
import re
import subprocess
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[3]
RUN_DIR = Path(__file__).resolve().parent
CURRENT_ID = (
    "sha256:5f9dd06860a91dfc5461357c731fa2d4c34b91cb3b3cdedc754f0972f8bf4c5a"
)
PRIOR_ID = (
    "sha256:c1b5317212bfe47e507eac83a28dff405527f50493e3709e96ffbec2dc3bb594"
)
SEMANTIC = RUN_DIR / "semantic-delta-identity.json"
SYSTEM_MATRIX = RUN_DIR / "system-current-matrix/summary.json"
QH_MUTATION = RUN_DIR / "mutations/qh-csr-c2-replay-v2/summary.json"
REPLAY_DIR = RUN_DIR / "current-replay"
V10D_DIR = (
    ROOT
    / ".github/task-runs/2026-07-27-rv64-v10d-simulation-exit-exactly-once"
)
V10D_ROUND = V10D_DIR / "round-state.json"
V10D_MUTATION = V10D_DIR / "mutations/summary.json"
OUTPUT = RUN_DIR / "serialize-g1-closure-candidate.json"


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def sha256(path: Path) -> str:
    value = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            value.update(chunk)
    return value.hexdigest()


def load_json(path: Path) -> dict[str, Any]:
    require(path.is_file(), f"missing JSON evidence: {path}")
    value = json.loads(path.read_text(encoding="utf-8"))
    require(isinstance(value, dict), f"JSON root is not an object: {path}")
    return value


def relative(path: Path) -> str:
    return path.relative_to(ROOT).as_posix()


def evidence_file(path: Path) -> dict[str, Any]:
    require(path.is_file(), f"missing evidence file: {path}")
    return {
        "path": relative(path),
        "sha256": sha256(path),
        "size_bytes": path.stat().st_size,
    }


def require_exact_count(text: str, marker: str, count: int, context: str) -> None:
    actual = text.count(marker)
    require(
        actual == count,
        f"{context}: marker count {actual} != {count}: {marker}",
    )


def validate_qh_log(path: Path, mode: str) -> dict[str, Any]:
    text = path.read_text(encoding="utf-8", errors="replace")
    require("[CHECK-FAIL]" not in text, f"{mode}: queue-head CSR CHECK-FAIL")
    require_exact_count(text, "[RESULT] PASS", 1, mode)
    expected_committed = (
        "ecall handler queue-head CSR",
        "older-store queue-head CSR",
        "CSR/JALR callback chain",
    )
    expected_killed = (
        "branch-recovery wrong-path CSR",
        "JALR-recovery wrong-path CSR",
    )
    for label in expected_committed:
        require_exact_count(
            text,
            (
                f"[V10G-QH-CSR-RAW] {label} "
                "birth=1 C0_commit=1 C0_barrier=1 "
                "C1_apply=1 C2_quiet=1 PASS"
            ),
            1,
            mode,
        )
    for label in expected_killed:
        require_exact_count(
            text,
            (
                f"[V10G-QH-CSR-KILL] {label} "
                "birth=1 selective_kill=1 C0=0 C1=0 PASS"
            ),
            1,
            mode,
        )
    return {
        **evidence_file(path),
        "mode": mode,
        "committed_transactions": len(expected_committed),
        "selectively_killed_transactions": len(expected_killed),
        "raw_c0_c1_c2_exact": True,
    }


def validate_qh_mutation() -> dict[str, Any]:
    value = load_json(QH_MUTATION)
    require(value["status"] == "PASS", "queue-head CSR mutation is not PASS")
    require(value["design_id"] == CURRENT_ID, "queue-head mutation RTL ID drift")
    require(value["mutation"]["compile_success"] is True, "mutation did not compile")
    require(len(value["cases"]) == 2, "unexpected queue-head mutation case count")
    old_case, current_case = value["cases"]
    require(
        old_case["name"] == "pre-scoreboard-release"
        and old_case["compile_returncode"] == 0
        and old_case["simulation_returncode"] == 0
        and old_case["pass_marker"] is True
        and old_case["scoreboard_reject_marker"] is False,
        "pre-scoreboard false-green control is not exact",
    )
    require(
        current_case["name"] == "current-scoreboard-release"
        and current_case["compile_returncode"] == 0
        and current_case["simulation_returncode"] == 1
        and current_case["pass_marker"] is False
        and current_case["scoreboard_reject_marker"] is True
        and current_case["unowned_reject_marker"] is True,
        "current raw scoreboard did not reject C2 replay exactly",
    )
    return {
        **evidence_file(QH_MUTATION),
        "compile_success": True,
        "old_sticky_scoreboard_false_green": True,
        "current_raw_scoreboard_rejected": True,
        "production_rtl_sha256": value["mutation"]["production_sha256"],
        "mutated_rtl_sha256": value["mutation"]["mutated_sha256"],
        "current_testbench_sha256": current_case["testbench_sha256"],
    }


def validate_system_matrix() -> dict[str, Any]:
    value = load_json(SYSTEM_MATRIX)
    require(value["schema"] == "rv64-v10g-system-current-matrix-v1", "matrix schema")
    require(value["design_id"] == CURRENT_ID, "SYSTEM matrix RTL ID drift")
    require(value["all_pass"] is True, "SYSTEM matrix is not all-pass")
    baselines = [case for case in value["cases"] if case["expect_pass"]]
    mutations = [case for case in value["cases"] if not case["expect_pass"]]
    require(len(baselines) == 3, f"unexpected SYSTEM baseline count: {len(baselines)}")
    require(len(mutations) == 14, f"unexpected SYSTEM mutation count: {len(mutations)}")
    require(
        all(
            case["compile_returncode"] == 0
            and case["make_returncode"] == 0
            and case["result_pass"]
            and case["passed"]
            for case in baselines
        ),
        "SYSTEM baseline did not pass exactly",
    )
    require(
        all(
            case["compile_returncode"] == 0
            and case["simulation_rejected"]
            and case["result_fail"]
            and case["passed"]
            for case in mutations
        ),
        "SYSTEM compile-success mutation was not dynamically rejected",
    )
    require(value["compile_success_mutations"] == 14, "compile-success count drift")
    require(value["dynamically_rejected_mutations"] == 14, "rejection count drift")
    return {
        **evidence_file(SYSTEM_MATRIX),
        "design_id": value["design_id"],
        "baseline_pass": f"{len(baselines)}/{len(baselines)}",
        "compile_success_mutations": "14/14",
        "dynamically_rejected_mutations": "14/14",
        "testbench_sha256_map": value["testbench_sha256_map"],
    }


def file_birth_epoch(path: Path) -> int:
    result = subprocess.run(
        ["stat", "-c", "%W", str(path)],
        check=True,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    value = int(result.stdout.strip())
    require(value > 0, f"filesystem birth time unavailable: {path}")
    return value


def validate_current_replay() -> dict[str, Any]:
    replay_status = REPLAY_DIR / "replay.status"
    task_status = REPLAY_DIR / "task-run.status"
    driver = REPLAY_DIR / "driver.log"
    status_text = replay_status.read_text(encoding="utf-8")
    task_text = task_status.read_text(encoding="utf-8").strip()
    driver_text = driver.read_text(encoding="utf-8", errors="replace")
    require("state=PASS\nstage=complete\n" in status_text, "replay status is not PASS")
    require(f"design_id={CURRENT_ID}" in status_text, "replay status design ID drift")
    require("closed_evidence=current" in status_text, "closed evidence not current")
    require("SERIALIZE-G1=OPEN" in status_text, "pre-review debt status changed")
    require(task_text == "PASS", "task-run status is not PASS")
    require("[V10C-REPLAY][FAIL]" not in driver_text, "replay driver contains FAIL")
    require_exact_count(
        driver_text,
        (
            f"[V10C-REPLAY][PASS] design_id={CURRENT_ID} "
            "closed_evidence=current SERIALIZE-G1=OPEN"
        ),
        1,
        "current replay",
    )

    logs = sorted((REPLAY_DIR / "stage-logs").glob("*.log"))
    require(len(logs) == 26, f"unexpected replay stage-log count: {len(logs)}")
    log_evidence = {path.name: evidence_file(path) for path in logs}
    birth = file_birth_epoch(driver)
    completion = int(driver.stat().st_mtime)
    elapsed = completion - birth
    require(
        1_800 <= elapsed < 4 * 60 * 60,
        f"unexpected current replay elapsed seconds: {elapsed}",
    )
    return {
        "status": evidence_file(replay_status),
        "task_status": evidence_file(task_status),
        "driver": evidence_file(driver),
        "design_id": CURRENT_ID,
        "stage_count": len(logs),
        "stage_logs": log_evidence,
        "driver_birth_epoch": birth,
        "completion_epoch": completion,
        "elapsed_seconds_from_filesystem": elapsed,
        "parent_command_wall_seconds": 2006.2,
        "cost_class_actual": "greater-than-30-minutes-less-than-4-hours",
        "prelaunch_gates": {
            "necessity": "bind all closed architecture evidence to live RTL",
            "information_gain": "distinguish stale evidence from current closure input",
            "single_flight": True,
            "stop_on_stage_failure_or_design_drift": True,
            "user_authorization_required": False,
        },
    }


def validate_v10d() -> dict[str, Any]:
    round_state = load_json(V10D_ROUND)
    mutation = load_json(V10D_MUTATION)
    require(
        round_state["status"] == "APPROVED_FOR_CURRENT_SCOPE_RECORD_CLOSED",
        "V10D record is not approved and closed",
    )
    require(
        round_state["implementation"]["current_design_id"] == PRIOR_ID,
        "V10D prior design ID drift",
    )
    require(mutation["passed"] is True, "V10D mutations are not PASS")
    require(
        mutation["total_count"] == 7 and mutation["rejected_count"] == 7,
        "V10D mutation rejection count drift",
    )
    require(
        all(
            item["compile_success"]
            and item["rejected"]
            and item["marker_observed"]
            for item in mutation["mutations"]
        ),
        "V10D mutation sensitivity is incomplete",
    )
    for name, expected_digest in mutation["production_rtl_sha256"].items():
        require(
            sha256(ROOT / name) == expected_digest,
            f"V10D production RTL applicability drift: {name}",
        )
    require(
        sha256(ROOT / mutation["testbench"]) == mutation["testbench_sha256"],
        "V10D focused testbench applicability drift",
    )

    configurations: dict[str, Any] = {}
    for mode in ("focused-assert", "focused-release"):
        log_dir = V10D_DIR / mode / "result/logs"
        logs = sorted(log_dir.glob("*.log"))
        require(len(logs) == 5, f"{mode}: expected 5 focused logs")
        for path in logs:
            text = path.read_text(encoding="utf-8", errors="replace")
            require("[CHECK-FAIL]" not in text, f"{mode}: CHECK-FAIL in {path.name}")
            require("[RESULT] PASS" in text, f"{mode}: no PASS in {path.name}")
        configurations[mode] = {
            "pass": "5/5",
            "logs": {path.name: evidence_file(path) for path in logs},
        }
    return {
        "prior_design_id": PRIOR_ID,
        "current_design_applicability": {
            "production_files_exact": len(mutation["production_rtl_sha256"]),
            "focused_testbench_exact": True,
            "production_semantic_delta": "NONE",
            "applicable": True,
        },
        "focused": configurations,
        "compile_success_mutations": "7/7",
        "mutations": evidence_file(V10D_MUTATION),
        "round_state": evidence_file(V10D_ROUND),
        "remaining_assumption": round_state["final_review_v1"][
            "remaining_assumption"
        ],
    }


def extract_default(path: Path, pattern: str, label: str) -> int:
    text = path.read_text(encoding="utf-8")
    match = re.search(pattern, text, re.MULTILINE)
    require(match is not None, f"cannot locate {label} default")
    return int(match.group(1))


def main() -> int:
    semantic = load_json(SEMANTIC)
    require(semantic["status"] == "PASS", "semantic identity is not PASS")
    require(
        semantic["identity"]["aggregate_rtl_source_set"]["current_design_id"]
        == CURRENT_ID,
        "semantic identity current RTL ID drift",
    )
    require(
        semantic["semantic_delta"]["production_design_rtl_changed"] is False,
        "production design RTL changed",
    )
    require(
        semantic["evidence_state"]["full_system_rerun_required"] == "NO",
        "unexpected full-system rerun requirement",
    )

    qh_logs = {
        "assertions_on": validate_qh_log(
            RUN_DIR
            / "focused-assert/logs/tb_ooo_core_top_glue_v9o_csr_qh.log",
            "assertions-on",
        ),
        "assertions_off": validate_qh_log(
            RUN_DIR
            / "focused-release/logs/tb_ooo_core_top_glue_v9o_csr_qh.log",
            "assertions-off",
        ),
    }
    qh_mutation = validate_qh_mutation()
    system_matrix = validate_system_matrix()
    replay = validate_current_replay()
    v10d = validate_v10d()

    makefile_default = extract_default(
        ROOT / "npc/rv64/Makefile",
        r"^OOO_CSR_QUEUE_HEAD\s*\?=\s*([01])\s*$",
        "npc Makefile OOO_CSR_QUEUE_HEAD",
    )
    rtl_fallback = extract_default(
        ROOT / "npc/rv64/vsrc/include/define.v",
        r"^`define\s+OOO_CSR_QUEUE_HEAD\s+1'b([01])\s*$",
        "RTL OOO_CSR_QUEUE_HEAD",
    )
    product_config = semantic["identity"]["configuration"]["OOO_CSR_QUEUE_HEAD"]
    require(product_config == 1, "A3 product recert did not enable queue-head CSR")

    result = {
        "schema": "npc-rv64-serialize-g1-closure-candidate/v1",
        "status": "READY_FOR_INDEPENDENT_REVIEW",
        "design_id": CURRENT_ID,
        "classification": {
            "primary": "verification",
            "secondary": ["architecture", "tooling-workflow"],
            "production_rtl_edit": False,
            "testbench_edit": True,
        },
        "debt": {
            "id": "SERIALIZE-G1",
            "priority": "P1",
            "pre_review_status": "OPEN",
            "closure_requirement": (
                "close and enable queue-head serialize contract, or normatively "
                "freeze pending full-drain product architecture"
            ),
        },
        "candidate_architecture": {
            "queue_head_domain": {
                "scope": "legal non-FP head0 CSR",
                "birth": "head0_csr_dispatch_fire_w",
                "c0": [
                    "head0_csr_commit_w exactly once",
                    "CSR architectural request exactly once",
                    "typed CSR_COMMIT full-flush barrier exactly once",
                ],
                "c1": [
                    "typed CSR_COMMIT apply exactly once",
                    "head0 CSR holder clear",
                    "stop owner clear",
                ],
                "c2": [
                    "no repeated CSR architectural request",
                    "no repeated typed apply",
                    "no unowned apply",
                ],
                "recovery": (
                    "wrong-path branch/JALR kill has one birth and selective "
                    "death with zero C0/C1 side effects"
                ),
            },
            "pending_full_drain_domain": {
                "scope": [
                    "lane1 CSR",
                    "FP CSR",
                    "ECALL/EBREAK",
                    "MRET/SRET",
                    "WFI",
                    "SFENCE.VMA/Svinval",
                    "architectural trap/IRQ/fetch fault",
                    "simulation exit",
                ],
                "contract": (
                    "single pending owner; exact memory-terminal or pending-only "
                    "C0; owner/stop clear at C1; no unowned repeat at C2"
                ),
                "retained": True,
            },
            "no_deduplication_mask": True,
            "assertions_weakened": False,
        },
        "queue_head_csr_evidence": {
            "focused": qh_logs,
            "oracle_sensitivity": qh_mutation,
        },
        "pending_system_evidence": system_matrix,
        "trap_exit_evidence": v10d,
        "current_design_replay": replay,
        "layered_identity_and_a3_oracle": evidence_file(SEMANTIC),
        "configuration_boundary": {
            "a3_product_recert_OOO_CSR_QUEUE_HEAD": product_config,
            "npc_makefile_default": makefile_default,
            "rtl_fallback_default": rtl_fallback,
            "architecture_docs_describe_default_off": True,
            "review_question": (
                "Does authoritative product configuration=1 satisfy enabled, "
                "or must repository defaults and normative docs change before "
                "SERIALIZE-G1 may close?"
            ),
        },
        "system_observation_boundary": {
            "a3": {
                "cycles": semantic["a3"]["cycles"],
                "commits": semantic["a3"]["commits"],
                "terminal_counts": semantic["a3"]["terminal_counts"],
                "rtl_assertion_file_empty": True,
                "original_published_gate": "FAIL",
                "execution_state": "COMPLETE",
                "oracle_state": "INVALID",
                "versioned_checker_replay": "PASS",
            },
            "proves": "system transaction completion under queue-head CSR config",
            "does_not_prove": "internal C0/C1/C2 microcycle uniqueness",
            "full_system_rerun_required": "NO",
        },
        "review_acceptance": {
            "approved": (
                "all source identities, raw counters, mutation sensitivity, "
                "pending-system matrix, trap/exit applicability and product "
                "configuration boundary support the normative split"
            ),
            "gap": (
                "name the exact missing cycle/configuration/owner counterexample "
                "and keep SERIALIZE-G1 OPEN"
            ),
            "prohibited": [
                "use deduplication to hide repeated terminal events",
                "weaken RTL assertions",
                "reinterpret A3 original FAIL as historical PASS",
                "use A4 TERM as system PASS evidence",
                "claim architecture freeze or PPA qualification",
            ],
        },
        "promotion": {
            "serialize_g1": "OPEN_PENDING_REVIEW",
            "architecture_freeze": "GAP",
            "ppa": "UNQUALIFIED",
            "eligible": False,
        },
    }
    OUTPUT.write_text(
        json.dumps(result, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    print(
        "[V10G-SERIALIZE-CANDIDATE] "
        f"design_id={CURRENT_ID} qh=2x5 "
        "system=3/3+14/14 v10d=2x5+7/7 "
        f"replay_stages={replay['stage_count']} "
        f"default={makefile_default} product_config={product_config} "
        "READY_FOR_INDEPENDENT_REVIEW"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
