#!/usr/bin/env python3
"""Identity and semantic evidence helper for RV64 L3 lightweight Linux.

The shell runner owns build, execution, locks, status and cleanup.  This helper
only reads explicit local artifacts/logs and emits deterministic JSON.
"""

from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import pathlib
import re
import sys
from typing import Any


SCHEMA = "npc-rv64-l3-lightweight-linux-execution-v1"
RTL_IDENTITY_SCHEMA = "npc-rv64-l3-rtl-identity-v1"

COMMON_PHASE_MARKERS = (
    "__RV64_L3_PID1_BEGIN__",
    "__RV64_L3_MOUNTS_PASS__",
    "__RV64_L3_FILES_PASS__",
    "__RV64_L3_CASE_SELECT__",
)

CASE_SELECTORS = {
    "boot": 0x62,
    "mmu": 0x6D,
    "process": 0x70,
    "timer": 0x74,
    "storage": 0x73,
    "atomic": 0x61,
    "interrupt": 0x69,
    "shutdown": 0x64,
    "all": 0x78,
}

CASE_MARKERS = {
    name: f"__RV64_L3_CASE_{name.upper()}__" for name in CASE_SELECTORS
}

CASE_BODY_MARKERS = {
    "boot": ("__RV64_L3_BOOT_PASS__",),
    "mmu": ("__RV64_L3_COW_PASS__",),
    "process": ("__RV64_L3_PROCESS_PASS__",),
    "timer": ("__RV64_L3_TIME_PASS__",),
    "storage": ("__RV64_L3_TMPFS_PASS__",),
    "atomic": ("__RV64_L3_ATOMIC_PASS__",),
    "interrupt": (
        "__RV64_L3_UART_ARM_1__",
        "__RV64_L3_UART_RX_1=0x41__",
        "__RV64_L3_UART_ARM_2__",
        "__RV64_L3_UART_RX_2=0x42__",
        "__RV64_L3_UART_IRQ_PASS__",
    ),
    "shutdown": (),
    "all": (
        "__RV64_L3_BOOT_PASS__",
        "__RV64_L3_COW_PASS__",
        "__RV64_L3_PROCESS_PASS__",
        "__RV64_L3_TIME_PASS__",
        "__RV64_L3_TMPFS_PASS__",
        "__RV64_L3_ATOMIC_PASS__",
        "__RV64_L3_UART_ARM_1__",
        "__RV64_L3_UART_RX_1=0x41__",
        "__RV64_L3_UART_ARM_2__",
        "__RV64_L3_UART_RX_2=0x42__",
        "__RV64_L3_UART_IRQ_PASS__",
    ),
}

FINAL_PHASE_MARKERS = (
    "__RV64_L3_SHUTDOWN_ARM__",
    "__RV64_L3_LIGHTWEIGHT_PASS__",
)

ALL_KNOWN_PHASE_MARKERS = set(COMMON_PHASE_MARKERS) | set(CASE_MARKERS.values())
for _body_markers in CASE_BODY_MARKERS.values():
    ALL_KNOWN_PHASE_MARKERS.update(_body_markers)
ALL_KNOWN_PHASE_MARKERS.update(FINAL_PHASE_MARKERS)


def phase_markers_for_case(case_name: str) -> tuple[str, ...]:
    if case_name not in CASE_SELECTORS:
        raise LightweightLinuxError(f"unsupported L3 case: {case_name!r}")
    return (
        *COMMON_PHASE_MARKERS,
        CASE_MARKERS[case_name],
        *CASE_BODY_MARKERS[case_name],
        *FINAL_PHASE_MARKERS,
    )

