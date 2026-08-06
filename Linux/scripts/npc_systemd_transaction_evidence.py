#!/usr/bin/env python3
"""Collect and verify bounded NPC RV64 systemd transaction evidence.

The collector treats the console and NPC log as two observations of one local
RV64 simulation.  It counts every marker, preserves semantic failures, and
never de-duplicates terminal events.  The verifier recomputes the canonical
receipt from the supplied logs; a successful verification does not by itself
promote a semantic FAIL receipt.
"""

from __future__ import annotations

import argparse
import collections
import hashlib
import json
import os
import re
import sys
import tempfile
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, Sequence


SCHEMA = "npc-rv64-systemd-transaction-evidence/v2"
SNAPSHOT_ROUNDS = 3
MAX_U64 = (1 << 64) - 1

RC_PASS = 0
RC_FAIL = 1
RC_INVALID_EVIDENCE = 2
RC_VERIFY_MISMATCH = 3
RC_USAGE = 64
RC_INTERNAL = 70
RC_OUTPUT = 74

SGR_RE = re.compile(r"\x1b\[[0-9;]{0,32}m")
INIT_RE = re.compile(
    r"^\[log\.c:[0-9]+ npc_init_log\] Log is written to (/.+)$"
)
KERNEL_POWER_DOWN_RE = re.compile(
    r"^\[\s*[0-9]+\.[0-9]{6}\] reboot: Power down$"
)
SYSCON_RE = re.compile(
    r"^syscon-reset: poweroff requested value=0x00005555 "
    r"pc=(0x[0-9a-f]{16})"
    r"(?: cycle=[0-9]+ commit=[0-9]+)?$"
)
GOOD_RE = re.compile(
    r"^\[cpu-exec\.cpp:[0-9]+ cpu_exec\] npc: HIT GOOD TRAP "
    r"at pc = (0x[0-9a-f]{16})$"
)
RESET_RE = re.compile(
    r"^\[cpu-exec\.cpp:[0-9]+ report_run_result\] "
    r"exit via system-reset, code=0, cycles=([0-9]+), commits=([0-9]+)$"
)
STATS_INST_RE = re.compile(
    r"^\[cpu-exec\.cpp:[0-9]+ statistic\] "
    r"total guest instructions = ([0-9]+)$"
)
STATS_CYCLES_RE = re.compile(
    r"^\[cpu-exec\.cpp:[0-9]+ statistic\] total guest cycles = ([0-9]+)$"
)

POWEROFF_BEGIN = "__NPC_SYSTEMD_POWEROFF_BEGIN__"
TERMINAL_EVENT_ORDER = (
    "poweroff_begin",
    "kernel_power_down",
    "syscon_poweroff",
    "good_trap",
    "system_reset",
    "stats_instructions",
    "stats_cycles",
)
NPC_EVENT_ORDER = (
    "poweroff_begin",
    "kernel_power_down",
    "good_trap",
    "system_reset",
    "stats_instructions",
    "stats_cycles",
)

PREFLIGHT_LABELS = (
    "os-release-ubuntu-2204",
    "bin-sh",
    "bin-bash",
    "systemd-binary",
    "systemd-autocheck-script",
    "systemd-wrapper-preflight",
)
AUTOCHECK_LABELS = (
    "uname-riscv64",
    "os-release-ubuntu-2204",
    "root-context",
    "bin-sh",
    "bin-bash",
    "systemd-state",
)
STRICT_LABELS = (
    "uname-riscv64",
    "os-release-ubuntu-2204",
    "root-shell",
    "bin-sh",
    "bin-bash",
    "systemd-state",
    "block-vda",
    "virtio-blk-driver",
    "root-on-vda",
    "root-ext4",
    "root-rw",
    "rootfs-write-sync-readback",
    "virtio-device-name",
    "virtio-irq-before-parse",
    "virtio-blk-direct-read",
    "virtio-irq-growth",
    "dmesg-no-critical",
)


class UsageError(Exception):
    """Command-line usage error mapped to sysexits EX_USAGE."""


class DuplicateJsonKey(ValueError):
    """Duplicate JSON object key."""


class EvidenceArgumentParser(argparse.ArgumentParser):
    def error(self, message: str) -> None:
        raise UsageError(f"{self.format_usage().strip()}\n{self.prog}: {message}")


@dataclass(frozen=True)
class StageSpec:
    name: str
    begin: str
    done_stem: str
    pass_prefix: str
    fail_prefix: str
    expected_labels: tuple[str, ...]
    ancillary_prefixes: tuple[str, ...]

    @property
    def done_re(self) -> re.Pattern[str]:
        return re.compile(rf"^{re.escape(self.done_stem)} rc=([0-9]+)$")


@dataclass(frozen=True)
class NormalizedSource:
    name: str
    path: Path
    resolved_path: str
    raw: bytes
    lines: list[str]
    newline_counts: dict[str, int]
    sgr_sequences_stripped: int

    @property
    def metadata(self) -> dict[str, object]:
        return {
            "path": self.resolved_path,
            "sha256": hashlib.sha256(self.raw).hexdigest(),
            "size_bytes": len(self.raw),
            "line_count": len(self.lines),
            "format_status": "VALID",
            "newline_counts": self.newline_counts,
            "sgr_sequences_stripped": self.sgr_sequences_stripped,
        }


