#!/usr/bin/env python3
"""Fail-closed parser for SQ idle-fusion qualification markers.

The simulator emits one PC-bounded region marker and one whole-run marker.
This parser deliberately treats their field order, integer domain, local
conservation, and region-to-final containment as part of the versioned ABI.
"""

from __future__ import annotations

import argparse
import json
import pathlib
import re
import sys
from typing import Iterable


SCHEMA = "npc-rv64-sq-idle-fusion-qualification-v1"
REGION_MARKER = "SQ_IDLE_FUSION_REGION"
FINAL_MARKER = "SQ_IDLE_FUSION_FINAL"
STATUS = "SQ_IDLE_FUSION_QUALIFIED"
UINT64_MAX = (1 << 64) - 1
ANSI_RE = re.compile(r"\x1b\[[0-9;]*m")

FIELDS = (
    "schema",
    "complete",
    "available",
    "overflow",
    "malformed",
    "cycles",
    "prequal",
    "exact",
    "identity_or_lq_reject",
    "allow",
    "forward",
    "replay",
    "invalid",
    "allow_rob_head",
    "conservation",
)
BOOLEAN_FIELDS = (
    "complete", "available", "overflow", "malformed", "conservation",
)
COUNTER_FIELDS = (
    "cycles",
    "prequal",
    "exact",
    "identity_or_lq_reject",
    "allow",
    "forward",
    "replay",
    "invalid",
    "allow_rob_head",
)


class QualificationError(ValueError):
    """The log cannot support the v1 SQ idle-fusion qualification claim."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise QualificationError(message)


def _marker_line(lines: Iterable[str], marker: str) -> str:
    prefix = f"sq_idle_fusion] {marker}"
    matches: list[str] = []
    occurrences = 0
    for line in lines:
        count = line.count(prefix)
        occurrences += count
        if count:
            matches.append(line)

    require(occurrences == 1,
            f"expected exactly one {marker} marker, found {occurrences}")
    line = matches[0]
    payload_offset = line.index(prefix) + len(prefix)
    require(payload_offset < len(line) and line[payload_offset] == " ",
            f"{marker} marker is missing its payload delimiter")
    return line


def _uint64(text: str, label: str) -> int:
    require(re.fullmatch(r"[0-9]+", text) is not None,
            f"{label} is not an unsigned decimal integer")
    value = int(text, 10)
    require(value <= UINT64_MAX, f"{label} exceeds uint64")
    return value


def _parse_marker(lines: list[str], marker: str) -> dict[str, int | str]:
    line = _marker_line(lines, marker)
    token = f"sq_idle_fusion] {marker} "
    payload = line.split(token, 1)[1]
    words = payload.split()
    require(all(word.count("=") == 1 for word in words),
            f"{marker} contains a malformed field")
    pairs = [word.split("=", 1) for word in words]
    keys = [key for key, _ in pairs]
    require(len(keys) == len(set(keys)), f"{marker} contains a duplicate field")
    require(tuple(keys) == FIELDS,
            f"{marker} field list or order does not match the v1 ABI")

    raw = dict(pairs)
    require(raw["schema"] == SCHEMA, f"{marker} schema mismatch")
    values: dict[str, int | str] = {"schema": raw["schema"]}
    for key in FIELDS[1:]:
        values[key] = _uint64(raw[key], f"{marker}.{key}")
    for key in BOOLEAN_FIELDS:
        require(values[key] in (0, 1), f"{marker}.{key} is not boolean")
    return values


def _validate_scope(values: dict[str, int | str], marker: str) -> None:
    counters = {key: int(values[key]) for key in COUNTER_FIELDS}
    cycles = counters["cycles"]
    require(cycles > 0, f"{marker}.cycles must be positive")
    require(int(values["available"]) == 1, f"{marker} is unavailable")
    require(int(values["overflow"]) == 0, f"{marker} reports overflow")
    require(int(values["malformed"]) == 0, f"{marker} reports malformed input")
    require(int(values["conservation"]) == 1,
            f"{marker} conservation marker is false")
    require(int(values["complete"]) == 1, f"{marker} is incomplete")

    prequal = counters["prequal"]
    exact = counters["exact"]
    allow = counters["allow"]
    forward = counters["forward"]
    replay = counters["replay"]
    invalid = counters["invalid"]
    allow_rob_head = counters["allow_rob_head"]
    reject = counters["identity_or_lq_reject"]

    require(prequal >= exact, f"{marker} has exact greater than prequal")
    require(reject == prequal - exact,
            f"{marker} identity_or_lq_reject mismatch")
    require(exact == allow + forward + replay + invalid,
            f"{marker} exact decision partition does not conserve")
    require(allow_rob_head <= allow,
            f"{marker} allow_rob_head exceeds allow")
    require(invalid == 0,
            f"{marker} contains a non-onehot exact decision")

    lane_capacity = 2 * cycles
    for key in COUNTER_FIELDS[1:]:
        require(counters[key] <= lane_capacity,
                f"{marker}.{key} exceeds two-lane cycle capacity")


def parse_text(text: str) -> dict[str, object]:
    require(isinstance(text, str), "log text must be a string")
    clean = ANSI_RE.sub("", text)
    lines = clean.splitlines()
    region = _parse_marker(lines, REGION_MARKER)
    final = _parse_marker(lines, FINAL_MARKER)
    _validate_scope(region, REGION_MARKER)
    _validate_scope(final, FINAL_MARKER)

    for key in COUNTER_FIELDS:
        require(int(region[key]) <= int(final[key]),
                f"region.{key} exceeds final.{key}")

    return {
        "schema": SCHEMA,
        "status": STATUS,
        "region": region,
        "final": final,
    }


def parse_log(path: pathlib.Path) -> dict[str, object]:
    try:
        text = path.read_text(encoding="utf-8")
    except (OSError, UnicodeDecodeError) as exc:
        raise QualificationError(f"cannot read SQ idle-fusion log: {exc}") from exc
    return parse_text(text)


def _write_json(path: pathlib.Path, value: dict[str, object]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(
        json.dumps(value, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    temporary.replace(path)


def argument_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Validate SQ current-head idle-fusion qualification markers")
    parser.add_argument("log", type=pathlib.Path, help="raw simulator log")
    parser.add_argument(
        "--output", type=pathlib.Path,
        help="optional JSON receipt; stdout is used when omitted")
    return parser


def main(argv: list[str] | None = None) -> int:
    args = argument_parser().parse_args(argv)
    try:
        result = parse_log(args.log)
        if args.output is None:
            print(json.dumps(result, indent=2, sort_keys=True))
        else:
            _write_json(args.output, result)
    except QualificationError as exc:
        print(f"[sq-idle-fusion] ERROR {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
