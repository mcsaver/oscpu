#!/usr/bin/env python3
"""Fail-closed tests for local RV64 functional aggregate v2 assembly."""

from __future__ import annotations

import importlib.util
import json
import pathlib
import shutil
import sys
import tempfile
import unittest


TOOLS = pathlib.Path(__file__).resolve().parents[1] / "tools"
REPO = TOOLS.parents[4]
SPEC = importlib.util.spec_from_file_location(
    "functional_aggregate_under_test", TOOLS / "functional_aggregate.py")
assert SPEC is not None and SPEC.loader is not None
functional = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = functional
SPEC.loader.exec_module(functional)


def write_text(root: pathlib.Path, relative: str, text: str) -> pathlib.Path:
    path = root / relative
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")
    return path


def write_bytes(root: pathlib.Path, relative: str, data: bytes) -> pathlib.Path:
    path = root / relative
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(data)
    return path


def write_json(root: pathlib.Path, relative: str, value: object) -> pathlib.Path:
    return write_text(
        root, relative,
        json.dumps(value, allow_nan=False, indent=2, sort_keys=True) + "\n")


class FunctionalFixture:
    def __init__(self, *, am_count: int = 59) -> None:
        self.temp = tempfile.TemporaryDirectory(prefix="rv64-functional-v2-")
        self.root = pathlib.Path(self.temp.name)
        self.design_id = "sha256:" + "a" * 64
        self.cohort_id = "fixture-current-design"
        self._copy_schemas()
        write_text(
            self.root, "npc/rv64/testbench/Makefile",
            "TESTS := \\\n  tb_a \\\n  tb_b\n")
        write_text(
            self.root,
            "npc/rv64/eval/ppa/tools/architecture_hard_gates.py",
            "def rtl_binding(root):\n"
            "    return ('" + "a" * 64 + "', {'npc/rv64/vsrc/Dut.v': 'fixture'})\n",
        )
        write_text(self.root, "npc/rv64/vsrc/Dut.v", "module Dut; endmodule\n")
        simulator = write_text(
            self.root, "evidence/frozen/NpcSimTop", "fixture simulator\n")
        reference = write_text(
            self.root, "evidence/frozen/riscv64-nemu-interpreter-so",
            "fixture reference\n")
        simulator.chmod(0o755)
        reference.chmod(0o755)
        write_text(self.root, "evidence/frozen/npc.config", "CONFIG_NPC_DIFFTEST=y\n")
        sources = []
        for index, kind in enumerate((
            "reference_config", "reference_model_source",
            "comparison_policy_source",
        )):
            path = write_text(
                self.root, f"evidence/reference/source-{index}.txt",
                f"reference source {index}\n")
            sources.append({
                "kind": kind,
                "path": path.relative_to(self.root).as_posix(),
                "sha256": functional.sha256_file(path),
            })
        profile = {
            "schema": functional.freeze.DIFFTEST_PROFILE_SCHEMA,
            "reference_sha256": functional.sha256_file(reference),
            "isa": "rv64im_zicsr_zifencei_zba_zbb_zbc_zbs",
            "reset_pc": functional.LOAD_ADDRESS,
            "program_load_address": functional.LOAD_ADDRESS,
            "memory_map": {
                "pmem_base": functional.LOAD_ADDRESS,
                "pmem_size": "0x0000000040000000",
                "mmio_model": "local NPC MMIO model",
            },
            "comparison_policy": [
                "retired instruction architectural state",
                "program counter and integer register state",
            ],
            "source_artifacts": sources,
        }
        write_json(self.root, "evidence/reference/profile.json", profile)
        write_text(self.root, "evidence/raw/build.log", "Verilator build complete\n")
        module_tests = []
        for test_id in ("tb_a", "tb_b"):
            raw = write_text(
                self.root, f"evidence/raw/module/{test_id}.log",
                f"[TEST] {test_id}\n[PASS] {test_id}\n[RESULT] PASS\n")
            module_tests.append({
                "test_id": test_id,
                "compile_rc": 0,
                "simulation_rc": 0,
                "raw_log": raw.relative_to(self.root).as_posix(),
            })
        official = self._suite_records("official", 177, "Difftest: OFF\nTOHOST PASS\n")
        am = self._suite_records(
            "am", am_count, "Difftest: ON\nHIT GOOD TRAP\n")
        coremark_image = write_bytes(
            self.root, "evidence/images/coremark.bin", b"coremark-image")
        dhrystone_image = write_bytes(
            self.root, "evidence/images/dhrystone.bin", b"dhrystone-image")
        coremark_raw = write_text(
            self.root, "evidence/raw/coremark.log",
            "CoreMark 10 iterations\ncrcfinal : 0xfcaf\nHIT GOOD TRAP\n")
        dhrystone_raw = write_text(
            self.root, "evidence/raw/dhrystone.log",
            "Dhrystone 10000 runs\nHIT GOOD TRAP\n")
        self.descriptor_value = {
            "schema": functional.DESCRIPTOR_SCHEMA,
            "design_id": self.design_id,
            "cohort_id": self.cohort_id,
            "simulator": simulator.relative_to(self.root).as_posix(),
            "configuration": "evidence/frozen/npc.config",
            "build": {
                "command": "make local RV64 Verilator simulator",
                "return_code": 0,
                "raw_log": "evidence/raw/build.log",
            },
            "module": {
                "command": "run local SystemVerilog module inventory",
                "tests": module_tests,
            },
            "official": {
                "command": "run exact local official RV64 instruction inventory",
                "tests": official,
            },
            "am": {
                "command": "run exact local AM cpu-test inventory with DiffTest",
                "tests": am,
            },
            "difftest": {
                "command": "compare AM architectural retirement with local NEMU reference",
                "mismatches": 0,
                "reference": reference.relative_to(self.root).as_posix(),
                "reference_profile": "evidence/reference/profile.json",
            },
            "benchmarks": {
                "coremark": {
                    "command": "run local CoreMark for 10 iterations",
                    "return_code": 0,
                    "image": coremark_image.relative_to(self.root).as_posix(),
                    "raw_log": coremark_raw.relative_to(self.root).as_posix(),
                    "iterations": 10,
                    "crc": "0xfcaf",
                    "good_traps": 1,
                },
                "dhrystone": {
                    "command": "run local Dhrystone for 10000 runs",
                    "return_code": 0,
                    "image": dhrystone_image.relative_to(self.root).as_posix(),
                    "raw_log": dhrystone_raw.relative_to(self.root).as_posix(),
                    "runs": 10000,
                    "good_traps": 1,
                },
            },
        }
        self.descriptor = write_json(
            self.root, "evidence/descriptor.json", self.descriptor_value)

    def _copy_schemas(self) -> None:
        for name in (
            "functional-aggregate-v2.schema.json",
            "functional-aggregate-result-v1.schema.json",
            "difftest-reference-profile-v1.schema.json",
        ):
            destination = self.root / "npc/rv64/eval/ppa/schemas" / name
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(REPO / "npc/rv64/eval/ppa/schemas" / name, destination)

    def _suite_records(self, name: str, count: int, log_text: str) -> list[dict]:
        records = []
        for index in range(count):
            test_id = f"{name}_{index:03d}"
            image = write_bytes(
                self.root, f"evidence/images/{name}/{test_id}.bin",
                f"{name}-image-{index}".encode("utf-8"))
            raw = write_text(
                self.root, f"evidence/raw/{name}/{test_id}.log", log_text)
            records.append({
                "test_id": test_id,
                "return_code": 0,
                "image": image.relative_to(self.root).as_posix(),
                "raw_log": raw.relative_to(self.root).as_posix(),
            })
        return records

    def assemble(self) -> dict:
        return functional.assemble(
            root=self.root,
            descriptor_path=self.descriptor,
            wrapper_dir=self.root / "evidence/wrapped",
            aggregate_path=self.root / functional.freeze.F0_AGGREGATE_PATH,
            mutation_summary_path=self.root / "evidence/mutations.json",
            raw_log_path=self.root / functional.freeze.F0_RAW_PATH,
            result_path=self.root / functional.freeze.F0_RESULT_PATH,
            check_current_design=False,
        )

    def close(self) -> None:
        self.temp.cleanup()


class FunctionalAggregateTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.fixture = FunctionalFixture()
        cls.result = cls.fixture.assemble()

    @classmethod
    def tearDownClass(cls) -> None:
        cls.fixture.close()

    def test_complete_aggregate_is_reconstructed(self) -> None:
        counts = self.result["counts"]
        self.assertEqual(counts["module_passed"], 2)
        self.assertEqual(counts["official_passed"], 177)
        self.assertEqual(counts["am_passed"], 59)
        self.assertEqual(counts["difftest_mismatches"], 0)
        self.assertTrue(all(item["status"] == "PASS" for item in self.result["checks"]))

    def test_schema_valid_evidence_mutations_are_all_rejected(self) -> None:
        value = json.loads(
            (self.fixture.root / "evidence/mutations.json").read_text(encoding="utf-8"))
        self.assertGreaterEqual(value["schema_valid"], 10)
        self.assertEqual(value["schema_valid_rejected"], value["schema_valid"])
        self.assertTrue(value["all_rejected"])
        self.assertIn(
            "official_test_to_image_swap",
            {item["mutation_id"] for item in value["mutations"]})

    def test_image_map_digest_excludes_workspace_path(self) -> None:
        aggregate = json.loads(
            (self.fixture.root / functional.freeze.F0_AGGREGATE_PATH).read_text(encoding="utf-8"))
        original = aggregate["official"]["image_set_sha256"]
        changed = json.loads(json.dumps(aggregate["official"]["images"]))
        changed[0]["image"]["path"] = "different/local/copy.bin"
        self.assertEqual(original, functional.image_set_sha("official", changed))

    def test_f0_debt_semantic_validator_reconstructs_live_result(self) -> None:
        paths = {
            "functional_aggregate_result": self.fixture.root / functional.freeze.F0_RESULT_PATH,
            "functional_aggregate": self.fixture.root / functional.freeze.F0_AGGREGATE_PATH,
            "raw_log": self.fixture.root / functional.freeze.F0_RAW_PATH,
            "mutation_summary": self.fixture.root / "evidence/mutations.json",
        }
        entry = {
            "canonical_command": functional.CANONICAL_COMMAND,
            "evidence": [
                {
                    "kind": kind,
                    "path": path.relative_to(self.fixture.root).as_posix(),
                    "sha256": functional.sha256_file(path),
                }
                for kind, path in paths.items()
            ],
        }
        self.assertEqual(
            functional.freeze.validate_f0_debt(
                self.fixture.root, entry, self.fixture.design_id),
            [],
        )

    def test_am_log_with_difftest_off_is_rejected(self) -> None:
        fixture = FunctionalFixture()
        try:
            raw = fixture.root / fixture.descriptor_value["am"]["tests"][0]["raw_log"]
            raw.write_text("Difftest: OFF\nHIT GOOD TRAP\n", encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "DiffTest is not ON"):
                functional.build_aggregate(
                    fixture.root, fixture.descriptor_value,
                    fixture.root / "evidence/off-wrapped")
        finally:
            fixture.close()

    def test_am_inventory_count_is_dynamic_but_internally_exact(self) -> None:
        fixture = FunctionalFixture(am_count=3)
        try:
            result = fixture.assemble()
            self.assertEqual(result["counts"]["am_required"], 3)
            self.assertEqual(result["counts"]["am_passed"], 3)

            paths = {
                "functional_aggregate_result": (
                    fixture.root / functional.freeze.F0_RESULT_PATH),
                "functional_aggregate": (
                    fixture.root / functional.freeze.F0_AGGREGATE_PATH),
                "raw_log": fixture.root / functional.freeze.F0_RAW_PATH,
                "mutation_summary": fixture.root / "evidence/mutations.json",
            }
            entry = {
                "canonical_command": functional.CANONICAL_COMMAND,
                "evidence": [
                    {
                        "kind": kind,
                        "path": path.relative_to(fixture.root).as_posix(),
                        "sha256": functional.sha256_file(path),
                    }
                    for kind, path in paths.items()
                ],
            }
            self.assertEqual(
                functional.freeze.validate_f0_debt(
                    fixture.root, entry, fixture.design_id),
                [],
            )

            aggregate = json.loads(
                (fixture.root / functional.freeze.F0_AGGREGATE_PATH).read_text(
                    encoding="utf-8"))
            aggregate["am"]["passed"] = 2
            _checks, blockers, _observed = functional.validate_aggregate(
                fixture.root, aggregate, ["tb_a", "tb_b"])
            self.assertTrue(
                any("functional.am" in blocker for blocker in blockers),
                blockers,
            )
        finally:
            fixture.close()


if __name__ == "__main__":
    unittest.main()