V2_SPECS = (
    StageSpec(
        "preflight",
        "__NPC_SYSTEMD_PREFLIGHT_BEGIN__",
        "__NPC_SYSTEMD_PREFLIGHT_DONE__",
        "__NPC_PREFLIGHT_PASS__:",
        "__NPC_PREFLIGHT_FAIL__:",
        PREFLIGHT_LABELS,
        ("__NPC_PREFLIGHT_SYSTEMD_STATE__:",),
    ),
    StageSpec(
        "autocheck",
        "__NPC_SYSTEMD_AUTOCHECK_BEGIN__",
        "__NPC_SYSTEMD_AUTOCHECK_DONE__",
        "__NPC_AUTOCHECK_PASS__:",
        "__NPC_AUTOCHECK_FAIL__:",
        AUTOCHECK_LABELS,
        (
            "__NPC_AUTOCHECK_UNAME__:",
            "__NPC_AUTOCHECK_SYSTEMD_STATE__:",
        ),
    ),
    StageSpec(
        "strict",
        "__NPC_SYSTEMD_STRICT_BEGIN__",
        "__NPC_SYSTEMD_STRICT_DONE__",
        "__NPC_CHECK_PASS__:",
        "__NPC_CHECK_FAIL__:",
        STRICT_LABELS,
        (
            "__NPC_CHECK_UNAME__:",
            "__NPC_CHECK_SYSTEMD_STATE__:",
            "__NPC_CHECK_VDA_DRIVER__:",
            "__NPC_CHECK_ROOT_SOURCE__:",
            "__NPC_CHECK_ROOT_MOUNT__:",
            "__NPC_CHECK_VIRTIO_IRQ_OWNER__:",
            "__NPC_CHECK_VIRTIO_IRQ__:",
        ),
    ),
)

LEGACY_SPECS = (
    StageSpec(
        "preflight",
        "__NPC_SYSTEMD_CHECK_BEGIN__",
        "__NPC_SYSTEMD_CHECK_DONE__",
        "__NPC_CHECK_PASS__:",
        "__NPC_CHECK_FAIL__:",
        PREFLIGHT_LABELS,
        ("__NPC_CHECK_SYSTEMD_STATE__:",),
    ),
    StageSpec(
        "autocheck",
        "__NPC_SYSTEMD_CHECK_BEGIN__",
        "__NPC_SYSTEMD_AUTOCHECK_DONE__",
        "__NPC_CHECK_PASS__:",
        "__NPC_CHECK_FAIL__:",
        AUTOCHECK_LABELS,
        (
            "__NPC_CHECK_UNAME__:",
            "__NPC_CHECK_SYSTEMD_STATE__:",
        ),
    ),
    StageSpec(
        "strict",
        "__NPC_SYSTEMD_CHECK_BEGIN__",
        "__NPC_SYSTEMD_UART_CHECK_DONE__",
        "__NPC_CHECK_PASS__:",
        "__NPC_CHECK_FAIL__:",
        STRICT_LABELS,
        (
            "__NPC_CHECK_UNAME__:",
            "__NPC_CHECK_SYSTEMD_STATE__:",
            "__NPC_CHECK_VDA_DRIVER__:",
            "__NPC_CHECK_ROOT_SOURCE__:",
            "__NPC_CHECK_ROOT_MOUNT__:",
            "__NPC_CHECK_VIRTIO_IRQ_OWNER__:",
            "__NPC_CHECK_VIRTIO_IRQ__:",
        ),
    ),
)


def canonical_json_bytes(payload: dict[str, object]) -> bytes:
    return (
        json.dumps(
            payload,
            ensure_ascii=False,
            sort_keys=True,
            separators=(",", ":"),
        )
        + "\n"
    ).encode("utf-8")


def sha256_bytes(raw: bytes) -> str:
    return hashlib.sha256(raw).hexdigest()


def resolved(path: Path) -> str:
    return str(path.expanduser().resolve(strict=False))


def read_joint_snapshot(
    paths: dict[str, Path],
    producer_closed_proof: bool,
) -> tuple[dict[str, bytes], dict[str, object], list[str]]:
    observations: list[dict[str, dict[str, object]]] = []
    latest: dict[str, bytes] = {}
    errors: list[str] = []
    for round_index in range(1, SNAPSHOT_ROUNDS + 1):
        row: dict[str, dict[str, object]] = {}
        for name, path in paths.items():
            try:
                raw = path.read_bytes()
            except OSError as error:
                errors.append(
                    f"{name}: read failed in snapshot round {round_index}: "
                    f"{type(error).__name__}: {error}"
                )
                continue
            latest[name] = raw
            row[name] = {
                "path": resolved(path),
                "sha256": sha256_bytes(raw),
                "size_bytes": len(raw),
            }
        observations.append(row)

    stable = (
        not errors
        and bool(observations)
        and all(row == observations[0] for row in observations[1:])
        and set(latest) == set(paths)
    )
    if not stable and not errors:
        errors.append("joint snapshot changed across three consecutive read rounds")
    return (
        latest,
        {
            "rounds": SNAPSHOT_ROUNDS,
            "stable": stable,
            "producer_closed_proof": producer_closed_proof,
            "observations": observations,
        },
        errors,
    )


def normalize_newlines(text: str) -> tuple[str, dict[str, int]]:
    counts = {"LF": 0, "CRLF": 0, "CRCRLF": 0}
    output: list[str] = []
    index = 0
    while index < len(text):
        char = text[index]
        if char == "\n":
            counts["LF"] += 1
            output.append("\n")
            index += 1
            continue
        if char != "\r":
            output.append(char)
            index += 1
            continue

        run_start = index
        while index < len(text) and text[index] == "\r":
            index += 1
        run_length = index - run_start
        if index >= len(text) or text[index] != "\n":
            raise ValueError(f"bare CR sequence at character {run_start}")
        if run_length > 2:
            raise ValueError(
                f"CR run length {run_length} before LF at character {run_start}; "
                "maximum is 2"
            )
        counts["CRLF" if run_length == 1 else "CRCRLF"] += 1
        output.append("\n")
        index += 1
    return "".join(output), counts


