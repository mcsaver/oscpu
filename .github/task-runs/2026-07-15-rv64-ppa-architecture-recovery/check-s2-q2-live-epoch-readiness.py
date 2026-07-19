#!/usr/bin/env python3
"""Fail-closed structural readiness audit for the S2-Q2 live MMU epoch slice.

This checker deliberately proves only source/port/connectivity readiness.  A PASS is
necessary, never sufficient: the contract still requires directed and mutation RTL
tests for ordering, age, same-edge atomicity, stale responses, wrap, and deadlock.
"""

from __future__ import annotations

import argparse
from collections import Counter
from functools import lru_cache
import hashlib
import json
import re
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Any


RUN_DIR = Path(__file__).resolve().parent
REPO_ROOT = RUN_DIR.parents[2]
DEFAULT_MANIFEST = RUN_DIR / "s2-q2-live-epoch-interface.json"
EXPECTED_CONTRACT_LOCK_SHA256 = "d830e31698425f431ad92fc907e2748b151399539e9736a0abfc0ee7d9d2d5fa"
EXPECTED_EVIDENCE_BASELINE_SHA256 = "abfe4e248f27e50d4f6cafc69f7429dba37e36544b3a5d6ec01248993ed1dc88"
ACTIVE_VARIANTS = {
    "release": (),
    "ooo_assert": ("OOO_ASSERT",),
}

EXPECTED_MACRO_DEFINITIONS = {
    "OOO_CONTEXT_ID_W": "8",
    "OOO_CONTEXT_ID_LSB": "0",
    "OOO_CONTEXT_ID_MSB": "7",
    "OOO_CONTEXT_OWNER_W": "3",
    "OOO_CONTEXT_OWNER_LSB": "8",
    "OOO_CONTEXT_OWNER_MSB": "10",
    "OOO_CONTEXT_OWNER_PENDING_SYSTEM": "3'd1",
    "OOO_CONTEXT_CAUSE_W": "7",
    "OOO_CONTEXT_CAUSE_SATP": "7'b0000001",
    "OOO_CONTEXT_CAUSE_SFENCE_VMA": "7'b0000010",
    "OOO_CONTEXT_CAUSE_ACCESS_CONTEXT": "7'b0000100",
    "OOO_CONTEXT_CAUSE_PBMTE": "7'b0001000",
    "OOO_CONTEXT_CAUSE_PMP": "7'b0010000",
    "OOO_CONTEXT_CAUSE_TRAP": "7'b0100000",
    "OOO_CONTEXT_CAUSE_XRET": "7'b1000000",
    "OOO_CONTEXT_DTLB_CAUSE_MASK": "7'b1111111",
    "OOO_CONTEXT_ITLB_CAUSE_MASK": "7'b1111011",
    "OOO_CONTEXT_FPC_CAUSE_MASK": "7'b1111011",
    "OOO_CONTEXT_PAYLOAD_W": "256",
    "OOO_CONTEXT_GENERATION_W": "8",
    "OOO_MMU_EPOCH_W": "2",
    "MMU_EPOCH_PHASE_W": "2",
    "MMU_EPOCH_PHASE_CAPTURE": "2'd0",
    "MMU_EPOCH_PHASE_SQUASH": "2'd1",
    "MMU_EPOCH_PHASE_WAIT_QUIET": "2'd2",
    "MMU_EPOCH_PHASE_GRANT": "2'd3",
}

EXPECTED_PAYLOAD_FIELDS = {
    "IDENTITY": {
        "msb": "`OOO_CONTEXT_ID_MSB",
        "lsb": "`OOO_CONTEXT_ID_LSB",
        "width": "`OOO_CONTEXT_ID_W",
    },
    "OWNER": {
        "msb": "`OOO_CONTEXT_OWNER_MSB",
        "lsb": "`OOO_CONTEXT_OWNER_LSB",
        "width": "`OOO_CONTEXT_OWNER_W",
    },
}

EXPECTED_LEAF_CAUSE_MEMBERSHIP = {
    "DTLB": ["SATP", "SFENCE_VMA", "ACCESS_CONTEXT", "PBMTE", "PMP", "TRAP", "XRET"],
    "ITLB": ["SATP", "SFENCE_VMA", "PBMTE", "PMP", "TRAP", "XRET"],
    "FPC": ["SATP", "SFENCE_VMA", "PBMTE", "PMP", "TRAP", "XRET"],
}

EXPECTED_SELF_TEST_INVENTORY = [
    "exact-live-instance",
    "comment-declaration-only-killed",
    "wrong-named-connection-killed",
    "dummy-wrong-host-killed",
    "same-host-dummy-instance-killed",
    "transitive-forbidden-alias-killed",
    "pure-constant-quiet-killed",
    "pure-constant-lane1-classifier-killed",
    "absorbing-constant-quiet-killed",
    "wide-absorbing-constant-killed",
    "ternary-boolean-bypass-killed",
    "absorbing-constant-lane1-killed",
    "lane1-self-inequality-classifier-killed",
    "missing-squash-ack-killed",
    "grant-ready-loop-killed",
    "missing-atomic-consumer-killed",
    "legacy-context-write-bypass-killed",
    "unique-reset-logical-not-killed",
    "unique-reset-bitwise-not-killed",
    "unique-reset-zero-compare-killed",
    "unique-reset-composite-killed",
    "extra-sensitivity-event-unique-next-killed",
    "procedural-local-reset-shadow-killed",
    "procedural-local-next-shadow-killed",
    "nonreset-conditional-unique-next-killed",
    "statement-event-unique-next-killed",
    "uppercase-live-reset-input-killed",
    "uppercase-localparam-reset-literal-accepted",
    "legacy-constant-write-killed",
    "nonreset-constant-tail-override-killed",
    "multiple-sequential-writers-killed",
    "blocking-sequential-writer-killed",
    "always-ff-second-writer-killed",
    "negedge-second-writer-killed",
    "always-latch-second-writer-killed",
    "initial-writer-killed",
    "continuous-writer-killed",
    "scalar-lhs-part-select-killed",
    "scalar-rhs-part-select-killed",
    "indexed-array-unique-next-accepted",
    "indexed-array-second-dimension-writer-killed",
    "nested-index-second-writer-killed",
    "task-output-actual-writer-killed",
    "task-inout-actual-writer-killed",
    "task-ref-actual-writer-killed",
    "imported-package-task-output-actual-writer-killed",
    "hierarchical-task-actual-writer-killed",
    "escaped-bare-task-actual-writer-killed",
    "escaped-package-task-actual-writer-killed",
    "escaped-hierarchical-task-actual-writer-killed",
    "punctuation-only-escaped-task-actual-killed",
    "system-readmemh-array-writer-killed",
    "system-output-actual-writer-killed",
    "readonly-system-diagnostic-accepted",
    "embedded-system-output-expression-killed",
    "embedded-unknown-call-expression-killed",
    "nested-concat-unique-next-writer-killed",
    "dead-generate-unique-next-writer-killed",
    "generate-for-replicated-writer-killed",
    "named-generate-shadow-unique-next-killed",
    "procedural-local-state-shadow-unique-next-killed",
    "typedef-local-shadow-unique-next-killed",
    "registered-writer-breaks-combinational-loop",
    "sequential-delay-not-a-combinational-dependency",
    "dummy-width-parameter-killed",
    "dummy-identity-port-width-killed",
    "noncanonical-packed-ranges-killed",
    "adjacent-port-width-misattribution-killed",
    "internal-identity-signal-width-killed",
    "held-head-match-bypass-killed",
    "inverted-held-head-equality-killed",
    "inverted-grant-source-killed",
    "phase-nonzero-instead-of-enum-killed",
    "stale-generation-ack-killed",
    "nonsticky-request-pulse-done-killed",
    "wrong-typed-leaf-mask-killed",
    "early-translation-invalidate-killed",
    "memory-squash-done-or-killed",
    "wrong-held-identity-payload-slice-killed",
    "valid-epoch-capture-constant-killed",
    "sq-fill-epoch-constant-alias-killed",
    "miq-push-port-map-killed",
    "miq-push-valid-alias-killed",
    "miq-push-epoch-alias-killed",
    "miq-head-epoch-source-killed",
    "miq-head-host-override-killed",
    "miq-epoch-storage-width-killed",
    "miq-epoch-capture-constant-killed",
    "miq-epoch-capture-wrong-edge-killed",
    "guarded-reset-logical-not-killed",
    "guarded-reset-bitwise-not-killed",
    "guarded-reset-zero-compare-killed",
    "guarded-reset-composite-killed",
    "extra-sensitivity-event-guarded-capture-killed",
    "procedural-local-shadow-guarded-capture-killed",
    "procedural-local-source-shadow-guarded-capture-killed",
    "typedef-local-shadow-guarded-array-killed",
    "guarded-capture-extra-outer-condition-killed",
    "guarded-capture-statement-event-killed",
    "guarded-capture-delay-control-killed",
    "guarded-capture-wait-control-killed",
    "miq-epoch-capture-dead-generate-killed",
    "miq-epoch-capture-extra-alias-writer-killed",
    "miq-epoch-capture-concat-writer-killed",
    "guarded-capture-after-reset-else-killed",
    "guarded-capture-writer-region-swap-killed",
    "nested-concat-guarded-array-writer-killed",
    "dead-generate-else-guarded-capture-killed",
    "dead-generate-critical-equation-killed",
    "wire-declaration-continuous-equation-accepted",
    "logic-initializer-not-combinational-equation-killed",
    "initializer-plus-live-blocking-driver-killed",
    "exact-equation-extra-driver-killed",
    "exact-equation-concat-writer-killed",
    "exact-equation-task-actual-writer-killed",
    "procedural-continuous-canonical-equation-killed",
    "named-generate-shadow-canonical-equation-killed",
    "implicit-net-rhs-not-a-declaration-killed",
    "port-range-reference-not-a-declaration-killed",
    "unparenthesized-always-procedural-assign-killed",
    "unknown-child-output-extra-driver-killed",
    "known-child-input-consumer-accepted",
    "lexical-header-port-direction-shadow-killed",
    "canonical-reset-host-driver-killed",
    "canonical-clock-child-output-driver-killed",
    "fencei-frontend-producer-map-killed",
    "fencei-execute-producer-map-killed",
    "fencei-exclusive-output-local-driver-killed",
    "nested-concat-exclusive-output-writer-killed",
    "context-payload-identity-exact-nonoverlap-accepted",
    "context-payload-identity-wrong-slice-killed",
    "context-payload-identity-shifted-source-killed",
    "context-payload-identity-whole-bus-writer-killed",
    "context-payload-identity-overlap-writer-killed",
    "dead-generate-payload-slice-writer-killed",
    "named-generate-shadow-payload-writer-killed",
    "procedural-continuous-payload-writer-killed",
    "nested-concat-payload-writer-killed",
    "memory-squash-true-leaf-maps-killed",
    "memory-squash-extra-host-done-driver-killed",
    "memory-squash-leaf-constant-done-killed",
    "memory-squash-leaf-request-echo-done-killed",
    "memory-squash-set-dominant-seen-formulas-locked",
    "memory-squash-staggered-leaf-pulses-retained",
    "memory-squash-request-cycle-dual-done-retained",
    "memory-squash-owner-rob-age-capture-killed",
    "memory-squash-owner-irrevocable-provenance-killed",
    "memory-squash-leaf-age-provenance-killed",
    "dead-generate-age-provenance-killed",
    "age-provenance-variable-initializer-killed",
    "age-provenance-extra-driver-killed",
    "named-generate-shadow-age-provenance-killed",
    "multiple-combinational-next-drivers-killed",
    "concrete-macro-layout-and-cause-values-locked",
    "inactive-canonical-active-constant-killed",
    "release-canonical-assert-mutated-killed",
    "assert-canonical-release-mutated-killed",
    "dead-explicit-generate-instance-killed",
    "dead-implicit-generate-instance-killed",
    "named-generate-local-producer-map-killed",
    "runner-pre-post-source-snapshot-locked",
    "missing-critical-child-definition-fails-closed",
]


def contract_lock_sha256(manifest: dict[str, Any]) -> str:
    projection = {
        key: value for key, value in manifest.items()
        if key not in {"contract_lock_sha256", "evidence_baseline"}
    }
    encoded = json.dumps(
        projection, ensure_ascii=False, sort_keys=True, separators=(",", ":")
    ).encode("utf-8")
    return hashlib.sha256(encoded).hexdigest()


def evidence_baseline_sha256(manifest: dict[str, Any]) -> str:
    encoded = json.dumps(
        manifest.get("evidence_baseline", {}),
        ensure_ascii=False,
        sort_keys=True,
        separators=(",", ":"),
    ).encode("utf-8")
    return hashlib.sha256(encoded).hexdigest()


def code_only(text: str) -> str:
    text = re.sub(r"/\*.*?\*/", " ", text, flags=re.S)
    text = re.sub(r"//[^\n]*", " ", text)
    return re.sub(r'"(?:\\.|[^"\\])*"', '""', text)


def preprocess_verilog_path(
    path: Path, repo_root: Path, *, defines: tuple[str, ...] = ()
) -> tuple[str | None, str]:
    """Return one explicitly selected active-source variant, failing closed."""
    vsrc = repo_root / "npc/rv64/vsrc"
    command = [
        "iverilog", "-E", "-g2012",
        "-I", str(vsrc / "include"),
        "-I", str(vsrc),
        *(f"-D{define}" for define in defines),
        "-o", "-", str(path),
    ]
    try:
        result = subprocess.run(
            command, check=False, capture_output=True, text=True, timeout=30
        )
    except (OSError, subprocess.TimeoutExpired) as exc:
        return None, f"unable to preprocess active source: {exc}"
    if result.returncode != 0:
        detail = result.stderr.strip().splitlines()
        return None, (
            "iverilog preprocessing failed"
            + (f": {detail[-1]}" if detail else "")
        )
    return result.stdout, ""


def object_macro_definitions(text: str) -> dict[str, str]:
    definitions: dict[str, str] = {}
    for name, value in re.findall(
        r"(?m)^\s*`define\s+([A-Za-z_][A-Za-z0-9_]*)\s+([^\n]+?)\s*$",
        code_only(text),
    ):
        definitions[name] = value.strip()
    return definitions


def expand_object_macros(expression: str, definitions: dict[str, str]) -> str:
    expanded = expression
    for _ in range(32):
        updated = re.sub(
            r"`([A-Za-z_][A-Za-z0-9_]*)",
            lambda match: definitions.get(match.group(1), match.group(0)),
            expanded,
        )
        if updated == expanded:
            return updated
        expanded = updated
    return expanded


def parse_verilog_integer(expression: str) -> int | None:
    compact = re.sub(r"[\s_]", "", strip_balanced_outer_parentheses(expression))
    if re.fullmatch(r"\d+", compact):
        return int(compact, 10)
    match = re.fullmatch(r"(\d+)'[sS]?([bBdDhHoO])([0-9a-fA-F]+)", compact)
    if not match:
        return None
    base = {"b": 2, "d": 10, "h": 16, "o": 8}[match.group(2).lower()]
    try:
        return int(match.group(3), base)
    except ValueError:
        return None


def balanced_region(text: str, open_pos: int) -> tuple[str, int] | None:
    if open_pos >= len(text) or text[open_pos] != "(":
        return None
    depth = 0
    for pos in range(open_pos, len(text)):
        if text[pos] == "(":
            depth += 1
        elif text[pos] == ")":
            depth -= 1
            if depth == 0:
                return text[open_pos + 1:pos], pos + 1
    return None


def module_body(text: str, module: str) -> str | None:
    match = re.search(rf"\bmodule\s+{re.escape(module)}\b", text)
    if not match:
        return None
    end = re.search(r"\bendmodule\b", text[match.end():])
    if not end:
        return None
    return text[match.start():match.end() + end.end()]


def all_instances(text: str) -> list[dict[str, Any]]:
    found: list[dict[str, Any]] = []
    primitive_names = {
        "and", "nand", "or", "nor", "xor", "xnor", "buf", "not",
        "bufif0", "bufif1", "notif0", "notif1", "nmos", "pmos",
        "cmos", "rnmos", "rpmos", "rcmos", "tran", "rtran",
        "tranif0", "tranif1", "rtranif0", "rtranif1", "pullup",
        "pulldown",
    }
    reserved = {
        "module", "interface", "program", "primitive", "function", "task",
        "input", "output", "inout", "wire", "logic", "reg", "assign",
        "always", "always_ff", "always_comb", "always_latch", "initial",
        "if", "else", "for", "foreach", "while", "repeat", "case",
    }
    for match in re.finditer(r"\b[A-Za-z_][A-Za-z0-9_$]*\b", text):
        child = match.group(0)
        if child in reserved or position_is_inside_procedural_span(text, match.start()):
            continue
        pos = match.end()
        while pos < len(text) and text[pos].isspace():
            pos += 1
        parameters: dict[str, str] = {}
        if pos < len(text) and text[pos] == "#":
            pos += 1
            while pos < len(text) and text[pos].isspace():
                pos += 1
            region = balanced_region(text, pos)
            if region is None:
                continue
            parameters_text, pos = region
            parameters = {
                parameter: value.strip()
                for parameter, value in re.findall(
                    r"\.([A-Za-z_][A-Za-z0-9_$]*)\s*\(\s*([^()]+?)\s*\)",
                    parameters_text,
                )
            }
            while pos < len(text) and text[pos].isspace():
                pos += 1
        name = re.match(r"[A-Za-z_][A-Za-z0-9_$]*", text[pos:])
        if name is None:
            if child not in primitive_names or pos >= len(text) or text[pos] != "(":
                continue
            instance_name = f"<unnamed@{match.start()}>"
        else:
            instance_name = name.group(0)
            pos += len(instance_name)
        while pos < len(text) and text[pos].isspace():
            pos += 1
        region = balanced_region(text, pos)
        if region is None:
            continue
        ports_text, end_pos = region
        if not re.match(r"\s*;", text[end_pos:]):
            continue
        ports: dict[str, str] = {}
        positional_ports: list[str] = []
        for fragment, _offset in split_top_level_fragments(ports_text):
            named = re.fullmatch(
                r"\s*\.([A-Za-z_][A-Za-z0-9_$]*)\s*\((.*)\)\s*",
                fragment,
                flags=re.S,
            )
            if named is not None:
                ports[named.group(1)] = named.group(2).strip()
            else:
                positional_ports.append(fragment.strip())
        found.append({
            "child": child,
            "name": instance_name,
            "ports": ports,
            "positional_ports": positional_ports,
            "parameters": parameters,
            "start": match.start(),
        })
    return found


def instances(text: str, child: str) -> list[dict[str, Any]]:
    # 承重 named instance 必须直接位于 host module lexical scope；即使
    # generate elaboration 为真，也不能让局部同名 shadow 冒充 canonical map。
    return [
        item for item in all_instances(text)
        if item["child"] == child
        and not position_is_under_module_generate(text, item["start"])
    ]


def instance_signal_uses(text: str, signal: str) -> list[dict[str, Any]]:
    def may_be_driven(actual: str) -> bool:
        expression = strip_balanced_outer_parentheses(actual.strip())
        if exact_signal_reference_selectors(expression, signal) is not None:
            return True
        if expression.startswith("{"):
            region = balanced_delimited_region(expression, 0, "{", "}")
            if region is not None and region[1] == len(expression):
                return any(
                    may_be_driven(fragment)
                    for fragment, _offset in split_top_level_fragments(region[0])
                )
        return False

    named = [
        {**item, "port": port}
        for item in all_instances(text)
        for port, actual in item["ports"].items()
        if may_be_driven(actual)
    ]
    positional = [
        {**item, "port": f"#{index}", "port_index": index}
        for item in all_instances(text)
        for index, actual in enumerate(item["positional_ports"])
        if may_be_driven(actual)
    ]
    return named + positional


def module_port_declarations(text: str) -> list[dict[str, Any]]:
    """Parse only host-module lexical ANSI/non-ANSI port declarations."""
    module_match = re.search(r"\bmodule\s+[A-Za-z_][A-Za-z0-9_$]*", text)
    if module_match is None:
        return []
    pos = module_match.end()
    while pos < len(text) and text[pos].isspace():
        pos += 1
    if pos < len(text) and text[pos] == "#":
        pos += 1
        while pos < len(text) and text[pos].isspace():
            pos += 1
        parameter_region = balanced_region(text, pos)
        if parameter_region is None:
            return []
        pos = parameter_region[1]
    while pos < len(text) and text[pos].isspace():
        pos += 1
    port_region = balanced_region(text, pos)
    if port_region is None:
        return []
    ports_text, after_ports = port_region
    fragments = split_top_level_fragments(ports_text)
    declarations: list[dict[str, Any]] = []
    ansi = re.search(r"\b(?:input|output|inout)\b", ports_text) is not None
    if ansi:
        current_direction: str | None = None
        current_ranges: list[str] = []
        for ordinal, (fragment, offset) in enumerate(fragments):
            direction = re.search(r"\b(input|output|inout)\b", fragment)
            if direction is not None:
                current_direction = direction.group(1)
                current_ranges = []
            declared = declaration_name(fragment)
            if declared is None or current_direction is None:
                continue
            prefix = fragment[:declared[1]]
            ranges = re.findall(r"\[([^\]]+)\]", prefix)
            if ranges:
                current_ranges = ranges
            declarations.append({
                "name": declared[0],
                "direction": current_direction,
                "ranges": list(current_ranges),
                "ordinal": ordinal,
                "start": pos + 1 + offset + declared[1],
            })
        return declarations

    header_order = {
        declared[0]: ordinal
        for ordinal, (fragment, _offset) in enumerate(fragments)
        if (declared := declaration_name(fragment)) is not None
    }
    semicolon = text.find(";", after_ports)
    body_start = semicolon + 1 if semicolon >= 0 else after_ports
    declaration = re.compile(r"\b(input|output|inout)\b[^;]*;", flags=re.S)
    for match in declaration.finditer(text, body_start):
        if (position_is_inside_procedural_span(text, match.start())
                or position_is_under_module_generate(text, match.start())):
            continue
        direction = match.group(1)
        current_ranges: list[str] = []
        for fragment, offset in split_top_level_fragments(match.group(0)[:-1]):
            declared = declaration_name(fragment)
            if declared is None or declared[0] not in header_order:
                continue
            prefix = fragment[:declared[1]]
            ranges = re.findall(r"\[([^\]]+)\]", prefix)
            if ranges:
                current_ranges = ranges
            declarations.append({
                "name": declared[0],
                "direction": direction,
                "ranges": list(current_ranges),
                "ordinal": header_order[declared[0]],
                "start": match.start() + offset + declared[1],
            })
    return declarations


def declared_port(text: str, direction: str, port: str) -> bool:
    matches = [
        item for item in module_port_declarations(text)
        if item["direction"] == direction and item["name"] == port
    ]
    return len(matches) == 1


def declared_port_width(text: str, port: str, width_token: str) -> bool:
    matches = [
        item for item in module_port_declarations(text)
        if item["name"] == port
    ]
    if len(matches) != 1:
        return False
    expected = re.sub(r"\s+", "", f"{width_token}-1:0")
    ranges = matches[0]["ranges"]
    return len(ranges) == 1 and re.sub(r"\s+", "", ranges[0]) == expected


def declared_signal_width(text: str, signal: str, width_token: str) -> bool:
    fragments = re.findall(
        r"\b(?:wire|logic|reg)\b(.*?)(?=\b(?:wire|logic|reg)\b|[;\n])",
        text,
        flags=re.S,
    )
    matches = [fragment for fragment in fragments
               if re.search(rf"\b{re.escape(signal)}\b", fragment)]
    if len(matches) != 1:
        return False
    signal_match = re.search(rf"\b{re.escape(signal)}\b", matches[0])
    if signal_match is None:
        return False
    ranges = re.findall(r"\[([^\]]+)\]", matches[0][:signal_match.start()])
    expected = re.sub(r"\s+", "", f"{width_token}-1:0")
    return len(ranges) == 1 and re.sub(r"\s+", "", ranges[0]) == expected


def assignment_expressions(
    text: str, *, include_sequential: bool = True
) -> dict[str, list[str]]:
    expressions: dict[str, list[str]] = {}
    patterns: list[tuple[str, bool]] = [
        (r"\bassign\s+([A-Za-z_][A-Za-z0-9_$]*)\s*=\s*([^;]+);", False),
        # 只有 net declaration assignment 具有连续赋值语义；logic/reg 的
        # declaration initializer 是 time-zero 初始化，不能提供组合 provenance。
        (r"\bwire\b(?:\s+(?:signed|unsigned))?(?:\s*\[[^\]]+\])?\s+"
         r"([A-Za-z_][A-Za-z0-9_$]*)\s*=\s*([^;]+);", False),
    ]
    if include_sequential:
        patterns.append((
            r"\b([A-Za-z_][A-Za-z0-9_$]*)\s*<=\s*([^;]+);", True
        ))
    for pattern, allow_procedural in patterns:
        for match in re.finditer(pattern, text, flags=re.S):
            if (position_is_under_module_generate(text, match.start())
                    or (not allow_procedural
                        and position_is_inside_procedural_span(text, match.start()))):
                continue
            target, rhs = match.groups()
            expressions.setdefault(target, []).append(rhs.strip())
    return expressions


def assignment_graph(
    text: str, *, include_sequential: bool = True
) -> dict[str, set[str]]:
    graph: dict[str, set[str]] = {}
    for target, rhs_list in assignment_expressions(
        text, include_sequential=include_sequential
    ).items():
        for rhs in rhs_list:
            graph.setdefault(target, set()).update(
                re.findall(r"\b[A-Za-z_][A-Za-z0-9_$]*\b", rhs)
            )
    return graph


def depends_on(graph: dict[str, set[str]], target: str, source: str) -> bool:
    todo = [target]
    seen: set[str] = set()
    while todo:
        node = todo.pop()
        if node in seen:
            continue
        seen.add(node)
        for dependency in graph.get(node, set()):
            if dependency == source:
                return True
            if dependency not in seen:
                todo.append(dependency)
    return False


def exact_instance_connection(
    host_text: str, child: str, expected: dict[str, str],
    expected_instance: str | None = None,
) -> tuple[bool, str]:
    candidates = instances(host_text, child)
    if not candidates:
        return False, f"no live {child} instance in required host"
    if expected_instance is not None:
        candidates = [candidate for candidate in candidates
                      if candidate["name"] == expected_instance]
        if len(candidates) != 1:
            return False, (
                f"expected exactly one canonical {child} instance "
                f"{expected_instance}, found {len(candidates)}"
            )
    for candidate in candidates:
        if all(candidate["ports"].get(port) == signal
               for port, signal in expected.items()):
            return True, candidate["name"]
    missing = ", ".join(f".{port}({signal})" for port, signal in expected.items())
    return False, f"no one {child} instance has complete exact map: {missing}"


def exact_instance_parameters(
    host_text: str, child: str, expected: dict[str, str],
    expected_instance: str | None = None,
) -> tuple[bool, str]:
    candidates = instances(host_text, child)
    if not candidates:
        return False, f"no live {child} instance in required host"
    if expected_instance is not None:
        candidates = [candidate for candidate in candidates
                      if candidate["name"] == expected_instance]
        if len(candidates) != 1:
            return False, (
                f"expected exactly one canonical {child} instance "
                f"{expected_instance}, found {len(candidates)}"
            )
    for candidate in candidates:
        if all(candidate["parameters"].get(name) == value
               for name, value in expected.items()):
            return True, candidate["name"]
    missing = ", ".join(f".{name}({value})" for name, value in expected.items())
    return False, f"no one {child} instance has complete parameter map: {missing}"


def balanced_delimited_region(
    text: str, open_pos: int, opener: str, closer: str
) -> tuple[str, int] | None:
    """Return one balanced delimiter body and the position after its close."""
    if open_pos >= len(text) or text[open_pos] != opener:
        return None
    depth = 0
    for pos in range(open_pos, len(text)):
        if text[pos] == opener:
            depth += 1
        elif text[pos] == closer:
            depth -= 1
            if depth == 0:
                return text[open_pos + 1:pos], pos + 1
    return None


def assignment_operator_at(text: str, position: int) -> str | None:
    pos = position
    while pos < len(text) and text[pos].isspace():
        pos += 1
    for candidate in (
        "<<=", ">>=", "<=", "+=", "-=", "*=", "/=", "%=", "&=", "|=", "^=", "="
    ):
        if not text.startswith(candidate, pos):
            continue
        if candidate == "=" and text.startswith("==", pos):
            continue
        return candidate
    return None


def signal_has_concatenated_lhs_write(text: str, signal: str) -> bool:
    """Detect any-depth concatenated LHS containing an audited signal."""
    token = re.compile(
        rf"\b{re.escape(signal)}(?:\s*\[[^\]]+\])*\b"
    )
    for match in re.finditer(r"\{", text):
        region = balanced_delimited_region(text, match.start(), "{", "}")
        if region is None:
            continue
        body, after = region
        if assignment_operator_at(text, after) is not None and token.search(body):
            return True
    return False


def direct_signal_writes(text: str, signal: str) -> list[dict[str, Any]]:
    """Return direct procedural/continuous writes to one signal or its selects."""
    writes: list[dict[str, Any]] = []
    for match in re.finditer(rf"\b{re.escape(signal)}\b", text):
        pos = match.end()
        selectors: list[str] = []
        while True:
            while pos < len(text) and text[pos].isspace():
                pos += 1
            if pos >= len(text) or text[pos] != "[":
                break
            start = pos
            depth = 0
            closed = False
            while pos < len(text):
                if text[pos] == "[":
                    depth += 1
                elif text[pos] == "]":
                    depth -= 1
                    if depth == 0:
                        selectors.append(text[start + 1:pos])
                        pos += 1
                        closed = True
                        break
                pos += 1
            if not closed:
                break
        while pos < len(text) and text[pos].isspace():
            pos += 1
        op = ""
        for candidate in ("<<=", ">>=", "<=", "+=", "-=", "*=", "/=",
                          "%=", "&=", "|=", "^=", "="):
            if text.startswith(candidate, pos):
                if candidate == "=" and text.startswith("==", pos):
                    continue
                op = candidate
                break
        if not op:
            continue
        rhs_start = pos + len(op)
        semicolon = text.find(";", rhs_start)
        if semicolon < 0:
            continue
        prefix = text[max(0, match.start() - 96):match.start()]
        if re.search(r"\bassign\s*$", prefix):
            kind = "continuous"
        else:
            declaration = re.search(
                r"\b(wire|logic|reg)\b[^;]*$", prefix, flags=re.S
            )
            if declaration is not None:
                kind = (
                    "net-declaration"
                    if declaration.group(1) == "wire"
                    else "variable-initializer"
                )
            else:
                kind = "procedural"
        writes.append({
            "lhs": text[match.start():pos],
            "selects": selectors,
            "op": op,
            "rhs": text[rhs_start:semicolon].strip(),
            "kind": kind,
            "start": match.start(),
            "end": semicolon + 1,
        })
    return writes


