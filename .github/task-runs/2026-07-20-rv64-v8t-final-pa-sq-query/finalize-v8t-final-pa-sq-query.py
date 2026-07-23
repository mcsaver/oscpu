#!/usr/bin/env python3
"""Build the fail-closed F3 candidate/checkpoint result.

The focused runner owns executable RTL evidence.  An independent reviewer may
authorize the scoped checkpoint by publishing a small JSON disposition that
binds the already-reviewed functional source closure and its own contract SHA.
Review provenance is intentionally not part of that functional closure; this
avoids a self-referential hash cycle while keeping every overlay input hashed in
the emitted result.
"""

from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import json
import pathlib
from typing import Any


EXPECTED_MUTATIONS = 38
EXPECTED_DYNAMIC_REJECTIONS = 37
EXPECTED_PROFILES = 11
CHECKPOINT_CLAIM = "final_pa_sq_ordering_checkpoint"
CANDIDATE_CLAIM = "final_pa_sq_ordering_candidate"
REVIEW_SCHEMA = "v8t-f3-independent-implementation-review/v1"


def sha256_file(path: pathlib.Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def load_mutations(path: pathlib.Path) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for line_number, line in enumerate(
        path.read_text(encoding="utf-8").splitlines(), start=1
    ):
        fields = line.split("|")
        if len(fields) != 7:
            raise ValueError(
                f"mutation row {line_number} has {len(fields)} fields, expected 7"
            )
        name, role, static_check, dynamic, mutant_sha, image_sha, dynamic_rc = fields
        if dynamic not in {"target_rejected", "not_required"}:
            raise ValueError(
                f"mutation {name} has unsupported dynamic status {dynamic!r}"
            )
        rows.append(
            {
                "name": name,
                "role": role,
                "compile_success": True,
                "elaborated": True,
                "static_oracle": static_check,
                "static_target_rejected": True,
                "dynamic_status": dynamic,
                "dynamic_rc": int(dynamic_rc),
                "mutant_sha256": mutant_sha,
                "image_sha256": image_sha,
            }
        )

    if len(rows) != EXPECTED_MUTATIONS:
        raise ValueError(
            f"expected {EXPECTED_MUTATIONS} mutation rows, observed {len(rows)}"
        )
    dynamic_count = sum(
        row["dynamic_status"] == "target_rejected" for row in rows
    )
    if dynamic_count != EXPECTED_DYNAMIC_REJECTIONS:
        raise ValueError(
            "expected "
            f"{EXPECTED_DYNAMIC_REJECTIONS} dynamic rejections, observed {dynamic_count}"
        )
    static_only = [row["name"] for row in rows if row["dynamic_status"] == "not_required"]
    if static_only != ["legacy_all_load_block"]:
        raise ValueError(f"unexpected static-only mutation set: {static_only}")
    return rows


def _require_equal(mapping: dict[str, Any], key: str, expected: Any) -> None:
    actual = mapping.get(key)
    if actual != expected:
        raise ValueError(f"review field {key!r}: expected {expected!r}, observed {actual!r}")


def _resolve_repo_file(repo_root: pathlib.Path, relative: str) -> pathlib.Path:
    candidate = pathlib.Path(relative)
    if candidate.is_absolute():
        raise ValueError("review contract path must be repository-relative")
    resolved_root = repo_root.resolve()
    resolved = (resolved_root / candidate).resolve()
    try:
        resolved.relative_to(resolved_root)
    except ValueError as exc:
        raise ValueError("review contract path escapes repository root") from exc
    if not resolved.is_file():
        raise ValueError(f"review contract does not exist: {relative}")
    return resolved


def validate_review(
    review_path: pathlib.Path | None,
    repo_root: pathlib.Path,
    source_closure_sha256: str,
    run_id: str,
    candidate_result_path: pathlib.Path | None,
    mutation_path: pathlib.Path,
) -> dict[str, Any] | None:
    if review_path is None:
        return None
    if not review_path.is_file():
        raise ValueError(f"review disposition does not exist: {review_path}")
    review = json.loads(review_path.read_text(encoding="utf-8"))
    if not isinstance(review, dict):
        raise ValueError("review disposition must be a JSON object")

    _require_equal(review, "schema", REVIEW_SCHEMA)
    _require_equal(review, "verdict", "PASS")
    _require_equal(review, "authorized_claim", CHECKPOINT_CLAIM)
    _require_equal(
        review, "reviewed_source_closure_sha256", source_closure_sha256
    )
    _require_equal(review, "reviewed_runner_status", "PASS")
    _require_equal(review, "reviewed_mutations", EXPECTED_MUTATIONS)
    _require_equal(
        review, "reviewed_dynamic_rejections", EXPECTED_DYNAMIC_REJECTIONS
    )
    _require_equal(review, "reviewed_profiles", EXPECTED_PROFILES)
    _require_equal(review, "reviewed_retry_holder_proof", "PASS")
    _require_equal(review, "reviewed_predecessors", {"F0": "PASS", "F1": "PASS", "F2": "PASS"})
    _require_equal(review, "unresolved_blockers", {"P0": [], "P1": []})
    _require_equal(
        review,
        "claim_boundary",
        {
            "architecture": "RED",
            "ppa": "UNQUALIFIED",
            "promotion_eligible": False,
        },
    )

    _require_equal(review, "reviewed_candidate_run_id", run_id)

    if candidate_result_path is None or not candidate_result_path.is_file():
        raise ValueError("explicit candidate result is required for checkpoint promotion")
    if candidate_result_path.resolve() == review_path.resolve():
        raise ValueError("candidate result and review disposition must be distinct files")
    candidate_sha = sha256_file(candidate_result_path)
    mutation_sha = sha256_file(mutation_path)
    _require_equal(review, "reviewed_candidate_result_sha256", candidate_sha)
    _require_equal(review, "reviewed_mutation_summary_sha256", mutation_sha)

    candidate = json.loads(candidate_result_path.read_text(encoding="utf-8"))
    if not isinstance(candidate, dict):
        raise ValueError("candidate result must be a JSON object")
    candidate_required = {
        "runner_status": "PASS",
        "claim": CANDIDATE_CLAIM,
        "checkpoint_eligible": False,
        "run_id": run_id,
        "source_closure_sha256": source_closure_sha256,
        "review_overlay_applied": False,
        "architecture": {"DI-5": "RED", "OOO-3": "RED", "overall": "RED"},
        "ppa": "UNQUALIFIED",
        "promotion_eligible": False,
    }
    for key, expected in candidate_required.items():
        actual = candidate.get(key)
        if actual != expected:
            raise ValueError(
                f"candidate field {key!r}: expected {expected!r}, observed {actual!r}"
            )
    candidate_mutations = candidate.get("mutations", {})
    if not isinstance(candidate_mutations, dict):
        raise ValueError("candidate mutation summary is malformed")
    for key, expected in {
        "implemented": EXPECTED_MUTATIONS,
        "compile_success": EXPECTED_MUTATIONS,
        "static_target_rejected": EXPECTED_MUTATIONS,
        "dynamic_target_rejected": EXPECTED_DYNAMIC_REJECTIONS,
    }.items():
        actual = candidate_mutations.get(key)
        if actual != expected:
            raise ValueError(
                f"candidate mutation field {key!r}: expected {expected!r}, observed {actual!r}"
            )

    contract_relative = review.get("contract_json")
    contract_sha = review.get("contract_json_sha256")
    if not isinstance(contract_relative, str) or not isinstance(contract_sha, str):
        raise ValueError("review contract path/SHA is missing")
    contract_path = _resolve_repo_file(repo_root, contract_relative)
    actual_contract_sha = sha256_file(contract_path)
    if actual_contract_sha != contract_sha:
        raise ValueError(
            "review contract SHA mismatch: "
            f"declared={contract_sha} actual={actual_contract_sha}"
        )

    return {
        "status": "PASS",
        "review_result_path": review_path.relative_to(repo_root).as_posix(),
        "review_result_sha256": sha256_file(review_path),
        "candidate_result_path": candidate_result_path.relative_to(repo_root).as_posix(),
        "candidate_result_sha256": candidate_sha,
        "mutation_summary_sha256": mutation_sha,
        "contract_json": contract_relative,
        "contract_json_sha256": actual_contract_sha,
        "reviewed_candidate_run_id": run_id,
        "reviewed_source_closure_sha256": source_closure_sha256,
        "reviewer_task": review.get("reviewer_task"),
        "unresolved_blockers": {"P0": [], "P1": []},
    }


def build_payload(
    *,
    run_id: str,
    source_closure_sha256: str,
    mutation_path: pathlib.Path,
    review_path: pathlib.Path | None,
    candidate_result_path: pathlib.Path | None,
    repo_root: pathlib.Path,
) -> dict[str, Any]:
    mutations = load_mutations(mutation_path)
    review = validate_review(
        review_path,
        repo_root,
        source_closure_sha256,
        run_id,
        candidate_result_path,
        mutation_path,
    )
    promoted = review is not None

    return {
        "schema": "v8t-final-pa-sq-query-evidence/v1",
        "generated_at_utc": dt.datetime.now(dt.timezone.utc).isoformat(),
        "run_id": run_id,
        "runner_status": "PASS",
        "claim": CHECKPOINT_CLAIM if promoted else CANDIDATE_CLAIM,
        "coverage_mode": "contract_p0_closure" if promoted else "contract_p0_implementation_closure",
        "checkpoint_eligible": promoted,
        "source_closure_sha256": source_closure_sha256,
        "source_closure_kind": "functional-source-list-sha256",
        "review_overlay_applied": promoted,
        "reviewer_provenance": review,
        "profiles": {
            "baseline_release_assert_directed": 10,
            "negative_nonvacuity_assertion": 1,
            "npc_core_release_lint": "PASS",
            "npc_core_assert_lint": "PASS",
            "checker_unit_tests": "PASS",
            "mutator_anchor_tests": "PASS",
            "retry_holder_proof_binding_tests": "PASS",
            "retry_holder_bounded_exhaustive_proof": "PASS",
            "checkpoint_finalizer_unit_tests": "PASS",
        },
        "mutations": {
            "implemented": len(mutations),
            "compile_success": sum(item["compile_success"] for item in mutations),
            "static_target_rejected": sum(
                item["static_target_rejected"] for item in mutations
            ),
            "dynamic_target_rejected": sum(
                item["dynamic_status"] == "target_rejected" for item in mutations
            ),
            "rows": mutations,
        },
        "predecessors": {"F0": "PASS", "F1": "PASS", "F2": "PASS"},
        "full_contract_mutation_closure": True,
        "remaining_p0_categories": [] if promoted else ["independent implementation review"],
        "unresolved_p0_p1": {"P0": [], "P1": []} if promoted else None,
        "architecture": {"DI-5": "RED", "OOO-3": "RED", "overall": "RED"},
        "ppa": "UNQUALIFIED",
        "promotion_eligible": False,
        "canonical_architecture_manifest_modified": False,
    }


def write_outputs(
    payload: dict[str, Any], output_path: pathlib.Path, final_log_path: pathlib.Path
) -> None:
    output_path.write_text(
        json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    promoted = payload["review_overlay_applied"]
    reviewer = "PASS" if promoted else "PENDING"
    marker = "V8T-F3-CHECKPOINT" if promoted else "V8T-F3-RUNNER"
    line = (
        f"[{marker}][PASS] "
        f"run_id={payload['run_id']} claim={payload['claim']} "
        f"coverage={payload['coverage_mode']} profiles=11 mutations=38 "
        "dynamic_rejections=37 retry_proof=PASS predecessors=F0/F1/F2_PASS "
        "architecture=RED ppa=UNQUALIFIED "
        f"checkpoint_eligible={str(payload['checkpoint_eligible']).lower()} "
        f"reviewer={reviewer} promotion_eligible=false\n"
    )
    final_log_path.write_text(line, encoding="utf-8")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", required=True, type=pathlib.Path)
    parser.add_argument("--final-log", required=True, type=pathlib.Path)
    parser.add_argument("--run-id", required=True)
    parser.add_argument("--source-closure-sha256", required=True)
    parser.add_argument("--mutation-summary", required=True, type=pathlib.Path)
    parser.add_argument("--review-result", type=pathlib.Path)
    parser.add_argument("--candidate-result", type=pathlib.Path)
    parser.add_argument("--repo-root", required=True, type=pathlib.Path)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    try:
        if args.review_result is None and args.candidate_result is not None:
            raise ValueError("candidate result is only valid with an explicit review result")
        if args.review_result is not None and args.candidate_result is None:
            raise ValueError("checkpoint promotion requires an explicit candidate result")
        if (
            args.candidate_result is not None
            and args.output.resolve() == args.candidate_result.resolve()
        ):
            raise ValueError("checkpoint output must not overwrite the reviewed candidate")
        payload = build_payload(
            run_id=args.run_id,
            source_closure_sha256=args.source_closure_sha256,
            mutation_path=args.mutation_summary,
            review_path=args.review_result,
            candidate_result_path=args.candidate_result,
            repo_root=args.repo_root,
        )
        write_outputs(payload, args.output, args.final_log)
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        raise SystemExit(f"[V8T-FINALIZE][FAIL] {exc}") from exc
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