def normalize_source(name: str, path: Path, raw: bytes) -> NormalizedSource:
    if not raw.endswith(b"\n"):
        raise ValueError("final byte is not LF")
    if raw.startswith(b"\xef\xbb\xbf"):
        raise ValueError("UTF-8 BOM is not permitted")
    try:
        text = raw.decode("utf-8", errors="strict")
    except UnicodeDecodeError as error:
        raise ValueError(
            f"invalid UTF-8 at byte {error.start}: {error.reason}"
        ) from error
    if "\ufeff" in text:
        raise ValueError("U+FEFF BOM is not permitted")

    text, newline_counts = normalize_newlines(text)
    text, sgr_count = SGR_RE.subn("", text)
    if "\x1b" in text:
        raise ValueError("unsupported escape sequence remains after bounded SGR removal")

    for index, char in enumerate(text):
        codepoint = ord(char)
        if char == "\n":
            continue
        if codepoint == 0:
            raise ValueError(f"NUL control byte at character {index}")
        if codepoint < 0x20 or codepoint == 0x7F or 0x80 <= codepoint <= 0x9F:
            raise ValueError(
                f"disallowed control U+{codepoint:04X} at character {index}"
            )

    lines = text[:-1].split("\n")
    return NormalizedSource(
        name=name,
        path=path,
        resolved_path=resolved(path),
        raw=raw,
        lines=lines,
        newline_counts=newline_counts,
        sgr_sequences_stripped=sgr_count,
    )


def invalid_source_metadata(
    path: Path, raw: bytes | None, error: str
) -> dict[str, object]:
    metadata: dict[str, object] = {
        "path": resolved(path),
        "format_status": "INVALID",
        "format_errors": [error],
    }
    if raw is not None:
        metadata.update(
            {
                "sha256": sha256_bytes(raw),
                "size_bytes": len(raw),
            }
        )
    return metadata


def exact_positions(lines: list[str], marker: str) -> list[int]:
    return [index for index, line in enumerate(lines, start=1) if line == marker]


def done_positions(lines: list[str], spec: StageSpec) -> list[tuple[int, int, str]]:
    result: list[tuple[int, int, str]] = []
    for index, line in enumerate(lines, start=1):
        match = spec.done_re.fullmatch(line)
        if match:
            result.append((index, int(match.group(1)), line))
    return result


def protocol_from_lines(lines: list[str], requested: str) -> str:
    if requested != "auto":
        return requested
    v2_stems = (
        "__NPC_SYSTEMD_PREFLIGHT_BEGIN__",
        "__NPC_SYSTEMD_PREFLIGHT_DONE__",
        "__NPC_SYSTEMD_AUTOCHECK_BEGIN__",
        "__NPC_SYSTEMD_STRICT_BEGIN__",
        "__NPC_SYSTEMD_STRICT_DONE__",
    )
    if any(any(line.startswith(stem) for stem in v2_stems) for line in lines):
        return "strict-v2"
    return "legacy-v1"


def add_count_errors(
    expected_labels: Iterable[str],
    observed: collections.Counter[str],
    errors: list[str],
) -> None:
    expected = set(expected_labels)
    for label in expected_labels:
        count = observed[label]
        if count == 0:
            errors.append(f"missing PASS label {label}")
        elif count != 1:
            errors.append(
                f"PASS label {label} observed {count} times; expected exactly 1"
            )
    for label in sorted(set(observed) - expected):
        errors.append(
            f"unexpected PASS label {label} observed {observed[label]} times"
        )


