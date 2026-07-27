#!/usr/bin/env python3
"""Build a fail-closed, current-design evidence index for V9O."""

from __future__ import annotations

import argparse
import datetime
import hashlib
import json
import pathlib
import re
import sys
from typing import Any, Iterable

RUN_ID = "2026-07-23-rv64-v9o-control-event-current-design"
SCHEMA = "npc-rv64-control-event-evidence-index-v1"
EXPECTED_GATES = {
    "DI-1", "DI-2", "DI-3", "DI-4", "DI-5",
    "OOO-1", "OOO-2", "OOO-3", "OOO-4",
}

FOCUSED_MARKERS = {
    "tb_ooo_control_event_apply_sequencer": (),
    "tb_ooo_redirect_arbiter": (),
    "tb_ooo_frontend_action_gate": (),
    "tb_ooo_load_queue": (),
    "tb_ooo_rob": (
        "[V9O-FULL-C0-COMPLETION-MATRIX] "
        "classes=8 wrap_head=15 wrap_younger=0 PASS",
    ),
    "tb_ooo_dispatch_backend": (),
    "tb_ooo_int_backend": (
        "[V9O-BACKEND-C0-BARRIER] "
        "younger branch/dispatch/memory actions held PASS",
        "[V9O-PENDING-CSR-BRANCH-PRIORITY] "
        "older action-NONE commit suppresses younger branch PASS",
    ),
    "tb_ooo_mem_axi_bridge": (
        "[V9O-MEM-C0-BARRIER] "
        "pre-owner held; registered AR/AW/W owners preserved PASS",
    ),
    "tb_ooo_dual_mem_bridge_wrapper": (
        "[V9O-DUAL-REGISTERED-AR-BARRIER] "
        "lanes=2 hold_cycles=4 terminals=2 PASS",
    ),
    "tb_ooo_core_top_glue": (
        "[V9O-CONTROL-EVENT-C0-C1] source-to-typed-apply timing PASS",
    ),
}

CONFIG_MARKERS = {
    "tb_ooo_rob": (
        "[V9O-FULL-C0-COMPLETION-MATRIX] "
        "classes=8 wrap_head=15 wrap_younger=0 PASS",
        "[V9O-CSR-OWNER-CLASS-PASS] "
        "exact pending CSR ProducerId classified without full flush",
    ),
    "tb_ooo_core_top_glue_v9o_csr_qh": (
        "[V9O-CSR-QH-CORE-INTEGRATION] "
        "real queue-head CSR C0/C1 PASS",
        "[V9O-PENDING-CSR-OWNER-INTEGRATION] "
        "exact type/PID action-NONE path PASS",
        "[V9O-CSR-MEMORY-ORDER-INTEGRATION] "
        "older drain/younger refetch PASS",
    ),
    "tb_ooo_core_top_glue": (
        "[V9O-CONTROL-EVENT-C0-C1] source-to-typed-apply timing PASS",
    ),
}

PROVENANCE_PATHS = (
    f".github/task-runs/{RUN_ID}/build-evidence-index.py",
    f".github/task-runs/{RUN_ID}/evidence_source_set.py",
    f".github/task-runs/{RUN_ID}/run-focused.sh",
    f".github/task-runs/{RUN_ID}/run-v9o-config-variants.sh",
    f".github/task-runs/{RUN_ID}/run-control-event-rtl-mutations.py",
    f".github/task-runs/{RUN_ID}/run-module-aggregate.sh",
    f".github/task-runs/{RUN_ID}/refresh-architecture-evidence.sh",
    f".github/task-runs/{RUN_ID}/run-arch-stable-boundary.sh",
    f".github/task-runs/{RUN_ID}/contract.md",
    f".github/task-runs/{RUN_ID}/completion-definition.md",
    f".github/task-runs/{RUN_ID}/rtl-derivation.md",
    "npc/rv64/design/specs/ooo-control-event-apply-sequencer.md",
    "npc/rv64/design/specs/ooo-core-top-glue.md",
    "npc/rv64/design/specs/ooo-flush-redirect-contract.md",
    "npc/rv64/design/specs/ooo-frontend-action-gate.md",
    "npc/rv64/design/specs/ooo-load-queue.md",
    "npc/rv64/design/specs/ooo-mem-axi-bridge-fsm.md",
    "npc/rv64/design/specs/ooo-redirect-arbiter.md",
    "npc/rv64/design/specs/ooo-rob.md",
    "npc/rv64/eval/ppa/tools/arch_stable_freeze.py",
    "npc/rv64/eval/ppa/tools/architecture_hard_gates.py",
    "npc/rv64/eval/ppa/tests/test_arch_stable_freeze.py",
    "npc/rv64/eval/ppa/schemas/architecture-debt-ledger-v2.schema.json",
)

