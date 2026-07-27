#!/usr/bin/env python3
"""Parse bounded NPC RV64 systemd guest transactions from a console log.

The parser deliberately counts every exact marker line.  It never de-duplicates
PASS/FAIL events and never borrows a label from an earlier transaction stage.
"""

from __future__ import annotations

import argparse
import collections
import hashlib
import json
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable


SCHEMA = "npc-rv64-systemd-transaction-evidence/v1"
ANSI_RE = re.compile(r"\x1b(?:\[[0-?]*[ -/]*[@-~]|\][^\x07]*(?:\x07|\x1b\\))")

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


def normalized_lines(raw: bytes) -> list[str]:
    text = raw.decode("utf-8", errors="replace")
    text = text.replace("\r\n", "\n").replace("\r", "\n")
    return [ANSI_RE.sub("", line).strip() for line in text.splitlines()]


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


def parse_console(console: Path, requested_protocol: str = "auto") -> dict[str, object]:
    raw = console.read_bytes()
    lines = normalized_lines(raw)
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
    if protocol == "strict-v2":
        mixed = [
            (index, line)
            for index, line in enumerate(lines, start=1)
            if any(line.startswith(stem) for stem in legacy_structural_stems)
        ]
        if mixed:
            errors.append(
                "protocol: strict-v2 console contains legacy-v1 structural marker(s): "
                + ", ".join(f"L{index}={line}" for index, line in mixed)
            )
    else:
        mixed = [
            (index, line)
            for index, line in enumerate(lines, start=1)
            if any(line.startswith(stem) for stem in v2_structural_stems)
        ]
        if mixed:
            errors.append(
                "protocol: legacy-v1 console contains strict-v2 structural marker(s): "
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
            positions = exact_positions(lines, spec.begin)
            begin_by_stage[spec.name] = positions

    done_by_stage: dict[str, list[tuple[int, int, str]]] = {}
    for spec in specs:
        positions = done_positions(lines, spec)
        done_by_stage[spec.name] = positions

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
            window_start = 1
            window_end = 0
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
                    window_end - window_start + 1
                    if window_start <= window_end
                    else 0
                ),
                "expected_pass_labels": list(spec.expected_labels),
                "observed_pass_counts": {
                    label: pass_counts[label]
                    for label in sorted(pass_counts)
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
                f"protocol: reserved marker outside its bounded stage at "
                f"L{line_no}: {line}"
            )

    if any(line == "__NPC_SYSTEMD_POWEROFF_CMD_FAIL__" for line in lines):
        errors.append("terminal: guest poweroff command reported failure")

    return {
        "schema": SCHEMA,
        "status": "PASS" if not errors else "FAIL",
        "protocol": protocol,
        "requested_protocol": requested_protocol,
        "console": {
            "path": str(console),
            "sha256": hashlib.sha256(raw).hexdigest(),
            "size_bytes": len(raw),
            "line_count": len(lines),
        },
        "stage_order": [spec.name for spec in specs],
        "stages": stages,
        "errors": errors,
    }


def write_json(path: Path, payload: dict[str, object]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(payload, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Validate bounded NPC RV64 systemd console transactions"
    )
    parser.add_argument("--console", required=True, type=Path)
    parser.add_argument(
        "--protocol",
        choices=("auto", "legacy-v1", "strict-v2"),
        default="auto",
    )
    parser.add_argument("--json-out", required=True, type=Path)
    args = parser.parse_args(argv)

    try:
        payload = parse_console(args.console, args.protocol)
    except (OSError, UnicodeError) as error:
        payload = {
            "schema": SCHEMA,
            "status": "FAIL",
            "protocol": args.protocol,
            "requested_protocol": args.protocol,
            "console": {"path": str(args.console)},
            "stage_order": [],
            "stages": [],
            "errors": [f"console read failed: {error}"],
        }

    try:
        write_json(args.json_out, payload)
    except OSError as error:
        print(
            f"[npc-systemd-transaction] JSON evidence write failed: {error}",
            file=sys.stderr,
        )
        return 2

    stage_summary = ",".join(
        f"{stage['name']}={stage['status']}:"
        f"{stage['pass_observation_count']}/"
        f"{len(stage['expected_pass_labels'])}"
        for stage in payload.get("stages", [])
    )
    print(
        "[npc-systemd-transaction] "
        f"protocol={payload['protocol']} status={payload['status']} "
        f"stages={stage_summary or 'none'} "
        f"evidence={args.json_out}"
    )
    if payload["status"] != "PASS":
        for error in payload.get("errors", []):
            print(f"[npc-systemd-transaction] GAP: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
