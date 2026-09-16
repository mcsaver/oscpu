#!/usr/bin/env python3
"""Fail-closed v3 NPU compiler artifacts and relocation support.

``command.bin`` is deliberately a relocatable template.  Its records use the
same 30-word macro descriptor consumed by ``NpcTensorNpuSystemTop`` today, but
addresses are represented by an addend plus a relocation in ``metadata.json``.
The runtime validates the immutable three-file bundle first, then materializes
an executable command image using registered IOVA buffer bases.

This module performs no tensor arithmetic.  Weight payloads are copied as raw
bytes and all hashes are control-integrity hashes.
"""

from __future__ import annotations

import hashlib
import json
import os
import re
import struct
import tempfile
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Iterable, Mapping, Sequence


ABI_MAJOR = 1
ABI_MINOR = 1
SERVICE_ABI_MAJOR = 1
SERVICE_ABI_MINOR = 1
COMMAND_MAGIC = b"NPUCMD\x00\x00"
COMMAND_HEADER_BYTES = 64
COMMAND_RECORD_WORDS = 30
COMMAND_RECORD_BYTES = COMMAND_RECORD_WORDS * 8
COMMAND_HEADER = struct.Struct("<8sHHHHIIQ32s")
COMMAND_RECORD = struct.Struct("<" + "Q" * COMMAND_RECORD_WORDS)
WEIGHT_ALIGNMENT = 64
GRAPH_SCHEMA = "npu-compiler-graph-v3"
METADATA_SCHEMA = "npu-artifact-bundle-v3"
F32_ALU_OWNER = "f32_alu"
F32_ALU_KERNEL_ID = 0x514E0010
F32_ALU_WORKLOAD_SCHEMA = "f32-alu-v1"
PUBLICATION_MODE = "bundle_atomic"
UINT64_MAX = (1 << 64) - 1

IDENTITY_FIELDS = (
    "kernel_id",
    "command_flags",
    "context_id",
    "sequence_id",
    "producer_id",
    "user_tag",
    "covered_node_count",
    "node_hash_lo",
    "node_hash_hi",
    "local_profile",
)
IDENTITY_U32_FIELDS = frozenset(
    {"kernel_id", "command_flags", "context_id", "covered_node_count", "local_profile"}
)
WORKLOAD_FIELDS = (
    "request_groups",
    "response_groups",
    "read_groups",
    "write_groups",
    "input_words",
    "output_words",
    "read_bytes",
    "write_bytes",
    "completion_vector_elements",
    "expected_starts",
)

IOVA_WORDS = frozenset({10, 11, 12, 13})
WINDOW_BASE_WORDS = frozenset({23, 26, 28})
RELOCATION_WORDS = IOVA_WORDS | WINDOW_BASE_WORDS
RELOCATION_KIND_FOR_WORD = {
    **{word: "iova64" for word in IOVA_WORDS},
    **{word: "window_base64" for word in WINDOW_BASE_WORDS},
}
WINDOW_ADDRESS_PAIRS = ((10, 23), (11, 26), (13, 28))
SOURCE_WORDS = frozenset({10, 11, 12, 23, 26})
DESTINATION_WORDS = frozenset({13, 28})
BUFFER_ID_RE = re.compile(r"[A-Za-z][A-Za-z0-9_.-]{0,63}\Z")
LOWER_SHA256_RE = re.compile(r"[0-9a-f]{64}\Z")
SOURCE_SCHEMA_RE = re.compile(r"[a-z][a-z0-9]*(?:-[a-z0-9]+)*-v[1-9][0-9]*\Z")
CANONICAL_ID_RE = re.compile(
    r"(?=.{3,128}\Z)[a-z][a-z0-9]*(?:[._:/-][a-z0-9]+)*\Z"
)
PROVENANCE_LABEL_RE = re.compile(r"[a-z][a-z0-9_-]{0,63}\Z")
SOURCE_COMMIT_RE = re.compile(r"(?:[0-9a-f]{40}|[0-9a-f]{64})\Z")
PROVENANCE_ORIGIN_KINDS = frozenset(
    {"graph_input", "graph_output", "graph_node", "constant", "compiler_transient"}
)
SOURCE_PROVENANCE_FIELDS = (
    "schema",
    "manifest_sha256",
    "raw_sha256",
    "graph_ir_schema",
    "graph_ir_sha256",
    "profile",
    "source_commit",
    "graph_scope",
)
NODE_BINDING_FIELDS = (
    "artifact_node_id",
    "canonical_id",
    "manifest_graph_index",
    "source_descriptor_sha256",
    "command_descriptor_sha256",
    "artifact_schedule_position",
    "source_schedule_position",
    "profile_family",
    "profile_id",
)
BUFFER_BINDING_FIELDS = (
    "buffer_id",
    "origin_kind",
    "origin_index",
    "canonical_id",
    "tensor_descriptor_sha256",
    "storage_origin_kind",
    "storage_origin_index",
    "storage_canonical_id",
    "storage_tensor_descriptor_sha256",
    "alias_offset",
    "logical_size",
    "storage_size",
)


class ArtifactError(ValueError):
    """A stable, machine-readable rejection at the artifact trust boundary."""

    def __init__(self, code: str, path: str, detail: str):
        super().__init__(f"{code} at {path}: {detail}")
        self.code = code
        self.path = path
        self.detail = detail


def _fail(code: str, path: str, detail: str) -> None:
    raise ArtifactError(code, path, detail)


def _object(value: Any, path: str, keys: Iterable[str]) -> dict[str, Any]:
    if type(value) is not dict:
        _fail("SCHEMA_TYPE", path, "expected object")
    expected = set(keys)
    actual = set(value)
    if actual != expected:
        _fail(
            "SCHEMA_KEYS",
            path,
            f"missing={sorted(expected - actual)} extra={sorted(actual - expected)}",
        )
    return value


def _array(value: Any, path: str, *, length: int | None = None) -> list[Any]:
    if type(value) is not list:
        _fail("SCHEMA_TYPE", path, "expected array")
    if length is not None and len(value) != length:
        _fail("SCHEMA_LENGTH", path, f"expected {length}, got {len(value)}")
    return value


def _string(value: Any, path: str, *, nonempty: bool = True) -> str:
    if type(value) is not str:
        _fail("SCHEMA_TYPE", path, "expected string")
    if nonempty and not value:
        _fail("SCHEMA_VALUE", path, "must be non-empty")
    if "\x00" in value:
        _fail("SCHEMA_VALUE", path, "NUL is forbidden")
    return value


def _integer(
    value: Any,
    path: str,
    *,
    minimum: int | None = None,
    maximum: int | None = None,
) -> int:
    if type(value) is not int:
        _fail("SCHEMA_TYPE", path, "expected integer")
    if minimum is not None and value < minimum:
        _fail("SCHEMA_RANGE", path, f"must be >= {minimum}")
    if maximum is not None and value > maximum:
        _fail("SCHEMA_RANGE", path, f"must be <= {maximum}")
    return value


def _sha256(value: Any, path: str) -> str:
    text = _string(value, path)
    if LOWER_SHA256_RE.fullmatch(text) is None:
        _fail("SCHEMA_HASH", path, "expected 64 lowercase hexadecimal digits")
    return text


def _canonical_id(value: Any, path: str) -> str:
    text = _string(value, path)
    if CANONICAL_ID_RE.fullmatch(text) is None and LOWER_SHA256_RE.fullmatch(text) is None:
        _fail(
            "PROVENANCE_FORMAT",
            path,
            "expected a lowercase segmented identifier or exact lowercase SHA-256 id",
        )
    return text


def _nullable_canonical_id(value: Any, path: str) -> str | None:
    if value is None:
        return None
    return _canonical_id(value, path)


def _provenance_label(value: Any, path: str) -> str:
    text = _string(value, path)
    if PROVENANCE_LABEL_RE.fullmatch(text) is None:
        _fail(
            "PROVENANCE_FORMAT",
            path,
            "expected a lowercase provenance label",
        )
    return text


def _origin_kind(value: Any, path: str) -> str:
    text = _string(value, path)
    if text not in PROVENANCE_ORIGIN_KINDS:
        _fail(
            "PROVENANCE_FORMAT",
            path,
            f"expected one of {sorted(PROVENANCE_ORIGIN_KINDS)}",
        )
    return text


def _buffer_id(value: Any, path: str) -> str:
    text = _string(value, path)
    if BUFFER_ID_RE.fullmatch(text) is None:
        _fail("BUFFER_ID", path, "expected [A-Za-z][A-Za-z0-9_.-]{0,63}")
    return text


def _power_of_two(value: Any, path: str, *, minimum: int = 1) -> int:
    number = _integer(value, path, minimum=minimum, maximum=1 << 31)
    if number & (number - 1):
        _fail("ALIGNMENT", path, "must be a power of two")
    return number


def _duplicate_checked_object(pairs: list[tuple[str, Any]]) -> dict[str, Any]:
    result: dict[str, Any] = {}
    for key, value in pairs:
        if key in result:
            _fail("DUPLICATE_KEY", "$json", f"duplicate key {key!r}")
        result[key] = value
    return result


def _reject_real(text: str) -> Any:
    _fail("JSON_REAL", "$json", f"real number is forbidden: {text}")


def _reject_constant(text: str) -> Any:
    _fail("JSON_CONSTANT", "$json", f"non-finite number is forbidden: {text}")


def _parse_json(payload: bytes, path: str) -> Any:
    try:
        text = payload.decode("utf-8")
    except UnicodeDecodeError as exc:
        _fail("UTF8", path, str(exc))
    try:
        return json.loads(
            text,
            object_pairs_hook=_duplicate_checked_object,
            parse_float=_reject_real,
            parse_constant=_reject_constant,
        )
    except ArtifactError:
        raise
    except json.JSONDecodeError as exc:
        _fail("JSON", path, str(exc))


def canonical_json_bytes(value: Any) -> bytes:
    """Encode the one accepted metadata representation (UTF-8, no newline)."""

    return json.dumps(
        value,
        ensure_ascii=False,
        sort_keys=True,
        separators=(",", ":"),
        allow_nan=False,
    ).encode("utf-8")


def _digest(payload: bytes) -> str:
    return hashlib.sha256(payload).hexdigest()


def _checked_u64_add(left: int, right: int, path: str) -> int:
    if left > UINT64_MAX - right:
        _fail("WORKLOAD_OVERFLOW", path, "u64 addition overflow")
    return left + right


def _checked_u64_mul(left: int, right: int, path: str) -> int:
    if left != 0 and right > UINT64_MAX // left:
        _fail("WORKLOAD_OVERFLOW", path, "u64 multiplication overflow")
    return left * right


def _checked_cycle_sum(left: int, right: int, path: str) -> int:
    if left > UINT64_MAX - right:
        _fail("CYCLE_UPPER_BOUND_OVERFLOW", path, "command cycle upper-bound sum overflows u64")
    return left + right


