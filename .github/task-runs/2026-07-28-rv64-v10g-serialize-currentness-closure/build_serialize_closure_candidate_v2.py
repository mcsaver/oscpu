#!/usr/bin/env python3
"""Build the product-default SERIALIZE-G1 independent-review candidate."""

from __future__ import annotations

import hashlib
import importlib.util
import json
import pathlib
import sys
from typing import Any


RUN_DIR = pathlib.Path(__file__).resolve().parent
ROOT = RUN_DIR.parents[2]
CURRENT_ID = (
    "sha256:"
    "04c5458ff274b7b30e0629fc20ccef4ffa958dee3b80595ee4b46faf17a73897"
)
PRODUCT_IDENTITY = RUN_DIR / "product-default-identity.json"
SEMANTIC_IDENTITY = RUN_DIR / "semantic-delta-identity.json"
QH_FALLBACK = RUN_DIR / "product-default-qh-fallback-v1/summary.json"
APPLY_MUTATION = RUN_DIR / "mutations/qh-csr-c2-replay-v5/summary.json"
CSRFILE_MUTATION = (
    RUN_DIR / "mutations/qh-csrfile-c2-replay-v2/summary.json"
)
SYSTEM_MATRIX = RUN_DIR / "system-product-default-matrix-v2/summary.json"
REPLAY = RUN_DIR / "product-default-current-replay"
OUTPUT = RUN_DIR / "serialize-g1-closure-candidate-v2.json"
OLD_BUILDER = RUN_DIR / "build_serialize_closure_candidate.py"
DOCS = (
    ROOT / "npc/rv64/design/arch/ooo-core-architecture.md",
    ROOT / "npc/rv64/design/arch/ROADMAP.md",
    ROOT / "npc/rv64/design/arch/serialize-at-retire.md",
    ROOT / "npc/rv64/design/arch/serialize-at-retire-phase1.md",
    ROOT / "npc/rv64/design/arch/rtl-ground-truth-2026-07-11.md",
)


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def sha256(path: pathlib.Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def relative(path: pathlib.Path) -> str:
    return path.relative_to(ROOT).as_posix()


def evidence(path: pathlib.Path) -> dict[str, Any]:
    require(path.is_file(), f"missing evidence: {path}")
    return {
        "path": relative(path),
        "sha256": sha256(path),
        "size_bytes": path.stat().st_size,
    }


def load(path: pathlib.Path) -> dict[str, Any]:
    value = json.loads(path.read_text(encoding="utf-8"))
    require(isinstance(value, dict), f"JSON root is not object: {path}")
    return value


def live_design_id() -> str:
    sys.path.insert(0, str(ROOT / "npc/rv64/eval/ppa/tools"))
    import architecture_hard_gates as architecture

    return f"sha256:{architecture.rtl_binding(ROOT)[0]}"


def validate_identity() -> dict[str, Any]:
    product = load(PRODUCT_IDENTITY)
    semantic = load(SEMANTIC_IDENTITY)
    require(product["status"] == "PASS", "product identity is not PASS")
    require(
        product["current_design_id"] == CURRENT_ID,
        "product identity design ID drift",
    )
    require(live_design_id() == CURRENT_ID, "live RTL design ID drift")
    require(
        product["product_config"]["receipt"]["OOO_CSR_QUEUE_HEAD"] == "1",
        "product receipt queue-head value drift",
    )
    require(
        product["product_config"]["receipt"]["OOO_TERMINAL_HOLDER_ASSERT"]
        == "1",
        "product receipt holder-assert value drift",
    )
    require(
        product["active_elaborated_rtl"]["exact"]["differences"] == [],
        "A4/product generated RTL exact identity drift",
    )
    require(
        product["active_elaborated_rtl"]["source_location_normalized"][
            "logic_changed"
        ]
        is False,
        "A4/product elaborated logic changed",
    )
    require(
        product["host_and_device_execution"]["device_objects_changed"]
        is False,
        "device object identity changed",
    )
    require(
        product["host_and_device_execution"]["cpu_exec_o"]["changed"]
        is False,
        "host execution object identity changed",
    )
    decision = product["system_recert_decision"]
    require(
        decision
        == {
            "production_core_semantics_changed_relative_to_a4": False,
            "active_elaborated_rtl_logic_changed_relative_to_a4": False,
            "device_model_execution_semantics_changed": False,
            "host_harness_execution_semantics_changed": False,
            "a3_required_raw_evidence_missing": False,
            "full_system_rerun_required": "NO",
            "launch_authorization_state": "NOT_REQUIRED",
            "rerun_reason": "NONE",
        },
        "system recertification decision drift",
    )
    expected_a3_state = {
        "published_gate_state": "FAIL",
        "execution_state": "COMPLETE",
        "dut_terminal_state": "COMPLETE",
        "binding_state": "NO_DRIFT",
        "raw_artifact_state": "VALID",
        "rtl_assertion_state": "CLEAN",
        "oracle_state": "INVALID",
        "evidence_replayable": "YES",
        "full_system_rerun_required": "NO",
        "launch_authorization_state": "NOT_REQUIRED",
        "rerun_reason": "NONE",
    }
    require(
        semantic["evidence_state"] == expected_a3_state,
        "A3 state-vector drift",
    )
    require(
        semantic["a3"]["original_status_preserved"] is True,
        "A3 original status was not preserved",
    )
    return {
        "product_default_identity": evidence(PRODUCT_IDENTITY),
        "a3_semantic_identity": evidence(SEMANTIC_IDENTITY),
        "current_design_id": CURRENT_ID,
        "active_generated_rtl_exact": "51/51",
        "device_objects_exact": "8/8",
        "host_execution_object_exact": True,
        "a3_state": expected_a3_state,
        "a3_cycles": semantic["a3"]["cycles"],
        "a3_commits": semantic["a3"]["commits"],
        "a3_terminal_counts": semantic["a3"]["terminal_counts"],
        "a3_rtl_assertion_file_empty":
            semantic["a3"]["rtl_assertion_file_empty"],
        "system_recertification": decision,
    }


def validate_qh_fallback() -> dict[str, Any]:
    value = load(QH_FALLBACK)
    require(value["status"] == "PASS", "queue-head fallback is not PASS")
    require(value["design_id"] == CURRENT_ID, "queue-head fallback ID drift")
    require(
        value["product_config"]["OOO_CSR_QUEUE_HEAD"] == 1
        and value["product_config"]["command_line_override"] is False,
        "queue-head fallback configuration drift",
    )
    require(len(value["cases"]) == 2, "queue-head fallback case count drift")
    require(
        all(
            case["compile_returncode"] == 0
            and case["simulation_returncode"] == 0
            and case["queue_head_command_define_present"] is False
            and case["fallback_value"] == 1
            and case["markers"]
            == {"committed": 3, "selectively_killed": 2}
            and case["passed"]
            for case in value["cases"]
        ),
        "queue-head fallback assert/release evidence drift",
    )
    return {
        **evidence(QH_FALLBACK),
        "assertions_on_off": "2/2",
        "command_line_override": False,
        "rtl_fallback": 1,
        "committed_transactions": "3 per mode",
        "selectively_killed_transactions": "2 per mode",
        "raw_contract": (
            "birth=1; C0 commit/barrier/CsrFile request=1; "
            "C1 apply=1; C2 quiet=1"
        ),
    }


def validate_apply_mutation() -> dict[str, Any]:
    value = load(APPLY_MUTATION)
    require(value["status"] == "PASS", "typed-apply mutation is not PASS")
    require(value["design_id"] == CURRENT_ID, "typed-apply mutation ID drift")
    require(
        value["product_default_binding"]["command_line_override"] is False,
        "typed-apply mutation did not use fallback",
    )
    old_case, current_case = value["cases"]
    require(
        old_case["compile_returncode"] == 0
        and old_case["simulation_returncode"] == 0
        and old_case["pass_marker"],
        "typed-apply false-green control drift",
    )
    require(
        current_case["compile_returncode"] == 0
        and current_case["simulation_returncode"] == 1
        and not current_case["pass_marker"]
        and current_case["c2_request_apply_reject_count"] == 3
        and current_case["unowned_apply_reject_count"] == 3,
        "typed-apply current raw rejection drift",
    )
    return {
        **evidence(APPLY_MUTATION),
        "compile_success": True,
        "pre_scoreboard_false_green": True,
        "current_raw_scoreboard_rejected": True,
        "C2_reject_markers": 3,
        "unowned_reject_markers": 3,
        "command_line_override": False,
    }


def validate_csrfile_mutation() -> dict[str, Any]:
    value = load(CSRFILE_MUTATION)
    require(value["status"] == "PASS", "CsrFile mutation is not PASS")
    require(value["design_id"] == CURRENT_ID, "CsrFile mutation ID drift")
    require(
        value["product_config"]["command_line_override"] is False,
        "CsrFile mutation did not use fallback",
    )
    run = value["run"]
    require(
        run["compile_returncode"] == 0
        and run["simulation_returncode"] == 1
        and not run["baseline_pass_marker"]
        and run["unowned_csrfile_request_rejected"]
        and run["c2_request_apply_rejected"],
        "CsrFile C2 replay was not rejected exactly",
    )
    require(
        value["production_binding"]["exact_occurrences"] == 1,
        "NpcCoreTop CsrFile binding count drift",
    )
    return {
        **evidence(CSRFILE_MUTATION),
        "compile_success": True,
        "current_raw_scoreboard_rejected": True,
        "production_binding": value["production_binding"],
        "command_line_override": False,
    }


def validate_system_matrix() -> dict[str, Any]:
    value = load(SYSTEM_MATRIX)
    require(
        value["schema"] == "rv64-v10g-system-product-default-matrix-v2",
        "pending-SYSTEM matrix schema drift",
    )
    require(value["design_id"] == CURRENT_ID, "SYSTEM matrix ID drift")
    require(value["all_pass"] is True, "SYSTEM matrix is not PASS")
    require(
        value["product_default_binding"]["status"] == "PASS"
        and value["product_default_binding"]["OOO_CSR_QUEUE_HEAD"] == 1
        and value["product_default_binding"]["command_line_override"]
        is False,
        "SYSTEM product-default binding drift",
    )
    baselines = [case for case in value["cases"] if case["expect_pass"]]
    mutations = [case for case in value["cases"] if not case["expect_pass"]]
    require(
        len(baselines) == 3
        and all(
            case["compile_returncode"] == 0
            and case["make_returncode"] == 0
            and case["result_pass"]
            and case["passed"]
            for case in baselines
        ),
        "SYSTEM baseline drift",
    )
    require(
        len(mutations) == 14
        and all(
            case["compile_returncode"] == 0
            and case["make_returncode"] != 0
            and case["result_fail"]
            and case["simulation_rejected"]
            and case["passed"]
            for case in mutations
        ),
        "SYSTEM mutation rejection drift",
    )
    assert_log = ROOT / baselines[0]["result_log"]
    release_log = ROOT / baselines[1]["result_log"]
    for path in (assert_log, release_log):
        text = path.read_text(encoding="utf-8", errors="replace")
        require(
            text.count(
                "[V10B-SATP-MMU] lane1-capture=1 exact-csr-commit=1 "
                "sfence=1 registered-mmu-actions=2 C1=clear "
                "C2=no-repeat PASS"
            )
            == 1,
            f"lane1 SATP marker drift: {path}",
        )
        require(
            text.count(
                "[V10G-PRODUCT-QH-SATP] birth=1 C0_commit=1 "
                "C0_barrier=1 CsrFile_request=1 C1_apply=1 "
                "C2_quiet=1 pending_terminal=0 pending_mmu=0 "
                "backend_drained=1 PASS"
            )
            == 1,
            f"head0 SATP marker drift: {path}",
        )
    return {
        **evidence(SYSTEM_MATRIX),
        "baseline_pass": "3/3",
        "compile_success_mutations": "14/14",
        "dynamically_rejected_mutations": "14/14",
        "lane1_satp_pending_full_drain": "assert/release PASS",
        "head0_satp_queue_head": "assert/release PASS",
        "command_line_override": False,
    }


def validate_replay() -> dict[str, Any]:
    replay_status = REPLAY / "replay.status"
    task_status = REPLAY / "task-run.status"
    driver = REPLAY / "driver.log"
    launch = REPLAY / "launch-gate.json"
    receipt = REPLAY / "product-config-receipt.txt"
    status_text = replay_status.read_text(encoding="utf-8")
    driver_text = driver.read_text(encoding="utf-8", errors="replace")
    launch_value = load(launch)
    require(
        status_text
        == (
            "state=PASS\nstage=complete\n"
            f"detail=design_id={CURRENT_ID};closed_evidence=current;"
            "SERIALIZE-G1=OPEN\n"
        ),
        "product-default replay status drift",
    )
    require(
        task_status.read_text(encoding="utf-8").strip() == "PASS",
        "product-default task status drift",
    )
    require("[V10C-REPLAY][FAIL]" not in driver_text, "replay has FAIL marker")
    require(
        driver_text.count("[V10C-REPLAY][PASS] stage=") == 26,
        "replay stage PASS count drift",
    )
    require(
        driver_text.count(
            f"[V10C-REPLAY][PASS] design_id={CURRENT_ID} "
            "closed_evidence=current SERIALIZE-G1=OPEN"
        )
        == 1,
        "replay terminal marker drift",
    )
    logs = sorted((REPLAY / "stage-logs").glob("*.log"))
    require(len(logs) == 26, "replay stage-log count drift")
    require(launch_value["status"] == "PASS", "replay launch gate drift")
    require(
        launch_value["over_30_minute_gate"]["single_flight"] is True
        and launch_value["over_4_hour_user_authorization"]
        == "NOT_REQUIRED",
        "replay cost gate drift",
    )
    receipt_text = receipt.read_text(encoding="utf-8")
    require(
        "OOO_CSR_QUEUE_HEAD=1\n" in receipt_text
        and "OOO_TERMINAL_HOLDER_ASSERT=1\n" in receipt_text,
        "replay product config receipt drift",
    )
    functional = REPLAY / "stage-logs/functional-aggregate-current.log"
    functional_text = functional.read_text(encoding="utf-8", errors="replace")
    require(
        "[F0-G1-GATE] PASS" in functional_text,
        "functional aggregate gate drift",
    )
    module_summary = (
        ROOT
        / ".github/task-runs/2026-07-23-rv64-v9o-control-event-current-design/"
        "module-aggregate-current/summary.txt"
    )
    module_text = module_summary.read_text(encoding="utf-8")
    require(
        "- total: 113\n- passed: 113\n- failed: 0\n" in module_text,
        "module aggregate count drift",
    )
    return {
        "status": evidence(replay_status),
        "task_status": evidence(task_status),
        "driver": evidence(driver),
        "launch_gate": evidence(launch),
        "product_config_receipt": evidence(receipt),
        "stage_logs": 26,
        "stage_pass": "26/26",
        "module": "113/113",
        "official": "177/177",
        "am_difftest": "59/59; mismatch=0",
        "benchmarks": "CoreMark + Dhrystone + microbench PASS",
        "design_id": CURRENT_ID,
        "wall_seconds": 2005.8,
        "cost_class": "greater-than-30-minutes-less-than-4-hours",
        "single_flight": True,
    }


def validate_trap_exit() -> dict[str, Any]:
    spec = importlib.util.spec_from_file_location(
        "v10g_old_closure_builder_for_v10d", OLD_BUILDER
    )
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot load prior closure builder: {OLD_BUILDER}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    value = module.validate_v10d()
    return {
        **value,
        "current_design_bridge": {
            "product_default_identity": evidence(PRODUCT_IDENTITY),
            "active_elaborated_logic_changed_relative_to_a4": False,
            "product_current_replay_v10d_applicable_stages": [
                "xret-current-mode",
                "vectored-trap",
                "control-event-focused",
                "control-event-mutations",
            ],
            "current_design_id": CURRENT_ID,
        },
    }


def validate_docs() -> dict[str, Any]:
    records = {}
    for path in DOCS:
        text = path.read_text(encoding="utf-8")
        require(
            "OOO_CSR_QUEUE_HEAD=1" in text,
            f"normative product default missing: {path}",
        )
        records[relative(path)] = evidence(path)
    require(
        "OPEN_PENDING_REVIEW"
        in (ROOT / "npc/rv64/design/arch/ROADMAP.md").read_text(
            encoding="utf-8"
        ),
        "ROADMAP review boundary missing",
    )
    return {
        "status": "PASS",
        "normative_product_default": 1,
        "split_domain_documented": True,
        "a3_original_fail_preserved": True,
        "documents": records,
    }


def main() -> int:
    if OUTPUT.exists():
        raise SystemExit(f"refusing to overwrite candidate: {OUTPUT}")
    identity = validate_identity()
    qh = validate_qh_fallback()
    apply_mutation = validate_apply_mutation()
    csrfile_mutation = validate_csrfile_mutation()
    system = validate_system_matrix()
    replay = validate_replay()
    trap_exit = validate_trap_exit()
    docs = validate_docs()

    result = {
        "schema": "npc-rv64-serialize-g1-closure-candidate/v2",
        "status": "READY_FOR_INDEPENDENT_REVIEW",
        "design_id": CURRENT_ID,
        "classification": {
            "primary": "verification",
            "secondary": ["architecture", "tooling-workflow"],
            "production_rtl_edit": False,
            "product_configuration_edit": True,
            "testbench_edit": True,
        },
        "debt": {
            "id": "SERIALIZE-G1",
            "priority": "P1",
            "pre_review_status": "OPEN",
            "requested_review_transition": "CLOSED or named GAP",
        },
        "normative_split": {
            "product_default": {
                "OOO_CSR_QUEUE_HEAD": 1,
                "OOO_TERMINAL_HOLDER_ASSERT": 1,
                "command_line_override_required": False,
                "queue_head_zero_role": "explicit comparison/recovery only",
            },
            "queue_head_domain": {
                "scope": "legal non-FP lane0/head0 CSR",
                "transaction": (
                    "birth -> C0 commit/CsrFile request/typed barrier -> "
                    "C1 typed apply/holder+stop clear -> C2 quiet"
                ),
                "wrong_path": (
                    "selective kill with one birth, one death, zero C0/C1"
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
                "retained": True,
            },
            "satp_position_split": {
                "lane1": "pending/full-drain plus registered MMU pulse",
                "head0": (
                    "queue-head C0/C1; no fabricated pending-SYSTEM MMU pulse"
                ),
            },
            "raw_event_counting": True,
            "deduplication_mask": False,
            "rtl_assertions_weakened": False,
        },
        "evidence": {
            "layered_identity_and_a3": identity,
            "queue_head_fallback_assert_release": qh,
            "typed_apply_c2_mutation": apply_mutation,
            "csrfile_request_c2_mutation": csrfile_mutation,
            "pending_system_product_matrix": system,
            "trap_exit": trap_exit,
            "product_default_current_replay": replay,
            "normative_docs": docs,
        },
        "a3_publication_boundary": {
            "published_gate_state": "FAIL",
            "execution_state": "COMPLETE",
            "dut_terminal_state": "COMPLETE",
            "oracle_state": "INVALID",
            "checker_replay": "PASS",
            "original_status_mutated": False,
            "a4_term_used_as_pass": False,
            "full_system_rerun_required": "NO",
        },
        "review_acceptance": {
            "approve_if": (
                "the product-default split, exact raw C0/C1/C2 counts, "
                "two compile-success C2 replays, pending-SYSTEM matrix, "
                "trap/exit applicability, identities and docs jointly close "
                "SERIALIZE-G1 on the current design"
            ),
            "gap_if": (
                "name an exact uncovered lane/cycle/configuration/owner "
                "counterexample and keep SERIALIZE-G1 OPEN"
            ),
            "prohibited": [
                "deduplicate repeated terminal events",
                "weaken RTL assertions",
                "rewrite A3 original FAIL as PASS",
                "use A4 TERM as system PASS",
                "claim architecture freeze before historical backfill",
                "claim PPA qualification",
            ],
        },
        "promotion_boundary": {
            "serialize_g1": "OPEN_PENDING_INDEPENDENT_REVIEW",
            "architecture_freeze": "GAP",
            "historical_defect_backfill": "NOT_STARTED_UNTIL_P0_P1_CLEAR",
            "ppa": "UNQUALIFIED",
            "promotion_eligible": False,
        },
    }
    OUTPUT.write_text(
        json.dumps(result, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    print(
        "[V10G-SERIALIZE-CANDIDATE-V2] "
        f"design_id={CURRENT_ID} qh_fallback=2x5 "
        "apply_mutation=PASS csrfile_mutation=PASS "
        "system=3/3+14/14 replay=26/26 "
        "READY_FOR_INDEPENDENT_REVIEW"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