def signal_has_procedural_local_declaration(text: str, signal: str) -> bool:
    """Reject a procedural local that shadows audited module state."""
    declaration = re.compile(
        rf"\b(?:wire|logic|reg|bit|integer|time|parameter|localparam|genvar)\b[^;]*"
        rf"\b{re.escape(signal)}\b[^;]*;",
        flags=re.S,
    )
    if any(
        position_is_inside_procedural_span(text, match.start())
        for match in declaration.finditer(text)
    ):
        return True
    # User-defined/struct/enum types are legal block-item declarations too.
    # Identify the audited declarator from its statement prefix/suffix without
    # confusing an assignment or a task/system-call actual for a declaration.
    for name in re.finditer(rf"\b{re.escape(signal)}\b", text):
        if not position_is_inside_procedural_span(text, name.start()):
            continue
        boundaries = [
            match.end() for match in re.finditer(
                r";|\bbegin\b|\bend\b", text[:name.start()]
            )
        ]
        start = boundaries[-1] if boundaries else 0
        semicolon = text.find(";", name.end())
        if semicolon < 0:
            continue
        fragment = text[start:semicolon]
        relative = name.start() - start
        prefix = fragment[:relative]
        suffix = fragment[relative + len(signal):]
        # Calls/control expressions have an unmatched parenthesis before the
        # actual; a declaration prefix does not (packed dimensions use []).
        if prefix.count("(") != prefix.count(")"):
            continue
        tail = suffix.lstrip()
        while tail.startswith("["):
            region = balanced_delimited_region(tail, 0, "[", "]")
            if region is None:
                break
            tail = tail[region[1]:].lstrip()
        if not (tail == "" or tail.startswith((",", "="))):
            continue
        declaration_prefix = re.search(
            r"(?:[A-Za-z_][A-Za-z0-9_$]*|\}|::)\s*$", prefix
        ) is not None
        comma_declarator = (
            "," in prefix
            and declaration_name(prefix.rsplit(",", 1)[0]) is not None
        )
        if (declaration_prefix or comma_declarator) and not re.search(
            r"\b(?:if|else|return|assign|deassign)\s*$", prefix
        ):
            return True
    return False


def instance_driver_errors(
    text: str, signal: str, module_code: dict[str, str] | None
) -> list[str]:
    errors: list[str] = []
    for use in instance_signal_uses(text, signal):
        child_body = (module_code or {}).get(use["child"], "")
        if "port_index" in use:
            is_known_input = any(
                declaration["ordinal"] == use["port_index"]
                and declaration["direction"] == "input"
                for declaration in module_port_declarations(child_body)
            )
        else:
            is_known_input = bool(child_body) and declared_port(
                child_body, "input", use["port"]
            )
        if not is_known_input:
            errors.append(
                f"unknown/output instance port may drive {signal}: "
                f"{use['child']}.{use['name']}.{use['port']}"
            )
    return errors


def exact_combinational_driver_errors(
    text: str, signal: str, module_code: dict[str, str] | None = None
) -> list[str]:
    """Require one module-scope continuous driver for a critical equation.

    A plain ``assign`` or a ``wire`` declaration assignment is legal.  Variable
    initializers, procedural writes, generated/local shadows, concatenated LHS,
    compound updates, and subroutine output/inout actuals all fail closed.
    """
    errors: list[str] = []
    expressions = assignment_expressions(text, include_sequential=False).get(
        signal, []
    )
    if len(expressions) != 1:
        errors.append(
            f"expected one module-scope continuous driver, found {len(expressions)}"
        )

    writes = direct_signal_writes(text, signal)
    legal_writes = [
        write for write in writes
        if write["op"] == "="
        and write["kind"] in {"continuous", "net-declaration"}
        and not position_is_under_module_generate(text, write["start"])
        and not position_is_inside_procedural_span(text, write["start"])
    ]
    if len(legal_writes) != 1 or len(writes) != 1:
        errors.append(
            "direct writer inventory is not one lexical continuous assignment: "
            f"legal={len(legal_writes)} all={len(writes)}"
        )
    if signal_has_concatenated_lhs_write(text, signal):
        errors.append("concatenated LHS can overwrite the critical equation")
    if re.search(
        rf"\b{re.escape(signal)}(?:\s*\[[^\]]+\])*\s*"
        r"(?:\+\+|--|(?:<<|>>|[+\-*/%&|^])=)",
        text,
    ):
        errors.append("compound update can overwrite the critical equation")
    if signal_has_procedural_local_declaration(text, signal):
        errors.append("procedural local declaration shadows the audited signal")
    if register_is_user_task_actual(text, signal):
        errors.append("critical equation signal is passed to a writing subroutine")
    errors.extend(instance_driver_errors(text, signal, module_code))
    return errors


def canonical_control_source_errors(
    text: str, signal: str, module_code: dict[str, str]
) -> list[str]:
    errors: list[str] = []
    if not declared_port(text, "input", signal):
        errors.append("canonical control source is not one lexical input port")
    if direct_signal_writes(text, signal):
        errors.append("host directly writes canonical control input")
    if signal_has_concatenated_lhs_write(text, signal):
        errors.append("concatenated LHS writes canonical control input")
    if register_is_user_task_actual(text, signal):
        errors.append("canonical control input is passed to a writing subroutine")
    errors.extend(instance_driver_errors(text, signal, module_code))
    return errors


def manifest_unique_combinational_targets(
    manifest: dict[str, Any]
) -> set[tuple[str, str]]:
    targets: set[tuple[str, str]] = set()
    for collection in ("boolean_requirements", "exact_next_expressions"):
        targets.update(
            (item["module"], item["target"])
            for item in manifest.get(collection, [])
        )
    targets.update(
        (item["module"], item["next_signal"])
        for item in manifest.get("epoch_register_captures", [])
    )
    for group in manifest.get("next_signal_source_groups", []):
        targets.update(
            (group["module"], signal) for signal in group["next_signals"]
        )
    for qualified in manifest.get(
        "unique_combinational_driver_policy", {}
    ).get("age_provenance_targets", []):
        if isinstance(qualified, str) and "." in qualified:
            module, signal = qualified.split(".", 1)
            targets.add((module, signal))
    return targets


def expression_signal_names(expression: str) -> set[str]:
    names: set[str] = set()
    for match in re.finditer(r"\b[A-Za-z_][A-Za-z0-9_$]*\b", expression):
        if match.start() > 0 and expression[match.start() - 1] in {"'", "`"}:
            continue
        name = match.group(0)
        if name in {"if", "else", "begin", "end"} or name.isupper():
            continue
        names.add(name)
    return names


def manifest_critical_symbols(manifest: dict[str, Any]) -> set[tuple[str, str]]:
    """Build the frozen target/source declaration inventory from the manifest."""
    symbols: set[tuple[str, str]] = set()

    def add(module: str, expression: str) -> None:
        for name in expression_signal_names(expression):
            symbols.add((module, name))

    for collection in (
        "boolean_requirements", "exact_next_expressions", "signal_dependencies",
        "forbidden_dependencies", "forbidden_direct_dependencies",
    ):
        for item in manifest.get(collection, []):
            module = item["module"]
            add(module, item["target"])
            for source in item.get("sources", []):
                add(module, source)
            if isinstance(item.get("source"), str):
                add(module, item["source"])
    for item in manifest.get("epoch_register_captures", []):
        for field in ("register", "next_signal", "capture_fire", "signal"):
            add(item["module"], item[field])
    for group in manifest.get("next_signal_source_groups", []):
        for signal in group.get("next_signals", []):
            add(group["module"], signal)
        for source in group.get("sources", []):
            add(group["module"], source)
    for item in manifest.get("unique_next_writes", []):
        add(item["module"], item["register"])
        add(item["module"], item["next_signal"])
        add(item["module"], manifest.get("canonical_reset_predicate", "rst"))
        add(item["module"], "clk")
    for item in manifest.get("guarded_indexed_captures", []):
        for field in ("register", "index", "source", "guard"):
            add(item["module"], item[field])
        add(item["module"], manifest.get("canonical_reset_predicate", "rst"))
        add(item["module"], "clk")
    for item in manifest.get("exact_payload_slices", []):
        add(item["module"], item["signal"])
        add(item["module"], item["source"])
    for item in manifest.get("exclusive_instance_outputs", []):
        add(item["host"], item["signal"])
    for item in manifest.get("instance_connections", []):
        for signal in item.get("ports", {}).values():
            add(item["host"], signal)
        for signal in item.get("same_name_ports", []):
            add(item["host"], signal)
    for item in manifest.get("epoch_named_connections", []):
        add(item["module"], item["signal"])
    for collection in ("required_ports", "required_port_widths"):
        for item in manifest.get(collection, []):
            port = item.get("port")
            if isinstance(port, str) and port:
                symbols.add((item["module"], port))
    return symbols


def position_is_under_conditional_if(text: str, position: int) -> bool:
    """Conservatively reject critical writers hidden in any if/generate arm."""
    for match in re.finditer(r"\bif\s*\(", text[:position]):
        open_pos = text.find("(", match.start(), match.end())
        condition_region = balanced_region(text, open_pos)
        if condition_region is None:
            continue
        true_span = statement_span(text, condition_region[1])
        if true_span is None:
            continue
        if true_span[0] <= position < true_span[1]:
            return True
        pos = true_span[1]
        while pos < len(text) and text[pos].isspace():
            pos += 1
        else_match = re.match(r"else\b", text[pos:])
        if not else_match:
            continue
        false_span = statement_span(text, pos + else_match.end())
        if false_span is not None and false_span[0] <= position < false_span[1]:
            return True
    return False


def exclusive_instance_output_errors(
    host_text: str, requirement: dict[str, Any]
) -> list[str]:
    """Lock a host wire to one named child output and forbid host-side writers."""
    ok, detail = exact_instance_connection(
        host_text,
        requirement["child"],
        {requirement["port"]: requirement["signal"]},
        requirement["instance"],
    )
    errors: list[str] = []
    if not ok:
        errors.append(detail)
    signal = requirement["signal"]
    writes = direct_signal_writes(host_text, signal)
    if writes:
        errors.append(f"host directly writes producer signal {signal}")
    if re.search(
        rf"\b{re.escape(signal)}(?:\s*\[[^\]]+\])*\s*"
        r"(?:\+\+|--|(?:<<|>>|[+\-*/%&|^])=)",
        host_text,
    ):
        errors.append(f"host compound-writes producer signal {signal}")
    if signal_has_concatenated_lhs_write(host_text, signal):
        errors.append(f"host concatenated-LHS writes producer signal {signal}")
    if register_is_user_task_actual(host_text, signal):
        errors.append(f"producer signal {signal} is passed to a user task")
    return errors


def guarded_indexed_capture_errors(
    text: str, requirement: dict[str, Any], reset_predicate: str = "rst"
) -> list[str]:
    """Require one exact indexed NBA directly under one exact true-arm guard."""
    register = requirement["register"]
    index = compact_expression(requirement["index"])
    source = compact_expression(requirement["source"])
    guard = compact_expression(requirement["guard"])
    errors: list[str] = []
    if register_is_user_task_actual(text, register):
        errors.append(f"{register} is passed to a user task")
    frozen_names = {
        reset_predicate, "clk", requirement["register"], requirement["source"],
        requirement["guard"],
        *re.findall(r"\b[A-Za-z_][A-Za-z0-9_$]*\b", requirement["index"]),
        *(
            name
            for ancestor in requirement.get("canonical_ancestors", [])
            for name in re.findall(
                r"\b[A-Za-z_][A-Za-z0-9_$]*\b",
                ancestor.get("condition", ""),
            )
        ),
    }
    shadowed = sorted(
        name for name in frozen_names
        if re.fullmatch(r"[A-Za-z_][A-Za-z0-9_$]*", name)
        and signal_has_procedural_local_declaration(text, name)
    )
    if shadowed:
        errors.append(
            "procedural local shadows frozen capture symbols: "
            + ", ".join(shadowed)
        )

    writes = direct_signal_writes(text, register)
    expected_writes = Counter(
        (
            compact_expression(item["index"]),
            compact_expression(item["source"]),
            item.get("op", "<="),
        )
        for item in requirement.get("allowed_writes", [])
    )
    actual_writes = Counter(
        (
            compact_expression(write["selects"][0])
            if len(write["selects"]) == 1 else
            "<whole-or-multiselect>",
            compact_expression(write["rhs"]),
            write["op"],
        )
        for write in writes
    )
    if actual_writes != expected_writes:
        errors.append("array writer inventory differs from the frozen exact multiset")
    if signal_has_concatenated_lhs_write(text, register):
        errors.append("concatenated LHS can overwrite the audited array")
    target_writes: list[dict[str, Any]] = []
    for write in writes:
        selectors = write["selects"]
        if not selectors:
            errors.append(f"whole-array write may overwrite {register}[{index}]")
            continue
        first = compact_expression(selectors[0])
        if first == index:
            target_writes.append(write)
        elif re.search(rf"\b{re.escape(requirement['index'])}\b", selectors[0]):
            errors.append(f"noncanonical alias index writes {register}[{selectors[0]}]")
    if len(target_writes) != 1:
        errors.append(
            f"expected one write to {register}[{requirement['index']}], "
            f"found {len(target_writes)}"
        )
        return errors
    capture = target_writes[0]
    if len(capture["selects"]) != 1:
        errors.append("capture LHS has an extra packed/unpacked selector")
    if capture["op"] != "<=":
        errors.append("capture is not a nonblocking assignment")
    if compact_expression(capture["rhs"]) != source:
        errors.append("capture RHS differs from the frozen provenance source")

    block_spans: list[tuple[int, int, str]] = []
    search_from = 0
    for block in posedge_clk_blocks(text):
        start = text.find(block, search_from)
        if start < 0:
            continue
        block_spans.append((start, start + len(block), block))
        search_from = start + len(block)
    containing_blocks = [
        item for item in block_spans if item[0] <= capture["start"] < item[1]
    ]
    if len(containing_blocks) != 1:
        errors.append(
            "capture must belong to exactly one always @(posedge clk) block"
        )
        return errors
    block_start, _block_end, block = containing_blocks[0]
    if any(not (block_start <= write["start"] < _block_end) for write in writes):
        errors.append("audited array has a writer outside the canonical clock block")
    relative_capture = capture["start"] - block_start
    reset_regions = outer_reset_regions(block, reset_predicate)
    if reset_regions is None:
        errors.append("capture is not in the non-reset arm of a canonical clock block")
    else:
        reset_span, nonreset_span = reset_regions
        if not (nonreset_span[0] <= relative_capture < nonreset_span[1]):
            errors.append(
                "capture is not in the non-reset arm of a canonical clock block"
            )
        expected_region_writes = Counter(
            (
                compact_expression(item["index"]),
                compact_expression(item["source"]),
                item.get("op", "<="),
                item.get("region", ""),
            )
            for item in requirement.get("allowed_writes", [])
        )
        actual_region_writes: Counter[tuple[str, str, str, str]] = Counter()
        for write in writes:
            relative = write["start"] - block_start
            if reset_span[0] <= relative < reset_span[1]:
                region = "reset"
            elif nonreset_span[0] <= relative < nonreset_span[1]:
                region = "nonreset"
            else:
                region = "outside"
            actual_region_writes.update([(
                compact_expression(write["selects"][0])
                if len(write["selects"]) == 1 else "<whole-or-multiselect>",
                compact_expression(write["rhs"]),
                write["op"],
                region,
            )])
        if actual_region_writes != expected_region_writes:
            errors.append(
                "array writer reset/non-reset regions differ from the frozen multiset"
            )

    if position_is_under_conditional_generate(text, block_start):
        errors.append("capture clock block is under a module generate scope")
    errors.extend(procedural_timing_control_errors(block))

    actual_ancestors = if_ancestor_path(
        text, capture["start"], block_start, _block_end
    )
    expected_ancestors = [
        {
            "condition": compact_expression(item["condition"]),
            "arm": item["arm"],
        }
        for item in requirement.get("canonical_ancestors", [])
    ]
    if actual_ancestors != expected_ancestors:
        errors.append(
            "capture ancestor control path differs from the frozen exact path"
        )

    containing_guards = 0
    for match in re.finditer(r"\bif\s*\(", text):
        open_pos = text.find("(", match.start(), match.end())
        condition_region = balanced_region(text, open_pos)
        if condition_region is None:
            continue
        condition, after_condition = condition_region
        if compact_expression(condition) != guard:
            continue
        true_span = statement_span(text, after_condition)
        if true_span is None:
            continue
        if true_span[0] <= capture["start"] < true_span[1]:
            prefix = text[true_span[0]:capture["start"]]
            if re.search(r"\b(?:if|case|casex|casez|for|while|repeat)\b", prefix):
                errors.append("capture is hidden behind a nested control condition")
            containing_guards += 1
    if containing_guards != 1:
        errors.append(
            f"capture must be in one exact if ({requirement['guard']}) true arm; "
            f"found {containing_guards}"
        )
    return errors


def exact_payload_slice_errors(
    text: str, requirement: dict[str, Any], definitions: dict[str, str]
) -> list[str]:
    """Require one exact identity-slice writer and reject overlapping writers."""
    signal = requirement["signal"]
    source = compact_expression(requirement["source"])
    msb_text = expand_object_macros(requirement["msb"], definitions)
    lsb_text = expand_object_macros(requirement["lsb"], definitions)
    msb = parse_verilog_integer(msb_text)
    lsb = parse_verilog_integer(lsb_text)
    if msb is None or lsb is None or msb < lsb:
        return ["payload slice bounds are not concrete canonical integers"]

    errors: list[str] = []
    writes = direct_signal_writes(text, signal)
    if any(position_is_under_module_generate(text, write["start"])
           for write in writes):
        errors.append("payload writer is under a module generate scope")
    if any(position_is_inside_procedural_span(text, write["start"])
           for write in writes):
        errors.append("payload writer is under procedural scope")
    exact_writes = 0
    for write in writes:
        selectors = write["selects"]
        if not selectors:
            errors.append(f"whole-bus write overlaps {signal}[{msb}:{lsb}]")
            continue
        if len(selectors) != 1:
            errors.append("payload LHS has a noncanonical selector chain")
            continue
        selector = expand_object_macros(selectors[0], definitions)
        bounds = [part.strip() for part in selector.split(":")]
        if len(bounds) == 1:
            bit = parse_verilog_integer(bounds[0])
            high = low = bit
        elif len(bounds) == 2:
            high = parse_verilog_integer(bounds[0])
            low = parse_verilog_integer(bounds[1])
        else:
            high = low = None
        if high is None or low is None or high < low:
            errors.append(f"payload writer has noncanonical select [{selectors[0]}]")
            continue
        overlaps = max(low, lsb) <= min(high, msb)
        is_exact = (
            high == msb and low == lsb and write["op"] == "="
            and write["kind"] == "continuous"
            and not position_is_under_module_generate(text, write["start"])
            and not position_is_inside_procedural_span(text, write["start"])
            and compact_expression(write["rhs"]) == source
        )
        if is_exact:
            exact_writes += 1
        elif overlaps:
            errors.append(
                f"payload writer [{high}:{low}] overlaps frozen identity slice"
            )
    if exact_writes != 1:
        errors.append(f"expected one exact identity-slice writer, found {exact_writes}")
    if signal_has_concatenated_lhs_write(text, signal):
        errors.append("concatenated payload LHS may overlap the identity slice")
    if re.search(
        rf"\b{re.escape(signal)}(?:\s*\[[^\]]+\])*\s*"
        r"(?:\+\+|--|(?:<<|>>|[+\-*/%&|^])=)",
        text,
    ):
        errors.append("compound payload write may overlap the identity slice")
    if register_is_user_task_actual(text, signal):
        errors.append("payload signal is passed to a user task")
    if signal_has_procedural_local_declaration(text, signal):
        errors.append("procedural local declaration shadows the payload signal")
    return errors


def elaborated_instance_errors(
    manifest: dict[str, Any], repo_root: Path, defines: tuple[str, ...]
) -> list[str]:
    """Verify canonical instances in Icarus' elaborated scope tree.

    Textual presence is insufficient because a canonical-looking instance may
    live under ``generate if (0)``.  Icarus VVP scopes provide the authoritative
    active hierarchy for the same release/OOO_ASSERT variant used by the source
    checker.
    """
    errors: list[str] = []
    module_files = manifest.get("module_files", {})
    module_names = set(module_files)
    edges = manifest.get("instance_connections", [])
    referenced = {
        item.get(side) for item in edges for side in ("host", "child")
    }
    missing_definitions = sorted(
        name for name in referenced if name not in module_names
    )
    if missing_definitions:
        return [
            "elaboration module_files lacks critical definitions: "
            + ", ".join(missing_definitions)
        ]

    reachable = {"NpcCoreTop"}
    while True:
        expanded = reachable | {
            item["child"] for item in edges if item["host"] in reachable
        }
        if expanded == reachable:
            break
        reachable = expanded
    unreachable = sorted(
        f"{item['host']}->{item['child']}"
        for item in edges if item["host"] not in reachable
    )
    if unreachable:
        return [
            "critical instance edges are unreachable from NpcCoreTop: "
            + ", ".join(unreachable)
        ]

    source_paths: list[Path] = []
    seen_paths: set[Path] = set()
    for module, relative in module_files.items():
        path = (repo_root / relative).resolve()
        if not path.is_file():
            errors.append(f"elaboration source missing for {module}: {relative}")
            continue
        raw = code_only(path.read_text(encoding="utf-8"))
        if module_body(raw, module) is None:
            errors.append(
                f"elaboration source does not textually define {module}: {relative}"
            )
        if path not in seen_paths:
            source_paths.append(path)
            seen_paths.add(path)
    if errors:
        return errors

    vsrc = repo_root / "npc/rv64/vsrc"
    with tempfile.TemporaryDirectory(prefix="q2-elab-") as temp_dir:
        vvp_path = Path(temp_dir) / "scopes.vvp"
        command = [
            "iverilog", "-g2012", "-i", "-tvvp", "-s", "NpcCoreTop",
            "-I", str(vsrc / "include"),
            "-I", str(vsrc),
            *(f"-D{define}" for define in defines),
            "-o", str(vvp_path),
            *(str(path) for path in source_paths),
        ]
        try:
            result = subprocess.run(
                command,
                cwd=repo_root,
                check=False,
                capture_output=True,
                text=True,
                timeout=60,
            )
        except (OSError, subprocess.TimeoutExpired) as exc:
            return [f"Icarus elaboration failed to execute: {exc}"]
        if result.returncode != 0 or not vvp_path.is_file():
            detail = result.stderr.strip().splitlines()
            return [
                "Icarus elaboration failed"
                + (f": {detail[-1]}" if detail else "")
            ]
        vvp_text = vvp_path.read_text(encoding="utf-8", errors="replace")

    scope_pattern = re.compile(
        r'^(?P<id>\S+)\s+\.scope\s+(?P<kind>module|generate),\s*'
        r'"(?P<name>[^"]+)"\s+"(?P<type>[^"]+)"(?P<tail>.*);$',
        flags=re.M,
    )
    scopes: dict[str, dict[str, str | None]] = {}
    for match in scope_pattern.finditer(vvp_text):
        tail = match.group("tail")
        parent_match = re.search(r",\s*(?P<parent>S_\S+)\s*$", tail)
        scopes[match.group("id")] = {
            "kind": match.group("kind"),
            "name": match.group("name"),
            "type": match.group("type"),
            "parent": parent_match.group("parent") if parent_match else None,
        }
    roots = [
        scope_id for scope_id, scope in scopes.items()
        if scope["kind"] == "module"
        and scope["type"] == "NpcCoreTop"
        and scope["name"] == "NpcCoreTop"
        and scope["parent"] is None
    ]
    if len(roots) != 1:
        return [f"elaboration expected one NpcCoreTop root, found {len(roots)}"]
    dangling = sorted({
        str(scope["parent"])
        for scope in scopes.values()
        if scope["parent"] is not None and scope["parent"] not in scopes
    })
    if dangling:
        return [
            "elaboration scope parent graph is incomplete: "
            + ", ".join(dangling[:8])
        ]

    def stable_path(scope_id: str) -> str:
        names: list[str] = []
        current: str | None = scope_id
        visited: set[str] = set()
        while current is not None and current in scopes and current not in visited:
            visited.add(current)
            names.append(str(scopes[current]["name"]))
            current = scopes[current]["parent"]  # type: ignore[assignment]
        return "/".join(reversed(names))

    def module_parent(scope_id: str) -> str | None:
        current = scopes[scope_id]["parent"]
        visited: set[str] = set()
        while current is not None and current in scopes and current not in visited:
            visited.add(current)
            if scopes[current]["kind"] == "module":
                return current
            current = scopes[current]["parent"]
        return None

    for item in edges:
        expected_instance = item.get("instance")
        if not expected_instance:
            errors.append(
                f"elaboration contract lacks instance name for "
                f"{item['host']}->{item['child']}"
            )
            continue
        hosts = [
            scope_id for scope_id, scope in scopes.items()
            if scope["kind"] == "module" and scope["type"] == item["host"]
        ]
        if not hosts:
            errors.append(f"elaboration has no live host module {item['host']}")
            continue
        for host_id in hosts:
            candidates = [
                scope_id for scope_id, scope in scopes.items()
                if scope["kind"] == "module"
                and scope["type"] == item["child"]
                and scope["name"] == expected_instance
                and module_parent(scope_id) == host_id
            ]
            if len(candidates) != 1:
                errors.append(
                    f"elaboration {stable_path(host_id)} expects one "
                    f"{expected_instance}:{item['child']}, found {len(candidates)}"
                )
    return errors


def cone_expressions(
    expressions: dict[str, list[str]], target: str
) -> list[str]:
    result: list[str] = []
    todo = [target]
    seen: set[str] = set()
    while todo:
        node = todo.pop()
        if node in seen:
            continue
        seen.add(node)
        for rhs in expressions.get(node, []):
            result.append(rhs)
            for dependency in re.findall(r"\b[A-Za-z_][A-Za-z0-9_$]*\b", rhs):
                if dependency in expressions and dependency not in seen:
                    todo.append(dependency)
    return result


def has_absorbing_constant(expression: str) -> bool:
    zero = (
        r"(?:\b0\b|'\s*0\b|\d+\s*'\s*[bBdDhHoO]\s*0+\b|"
        r"\{\s*\d+\s*\{\s*1\s*'\s*[bB]\s*0\s*\}\s*\})"
    )
    one = (
        r"(?:\b1\b|'\s*1\b|\d+\s*'\s*[bB]\s*1+\b|"
        r"\d+\s*'\s*[hH]\s*[fF]+\b|"
        r"\{\s*\d+\s*\{\s*1\s*'\s*[bB]\s*1\s*\}\s*\})"
    )
    return any(
        re.search(pattern, expression)
        for pattern in (
            rf"{zero}\s*(?:&&|&)", rf"(?:&&|&)\s*{zero}",
            rf"{one}\s*(?:\|\||\|)", rf"(?:\|\||\|)\s*{one}",
        )
    )


def strip_balanced_outer_parentheses(expression: str) -> str:
    result = expression.strip()
    while result.startswith("(") and result.endswith(")"):
        depth = 0
        closes_at_end = False
        for index, char in enumerate(result):
            if char == "(":
                depth += 1
            elif char == ")":
                depth -= 1
                if depth < 0:
                    return result
                if depth == 0:
                    closes_at_end = index == len(result) - 1
                    break
        if not closes_at_end:
            break
        result = result[1:-1].strip()
    return result


def exact_equality_expression(expression: str, left: str, right: str) -> bool:
    normalized = re.sub(
        r"\s+", "", strip_balanced_outer_parentheses(expression)
    )
    return normalized in {f"{left}=={right}", f"{right}=={left}"}


def compact_expression(expression: str) -> str:
    return re.sub(r"\s+", "", strip_balanced_outer_parentheses(expression))


def source_is_explicitly_negated(expression: str, source: str) -> bool:
    return re.search(
        rf"(?:!|~)\s*(?:\(\s*)*{re.escape(source)}\b", expression
    ) is not None


def expression_operators(expression: str) -> set[str]:
    operators: set[str] = set()
    if "&&" in expression:
        operators.add("&&")
    if "||" in expression:
        operators.add("||")
    if "==" in expression:
        operators.add("==")
    if re.search(r"(?<![=!])!(?!=)", expression):
        operators.add("!")
    if re.search(r"(?<!&)&(?!&)", expression):
        operators.add("&")
    if re.search(r"(?<!\|)\|(?!\|)", expression):
        operators.add("|")
    return operators


def boolean_requirement_errors(
    body: str, requirement: dict[str, Any]
) -> list[str]:
    target = requirement["target"]
    expressions = assignment_expressions(body, include_sequential=False)
    cone = cone_expressions(expressions, target)
    if not cone:
        return [f"{target} has no combinational equation"]
    joined = "\n".join(cone)
    errors: list[str] = []
    graph = assignment_graph(body, include_sequential=False)
    missing = [source for source in requirement.get("sources", [])
               if not depends_on(graph, target, source)]
    if missing:
        errors.append("missing boolean sources " + ", ".join(missing))
    for operator in requirement.get("required_operators", []):
        if operator not in joined:
            errors.append(f"missing required operator {operator}")
    for operator in requirement.get("forbidden_operators", []):
        if operator in joined:
            errors.append(f"contains forbidden operator {operator}")
    equality_pair = requirement.get("equality_pair")
    if equality_pair is not None:
        direct = expressions.get(target, [])
        if len(equality_pair) != 2 or len(direct) != 1 or not exact_equality_expression(
            direct[0], equality_pair[0], equality_pair[1]
        ):
            errors.append(
                "direct equation is not the exact required positive equality"
            )
    exact_expression = requirement.get("exact_expression")
    if exact_expression is not None:
        direct = expressions.get(target, [])
        if len(direct) != 1 or compact_expression(direct[0]) != compact_expression(
            exact_expression
        ):
            errors.append("direct equation differs from frozen canonical expression")
        target_writes = direct_signal_writes(body, target)
        if any(position_is_under_conditional_if(body, write["start"])
               for write in target_writes):
            errors.append("critical equation is hidden in a conditional generate/if arm")
    for source in requirement.get("positive_sources", []):
        if any(source_is_explicitly_negated(expression, source)
               for expression in cone):
            errors.append(f"positive source is explicitly negated: {source}")
    for source in requirement.get("negated_sources", []):
        if not any(source_is_explicitly_negated(expression, source)
                   for expression in cone):
            errors.append(f"source is not explicitly negated: {source}")
    if requirement.get("forbid_absorbing_constants") and any(
        has_absorbing_constant(expression) for expression in cone
    ):
        errors.append("dependency cone contains an absorbing constant")
    if requirement.get("forbid_ternary_xor") and re.search(r"[?^]", joined):
        errors.append("dependency cone contains forbidden ternary/XOR logic")
    return errors


def expanded_requirement(
    requirement: dict[str, Any], definitions: dict[str, str]
) -> dict[str, Any]:
    expanded = dict(requirement)
    if isinstance(expanded.get("exact_expression"), str):
        expanded["exact_expression"] = expand_object_macros(
            expanded["exact_expression"], definitions
        )
    return expanded


