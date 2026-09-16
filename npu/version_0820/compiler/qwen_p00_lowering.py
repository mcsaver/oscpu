#!/usr/bin/env python3
"""Exact Qwen GraphIR selection and normalization for the first P00 slice.

This is intentionally narrower than a general NPU compiler.  It selects one
canonical P00 node from an exact, fully audited Qwen manifest and proves the
metadata VIEW, storage root, weight edge, and output identities needed by the
subsequent buffer-planning and command-generation pass.
"""

from __future__ import annotations

import re
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Mapping, Sequence

from . import qwen_graph_ir


UINT64_MAX = (1 << 64) - 1
LOWER_SHA256_RE = re.compile(r"[0-9a-f]{64}\Z")


class P00LoweringError(ValueError):
    """Fail-closed P00 lowering diagnostic with a stable code and path."""

    def __init__(self, code: str, path: str, detail: str):
        super().__init__(f"{code} at {path}: {detail}")
        self.code = code
        self.path = path
        self.detail = detail


def _fail(code: str, path: str, detail: str) -> None:
    raise P00LoweringError(code, path, detail)


def _checked_u64(value: Any, path: str) -> int:
    if type(value) is not int or value < 0 or value > UINT64_MAX:
        _fail("P00_U64", path, "expected an unsigned 64-bit integer")
    return value


def _exact_tensor(
    tensor: Mapping[str, Any],
    profile_tensor: Any,
    *,
    require_view: bool,
    path: str,
) -> None:
    try:
        actual_ne = tuple(tensor["ne"])
        actual_nb = tuple(tensor["nb"])
        actual_offset = tensor["view_offs"]
        actual_type = tensor["type_name"]
    except (KeyError, TypeError) as error:
        _fail("P00_TENSOR", path, str(error))
    if (
        actual_type != "f32"
        or actual_ne != tuple(profile_tensor.ne)
        or actual_nb != tuple(profile_tensor.nb)
        or actual_offset != profile_tensor.view_off
        or bool(profile_tensor.view) != require_view
    ):
        _fail(
            "P00_TENSOR",
            path,
            "tensor shape/stride/type/view-offset differs from profile authority",
        )


@dataclass(frozen=True)
class NormalizedBuffer:
    buffer_id: str
    logical_origin_kind: str
    logical_origin_index: int
    logical_canonical_id: str | None
    logical_descriptor_sha256: str
    storage_origin_kind: str
    storage_origin_index: int
    storage_canonical_id: str | None
    storage_descriptor_sha256: str
    alias_offset: int
    logical_size: int
    storage_size: int
    tensor_name: str


@dataclass(frozen=True)
class P00Selection:
    manifest_path: Path
    source_graph: Mapping[str, Any]
    graph_ir_sha256: str
    canonical_id: str
    manifest_graph_index: int
    schedule_position: int
    descriptor_sha256: str
    profile: Any
    src0: NormalizedBuffer
    src1: NormalizedBuffer
    dst: NormalizedBuffer


def _logical_bytes(tensor: Mapping[str, Any], path: str) -> int:
    if tensor.get("type_name") != "f32":
        _fail("P00_TENSOR", path + ".type_name", "P00 requires f32")
    elements = 1
    ne = tensor.get("ne")
    if type(ne) is not list or len(ne) != 4:
        _fail("P00_TENSOR", path + ".ne", "expected rank-four GGML dimensions")
    for index, dimension in enumerate(ne):
        value = _checked_u64(dimension, f"{path}.ne[{index}]")
        if value == 0 or elements > UINT64_MAX // value:
            _fail("P00_RANGE", path + ".ne", "element count is empty or overflows")
        elements *= value
    if elements > UINT64_MAX // 4:
        _fail("P00_RANGE", path, "F32 logical byte size overflows")
    return elements * 4


def _origin(buffer: Mapping[str, Any], path: str) -> tuple[str, int, str | None]:
    origin = buffer.get("origin")
    if type(origin) is not dict:
        _fail("P00_BUFFER", path + ".origin", "expected object")
    kind = origin.get("kind")
    index = origin.get("index")
    canonical_id = origin.get("canonical_id")
    if kind not in {"node", "external"} or type(index) is not int or index < 0:
        _fail("P00_BUFFER", path + ".origin", "invalid origin kind/index")
    if kind == "node":
        if type(canonical_id) is not str or LOWER_SHA256_RE.fullmatch(canonical_id) is None:
            _fail("P00_BUFFER", path + ".origin.canonical_id", "invalid node identity")
    elif canonical_id is not None:
        _fail("P00_BUFFER", path + ".origin.canonical_id", "external identity must be null")
    return kind, index, canonical_id


