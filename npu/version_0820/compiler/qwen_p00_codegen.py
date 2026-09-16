#!/usr/bin/env python3
"""Production code generation for one exact Qwen P00 graph slice.

The input to this stage is not an arbitrary shape-compatible GGML node.  It is
an identity-checked :class:`P00Selection` produced from the exact Qwen graph
manifest, plus the exact on-disk bytes of its external F32 bias tensor.  The
output is the low-level relocatable graph accepted by ``npu_artifact`` and a
bundle that has already crossed the same load-time trust boundary as the C++
runtime.

This deliberately remains a one-node compiler slice.  It proves the real
manifest -> GraphIR -> VIEW/storage normalization -> descriptor -> raw GGUF
weight -> artifact path without implying that the complete Qwen graph is
lowered or that token generation is available yet.
"""

from __future__ import annotations

import hashlib
import struct
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Mapping, Sequence

from . import npu_artifact, qwen_graph_ir
from .qwen_p00_lowering import NormalizedBuffer, P00Selection, select_exact_p00
from .qwen_weights import RawWeight, extract_gguf_tensor_bytes


COMMAND_FLAGS = 0x11
CAPABILITY_EPOCH = 1
DTYPE_F32 = 1
PORTAL_LANE_WORDS = 8
PERMISSIONS_SRC0_READ_SRC1_READ_DST_WRITE = 0x97
IDENTITY_DOMAIN = b"qwen-p00-command-identity-v1\x00"
UINT64_MAX = (1 << 64) - 1


class P00CodegenError(ValueError):
    """Fail-closed code-generation diagnostic with a stable code and path."""

    def __init__(self, code: str, path: str, detail: str):
        super().__init__(f"{code} at {path}: {detail}")
        self.code = code
        self.path = path
        self.detail = detail


def _fail(code: str, path: str, detail: str) -> None:
    raise P00CodegenError(code, path, detail)


@dataclass(frozen=True)
class P00Compilation:
    selection: P00Selection
    weight: RawWeight
    low_level_graph: Mapping[str, Any]
    bundle: npu_artifact.ArtifactBundle
    verified: npu_artifact.LoadedBundle


def _u64(value: Any, path: str) -> int:
    if type(value) is not int or value < 0 or value > UINT64_MAX:
        _fail("P00_CODEGEN_U64", path, "expected an unsigned 64-bit integer")
    return value


def _shape_without_trailing_ones(values: Sequence[int]) -> tuple[int, ...]:
    result = tuple(values)
    while len(result) > 1 and result[-1] == 1:
        result = result[:-1]
    return result


def _origin_kind(kind: str, path: str) -> str:
    if kind == "node":
        return "graph_node"
    if kind == "external":
        return "constant"
    _fail("P00_CODEGEN_ORIGIN", path, f"unsupported GraphIR origin {kind!r}")


def _checked_product(values: Sequence[int], path: str) -> int:
    result = 1
    for index, raw in enumerate(values):
        value = _u64(raw, f"{path}[{index}]")
        if value == 0 or result > UINT64_MAX // value:
            _fail("P00_CODEGEN_RANGE", path, "empty or overflowing tensor cardinality")
        result *= value
    return result


def _validate_buffer(buffer: NormalizedBuffer, path: str) -> None:
    if not buffer.buffer_id or len(buffer.buffer_id) > 64:
        _fail("P00_CODEGEN_BUFFER", path + ".buffer_id", "invalid artifact BufferId")
    _u64(buffer.logical_origin_index, path + ".logical_origin_index")
    _u64(buffer.storage_origin_index, path + ".storage_origin_index")
    offset = _u64(buffer.alias_offset, path + ".alias_offset")
    logical_size = _u64(buffer.logical_size, path + ".logical_size")
    storage_size = _u64(buffer.storage_size, path + ".storage_size")
    if logical_size == 0 or storage_size == 0:
        _fail("P00_CODEGEN_BUFFER", path, "zero-sized buffers are not executable")
    if offset >= storage_size or logical_size > storage_size - offset:
        _fail("P00_CODEGEN_BUFFER", path, "logical range exceeds normalized storage")
    for field, value in (
        ("logical_descriptor_sha256", buffer.logical_descriptor_sha256),
        ("storage_descriptor_sha256", buffer.storage_descriptor_sha256),
    ):
        if (
            type(value) is not str
            or len(value) != 64
            or any(character not in "0123456789abcdef" for character in value)
        ):
            _fail("P00_CODEGEN_HASH", f"{path}.{field}", "expected lowercase SHA-256")


