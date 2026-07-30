#!/usr/bin/env python3
"""Fail-closed verification for the current-design SERIALIZE-G1 decision."""

from __future__ import annotations

import hashlib
import json
import pathlib
import sys
from typing import Any, Iterable


ROOT = pathlib.Path(__file__).resolve().parents[3]
RUN = pathlib.Path(
    ".github/task-runs/2026-07-28-rv64-v10g-serialize-currentness-closure"
)
DESIGN_ID = (
    "sha256:04c5458ff274b7b30e0629fc20ccef4"
    "ffa958dee3b80595ee4b46faf17a73897"
)
CANDIDATE = RUN / "serialize-g1-closure-candidate-v2.json"
CONTRACT = RUN / (
    "subagent-contracts/serialize-currentness-final-review-v2.json"
)
REVIEW = RUN / "final-reviewer-report-v2.md"
EXPECTED_ARTIFACT_HASHES = {
    CANDIDATE: (
        "158cf6328943a275cd3e12eac780c0cc"
        "48223012e2692ca9d9e7f9dace110bab"
    ),
    CONTRACT: (
        "b1316f46171145a8265393d29a0069a9"
        "b12f0eb61ae8f13e68b43d8c21aa1af2"
    ),
    REVIEW: (
        "c79a301cdb5a2ae9210bf872d6cb786a"
        "78adcbdc41244f53b20716bfdb2ff93b"
    ),
}
EXPECTED_LEDGER_EVIDENCE = (
    {
        "kind": "serialize_closure_candidate",
        "path": CANDIDATE.as_posix(),
        "sha256": EXPECTED_ARTIFACT_HASHES[CANDIDATE],
    },
    {
        "kind": "independent_review_contract",
        "path": CONTRACT.as_posix(),
        "sha256": EXPECTED_ARTIFACT_HASHES[CONTRACT],
    },
    {
        "kind": "independent_review_report",
        "path": REVIEW.as_posix(),
        "sha256": EXPECTED_ARTIFACT_HASHES[REVIEW],
    },
)
A3_STATUS = pathlib.Path(
    ".github/task-runs/2026-07-27-rv64-v10e-current-design-system-recert/"
    "rootfs-c1b531-systemd-strict-6b-a3.status"
)
A4_STATUS = pathlib.Path(
    ".github/task-runs/2026-07-27-rv64-v10e-current-design-system-recert/"
    "rootfs-5f9dd068-systemd-strict-6b-a4.status"
)
CHECKER_REPLAY_STATUS = pathlib.Path(
    ".github/task-runs/2026-07-28-rv64-v10f-a3-checker-replay-v2/"
    "a3-checker-replay-v2.status"
)


