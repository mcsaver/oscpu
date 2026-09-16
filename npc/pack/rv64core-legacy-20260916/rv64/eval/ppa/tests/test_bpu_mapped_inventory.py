from __future__ import annotations

import copy
import hashlib
import tempfile
import unittest
from pathlib import Path

from npc.rv64.eval.ppa.tools import traceable_mapped_sta as mapped_sta


TCL_PATH = (
    mapped_sta.ROOT / "npc/rv64/eval/ppa/opensta-traceable-mapped-current.tcl"
)
PARSER_PATH = mapped_sta.ROOT / "npc/rv64/eval/ppa/tools/traceable_mapped_sta.py"
RUNNER_PATH = mapped_sta.ROOT / "npc/rv64/eval/ppa/run-traceable-mapped-current.sh"

WRAPPER_SOURCE = (
    "NpcTop/u_core/u_frontend/u_branch_direction_predictor/"
    "u_local_pht/update_taken_i"
)
BANK_SOURCE = (
    "NpcTop/u_core/u_frontend/u_branch_direction_predictor/"
    "u_local_pht/g_bank[0].u_bank/update_taken_i"
)


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def write_negative_inventory(
    directory: Path,
    *,
    matched: int,
    numeric: int,
    rows: list[tuple[str, str]],
    declared_negative: int | None = None,
) -> Path:
    path = directory / mapped_sta.BPU_NEGATIVE_SLACK_FILENAME
    lines = [
        f"schema\t{mapped_sta.BPU_NEGATIVE_SLACK_SCHEMA}",
        f"inventory_semantics\t{mapped_sta.BPU_NEGATIVE_SLACK_SEMANTICS}",
        f"matched_pin_count\t{matched}",
        f"numeric_slack_pin_count\t{numeric}",
        f"negative_slack_pin_count\t{len(rows) if declared_negative is None else declared_negative}",
        "full_name\tslack_max_ns",
    ]
    lines.extend(f"{name}\t{slack}" for name, slack in rows)
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    return path


def write_fanout_inventory(
    directory: Path,
    sources: list[tuple[str, list[str]]],
    *,
    declared_sources: int | None = None,
) -> Path:
    path = directory / mapped_sta.BPU_UPDATE_FANOUT_FILENAME
    ordered_sources = sorted(sources)
    lines = [
        f"schema\t{mapped_sta.BPU_UPDATE_FANOUT_SCHEMA}",
        f"inventory_semantics\t{mapped_sta.BPU_UPDATE_FANOUT_SEMANTICS}",
        f"matched_source_count\t{len(sources) if declared_sources is None else declared_sources}",
        "record_type\tsource_full_name\tvalue",
    ]
    for source, endpoints in ordered_sources:
        ordered_endpoints = sorted(endpoints)
        lines.append(f"source\t{source}\t{len(ordered_endpoints)}")
        lines.extend(
            f"endpoint\t{source}\t{endpoint}" for endpoint in ordered_endpoints
        )
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    return path


def pipeline_contract_errors(tcl: str, parser: str, runner: str) -> list[str]:
    required = {
        "tcl": (
            "get_pins -hierarchical -quiet *u_branch_direction_predictor*",
            "get_fanout -from [list $source] -flat -endpoints_only -trace_arcs timing",
            "write_bpu_negative_slack_inventory $bpu_negative_slack_path",
            "write_bpu_update_fanout_inventory $bpu_update_fanout_path",
        ),
        "parser": (
            '"bpu_negative_slack": out_dir / BPU_NEGATIVE_SLACK_FILENAME',
            '"bpu_update_fanout": out_dir / BPU_UPDATE_FANOUT_FILENAME',
            'if profile == MAPPED_ARTIFACT_PROFILE_BPU_LOCAL_PHT:',
            "result.update(parse_bpu_inventories(out_dir))",
            '"mapped_profile_evidence": profile_evidence',
        ),
        "runner": (
            '-s "${bpu_negative_slack_artifact}"',
            '! -L "${bpu_negative_slack_artifact}"',
            '-s "${bpu_update_fanout_artifact}"',
            '! -L "${bpu_update_fanout_artifact}"',
            '"${sta_tcl}" "${trace_checker}" "${architecture_registry}" "${runner_path}"',
            "stamp-mapped-summary",
        ),
    }
    texts = {"tcl": tcl, "parser": parser, "runner": runner}
    errors = [
        f"{owner} lacks {marker}"
        for owner, markers in required.items()
        for marker in markers
        if marker not in texts[owner]
    ]
    if (
        "write_bpu_negative_slack_inventory $bpu_negative_slack_path" in tcl
        and "write_note $complete_path" in tcl
        and tcl.index("write_bpu_negative_slack_inventory $bpu_negative_slack_path")
        > tcl.index("write_note $complete_path")
    ):
        errors.append("Tcl writes the negative-slack inventory after COMPLETE")
    if (
        'python3 -B "${parser}" variant' in runner
        and "stamp-mapped-summary" in runner
        and runner.index('python3 -B "${parser}" variant')
        > runner.index("stamp-mapped-summary")
    ):
        errors.append("runner binds summary before inventory parsing")
    return errors


