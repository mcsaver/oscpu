from __future__ import annotations

import copy
import hashlib
import tempfile
import unittest
from pathlib import Path

from npc.rv64.eval.ppa.tools import architecture_registry as registry
from npc.rv64.eval.ppa.tools import fp_mapped_artifact_tool_result as tool_result
from npc.rv64.eval.ppa.tools import traceable_mapped_sta as mapped_sta


TCL_PATH = (
    mapped_sta.ROOT / "npc/rv64/eval/ppa/opensta-traceable-mapped-current.tcl"
)
PARSER_PATH = mapped_sta.ROOT / "npc/rv64/eval/ppa/tools/traceable_mapped_sta.py"
RUNNER_PATH = mapped_sta.ROOT / "npc/rv64/eval/ppa/run-traceable-mapped-current.sh"
REGISTRY_PATH = mapped_sta.ROOT / "npc/rv64/eval/ppa/tools/architecture_registry.py"

WRAPPER = "OooFpArithGate"
CHILDREN = (
    "OooFpAddSubPipe",
    "OooFpMulProductPipe",
    "OooFpMulNormRoundPipe",
    "OooFpFmaAlignAddPipe",
    "OooFpFmaNormRoundPipe",
)


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def write_negative_inventory(
    directory: Path,
    *,
    matched: int = 4,
    numeric: int = 3,
    rows: list[tuple[str, str]] | None = None,
    declared_negative: int | None = None,
) -> Path:
    if rows is None:
        rows = [
            (
                "NpcTop/u_core/u_fp_backend/u_fp_arith/"
                "u_addsub_pipe/stage3_q_DFF/D",
                "-0.125",
            )
        ]
    path = directory / mapped_sta.FP_NEGATIVE_SLACK_FILENAME
    lines = [
        f"schema\t{mapped_sta.FP_NEGATIVE_SLACK_SCHEMA}",
        f"inventory_semantics\t{mapped_sta.FP_NEGATIVE_SLACK_SEMANTICS}",
        f"matched_pin_count\t{matched}",
        f"numeric_slack_pin_count\t{numeric}",
        "negative_slack_pin_count\t"
        f"{len(rows) if declared_negative is None else declared_negative}",
        "full_name\tslack_max_ns",
    ]
    lines.extend(f"{name}\t{slack}" for name, slack in rows)
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    return path


def timing_path_block(
    *,
    suffix: str = "0",
    slack: str = "-0.200000000",
    endpoint: str | None = None,
    mapped_cell_points: int = 2,
) -> str:
    startpoint = (
        "NpcTop/u_core/u_fp_backend/u_fp_arith/"
        f"stage1_q_{suffix}_DFF/Q"
    )
    if endpoint is None:
        endpoint = (
            "NpcTop/u_core/u_fp_backend/u_fp_arith/"
            f"stage2_q_{suffix}_DFF/D"
        )
    state = "VIOLATED" if float(slack) < 0.0 else "MET"
    lines = [
        f"Startpoint: {startpoint}",
        f"Endpoint: {endpoint}",
        "Path Group: core_clock",
        "Path Type: max",
    ]
    for index in range(mapped_cell_points):
        lines.append(
            "  0.010 0.010 ^ "
            "NpcTop/u_core/u_fp_backend/u_fp_arith/"
            f"U{suffix}_{index}/Y (NAND2X1H7L)"
        )
    lines.append(f"  {slack} slack ({state})")
    return "\n".join(lines) + "\n"


def write_internal_paths(
    directory: Path,
    blocks: list[str] | None = None,
) -> Path:
    if blocks is None:
        blocks = [timing_path_block()]
    path = directory / mapped_sta.FP_INTERNAL_PATHS_FILENAME
    path.write_text("".join(blocks), encoding="utf-8")
    return path


def mapped_section(
    heading: str,
    *,
    cells: int,
    area: str,
    submodules: list[tuple[int, str]] | None = None,
) -> str:
    lines = [
        f"=== {heading} ===",
        "",
        f"  {cells} {area} cells",
    ]
    for count, module in submodules or []:
        lines.append(f"  {count} - {module}")
    lines.extend(
        (
            "",
            f"Chip area for module '{heading}': {area}",
            "  of which used for sequential elements: 1.000000 (1.00%)",
            "",
        )
    )
    return "\n".join(lines)


