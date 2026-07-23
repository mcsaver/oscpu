#!/usr/bin/env python3
"""Positive and fail-closed tests for the full-core ARCH_STABLE audit."""

from __future__ import annotations

import importlib.util
import json
import os
import pathlib
import subprocess
import sys
import tempfile
import unittest

import jsonschema


TOOL = pathlib.Path(__file__).resolve().parents[1] / "tools" / "arch_stable_freeze.py"
REPO_ROOT = TOOL.parents[5]
SPEC = importlib.util.spec_from_file_location("arch_stable_freeze", TOOL)
assert SPEC is not None and SPEC.loader is not None
freeze = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = freeze
SPEC.loader.exec_module(freeze)


STATIC_DESIGN_ID = "sha256:" + "d" * 64


def write_text(root: pathlib.Path, relative: str, text: str) -> pathlib.Path:
    path = root / relative
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")
    return path


def write_json(root: pathlib.Path, relative: str, value: dict) -> pathlib.Path:
    return write_text(
        root,
        relative,
        json.dumps(value, allow_nan=False, indent=2, sort_keys=True) + "\n",
    )


def artifact(root: pathlib.Path, path: pathlib.Path, kind: str) -> dict[str, str]:
    return {
        "kind": kind,
        "path": path.relative_to(root).as_posix(),
        "sha256": freeze.sha256_file(path),
    }


