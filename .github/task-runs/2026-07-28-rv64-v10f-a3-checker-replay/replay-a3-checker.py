#!/usr/bin/env python3

from __future__ import annotations

import argparse
import hashlib
import json
import pathlib
import re
import subprocess
from typing import Any


SCHEMA = "npc-rv64-a3-checker-replay/v1"
SOURCE_STATUS = (
    "FAIL rc=1 stage=systemd-strict-guest "
    "evidence_complete=0 cleanup_rc=0"
)
EXPECTED_DESIGN = (
    "sha256:c1b5317212bfe47e507eac83a28dff405527f50493e3709e96ffbec2dc3bb594"
)
EXPECTED_CYCLES = 5_071_521_696
EXPECTED_COMMITS = 1_223_536_213
DEBUG_WITNESS = (
    "[    0.000000] printk: debug: ignoring loglevel setting."
)
REAL_BUG_FIXTURE = "[   12.300000] BUG: unable to handle page fault"
TERMINAL_MARKERS = (
    ("strict_done", "__NPC_SYSTEMD_STRICT_DONE__ rc=1"),
    ("poweroff_begin", "__NPC_SYSTEMD_POWEROFF_BEGIN__"),
    ("kernel_power_down", "reboot: Power down"),
    (
        "syscon_poweroff",
        "syscon-reset: poweroff requested value=0x00005555",
    ),
    ("good_trap", "HIT GOOD TRAP"),
    ("system_reset_exit", "exit via system-reset, code=0"),
)
STABLE_BINDING_KEYS = (
    "npc_config_sha256",
    "npc_auto_conf_sha256",
    "npc_autoconf_header_sha256",
    "npc_makefile_sha256",
    "linux_image_sha256",
    "opensbi_fw_sha256",
    "run_dtb_sha256",
    "OOO_CSR_QUEUE_HEAD",
    "OOO_ASSERT",
    "OOO_TERMINAL_HOLDER_ASSERT",
    "NPC_SYSTEMD_GUEST_COMMAND_MODE",
    "uart_rx_bytes",
    "max_cycles",
)
DEVICE_OBJECTS = (
    "dpi.o",
    "device.o",
    "virtio_blk.o",
    "map.o",
    "timer.o",
    "vga.o",
    "keyboard.o",
    "paddr.o",
)


