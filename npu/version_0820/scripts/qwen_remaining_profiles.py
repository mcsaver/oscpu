#!/usr/bin/env python3
"""Audit and emit the exact frozen-v5 profiles for the remaining 433 nodes.

This module is metadata-only.  It validates the frozen graph identity, proves
that the existing 646-owner set and this 433-node set are a disjoint partition
of every required compute/mover node, and emits a deterministic C++ header.
It never reads tensor payloads and performs no floating-point computation.
"""

from __future__ import annotations

import argparse
import dataclasses
import hashlib
import json
import pathlib
import re
import sys
from collections import Counter
from typing import Any, Mapping, Sequence


SCRIPT_DIR = pathlib.Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

import qwen_f32_alu_profiles  # noqa: E402
import qwen_f32_gather_repeat_profiles  # noqa: E402
import qwen_q8_gemv_profiles  # noqa: E402


MARKER = "QWEN_REMAINING_433_EXACT_V1"
NODE_COUNT = 433
PROFILE_COUNT = 30
EXISTING_OWNER_NODE_COUNT = 646
SAMPLER_ARGMAX_NODE_COUNT = 1
REQUIRED_NONMETADATA_COUNT = 1080
GRAPH_NODE_COUNT = 1714
SAMPLER_ARGMAX_INDEX = 1713
SAMPLER_ARGMAX_CANONICAL_ID = (
    "333b5a00492fe61586c65c614c15fc3886d2da8661a6f4b818efcd78ef77d97d"
)
MAX_SOURCES = 3
ROUTE_SENTINEL = 0xFFFFFFFF
ZERO_OP_PARAMS = "00" * 64

# Filled from canonical JSON rows produced by _audit_catalog().  These are not
# manifest substitutes: audit_manifest_object() first revalidates the complete
# frozen manifest through qwen_f32_alu_profiles.audit_manifest_object().
CANONICAL_SET_SHA256 = (
    "ef0a458d780a94185d7555c7f02e7ab65daa11ddc0c9432a665ba80cc9591048"
)
PROFILE_SET_SHA256 = (
    "585980e9c9863e6df3823263222fee58fd4bba815e5aa4ebb21f78dcbd86ac05"
)


@dataclasses.dataclass(frozen=True)
class OwnerSpec:
    owner_id: int
    enum_name: str
    label: str
    op_name: str
    op_id: int
    classification: str
    node_count: int
    profile_count: int


OWNER_SPECS = (
    OwnerSpec(0, "kUnary", "UNARY", "UNARY", 91, "compute", 96, 6),
    OwnerSpec(1, "kRmsNorm", "RMS_NORM", "RMS_NORM", 25, "compute", 79, 5),
    OwnerSpec(2, "kL2Norm", "L2_NORM", "L2_NORM", 28, "compute", 36, 2),
    OwnerSpec(3, "kSumRows", "SUM_ROWS", "SUM_ROWS", 15, "compute", 36, 1),
    OwnerSpec(4, "kGlu", "GLU", "GLU", 100, "compute", 24, 1),
    OwnerSpec(5, "kSsmConv", "SSM_CONV", "SSM_CONV", 76, "compute", 18, 1),
    OwnerSpec(6, "kCpy", "CPY", "CPY", 34, "mover", 72, 4),
    OwnerSpec(7, "kCont", "CONT", "CONT", 35, "mover", 12, 2),
    OwnerSpec(8, "kConcat", "CONCAT", "CONCAT", 22, "mover", 18, 1),
    OwnerSpec(9, "kSetRows", "SET_ROWS", "SET_ROWS", 42, "compute", 12, 2),
    OwnerSpec(
        10,
        "kF16AttentionMulMat",
        "F16_MUL_MAT",
        "MUL_MAT",
        29,
        "compute",
        12,
        2,
    ),
    OwnerSpec(11, "kRope", "ROPE", "ROPE", 48, "compute", 12, 2),
    OwnerSpec(12, "kSoftMax", "SOFT_MAX", "SOFT_MAX", 46, "compute", 6, 1),
)

OWNER_BY_ID = {owner.owner_id: owner for owner in OWNER_SPECS}
OWNER_BY_OP = {
    owner.op_name: owner
    for owner in OWNER_SPECS
    if owner.label != "F16_MUL_MAT"
}
EXPECTED_OWNER_COUNTS = {owner.label: owner.node_count for owner in OWNER_SPECS}
EXPECTED_OWNER_PROFILE_COUNTS = {
    owner.label: owner.profile_count for owner in OWNER_SPECS
}


def _fail(message: str) -> None:
    raise qwen_f32_alu_profiles.ProfileError(message)


def _compact(value: Any) -> str:
    return json.dumps(
        value, ensure_ascii=False, sort_keys=True, separators=(",", ":")
    )


def _sha256(value: Any) -> str:
    return hashlib.sha256(_compact(value).encode("utf-8")).hexdigest()


def _require_int(value: Any, description: str, minimum: int = 0) -> int:
    if type(value) is not int or value < minimum:
        _fail(f"{description} is not an integer >= {minimum}: {value!r}")
    return value


