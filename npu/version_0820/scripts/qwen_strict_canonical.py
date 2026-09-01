#!/usr/bin/env python3
"""Manifest-derived canonical identity helpers for the current strict path."""

from __future__ import annotations

import argparse
import pathlib
import re
import sys

import qwen_f32_alu_profiles
import qwen_f32_gather_repeat_profiles
import qwen_q8_gemv_profiles


PREFLIGHT_BEGIN_LINE = re.compile(
    r"^\[NPU-STRICT\]\[PREFLIGHT-BEGIN\] graph=(\S+) "
    r"cohort=(\d+) nodes=(\d+)$"
)
MANIFEST_LINE = re.compile(
    r"^\[NPU-STRICT\]\[MANIFEST\] graph=(\S+) cohort=(\d+) node=(\d+) "
    r"canonical_id=([0-9a-f]{64}) .* supported=([01])$"
)
PREFLIGHT_END_LINE = re.compile(
    r"^\[NPU-STRICT\]\[PREFLIGHT-END\] graph=(\S+) "
    r"cohort=(\d+) nodes=(\d+) required_seen=(\d+) supported=(\d+) "
    r"unsupported=(\d+) canonical_errors=(\d+)$"
)


def audited_manifest(path: pathlib.Path) -> tuple[dict, dict]:
    envelope = qwen_f32_alu_profiles.load_manifest(path)
    census = qwen_f32_alu_profiles.audit_manifest_object(envelope)
    return envelope, census


def emit_test_id(arguments: argparse.Namespace) -> int:
    envelope, census = audited_manifest(arguments.manifest)
    rows = {
        profile["profile_id"]: profile["canonical_nodes"]
        for profile in census["profiles"]
    }
    matches = [
        row
        for row in rows.get(arguments.profile_id, [])
        if row["index"] == arguments.node_index
    ]
    if len(matches) != 1:
        raise qwen_f32_alu_profiles.ProfileError(
            f"P{arguments.profile_id:02d} manifest node index "
            f"{arguments.node_index} matches={len(matches)}"
        )
    node = envelope["manifest"]["nodes"][arguments.node_index]
    if node["canonical_id"] != matches[0]["canonical_id"]:
        raise qwen_f32_alu_profiles.ProfileError(
            "profile census and manifest canonical identity disagree"
        )
    print(matches[0]["canonical_id"])
    return 0


def exact_q8_get_rows_nodes(envelope: dict) -> list[dict]:
    expected_semantic = {
        "graph_scope": "decoder-main",
        "layer_index": None,
        "layer_kind": "global",
        "occurrence": 0,
        "op": "GET_ROWS",
        "path": "trunk/global/model.input_embed",
        "profile": "qwen35-0.8b-b1t1-unfused-nonflash-v5",
        "role": "model.input_embed",
        "schema": "qwen-graph-semantic-key-v2",
        "source_commit": "95c409c13625a23da2aa37270339ce9179215a18",
        "subtype": "GET_ROWS",
    }
    expected_dst = {
        "flags": 16,
        "name": "model.input_embed",
        "nb": [4, 4096, 4096, 4096],
        "ne": [1024, 1, 1, 1],
        "op_desc": "GET_ROWS",
        "op_id": 40,
        "op_name": "GET_ROWS",
        "op_params_hex": "00" * 64,
        "type_id": 0,
        "type_name": "f32",
        "view_offs": 0,
        "view_src": None,
    }
    expected_sources = [
        {
            "descriptor": {
                "flags": 0,
                "name": "token_embd.weight",
                "nb": [34, 1088, 270172160, 270172160],
                "ne": [1024, 248320, 1, 1],
                "op_desc": "NONE",
                "op_id": 0,
                "op_name": "NONE",
                "op_params_hex": "00" * 64,
                "type_id": 8,
                "type_name": "q8_0",
                "view_offs": 0,
                "view_src": None,
            },
            "ref": {"index": 0, "kind": "external"},
            "slot": 0,
        },
        {
            "descriptor": {
                "flags": 1,
                "name": "inp_tokens",
                "nb": [4, 4, 4, 4],
                "ne": [1, 1, 1, 1],
                "op_desc": "NONE",
                "op_id": 0,
                "op_name": "NONE",
                "op_params_hex": "00" * 64,
                "type_id": 26,
                "type_name": "i32",
                "view_offs": 0,
                "view_src": None,
            },
            "ref": {"index": 1, "kind": "external"},
            "slot": 1,
        },
    ]
    return [
        node
        for node in envelope["manifest"]["nodes"]
        if node.get("classification") == "compute"
        and node.get("record_kind") == "node"
        and node.get("semantic_key") == expected_semantic
        and node.get("descriptor") == expected_dst
        and node.get("sources") == expected_sources
    ]