def macro_contract_errors(
    manifest: dict[str, Any], definitions: dict[str, str]
) -> list[str]:
    errors: list[str] = []
    required = manifest.get("required_macro_definitions", [])
    expected_entries = [
        {
            "file": "npc/rv64/vsrc/include/define.v",
            "name": name,
            "exact": exact,
        }
        for name, exact in EXPECTED_MACRO_DEFINITIONS.items()
    ]
    if required != expected_entries:
        errors.append("required macro-definition inventory differs from frozen values")
        return errors

    actual_values: dict[str, int] = {}
    for name, expected in EXPECTED_MACRO_DEFINITIONS.items():
        actual = definitions.get(name)
        if actual is None:
            errors.append(f"define.v lacks required macro {name}")
            continue
        if compact_expression(actual) != compact_expression(expected):
            errors.append(
                f"define.v macro {name} differs: expected {expected}, got {actual}"
            )
            continue
        numeric = parse_verilog_integer(expand_object_macros(actual, definitions))
        if numeric is not None:
            actual_values[name] = numeric

    layout_names = [
        "OOO_CONTEXT_ID_W", "OOO_CONTEXT_ID_LSB", "OOO_CONTEXT_ID_MSB",
        "OOO_CONTEXT_OWNER_W", "OOO_CONTEXT_OWNER_LSB", "OOO_CONTEXT_OWNER_MSB",
        "OOO_CONTEXT_PAYLOAD_W",
    ]
    if all(name in actual_values for name in layout_names):
        id_lsb = actual_values["OOO_CONTEXT_ID_LSB"]
        id_msb = actual_values["OOO_CONTEXT_ID_MSB"]
        owner_lsb = actual_values["OOO_CONTEXT_OWNER_LSB"]
        owner_msb = actual_values["OOO_CONTEXT_OWNER_MSB"]
        payload_w = actual_values["OOO_CONTEXT_PAYLOAD_W"]
        if id_msb - id_lsb + 1 != actual_values["OOO_CONTEXT_ID_W"]:
            errors.append("identity payload field width does not equal OOO_CONTEXT_ID_W")
        if owner_msb - owner_lsb + 1 != actual_values["OOO_CONTEXT_OWNER_W"]:
            errors.append("owner payload field width does not equal OOO_CONTEXT_OWNER_W")
        if id_lsb < 0 or owner_lsb < 0 or id_msb >= payload_w or owner_msb >= payload_w:
            errors.append("identity/owner payload field is outside OOO_CONTEXT_PAYLOAD_W")
        if max(id_lsb, owner_lsb) <= min(id_msb, owner_msb):
            errors.append("identity and owner payload fields overlap")

    cause_names = list(manifest.get("context_cause_bits", {}).keys())
    cause_values: dict[str, int] = {}
    for cause in cause_names:
        macro = manifest["context_cause_bits"][cause].lstrip("`")
        if macro in actual_values:
            cause_values[cause] = actual_values[macro]
    if len(cause_values) == len(cause_names):
        values = list(cause_values.values())
        if any(value <= 0 or value & (value - 1) for value in values):
            errors.append("context cause macros are not one-hot")
        if len(set(values)) != len(values):
            errors.append("context cause macros reuse a bit value")
        for leaf, members in manifest.get("leaf_cause_membership", {}).items():
            mask_macro = manifest.get("leaf_cause_masks", {}).get(leaf, "").lstrip("`")
            actual_mask = actual_values.get(mask_macro)
            expected_mask = 0
            complete = True
            for member in members:
                if member not in cause_values:
                    complete = False
                    break
                expected_mask |= cause_values[member]
            if complete and actual_mask is not None and actual_mask != expected_mask:
                errors.append(
                    f"{leaf} cause mask value does not equal its frozen membership OR"
                )
    return errors