def _require_hex(value: Any, octets: int, description: str) -> str:
    if not isinstance(value, str) or re.fullmatch(
        rf"[0-9a-f]{{{octets * 2}}}", value
    ) is None:
        _fail(f"{description} is not canonical lowercase {octets}-byte hex")
    return value


def _tensor_spec(descriptor: Mapping[str, Any], description: str) -> dict[str, Any]:
    type_name = descriptor.get("type_name")
    op_name = descriptor.get("op_name")
    if not isinstance(type_name, str) or not type_name:
        _fail(f"{description} type_name is empty or malformed")
    if not isinstance(op_name, str) or not op_name:
        _fail(f"{description} op_name is empty or malformed")
    ne = descriptor.get("ne")
    nb = descriptor.get("nb")
    if (
        not isinstance(ne, list)
        or len(ne) != 4
        or any(type(value) is not int or value < 0 for value in ne)
    ):
        _fail(f"{description} ne is not four non-negative integers")
    if (
        not isinstance(nb, list)
        or len(nb) != 4
        or any(type(value) is not int or value < 0 for value in nb)
    ):
        _fail(f"{description} nb is not four non-negative integers")
    view_offs = _require_int(
        descriptor.get("view_offs"), f"{description} view_offs"
    )
    return {
        "type_id": _require_int(
            descriptor.get("type_id"), f"{description} type_id"
        ),
        "type_name": type_name,
        "op_id": _require_int(descriptor.get("op_id"), f"{description} op_id"),
        "op_name": op_name,
        "flags": _require_int(descriptor.get("flags"), f"{description} flags"),
        "view_present": descriptor.get("view_src") is not None,
        "view_offs": view_offs,
        "ne": list(ne),
        "nb": list(nb),
        "op_params_hex": _require_hex(
            descriptor.get("op_params_hex"), 64, f"{description} op_params"
        ),
    }


def _is_f16_attention_mul_mat(node: Mapping[str, Any]) -> bool:
    descriptor = node.get("descriptor")
    sources = node.get("sources")
    return (
        node.get("record_kind") == "node"
        and node.get("classification") == "compute"
        and isinstance(descriptor, Mapping)
        and descriptor.get("op_name") == "MUL_MAT"
        and descriptor.get("op_id") == 29
        and descriptor.get("type_name") == "f32"
        and isinstance(sources, list)
        and len(sources) == 2
        and sources[0].get("slot") == 0
        and sources[0].get("descriptor", {}).get("type_name") == "f16"
        and sources[1].get("slot") == 1
        and sources[1].get("descriptor", {}).get("type_name") == "f32"
    )


def _owner_for_node(node: Mapping[str, Any]) -> OwnerSpec | None:
    if node.get("record_kind") != "node":
        return None
    descriptor = node.get("descriptor")
    if not isinstance(descriptor, Mapping):
        return None
    if _is_f16_attention_mul_mat(node):
        return OWNER_BY_ID[10]
    owner = OWNER_BY_OP.get(descriptor.get("op_name"))
    if owner is None or node.get("classification") != owner.classification:
        return None
    return owner


def _source_ref(source: Mapping[str, Any], node_index: int, slot: int) -> dict[str, Any]:
    ref = source.get("ref")
    if not isinstance(ref, Mapping):
        _fail(f"node {node_index} source {slot} reference is missing")
    kind = ref.get("kind")
    index = ref.get("index")
    if kind not in ("node", "external"):
        _fail(f"node {node_index} source {slot} reference kind changed: {kind!r}")
    _require_int(index, f"node {node_index} source {slot} reference index")
    if kind == "node" and index >= node_index:
        _fail(f"node {node_index} source {slot} is not topologically earlier")
    return {"kind": kind, "index": index}


def _audit_node(node: Mapping[str, Any], owner: OwnerSpec) -> dict[str, Any]:
    index = _require_int(node.get("index"), "remaining graph index")
    if index >= GRAPH_NODE_COUNT:
        _fail(f"remaining graph index is out of frozen range: {index}")
    if node.get("classification") != owner.classification:
        _fail(f"node {index} classification changed")
    descriptor = node.get("descriptor")
    sources = node.get("sources")
    if not isinstance(descriptor, Mapping) or not isinstance(sources, list):
        _fail(f"node {index} descriptor/source list is malformed")
    if descriptor.get("op_name") != owner.op_name or descriptor.get("op_id") != owner.op_id:
        _fail(f"node {index} owner operation identity changed")
    if owner.label == "F16_MUL_MAT" and not _is_f16_attention_mul_mat(node):
        _fail(f"node {index} is no longer the F16/F32 attention MUL_MAT family")
    if not 1 <= len(sources) <= MAX_SOURCES:
        _fail(f"node {index} source arity changed: {len(sources)}")
    ordered = sorted(sources, key=lambda item: item.get("slot", -1))
    if [source.get("slot") for source in ordered] != list(range(len(sources))):
        _fail(f"node {index} source slots are not exact and contiguous")

    dst_name = descriptor.get("name")
    if not isinstance(dst_name, str) or not dst_name:
        _fail(f"node {index} destination name is empty")
    dst = _tensor_spec(descriptor, f"node {index} destination")
    source_specs: list[dict[str, Any]] = []
    names = [dst_name]
    refs: list[dict[str, Any]] = []
    for slot, source in enumerate(ordered):
        if not isinstance(source, Mapping):
            _fail(f"node {index} source {slot} is malformed")
        source_descriptor = source.get("descriptor")
        if not isinstance(source_descriptor, Mapping):
            _fail(f"node {index} source {slot} descriptor is missing")
        source_name = source_descriptor.get("name")
        if not isinstance(source_name, str) or not source_name:
            _fail(f"node {index} source {slot} name is empty")
        names.append(source_name)
        source_specs.append(
            _tensor_spec(source_descriptor, f"node {index} source {slot}")
        )
        refs.append(_source_ref(source, index, slot))

    canonical_id = _require_hex(node.get("canonical_id"), 32, f"node {index} canonical_id")
    if canonical_id != qwen_f32_alu_profiles.canonical_sha256(
        node.get("semantic_key")
    ):
        _fail(f"node {index} canonical_id recompute mismatch")
    descriptor_sha256 = _require_hex(
        node.get("descriptor_sha256"), 32, f"node {index} descriptor_sha256"
    )
    recomputed_descriptor_sha256 = qwen_f32_alu_profiles.canonical_sha256(
        {"descriptor": descriptor, "sources": sources}
    )
    if descriptor_sha256 != recomputed_descriptor_sha256:
        _fail(f"node {index} descriptor/source SHA256 recompute mismatch")

    return {
        "index": index,
        "owner": owner.owner_id,
        "canonical_id": canonical_id,
        "descriptor_sha256": descriptor_sha256,
        "names": names,
        "refs": refs,
        "dst": dst,
        "srcs": source_specs,
        "raw_node": node,
    }


