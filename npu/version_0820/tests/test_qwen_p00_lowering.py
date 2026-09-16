#!/usr/bin/env python3

from __future__ import annotations

import os
import unittest

from compiler.qwen_p00_lowering import (
    P00LoweringError,
    exact_p00_canonical_ids,
    select_exact_p00,
)


FIRST_P00 = "1e3dac5ab4a21eb84d4d473de864ce2aa3129e1d4f248ee44d766549a51e6f3f"


class QwenP00LoweringTests(unittest.TestCase):
    def test_structural_fixture_is_not_a_production_codegen_source(self) -> None:
        with self.assertRaises(P00LoweringError) as caught:
            select_exact_p00(
                "compiler/fixtures/tiny_qwen_graph_manifest.json",
                "0" * 64,
            )
        self.assertEqual(caught.exception.code, "P00_GRAPHIR")

    @unittest.skipUnless(
        os.environ.get("NPU_QWEN_GRAPH_MANIFEST"),
        "set NPU_QWEN_GRAPH_MANIFEST for exact canonical P00 lowering",
    )
    def test_real_manifest_p00_view_and_weight_boundary(self) -> None:
        path = os.environ["NPU_QWEN_GRAPH_MANIFEST"]
        identities = exact_p00_canonical_ids(path)
        self.assertEqual(len(identities), 18)
        self.assertEqual(identities[0], FIRST_P00)
        selected = select_exact_p00(path, FIRST_P00)
        self.assertEqual(selected.manifest_graph_index, 30)
        self.assertEqual(selected.schedule_position, 15)
        self.assertEqual(selected.profile.profile_id, 0)
        self.assertEqual(selected.src0.logical_origin_index, 29)
        self.assertEqual(selected.src0.storage_origin_index, 28)
        self.assertEqual(selected.src0.alias_offset, 0)
        self.assertEqual(selected.src0.logical_size, 64)
        self.assertEqual(selected.src1.logical_origin_kind, "external")
        self.assertEqual(selected.src1.logical_origin_index, 8)
        self.assertEqual(selected.src1.tensor_name, "blk.0.ssm_dt.bias")
        self.assertEqual(selected.dst.logical_origin_index, 30)

    @unittest.skipUnless(
        os.environ.get("NPU_QWEN_GRAPH_MANIFEST"),
        "set NPU_QWEN_GRAPH_MANIFEST for exact canonical P00 lowering",
    )
    def test_unknown_or_non_p00_identity_fails_closed(self) -> None:
        path = os.environ["NPU_QWEN_GRAPH_MANIFEST"]
        with self.assertRaises(P00LoweringError) as missing:
            select_exact_p00(path, "0" * 64)
        self.assertEqual(missing.exception.code, "P00_NODE_LOOKUP")


if __name__ == "__main__":
    unittest.main()
