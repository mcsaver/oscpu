#!/usr/bin/env python3
"""Build fail-closed local RV64 IFU-AXI-G1 current-design evidence."""

from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import os
import pathlib
import re
import subprocess
import sys
from typing import Any, Sequence


SCHEMA = "npc-rv64-ifu-axi-flush-drain-evidence-v1"
MUTATION_SCHEMA = "npc-rv64-ifu-axi-flush-drain-rtl-variants-v1"
RUN_ID = "2026-07-22-rv64-v9g-ifu-axi-current-design"
CANONICAL_COMMAND = (
    "/usr/bin/env -u MAKEFLAGS -u MFLAGS -u MAKELEVEL -u GNUMAKEFLAGS "
    "-u MAKEFILES /usr/bin/make -rR --no-print-directory -C npc/rv64 "
    "-f eval/ppa/ifu-evidence.mk check-ifu-axi-flush-drain"
)
CANONICAL_TARGET = "check-ifu-axi-flush-drain"
CANONICAL_DISPATCH_FILE = "npc/rv64/eval/ppa/ifu-evidence.mk"
CANONICAL_RUNNER = f".github/task-runs/{RUN_ID}/run-focused.sh"
CANONICAL_DISPATCH_BLOCK = (
    ".PHONY: check-ifu-axi-flush-drain\n"
    "check-ifu-axi-flush-drain:\n"
    "\t@bash ../../.github/task-runs/"
    f"{RUN_ID}/run-focused.sh"
)
REPO = pathlib.Path(__file__).resolve().parents[5]

ARCH_TOOL = pathlib.Path(__file__).with_name("architecture_hard_gates.py")
ARCH_SPEC = importlib.util.spec_from_file_location(
    "architecture_hard_gates_ifu_axi", ARCH_TOOL)
assert ARCH_SPEC is not None and ARCH_SPEC.loader is not None
arch = importlib.util.module_from_spec(ARCH_SPEC)
sys.modules[ARCH_SPEC.name] = arch
ARCH_SPEC.loader.exec_module(arch)

VARIANT_RUNNER = REPO / f".github/task-runs/{RUN_ID}/run-ifu-axi-variants.py"
VARIANT_SPEC = importlib.util.spec_from_file_location(
    "ifu_axi_flush_drain_variants", VARIANT_RUNNER)
assert VARIANT_SPEC is not None and VARIANT_SPEC.loader is not None
variant_model = importlib.util.module_from_spec(VARIANT_SPEC)
sys.modules[VARIANT_SPEC.name] = variant_model
VARIANT_SPEC.loader.exec_module(variant_model)

BRIDGE_RE = re.compile(
    r"^\[IFU-AXI-G1-FOCUSED\] aw_first=(\d+) w_first=(\d+) "
    r"first_aw_with_flush=(\d+) first_w_with_flush=(\d+) "
    r"last_aw_b_with_flush=(\d+) last_w_b_with_flush=(\d+) "
    r"all_aw_w_b_with_flush=(\d+) both_done_flush_b_error=(\d+) "
    r"both_stalled_flush_cycles=(\d+) dropped_bresp_error=(\d+) "
    r"normal_bresp_error=(\d+) payload_stability=(\d+) "
    r"drop_quiet=(\d+) PASS$",
    re.MULTILINE,
)
XBAR_INTEGRATION_RE = re.compile(
    r"^\[IFU-AXI-G1-XBAR\] ifu_b_owner_release=(\d+) "
    r"later_master_progress=(\d+) later_master_payload=(\d+) "
    r"later_master_b=(\d+) PASS$",
    re.MULTILINE,
)
XBAR_BACKPRESSURE_RE = re.compile(
    r"^\[IFU-AXI-G1-XBAR-BACKPRESSURE\] bvalid_hold_cycles=(\d+) "
    r"early_release=(\d+) aw_first=(\d+) w_first=(\d+) "
    r"payload_stability=(\d+) PASS$",
    re.MULTILINE,
)