def _local_route(owner: OwnerSpec, exact: Mapping[str, Any]) -> dict[str, int]:
    dst = exact["dst"]
    srcs = exact["srcs"]
    kernel = ROUTE_SENTINEL
    operation = ROUTE_SENTINEL
    profile = ROUTE_SENTINEL

    if owner.label == "UNARY":
        kernel = 0x514E0005
        operation = int(dst["op_params_hex"][:2], 16)
        unary_profiles = {
            (7, (1, 16, 1, 1)): 0,
            (7, (2048, 1, 1, 1)): 1,
            (15, (16, 1, 1, 1)): 2,
            (10, (128, 16, 1, 1)): 3,
            (10, (6144, 1, 1, 1)): 4,
            (13, (1, 1, 16, 1)): 5,
        }
        profile = unary_profiles.get((operation, tuple(dst["ne"])), ROUTE_SENTINEL)
    elif owner.label == "GLU":
        kernel, operation, profile = 0x514E0006, 2, 6
    elif owner.label in ("RMS_NORM", "L2_NORM"):
        kernel = 0x514E0011
        operation = 4 if owner.label == "RMS_NORM" else 5
        shape_profiles = {
            (1024, 1, 1, 1): 0,
            (128, 16, 1, 1): 1 if owner.label == "RMS_NORM" else 4,
            (256, 2, 1, 1): 2,
            (256, 8, 1, 1): 3,
        }
        profile = shape_profiles.get(tuple(dst["ne"]), ROUTE_SENTINEL)
    elif owner.label == "SUM_ROWS":
        kernel, operation, profile = 0x514E0011, 1, 0
    elif owner.label == "SOFT_MAX":
        kernel, operation, profile = 0x514E0011, 6, 0
    elif owner.label == "SSM_CONV":
        kernel, profile = 0x514E0022, 0
    elif owner.label in ("CPY", "CONT", "CONCAT"):
        kernel = 0x514E0007
        operation = {"CPY": 0, "CONT": 1, "CONCAT": 2}[owner.label]
    elif owner.label == "SET_ROWS":
        kernel = 0x514E0008
        if dst["ne"] == [512, 256, 1, 1] and srcs[0]["ne"] == [512, 1, 1, 1]:
            operation, profile = 3, 0
        elif dst["ne"] == [1, 131072, 1, 1] and srcs[0]["ne"] == [1, 512, 1, 1]:
            operation, profile = 4, 1
    elif owner.label == "F16_MUL_MAT":
        kernel = 0x514E0009
        if srcs[0]["nb"][1] == 1024 and dst["op_params_hex"].startswith("0a000000"):
            profile = 0
        elif srcs[0]["nb"][1] == 512 and dst["op_params_hex"] == ZERO_OP_PARAMS:
            profile = 1
    elif owner.label == "ROPE":
        kernel = 0x514E000A
        if dst["ne"] == [256, 8, 1, 1]:
            profile = 0
        elif dst["ne"] == [256, 2, 1, 1]:
            profile = 1
    return {
        "kernel_id": kernel,
        "local_operation": operation,
        "local_profile": profile,
    }


