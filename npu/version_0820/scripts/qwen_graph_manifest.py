#!/usr/bin/env python3
"""Fail-closed validator for the llama.cpp pre-scheduler dispatch graph dump."""

from __future__ import annotations

import argparse
import copy
import hashlib
import json
import os
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Iterable, Mapping, Sequence


RAW_SCHEMA = "llama-npu-dispatch-graph-raw-v2"
SEMANTIC_SCHEMA = "qwen-graph-semantic-key-v2"
MANIFEST_SCHEMA = "qwen-npu-graph-manifest-v2"
ENVELOPE_SCHEMA = "qwen-npu-graph-manifest-envelope-v2"
BUNDLE_SCHEMA = "qwen-npu-graph-manifest-bundle-v1"
BUNDLE_ENVELOPE_SCHEMA = "qwen-npu-graph-manifest-bundle-envelope-v1"

# Exact strict-greedy Qwen3.5-0.8B dispatch identities.  Dispatch 1 is kept in
# its legacy raw-v2 form (without target/observed fields); dispatch 2 is the
# first steady-state graph and carries the explicit collector dispatch fields.
BOOTSTRAP_RAW_SHA256 = "a144ef45f25e8f7a754ddd16faea09422b175d443538bf884964b2ff3685f112"
BOOTSTRAP_MANIFEST_SHA256 = "92d404d308cb9ca6a7741233ab05f8eb07be6659dc833fb99b7cd023958fe48e"
STEADY_RAW_SHA256 = "0338b4e64e3fb1d848ae2387cfbd8e7816d6e5b9cb4d5645759cbc3f0b5753f5"
STEADY_MANIFEST_SHA256 = "9b0609f46b30267cfc43d1a7fb96eed0f654eb727d792f10d82b3b847578bf10"
QWEN_COUNTS = {
    "compute": 960,
    "external_tensors": 375,
    "metadata": 634,
    "mover": 120,
    "source_edges": 2474,
    "total": 1714,
}
QWEN_RECURRENT_LAYERS = (0, 1, 2, 4, 5, 6, 8, 9, 10, 12, 13, 14, 16, 17, 18, 20, 21, 22)
QWEN_ZERO_NODE_RE = re.compile(
    r"cache_([rs])_l(0|1|2|4|5|6|8|9|10|12|13|14|16|17|18|20|21|22) "
    r"\(reshaped\) \(view\)( \(view\))?\Z"
)

METADATA_OPS = frozenset({"NONE", "RESHAPE", "VIEW", "PERMUTE", "TRANSPOSE"})
MOVER_OPS = frozenset({"REPEAT", "CONCAT", "CONT", "CPY"})
if METADATA_OPS & MOVER_OPS:  # pragma: no cover - import-time invariant
    raise RuntimeError("classification sets overlap")

LOWER_HEX_8 = re.compile(r"[0-9a-f]{8}\Z")
LOWER_HEX_40 = re.compile(r"[0-9a-f]{40}\Z")
LOWER_HEX_64 = re.compile(r"[0-9a-f]{64}\Z")
LOWER_HEX_128 = re.compile(r"[0-9a-f]{128}\Z")


class ManifestError(ValueError):
    def __init__(self, code: str, path: str, detail: str):
        super().__init__(f"{code} at {path}: {detail}")
        self.code = code
        self.path = path
        self.detail = detail


def _duplicate_checked_object(pairs: list[tuple[str, Any]]) -> dict[str, Any]:
    result: dict[str, Any] = {}
    for key, value in pairs:
        if key in result:
            raise ManifestError("DUPLICATE_KEY", "$json", f"duplicate key {key!r}")
        result[key] = value
    return result


def _reject_json_real(text: str) -> Any:
    raise ManifestError("JSON_REAL", "$json", f"real number is forbidden: {text}")


def _reject_json_constant(text: str) -> Any:
    raise ManifestError("JSON_CONSTANT", "$json", f"non-finite constant is forbidden: {text}")


def canonical_bytes(value: Any) -> bytes:
    return json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":")).encode("utf-8")


def compact_bytes(value: Any) -> bytes:
    return json.dumps(value, ensure_ascii=False, sort_keys=False, separators=(",", ":")).encode("utf-8")


def sha256_bytes(payload: bytes) -> str:
    return hashlib.sha256(payload).hexdigest()


def _fail(code: str, path: str, detail: str) -> None:
    raise ManifestError(code, path, detail)


def _object(value: Any, path: str, keys: Iterable[str]) -> dict[str, Any]:
    if type(value) is not dict:
        _fail("SCHEMA_TYPE", path, "expected object")
    expected = set(keys)
    actual = set(value)
    if actual != expected:
        _fail("SCHEMA_KEYS", path, f"missing={sorted(expected - actual)} extra={sorted(actual - expected)}")
    return value


def _array(value: Any, path: str, length: int | None = None) -> list[Any]:
    if type(value) is not list:
        _fail("SCHEMA_TYPE", path, "expected array")
    if length is not None and len(value) != length:
        _fail("SCHEMA_LENGTH", path, f"expected {length}, got {len(value)}")
    return value


def _string(value: Any, path: str, *, nonempty: bool = True) -> str:
    if type(value) is not str:
        _fail("SCHEMA_TYPE", path, "expected string")
    if nonempty and not value:
        _fail("SCHEMA_VALUE", path, "string must be non-empty")
    if "\x00" in value:
        _fail("SCHEMA_VALUE", path, "NUL is forbidden")
    return value


def _label(value: Any, path: str) -> str:
    text = _string(value, path)
    if len(text) > 128 or any(ord(ch) < 0x21 or ord(ch) > 0x7E or ch in {'"', "\\"} for ch in text):
        _fail("BINDING_LABEL", path, "must be printable ASCII without quote/backslash, max 128 bytes")
    return text


def _integer(value: Any, path: str, minimum: int | None = None, maximum: int | None = None) -> int:
    if type(value) is not int:
        _fail("SCHEMA_TYPE", path, "expected integer")
    if minimum is not None and value < minimum:
        _fail("SCHEMA_RANGE", path, f"must be >= {minimum}")
    if maximum is not None and value > maximum:
        _fail("SCHEMA_RANGE", path, f"must be <= {maximum}")
    return value


def _boolean(value: Any, path: str) -> bool:
    if type(value) is not bool:
        _fail("SCHEMA_TYPE", path, "expected boolean")
    return value


def _hex(value: Any, path: str, pattern: re.Pattern[str]) -> str:
    text = _string(value, path)
    if pattern.fullmatch(text) is None:
        _fail("SCHEMA_HEX", path, "wrong width or non-lowercase hex")
    return text


def _parse_record(line: bytes, line_number: int) -> dict[str, Any]:
    path = f"$line[{line_number}]"
    try:
        text = line.decode("utf-8")
    except UnicodeDecodeError as exc:
        _fail("UTF8", path, str(exc))
    try:
        value = json.loads(
            text,
            object_pairs_hook=_duplicate_checked_object,
            parse_float=_reject_json_real,
            parse_constant=_reject_json_constant,
        )
    except ManifestError:
        raise
    except (json.JSONDecodeError, UnicodeError) as exc:
        _fail("JSON", path, str(exc))
    if type(value) is not dict:
        _fail("SCHEMA_TYPE", path, "record must be an object")
    if compact_bytes(value) != line:
        _fail("RAW_COMPACT", path, "record is not compact deterministic JSON")
    return value