BRIDGE_METRICS = {
    "aw_first": 1,
    "w_first": 1,
    "first_aw_with_flush": 1,
    "first_w_with_flush": 1,
    "last_aw_b_with_flush": 1,
    "last_w_b_with_flush": 1,
    "all_aw_w_b_with_flush": 1,
    "both_done_flush_b_error": 1,
    "both_stalled_flush_cycles": 2,
    "dropped_bresp_error": 1,
    "normal_bresp_error": 1,
    "payload_stability": 1,
    "drop_quiet": 1,
}
XBAR_INTEGRATION_METRICS = {
    "ifu_b_owner_release": 1,
    "later_master_progress": 1,
    "later_master_payload": 1,
    "later_master_b": 1,
}
XBAR_BACKPRESSURE_METRICS = {
    "bvalid_hold_cycles": 2,
    "early_release": 0,
    "aw_first": 1,
    "w_first": 1,
    "payload_stability": 1,
}

INVARIANTS = {
    "aw_and_w_channels_accept_independently": True,
    "flush_preserves_pending_channel_valid_and_payload": True,
    "flush_cycle_aw_and_w_fire_are_recorded": True,
    "completion_uses_current_cycle_aw_and_w_fire": True,
    "current_cycle_flush_dominates_bresp_at_completion": True,
    "semantic_drop_is_sticky_until_b_completion": True,
    "drop_owner_blocks_fetch_response_and_read_address": True,
    "drop_completion_returns_idle_without_rewalk": True,
    "non_drop_bresp_error_remains_instruction_access_fault": True,
    "xbar_releases_write_owner_only_on_exact_b_fire": True,
    "xbar_accepts_aw_first_and_w_first_master_presentation": True,
    "later_master_progress_preserves_address_data_and_response": True,
}


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def sha256_file(path: pathlib.Path) -> str:
    return sha256_bytes(path.read_bytes())


def safe_file(root: pathlib.Path, path: pathlib.Path) -> pathlib.Path:
    resolved = path.resolve(strict=True)
    if not resolved.is_relative_to(root):
        raise ValueError(f"artifact escapes repository: {resolved}")
    if path.is_symlink() or not resolved.is_file():
        raise ValueError(f"artifact is not a regular non-symlink file: {path}")
    return resolved


def artifact(root: pathlib.Path, path: pathlib.Path, kind: str) -> dict[str, str]:
    resolved = safe_file(root, path)
    return {
        "kind": kind,
        "path": resolved.relative_to(root).as_posix(),
        "sha256": sha256_file(resolved),
    }


def require_pass_log(text: str, test_name: str, label: str) -> None:
    accepted = {f"[PASS] {test_name}", f"PASS {test_name}"}
    if len([line for line in text.splitlines() if line in accepted]) != 1:
        raise ValueError(f"{label}: expected one exact test PASS line")
    if text.count("[RESULT] PASS") != 1:
        raise ValueError(f"{label}: expected one exact marker [RESULT] PASS")
    for marker in ("[RESULT] FAIL", "[CHECK-FAIL]", "FATAL:", "ERROR:"):
        if marker in text:
            raise ValueError(f"{label}: unexpected failure marker {marker}")


def parse_marker(
    regex: re.Pattern[str],
    text: str,
    names: tuple[str, ...],
    expected: dict[str, int],
    label: str,
) -> dict[str, int]:
    matches = list(regex.finditer(text))
    if len(matches) != 1:
        raise ValueError(f"{label}: expected one exact semantic marker")
    metrics = dict(zip(
        names, (int(value) for value in matches[0].groups()), strict=True))
    if metrics != expected:
        raise ValueError(f"{label}: event inventory drifted: {metrics}")
    return metrics


def parse_bridge_log(path: pathlib.Path) -> dict[str, int]:
    text = path.read_text(encoding="utf-8")
    require_pass_log(text, "tb_ooo_fetch_axi_bridge", "IFU bridge log")
    return parse_marker(
        BRIDGE_RE,
        text,
        tuple(BRIDGE_METRICS),
        BRIDGE_METRICS,
        "IFU bridge log",
    )


