#!/usr/bin/env python3
"""Build and verify the current-design RV64 architecture-debt receipt.

The tool composes immutable V14C/V14D/V14E executions, an exact per-file RTL
delta rebind, the current default L0+L1+L2+L3 system signoff and the current
ProducerId holder ledger.  It never launches RTL simulation.  Historical
PASS/FAIL records keep their original design identity; the delta receipt
proves which observations are reusable by unchanged source hash and which
changed-cone observations were replayed against the exact current RTL.
"""

from __future__ import annotations

import argparse
import functools
import hashlib
import importlib.util
import json
import pathlib
import re
import sys
from typing import Any


SCHEMA = "npc-rv64-architecture-debt-current-v2"
LEDGER_SCHEMA = "npc-rv64-architecture-debt-ledger-v2"
DESIGN_ID_RE = re.compile(r"^sha256:[0-9a-f]{64}$")
COHORT_ID = "full-core-single-hart-rv64-dual-issue-ooo-v1"
RTL_FILE_COUNT = 146

RECEIPT_PATH = pathlib.PurePosixPath(
    "npc/rv64/eval/ppa/evidence/architecture-debt-current.json"
)
LEDGER_PATH = pathlib.PurePosixPath(
    "npc/rv64/design/arch/architecture-debt-ledger.json"
)
ROADMAP_PATH = pathlib.PurePosixPath("npc/rv64/design/arch/ROADMAP.md")
COHORT_SCOPE_PATH = pathlib.PurePosixPath(
    "npc/rv64/design/arch/full-core-cohort-scope-v1.md"
)
SCHEMA_PATH = pathlib.PurePosixPath(
    "npc/rv64/eval/ppa/schemas/architecture-debt-current-v2.schema.json"
)
DELTA_RECEIPT_PATH = pathlib.PurePosixPath(
    "npc/rv64/eval/ppa/evidence/architecture-debt-delta-rebind-current.json"
)
DELTA_TOOL_PATH = pathlib.PurePosixPath(
    "npc/rv64/eval/ppa/tools/architecture_debt_delta_rebind.py"
)
ARCH_BINDING_TOOL_PATH = pathlib.PurePosixPath(
    "npc/rv64/eval/ppa/tools/architecture_hard_gates.py"
)
SYSTEM_TOOL_PATH = pathlib.PurePosixPath(
    "npc/rv64/eval/ppa/tools/system_recertification_current.py"
)
PRODUCER_LEDGER_PATH = pathlib.PurePosixPath(
    "npc/rv64/design/arch/producer-holder-semantic-coverage.json"
)
GLOBAL_HOLDER_RECEIPT_PATH = pathlib.PurePosixPath(
    "npc/rv64/eval/ppa/evidence/global-producer-no-live-reuse-current.json"
)
GLOBAL_HOLDER_TOOL_PATH = pathlib.PurePosixPath(
    "npc/rv64/eval/ppa/tools/global_producer_no_live_reuse.py"
)
V14E_A1_STATUS_PATH = pathlib.PurePosixPath(
    ".github/task-runs/2026-08-02-rv64-v14e-p1-remaining-current-rebind-v1/"
    "rootfs-093c2380-systemd-strict-6b-v14e-a1.status"
)
V14E_A2_STATUS_PATH = pathlib.PurePosixPath(
    ".github/task-runs/2026-08-02-rv64-v14e-p1-remaining-current-rebind-v1/"
    "rootfs-093c2380-systemd-strict-6b-v14e-a2.status"
)
V14E_A1_STATUS_TEXT = (
    "FAIL rc=1 stage=runner-contract-tests evidence_complete=0 cleanup_rc=1"
)

SOURCE_PATHS = {
    "v14c_p0": pathlib.PurePosixPath(
        ".github/task-runs/2026-08-02-rv64-v14c-p0-transitive-current-rebind-v1/"
        "evidence/p0-final-2/receipt.json"
    ),
    "v14d_p1_direct": pathlib.PurePosixPath(
        ".github/task-runs/2026-08-02-rv64-v14d-p1-direct-current-rebind-v1/"
        "evidence/p1-direct-1/receipt.json"
    ),
    "v14e_f0": pathlib.PurePosixPath(
        ".github/task-runs/2026-08-02-rv64-v14e-p1-remaining-current-rebind-v1/"
        "evidence/f0-run-6/summary.json"
    ),
    "v14e_fence": pathlib.PurePosixPath(
        ".github/task-runs/2026-08-02-rv64-v14e-p1-remaining-current-rebind-v1/"
        "evidence/fence-run-1/summary.json"
    ),
    "v14e_serialize_fast": pathlib.PurePosixPath(
        ".github/task-runs/2026-08-02-rv64-v14e-p1-remaining-current-rebind-v1/"
        "evidence/serialize-fast-run-1/summary.json"
    ),
    "v14e_vectored": pathlib.PurePosixPath(
        ".github/task-runs/2026-08-02-rv64-v14e-p1-remaining-current-rebind-v1/"
        "evidence/vectored-run-1/summary.json"
    ),
    "layered_system": pathlib.PurePosixPath(
        "npc/rv64/eval/ppa/evidence/system-recertification-current.json"
    ),
    "v14h_holder": PRODUCER_LEDGER_PATH,
    "delta_rebind": DELTA_RECEIPT_PATH,
}

P0_DEBTS = (
    "FDG-G1",
    "XRET-G1",
    "MEM-ISSUE-G1",
    "IFU-AXI-G1",
    "IFU-FETCH-G2",
    "IFU-ACCESS-G1",
    "IFU-TVAL-G1",
    "PTW-PMP-G1",
    "INSTRET-G1",
)
P1_DIRECT_DEBTS = (
    "MIQ-FLUSH-G1",
    "STORE-BRESP-G1",
    "CONTROL-EVENT-G1",
)
P1_REMAINING_DEBTS = (
    "F0-G1",
    "FENCE-G1",
    "SERIALIZE-G1",
    "VECTORED-TRAP-G1",
)
EXCLUDED_DEBTS = (
    "A-COHERENCE-G1",
    "WFI-G1",
    "SFENCE-SINVAL-G1",
    "DEBUG-TRIGGER-G1",
)
CLOSED_DEBTS = tuple(sorted(P0_DEBTS + P1_DIRECT_DEBTS + P1_REMAINING_DEBTS))
ALL_DEBTS = tuple(sorted(CLOSED_DEBTS + EXCLUDED_DEBTS))

