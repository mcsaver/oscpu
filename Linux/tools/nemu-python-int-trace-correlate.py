#!/usr/bin/env python3
"""Correlate PyLong object markers with NEMU write-value trace lines."""

import argparse
import re
import sys


PREFLIGHT_RE = re.compile(r"__PYTHON_INT_PREFLIGHT_([^_\s].*?)__:(.*)")
VALUE_TOKEN_RE = re.compile(r"-?0x[0-9a-fA-F]+|-?\d+")
VALUE_TRACE_RE = re.compile(
    r"vaddr-write-value-trace count=(?P<count>\d+) "
    r"match=(?P<match>\S+) byte_offset=(?P<byte_offset>\d+) "
    r"vaddr=(?P<vaddr>0x[0-9a-fA-F]+) "
    r"paddr=(?P<paddr>0x[0-9a-fA-F]+) "
    r"len=(?P<len>\d+) data=(?P<data>0x[0-9a-fA-F]+) "
    r"value=(?P<value>0x[0-9a-fA-F]+) "
    r"mask=(?P<mask>0x[0-9a-fA-F]+) "
    r"pc=(?P<pc>0x[0-9a-fA-F]+) priv=(?P<priv>\d+) "
    r"satp=(?P<satp>0x[0-9a-fA-F]+) host_fast=(?P<host_fast>\d+)"
)


def parse_int(text):
    return int(text, 0)


def first_value_token(text):
    match = VALUE_TOKEN_RE.search(text)
    if match is not None:
        return match.group(0)
    return text.strip()


def early_prefix_for(base):
    if base.startswith("PYLONG_"):
        base = base[len("PYLONG_"):]
    return "PYLONG_%s_EARLY" % base


def is_bad_ob_size(value_text):
    try:
        value = int(value_text, 0)
    except ValueError:
        return True
    return value != 1


def parse_console(path):
    markers = {}
    targets = []
    value_hits = []

    with open(path, "r", encoding="utf-8", errors="replace") as source:
        for lineno, line in enumerate(source, 1):
            line = line.rstrip("\n")
            marker_match = PREFLIGHT_RE.search(line)
            if marker_match is not None:
                name, value = marker_match.groups()
                value = first_value_token(value)
                markers[name] = {"value": value, "line": lineno}
                if name.endswith("_ERROR_STATE_OB_SIZE") and is_bad_ob_size(value):
                    base = name[: -len("_ERROR_STATE_OB_SIZE")]
                    early = early_prefix_for(base)
                    id_marker = markers.get("%s_ERROR_STATE_ID" % base)
                    early_id_marker = markers.get("%s_ID" % early)
                    vaddr_marker = markers.get("%s_OB_SIZE_VADDR" % early)
                    paddr_marker = markers.get("%s_OB_SIZE_PADDR" % early)
                    targets.append({
                        "base": base,
                        "ob_size": value,
                        "line": lineno,
                        "id": id_marker["value"] if id_marker is not None else "",
                        "early_id": (
                            early_id_marker["value"] if early_id_marker is not None else ""),
                        "vaddr": (
                            vaddr_marker["value"] if vaddr_marker is not None else ""),
                        "paddr": (
                            paddr_marker["value"] if paddr_marker is not None else ""),
                    })
                continue

            trace_match = VALUE_TRACE_RE.search(line)
            if trace_match is not None:
                hit = trace_match.groupdict()
                hit["line"] = lineno
                hit["vaddr_int"] = parse_int(hit["vaddr"])
                hit["paddr_int"] = parse_int(hit["paddr"])
                hit["len_int"] = int(hit["len"])
                value_hits.append(hit)

    return targets, value_hits


def overlaps(addr, size, target):
    return addr <= target < addr + size


def correlate(targets, value_hits):
    correlated = []
    for index, target in enumerate(targets):
        vaddr = parse_int(target["vaddr"]) if target["vaddr"] else None
        paddr = parse_int(target["paddr"]) if target["paddr"] else None
        for hit in value_hits:
            hit_by_vaddr = vaddr is not None and overlaps(
                hit["vaddr_int"], hit["len_int"], vaddr)
            hit_by_paddr = paddr is not None and overlaps(
                hit["paddr_int"], hit["len_int"], paddr)
            if hit_by_vaddr or hit_by_paddr:
                correlated.append((index, target, hit, hit_by_vaddr, hit_by_paddr))
    return correlated


def main(argv):
    parser = argparse.ArgumentParser()
    parser.add_argument("console_log")
    args = parser.parse_args(argv)

    targets, value_hits = parse_console(args.console_log)
    correlated = correlate(targets, value_hits)

    print("__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGETS__:%d" % len(targets))
    for index, target in enumerate(targets):
        print("__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGET__:%d:%s:%s:%s:%s:%s:%s" % (
            index, target["base"], target["ob_size"], target["id"],
            target["early_id"], target["vaddr"], target["paddr"]))
    print("__NEMU_PYTHON_INT_TRACE_CORRELATE_VALUE_HITS__:%d" % len(value_hits))
    print("__NEMU_PYTHON_INT_TRACE_CORRELATE_TARGET_HITS__:%d" % len(correlated))
    for index, target, hit, by_vaddr, by_paddr in correlated:
        print("__NEMU_PYTHON_INT_TRACE_CORRELATE_HIT__:%d:%s:%s:%s:%s:%s:%s:%s:%s:%s" % (
            index, target["base"], hit["line"], hit["match"], hit["vaddr"],
            hit["paddr"], hit["len"], hit["pc"], int(by_vaddr), int(by_paddr)))
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