def parse_xbar_integration_log(path: pathlib.Path) -> dict[str, int]:
    text = path.read_text(encoding="utf-8")
    require_pass_log(
        text, "tb_ooo_fetch_axi_bridge_xbar", "IFU bridge+xbar log")
    return parse_marker(
        XBAR_INTEGRATION_RE,
        text,
        tuple(XBAR_INTEGRATION_METRICS),
        XBAR_INTEGRATION_METRICS,
        "IFU bridge+xbar log",
    )


def parse_xbar_backpressure_log(path: pathlib.Path) -> dict[str, int]:
    text = path.read_text(encoding="utf-8")
    require_pass_log(text, "tb_axi_xbar", "AXI xbar log")
    return parse_marker(
        XBAR_BACKPRESSURE_RE,
        text,
        tuple(XBAR_BACKPRESSURE_METRICS),
        XBAR_BACKPRESSURE_METRICS,
        "AXI xbar log",
    )


def required_module_tests(makefile: pathlib.Path) -> list[str]:
    tests: list[str] = []
    collecting = False
    for line in makefile.read_text(encoding="utf-8").splitlines():
        stripped = line.strip()
        if not collecting:
            if not stripped.startswith("TESTS :="):
                continue
            collecting = True
            stripped = stripped.removeprefix("TESTS :=").strip()
        continued = stripped.endswith("\\")
        payload = stripped[:-1].strip() if continued else stripped
        if payload:
            tests.extend(payload.split())
        if not continued:
            break
    if not tests or len(tests) != len(set(tests)):
        raise ValueError("module TESTS inventory is empty or duplicated")
    if any(not re.fullmatch(r"tb_[a-z0-9_]+", name) for name in tests):
        raise ValueError("module TESTS inventory contains a malformed name")
    return tests


def parse_module_aggregate(
    root: pathlib.Path,
    summary: pathlib.Path,
) -> dict[str, Any]:
    tests = required_module_tests(root / "npc/rv64/testbench/Makefile")
    text = summary.read_text(encoding="utf-8")
    count = len(tests)
    markers = (
        "# NPC single module testbench summary",
        f"- total: {count}", f"- passed: {count}", "- failed: 0",
    )
    if any(text.count(marker) != 1 for marker in markers):
        raise ValueError("module aggregate summary counts are incomplete")
    log_dir = summary.parent / "logs"
    actual_logs = {path.stem for path in log_dir.glob("*.log") if path.is_file()}
    if actual_logs != set(tests):
        raise ValueError("module aggregate log inventory is not exact")
    records: dict[str, dict[str, str]] = {}
    summary_lines = text.splitlines()
    for test_name in tests:
        if summary_lines.count(f"- PASS {test_name}") != 1:
            raise ValueError(f"module aggregate summary missing {test_name}")
        log_path = safe_file(root, log_dir / f"{test_name}.log")
        require_pass_log(
            log_path.read_text(encoding="utf-8"), test_name,
            f"module aggregate {test_name}")
        records[test_name] = {
            "path": log_path.relative_to(root).as_posix(),
            "sha256": sha256_file(log_path),
        }
    return {
        "required": count,
        "passed": count,
        "failed": 0,
        "tests": records,
    }


def reconstruct_variant(root: pathlib.Path, spec: Any) -> tuple[str, str]:
    source = safe_file(root, root / spec.source_rel)
    text = source.read_text(encoding="utf-8")
    if text.count(spec.old) != 1 or spec.old == spec.new:
        raise ValueError(f"{spec.name}: live RTL variant anchor is not unique")
    return text, text.replace(spec.old, spec.new, 1)