def _audit_catalog(
    envelope: Mapping[str, Any], *, enforce_frozen_digests: bool = True
) -> dict[str, Any]:
    manifest = envelope.get("manifest")
    if not isinstance(manifest, Mapping):
        _fail("manifest payload missing from remaining-profile audit")
    raw_nodes = manifest.get("nodes")
    if not isinstance(raw_nodes, list):
        _fail("manifest node list missing from remaining-profile audit")

    selected: list[dict[str, Any]] = []
    for raw_node in raw_nodes:
        if not isinstance(raw_node, Mapping):
            _fail("manifest contains a non-object node")
        owner = _owner_for_node(raw_node)
        if owner is not None:
            selected.append(_audit_node(raw_node, owner))
    selected.sort(key=lambda node: node["index"])

    owner_counts = Counter(OWNER_BY_ID[node["owner"]].label for node in selected)
    if dict(owner_counts) != EXPECTED_OWNER_COUNTS:
        _fail(f"remaining owner census changed: {dict(owner_counts)}")
    if len(selected) != NODE_COUNT:
        _fail(f"remaining node census changed: {len(selected)}")
    graph_indices = [node["index"] for node in selected]
    canonical_ids = [node["canonical_id"] for node in selected]
    name_tuples = [tuple(node["names"]) for node in selected]
    if len(set(graph_indices)) != NODE_COUNT:
        _fail("remaining graph index collision")
    if len(set(canonical_ids)) != NODE_COUNT:
        _fail("remaining canonical identity collision")
    if len(set(name_tuples)) != NODE_COUNT:
        _fail("remaining destination/source name tuple collision")

    grouped: dict[str, list[dict[str, Any]]] = {}
    for node in selected:
        exact = {"owner": node["owner"], "dst": node["dst"], "srcs": node["srcs"]}
        grouped.setdefault(_compact(exact), []).append(node)
    ordered_groups = sorted(
        grouped.items(),
        key=lambda item: (
            json.loads(item[0])["owner"],
            min(node["index"] for node in item[1]),
            item[0],
        ),
    )
    profiles: list[dict[str, Any]] = []
    owner_profile_next = Counter()
    for profile_id, (key, members) in enumerate(ordered_groups):
        exact = json.loads(key)
        owner_id = exact["owner"]
        owner = OWNER_BY_ID[owner_id]
        owner_profile_id = owner_profile_next[owner_id]
        owner_profile_next[owner_id] += 1
        profiles.append(
            {
                "profile_id": profile_id,
                "owner_profile_id": owner_profile_id,
                "owner": owner_id,
                "count": len(members),
                "first_graph_index": min(node["index"] for node in members),
                "exact": exact,
                "route": _local_route(owner, exact),
                "members": members,
            }
        )
    if len(profiles) != PROFILE_COUNT:
        _fail(f"remaining exact profile census changed: {len(profiles)}")
    owner_profile_counts = Counter(
        OWNER_BY_ID[profile["owner"]].label for profile in profiles
    )
    if dict(owner_profile_counts) != EXPECTED_OWNER_PROFILE_COUNTS:
        _fail(f"remaining owner profile census changed: {dict(owner_profile_counts)}")

    profile_for_index = {
        node["index"]: profile["profile_id"]
        for profile in profiles
        for node in profile["members"]
    }
    if len(profile_for_index) != NODE_COUNT:
        _fail("remaining node-to-profile assignment is not one-to-one")
    for node in selected:
        node["profile_id"] = profile_for_index[node["index"]]

    profile_digest_rows = [
        {
            "profile_id": profile["profile_id"],
            "owner_profile_id": profile["owner_profile_id"],
            "owner": profile["owner"],
            "count": profile["count"],
            "first_graph_index": profile["first_graph_index"],
            "exact": profile["exact"],
        }
        for profile in profiles
    ]
    canonical_digest_rows = [
        {
            "index": node["index"],
            "profile_id": node["profile_id"],
            "owner": node["owner"],
            "canonical_id": node["canonical_id"],
            "descriptor_sha256": node["descriptor_sha256"],
            "names": node["names"],
            "refs": node["refs"],
        }
        for node in selected
    ]
    profile_set_sha256 = _sha256(profile_digest_rows)
    canonical_set_sha256 = _sha256(canonical_digest_rows)
    if enforce_frozen_digests:
        if profile_set_sha256 != PROFILE_SET_SHA256:
            _fail(f"remaining exact profile set changed: {profile_set_sha256}")
        if canonical_set_sha256 != CANONICAL_SET_SHA256:
            _fail(f"remaining canonical set changed: {canonical_set_sha256}")

    route_sentinel_fields = {
        profile["profile_id"]: [
            field
            for field, value in profile["route"].items()
            if value == ROUTE_SENTINEL
        ]
        for profile in profiles
        if ROUTE_SENTINEL in profile["route"].values()
    }
    return {
        "nodes": selected,
        "profiles": profiles,
        "owner_counts": dict(owner_counts),
        "owner_profile_counts": dict(owner_profile_counts),
        "canonical_set_sha256": canonical_set_sha256,
        "profile_set_sha256": profile_set_sha256,
        "route_sentinel_profile_ids": [
            profile_id for profile_id in route_sentinel_fields
        ],
        "route_sentinel_fields": route_sentinel_fields,
    }