TERMINAL_MARKERS = {
    "kernel_power_down": "reboot: Power down",
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
CRITICAL_PATTERNS = (
    re.compile(r"Kernel panic", re.IGNORECASE),
    re.compile(r"(?:^|[^A-Za-z0-9_])Oops(?:[^A-Za-z0-9_]|$)", re.IGNORECASE),
    re.compile(r"Call Trace:", re.IGNORECASE),
    re.compile(r"HIT BAD TRAP", re.IGNORECASE),
    re.compile(r"Bad trap", re.IGNORECASE),
    re.compile(r"(?<![A-Za-z0-9_])BUG:"),
)


class LightweightLinuxError(RuntimeError):
    """The bound L3 execution cannot support the requested claim."""


def sha256_file(path: pathlib.Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(4 * 1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def regular_file(path: pathlib.Path) -> pathlib.Path:
    if path.is_symlink() or not path.is_file():
        raise LightweightLinuxError(f"not a regular non-symlink file: {path}")
    return path


def read_text(path: pathlib.Path) -> str:
    return ANSI_RE.sub("", regular_file(path).read_text(encoding="utf-8", errors="replace"))


def read_binding(path: pathlib.Path) -> dict[str, str]:
    result: dict[str, str] = {}
    for number, raw in enumerate(read_text(path).splitlines(), start=1):
        if not raw or raw.startswith("#"):
            continue
        if "=" not in raw:
            raise LightweightLinuxError(f"binding line {number} has no '='")
        key, value = raw.split("=", 1)
        if not key or key in result:
            raise LightweightLinuxError(f"invalid/duplicate binding key: {key!r}")
        result[key] = value
    return result


def require_binding(binding: dict[str, str]) -> None:
    required = {
        "schema": "npc-rv64-l3-lightweight-linux-run-binding-v1",
        "effective_dtb_shared": "1",
        "effective_dtb_rdinit": "1",
        "effective_dtb_initrd": "1",
        "linux_syscon_poweroff_driver": "0",
        "linux_guest_dtb_syscon": "1",
        "opensbi_platform_dtb_syscon": "1",
        "opensbi_fw_jump_fdt_addr": "0x82300000",
        "linux_load_addr": "0x80400000",
        "linux_guest_dtb_addr": "0x82300000",
        "initramfs_addr": "0x84000000",
        "OOO_ASSERT": "1",
        "OOO_CSR_QUEUE_HEAD": "1",
        "OOO_TERMINAL_HOLDER_ASSERT": "1",
        "linux_version": "6.6.0",
        "ubuntu2204_full_simulation": "not_launched",
    }
    for key, expected in required.items():
        if binding.get(key) != expected:
            raise LightweightLinuxError(
                f"binding mismatch {key}: {binding.get(key)!r} != {expected!r}"
            )
    design_id = binding.get("rtl_design_id", "")
    if not re.fullmatch(r"sha256:[0-9a-f]{64}", design_id):
        raise LightweightLinuxError("invalid rtl_design_id")
    for key in (
        "simulator_sha256",
        "simulator_source_sha256",
        "layer_source_sha256",
        "linux_image_sha256",
        "initramfs_sha256",
        "guest_dtb_sha256",
        "opensbi_platform_dtb_sha256",
        "opensbi_fw_sha256",
        "kernel_effective_config_sha256",
        "pid1_sha256",
        "effective_dtb_sha256",
    ):
        if not re.fullmatch(r"[0-9a-f]{64}", binding.get(key, "")):
            raise LightweightLinuxError(f"invalid/missing hash: {key}")
    for key in ("max_cycles", "uart_rx_cycle_gap"):
        if not binding.get(key, "").isdigit() or int(binding[key]) <= 0:
            raise LightweightLinuxError(f"invalid positive integer: {key}")
    case_name = binding.get("l3_case", "")
    if case_name not in CASE_SELECTORS:
        raise LightweightLinuxError(f"invalid/missing l3_case: {case_name!r}")
    if binding["guest_dtb_sha256"] != binding["opensbi_platform_dtb_sha256"]:
        raise LightweightLinuxError("OpenSBI and Linux DTB hashes differ")
    if binding["guest_dtb_sha256"] != binding["effective_dtb_sha256"]:
        raise LightweightLinuxError("effective DTB hash does not match guest DTB")


def exact_single(text: str, marker: str) -> int:
    count = text.count(marker)
    if count != 1:
        raise LightweightLinuxError(
            f"marker cardinality mismatch {marker!r}: observed {count}"
        )
    return text.index(marker)


def parse_uart_tx_entries(npc_text: str) -> tuple[list[dict[str, int]], bytes]:
    entries: list[dict[str, int]] = []
    for match in UART_TX_RE.finditer(npc_text):
        entries.append(
            {
                "ordinal": int(match.group("ordinal")),
                "cycle": int(match.group("cycle")),
                "commit": int(match.group("commit")),
                "data": int(match.group("data"), 16),
            }
        )
    if not entries:
        raise LightweightLinuxError("no UART TX phase trace")
    if [entry["ordinal"] for entry in entries] != list(range(1, len(entries) + 1)):
        raise LightweightLinuxError("UART TX trace ordinal is not exact/consecutive")
    return entries, bytes(entry["data"] for entry in entries)


def exact_stream_observation(
    entries: list[dict[str, int]], stream: bytes, marker: bytes
) -> dict[str, int]:
    first = stream.find(marker)
    last = stream.rfind(marker)
    if first < 0 or first != last:
        raise LightweightLinuxError(
            f"UART TX trace marker cardinality mismatch: {marker.decode('ascii')}"
        )
    end = first + len(marker) - 1
    return {
        "commit": entries[end]["commit"],
        "cycle": entries[end]["cycle"],
        "tx_ordinal": entries[end]["ordinal"],
    }


def parse_uart_tx_phases(
    entries: list[dict[str, int]], stream: bytes, phase_markers: tuple[str, ...]
) -> dict[str, dict[str, int]]:
    phases: dict[str, dict[str, int]] = {}
    previous = -1
    for marker in phase_markers:
        encoded = marker.encode("ascii")
        first = stream.find(encoded)
        last = stream.rfind(encoded)
        if first < 0 or first != last:
            raise LightweightLinuxError(
                f"UART TX trace marker cardinality mismatch: {marker}"
            )
        if first <= previous:
            raise LightweightLinuxError(f"UART TX phase order mismatch: {marker}")
        phases[marker] = exact_stream_observation(entries, stream, encoded)
        previous = first
    return phases


def parse_uart_rx(
    npc_text: str, case_name: str, minimum_gap: int
) -> list[dict[str, int]]:
    entries = [
        {
            "ordinal": int(match.group("ordinal")),
            "cycle": int(match.group("cycle")),
            "commit": int(match.group("commit")),
            "data": int(match.group("data"), 16),
        }
        for match in UART_RX_RE.finditer(npc_text)
    ]
    expected_data = [CASE_SELECTORS[case_name]]
    if case_name in ("interrupt", "all"):
        expected_data.extend((0x41, 0x42))
    if len(entries) != len(expected_data):
        raise LightweightLinuxError(
            f"expected {len(expected_data)} UART RX pops, observed {len(entries)}"
        )
    if [item["ordinal"] for item in entries] != list(range(1, len(entries) + 1)):
        raise LightweightLinuxError("UART RX ordinals are not exact/consecutive")
    if [item["data"] for item in entries] != expected_data:
        raise LightweightLinuxError(
            f"UART RX payload mismatch for {case_name}: expected {expected_data}"
        )
    if len(entries) == 3 and entries[2]["cycle"] - entries[1]["cycle"] < minimum_gap:
        raise LightweightLinuxError("UART RX cycle gap is below the bound contract")
    return entries


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
    if entries and [item["ordinal"] for item in entries] != list(
        range(1, len(entries) + 1)
    ):
        raise LightweightLinuxError("IRQ trace ordinal is not exact/consecutive")
    return entries


def precedes(left: dict[str, int], right: dict[str, int]) -> bool:
    return left["cycle"] < right["cycle"] and left["commit"] < right["commit"]


def require_uart_irq_windows(
    case_name: str,
    phases: dict[str, dict[str, int]],
    uart_rx: list[dict[str, int]],
    irq_entries: list[dict[str, int]],
) -> list[dict[str, int]]:
    selector = uart_rx[0]
    if not (
        precedes(phases["__RV64_L3_CASE_SELECT__"], selector)
        and precedes(selector, phases[CASE_MARKERS[case_name]])
    ):
        raise LightweightLinuxError(
            "case selector RX is not bracketed by CASE_SELECT/case phase"
        )
    if case_name not in ("interrupt", "all"):
        return []

    windows = (
        (
            "__RV64_L3_UART_ARM_1__",
            uart_rx[1],
            "__RV64_L3_UART_RX_1=0x41__",
        ),
        (
            "__RV64_L3_UART_ARM_2__",
            uart_rx[2],
            "__RV64_L3_UART_RX_2=0x42__",
        ),
    )
    selected: list[dict[str, int]] = []
    for arm_marker, rx_event, observed_marker in windows:
        arm = phases[arm_marker]
        observed = phases[observed_marker]
        if not (precedes(arm, rx_event) and precedes(rx_event, observed)):
            raise LightweightLinuxError(
                f"UART RX is not bracketed by {arm_marker}/{observed_marker}"
            )
        matches = [
            event
            for event in irq_entries
            if event["uart_irq"] == 1
            and event["plic_irq"] == 1
            and precedes(rx_event, event)
            and precedes(event, observed)
        ]
        if not matches:
            raise LightweightLinuxError(
                f"no UART-to-PLIC assertion in {arm_marker}/{observed_marker} window"
            )
        selected.append(matches[0])
    return selected


def parse_execution(
    console_path: pathlib.Path,
    npc_path: pathlib.Path,
    binding_path: pathlib.Path,
) -> dict[str, Any]:
    console = read_text(console_path)
    npc = read_text(npc_path)
    binding = read_binding(binding_path)
    require_binding(binding)
    case_name = binding["l3_case"]
    phase_markers = phase_markers_for_case(case_name)

    combined = console + "\n" + npc
    if "__RV64_L3_FAIL__" in combined:
        raise LightweightLinuxError("guest emitted an L3 failure marker")
    guest_positions = [exact_single(npc, f"[guest] {marker}") for marker in phase_markers]
    if guest_positions != sorted(guest_positions) or len(set(guest_positions)) != len(
        guest_positions
    ):
        raise LightweightLinuxError("guest phase order mismatch")
    unexpected_markers = sorted(ALL_KNOWN_PHASE_MARKERS - set(phase_markers))
    for marker in unexpected_markers:
        if marker in console or marker in npc:
            raise LightweightLinuxError(f"unselected L3 phase marker observed: {marker}")
    terminal_counts = {
        "kernel_power_down": npc.count(TERMINAL_MARKERS["kernel_power_down"]),
        **{
            key: console.count(marker)
            for key, marker in TERMINAL_MARKERS.items()
            if key != "kernel_power_down"
        },
    }
    if any(value != 1 for value in terminal_counts.values()):
        raise LightweightLinuxError(f"terminal cardinality mismatch: {terminal_counts}")
    terminal_order = (
        "syscon_poweroff",
        "good_trap",
        "system_reset",
        "stats_instructions",
        "stats_cycles",
    )
    terminal_positions = [console.index(TERMINAL_MARKERS[key]) for key in terminal_order]
    if terminal_positions != sorted(terminal_positions):
        raise LightweightLinuxError("terminal transaction order mismatch")
    kernel_power_down_pos = npc.index(TERMINAL_MARKERS["kernel_power_down"])
    npc_good_trap_pos = npc.index(TERMINAL_MARKERS["good_trap"])
    if not guest_positions[-1] < kernel_power_down_pos < npc_good_trap_pos:
        raise LightweightLinuxError("guest PASS/kernel power-down/GOOD TRAP order mismatch")
    if ASSERTION_RE.search(combined):
        raise LightweightLinuxError("RTL assertion marker observed")
    for pattern in CRITICAL_PATTERNS:
        match = pattern.search(combined)
        if match:
            raise LightweightLinuxError(f"critical Linux/RTL marker observed: {match.group(0)}")

    results = list(RUN_RESULT_RE.finditer(console))
    instructions = list(TOTAL_INSTRUCTIONS_RE.finditer(console))
    cycles = list(TOTAL_CYCLES_RE.finditer(console))
    if len(results) != 1 or len(instructions) != 1 or len(cycles) != 1:
        raise LightweightLinuxError("final statistics/result cardinality mismatch")
    commits_value = int(results[0].group("commits"))
    cycles_value = int(results[0].group("cycles"))
    if int(results[0].group("code")) != 0:
        raise LightweightLinuxError("system-reset exit code is nonzero")
    if int(instructions[0].group("value")) != commits_value:
        raise LightweightLinuxError("instruction total does not match final commits")
    if int(cycles[0].group("value")) != cycles_value:
        raise LightweightLinuxError("cycle total does not match final cycles")
    if cycles_value > int(binding["max_cycles"]):
        raise LightweightLinuxError("execution exceeded bound max_cycles")

    tx_entries, tx_stream = parse_uart_tx_entries(npc)
    phase_observations = parse_uart_tx_phases(tx_entries, tx_stream, phase_markers)
    pass_observation = phase_observations[FINAL_PHASE_MARKERS[-1]]
    if (
        pass_observation["cycle"] >= cycles_value
        or pass_observation["commit"] >= commits_value
    ):
        raise LightweightLinuxError("L3 PASS phase does not precede terminal result")
    power_down_observation = exact_stream_observation(
        tx_entries, tx_stream, TERMINAL_MARKERS["kernel_power_down"].encode("ascii")
    )
    syscon_matches = list(SYSCON_POWEROFF_RE.finditer(console))
    if len(syscon_matches) != 1:
        raise LightweightLinuxError(
            "syscon poweroff cycle/commit observation cardinality mismatch"
        )
    syscon_observation = {
        "cycle": int(syscon_matches[0].group("cycle")),
        "commit": int(syscon_matches[0].group("commit")),
    }
    if not (
        precedes(pass_observation, power_down_observation)
        and precedes(power_down_observation, syscon_observation)
        and syscon_observation["cycle"] <= cycles_value
        and syscon_observation["commit"] <= commits_value
    ):
        raise LightweightLinuxError(
            "L3 PASS/kernel power-down/syscon/result counter order mismatch"
        )
    uart_rx = parse_uart_rx(npc, case_name, int(binding["uart_rx_cycle_gap"]))
    irq_entries = parse_irq_trace(npc)
    irq_observations = require_uart_irq_windows(
        case_name, phase_observations, uart_rx, irq_entries
    )
    return {
        "schema": SCHEMA,
        "status": "PASS",
        "claim": (
            "L3_LIGHTWEIGHT_LINUX_PASS_CURRENT_IDENTITY"
            if case_name == "all"
            else "L3_LIGHTWEIGHT_LINUX_DIRECTED_CASE_PASS_CURRENT_IDENTITY"
        ),
        "l3_case": case_name,
        "signoff_scope": "full-l3" if case_name == "all" else "directed-case",
        "rtl_design_id": binding["rtl_design_id"],
        "production_rtl_file_count": int(binding["production_rtl_file_count"]),
        "cycles": cycles_value,
        "commits": commits_value,
        "cpi": cycles_value / commits_value,
        "terminal_counts": terminal_counts,
        "phase_observations": phase_observations,
        "uart_rx": uart_rx,
        "uart_irq_observations": irq_observations,
        "kernel_power_down_observation": power_down_observation,
        "syscon_poweroff_observation": syscon_observation,
        "assertion_failures": 0,
        "critical_markers": 0,
        "console": {
            "path": console_path.as_posix(),
            "sha256": sha256_file(console_path),
        },
        "npc_log": {
            "path": npc_path.as_posix(),
            "sha256": sha256_file(npc_path),
        },
        "binding": {
            "path": binding_path.as_posix(),
            "sha256": sha256_file(binding_path),
        },
        "non_claims": [
            "Ubuntu userland",
            "systemd",
            "virtio block rootfs",
            "networking",
            "SMP",
        ],
    }


def load_architecture_binding(root: pathlib.Path) -> tuple[str, int]:
    path = root / "npc/rv64/eval/ppa/tools/architecture_hard_gates.py"
    spec = importlib.util.spec_from_file_location("l3_architecture_binding", path)
    if spec is None or spec.loader is None:
        raise LightweightLinuxError(f"cannot load RTL identity helper: {path}")
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
    subparsers = parser.add_subparsers(dest="command", required=True)
    identity = subparsers.add_parser("rtl-identity")
    identity.add_argument("--repo-root", type=pathlib.Path, required=True)
    identity.add_argument("--output", type=pathlib.Path, required=True)
    check = subparsers.add_parser("check")
    check.add_argument("--console", type=pathlib.Path, required=True)
    check.add_argument("--npc-log", type=pathlib.Path, required=True)
    check.add_argument("--binding", type=pathlib.Path, required=True)
    check.add_argument("--output", type=pathlib.Path, required=True)
    subparsers.add_parser("self-test")
    args = parser.parse_args()
    try:
        if args.command == "rtl-identity":
            root = args.repo_root.resolve()
            design_id, file_count = load_architecture_binding(root)
            result = {
                "schema": RTL_IDENTITY_SCHEMA,
                "rtl_design_id": design_id,
                "production_rtl_file_count": file_count,
            }
            atomic_json(args.output, result)
            print(f"[RV64-L3-RTL-IDENTITY] {design_id} files={file_count}")
            return 0
        if args.command == "check":
            result = parse_execution(args.console, args.npc_log, args.binding)
            atomic_json(args.output, result)
            print(
                "[RV64-L3-CHECK][PASS] "
                f"case={result['l3_case']} scope={result['signoff_scope']} "
                f"commits={result['commits']} cycles={result['cycles']} "
                f"cpi={result['cpi']:.6f} terminal=6/6 "
                f"phases={len(result['phase_observations'])}"
            )
            return 0
        if args.command == "self-test":
            if CRITICAL_PATTERNS[-1].search("printk: debug:"):
                raise LightweightLinuxError("BUG regex rejects benign printk debug")
            if not CRITICAL_PATTERNS[-1].search("kernel BUG: real failure"):
                raise LightweightLinuxError("BUG regex misses a real BUG marker")
            print("[RV64-L3-CHECK-SELF-TEST][PASS] debug-accepted bug-rejected")
            return 0
    except (OSError, ValueError, LightweightLinuxError) as exc:
        print(f"[RV64-L3-CHECK][FAIL] {exc}", file=sys.stderr)
        return 1
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