HEADER_KEYS = {
    "record_kind", "schema", "collector_phase", "bindings", "graph", "model", "runtime", "node_count",
}
HEADER_DISPATCH_KEYS = {"target_dispatch", "observed_dispatch"}
BINDING_KEYS = {"model_sha256", "numeric_profile", "profile", "source_commit"}
GRAPH_KEYS = {"kind", "scope", "type_id", "type_name"}
MODEL_KEYS = {
    "arch_id", "arch_name", "description", "model_name", "model_size", "n_embd", "n_elements", "n_layer",
    "n_layer_all", "n_layer_nextn", "n_tensors", "n_vocab", "recurrent_layers", "rope_sections", "ssm",
    "type_id", "type_name",
}
SSM_KEYS = {"d_conv", "d_inner", "d_state", "dt_rank", "n_group"}
RUNTIME_KEYS = {
    "auto_fa", "auto_fhc", "auto_fgdn", "auto_flid", "causal_attn", "collect_only", "context_type",
    "embeddings", "embeddings_layer_inp", "embeddings_nextn",
    "embeddings_nextn_masked", "flash_attn", "fused_dsv4_hc_comb", "fused_dsv4_hc_post",
    "fused_dsv4_hc_pre", "fused_gdn_ar", "fused_gdn_ch", "fused_lid", "graph_reuse_disable", "has_memory",
    "has_memory_context", "kv_unified", "n_batch", "n_ctx", "n_ctx_orig_yarn", "n_ctx_seq", "n_outputs",
    "n_outputs_max", "n_outputs_max_per_seq", "n_rs_seq", "n_seq_max", "n_threads", "n_threads_batch", "n_ubatch",
    "nextn_layer_offset", "offload_kqv", "op_offload", "pipeline_parallel", "pooling_type", "rope_freq_base_f32",
    "rope_freq_scale_f32", "sampler_count", "ubatch", "warmup", "yarn_attn_factor_f32", "yarn_beta_fast_f32",
    "yarn_beta_slow_f32", "yarn_ext_factor_f32",
}
UBATCH_KEYS = {
    "b_equal_seqs", "has_embd", "has_output", "has_token", "n_pos", "n_seq_tokens", "n_seqs", "n_seqs_unq",
    "n_tokens",
}
DESCRIPTOR_KEYS = {
    "flags", "name", "nb", "ne", "op_desc", "op_id", "op_name", "op_params_hex", "type_id", "type_name",
    "view_offs", "view_src",
}
SEMANTIC_KEYS = {
    "schema", "source_commit", "profile", "graph_scope", "path", "layer_index", "layer_kind", "role", "op",
    "subtype", "occurrence",
}
FOOTER_KEYS = {
    "record_kind", "schema", "complete", "compute_started", "dispatch_graph_scheduler_allocated",
    "external_tensor_count", "node_count", "record_count", "source_edge_count",
}


def _validate_header(record: dict[str, Any]) -> int:
    dispatch_keys = set(record) & HEADER_DISPATCH_KEYS
    if dispatch_keys and dispatch_keys != HEADER_DISPATCH_KEYS:
        _fail(
            "COLLECT_DISPATCH_FIELDS",
            "$header",
            f"target_dispatch and observed_dispatch must appear together; present={sorted(dispatch_keys)}",
        )
    header = _object(record, "$header", HEADER_KEYS | dispatch_keys)
    if _string(header["record_kind"], "$header.record_kind") != "header":
        _fail("RECORD_KIND", "$header.record_kind", "expected header")
    if _string(header["schema"], "$header.schema") != RAW_SCHEMA:
        _fail("SCHEMA_VERSION", "$header.schema", f"expected {RAW_SCHEMA}")
    if _string(header["collector_phase"], "$header.collector_phase") != "process_ubatch.post_build.pre_scheduler_alloc":
        _fail("COLLECT_PHASE", "$header.collector_phase", "collector is not at the frozen dispatch boundary")
    _integer(header["node_count"], "$header.node_count", 1)
    target_dispatch = 1
    if dispatch_keys:
        target_dispatch = _integer(header["target_dispatch"], "$header.target_dispatch", 1)
        observed_dispatch = _integer(header["observed_dispatch"], "$header.observed_dispatch", 1)
        if observed_dispatch != target_dispatch:
            _fail(
                "COLLECT_DISPATCH",
                "$header.observed_dispatch",
                f"expected {target_dispatch}, got {observed_dispatch}",
            )

    bindings = _object(header["bindings"], "$header.bindings", BINDING_KEYS)
    _hex(bindings["model_sha256"], "$header.bindings.model_sha256", LOWER_HEX_64)
    _label(bindings["numeric_profile"], "$header.bindings.numeric_profile")
    _label(bindings["profile"], "$header.bindings.profile")
    _hex(bindings["source_commit"], "$header.bindings.source_commit", LOWER_HEX_40)

    graph = _object(header["graph"], "$header.graph", GRAPH_KEYS)
    if _string(graph["kind"], "$header.graph.kind") != "dispatch":
        _fail("GRAPH_KIND", "$header.graph.kind", "only real dispatch graphs are accepted")
    if _string(graph["scope"], "$header.graph.scope") not in {"decoder-main", "decoder-mtp", "encoder"}:
        _fail("GRAPH_SCOPE", "$header.graph.scope", "unsupported graph scope")
    _integer(graph["type_id"], "$header.graph.type_id", 0)
    _string(graph["type_name"], "$header.graph.type_name")

    model = _object(header["model"], "$header.model", MODEL_KEYS)
    for key in ("arch_id", "type_id"):
        _integer(model[key], f"$header.model.{key}", 0)
    for key in ("arch_name", "description", "model_name", "type_name"):
        _string(model[key], f"$header.model.{key}")
    for key in ("model_size", "n_embd", "n_elements", "n_layer", "n_layer_all", "n_tensors", "n_vocab"):
        _integer(model[key], f"$header.model.{key}", 1)
    _integer(model["n_layer_nextn"], "$header.model.n_layer_nextn", 0)
    if model["n_layer"] + model["n_layer_nextn"] != model["n_layer_all"]:
        _fail("MODEL_LAYERS", "$header.model", "n_layer + n_layer_nextn must equal n_layer_all")
    recurrent = _array(model["recurrent_layers"], "$header.model.recurrent_layers", model["n_layer"])
    for index, value in enumerate(recurrent):
        _boolean(value, f"$header.model.recurrent_layers[{index}]")
    rope_sections = _array(model["rope_sections"], "$header.model.rope_sections", 4)
    for index, value in enumerate(rope_sections):
        _integer(value, f"$header.model.rope_sections[{index}]", 0)
    ssm = _object(model["ssm"], "$header.model.ssm", SSM_KEYS)
    for key in SSM_KEYS:
        _integer(ssm[key], f"$header.model.ssm.{key}", 0)

    runtime = _object(header["runtime"], "$header.runtime", RUNTIME_KEYS)
    bool_keys = {
        "auto_fa", "auto_fhc", "auto_fgdn", "auto_flid", "causal_attn", "collect_only", "embeddings",
        "embeddings_nextn", "embeddings_nextn_masked", "flash_attn",
        "fused_dsv4_hc_comb", "fused_dsv4_hc_post", "fused_dsv4_hc_pre", "fused_gdn_ar", "fused_gdn_ch",
        "fused_lid", "graph_reuse_disable", "has_memory", "has_memory_context", "kv_unified", "offload_kqv",
        "op_offload", "pipeline_parallel", "warmup",
    }
    for key in bool_keys:
        _boolean(runtime[key], f"$header.runtime.{key}")
    if runtime["collect_only"] is not True or runtime["graph_reuse_disable"] is not True:
        _fail("COLLECT_MODE", "$header.runtime", "collect_only and graph_reuse_disable must both be true")
    nonnegative_keys = {
        "context_type", "n_batch", "n_ctx", "n_ctx_orig_yarn", "n_ctx_seq", "n_outputs", "n_outputs_max",
        "n_outputs_max_per_seq", "n_rs_seq", "n_seq_max", "n_ubatch", "pooling_type", "sampler_count",
    }
    for key in nonnegative_keys:
        _integer(runtime[key], f"$header.runtime.{key}", 0)
    for key in ("n_threads", "n_threads_batch", "nextn_layer_offset"):
        _integer(runtime[key], f"$header.runtime.{key}")
    for key in (
        "rope_freq_base_f32", "rope_freq_scale_f32", "yarn_attn_factor_f32", "yarn_beta_fast_f32",
        "yarn_beta_slow_f32", "yarn_ext_factor_f32",
    ):
        _hex(runtime[key], f"$header.runtime.{key}", LOWER_HEX_8)
    layer_inputs = _array(runtime["embeddings_layer_inp"], "$header.runtime.embeddings_layer_inp", model["n_layer"] + 1)
    for index, value in enumerate(layer_inputs):
        _boolean(value, f"$header.runtime.embeddings_layer_inp[{index}]")
    ubatch = _object(runtime["ubatch"], "$header.runtime.ubatch", UBATCH_KEYS)
    for key in ("has_embd", "has_output", "has_token"):
        _boolean(ubatch[key], f"$header.runtime.ubatch.{key}")
    for key in ("b_equal_seqs", "n_pos", "n_seq_tokens", "n_seqs", "n_seqs_unq", "n_tokens"):
        _integer(ubatch[key], f"$header.runtime.ubatch.{key}", 0)
    if ubatch["n_tokens"] <= 0 or ubatch["n_seqs"] <= 0 or ubatch["n_seq_tokens"] <= 0:
        _fail("UBATCH_EMPTY", "$header.runtime.ubatch", "dispatch ubatch must be non-empty")
    if ubatch["n_tokens"] != ubatch["n_seq_tokens"] * ubatch["n_seqs"]:
        _fail("UBATCH_SHAPE", "$header.runtime.ubatch", "n_tokens must equal n_seq_tokens*n_seqs")
    return target_dispatch


