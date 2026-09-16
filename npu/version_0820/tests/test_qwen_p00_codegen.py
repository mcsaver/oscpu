#!/usr/bin/env python3

from __future__ import annotations

import dataclasses
import hashlib
import json
import os
import pathlib
import sys
import unittest


PROJECT_ROOT = pathlib.Path(__file__).resolve().parents[1]
sys.path.insert(0, str(PROJECT_ROOT))

from compiler import npu_artifact  # noqa: E402
from compiler.qwen_p00_codegen import (  # noqa: E402
    P00CodegenError,
    build_p00_graph,
    compile_exact_p00,
)
from compiler.qwen_p00_lowering import NormalizedBuffer, P00Selection  # noqa: E402
from compiler.qwen_weights import RawWeight  # noqa: E402
from scripts.qwen_f32_alu_profiles import PROFILES  # noqa: E402


FIRST_P00 = "1e3dac5ab4a21eb84d4d473de864ce2aa3129e1d4f248ee44d766549a51e6f3f"
FIRST_P00_SOURCE_DESCRIPTOR = (
    "b044be11bc3aed031e294b03ae2fe37db09071cc30f966cc5f522d72b8459dfc"
)
FIRST_P00_WEIGHT_SHA256 = (
    "5cc0802165d8bcf1732815a772436a6cd8c9aa2d546b6ea7c05aa4cb6b5b371d"
)
FIRST_P00_BUNDLE_ID = (
    "a7bfbd7496d40bf376836a18a3fc0ca766d1b278021aaf8ce483e2d91eb62d5a"
)
FIRST_P00_COMMAND_FILE_SHA256 = (
    "8d5eccd464b9aef0fb82674bf73e7732094803e26c5dc05652efceac6aa58afb"
)
FIRST_P00_METADATA_FILE_SHA256 = (
    "abf6502519cdb0b62c33f7e21952e753a0708e2c3d086dceeef0720214841296"
)


def normalized_buffer(
    buffer_id: str,
    *,
    logical_index: int,
    logical_id: str | None,
    logical_hash: str,
    storage_index: int | None = None,
    storage_id: str | None = None,
    storage_hash: str | None = None,
    name: str,
) -> NormalizedBuffer:
    final_storage_index = logical_index if storage_index is None else storage_index
    final_storage_id = logical_id if storage_index is None else storage_id
    final_storage_hash = logical_hash if storage_hash is None else storage_hash
    kind = "external" if logical_id is None else "node"
    storage_kind = "external" if final_storage_id is None else "node"
    return NormalizedBuffer(
        buffer_id=buffer_id,
        logical_origin_kind=kind,
        logical_origin_index=logical_index,
        logical_canonical_id=logical_id,
        logical_descriptor_sha256=logical_hash,
        storage_origin_kind=storage_kind,
        storage_origin_index=final_storage_index,
        storage_canonical_id=final_storage_id,
        storage_descriptor_sha256=final_storage_hash,
        alias_offset=0,
        logical_size=64,
        storage_size=64,
        tensor_name=name,
    )


def synthetic_selection_and_weight() -> tuple[P00Selection, RawWeight]:
    selection = P00Selection(
        manifest_path=pathlib.Path("synthetic/dispatch.manifest.json"),
        source_graph={
            "schema": "qwen-npu-graph-manifest-v2",
            "manifest_sha256": "7" * 64,
            "raw_sha256": "8" * 64,
            "profile": "qwen35-0.8b-b1t1-unfused-nonflash-v5",
            "source_commit": "9" * 40,
            "graph_scope": "decoder-main",
        },
        graph_ir_sha256="6" * 64,
        canonical_id=FIRST_P00,
        manifest_graph_index=30,
        schedule_position=15,
        descriptor_sha256=FIRST_P00_SOURCE_DESCRIPTOR,
        profile=PROFILES[0],
        src0=normalized_buffer(
            "n." + "a" * 52,
            logical_index=29,
            logical_id="2" * 64,
            logical_hash="a" * 64,
            storage_index=28,
            storage_id="3" * 64,
            storage_hash="b" * 64,
            name="alpha-0",
        ),
        src1=normalized_buffer(
            "e." + "b" * 52,
            logical_index=8,
            logical_id=None,
            logical_hash="c" * 64,
            name="blk.0.ssm_dt.bias",
        ),
        dst=normalized_buffer(
            "n." + "c" * 52,
            logical_index=30,
            logical_id=FIRST_P00,
            logical_hash="d" * 64,
            name="node_30",
        ),
    )
    raw = bytes(range(64))
    weight = RawWeight(
        name="blk.0.ssm_dt.bias",
        ggml_type="f32",
        shape=(16,),
        file_offset=1234,
        data=raw,
        sha256=hashlib.sha256(raw).hexdigest(),
    )
    return selection, weight