EXCLUSION_PATHS = {
    "A-COHERENCE-G1": pathlib.PurePosixPath(
        "npc/rv64/design/arch/cohort/a-coherence-g1-exclusion.json"
    ),
    "WFI-G1": pathlib.PurePosixPath(
        "npc/rv64/design/arch/cohort/wfi-g1-exclusion.json"
    ),
    "SFENCE-SINVAL-G1": pathlib.PurePosixPath(
        "npc/rv64/design/arch/cohort/sfence-sinval-g1-exclusion.json"
    ),
    "DEBUG-TRIGGER-G1": pathlib.PurePosixPath(
        "npc/rv64/design/arch/cohort/debug-trigger-g1-exclusion.json"
    ),
}

SUPPORT = {
    **{debt: ["v14c_p0", "delta_rebind"] for debt in P0_DEBTS},
    **{
        debt: ["v14d_p1_direct", "delta_rebind"]
        for debt in P1_DIRECT_DEBTS
    },
    "F0-G1": ["v14e_f0", "delta_rebind"],
    "FENCE-G1": ["v14e_fence", "delta_rebind"],
    "SERIALIZE-G1": [
        "v14e_serialize_fast", "delta_rebind", "layered_system"
    ],
    "VECTORED-TRAP-G1": ["v14e_vectored", "delta_rebind"],
}

SERIALIZE_COMMAND = (
    "/usr/bin/env -u MAKEFLAGS -u MFLAGS -u MAKELEVEL -u GNUMAKEFLAGS "
    "-u MAKEFILES /usr/bin/make -rR --no-print-directory -C npc/rv64 "
    "-f eval/ppa/architecture-debt-current-evidence.mk "
    "check-architecture-debt-current"
)
CANONICAL_COMMANDS = {
    "FDG-G1": "make -C npc/rv64 check-fdg-arch-trap",
    "XRET-G1": "make -C npc/rv64 check-xret-current-mode",
    "MEM-ISSUE-G1": "make -C npc/rv64 check-memory-issue-lifecycle",
    "IFU-AXI-G1": (
        "/usr/bin/env -u MAKEFLAGS -u MFLAGS -u MAKELEVEL -u GNUMAKEFLAGS "
        "-u MAKEFILES /usr/bin/make -rR --no-print-directory -C npc/rv64 "
        "-f eval/ppa/ifu-evidence.mk check-ifu-axi-flush-drain"
    ),
    "IFU-FETCH-G2": "make -C npc/rv64 check-ifu-fetch-provenance",
    "IFU-ACCESS-G1": (
        "/usr/bin/env -u MAKEFLAGS -u MFLAGS -u MAKELEVEL -u GNUMAKEFLAGS "
        "-u MAKEFILES /usr/bin/make -rR --no-print-directory -C npc/rv64 "
        "-f eval/ppa/ifu-evidence.mk check-ifu-access"
    ),
    "IFU-TVAL-G1": "make -C npc/rv64 check-ifu-tval",
    "PTW-PMP-G1": "make -C npc/rv64 check-ptw-pmp",
    "INSTRET-G1": "make -C npc/rv64 check-instret-retirement",
    "F0-G1": "make -C npc/rv64 check-functional-aggregate",
    "MIQ-FLUSH-G1": "make -C npc/rv64 check-memory-issue-lifecycle",
    "STORE-BRESP-G1": "make -C npc/rv64 check-memory-ordering",
    "FENCE-G1": "make -C npc/rv64 check-fence-ordering",
    "CONTROL-EVENT-G1": (
        "/usr/bin/env -u MAKEFLAGS -u MFLAGS -u MAKELEVEL -u GNUMAKEFLAGS "
        "-u MAKEFILES /usr/bin/make -rR --no-print-directory -C npc/rv64 "
        "-f eval/ppa/control-event-evidence.mk check-control-event-current "
        "check-control-event-sq-retry"
    ),
    "SERIALIZE-G1": SERIALIZE_COMMAND,
    "VECTORED-TRAP-G1": "make -C npc/rv64 check-vectored-trap",
}


class DebtCurrentError(RuntimeError):
    """The current-design debt receipt or canonical ledger is invalid."""


def find_repo_root(start: pathlib.Path) -> pathlib.Path:
    for candidate in (start.resolve(), *start.resolve().parents):
        if (candidate / ".github").is_dir() and (candidate / "npc/rv64").is_dir():
            return candidate
    raise DebtCurrentError("cannot locate repository root")