def _validate_ref(value: Any, path: str) -> tuple[str, int] | None:
    if value is None:
        return None
    ref = _object(value, path, {"kind", "index"})
    kind = _string(ref["kind"], path + ".kind")
    if kind not in {"node", "external"}:
        _fail("EDGE_KIND", path + ".kind", "expected node or external")
    return kind, _integer(ref["index"], path + ".index", 0)


def _validate_descriptor(value: Any, path: str) -> dict[str, Any]:
    descriptor = _object(value, path, DESCRIPTOR_KEYS)
    _integer(descriptor["flags"], path + ".flags", 0, 0x7FFFFFFF)
    _string(descriptor["name"], path + ".name", nonempty=False)
    nb = _array(descriptor["nb"], path + ".nb", 4)
    ne = _array(descriptor["ne"], path + ".ne", 4)
    for index, value_nb in enumerate(nb):
        _integer(value_nb, f"{path}.nb[{index}]", 0)
    # GGML deliberately permits zero-length tensors.  Qwen3.5 uses them for
    # empty state views/copies, so zero is part of the frozen descriptor
    # identity rather than a malformed dimension.  Negative dimensions remain
    # invalid and fail closed.
    for index, value_ne in enumerate(ne):
        _integer(value_ne, f"{path}.ne[{index}]", 0)
    _string(descriptor["op_desc"], path + ".op_desc")
    _integer(descriptor["op_id"], path + ".op_id", 0)
    _string(descriptor["op_name"], path + ".op_name")
    _hex(descriptor["op_params_hex"], path + ".op_params_hex", LOWER_HEX_128)
    _integer(descriptor["type_id"], path + ".type_id", 0)
    _string(descriptor["type_name"], path + ".type_name")
    view_offs = _integer(descriptor["view_offs"], path + ".view_offs", 0)
    view_src = _validate_ref(descriptor["view_src"], path + ".view_src")
    if view_src is None and view_offs != 0:
        _fail("VIEW_OFFSET", path, "view_offs must be zero when view_src is null")
    return descriptor


def _validate_sources(value: Any, path: str) -> list[dict[str, Any]]:
    sources = _array(value, path)
    if len(sources) > 10:
        _fail("EDGE_COUNT", path, "more than GGML_MAX_SRC edges")
    previous_slot = -1
    for index, source_value in enumerate(sources):
        source_path = f"{path}[{index}]"
        source = _object(source_value, source_path, {"slot", "ref", "descriptor"})
        slot = _integer(source["slot"], source_path + ".slot", 0, 9)
        if slot <= previous_slot:
            _fail("EDGE_ORDER", source_path + ".slot", "source slots must be strictly increasing")
        previous_slot = slot
        if _validate_ref(source["ref"], source_path + ".ref") is None:
            _fail("EDGE_NULL", source_path + ".ref", "source ref cannot be null")
        _validate_descriptor(source["descriptor"], source_path + ".descriptor")
    return sources


def _validate_semantic(value: Any, path: str, header: dict[str, Any], descriptor: dict[str, Any]) -> dict[str, Any]:
    semantic = _object(value, path, SEMANTIC_KEYS)
    if _string(semantic["schema"], path + ".schema") != SEMANTIC_SCHEMA:
        _fail("SEMANTIC_SCHEMA", path + ".schema", f"expected {SEMANTIC_SCHEMA}")
    if _string(semantic["source_commit"], path + ".source_commit") != header["bindings"]["source_commit"]:
        _fail("SEMANTIC_BINDING", path + ".source_commit", "does not match header")
    if _string(semantic["profile"], path + ".profile") != header["bindings"]["profile"]:
        _fail("SEMANTIC_BINDING", path + ".profile", "does not match header")
    if _string(semantic["graph_scope"], path + ".graph_scope") != header["graph"]["scope"]:
        _fail("SEMANTIC_BINDING", path + ".graph_scope", "does not match header")
    path_text = _string(semantic["path"], path + ".path")
    role = _string(semantic["role"], path + ".role")
    if not path_text.endswith("/" + role):
        _fail("SEMANTIC_PATH", path + ".path", "path must terminate in role")
    layer_kind = _string(semantic["layer_kind"], path + ".layer_kind")
    layer_index = semantic["layer_index"]
    if layer_index is None:
        if layer_kind not in {"global", "mixed"}:
            _fail("SEMANTIC_LAYER", path, "null layer_index requires global or mixed")
    else:
        layer_index = _integer(layer_index, path + ".layer_index", 0)
        model = header["model"]
        if layer_index >= model["n_layer_all"]:
            _fail("SEMANTIC_LAYER", path + ".layer_index", "outside model layers")
        expected_kind = (
            ("recurrent" if model["recurrent_layers"][layer_index] else "full-attention")
            if layer_index < model["n_layer"]
            else "nextn"
        )
        if layer_kind != expected_kind:
            _fail("SEMANTIC_LAYER", path + ".layer_kind", f"expected {expected_kind}")
    if _string(semantic["op"], path + ".op") != descriptor["op_name"]:
        _fail("SEMANTIC_OP", path + ".op", "does not match descriptor op_name")
    if _string(semantic["subtype"], path + ".subtype") != descriptor["op_desc"]:
        _fail("SEMANTIC_OP", path + ".subtype", "does not match descriptor op_desc")
    _integer(semantic["occurrence"], path + ".occurrence", 0)
    return semantic


def classify_op(op_name: str) -> str:
    memberships = int(op_name in METADATA_OPS) + int(op_name in MOVER_OPS)
    if memberships > 1:  # pragma: no cover - constant-set invariant
        raise RuntimeError("operator belongs to multiple classes")
    if op_name in METADATA_OPS:
        return "metadata"
    if op_name in MOVER_OPS:
        return "mover"
    return "compute"


@dataclass(frozen=True)
class Expectations:
    raw_sha256: str | None = None
    manifest_sha256: str | None = None
    model_sha256: str | None = None
    source_commit: str | None = None
    profile: str | None = None
    numeric_profile: str | None = None
    graph_scope: str | None = None
    graph_type_name: str | None = None
    target_dispatch: int | None = None
    flash_attn: bool | None = None
    fused_gdn_ar: bool | None = None
    fused_gdn_ch: bool | None = None
    fused_lid: bool | None = None
    fused_dsv4_hc_pre: bool | None = None
    fused_dsv4_hc_comb: bool | None = None
    fused_dsv4_hc_post: bool | None = None
    auto_fa: bool | None = None
    auto_fgdn: bool | None = None
    auto_flid: bool | None = None
    auto_fhc: bool | None = None
    n_batch: int | None = None
    n_ubatch: int | None = None
    n_rs_seq: int | None = None
    ubatch_tokens: int | None = None
    node_count: int | None = None
    compute_count: int | None = None
    mover_count: int | None = None
    metadata_count: int | None = None


@dataclass(frozen=True)
class ManifestResult:
    raw_sha256: str
    manifest_sha256: str
    counts: dict[str, int]
    envelope: dict[str, Any]
    json_bytes: bytes
    jsonl_bytes: bytes


@dataclass(frozen=True)
class ManifestBundleResult:
    bundle_sha256: str
    counts: dict[str, int]
    envelope: dict[str, Any]
    json_bytes: bytes


def _manifest_payload(envelope: Mapping[str, Any], label: str) -> Mapping[str, Any]:
    if type(envelope) is not dict:
        _fail("BUNDLE_SCHEMA", f"${label}", "manifest envelope must be an object")
    _object(envelope, f"${label}", {"schema", "manifest_sha256", "manifest"})
    if envelope.get("schema") != ENVELOPE_SCHEMA:
        _fail("BUNDLE_SCHEMA", f"${label}.schema", f"expected {ENVELOPE_SCHEMA}")
    claimed = _hex(
        envelope.get("manifest_sha256"),
        f"${label}.manifest_sha256",
        LOWER_HEX_64,
    )
    payload = envelope.get("manifest")
    if type(payload) is not dict:
        _fail("BUNDLE_SCHEMA", f"${label}.manifest", "manifest payload must be an object")
    _object(
        payload,
        f"${label}.manifest",
        {"schema", "raw_schema", "raw_sha256", "header", "counts", "nodes", "external_tensors", "raw_footer"},
    )
    if payload.get("schema") != MANIFEST_SCHEMA or payload.get("raw_schema") != RAW_SCHEMA:
        _fail("BUNDLE_SCHEMA", f"${label}.manifest.schema", "manifest/raw schema mismatch")
    actual = sha256_bytes(canonical_bytes(payload))
    if actual != claimed:
        _fail(
            "BUNDLE_MANIFEST_SHA256",
            f"${label}.manifest_sha256",
            f"claimed={claimed} recomputed={actual}",
        )
    return payload