def emit_q8_id(arguments: argparse.Namespace) -> int:
    envelope, _ = audited_manifest(arguments.manifest)
    matches = exact_q8_get_rows_nodes(envelope)
    if len(matches) != 1 or matches[0].get("index") != 0:
        raise qwen_f32_alu_profiles.ProfileError(
            "canonical-v5 exact Q8_0 GET_ROWS node is not unique at index 0 "
            f"(matches={len(matches)})"
        )
    canonical_id = matches[0].get("canonical_id", "")
    if re.fullmatch(r"[0-9a-f]{64}", canonical_id) is None:
        raise qwen_f32_alu_profiles.ProfileError(
            "exact Q8_0 GET_ROWS canonical ID is malformed"
        )
    print(canonical_id)
    return 0


def verify_log(arguments: argparse.Namespace) -> int:
    envelope, census = audited_manifest(arguments.manifest)
    nodes = envelope["manifest"]["nodes"]
    expected = {
        int(node["index"]): node["canonical_id"]
        for node in nodes
        if node["classification"] != "metadata"
    }
    expected_supported = {
        row["canonical_id"]
        for profile in census["profiles"]
        for row in profile["canonical_nodes"]
    }
    q8_matches = exact_q8_get_rows_nodes(envelope)
    if len(q8_matches) != 1 or q8_matches[0].get("index") != 0:
        raise qwen_f32_alu_profiles.ProfileError(
            "frozen exact Q8_0 GET_ROWS identity changed unexpectedly"
        )
    expected_supported.add(q8_matches[0]["canonical_id"])
    q8_gemv_nodes, _ = qwen_q8_gemv_profiles.audit_q8_gemv_manifest(envelope)
    q8_gemv_ids = {node["canonical_id"] for node in q8_gemv_nodes}
    if expected_supported & q8_gemv_ids:
        raise qwen_f32_alu_profiles.ProfileError(
            "Q8 GEMV owner overlaps the existing F32/GET_ROWS support set"
        )
    expected_supported.update(q8_gemv_ids)
    f32_mover_nodes, _ = qwen_f32_gather_repeat_profiles.audit_manifest(
        envelope
    )
    f32_mover_ids = {node["canonical_id"] for node in f32_mover_nodes}
    if expected_supported & f32_mover_ids:
        raise qwen_f32_alu_profiles.ProfileError(
            "F32 mover owner overlaps the existing F32/Q8 support set"
        )
    expected_supported.update(f32_mover_ids)
    if (len(expected) != 1079 or len(q8_gemv_ids) != 187 or
            len(f32_mover_ids) != 91 or len(expected_supported) != 646):
        raise qwen_f32_alu_profiles.ProfileError(
            "frozen strict/profile census changed unexpectedly"
        )

    try:
        lines = arguments.log.read_text(encoding="utf-8").splitlines()
    except OSError as error:
        raise qwen_f32_alu_profiles.ProfileError(
            f"cannot read strict log {arguments.log}: {error}"
        ) from error
    fail_marker = (
        "[NPU-STRICT][FAIL] phase=preflight compute_started=0 "
        "required_seen=1079 assigned=0 required_enqueued=0 "
        "required_completed=0 executed=0 unsupported=433 "
        "cpu_fallback_attempts=not_observed "
        "host_tensor_arithmetic=not_observed"
    )

    completed_cohorts: list[int] = []
    seen_cohort_ids: set[int] = set()
    active: dict | None = None
    awaiting_failure: int | None = None

    for line_number, line in enumerate(lines, start=1):
        if line.startswith("[NPU-STRICT][PREFLIGHT-BEGIN]"):
            match = PREFLIGHT_BEGIN_LINE.fullmatch(line)
            if match is None:
                raise qwen_f32_alu_profiles.ProfileError(
                    f"malformed preflight BEGIN at log line {line_number}"
                )
            if active is not None:
                raise qwen_f32_alu_profiles.ProfileError(
                    f"nested preflight BEGIN at log line {line_number}"
                )
            if awaiting_failure is not None:
                raise qwen_f32_alu_profiles.ProfileError(
                    f"cohort={awaiting_failure} has no exact negative admission marker"
                )
            cohort_id = int(match.group(2))
            if cohort_id == 0 or cohort_id in seen_cohort_ids:
                raise qwen_f32_alu_profiles.ProfileError(
                    f"invalid or reused preflight cohort={cohort_id}"
                )
            seen_cohort_ids.add(cohort_id)
            active = {
                "graph": match.group(1),
                "cohort": cohort_id,
                "nodes": int(match.group(3)),
                "last_index": -1,
                "observed": {},
            }
            continue

        if line.startswith("[NPU-STRICT][MANIFEST]"):
            match = MANIFEST_LINE.fullmatch(line)
            if match is None:
                raise qwen_f32_alu_profiles.ProfileError(
                    f"malformed runtime manifest row at log line {line_number}"
                )
            if active is None:
                raise qwen_f32_alu_profiles.ProfileError(
                    f"manifest row outside a preflight cohort at log line {line_number}"
                )
            graph = match.group(1)
            cohort_id = int(match.group(2))
            if graph != active["graph"] or cohort_id != active["cohort"]:
                raise qwen_f32_alu_profiles.ProfileError(
                    f"manifest row crossed preflight cohort at log line {line_number}"
                )
            if graph != arguments.graph:
                continue
            index = int(match.group(3))
            if index in active["observed"]:
                raise qwen_f32_alu_profiles.ProfileError(
                    f"duplicate runtime strict row cohort={cohort_id} index={index}"
                )
            if index <= active["last_index"]:
                raise qwen_f32_alu_profiles.ProfileError(
                    f"runtime strict node order regressed cohort={cohort_id} "
                    f"at index={index}"
                )
            active["last_index"] = index
            active["observed"][index] = (
                match.group(4),
                match.group(5) == "1",
            )
            continue

        if line.startswith("[NPU-STRICT][PREFLIGHT-END]"):
            match = PREFLIGHT_END_LINE.fullmatch(line)
            if match is None:
                raise qwen_f32_alu_profiles.ProfileError(
                    f"malformed preflight END at log line {line_number}"
                )
            if active is None:
                raise qwen_f32_alu_profiles.ProfileError(
                    f"preflight END without BEGIN at log line {line_number}"
                )
            graph = match.group(1)
            cohort_id = int(match.group(2))
            if graph != active["graph"] or cohort_id != active["cohort"]:
                raise qwen_f32_alu_profiles.ProfileError(
                    f"preflight END crossed cohort at log line {line_number}"
                )
            if int(match.group(3)) != active["nodes"]:
                raise qwen_f32_alu_profiles.ProfileError(
                    f"preflight node count changed inside cohort={cohort_id}"
                )

            if graph == arguments.graph:
                end_census = tuple(int(match.group(group)) for group in range(3, 8))
                expected_census = (len(nodes), 1079, 646, 433, 0)
                if end_census != expected_census or active["nodes"] != len(nodes):
                    raise qwen_f32_alu_profiles.ProfileError(
                        f"runtime preflight census mismatch cohort={cohort_id} "
                        f"observed={end_census} expected={expected_census}"
                    )
                observed = active["observed"]
                if set(observed) != set(expected):
                    missing = sorted(set(expected) - set(observed))[:8]
                    extra = sorted(set(observed) - set(expected))[:8]
                    raise qwen_f32_alu_profiles.ProfileError(
                        f"runtime required-node index set mismatch cohort={cohort_id} "
                        f"missing={missing} extra={extra} observed={len(observed)}"
                    )
                for index, canonical_id in expected.items():
                    if observed[index][0] != canonical_id:
                        raise qwen_f32_alu_profiles.ProfileError(
                            f"runtime canonical ID mismatch cohort={cohort_id} "
                            f"node index={index}"
                        )
                observed_supported = {
                    canonical_id
                    for canonical_id, supported in observed.values()
                    if supported
                }
                if observed_supported != expected_supported:
                    raise qwen_f32_alu_profiles.ProfileError(
                        "runtime exact F32+Q8 support set differs from frozen "
                        "P00--P18 plus Q8 GET_ROWS/GEMV plus 91 F32 mover nodes "
                        f"identity set in cohort={cohort_id} "
                        f"({len(observed_supported)} vs 646)"
                    )
                completed_cohorts.append(cohort_id)
                awaiting_failure = cohort_id
            active = None
            continue

        if line == fail_marker:
            if active is not None or awaiting_failure is None:
                raise qwen_f32_alu_profiles.ProfileError(
                    f"unpaired exact negative admission marker at log line {line_number}"
                )
            awaiting_failure = None

    if active is not None:
        raise qwen_f32_alu_profiles.ProfileError(
            f"preflight cohort={active['cohort']} is missing END"
        )
    if awaiting_failure is not None:
        raise qwen_f32_alu_profiles.ProfileError(
            f"cohort={awaiting_failure} has no exact negative admission marker"
        )
    if len(completed_cohorts) != 2:
        raise qwen_f32_alu_profiles.ProfileError(
            f"expected two complete {arguments.graph} strict preflight "
            f"cohorts, observed={len(completed_cohorts)}"
        )
    for cohort_id in completed_cohorts:
        print(
            "[NPU-STRICT-CANONICAL][COHORT-PASS] "
            f"graph={arguments.graph} cohort={cohort_id} nodes=1711 "
            "required=1079 supported=646 unsupported=433 "
            "canonical_ids=exact-v5 negative_admission=paired"
        )
    print(
        "[NPU-STRICT-CANONICAL][PASS] "
        f"graph={arguments.graph} nodes=1711 required=1079 "
        "supported=646 unsupported=433 canonical_ids=exact-v5 "
        f"cohorts={len(completed_cohorts)}"
    )
    return 0


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest="command", required=True)

    emit = subparsers.add_parser("emit-test-id")
    emit.add_argument("--manifest", type=pathlib.Path, required=True)
    emit.add_argument("--profile-id", type=int, default=0)
    emit.add_argument("--node-index", type=int, default=30)
    emit.set_defaults(handler=emit_test_id)

    emit_q8 = subparsers.add_parser("emit-q8-id")
    emit_q8.add_argument("--manifest", type=pathlib.Path, required=True)
    emit_q8.set_defaults(handler=emit_q8_id)

    verify = subparsers.add_parser("verify-log")
    verify.add_argument("--manifest", type=pathlib.Path, required=True)
    verify.add_argument("--log", type=pathlib.Path, required=True)
    verify.add_argument("--graph", default="reserve")
    verify.set_defaults(handler=verify_log)
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    arguments = parse_args(sys.argv[1:] if argv is None else argv)
    try:
        return arguments.handler(arguments)
    except qwen_f32_alu_profiles.ProfileError as error:
        print(f"[NPU-STRICT-CANONICAL][FAIL] {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