FAIL_MARKERS = (
    "[RESULT] FAIL",
    "[CHECK-FAIL]",
    "[TIMEOUT]",
    "FATAL:",
)


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def sha256_file(path: pathlib.Path) -> str:
    return sha256_bytes(path.read_bytes())


def canonical_sha256(value: Any) -> str:
    return sha256_bytes(
        json.dumps(
            value,
            sort_keys=True,
            separators=(",", ":"),
            ensure_ascii=False,
        ).encode("utf-8")
    )


def safe_file(root: pathlib.Path, relative: str) -> pathlib.Path:
    path = (root / relative).resolve(strict=True)
    if not path.is_relative_to(root):
        raise ValueError(f"artifact escapes repository: {relative}")
    if path.is_symlink() or not path.is_file():
        raise ValueError(f"artifact is not a regular file: {relative}")
    return path


def artifact(root: pathlib.Path, relative: str) -> dict[str, Any]:
    path = safe_file(root, relative)
    return {
        "path": relative,
        "sha256": sha256_file(path),
        "size_bytes": path.stat().st_size,
    }


def require_unique(text: str, marker: str, label: str) -> None:
    count = text.count(marker)
    if count != 1:
        raise ValueError(
            f"{label}: marker must appear exactly once: "
            f"{marker!r}, observed={count}"
        )


def validate_pass_log(
    root: pathlib.Path,
    relative: str,
    *,
    test_name: str,
    design_id: str,
    verification_id: str,
    expected_markers: Iterable[str] = (),
) -> dict[str, Any]:
    path = safe_file(root, relative)
    text = path.read_text(encoding="utf-8")
    require_unique(text, "[RESULT] PASS", test_name)
    native_pass_lines = [
        line
        for line in text.splitlines()
        if line in {f"[PASS] {test_name}", f"PASS {test_name}"}
    ]
    if len(native_pass_lines) != 1:
        raise ValueError(
            f"{test_name}: native PASS line must appear exactly once, "
            f"observed={len(native_pass_lines)}"
        )
    require_unique(text, f"[RTL-DESIGN-ID] {design_id}", test_name)
    require_unique(
        text,
        f"[V9O-VERIFICATION-SOURCE-ID] sha256:{verification_id}",
        test_name,
    )
    for marker in expected_markers:
        require_unique(text, marker, test_name)
    present_failures = [marker for marker in FAIL_MARKERS if marker in text]
    if present_failures:
        raise ValueError(
            f"{test_name}: failure markers present: {present_failures}"
        )
    return artifact(root, relative)


def parse_module_summary(text: str) -> tuple[list[str], int, int, int]:
    passed = re.findall(r"^- PASS ([A-Za-z0-9_]+)$", text, re.MULTILINE)
    values: dict[str, int] = {}
    for key in ("total", "passed", "failed"):
        matches = re.findall(rf"^- {key}: ([0-9]+)$", text, re.MULTILINE)
        if len(matches) != 1:
            raise ValueError(f"module summary has no exact {key} count")
        values[key] = int(matches[0])
    return passed, values["total"], values["passed"], values["failed"]