def parse_stages(lines: list[str], requested_protocol: str) -> dict[str, object]:
    protocol = protocol_from_lines(lines, requested_protocol)
    specs = V2_SPECS if protocol == "strict-v2" else LEGACY_SPECS
    errors: list[str] = []

    v2_structural_stems = (
        "__NPC_SYSTEMD_PREFLIGHT_BEGIN__",
        "__NPC_SYSTEMD_PREFLIGHT_DONE__",
        "__NPC_SYSTEMD_AUTOCHECK_BEGIN__",
        "__NPC_SYSTEMD_STRICT_BEGIN__",
        "__NPC_SYSTEMD_STRICT_DONE__",
    )
    legacy_structural_stems = (
        "__NPC_SYSTEMD_CHECK_BEGIN__",
        "__NPC_SYSTEMD_CHECK_DONE__",
        "__NPC_SYSTEMD_UART_CHECK_DONE__",
    )
    mixed_stems = legacy_structural_stems if protocol == "strict-v2" else v2_structural_stems
    mixed = [
        (index, line)
        for index, line in enumerate(lines, start=1)
        if any(line.startswith(stem) for stem in mixed_stems)
    ]
    if mixed:
        other = "legacy-v1" if protocol == "strict-v2" else "strict-v2"
        errors.append(
            f"protocol: {protocol} console contains {other} structural marker(s): "
            + ", ".join(f"L{index}={line}" for index, line in mixed)
        )

    begin_by_stage: dict[str, list[int]] = {}
    if protocol == "legacy-v1":
        common_begins = exact_positions(lines, "__NPC_SYSTEMD_CHECK_BEGIN__")
        if len(common_begins) != len(specs):
            errors.append(
                "protocol: legacy-v1 begin marker observed "
                f"{len(common_begins)} times; expected exactly {len(specs)}"
            )
        for index, spec in enumerate(specs):
            begin_by_stage[spec.name] = (
                [common_begins[index]] if index < len(common_begins) else []
            )
    else:
        for spec in specs:
            begin_by_stage[spec.name] = exact_positions(lines, spec.begin)

    done_by_stage = {spec.name: done_positions(lines, spec) for spec in specs}
    structural_indices: set[int] = set()
    for positions in begin_by_stage.values():
        structural_indices.update(positions)
    for positions in done_by_stage.values():
        structural_indices.update(position[0] for position in positions)

    sequence: list[int] = []
    complete_sequence = True
    for spec in specs:
        begins = begin_by_stage[spec.name]
        dones = done_by_stage[spec.name]
        if len(begins) == 1 and len(dones) == 1:
            sequence.extend((begins[0], dones[0][0]))
        else:
            complete_sequence = False
    if complete_sequence and sequence != sorted(sequence):
        errors.append(
            "protocol: stage boundaries are not ordered as "
            "preflight -> autocheck -> strict"
        )

    accepted_marker_indices: set[int] = set(structural_indices)
    stages: list[dict[str, object]] = []
    for stage_index, spec in enumerate(specs):
        stage_errors: list[str] = []
        begins = begin_by_stage[spec.name]
        dones = done_by_stage[spec.name]
        if len(begins) != 1:
            stage_errors.append(
                f"begin marker observed {len(begins)} times; expected exactly 1"
            )
        if len(dones) != 1:
            stage_errors.append(
                f"done marker observed {len(dones)} times; expected exactly 1"
            )
        begin_line = begins[0] if begins else None
        done_line = dones[0][0] if dones else None
        done_rc = dones[0][1] if dones else None
        if done_rc is not None and done_rc != 0:
            stage_errors.append(f"done marker has rc={done_rc}")

        next_begin: int | None = None
        for next_spec in specs[stage_index + 1 :]:
            next_positions = begin_by_stage[next_spec.name]
            if next_positions:
                next_begin = next_positions[0]
                break

        if begin_line is None:
            window_start, window_end = 1, 0
        else:
            window_start = begin_line + 1
            if done_line is not None and done_line > begin_line:
                window_end = done_line - 1
            elif next_begin is not None and next_begin > begin_line:
                window_end = next_begin - 1
            else:
                window_end = len(lines)

        if begin_line is not None and done_line is not None and done_line <= begin_line:
            stage_errors.append(
                f"done marker L{done_line} is not after begin marker L{begin_line}"
            )
        if (
            begin_line is not None
            and done_line is not None
            and next_begin is not None
            and done_line >= next_begin
        ):
            stage_errors.append(
                f"done marker L{done_line} crosses next stage begin L{next_begin}"
            )

        pass_counts: collections.Counter[str] = collections.Counter()
        fail_markers: list[dict[str, object]] = []
        ancillary_counts: collections.Counter[str] = collections.Counter()
        ancillary_markers: list[dict[str, object]] = []
        if window_start <= window_end:
            for line_no in range(window_start, window_end + 1):
                line = lines[line_no - 1]
                if line.startswith(spec.pass_prefix):
                    pass_counts[line[len(spec.pass_prefix) :]] += 1
                    accepted_marker_indices.add(line_no)
                elif line.startswith(spec.fail_prefix):
                    fail_markers.append({"line": line_no, "text": line})
                    accepted_marker_indices.add(line_no)
                else:
                    for prefix in spec.ancillary_prefixes:
                        if line.startswith(prefix):
                            ancillary_counts[prefix] += 1
                            ancillary_markers.append({"line": line_no, "text": line})
                            accepted_marker_indices.add(line_no)
                            break

        add_count_errors(spec.expected_labels, pass_counts, stage_errors)
        if fail_markers:
            stage_errors.append(
                f"{len(fail_markers)} FAIL marker(s) observed in bounded stage"
            )
        for prefix in spec.ancillary_prefixes:
            count = ancillary_counts[prefix]
            if count != 1:
                stage_errors.append(
                    f"ancillary marker {prefix} observed {count} times; expected exactly 1"
                )

        errors.extend(f"{spec.name}: {error}" for error in stage_errors)
        stages.append(
            {
                "name": spec.name,
                "status": "PASS" if not stage_errors else "FAIL",
                "begin_line": begin_line,
                "done_line": done_line,
                "done_rc": done_rc,
                "window_line_count": (
                    window_end - window_start + 1 if window_start <= window_end else 0
                ),
                "expected_pass_labels": list(spec.expected_labels),
                "observed_pass_counts": {
                    label: pass_counts[label] for label in sorted(pass_counts)
                },
                "pass_observation_count": sum(pass_counts.values()),
                "fail_markers": fail_markers,
                "ancillary_markers": ancillary_markers,
                "errors": stage_errors,
            }
        )

    reserved_prefixes = tuple(
        dict.fromkeys(
            prefix
            for spec in specs
            for prefix in (
                spec.begin,
                spec.done_stem,
                spec.pass_prefix,
                spec.fail_prefix,
                *spec.ancillary_prefixes,
            )
        )
    )
    for line_no, line in enumerate(lines, start=1):
        if line_no in accepted_marker_indices:
            continue
        if any(line.startswith(prefix) for prefix in reserved_prefixes):
            errors.append(
                "protocol: reserved marker outside its bounded stage at "
                f"L{line_no}: {line}"
            )
    if any(line == "__NPC_SYSTEMD_POWEROFF_CMD_FAIL__" for line in lines):
        errors.append("terminal: guest poweroff command reported failure")

    return {
        "status": "PASS" if not errors else "FAIL",
        "protocol": protocol,
        "stage_order": [spec.name for spec in specs],
        "stages": stages,
        "errors": errors,
    }