def _node_identity_audit(node: Any, label: str, expected_index: int) -> Mapping[str, Any]:
    if type(node) is not dict:
        _fail("BUNDLE_NODE", label, "node must be an object")
    _object(
        node,
        label,
        {
            "record_kind", "index", "semantic_key", "descriptor", "sources",
            "classification", "canonical_id", "descriptor_sha256",
        },
    )
    if node.get("record_kind") != "node" or node.get("index") != expected_index:
        _fail("BUNDLE_NODE_INDEX", label, f"expected node index {expected_index}")
    canonical_id = _hex(node.get("canonical_id"), label + ".canonical_id", LOWER_HEX_64)
    if canonical_id != sha256_bytes(canonical_bytes(node.get("semantic_key"))):
        _fail("BUNDLE_CANONICAL_ID", label + ".canonical_id", "semantic identity mismatch")
    descriptor_sha256 = _hex(
        node.get("descriptor_sha256"), label + ".descriptor_sha256", LOWER_HEX_64
    )
    actual_descriptor_sha256 = sha256_bytes(canonical_bytes({
        "descriptor": node.get("descriptor"),
        "sources": node.get("sources"),
    }))
    if descriptor_sha256 != actual_descriptor_sha256:
        _fail(
            "BUNDLE_DESCRIPTOR_SHA256",
            label + ".descriptor_sha256",
            f"claimed={descriptor_sha256} recomputed={actual_descriptor_sha256}",
        )
    return node


def _zero_descriptor_from(bootstrap: Mapping[str, Any], state: str) -> dict[str, Any]:
    expected_ne0 = 18432 if state == "r" else 262144
    expected_nb = 73728 if state == "r" else 1048576
    if bootstrap.get("ne") != [expected_ne0, 1, 1, 1]:
        _fail("BUNDLE_ZERO_BOOTSTRAP", "$bundle.nodes", f"cache_{state} ne mismatch")
    if bootstrap.get("nb") != [4, expected_nb, expected_nb, expected_nb]:
        _fail("BUNDLE_ZERO_BOOTSTRAP", "$bundle.nodes", f"cache_{state} nb mismatch")
    steady = copy.deepcopy(dict(bootstrap))
    steady["ne"] = [0, 1, 1, 1]
    steady["nb"] = [4, 0, 0, 0]
    return steady


def _audit_repeat_dispatch_prefix(dispatches: Sequence[int]) -> None:
    """Require a complete steady-state capture prefix beginning at dispatch 3."""

    if not dispatches:
        return
    expected = list(range(3, dispatches[-1] + 1))
    if list(dispatches) != expected:
        missing = sorted(set(expected) - set(dispatches))
        _fail(
            "BUNDLE_REPEAT_GAP",
            "$bundle.steady_repeats",
            f"dispatches must be contiguous from 3 through {dispatches[-1]}; missing={missing}",
        )