def validate_manifest(manifest: dict[str, Any]) -> list[str]:
    errors: list[str] = []
    if manifest.get("schema") != "s2-q2-live-epoch-interface-v7":
        errors.append("unexpected interface schema")
    actual_lock = contract_lock_sha256(manifest)
    if manifest.get("contract_lock_sha256") != EXPECTED_CONTRACT_LOCK_SHA256 or \
            actual_lock != EXPECTED_CONTRACT_LOCK_SHA256:
        errors.append("manifest contract-lock digest differs from frozen checker digest")
    if evidence_baseline_sha256(manifest) != EXPECTED_EVIDENCE_BASELINE_SHA256:
        errors.append("evidence baseline differs from separately reviewed frozen digest")
    if manifest.get("canonical_reset_predicate") != "rst":
        errors.append("canonical outer reset predicate must be exact positive rst")
    if manifest.get("unique_combinational_driver_policy") != {
        "legal_driver_kinds": [
            "module-scope-assign",
            "module-scope-wire-declaration-assignment",
        ],
        "audited_collections": [
            "boolean_requirements",
            "exact_next_expressions",
            "epoch_register_captures",
            "next_signal_source_groups",
        ],
        "age_provenance_targets": [
            "OooStoreQueue.context_squash_age_scan_done_w",
            "OooMemOwnerTracker.context_squash_age_scan_done_w",
        ],
        "reject_variable_initializers": True,
        "reject_procedural_or_generate_scope": True,
        "reject_concat_compound_or_subroutine_writers": True,
        "reject_unknown_or_output_instance_drivers": True,
    }:
        errors.append("unique combinational-driver policy differs from frozen v7 map")
    if manifest.get("canonical_sequential_writer_policy") != {
        "event_control": "always-at-exact-posedge-clk",
        "reset_predicate": "exact-positive-rst",
        "reset_identifier_must_be_declared_constant": True,
        "nonreset_if_ancestors": [{"condition": "rst", "arm": "false"}],
        "forbid_nested_event_delay_wait": True,
    }:
        errors.append("canonical sequential-writer policy differs from frozen v7 map")
    if manifest.get("canonical_control_source_policy") != {
        "modules": [
            "CsrFile", "NpcCoreTop", "OooControlPlane", "OooFetchAxiBridge",
            "OooIntBackend", "OooMemInflightQueue", "OooMemOwnerTracker",
            "OooMmuEpochOwner", "OooStoreQueue",
        ],
        "signals": ["clk", "rst"],
        "require_lexical_input_port": True,
        "forbid_host_or_instance_output_driver": True,
    }:
        errors.append("canonical clock/reset source policy differs from frozen v7 map")
    if manifest.get("critical_symbol_declaration_policy") != {
        "require_exactly_one_declaration": True,
        "require_host_module_lexical_scope": True,
        "audit_targets_and_frozen_sources": True,
        "audit_required_ports": True,
        "audit_reset_and_clock": True,
        "audit_instance_map_signals": True,
    }:
        errors.append("critical symbol declaration policy differs from frozen v7 map")
    if manifest.get("phase_order") != ["CAPTURE", "SQUASH", "WAIT_QUIET", "GRANT"]:
        errors.append("phase order is not CAPTURE->SQUASH->WAIT_QUIET->GRANT")
    scope = manifest.get("scope", {})
    if scope.get("memory_lanes") != 1 or scope.get("issue1_memory_enabled") is not False:
        errors.append("scope must remain mem0-only with issue1 memory disabled")
    if scope.get("structural_pass_is_sufficient") is not False:
        errors.append("manifest incorrectly treats structural PASS as sufficient")
    if scope.get("ifu_policy") != "generation-matched-sticky-drain-and-block":
        errors.append("Q2 IFU policy must require generation-matched sticky drain")
    if scope.get("fencei_policy") != "separate-serialize-no-data-epoch":
        errors.append("FENCE.I must serialize separately without advancing data epoch")
    expected_hazards = {
        "owner_alloc", "sq_bind_or_fill", "reservation_or_buffer_capture",
        "terminal_ingress", "bridge_station_ingress",
        "ptw_or_rmw_station_ingress", "ifu_or_fpc_fill",
    }
    if set(manifest.get("same_cycle_hazards", [])) != expected_hazards:
        errors.append("same-cycle ingress hazard set is incomplete")
    if manifest.get("context_cause_bits") != {
        "SATP": "`OOO_CONTEXT_CAUSE_SATP",
        "SFENCE_VMA": "`OOO_CONTEXT_CAUSE_SFENCE_VMA",
        "ACCESS_CONTEXT": "`OOO_CONTEXT_CAUSE_ACCESS_CONTEXT",
        "PBMTE": "`OOO_CONTEXT_CAUSE_PBMTE",
        "PMP": "`OOO_CONTEXT_CAUSE_PMP",
        "TRAP": "`OOO_CONTEXT_CAUSE_TRAP",
        "XRET": "`OOO_CONTEXT_CAUSE_XRET",
    } or manifest.get("leaf_cause_masks") != {
        "DTLB": "`OOO_CONTEXT_DTLB_CAUSE_MASK",
        "ITLB": "`OOO_CONTEXT_ITLB_CAUSE_MASK",
        "FPC": "`OOO_CONTEXT_FPC_CAUSE_MASK",
    }:
        errors.append("typed context cause bits/leaf masks differ from frozen map")
    if manifest.get("leaf_cause_membership") != EXPECTED_LEAF_CAUSE_MEMBERSHIP:
        errors.append("typed leaf cause membership differs from frozen exact map")
    if manifest.get("payload_fields") != EXPECTED_PAYLOAD_FIELDS:
        errors.append("payload identity/owner field layout differs from frozen map")
    expected_macro_entries = [
        {
            "file": "npc/rv64/vsrc/include/define.v",
            "name": name,
            "exact": exact,
        }
        for name, exact in EXPECTED_MACRO_DEFINITIONS.items()
    ]
    if manifest.get("required_macro_definitions") != expected_macro_entries:
        errors.append("required macro-definition values differ from frozen inventory")
    if manifest.get("self_test_inventory") != EXPECTED_SELF_TEST_INVENTORY:
        errors.append("checker self-test name/order inventory differs from frozen list")

    expected_exclusive_outputs = {
        (
            "OooCoreTopGlue", "OooFrontend", "u_frontend",
            "head0_fencei_raw_w", "head0_fencei_raw_w",
        ),
        (
            "OooCoreTopGlue", "OooExecuteBackend", "u_execute_backend",
            "core_commit0_valid_w", "core_commit0_valid_w",
        ),
        (
            "OooCoreTopGlue", "OooExecuteBackend", "u_execute_backend",
            "core_mem_idle_w", "core_mem_idle_w",
        ),
        (
            "OooCoreTopGlue", "OooExecuteBackend", "u_execute_backend",
            "core_mem_retire_quiet_w", "core_mem_retire_quiet_w",
        ),
        (
            "OooIntBackend", "OooMemInflightQueue", "u_mem_inflight_queue",
            "head_mmu_epoch_o", "miq_head_mmu_epoch_w",
        ),
        (
            "OooIntBackend", "OooStoreQueue", "u_store_queue",
            "context_squash_done_o", "sq_context_squash_done_w",
        ),
        (
            "OooIntBackend", "OooMemOwnerTracker", "u_mem_owner_tracker",
            "context_squash_done_o", "owner_context_squash_done_w",
        ),
    }
    actual_exclusive_outputs = {
        (
            item.get("host"), item.get("child"), item.get("instance"),
            item.get("port"), item.get("signal"),
        )
        for item in manifest.get("exclusive_instance_outputs", [])
    }
    if actual_exclusive_outputs != expected_exclusive_outputs or \
            len(actual_exclusive_outputs) != len(
                manifest.get("exclusive_instance_outputs", [])
            ):
        errors.append("exclusive child-output producer inventory differs from frozen set")
    producer_signals = [
        (item.get("host"), item.get("signal"))
        for item in manifest.get("exclusive_instance_outputs", [])
    ]
    if len(producer_signals) != len(set(producer_signals)):
        errors.append("exclusive child-output inventory repeats a host signal")

    expected_payload_slices = [{
        "module": "CsrFile",
        "signal": "context_payload_o",
        "field": "IDENTITY",
        "source": "context_prepare_identity_i",
        "msb": "`OOO_CONTEXT_ID_MSB",
        "lsb": "`OOO_CONTEXT_ID_LSB",
        "assignment_kind": "continuous",
    }]
    if manifest.get("exact_payload_slices") != expected_payload_slices:
        errors.append("exact CSR payload-slice producer inventory differs from frozen map")

    expected_guarded_captures = {
        (
            "OooMemInflightQueue", "mmu_epoch_q", "tail_q",
            "push_mmu_epoch_i", "push_fire_w",
        ),
        (
            "OooStoreQueue", "rob_idx_q", "alloc0_idx_w",
            "alloc0_rob_idx_i", "alloc0_fire_w",
        ),
        (
            "OooMemOwnerTracker", "rob_idx_q", "alloc0_token_o",
            "alloc0_rob_idx_i", "alloc0_fire_w",
        ),
        (
            "OooMemOwnerTracker", "irrevocable_q", "irrevocable_token_i",
            "1'b1", "irrevocable_fire_w",
        ),
    }
    actual_guarded_captures = {
        (
            item.get("module"), item.get("register"), item.get("index"),
            item.get("source"), item.get("guard"),
        )
        for item in manifest.get("guarded_indexed_captures", [])
    }
    if actual_guarded_captures != expected_guarded_captures or \
            len(actual_guarded_captures) != len(
                manifest.get("guarded_indexed_captures", [])
            ):
        errors.append("guarded indexed provenance inventory differs from frozen set")
    expected_guarded_ancestors = {
        ("OooMemInflightQueue", "mmu_epoch_q"): (
            ("rst", "false"), ("flush_i", "false"),
            ("push_fire_w", "true"),
        ),
        ("OooStoreQueue", "rob_idx_q"): (
            ("rst", "false"), ("flush_valid_i", "false"),
            ("alloc0_fire_w", "true"),
        ),
        ("OooMemOwnerTracker", "rob_idx_q"): (
            ("rst", "false"), ("alloc0_fire_w", "true"),
        ),
        ("OooMemOwnerTracker", "irrevocable_q"): (
            ("rst", "false"), ("irrevocable_fire_w", "true"),
        ),
    }
    actual_guarded_ancestors = {
        (item.get("module"), item.get("register")): tuple(
            (compact_expression(ancestor.get("condition", "")), ancestor.get("arm"))
            for ancestor in item.get("canonical_ancestors", [])
        )
        for item in manifest.get("guarded_indexed_captures", [])
    }
    if actual_guarded_ancestors != expected_guarded_ancestors:
        errors.append("guarded capture ancestor paths differ from frozen v6 maps")
    expected_guarded_write_multisets = {
        ("OooMemInflightQueue", "mmu_epoch_q"): Counter({
            ("i", "{MMU_EPOCH_W{1'b0}}", "<=", "reset"): 1,
            ("wr[ENTRY_W-1:0]", "mmu_epoch_q[src]", "<=", "nonreset"): 1,
            ("tail_q", "push_mmu_epoch_i", "<=", "nonreset"): 1,
        }),
        ("OooStoreQueue", "rob_idx_q"): Counter({
            ("i", "{ROB_INDEX_W{1'b0}}", "<=", "reset"): 1,
            ("alloc0_idx_w", "alloc0_rob_idx_i", "<=", "nonreset"): 1,
            ("alloc1_idx_w", "alloc1_rob_idx_i", "<=", "nonreset"): 1,
        }),
        ("OooMemOwnerTracker", "rob_idx_q"): Counter({
            ("i", "{ROB_INDEX_W{1'b0}}", "<=", "reset"): 1,
            ("alloc0_token_o", "alloc0_rob_idx_i", "<=", "nonreset"): 1,
        }),
        ("OooMemOwnerTracker", "irrevocable_q"): Counter({
            ("i", "1'b0", "<=", "reset"): 1,
            ("alloc0_token_o", "1'b0", "<=", "nonreset"): 1,
            ("irrevocable_token_i", "1'b1", "<=", "nonreset"): 1,
        }),
    }
    actual_guarded_write_multisets = {
        (item.get("module"), item.get("register")): Counter(
            (
                compact_expression(write.get("index", "")),
                compact_expression(write.get("source", "")),
                write.get("op", "<="),
                write.get("region", ""),
            )
            for write in item.get("allowed_writes", [])
        )
        for item in manifest.get("guarded_indexed_captures", [])
    }
    if actual_guarded_write_multisets != expected_guarded_write_multisets:
        errors.append("guarded array full-writer inventories differ from frozen maps")

    required_ports = {
        ("CsrFile", "context_boundary_active_i"),
        ("CsrFile", "context_abort_valid_i"),
        ("CsrFile", "context_reserve_valid_i"),
        ("CsrFile", "context_reserve_ready_o"),
        ("CsrFile", "context_writer_owned_o"),
        ("OooIntBackend", "mem_context_squash_valid_i"),
        ("OooIntBackend", "mem_context_squash_identity_i"),
        ("OooIntBackend", "mem_context_squash_done_o"),
        ("OooFetchAxiBridge", "context_squash_valid_i"),
        ("OooFetchAxiBridge", "context_squash_generation_i"),
        ("OooFetchAxiBridge", "context_squash_done_o"),
        ("OooFetchAxiBridge", "context_squash_ack_generation_o"),
        ("OooFetchAxiBridge", "fencei_squash_valid_i"),
        ("OooFetchAxiBridge", "fencei_squash_generation_i"),
        ("OooFetchAxiBridge", "fencei_squash_done_o"),
        ("OooFetchAxiBridge", "fencei_commit_fire_i"),
        ("OooMemoryRequestGate", "translation_context_invalidate_i"),
        ("OooMemAxiBridge", "translation_context_invalidate_i"),
        ("OooFetchAxiBridge", "translation_context_invalidate_i"),
        ("OooControlPlane", "context_boundary_grant_fire_i"),
        ("OooControlPlane", "mem_retire_quiet_i"),
        ("OooControlPlane", "mem_idle_i"),
        ("OooControlPlane", "head0_fencei_raw_w"),
        ("OooControlPlane", "core_commit0_valid_w"),
        ("OooControlPlane", "fencei_retire_permit_o"),
        ("OooControlPlane", "fencei_commit_fire_o"),
        ("OooRob", "fencei_retire_permit_i"),
        ("OooFrontend", "context_boundary_redirect_valid_i"),
        ("OooFrontend", "head0_fencei_raw_w"),
        ("OooExecuteBackend", "core_commit0_valid_w"),
        ("OooExecuteBackend", "core_mem_idle_w"),
        ("OooExecuteBackend", "core_mem_retire_quiet_w"),
        ("OooMemInflightQueue", "push_valid_i"),
        ("OooMemInflightQueue", "push_mmu_epoch_i"),
        ("OooMemInflightQueue", "head_mmu_epoch_o"),
        ("OooStoreQueue", "context_squash_valid_i"),
        ("OooStoreQueue", "context_squash_identity_i"),
        ("OooStoreQueue", "context_squash_done_o"),
        ("OooStoreQueue", "rob_head_idx_i"),
        ("OooStoreQueue", "alloc0_rob_idx_i"),
        ("OooStoreQueue", "alloc1_rob_idx_i"),
        ("OooMemOwnerTracker", "context_squash_valid_i"),
        ("OooMemOwnerTracker", "context_squash_identity_i"),
        ("OooMemOwnerTracker", "context_squash_done_o"),
        ("OooMemOwnerTracker", "rob_head_idx_i"),
        ("OooMemOwnerTracker", "alloc0_rob_idx_i"),
        ("OooMemOwnerTracker", "alloc0_epoch_i"),
        ("OooMemOwnerTracker", "irrevocable_valid_i"),
        ("OooMemOwnerTracker", "irrevocable_kind_i"),
        ("OooMemOwnerTracker", "irrevocable_token_i"),
        ("OooMemOwnerTracker", "irrevocable_epoch_i"),
        ("OooFetchAxiBridge", "fetch_req_ready_o"),
        ("OooMmuEpochOwner", "abort_i"),
    }
    actual_ports = {
        (item.get("module"), item.get("port"))
        for item in manifest.get("required_ports", [])
    }
    if not required_ports <= actual_ports:
        errors.append("required squash/legacy-writer/invalidate ports were removed")
    required_port_directions = {
        ("OooFrontend", "output", "head0_fencei_raw_w"),
        ("OooExecuteBackend", "output", "core_commit0_valid_w"),
        ("OooExecuteBackend", "output", "core_mem_idle_w"),
        ("OooExecuteBackend", "output", "core_mem_retire_quiet_w"),
        ("OooMemInflightQueue", "input", "push_valid_i"),
        ("OooMemInflightQueue", "input", "push_mmu_epoch_i"),
        ("OooMemInflightQueue", "output", "head_mmu_epoch_o"),
        ("OooStoreQueue", "input", "context_squash_valid_i"),
        ("OooStoreQueue", "input", "context_squash_identity_i"),
        ("OooStoreQueue", "output", "context_squash_done_o"),
        ("OooStoreQueue", "input", "rob_head_idx_i"),
        ("OooStoreQueue", "input", "alloc0_rob_idx_i"),
        ("OooStoreQueue", "input", "alloc1_rob_idx_i"),
        ("OooMemOwnerTracker", "input", "context_squash_valid_i"),
        ("OooMemOwnerTracker", "input", "context_squash_identity_i"),
        ("OooMemOwnerTracker", "output", "context_squash_done_o"),
        ("OooMemOwnerTracker", "input", "rob_head_idx_i"),
        ("OooMemOwnerTracker", "input", "alloc0_rob_idx_i"),
        ("OooMemOwnerTracker", "input", "alloc0_epoch_i"),
        ("OooMemOwnerTracker", "input", "irrevocable_valid_i"),
        ("OooMemOwnerTracker", "input", "irrevocable_kind_i"),
        ("OooMemOwnerTracker", "input", "irrevocable_token_i"),
        ("OooMemOwnerTracker", "input", "irrevocable_epoch_i"),
    }
    actual_port_directions = {
        (item.get("module"), item.get("direction"), item.get("port"))
        for item in manifest.get("required_ports", [])
    }
    if not required_port_directions <= actual_port_directions:
        errors.append("critical producer/squash port directions were weakened")

    manifest_connections = {
        (item.get("host"), item.get("child"), port): signal
        for item in manifest.get("instance_connections", [])
        for port, signal in item.get("ports", {}).items()
    }
    required_provenance_connections = {
        ("OooCoreTopGlue", "OooFrontend", "head0_fencei_raw_w"):
            "head0_fencei_raw_w",
        ("OooCoreTopGlue", "OooExecuteBackend", "core_commit0_valid_w"):
            "core_commit0_valid_w",
        ("OooCoreTopGlue", "OooExecuteBackend", "core_mem_idle_w"):
            "core_mem_idle_w",
        ("OooCoreTopGlue", "OooExecuteBackend", "core_mem_retire_quiet_w"):
            "core_mem_retire_quiet_w",
        ("OooIntBackend", "OooMemInflightQueue", "push_valid_i"):
            "miq_push_valid_w",
        ("OooIntBackend", "OooMemInflightQueue", "push_mmu_epoch_i"):
            "miq_push_mmu_epoch_w",
        ("OooIntBackend", "OooMemInflightQueue", "head_mmu_epoch_o"):
            "miq_head_mmu_epoch_w",
        ("OooIntBackend", "OooStoreQueue", "context_squash_valid_i"):
            "mem_context_squash_valid_i",
        ("OooIntBackend", "OooStoreQueue", "context_squash_identity_i"):
            "mem_context_squash_identity_i",
        ("OooIntBackend", "OooStoreQueue", "context_squash_done_o"):
            "sq_context_squash_done_w",
        ("OooIntBackend", "OooStoreQueue", "rob_head_idx_i"):
            "rob_head_idx_w",
        ("OooIntBackend", "OooStoreQueue", "alloc0_rob_idx_i"):
            "sq_alloc0_rob_w",
        ("OooIntBackend", "OooStoreQueue", "alloc1_rob_idx_i"):
            "dispatch1_rob_idx_w",
        ("OooIntBackend", "OooMemOwnerTracker", "context_squash_valid_i"):
            "mem_context_squash_valid_i",
        ("OooIntBackend", "OooMemOwnerTracker", "context_squash_identity_i"):
            "mem_context_squash_identity_i",
        ("OooIntBackend", "OooMemOwnerTracker", "context_squash_done_o"):
            "owner_context_squash_done_w",
        ("OooIntBackend", "OooMemOwnerTracker", "rob_head_idx_i"):
            "rob_head_idx_w",
        ("OooIntBackend", "OooMemOwnerTracker", "alloc0_rob_idx_i"):
            "iq_issue0_rob_idx_w",
        ("OooIntBackend", "OooMemOwnerTracker", "irrevocable_valid_i"):
            "mem_req_fire_any_w",
        ("OooIntBackend", "OooMemOwnerTracker", "irrevocable_kind_i"):
            "mem_req_owner_kind_o",
        ("OooIntBackend", "OooMemOwnerTracker", "irrevocable_token_i"):
            "mem_req_owner_token_o",
        ("OooIntBackend", "OooMemOwnerTracker", "irrevocable_epoch_i"):
            "mem_req_mmu_epoch_o",
    }
    if any(manifest_connections.get(key) != signal
           for key, signal in required_provenance_connections.items()):
        errors.append("FENCE/MIQ/selective-squash exact provenance maps were weakened")
    if any(
        manifest_connections.get((host, child, port)) != signal
        for host, child, _instance, port, signal in expected_exclusive_outputs
    ):
        errors.append("exclusive output inventory disagrees with instance maps")
    required_abort_connections = {
        ("NpcCoreTop", "OooMmuEpochOwner", "abort_i"):
            "mmu_epoch_abort_fire_w",
        ("NpcCoreTop", "CsrFile", "context_abort_valid_i"):
            "mmu_epoch_abort_fire_w",
    }
    if any(manifest_connections.get(key) != signal
           for key, signal in required_abort_connections.items()):
        errors.append("owner/CSR abort ports are not driven by one exact abort fire")

    required_dependencies = {
        ("NpcCoreTop", "mmu_epoch_wait_quiet_enable_w", "backend_mem_context_squash_done_w"),
        ("NpcCoreTop", "mmu_epoch_wait_quiet_enable_w", "ifu_context_squash_current_done_w"),
        ("NpcCoreTop", "mmu_epoch_held_head_match_w", "ooo_head0_identity_w"),
        ("NpcCoreTop", "mmu_epoch_held_head_match_w", "mmu_epoch_held_identity_w"),
        ("NpcCoreTop", "mmu_epoch_grant_ready_w", "mmu_epoch_held_head_match_w"),
        ("NpcCoreTop", "mmu_epoch_grant_ready_w", "mmu_epoch_identity_mismatch_recovery_q"),
        ("NpcCoreTop", "mmu_epoch_abort_fire_w", "mmu_epoch_identity_mismatch_recovery_q"),
        ("NpcCoreTop", "mmu_epoch_abort_fire_w", "mmu_epoch_grant_valid_w"),
        ("NpcCoreTop", "mmu_epoch_phase_next_w", "mmu_epoch_abort_fire_w"),
        ("NpcCoreTop", "mmu_epoch_identity_mismatch_recovery_next_w", "mmu_epoch_abort_fire_w"),
        ("NpcCoreTop", "translation_context_invalidate_w", "mmu_epoch_grant_fire_w"),
        ("NpcCoreTop", "lr_context_clear_w", "mmu_epoch_grant_fire_w"),
        ("CsrFile", "context_state_apply_fire_w", "context_apply_valid_i"),
        ("CsrFile", "context_state_apply_fire_w", "legacy_context_write_fire_w"),
        ("CsrFile", "context_writer_owned_o", "context_writer_owner_q"),
        ("CsrFile", "context_writer_owner_next_w", "context_abort_valid_i"),
        ("OooRob", "head1_context_boundary_w", "head1_potential_context_boundary_w"),
        ("OooFetchAxiBridge", "context_quiet_o", "fpc_write_pending_q"),
        ("OooControlPlane", "context_boundary_pending_system_clear_w", "context_boundary_grant_fire_i"),
        ("OooControlPlane", "context_boundary_pending_system_clear_w", "context_boundary_payload_owner_is_pending_system_w"),
        ("OooControlPlane", "core_local_flush_w", "context_boundary_grant_fire_i"),
        ("OooControlPlane", "fencei_serial_ready_next_w", "mem_retire_quiet_i"),
        ("OooControlPlane", "fencei_serial_ready_next_w", "fencei_ifu_cancel_current_done_w"),
        ("OooRob", "commit0_fire_w", "fencei_retire_permit_i"),
        ("OooFetchAxiBridge", "context_squash_done_o", "fetch_context_squash_generation_q"),
        ("OooFetchAxiBridge", "fencei_squash_done_o", "fencei_squash_generation_q"),
        ("OooMmuEpochOwner", "state_next_w", "abort_i"),
        ("OooMmuEpochOwner", "held_cause_next_w", "abort_i"),
        ("OooMmuEpochOwner", "held_payload_next_w", "abort_i"),
        ("OooStoreQueue", "context_squash_age_scan_done_w", "valid_q"),
        ("OooStoreQueue", "context_squash_age_scan_done_w", "request_sent_q"),
        ("OooStoreQueue", "context_squash_age_scan_done_w", "rob_idx_q"),
        ("OooStoreQueue", "context_squash_age_scan_done_w", "rob_head_idx_i"),
        ("OooStoreQueue", "context_squash_age_scan_done_w", "context_squash_identity_i"),
        ("OooMemOwnerTracker", "context_squash_age_scan_done_w", "live_q"),
        ("OooMemOwnerTracker", "context_squash_age_scan_done_w", "kind_q"),
        ("OooMemOwnerTracker", "context_squash_age_scan_done_w", "rob_idx_q"),
        ("OooMemOwnerTracker", "context_squash_age_scan_done_w", "irrevocable_q"),
        ("OooMemOwnerTracker", "context_squash_age_scan_done_w", "rob_head_idx_i"),
        ("OooMemOwnerTracker", "context_squash_age_scan_done_w", "context_squash_identity_i"),
    }
    actual_dependencies = {
        (item.get("module"), item.get("target"), source)
        for item in manifest.get("signal_dependencies", [])
        for source in item.get("sources", [])
    }
    if not required_dependencies <= actual_dependencies:
        errors.append("required squash/grant/lane1/IFU dependencies were removed")

    required_forbidden = {
        ("NpcCoreTop", "mmu_epoch_grant_ready_w", "head0_context_permit_w"),
        ("NpcCoreTop", "mmu_epoch_grant_ready_w", "ooo_commit0_fire_w"),
        ("NpcCoreTop", "mmu_epoch_grant_ready_w", "mmu_epoch_grant_fire_w"),
        ("NpcCoreTop", "mmu_epoch_grant_ready_w", "mmu_epoch_identity_mismatch_recovery_w"),
        ("NpcCoreTop", "mmu_epoch_abort_fire_w", "mmu_epoch_held_head_match_w"),
        ("NpcCoreTop", "fencei_commit_fire_w", "mmu_epoch_grant_fire_w"),
        ("NpcCoreTop", "mmu_epoch_request_valid_w", "fencei_commit_fire_w"),
        ("NpcCoreTop", "translation_context_invalidate_w", "fencei_commit_fire_w"),
        ("OooFetchAxiBridge", "context_squash_done_o", "context_squash_valid_i"),
        ("OooFetchAxiBridge", "fencei_squash_done_o", "fencei_squash_valid_i"),
        ("CsrFile", "context_writer_owned_o", "csr_commit_i"),
        ("CsrFile", "context_writer_owned_o", "trap_irq_valid_i"),
    }
    actual_forbidden = {
        (item.get("module"), item.get("target"), item.get("source"))
        for item in manifest.get("forbidden_dependencies", [])
    }
    if not required_forbidden <= actual_forbidden:
        errors.append("required grant-loop/FENCE.I forbidden edges were removed")
    expected_unique_writes = {
        ("CsrFile", "priv_mode_q", "context_priv_mode_next_w", False),
        ("CsrFile", "csr_mstatus_q", "context_mstatus_next_w", False),
        ("CsrFile", "csr_satp_q", "context_satp_next_w", False),
        ("CsrFile", "csr_menvcfg_q", "context_menvcfg_next_w", False),
        ("CsrFile", "csr_pmpcfg_q", "context_pmpcfg_next_w", True),
        ("CsrFile", "csr_pmpaddr_q", "context_pmpaddr_next_w", True),
        ("CsrFile", "csr_mepc_q", "context_mepc_next_w", False),
        ("CsrFile", "csr_sepc_q", "context_sepc_next_w", False),
        ("CsrFile", "csr_mcause_q", "context_mcause_next_w", False),
        ("CsrFile", "csr_scause_q", "context_scause_next_w", False),
        ("CsrFile", "csr_mtval_q", "context_mtval_next_w", False),
        ("CsrFile", "csr_stval_q", "context_stval_next_w", False),
        ("CsrFile", "context_writer_owner_q", "context_writer_owner_next_w", False),
        ("OooIntBackend", "reservation_valid_q", "reservation_valid_next_w", False),
        ("OooIntBackend", "mem_context_squash_identity_q", "mem_context_squash_identity_next_w", False),
        ("OooIntBackend", "mem_context_sq_done_seen_q", "mem_context_sq_done_seen_next_w", False),
        ("OooIntBackend", "mem_context_owner_done_seen_q", "mem_context_owner_done_seen_next_w", False),
        ("OooIntBackend", "mem_context_squash_ack_q", "mem_context_squash_ack_next_w", False),
        ("OooIntBackend", "mem_issue_res_mmu_epoch_q", "mem_issue_res_mmu_epoch_next_w", False),
        ("OooIntBackend", "mem_mmu_epoch_q", "mem_mmu_epoch_next_w", False),
        ("OooIntBackend", "mem_buffer_mmu_epoch_q", "mem_buffer_mmu_epoch_next_w", False),
        ("NpcCoreTop", "mmu_epoch_phase_q", "mmu_epoch_phase_next_w", False),
        ("NpcCoreTop", "mmu_epoch_squash_sent_q", "mmu_epoch_squash_sent_next_w", False),
        ("NpcCoreTop", "mmu_epoch_transaction_generation_q", "mmu_epoch_transaction_generation_next_w", False),
        ("NpcCoreTop", "mmu_epoch_identity_mismatch_recovery_q", "mmu_epoch_identity_mismatch_recovery_next_w", False),
        ("NpcCoreTop", "mmu_epoch_registered_quiet_q", "mmu_epoch_registered_quiet_next_w", False),
        ("OooMmuEpochOwner", "state_q", "state_next_w", False),
        ("OooMmuEpochOwner", "held_cause_q", "held_cause_next_w", False),
        ("OooMmuEpochOwner", "held_payload_q", "held_payload_next_w", False),
        ("OooStoreQueue", "context_squash_identity_q", "context_squash_identity_next_w", False),
        ("OooStoreQueue", "context_squash_ack_q", "context_squash_ack_next_w", False),
        ("OooMemOwnerTracker", "context_squash_identity_q", "context_squash_identity_next_w", False),
        ("OooMemOwnerTracker", "context_squash_ack_q", "context_squash_ack_next_w", False),
    }
    actual_unique_writes = {
        (item.get("module"), item.get("register"), item.get("next_signal"),
         bool(item.get("allow_indexed", False)))
        for item in manifest.get("unique_next_writes", [])
    }
    if not expected_unique_writes <= actual_unique_writes:
        errors.append("required unique-next writer inventory was weakened")
    boolean_items = manifest.get("boolean_requirements", [])
    boolean_keys = [
        (item.get("module"), item.get("target")) for item in boolean_items
    ]
    if len(boolean_keys) != len(set(boolean_keys)):
        errors.append("duplicate boolean-shape target in frozen inventory")
    for item in boolean_items:
        key = (item.get("module"), item.get("target"))
        exact_expression = item.get("exact_expression")
        if not isinstance(exact_expression, str) or not exact_expression.strip():
            errors.append(f"{key[0]}.{key[1]} lacks frozen canonical expression")
            continue
        expression_sources = set(re.findall(
            r"\b[A-Za-z_][A-Za-z0-9_$]*_(?:w|q|i|o)\b",
            exact_expression,
        ))
        declared_sources = set(item.get("sources", []))
        if declared_sources != expression_sources:
            errors.append(
                f"{key[0]}.{key[1]} source inventory differs from canonical expression"
            )
        expected_negated = {
            source for source in expression_sources
            if source_is_explicitly_negated(exact_expression, source)
        }
        expected_positive = expression_sources - expected_negated
        if set(item.get("negated_sources", [])) != expected_negated or \
                set(item.get("positive_sources", [])) != expected_positive:
            errors.append(
                f"{key[0]}.{key[1]} polarity inventory differs from canonical expression"
            )
        if set(item.get("required_operators", [])) != expression_operators(
            exact_expression
        ):
            errors.append(
                f"{key[0]}.{key[1]} operator inventory differs from canonical expression"
            )
        expected_forbidden = set() if "||" in exact_expression else {"||"}
        if set(item.get("forbidden_operators", [])) != expected_forbidden:
            errors.append(
                f"{key[0]}.{key[1]} forbidden-operator policy is inconsistent"
            )
        if item.get("forbid_absorbing_constants") is not True or \
                item.get("forbid_ternary_xor") is not True:
            errors.append(
                f"{key[0]}.{key[1]} constant/ternary/XOR policy was weakened"
            )
    actual_equality_pairs = {
        (item.get("module"), item.get("target")): item.get("equality_pair")
        for item in boolean_items if item.get("equality_pair") is not None
    }
    if actual_equality_pairs != {
        ("NpcCoreTop", "mmu_epoch_held_head_match_w"):
            ["ooo_head0_identity_w", "mmu_epoch_held_identity_w"]
    }:
        errors.append("held-identity exact positive equality policy was weakened")
    expected_widths = {
        ("OooRob", "head0_identity_o", "`OOO_CONTEXT_ID_W"),
        ("CsrFile", "context_prepare_identity_i", "`OOO_CONTEXT_ID_W"),
        ("CsrFile", "context_cause_o", "`OOO_CONTEXT_CAUSE_W"),
        ("CsrFile", "context_payload_o", "`OOO_CONTEXT_PAYLOAD_W"),
        ("CsrFile", "context_apply_payload_i", "`OOO_CONTEXT_PAYLOAD_W"),
        ("OooIntBackend", "mem_context_squash_identity_i", "`OOO_CONTEXT_ID_W"),
        ("OooIntBackend", "mem_req_mmu_epoch_o", "`OOO_MMU_EPOCH_W"),
        ("OooIntBackend", "head0_identity_o", "`OOO_CONTEXT_ID_W"),
        ("OooDispatchBackend", "head0_identity_o", "`OOO_CONTEXT_ID_W"),
        ("OooCoreTopGlue", "translation_context_cause_i", "`OOO_CONTEXT_CAUSE_W"),
        ("OooCoreTopGlue", "context_boundary_grant_payload_i", "`OOO_CONTEXT_PAYLOAD_W"),
        ("OooControlPlane", "context_boundary_grant_payload_i", "`OOO_CONTEXT_PAYLOAD_W"),
        ("OooMemoryAccess", "translation_context_cause_i", "`OOO_CONTEXT_CAUSE_W"),
        ("OooMemoryRequestGate", "translation_context_cause_i", "`OOO_CONTEXT_CAUSE_W"),
        ("OooMemAxiBridge", "translation_context_cause_i", "`OOO_CONTEXT_CAUSE_W"),
        ("OooFetchAxiBridge", "translation_context_cause_i", "`OOO_CONTEXT_CAUSE_W"),
        ("OooFetchAxiBridge", "context_squash_generation_i", "`OOO_CONTEXT_GENERATION_W"),
        ("OooMemInflightQueue", "head_mmu_epoch_o", "MMU_EPOCH_W"),
        ("OooMemInflightQueue", "push_mmu_epoch_i", "MMU_EPOCH_W"),
        ("OooStoreQueue", "fill0_mmu_epoch_i", "MMU_EPOCH_W"),
        ("OooStoreQueue", "context_squash_identity_i", "`OOO_CONTEXT_ID_W"),
        ("OooStoreQueue", "rob_head_idx_i", "ROB_INDEX_W"),
        ("OooStoreQueue", "alloc0_rob_idx_i", "ROB_INDEX_W"),
        ("OooStoreQueue", "alloc1_rob_idx_i", "ROB_INDEX_W"),
        ("OooMemOwnerTracker", "context_squash_identity_i", "`OOO_CONTEXT_ID_W"),
        ("OooMemOwnerTracker", "rob_head_idx_i", "ROB_INDEX_W"),
        ("OooMemOwnerTracker", "alloc0_rob_idx_i", "ROB_INDEX_W"),
        ("OooMemOwnerTracker", "alloc0_epoch_i", "EPOCH_W"),
        ("OooMemOwnerTracker", "irrevocable_kind_i", "KIND_W"),
        ("OooMemOwnerTracker", "irrevocable_token_i", "TOKEN_W"),
        ("OooMemOwnerTracker", "irrevocable_epoch_i", "EPOCH_W"),
    }
    actual_widths = {
        (item.get("module"), item.get("port"), item.get("width_token"))
        for item in manifest.get("required_port_widths", [])
    }
    if not expected_widths <= actual_widths:
        errors.append("required identity/cause/payload width inventory was weakened")
    wrapper_width_bundle = manifest.get("wrapper_width_bundle", {})
    if set(wrapper_width_bundle.get("modules", [])) != {
        "OooCoreTopGlue", "OooExecuteBackend", "OooAluCoreSlice",
        "OooAluDecodeBackend"
    } or wrapper_width_bundle.get("ports") != {
        "mem_context_squash_identity_i": "`OOO_CONTEXT_ID_W",
        "head0_identity_o": "`OOO_CONTEXT_ID_W",
    }:
        errors.append("wrapper identity width bundle differs from frozen exact map")
    fencei_wrapper_bundle = manifest.get("fencei_wrapper_bundle", {})
    if set(fencei_wrapper_bundle.get("modules", [])) != {
        "OooExecuteBackend", "OooAluCoreSlice", "OooAluDecodeBackend"
    } or fencei_wrapper_bundle.get("input") != "fencei_retire_permit_i":
        errors.append("FENCE.I retire-permit wrapper bundle differs from frozen map")
    expected_signal_widths = {
        ("NpcCoreTop", "ooo_head0_identity_w", "`OOO_CONTEXT_ID_W"),
        ("NpcCoreTop", "mmu_epoch_held_identity_w", "`OOO_CONTEXT_ID_W"),
        ("NpcCoreTop", "mmu_epoch_grant_payload_w", "`OOO_CONTEXT_PAYLOAD_W"),
        ("NpcCoreTop", "csr_context_payload_w", "`OOO_CONTEXT_PAYLOAD_W"),
        ("NpcCoreTop", "mmu_epoch_grant_cause_w", "`OOO_CONTEXT_CAUSE_W"),
        ("NpcCoreTop", "csr_context_cause_w", "`OOO_CONTEXT_CAUSE_W"),
        ("NpcCoreTop", "mmu_epoch_boundary_generation_w", "`OOO_CONTEXT_GENERATION_W"),
        ("OooIntBackend", "miq_head_mmu_epoch_w", "`OOO_MMU_EPOCH_W"),
        ("OooIntBackend", "miq_push_mmu_epoch_w", "`OOO_MMU_EPOCH_W"),
        ("OooIntBackend", "sq_fill_mmu_epoch_w", "`OOO_MMU_EPOCH_W"),
        ("OooStoreQueue", "context_squash_identity_q", "`OOO_CONTEXT_ID_W"),
        ("OooStoreQueue", "context_squash_identity_next_w", "`OOO_CONTEXT_ID_W"),
        ("OooMemOwnerTracker", "context_squash_identity_q", "`OOO_CONTEXT_ID_W"),
        ("OooMemOwnerTracker", "context_squash_identity_next_w", "`OOO_CONTEXT_ID_W"),
        ("OooMemOwnerTracker", "rob_idx_q", "ROB_INDEX_W"),
        ("OooMemInflightQueue", "mmu_epoch_q", "MMU_EPOCH_W"),
    }
    actual_signal_widths = {
        (item.get("module"), item.get("signal"), item.get("width_token"))
        for item in manifest.get("required_signal_widths", [])
    }
    if not expected_signal_widths <= actual_signal_widths:
        errors.append("required internal identity/cause/payload widths were weakened")
    context_next_signals = {
        "context_priv_mode_next_w", "context_mstatus_next_w",
        "context_satp_next_w", "context_menvcfg_next_w",
        "context_pmpcfg_next_w", "context_pmpaddr_next_w",
        "context_mepc_next_w", "context_sepc_next_w",
        "context_mcause_next_w", "context_scause_next_w",
        "context_mtval_next_w", "context_stval_next_w",
    }
    expected_next_groups = {
        ("CsrFile", frozenset(context_next_signals)):
            {"context_state_write_select_w", "context_apply_payload_i"},
        ("CsrFile", frozenset({"context_writer_owner_next_w"})):
            {"context_reserve_valid_i", "context_apply_valid_i",
             "context_abort_valid_i"},
        ("OooMmuEpochOwner", frozenset({"state_next_w"})):
            {"request_fire_w", "full_quiet_w", "grant_fire_w", "abort_i"},
        ("OooMmuEpochOwner", frozenset({"held_cause_next_w"})):
            {"request_fire_w", "request_cause_i", "grant_fire_w", "abort_i"},
        ("OooMmuEpochOwner", frozenset({"held_payload_next_w"})):
            {"request_fire_w", "request_payload_i", "grant_fire_w", "abort_i"},
        ("NpcCoreTop", frozenset({"mmu_epoch_registered_quiet_next_w"})):
            {"mmu_epoch_registered_quiet_q", "mmu_epoch_registered_quiet_set_w",
             "mmu_epoch_registered_quiet_clear_w"},
        ("OooIntBackend", frozenset({"mem_context_squash_identity_next_w"})):
            {"mem_context_squash_identity_q", "mem_context_squash_valid_i",
             "mem_context_squash_identity_i"},
        ("OooIntBackend", frozenset({"mem_context_sq_done_seen_next_w"})):
            {"mem_context_sq_done_seen_q", "mem_context_squash_valid_i",
             "sq_context_squash_done_w"},
        ("OooIntBackend", frozenset({"mem_context_owner_done_seen_next_w"})):
            {"mem_context_owner_done_seen_q", "mem_context_squash_valid_i",
             "owner_context_squash_done_w"},
        ("OooIntBackend", frozenset({"mem_context_squash_ack_next_w"})):
            {"mem_context_squash_ack_q", "mem_context_squash_all_done_w",
             "mem_context_squash_valid_i"},
        ("OooStoreQueue", frozenset({"context_squash_identity_next_w"})):
            {"context_squash_identity_q", "context_squash_valid_i",
             "context_squash_identity_i"},
        ("OooStoreQueue", frozenset({"context_squash_ack_next_w"})):
            {"context_squash_ack_q", "context_squash_valid_i",
             "context_squash_apply_done_w"},
        ("OooMemOwnerTracker", frozenset({"context_squash_identity_next_w"})):
            {"context_squash_identity_q", "context_squash_valid_i",
             "context_squash_identity_i"},
        ("OooMemOwnerTracker", frozenset({"context_squash_ack_next_w"})):
            {"context_squash_ack_q", "context_squash_valid_i",
             "context_squash_apply_done_w"},
        ("OooIntBackend", frozenset({"mem_issue_res_mmu_epoch_next_w"})):
            {"mem_issue_res_mmu_epoch_q", "mem_issue_res_capture_w",
             "current_mmu_epoch_i"},
        ("OooIntBackend", frozenset({"mem_mmu_epoch_next_w"})):
            {"mem_mmu_epoch_q", "issue0_mem_request_fire_w",
             "mem_issue_res_mmu_epoch_q"},
        ("OooIntBackend", frozenset({"mem_buffer_mmu_epoch_next_w"})):
            {"mem_buffer_mmu_epoch_q", "issue0_mem_buffer_fire_w",
             "mem_issue_res_mmu_epoch_q"},
    }
    actual_next_groups = {
        (group.get("module"), frozenset(group.get("next_signals", []))):
            set(group.get("sources", []))
        for group in manifest.get("next_signal_source_groups", [])
    }
    if not all(actual_next_groups.get(key) == sources
               for key, sources in expected_next_groups.items()):
        errors.append("required normalized next-state source groups were weakened")
    required_children = {
        ("OooMemAxiBridge", "OooSv39Tlb"),
        ("OooFetchAxiBridge", "OooSv39Tlb"),
        ("OooFetchAxiBridge", "OooFetchPacketCache"),
        ("OooCoreTopGlue", "OooControlPlane"),
        ("OooCoreTopGlue", "OooFrontend"),
        ("OooFrontend", "OooRedirectArbiter"),
        ("OooFrontend", "OooFetchPcOutstandingSequencer"),
    }
    actual_children = {
        (item.get("host"), item.get("child"))
        for item in manifest.get("instance_connections", [])
    }
    if not required_children <= actual_children:
        errors.append("true leaf invalidation/control consumer map is incomplete")
    required_instance_names = {
        ("NpcCoreTop", "OooMmuEpochOwner"): "u_mmu_epoch_owner",
        ("NpcCoreTop", "CsrFile"): "u_csr_file",
        ("NpcCoreTop", "OooFetchAxiBridge"): "u_ooo_fetch_bridge",
        ("NpcCoreTop", "OooCoreTopGlue"): "u_ooo_core",
        ("NpcCoreTop", "OooMemAxiBridge"): "u_ooo_mem_bridge",
        ("OooMemAxiBridge", "OooSv39Tlb"): "u_dtlb",
        ("OooFetchAxiBridge", "OooSv39Tlb"): "u_itlb",
        ("OooFetchAxiBridge", "OooFetchPacketCache"): "u_fetch_packet_cache",
        ("OooCoreTopGlue", "OooControlPlane"): "u_control_plane",
        ("OooCoreTopGlue", "OooFrontend"): "u_frontend",
        ("OooFrontend", "OooRedirectArbiter"): "u_redirect_arbiter",
        ("OooFrontend", "OooFetchPcOutstandingSequencer"):
            "u_fetch_pc_outstanding",
        ("OooDispatchBackend", "OooRob"): "u_rob",
        ("OooCoreTopGlue", "OooExecuteBackend"): "u_execute_backend",
        ("OooExecuteBackend", "OooAluCoreSlice"): "u_core_slice",
        ("OooAluCoreSlice", "OooAluDecodeBackend"): "u_decode_backend",
        ("OooAluDecodeBackend", "OooIntBackend"): "u_int_backend",
        ("OooIntBackend", "OooDispatchBackend"): "u_dispatch_backend",
        ("OooCoreTopGlue", "OooMemoryAccess"): "u_memory_access",
        ("OooMemoryAccess", "OooMemoryRequestGate"): "u_memory_request_gate",
        ("OooIntBackend", "OooMemOwnerTracker"): "u_mem_owner_tracker",
        ("OooIntBackend", "OooMemInflightQueue"): "u_mem_inflight_queue",
        ("OooIntBackend", "OooStoreQueue"): "u_store_queue",
    }
    actual_instance_names = {
        (item.get("host"), item.get("child")): item.get("instance")
        for item in manifest.get("instance_connections", [])
        if item.get("instance") is not None
    }
    if any(actual_instance_names.get(key) != name
           for key, name in required_instance_names.items()):
        errors.append("canonical live instance-name inventory was weakened")
    required_instance_parameters = {
        (
            "OooIntBackend", "OooMemInflightQueue", "u_mem_inflight_queue",
            "MMU_EPOCH_W", "`OOO_MMU_EPOCH_W",
        ),
        (
            "OooIntBackend", "OooStoreQueue", "u_store_queue",
            "MMU_EPOCH_W", "`OOO_MMU_EPOCH_W",
        ),
        (
            "OooIntBackend", "OooMemOwnerTracker", "u_mem_owner_tracker",
            "EPOCH_W", "`OOO_MMU_EPOCH_W",
        ),
    }
    actual_instance_parameters = {
        (
            item.get("host"), item.get("child"), item.get("instance"),
            name, value,
        )
        for item in manifest.get("instance_parameters", [])
        for name, value in item.get("parameters", {}).items()
    }
    if not required_instance_parameters <= actual_instance_parameters:
        errors.append("MIQ/SQ/owner epoch parameter provenance was weakened")
    expected_semantic_gates = {
        "abort_dominates_grant_apply_and_epoch_advance",
        "abort_edge_keeps_capture_block_and_forbids_commit_invalidate_lr_redirect",
        "abort_releases_only_held_csr_owner_and_preserves_deferred_writer",
        "ifu_ack_sticky_until_next_request_and_only_after_fetch_ptw_fpc_cancel_or_drain",
        "ifu_generation_reuse_only_after_all_old_references_empty",
        "fencei_waits_store_retire_mem_idle_current_generation_ifu_done_and_ifu_quiet",
        "fencei_commit_does_not_request_or_advance_data_mmu_epoch",
        "deferred_legacy_writer_eventually_arbitrates_exactly_once",
        "context_apply_and_legacy_write_are_mutually_exclusive",
        "registered_quiet_and_memory_squash_ack_are_sticky_and_generation_matched",
        "all_epoch_captures_use_active_valid_next_state_and_canonical_owner_leaves",
        "active_preprocessed_source_matches_every_frozen_critical_equation",
        "payload_fields_and_typed_cause_masks_match_concrete_macro_values",
        "every_context_register_has_one_canonical_procedural_writer",
        "sq_fill_epoch_mux_sources_are_canonical",
        "fencei_producer_outputs_are_exact_and_host_local_single_source",
        "csr_payload_identity_has_one_exact_nonoverlapping_slice_writer",
        "miq_request_fire_is_accepted_exactly_once_and_replays_captured_epoch_until_pop",
        "memory_squash_true_leaves_preserve_strict_age_irrevocable_and_single_store_release",
        "memory_squash_leaf_pulses_are_set_dominant_and_losslessly_aggregated",
        "canonical_instances_exist_in_release_and_ooo_assert_elaboration",
    }
    if set(manifest.get("semantic_gates", [])) != expected_semantic_gates:
        errors.append("semantic directed-gate inventory differs from frozen set")
    expected_mutations = {
        "inverted_held_identity_equality",
        "inverted_grant_source",
        "phase_nonzero_instead_of_phase_equals_squash",
        "stale_ifu_generation_ack",
        "nonsticky_ifu_done_pulse",
        "capture_block_gates_registered_axi_continuation",
        "fencei_retires_before_store_or_ifu_drain",
        "fencei_advances_data_epoch",
        "same_host_dummy_leaf_instance",
        "typed_leaf_wrong_cause_mask",
        "boundary_redirect_bypasses_arbiter",
        "raw_legacy_writer_bypasses_defer",
        "legacy_constant_register_write",
        "multiple_sequential_register_drivers",
        "blocking_register_write",
        "wide_absorbing_constant",
        "ternary_boolean_bypass",
        "truncated_internal_identity_or_generation",
        "off_by_one_or_symbolic_packed_range",
        "nonreset_constant_tail_override",
        "sequential_delay_disguised_as_combinational_dependency",
        "lane1_classifier_self_inequality_or_missing_boundary_class",
        "inactive_conditional_canonical_equation",
        "canonical_instance_source_or_sink_tied_constant",
        "unused_fetch_admission_or_fill_gate",
        "memory_squash_done_uses_or_or_nonsticky_ack",
        "registered_quiet_is_combinational_or_not_unique_next",
        "early_translation_invalidate_or_lr_clear",
        "wrong_held_identity_payload_slice",
        "overlapping_or_out_of_range_payload_fields",
        "duplicate_cause_bit_or_wrong_leaf_mask_value",
        "epoch_capture_valid_branch_constant_or_alias",
        "dummy_memory_owner_or_store_queue_instance",
        "always_ff_negedge_latch_initial_or_continuous_register_writer",
        "sq_fill_epoch_constant_alias_or_wrong_provenance",
        "fencei_producer_output_alias_or_wrong_instance_map",
        "payload_identity_wrong_slice_shifted_source_or_overlapping_writer",
        "miq_parent_fire_when_full_or_flush",
        "miq_push_epoch_constant_or_live_current_alias",
        "miq_head_reads_tail_or_live_current_epoch",
        "memory_squash_true_leaf_constant_or_request_echo_done",
        "memory_squash_clear_dominates_leaf_done_or_all_done",
        "memory_squash_owner_rob_or_irrevocable_provenance_missing",
        "memory_squash_store_double_release_or_fired_owner_killed",
        "dead_generate_critical_equation_or_instance",
        "scalar_or_multidimensional_partial_register_writer",
        "task_output_inout_ref_register_writer",
    }
    if set(manifest.get("required_mutations", [])) != expected_mutations:
        errors.append("required mutation inventory differs from frozen set")

    expected_exact_next = {
        ("OooIntBackend", "mem_context_squash_identity_next_w"):
            "mem_context_squash_valid_i ? mem_context_squash_identity_i : mem_context_squash_identity_q",
        ("OooIntBackend", "mem_req_fire_any_w"):
            "mem_req_valid_o && mem_req_ready_i",
        ("OooIntBackend", "miq_push_valid_w"):
            "mem_req_fire_any_w",
        ("OooIntBackend", "miq_push_mmu_epoch_w"):
            "mem_req_mmu_epoch_o",
        ("OooMemInflightQueue", "push_fire_w"):
            "push_valid_i && !full_o && !flush_i",
        ("OooMemInflightQueue", "head_mmu_epoch_o"):
            "mmu_epoch_q[head_q]",
        ("OooStoreQueue", "alloc0_fire_w"):
            "alloc0_valid_i && alloc0_ready_o && !flush_valid_i",
        ("OooStoreQueue", "context_squash_identity_next_w"):
            "context_squash_valid_i ? context_squash_identity_i : context_squash_identity_q",
        ("OooMemOwnerTracker", "alloc0_fire_w"):
            "alloc0_valid_i && alloc0_ready_o",
        ("OooMemOwnerTracker", "irrevocable_fire_w"):
            "irrevocable_valid_i && live_q[irrevocable_token_i] && (kind_q[irrevocable_token_i] == irrevocable_kind_i) && (epoch_q[irrevocable_token_i] == irrevocable_epoch_i)",
        ("OooMemOwnerTracker", "context_squash_identity_next_w"):
            "context_squash_valid_i ? context_squash_identity_i : context_squash_identity_q",
        ("OooFetchAxiBridge", "fetch_context_squash_generation_next_w"):
            "context_squash_valid_i ? context_squash_generation_i : fetch_context_squash_generation_q",
        ("OooFetchAxiBridge", "fencei_squash_generation_next_w"):
            "fencei_squash_valid_i ? fencei_squash_generation_i : fencei_squash_generation_q",
        ("OooIntBackend", "sq_fill_mmu_epoch_w"):
            "sq_mode_w ? miq_head_mmu_epoch_w : mem_issue_res_mmu_epoch_q",
    }
    actual_exact_next = {
        (item.get("module"), item.get("target")): item.get("exact_expression")
        for item in manifest.get("exact_next_expressions", [])
    }
    if actual_exact_next != expected_exact_next:
        errors.append("exact non-Boolean next-state expressions differ from frozen map")

    expected_epoch_captures = {
        ("OooIntBackend", "mem_issue_res_mmu_epoch_q"):
            ("mem_issue_res_mmu_epoch_next_w", "mem_issue_res_capture_w",
             "current_mmu_epoch_i",
             "mem_issue_res_capture_w ? current_mmu_epoch_i : mem_issue_res_mmu_epoch_q"),
        ("OooIntBackend", "mem_mmu_epoch_q"):
            ("mem_mmu_epoch_next_w", "issue0_mem_request_fire_w",
             "mem_issue_res_mmu_epoch_q",
             "issue0_mem_request_fire_w ? mem_issue_res_mmu_epoch_q : mem_mmu_epoch_q"),
        ("OooIntBackend", "mem_buffer_mmu_epoch_q"):
            ("mem_buffer_mmu_epoch_next_w", "issue0_mem_buffer_fire_w",
             "mem_issue_res_mmu_epoch_q",
             "issue0_mem_buffer_fire_w ? mem_issue_res_mmu_epoch_q : mem_buffer_mmu_epoch_q"),
    }
    actual_epoch_captures = {
        (item.get("module"), item.get("register")):
            (item.get("next_signal"), item.get("capture_fire"), item.get("signal"),
             item.get("exact_expression"))
        for item in manifest.get("epoch_register_captures", [])
    }
    if actual_epoch_captures != expected_epoch_captures:
        errors.append("valid epoch-capture next-state inventory differs from frozen map")
    return errors


def posedge_clk_blocks(text: str) -> list[str]:
    blocks: list[str] = []
    pattern = re.compile(
        # Sequential contract freezes one synchronous event only.  Extra edge
        # events (including async reset or a fake clock) cannot share this block.
        r"\balways\s*@\s*\(\s*posedge\s+clk\s*\)\s*begin\b",
        flags=re.S,
    )
    for match in pattern.finditer(text):
        begin_pos = text.find("begin", match.start(), match.end())
        depth = 0
        end_pos: int | None = None
        for token in re.finditer(r"\b(?:begin|end)\b", text[begin_pos:]):
            if token.group(0) == "begin":
                depth += 1
            else:
                depth -= 1
                if depth == 0:
                    end_pos = begin_pos + token.end()
                    break
        if end_pos is not None:
            blocks.append(text[match.start():end_pos])
    return blocks


def statement_span(text: str, start: int) -> tuple[int, int] | None:
    pos = start
    while pos < len(text) and text[pos].isspace():
        pos += 1
    conditional = re.match(r"if\s*\(", text[pos:])
    if conditional:
        open_pos = text.find("(", pos, pos + conditional.end())
        condition_region = balanced_region(text, open_pos)
        if condition_region is None:
            return None
        true_span = statement_span(text, condition_region[1])
        if true_span is None:
            return None
        after = true_span[1]
        while after < len(text) and text[after].isspace():
            after += 1
        else_match = re.match(r"else\b", text[after:])
        if not else_match:
            return pos, true_span[1]
        false_span = statement_span(text, after + else_match.end())
        return (pos, false_span[1]) if false_span is not None else None
    case_match = re.match(r"(?:case|casex|casez)\s*\(", text[pos:])
    if case_match:
        depth = 0
        for token in re.finditer(
            r"\b(?:case|casex|casez|endcase)\b", text[pos:]
        ):
            if token.group(0) == "endcase":
                depth -= 1
                if depth == 0:
                    return pos, pos + token.end()
            else:
                depth += 1
        return None
    loop = re.match(r"(?:for|foreach|while|repeat)\s*\(", text[pos:])
    if loop:
        open_pos = text.find("(", pos, pos + loop.end())
        control_region = balanced_region(text, open_pos)
        if control_region is None:
            return None
        body_span = statement_span(text, control_region[1])
        return (pos, body_span[1]) if body_span is not None else None
    begin = re.match(r"begin\b", text[pos:])
    if begin:
        depth = 0
        for token in re.finditer(r"\b(?:begin|end)\b", text[pos:]):
            if token.group(0) == "begin":
                depth += 1
            else:
                depth -= 1
                if depth == 0:
                    return pos, pos + token.end()
        return None
    semicolon = text.find(";", pos)
    if semicolon < 0:
        return None
    return pos, semicolon + 1