def terminal_reserved(line: str) -> bool:
    return (
        line.startswith("__NPC_SYSTEMD_POWEROFF")
        or "reboot: Power" in line
        or line.startswith("syscon-reset: poweroff requested")
        or "HIT GOOD TRAP" in line
        or "HIT BAD TRAP" in line
        or "exit via system-reset" in line
        or "total guest instructions" in line
        or "total guest cycles" in line
    )


def event_record(line_no: int, text: str, match: re.Match[str] | None = None) -> dict[str, object]:
    record: dict[str, object] = {"line": line_no, "text": text}
    if match is not None:
        record["groups"] = list(match.groups())
    return record


def add_exact_count_errors(
    scope: str,
    order: Sequence[str],
    observations: dict[str, list[dict[str, object]]],
    errors: list[str],
) -> None:
    for name in order:
        count = len(observations[name])
        if count != 1:
            errors.append(
                f"{scope}: {name} observed {count} times; expected exactly 1"
            )
    if all(len(observations[name]) == 1 for name in order):
        positions = [int(observations[name][0]["line"]) for name in order]
        if positions != sorted(positions) or len(set(positions)) != len(positions):
            errors.append(
                f"{scope}: terminal events are not ordered as " + " -> ".join(order)
            )


def parse_u64(scope: str, field: str, text: str, errors: list[str]) -> int | None:
    value = int(text)
    if not 1 <= value <= MAX_U64:
        errors.append(f"{scope}: {field}={text} is outside nonzero u64 range")
        return None
    return value


def scan_console_terminal(lines: list[str]) -> dict[str, object]:
    observations = {name: [] for name in TERMINAL_EVENT_ORDER}
    malformed: list[dict[str, object]] = []
    errors: list[str] = []
    for line_no, line in enumerate(lines, start=1):
        match: re.Match[str] | None
        if line == POWEROFF_BEGIN:
            observations["poweroff_begin"].append(event_record(line_no, line))
        elif (match := KERNEL_POWER_DOWN_RE.fullmatch(line)) is not None:
            observations["kernel_power_down"].append(event_record(line_no, line, match))
        elif (match := SYSCON_RE.fullmatch(line)) is not None:
            observations["syscon_poweroff"].append(event_record(line_no, line, match))
        elif (match := GOOD_RE.fullmatch(line)) is not None:
            observations["good_trap"].append(event_record(line_no, line, match))
        elif (match := RESET_RE.fullmatch(line)) is not None:
            observations["system_reset"].append(event_record(line_no, line, match))
        elif (match := STATS_INST_RE.fullmatch(line)) is not None:
            observations["stats_instructions"].append(event_record(line_no, line, match))
        elif (match := STATS_CYCLES_RE.fullmatch(line)) is not None:
            observations["stats_cycles"].append(event_record(line_no, line, match))
        elif terminal_reserved(line):
            malformed.append(event_record(line_no, line))

    add_exact_count_errors("console", TERMINAL_EVENT_ORDER, observations, errors)
    for record in malformed:
        errors.append(
            f"console: malformed or reserved terminal marker at "
            f"L{record['line']}: {record['text']}"
        )

    pc: str | None = None
    cycles: int | None = None
    commits: int | None = None
    stats_instructions: int | None = None
    stats_cycles: int | None = None
    if len(observations["syscon_poweroff"]) == 1:
        pc = str(observations["syscon_poweroff"][0]["groups"][0])
    if len(observations["good_trap"]) == 1:
        good_pc = str(observations["good_trap"][0]["groups"][0])
        if pc is not None and good_pc != pc:
            errors.append(f"console: syscon PC {pc} != GOOD TRAP PC {good_pc}")
    if len(observations["system_reset"]) == 1:
        groups = observations["system_reset"][0]["groups"]
        cycles = parse_u64("console", "cycles", str(groups[0]), errors)
        commits = parse_u64("console", "commits", str(groups[1]), errors)
    if len(observations["stats_instructions"]) == 1:
        stats_instructions = parse_u64(
            "console",
            "stats_instructions",
            str(observations["stats_instructions"][0]["groups"][0]),
            errors,
        )
    if len(observations["stats_cycles"]) == 1:
        stats_cycles = parse_u64(
            "console",
            "stats_cycles",
            str(observations["stats_cycles"][0]["groups"][0]),
            errors,
        )
    if commits is not None and stats_instructions is not None and commits != stats_instructions:
        errors.append(
            f"console: reset commits {commits} != stats instructions {stats_instructions}"
        )
    if cycles is not None and stats_cycles is not None and cycles != stats_cycles:
        errors.append(f"console: reset cycles {cycles} != stats cycles {stats_cycles}")

    return {
        "status": "PASS" if not errors else "FAIL",
        "event_counts": {name: len(observations[name]) for name in TERMINAL_EVENT_ORDER},
        "observations": observations,
        "malformed_markers": malformed,
        "pc": pc,
        "cycles": cycles,
        "commits": commits,
        "stats_instructions": stats_instructions,
        "stats_cycles": stats_cycles,
        "errors": errors,
    }


