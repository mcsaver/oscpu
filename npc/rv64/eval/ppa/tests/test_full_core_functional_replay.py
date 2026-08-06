from __future__ import annotations

import pathlib
import tempfile
import unittest
from unittest import mock

from npc.rv64.eval.ppa.tools import full_core_functional_replay as replay


class FullCoreFunctionalReplayTests(unittest.TestCase):
    def test_relative_repo_dir_accepts_only_directory_inside_root(self) -> None:
        with tempfile.TemporaryDirectory(prefix="rv64-functional-replay-root-") as raw:
            root = pathlib.Path(raw)
            evidence = root / "evidence/functional"
            evidence.mkdir(parents=True)
            alias = root / "alias"
            alias.symlink_to(evidence, target_is_directory=True)
            with mock.patch.object(replay, "ROOT", root):
                self.assertEqual(
                    replay.relative_repo_dir(evidence), "evidence/functional"
                )
                with self.assertRaisesRegex(RuntimeError, "symlink"):
                    replay.relative_repo_dir(alias)

    def test_benchmark_failure_boundary_is_exact(self) -> None:
        accepted = (
            "benchmark:coremark: guest result markers drifted: missing=[] "
            "duplicate=[] contradictory_values=[] contradictory=[] good_traps=0"
        )
        self.assertIsNotNone(replay.BENCHMARK_ORACLE_FAILURE_RE.fullmatch(accepted))
        for changed in (
            accepted.replace("good_traps=0", "good_traps=2"),
            accepted.replace("missing=[]", "missing=['CoreMark PASS']"),
            accepted + " trailing",
        ):
            with self.subTest(changed=changed):
                self.assertIsNone(
                    replay.BENCHMARK_ORACLE_FAILURE_RE.fullmatch(changed)
                )

    def test_official_build_outputs_use_isa_directory(self) -> None:
        legacy = mock.Mock(OFFICIAL_TREE=pathlib.Path("/repo/riscv-tests"))
        with mock.patch.object(
            replay.module_evidence,
            "relative",
            return_value="official/riscv-tests/isa",
        ) as relative:
            observed = replay.official_build_outputs(legacy, ["rv64ui-p-add"])

        relative.assert_called_once_with(legacy.OFFICIAL_TREE / "isa")
        self.assertEqual(
            observed,
            {
                ("official_program_sources", "official/riscv-tests/isa/rv64ui-p-add"),
                (
                    "official_program_sources",
                    "official/riscv-tests/isa/rv64ui-p-add.dump",
                ),
            },
        )

    def test_generated_elf_drift_is_removed_from_both_bindings(self) -> None:
        with tempfile.TemporaryDirectory(prefix="rv64-functional-replay-") as raw:
            root = pathlib.Path(raw)
            binary = root / "official/rv64ui-p-add"
            source = root / "official/add.S"
            binary.parent.mkdir(parents=True)
            binary.write_bytes(b"\x7fELFcurrent")
            source.write_text("add x1, x2, x3\n", encoding="utf-8")
            before = {
                "groups": {
                    "official_program_sources": {
                        "official/rv64ui-p-add": "old-elf",
                        "official/add.S": "source",
                    }
                }
            }
            after = {
                "groups": {
                    "official_program_sources": {
                        "official/rv64ui-p-add": "new-elf",
                        "official/add.S": "source",
                    }
                }
            }

            known = {
                ("official_program_sources", "official/rv64ui-p-add")
            }
            with mock.patch.object(replay, "ROOT", root):
                filtered_before, removed_before = replay.filter_generated_inputs(
                    before, known)
                filtered_after, removed_after = replay.filter_generated_inputs(
                    after, known)

            self.assertEqual(filtered_before, filtered_after)
            self.assertEqual(removed_before, removed_after)
            self.assertEqual(
                removed_before,
                [("official_program_sources", "official/rv64ui-p-add")],
            )

    def test_real_source_drift_remains_visible(self) -> None:
        with tempfile.TemporaryDirectory(prefix="rv64-functional-replay-") as raw:
            root = pathlib.Path(raw)
            source = root / "official/add.S"
            source.parent.mkdir(parents=True)
            source.write_text("add x1, x2, x3\n", encoding="utf-8")
            before = {
                "groups": {"official_program_sources": {"official/add.S": "old"}}
            }
            after = {
                "groups": {"official_program_sources": {"official/add.S": "new"}}
            }

            with mock.patch.object(replay, "ROOT", root):
                filtered_before, _ = replay.filter_generated_inputs(before, set())
                filtered_after, _ = replay.filter_generated_inputs(after, set())

            self.assertNotEqual(filtered_before, filtered_after)
            self.assertEqual(
                replay.binding_changes(filtered_before, filtered_after),
                [("official_program_sources", "official/add.S")],
            )

    def test_unlisted_path_drift_is_not_hidden(self) -> None:
        before = {
            "groups": {"official_program_sources": {"official/source": "old"}}
        }
        after = {
            "groups": {"official_program_sources": {"official/source": "new"}}
        }

        filtered_before, removed_before = replay.filter_generated_inputs(
            before, set())
        filtered_after, removed_after = replay.filter_generated_inputs(after, set())

        self.assertEqual(removed_before, [])
        self.assertEqual(removed_after, [])
        self.assertEqual(
            replay.binding_changes(filtered_before, filtered_after),
            [("official_program_sources", "official/source")],
        )

    def test_copy_regular_rejects_symlink(self) -> None:
        with tempfile.TemporaryDirectory(prefix="rv64-functional-copy-") as raw:
            root = pathlib.Path(raw)
            source = root / "source"
            alias = root / "alias"
            destination = root / "destination"
            source.write_text("evidence\n", encoding="utf-8")
            alias.symlink_to(source)

            with self.assertRaisesRegex(RuntimeError, "not a regular file"):
                replay.copy_regular(alias, destination)
            self.assertFalse(destination.exists())

    def test_phase_command_requires_recorded_zero_return_code(self) -> None:
        with tempfile.TemporaryDirectory(prefix="rv64-functional-phase-") as raw:
            root = pathlib.Path(raw)
            passed = root / "pass.log"
            failed = root / "fail.log"
            passed.write_text(
                "phase=official\ncommand=run official\nphase_return_code=0\n",
                encoding="utf-8",
            )
            failed.write_text(
                "phase=official\ncommand=run official\nphase_return_code=1\n",
                encoding="utf-8",
            )

            self.assertEqual(replay.phase_command(passed), "run official")
            with self.assertRaisesRegex(RuntimeError, "not PASS-complete"):
                replay.phase_command(failed)


if __name__ == "__main__":
    unittest.main()