def validate_variants(root: pathlib.Path, path: pathlib.Path) -> dict[str, Any]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    specs = {spec.name: spec for spec in variant_model.VARIANTS}
    rows = payload.get("results")
    if not isinstance(rows, list):
        raise ValueError("RTL verification-variant result list is missing")
    by_name = {
        row.get("name"): row for row in rows
        if isinstance(row, dict) and isinstance(row.get("name"), str)
    }
    aggregate_ok = (
        payload.get("schema") == MUTATION_SCHEMA
        and payload.get("suite_run_id") == RUN_ID
        and payload.get("required") == len(specs)
        and payload.get("compile_success") == len(specs)
        and payload.get("dynamic_rejected") == len(specs)
        and payload.get("source_unchanged") is True
        and payload.get("source_sha256_before")
            == payload.get("source_sha256_after")
        and set(by_name) == set(specs)
    )
    if not aggregate_ok:
        raise ValueError("RTL verification-variant aggregate is incomplete")

    verified: list[dict[str, Any]] = []
    source_before: dict[str, str] = {}
    for name, spec in specs.items():
        row = by_name[name]
        original, variant = reconstruct_variant(root, spec)
        original_sha = sha256_bytes(original.encode("utf-8"))
        variant_sha = sha256_bytes(variant.encode("utf-8"))
        log = row.get("log")
        log_path = safe_file(root, root / log.get("path", "")) \
            if isinstance(log, dict) else None
        log_ok = (
            log_path is not None
            and set(log) == {"path", "sha256"}
            and log.get("sha256") == sha256_file(log_path)
        )
        log_text = log_path.read_text(encoding="utf-8") if log_path else ""
        row_ok = (
            row.get("debt_id") == "IFU-AXI-G1"
            and row.get("purpose") == spec.purpose
            and row.get("source") == spec.source_rel
            and row.get("make_variable") == spec.make_variable
            and row.get("test_name") == spec.test_name
            and row.get("original_sha256") == original_sha
            and row.get("variant_sha256") == variant_sha
            and row.get("expected_marker") == spec.expected_marker
            and row.get("compile_success") is True
            and row.get("marker_observed") is True
            and row.get("dynamic_rejected") is True
            and isinstance(row.get("make_returncode"), int)
            and row.get("make_returncode") != 0
            and log_ok
            and variant_model.TRANSIENT_DIR_TOKEN in log_text
            and "/tmp/rv64-v9g-" not in log_text
            and spec.expected_marker in log_text
            and "[RESULT] FAIL status=" in log_text
            and "[RESULT] PASS" not in log_text
        )
        if not row_ok:
            raise ValueError(f"{name}: RTL verification variant is stale")
        source_before[spec.source_rel] = original_sha
        verified.append(dict(row))

    if payload.get("source_sha256_before") != source_before:
        raise ValueError("RTL verification-variant source binding is stale")
    by_source = {
        source: {
            "required": sum(spec.source_rel == source for spec in specs.values()),
            "compile_success": sum(
                row["source"] == source and bool(row["compile_success"])
                for row in verified),
            "dynamic_rejected": sum(
                row["source"] == source and bool(row["dynamic_rejected"])
                for row in verified),
        }
        for source in sorted(source_before)
    }
    return {
        "schema": MUTATION_SCHEMA,
        "required": len(specs),
        "compile_success": len(specs),
        "dynamic_rejected": len(specs),
        "by_source": by_source,
        "source_unchanged": True,
        "results": sorted(verified, key=lambda item: item["name"]),
    }


def validate_canonical_make_dispatch(makefile_text: str) -> None:
    """Validate a literal-only dispatch file before asking Make to parse it."""

    safe_target = r"[A-Za-z0-9_.-]+"
    safe_recipe = re.compile(r"^\t@?[A-Za-z0-9_./ -]+$")
    for line_number, line in enumerate(makefile_text.splitlines(), start=1):
        if not line or line.startswith("#"):
            continue
        if safe_recipe.fullmatch(line):
            continue
        if re.fullmatch(rf"\.PHONY:(?: {safe_target})+", line):
            continue
        if re.fullmatch(rf"{safe_target}:", line):
            continue
        raise ValueError(
            "IFU AXI restricted Make dispatch contains dynamic syntax at "
            f"line {line_number}"
        )

    target_rules = re.findall(
        rf"(?m)^{re.escape(CANONICAL_TARGET)}\s*::?.*$", makefile_text)
    phony_rules = [
        line for line in makefile_text.splitlines()
        if line.startswith(".PHONY:")
        and CANONICAL_TARGET in line.split()[1:]
    ]
    if (
        makefile_text.count(CANONICAL_DISPATCH_BLOCK) != 1
        or target_rules != [f"{CANONICAL_TARGET}:"]
        or phony_rules != [f".PHONY: {CANONICAL_TARGET}"]
    ):
        raise ValueError("IFU AXI canonical Make dispatch drifted")