def scan_npc_terminal(lines: list[str]) -> dict[str, object]:
    observations = {name: [] for name in NPC_EVENT_ORDER}
    syscon_markers: list[dict[str, object]] = []
    malformed: list[dict[str, object]] = []
    errors: list[str] = []
    for line_no, line in enumerate(lines, start=1):
        match: re.Match[str] | None
        if line == f"[guest] {POWEROFF_BEGIN}":
            observations["poweroff_begin"].append(event_record(line_no, line))
        elif line.startswith("[guest] ") and (
            match := KERNEL_POWER_DOWN_RE.fullmatch(line[len("[guest] ") :])
        ) is not None:
            observations["kernel_power_down"].append(event_record(line_no, line, match))
        elif (match := GOOD_RE.fullmatch(line)) is not None:
            observations["good_trap"].append(event_record(line_no, line, match))
        elif (match := RESET_RE.fullmatch(line)) is not None:
            observations["system_reset"].append(event_record(line_no, line, match))
        elif (match := STATS_INST_RE.fullmatch(line)) is not None:
            observations["stats_instructions"].append(event_record(line_no, line, match))
        elif (match := STATS_CYCLES_RE.fullmatch(line)) is not None:
            observations["stats_cycles"].append(event_record(line_no, line, match))
        elif SYSCON_RE.fullmatch(line) is not None or (
            line.startswith("[guest] ")
            and SYSCON_RE.fullmatch(line[len("[guest] ") :]) is not None
        ):
            syscon_markers.append(event_record(line_no, line))
        elif terminal_reserved(line) or (
            line.startswith("[guest] ") and terminal_reserved(line[len("[guest] ") :])
        ):
            malformed.append(event_record(line_no, line))

    add_exact_count_errors("npc", NPC_EVENT_ORDER, observations, errors)
    if syscon_markers:
        errors.append(
            f"npc: syscon poweroff marker observed {len(syscon_markers)} times; expected 0"
        )
    for record in malformed:
        errors.append(
            f"npc: malformed or reserved terminal marker at "
            f"L{record['line']}: {record['text']}"
        )
    return {
        "status": "PASS" if not errors else "FAIL",
        "event_counts": {name: len(observations[name]) for name in NPC_EVENT_ORDER},
        "observations": observations,
        "syscon_markers": syscon_markers,
        "malformed_markers": malformed,
        "errors": errors,
    }


def one_observation_text(result: dict[str, object], name: str) -> str | None:
    records = result["observations"][name]
    if len(records) != 1:
        return None
    return str(records[0]["text"])


def init_observations(lines: list[str]) -> list[dict[str, object]]:
    result: list[dict[str, object]] = []
    for line_no, line in enumerate(lines, start=1):
        match = INIT_RE.fullmatch(line)
        if match:
            result.append(event_record(line_no, line, match))
    return result


def validate_init_and_mirror(
    console: NormalizedSource,
    npc: NormalizedSource,
    console_result: dict[str, object],
    npc_result: dict[str, object],
) -> tuple[dict[str, object], list[str]]:
    errors: list[str] = []
    expected_npc_path = npc.resolved_path
    console_init = init_observations(console.lines)
    npc_init = init_observations(npc.lines)
    for scope, observations in (("console", console_init), ("npc", npc_init)):
        if len(observations) != 1:
            errors.append(
                f"{scope}: NPC log init line observed {len(observations)} times; "
                "expected exactly 1"
            )
            continue
        logged = str(observations[0]["groups"][0])
        logged_resolved = resolved(Path(logged))
        if logged_resolved != expected_npc_path:
            errors.append(
                f"{scope}: NPC log init path {logged_resolved} != CLI NPC log "
                f"path {expected_npc_path}"
            )
        begin_text = one_observation_text(
            console_result if scope == "console" else npc_result,
            "poweroff_begin",
        )
        if begin_text is not None:
            begin_records = (
                console_result if scope == "console" else npc_result
            )["observations"]["poweroff_begin"]
            if int(observations[0]["line"]) >= int(begin_records[0]["line"]):
                errors.append(f"{scope}: NPC log init line is not before poweroff begin")

    mirror_pairs = (
        ("poweroff_begin", True),
        ("kernel_power_down", True),
        ("good_trap", False),
        ("system_reset", False),
        ("stats_instructions", False),
        ("stats_cycles", False),
    )
    for name, guest_prefix in mirror_pairs:
        console_text = one_observation_text(console_result, name)
        npc_text = one_observation_text(npc_result, name)
        if console_text is None or npc_text is None:
            continue
        expected = f"[guest] {console_text}" if guest_prefix else console_text
        if npc_text != expected:
            errors.append(
                f"mirror: NPC {name} text does not equal expected console mirror"
            )

    return {
        "expected_npc_log_path": expected_npc_path,
        "console": console_init,
        "npc": npc_init,
    }, errors


def parse_terminal(
    console: NormalizedSource, npc: NormalizedSource
) -> dict[str, object]:
    console_result = scan_console_terminal(console.lines)
    npc_result = scan_npc_terminal(npc.lines)
    init_result, mirror_errors = validate_init_and_mirror(
        console, npc, console_result, npc_result
    )
    errors = [
        *console_result["errors"],
        *npc_result["errors"],
        *mirror_errors,
    ]
    return {
        "contract": "natural-poweroff",
        "status": "PASS" if not errors else "FAIL",
        "init": init_result,
        "console": console_result,
        "npc": npc_result,
        "errors": errors,
    }