def _parse_workload(value: Any, path: str) -> dict[str, Any]:
    workload = _object(value, path, {"schema", *WORKLOAD_FIELDS})
    if _string(workload["schema"], f"{path}.schema") != F32_ALU_WORKLOAD_SCHEMA:
        _fail(
            "WORKLOAD_VERSION",
            f"{path}.schema",
            f"expected {F32_ALU_WORKLOAD_SCHEMA}",
        )
    normalized: dict[str, Any] = {"schema": F32_ALU_WORKLOAD_SCHEMA}
    for field in WORKLOAD_FIELDS:
        normalized[field] = _integer(
            workload[field],
            f"{path}.{field}",
            minimum=0,
            maximum=1 if field == "expected_starts" else UINT64_MAX,
        )

    request_groups = _checked_u64_add(
        normalized["read_groups"], normalized["write_groups"], path
    )
    if normalized["request_groups"] != request_groups:
        _fail(
            "WORKLOAD_LEDGER",
            f"{path}.request_groups",
            "must equal read_groups + write_groups",
        )
    if normalized["response_groups"] != normalized["request_groups"]:
        _fail(
            "WORKLOAD_LEDGER",
            f"{path}.response_groups",
            "must equal request_groups",
        )
    expected_read_bytes = _checked_u64_mul(normalized["input_words"], 4, path)
    if normalized["read_bytes"] != expected_read_bytes:
        _fail(
            "WORKLOAD_LEDGER",
            f"{path}.read_bytes",
            "must equal input_words * 4",
        )
    expected_write_bytes = _checked_u64_mul(normalized["output_words"], 4, path)
    if normalized["write_bytes"] != expected_write_bytes:
        _fail(
            "WORKLOAD_LEDGER",
            f"{path}.write_bytes",
            "must equal output_words * 4",
        )
    if normalized["expected_starts"] == 0 and any(
        normalized[field] != 0 for field in WORKLOAD_FIELDS if field != "expected_starts"
    ):
        _fail(
            "WORKLOAD_ZERO_START",
            path,
            "expected_starts=0 requires every other ledger counter to be zero",
        )
    return normalized


def _identity_from_words(words: Sequence[int]) -> dict[str, int]:
    """Derive the exact completion identity from the final command template."""

    return {
        "kernel_id": words[0] & 0xFFFFFFFF,
        "command_flags": words[0] >> 32,
        "context_id": words[1] & 0xFFFFFFFF,
        "sequence_id": words[2],
        "producer_id": words[3],
        "user_tag": words[4],
        "covered_node_count": words[5] & 0xFFFFFFFF,
        "node_hash_lo": words[6],
        "node_hash_hi": words[7],
        "local_profile": words[9] & 0xFFFFFFFF,
    }


def _validate_descriptor_wire_static(words: Sequence[int], path: str) -> None:
    """Reject descriptor encodings the C++ command ABI cannot decode/execute."""

    if words[8] != 0:
        _fail("DESCRIPTOR_CAPABILITY", f"{path}[8]",
              "current F32 portal requires deadline=0; use metadata cycle_upper_bound")
    if words[18] >> 32:
        _fail("DESCRIPTOR_RESERVED", f"{path}[18]", "high 32 reserved bits must be zero")
    permissions = words[25]
    if permissions >> 8:
        _fail("DESCRIPTOR_RESERVED", f"{path}[25]", "bits 8..63 are reserved")
    if (permissions & 0x3) != 0x3:
        _fail(
            "DESCRIPTOR_VALIDITY",
            f"{path}[25]",
            "abi_valid and windows_generation_valid must both be one",
        )
    src0_permission = (permissions >> 2) & 0x3
    src1_permission = (permissions >> 4) & 0x3
    dst_permission = (permissions >> 6) & 0x3
    if src0_permission != 1 or src1_permission not in {0, 1} or dst_permission != 2:
        _fail(
            "DESCRIPTOR_PERMISSION",
            f"{path}[25]",
            "expected src0=read, src1=none/read, dst=write",
        )
    if src1_permission == 0 and any(words[index] != 0 for index in (11, 26, 27)):
        _fail(
            "DESCRIPTOR_PERMISSION",
            f"{path}[25]",
            "src1 none requires zero address, window base, and window size",
        )


def _parse_identity(value: Any, path: str) -> dict[str, int]:
    identity = _object(value, path, IDENTITY_FIELDS)
    return {
        field: _integer(
            identity[field],
            f"{path}.{field}",
            minimum=0,
            maximum=0xFFFFFFFF if field in IDENTITY_U32_FIELDS else UINT64_MAX,
        )
        for field in IDENTITY_FIELDS
    }


def _align_up(value: int, alignment: int) -> int:
    return (value + alignment - 1) & -alignment


def _record_bytes(words: Sequence[int]) -> bytes:
    if len(words) != COMMAND_RECORD_WORDS:
        _fail(
            "COMMAND_RECORD_WORDS",
            "$command",
            f"expected {COMMAND_RECORD_WORDS}, got {len(words)}",
        )
    checked = [
        _integer(word, f"$command[{index}]", minimum=0, maximum=UINT64_MAX)
        for index, word in enumerate(words)
    ]
    return COMMAND_RECORD.pack(*checked)


def pack_command_file(records: Sequence[Sequence[int]]) -> bytes:
    """Pack immutable 30xu64 command templates into the ABI 1.1 file envelope."""

    if len(records) > 0xFFFFFFFF:
        _fail("COMMAND_COUNT", "$command", "too many command records")
    payload = b"".join(_record_bytes(record) for record in records)
    header = COMMAND_HEADER.pack(
        COMMAND_MAGIC,
        ABI_MAJOR,
        ABI_MINOR,
        COMMAND_HEADER_BYTES,
        COMMAND_RECORD_BYTES,
        len(records),
        0,
        len(payload),
        hashlib.sha256(payload).digest(),
    )
    return header + payload


def unpack_command_file(payload: bytes) -> tuple[tuple[int, ...], ...]:
    """Validate and decode a complete command file, rejecting trailing bytes."""

    if not isinstance(payload, bytes):
        _fail("SCHEMA_TYPE", "$command.bin", "expected bytes")
    if len(payload) < COMMAND_HEADER_BYTES:
        _fail(
            "COMMAND_TRUNCATED",
            "$command.bin",
            f"need {COMMAND_HEADER_BYTES}-byte header, got {len(payload)}",
        )
    (
        magic,
        major,
        minor,
        header_size,
        record_size,
        command_count,
        flags,
        payload_size,
        expected_hash,
    ) = COMMAND_HEADER.unpack_from(payload)
    if magic != COMMAND_MAGIC:
        _fail("COMMAND_MAGIC", "$command.bin.magic", f"got {magic!r}")
    if (major, minor) != (ABI_MAJOR, ABI_MINOR):
        _fail(
            "COMMAND_VERSION",
            "$command.bin.version",
            f"expected {ABI_MAJOR}.{ABI_MINOR}, got {major}.{minor}",
        )
    if header_size != COMMAND_HEADER_BYTES:
        _fail(
            "COMMAND_HEADER_SIZE",
            "$command.bin.header_size",
            f"expected {COMMAND_HEADER_BYTES}, got {header_size}",
        )
    if record_size != COMMAND_RECORD_BYTES:
        _fail(
            "COMMAND_RECORD_SIZE",
            "$command.bin.record_size",
            f"expected {COMMAND_RECORD_BYTES}, got {record_size}",
        )
    if flags != 0:
        _fail("COMMAND_FLAGS", "$command.bin.flags", "reserved flags must be zero")
    expected_payload_size = command_count * COMMAND_RECORD_BYTES
    if payload_size != expected_payload_size:
        _fail(
            "COMMAND_SIZE",
            "$command.bin.payload_size",
            f"expected {expected_payload_size}, got {payload_size}",
        )
    expected_file_size = COMMAND_HEADER_BYTES + payload_size
    if len(payload) != expected_file_size:
        code = "COMMAND_TRUNCATED" if len(payload) < expected_file_size else "COMMAND_TRAILING"
        _fail(code, "$command.bin", f"expected {expected_file_size} bytes, got {len(payload)}")
    body = payload[COMMAND_HEADER_BYTES:]
    actual_hash = hashlib.sha256(body).digest()
    if actual_hash != expected_hash:
        _fail(
            "COMMAND_HASH",
            "$command.bin.payload_sha256",
            f"expected {expected_hash.hex()}, got {actual_hash.hex()}",
        )
    return tuple(
        COMMAND_RECORD.unpack_from(body, index * COMMAND_RECORD_BYTES)
        for index in range(command_count)
    )


@dataclass(frozen=True)
class ArtifactBundle:
    command_bin: bytes
    weights_bin: bytes
    metadata_json: bytes

    def write_to(self, output_dir: str | os.PathLike[str]) -> None:
        """Atomically replace the three bundle files inside ``output_dir``."""

        directory = Path(output_dir)
        directory.mkdir(parents=True, exist_ok=True)
        for name, payload in (
            ("command.bin", self.command_bin),
            ("weights.bin", self.weights_bin),
            ("metadata.json", self.metadata_json),
        ):
            fd, temporary = tempfile.mkstemp(prefix=f".{name}.", dir=directory)
            try:
                with os.fdopen(fd, "wb") as handle:
                    handle.write(payload)
                    handle.flush()
                    os.fsync(handle.fileno())
                os.replace(temporary, directory / name)
            except BaseException:
                try:
                    os.unlink(temporary)
                except FileNotFoundError:
                    pass
                raise


@dataclass(frozen=True)
class LoadedBundle:
    command_bin: bytes
    weights_bin: bytes
    metadata_json: bytes
    metadata: Mapping[str, Any]
    records: tuple[tuple[int, ...], ...]

    def relocate(
        self,
        buffer_bases: Mapping[str, int],
        *,
        weights_base: int | None = None,
    ) -> bytes:
        return apply_relocations(
            self.command_bin,
            self.metadata,
            buffer_bases,
            weights_base=weights_base,
        )


class _WeightImageBuilder:
    def __init__(self, deduplicate: bool):
        self._deduplicate = deduplicate
        self._image = bytearray()
        self._placements: dict[bytes, list[int]] = {}

    def add(self, payload: bytes, alignment: int) -> int:
        if self._deduplicate:
            for offset in self._placements.get(payload, ()):
                if offset % alignment == 0:
                    return offset
        offset = _align_up(len(self._image), alignment)
        self._image.extend(b"\x00" * (offset - len(self._image)))
        self._image.extend(payload)
        self._placements.setdefault(payload, []).append(offset)
        return offset

    def finish(self) -> bytes:
        final_size = _align_up(len(self._image), WEIGHT_ALIGNMENT)
        self._image.extend(b"\x00" * (final_size - len(self._image)))
        return bytes(self._image)


def _node_digest(node_ids: Sequence[int], path: str) -> tuple[bytes, list[int]]:
    checked = [
        _integer(node_id, f"{path}[{index}]", minimum=0, maximum=UINT64_MAX)
        for index, node_id in enumerate(node_ids)
    ]
    if not checked:
        _fail("NODE_LIST", path, "a command must cover at least one node")
    raw = b"".join(struct.pack("<Q", node_id) for node_id in checked)
    return hashlib.sha256(raw).digest(), checked


def _check_permission(buffer: Mapping[str, Any], word: int, path: str) -> None:
    permission = buffer["permissions"]
    if word in SOURCE_WORDS and "r" not in permission:
        _fail("BUFFER_PERMISSION", path, f"word {word} requires a readable buffer")
    if word in DESTINATION_WORDS and "w" not in permission:
        _fail("BUFFER_PERMISSION", path, f"word {word} requires a writable buffer")


