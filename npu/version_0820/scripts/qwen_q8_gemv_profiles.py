#!/usr/bin/env python3
"""Frozen-v5 canonical Q8_0 MUL_MAT profiles and generated C++ tables.

The manifest owns both the 187-node semantic identity set and the exact GGML
metadata profiles.  This module audits that source before it emits any build
input; no canonical digest or profile row is handwritten into runtime code.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import pathlib
import re
import sys
from typing import Any

import qwen_f32_alu_profiles


NODE_COUNT = 187
EXCLUDED_F16_MUL_MAT_COUNT = 12
PROFILE_COUNT = 10
MINIMAL_PROFILE_GRAPH_INDEX = 28
ZERO_CARDINALITY_GRAPH_INDEX = 1710
CANONICAL_SET_SHA256 = (
    "f08be48521cc47cee08e078bff68df3a92c6a417edddf086ee6d76dc30aaf843"
)
RUNTIME_PROFILES_SHA256 = (
    "d8fcffb195ccd1ed90b9af948d5460ebca4b8ea27b4d5872c87fe26469bf50b7"
)
ZERO_OP_PARAMS = "00" * 64


def _fail(message: str) -> None:
    raise qwen_f32_alu_profiles.ProfileError(message)


def _compact(value: Any) -> str:
    return json.dumps(
        value, ensure_ascii=False, sort_keys=True, separators=(",", ":")
    )


def _sha256(value: Any) -> str:
    return hashlib.sha256(_compact(value).encode("utf-8")).hexdigest()


def _runtime_tensor_spec(descriptor: dict[str, Any]) -> dict[str, Any]:
    return {
        "flags": descriptor["flags"],
        "nb": descriptor["nb"],
        "ne": descriptor["ne"],
        "op_id": descriptor["op_id"],
        "op_name": descriptor["op_name"],
        "op_params_hex": descriptor["op_params_hex"],
        "type_id": descriptor["type_id"],
        "type_name": descriptor["type_name"],
        "view_offs": descriptor["view_offs"],
        "view_present": descriptor["view_src"] is not None,
    }


def _is_q8_gemv_candidate(node: dict[str, Any]) -> bool:
    sources = node.get("sources")
    return (
        node.get("record_kind") == "node"
        and node.get("classification") == "compute"
        and node.get("descriptor", {}).get("op_name") == "MUL_MAT"
        and node["descriptor"].get("type_name") == "f32"
        and isinstance(sources, list)
        and len(sources) == 2
        and sources[0].get("slot") == 0
        and sources[0].get("descriptor", {}).get("type_name") == "q8_0"
        and sources[1].get("slot") == 1
        and sources[1].get("descriptor", {}).get("type_name") == "f32"
    )


def _audit_node_contract(node: dict[str, Any]) -> None:
    dst = node["descriptor"]
    weight = node["sources"][0]["descriptor"]
    activation = node["sources"][1]["descriptor"]
    index = node["index"]

    if node["sources"][0]["ref"].get("kind") != "external":
        _fail(f"Q8 GEMV node {index} weight is not an external source")
    if node["sources"][1]["ref"].get("kind") != "node":
        _fail(f"Q8 GEMV node {index} activation is not a graph-node source")
    weight_ref = node["sources"][0]["ref"].get("index")
    activation_ref = node["sources"][1]["ref"].get("index")
    if type(weight_ref) is not int or weight_ref < 0:
        _fail(f"Q8 GEMV node {index} weight source reference changed")
    if (type(activation_ref) is not int or activation_ref < 0 or
            activation_ref >= index):
        _fail(f"Q8 GEMV node {index} activation source reference changed")
    if not dst["name"] or not weight["name"] or not activation["name"]:
        _fail(f"Q8 GEMV node {index} has an empty tensor identity name")
    if dst["op_id"] != 29 or dst["op_name"] != "MUL_MAT":
        _fail(f"Q8 GEMV node {index} operation identity changed")
    if dst["op_params_hex"] != ZERO_OP_PARAMS:
        _fail(f"Q8 GEMV node {index} op_params are not exactly zero")
    if weight["op_id"] != 0 or weight["op_name"] != "NONE":
        _fail(f"Q8 GEMV node {index} weight is not a leaf")
    if weight["op_params_hex"] != ZERO_OP_PARAMS:
        _fail(f"Q8 GEMV node {index} weight op_params changed")
    if dst["view_src"] is not None or dst["view_offs"] != 0:
        _fail(f"Q8 GEMV node {index} destination unexpectedly became a view")
    if weight["view_src"] is not None or weight["view_offs"] != 0:
        _fail(f"Q8 GEMV node {index} weight unexpectedly became a view")
    if activation["view_offs"] != 0:
        _fail(f"Q8 GEMV node {index} activation has a nonzero view offset")
    for role, descriptor in (
        ("destination", dst),
        ("weight", weight),
        ("activation", activation),
    ):
        if re.fullmatch(r"[0-9a-f]{128}", descriptor["op_params_hex"]) is None:
            _fail(f"Q8 GEMV node {index} {role} op_params encoding changed")

    if len(dst["ne"]) != 4 or len(weight["ne"]) != 4 or len(activation["ne"]) != 4:
        _fail(f"Q8 GEMV node {index} rank changed")
    k = weight["ne"][0]
    m = weight["ne"][1]
    if (
        type(k) is not int
        or type(m) is not int
        or k < 32
        or k > 4096
        or k % 32 != 0
        or m < 1
        or m > 248320
    ):
        _fail(f"Q8 GEMV node {index} K/M capability changed: K={k} M={m}")
    if weight["ne"] != [k, m, 1, 1]:
        _fail(f"Q8 GEMV node {index} weight shape is not [K,M,1,1]")
    if activation["ne"] != [k, 1, 1, 1]:
        _fail(f"Q8 GEMV node {index} activation shape is not [K,1,1,1]")
    if dst["ne"] != [m, 1, 1, 1]:
        _fail(f"Q8 GEMV node {index} destination shape is not [M,1,1,1]")

    weight_row_bytes = (k // 32) * 34
    weight_bytes = weight_row_bytes * m
    activation_bytes = k * 4
    dst_bytes = m * 4
    if weight["nb"] != [34, weight_row_bytes, weight_bytes, weight_bytes]:
        _fail(f"Q8 GEMV node {index} packed weight strides changed")
    if activation["nb"] != [4, activation_bytes, activation_bytes, activation_bytes]:
        _fail(f"Q8 GEMV node {index} activation strides changed")
    if dst["nb"] != [4, dst_bytes, dst_bytes, dst_bytes]:
        _fail(f"Q8 GEMV node {index} destination strides changed")

    terminal_output = index == 1710
    expected_flags = 18 if terminal_output else 16
    if dst["flags"] != expected_flags or activation["flags"] != expected_flags:
        _fail(f"Q8 GEMV node {index} compute/output flags changed")
    if weight["flags"] != 0:
        _fail(f"Q8 GEMV node {index} weight flags changed")


def audit_q8_gemv_manifest(
    envelope: dict[str, Any],
) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    qwen_f32_alu_profiles.audit_manifest_object(envelope)
    nodes = envelope["manifest"]["nodes"]
    selected = [node for node in nodes if _is_q8_gemv_candidate(node)]
    excluded_f16 = [
        node
        for node in nodes
        if node.get("record_kind") == "node"
        and node.get("classification") == "compute"
        and node.get("descriptor", {}).get("op_name") == "MUL_MAT"
        and len(node.get("sources", [])) >= 1
        and node["sources"][0].get("descriptor", {}).get("type_name") == "f16"
    ]
    if len(selected) != NODE_COUNT:
        _fail(f"frozen Q8 GEMV node count changed: {len(selected)}")
    if len(excluded_f16) != EXCLUDED_F16_MUL_MAT_COUNT:
        _fail(f"frozen F16 attention MUL_MAT count changed: {len(excluded_f16)}")

    canonical_ids = [node["canonical_id"] for node in selected]
    graph_indices = [node["index"] for node in selected]
    runtime_names = [
        (
            node["descriptor"]["name"],
            node["sources"][0]["descriptor"]["name"],
            node["sources"][1]["descriptor"]["name"],
        )
        for node in selected
    ]
    if len(set(canonical_ids)) != NODE_COUNT or len(set(graph_indices)) != NODE_COUNT:
        _fail("Q8 GEMV canonical IDs or graph indices are not unique")
    if len(set(runtime_names)) != NODE_COUNT:
        _fail("Q8 GEMV destination/source name tuples are not unique")
    if any(re.fullmatch(r"[0-9a-f]{64}", value) is None for value in canonical_ids):
        _fail("Q8 GEMV canonical ID is malformed")
    for node in selected:
        _audit_node_contract(node)

    grouped: dict[str, list[dict[str, Any]]] = {}
    for node in selected:
        key = _compact(
            {
                "dst": _runtime_tensor_spec(node["descriptor"]),
                "src0": _runtime_tensor_spec(node["sources"][0]["descriptor"]),
                "src1": _runtime_tensor_spec(node["sources"][1]["descriptor"]),
            }
        )
        grouped.setdefault(key, []).append(node)
    ordered_groups = sorted(
        grouped.items(), key=lambda item: min(node["index"] for node in item[1])
    )
    if len(ordered_groups) != PROFILE_COUNT:
        _fail(f"frozen Q8 GEMV runtime profile count changed: {len(ordered_groups)}")

    profiles: list[dict[str, Any]] = []
    for profile_id, (key, members) in enumerate(ordered_groups):
        spec = json.loads(key)
        weight = spec["src0"]
        profiles.append(
            {
                "profile_id": profile_id,
                "count": len(members),
                "first_graph_index": min(node["index"] for node in members),
                "k": weight["ne"][0],
                "m": weight["ne"][1],
                "block_count": weight["ne"][0] // 32,
                "activation_bytes": weight["ne"][0] * 4,
                "weight_row_stride": weight["nb"][1],
                "weight_bytes": weight["nb"][2],
                "dst_row_stride": 4,
                "dst_bytes": weight["ne"][1] * 4,
                "dst": spec["dst"],
                "weight": spec["src0"],
                "activation": spec["src1"],
                "members": members,
            }
        )

    node_digest = _sha256(
        [
            {"canonical_id": node["canonical_id"], "index": node["index"]}
            for node in selected
        ]
    )
    profile_digest = _sha256(
        [
            {
                "dst": profile["dst"],
                "src0": profile["weight"],
                "src1": profile["activation"],
            }
            for profile in profiles
        ]
    )
    if node_digest != CANONICAL_SET_SHA256:
        _fail(f"Q8 GEMV canonical identity set changed: {node_digest}")
    if profile_digest != RUNTIME_PROFILES_SHA256:
        _fail(f"Q8 GEMV runtime profile set changed: {profile_digest}")

    expected_shapes = [
        (1024, 6144, 18, False, 16),
        (1024, 16, 36, False, 16),
        (1024, 2048, 18, False, 16),
        (2048, 1024, 18, True, 16),
        (1024, 3584, 48, False, 16),
        (3584, 1024, 24, False, 16),
        (1024, 4096, 6, False, 16),
        (1024, 512, 12, False, 16),
        (2048, 1024, 6, False, 16),
        (1024, 248320, 1, False, 18),
    ]
    observed_shapes = [
        (
            profile["k"],
            profile["m"],
            profile["count"],
            profile["activation"]["view_present"],
            profile["dst"]["flags"],
        )
        for profile in profiles
    ]
    if observed_shapes != expected_shapes:
        _fail(f"Q8 GEMV ordered profile census changed: {observed_shapes}")

    minimal = [
        node
        for node in selected
        if node["index"] == MINIMAL_PROFILE_GRAPH_INDEX
        and node["descriptor"]["ne"] == [16, 1, 1, 1]
        and node["sources"][0]["descriptor"]["ne"] == [1024, 16, 1, 1]
    ]
    if len(minimal) != 1:
        _fail("canonical minimal M16/K1024 node is no longer unique at index 28")
    zero_cardinality_nodes = [
        node for node in selected
        if node["index"] == ZERO_CARDINALITY_GRAPH_INDEX
    ]
    if len(zero_cardinality_nodes) != 1:
        _fail("terminal Q8 GEMV zero-cardinality owner changed")
    return selected, profiles


def load_audited(path: pathlib.Path) -> tuple[dict[str, Any], list[dict[str, Any]], list[dict[str, Any]]]:
    envelope = qwen_f32_alu_profiles.load_manifest(path)
    nodes, profiles = audit_q8_gemv_manifest(envelope)
    return envelope, nodes, profiles


def _cpp_u8_array(hex_digest: str) -> str:
    return "{{" + ", ".join(
        f"0x{hex_digest[index:index + 2]}U" for index in range(0, 64, 2)
    ) + "}}"


def _cpp_i64_array(values: list[int]) -> str:
    return "{{" + ", ".join(f"{value}LL" for value in values) + "}}"


def _cpp_size_array(values: list[int]) -> str:
    return "{{" + ", ".join(f"{value}ULL" for value in values) + "}}"


def _cpp_hex_array(value: str) -> str:
    return "{{" + ", ".join(
        f"0x{value[index:index + 2]}U" for index in range(0, len(value), 2)
    ) + "}}"


def _cpp_tensor(spec: dict[str, Any]) -> str:
    return (
        "{"
        f"{spec['type_id']}U, {spec['op_id']}U, {spec['flags']}U, "
        f"{str(spec['view_present']).lower()}, {spec['view_offs']}ULL, "
        f"{_cpp_i64_array(spec['ne'])}, {_cpp_size_array(spec['nb'])}, "
        f"{_cpp_hex_array(spec['op_params_hex'])}"
        "}"
    )


def render_header(nodes: list[dict[str, Any]], profiles: list[dict[str, Any]]) -> str:
    profile_for_index: dict[int, int] = {}
    for profile in profiles:
        for node in profile["members"]:
            profile_for_index[node["index"]] = profile["profile_id"]

    lines = [
        "// Generated from audited canonical-v5 dispatch.manifest.json.",
        "// Do not edit: scripts/qwen_q8_gemv_profiles.py owns this file.",
        "#ifndef QWEN_Q8_GEMV_MANIFEST_GENERATED_H",
        "#define QWEN_Q8_GEMV_MANIFEST_GENERATED_H",
        "",
        "#include <array>",
        "#include <cstddef>",
        "#include <cstdint>",
        "",
        "namespace qwen_q8_gemv_manifest {",
        "",
        "struct tensor_spec {",
        "    std::uint32_t type_id;",
        "    std::uint32_t op_id;",
        "    std::uint32_t flags;",
        "    bool view_present;",
        "    std::uint64_t view_offs;",
        "    std::array<std::int64_t, 4> ne;",
        "    std::array<std::size_t, 4> nb;",
        "    std::array<std::uint8_t, 64> op_params;",
        "};",
        "",
        "struct profile {",
        "    std::uint32_t profile_id;",
        "    std::uint32_t k;",
        "    std::uint32_t m;",
        "    std::uint32_t block_count;",
        "    std::uint64_t activation_bytes;",
        "    std::uint64_t weight_row_stride;",
        "    std::uint64_t weight_bytes;",
        "    std::uint64_t dst_row_stride;",
        "    std::uint64_t dst_bytes;",
        "    tensor_spec dst;",
        "    tensor_spec weight;",
        "    tensor_spec activation;",
        "};",
        "",
        "struct canonical_node {",
        "    std::uint32_t graph_node_index;",
        "    std::uint32_t profile_id;",
        "    std::array<std::uint8_t, 32> canonical_id;",
        "    const char * dst_name;",
        "    const char * weight_name;",
        "    const char * activation_name;",
        "    std::uint32_t weight_ref_index;",
        "    std::uint32_t activation_ref_index;",
        "    bool allow_zero_cardinality;",
        "};",
        "",
        f"inline constexpr std::size_t kProfileCount = {PROFILE_COUNT}ULL;",
        f"inline constexpr std::size_t kCanonicalNodeCount = {NODE_COUNT}ULL;",
        f"inline constexpr char kCanonicalSetSha256[] = \"{CANONICAL_SET_SHA256}\";",
        f"inline constexpr char kRuntimeProfilesSha256[] = \"{RUNTIME_PROFILES_SHA256}\";",
        "",
        f"inline constexpr std::array<profile, {PROFILE_COUNT}> kProfiles = {{{{",
    ]
    for profile in profiles:
        lines.append(
            "    {"
            f"{profile['profile_id']}U, {profile['k']}U, {profile['m']}U, "
            f"{profile['block_count']}U, {profile['activation_bytes']}ULL, "
            f"{profile['weight_row_stride']}ULL, {profile['weight_bytes']}ULL, "
            f"{profile['dst_row_stride']}ULL, {profile['dst_bytes']}ULL, "
            f"{_cpp_tensor(profile['dst'])}, "
            f"{_cpp_tensor(profile['weight'])}, "
            f"{_cpp_tensor(profile['activation'])}"
            "},"
        )
    lines.extend(
        [
            "}};",
            "",
            f"inline constexpr std::array<canonical_node, {NODE_COUNT}> kCanonicalNodes = {{{{",
        ]
    )
    for node in nodes:
        lines.append(
            "    {"
            f"{node['index']}U, {profile_for_index[node['index']]}U, "
            f"{_cpp_u8_array(node['canonical_id'])}, "
            f"{json.dumps(node['descriptor']['name'])}, "
            f"{json.dumps(node['sources'][0]['descriptor']['name'])}, "
            f"{json.dumps(node['sources'][1]['descriptor']['name'])}, "
            f"{node['sources'][0]['ref']['index']}U, "
            f"{node['sources'][1]['ref']['index']}U, "
            f"{str(node['index'] == ZERO_CARDINALITY_GRAPH_INDEX).lower()}"
            "},"
        )
    lines.extend(
        [
            "}};",
            "",
            "} // namespace qwen_q8_gemv_manifest",
            "",
            "#endif",
            "",
        ]
    )
    return "\n".join(lines)


def command_audit(arguments: argparse.Namespace) -> int:
    _, nodes, profiles = load_audited(arguments.manifest)
    print(
        "[NPU-Q8-GEMV-MANIFEST][PASS] "
        f"nodes={len(nodes)} profiles={len(profiles)} excluded_f16=12 "
        "k=1024+2048+3584 b=32+64+112 "
        "m=16+512+1024+2048+3584+4096+6144+248320 "
        f"canonical_set_sha256={CANONICAL_SET_SHA256} "
        f"profile_set_sha256={RUNTIME_PROFILES_SHA256}"
    )
    return 0


def command_emit_header(arguments: argparse.Namespace) -> int:
    _, nodes, profiles = load_audited(arguments.manifest)
    output = arguments.output.resolve()
    output.parent.mkdir(parents=True, exist_ok=True)
    temporary = output.with_suffix(output.suffix + ".tmp")
    temporary.write_text(render_header(nodes, profiles), encoding="utf-8")
    temporary.replace(output)
    return 0


def command_emit_test_id(arguments: argparse.Namespace) -> int:
    _, nodes, _ = load_audited(arguments.manifest)
    matches = [node for node in nodes if node["index"] == MINIMAL_PROFILE_GRAPH_INDEX]
    if len(matches) != 1:
        _fail("minimal Q8 GEMV canonical test node changed")
    print(matches[0]["canonical_id"])
    return 0


def parser() -> argparse.ArgumentParser:
    result = argparse.ArgumentParser()
    subparsers = result.add_subparsers(dest="command", required=True)

    audit = subparsers.add_parser("audit")
    audit.add_argument("--manifest", required=True, type=pathlib.Path)
    audit.set_defaults(function=command_audit)

    header = subparsers.add_parser("emit-header")
    header.add_argument("--manifest", required=True, type=pathlib.Path)
    header.add_argument("--output", required=True, type=pathlib.Path)
    header.set_defaults(function=command_emit_header)

    test_id = subparsers.add_parser("emit-test-id")
    test_id.add_argument("--manifest", required=True, type=pathlib.Path)
    test_id.set_defaults(function=command_emit_test_id)
    return result


def main() -> int:
    arguments = parser().parse_args()
    try:
        return arguments.function(arguments)
    except qwen_f32_alu_profiles.ProfileError as error:
        print(f"[NPU-Q8-GEMV-MANIFEST][FAIL] {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
