#!/usr/bin/env python3
"""Audit the strict-greedy sampler ARGMAX node and emit its C++ binding.

The fresh strict-greedy graph adds one required compute node after the frozen
Qwen v5 decoder graph.  This tool deliberately audits metadata only: it never
reads tensor payloads and it never implements a host sampler or arithmetic
fallback.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import pathlib
import re
import sys
from collections import Counter
from typing import Any, Mapping, Sequence


MARKER = "[NPU-SAMPLER-ARGMAX-PROFILE]"
ENVELOPE_SCHEMA = "qwen-npu-graph-manifest-envelope-v2"
MANIFEST_SCHEMA = "qwen-npu-graph-manifest-v2"
RAW_SCHEMA = "llama-npu-dispatch-graph-raw-v2"
GRAPH_PROFILE = "qwen35-0.8b-b1t1-unfused-nonflash-v5"
NUMERIC_PROFILE = "strict-f32-rne-canonical-nan-v1"
SOURCE_COMMIT = "95c409c13625a23da2aa37270339ce9179215a18"
MODEL_SHA256 = "37ae482d336108d23516fa35e8e0c4126688d81018b87178a18d752a1357814f"

MANIFEST_SHA256 = "92d404d308cb9ca6a7741233ab05f8eb07be6659dc833fb99b7cd023958fe48e"
RAW_SHA256 = "a144ef45f25e8f7a754ddd16faea09422b175d443538bf884964b2ff3685f112"

PROFILE_ID = 0
PROFILE_COUNT = 1
ARGMAX_NODE_COUNT = 1
ARGMAX_GRAPH_INDEX = 1713
ARGMAX_CANONICAL_ID = "333b5a00492fe61586c65c614c15fc3886d2da8661a6f4b818efcd78ef77d97d"
ARGMAX_DESCRIPTOR_SHA256 = (
    "58e97814cb797a28c03e9625ea07d52ba02a0426c39e0fd7efa7bbce6236be92"
)
ARGMAX_DST_NAME = "greedy_argmax"
ARGMAX_OP_ID = 18

SOURCE_GRAPH_INDEX = 1712
SOURCE_CANONICAL_ID = "6330c2787defcdae1523a0a17c46d70e4a833a07b6fe7ed9b035a13f585b5249"
SOURCE_DESCRIPTOR_SHA256 = (
    "aadf877fe98f6793b8cb550470c25d7f013a8abe58aaaf1f543a4c10fedde841"
)
SOURCE_NAME = "logits_seq_0_0 (reshaped)"
SOURCE_ELEMENT_COUNT = 248320
ZERO_OP_PARAMS = "00" * 64

EXPECTED_COUNTS = {
    "compute": 960,
    "external_tensors": 375,
    "metadata": 634,
    "mover": 120,
    "source_edges": 2474,
    "total": 1714,
}
REQUIRED_NODE_COUNT = EXPECTED_COUNTS["compute"] + EXPECTED_COUNTS["mover"]

EXPECTED_BINDINGS = {
    "model_sha256": MODEL_SHA256,
    "numeric_profile": NUMERIC_PROFILE,
    "profile": GRAPH_PROFILE,
    "source_commit": SOURCE_COMMIT,
}

EXPECTED_GRAPH = {
    "kind": "dispatch",
    "scope": "decoder-main",
    "type_id": 0,
    "type_name": "default",
}

EXPECTED_RAW_FOOTER = {
    "complete": True,
    "compute_started": False,
    "dispatch_graph_scheduler_allocated": False,
    "external_tensor_count": 375,
    "node_count": 1714,
    "record_count": 2091,
    "record_kind": "footer",
    "schema": RAW_SCHEMA,
    "source_edge_count": 2474,
}

EXPECTED_DST_DESCRIPTOR = {
    "flags": 18,
    "name": ARGMAX_DST_NAME,
    "nb": [4, 4, 4, 4],
    "ne": [1, 1, 1, 1],
    "op_desc": "ARGMAX",
    "op_id": ARGMAX_OP_ID,
    "op_name": "ARGMAX",
    "op_params_hex": ZERO_OP_PARAMS,
    "type_id": 26,
    "type_name": "i32",
    "view_offs": 0,
    "view_src": None,
}

EXPECTED_SOURCE_DESCRIPTOR = {
    "flags": 16,
    "name": SOURCE_NAME,
    "nb": [4, 993280, 993280, 993280],
    "ne": [SOURCE_ELEMENT_COUNT, 1, 1, 1],
    "op_desc": "RESHAPE",
    "op_id": 36,
    "op_name": "RESHAPE",
    "op_params_hex": ZERO_OP_PARAMS,
    "type_id": 0,
    "type_name": "f32",
    "view_offs": 0,
    "view_src": {"index": 1710, "kind": "node"},
}

EXPECTED_ARGMAX_SOURCE = {
    "descriptor": EXPECTED_SOURCE_DESCRIPTOR,
    "ref": {"index": SOURCE_GRAPH_INDEX, "kind": "node"},
    "slot": 0,
}

EXPECTED_SOURCE_NODE_SOURCES = [
    {
        "descriptor": {
            "flags": 16,
            "name": "logits_seq_0_0",
            "nb": [4, 993280, 993280, 993280],
            "ne": [SOURCE_ELEMENT_COUNT, 1, 1, 1],
            "op_desc": "VIEW",
            "op_id": 37,
            "op_name": "VIEW",
            "op_params_hex": ZERO_OP_PARAMS,
            "type_id": 0,
            "type_name": "f32",
            "view_offs": 0,
            "view_src": {"index": 1710, "kind": "node"},
        },
        "ref": {"index": 1711, "kind": "node"},
        "slot": 0,
    }
]

EXPECTED_ARGMAX_SEMANTIC_KEY = {
    "graph_scope": "decoder-main",
    "layer_index": 23,
    "layer_kind": "full-attention",
    "occurrence": 0,
    "op": "ARGMAX",
    "path": "trunk/layer/23/full-attention/greedy_argmax",
    "profile": GRAPH_PROFILE,
    "role": ARGMAX_DST_NAME,
    "schema": "qwen-graph-semantic-key-v2",
    "source_commit": SOURCE_COMMIT,
    "subtype": "ARGMAX",
}

EXPECTED_SOURCE_SEMANTIC_KEY = {
    "graph_scope": "decoder-main",
    "layer_index": 23,
    "layer_kind": "full-attention",
    "occurrence": 0,
    "op": "RESHAPE",
    "path": "trunk/layer/23/full-attention/logits_seq_0_0 (reshaped)",
    "profile": GRAPH_PROFILE,
    "role": SOURCE_NAME,
    "schema": "qwen-graph-semantic-key-v2",
    "source_commit": SOURCE_COMMIT,
    "subtype": "RESHAPE",
}

_HEX_256 = re.compile(r"^[0-9a-f]{64}$")


class ProfileError(RuntimeError):
    """The manifest no longer satisfies the exact sampler binding contract."""


def canonical_bytes(value: Any) -> bytes:
    """Encode canonical JSON exactly as the graph-manifest collector does."""

    return json.dumps(
        value, ensure_ascii=False, sort_keys=True, separators=(",", ":")
    ).encode("utf-8")


def canonical_sha256(value: Any) -> str:
    return hashlib.sha256(canonical_bytes(value)).hexdigest()


def _fail(message: str) -> None:
    raise ProfileError(message)


def _require_mapping(value: Any, label: str) -> Mapping[str, Any]:
    if not isinstance(value, Mapping):
        _fail(f"{label} must be an object")
    return value


def _require_hex256(value: Any, label: str) -> str:
    if not isinstance(value, str) or _HEX_256.fullmatch(value) is None:
        _fail(f"{label} must be 32-byte lowercase hex")
    return value


def _audit_identity(
    node: Mapping[str, Any],
    *,
    graph_index: int,
    canonical_id: str,
    descriptor_sha256: str,
    label: str,
) -> None:
    observed_id = _require_hex256(node.get("canonical_id"), f"{label} canonical_id")
    semantic_key = _require_mapping(node.get("semantic_key"), f"{label} semantic_key")
    recomputed_id = canonical_sha256(semantic_key)
    if observed_id != recomputed_id:
        _fail(f"{label} canonical_id recompute mismatch")
    if observed_id != canonical_id:
        _fail(f"{label} canonical_id changed: {observed_id}")

    observed_descriptor_sha256 = _require_hex256(
        node.get("descriptor_sha256"), f"{label} descriptor_sha256"
    )
    recomputed_descriptor_sha256 = canonical_sha256(
        {"descriptor": node.get("descriptor"), "sources": node.get("sources")}
    )
    if observed_descriptor_sha256 != recomputed_descriptor_sha256:
        _fail(f"{label} descriptor_sha256 recompute mismatch")
    if observed_descriptor_sha256 != descriptor_sha256:
        _fail(f"{label} descriptor_sha256 changed: {observed_descriptor_sha256}")
    if node.get("index") != graph_index:
        _fail(f"{label} graph index changed: {node.get('index')}")


def _looks_like_argmax(node: Mapping[str, Any]) -> bool:
    descriptor = node.get("descriptor")
    semantic_key = node.get("semantic_key")
    descriptor = descriptor if isinstance(descriptor, Mapping) else {}
    semantic_key = semantic_key if isinstance(semantic_key, Mapping) else {}
    return any(
        (
            node.get("index") == ARGMAX_GRAPH_INDEX,
            node.get("canonical_id") == ARGMAX_CANONICAL_ID,
            descriptor.get("op_id") == ARGMAX_OP_ID,
            descriptor.get("op_name") == "ARGMAX",
            descriptor.get("name") == ARGMAX_DST_NAME,
            semantic_key.get("op") == "ARGMAX",
            semantic_key.get("subtype") == "ARGMAX",
            semantic_key.get("role") == ARGMAX_DST_NAME,
        )
    )


def _audit_source_node(node: Mapping[str, Any]) -> None:
    if node.get("record_kind") != "node" or node.get("classification") != "metadata":
        _fail("ARGMAX source node record kind/classification changed")
    if node.get("descriptor") != EXPECTED_SOURCE_DESCRIPTOR:
        _fail("ARGMAX source node descriptor changed")
    if node.get("sources") != EXPECTED_SOURCE_NODE_SOURCES:
        _fail("ARGMAX source node provenance changed")
    _audit_identity(
        node,
        graph_index=SOURCE_GRAPH_INDEX,
        canonical_id=SOURCE_CANONICAL_ID,
        descriptor_sha256=SOURCE_DESCRIPTOR_SHA256,
        label="ARGMAX source node",
    )


def _audit_argmax_node(node: Mapping[str, Any]) -> None:
    if node.get("record_kind") != "node" or node.get("classification") != "compute":
        _fail("sampler ARGMAX record kind/classification changed")
    if node.get("descriptor") != EXPECTED_DST_DESCRIPTOR:
        _fail("sampler ARGMAX destination descriptor changed")
    if node.get("sources") != [EXPECTED_ARGMAX_SOURCE]:
        _fail("sampler ARGMAX source contract changed")
    _audit_identity(
        node,
        graph_index=ARGMAX_GRAPH_INDEX,
        canonical_id=ARGMAX_CANONICAL_ID,
        descriptor_sha256=ARGMAX_DESCRIPTOR_SHA256,
        label="sampler ARGMAX node",
    )


def audit_manifest_object(
    envelope: Mapping[str, Any],
) -> dict[str, Any]:
    """Audit the exact pinned fresh graph and return normalized header input."""

    if set(envelope) != {"schema", "manifest_sha256", "manifest"}:
        _fail("manifest envelope fields changed")
    if envelope.get("schema") != ENVELOPE_SCHEMA:
        _fail("manifest envelope schema mismatch")
    claimed_manifest_sha256 = _require_hex256(
        envelope.get("manifest_sha256"), "manifest payload identity"
    )
    expected_manifest_sha256 = _require_hex256(
        MANIFEST_SHA256, "expected manifest payload identity"
    )
    manifest = _require_mapping(envelope.get("manifest"), "manifest payload")
    expected_manifest_fields = {
        "counts",
        "external_tensors",
        "header",
        "nodes",
        "raw_footer",
        "raw_schema",
        "raw_sha256",
        "schema",
    }
    if set(manifest) != expected_manifest_fields:
        _fail("manifest payload fields changed")
    if manifest.get("schema") != MANIFEST_SCHEMA:
        _fail("manifest schema mismatch")
    if manifest.get("raw_schema") != RAW_SCHEMA:
        _fail("manifest raw schema mismatch")
    if manifest.get("raw_sha256") != RAW_SHA256:
        _fail("manifest raw source identity mismatch")

    counts = manifest.get("counts")
    if counts != EXPECTED_COUNTS:
        _fail(f"manifest global census changed: {counts}")
    if manifest.get("raw_footer") != EXPECTED_RAW_FOOTER:
        _fail("manifest raw footer/census changed")

    header = _require_mapping(manifest.get("header"), "manifest header")
    if header.get("schema") != RAW_SCHEMA or header.get("record_kind") != "header":
        _fail("manifest raw header schema/record kind changed")
    if header.get("collector_phase") != "process_ubatch.post_build.pre_scheduler_alloc":
        _fail("manifest collector phase changed")
    if header.get("node_count") != EXPECTED_COUNTS["total"]:
        _fail("manifest header node count changed")
    if header.get("bindings") != EXPECTED_BINDINGS:
        _fail("manifest graph bindings changed")
    if header.get("graph") != EXPECTED_GRAPH:
        _fail("manifest dispatch graph identity changed")
    runtime = _require_mapping(header.get("runtime"), "manifest runtime header")
    if (
        runtime.get("collect_only") is not True
        or runtime.get("sampler_count") != 1
        or runtime.get("n_outputs") != 1
        or runtime.get("n_outputs_max") != 1
    ):
        _fail("manifest strict sampler runtime binding changed")

    nodes_value = manifest.get("nodes")
    if not isinstance(nodes_value, list):
        _fail("manifest node list missing")
    if len(nodes_value) != EXPECTED_COUNTS["total"]:
        _fail(f"manifest node list cardinality changed: {len(nodes_value)}")
    nodes: list[Mapping[str, Any]] = []
    for position, value in enumerate(nodes_value):
        node = _require_mapping(value, f"manifest node {position}")
        if node.get("index") != position:
            _fail(
                "manifest graph indices are not exact contiguous order: "
                f"position={position} index={node.get('index')}"
            )
        sources = node.get("sources")
        if not isinstance(sources, list):
            _fail(f"manifest node {position} sources must be an array")
        if any(not isinstance(source, Mapping) for source in sources):
            _fail(f"manifest node {position} source entry must be an object")
        nodes.append(node)

    classification_census = Counter(node.get("classification") for node in nodes)
    expected_classification_census = Counter(
        {
            "compute": EXPECTED_COUNTS["compute"],
            "metadata": EXPECTED_COUNTS["metadata"],
            "mover": EXPECTED_COUNTS["mover"],
        }
    )
    if classification_census != expected_classification_census:
        _fail(f"manifest derived classification census changed: {classification_census}")
    source_edge_count = sum(len(node["sources"]) for node in nodes)
    if source_edge_count != EXPECTED_COUNTS["source_edges"]:
        _fail(f"manifest derived source-edge census changed: {source_edge_count}")
    external_tensors = manifest.get("external_tensors")
    if not isinstance(external_tensors, list) or len(external_tensors) != EXPECTED_COUNTS[
        "external_tensors"
    ]:
        observed = len(external_tensors) if isinstance(external_tensors, list) else None
        _fail(f"manifest external-tensor census changed: {observed}")

    candidates = [node for node in nodes if _looks_like_argmax(node)]
    if len(candidates) != ARGMAX_NODE_COUNT:
        _fail(f"sampler ARGMAX unique match count changed: {len(candidates)}")
    source_node = nodes[SOURCE_GRAPH_INDEX]
    argmax_node = candidates[0]
    _audit_source_node(source_node)
    _audit_argmax_node(argmax_node)

    recomputed_manifest_sha256 = canonical_sha256(manifest)
    if claimed_manifest_sha256 != recomputed_manifest_sha256:
        _fail("manifest payload hash does not match envelope field")
    if recomputed_manifest_sha256 != expected_manifest_sha256:
        _fail(f"manifest payload identity changed: {recomputed_manifest_sha256}")

    return {
        "marker": MARKER,
        "schema": "qwen-sampler-argmax-profile-v1",
        "manifest_sha256": recomputed_manifest_sha256,
        "raw_sha256": RAW_SHA256,
        "graph_profile": GRAPH_PROFILE,
        "numeric_profile": NUMERIC_PROFILE,
        "counts": dict(EXPECTED_COUNTS),
        "required_node_count": REQUIRED_NODE_COUNT,
        "profile_count": PROFILE_COUNT,
        "profiles": [
            {
                "profile_id": PROFILE_ID,
                "canonical_id": argmax_node["canonical_id"],
                "graph_node_index": ARGMAX_GRAPH_INDEX,
                "source_node_index": SOURCE_GRAPH_INDEX,
                "dst_name": ARGMAX_DST_NAME,
                "src0_name": SOURCE_NAME,
                "op_id": ARGMAX_OP_ID,
                "dst_type_id": EXPECTED_DST_DESCRIPTOR["type_id"],
                "src0_type_id": EXPECTED_SOURCE_DESCRIPTOR["type_id"],
                "dst_flags": EXPECTED_DST_DESCRIPTOR["flags"],
                "src0_flags": EXPECTED_SOURCE_DESCRIPTOR["flags"],
                "dst_ne": list(EXPECTED_DST_DESCRIPTOR["ne"]),
                "dst_nb": list(EXPECTED_DST_DESCRIPTOR["nb"]),
                "src0_ne": list(EXPECTED_SOURCE_DESCRIPTOR["ne"]),
                "src0_nb": list(EXPECTED_SOURCE_DESCRIPTOR["nb"]),
                "op_param_bytes": 64,
                "op_params_all_zero": True,
            }
        ],
    }


def load_manifest(path: pathlib.Path) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise ProfileError(f"cannot load manifest {path}: {error}") from error
    if not isinstance(value, dict):
        raise ProfileError("manifest envelope must be an object")
    return value


def load_audited(path: pathlib.Path) -> dict[str, Any]:
    return audit_manifest_object(load_manifest(path))


def _cpp_u8_array(value: str) -> str:
    _require_hex256(value, "C++ canonical ID")
    return "{{" + ", ".join(
        f"0x{value[index:index + 2]}U" for index in range(0, len(value), 2)
    ) + "}}"


def _cpp_i64_array(values: Sequence[int]) -> str:
    return "{{" + ", ".join(f"{value}LL" for value in values) + "}}"


def _cpp_size_array(values: Sequence[int]) -> str:
    return "{{" + ", ".join(f"{value}ULL" for value in values) + "}}"


def render_header(audit: Mapping[str, Any]) -> str:
    profiles = audit.get("profiles")
    if not isinstance(profiles, list) or len(profiles) != PROFILE_COUNT:
        _fail("audited sampler profile count changed before header rendering")
    profile = _require_mapping(profiles[0], "audited sampler profile")
    counts = _require_mapping(audit.get("counts"), "audited manifest counts")
    if counts != EXPECTED_COUNTS:
        _fail("audited manifest counts changed before header rendering")
    return "\n".join(
        [
            "// Generated from the audited fresh strict-greedy dispatch manifest.",
            "// Do not edit: scripts/qwen_sampler_argmax_profile.py owns this file.",
            "#ifndef QWEN_SAMPLER_ARGMAX_PROFILE_GENERATED_H",
            "#define QWEN_SAMPLER_ARGMAX_PROFILE_GENERATED_H",
            "",
            "#include <array>",
            "#include <cstddef>",
            "#include <cstdint>",
            "",
            "namespace qwen_sampler_argmax_manifest {",
            "",
            "struct manifest_counts {",
            "    std::size_t total;",
            "    std::size_t compute;",
            "    std::size_t mover;",
            "    std::size_t metadata;",
            "    std::size_t external_tensors;",
            "    std::size_t source_edges;",
            "    std::size_t required;",
            "};",
            "",
            "struct sampler_argmax_profile {",
            "    std::uint32_t profile_id;",
            "    std::uint32_t graph_node_index;",
            "    std::uint32_t source_node_index;",
            "    std::uint32_t op_id;",
            "    std::uint32_t dst_type_id;",
            "    std::uint32_t src0_type_id;",
            "    std::uint32_t dst_flags;",
            "    std::uint32_t src0_flags;",
            "    std::array<std::int64_t, 4> dst_ne;",
            "    std::array<std::size_t, 4> dst_nb;",
            "    std::array<std::int64_t, 4> src0_ne;",
            "    std::array<std::size_t, 4> src0_nb;",
            "    std::array<std::uint8_t, 32> canonical_id;",
            "    const char * dst_name;",
            "    const char * src0_name;",
            "};",
            "",
            f"inline constexpr char kAuditMarker[] = {json.dumps(MARKER)};",
            f"inline constexpr char kGraphProfile[] = {json.dumps(GRAPH_PROFILE)};",
            f"inline constexpr char kNumericProfile[] = {json.dumps(NUMERIC_PROFILE)};",
            f"inline constexpr char kManifestSha256[] = {json.dumps(audit['manifest_sha256'])};",
            f"inline constexpr char kRawSha256[] = {json.dumps(RAW_SHA256)};",
            f"inline constexpr char kCanonicalIdHex[] = {json.dumps(profile['canonical_id'])};",
            f"inline constexpr std::size_t kProfileCount = {PROFILE_COUNT}ULL;",
            f"inline constexpr std::size_t kArgmaxNodeCount = {ARGMAX_NODE_COUNT}ULL;",
            "inline constexpr std::size_t kOpParamBytes = 64ULL;",
            "inline constexpr bool kOpParamsAllZero = true;",
            "inline constexpr std::uint32_t kSourceRefKindNode = 1U;",
            "",
            "inline constexpr manifest_counts kManifestCounts = {",
            f"    {counts['total']}ULL, {counts['compute']}ULL, {counts['mover']}ULL,",
            f"    {counts['metadata']}ULL, {counts['external_tensors']}ULL,",
            f"    {counts['source_edges']}ULL, {audit['required_node_count']}ULL",
            "};",
            "",
            "inline constexpr sampler_argmax_profile kProfile = {",
            f"    {profile['profile_id']}U, {profile['graph_node_index']}U,",
            f"    {profile['source_node_index']}U, {profile['op_id']}U,",
            f"    {profile['dst_type_id']}U, {profile['src0_type_id']}U,",
            f"    {profile['dst_flags']}U, {profile['src0_flags']}U,",
            f"    {_cpp_i64_array(profile['dst_ne'])},",
            f"    {_cpp_size_array(profile['dst_nb'])},",
            f"    {_cpp_i64_array(profile['src0_ne'])},",
            f"    {_cpp_size_array(profile['src0_nb'])},",
            f"    {_cpp_u8_array(profile['canonical_id'])},",
            f"    {json.dumps(profile['dst_name'])}, {json.dumps(profile['src0_name'])}",
            "};",
            "",
            "} // namespace qwen_sampler_argmax_manifest",
            "",
            "#endif",
            "",
        ]
    )


def write_header(path: pathlib.Path, audit: Mapping[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_name(path.name + ".tmp")
    temporary.write_text(render_header(audit), encoding="utf-8")
    temporary.replace(path)


def command_audit(arguments: argparse.Namespace) -> int:
    audit = load_audited(arguments.manifest)
    counts = audit["counts"]
    profile = audit["profiles"][0]
    print(
        f"{MARKER}[PASS] profile={audit['graph_profile']} profiles={audit['profile_count']} "
        f"node={profile['graph_node_index']} source={profile['source_node_index']} "
        f"canonical_id={profile['canonical_id']} total={counts['total']} "
        f"compute={counts['compute']} mover={counts['mover']} "
        f"metadata={counts['metadata']} external={counts['external_tensors']} "
        f"source_edges={counts['source_edges']} required={audit['required_node_count']}"
    )
    return 0


def command_emit_header(arguments: argparse.Namespace) -> int:
    audit = load_audited(arguments.manifest)
    write_header(arguments.output.resolve(), audit)
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
    return result


def main(argv: Sequence[str] | None = None) -> int:
    arguments = parser().parse_args(sys.argv[1:] if argv is None else argv)
    try:
        return arguments.function(arguments)
    except ProfileError as error:
        print(f"{MARKER}[FAIL] {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