class GreenFixture:
    """Small but independently recomputed full-green architecture fixture."""

    def __init__(self, root: pathlib.Path) -> None:
        self.root = root
        self.old_path = os.environ.get("PATH", "")
        (root / ".git").mkdir()
        self.cohort_id = "test-full-core"

        self.roadmap = write_text(
            root,
            "npc/rv64/design/arch/ROADMAP.md",
            "<!-- ARCH-DEBT-P0: STORE-BRESP-G1 -->\n"
            "<!-- ARCH-DEBT-P1: OPTIONAL-G1 -->\n",
        )
        self.arch_contract = write_text(
            root,
            "npc/rv64/design/arch/rv64-architecture-ppa-contract.md",
            "# fixture architecture contract\n",
        )
        self.module_spec = write_text(
            root, "npc/rv64/design/specs/core.md", "# frozen core spec\n")
        self.rtl = write_text(
            root, "npc/rv64/vsrc/core.v", "module core; endmodule\n")
        self.filelist = write_text(
            root, "npc/rv64/vsrc/filelist.mk", "RTL_CORE_SRCS := core.v\n")
        self.config = write_text(root, "npc/rv64/.config", "CONFIG_TEST=y\n")
        self.header = write_text(
            root, "npc/rv64/include/generated/autoconf.h",
            "#define CONFIG_TEST 1\n")
        self.makefile = write_text(
            root, "npc/rv64/testbench/Makefile", "TESTS := tb_a\n")
        self.test_source = write_text(
            root, "npc/rv64/testbench/tests/tb_a.sv",
            "module tb_a; endmodule\n")
        self.test_common = write_text(
            root, "npc/rv64/testbench/common/tb_common.svh",
            "`define TB_PASS 1\n")
        self.test_runner = write_text(
            root, "npc/rv64/testbench/scripts/run_tb.sh",
            "#!/bin/sh\nexit 0\n")

        self.owner_sq_rtl = write_text(
            root,
            "npc/rv64/vsrc/memory/OooStoreQueue.v",
            "module OooStoreQueue;\n"
            "  reg request_sent_q [0:3];\n"
            "  integer head_q;\n"
            "  wire req_fire_i = 1'b0;\n"
            "  wire req_valid_o = 1'b0;\n"
            "  always @(*) begin\n"
            "      if (req_fire_i && req_valid_o)\n"
            "        request_sent_q[head_q] <= 1'b1;\n"
            "  end\n"
            "endmodule\n",
        )
        self.owner_amo_rtl = write_text(
            root,
            "npc/rv64/vsrc/execute/OooIntBackend.v",
            "module OooIntBackend;\n"
            "  reg mem_amo_write_sent_q;\n"
            "  reg reservation_valid_q;\n"
            "  reg [63:0] reservation_addr_q;\n"
            "  reg [1:0] reservation_size_q;\n"
            "  wire push_amo_write_w = 1'b0;\n"
            "  always @(*) begin\n"
            "      if (push_amo_write_w) begin\n"
            "        mem_amo_write_sent_q <= 1'b1;\n"
            "        reservation_valid_q <= 1'b0;\n"
            "        reservation_addr_q <= {`XLEN{1'b0}};\n"
            "        reservation_size_q <= 2'b00;\n"
            "      end\n"
            "  end\n"
            "endmodule\n",
        )
        self.owner_top_rtl = write_text(
            root,
            "npc/rv64/vsrc/core/NpcCoreTop.v",
            "module NpcCoreTop;\n"
            "  ) u_ooo_core (\n"
            "    .clk(clk),\n"
            "    .rst(rst),\n"
            "    .flush_i(1'b0),\n"
            "  );\n"
            "endmodule\n",
        )
        owner_runner_rel = (
            ".github/task-runs/2026-07-23-rv64-v9n-"
            "irrevocable-write-owner-residency/"
            "run-owner-residency-rtl-variants.py"
        )
        self.owner_variant_runner = write_text(
            root,
            owner_runner_rel,
            (REPO_ROOT / owner_runner_rel).read_text(encoding="utf-8"),
        )

        for relative in freeze.WORKFLOW_BINDING_PATHS:
            if relative in {
                "npc/rv64/eval/ppa/tools/architecture_hard_gates.py",
                "npc/rv64/eval/ppa/tools/producer_holder_census.py",
            }:
                continue
            source = REPO_ROOT / relative
            write_text(root, relative, source.read_text(encoding="utf-8"))

        self._write_architecture_evaluator()
        self._write_census_evaluator()
        evaluator = freeze.load_workspace_module(
            root,
            "npc/rv64/eval/ppa/tools/architecture_hard_gates.py",
            "fixture_architecture_hard_gates",
        )
        design_hex, _ = evaluator.rtl_binding(root)
        self.design_id = f"sha256:{design_hex}"

        self.focused_log = write_text(
            root, "evidence/focused.log", "[RESULT] PASS\n")
        tests = {
            name: {
                "status": "PASS",
                "provenance": {
                    "files": {
                        "evidence/focused.log": freeze.sha256_file(self.focused_log)
                    },
                    "rtl_sha256": design_hex,
                },
            }
            for name in (
                "frontend_ii1", "width_continuity", "pair_matrix",
                "no_static_lane_semantics", "dual_memory_issue",
                "true_ooo_long_latency", "selective_scheduling",
                "memory_ordering", "speculation_recovery",
            )
        }
        tests["memory_ordering"].update({
            "command": "make -C npc/rv64 check-memory-ordering",
            "metrics": {
                "precise_b_error_trap": True,
                "store_retire_before_b_success": 0,
                "store_b_terminal_violations": 0,
                "store_side_effect_before_authorization": 0,
            },
            "mutation_audit": {
                "lq_compile_success_dynamic_reject": 1,
                "f2_compile_success_dynamic_reject": 1,
            },
        })
        evidence = {
            "schema": freeze.ARCH_EVIDENCE_SCHEMA,
            "design_id": self.design_id,
            "tests": tests,
        }
        self.arch_evidence = write_json(
            root, "evidence/architecture-current.json", evidence)
        self.arch_result = write_json(
            root,
            "evidence/architecture-result.json",
            evaluator.evaluate(root, self.arch_evidence),
        )

        self.debt_log = write_text(
            root,
            "evidence/memory-ordering.log",
            f"design_id={self.design_id}\n"
            "metric precise_b_error_trap true\n"
            "metric store_retire_before_b_success 0\n"
            "metric store_b_terminal_violations 0\n"
            "lq_compile_success_mutations=9\n"
            "[ARCH-GATE] memory_ordering PASS\n",
        )
        owner_runner = freeze.load_workspace_module(
            root,
            self.owner_variant_runner.relative_to(root).as_posix(),
            "fixture_owner_residency_variants",
        )
        owner_source_paths = sorted(
            {spec.source_rel for spec in owner_runner.VARIANTS})
        owner_live_sources = {
            rel: freeze.sha256_file(root / rel) for rel in owner_source_paths
        }
        owner_variant_rows = []
        owner_variant_logs = []
        for spec in owner_runner.VARIANTS:
            original, variant = owner_runner.reconstruct_variant(root, spec)
            log = write_text(
                root,
                "evidence/owner-residency/" + spec.name + ".log",
                f"[COMPILE] iverilog -s {spec.test_name}\n"
                f"{spec.expected_marker}\n"
                f"[FAIL] {spec.test_name} errors=1\n"
                "[RESULT] FAIL status=1\n",
            )
            owner_variant_logs.append(log)
            owner_variant_rows.append({
                "name": spec.name,
                "purpose": spec.purpose,
                "source": spec.source_rel,
                "make_variable": spec.make_variable,
                "test_name": spec.test_name,
                "original_sha256": freeze.sha256_bytes(
                    original.encode("utf-8")),
                "variant_sha256": freeze.sha256_bytes(
                    variant.encode("utf-8")),
                "expected_marker": spec.expected_marker,
                "marker_observed": True,
                "old_same_edge_assertion_quiet": True,
                "compile_success": True,
                "dynamic_rejected": True,
                "make_returncode": 2,
                "log": {
                    "path": log.relative_to(root).as_posix(),
                    "sha256": freeze.sha256_file(log),
                },
            })
        self.owner_variant_summary = write_json(
            root,
            "evidence/owner-residency/summary.json",
            {
                "schema": (
                    "npc-rv64-irrevocable-owner-residency-"
                    "rtl-variants-v1"),
                "suite_run_id": (
                    "2026-07-23-rv64-v9n-"
                    "irrevocable-write-owner-residency"),
                "required": 2,
                "compile_success": 2,
                "dynamic_rejected": 2,
                "source_unchanged": True,
                "source_sha256_before": owner_live_sources,
                "source_sha256_after": owner_live_sources,
                "results": owner_variant_rows,
            },
        )
        owner_focused_specs = {
            "store": (
                "tb_v9n_sq_owner_residency",
                "[V9N-SQ-NEXT-EDGE-OWNER] "
                "launch=1 preserved=1 exact_terminal=1 PASS",
            ),
            "amo": (
                "tb_v9n_amo_owner_residency",
                "[V9N-AMO-NEXT-EDGE-OWNER] "
                "launch=1 preserved=1 exact_terminal=1 PASS",
            ),
        }
        owner_focused = {}
        owner_artifacts = {
            self.owner_variant_summary.relative_to(root).as_posix():
                freeze.sha256_file(self.owner_variant_summary),
        }
        for log in owner_variant_logs:
            owner_artifacts[log.relative_to(root).as_posix()] = (
                freeze.sha256_file(log))
        for name, (test_name, marker) in owner_focused_specs.items():
            log = write_text(
                root,
                f"evidence/owner-residency/{name}-focused.log",
                f"{marker}\n"
                f"[PASS] {test_name}\n"
                f"[RTL-DESIGN-ID] {self.design_id}\n"
                "[RESULT] PASS\n",
            )
            owner_artifacts[log.relative_to(root).as_posix()] = (
                freeze.sha256_file(log))
            owner_focused[name] = {
                "test": test_name,
                "marker": marker,
                "log": {
                    "path": log.relative_to(root).as_posix(),
                    "sha256": freeze.sha256_file(log),
                },
            }
        owner_provenance_paths = (
            self.owner_variant_runner,
            self.owner_sq_rtl,
            self.owner_amo_rtl,
            self.owner_top_rtl,
        )
        owner_provenance_files = {
            path.relative_to(root).as_posix(): freeze.sha256_file(path)
            for path in owner_provenance_paths
        }
        self.owner_result = write_json(
            root,
            "evidence/owner-residency/result.json",
            {
                "schema": (
                    "npc-rv64-irrevocable-owner-residency-evidence-v1"),
                "run_id": (
                    "2026-07-23-rv64-v9n-"
                    "irrevocable-write-owner-residency"),
                "status": "PASS",
                "design_id": self.design_id,
                "canonical_command": (
                    "make -C npc/rv64 check-memory-ordering"),
                "claim": {
                    "store_next_edge_owner_residency": True,
                    "amo_next_edge_owner_residency": True,
                    "canonical_top_global_flush_static_low": True,
                    "canonical_top_global_flush_binding":
                        "NpcCoreTop.u_ooo_core.flush_i=1'b0",
                },
                "focused": owner_focused,
                "mutation_audit": {
                    "required": 2,
                    "compile_success": 2,
                    "dynamic_rejected": 2,
                    "old_same_edge_assertion_quiet": 2,
                    "identities": sorted(
                        spec.name for spec in owner_runner.VARIANTS),
                    "summary": {
                        "path": self.owner_variant_summary.relative_to(
                            root).as_posix(),
                        "sha256": freeze.sha256_file(
                            self.owner_variant_summary),
                    },
                },
                "artifacts": owner_artifacts,
                "provenance": {
                    "files": owner_provenance_files,
                    "sha256": freeze.canonical_sha256(
                        owner_provenance_files),
                    "rtl_sha256": self.design_id.removeprefix("sha256:"),
                    "rtl_file_count": 4,
                },
                "ppa": "UNQUALIFIED",
                "promotion_eligible": False,
            },
        )
        self.owner_raw = write_text(
            root,
            "evidence/owner-residency/raw.log",
            f"design_id={self.design_id}\n"
            "store_next_edge_owner_residency=true\n"
            "amo_next_edge_owner_residency=true\n"
            "canonical_top_global_flush_static_low=true\n"
            "focused_passed=2\n"
            "compile_success_variants=2\n"
            "dynamic_rejected_variants=2\n"
            "old_same_edge_assertion_quiet=2\n"
            "[STORE-BRESP-G1-OWNER-RESIDENCY] PASS "
            "focused=2 variants=2 ppa=UNQUALIFIED\n",
        )
        exclusion_value = {
            "schema": "npc-rv64-architecture-debt-exclusion-v1",
            "debt_id": "OPTIONAL-G1",
            "design_id": self.design_id,
            "cohort_id": self.cohort_id,
            "rationale": "not implemented by the fixture cohort",
        }
        self.exclusion = write_json(
            root, "freeze/optional-g1-exclusion.json", exclusion_value)
        ledger = {
            "schema": freeze.LEDGER_SCHEMA,
            "revision": "test",
            "scope": "test full core",
            "design_id": self.design_id,
            "roadmap": {
                "path": self.roadmap.relative_to(root).as_posix(),
                "sha256": freeze.sha256_file(self.roadmap),
            },
            "entries": [
                {
                    "id": "STORE-BRESP-G1",
                    "priority": "P0",
                    "title": "precise store B-response lifecycle",
                    "status": "CLOSED",
                    "owner_paths": [self.rtl.relative_to(root).as_posix()],
                    "closure_requirements": [
                        "positive, counterexample and compile-success RTL mutation evidence"
                    ],
                    "current_design_bound": True,
                    "design_id": self.design_id,
                    "canonical_command": "make -C npc/rv64 check-memory-ordering",
                    "coverage": {
                        "positive": True,
                        "counterexample": True,
                        "compile_success_rtl_mutation": True,
                    },
                    "evidence": [
                        artifact(root, self.arch_evidence,
                                 "architecture_directed_suite"),
                        artifact(root, self.debt_log, "raw_log"),
                        artifact(
                            root, self.owner_result,
                            "irrevocable_owner_residency_result"),
                        artifact(
                            root, self.owner_raw,
                            "irrevocable_owner_residency_raw"),
                    ],
                },
                {
                    "id": "OPTIONAL-G1",
                    "priority": "P1",
                    "title": "fixture optional interface",
                    "status": "EXCLUDED_BY_COHORT",
                    "owner_paths": [self.module_spec.relative_to(root).as_posix()],
                    "closure_requirements": ["exact cohort exclusion contract"],
                    "scope_rationale": "not implemented by the fixture cohort",
                    "scope_contract": {
                        "path": self.exclusion.relative_to(root).as_posix(),
                        "sha256": freeze.sha256_file(self.exclusion),
                    },
                },
            ],
        }
        self.ledger = write_json(
            root, "npc/rv64/design/arch/architecture-debt-ledger.json", ledger)

        self.census_log = write_text(
            root,
            "evidence/census-dynamic.log",
            f"design_id={self.design_id}\n"
            "V8L-INTIQ-DEATH-EDGE\n"
            "V8L-FINITE-GENERATION-WRAP\n"
            "V8L-TRANSIENT-HOLDER-CENSUS\n"
            "V8L-MEM-HANDOFF-BACKPRESSURE\n"
            "V8L-MEM-INDIRECT-TRACKER\n",
        )
        self.census_mutations = write_json(
            root,
            "evidence/census-mutations.json",
            {
                "schema": "npc-rv64-holder-lifecycle-mutations-v1",
                "design_id": self.design_id,
                "compile_success": 3,
                "rejected": 3,
            },
        )
        census = {
            "schema_version": freeze.CENSUS_SCHEMA,
            "design_id": self.design_id,
            "scope": {
                "field_level_complete": True,
                "instance_graph_complete": True,
                "semantic_complete": True,
            },
            "status_ledger": {
                "current_production_holder_census": "GREEN",
                "global_no_live_reuse": "GREEN",
                "whole_architecture": "GREEN",
                "ppa_promotion": "UNPROMOTED",
            },
            "freeze_evidence": {
                "canonical_command":
                    "make -C npc/rv64 check-global-producer-no-live-reuse",
                "dynamic_log": artifact(
                    root, self.census_log, "holder_lifecycle_log"),
                "mutation_summary": artifact(
                    root, self.census_mutations, "mutation_summary"),
            },
        }
        self.census = write_json(root, "evidence/census.json", census)

        self._build_frozen_inputs()
        self._build_functional_aggregate()
        self.run_parameters = {
            "top": "NpcTop",
            "clock_port": "clk",
            "period_ns": 5.0,
            "synthesis_seed": 0,
            "threads": 1,
        }
        self.cohort = write_json(
            root,
            "freeze/cohort.json",
            {
                "schema": freeze.COHORT_SCHEMA,
                "design_id": self.design_id,
                "cohort_id": self.cohort_id,
                "freeze_inputs": self.freeze_inputs,
                "run_parameters": self.run_parameters,
            },
        )
        self.candidate_value = {
            "schema": freeze.CANDIDATE_SCHEMA,
            "design_id": self.design_id,
            "scope": {
                "cohort_id": self.cohort_id,
                "product": "local RV64 processor RTL fixture",
                "excluded_debt_ids": ["OPTIONAL-G1"],
            },
            "artifacts": {
                "debt_ledger": self.ledger.relative_to(root).as_posix(),
                "architecture_evidence": self.arch_evidence.relative_to(root).as_posix(),
                "architecture_result": self.arch_result.relative_to(root).as_posix(),
                "holder_census": self.census.relative_to(root).as_posix(),
                "functional_aggregate": self.functional.relative_to(root).as_posix(),
                "cohort_inventory": self.cohort.relative_to(root).as_posix(),
            },
            "freeze_inputs": self.freeze_inputs,
            "run_parameters": self.run_parameters,
            "claim": {
                "architecture_freeze": "ARCH_STABLE",
                "ppa": "UNQUALIFIED",
                "promotion_eligible": False,
                "canonical": None,
                "architecture_feasible_seed": None,
            },
        }
        self.candidate = self.write_candidate()

    def close(self) -> None:
        os.environ["PATH"] = self.old_path

    def _write_architecture_evaluator(self) -> None:
        write_text(
            self.root,
            "npc/rv64/eval/ppa/tools/architecture_hard_gates.py",
            '''import hashlib\nimport json\nimport pathlib\n\n'''
            '''GATE_TEST = {"DI-1":"frontend_ii1","DI-2":"width_continuity",'''
            '''"DI-3":"pair_matrix","DI-4":"no_static_lane_semantics",'''
            '''"DI-5":"dual_memory_issue","OOO-1":"true_ooo_long_latency",'''
            '''"OOO-2":"selective_scheduling","OOO-3":"memory_ordering",'''
            '''"OOO-4":"speculation_recovery"}\n'''
            '''def digest(path):\n    return hashlib.sha256(path.read_bytes()).hexdigest()\n'''
            '''def canonical(value):\n    data=json.dumps(value,allow_nan=False,sort_keys=True,separators=(",",":")).encode()\n    return hashlib.sha256(data).hexdigest()\n'''
            '''def rtl_binding(root):\n    suffixes={".v",".sv",".vh",".svh",".mk"}\n    files=sorted(p for p in (root/"npc/rv64/vsrc").rglob("*") if p.is_file() and p.suffix in suffixes)\n    entries={p.relative_to(root).as_posix():digest(p) for p in files}\n    if not entries: raise ValueError("empty fixture RTL")\n    return canonical(entries),entries\n'''
            '''def evaluate(root,evidence_path):\n    source_sha,files=rtl_binding(root)\n    evidence=json.loads(evidence_path.read_text())\n    tests=evidence.get("tests",{})\n    ok=(evidence.get("schema")=="npc-rv64-architecture-directed-suite-v2" and evidence.get("design_id")==f"sha256:{source_sha}" and set(tests)==set(GATE_TEST.values()) and all(isinstance(v,dict) and v.get("status")=="PASS" for v in tests.values()))\n    gates={}\n    for gate,test in GATE_TEST.items():\n        passed=ok and tests.get(test,{}).get("status")=="PASS"\n        gates[gate]={"status":"GREEN" if passed else "RED","evidence_test":test,"checks":[{"check_id":"fixture.recomputed","passed":passed,"detail":"derived from current RTL and evidence"}]}\n    contract=root/"npc/rv64/design/arch/rv64-architecture-ppa-contract.md"\n    return {"schema":"npc-rv64-architecture-hard-gates-result-v2","overall_status":"GREEN" if ok else "RED","exit_code":0 if ok else 1,"contract":{"path":"npc/rv64/design/arch/rv64-architecture-ppa-contract.md","sha256":digest(contract)},"rtl_source_set":{"design_id":f"sha256:{source_sha}","sha256":source_sha,"file_count":len(files),"files":files},"evidence_errors":[] if ok else ["fixture evidence mismatch"],"gates":gates}\n''',
        )

    def _write_census_evaluator(self) -> None:
        write_text(
            self.root,
            "npc/rv64/eval/ppa/tools/producer_holder_census.py",
            '''import hashlib\nimport json\n'''
            '''def digest(path):\n    return hashlib.sha256(path.read_bytes()).hexdigest()\n'''
            '''def audit(root,manifest_path,vsrc):\n    value=json.loads(manifest_path.read_text())\n    files={p.relative_to(root).as_posix():digest(p) for p in sorted(vsrc.rglob("*")) if p.is_file()}\n    return {"status":"PASS" if files else "FAIL","scope":value.get("scope"),"status_ledger":value.get("status_ledger"),"hashes":{"manifest_sha256":digest(manifest_path),"source_files":files}}\n''',
        )

    def _build_frozen_inputs(self) -> None:
        fakebin = self.root / "freeze/fakebin"
        fakebin.mkdir(parents=True)
        os.environ["PATH"] = f"{fakebin}:{self.old_path}"
        tool_records: dict[str, dict[str, str]] = {}
        for name, args in freeze.TOOL_VERSION_ARGS.items():
            executable = write_text(
                self.root,
                f"freeze/fakebin/{name}",
                "#!/bin/sh\nprintf '%s test-1.0\\n' \"$(basename \"$0\")\"\n",
            )
            executable.chmod(0o755)
            resolved = executable.resolve()
            completed = subprocess.run(
                [str(resolved), *args], check=False, capture_output=True)
            self.assert_fixture(completed.returncode == 0, f"fake tool {name}")
            tool_records[name] = {
                "path": resolved.as_posix(),
                "version": f"{name} test-1.0",
                "version_output_sha256": freeze.sha256_bytes(
                    completed.stdout + completed.stderr),
                "executable_sha256": freeze.sha256_file(resolved),
            }
        self.tool_manifest = write_json(
            self.root,
            "freeze/tool-versions.json",
            {"schema": "npc-rv64-tool-versions-v1", "tools": tool_records},
        )
        self.liberty = write_text(
            self.root, "freeze/stdcells.lib", "library(test) {}\n")
        self.macro_manifest = write_json(
            self.root,
            "freeze/macros.json",
            {
                "schema": "npc-rv64-macro-inventory-v1",
                "macros": [{
                    "name": "FixtureMacro",
                    "liberty_path": self.liberty.relative_to(self.root).as_posix(),
                    "qualification": "placeholder",
                }],
            },
        )
        self.constraint = write_text(
            self.root,
            "freeze/top.sdc",
            "create_clock -name clk -period 5 [get_ports clk]\n",
        )
        self.official_image_artifacts = [
            artifact(
                self.root,
                write_text(
                    self.root,
                    f"freeze/images/official_{index:03d}.bin",
                    f"official RV64 program {index:03d}\n",
                ),
                "program_image",
            )
            for index in range(177)
        ]
        self.am_image_artifacts = [
            artifact(
                self.root,
                write_text(
                    self.root,
                    f"freeze/images/am_{index:03d}.bin",
                    f"AM RV64 program {index:03d}\n",
                ),
                "program_image",
            )
            for index in range(59)
        ]
        self.coremark_image = artifact(
            self.root,
            write_text(
                self.root, "freeze/images/coremark.bin",
                "CoreMark RV64 program\n"),
            "program_image",
        )
        self.dhrystone_image = artifact(
            self.root,
            write_text(
                self.root, "freeze/images/dhrystone.bin",
                "Dhrystone RV64 program\n"),
            "program_image",
        )
        self.simulator = write_text(
            self.root, "freeze/simv", "#!/bin/sh\nexit 0\n")
        self.simulator.chmod(0o755)
        self.reference = write_text(
            self.root, "freeze/reference-model.so", "#!/bin/sh\nexit 0\n")
        self.reference.chmod(0o755)
        self.reference_config = write_text(
            self.root, "freeze/reference.config", "CONFIG_RV64=y\n")
        self.reference_source = write_text(
            self.root, "freeze/reference-model.c", "/* RV64 reference */\n")
        self.comparison_source = write_text(
            self.root, "freeze/difftest-policy.cpp", "/* compare RV64 state */\n")
        self.reference_profile = write_json(
            self.root,
            "freeze/difftest-reference-profile.json",
            {
                "schema": freeze.DIFFTEST_PROFILE_SCHEMA,
                "reference_sha256": freeze.sha256_file(self.reference),
                "isa": "RV64IMAFDC_Zicsr_Zifencei",
                "reset_pc": "0x0000000080000000",
                "program_load_address": "0x0000000080000000",
                "memory_map": {
                    "pmem_base": "0x0000000080000000",
                    "pmem_size": "128MiB",
                    "mmio_model": "local NPC DiffTest skip/synchronize policy",
                },
                "comparison_policy": [
                    "compare committed RV64 architectural state",
                    "apply current local MMIO synchronization rules",
                ],
                "source_artifacts": [
                    artifact(
                        self.root, self.reference_config, "reference_config"),
                    artifact(
                        self.root, self.reference_source, "reference_model_source"),
                    artifact(
                        self.root, self.comparison_source,
                        "comparison_policy_source"),
                ],
            },
        )

        self.freeze_inputs = {
            "config": [artifact(self.root, self.config, "kconfig")],
            "generated_headers": [
                artifact(self.root, self.header, "generated_header")
            ],
            "filelists": [
                artifact(self.root, self.filelist, "rtl_filelist"),
                artifact(self.root, self.makefile, "test_inventory"),
            ],
            "specifications": [
                artifact(self.root, self.roadmap, "architecture_spec"),
                artifact(self.root, self.arch_contract, "architecture_spec"),
                artifact(self.root, self.module_spec, "module_spec"),
            ],
            "test_sources": [
                artifact(self.root, self.test_source, "module_test_source"),
                artifact(self.root, self.test_common, "test_common"),
                artifact(self.root, self.test_runner, "test_runner"),
            ],
            "tool_versions": [
                artifact(self.root, self.tool_manifest, "tool_version_manifest")
            ],
            "liberty": [
                artifact(self.root, self.liberty, "standard_cell_liberty")
            ],
            "macros": [
                artifact(self.root, self.macro_manifest, "macro_inventory")
            ],
            "constraints": [
                artifact(self.root, self.constraint, "primary_sdc")
            ],
            "images": [
                *self.official_image_artifacts,
                *self.am_image_artifacts,
                self.coremark_image,
                self.dhrystone_image,
            ],
            "binaries": [
                artifact(self.root, self.simulator, "simulator_binary"),
                artifact(self.root, self.reference, "reference_model_binary"),
            ],
            "workflow": [
                artifact(
                    self.root,
                    self.root / relative,
                    (
                        "audit_checker"
                        if relative.endswith("tools/arch_stable_freeze.py") else
                        "canonical_architecture_checker"
                        if relative.endswith("tools/architecture_hard_gates.py") else
                        "holder_census_checker"
                        if relative.endswith("tools/producer_holder_census.py") else
                        "audit_runner"
                        if relative.endswith("run-arch-stable-audit.sh") else
                        "audit_test"
                        if relative.endswith("test_arch_stable_freeze.py") else
                        "json_schema"
                    ),
                )
                for relative in freeze.WORKFLOW_BINDING_PATHS
            ],
        }

    @staticmethod
    def assert_fixture(condition: bool, detail: str) -> None:
        if not condition:
            raise RuntimeError(f"fixture construction failed: {detail}")

    def _log_header(self, command: str, image: dict | None = None) -> str:
        lines = [
            f"design_id={self.design_id}",
            f"cohort_id={self.cohort_id}",
            f"program_image_canonicalization={freeze.PROGRAM_IMAGE_CANONICALIZATION}",
            f"simulator_sha256={self.freeze_inputs['binaries'][0]['sha256']}",
            f"config_sha256={self.freeze_inputs['config'][0]['sha256']}",
            f"command_sha256={freeze.sha256_bytes(command.encode('utf-8'))}",
        ]
        if image is not None:
            lines.append(f"image_sha256={image['sha256']}")
        return "\n".join(lines) + "\n"

    def _build_functional_aggregate(self) -> None:
        simulator = self.freeze_inputs["binaries"][0]
        configuration = self.freeze_inputs["config"][0]

        build_command = "make -C npc/rv64 default"
        build_log = write_text(
            self.root,
            "evidence/simulator-build.log",
            self._log_header(build_command)
            + "return_code=0\n[RESULT] PASS\n",
        )
        build = {
            "command": build_command,
            "return_code": 0,
            "log": artifact(
                self.root, build_log, "simulator_build_log"),
        }

        module_command = "make -C npc/rv64/testbench run"
        module_log = write_text(
            self.root,
            "evidence/module/tb_a.log",
            self._log_header(module_command)
            + "test_id=tb_a\ncompile_rc=0\nsimulation_rc=0\n[RESULT] PASS\n",
        )
        module = {
            "command": module_command,
            "required": 1,
            "passed": 1,
            "failed": 0,
            "tests": [{
                "test_id": "tb_a",
                "compile_rc": 0,
                "simulation_rc": 0,
                "pass_markers": 1,
                "fail_markers": 0,
                "log": artifact(self.root, module_log, "module_test_log"),
            }],
        }

        def suite_images(
            label: str,
            image_artifacts: list[dict[str, str]],
            command: str,
            require_difftest: bool,
        ) -> tuple[list[str], list[dict], str, str]:
            inventory = [
                f"{label}_{index:03d}" for index in range(len(image_artifacts))
            ]
            images = []
            for test_id, image in zip(
                inventory, image_artifacts, strict=True
            ):
                reference_markers = ""
                if require_difftest:
                    reference_markers = (
                        f"difftest_reference_sha256={reference['sha256']}\n"
                        f"difftest_reference_profile_sha256="
                        f"{reference_profile['sha256']}\n"
                    )
                test_log = write_text(
                    self.root,
                    f"evidence/{label}-tests/{test_id}.log",
                    self._log_header(command)
                    + f"suite={label}\n"
                    + f"test_id={test_id}\n"
                    + f"image_sha256={image['sha256']}\n"
                    + "load_address=0x0000000080000000\n"
                    + "entry_pc=0x0000000080000000\n"
                    + reference_markers
                    + "[RESULT] PASS\n",
                )
                images.append({
                    "test_id": test_id,
                    "load_address": "0x0000000080000000",
                    "entry_pc": "0x0000000080000000",
                    "image": image,
                    "log": artifact(
                        self.root, test_log,
                        "am_test_log" if require_difftest
                        else "official_test_log"),
                })
            inventory_sha = freeze.canonical_sha256({
                "schema": "npc-rv64-test-inventory-v1",
                "suite": label,
                "test_ids": sorted(inventory),
            })
            identity_records = [
                {
                    "suite": label,
                    "test_id": item["test_id"],
                    "image_sha256": item["image"]["sha256"],
                    "load_address": item["load_address"],
                    "entry_pc": item["entry_pc"],
                }
                for item in images
            ]
            image_set_sha = freeze.canonical_sha256({
                "schema": freeze.PROGRAM_IMAGE_CANONICALIZATION,
                "suite": label,
                "images": sorted(
                    identity_records, key=lambda item: item["test_id"]),
            })
            return inventory, images, inventory_sha, image_set_sha

        reference = self.freeze_inputs["binaries"][1]
        reference_profile = artifact(
            self.root, self.reference_profile, "reference_model_profile")

        def suite(
            label: str,
            count: int,
            command: str,
            kind: str,
            image_artifacts: list[dict[str, str]],
            *,
            difftest_enabled: bool | None = None,
        ) -> dict:
            inventory, images, inventory_sha, image_set_sha = suite_images(
                label, image_artifacts, command,
                difftest_enabled is True)
            self.assert_fixture(len(inventory) == count, f"{label} image count")
            body = "".join(f"[TEST] {test_id} PASS\n" for test_id in inventory)
            reference_markers = ""
            if difftest_enabled:
                reference_markers = (
                    f"difftest_reference_sha256={reference['sha256']}\n"
                    f"difftest_reference_profile_sha256="
                    f"{reference_profile['sha256']}\n"
                )
            log = write_text(
                self.root,
                f"evidence/{label}.log",
                self._log_header(command)
                + f"suite={label}\n"
                + f"inventory_sha256={inventory_sha}\n"
                + f"image_set_sha256={image_set_sha}\n"
                + reference_markers
                + body
                + "[SUITE] PASS\n",
            )
            value = {
                "command": command,
                "required": count,
                "passed": count,
                "failed": 0,
                "inventory": inventory,
                "inventory_sha256": inventory_sha,
                "image_set_sha256": image_set_sha,
                "images": images,
                "log": artifact(self.root, log, kind),
            }
            if difftest_enabled is not None:
                value["difftest_enabled"] = difftest_enabled
            return value

        official = suite(
            "official", 177, "run local RV64 official suite",
            "official_suite_log", self.official_image_artifacts)
        am = suite(
            "am", 59, "run local RV64 AM suite with DiffTest",
            "am_suite_log", self.am_image_artifacts,
            difftest_enabled=True)

        diff_command = "run local RV64 architectural DiffTest"
        diff_log = write_text(
            self.root,
            "evidence/difftest.log",
            self._log_header(diff_command)
            + "suite=am\n"
            + f"image_set_sha256={am['image_set_sha256']}\n"
            + f"difftest_reference_sha256={reference['sha256']}\n"
            + f"difftest_reference_profile_sha256="
            + f"{reference_profile['sha256']}\n"
            + "mismatches=0\n[RESULT] PASS\n",
        )
        difftest = {
            "command": diff_command,
            "applicable": True,
            "mismatches": 0,
            "suite": "am",
            "image_set_sha256": am["image_set_sha256"],
            "reference": reference,
            "reference_profile": reference_profile,
            "log": artifact(self.root, diff_log, "difftest_log"),
        }

        def benchmark(
            name: str,
            command: str,
            image: dict[str, str],
            metrics: dict,
        ) -> dict:
            metric_text = "".join(f"{key}={value}\n" for key, value in metrics.items())
            log = write_text(
                self.root,
                f"evidence/{name}.log",
                self._log_header(command, image)
                + "return_code=0\n" + metric_text + "[RESULT] PASS\n",
            )
            return {
                "command": command,
                "return_code": 0,
                "image": image,
                "log": artifact(self.root, log, "benchmark_log"),
                **metrics,
            }

        functional = {
            "schema": freeze.FUNCTIONAL_SCHEMA,
            "design_id": self.design_id,
            "cohort_id": self.cohort_id,
            "program_image_canonicalization":
                freeze.PROGRAM_IMAGE_CANONICALIZATION,
            "simulator": simulator,
            "configuration": configuration,
            "build": build,
            "module": module,
            "official": official,
            "am": am,
            "difftest": difftest,
            "benchmarks": {
                "coremark": benchmark(
                    "coremark", "run local RV64 CoreMark", self.coremark_image,
                    {"iterations": 10, "crc": "0xfcaf", "good_traps": 1}),
                "dhrystone": benchmark(
                    "dhrystone", "run local RV64 Dhrystone",
                    self.dhrystone_image,
                    {"runs": 10000, "good_traps": 1}),
            },
        }
        self.functional = write_json(
            self.root, "evidence/functional.json", functional)

    def write_candidate(self) -> pathlib.Path:
        self.candidate = write_json(
            self.root, "freeze/candidate.json", self.candidate_value)
        return self.candidate

    def audit(self) -> dict:
        self.write_candidate()
        return freeze.evaluate_candidate(
            root=self.root,
            candidate_path=self.candidate,
            generated_at_utc="2026-07-21T00:00:00+00:00",
        )