def _parse_graph_buffers(
    raw_buffers: Any,
    *,
    deduplicate_weights: bool,
) -> tuple[list[dict[str, Any]], bytes, dict[str, dict[str, Any]]]:
    buffers = _array(raw_buffers, "$graph.buffers")
    by_id: dict[str, dict[str, Any]] = {}
    weight_payloads: dict[str, bytes] = {}
    for index, raw in enumerate(buffers):
        path = f"$graph.buffers[{index}]"
        if type(raw) is not dict:
            _fail("SCHEMA_TYPE", path, "expected object")
        kind = _string(raw.get("kind"), f"{path}.kind")
        if kind == "weight":
            item = _object(raw, path, {"id", "kind", "alignment", "permissions", "data_hex"})
        else:
            item = _object(raw, path, {"id", "kind", "size", "alignment", "permissions"})
            if kind not in {"input", "output", "scratch", "transient"}:
                _fail("BUFFER_KIND", f"{path}.kind", f"unknown kind {kind!r}")
        identifier = _buffer_id(item["id"], f"{path}.id")
        if identifier in by_id:
            _fail("BUFFER_DUPLICATE", f"{path}.id", identifier)
        alignment = _power_of_two(item["alignment"], f"{path}.alignment", minimum=WEIGHT_ALIGNMENT)
        permission = _string(item["permissions"], f"{path}.permissions")
        if permission not in {"r", "w", "rw"}:
            _fail("BUFFER_PERMISSION", f"{path}.permissions", "expected r, w, or rw")
        if kind == "output" and permission != "w":
            _fail(
                "BUFFER_PERMISSION",
                f"{path}.permissions",
                "output buffers must be write-only publication targets",
            )
        if kind == "weight":
            if permission != "r":
                _fail("BUFFER_PERMISSION", f"{path}.permissions", "weights must be read-only")
            data_hex = _string(item["data_hex"], f"{path}.data_hex", nonempty=False)
            if len(data_hex) % 2 or re.fullmatch(r"[0-9a-f]*", data_hex) is None:
                _fail("WEIGHT_HEX", f"{path}.data_hex", "expected lowercase even-width hexadecimal")
            data = bytes.fromhex(data_hex)
            if not data:
                _fail("BUFFER_SIZE", f"{path}.data_hex", "weight payload must be non-empty")
            weight_payloads[identifier] = data
            normalized = {
                "alignment": alignment,
                "id": identifier,
                "kind": kind,
                "permissions": permission,
                "size": len(data),
            }
        else:
            size = _integer(item["size"], f"{path}.size", minimum=1, maximum=UINT64_MAX)
            normalized = {
                "alignment": alignment,
                "id": identifier,
                "kind": kind,
                "permissions": permission,
                "size": size,
            }
        by_id[identifier] = normalized

    builder = _WeightImageBuilder(deduplicate_weights)
    metadata_buffers: list[dict[str, Any]] = []
    for identifier in sorted(by_id):
        normalized = dict(by_id[identifier])
        if normalized["kind"] == "weight":
            data = weight_payloads[identifier]
            normalized["weights_offset"] = builder.add(data, normalized["alignment"])
            normalized["sha256"] = _digest(data)
        metadata_buffers.append(normalized)
    weights = builder.finish()
    normalized_by_id = {item["id"]: item for item in metadata_buffers}
    return metadata_buffers, weights, normalized_by_id


def _parse_publications(
    raw_publications: Any,
    buffers: Mapping[str, Mapping[str, Any]],
    path: str,
) -> list[dict[str, Any]]:
    publications = _array(raw_publications, path)
    normalized: list[dict[str, Any]] = []
    previous_key: tuple[str, int, int, int] | None = None
    by_buffer: dict[str, list[dict[str, Any]]] = {}
    for index, raw in enumerate(publications):
        entry_path = f"{path}[{index}]"
        entry = _object(
            raw,
            entry_path,
            {"buffer_id", "source_offset", "target_offset", "bytes"},
        )
        identifier = _buffer_id(entry["buffer_id"], f"{entry_path}.buffer_id")
        if identifier not in buffers:
            _fail("PUBLICATION_BUFFER", f"{entry_path}.buffer_id", identifier)
        buffer = buffers[identifier]
        if buffer["kind"] != "output" or buffer["permissions"] != "w":
            _fail(
                "PUBLICATION_BUFFER",
                f"{entry_path}.buffer_id",
                "publication entries require a write-only output buffer",
            )
        source_offset = _integer(
            entry["source_offset"],
            f"{entry_path}.source_offset",
            minimum=0,
            maximum=UINT64_MAX,
        )
        target_offset = _integer(
            entry["target_offset"],
            f"{entry_path}.target_offset",
            minimum=0,
            maximum=UINT64_MAX,
        )
        byte_count = _integer(
            entry["bytes"],
            f"{entry_path}.bytes",
            minimum=1,
            maximum=UINT64_MAX,
        )
        size = buffer["size"]
        if (
            source_offset > size
            or byte_count > size - source_offset
            or target_offset > size
            or byte_count > size - target_offset
        ):
            _fail(
                "PUBLICATION_RANGE",
                entry_path,
                f"source/target range must fit output {identifier!r} ({size} bytes)",
            )
        item = {
            "buffer_id": identifier,
            "bytes": byte_count,
            "source_offset": source_offset,
            "target_offset": target_offset,
        }
        key = (identifier, target_offset, source_offset, byte_count)
        if previous_key is not None and key <= previous_key:
            _fail(
                "PUBLICATION_ORDER",
                entry_path,
                "entries must be strictly sorted by buffer_id, target_offset, source_offset, bytes",
            )
        previous_key = key
        normalized.append(item)
        by_buffer.setdefault(identifier, []).append(item)

    output_ids = sorted(
        identifier for identifier, buffer in buffers.items() if buffer["kind"] == "output"
    )
    if set(by_buffer) != set(output_ids):
        missing = sorted(set(output_ids) - set(by_buffer))
        _fail(
            "PUBLICATION_COVERAGE",
            path,
            f"every output must be published exactly once; missing={missing}",
        )
    for identifier in output_ids:
        size = buffers[identifier]["size"]
        entries = by_buffer[identifier]
        for axis in ("source_offset", "target_offset"):
            cursor = 0
            for entry in sorted(entries, key=lambda item: (item[axis], item["bytes"])):
                start = entry[axis]
                if start < cursor:
                    _fail(
                        "PUBLICATION_OVERLAP",
                        path,
                        f"{identifier!r} {axis} range overlaps before byte {cursor}",
                    )
                if start > cursor:
                    _fail(
                        "PUBLICATION_GAP",
                        path,
                        f"{identifier!r} {axis} has gap [{cursor}, {start})",
                    )
                cursor = start + entry["bytes"]
            if cursor != size:
                _fail(
                    "PUBLICATION_COVERAGE",
                    path,
                    f"{identifier!r} {axis} covers {cursor} of {size} bytes",
                )
    return normalized


def _parse_graph_commands(
    raw_commands: Any,
    buffers: Mapping[str, Mapping[str, Any]],
) -> tuple[list[tuple[int, ...]], list[dict[str, Any]], list[dict[str, Any]]]:
    commands = _array(raw_commands, "$graph.commands")
    if not commands:
        _fail("COMMAND_COUNT", "$graph.commands", "at least one command is required")
    records: list[tuple[int, ...]] = []
    metadata_commands: list[dict[str, Any]] = []
    metadata_relocations: list[dict[str, Any]] = []
    names: set[str] = set()
    total_cycle_upper_bound = 0
    for command_index, raw in enumerate(commands):
        path = f"$graph.commands[{command_index}]"
        command = _object(
            raw,
            path,
            {
                "name",
                "node_ids",
                "owner",
                "workload",
                "cycle_upper_bound",
                "descriptor_words",
                "relocations",
            },
        )
        name = _string(command["name"], f"{path}.name")
        if name in names:
            _fail("COMMAND_DUPLICATE", f"{path}.name", name)
        names.add(name)
        raw_words = _array(
            command["descriptor_words"],
            f"{path}.descriptor_words",
            length=COMMAND_RECORD_WORDS,
        )
        words = [
            _integer(word, f"{path}.descriptor_words[{index}]", minimum=0, maximum=UINT64_MAX)
            for index, word in enumerate(raw_words)
        ]
        _validate_descriptor_wire_static(words, f"{path}.descriptor_words")
        owner = _string(command["owner"], f"{path}.owner")
        if owner != F32_ALU_OWNER:
            _fail("COMMAND_OWNER", f"{path}.owner", f"unsupported owner {owner!r}")
        kernel_id = words[0] & 0xFFFFFFFF
        if kernel_id != F32_ALU_KERNEL_ID:
            _fail(
                "OWNER_KERNEL",
                f"{path}.descriptor_words[0]",
                f"owner {owner!r} requires kernel 0x{F32_ALU_KERNEL_ID:08x}",
            )
        workload = _parse_workload(command["workload"], f"{path}.workload")
        cycle_upper_bound = _integer(
            command["cycle_upper_bound"],
            f"{path}.cycle_upper_bound",
            minimum=1,
            maximum=UINT64_MAX,
        )
        total_cycle_upper_bound = _checked_cycle_sum(
            total_cycle_upper_bound, cycle_upper_bound, f"{path}.cycle_upper_bound"
        )
        if words[14] != 0 or words[17] >> 32 != 0:
            _fail(
                "SCRATCH_UNSUPPORTED",
                path,
                "ABI 1.1 has no scratch window; word 14 and scratch_bytes must be zero",
            )
        node_digest, node_ids = _node_digest(
            _array(command["node_ids"], f"{path}.node_ids"),
            f"{path}.node_ids",
        )
        if len(node_ids) > 0xFFFFFFFF:
            _fail("NODE_LIST", f"{path}.node_ids", "too many nodes")
        words[5] = (words[5] & 0xFFFFFFFF00000000) | len(node_ids)
        words[6] = int.from_bytes(node_digest[0:8], "little")
        words[7] = int.from_bytes(node_digest[8:16], "little")

        relocations = _array(command["relocations"], f"{path}.relocations")
        command_relocations: dict[int, dict[str, Any]] = {}
        for relocation_index, raw_relocation in enumerate(relocations):
            relocation_path = f"{path}.relocations[{relocation_index}]"
            relocation = _object(
                raw_relocation,
                relocation_path,
                {"word_index", "kind", "buffer_id", "addend"},
            )
            word_index = _integer(
                relocation["word_index"],
                f"{relocation_path}.word_index",
                minimum=0,
                maximum=COMMAND_RECORD_WORDS - 1,
            )
            kind = _string(relocation["kind"], f"{relocation_path}.kind")
            expected_kind = RELOCATION_KIND_FOR_WORD.get(word_index)
            if expected_kind is None or kind != expected_kind:
                _fail(
                    "RELOCATION_KIND",
                    relocation_path,
                    f"word {word_index} requires {expected_kind!r}, got {kind!r}",
                )
            if word_index in command_relocations:
                _fail("RELOCATION_DUPLICATE", relocation_path, f"word {word_index}")
            identifier = _buffer_id(relocation["buffer_id"], f"{relocation_path}.buffer_id")
            if identifier not in buffers:
                _fail("UNKNOWN_BUFFER", f"{relocation_path}.buffer_id", identifier)
            buffer = buffers[identifier]
            _check_permission(buffer, word_index, relocation_path)
            addend = _integer(
                relocation["addend"],
                f"{relocation_path}.addend",
                minimum=0,
                maximum=UINT64_MAX,
            )
            if addend >= buffer["size"]:
                _fail(
                    "RELOCATION_RANGE",
                    f"{relocation_path}.addend",
                    f"{addend} is outside {identifier!r} ({buffer['size']} bytes)",
                )
            if words[word_index] not in {0, addend}:
                _fail(
                    "RELOCATION_TEMPLATE",
                    f"{path}.descriptor_words[{word_index}]",
                    "address word must be zero or equal its relocation addend",
                )
            words[word_index] = addend
            normalized = {
                "addend": addend,
                "buffer_id": identifier,
                "command_index": command_index,
                "kind": kind,
                "word_index": word_index,
            }
            command_relocations[word_index] = normalized
            metadata_relocations.append(normalized)

        for iova_word, window_word in WINDOW_ADDRESS_PAIRS:
            iova = command_relocations.get(iova_word)
            window = command_relocations.get(window_word)
            if (iova is None) != (window is None):
                _fail(
                    "RELOCATION_PAIR_MISSING",
                    path,
                    f"words {iova_word}/{window_word} must be relocated together",
                )
            if iova is not None and iova["buffer_id"] != window["buffer_id"]:
                _fail(
                    "WINDOW_BUFFER_MISMATCH",
                    path,
                    f"words {iova_word}/{window_word} reference different buffers",
                )
            if iova is None and (words[iova_word] != 0 or words[window_word] != 0):
                _fail(
                    "RELOCATION_PAIR_MISSING",
                    path,
                    f"non-zero words {iova_word}/{window_word} require relocations",
                )
            if window is not None:
                declared_size = words[window_word + 1]
                available = buffers[window["buffer_id"]]["size"] - window["addend"]
                if declared_size == 0 or declared_size > available:
                    _fail(
                        "WINDOW_RANGE",
                        f"{path}.descriptor_words[{window_word + 1}]",
                        f"declared {declared_size} bytes, available {available}",
                    )
        src2 = command_relocations.get(12)
        declared_window_buffers = {
            command_relocations[word]["buffer_id"]
            for word in (10, 11, 13)
            if word in command_relocations
        }
        if src2 is not None and src2["buffer_id"] not in declared_window_buffers:
            _fail(
                "SRC2_NOT_WINDOW_ALIAS",
                path,
                "word 12 must alias a relocated src0/src1/dst window",
            )
        if src2 is not None:
            aliases_window = False
            for primary_word, window_word in WINDOW_ADDRESS_PAIRS:
                primary = command_relocations.get(primary_word)
                window = command_relocations.get(window_word)
                if primary is None or primary["buffer_id"] != src2["buffer_id"]:
                    continue
                window_start = window["addend"]
                window_size = words[window_word + 1]
                if window_start <= src2["addend"] and src2["addend"] - window_start < window_size:
                    aliases_window = True
                    break
            if not aliases_window:
                _fail(
                    "SRC2_NOT_WINDOW_ALIAS",
                    path,
                    "word 12 addend is outside every declared window for its buffer",
                )
        if src2 is None and words[12] != 0:
            _fail("RELOCATION_PAIR_MISSING", path, "non-zero word 12 requires relocation")

        record = tuple(words)
        records.append(record)
        metadata_commands.append(
            {
                "cycle_upper_bound": cycle_upper_bound,
                "descriptor_sha256": _digest(_record_bytes(record)),
                "identity": _identity_from_words(record),
                "index": command_index,
                "name": name,
                "node_ids": node_ids,
                "node_sha256": node_digest.hex(),
                "owner": owner,
                "workload": workload,
            }
        )

    metadata_relocations.sort(key=lambda item: (item["command_index"], item["word_index"]))
    return records, metadata_commands, metadata_relocations