def write_synth_stat(directory: Path, *, placeholder_notice: bool = False) -> Path:
    wrapper_heading = "$paramod$arith\\OooFpArithGate"
    sections = [
        mapped_section(
            "$paramod$backend\\OooFpBackend",
            cells=120,
            area="300.000000",
            submodules=[(1, wrapper_heading)],
        ),
        mapped_section(
            wrapper_heading,
            cells=1000,
            area="5000.000000",
            submodules=[(1, child) for child in CHILDREN],
        ),
    ]
    for index, child in enumerate(CHILDREN, start=1):
        sections.append(
            mapped_section(
                child,
                cells=200 + index,
                area=f"{1000 + index}.000000",
            )
        )
    if placeholder_notice:
        sections.append("Area for cell type \\OooFpArithGate is unknown!\n")
    hierarchy_rows = [
        "=== design hierarchy ===",
        "  210000 400000.000000 NpcTop",
        f"  7000 10000.000000 {wrapper_heading}",
    ]
    for index, child in enumerate(CHILDREN, start=1):
        hierarchy_rows.append(
            f"  {200 + index} {1000 + index}.000000 {child}"
        )
    hierarchy_rows.extend(("  1 - Sram4096x199", ""))
    path = directory / "synth_stat.txt"
    path.write_text(
        "".join(sections) + "\n".join(hierarchy_rows),
        encoding="utf-8",
    )
    return path


def profile_summary(evidence: dict[str, object]) -> dict[str, object]:
    negative = evidence["fp_negative_slack_inventory"]
    internal = evidence["fp_internal_timing_paths"]
    hierarchy = evidence["fp_mapped_hierarchy_inventory"]
    assert isinstance(negative, dict)
    assert isinstance(internal, dict)
    assert isinstance(hierarchy, dict)
    return {
        "mapped_artifact_profile": mapped_sta.MAPPED_ARTIFACT_PROFILE_FP_ARITH_CHILDREN,
        "inputs": {
            "mapped_artifact_profile": (
                mapped_sta.MAPPED_ARTIFACT_PROFILE_FP_ARITH_CHILDREN
            )
        },
        "mapped_profile_evidence": evidence,
        "artifacts": {
            "fp_negative_slack": negative["artifact"],
            "fp_internal_paths": internal["artifact"],
        },
        "synthesis": {"synth_stat": hierarchy["source_artifact"]},
    }


def pipeline_contract_errors(
    tcl: str,
    parser: str,
    runner: str,
    registry_text: str,
) -> list[str]:
    required = {
        "tcl": (
            "switch -- $mapped_artifact_profile",
            "write_fp_negative_slack_inventory $fp_negative_slack_path",
            "write_fp_internal_timing_paths $fp_internal_paths_path",
            "report_checks -path_delay max -from $fp_pins -to $fp_pins",
        ),
        "parser": (
            "parse_fp_negative_slack_inventory(",
            "parse_fp_internal_timing_paths(",
            "parse_fp_mapped_hierarchy_inventory(",
            "instance_declarations",
            '"mapped_profile_evidence": profile_evidence',
        ),
        "runner": (
            'V15P_STA_MAPPED_ARTIFACT_PROFILE="${mapped_artifact_profile}"',
            '-s "${fp_negative_slack_artifact}"',
            '-s "${fp_internal_paths_artifact}"',
            '--mapped-artifact-profile "${mapped_artifact_profile}"',
            "stamp-mapped-summary",
        ),
        "registry": (
            'MAPPED_ARTIFACT_PROFILE_FP_ARITH_CHILDREN = "fp-arith-children-v1"',
            '"mapped_profile_evidence_sha256"',
            '"mapped_artifact_profile": mapped_artifact_profile',
            "profile_evidence_errors",
        ),
    }
    texts = {
        "tcl": tcl,
        "parser": parser,
        "runner": runner,
        "registry": registry_text,
    }
    errors = [
        f"{owner} lacks {marker}"
        for owner, markers in required.items()
        for marker in markers
        if marker not in texts[owner]
    ]
    if (
        "write_fp_internal_timing_paths $fp_internal_paths_path" in tcl
        and "write_note $complete_path" in tcl
        and tcl.index("write_fp_internal_timing_paths $fp_internal_paths_path")
        > tcl.index("write_note $complete_path")
    ):
        errors.append("Tcl writes FP internal paths after COMPLETE")
    if (
        'python3 -B "${parser}" variant' in runner
        and "stamp-mapped-summary" in runner
        and runner.index('python3 -B "${parser}" variant')
        > runner.index("stamp-mapped-summary")
    ):
        errors.append("runner binds FP evidence before parser validation")
    return errors