def audit_manifest_bundle_objects(
    bootstrap_envelope: Mapping[str, Any],
    steady_envelope: Mapping[str, Any],
    steady_repeat_envelopes: Sequence[Mapping[str, Any]] = (),
) -> ManifestBundleResult:
    """Audit dispatch 1/2 plus an optional contiguous dispatch 3..N repeat prefix.

    The comparison is intentionally stronger than comparing the two frozen
    content hashes: every unchanged node is compared as a complete canonical
    record, and each permitted cache zero transition is reconstructed from the
    bootstrap descriptor field by field.
    """

    bootstrap = _manifest_payload(bootstrap_envelope, "bootstrap")
    steady = _manifest_payload(steady_envelope, "steady")

    if bootstrap.get("raw_sha256") != BOOTSTRAP_RAW_SHA256:
        _fail("BUNDLE_BOOTSTRAP_RAW", "$bootstrap.manifest.raw_sha256", "frozen dispatch-1 raw identity mismatch")
    if steady.get("raw_sha256") != STEADY_RAW_SHA256:
        _fail("BUNDLE_STEADY_RAW", "$steady.manifest.raw_sha256", "frozen dispatch-2 raw identity mismatch")

    if bootstrap.get("counts") != QWEN_COUNTS or steady.get("counts") != QWEN_COUNTS:
        _fail("BUNDLE_COUNTS", "$bundle.counts", "dispatch census mismatch")
    bootstrap_header = bootstrap.get("header")
    steady_header = steady.get("header")
    if type(bootstrap_header) is not dict or type(steady_header) is not dict:
        _fail("BUNDLE_HEADER", "$bundle.header", "header missing")
    if set(bootstrap_header) & HEADER_DISPATCH_KEYS:
        _fail("BUNDLE_BOOTSTRAP_DISPATCH", "$bootstrap.manifest.header", "dispatch 1 must retain legacy header identity")
    if {key: steady_header.get(key) for key in HEADER_DISPATCH_KEYS} != {
        "target_dispatch": 2,
        "observed_dispatch": 2,
    }:
        _fail("BUNDLE_STEADY_DISPATCH", "$steady.manifest.header", "dispatch 2 target/observed identity mismatch")
    steady_header_common = copy.deepcopy(steady_header)
    for key in HEADER_DISPATCH_KEYS:
        steady_header_common.pop(key, None)
    if bootstrap_header != steady_header_common:
        _fail("BUNDLE_HEADER_DRIFT", "$bundle.header", "non-dispatch header field changed")
    if bootstrap.get("external_tensors") != steady.get("external_tensors"):
        _fail("BUNDLE_EXTERNAL_DRIFT", "$bundle.external_tensors", "external tensor registry changed")
    if bootstrap.get("raw_footer") != steady.get("raw_footer"):
        _fail("BUNDLE_FOOTER_DRIFT", "$bundle.raw_footer", "raw footer changed")

    bootstrap_nodes = bootstrap.get("nodes")
    steady_nodes = steady.get("nodes")
    if type(bootstrap_nodes) is not list or type(steady_nodes) is not list:
        _fail("BUNDLE_NODES", "$bundle.nodes", "node lists missing")
    if len(bootstrap_nodes) != QWEN_COUNTS["total"] or len(steady_nodes) != len(bootstrap_nodes):
        _fail("BUNDLE_NODE_COUNT", "$bundle.nodes", "expected two 1714-node graphs")

    observed_delta_keys: set[tuple[int, str, str]] = set()
    descriptor_deltas: list[dict[str, Any]] = []
    zero_scale_nodes: list[dict[str, Any]] = []
    seen_bootstrap_ids: set[str] = set()
    seen_steady_ids: set[str] = set()
    node_pairs: dict[int, tuple[Mapping[str, Any], Mapping[str, Any]]] = {}

    for index, (bootstrap_node_raw, steady_node_raw) in enumerate(zip(bootstrap_nodes, steady_nodes)):
        bootstrap_node = _node_identity_audit(bootstrap_node_raw, f"$bootstrap.nodes[{index}]", index)
        steady_node = _node_identity_audit(steady_node_raw, f"$steady.nodes[{index}]", index)
        bootstrap_id = bootstrap_node["canonical_id"]
        steady_id = steady_node["canonical_id"]
        if bootstrap_id in seen_bootstrap_ids or steady_id in seen_steady_ids:
            _fail("BUNDLE_DUPLICATE_ID", f"$bundle.nodes[{index}]", "canonical ID duplicated")
        seen_bootstrap_ids.add(bootstrap_id)
        seen_steady_ids.add(steady_id)
        if bootstrap_id != steady_id:
            _fail("BUNDLE_ID_DRIFT", f"$bundle.nodes[{index}]", "canonical ID/index mapping changed")
        node_pairs[index] = (bootstrap_node, steady_node)
        if bootstrap_node == steady_node:
            continue

        bootstrap_descriptor = bootstrap_node.get("descriptor")
        steady_descriptor = steady_node.get("descriptor")
        if type(bootstrap_descriptor) is not dict or type(steady_descriptor) is not dict:
            _fail("BUNDLE_DESCRIPTOR", f"$bundle.nodes[{index}]", "descriptor missing")
        match = QWEN_ZERO_NODE_RE.fullmatch(str(bootstrap_descriptor.get("name", "")))
        if match is None:
            _fail("BUNDLE_UNEXPECTED_DELTA", f"$bundle.nodes[{index}]", "node outside cache zero allowlist changed")
        state, layer_text, scale_suffix = match.groups()
        layer = int(layer_text)
        op = "SCALE" if scale_suffix else "VIEW"
        if bootstrap_descriptor.get("op_name") != op or steady_descriptor.get("op_name") != op:
            _fail("BUNDLE_ZERO_OP", f"$bundle.nodes[{index}]", f"expected {op}")
        expected_classification = "compute" if op == "SCALE" else "metadata"
        if bootstrap_node.get("classification") != expected_classification or steady_node.get("classification") != expected_classification:
            _fail("BUNDLE_ZERO_CLASS", f"$bundle.nodes[{index}]", "owner classification changed")

        bootstrap_core = copy.deepcopy(dict(bootstrap_node))
        steady_core = copy.deepcopy(dict(steady_node))
        for core in (bootstrap_core, steady_core):
            core.pop("descriptor", None)
            core.pop("descriptor_sha256", None)
            core.pop("sources", None)
        if bootstrap_core != steady_core:
            _fail("BUNDLE_ZERO_IDENTITY", f"$bundle.nodes[{index}]", "non-descriptor node identity changed")
        if steady_descriptor != _zero_descriptor_from(bootstrap_descriptor, state):
            _fail("BUNDLE_ZERO_DESCRIPTOR", f"$steady.nodes[{index}].descriptor", "zero variant changed fields other than ne/nb or has wrong zero shape")

        bootstrap_sources = bootstrap_node.get("sources")
        steady_sources = steady_node.get("sources")
        if op == "VIEW":
            if bootstrap_sources != steady_sources:
                _fail("BUNDLE_ZERO_VIEW_SOURCE", f"$bundle.nodes[{index}].sources", "VIEW source descriptor changed")
        else:
            if type(bootstrap_sources) is not list or type(steady_sources) is not list or len(bootstrap_sources) != 1 or len(steady_sources) != 1:
                _fail("BUNDLE_ZERO_SCALE_SOURCE", f"$bundle.nodes[{index}].sources", "SCALE must have one source")
            view_index = index - 1
            expected_ref = {"kind": "node", "index": view_index}
            if bootstrap_sources[0].get("slot") != 0 or steady_sources[0].get("slot") != 0 or bootstrap_sources[0].get("ref") != expected_ref or steady_sources[0].get("ref") != expected_ref:
                _fail("BUNDLE_ZERO_SCALE_SOURCE", f"$bundle.nodes[{index}].sources", "SCALE source binding changed")
            bootstrap_view, steady_view = node_pairs.get(view_index, ({}, {}))
            if bootstrap_sources[0].get("descriptor") != bootstrap_view.get("descriptor") or steady_sources[0].get("descriptor") != steady_view.get("descriptor"):
                _fail("BUNDLE_ZERO_SCALE_SOURCE", f"$bundle.nodes[{index}].sources", "SCALE source is not the paired VIEW descriptor")

        delta_key = (layer, state, op)
        if delta_key in observed_delta_keys:
            _fail("BUNDLE_DUPLICATE_ZERO", f"$bundle.nodes[{index}]", f"duplicate {delta_key}")
        observed_delta_keys.add(delta_key)
        delta = {
            "canonical_id": bootstrap_id,
            "index": index,
            "layer": layer,
            "state": state,
            "op": op,
            "bootstrap_descriptor_sha256": bootstrap_node["descriptor_sha256"],
            "steady_descriptor_sha256": steady_node["descriptor_sha256"],
        }
        descriptor_deltas.append(delta)
        if op == "SCALE":
            zero_scale_nodes.append({
                **delta,
                "profile_id": 17 if state == "r" else 18,
                "dst_name": steady_descriptor["name"],
                "src0_name": steady_sources[0]["descriptor"]["name"],
            })

    expected_delta_keys = {
        (layer, state, op)
        for layer in QWEN_RECURRENT_LAYERS
        for state in ("r", "s")
        for op in ("VIEW", "SCALE")
    }
    if observed_delta_keys != expected_delta_keys:
        missing = sorted(expected_delta_keys - observed_delta_keys)
        extra = sorted(observed_delta_keys - expected_delta_keys)
        _fail("BUNDLE_ZERO_SET", "$bundle.nodes", f"missing={missing} extra={extra}")
    if len(descriptor_deltas) != 72 or len(zero_scale_nodes) != 36:
        _fail("BUNDLE_ZERO_COUNT", "$bundle.nodes", "expected 72 descriptor deltas and 36 SCALE zero variants")

    # Optional later-dispatch captures close the multi-token graph-reuse
    # assumption.  Their raw/content identities are recorded rather than
    # pre-frozen, but their complete graph payload must equal dispatch 2 after
    # removing only collector dispatch metadata and raw identity fields.
    repeat_rows: list[dict[str, Any]] = []
    repeat_dispatches: set[int] = set()
    for repeat_index, repeat_envelope in enumerate(steady_repeat_envelopes):
        label = f"steady_repeat[{repeat_index}]"
        repeat = _manifest_payload(repeat_envelope, label)
        repeat_header = repeat.get("header")
        if type(repeat_header) is not dict:
            _fail("BUNDLE_REPEAT_HEADER", f"${label}.manifest.header", "header missing")
        target = repeat_header.get("target_dispatch")
        observed = repeat_header.get("observed_dispatch")
        if type(target) is not int or target < 3 or observed != target:
            _fail("BUNDLE_REPEAT_DISPATCH", f"${label}.manifest.header", "target=observed>=3 required")
        if target in repeat_dispatches:
            _fail("BUNDLE_REPEAT_DUPLICATE", f"${label}.manifest.header", f"duplicate dispatch {target}")
        repeat_dispatches.add(target)
        repeat_header_common = copy.deepcopy(repeat_header)
        for key in HEADER_DISPATCH_KEYS:
            repeat_header_common.pop(key, None)
        if repeat_header_common != steady_header_common:
            _fail("BUNDLE_REPEAT_HEADER_DRIFT", f"${label}.manifest.header", "non-dispatch header field changed")
        if repeat.get("counts") != steady.get("counts"):
            _fail("BUNDLE_REPEAT_COUNTS", f"${label}.manifest.counts", "steady census changed")
        if repeat.get("nodes") != steady_nodes:
            _fail("BUNDLE_REPEAT_NODE_DRIFT", f"${label}.manifest.nodes", "dispatch is not byte-identical to steady nodes")
        if repeat.get("external_tensors") != steady.get("external_tensors"):
            _fail("BUNDLE_REPEAT_EXTERNAL_DRIFT", f"${label}.manifest.external_tensors", "external tensor registry changed")
        if repeat.get("raw_footer") != steady.get("raw_footer"):
            _fail("BUNDLE_REPEAT_FOOTER_DRIFT", f"${label}.manifest.raw_footer", "raw footer changed")
        repeat_raw_sha256 = _hex(
            repeat.get("raw_sha256"), f"${label}.manifest.raw_sha256", LOWER_HEX_64
        )
        repeat_rows.append({
            "dispatch": target,
            "raw_sha256": repeat_raw_sha256,
            "manifest_sha256": repeat_envelope["manifest_sha256"],
        })
    repeat_rows.sort(key=lambda row: row["dispatch"])
    # A capture of dispatch N only proves that dispatch.  It cannot close the
    # multi-token steady-state claim for dispatches 3..N because an
    # intermediate graph may drift and later converge again.  Therefore a
    # repeat bundle is a contiguous prefix beginning at dispatch 3.
    _audit_repeat_dispatch_prefix([row["dispatch"] for row in repeat_rows])

    if bootstrap_envelope.get("manifest_sha256") != BOOTSTRAP_MANIFEST_SHA256:
        _fail("BUNDLE_BOOTSTRAP_MANIFEST", "$bootstrap.manifest_sha256", "frozen dispatch-1 manifest identity mismatch")
    if steady_envelope.get("manifest_sha256") != STEADY_MANIFEST_SHA256:
        _fail("BUNDLE_STEADY_MANIFEST", "$steady.manifest_sha256", "frozen dispatch-2 manifest identity mismatch")

    counts = {
        "nodes": len(bootstrap_nodes),
        "unchanged_nodes": len(bootstrap_nodes) - len(descriptor_deltas),
        "descriptor_delta_nodes": len(descriptor_deltas),
        "zero_scale_nodes": len(zero_scale_nodes),
        "zero_p17_nodes": sum(row["profile_id"] == 17 for row in zero_scale_nodes),
        "zero_p18_nodes": sum(row["profile_id"] == 18 for row in zero_scale_nodes),
        "steady_repeat_manifests": len(repeat_rows),
    }
    bundle = {
        "schema": BUNDLE_SCHEMA,
        "bootstrap": {
            "dispatch": 1,
            "raw_sha256": BOOTSTRAP_RAW_SHA256,
            "manifest_sha256": BOOTSTRAP_MANIFEST_SHA256,
        },
        "steady": {
            "dispatch": 2,
            "raw_sha256": STEADY_RAW_SHA256,
            "manifest_sha256": STEADY_MANIFEST_SHA256,
        },
        "counts": counts,
        "descriptor_deltas": descriptor_deltas,
        "zero_scale_nodes": zero_scale_nodes,
        "steady_repeats": repeat_rows,
    }
    bundle_sha256 = sha256_bytes(canonical_bytes(bundle))
    envelope = {
        "schema": BUNDLE_ENVELOPE_SCHEMA,
        "bundle_sha256": bundle_sha256,
        "bundle": bundle,
    }
    return ManifestBundleResult(
        bundle_sha256=bundle_sha256,
        counts=counts,
        envelope=envelope,
        json_bytes=canonical_bytes(envelope) + b"\n",
    )