def _parse_provenance(
    value: Any,
    buffers: Mapping[str, Mapping[str, Any]],
    commands: Sequence[Mapping[str, Any]],
    path: str,
    *,
    require_sorted: bool,
) -> dict[str, Any]:
    """Validate canonical graph-to-artifact provenance and exact coverage.

    Buffer provenance names both the logical tensor and its already-normalized
    storage root.  A view therefore remains one artifact capability: the
    binding's ``storage_size`` equals the artifact buffer size, while
    ``alias_offset`` and ``logical_size`` bound the logical subrange.
    """

    provenance = _object(value, path, {"source", "node_bindings", "buffer_bindings"})
    raw_source = _object(
        provenance["source"], f"{path}.source", SOURCE_PROVENANCE_FIELDS
    )
    source_schema = _string(raw_source["schema"], f"{path}.source.schema")
    if len(source_schema) > 128 or SOURCE_SCHEMA_RE.fullmatch(source_schema) is None:
        _fail(
            "PROVENANCE_FORMAT",
            f"{path}.source.schema",
            "expected lowercase hyphenated schema ending in -vN",
        )
    source_commit = raw_source["source_commit"]
    if source_commit is not None:
        source_commit = _string(source_commit, f"{path}.source.source_commit")
        if SOURCE_COMMIT_RE.fullmatch(source_commit) is None:
            _fail(
                "PROVENANCE_FORMAT",
                f"{path}.source.source_commit",
                "expected null or a 40/64 digit lowercase hexadecimal commit",
            )
    source = {
        "graph_ir_schema": _string(
            raw_source["graph_ir_schema"], f"{path}.source.graph_ir_schema"
        ),
        "graph_ir_sha256": _sha256(
            raw_source["graph_ir_sha256"], f"{path}.source.graph_ir_sha256"
        ),
        "graph_scope": _canonical_id(
            raw_source["graph_scope"], f"{path}.source.graph_scope"
        ),
        "manifest_sha256": _sha256(
            raw_source["manifest_sha256"], f"{path}.source.manifest_sha256"
        ),
        "profile": _canonical_id(raw_source["profile"], f"{path}.source.profile"),
        "raw_sha256": _sha256(
            raw_source["raw_sha256"], f"{path}.source.raw_sha256"
        ),
        "schema": source_schema,
        "source_commit": source_commit,
    }
    if (
        len(source["graph_ir_schema"]) > 128
        or SOURCE_SCHEMA_RE.fullmatch(source["graph_ir_schema"]) is None
    ):
        _fail(
            "PROVENANCE_FORMAT",
            f"{path}.source.graph_ir_schema",
            "expected lowercase hyphenated schema ending in -vN",
        )

    flattened_nodes: list[int] = []
    command_for_node: dict[int, Mapping[str, Any]] = {}
    for command_index, command in enumerate(commands):
        for node_index, raw_node_id in enumerate(command["node_ids"]):
            node_id = _integer(
                raw_node_id,
                f"{path}.command_nodes[{command_index}][{node_index}]",
                minimum=0,
                maximum=UINT64_MAX,
            )
            if node_id in command_for_node:
                _fail(
                    "PROVENANCE_NODE_DUPLICATE",
                    f"{path}.command_nodes[{command_index}][{node_index}]",
                    f"artifact node id {node_id} appears in more than one command position",
                )
            command_for_node[node_id] = command
            flattened_nodes.append(node_id)

    raw_node_bindings = _array(provenance["node_bindings"], f"{path}.node_bindings")
    node_bindings: list[dict[str, Any]] = []
    artifact_node_ids: set[int] = set()
    canonical_node_ids: set[str] = set()
    manifest_graph_indices: set[int] = set()
    artifact_schedule_positions: set[int] = set()
    source_schedule_positions: set[int] = set()
    for index, raw in enumerate(raw_node_bindings):
        binding_path = f"{path}.node_bindings[{index}]"
        binding = _object(raw, binding_path, NODE_BINDING_FIELDS)
        artifact_node_id = _integer(
            binding["artifact_node_id"],
            f"{binding_path}.artifact_node_id",
            minimum=0,
            maximum=UINT64_MAX,
        )
        canonical_id = _canonical_id(
            binding["canonical_id"], f"{binding_path}.canonical_id"
        )
        manifest_graph_index = _integer(
            binding["manifest_graph_index"],
            f"{binding_path}.manifest_graph_index",
            minimum=0,
            maximum=UINT64_MAX,
        )
        artifact_schedule_position = _integer(
            binding["artifact_schedule_position"],
            f"{binding_path}.artifact_schedule_position",
            minimum=0,
            maximum=UINT64_MAX,
        )
        source_schedule_position = _integer(
            binding["source_schedule_position"],
            f"{binding_path}.source_schedule_position",
            minimum=0,
            maximum=UINT64_MAX,
        )
        for seen, key, item in (
            (artifact_node_ids, "artifact_node_id", artifact_node_id),
            (canonical_node_ids, "canonical_id", canonical_id),
            (manifest_graph_indices, "manifest_graph_index", manifest_graph_index),
            (
                artifact_schedule_positions,
                "artifact_schedule_position",
                artifact_schedule_position,
            ),
            (
                source_schedule_positions,
                "source_schedule_position",
                source_schedule_position,
            ),
        ):
            if item in seen:
                _fail(
                    "PROVENANCE_NODE_DUPLICATE",
                    f"{binding_path}.{key}",
                    f"duplicate {key} {item!r}",
                )
            seen.add(item)
        node_bindings.append(
            {
                "artifact_node_id": artifact_node_id,
                "artifact_schedule_position": artifact_schedule_position,
                "canonical_id": canonical_id,
                "command_descriptor_sha256": _sha256(
                    binding["command_descriptor_sha256"],
                    f"{binding_path}.command_descriptor_sha256",
                ),
                "manifest_graph_index": manifest_graph_index,
                "profile_family": _provenance_label(
                    binding["profile_family"], f"{binding_path}.profile_family"
                ),
                "profile_id": _provenance_label(
                    binding["profile_id"], f"{binding_path}.profile_id"
                ),
                "source_descriptor_sha256": _sha256(
                    binding["source_descriptor_sha256"],
                    f"{binding_path}.source_descriptor_sha256",
                ),
                "source_schedule_position": source_schedule_position,
            }
        )

    sorted_node_bindings = sorted(
        node_bindings, key=lambda binding: binding["artifact_schedule_position"]
    )
    if require_sorted and node_bindings != sorted_node_bindings:
        _fail(
            "PROVENANCE_NODE_ORDER",
            f"{path}.node_bindings",
            "bindings must be strictly sorted by artifact_schedule_position",
        )
    node_bindings = sorted_node_bindings
    if artifact_node_ids != set(flattened_nodes) or len(node_bindings) != len(flattened_nodes):
        missing = sorted(set(flattened_nodes) - artifact_node_ids)
        extra = sorted(artifact_node_ids - set(flattened_nodes))
        _fail(
            "PROVENANCE_NODE_COVERAGE",
            f"{path}.node_bindings",
            f"bindings must exactly cover command node_ids; missing={missing} extra={extra}",
        )
    for position, (binding, expected_node_id) in enumerate(
        zip(node_bindings, flattened_nodes)
    ):
        if binding["artifact_schedule_position"] != position:
            _fail(
                "PROVENANCE_NODE_ORDER",
                f"{path}.node_bindings[{position}].artifact_schedule_position",
                f"expected contiguous artifact schedule position {position}",
            )
        if binding["artifact_node_id"] != expected_node_id:
            _fail(
                "PROVENANCE_NODE_ORDER",
                f"{path}.node_bindings[{position}].artifact_node_id",
                f"expected scheduled command node {expected_node_id}",
            )
        expected_descriptor = command_for_node[expected_node_id]["descriptor_sha256"]
        if binding["command_descriptor_sha256"] != expected_descriptor:
            _fail(
                "PROVENANCE_NODE_DESCRIPTOR",
                f"{path}.node_bindings[{position}].command_descriptor_sha256",
                "does not match the immutable descriptor covering this node",
            )

    raw_buffer_bindings = _array(
        provenance["buffer_bindings"], f"{path}.buffer_bindings"
    )
    buffer_bindings: list[dict[str, Any]] = []
    buffer_ids: set[str] = set()
    logical_canonical_ids: set[str] = set()
    for index, raw in enumerate(raw_buffer_bindings):
        binding_path = f"{path}.buffer_bindings[{index}]"
        binding = _object(raw, binding_path, BUFFER_BINDING_FIELDS)
        buffer_id = _buffer_id(binding["buffer_id"], f"{binding_path}.buffer_id")
        if buffer_id in buffer_ids:
            _fail(
                "PROVENANCE_BUFFER_DUPLICATE",
                f"{binding_path}.buffer_id",
                f"duplicate buffer binding {buffer_id!r}",
            )
        buffer_ids.add(buffer_id)
        canonical_id = _nullable_canonical_id(
            binding["canonical_id"], f"{binding_path}.canonical_id"
        )
        if canonical_id is not None:
            if canonical_id in logical_canonical_ids:
                _fail(
                    "PROVENANCE_BUFFER_DUPLICATE",
                    f"{binding_path}.canonical_id",
                    f"duplicate logical canonical id {canonical_id!r}",
                )
            logical_canonical_ids.add(canonical_id)
        storage_canonical_id = _nullable_canonical_id(
            binding["storage_canonical_id"],
            f"{binding_path}.storage_canonical_id",
        )
        alias_offset = _integer(
            binding["alias_offset"],
            f"{binding_path}.alias_offset",
            minimum=0,
            maximum=UINT64_MAX,
        )
        logical_size = _integer(
            binding["logical_size"],
            f"{binding_path}.logical_size",
            minimum=1,
            maximum=UINT64_MAX,
        )
        storage_size = _integer(
            binding["storage_size"],
            f"{binding_path}.storage_size",
            minimum=1,
            maximum=UINT64_MAX,
        )
        if alias_offset >= storage_size or logical_size > storage_size - alias_offset:
            _fail(
                "PROVENANCE_BUFFER_RANGE",
                binding_path,
                "logical [alias_offset, alias_offset + logical_size) must fit storage_size",
            )
        if buffer_id not in buffers:
            # Defer the complete missing/extra report until after every row is parsed.
            expected_storage_size = None
        else:
            expected_storage_size = buffers[buffer_id]["size"]
            if storage_size != expected_storage_size:
                _fail(
                    "PROVENANCE_BUFFER_RANGE",
                    f"{binding_path}.storage_size",
                    f"must equal artifact buffer size {expected_storage_size}",
                )
        origin = (
            _origin_kind(binding["origin_kind"], f"{binding_path}.origin_kind"),
            _integer(
                binding["origin_index"],
                f"{binding_path}.origin_index",
                minimum=0,
                maximum=UINT64_MAX,
            ),
            canonical_id,
            _sha256(
                binding["tensor_descriptor_sha256"],
                f"{binding_path}.tensor_descriptor_sha256",
            ),
        )
        storage_origin = (
            _origin_kind(
                binding["storage_origin_kind"],
                f"{binding_path}.storage_origin_kind",
            ),
            _integer(
                binding["storage_origin_index"],
                f"{binding_path}.storage_origin_index",
                minimum=0,
                maximum=UINT64_MAX,
            ),
            storage_canonical_id,
            _sha256(
                binding["storage_tensor_descriptor_sha256"],
                f"{binding_path}.storage_tensor_descriptor_sha256",
            ),
        )
        if origin == storage_origin and (alias_offset != 0 or logical_size != storage_size):
            _fail(
                "PROVENANCE_BUFFER_RANGE",
                binding_path,
                "a non-view binding requires alias_offset=0 and logical_size=storage_size",
            )
        buffer_bindings.append(
            {
                "alias_offset": alias_offset,
                "buffer_id": buffer_id,
                "canonical_id": canonical_id,
                "logical_size": logical_size,
                "origin_index": origin[1],
                "origin_kind": origin[0],
                "storage_canonical_id": storage_canonical_id,
                "storage_origin_index": storage_origin[1],
                "storage_origin_kind": storage_origin[0],
                "storage_size": storage_size,
                "storage_tensor_descriptor_sha256": storage_origin[3],
                "tensor_descriptor_sha256": origin[3],
            }
        )

    sorted_buffer_bindings = sorted(
        buffer_bindings, key=lambda binding: binding["buffer_id"]
    )
    if require_sorted and buffer_bindings != sorted_buffer_bindings:
        _fail(
            "PROVENANCE_BUFFER_ORDER",
            f"{path}.buffer_bindings",
            "bindings must be strictly sorted by BufferId",
        )
    buffer_bindings = sorted_buffer_bindings
    expected_buffer_ids = set(buffers)
    if buffer_ids != expected_buffer_ids or len(buffer_bindings) != len(expected_buffer_ids):
        missing = sorted(expected_buffer_ids - buffer_ids)
        extra = sorted(buffer_ids - expected_buffer_ids)
        _fail(
            "PROVENANCE_BUFFER_COVERAGE",
            f"{path}.buffer_bindings",
            f"bindings must exactly cover artifact buffers; missing={missing} extra={extra}",
        )
    return {
        "buffer_bindings": buffer_bindings,
        "node_bindings": node_bindings,
        "source": source,
    }