@lru_cache(maxsize=256)
def procedural_statement_spans(text: str) -> tuple[tuple[int, int], ...]:
    """Return procedural regions so module-level generate controls stay distinct."""
    spans: list[tuple[int, int]] = []
    for match in re.finditer(r"\balways(?:_ff|_comb|_latch)?\b", text):
        pos = match.end()
        while pos < len(text) and text[pos].isspace():
            pos += 1
        if pos < len(text) and text[pos] == "@":
            pos += 1
            while pos < len(text) and text[pos].isspace():
                pos += 1
            if pos < len(text) and text[pos] == "(":
                region = balanced_region(text, pos)
                if region is None:
                    continue
                pos = region[1]
            elif pos < len(text) and text[pos] == "*":
                pos += 1
            else:
                event = re.match(
                    r"(?:(?:posedge|negedge)\s+)?"
                    r"(?:\\[^\s]+|[A-Za-z_][A-Za-z0-9_$]*)"
                    r"(?:\s*\[[^\]]+\])*",
                    text[pos:],
                )
                if event is None:
                    continue
                pos += event.end()
        span = statement_span(text, pos)
        if span is not None:
            spans.append((match.start(), span[1]))
    for match in re.finditer(r"\b(?:initial|final)\b", text):
        span = statement_span(text, match.end())
        if span is not None:
            spans.append((match.start(), span[1]))
    for match in re.finditer(r"\b(task|function)\b", text):
        terminator = "endtask" if match.group(1) == "task" else "endfunction"
        end = re.search(rf"\b{terminator}\b", text[match.end():])
        if end is not None:
            spans.append((match.start(), match.end() + end.end()))
    return tuple(spans)


@lru_cache(maxsize=256)
def conditional_generate_spans(text: str) -> tuple[tuple[int, int], ...]:
    """Collect every non-lexical module generate scope.

    Besides conditional/replicated generate, explicit ``generate`` regions and
    unconditional named ``begin : name`` blocks are local scopes.  Critical
    equations, writers, and named instances may not be sourced from any of them.
    """
    procedural_spans = procedural_statement_spans(text)
    spans: list[tuple[int, int]] = []

    def is_procedural(control_pos: int) -> bool:
        return any(start <= control_pos < end for start, end in procedural_spans)

    generate_stack: list[int] = []
    for token in re.finditer(r"\b(?:generate|endgenerate)\b", text):
        if token.group(0) == "generate":
            generate_stack.append(token.start())
        elif generate_stack:
            spans.append((generate_stack.pop(), token.end()))

    for match in re.finditer(
        r"\bbegin\s*:\s*(?:\\[^\s]+|[A-Za-z_][A-Za-z0-9_$]*)", text
    ):
        if is_procedural(match.start()):
            continue
        named_span = statement_span(text, match.start())
        if named_span is not None:
            spans.append(named_span)

    for match in re.finditer(r"\bif\s*\(", text):
        if is_procedural(match.start()):
            continue
        open_pos = text.find("(", match.start(), match.end())
        condition_region = balanced_region(text, open_pos)
        if condition_region is None:
            continue
        true_span = statement_span(text, condition_region[1])
        if true_span is None:
            continue
        spans.append(true_span)
        pos = true_span[1]
        while pos < len(text) and text[pos].isspace():
            pos += 1
        else_match = re.match(r"else\b", text[pos:])
        if else_match:
            false_span = statement_span(text, pos + else_match.end())
            if false_span is not None:
                spans.append(false_span)

    case_tokens = re.compile(r"\b(?:case|casex|casez|endcase)\b")
    for match in re.finditer(r"\b(?:case|casex|casez)\s*\(", text):
        if is_procedural(match.start()):
            continue
        depth = 0
        end_pos: int | None = None
        for token in case_tokens.finditer(text, match.start()):
            if token.group(0) == "endcase":
                depth -= 1
                if depth == 0:
                    end_pos = token.end()
                    break
            else:
                depth += 1
        if end_pos is not None:
            spans.append((match.start(), end_pos))

    for match in re.finditer(r"\b(?:for|foreach)\s*\(", text):
        if is_procedural(match.start()):
            continue
        open_pos = text.find("(", match.start(), match.end())
        control_region = balanced_region(text, open_pos)
        if control_region is None:
            continue
        body_span = statement_span(text, control_region[1])
        if body_span is not None:
            spans.append(body_span)
    return tuple(spans)


def position_is_under_conditional_generate(text: str, position: int) -> bool:
    """Compatibility alias for the stronger any-generate lexical-scope rule."""
    return any(
        start <= position < end for start, end in conditional_generate_spans(text)
    )


def position_is_under_module_generate(text: str, position: int) -> bool:
    return position_is_under_conditional_generate(text, position)


def position_is_inside_procedural_span(text: str, position: int) -> bool:
    return any(
        start <= position < end for start, end in procedural_statement_spans(text)
    )


def procedural_timing_control_errors(block: str) -> list[str]:
    """Reject nested event/delay/wait controls inside a canonical clock block."""
    always_begin = re.search(r"\bbegin\b", block)
    if always_begin is None:
        return ["canonical clock block has no begin"]
    body = block[always_begin.end():]
    errors: list[str] = []
    if re.search(r"@\s*(?:\(|\*|\\|[A-Za-z_])", body):
        errors.append("nested event control appears inside the clock block")
    if re.search(r"#\s*(?:\(|[0-9A-Za-z_`])", body):
        errors.append("procedural delay control appears inside the clock block")
    if re.search(r"\bwait\s*\(", body):
        errors.append("wait control appears inside the clock block")
    return errors


def if_ancestor_path(
    text: str, position: int, start: int, end: int
) -> list[dict[str, str]]:
    """Return every lexical if ancestor and selected arm, outermost first."""
    ancestors: list[dict[str, str]] = []
    for match in re.finditer(r"\bif\s*\(", text, flags=re.S):
        if not (start <= match.start() < end):
            continue
        open_pos = text.find("(", match.start(), match.end())
        condition_region = balanced_region(text, open_pos)
        if condition_region is None:
            continue
        condition, after_condition = condition_region
        true_span = statement_span(text, after_condition)
        if true_span is None:
            continue
        arm: str | None = None
        if true_span[0] <= position < true_span[1]:
            arm = "true"
        else:
            cursor = true_span[1]
            while cursor < len(text) and text[cursor].isspace():
                cursor += 1
            else_match = re.match(r"else\b", text[cursor:])
            if else_match:
                false_span = statement_span(text, cursor + else_match.end())
                if false_span is not None and false_span[0] <= position < false_span[1]:
                    arm = "false"
        if arm is not None:
            ancestors.append({
                "condition": compact_expression(condition),
                "arm": arm,
            })
    return ancestors


def split_top_level_fragments(text: str, delimiter: str = ",") -> list[tuple[str, int]]:
    fragments: list[tuple[str, int]] = []
    start = 0
    round_depth = square_depth = brace_depth = 0
    for pos, char in enumerate(text):
        if char == "(":
            round_depth += 1
        elif char == ")":
            round_depth = max(0, round_depth - 1)
        elif char == "[":
            square_depth += 1
        elif char == "]":
            square_depth = max(0, square_depth - 1)
        elif char == "{":
            brace_depth += 1
        elif char == "}":
            brace_depth = max(0, brace_depth - 1)
        elif (char == delimiter and round_depth == 0 and square_depth == 0
              and brace_depth == 0):
            fragments.append((text[start:pos], start))
            start = pos + 1
    fragments.append((text[start:], start))
    return fragments


def declaration_name(fragment: str) -> tuple[str, int] | None:
    """Extract only the declarator name, never a range/RHS reference."""
    lhs = fragment
    round_depth = square_depth = brace_depth = 0
    for pos, char in enumerate(fragment):
        if char == "(":
            round_depth += 1
        elif char == ")":
            round_depth = max(0, round_depth - 1)
        elif char == "[":
            square_depth += 1
        elif char == "]":
            square_depth = max(0, square_depth - 1)
        elif char == "{":
            brace_depth += 1
        elif char == "}":
            brace_depth = max(0, brace_depth - 1)
        elif (char == "=" and round_depth == 0 and square_depth == 0
              and brace_depth == 0):
            lhs = fragment[:pos]
            break
    keywords = {
        "input", "output", "inout", "wire", "logic", "reg", "bit",
        "integer", "time", "parameter", "localparam", "genvar", "signed",
        "unsigned", "var", "automatic", "static",
    }
    candidates: list[tuple[str, int]] = []
    square_depth = 0
    for match in re.finditer(r"\[|\]|[A-Za-z_][A-Za-z0-9_$]*", lhs):
        token = match.group(0)
        if token == "[":
            square_depth += 1
        elif token == "]":
            square_depth = max(0, square_depth - 1)
        elif square_depth == 0 and token not in keywords:
            candidates.append((token, match.start()))
    return candidates[-1] if candidates else None


def symbol_declaration_sites(text: str, signal: str) -> list[int]:
    """Return true ANSI/body declarator sites for one exact symbol name."""
    sites: list[int] = []
    module_match = re.search(r"\bmodule\s+[A-Za-z_][A-Za-z0-9_$]*", text)
    body_start = 0
    if module_match is not None:
        pos = module_match.end()
        while pos < len(text) and text[pos].isspace():
            pos += 1
        if pos < len(text) and text[pos] == "#":
            pos += 1
            while pos < len(text) and text[pos].isspace():
                pos += 1
            parameter_region = balanced_region(text, pos)
            if parameter_region is not None:
                pos = parameter_region[1]
        while pos < len(text) and text[pos].isspace():
            pos += 1
        if pos < len(text) and text[pos] == "(":
            port_region = balanced_region(text, pos)
            if port_region is not None:
                ports, after_ports = port_region
                ansi_active = False
                for fragment, offset in split_top_level_fragments(ports):
                    if re.search(r"\b(?:input|output|inout)\b", fragment):
                        ansi_active = True
                    if not ansi_active:
                        continue
                    declared = declaration_name(fragment)
                    if declared is not None and declared[0] == signal:
                        sites.append(pos + 1 + offset + declared[1])
                semicolon = text.find(";", after_ports)
                body_start = semicolon + 1 if semicolon >= 0 else after_ports

    declaration = re.compile(
        r"\b(?:input|output|inout|wire|logic|reg|bit|integer|time|"
        r"parameter|localparam|genvar)\b[^;]*;",
        flags=re.S,
    )
    for match in declaration.finditer(text, body_start):
        for fragment, offset in split_top_level_fragments(match.group(0)[:-1]):
            declared = declaration_name(fragment)
            if declared is not None and declared[0] == signal:
                sites.append(match.start() + offset + declared[1])
    return sites


def module_symbol_declaration_errors(text: str, signal: str) -> list[str]:
    sites = symbol_declaration_sites(text, signal)
    errors: list[str] = []
    if len(sites) != 1:
        errors.append(f"expected one declaration site, found {len(sites)}")
    if any(
        position_is_under_module_generate(text, site)
        or position_is_inside_procedural_span(text, site)
        for site in sites
    ):
        errors.append("declaration is not in host module lexical scope")
    if signal_has_procedural_local_declaration(text, signal):
        errors.append("procedural local declaration shadows the module symbol")
    return errors


def outer_reset_regions(
    block: str, reset_predicate: str = "rst"
) -> tuple[tuple[int, int], tuple[int, int]] | None:
    always_begin = re.search(r"\bbegin\b", block)
    if not always_begin:
        return None
    # reset 必须是 clock block 的首个、最外层 statement；不能先写状态再在
    # 后续某个含 reset 字样的 if 中伪造 reset/non-reset region。
    pos = always_begin.end()
    while pos < len(block) and block[pos].isspace():
        pos += 1
    first_if = re.match(r"if\s*\(", block[pos:])
    if not first_if:
        return None
    if_start = pos + first_if.start()
    open_pos = block.find("(", if_start)
    condition_region = balanced_region(block, open_pos)
    if condition_region is None:
        return None
    condition, after_condition = condition_region
    # 只接受 exact positive canonical ``rst``。!rst、~rst、rst==0 及复合
    # predicate 会交换或扩大 reset arm，必须全部拒绝。
    if compact_expression(condition) != compact_expression(reset_predicate):
        return None
    true_span = statement_span(block, after_condition)
    if true_span is None:
        return None
    pos = true_span[1]
    while pos < len(block) and block[pos].isspace():
        pos += 1
    else_match = re.match(r"else\b", block[pos:])
    if not else_match:
        return None
    false_span = statement_span(block, pos + else_match.end())
    if false_span is None:
        return None
    return true_span, false_span


def register_is_user_task_actual(text: str, register: str) -> bool:
    """Fail closed for any potentially-writing subroutine call with audited state.

    Imported, package-qualified, and hierarchical task calls may write an
    actual without placing it on an assignment LHS.  Calls anywhere inside a
    procedural region are considered, including calls embedded in expressions;
    module-instance port maps remain outside those regions.  System calls are
    fail-closed except for an explicit read-only diagnostic allowlist.
    """
    actual_token = re.compile(
        rf"\b{re.escape(register)}(?:\s*\[[^\]]+\])*\b"
    )
    procedural_spans = procedural_statement_spans(text)
    # IEEE escaped identifiers are terminated only by whitespace; punctuation
    # (including a literal '(') is therefore part of the identifier token.
    identifier = r"(?:\\[^\s]+|[A-Za-z_][A-Za-z0-9_$]*)"
    qualified = rf"{identifier}(?:\s*(?:::|\.)\s*{identifier})*"
    call_pattern = re.compile(
        rf"(?<![A-Za-z0-9_$\\])(?P<name>\$[A-Za-z_][A-Za-z0-9_$]*|{qualified})\s*\("
    )
    control_names = {"if", "for", "foreach", "while", "repeat", "case"}
    readonly_system_calls = {
        "$display", "$displayb", "$displayh", "$displayo",
        "$write", "$writeb", "$writeh", "$writeo",
        "$monitor", "$monitorb", "$monitorh", "$monitoro",
        "$strobe", "$strobeb", "$strobeh", "$strobeo",
        "$error", "$warning", "$fatal", "$info",
    }
    for call in call_pattern.finditer(text):
        call_name = re.sub(r"\s+", "", call.group("name"))
        terminal_name = re.split(r"::|\.", call_name)[-1]
        terminal_name = terminal_name.lstrip("\\")
        if terminal_name in control_names:
            continue
        if not any(start <= call.start() < end for start, end in procedural_spans):
            continue
        open_pos = call.end() - 1
        region = balanced_region(text, open_pos)
        if region is None:
            continue
        if actual_token.search(region[0]):
            if call_name.startswith("$") and call_name in readonly_system_calls:
                continue
            return True
    return False


def exact_signal_reference_selectors(
    expression: str, signal: str
) -> list[str] | None:
    """Parse one exact signal reference with balanced nested selectors."""
    pos = 0
    while pos < len(expression) and expression[pos].isspace():
        pos += 1
    name = re.match(rf"{re.escape(signal)}\b", expression[pos:])
    if name is None:
        return None
    pos += name.end()
    selectors: list[str] = []
    while True:
        while pos < len(expression) and expression[pos].isspace():
            pos += 1
        if pos >= len(expression) or expression[pos] != "[":
            break
        region = balanced_delimited_region(expression, pos, "[", "]")
        if region is None:
            return None
        selector, pos = region
        selectors.append(selector)
    while pos < len(expression) and expression[pos].isspace():
        pos += 1
    return selectors if pos == len(expression) else None


def identifier_is_compile_time_constant(text: str, identifier: str) -> bool:
    for match in re.finditer(r"\b(?:parameter|localparam)\b[^;]*;", text, flags=re.S):
        if (position_is_inside_procedural_span(text, match.start())
                or position_is_under_module_generate(text, match.start())):
            continue
        for fragment, _offset in split_top_level_fragments(match.group(0)[:-1]):
            declared = declaration_name(fragment)
            if declared is not None and declared[0] == identifier:
                return True
    for enum in re.finditer(r"\benum\b[^\{;]*\{([^}]*)\}", text, flags=re.S):
        if (position_is_inside_procedural_span(text, enum.start())
                or position_is_under_module_generate(text, enum.start())):
            continue
        for fragment, _offset in split_top_level_fragments(enum.group(1)):
            declared = declaration_name(fragment)
            if declared is not None and declared[0] == identifier:
                return True
    return False


def context_register_uses_unique_next(
    text: str, register: str, next_signal: str, *, allow_indexed: bool = False,
    reset_predicate: str = "rst",
) -> tuple[bool, str]:
    writes = direct_signal_writes(text, register)
    compound_or_increment = re.compile(
        rf"\b{re.escape(register)}(?:\s*\[[^;]+\])*"
        + r"\s*(?:\+\+|--|(?:<<|>>|[+\-*/%&|^])=)",
        flags=re.S,
    )
    block_spans: list[tuple[int, int, str]] = []
    search_from = 0
    for candidate in posedge_clk_blocks(text):
        start = text.find(candidate, search_from)
        if start >= 0:
            block_spans.append((start, start + len(candidate), candidate))
            search_from = start + len(candidate)
    driver_blocks = [
        item for item in block_spans
        if any(item[0] <= write["start"] < item[1] for write in writes)
    ]
    if len(driver_blocks) != 1:
        return False, f"expected one exact @(posedge clk) driver, found {len(driver_blocks)}"
    block_start, block_end, block = driver_blocks[0]
    if block_start < 0 or position_is_under_conditional_generate(text, block_start):
        return False, "canonical writer is under a module generate scope"
    timing_errors = procedural_timing_control_errors(block)
    if timing_errors:
        return False, "; ".join(timing_errors)
    assignments = [
        write for write in writes if block_start <= write["start"] < block_end
    ]
    if (any(write["op"] != "<=" for write in writes)
            or compound_or_increment.search(text)
            or signal_has_concatenated_lhs_write(text, register)):
        return False, "blocking/continuous/compound write bypasses unique-next policy"
    if len(writes) != len(assignments):
        return False, (
            "nonblocking writer exists outside the one canonical posedge block: "
            f"all={len(writes)} canonical={len(assignments)}"
        )
    if not assignments:
        return False, "register has no nonblocking procedural assignments"
    if register_is_user_task_actual(text, register):
        return False, "audited register is passed to a user task actual"
    for frozen_name in (register, next_signal, reset_predicate, "clk"):
        if signal_has_procedural_local_declaration(text, frozen_name):
            return False, (
                f"procedural local shadows frozen writer symbol {frozen_name}"
            )
    reset_regions = outer_reset_regions(block, reset_predicate)
    if reset_regions is None:
        return False, "writer is not a canonical outer reset/else block"
    reset_span, nonreset_span = reset_regions

    def reset_literal(rhs: str) -> bool:
        compact = re.sub(r"\s+", "", rhs)
        if re.fullmatch(r"(?:\d+)?'[sS]?[bBdDhHoO][0-9a-fA-F_xXzZ]+", compact):
            return True
        if re.fullmatch(r"\d+", compact):
            return True
        if compact.startswith("`") and re.fullmatch(r"`[A-Za-z_][A-Za-z0-9_]*", compact):
            return True
        if re.fullmatch(r"[A-Z][A-Z0-9_$]*", compact):
            return identifier_is_compile_time_constant(text, compact)
        if compact.startswith("{") and compact.endswith("}"):
            residue = re.sub(r"(?:\d+)?'[sS]?[bBdDhHoO][0-9a-fA-F_xXzZ]+", "", compact)
            residue = re.sub(r"`[A-Za-z_][A-Za-z0-9_]*", "", residue)
            residue = re.sub(r"[0-9_{}():+\-*/]+", "", residue)
            return not re.search(r"[A-Za-z_$]", residue)
        return False

    next_assignments = 0
    reset_assignments = 0
    unsafe: list[str] = []
    for assignment in assignments:
        rhs = assignment["rhs"].strip()
        lhs_selects = assignment["selects"]
        rhs_selects = exact_signal_reference_selectors(rhs, next_signal)
        compact = re.sub(r"\s+", "", rhs)
        relative = assignment["start"] - block_start
        in_reset = reset_span[0] <= relative < reset_span[1]
        in_nonreset = nonreset_span[0] <= relative < nonreset_span[1]
        indexed_pair_ok = (
            allow_indexed
            and len(lhs_selects) == 1
            and rhs_selects is not None
            and len(rhs_selects) == 1
            and compact_expression(lhs_selects[0])
            == compact_expression(rhs_selects[0])
        )
        scalar_pair_ok = (
            not allow_indexed and not lhs_selects and rhs_selects == []
        )
        if rhs_selects is not None and (indexed_pair_ok or scalar_pair_ok) and in_nonreset:
            if if_ancestor_path(text, assignment["start"], block_start, block_end) != [{
                "condition": compact_expression(reset_predicate),
                "arm": "false",
            }]:
                unsafe.append(rhs)
                continue
            next_assignments += 1
            continue
        reset_lhs_ok = (
            (allow_indexed and len(lhs_selects) == 1)
            or (not allow_indexed and not lhs_selects)
        )
        if (reset_literal(rhs) and reset_lhs_ok and in_reset
                and if_ancestor_path(
                    text, assignment["start"], block_start, block_end
                ) == [{
                    "condition": compact_expression(reset_predicate),
                    "arm": "true",
                }]):
            reset_assignments += 1
            continue
        unsafe.append(rhs)
    if next_assignments != 1:
        return False, f"expected one assignment from {next_signal}, found {next_assignments}"
    if reset_assignments != 1:
        return False, f"expected one reset-only literal assignment, found {reset_assignments}"
    if unsafe:
        return False, f"non-reset writes bypass {next_signal}: {len(unsafe)}"
    return True, f"posedge_drivers=1 assignments={len(assignments)}"


