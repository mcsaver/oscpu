#!/usr/bin/env python3

from __future__ import annotations

import copy
import importlib.util
import json
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parent.parent
SCRIPT = PROJECT_ROOT / "scripts" / "qwen_graph_manifest.py"
CONTEXT_CPP = PROJECT_ROOT / "third_party" / "llama.cpp" / "src" / "llama-context.cpp"

MODULE_SPEC = importlib.util.spec_from_file_location("qwen_graph_manifest", SCRIPT)
if MODULE_SPEC is None or MODULE_SPEC.loader is None:
    raise RuntimeError("cannot load qwen graph manifest validator")
manifest = importlib.util.module_from_spec(MODULE_SPEC)
sys.modules[MODULE_SPEC.name] = manifest
MODULE_SPEC.loader.exec_module(manifest)


SOURCE_COMMIT = "1" * 40
MODEL_SHA256 = "2" * 64

# The frozen Qwen bundle tests are real-artifact integration tests.  They are
# deliberately opt-in: a developer's unrelated tmp/ history must never decide
# whether the default unit suite passes.  The strict smoke runner should bind
# the artifacts it just collected through these variables.
BUNDLE_ENV_NAMES = (
    "NPU_MANIFEST",
    "NPU_STEADY_MANIFEST",
    "NPU_STEADY_REPEAT_MANIFESTS",
)
BUNDLE_INTEGRATION_REQUESTED = any(name in os.environ for name in BUNDLE_ENV_NAMES)
BUNDLE_INTEGRATION_HELP = (
    "real Qwen bundle integration is opt-in; set NPU_MANIFEST, "
    "NPU_STEADY_MANIFEST, and NPU_STEADY_REPEAT_MANIFESTS (os.pathsep-separated "
    "dispatch-3..dispatch-8 manifest paths)"
)


def optional_env_path(name: str) -> Path | None:
    value = os.environ.get(name)
    return Path(value) if value else None


def env_path_list(name: str) -> tuple[Path, ...]:
    value = os.environ.get(name, "")
    return tuple(Path(item) for item in value.split(os.pathsep) if item)


BOOTSTRAP_MANIFEST_PATH = optional_env_path("NPU_MANIFEST")
STEADY_MANIFEST_PATH = optional_env_path("NPU_STEADY_MANIFEST")
STEADY_REPEAT_MANIFEST_PATHS = env_path_list("NPU_STEADY_REPEAT_MANIFESTS")

EXPECTED_REPEAT_IDENTITIES = {
    3: (
        "1131a4dedaf9430e545cea4516807cb0cac67c357b4c8340d4cf4b21ee877959",
        "1309a6a176a5c1c5627dca7d28c5cf2578ff9c515d5ebc8ca60f1ff21ef766f2",
    ),
    4: (
        "389e60d07ede153efadfc3724aaf8558275041003962c216fa6894bbb0e0929b",
        "1ce4f0735a8131a2198bbebdba8422bf4d86223f41a4b7d73b610bfc4c960259",
    ),
    5: (
        "5bcfa951d47d0ee7c85b2519f9be82eea102b668cf4ec856f55ae804706fccf2",
        "1266d5f928f67e24244ede685acebdd500a54019a2804cd54b0e08aa476bec5e",
    ),
    6: (
        "0b13c7cf1b333bcc3fb233a6e2cd1e129ef4ac34a9839853598a04c40e31b560",
        "59ccc88eeb7f258f189ced86dcc995bd85074cd021b152c44e5bdd7115c1edf8",
    ),
    7: (
        "f5f55fc67d2454c7ddde86b13457500d4627961212dd01e6c31316bc39a6fb75",
        "1091cf6b1c48f11b360e86e804db6fc65c68dded747015753ff1e2f2f8cc0822",
    ),
    8: (
        "6e1493ae53b558bf0058dc5692ea906b50150bbe708f0f2b51fc0b463cb8d37b",
        "0d6a67f2dc30c9a759c3200cb267d3f0c3ab0d91863d68064031a7365b9bcce8",
    ),
}
EXPECTED_REPEAT_FILE_SHA256 = {
    3: "2fa93ebb0e4ea44a3ca85f29693b14f7df6254ea103bb16c218273c6b9bd8e58",
    4: "6c4d5cf1c76692d8e9b922d9eba955f0e9c1eb70a28086bf68c85e6b65c71412",
    5: "5f3d966e508e496a774e06c68e1e9d7bdb51886ec99a94dbdb2ef42aab657bd2",
    6: "ac91396ec9d24a469adf1a25a491dd943c170a3c5b1527a70969904e0b25f68d",
    7: "78b8e66d742955d7b67acf3106973e2f27f203737fbb0986e5ccc4b36cd245a7",
    8: "6e6199a2b2e9fee55b5e41a01be97a4488b094eb6cd6dc2ab23d7889ab8d1d64",
}
EXPECTED_MULTI_REPEAT_BUNDLE_SHA256 = "433686dc48cd927ca930b80c8430beec459080cdfc813cd25d927c47e772695f"