def _metadata_with_bundle_id(core: Mapping[str, Any]) -> dict[str, Any]:
    metadata = dict(core)
    metadata["bundle_id"] = _digest(canonical_json_bytes(core))
    return metadata


def _validate_output_producers(
    buffers: Mapping[str, Mapping[str, Any]],
    relocations: Sequence[Mapping[str, Any]],
    publications: Sequence[Mapping[str, Any]],
    records: Sequence[Sequence[int]],
    path: str,
) -> None:
    """Prove every published source byte belongs to a valid destination window."""

    by_command: dict[int, dict[int, Mapping[str, Any]]] = {}
    for relocation in relocations:
        by_command.setdefault(relocation["command_index"], {})[relocation["word_index"]] = relocation
    produced: dict[str, list[tuple[int, int]]] = {}
    for command_index, command_relocations in by_command.items():
        dst = command_relocations.get(13)
        window = command_relocations.get(28)
        if dst is not None and window is not None and dst["buffer_id"] == window["buffer_id"]:
            identifier = dst["buffer_id"]
            lo = window["addend"]
            size = records[command_index][29]
            if size == 0 or lo > UINT64_MAX - size:
                _fail("PUBLICATION_PRODUCER_RANGE", path, "destination window range is invalid")
            hi = lo + size
            if hi > buffers[identifier]["size"] or not (lo <= dst["addend"] < hi):
                _fail(
                    "PUBLICATION_PRODUCER_RANGE",
                    path,
                    f"destination window for {identifier!r} is outside its buffer or excludes dst",
                )
            produced.setdefault(identifier, []).append((lo, hi))
    for identifier, buffer in buffers.items():
        if buffer["kind"] == "output" and identifier not in produced:
            _fail(
                "PUBLICATION_NO_PRODUCER",
                path,
                f"output buffer {identifier!r} has no paired word 13/28 destination relocation",
            )
    merged: dict[str, list[tuple[int, int]]] = {}
    for identifier, ranges in produced.items():
        for lo, hi in sorted(ranges):
            if merged.setdefault(identifier, []) and lo <= merged[identifier][-1][1]:
                previous_lo, previous_hi = merged[identifier][-1]
                merged[identifier][-1] = (previous_lo, max(previous_hi, hi))
            else:
                merged[identifier].append((lo, hi))
    for index, publication in enumerate(publications):
        lo = publication["source_offset"]
        hi = lo + publication["bytes"]
        cursor = lo
        for range_lo, range_hi in merged.get(publication["buffer_id"], []):
            if range_hi <= cursor:
                continue
            if range_lo > cursor:
                break
            cursor = min(hi, max(cursor, range_hi))
            if cursor == hi:
                break
        if cursor != hi:
            _fail(
                "PUBLICATION_UNWRITTEN_SOURCE",
                f"{path}.publications[{index}]",
                f"source range [{lo}, {hi}) contains unwritten bytes starting at {cursor}",
            )


def _validate_transient_dataflow(
    buffers: Mapping[str, Mapping[str, Any]],
    relocations: Sequence[Mapping[str, Any]],
    records: Sequence[Sequence[int]],
    path: str,
) -> None:
    """Prove transient reads are initialized by strictly earlier commands."""

    by_command: dict[int, dict[int, Mapping[str, Any]]] = {}
    for relocation in relocations:
        by_command.setdefault(relocation["command_index"], {})[relocation["word_index"]] = relocation
    written: dict[str, list[tuple[int, int]]] = {}

    def window_interval(
        command_index: int,
        command_relocations: Mapping[int, Mapping[str, Any]],
        iova_word: int,
        window_word: int,
    ) -> tuple[str, int, int] | None:
        iova = command_relocations.get(iova_word)
        window = command_relocations.get(window_word)
        if iova is None or window is None:
            return None
        identifier = iova["buffer_id"]
        if identifier != window["buffer_id"]:
            return None
        lo = window["addend"]
        size = records[command_index][window_word + 1]
        if size == 0 or lo > UINT64_MAX - size:
            _fail("DATAFLOW_WINDOW_RANGE", path, "window range is empty or overflows u64")
        hi = lo + size
        if hi > buffers[identifier]["size"] or not (lo <= iova["addend"] < hi):
            _fail(
                "DATAFLOW_WINDOW_RANGE",
                path,
                f"window for {identifier!r} is outside its buffer or excludes its IOVA",
            )
        return identifier, lo, hi

    def add_written(identifier: str, lo: int, hi: int) -> None:
        ranges = written.setdefault(identifier, [])
        ranges.append((lo, hi))
        merged: list[tuple[int, int]] = []
        for range_lo, range_hi in sorted(ranges):
            if merged and range_lo <= merged[-1][1]:
                merged[-1] = (merged[-1][0], max(merged[-1][1], range_hi))
            else:
                merged.append((range_lo, range_hi))
        written[identifier] = merged

    def require_written(identifier: str, lo: int, hi: int, command_index: int) -> None:
        if buffers[identifier]["kind"] != "transient":
            return
        cursor = lo
        for range_lo, range_hi in written.get(identifier, []):
            if range_hi <= cursor:
                continue
            if range_lo > cursor:
                break
            cursor = min(hi, max(cursor, range_hi))
            if cursor == hi:
                return
        _fail(
            "TRANSIENT_READ_BEFORE_WRITE",
            f"{path}.commands[{command_index}]",
            f"transient {identifier!r} read [{lo}, {hi}) is unwritten from byte {cursor}",
        )

    for command_index in range(len(records)):
        command_relocations = by_command.get(command_index, {})
        windows = {
            pair: window_interval(command_index, command_relocations, *pair)
            for pair in WINDOW_ADDRESS_PAIRS
        }
        reads = [windows[(10, 23)], windows[(11, 26)]]
        src2 = command_relocations.get(12)
        if src2 is not None:
            aliases = [
                interval
                for interval in windows.values()
                if interval is not None
                and interval[0] == src2["buffer_id"]
                and interval[1] <= src2["addend"] < interval[2]
            ]
            if not aliases:
                _fail("SRC2_NOT_WINDOW_ALIAS", f"{path}.commands[{command_index}]", "invalid src2 alias")
            reads.extend(aliases)
        for interval in reads:
            if interval is not None:
                require_written(*interval, command_index)
        destination = windows[(13, 28)]
        if destination is not None and buffers[destination[0]]["kind"] == "transient":
            add_written(*destination)


