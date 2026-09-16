#!/usr/bin/env python3
"""Import a canonical Qwen GGML manifest into address-free NPU GraphIR.

This module deliberately stops before command generation.  It validates the
captured GGML graph, preserves one GraphIR node per required compute/mover
node, and binds every node to an already-audited lowering-owner family.  IOVA
assignment, tiling, scheduling and 30-word command encoding remain later
compiler passes.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import pathlib
import re
import sys
from collections import Counter
from collections.abc import Mapping, Sequence
from typing import Any


PROJECT_ROOT = pathlib.Path(__file__).resolve().parents[1]
SCRIPTS_DIR = PROJECT_ROOT / "scripts"
if str(SCRIPTS_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPTS_DIR))

# These modules are the existing canonical owner oracles.  Do not duplicate
# their frozen profile tables here: this file is only an adapter over their
# public audit/matching functions.
import qwen_f32_alu_profiles  # noqa: E402
import qwen_f32_gather_repeat_profiles  # noqa: E402
import qwen_graph_manifest  # noqa: E402
import qwen_q8_gemv_profiles  # noqa: E402
import qwen_remaining_profiles  # noqa: E402
import qwen_sampler_argmax_profile  # noqa: E402

try:
    from . import npu_ids
except ImportError:  # Direct ``python compiler/qwen_graph_ir.py`` execution.
    import npu_ids  # type: ignore[no-redef]


GRAPH_IR_SCHEMA = "qwen-npu-graph-ir-v1"
GRAPH_IR_ENVELOPE_SCHEMA = "qwen-npu-graph-ir-envelope-v1"
OWNER_MODE_EXACT = "qwen35-v5-exact"
OWNER_MODE_FIXTURE = "structural-fixture"
LOWERING_FAMILY_ORDER = (
    "f32_alu",
    "q8_get_rows",
    "q8_gemv",
    "f32_gather_repeat",
    "remaining",
    "sampler_argmax",
)
EXPECTED_QWEN35_V5_OWNER_COUNTS = {
    "f32_alu": 367,
    "q8_get_rows": 1,
    "q8_gemv": 187,
    "f32_gather_repeat": 91,
    "remaining": 433,
    "sampler_argmax": 1,
}

_HEX64 = re.compile(r"[0-9a-f]{64}\Z")
_HEX128 = re.compile(r"[0-9a-f]{128}\Z")
_DESCRIPTOR_KEYS = {
    "flags",
    "name",
    "nb",
    "ne",
    "op_desc",
    "op_id",
    "op_name",
    "op_params_hex",
    "type_id",
    "type_name",
    "view_offs",
    "view_src",
}
_NODE_KEYS = {
    "canonical_id",
    "classification",
    "descriptor",
    "descriptor_sha256",
    "index",
    "record_kind",
    "semantic_key",
    "sources",
}
_SEMANTIC_KEYS = {
    "graph_scope",
    "layer_index",
    "layer_kind",
    "occurrence",
    "op",
    "path",
    "profile",
    "role",
    "schema",
    "source_commit",
    "subtype",
}


class GraphIRError(ValueError):
    """Fail-closed manifest import diagnostic with a stable error code/path."""

    def __init__(self, code: str, path: str, detail: str):
        super().__init__(f"{code} at {path}: {detail}")
        self.code = code
        self.path = path
        self.detail = detail


def _fail(code: str, path: str, detail: str) -> None:
    raise GraphIRError(code, path, detail)


def canonical_bytes(value: Any) -> bytes:
    return json.dumps(
        value, ensure_ascii=False, sort_keys=True, separators=(",", ":")
    ).encode("utf-8")


def canonical_sha256(value: Any) -> str:
    return hashlib.sha256(canonical_bytes(value)).hexdigest()


def _mapping(value: Any, path: str) -> Mapping[str, Any]:
    if not isinstance(value, Mapping):
        _fail("SCHEMA_TYPE", path, "expected object")
    return value


def _exact_keys(value: Mapping[str, Any], keys: set[str], path: str) -> None:
    actual = set(value)
    if actual != keys:
        _fail(
            "SCHEMA_KEYS",
            path,
            f"missing={sorted(keys - actual)} extra={sorted(actual - keys)}",
        )


def _integer(value: Any, path: str, minimum: int = 0) -> int:
    if type(value) is not int or value < minimum:
        _fail("SCHEMA_INTEGER", path, f"expected integer >= {minimum}")
    return value


def _reference(
    value: Any,
    path: str,
    *,
    node_limit: int,
    external_count: int,
) -> tuple[str, int]:
    ref = _mapping(value, path)
    _exact_keys(ref, {"kind", "index"}, path)
    kind = ref.get("kind")
    index = _integer(ref.get("index"), path + ".index")
    if kind == "node":
        if index >= node_limit:
            _fail(
                "FORWARD_SOURCE_REF",
                path,
                f"node ref {index} is not before consumer {node_limit}",
            )
    elif kind == "external":
        if index >= external_count:
            _fail(
                "EXTERNAL_SOURCE_REF",
                path,
                f"external ref {index} >= count {external_count}",
            )
    else:
        _fail("SOURCE_REF_KIND", path + ".kind", f"unsupported ref kind {kind!r}")
    return kind, index


def _descriptor(
    value: Any,
    path: str,
    *,
    node_limit: int,
    external_count: int,
) -> Mapping[str, Any]:
    descriptor = _mapping(value, path)
    _exact_keys(descriptor, _DESCRIPTOR_KEYS, path)
    for field in ("flags", "op_id", "type_id", "view_offs"):
        _integer(descriptor.get(field), path + "." + field)
    for field in ("name", "op_desc", "op_name", "type_name"):
        if type(descriptor.get(field)) is not str:
            _fail("SCHEMA_STRING", path + "." + field, "expected string")
    params = descriptor.get("op_params_hex")
    if type(params) is not str or _HEX128.fullmatch(params) is None:
        _fail("OP_PARAMS", path + ".op_params_hex", "expected 64 lowercase-hex bytes")
    for field in ("ne", "nb"):
        values = descriptor.get(field)
        if type(values) is not list or len(values) != 4:
            _fail("TENSOR_RANK", path + "." + field, "expected four dimensions")
        for position, item in enumerate(values):
            _integer(item, f"{path}.{field}[{position}]")
    view_src = descriptor.get("view_src")
    if view_src is not None:
        _reference(
            view_src,
            path + ".view_src",
            node_limit=node_limit,
            external_count=external_count,
        )
    return descriptor


def _validate_manifest(envelope: Mapping[str, Any]) -> dict[str, Any]:
    """Validate generic canonical-manifest structure and all graph identities."""

    _exact_keys(envelope, {"manifest", "manifest_sha256", "schema"}, "$envelope")
    if envelope.get("schema") != qwen_graph_manifest.ENVELOPE_SCHEMA:
        _fail("ENVELOPE_SCHEMA", "$envelope.schema", "unsupported manifest envelope")
    claimed_hash = envelope.get("manifest_sha256")
    if type(claimed_hash) is not str or _HEX64.fullmatch(claimed_hash) is None:
        _fail("MANIFEST_HASH", "$envelope.manifest_sha256", "malformed SHA-256")

    manifest = _mapping(envelope.get("manifest"), "$manifest")
    _exact_keys(
        manifest,
        {
            "counts",
            "external_tensors",
            "header",
            "nodes",
            "raw_footer",
            "raw_schema",
            "raw_sha256",
            "schema",
        },
        "$manifest",
    )
    if manifest.get("schema") != qwen_graph_manifest.MANIFEST_SCHEMA:
        _fail("MANIFEST_SCHEMA", "$manifest.schema", "unsupported manifest schema")
    if manifest.get("raw_schema") != qwen_graph_manifest.RAW_SCHEMA:
        _fail("RAW_SCHEMA", "$manifest.raw_schema", "unsupported raw graph schema")
    raw_hash = manifest.get("raw_sha256")
    if type(raw_hash) is not str or _HEX64.fullmatch(raw_hash) is None:
        _fail("RAW_HASH", "$manifest.raw_sha256", "malformed SHA-256")
    recomputed_hash = canonical_sha256(manifest)
    if recomputed_hash != claimed_hash:
        _fail(
            "MANIFEST_HASH",
            "$envelope.manifest_sha256",
            f"claimed={claimed_hash} recomputed={recomputed_hash}",
        )

    header = _mapping(manifest.get("header"), "$manifest.header")
    if header.get("record_kind") != "header" or header.get("schema") != qwen_graph_manifest.RAW_SCHEMA:
        _fail("HEADER_SCHEMA", "$manifest.header", "raw header identity mismatch")
    bindings = _mapping(header.get("bindings"), "$manifest.header.bindings")
    graph = _mapping(header.get("graph"), "$manifest.header.graph")
    profile = bindings.get("profile")
    source_commit = bindings.get("source_commit")
    graph_scope = graph.get("scope")
    if type(profile) is not str or not profile:
        _fail("HEADER_PROFILE", "$manifest.header.bindings.profile", "missing profile")
    if type(source_commit) is not str or re.fullmatch(r"[0-9a-f]{40}", source_commit) is None:
        _fail("HEADER_SOURCE", "$manifest.header.bindings.source_commit", "malformed commit")
    if type(graph_scope) is not str or not graph_scope:
        _fail("HEADER_SCOPE", "$manifest.header.graph.scope", "missing scope")

    external_value = manifest.get("external_tensors")
    nodes_value = manifest.get("nodes")
    if type(external_value) is not list or type(nodes_value) is not list:
        _fail("GRAPH_ARRAY", "$manifest", "nodes/external_tensors must be arrays")
    external_count = len(external_value)

    external: list[Mapping[str, Any]] = []
    for position, raw_external in enumerate(external_value):
        path = f"$manifest.external_tensors[{position}]"
        item = _mapping(raw_external, path)
        _exact_keys(item, {"descriptor", "index", "record_kind", "sources"}, path)
        if item.get("record_kind") != "external_tensor" or item.get("index") != position:
            _fail("EXTERNAL_INDEX", path, f"expected contiguous external index {position}")
        if item.get("sources") != []:
            _fail("EXTERNAL_SOURCES", path + ".sources", "external tensor must have no sources")
        _descriptor(
            item.get("descriptor"),
            path + ".descriptor",
            node_limit=0,
            external_count=external_count,
        )
        external.append(item)

    nodes: list[Mapping[str, Any]] = []
    classifications: Counter[str] = Counter()
    source_edge_count = 0
    seen_canonical_ids: set[str] = set()
    for position, raw_node in enumerate(nodes_value):
        path = f"$manifest.nodes[{position}]"
        node = _mapping(raw_node, path)
        _exact_keys(node, _NODE_KEYS, path)
        if node.get("record_kind") != "node" or node.get("index") != position:
            _fail("NODE_INDEX", path, f"expected contiguous graph index {position}")
        descriptor = _descriptor(
            node.get("descriptor"),
            path + ".descriptor",
            node_limit=position,
            external_count=external_count,
        )
        classification = node.get("classification")
        expected_classification = qwen_graph_manifest.classify_op(descriptor["op_name"])
        if classification != expected_classification:
            _fail(
                "NODE_CLASSIFICATION",
                path + ".classification",
                f"expected {expected_classification}, got {classification!r}",
            )
        classifications[classification] += 1

        semantic = _mapping(node.get("semantic_key"), path + ".semantic_key")
        _exact_keys(semantic, _SEMANTIC_KEYS, path + ".semantic_key")
        if (
            semantic.get("schema") != qwen_graph_manifest.SEMANTIC_SCHEMA
            or semantic.get("profile") != profile
            or semantic.get("source_commit") != source_commit
            or semantic.get("graph_scope") != graph_scope
            or semantic.get("op") != descriptor.get("op_name")
        ):
            _fail("SEMANTIC_BINDING", path + ".semantic_key", "header/op binding mismatch")
        canonical_id = node.get("canonical_id")
        if type(canonical_id) is not str or _HEX64.fullmatch(canonical_id) is None:
            _fail("CANONICAL_ID", path + ".canonical_id", "malformed SHA-256")
        if canonical_id != canonical_sha256(semantic):
            _fail("CANONICAL_ID", path + ".canonical_id", "semantic identity mismatch")
        if canonical_id in seen_canonical_ids:
            _fail("CANONICAL_ID", path + ".canonical_id", "duplicate canonical identity")
        seen_canonical_ids.add(canonical_id)

        sources = node.get("sources")
        if type(sources) is not list:
            _fail("NODE_SOURCES", path + ".sources", "expected array")
        for slot, raw_source in enumerate(sources):
            source_path = f"{path}.sources[{slot}]"
            source = _mapping(raw_source, source_path)
            _exact_keys(source, {"descriptor", "ref", "slot"}, source_path)
            if source.get("slot") != slot:
                _fail("SOURCE_SLOT", source_path + ".slot", f"expected contiguous slot {slot}")
            kind, index = _reference(
                source.get("ref"),
                source_path + ".ref",
                node_limit=position,
                external_count=external_count,
            )
            source_descriptor = _descriptor(
                source.get("descriptor"),
                source_path + ".descriptor",
                node_limit=position,
                external_count=external_count,
            )
            producer = external[index] if kind == "external" else nodes[index]
            if source_descriptor != producer.get("descriptor"):
                _fail(
                    "SOURCE_DESCRIPTOR",
                    source_path + ".descriptor",
                    f"does not match {kind} producer {index}",
                )
            source_edge_count += 1

        descriptor_hash = node.get("descriptor_sha256")
        if type(descriptor_hash) is not str or _HEX64.fullmatch(descriptor_hash) is None:
            _fail("DESCRIPTOR_HASH", path + ".descriptor_sha256", "malformed SHA-256")
        expected_descriptor_hash = canonical_sha256(
            {"descriptor": descriptor, "sources": sources}
        )
        if descriptor_hash != expected_descriptor_hash:
            _fail("DESCRIPTOR_HASH", path + ".descriptor_sha256", "descriptor/source identity mismatch")
        nodes.append(node)

    counts = _mapping(manifest.get("counts"), "$manifest.counts")
    expected_counts = {
        "compute": classifications["compute"],
        "external_tensors": external_count,
        "metadata": classifications["metadata"],
        "mover": classifications["mover"],
        "source_edges": source_edge_count,
        "total": len(nodes),
    }
    if dict(counts) != expected_counts:
        _fail("GRAPH_COUNTS", "$manifest.counts", f"expected {expected_counts}, got {dict(counts)}")
    if header.get("node_count") != len(nodes):
        _fail("HEADER_NODE_COUNT", "$manifest.header.node_count", f"expected {len(nodes)}")

    return {
        "manifest": dict(manifest),
        "nodes": nodes,
        "external_tensors": external,
        "counts": expected_counts,
        "profile": profile,
        "source_commit": source_commit,
        "graph_scope": graph_scope,
        "manifest_sha256": claimed_hash,
    }


def _add_owner(
    owners: dict[int, dict[str, Any]],
    overlaps: dict[int, list[str]],
    index: int,
    record: dict[str, Any],
) -> None:
    if index in owners:
        overlaps.setdefault(index, [owners[index]["family"]]).append(record["family"])
        return
    owners[index] = record


def _exact_qwen35_v5_owners(
    envelope: Mapping[str, Any], validated: Mapping[str, Any]
) -> tuple[dict[int, dict[str, Any]], dict[str, Any]]:
    """Join the exact manifest to all existing public owner-profile audits."""

    try:
        alu_audit = qwen_f32_alu_profiles.audit_manifest_object(envelope)
        q8_nodes, q8_profiles = qwen_q8_gemv_profiles.audit_q8_gemv_manifest(dict(envelope))
        gather_nodes, gather_profiles = qwen_f32_gather_repeat_profiles.audit_manifest(dict(envelope))
        remaining_audit = qwen_remaining_profiles.audit_manifest_object(envelope)
        sampler_audit = qwen_sampler_argmax_profile.audit_manifest_object(envelope)
    except (RuntimeError, ValueError, KeyError, TypeError) as error:
        _fail("OWNER_AUDIT", "$manifest", str(error))

    del q8_nodes, gather_nodes  # membership is taken from the audited profile members below
    owners: dict[int, dict[str, Any]] = {}
    overlaps: dict[int, list[str]] = {}

    for profile in alu_audit["profiles"]:
        for member in profile["canonical_nodes"]:
            _add_owner(
                owners,
                overlaps,
                member["index"],
                {
                    "family": "f32_alu",
                    "profile_id": profile["profile_id"],
                    "profile_name": profile["profile"],
                    "authority": "qwen_f32_alu_profiles.audit_manifest_object",
                },
            )
    for profile in q8_profiles:
        for member in profile["members"]:
            _add_owner(
                owners,
                overlaps,
                member["index"],
                {
                    "family": "q8_gemv",
                    "profile_id": profile["profile_id"],
                    "authority": "qwen_q8_gemv_profiles.audit_q8_gemv_manifest",
                },
            )
    for profile in gather_profiles:
        for member in profile["members"]:
            _add_owner(
                owners,
                overlaps,
                member["index"],
                {
                    "family": "f32_gather_repeat",
                    "profile_id": profile["profile_id"],
                    "owner": profile["exact"]["owner"],
                    "authority": "qwen_f32_gather_repeat_profiles.audit_manifest",
                },
            )
    for member in remaining_audit["nodes"]:
        _add_owner(
            owners,
            overlaps,
            member["index"],
            {
                "family": "remaining",
                "profile_id": member["profile_id"],
                "owner_id": member["owner"],
                "owner_op": member["dst"]["op_name"],
                "authority": "qwen_remaining_profiles.audit_manifest_object",
            },
        )
    for profile in sampler_audit["profiles"]:
        _add_owner(
            owners,
            overlaps,
            profile["graph_node_index"],
            {
                "family": "sampler_argmax",
                "profile_id": profile["profile_id"],
                "authority": "qwen_sampler_argmax_profile.audit_manifest_object",
            },
        )

    required = {
        node["index"]
        for node in validated["nodes"]
        if node["classification"] in {"compute", "mover"}
    }
    if overlaps:
        _fail("OWNER_OVERLAP", "$manifest.nodes", f"overlaps={overlaps}")

    # The existing remaining-owner public audit validates the one Q8 GET_ROWS
    # owner as part of its exact 646+433+1 partition, but it does not return
    # that row.  Derive that audited singleton as the sole residual and bind it
    # with an additional local signature check.  This is intentionally an
    # adapter, not a copied profile table.
    residual = sorted(required - set(owners))
    if len(residual) != 1:
        _fail("Q8_GET_ROWS_ADAPTER", "$manifest.nodes", f"expected one residual, got {residual}")
    index = residual[0]
    node = validated["nodes"][index]
    sources = node["sources"]
    if not (
        node["classification"] == "compute"
        and node["descriptor"]["op_name"] == "GET_ROWS"
        and node["descriptor"]["type_name"] == "f32"
        and len(sources) == 2
        and sources[0]["slot"] == 0
        and sources[0]["descriptor"]["type_name"] == "q8_0"
        and sources[1]["slot"] == 1
        and sources[1]["descriptor"]["type_name"] == "i32"
    ):
        _fail("Q8_GET_ROWS_ADAPTER", f"$manifest.nodes[{index}]", "residual signature mismatch")
    _add_owner(
        owners,
        overlaps,
        index,
        {
            "family": "q8_get_rows",
            "profile_id": 0,
            "authority": "qwen_remaining_profiles.audit_manifest_object+residual-adapter",
        },
    )

    gaps = sorted(required - set(owners))
    extras = sorted(set(owners) - required)
    family_counts = Counter(record["family"] for record in owners.values())
    observed_counts = {family: family_counts[family] for family in LOWERING_FAMILY_ORDER}
    if gaps or extras or observed_counts != EXPECTED_QWEN35_V5_OWNER_COUNTS:
        _fail(
            "OWNER_PARTITION",
            "$manifest.nodes",
            f"counts={observed_counts} gaps={gaps} extras={extras}",
        )
    return owners, {
        "mode": OWNER_MODE_EXACT,
        "authority_audits": [
            "qwen_f32_alu_profiles.audit_manifest_object",
            "qwen_q8_gemv_profiles.audit_q8_gemv_manifest",
            "qwen_f32_gather_repeat_profiles.audit_manifest",
            "qwen_remaining_profiles.audit_manifest_object",
            "qwen_sampler_argmax_profile.audit_manifest_object",
        ],
        "adapter_notes": [
            "Q8 GET_ROWS is validated by the remaining-owner exact partition; "
            "the public audit omits its row, so this adapter derives the sole residual."
        ],
    }


def _fixture_owners(validated: Mapping[str, Any]) -> tuple[dict[int, dict[str, Any]], dict[str, Any]]:
    """Small-test resolver; production imports must use the exact owner audits."""

    owners: dict[int, dict[str, Any]] = {}
    overlaps: dict[int, list[str]] = {}
    required = [
        node
        for node in validated["nodes"]
        if node["classification"] in {"compute", "mover"}
    ]
    for node in required:
        matches = qwen_f32_alu_profiles.matching_profiles(node)
        if len(matches) == 1:
            profile = matches[0]
            _add_owner(
                owners,
                overlaps,
                node["index"],
                {
                    "family": "f32_alu",
                    "profile_id": profile.profile_id,
                    "profile_name": profile.name,
                    "authority": "qwen_f32_alu_profiles.matching_profiles",
                },
            )
        elif len(matches) > 1:
            overlaps[node["index"]] = [f"f32_alu:{profile.name}" for profile in matches]
    gaps = sorted(node["index"] for node in required if node["index"] not in owners)
    if overlaps:
        _fail("OWNER_OVERLAP", "$manifest.nodes", f"overlaps={overlaps}")
    if gaps:
        _fail(
            "OWNER_GAP",
            "$manifest.nodes",
            "structural fixture mode only accepts nodes matched by the public F32 ALU table; "
            f"gaps={gaps}",
        )
    return owners, {
        "mode": OWNER_MODE_FIXTURE,
        "authority_audits": ["qwen_f32_alu_profiles.matching_profiles"],
        "adapter_notes": [
            "Fixture mode is a parser/identity test only and is not accepted for production codegen."
        ],
    }


def _buffer_id(kind: str, index: int, item: Mapping[str, Any]) -> str:
    if kind == "node":
        return npu_ids.node_buffer_id(str(item["canonical_id"]))
    return npu_ids.external_buffer_id(index, item["descriptor"])


def _buffer_for_ref(
    ref: Mapping[str, Any],
    nodes: Sequence[Mapping[str, Any]],
    external: Sequence[Mapping[str, Any]],
) -> str:
    kind = str(ref["kind"])
    index = int(ref["index"])
    item = nodes[index] if kind == "node" else external[index]
    return _buffer_id(kind, index, item)


def _tensor_record(descriptor: Mapping[str, Any]) -> dict[str, Any]:
    return {
        "flags": descriptor["flags"],
        "name": descriptor["name"],
        "type_id": descriptor["type_id"],
        "type_name": descriptor["type_name"],
        "ne": list(descriptor["ne"]),
        "nb": list(descriptor["nb"]),
        "view_offs": descriptor["view_offs"],
        "tensor_descriptor_sha256": canonical_sha256(descriptor),
    }


def import_manifest_object(
    envelope: Mapping[str, Any], *, owner_mode: str = OWNER_MODE_EXACT
) -> dict[str, Any]:
    """Validate ``envelope`` and return a canonical, address-free GraphIR envelope."""

    validated = _validate_manifest(envelope)
    if owner_mode == OWNER_MODE_EXACT:
        owners, owner_provenance = _exact_qwen35_v5_owners(envelope, validated)
    elif owner_mode == OWNER_MODE_FIXTURE:
        owners, owner_provenance = _fixture_owners(validated)
    else:
        _fail("OWNER_MODE", "$owner_mode", f"unsupported mode {owner_mode!r}")

    nodes = validated["nodes"]
    external = validated["external_tensors"]
    buffers: list[dict[str, Any]] = []
    for kind, items in (("external", external), ("node", nodes)):
        for index, item in enumerate(items):
            descriptor = item["descriptor"]
            view_src = descriptor["view_src"]
            buffers.append(
                {
                    "buffer_id": _buffer_id(kind, index, item),
                    "origin": {
                        "kind": kind,
                        "index": index,
                        "canonical_id": item.get("canonical_id"),
                    },
                    "tensor": _tensor_record(descriptor),
                    "alias": None
                    if view_src is None
                    else {
                        "buffer_id": _buffer_for_ref(view_src, nodes, external),
                        "byte_offset": descriptor["view_offs"],
                    },
                    "runtime_binding": {
                        "state": "unresolved",
                        "iova": None,
                        "allocation_size_bytes": None,
                    },
                }
            )

    graph_nodes: list[dict[str, Any]] = []
    for schedule_position, node in enumerate(
        item for item in nodes if item["classification"] in {"compute", "mover"}
    ):
        source_edges = []
        for source in node["sources"]:
            source_edges.append(
                {
                    "slot": source["slot"],
                    "source_ref": dict(source["ref"]),
                    "buffer_id": _buffer_for_ref(source["ref"], nodes, external),
                    "tensor_descriptor_sha256": canonical_sha256(source["descriptor"]),
                }
            )
        graph_nodes.append(
            {
                "schedule_position": schedule_position,
                "graph_index": node["index"],
                "canonical_id": node["canonical_id"],
                "descriptor_sha256": node["descriptor_sha256"],
                "semantic_key": dict(node["semantic_key"]),
                "classification": node["classification"],
                "operation": {
                    "op_id": node["descriptor"]["op_id"],
                    "op_name": node["descriptor"]["op_name"],
                    "op_desc": node["descriptor"]["op_desc"],
                    "op_params_hex": node["descriptor"]["op_params_hex"],
                },
                "output_buffer_id": _buffer_id("node", node["index"], node),
                "source_edges": source_edges,
                "lowering": {
                    **owners[node["index"]],
                    "state": "classified_not_codegen",
                    "fusion_group": None,
                },
                "dynamic_address_bindings": [
                    {
                        "role": "dst",
                        "buffer_id": _buffer_id("node", node["index"], node),
                        "state": "unresolved",
                    },
                    *[
                        {
                            "role": f"src{source['slot']}",
                            "buffer_id": _buffer_for_ref(source["ref"], nodes, external),
                            "state": "unresolved",
                        }
                        for source in node["sources"]
                    ],
                ],
            }
        )

    family_counter = Counter(node["lowering"]["family"] for node in graph_nodes)
    family_counts = {
        family: family_counter[family]
        for family in LOWERING_FAMILY_ORDER
        if family_counter[family] != 0 or owner_mode == OWNER_MODE_EXACT
    }
    payload = {
        "schema": GRAPH_IR_SCHEMA,
        "source_manifest": {
            "schema": qwen_graph_manifest.MANIFEST_SCHEMA,
            "manifest_sha256": validated["manifest_sha256"],
            "raw_sha256": validated["manifest"]["raw_sha256"],
            "profile": validated["profile"],
            "source_commit": validated["source_commit"],
            "graph_scope": validated["graph_scope"],
            "counts": dict(validated["counts"]),
        },
        "lowering_policy": {
            "order": "original_topological_order",
            "fusion": "none",
            "one_graphir_node_per_required_manifest_node": True,
            "executable_command_descriptors_generated": False,
            "address_resolution": "deferred_to_memory_planning_and_runtime_relocation",
            **owner_provenance,
        },
        "coverage": {
            "required_node_count": len(graph_nodes),
            "metadata_node_count": validated["counts"]["metadata"],
            "assigned_exactly_once": len(owners) == len(graph_nodes),
            "assigned_node_count": len(owners),
            "gap_count": 0,
            "gap_graph_indices": [],
            "overlap_count": 0,
            "overlap_graph_indices": [],
            "owner_family_counts": family_counts,
        },
        "buffers": buffers,
        "nodes": graph_nodes,
    }
    return {
        "schema": GRAPH_IR_ENVELOPE_SCHEMA,
        "graph_ir_sha256": canonical_sha256(payload),
        "graph_ir": payload,
    }


def load_graph_ir(
    manifest_path: pathlib.Path | str, *, owner_mode: str = OWNER_MODE_EXACT
) -> dict[str, Any]:
    """Load canonical bytes from ``manifest_path`` and import them to GraphIR."""

    path = pathlib.Path(manifest_path)
    try:
        envelope = qwen_graph_manifest.load_manifest_envelope(path)
    except (OSError, RuntimeError, ValueError) as error:
        _fail("MANIFEST_LOAD", str(path), str(error))
    return import_manifest_object(envelope, owner_mode=owner_mode)


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("manifest", type=pathlib.Path)
    parser.add_argument("-o", "--output", type=pathlib.Path)
    parser.add_argument(
        "--structural-fixture",
        action="store_true",
        help="test-only: use the small structural F32 owner resolver",
    )
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    arguments = _parser().parse_args(argv)
    owner_mode = OWNER_MODE_FIXTURE if arguments.structural_fixture else OWNER_MODE_EXACT
    try:
        result = load_graph_ir(arguments.manifest, owner_mode=owner_mode)
    except GraphIRError as error:
        print(f"[NPU-GRAPHIR] error={error}", file=sys.stderr)
        return 2
    if arguments.output is not None:
        arguments.output.parent.mkdir(parents=True, exist_ok=True)
        arguments.output.write_bytes(canonical_bytes(result) + b"\n")
    coverage = result["graph_ir"]["coverage"]
    counts = ",".join(
        f"{family}:{count}" for family, count in coverage["owner_family_counts"].items()
    )
    print(
        "[NPU-GRAPHIR] "
        f"required={coverage['required_node_count']} metadata={coverage['metadata_node_count']} "
        f"families={counts} gaps={coverage['gap_count']} overlaps={coverage['overlap_count']} "
        f"sha256={result['graph_ir_sha256']}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