def validate_effective_make_dispatch(
    make_dir: pathlib.Path,
    dispatch_file: pathlib.Path,
    target: str,
    expected_command: str,
) -> None:
    """Resolve a prevalidated literal recipe in a sanitized Make process."""

    dispatch_path = safe_file(make_dir, make_dir / dispatch_file)
    validate_canonical_make_dispatch(dispatch_path.read_text(encoding="utf-8"))

    env = os.environ.copy()
    for name in (
        "MAKEFLAGS", "MFLAGS", "MAKELEVEL", "GNUMAKEFLAGS", "MAKEFILES",
    ):
        env.pop(name, None)
    env["LC_ALL"] = "C"
    try:
        completed = subprocess.run(
            [
                "/usr/bin/make", "-rR", "--no-print-directory", "-n",
                "-C", str(make_dir), "-f", dispatch_file.as_posix(),
                "SHELL=/bin/false", target,
            ],
            check=False,
            capture_output=True,
            text=True,
            timeout=5,
            env=env,
        )
    except (OSError, subprocess.TimeoutExpired) as exc:
        raise ValueError(f"cannot resolve IFU AXI Make dispatch: {exc}") from exc
    if (
        completed.returncode != 0
        or completed.stdout.splitlines() != [expected_command]
        or completed.stderr.strip()
    ):
        raise ValueError("IFU AXI effective Make recipe drifted")