def validate_static_contract(root: pathlib.Path) -> dict[str, bool]:
    glue = safe_file(
        root, "npc/rv64/vsrc/core/OooCoreTopGlue.v"
    ).read_text(encoding="utf-8")
    rob_tb = safe_file(
        root, "npc/rv64/testbench/tests/tb_ooo_rob.sv"
    ).read_text(encoding="utf-8")
    dual_tb = safe_file(
        root,
        "npc/rv64/testbench/tests/tb_ooo_dual_mem_bridge_wrapper.sv",
    ).read_text(encoding="utf-8")
    checks = {
        "single_c0_request_valid_source": (
            glue.count(
                "assign control_event_request_valid_w = "
                "control_full_flush_barrier_w;"
            ) == 1
        ),
        "single_c0_request_reason_source": (
            glue.count(
                "assign control_event_request_reason_w = "
                "control_full_flush_reason_w;"
            ) == 1
        ),
        "trap_pregrant_bidirectional_assertion": (
            glue.count("[V9O-CONTROL-EVENT-TRAP-EQUIV]") == 1
        ),
        "csr_pregrant_bidirectional_assertion": (
            glue.count("[V9O-CONTROL-EVENT-CSR-EQUIV]") == 1
        ),
        "completion_matrix_has_eight_classes": (
            "exercise_v9o_full_pregrant_completion_matrix" in rob_tb
            and "classes=8 wrap_head=15 wrap_younger=0 PASS" in rob_tb
            and "completion7_query_valid_i" in rob_tb
        ),
        "dual_registered_ar_barrier_oracle": (
            "v9o_dual_registered_ar_barrier" in dual_tb
            and "lanes=2 hold_cycles=4 terminals=2 PASS" in dual_tb
        ),
    }
    failed = sorted(name for name, value in checks.items() if not value)
    if failed:
        raise ValueError(f"static control-event contract failed: {failed}")
    return checks


def verify_index(
    root: pathlib.Path,
    run_dir: pathlib.Path,
) -> int:
    index_path = safe_file(
        root, f".github/task-runs/{RUN_ID}/evidence-index.json"
    )
    payload = json.loads(index_path.read_text(encoding="utf-8"))
    if payload.get("schema") != SCHEMA or payload.get("status") != "PASS":
        raise ValueError("evidence index schema/status is invalid")
    canonical_payload = dict(payload)
    expected_provenance = canonical_payload.pop("provenance_sha256", None)
    if expected_provenance != canonical_sha256(canonical_payload):
        raise ValueError("evidence index provenance SHA-256 is invalid")
    provenance = payload.get("provenance")
    if (
        not isinstance(provenance, dict)
        or set(provenance) != set(PROVENANCE_PATHS)
    ):
        raise ValueError("evidence index provenance inventory is not exact")

    sys.path.insert(0, str(run_dir))
    import evidence_source_set

    rtl_sha, rtl_files = evidence_source_set.rtl_binding(root)
    verification_sha, verification_files = (
        evidence_source_set.verification_binding(root)
    )
    if payload.get("design_id") != f"sha256:{rtl_sha}":
        raise ValueError("evidence index design-id is stale")
    if payload.get("rtl_source_set") != {
        "design_id": f"sha256:{rtl_sha}",
        "file_count": len(rtl_files),
        "files": rtl_files,
        "sha256": rtl_sha,
    }:
        raise ValueError("evidence index RTL source set is stale")
    if payload.get("verification_source_set") != {
        "sha256": verification_sha,
        "file_count": len(verification_files),
        "files": verification_files,
    }:
        raise ValueError("evidence index verification source set is stale")

    verified_artifacts: dict[str, str] = {}

    def walk(value: Any) -> None:
        if isinstance(value, dict):
            if {"path", "sha256", "size_bytes"} <= set(value):
                relative = value["path"]
                if not isinstance(relative, str):
                    raise ValueError("artifact path is not a string")
                observed = artifact(root, relative)
                expected = {
                    "path": value["path"],
                    "sha256": value["sha256"],
                    "size_bytes": value["size_bytes"],
                }
                if observed != expected:
                    raise ValueError(f"artifact drifted: {relative}")
                previous = verified_artifacts.setdefault(
                    relative, observed["sha256"]
                )
                if previous != observed["sha256"]:
                    raise ValueError(
                        f"artifact has conflicting identities: {relative}"
                    )
            for child in value.values():
                walk(child)
        elif isinstance(value, list):
            for child in value:
                walk(child)

    walk(payload)

    sys.path.insert(0, str(root / "npc/rv64/eval/ppa/tools"))
    import arch_stable_freeze as freeze

    mutation_path = safe_file(
        root,
        f".github/task-runs/{RUN_ID}/mutations/summary.json",
    )
    v9r_path = safe_file(root, freeze.V9R_SQ_RETRY_SUMMARY_PATH)
    semantic_entry = {
        "canonical_command": freeze.CONTROL_EVENT_COMMAND,
        "design_id": payload["design_id"],
        "evidence": [
            {
                "kind": "control_event_evidence_index",
                "path": f".github/task-runs/{RUN_ID}/evidence-index.json",
                "sha256": sha256_file(index_path),
            },
            {
                "kind": "control_event_rtl_mutations",
                "path": f".github/task-runs/{RUN_ID}/mutations/summary.json",
                "sha256": sha256_file(mutation_path),
            },
            {
                "kind": "v9r_sq_retry_c0_evidence",
                "path": freeze.V9R_SQ_RETRY_SUMMARY_PATH,
                "sha256": sha256_file(v9r_path),
            },
        ],
    }
    semantic_errors = freeze.validate_control_event_debt(
        root, semantic_entry, payload["design_id"])
    if semantic_errors:
        raise ValueError(
            "evidence index semantic replay failed: "
            + "; ".join(semantic_errors[:4]))
    print(
        "[V9O-EVIDENCE-INDEX-VERIFY] "
        f"design_id=sha256:{rtl_sha} "
        f"verification_id=sha256:{verification_sha} "
        f"artifacts={len(verified_artifacts)} status=PASS"
    )
    return 0


