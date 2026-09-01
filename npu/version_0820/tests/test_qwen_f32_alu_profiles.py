#!/usr/bin/env python3
"""Qwen F32 ALU 19-profile/canonical-manifest 定向单测。"""

from __future__ import annotations

import argparse
import importlib.util
import os
import pathlib
import subprocess
import sys
import tempfile
import unittest


NPU_ROOT = pathlib.Path(__file__).resolve().parents[1]
MODULE_PATH = NPU_ROOT / "scripts/qwen_f32_alu_profiles.py"
SPEC = importlib.util.spec_from_file_location("qwen_f32_alu_profiles", MODULE_PATH)
if SPEC is None or SPEC.loader is None:
    raise RuntimeError("cannot load qwen_f32_alu_profiles.py")
profiles = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = profiles
SPEC.loader.exec_module(profiles)

MANIFEST_PATH = pathlib.Path(os.environ.get(
    "NPU_MANIFEST",
    NPU_ROOT / "tmp/acceptance/qwen35-08b-q8_0-npu-strict-20260826T113230-1572837/graph-manifest/dispatch.manifest.json",
))
STEADY_MANIFEST_PATH = pathlib.Path(os.environ.get(
    "NPU_STEADY_MANIFEST",
    NPU_ROOT / "tmp/analysis/strict-collect-dispatch2-20260826/dispatch.manifest.json",
))


class ProfileTableTest(unittest.TestCase):
    def test_exact_table_and_census(self) -> None:
        audit = profiles.validate_profiles()
        self.assertEqual(audit["profile_count"], 19)
        self.assertEqual(audit["eligible_identity_count"], 367)
        self.assertEqual(
            audit["op_counts"],
            {"ADD": 84, "MUL": 211, "SUB": 18, "SCALE": 54},
        )
        self.assertEqual(audit["maximum_cycle_upper_bound"], 148111392)
        self.assertEqual(audit["p18_cycle_upper_bound"], 143654944)
        self.assertLess(
            audit["maximum_cycle_upper_bound"], audit["child_command_timeout"]
        )
        self.assertLess(
            audit["child_command_timeout"], audit["harness_cycle_limit"]
        )

    def test_profile_ids_and_signatures_are_unique(self) -> None:
        self.assertEqual(
            [profile.profile_id for profile in profiles.PROFILES], list(range(19))
        )
        signatures = [
            profiles.profile_signature(profile) for profile in profiles.PROFILES
        ]
        self.assertEqual(len(signatures), len(set(signatures)))

    def test_allocation_relative_span(self) -> None:
        p15 = profiles.PROFILES[15]
        self.assertEqual(
            profiles.source_span(p15.src0),
            {
                "logical_hi": 24576,
                "beat_lo": 16384,
                "beat_hi": 24576,
                "copy_bytes": 8192,
                "region_size": 24576,
            },
        )
        p18 = profiles.PROFILES[18]
        self.assertEqual(profiles.source_span(p18.src0)["beat_hi"], 1048576)
        self.assertEqual(p18.elements, 262144)
        self.assertEqual(p18.read_bytes, 2097152)
        self.assertEqual(p18.write_bytes, 1048576)

    def test_exact_permission_truth_tables(self) -> None:
        truth = profiles.permission_truth_table()
        self.assertEqual(truth["rows_per_profile"], 64)
        for profile in profiles.PROFILES[:16]:
            self.assertEqual(truth["accepted"][profile.name], [[1, 1, 2]])
        for profile in profiles.PROFILES[16:]:
            self.assertEqual(truth["accepted"][profile.name], [[1, 0, 2]])
        self.assertFalse(profiles.permission_accepted(profiles.PROFILES[0], 3, 1, 2))
        self.assertFalse(profiles.permission_accepted(profiles.PROFILES[18], 1, 1, 2))

    def test_scale_raw_parameter_abi(self) -> None:
        self.assertEqual(profiles.PROFILES[16].op_params_hex[:8], "f304b53d")
        self.assertEqual(profiles.PROFILES[16].op_params_hex[8:], "00" * 60)
        self.assertEqual(profiles.PROFILES[17].op_params_hex, "00" * 64)
        self.assertEqual(profiles.PROFILES[18].op_params_hex, "00" * 64)
        for profile in profiles.PROFILES[:16]:
            self.assertEqual(profile.op_params_hex, "00" * 64)


class CanonicalManifestTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.envelope = profiles.load_manifest(MANIFEST_PATH)

    def test_exact_manifest_join(self) -> None:
        census = profiles.audit_manifest_object(self.envelope)
        self.assertEqual(census["manifest_sha256"], profiles.MANIFEST_SHA256)
        self.assertEqual(census["raw_sha256"], profiles.RAW_SHA256)
        self.assertTrue(census["manifest_payload_recomputed"])
        self.assertEqual(census["eligible_canonical_ids_recomputed"], 367)
        self.assertEqual(census["eligible_descriptor_hashes_recomputed"], 367)
        self.assertEqual(census["profile_count"], 19)
        self.assertEqual(census["eligible_identity_count"], 367)
        self.assertEqual(
            census["predecessor_representative_transactions_passed"], 1
        )
        self.assertEqual(
            census["verified_canonical_node_identities_completed"], 0
        )
        self.assertEqual(census["remaining_nonmetadata_gap"], 1080)
        self.assertEqual(
            census["canonical_identity_set_sha256"],
            profiles.CANONICAL_IDENTITY_SET_SHA256,
        )
        row_counts = {
            row["profile"]: len(row["canonical_nodes"])
            for row in census["profiles"]
        }
        self.assertEqual(
            row_counts,
            {profile.name: profile.count for profile in profiles.PROFILES},
        )
        identities = [
            node["canonical_id"]
            for row in census["profiles"]
            for node in row["canonical_nodes"]
        ]
        self.assertEqual(len(identities), 367)
        self.assertEqual(len(set(identities)), 367)

    def test_fail_closed_manifest_mutations(self) -> None:
        result = profiles.mutation_self_test(self.envelope)
        self.assertEqual(result["baseline_eligible"], 367)
        self.assertEqual(
            result["baseline_identity_set_sha256"],
            profiles.CANONICAL_IDENTITY_SET_SHA256,
        )
        self.assertEqual(result["rejected_mutation_count"], 19)
        self.assertEqual(
            set(result["rejected_mutations"]),
            {
                "missing",
                "extra",
                "duplicate",
                "op",
                "shape",
                "nb",
                "view",
                "view_off",
                "op_params",
                "source_shape",
                "payload_stale_envelope_hash",
                "raw_source_hash",
                "semantic_key",
                "descriptor_source",
                "stale_descriptor_sha256",
                "fake_distinct_identities",
                "profile_identity_substitution",
                "profile_collision",
                "permission",
            },
        )
        representative = result["representative_stage_mutations"]
        self.assertEqual(representative["baseline_count"], 19)
        self.assertEqual(representative["rejected_mutation_count"], 7)
        self.assertEqual(
            set(representative["rejected_mutations"]),
            {
                "duplicate_replay",
                "wrong_profile",
                "missing",
                "extra",
                "profile_identity_substitution",
                "reordered_profile_collision",
                "required_namespace_pollution",
            },
        )


class CanonicalBundleHeaderTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.bootstrap = profiles.load_manifest(MANIFEST_PATH)
        cls.steady = profiles.load_manifest(STEADY_MANIFEST_PATH)

    def test_exact_allowlist_and_zero_subset(self) -> None:
        bundle = profiles.audit_manifest_bundle_object(
            self.bootstrap, self.steady
        )
        self.assertEqual(bundle["canonical_node_count"], 367)
        self.assertEqual(bundle["zero_cardinality_count"], 36)
        self.assertEqual(bundle["zero_profile_counts"], {"P17": 18, "P18": 18})
        self.assertEqual(
            bundle["canonical_allowlist_sha256"],
            profiles.F32_CANONICAL_ALLOWLIST_SHA256,
        )
        rows = bundle["canonical_nodes"]
        self.assertEqual(
            [row["graph_node_index"] for row in rows],
            sorted(row["graph_node_index"] for row in rows),
        )
        self.assertEqual(
            {row["profile_id"] for row in rows if row["zero_cardinality_allowed"]},
            {17, 18},
        )
        self.assertTrue(all(
            row["profile_id"] in {17, 18}
            for row in rows
            if row["zero_cardinality_allowed"]
        ))

    def test_generated_header_has_fixed_cpp_abi(self) -> None:
        bundle = profiles.audit_manifest_bundle_object(
            self.bootstrap, self.steady
        )
        header = profiles.render_canonical_header(bundle)
        self.assertIn("struct qwen_f32_alu_canonical_node", header)
        self.assertIn("kQwenF32AluCanonicalNodes", header)
        self.assertIn("kQwenF32AluZeroCardinalityCount = 36ULL", header)
        self.assertIn(profiles.F32_CANONICAL_ALLOWLIST_SHA256, header)
        self.assertEqual(header.count("true},"), 36)
        self.assertEqual(header.count("false},"), 331)

    def test_emit_header_cli_is_deterministic_and_compiles(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            output = pathlib.Path(temporary) / "qwen-f32-alu-manifest.generated.h"
            command = [
                sys.executable,
                str(MODULE_PATH),
                "emit-header",
                "--bootstrap-manifest",
                str(MANIFEST_PATH),
                "--steady-manifest",
                str(STEADY_MANIFEST_PATH),
                "--output",
                str(output),
            ]
            first = subprocess.run(
                command, capture_output=True, text=True, check=False, timeout=30
            )
            self.assertEqual(first.returncode, 0, first.stderr)
            self.assertIn("[NPU-QWEN-F32-ALU-CANONICAL][PASS]", first.stdout)
            first_bytes = output.read_bytes()
            second = subprocess.run(
                command, capture_output=True, text=True, check=False, timeout=30
            )
            self.assertEqual(second.returncode, 0, second.stderr)
            self.assertEqual(first_bytes, output.read_bytes())
            source = pathlib.Path(temporary) / "probe.cpp"
            source.write_text(
                '#include "qwen-f32-alu-manifest.generated.h"\n'
                "int main() { return ggml_npu_generated::"
                "kQwenF32AluCanonicalNodes.size() == 367 ? 0 : 1; }\n",
                encoding="utf-8",
            )
            compile_result = subprocess.run(
                ["c++", "-std=c++17", "-fsyntax-only", str(source)],
                cwd=temporary,
                capture_output=True,
                text=True,
                check=False,
                timeout=30,
            )
            self.assertEqual(compile_result.returncode, 0, compile_result.stderr)


class RepresentativeIdentityTest(unittest.TestCase):
    def test_exact_namespace_and_stage_sets(self) -> None:
        identity = profiles.representative_identity_audit()
        self.assertEqual(identity["count"], 19)
        self.assertEqual(identity["exact_profile_mask"], 0x7FFFF)
        self.assertEqual(identity["required_bit"], 0)
        self.assertEqual(len({row["namespace"] for row in identity["records"]}), 19)
        self.assertTrue(
            all(row["command_flags"] == 0x10 for row in identity["records"])
        )
        stages = {
            stage: identity["records"]
            for stage in profiles.REPRESENTATIVE_STAGES
        }
        ledger = profiles.audit_representative_stage_sets(stages)
        self.assertEqual(ledger["stage_count"], 5)
        self.assertEqual(ledger["exact_profile_mask"], 0x7FFFF)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--manifest", type=pathlib.Path, default=MANIFEST_PATH)
    return parser.parse_args()


if __name__ == "__main__":
    arguments = parse_args()
    MANIFEST_PATH = arguments.manifest.resolve()
    unittest.main(argv=[sys.argv[0]], verbosity=2)
