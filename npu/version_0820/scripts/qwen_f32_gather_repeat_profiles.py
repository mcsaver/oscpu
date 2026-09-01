#!/usr/bin/env python3
"""Audit frozen-v5 F32 GET_ROWS/REPEAT nodes and emit exact C++ tables.

The manifest, rather than a handwritten list of hashes, owns the canonical
identity and GGML metadata for these two raw-bit mover kernels.
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


GET_ROWS_NODE_COUNT = 73
REPEAT_NODE_COUNT = 18
NODE_COUNT = GET_ROWS_NODE_COUNT + REPEAT_NODE_COUNT
PROFILE_COUNT = 6
GET_ROWS_PROFILE_COUNT = 5
REPEAT_PROFILE_COUNT = 1
GET_ROWS_TEST_GRAPH_INDEX = 1709
GET_ROWS_EMPTY_TEST_GRAPH_INDEX = 9
ZERO_CARDINALITY_GRAPH_INDEX = GET_ROWS_TEST_GRAPH_INDEX
REPEAT_TEST_GRAPH_INDEX = 42
CANONICAL_SET_SHA256 = (
    "ae86cbd2dc835aaabf7788968f37712ed8bd68b4f371e0145ac94867db0d3457"
)
PROFILE_SET_SHA256 = (
    "0e7695679f94171303a5a52a59c4a6e57d79874f635e3f540deff9634fa7940a"
)
ZERO_OP_PARAMS = "00" * 64
OWNER_GET_ROWS = 0
OWNER_REPEAT = 1
REF_EXTERNAL = 0
REF_NODE = 1
REF_NONE = 2


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
        "op_params_hex": descriptor["op_params_hex"],
        "type_id": descriptor["type_id"],
        "view_offs": descriptor["view_offs"],
        "view_present": descriptor["view_src"] is not None,
    }


def _owner(node: dict[str, Any]) -> int | None:
    descriptor = node.get("descriptor", {})
    sources = node.get("sources", [])
    if node.get("record_kind") != "node" or descriptor.get("type_name") != "f32":
        return None
    if (
        descriptor.get("op_name") == "GET_ROWS"
        and len(sources) == 2
        and sources[0].get("slot") == 0
        and sources[0].get("descriptor", {}).get("type_name") == "f32"
        and sources[1].get("slot") == 1
        and sources[1].get("descriptor", {}).get("type_name") == "i32"
    ):
        return OWNER_GET_ROWS
    if (
        descriptor.get("op_name") == "REPEAT"
        and len(sources) == 1
        and sources[0].get("slot") == 0
        and sources[0].get("descriptor", {}).get("type_name") == "f32"
    ):
        return OWNER_REPEAT
    return None


def _audit_ref(node: dict[str, Any], slot: int) -> None:
    source = node["sources"][slot]
    ref = source.get("ref", {})
    kind = ref.get("kind")
    index = ref.get("index")
    if kind not in ("node", "external") or type(index) is not int or index < 0:
        _fail(f"node {node['index']} source {slot} reference changed")
    if kind == "node" and index >= node["index"]:
        _fail(f"node {node['index']} source {slot} is not topologically earlier")


def _audit_get_rows(node: dict[str, Any]) -> None:
    index = node["index"]
    dst = node["descriptor"]
    src = node["sources"][0]["descriptor"]
    ids = node["sources"][1]["descriptor"]
    _audit_ref(node, 0)
    _audit_ref(node, 1)
    if node.get("classification") != "compute" or dst["op_id"] != 40:
        _fail(f"F32 GET_ROWS node {index} operation/classification changed")
    if not dst["name"] or not src["name"] or not ids["name"]:
        _fail(f"F32 GET_ROWS node {index} has an empty tensor name")
    if dst["view_src"] is not None or dst["view_offs"] != 0:
        _fail(f"F32 GET_ROWS node {index} destination became a view")
    if dst["op_params_hex"] != ZERO_OP_PARAMS:
        _fail(f"F32 GET_ROWS node {index} destination op_params changed")
    d = src["ne"][0]
    v = src["ne"][1]
    n = ids["ne"][0]
    if d not in (1024, 18432, 262144) or v != 1 or n not in (0, 1):
        _fail(f"F32 GET_ROWS node {index} D/N/V changed: {d}/{n}/{v}")
    if src["ne"] != [d, v, 1, 1] or ids["ne"] != [n, 1, 1, 1]:
        _fail(f"F32 GET_ROWS node {index} source shape changed")
    if dst["ne"] != [d, n, 1, 1]:
        _fail(f"F32 GET_ROWS node {index} destination shape changed")
    row_bytes = d * 4
    total_bytes = row_bytes * n
    if src["nb"] != [4, row_bytes, row_bytes, row_bytes]:
        _fail(f"F32 GET_ROWS node {index} source stride changed")
    if ids["nb"] != [4, n * 4, n * 4, n * 4]:
        _fail(f"F32 GET_ROWS node {index} index stride changed")
    if dst["nb"] != [4, row_bytes, total_bytes, total_bytes]:
        _fail(f"F32 GET_ROWS node {index} destination stride changed")
    if index == GET_ROWS_TEST_GRAPH_INDEX:
        if (
            d != 1024
            or n != 1
            or dst["flags"] != 18
            or src["flags"] != 18
            or ids["flags"] != 1
            or src["view_src"] is not None
            or ids["view_src"] is not None
            or node["sources"][1]["ref"].get("kind") != "external"
        ):
            _fail("terminal F32 GET_ROWS profile changed")
    else:
        if (
            d not in (18432, 262144)
            or dst["flags"] != 16
            or src["flags"] != 16
            or ids["flags"] != 16
            or src["view_src"] is None
            or ids["view_src"] is None
            or node["sources"][1]["ref"].get("kind") != "node"
        ):
            _fail(f"recurrent F32 GET_ROWS node {index} metadata changed")
        if n == 0:
            if ids["view_offs"] != 4 or not ids["op_params_hex"].startswith("04"):
                _fail(f"empty F32 GET_ROWS node {index} view contract changed")
        elif ids["view_offs"] != 0 or ids["op_params_hex"] != ZERO_OP_PARAMS:
            _fail(f"nonempty F32 GET_ROWS node {index} index contract changed")


def _audit_repeat(node: dict[str, Any]) -> None:
    index = node["index"]
    dst = node["descriptor"]
    src = node["sources"][0]["descriptor"]
    _audit_ref(node, 0)
    if (
        node.get("classification") != "mover"
        or dst["op_id"] != 20
        or dst["op_name"] != "REPEAT"
        or not dst["name"]
        or not src["name"]
    ):
        _fail(f"F32 REPEAT node {index} operation/classification changed")
    if (
        dst["ne"] != [128, 128, 16, 1]
        or dst["nb"] != [4, 512, 65536, 1048576]
        or dst["flags"] != 16
        or dst["view_src"] is not None
        or dst["view_offs"] != 0
        or dst["op_params_hex"] != ZERO_OP_PARAMS
    ):
        _fail(f"F32 REPEAT node {index} destination contract changed")
    if (
        src["ne"] != [128, 1, 16, 1]
        or src["nb"] != [4, 8192, 512, 8192]
        or src["flags"] != 16
        or src["op_id"] != 38
        or src["op_name"] != "PERMUTE"
        or src["view_src"] is None
        or src["view_offs"] != 0
        or not src["op_params_hex"].startswith(
            "00000000020000000100000003000000"
        )
    ):
        _fail(f"F32 REPEAT node {index} source contract changed")


def _profile_runtime(owner: int, spec: dict[str, Any]) -> dict[str, Any]:
    dst = spec["dst"]
    src0 = spec["srcs"][0]
    if owner == OWNER_GET_ROWS:
        src1 = spec["srcs"][1]
        d = src0["ne"][0]
        n = src1["ne"][0]
        source_rows = 0 if n == 0 else src0["ne"][1]
        return {
            "owner": owner,
            "element_count": d,
            "index_count": n,
            "source_row_count": source_rows,
            "outer_count": 0,
            "repeat_count": 0,
            "src_bytes": src0["nb"][1] * src0["ne"][1],
            "index_bytes": n * 4,
            "dst_bytes": d * n * 4,
            "src_row_stride": src0["nb"][1],
            "index_stride": src1["nb"][0],
            "dst_row_stride": dst["nb"][1],
            "dst_outer_stride": 0,
        }
    d = src0["ne"][0]
    outer = src0["ne"][2]
    repeat = dst["ne"][1] // src0["ne"][1]
    return {
        "owner": owner,
        "element_count": d,
        "index_count": 0,
        "source_row_count": 0,
        "outer_count": outer,
        "repeat_count": repeat,
        "src_bytes": src0["nb"][2] * src0["ne"][2],
        "index_bytes": 0,
        "dst_bytes": dst["nb"][2] * dst["ne"][2],
        "src_row_stride": src0["nb"][2],
        "index_stride": 0,
        "dst_row_stride": dst["nb"][1],
        "dst_outer_stride": dst["nb"][2],
    }


def audit_manifest(
    envelope: dict[str, Any],
) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    qwen_f32_alu_profiles.audit_manifest_object(envelope)
    selected = [
        node for node in envelope["manifest"]["nodes"] if _owner(node) is not None
    ]
    get_nodes = [node for node in selected if _owner(node) == OWNER_GET_ROWS]
    repeat_nodes = [node for node in selected if _owner(node) == OWNER_REPEAT]
    if len(get_nodes) != GET_ROWS_NODE_COUNT or len(repeat_nodes) != REPEAT_NODE_COUNT:
        _fail(
            "frozen mover census changed: "
            f"GET_ROWS={len(get_nodes)} REPEAT={len(repeat_nodes)}"
        )
    for node in get_nodes:
        _audit_get_rows(node)
    for node in repeat_nodes:
        _audit_repeat(node)
    selected.sort(key=lambda node: node["index"])

    canonical_ids = [node["canonical_id"] for node in selected]
    graph_indices = [node["index"] for node in selected]
    names = [
        tuple(
            [node["descriptor"]["name"]]
            + [source["descriptor"]["name"] for source in node["sources"]]
        )
        for node in selected
    ]
    if (
        len(set(canonical_ids)) != NODE_COUNT
        or len(set(graph_indices)) != NODE_COUNT
        or len(set(names)) != NODE_COUNT
    ):
        _fail("F32 mover canonical IDs, graph indices, or name tuples collide")
    if any(re.fullmatch(r"[0-9a-f]{64}", value) is None for value in canonical_ids):
        _fail("F32 mover canonical ID is malformed")
    canonical_digest = _sha256(
        [
            {"canonical_id": node["canonical_id"], "index": node["index"]}
            for node in selected
        ]
    )
    if canonical_digest != CANONICAL_SET_SHA256:
        _fail(f"F32 mover canonical set changed: {canonical_digest}")

    grouped: dict[str, list[dict[str, Any]]] = {}
    for node in selected:
        owner = _owner(node)
        key = _compact(
            {
                "owner": "get" if owner == OWNER_GET_ROWS else "repeat",
                "dst": _runtime_tensor_spec(node["descriptor"]),
                "srcs": [
                    _runtime_tensor_spec(source["descriptor"])
                    for source in node["sources"]
                ],
            }
        )
        grouped.setdefault(key, []).append(node)
    # Keep each logical kernel's profile namespace contiguous.  This also makes
    # an accidental owner reassignment visible even when its first graph index
    # interleaves with the other mover kernel.
    ordered = sorted(
        grouped.items(),
        key=lambda item: (
            0 if json.loads(item[0])["owner"] == "get" else 1,
            min(node["index"] for node in item[1]),
        ),
    )
    profiles: list[dict[str, Any]] = []
    for profile_id, (key, members) in enumerate(ordered):
        exact = json.loads(key)
        owner = OWNER_GET_ROWS if exact["owner"] == "get" else OWNER_REPEAT
        profiles.append(
            {
                "profile_id": profile_id,
                "count": len(members),
                "first_graph_index": min(node["index"] for node in members),
                "exact": exact,
                "runtime": _profile_runtime(owner, exact),
                "members": members,
            }
        )
    if len(profiles) != PROFILE_COUNT:
        _fail(f"frozen F32 mover profile count changed: {len(profiles)}")
    observed = [
        (
            profile["runtime"]["owner"],
            profile["runtime"]["element_count"],
            profile["runtime"]["index_count"],
            profile["runtime"]["outer_count"],
            profile["runtime"]["repeat_count"],
            profile["count"],
            profile["first_graph_index"],
        )
        for profile in profiles
    ]
    expected = [
        (OWNER_GET_ROWS, 18432, 1, 0, 0, 18, 7),
        (OWNER_GET_ROWS, 18432, 0, 0, 0, 18, 9),
        (OWNER_GET_ROWS, 262144, 1, 0, 0, 18, 23),
        (OWNER_GET_ROWS, 262144, 0, 0, 0, 18, 24),
        (OWNER_GET_ROWS, 1024, 1, 0, 0, 1, 1709),
        (OWNER_REPEAT, 128, 0, 16, 128, 18, 42),
    ]
    if observed != expected:
        _fail(f"frozen F32 mover ordered profiles changed: {observed}")
    profile_digest_rows = [
        {
            "owner": profile["exact"]["owner"],
            "profile": profile["exact"],
            "count": profile["count"],
            "first_graph_index": profile["first_graph_index"],
        }
        for profile in profiles
    ]
    profile_digest = _sha256(profile_digest_rows)
    if profile_digest != PROFILE_SET_SHA256:
        _fail(f"F32 mover profile set changed: {profile_digest}")
    zero_cardinality_nodes = [
        node for node in selected
        if node["index"] == ZERO_CARDINALITY_GRAPH_INDEX
    ]
    if len(zero_cardinality_nodes) != 1:
        _fail("terminal F32 GET_ROWS zero-cardinality owner changed")
    return selected, profiles


def load_audited(
    path: pathlib.Path,
) -> tuple[dict[str, Any], list[dict[str, Any]], list[dict[str, Any]]]:
    envelope = qwen_f32_alu_profiles.load_manifest(path)
    nodes, profiles = audit_manifest(envelope)
    return envelope, nodes, profiles


def _cpp_u8_array(value: str) -> str:
    return "{{" + ", ".join(
        f"0x{value[index:index + 2]}U" for index in range(0, len(value), 2)
    ) + "}}"


def _cpp_i64_array(values: list[int]) -> str:
    return "{{" + ", ".join(f"{value}LL" for value in values) + "}}"


def _cpp_size_array(values: list[int]) -> str:
    return "{{" + ", ".join(f"{value}ULL" for value in values) + "}}"


def _cpp_tensor(spec: dict[str, Any]) -> str:
    return (
        "{"
        f"{spec['type_id']}U, {spec['op_id']}U, {spec['flags']}U, "
        f"{str(spec['view_present']).lower()}, {spec['view_offs']}ULL, "
        f"{_cpp_i64_array(spec['ne'])}, {_cpp_size_array(spec['nb'])}, "
        f"{_cpp_u8_array(spec['op_params_hex'])}"
        "}"
    )


def _ref_kind(source: dict[str, Any] | None) -> int:
    if source is None:
        return REF_NONE
    return REF_NODE if source["ref"]["kind"] == "node" else REF_EXTERNAL


def render_header(nodes: list[dict[str, Any]], profiles: list[dict[str, Any]]) -> str:
    profile_for_index = {
        node["index"]: profile["profile_id"]
        for profile in profiles
        for node in profile["members"]
    }
    lines = [
        "// Generated from audited canonical-v5 dispatch.manifest.json.",
        "// Do not edit: scripts/qwen_f32_gather_repeat_profiles.py owns this file.",
        "#ifndef QWEN_F32_GATHER_REPEAT_MANIFEST_GENERATED_H",
        "#define QWEN_F32_GATHER_REPEAT_MANIFEST_GENERATED_H",
        "",
        "#include <array>",
        "#include <cstddef>",
        "#include <cstdint>",
        "",
        "namespace qwen_f32_mover_manifest {",
        "",
        "inline constexpr std::uint32_t kOwnerGetRows = 0U;",
        "inline constexpr std::uint32_t kOwnerRepeat = 1U;",
        "inline constexpr std::uint32_t kRefExternal = 0U;",
        "inline constexpr std::uint32_t kRefNode = 1U;",
        "inline constexpr std::uint32_t kRefNone = 2U;",
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
        "    std::uint32_t owner;",
        "    std::uint32_t element_count;",
        "    std::uint32_t source_row_count;",
        "    std::uint32_t index_count;",
        "    std::uint32_t outer_count;",
        "    std::uint32_t repeat_count;",
        "    std::uint64_t src_bytes;",
        "    std::uint64_t index_bytes;",
        "    std::uint64_t dst_bytes;",
        "    std::uint64_t src_row_stride;",
        "    std::uint64_t index_stride;",
        "    std::uint64_t dst_row_stride;",
        "    std::uint64_t dst_outer_stride;",
        "    tensor_spec dst;",
        "    tensor_spec src0;",
        "    bool src1_present;",
        "    tensor_spec src1;",
        "};",
        "",
        "struct canonical_node {",
        "    std::uint32_t graph_node_index;",
        "    std::uint32_t profile_id;",
        "    std::uint32_t owner;",
        "    std::array<std::uint8_t, 32> canonical_id;",
        "    const char * dst_name;",
        "    const char * src0_name;",
        "    const char * src1_name;",
        "    std::uint32_t src0_ref_kind;",
        "    std::uint32_t src0_ref_index;",
        "    std::uint32_t src1_ref_kind;",
        "    std::uint32_t src1_ref_index;",
        "    bool allow_zero_cardinality;",
        "};",
        "",
        f"inline constexpr std::size_t kProfileCount = {PROFILE_COUNT}ULL;",
        f"inline constexpr std::size_t kCanonicalNodeCount = {NODE_COUNT}ULL;",
        f"inline constexpr std::size_t kGetRowsNodeCount = {GET_ROWS_NODE_COUNT}ULL;",
        f"inline constexpr std::size_t kRepeatNodeCount = {REPEAT_NODE_COUNT}ULL;",
        f"inline constexpr char kCanonicalSetSha256[] = \"{CANONICAL_SET_SHA256}\";",
        f"inline constexpr char kProfileSetSha256[] = \"{PROFILE_SET_SHA256}\";",
        "",
        f"inline constexpr std::array<profile, {PROFILE_COUNT}> kProfiles = {{{{",
    ]
    empty_tensor = {
        "type_id": 0,
        "op_id": 0,
        "flags": 0,
        "view_present": False,
        "view_offs": 0,
        "ne": [0, 0, 0, 0],
        "nb": [0, 0, 0, 0],
        "op_params_hex": ZERO_OP_PARAMS,
    }
    for profile in profiles:
        runtime = profile["runtime"]
        exact = profile["exact"]
        src1_present = len(exact["srcs"]) == 2
        src1 = exact["srcs"][1] if src1_present else empty_tensor
        lines.append(
            "    {"
            f"{profile['profile_id']}U, {runtime['owner']}U, "
            f"{runtime['element_count']}U, {runtime['source_row_count']}U, "
            f"{runtime['index_count']}U, {runtime['outer_count']}U, "
            f"{runtime['repeat_count']}U, {runtime['src_bytes']}ULL, "
            f"{runtime['index_bytes']}ULL, {runtime['dst_bytes']}ULL, "
            f"{runtime['src_row_stride']}ULL, {runtime['index_stride']}ULL, "
            f"{runtime['dst_row_stride']}ULL, "
            f"{runtime['dst_outer_stride']}ULL, {_cpp_tensor(exact['dst'])}, "
            f"{_cpp_tensor(exact['srcs'][0])}, "
            f"{str(src1_present).lower()}, {_cpp_tensor(src1)}"
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
        owner = _owner(node)
        src0 = node["sources"][0]
        src1 = node["sources"][1] if len(node["sources"]) == 2 else None
        lines.append(
            "    {"
            f"{node['index']}U, {profile_for_index[node['index']]}U, {owner}U, "
            f"{_cpp_u8_array(node['canonical_id'])}, "
            f"{json.dumps(node['descriptor']['name'])}, "
            f"{json.dumps(src0['descriptor']['name'])}, "
            f"{json.dumps(src1['descriptor']['name'] if src1 else '')}, "
            f"{_ref_kind(src0)}U, {src0['ref']['index']}U, "
            f"{_ref_kind(src1)}U, {src1['ref']['index'] if src1 else 0}U, "
            f"{str(node['index'] == ZERO_CARDINALITY_GRAPH_INDEX).lower()}"
            "},"
        )
    lines.extend(
        [
            "}};",
            "",
            "} // namespace qwen_f32_mover_manifest",
            "",
            "#endif",
            "",
        ]
    )
    return "\n".join(lines)


def command_audit(arguments: argparse.Namespace) -> int:
    _, nodes, profiles = load_audited(arguments.manifest)
    empty_nodes = sum(
        profile["count"]
        for profile in profiles
        if profile["runtime"]["owner"] == OWNER_GET_ROWS
        and profile["runtime"]["index_count"] == 0
    )
    print(
        "[NPU-F32-MOVER-MANIFEST][PASS] "
        f"nodes={len(nodes)} get_rows={GET_ROWS_NODE_COUNT} repeat={REPEAT_NODE_COUNT} "
        f"profiles={len(profiles)} get_profiles=5 repeat_profiles=1 empty_get={empty_nodes} "
        f"canonical_set_sha256={CANONICAL_SET_SHA256} "
        f"profile_set_sha256={PROFILE_SET_SHA256}"
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
    graph_index = {
        "get": GET_ROWS_TEST_GRAPH_INDEX,
        "empty-get": GET_ROWS_EMPTY_TEST_GRAPH_INDEX,
        "repeat": REPEAT_TEST_GRAPH_INDEX,
    }[arguments.owner]
    matches = [node for node in nodes if node["index"] == graph_index]
    if len(matches) != 1:
        _fail(f"F32 mover test identity {arguments.owner} changed")
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
    test_id.add_argument("--owner", choices=("get", "empty-get", "repeat"), required=True)
    test_id.set_defaults(function=command_emit_test_id)
    return result


def main() -> int:
    arguments = parser().parse_args()
    try:
        return arguments.function(arguments)
    except qwen_f32_alu_profiles.ProfileError as error:
        print(f"[NPU-F32-MOVER-MANIFEST][FAIL] {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
