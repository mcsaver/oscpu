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
        self.cohort_id = functional.freeze.F0_COHORT_ID
        self.run_dir = self.root / ".github/task-runs/fixture"
        self.source_dir = self.run_dir / "evidence/functional"
        self.module_dir = self.run_dir / "evidence/module"
        self.mutation_path = self.source_dir / "mutations/summary.json"
        self._copy_schemas()
        self._copy_workflow_sources()
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
        self._prepare_source_closure(am_count)
        simulator = write_text(
            self.root,
            ".github/task-runs/fixture/evidence/functional/frozen/NpcSimTop",
            "fixture simulator\n",
        )
        reference = write_text(
            self.root,
            ".github/task-runs/fixture/evidence/functional/frozen/"
            "riscv64-nemu-interpreter-so",
            "fixture reference\n",
        )
        simulator.chmod(0o755)
        reference.chmod(0o755)
        write_text(
            self.root,
            ".github/task-runs/fixture/evidence/functional/frozen/npc.config",
            "CONFIG_NPC_DIFFTEST=y\n",
        )
        sources = []
        for index, kind in enumerate((
            "reference_config", "reference_model_source",
            "comparison_policy_source",
        )):
            path = write_text(
                self.root,
                ".github/task-runs/fixture/evidence/functional/"
                f"reference/source-{index}.txt",
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
        write_json(
            self.root,
            ".github/task-runs/fixture/evidence/functional/reference/profile.json",
            profile,
        )
        write_text(
            self.root,
            ".github/task-runs/fixture/evidence/functional/raw/build.log",
            "Verilator build complete\n",
        )
        module_tests = []
        for test_id in ("tb_a", "tb_b"):
            raw = write_text(
                self.root,
                ".github/task-runs/fixture/evidence/module/"
                f"logs/{test_id}.log",
                f"[RTL-DESIGN-ID] {self.design_id}\n"
                f"[TEST] {test_id}\n[PASS] {test_id}\n[RESULT] PASS\n",
            )
            module_tests.append({
                "test_id": test_id,
                "compile_rc": 0,
                "simulation_rc": 0,
                "raw_log": raw.relative_to(self.root).as_posix(),
            })
        official = self._suite_records(
            "official", 177, "Difftest: OFF\nTOHOST PASS\n",
            test_ids=self.official_ids,
        )
        am = self._suite_records(
            "am", am_count, "Difftest: ON\nHIT GOOD TRAP\n")
        coremark_image = write_bytes(
            self.root,
            ".github/task-runs/fixture/evidence/functional/images/coremark.bin",
            b"coremark-image",
        )
        dhrystone_image = write_bytes(
            self.root,
            ".github/task-runs/fixture/evidence/functional/images/dhrystone.bin",
            b"dhrystone-image",
        )
        coremark_raw = write_text(
            self.root,
            ".github/task-runs/fixture/evidence/functional/raw/coremark.log",
            "Running CoreMark for 10 iterations\n"
            "Iterations       : 10\n"
            "[0]crcfinal      : 0xfcaf\n"
            "CoreMark PASS       123 Marks\n"
            "HIT GOOD TRAP\n")
        dhrystone_raw = write_text(
            self.root,
            ".github/task-runs/fixture/evidence/functional/raw/dhrystone.log",
            "Trying 10000 runs through Dhrystone.\n"
            "Dhrystone PASS         123 Marks\n"
            "HIT GOOD TRAP\n")
        self.descriptor_value = {
            "schema": functional.DESCRIPTOR_SCHEMA,
            "design_id": self.design_id,
            "cohort_id": self.cohort_id,
            "simulator": simulator.relative_to(self.root).as_posix(),
            "configuration": (
                ".github/task-runs/fixture/evidence/functional/frozen/npc.config"
            ),
            "build": {
                "command": "make local RV64 Verilator simulator",
                "return_code": 0,
                "raw_log": (
                    ".github/task-runs/fixture/evidence/functional/raw/build.log"
                ),
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
                "reference_profile": (
                    ".github/task-runs/fixture/evidence/functional/"
                    "reference/profile.json"
                ),
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
            self.root,
            ".github/task-runs/fixture/evidence/functional/descriptor.json",
            self.descriptor_value,
        )

    def _copy_schemas(self) -> None:
        for name in (
            "functional-aggregate-v2.schema.json",
            "functional-aggregate-result-v1.schema.json",
            "difftest-reference-profile-v1.schema.json",
        ):
            destination = self.root / "npc/rv64/eval/ppa/schemas" / name
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(REPO / "npc/rv64/eval/ppa/schemas" / name, destination)

    def _copy_workflow_sources(self) -> None:
        relative_paths = (
            "npc/rv64/eval/ppa/tools/arch_stable_freeze.py",
            "npc/rv64/eval/ppa/tools/functional_aggregate.py",
            "npc/rv64/eval/ppa/tools/full_core_current_evidence.py",
            "npc/rv64/eval/ppa/tools/full_core_functional_evidence.py",
            "npc/rv64/eval/ppa/run-full-core-current.sh",
            "npc/rv64/design/arch/full-core-functional-run-policy-v1.json",
            "scripts/task-run-status.sh",
            ".github/task-runs/2026-07-22-rv64-v9l-functional-aggregate-current-design/"
            "run-functional-aggregate.py",
        )
        for relative in relative_paths:
            destination = self.root / relative
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(REPO / relative, destination)

    def _prepare_source_closure(self, am_count: int) -> None:
        write_text(
            self.root, "npc/rv64/include/generated/autoconf.h",
            "#define CONFIG_FIXTURE 1\n")
        write_text(self.root, "npc/rv64/vsrc/filelist.mk", "Dut.v\n")
        for test_id in ("tb_a", "tb_b"):
            write_text(
                self.root, f"npc/rv64/testbench/tests/{test_id}.sv",
                f"module {test_id}; endmodule\n")
        for relative, text in (
            ("npc/rv64/Makefile", "all:\n\t@true\n"),
            ("npc/rv64/Kconfig", "mainmenu \"fixture\"\n"),
            ("npc/rv64/.config", "CONFIG_NPC_DIFFTEST=y\n"),
            ("npc/rv64/configs/default_defconfig", "CONFIG_NPC_DIFFTEST=y\n"),
            ("npc/rv64/csrc/main.cpp", "int main() { return 0; }\n"),
            ("am-kernels/tests/cpu-tests/Makefile", "all:\n\t@true\n"),
            ("am-kernels/tests/cpu-tests/scripts/check_results.py", "pass\n"),
            ("abstract-machine/Makefile", "all:\n\t@true\n"),
            ("abstract-machine/am/fixture.c", "int am_fixture;\n"),
            ("abstract-machine/klib/fixture.c", "int klib_fixture;\n"),
            ("abstract-machine/scripts/riscv64-npc.mk", "ARCH := riscv64\n"),
            ("am-kernels/benchmarks/coremark/Makefile", "all:\n\t@true\n"),
            ("am-kernels/benchmarks/coremark/core_main.c", "int coremark;\n"),
            ("am-kernels/benchmarks/dhrystone/Makefile", "all:\n\t@true\n"),
            ("am-kernels/benchmarks/dhrystone/dhry.c", "int dhrystone;\n"),
            ("nemu/Makefile", "all:\n\t@true\n"),
            ("nemu/Kconfig", "mainmenu \"fixture\"\n"),
            ("nemu/.config", "CONFIG_ENGINE_INTERPRETER=y\n"),
            ("nemu/configs/riscv64-npc_defconfig", "CONFIG_ISA_RISCV64=y\n"),
            ("nemu/src/main.c", "int nemu_main;\n"),
            ("nemu/include/cpu.h", "#pragma once\n"),
            ("nemu/scripts/build.mk", "all:\n\t@true\n"),
        ):
            write_text(self.root, relative, text)
        self.official_ids = [f"rv64ui-p-case_{index:03d}" for index in range(177)]
        write_text(
            self.root, "npc/rv64/testsuites/scripts/npc-rv64-core-regress.sh",
            "RISCV_SUITES_DEFAULT=(rv64ui)\nRISCV_PRIVILEGED_SUITES=()\n",
        )
        for index in range(177):
            write_text(
                self.root,
                "npc/rv64/testsuites/core-tests/src/riscv-tests/isa/rv64ui/"
                f"case_{index:03d}.S",
                ".section .text\n",
            )
        for index in range(am_count):
            write_text(
                self.root,
                f"am-kernels/tests/cpu-tests/tests/am_{index:03d}.c",
                "int main(void) { return 0; }\n",
            )

    def _suite_records(
        self,
        name: str,
        count: int,
        log_text: str,
        *,
        test_ids: list[str] | None = None,
    ) -> list[dict]:
        records = []
        ids = test_ids or [f"{name}_{index:03d}" for index in range(count)]
        if len(ids) != count:
            raise AssertionError("fixture suite source count drifted")
        for index, test_id in enumerate(ids):
            image = write_bytes(
                self.root,
                ".github/task-runs/fixture/evidence/functional/"
                f"images/{name}/{test_id}.bin",
                f"{name}-image-{index}".encode("utf-8"))
            raw = write_text(
                self.root,
                ".github/task-runs/fixture/evidence/functional/"
                f"raw/{name}/{test_id}.log",
                log_text,
            )
            records.append({
                "test_id": test_id,
                "return_code": 0,
                "image": image.relative_to(self.root).as_posix(),
                "raw_log": raw.relative_to(self.root).as_posix(),
            })
        return records

    def assemble(self) -> dict:
        result = functional.assemble(
            root=self.root,
            descriptor_path=self.descriptor,
            wrapper_dir=self.source_dir / "wrapped",
            aggregate_path=self.source_dir / "functional-aggregate.json",
            mutation_summary_path=self.mutation_path,
            raw_log_path=self.source_dir / "functional-aggregate.log",
            result_path=self.source_dir / "functional-aggregate-result.json",
            check_current_design=False,
        )
        self._write_run_closure(result)
        write_text(self.root, ".github/task-runs/fixture/full-core-current.status", "PASS\n")
        write_text(
            self.root,
            ".github/task-runs/fixture/full-core-publication.status",
            "PASS\n",
        )
        self.rebind_publication()
        return result

    def _write_run_closure(self, aggregate_result: dict) -> None:
        tests = ["tb_a", "tb_b"]
        architecture = functional.freeze.load_workspace_module(
            self.root,
            "npc/rv64/eval/ppa/tools/architecture_hard_gates.py",
            "functional_fixture_architecture",
        )
        module_inputs = functional.freeze.f0_capture_module_inputs(
            self.root, tests, architecture
        )
        write_json(
            self.root,
            (self.module_dir / "inputs.pre.json").relative_to(self.root).as_posix(),
            module_inputs,
        )
        write_json(
            self.root,
            (self.module_dir / "inputs.post.json").relative_to(self.root).as_posix(),
            module_inputs,
        )
        write_text(
            self.root,
            (self.module_dir / "summary.txt").relative_to(self.root).as_posix(),
            "module=2/2\n",
        )
        write_text(
            self.root,
            (self.module_dir / "module-make.log").relative_to(self.root).as_posix(),
            "module make PASS\n",
        )
        module_result_path = self.module_dir / "result.json"
        module_result = {
            "schema": "npc-rv64-full-core-module-current-evidence-v1",
            "status": "PASS",
            "design_id": self.design_id,
            "tests": {
                "required": len(tests),
                "passed": len(tests),
                "inventory": tests,
                "logs": {
                    test_id: self._artifact(
                        self.module_dir / "logs" / f"{test_id}.log",
                        "module_test_log",
                    )
                    for test_id in tests
                },
            },
            "command": "run local SystemVerilog module inventory",
            "inputs": {
                "pre": self._artifact(
                    self.module_dir / "inputs.pre.json", "input_binding"
                ),
                "post": self._artifact(
                    self.module_dir / "inputs.post.json", "input_binding"
                ),
                "unchanged": True,
            },
            "artifacts": {
                "summary": self._artifact(
                    self.module_dir / "summary.txt", "module_test_summary"
                ),
                "make_log": self._artifact(
                    self.module_dir / "module-make.log", "module_make_log"
                ),
            },
            "retention": {
                "compiled_images_retained": 0,
                "compiled_images_location": "task-owned temporary directory",
            },
        }
        write_json(
            self.root,
            module_result_path.relative_to(self.root).as_posix(),
            module_result,
        )
        write_json(
            self.root,
            (self.module_dir / "status.json").relative_to(self.root).as_posix(),
            {
                "schema": "npc-rv64-evidence-stage-status-v1",
                "state": "PASS",
                "stage": "complete",
                "detail": "tests=2/2",
                "design_id": self.design_id,
            },
        )

        functional_inputs = functional.freeze.f0_capture_functional_inputs(
            self.root, tests, architecture
        )
        for name in ("inputs.pre.json", "inputs.post.json"):
            write_json(
                self.root,
                (self.source_dir / name).relative_to(self.root).as_posix(),
                functional_inputs,
            )
        counts = aggregate_result["counts"]
        run_result = {
            "schema": functional.freeze.F0_RUN_RESULT_SCHEMA,
            "status": "PASS",
            "design_id": self.design_id,
            "counts": counts,
            "module_result": self._artifact(
                module_result_path, "module_current_result"
            ),
            "artifacts": {
                "aggregate": self._artifact(
                    self.source_dir / "functional-aggregate.json",
                    "functional_aggregate",
                ),
                "aggregate_result": self._artifact(
                    self.source_dir / "functional-aggregate-result.json",
                    "functional_aggregate_result",
                ),
                "aggregate_log": self._artifact(
                    self.source_dir / "functional-aggregate.log",
                    "functional_aggregate_log",
                ),
                "simulator": self._artifact(
                    self.source_dir / "frozen/NpcSimTop", "simulator_binary"
                ),
                "reference": self._artifact(
                    self.source_dir / "frozen/riscv64-nemu-interpreter-so",
                    "reference_model_binary",
                ),
                "configuration": self._artifact(
                    self.source_dir / "frozen/npc.config", "kconfig"
                ),
            },
            "inputs": {
                "pre": self._artifact(
                    self.source_dir / "inputs.pre.json", "functional_input_binding"
                ),
                "post": self._artifact(
                    self.source_dir / "inputs.post.json", "functional_input_binding"
                ),
                "unchanged": True,
            },
            "inputs_unchanged": True,
            "retention": {
                "module_simulation_reused": True,
                "compiled_intermediates_retained": 0,
                "frozen_simulator_retained": 1,
                "frozen_reference_retained": 1,
                "program_images_retained": 177 + counts["am_required"] + 2,
            },
            "published_current": False,
        }
        write_json(
            self.root,
            (self.source_dir / "run-result.json").relative_to(self.root).as_posix(),
            run_result,
        )
        write_json(
            self.root,
            (self.source_dir / "status.json").relative_to(self.root).as_posix(),
            {
                "schema": "npc-rv64-evidence-stage-status-v1",
                "state": "PASS",
                "stage": "complete",
                "detail": "fixture full-core functional PASS",
                "design_id": self.design_id,
            },
        )

    def _artifact(self, path: pathlib.Path, kind: str) -> dict[str, object]:
        return {
            "kind": kind,
            "path": path.relative_to(self.root).as_posix(),
            "sha256": functional.sha256_file(path),
            "size_bytes": path.stat().st_size,
        }

    def rebuild_aggregate_receipts(self) -> None:
        """Rebind a deliberately mutated wrapper as a coherent negative input."""

        aggregate_path = self.source_dir / "functional-aggregate.json"
        aggregate = functional.load_json(aggregate_path)
        required_tests = ["tb_a", "tb_b"]
        mutations = functional.run_mutations(
            self.root,
            aggregate,
            required_tests,
            self.source_dir / "wrapped/mutation-inputs",
            prepare_inputs=False,
        )
        write_json(
            self.root,
            self.mutation_path.relative_to(self.root).as_posix(),
            mutations,
        )
        checks, blockers, _ = functional.validate_aggregate(
            self.root, aggregate, required_tests
        )
        if blockers:
            raise AssertionError(f"fixture aggregate mutation is inconsistent: {blockers}")
        aggregate_result_path = self.source_dir / "functional-aggregate-result.json"
        aggregate_result = functional.load_json(aggregate_result_path)
        counts = aggregate_result["counts"]
        counts["evidence_mutations_compiled"] = mutations["schema_valid"]
        counts["evidence_mutations_rejected"] = mutations["schema_valid_rejected"]
        aggregate_log_path = self.source_dir / "functional-aggregate.log"
        write_text(
            self.root,
            aggregate_log_path.relative_to(self.root).as_posix(),
            functional.aggregate_log_text(aggregate, counts, checks),
        )
        aggregate_result["aggregate"] = functional.artifact(
            self.root,
            aggregate_path.relative_to(self.root).as_posix(),
            "functional_aggregate",
        )
        aggregate_result["raw_log"] = functional.artifact(
            self.root,
            aggregate_log_path.relative_to(self.root).as_posix(),
            "raw_log",
        )
        aggregate_result["mutation_summary"] = functional.artifact(
            self.root,
            self.mutation_path.relative_to(self.root).as_posix(),
            "mutation_summary",
        )
        aggregate_result["checks"] = checks
        write_json(
            self.root,
            aggregate_result_path.relative_to(self.root).as_posix(),
            aggregate_result,
        )
        self.rebind_publication()

    def rebind_publication(self) -> None:
        """Recompute a production-shaped binding after a negative mutation."""

        source_aggregate = self.source_dir / "functional-aggregate.json"
        source_result = self.source_dir / "functional-aggregate-result.json"
        source_log = self.source_dir / "functional-aggregate.log"
        canonical_aggregate = self.root / functional.freeze.F0_AGGREGATE_PATH
        canonical_result = self.root / functional.freeze.F0_RESULT_PATH
        canonical_log = self.root / functional.freeze.F0_RAW_PATH
        for source, destination in (
            (source_aggregate, canonical_aggregate),
            (source_result, canonical_result),
            (source_log, canonical_log),
        ):
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source, destination)

        aggregate_result = json.loads(source_result.read_text(encoding="utf-8"))
        run_result_path = self.source_dir / "run-result.json"
        run_result = json.loads(run_result_path.read_text(encoding="utf-8"))
        run_result["counts"] = aggregate_result["counts"]
        run_result["artifacts"]["aggregate"] = self._artifact(
            source_aggregate, "functional_aggregate")
        run_result["artifacts"]["aggregate_result"] = self._artifact(
            source_result, "functional_aggregate_result")
        run_result["artifacts"]["aggregate_log"] = self._artifact(
            source_log, "functional_aggregate_log")
        write_json(
            self.root,
            run_result_path.relative_to(self.root).as_posix(),
            run_result,
        )
        binding = {
            "schema": functional.freeze.F0_PUBLICATION_SCHEMA,
            "status": "PASS",
            "design_id": self.design_id,
            "cohort_id": self.cohort_id,
            "source_run_result": self._artifact(
                run_result_path, "functional_run_result"),
            "execution_status": self._artifact(
                self.run_dir / "full-core-current.status",
                "full_core_execution_status",
            ),
            "artifacts": {
                "aggregate": self._artifact(
                    canonical_aggregate, "functional_aggregate"),
                "aggregate_result": self._artifact(
                    canonical_result, "functional_aggregate_result"),
                "aggregate_log": self._artifact(
                    canonical_log, "functional_aggregate_log"),
            },
        }
        write_json(self.root, functional.freeze.F0_BINDING_PATH, binding)

    def f0_entry(self) -> dict[str, object]:
        paths = {
            "functional_aggregate_result": (
                self.root / functional.freeze.F0_RESULT_PATH),
            "functional_aggregate": (
                self.root / functional.freeze.F0_AGGREGATE_PATH),
            "raw_log": self.root / functional.freeze.F0_RAW_PATH,
            "mutation_summary": self.mutation_path,
        }
        return {
            "canonical_command": functional.CANONICAL_COMMAND,
            "evidence": [
                {
                    "kind": kind,
                    "path": path.relative_to(self.root).as_posix(),
                    "sha256": functional.sha256_file(path),
                }
                for kind, path in paths.items()
            ],
        }

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
            self.fixture.mutation_path.read_text(encoding="utf-8"))
        self.assertEqual(
            value["schema_valid"], len(functional.SCHEMA_VALID_MUTATION_IDS))
        self.assertEqual(
            value["schema_invalid"], len(functional.SCHEMA_INVALID_MUTATION_IDS))
        self.assertEqual(
            [item["mutation_id"] for item in value["mutations"]],
            list(functional.CANONICAL_MUTATION_IDS),
        )
        self.assertEqual(value["schema_valid_rejected"], value["schema_valid"])
        self.assertTrue(value["all_rejected"])
        self.assertIn(
            "official_test_to_image_swap",
            {item["mutation_id"] for item in value["mutations"]})

    def test_frozen_mutation_summary_matches_read_only_replay(self) -> None:
        aggregate = functional.load_json(
            self.fixture.root / functional.freeze.F0_AGGREGATE_PATH)
        frozen = functional.load_json(self.fixture.mutation_path)
        replayed = functional.run_mutations(
            self.fixture.root,
            aggregate,
            ["tb_a", "tb_b"],
            self.fixture.source_dir / "wrapped/mutation-inputs",
            prepare_inputs=False,
        )
        for key in sorted(set(replayed) | set(frozen)):
            if key == "mutations":
                continue
            with self.subTest(field=key):
                self.assertEqual(replayed.get(key), frozen.get(key))
        for index, (replayed_record, frozen_record) in enumerate(
            zip(replayed["mutations"], frozen["mutations"], strict=True)
        ):
            for key in sorted(set(replayed_record) | set(frozen_record)):
                with self.subTest(mutation=index, field=key):
                    self.assertEqual(
                        replayed_record.get(key), frozen_record.get(key))
        frozen["mutations"][0]["mutant_canonical_sha256"] = "b" * 64
        self.assertNotEqual(replayed, frozen)

    def test_benchmark_oracle_rejects_argument_only_run_count(self) -> None:
        with self.assertRaisesRegex(ValueError, "guest result markers"):
            functional.validate_benchmark_raw_output(
                "dhrystone",
                "command=mainargs=10000\nDhrystone PASS 1 Marks\n",
            )
        with self.assertRaisesRegex(ValueError, "guest result markers"):
            functional.validate_benchmark_raw_output(
                "coremark",
                "command=ITERATIONS=10\n[0]crcfinal : 0xfcaf\n",
            )

    def test_benchmark_oracle_rejects_duplicate_or_conflicting_guest_values(self) -> None:
        cases = {
            "coremark": (
                "Running CoreMark for 10 iterations\n"
                "Iterations : 10\nIterations : 9\n"
                "[0]crcfinal : 0xfcaf\n[0]crcfinal : 0x0000\n"
                "CoreMark PASS 123 Marks\nHIT GOOD TRAP\n"
            ),
            "dhrystone": (
                "Trying 10000 runs through Dhrystone.\n"
                "Trying 9999 runs through Dhrystone.\n"
                "Dhrystone PASS 123 Marks\nHIT GOOD TRAP\n"
            ),
        }
        for name, transcript in cases.items():
            with self.subTest(name=name), self.assertRaisesRegex(
                ValueError, "guest result markers"
            ):
                functional.validate_benchmark_raw_output(name, transcript)

    def test_benchmark_oracle_accepts_exact_simulator_good_trap_line(self) -> None:
        cases = {
            "coremark": (
                "Running CoreMark for 10 iterations\n"
                "Iterations : 10\n"
                "[0]crcfinal : 0xfcaf\n"
                "CoreMark PASS 5 Marks\n"
                "\x1b[1;34m[cpu-exec.cpp:2834 cpu_exec] npc: "
                "\x1b[1;32mHIT GOOD TRAP\x1b[0m at pc = "
                "0x0000000080002010\x1b[0m\n"
            ),
            "dhrystone": (
                "Trying 10000 runs through Dhrystone.\n"
                "Dhrystone PASS 42 Marks\n"
                "HIT GOOD TRAP\n"
            ),
        }
        for name, transcript in cases.items():
            with self.subTest(name=name):
                functional.validate_benchmark_raw_output(name, transcript)

    def test_benchmark_oracle_rejects_prose_or_duplicate_good_trap(self) -> None:
        coremark_prefix = (
            "Running CoreMark for 10 iterations\n"
            "Iterations : 10\n"
            "[0]crcfinal : 0xfcaf\n"
            "CoreMark PASS 5 Marks\n"
        )
        cases = (
            coremark_prefix + "diagnostic mentions HIT GOOD TRAP only\n",
            coremark_prefix
            + "HIT GOOD TRAP\n"
            + "[cpu_exec] npc: HIT GOOD TRAP at pc = 0x80002010\n",
        )
        for transcript in cases:
            with self.subTest(transcript=transcript), self.assertRaisesRegex(
                ValueError, "guest result markers"
            ):
                functional.validate_benchmark_raw_output("coremark", transcript)

    def test_suite_oracle_rejects_duplicate_terminal_or_difftest_state(self) -> None:
        cases = (
            (
                "official",
                "rv64ui-p-add",
                "[cpu_exec] npc: TOHOST PASS at pc = 0x80000000\n"
                "TOHOST PASS\n",
            ),
            (
                "am",
                "am_000",
                "[welcome] Difftest: ON\nDifftest: ON\nHIT GOOD TRAP\n",
            ),
            (
                "am",
                "am_000",
                "[welcome] Difftest: ON\nDifftest: OFF\nHIT GOOD TRAP\n",
            ),
        )
        for suite, test_id, transcript in cases:
            with self.subTest(suite=suite, transcript=transcript), \
                    self.assertRaisesRegex(ValueError, "terminal|DiffTest"):
                functional.validate_suite_raw_output(
                    suite, transcript, test_id=test_id
                )

    def test_suite_oracle_accepts_one_tagged_terminal_and_difftest_state(self) -> None:
        functional.validate_suite_raw_output(
            "official",
            "[cpu_exec] npc: TOHOST PASS at pc = 0x80000000\n",
            test_id="rv64ui-p-add",
        )
        functional.validate_suite_raw_output(
            "am",
            "[welcome] Difftest: ON\n"
            "[cpu_exec] npc: HIT GOOD TRAP at pc = 0x80000000\n",
            test_id="am_000",
        )

    def test_prepare_output_rejects_parent_and_dangling_file_symlinks(self) -> None:
        with tempfile.TemporaryDirectory(prefix="rv64-output-alias-") as raw:
            root = pathlib.Path(raw)
            foreign = root / "foreign"
            foreign.mkdir()
            parent_alias = root / "alias"
            parent_alias.symlink_to(foreign, target_is_directory=True)
            with self.assertRaisesRegex(ValueError, "symlink"):
                functional.prepare_output(root, parent_alias / "result.json")

            dangling_target = foreign / "not-created.json"
            file_alias = root / "result.json"
            file_alias.symlink_to(dangling_target)
            with self.assertRaisesRegex(ValueError, "symlink"):
                functional.prepare_output(root, file_alias)

    def test_image_map_digest_excludes_workspace_path(self) -> None:
        aggregate = json.loads(
            (self.fixture.root / functional.freeze.F0_AGGREGATE_PATH).read_text(encoding="utf-8"))
        original = aggregate["official"]["image_set_sha256"]
        changed = json.loads(json.dumps(aggregate["official"]["images"]))
        changed[0]["image"]["path"] = "different/local/copy.bin"
        self.assertEqual(original, functional.image_set_sha("official", changed))

    def test_f0_debt_semantic_validator_reconstructs_live_result(self) -> None:
        self.assertEqual(
            functional.freeze.validate_f0_debt(
                self.fixture.root,
                self.fixture.f0_entry(),
                self.fixture.design_id,
            ),
            [],
        )

    def test_f0_debt_requires_execution_and_publication_pass(self) -> None:
        fixture = FunctionalFixture()
        try:
            fixture.assemble()
            (fixture.run_dir / "full-core-publication.status").write_text(
                "FAIL stage=publication\n", encoding="utf-8")
            errors = functional.freeze.validate_f0_debt(
                fixture.root, fixture.f0_entry(), fixture.design_id)
            self.assertTrue(
                any("publication status is not exact PASS" in item for item in errors),
                errors,
            )
            (fixture.run_dir / "full-core-publication.status").write_text(
                "PASS\n", encoding="utf-8")
            (fixture.run_dir / "full-core-current.status").write_text(
                "FAIL stage=verify\n", encoding="utf-8")
            fixture.rebind_publication()
            errors = functional.freeze.validate_f0_debt(
                fixture.root, fixture.f0_entry(), fixture.design_id)
            self.assertTrue(
                any("execution status is not exact PASS" in item for item in errors),
                errors,
            )
        finally:
            fixture.close()

    def test_f0_debt_requires_canonical_publication_binding(self) -> None:
        fixture = FunctionalFixture()
        try:
            fixture.assemble()
            (fixture.root / functional.freeze.F0_BINDING_PATH).unlink()
            errors = functional.freeze.validate_f0_debt(
                fixture.root, fixture.f0_entry(), fixture.design_id)
            self.assertTrue(
                any("binding" in item for item in errors),
                errors,
            )
        finally:
            fixture.close()

    def test_f0_debt_rejects_source_run_without_module_closure(self) -> None:
        fixture = FunctionalFixture(am_count=3)
        try:
            fixture.assemble()
            run_result_path = fixture.source_dir / "run-result.json"
            run_result = functional.load_json(run_result_path)
            run_result.pop("module_result")
            write_json(
                fixture.root,
                run_result_path.relative_to(fixture.root).as_posix(),
                run_result,
            )
            fixture.rebind_publication()
            errors = functional.freeze.validate_f0_debt(
                fixture.root, fixture.f0_entry(), fixture.design_id
            )
            self.assertTrue(
                any("source run deep validation failed" in item for item in errors),
                errors,
            )
        finally:
            fixture.close()

    def test_f0_debt_rejects_cross_run_module_log(self) -> None:
        fixture = FunctionalFixture(am_count=3)
        try:
            fixture.assemble()
            foreign_log = write_text(
                fixture.root,
                ".github/task-runs/foreign/evidence/module/logs/tb_a.log",
                f"[RTL-DESIGN-ID] {fixture.design_id}\n"
                "[TEST] tb_a\n[PASS] tb_a\n[RESULT] PASS\n",
            )
            module_result_path = fixture.module_dir / "result.json"
            module_result = functional.load_json(module_result_path)
            module_result["tests"]["logs"]["tb_a"] = fixture._artifact(
                foreign_log, "module_test_log"
            )
            write_json(
                fixture.root,
                module_result_path.relative_to(fixture.root).as_posix(),
                module_result,
            )
            run_result_path = fixture.source_dir / "run-result.json"
            run_result = functional.load_json(run_result_path)
            run_result["module_result"] = fixture._artifact(
                module_result_path, "module_current_result"
            )
            write_json(
                fixture.root,
                run_result_path.relative_to(fixture.root).as_posix(),
                run_result,
            )
            fixture.rebind_publication()
            errors = functional.freeze.validate_f0_debt(
                fixture.root, fixture.f0_entry(), fixture.design_id
            )
            self.assertTrue(
                any("points outside the owning run" in item for item in errors),
                errors,
            )
        finally:
            fixture.close()

    def test_f0_debt_rejects_parent_directory_symlink_to_foreign_module(self) -> None:
        fixture = FunctionalFixture(am_count=3)
        try:
            fixture.assemble()
            foreign_module = (
                fixture.root / ".github/task-runs/foreign/evidence/module"
            )
            shutil.copytree(fixture.module_dir, foreign_module)
            shutil.rmtree(fixture.module_dir)
            fixture.module_dir.symlink_to(foreign_module, target_is_directory=True)
            errors = functional.freeze.validate_f0_debt(
                fixture.root, fixture.f0_entry(), fixture.design_id
            )
            self.assertTrue(any("symlink" in item for item in errors), errors)
        finally:
            fixture.close()

    def test_f0_debt_replays_rebound_official_and_am_guest_logs(self) -> None:
        cases = (
            ("official", "TOHOST PASS", "ABORT at pc 0x80000000"),
            ("am", "Difftest: ON", "Difftest: OFF"),
        )
        for suite, original, replacement in cases:
            with self.subTest(suite=suite):
                fixture = FunctionalFixture(am_count=3)
                try:
                    fixture.assemble()
                    aggregate_path = (
                        fixture.source_dir / "functional-aggregate.json"
                    )
                    aggregate = functional.load_json(aggregate_path)
                    record = aggregate[suite]["images"][0]
                    wrapper_path = fixture.root / record["log"]["path"]
                    wrapper_text = wrapper_path.read_text(encoding="utf-8")
                    self.assertIn(original, wrapper_text)
                    wrapper_path.write_text(
                        wrapper_text.replace(original, replacement, 1),
                        encoding="utf-8",
                    )
                    record["log"] = functional.artifact(
                        fixture.root,
                        wrapper_path.relative_to(fixture.root).as_posix(),
                        "official_test_log" if suite == "official" else "am_test_log",
                    )
                    write_json(
                        fixture.root,
                        aggregate_path.relative_to(fixture.root).as_posix(),
                        aggregate,
                    )
                    fixture.rebuild_aggregate_receipts()
                    errors = functional.freeze.validate_f0_debt(
                        fixture.root, fixture.f0_entry(), fixture.design_id
                    )
                    self.assertTrue(
                        any("source run deep validation failed" in item for item in errors),
                        errors,
                    )
                finally:
                    fixture.close()

    def test_f0_debt_rejects_post_wrapper_raw_suite_log_drift(self) -> None:
        cases = (
            ("official", "ABORT at pc 0x80000000\n"),
            ("am", "Difftest: OFF\nHIT GOOD TRAP\n"),
        )
        for suite, drifted_text in cases:
            with self.subTest(suite=suite):
                fixture = FunctionalFixture(am_count=3)
                try:
                    fixture.assemble()
                    aggregate = functional.load_json(
                        fixture.source_dir / "functional-aggregate.json"
                    )
                    test_id = aggregate[suite]["inventory"][0]
                    raw_log = (
                        fixture.source_dir / "raw" / suite / f"{test_id}.log"
                    )
                    raw_log.write_text(drifted_text, encoding="utf-8")
                    errors = functional.freeze.validate_f0_debt(
                        fixture.root, fixture.f0_entry(), fixture.design_id
                    )
                    self.assertTrue(
                        any("source run deep validation failed" in item for item in errors),
                        errors,
                    )
                finally:
                    fixture.close()

    def test_f0_debt_rejects_crlf_only_raw_log_byte_drift(self) -> None:
        fixture = FunctionalFixture(am_count=3)
        try:
            fixture.assemble()
            aggregate_path = fixture.source_dir / "functional-aggregate.json"
            aggregate = functional.load_json(aggregate_path)
            test_id = aggregate["official"]["inventory"][0]
            raw_path = fixture.source_dir / "raw/official" / f"{test_id}.log"
            old_hash = functional.sha256_file(raw_path)
            raw_bytes = raw_path.read_bytes()
            self.assertIn(b"\n", raw_bytes)
            self.assertNotIn(b"\r\n", raw_bytes)
            raw_path.write_bytes(raw_bytes.replace(b"\n", b"\r\n"))
            new_hash = functional.sha256_file(raw_path)

            wrapper_path = fixture.source_dir / "wrapped/official" / f"{test_id}.log"
            wrapper_path.write_text(
                wrapper_path.read_text(encoding="utf-8").replace(
                    f"source_log_sha256={old_hash}",
                    f"source_log_sha256={new_hash}",
                ),
                encoding="utf-8",
            )
            aggregate["official"]["images"][0]["log"] = functional.artifact(
                fixture.root,
                wrapper_path.relative_to(fixture.root).as_posix(),
                "official_test_log",
            )
            write_json(
                fixture.root,
                aggregate_path.relative_to(fixture.root).as_posix(),
                aggregate,
            )
            fixture.rebuild_aggregate_receipts()
            errors = functional.freeze.validate_f0_debt(
                fixture.root, fixture.f0_entry(), fixture.design_id
            )
            self.assertTrue(
                any("source run deep validation failed" in item for item in errors),
                errors,
            )
        finally:
            fixture.close()

    def test_f0_debt_rejects_frozen_official_source_membership_drift(self) -> None:
        fixture = FunctionalFixture(am_count=3)
        try:
            fixture.assemble()
            run_result_path = fixture.source_dir / "run-result.json"
            run_result = functional.load_json(run_result_path)
            for name in ("inputs.pre.json", "inputs.post.json"):
                input_path = fixture.source_dir / name
                inputs = functional.load_json(input_path)
                inputs["official_test_ids"][0] = "rv64ui-p-arbitrary"
                write_json(
                    fixture.root,
                    input_path.relative_to(fixture.root).as_posix(),
                    inputs,
                )
            run_result["inputs"]["pre"] = fixture._artifact(
                fixture.source_dir / "inputs.pre.json", "functional_input_binding"
            )
            run_result["inputs"]["post"] = fixture._artifact(
                fixture.source_dir / "inputs.post.json", "functional_input_binding"
            )
            write_json(
                fixture.root,
                run_result_path.relative_to(fixture.root).as_posix(),
                run_result,
            )
            fixture.rebind_publication()
            errors = functional.freeze.validate_f0_debt(
                fixture.root, fixture.f0_entry(), fixture.design_id
            )
            self.assertTrue(
                any("official inventory differs" in item for item in errors),
                errors,
            )
        finally:
            fixture.close()

    def test_f0_debt_reparses_benchmark_guest_lines(self) -> None:
        fixture = FunctionalFixture(am_count=3)
        try:
            fixture.assemble()
            raw_path = fixture.source_dir / "raw/coremark.log"
            old_raw_hash = functional.sha256_file(raw_path)
            raw_path.write_text(
                raw_path.read_text(encoding="utf-8").replace(
                    "Iterations       : 10", "Iterations       : 9"
                ),
                encoding="utf-8",
            )
            new_raw_hash = functional.sha256_file(raw_path)
            wrapper_path = fixture.source_dir / "wrapped/coremark.log"
            wrapper_path.write_text(
                wrapper_path.read_text(encoding="utf-8").replace(
                    "Iterations       : 10", "Iterations       : 9"
                ).replace(
                    f"source_log_sha256={old_raw_hash}",
                    f"source_log_sha256={new_raw_hash}",
                ),
                encoding="utf-8",
            )
            aggregate_path = fixture.source_dir / "functional-aggregate.json"
            aggregate = functional.load_json(aggregate_path)
            aggregate["benchmarks"]["coremark"]["log"]["sha256"] = (
                functional.sha256_file(wrapper_path)
            )
            write_json(
                fixture.root,
                aggregate_path.relative_to(fixture.root).as_posix(),
                aggregate,
            )
            aggregate_result_path = (
                fixture.source_dir / "functional-aggregate-result.json"
            )
            aggregate_result = functional.load_json(aggregate_result_path)
            aggregate_result["aggregate"]["sha256"] = functional.sha256_file(
                aggregate_path
            )
            write_json(
                fixture.root,
                aggregate_result_path.relative_to(fixture.root).as_posix(),
                aggregate_result,
            )
            fixture.rebind_publication()
            errors = functional.freeze.validate_f0_debt(
                fixture.root, fixture.f0_entry(), fixture.design_id
            )
            self.assertTrue(
                any("guest result markers" in item for item in errors), errors
            )
        finally:
            fixture.close()

    def test_f0_debt_rejects_rebound_noncanonical_mutation_inventory(self) -> None:
        fixture = FunctionalFixture()
        try:
            fixture.assemble()
            mutations = functional.load_json(fixture.mutation_path)
            mutations["mutations"] = mutations["mutations"][:10]
            mutations["total"] = 10
            mutations["schema_valid"] = 10
            mutations["schema_invalid"] = 0
            mutations["schema_valid_rejected"] = 10
            write_json(
                fixture.root,
                fixture.mutation_path.relative_to(fixture.root).as_posix(),
                mutations,
            )
            aggregate_result_path = (
                fixture.source_dir / "functional-aggregate-result.json")
            aggregate_result = functional.load_json(aggregate_result_path)
            aggregate_result["mutation_summary"]["sha256"] = (
                functional.sha256_file(fixture.mutation_path))
            aggregate_result["counts"]["evidence_mutations_compiled"] = 10
            aggregate_result["counts"]["evidence_mutations_rejected"] = 10
            write_json(
                fixture.root,
                aggregate_result_path.relative_to(fixture.root).as_posix(),
                aggregate_result,
            )
            fixture.rebind_publication()
            errors = functional.freeze.validate_f0_debt(
                fixture.root, fixture.f0_entry(), fixture.design_id)
            self.assertTrue(
                any("canonical inventory drifted" in item for item in errors),
                errors,
            )
        finally:
            fixture.close()

    def test_f0_debt_rejects_rebound_contradictory_terminal_receipt(self) -> None:
        fixture = FunctionalFixture()
        try:
            fixture.assemble()
            source_log = fixture.source_dir / "functional-aggregate.log"
            source_log.write_text(
                source_log.read_text(encoding="utf-8")
                + "ppa=QUALIFIED\npromotion_eligible=true\n",
                encoding="utf-8",
            )
            aggregate_result_path = (
                fixture.source_dir / "functional-aggregate-result.json")
            aggregate_result = functional.load_json(aggregate_result_path)
            aggregate_result["raw_log"]["sha256"] = functional.sha256_file(
                source_log)
            write_json(
                fixture.root,
                aggregate_result_path.relative_to(fixture.root).as_posix(),
                aggregate_result,
            )
            fixture.rebind_publication()
            errors = functional.freeze.validate_f0_debt(
                fixture.root, fixture.f0_entry(), fixture.design_id)
            self.assertTrue(
                any("exact terminal receipt" in item for item in errors),
                errors,
            )
        finally:
            fixture.close()

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

            self.assertEqual(
                functional.freeze.validate_f0_debt(
                    fixture.root, fixture.f0_entry(), fixture.design_id),
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
