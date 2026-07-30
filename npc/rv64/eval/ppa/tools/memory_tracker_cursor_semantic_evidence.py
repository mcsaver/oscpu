#!/usr/bin/env python3
"""Build current-design cursor evidence for OooMemOwnerTracker.

This evidence closes only ``tracker-next-token-cursor``.  The reference model
must derive ready/token/fire from stimulus plus edge-old expected state; the
tool therefore rejects evidence that lacks both 4-token and production
32-token runs or any declared compile-success cursor mutation.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import pathlib
import sys
from typing import Any


SCHEMA = "rv64-v11d-memory-tracker-cursor-semantic-evidence-v1"
MUTANT_SCHEMA = "rv64-v11d-memory-tracker-cursor-mutant-v1"
TEST = "tb_ooo_mem_owner_tracker_cursor"
TRACKER_PATH = "npc/rv64/vsrc/memory/OooMemOwnerTracker.v"
EXPECTED_TRACKER_SHA256 = (
    "fd7e0a1bcdd1fd12f35b07bb655db67a512c9a30c3ca0aae6bd5a41903f889c8"
)
UNIT_IDS = frozenset({"tracker-next-token-cursor"})
POSITIVE_PROFILES = {
    "assert-t4": (4, True),
    "release-t4": (4, False),
    "assert-t32": (32, True),
    "release-t32": (32, False),
}
POSITIVE_MARKERS = (
    "[V11D-CURSOR-LANE-SELECTION] token_count={token_count} PASS",
    "[V11D-CURSOR-RING-SCAN] token_count={token_count} PASS",
    "[V11D-CURSOR-DEATH-VISIBILITY] token_count={token_count} PASS",
    "[V11D-CURSOR-ATOMIC-HOLD] token_count={token_count} PASS",
    "[PASS] tb_ooo_mem_owner_tracker_cursor",
    "[RESULT] PASS",
)
MUTATION_MARKERS = {
    "reset-to-one": "[V11D-CURSOR-ORACLE][FAIL]",
    "fixed-scan-base": "[V11D-CURSOR-ORACLE][FAIL]",
    "advance-step-two": "[V11D-CURSOR-ORACLE][FAIL]",
    "dual-advance-lane0": "[V11D-CURSOR-ORACLE][FAIL]",
    "advance-on-ready": "[V11D-CURSOR-ORACLE][FAIL]",
    "idle-increment": "[V11D-CURSOR-ORACLE][FAIL]",
    "lane1-does-not-exclude-lane0": "[V11D-CURSOR-ORACLE][FAIL]",
    "lane1-excludes-unclaimed-lane0": "[V11D-CURSOR-ORACLE][FAIL]",
    "truncate-scan-four": "[V11D-CURSOR-ORACLE][FAIL]",
}


class EvidenceError(RuntimeError):
    """Raised when a mutation or evidence record is not auditable."""


def sha256(path: pathlib.Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def load_json(path: pathlib.Path) -> dict[str, Any]:
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise EvidenceError(f"cannot read JSON {path}: {exc}") from exc
    if not isinstance(payload, dict):
        raise EvidenceError(f"JSON root is not an object: {path}")
    return payload


def entry(root: pathlib.Path, path: pathlib.Path) -> dict[str, Any]:
    try:
        relative = path.resolve().relative_to(root).as_posix()
    except ValueError as exc:
        raise EvidenceError(f"artifact escapes repository root: {path}") from exc
    if not path.is_file():
        raise EvidenceError(f"artifact is missing: {relative}")
    return {
        "path": relative,
        "sha256": sha256(path),
        "size_bytes": path.stat().st_size,
    }


def require_once(text: str, marker: str, label: str) -> None:
    count = text.count(marker)
    if count != 1:
        raise EvidenceError(
            f"{label} marker count mismatch: {marker!r} count={count}"
        )


def replace_once(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count != 1:
        raise EvidenceError(
            f"mutation {label} anchor count={count} expected=1"
        )
    return text.replace(old, new, 1)


def replace_count(
    text: str,
    old: str,
    new: str,
    expected_count: int,
    label: str,
) -> str:
    count = text.count(old)
    if count != expected_count:
        raise EvidenceError(
            f"mutation {label} anchor count={count} "
            f"expected={expected_count}"
        )
    return text.replace(old, new)


def mutate_source(text: str, case: str) -> str:
    if case == "reset-to-one":
        return replace_once(
            text,
            "      next_token_q <= {TOKEN_W{1'b0}};\n",
            "      next_token_q <= {{(TOKEN_W-1){1'b0}}, 1'b1};\n",
            case,
        )
    if case == "fixed-scan-base":
        mutated = replace_count(
            text,
            "token_at_offset(next_token_q, scan0_i)",
            "token_at_offset({TOKEN_W{1'b0}}, scan0_i)",
            2,
            case,
        )
        return replace_count(
            mutated,
            "token_at_offset(next_token_q, scan1_i)",
            "token_at_offset({TOKEN_W{1'b0}}, scan1_i)",
            3,
            case,
        )
    if case == "advance-step-two":
        return replace_count(
            text,
            " + {{(TOKEN_W-1){1'b0}}, 1'b1};",
            " + {{(TOKEN_W-2){1'b0}}, 2'b10};",
            2,
            case,
        )
    if case == "dual-advance-lane0":
        return replace_once(
            text,
            "        next_token_q <= alloc1_token_o + "
            "{{(TOKEN_W-1){1'b0}}, 1'b1};\n",
            "        next_token_q <= alloc0_token_o + "
            "{{(TOKEN_W-1){1'b0}}, 1'b1};\n",
            case,
        )
    if case == "advance-on-ready":
        return replace_once(
            text,
            "      else if (alloc0_fire_w)\n"
            "        next_token_q <= alloc0_token_o + "
            "{{(TOKEN_W-1){1'b0}}, 1'b1};\n",
            "      else if (alloc0_ready_o)\n"
            "        next_token_q <= alloc0_token_o + "
            "{{(TOKEN_W-1){1'b0}}, 1'b1};\n",
            case,
        )
    if case == "idle-increment":
        return replace_once(
            text,
            "      else if (alloc0_fire_w)\n"
            "        next_token_q <= alloc0_token_o + "
            "{{(TOKEN_W-1){1'b0}}, 1'b1};\n",
            "      else if (alloc0_fire_w)\n"
            "        next_token_q <= alloc0_token_o + "
            "{{(TOKEN_W-1){1'b0}}, 1'b1};\n"
            "      else\n"
            "        next_token_q <= next_token_q + "
            "{{(TOKEN_W-1){1'b0}}, 1'b1};\n",
            case,
        )
    if case == "lane1-does-not-exclude-lane0":
        return replace_once(
            text,
            "      if (!alloc1_found_r &&\n"
            "          !live_q[token_at_offset(next_token_q, scan1_i)] &&\n"
            "          !(alloc0_claim_w &&\n"
            "            (token_at_offset(next_token_q, scan1_i) == "
            "alloc0_token_r))) begin\n",
            "      if (!alloc1_found_r &&\n"
            "          !live_q[token_at_offset(next_token_q, scan1_i)]) "
            "begin\n",
            case,
        )
    if case == "lane1-excludes-unclaimed-lane0":
        return replace_once(
            text,
            "          !(alloc0_claim_w &&\n"
            "            (token_at_offset(next_token_q, scan1_i) == "
            "alloc0_token_r))) begin\n",
            "          !(alloc0_found_r &&\n"
            "            (token_at_offset(next_token_q, scan1_i) == "
            "alloc0_token_r))) begin\n",
            case,
        )
    if case == "truncate-scan-four":
        mutated = replace_once(
            text,
            "    for (scan0_i = 0; scan0_i < TOKEN_COUNT; "
            "scan0_i = scan0_i + 1) begin\n",
            "    for (scan0_i = 0; scan0_i < 4; "
            "scan0_i = scan0_i + 1) begin\n",
            case,
        )
        return replace_once(
            mutated,
            "    for (scan1_i = 0; scan1_i < TOKEN_COUNT; "
            "scan1_i = scan1_i + 1) begin\n",
            "    for (scan1_i = 0; scan1_i < 4; "
            "scan1_i = scan1_i + 1) begin\n",
            case,
        )
    raise EvidenceError(f"unsupported mutation case: {case}")


def parse_manifest(root: pathlib.Path, path: pathlib.Path) -> dict[str, str]:
    result: dict[str, str] = {}
    for lineno, line in enumerate(
        path.read_text(encoding="utf-8").splitlines(), 1
    ):
        if not line:
            continue
        try:
            digest, raw = line.split(None, 1)
        except ValueError as exc:
            raise EvidenceError(
                f"malformed manifest line {path}:{lineno}"
            ) from exc
        source = pathlib.Path(raw.strip())
        if not source.is_absolute():
            source = root / source
        try:
            key = source.resolve().relative_to(root).as_posix()
        except ValueError as exc:
            raise EvidenceError(
                f"manifest path escapes repository root: {source}"
            ) from exc
        if key in result:
            raise EvidenceError(f"duplicate manifest path: {key}")
        result[key] = digest
    return result


def current_design_id(root: pathlib.Path) -> str:
    sys.path.insert(0, str(root / "npc/rv64/eval/ppa/tools"))
    try:
        import architecture_hard_gates as architecture
    finally:
        sys.path.pop(0)
    digest, _ = architecture.rtl_binding(root)
    return f"sha256:{digest}"


def compile_line(text: str, label: str) -> str:
    matches = [
        line for line in text.splitlines() if line.startswith("[COMPILE]")
    ]
    if len(matches) != 1:
        raise EvidenceError(f"{label} compile line count={len(matches)}")
    if "compile returned nonzero" in text:
        raise EvidenceError(f"{label} did not compile successfully")
    return matches[0]


def validate_full_rtl_snapshot(
    root: pathlib.Path,
    path: pathlib.Path,
    design_id: str,
) -> dict[str, Any]:
    payload = load_json(path)
    if (
        payload.get("schema") != "npc-rv64-v8l-rtl-source-binding-v1"
        or payload.get("design_id") != design_id
    ):
        raise EvidenceError("full RTL snapshot schema/design mismatch")
    rtl_files = payload.get("rtl_files")
    if not isinstance(rtl_files, dict) or not rtl_files:
        raise EvidenceError("full RTL snapshot has no source records")
    for value, expected in rtl_files.items():
        source = root / value
        if not source.is_file() or sha256(source) != expected:
            raise EvidenceError(f"live RTL differs from snapshot: {value}")
    return payload


def read_nonzero_rc(path: pathlib.Path, label: str) -> int:
    try:
        value = int(path.read_text(encoding="utf-8").strip())
    except (OSError, ValueError) as exc:
        raise EvidenceError(f"{label} return code is unreadable") from exc
    if value == 0:
        raise EvidenceError(f"{label} unexpectedly returned zero")
    return value


def build_summary(
    root: pathlib.Path,
    evidence: pathlib.Path,
) -> dict[str, Any]:
    design_id = current_design_id(root)
    tracker = root / TRACKER_PATH
    if sha256(tracker) != EXPECTED_TRACKER_SHA256:
        raise EvidenceError(
            "production tracker RTL differs from the reviewed V11D source"
        )

    rtl_pre_path = evidence / "rtl-source-binding.pre.json"
    rtl_post_path = evidence / "rtl-source-binding.post.json"
    rtl_pre = validate_full_rtl_snapshot(root, rtl_pre_path, design_id)
    rtl_post = validate_full_rtl_snapshot(root, rtl_post_path, design_id)
    if rtl_pre != rtl_post:
        raise EvidenceError("full RTL pre/post snapshots differ")

    source_pre_path = evidence / "sources.pre.sha256"
    source_post_path = evidence / "sources.post.sha256"
    source_pre = parse_manifest(root, source_pre_path)
    source_post = parse_manifest(root, source_post_path)
    if source_pre != source_post:
        raise EvidenceError("focused source manifest changed during execution")
    for value, expected in source_pre.items():
        source = root / value
        if not source.is_file() or sha256(source) != expected:
            raise EvidenceError(f"live focused source differs: {value}")

    positives: dict[str, Any] = {}
    for profile, (token_count, assertions_enabled) in (
        POSITIVE_PROFILES.items()
    ):
        profile_dir = evidence / profile
        log_path = profile_dir / "result/logs" / f"{TEST}.log"
        text = log_path.read_text(encoding="utf-8")
        line = compile_line(text, f"{profile} positive")
        for marker in POSITIVE_MARKERS:
            require_once(
                text,
                marker.format(token_count=token_count),
                f"{profile} positive",
            )
        parameter = (
            f"-P{TEST}.TOKEN_COUNT={token_count}"
        )
        if parameter not in line:
            raise EvidenceError(
                f"{profile} compile line lacks {parameter}"
            )
        if assertions_enabled and "-DOOO_ASSERT" not in line:
            raise EvidenceError(f"{profile} did not enable OOO_ASSERT")
        if not assertions_enabled and "-DOOO_ASSERT" in line:
            raise EvidenceError(f"{profile} unexpectedly enabled OOO_ASSERT")
        positives[profile] = {
            "token_count": token_count,
            "assertions_enabled": assertions_enabled,
            "log": entry(root, log_path),
            "compiled_image": entry(
                root, profile_dir / "build" / f"{TEST}.vvp"
            ),
        }

    mutations: list[dict[str, Any]] = []
    for case, marker in MUTATION_MARKERS.items():
        case_dir = evidence / "mutations" / case
        receipt_path = case_dir / "mutator.json"
        receipt = load_json(receipt_path)
        mutant_path = case_dir / "OooMemOwnerTracker.v"
        if (
            receipt.get("schema_version") != MUTANT_SCHEMA
            or receipt.get("case") != case
            or receipt.get("changed") is not True
            or receipt.get("source_sha256") != EXPECTED_TRACKER_SHA256
            or receipt.get("mutant_sha256") != sha256(mutant_path)
        ):
            raise EvidenceError(f"mutation receipt mismatch: {case}")
        log_path = case_dir / "result/logs" / f"{TEST}.log"
        text = log_path.read_text(encoding="utf-8")
        line = compile_line(text, f"mutation {case}")
        require_once(text, marker, f"mutation {case}")
        require_once(text, "[RESULT] FAIL", f"mutation {case}")
        if f"-P{TEST}.TOKEN_COUNT=32" not in line:
            raise EvidenceError(f"mutation {case} was not run at 32 tokens")
        if "-DOOO_ASSERT" in line:
            raise EvidenceError(
                f"mutation {case} was not isolated from OOO_ASSERT"
            )
        rc_path = case_dir / "make.rc"
        mutations.append(
            {
                "case": case,
                "token_count": 32,
                "expected_marker": marker,
                "compile_success": True,
                "dynamically_rejected": True,
                "make_rc": read_nonzero_rc(rc_path, f"mutation {case}"),
                "receipt": entry(root, receipt_path),
                "mutant_rtl": entry(root, mutant_path),
                "log": entry(root, log_path),
                "compiled_image": entry(
                    root, case_dir / "build" / f"{TEST}.vvp"
                ),
            }
        )

    return {
        "schema_version": SCHEMA,
        "result": "PASS",
        "design_id": design_id,
        "unit_ids": sorted(UNIT_IDS),
        "production_tracker_sha256": EXPECTED_TRACKER_SHA256,
        "production_rtl_modified": False,
        "source_binding": {
            "rtl_pre": entry(root, rtl_pre_path),
            "rtl_post": entry(root, rtl_post_path),
            "runner_pre": entry(root, source_pre_path),
            "runner_post": entry(root, source_post_path),
            "rtl_file_count": len(rtl_pre["rtl_files"]),
            "runner_file_count": len(source_pre),
        },
        "cycle_contract": {
            "reference_model_uses_stimulus_and_edge_old_state": True,
            "dut_token_not_reused_as_expected_token": True,
            "lane0_only_checked": True,
            "lane1_only_checked": True,
            "dual_birth_last_lane_advance_checked": True,
            "blocked_lane_checked": True,
            "atomic_single_credit_zero_fire_hold_checked": True,
            "idle_and_full_hold_checked": True,
            "exact_and_bulk_death_edge_old_visibility_checked": True,
            "wraparound_checked": True,
            "production_32_token_full_scan_checked": True,
            "next_token_cursor_closed": True,
        },
        "positive_profiles": positives,
        "positive_profile_count": len(positives),
        "compile_success_mutations": mutations,
        "mutation_count": len(mutations),
        "rejected_mutation_count": len(mutations),
        "claim_boundary": (
            "Closes only tracker-next-token-cursor for the single production "
            "OooMemOwnerTracker instance under the bound current RTL and "
            "parameterized 4/32-token TB. It does not rebind V11C map/live-set "
            "evidence and excludes other holders, global no-live-reuse, "
            "whole-core/system behavior, synthesis/STA/power and PPA."
        ),
    }


def command_mutate(args: argparse.Namespace) -> int:
    source = args.input.resolve()
    output = args.output.resolve()
    receipt = args.receipt.resolve()
    original = source.read_text(encoding="utf-8")
    mutated = mutate_source(original, args.case)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(mutated, encoding="utf-8")
    receipt.parent.mkdir(parents=True, exist_ok=True)
    receipt.write_text(
        json.dumps(
            {
                "schema_version": MUTANT_SCHEMA,
                "case": args.case,
                "source_sha256": sha256(source),
                "mutant_sha256": sha256(output),
                "changed": original != mutated,
            },
            indent=2,
            sort_keys=True,
        )
        + "\n",
        encoding="utf-8",
    )
    print(
        "[V11D-CURSOR-MUTATOR][PASS] "
        f"case={args.case} mutant_sha256={sha256(output)}"
    )
    return 0


def command_build(args: argparse.Namespace) -> int:
    root = args.root.resolve()
    evidence = args.evidence_dir.resolve()
    output = args.output.resolve()
    summary = build_summary(root, evidence)
    output.write_text(
        json.dumps(summary, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    print(
        "[V11D-CURSOR-EVIDENCE][PASS] "
        f"design_id={summary['design_id']} profiles=4 "
        f"mutations={summary['mutation_count']}/"
        f"{summary['mutation_count']}"
    )
    return 0


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)

    mutate_parser = subparsers.add_parser(
        "mutate", help="create one compile-success cursor RTL variant"
    )
    mutate_parser.add_argument(
        "--case", required=True, choices=sorted(MUTATION_MARKERS)
    )
    mutate_parser.add_argument("--input", type=pathlib.Path, required=True)
    mutate_parser.add_argument("--output", type=pathlib.Path, required=True)
    mutate_parser.add_argument("--receipt", type=pathlib.Path, required=True)
    mutate_parser.set_defaults(func=command_mutate)

    build_parser = subparsers.add_parser(
        "build", help="validate focused logs and publish summary JSON"
    )
    build_parser.add_argument("--root", type=pathlib.Path, required=True)
    build_parser.add_argument(
        "--evidence-dir", type=pathlib.Path, required=True
    )
    build_parser.add_argument("--output", type=pathlib.Path, required=True)
    build_parser.set_defaults(func=command_build)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    return args.func(args)


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except EvidenceError as exc:
        print(f"[V11D-CURSOR-EVIDENCE][FAIL] {exc}", file=sys.stderr)
        raise SystemExit(1)