def _normalize_buffer(
    first_id: str,
    buffers: Mapping[str, Mapping[str, Any]],
    path: str,
) -> tuple[NormalizedBuffer, int]:
    if first_id not in buffers:
        _fail("P00_BUFFER", path, f"unknown BufferId {first_id!r}")
    logical = buffers[first_id]
    chain: list[str] = []
    seen: set[str] = set()
    current_id = first_id
    offset = 0
    while True:
        if current_id in seen:
            _fail("P00_ALIAS_CYCLE", path, f"cycle at {current_id!r}")
        seen.add(current_id)
        chain.append(current_id)
        current = buffers.get(current_id)
        if current is None:
            _fail("P00_ALIAS_ROOT", path, f"unknown alias target {current_id!r}")
        alias = current.get("alias")
        if alias is None:
            storage = current
            break
        if type(alias) is not dict or set(alias) != {"buffer_id", "byte_offset"}:
            _fail("P00_ALIAS", path, "alias must contain BufferId and byte offset")
        addend = _checked_u64(alias["byte_offset"], path + ".alias.byte_offset")
        if offset > UINT64_MAX - addend:
            _fail("P00_ALIAS_RANGE", path, "alias offset overflows u64")
        offset += addend
        target = alias["buffer_id"]
        if type(target) is not str:
            _fail("P00_ALIAS", path + ".alias.buffer_id", "expected string")
        current_id = target

    logical_tensor = logical.get("tensor")
    storage_tensor = storage.get("tensor")
    if type(logical_tensor) is not dict or type(storage_tensor) is not dict:
        _fail("P00_BUFFER", path + ".tensor", "missing tensor descriptor")
    logical_size = _logical_bytes(logical_tensor, path + ".logical.tensor")
    storage_size = _logical_bytes(storage_tensor, path + ".storage.tensor")
    if offset > storage_size or logical_size > storage_size - offset:
        _fail(
            "P00_ALIAS_RANGE",
            path,
            f"logical [{offset}, {offset + logical_size}) exceeds root size {storage_size}",
        )
    logical_kind, logical_index, logical_id = _origin(logical, path + ".logical")
    storage_kind, storage_index, storage_id = _origin(storage, path + ".storage")
    logical_hash = logical_tensor.get("tensor_descriptor_sha256")
    storage_hash = storage_tensor.get("tensor_descriptor_sha256")
    if (
        type(logical_hash) is not str
        or LOWER_SHA256_RE.fullmatch(logical_hash) is None
        or type(storage_hash) is not str
        or LOWER_SHA256_RE.fullmatch(storage_hash) is None
    ):
        _fail("P00_BUFFER", path + ".tensor_descriptor_sha256", "invalid descriptor hash")
    name = logical_tensor.get("name")
    if type(name) is not str or not name:
        _fail("P00_BUFFER", path + ".tensor.name", "missing tensor name")
    return (
        NormalizedBuffer(
            buffer_id=first_id,
            logical_origin_kind=logical_kind,
            logical_origin_index=logical_index,
            logical_canonical_id=logical_id,
            logical_descriptor_sha256=logical_hash,
            storage_origin_kind=storage_kind,
            storage_origin_index=storage_index,
            storage_canonical_id=storage_id,
            storage_descriptor_sha256=storage_hash,
            alias_offset=offset,
            logical_size=logical_size,
            storage_size=storage_size,
            tensor_name=name,
        ),
        len(chain),
    )