def _existing_coverage(
    envelope: Mapping[str, Any], base_audit: Mapping[str, Any]
) -> dict[str, Any]:
    alu_indices = {
        node["index"]
        for profile in base_audit["profiles"]
        for node in profile["canonical_nodes"]
    }
    q8_nodes, _ = qwen_q8_gemv_profiles.audit_q8_gemv_manifest(dict(envelope))
    mover_nodes, _ = qwen_f32_gather_repeat_profiles.audit_manifest(dict(envelope))
    q8_indices = {node["index"] for node in q8_nodes}
    mover_indices = {node["index"] for node in mover_nodes}
    q8_get_rows_nodes = [
        node
        for node in envelope["manifest"]["nodes"]
        if node.get("record_kind") == "node"
        and node.get("classification") == "compute"
        and node.get("descriptor", {}).get("op_name") == "GET_ROWS"
        and node.get("descriptor", {}).get("type_name") == "f32"
        and len(node.get("sources", [])) == 2
        and node["sources"][0].get("slot") == 0
        and node["sources"][0].get("descriptor", {}).get("type_name") == "q8_0"
        and node["sources"][1].get("slot") == 1
        and node["sources"][1].get("descriptor", {}).get("type_name") == "i32"
    ]
    if len(q8_get_rows_nodes) != 1:
        _fail(f"existing Q8 GET_ROWS owner census changed: {len(q8_get_rows_nodes)}")
    q8_get_rows = q8_get_rows_nodes[0]
    q8_get_rows_index = _require_int(
        q8_get_rows.get("index"), "existing Q8 GET_ROWS graph index"
    )
    if q8_get_rows.get("descriptor", {}).get("op_id") != 40:
        _fail("existing Q8 GET_ROWS operation id changed")
    if q8_get_rows.get("canonical_id") != qwen_f32_alu_profiles.canonical_sha256(
        q8_get_rows.get("semantic_key")
    ):
        _fail("existing Q8 GET_ROWS canonical identity changed")
    if q8_get_rows.get("descriptor_sha256") != qwen_f32_alu_profiles.canonical_sha256(
        {
            "descriptor": q8_get_rows.get("descriptor"),
            "sources": q8_get_rows.get("sources"),
        }
    ):
        _fail("existing Q8 GET_ROWS descriptor identity changed")
    q8_get_rows_indices = {q8_get_rows_index}
    if len(alu_indices) != 367 or len(q8_indices) != 187 or len(mover_indices) != 91:
        _fail("existing owner component census changed")
    components = (alu_indices, q8_indices, mover_indices, q8_get_rows_indices)
    if any(
        components[left] & components[right]
        for left in range(len(components))
        for right in range(left + 1, len(components))
    ):
        _fail("existing 646-owner sets overlap")
    covered = alu_indices | q8_indices | mover_indices | q8_get_rows_indices
    if len(covered) != EXISTING_OWNER_NODE_COUNT:
        _fail(f"existing owner union changed: {len(covered)}")
    return {
        "alu": alu_indices,
        "q8_gemv": q8_indices,
        "gather_repeat": mover_indices,
        "q8_get_rows": q8_get_rows_indices,
        "all": covered,
    }


def _sampler_argmax_coverage(envelope: Mapping[str, Any]) -> set[int]:
    """Bind the one terminal sampler owner without classifying it as remaining."""

    candidates = [
        node
        for node in envelope["manifest"]["nodes"]
        if node.get("record_kind") == "node"
        and node.get("classification") == "compute"
        and node.get("descriptor", {}).get("op_name") == "ARGMAX"
    ]
    if len(candidates) != SAMPLER_ARGMAX_NODE_COUNT:
        _fail(f"sampler ARGMAX owner census changed: {len(candidates)}")
    node = candidates[0]
    index = _require_int(node.get("index"), "sampler ARGMAX graph index")
    descriptor = node.get("descriptor")
    sources = node.get("sources")
    if index != SAMPLER_ARGMAX_INDEX or not isinstance(descriptor, Mapping):
        _fail("sampler ARGMAX graph index/descriptor changed")
    if (
        node.get("canonical_id") != SAMPLER_ARGMAX_CANONICAL_ID
        or descriptor.get("op_id") != 18
        or descriptor.get("name") != "greedy_argmax"
        or descriptor.get("type_id") != 26
        or descriptor.get("type_name") != "i32"
        or descriptor.get("ne") != [1, 1, 1, 1]
        or descriptor.get("nb") != [4, 4, 4, 4]
        or descriptor.get("op_params_hex") != ZERO_OP_PARAMS
        or not isinstance(sources, list)
        or len(sources) != 1
    ):
        _fail("sampler ARGMAX destination identity changed")
    source = sources[0]
    source_descriptor = source.get("descriptor")
    if (
        source.get("slot") != 0
        or source.get("ref") != {"kind": "node", "index": 1712}
        or not isinstance(source_descriptor, Mapping)
        or source_descriptor.get("name") != "logits_seq_0_0 (reshaped)"
        or source_descriptor.get("type_id") != 0
        or source_descriptor.get("type_name") != "f32"
        or source_descriptor.get("ne") != [248320, 1, 1, 1]
        or source_descriptor.get("nb") != [4, 993280, 993280, 993280]
    ):
        _fail("sampler ARGMAX source identity changed")
    if node.get("canonical_id") != qwen_f32_alu_profiles.canonical_sha256(
        node.get("semantic_key")
    ):
        _fail("sampler ARGMAX canonical identity recompute mismatch")
    if node.get("descriptor_sha256") != qwen_f32_alu_profiles.canonical_sha256(
        {"descriptor": descriptor, "sources": sources}
    ):
        _fail("sampler ARGMAX descriptor identity recompute mismatch")
    return {index}