def descriptor(
    *,
    name: str,
    op_id: int,
    op_name: str,
    op_desc: str | None = None,
    view_src: dict[str, object] | None = None,
    view_offs: int = 0,
    op_params_hex: str = "00" * 64,
) -> dict[str, object]:
    return {
        "flags": 16,
        "name": name,
        "nb": [4, 16, 16, 16],
        "ne": [4, 1, 1, 1],
        "op_desc": op_desc or op_name,
        "op_id": op_id,
        "op_name": op_name,
        "op_params_hex": op_params_hex,
        "type_id": 0,
        "type_name": "f32",
        "view_offs": view_offs,
        "view_src": copy.deepcopy(view_src),
    }


def semantic(index: int, role: str, op: str) -> dict[str, object]:
    return {
        "schema": manifest.SEMANTIC_SCHEMA,
        "source_commit": SOURCE_COMMIT,
        "profile": "qwen35-0.8b-token0",
        "graph_scope": "decoder-main",
        "path": f"trunk/layer/0/full-attention/{role}",
        "layer_index": 0,
        "layer_kind": "full-attention",
        "role": role,
        "op": op,
        "subtype": op,
        "occurrence": 0,
    }


def make_records() -> list[dict[str, object]]:
    external_ref = {"kind": "external", "index": 0}
    node0_ref = {"kind": "node", "index": 0}
    node1_ref = {"kind": "node", "index": 1}
    ext_descriptor = descriptor(name="blk.0.weight", op_id=0, op_name="NONE")
    view_descriptor = descriptor(name="view-0", op_id=1, op_name="VIEW", view_src=external_ref)
    copy_descriptor = descriptor(name="copy-0", op_id=2, op_name="CPY")
    mul_descriptor = descriptor(name="mul-0", op_id=3, op_name="MUL")

    header: dict[str, object] = {
        "record_kind": "header",
        "schema": manifest.RAW_SCHEMA,
        "collector_phase": "process_ubatch.post_build.pre_scheduler_alloc",
        "bindings": {
            "model_sha256": MODEL_SHA256,
            "numeric_profile": "ggml-f32-rne-v1",
            "profile": "qwen35-0.8b-token0",
            "source_commit": SOURCE_COMMIT,
        },
        "graph": {"kind": "dispatch", "scope": "decoder-main", "type_id": 0, "type_name": "default"},
        "model": {
            "arch_id": 1,
            "arch_name": "qwen35",
            "description": "qwen35 0.8B q8_0",
            "model_name": "fixture",
            "model_size": 1024,
            "n_embd": 1024,
            "n_elements": 100,
            "n_layer": 1,
            "n_layer_all": 1,
            "n_layer_nextn": 0,
            "n_tensors": 8,
            "n_vocab": 32,
            "recurrent_layers": [False],
            "rope_sections": [11, 11, 10, 0],
            "ssm": {"d_conv": 4, "d_inner": 8, "d_state": 16, "dt_rank": 4, "n_group": 2},
            "type_id": 2,
            "type_name": "0.8B",
        },
        "runtime": {
            "auto_fa": False,
            "auto_fhc": False,
            "auto_fgdn": False,
            "auto_flid": False,
            "causal_attn": True,
            "collect_only": True,
            "context_type": 0,
            "embeddings": False,
            "embeddings_layer_inp": [False, False],
            "embeddings_nextn": False,
            "embeddings_nextn_masked": False,
            "flash_attn": False,
            "fused_dsv4_hc_comb": False,
            "fused_dsv4_hc_post": False,
            "fused_dsv4_hc_pre": False,
            "fused_gdn_ar": False,
            "fused_gdn_ch": False,
            "fused_lid": False,
            "graph_reuse_disable": True,
            "has_memory": True,
            "has_memory_context": True,
            "kv_unified": False,
            "n_batch": 1,
            "n_ctx": 256,
            "n_ctx_orig_yarn": 32768,
            "n_ctx_seq": 256,
            "n_outputs": 1,
            "n_outputs_max": 1,
            "n_outputs_max_per_seq": 1,
            "n_rs_seq": 0,
            "n_seq_max": 1,
            "n_threads": 1,
            "n_threads_batch": 1,
            "n_ubatch": 1,
            "nextn_layer_offset": 0,
            "offload_kqv": False,
            "op_offload": False,
            "pipeline_parallel": False,
            "pooling_type": 0,
            "rope_freq_base_f32": "461c4000",
            "rope_freq_scale_f32": "3f800000",
            "sampler_count": 0,
            "ubatch": {
                "b_equal_seqs": 1,
                "has_embd": False,
                "has_output": True,
                "has_token": True,
                "n_pos": 1,
                "n_seq_tokens": 1,
                "n_seqs": 1,
                "n_seqs_unq": 1,
                "n_tokens": 1,
            },
            "warmup": False,
            "yarn_attn_factor_f32": "3f800000",
            "yarn_beta_fast_f32": "42000000",
            "yarn_beta_slow_f32": "3f800000",
            "yarn_ext_factor_f32": "00000000",
        },
        "node_count": 3,
    }
    nodes: list[dict[str, object]] = [
        {
            "record_kind": "node",
            "index": 0,
            "semantic_key": semantic(0, "view", "VIEW"),
            "descriptor": view_descriptor,
            "sources": [{"slot": 0, "ref": external_ref, "descriptor": copy.deepcopy(ext_descriptor)}],
        },
        {
            "record_kind": "node",
            "index": 1,
            "semantic_key": semantic(1, "copy", "CPY"),
            "descriptor": copy_descriptor,
            "sources": [{"slot": 0, "ref": node0_ref, "descriptor": copy.deepcopy(view_descriptor)}],
        },
        {
            "record_kind": "node",
            "index": 2,
            "semantic_key": semantic(2, "mul", "MUL"),
            "descriptor": mul_descriptor,
            "sources": [{"slot": 0, "ref": node1_ref, "descriptor": copy.deepcopy(copy_descriptor)}],
        },
    ]
    external = {"record_kind": "external_tensor", "index": 0, "descriptor": ext_descriptor, "sources": []}
    footer = {
        "record_kind": "footer",
        "schema": manifest.RAW_SCHEMA,
        "complete": True,
        "compute_started": False,
        "dispatch_graph_scheduler_allocated": False,
        "external_tensor_count": 1,
        "node_count": 3,
        "record_count": 6,
        "source_edge_count": 3,
    }
    return [header, *nodes, external, footer]