def main() -> int:
    run_dir = pathlib.Path(__file__).resolve().parent
    root = run_dir.parents[2]
    if run_dir != root / ".github/task-runs" / RUN_ID:
        raise ValueError("V9O evidence builder is outside its canonical run")
    parser = argparse.ArgumentParser()
    parser.add_argument("--verify", action="store_true")
    args = parser.parse_args()
    if args.verify:
        return verify_index(root, run_dir)

    sys.path.insert(0, str(run_dir))
    import evidence_source_set
    sys.path.insert(0, str(root / "npc/rv64/eval/ppa/tools"))
    import arch_stable_freeze as freeze

    rtl_sha, rtl_files = evidence_source_set.rtl_binding(root)
    verification_sha, verification_files = (
        evidence_source_set.verification_binding(root)
    )
    design_id = f"sha256:{rtl_sha}"

    architecture_relative = (
        f".github/task-runs/{RUN_ID}/gates/"
        "final-architecture-hard-gates.json"
    )
    architecture_path = safe_file(root, architecture_relative)
    architecture = json.loads(
        architecture_path.read_text(encoding="utf-8")
    )
    if (
        architecture.get("overall_status") != "GREEN"
        or architecture.get("exit_code") != 0
        or set(architecture.get("gates", {})) != EXPECTED_GATES
        or any(
            gate.get("status") != "GREEN"
            for gate in architecture["gates"].values()
        )
    ):
        raise ValueError("architecture hard-gate aggregate is not exact GREEN")
    architecture_rtl = architecture.get("rtl_source_set", {})
    expected_rtl = {
        "design_id": design_id,
        "file_count": len(rtl_files),
        "files": rtl_files,
        "sha256": rtl_sha,
    }
    if architecture_rtl != expected_rtl:
        raise ValueError("architecture result is not bound to live RTL")

    focused_logs: dict[str, dict[str, Any]] = {}
    for test_name, markers in FOCUSED_MARKERS.items():
        relative = (
            f".github/task-runs/{RUN_ID}/focused/logs/{test_name}.log"
        )
        focused_logs[test_name] = validate_pass_log(
            root,
            relative,
            test_name=test_name,
            design_id=design_id,
            verification_id=verification_sha,
            expected_markers=markers,
        )

    config_logs: dict[str, dict[str, Any]] = {}
    for test_name, markers in CONFIG_MARKERS.items():
        relative = (
            f".github/task-runs/{RUN_ID}/config-variants/logs/"
            f"{test_name}.log"
        )
        config_logs[test_name] = validate_pass_log(
            root,
            relative,
            test_name=test_name,
            design_id=design_id,
            verification_id=verification_sha,
            expected_markers=markers,
        )

    makefile = safe_file(root, "npc/rv64/testbench/Makefile")
    inventory, inventory_errors = freeze.parse_required_tests(
        makefile.read_text(encoding="utf-8")
    )
    if inventory_errors:
        raise ValueError(
            "module inventory is invalid: " + "; ".join(inventory_errors)
        )
    module_count = len(inventory)
    module_summary_relative = (
        f".github/task-runs/{RUN_ID}/module-aggregate-current/summary.txt"
    )
    module_summary_path = safe_file(root, module_summary_relative)
    module_passed, total, passed, failed = parse_module_summary(
        module_summary_path.read_text(encoding="utf-8")
    )
    if (
        total != module_count
        or passed != module_count
        or failed != 0
        or module_passed != inventory
        or len(set(module_passed)) != module_count
    ):
        raise ValueError(
            "module aggregate is not the exact current TESTS inventory")
    module_logs: dict[str, dict[str, Any]] = {}
    for test_name in inventory:
        relative = (
            f".github/task-runs/{RUN_ID}/module-aggregate-current/logs/"
            f"{test_name}.log"
        )
        module_logs[test_name] = validate_pass_log(
            root,
            relative,
            test_name=test_name,
            design_id=design_id,
            verification_id=verification_sha,
        )

    mutation_relative = (
        f".github/task-runs/{RUN_ID}/mutations/summary.json"
    )
    mutation_path = safe_file(root, mutation_relative)
    mutations = json.loads(mutation_path.read_text(encoding="utf-8"))
    if not (
        mutations.get("schema")
        == "npc-rv64-control-event-rtl-mutations-v3"
        and mutations.get("design_id") == design_id
        and mutations.get("required") == 11
        and mutations.get("compile_success") == 11
        and mutations.get("rejected") == 11
        and mutations.get("dynamic_rejected") == 10
        and mutations.get("lint_rejected") == 1
        and mutations.get("baseline_unoptflat") is False
        and mutations.get("source_unchanged") is True
        and mutations.get("full_rtl_source_unchanged") is True
        and mutations.get("verification_source_unchanged") is True
        and mutations.get("rtl_source_set") == expected_rtl
        and mutations.get("verification_source_set")
        == {
            "file_count": len(verification_files),
            "files": verification_files,
            "sha256": verification_sha,
        }
    ):
        raise ValueError("compile-success mutation summary is incomplete")
    mutation_logs: dict[str, dict[str, Any]] = {}
    for row in mutations.get("results", []):
        if not (
            row.get("compile_success") is True
            and row.get("rejected") is True
        ):
            raise ValueError(f"mutation was not rejected: {row.get('name')}")
        log = row.get("log", {})
        relative = log.get("path")
        if not isinstance(relative, str):
            raise ValueError("mutation log path is missing")
        record = artifact(root, relative)
        if record["sha256"] != log.get("sha256"):
            raise ValueError(f"mutation log hash drifted: {relative}")
        mutation_logs[str(row["name"])] = record
    if len(mutation_logs) != 11:
        raise ValueError("mutation result inventory is not exactly 11")

    audit_relative = (
        f".github/task-runs/{RUN_ID}/gates/arch-stable-audit.json"
    )
    audit_path = safe_file(root, audit_relative)
    audit = json.loads(audit_path.read_text(encoding="utf-8"))
    blockers = audit.get("blockers")
    if not (
        audit.get("architecture_freeze") == "GAP"
        and audit.get("ppa") == "UNQUALIFIED"
        and audit.get("promotion_eligible") is False
        and isinstance(blockers, list)
        and blockers
    ):
        raise ValueError("full-core freeze boundary is not an honest GAP")

    architecture_manifest_relative = (
        "npc/rv64/eval/ppa/evidence/architecture-current.json"
    )
    architecture_manifest = json.loads(
        safe_file(root, architecture_manifest_relative).read_text(
            encoding="utf-8"
        )
    )
    if (
        architecture_manifest.get("design_id") != design_id
        or len(architecture_manifest.get("tests", {})) != 9
    ):
        raise ValueError("directed architecture manifest is not current")

    static_contract = validate_static_contract(root)
    provenance = {
        relative: artifact(root, relative)
        for relative in PROVENANCE_PATHS
    }
    payload: dict[str, Any] = {
        "schema": SCHEMA,
        "run_id": RUN_ID,
        "generated_at_utc": datetime.datetime.now(
            datetime.timezone.utc
        ).isoformat(),
        "status": "PASS",
        "claim_scope": "CONTROL-EVENT-G1 current-design review candidate",
        "design_id": design_id,
        "rtl_source_set": expected_rtl,
        "verification_source_set": {
            "sha256": verification_sha,
            "file_count": len(verification_files),
            "files": verification_files,
        },
        "static_contract": static_contract,
        "focused": {
            "required": 10,
            "passed": 10,
            "logs": focused_logs,
        },
        "config_variants": {
            "configuration": "OOO_CSR_QUEUE_HEAD=1",
            "required": 3,
            "passed": 3,
            "logs": config_logs,
        },
        "rtl_mutations": {
            "required": 11,
            "compile_success": 11,
            "rejected": 11,
            "dynamic_rejected": 10,
            "lint_rejected": 1,
            "summary": artifact(root, mutation_relative),
            "baseline_lint": artifact(
                root,
                f".github/task-runs/{RUN_ID}/mutations/"
                "baseline-verilator.log",
            ),
            "logs": mutation_logs,
        },
        "module_aggregate": {
            "required": module_count,
            "passed": module_count,
            "failed": 0,
            "inventory": inventory,
            "summary": artifact(root, module_summary_relative),
            "run_log": artifact(
                root,
                f".github/task-runs/{RUN_ID}/"
                "module-aggregate-current/run.log",
            ),
            "logs": module_logs,
        },
        "architecture_hard_gates": {
            "required": 9,
            "green": 9,
            "negative_unit_tests": 30,
            "result": artifact(root, architecture_relative),
            "manifest": artifact(root, architecture_manifest_relative),
            "refresh_log": artifact(
                root,
                f".github/task-runs/{RUN_ID}/gates/"
                "architecture-evidence-refresh.log",
            ),
        },
        "contract_gate": {
            "holder_census": "PASS",
            "immediate_assertions": 471,
            "unit_tests": 13,
        },
        "full_core_boundary": {
            "architecture_freeze": "GAP",
            "blockers": len(blockers),
            "ppa": "UNQUALIFIED",
            "promotion_eligible": False,
            "candidate_design_id": audit["design_id"],
            "current_design_match": audit["design_id"] == design_id,
        },
        "provenance": provenance,
    }
    payload["provenance_sha256"] = canonical_sha256(payload)
    semantic_errors = freeze.validate_control_event_payload(
        root, payload, mutations, design_id)
    if semantic_errors:
        raise ValueError(
            "evidence index semantic construction failed: "
            + "; ".join(semantic_errors[:4]))

    output = run_dir / "evidence-index.json"
    output.write_text(
        json.dumps(payload, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    markdown = f"""# V9O evidence index

- status: `PASS`
- claim scope: `CONTROL-EVENT-G1 current-design review candidate`
- RTL design-id: `{design_id}`
- RTL source set: `{len(rtl_files)}` files
- verification source-id: `sha256:{verification_sha}`
- verification source set: `{len(verification_files)}` files
- provenance SHA-256: `{payload["provenance_sha256"]}`

## Bound evidence

- focused: `10/10`
- `OOO_CSR_QUEUE_HEAD=1`: `3/3`
- compile-success RTL variants: `11/11` rejected
  (`10` dynamic, `1` full-cone SCC lint)
- default module aggregate: `{module_count}/{module_count}`
- directed architecture hard gates: `9/9 GREEN`
- contract gate: holder census PASS, `471` immediate assertions,
  `13/13` unit tests

## Dynamic control-event oracles

- real full-C0 completion matrix: `8/8` classes,
  `head=15/younger=0`
- dual registered AR barrier: `2` lanes, `4` held cycles,
  `2` exact terminals
- single C0 request source: trap/CSR commit pulses are bidirectional
  pregrant assertions, not alternate request inputs

## Claim boundary

- full-core architecture freeze: `GAP`
- blockers: `{len(blockers)}`
- candidate design-id matches current RTL: `{str(audit["design_id"] == design_id).lower()}`
- PPA: `UNQUALIFIED`
- promotion eligible: `false`

Machine-readable artifact: `evidence-index.json`.
"""
    (run_dir / "evidence-index.md").write_text(
        markdown,
        encoding="utf-8",
    )
    print(
        "[V9O-EVIDENCE-INDEX] "
        f"design_id={design_id} verification_id=sha256:{verification_sha} "
        f"focused=10 config=3 mutations=11 modules={module_count} "
        "architecture=9 status=PASS"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