def _validate_codegen_inputs(selection: P00Selection, weight: RawWeight) -> None:
    profile = selection.profile
    if not (
        profile.profile_id == 0
        and profile.name == "P00"
        and profile.op == "ADD"
        and profile.vector_op == 1
        and profile.src1 is not None
        and profile.scalar0 == 0
        and profile.permissions == (1, 1, 2)
    ):
        _fail("P00_CODEGEN_PROFILE", "$selection.profile", "exact F32 ADD P00 required")
    elements = _checked_product(profile.dst.ne, "$selection.profile.dst.ne")
    if elements != profile.elements or profile.outer_count != 1 or profile.dst.ne[0] != 16:
        _fail("P00_CODEGEN_PROFILE", "$selection.profile", "unexpected P00 cardinality")
    if profile.cycle_upper_bound <= 0:
        _fail("P00_CODEGEN_PROFILE", "$selection.profile.cycle_upper_bound", "must be positive")
    _u64(selection.manifest_graph_index, "$selection.manifest_graph_index")
    _u64(selection.schedule_position, "$selection.schedule_position")
    _validate_buffer(selection.src0, "$selection.src0")
    _validate_buffer(selection.src1, "$selection.src1")
    _validate_buffer(selection.dst, "$selection.dst")
    if len({selection.src0.buffer_id, selection.src1.buffer_id, selection.dst.buffer_id}) != 3:
        _fail("P00_CODEGEN_BUFFER", "$selection", "src0/src1/dst BufferIds must be unique")
    if (
        selection.src0.logical_origin_kind != "node"
        or selection.src0.storage_origin_kind != "node"
        or selection.src0.logical_origin_index == selection.src0.storage_origin_index
        or selection.src0.alias_offset != profile.src0.view_off
    ):
        _fail("P00_CODEGEN_VIEW", "$selection.src0", "metadata VIEW/storage root was not preserved")
    if (
        selection.src1.logical_origin_kind != "external"
        or selection.src1.storage_origin_kind != "external"
        or selection.src1.logical_origin_index != selection.src1.storage_origin_index
        or selection.src1.alias_offset != 0
    ):
        _fail("P00_CODEGEN_WEIGHT", "$selection.src1", "bias must be one non-view external tensor")
    if (
        selection.dst.logical_origin_kind != "node"
        or selection.dst.storage_origin_kind != "node"
        or selection.dst.logical_origin_index != selection.manifest_graph_index
        or selection.dst.storage_origin_index != selection.manifest_graph_index
        or selection.dst.logical_canonical_id != selection.canonical_id
        or selection.dst.storage_canonical_id != selection.canonical_id
        or selection.dst.alias_offset != 0
    ):
        _fail("P00_CODEGEN_OUTPUT", "$selection.dst", "destination provenance is not the selected node")
    expected_bytes = elements * 4
    if (
        selection.src0.logical_size != expected_bytes
        or selection.src1.logical_size != expected_bytes
        or selection.dst.logical_size != expected_bytes
    ):
        _fail("P00_CODEGEN_SIZE", "$selection", "P00 logical buffers must each cover 16 F32 values")
    if weight.name != selection.src1.tensor_name:
        _fail("P00_CODEGEN_WEIGHT", "$weight.name", "does not match the selected external tensor")
    if weight.ggml_type.lower() != "f32":
        _fail("P00_CODEGEN_WEIGHT", "$weight.ggml_type", "P00 bias must be raw F32")
    if _shape_without_trailing_ones(weight.shape) != _shape_without_trailing_ones(profile.src1.ne):
        _fail("P00_CODEGEN_WEIGHT", "$weight.shape", "does not match the P00 source shape")
    if len(weight.data) != selection.src1.logical_size:
        _fail("P00_CODEGEN_WEIGHT", "$weight.data", "raw bias byte count differs from GraphIR")
    if hashlib.sha256(weight.data).hexdigest() != weight.sha256:
        _fail("P00_CODEGEN_WEIGHT", "$weight.sha256", "raw bias hash is inconsistent")


def _identity_value(seed: bytes, label: str, byte_count: int) -> int:
    digest = hashlib.sha256(IDENTITY_DOMAIN + label.encode("ascii") + b"\x00" + seed).digest()
    value = int.from_bytes(digest[:byte_count], "little")
    return value if value != 0 else 1


def _command_identity(selection: P00Selection) -> tuple[int, int, int, int]:
    seed = npu_artifact.canonical_json_bytes(
        {
            "canonical_id": selection.canonical_id,
            "graph_ir_sha256": selection.graph_ir_sha256,
            "manifest_graph_index": selection.manifest_graph_index,
            "manifest_sha256": selection.source_graph["manifest_sha256"],
            "profile_id": selection.profile.profile_id,
            "source_descriptor_sha256": selection.descriptor_sha256,
            "source_schedule_position": selection.schedule_position,
        }
    )
    return (
        _identity_value(seed, "context", 4),
        _identity_value(seed, "sequence", 8),
        _identity_value(seed, "producer", 8),
        _identity_value(seed, "user-tag", 8),
    )


