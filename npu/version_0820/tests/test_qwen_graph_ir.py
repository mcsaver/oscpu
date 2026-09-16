#!/usr/bin/env python3
"""Fast GraphIR importer tests plus an opt-in frozen Qwen manifest audit."""

from __future__ import annotations

import copy
import json
import os
import pathlib
import sys
import unittest

PROJECT_ROOT = pathlib.Path(__file__).resolve().parents[1]
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from compiler import qwen_graph_ir  # noqa: E402
from compiler import npu_artifact, npu_ids  # noqa: E402


FIXTURE = PROJECT_ROOT / "compiler" / "fixtures" / "tiny_qwen_graph_manifest.json"
REAL_MANIFEST_ENV = "NPU_QWEN_GRAPH_MANIFEST"


def load_fixture_object() -> dict:
    return json.loads(FIXTURE.read_text(encoding="utf-8"))


def reseal(envelope: dict, *node_indices: int) -> dict:
    for index in node_indices:
        node = envelope["manifest"]["nodes"][index]
        node["descriptor_sha256"] = qwen_graph_ir.canonical_sha256(
            {"descriptor": node["descriptor"], "sources": node["sources"]}
        )
    envelope["manifest_sha256"] = qwen_graph_ir.canonical_sha256(envelope["manifest"])
    return envelope