def encode_records(records: list[dict[str, object]]) -> bytes:
    return b"\n".join(manifest.compact_bytes(record) for record in records) + b"\n"


def assert_manifest_error(test: unittest.TestCase, records: list[dict[str, object]], code: str) -> None:
    with test.assertRaises(manifest.ManifestError) as caught:
        manifest.validate_raw_bytes(encode_records(records))
    test.assertEqual(caught.exception.code, code)


class ValidatorTests(unittest.TestCase):
    def test_valid_fixture_is_canonical_and_exhaustively_classified(self) -> None:
        result = manifest.validate_raw_bytes(
            encode_records(make_records()),
            manifest.Expectations(
                model_sha256=MODEL_SHA256,
                source_commit=SOURCE_COMMIT,
                profile="qwen35-0.8b-token0",
                numeric_profile="ggml-f32-rne-v1",
                graph_scope="decoder-main",
                graph_type_name="default",
                flash_attn=False,
                fused_gdn_ar=False,
                fused_gdn_ch=False,
                fused_lid=False,
                fused_dsv4_hc_pre=False,
                fused_dsv4_hc_comb=False,
                fused_dsv4_hc_post=False,
                auto_fa=False,
                auto_fgdn=False,
                auto_flid=False,
                auto_fhc=False,
                n_batch=1,
                n_ubatch=1,
                n_rs_seq=0,
                ubatch_tokens=1,
                node_count=3,
                compute_count=1,
                mover_count=1,
                metadata_count=1,
            ),
        )
        self.assertEqual(result.counts["total"], 3)
        self.assertEqual(json.loads(result.json_bytes)["manifest_sha256"], result.manifest_sha256)
        self.assertTrue(result.json_bytes.endswith(b"\n"))
        self.assertTrue(result.jsonl_bytes.endswith(b"\n"))
        self.assertEqual(result.json_bytes, manifest.canonical_bytes(result.envelope) + b"\n")

    def test_same_input_is_byte_deterministic(self) -> None:
        raw = encode_records(make_records())
        first = manifest.validate_raw_bytes(raw)
        second = manifest.validate_raw_bytes(raw)
        self.assertEqual(first.json_bytes, second.json_bytes)
        self.assertEqual(first.jsonl_bytes, second.jsonl_bytes)
        self.assertEqual(first.manifest_sha256, second.manifest_sha256)

    def test_legacy_and_targeted_dispatch_headers_are_accepted(self) -> None:
        legacy = make_records()
        legacy_result = manifest.validate_raw_bytes(
            encode_records(legacy), manifest.Expectations(target_dispatch=1)
        )
        self.assertNotIn("target_dispatch", legacy_result.envelope["manifest"]["header"])

        targeted = make_records()
        targeted[0]["target_dispatch"] = 2
        targeted[0]["observed_dispatch"] = 2
        targeted_result = manifest.validate_raw_bytes(
            encode_records(targeted), manifest.Expectations(target_dispatch=2)
        )
        self.assertEqual(targeted_result.envelope["manifest"]["header"]["target_dispatch"], 2)
        self.assertEqual(targeted_result.envelope["manifest"]["header"]["observed_dispatch"], 2)

    def test_partial_dispatch_header_fields_are_rejected(self) -> None:
        for field in ("target_dispatch", "observed_dispatch"):
            with self.subTest(field=field):
                records = make_records()
                records[0][field] = 2
                assert_manifest_error(self, records, "COLLECT_DISPATCH_FIELDS")

    def test_invalid_targeted_dispatch_header_values_are_rejected(self) -> None:
        cases = (
            (0, 0, "SCHEMA_RANGE"),
            (2, 1, "COLLECT_DISPATCH"),
            ("2", 2, "SCHEMA_TYPE"),
            (2, "2", "SCHEMA_TYPE"),
        )
        for target, observed, code in cases:
            with self.subTest(target=target, observed=observed):
                records = make_records()
                records[0]["target_dispatch"] = target
                records[0]["observed_dispatch"] = observed
                assert_manifest_error(self, records, code)

    def test_expected_target_dispatch_is_fail_closed(self) -> None:
        legacy = encode_records(make_records())
        with self.assertRaises(manifest.ManifestError) as caught:
            manifest.validate_raw_bytes(
                legacy, manifest.Expectations(target_dispatch=2)
            )
        self.assertEqual(caught.exception.code, "COLLECT_DISPATCH")

    def test_repeat_dispatch_prefix_is_self_contained_and_fail_closed(self) -> None:
        for dispatches in ((), (3,), (3, 4), (3, 4, 5, 6, 7, 8)):
            with self.subTest(dispatches=dispatches):
                manifest._audit_repeat_dispatch_prefix(dispatches)

        for dispatches in ((4,), (3, 5), (3, 4, 6, 7, 8)):
            with self.subTest(dispatches=dispatches):
                with self.assertRaises(manifest.ManifestError) as caught:
                    manifest._audit_repeat_dispatch_prefix(dispatches)
                self.assertEqual(caught.exception.code, "BUNDLE_REPEAT_GAP")

        targeted = make_records()
        targeted[0]["target_dispatch"] = 2
        targeted[0]["observed_dispatch"] = 2
        with self.assertRaises(manifest.ManifestError) as caught:
            manifest.validate_raw_bytes(
                encode_records(targeted), manifest.Expectations(target_dispatch=1)
            )
        self.assertEqual(caught.exception.code, "COLLECT_DISPATCH")

    def test_duplicate_json_key_is_rejected(self) -> None:
        raw = encode_records(make_records())
        first = raw.split(b"\n", 1)[0]
        bad_first = first[:-1] + b',"schema":"duplicate"}'
        with self.assertRaises(manifest.ManifestError) as caught:
            manifest.validate_raw_bytes(bad_first + b"\n" + raw.split(b"\n", 1)[1])
        self.assertEqual(caught.exception.code, "DUPLICATE_KEY")

    def test_node_index_gap_is_rejected(self) -> None:
        records = make_records()
        records[2]["index"] = 9
        assert_manifest_error(self, records, "NODE_INDEX")

    def test_dangling_edge_is_rejected(self) -> None:
        records = make_records()
        records[3]["sources"][0]["ref"] = {"kind": "external", "index": 8}
        assert_manifest_error(self, records, "EDGE_DANGLING")

    def test_edge_descriptor_substitution_is_rejected(self) -> None:
        records = make_records()
        records[2]["sources"][0]["descriptor"]["name"] = "substituted"
        assert_manifest_error(self, records, "EDGE_DESCRIPTOR")

    def test_semantic_occurrence_mutation_is_rejected(self) -> None:
        records = make_records()
        records[3]["semantic_key"]["occurrence"] = 1
        assert_manifest_error(self, records, "SEMANTIC_OCCURRENCE")

    def test_duplicate_stable_identity_is_rejected(self) -> None:
        records = make_records()
        records[3]["descriptor"]["op_id"] = 2
        records[3]["descriptor"]["op_name"] = "CPY"
        records[3]["descriptor"]["op_desc"] = "CPY"
        records[3]["semantic_key"] = copy.deepcopy(records[2]["semantic_key"])
        assert_manifest_error(self, records, "SEMANTIC_OCCURRENCE")

    def test_op_params_width_mutation_is_rejected(self) -> None:
        records = make_records()
        records[3]["descriptor"]["op_params_hex"] = "00" * 63
        assert_manifest_error(self, records, "SCHEMA_HEX")

    def test_view_without_root_is_rejected(self) -> None:
        records = make_records()
        records[3]["descriptor"]["view_offs"] = 4
        assert_manifest_error(self, records, "VIEW_OFFSET")

    def test_zero_length_tensor_is_part_of_descriptor_identity(self) -> None:
        records = make_records()
        records[2]["descriptor"]["ne"] = [4, 0, 1, 1]
        records[2]["descriptor"]["nb"] = [4, 16, 0, 0]
        records[3]["sources"][0]["descriptor"] = copy.deepcopy(records[2]["descriptor"])
        result = manifest.validate_raw_bytes(encode_records(records))
        self.assertEqual(result.envelope["manifest"]["nodes"][1]["descriptor"]["ne"], [4, 0, 1, 1])

    def test_negative_tensor_dimension_is_rejected(self) -> None:
        records = make_records()
        records[2]["descriptor"]["ne"] = [4, -1, 1, 1]
        records[3]["sources"][0]["descriptor"] = copy.deepcopy(records[2]["descriptor"])
        assert_manifest_error(self, records, "SCHEMA_RANGE")

    def test_forward_node_edge_is_rejected(self) -> None:
        records = make_records()
        records[1]["sources"][0]["ref"] = {"kind": "node", "index": 2}
        records[1]["sources"][0]["descriptor"] = copy.deepcopy(records[3]["descriptor"])
        assert_manifest_error(self, records, "EDGE_TOPOLOGY")

    def test_footer_compute_started_is_rejected(self) -> None:
        records = make_records()
        records[-1]["compute_started"] = True
        assert_manifest_error(self, records, "CPU_EXECUTION")

    def test_expected_class_count_is_fail_closed(self) -> None:
        with self.assertRaises(manifest.ManifestError) as caught:
            manifest.validate_raw_bytes(encode_records(make_records()), manifest.Expectations(compute_count=2))
        self.assertEqual(caught.exception.code, "CLASS_COUNT")

    def test_expected_dispatch_identity_is_fail_closed(self) -> None:
        raw = encode_records(make_records())
        cases = (
            (manifest.Expectations(graph_scope="encoder"), "GRAPH_SCOPE"),
            (manifest.Expectations(graph_type_name="decoder-mtp"), "GRAPH_TYPE"),
            (manifest.Expectations(ubatch_tokens=2), "UBATCH_TOKENS"),
            (manifest.Expectations(flash_attn=True), "RUNTIME_PROFILE"),
            (manifest.Expectations(fused_gdn_ar=True), "RUNTIME_PROFILE"),
            (manifest.Expectations(fused_gdn_ch=True), "RUNTIME_PROFILE"),
            (manifest.Expectations(fused_lid=True), "RUNTIME_PROFILE"),
            (manifest.Expectations(fused_dsv4_hc_pre=True), "RUNTIME_PROFILE"),
            (manifest.Expectations(fused_dsv4_hc_comb=True), "RUNTIME_PROFILE"),
            (manifest.Expectations(fused_dsv4_hc_post=True), "RUNTIME_PROFILE"),
            (manifest.Expectations(auto_fa=True), "RUNTIME_PROFILE"),
            (manifest.Expectations(auto_fgdn=True), "RUNTIME_PROFILE"),
            (manifest.Expectations(auto_flid=True), "RUNTIME_PROFILE"),
            (manifest.Expectations(auto_fhc=True), "RUNTIME_PROFILE"),
            (manifest.Expectations(n_batch=2), "RUNTIME_PROFILE"),
            (manifest.Expectations(n_ubatch=2), "RUNTIME_PROFILE"),
            (manifest.Expectations(n_rs_seq=1), "RUNTIME_PROFILE"),
        )
        for expectations, code in cases:
            with self.subTest(code=code):
                with self.assertRaises(manifest.ManifestError) as caught:
                    manifest.validate_raw_bytes(raw, expectations)
                self.assertEqual(caught.exception.code, code)

    def test_descriptor_mutation_preserves_stable_id_but_breaks_sealed_hash(self) -> None:
        baseline_raw = encode_records(make_records())
        baseline = manifest.validate_raw_bytes(baseline_raw)
        records = make_records()
        records[3]["descriptor"]["op_params_hex"] = "01" + "00" * 63
        mutated = manifest.validate_raw_bytes(encode_records(records))
        baseline_id = baseline.envelope["manifest"]["nodes"][2]["canonical_id"]
        mutated_id = mutated.envelope["manifest"]["nodes"][2]["canonical_id"]
        self.assertEqual(baseline_id, mutated_id)
        self.assertNotEqual(baseline.manifest_sha256, mutated.manifest_sha256)
        with self.assertRaises(manifest.ManifestError) as caught:
            manifest.validate_raw_bytes(
                encode_records(records),
                manifest.Expectations(manifest_sha256=baseline.manifest_sha256),
            )
        self.assertEqual(caught.exception.code, "MANIFEST_SHA256")

    def test_raw_byte_mutation_breaks_sealed_raw_hash(self) -> None:
        baseline_raw = encode_records(make_records())
        expected = manifest.sha256_bytes(baseline_raw)
        records = make_records()
        records[3]["descriptor"]["op_params_hex"] = "02" + "00" * 63
        with self.assertRaises(manifest.ManifestError) as caught:
            manifest.validate_raw_bytes(encode_records(records), manifest.Expectations(raw_sha256=expected))
        self.assertEqual(caught.exception.code, "RAW_SHA256")

    def test_cli_publishes_exclusive_canonical_artifacts(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            raw_path = root / "raw.jsonl"
            json_path = root / "manifest.json"
            jsonl_path = root / "manifest.jsonl"
            raw_path.write_bytes(encode_records(make_records()))
            command = [
                sys.executable,
                str(SCRIPT),
                "validate",
                str(raw_path),
                "--json-out",
                str(json_path),
                "--jsonl-out",
                str(jsonl_path),
                "--expect-node-count",
                "3",
                "--expect-target-dispatch",
                "1",
                "--expect-compute-count",
                "1",
                "--expect-mover-count",
                "1",
                "--expect-metadata-count",
                "1",
            ]
            first = subprocess.run(command, capture_output=True, text=True, check=False, timeout=10)
            self.assertEqual(first.returncode, 0, first.stderr)
            self.assertIn("[NPU-GRAPH-MANIFEST][PASS]", first.stdout)
            self.assertTrue(json_path.read_bytes().endswith(b"\n"))
            self.assertTrue(jsonl_path.read_bytes().endswith(b"\n"))
            second = subprocess.run(command, capture_output=True, text=True, check=False, timeout=10)
            self.assertEqual(second.returncode, 2)
            self.assertIn("code=WRITE", second.stderr)


@unittest.skipUnless(BUNDLE_INTEGRATION_REQUESTED, BUNDLE_INTEGRATION_HELP)
class FrozenDispatchBundleTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        missing = [name for name in BUNDLE_ENV_NAMES if not os.environ.get(name)]
        if missing:
            raise RuntimeError(
                f"incomplete real-artifact bundle binding: missing {', '.join(missing)}; "
                f"{BUNDLE_INTEGRATION_HELP}"
            )
        assert BOOTSTRAP_MANIFEST_PATH is not None
        assert STEADY_MANIFEST_PATH is not None
        if len(STEADY_REPEAT_MANIFEST_PATHS) < 2:
            raise RuntimeError(
                "NPU_STEADY_REPEAT_MANIFESTS must bind multiple independently collected manifests "
                "(dispatch 3 through dispatch 8), not a cloned/resealed steady manifest"
            )
        bound_paths = (
            BOOTSTRAP_MANIFEST_PATH,
            STEADY_MANIFEST_PATH,
            *STEADY_REPEAT_MANIFEST_PATHS,
        )
        missing_paths = [str(path) for path in bound_paths if not path.is_file()]
        if missing_paths:
            raise RuntimeError(
                "bound real-artifact manifest does not exist: " + ", ".join(missing_paths)
            )
        cls.bootstrap_path = BOOTSTRAP_MANIFEST_PATH
        cls.steady_path = STEADY_MANIFEST_PATH
        cls.repeat_paths = STEADY_REPEAT_MANIFEST_PATHS
        cls.bootstrap = manifest.load_manifest_envelope(cls.bootstrap_path)
        cls.steady = manifest.load_manifest_envelope(cls.steady_path)
        cls.repeats = [manifest.load_manifest_envelope(path) for path in cls.repeat_paths]

    @staticmethod
    def reseal(envelope: dict[str, object]) -> None:
        payload = envelope["manifest"]
        envelope["manifest_sha256"] = manifest.sha256_bytes(
            manifest.canonical_bytes(payload)
        )

    @staticmethod
    def reseal_node(node: dict[str, object]) -> None:
        node["descriptor_sha256"] = manifest.sha256_bytes(manifest.canonical_bytes({
            "descriptor": node["descriptor"],
            "sources": node["sources"],
        }))

    def assert_bundle_rejected(self, steady: dict[str, object], code: str) -> None:
        self.reseal(steady)
        with self.assertRaises(manifest.ManifestError) as caught:
            manifest.audit_manifest_bundle_objects(self.bootstrap, steady)
        self.assertEqual(caught.exception.code, code)

    def assert_repeats_rejected(
        self, repeats: list[dict[str, object]], code: str
    ) -> None:
        with self.assertRaises(manifest.ManifestError) as caught:
            manifest.audit_manifest_bundle_objects(self.bootstrap, self.steady, repeats)
        self.assertEqual(caught.exception.code, code)

    def test_exact_bundle_is_canonical_and_phase_closed(self) -> None:
        result = manifest.audit_manifest_bundle_objects(self.bootstrap, self.steady)
        self.assertEqual(
            result.counts,
            {
                "nodes": 1714,
                "unchanged_nodes": 1642,
                "descriptor_delta_nodes": 72,
                "zero_scale_nodes": 36,
                "zero_p17_nodes": 18,
                "zero_p18_nodes": 18,
                "steady_repeat_manifests": 0,
            },
        )
        self.assertEqual(result.bundle_sha256, "660a917fa0eac112837b6814bf07e3f9a7ad80e6a8310f8994072b855541b915")
        rows = result.envelope["bundle"]["zero_scale_nodes"]
        self.assertEqual(len({(row["canonical_id"], row["index"]) for row in rows}), 36)
        self.assertEqual({row["profile_id"] for row in rows}, {17, 18})

    def test_dispatch1_legacy_raw_identity_is_unchanged(self) -> None:
        result = manifest.validate_raw_file(
            self.bootstrap_path.with_name("dispatch.raw.jsonl"),
            manifest.Expectations(
                raw_sha256=manifest.BOOTSTRAP_RAW_SHA256,
                manifest_sha256=manifest.BOOTSTRAP_MANIFEST_SHA256,
                target_dispatch=1,
                node_count=1714,
                compute_count=960,
                mover_count=120,
                metadata_count=634,
            ),
        )
        self.assertNotIn(
            "target_dispatch", result.envelope["manifest"]["header"]
        )

    def test_37th_zero_variant_is_rejected(self) -> None:
        steady = copy.deepcopy(self.steady)
        nodes = steady["manifest"]["nodes"]
        victim = next(
            node for node in nodes
            if node["classification"] == "compute"
            and node["descriptor"]["op_name"] == "ADD"
        )
        victim["descriptor"]["ne"] = [0, 1, 1, 1]
        victim["descriptor"]["nb"] = [4, 0, 0, 0]
        self.reseal_node(victim)
        self.assert_bundle_rejected(steady, "BUNDLE_UNEXPECTED_DELTA")

    def test_p16_zero_variant_is_rejected(self) -> None:
        steady = copy.deepcopy(self.steady)
        nodes = steady["manifest"]["nodes"]
        victim = next(
            node for node in nodes
            if node["classification"] == "compute"
            and node["descriptor"]["op_name"] == "SCALE"
            and node["descriptor"]["ne"] == [128, 16, 1, 1]
        )
        victim["descriptor"]["ne"] = [0, 1, 1, 1]
        victim["descriptor"]["nb"] = [4, 0, 0, 0]
        self.reseal_node(victim)
        self.assert_bundle_rejected(steady, "BUNDLE_UNEXPECTED_DELTA")

    def test_allowed_zero_non_ne0_mutation_is_rejected(self) -> None:
        steady = copy.deepcopy(self.steady)
        victim = next(
            node for node in steady["manifest"]["nodes"]
            if node["classification"] == "compute"
            and node["descriptor"]["op_name"] == "SCALE"
            and node["descriptor"]["ne"] == [0, 1, 1, 1]
        )
        victim["descriptor"]["ne"][1] = 0
        self.reseal_node(victim)
        self.assert_bundle_rejected(steady, "BUNDLE_ZERO_DESCRIPTOR")

    def test_canonical_id_index_swap_is_rejected(self) -> None:
        steady = copy.deepcopy(self.steady)
        nodes = steady["manifest"]["nodes"]
        nodes[5]["canonical_id"], nodes[22]["canonical_id"] = (
            nodes[22]["canonical_id"],
            nodes[5]["canonical_id"],
        )
        self.assert_bundle_rejected(steady, "BUNDLE_CANONICAL_ID")

    def test_missing_and_duplicate_nodes_are_rejected(self) -> None:
        missing = copy.deepcopy(self.steady)
        missing["manifest"]["nodes"].pop(5)
        self.assert_bundle_rejected(missing, "BUNDLE_NODE_COUNT")

        duplicate = copy.deepcopy(self.steady)
        duplicate["manifest"]["nodes"].append(
            copy.deepcopy(duplicate["manifest"]["nodes"][5])
        )
        self.assert_bundle_rejected(duplicate, "BUNDLE_NODE_COUNT")

    def test_real_repeat_manifest_list_is_contiguous_frozen_and_canonical(self) -> None:
        # Positive multi-dispatch coverage only uses independently collected
        # artifacts supplied by the smoke runner.  No clone/reseal construction
        # is allowed to stand in for a real dispatch here.
        actual_identities: dict[int, tuple[str, str]] = {}
        actual_file_sha256: dict[int, str] = {}
        for repeat_path, repeat in zip(self.repeat_paths, self.repeats):
            payload = repeat["manifest"]
            header = payload["header"]
            dispatch = header["target_dispatch"]
            self.assertEqual(header["observed_dispatch"], dispatch)
            actual_identities[dispatch] = (
                payload["raw_sha256"], repeat["manifest_sha256"]
            )
            actual_file_sha256[dispatch] = manifest.sha256_bytes(repeat_path.read_bytes())
        self.assertEqual(actual_identities, EXPECTED_REPEAT_IDENTITIES)
        self.assertEqual(actual_file_sha256, EXPECTED_REPEAT_FILE_SHA256)

        # Deliberately reverse the CLI/input order: the bundle must canonicalize
        # rows by dispatch while still checking every intermediate graph.
        repeats = list(reversed(self.repeats))
        result = manifest.audit_manifest_bundle_objects(
            self.bootstrap, self.steady, repeats
        )
        self.assertEqual(result.counts["steady_repeat_manifests"], 6)
        self.assertEqual(result.bundle_sha256, EXPECTED_MULTI_REPEAT_BUNDLE_SHA256)
        self.assertEqual(
            [row["dispatch"] for row in result.envelope["bundle"]["steady_repeats"]],
            [3, 4, 5, 6, 7, 8],
        )

        command = [
            sys.executable,
            str(SCRIPT),
            "bundle",
            str(self.bootstrap_path),
            str(self.steady_path),
        ]
        for repeat_path in reversed(self.repeat_paths):
            command.extend(("--steady-repeat-manifest", str(repeat_path)))
        command.extend(("--expect-bundle-sha256", EXPECTED_MULTI_REPEAT_BUNDLE_SHA256))
        cli = subprocess.run(
            command,
            capture_output=True,
            text=True,
            check=False,
            timeout=60,
        )
        self.assertEqual(cli.returncode, 0, cli.stderr)
        self.assertIn("steady_repeats=6", cli.stdout)

    def test_missing_intermediate_real_repeat_is_rejected(self) -> None:
        repeats = [
            repeat for repeat in self.repeats
            if repeat["manifest"]["header"]["target_dispatch"] != 5
        ]
        self.assert_repeats_rejected(repeats, "BUNDLE_REPEAT_GAP")

    def test_duplicate_real_repeat_is_rejected(self) -> None:
        repeats = [*self.repeats, self.repeats[0]]
        self.assert_repeats_rejected(repeats, "BUNDLE_REPEAT_DUPLICATE")

    def test_middle_real_repeat_drift_matrix_is_rejected(self) -> None:
        middle_index = next(
            index for index, repeat in enumerate(self.repeats)
            if repeat["manifest"]["header"]["target_dispatch"] == 5
        )
        cases = (
            ("node", "BUNDLE_REPEAT_NODE_DRIFT"),
            ("header", "BUNDLE_REPEAT_HEADER_DRIFT"),
            ("counts", "BUNDLE_REPEAT_COUNTS"),
            ("external", "BUNDLE_REPEAT_EXTERNAL_DRIFT"),
            ("footer", "BUNDLE_REPEAT_FOOTER_DRIFT"),
        )
        for mutation, code in cases:
            with self.subTest(mutation=mutation):
                # Resealing is used only for negative fault injection.  The
                # positive coverage above remains tied to physical captures.
                repeats = copy.deepcopy(self.repeats)
                victim = repeats[middle_index]
                payload = victim["manifest"]
                if mutation == "node":
                    node = payload["nodes"][5]
                    node["descriptor"]["nb"][1] += 4
                    self.reseal_node(node)
                elif mutation == "header":
                    payload["header"]["runtime"]["n_ctx"] += 1
                elif mutation == "counts":
                    payload["counts"]["compute"] -= 1
                elif mutation == "external":
                    payload["external_tensors"][0]["descriptor"]["name"] += "-drift"
                else:
                    payload["raw_footer"]["source_edge_count"] -= 1
                self.reseal(victim)
                self.assert_repeats_rejected(repeats, code)

    def test_bundle_cli_publishes_exclusively(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            output = Path(temporary) / "dispatch.bundle.json"
            command = [
                sys.executable,
                str(SCRIPT),
                "bundle",
                str(self.bootstrap_path),
                str(self.steady_path),
                "--json-out",
                str(output),
                "--expect-bundle-sha256",
                "660a917fa0eac112837b6814bf07e3f9a7ad80e6a8310f8994072b855541b915",
            ]
            first = subprocess.run(command, capture_output=True, text=True, check=False, timeout=30)
            self.assertEqual(first.returncode, 0, first.stderr)
            self.assertIn("[NPU-GRAPH-MANIFEST-BUNDLE][PASS]", first.stdout)
            second = subprocess.run(command, capture_output=True, text=True, check=False, timeout=30)
            self.assertEqual(second.returncode, 2)
            self.assertIn("code=WRITE", second.stderr)


class StaticHookTests(unittest.TestCase):
    def test_collect_hook_is_after_fresh_build_and_before_scheduler_or_compute(self) -> None:
        source = CONTEXT_CPP.read_text(encoding="utf-8")
        start = source.index("llm_graph_result * llama_context::process_ubatch")
        end = source.index("\nint llama_context::encode", start)
        body = source[start:end]
        build = body.index("gf = model.build_graph(gparams);")
        collect = body.index("npu_graph_collect_dump(gf, ubatch, gtype")
        strict = body.index("npu_strict_preflight(gf, gtype, \"dispatch\")")
        admission = body.index("[NPU-STRICT-ADMISSION-ONLY][PASS]")
        allocate = body.index("ggml_backend_sched_alloc_graph(sched.get(), gf)")
        set_inputs = body.index("res->set_inputs(&ubatch)")
        compute = body.index("graph_compute(res->get_gf()")
        self.assertLess(build, collect)
        self.assertLess(collect, strict)
        self.assertLess(strict, admission)
        self.assertLess(admission, allocate)
        self.assertLess(admission, set_inputs)
        self.assertLess(admission, compute)
        self.assertLess(collect, allocate)
        self.assertLess(collect, set_inputs)
        self.assertLess(collect, compute)
        self.assertEqual(body.count("npu_graph_collect_dump("), 1)

    def test_reserve_path_does_not_call_collector(self) -> None:
        source = CONTEXT_CPP.read_text(encoding="utf-8")
        start = source.index("ggml_cgraph * llama_context::graph_reserve")
        end = source.index("\nllm_graph_params llama_context::graph_params", start)
        self.assertNotIn("npu_graph_collect_dump", source[start:end])

    def test_collect_mode_requires_all_identity_bindings(self) -> None:
        source = CONTEXT_CPP.read_text(encoding="utf-8")
        for variable in (
            "LLAMA_NPU_GRAPH_COLLECT",
            "LLAMA_NPU_GRAPH_PROFILE",
            "LLAMA_NPU_GRAPH_NUMERIC_PROFILE",
            "LLAMA_NPU_GRAPH_SOURCE_COMMIT",
            "LLAMA_NPU_GRAPH_MODEL_SHA256",
            "LLAMA_NPU_GRAPH_FUSED_OPS",
        ):
            self.assertIn(variable, source)
        self.assertIn("graph collect mode requires --flash-attn off", source)
        self.assertIn("GGML_STATUS_ABORTED", source)
        self.assertIn("compute_started=0", source)


if __name__ == "__main__":
    unittest.main()
