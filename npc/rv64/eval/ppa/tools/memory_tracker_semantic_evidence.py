#!/usr/bin/env python3
"""Build current-design semantic evidence for OooMemOwnerTracker.

The evidence closes only the canonical token live-set and token-to-ProducerId
map.  It deliberately excludes the next-token allocation cursor, wider holder
instances, whole-core no-live-reuse, full-system behavior and PPA.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import pathlib
import sys
from typing import Any


SCHEMA = "rv64-v11c-memory-tracker-semantic-evidence-v1"
MUTANT_SCHEMA = "rv64-v11c-memory-tracker-semantic-mutant-v1"
TEST = "tb_ooo_mem_owner_tracker"
TRACKER_PATH = "npc/rv64/vsrc/memory/OooMemOwnerTracker.v"
EXPECTED_TRACKER_SHA256 = (
    "fd7e0a1bcdd1fd12f35b07bb655db67a512c9a30c3ca0aae6bd5a41903f889c8"
)
UNIT_IDS = frozenset(
    {
        "memory-tracker-producer-map",
        "memory-tracker-live-set",
    }
)
POSITIVE_MARKERS = (
    "[V8L-TRACKER-BACKPRESSURE] full token set blocks a distinct legal ProducerId PASS",
    "[V8P-TRACKER-ATOMIC-SCARCITY] split ready causes zero owner births PASS",
    "[V11C-TRACKER-MAP-LIFECYCLE] exact token-to-ProducerId/kind/epoch scoreboard PASS",
    "[V11C-TRACKER-LIVE-SET] exact birth/hold/exact+bulk death/edge-old reuse PASS",
    "[PASS] tb_ooo_mem_owner_tracker",
    "[RESULT] PASS",
)
NEGATIVE_CASES = {
    "alloc-pid-unknown": "[V11C-TRACKER-ALLOC0-TUPLE-KNOWN]",
    "release-mask-unknown": "[V11C-TRACKER-RELEASE-MASK-KNOWN]",
    "live-map-unknown": "[V11C-TRACKER-LIVE-TUPLE-KNOWN]",
    "live-set-unknown": "[V11C-TRACKER-LIVE-MASK-KNOWN]",
}
MUTATION_MARKERS = {
    "live-mask-output-zero": "[V11C-TRACKER-LIVE-SET][FAIL]",
    "drop-live-birth": "[V11C-TRACKER-LIVE-SET][FAIL]",
    "drop-live-death": "[V11C-TRACKER-LIVE-SET][FAIL]",
    "wrong-producer-map-birth0": "[V11C-TRACKER-MAP-LIFECYCLE][FAIL]",
    "drop-producer-live-birth": "[V11C-TRACKER-MAP-LIFECYCLE][FAIL]",
    "wrong-producer-clear": "[V11C-TRACKER-MAP-LIFECYCLE][FAIL]",
    "same-edge-exact-token-reuse": (
        "exact death exposed an edge-old live token to a distinct PID"
    ),
    "same-edge-bulk-token-reuse": (
        "STORE bulk death exposed an edge-old live token to a distinct PID"
    ),
    "allow-dual-duplicate-pid": (
        "duplicate dual ProducerId did not select exactly one birth"
    ),
}


class EvidenceError(RuntimeError):
    """Raised when a mutation or evidence record is not auditable."""


def sha256(path: pathlib.Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


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


def mutate_source(text: str, case: str) -> str:
    if case == "live-mask-output-zero":
        return replace_once(
            text,
            "  assign live_mask_o = live_q;\n",
            "  assign live_mask_o = {TOKEN_COUNT{1'b0}};\n",
            case,
        )
    if case == "drop-live-birth":
        return replace_once(
            text,
            "    live_next_r = (live_q & ~death_mask_r) | birth_mask_r;\n",
            "    live_next_r = live_q & ~death_mask_r;\n",
            case,
        )
    if case == "drop-live-death":
        return replace_once(
            text,
            "    live_next_r = (live_q & ~death_mask_r) | birth_mask_r;\n",
            "    live_next_r = live_q | birth_mask_r;\n",
            case,
        )
    if case == "wrong-producer-map-birth0":
        return replace_once(
            text,
            "        producer_id_q[alloc0_token_o] <= alloc0_producer_id_i;\n",
            "        producer_id_q[alloc0_token_o] <= ~alloc0_producer_id_i;\n",
            case,
        )
    if case == "drop-producer-live-birth":
        return replace_once(
            text,
            "    producer_live_next_r =\n"
            "        (producer_live_q & ~producer_clear_mask_r) |\n"
            "        producer_set_mask_r;\n",
            "    producer_live_next_r =\n"
            "        producer_live_q & ~producer_clear_mask_r;\n",
            case,
        )
    if case == "wrong-producer-clear":
        return replace_once(
            text,
            "        producer_clear_mask_r[producer_id_q[event_i]] = 1'b1;\n",
            "        producer_clear_mask_r[~producer_id_q[event_i]] = 1'b1;\n",
            case,
        )
    if case == "same-edge-exact-token-reuse":
        return replace_once(
            text,
            "      if (!alloc0_found_r &&\n"
            "          !live_q[token_at_offset(next_token_q, scan0_i)]) begin\n",
            "      if (!alloc0_found_r &&\n"
            "          (!live_q[token_at_offset(next_token_q, scan0_i)] ||\n"
            "           (free0_valid_i && free0_exact_w &&\n"
            "            (token_at_offset(next_token_q, scan0_i) ==\n"
            "             free0_token_i)))) begin\n",
            case,
        )
    if case == "same-edge-bulk-token-reuse":
        return replace_once(
            text,
            "      if (!alloc0_found_r &&\n"
            "          !live_q[token_at_offset(next_token_q, scan0_i)]) begin\n",
            "      if (!alloc0_found_r &&\n"
            "          (!live_q[token_at_offset(next_token_q, scan0_i)] ||\n"
            "           release_effective_w[\n"
            "             token_at_offset(next_token_q, scan0_i)])) begin\n",
            case,
        )
    if case == "allow-dual-duplicate-pid":
        return replace_once(
            text,
            "  assign alloc1_ready_o = PARAM_SHAPE_VALID && alloc1_found_r &&\n"
            "      (alloc1_kind_i != OWNER_KIND_RESERVED) && alloc1_pid_clear_w &&\n"
            "      !(alloc0_claim_w &&\n"
            "        (alloc1_producer_id_i == alloc0_producer_id_i));\n",
            "  assign alloc1_ready_o = PARAM_SHAPE_VALID && alloc1_found_r &&\n"
            "      (alloc1_kind_i != OWNER_KIND_RESERVED) && alloc1_pid_clear_w;\n",
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


def build_summary(
    root: pathlib.Path,
    evidence: pathlib.Path,
) -> dict[str, Any]:
    design_id = current_design_id(root)
    tracker = root / TRACKER_PATH
    if sha256(tracker) != EXPECTED_TRACKER_SHA256:
        raise EvidenceError(
            "production tracker RTL differs from the reviewed V8L/V11C source"
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
    for profile in ("assert", "release"):
        path = evidence / profile / "result/logs" / f"{TEST}.log"
        text = path.read_text(encoding="utf-8")
        line = compile_line(text, f"{profile} positive")
        for marker in POSITIVE_MARKERS:
            require_once(text, marker, f"{profile} positive")
        if profile == "assert" and "-DOOO_ASSERT" not in line:
            raise EvidenceError("assert profile did not enable OOO_ASSERT")
        if profile == "release" and "-DOOO_ASSERT" in line:
            raise EvidenceError("release profile enabled OOO_ASSERT")
        positives[profile] = entry(root, path)

    negatives: list[dict[str, Any]] = []
    for case, marker in NEGATIVE_CASES.items():
        case_dir = evidence / "negative" / case
        log_path = case_dir / "result/logs" / f"{TEST}.log"
        text = log_path.read_text(encoding="utf-8")
        line = compile_line(text, f"negative {case}")
        require_once(text, marker, f"negative {case}")
        require_once(text, "[RESULT] FAIL", f"negative {case}")
        if "-DOOO_ASSERT" in line:
            raise EvidenceError(
                f"negative {case} must use the external checker only"
            )
        image = case_dir / "build" / f"{TEST}.vvp"
        negatives.append(
            {
                "case": case,
                "expected_marker": marker,
                "compile_success": True,
                "dynamically_rejected": True,
                "log": entry(root, log_path),
                "compiled_image": entry(root, image),
            }
        )

    mutations: list[dict[str, Any]] = []
    for case, marker in MUTATION_MARKERS.items():
        case_dir = evidence / "mutations" / case
        receipt_path = case_dir / "mutator.json"
        receipt = load_json(receipt_path)
        if (
            receipt.get("schema_version") != MUTANT_SCHEMA
            or receipt.get("case") != case
            or receipt.get("changed") is not True
            or receipt.get("source_sha256") != EXPECTED_TRACKER_SHA256
        ):
            raise EvidenceError(f"mutation receipt mismatch: {case}")
        log_path = case_dir / "result/logs" / f"{TEST}.log"
        text = log_path.read_text(encoding="utf-8")
        line = compile_line(text, f"mutation {case}")
        require_once(text, marker, f"mutation {case}")
        require_once(text, "[RESULT] FAIL", f"mutation {case}")
        if (
            "-DV11C_DISABLE_SEMANTIC_CHECKER" not in line
            or "-DOOO_ASSERT" in line
        ):
            raise EvidenceError(
                f"mutation {case} was not isolated to the TB scoreboard"
            )
        image = case_dir / "build" / f"{TEST}.vvp"
        mutations.append(
            {
                "case": case,
                "expected_marker": marker,
                "compile_success": True,
                "dynamically_rejected": True,
                "receipt": entry(root, receipt_path),
                "log": entry(root, log_path),
                "compiled_image": entry(root, image),
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
            "allocation_scans_edge_old_live_set": True,
            "birth_and_death_are_disjoint": True,
            "exact_death_same_edge_reuse_rejected": True,
            "bulk_death_same_edge_reuse_rejected": True,
            "next_cycle_reuse_observed": True,
            "token_to_producer_map_checked_each_observed_edge": True,
            "next_token_cursor_closed": False,
        },
        "positive_profiles": positives,
        "positive_profile_count": len(positives),
        "unknown_negatives": negatives,
        "unknown_negative_count": len(negatives),
        "compile_success_mutations": mutations,
        "mutation_count": len(mutations),
        "rejected_mutation_count": len(mutations),
        "claim_boundary": (
            "Closes only memory-tracker-producer-map and "
            "memory-tracker-live-set for the single elaborated "
            "OooMemOwnerTracker instance under the bound current RTL/TB/"
            "checker. It excludes tracker-next-token-cursor, other holder "
            "units or instances, whole-core no-live-reuse, system replay, "
            "synthesis/STA/power and PPA."
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
        "[V11C-TRACKER-MUTATOR][PASS] "
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
        "[V11C-TRACKER-EVIDENCE][PASS] "
        f"design_id={summary['design_id']} profiles=2 "
        f"unknown={summary['unknown_negative_count']} "
        f"mutations={summary['mutation_count']}/"
        f"{summary['mutation_count']}"
    )
    return 0


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)

    mutate_parser = subparsers.add_parser(
        "mutate", help="create one compile-success RTL semantic variant"
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
        print(f"[V11C-TRACKER-EVIDENCE][FAIL] {exc}", file=sys.stderr)
        raise SystemExit(1)