def load_manifest_envelope(path: Path) -> dict[str, Any]:
    try:
        raw = path.read_bytes()
    except OSError as exc:
        _fail("READ", str(path), str(exc))
    if not raw.endswith(b"\n") or b"\r" in raw or raw.startswith(b"\xef\xbb\xbf"):
        _fail("MANIFEST_BYTES", str(path), "canonical UTF-8 JSON plus final LF required")
    try:
        value = json.loads(
            raw.decode("utf-8"),
            object_pairs_hook=_duplicate_checked_object,
            parse_float=_reject_json_real,
            parse_constant=_reject_json_constant,
        )
    except ManifestError:
        raise
    except (UnicodeError, json.JSONDecodeError) as exc:
        _fail("JSON", str(path), str(exc))
    if type(value) is not dict:
        _fail("BUNDLE_SCHEMA", str(path), "manifest envelope must be an object")
    if raw != canonical_bytes(value) + b"\n":
        _fail("MANIFEST_BYTES", str(path), "manifest envelope is not canonical JSON")
    return value


def audit_manifest_bundle_files(
    bootstrap_path: Path,
    steady_path: Path,
    steady_repeat_paths: Sequence[Path] = (),
) -> ManifestBundleResult:
    return audit_manifest_bundle_objects(
        load_manifest_envelope(bootstrap_path),
        load_manifest_envelope(steady_path),
        [load_manifest_envelope(path) for path in steady_repeat_paths],
    )


