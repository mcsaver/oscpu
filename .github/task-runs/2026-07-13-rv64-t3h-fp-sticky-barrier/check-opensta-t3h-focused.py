#!/usr/bin/env python3
"""Fail closed on T3H directed OpenSTA evidence."""

from __future__ import annotations

import re
import sys
from pathlib import Path


REQUIRED_COUNTS = (
    "dcache_rdata",
    "int_ex0_d",
    "int_ex1_d",
    "fp_exec1_d",
    "fpiq_q",
    "fpprf_q",
    "fetch_payload_en",
    "fpiq_wake0",
    "fpiq_wake1",
    "intiq_wake0",
    "intiq_wake1",
    "fpprf_write0",
    "fpprf_write1",
    "fpprf_read0",
    "fpprf_read1",
    "fpprf_read2",
    "fpprf_read3",
)

EXPECTED_COUNTS = {
    "dcache_rdata": 113,
    "int_ex0_d": 145,
    "int_ex1_d": 145,
    "fp_exec1_d": 82,
    "fetch_payload_en": 1,
    "fpiq_wake0": 7,
    "fpiq_wake1": 7,
    "intiq_wake0": 7,
    "intiq_wake1": 7,
    "fpprf_write0": 71,
    "fpprf_write1": 71,
    "fpprf_read0": 64,
    "fpprf_read1": 64,
    "fpprf_read2": 64,
    "fpprf_read3": 64,
}

LEGAL_RESIDUAL_REPORTS = (
    "opensta-t3h-dcache-to-int-ex0-d.rpt",
    "opensta-t3h-dcache-to-int-ex1-d.rpt",
    "opensta-t3h-dcache-to-fp-exec1-d.rpt",
)

FORBIDDEN_REPORTS = (
    "opensta-t3h-fpiq-wake0-to-fp-exec1-d.rpt",
    "opensta-t3h-fpiq-wake1-to-fp-exec1-d.rpt",
    "opensta-t3h-intiq-wake0-to-int-ex0-d.rpt",
    "opensta-t3h-intiq-wake0-to-int-ex1-d.rpt",
    "opensta-t3h-intiq-wake1-to-int-ex0-d.rpt",
    "opensta-t3h-intiq-wake1-to-int-ex1-d.rpt",
    "opensta-t3h-fpprf-write0-to-fp-exec1-d.rpt",
    "opensta-t3h-fpprf-write0-to-int-ex0-d.rpt",
    "opensta-t3h-fpprf-write0-to-int-ex1-d.rpt",
    "opensta-t3h-fpprf-write1-to-fp-exec1-d.rpt",
    "opensta-t3h-fpprf-write1-to-int-ex0-d.rpt",
    "opensta-t3h-fpprf-write1-to-int-ex1-d.rpt",
    "opensta-t3h-fpprf-write0-to-read0-data.rpt",
    "opensta-t3h-fpprf-write0-to-read1-data.rpt",
    "opensta-t3h-fpprf-write0-to-read2-data.rpt",
    "opensta-t3h-fpprf-write0-to-read3-data.rpt",
    "opensta-t3h-fpprf-write1-to-read0-data.rpt",
    "opensta-t3h-fpprf-write1-to-read1-data.rpt",
    "opensta-t3h-fpprf-write1-to-read2-data.rpt",
    "opensta-t3h-fpprf-write1-to-read3-data.rpt",
)

FANOUT_REPORTS = (
    "opensta-t3h-fpiq-wake0-fanout-endpoints.txt",
    "opensta-t3h-fpiq-wake1-fanout-endpoints.txt",
    "opensta-t3h-intiq-wake0-fanout-endpoints.txt",
    "opensta-t3h-intiq-wake1-fanout-endpoints.txt",
    "opensta-t3h-fpprf-write0-fanout-endpoints.txt",
    "opensta-t3h-fpprf-write1-fanout-endpoints.txt",
)


def fail(message: str) -> None:
    print(f"[T3H-STA-CHECK] FAIL: {message}", file=sys.stderr)
    raise SystemExit(1)


def parse_kv(text: str) -> dict[str, int]:
    values: dict[str, int] = {}
    for line in text.splitlines():
        match = re.fullmatch(r"([A-Za-z0-9_]+)=([0-9]+)", line.strip())
        if match:
            values[match.group(1)] = int(match.group(2))
    return values


