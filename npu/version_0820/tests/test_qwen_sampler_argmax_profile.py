#!/usr/bin/env python3
"""Directed tests for the strict-greedy sampler ARGMAX profile generator."""

from __future__ import annotations

import argparse
import contextlib
import copy
import io
import os
import pathlib
import shutil
import subprocess
import sys
import tempfile
import unittest
from unittest import mock
from typing import Callable


NPU_ROOT = pathlib.Path(__file__).resolve().parents[1]
SCRIPTS_DIR = NPU_ROOT / "scripts"
if str(SCRIPTS_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPTS_DIR))

import qwen_sampler_argmax_profile as sampler  # noqa: E402


DEFAULT_REAL_MANIFEST_PATH = (
    NPU_ROOT
    / "tmp/analysis/strict-greedy-fresh-20260824-c/dispatch.manifest.json"
)
NPU_MANIFEST_ENV = os.environ.get("NPU_MANIFEST")


def _resolve_real_manifest_path(environment: dict[str, str]) -> pathlib.Path:
    if "NPU_MANIFEST" in environment:
        return pathlib.Path(environment["NPU_MANIFEST"])
    return DEFAULT_REAL_MANIFEST_PATH


REAL_MANIFEST_PATH = _resolve_real_manifest_path(dict(os.environ))
TEST_TMP_PARENT = NPU_ROOT / "tmp/tests/qwen-sampler-argmax-profile"


def _source_node() -> dict:
    node = {
        "canonical_id": sampler.SOURCE_CANONICAL_ID,
        "classification": "metadata",
        "descriptor": copy.deepcopy(sampler.EXPECTED_SOURCE_DESCRIPTOR),
        "index": sampler.SOURCE_GRAPH_INDEX,
        "record_kind": "node",
        "semantic_key": copy.deepcopy(sampler.EXPECTED_SOURCE_SEMANTIC_KEY),
        "sources": copy.deepcopy(sampler.EXPECTED_SOURCE_NODE_SOURCES),
    }
    node["descriptor_sha256"] = sampler.canonical_sha256(
        {"descriptor": node["descriptor"], "sources": node["sources"]}
    )
    return node


def _argmax_node() -> dict:
    node = {
        "canonical_id": sampler.ARGMAX_CANONICAL_ID,
        "classification": "compute",
        "descriptor": copy.deepcopy(sampler.EXPECTED_DST_DESCRIPTOR),
        "index": sampler.ARGMAX_GRAPH_INDEX,
        "record_kind": "node",
        "semantic_key": copy.deepcopy(sampler.EXPECTED_ARGMAX_SEMANTIC_KEY),
        "sources": [copy.deepcopy(sampler.EXPECTED_ARGMAX_SOURCE)],
    }
    node["descriptor_sha256"] = sampler.canonical_sha256(
        {"descriptor": node["descriptor"], "sources": node["sources"]}
    )
    return node


def _fixture_envelope() -> dict:
    nodes: list[dict] = []
    for index in range(sampler.SOURCE_GRAPH_INDEX):
        if index < 959:
            classification = "compute"
        elif index < 1079:
            classification = "mover"
        else:
            classification = "metadata"
        # 1712 filler nodes contribute 2472 edges: one each plus a second
        # edge on the first 760.  Nodes 1712/1713 contribute one edge each.
        sources = [{} for _ in range(2 if index < 760 else 1)]
        nodes.append(
            {
                "classification": classification,
                "descriptor": {
                    "name": f"fixture_{index}",
                    "op_id": 0,
                    "op_name": "NONE",
                },
                "index": index,
                "record_kind": "node",
                "sources": sources,
            }
        )
    nodes.extend([_source_node(), _argmax_node()])
    manifest = {
        "counts": dict(sampler.EXPECTED_COUNTS),
        "external_tensors": [{} for _ in range(375)],
        "header": {
            "bindings": dict(sampler.EXPECTED_BINDINGS),
            "collector_phase": "process_ubatch.post_build.pre_scheduler_alloc",
            "graph": dict(sampler.EXPECTED_GRAPH),
            "node_count": 1714,
            "record_kind": "header",
            "runtime": {
                "collect_only": True,
                "n_outputs": 1,
                "n_outputs_max": 1,
                "sampler_count": 1,
            },
            "schema": sampler.RAW_SCHEMA,
        },
        "nodes": nodes,
        "raw_footer": dict(sampler.EXPECTED_RAW_FOOTER),
        "raw_schema": sampler.RAW_SCHEMA,
        "raw_sha256": sampler.RAW_SHA256,
        "schema": sampler.MANIFEST_SCHEMA,
    }
    return {
        "schema": sampler.ENVELOPE_SCHEMA,
        "manifest_sha256": sampler.canonical_sha256(manifest),
        "manifest": manifest,
    }