def compile_graph(
    graph: Mapping[str, Any],
    *,
    deduplicate_weights: bool = True,
) -> ArtifactBundle:
    """Lower a validated low-level graph IR to the immutable v3 bundle."""

    root = _object(
        graph,
        "$graph",
        {"schema", "name", "buffers", "commands", "publications", "provenance"},
    )
    if _string(root["schema"], "$graph.schema") != GRAPH_SCHEMA:
        _fail("GRAPH_VERSION", "$graph.schema", f"expected {GRAPH_SCHEMA}")
    graph_name = _string(root["name"], "$graph.name")
    buffers, weights_bin, by_id = _parse_graph_buffers(
        root["buffers"], deduplicate_weights=deduplicate_weights
    )
    publications = _parse_publications(root["publications"], by_id, "$graph.publications")
    records, commands, relocations = _parse_graph_commands(root["commands"], by_id)
    _validate_transient_dataflow(by_id, relocations, records, "$graph")
    _validate_output_producers(by_id, relocations, publications, records, "$graph.commands")
    provenance = _parse_provenance(
        root["provenance"], by_id, commands, "$graph.provenance", require_sorted=False
    )
    command_bin = pack_command_file(records)
    core = {
        "abi": {
            "command_header_bytes": COMMAND_HEADER_BYTES,
            "command_record_words": COMMAND_RECORD_WORDS,
            "endianness": "little",
            "major": ABI_MAJOR,
            "minor": ABI_MINOR,
            "weight_alignment": WEIGHT_ALIGNMENT,
        },
        "artifacts": {
            "command.bin": {"bytes": len(command_bin), "sha256": _digest(command_bin)},
            "weights.bin": {"bytes": len(weights_bin), "sha256": _digest(weights_bin)},
        },
        "buffers": buffers,
        "commands": commands,
        "graph": {"name": graph_name, "source_schema": GRAPH_SCHEMA},
        "publication": {"entries": publications, "mode": PUBLICATION_MODE},
        "provenance": provenance,
        "relocations": relocations,
        "runtime": {
            "service_abi": {"major": SERVICE_ABI_MAJOR, "minor": SERVICE_ABI_MINOR}
        },
        "schema": METADATA_SCHEMA,
    }
    return ArtifactBundle(command_bin, weights_bin, canonical_json_bytes(_metadata_with_bundle_id(core)))


def compile_graph_json(
    graph_json: bytes,
    *,
    deduplicate_weights: bool = True,
) -> ArtifactBundle:
    graph = _parse_json(graph_json, "$graph")
    if type(graph) is not dict:
        _fail("SCHEMA_TYPE", "$graph", "expected object")
    return compile_graph(graph, deduplicate_weights=deduplicate_weights)


def _validate_metadata(metadata: Any) -> dict[str, Any]:
    root = _object(
        metadata,
        "$metadata",
        {
            "schema",
            "bundle_id",
            "abi",
            "artifacts",
            "buffers",
            "commands",
            "graph",
            "publication",
            "provenance",
            "relocations",
            "runtime",
        },
    )
    if _string(root["schema"], "$metadata.schema") != METADATA_SCHEMA:
        _fail("METADATA_VERSION", "$metadata.schema", f"expected {METADATA_SCHEMA}")
    bundle_id = _sha256(root["bundle_id"], "$metadata.bundle_id")
    core = dict(root)
    del core["bundle_id"]
    expected_bundle_id = _digest(canonical_json_bytes(core))
    if bundle_id != expected_bundle_id:
        _fail(
            "BUNDLE_ID",
            "$metadata.bundle_id",
            f"expected {expected_bundle_id}, got {bundle_id}",
        )

    abi = _object(
        root["abi"],
        "$metadata.abi",
        {
            "major",
            "minor",
            "endianness",
            "command_header_bytes",
            "command_record_words",
            "weight_alignment",
        },
    )
    expected_abi = {
        "major": ABI_MAJOR,
        "minor": ABI_MINOR,
        "endianness": "little",
        "command_header_bytes": COMMAND_HEADER_BYTES,
        "command_record_words": COMMAND_RECORD_WORDS,
        "weight_alignment": WEIGHT_ALIGNMENT,
    }
    checked_abi = {
        "major": _integer(abi["major"], "$metadata.abi.major", minimum=0, maximum=0xFFFF),
        "minor": _integer(abi["minor"], "$metadata.abi.minor", minimum=0, maximum=0xFFFF),
        "endianness": _string(abi["endianness"], "$metadata.abi.endianness"),
        "command_header_bytes": _integer(
            abi["command_header_bytes"],
            "$metadata.abi.command_header_bytes",
            minimum=0,
            maximum=0xFFFF,
        ),
        "command_record_words": _integer(
            abi["command_record_words"],
            "$metadata.abi.command_record_words",
            minimum=0,
            maximum=0xFFFF,
        ),
        "weight_alignment": _integer(
            abi["weight_alignment"],
            "$metadata.abi.weight_alignment",
            minimum=0,
            maximum=UINT64_MAX,
        ),
    }
    if checked_abi != expected_abi:
        _fail("METADATA_ABI", "$metadata.abi", f"expected {expected_abi}, got {checked_abi}")
    runtime = _object(root["runtime"], "$metadata.runtime", {"service_abi"})
    service_abi = _object(
        runtime["service_abi"], "$metadata.runtime.service_abi", {"major", "minor"}
    )
    expected_service_abi = {"major": SERVICE_ABI_MAJOR, "minor": SERVICE_ABI_MINOR}
    checked_service_abi = {
        "major": _integer(
            service_abi["major"],
            "$metadata.runtime.service_abi.major",
            minimum=0,
            maximum=0xFFFF,
        ),
        "minor": _integer(
            service_abi["minor"],
            "$metadata.runtime.service_abi.minor",
            minimum=0,
            maximum=0xFFFF,
        ),
    }
    if checked_service_abi != expected_service_abi:
        _fail(
            "SERVICE_ABI",
            "$metadata.runtime.service_abi",
            f"expected {expected_service_abi}, got {checked_service_abi}",
        )
    graph = _object(root["graph"], "$metadata.graph", {"name", "source_schema"})
    _string(graph["name"], "$metadata.graph.name")
    if _string(graph["source_schema"], "$metadata.graph.source_schema") != GRAPH_SCHEMA:
        _fail("GRAPH_VERSION", "$metadata.graph.source_schema", f"expected {GRAPH_SCHEMA}")

    artifacts = _object(root["artifacts"], "$metadata.artifacts", {"command.bin", "weights.bin"})
    for name in ("command.bin", "weights.bin"):
        artifact = _object(artifacts[name], f"$metadata.artifacts.{name}", {"bytes", "sha256"})
        _integer(artifact["bytes"], f"$metadata.artifacts.{name}.bytes", minimum=0, maximum=UINT64_MAX)
        _sha256(artifact["sha256"], f"$metadata.artifacts.{name}.sha256")

    raw_buffers = _array(root["buffers"], "$metadata.buffers")
    by_id: dict[str, dict[str, Any]] = {}
    previous_id: str | None = None
    for index, raw in enumerate(raw_buffers):
        path = f"$metadata.buffers[{index}]"
        if type(raw) is not dict:
            _fail("SCHEMA_TYPE", path, "expected object")
        kind = _string(raw.get("kind"), f"{path}.kind")
        common = {"alignment", "id", "kind", "permissions", "size"}
        item = _object(raw, path, common | ({"weights_offset", "sha256"} if kind == "weight" else set()))
        if kind not in {"input", "output", "scratch", "transient", "weight"}:
            _fail("BUFFER_KIND", f"{path}.kind", f"unknown kind {kind!r}")
        identifier = _buffer_id(item["id"], f"{path}.id")
        if previous_id is not None and identifier <= previous_id:
            _fail("BUFFER_ORDER", f"{path}.id", "buffers must be sorted and unique")
        previous_id = identifier
        alignment = _power_of_two(item["alignment"], f"{path}.alignment", minimum=WEIGHT_ALIGNMENT)
        size = _integer(item["size"], f"{path}.size", minimum=1, maximum=UINT64_MAX)
        permission = _string(item["permissions"], f"{path}.permissions")
        if permission not in {"r", "w", "rw"}:
            _fail("BUFFER_PERMISSION", f"{path}.permissions", "expected r, w, or rw")
        if kind == "output" and permission != "w":
            _fail(
                "BUFFER_PERMISSION",
                f"{path}.permissions",
                "output buffers must be write-only publication targets",
            )
        if kind == "weight":
            if permission != "r":
                _fail("BUFFER_PERMISSION", f"{path}.permissions", "weights must be read-only")
            offset = _integer(
                item["weights_offset"], f"{path}.weights_offset", minimum=0, maximum=UINT64_MAX
            )
            if offset % alignment:
                _fail("WEIGHT_ALIGNMENT", f"{path}.weights_offset", f"not aligned to {alignment}")
            _sha256(item["sha256"], f"{path}.sha256")
        by_id[identifier] = item

    publication = _object(
        root["publication"], "$metadata.publication", {"mode", "entries"}
    )
    if _string(publication["mode"], "$metadata.publication.mode") != PUBLICATION_MODE:
        _fail(
            "PUBLICATION_MODE",
            "$metadata.publication.mode",
            f"expected {PUBLICATION_MODE}",
        )
    _parse_publications(
        publication["entries"], by_id, "$metadata.publication.entries"
    )

    raw_commands = _array(root["commands"], "$metadata.commands")
    names: set[str] = set()
    total_cycle_upper_bound = 0
    for index, raw in enumerate(raw_commands):
        path = f"$metadata.commands[{index}]"
        command = _object(
            raw,
            path,
            {
                "cycle_upper_bound",
                "descriptor_sha256",
                "identity",
                "index",
                "name",
                "node_ids",
                "node_sha256",
                "owner",
                "workload",
            },
        )
        if _integer(command["index"], f"{path}.index", minimum=0, maximum=0xFFFFFFFF) != index:
            _fail("COMMAND_ORDER", f"{path}.index", f"expected {index}")
        name = _string(command["name"], f"{path}.name")
        if name in names:
            _fail("COMMAND_DUPLICATE", f"{path}.name", name)
        names.add(name)
        cycle_upper_bound = _integer(
            command["cycle_upper_bound"],
            f"{path}.cycle_upper_bound",
            minimum=1,
            maximum=UINT64_MAX,
        )
        total_cycle_upper_bound = _checked_cycle_sum(
            total_cycle_upper_bound, cycle_upper_bound, f"{path}.cycle_upper_bound"
        )
        owner = _string(command["owner"], f"{path}.owner")
        if owner != F32_ALU_OWNER:
            _fail("COMMAND_OWNER", f"{path}.owner", f"unsupported owner {owner!r}")
        identity = _parse_identity(command["identity"], f"{path}.identity")
        if identity["kernel_id"] != F32_ALU_KERNEL_ID:
            _fail(
                "OWNER_KERNEL",
                f"{path}.identity.kernel_id",
                f"owner {owner!r} requires kernel 0x{F32_ALU_KERNEL_ID:08x}",
            )
        _parse_workload(command["workload"], f"{path}.workload")
        _sha256(command["descriptor_sha256"], f"{path}.descriptor_sha256")
        node_digest, node_ids = _node_digest(
            _array(command["node_ids"], f"{path}.node_ids"), f"{path}.node_ids"
        )
        node_sha256 = _sha256(command["node_sha256"], f"{path}.node_sha256")
        if node_sha256 != node_digest.hex():
            _fail("NODE_HASH", f"{path}.node_sha256", "does not match node_ids")
        if identity["covered_node_count"] != len(node_ids):
            _fail(
                "COMMAND_IDENTITY",
                f"{path}.identity.covered_node_count",
                "does not match node_ids",
            )
        if identity["node_hash_lo"] != int.from_bytes(node_digest[0:8], "little") or identity[
            "node_hash_hi"
        ] != int.from_bytes(node_digest[8:16], "little"):
            _fail(
                "COMMAND_IDENTITY",
                f"{path}.identity",
                "node hash does not match node_ids",
            )

    raw_relocations = _array(root["relocations"], "$metadata.relocations")
    previous_key: tuple[int, int] | None = None
    relocation_by_command: dict[int, dict[int, Mapping[str, Any]]] = {}
    for index, raw in enumerate(raw_relocations):
        path = f"$metadata.relocations[{index}]"
        relocation = _object(
            raw,
            path,
            {"addend", "buffer_id", "command_index", "kind", "word_index"},
        )
        command_index = _integer(
            relocation["command_index"], f"{path}.command_index", minimum=0, maximum=0xFFFFFFFF
        )
        if command_index >= len(raw_commands):
            _fail("RELOCATION_COMMAND", f"{path}.command_index", "outside command table")
        word_index = _integer(
            relocation["word_index"],
            f"{path}.word_index",
            minimum=0,
            maximum=COMMAND_RECORD_WORDS - 1,
        )
        key = (command_index, word_index)
        if previous_key is not None and key <= previous_key:
            code = "RELOCATION_DUPLICATE" if key == previous_key else "RELOCATION_ORDER"
            _fail(code, path, f"command/word key {key}")
        previous_key = key
        kind = _string(relocation["kind"], f"{path}.kind")
        expected_kind = RELOCATION_KIND_FOR_WORD.get(word_index)
        if expected_kind is None or kind != expected_kind:
            _fail(
                "RELOCATION_KIND",
                f"{path}.kind",
                f"word {word_index} requires {expected_kind!r}, got {kind!r}",
            )
        identifier = _buffer_id(relocation["buffer_id"], f"{path}.buffer_id")
        if identifier not in by_id:
            _fail("UNKNOWN_BUFFER", f"{path}.buffer_id", identifier)
        _check_permission(by_id[identifier], word_index, path)
        addend = _integer(relocation["addend"], f"{path}.addend", minimum=0, maximum=UINT64_MAX)
        if addend >= by_id[identifier]["size"]:
            _fail("RELOCATION_RANGE", f"{path}.addend", "outside buffer")
        relocation_by_command.setdefault(command_index, {})[word_index] = relocation

    for command_index, command_relocations in relocation_by_command.items():
        for iova_word, window_word in WINDOW_ADDRESS_PAIRS:
            iova = command_relocations.get(iova_word)
            window = command_relocations.get(window_word)
            if (iova is None) != (window is None):
                _fail(
                    "RELOCATION_PAIR_MISSING",
                    f"$metadata.commands[{command_index}]",
                    f"words {iova_word}/{window_word} must be relocated together",
                )
            if iova is not None and iova["buffer_id"] != window["buffer_id"]:
                _fail(
                    "WINDOW_BUFFER_MISMATCH",
                    f"$metadata.commands[{command_index}]",
                    f"words {iova_word}/{window_word} reference different buffers",
                )
        src2 = command_relocations.get(12)
        declared_window_buffers = {
            command_relocations[word]["buffer_id"]
            for word in (10, 11, 13)
            if word in command_relocations
        }
        if src2 is not None and src2["buffer_id"] not in declared_window_buffers:
            _fail(
                "SRC2_NOT_WINDOW_ALIAS",
                f"$metadata.commands[{command_index}]",
                "word 12 must alias a relocated src0/src1/dst window",
            )
    _parse_provenance(
        root["provenance"],
        by_id,
        raw_commands,
        "$metadata.provenance",
        require_sorted=True,
    )
    return root