def main() -> None:
    if len(sys.argv) != 2:
        fail("usage: check-opensta-t3h-focused.py OUT_DIR")
    out_dir = Path(sys.argv[1]).resolve()
    complete_path = out_dir / "opensta-t3h-focused-complete.txt"
    if not complete_path.is_file():
        fail(f"missing completion sentinel: {complete_path}")
    if complete_path.read_text(errors="replace").strip() != "status=COMPLETE":
        fail(f"invalid completion sentinel: {complete_path}")
    counts_path = out_dir / "opensta-t3h-focused-counts.txt"
    if not counts_path.is_file():
        fail(f"missing counts: {counts_path}")
    counts = parse_kv(counts_path.read_text(errors="replace"))
    for label in REQUIRED_COUNTS:
        if counts.get(label, 0) <= 0:
            fail(f"empty required collection: {label}={counts.get(label, 0)}")
    for label, expected in EXPECTED_COUNTS.items():
        if counts.get(label) != expected:
            fail(
                f"partial/misbound collection: {label}={counts.get(label)} "
                f"expected={expected}"
            )

    # T3H removes the long FP-load wake/data path, not every DCache-driven
    # resource-control arc.  The surviving directed paths must therefore be
    # real, non-empty paths that all meet 5 ns; accepting NO_TIMING_PATH here
    # would hide a collection/binding regression, while requiring a full cut
    # would reject the intentional short control residuals.
    for name in LEGAL_RESIDUAL_REPORTS:
        path = out_dir / name
        if not path.is_file():
            fail(f"missing legal-residual report: {name}")
        text = path.read_text(errors="replace")
        if "status=EMPTY_COLLECTION" in text:
            fail(f"empty legal-residual collection: {name}")
        if "status=NO_TIMING_PATH" in text:
            fail(f"legal residual unexpectedly disappeared: {name}")
        if "slack (MET)" not in text:
            fail(f"legal residual has no met timing path: {name}")
        if "slack (VIOLATED)" in text:
            fail(f"legal residual violates 5 ns: {name}")

    for name in FORBIDDEN_REPORTS:
        path = out_dir / name
        if not path.is_file():
            fail(f"missing forbidden-path report: {name}")
        text = path.read_text(errors="replace")
        if "status=EMPTY_COLLECTION" in text:
            fail(f"empty collection masquerading as cut: {name}")
        if not re.fullmatch(
            r"status=NO_TIMING_PATH from_count=[1-9][0-9]* "
            r"to_count=[1-9][0-9]*",
            text.strip(),
        ):
            fail(f"same-cycle timing path still exists: {name}")

    forbidden_endpoint_fragments = (
        "/u_ex0_stage/",
        "/u_ex1_stage/",
        "/u_exec1_stage/",
    )
    endpoint_owner = {
        "opensta-t3h-fpiq-wake0-fanout-endpoints.txt":
            "/u_fp_backend/u_fp_issue_queue/",
        "opensta-t3h-fpiq-wake1-fanout-endpoints.txt":
            "/u_fp_backend/u_fp_issue_queue/",
        "opensta-t3h-intiq-wake0-fanout-endpoints.txt":
            "/u_dispatch_backend/u_issue_queue/",
        "opensta-t3h-intiq-wake1-fanout-endpoints.txt":
            "/u_dispatch_backend/u_issue_queue/",
        "opensta-t3h-fpprf-write0-fanout-endpoints.txt":
            "/u_fp_backend/u_fp_phys_reg_file/",
        "opensta-t3h-fpprf-write1-fanout-endpoints.txt":
            "/u_fp_backend/u_fp_phys_reg_file/",
    }
    for name in FANOUT_REPORTS:
        path = out_dir / name
        if not path.is_file():
            fail(f"missing fanout evidence: {name}")
        text = path.read_text(errors="replace")
        values = parse_kv(text)
        if values.get("source_count", 0) <= 0:
            fail(f"empty fanout source collection: {name}")
        if values.get("endpoint_count", 0) <= 0:
            fail(f"empty fanout endpoint collection: {name}")
        for fragment in forbidden_endpoint_fragments:
            if fragment in text:
                fail(f"fanout reaches execute stage ({fragment}): {name}")
        owner_fragment = endpoint_owner[name]
        endpoint_lines = [line for line in text.splitlines()[2:] if line]
        if len(endpoint_lines) != values["endpoint_count"]:
            fail(
                f"fanout endpoint body truncated: {name}: "
                f"header={values['endpoint_count']} actual={len(endpoint_lines)}"
            )
        for endpoint in endpoint_lines:
            if endpoint and owner_fragment not in endpoint:
                fail(
                    f"fanout escapes state owner {owner_fragment}: "
                    f"{name}: {endpoint}"
                )
            if not endpoint.endswith(("/D", "/E")):
                fail(f"fanout endpoint is not state D/E: {name}: {endpoint}")

    print(
        "[T3H-STA-CHECK] PASS: collections non-empty; "
        f"{len(LEGAL_RESIDUAL_REPORTS)} legal residuals meet 5 ns; "
        f"{len(FORBIDDEN_REPORTS)} forbidden paths cut; fanouts state-only"
    )


if __name__ == "__main__":
    main()