def _reseal(envelope: dict) -> str:
    digest = sampler.canonical_sha256(envelope["manifest"])
    envelope["manifest_sha256"] = digest
    return digest


def _audit_fixture(envelope: dict) -> dict:
    # Production has no digest override.  The directed in-memory fixture
    # temporarily substitutes the pinned constant only inside this call.
    with mock.patch.object(
        sampler, "MANIFEST_SHA256", envelope["manifest_sha256"]
    ):
        return sampler.audit_manifest_object(envelope)


class SamplerArgmaxProfileTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        TEST_TMP_PARENT.mkdir(parents=True, exist_ok=True)

    def setUp(self) -> None:
        self.envelope = _fixture_envelope()

    def _argmax(self, envelope: dict | None = None) -> dict:
        value = self.envelope if envelope is None else envelope
        return value["manifest"]["nodes"][sampler.ARGMAX_GRAPH_INDEX]

    def _assert_rejected(self, envelope: dict) -> None:
        _reseal(envelope)
        with self.assertRaises(sampler.ProfileError):
            _audit_fixture(envelope)

    def test_correct_fixture_audits_and_emits_exact_marker(self) -> None:
        audit = _audit_fixture(self.envelope)
        self.assertEqual(audit["marker"], sampler.MARKER)
        self.assertEqual(audit["counts"], sampler.EXPECTED_COUNTS)
        self.assertEqual(audit["required_node_count"], 1080)
        self.assertEqual(audit["profile_count"], 1)
        profile = audit["profiles"][0]
        self.assertEqual(profile["canonical_id"], sampler.ARGMAX_CANONICAL_ID)
        self.assertEqual(profile["graph_node_index"], 1713)
        self.assertEqual(profile["source_node_index"], 1712)
        self.assertEqual(profile["dst_name"], "greedy_argmax")
        self.assertEqual(profile["src0_name"], "logits_seq_0_0 (reshaped)")
        self.assertEqual(profile["src0_ne"], [248320, 1, 1, 1])

        with mock.patch.object(sampler, "load_audited", return_value=audit):
            stream = io.StringIO()
            with contextlib.redirect_stdout(stream):
                result = sampler.command_audit(
                    argparse.Namespace(manifest=pathlib.Path("unused"))
                )
        self.assertEqual(result, 0)
        marker = stream.getvalue().strip()
        self.assertTrue(marker.startswith(f"{sampler.MARKER}[PASS] "))
        self.assertIn("node=1713 source=1712", marker)
        self.assertIn("total=1714 compute=960 mover=120 metadata=634", marker)
        self.assertIn("external=375 source_edges=2474 required=1080", marker)

    def test_header_is_deterministic_small_and_cpp17_includable(self) -> None:
        audit = _audit_fixture(self.envelope)
        first = sampler.render_header(audit)
        self.assertEqual(first, sampler.render_header(audit))
        for expected in (
            sampler.ARGMAX_CANONICAL_ID,
            "kProfileCount = 1ULL",
            "1713U",
            "1712U",
            '"greedy_argmax"',
            '"logits_seq_0_0 (reshaped)"',
            "248320LL",
            "kOpParamsAllZero = true",
        ):
            self.assertIn(expected, first)
        for forbidden in ("#include <cmath>", "std::argmax", "tensor_data", "host_oracle"):
            self.assertNotIn(forbidden, first)

        with tempfile.TemporaryDirectory(prefix="header-", dir=TEST_TMP_PARENT) as name:
            temporary = pathlib.Path(name)
            header = temporary / "qwen-sampler-argmax.h"
            sampler.write_header(header, audit)
            self.assertEqual(header.read_text(encoding="utf-8"), first)
            compiler = shutil.which("g++")
            self.assertIsNotNone(compiler, "g++ is required for generated-header QA")
            source = temporary / "include-smoke.cc"
            source.write_text(
                '#include "qwen-sampler-argmax.h"\n'
                "using namespace qwen_sampler_argmax_manifest;\n"
                "static_assert(kProfileCount == 1);\n"
                "static_assert(kProfile.graph_node_index == 1713);\n"
                "static_assert(kProfile.source_node_index == 1712);\n"
                "static_assert(kManifestCounts.required == 1080);\n"
                "int main() { return 0; }\n",
                encoding="utf-8",
            )
            environment = dict(os.environ)
            environment.update({"TMPDIR": name, "TMP": name, "TEMP": name})
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

    def test_default_audit_remains_pinned_to_real_fresh_manifest(self) -> None:
        self.assertNotEqual(self.envelope["manifest_sha256"], sampler.MANIFEST_SHA256)
        with self.assertRaises(sampler.ProfileError):
            sampler.audit_manifest_object(self.envelope)

    def test_real_fresh_manifest_passes_pinned_audit(self) -> None:
        if not REAL_MANIFEST_PATH.is_file():
            if NPU_MANIFEST_ENV is not None:
                self.fail(
                    "NPU_MANIFEST was set but is not a file: "
                    + str(REAL_MANIFEST_PATH)
                )
            self.skipTest("default fresh manifest is not present")
        audit = sampler.load_audited(REAL_MANIFEST_PATH)
        self.assertEqual(audit["manifest_sha256"], sampler.MANIFEST_SHA256)
        self.assertEqual(audit["profiles"][0]["canonical_id"], sampler.ARGMAX_CANONICAL_ID)
        print(
            "[NPU-SAMPLER-ARGMAX-PROFILE-TEST][PASS] "
            f"manifest_source={'NPU_MANIFEST' if NPU_MANIFEST_ENV is not None else 'default'} "
            f"non_skip={1 if NPU_MANIFEST_ENV is not None else 0} "
            f"manifest_sha256={audit['manifest_sha256']}"
        )

    def test_manifest_environment_override_has_priority(self) -> None:
        override = NPU_ROOT / "tmp/fixture/override.manifest.json"
        self.assertEqual(
            _resolve_real_manifest_path({"NPU_MANIFEST": str(override)}),
            override,
        )
        self.assertEqual(_resolve_real_manifest_path({}), DEFAULT_REAL_MANIFEST_PATH)
        self.assertEqual(
            _resolve_real_manifest_path({"NPU_MANIFEST": ""}), pathlib.Path("")
        )
        if NPU_MANIFEST_ENV is not None:
            self.assertEqual(REAL_MANIFEST_PATH, pathlib.Path(NPU_MANIFEST_ENV))

    def test_canonical_id_index_name_shape_type_source_and_count_drift_fail(self) -> None:
        mutations: list[tuple[str, Callable[[dict], object]]] = [
            (
                "canonical_semantic_key",
                lambda envelope: self._argmax(envelope)["semantic_key"].__setitem__(
                    "path", "trunk/tampered/greedy_argmax"
                ),
            ),
            (
                "canonical_id",
                lambda envelope: self._argmax(envelope).__setitem__(
                    "canonical_id", "0" * 64
                ),
            ),
            (
                "graph_index",
                lambda envelope: self._argmax(envelope).__setitem__("index", 1714),
            ),
            (
                "destination_name",
                lambda envelope: self._argmax(envelope)["descriptor"].__setitem__(
                    "name", "greedy_argmax_drift"
                ),
            ),
            (
                "source_name",
                lambda envelope: self._argmax(envelope)["sources"][0][
                    "descriptor"
                ].__setitem__("name", "logits_drift"),
            ),
            (
                "source_shape",
                lambda envelope: self._argmax(envelope)["sources"][0][
                    "descriptor"
                ]["ne"].__setitem__(0, 248319),
            ),
            (
                "destination_type",
                lambda envelope: self._argmax(envelope)["descriptor"].__setitem__(
                    "type_id", 0
                ),
            ),
            (
                "source_type",
                lambda envelope: self._argmax(envelope)["sources"][0][
                    "descriptor"
                ].__setitem__("type_name", "f16"),
            ),
            (
                "source_reference",
                lambda envelope: self._argmax(envelope)["sources"][0]["ref"].__setitem__(
                    "index", 1711
                ),
            ),
            (
                "declared_count",
                lambda envelope: envelope["manifest"]["counts"].__setitem__(
                    "compute", 959
                ),
            ),
            (
                "derived_external_count",
                lambda envelope: envelope["manifest"]["external_tensors"].pop(),
            ),
        ]
        for name, mutate in mutations:
            with self.subTest(name=name):
                envelope = copy.deepcopy(self.envelope)
                mutate(envelope)
                self._assert_rejected(envelope)

    def test_non_unique_argmax_match_fails_closed(self) -> None:
        duplicate = copy.deepcopy(self.envelope)
        node = copy.deepcopy(self._argmax(duplicate))
        node["index"] = 800
        node["semantic_key"]["path"] = "trunk/fixture/duplicate_greedy_argmax"
        node["semantic_key"]["occurrence"] = 1
        node["canonical_id"] = sampler.canonical_sha256(node["semantic_key"])
        node["descriptor_sha256"] = sampler.canonical_sha256(
            {"descriptor": node["descriptor"], "sources": node["sources"]}
        )
        duplicate["manifest"]["nodes"][800] = node
        self._assert_rejected(duplicate)


if __name__ == "__main__":
    unittest.main(verbosity=2)