def not_evaluated_stage(requested_protocol: str) -> dict[str, object]:
    return {
        "status": "NOT_EVALUATED",
        "protocol": requested_protocol,
        "stage_order": [],
        "stages": [],
        "errors": [],
    }


def not_evaluated_terminal(contract: str, status: str) -> dict[str, object]:
    return {
        "contract": contract,
        "status": status,
        "init": None,
        "console": None,
        "npc": None,
        "errors": [],
    }


def collect_payload(
    console_path: Path,
    npc_path: Path | None,
    requested_protocol: str,
    terminal_contract: str,
    producer_closed_proof: bool = False,
) -> dict[str, object]:
    paths = {"console": console_path}
    if npc_path is not None:
        paths["npc"] = npc_path
    raw_sources, snapshot, snapshot_errors = read_joint_snapshot(
        paths, producer_closed_proof
    )

    sources: dict[str, object] = {}
    normalized: dict[str, NormalizedSource] = {}
    format_errors: list[str] = []
    for name, path in paths.items():
        raw = raw_sources.get(name)
        if raw is None:
            error = next(
                (item for item in snapshot_errors if item.startswith(f"{name}:")),
                f"{name}: source bytes unavailable",
            )
            sources[name] = invalid_source_metadata(path, None, error)
            format_errors.append(error)
            continue
        try:
            source = normalize_source(name, path, raw)
        except ValueError as error:
            message = f"{name}: {error}"
            sources[name] = invalid_source_metadata(path, raw, message)
            format_errors.append(message)
        else:
            normalized[name] = source
            sources[name] = source.metadata
    if npc_path is None:
        sources["npc"] = None

    all_invalid_errors = [*snapshot_errors, *format_errors]
    console_valid = "console" in normalized
    npc_valid = npc_path is None or "npc" in normalized

    if console_valid:
        stage = parse_stages(normalized["console"].lines, requested_protocol)
    else:
        stage = not_evaluated_stage(requested_protocol)

    if terminal_contract == "none":
        terminal = not_evaluated_terminal("none", "NOT_REQUESTED")
    elif console_valid and npc_valid and npc_path is not None:
        terminal = parse_terminal(normalized["console"], normalized["npc"])
        strict_done_line: int | None = None
        for stage_item in stage["stages"]:
            if stage_item["name"] == "strict":
                strict_done_line = stage_item["done_line"]
                break
        begin_records = terminal["console"]["observations"]["poweroff_begin"]
        if strict_done_line is not None and len(begin_records) == 1:
            begin_line = int(begin_records[0]["line"])
            if int(strict_done_line) >= begin_line:
                cross_error = (
                    "console: strict done is not before poweroff begin "
                    f"(strict_done=L{strict_done_line}, poweroff_begin=L{begin_line})"
                )
                terminal["errors"].append(cross_error)
                terminal["status"] = "FAIL"
    else:
        terminal = not_evaluated_terminal(
            "natural-poweroff", "NOT_EVALUATED"
        )

    if all_invalid_errors:
        status = "INVALID_EVIDENCE"
        errors = all_invalid_errors
    else:
        semantic_errors = [
            *stage["errors"],
            *terminal["errors"],
        ]
        status = "PASS" if not semantic_errors else "FAIL"
        errors = semantic_errors

    return {
        "schema": SCHEMA,
        "status": status,
        "requested_protocol": requested_protocol,
        "protocol": stage["protocol"],
        "terminal_contract": terminal_contract,
        "snapshot": snapshot,
        "sources": sources,
        "stage_status": stage["status"],
        "stage_order": stage["stage_order"],
        "stages": stage["stages"],
        "terminal": terminal,
        "errors": errors,
    }


def remove_stale_output(path: Path) -> None:
    if path.exists() or path.is_symlink():
        path.unlink()


