#!/usr/bin/env python3
"""Fail-closed provenance tests for the V8L holder evidence builder."""

from __future__ import annotations

import copy
import hashlib
import importlib.util
import sys
import tempfile
import unittest
from pathlib import Path


TEST_DIR = Path(__file__).resolve().parent
REPO_ROOT = TEST_DIR.parents[4]
BUILDER = (
    REPO_ROOT
    / ".github/task-runs/2026-07-20-rv64-v8l-global-producer-no-live-reuse"
    / "build-current-census-evidence.py"
)
RUNNER = BUILDER.with_name("run-focused.sh")

SPEC = importlib.util.spec_from_file_location(
    "v8l_current_census_evidence_test_subject", BUILDER
)
assert SPEC is not None and SPEC.loader is not None
builder = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = builder
SPEC.loader.exec_module(builder)


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


class V8lCurrentCensusEvidenceTests(unittest.TestCase):
    def snapshot(self) -> dict[str, object]:
        return {
            "schema": builder.RTL_BINDING_SCHEMA,
            "design_id": "sha256:" + "a" * 64,
            "rtl_files": {
                "npc/rv64/vsrc/example.v": "b" * 64,
            },
        }

    def test_identical_pre_post_and_live_binding_passes(self) -> None:
        value = self.snapshot()
        result = builder.validate_rtl_snapshots(
            copy.deepcopy(value),
            copy.deepcopy(value),
            copy.deepcopy(value),
        )
        self.assertEqual(result, value)
        self.assertIsNot(result, value)

    def test_pre_post_rtl_drift_is_rejected(self) -> None:
        pre = self.snapshot()
        post = self.snapshot()
        post["rtl_files"]["npc/rv64/vsrc/example.v"] = "c" * 64
        with self.assertRaisesRegex(
            RuntimeError, "drifted during the focused run"
        ):
            builder.validate_rtl_snapshots(pre, post, copy.deepcopy(post))

    def test_old_logs_cannot_be_relabelled_with_live_design_id(self) -> None:
        old = self.snapshot()
        live = self.snapshot()
        live["design_id"] = "sha256:" + "d" * 64
        live["rtl_files"]["npc/rv64/vsrc/example.v"] = "e" * 64
        with self.assertRaisesRegex(
            RuntimeError, "live canonical RTL differs"
        ):
            builder.validate_rtl_snapshots(
                copy.deepcopy(old), copy.deepcopy(old), live
            )

    def test_runner_source_manifests_bind_live_bytes(self) -> None:
        with tempfile.TemporaryDirectory(prefix="v8l-provenance-") as temp:
            root = Path(temp)
            source = root / "npc/rv64/vsrc/example.v"
            source.parent.mkdir(parents=True)
            source.write_text("module example; endmodule\n", encoding="utf-8")
            row = f"{digest(source)}  {source}\n"
            pre = root / "sources.pre.sha256"
            post = root / "sources.post.sha256"
            pre.write_text(row, encoding="utf-8")
            post.write_text(row, encoding="utf-8")

            result = builder.validate_runner_source_manifests(
                pre, post, root
            )
            self.assertEqual(
                result,
                {"npc/rv64/vsrc/example.v": digest(source)},
            )

            source.write_text(
                "module example; wire changed; endmodule\n",
                encoding="utf-8",
            )
            with self.assertRaisesRegex(
                RuntimeError, "live focused runner input differs"
            ):
                builder.validate_runner_source_manifests(pre, post, root)

    def test_runner_pre_post_manifest_drift_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory(prefix="v8l-provenance-") as temp:
            root = Path(temp)
            source = root / "example.v"
            source.write_text("module example; endmodule\n", encoding="utf-8")
            pre = root / "sources.pre.sha256"
            post = root / "sources.post.sha256"
            pre.write_text(
                f"{digest(source)}  {source}\n", encoding="utf-8"
            )
            post.write_text(
                f"{'f' * 64}  {source}\n", encoding="utf-8"
            )
            with self.assertRaisesRegex(
                RuntimeError, "input hashes drifted"
            ):
                builder.validate_runner_source_manifests(pre, post, root)

    def test_dynamic_source_list_excludes_hash_envelope(self) -> None:
        text = RUNNER.read_text(encoding="utf-8")
        source_block = text.split("source_paths=(", 1)[1].split("\n)", 1)[0]
        self.assertNotIn('"$MANIFEST"', source_block)
        self.assertGreaterEqual(
            text.count('python3 "$CHECKER" --manifest "$MANIFEST"'), 2
        )


if __name__ == "__main__":
    unittest.main(verbosity=2)
