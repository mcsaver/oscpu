#!/usr/bin/env python3
"""Deterministic evidence checker for the local RV64 L2 mini-system layer."""

from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import pathlib
import re
import sys
from typing import Any


SCHEMA = "npc-rv64-l2-mini-system-execution-v1"
RTL_IDENTITY_SCHEMA = "npc-rv64-l2-rtl-identity-v1"

CASE_SELECTORS = {
    "privilege": 0x70,
    "sv39": 0x76,
    "timer": 0x74,
    "interrupt": 0x69,
    "atomic-mmio": 0x61,
    "shutdown": 0x64,
    "all": 0x78,
}
CASE_MARKERS = {
    "privilege": "__RV64_L2_CASE_PRIVILEGE__",
    "sv39": "__RV64_L2_CASE_SV39__",
    "timer": "__RV64_L2_CASE_TIMER__",
    "interrupt": "__RV64_L2_CASE_INTERRUPT__",
    "atomic-mmio": "__RV64_L2_CASE_ATOMIC_MMIO__",
    "shutdown": "__RV64_L2_CASE_SHUTDOWN__",
    "all": "__RV64_L2_CASE_ALL__",
}
COMMON_MARKERS = (
    "__RV64_L2_BEGIN__",
    "__RV64_L2_OPENSBI_PASS__",
    "__RV64_L2_M_TO_S_PASS__",
    "__RV64_L2_FDT_PASS__",
    "__RV64_L2_CASE_SELECT__",
)
VM_MARKERS = (
    "__RV64_L2_SV39_PASS__",
    "__RV64_L2_AD_UPDATE_PASS__",
    "__RV64_L2_PERMISSION_RECOVERY_PASS__",
    "__RV64_L2_S_TO_U_PASS__",
    "__RV64_L2_AMO_LRSC_FENCE_PASS__",
    "__RV64_L2_SFENCE_VMA_PASS__",
)
CASE_BODY_MARKERS = {
    "privilege": VM_MARKERS,
    "sv39": VM_MARKERS,
    "timer": ("__RV64_L2_TIMER_IRQ_PASS__",),
    "interrupt": (
        "__RV64_L2_MMIO_PASS__",
        "__RV64_L2_PLIC_UART_IRQ_PASS__",
    ),
    "atomic-mmio": (*VM_MARKERS, "__RV64_L2_MMIO_PASS__"),
    "shutdown": (),
    "all": (
        *VM_MARKERS,
        "__RV64_L2_TIMER_IRQ_PASS__",
        "__RV64_L2_MMIO_PASS__",
        "__RV64_L2_PLIC_UART_IRQ_PASS__",
    ),
}
FINAL_MARKERS = (
    "__RV64_L2_POWERDOWN_ARM__",
    "__RV64_L2_MINI_SYSTEM_PASS__",
)
ALL_KNOWN_MARKERS = set(COMMON_MARKERS) | set(CASE_MARKERS.values())
for _body in CASE_BODY_MARKERS.values():
    ALL_KNOWN_MARKERS.update(_body)
ALL_KNOWN_MARKERS.update(FINAL_MARKERS)