def select_exact_p00(
    manifest_path: str | Path,
    canonical_id: str,
) -> P00Selection:
    """Select and normalize one production P00 node from an exact manifest."""

    if type(canonical_id) is not str or LOWER_SHA256_RE.fullmatch(canonical_id) is None:
        _fail("P00_CANONICAL_ID", "$canonical_id", "expected 64 lowercase hex digits")
    path = Path(manifest_path)
    try:
        envelope = qwen_graph_ir.load_graph_ir(path, owner_mode=qwen_graph_ir.OWNER_MODE_EXACT)
    except qwen_graph_ir.GraphIRError as error:
        _fail("P00_GRAPHIR", error.path, f"{error.code}: {error.detail}")
    payload = envelope["graph_ir"]
    if payload["lowering_policy"].get("mode") != qwen_graph_ir.OWNER_MODE_EXACT:
        _fail("P00_OWNER_MODE", "$graph_ir.lowering_policy.mode", "exact mode required")
    candidates = [node for node in payload["nodes"] if node.get("canonical_id") == canonical_id]
    if len(candidates) != 1:
        _fail("P00_NODE_LOOKUP", "$graph_ir.nodes", f"expected one node, found {len(candidates)}")
    node = candidates[0]
    lowering = node.get("lowering")
    if not (
        type(lowering) is dict
        and lowering.get("family") == "f32_alu"
        and lowering.get("profile_id") == 0
        and node.get("classification") == "compute"
        and node.get("operation", {}).get("op_name") == "ADD"
    ):
        _fail("P00_PROFILE", "$graph_ir.nodes[selected]", "selected node is not exact F32 P00")

    graph_index = _checked_u64(node.get("graph_index"), "$graph_ir.nodes[selected].graph_index")
    schedule_position = _checked_u64(
        node.get("schedule_position"), "$graph_ir.nodes[selected].schedule_position"
    )
    try:
        manifest_envelope = qwen_graph_ir.qwen_graph_manifest.load_manifest_envelope(path)
        manifest_node = manifest_envelope["manifest"]["nodes"][graph_index]
    except (IndexError, KeyError, OSError, TypeError, ValueError) as error:
        _fail("P00_MANIFEST", "$manifest", str(error))
    if (
        manifest_node.get("index") != graph_index
        or manifest_node.get("canonical_id") != canonical_id
        or manifest_node.get("descriptor_sha256") != node.get("descriptor_sha256")
    ):
        _fail("P00_MANIFEST_BINDING", f"$manifest.nodes[{graph_index}]", "identity mismatch")
    matches = qwen_graph_ir.qwen_f32_alu_profiles.matching_profiles(manifest_node)
    if len(matches) != 1 or matches[0].profile_id != 0:
        _fail("P00_PROFILE", f"$manifest.nodes[{graph_index}]", "authority did not return P00")
    profile = matches[0]

    edges = node.get("source_edges")
    if type(edges) is not list or [edge.get("slot") for edge in edges] != [0, 1]:
        _fail("P00_EDGES", "$graph_ir.nodes[selected].source_edges", "expected exact slots 0,1")
    raw_buffers = payload.get("buffers")
    if type(raw_buffers) is not list:
        _fail("P00_BUFFER", "$graph_ir.buffers", "expected array")
    buffers: dict[str, Mapping[str, Any]] = {}
    for index, buffer in enumerate(raw_buffers):
        if type(buffer) is not dict or type(buffer.get("buffer_id")) is not str:
            _fail("P00_BUFFER", f"$graph_ir.buffers[{index}]", "invalid buffer record")
        if buffer["buffer_id"] in buffers:
            _fail("P00_BUFFER", f"$graph_ir.buffers[{index}].buffer_id", "duplicate")
        buffers[buffer["buffer_id"]] = buffer

    src0, src0_chain = _normalize_buffer(edges[0]["buffer_id"], buffers, "$p00.src0")
    src1, src1_chain = _normalize_buffer(edges[1]["buffer_id"], buffers, "$p00.src1")
    dst, dst_chain = _normalize_buffer(node["output_buffer_id"], buffers, "$p00.dst")
    if src0_chain < 2 or src0.alias_offset != 0:
        _fail("P00_VIEW", "$p00.src0", "P00 src0 must preserve an offset-zero metadata VIEW")
    if src1_chain != 1 or dst_chain != 1:
        _fail("P00_ALIAS", "$p00", "P00 src1 and destination must not be aliases")
    _exact_tensor(buffers[src0.buffer_id]["tensor"], profile.src0, require_view=True, path="$p00.src0")
    _exact_tensor(buffers[src1.buffer_id]["tensor"], profile.src1, require_view=False, path="$p00.src1")
    _exact_tensor(buffers[dst.buffer_id]["tensor"], profile.dst, require_view=False, path="$p00.dst")
    if src1.logical_origin_kind != "external":
        _fail("P00_WEIGHT", "$p00.src1", "P00 bias must be an external model tensor")

    return P00Selection(
        manifest_path=path,
        source_graph=dict(payload["source_manifest"]),
        graph_ir_sha256=envelope["graph_ir_sha256"],
        canonical_id=canonical_id,
        manifest_graph_index=graph_index,
        schedule_position=schedule_position,
        descriptor_sha256=node["descriptor_sha256"],
        profile=profile,
        src0=src0,
        src1=src1,
        dst=dst,
    )


def exact_p00_canonical_ids(manifest_path: str | Path) -> tuple[str, ...]:
    """Return all P00 canonical IDs after the production exact-cover audit."""

    try:
        envelope = qwen_graph_ir.load_graph_ir(
            Path(manifest_path), owner_mode=qwen_graph_ir.OWNER_MODE_EXACT
        )
    except qwen_graph_ir.GraphIRError as error:
        _fail("P00_GRAPHIR", error.path, f"{error.code}: {error.detail}")
    result = tuple(
        node["canonical_id"]
        for node in envelope["graph_ir"]["nodes"]
        if node["lowering"]["family"] == "f32_alu"
        and node["lowering"]["profile_id"] == 0
    )
    if len(result) != 18 or len(set(result)) != len(result):
        _fail("P00_CENSUS", "$graph_ir.nodes", f"expected 18 unique nodes, got {len(result)}")
    return result