class TinyGraphIRTests(unittest.TestCase):
    def test_import_is_stable_address_free_and_unfused(self) -> None:
        first = qwen_graph_ir.load_graph_ir(
            FIXTURE, owner_mode=qwen_graph_ir.OWNER_MODE_FIXTURE
        )
        second = qwen_graph_ir.load_graph_ir(
            FIXTURE, owner_mode=qwen_graph_ir.OWNER_MODE_FIXTURE
        )
        self.assertEqual(first, second)
        self.assertEqual(
            first["graph_ir_sha256"],
            qwen_graph_ir.canonical_sha256(first["graph_ir"]),
        )

        graph = first["graph_ir"]
        self.assertEqual(graph["coverage"]["required_node_count"], 1)
        self.assertEqual(graph["coverage"]["metadata_node_count"], 1)
        self.assertEqual(graph["coverage"]["owner_family_counts"], {"f32_alu": 1})
        self.assertTrue(graph["coverage"]["assigned_exactly_once"])
        self.assertEqual(graph["coverage"]["gap_count"], 0)
        self.assertEqual(graph["coverage"]["overlap_count"], 0)
        self.assertEqual(len(graph["nodes"]), 1)
        self.assertEqual(graph["nodes"][0]["graph_index"], 1)
        self.assertEqual(graph["nodes"][0]["lowering"]["family"], "f32_alu")
        self.assertEqual(graph["nodes"][0]["lowering"]["profile_name"], "P00")
        self.assertIsNone(graph["nodes"][0]["lowering"]["fusion_group"])
        self.assertFalse(
            graph["lowering_policy"]["executable_command_descriptors_generated"]
        )
        self.assertEqual(
            graph["lowering_policy"]["order"], "original_topological_order"
        )
        self.assertEqual(graph["lowering_policy"]["fusion"], "none")

        # Both immediate GGML source edges survive.  The metadata VIEW itself
        # is not an executable GraphIR node, but its buffer alias is retained.
        edges = graph["nodes"][0]["source_edges"]
        self.assertEqual([edge["slot"] for edge in edges], [0, 1])
        self.assertEqual(edges[0]["source_ref"], {"kind": "node", "index": 0})
        view_buffer = next(
            buffer
            for buffer in graph["buffers"]
            if buffer["origin"] == {
                "kind": "node",
                "index": 0,
                "canonical_id": "7b8b706949e74aba06f6f29cdb79c366d354ac1c8a0894ea306537e8822cba98",
            }
        )
        self.assertEqual(view_buffer["buffer_id"], edges[0]["buffer_id"])
        self.assertEqual(view_buffer["alias"]["byte_offset"], 0)
        self.assertRegex(view_buffer["alias"]["buffer_id"], r"e\.[a-z2-7]{52}\Z")

        buffer_ids = [buffer["buffer_id"] for buffer in graph["buffers"]]
        self.assertEqual(len(buffer_ids), len(set(buffer_ids)))
        self.assertEqual(
            buffer_ids,
            [buffer["buffer_id"] for buffer in second["graph_ir"]["buffers"]],
        )
        for buffer in graph["buffers"]:
            expected_prefix = "n" if buffer["origin"]["kind"] == "node" else "e"
            self.assertRegex(buffer["buffer_id"], rf"{expected_prefix}\.[a-z2-7]{{52}}\Z")
            self.assertIsNotNone(npu_artifact.BUFFER_ID_RE.fullmatch(buffer["buffer_id"]))

        encoded = qwen_graph_ir.canonical_bytes(first).decode("utf-8")
        self.assertNotIn("descriptor_words", encoded)
        self.assertNotIn("command.bin", encoded)
        for buffer in graph["buffers"]:
            self.assertEqual(buffer["runtime_binding"]["state"], "unresolved")
            self.assertIsNone(buffer["runtime_binding"]["iova"])
        for binding in graph["nodes"][0]["dynamic_address_bindings"]:
            self.assertEqual(binding["state"], "unresolved")

    def test_buffer_ids_bind_node_origin_and_external_descriptor_identity(self) -> None:
        baseline = qwen_graph_ir.import_manifest_object(
            load_fixture_object(), owner_mode=qwen_graph_ir.OWNER_MODE_FIXTURE
        )["graph_ir"]

        changed_origin = load_fixture_object()
        origin_node = changed_origin["manifest"]["nodes"][0]
        origin_node["semantic_key"]["occurrence"] += 1
        origin_node["canonical_id"] = qwen_graph_ir.canonical_sha256(
            origin_node["semantic_key"]
        )
        reseal(changed_origin)
        origin_result = qwen_graph_ir.import_manifest_object(
            changed_origin, owner_mode=qwen_graph_ir.OWNER_MODE_FIXTURE
        )["graph_ir"]

        baseline_node_id = next(
            buffer["buffer_id"]
            for buffer in baseline["buffers"]
            if buffer["origin"]["kind"] == "node" and buffer["origin"]["index"] == 0
        )
        changed_node_id = next(
            buffer["buffer_id"]
            for buffer in origin_result["buffers"]
            if buffer["origin"]["kind"] == "node" and buffer["origin"]["index"] == 0
        )
        self.assertNotEqual(baseline_node_id, changed_node_id)

        changed_descriptor = load_fixture_object()
        external = changed_descriptor["manifest"]["external_tensors"][0]
        external["descriptor"]["name"] = "tiny.input0.renamed"
        source = changed_descriptor["manifest"]["nodes"][0]["sources"][0]
        source["descriptor"] = copy.deepcopy(external["descriptor"])
        reseal(changed_descriptor, 0)
        descriptor_result = qwen_graph_ir.import_manifest_object(
            changed_descriptor, owner_mode=qwen_graph_ir.OWNER_MODE_FIXTURE
        )["graph_ir"]

        baseline_external_id = next(
            buffer["buffer_id"]
            for buffer in baseline["buffers"]
            if buffer["origin"]["kind"] == "external"
            and buffer["origin"]["index"] == 0
        )
        changed_external_id = next(
            buffer["buffer_id"]
            for buffer in descriptor_result["buffers"]
            if buffer["origin"]["kind"] == "external"
            and buffer["origin"]["index"] == 0
        )
        self.assertNotEqual(baseline_external_id, changed_external_id)

    def test_shared_id_encoding_is_full_and_domain_separated(self) -> None:
        canonical_id = "0" * 64
        descriptor = {"name": "same identity payload"}
        node_id = npu_ids.node_buffer_id(canonical_id)
        external_id = npu_ids.external_buffer_id(0, descriptor)

        self.assertRegex(node_id, r"n\.[a-z2-7]{52}\Z")
        self.assertRegex(external_id, r"e\.[a-z2-7]{52}\Z")
        self.assertEqual(
            node_id,
            "n.rkbvbkr65xaptfbpr7btpvv47xzlz5chsstyck5bwj6kxugoitgq",
        )
        self.assertEqual(
            external_id,
            "e.2gw774r7hkkaw55wt4iuapetkg4ahfwk666vk6nhc34x7li4i52q",
        )
        self.assertEqual(node_id, npu_ids.node_buffer_id(canonical_id))
        self.assertEqual(external_id, npu_ids.external_buffer_id(0, descriptor))
        self.assertEqual(
            npu_ids.external_buffer_id(7, {"a": 1, "b": 2}),
            npu_ids.external_buffer_id(7, {"b": 2, "a": 1}),
        )
        self.assertNotEqual(node_id[2:], external_id[2:])
        self.assertNotIn("=", node_id + external_id)

    def test_rejects_forward_node_source(self) -> None:
        envelope = load_fixture_object()
        source = envelope["manifest"]["nodes"][1]["sources"][0]
        source["ref"] = {"kind": "node", "index": 1}
        source["descriptor"] = copy.deepcopy(envelope["manifest"]["nodes"][1]["descriptor"])
        reseal(envelope, 1)
        with self.assertRaisesRegex(qwen_graph_ir.GraphIRError, "FORWARD_SOURCE_REF"):
            qwen_graph_ir.import_manifest_object(
                envelope, owner_mode=qwen_graph_ir.OWNER_MODE_FIXTURE
            )

    def test_rejects_canonical_identity_substitution(self) -> None:
        envelope = load_fixture_object()
        envelope["manifest"]["nodes"][1]["canonical_id"] = "0" * 64
        reseal(envelope)
        with self.assertRaisesRegex(qwen_graph_ir.GraphIRError, "CANONICAL_ID"):
            qwen_graph_ir.import_manifest_object(
                envelope, owner_mode=qwen_graph_ir.OWNER_MODE_FIXTURE
            )

    def test_rejects_source_descriptor_not_owned_by_ref(self) -> None:
        envelope = load_fixture_object()
        envelope["manifest"]["nodes"][1]["sources"][1]["descriptor"]["name"] = "wrong"
        reseal(envelope, 1)
        with self.assertRaisesRegex(qwen_graph_ir.GraphIRError, "SOURCE_DESCRIPTOR"):
            qwen_graph_ir.import_manifest_object(
                envelope, owner_mode=qwen_graph_ir.OWNER_MODE_FIXTURE
            )

    def test_rejects_unowned_required_node(self) -> None:
        envelope = load_fixture_object()
        node = envelope["manifest"]["nodes"][1]
        node["descriptor"]["ne"] = [15, 1, 1, 1]
        node["descriptor"]["nb"] = [4, 60, 60, 60]
        reseal(envelope, 1)
        with self.assertRaisesRegex(qwen_graph_ir.GraphIRError, "OWNER_GAP"):
            qwen_graph_ir.import_manifest_object(
                envelope, owner_mode=qwen_graph_ir.OWNER_MODE_FIXTURE
            )