def validate_static_contract(root: pathlib.Path) -> dict[str, bool]:
    bridge = safe_file(
        root, root / "npc/rv64/vsrc/frontend/OooFetchAxiBridge.v"
    ).read_text(encoding="utf-8")
    xbar = safe_file(
        root, root / "npc/rv64/vsrc/bus/AxiCrossbar.v"
    ).read_text(encoding="utf-8")
    bridge_tb = safe_file(
        root, root / "npc/rv64/testbench/tests/tb_ooo_fetch_axi_bridge.sv"
    ).read_text(encoding="utf-8")
    xbar_tb = safe_file(
        root,
        root / "npc/rv64/testbench/tests/tb_ooo_fetch_axi_bridge_xbar.sv",
    ).read_text(encoding="utf-8")
    generic_xbar_tb = safe_file(
        root, root / "npc/rv64/testbench/tests/tb_axi_xbar.sv"
    ).read_text(encoding="utf-8")
    makefile = safe_file(
        root, root / CANONICAL_DISPATCH_FILE
    ).read_text(encoding="utf-8")
    validate_canonical_make_dispatch(makefile)
    validate_effective_make_dispatch(
        root / "npc/rv64",
        pathlib.Path("eval/ppa/ifu-evidence.mk"),
        CANONICAL_TARGET,
        f"bash ../../{CANONICAL_RUNNER}",
    )

    bridge_anchors = (
        "  assign ifu_axi_awvalid_o = (state_q == S_AD_UPDATE) && !aw_done_q;",
        "  assign ifu_axi_wvalid_o = (state_q == S_AD_UPDATE) && !w_done_q;",
        "  assign ifu_axi_bready_o = (state_q == S_AD_UPDATE);",
        "  wire ifu_ad_aw_accepted_next_w = aw_done_q || ifu_ad_aw_fire_w;",
        "  wire ifu_ad_w_accepted_next_w = w_done_q || ifu_ad_w_fire_w;",
        "    end else if (mmu_flush_i && (state_q != S_AD_UPDATE)) begin",
        "          if (mmu_flush_i) ad_drop_q <= 1'b1;",
        "          if (ifu_ad_aw_fire_w) aw_done_q <= 1'b1;",
        "          if (ifu_ad_w_fire_w) w_done_q <= 1'b1;",
        "            if (ad_drop_q || mmu_flush_i) begin",
        "[IFU-AD-AW-HOLD]",
        "[IFU-AD-W-HOLD]",
        "[IFU-AD-BREADY-HOLD]",
        "[IFU-AD-DROP-QUIET]",
        "[IFU-AD-DROP-COMPLETE]",
    )
    if any(bridge.count(anchor) != 1 for anchor in bridge_anchors):
        raise ValueError("IFU bridge contract topology anchor drifted")
    completion_anchor = (
        "  wire ifu_ad_write_complete_w = ifu_ad_aw_accepted_next_w &&\n"
        "                                 ifu_ad_w_accepted_next_w && "
        "ifu_ad_b_fire_w;"
    )
    if bridge.count(completion_anchor) != 1:
        raise ValueError("IFU bridge completion equation drifted")

    xbar_anchors = (
        "        s_bready_r[s] = m_bready_i[owner];",
        (
            "        if (wr_active_q[s] && wr_aw_sent_q[s] && "
            "wr_w_sent_q[s] &&\n"
            "            s_bvalid_i[s] && s_bready_r[s]) begin"
        ),
        "        if (m_awvalid_i[m] && m_awready_r[m]) begin",
        "        if (m_wvalid_i[m] && m_wready_r[m]) begin",
    )
    if any(xbar.count(anchor) != 1 for anchor in xbar_anchors):
        raise ValueError("AxiCrossbar write-owner topology anchor drifted")

    bridge_tb_anchors = (
        "[IFU-AXI-G1-FOCUSED]",
        "flush+first AW records fire",
        "flush+first W records fire",
        "flush+last-AW+B completes to IDLE",
        "flush+last-W+B completes to IDLE",
        "flush+AW+W+B completes to IDLE",
        "both-done flush+B-error drains to IDLE",
        "repeated flush blocks fetch accept",
        "repeated flush keeps AWADDR",
        "repeated flush keeps WDATA",
        "non-flushed B error enters response",
    )
    if any(bridge_tb.count(anchor) != 1 for anchor in bridge_tb_anchors):
        raise ValueError("IFU bridge focused-oracle anchor drifted")
    xbar_tb_anchors = (
        "[IFU-AXI-G1-XBAR]",
        "xbar releases IFU write owner",
        "later master reaches slave after IFU B",
        "later master AWADDR intact",
        "later master WDATA intact",
        "later master receives B",
    )
    if any(xbar_tb.count(anchor) != 1 for anchor in xbar_tb_anchors):
        raise ValueError("IFU bridge+xbar progress-oracle anchor drifted")
    generic_xbar_anchors = (
        "[IFU-AXI-G1-XBAR-BACKPRESSURE]",
        "split write owner remains active under B backpressure",
        "queued owner remains blocked under B backpressure",
        "split write BVALID holds for second backpressure cycle",
        "split write accepts aw",
        "w-first write accepts w",
    )
    if any(
        generic_xbar_tb.count(anchor) != 1 for anchor in generic_xbar_anchors
    ):
        raise ValueError("AxiCrossbar backpressure/skew oracle anchor drifted")
    return {
        "bridge_write_owner_excludes_ordinary_flush_clear": True,
        "bridge_aw_w_valid_are_independent_done_gated": True,
        "bridge_bready_spans_complete_write_owner": True,
        "bridge_completion_uses_both_accepted_next_values": True,
        "bridge_effective_drop_includes_current_flush": True,
        "bridge_port_shadow_is_present": True,
        "bridge_focused_matrix_has_first_last_all_and_both_done_cases": True,
        "bridge_drop_quiet_and_payload_oracles_are_explicit": True,
        "xbar_b_route_uses_recorded_owner": True,
        "xbar_release_requires_exact_b_fire": True,
        "xbar_generic_oracle_has_two_cycle_b_backpressure": True,
        "xbar_generic_oracle_has_aw_first_and_w_first": True,
        "xbar_integration_oracle_has_later_master_progress": True,
        "canonical_make_dispatch_is_exact": True,
        "canonical_make_dispatch_file_is_restricted": True,
        "canonical_make_environment_is_sanitized": True,
        "canonical_make_effective_recipe_is_exact": True,
    }