def audit_manifest_object(envelope: Mapping[str, Any]) -> dict[str, Any]:
    # Mandatory first gate: the shared oracle verifies the frozen envelope,
    # payload hash, raw graph identity, global census, and all 367 ALU owners.
    base_audit = qwen_f32_alu_profiles.audit_manifest_object(envelope)
    catalog = _audit_catalog(envelope)
    existing = _existing_coverage(envelope, base_audit)
    sampler_argmax = _sampler_argmax_coverage(envelope)
    manifest = envelope["manifest"]
    required_indices = {
        node["index"]
        for node in manifest["nodes"]
        if node.get("record_kind") == "node"
        and node.get("classification") in ("compute", "mover")
    }
    remaining_indices = {node["index"] for node in catalog["nodes"]}
    if len(required_indices) != REQUIRED_NONMETADATA_COUNT:
        _fail(f"required compute/mover census changed: {len(required_indices)}")
    if remaining_indices & existing["all"]:
        _fail("remaining 433 nodes overlap an existing owner")
    if sampler_argmax & (remaining_indices | existing["all"]):
        _fail("sampler ARGMAX overlaps a model owner")
    partition = remaining_indices | existing["all"] | sampler_argmax
    if partition != required_indices:
        missing = sorted(required_indices - partition)
        extra = sorted(partition - required_indices)
        _fail(f"646+433+1 partition changed: missing={missing} extra={extra}")

    return {
        "marker": MARKER,
        "manifest_sha256": base_audit["manifest_sha256"],
        "raw_sha256": base_audit["raw_sha256"],
        "existing_owner_node_count": len(existing["all"]),
        "sampler_argmax_node_count": len(sampler_argmax),
        "required_nonmetadata_count": len(required_indices),
        "node_count": len(catalog["nodes"]),
        "profile_count": len(catalog["profiles"]),
        "owner_counts": catalog["owner_counts"],
        "owner_profile_counts": catalog["owner_profile_counts"],
        "canonical_set_sha256": catalog["canonical_set_sha256"],
        "profile_set_sha256": catalog["profile_set_sha256"],
        "route_sentinel_profile_ids": catalog["route_sentinel_profile_ids"],
        "route_sentinel_fields": catalog["route_sentinel_fields"],
        "nodes": catalog["nodes"],
        "profiles": catalog["profiles"],
    }


def load_audited(path: pathlib.Path) -> tuple[dict[str, Any], dict[str, Any]]:
    envelope = qwen_f32_alu_profiles.load_manifest(path)
    return envelope, audit_manifest_object(envelope)


def _cpp_string(value: str) -> str:
    return json.dumps(value, ensure_ascii=True)


def _cpp_u8_array(value: str) -> str:
    return "{{" + ", ".join(
        f"0x{value[index:index + 2]}U" for index in range(0, len(value), 2)
    ) + "}}"


def _cpp_i64_array(values: Sequence[int]) -> str:
    return "{{" + ", ".join(f"{value}LL" for value in values) + "}}"


def _cpp_u64_array(values: Sequence[int]) -> str:
    return "{{" + ", ".join(f"{value}ULL" for value in values) + "}}"


def _cpp_tensor(spec: Mapping[str, Any]) -> str:
    return (
        "{"
        f"{spec['type_id']}U, {_cpp_string(spec['type_name'])}, "
        f"{spec['op_id']}U, {_cpp_string(spec['op_name'])}, "
        f"{spec['flags']}U, {str(spec['view_present']).lower()}, "
        f"{spec['view_offs']}ULL, {_cpp_i64_array(spec['ne'])}, "
        f"{_cpp_u64_array(spec['nb'])}, {_cpp_u8_array(spec['op_params_hex'])}"
        "}"
    )


EMPTY_TENSOR = {
    "type_id": 0,
    "type_name": "",
    "op_id": 0,
    "op_name": "",
    "flags": 0,
    "view_present": False,
    "view_offs": 0,
    "ne": [0, 0, 0, 0],
    "nb": [0, 0, 0, 0],
    "op_params_hex": ZERO_OP_PARAMS,
}


def _cpp_source_specs(specs: Sequence[Mapping[str, Any]]) -> str:
    padded = list(specs) + [EMPTY_TENSOR] * (MAX_SOURCES - len(specs))
    return "{{" + ", ".join(_cpp_tensor(spec) for spec in padded) + "}}"


def _cpp_source_names(names: Sequence[str]) -> str:
    padded = list(names) + [""] * (MAX_SOURCES - len(names))
    return "{{" + ", ".join(_cpp_string(name) for name in padded) + "}}"


def _cpp_refs(refs: Sequence[Mapping[str, Any]]) -> str:
    values = [
        "{ref_kind::kNode, " + f"{ref['index']}U" + "}"
        if ref["kind"] == "node"
        else "{ref_kind::kExternal, " + f"{ref['index']}U" + "}"
        for ref in refs
    ]
    values.extend(
        ["{ref_kind::kNone, 0U}"] * (MAX_SOURCES - len(values))
    )
    return "{{" + ", ".join(values) + "}}"


