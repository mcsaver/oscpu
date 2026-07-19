#!/usr/bin/env python3
"""Supplemental implementation audit for the frozen v8a shadow contract.

The historical v8a checker and RED evidence remain byte-frozen.  This checker
closes implementation-time blind spots that only become meaningful once RTL
exists: legacy lane1 retirement prefix, exact opaque-head encoding, scalar ABI
shape, non-use of the extracted base-ready signal, and a whole-tree instance
census including direct testbench instantiations.
"""

from __future__ import annotations

import argparse
import importlib.util
import json
import sys
from pathlib import Path
from typing import Any


RUN_DIR = Path(__file__).resolve().parent
REPO_ROOT = RUN_DIR.parents[2]
FROZEN_CHECKER = RUN_DIR / "check-s2-q2-shadow-foundation-v8a.py"
MANIFEST = RUN_DIR / "s2-q2-shadow-foundation-interface-v8a.json"
SCALAR_INPUTS = ("head0_context_permit_i", "fencei_retire_permit_i")
SCALAR_OUTPUTS = (
    "head0_retire_candidate_valid_o",
    "head0_identity_valid_o",
)
ALL_PORTS = SCALAR_INPUTS + SCALAR_OUTPUTS + ("head0_identity_o",)
COMMIT1_EXPRESSION = (
    "commit0_fire_w && !commit1_block_i && "
    "!head_exception_w && !head1_exception_w && "
    "!csr_commit1_block_w && "
    "(count_q > {{(ROB_COUNT_W-1){1'b0}}, 1'b1}) && "
    "valid_q[head1_w] && head1_done_w"
)
IDENTITY_EXPRESSION = (
    "{{(`OOO_CONTEXT_ID_W-ROB_INDEX_W){1'b0}}, head_q}"
)
FORBIDDEN_COMMIT1_SOURCES = (
    "head1_is_csr_raw_w",
    "head1_is_sfence_vma_raw_w",
    "head1_is_xret_raw_w",
    "head1_is_fencei_raw_w",
    "head1_potential_context_boundary_w",
    "head1_context_boundary_shadow_w",
)


def load_frozen_checker() -> Any:
    spec = importlib.util.spec_from_file_location("q2_v8a_frozen", FROZEN_CHECKER)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot import frozen checker: {FROZEN_CHECKER}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


FROZEN = load_frozen_checker()
V7 = FROZEN.V7


def direct_exact_error(body: str, target: str, expected: str) -> str | None:
    direct = V7.assignment_expressions(
        body, include_sequential=False
    ).get(target, [])
    if len(direct) != 1:
        return f"{target} expected one direct equation, found {len(direct)}"
    if V7.compact_expression(direct[0]) != V7.compact_expression(expected):
        return f"{target} differs from the frozen implementation expression"
    driver_errors = V7.exact_combinational_driver_errors(body, target)
    if driver_errors:
        return f"{target} driver invalid: {'; '.join(driver_errors)}"
    return None


def rob_shape_errors(body: str, identity_expression: str) -> list[str]:
    errors: list[str] = []
    for target, expected in (
        ("commit1_fire_w", COMMIT1_EXPRESSION),
        ("head0_identity_o", identity_expression),
    ):
        error = direct_exact_error(body, target, expected)
        if error:
            errors.append(error)
    graph = V7.assignment_graph(body, include_sequential=False)
    if not V7.depends_on(graph, "commit1_fire_w", "commit0_fire_w"):
        errors.append("commit1_fire_w no longer depends on the older commit0_fire_w")
    leaked = [
        signal for signal in FORBIDDEN_COMMIT1_SOURCES
        if V7.depends_on(graph, "commit1_fire_w", signal)
    ]
    if leaked:
        errors.append(
            "commit1_fire_w is gated by lane1 shadow classifier sources: "
            + ", ".join(leaked)
        )
    base_ready_uses = V7.code_only(body).count("head0_base_ready_w")
    if base_ready_uses != 3:
        errors.append(
            "head0_base_ready_w escaped declaration/equation/commit0-only use: "
            f"occurrences={base_ready_uses}"
        )
    return errors


def scalar_port_errors(body: str, module: str) -> list[str]:
    declarations = V7.module_port_declarations(body)
    errors: list[str] = []
    expected_directions = {
        **{name: "input" for name in SCALAR_INPUTS},
        **{name: "output" for name in SCALAR_OUTPUTS},
    }
    for name, direction in expected_directions.items():
        matches = [item for item in declarations if item["name"] == name]
        if len(matches) != 1:
            errors.append(f"{module}.{name} declaration count={len(matches)}")
        elif matches[0]["direction"] != direction or matches[0]["ranges"]:
            errors.append(f"{module}.{name} is not one scalar {direction} port")
    return errors