class PureFunctionTests(unittest.TestCase):
    def test_debt_markers_are_exact_and_unique(self) -> None:
        markers, errors = freeze.parse_debt_markers(
            "<!-- ARCH-DEBT-P0: A,B -->\n<!-- ARCH-DEBT-P1: C -->\n")
        self.assertEqual(markers, {"A": "P0", "B": "P0", "C": "P1"})
        self.assertEqual(errors, [])
        _, errors = freeze.parse_debt_markers(
            "<!-- ARCH-DEBT-P0: A -->\n<!-- ARCH-DEBT-P1: A -->\n")
        self.assertTrue(any("duplicate" in error for error in errors))

    def test_required_tests_are_dynamic_and_reject_duplicates(self) -> None:
        tests, errors = freeze.parse_required_tests(
            "TESTS := \\\n              tb_a \\\n              tb_b\n")
        self.assertEqual(tests, ["tb_a", "tb_b"])
        self.assertEqual(errors, [])
        _, errors = freeze.parse_required_tests("TESTS := tb_a tb_a\n")
        self.assertTrue(any("duplicate" in error for error in errors))

    def test_ppa_claim_cannot_be_promoted_by_arch_freeze(self) -> None:
        checks, blockers = freeze.validate_claim({
            "architecture_freeze": "ARCH_STABLE",
            "ppa": "QUALIFIED",
            "promotion_eligible": True,
            "canonical": "candidate.json",
            "architecture_feasible_seed": "candidate.json",
        })
        self.assertEqual(checks[0]["status"], "GAP")
        self.assertTrue(blockers)


class EndToEndFixtureTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.root = pathlib.Path(self.temporary.name)
        self.fixture = GreenFixture(self.root)

    def tearDown(self) -> None:
        self.fixture.close()
        self.temporary.cleanup()

    def assert_gap(self, result: dict, fragment: str) -> None:
        self.assertEqual(result["architecture_freeze"], "GAP")
        self.assertTrue(
            any(fragment in blocker for blocker in result["blockers"]),
            result["blockers"],
        )

    def rewrite_ledger(self, value: dict) -> None:
        write_json(
            self.root,
            self.fixture.ledger.relative_to(self.root).as_posix(),
            value,
        )

    def rewrite_functional(self, value: dict) -> None:
        write_json(
            self.root,
            self.fixture.functional.relative_to(self.root).as_posix(),
            value,
        )

    def test_complete_fixture_can_issue_arch_stable_without_ppa_promotion(self) -> None:
        result = self.fixture.audit()
        self.assertEqual(result["architecture_freeze"], "ARCH_STABLE")
        self.assertEqual(result["blockers"], [])
        self.assertEqual(result["ppa"], "UNQUALIFIED")
        self.assertFalse(result["promotion_eligible"])

    def test_cli_require_stable_accepts_complete_fixture(self) -> None:
        result_path = self.root / "freeze/cli-result.json"
        completed = subprocess.run(
            [
                sys.executable, str(TOOL), "audit", str(self.fixture.candidate),
                "--output", str(result_path), "--require-stable",
            ],
            cwd=self.root,
            check=False,
            capture_output=True,
            text=True,
        )
        self.assertEqual(completed.returncode, 0, completed.stderr + completed.stdout)
        verified = subprocess.run(
            [sys.executable, str(TOOL), "verify", str(result_path),
             "--require-stable"],
            cwd=self.root,
            check=False,
            capture_output=True,
            text=True,
        )
        self.assertEqual(verified.returncode, 0, verified.stderr + verified.stdout)

    def test_new_roadmap_debt_id_invalidates_ledger(self) -> None:
        self.fixture.roadmap.write_text(
            "<!-- ARCH-DEBT-P0: STORE-BRESP-G1,P0-NEW -->\n"
            "<!-- ARCH-DEBT-P1: OPTIONAL-G1 -->\n",
            encoding="utf-8",
        )
        ledger = json.loads(self.fixture.ledger.read_text(encoding="utf-8"))
        ledger["roadmap"]["sha256"] = freeze.sha256_file(self.fixture.roadmap)
        self.rewrite_ledger(ledger)
        self.assert_gap(self.fixture.audit(), "debt.entries.exact_membership")

    def test_closed_debt_without_rtl_mutation_coverage_is_rejected(self) -> None:
        ledger = json.loads(self.fixture.ledger.read_text(encoding="utf-8"))
        ledger["entries"][0]["coverage"]["compile_success_rtl_mutation"] = False
        self.rewrite_ledger(ledger)
        self.assert_gap(self.fixture.audit(), "debt.STORE-BRESP-G1.closed_binding")

    def test_owner_residency_variant_count_is_semantically_rejected(self) -> None:
        value = json.loads(self.fixture.owner_result.read_text(encoding="utf-8"))
        value["mutation_audit"]["dynamic_rejected"] = 1
        write_json(
            self.root,
            self.fixture.owner_result.relative_to(self.root).as_posix(),
            value,
        )
        ledger = json.loads(self.fixture.ledger.read_text(encoding="utf-8"))
        entry = ledger["entries"][0]
        for record in entry["evidence"]:
            if record["kind"] == "irrevocable_owner_residency_result":
                record["sha256"] = freeze.sha256_file(self.fixture.owner_result)
        self.rewrite_ledger(ledger)
        self.assert_gap(
            self.fixture.audit(), "debt.STORE-BRESP-G1.semantic_evidence")

    def test_arbitrary_closed_debt_has_no_semantic_validator(self) -> None:
        ledger = json.loads(self.fixture.ledger.read_text(encoding="utf-8"))
        entry = ledger["entries"][1]
        entry.pop("scope_rationale")
        entry.pop("scope_contract")
        entry.update({
            "status": "CLOSED",
            "current_design_bound": True,
            "design_id": self.fixture.design_id,
            "canonical_command": "make fixture",
            "coverage": {
                "positive": True,
                "counterexample": True,
                "compile_success_rtl_mutation": True,
            },
            "evidence": [artifact(self.root, self.fixture.focused_log, "raw_log")],
        })
        self.rewrite_ledger(ledger)
        self.fixture.candidate_value["scope"]["excluded_debt_ids"] = []
        self.assert_gap(self.fixture.audit(), "debt.OPTIONAL-G1.semantic_evidence")

    def test_exclusion_contract_must_bind_current_cohort(self) -> None:
        value = json.loads(self.fixture.exclusion.read_text(encoding="utf-8"))
        value["cohort_id"] = "different-cohort"
        write_json(
            self.root,
            self.fixture.exclusion.relative_to(self.root).as_posix(),
            value,
        )
        ledger = json.loads(self.fixture.ledger.read_text(encoding="utf-8"))
        ledger["entries"][1]["scope_contract"]["sha256"] = freeze.sha256_file(
            self.fixture.exclusion)
        self.rewrite_ledger(ledger)
        self.assert_gap(self.fixture.audit(), "debt.OPTIONAL-G1.cohort_exclusion")

    def test_module_inventory_addition_rejects_old_aggregate_and_freeze_set(self) -> None:
        self.fixture.makefile.write_text("TESTS := tb_a tb_b\n", encoding="utf-8")
        write_text(
            self.root, "npc/rv64/testbench/tests/tb_b.sv",
            "module tb_b; endmodule\n")
        result = self.fixture.audit()
        self.assert_gap(result, "functional.module_dynamic_inventory")
        self.assertTrue(any(
            "freeze_inputs.test_sources.exact_membership" in blocker
            for blocker in result["blockers"]
        ))

    def test_functional_module_order_is_not_semantic(self) -> None:
        value = json.loads(self.fixture.functional.read_text(encoding="utf-8"))
        value["module"]["tests"] = list(reversed(value["module"]["tests"]))
        self.rewrite_functional(value)
        result = self.fixture.audit()
        self.assertEqual(result["architecture_freeze"], "ARCH_STABLE", result["blockers"])

    def test_module_pass_without_bound_log_is_rejected(self) -> None:
        value = json.loads(self.fixture.functional.read_text(encoding="utf-8"))
        value["module"]["tests"][0]["log"]["sha256"] = "0" * 64
        self.rewrite_functional(value)
        self.assert_gap(self.fixture.audit(), "functional.module_dynamic_inventory")

    def test_zero_byte_module_log_is_rejected(self) -> None:
        value = json.loads(self.fixture.functional.read_text(encoding="utf-8"))
        relative = value["module"]["tests"][0]["log"]["path"]
        log = self.root / relative
        log.write_text("", encoding="utf-8")
        value["module"]["tests"][0]["log"]["sha256"] = freeze.sha256_file(log)
        self.rewrite_functional(value)
        self.assert_gap(self.fixture.audit(), "functional.module_dynamic_inventory")

    def test_duplicate_functional_pass_marker_is_rejected(self) -> None:
        value = json.loads(self.fixture.functional.read_text(encoding="utf-8"))
        relative = value["module"]["tests"][0]["log"]["path"]
        log = self.root / relative
        log.write_text(
            log.read_text(encoding="utf-8") + "[RESULT] PASS\n",
            encoding="utf-8",
        )
        value["module"]["tests"][0]["log"]["sha256"] = freeze.sha256_file(log)
        value["module"]["tests"][0]["pass_markers"] = 2
        self.rewrite_functional(value)
        self.assert_gap(self.fixture.audit(), "functional.module_dynamic_inventory")

    def test_two_module_records_cannot_reuse_one_log_identity(self) -> None:
        value = json.loads(self.fixture.functional.read_text(encoding="utf-8"))
        command = value["module"]["command"]
        shared = write_text(
            self.root,
            "evidence/module/shared.log",
            self.fixture._log_header(command)
            + "test_id=tb_a\ntest_id=tb_b\ncompile_rc=0\n"
            "simulation_rc=0\n[RESULT] PASS\n",
        )
        first = value["module"]["tests"][0]
        first["log"] = artifact(self.root, shared, "module_test_log")
        second = json.loads(json.dumps(first))
        second["test_id"] = "tb_b"
        value["module"].update({
            "required": 2,
            "passed": 2,
            "tests": [first, second],
        })
        checks, blockers, _ = freeze.validate_functional(
            root=self.root,
            functional=value,
            expected_design_id=self.fixture.design_id,
            cohort_id=self.fixture.cohort_id,
            required_tests=["tb_a", "tb_b"],
            freeze_groups=self.fixture.freeze_inputs,
        )
        self.assertTrue(blockers)
        module_check = next(
            item for item in checks
            if item["check_id"] == "functional.module_dynamic_inventory")
        self.assertEqual(module_check["status"], "GAP")
        self.assertIn("reuses file identity", module_check["detail"])

    def test_benchmark_metrics_are_log_bound(self) -> None:
        value = json.loads(self.fixture.functional.read_text(encoding="utf-8"))
        value["benchmarks"]["coremark"]["crc"] = "0x0000"
        self.rewrite_functional(value)
        self.assert_gap(self.fixture.audit(), "functional.benchmarks")

    def test_v1_functional_aggregate_cannot_satisfy_v2_closure(self) -> None:
        value = json.loads(self.fixture.functional.read_text(encoding="utf-8"))
        value["schema"] = "npc-rv64-functional-aggregate-v1"
        self.rewrite_functional(value)
        result = self.fixture.audit()
        self.assert_gap(result, "functional.json_schema")
        self.assert_gap(result, "functional.schema_design_cohort")

    def test_official_image_swap_is_rejected_even_when_hash_set_is_unchanged(
        self,
    ) -> None:
        value = json.loads(self.fixture.functional.read_text(encoding="utf-8"))
        images = value["official"]["images"]
        images[0]["image"], images[1]["image"] = (
            images[1]["image"], images[0]["image"])
        self.rewrite_functional(value)
        self.assert_gap(self.fixture.audit(), "functional.official")

    def test_two_suite_ids_cannot_reuse_one_program_image_identity(self) -> None:
        value = json.loads(self.fixture.functional.read_text(encoding="utf-8"))
        value["official"]["images"][1]["image"] = json.loads(json.dumps(
            value["official"]["images"][0]["image"]))
        self.rewrite_functional(value)
        result = self.fixture.audit()
        self.assert_gap(result, "functional.official")
        check = next(
            item for item in result["checks"]
            if item["check_id"] == "functional.official")
        self.assertIn("reuses file identity", check["detail"])

    def test_difftest_must_use_the_exact_am_program_image_map(self) -> None:
        value = json.loads(self.fixture.functional.read_text(encoding="utf-8"))
        value["difftest"]["image_set_sha256"] = (
            value["official"]["image_set_sha256"])
        self.rewrite_functional(value)
        self.assert_gap(self.fixture.audit(), "functional.difftest")

    def test_different_architecture_design_id_is_rejected(self) -> None:
        evidence = json.loads(self.fixture.arch_evidence.read_text(encoding="utf-8"))
        evidence["design_id"] = "sha256:" + "e" * 64
        write_json(
            self.root,
            self.fixture.arch_evidence.relative_to(self.root).as_posix(),
            evidence,
        )
        self.assert_gap(self.fixture.audit(), "architecture.directed_suite")

    def test_empty_architecture_source_map_is_rejected(self) -> None:
        result_value = json.loads(self.fixture.arch_result.read_text(encoding="utf-8"))
        result_value["rtl_source_set"]["files"] = {}
        result_value["rtl_source_set"]["file_count"] = 0
        write_json(
            self.root,
            self.fixture.arch_result.relative_to(self.root).as_posix(),
            result_value,
        )
        self.assert_gap(self.fixture.audit(), "architecture.hard_gates")

    def test_simplified_self_reported_green_gates_are_rejected(self) -> None:
        result_value = json.loads(self.fixture.arch_result.read_text(encoding="utf-8"))
        result_value["gates"] = {
            gate: {"status": "GREEN"} for gate in sorted(freeze.GATE_IDS)
        }
        write_json(
            self.root,
            self.fixture.arch_result.relative_to(self.root).as_posix(),
            result_value,
        )
        self.assert_gap(self.fixture.audit(), "architecture.canonical_reevaluation")

    def test_rtl_source_drift_is_recomputed(self) -> None:
        self.fixture.rtl.write_text(
            "module core; wire changed; endmodule\n", encoding="utf-8")
        result = self.fixture.audit()
        self.assert_gap(result, "architecture.rtl_source_drift")
        self.assertTrue(any(
            "architecture.canonical_reevaluation" in blocker
            for blocker in result["blockers"]
        ))

    def test_incomplete_census_is_rejected(self) -> None:
        census = json.loads(self.fixture.census.read_text(encoding="utf-8"))
        census["scope"]["instance_graph_complete"] = False
        write_json(
            self.root,
            self.fixture.census.relative_to(self.root).as_posix(),
            census,
        )
        self.assert_gap(self.fixture.audit(), "census.full_core_complete")

    def test_missing_constraint_is_rejected(self) -> None:
        self.fixture.candidate_value["freeze_inputs"]["constraints"] = []
        self.assert_gap(self.fixture.audit(), "freeze_inputs.constraints.artifacts")

    def test_workspace_escape_is_rejected(self) -> None:
        self.fixture.candidate_value["freeze_inputs"]["constraints"] = [{
            "kind": "primary_sdc", "path": "../outside.sdc", "sha256": "0" * 64,
        }]
        self.assert_gap(self.fixture.audit(), "freeze_inputs.constraints.artifacts")

    def test_cross_group_artifact_reuse_is_rejected(self) -> None:
        reused = dict(self.fixture.candidate_value["freeze_inputs"]["config"][0])
        reused["kind"] = "program_image"
        self.fixture.candidate_value["freeze_inputs"]["images"] = [reused]
        self.assert_gap(self.fixture.audit(), "freeze_inputs.images.artifacts")

    def test_noncanonical_path_alias_is_rejected(self) -> None:
        aliased = {
            "kind": "program_image",
            "path": "npc/rv64/./.config",
            "sha256": freeze.sha256_file(self.fixture.config),
        }
        self.fixture.candidate_value["freeze_inputs"]["images"] = [aliased]
        self.assert_gap(self.fixture.audit(), "freeze_inputs.images.artifacts")

    def test_parent_directory_symlink_alias_is_rejected(self) -> None:
        alias = self.root / "freeze-alias"
        alias.symlink_to(self.root / "freeze", target_is_directory=True)
        self.fixture.candidate_value["freeze_inputs"]["constraints"] = [{
            "kind": "primary_sdc",
            "path": "freeze-alias/top.sdc",
            "sha256": freeze.sha256_file(self.fixture.constraint),
        }]
        self.assert_gap(self.fixture.audit(), "freeze_inputs.constraints.artifacts")

    def test_hardlink_identity_cannot_cross_freeze_groups(self) -> None:
        hardlink = self.root / "freeze/config-image.bin"
        os.link(self.fixture.config, hardlink)
        groups = json.loads(json.dumps(self.fixture.freeze_inputs))
        groups["images"] = [artifact(self.root, hardlink, "program_image")]
        cohort = {
            "schema": freeze.COHORT_SCHEMA,
            "design_id": self.fixture.design_id,
            "cohort_id": self.fixture.cohort_id,
            "freeze_inputs": groups,
            "run_parameters": self.fixture.run_parameters,
        }
        checks, blockers, _ = freeze.validate_freeze_inputs(
            root=self.root,
            groups=groups,
            required_tests=["tb_a"],
            cohort=cohort,
            expected_design_id=self.fixture.design_id,
            cohort_id=self.fixture.cohort_id,
            run_parameters=self.fixture.run_parameters,
        )
        self.assertTrue(blockers)
        image_check = next(
            item for item in checks
            if item["check_id"] == "freeze_inputs.images.artifacts")
        self.assertEqual(image_check["status"], "GAP")
        self.assertIn("reused across groups", image_check["detail"])

    def test_wrong_artifact_kind_is_rejected(self) -> None:
        self.fixture.candidate_value["freeze_inputs"]["constraints"][0]["kind"] = (
            "program_image")
        self.assert_gap(self.fixture.audit(), "freeze_inputs.constraints.artifacts")

    def test_sdc_period_must_match_frozen_parameters(self) -> None:
        self.fixture.constraint.write_text(
            "create_clock -name clk -period 10 [get_ports clk]\n",
            encoding="utf-8",
        )
        self.assert_gap(self.fixture.audit(), "freeze_inputs.constraints.semantic")

    def test_simulator_binary_must_remain_executable(self) -> None:
        self.fixture.simulator.chmod(0o644)
        self.assert_gap(self.fixture.audit(), "freeze_inputs.binaries.semantic")

    def test_shared_testbench_dependency_is_frozen(self) -> None:
        self.fixture.test_common.write_text("`define TB_PASS 0\n", encoding="utf-8")
        self.assert_gap(self.fixture.audit(), "freeze_inputs.test_sources.artifacts")

    def test_live_tool_binary_hash_drift_is_rejected(self) -> None:
        fake_python = self.root / "freeze/fakebin/python3"
        fake_python.write_text(
            "#!/bin/sh\necho 'python3 test-2.0'\n", encoding="utf-8")
        fake_python.chmod(0o755)
        self.assert_gap(self.fixture.audit(), "freeze_inputs.tool_versions.semantic")

    def test_extra_claim_field_is_rejected_by_schema(self) -> None:
        self.fixture.candidate_value["claim"]["ppa_champion"] = True
        self.assert_gap(self.fixture.audit(), "candidate.json_schema")

    def test_promotion_claim_is_rejected(self) -> None:
        self.fixture.candidate_value["claim"].update({
            "ppa": "QUALIFIED",
            "promotion_eligible": True,
        })
        self.assert_gap(self.fixture.audit(), "claim.architecture_only")

    def test_stored_result_tamper_and_schema_extension_are_detected(self) -> None:
        result = self.fixture.audit()
        result_path = write_json(self.root, "freeze/result.json", result)
        verified, errors = freeze.verify_result(root=self.root, result_path=result_path)
        self.assertIsNotNone(verified)
        self.assertEqual(errors, [])
        result["unqualified_promotion"] = True
        write_json(self.root, "freeze/result.json", result)
        verified, errors = freeze.verify_result(root=self.root, result_path=result_path)
        self.assertIsNone(verified)
        self.assertTrue(any("schema violation" in error for error in errors))