class BpuMappedInventoryTests(unittest.TestCase):
    def test_positive_multiple_negative_and_fanout_summary_fields(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            negative_path = write_negative_inventory(
                directory,
                matched=5,
                numeric=4,
                rows=[
                    (
                        "NpcTop/u_core/u_frontend/u_branch_direction_predictor/"
                        "late_pin_a/D",
                        "-0.125",
                    ),
                    (
                        "NpcTop/u_core/u_frontend/u_branch_direction_predictor/"
                        "late_pin_b/D",
                        "-1.25e-2",
                    ),
                ],
            )
            fanout_path = write_fanout_inventory(
                directory,
                [
                    (
                        WRAPPER_SOURCE,
                        [
                            "NpcTop/u_core/u_frontend/u_branch_direction_predictor/"
                            "u_local_pht/g_bank[0].u_bank/upd_taken_q_DFF/D",
                            "NpcTop/u_core/u_frontend/u_branch_direction_predictor/"
                            "u_local_pht/g_bank[1].u_bank/upd_taken_q_DFF/D",
                        ],
                    ),
                    (
                        BANK_SOURCE,
                        [
                            "NpcTop/u_core/u_frontend/u_branch_direction_predictor/"
                            "u_local_pht/g_bank[0].u_bank/upd_taken_q_DFF/D"
                        ],
                    ),
                ],
            )

            summary = mapped_sta.parse_bpu_inventories(directory)
            negative = summary["bpu_negative_slack_inventory"]
            self.assertEqual(mapped_sta.BPU_NEGATIVE_SLACK_SCHEMA, negative["schema"])
            self.assertEqual(5, negative["matched_pin_count"])
            self.assertEqual(4, negative["numeric_slack_pin_count"])
            self.assertEqual(2, negative["negative_slack_pin_count"])
            self.assertEqual(
                [-0.125, -0.0125],
                [row["slack_max_ns"] for row in negative["negative_slack_pins"]],
            )
            self.assertEqual(sha256(negative_path), negative["artifact"]["sha256"])

            fanout = summary["bpu_update_fanout_inventory"]
            self.assertEqual(mapped_sta.BPU_UPDATE_FANOUT_SCHEMA, fanout["schema"])
            self.assertEqual(2, fanout["matched_source_count"])
            self.assertEqual(1, fanout["wrapper_source_count"])
            self.assertEqual(2, fanout["maximum_endpoint_count"])
            self.assertEqual(3, fanout["source_endpoint_count"])
            self.assertEqual(sha256(fanout_path), fanout["artifact"]["sha256"])
            self.assertEqual(
                sorted((BANK_SOURCE, WRAPPER_SOURCE)),
                [source["full_name"] for source in fanout["sources"]],
            )

    def test_positive_zero_negative_slack_is_allowed(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            path = write_negative_inventory(
                directory, matched=3, numeric=2, rows=[]
            )
            value = mapped_sta.parse_bpu_negative_slack_inventory(path)
            self.assertEqual(0, value["negative_slack_pin_count"])
            self.assertEqual([], value["negative_slack_pins"])

    def test_negative_slack_counts_duplicates_and_nonnegative_rows_fail(self) -> None:
        name = (
            "NpcTop/u_core/u_frontend/u_branch_direction_predictor/late_pin/D"
        )
        cases = (
            ("count", 2, 2, [(name, "-0.1")], 2),
            ("duplicate", 2, 2, [(name, "-0.1"), (name, "-0.2")], None),
            ("nonnegative", 1, 1, [(name, "0.0")], None),
            ("numeric_gt_matched", 1, 2, [], 0),
        )
        for label, matched, numeric, rows, declared in cases:
            with self.subTest(label=label), tempfile.TemporaryDirectory() as temporary:
                path = write_negative_inventory(
                    Path(temporary),
                    matched=matched,
                    numeric=numeric,
                    rows=rows,
                    declared_negative=declared,
                )
                with self.assertRaises(mapped_sta.EvidenceError):
                    mapped_sta.parse_bpu_negative_slack_inventory(path)

    def test_fanout_missing_wrapper_and_more_than_sixteen_fail(self) -> None:
        endpoint = (
            "NpcTop/u_core/u_frontend/u_branch_direction_predictor/"
            "u_local_pht/g_bank[0].u_bank/upd_taken_q_DFF/D"
        )
        with tempfile.TemporaryDirectory() as temporary:
            path = write_fanout_inventory(
                Path(temporary), [(BANK_SOURCE, [endpoint])]
            )
            with self.assertRaises(mapped_sta.EvidenceError):
                mapped_sta.parse_bpu_update_fanout_inventory(path)
        with tempfile.TemporaryDirectory() as temporary:
            endpoints = [
                "NpcTop/u_core/u_frontend/u_branch_direction_predictor/"
                f"u_local_pht/g_bank[{index}].u_bank/upd_taken_q_DFF/D"
                for index in range(17)
            ]
            path = write_fanout_inventory(
                Path(temporary), [(WRAPPER_SOURCE, endpoints)]
            )
            with self.assertRaises(mapped_sta.EvidenceError):
                mapped_sta.parse_bpu_update_fanout_inventory(path)

    def test_fanout_source_endpoint_consistency_and_counts_fail(self) -> None:
        endpoint = (
            "NpcTop/u_core/u_frontend/u_branch_direction_predictor/"
            "u_local_pht/g_bank[0].u_bank/upd_taken_q_DFF/D"
        )
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            path = write_fanout_inventory(
                directory, [(WRAPPER_SOURCE, [endpoint])]
            )
            text = path.read_text(encoding="utf-8").replace(
                f"endpoint\t{WRAPPER_SOURCE}\t",
                f"endpoint\t{BANK_SOURCE}\t",
            )
            path.write_text(text, encoding="utf-8")
            with self.assertRaises(mapped_sta.EvidenceError):
                mapped_sta.parse_bpu_update_fanout_inventory(path)
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            path = write_fanout_inventory(
                directory, [(WRAPPER_SOURCE, [endpoint])], declared_sources=2
            )
            with self.assertRaises(mapped_sta.EvidenceError):
                mapped_sta.parse_bpu_update_fanout_inventory(path)

    def test_direct_valid_or_counter_entry_d_endpoint_fails(self) -> None:
        endpoints = (
            "NpcTop/u_core/u_frontend/u_branch_direction_predictor/"
            "u_local_pht/g_bank[0].u_bank/valid_q[19]_DFF/D",
            "NpcTop/u_core/u_frontend/u_branch_direction_predictor/"
            "u_local_pht/g_bank[0].u_bank/counter_q[19]_DFF/D",
        )
        for endpoint in endpoints:
            with self.subTest(endpoint=endpoint), tempfile.TemporaryDirectory() as temporary:
                path = write_fanout_inventory(
                    Path(temporary), [(WRAPPER_SOURCE, [endpoint])]
                )
                with self.assertRaises(mapped_sta.EvidenceError):
                    mapped_sta.parse_bpu_update_fanout_inventory(path)

    def test_missing_artifact_fails_closed(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            write_negative_inventory(directory, matched=1, numeric=1, rows=[])
            with self.assertRaises(mapped_sta.EvidenceError):
                mapped_sta.parse_bpu_inventories(directory)

    def test_bpu_profile_accepts_only_the_bpu_artifact_family(self) -> None:
        endpoint = (
            "NpcTop/u_core/u_frontend/u_branch_direction_predictor/"
            "u_local_pht/g_bank[0].u_bank/upd_taken_q_DFF/D"
        )
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            write_negative_inventory(directory, matched=1, numeric=1, rows=[])
            write_fanout_inventory(directory, [(WRAPPER_SOURCE, [endpoint])])
            evidence = mapped_sta.parse_mapped_profile_evidence(
                mapped_sta.MAPPED_ARTIFACT_PROFILE_BPU_LOCAL_PHT,
                directory,
                directory / "unused-synth-stat.txt",
            )
            self.assertEqual(
                [
                    mapped_sta.BPU_NEGATIVE_SLACK_FILENAME,
                    mapped_sta.BPU_UPDATE_FANOUT_FILENAME,
                ],
                evidence["artifact_family"],
            )
            self.assertEqual(
                1,
                evidence["bpu_update_fanout_inventory"]["wrapper_source_count"],
            )

            (directory / mapped_sta.FP_INTERNAL_PATHS_FILENAME).write_text(
                "wrong-family\n", encoding="utf-8"
            )
            with self.assertRaises(mapped_sta.EvidenceError):
                mapped_sta.parse_mapped_profile_evidence(
                    mapped_sta.MAPPED_ARTIFACT_PROFILE_BPU_LOCAL_PHT,
                    directory,
                    directory / "unused-synth-stat.txt",
                )

    def test_bpu_profile_receipts_reject_replay_alias_and_wrong_basename(self) -> None:
        endpoint = (
            "NpcTop/u_core/u_frontend/u_branch_direction_predictor/"
            "u_local_pht/g_bank[0].u_bank/upd_taken_q_DFF/D"
        )
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            replay_source = root / "replay-source"
            evidence_dir = root / "evidence"
            replay_source.mkdir()
            evidence_dir.mkdir()
            negative = write_negative_inventory(
                replay_source,
                matched=1,
                numeric=1,
                rows=[],
            )
            fanout = write_fanout_inventory(
                replay_source,
                [(WRAPPER_SOURCE, [endpoint])],
            )
            (evidence_dir / mapped_sta.BPU_NEGATIVE_SLACK_FILENAME).symlink_to(
                negative
            )
            (evidence_dir / mapped_sta.BPU_UPDATE_FANOUT_FILENAME).symlink_to(
                fanout
            )
            with self.assertRaises(mapped_sta.EvidenceError):
                mapped_sta.parse_mapped_profile_evidence(
                    mapped_sta.MAPPED_ARTIFACT_PROFILE_BPU_LOCAL_PHT,
                    evidence_dir,
                    evidence_dir / "unused-synth-stat.txt",
                )

        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            evidence_dir = root / "canonical-evidence"
            evidence_dir.mkdir()
            write_negative_inventory(
                evidence_dir,
                matched=1,
                numeric=1,
                rows=[],
            )
            write_fanout_inventory(
                evidence_dir,
                [(WRAPPER_SOURCE, [endpoint])],
            )
            alias_dir = root / "evidence-alias"
            alias_dir.symlink_to(evidence_dir, target_is_directory=True)
            with self.assertRaises(mapped_sta.EvidenceError):
                mapped_sta.parse_mapped_profile_evidence(
                    mapped_sta.MAPPED_ARTIFACT_PROFILE_BPU_LOCAL_PHT,
                    alias_dir,
                    alias_dir / "unused-synth-stat.txt",
                )

            wrong_basename = evidence_dir / "replayed-bpu-update-fanout.tsv"
            wrong_basename.write_text(
                (evidence_dir / mapped_sta.BPU_UPDATE_FANOUT_FILENAME).read_text(
                    encoding="utf-8"
                ),
                encoding="utf-8",
            )
            with self.assertRaises(mapped_sta.EvidenceError):
                mapped_sta.canonical_profile_artifact_path(
                    evidence_dir,
                    mapped_sta.BPU_UPDATE_FANOUT_FILENAME,
                    wrong_basename,
                )

            evidence = mapped_sta.parse_mapped_profile_evidence(
                mapped_sta.MAPPED_ARTIFACT_PROFILE_BPU_LOCAL_PHT,
                evidence_dir,
                evidence_dir / "unused-synth-stat.txt",
            )
            detached = copy.deepcopy(evidence["bpu_negative_slack_inventory"])
            detached["artifact"]["path"] = wrong_basename.as_posix()
            with self.assertRaises(mapped_sta.EvidenceError):
                mapped_sta.require_profile_artifact_receipt(
                    detached,
                    evidence_dir,
                    mapped_sta.BPU_NEGATIVE_SLACK_FILENAME,
                )

    def test_bpu_profile_rejects_exact_basename_hardlink_replay(self) -> None:
        endpoint = (
            "NpcTop/u_core/u_frontend/u_branch_direction_predictor/"
            "u_local_pht/g_bank[0].u_bank/upd_taken_q_DFF/D"
        )
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            replay_source = root / "replay-source"
            evidence_dir = root / "evidence"
            replay_source.mkdir()
            evidence_dir.mkdir()
            negative = write_negative_inventory(
                replay_source,
                matched=1,
                numeric=1,
                rows=[],
            )
            fanout = write_fanout_inventory(
                replay_source,
                [(WRAPPER_SOURCE, [endpoint])],
            )
            (evidence_dir / mapped_sta.BPU_NEGATIVE_SLACK_FILENAME).hardlink_to(
                negative
            )
            (evidence_dir / mapped_sta.BPU_UPDATE_FANOUT_FILENAME).hardlink_to(
                fanout
            )
            self.assertEqual(2, negative.stat().st_nlink)
            self.assertEqual(2, fanout.stat().st_nlink)
            with self.assertRaises(mapped_sta.EvidenceError):
                mapped_sta.parse_mapped_profile_evidence(
                    mapped_sta.MAPPED_ARTIFACT_PROFILE_BPU_LOCAL_PHT,
                    evidence_dir,
                    evidence_dir / "unused-synth-stat.txt",
                )

        with tempfile.TemporaryDirectory() as temporary:
            evidence_dir = Path(temporary)
            negative = write_negative_inventory(
                evidence_dir,
                matched=1,
                numeric=1,
                rows=[],
            )
            fanout = write_fanout_inventory(
                evidence_dir,
                [(WRAPPER_SOURCE, [endpoint])],
            )
            self.assertEqual(1, negative.stat().st_nlink)
            self.assertEqual(1, fanout.stat().st_nlink)
            evidence = mapped_sta.parse_mapped_profile_evidence(
                mapped_sta.MAPPED_ARTIFACT_PROFILE_BPU_LOCAL_PHT,
                evidence_dir,
                evidence_dir / "unused-synth-stat.txt",
            )
            self.assertEqual(
                1,
                evidence["bpu_update_fanout_inventory"]["wrapper_source_count"],
            )

    def test_tcl_parser_runner_inventory_bypass_mutations_fail(self) -> None:
        tcl = TCL_PATH.read_text(encoding="utf-8")
        parser = PARSER_PATH.read_text(encoding="utf-8")
        runner = RUNNER_PATH.read_text(encoding="utf-8")
        self.assertEqual([], pipeline_contract_errors(tcl, parser, runner))
        mutations = (
            (
                "tcl-negative-writer",
                tcl.replace(
                    "write_bpu_negative_slack_inventory $bpu_negative_slack_path",
                    "BYPASS",
                    1,
                ),
                parser,
                runner,
            ),
            (
                "tcl-fanout-writer",
                tcl.replace(
                    "write_bpu_update_fanout_inventory $bpu_update_fanout_path",
                    "BYPASS",
                    1,
                ),
                parser,
                runner,
            ),
            (
                "parser-summary",
                tcl,
                parser.replace(
                    '"mapped_profile_evidence": profile_evidence',
                    '"mapped_profile_evidence": {"profile": profile}',
                    1,
                ),
                runner,
            ),
            (
                "runner-negative-artifact",
                tcl,
                parser,
                runner.replace('-s "${bpu_negative_slack_artifact}"', "BYPASS", 1),
            ),
            (
                "runner-fanout-artifact",
                tcl,
                parser,
                runner.replace('-s "${bpu_update_fanout_artifact}"', "BYPASS", 1),
            ),
            (
                "runner-binding",
                tcl,
                parser,
                runner.replace("stamp-mapped-summary", "BYPASS", 1),
            ),
        )
        for label, mutated_tcl, mutated_parser, mutated_runner in mutations:
            with self.subTest(label=label):
                self.assertTrue(
                    pipeline_contract_errors(
                        mutated_tcl, mutated_parser, mutated_runner
                    )
                )


if __name__ == "__main__":
    unittest.main()