TERMINAL_MARKERS = {
    "syscon_poweroff": "syscon-reset: poweroff requested value=0x00005555",
    "good_trap": "HIT GOOD TRAP",
    "system_reset": "exit via system-reset, code=0",
    "stats_instructions": "total guest instructions = ",
    "stats_cycles": "total guest cycles = ",
}
ANSI_RE = re.compile(r"\x1b\[[0-9;]*[A-Za-z]")
RUN_RESULT_RE = re.compile(
    r"exit via system-reset, code=(?P<code>\d+), "
    r"cycles=(?P<cycles>\d+), commits=(?P<commits>\d+)"
)
TOTAL_INSTRUCTIONS_RE = re.compile(r"total guest instructions = (?P<value>\d+)")
TOTAL_CYCLES_RE = re.compile(r"total guest cycles = (?P<value>\d+)")
UART_TX_RE = re.compile(
    r"uart-trace[^\n]*tx=(?P<ordinal>\d+) cycle=(?P<cycle>\d+) "
    r"commit=(?P<commit>\d+) data=0x(?P<data>[0-9a-fA-F]{2})"
)
UART_RX_RE = re.compile(
    r"uart-rx[^\n]*pop=(?P<ordinal>\d+) cycle=(?P<cycle>\d+) "
    r"commit=(?P<commit>\d+) data=0x(?P<data>[0-9a-fA-F]{2})"
)
IRQ_TRACE_RE = re.compile(
    r"irq-trace[^\n]*event=(?P<ordinal>\d+) cycle=(?P<cycle>\d+) "
    r"commit=(?P<commit>\d+) uart_irq=(?P<uart_irq>[01]) "
    r"plic_irq=(?P<plic_irq>[01])"
)
SYSCON_POWEROFF_RE = re.compile(
    r"syscon-reset: poweroff requested value=0x00005555[^\n]*"
    r"cycle=(?P<cycle>\d+) commit=(?P<commit>\d+)"
)
ASSERTION_RE = re.compile(
    r"\[(?:V[0-9]+[A-Z]?-[^\]]*(?:DISJOINT|HANDOFF|INGRESS-DUP|"
    r"ASSERT[^\]]*FAIL)|S2-G1-TCOLL-INGRESS-DUP)\]|%Error:|"
    r"Assertion failed|RTL assertion|\[[^\]]*ASSERT[^\]]*FAIL",
    re.IGNORECASE,
)


class MiniSystemError(RuntimeError):
    """The bound L2 execution cannot support the requested claim."""


def phases_for_case(case_name: str) -> tuple[str, ...]:
    if case_name not in CASE_SELECTORS:
        raise MiniSystemError(f"unsupported L2 case: {case_name!r}")
    return (
        *COMMON_MARKERS,
        CASE_MARKERS[case_name],
        *CASE_BODY_MARKERS[case_name],
        *FINAL_MARKERS,
    )


def regular_file(path: pathlib.Path) -> pathlib.Path:
    if path.is_symlink() or not path.is_file():
        raise MiniSystemError(f"not a regular non-symlink file: {path}")
    return path


def read_text(path: pathlib.Path) -> str:
    return ANSI_RE.sub("", regular_file(path).read_text(encoding="utf-8", errors="replace"))