def _verify_weight_layout(metadata: Mapping[str, Any], weights_bin: bytes) -> None:
    if len(weights_bin) % WEIGHT_ALIGNMENT:
        _fail(
            "WEIGHT_FILE_ALIGNMENT",
            "$weights.bin",
            f"size {len(weights_bin)} is not a multiple of {WEIGHT_ALIGNMENT}",
        )
    ranges: list[tuple[int, int, str, str]] = []
    for index, buffer in enumerate(metadata["buffers"]):
        if buffer["kind"] != "weight":
            continue
        start = buffer["weights_offset"]
        size = buffer["size"]
        if start > len(weights_bin) or size > len(weights_bin) - start:
            _fail("WEIGHT_RANGE", f"$metadata.buffers[{index}]", "outside weights.bin")
        payload = weights_bin[start : start + size]
        actual = _digest(payload)
        if actual != buffer["sha256"]:
            _fail(
                "WEIGHT_HASH",
                f"$metadata.buffers[{index}].sha256",
                f"expected {buffer['sha256']}, got {actual}",
            )
        ranges.append((start, start + size, buffer["id"], buffer["sha256"]))
    ranges.sort()
    unique_ranges: list[tuple[int, int]] = []
    previous: tuple[int, int, str, str] | None = None
    for current in ranges:
        if previous is not None and current[0] < previous[1]:
            exact_dedup = (
                current[0] == previous[0]
                and current[1] == previous[1]
                and current[3] == previous[3]
            )
            if not exact_dedup:
                _fail(
                    "WEIGHT_OVERLAP",
                    "$metadata.buffers",
                    f"{previous[2]!r} overlaps {current[2]!r}",
                )
        if not unique_ranges or (current[0], current[1]) != unique_ranges[-1]:
            unique_ranges.append((current[0], current[1]))
        if previous is None or current[1] > previous[1]:
            previous = current
    cursor = 0
    for start, end in unique_ranges:
        if any(weights_bin[cursor:start]):
            _fail("WEIGHT_PADDING", "$weights.bin", f"non-zero padding at [{cursor}, {start})")
        cursor = max(cursor, end)
    if any(weights_bin[cursor:]):
        _fail("WEIGHT_PADDING", "$weights.bin", f"non-zero padding at [{cursor}, {len(weights_bin)})")


def load_bundle(command_bin: bytes, weights_bin: bytes, metadata_json: bytes) -> LoadedBundle:
    """Validate that all three immutable files form one internally closed bundle."""

    if not isinstance(command_bin, bytes) or not isinstance(weights_bin, bytes):
        _fail("SCHEMA_TYPE", "$bundle", "binary artifacts must be bytes")
    if not isinstance(metadata_json, bytes):
        _fail("SCHEMA_TYPE", "$metadata.json", "expected bytes")
    metadata = _parse_json(metadata_json, "$metadata.json")
    if canonical_json_bytes(metadata) != metadata_json:
        _fail("METADATA_CANONICAL", "$metadata.json", "not canonical JSON")
    metadata = _validate_metadata(metadata)
    records = unpack_command_file(command_bin)
    for name, payload in (("command.bin", command_bin), ("weights.bin", weights_bin)):
        expected = metadata["artifacts"][name]
        if len(payload) != expected["bytes"]:
            _fail(
                "ARTIFACT_SIZE",
                f"$metadata.artifacts.{name}.bytes",
                f"expected {expected['bytes']}, got {len(payload)}",
            )
        actual_hash = _digest(payload)
        if actual_hash != expected["sha256"]:
            _fail(
                "ARTIFACT_HASH",
                f"$metadata.artifacts.{name}.sha256",
                f"expected {expected['sha256']}, got {actual_hash}",
            )
    if len(records) != len(metadata["commands"]):
        _fail(
            "COMMAND_COUNT",
            "$metadata.commands",
            f"command.bin has {len(records)}, metadata has {len(metadata['commands'])}",
        )
    for index, (record, command) in enumerate(zip(records, metadata["commands"])):
        _validate_descriptor_wire_static(record, f"$command.bin.records[{index}]")
        actual_descriptor_hash = _digest(_record_bytes(record))
        if command["descriptor_sha256"] != actual_descriptor_hash:
            _fail(
                "DESCRIPTOR_HASH",
                f"$metadata.commands[{index}].descriptor_sha256",
                f"expected {command['descriptor_sha256']}, got {actual_descriptor_hash}",
            )
        expected_identity = _identity_from_words(record)
        if command["identity"] != expected_identity:
            _fail(
                "COMMAND_IDENTITY",
                f"$metadata.commands[{index}].identity",
                f"expected {expected_identity}, got {command['identity']}",
            )
        node_digest, node_ids = _node_digest(command["node_ids"], f"$metadata.commands[{index}].node_ids")
        if record[5] & 0xFFFFFFFF != len(node_ids):
            _fail("NODE_COUNT", f"$metadata.commands[{index}]", "does not match descriptor")
        if record[6] != int.from_bytes(node_digest[0:8], "little") or record[7] != int.from_bytes(
            node_digest[8:16], "little"
        ):
            _fail("NODE_HASH", f"$metadata.commands[{index}]", "does not match descriptor")
        if record[14] != 0 or record[17] >> 32 != 0:
            _fail(
                "SCRATCH_UNSUPPORTED",
                f"$metadata.commands[{index}]",
                "ABI 1.1 has no scratch window",
            )
        relocated_words = {
            relocation["word_index"]
            for relocation in metadata["relocations"]
            if relocation["command_index"] == index
        }
        for word in RELOCATION_WORDS:
            if word not in relocated_words and record[word] != 0:
                _fail(
                    "RELOCATION_PAIR_MISSING",
                    f"$metadata.commands[{index}]",
                    f"non-zero address word {word} has no relocation",
                )
    for index, relocation in enumerate(metadata["relocations"]):
        record_value = records[relocation["command_index"]][relocation["word_index"]]
        if record_value != relocation["addend"]:
            _fail(
                "RELOCATION_TEMPLATE",
                f"$metadata.relocations[{index}]",
                f"template has {record_value}, expected addend {relocation['addend']}",
            )
    _validate_output_producers(
        {buffer["id"]: buffer for buffer in metadata["buffers"]},
        metadata["relocations"],
        metadata["publication"]["entries"],
        records,
        "$metadata",
    )
    _validate_transient_dataflow(
        {buffer["id"]: buffer for buffer in metadata["buffers"]},
        metadata["relocations"],
        records,
        "$metadata",
    )
    _verify_weight_layout(metadata, weights_bin)
    return LoadedBundle(command_bin, weights_bin, metadata_json, metadata, records)