def run_self_test() -> int:
    good = code_only("""
      module Host(input block, input sig_a, output sink);
        wire alias = block;
        assign sink = alias;
        Child u_child (.a(sig_a), .b(sink));
      endmodule
    """)
    host = module_body(good, "Host") or ""
    checks: list[tuple[str, bool]] = []
    ok, _ = exact_instance_connection(host, "Child", {"a": "sig_a", "b": "sink"})
    checks.append(("exact-live-instance", ok))

    declaration_only = code_only("""
      module Host(input sig_a, output sink);
        // Child u_child (.a(sig_a), .b(sink));
        wire Child;
      endmodule
    """)
    ok, _ = exact_instance_connection(
        module_body(declaration_only, "Host") or "", "Child",
        {"a": "sig_a", "b": "sink"},
    )
    checks.append(("comment-declaration-only-killed", not ok))

    wrong_connection = good.replace(".b(sink)", ".b(sig_a)")
    ok, _ = exact_instance_connection(
        module_body(wrong_connection, "Host") or "", "Child",
        {"a": "sig_a", "b": "sink"},
    )
    checks.append(("wrong-named-connection-killed", not ok))

    wrong_host = code_only("""
      module Host(input sig_a, output sink); assign sink = sig_a; endmodule
      module Other(input sig_a, output sink);
        Child u_dummy (.a(sig_a), .b(sink));
      endmodule
    """)
    ok, _ = exact_instance_connection(
        module_body(wrong_host, "Host") or "", "Child",
        {"a": "sig_a", "b": "sink"},
    )
    checks.append(("dummy-wrong-host-killed", not ok))

    same_host_dummy = code_only("""
      module Host(input sig_a, output sink);
        Child u_real (.a(sig_a), .b(sig_a));
        Child u_dummy (.a(sig_a), .b(sink));
      endmodule
    """)
    canonical_ok, _ = exact_instance_connection(
        module_body(same_host_dummy, "Host") or "", "Child",
        {"a": "sig_a", "b": "sink"}, "u_real",
    )
    checks.append(("same-host-dummy-instance-killed", not canonical_ok))

    graph = assignment_graph(host)
    checks.append(("transitive-forbidden-alias-killed", depends_on(graph, "sink", "block")))

    constant_quiet = assignment_graph(code_only("assign quiet = 1'b1;"))
    checks.append(("pure-constant-quiet-killed", not depends_on(constant_quiet, "quiet", "pending_q")))

    constant_lane1 = assignment_graph(code_only("assign head1_boundary = 1'b0;"))
    checks.append(("pure-constant-lane1-classifier-killed",
                   not depends_on(constant_lane1, "head1_boundary", "inst_q")))

    quiet_requirement = {
        "target": "quiet",
        "sources": ["pending_q", "fill_q"],
        "required_operators": ["&&"],
        "forbidden_operators": ["||"],
        "forbid_absorbing_constants": True,
    }
    quiet_good = code_only("assign quiet = !pending_q && !fill_q;")
    quiet_bad = code_only("assign quiet = 1'b1 | pending_q | fill_q;")
    checks.append((
        "absorbing-constant-quiet-killed",
        not boolean_requirement_errors(quiet_good, quiet_requirement)
        and bool(boolean_requirement_errors(quiet_bad, quiet_requirement)),
    ))
    wide_constant_bad = code_only(
        "assign quiet = 8'hff || (pending_q && fill_q);"
    )
    checks.append((
        "wide-absorbing-constant-killed",
        bool(boolean_requirement_errors(wide_constant_bad, quiet_requirement)),
    ))
    ternary_requirement = dict(quiet_requirement)
    ternary_requirement["forbid_ternary_xor"] = True
    ternary_bad = code_only(
        "assign quiet = pending_q ? fill_q : pending_q && fill_q;"
    )
    checks.append((
        "ternary-boolean-bypass-killed",
        bool(boolean_requirement_errors(ternary_bad, ternary_requirement)),
    ))

    lane_requirement = {
        "target": "head1_boundary",
        "sources": ["inst_q"],
        "forbidden_operators": [],
        "forbid_absorbing_constants": True,
    }
    lane_bad = code_only("assign head1_boundary = (|inst_q) & 1'b0;")
    checks.append((
        "absorbing-constant-lane1-killed",
        bool(boolean_requirement_errors(lane_bad, lane_requirement)),
    ))
    lane_exact_requirement = {
        "target": "head1_context_boundary_w",
        "sources": ["valid_q", "head1_w", "head1_done_w",
                    "head1_exception_w", "head1_potential_context_boundary_w"],
        "exact_expression": (
            "valid_q[head1_w] && head1_done_w && !head1_exception_w && "
            "head1_potential_context_boundary_w"
        ),
    }
    lane_exact_good = code_only(
        "assign head1_context_boundary_w = valid_q[head1_w] && head1_done_w && "
        "!head1_exception_w && head1_potential_context_boundary_w;"
    )
    lane_self_inequality = code_only(
        "assign head1_context_boundary_w = valid_q[head1_w] && head1_done_w && "
        "(inst_q[head1_w] != inst_q[head1_w]);"
    )
    checks.append((
        "lane1-self-inequality-classifier-killed",
        not boolean_requirement_errors(lane_exact_good, lane_exact_requirement)
        and bool(boolean_requirement_errors(
            lane_self_inequality, lane_exact_requirement
        )),
    ))

    squash_missing_ack = code_only("""
      module Host(input valid, input identity, output done);
        Squash u_sq (.valid_i(valid), .identity_i(identity));
      endmodule
    """)
    ok, _ = exact_instance_connection(
        module_body(squash_missing_ack, "Host") or "", "Squash",
        {"valid_i": "valid", "identity_i": "identity", "done_o": "done"},
    )
    checks.append(("missing-squash-ack-killed", not ok))

    grant_loop = assignment_graph(code_only("""
      assign grant_ready = permit && base_ready;
      assign permit = grant_valid && grant_ready;
    """))
    checks.append(("grant-ready-loop-killed", depends_on(grant_loop, "grant_ready", "permit")))

    atomic_consumer = code_only("""
      module Host(input grant_fire, input payload);
        Consumer u_consumer (.apply_i(grant_fire), .payload_i(payload));
      endmodule
    """)
    ok, _ = exact_instance_connection(
        module_body(atomic_consumer, "Host") or "", "Consumer",
        {"apply_i": "grant_fire", "payload_i": "payload"},
    )
    mutated_consumer = atomic_consumer.replace(".apply_i(grant_fire)", ".apply_i(payload)")
    mutated_ok, _ = exact_instance_connection(
        module_body(mutated_consumer, "Host") or "", "Consumer",
        {"apply_i": "grant_fire", "payload_i": "payload"},
    )
    checks.append(("missing-atomic-consumer-killed", ok and not mutated_ok))

    unique_writer = code_only("""
      always @(posedge clk) begin
        if (rst) state_q <= 2'b00;
        else state_q <= context_state_next_w;
      end
    """)
    unique_ok, _ = context_register_uses_unique_next(
        unique_writer, "state_q", "context_state_next_w"
    )
    bypass_writer = unique_writer.replace(
        "else state_q <= context_state_next_w;",
        "else if (legacy) state_q <= raw_value; else state_q <= context_state_next_w;",
    )
    bypass_ok, _ = context_register_uses_unique_next(
        bypass_writer, "state_q", "context_state_next_w"
    )
    checks.append(("legacy-context-write-bypass-killed", unique_ok and not bypass_ok))

    reset_predicate_mutations = [
        ("unique-reset-logical-not-killed", "if (!rst)"),
        ("unique-reset-bitwise-not-killed", "if (~rst)"),
        ("unique-reset-zero-compare-killed", "if (rst == 1'b0)"),
        ("unique-reset-composite-killed", "if (rst || test_mode_i)"),
    ]
    for name, predicate in reset_predicate_mutations:
        mutated = unique_writer.replace("if (rst)", predicate)
        mutated_ok, _ = context_register_uses_unique_next(
            mutated, "state_q", "context_state_next_w"
        )
        checks.append((name, unique_ok and not mutated_ok))

    extra_sensitivity = unique_writer.replace(
        "@(posedge clk)", "@(posedge fake_clk or posedge clk)"
    )
    extra_sensitivity_ok, _ = context_register_uses_unique_next(
        extra_sensitivity, "state_q", "context_state_next_w"
    )
    checks.append((
        "extra-sensitivity-event-unique-next-killed",
        unique_ok and not extra_sensitivity_ok,
    ))
    local_reset_shadow = unique_writer.replace(
        "if (rst)", "logic rst; if (rst)"
    )
    local_reset_shadow_ok, _ = context_register_uses_unique_next(
        local_reset_shadow, "state_q", "context_state_next_w"
    )
    checks.append((
        "procedural-local-reset-shadow-killed",
        unique_ok and not local_reset_shadow_ok,
    ))
    local_next_shadow = unique_writer.replace(
        "else state_q <= context_state_next_w;",
        "else begin logic context_state_next_w; "
        "state_q <= context_state_next_w; end",
    )
    local_next_shadow_ok, _ = context_register_uses_unique_next(
        local_next_shadow, "state_q", "context_state_next_w"
    )
    checks.append((
        "procedural-local-next-shadow-killed",
        unique_ok and not local_next_shadow_ok,
    ))
    conditional_nonreset = unique_writer.replace(
        "else state_q <= context_state_next_w;",
        "else if (evil_i) state_q <= context_state_next_w;",
    )
    conditional_nonreset_ok, _ = context_register_uses_unique_next(
        conditional_nonreset, "state_q", "context_state_next_w"
    )
    checks.append((
        "nonreset-conditional-unique-next-killed",
        unique_ok and not conditional_nonreset_ok,
    ))
    statement_event_nonreset = unique_writer.replace(
        "else state_q <= context_state_next_w;",
        "else begin @(posedge evil_clk); "
        "state_q <= context_state_next_w; end",
    )
    statement_event_ok, _ = context_register_uses_unique_next(
        statement_event_nonreset, "state_q", "context_state_next_w"
    )
    checks.append((
        "statement-event-unique-next-killed",
        unique_ok and not statement_event_ok,
    ))
    uppercase_reset_input = code_only("""
      module UpperReset(input clk, input rst, input [1:0] RESET_VALUE,
                        input [1:0] context_state_next_w);
        logic [1:0] state_q;
        always @(posedge clk) begin
          if (rst) state_q <= RESET_VALUE;
          else state_q <= context_state_next_w;
        end
      endmodule
    """)
    uppercase_reset_input_ok, _ = context_register_uses_unique_next(
        module_body(uppercase_reset_input, "UpperReset") or "",
        "state_q", "context_state_next_w",
    )
    uppercase_localparam = uppercase_reset_input.replace(
        "input [1:0] RESET_VALUE,", "input [1:0] reset_unused_i,"
    ).replace(
        "logic [1:0] state_q;",
        "localparam [1:0] RESET_VALUE = 2'b00; logic [1:0] state_q;",
    )
    uppercase_localparam_ok, _ = context_register_uses_unique_next(
        module_body(uppercase_localparam, "UpperReset") or "",
        "state_q", "context_state_next_w",
    )
    uppercase_task_localparam = uppercase_reset_input.replace(
        "logic [1:0] state_q;",
        "task automatic shadow; localparam [1:0] RESET_VALUE = 2'b00; "
        "endtask logic [1:0] state_q;",
    )
    uppercase_task_localparam_ok, _ = context_register_uses_unique_next(
        module_body(uppercase_task_localparam, "UpperReset") or "",
        "state_q", "context_state_next_w",
    )
    checks.append((
        "uppercase-live-reset-input-killed",
        not uppercase_reset_input_ok and not uppercase_task_localparam_ok,
    ))
    checks.append((
        "uppercase-localparam-reset-literal-accepted", uppercase_localparam_ok
    ))

    legacy_constant_writer = code_only("""
      always @(posedge clk) begin
        if (rst) state_q <= 1'b0;
        else if (legacy) state_q <= 1'b0;
        else state_q <= state_next_w;
      end
    """)
    legacy_constant_ok, _ = context_register_uses_unique_next(
        legacy_constant_writer, "state_q", "state_next_w"
    )
    checks.append(("legacy-constant-write-killed", not legacy_constant_ok))

    nonreset_tail_override = code_only("""
      always @(posedge clk) begin
        if (rst) state_q <= 1'b0;
        else begin
          state_q <= state_next_w;
          state_q <= 1'b0;
        end
      end
    """)
    nonreset_tail_ok, _ = context_register_uses_unique_next(
        nonreset_tail_override, "state_q", "state_next_w"
    )
    checks.append(("nonreset-constant-tail-override-killed", not nonreset_tail_ok))

    multiple_writers = code_only("""
      always @(posedge clk) begin
        if (rst) state_q <= 1'b0; else state_q <= state_next_w;
      end
      always @(posedge clk) begin
        state_q <= state_next_w;
      end
    """)
    multiple_writers_ok, _ = context_register_uses_unique_next(
        multiple_writers, "state_q", "state_next_w"
    )
    checks.append(("multiple-sequential-writers-killed", not multiple_writers_ok))

    blocking_writer = code_only("""
      always @(posedge clk) begin
        if (rst) state_q = 1'b0; else state_q = state_next_w;
      end
    """)
    blocking_writer_ok, _ = context_register_uses_unique_next(
        blocking_writer, "state_q", "state_next_w"
    )
    checks.append(("blocking-sequential-writer-killed", not blocking_writer_ok))

    extra_writer_mutations = [
        (
            "always-ff-second-writer-killed",
            "always_ff @(posedge clk) state_q <= bad_w;",
        ),
        (
            "negedge-second-writer-killed",
            "always @(negedge clk) state_q <= bad_w;",
        ),
        (
            "always-latch-second-writer-killed",
            "always_latch state_q <= bad_w;",
        ),
        (
            "initial-writer-killed",
            "initial state_q <= bad_w;",
        ),
        (
            "continuous-writer-killed",
            "assign state_q = bad_w;",
        ),
    ]
    for name, extra_writer in extra_writer_mutations:
        extra_writer_ok, _ = context_register_uses_unique_next(
            unique_writer + "\n" + extra_writer,
            "state_q",
            "context_state_next_w",
        )
        checks.append((name, not extra_writer_ok))

    scalar_lhs_select = unique_writer.replace(
        "else state_q <= context_state_next_w;",
        "else state_q[0] <= context_state_next_w;",
    )
    scalar_lhs_select_ok, _ = context_register_uses_unique_next(
        scalar_lhs_select, "state_q", "context_state_next_w"
    )
    checks.append(("scalar-lhs-part-select-killed", not scalar_lhs_select_ok))

    scalar_rhs_select = unique_writer.replace(
        "else state_q <= context_state_next_w;",
        "else state_q <= context_state_next_w[0];",
    )
    scalar_rhs_select_ok, _ = context_register_uses_unique_next(
        scalar_rhs_select, "state_q", "context_state_next_w"
    )
    checks.append(("scalar-rhs-part-select-killed", not scalar_rhs_select_ok))

    indexed_writer = code_only("""
      always @(posedge clk) begin
        if (rst) array_q[i] <= 8'b0;
        else array_q[i] <= array_next_w[i];
      end
    """)
    indexed_writer_ok, _ = context_register_uses_unique_next(
        indexed_writer, "array_q", "array_next_w", allow_indexed=True
    )
    checks.append(("indexed-array-unique-next-accepted", indexed_writer_ok))
    indexed_second_dimension = indexed_writer + code_only("""
      always_ff @(posedge clk) array_q[j][0] <= bad_w;
    """)
    indexed_second_dimension_ok, _ = context_register_uses_unique_next(
        indexed_second_dimension,
        "array_q",
        "array_next_w",
        allow_indexed=True,
    )
    checks.append((
        "indexed-array-second-dimension-writer-killed",
        not indexed_second_dimension_ok,
    ))
    scalar_nested_index = unique_writer + code_only(
        "always @(posedge clk) state_q[idx[0]] <= bad_w;"
    )
    scalar_nested_index_ok, _ = context_register_uses_unique_next(
        scalar_nested_index, "state_q", "context_state_next_w"
    )
    indexed_nested_index = indexed_writer.replace(
        "else array_q[i] <= array_next_w[i];",
        "else begin array_q[i] <= array_next_w[i]; "
        "array_q[idx[0]] <= bad_w; end",
    )
    indexed_nested_index_ok, _ = context_register_uses_unique_next(
        indexed_nested_index, "array_q", "array_next_w", allow_indexed=True
    )
    checks.append((
        "nested-index-second-writer-killed",
        not scalar_nested_index_ok and not indexed_nested_index_ok,
    ))

    for direction, name in (
        ("output logic [7:0]", "task-output-actual-writer-killed"),
        ("inout logic [7:0]", "task-inout-actual-writer-killed"),
        ("ref logic [7:0]", "task-ref-actual-writer-killed"),
    ):
        task_writer = unique_writer + code_only(f"""
          task automatic write_bad({direction} x);
            x = bad_w;
          endtask
          always @(posedge clk) write_bad(state_q);
        """)
        task_writer_ok, _ = context_register_uses_unique_next(
            task_writer, "state_q", "context_state_next_w"
        )
        checks.append((name, not task_writer_ok))

    imported_task_source = code_only("""
      package P;
        task automatic overwrite(output logic [1:0] x);
          x = 2'b11;
        endtask
      endpackage
      module ImportedTaskHost(input clk, input rst,
                              input [1:0] context_state_next_w);
        import P::*;
        logic [1:0] state_q;
        always @(posedge clk) begin
          if (rst) state_q <= 2'b00;
          else begin
            state_q <= context_state_next_w;
            overwrite(state_q);
          end
        end
      endmodule
    """)
    imported_task_ok, _ = context_register_uses_unique_next(
        module_body(imported_task_source, "ImportedTaskHost") or "",
        "state_q",
        "context_state_next_w",
    )
    checks.append((
        "imported-package-task-output-actual-writer-killed",
        not imported_task_ok,
    ))
    hierarchical_task_writer = unique_writer.replace(
        "else state_q <= context_state_next_w;",
        "else begin state_q <= context_state_next_w; writer.overwrite(state_q); end",
    )
    hierarchical_task_ok, _ = context_register_uses_unique_next(
        hierarchical_task_writer, "state_q", "context_state_next_w"
    )
    checks.append((
        "hierarchical-task-actual-writer-killed",
        not hierarchical_task_ok,
    ))
    escaped_task_mutations = [
        (
            "escaped-bare-task-actual-writer-killed",
            "\\overwrite_bad (state_q);",
        ),
        (
            "escaped-package-task-actual-writer-killed",
            "P::\\overwrite_bad (state_q);",
        ),
        (
            "escaped-hierarchical-task-actual-writer-killed",
            "writer.\\overwrite_bad (state_q);",
        ),
    ]
    for name, call in escaped_task_mutations:
        source = unique_writer.replace(
            "else state_q <= context_state_next_w;",
            f"else begin state_q <= context_state_next_w; {call} end",
        )
        escaped_ok, _ = context_register_uses_unique_next(
            source, "state_q", "context_state_next_w"
        )
        checks.append((name, not escaped_ok))
    punctuation_escaped = unique_writer.replace(
        "else state_q <= context_state_next_w;",
        "else begin state_q <= context_state_next_w; \\( (state_q); end",
    )
    punctuation_escaped_ok, _ = context_register_uses_unique_next(
        punctuation_escaped, "state_q", "context_state_next_w"
    )
    checks.append((
        "punctuation-only-escaped-task-actual-killed",
        not punctuation_escaped_ok,
    ))

    system_readmemh = unique_writer + code_only(
        'initial $readmemh("state.hex", state_q);'
    )
    system_readmemh_ok, _ = context_register_uses_unique_next(
        system_readmemh, "state_q", "context_state_next_w"
    )
    checks.append((
        "system-readmemh-array-writer-killed", not system_readmemh_ok
    ))
    system_output_actual = unique_writer.replace(
        "else state_q <= context_state_next_w;",
        'else begin state_q <= context_state_next_w; '
        '$sscanf(text_i, "%d", state_q); end',
    )
    system_output_ok, _ = context_register_uses_unique_next(
        system_output_actual, "state_q", "context_state_next_w"
    )
    checks.append((
        "system-output-actual-writer-killed", not system_output_ok
    ))
    diagnostic_call = unique_writer.replace(
        "else state_q <= context_state_next_w;",
        'else begin state_q <= context_state_next_w; $display("q=%0d", state_q); end',
    )
    diagnostic_ok, _ = context_register_uses_unique_next(
        diagnostic_call, "state_q", "context_state_next_w"
    )
    checks.append(("readonly-system-diagnostic-accepted", diagnostic_ok))
    embedded_system_output = unique_writer.replace(
        "else state_q <= context_state_next_w;",
        'else begin state_q <= context_state_next_w; '
        'if ($sscanf(text_i, "%d", state_q) > 0) sink_q <= 1\'b1; end',
    )
    embedded_system_ok, _ = context_register_uses_unique_next(
        embedded_system_output, "state_q", "context_state_next_w"
    )
    checks.append((
        "embedded-system-output-expression-killed", not embedded_system_ok
    ))
    embedded_unknown_call = unique_writer.replace(
        "else state_q <= context_state_next_w;",
        "else begin state_q <= context_state_next_w; "
        "if (mystery_ref(state_q)) sink_q <= 1'b1; end",
    )
    embedded_unknown_ok, _ = context_register_uses_unique_next(
        embedded_unknown_call, "state_q", "context_state_next_w"
    )
    checks.append((
        "embedded-unknown-call-expression-killed", not embedded_unknown_ok
    ))
    nested_concat_writer = unique_writer + code_only("""
      always @* begin
        {other_q, {state_q}} = bad_w;
      end
    """)
    nested_concat_ok, _ = context_register_uses_unique_next(
        nested_concat_writer, "state_q", "context_state_next_w"
    )
    checks.append((
        "nested-concat-unique-next-writer-killed",
        not nested_concat_ok,
    ))
    dead_generate_unique = code_only(
        "generate if (0) begin : g_dead\n" + unique_writer
        + "\nend endgenerate"
    )
    dead_generate_unique_ok, _ = context_register_uses_unique_next(
        dead_generate_unique, "state_q", "context_state_next_w"
    )
    checks.append((
        "dead-generate-unique-next-writer-killed",
        not dead_generate_unique_ok,
    ))
    replicated_generate_unique = code_only(
        "generate for (genvar g = 0; g < 2; g = g + 1) begin : g_rep\n"
        + unique_writer + "\nend endgenerate"
    )
    replicated_generate_unique_ok, _ = context_register_uses_unique_next(
        replicated_generate_unique, "state_q", "context_state_next_w"
    )
    checks.append((
        "generate-for-replicated-writer-killed",
        not replicated_generate_unique_ok,
    ))
    named_generate_unique = code_only(
        "generate begin : g_shadow\n" + unique_writer
        + "\nend endgenerate"
    )
    named_generate_unique_ok, _ = context_register_uses_unique_next(
        named_generate_unique, "state_q", "context_state_next_w"
    )
    checks.append((
        "named-generate-shadow-unique-next-killed",
        not named_generate_unique_ok,
    ))
    procedural_local_state = unique_writer.replace(
        "if (rst)", "logic [1:0] state_q; if (rst)"
    )
    procedural_local_state_ok, _ = context_register_uses_unique_next(
        procedural_local_state, "state_q", "context_state_next_w"
    )
    checks.append((
        "procedural-local-state-shadow-unique-next-killed",
        not procedural_local_state_ok,
    ))
    typedef_local_state = code_only("typedef logic [1:0] state_t;\n") + \
        unique_writer.replace(
            "else state_q <= context_state_next_w;",
            "else begin state_t state_q; state_q <= context_state_next_w; end",
        )
    typedef_local_state_ok, _ = context_register_uses_unique_next(
        typedef_local_state, "state_q", "context_state_next_w"
    )
    checks.append((
        "typedef-local-shadow-unique-next-killed",
        not typedef_local_state_ok,
    ))

    registered_owner = code_only("""
      assign writer_owned = writer_owner_q;
      always @(posedge clk) writer_owner_q <= csr_commit;
    """)
    owner_all = assignment_graph(registered_owner)
    owner_comb = assignment_graph(registered_owner, include_sequential=False)
    checks.append((
        "registered-writer-breaks-combinational-loop",
        depends_on(owner_all, "writer_owned", "csr_commit")
        and not depends_on(owner_comb, "writer_owned", "csr_commit"),
    ))
    delayed_abort = code_only("""
      assign state_next_w = delayed_abort_q;
      always @(posedge clk) begin
        if (rst) delayed_abort_q <= 1'b0;
        else delayed_abort_q <= abort_i;
      end
    """)
    delayed_all = assignment_graph(delayed_abort)
    delayed_comb = assignment_graph(delayed_abort, include_sequential=False)
    checks.append((
        "sequential-delay-not-a-combinational-dependency",
        depends_on(delayed_all, "state_next_w", "abort_i")
        and not depends_on(delayed_comb, "state_next_w", "abort_i"),
    ))

    parameterized = code_only("""
      module Host(input sig);
        Child #(.WIDTH(`EXPECTED_W)) u_child (.sig_i(sig));
      endmodule
    """)
    params_ok, _ = exact_instance_parameters(
        module_body(parameterized, "Host") or "", "Child",
        {"WIDTH": "`EXPECTED_W"},
    )
    params_bad, _ = exact_instance_parameters(
        module_body(parameterized, "Host") or "", "Child",
        {"WIDTH": "`WRONG_W"},
    )
    checks.append(("dummy-width-parameter-killed", params_ok and not params_bad))

    width_fixture = code_only("module Host(output [`EXPECTED_W-1:0] identity_o); endmodule")
    checks.append((
        "dummy-identity-port-width-killed",
        declared_port_width(width_fixture, "identity_o", "`EXPECTED_W")
        and not declared_port_width(width_fixture, "identity_o", "`WRONG_W"),
    ))
    off_by_one_width = code_only(
        "module Host(output [`EXPECTED_W:0] identity_o); endmodule"
    )
    truncated_width = code_only(
        "module Host(output [`EXPECTED_W-2:0] identity_o); endmodule"
    )
    symbolic_width = code_only(
        "module Host(output [(`EXPECTED_W*0)+3:0] identity_o); endmodule"
    )
    checks.append((
        "noncanonical-packed-ranges-killed",
        not declared_port_width(off_by_one_width, "identity_o", "`EXPECTED_W")
        and not declared_port_width(truncated_width, "identity_o", "`EXPECTED_W")
        and not declared_port_width(symbolic_width, "identity_o", "`EXPECTED_W"),
    ))
    adjacent_width_fixture = code_only(
        "module Host(output [`EXPECTED_W-1:0] other_o, "
        "output [`WRONG_W-1:0] identity_o); endmodule"
    )
    checks.append((
        "adjacent-port-width-misattribution-killed",
        not declared_port_width(
            adjacent_width_fixture, "identity_o", "`EXPECTED_W"
        ),
    ))

    signal_width_fixture = code_only(
        "module Host; wire [`EXPECTED_W-1:0] held_identity_w; endmodule"
    )
    checks.append((
        "internal-identity-signal-width-killed",
        declared_signal_width(
            signal_width_fixture, "held_identity_w", "`EXPECTED_W"
        ) and not declared_signal_width(
            signal_width_fixture, "held_identity_w", "`WRONG_W"
        ),
    ))

    match_requirement = {
        "target": "held_match",
        "sources": ["current_id", "held_id"],
        "required_operators": ["=="],
        "equality_pair": ["current_id", "held_id"],
        "forbidden_operators": ["||"],
        "forbid_absorbing_constants": True,
    }
    match_good = code_only("assign held_match = (current_id == held_id);")
    match_bad = code_only("assign held_match = (current_id == held_id) || 1'b1;")
    checks.append((
        "held-head-match-bypass-killed",
        not boolean_requirement_errors(match_good, match_requirement)
        and bool(boolean_requirement_errors(match_bad, match_requirement)),
    ))
    match_inverted = code_only("assign held_match = !(current_id == held_id);")
    checks.append((
        "inverted-held-head-equality-killed",
        bool(boolean_requirement_errors(match_inverted, match_requirement)),
    ))

    grant_requirement = {
        "target": "grant_ready",
        "sources": ["held_match", "base_ready"],
        "positive_sources": ["held_match", "base_ready"],
        "required_operators": ["&&"],
        "forbidden_operators": ["||"],
        "forbid_absorbing_constants": True,
    }
    grant_good = code_only("assign grant_ready = held_match && base_ready;")
    grant_inverted = code_only("assign grant_ready = !held_match && base_ready;")
    checks.append((
        "inverted-grant-source-killed",
        not boolean_requirement_errors(grant_good, grant_requirement)
        and bool(boolean_requirement_errors(grant_inverted, grant_requirement)),
    ))

    phase_requirement = {
        "target": "squash_valid",
        "sources": ["phase_q", "sent_q"],
        "positive_sources": ["phase_q"],
        "negated_sources": ["sent_q"],
        "required_operators": ["==", "&&", "!"],
        "exact_expression": "(phase_q == PHASE_SQUASH) && !sent_q",
        "forbidden_operators": ["||"],
        "forbid_absorbing_constants": True,
        "forbid_ternary_xor": True,
    }
    phase_good = code_only(
        "assign squash_valid = (phase_q == PHASE_SQUASH) && !sent_q;"
    )
    phase_bad = code_only("assign squash_valid = phase_q && !sent_q;")
    checks.append((
        "phase-nonzero-instead-of-enum-killed",
        not boolean_requirement_errors(phase_good, phase_requirement)
        and bool(boolean_requirement_errors(phase_bad, phase_requirement)),
    ))

    generation_requirement = {
        "target": "done",
        "sources": ["ack_q", "generation_q", "generation_i"],
        "positive_sources": ["ack_q", "generation_q", "generation_i"],
        "required_operators": ["&&", "=="],
        "exact_expression": "ack_q && (generation_q == generation_i)",
        "forbidden_operators": ["||"],
        "forbid_absorbing_constants": True,
        "forbid_ternary_xor": True,
    }
    generation_good = code_only(
        "assign done = ack_q && (generation_q == generation_i);"
    )
    stale_generation_bad = code_only(
        "assign done = ack_q && (generation_q != generation_i);"
    )
    nonsticky_done_bad = code_only(
        "assign done = request_valid_i && (generation_q == generation_i);"
    )
    checks.append((
        "stale-generation-ack-killed",
        not boolean_requirement_errors(generation_good, generation_requirement)
        and bool(boolean_requirement_errors(stale_generation_bad, generation_requirement)),
    ))
    checks.append((
        "nonsticky-request-pulse-done-killed",
        bool(boolean_requirement_errors(nonsticky_done_bad, generation_requirement)),
    ))

    typed_requirement = {
        "target": "leaf_clear",
        "sources": ["invalidate_i", "cause_i"],
        "positive_sources": ["invalidate_i", "cause_i"],
        "required_operators": ["&&", "&", "|"],
        "exact_expression": "invalidate_i && |(cause_i & EXPECTED_MASK)",
        "forbidden_operators": ["||"],
        "forbid_absorbing_constants": True,
        "forbid_ternary_xor": True,
    }
    typed_good = code_only(
        "assign leaf_clear = invalidate_i && |(cause_i & EXPECTED_MASK);"
    )
    typed_bad = code_only(
        "assign leaf_clear = invalidate_i && |(cause_i & WRONG_MASK);"
    )
    checks.append((
        "wrong-typed-leaf-mask-killed",
        not boolean_requirement_errors(typed_good, typed_requirement)
        and bool(boolean_requirement_errors(typed_bad, typed_requirement)),
    ))

    atomic_invalidate_requirement = {
        "target": "invalidate_w",
        "sources": ["grant_fire_w", "grant_cause_w"],
        "exact_expression": "grant_fire_w && |grant_cause_w",
    }
    atomic_invalidate_good = code_only(
        "assign invalidate_w = grant_fire_w && |grant_cause_w;"
    )
    atomic_invalidate_early = code_only(
        "assign invalidate_w = grant_fire_w || |grant_cause_w;"
    )
    checks.append((
        "early-translation-invalidate-killed",
        not boolean_requirement_errors(
            atomic_invalidate_good, atomic_invalidate_requirement
        ) and bool(boolean_requirement_errors(
            atomic_invalidate_early, atomic_invalidate_requirement
        )),
    ))

    memory_done_requirement = {
        "target": "done_o",
        "sources": ["ack_q", "captured_identity_q", "request_identity_i"],
        "exact_expression": (
            "ack_q && (captured_identity_q == request_identity_i)"
        ),
    }
    memory_done_good = code_only(
        "assign done_o = ack_q && (captured_identity_q == request_identity_i);"
    )
    memory_done_or = code_only(
        "assign done_o = sq_done_w || owner_done_w;"
    )
    checks.append((
        "memory-squash-done-or-killed",
        not boolean_requirement_errors(memory_done_good, memory_done_requirement)
        and bool(boolean_requirement_errors(memory_done_or, memory_done_requirement)),
    ))

    held_slice_requirement = {
        "target": "held_identity_w",
        "sources": ["grant_payload_w"],
        "exact_expression": "grant_payload_w[`ID_MSB:`ID_LSB]",
    }
    held_slice_good = code_only(
        "assign held_identity_w = grant_payload_w[`ID_MSB:`ID_LSB];"
    )
    held_slice_bad = code_only(
        "assign held_identity_w = grant_payload_w[`OWNER_MSB:`OWNER_LSB];"
    )
    checks.append((
        "wrong-held-identity-payload-slice-killed",
        not boolean_requirement_errors(held_slice_good, held_slice_requirement)
        and bool(boolean_requirement_errors(held_slice_bad, held_slice_requirement)),
    ))

    epoch_capture_requirement = {
        "target": "epoch_next_w",
        "sources": ["epoch_q", "capture_fire_w", "current_epoch_i"],
        "exact_expression": "capture_fire_w ? current_epoch_i : epoch_q",
    }
    epoch_capture_good = code_only(
        "assign epoch_next_w = capture_fire_w ? current_epoch_i : epoch_q;"
    )
    epoch_capture_bad = code_only(
        "assign epoch_next_w = capture_fire_w ? 2'b00 : epoch_q;"
    )
    checks.append((
        "valid-epoch-capture-constant-killed",
        not boolean_requirement_errors(epoch_capture_good, epoch_capture_requirement)
        and bool(boolean_requirement_errors(epoch_capture_bad, epoch_capture_requirement)),
    ))

    sq_fill_epoch_requirement = {
        "target": "sq_fill_mmu_epoch_w",
        "sources": [
            "sq_mode_w", "miq_head_mmu_epoch_w", "mem_issue_res_mmu_epoch_q"
        ],
        "exact_expression": (
            "sq_mode_w ? miq_head_mmu_epoch_w : mem_issue_res_mmu_epoch_q"
        ),
    }
    sq_fill_epoch_good = code_only(
        "assign sq_fill_mmu_epoch_w = sq_mode_w ? "
        "miq_head_mmu_epoch_w : mem_issue_res_mmu_epoch_q;"
    )
    sq_fill_epoch_constant = code_only(
        "assign sq_fill_mmu_epoch_w = 2'b00;"
    )
    checks.append((
        "sq-fill-epoch-constant-alias-killed",
        not boolean_requirement_errors(
            sq_fill_epoch_good, sq_fill_epoch_requirement
        )
        and bool(boolean_requirement_errors(
            sq_fill_epoch_constant, sq_fill_epoch_requirement
        )),
    ))

    miq_map = code_only("""
      module Host(input push_valid_w, input [1:0] push_epoch_w,
                  output [1:0] head_epoch_w);
        Queue u_mem_inflight_queue (
          .push_valid_i(push_valid_w),
          .push_mmu_epoch_i(push_epoch_w),
          .head_mmu_epoch_o(head_epoch_w)
        );
      endmodule
    """)
    miq_map_expected = {
        "push_valid_i": "push_valid_w",
        "push_mmu_epoch_i": "push_epoch_w",
        "head_mmu_epoch_o": "head_epoch_w",
    }
    miq_map_ok, _ = exact_instance_connection(
        module_body(miq_map, "Host") or "", "Queue", miq_map_expected,
        "u_mem_inflight_queue",
    )
    miq_map_bad, _ = exact_instance_connection(
        (module_body(miq_map, "Host") or "").replace(
            ".push_valid_i(push_valid_w)", ".push_valid_i(1'b0)"
        ),
        "Queue", miq_map_expected, "u_mem_inflight_queue",
    )
    checks.append(("miq-push-port-map-killed", miq_map_ok and not miq_map_bad))

    miq_chain_good = code_only("""
      assign mem_req_fire_any_w = mem_req_valid_o && mem_req_ready_i;
      assign miq_push_valid_w = mem_req_fire_any_w;
      assign miq_push_mmu_epoch_w = mem_req_mmu_epoch_o;
      assign push_fire_w = push_valid_i && !full_o && !flush_i;
      assign head_mmu_epoch_o = mmu_epoch_q[head_q];
    """)
    miq_chain_requirements = {
        "mem_req_fire_any_w": {
            "target": "mem_req_fire_any_w",
            "sources": ["mem_req_valid_o", "mem_req_ready_i"],
            "exact_expression": "mem_req_valid_o && mem_req_ready_i",
        },
        "miq_push_valid_w": {
            "target": "miq_push_valid_w",
            "sources": ["mem_req_fire_any_w"],
            "exact_expression": "mem_req_fire_any_w",
        },
        "miq_push_mmu_epoch_w": {
            "target": "miq_push_mmu_epoch_w",
            "sources": ["mem_req_mmu_epoch_o"],
            "exact_expression": "mem_req_mmu_epoch_o",
        },
        "push_fire_w": {
            "target": "push_fire_w",
            "sources": ["push_valid_i", "full_o", "flush_i"],
            "exact_expression": "push_valid_i && !full_o && !flush_i",
        },
        "head_mmu_epoch_o": {
            "target": "head_mmu_epoch_o",
            "sources": ["mmu_epoch_q", "head_q"],
            "exact_expression": "mmu_epoch_q[head_q]",
        },
    }
    miq_chain_is_good = all(
        not boolean_requirement_errors(miq_chain_good, requirement)
        for requirement in miq_chain_requirements.values()
    )
    miq_push_valid_bad = miq_chain_good.replace(
        "assign miq_push_valid_w = mem_req_fire_any_w;",
        "assign miq_push_valid_w = mem_req_valid_o;",
    )
    checks.append((
        "miq-push-valid-alias-killed",
        miq_chain_is_good and bool(boolean_requirement_errors(
            miq_push_valid_bad, miq_chain_requirements["miq_push_valid_w"]
        )),
    ))
    miq_push_epoch_bad = miq_chain_good.replace(
        "assign miq_push_mmu_epoch_w = mem_req_mmu_epoch_o;",
        "assign miq_push_mmu_epoch_w = current_mmu_epoch_i;",
    )
    checks.append((
        "miq-push-epoch-alias-killed",
        miq_chain_is_good and bool(boolean_requirement_errors(
            miq_push_epoch_bad, miq_chain_requirements["miq_push_mmu_epoch_w"]
        )),
    ))
    miq_head_bad = miq_chain_good.replace(
        "assign head_mmu_epoch_o = mmu_epoch_q[head_q];",
        "assign head_mmu_epoch_o = mmu_epoch_q[tail_q];",
    )
    checks.append((
        "miq-head-epoch-source-killed",
        miq_chain_is_good and bool(boolean_requirement_errors(
            miq_head_bad, miq_chain_requirements["head_mmu_epoch_o"]
        )),
    ))

    miq_host_override = code_only("""
      module Host(output [1:0] head_epoch_w);
        Queue u_mem_inflight_queue (.head_mmu_epoch_o(head_epoch_w));
        assign head_epoch_w = 2'b00;
      endmodule
    """)
    miq_exclusive_requirement = {
        "child": "Queue",
        "instance": "u_mem_inflight_queue",
        "port": "head_mmu_epoch_o",
        "signal": "head_epoch_w",
    }
    checks.append((
        "miq-head-host-override-killed",
        bool(exclusive_instance_output_errors(
            module_body(miq_host_override, "Host") or "",
            miq_exclusive_requirement,
        )),
    ))

    miq_width_good = code_only("""
      module Queue #(parameter MMU_EPOCH_W = 2);
        reg [MMU_EPOCH_W-1:0] mmu_epoch_q [0:3];
      endmodule
    """)
    miq_width_bad = miq_width_good.replace(
        "[MMU_EPOCH_W-1:0]", "[MMU_EPOCH_W-2:0]"
    )
    checks.append((
        "miq-epoch-storage-width-killed",
        declared_signal_width(miq_width_good, "mmu_epoch_q", "MMU_EPOCH_W")
        and not declared_signal_width(
            miq_width_bad, "mmu_epoch_q", "MMU_EPOCH_W"
        ),
    ))

    miq_capture_requirement = {
        "register": "mmu_epoch_q",
        "index": "tail_q",
        "source": "push_mmu_epoch_i",
        "guard": "push_fire_w",
        "canonical_ancestors": [
            {"condition": "rst", "arm": "false"},
            {"condition": "flush_i", "arm": "false"},
            {"condition": "push_fire_w", "arm": "true"},
        ],
        "allowed_writes": [
            {
                "index": "i", "source": "{MMU_EPOCH_W{1'b0}}",
                "region": "reset",
            },
            {
                "index": "wr[ENTRY_W-1:0]",
                "source": "mmu_epoch_q[src]",
                "region": "nonreset",
            },
            {
                "index": "tail_q", "source": "push_mmu_epoch_i",
                "region": "nonreset",
            },
        ],
    }
    miq_capture_good = code_only("""
      always @(posedge clk) begin
        if (rst) begin
          mmu_epoch_q[i] <= {MMU_EPOCH_W{1'b0}};
        end else if (flush_i) begin
          mmu_epoch_q[wr[ENTRY_W-1:0]] <= mmu_epoch_q[src];
        end else begin
          if (push_fire_w) begin
            mmu_epoch_q[tail_q] <= push_mmu_epoch_i;
          end
        end
      end
    """)
    miq_capture_good_errors = guarded_indexed_capture_errors(
        miq_capture_good, miq_capture_requirement
    )
    miq_capture_constant = miq_capture_good.replace(
        "mmu_epoch_q[tail_q] <= push_mmu_epoch_i;",
        "mmu_epoch_q[tail_q] <= 2'b00;",
    )
    checks.append((
        "miq-epoch-capture-constant-killed",
        not miq_capture_good_errors and bool(guarded_indexed_capture_errors(
            miq_capture_constant, miq_capture_requirement
        )),
    ))
    miq_capture_wrong_edge = miq_capture_good.replace("posedge clk", "negedge clk")
    checks.append((
        "miq-epoch-capture-wrong-edge-killed",
        not miq_capture_good_errors and bool(guarded_indexed_capture_errors(
            miq_capture_wrong_edge, miq_capture_requirement
        )),
    ))
    guarded_reset_mutations = [
        ("guarded-reset-logical-not-killed", "if (!rst)"),
        ("guarded-reset-bitwise-not-killed", "if (~rst)"),
        ("guarded-reset-zero-compare-killed", "if (rst == 1'b0)"),
        ("guarded-reset-composite-killed", "if (rst && reset_enable_i)"),
    ]
    for name, predicate in guarded_reset_mutations:
        mutated = miq_capture_good.replace("if (rst)", predicate)
        checks.append((
            name,
            not miq_capture_good_errors and bool(guarded_indexed_capture_errors(
                mutated, miq_capture_requirement
            )),
        ))
    guarded_extra_event = miq_capture_good.replace(
        "@(posedge clk)", "@(posedge clk or negedge rst)"
    )
    checks.append((
        "extra-sensitivity-event-guarded-capture-killed",
        not miq_capture_good_errors and bool(guarded_indexed_capture_errors(
            guarded_extra_event, miq_capture_requirement
        )),
    ))
    guarded_local_state = miq_capture_good.replace(
        "if (rst)", "logic [1:0] mmu_epoch_q [0:3]; if (rst)"
    )
    checks.append((
        "procedural-local-shadow-guarded-capture-killed",
        not miq_capture_good_errors and bool(guarded_indexed_capture_errors(
            guarded_local_state, miq_capture_requirement
        )),
    ))
    guarded_local_source = miq_capture_good.replace(
        "if (push_fire_w) begin",
        "logic [1:0] push_mmu_epoch_i; if (push_fire_w) begin",
    )
    checks.append((
        "procedural-local-source-shadow-guarded-capture-killed",
        not miq_capture_good_errors and bool(guarded_indexed_capture_errors(
            guarded_local_source, miq_capture_requirement
        )),
    ))
    guarded_typedef_shadow = code_only("typedef logic [1:0] epoch_t;\n") + \
        miq_capture_good.replace(
            "if (push_fire_w) begin",
            "epoch_t mmu_epoch_q [0:3]; if (push_fire_w) begin",
        )
    checks.append((
        "typedef-local-shadow-guarded-array-killed",
        not miq_capture_good_errors and bool(guarded_indexed_capture_errors(
            guarded_typedef_shadow, miq_capture_requirement
        )),
    ))
    guarded_extra_outer = code_only("""
      always @(posedge clk) begin
        if (rst) begin
          mmu_epoch_q[i] <= {MMU_EPOCH_W{1'b0}};
        end else if (flush_i) begin
          mmu_epoch_q[wr[ENTRY_W-1:0]] <= mmu_epoch_q[src];
        end else if (evil_i) begin
          if (push_fire_w) begin
            mmu_epoch_q[tail_q] <= push_mmu_epoch_i;
          end
        end
      end
    """)
    checks.append((
        "guarded-capture-extra-outer-condition-killed",
        not miq_capture_good_errors and bool(guarded_indexed_capture_errors(
            guarded_extra_outer, miq_capture_requirement
        )),
    ))
    guarded_timing_mutations = [
        (
            "guarded-capture-statement-event-killed",
            "@(posedge evil_clk); mmu_epoch_q[tail_q] <= push_mmu_epoch_i;",
        ),
        (
            "guarded-capture-delay-control-killed",
            "#1 mmu_epoch_q[tail_q] <= push_mmu_epoch_i;",
        ),
        (
            "guarded-capture-wait-control-killed",
            "wait (evil_i); mmu_epoch_q[tail_q] <= push_mmu_epoch_i;",
        ),
    ]
    for name, replacement in guarded_timing_mutations:
        mutated = miq_capture_good.replace(
            "mmu_epoch_q[tail_q] <= push_mmu_epoch_i;", replacement
        )
        checks.append((
            name,
            not miq_capture_good_errors and bool(guarded_indexed_capture_errors(
                mutated, miq_capture_requirement
            )),
        ))
    miq_capture_dead_generate = code_only(
        "generate if (0) begin : g_dead\n" + miq_capture_good
        + "\nend endgenerate"
    )
    checks.append((
        "miq-epoch-capture-dead-generate-killed",
        not miq_capture_good_errors and bool(guarded_indexed_capture_errors(
            miq_capture_dead_generate, miq_capture_requirement
        )),
    ))
    miq_capture_alias = miq_capture_good.replace(
        "mmu_epoch_q[tail_q] <= push_mmu_epoch_i;",
        "mmu_epoch_q[tail_q] <= push_mmu_epoch_i;\n"
        "            mmu_epoch_q[tail_alias_w] <= 2'b00;",
    )
    checks.append((
        "miq-epoch-capture-extra-alias-writer-killed",
        not miq_capture_good_errors and bool(guarded_indexed_capture_errors(
            miq_capture_alias, miq_capture_requirement
        )),
    ))
    miq_capture_concat = miq_capture_good.replace(
        "mmu_epoch_q[tail_q] <= push_mmu_epoch_i;",
        "mmu_epoch_q[tail_q] <= push_mmu_epoch_i;\n"
        "            {mmu_epoch_q[tail_alias_w], other_q} <= 3'b000;",
    )
    checks.append((
        "miq-epoch-capture-concat-writer-killed",
        not miq_capture_good_errors and bool(guarded_indexed_capture_errors(
            miq_capture_concat, miq_capture_requirement
        )),
    ))
    miq_capture_after_else = code_only("""
      always @(posedge clk) begin
        if (rst) begin
          mmu_epoch_q[i] <= {MMU_EPOCH_W{1'b0}};
        end else if (flush_i) begin
          mmu_epoch_q[wr[ENTRY_W-1:0]] <= mmu_epoch_q[src];
        end
        if (push_fire_w) begin
          mmu_epoch_q[tail_q] <= push_mmu_epoch_i;
        end
      end
    """)
    checks.append((
        "guarded-capture-after-reset-else-killed",
        not miq_capture_good_errors and bool(guarded_indexed_capture_errors(
            miq_capture_after_else, miq_capture_requirement
        )),
    ))
    miq_capture_region_swap = code_only("""
      always @(posedge clk) begin
        if (rst) begin
          mmu_epoch_q[i] <= {MMU_EPOCH_W{1'b0}};
          mmu_epoch_q[wr[ENTRY_W-1:0]] <= mmu_epoch_q[src];
        end else begin
          if (push_fire_w) begin
            mmu_epoch_q[tail_q] <= push_mmu_epoch_i;
          end
        end
      end
    """)
    checks.append((
        "guarded-capture-writer-region-swap-killed",
        not miq_capture_good_errors and bool(guarded_indexed_capture_errors(
            miq_capture_region_swap, miq_capture_requirement
        )),
    ))
    miq_capture_nested_concat = miq_capture_good.replace(
        "mmu_epoch_q[tail_q] <= push_mmu_epoch_i;",
        "mmu_epoch_q[tail_q] <= push_mmu_epoch_i;\n"
        "            {other_q, {mmu_epoch_q[tail_alias_w]}} <= 3'b000;",
    )
    checks.append((
        "nested-concat-guarded-array-writer-killed",
        not miq_capture_good_errors and bool(guarded_indexed_capture_errors(
            miq_capture_nested_concat, miq_capture_requirement
        )),
    ))
    miq_capture_dead_else = code_only(
        "generate if (1) begin : g_live\nwire dummy_w;\n"
        "end else begin : g_dead\n" + miq_capture_good
        + "\nend endgenerate"
    )
    checks.append((
        "dead-generate-else-guarded-capture-killed",
        not miq_capture_good_errors and bool(guarded_indexed_capture_errors(
            miq_capture_dead_else, miq_capture_requirement
        )),
    ))

    dead_equation = code_only("""
      generate if (0) begin : g_dead
        assign critical_w = source_a_w && source_b_w;
      end endgenerate
    """)
    dead_equation_requirement = {
        "target": "critical_w",
        "sources": ["source_a_w", "source_b_w"],
        "exact_expression": "source_a_w && source_b_w",
    }
    checks.append((
        "dead-generate-critical-equation-killed",
        bool(boolean_requirement_errors(
            dead_equation, dead_equation_requirement
        )),
    ))
    canonical_equation = code_only(
        "assign critical_w = source_a_w && source_b_w;"
    )
    wire_initializer_equation = code_only(
        "wire critical_w = source_a_w && source_b_w;"
    )
    checks.append((
        "wire-declaration-continuous-equation-accepted",
        not exact_combinational_driver_errors(canonical_equation, "critical_w")
        and not exact_combinational_driver_errors(
            wire_initializer_equation, "critical_w"
        ),
    ))
    logic_initializer_equation = code_only(
        "logic critical_w = source_a_w && source_b_w;"
    )
    checks.append((
        "logic-initializer-not-combinational-equation-killed",
        bool(exact_combinational_driver_errors(
            logic_initializer_equation, "critical_w"
        )),
    ))
    initializer_plus_blocking = code_only("""
      logic critical_w = source_a_w && source_b_w;
      always_comb critical_w = live_w;
    """)
    checks.append((
        "initializer-plus-live-blocking-driver-killed",
        bool(exact_combinational_driver_errors(
            initializer_plus_blocking, "critical_w"
        )),
    ))
    extra_equation_driver = canonical_equation + code_only(
        "always @* critical_w = live_w;"
    )
    checks.append((
        "exact-equation-extra-driver-killed",
        bool(exact_combinational_driver_errors(
            extra_equation_driver, "critical_w"
        )),
    ))
    concat_equation_driver = canonical_equation + code_only(
        "always @* {other_w, {critical_w}} = live_w;"
    )
    checks.append((
        "exact-equation-concat-writer-killed",
        bool(exact_combinational_driver_errors(
            concat_equation_driver, "critical_w"
        )),
    ))
    task_equation_driver = canonical_equation + code_only(
        "always @* overwrite(critical_w);"
    )
    checks.append((
        "exact-equation-task-actual-writer-killed",
        bool(exact_combinational_driver_errors(
            task_equation_driver, "critical_w"
        )),
    ))
    procedural_continuous_equation = code_only("""
      initial begin
        assign critical_w = source_a_w && source_b_w;
      end
    """)
    checks.append((
        "procedural-continuous-canonical-equation-killed",
        bool(exact_combinational_driver_errors(
            procedural_continuous_equation, "critical_w"
        )),
    ))
    named_generate_equation = code_only("""
      generate begin : g_shadow
        wire critical_w = source_a_w && source_b_w;
      end endgenerate
    """)
    checks.append((
        "named-generate-shadow-canonical-equation-killed",
        bool(boolean_requirement_errors(
            named_generate_equation, dead_equation_requirement
        )) and bool(exact_combinational_driver_errors(
            named_generate_equation, "critical_w"
        )),
    ))
    implicit_rhs_declaration = code_only("""
      module DeclHost;
        wire other_w = implicit_target_w;
      endmodule
    """)
    implicit_rhs_body = module_body(implicit_rhs_declaration, "DeclHost") or ""
    checks.append((
        "implicit-net-rhs-not-a-declaration-killed",
        bool(module_symbol_declaration_errors(
            implicit_rhs_body, "implicit_target_w"
        )),
    ))
    port_range_reference = code_only("""
      module RangeHost(input [range_source_w-1:0] other_i);
      endmodule
    """)
    port_range_body = module_body(port_range_reference, "RangeHost") or ""
    checks.append((
        "port-range-reference-not-a-declaration-killed",
        bool(module_symbol_declaration_errors(
            port_range_body, "range_source_w"
        )),
    ))
    unparenthesized_always_assign = code_only("""
      always @ trigger_i begin
        assign critical_w = source_a_w && source_b_w;
      end
    """)
    checks.append((
        "unparenthesized-always-procedural-assign-killed",
        bool(exact_combinational_driver_errors(
            unparenthesized_always_assign, "critical_w"
        )),
    ))
    unknown_child_driver = code_only("""
      module DriverHost(input source_a_w, input source_b_w, output critical_w);
        wire unused_w;
        assign critical_w = source_a_w && source_b_w;
        UnknownDriver u_unknown (.out_o({unused_w, critical_w}));
      endmodule
    """)
    unknown_driver_body = module_body(unknown_child_driver, "DriverHost") or ""
    primitive_driver = code_only("""
      module PrimitiveDriverHost(input source_a_w, input source_b_w,
                                 output critical_w);
        assign critical_w = source_a_w && source_b_w;
        buf u_extra_driver (critical_w, source_a_w);
      endmodule
    """)
    primitive_driver_body = (
        module_body(primitive_driver, "PrimitiveDriverHost") or ""
    )
    checks.append((
        "unknown-child-output-extra-driver-killed",
        bool(exact_combinational_driver_errors(
            unknown_driver_body, "critical_w", {}
        )) and bool(exact_combinational_driver_errors(
            primitive_driver_body, "critical_w", {}
        )),
    ))
    known_input_child = code_only("""
      module KnownConsumer(input in_i); endmodule
      module ConsumerHost(input source_a_w, input source_b_w, output critical_w);
        assign critical_w = source_a_w && source_b_w;
        KnownConsumer u_known (.in_i({critical_w}));
        KnownConsumer u_positional (critical_w);
      endmodule
    """)
    known_child_body = module_body(known_input_child, "KnownConsumer") or ""
    known_host_body = module_body(known_input_child, "ConsumerHost") or ""
    checks.append((
        "known-child-input-consumer-accepted",
        not exact_combinational_driver_errors(
            known_host_body, "critical_w", {"KnownConsumer": known_child_body}
        ),
    ))
    port_direction_shadow = code_only("""
      module PortShadow #(
        parameter WIDTH = 2, parameter OTHER_WIDTH = 8
      ) (input wire [WIDTH-1:0] context_effective_o);
        task automatic fake_writer(
          output logic [OTHER_WIDTH-1:0] context_effective_o
        );
          context_effective_o = 1'b0;
        endtask
      endmodule
    """)
    port_shadow_body = module_body(port_direction_shadow, "PortShadow") or ""
    checks.append((
        "lexical-header-port-direction-shadow-killed",
        declared_port(port_shadow_body, "input", "context_effective_o")
        and not declared_port(port_shadow_body, "output", "context_effective_o")
        and declared_port_width(
            port_shadow_body, "context_effective_o", "WIDTH"
        )
        and {
            ("PortShadow", "context_effective_o"),
            ("PortShadow", "RESET_VALUE"),
        }.issubset(manifest_critical_symbols({
            "required_ports": [{
                "module": "PortShadow", "port": "context_effective_o"
            }],
            "required_port_widths": [{
                "module": "PortShadow", "port": "RESET_VALUE"
            }],
        }))
        and bool(module_symbol_declaration_errors(
            port_shadow_body, "context_effective_o"
        )),
    ))
    reset_host_driver = code_only("""
      module ResetHost(input wire clk, input wire rst, input wire evil_i);
        assign rst = !evil_i;
      endmodule
    """)
    reset_host_body = module_body(reset_host_driver, "ResetHost") or ""
    checks.append((
        "canonical-reset-host-driver-killed",
        bool(canonical_control_source_errors(
            reset_host_body, "rst", {"ResetHost": reset_host_body}
        )),
    ))
    clock_child_driver = code_only("""
      module ClockSource(output clk_o); endmodule
      module ClockHost(input wire clk, input wire rst);
        ClockSource u_clock_source (.clk_o(clk));
      endmodule
    """)
    clock_source_body = module_body(clock_child_driver, "ClockSource") or ""
    clock_host_body = module_body(clock_child_driver, "ClockHost") or ""
    clock_input_consumer = code_only("""
      module ClockSink(input clk_i); endmodule
      module ClockGoodHost(input wire clk, input wire rst);
        ClockSink u_clock_sink (.clk_i(clk));
      endmodule
    """)
    clock_sink_body = module_body(clock_input_consumer, "ClockSink") or ""
    clock_good_host_body = (
        module_body(clock_input_consumer, "ClockGoodHost") or ""
    )
    checks.append((
        "canonical-clock-child-output-driver-killed",
        bool(canonical_control_source_errors(
            clock_host_body, "clk", {"ClockSource": clock_source_body}
        )) and not canonical_control_source_errors(
            clock_good_host_body, "clk", {"ClockSink": clock_sink_body}
        ),
    ))

    fence_frontend = code_only("""
      module Host(output head0_fencei_raw_w);
        Frontend u_frontend (.head0_fencei_raw_w(head0_fencei_raw_w));
      endmodule
    """)
    frontend_ok, _ = exact_instance_connection(
        module_body(fence_frontend, "Host") or "", "Frontend",
        {"head0_fencei_raw_w": "head0_fencei_raw_w"}, "u_frontend",
    )
    frontend_bad, _ = exact_instance_connection(
        (module_body(fence_frontend, "Host") or "").replace(
            ".head0_fencei_raw_w(head0_fencei_raw_w)",
            ".head0_fencei_raw_w(dummy_w)",
        ),
        "Frontend", {"head0_fencei_raw_w": "head0_fencei_raw_w"},
        "u_frontend",
    )
    checks.append((
        "fencei-frontend-producer-map-killed", frontend_ok and not frontend_bad
    ))

    fence_execute = code_only("""
      module Host(output core_commit0_valid_w, output core_mem_idle_w,
                  output core_mem_retire_quiet_w);
        Execute u_execute_backend (
          .core_commit0_valid_w(core_commit0_valid_w),
          .core_mem_idle_w(core_mem_idle_w),
          .core_mem_retire_quiet_w(core_mem_retire_quiet_w)
        );
      endmodule
    """)
    execute_map = {
        "core_commit0_valid_w": "core_commit0_valid_w",
        "core_mem_idle_w": "core_mem_idle_w",
        "core_mem_retire_quiet_w": "core_mem_retire_quiet_w",
    }
    execute_ok, _ = exact_instance_connection(
        module_body(fence_execute, "Host") or "", "Execute", execute_map,
        "u_execute_backend",
    )
    execute_mutations_killed = True
    for port, signal in execute_map.items():
        mutated = (module_body(fence_execute, "Host") or "").replace(
            f".{port}({signal})", f".{port}(dummy_w)"
        )
        mutated_ok, _ = exact_instance_connection(
            mutated, "Execute", execute_map, "u_execute_backend"
        )
        execute_mutations_killed = execute_mutations_killed and not mutated_ok
    checks.append((
        "fencei-execute-producer-map-killed",
        execute_ok and execute_mutations_killed,
    ))
    fence_exclusive_killed = True
    for port, signal in execute_map.items():
        requirement = {
            "child": "Execute",
            "instance": "u_execute_backend",
            "port": port,
            "signal": signal,
        }
        mutated = (module_body(fence_execute, "Host") or "").replace(
            "endmodule", f"assign {signal} = 1'b0; endmodule"
        )
        fence_exclusive_killed = fence_exclusive_killed and bool(
            exclusive_instance_output_errors(mutated, requirement)
        )
    checks.append((
        "fencei-exclusive-output-local-driver-killed",
        execute_ok and fence_exclusive_killed,
    ))
    nested_fence_override = (
        module_body(fence_execute, "Host") or ""
    ).replace(
        "endmodule",
        "always @* begin {other_q, {core_mem_idle_w}} = bad_w; end endmodule",
    )
    checks.append((
        "nested-concat-exclusive-output-writer-killed",
        bool(exclusive_instance_output_errors(
            nested_fence_override,
            {
                "child": "Execute",
                "instance": "u_execute_backend",
                "port": "core_mem_idle_w",
                "signal": "core_mem_idle_w",
            },
        )),
    ))

    payload_requirement = {
        "signal": "context_payload_o",
        "source": "context_prepare_identity_i",
        "msb": "7",
        "lsb": "0",
    }
    payload_good = code_only("""
      assign context_payload_o[7:0] = context_prepare_identity_i;
      assign context_payload_o[255:8] = context_other_fields_i;
    """)
    payload_good_errors = exact_payload_slice_errors(
        payload_good, payload_requirement, {}
    )
    checks.append((
        "context-payload-identity-exact-nonoverlap-accepted",
        not payload_good_errors,
    ))
    payload_wrong_slice = payload_good.replace(
        "context_payload_o[7:0]", "context_payload_o[8:1]"
    )
    checks.append((
        "context-payload-identity-wrong-slice-killed",
        bool(exact_payload_slice_errors(
            payload_wrong_slice, payload_requirement, {}
        )),
    ))
    payload_shifted = payload_good.replace(
        "context_prepare_identity_i;", "context_prepare_identity_i << 1;"
    )
    checks.append((
        "context-payload-identity-shifted-source-killed",
        bool(exact_payload_slice_errors(
            payload_shifted, payload_requirement, {}
        )),
    ))
    payload_whole_bus = payload_good + code_only(
        "assign context_payload_o = 256'b0;"
    )
    checks.append((
        "context-payload-identity-whole-bus-writer-killed",
        bool(exact_payload_slice_errors(
            payload_whole_bus, payload_requirement, {}
        )),
    ))
    payload_overlap = payload_good + code_only(
        "assign context_payload_o[3:2] = 2'b0;"
    )
    checks.append((
        "context-payload-identity-overlap-writer-killed",
        bool(exact_payload_slice_errors(
            payload_overlap, payload_requirement, {}
        )),
    ))
    payload_dead_generate = code_only("""
      generate if (0) begin : g_dead
        assign context_payload_o[7:0] = context_prepare_identity_i;
      end endgenerate
    """)
    checks.append((
        "dead-generate-payload-slice-writer-killed",
        bool(exact_payload_slice_errors(
            payload_dead_generate, payload_requirement, {}
        )),
    ))
    payload_named_generate = code_only("""
      generate begin : g_shadow
        assign context_payload_o[7:0] = context_prepare_identity_i;
      end endgenerate
    """)
    checks.append((
        "named-generate-shadow-payload-writer-killed",
        bool(exact_payload_slice_errors(
            payload_named_generate, payload_requirement, {}
        )),
    ))
    payload_procedural_continuous = code_only("""
      initial begin
        assign context_payload_o[7:0] = context_prepare_identity_i;
      end
    """)
    checks.append((
        "procedural-continuous-payload-writer-killed",
        bool(exact_payload_slice_errors(
            payload_procedural_continuous, payload_requirement, {}
        )),
    ))
    payload_nested_concat = payload_good + code_only("""
      always @* begin
        {other_q, {context_payload_o[3:2]}} = bad_w;
      end
    """)
    checks.append((
        "nested-concat-payload-writer-killed",
        bool(exact_payload_slice_errors(
            payload_nested_concat, payload_requirement, {}
        )),
    ))

    squash_leaf_host = code_only("""
      module Host(input valid_i, input [7:0] identity_i,
                  output sq_done_w, output owner_done_w);
        StoreQueue u_store_queue (
          .context_squash_valid_i(valid_i),
          .context_squash_identity_i(identity_i),
          .context_squash_done_o(sq_done_w)
        );
        OwnerTracker u_mem_owner_tracker (
          .context_squash_valid_i(valid_i),
          .context_squash_identity_i(identity_i),
          .context_squash_done_o(owner_done_w)
        );
      endmodule
    """)
    squash_host_body = module_body(squash_leaf_host, "Host") or ""
    leaf_map = {
        "context_squash_valid_i": "valid_i",
        "context_squash_identity_i": "identity_i",
    }
    sq_leaf_ok, _ = exact_instance_connection(
        squash_host_body, "StoreQueue", {**leaf_map, "context_squash_done_o": "sq_done_w"},
        "u_store_queue",
    )
    owner_leaf_ok, _ = exact_instance_connection(
        squash_host_body, "OwnerTracker",
        {**leaf_map, "context_squash_done_o": "owner_done_w"},
        "u_mem_owner_tracker",
    )
    sq_leaf_bad, _ = exact_instance_connection(
        squash_host_body.replace(
            ".context_squash_done_o(sq_done_w)",
            ".context_squash_done_o(owner_done_w)",
        ),
        "StoreQueue", {**leaf_map, "context_squash_done_o": "sq_done_w"},
        "u_store_queue",
    )
    owner_leaf_bad, _ = exact_instance_connection(
        squash_host_body.replace(
            ".context_squash_done_o(owner_done_w)",
            ".context_squash_done_o(sq_done_w)",
        ),
        "OwnerTracker", {**leaf_map, "context_squash_done_o": "owner_done_w"},
        "u_mem_owner_tracker",
    )
    checks.append((
        "memory-squash-true-leaf-maps-killed",
        sq_leaf_ok and owner_leaf_ok and not sq_leaf_bad and not owner_leaf_bad,
    ))
    squash_exclusive_requirement = {
        "child": "StoreQueue",
        "instance": "u_store_queue",
        "port": "context_squash_done_o",
        "signal": "sq_done_w",
    }
    checks.append((
        "memory-squash-extra-host-done-driver-killed",
        bool(exclusive_instance_output_errors(
            squash_host_body.replace(
                "endmodule", "assign sq_done_w = 1'b1; endmodule"
            ),
            squash_exclusive_requirement,
        )),
    ))

    leaf_done_requirement = {
        "target": "context_squash_done_o",
        "sources": [
            "context_squash_ack_q", "context_squash_valid_i",
            "context_squash_identity_q", "context_squash_identity_i",
        ],
        "exact_expression": (
            "context_squash_ack_q && !context_squash_valid_i && "
            "(context_squash_identity_q == context_squash_identity_i)"
        ),
    }
    leaf_done_good = code_only(
        "assign context_squash_done_o = context_squash_ack_q && "
        "!context_squash_valid_i && "
        "(context_squash_identity_q == context_squash_identity_i);"
    )
    leaf_done_constant = code_only(
        "assign context_squash_done_o = 1'b1;"
    )
    checks.append((
        "memory-squash-leaf-constant-done-killed",
        not boolean_requirement_errors(leaf_done_good, leaf_done_requirement)
        and bool(boolean_requirement_errors(
            leaf_done_constant, leaf_done_requirement
        )),
    ))
    leaf_done_echo = code_only(
        "assign context_squash_done_o = context_squash_valid_i && "
        "(context_squash_identity_q == context_squash_identity_i);"
    )
    checks.append((
        "memory-squash-leaf-request-echo-done-killed",
        bool(boolean_requirement_errors(leaf_done_echo, leaf_done_requirement)),
    ))

    squash_seen_good = code_only("""
      assign mem_context_sq_done_seen_next_w =
          (mem_context_sq_done_seen_q && !mem_context_squash_valid_i) ||
          sq_context_squash_done_w;
      assign mem_context_owner_done_seen_next_w =
          (mem_context_owner_done_seen_q && !mem_context_squash_valid_i) ||
          owner_context_squash_done_w;
      assign mem_context_squash_all_done_w =
          mem_context_sq_done_seen_next_w &&
          mem_context_owner_done_seen_next_w;
      assign mem_context_squash_ack_next_w =
          (mem_context_squash_ack_q && !mem_context_squash_valid_i) ||
          mem_context_squash_all_done_w;
    """)
    squash_seen_requirements = [
        {
            "target": "mem_context_sq_done_seen_next_w",
            "sources": [
                "mem_context_sq_done_seen_q", "mem_context_squash_valid_i",
                "sq_context_squash_done_w",
            ],
            "exact_expression": (
                "(mem_context_sq_done_seen_q && !mem_context_squash_valid_i) || "
                "sq_context_squash_done_w"
            ),
        },
        {
            "target": "mem_context_owner_done_seen_next_w",
            "sources": [
                "mem_context_owner_done_seen_q", "mem_context_squash_valid_i",
                "owner_context_squash_done_w",
            ],
            "exact_expression": (
                "(mem_context_owner_done_seen_q && !mem_context_squash_valid_i) || "
                "owner_context_squash_done_w"
            ),
        },
        {
            "target": "mem_context_squash_all_done_w",
            "sources": [
                "mem_context_sq_done_seen_next_w",
                "mem_context_owner_done_seen_next_w",
            ],
            "exact_expression": (
                "mem_context_sq_done_seen_next_w && "
                "mem_context_owner_done_seen_next_w"
            ),
        },
        {
            "target": "mem_context_squash_ack_next_w",
            "sources": [
                "mem_context_squash_ack_q", "mem_context_squash_valid_i",
                "mem_context_squash_all_done_w",
            ],
            "exact_expression": (
                "(mem_context_squash_ack_q && !mem_context_squash_valid_i) || "
                "mem_context_squash_all_done_w"
            ),
        },
    ]
    squash_seen_good_ok = all(
        not boolean_requirement_errors(squash_seen_good, requirement)
        for requirement in squash_seen_requirements
    )
    squash_seen_bad = squash_seen_good.replace(
        "(mem_context_sq_done_seen_q && !mem_context_squash_valid_i) ||\n"
        "          sq_context_squash_done_w",
        "(mem_context_sq_done_seen_q || sq_context_squash_done_w) &&\n"
        "          !mem_context_squash_valid_i",
    ).replace(
        "mem_context_sq_done_seen_next_w &&\n"
        "          mem_context_owner_done_seen_next_w",
        "sq_context_squash_done_w && owner_context_squash_done_w",
    ).replace(
        "(mem_context_squash_ack_q && !mem_context_squash_valid_i) ||\n"
        "          mem_context_squash_all_done_w",
        "(mem_context_squash_ack_q || mem_context_squash_all_done_w) &&\n"
        "          !mem_context_squash_valid_i",
    )
    checks.append((
        "memory-squash-set-dominant-seen-formulas-locked",
        squash_seen_good_ok and any(
            boolean_requirement_errors(squash_seen_bad, requirement)
            for requirement in squash_seen_requirements
        ),
    ))

    def squash_seen_step(
        state: tuple[bool, bool, bool], request: bool,
        sq_done: bool, owner_done: bool,
    ) -> tuple[bool, bool, bool]:
        sq_seen, owner_seen, ack = state
        sq_next = (sq_seen and not request) or sq_done
        owner_next = (owner_seen and not request) or owner_done
        all_done = sq_next and owner_next
        ack_next = (ack and not request) or all_done
        return sq_next, owner_next, ack_next

    staggered_state = squash_seen_step((False, False, False), True, True, False)
    staggered_state = squash_seen_step(staggered_state, False, False, True)
    checks.append((
        "memory-squash-staggered-leaf-pulses-retained",
        staggered_state == (True, True, True),
    ))
    dual_done_state = squash_seen_step((False, False, False), True, True, True)
    old_ack_next = (False or (True and True)) and not True
    checks.append((
        "memory-squash-request-cycle-dual-done-retained",
        dual_done_state == (True, True, True) and not old_ack_next,
    ))

    owner_rob_capture_requirement = {
        "register": "rob_idx_q",
        "index": "alloc0_token_o",
        "source": "alloc0_rob_idx_i",
        "guard": "alloc0_fire_w",
        "canonical_ancestors": [
            {"condition": "rst", "arm": "false"},
            {"condition": "alloc0_fire_w", "arm": "true"},
        ],
        "allowed_writes": [
            {
                "index": "i", "source": "{ROB_INDEX_W{1'b0}}",
                "region": "reset",
            },
            {
                "index": "alloc0_token_o", "source": "alloc0_rob_idx_i",
                "region": "nonreset",
            },
        ],
    }
    owner_rob_capture_good = code_only("""
      always @(posedge clk) begin
        if (rst) begin
          rob_idx_q[i] <= {ROB_INDEX_W{1'b0}};
        end else begin
          if (alloc0_fire_w) begin
            rob_idx_q[alloc0_token_o] <= alloc0_rob_idx_i;
          end
        end
      end
    """)
    owner_rob_capture_bad = owner_rob_capture_good.replace(
        "rob_idx_q[alloc0_token_o] <= alloc0_rob_idx_i;",
        "rob_idx_q[alloc0_token_o] <= {ROB_INDEX_W{1'b0}};",
    )
    checks.append((
        "memory-squash-owner-rob-age-capture-killed",
        not guarded_indexed_capture_errors(
            owner_rob_capture_good, owner_rob_capture_requirement
        ) and bool(guarded_indexed_capture_errors(
            owner_rob_capture_bad, owner_rob_capture_requirement
        )),
    ))

    owner_irrevocable_requirement = {
        "register": "irrevocable_q",
        "index": "irrevocable_token_i",
        "source": "1'b1",
        "guard": "irrevocable_fire_w",
        "canonical_ancestors": [
            {"condition": "rst", "arm": "false"},
            {"condition": "irrevocable_fire_w", "arm": "true"},
        ],
        "allowed_writes": [
            {"index": "i", "source": "1'b0", "region": "reset"},
            {
                "index": "alloc0_token_o", "source": "1'b0",
                "region": "nonreset",
            },
            {
                "index": "irrevocable_token_i", "source": "1'b1",
                "region": "nonreset",
            },
        ],
    }
    owner_irrevocable_good = code_only("""
      always @(posedge clk) begin
        if (rst) begin
          irrevocable_q[i] <= 1'b0;
        end else begin
          if (alloc0_fire_w) begin
            irrevocable_q[alloc0_token_o] <= 1'b0;
          end
          if (irrevocable_fire_w) begin
            irrevocable_q[irrevocable_token_i] <= 1'b1;
          end
        end
      end
    """)
    owner_irrevocable_bad = owner_irrevocable_good.replace(
        "irrevocable_q[irrevocable_token_i] <= 1'b1;",
        "irrevocable_q[irrevocable_token_i] <= 1'b0;",
    )
    checks.append((
        "memory-squash-owner-irrevocable-provenance-killed",
        not guarded_indexed_capture_errors(
            owner_irrevocable_good, owner_irrevocable_requirement
        ) and bool(guarded_indexed_capture_errors(
            owner_irrevocable_bad, owner_irrevocable_requirement
        )),
    ))

    leaf_age_good = code_only("""
      assign context_squash_age_scan_done_w =
          (|live_q) && (|kind_q) && (|rob_idx_q) && (|irrevocable_q) &&
          rob_head_idx_i && (|context_squash_identity_i);
    """)
    leaf_age_graph = assignment_graph(leaf_age_good, include_sequential=False)
    leaf_age_sources = [
        "live_q", "kind_q", "rob_idx_q", "irrevocable_q", "rob_head_idx_i",
        "context_squash_identity_i",
    ]
    leaf_age_bad_graph = assignment_graph(
        code_only("assign context_squash_age_scan_done_w = 1'b1;"),
        include_sequential=False,
    )
    checks.append((
        "memory-squash-leaf-age-provenance-killed",
        all(depends_on(
            leaf_age_graph, "context_squash_age_scan_done_w", source
        ) for source in leaf_age_sources)
        and any(not depends_on(
            leaf_age_bad_graph, "context_squash_age_scan_done_w", source
        ) for source in leaf_age_sources),
    ))
    dead_leaf_age = code_only("""
      generate if (0) begin : g_dead
        assign context_squash_age_scan_done_w =
            (|live_q) && (|kind_q) && (|rob_idx_q) && (|irrevocable_q) &&
            rob_head_idx_i && (|context_squash_identity_i);
      end endgenerate
      assign context_squash_age_scan_done_w = 1'b1;
    """)
    dead_leaf_age_graph = assignment_graph(
        dead_leaf_age, include_sequential=False
    )
    dead_leaf_age_expressions = assignment_expressions(
        dead_leaf_age, include_sequential=False
    )
    checks.append((
        "dead-generate-age-provenance-killed",
        len(dead_leaf_age_expressions.get(
            "context_squash_age_scan_done_w", []
        )) == 1
        and all(not depends_on(
            dead_leaf_age_graph, "context_squash_age_scan_done_w", source
        ) for source in leaf_age_sources),
    ))
    leaf_age_initializer = leaf_age_good.replace(
        "assign context_squash_age_scan_done_w =",
        "logic context_squash_age_scan_done_w =",
    )
    checks.append((
        "age-provenance-variable-initializer-killed",
        bool(exact_combinational_driver_errors(
            leaf_age_initializer, "context_squash_age_scan_done_w"
        )) and not assignment_expressions(
            leaf_age_initializer, include_sequential=False
        ).get("context_squash_age_scan_done_w"),
    ))
    leaf_age_extra_driver = leaf_age_good + code_only(
        "always_comb context_squash_age_scan_done_w = 1'b1;"
    )
    checks.append((
        "age-provenance-extra-driver-killed",
        bool(exact_combinational_driver_errors(
            leaf_age_extra_driver, "context_squash_age_scan_done_w"
        )),
    ))
    named_generate_leaf_age = code_only("""
      generate begin : g_shadow
        wire context_squash_age_scan_done_w =
            (|live_q) && (|kind_q) && (|rob_idx_q) && (|irrevocable_q) &&
            rob_head_idx_i && (|context_squash_identity_i);
      end endgenerate
    """)
    checks.append((
        "named-generate-shadow-age-provenance-killed",
        bool(exact_combinational_driver_errors(
            named_generate_leaf_age, "context_squash_age_scan_done_w"
        )),
    ))

    duplicate_next = assignment_expressions(code_only("""
      assign state_next_w = source_a;
      assign state_next_w = source_b;
    """), include_sequential=False)
    checks.append((
        "multiple-combinational-next-drivers-killed",
        len(duplicate_next.get("state_next_w", [])) != 1,
    ))

    manifest_fixture = json.loads(DEFAULT_MANIFEST.read_text(encoding="utf-8"))
    canonical_macro_errors = macro_contract_errors(
        manifest_fixture, dict(EXPECTED_MACRO_DEFINITIONS)
    )
    duplicate_cause_definitions = dict(EXPECTED_MACRO_DEFINITIONS)
    duplicate_cause_definitions["OOO_CONTEXT_CAUSE_XRET"] = \
        duplicate_cause_definitions["OOO_CONTEXT_CAUSE_TRAP"]
    wrong_mask_definitions = dict(EXPECTED_MACRO_DEFINITIONS)
    wrong_mask_definitions["OOO_CONTEXT_ITLB_CAUSE_MASK"] = "7'b1111111"
    overlapping_layout_definitions = dict(EXPECTED_MACRO_DEFINITIONS)
    overlapping_layout_definitions["OOO_CONTEXT_OWNER_LSB"] = "7"
    overlapping_layout_definitions["OOO_CONTEXT_OWNER_MSB"] = "9"
    checks.append((
        "concrete-macro-layout-and-cause-values-locked",
        not canonical_macro_errors
        and bool(macro_contract_errors(
            manifest_fixture, duplicate_cause_definitions
        ))
        and bool(macro_contract_errors(manifest_fixture, wrong_mask_definitions))
        and bool(macro_contract_errors(
            manifest_fixture, overlapping_layout_definitions
        )),
    ))

    conditional_requirement = {
        "target": "critical_w",
        "sources": ["source_a_w", "source_b_w"],
        "exact_expression": "source_a_w && source_b_w",
    }
    conditional_source = """
      module ConditionalHost(input source_a_w, input source_b_w, output reg critical_w);
      `ifdef NEVER_DEFINED
        assign critical_w = source_a_w && source_b_w;
      `else
        always @* critical_w = 1'b1;
      `endif
      endmodule
    """
    with tempfile.TemporaryDirectory(prefix="q2-checker-selftest-") as temp_dir:
        conditional_path = Path(temp_dir) / "conditional.v"
        conditional_path.write_text(conditional_source, encoding="utf-8")
        active_source, _ = preprocess_verilog_path(conditional_path, REPO_ROOT)
    raw_conditional_body = module_body(
        code_only(conditional_source), "ConditionalHost"
    ) or ""
    active_conditional_body = module_body(
        code_only(active_source or ""), "ConditionalHost"
    ) or ""
    checks.append((
        "inactive-canonical-active-constant-killed",
        not boolean_requirement_errors(
            raw_conditional_body, conditional_requirement
        ) and bool(boolean_requirement_errors(
            active_conditional_body, conditional_requirement
        )),
    ))

    dual_variant_sources = [
        (
            "release-canonical-assert-mutated-killed",
            """
              module VariantHost(input source_a_w, input source_b_w, output critical_w);
              `ifdef OOO_ASSERT
                assign critical_w = 1'b0;
              `else
                assign critical_w = source_a_w && source_b_w;
              `endif
              endmodule
            """,
            "release",
        ),
        (
            "assert-canonical-release-mutated-killed",
            """
              module VariantHost(input source_a_w, input source_b_w, output critical_w);
              `ifdef OOO_ASSERT
                assign critical_w = source_a_w && source_b_w;
              `else
                assign critical_w = 1'b0;
              `endif
              endmodule
            """,
            "ooo_assert",
        ),
    ]
    for name, source, good_variant in dual_variant_sources:
        with tempfile.TemporaryDirectory(prefix="q2-variant-selftest-") as temp_dir:
            source_path = Path(temp_dir) / "variant.v"
            source_path.write_text(source, encoding="utf-8")
            bodies: dict[str, str] = {}
            for variant, defines in ACTIVE_VARIANTS.items():
                active, _ = preprocess_verilog_path(
                    source_path, REPO_ROOT, defines=defines
                )
                bodies[variant] = module_body(
                    code_only(active or ""), "VariantHost"
                ) or ""
        good_errors = boolean_requirement_errors(
            bodies[good_variant], conditional_requirement
        )
        bad_variant = next(
            variant for variant in ACTIVE_VARIANTS if variant != good_variant
        )
        bad_errors = boolean_requirement_errors(
            bodies[bad_variant], conditional_requirement
        )
        checks.append((name, not good_errors and bool(bad_errors)))

    generate_cases = [
        (
            "dead-explicit-generate-instance-killed",
            "generate if (0) begin : g_dead Child u_child(); end endgenerate",
            False,
            True,
        ),
        (
            "dead-implicit-generate-instance-killed",
            "if (0) begin : g_dead Child u_child(); end",
            False,
            True,
        ),
        (
            "named-generate-local-producer-map-killed",
            "generate begin : g_shadow Child u_child(); end endgenerate",
            False,
            False,
        ),
    ]
    for name, generate_body, expect_textual, expect_elaboration_error in generate_cases:
        with tempfile.TemporaryDirectory(prefix="q2-elab-selftest-") as temp_dir:
            root = Path(temp_dir)
            (root / "top.v").write_text(
                f"module NpcCoreTop; {generate_body} endmodule\n",
                encoding="utf-8",
            )
            (root / "child.v").write_text(
                "module Child; endmodule\n", encoding="utf-8"
            )
            fixture = {
                "module_files": {
                    "NpcCoreTop": "top.v",
                    "Child": "child.v",
                },
                "instance_connections": [{
                    "host": "NpcCoreTop",
                    "child": "Child",
                    "instance": "u_child",
                    "ports": {},
                }],
            }
            textual_ok, _ = exact_instance_connection(
                code_only((root / "top.v").read_text(encoding="utf-8")),
                "Child",
                {},
                "u_child",
            )
            elaboration_errors = elaborated_instance_errors(
                fixture, root, ()
            )
        checks.append((
            name,
            textual_ok == expect_textual
            and bool(elaboration_errors) == expect_elaboration_error,
        ))

    runner_text = (RUN_DIR / "run-s2-q2-live-epoch-readiness.sh").read_text(
        encoding="utf-8"
    )
    runner_order = [
        runner_text.find('sources.pre.sha256"'),
        runner_text.find('python3 "${CHECKER}" > "${EVIDENCE_DIR}/readiness.log"'),
        runner_text.find('sources.post.sha256"'),
        runner_text.find('cmp -s --'),
        runner_text.find('} > "${COMPLETE_MARKER}"'),
    ]
    checks.append((
        "runner-pre-post-source-snapshot-locked",
        all(position >= 0 for position in runner_order)
        and runner_order == sorted(runner_order)
        and runner_text.find('rm -f -- "${COMPLETE_MARKER}"') < runner_order[0],
    ))

    with tempfile.TemporaryDirectory(prefix="q2-elab-missing-selftest-") as temp_dir:
        root = Path(temp_dir)
        (root / "top.v").write_text(
            "module NpcCoreTop; Child u_child(); endmodule\n",
            encoding="utf-8",
        )
        missing_fixture = {
            "module_files": {
                "NpcCoreTop": "top.v",
                "Child": "missing-child.v",
            },
            "instance_connections": [{
                "host": "NpcCoreTop",
                "child": "Child",
                "instance": "u_child",
                "ports": {},
            }],
        }
        missing_errors = elaborated_instance_errors(missing_fixture, root, ())
    checks.append((
        "missing-critical-child-definition-fails-closed",
        bool(missing_errors),
    ))

    actual_inventory = [name for name, _ in checks]
    if actual_inventory != EXPECTED_SELF_TEST_INVENTORY:
        print("[S2-Q2-CHECKER-SELFTEST][FAIL] frozen self-test inventory drift")
        return 1
    for name, passed in checks:
        marker = "PASS" if passed else "FAIL"
        print(f"[S2-Q2-CHECKER-SELFTEST][{marker}] {name}")
    if not all(passed for _, passed in checks):
        return 1
    print(f"[S2-Q2-CHECKER-SELFTEST][PASS] mutations={len(checks)}")
    return 0


