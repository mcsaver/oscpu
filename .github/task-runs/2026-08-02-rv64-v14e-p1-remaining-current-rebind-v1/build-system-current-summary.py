#!/usr/bin/env python3
"""Build the current-design SERIALIZE-G1 full-system receipt."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from pathlib import Path
from typing import Any


ANSI_RE = re.compile(r"\x1b\[[0-9;]*[A-Za-z]")
RUN_RESULT_RE = re.compile(
    r"exit via system-reset, code=(?P<code>\d+), "
    r"cycles=(?P<cycles>\d+), commits=(?P<commits>\d+)"
)
TOTAL_INSTRUCTIONS_RE = re.compile(r"total guest instructions = (?P<value>\d+)")
TOTAL_CYCLES_RE = re.compile(r"total guest cycles = (?P<value>\d+)")
CPI_RE = re.compile(r"CPI \(cycles/instruction\) = (?P<value>[0-9.]+)")


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def artifact(root: Path, path: Path) -> dict[str, Any]:
    resolved = path.resolve()
    return {
        "path": resolved.relative_to(root.resolve()).as_posix(),
        "sha256": sha256(resolved),
        "size_bytes": resolved.stat().st_size,
    }


def read_json(path: Path) -> Any:
    with path.open(encoding="utf-8") as stream:
        return json.load(stream)


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="replace")


def parse_kv(path: Path) -> dict[str, str]:
    values: dict[str, str] = {}
    for line_number, raw in enumerate(read_text(path).splitlines(), start=1):
        line = raw.strip()
        if not line:
            continue
        if "=" not in line:
            raise ValueError(f"{path}:{line_number}: malformed binding line")
        key, value = line.split("=", 1)
        if not key or key in values:
            raise ValueError(f"{path}:{line_number}: duplicate/empty key {key!r}")
        values[key] = value
    return values


def exact_count(text: str, marker: str) -> int:
    return text.count(marker)


def parse_execution(text: str) -> dict[str, Any]:
    clean = ANSI_RE.sub("", text)
    results = list(RUN_RESULT_RE.finditer(clean))
    if len(results) != 1:
        raise ValueError(f"expected one system-reset result, observed {len(results)}")
    result = results[0].groupdict()
    instruction_matches = TOTAL_INSTRUCTIONS_RE.findall(clean)
    cycle_matches = TOTAL_CYCLES_RE.findall(clean)
    cpi_matches = CPI_RE.findall(clean)
    if len(instruction_matches) != 1 or len(cycle_matches) != 1:
        raise ValueError("missing or duplicate final instruction/cycle statistics")
    commits = int(result["commits"])
    cycles = int(result["cycles"])
    if int(result["code"]) != 0:
        raise ValueError(f"system-reset exit code is {result['code']}")
    if int(instruction_matches[0]) != commits or int(cycle_matches[0]) != cycles:
        raise ValueError("run-result and final statistic counters disagree")
    return {
        "commits": commits,
        "cycles": cycles,
        "cpi_reported": float(cpi_matches[-1]) if cpi_matches else None,
        "final_pc": _final_pc(clean),
        "system_reset_code": 0,
    }


def _final_pc(text: str) -> str | None:
    matches = re.findall(r"HIT GOOD TRAP.*?pc = (0x[0-9a-fA-F]+)", text)
    return matches[-1].lower() if matches else None


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def build(args: argparse.Namespace) -> dict[str, Any]:
    root = args.repo_root.resolve()
    result = args.result_dir.resolve()
    output = args.output.resolve()
    require(result.is_relative_to(root), "result directory is outside repository")
    require(output.is_relative_to(result), "summary output is outside result directory")

    paths = {
        "binding": result / "binding.txt",
        "post_binding": result / "post-binding.txt",
        "runtime_cleanup": result / "runtime-cleanup.txt",
        "source_before": result / "source-before.json",
        "source_after": result / "source-after.json",
        "transaction": result / "systemd-transaction-evidence.json",
        "driver": result / "driver.log",
        "console": result / "guest/console.log",
        "npc": result / "guest/npc.log",
        "terminal": result / "terminal-markers.txt",
        "assertions": result / "rtl-assertion-failures.txt",
        "progress_tail": result / "progress-tail.txt",
        "system_stats": result / "system-stats.txt",
    }
    for label, path in paths.items():
        require(path.is_file(), f"missing {label}: {path}")

    before = read_json(paths["source_before"])
    after = read_json(paths["source_after"])
    expected_design_id = args.expected_design_id
    require(before == after, "production RTL source snapshot drifted during run")
    require(before.get("design_id") == expected_design_id, "unexpected RTL design-id")
    require(
        before.get("file_count") == args.expected_file_count,
        "unexpected production RTL file count",
    )

    binding = parse_kv(paths["binding"])
    post_binding = parse_kv(paths["post_binding"])
    cleanup = parse_kv(paths["runtime_cleanup"])
    require(binding.get("rtl_design_id") == expected_design_id, "binding design-id mismatch")
    require(post_binding.get("binding_status") == "PASS", "post binding did not pass")
    require(cleanup.get("runtime_removed") == "1", "runtime products were retained")
    require(cleanup.get("runtime_path_validated") == "1", "runtime path was not validated")

    transaction = read_json(paths["transaction"])
    stages = {stage.get("name"): stage for stage in transaction.get("stages", [])}
    strict = stages.get("strict") or {}
    require(transaction.get("status") == "PASS", "transaction parser status is not PASS")
    require(strict.get("status") == "PASS", "strict transaction stage is not PASS")
    require(strict.get("done_rc") == 0, "strict transaction done_rc is not zero")
    require(
        len(strict.get("expected_pass_labels", [])) == 17,
        "strict expected label count is not 17",
    )
    require(strict.get("pass_observation_count") == 17, "strict observed count is not 17")

    console_text = ANSI_RE.sub("", read_text(paths["console"]))
    npc_text = ANSI_RE.sub("", read_text(paths["npc"]))
    driver_text = ANSI_RE.sub("", read_text(paths["driver"]))
    terminal_markers = {
        "strict_done_rc0": "__NPC_SYSTEMD_STRICT_DONE__ rc=0",
        "poweroff_begin": "__NPC_SYSTEMD_POWEROFF_BEGIN__",
        "kernel_power_down": "reboot: Power down",
        "syscon_poweroff": "syscon-reset: poweroff requested value=0x00005555",
        "system_reset_exit": "exit via system-reset, code=0",
        "good_trap": "HIT GOOD TRAP",
    }
    terminal_counts = {
        label: exact_count(console_text, marker)
        for label, marker in terminal_markers.items()
    }
    require(
        all(count == 1 for count in terminal_counts.values()),
        f"terminal transaction count mismatch: {terminal_counts}",
    )
    pass_marker = (
        "[npc-systemd-check] PASS strict guest + natural poweroff "
        "(mode=systemd-strict)"
    )
    require(exact_count(driver_text, pass_marker) == 1, "driver PASS marker count is not one")
    require(
        "loaded bytes=0 file_bytes=0 text_bytes=0" in console_text,
        "UART zero-byte input binding is missing",
    )
    require(
        re.search(r"uart-rx\]\s+pop=", console_text + "\n" + npc_text) is None,
        "UART RX byte observed",
    )
    require(paths["assertions"].stat().st_size == 0, "RTL assertion failure file is non-empty")

    execution = parse_execution(console_text)
    require(execution["cycles"] <= args.max_cycles, "execution exceeded cycle budget")
    require(execution["commits"] > 0, "execution has no committed instructions")

    forbidden_suffixes = {".a", ".bin", ".o", ".pyc", ".so", ".vvp"}
    forbidden_names = {"NpcSimTop"}
    retained_products = sorted(
        path.relative_to(result).as_posix()
        for path in result.rglob("*")
        if path.is_file()
        and (path.suffix in forbidden_suffixes or path.name in forbidden_names)
    )
    require(not retained_products, f"compiled products retained in task-run: {retained_products}")

    receipt = {
        "schema": "rv64-v14e-serialize-system-current-summary-v1",
        "debt_id": "SERIALIZE-G1",
        "scope_status": "CURRENT_DYNAMIC_PASS",
        "debt_current_status": "CURRENT_DYNAMIC_PASS",
        "architecture_gate_state": "RED",
        "ppa_state": "BLOCKED_BY_ARCHITECTURE",
        "production_rtl_written": False,
        "current_design_id": expected_design_id,
        "source_identity": {
            "unchanged": True,
            "file_count": args.expected_file_count,
            "before": artifact(root, paths["source_before"]),
            "after": artifact(root, paths["source_after"]),
        },
        "full_system_recertification": {
            "status": "PASS",
            "mode": "CURRENT_DESIGN_EXECUTION",
            "max_cycles": args.max_cycles,
            "strict_passed": 17,
            "strict_required": 17,
            "terminal_counts": terminal_counts,
            "rtl_assertion_failures": 0,
            "uart_rx_bytes": 0,
            **execution,
        },
        "binding": {
            "simulator_sha256": binding.get("simulator_sha256"),
            "npc_config_sha256": binding.get("npc_config_sha256"),
            "rootfs_template_sha256": binding.get("rootfs_template_sha256"),
            "linux_image_sha256": binding.get("linux_image_sha256"),
            "opensbi_fw_sha256": binding.get("opensbi_fw_sha256"),
            "run_dtb_sha256": binding.get("run_dtb_sha256"),
            "post_binding_status": post_binding.get("binding_status"),
        },
        "runtime_compaction": {
            "runtime_products_retained": 0,
            "runtime_removed": True,
            "compiled_products_in_task_run": retained_products,
        },
        "evidence": {
            label: artifact(root, path)
            for label, path in paths.items()
        },
    }
    return receipt


def self_test() -> int:
    sample = (
        "\x1b[1;34mHIT GOOD TRAP at pc = 0x00000000800237ae\x1b[0m\n"
        "exit via system-reset, code=0, cycles=5071521696, commits=1223536213\n"
        "total guest instructions = 1223536213\n"
        "total guest cycles = 5071521696\n"
        "CPI (cycles/instruction) = 4.145\n"
    )
    parsed = parse_execution(sample)
    assert parsed["commits"] == 1223536213
    assert parsed["cycles"] == 5071521696
    assert parsed["final_pc"] == "0x00000000800237ae"
    print("[V14E-SERIALIZE-SYSTEM-SUMMARY-SELFTEST] PASS")
    return 0


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--self-test", action="store_true")
    parser.add_argument("--repo-root", type=Path)
    parser.add_argument("--result-dir", type=Path)
    parser.add_argument("--expected-design-id")
    parser.add_argument("--expected-file-count", type=int)
    parser.add_argument("--max-cycles", type=int)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args(argv)
    if not args.self_test:
        missing = [
            name
            for name in (
                "repo_root",
                "result_dir",
                "expected_design_id",
                "expected_file_count",
                "max_cycles",
                "output",
            )
            if getattr(args, name) is None
        ]
        if missing:
            parser.error(f"missing required arguments: {', '.join(missing)}")
    return args


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    if args.self_test:
        return self_test()
    try:
        receipt = build(args)
        args.output.parent.mkdir(parents=True, exist_ok=True)
        temporary = args.output.with_name(f"{args.output.name}.tmp")
        temporary.write_text(
            json.dumps(receipt, indent=2, sort_keys=True) + "\n",
            encoding="utf-8",
        )
        temporary.replace(args.output)
    except (OSError, ValueError, json.JSONDecodeError) as error:
        print(f"[V14E-SERIALIZE-SYSTEM-SUMMARY][FAIL] {error}", file=sys.stderr)
        return 1
    execution = receipt["full_system_recertification"]
    print(
        "[V14E-SERIALIZE-SYSTEM][PASS] "
        f"strict={execution['strict_passed']}/{execution['strict_required']} "
        f"commits={execution['commits']} cycles={execution['cycles']} "
        "terminals=6/6 assertions=0 source_unchanged=1 "
        "runtime_products_retained=0"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
