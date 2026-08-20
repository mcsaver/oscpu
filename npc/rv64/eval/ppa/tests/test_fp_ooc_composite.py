from __future__ import annotations

import copy
import hashlib
import json
import os
import re
import shlex
import subprocess
import tempfile
import tkinter
import unittest
from pathlib import Path

from npc.rv64.eval.ppa.tools import architecture_registry as registry
from npc.rv64.eval.ppa.tools import fp_ooc_composite as ooc


_YOSYS_VARIABLE_TOKEN = "${yosys}"
_CHILD_YOSYS_ENV_ASSIGNMENTS = [
    "FP_OOC_CHILD_MODULE=${module}",
    "FP_OOC_PROFILE=${profile}",
    "SYNTH_BLACKBOX_MODULES=",
    "SYNTH_KNOWN_OOC_MODULES=",
    "SYNTH_COMPOSITE_CENSUS_JSON=${child_census}",
    "SYNTH_COMPOSITE_DESIGN_JSON=${child_design_json}",
    "CLK_FREQ_MHZ=200",
    "SYNTH_FLATTEN=0",
    "SYNTH_SHARE=0",
    "SYNTH_STOP_AFTER_COARSE=0",
    "SYNTH_PUBLIC_AUTONAME=1",
    "SYNTH_DFF_AUTONAME=0",
    "SYNTH_STA_FLATTEN_EXPORT=0",
]
_ENV_ASSIGNMENT_RE = re.compile(r"[A-Za-z_][A-Za-z0-9_]*=.*", re.S)
_SHELL_CONTROL_OPERATOR_RE = re.compile(r"[|&;]+")


def _child_synthesis_logical_command(runner: str) -> tuple[str, list[str]]:
    def require(condition: bool, label: str) -> None:
        if not condition:
            raise AssertionError(label)

    child_loop_marker = 'for module in "${children[@]}"; do\n'
    top_marker = '\ntop_runtime="${runtime_dir}/top"\n'
    child_start = runner.find(child_loop_marker)
    top_start = runner.find(top_marker, child_start)
    require(child_start >= 0 and top_start > child_start, "child loop boundary")
    child_block = runner[child_start:top_start]

    lines = child_block.splitlines(keepends=True)
    start_line = '  run_bounded 1800 /usr/bin/env \\'
    starts = [
        index for index, line in enumerate(lines)
        if line.rstrip("\r\n") == start_line
    ]
    require(len(starts) == 1,
            "one exact 1800-second child synthesis logical command")
    logical_lines: list[str] = []
    for line in lines[starts[0]:]:
        logical_lines.append(line)
        if line.rstrip("\r\n").rstrip(" \t").endswith("\\"):
            continue
        break
    require(bool(logical_lines), "child synthesis logical command is present")
    require(logical_lines[-1].strip() == "|| fail $?",
            "child synthesis logical command terminates in fail-closed status")
    command = "".join(logical_lines)
    require(command.count("||") == 1 and command.count("|| fail $?") == 1,
            "child synthesis logical command has one terminal || fail")
    require("$(" not in command and "`" not in command,
            "child synthesis command has no command substitution")

    normalized = re.sub(r"\\\r?\n", " ", command)
    try:
        lexer = shlex.shlex(
            normalized, posix=True, punctuation_chars="|&;"
        )
        lexer.whitespace_split = True
        lexer.commenters = ""
        tokens = list(lexer)
    except ValueError as exc:
        raise AssertionError(f"child synthesis shell tokenization: {exc}") from exc
    require(tokens[:3] == ["run_bounded", "1800", "/usr/bin/env"],
            "child synthesis bounded-command prefix")
    require(tokens[-3:] == ["||", "fail", "$?"],
            "child synthesis bounded-command terminal tokens")
    operators = [
        (index, token)
        for index, token in enumerate(tokens)
        if _SHELL_CONTROL_OPERATOR_RE.fullmatch(token)
    ]
    require(operators == [(len(tokens) - 3, "||")],
            "only the terminal fail-closed || control operator is present")

    executable_index = 3
    env_assignments: list[str] = []
    while (executable_index < len(tokens) and
           _ENV_ASSIGNMENT_RE.fullmatch(tokens[executable_index])):
        env_assignments.append(tokens[executable_index])
        executable_index += 1
    require(env_assignments == _CHILD_YOSYS_ENV_ASSIGNMENTS,
            "child synthesis /usr/bin/env assignment sequence is exact")
    require(executable_index < len(tokens) and
            tokens[executable_index] == _YOSYS_VARIABLE_TOKEN,
            "first executable after /usr/bin/env assignments is direct Yosys")
    require(tokens.count(_YOSYS_VARIABLE_TOKEN) == 1,
            "one direct Yosys executable token in the bounded command")
    yosys_index = executable_index
    expected_argv = [
        _YOSYS_VARIABLE_TOKEN, "-q", "-Q", "-T", "-t", "-l",
        "${child_dir}/yosys.log", "-c",
    ]
    require(tokens[yosys_index:yosys_index + len(expected_argv)] == expected_argv,
            "direct child Yosys timestamp argv is exact")
    require(tokens.count("-t") == 1,
            "bounded child Yosys argv contains one timestamp flag")
    for token in tokens[:yosys_index + len(expected_argv)]:
        require(
            re.search(r"\$\{[^}]*\[(?:@|\*)\][^}]*\}", token) is None,
            "bounded child Yosys launcher/flags have no array indirection",
        )
    return command, tokens


def _validate_production_runner_child_yosys_timestamp(runner: str) -> None:
    def require(condition: bool, label: str) -> None:
        if not condition:
            raise AssertionError(label)

    command, _ = _child_synthesis_logical_command(runner)
    child_loop_marker = 'for module in "${children[@]}"; do\n'
    top_marker = '\ntop_runtime="${runtime_dir}/top"\n'
    child_start = runner.find(child_loop_marker)
    top_start = runner.find(top_marker, child_start)
    child_block = runner[child_start:top_start]

    direct_invocation = (
        '    "${yosys}" -q -Q -T -t -l "${child_dir}/yosys.log" \\\n'
    )
    synth_budget = '  run_bounded 1800 /usr/bin/env \\\n'
    opensta_budget = (
        '    run_bounded 600 /usr/bin/env FP_OOC_CHILD_MODULE="${module}" \\\n'
    )
    require(command.count(direct_invocation) == 1,
            "one timestamped direct child Yosys invocation in bounded command")
    require(child_block.count('    "${yosys}" ') == 1,
            "one direct child Yosys command")
    require(command.startswith(synth_budget),
            "child synthesis timeout is exactly 1800 seconds")
    require(child_block.count(opensta_budget) == 1,
            "child OpenSTA timeout is exactly 600 seconds")
    require(command.index(synth_budget) < command.index(direct_invocation),
            "timestamped Yosys argv is owned by bounded child synthesis")
    require(
        len(re.findall(r"(?<![A-Za-z0-9_])-t(?![A-Za-z0-9_])", runner)) == 1,
        "-t appears exactly once in the production runner",
    )
    require(
        runner.count('[[ "${#children[@]}" -eq 5 && '
                     '"${#placeholder_rel[@]}" -eq 3 ]] || fail 2') == 1,
        "production child census remains five",
    )
    require(
        child_block.count(
            '    CLK_FREQ_MHZ=200 SYNTH_FLATTEN=0 SYNTH_SHARE=0 \\\n'
        ) == 1,
        "child synthesis sharing configuration remains frozen",
    )
    require(
        child_block.count(
            '    -c "${child_yosys_tcl}" -- "${module}" icsprout55 \\\n'
        ) == 1,
        "child Yosys Tcl and PDK selection remain frozen",
    )
    require(runner.count('run_bounded 5400 /usr/bin/env') == 1,
            "top synthesis budget remains frozen")
    require(
        runner.count(
            '  YOSYS_ARGS="-q -Q -T" YOSYS_LOG_ARGS= || fail $?'
        ) == 1,
        "top Yosys invocation remains untimestamped",
    )