def sha256_file(path: pathlib.Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def safe_file(root: pathlib.Path, relative: str | pathlib.PurePosixPath) -> pathlib.Path:
    try:
        candidate = (root / pathlib.PurePosixPath(relative)).resolve(strict=True)
        candidate.relative_to(root.resolve())
    except (OSError, ValueError) as exc:
        raise DebtCurrentError(f"invalid repository file: {relative}") from exc
    if candidate.is_symlink() or not candidate.is_file():
        raise DebtCurrentError(f"not a regular repository file: {relative}")
    return candidate


def artifact(root: pathlib.Path, relative: str | pathlib.PurePosixPath) -> dict[str, Any]:
    path = safe_file(root, relative)
    return {
        "path": path.relative_to(root.resolve()).as_posix(),
        "sha256": sha256_file(path),
        "size_bytes": path.stat().st_size,
    }


def ledger_artifact(root: pathlib.Path) -> dict[str, str]:
    record = artifact(root, RECEIPT_PATH)
    return {
        "kind": "architecture_debt_current_receipt",
        "path": record["path"],
        "sha256": record["sha256"],
    }


def load_json(root: pathlib.Path, relative: str | pathlib.PurePosixPath) -> dict[str, Any]:
    path = safe_file(root, relative)
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise DebtCurrentError(f"cannot load JSON {relative}: {exc}") from exc
    if not isinstance(value, dict):
        raise DebtCurrentError(f"JSON root is not an object: {relative}")
    return value


def load_module(path: pathlib.Path, name: str) -> Any:
    spec = importlib.util.spec_from_file_location(name, path)
    if spec is None or spec.loader is None:
        raise DebtCurrentError(f"cannot import helper: {path}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module


def require(condition: bool, message: str) -> None:
    if not condition:
        raise DebtCurrentError(message)


def require_equal(actual: Any, expected: Any, label: str) -> None:
    if actual != expected:
        raise DebtCurrentError(f"{label}: expected {expected!r}, got {actual!r}")


def validate_hash_records(root: pathlib.Path, value: Any, label: str) -> int:
    """Verify every nested object that carries both path and sha256."""

    count = 0
    if isinstance(value, dict):
        if isinstance(value.get("path"), str) and isinstance(value.get("sha256"), str):
            path = safe_file(root, value["path"])
            require_equal(sha256_file(path), value["sha256"], f"{label} artifact")
            if "size_bytes" in value:
                require_equal(path.stat().st_size, value["size_bytes"], f"{label} size")
            count += 1
        for key, child in value.items():
            count += validate_hash_records(root, child, f"{label}.{key}")
    elif isinstance(value, list):
        for index, child in enumerate(value):
            count += validate_hash_records(root, child, f"{label}[{index}]")
    return count


def validate_source_identity(payload: dict[str, Any], label: str) -> None:
    identity = payload.get("source_identity")
    require(isinstance(identity, dict), f"{label} source_identity is missing")
    require_equal(identity.get("file_count"), RTL_FILE_COUNT, f"{label} RTL file count")
    require_equal(identity.get("pre_post_equal"), True, f"{label} pre/post binding")


def validate_cohort_scope_text(text: str, design_id: str) -> dict[str, str]:
    cohort_matches = re.findall(
        r"\*\*Normative cohort ID\*\*:[ \t]*\r?\n>[ \t]*`([^`\r\n]+)`",
        text,
    )
    design_matches = re.findall(
        r"\*\*Bound RTL design ID\*\*:[ \t]*\r?\n>[ \t]*`([^`\r\n]+)`",
        text,
    )
    require_equal(len(cohort_matches), 1, "normative cohort ID declaration count")
    require_equal(len(design_matches), 1, "normative cohort design-id declaration count")
    require_equal(cohort_matches[0], COHORT_ID, "normative cohort ID")
    require_equal(design_matches[0], design_id, "normative cohort design-id")
    return {"cohort_id": cohort_matches[0], "design_id": design_matches[0]}


def validate_cohort_scope(root: pathlib.Path, design_id: str) -> dict[str, str]:
    path = safe_file(root, COHORT_SCOPE_PATH)
    return validate_cohort_scope_text(path.read_text(encoding="utf-8"), design_id)


def nested_field_values(value: Any, field: str) -> list[Any]:
    result: list[Any] = []
    if isinstance(value, dict):
        if field in value:
            result.append(value[field])
        for child in value.values():
            result.extend(nested_field_values(child, field))
    elif isinstance(value, list):
        for child in value:
            result.extend(nested_field_values(child, field))
    return result


def current_rtl_binding(root: pathlib.Path) -> tuple[str, int]:
    module = load_module(
        safe_file(root, ARCH_BINDING_TOOL_PATH),
        "architecture_debt_current_rtl_binding",
    )
    digest, files = module.rtl_binding(root)
    return f"sha256:{digest}", len(files)


def validate_delta_rebind(
    root: pathlib.Path, design_id: str,
) -> dict[str, Any]:
    module = load_module(
        safe_file(root, DELTA_TOOL_PATH),
        "architecture_debt_current_delta_rebind",
    )
    try:
        payload = module.validate_receipt(
            root,
            safe_file(root, DELTA_RECEIPT_PATH),
            design_id,
        )
    except module.DeltaRebindError as exc:
        raise DebtCurrentError(
            f"architecture-debt RTL delta rebind is GAP: {exc}"
        ) from exc
    require_equal(payload.get("schema"), module.SCHEMA, "delta rebind schema")
    require_equal(payload.get("status"), "PASS", "delta rebind status")
    require_equal(
        payload.get("baseline_design_id"),
        module.BASELINE_DESIGN_ID,
        "delta baseline design-id",
    )
    require_equal(
        payload.get("current_design_id"), design_id, "delta current design-id"
    )
    delta = payload.get("rtl_delta", {})
    require_equal(delta.get("file_count"), RTL_FILE_COUNT, "delta RTL file count")
    changed_files = delta.get("changed_files")
    require(isinstance(changed_files, list), "delta changed RTL inventory is absent")
    changed_paths = {
        row.get("path") for row in changed_files if isinstance(row, dict)
    }
    require_equal(
        len(changed_paths), len(changed_files), "delta changed RTL uniqueness"
    )
    require_equal(
        delta.get("changed_file_count"), len(changed_files),
        "delta changed RTL count",
    )
    historical = payload.get("historical_negative", {})
    require_equal(historical.get("total"), 175, "delta historical negatives")
    require_equal(
        historical.get("mode_counts", {}).get("CHANGED_RTL_REPLAY_REQUIRED"),
        29,
        "delta changed-cone negatives",
    )
    current = payload.get("current_changed_cone", {})
    require_equal(
        (current.get("passed"), current.get("required")),
        (29, 29),
        "delta current changed-cone replay",
    )
    coverage = payload.get("changed_source_coverage", {})
    historical_sources = coverage.get("historical_negative_sources")
    positive_only = coverage.get("positive_only_changed_files")
    require(
        isinstance(historical_sources, list) and isinstance(positive_only, list),
        "delta changed-source coverage split is absent",
    )
    require_equal(
        set(historical_sources) | set(positive_only), changed_paths,
        "delta changed-source coverage completeness",
    )
    require_equal(
        set(historical_sources) & set(positive_only), set(),
        "delta changed-source coverage overlap",
    )
    require_equal(
        coverage.get("positive_only_coverage"), "CURRENT_L0_L1_L2_L3",
        "delta positive-only coverage",
    )
    promotion = payload.get("promotion", {})
    require_equal(promotion.get("whole_architecture"), "RED", "delta boundary")
    require_equal(promotion.get("ppa"), "UNPROMOTED", "delta PPA boundary")
    return {
        "baseline_design_id": payload["baseline_design_id"],
        "rtl_files": 146,
        "changed_rtl_files": len(changed_files),
        "positive_only_changed_rtl_files": len(positive_only),
        "historical_negative": "175/175",
        "unchanged_rtl_reused": 142,
        "verification_only_reused": 4,
        "changed_rtl_replayed": "29/29",
        "artifact_records": validate_hash_records(
            root, payload.get("inputs", {}), "delta.inputs"
        ),
    }


def validate_v14c(root: pathlib.Path, payload: dict[str, Any], design_id: str) -> dict[str, Any]:
    require_equal(payload.get("schema"), "rv64-v14c-p0-final-current-dynamic-receipt-v2", "V14C schema")
    require_equal(payload.get("status"), "PASS", "V14C status")
    require_equal(payload.get("current_design_id"), design_id, "V14C design-id")
    require_equal(set(payload.get("scope", [])), set(P0_DEBTS), "V14C scope")
    require_equal(
        payload.get("scope_status"),
        {debt: "CURRENT_DYNAMIC_PASS" for debt in sorted(P0_DEBTS)},
        "V14C scope status",
    )
    require_equal(payload.get("current_dynamic_gate_count"), 9, "V14C gate count")
    validate_source_identity(payload, "V14C")
    positive = payload.get("positive_current_rtl", {})
    require_equal(positive.get("shared_module_aggregate"), {"passed": 113, "required": 113}, "V14C module aggregate")
    require_equal(positive.get("v14c_dynamic_suite"), {"passed": 18, "required": 18}, "V14C dynamic suite")
    negative = payload.get("p0_negative_observations", {})
    require_equal((negative.get("detected"), negative.get("required")), (121, 121), "V14C negative observations")
    require_equal(payload.get("replay_dependency_for_delivery"), False, "V14C replay dependency")
    publication = payload.get("publication", {})
    require_equal(publication.get("p0_current_bound"), 9, "V14C current P0")
    require_equal(publication.get("architecture_gate_state"), "RED", "V14C architecture boundary")
    require_equal(publication.get("ppa_state"), "BLOCKED_BY_ARCHITECTURE", "V14C PPA boundary")
    history = payload.get("status_history")
    require(isinstance(history, dict), "V14C status history is missing")
    expected_history_flags = {
        "current_bind_checker_replay_1_preserved_fail": True,
        "current_bind_checker_replay_2_pass": True,
        "current_bind_source_pass_invalidated": True,
        "historical_status_rewritten": False,
        "p0_final_1_attribution_superseded": True,
        "p0_final_1_status_preserved": True,
        "replay_elimination_checker_replay_pass": True,
        "replay_elimination_source_preserved_fail": True,
    }
    require_equal(
        set(history),
        set(expected_history_flags) | {"p0_final_1_superseded_reason"},
        "V14C status history fields",
    )
    for field, expected in expected_history_flags.items():
        require_equal(history.get(field), expected, f"V14C status history {field}")
    require(
        isinstance(history.get("p0_final_1_superseded_reason"), str)
        and bool(history["p0_final_1_superseded_reason"]),
        "V14C supersession reason is missing",
    )
    return {"positive": "136/136", "negative": "121/121", "artifact_records": validate_hash_records(root, payload, "V14C")}


def validate_v14d(root: pathlib.Path, payload: dict[str, Any], design_id: str) -> dict[str, Any]:
    require_equal(payload.get("schema"), "rv64-v14d-p1-direct-current-receipt-v1", "V14D schema")
    require_equal(payload.get("status"), "PASS", "V14D status")
    require_equal(payload.get("current_design_id"), design_id, "V14D design-id")
    require_equal(set(payload.get("scope", [])), set(P1_DIRECT_DEBTS), "V14D scope")
    require_equal(
        payload.get("scope_status"),
        {debt: "CURRENT_DYNAMIC_PASS" for debt in sorted(P1_DIRECT_DEBTS)},
        "V14D scope status",
    )
    validate_source_identity(payload, "V14D")
    positive = payload.get("positive_rtl", {})
    require_equal((positive.get("passed"), positive.get("required")), (21, 21), "V14D positive RTL")
    negative = payload.get("compile_success_rtl_counterexamples", {})
    require_equal((negative.get("detected"), negative.get("required")), (24, 24), "V14D counterexamples")
    require_equal(negative.get("by_gate"), {"CONTROL-EVENT-G1": 16, "MIQ-FLUSH-G1": 3, "STORE-BRESP-G1": 5}, "V14D mutation partition")
    require_equal(payload.get("arch_stable"), False, "V14D arch-stable boundary")
    require_equal(payload.get("architecture_gate_state"), "RED", "V14D architecture boundary")
    require_equal(payload.get("promotion_eligible"), False, "V14D promotion boundary")
    require_equal(payload.get("ppa_state"), "BLOCKED_BY_ARCHITECTURE", "V14D PPA boundary")
    require_equal(payload.get("production_rtl_written"), False, "V14D production RTL")
    require_equal(payload.get("historical_status_rewritten"), False, "V14D status history")
    require_equal(payload.get("canonical_ledger_unchanged"), True, "V14D canonical ledger history")
    return {"positive": "21/21", "negative": "24/24", "artifact_records": validate_hash_records(root, payload, "V14D")}


def validate_v14e_common(payload: dict[str, Any], design_id: str, debt_id: str, schema: str) -> None:
    require_equal(payload.get("schema"), schema, f"{debt_id} schema")
    require_equal(payload.get("debt_id"), debt_id, f"{debt_id} identity")
    require_equal(payload.get("status"), "PASS", f"{debt_id} status")
    require_equal(payload.get("current_design_id"), design_id, f"{debt_id} design-id")
    require_equal(payload.get("architecture_gate_state"), "RED", f"{debt_id} architecture boundary")
    require_equal(payload.get("ppa_state"), "BLOCKED_BY_ARCHITECTURE", f"{debt_id} PPA boundary")
    require_equal(payload.get("production_rtl_written"), False, f"{debt_id} production RTL")
    validate_source_identity(payload, debt_id)


def validate_v14e_f0(root: pathlib.Path, payload: dict[str, Any], design_id: str) -> dict[str, Any]:
    validate_v14e_common(payload, design_id, "F0-G1", "rv64-v14e-f0-current-summary-v1")
    require_equal(payload.get("scope_status"), "CURRENT_DYNAMIC_PASS", "F0 scope status")
    require_equal(payload.get("evidence_mode"), "CHECKER_REPLAY", "F0 evidence mode")
    require_equal(payload.get("module", {}).get("passed"), 113, "F0 module pass")
    require_equal(payload.get("module", {}).get("required"), 113, "F0 module required")
    functional = payload.get("functional", {})
    require_equal((functional.get("official_passed"), functional.get("official_required")), (177, 177), "F0 official")
    require_equal((functional.get("am_passed"), functional.get("am_required")), (61, 61), "F0 AM")
    require_equal(functional.get("difftest_mismatches"), 0, "F0 DiffTest")
    require_equal((functional.get("evidence_oracle_mutations_rejected"), functional.get("evidence_oracle_mutations_compiled")), (11, 11), "F0 oracle mutations")
    mutations = payload.get("compile_success_rtl_counterexamples", {})
    require_equal((mutations.get("production_rtl_detected"), mutations.get("production_rtl_required")), (3, 3), "F0 RTL counterexamples")
    require_equal(payload.get("counterexample_assertion_rejection_observed"), True, "F0 negative assertion")
    require_equal(payload.get("positive_assertion_failure_observed"), False, "F0 positive assertion")
    checker = payload.get("checker_replay", {})
    require_equal(checker.get("workload_rerun"), False, "F0 workload rerun")
    require_equal(
        checker.get("source_status_text"),
        "FAIL rc=1 stage=evidence-complete evidence_complete=0 cleanup_rc=0",
        "F0 original FAIL status",
    )
    return {"module": "113/113", "official": "177/177", "am": "61/61", "rtl_negative": "3/3", "oracle_negative": "11/11", "artifact_records": validate_hash_records(root, payload, "F0")}


def validate_v14e_fence(root: pathlib.Path, payload: dict[str, Any], design_id: str) -> dict[str, Any]:
    validate_v14e_common(payload, design_id, "FENCE-G1", "rv64-v14e-fence-current-summary-v1")
    require_equal(payload.get("scope_status"), "CURRENT_DYNAMIC_PASS", "FENCE scope status")
    positive = payload.get("positive", {})
    mutations = payload.get("compile_success_rtl_counterexamples", {})
    require_equal((positive.get("passed"), positive.get("required")), (2, 2), "FENCE positive")
    require_equal((mutations.get("detected"), mutations.get("required")), (2, 2), "FENCE counterexamples")
    require_equal(payload.get("assertion_failure_observed"), False, "FENCE assertions")
    return {"positive": "2/2", "negative": "2/2", "artifact_records": validate_hash_records(root, payload, "FENCE")}


def validate_v14e_serialize(root: pathlib.Path, payload: dict[str, Any], design_id: str) -> dict[str, Any]:
    validate_v14e_common(payload, design_id, "SERIALIZE-G1", "rv64-v14e-serialize-fast-current-summary-v1")
    require_equal(payload.get("scope_status"), "CURRENT_FAST_DYNAMIC_PASS", "SERIALIZE fast status")
    require_equal(payload.get("debt_current_status"), "STALE_PENDING_FULL_SYSTEM", "SERIALIZE pre-system history")
    require_equal(payload.get("positive_profiles"), {"passed": 5, "required": 5}, "SERIALIZE positives")
    mutations = payload.get("compile_success_rtl_counterexamples", {})
    require_equal((mutations.get("production_rtl_detected"), mutations.get("production_rtl_required")), (17, 17), "SERIALIZE RTL counterexamples")
    require_equal((mutations.get("verification_only_detected"), mutations.get("verification_only_required")), (1, 1), "SERIALIZE verification counterexample")
    require_equal(payload.get("counterexample_rejection_observed"), True, "SERIALIZE negative rejection")
    full_system = payload.get("full_system_recertification", {})
    require_equal(full_system.get("status"), "NOT_RUN_IN_FAST_LAYER", "SERIALIZE fast-layer system status")
    require_equal(full_system.get("required"), True, "SERIALIZE full-system requirement")
    return {"positive": "5/5", "rtl_negative": "17/17", "verification_negative": "1/1", "fast_layer_system": "NOT_RUN_IN_FAST_LAYER", "artifact_records": validate_hash_records(root, payload, "SERIALIZE")}


def validate_v14e_vectored(root: pathlib.Path, payload: dict[str, Any], design_id: str) -> dict[str, Any]:
    validate_v14e_common(payload, design_id, "VECTORED-TRAP-G1", "rv64-v14e-vectored-trap-current-summary-v1")
    require_equal(payload.get("scope_status"), "CURRENT_DYNAMIC_PASS", "VECTORED scope status")
    positive = payload.get("positive", {})
    mutations = payload.get("compile_success_rtl_counterexamples", {})
    require_equal((positive.get("passed_tests"), positive.get("required_tests")), (3, 3), "VECTORED positive")
    require_equal(positive.get("contract_markers"), 7, "VECTORED marker count")
    require_equal((mutations.get("detected"), mutations.get("required")), (7, 7), "VECTORED counterexamples")
    require_equal(payload.get("counterexample_assertion_rejection_observed"), True, "VECTORED negative assertion")
    require_equal(payload.get("positive_assertion_failure_observed"), False, "VECTORED positive assertion")
    return {"positive": "3/3", "markers": "7/7", "negative": "7/7", "artifact_records": validate_hash_records(root, payload, "VECTORED")}


def validate_system_history(
    failed_status_text: str, passed_status_text: str
) -> dict[str, Any]:
    require_equal(
        failed_status_text.strip(), V14E_A1_STATUS_TEXT, "legacy V14E A1 status"
    )
    require_equal(passed_status_text, "PASS\n", "legacy V14E A2 status")
    return {
        "legacy_v14e_a1_original_status": "FAIL",
        "legacy_v14e_a1_status_text": V14E_A1_STATUS_TEXT,
        "legacy_v14e_a2_original_status": "PASS",
        "historical_status_rewritten": False,
    }


def validate_system(root: pathlib.Path, design_id: str) -> dict[str, Any]:
    module = load_module(
        safe_file(root, SYSTEM_TOOL_PATH),
        "architecture_debt_current_system_receipt",
    )
    history = validate_system_history(
        safe_file(root, V14E_A1_STATUS_PATH).read_text(encoding="utf-8"),
        safe_file(root, V14E_A2_STATUS_PATH).read_text(encoding="utf-8"),
    )
    try:
        result = module.validate_receipt(
            root,
            safe_file(root, SOURCE_PATHS["layered_system"]),
            design_id,
        )
    except module.RecertificationError as exc:
        raise DebtCurrentError(
            f"default layered-system receipt is not current: {exc}"
        ) from exc
    require_equal(
        result.get("default_signoff_conjunction"),
        [
            "L0_DIRECTED_RTL",
            "L1_FULL_CORE_DIFFTEST",
            "L2_MINI_SYSTEM",
            "L3_LIGHTWEIGHT_LINUX",
        ],
        "default layered-system conjunction",
    )
    require_equal(result.get("optional_ubuntu"), "NOT_RUN_OPTIONAL", "Ubuntu boundary")
    result["execution_history"] = history
    return result


def validate_holder(root: pathlib.Path, payload: dict[str, Any], design_id: str) -> dict[str, Any]:
    require_equal(payload.get("schema_version"), "rv64-producer-holder-semantic-coverage-v1", "holder schema")
    require_equal(payload.get("status"), "PASS", "holder status")
    require_equal(payload.get("design_id"), design_id, "holder design-id")
    counts = payload.get("counts", {})
    require_equal((counts.get("semantic_units"), counts.get("units_semantic_pass")), (46, 46), "holder units")
    require_equal(counts.get("unit_instance_bindings"), 52, "holder bindings")
    promotion = payload.get("promotion", {})
    require_equal(promotion.get("global_no_live_reuse"), "GREEN", "holder global closure")
    require_equal(promotion.get("whole_architecture"), "RED", "holder architecture boundary")
    require_equal(promotion.get("system_recertification"), "PASS_CURRENT_CONFIG", "holder system boundary")
    require_equal(promotion.get("ppa"), "UNPROMOTED", "holder PPA boundary")
    a3_statuses = nested_field_values(payload.get("evidence_sets", []), "a3_original_status")
    a3_oracles = nested_field_values(payload.get("evidence_sets", []), "a3_oracle_state")
    a3_replays = nested_field_values(payload.get("evidence_sets", []), "a3_checker_replay")
    require_equal(len(a3_statuses), 9, "holder A3 original-status record count")
    require_equal(set(a3_statuses), {"FAIL_RETAINED"}, "holder A3 original-status values")
    require_equal(len(a3_oracles), 5, "holder A3 oracle-state record count")
    require_equal(set(a3_oracles), {"OLD_ORACLE_INVALID"}, "holder A3 oracle-state values")
    require_equal(len(a3_replays), 9, "holder A3 checker-replay record count")
    require_equal(set(a3_replays), {"PASS_INDEPENDENT"}, "holder A3 checker-replay values")
    return {
        "semantic_units": "46/46",
        "bindings": 52,
        "global_no_live_reuse": "GREEN",
        "a3_original_fail_records": 9,
        "a3_legacy_oracle_records": 5,
        "artifact_records": validate_hash_records(root, payload.get("inputs", {}), "holder.inputs"),
    }


def validate_exclusions(root: pathlib.Path, design_id: str) -> dict[str, dict[str, Any]]:
    result: dict[str, dict[str, Any]] = {}
    for debt_id, path in EXCLUSION_PATHS.items():
        payload = load_json(root, path)
        require_equal(
            set(payload),
            {"schema", "debt_id", "design_id", "cohort_id", "rationale"},
            f"{debt_id} exclusion fields",
        )
        require_equal(payload.get("schema"), "npc-rv64-architecture-debt-exclusion-v1", f"{debt_id} exclusion schema")
        require_equal(payload.get("debt_id"), debt_id, f"{debt_id} exclusion identity")
        require_equal(payload.get("design_id"), design_id, f"{debt_id} exclusion design-id")
        require_equal(payload.get("cohort_id"), COHORT_ID, f"{debt_id} exclusion cohort")
        require(isinstance(payload.get("rationale"), str) and bool(payload["rationale"]), f"{debt_id} exclusion rationale is empty")
        result[debt_id] = payload
    return result


def build_receipt(root: pathlib.Path) -> dict[str, Any]:
    root = root.resolve()
    design_id, file_count = current_rtl_binding(root)
    require(DESIGN_ID_RE.fullmatch(design_id) is not None, "live RTL design-id is malformed")
    require_equal(file_count, RTL_FILE_COUNT, "live RTL file count")
    sources = {name: load_json(root, path) for name, path in SOURCE_PATHS.items()}
    delta = validate_delta_rebind(root, design_id)
    historical_design_id = delta["baseline_design_id"]
    cohort_binding = validate_cohort_scope(root, design_id)
    metrics = {
        "delta_rebind": delta,
        "v14c_p0": validate_v14c(
            root, sources["v14c_p0"], historical_design_id
        ),
        "v14d_p1_direct": validate_v14d(
            root, sources["v14d_p1_direct"], historical_design_id
        ),
        "v14e_f0": validate_v14e_f0(
            root, sources["v14e_f0"], historical_design_id
        ),
        "v14e_fence": validate_v14e_fence(
            root, sources["v14e_fence"], historical_design_id
        ),
        "v14e_serialize_fast": validate_v14e_serialize(
            root, sources["v14e_serialize_fast"], historical_design_id
        ),
        "v14e_vectored": validate_v14e_vectored(
            root, sources["v14e_vectored"], historical_design_id
        ),
    }
    system = validate_system(root, design_id)
    holder = validate_holder(root, sources["v14h_holder"], design_id)
    exclusions = validate_exclusions(root, design_id)

    schema = load_json(root, SCHEMA_PATH)
    require_equal(schema.get("$id"), "npc-rv64-architecture-debt-current-v2.schema.json", "receipt schema id")
    require_equal(schema.get("properties", {}).get("schema", {}).get("const"), SCHEMA, "receipt schema const")

    inputs = {
        **{name: artifact(root, path) for name, path in SOURCE_PATHS.items()},
        **{f"exclusion_{debt.lower()}": artifact(root, path) for debt, path in EXCLUSION_PATHS.items()},
        "architecture_binding_tool": artifact(root, ARCH_BINDING_TOOL_PATH),
        "cohort_scope": artifact(root, COHORT_SCOPE_PATH),
        "delta_rebind_tool": artifact(root, DELTA_TOOL_PATH),
        "global_holder_receipt": artifact(root, GLOBAL_HOLDER_RECEIPT_PATH),
        "global_holder_tool": artifact(root, GLOBAL_HOLDER_TOOL_PATH),
        "receipt_schema": artifact(root, SCHEMA_PATH),
        "receipt_tool": artifact(root, pathlib.Path(__file__).resolve().relative_to(root).as_posix()),
        "system_tool": artifact(root, SYSTEM_TOOL_PATH),
        "legacy_v14e_a1_status": artifact(root, V14E_A1_STATUS_PATH),
        "legacy_v14e_a2_status": artifact(root, V14E_A2_STATUS_PATH),
    }
    debt_status = {
        **{debt: "CLOSED_CURRENT_DESIGN" for debt in CLOSED_DEBTS},
        **{debt: "EXCLUDED_BY_COHORT" for debt in EXCLUDED_DEBTS},
    }
    return {
        "schema": SCHEMA,
        "status": "PASS",
        "design_id": design_id,
        "rtl_file_count": file_count,
        "cohort_id": COHORT_ID,
        "closed_debts": list(CLOSED_DEBTS),
        "excluded_debts": list(sorted(EXCLUDED_DEBTS)),
        "debt_status": dict(sorted(debt_status.items())),
        "support": {debt: SUPPORT[debt] for debt in sorted(SUPPORT)},
        "inputs": dict(sorted(inputs.items())),
        "metrics": metrics,
        "prerequisites": {
            "producer_holder": holder,
            "system_recertification": system,
            "cohort_exclusions": {
                debt: {
                    "cohort_id": exclusions[debt]["cohort_id"],
                    "rationale": exclusions[debt]["rationale"],
                }
                for debt in sorted(exclusions)
            },
            "cohort_scope_binding": cohort_binding,
        },
        "evidence_reuse_contract": {
            "execution_state": "ORIGINAL_STATUS_IMMUTABLE",
            "artifact_state": "PATH_SHA256_SIZE_BOUND",
            "historical_design_state": "IMMUTABLE_BASELINE_093C",
            "delta_state": "PER_FILE_SHA_PLUS_CURRENT_CHANGED_CONE_REPLAY",
            "assertion_state": "POSITIVE_ZERO_FAILURE_AND_NEGATIVE_REJECTION_REQUIRED",
            "oracle_state": "CHECKER_REPLAY_VERSIONED_WHEN_EXECUTION_INPUTS_ARE_COMPLETE",
            "receipt_builder_state": "NO_RTL_SIMULATOR_LAUNCHED",
            "rerun_on": [
                "production_or_elaborated_rtl_change_outside_bound_delta",
                "active_device_model_or_simulator_semantics_change",
                "configuration_or_workload_identity_change",
                "missing_raw_terminal_assertion_or_post_hash_evidence",
            ],
        },
        "promotion": {
            "architecture_debt_ledger": "RESOLVED_CURRENT_DESIGN",
            "whole_architecture": "RED",
            "system_recertification": "PASS_CURRENT_CONFIG",
            "ppa": "UNPROMOTED",
        },
    }


def validate_receipt_payload(actual: dict[str, Any], expected: dict[str, Any]) -> None:
    require_equal(actual, expected, "current architecture-debt receipt")


@functools.lru_cache(maxsize=4)
def _cached_expected(root_text: str) -> dict[str, Any]:
    return build_receipt(pathlib.Path(root_text))


def validate_receipt(
    root: pathlib.Path,
    input_path: pathlib.Path,
    expected_design_id: str | None = None,
) -> dict[str, Any]:
    actual = load_json(root, input_path.relative_to(root.resolve()).as_posix())
    expected = _cached_expected(str(root.resolve()))
    validate_receipt_payload(actual, expected)
    if expected_design_id is not None:
        require_equal(actual.get("design_id"), expected_design_id, "caller design-id")
    return actual


def roadmap_inventory(root: pathlib.Path) -> dict[str, str]:
    text = safe_file(root, ROADMAP_PATH).read_text(encoding="utf-8")
    result: dict[str, str] = {}
    for priority in ("P0", "P1"):
        match = re.search(rf"<!-- ARCH-DEBT-{priority}: ([A-Z0-9,-]+) -->", text)
        require(match is not None, f"ROADMAP {priority} debt marker is missing")
        for debt_id in match.group(1).split(","):
            require(debt_id not in result, f"ROADMAP duplicate debt {debt_id}")
            result[debt_id] = priority
    return result


def validate_ledger_payload(
    root: pathlib.Path,
    ledger: dict[str, Any],
    receipt: dict[str, Any],
) -> None:
    require_equal(ledger.get("schema"), LEDGER_SCHEMA, "ledger schema")
    require_equal(ledger.get("design_id"), receipt["design_id"], "ledger design-id")
    revision = ledger.get("revision")
    require(
        isinstance(revision, str)
        and receipt["design_id"].removeprefix("sha256:")[:12] in revision
        and "delta-rebound" in revision,
        "ledger revision must identify the current delta-rebound design",
    )
    roadmap = ledger.get("roadmap", {})
    require_equal(roadmap.get("path"), str(ROADMAP_PATH), "ledger ROADMAP path")
    require_equal(roadmap.get("sha256"), sha256_file(safe_file(root, ROADMAP_PATH)), "ledger ROADMAP hash")

    inventory = roadmap_inventory(root)
    require_equal(set(inventory), set(ALL_DEBTS), "ledger/ROADMAP membership")
    entries = ledger.get("entries")
    require(isinstance(entries, list), "ledger entries are missing")
    entry_map = {
        entry.get("id"): entry
        for entry in entries
        if isinstance(entry, dict) and isinstance(entry.get("id"), str)
    }
    require_equal(len(entry_map), len(entries), "ledger duplicate or malformed entry")
    require_equal(set(entry_map), set(ALL_DEBTS), "ledger entry membership")
    current_artifact = ledger_artifact(root)

    for debt_id in CLOSED_DEBTS:
        entry = entry_map[debt_id]
        require_equal(entry.get("priority"), inventory[debt_id], f"{debt_id} priority")
        require_equal(entry.get("status"), "CLOSED", f"{debt_id} status")
        require_equal(entry.get("current_design_bound"), True, f"{debt_id} current binding")
        require_equal(entry.get("design_id"), receipt["design_id"], f"{debt_id} design-id")
        require_equal(entry.get("canonical_command"), CANONICAL_COMMANDS[debt_id], f"{debt_id} command")
        require_equal(
            entry.get("coverage"),
            {"positive": True, "counterexample": True, "compile_success_rtl_mutation": True},
            f"{debt_id} coverage",
        )
        require_equal(entry.get("evidence"), [current_artifact], f"{debt_id} receipt pointer")
        require_equal(receipt["debt_status"].get(debt_id), "CLOSED_CURRENT_DESIGN", f"{debt_id} receipt status")
        require_equal(receipt["support"].get(debt_id), SUPPORT[debt_id], f"{debt_id} support")

    exclusions = validate_exclusions(root, receipt["design_id"])
    for debt_id in EXCLUDED_DEBTS:
        entry = entry_map[debt_id]
        require_equal(entry.get("priority"), "P1", f"{debt_id} priority")
        require_equal(entry.get("status"), "EXCLUDED_BY_COHORT", f"{debt_id} status")
        require_equal(entry.get("scope_rationale"), exclusions[debt_id]["rationale"], f"{debt_id} rationale")
        expected_contract = artifact(root, EXCLUSION_PATHS[debt_id])
        expected_contract.pop("size_bytes")
        require_equal(entry.get("scope_contract"), expected_contract, f"{debt_id} scope contract")
        require_equal(receipt["debt_status"].get(debt_id), "EXCLUDED_BY_COHORT", f"{debt_id} receipt status")

    for debt_id, entry in entry_map.items():
        owners = entry.get("owner_paths")
        require(isinstance(owners, list) and bool(owners), f"{debt_id} owner paths are missing")
        for owner in owners:
            safe_file(root, owner)
        requirements = entry.get("closure_requirements")
        require(isinstance(requirements, list) and all(isinstance(item, str) and item for item in requirements), f"{debt_id} closure requirements are missing")


def validate_entry(root: pathlib.Path, entry: dict[str, Any], design_id: str) -> list[str]:
    """Adapter used by arch_stable_freeze for one CLOSED ledger entry."""

    try:
        require(entry.get("id") in CLOSED_DEBTS, "entry is not a current CLOSED debt")
        require_equal(entry.get("design_id"), design_id, "entry design-id")
        require_equal(entry.get("canonical_command"), CANONICAL_COMMANDS[entry["id"]], "entry command")
        expected_artifact = ledger_artifact(root)
        require_equal(entry.get("evidence"), [expected_artifact], "entry receipt pointer")
        receipt = validate_receipt(root, safe_file(root, RECEIPT_PATH), design_id)
        require_equal(receipt["debt_status"].get(entry["id"]), "CLOSED_CURRENT_DESIGN", "entry receipt status")
        require_equal(receipt["support"].get(entry["id"]), SUPPORT[entry["id"]], "entry support")
    except DebtCurrentError as exc:
        return [str(exc)]
    return []


def write_json(path: pathlib.Path, payload: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    temporary.replace(path)


def rebind_ledger_receipt(
    root: pathlib.Path, ledger_path: pathlib.Path,
) -> dict[str, Any]:
    try:
        ledger_relative = ledger_path.resolve().relative_to(root.resolve()).as_posix()
    except (OSError, ValueError) as exc:
        raise DebtCurrentError("architecture debt ledger escapes repository") from exc
    ledger = load_json(root, ledger_relative)
    entries = ledger.get("entries")
    require(isinstance(entries, list), "ledger entries are missing")
    entry_map = {
        entry.get("id"): entry
        for entry in entries
        if isinstance(entry, dict) and isinstance(entry.get("id"), str)
    }
    require_equal(set(entry_map), set(ALL_DEBTS), "ledger entry membership")
    pointer = ledger_artifact(root)
    design_id, _ = current_rtl_binding(root)
    ledger["design_id"] = design_id
    ledger["revision"] = (
        "current-"
        f"{design_id.removeprefix('sha256:')[:12]}-"
        "delta-rebound-evidence-ledger"
    )
    ledger["roadmap"] = {
        "path": str(ROADMAP_PATH),
        "sha256": sha256_file(safe_file(root, ROADMAP_PATH)),
    }
    for debt_id in CLOSED_DEBTS:
        entry_map[debt_id]["design_id"] = design_id
        entry_map[debt_id]["evidence"] = [dict(pointer)]
    for debt_id in EXCLUDED_DEBTS:
        scope_contract = artifact(root, EXCLUSION_PATHS[debt_id])
        scope_contract.pop("size_bytes")
        entry_map[debt_id]["scope_contract"] = scope_contract
    write_json(ledger_path, ledger)
    return ledger


def parser() -> argparse.ArgumentParser:
    result = argparse.ArgumentParser(description=__doc__)
    result.add_argument("--root", type=pathlib.Path, default=pathlib.Path(__file__).resolve().parents[5])
    sub = result.add_subparsers(dest="command", required=True)
    build = sub.add_parser("build")
    build.add_argument("--output", type=pathlib.Path, required=True)
    refresh = sub.add_parser(
        "refresh",
        help="atomically rebuild the receipt and rebind all CLOSED ledger pointers",
    )
    refresh.add_argument("--output", type=pathlib.Path, required=True)
    refresh.add_argument(
        "--ledger", type=pathlib.Path, default=pathlib.Path(LEDGER_PATH))
    verify = sub.add_parser("verify")
    verify.add_argument("--input", type=pathlib.Path, required=True)
    verify.add_argument("--ledger", type=pathlib.Path, default=pathlib.Path(LEDGER_PATH))
    return result


def main(argv: list[str] | None = None) -> int:
    args = parser().parse_args(argv)
    root = args.root.resolve()
    try:
        expected = build_receipt(root)
        if args.command in {"build", "refresh"}:
            output = args.output if args.output.is_absolute() else root / args.output
            write_json(output.resolve(), expected)
            receipt = expected
            if args.command == "refresh":
                ledger_path = (
                    args.ledger if args.ledger.is_absolute()
                    else root / args.ledger)
                ledger = rebind_ledger_receipt(root, ledger_path.resolve())
                validate_receipt_payload(receipt, expected)
                validate_ledger_payload(root, ledger, receipt)
        else:
            input_path = args.input if args.input.is_absolute() else root / args.input
            receipt = load_json(root, input_path.resolve().relative_to(root).as_posix())
            validate_receipt_payload(receipt, expected)
            ledger_path = args.ledger if args.ledger.is_absolute() else root / args.ledger
            ledger = load_json(root, ledger_path.resolve().relative_to(root).as_posix())
            validate_ledger_payload(root, ledger, receipt)
    except (DebtCurrentError, OSError, ValueError) as exc:
        print(f"[ARCHITECTURE-DEBT-CURRENT][FAIL] {exc}", file=sys.stderr)
        return 1
    print(
        "[ARCHITECTURE-DEBT-CURRENT][PASS] "
        f"design_id={receipt['design_id']} closed=16 excluded=4 "
        "ledger=RESOLVED_CURRENT_DESIGN system=PASS_CURRENT_CONFIG "
        "whole_architecture=RED ppa=UNPROMOTED"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