def _node_digest(node_id: int) -> bytes:
    return hashlib.sha256(struct.pack("<Q", _u64(node_id, "$node_id"))).digest()


def _descriptor_words(selection: P00Selection) -> list[int]:
    profile = selection.profile
    context_id, sequence_id, producer_id, user_tag = _command_identity(selection)
    digest = _node_digest(selection.manifest_graph_index)
    words = [
        (COMMAND_FLAGS << 32) | npu_artifact.F32_ALU_KERNEL_ID,
        (CAPABILITY_EPOCH << 32) | context_id,
        sequence_id,
        producer_id,
        user_tag,
        (profile.vector_op << 32) | 1,
        int.from_bytes(digest[0:8], "little"),
        int.from_bytes(digest[8:16], "little"),
        # F32 portal ABI has no deadline field support. The checked host
        # timeout remains compiler-owned metadata.cycle_upper_bound.
        0,
        (profile.outer_count << 32) | profile.profile_id,
        selection.src0.alias_offset,
        selection.src1.alias_offset,
        0,
        selection.dst.alias_offset,
        0,
        profile.dst.ne[0],
        (profile.scalar0 << 32) | DTYPE_F32,
        0,
        0,
        profile.src0.nb[1],
        profile.src1.nb[1],
        0,
        profile.dst.nb[1],
        selection.src0.alias_offset,
        selection.src0.logical_size,
        PERMISSIONS_SRC0_READ_SRC1_READ_DST_WRITE,
        selection.src1.alias_offset,
        selection.src1.logical_size,
        selection.dst.alias_offset,
        selection.dst.logical_size,
    ]
    if len(words) != npu_artifact.COMMAND_RECORD_WORDS:
        _fail("P00_CODEGEN_DESCRIPTOR", "$descriptor", "internal word-count mismatch")
    return words


def _command_descriptor_sha256(words: Sequence[int]) -> str:
    try:
        payload = struct.pack("<" + "Q" * npu_artifact.COMMAND_RECORD_WORDS, *words)
    except (struct.error, TypeError) as error:
        _fail("P00_CODEGEN_DESCRIPTOR", "$descriptor", str(error))
    return hashlib.sha256(payload).hexdigest()


def _relocation(word_index: int, buffer_id: str, addend: int) -> dict[str, Any]:
    return {
        "word_index": word_index,
        "kind": "window_base64" if word_index in {23, 26, 28} else "iova64",
        "buffer_id": buffer_id,
        "addend": addend,
    }


def _workload(selection: P00Selection) -> dict[str, Any]:
    elements = selection.profile.elements
    read_groups = (elements + PORTAL_LANE_WORDS - 1) // PORTAL_LANE_WORDS
    write_groups = (elements + PORTAL_LANE_WORDS - 1) // PORTAL_LANE_WORDS
    input_words = elements * 2
    output_words = elements
    # This is the service portal's exact 32-bit payload ledger.  The profile
    # authority's ``read_bytes`` field uses its older global-memory accounting
    # convention and is intentionally not copied into ABI 1.1 metadata.
    return {
        "schema": npu_artifact.F32_ALU_WORKLOAD_SCHEMA,
        "request_groups": read_groups + write_groups,
        "response_groups": read_groups + write_groups,
        "read_groups": read_groups,
        "write_groups": write_groups,
        "input_words": input_words,
        "output_words": output_words,
        "read_bytes": input_words * 4,
        "write_bytes": output_words * 4,
        "completion_vector_elements": elements,
        "expected_starts": 1,
    }


def _buffer_binding(buffer: NormalizedBuffer) -> dict[str, Any]:
    return {
        "buffer_id": buffer.buffer_id,
        "origin_kind": _origin_kind(buffer.logical_origin_kind, "$provenance.buffer.origin_kind"),
        "origin_index": buffer.logical_origin_index,
        "canonical_id": buffer.logical_canonical_id,
        "tensor_descriptor_sha256": buffer.logical_descriptor_sha256,
        "storage_origin_kind": _origin_kind(
            buffer.storage_origin_kind, "$provenance.buffer.storage_origin_kind"
        ),
        "storage_origin_index": buffer.storage_origin_index,
        "storage_canonical_id": buffer.storage_canonical_id,
        "storage_tensor_descriptor_sha256": buffer.storage_descriptor_sha256,
        "alias_offset": buffer.alias_offset,
        "logical_size": buffer.logical_size,
        "storage_size": buffer.storage_size,
    }