class FpOocCompositeTests(unittest.TestCase):
    def setUp(self) -> None:
        self.projection = ooc.projection()
        catalog = registry.load_json(registry.CATALOG_PATH)
        configuration = registry.selected_physical_configuration(
            catalog, ooc.CONFIGURATION
        )
        digest = "1" * 64
        self.identity = {
            "schema": ooc.IDENTITY_SCHEMA,
            "run_id": "traceable-fp-ooc-unit-v1",
            "design_id": registry.EXPECTED_LIVE_DESIGN_ID,
            "physical_configuration_id": ooc.CONFIGURATION,
            "physical_configuration_sha256": registry.physical_configuration_sha256(
                ooc.CONFIGURATION, configuration
            ),
            "mapped_projection_sha256": ooc.canonical_sha256(self.projection),
            "mapped_artifact_profile": ooc.PROFILE,
            "abstraction_kind": ooc.ABSTRACTION,
            "corner": "typ_tt_1p2_25",
            "source_manifest_sha256": digest,
            "tool_manifest_sha256": "2" * 64,
            "standard_cell_lib_sha256": "3" * 64,
            "yosys_sha256": "4" * 64,
            "opensta_sha256": "5" * 64,
        }

    @staticmethod
    def receipt(name: str) -> dict[str, object]:
        return {
            "path": name,
            "path_scope": "evidence_relative",
            "sha256": hashlib.sha256(name.encode()).hexdigest(),
            "size_bytes": len(name) + 1,
        }

    @staticmethod
    def observed(startpoint: str, endpoint: str, *, slack: float = 0.1,
                 start_class: str = "PORT", end_class: str = "REGISTER_D",
                 from_objects: list[str] | None = None,
                 to_objects: list[str] | None = None) -> dict[str, object]:
        return {
            "status": "OBSERVED",
            "path_count": 1,
            "negative_path_count": 1 if slack < 0.0 else 0,
            "worst_slack_ns": slack,
            "startpoint": startpoint,
            "endpoint": endpoint,
            "startpoint_object_class": start_class,
            "endpoint_object_class": end_class,
            "from_objects": sorted(from_objects or [startpoint]),
            "to_objects": sorted(to_objects or [endpoint]),
        }

    @staticmethod
    def not_applicable() -> dict[str, object]:
        return {
            "status": "NOT_APPLICABLE",
            "path_count": 0,
            "negative_path_count": 0,
            "worst_slack_ns": None,
            "startpoint": None,
            "endpoint": None,
            "startpoint_object_class": None,
            "endpoint_object_class": None,
            "from_objects": [],
            "to_objects": [],
        }

    @staticmethod
    def family_objects(family: str, width: int, prefix: str = "") -> list[str]:
        base = f"{prefix}/{family}" if prefix else family
        return [base] if width == 1 else sorted(
            f"{base}[{bit}]" for bit in range(width)
        )

    def arc_inventory(self, module: str, analysis: str) -> list[dict[str, object]]:
        contract = self.projection["child_contracts"][module]
        rows: list[dict[str, object]] = []
        for family, width in contract["input_ports"].items():
            if family == "clk":
                continue
            names = self.family_objects(family, width)
            for arc_class, path_delay, delay, slack in (
                ("setup", "max", 1.2, 3.8),
                ("hold", "min", 0.03, -0.02),
            ):
                rows.append({
                    "arc_class": arc_class,
                    "port_family": family,
                    "path_delay": path_delay,
                    "declared_cardinality": width,
                    "observed_cardinality": width,
                    "path_count": width,
                    "worst_path_delay_ns": delay,
                    "worst_slack_ns": slack,
                    "source_object_class": "PORT",
                    "endpoint_object_class": "REGISTER_D",
                    "object_names": names,
                    "startpoint": names[0],
                    "endpoint": "u_stage_q/D",
                })
        driver_contract = self.dynamic_output_driver_contract(module)
        for family, width in contract["output_ports"].items():
            names = sorted(
                bit["opensta_object_name"] for bit in driver_contract["bits"]
                if bit["family"] == family and
                bit["classification"] == "DYNAMIC"
            )
            rows.append({
                "arc_class": "clk_to_q",
                "port_family": family,
                "path_delay": analysis,
                "declared_cardinality": width,
                "observed_cardinality": len(names),
                "path_count": len(names),
                "worst_path_delay_ns": (
                    0.22 if analysis == "max" else 0.04
                ) if names else None,
                "worst_slack_ns": 4.5 if names else None,
                "source_object_class": "REGISTER_Q",
                "endpoint_object_class": "PORT",
                "object_names": names,
                "startpoint": "u_stage_q/Q" if names else None,
                "endpoint": names[0] if names else None,
            })
        return sorted(rows, key=lambda row: (str(row["arc_class"]),
                                             str(row["port_family"])))

    def dynamic_output_driver_contract(self, module: str) -> dict[str, object]:
        bits: list[dict[str, object]] = []
        for family, width in sorted(
                self.projection["child_contracts"][module]["output_ports"].items()):
            for index in range(width):
                object_name = family if width == 1 else f"{family}[{index}]"
                is_addsub_constant = (
                    module == "OooFpAddSubPipe" and index == 3 and
                    family in {"addsub_d_fflags_q_o", "addsub_s_fflags_q_o"}
                )
                bit: dict[str, object] = {
                    "family": family,
                    "index": index,
                    "raw_port_name": family,
                    "opensta_object_name": object_name,
                    "net": index + 1,
                    "driver_instance": f"u_{family}_{index}",
                    "driver_cell_type": (
                        "TIELOH7L" if is_addsub_constant else "DFFQX1H7L"
                    ),
                    "driver_pin": "Z" if is_addsub_constant else "Q",
                    "stdlib_function": "0" if is_addsub_constant else "IQ",
                    "stdlib_function_sha256": ooc.canonical_sha256(
                        "0" if is_addsub_constant else "IQ"
                    ),
                    "classification": (
                        "CONSTANT_0" if is_addsub_constant else "DYNAMIC"
                    ),
                    "value": 0 if is_addsub_constant else None,
                }
                bit["driver_binding_sha256"] = ooc.canonical_sha256(bit)
                bits.append(bit)
        summary = {
            "bit_count": len(bits),
            "dynamic_count": sum(
                bit["classification"] == "DYNAMIC" for bit in bits
            ),
            "constant_0_count": sum(
                bit["classification"] == "CONSTANT_0" for bit in bits
            ),
            "constant_1_count": 0,
            "family_counts": {
                family: {
                    "CONSTANT_0": sum(
                        bit["family"] == family and
                        bit["classification"] == "CONSTANT_0" for bit in bits
                    ),
                    "CONSTANT_1": 0,
                    "DYNAMIC": sum(
                        bit["family"] == family and
                        bit["classification"] == "DYNAMIC" for bit in bits
                    ),
                }
                for family, width in sorted(
                    self.projection["child_contracts"][module][
                        "output_ports"
                    ].items()
                )
            },
        }
        return {
            "contract_id": ooc.canonical_sha256({"module": module, "bits": bits}),
            "bits": bits,
            "summary": summary,
        }

    def dynamic_output_bit_inventory(
        self, module: str, analysis: str,
        driver_contract: dict[str, object] | None = None,
    ) -> list[dict[str, object]]:
        contract = driver_contract or self.dynamic_output_driver_contract(module)
        rows = []
        for bit in contract["bits"]:
            dynamic = bit["classification"] == "DYNAMIC"
            rows.append({
                "family": bit["family"],
                "index": bit["index"],
                "object_name": bit["opensta_object_name"],
                "classification": bit["classification"],
                "constant_value": bit["value"],
                "path_delay": analysis,
                "path_count": 1 if dynamic else 0,
                "worst_path_delay_ns": (
                    0.22 if analysis == "max" else 0.04
                ) if dynamic else None,
                "worst_slack_ns": 4.5 if dynamic else None,
                "source_object_class": (
                    "REGISTER_Q" if dynamic else "STRUCTURAL_CONSTANT"
                ),
                "endpoint_object_class": "PORT",
                "startpoint": "u_stage_q/Q" if dynamic else None,
                "endpoint": bit["opensta_object_name"] if dynamic else None,
                "driver_binding_sha256": bit["driver_binding_sha256"],
            })
        return rows

    def boundary_objects(self, module: str) -> tuple[list[str], list[str], str]:
        contracts = self.projection["child_contracts"]
        contract = contracts[module]
        exact = contract["top_boundary_contract"]
        from_objects = sorted(
            name for family in exact["source_port_families"]
            for name in self.family_objects(
                family, contract["output_ports"][family],
                exact["source_instance_path"],
            )
        )
        endpoint = exact["endpoint"]
        instance, widths = ooc._boundary_endpoint_widths(endpoint, contracts)
        to_objects = sorted(
            name for family, width in widths.items()
            for name in self.family_objects(family, width, instance or "")
        )
        return from_objects, to_objects, endpoint["object_class"]

    def query_budget(
        self, module: str, analysis: str, *, path_classes: dict[str, object],
        arc_inventory: list[dict[str, object]],
        driver_contract: dict[str, object],
    ) -> dict[str, object]:
        contract = self.projection["child_contracts"][module]
        nonclock = sum(contract["input_ports"].values()) - 1
        outputs = sum(contract["output_ports"].values())
        dynamic = int(driver_contract["summary"]["dynamic_count"])
        class_count = 3 if module == "OooFpMulProductPipe" else 4
        register_multiplier = 2 if module == "OooFpMulProductPipe" else 3
        register_d = 608 if module == "OooFpAddSubPipe" else 16
        limit = register_multiplier * register_d + 2 * dynamic + 2 * nonclock
        materialized = (
            sum(int(row["path_count"]) for row in path_classes.values()) +
            sum(int(row["path_count"]) for row in arc_inventory)
        )
        return {
            "schema": ooc.QUERY_PROGRESS_SCHEMA,
            "artifact": self.receipt(
                f"children/{module}/child-query-progress-{analysis}.tsv"
            ),
            "completion_marker": ooc.QUERY_BUDGET_COMPLETION_MARKER,
            "complete": True,
            "expected_find_calls": class_count + 2 * nonclock + 1,
            "find_calls": class_count + 2 * nonclock + 1,
            "path_end_limit": limit,
            "path_end_count": materialized,
            "validation_limit": limit,
            "validation_count": materialized,
            "register_d_endpoints": register_d,
            "nonclock_input_bits": nonclock,
            "output_bits": outputs,
            "dynamic_output_bits": dynamic,
        }

    def child_result(self, module: str, *, negative: bool = False) -> dict[str, object]:
        contract = self.projection["child_contracts"][module]
        family_count = len(contract["input_ports"]) + len(contract["output_ports"])
        bit_count = (sum(contract["input_ports"].values()) +
                     sum(contract["output_ports"].values()))

        driver_contract = self.dynamic_output_driver_contract(module)

        def timing(mode: str) -> dict[str, object]:
            slack = -0.1 if negative and mode == "max" else 0.1
            data_ports = ["frs1_value_i", "frs2_value_i"]
            if "frs1_value_i" not in self.projection["child_contracts"][module]["input_ports"]:
                data_ports = [next(
                    name for name in self.projection["child_contracts"][module]["input_ports"]
                    if name not in {"clk", "rst", "flush_i"}
                )]
            input_names = sorted({name for family in data_ports for name in
                                  self.family_objects(family, self.projection[
                                      "child_contracts"][module]["input_ports"][family])})
            output_family, output_width = next(iter(
                self.projection["child_contracts"][module]["output_ports"].items()
            ))
            output_names = self.family_objects(output_family, output_width)
            d_names = ["u_s1_q/D"]
            q_names = ["u_s1_q/Q"]
            classes = {
                "port_to_register": self.observed(input_names[0], d_names[0], slack=slack,
                    from_objects=input_names, to_objects=d_names),
                "register_to_register": self.observed(q_names[0], d_names[0],
                    start_class="REGISTER_Q", end_class="REGISTER_D",
                    from_objects=q_names, to_objects=d_names),
                "register_to_port": self.observed(q_names[0], output_names[0],
                    start_class="REGISTER_Q", end_class="PORT",
                    from_objects=q_names, to_objects=output_names),
                "synchronous_control_to_register": self.observed("rst", d_names[0],
                    from_objects=["flush_i", "rst"], to_objects=d_names),
            }
            if module == "OooFpMulProductPipe":
                classes["register_to_register"] = self.not_applicable()
            negative_count = sum(
                int(row["negative_path_count"]) for row in classes.values()
            )
            arcs = self.arc_inventory(module, mode)
            return {
                "analysis": mode,
                "artifact": self.receipt(f"children/{module}/timing-{mode}.tsv"),
                "path_classes": classes,
                "arc_inventory": arcs,
                "output_bit_driver_contract_id": driver_contract["contract_id"],
                "output_bit_inventory": self.dynamic_output_bit_inventory(
                    module, mode, driver_contract
                ),
                "query_budget": self.query_budget(
                    module, mode, path_classes=classes,
                    arc_inventory=arcs, driver_contract=driver_contract,
                ),
                "negative_slack_count": negative_count,
            }

        return {
            "schema": ooc.CHILD_SCHEMA,
            "status": "PASS",
            "module": module,
            "run_identity": copy.deepcopy(self.identity),
            "source_closure_sha256": "6" * 64,
            "synthesis": {
                "implementation_class": "known_ooc_macro_source_mapping",
                "cell_count": 100,
                "area_um2": 10.0,
                "netlist_sha256": "7" * 64,
                "netlist_size_bytes": 1000,
                "synth_stat": self.receipt(f"children/{module}/synth-stat.txt"),
                "census_json": self.receipt(f"children/{module}/synth-census.json"),
                "netlist_manifest": self.receipt(
                    f"children/{module}/netlist-manifest.json"
                ),
                "port_manifest": {
                    "schema": ooc.PORT_CANONICALIZATION_SCHEMA,
                    "raw_port_count": family_count,
                    "raw_bit_count": bit_count,
                    "canonical_port_count": family_count,
                    "canonical_bit_count": bit_count,
                    "mapping_count": family_count,
                },
                "output_bit_driver_contract": self.receipt(
                    f"children/{module}/output-bit-driver-contract.json"
                ),
                "output_bit_driver_contract_value": driver_contract,
                "census": {module: 1},
            },
            "timing": {
                "max": timing("max"),
                "min": timing("min"),
                "assessment": "VIOLATED" if negative else "CLEAN",
            },
            "liberty": {
                mode: {
                    "analysis": mode,
                    "artifact": self.receipt(f"children/{module}/{module}-{mode}.lib"),
                    "metadata_sha256": "8" * 64,
                }
                for mode in ("max", "min")
            },
            "power": {
                "model": "absent",
                "complete": False,
                "status": "INCOMPLETE_NO_OOC_POWER_MODEL",
            },
        }

    def top_result(self, *, negative: bool = False) -> dict[str, object]:
        def timing(mode: str) -> dict[str, object]:
            classes: dict[str, object] = {}
            for module, contract in self.projection["child_contracts"].items():
                boundary = contract["path_classes"]["top_boundary"]
                from_objects, to_objects, endpoint_class = self.boundary_objects(module)
                slack = -0.2 if negative and mode == "max" and not classes else 0.2
                classes[boundary] = self.observed(
                    from_objects[0], to_objects[0], slack=slack,
                    start_class="MACRO_PIN_OUTPUT", end_class=endpoint_class,
                    from_objects=from_objects, to_objects=to_objects,
                )
            return {
                "analysis": mode,
                "artifact": self.receipt(f"top-boundary-{mode}.tsv"),
                "boundary_classes": classes,
                "negative_slack_count": sum(
                    int(row["negative_path_count"]) for row in classes.values()
                ),
            }

        return {
            "schema": ooc.TOP_SCHEMA,
            "status": "PASS",
            "run_identity": copy.deepcopy(self.identity),
            "synthesis": {
                "implementation_class": "npctop_inline_wrapper_plus_known_ooc_macros",
                "top_stdcell_cell_count": 1000,
                "top_stdcell_area_um2": 100.0,
                "inline_rtl_instances": {"OooFpArithGate": 1},
                "known_ooc_macro_instances": copy.deepcopy(
                    self.projection["expected_known_ooc_macro_instances"]
                ),
                "unknown_placeholder_instances": copy.deepcopy(
                    self.projection["expected_unknown_macro_instances"]
                ),
                "standard_cell_module_census": {"ics55_dff": 100, "ics55_nand2": 900},
                "netlist_sha256": "9" * 64,
                "netlist_size_bytes": 10000,
                "synth_stat": self.receipt("top-synth-stat.txt"),
                "census_json": self.receipt("top-synth-census.json"),
                "netlist_manifest": self.receipt("top-netlist-manifest.json"),
            },
            "timing": {
                "max": timing("max"),
                "min": timing("min"),
                "assessment": "VIOLATED" if negative else "CLEAN",
            },
        }

    def summary(self, *, child_negative: bool = False,
                top_negative: bool = False) -> dict[str, object]:
        children = {
            module: self.child_result(
                module,
                negative=child_negative and module == "OooFpFmaAlignAddPipe",
            )
            for module in ooc.CHILDREN
        }
        run_artifacts = {
            "production_manifest_before": self.receipt("production-manifest-before.sha256"),
            "production_manifest_after": self.receipt("production-manifest-after.sha256"),
            "source_manifest": self.receipt("synthesis-sources.sha256"),
            "tool_manifest": self.receipt("tool-inputs.sha256"),
            "run_identity": self.receipt("run-identity.json"),
            "registry_contract": self.receipt("ooc-composite-contract.json"),
            "stdlib_leaf_whitelist": self.receipt("stdlib-leaf-whitelist.json"),
            "top_boundary_contract_tcl": self.receipt("top-boundary-contract.tcl"),
        }
        run_artifacts["production_manifest_after"]["sha256"] = (
            run_artifacts["production_manifest_before"]["sha256"]
        )
        run_artifacts["source_manifest"]["sha256"] = self.identity[
            "source_manifest_sha256"
        ]
        run_artifacts["tool_manifest"]["sha256"] = self.identity[
            "tool_manifest_sha256"
        ]
        return ooc.build_composite_summary(
            identity=copy.deepcopy(self.identity),
            children=children,
            top=self.top_result(negative=top_negative),
            run_artifacts=run_artifacts,
            expected_projection=self.projection,
        )

    def assert_rejected(self, value: dict[str, object]) -> None:
        with self.assertRaises(ooc.EvidenceError):
            ooc.validate_composite_summary(value, expected_projection=self.projection)

    def test_production_tcl_row_emitters_are_exact_nested_lists(self) -> None:
        def decode(script: str, variable: str) -> tuple[tuple[str, ...], ...]:
            interp = tkinter.Tcl()
            interp.eval(script)
            outer = interp.splitlist(interp.getvar(variable))
            return tuple(
                tuple(str(atom) for atom in interp.splitlist(row))
                for row in outer
            )

        def raw_nested(
            variable: str, rows: tuple[tuple[str, ...], ...]
        ) -> str:
            rendered = [
                "  {" + " ".join(f"{{{atom}}}" for atom in row) + "}"
                for row in rows
            ]
            return f"set {variable} {{\n" + "\n".join(rendered) + "\n}\n"

        def legacy_flattened(
            variable: str, rows: tuple[tuple[str, ...], ...]
        ) -> str:
            rendered = [
                "  " + " ".join(f"{{{atom}}}" for atom in row)
                for row in rows
            ]
            return f"set {variable} {{\n" + "\n".join(rendered) + "\n}\n"

        a8_root = (
            registry.REPO_ROOT
            / ".github/task-runs/2026-08-11-rv64-fp-ooc-composite-ppa-9d8b-a8"
            / "evidence/fp-ooc-composite-v1"
        )
        gate_status = (a8_root / "gate-status.txt").read_text(encoding="utf-8")
        self.assertIn("RESULT=FAIL", gate_status)
        self.assertIn("STAGE=child-OooFpAddSubPipe-opensta-max", gate_status)
        driver_contract = ooc.load_json(
            a8_root
            / "children/OooFpAddSubPipe/output-bit-driver-contract.json"
        )
        self.assertEqual("PASS", driver_contract["status"])
        self.assertEqual(138, driver_contract["summary"]["bit_count"])

        child_script = ooc.render_output_bit_driver_contract_tcl(driver_contract)
        child_rows = decode(
            child_script, "fp_ooc_output_bit_driver_contract"
        )
        expected_child_rows = tuple(
            (
                str(bit["family"]),
                str(bit["index"]),
                str(bit["opensta_object_name"]),
                str(bit["classification"]),
                "-" if bit["value"] is None else str(bit["value"]),
                str(bit["driver_binding_sha256"]),
            )
            for bit in driver_contract["bits"]
        )
        self.assertEqual(expected_child_rows, child_rows)
        self.assertEqual(138, len(child_rows))
        self.assertEqual({6}, {len(row) for row in child_rows})

        contracts = self.projection["child_contracts"]
        top_script = ooc.render_top_boundary_contract_tcl(contracts)
        top_rows = decode(top_script, "fp_ooc_boundary_contract")
        expected_top_rows: list[tuple[str, ...]] = []
        for module in ooc.CHILDREN:
            contract = contracts[module]
            exact = contract["top_boundary_contract"]
            endpoint = exact["endpoint"]
            endpoint_instance, endpoint_widths = ooc._boundary_endpoint_widths(
                endpoint, contracts
            )
            source_widths = {
                name: contract["output_ports"][name]
                for name in exact["source_port_families"]
            }
            encode = lambda widths: " ".join(
                f"{name}={width}" for name, width in sorted(widths.items())
            )
            expected_top_rows.append((
                contract["path_classes"]["top_boundary"],
                exact["source_instance_path"],
                exact["source_object_class"],
                encode(source_widths),
                endpoint["kind"],
                endpoint_instance or "-",
                endpoint["object_class"],
                encode(endpoint_widths),
            ))
        self.assertEqual(tuple(expected_top_rows), top_rows)
        self.assertEqual(5, len(top_rows))
        self.assertEqual({8}, {len(row) for row in top_rows})

        missing_field = (child_rows[0][:-1], *child_rows[1:])
        extra_field = (child_rows[0] + ("unexpected",), *child_rows[1:])
        cross_row_merge = (
            child_rows[0] + child_rows[1], *child_rows[2:]
        )
        digest = "0" * 64
        unsafe_brace = (
            'set unsafe_brace [list [list "bad\\{atom" {0} {object_0_} '
            f'{{DYNAMIC}} {{-}} {{{digest}}}]]\n'
        )
        unsafe_backslash = (
            r"set unsafe_backslash [list [list {bad\atom} {0} {object_0_} "
            f'{{DYNAMIC}} {{-}} {{{digest}}}]]\n'
        )
        mutations = (
            (
                "a8-child-flattened",
                legacy_flattened("mutated", child_rows),
                "mutated", 138, ooc.OUTPUT_BIT_DRIVER_TCL_FIELDS,
            ),
            (
                "top-flattened",
                legacy_flattened("mutated", top_rows),
                "mutated", 5, ooc.TOP_BOUNDARY_TCL_FIELDS,
            ),
            (
                "missing-field",
                raw_nested("mutated", missing_field),
                "mutated", 138, ooc.OUTPUT_BIT_DRIVER_TCL_FIELDS,
            ),
            (
                "extra-field",
                raw_nested("mutated", extra_field),
                "mutated", 138, ooc.OUTPUT_BIT_DRIVER_TCL_FIELDS,
            ),
            (
                "cross-row-merge",
                raw_nested("mutated", cross_row_merge),
                "mutated", 138, ooc.OUTPUT_BIT_DRIVER_TCL_FIELDS,
            ),
            (
                "top-row-count-drift",
                raw_nested("mutated", top_rows[:-1]),
                "mutated", 5, ooc.TOP_BOUNDARY_TCL_FIELDS,
            ),
            (
                "unsafe-brace",
                unsafe_brace,
                "unsafe_brace", 1, ooc.OUTPUT_BIT_DRIVER_TCL_FIELDS,
            ),
            (
                "unsafe-backslash",
                unsafe_backslash,
                "unsafe_backslash", 1, ooc.OUTPUT_BIT_DRIVER_TCL_FIELDS,
            ),
        )
        for label, script, variable, row_count, field_names in mutations:
            with self.subTest(mutation=label):
                # Every mutation is valid Tcl source; the semantic row/atom
                # contract, rather than a syntax error, must reject it.
                decoded = decode(script, variable)
                with self.assertRaises(ooc.EvidenceError):
                    ooc.validate_tcl_row_table(
                        decoded,
                        field_names=field_names,
                        expected_rows=row_count,
                        label=label,
                    )

        for atom in ("bad{atom", r"bad\atom"):
            damaged = [list(child_rows[0])]
            damaged[0][0] = atom
            with self.subTest(emitter_unsafe_atom=atom), self.assertRaises(
                ooc.EvidenceError
            ):
                ooc.render_tcl_row_table(
                    "damaged",
                    damaged,
                    field_names=ooc.OUTPUT_BIT_DRIVER_TCL_FIELDS,
                    expected_rows=1,
                    label="unsafe emitter mutation",
                )

        print(
            "[FP-OOC-TCL-ROW-SHAPE][PASS] "
            "child=OooFpAddSubPipe rows=138 fields=6 "
            "top=NpcTop rows=5 fields=8 mutations=8"
        )

    def test_registry_projection_has_three_disjoint_implementation_classes(self) -> None:
        self.assertEqual(["OooFpArithGate"], self.projection["inline_modules"])
        self.assertEqual(list(ooc.CHILDREN), self.projection["known_ooc_macro_modules"])
        classes = self.projection["implementation_classes"]
        members = [module for group in classes.values() for module in group]
        self.assertEqual(len(members), len(set(members)))
        self.assertEqual(
            {"Sram4096x199": 1, "Sram4096x113": 2, "OooBranchDirectionPredictor": 1},
            self.projection["expected_unknown_macro_instances"],
        )
        endpoint = self.projection["child_contracts"][
            "OooFpFmaNormRoundPipe"
        ]["top_boundary_contract"]["endpoint"]
        self.assertEqual(
            {
                "kind": "backend_completion_register_d",
                "object_class": "REGISTER_D",
                "instance_path": registry.FP_OOC_BACKEND_COMPLETION_INSTANCE_PATH,
                "register_families": {"df_fflags_q": 40, "df_value_q": 512},
            },
            endpoint,
        )
        self.assertNotIn("top_port", json.dumps(endpoint, sort_keys=True))
        self.assertNotIn("out_value_o", json.dumps(endpoint, sort_keys=True))
        self.assertNotIn("out_fflags_o", json.dumps(endpoint, sort_keys=True))
        with self.assertRaises(ooc.EvidenceError):
            ooc._boundary_endpoint_widths(
                {
                    "kind": "top_port",
                    "object_class": "PORT",
                    "port_families": {"out_fflags_o": 5, "out_value_o": 64},
                },
                self.projection["child_contracts"],
            )

    def test_canonical_liberty_has_complete_sequential_arcs_and_no_power(self) -> None:
        driver_contract = self.dynamic_output_driver_contract("OooFpAddSubPipe")
        metadata = ooc.liberty_metadata(
            identity=copy.deepcopy(self.identity),
            module="OooFpAddSubPipe",
            analysis="max",
            source_closure_sha256="a" * 64,
            timing_evidence_sha256="b" * 64,
            area_um2=12.5,
            cell_count=42,
            arc_inventory=self.arc_inventory("OooFpAddSubPipe", "max"),
            output_bit_inventory=self.dynamic_output_bit_inventory(
                "OooFpAddSubPipe", "max", driver_contract
            ),
            output_bit_driver_contract=driver_contract,
        )
        text = ooc.render_sequential_liberty(metadata)
        self.assertEqual(
            self.projection["ooc_model_contract"]["path_measurement_basis"],
            metadata["arc_derivation"]["path_measurement_basis"],
        )
        self.assertEqual(
            metadata,
            ooc.validate_sequential_liberty(
                text,
                expected_identity=self.identity,
                expected_module="OooFpAddSubPipe",
                expected_analysis="max",
                expected_timing_sha256="b" * 64,
            ),
        )
        self.assertNotIn("internal_power", text)
        self.assertNotIn("leakage_power", text)

    def test_liberty_negative_matrix_rejects_arc_exception_and_identity_damage(self) -> None:
        driver_contract = self.dynamic_output_driver_contract("OooFpMulNormRoundPipe")
        metadata = ooc.liberty_metadata(
            identity=copy.deepcopy(self.identity),
            module="OooFpMulNormRoundPipe",
            analysis="min",
            source_closure_sha256="a" * 64,
            timing_evidence_sha256="b" * 64,
            area_um2=8.0,
            cell_count=20,
            arc_inventory=self.arc_inventory("OooFpMulNormRoundPipe", "min"),
            output_bit_inventory=self.dynamic_output_bit_inventory(
                "OooFpMulNormRoundPipe", "min", driver_contract
            ),
            output_bit_driver_contract=driver_contract,
        )
        good = ooc.render_sequential_liberty(metadata)
        mutations = {
            "missing_setup": good.replace("timing_type : setup_rising;", "timing_type : hold_rising;", 1),
            "missing_hold": good.replace("timing_type : hold_rising;", "timing_type : setup_rising;", 1),
            "missing_clk_to_q": good.replace("timing_type : rising_edge;", "timing_type : setup_rising;", 1),
            "wrong_related_pin": good.replace('related_pin : "clk";', 'related_pin : "rst";', 1),
            "async_recovery": good.replace("timing_type : setup_rising;", "timing_type : recovery_rising;", 1),
            "fake_pi_to_po": good.replace("timing_type : rising_edge;", "timing_type : combinational;", 1),
            "false_path": good.replace("  cell (", "  /* false_path */\n  cell (", 1),
            "multicycle": good.replace("  cell (", "  /* multicycle_path */\n  cell (", 1),
            "fake_power": good.replace("  cell (", "  leakage_power () {}\n  cell (", 1),
        }
        for label, damaged in mutations.items():
            with self.subTest(label=label), self.assertRaises(ooc.EvidenceError):
                ooc.validate_sequential_liberty(
                    damaged,
                    expected_identity=self.identity,
                    expected_module="OooFpMulNormRoundPipe",
                    expected_analysis="min",
                )

    def test_mul_product_single_stage_explicitly_has_no_reg_to_reg_requirement(self) -> None:
        result = self.child_result("OooFpMulProductPipe")
        self.assertEqual(
            0, ooc.validate_child_result(result, expected_identity=self.identity)
        )
        damaged = copy.deepcopy(result)
        damaged["timing"]["max"]["path_classes"]["register_to_register"] = self.observed(
            "REG:s1_q", "REG:invented_s2_q"
        )
        with self.assertRaises(ooc.EvidenceError):
            ooc.validate_child_result(damaged, expected_identity=self.identity)

    def test_zero_negative_slack_clean_design_is_accepted(self) -> None:
        summary = self.summary()
        ooc.validate_composite_summary(summary, expected_projection=self.projection)
        self.assertEqual("CLEAN", summary["timing_accounting"]["assessment"])
        self.assertTrue(summary["timing_accounting"]["zero_negative_slack_is_valid"])

    def test_addsub_query_budget_and_complete_marker_fail_closed(self) -> None:
        result = self.child_result("OooFpAddSubPipe")
        self.assertEqual(
            (273, 2364, 2364),
            (
                result["timing"]["max"]["query_budget"]["find_calls"],
                result["timing"]["max"]["query_budget"]["path_end_limit"],
                result["timing"]["max"]["query_budget"]["validation_limit"],
            ),
        )
        self.assertEqual(
            0, ooc.validate_child_result(result, expected_identity=self.identity)
        )
        for field, value in (
            ("find_calls", 272),
            ("path_end_limit", 2363),
            ("validation_limit", 2363),
            ("completion_marker", "[FP-OOC-QUERY-BUDGET][INCOMPLETE]"),
            ("complete", False),
            ("path_end_count", 1),
            ("validation_count", 1),
        ):
            damaged = copy.deepcopy(result)
            damaged["timing"]["max"]["query_budget"][field] = value
            with self.subTest(field=field), self.assertRaises(ooc.EvidenceError):
                ooc.validate_child_result(damaged, expected_identity=self.identity)

    def test_child_internal_negative_slack_cannot_be_masked_by_clean_top(self) -> None:
        summary = self.summary(child_negative=True)
        self.assertEqual("VIOLATED", summary["timing_accounting"]["assessment"])
        ooc.validate_composite_summary(summary, expected_projection=self.projection)
        damaged = copy.deepcopy(summary)
        damaged["timing_accounting"]["assessment"] = "CLEAN"
        self.assert_rejected(damaged)

    def test_missing_top_boundary_class_is_rejected(self) -> None:
        summary = self.summary()
        classes = summary["top"]["timing"]["max"]["boundary_classes"]
        classes.pop("fma_align_s3_q_to_fma_norm_s4_d")
        self.assert_rejected(summary)

    def test_run_corner_source_tool_and_liberty_replay_are_rejected(self) -> None:
        for field, replacement in {
            "run_id": "replayed-run",
            "corner": "wrong_corner",
            "source_manifest_sha256": "a" * 64,
            "tool_manifest_sha256": "b" * 64,
            "standard_cell_lib_sha256": "c" * 64,
        }.items():
            summary = self.summary()
            summary["children"]["OooFpAddSubPipe"]["run_identity"][field] = replacement
            with self.subTest(field=field):
                self.assert_rejected(summary)

    def test_child_missing_duplicate_zero_area_and_zero_cells_are_rejected(self) -> None:
        missing = self.summary()
        missing["children"].pop("OooFpMulNormRoundPipe")
        self.assert_rejected(missing)
        for field in ("cell_count", "area_um2"):
            damaged = self.summary()
            damaged["children"]["OooFpAddSubPipe"]["synthesis"][field] = 0
            with self.subTest(field=field):
                self.assert_rejected(damaged)
        duplicate = self.summary()
        duplicate["top"]["synthesis"]["known_ooc_macro_instances"]["OooFpAddSubPipe"] = 2
        self.assert_rejected(duplicate)

    def test_macro_stdcell_duplicate_and_area_double_or_missing_are_rejected(self) -> None:
        duplicate = self.summary()
        duplicate["top"]["synthesis"]["standard_cell_module_census"]["OooFpAddSubPipe"] = 1
        self.assert_rejected(duplicate)
        for field, value in {
            "macro_area_sum_um2": 40.0,
            "composite_area_um2": 100.0,
            "double_counted_modules": ["OooFpAddSubPipe"],
            "missing_modules": ["OooFpFmaNormRoundPipe"],
        }.items():
            damaged = self.summary()
            damaged["area_accounting"][field] = value
            with self.subTest(field=field):
                self.assert_rejected(damaged)

    def test_absent_power_model_cannot_be_promoted(self) -> None:
        summary = self.summary()
        summary["power"]["complete"] = True
        self.assert_rejected(summary)
        child = self.summary()
        child["children"]["OooFpAddSubPipe"]["power"]["complete"] = True
        self.assert_rejected(child)

    def test_measured_arc_change_propagates_to_canonical_liberty(self) -> None:
        module = "OooFpAddSubPipe"
        driver_contract = self.dynamic_output_driver_contract(module)
        bit_inventory = self.dynamic_output_bit_inventory(
            module, "max", driver_contract
        )
        original_inventory = self.arc_inventory(module, "max")
        original = ooc.liberty_metadata(
            identity=copy.deepcopy(self.identity), module=module, analysis="max",
            source_closure_sha256="a" * 64, timing_evidence_sha256="b" * 64,
            area_um2=12.5, cell_count=42,
            arc_inventory=original_inventory,
            output_bit_inventory=bit_inventory,
            output_bit_driver_contract=driver_contract,
        )
        changed_inventory = copy.deepcopy(original_inventory)
        setup = next(row for row in changed_inventory
                     if row["arc_class"] == "setup")
        setup["worst_slack_ns"] = float(setup["worst_slack_ns"]) - 0.25
        changed = ooc.liberty_metadata(
            identity=copy.deepcopy(self.identity), module=module, analysis="max",
            source_closure_sha256="a" * 64, timing_evidence_sha256="c" * 64,
            area_um2=12.5, cell_count=42,
            arc_inventory=changed_inventory,
            output_bit_inventory=bit_inventory,
            output_bit_driver_contract=driver_contract,
        )
        self.assertNotEqual(
            ooc.render_sequential_liberty(original),
            ooc.render_sequential_liberty(changed),
        )
        constant_substitution = copy.deepcopy(original)
        constant_substitution["arc_inventory"] = changed_inventory
        with self.assertRaises(ooc.EvidenceError):
            ooc.render_sequential_liberty(constant_substitution)

    def test_d_pin_launch_and_missing_control_or_port_family_are_rejected(self) -> None:
        module = "OooFpAddSubPipe"
        d_launch = self.child_result(module)
        d_launch["timing"]["max"]["path_classes"]["register_to_port"][
            "startpoint_object_class"
        ] = "REGISTER_D"
        with self.assertRaises(ooc.EvidenceError):
            ooc.validate_child_result(d_launch, expected_identity=self.identity)
        for family in ("rst", "flush_i", "frs1_value_i"):
            damaged = self.child_result(module)
            damaged["timing"]["max"]["arc_inventory"] = [
                row for row in damaged["timing"]["max"]["arc_inventory"]
                if row["port_family"] != family
            ]
            with self.subTest(family=family), self.assertRaises(ooc.EvidenceError):
                ooc.validate_child_result(damaged, expected_identity=self.identity)

    def test_dollar_generic_and_nonstdlib_leaf_are_rejected(self) -> None:
        for cell_type in ("$mul", "invented_leaf"):
            modules = {
                "T": {
                    "num_cells": 1,
                    "num_cells_by_type": {cell_type: 1},
                    "area": 1.0,
                }
            }
            with self.subTest(cell_type=cell_type), self.assertRaises(ooc.EvidenceError):
                ooc._mapped_leaf_census(
                    modules, top="T", whitelist={"ics55_dff"},
                    boundary_modules=set(),
                )
        self.assertEqual(
            {"ics55_dff": 1},
            ooc._mapped_leaf_census(
                {"T": {"num_cells": 1,
                       "num_cells_by_type": {"ics55_dff": 1}, "area": 1.0}},
                top="T", whitelist={"ics55_dff"}, boundary_modules=set(),
            ),
        )

    def test_forged_top_object_label_and_manifest_receipt_are_rejected(self) -> None:
        summary = self.summary()
        boundary = "addsub_s3_q_to_wrapper_s4_d"
        row = summary["top"]["timing"]["max"]["boundary_classes"][boundary]
        forged = row["from_objects"][0].replace(
            "u_fp_arith/u_addsub_pipe", "u_fp_arith/u_fake_pipe"
        )
        row["from_objects"][0] = forged
        row["from_objects"] = sorted(row["from_objects"])
        row["startpoint"] = forged
        self.assert_rejected(summary)
        missing_manifest = self.summary()
        missing_manifest["children"]["OooFpAddSubPipe"]["synthesis"].pop(
            "netlist_manifest"
        )
        self.assert_rejected(missing_manifest)

    def test_final_fma_boundary_rejects_legacy_port_near_name_and_wrong_hierarchy(
            self) -> None:
        boundary = "fma_norm_s5_q_to_wrapper_result_completion_d"
        legacy = self.summary()
        for mode in ("max", "min"):
            row = legacy["top"]["timing"][mode]["boundary_classes"][boundary]
            row["endpoint_object_class"] = "PORT"
            row["to_objects"] = sorted([
                *self.family_objects("out_fflags_o", 5),
                *self.family_objects("out_value_o", 64),
            ])
            row["endpoint"] = row["to_objects"][0]
        self.assert_rejected(legacy)

        for label, old, new in (
            ("near-name", "df_value_q", "df_value_qq"),
            ("wrong-hierarchy", "/u_fp_backend/", "/u_fake_fp_backend/"),
        ):
            damaged = self.summary()
            for mode in ("max", "min"):
                row = damaged["top"]["timing"][mode]["boundary_classes"][boundary]
                row["to_objects"] = [name.replace(old, new) for name in row["to_objects"]]
                row["endpoint"] = row["endpoint"].replace(old, new)
            with self.subTest(label=label):
                self.assert_rejected(damaged)

    def test_hardlinked_retained_artifact_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary).resolve()
            original = root / "a.txt"
            replay = root / "b.txt"
            original.write_text("evidence\n", encoding="utf-8")
            replay.hardlink_to(original)
            with self.assertRaises(ooc.EvidenceError):
                ooc.artifact(original, evidence_dir=root)

    def test_schema_and_production_entries_are_not_placeholders(self) -> None:
        schema = json.loads(
            (registry.REPO_ROOT / "npc/rv64/eval/ppa/schemas/fp-ooc-composite-v1.schema.json")
            .read_text(encoding="utf-8")
        )
        self.assertEqual(ooc.SCHEMA, schema["properties"]["schema"]["const"])
        child_synthesis = schema["$defs"]["child"]["properties"]["synthesis"]
        self.assertIn("port_manifest", child_synthesis["required"])
        self.assertEqual(
            "#/$defs/portManifestSummary",
            child_synthesis["properties"]["port_manifest"]["$ref"],
        )
        self.assertEqual(
            ooc.PORT_CANONICALIZATION_SCHEMA,
            schema["$defs"]["portManifestSummary"]["properties"]["schema"][
                "const"
            ],
        )
        self.assertEqual(
            "#/$defs/outputBitDriverContract",
            child_synthesis["properties"][
                "output_bit_driver_contract_value"
            ]["$ref"],
        )
        self.assertEqual(
            ooc.OUTPUT_BIT_DRIVER_CONTRACT_SCHEMA,
            schema["$defs"]["outputBitDriverContract"]["properties"][
                "schema"
            ]["const"],
        )
        self.assertEqual(
            ooc.QUERY_PROGRESS_SCHEMA,
            schema["$defs"]["queryBudget"]["properties"]["schema"]["const"],
        )
        self.assertIn(
            "query_budget", schema["$defs"]["childTimingMode"]["required"]
        )
        runner = (registry.REPO_ROOT / "npc/rv64/eval/ppa/run-fp-ooc-composite-current.sh").read_text(encoding="utf-8")
        child_tcl = (registry.REPO_ROOT / "npc/rv64/eval/ppa/opensta-fp-ooc-child.tcl").read_text(encoding="utf-8")
        top_tcl = (registry.REPO_ROOT / "npc/rv64/eval/ppa/opensta-fp-ooc-top.tcl").read_text(encoding="utf-8")
        for marker in (
            "SYNTH_KNOWN_OOC_MODULES",
            "render-liberty-from-artifacts",
            "parse-child",
            "parse-top",
            "production-manifest-before.sha256",
            "production-manifest-after.sha256",
            "stdlib-leaf-whitelist.json",
            "netlist-manifest.json",
            'status_path="${evidence_dir}/gate-status.txt"',
            "[TRACEABLE-FP-OOC-COMPOSITE][PASS]",
            "[FP-OOC-QUERY-BUDGET][PASS] child_analyses=10 complete=10",
        ):
            self.assertIn(marker, runner)
        self.assertIn("find_timing_paths", child_tcl)
        self.assertEqual(1, child_tcl.count("find_timing_paths -from"))
        self.assertIn("proc collect_output_timing_bulk", child_tcl)
        self.assertNotIn("group_path_count 100000", child_tcl)
        self.assertIn("register_q_pins", child_tcl)
        self.assertIn("FP_OOC_INPUT_PORT_CONTRACT", child_tcl)
        self.assertIn("arc_inventory", child_tcl)
        self.assertIn("register_to_register NOT_APPLICABLE", child_tcl)
        self.assertIn("find_timing_paths", top_tcl)
        self.assertIn("actual_pin_crosscheck", top_tcl)
        self.assertIn("$exact_name ne $full", top_tcl)
        self.assertIn("actual_parent_cell_crosscheck", top_tcl)
        self.assertIn("exact_backend_completion_register_d_objects", top_tcl)
        self.assertNotIn('endpoint_kind eq "top_port"', top_tcl)
        self.assertNotIn("proc exact_top_port_objects", top_tcl)
        self.assertNotIn("proc actual_port_crosscheck", top_tcl)
        self.assertIn("FP_OOC_TOP_BOUNDARY_CONTRACT_TCL", top_tcl)
        projection_text = json.dumps(self.projection, sort_keys=True)
        for boundary in (
            "addsub_s3_q_to_wrapper_s4_d",
            "mul_product_s1_q_to_mul_norm_s2_d",
            "mul_norm_s3_q_to_wrapper_s4_d",
            "fma_align_s3_q_to_fma_norm_s4_d",
            "fma_norm_s5_q_to_wrapper_result_completion_d",
        ):
            self.assertIn(boundary, projection_text)
        for forbidden in ("set_false_path", "set_multicycle_path"):
            self.assertNotIn(forbidden, child_tcl)
            self.assertNotIn(forbidden, top_tcl)
        yosys_tcl = (registry.REPO_ROOT / "yosys-sta/scripts/yosys.tcl").read_text(
            encoding="utf-8"
        )
        self.assertIn("check -mapped -assert", yosys_tcl)
        self.assertIn("SYNTH_COMPOSITE_DESIGN_JSON", yosys_tcl)
        self.assertNotIn('status_path="${run_dir}/${run_id}.status"', runner)

    def test_child_source_domains_and_runner_consumption_are_explicit(self) -> None:
        filelist = "npc/rv64/vsrc/filelist.mk"
        for module, contract in self.projection["child_contracts"].items():
            closure = contract["source_closure"]
            compile_sources = contract["compile_sources"]
            self.assertEqual(
                [path for path in closure if Path(path).suffix in {".v", ".sv"}],
                compile_sources,
                module,
            )
            self.assertIn(contract["rtl"], compile_sources, module)
            self.assertIn(filelist, closure, module)
            self.assertNotIn(filelist, compile_sources, module)

        args = ooc.build_parser().parse_args([
            "emit-child-compile-sources", "--module", "OooFpAddSubPipe"
        ])
        self.assertIs(args.function, ooc.command_emit_child_compile_sources)

        runner = (
            registry.REPO_ROOT
            / "npc/rv64/eval/ppa/run-fp-ooc-composite-current.sh"
        ).read_text(encoding="utf-8")
        ordered = (
            'emit-child-sources --module "${module}"',
            'sha256sum "${child_source_closure[@]}" '
            '>"${child_dir}/source-closure.sha256"',
            'emit-child-compile-sources --module "${module}"',
            'sha256sum "${child_compile_sources[@]}" '
            '>"${child_dir}/compile-sources.sha256"',
            '"${child_compile_sources[*]}" "${child_netlist}"',
        )
        positions = [runner.index(marker) for marker in ordered]
        self.assertEqual(sorted(positions), positions)
        self.assertNotIn(
            '"${child_source_closure[*]}" "${child_netlist}"', runner
        )
        self.assertNotIn('"${child_sources[*]}" "${child_netlist}"', runner)

    def test_real_a4_post_split_ports_canonicalize_and_mutations_fail_closed(
            self) -> None:
        evidence_dir = (
            registry.REPO_ROOT
            / ".github/task-runs/2026-08-10-rv64-fp-ooc-composite-ppa-9d8b-a4"
            / "evidence/fp-ooc-composite-v1"
        ).resolve()
        status_path = evidence_dir / "gate-status.txt"
        design_path = (
            evidence_dir / "children/OooFpAddSubPipe/synth-design.json"
        )
        self.assertEqual(
            "b0c1baa333535d879989f5a135ee6d47cf7f7381380a4b4eccc055c869267237",
            hashlib.sha256(status_path.read_bytes()).hexdigest(),
        )
        self.assertEqual(
            "2882f99f31ccb56999bfc1b3a87a4232cad68e94a0a65a8787a07436ec457ec2",
            hashlib.sha256(design_path.read_bytes()).hexdigest(),
        )
        status = status_path.read_text(encoding="utf-8")
        self.assertIn("STAGE=child-OooFpAddSubPipe-retained-netlist-manifest", status)
        self.assertIn("RETURN_CODE=2", status)
        module = "OooFpAddSubPipe"
        contract = self.projection["child_contracts"][module]
        modules = ooc._normalized_design_modules(design_path)
        ports_raw = modules[module]["ports"]
        raw_ports, ports, canonicalization = ooc.canonicalize_retained_ports(
            subject=module, ports_raw=ports_raw, child_contract=contract,
        )
        expected = {
            **{name: ("input", width)
               for name, width in contract["input_ports"].items()},
            **{name: ("output", width)
               for name, width in contract["output_ports"].items()},
        }
        actual = {
            row["name"]: (row["direction"], row["width"])
            for row in ports
        }
        self.assertEqual(expected, actual)
        self.assertEqual(273, len(raw_ports))
        self.assertEqual(273, canonicalization["raw_bit_count"])
        self.assertEqual(11, canonicalization["canonical_port_count"])
        self.assertEqual(273, canonicalization["canonical_bit_count"])
        self.assertEqual(273, len(canonicalization["raw_to_canonical"]))
        raw_by_name = {row["normalized_name"]: row for row in raw_ports}
        self.assertNotIn("offset", raw_by_name["frs1_value_i_0_"])
        self.assertEqual(1, raw_by_name["frs1_value_i_1_"]["offset"])

        next_bit = 2
        unsplit: dict[str, dict[str, object]] = {}
        for family, (direction, width) in expected.items():
            unsplit[family] = {
                "direction": direction,
                "bits": list(range(next_bit, next_bit + width)),
            }
            next_bit += width
        _, unsplit_ports, unsplit_canonicalization = (
            ooc.canonicalize_retained_ports(
                subject=module, ports_raw=unsplit, child_contract=contract,
            )
        )
        self.assertEqual(expected, {
            row["name"]: (row["direction"], row["width"])
            for row in unsplit_ports
        })
        self.assertEqual(11, unsplit_canonicalization["raw_port_count"])
        self.assertTrue(all(
            row["representation"] == "unsplit"
            for row in unsplit_canonicalization["raw_to_canonical"]
        ))
        metadata_unsplit = copy.deepcopy(unsplit)
        metadata_family = next(
            family for family in sorted(metadata_unsplit)
            if len(metadata_unsplit[family]["bits"]) > 1
        )
        metadata_unsplit[metadata_family].update({
            "offset": 0, "upto": 0, "signed": 0,
        })
        ooc.canonicalize_retained_ports(
            subject=module, ports_raw=metadata_unsplit,
            child_contract=contract,
        )

        def assert_ports_rejected(label: str, damaged: dict[str, object]) -> None:
            with self.subTest(port_mutation=label), self.assertRaises(ooc.EvidenceError):
                ooc.canonicalize_retained_ports(
                    subject=module, ports_raw=damaged, child_contract=contract,
                )

        for attribute in ("offset", "upto", "signed"):
            damaged = copy.deepcopy(unsplit)
            damaged[metadata_family][attribute] = 1
            assert_ports_rejected(f"unsplit-{attribute}-noncanonical", damaged)

        damaged = copy.deepcopy(ports_raw)
        del damaged["frs1_value_i_7_"]
        assert_ports_rejected("missing-index", damaged)
        damaged = copy.deepcopy(ports_raw)
        damaged["\\frs1_value_i_1_"] = copy.deepcopy(
            damaged["frs1_value_i_1_"]
        )
        assert_ports_rejected("duplicate-index", damaged)
        damaged = copy.deepcopy(ports_raw)
        damaged["frs1_value_i_01_"] = damaged.pop("frs1_value_i_1_")
        assert_ports_rejected("noncanonical-index", damaged)
        damaged = copy.deepcopy(ports_raw)
        damaged["frs1_value_i_2_"]["direction"] = "output"
        assert_ports_rejected("wrong-direction", damaged)
        damaged = copy.deepcopy(ports_raw)
        damaged["foreign_value_i_2_"] = damaged.pop("frs1_value_i_2_")
        assert_ports_rejected("wrong-family", damaged)
        damaged = copy.deepcopy(ports_raw)
        damaged["frs1_value_i_64_"] = damaged.pop("frs1_value_i_63_")
        damaged["frs1_value_i_64_"]["offset"] = 64
        assert_ports_rejected("out-of-range-index-offset", damaged)
        damaged = copy.deepcopy(ports_raw)
        damaged["frs1_value_i_2_"]["offset"] = 3
        assert_ports_rejected("wrong-offset", damaged)
        damaged = copy.deepcopy(ports_raw)
        damaged["frs1_value_i_2_"]["offset"] = 64
        assert_ports_rejected("out-of-range-offset", damaged)
        damaged = copy.deepcopy(ports_raw)
        damaged["frs1_value_i_2_"]["bits"].append(999999)
        assert_ports_rejected("non-scalar-split-bit", damaged)
        damaged = copy.deepcopy(ports_raw)
        damaged["frs1_value_i"] = {
            "direction": "input",
            "bits": [
                damaged[f"frs1_value_i_{index}_"]["bits"][0]
                for index in range(64)
            ],
        }
        assert_ports_rejected("split-unsplit-collision", damaged)

        # Consume the complete frozen A4 universe directly.  The stdlib cell
        # modules in synth-design.json are blackbox definitions, while the
        # OooFpAddSubPipe top contains all 7146 real mapped instances.
        identity = ooc.load_json(evidence_dir / "run-identity.json")
        whitelist_path = evidence_dir / "stdlib-leaf-whitelist.json"
        whitelist = ooc.load_json(whitelist_path)
        census_path = evidence_dir / "children/OooFpAddSubPipe/synth-census.json"
        census = ooc.parse_yosys_census(census_path)[module]
        full_design = ooc.load_json(design_path)
        self.assertGreater(len(full_design["modules"]), 1)
        manifest = ooc._manifest_payload(
            identity=identity, subject=module,
            netlist_sha256="a" * 64, netlist_size_bytes=1,
            design_json=design_path, census_json=census_path,
            stdlib_whitelist=whitelist_path, evidence_dir=evidence_dir,
        )
        self.assertEqual(raw_ports, manifest["raw_ports"])
        self.assertEqual(ports, manifest["ports"])
        self.assertEqual(canonicalization, manifest["port_canonicalization"])
        self.assertEqual(7146, len(manifest["instances"]))
        self.assertEqual(7146, len(manifest["leaf_cells"]))
        self.assertEqual(7146, sum(manifest["leaf_cell_census"].values()))
        self.assertEqual(
            census["num_cells_by_type"], manifest["leaf_cell_census"]
        )
        self.assertTrue(all(
            row["implementation_class"] == "standard_cell_leaf"
            for row in manifest["instances"]
        ))
        self.assertEqual(manifest, ooc.validate_netlist_manifest(
            manifest, expected_identity=identity, expected_subject=module,
            evidence_dir=evidence_dir, expected_netlist_sha256="a" * 64,
            expected_netlist_size_bytes=1,
        ))
        damaged_manifest = copy.deepcopy(manifest)
        original_direction = damaged_manifest["raw_ports"][0]["direction"]
        damaged_manifest["raw_ports"][0]["direction"] = (
            "input" if original_direction == "output" else "output"
        )
        unsigned = dict(damaged_manifest)
        unsigned.pop("manifest_id")
        damaged_manifest["manifest_id"] = ooc.canonical_sha256(unsigned)
        with self.assertRaises(ooc.EvidenceError):
            ooc.validate_netlist_manifest(
                damaged_manifest, expected_identity=identity,
                expected_subject=module, evidence_dir=evidence_dir,
                expected_netlist_sha256="a" * 64,
                expected_netlist_size_bytes=1,
            )
        damaged_manifest = copy.deepcopy(manifest)
        damaged_manifest["netlist_sha256"] = "b" * 64
        unsigned = dict(damaged_manifest)
        unsigned.pop("manifest_id")
        damaged_manifest["manifest_id"] = ooc.canonical_sha256(unsigned)
        with self.assertRaises(ooc.EvidenceError):
            ooc.validate_netlist_manifest(
                damaged_manifest, expected_identity=identity,
                expected_subject=module, evidence_dir=evidence_dir,
                expected_netlist_sha256="a" * 64,
                expected_netlist_size_bytes=1,
            )

        used_cell_type = sorted(census["num_cells_by_type"])[0]
        self.assertIn(used_cell_type, full_design["modules"])
        self.assertIn(used_cell_type, whitelist["cells"])
        with tempfile.TemporaryDirectory() as temporary:
            mutation_root = Path(temporary).resolve()
            mutation_census = mutation_root / "synth-census.json"
            mutation_design = mutation_root / "synth-design.json"
            mutation_whitelist = mutation_root / "stdlib-leaf-whitelist.json"
            mutation_census.write_text(
                census_path.read_text(encoding="utf-8"), encoding="utf-8"
            )

            for mutation in (
                "missing-blackbox",
                "false-blackbox",
                "nonempty-blackbox-body",
                "stdlib-rtl-name-collision",
                "whitelist-missing",
            ):
                damaged_design = copy.deepcopy(full_design)
                damaged_whitelist = copy.deepcopy(whitelist)
                definition = damaged_design["modules"][used_cell_type]
                if mutation == "missing-blackbox":
                    definition["attributes"].pop("blackbox")
                elif mutation == "false-blackbox":
                    definition["attributes"]["blackbox"] = "0" * 32
                elif mutation == "nonempty-blackbox-body":
                    definition["cells"] = {
                        "u_illegal_body": {"type": used_cell_type}
                    }
                elif mutation == "stdlib-rtl-name-collision":
                    definition["attributes"].pop("blackbox")
                    definition["cells"] = {
                        "u_rtl_body": {"type": used_cell_type}
                    }
                else:
                    damaged_whitelist["cells"].remove(used_cell_type)
                    whitelist_unsigned = dict(damaged_whitelist)
                    whitelist_unsigned.pop("whitelist_id")
                    damaged_whitelist["whitelist_id"] = ooc.canonical_sha256(
                        whitelist_unsigned
                    )
                mutation_design.write_text(
                    json.dumps(damaged_design, sort_keys=True) + "\n",
                    encoding="utf-8",
                )
                mutation_whitelist.write_text(
                    json.dumps(damaged_whitelist, sort_keys=True) + "\n",
                    encoding="utf-8",
                )
                with self.subTest(blackbox_mutation=mutation), self.assertRaises(
                        ooc.EvidenceError):
                    ooc._manifest_payload(
                        identity=identity, subject=module,
                        netlist_sha256="a" * 64, netlist_size_bytes=1,
                        design_json=mutation_design,
                        census_json=mutation_census,
                        stdlib_whitelist=mutation_whitelist,
                        evidence_dir=mutation_root,
                    )
        print(
            "[A4-STDLIB-BLACKBOX-LEAF-CLASSIFICATION][PASS] "
            f"modules={len(full_design['modules'])} "
            f"stdlib_definitions={len(set(full_design['modules']) & set(whitelist['cells']))} "
            "leaf_instances=7146 raw_ports=273 canonical_families=11 "
            "blackbox_mutations=5 orientation_mutations=3"
        )

    def test_opensta_exact_port_family_tcl_semantics(self) -> None:
        child_tcl_path = (
            registry.REPO_ROOT / "npc/rv64/eval/ppa/opensta-fp-ooc-child.tcl"
        )
        child_tcl = child_tcl_path.read_text(encoding="utf-8")
        proc_prefix = child_tcl[:child_tcl.index("\nproc register_d_pins")]
        self.assertIn(
            "set underscore_pattern [format {^%s_([0-9]+)_$} $family]",
            proc_prefix,
        )
        self.assertNotRegex(proc_prefix, r'regexp\s+"')

        a5_root = (
            registry.REPO_ROOT
            / ".github/task-runs/2026-08-10-rv64-fp-ooc-composite-ppa-9d8b-a5"
            / "evidence/fp-ooc-composite-v1"
        )
        a5_status = a5_root / "gate-status.txt"
        a5_manifest_path = (
            a5_root / "children/OooFpAddSubPipe/netlist-manifest.json"
        )
        self.assertEqual(
            "82609bd249ce2d8d8fca400ae17ffc8d440886a3ca723b77dad06e07b437c369",
            hashlib.sha256(a5_status.read_bytes()).hexdigest(),
        )
        self.assertEqual(
            "cf6e0125b1970d38cadd4af03e5e8896daeb6bec5fa074b739f98aa60de61bc9",
            hashlib.sha256(a5_manifest_path.read_bytes()).hexdigest(),
        )
        self.assertIn(
            "STAGE=child-OooFpAddSubPipe-opensta-max",
            a5_status.read_text(encoding="utf-8"),
        )
        a5_manifest = json.loads(a5_manifest_path.read_text(encoding="utf-8"))
        a5_names = [
            str(row["name"])
            for row in a5_manifest["raw_ports"]
            if re.fullmatch(r"frs1_value_i_[0-9]+_", str(row["name"]))
        ]
        self.assertEqual(64, len(a5_names))
        self.assertEqual(
            {"input"},
            {
                str(row["direction"])
                for row in a5_manifest["raw_ports"]
                if str(row["name"]) in set(a5_names)
            },
        )

        def tcl_atom(value: str) -> str:
            self.assertNotRegex(value, r"[{}\\\r\n]")
            return "{" + value + "}"

        legacy_proc = r'''
proc exact_port_family {family width direction} {
  set result {}
  foreach port [get_ports *] {
    set name [get_full_name $port]
    if {($name eq $family ||
         [regexp "^${family}(?:\\\[[0-9]+\\\]|__v[0-9]+)$" $name]) &&
        [get_property $port direction] eq $direction} {
      lappend result $port
    }
  }
  if {[collection_count $result] != $width} {
    error "port family $family/$direction cardinality differs from $width"
  }
  return $result
}
'''

        def run_case(
                family: str, width: int, direction: str,
                ports: list[tuple[str, str]], *, legacy: bool = False,
        ) -> subprocess.CompletedProcess[str]:
            registrations = "\n".join(
                f"register_stub_port p{index} {tcl_atom(name)} {tcl_atom(port_direction)}"
                for index, (name, port_direction) in enumerate(ports)
            )
            override = legacy_proc if legacy else ""
            script = f'''{proc_prefix}
set ::port_objects {{}}
array set ::port_names {{}}
array set ::port_directions {{}}
proc register_stub_port {{object name direction}} {{
  lappend ::port_objects $object
  set ::port_names($object) $name
  set ::port_directions($object) $direction
}}
proc get_ports {{pattern}} {{
  if {{$pattern ne "*"}} {{ error "stub get_ports only accepts *" }}
  return $::port_objects
}}
proc get_full_name {{object}} {{ return $::port_names($object) }}
proc get_property {{object property}} {{
  if {{$property ne "direction"}} {{ error "unsupported property: $property" }}
  return $::port_directions($object)
}}
{override}
{registrations}
set code [catch {{exact_port_family {tcl_atom(family)} {width} {tcl_atom(direction)}}} result]
if {{$code != 0}} {{
  puts stderr $result
  exit 23
}}
set names {{}}
foreach object $result {{ lappend names [get_full_name $object] }}
puts [join $names {{|}}]
'''
            return subprocess.run(
                ["tclsh"], input=script, text=True, capture_output=True,
                check=False,
                env={
                    "PATH": os.environ.get("PATH", "/usr/bin:/bin"),
                    "LC_ALL": "C",
                    "LANG": "C",
                },
            )

        positive_cases = (
            (
                "a5-underscore", "frs1_value_i", 64, "input",
                [(name, "input") for name in a5_names],
                [f"frs1_value_i_{index}_" for index in range(64)],
            ),
            (
                "bracket", "bracket_bus", 4, "input",
                [(f"bracket_bus[{index}]", "input") for index in (2, 0, 3, 1)],
                [f"bracket_bus[{index}]" for index in range(4)],
            ),
            (
                "splitnets", "split_bus", 4, "output",
                [(f"split_bus__v{index}", "output") for index in (3, 1, 0, 2)],
                [f"split_bus__v{index}" for index in range(4)],
            ),
            (
                "scalar", "flush_i", 1, "input",
                [("flush_i", "input")], ["flush_i"],
            ),
        )
        for label, family, width, direction, ports, expected in positive_cases:
            with self.subTest(positive=label):
                completed = run_case(family, width, direction, ports)
                self.assertEqual(0, completed.returncode, completed.stderr)
                self.assertEqual(expected, completed.stdout.strip().split("|"))

        vector = lambda names: [(name, "input") for name in names]
        negative_cases = (
            (
                "missing-index",
                vector(["probe[0]", "probe[1]", "probe[3]"]),
                "missing index 2",
            ),
            (
                "duplicate-index",
                vector(["probe[0]", "probe[0]", "probe[1]", "probe[2]", "probe[3]"]),
                "duplicates index 0",
            ),
            (
                "leading-zero",
                vector(["probe[00]", "probe[1]", "probe[2]", "probe[3]"]),
                "noncanonical index",
            ),
            (
                "out-of-range",
                vector(["probe[0]", "probe[1]", "probe[2]", "probe[4]"]),
                "outside 0..3",
            ),
            (
                "wrong-direction",
                [("probe[0]", "input"), ("probe[1]", "output"),
                 ("probe[2]", "input"), ("probe[3]", "input")],
                "wrong-direction object",
            ),
            (
                "near-family",
                vector([f"probe_near[{index}]" for index in range(4)]),
                "must use one indexed representation",
            ),
            (
                "mixed-style",
                vector(["probe[0]", "probe__v1", "probe[2]", "probe[3]"]),
                "mixes bracket and splitnets",
            ),
        )
        for label, ports, expected_error in negative_cases:
            with self.subTest(negative=label):
                completed = run_case("probe", 4, "input", ports)
                self.assertEqual(23, completed.returncode, completed.stdout)
                self.assertIn(expected_error, completed.stderr)

        legacy = run_case(
            "probe", 4, "input",
            vector([f"probe[{index}]" for index in range(4)]), legacy=True,
        )
        self.assertEqual(23, legacy.returncode, legacy.stdout)
        self.assertIn('invalid command name "0-9"', legacy.stderr)
        print(
            "[A5-OPENSTA-EXACT-PORT-FAMILY][PASS] "
            "actual_family=frs1_value_i style=underscore width=64 "
            "positive_styles=4 negative_mutations=8"
        )

    def test_a6_arc_inventory_port_family_parser_is_strict(self) -> None:
        a6_manifest_path = (
            registry.REPO_ROOT
            / ".github/task-runs/2026-08-10-rv64-fp-ooc-composite-ppa-9d8b-a6"
            / "evidence/fp-ooc-composite-v1/children/OooFpAddSubPipe/"
              "netlist-manifest.json"
        )
        self.assertEqual(
            "31ffc36295bdcd99f61db3d0dcd0af8e5ec798076a6f1987809b3b967641139d",
            hashlib.sha256(a6_manifest_path.read_bytes()).hexdigest(),
        )
        manifest = json.loads(a6_manifest_path.read_text(encoding="utf-8"))
        actual_names = sorted(
            str(row["name"])
            for row in manifest["raw_ports"]
            if re.fullmatch(r"frs1_value_i_[0-9]+_", str(row["name"]))
        )
        self.assertEqual(64, len(actual_names))
        self.assertEqual(
            "underscore",
            ooc._validate_port_object_family_names(
                actual_names, family="frs1_value_i", width=64,
                label="a6.OooFpAddSubPipe.frs1_value_i",
            ),
        )

        driver_contract = self.dynamic_output_driver_contract(
            "OooFpAddSubPipe"
        )
        output_bit_inventory = self.dynamic_output_bit_inventory(
            "OooFpAddSubPipe", "max", driver_contract
        )
        inventory = self.arc_inventory("OooFpAddSubPipe", "max")
        for row in inventory:
            if row["port_family"] == "frs1_value_i":
                row["object_names"] = actual_names
                if row["arc_class"] in {"setup", "hold"}:
                    row["startpoint"] = actual_names[0]
        ooc.validate_arc_inventory(
            inventory, module="OooFpAddSubPipe", analysis="max",
            output_bit_inventory=output_bit_inventory,
            driver_contract=driver_contract,
        )

        positive = (
            ("scalar", ["flush_i"], "flush_i", 1, "scalar"),
            ("bracket", [f"probe[{i}]" for i in range(4)], "probe", 4, "bracket"),
            ("splitnets", [f"probe__v{i}" for i in range(4)], "probe", 4, "splitnets"),
            ("underscore", [f"probe_{i}_" for i in range(4)], "probe", 4, "underscore"),
        )
        for label, names, family, width, expected_style in positive:
            with self.subTest(positive=label):
                self.assertEqual(
                    expected_style,
                    ooc._validate_port_object_family_names(
                        sorted(names), family=family, width=width, label=label,
                    ),
                )

        negative = (
            ("leading-zero", ["probe_00_", "probe_1_", "probe_2_", "probe_3_"], 4),
            ("missing-index", ["probe_0_", "probe_1_", "probe_3_"], 4),
            ("out-of-range", ["probe_0_", "probe_1_", "probe_2_", "probe_4_"], 4),
            ("mixed-style", ["probe_0_", "probe__v1", "probe_2_", "probe_3_"], 4),
            ("duplicate-index", ["probe_0_", "probe_0_"], 2),
            ("near-name", [f"probe_near_{i}_" for i in range(4)], 4),
            ("vector-as-scalar", ["probe"], 2),
            (
                "different-owner-continuous-index",
                [f"u{index}/probe_{index}_" for index in range(4)], 4,
            ),
            (
                "uniform-fake-owner",
                [f"u_fake/probe_{index}_" for index in range(4)], 4,
            ),
            (
                "mixed-owner",
                ["probe_0_", "u_fake/probe_1_", "probe_2_", "probe_3_"], 4,
            ),
            ("slash-scalar-alias", ["u_fake/probe"], 1),
        )
        for label, names, width in negative:
            with self.subTest(negative=label), self.assertRaises(ooc.EvidenceError):
                ooc._validate_port_object_family_names(
                    sorted(names), family="probe", width=width, label=label,
                )

        forged_inventory = copy.deepcopy(inventory)
        for row in forged_inventory:
            if (row["arc_class"] == "setup" and
                    row["port_family"] == "frs1_value_i"):
                row["object_names"] = sorted(
                    f"u{index}/frs1_value_i_{index}_" for index in range(64)
                )
                row["startpoint"] = row["object_names"][0]
        with self.assertRaises(ooc.EvidenceError):
            ooc.validate_arc_inventory(
                forged_inventory, module="OooFpAddSubPipe", analysis="max",
                output_bit_inventory=output_bit_inventory,
                driver_contract=driver_contract,
            )
        print(
            "[A6-ARC-PORT-FAMILY-OWNER-ISOMORPHISM][PASS] "
            "actual_style=underscore actual_width=64 positive_styles=4 "
            "negative_mutations=11 cross_owner_public_oracle=1 "
            "hierarchical_pin_endpoints_preserved=1"
        )

    def test_literal_stdlib_timing_groups_are_structured_and_tied_off_only(
            self) -> None:
        standard_lib = (
            registry.REPO_ROOT
            / "yosys-sta/pdk/icsprout55/IP/STD_cell/"
              "ics55_LLSC_H7C_V1p10C100/ics55_LLSC_H7CL/liberty/"
              "ics55_LLSC_H7CL_typ_tt_1p2_25_nldm.lib"
        )
        bound = ooc._stdlib_output_pin_functions(
            standard_lib, {"TIELOH7L", "TIEHIH7L"},
        )
        self.assertEqual("0", bound["TIELOH7L"]["Z"])
        self.assertEqual("1", bound["TIEHIH7L"]["Z"])

        def literal_lib(timing_text: str) -> str:
            return (
                "library (structured_literal_test) {\n"
                "  cell (TIE_TEST) {\n"
                "    pin (Z) {\n"
                "      direction : output;\n"
                '      function : "0";\n'
                f"{timing_text}"
                "    }\n"
                "  }\n"
                "}\n"
            )

        positive = {
            "no-timing": "",
            "compact-tied-off": "      timing(){tied_off:true;}\n",
            "isolated-tied-off": (
                "      timing () {\n"
                "        tied_off : true;\n"
                "        output_current_rise (si_template) {\n"
                '          vector ("0.0");\n'
                "        }\n"
                "      }\n"
            ),
            "isolated-tied-off-resistance": (
                "      timing () {\n"
                "        tied_off : true;\n"
                "        steady_state_resistance_high : 1.25;\n"
                "        steady_state_current_high (si_template) {\n"
                '          vector ("0.0");\n'
                "        }\n"
                "      }\n"
            ),
            "comment-and-newline-heading": (
                "      timing /* heading comment */\n"
                "      (\n"
                "      )\n"
                "      {\n"
                "        tied_off : true;\n"
                "      }\n"
            ),
            "comment-only-fake-group": (
                "      /* timing () { related_pin : \"A\"; } */\n"
            ),
        }
        negative = {
            "ordinary-no-space": (
                "      timing() { related_pin : \"A\"; "
                "timing_type : combinational; }\n"
            ),
            "ordinary-newline": (
                "      timing\n      (\n      ) {\n"
                "        related_pin : \"A\";\n"
                "      }\n"
            ),
            "ordinary-comment-heading": (
                "      timing /* comment */ () {\n"
                "        related_pin : \"A\";\n"
                "      }\n"
            ),
            "missing-tied-off": "      timing () { }\n",
            "false-tied-off": (
                "      timing () { tied_off : false; }\n"
            ),
            "tied-off-related-pin": (
                "      timing () { tied_off : true; "
                "related_pin : \"A\"; }\n"
            ),
            "tied-off-ordinary-table": (
                "      timing () {\n"
                "        tied_off : true;\n"
                "        cell_rise (delay_template) { values (\"0.1\"); }\n"
                "      }\n"
            ),
            "mixed-groups": (
                "      timing () { tied_off : true; }\n"
                "      timing() { related_pin : \"A\"; }\n"
            ),
            "unsupported-attribute": (
                "      timing () { tied_off : true; "
                "default_timing : true; }\n"
            ),
            "unsupported-group": (
                "      timing () { tied_off : true; "
                "ordinary_table () { values (\"0.1\"); } }\n"
            ),
        }
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            for label, timing_text in positive.items():
                path = root / f"positive-{label}.lib"
                path.write_text(literal_lib(timing_text), encoding="utf-8")
                with self.subTest(positive=label):
                    self.assertEqual(
                        {"TIE_TEST": {"Z": "0"}},
                        ooc._stdlib_output_pin_functions(path, {"TIE_TEST"}),
                    )
            for label, timing_text in negative.items():
                path = root / f"negative-{label}.lib"
                path.write_text(literal_lib(timing_text), encoding="utf-8")
                with self.subTest(negative=label), self.assertRaises(
                        ooc.EvidenceError):
                    ooc._stdlib_output_pin_functions(path, {"TIE_TEST"})
        print(
            "[FP-OOC-STDLIB-TIED-OFF-PARSER][PASS] actual_ics55=2 "
            "positive=6 negative=10 whitespace_comment_invariant=1"
        )

    def test_a7_constant_output_driver_contract_bitwise_liberty_and_opensta(
            self) -> None:
        a7_root = (
            registry.REPO_ROOT
            / ".github/task-runs/2026-08-10-rv64-fp-ooc-composite-ppa-9d8b-a7"
            / "evidence/fp-ooc-composite-v1"
        )
        child_dir = a7_root / "children/OooFpAddSubPipe"
        design_path = child_dir / "synth-design.json"
        manifest_path = child_dir / "netlist-manifest.json"
        whitelist_path = a7_root / "stdlib-leaf-whitelist.json"
        standard_lib = (
            registry.REPO_ROOT
            / "yosys-sta/pdk/icsprout55/IP/STD_cell/"
              "ics55_LLSC_H7C_V1p10C100/ics55_LLSC_H7CL/liberty/"
              "ics55_LLSC_H7CL_typ_tt_1p2_25_nldm.lib"
        )
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        whitelist_value = json.loads(whitelist_path.read_text(encoding="utf-8"))
        self.assertEqual(
            manifest["inputs"]["design_json"]["sha256"],
            hashlib.sha256(design_path.read_bytes()).hexdigest(),
        )
        self.assertEqual(
            manifest["inputs"]["stdlib_whitelist"]["sha256"],
            hashlib.sha256(whitelist_path.read_bytes()).hexdigest(),
        )
        self.assertEqual(
            "55c129ca0f03a409622e6c309f7f2da3034a003323fc6f4e58ae2225ed416264",
            hashlib.sha256(standard_lib.read_bytes()).hexdigest(),
        )
        bindings = {
            "a7_design_sha256": manifest["inputs"]["design_json"]["sha256"],
            "a7_manifest_sha256": hashlib.sha256(
                manifest_path.read_bytes()
            ).hexdigest(),
            "a7_whitelist_sha256": manifest["inputs"]["stdlib_whitelist"][
                "sha256"
            ],
            "standard_cell_lib_sha256": hashlib.sha256(
                standard_lib.read_bytes()
            ).hexdigest(),
        }
        bits = ooc.classify_retained_output_bits(
            module="OooFpAddSubPipe", manifest=manifest,
            design_json=design_path, standard_cell_lib=standard_lib,
            whitelist=set(whitelist_value["cells"]), bindings=bindings,
        )
        self.assertEqual(138, len(bits))
        d_fflags = {
            int(bit["index"]): bit for bit in bits
            if bit["family"] == "addsub_d_fflags_q_o"
        }
        self.assertEqual(
            {0: "DYNAMIC", 1: "DYNAMIC", 2: "DYNAMIC",
             3: "CONSTANT_0", 4: "DYNAMIC"},
            {index: bit["classification"] for index, bit in d_fflags.items()},
        )
        s_constant = next(
            bit for bit in bits
            if bit["family"] == "addsub_s_fflags_q_o" and bit["index"] == 3
        )
        self.assertEqual(204, d_fflags[3]["net"])
        self.assertEqual(d_fflags[3]["net"], s_constant["net"])
        self.assertEqual(
            ("TIELOH7L", "Z", "0"),
            (d_fflags[3]["driver_cell_type"], d_fflags[3]["driver_pin"],
             d_fflags[3]["stdlib_function"]),
        )

        family_counts = {}
        for family, width in sorted(
                self.projection["child_contracts"]["OooFpAddSubPipe"][
                    "output_ports"
                ].items()):
            selected = [bit for bit in bits if bit["family"] == family]
            self.assertEqual(width, len(selected))
            family_counts[family] = {
                name: sum(bit["classification"] == name for bit in selected)
                for name in sorted(ooc.OUTPUT_BIT_CLASSES)
            }
        driver_contract = {
            "contract_id": ooc.canonical_sha256({"bindings": bindings, "bits": bits}),
            "bits": bits,
            "summary": {
                "bit_count": len(bits),
                "dynamic_count": sum(
                    bit["classification"] == "DYNAMIC" for bit in bits
                ),
                "constant_0_count": sum(
                    bit["classification"] == "CONSTANT_0" for bit in bits
                ),
                "constant_1_count": sum(
                    bit["classification"] == "CONSTANT_1" for bit in bits
                ),
                "family_counts": family_counts,
            },
        }
        self.assertEqual(
            driver_contract["summary"],
            ooc.validate_output_bit_driver_partition(
                driver_contract, module="OooFpAddSubPipe"
            ),
        )
        constant_base = {
            key: value for key, value in d_fflags[3].items()
            if key != "driver_binding_sha256"
        }
        self.assertEqual(
            d_fflags[3]["driver_binding_sha256"],
            ooc.canonical_sha256({"bindings": bindings, "bit": constant_base}),
        )
        replayed_bindings = dict(bindings)
        replayed_bindings["a7_manifest_sha256"] = "0" * 64
        self.assertNotEqual(
            d_fflags[3]["driver_binding_sha256"],
            ooc.canonical_sha256({
                "bindings": replayed_bindings, "bit": constant_base,
            }),
        )

        design_value = json.loads(design_path.read_text(encoding="utf-8"))
        cells = design_value["modules"]["OooFpAddSubPipe"]["cells"]
        tie_raw_name = next(
            name for name in cells
            if ooc._normalized_yosys_name(name) ==
            d_fflags[3]["driver_instance"]
        )
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            zero_driver = copy.deepcopy(design_value)
            del zero_driver["modules"]["OooFpAddSubPipe"]["cells"][tie_raw_name]
            zero_path = root / "zero-driver.json"
            zero_path.write_text(
                json.dumps(zero_driver, sort_keys=True), encoding="utf-8"
            )
            with self.assertRaises(ooc.EvidenceError):
                ooc.classify_retained_output_bits(
                    module="OooFpAddSubPipe", manifest=manifest,
                    design_json=zero_path, standard_cell_lib=standard_lib,
                    whitelist=set(whitelist_value["cells"]), bindings=bindings,
                )

            multiple_driver = copy.deepcopy(design_value)
            multiple_driver["modules"]["OooFpAddSubPipe"]["cells"][
                "duplicate_constant_driver"
            ] = copy.deepcopy(cells[tie_raw_name])
            multiple_path = root / "multiple-driver.json"
            multiple_path.write_text(
                json.dumps(multiple_driver, sort_keys=True), encoding="utf-8"
            )
            with self.assertRaises(ooc.EvidenceError):
                ooc.classify_retained_output_bits(
                    module="OooFpAddSubPipe", manifest=manifest,
                    design_json=multiple_path, standard_cell_lib=standard_lib,
                    whitelist=set(whitelist_value["cells"]), bindings=bindings,
                )

        reversed_function = copy.deepcopy(driver_contract)
        reversed_bit = next(
            bit for bit in reversed_function["bits"]
            if bit["classification"] == "CONSTANT_0"
        )
        reversed_bit["stdlib_function"] = "1"
        reversed_bit["stdlib_function_sha256"] = ooc.canonical_sha256("1")
        with self.assertRaises(ooc.EvidenceError):
            ooc.validate_output_bit_driver_partition(
                reversed_function, module="OooFpAddSubPipe"
            )
        timing_bits = []
        for bit in bits:
            dynamic = bit["classification"] == "DYNAMIC"
            timing_bits.append({
                "family": bit["family"],
                "index": bit["index"],
                "object_name": bit["opensta_object_name"],
                "classification": bit["classification"],
                "constant_value": bit["value"],
                "path_delay": "max",
                "path_count": 1 if dynamic else 0,
                "worst_path_delay_ns": 0.2 if dynamic else None,
                "worst_slack_ns": 4.7 if dynamic else None,
                "source_object_class": (
                    "REGISTER_Q" if dynamic else "STRUCTURAL_CONSTANT"
                ),
                "endpoint_object_class": "PORT",
                "startpoint": "u_q/Q" if dynamic else None,
                "endpoint": bit["opensta_object_name"] if dynamic else None,
                "driver_binding_sha256": bit["driver_binding_sha256"],
            })
        arcs = self.arc_inventory("OooFpAddSubPipe", "max")
        for arc in arcs:
            if arc["arc_class"] != "clk_to_q":
                continue
            selected = [
                row for row in timing_bits
                if row["family"] == arc["port_family"] and
                row["classification"] == "DYNAMIC"
            ]
            arc["observed_cardinality"] = len(selected)
            arc["path_count"] = len(selected)
            arc["object_names"] = sorted(row["object_name"] for row in selected)
            arc["startpoint"] = "u_q/Q" if selected else None
            arc["endpoint"] = arc["object_names"][0] if selected else None
            if not selected:
                arc["worst_path_delay_ns"] = None
                arc["worst_slack_ns"] = None
        metadata = ooc.liberty_metadata(
            identity=copy.deepcopy(self.identity), module="OooFpAddSubPipe",
            analysis="max", source_closure_sha256="a" * 64,
            timing_evidence_sha256="b" * 64, area_um2=12.5, cell_count=42,
            arc_inventory=arcs, output_bit_inventory=timing_bits,
            output_bit_driver_contract=driver_contract,
        )
        liberty_text = ooc.render_sequential_liberty(metadata)
        pins = dict(ooc._extract_liberty_named_groups(liberty_text, "pin"))
        buses = dict(ooc._extract_liberty_named_groups(liberty_text, "bus"))
        constant_pin = pins["addsub_d_fflags_q_o[3]"]
        dynamic_pin = pins["addsub_d_fflags_q_o[4]"]
        mixed_bus = buses["addsub_d_fflags_q_o"]
        self.assertNotIn("function :", mixed_bus.split("pin (")[0])
        self.assertNotIn("timing_type", mixed_bus.split("pin (")[0])
        self.assertIn('function : "0";', constant_pin)
        self.assertNotIn("timing_type", constant_pin)
        self.assertIn(
            'function : "fp_ooc_state__addsub_d_fflags_q_o__4";',
            dynamic_pin,
        )
        self.assertIn("timing_type : rising_edge;", dynamic_pin)
        ooc.validate_sequential_liberty(
            liberty_text, expected_identity=self.identity,
            expected_module="OooFpAddSubPipe", expected_analysis="max",
            expected_arc_inventory=arcs,
            expected_output_bit_inventory=timing_bits,
            expected_driver_contract_id=driver_contract["contract_id"],
        )
        liberty_mutations = {
            "bus-default-function": liberty_text.replace(
                "    bus (addsub_d_fflags_q_o) {\n"
                "      bus_type : bus_5;",
                "    bus (addsub_d_fflags_q_o) {\n"
                "      bus_type : bus_5;\n"
                '      function : "0";',
                1,
            ),
            "constant-function-reversal": liberty_text.replace(
                '        function : "0";', '        function : "1";', 1
            ),
            "constant-function-plus-timing": liberty_text.replace(
                '        function : "0";',
                '        function : "0";\n'
                "        timing_type : rising_edge;",
                1,
            ),
        }
        for label, damaged_liberty in liberty_mutations.items():
            with self.subTest(liberty_mutation=label), self.assertRaises(
                    ooc.EvidenceError):
                ooc.validate_sequential_liberty(
                    damaged_liberty, expected_identity=self.identity,
                    expected_module="OooFpAddSubPipe",
                    expected_analysis="max",
                    expected_arc_inventory=arcs,
                    expected_output_bit_inventory=timing_bits,
                    expected_driver_contract_id=driver_contract["contract_id"],
                )
        damaged = copy.deepcopy(timing_bits)
        damaged[next(index for index, row in enumerate(damaged)
                     if row["classification"] == "CONSTANT_0")]["path_count"] = 1
        with self.assertRaises(ooc.EvidenceError):
            ooc.validate_output_bit_timing_inventory(
                damaged, module="OooFpAddSubPipe", analysis="max",
                driver_contract=driver_contract,
            )
        missing_path_is_not_constant = copy.deepcopy(timing_bits)
        dynamic_index = next(
            index for index, row in enumerate(missing_path_is_not_constant)
            if row["classification"] == "DYNAMIC"
        )
        missing_path_is_not_constant[dynamic_index].update({
            "classification": "CONSTANT_0", "constant_value": 0,
            "path_count": 0, "worst_path_delay_ns": None,
            "worst_slack_ns": None,
            "source_object_class": "STRUCTURAL_CONSTANT",
            "startpoint": None, "endpoint": None,
        })
        with self.assertRaises(ooc.EvidenceError):
            ooc.validate_output_bit_timing_inventory(
                missing_path_is_not_constant, module="OooFpAddSubPipe",
                analysis="max", driver_contract=driver_contract,
            )

        child_tcl = (
            registry.REPO_ROOT / "npc/rv64/eval/ppa/opensta-fp-ooc-child.tcl"
        ).read_text(encoding="utf-8")
        proc_prefix = child_tcl[:child_tcl.index("\nset allowed_children")]
        opensta = Path("/home/lyg/tools/OpenSTA/build/sta")
        fixture = (
            registry.REPO_ROOT
            / "npc/rv64/eval/ppa/tests/fixtures/"
              "fp_ooc_constant_output_harness.v"
        )
        macro_fixture = (
            registry.REPO_ROOT
            / "npc/rv64/eval/ppa/tests/fixtures/"
              "fp_ooc_constant_macro_harness.v"
        )
        self.assertEqual(
            "50fb07e41cd448cbb6ee782cc552db9adff12ed5f98d02bcca97ea3d7c2dd788",
            hashlib.sha256(opensta.read_bytes()).hexdigest(),
        )
        script = proc_prefix + "\n" + "\n".join([
            f"read_liberty {{{standard_lib}}}",
            "read_liberty {__GENERATED_LIBERTY__}",
            f"read_verilog {{{macro_fixture}}}",
            f"read_verilog {{{fixture}}}",
            "link_design fp_ooc_constant_output_harness",
            "set fp_ooc_clock_origin_ns 0.0",
            "set fp_ooc_clock_source_latency_ns 0.0",
            "set fp_ooc_clock_network_latency_ns 0.0",
            "set fp_ooc_clock_insertion_ns 0.0",
            "set fp_ooc_clock_propagated 0",
            "set fp_ooc_input_seed_ns 0.0",
            "create_clock -name fp_ooc_clock -period 5.0 -waveform {0.0 2.5} [get_ports clk]",
            "set_clock_latency -source 0.0 [get_clocks fp_ooc_clock]",
            "set_clock_latency 0.0 [get_clocks fp_ooc_clock]",
            "set_input_delay 0.0 -clock fp_ooc_clock [get_ports data_i]",
            "set outputs [exact_port_family data_o 2 output]",
            "set_output_delay 0.0 -clock fp_ooc_clock $outputs",
            "set_output_delay 0.0 -clock fp_ooc_clock [get_ports macro_*]",
            "set q_pins [register_q_pins]",
            "set dynamic [dict create family data_o index 0 object [lindex $outputs 0] object_name [object_name [lindex $outputs 0]] classification DYNAMIC value - driver_binding_sha256 [string repeat a 64]]",
            "set constant [dict create family data_o index 1 object [lindex $outputs 1] object_name [object_name [lindex $outputs 1]] classification CONSTANT_0 value 0 driver_binding_sha256 [string repeat b 64]]",
            "set fp_ooc_progress_stream [open /dev/null w]",
            "configure_query_budget fp_ooc_constant_output_harness 1 1 2 1",
            "set output_contract [dict create [list data_o 0] $dynamic [list data_o 1] $constant]",
            "set output_rows [collect_output_timing_bulk $output_contract $q_pins max]",
            "set dynamic_row [lindex $output_rows 0]",
            "set constant_row [lindex $output_rows 1]",
            "if {[lindex $dynamic_row 6] < 1 || [lindex $dynamic_row 3] ne \"DYNAMIC\"} { error \"dynamic bit timing missing\" }",
            "if {[lindex $constant_row 6] != 0 || [lindex $constant_row 3] ne \"CONSTANT_0\"} { error \"constant bit timing forged\" }",
            "proc exact_harness_pin {expected} {",
            "  set matched [list]",
            "  foreach pin [get_pins -hierarchical *] {",
            "    if {[object_name $pin] eq $expected} { lappend matched $pin }",
            "  }",
            "  if {[llength $matched] != 1} { error \"expected one harness pin $expected, got [llength $matched]\" }",
            "  return [lindex $matched 0]",
            "}",
            "proc harness_pins_connected {first second} {",
            "  set found 0",
            "  set iterator [$first connected_pin_iterator]",
            "  while {[$iterator has_next]} {",
            "    if {[string equal [$iterator next] $second]} { set found 1 }",
            "  }",
            "  $iterator finish",
            "  return $found",
            "}",
            "proc assert_no_sdc_logic_seed {label pin} {",
            "  set case_value [::sta::pin_case_logic_value $pin]",
            "  set logic_value [::sta::pin_logic_value $pin]",
            "  if {$case_value ne \"X\" || $logic_value ne \"X\"} { error \"$label is contaminated by SDC logic seed\" }",
            "}",
            "foreach command {::sta::pin_sim_logic_value ::sta::pin_case_logic_value ::sta::pin_logic_value ::sta::get_port_pin get_timing_edges} {",
            "  if {[llength [info commands $command]] != 1} { error \"required OpenSTA command unavailable: $command\" }",
            "}",
            "set macro_clk_pin [exact_harness_pin {u_macro_harness/u_macro/clk}]",
            "set macro_dynamic_pin [exact_harness_pin {u_macro_harness/u_macro/addsub_d_fflags_q_o[4]}]",
            "set macro_constant_pin [exact_harness_pin {u_macro_harness/u_macro/addsub_d_fflags_q_o[3]}]",
            "set macro_constant_ports [get_ports macro_constant_o]",
            "if {[collection_count $macro_constant_ports] != 1} { error \"macro constant top-port census drifted\" }",
            "set macro_constant_top_pin [::sta::get_port_pin [lindex $macro_constant_ports 0]]",
            "if {$macro_constant_top_pin eq \"NULL\" || ![$macro_constant_top_pin is_top_level_port]} { error \"macro constant top port did not convert to a top-level Pin\" }",
            "if {![harness_pins_connected $macro_constant_pin $macro_constant_top_pin]} { error \"macro constant pin is not connected to the observed top port\" }",
            "set macro_constant_libpin [$macro_constant_pin liberty_port]",
            "set macro_dynamic_libpin [$macro_dynamic_pin liberty_port]",
            "if {$macro_constant_libpin eq \"NULL\" || $macro_dynamic_libpin eq \"NULL\"} { error \"generated macro output lacks Liberty pin ownership\" }",
            "if {[$macro_constant_libpin function] ne \"0\" || [$macro_constant_libpin tristate_enable] ne \"\"} { error \"generated macro constant pin is not a literal non-tristate 0\" }",
            "set macro_dynamic_function [$macro_dynamic_libpin function]",
            "if {$macro_dynamic_function eq \"0\" || $macro_dynamic_function eq \"1\"} { error \"generated macro dynamic pin inherited a literal function\" }",
            "assert_no_sdc_logic_seed macro_constant $macro_constant_pin",
            "assert_no_sdc_logic_seed top_constant $macro_constant_top_pin",
            "assert_no_sdc_logic_seed macro_dynamic $macro_dynamic_pin",
            "set macro_constant_value [::sta::pin_sim_logic_value $macro_constant_pin]",
            "set macro_constant_top_value [::sta::pin_sim_logic_value $macro_constant_top_pin]",
            "set macro_dynamic_value [::sta::pin_sim_logic_value $macro_dynamic_pin]",
            "if {$macro_constant_value ne \"0\" || $macro_constant_top_value ne \"0\"} { error \"generated macro constant did not propagate to its wrapper port\" }",
            "if {$macro_dynamic_value eq \"0\" || $macro_dynamic_value eq \"1\"} { error \"generated macro dynamic output was forged as a constant\" }",
            "set macro_dynamic_edge_count 0",
            "set macro_dynamic_arc_count 0",
            "foreach edge [get_timing_edges -from $macro_clk_pin -to $macro_dynamic_pin] {",
            "  if {[$edge role] eq \"Reg Clk to Q\"} {",
            "    incr macro_dynamic_edge_count",
            "    foreach arc [$edge timing_arcs] {",
            "      if {[$arc role] ne \"Reg Clk to Q\"} { error \"Reg-Q edge contains a non-Reg-Q arc\" }",
            "      incr macro_dynamic_arc_count",
            "    }",
            "  }",
            "}",
            "set macro_constant_reg_edge_count 0",
            "set macro_constant_nonwire_edge_count 0",
            "foreach edge [get_timing_edges -to $macro_constant_pin] {",
            "  if {[$edge role] eq \"Reg Clk to Q\"} { incr macro_constant_reg_edge_count }",
            "  if {[$edge role] ne \"wire\"} { incr macro_constant_nonwire_edge_count }",
            "}",
            "if {$macro_dynamic_edge_count < 1 || $macro_dynamic_arc_count < 1} { error \"generated macro dynamic output lacks a real Reg Clk to Q arc\" }",
            "if {$macro_constant_reg_edge_count != 0 || $macro_constant_nonwire_edge_count != 0} { error \"generated macro constant output carries a forged timing edge\" }",
            'puts "\\[FP-OOC-CONSTANT-OUTPUT-HARNESS\\]\\[PASS\\] dynamic_paths=[lindex $dynamic_row 6] constant_paths=[lindex $constant_row 6] generated_macro_constant=$macro_constant_value generated_top_constant=$macro_constant_top_value generated_dynamic_value=$macro_dynamic_value generated_dynamic_edges=$macro_dynamic_edge_count generated_dynamic_arcs=$macro_dynamic_arc_count generated_constant_reg_edges=$macro_constant_reg_edge_count"',
            "exit",
            "",
        ])
        with tempfile.TemporaryDirectory() as temp_dir:
            generated_liberty_path = Path(temp_dir) / "mixed-output-model.lib"
            generated_liberty_path.write_text(liberty_text, encoding="utf-8")
            script = script.replace(
                "__GENERATED_LIBERTY__", str(generated_liberty_path)
            )
            script_path = Path(temp_dir) / "constant-output-harness.tcl"
            script_path.write_text(script, encoding="utf-8")
            completed = subprocess.run(
                [str(opensta), str(script_path)], cwd=registry.REPO_ROOT,
                text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                check=False, timeout=120,
            )
        self.assertEqual(0, completed.returncode, completed.stdout)
        self.assertIn("[FP-OOC-CONSTANT-OUTPUT-HARNESS][PASS]", completed.stdout)
        print(
            "[A7-FP-OOC-CONSTANT-OUTPUT][PASS] bits=138 "
            "d_fflags_dynamic=0,1,2,4 d_fflags_constant0=3 "
            "shared_net=204 structural_mutations=4 liberty_mutations=3 "
            "real_opensta_mixed_output=PASS generated_macro=PASS"
        )

    def test_opensta_bulk_query_budget_harness_and_mutations(self) -> None:
        child_tcl_path = (
            registry.REPO_ROOT / "npc/rv64/eval/ppa/opensta-fp-ooc-child.tcl"
        )
        child_tcl = child_tcl_path.read_text(encoding="utf-8")
        proc_prefix = child_tcl[:child_tcl.index("\nset allowed_children")]
        self.assertEqual(1, child_tcl.count("find_timing_paths -from"))
        self.assertNotIn("group_path_count 100000", child_tcl)
        measured = proc_prefix[
            proc_prefix.index("proc measured_path_delay_ns"):
            proc_prefix.index("\nproc parse_port_contract")
        ]
        self.assertNotIn("validate_path_end", measured)

        opensta = Path("/home/lyg/tools/OpenSTA/build/sta")
        liberty = (
            registry.REPO_ROOT
            / "yosys-sta/pdk/icsprout55/IP/STD_cell/"
              "ics55_LLSC_H7C_V1p10C100/ics55_LLSC_H7CL/liberty/"
              "ics55_LLSC_H7CL_typ_tt_1p2_25_nldm.lib"
        )
        fixture = (
            registry.REPO_ROOT
            / "npc/rv64/eval/ppa/tests/fixtures/"
              "fp_ooc_bulk_query_budget_harness.v"
        )
        opensta_sha = hashlib.sha256(opensta.read_bytes()).hexdigest()
        liberty_sha = hashlib.sha256(liberty.read_bytes()).hexdigest()
        fixture_sha = hashlib.sha256(fixture.read_bytes()).hexdigest()
        self.assertEqual(
            "50fb07e41cd448cbb6ee782cc552db9adff12ed5f98d02bcca97ea3d7c2dd788",
            opensta_sha,
        )
        self.assertEqual(
            "55c129ca0f03a409622e6c309f7f2da3034a003323fc6f4e58ae2225ed416264",
            liberty_sha,
        )

        def tcl_path(path: Path) -> str:
            rendered = str(path.resolve())
            self.assertNotRegex(rendered, r"[{}\\\r\n]")
            return "{" + rendered + "}"

        script = f'''{proc_prefix}
read_liberty {tcl_path(liberty)}
read_verilog {tcl_path(fixture)}
link_design fp_ooc_bulk_query_budget_harness
set fp_ooc_clock_origin_ns 0.0
set fp_ooc_clock_source_latency_ns 0.0
set fp_ooc_clock_network_latency_ns 0.0
set fp_ooc_clock_insertion_ns 0.0
set fp_ooc_clock_propagated 0
set fp_ooc_input_seed_ns 0.0
create_clock -name fp_ooc_clock -period 5.0 -waveform {{0.0 2.5}} [get_ports clk]
set_clock_latency -source 0.0 [get_clocks fp_ooc_clock]
set_clock_latency 0.0 [get_clocks fp_ooc_clock]
set data_objects [exact_port_family data_i 2 input]
set dynamic_objects [exact_port_family dynamic_o 2 output]
set constant_objects [exact_port_family constant_o 1 output]
set_input_delay 0.0 -clock fp_ooc_clock $data_objects
set_output_delay 0.0 -clock fp_ooc_clock [concat $dynamic_objects $constant_objects]
set_input_transition 0.02 $data_objects
set_load 0.01 [concat $dynamic_objects $constant_objects]
set d_pins [register_d_pins]
set q_pins [register_q_pins]
set q_names [object_name_list $q_pins]
set dynamic_names [object_name_list $dynamic_objects]

proc require_close {{actual expected label}} {{
  if {{abs($actual - $expected) > 1.0e-9}} {{
    error "$label mismatch: actual=$actual expected=$expected"
  }}
}}
proc expect_failure {{script label}} {{
  if {{![catch {{uplevel 1 $script}} message]}} {{
    error "$label unexpectedly passed"
  }}
  return $message
}}
proc raw_output_observations {{paths q_names output_names analysis}} {{
  set result {{}}
  set role [expr {{$analysis eq "max" ? "output setup" : "output hold"}}]
  foreach path $paths {{
    set observation [validate_path_end $path raw_output $analysis [list $role] \\
      $q_names $output_names]
    dict set observation delay_ns [measured_path_delay_ns $observation raw_output \\
      register_q_to_output]
    lappend result $observation
  }}
  return $result
}}
proc delay_extreme {{observations analysis}} {{
  set selected {{}}
  foreach observation $observations {{
    if {{$selected eq "" ||
        ($analysis eq "max" && [dict get $observation delay_ns] > [dict get $selected delay_ns]) ||
        ($analysis eq "min" && [dict get $observation delay_ns] < [dict get $selected delay_ns])}} {{
      set selected $observation
    }}
  }}
  return $selected
}}

set dynamic0 [dict create family dynamic_o index 0 object [lindex $dynamic_objects 0] \\
  object_name [lindex $dynamic_names 0] classification DYNAMIC value - \\
  driver_binding_sha256 [string repeat a 64]]
set dynamic1 [dict create family dynamic_o index 1 object [lindex $dynamic_objects 1] \\
  object_name [lindex $dynamic_names 1] classification DYNAMIC value - \\
  driver_binding_sha256 [string repeat b 64]]
set constant [dict create family constant_o index 0 object [lindex $constant_objects 0] \\
  object_name [object_name [lindex $constant_objects 0]] classification CONSTANT_0 value 0 \\
  driver_binding_sha256 [string repeat c 64]]
set output_contract [dict create [list dynamic_o 0] $dynamic0 \\
  [list dynamic_o 1] $dynamic1 [list constant_o 0] $constant]

# Exact positive production-shaped ledger: 4 path classes, 2x2 input queries,
# and one output bulk query.  BEGIN/COMPLETE rows must close at 9 calls/14
# PathEnds/14 validations before any mutation starts.
set fp_ooc_progress_stream [open __PROGRESS__ w]
puts $fp_ooc_progress_stream "schema\t{ooc.QUERY_PROGRESS_SCHEMA}"
puts $fp_ooc_progress_stream "run_id\t{self.identity['run_id']}"
puts $fp_ooc_progress_stream "design_id\t{self.identity['design_id']}"
puts $fp_ooc_progress_stream "subject\tfp_ooc_bulk_query_budget_harness"
puts $fp_ooc_progress_stream "analysis\tmax"
puts $fp_ooc_progress_stream "phase_marker\tpre_link\tBEGIN"
puts $fp_ooc_progress_stream "phase_marker\tlink\tCOMPLETE"
configure_query_budget fp_ooc_bulk_query_budget_harness 2 2 3 2
collect_path_class port_to_register $data_objects $d_pins max PORT REGISTER_D
collect_path_class register_to_register $q_pins $d_pins max REGISTER_Q REGISTER_D
collect_path_class register_to_port $q_pins $dynamic_objects max REGISTER_Q PORT
collect_path_class synchronous_control_to_register $data_objects $d_pins max PORT REGISTER_D
set setup_row [collect_arc_family setup data_i $data_objects $d_pins max 2 PORT REGISTER_D]
set hold_row [collect_arc_family hold data_i $data_objects $d_pins min 2 PORT REGISTER_D]
if {{[lindex $setup_row 11] ne [object_name [lindex $data_objects 0]]}} {{
  error "non-final input source was not retained as setup worst"
}}
set max_rows [collect_output_timing_bulk $output_contract $q_pins max]
verify_query_budget
set focused_find_calls $fp_ooc_find_calls
set focused_pathends $fp_ooc_pathend_count
set focused_validations $fp_ooc_validation_count
puts $fp_ooc_progress_stream "phase_marker\treport\tBEGIN"
puts $fp_ooc_progress_stream "phase_marker\treport\tCOMPLETE"
puts $fp_ooc_progress_stream "completion_marker\t\\[FP-OOC-QUERY-BUDGET\\]\\[PASS\\]"
close $fp_ooc_progress_stream
set max_dynamic0 [lindex $max_rows 1]
set max_dynamic1 [lindex $max_rows 2]
set max_constant [lindex $max_rows 0]

# A second budget instance proves max observations are ordinary Tcl values and
# remain valid after the min bulk search.
set fp_ooc_progress_stream [open /dev/null w]
configure_query_budget fp_ooc_bulk_query_budget_harness 2 2 3 2
set min_rows [collect_output_timing_bulk $output_contract $q_pins min]
set min_dynamic0 [lindex $min_rows 1]
if {{[lindex $max_constant 6] != 0 || [lindex $max_constant 3] ne "CONSTANT_0" ||
    [lindex $max_dynamic0 6] != 1 || [lindex $max_dynamic1 6] != 1 ||
    [lindex $min_dynamic0 6] != 1}} {{
  error "bulk output join did not preserve 2 dynamic plus 1 constant partition"
}}
if {{[lindex $max_dynamic1 7] <= [lindex $max_dynamic0 7]}} {{
  error "fixture non-first endpoint is not the maximum raw-delay endpoint"
}}

# Two Q launch paths share dynamic_o[0].  Under uniform required time, the
# endpoint_path_count=1 max/min candidates must equal raw delay extrema.
foreach sense {{max min}} {{
  set paths [find_timing_paths -from $q_pins -to [list [lindex $dynamic_objects 0]] \\
    -path_delay $sense -endpoint_path_count 2 -group_path_count 2 -sort_by_slack]
  if {{[collection_count $paths] != 2}} {{ error "two-launch reference census drifted" }}
  set observations [raw_output_observations $paths $q_names \\
    [list [lindex $dynamic_names 0]] $sense]
  set extreme [delay_extreme $observations $sense]
  if {{$sense eq "max"}} {{
    set bulk_row $max_dynamic0
  }} else {{
    set bulk_row $min_dynamic0
  }}
  require_close [lindex $bulk_row 7] [dict get $extreme delay_ns] \\
    "$sense uniform-required raw-delay extreme"
}}
set uniform_paths [find_timing_paths -from $q_pins -to $dynamic_objects \\
  -path_delay max -endpoint_path_count 1 -group_path_count 2 -sort_by_slack]
set uniform_observations [raw_output_observations $uniform_paths $q_names $dynamic_names max]
if {{[llength $uniform_observations] != 2}} {{
  error "focused positive constraint lost an endpoint"
}}
set uniform_required0 [dict get [lindex $uniform_observations 0] required_ns]
set uniform_required1 [dict get [lindex $uniform_observations 1] required_ns]
if {{abs($uniform_required0 - $uniform_required1) > 2.0e-6}} {{
  error "focused positive constraint required-time drift: $uniform_required0 vs $uniform_required1"
}}

set mutations 0
# 1. A Q-driven endpoint cannot be relabelled as structural constant.
configure_query_budget fp_ooc_bulk_query_budget_harness 2 2 3 2
set bad_constant $dynamic0
dict set bad_constant classification CONSTANT_0
dict set bad_constant value 0
set bad_contract [dict replace $output_contract [list dynamic_o 0] $bad_constant]
expect_failure [list collect_output_timing_bulk $bad_contract $q_pins max] constant_to_q
incr mutations

# 2. A disconnected/tied endpoint cannot be relabelled dynamic.
configure_query_budget fp_ooc_bulk_query_budget_harness 2 2 3 2
set bad_dynamic $constant
dict set bad_dynamic classification DYNAMIC
dict set bad_dynamic value -
set bad_contract [dict replace $output_contract [list constant_o 0] $bad_dynamic]
expect_failure [list collect_output_timing_bulk $bad_contract $q_pins max] dynamic_disconnected
incr mutations

# 3. dynamic_count-1 group cap must be detected as endpoint truncation.
set truncated [find_timing_paths -from $q_pins -to [concat $dynamic_objects $constant_objects] \\
  -path_delay max -endpoint_path_count 1 -group_path_count 1 -sort_by_slack]
set truncated_observations [materialize_output_paths $truncated $output_contract \\
  $q_names [concat $dynamic_names [object_name_list $constant_objects]] max]
expect_failure [list output_rows_from_observations $output_contract \\
  $truncated_observations max] group_cap_minus_one
incr mutations

# 4. A second production search is rejected while the first Search-owned
# PathEnd is live.  Materialize and close the first query before continuing;
# never dereference a freed PathEnd as a negative oracle (OpenSTA 3.1 rightly
# treats that as an invalid native pointer, not a recoverable Tcl exception).
configure_query_budget fp_ooc_bulk_query_budget_harness 2 2 3 2
set held_paths [budgeted_find_timing_paths $q_pins \
  [list [lindex $dynamic_objects 0]] max 1 1 output_bulk lifetime_guard]
expect_failure [list budgeted_find_timing_paths $q_pins \
  [list [lindex $dynamic_objects 1]] max 1 1 output_bulk forbidden_overlap] \
  cross_search_pathend
raw_output_observations $held_paths $q_names \
  [list [lindex $dynamic_names 0]] max
complete_timing_query $held_paths output_bulk lifetime_guard max 1 1
unset held_paths
incr mutations

# 5. A min PathEnd cannot satisfy the max-sense validator.
set min_paths [find_timing_paths -from $q_pins -to [list [lindex $dynamic_objects 0]] \\
  -path_delay min -endpoint_path_count 1 -group_path_count 1 -sort_by_slack]
expect_failure [list validate_path_end [lindex $min_paths 0] wrong_sense max \\
  [list {{output setup}}] $q_names [list [lindex $dynamic_names 0]]] sense_inverted
incr mutations

# 6. Nonuniform required time makes a slack-only group-cap=1 oracle choose a
# different endpoint from raw max delay.  Production bulk keeps both endpoints
# and therefore still derives the raw-delay extreme after scalarization.
set_output_delay 4.8 -clock fp_ooc_clock [list [lindex $dynamic_objects 0]]
set_output_delay 0.0 -clock fp_ooc_clock [list [lindex $dynamic_objects 1]]
set slack_only [find_timing_paths -from $q_pins -to $dynamic_objects \\
  -path_delay max -endpoint_path_count 1 -group_path_count 1 -sort_by_slack]
set slack_observation [lindex [raw_output_observations $slack_only $q_names $dynamic_names max] 0]
set full_paths [find_timing_paths -from $q_pins -to $dynamic_objects \\
  -path_delay max -endpoint_path_count 1 -group_path_count 2 -sort_by_slack]
set full_observations [raw_output_observations $full_paths $q_names $dynamic_names max]
set raw_max [delay_extreme $full_observations max]
if {{[dict get $slack_observation endpoint] eq [dict get $raw_max endpoint]}} {{
  error "nonuniform-required mutation did not separate slack and raw delay"
}}
configure_query_budget fp_ooc_bulk_query_budget_harness 2 2 3 2
set nonuniform_rows [collect_output_timing_bulk $output_contract $q_pins max]
set aggregate [aggregate_output_family dynamic_o 2 $nonuniform_rows max]
if {{[lindex $aggregate 12] ne [dict get $raw_max endpoint]}} {{
  error "production bulk failed to retain raw-delay extreme under nonuniform required time"
}}
incr mutations

if {{$mutations != 6}} {{ error "focused mutation census drifted" }}
puts [format {{[OPENSTA-FP-OOC-QUERY-BUDGET][PASS] find_calls=%d pathends=%d validations=%d dynamic=2 constant=1 max_bulk=2 min_bulk=2 nonfirst_endpoint_worst=1 uniform_required=1 scalar_lifetime=1 mutations=%d}} \\
  $focused_find_calls $focused_pathends $focused_validations $mutations]
exit
'''
        with tempfile.TemporaryDirectory() as temporary:
            script_path = Path(temporary) / "bulk-query-budget-harness.tcl"
            progress_path = Path(temporary) / "child-query-progress-max.tsv"
            script_path.write_text(
                script.replace("__PROGRESS__", tcl_path(progress_path)),
                encoding="utf-8",
            )
            completed = subprocess.run(
                [str(opensta), "-no_init", str(script_path)],
                text=True, capture_output=True, check=False,
                env={"PATH": "/usr/bin:/bin", "LC_ALL": "C", "LANG": "C"},
                timeout=120,
            )
            transcript = completed.stdout + completed.stderr
            self.assertEqual(0, completed.returncode, transcript)
            self.assertIn(
                "[OPENSTA-FP-OOC-QUERY-BUDGET][PASS]", transcript,
                transcript,
            )
            parsed_progress = ooc.parse_query_progress(
                progress_path, identity=self.identity,
                module="fp_ooc_bulk_query_budget_harness", analysis="max",
                expected_sequence_override=[
                    ("path_class", "port_to_register", "max", 2),
                    ("path_class", "register_to_register", "max", 2),
                    ("path_class", "register_to_port", "max", 2),
                    ("path_class", "synchronous_control_to_register", "max", 2),
                    ("input_arc", "setup/data_i/0", "max", 1),
                    ("input_arc", "setup/data_i/1", "max", 1),
                    ("input_arc", "hold/data_i/0", "min", 1),
                    ("input_arc", "hold/data_i/1", "min", 1),
                    ("output_bulk", "all_outputs", "max", 3),
                ],
            )
            self.assertEqual(
                (9, 14, 14),
                (parsed_progress["find_calls"],
                 parsed_progress["path_end_count"],
                 parsed_progress["validation_count"]),
            )
        marker = re.search(
            r"\[OPENSTA-FP-OOC-QUERY-BUDGET\]\[PASS\] "
            r"find_calls=9 pathends=14 validations=14 dynamic=2 constant=1 "
            r"max_bulk=2 min_bulk=2 nonfirst_endpoint_worst=1 "
            r"uniform_required=1 scalar_lifetime=1 mutations=6",
            transcript,
        )
        self.assertIsNotNone(marker, transcript)
        print(
            f"{marker.group(0)} opensta_sha256={opensta_sha} "
            f"stdlib_sha256={liberty_sha} fixture_sha256={fixture_sha}"
        )

    def test_production_collect_arc_family_materializes_multibit_worst_path(
            self) -> None:
        child_tcl_path = (
            registry.REPO_ROOT / "npc/rv64/eval/ppa/opensta-fp-ooc-child.tcl"
        )
        child_tcl = child_tcl_path.read_text(encoding="utf-8")
        proc_prefix = child_tcl[:child_tcl.index("\nset allowed_children")]
        collect_start = proc_prefix.index("proc collect_arc_family")
        collect_source = proc_prefix[collect_start:]
        self.assertNotIn("selected_path", collect_source)
        self.assertNotIn("selected_points", collect_source)
        self.assertIn("set selected_startpoint $path_startpoint", collect_source)
        self.assertIn("set selected_endpoint $path_endpoint", collect_source)

        opensta = Path("/home/lyg/tools/OpenSTA/build/sta")
        liberty = (
            registry.REPO_ROOT
            / "yosys-sta/pdk/icsprout55/IP/STD_cell/"
              "ics55_LLSC_H7C_V1p10C100/ics55_LLSC_H7CL/liberty/"
              "ics55_LLSC_H7CL_typ_tt_1p2_25_nldm.lib"
        )
        fixture = (
            registry.REPO_ROOT
            / "npc/rv64/eval/ppa/tests/fixtures/"
              "fp_ooc_pathend_multibit_harness.v"
        )
        self.assertEqual(
            "50fb07e41cd448cbb6ee782cc552db9adff12ed5f98d02bcca97ea3d7c2dd788",
            hashlib.sha256(opensta.read_bytes()).hexdigest(),
        )
        self.assertEqual(
            "55c129ca0f03a409622e6c309f7f2da3034a003323fc6f4e58ae2225ed416264",
            hashlib.sha256(liberty.read_bytes()).hexdigest(),
        )

        def tcl_path(path: Path) -> str:
            rendered = str(path.resolve())
            self.assertNotRegex(rendered, r"[{}\\\r\n]")
            return "{" + rendered + "}"

        script = f'''{proc_prefix}
read_liberty {tcl_path(liberty)}
read_verilog {tcl_path(fixture)}
link_design fp_ooc_pathend_multibit_harness
set fp_ooc_clock_origin_ns 0.0
set fp_ooc_clock_source_latency_ns 0.0
set fp_ooc_clock_network_latency_ns 0.0
set fp_ooc_clock_insertion_ns 0.0
set fp_ooc_clock_propagated 0
set fp_ooc_input_seed_ns 0.0
create_clock -name fp_ooc_clock -period 5.0 -waveform {{0.0 2.5}} [get_ports clk]
set_clock_latency -source 0.0 [get_clocks fp_ooc_clock]
set_clock_latency 0.0 [get_clocks fp_ooc_clock]
set_input_delay 0.0 -clock fp_ooc_clock [get_ports data_i*]
set_output_delay 0.0 -clock fp_ooc_clock [get_ports data_o*]
set_input_transition 0.02 [get_ports data_i*]
set_load 0.01 [get_ports data_o*]

set data_objects [exact_port_family data_i 2 input]
set data_names [object_name_list $data_objects]
set d_pins [get_pins */D]
if {{[llength $data_names] != 2 || [collection_count $d_pins] != 2}} {{
  error "multibit fixture object census is not exact"
}}

# Prove the first query is physically worse, consuming each PathEnd before the
# next query.  Only ordinary delay values survive into the production call.
set individual_delays {{}}
set individual_slacks {{}}
set individual_endpoints {{}}
foreach object $data_objects {{
  set from_names [list [object_name $object]]
  set to_names [object_name_list $d_pins]
  set paths [find_timing_paths -from [list $object] -to $d_pins \
    -path_delay max -endpoint_path_count 1 -group_path_count 1 -sort_by_slack]
  if {{[collection_count $paths] != 1}} {{ error "expected one path per input bit" }}
  set path_end [lindex $paths 0]
  set observation [validate_path_end $path_end individual_setup max \
    [list setup] $from_names $to_names]
  set delay [measured_path_delay_ns $observation individual_setup \
    input_to_register_d]
  lappend individual_delays $delay
  lappend individual_slacks [dict get $observation slack_ns]
  lappend individual_endpoints [dict get $observation endpoint]
  unset path_end paths observation
}}
if {{[lindex $individual_delays 0] <= [lindex $individual_delays 1]}} {{
  error "bit zero is not the global worst setup path"
}}
if {{[lindex $individual_slacks 0] >= [lindex $individual_slacks 1]}} {{
  error "bit zero is not worst under production setup slack ordering"
}}
if {{[lindex $individual_endpoints 0] eq [lindex $individual_endpoints 1]}} {{
  error "multibit fixture does not expose distinct register-D endpoints"
}}

set fp_ooc_progress_stream [open /dev/null w]
configure_query_budget fp_ooc_pathend_multibit_harness 2 2 2 2
set row [collect_arc_family setup data_i $data_objects $d_pins max 2 PORT REGISTER_D]
set selected_startpoint [lindex $row 11]
set selected_endpoint [lindex $row 12]
set first_query [lindex $data_names 0]
set last_query [lindex $data_names 1]
if {{$selected_startpoint ne $first_query || $selected_startpoint eq $last_query}} {{
  error "production collector did not preserve the non-final global worst value"
}}
if {{$selected_endpoint ni [object_name_list $d_pins]}} {{
  error "production collector returned an endpoint outside the real D pins"
}}
if {{$selected_endpoint ne [lindex $individual_endpoints 0] ||
    abs([lindex $row 6] - [lindex $individual_delays 0]) > 1.0e-9 ||
    abs([lindex $row 7] - [lindex $individual_slacks 0]) > 1.0e-9}} {{
  error "production collector did not preserve all bit-zero ordinary values"
}}
puts [format {{[OPENSTA-PRODUCTION-MULTIBIT-PATHEND][PASS] selected_startpoint=%s selected_endpoint=%s last_query=%s bit0_delay_ns=%.12g bit1_delay_ns=%.12g bit0_slack_ns=%.12g bit1_slack_ns=%.12g selected_from_nonfinal_query=1}} \
  $selected_startpoint $selected_endpoint $last_query \
  [lindex $individual_delays 0] [lindex $individual_delays 1] \
  [lindex $individual_slacks 0] [lindex $individual_slacks 1]]
exit
'''
        with tempfile.TemporaryDirectory() as temporary:
            script_path = Path(temporary) / "production-multibit-pathend.tcl"
            script_path.write_text(script, encoding="utf-8")
            completed = subprocess.run(
                [str(opensta), "-no_init", str(script_path)],
                text=True, capture_output=True, check=False,
                env={"PATH": "/usr/bin:/bin", "LC_ALL": "C", "LANG": "C"},
                timeout=120,
            )
        transcript = completed.stdout + completed.stderr
        self.assertEqual(0, completed.returncode, transcript)
        marker = re.search(
            r"\[OPENSTA-PRODUCTION-MULTIBIT-PATHEND\]\[PASS\] "
            r"selected_startpoint=(\S+) selected_endpoint=(\S+) last_query=(\S+) "
            r"bit0_delay_ns=([0-9.eE+-]+) bit1_delay_ns=([0-9.eE+-]+) "
            r"bit0_slack_ns=([0-9.eE+-]+) bit1_slack_ns=([0-9.eE+-]+) "
            r"selected_from_nonfinal_query=1",
            transcript,
        )
        self.assertIsNotNone(marker, transcript)
        self.assertNotEqual(marker.group(1), marker.group(3))
        self.assertGreater(float(marker.group(4)), float(marker.group(5)))
        self.assertLess(float(marker.group(6)), float(marker.group(7)))
        print(marker.group(0))

    def test_opensta_pathend_points_arrival_measurement_semantics(self) -> None:
        child_tcl_path = (
            registry.REPO_ROOT / "npc/rv64/eval/ppa/opensta-fp-ooc-child.tcl"
        )
        child_tcl = child_tcl_path.read_text(encoding="utf-8")
        proc_prefix = child_tcl[:child_tcl.index("\nset allowed_children")]
        self.assertNotIn("sta::time_sta_ui", child_tcl)
        self.assertNotRegex(
            child_tcl,
            r"get_property\s+\$(?:path|path_end)\s+(?:path_delay|delay|arrival)\b",
        )
        self.assertNotRegex(child_tcl, r"\$(?:path|path_end)\s+arrival\b")
        self.assertEqual(
            1,
            child_tcl.count(
                "set delay_ns [expr {$endpoint_arrival_ns - $first_arrival_ns}]"
            ),
        )
        self.assertEqual(1, child_tcl.count("return $endpoint_arrival_ns"))

        opensta = Path("/home/lyg/tools/OpenSTA/build/sta")
        liberty = (
            registry.REPO_ROOT
            / "yosys-sta/pdk/icsprout55/IP/STD_cell/"
            "ics55_LLSC_H7C_V1p10C100/ics55_LLSC_H7CL/liberty/"
            "ics55_LLSC_H7CL_typ_tt_1p2_25_nldm.lib"
        )
        fixture = (
            registry.REPO_ROOT
            / "npc/rv64/eval/ppa/tests/fixtures/fp_ooc_path_arrival_harness.v"
        )
        self.assertEqual(
            "50fb07e41cd448cbb6ee782cc552db9adff12ed5f98d02bcca97ea3d7c2dd788",
            hashlib.sha256(opensta.read_bytes()).hexdigest(),
        )
        self.assertEqual(
            "55c129ca0f03a409622e6c309f7f2da3034a003323fc6f4e58ae2225ed416264",
            hashlib.sha256(liberty.read_bytes()).hexdigest(),
        )

        def tcl_path(path: Path) -> str:
            rendered = str(path.resolve())
            self.assertNotRegex(rendered, r"[{}\\\r\n]")
            return "{" + rendered + "}"

        script = f'''{proc_prefix}
read_liberty {tcl_path(liberty)}
read_verilog {tcl_path(fixture)}
link_design fp_ooc_path_arrival_harness
set fp_ooc_clock_origin_ns 0.0
set fp_ooc_clock_source_latency_ns 0.0
set fp_ooc_clock_network_latency_ns 0.0
set fp_ooc_clock_insertion_ns 0.0
set fp_ooc_clock_propagated 0
set fp_ooc_input_seed_ns 0.0
create_clock -name fp_ooc_clock -period 5.0 -waveform {{0.0 2.5}} [get_ports clk]
set_clock_latency -source 0.0 [get_clocks fp_ooc_clock]
set_clock_latency 0.0 [get_clocks fp_ooc_clock]
set_input_delay 0.0 -clock fp_ooc_clock [get_ports data_i]
set_output_delay 0.0 -clock fp_ooc_clock [get_ports data_o]
set_input_transition 0.02 [get_ports data_i]
set_load 0.01 [get_ports data_o]

proc one_path {{from_objects to_objects corner label}} {{
  set paths [find_timing_paths -from $from_objects -to $to_objects \\
    -path_delay $corner -group_path_count 10 -sort_by_slack]
  if {{[collection_count $paths] == 0}} {{ error "$label has no timing path" }}
  return [lindex $paths 0]
}}
proc require_close {{actual expected label}} {{
  if {{abs($actual - $expected) > 1.0e-9}} {{
    error "$label mismatch: actual=$actual expected=$expected"
  }}
}}
proc expect_rejected {{script label}} {{
  if {{![catch {{uplevel 1 $script}} message]}} {{
    error "$label unexpectedly passed"
  }}
}}

set data_port [get_ports data_i]
set data_d [get_pins u_state_q/D]
set state_q [get_pins u_state_q/Q]
set data_out [get_ports data_o]
set input_names [object_name_list $data_port]
set d_names [object_name_list $data_d]
set q_names [object_name_list $state_q]
set output_names [object_name_list $data_out]

# Search owns each PathEnd and deletes it on the next timing query.  Consume
# the setup PathEnd completely, including its negative mutations, before hold.
set setup_end [one_path $data_port $data_d max setup]
set setup_observation [validate_path_end $setup_end setup max [list setup] \\
  $input_names $d_names]
set input_delay [measured_path_delay_ns $setup_observation setup \\
  input_to_register_d]
set expected_input_delta [expr {{[dict get $setup_observation endpoint_arrival_ns] - \\
  [dict get $setup_observation first_arrival_ns]}}]
require_close $input_delay $expected_input_delta input_to_register_d
if {{abs([dict get $setup_observation first_arrival_ns]) > 1.0e-9 ||
    $input_delay <= 0.0 || $input_delay >= 5.0}} {{
  error "input Path Property arrival is not zero-seeded UI nanoseconds"
}}
set pseudo_rejections 0
foreach property {{path_delay delay arrival}} {{
  if {{![catch {{get_property $setup_end $property}}]}} {{
    error "PathEnd pseudo property unexpectedly exists: $property"
  }}
  incr pseudo_rejections
}}
expect_rejected [list validate_path_end $setup_end wrong_object max \\
  [list setup] [list not_data_i] $d_names] wrong_object
expect_rejected [list validate_path_end $setup_end wrong_minmax min \\
  [list setup] $input_names $d_names] wrong_minmax
expect_rejected [list validate_path_end $setup_end wrong_role max \\
  [list hold] $input_names $d_names] wrong_role
unset setup_end setup_observation

# Hold PathEnd lifetime ends before the output-max query.
set hold_end [one_path $data_port $data_d min hold]
validate_path_end $hold_end hold min [list hold] $input_names $d_names
unset hold_end

# Output-max positive and origin-negative checks both precede output-min.
set output_max_end [one_path $state_q $data_out max output_max]
set output_observation [validate_path_end $output_max_end output_max max \\
  [list {{output setup}}] $q_names $output_names]
set clock_to_q [measured_path_delay_ns $output_observation output_max \\
  register_q_to_output]
set q_to_output_delta [expr {{[dict get $output_observation endpoint_arrival_ns] - \\
  [dict get $output_observation first_arrival_ns]}}]
require_close $clock_to_q [dict get $output_observation endpoint_arrival_ns] \\
  cumulative_clock_to_q
if {{$clock_to_q <= $q_to_output_delta + 1.0e-9 ||
    [dict get $output_observation first_arrival_ns] <= 0.0 ||
    $clock_to_q >= 5.0}} {{
  error "clock-to-Q endpoint arrival lost its real register clock-to-Q arc"
}}
set fp_ooc_clock_origin_ns 0.25
expect_rejected [list measured_path_delay_ns $output_observation nonzero_origin \\
  register_q_to_output] \\
  nonzero_clock_origin
set fp_ooc_clock_origin_ns 0.0
unset output_max_end

# The final query is consumed immediately and leaves no retained PathEnd.
set output_min_end [one_path $state_q $data_out min output_min]
set output_min_observation [validate_path_end $output_min_end output_min min \\
  [list {{output hold}}] $q_names $output_names]
measured_path_delay_ns $output_min_observation output_min register_q_to_output
unset output_min_end output_min_observation output_observation
puts [format {{[OPENSTA-PATHEND-ARRIVAL-HARNESS][PASS] input_delta_ns=%.12g clock_to_q_ns=%.12g q_to_output_delta_ns=%.12g pseudo_rejections=%d negative_mutations=4 unit_domain=PropertyValue_UI_ns}} \\
  $input_delay $clock_to_q $q_to_output_delta $pseudo_rejections]
exit
'''
        self.assertNotIn("-group_count", script)
        lifetime_markers = (
            "set setup_end [one_path",
            "unset setup_end setup_observation",
            "set hold_end [one_path",
            "unset hold_end",
            "set output_max_end [one_path",
            "unset output_max_end",
            "set output_min_end [one_path",
            "unset output_min_end output_min_observation output_observation",
        )
        lifetime_positions = [script.index(marker) for marker in lifetime_markers]
        self.assertEqual(sorted(lifetime_positions), lifetime_positions)
        self.assertEqual(4, script.count("[one_path "))
        with tempfile.TemporaryDirectory() as temporary:
            script_path = Path(temporary) / "pathend-arrival-harness.tcl"
            script_path.write_text(script, encoding="utf-8")
            completed = subprocess.run(
                [str(opensta), "-no_init", str(script_path)],
                text=True, capture_output=True,
                check=False,
                env={
                    "PATH": "/usr/bin:/bin",
                    "LC_ALL": "C",
                    "LANG": "C",
                },
                timeout=120,
            )
        transcript = completed.stdout + completed.stderr
        self.assertEqual(0, completed.returncode, transcript)
        marker = re.search(
            r"\[OPENSTA-PATHEND-ARRIVAL-HARNESS\]\[PASS\] "
            r"input_delta_ns=([0-9.eE+-]+) clock_to_q_ns=([0-9.eE+-]+) "
            r"q_to_output_delta_ns=([0-9.eE+-]+) pseudo_rejections=3 "
            r"negative_mutations=4 unit_domain=PropertyValue_UI_ns",
            transcript,
        )
        self.assertIsNotNone(marker, transcript)
        input_delta, clock_to_q, q_delta = map(float, marker.groups())
        self.assertGreater(input_delta, 0.0)
        self.assertGreater(clock_to_q, q_delta)
        print(marker.group(0))

    def test_production_runner_python_root_and_failure_status_are_explicit(
            self) -> None:
        runner = (
            registry.REPO_ROOT
            / "npc/rv64/eval/ppa/run-fp-ooc-composite-current.sh"
        ).read_text(encoding="utf-8")
        repo_root = 'repo_root="$(realpath -e --'
        export_root = 'export PYTHONPATH="${repo_root}"'
        readonly_root = "readonly PYTHONPATH"
        first_registry = 'python3 "${architecture_registry}"'
        self.assertEqual(1, runner.count(export_root))
        self.assertEqual(1, runner.count(readonly_root))
        self.assertLess(runner.index(repo_root), runner.index(export_root))
        self.assertLess(runner.index(export_root), runner.index(readonly_root))
        self.assertLess(runner.index(readonly_root), runner.index(first_registry))
        self.assertIn('local failure_stage="${stage}"', runner)
        self.assertIn('stage="${failure_stage}"', runner)
        self.assertIn("printf 'CLEANUP_RC=%s\\n'", runner)
        self.assertNotIn("stage=exit-trap", runner)

    def test_production_runner_child_yosys_timestamp_is_exact_and_mutation_sensitive(
            self) -> None:
        runner = (
            registry.REPO_ROOT
            / "npc/rv64/eval/ppa/run-fp-ooc-composite-current.sh"
        ).read_text(encoding="utf-8")
        direct = (
            '    "${yosys}" -q -Q -T -t -l "${child_dir}/yosys.log" \\\n'
        )
        untimestamped = direct.replace("-T -t -l", "-T -l")
        mutations = {
            "delete-direct-t": runner.replace(direct, untimestamped, 1),
            "duplicate-direct-t": runner.replace(
                direct, direct.replace("-T -t -l", "-T -t -t -l"), 1
            ),
            "environment-only-t": runner.replace(
                direct,
                '    FP_OOC_YOSYS_TIMESTAMP=-t \\\n' + untimestamped,
                1,
            ),
            "top-only-t": runner.replace(direct, untimestamped, 1).replace(
                '  YOSYS_ARGS="-q -Q -T" YOSYS_LOG_ARGS= || fail $?',
                '  YOSYS_ARGS="-q -Q -T -t" YOSYS_LOG_ARGS= || fail $?',
                1,
            ),
            "child-timeout-1799": runner.replace(
                '  run_bounded 1800 /usr/bin/env \\\n',
                '  run_bounded 1799 /usr/bin/env \\\n',
                1,
            ),
            "wrong-option-order": runner.replace(
                direct, direct.replace("-T -t -l", "-t -T -l"), 1
            ),
        }
        dead_branch_array = runner.replace(
            '  run_bounded 1800 /usr/bin/env \\\n',
            '  child_yosys_argv=("${yosys}" -q -Q -T -l '
            '"${child_dir}/yosys.log")\n'
            '  run_bounded 1800 /usr/bin/env \\\n',
            1,
        ).replace(
            direct, '    "${child_yosys_argv[@]}" \\\n', 1
        ).replace(
            '    || fail $?\n  [[ -s "${child_netlist}"',
            '    || fail $?\n'
            '  if false; then\n'
            + direct
            + '      -c "${child_yosys_tcl}" -- "${module}" icsprout55\n'
            '  fi\n'
            '  [[ -s "${child_netlist}"',
            1,
        )
        mutations.update({
            "dead-branch-array-indirection": dead_branch_array,
            "and-split-unbounded-yosys": runner.replace(
                direct, '    /usr/bin/true && \\\n' + direct, 1
            ),
            "semicolon-split-unbounded-yosys": runner.replace(
                direct, '    /usr/bin/true ; \\\n' + direct, 1
            ),
            "command-substitution-yosys": runner.replace(
                direct,
                direct.replace(
                    '"${yosys}"', '"$(printf %s "${yosys}")"', 1
                ),
                1,
            ),
            "printf-decoy-executable": runner.replace(
                direct, '    /usr/bin/printf "%s" \\\n' + direct, 1
            ),
            "true-pipeline-before-yosys": runner.replace(
                direct, '    /usr/bin/true | \\\n' + direct, 1
            ),
            "true-pipe-and-before-yosys": runner.replace(
                direct, '    /usr/bin/true |& \\\n' + direct, 1
            ),
            "true-background-before-yosys": runner.replace(
                direct, '    /usr/bin/true & \\\n' + direct, 1
            ),
        })

        _validate_production_runner_child_yosys_timestamp(runner)
        with tempfile.TemporaryDirectory() as temporary:
            for label, candidate in {"baseline": runner, **mutations}.items():
                with self.subTest(bash_n=label):
                    path = Path(temporary) / f"{label}.sh"
                    path.write_text(candidate, encoding="utf-8")
                    completed = subprocess.run(
                        ["/usr/bin/bash", "-n", str(path)],
                        text=True,
                        capture_output=True,
                        check=False,
                        env={"PATH": "/usr/bin:/bin", "LC_ALL": "C", "LANG": "C"},
                    )
                    self.assertEqual(0, completed.returncode, completed.stderr)

        for label, candidate in mutations.items():
            with self.subTest(rejected_mutation=label), self.assertRaises(
                    AssertionError):
                _validate_production_runner_child_yosys_timestamp(candidate)
        print(
            "[FP-OOC-CHILD-YOSYS-TIMESTAMP][PASS] "
            "production_children=5 direct_invocations=1 child_timeout_s=1800 "
            "child_opensta_timeout_s=600 top_timestamp=0 logical_commands=1 "
            "env_assignments=13 actual_executable=1 argv_timestamp=1 "
            "mutations=14 bash_n=15"
        )

    def test_production_runner_child_result_dir_and_cleanup_are_single_owner(
            self) -> None:
        runner = (
            registry.REPO_ROOT
            / "npc/rv64/eval/ppa/run-fp-ooc-composite-current.sh"
        ).read_text(encoding="utf-8")
        ordered = (
            'child_result_dir="${child_runtime}/${module}-200MHz"',
            'mkdir -p -- "${child_dir}" "${child_runtime}" '
            '"${child_result_dir}" || fail 1',
            'child_netlist="${child_result_dir}/${module}.netlist.v"',
            "run_bounded 1800",
        )
        positions = [runner.index(marker) for marker in ordered]
        self.assertEqual(sorted(positions), positions)
        for marker in ordered:
            self.assertEqual(1, runner.count(marker), marker)

        cleanup_start = runner.index("cleanup_runtime() {")
        cleanup_end = runner.index("\n}\n", cleanup_start)
        cleanup = runner[cleanup_start:cleanup_end]
        cleanup_order = (
            '[[ -e "${runtime_parent}" ]] || return 1',
            'resolved_parent="$(realpath -e -- "${runtime_parent}")"',
            'resolved_runtime="$(realpath -e -- "${runtime_dir}")"',
            '"${resolved_parent}"/run.*) rm -r -- "${resolved_runtime}" '
            '|| return $? ;;',
            'rmdir -- "${resolved_parent}"',
        )
        cleanup_positions = [cleanup.index(marker) for marker in cleanup_order]
        self.assertEqual(sorted(cleanup_positions), cleanup_positions)
        self.assertEqual(1, runner.count('rmdir -- "${resolved_parent}"'))
        self.assertNotIn(
            'rmdir -- "${resolved_parent}" || true', cleanup
        )
        self.assertNotIn("rmdir --ignore-fail-on-non-empty", runner)
        self.assertEqual(3, runner.count("cleanup_runtime || cleanup_rc=$?"))
        self.assertIn(
            'runtime_parent="${repo_root}/.github/runtime-artifacts/'
            'fp-ooc-composite/${run_id}"',
            runner,
        )


if __name__ == "__main__":
    unittest.main()