@unittest.skipUnless(
    os.environ.get(REAL_MANIFEST_ENV),
    f"set {REAL_MANIFEST_ENV} to the canonical Qwen v5 manifest",
)
class ExactQwenGraphIRTests(unittest.TestCase):
    def test_exact_1080_node_owner_partition(self) -> None:
        manifest = pathlib.Path(os.environ[REAL_MANIFEST_ENV])
        result = qwen_graph_ir.load_graph_ir(manifest)
        graph = result["graph_ir"]
        coverage = graph["coverage"]
        self.assertEqual(coverage["required_node_count"], 1080)
        self.assertEqual(coverage["metadata_node_count"], 634)
        self.assertEqual(
            coverage["owner_family_counts"],
            qwen_graph_ir.EXPECTED_QWEN35_V5_OWNER_COUNTS,
        )
        self.assertTrue(coverage["assigned_exactly_once"])
        self.assertEqual(coverage["gap_count"], 0)
        self.assertEqual(coverage["overlap_count"], 0)
        self.assertEqual(len(graph["buffers"]), 2089)
        self.assertEqual(len(graph["nodes"]), 1080)
        self.assertEqual(sum(len(node["source_edges"]) for node in graph["nodes"]), 1840)
        self.assertEqual(
            [node["graph_index"] for node in graph["nodes"]],
            sorted(node["graph_index"] for node in graph["nodes"]),
        )
        self.assertEqual(
            {node["classification"] for node in graph["nodes"]},
            {"compute", "mover"},
        )
        self.assertEqual(
            result["graph_ir_sha256"], qwen_graph_ir.canonical_sha256(graph)
        )


if __name__ == "__main__":
    unittest.main()