def validate_raw_bytes(raw: bytes, expectations: Expectations = Expectations()) -> ManifestResult:
    if not raw:
        _fail("RAW_EMPTY", "$raw", "artifact is empty")
    if len(raw) > 256 * 1024 * 1024:
        _fail("RAW_SIZE", "$raw", "artifact exceeds 256 MiB")
    if raw.startswith(b"\xef\xbb\xbf"):
        _fail("RAW_BOM", "$raw", "UTF-8 BOM is forbidden")
    if b"\r" in raw:
        _fail("RAW_NEWLINE", "$raw", "CR is forbidden")
    if not raw.endswith(b"\n"):
        _fail("RAW_NEWLINE", "$raw", "final newline is required")
    raw_sha256 = sha256_bytes(raw)
    if expectations.raw_sha256 is not None and raw_sha256 != expectations.raw_sha256:
        _fail("RAW_SHA256", "$raw", f"expected {expectations.raw_sha256}, got {raw_sha256}")

    raw_lines = raw[:-1].split(b"\n")
    if any(not line for line in raw_lines):
        _fail("RAW_BLANK", "$raw", "blank records are forbidden")
    records = [_parse_record(line, index + 1) for index, line in enumerate(raw_lines)]
    if len(records) < 3:
        _fail("RECORD_COUNT", "$raw", "header, nodes and footer are required")

    header = records[0]
    target_dispatch = _validate_header(header)
    if expectations.target_dispatch is not None and target_dispatch != expectations.target_dispatch:
        _fail(
            "COLLECT_DISPATCH",
            "$header.target_dispatch",
            f"expected {expectations.target_dispatch}, got {target_dispatch}",
        )
    if expectations.graph_scope is not None and header["graph"]["scope"] != expectations.graph_scope:
        _fail(
            "GRAPH_SCOPE",
            "$header.graph.scope",
            f"expected {expectations.graph_scope!r}, got {header['graph']['scope']!r}",
        )
    if expectations.graph_type_name is not None and header["graph"]["type_name"] != expectations.graph_type_name:
        _fail(
            "GRAPH_TYPE",
            "$header.graph.type_name",
            f"expected {expectations.graph_type_name!r}, got {header['graph']['type_name']!r}",
        )
    runtime = header["runtime"]
    expected_runtime = {
        "flash_attn": expectations.flash_attn,
        "fused_gdn_ar": expectations.fused_gdn_ar,
        "fused_gdn_ch": expectations.fused_gdn_ch,
        "fused_lid": expectations.fused_lid,
        "fused_dsv4_hc_pre": expectations.fused_dsv4_hc_pre,
        "fused_dsv4_hc_comb": expectations.fused_dsv4_hc_comb,
        "fused_dsv4_hc_post": expectations.fused_dsv4_hc_post,
        "auto_fa": expectations.auto_fa,
        "auto_fgdn": expectations.auto_fgdn,
        "auto_flid": expectations.auto_flid,
        "auto_fhc": expectations.auto_fhc,
        "n_batch": expectations.n_batch,
        "n_ubatch": expectations.n_ubatch,
        "n_rs_seq": expectations.n_rs_seq,
    }
    for key, expected in expected_runtime.items():
        if expected is not None and runtime[key] != expected:
            _fail("RUNTIME_PROFILE", f"$header.runtime.{key}", f"expected {expected!r}, got {runtime[key]!r}")
    if expectations.ubatch_tokens is not None and header["runtime"]["ubatch"]["n_tokens"] != expectations.ubatch_tokens:
        _fail(
            "UBATCH_TOKENS",
            "$header.runtime.ubatch.n_tokens",
            f"expected {expectations.ubatch_tokens}, got {header['runtime']['ubatch']['n_tokens']}",
        )
    node_count = header["node_count"]
    if expectations.node_count is not None and node_count != expectations.node_count:
        _fail("NODE_COUNT", "$header.node_count", f"expected {expectations.node_count}, got {node_count}")
    bindings = header["bindings"]
    expected_bindings = {
        "model_sha256": expectations.model_sha256,
        "source_commit": expectations.source_commit,
        "profile": expectations.profile,
        "numeric_profile": expectations.numeric_profile,
    }
    for key, expected in expected_bindings.items():
        if expected is not None and bindings[key] != expected:
            _fail("BINDING", f"$header.bindings.{key}", f"expected {expected!r}, got {bindings[key]!r}")

    if len(records) < node_count + 2:
        _fail("RECORD_COUNT", "$raw", "fewer records than header node_count")
    nodes: list[dict[str, Any]] = []
    occurrence_next: dict[bytes, int] = {}
    stable_ids: set[str] = set()
    for index in range(node_count):
        path = f"$nodes[{index}]"
        node = _object(records[index + 1], path, {"record_kind", "index", "semantic_key", "descriptor", "sources"})
        if _string(node["record_kind"], path + ".record_kind") != "node":
            _fail("RECORD_KIND", path + ".record_kind", "expected node")
        if _integer(node["index"], path + ".index", 0) != index:
            _fail("NODE_INDEX", path + ".index", f"expected {index}")
        descriptor = _validate_descriptor(node["descriptor"], path + ".descriptor")
        semantic = _validate_semantic(node["semantic_key"], path + ".semantic_key", header, descriptor)
        _validate_sources(node["sources"], path + ".sources")

        occurrence_base = {key: value for key, value in semantic.items() if key != "occurrence"}
        occurrence_key = canonical_bytes(occurrence_base)
        expected_occurrence = occurrence_next.get(occurrence_key, 0)
        if semantic["occurrence"] != expected_occurrence:
            _fail("SEMANTIC_OCCURRENCE", path + ".semantic_key.occurrence", f"expected {expected_occurrence}")
        occurrence_next[occurrence_key] = expected_occurrence + 1
        stable_id = sha256_bytes(canonical_bytes(semantic))
        if stable_id in stable_ids:
            _fail("STABLE_ID_DUPLICATE", path + ".semantic_key", stable_id)
        stable_ids.add(stable_id)
        nodes.append(node)

    footer = records[-1]
    footer_path = "$footer"
    _object(footer, footer_path, FOOTER_KEYS)
    if _string(footer["record_kind"], footer_path + ".record_kind") != "footer":
        _fail("RECORD_KIND", footer_path + ".record_kind", "expected footer")
    if _string(footer["schema"], footer_path + ".schema") != RAW_SCHEMA:
        _fail("SCHEMA_VERSION", footer_path + ".schema", f"expected {RAW_SCHEMA}")
    if _boolean(footer["complete"], footer_path + ".complete") is not True:
        _fail("ARTIFACT_INCOMPLETE", footer_path + ".complete", "must be true")
    if _boolean(footer["compute_started"], footer_path + ".compute_started") is not False:
        _fail("CPU_EXECUTION", footer_path + ".compute_started", "compute must not start")
    if _boolean(footer["dispatch_graph_scheduler_allocated"], footer_path + ".dispatch_graph_scheduler_allocated") is not False:
        _fail("SCHEDULER_PHASE", footer_path, "dispatch graph was already scheduler-allocated")
    for key in ("external_tensor_count", "node_count", "record_count", "source_edge_count"):
        _integer(footer[key], footer_path + "." + key, 0)
    if footer["node_count"] != node_count:
        _fail("NODE_COUNT", footer_path + ".node_count", "does not match header")

    external_records_raw = records[node_count + 1:-1]
    if footer["external_tensor_count"] != len(external_records_raw):
        _fail("EXTERNAL_COUNT", footer_path + ".external_tensor_count", "does not match records")
    if footer["record_count"] != len(records):
        _fail("RECORD_COUNT", footer_path + ".record_count", "does not match records")
    external_tensors: list[dict[str, Any]] = []
    for index, record in enumerate(external_records_raw):
        path = f"$external_tensors[{index}]"
        external = _object(record, path, {"record_kind", "index", "descriptor", "sources"})
        if _string(external["record_kind"], path + ":record_kind") != "external_tensor":
            _fail("RECORD_KIND", path + ".record_kind", "expected external_tensor")
        if _integer(external["index"], path + ".index", 0) != index:
            _fail("EXTERNAL_INDEX", path + ".index", f"expected {index}")
        _validate_descriptor(external["descriptor"], path + ".descriptor")
        _validate_sources(external["sources"], path + ".sources")
        external_tensors.append(external)

    registry: dict[tuple[str, int], dict[str, Any]] = {}
    for node in nodes:
        registry[("node", node["index"])] = node
    for external in external_tensors:
        registry[("external", external["index"])] = external

    referenced_externals: set[int] = set()
    source_edge_count = 0
    adjacency: dict[tuple[str, int], list[tuple[str, int]]] = {key: [] for key in registry}
    op_id_to_name: dict[int, str] = {}
    op_name_to_id: dict[str, int] = {}
    type_id_to_name: dict[int, str] = {}
    type_name_to_id: dict[str, int] = {}

    for owner_ref, owner in registry.items():
        descriptor = owner["descriptor"]
        for forward, reverse, number, name in (
            (op_id_to_name, op_name_to_id, descriptor["op_id"], descriptor["op_name"]),
            (type_id_to_name, type_name_to_id, descriptor["type_id"], descriptor["type_name"]),
        ):
            if number in forward and forward[number] != name:
                _fail("ENUM_BIJECTION", f"$registry[{owner_ref}]", f"id {number} maps to multiple names")
            if name in reverse and reverse[name] != number:
                _fail("ENUM_BIJECTION", f"$registry[{owner_ref}]", f"name {name!r} maps to multiple ids")
            forward[number] = name
            reverse[name] = number

        refs: list[tuple[str, int]] = []
        view_ref = _validate_ref(descriptor["view_src"], f"$registry[{owner_ref}].descriptor.view_src")
        if view_ref is not None:
            refs.append(view_ref)
        for source in owner["sources"]:
            source_ref = _validate_ref(source["ref"], f"$registry[{owner_ref}].sources")
            assert source_ref is not None
            refs.append(source_ref)
            source_edge_count += 1
            target = registry.get(source_ref)
            if target is None:
                _fail("EDGE_DANGLING", f"$registry[{owner_ref}].sources", f"missing {source_ref}")
            if source["descriptor"] != target["descriptor"]:
                _fail("EDGE_DESCRIPTOR", f"$registry[{owner_ref}].sources", f"descriptor mismatch for {source_ref}")
            if owner_ref[0] == "node" and source_ref[0] == "node" and source_ref[1] >= owner_ref[1]:
                _fail("EDGE_TOPOLOGY", f"$registry[{owner_ref}].sources", "node source must precede consumer")
        for ref in refs:
            if ref not in registry:
                _fail("EDGE_DANGLING", f"$registry[{owner_ref}]", f"missing {ref}")
            if ref == owner_ref:
                _fail("EDGE_SELF", f"$registry[{owner_ref}]", "self-reference is forbidden")
            adjacency[owner_ref].append(ref)
            if ref[0] == "external":
                referenced_externals.add(ref[1])

    if source_edge_count != footer["source_edge_count"]:
        _fail("EDGE_COUNT", footer_path + ".source_edge_count", f"expected recomputed {source_edge_count}")
    if referenced_externals != set(range(len(external_tensors))):
        _fail("EXTERNAL_CLOSURE", "$external_tensors", "external registry has dangling or unreferenced entries")

    visiting: set[tuple[str, int]] = set()
    visited: set[tuple[str, int]] = set()

    def visit(ref: tuple[str, int]) -> None:
        if ref in visited:
            return
        if ref in visiting:
            _fail("EDGE_CYCLE", f"$registry[{ref}]", "source/view graph contains a cycle")
        visiting.add(ref)
        for target in adjacency[ref]:
            visit(target)
        visiting.remove(ref)
        visited.add(ref)

    for registry_ref in registry:
        visit(registry_ref)

    counts = {"total": node_count, "compute": 0, "mover": 0, "metadata": 0, "external_tensors": len(external_tensors), "source_edges": source_edge_count}
    canonical_nodes: list[dict[str, Any]] = []
    for node in nodes:
        canonical_node = copy.deepcopy(node)
        classification = classify_op(node["descriptor"]["op_name"])
        counts[classification] += 1
        canonical_node["classification"] = classification
        canonical_node["canonical_id"] = sha256_bytes(canonical_bytes(node["semantic_key"]))
        canonical_node["descriptor_sha256"] = sha256_bytes(canonical_bytes({
            "descriptor": node["descriptor"],
            "sources": node["sources"],
        }))
        canonical_nodes.append(canonical_node)
    if counts["compute"] + counts["mover"] + counts["metadata"] != node_count:
        _fail("CLASSIFICATION", "$counts", "classes are not exhaustive")

    expected_counts = {
        "compute": expectations.compute_count,
        "mover": expectations.mover_count,
        "metadata": expectations.metadata_count,
    }
    for key, expected in expected_counts.items():
        if expected is not None and counts[key] != expected:
            _fail("CLASS_COUNT", f"$counts.{key}", f"expected {expected}, got {counts[key]}")

    manifest = {
        "schema": MANIFEST_SCHEMA,
        "raw_schema": RAW_SCHEMA,
        "raw_sha256": raw_sha256,
        "header": copy.deepcopy(header),
        "counts": counts,
        "nodes": canonical_nodes,
        "external_tensors": copy.deepcopy(external_tensors),
        "raw_footer": copy.deepcopy(footer),
    }
    manifest_sha256 = sha256_bytes(canonical_bytes(manifest))
    if expectations.manifest_sha256 is not None and manifest_sha256 != expectations.manifest_sha256:
        _fail("MANIFEST_SHA256", "$manifest", f"expected {expectations.manifest_sha256}, got {manifest_sha256}")
    envelope = {"schema": ENVELOPE_SCHEMA, "manifest_sha256": manifest_sha256, "manifest": manifest}
    json_bytes = canonical_bytes(envelope) + b"\n"

    jsonl_records: list[dict[str, Any]] = [{
        "record_kind": "manifest_header",
        "schema": MANIFEST_SCHEMA,
        "manifest_sha256": manifest_sha256,
        "raw_sha256": raw_sha256,
        "header": manifest["header"],
        "counts": counts,
    }]
    jsonl_records.extend(canonical_nodes)
    jsonl_records.extend(copy.deepcopy(external_tensors))
    jsonl_records.append({
        "record_kind": "manifest_footer",
        "schema": MANIFEST_SCHEMA,
        "manifest_sha256": manifest_sha256,
        "complete": True,
        "node_count": node_count,
        "external_tensor_count": len(external_tensors),
    })
    jsonl_bytes = b"\n".join(canonical_bytes(record) for record in jsonl_records) + b"\n"
    return ManifestResult(raw_sha256, manifest_sha256, counts, envelope, json_bytes, jsonl_bytes)