def runner_out_dir_contract_errors(runner: str) -> list[str]:
    required = (
        'repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../../.." && pwd -P)"',
        'task_run_root="$(realpath -e -- "${task_run_root}")"',
        'evidence_dir="${run_dir}/evidence/${evidence_id}"',
        'mkdir -- "${evidence_dir}"',
        'evidence_dir_canonical="$(realpath -e -- "${evidence_dir}")"',
        '"${evidence_dir}" != /*',
        '"${evidence_dir}" != "${evidence_dir_canonical}"',
        '-L "${evidence_dir}"',
        '--out-dir "${evidence_dir}"',
    )
    errors = [f"runner lacks canonical out_dir marker: {marker}" for marker in required
              if marker not in runner]
    if not errors and not (
        runner.index('mkdir -- "${evidence_dir}"')
        < runner.index('evidence_dir_canonical="$(realpath -e -- "${evidence_dir}")"')
        < runner.index('--out-dir "${evidence_dir}"')
    ):
        errors.append("runner canonicalizes evidence_dir after parser consumption")
    return errors


class FpMappedInventoryTests(unittest.TestCase):
    def test_positive_fp_profile_records_all_artifacts_and_exact_hierarchy(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            negative_path = write_negative_inventory(
                directory,
                matched=6,
                numeric=5,
                rows=[
                    (
                        "NpcTop/u_core/u_fp_backend/u_fp_arith/"
                        "u_addsub_pipe/stage3_q_DFF/D",
                        "-0.125",
                    ),
                    (
                        "NpcTop/u_core/u_fp_backend/u_fp_arith/"
                        "u_fma_norm_round_pipe/stage5_q_DFF/D",
                        "-1.25e-2",
                    ),
                ],
            )
            internal_path = write_internal_paths(
                directory,
                [
                    timing_path_block(suffix="0", slack="-0.200000000"),
                    timing_path_block(suffix="1", slack="0.050000000"),
                ],
            )
            synth_stat = write_synth_stat(directory)

            evidence = mapped_sta.parse_mapped_profile_evidence(
                mapped_sta.MAPPED_ARTIFACT_PROFILE_FP_ARITH_CHILDREN,
                directory,
                synth_stat,
            )
            self.assertEqual(
                [
                    mapped_sta.FP_NEGATIVE_SLACK_FILENAME,
                    mapped_sta.FP_INTERNAL_PATHS_FILENAME,
                ],
                evidence["artifact_family"],
            )
            negative = evidence["fp_negative_slack_inventory"]
            self.assertEqual(2, negative["negative_slack_pin_count"])
            self.assertEqual(-0.125, negative["worst_slack_ns"])
            self.assertEqual(sha256(negative_path), negative["artifact"]["sha256"])

            internal = evidence["fp_internal_timing_paths"]
            self.assertEqual(2, internal["path_count"])
            self.assertEqual(1, internal["violated_path_count"])
            self.assertTrue(
                all(path["mapped_cell_point_count"] >= 2 for path in internal["paths"])
            )
            self.assertEqual(sha256(internal_path), internal["artifact"]["sha256"])

            hierarchy = evidence["fp_mapped_hierarchy_inventory"]
            self.assertEqual(6, hierarchy["module_count"])
            self.assertEqual(0, hierarchy["fp_placeholder_unknown_notice_count"])
            self.assertEqual(sha256(synth_stat), hierarchy["source_artifact"]["sha256"])
            for module in (WRAPPER, *CHILDREN):
                row = hierarchy["modules"][module]
                self.assertEqual(1, row["instance_count"])
                self.assertGreater(row["mapped_cells"], 0)
                self.assertGreater(row["area"], 0.0)
                self.assertGreater(row["section_mapped_cells"], 0)
                self.assertGreater(row["section_area"], 0.0)
            self.assertIn(
                "OooFpBackend",
                hierarchy["modules"][WRAPPER]["parent_heading"],
            )
            for child in CHILDREN:
                self.assertIn(
                    "OooFpArithGate",
                    hierarchy["modules"][child]["parent_heading"],
                )

            summary = profile_summary(evidence)
            digest, errors = registry.mapped_profile_evidence_state(
                summary,
                expected_profile=registry.MAPPED_ARTIFACT_PROFILE_FP_ARITH_CHILDREN,
            )
            self.assertEqual([], errors)
            self.assertEqual(registry.canonical_sha256(evidence), digest)

    def test_negative_slack_missing_duplicate_nonfinite_and_nonnegative_fail(self) -> None:
        name = (
            "NpcTop/u_core/u_fp_backend/u_fp_arith/"
            "u_addsub_pipe/stage3_q_DFF/D"
        )
        cases = (
            ("declared-count", 4, 3, [(name, "-0.1")], 2),
            ("duplicate", 4, 3, [(name, "-0.1"), (name, "-0.2")], None),
            ("non-finite", 4, 3, [(name, "nan")], None),
            ("non-negative", 4, 3, [(name, "0.0")], None),
            ("numeric-gt-matched", 1, 2, [(name, "-0.1")], None),
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
                    mapped_sta.parse_fp_negative_slack_inventory(path)
        with tempfile.TemporaryDirectory() as temporary:
            missing = Path(temporary) / mapped_sta.FP_NEGATIVE_SLACK_FILENAME
            with self.assertRaises(mapped_sta.EvidenceError):
                mapped_sta.parse_fp_negative_slack_inventory(missing)

    def test_internal_path_requires_real_mapped_cells_and_fp_endpoints(self) -> None:
        outside_endpoint = "NpcTop/u_core/u_int_backend/stage2_q_DFF/D"
        self_endpoint = (
            "NpcTop/u_core/u_fp_backend/u_fp_arith/stage1_q_0_DFF/Q"
        )
        cases = (
            (
                "one-cell-point",
                timing_path_block(mapped_cell_points=1),
            ),
            (
                "outside-fp",
                timing_path_block(endpoint=outside_endpoint),
            ),
            (
                "self-path",
                timing_path_block(endpoint=self_endpoint),
            ),
        )
        for label, block in cases:
            with self.subTest(label=label), tempfile.TemporaryDirectory() as temporary:
                path = write_internal_paths(Path(temporary), [block])
                with self.assertRaises(mapped_sta.EvidenceError):
                    mapped_sta.parse_fp_internal_timing_paths(path)
        with tempfile.TemporaryDirectory() as temporary:
            missing = Path(temporary) / mapped_sta.FP_INTERNAL_PATHS_FILENAME
            with self.assertRaises(mapped_sta.EvidenceError):
                mapped_sta.parse_fp_internal_timing_paths(missing)

    def test_hierarchy_missing_duplicate_zero_and_placeholder_fail(self) -> None:
        mutations = (
            (
                "missing-child",
                lambda text: text.replace("  1 - OooFpAddSubPipe\n", "", 1),
            ),
            (
                "duplicate-child",
                lambda text: text.replace(
                    "  1 - OooFpMulProductPipe\n",
                    "  2 - OooFpMulProductPipe\n",
                    1,
                ),
            ),
            (
                "zero-section-cells",
                lambda text: text.replace(
                    "  203 1003.000000 cells\n",
                    "  0 1003.000000 cells\n",
                    1,
                ),
            ),
            (
                "zero-section-area",
                lambda text: text.replace(
                    "Chip area for module 'OooFpFmaAlignAddPipe': 1004.000000",
                    "Chip area for module 'OooFpFmaAlignAddPipe': 0.000000",
                    1,
                ),
            ),
            (
                "zero-hierarchy-area",
                lambda text: text.replace(
                    "  205 1005.000000 OooFpFmaNormRoundPipe",
                    "  205 0.000000 OooFpFmaNormRoundPipe",
                    1,
                ),
            ),
            (
                "placeholder",
                lambda text: text.replace(
                    "=== design hierarchy ===",
                    "Area for cell type \\OooFpArithGate is unknown!\n"
                    "=== design hierarchy ===",
                    1,
                ),
            ),
            (
                "wrong-parent",
                lambda text: text.replace(
                    "  1 - OooFpMulNormRoundPipe\n",
                    "",
                    1,
                ).replace(
                    "  1 - $paramod$arith\\OooFpArithGate\n",
                    "  1 - $paramod$arith\\OooFpArithGate\n"
                    "  1 - OooFpMulNormRoundPipe\n",
                    1,
                ),
            ),
        )
        for label, mutate in mutations:
            with self.subTest(label=label), tempfile.TemporaryDirectory() as temporary:
                path = write_synth_stat(Path(temporary))
                original = path.read_text(encoding="utf-8")
                mutated = mutate(original)
                self.assertNotEqual(original, mutated, label)
                path.write_text(mutated, encoding="utf-8")
                with self.assertRaises(mapped_sta.EvidenceError):
                    mapped_sta.parse_fp_mapped_hierarchy_inventory(path)

    def test_fp_profile_area_unknown_set_excludes_fp_placeholder(self) -> None:
        text = "\n".join(
            (
                "=== design hierarchy ===",
                "  100005 top NpcTop",
                "  100005 mapped cells",
                "  1 - Sram4096x199",
                "  2 - Sram4096x113",
                "  1 - OooBranchDirectionPredictor",
                "  3 mapped submodules",
                "Area for cell type \\Sram4096x199 is unknown!",
                "Area for cell type \\Sram4096x113 is unknown!",
                "Area for cell type \\OooBranchDirectionPredictor is unknown!",
                "Chip area for top module '\\NpcTop': 200000.00",
                "  of which used for sequential elements: 100000.00 (50.00%)",
                "",
            )
        )
        expected = {
            "Sram4096x199",
            "Sram4096x113",
            "OooBranchDirectionPredictor",
        }
        with tempfile.TemporaryDirectory() as temporary:
            synth_stat = Path(temporary) / "synth_stat.txt"
            synth_stat.write_text(text, encoding="utf-8")
            area = mapped_sta.parse_area(synth_stat, expected)
            self.assertEqual(
                {
                    "OooBranchDirectionPredictor": 1,
                    "Sram4096x113": 2,
                    "Sram4096x199": 1,
                },
                area["unknown_macro_instances"],
            )
            self.assertNotIn("OooFpArithGate", area["unknown_macro_instances"])
            synth_stat.write_text(
                text.replace(
                    "  3 mapped submodules",
                    "  1 - OooFpArithGate\n  4 mapped submodules",
                ).replace(
                    "Chip area for top module",
                    "Area for cell type \\OooFpArithGate is unknown!\n"
                    "Chip area for top module",
                ),
                encoding="utf-8",
            )
            with self.assertRaises(mapped_sta.EvidenceError):
                mapped_sta.parse_area(synth_stat, expected)

    def test_profile_artifact_family_and_binding_drift_fail_closed(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            write_negative_inventory(directory)
            write_internal_paths(directory)
            synth_stat = write_synth_stat(directory)
            evidence = mapped_sta.parse_mapped_profile_evidence(
                mapped_sta.MAPPED_ARTIFACT_PROFILE_FP_ARITH_CHILDREN,
                directory,
                synth_stat,
            )
            summary = profile_summary(evidence)

            drifted_profile = copy.deepcopy(summary)
            drifted_profile["mapped_artifact_profile"] = (
                registry.MAPPED_ARTIFACT_PROFILE_BPU_LOCAL_PHT
            )
            _, errors = registry.mapped_profile_evidence_state(
                drifted_profile,
                expected_profile=registry.MAPPED_ARTIFACT_PROFILE_FP_ARITH_CHILDREN,
            )
            self.assertTrue(any("profile" in error for error in errors), errors)

            detached = copy.deepcopy(summary)
            detached["artifacts"]["fp_internal_paths"] = {"detached": True}
            _, errors = registry.mapped_profile_evidence_state(
                detached,
                expected_profile=registry.MAPPED_ARTIFACT_PROFILE_FP_ARITH_CHILDREN,
            )
            self.assertTrue(any("detached" in error for error in errors), errors)

            empty_path = copy.deepcopy(summary)
            empty_path["mapped_profile_evidence"]["fp_internal_timing_paths"][
                "path_count"
            ] = 0
            _, errors = registry.mapped_profile_evidence_state(
                empty_path,
                expected_profile=registry.MAPPED_ARTIFACT_PROFILE_FP_ARITH_CHILDREN,
            )
            self.assertTrue(any("real internal timing path" in error for error in errors))

            duplicate_child = copy.deepcopy(summary)
            duplicate_child["mapped_profile_evidence"][
                "fp_mapped_hierarchy_inventory"
            ]["modules"]["OooFpAddSubPipe"]["instance_count"] = 2
            _, errors = registry.mapped_profile_evidence_state(
                duplicate_child,
                expected_profile=registry.MAPPED_ARTIFACT_PROFILE_FP_ARITH_CHILDREN,
            )
            self.assertTrue(any("not exact/nonzero" in error for error in errors), errors)

            zero_area = copy.deepcopy(summary)
            zero_area["mapped_profile_evidence"][
                "fp_mapped_hierarchy_inventory"
            ]["modules"]["OooFpMulProductPipe"]["area"] = 0.0
            _, errors = registry.mapped_profile_evidence_state(
                zero_area,
                expected_profile=registry.MAPPED_ARTIFACT_PROFILE_FP_ARITH_CHILDREN,
            )
            self.assertTrue(any("not exact/nonzero" in error for error in errors), errors)

            placeholder = copy.deepcopy(summary)
            placeholder["mapped_profile_evidence"][
                "fp_mapped_hierarchy_inventory"
            ]["fp_placeholder_unknown_notice_count"] = 1
            _, errors = registry.mapped_profile_evidence_state(
                placeholder,
                expected_profile=registry.MAPPED_ARTIFACT_PROFILE_FP_ARITH_CHILDREN,
            )
            self.assertTrue(any("placeholder macro" in error for error in errors), errors)

            wrong_family = directory / mapped_sta.BPU_NEGATIVE_SLACK_FILENAME
            wrong_family.write_text("wrong-family\n", encoding="utf-8")
            with self.assertRaises(mapped_sta.EvidenceError):
                mapped_sta.parse_mapped_profile_evidence(
                    mapped_sta.MAPPED_ARTIFACT_PROFILE_FP_ARITH_CHILDREN,
                    directory,
                    synth_stat,
                )

    def test_missing_and_stale_profile_artifacts_fail_closed(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            write_negative_inventory(directory)
            synth_stat = write_synth_stat(directory)
            with self.assertRaises(mapped_sta.EvidenceError):
                mapped_sta.parse_mapped_profile_evidence(
                    mapped_sta.MAPPED_ARTIFACT_PROFILE_FP_ARITH_CHILDREN,
                    directory,
                    synth_stat,
                )
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            synth_stat = write_synth_stat(directory)
            evidence = mapped_sta.parse_mapped_profile_evidence(
                mapped_sta.MAPPED_ARTIFACT_PROFILE_NONE,
                directory,
                synth_stat,
            )
            self.assertEqual([], evidence["artifact_family"])
            write_internal_paths(directory)
            with self.assertRaises(mapped_sta.EvidenceError):
                mapped_sta.parse_mapped_profile_evidence(
                    mapped_sta.MAPPED_ARTIFACT_PROFILE_NONE,
                    directory,
                    synth_stat,
                )

    def test_fp_profile_receipts_reject_replay_alias_and_wrong_basename(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            replay_source = root / "replay-source"
            evidence_dir = root / "evidence"
            replay_source.mkdir()
            evidence_dir.mkdir()
            negative = write_negative_inventory(replay_source)
            internal = write_internal_paths(replay_source)
            synth_stat = write_synth_stat(evidence_dir)
            (evidence_dir / mapped_sta.FP_NEGATIVE_SLACK_FILENAME).symlink_to(
                negative
            )
            (evidence_dir / mapped_sta.FP_INTERNAL_PATHS_FILENAME).symlink_to(
                internal
            )
            with self.assertRaises(mapped_sta.EvidenceError):
                mapped_sta.parse_mapped_profile_evidence(
                    mapped_sta.MAPPED_ARTIFACT_PROFILE_FP_ARITH_CHILDREN,
                    evidence_dir,
                    synth_stat,
                )

        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            evidence_dir = root / "canonical-evidence"
            evidence_dir.mkdir()
            write_negative_inventory(evidence_dir)
            write_internal_paths(evidence_dir)
            synth_stat = write_synth_stat(evidence_dir)
            alias_dir = root / "evidence-alias"
            alias_dir.symlink_to(evidence_dir, target_is_directory=True)
            with self.assertRaises(mapped_sta.EvidenceError):
                mapped_sta.parse_mapped_profile_evidence(
                    mapped_sta.MAPPED_ARTIFACT_PROFILE_FP_ARITH_CHILDREN,
                    alias_dir,
                    synth_stat,
                )

            wrong_basename = evidence_dir / "replayed-fp-negative-slack.tsv"
            wrong_basename.write_text(
                (evidence_dir / mapped_sta.FP_NEGATIVE_SLACK_FILENAME).read_text(
                    encoding="utf-8"
                ),
                encoding="utf-8",
            )
            with self.assertRaises(mapped_sta.EvidenceError):
                mapped_sta.canonical_profile_artifact_path(
                    evidence_dir,
                    mapped_sta.FP_NEGATIVE_SLACK_FILENAME,
                    wrong_basename,
                )

            evidence = mapped_sta.parse_mapped_profile_evidence(
                mapped_sta.MAPPED_ARTIFACT_PROFILE_FP_ARITH_CHILDREN,
                evidence_dir,
                synth_stat,
            )
            detached = copy.deepcopy(evidence["fp_internal_timing_paths"])
            detached["artifact"]["path"] = wrong_basename.as_posix()
            with self.assertRaises(mapped_sta.EvidenceError):
                mapped_sta.require_profile_artifact_receipt(
                    detached,
                    evidence_dir,
                    mapped_sta.FP_INTERNAL_PATHS_FILENAME,
                )

    def test_fp_profile_rejects_exact_basename_hardlink_replay(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            replay_source = root / "replay-source"
            evidence_dir = root / "evidence"
            replay_source.mkdir()
            evidence_dir.mkdir()
            negative = write_negative_inventory(replay_source)
            internal = write_internal_paths(replay_source)
            (evidence_dir / mapped_sta.FP_NEGATIVE_SLACK_FILENAME).hardlink_to(
                negative
            )
            (evidence_dir / mapped_sta.FP_INTERNAL_PATHS_FILENAME).hardlink_to(
                internal
            )
            self.assertEqual(2, negative.stat().st_nlink)
            self.assertEqual(2, internal.stat().st_nlink)
            synth_stat = write_synth_stat(evidence_dir)
            with self.assertRaises(mapped_sta.EvidenceError):
                mapped_sta.parse_mapped_profile_evidence(
                    mapped_sta.MAPPED_ARTIFACT_PROFILE_FP_ARITH_CHILDREN,
                    evidence_dir,
                    synth_stat,
                )

        with tempfile.TemporaryDirectory() as temporary:
            evidence_dir = Path(temporary)
            negative = write_negative_inventory(evidence_dir)
            internal = write_internal_paths(evidence_dir)
            self.assertEqual(1, negative.stat().st_nlink)
            self.assertEqual(1, internal.stat().st_nlink)
            evidence = mapped_sta.parse_mapped_profile_evidence(
                mapped_sta.MAPPED_ARTIFACT_PROFILE_FP_ARITH_CHILDREN,
                evidence_dir,
                write_synth_stat(evidence_dir),
            )
            self.assertEqual(
                1,
                evidence["fp_internal_timing_paths"]["path_count"],
            )

    def test_runner_tcl_parser_and_binding_bypass_mutations_fail(self) -> None:
        tcl = TCL_PATH.read_text(encoding="utf-8")
        parser = PARSER_PATH.read_text(encoding="utf-8")
        runner = RUNNER_PATH.read_text(encoding="utf-8")
        registry_text = REGISTRY_PATH.read_text(encoding="utf-8")
        self.assertEqual(
            [], pipeline_contract_errors(tcl, parser, runner, registry_text)
        )
        self.assertEqual([], registry.mapped_sta_tool_contract_errors(tcl, parser))
        mutations = (
            (
                "tcl-negative-writer",
                tcl.replace(
                    "write_fp_negative_slack_inventory $fp_negative_slack_path",
                    "BYPASS",
                    1,
                ),
                parser,
                runner,
                registry_text,
            ),
            (
                "tcl-internal-writer",
                tcl.replace(
                    "write_fp_internal_timing_paths $fp_internal_paths_path",
                    "BYPASS",
                    1,
                ),
                parser,
                runner,
                registry_text,
            ),
            (
                "parser-hierarchy",
                tcl,
                parser.replace("instance_declarations", "BYPASS"),
                runner,
                registry_text,
            ),
            (
                "runner-profile",
                tcl,
                parser,
                runner.replace(
                    '--mapped-artifact-profile "${mapped_artifact_profile}"',
                    "BYPASS",
                ),
                registry_text,
            ),
            (
                "runner-binding",
                tcl,
                parser,
                runner.replace("stamp-mapped-summary", "BYPASS", 1),
                registry_text,
            ),
            (
                "binding-evidence-hash",
                tcl,
                parser,
                runner,
                registry_text.replace('"mapped_profile_evidence_sha256"', "BYPASS"),
            ),
        )
        for label, mutated_tcl, mutated_parser, mutated_runner, mutated_registry in mutations:
            with self.subTest(label=label):
                self.assertTrue(
                    pipeline_contract_errors(
                        mutated_tcl,
                        mutated_parser,
                        mutated_runner,
                        mutated_registry,
                    )
                )


class FpMappedToolIdentityTests(unittest.TestCase):
    def test_registry_generated_identity_and_state_fail_closed(self) -> None:
        result = tool_result.build_result()
        tool_result.validate_result(result)
        self.assertEqual(
            "mapped-5ns-fp-arith-production-children-inline-v1",
            result["configuration_id"],
        )
        self.assertEqual("fp-arith-children-v1", result["profile"])
        self.assertEqual("development", result["lifecycle"])
        self.assertEqual("UNMEASURED", result["measurement_status"])
        self.assertEqual("GAP", result["physical_status"])
        self.assertIs(False, result["canonical"])
        self.assertIs(False, result["champion"])
        self.assertEqual(
            tool_result.SUPERSEDED_RESULT_SHA256,
            result["superseded_result"]["sha256"],
        )
        self.assertEqual(
            tool_result.SUPERSEDED_V2_RESULT_SHA256,
            result["superseded_v2_result"]["result"]["sha256"],
        )
        self.assertEqual(
            "UNDISPATCHED_SEMANTIC_DISTORTION",
            result["undispatched_v3_contract"]["qualification"],
        )
        self.assertEqual(
            tool_result.sha256_file(tool_result.REGISTRY_TOOL_PATH),
            result["source_receipts"]["architecture_registry_tool"]["sha256"],
        )

        cases = (
            (
                "profile-as-configuration",
                "configuration_id",
                "fp-arith-children-v1",
            ),
            ("unknown-configuration", "configuration_id", "unknown-fp-config"),
            ("profile-drift", "profile", "bpu-local-pht-v1"),
        )
        for label, field, value in cases:
            with self.subTest(label=label):
                drifted = copy.deepcopy(result)
                drifted[field] = value
                with self.assertRaises(tool_result.ToolResultError):
                    tool_result.validate_result(drifted)

        for receipt_name in (
            "architecture_registry",
            "architecture_registry_tool",
            "result_schema",
        ):
            with self.subTest(receipt=receipt_name):
                drifted = copy.deepcopy(result)
                drifted["source_receipts"][receipt_name]["sha256"] = "0" * 64
                with self.assertRaises(tool_result.ToolResultError):
                    tool_result.validate_result(drifted)

    def test_detached_receipt_rejects_all_bound_hash_drift(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            result_path = directory / "result-identity-v4.json"
            tool_result.write_json(result_path, tool_result.build_result())
            receipt = tool_result.build_validation_receipt(result_path)
            tool_result.validate_validation_receipt(receipt, result_path)

            for artifact_name in (
                "result",
                "result_schema",
                "architecture_registry",
                "architecture_registry_schema",
                "architecture_registry_tool",
                "generator",
                "v4_contract",
            ):
                with self.subTest(artifact=artifact_name):
                    drifted = copy.deepcopy(receipt)
                    drifted["artifacts"][artifact_name]["sha256"] = "f" * 64
                    with self.assertRaises(tool_result.ToolResultError):
                        tool_result.validate_validation_receipt(
                            drifted,
                            result_path,
                        )

            result = tool_result.read_json(result_path)
            result["profile"] = "none"
            tool_result.write_json(result_path, result)
            with self.assertRaises(tool_result.ToolResultError):
                tool_result.validate_validation_receipt(receipt, result_path)

    def test_schema_registry_and_generator_file_drift_fail(self) -> None:
        result = tool_result.build_result()
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            schema_copy = directory / "result-schema.json"
            schema_copy.write_text(
                tool_result.RESULT_SCHEMA_PATH.read_text(encoding="utf-8") + "\n",
                encoding="utf-8",
            )
            with self.assertRaises(tool_result.ToolResultError):
                tool_result.validate_result(
                    result,
                    result_schema_path=schema_copy,
                )

            registry_copy = directory / "registry.json"
            registry_copy.write_text(
                tool_result.REGISTRY_PATH.read_text(encoding="utf-8") + "\n",
                encoding="utf-8",
            )
            with self.assertRaises(tool_result.ToolResultError):
                tool_result.validate_result(
                    result,
                    registry_path=registry_copy,
                )

            generator_copy = directory / "generator.py"
            generator_copy.write_text(
                tool_result.GENERATOR_PATH.read_text(encoding="utf-8") + "\n",
                encoding="utf-8",
            )
            with self.assertRaises(tool_result.ToolResultError):
                tool_result.validate_result(
                    result,
                    generator_path=generator_copy,
                )

            registry_tool_copy = directory / "architecture_registry.py"
            registry_tool_copy.write_text(
                tool_result.REGISTRY_TOOL_PATH.read_text(encoding="utf-8") + "\n",
                encoding="utf-8",
            )
            with self.assertRaises(tool_result.ToolResultError):
                tool_result.validate_result(
                    result,
                    registry_tool_path=registry_tool_copy,
                )

    def test_runner_passes_absolute_canonical_non_alias_out_dir(self) -> None:
        runner = RUNNER_PATH.read_text(encoding="utf-8")
        self.assertEqual([], runner_out_dir_contract_errors(runner))
        mutations = (
            runner.replace("pwd -P", "pwd -L", 1),
            runner.replace(
                'evidence_dir_canonical="$(realpath -e -- "${evidence_dir}")"',
                "BYPASS",
                1,
            ),
            runner.replace('--out-dir "${evidence_dir}"', '--out-dir relative', 1),
        )
        for mutated in mutations:
            with self.subTest():
                self.assertTrue(runner_out_dir_contract_errors(mutated))


if __name__ == "__main__":
    unittest.main()