def sha256_file(path: pathlib.Path) -> str:
    digest = hashlib.sha256()
    with regular_file(path).open("rb") as stream:
        for block in iter(lambda: stream.read(4 * 1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def read_binding(path: pathlib.Path) -> dict[str, str]:
    result: dict[str, str] = {}
    for number, line in enumerate(read_text(path).splitlines(), start=1):
        if not line or line.startswith("#"):
            continue
        if "=" not in line:
            raise MiniSystemError(f"binding line {number} has no '='")
        key, value = line.split("=", 1)
        if not key or key in result:
            raise MiniSystemError(f"invalid/duplicate binding key: {key!r}")
        result[key] = value
    return result


def require_binding(binding: dict[str, str]) -> None:
    required = {
        "schema": "npc-rv64-l2-mini-system-run-binding-v1",
        "payload_load_addr": "0x80400000",
        "effective_dtb_addr": "0x82300000",
        "opensbi_fw_jump_fdt_addr": "0x82300000",
        "effective_dtb_syscon": "1",
        "OOO_ASSERT": "1",
        "OOO_CSR_QUEUE_HEAD": "1",
        "OOO_TERMINAL_HOLDER_ASSERT": "1",
        "ubuntu2204_full_simulation": "not_launched",
    }
    for key, expected in required.items():
        if binding.get(key) != expected:
            raise MiniSystemError(
                f"binding mismatch {key}: {binding.get(key)!r} != {expected!r}"
            )
    if binding.get("l2_case") not in CASE_SELECTORS:
        raise MiniSystemError("invalid/missing l2_case")
    if not re.fullmatch(r"sha256:[0-9a-f]{64}", binding.get("rtl_design_id", "")):
        raise MiniSystemError("invalid rtl_design_id")
    for key in (
        "simulator_sha256",
        "simulator_source_sha256",
        "layer_source_sha256",
        "payload_elf_sha256",
        "payload_bin_sha256",
        "effective_dtb_sha256",
        "opensbi_fw_sha256",
    ):
        if not re.fullmatch(r"[0-9a-f]{64}", binding.get(key, "")):
            raise MiniSystemError(f"invalid/missing hash: {key}")
    if not binding.get("max_cycles", "").isdigit() or int(binding["max_cycles"]) <= 0:
        raise MiniSystemError("invalid max_cycles")


def exact_single(text: str, marker: str) -> int:
    count = text.count(marker)
    if count != 1:
        raise MiniSystemError(
            f"marker cardinality mismatch {marker!r}: observed {count}"
        )
    return text.index(marker)


def parse_uart_tx(
    npc_text: str, phases: tuple[str, ...]
) -> dict[str, dict[str, int]]:
    entries = [
        {
            "ordinal": int(match.group("ordinal")),
            "cycle": int(match.group("cycle")),
            "commit": int(match.group("commit")),
            "data": int(match.group("data"), 16),
        }
        for match in UART_TX_RE.finditer(npc_text)
    ]
    if not entries:
        raise MiniSystemError("no UART TX phase trace")
    if [entry["ordinal"] for entry in entries] != list(range(1, len(entries) + 1)):
        raise MiniSystemError("UART TX ordinals are not exact/consecutive")
    stream = bytes(entry["data"] for entry in entries)
    result: dict[str, dict[str, int]] = {}
    previous = -1
    for marker in phases:
        encoded = marker.encode("ascii")
        first = stream.find(encoded)
        if first < 0 or first != stream.rfind(encoded) or first <= previous:
            raise MiniSystemError(f"UART TX phase mismatch: {marker}")
        end = first + len(encoded) - 1
        result[marker] = {
            "cycle": entries[end]["cycle"],
            "commit": entries[end]["commit"],
            "tx_ordinal": entries[end]["ordinal"],
        }
        previous = first
    return result


def precedes(left: dict[str, int], right: dict[str, int]) -> bool:
    return left["cycle"] < right["cycle"] and left["commit"] < right["commit"]


def parse_irq_trace(npc_text: str) -> list[dict[str, int]]:
    entries = [
        {
            "ordinal": int(match.group("ordinal")),
            "cycle": int(match.group("cycle")),
            "commit": int(match.group("commit")),
            "uart_irq": int(match.group("uart_irq")),
            "plic_irq": int(match.group("plic_irq")),
        }
        for match in IRQ_TRACE_RE.finditer(npc_text)
    ]
    if entries and [entry["ordinal"] for entry in entries] != list(
        range(1, len(entries) + 1)
    ):
        raise MiniSystemError("IRQ trace ordinal is not exact/consecutive")
    return entries


def parse_execution(
    console_path: pathlib.Path,
    npc_path: pathlib.Path,
    binding_path: pathlib.Path,
) -> dict[str, Any]:
    console = read_text(console_path)
    npc = read_text(npc_path)
    binding = read_binding(binding_path)
    require_binding(binding)
    case_name = binding["l2_case"]
    phases = phases_for_case(case_name)
    combined = console + "\n" + npc
    if "__RV64_L2_FAIL__" in combined:
        raise MiniSystemError("payload emitted an L2 failure marker")
    if "HIT BAD TRAP" in combined or ASSERTION_RE.search(combined):
        raise MiniSystemError("bad-trap or RTL assertion marker observed")

    positions = [exact_single(npc, f"[guest] {marker}") for marker in phases]
    if positions != sorted(positions) or len(positions) != len(set(positions)):
        raise MiniSystemError("console phase order mismatch")
    for marker in sorted(ALL_KNOWN_MARKERS - set(phases)):
        if marker in combined:
            raise MiniSystemError(f"unselected L2 phase marker observed: {marker}")

    terminal_counts = {
        key: console.count(marker) for key, marker in TERMINAL_MARKERS.items()
    }
    if any(count != 1 for count in terminal_counts.values()):
        raise MiniSystemError(f"terminal cardinality mismatch: {terminal_counts}")
    terminal_order = (
        "syscon_poweroff",
        "good_trap",
        "system_reset",
        "stats_instructions",
        "stats_cycles",
    )
    terminal_positions = [console.index(TERMINAL_MARKERS[key]) for key in terminal_order]
    if terminal_positions != sorted(terminal_positions):
        raise MiniSystemError("terminal transaction order mismatch")
    results = list(RUN_RESULT_RE.finditer(console))
    instruction_totals = list(TOTAL_INSTRUCTIONS_RE.finditer(console))
    cycle_totals = list(TOTAL_CYCLES_RE.finditer(console))
    if len(results) != 1 or len(instruction_totals) != 1 or len(cycle_totals) != 1:
        raise MiniSystemError("final statistics/result cardinality mismatch")
    commits = int(results[0].group("commits"))
    cycles = int(results[0].group("cycles"))
    if int(results[0].group("code")) != 0:
        raise MiniSystemError("system-reset exit code is nonzero")
    if int(instruction_totals[0].group("value")) != commits:
        raise MiniSystemError("instruction total does not match final commits")
    if int(cycle_totals[0].group("value")) != cycles:
        raise MiniSystemError("cycle total does not match final cycles")
    if cycles > int(binding["max_cycles"]):
        raise MiniSystemError("execution exceeded max_cycles")

    rx = list(UART_RX_RE.finditer(npc))
    expected_selector = CASE_SELECTORS[case_name]
    if len(rx) != 1 or int(rx[0].group("ordinal")) != 1:
        raise MiniSystemError("L2 selector RX cardinality/ordinal mismatch")
    if int(rx[0].group("data"), 16) != expected_selector:
        raise MiniSystemError("L2 selector RX payload mismatch")
    observations = parse_uart_tx(npc, phases)
    selector_observation = {
        "data": expected_selector,
        "cycle": int(rx[0].group("cycle")),
        "commit": int(rx[0].group("commit")),
    }
    if not (
        precedes(observations["__RV64_L2_CASE_SELECT__"], selector_observation)
        and precedes(selector_observation, observations[CASE_MARKERS[case_name]])
    ):
        raise MiniSystemError(
            "L2 selector RX is not bracketed by CASE_SELECT/case phase"
        )
    irq_entries = parse_irq_trace(npc)
    plic_observations: list[dict[str, int]] = []
    if case_name in ("interrupt", "all"):
        window_start = observations["__RV64_L2_MMIO_PASS__"]
        window_end = observations["__RV64_L2_PLIC_UART_IRQ_PASS__"]
        plic_observations = [
            entry
            for entry in irq_entries
            if entry["uart_irq"] == 1
            and entry["plic_irq"] == 1
            and precedes(window_start, entry)
            and precedes(entry, window_end)
        ]
        if not plic_observations:
            raise MiniSystemError("no UART-to-PLIC assertion in MMIO/PLIC phase window")
    pass_observation = observations["__RV64_L2_MINI_SYSTEM_PASS__"]
    if pass_observation["cycle"] >= cycles or pass_observation["commit"] >= commits:
        raise MiniSystemError("L2 PASS does not precede the terminal transaction")
    syscon_matches = list(SYSCON_POWEROFF_RE.finditer(console))
    if len(syscon_matches) != 1:
        raise MiniSystemError(
            "syscon poweroff cycle/commit observation cardinality mismatch"
        )
    syscon_observation = {
        "cycle": int(syscon_matches[0].group("cycle")),
        "commit": int(syscon_matches[0].group("commit")),
    }
    if not (
        precedes(pass_observation, syscon_observation)
        and syscon_observation["cycle"] <= cycles
        and syscon_observation["commit"] <= commits
    ):
        raise MiniSystemError("L2 PASS/syscon/result counter order mismatch")
    return {
        "schema": SCHEMA,
        "status": "PASS",
        "claim": (
            "L2_MINI_SYSTEM_PASS_CURRENT_IDENTITY"
            if case_name == "all"
            else "L2_MINI_SYSTEM_DIRECTED_CASE_PASS_CURRENT_IDENTITY"
        ),
        "l2_case": case_name,
        "signoff_scope": "full-l2" if case_name == "all" else "directed-case",
        "rtl_design_id": binding["rtl_design_id"],
        "production_rtl_file_count": int(binding["production_rtl_file_count"]),
        "cycles": cycles,
        "commits": commits,
        "cpi": cycles / commits,
        "phase_observations": observations,
        "terminal_counts": terminal_counts,
        "selector_rx": selector_observation,
        "plic_irq_observations": plic_observations,
        "syscon_poweroff_observation": syscon_observation,
        "assertion_failures": 0,
        "console_sha256": sha256_file(console_path),
        "npc_log_sha256": sha256_file(npc_path),
        "binding_sha256": sha256_file(binding_path),
        "non_claims": ["Linux", "Ubuntu userland", "systemd", "virtio rootfs"],
    }


def load_architecture_binding(root: pathlib.Path) -> tuple[str, int]:
    path = root / "npc/rv64/eval/ppa/tools/architecture_hard_gates.py"
    spec = importlib.util.spec_from_file_location("l2_architecture_binding", path)
    if spec is None or spec.loader is None:
        raise MiniSystemError(f"cannot load RTL identity helper: {path}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    digest, files = module.rtl_binding(root)
    return f"sha256:{digest}", len(files)


def atomic_json(path: pathlib.Path, value: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_name(path.name + ".tmp")
    temporary.write_text(
        json.dumps(value, indent=2, ensure_ascii=False, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    temporary.replace(path)


def main() -> int:
    parser = argparse.ArgumentParser()
    commands = parser.add_subparsers(dest="command", required=True)
    identity = commands.add_parser("rtl-identity")
    identity.add_argument("--repo-root", type=pathlib.Path, required=True)
    identity.add_argument("--output", type=pathlib.Path, required=True)
    check = commands.add_parser("check")
    check.add_argument("--console", type=pathlib.Path, required=True)
    check.add_argument("--npc-log", type=pathlib.Path, required=True)
    check.add_argument("--binding", type=pathlib.Path, required=True)
    check.add_argument("--output", type=pathlib.Path, required=True)
    commands.add_parser("self-test")
    args = parser.parse_args()
    try:
        if args.command == "rtl-identity":
            design_id, file_count = load_architecture_binding(args.repo_root.resolve())
            result = {
                "schema": RTL_IDENTITY_SCHEMA,
                "rtl_design_id": design_id,
                "production_rtl_file_count": file_count,
            }
            atomic_json(args.output, result)
            print(f"[RV64-L2-RTL-IDENTITY] {design_id} files={file_count}")
            return 0
        if args.command == "check":
            result = parse_execution(args.console, args.npc_log, args.binding)
            atomic_json(args.output, result)
            print(
                "[RV64-L2-CHECK][PASS] "
                f"case={result['l2_case']} scope={result['signoff_scope']} "
                f"commits={result['commits']} cycles={result['cycles']} "
                f"terminal=5/5 phases={len(result['phase_observations'])}"
            )
            return 0
        if args.command == "self-test":
            if len(CASE_SELECTORS) != 7 or set(CASE_SELECTORS) != set(CASE_BODY_MARKERS):
                raise MiniSystemError("L2 case inventory is inconsistent")
            print("[RV64-L2-CHECK-SELF-TEST][PASS] cases=7 exact-terminal=5")
            return 0
    except (OSError, ValueError, MiniSystemError) as exc:
        print(f"[RV64-L2-CHECK][FAIL] {exc}", file=sys.stderr)
        return 1
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