class CurrentWorkspaceTests(unittest.TestCase):
    def test_current_candidate_is_honest_gap_with_dynamic_inventory(self) -> None:
        root = freeze.find_repo_root(TOOL)
        candidate = root / "npc/rv64/eval/ppa/arch-stable/full-core-current.json"
        result = freeze.evaluate_candidate(
            root=root,
            candidate_path=candidate,
            generated_at_utc="2026-07-21T00:00:00+00:00",
        )
        self.assertEqual(result["architecture_freeze"], "GAP")
        self.assertEqual(result["ppa"], "UNQUALIFIED")
        self.assertFalse(result["promotion_eligible"])
        self.assertEqual(
            len(result["observed"]["functional"]["required_module_tests"]),
            109,
        )
        checks = {item["check_id"]: item for item in result["checks"]}
        self.assertEqual(
            checks["debt.FDG-G1.closed_binding"]["status"], "PASS")
        self.assertEqual(
            checks["debt.FDG-G1.semantic_evidence"]["status"], "PASS")
        self.assertFalse(any(
            "debt.FDG-G1" in blocker for blocker in result["blockers"]
        ))
        self.assertEqual(
            checks["debt.XRET-G1.closed_binding"]["status"], "PASS")
        self.assertEqual(
            checks["debt.XRET-G1.semantic_evidence"]["status"], "PASS")
        self.assertFalse(any(
            "debt.XRET-G1" in blocker for blocker in result["blockers"]
        ))
        self.assertEqual(
            checks["debt.INSTRET-G1.closed_binding"]["status"], "PASS")
        self.assertEqual(
            checks["debt.INSTRET-G1.semantic_evidence"]["status"], "PASS")
        self.assertFalse(any(
            "debt.INSTRET-G1" in blocker for blocker in result["blockers"]
        ))
        for debt_id in ("MEM-ISSUE-G1", "MIQ-FLUSH-G1", "IFU-AXI-G1"):
            self.assertEqual(
                checks[f"debt.{debt_id}.closed_binding"]["status"], "PASS")
            self.assertEqual(
                checks[f"debt.{debt_id}.semantic_evidence"]["status"],
                "PASS",
            )
            self.assertFalse(any(
                f"debt.{debt_id}" in blocker
                for blocker in result["blockers"]
            ))
        self.assertEqual(
            checks["debt.F0-G1.closed_binding"]["status"], "PASS")
        self.assertEqual(
            checks["debt.F0-G1.semantic_evidence"]["status"], "PASS")
        self.assertFalse(any(
            "debt.F0-G1" in blocker for blocker in result["blockers"]
        ))
        self.assertEqual(checks["functional.json_schema"]["status"], "PASS")
        self.assertEqual(
            checks["functional.schema_design_cohort"]["status"], "PASS")
        self.assertTrue(any(
            "census.full_core_complete" in blocker for blocker in result["blockers"]
        ))
        self.assertFalse(any(
            "functional.aggregate" in blocker for blocker in result["blockers"]
        ))
        self.assertTrue(any(
            "freeze_inputs.cohort_inventory" in blocker
            for blocker in result["blockers"]
        ))

    def test_cli_require_stable_returns_two_for_current_gap(self) -> None:
        root = freeze.find_repo_root(TOOL)
        candidate = root / "npc/rv64/eval/ppa/arch-stable/full-core-current.json"
        with tempfile.TemporaryDirectory() as temporary:
            result_path = pathlib.Path(temporary) / "gap-result.json"
            completed = subprocess.run(
                [
                    sys.executable, str(TOOL), "audit", str(candidate),
                    "--output", str(result_path), "--require-stable",
                ],
                cwd=root,
                check=False,
                capture_output=True,
                text=True,
            )
            self.assertEqual(
                completed.returncode, 2, completed.stderr + completed.stdout)

    def test_json_schemas_are_valid_draft_2020_12(self) -> None:
        root = freeze.find_repo_root(TOOL)
        for relative in freeze.SCHEMA_PATHS.values():
            value = freeze.load_json(root / relative)
            self.assertEqual(
                value.get("$schema"),
                "https://json-schema.org/draft/2020-12/schema",
            )
            jsonschema.Draft202012Validator.check_schema(value)


if __name__ == "__main__":
    unittest.main()