def build_p00_graph(selection: P00Selection, weight: RawWeight) -> dict[str, Any]:
    """Build the deterministic low-level v3 graph for a trusted P00 selection."""

    _validate_codegen_inputs(selection, weight)
    source = selection.source_graph
    required_source_fields = {
        "schema",
        "manifest_sha256",
        "raw_sha256",
        "profile",
        "source_commit",
        "graph_scope",
        "graph_ir_schema",
        "graph_ir_sha256",
    }
    if set(npu_artifact.SOURCE_PROVENANCE_FIELDS) != required_source_fields:
        _fail(
            "P00_CODEGEN_PROVENANCE_SCHEMA",
            "$graph.provenance.source",
            "artifact v3 must bind both manifest and GraphIR identities",
        )
    words = _descriptor_words(selection)
    command_hash = _command_descriptor_sha256(words)
    graph_name = (
        f"qwen-p00-node-{selection.manifest_graph_index}-"
        f"{selection.canonical_id[:12]}"
    )
    buffers = [
        {
            "id": selection.src0.buffer_id,
            "kind": "input",
            "size": selection.src0.storage_size,
            "alignment": 64,
            "permissions": "r",
        },
        {
            "id": selection.src1.buffer_id,
            "kind": "weight",
            "alignment": 64,
            "permissions": "r",
            "data_hex": weight.data.hex(),
        },
        {
            "id": selection.dst.buffer_id,
            "kind": "output",
            "size": selection.dst.storage_size,
            "alignment": 64,
            "permissions": "w",
        },
    ]
    buffers.sort(key=lambda item: item["id"])
    buffer_bindings = [
        _buffer_binding(selection.src0),
        _buffer_binding(selection.src1),
        _buffer_binding(selection.dst),
    ]
    buffer_bindings.sort(key=lambda item: item["buffer_id"])
    return {
        "schema": npu_artifact.GRAPH_SCHEMA,
        "name": graph_name,
        "buffers": buffers,
        "commands": [
            {
                "cycle_upper_bound": selection.profile.cycle_upper_bound,
                "name": graph_name,
                "node_ids": [selection.manifest_graph_index],
                "owner": npu_artifact.F32_ALU_OWNER,
                "workload": _workload(selection),
                "descriptor_words": words,
                "relocations": [
                    _relocation(10, selection.src0.buffer_id, selection.src0.alias_offset),
                    _relocation(11, selection.src1.buffer_id, selection.src1.alias_offset),
                    _relocation(13, selection.dst.buffer_id, selection.dst.alias_offset),
                    _relocation(23, selection.src0.buffer_id, selection.src0.alias_offset),
                    _relocation(26, selection.src1.buffer_id, selection.src1.alias_offset),
                    _relocation(28, selection.dst.buffer_id, selection.dst.alias_offset),
                ],
            }
        ],
        "publications": [
            {
                "buffer_id": selection.dst.buffer_id,
                "source_offset": 0,
                "target_offset": 0,
                "bytes": selection.dst.storage_size,
            }
        ],
        "provenance": {
            "source": {
                "schema": source["schema"],
                "manifest_sha256": source["manifest_sha256"],
                "raw_sha256": source["raw_sha256"],
                "profile": source["profile"],
                "source_commit": source["source_commit"],
                "graph_scope": source["graph_scope"],
                "graph_ir_schema": qwen_graph_ir.GRAPH_IR_SCHEMA,
                "graph_ir_sha256": selection.graph_ir_sha256,
            },
            "node_bindings": [
                {
                    "artifact_node_id": selection.manifest_graph_index,
                    "canonical_id": selection.canonical_id,
                    "manifest_graph_index": selection.manifest_graph_index,
                    "source_descriptor_sha256": selection.descriptor_sha256,
                    "command_descriptor_sha256": command_hash,
                    "artifact_schedule_position": 0,
                    "source_schedule_position": selection.schedule_position,
                    "profile_family": "f32_alu",
                    "profile_id": selection.profile.name.lower(),
                }
            ],
            "buffer_bindings": buffer_bindings,
        },
    }


def compile_exact_p00(
    manifest_path: str | Path,
    canonical_id: str,
    model_path: str | Path,
) -> P00Compilation:
    """Compile and immediately revalidate one exact production P00 bundle."""

    selection = select_exact_p00(manifest_path, canonical_id)
    weight = extract_gguf_tensor_bytes(
        model_path,
        selection.src1.tensor_name,
        expected_type="f32",
        expected_shape=selection.profile.src1.ne,
        expected_nbytes=selection.src1.logical_size,
    )
    graph = build_p00_graph(selection, weight)
    bundle = npu_artifact.compile_graph(graph)
    verified = npu_artifact.load_bundle(
        bundle.command_bin,
        bundle.weights_bin,
        bundle.metadata_json,
    )
    return P00Compilation(
        selection=selection,
        weight=weight,
        low_level_graph=graph,
        bundle=bundle,
        verified=verified,
    )