class QwenP00CodegenTests(unittest.TestCase):
    def test_deterministic_descriptor_workload_and_v3_provenance(self) -> None:
        selection, weight = synthetic_selection_and_weight()
        first = build_p00_graph(selection, weight)
        second = build_p00_graph(selection, weight)
        self.assertEqual(
            npu_artifact.canonical_json_bytes(first),
            npu_artifact.canonical_json_bytes(second),
        )
        bundle = npu_artifact.compile_graph(first)
        loaded = npu_artifact.load_bundle(
            bundle.command_bin, bundle.weights_bin, bundle.metadata_json
        )
        command = loaded.metadata["commands"][0]
        words = loaded.records[0]
        self.assertEqual(first["schema"], "npu-compiler-graph-v3")
        self.assertEqual(loaded.metadata["schema"], "npu-artifact-bundle-v3")
        self.assertEqual(command["node_ids"], [30])
        self.assertEqual(command["cycle_upper_bound"], 9072)
        self.assertEqual(
            command["workload"],
            {
                "schema": "f32-alu-v1",
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
            },
        )
        self.assertEqual(words[0], (0x11 << 32) | 0x514E0010)
        self.assertEqual(words[1] >> 32, 1)
        self.assertNotEqual(words[1] & 0xFFFFFFFF, 0)
        self.assertTrue(all(words[index] != 0 for index in (2, 3, 4)))
        self.assertEqual(words[5] >> 32, 1)
        self.assertEqual(words[5] & 0xFFFFFFFF, 1)
        self.assertEqual(words[8], 0)
        self.assertEqual(words[9], 1 << 32)
        self.assertEqual(words[15], 16)
        self.assertEqual(words[16], 1)
        self.assertEqual(tuple(words[19:23]), (64, 64, 0, 64))
        self.assertEqual(words[25], 0x97)
        provenance = loaded.metadata["provenance"]
        self.assertEqual(provenance["source"]["graph_ir_schema"], "qwen-npu-graph-ir-v1")
        self.assertEqual(provenance["source"]["graph_ir_sha256"], "6" * 64)
        node = provenance["node_bindings"][0]
        self.assertEqual(node["canonical_id"], FIRST_P00)
        self.assertEqual(node["manifest_graph_index"], 30)
        self.assertEqual(node["artifact_schedule_position"], 0)
        self.assertEqual(node["source_schedule_position"], 15)
        self.assertEqual(node["source_descriptor_sha256"], FIRST_P00_SOURCE_DESCRIPTOR)
        self.assertEqual(
            node["command_descriptor_sha256"], command["descriptor_sha256"]
        )
        src0 = next(
            item
            for item in provenance["buffer_bindings"]
            if item["buffer_id"] == selection.src0.buffer_id
        )
        self.assertEqual(src0["origin_index"], 29)
        self.assertEqual(src0["storage_origin_index"], 28)
        self.assertEqual(src0["alias_offset"], 0)
        self.assertEqual(src0["logical_size"], 64)
        self.assertEqual(src0["storage_size"], 64)
        self.assertEqual(bundle.weights_bin[:64], weight.data)

    def test_codegen_rejects_untrusted_weight_and_output_identity(self) -> None:
        selection, weight = synthetic_selection_and_weight()
        corrupt_weight = dataclasses.replace(weight, data=b"x" + weight.data[1:])
        with self.assertRaisesRegex(P00CodegenError, "P00_CODEGEN_WEIGHT"):
            build_p00_graph(selection, corrupt_weight)
        wrong_dst = dataclasses.replace(selection.dst, logical_canonical_id="4" * 64)
        with self.assertRaisesRegex(P00CodegenError, "P00_CODEGEN_OUTPUT"):
            build_p00_graph(dataclasses.replace(selection, dst=wrong_dst), weight)

    @unittest.skipUnless(
        os.environ.get("NPU_QWEN_GRAPH_MANIFEST") and os.environ.get("NPU_QWEN_GGUF"),
        "set NPU_QWEN_GRAPH_MANIFEST and NPU_QWEN_GGUF for the real production slice",
    )
    def test_real_first_p00_compiles_from_manifest_and_raw_gguf(self) -> None:
        compiled = compile_exact_p00(
            pathlib.Path(os.environ["NPU_QWEN_GRAPH_MANIFEST"]),
            FIRST_P00,
            pathlib.Path(os.environ["NPU_QWEN_GGUF"]),
        )
        self.assertEqual(compiled.selection.manifest_graph_index, 30)
        self.assertEqual(compiled.selection.schedule_position, 15)
        self.assertEqual(compiled.weight.name, "blk.0.ssm_dt.bias")
        self.assertEqual(compiled.weight.file_offset, 301891168)
        self.assertEqual(compiled.weight.sha256, FIRST_P00_WEIGHT_SHA256)
        self.assertEqual(compiled.bundle.weights_bin[:64], compiled.weight.data)
        provenance = compiled.verified.metadata["provenance"]
        self.assertEqual(
            provenance["source"]["manifest_sha256"],
            "92d404d308cb9ca6a7741233ab05f8eb07be6659dc833fb99b7cd023958fe48e",
        )
        self.assertEqual(provenance["node_bindings"][0]["canonical_id"], FIRST_P00)
        self.assertEqual(
            provenance["node_bindings"][0]["source_descriptor_sha256"],
            FIRST_P00_SOURCE_DESCRIPTOR,
        )
        metadata = json.loads(compiled.bundle.metadata_json)
        self.assertEqual(metadata["bundle_id"], compiled.verified.metadata["bundle_id"])
        self.assertEqual(metadata["bundle_id"], FIRST_P00_BUNDLE_ID)
        self.assertEqual(
            hashlib.sha256(compiled.bundle.command_bin).hexdigest(),
            FIRST_P00_COMMAND_FILE_SHA256,
        )
        self.assertEqual(
            hashlib.sha256(compiled.bundle.metadata_json).hexdigest(),
            FIRST_P00_METADATA_FILE_SHA256,
        )


if __name__ == "__main__":
    unittest.main()