def run_active_variant_aggregate(
    manifest_path: Path, repo_root: Path, manifest: dict[str, Any]
) -> int:
    """Run every hardcoded active build variant through the full checker."""
    contract_errors = validate_manifest(manifest)
    if contract_errors:
        for error in contract_errors:
            print(f"[S2-Q2-CONTRACT][RED] {error}")
        print(f"[S2-Q2-CONTRACT][FAIL] unresolved={len(contract_errors)}")
        return 2
    print("[S2-Q2-CONTRACT][PASS] schema/phase/scope/IFU/ingress contract is complete")

    combined: list[str] = []
    infrastructure_failures: list[str] = []
    return_codes: list[int] = []
    for variant in ACTIVE_VARIANTS:
        command = [
            sys.executable,
            str(Path(__file__).resolve()),
            "--manifest",
            str(manifest_path.resolve()),
            "--repo-root",
            str(repo_root.resolve()),
            "--single-variant",
            variant,
        ]
        try:
            result = subprocess.run(
                command,
                cwd=repo_root,
                check=False,
                capture_output=True,
                text=True,
                timeout=180,
            )
        except (OSError, subprocess.TimeoutExpired) as exc:
            infrastructure_failures.append(
                f"[variant={variant}] checker execution failed: {exc}"
            )
            return_codes.append(2)
            continue
        return_codes.append(result.returncode)
        for line in result.stdout.splitlines():
            marker = "[S2-Q2-READINESS][RED] "
            if line.startswith(marker):
                combined.append(
                    f"[variant={variant}] {line[len(marker):]}"
                )
            elif line.startswith("[S2-Q2-CONTRACT][RED]"):
                infrastructure_failures.append(f"[variant={variant}] {line}")
        if result.returncode not in {0, 1, 2}:
            detail = result.stderr.strip().splitlines()
            infrastructure_failures.append(
                f"[variant={variant}] unexpected checker rc={result.returncode}"
                + (f": {detail[-1]}" if detail else "")
            )
            return_codes[-1] = 2
        elif result.returncode == 1 and not any(
            error.startswith(f"[variant={variant}]") for error in combined
        ):
            infrastructure_failures.append(
                f"[variant={variant}] readiness failed without RED diagnostics"
            )
            return_codes[-1] = 2
        elif result.returncode == 2 and not any(
            error.startswith(f"[variant={variant}]")
            for error in infrastructure_failures
        ):
            infrastructure_failures.append(
                f"[variant={variant}] contract/infrastructure check failed"
            )

    for error in infrastructure_failures:
        print(f"[S2-Q2-READINESS][RED] {error}")
    for error in combined:
        print(f"[S2-Q2-READINESS][RED] {error}")
    print(
        "[S2-Q2-READINESS][SCOPE] mem0-only; issue1 memory disabled; "
        "release+OOO_ASSERT structural check is necessary-only"
    )
    if infrastructure_failures or any(code == 2 for code in return_codes):
        print(
            "[S2-Q2-READINESS][FAIL] "
            f"unresolved={len(infrastructure_failures) + len(combined)}"
        )
        return 2
    if combined or any(code == 1 for code in return_codes):
        print(f"[S2-Q2-READINESS][FAIL] unresolved={len(combined)}")
        return 1
    print(
        "[S2-Q2-READINESS][PASS] both active variants satisfy exact structural "
        "requirements; semantic RTL gates still required"
    )
    return 0


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST)
    parser.add_argument("--repo-root", type=Path, default=REPO_ROOT)
    parser.add_argument("--self-test", action="store_true")
    parser.add_argument("--print-locks", action="store_true")
    parser.add_argument(
        "--single-variant",
        choices=tuple(ACTIVE_VARIANTS),
        help=argparse.SUPPRESS,
    )
    args = parser.parse_args()
    if args.self_test:
        return run_self_test()

    manifest = json.loads(args.manifest.read_text(encoding="utf-8"))
    if args.print_locks:
        print(f"contract_lock_sha256={contract_lock_sha256(manifest)}")
        print(f"evidence_baseline_sha256={evidence_baseline_sha256(manifest)}")
        return 0
    if args.single_variant is None:
        return run_active_variant_aggregate(args.manifest, args.repo_root, manifest)
    contract_errors = validate_manifest(manifest)
    if contract_errors:
        for error in contract_errors:
            print(f"[S2-Q2-CONTRACT][RED] {error}")
        print(f"[S2-Q2-CONTRACT][FAIL] unresolved={len(contract_errors)}")
        return 2
    print("[S2-Q2-CONTRACT][PASS] schema/phase/scope/IFU/ingress contract is complete")

    errors: list[str] = []
    macro_path = args.repo_root / "npc/rv64/vsrc/include/define.v"
    if macro_path.is_file():
        macro_text = macro_path.read_text(encoding="utf-8")
        macro_definitions = object_macro_definitions(macro_text)
        errors.extend(macro_contract_errors(manifest, macro_definitions))
    else:
        macro_definitions = {}
        errors.append("missing macro source npc/rv64/vsrc/include/define.v")

    module_code: dict[str, str] = {}
    for module, relative in manifest["module_files"].items():
        path = args.repo_root / relative
        if not path.is_file():
            errors.append(f"missing source for {module}: {relative}")
            module_code[module] = ""
            continue
        preprocessed, detail = preprocess_verilog_path(
            path,
            args.repo_root,
            defines=ACTIVE_VARIANTS[args.single_variant],
        )
        if preprocessed is None:
            errors.append(f"{module} active-source preprocessing failed: {detail}")
            module_code[module] = ""
            continue
        text = code_only(preprocessed)
        body = module_body(text, module)
        if body is None:
            errors.append(f"source does not define expected module {module}: {relative}")
            module_code[module] = ""
        else:
            module_code[module] = body

    errors.extend(elaborated_instance_errors(
        manifest,
        args.repo_root,
        ACTIVE_VARIANTS[args.single_variant],
    ))

    for module, signal in sorted(manifest_critical_symbols(manifest)):
        declaration_errors = module_symbol_declaration_errors(
            module_code.get(module, ""), signal
        )
        if declaration_errors:
            errors.append(
                f"{module}.{signal} declaration scope invalid: "
                + "; ".join(declaration_errors)
            )

    control_policy = manifest["canonical_control_source_policy"]
    for module in control_policy["modules"]:
        for signal in control_policy["signals"]:
            control_errors = canonical_control_source_errors(
                module_code.get(module, ""), signal, module_code
            )
            if control_errors:
                errors.append(
                    f"{module}.{signal} canonical control source invalid: "
                    + "; ".join(control_errors)
                )

    for module, signal in sorted(manifest_unique_combinational_targets(manifest)):
        driver_errors = exact_combinational_driver_errors(
            module_code.get(module, ""), signal, module_code
        )
        if driver_errors:
            errors.append(
                f"{module}.{signal} combinational driver invalid: "
                + "; ".join(driver_errors)
            )

    for item in manifest["required_ports"]:
        body = module_code.get(item["module"], "")
        if not declared_port(body, item["direction"], item["port"]):
            errors.append(
                f"{item['module']} lacks {item['direction']} port {item['port']}"
            )

    for item in manifest["required_port_widths"]:
        body = module_code.get(item["module"], "")
        expanded_width = expand_object_macros(
            item["width_token"], macro_definitions
        )
        if not declared_port_width(body, item["port"], expanded_width):
            errors.append(
                f"{item['module']}.{item['port']} lacks width token {item['width_token']}"
            )

    for item in manifest["required_signal_widths"]:
        body = module_code.get(item["module"], "")
        expanded_width = expand_object_macros(
            item["width_token"], macro_definitions
        )
        if not declared_signal_width(body, item["signal"], expanded_width):
            errors.append(
                f"{item['module']}.{item['signal']} lacks width token {item['width_token']}"
            )

    wrapper_bundle = manifest["wrapper_bundle"]
    for module in wrapper_bundle["modules"]:
        body = module_code.get(module, "")
        for port in wrapper_bundle["inputs"]:
            if not declared_port(body, "input", port):
                errors.append(f"{module} lacks wrapper input port {port}")
        for port in wrapper_bundle["outputs"]:
            if not declared_port(body, "output", port):
                errors.append(f"{module} lacks wrapper output port {port}")

    wrapper_width_bundle = manifest["wrapper_width_bundle"]
    for module in wrapper_width_bundle["modules"]:
        body = module_code.get(module, "")
        for port, width_token in wrapper_width_bundle["ports"].items():
            expanded_width = expand_object_macros(width_token, macro_definitions)
            if not declared_port_width(body, port, expanded_width):
                errors.append(
                    f"{module}.{port} lacks wrapper width token {width_token}"
                )

    fencei_wrapper_bundle = manifest["fencei_wrapper_bundle"]
    for module in fencei_wrapper_bundle["modules"]:
        body = module_code.get(module, "")
        port = fencei_wrapper_bundle["input"]
        if not declared_port(body, "input", port):
            errors.append(f"{module} lacks FENCE.I wrapper input port {port}")

    for item in manifest["instance_connections"]:
        expected = dict(item.get("ports", {}))
        for port in item.get("same_name_ports", []):
            expected[port] = port
        ok, detail = exact_instance_connection(
            module_code.get(item["host"], ""), item["child"], expected,
            item.get("instance"),
        )
        if not ok:
            errors.append(f"{item['host']}->{item['child']}: {detail}")

    for item in manifest["exclusive_instance_outputs"]:
        producer_errors = exclusive_instance_output_errors(
            module_code.get(item["host"], ""), item
        )
        if producer_errors:
            errors.append(
                f"{item['host']}.{item['signal']} producer is not exclusive: "
                + "; ".join(producer_errors)
            )

    for item in manifest["instance_parameters"]:
        expanded_parameters = {
            name: expand_object_macros(value, macro_definitions)
            for name, value in item["parameters"].items()
        }
        ok, detail = exact_instance_parameters(
            module_code.get(item["host"], ""),
            item["child"],
            expanded_parameters,
            item.get("instance"),
        )
        if not ok:
            errors.append(f"{item['host']}->{item['child']} parameters: {detail}")

    combinational_graphs = {
        module: assignment_graph(body, include_sequential=False)
        for module, body in module_code.items()
    }
    for item in manifest["signal_dependencies"]:
        graph = combinational_graphs.get(item["module"], {})
        missing = [source for source in item["sources"]
                   if not depends_on(graph, item["target"], source)]
        if missing:
            errors.append(
                f"{item['module']}.{item['target']} lacks dependency on "
                + ", ".join(missing)
            )

    for item in manifest["forbidden_dependencies"]:
        graph = combinational_graphs.get(item["module"], {})
        if depends_on(graph, item["target"], item["source"]):
            errors.append(
                f"FORBIDDEN-COMB: {item['module']}.{item['source']} reaches {item['target']}"
            )

    direct_expressions = {
        module: assignment_expressions(body, include_sequential=False)
        for module, body in module_code.items()
    }
    for item in manifest["forbidden_direct_dependencies"]:
        rhs_list = direct_expressions.get(item["module"], {}).get(
            item["target"], []
        )
        if any(re.search(rf"\b{re.escape(item['source'])}\b", rhs)
               for rhs in rhs_list):
            errors.append(
                f"FORBIDDEN-DIRECT: {item['module']}.{item['source']} directly "
                f"drives {item['target']}"
            )

    for item in manifest["boolean_requirements"]:
        shape_errors = boolean_requirement_errors(
            module_code.get(item["module"], ""),
            expanded_requirement(item, macro_definitions),
        )
        if shape_errors:
            errors.append(
                f"{item['module']}.{item['target']} boolean shape invalid: "
                + "; ".join(shape_errors)
            )

    for item in manifest["epoch_named_connections"]:
        body = module_code.get(item["module"], "")
        pattern = rf"\.{re.escape(item['port'])}\s*\(\s*{re.escape(item['signal'])}\s*\)"
        if re.search(pattern, body) is None:
            errors.append(
                f"{item['module']} lacks exact dynamic epoch connection "
                f".{item['port']}({item['signal']})"
            )

    for item in manifest["exact_next_expressions"]:
        requirement = {
            "target": item["target"],
            "sources": item["sources"],
            "exact_expression": item["exact_expression"],
        }
        shape_errors = boolean_requirement_errors(
            module_code.get(item["module"], ""),
            expanded_requirement(requirement, macro_definitions),
        )
        if shape_errors:
            errors.append(
                f"{item['module']}.{item['target']} exact next-state invalid: "
                + "; ".join(shape_errors)
            )

    for item in manifest["epoch_register_captures"]:
        requirement = {
            "target": item["next_signal"],
            "sources": [item["register"], item["capture_fire"], item["signal"]],
            "exact_expression": item["exact_expression"],
        }
        shape_errors = boolean_requirement_errors(
            module_code.get(item["module"], ""),
            expanded_requirement(requirement, macro_definitions),
        )
        if shape_errors:
            errors.append(
                f"{item['module']}.{item['register']} valid epoch capture invalid: "
                + "; ".join(shape_errors)
            )

    for item in manifest["guarded_indexed_captures"]:
        capture_errors = guarded_indexed_capture_errors(
            module_code.get(item["module"], ""), item,
            manifest["canonical_reset_predicate"],
        )
        if capture_errors:
            errors.append(
                f"{item['module']}.{item['register']} indexed provenance invalid: "
                + "; ".join(capture_errors)
            )

    for item in manifest["exact_payload_slices"]:
        slice_errors = exact_payload_slice_errors(
            module_code.get(item["module"], ""), item, macro_definitions
        )
        if slice_errors:
            errors.append(
                f"{item['module']}.{item['signal']} payload slice invalid: "
                + "; ".join(slice_errors)
            )

    for item in manifest["unique_next_writes"]:
        ok, detail = context_register_uses_unique_next(
            module_code.get(item["module"], ""),
            item["register"],
            item["next_signal"],
            allow_indexed=bool(item.get("allow_indexed", False)),
            reset_predicate=manifest["canonical_reset_predicate"],
        )
        if not ok:
            errors.append(
                f"{item['module']}.{item['register']} writer is not unique-next: {detail}"
            )

    for group in manifest["next_signal_source_groups"]:
        graph = combinational_graphs.get(group["module"], {})
        for next_signal in group["next_signals"]:
            missing = [source for source in group["sources"]
                       if not depends_on(graph, next_signal, source)]
            if missing:
                errors.append(
                    f"{group['module']}.{next_signal} lacks apply/select sources "
                    + ", ".join(missing)
                )

    backend = module_code.get("OooIntBackend", "")
    for port in manifest["forbidden_constant_epoch_ports"]:
        pattern = rf"\.{re.escape(port)}\s*\(\s*MEM_OWNER_EPOCH_BASE\s*\)"
        if re.search(pattern, backend):
            errors.append(f"live valid-owner port still uses constant epoch: {port}")

    for error in errors:
        print(f"[S2-Q2-READINESS][RED] {error}")
    print("[S2-Q2-READINESS][SCOPE] mem0-only; issue1 memory disabled; structural check is necessary-only")
    if errors:
        print(f"[S2-Q2-READINESS][FAIL] unresolved={len(errors)}")
        return 1

    print("[S2-Q2-READINESS][PASS] exact ports/connections/dependencies present; semantic RTL gates still required")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