def validate_raw_file(path: Path, expectations: Expectations = Expectations()) -> ManifestResult:
    try:
        raw = path.read_bytes()
    except OSError as exc:
        _fail("READ", str(path), str(exc))
    return validate_raw_bytes(raw, expectations)


def write_exclusive(path: Path, payload: bytes) -> None:
    try:
        descriptor = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    except OSError as exc:
        _fail("WRITE", str(path), str(exc))
    try:
        with os.fdopen(descriptor, "wb") as output:
            output.write(payload)
            output.flush()
            os.fsync(output.fileno())
    except BaseException:
        try:
            path.unlink()
        except OSError:
            pass
        raise


def _optional_nonnegative(value: str) -> int:
    parsed = int(value, 10)
    if parsed < 0:
        raise argparse.ArgumentTypeError("must be nonnegative")
    return parsed


def _optional_positive(value: str) -> int:
    parsed = int(value, 10)
    if parsed <= 0:
        raise argparse.ArgumentTypeError("must be positive")
    return parsed


def _optional_boolean(value: str) -> bool:
    if value == "true":
        return True
    if value == "false":
        return False
    raise argparse.ArgumentTypeError("must be true or false")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)
    validate = subparsers.add_parser("validate", help="validate raw JSONL and optionally publish canonical artifacts")
    validate.add_argument("input", type=Path)
    validate.add_argument("--json-out", type=Path)
    validate.add_argument("--jsonl-out", type=Path)
    validate.add_argument("--expect-raw-sha256")
    validate.add_argument("--expect-manifest-sha256")
    validate.add_argument("--expect-model-sha256")
    validate.add_argument("--expect-source-commit")
    validate.add_argument("--expect-profile")
    validate.add_argument("--expect-numeric-profile")
    validate.add_argument("--expect-graph-scope")
    validate.add_argument("--expect-graph-type-name")
    validate.add_argument("--expect-target-dispatch", type=_optional_positive)
    validate.add_argument("--expect-flash-attn", type=_optional_boolean)
    validate.add_argument("--expect-fused-gdn-ar", type=_optional_boolean)
    validate.add_argument("--expect-fused-gdn-ch", type=_optional_boolean)
    validate.add_argument("--expect-fused-lid", type=_optional_boolean)
    validate.add_argument("--expect-fused-dsv4-hc-pre", type=_optional_boolean)
    validate.add_argument("--expect-fused-dsv4-hc-comb", type=_optional_boolean)
    validate.add_argument("--expect-fused-dsv4-hc-post", type=_optional_boolean)
    validate.add_argument("--expect-auto-fa", type=_optional_boolean)
    validate.add_argument("--expect-auto-fgdn", type=_optional_boolean)
    validate.add_argument("--expect-auto-flid", type=_optional_boolean)
    validate.add_argument("--expect-auto-fhc", type=_optional_boolean)
    validate.add_argument("--expect-n-batch", type=_optional_nonnegative)
    validate.add_argument("--expect-n-ubatch", type=_optional_nonnegative)
    validate.add_argument("--expect-n-rs-seq", type=_optional_nonnegative)
    validate.add_argument("--expect-ubatch-tokens", type=_optional_nonnegative)
    validate.add_argument("--expect-node-count", type=_optional_nonnegative)
    validate.add_argument("--expect-compute-count", type=_optional_nonnegative)
    validate.add_argument("--expect-mover-count", type=_optional_nonnegative)
    validate.add_argument("--expect-metadata-count", type=_optional_nonnegative)
    bundle = subparsers.add_parser(
        "bundle",
        help="audit frozen dispatch 1/2 and an optional contiguous dispatch 3..N repeat prefix",
    )
    bundle.add_argument("bootstrap", type=Path)
    bundle.add_argument("steady", type=Path)
    bundle.add_argument(
        "--steady-repeat-manifest",
        action="append",
        default=[],
        type=Path,
        help=(
            "later dispatch manifest that must be graph-identical to dispatch 2; repeatable, "
            "and all supplied manifests must form the complete dispatch 3..N prefix"
        ),
    )
    bundle.add_argument("--json-out", type=Path)
    bundle.add_argument("--expect-bundle-sha256")
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    try:
        if args.command == "bundle":
            result = audit_manifest_bundle_files(
                args.bootstrap,
                args.steady,
                args.steady_repeat_manifest,
            )
            if args.expect_bundle_sha256 is not None:
                expected = _hex(
                    args.expect_bundle_sha256,
                    "$arguments.expect_bundle_sha256",
                    LOWER_HEX_64,
                )
                if result.bundle_sha256 != expected:
                    _fail(
                        "BUNDLE_SHA256",
                        "$bundle",
                        f"expected {expected}, got {result.bundle_sha256}",
                    )
            if args.json_out is not None:
                write_exclusive(args.json_out, result.json_bytes)
            print(
                "[NPU-GRAPH-MANIFEST-BUNDLE][PASS] "
                f"nodes={result.counts['nodes']} "
                f"unchanged={result.counts['unchanged_nodes']} "
                f"descriptor_deltas={result.counts['descriptor_delta_nodes']} "
                f"zero_scale={result.counts['zero_scale_nodes']} "
                f"p17={result.counts['zero_p17_nodes']} "
                f"p18={result.counts['zero_p18_nodes']} "
                f"steady_repeats={result.counts['steady_repeat_manifests']} "
                f"bundle_sha256={result.bundle_sha256}"
            )
            return 0
        expectations = Expectations(
            raw_sha256=args.expect_raw_sha256,
            manifest_sha256=args.expect_manifest_sha256,
            model_sha256=args.expect_model_sha256,
            source_commit=args.expect_source_commit,
            profile=args.expect_profile,
            numeric_profile=args.expect_numeric_profile,
            graph_scope=args.expect_graph_scope,
            graph_type_name=args.expect_graph_type_name,
            target_dispatch=args.expect_target_dispatch,
            flash_attn=args.expect_flash_attn,
            fused_gdn_ar=args.expect_fused_gdn_ar,
            fused_gdn_ch=args.expect_fused_gdn_ch,
            fused_lid=args.expect_fused_lid,
            fused_dsv4_hc_pre=args.expect_fused_dsv4_hc_pre,
            fused_dsv4_hc_comb=args.expect_fused_dsv4_hc_comb,
            fused_dsv4_hc_post=args.expect_fused_dsv4_hc_post,
            auto_fa=args.expect_auto_fa,
            auto_fgdn=args.expect_auto_fgdn,
            auto_flid=args.expect_auto_flid,
            auto_fhc=args.expect_auto_fhc,
            n_batch=args.expect_n_batch,
            n_ubatch=args.expect_n_ubatch,
            n_rs_seq=args.expect_n_rs_seq,
            ubatch_tokens=args.expect_ubatch_tokens,
            node_count=args.expect_node_count,
            compute_count=args.expect_compute_count,
            mover_count=args.expect_mover_count,
            metadata_count=args.expect_metadata_count,
        )
        result = validate_raw_file(args.input, expectations)
        if args.json_out is not None:
            write_exclusive(args.json_out, result.json_bytes)
        if args.jsonl_out is not None:
            write_exclusive(args.jsonl_out, result.jsonl_bytes)
        print(
            "[NPU-GRAPH-MANIFEST][PASS] "
            f"nodes={result.counts['total']} compute={result.counts['compute']} "
            f"mover={result.counts['mover']} metadata={result.counts['metadata']} "
            f"raw_sha256={result.raw_sha256} manifest_sha256={result.manifest_sha256}"
        )
        return 0
    except ManifestError as exc:
        print(f"[NPU-GRAPH-MANIFEST][FAIL] code={exc.code} path={exc.path} detail={exc.detail}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