def sha256(path: pathlib.Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8", errors="replace")


def parse_key_values(path: pathlib.Path) -> dict[str, str]:
    values: dict[str, str] = {}
    for raw_line in read_text(path).splitlines():
        if "=" not in raw_line:
            continue
        key, value = raw_line.split("=", 1)
        if re.fullmatch(r"[A-Za-z0-9_]+", key):
            values[key] = value
    return values


def production_regex(checker: pathlib.Path) -> str:
    match = re.search(
        r"^bad_dmesg_regex='([^']+)'$",
        read_text(checker),
        flags=re.MULTILINE,
    )
    if match is None:
        raise AssertionError("production bad_dmesg_regex assignment missing")
    return match.group(1)


def grep_probe(regex: str, text: str) -> tuple[int, list[str]]:
    result = subprocess.run(
        ["grep", "-i", "-E", regex],
        input=text,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if result.returncode not in (0, 1):
        raise AssertionError(
            f"grep query failed rc={result.returncode}: {result.stderr}"
        )
    return result.returncode, result.stdout.splitlines()


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def normalize_generated_text(text: str) -> str:
    text = re.sub(r"NpcSimTop\.sv:\d+", "NpcSimTop.sv:<LINE>", text)
    return re.sub(
        r'NpcSimTop\.sv",\s+\d+,',
        'NpcSimTop.sv", <LINE>,',
        text,
    )


def compare_elaboration(
    a3_obj: pathlib.Path,
    a4_obj: pathlib.Path,
) -> dict[str, Any]:
    generated_names = sorted(
        path.name
        for path in a3_obj.iterdir()
        if path.is_file()
        and path.name.startswith("VNpcSimTop")
        and path.suffix in {".cpp", ".h"}
    )
    require(generated_names, "no A3 generated Verilator C++/header files")

    exact_differences: list[str] = []
    normalized_differences: list[str] = []
    for name in generated_names:
        a3_path = a3_obj / name
        a4_path = a4_obj / name
        require(a4_path.is_file(), f"A4 generated file missing: {name}")
        if sha256(a3_path) == sha256(a4_path):
            continue
        exact_differences.append(name)
        a3_normalized = normalize_generated_text(read_text(a3_path))
        a4_normalized = normalize_generated_text(read_text(a4_path))
        if a3_normalized != a4_normalized:
            normalized_differences.append(name)

    device_hashes: dict[str, dict[str, str]] = {}
    for name in DEVICE_OBJECTS:
        a3_path = a3_obj / name
        a4_path = a4_obj / name
        require(a3_path.is_file(), f"A3 device object missing: {name}")
        require(a4_path.is_file(), f"A4 device object missing: {name}")
        a3_hash = sha256(a3_path)
        a4_hash = sha256(a4_path)
        require(a3_hash == a4_hash, f"device object changed: {name}")
        device_hashes[name] = {"a3": a3_hash, "a4": a4_hash}

    a3_cpu = sha256(a3_obj / "cpu-exec.o")
    a4_cpu = sha256(a4_obj / "cpu-exec.o")
    require(a3_cpu != a4_cpu, "expected host diagnostic object delta missing")
    require(
        not normalized_differences,
        "actually elaborated RTL differs after source-line normalization: "
        + ",".join(normalized_differences),
    )

    return {
        "generated_file_count": len(generated_names),
        "generated_exact_match_count": (
            len(generated_names) - len(exact_differences)
        ),
        "generated_exact_differences": exact_differences,
        "generated_normalized_differences": normalized_differences,
        "actual_elaborated_rtl_logic_changed": False,
        "device_model_objects_changed": [],
        "device_object_hashes": device_hashes,
        "host_cpu_exec_object_changed": True,
        "cpu_exec_object_sha256": {"a3": a3_cpu, "a4": a4_cpu},
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--out", required=True, type=pathlib.Path)
    args = parser.parse_args()

    repo_root = pathlib.Path(__file__).resolve().parents[3]
    task_root = (
        repo_root
        / ".github/task-runs/2026-07-27-rv64-v10e-current-design-system-recert"
    )
    a3 = task_root / "rootfs-c1b531-systemd-strict-6b-a3"
    a4 = task_root / "rootfs-5f9dd068-systemd-strict-6b-a4"
    runtime_root = (
        repo_root / ".github/runtime-artifacts/rv64-systemd-strict"
    )
    a3_obj = (
        runtime_root
        / "rootfs-c1b531-systemd-strict-6b-a3/sim-build/obj_dir"
    )
    a4_obj = (
        runtime_root
        / "rootfs-5f9dd068-systemd-strict-6b-a4/sim-build/obj_dir"
    )
    checker = repo_root / "Linux/scripts/npc-systemd-strict-check.sh"
    checker_test = (
        repo_root / "Linux/scripts/tests/test_npc_systemd_strict_check.py"
    )

    frozen_inputs = {
        "status": task_root / "rootfs-c1b531-systemd-strict-6b-a3.status",
        "console": a3 / "guest/console.log",
        "npc_log": a3 / "guest/npc.log",
        "binding": a3 / "binding.txt",
        "post_binding": a3 / "post-binding.txt",
        "transaction": a3 / "systemd-transaction-evidence.json",
        "rtl_assertions": a3 / "rtl-assertion-failures.txt",
        "terminal_markers": a3 / "terminal-markers.txt",
    }
    missing = [
        str(path.relative_to(repo_root))
        for path in frozen_inputs.values()
        if not path.is_file()
    ]
    require(not missing, "missing A3 frozen inputs: " + ",".join(missing))

    source_status = read_text(frozen_inputs["status"]).strip()
    require(source_status == SOURCE_STATUS, "A3 source status was modified")
    console_text = read_text(frozen_inputs["console"])
    transaction = json.loads(read_text(frozen_inputs["transaction"]))
    binding = parse_key_values(frozen_inputs["binding"])
    post_binding = parse_key_values(frozen_inputs["post_binding"])

    regex = production_regex(checker)
    bounded_token = "(^|[^[:alnum:]_])BUG:"
    require(bounded_token in regex, "bounded BUG token missing")
    legacy_regex = regex.replace(bounded_token, "BUG:")
    require(legacy_regex != regex, "legacy oracle mutation did not apply")

    current_rc, current_hits = grep_probe(regex, console_text)
    legacy_rc, legacy_hits = grep_probe(legacy_regex, console_text)
    witness_current_rc, _ = grep_probe(regex, DEBUG_WITNESS + "\n")
    witness_legacy_rc, _ = grep_probe(legacy_regex, DEBUG_WITNESS + "\n")
    real_bug_rc, real_bug_hits = grep_probe(regex, REAL_BUG_FIXTURE + "\n")
    require(current_rc == 1 and not current_hits, "current A3 replay is RED")
    require(legacy_rc == 0 and legacy_hits, "legacy A3 replay did not reproduce")
    require(
        all("printk: debug:" in line for line in legacy_hits),
        "legacy replay matched a competing critical marker",
    )
    require(witness_current_rc == 1, "current regex rejected debug witness")
    require(witness_legacy_rc == 0, "legacy regex missed debug witness")
    require(real_bug_rc == 0 and real_bug_hits, "real BUG fixture was accepted")

    stages = {stage["name"]: stage for stage in transaction["stages"]}
    strict = stages["strict"]
    require(transaction["status"] == "FAIL", "A3 transaction status changed")
    require(stages["preflight"]["status"] == "PASS", "preflight was not PASS")
    require(stages["autocheck"]["status"] == "PASS", "autocheck was not PASS")
    require(strict["status"] == "FAIL", "strict historical status changed")
    require(strict["done_rc"] == 1, "strict done_rc is not 1")
    require(
        len(strict["expected_pass_labels"]) == 17
        and strict["pass_observation_count"] == 16,
        "strict result is not 16/17",
    )
    require(
        strict["fail_markers"]
        == [
            {
                "line": strict["fail_markers"][0]["line"],
                "text": "__NPC_CHECK_FAIL__:dmesg-no-critical",
            }
        ],
        "strict has a competing FAIL marker",
    )

    terminal_counts: dict[str, int] = {}
    terminal_offsets: dict[str, int] = {}
    previous_offset = -1
    for name, marker in TERMINAL_MARKERS:
        count = console_text.count(marker)
        offset = console_text.find(marker)
        require(count == 1, f"{name} count={count}, expected=1")
        require(offset > previous_offset, f"{name} is out of order")
        terminal_counts[name] = count
        terminal_offsets[name] = offset
        previous_offset = offset

    exit_match = re.search(
        r"exit via system-reset, code=0, cycles=(\d+), commits=(\d+)",
        console_text,
    )
    require(exit_match is not None, "system-reset result missing")
    cycles = int(exit_match.group(1))
    commits = int(exit_match.group(2))
    require(cycles == EXPECTED_CYCLES, f"cycles={cycles}")
    require(commits == EXPECTED_COMMITS, f"commits={commits}")
    require(
        frozen_inputs["rtl_assertions"].stat().st_size == 0,
        "A3 RTL assertion evidence is nonempty",
    )

    require(binding.get("rtl_design_id") == EXPECTED_DESIGN, "design mismatch")
    require(
        post_binding.get("rtl_design_id_post") == EXPECTED_DESIGN,
        "post design mismatch",
    )
    require(
        post_binding.get("simulator_sha256_post")
        == binding.get("simulator_sha256"),
        "simulator pre/post drift",
    )
    binding_pairs: dict[str, dict[str, str]] = {}
    for key, pre_value in post_binding.items():
        if not key.endswith("_pre_sha256"):
            continue
        post_key = key.replace("_pre_sha256", "_post_sha256")
        post_value = post_binding.get(post_key)
        require(post_value == pre_value, f"binding drift: {key}")
        binding_pairs[key[: -len("_pre_sha256")]] = {
            "pre": pre_value,
            "post": post_value,
        }

    a3_binding = parse_key_values(a3 / "binding.txt")
    a4_binding = parse_key_values(a4 / "binding.txt")
    stable_comparison: dict[str, dict[str, str]] = {}
    for key in STABLE_BINDING_KEYS:
        a3_value = a3_binding.get(key)
        a4_value = a4_binding.get(key)
        require(a3_value is not None and a4_value is not None, f"missing {key}")
        require(a3_value == a4_value, f"A3/A4 binding changed: {key}")
        stable_comparison[key] = {"a3": a3_value, "a4": a4_value}
    require(
        read_text(a3 / "simulator-defines.txt")
        == read_text(a4 / "simulator-defines.txt"),
        "compiled define set changed",
    )
    elaboration = compare_elaboration(a3_obj, a4_obj)

    a4_status = read_text(
        task_root / "rootfs-5f9dd068-systemd-strict-6b-a4.status"
    ).strip()
    require(
        a4_status
        == (
            "FAIL rc=143 stage=systemd-strict-guest "
            "evidence_complete=0 cleanup_rc=143 signal=TERM"
        ),
        "A4 interruption status mismatch",
    )

    frozen_hashes = {
        name: {
            "path": str(path.relative_to(repo_root)),
            "sha256": sha256(path),
            "size_bytes": path.stat().st_size,
        }
        for name, path in frozen_inputs.items()
    }
    evidence = {
        "schema": SCHEMA,
        "status": "PASS",
        "classification": "verification-checker-replay",
        "source_run": {
            "path": str(a3.relative_to(repo_root)),
            "original_status": source_status,
            "original_status_preserved": True,
            "design_id": EXPECTED_DESIGN,
            "cycles": cycles,
            "commits": commits,
            "frozen_inputs": frozen_hashes,
        },
        "oracle_replay": {
            "production_checker": str(checker.relative_to(repo_root)),
            "production_checker_sha256": sha256(checker),
            "checker_test": str(checker_test.relative_to(repo_root)),
            "checker_test_sha256": sha256(checker_test),
            "current_regex": regex,
            "legacy_regex": legacy_regex,
            "legacy_a3_match_count": len(legacy_hits),
            "legacy_a3_matches": legacy_hits,
            "current_a3_match_count": len(current_hits),
            "debug_witness": {
                "text": DEBUG_WITNESS,
                "legacy_match": True,
                "current_match": False,
            },
            "real_bug_fixture": {
                "text": REAL_BUG_FIXTURE,
                "current_match": True,
            },
        },
        "system_transaction": {
            "classification": "COMPLETE_WITH_LEGACY_ORACLE_FALSE_POSITIVE",
            "preflight_status": stages["preflight"]["status"],
            "autocheck_status": stages["autocheck"]["status"],
            "strict_historical_status": strict["status"],
            "strict_historical_pass_count": strict["pass_observation_count"],
            "strict_expected_pass_count": len(strict["expected_pass_labels"]),
            "strict_historical_done_rc": strict["done_rc"],
            "strict_historical_fail_markers": strict["fail_markers"],
            "terminal_counts": terminal_counts,
            "terminal_offsets": terminal_offsets,
            "rtl_assertion_file_empty": True,
        },
        "binding": {
            "design_id_pre": binding["rtl_design_id"],
            "design_id_post": post_binding["rtl_design_id_post"],
            "simulator_sha256_pre": binding["simulator_sha256"],
            "simulator_sha256_post": post_binding[
                "simulator_sha256_post"
            ],
            "pre_post_pairs": binding_pairs,
        },
        "full_system_rerun_gate": {
            "production_core_semantics_changed": False,
            "actual_elaborated_rtl_changed": False,
            "device_model_execution_objects_changed": False,
            "host_diagnostic_observation_object_changed": True,
            "a3_required_evidence_missing": False,
            "a4_status": a4_status,
            "a4_is_system_pass_evidence": False,
            "rerun_required_for_oracle_correction": False,
            "stable_binding_comparison": stable_comparison,
            "elaboration_comparison": elaboration,
        },
        "conclusion": (
            "A3_SYSTEM_TRANSACTION_COMPLETE_LEGACY_ORACLE_FALSE_POSITIVE"
        ),
        "promotion": {
            "eligible": False,
            "reason": "checker replay does not qualify architecture or PPA",
        },
    }

    args.out.parent.mkdir(parents=True, exist_ok=True)
    temporary = args.out.with_suffix(args.out.suffix + ".tmp")
    temporary.write_text(
        json.dumps(evidence, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    temporary.replace(args.out)
    print(
        "[V10F-A3-CHECKER-REPLAY] "
        f"legacy_matches={len(legacy_hits)} current_matches=0 "
        f"strict=16/17 terminal=6/6 cycles={cycles} commits={commits} PASS"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