SOURCE_BINDING_PATHS = (
    "npc/rv64/vsrc/frontend/OooFetchAxiBridge.v",
    "npc/rv64/vsrc/bus/AxiCrossbar.v",
    "npc/rv64/design/specs/ooo-fetch-axi-bridge.md",
    "npc/rv64/testbench/tests/tb_ooo_fetch_axi_bridge.sv",
    "npc/rv64/testbench/tests/tb_ooo_fetch_axi_bridge_xbar.sv",
    "npc/rv64/testbench/tests/tb_axi_xbar.sv",
    "npc/rv64/testbench/Makefile",
    "npc/rv64/testbench/scripts/check_tb_result.py",
    CANONICAL_DISPATCH_FILE,
    f".github/task-runs/{RUN_ID}/contract.md",
    f".github/task-runs/{RUN_ID}/rtl-derivation.md",
    f".github/task-runs/{RUN_ID}/run-focused.sh",
    f".github/task-runs/{RUN_ID}/run-ifu-axi-variants.py",
    (
        f".github/task-runs/{RUN_ID}/subagent-contracts/"
        "v9g-ifu-axi-coverage-review-v1.json"
    ),
    "npc/rv64/eval/ppa/tools/ifu_axi_flush_drain_evidence.py",
    "npc/rv64/eval/ppa/tools/arch_stable_freeze.py",
    "npc/rv64/eval/ppa/tools/architecture_hard_gates.py",
    "npc/rv64/eval/ppa/tests/test_ifu_axi_flush_drain_evidence.py",
)


def build(
    *,
    root: pathlib.Path,
    bridge_log: pathlib.Path,
    xbar_log: pathlib.Path,
    generic_xbar_log: pathlib.Path,
    module_summary: pathlib.Path,
    variant_summary: pathlib.Path,
) -> dict[str, Any]:
    metrics = {
        "bridge": parse_bridge_log(bridge_log),
        "xbar_integration": parse_xbar_integration_log(xbar_log),
        "xbar_backpressure": parse_xbar_backpressure_log(generic_xbar_log),
    }
    module = parse_module_aggregate(root, module_summary)
    variants = validate_variants(root, variant_summary)
    static = validate_static_contract(root)
    rtl_sha, rtl_files = arch.rtl_binding(root)
    source_bindings = {
        rel: sha256_file(safe_file(root, root / rel))
        for rel in SOURCE_BINDING_PATHS
    }
    return {
        "schema": SCHEMA,
        "suite_run_id": RUN_ID,
        "status": "PASS",
        "design_id": f"sha256:{rtl_sha}",
        "canonical_command": CANONICAL_COMMAND,
        "scope": (
            "local RV64 instruction-fetch PTE A-update AW/W/B lifecycle "
            "through OooFetchAxiBridge and AxiCrossbar"
        ),
        "metrics": metrics,
        "invariants": INVARIANTS,
        "focused_tests": {
            "bridge": {
                "status": "PASS", "log_sha256": sha256_file(bridge_log)},
            "bridge_xbar": {
                "status": "PASS", "log_sha256": sha256_file(xbar_log)},
            "xbar_backpressure": {
                "status": "PASS",
                "log_sha256": sha256_file(generic_xbar_log),
            },
        },
        "module_aggregate": module,
        "variant_audit": variants,
        "static_audit": static,
        "provenance": {
            "rtl_sha256": rtl_sha,
            "files": rtl_files,
            "source_bindings": source_bindings,
        },
        "artifacts": [
            artifact(root, bridge_log, "ifu_axi_bridge_focused_log"),
            artifact(root, xbar_log, "ifu_axi_bridge_xbar_focused_log"),
            artifact(root, generic_xbar_log, "axi_xbar_backpressure_log"),
            artifact(root, module_summary, "module_aggregate_summary"),
            artifact(root, variant_summary, "rtl_variant_summary"),
        ],
        "claim": {
            "architecture_debts": {"IFU-AXI-G1": "CLOSED_ELIGIBLE"},
            "ppa": "UNQUALIFIED",
            "promotion_eligible": False,
        },
    }