def atomic_write(path: Path, raw: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, temporary_name = tempfile.mkstemp(
        prefix=f".{path.name}.", suffix=".tmp", dir=path.parent
    )
    temporary = Path(temporary_name)
    try:
        with os.fdopen(fd, "wb") as stream:
            stream.write(raw)
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(temporary, path)
        if hasattr(os, "O_DIRECTORY"):
            directory_fd = os.open(path.parent, os.O_RDONLY | os.O_DIRECTORY)
            try:
                os.fsync(directory_fd)
            finally:
                os.close(directory_fd)
    except BaseException:
        try:
            temporary.unlink(missing_ok=True)
        except OSError:
            pass
        raise


def duplicate_key_guard(pairs: list[tuple[str, object]]) -> dict[str, object]:
    result: dict[str, object] = {}
    for key, value in pairs:
        if key in result:
            raise DuplicateJsonKey(f"duplicate JSON key: {key}")
        result[key] = value
    return result


def collect_exit_code(status: str) -> int:
    if status == "PASS":
        return RC_PASS
    if status == "FAIL":
        return RC_FAIL
    return RC_INVALID_EVIDENCE


def print_summary(payload: dict[str, object], evidence: Path | None) -> None:
    stage_summary = ",".join(
        f"{stage['name']}={stage['status']}:"
        f"{stage['pass_observation_count']}/"
        f"{len(stage['expected_pass_labels'])}"
        for stage in payload.get("stages", [])
    )
    suffix = f" evidence={evidence}" if evidence is not None else ""
    print(
        "[npc-systemd-transaction] "
        f"protocol={payload['protocol']} status={payload['status']} "
        f"stage_status={payload['stage_status']} "
        f"terminal_status={payload['terminal']['status']} "
        f"stages={stage_summary or 'none'}{suffix}"
    )


def add_common_inputs(parser: argparse.ArgumentParser) -> None:
    parser.add_argument("--console", required=True, type=Path)
    parser.add_argument("--npc-log", type=Path)
    parser.add_argument(
        "--protocol",
        choices=("auto", "legacy-v1", "strict-v2"),
        default="auto",
    )
    parser.add_argument(
        "--terminal-contract",
        choices=("none", "natural-poweroff"),
        default="none",
    )
    parser.add_argument(
        "--producer-closed",
        action="store_true",
        help=(
            "record that the caller observed the console/NPC producer process "
            "return before this snapshot"
        ),
    )


def parse_cli(argv: list[str]) -> tuple[str, argparse.Namespace]:
    mode = argv[0] if argv and argv[0] in {"collect", "verify"} else "collect"
    mode_argv = argv[1:] if argv and argv[0] in {"collect", "verify"} else argv
    parser = EvidenceArgumentParser(
        prog=f"{Path(sys.argv[0]).name} {mode}",
        description="Collect or verify bounded NPC RV64 systemd transaction evidence",
    )
    add_common_inputs(parser)
    if mode == "collect":
        parser.add_argument("--json-out", required=True, type=Path)
    else:
        parser.add_argument("--evidence", required=True, type=Path)
        parser.add_argument(
            "--require-status",
            choices=("PASS", "FAIL", "INVALID_EVIDENCE"),
        )
    args = parser.parse_args(mode_argv)
    if args.terminal_contract == "natural-poweroff" and args.npc_log is None:
        raise UsageError("--npc-log is required for natural-poweroff")
    input_paths = [resolved(args.console)]
    if args.npc_log is not None:
        input_paths.append(resolved(args.npc_log))
    output_path = args.json_out if mode == "collect" else args.evidence
    if resolved(output_path) in input_paths:
        raise UsageError("evidence path must be distinct from console and NPC log")
    return mode, args


def run_collect(args: argparse.Namespace) -> int:
    try:
        remove_stale_output(args.json_out)
    except OSError as error:
        print(
            f"[npc-systemd-transaction] output preclear failed: {error}",
            file=sys.stderr,
        )
        return RC_OUTPUT

    payload = collect_payload(
        args.console,
        args.npc_log,
        args.protocol,
        args.terminal_contract,
        args.producer_closed,
    )
    try:
        atomic_write(args.json_out, canonical_json_bytes(payload))
    except OSError as error:
        print(
            f"[npc-systemd-transaction] atomic evidence write failed: {error}",
            file=sys.stderr,
        )
        return RC_OUTPUT
    print_summary(payload, args.json_out)
    if payload["status"] != "PASS":
        for error in payload["errors"]:
            label = "INVALID" if payload["status"] == "INVALID_EVIDENCE" else "GAP"
            print(f"[npc-systemd-transaction] {label}: {error}", file=sys.stderr)
    return collect_exit_code(str(payload["status"]))


def run_verify(args: argparse.Namespace) -> int:
    try:
        actual = args.evidence.read_bytes()
    except OSError as error:
        print(
            f"[npc-systemd-transaction] verification mismatch: "
            f"evidence read failed: {error}",
            file=sys.stderr,
        )
        return RC_VERIFY_MISMATCH
    try:
        decoded = actual.decode("utf-8", errors="strict")
        parsed = json.loads(decoded, object_pairs_hook=duplicate_key_guard)
    except (UnicodeError, json.JSONDecodeError, DuplicateJsonKey) as error:
        print(
            f"[npc-systemd-transaction] verification mismatch: "
            f"non-canonical JSON: {error}",
            file=sys.stderr,
        )
        return RC_VERIFY_MISMATCH
    if not isinstance(parsed, dict):
        print(
            "[npc-systemd-transaction] verification mismatch: root is not an object",
            file=sys.stderr,
        )
        return RC_VERIFY_MISMATCH

    expected_payload = collect_payload(
        args.console,
        args.npc_log,
        args.protocol,
        args.terminal_contract,
        args.producer_closed,
    )
    expected = canonical_json_bytes(expected_payload)
    if actual != expected:
        print(
            "[npc-systemd-transaction] verification mismatch: "
            f"actual_sha256={sha256_bytes(actual)} "
            f"expected_sha256={sha256_bytes(expected)}",
            file=sys.stderr,
        )
        return RC_VERIFY_MISMATCH
    if parsed != expected_payload:
        print(
            "[npc-systemd-transaction] verification mismatch: parsed receipt differs",
            file=sys.stderr,
        )
        return RC_VERIFY_MISMATCH

    print_summary(expected_payload, args.evidence)
    if args.require_status is not None and expected_payload["status"] != args.require_status:
        print(
            "[npc-systemd-transaction] required status mismatch: "
            f"required={args.require_status} actual={expected_payload['status']}",
            file=sys.stderr,
        )
        return RC_FAIL
    return RC_PASS


def main(argv: list[str] | None = None) -> int:
    try:
        mode, args = parse_cli(list(sys.argv[1:] if argv is None else argv))
        return run_collect(args) if mode == "collect" else run_verify(args)
    except UsageError as error:
        print(f"[npc-systemd-transaction] usage: {error}", file=sys.stderr)
        return RC_USAGE
    except (KeyboardInterrupt, SystemExit):
        raise
    except BaseException as error:
        print(
            f"[npc-systemd-transaction] internal error: "
            f"{type(error).__name__}: {error}",
            file=sys.stderr,
        )
        return RC_INTERNAL


if __name__ == "__main__":
    raise SystemExit(main())
