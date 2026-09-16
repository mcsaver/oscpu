from __future__ import annotations

import copy
import importlib.util
import pathlib
import sys
import tempfile
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[5]
TOOL = ROOT / "npc/rv64/eval/ppa/tools/architecture_current_checker_replay.py"
SPEC = importlib.util.spec_from_file_location("architecture_current_checker_replay", TOOL)
assert SPEC is not None and SPEC.loader is not None
replay = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = replay
SPEC.loader.exec_module(replay)


class ArchitectureCurrentCheckerReplayTests(unittest.TestCase):
    def test_allowed_checker_hash_is_refreshed_without_touching_metrics(self) -> None:
        test_id = "pair_matrix"
        files = {
            rel: replay.arch.digest(replay.arch.safe_artifact(ROOT, rel))
            for rel in replay.PROVENANCE_PATHS[test_id]
        }
        allowed = next(iter(replay.ALLOWED_DRIFT_PATHS))
        files[allowed] = "0" * 64
        record = {
            "metrics": {"sentinel": 7},
            "provenance": {
                "files": files,
                "sha256": replay.arch.canonical_digest(files),
            },
        }
        original = copy.deepcopy(record)
        updated, drift = replay.refresh_record(ROOT, test_id, record)
        self.assertEqual(drift, [allowed])
        self.assertEqual(updated["metrics"], {"sentinel": 7})
        self.assertEqual(record, original)
        self.assertEqual(
            updated["provenance"]["files"][allowed],
            replay.arch.digest(replay.arch.safe_artifact(ROOT, allowed)),
        )

    def test_non_allowed_provenance_drift_is_rejected(self) -> None:
        test_id = "pair_matrix"
        files = {
            rel: replay.arch.digest(replay.arch.safe_artifact(ROOT, rel))
            for rel in replay.PROVENANCE_PATHS[test_id]
        }
        unallowed = next(
            rel for rel in files if rel not in replay.ALLOWED_DRIFT_PATHS
        )
        files[unallowed] = "0" * 64
        record = {"provenance": {
            "files": files,
            "sha256": replay.arch.canonical_digest(files),
        }}
        with self.assertRaisesRegex(ValueError, "unauthorized provenance drift"):
            replay.refresh_record(ROOT, test_id, record)

    def test_inventory_shrink_is_rejected(self) -> None:
        test_id = "no_static_lane_semantics"
        files = {
            rel: replay.arch.digest(replay.arch.safe_artifact(ROOT, rel))
            for rel in replay.PROVENANCE_PATHS[test_id]
        }
        files.pop(next(iter(files)))
        with self.assertRaisesRegex(ValueError, "inventory mismatch"):
            replay.refresh_record(ROOT, test_id, {"provenance": {"files": files}})


if __name__ == "__main__":
    unittest.main()