def raw_summary(result: dict[str, Any]) -> str:
    bridge = result["metrics"]["bridge"]
    xbar = result["metrics"]["xbar_integration"]
    bp = result["metrics"]["xbar_backpressure"]
    variants = result["variant_audit"]
    module = result["module_aggregate"]
    bridge_source = "npc/rv64/vsrc/frontend/OooFetchAxiBridge.v"
    xbar_source = "npc/rv64/vsrc/bus/AxiCrossbar.v"
    return "\n".join((
        f"schema={result['schema']}",
        f"design_id={result['design_id']}",
        f"canonical_command={result['canonical_command']}",
        f"bridge_aw_first={bridge['aw_first']}",
        f"bridge_w_first={bridge['w_first']}",
        f"bridge_first_aw_with_flush={bridge['first_aw_with_flush']}",
        f"bridge_first_w_with_flush={bridge['first_w_with_flush']}",
        f"bridge_last_aw_b_with_flush={bridge['last_aw_b_with_flush']}",
        f"bridge_last_w_b_with_flush={bridge['last_w_b_with_flush']}",
        f"bridge_all_aw_w_b_with_flush={bridge['all_aw_w_b_with_flush']}",
        "bridge_both_done_flush_b_error="
        f"{bridge['both_done_flush_b_error']}",
        "bridge_both_stalled_flush_cycles="
        f"{bridge['both_stalled_flush_cycles']}",
        f"bridge_payload_stability={bridge['payload_stability']}",
        f"bridge_drop_quiet={bridge['drop_quiet']}",
        f"xbar_ifu_b_owner_release={xbar['ifu_b_owner_release']}",
        f"xbar_later_master_progress={xbar['later_master_progress']}",
        f"xbar_bvalid_hold_cycles={bp['bvalid_hold_cycles']}",
        f"xbar_early_release={bp['early_release']}",
        f"xbar_aw_first={bp['aw_first']}",
        f"xbar_w_first={bp['w_first']}",
        f"compile_success_rtl_variants={variants['compile_success']}",
        f"dynamic_rejected_rtl_variants={variants['dynamic_rejected']}",
        "bridge_rtl_variants="
        f"{variants['by_source'][bridge_source]['dynamic_rejected']}/"
        f"{variants['by_source'][bridge_source]['required']}",
        "xbar_rtl_variants="
        f"{variants['by_source'][xbar_source]['dynamic_rejected']}/"
        f"{variants['by_source'][xbar_source]['required']}",
        f"module_aggregate={module['passed']}/{module['required']}",
        "production_rtl_changed=false",
        "ppa=UNQUALIFIED",
        "promotion_eligible=false",
        "[IFU-AXI-G1-GATE] PASS",
        "",
    ))


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=pathlib.Path, required=True)
    parser.add_argument("--bridge-log", type=pathlib.Path, required=True)
    parser.add_argument("--xbar-log", type=pathlib.Path, required=True)
    parser.add_argument("--generic-xbar-log", type=pathlib.Path, required=True)
    parser.add_argument("--module-summary", type=pathlib.Path, required=True)
    parser.add_argument("--variant-summary", type=pathlib.Path, required=True)
    parser.add_argument("--output", type=pathlib.Path, required=True)
    parser.add_argument("--raw-log", type=pathlib.Path, required=True)
    args = parser.parse_args(argv)
    root = args.root.resolve(strict=True)
    output = args.output.resolve()
    raw_log = args.raw_log.resolve()
    for path in (output, raw_log):
        if not path.is_relative_to(root):
            parser.error(f"output escapes repository: {path}")
        path.parent.mkdir(parents=True, exist_ok=True)
    result = build(
        root=root,
        bridge_log=safe_file(root, args.bridge_log),
        xbar_log=safe_file(root, args.xbar_log),
        generic_xbar_log=safe_file(root, args.generic_xbar_log),
        module_summary=safe_file(root, args.module_summary),
        variant_summary=safe_file(root, args.variant_summary),
    )
    output.write_text(
        json.dumps(result, indent=2, sort_keys=True) + "\n",
        encoding="utf-8")
    raw_log.write_text(raw_summary(result), encoding="utf-8")
    print(
        f"[IFU-AXI-EVIDENCE] design_id={result['design_id']} focused=3/3 "
        f"variants={result['variant_audit']['dynamic_rejected']}/"
        f"{result['variant_audit']['required']} status=PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