def _runtime_buffer_bases(
    metadata: Mapping[str, Any],
    buffer_bases: Mapping[str, int],
    weights_base: int | None,
) -> dict[str, int]:
    if type(buffer_bases) is not dict:
        # Mapping implementations are accepted, but materialize once so keys
        # cannot change between validation and patching.
        try:
            buffer_bases = dict(buffer_bases)
        except (TypeError, ValueError):
            _fail("SCHEMA_TYPE", "$buffer_bases", "expected mapping")
    metadata_buffers = {buffer["id"]: buffer for buffer in metadata["buffers"]}
    for identifier in buffer_bases:
        if identifier not in metadata_buffers:
            _fail("UNKNOWN_BUFFER", "$buffer_bases", str(identifier))
    resolved: dict[str, int] = {}
    for identifier, raw_base in buffer_bases.items():
        base = _integer(raw_base, f"$buffer_bases.{identifier}", minimum=0, maximum=UINT64_MAX)
        resolved[identifier] = base
    if weights_base is not None:
        weight_image_base = _integer(
            weights_base, "$weights_base", minimum=0, maximum=UINT64_MAX
        )
        if weight_image_base % WEIGHT_ALIGNMENT:
            _fail("BUFFER_ALIGNMENT", "$weights_base", f"must be {WEIGHT_ALIGNMENT}-byte aligned")
        for identifier, buffer in metadata_buffers.items():
            if buffer["kind"] != "weight":
                continue
            if identifier in resolved:
                _fail(
                    "BUFFER_BASE_AMBIGUOUS",
                    f"$buffer_bases.{identifier}",
                    "weight base supplied both explicitly and through weights_base",
                )
            offset = buffer["weights_offset"]
            if weight_image_base > UINT64_MAX - offset:
                _fail("RELOC_OVERFLOW", f"$metadata.buffers.{identifier}", "weights base + offset")
            resolved[identifier] = weight_image_base + offset
    required_ids = {relocation["buffer_id"] for relocation in metadata["relocations"]}
    missing = sorted(required_ids - set(resolved))
    if missing:
        _fail("MISSING_BUFFER_BASE", "$buffer_bases", f"missing {missing}")

    intervals: list[tuple[int, int, str, Mapping[str, Any]]] = []
    for identifier in sorted(required_ids):
        buffer = metadata_buffers[identifier]
        base = resolved[identifier]
        if base % buffer["alignment"]:
            _fail(
                "BUFFER_ALIGNMENT",
                f"$buffer_bases.{identifier}",
                f"0x{base:x} is not aligned to {buffer['alignment']}",
            )
        size = buffer["size"]
        if base > UINT64_MAX - size:
            _fail("RELOC_OVERFLOW", f"$buffer_bases.{identifier}", "base + size overflows u64")
        intervals.append((base, base + size, identifier, buffer))
    intervals.sort()
    for left, right in zip(intervals, intervals[1:]):
        if right[0] >= left[1]:
            continue
        exact_weight_alias = (
            left[0] == right[0]
            and left[1] == right[1]
            and left[3]["kind"] == right[3]["kind"] == "weight"
            and left[3]["weights_offset"] == right[3]["weights_offset"]
            and left[3]["sha256"] == right[3]["sha256"]
        )
        if not exact_weight_alias:
            _fail(
                "BUFFER_OVERLAP",
                "$buffer_bases",
                f"{left[2]!r} [0x{left[0]:x},0x{left[1]:x}) overlaps "
                f"{right[2]!r} [0x{right[0]:x},0x{right[1]:x})",
            )
    return resolved


def apply_relocations(
    command_bin: bytes,
    metadata: Mapping[str, Any],
    buffer_bases: Mapping[str, int],
    *,
    weights_base: int | None = None,
) -> bytes:
    """Patch a validated command template and return a newly hashed command file.

    ``metadata`` still describes the immutable template.  The returned runtime
    image has a fresh internal payload hash and intentionally no longer matches
    ``metadata.artifacts['command.bin']``.
    """

    checked_metadata = _validate_metadata(metadata)
    records = unpack_command_file(command_bin)
    expected_command = checked_metadata["artifacts"]["command.bin"]
    if len(command_bin) != expected_command["bytes"] or _digest(command_bin) != expected_command["sha256"]:
        _fail("ARTIFACT_HASH", "$command.bin", "template does not match metadata")
    if len(records) != len(checked_metadata["commands"]):
        _fail("COMMAND_COUNT", "$metadata.commands", "does not match command.bin")
    bases = _runtime_buffer_bases(checked_metadata, buffer_bases, weights_base)
    patched = [list(record) for record in records]
    for index, relocation in enumerate(checked_metadata["relocations"]):
        command_index = relocation["command_index"]
        word_index = relocation["word_index"]
        addend = relocation["addend"]
        if patched[command_index][word_index] != addend:
            _fail("RELOCATION_TEMPLATE", f"$metadata.relocations[{index}]", "template/addend mismatch")
        base = bases[relocation["buffer_id"]]
        if base > UINT64_MAX - addend:
            _fail("RELOC_OVERFLOW", f"$metadata.relocations[{index}]", "base + addend overflows u64")
        patched[command_index][word_index] = base + addend
    return pack_command_file(patched)


def _descriptor_template(
    *,
    sequence_id: int,
    producer_id: int,
    user_tag: int,
    vector_op: int,
) -> list[int]:
    """Create one VECTOR_F32 ADD descriptor for the executable tiny fixture."""

    return [
        (0x11 << 32) | 0x514E0010,
        (1 << 32) | 7,
        sequence_id,
        producer_id,
        user_tag,
        (vector_op << 32) | 1,
        0,
        0,
        0,
        1 << 32,
        0,
        0,
        0,
        0,
        0,
        16,
        1,
        0,
        0,
        64,
        64,
        0,
        64,
        0,
        64,
        0x97,
        0,
        64,
        0,
        64,
    ]


def _relocation(word_index: int, kind: str, buffer_id: str, addend: int = 0) -> dict[str, Any]:
    return {
        "word_index": word_index,
        "kind": kind,
        "buffer_id": buffer_id,
        "addend": addend,
    }


def _tiny_f32_alu_workload() -> dict[str, Any]:
    return {
        "schema": F32_ALU_WORKLOAD_SCHEMA,
        "request_groups": 4,
        "response_groups": 4,
        "read_groups": 2,
        "write_groups": 2,
        "input_words": 32,
        "output_words": 16,
        "read_bytes": 128,
        "write_bytes": 64,
        "completion_vector_elements": 16,
        "expected_starts": 1,
    }


def tiny_two_command_graph() -> dict[str, Any]:
    """Return a deterministic two-command graph used by CLI and smoke tests."""

    bias_words = [0x3F800000 + index for index in range(16)]
    bias = b"".join(struct.pack("<I", word) for word in bias_words)
    graph: dict[str, Any] = {
        "schema": GRAPH_SCHEMA,
        "name": "tiny-two-vector-add",
        "buffers": [
            {"id": "input0", "kind": "input", "size": 64, "alignment": 64, "permissions": "r"},
            {"id": "input1", "kind": "input", "size": 64, "alignment": 64, "permissions": "r"},
            {"id": "intermediate", "kind": "transient", "size": 64, "alignment": 64, "permissions": "rw"},
            {"id": "bias", "kind": "weight", "alignment": 64, "permissions": "r", "data_hex": bias.hex()},
            {"id": "output", "kind": "output", "size": 64, "alignment": 64, "permissions": "w"},
        ],
        "commands": [
            {
                "cycle_upper_bound": 100000,
                "name": "add-inputs",
                "node_ids": [0x1001],
                "owner": F32_ALU_OWNER,
                "workload": _tiny_f32_alu_workload(),
                "descriptor_words": _descriptor_template(
                    sequence_id=1, producer_id=0x2001, user_tag=0x3001, vector_op=1
                ),
                "relocations": [
                    _relocation(10, "iova64", "input0"),
                    _relocation(11, "iova64", "input1"),
                    _relocation(13, "iova64", "intermediate"),
                    _relocation(23, "window_base64", "input0"),
                    _relocation(26, "window_base64", "input1"),
                    _relocation(28, "window_base64", "intermediate"),
                ],
            },
            {
                "cycle_upper_bound": 100000,
                "name": "add-bias",
                "node_ids": [0x1002],
                "owner": F32_ALU_OWNER,
                "workload": _tiny_f32_alu_workload(),
                "descriptor_words": _descriptor_template(
                    sequence_id=2, producer_id=0x2002, user_tag=0x3002, vector_op=1
                ),
                "relocations": [
                    _relocation(10, "iova64", "intermediate"),
                    _relocation(11, "iova64", "bias"),
                    _relocation(13, "iova64", "output"),
                    _relocation(23, "window_base64", "intermediate"),
                    _relocation(26, "window_base64", "bias"),
                    _relocation(28, "window_base64", "output"),
                ],
            },
        ],
        "publications": [
            {
                "buffer_id": "output",
                "source_offset": 0,
                "target_offset": 0,
                "bytes": 64,
            }
        ],
    }

    descriptor_hashes: list[str] = []
    for command in graph["commands"]:
        words = list(command["descriptor_words"])
        node_digest, node_ids = _node_digest(command["node_ids"], "$tiny.node_ids")
        words[5] = (words[5] & 0xFFFFFFFF00000000) | len(node_ids)
        words[6] = int.from_bytes(node_digest[0:8], "little")
        words[7] = int.from_bytes(node_digest[8:16], "little")
        descriptor_hashes.append(_digest(_record_bytes(words)))

    tensor_specs = {
        "bias": ("constant", 0, "synthetic:tiny/tensor/bias"),
        "input0": ("graph_input", 0, "synthetic:tiny/tensor/input0"),
        "input1": ("graph_input", 1, "synthetic:tiny/tensor/input1"),
        "intermediate": ("graph_node", 0, "synthetic:tiny/tensor/intermediate"),
        "output": ("graph_output", 0, "synthetic:tiny/tensor/output"),
    }
    buffer_bindings: list[dict[str, Any]] = []
    for buffer_id in sorted(tensor_specs):
        origin_kind, origin_index, canonical_id = tensor_specs[buffer_id]
        descriptor_hash = _digest(
            canonical_json_bytes(
                {
                    "buffer_id": buffer_id,
                    "dtype": "f32",
                    "layout": "dense",
                    "shape": [16],
                    "synthetic": True,
                }
            )
        )
        buffer_bindings.append(
            {
                "alias_offset": 0,
                "buffer_id": buffer_id,
                "canonical_id": canonical_id,
                "logical_size": 64,
                "origin_index": origin_index,
                "origin_kind": origin_kind,
                "storage_canonical_id": canonical_id,
                "storage_origin_index": origin_index,
                "storage_origin_kind": origin_kind,
                "storage_size": 64,
                "storage_tensor_descriptor_sha256": descriptor_hash,
                "tensor_descriptor_sha256": descriptor_hash,
            }
        )
    synthetic_manifest = canonical_json_bytes(
        {
            "graph_scope": "synthetic:tiny-two-vector-add",
            "name": graph["name"],
            "schema": "synthetic-graph-manifest-v1",
        }
    )
    graph["provenance"] = {
        "source": {
            "schema": "synthetic-graph-manifest-v1",
            "manifest_sha256": _digest(synthetic_manifest),
            "raw_sha256": _digest(b"synthetic fixture; no external model source"),
            "graph_ir_schema": "synthetic-npu-graph-ir-v1",
            "graph_ir_sha256": _digest(
                b"synthetic graph IR: tiny-two-vector-add"
            ),
            "profile": "synthetic:p00-dense-add",
            "source_commit": None,
            "graph_scope": "synthetic:tiny-two-vector-add",
        },
        "node_bindings": [
            {
                "artifact_node_id": 0x1001,
                "artifact_schedule_position": 0,
                "canonical_id": "synthetic:tiny/node/add-inputs",
                "command_descriptor_sha256": descriptor_hashes[0],
                "manifest_graph_index": 0,
                "profile_family": "vector_f32",
                "profile_id": "p00",
                "source_descriptor_sha256": _digest(
                    b"synthetic source descriptor: add-inputs"
                ),
                "source_schedule_position": 0,
            },
            {
                "artifact_node_id": 0x1002,
                "artifact_schedule_position": 1,
                "canonical_id": "synthetic:tiny/node/add-bias",
                "command_descriptor_sha256": descriptor_hashes[1],
                "manifest_graph_index": 1,
                "profile_family": "vector_f32",
                "profile_id": "p00",
                "source_descriptor_sha256": _digest(
                    b"synthetic source descriptor: add-bias"
                ),
                "source_schedule_position": 1,
            },
        ],
        "buffer_bindings": buffer_bindings,
    }
    return graph