def source_instance_census(repo_root: Path) -> tuple[list[str], list[str]]:
    affected = {
        "OooRob", "OooDispatchBackend", "OooIntBackend",
        "OooAluDecodeBackend", "OooAluCoreSlice", "OooExecuteBackend",
        "OooCoreTopGlue",
    }
    errors: list[str] = []
    inventory: list[str] = []
    for suffix in ("*.v", "*.sv"):
        for path in sorted((repo_root / "npc/rv64").rglob(suffix)):
            body = V7.code_only(path.read_text(encoding="utf-8"))
            for instance in V7.all_instances(body):
                if instance["child"] not in affected:
                    continue
                relative = path.relative_to(repo_root).as_posix()
                label = (
                    f"{relative}:{instance['child']}:{instance['name']}"
                )
                inventory.append(label)
                missing = [port for port in ALL_PORTS
                           if port not in instance["ports"]]
                if missing:
                    errors.append(
                        f"{label} missing named v8a ports: {', '.join(missing)}"
                    )
                empty_inputs = [
                    port for port in SCALAR_INPUTS
                    if not instance["ports"].get(port, "").strip()
                ]
                if empty_inputs:
                    errors.append(
                        f"{label} has empty permit inputs: {', '.join(empty_inputs)}"
                    )
                positional = [
                    fragment for fragment in instance["positional_ports"]
                    if fragment and not fragment.startswith("`")
                ]
                if positional:
                    errors.append(f"{label} contains positional port fragments")
    if len(inventory) < 15:
        errors.append(f"affected instance census shrank below baseline: {len(inventory)}")
    return errors, inventory


def run_self_test() -> int:
    good = V7.code_only(f"""
      module OooRob(input commit1_block_i,
                    input head_exception_w, input head1_exception_w,
                    input csr_commit1_block_w, input [4:0] count_q,
                    input [3:0] head1_w, input [15:0] valid_q,
                    input [15:0] done_q, input base_source_i,
                    input [3:0] head_q,
                    output [7:0] head0_identity_o);
        wire head1_done_w = done_q[head1_w];
        wire head0_base_ready_w;
        assign head0_base_ready_w = base_source_i;
        wire commit0_fire_w;
        assign commit0_fire_w = head0_base_ready_w;
        wire commit1_fire_w;
        assign commit1_fire_w = {COMMIT1_EXPRESSION};
        assign head0_identity_o = {{{{(8-4){{1'b0}}}}, head_q}};
      endmodule
    """)
    checks = [
        ("canonical-shape-accepted", not rob_shape_errors(
            good, "{{(8-4){1'b0}}, head_q}")),
        ("retire-prefix-drop-killed", bool(rob_shape_errors(
            good.replace("commit0_fire_w &&", "1'b1 &&", 1),
            "{{(8-4){1'b0}}, head_q}"))),
        ("classifier-direct-gate-killed", bool(rob_shape_errors(
            good.replace("head1_done_w;", "head1_done_w && head1_is_csr_raw_w;"),
            "{{(8-4){1'b0}}, head_q}"))),
        ("identity-recode-killed", bool(rob_shape_errors(
            good.replace("{{(8-4){1'b0}}, head_q}", "{head_q, 4'b0000}"),
            "{{(8-4){1'b0}}, head_q}"))),
        ("base-ready-escape-killed", bool(rob_shape_errors(
            good.replace("endmodule", "wire leak = head0_base_ready_w; endmodule"),
            "{{(8-4){1'b0}}, head_q}"))),
    ]
    for name, passed in checks:
        print(f"[S2-Q2-V8A-IMPL-SELFTEST][{'PASS' if passed else 'FAIL'}] {name}")
    if not all(passed for _, passed in checks):
        return 1
    print(f"[S2-Q2-V8A-IMPL-SELFTEST][PASS] mutations={len(checks) - 1}")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo-root", type=Path, default=REPO_ROOT)
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    if args.self_test:
        return run_self_test()

    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    macro_definitions = V7.object_macro_definitions(
        (args.repo_root / "npc/rv64/vsrc/include/define.v").read_text(
            encoding="utf-8"
        )
    )
    identity_expression = V7.expand_object_macros(
        IDENTITY_EXPRESSION, macro_definitions
    )
    errors: list[str] = []
    for variant in FROZEN.ACTIVE_VARIANTS:
        modules, load_errors = FROZEN.load_active_modules(
            args.repo_root, manifest, variant
        )
        errors.extend(f"[{variant}] {error}" for error in load_errors)
        rob = modules.get("OooRob", "")
        errors.extend(
            f"[{variant}] {error}"
            for error in rob_shape_errors(rob, identity_expression)
        )
        for module in manifest["wrapper_bundle"]["modules"] + ["OooRob"]:
            errors.extend(
                f"[{variant}] {error}"
                for error in scalar_port_errors(modules.get(module, ""), module)
            )
    census_errors, inventory = source_instance_census(args.repo_root)
    errors.extend(f"[census] {error}" for error in census_errors)
    for item in inventory:
        print(f"[S2-Q2-V8A-IMPL][CENSUS] {item}")
    for error in errors:
        print(f"[S2-Q2-V8A-IMPL][RED] {error}")
    if errors:
        print(f"[S2-Q2-V8A-IMPL][FAIL] unresolved={len(errors)}")
        return 1
    print(
        "[S2-Q2-V8A-IMPL][PASS] commit prefix, identity encoding, scalar ABI, "
        f"base-ready confinement, and instance census={len(inventory)}"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
