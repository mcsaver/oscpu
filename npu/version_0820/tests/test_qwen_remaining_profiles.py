#!/usr/bin/env python3
"""Directed tests for the frozen remaining-433 manifest/header generator."""

from __future__ import annotations

import argparse
import contextlib
import copy
import hashlib
import io
import os
import pathlib
import shutil
import subprocess
import sys
import tempfile
import unittest


NPU_ROOT = pathlib.Path(__file__).resolve().parents[1]
SCRIPTS_DIR = NPU_ROOT / "scripts"
if str(SCRIPTS_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPTS_DIR))

import qwen_remaining_profiles as remaining  # noqa: E402


MANIFEST_PATH = pathlib.Path(os.environ.get(
    "NPU_MANIFEST",
    NPU_ROOT / "tmp/logs/qwen-graph-manifest-v5/dispatch.manifest.json",
))
TEST_TMP_PARENT = NPU_ROOT / "tmp/tests/qwen-remaining-profiles"


class RemainingManifestTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        TEST_TMP_PARENT.mkdir(parents=True, exist_ok=True)
        cls.envelope = remaining.qwen_f32_alu_profiles.load_manifest(MANIFEST_PATH)
        cls.audit = remaining.audit_manifest_object(cls.envelope)

    def test_exact_census_partition_and_profile_uniqueness(self) -> None:
        audit = self.audit
        self.assertEqual(audit["marker"], remaining.MARKER)
        self.assertEqual(audit["manifest_sha256"], remaining.qwen_f32_alu_profiles.MANIFEST_SHA256)
        self.assertEqual(audit["node_count"], 433)
        self.assertEqual(audit["profile_count"], 30)
        self.assertEqual(audit["existing_owner_node_count"], 646)
        self.assertEqual(audit["sampler_argmax_node_count"], 1)
        self.assertEqual(audit["required_nonmetadata_count"], 1080)
        self.assertEqual(audit["owner_counts"], remaining.EXPECTED_OWNER_COUNTS)
        self.assertEqual(
            audit["owner_profile_counts"],
            remaining.EXPECTED_OWNER_PROFILE_COUNTS,
        )
        self.assertEqual(
            audit["canonical_set_sha256"], remaining.CANONICAL_SET_SHA256
        )
        self.assertEqual(audit["profile_set_sha256"], remaining.PROFILE_SET_SHA256)

        nodes = audit["nodes"]
        profiles = audit["profiles"]
        self.assertEqual(
            [profile["profile_id"] for profile in profiles], list(range(30))
        )
        self.assertEqual(len({node["index"] for node in nodes}), 433)
        self.assertEqual(len({node["canonical_id"] for node in nodes}), 433)
        self.assertEqual(len({node["descriptor_sha256"] for node in nodes}), 433)
        self.assertEqual(
            {node["profile_id"] for node in nodes}, set(range(30))
        )
        self.assertTrue(all(1 <= len(node["srcs"]) <= 3 for node in nodes))
        self.assertEqual(
            audit["route_sentinel_profile_ids"],
            [15, 16, 17, 18, 19, 20, 21, 22, 25, 26, 27, 28],
        )
        self.assertEqual(
            audit["route_sentinel_fields"],
            {
                15: ["local_operation"],
                16: ["local_profile"],
                17: ["local_profile"],
                18: ["local_profile"],
                19: ["local_profile"],
                20: ["local_profile"],
                21: ["local_profile"],
                22: ["local_profile"],
                25: ["local_operation"],
                26: ["local_operation"],
                27: ["local_operation"],
                28: ["local_operation"],
            },
        )

        required_tensor_keys = {
            "type_id",
            "type_name",
            "op_id",
            "op_name",
            "flags",
            "view_present",
            "view_offs",
            "ne",
            "nb",
            "op_params_hex",
        }
        for profile in profiles:
            exact = profile["exact"]
            self.assertEqual(set(exact["dst"]), required_tensor_keys)
            self.assertTrue(1 <= len(exact["srcs"]) <= 3)
            for source in exact["srcs"]:
                self.assertEqual(set(source), required_tensor_keys)

    def test_header_is_deterministic_metadata_only_and_cpp17_includable(self) -> None:
        first = remaining.render_header(self.audit)
        second = remaining.render_header(self.audit)
        self.assertEqual(first, second)
        self.assertIn("kCanonicalNodeCount = 433ULL", first)
        self.assertIn("kProfileCount = 30ULL", first)
        self.assertIn(remaining.CANONICAL_SET_SHA256, first)
        self.assertIn(remaining.PROFILE_SET_SHA256, first)
        self.assertIn("std::array<tensor_spec, 3>", first)
        self.assertIn("descriptor_sha256", first)
        self.assertIn("source_refs", first)
        self.assertIn("kRouteSentinel", first)
        for forbidden in (
            "#include <cmath>",
            "std::exp",
            "expf(",
            "double ",
            "tensor_data",
            "host_oracle",
        ):
            self.assertNotIn(forbidden, first)

        with tempfile.TemporaryDirectory(
            prefix="determinism-", dir=TEST_TMP_PARENT
        ) as temporary_name:
            temporary = pathlib.Path(temporary_name)
            first_path = temporary / "remaining-a.h"
            second_path = temporary / "remaining-b.h"
            remaining.write_header(first_path, self.audit)
            remaining.write_header(second_path, self.audit)
            self.assertEqual(first_path.read_bytes(), second_path.read_bytes())
            self.assertEqual(
                hashlib.sha256(first_path.read_bytes()).hexdigest(),
                hashlib.sha256(second_path.read_bytes()).hexdigest(),
            )

            compiler = shutil.which("g++")
            self.assertIsNotNone(compiler, "g++ is required to verify header inclusion")
            source = temporary / "include-smoke.cc"
            source.write_text(
                '#include "remaining-a.h"\n'
                "static_assert(qwen_remaining_manifest::kCanonicalNodeCount == 433);\n"
                "static_assert(qwen_remaining_manifest::kProfileCount == 30);\n"
                "int main() { return 0; }\n",
                encoding="utf-8",
            )
            environment = dict(os.environ)
            environment.update(
                {"TMPDIR": temporary_name, "TMP": temporary_name, "TEMP": temporary_name}
            )
            completed = subprocess.run(
                [compiler, "-std=c++17", "-fsyntax-only", str(source)],
                cwd=temporary,
                env=environment,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                check=False,
            )
            self.assertEqual(completed.returncode, 0, completed.stderr)

    def test_graph_index_cli_emits_exact_test_identity(self) -> None:
        node = self.audit["nodes"][0]
        arguments = remaining.parser().parse_args(
            [
                "test-id",
                "--manifest",
                str(MANIFEST_PATH),
                "--graph-index",
                hex(node["index"]),
            ]
        )
        stream = io.StringIO()
        with contextlib.redirect_stdout(stream):
            self.assertEqual(arguments.function(arguments), 0)
        self.assertEqual(stream.getvalue().strip(), node["canonical_id"])
        with self.assertRaises(remaining.qwen_f32_alu_profiles.ProfileError):
            remaining.command_test_id(
                argparse.Namespace(manifest=MANIFEST_PATH, graph_index=1711)
            )

    def _mutated_envelope(self) -> dict:
        return copy.deepcopy(self.envelope)

    @staticmethod
    def _selected_raw_nodes(envelope: dict) -> list[dict]:
        return [
            node
            for node in envelope["manifest"]["nodes"]
            if remaining._owner_for_node(node) is not None
        ]

    @staticmethod
    def _rehash_descriptor(node: dict) -> None:
        node["descriptor_sha256"] = (
            remaining.qwen_f32_alu_profiles.canonical_sha256(
                {"descriptor": node["descriptor"], "sources": node["sources"]}
            )
        )

    def _assert_catalog_rejects(self, envelope: dict) -> None:
        with self.assertRaises(remaining.qwen_f32_alu_profiles.ProfileError):
            remaining._audit_catalog(envelope)

    def test_fail_closed_manifest_hash_mutation(self) -> None:
        mutated = self._mutated_envelope()
        mutated["manifest_sha256"] = "0" * 64
        with self.assertRaises(remaining.qwen_f32_alu_profiles.ProfileError):
            remaining.audit_manifest_object(mutated)

    def test_fail_closed_exact_descriptor_and_identity_mutations(self) -> None:
        mutations: dict[str, dict] = {}

        op_mutation = self._mutated_envelope()
        op_node = self._selected_raw_nodes(op_mutation)[0]
        op_node["descriptor"]["op_name"] = "MUL"
        op_node["descriptor"]["op_id"] = 7
        self._rehash_descriptor(op_node)
        mutations["op"] = op_mutation

        dtype_mutation = self._mutated_envelope()
        dtype_node = self._selected_raw_nodes(dtype_mutation)[0]
        dtype_node["descriptor"]["type_name"] = "f16"
        dtype_node["descriptor"]["type_id"] = 1
        self._rehash_descriptor(dtype_node)
        mutations["dtype"] = dtype_mutation

        shape_mutation = self._mutated_envelope()
        shape_node = self._selected_raw_nodes(shape_mutation)[0]
        shape_node["descriptor"]["ne"][0] += 1
        self._rehash_descriptor(shape_node)
        mutations["shape"] = shape_mutation

        stride_mutation = self._mutated_envelope()
        stride_node = self._selected_raw_nodes(stride_mutation)[0]
        stride_node["descriptor"]["nb"][1] += 4
        self._rehash_descriptor(stride_node)
        mutations["stride"] = stride_mutation

        params_mutation = self._mutated_envelope()
        params_node = self._selected_raw_nodes(params_mutation)[0]
        old_params = params_node["descriptor"]["op_params_hex"]
        params_node["descriptor"]["op_params_hex"] = "ff" + old_params[2:]
        self._rehash_descriptor(params_node)
        mutations["op_params"] = params_mutation

        ref_mutation = self._mutated_envelope()
        ref_node = next(
            node
            for node in self._selected_raw_nodes(ref_mutation)
            if node["sources"][0]["ref"]["kind"] == "node"
            and node["sources"][0]["ref"]["index"] > 0
        )
        ref_node["sources"][0]["ref"]["index"] -= 1
        self._rehash_descriptor(ref_node)
        mutations["source_ref"] = ref_mutation

        collision_mutation = self._mutated_envelope()
        collision_nodes = self._selected_raw_nodes(collision_mutation)[:2]
        collision_nodes[1]["semantic_key"] = copy.deepcopy(
            collision_nodes[0]["semantic_key"]
        )
        collision_nodes[1]["canonical_id"] = collision_nodes[0]["canonical_id"]
        mutations["canonical_collision"] = collision_mutation

        profile_mutation = self._mutated_envelope()
        baseline_profile = self.audit["profiles"][0]
        baseline_indices = {node["index"] for node in baseline_profile["members"]}
        for profile_node in self._selected_raw_nodes(profile_mutation):
            if profile_node["index"] in baseline_indices:
                profile_node["descriptor"]["flags"] += 1
                self._rehash_descriptor(profile_node)
        mutations["profile_drift"] = profile_mutation

        self.assertEqual(
            set(mutations),
            {
                "op",
                "dtype",
                "shape",
                "stride",
                "op_params",
                "source_ref",
                "canonical_collision",
                "profile_drift",
            },
        )
        for name, envelope in mutations.items():
            with self.subTest(name=name):
                self._assert_catalog_rejects(envelope)


if __name__ == "__main__":
    unittest.main(verbosity=2)