def render_header(audit: Mapping[str, Any]) -> str:
    nodes = audit["nodes"]
    profiles = audit["profiles"]
    lines = [
        "// Generated from audited canonical-v5 dispatch.manifest.json.",
        "// Metadata only; no tensor payloads or host numerical oracle.",
        "// Do not edit: scripts/qwen_remaining_profiles.py owns this file.",
        "#ifndef QWEN_REMAINING_MANIFEST_GENERATED_H",
        "#define QWEN_REMAINING_MANIFEST_GENERATED_H",
        "",
        "#include <array>",
        "#include <cstddef>",
        "#include <cstdint>",
        "",
        "namespace qwen_remaining_manifest {",
        "",
        "enum class owner : std::uint32_t {",
    ]
    for owner in OWNER_SPECS:
        lines.append(f"    {owner.enum_name} = {owner.owner_id}U,")
    lines.extend(
        [
            "};",
            "",
            "enum class ref_kind : std::uint32_t {",
            "    kExternal = 0U,",
            "    kNode = 1U,",
            "    kNone = 2U,",
            "};",
            "",
            f"inline constexpr std::uint32_t kRouteSentinel = 0x{ROUTE_SENTINEL:08x}U;",
            "",
            "struct tensor_spec {",
            "    std::uint32_t type_id;",
            "    const char * type_name;",
            "    std::uint32_t op_id;",
            "    const char * op_name;",
            "    std::uint32_t flags;",
            "    bool view_present;",
            "    std::uint64_t view_offs;",
            "    std::array<std::int64_t, 4> ne;",
            "    std::array<std::uint64_t, 4> nb;",
            "    std::array<std::uint8_t, 64> op_params;",
            "};",
            "",
            "struct source_ref {",
            "    ref_kind kind;",
            "    std::uint32_t index;",
            "};",
            "",
            "struct owner_spec {",
            "    owner owner_id;",
            "    const char * operation_name;",
            "    std::uint32_t operation_id;",
            "    std::uint32_t node_count;",
            "    std::uint32_t profile_count;",
            "};",
            "",
            "struct profile {",
            "    std::uint32_t profile_id;",
            "    std::uint32_t owner_profile_id;",
            "    owner owner_id;",
            "    std::uint32_t node_count;",
            "    std::uint32_t first_graph_index;",
            "    std::uint32_t public_kernel_id;",
            "    std::uint32_t local_operation;",
            "    std::uint32_t local_profile;",
            "    tensor_spec dst;",
            "    std::uint32_t source_count;",
            f"    std::array<tensor_spec, {MAX_SOURCES}> sources;",
            "};",
            "",
            "struct canonical_node {",
            "    std::uint32_t graph_node_index;",
            "    std::uint32_t profile_id;",
            "    owner owner_id;",
            "    std::array<std::uint8_t, 32> canonical_id;",
            "    std::array<std::uint8_t, 32> descriptor_sha256;",
            "    const char * dst_name;",
            f"    std::array<const char *, {MAX_SOURCES}> source_names;",
            "    std::uint32_t source_count;",
            f"    std::array<source_ref, {MAX_SOURCES}> source_refs;",
            "};",
            "",
            f"inline constexpr char kMarker[] = \"{MARKER}\";",
            f"inline constexpr std::size_t kOwnerCount = {len(OWNER_SPECS)}ULL;",
            f"inline constexpr std::size_t kProfileCount = {PROFILE_COUNT}ULL;",
            f"inline constexpr std::size_t kCanonicalNodeCount = {NODE_COUNT}ULL;",
            f"inline constexpr std::size_t kExistingOwnerNodeCount = {EXISTING_OWNER_NODE_COUNT}ULL;",
            f"inline constexpr std::size_t kSamplerArgmaxNodeCount = {SAMPLER_ARGMAX_NODE_COUNT}ULL;",
            f"inline constexpr std::size_t kRequiredNonmetadataCount = {REQUIRED_NONMETADATA_COUNT}ULL;",
            f"inline constexpr char kManifestSha256[] = \"{audit['manifest_sha256']}\";",
            f"inline constexpr char kCanonicalSetSha256[] = \"{audit['canonical_set_sha256']}\";",
            f"inline constexpr char kProfileSetSha256[] = \"{audit['profile_set_sha256']}\";",
            "",
            f"inline constexpr std::array<owner_spec, {len(OWNER_SPECS)}> kOwners = {{{{",
        ]
    )
    for owner in OWNER_SPECS:
        lines.append(
            "    {"
            f"owner::{owner.enum_name}, {_cpp_string(owner.op_name)}, "
            f"{owner.op_id}U, {owner.node_count}U, {owner.profile_count}U"
            "},"
        )
    lines.extend(
        [
            "}};",
            "",
            f"inline constexpr std::array<profile, {PROFILE_COUNT}> kProfiles = {{{{",
        ]
    )
    for profile in profiles:
        owner = OWNER_BY_ID[profile["owner"]]
        exact = profile["exact"]
        route = profile["route"]
        lines.append(
            "    {"
            f"{profile['profile_id']}U, {profile['owner_profile_id']}U, "
            f"owner::{owner.enum_name}, {profile['count']}U, "
            f"{profile['first_graph_index']}U, 0x{route['kernel_id']:08x}U, "
            f"0x{route['local_operation']:08x}U, "
            f"0x{route['local_profile']:08x}U, {_cpp_tensor(exact['dst'])}, "
            f"{len(exact['srcs'])}U, {_cpp_source_specs(exact['srcs'])}"
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
        owner = OWNER_BY_ID[node["owner"]]
        lines.append(
            "    {"
            f"{node['index']}U, {node['profile_id']}U, owner::{owner.enum_name}, "
            f"{_cpp_u8_array(node['canonical_id'])}, "
            f"{_cpp_u8_array(node['descriptor_sha256'])}, "
            f"{_cpp_string(node['names'][0])}, "
            f"{_cpp_source_names(node['names'][1:])}, "
            f"{len(node['refs'])}U, {_cpp_refs(node['refs'])}"
            "},"
        )
    lines.extend(
        [
            "}};",
            "",
            "} // namespace qwen_remaining_manifest",
            "",
            "#endif",
            "",
        ]
    )
    return "\n".join(lines)


def write_header(path: pathlib.Path, audit: Mapping[str, Any]) -> None:
    output = path.resolve()
    output.parent.mkdir(parents=True, exist_ok=True)
    temporary = output.with_name(output.name + ".tmp")
    temporary.write_text(render_header(audit), encoding="utf-8")
    temporary.replace(output)


def _owner_census_text(audit: Mapping[str, Any]) -> str:
    return ",".join(
        f"{owner.label}:{audit['owner_counts'][owner.label]}"
        for owner in OWNER_SPECS
    )


def _owner_profile_census_text(audit: Mapping[str, Any]) -> str:
    return ",".join(
        f"{owner.label}:{audit['owner_profile_counts'][owner.label]}"
        for owner in OWNER_SPECS
    )


def command_audit(arguments: argparse.Namespace) -> int:
    _, audit = load_audited(arguments.manifest)
    sentinel_fields = ";".join(
        f"{profile_id}:" + "+".join(fields)
        for profile_id, fields in audit["route_sentinel_fields"].items()
    )
    print(
        "[NPU-QWEN-REMAINING-PROFILES][PASS] "
        f"marker={MARKER} nodes={audit['node_count']} profiles={audit['profile_count']} "
        f"existing={audit['existing_owner_node_count']} "
        f"sampler_argmax={audit['sampler_argmax_node_count']} "
        f"required={audit['required_nonmetadata_count']} "
        f"owners={_owner_census_text(audit)} "
        f"owner_profiles={_owner_profile_census_text(audit)} "
        f"route_sentinels={sentinel_fields or 'none'} "
        f"canonical_set_sha256={audit['canonical_set_sha256']} "
        f"profile_set_sha256={audit['profile_set_sha256']}"
    )
    return 0


def command_emit_header(arguments: argparse.Namespace) -> int:
    _, audit = load_audited(arguments.manifest)
    write_header(arguments.output, audit)
    header_sha256 = hashlib.sha256(
        arguments.output.resolve().read_bytes()
    ).hexdigest()
    print(
        "[NPU-QWEN-REMAINING-PROFILES][EMIT] "
        f"marker={MARKER} nodes={audit['node_count']} profiles={audit['profile_count']} "
        f"header_sha256={header_sha256} output={arguments.output.resolve()}"
    )
    return 0


def command_test_id(arguments: argparse.Namespace) -> int:
    _, audit = load_audited(arguments.manifest)
    matches = [
        node for node in audit["nodes"] if node["index"] == arguments.graph_index
    ]
    if len(matches) != 1:
        _fail(
            f"graph index {arguments.graph_index} is not a unique remaining owner node"
        )
    print(matches[0]["canonical_id"])
    return 0


def _integer_argument(value: str) -> int:
    try:
        result = int(value, 0)
    except ValueError as error:
        raise argparse.ArgumentTypeError(str(error)) from error
    if result < 0:
        raise argparse.ArgumentTypeError("graph index must be non-negative")
    return result


def parser() -> argparse.ArgumentParser:
    result = argparse.ArgumentParser()
    subparsers = result.add_subparsers(dest="command", required=True)
    audit_parser = subparsers.add_parser("audit")
    audit_parser.add_argument("--manifest", required=True, type=pathlib.Path)
    audit_parser.set_defaults(function=command_audit)
    header_parser = subparsers.add_parser("emit-header")
    header_parser.add_argument("--manifest", required=True, type=pathlib.Path)
    header_parser.add_argument("--output", required=True, type=pathlib.Path)
    header_parser.set_defaults(function=command_emit_header)
    for command in ("test-id", "emit-test-id"):
        test_id_parser = subparsers.add_parser(command)
        test_id_parser.add_argument("--manifest", required=True, type=pathlib.Path)
        test_id_parser.add_argument(
            "--graph-index", required=True, type=_integer_argument
        )
        test_id_parser.set_defaults(function=command_test_id)
    return result


def main(argv: Sequence[str] | None = None) -> int:
    arguments = parser().parse_args(sys.argv[1:] if argv is None else argv)
    try:
        return arguments.function(arguments)
    except qwen_f32_alu_profiles.ProfileError as error:
        print(f"[NPU-QWEN-REMAINING-PROFILES][FAIL] {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