def sha256_file(path: pathlib.Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def load_json(path: pathlib.Path) -> dict[str, Any]:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise ValueError(f"top-level object required: {path}")
    return value


def require(condition: bool, message: str, errors: list[str]) -> None:
    if not condition:
        errors.append(message)


def validate_ledger_evidence(value: Any) -> list[str]:
    """Require the exact ordered candidate/contract/review decision tuple."""
    if not isinstance(value, list):
        return ["SERIALIZE-G1 ledger evidence is not a list"]
    if len(value) != len(EXPECTED_LEDGER_EVIDENCE):
        return [
            "SERIALIZE-G1 ledger evidence cardinality drifted: "
            f"expected={len(EXPECTED_LEDGER_EVIDENCE)} actual={len(value)}"
        ]
    errors: list[str] = []
    for index, (actual, expected) in enumerate(
        zip(value, EXPECTED_LEDGER_EVIDENCE, strict=True)
    ):
        if actual != expected:
            errors.append(
                "SERIALIZE-G1 ledger evidence tuple drifted at "
                f"index={index}: expected={expected!r} actual={actual!r}"
            )
    return errors


def nested_artifacts(
    value: Any,
    *,
    prefix: tuple[str, ...] = (),
) -> Iterable[tuple[tuple[str, ...], dict[str, Any]]]:
    if isinstance(value, dict):
        if (
            isinstance(value.get("path"), str)
            and isinstance(value.get("sha256"), str)
        ):
            yield prefix, value
        for key, child in value.items():
            yield from nested_artifacts(child, prefix=(*prefix, str(key)))
    elif isinstance(value, list):
        for index, child in enumerate(value):
            yield from nested_artifacts(child, prefix=(*prefix, str(index)))


def validate_candidate_artifacts(
    candidate: dict[str, Any],
    errors: list[str],
) -> None:
    for prefix, artifact in nested_artifacts(candidate.get("evidence")):
        # The candidate is the immutable pre-review package. Normative documents
        # intentionally change when the independent decision is published, so
        # their current semantics are checked separately below.
        if prefix and prefix[0] == "normative_docs":
            continue
        path = ROOT / artifact["path"]
        label = ".".join(prefix)
        require(path.is_file(), f"candidate artifact missing: {label}", errors)
        if not path.is_file():
            continue
        require(
            sha256_file(path) == artifact["sha256"],
            f"candidate artifact hash drifted: {label}",
            errors,
        )
        if isinstance(artifact.get("size_bytes"), int):
            require(
                path.stat().st_size == artifact["size_bytes"],
                f"candidate artifact size drifted: {label}",
                errors,
            )


def validate(root: pathlib.Path = ROOT) -> list[str]:
    global ROOT
    ROOT = root.resolve()
    errors: list[str] = []

    for relative, expected in EXPECTED_ARTIFACT_HASHES.items():
        path = ROOT / relative
        require(path.is_file(), f"decision artifact missing: {relative}", errors)
        if path.is_file():
            require(
                sha256_file(path) == expected,
                f"decision artifact hash drifted: {relative}",
                errors,
            )

    if errors:
        return errors

    candidate = load_json(ROOT / CANDIDATE)
    require(
        candidate.get("schema")
        == "npc-rv64-serialize-g1-closure-candidate/v2",
        "candidate schema drifted",
        errors,
    )
    require(
        candidate.get("status") == "READY_FOR_INDEPENDENT_REVIEW",
        "candidate pre-review status drifted",
        errors,
    )
    require(candidate.get("design_id") == DESIGN_ID, "design ID drifted", errors)
    require(
        candidate.get("debt") == {
            "id": "SERIALIZE-G1",
            "priority": "P1",
            "pre_review_status": "OPEN",
            "requested_review_transition": "CLOSED or named GAP",
        },
        "candidate debt transition drifted",
        errors,
    )

    split = candidate.get("normative_split")
    require(
        isinstance(split, dict)
        and split.get("product_default") == {
            "OOO_CSR_QUEUE_HEAD": 1,
            "OOO_TERMINAL_HOLDER_ASSERT": 1,
            "command_line_override_required": False,
            "queue_head_zero_role": "explicit comparison/recovery only",
        }
        and split.get("raw_event_counting") is True
        and split.get("deduplication_mask") is False
        and split.get("rtl_assertions_weakened") is False,
        "candidate product split or raw-event boundary drifted",
        errors,
    )

    evidence = candidate.get("evidence")
    queue_head = (
        evidence.get("queue_head_fallback_assert_release")
        if isinstance(evidence, dict) else None
    )
    typed_apply = (
        evidence.get("typed_apply_c2_mutation")
        if isinstance(evidence, dict) else None
    )
    csrfile = (
        evidence.get("csrfile_request_c2_mutation")
        if isinstance(evidence, dict) else None
    )
    system = (
        evidence.get("pending_system_product_matrix")
        if isinstance(evidence, dict) else None
    )
    replay = (
        evidence.get("product_default_current_replay")
        if isinstance(evidence, dict) else None
    )
    require(
        isinstance(queue_head, dict)
        and queue_head.get("assertions_on_off") == "2/2"
        and queue_head.get("command_line_override") is False
        and queue_head.get("committed_transactions") == "3 per mode"
        and queue_head.get("selectively_killed_transactions") == "2 per mode",
        "queue-head assert/release coverage drifted",
        errors,
    )
    require(
        isinstance(typed_apply, dict)
        and typed_apply.get("compile_success") is True
        and typed_apply.get("pre_scoreboard_false_green") is True
        and typed_apply.get("current_raw_scoreboard_rejected") is True
        and typed_apply.get("C2_reject_markers") == 3
        and typed_apply.get("unowned_reject_markers") == 3
        and typed_apply.get("command_line_override") is False,
        "typed-apply C2 negative RTL version drifted",
        errors,
    )
    require(
        isinstance(csrfile, dict)
        and csrfile.get("compile_success") is True
        and csrfile.get("current_raw_scoreboard_rejected") is True
        and csrfile.get("command_line_override") is False
        and csrfile.get("production_binding", {}).get("exact_occurrences") == 1,
        "CsrFile C2 production-binding-equivalent wiring drifted",
        errors,
    )
    require(
        isinstance(system, dict)
        and system.get("baseline_pass") == "3/3"
        and system.get("compile_success_mutations") == "14/14"
        and system.get("dynamically_rejected_mutations") == "14/14"
        and system.get("lane1_satp_pending_full_drain")
        == "assert/release PASS"
        and system.get("head0_satp_queue_head") == "assert/release PASS"
        and system.get("command_line_override") is False,
        "pending-SYSTEM/SATP product matrix drifted",
        errors,
    )
    require(
        isinstance(replay, dict)
        and replay.get("stage_pass") == "26/26"
        and replay.get("stage_logs") == 26
        and replay.get("module") == "113/113"
        and replay.get("official") == "177/177"
        and replay.get("am_difftest") == "59/59; mismatch=0"
        and replay.get("design_id") == DESIGN_ID
        and replay.get("single_flight") is True,
        "current-design replay coverage drifted",
        errors,
    )

    expected_a3 = {
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
    a3 = (
        evidence.get("layered_identity_and_a3", {}).get("a3_state")
        if isinstance(evidence, dict) else None
    )
    require(a3 == expected_a3, "A3 layered state drifted", errors)
    require(
        candidate.get("a3_publication_boundary") == {
            "published_gate_state": "FAIL",
            "execution_state": "COMPLETE",
            "dut_terminal_state": "COMPLETE",
            "oracle_state": "INVALID",
            "checker_replay": "PASS",
            "original_status_mutated": False,
            "a4_term_used_as_pass": False,
            "full_system_rerun_required": "NO",
        },
        "A3 publication boundary drifted",
        errors,
    )
    require(
        candidate.get("promotion_boundary") == {
            "serialize_g1": "OPEN_PENDING_INDEPENDENT_REVIEW",
            "architecture_freeze": "GAP",
            "historical_defect_backfill": "NOT_STARTED_UNTIL_P0_P1_CLEAR",
            "ppa": "UNQUALIFIED",
            "promotion_eligible": False,
        },
        "pre-review promotion boundary drifted",
        errors,
    )
    validate_candidate_artifacts(candidate, errors)

    defaults = (ROOT / "npc/rv64/configs/product-rtl-defaults.mk").read_text(
        encoding="utf-8"
    )
    makefile = (ROOT / "npc/rv64/Makefile").read_text(encoding="utf-8")
    defines = (ROOT / "npc/rv64/vsrc/include/define.v").read_text(
        encoding="utf-8"
    )
    require(
        defaults.splitlines().count("OOO_CSR_QUEUE_HEAD ?= 1") == 1
        and defaults.splitlines().count("OOO_TERMINAL_HOLDER_ASSERT ?= 1") == 1,
        "product RTL manifest drifted",
        errors,
    )
    require(
        makefile.count("include $(RV64_PRODUCT_RTL_DEFAULTS)") == 1
        and makefile.count(
            "$(if $(filter 1 y,$(OOO_CSR_QUEUE_HEAD)),"
            "+define+OOO_CSR_QUEUE_HEAD=1)"
        ) == 1,
        "Makefile product-default consumption drifted",
        errors,
    )
    require(
        defines.count("`define OOO_CSR_QUEUE_HEAD 1'b1") == 1,
        "define.v queue-head fallback drifted",
        errors,
    )

    review = (ROOT / REVIEW).read_text(encoding="utf-8")
    for marker in (
        "范围=PASS",
        "`APPROVED_FOR_CURRENT_SCOPE`",
        "`OPEN_PENDING_REVIEW` 更新为 `CLOSED`",
        "不是 `NpcCoreTop.v` 源码 mutation",
        "`ARCH_STABLE=GAP`",
        "PPA `UNQUALIFIED`",
        "A3 边界：原始 `FAIL rc=1` 保留",
        "A4 `TERM/rc=143` 也不是 PASS",
    ):
        require(marker in review, f"independent review marker missing: {marker}", errors)

    current_doc_markers = {
        "npc/rv64/design/arch/ooo-core-architecture.md": (
            "SERIALIZE-G1=CLOSED",
            "architecture freeze 与 PPA 不在该裁决范围",
        ),
        "npc/rv64/design/arch/ROADMAP.md": (
            "SERIALIZE-G1=CLOSED",
            "APPROVED_FOR_CURRENT_SCOPE",
            "historical-defect-backfill-ledger.json",
        ),
        "npc/rv64/design/arch/serialize-at-retire.md": (
            "SERIALIZE-G1=CLOSED",
            "architecture freeze 或 PPA",
        ),
        "npc/rv64/design/arch/serialize-at-retire-phase1.md": (
            "SERIALIZE-G1=CLOSED",
            "不能把二者都表述为 production RTL mutation",
        ),
        "npc/rv64/design/arch/rtl-ground-truth-2026-07-11.md": (
            "SERIALIZE-G1=CLOSED",
            "ARCH_STABLE=GAP",
            "PPA `UNQUALIFIED`",
        ),
    }
    for relative, markers in current_doc_markers.items():
        text = (ROOT / relative).read_text(encoding="utf-8")
        for marker in markers:
            require(
                marker in text,
                f"current normative marker missing: {relative}: {marker}",
                errors,
            )

    require(
        (ROOT / A3_STATUS).read_text(encoding="utf-8").strip()
        == "FAIL rc=1 stage=systemd-strict-guest evidence_complete=0 cleanup_rc=0",
        "A3 original status was changed",
        errors,
    )
    require(
        (ROOT / A4_STATUS).read_text(encoding="utf-8").strip()
        == (
            "FAIL rc=143 stage=systemd-strict-guest evidence_complete=0 "
            "cleanup_rc=143 signal=TERM"
        ),
        "A4 TERM boundary drifted",
        errors,
    )
    require(
        (ROOT / CHECKER_REPLAY_STATUS).read_text(encoding="utf-8").strip()
        == "PASS",
        "A3 frozen-input checker replay is not PASS",
        errors,
    )
    return errors


def main() -> int:
    errors = validate()
    if errors:
        for error in errors:
            print(f"[SERIALIZE-G1-VERIFY][GAP] {error}", file=sys.stderr)
        return 1
    print(
        "[SERIALIZE-G1-VERIFY] "
        f"design_id={DESIGN_ID} "
        "product_qh=1 raw_c0_c1_c2=PASS c2_negative=2/2 "
        "system=3/3+14/14 replay=26/26 review=APPROVED "
        "a3=FAIL+execution_COMPLETE+oracle_INVALID "
        "arch_stable=GAP ppa=UNQUALIFIED PASS"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
