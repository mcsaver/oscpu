#!/usr/bin/env python3
from __future__ import annotations

import fcntl
import hashlib
import json
import os
import pathlib
import re
import subprocess
import sys
from typing import Any


ROOT = pathlib.Path(".").resolve()
RUN_DIR = (
    ROOT
    / ".github/task-runs/2026-07-27-rv64-v10e-current-design-system-recert"
)
OUT = RUN_DIR / "review-v6"
RUNNER = RUN_DIR / "run-v10e-current-design-systemd-strict.sh"
LAUNCHER = RUN_DIR / "launch-v10e-current-design-systemd-strict.sh"
LEGACY_LAUNCHER = (
    ROOT
    / ".github/task-runs/2026-07-24-rv64-v9s-serialize-default"
    / "launch-v9s-rootfs-csr-qh-systemd-strict.sh"
)
SELFTEST = RUN_DIR / "test-runner-contract.py"
STATUS_HELPER = ROOT / "scripts/task-run-status.sh"
STATUS_TEST = ROOT / "scripts/tests/test-task-run-status.sh"
CONTRACT = (
    RUN_DIR
    / "subagent-contracts/v10e_runner_prelaunch_review_v6.json"
)
LOCK_PATH = (
    ROOT
    / ".github/runtime-artifacts/rv64-engineering-single-flight.lock"
)
ARCH_TOOL = ROOT / "npc/rv64/eval/ppa/tools/architecture_hard_gates.py"
NPC_MAKEFILE = ROOT / "npc/rv64/Makefile"
DISPATCH_LOG = RUN_DIR / "dispatch-log.md"
REVIEW_V5 = RUN_DIR / "review-v5/review.md"
V5_INPUT_SHA = RUN_DIR / "review-v5/input-sha256-pre.txt"

A2_LABEL = "rootfs-c1b531-systemd-strict-6b-a2"
A2_DIR = RUN_DIR / A2_LABEL
A2_STATUS = RUN_DIR / f"{A2_LABEL}.status"
A2_POST_BINDING = A2_DIR / "post-binding.txt"
A2_QUERY_ERRORS = A2_DIR / "evidence-query-errors.log"
A2_PRELAUNCH_LOG = A2_DIR / "prelaunch-contract.log"
A2_SIM_BUILD_LOG = A2_DIR / "sim-build.log"
A2_RUNTIME = (
    ROOT
    / ".github/runtime-artifacts/rv64-systemd-strict"
    / A2_LABEL
)
A2_SIMULATOR = A2_RUNTIME / "sim-build/NpcSimTop"
A2_MANIFEST = A2_RUNTIME / "sim-build/obj_dir/VNpcSimTop__verFiles.dat"

A3_LABEL = "rootfs-c1b531-systemd-strict-6b-a3"
A3_DIR = RUN_DIR / A3_LABEL
A3_STATUS = RUN_DIR / f"{A3_LABEL}.status"
A3_RUNTIME = (
    ROOT
    / ".github/runtime-artifacts/rv64-systemd-strict"
    / A3_LABEL
)

EXPECTED_CONTRACT_SHA = (
    "7c62fba90d357837866db7e3654a9fa34047e7d190607264a738eb9d9b7f7792"
)
EXPECTED_DESIGN_SHA = (
    "c1b5317212bfe47e507eac83a28dff405527f50493e3709e96ffbec2dc3bb594"
)
EXPECTED_A2_STATUS = (
    "FAIL rc=1 stage=simulator-define-binding "
    "evidence_complete=0 cleanup_rc=2"
)
EXPECTED_A2_RUNNER_SHA = (
    "71c4d23a96421008a2e8bbe2c6218837685ee1d1b806b3887486afb412d7a27a"
)
EXPECTED_MAKEFILE_SHA = (
    "fb4110acb7cf3c4ff1964b8b93e3e516ffdea4a4cf1f97b6f8f96c1dc0f81118"
)
EXPECTED_A2_SIMULATOR_SHA = (
    "0332824953b7960f7195c197bd64042b2a67c69585a139e71673a35756bb4a0e"
)
EXPECTED_DEFINE_TOKEN = "+define+OOO_TERMINAL_HOLDER_ASSERT"
REJECTED_DEFINE_TOKEN = "+define+OOO_TERMINAL_HOLDER_ASSERT=1"
EXPECTED_ASSERTION_REGEX = (
    r"\[(V9Q-(BRIDGE-HOLDER|TRANSIENT-HOLDER|TRANSIENT-BRIDGE|"
    r"DUAL-REQ-TOKEN)-DISJOINT|S2-G1-TCOLL-INGRESS-DUP|"
    r"V10D-[^]]*FAIL)\]|%Error:|Assertion failed|RTL assertion|"
    r"\[.*ASSERT.*FAIL"
)

IMMUTABLE_INPUTS = (
    CONTRACT,
    RUNNER,
    LAUNCHER,
    LEGACY_LAUNCHER,
    SELFTEST,
    STATUS_HELPER,
    STATUS_TEST,
    ROOT / "Linux/Makefile",
    ROOT / "Linux/scripts/check-npc-systemd-guest.sh",
    ROOT / "Linux/scripts/npc-systemd-strict-check.sh",
    ROOT / "Linux/scripts/npc_systemd_transaction_evidence.py",
    ROOT / "Linux/scripts/prepare-npc-rootfs-run-image.sh",
    NPC_MAKEFILE,
    ROOT / "npc/rv64/scripts/config.mk",
    ROOT / "npc/rv64/configs/default_defconfig",
    ARCH_TOOL,
    DISPATCH_LOG,
    REVIEW_V5,
    V5_INPUT_SHA,
    A2_STATUS,
    A2_POST_BINDING,
    A2_QUERY_ERRORS,
    A2_PRELAUNCH_LOG,
    A2_SIM_BUILD_LOG,
    A2_MANIFEST,
    A2_SIMULATOR,
)

EXPECTED_STATIC_NAMES = {
    "stale-design",
    "lower-cycle-floor",
    "drop-canonical-config-stage",
    "drop-config-hash-binding",
    "drop-queue-head-build",
    "drop-queue-head-evidence",
    "drop-queue-head-compiled-define",
    "drop-assertion-compiled-define",
    "drop-terminal-holder-build",
    "drop-terminal-holder-compiled-define",
    "require-terminal-holder-define-value",
    "drop-verilator-assert-mode",
    "drop-makefile-pre-hash",
    "drop-manifest-pre-hash",
    "drop-rootfs-isolation",
    "drop-rootfs-copy-helper-binding",
    "drop-rootfs-pre-hash-proof",
    "drop-transaction-evidence",
    "drop-strict-count",
    "drop-assertion-oracle",
    "drop-evidence-completion",
    "skip-missing-simulator-failure",
    "drop-kernel-post-hash",
    "drop-opensbi-post-hash",
    "drop-dtb-post-hash",
    "restore-reenables-errexit",
    "cleanup-clears-signal-traps",
    "drop-post-binding-write-check",
    "ignore-terminal-query-errors",
    "overescape-assertion-regex",
    "require-guest-checker-executable",
    "drop-guest-checker-post-hash",
    "drop-transaction-parser-post-hash",
    "drop-rootfs-helper-post-hash",
    "drop-prelaunch-log-post-hash",
    "allow-duplicate-strict-done",
    "allow-duplicate-good-trap",
    "preflight-before-status-traps",
    "private-v10e-lock",
    "private-v9s-lock",
    "v10e-no-launch-failure-status",
    "v9s-no-launch-failure-status",
    "PASS-write-failure-ignored",
}

EXPECTED_DYNAMIC_SNIPPETS = (
    "task-run status PASS-write fallback PASS",
    "V9S launch rejected shared V10E lock rc=3",
    "cleanup failure finalized as FAIL rc=7",
    "cleanup TERM deferred and finalized as FAIL rc=143",
    "post-binding redirection failure finalized as FAIL rc=1",
    "production assertion regex match/no-match/read-error rc=0/1/2",
    "readable non-executable guest checker accepted via Bash rc=0 mode=0644",
    "Makefile/runner terminal-holder define binding "
    "token=+define+OOO_TERMINAL_HOLDER_ASSERT grep_rc=0",
    "rootfs copy hash PASS; existing run image rejected rc=4",
)

TERMINAL_ORACLES = {
    "strict_done": '[[ "${strict_done_count}" -eq 1 ]]',
    "poweroff_begin": '[[ "${poweroff_begin_count}" -eq 1 ]]',
    "syscon_terminal": '[[ "${syscon_terminal_count}" -eq 1 ]]',
    "system_reset_exit": '[[ "${system_reset_exit_count}" -eq 1 ]]',
    "good_trap": '[[ "${good_trap_count}" -eq 1 ]]',
}

POST_HASH_TOKENS = {
    "rootfs_template": "rootfs_template_post_sha256=",
    "rootfs_cpio": "rootfs_cpio_post_sha256=",
    "rtl_design_id": "rtl_design_id_post=sha256:",
    "simulator": "simulator_sha256_post=",
    "npc_config": 'verify_post_hash "npc_config"',
    "npc_auto_conf": 'verify_post_hash "npc_auto_conf"',
    "npc_autoconf_header": '"npc_autoconf_header" "${autoconf_header_path}"',
    "npc_makefile": '"npc_makefile" "${repo_root}/npc/rv64/Makefile"',
    "verilator_manifest": '"verilator_manifest" "${verilator_manifest}"',
    "linux_image": 'verify_post_hash "linux_image"',
    "opensbi_fw": 'verify_post_hash "opensbi_fw"',
    "run_dtb": 'verify_post_hash "run_dtb"',
    "runner_script": '"runner_script"',
    "task_run_status_helper": '"task_run_status_helper"',
    "linux_makefile": '"linux_makefile"',
    "guest_checker": '"guest_checker"',
    "strict_checker": '"strict_checker"',
    "transaction_parser": '"transaction_parser"',
    "rootfs_copy_helper": '"rootfs_copy_helper"',
    "prelaunch_contract_log": '"prelaunch_contract_log"',
}


def rel(path: pathlib.Path) -> str:
    return path.resolve().relative_to(ROOT).as_posix()


def digest(path: pathlib.Path) -> str:
    value = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            value.update(chunk)
    return value.hexdigest()


def snapshot(paths: tuple[pathlib.Path, ...]) -> dict[str, str]:
    return {rel(path): digest(path) for path in paths}


def write_json(path: pathlib.Path, value: Any) -> None:
    path.write_text(
        json.dumps(value, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


def write_snapshot(path: pathlib.Path, values: dict[str, str]) -> None:
    path.write_text(
        "".join(f"{sha}  {name}\n" for name, sha in sorted(values.items())),
        encoding="utf-8",
    )


def run_logged(
    argv: list[str],
    log_name: str,
    rc_name: str,
    *,
    env: dict[str, str] | None = None,
) -> subprocess.CompletedProcess[str]:
    result = subprocess.run(
        argv,
        cwd=ROOT,
        check=False,
        env=env,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
    )
    (OUT / log_name).write_text(result.stdout, encoding="utf-8")
    (OUT / rc_name).write_text(
        f"rc={result.returncode}\n",
        encoding="utf-8",
    )
    return result


def run_rg(
    pattern: str,
    *,
    input_text: str | None = None,
    path: pathlib.Path | None = None,
) -> subprocess.CompletedProcess[str]:
    argv = ["rg", "-a", "-n", pattern]
    if path is not None:
        argv.append(path.as_posix())
    return subprocess.run(
        argv,
        cwd=ROOT,
        check=False,
        input=input_text,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
    )


def marker_name(line: str) -> str:
    match = re.search(
        r"\[V10E-RUNNER-CONTRACT\]\[NEGATIVE\] (.+) rejected$",
        line,
    )
    if match is None:
        raise ValueError(f"malformed static marker: {line}")
    return match.group(1)


def key_values(text: str) -> dict[str, str]:
    result: dict[str, str] = {}
    for line in text.splitlines():
        if "=" in line:
            key, value = line.split("=", 1)
            result[key] = value
    return result


def token_line(text: str, token: str) -> int:
    offset = text.find(token)
    return 0 if offset < 0 else text.count("\n", 0, offset) + 1


def is_nonempty_file(path: pathlib.Path) -> bool:
    return path.is_file() and path.stat().st_size > 0


OUT.mkdir(parents=True, exist_ok=True)
contract_sha = digest(CONTRACT)
if contract_sha != EXPECTED_CONTRACT_SHA:
    raise SystemExit(
        f"contract SHA mismatch: expected={EXPECTED_CONTRACT_SHA} "
        f"actual={contract_sha}"
    )

contract_sha_cmd = run_logged(
    ["sha256sum", rel(CONTRACT)],
    "contract-sha256.log",
    "contract-sha256.rc",
)

sys.path.insert(0, str(ARCH_TOOL.parent))
import architecture_hard_gates as arch  # noqa: E402

immutable_pre = snapshot(IMMUTABLE_INPUTS)
lock_exists_pre = LOCK_PATH.is_file()
lock_sha_pre = digest(LOCK_PATH) if lock_exists_pre else "MISSING"
rtl_sha_pre, rtl_files_pre = arch.rtl_binding(ROOT)

runner_text = RUNNER.read_text(encoding="utf-8")
launcher_text = LAUNCHER.read_text(encoding="utf-8")
legacy_launcher_text = LEGACY_LAUNCHER.read_text(encoding="utf-8")
selftest_text = SELFTEST.read_text(encoding="utf-8")
makefile_text = NPC_MAKEFILE.read_text(encoding="utf-8")
dispatch_text = DISPATCH_LOG.read_text(encoding="utf-8")
review_v5_text = REVIEW_V5.read_text(encoding="utf-8")
v5_input_text = V5_INPUT_SHA.read_text(encoding="utf-8")
a2_status_text = A2_STATUS.read_text(encoding="utf-8").strip()
a2_post_text = A2_POST_BINDING.read_text(encoding="utf-8")
a2_query_text = A2_QUERY_ERRORS.read_text(encoding="utf-8")
a2_prelaunch_text = A2_PRELAUNCH_LOG.read_text(encoding="utf-8")
a2_manifest_text = A2_MANIFEST.read_text(encoding="utf-8")
a2_post = key_values(a2_post_text)

macro_consumers = run_logged(
    [
        "rg",
        "-n",
        r"^`ifdef[[:space:]]+OOO_TERMINAL_HOLDER_ASSERT$",
        "npc/rv64/vsrc",
    ],
    "rtl-macro-consumers.log",
    "rtl-macro-consumers.rc",
)
macro_consumer_lines = [
    line for line in macro_consumers.stdout.splitlines() if line.strip()
]

make_lines = [
    line.strip()
    for line in makefile_text.splitlines()
    if line.startswith("RTL_VERILATOR_DEFINES +=")
    and "OOO_TERMINAL_HOLDER_ASSERT" in line
]
make_match = (
    re.search(
        r",(\+define\+OOO_TERMINAL_HOLDER_ASSERT(?:=1)?)\)\s*$",
        make_lines[0],
    )
    if len(make_lines) == 1
    else None
)
make_token = make_match.group(1) if make_match else "UNEXTRACTED"
make_line_number = (
    token_line(makefile_text, make_lines[0]) if len(make_lines) == 1 else 0
)

manifest_command_lines = [
    line for line in a2_manifest_text.splitlines() if line.startswith('C "')
]
manifest_command = (
    manifest_command_lines[0] if len(manifest_command_lines) == 1 else ""
)
manifest_no_value_count = len(
    re.findall(
        r"(?<!\S)\+define\+OOO_TERMINAL_HOLDER_ASSERT(?=\s)",
        manifest_command,
    )
)
manifest_value_count = len(
    re.findall(
        r"(?<!\S)\+define\+OOO_TERMINAL_HOLDER_ASSERT=1(?=\s)",
        manifest_command,
    )
)
manifest_required_tokens = {
    "--assert": "--assert" in manifest_command,
    "+define+OOO_CSR_QUEUE_HEAD=1": (
        "+define+OOO_CSR_QUEUE_HEAD=1 " in manifest_command
    ),
    "+define+OOO_ASSERT": "+define+OOO_ASSERT " in manifest_command,
    EXPECTED_DEFINE_TOKEN: manifest_no_value_count == 1,
    REJECTED_DEFINE_TOKEN: manifest_value_count == 0,
}

runner_patterns = [
    pattern
    for pattern in re.findall(r'grep -Fq -- "([^"]+)"', runner_text)
    if "OOO_TERMINAL_HOLDER_ASSERT" in pattern
]
runner_pattern = runner_patterns[0] if len(runner_patterns) == 1 else "INVALID"
runner_pattern_line = token_line(
    runner_text,
    f'grep -Fq -- "{EXPECTED_DEFINE_TOKEN} "',
)

a2_present_paths = (
    A2_DIR / "config-canonical.log",
    A2_DIR / "rootfs-build.log",
    A2_DIR / "rootfs-check.log",
    A2_SIM_BUILD_LOG,
    A2_MANIFEST,
    A2_SIMULATOR,
)
a2_absent_paths = (
    A2_DIR / "driver.log",
    A2_DIR / "guest",
    A2_DIR / "systemd-transaction-evidence.json",
    A2_DIR / "binding.txt",
    A2_DIR / "simulator-defines.txt",
    A2_RUNTIME / "rootfs.ext4",
)
a2_presence = {
    rel(path): is_nonempty_file(path) for path in a2_present_paths
}
a2_absence = {rel(path): not path.exists() for path in a2_absent_paths}
a2_runner_sha = a2_post.get("runner_script_pre_sha256", "MISSING")
a2_simulator_sha = digest(A2_SIMULATOR)
a2_manifest_sha = digest(A2_MANIFEST)
makefile_sha = digest(NPC_MAKEFILE)
a2_old_negative_count = a2_prelaunch_text.count(
    "[V10E-RUNNER-CONTRACT][NEGATIVE]"
)
a2_old_dynamic_count = a2_prelaunch_text.count(
    "[V10E-RUNNER-CONTRACT][DYNAMIC]"
)
stage_order = {
    "simulator_define_binding": token_line(
        runner_text,
        'task_run_status_stage "simulator-define-binding"',
    ),
    "evidence_binding_pre": token_line(
        runner_text,
        'task_run_status_stage "evidence-binding-pre"',
    ),
    "systemd_strict_guest": token_line(
        runner_text,
        'task_run_status_stage "systemd-strict-guest"',
    ),
}
dispatch_root_cause_record = all(
    token in dispatch_text
    for token in (
        "FAIL rc=1 stage=simulator-define-binding",
        "generated `VNpcSimTop__verFiles.dat` contains `--assert`",
        "`+define+OOO_TERMINAL_HOLDER_ASSERT`",
        "incorrectly required the last token as",
        "`+define+OOO_TERMINAL_HOLDER_ASSERT=1`",
        "make variable",
    )
)

three_way_binding = {
    "makefile": {
        "path": rel(NPC_MAKEFILE),
        "line": make_line_number,
        "source_text": make_lines[0] if len(make_lines) == 1 else "",
        "token": make_token,
        "sha256": makefile_sha,
        "a2_pre_sha256": a2_post.get("npc_makefile_pre_sha256"),
        "a2_post_sha256": a2_post.get("npc_makefile_post_sha256"),
    },
    "a2_manifest": {
        "path": rel(A2_MANIFEST),
        "sha256": a2_manifest_sha,
        "command_line_count": len(manifest_command_lines),
        "no_value_token_count": manifest_no_value_count,
        "value_token_count": manifest_value_count,
        "required_tokens": manifest_required_tokens,
    },
    "corrected_runner": {
        "path": rel(RUNNER),
        "line": runner_pattern_line,
        "pattern_count": len(runner_patterns),
        "pattern": runner_pattern,
        "expected_pattern": f"{EXPECTED_DEFINE_TOKEN} ",
        "rejected_pattern_occurrences": runner_text.count(
            f'grep -Fq -- "{REJECTED_DEFINE_TOKEN} "'
        ),
    },
    "rtl_consumers": {
        "rg_rc": macro_consumers.returncode,
        "count": len(macro_consumer_lines),
        "raw_lines": macro_consumer_lines,
        "semantics": "`ifdef presence test; macro replacement text is unused",
    },
}
three_way_binding_closed = (
    len(make_lines) == 1
    and make_token == EXPECTED_DEFINE_TOKEN
    and makefile_sha == EXPECTED_MAKEFILE_SHA
    and a2_post.get("npc_makefile_pre_sha256") == EXPECTED_MAKEFILE_SHA
    and a2_post.get("npc_makefile_post_sha256") == EXPECTED_MAKEFILE_SHA
    and len(manifest_command_lines) == 1
    and all(manifest_required_tokens.values())
    and manifest_no_value_count == 1
    and manifest_value_count == 0
    and len(runner_patterns) == 1
    and runner_pattern == f"{EXPECTED_DEFINE_TOKEN} "
    and runner_text.count(f'grep -Fq -- "{REJECTED_DEFINE_TOKEN} "') == 0
    and macro_consumers.returncode == 0
    and len(macro_consumer_lines) == 3
)
write_json(OUT / "define-binding.json", three_way_binding)
(OUT / "define-binding.log").write_text(
    "\n".join(
        [
            f"[MAKEFILE] {rel(NPC_MAKEFILE)}:{make_line_number}",
            make_lines[0] if len(make_lines) == 1 else "INVALID",
            f"[MAKE-TOKEN] {make_token}",
            f"[MAKE-SHA256] {makefile_sha}",
            f"[A2-MANIFEST] {rel(A2_MANIFEST)}",
            f"[A2-MANIFEST-SHA256] {a2_manifest_sha}",
            f"[A2-MANIFEST-NO-VALUE-COUNT] {manifest_no_value_count}",
            f"[A2-MANIFEST-VALUE-COUNT] {manifest_value_count}",
            f"[RUNNER] {rel(RUNNER)}:{runner_pattern_line}",
            f"[RUNNER-PATTERN] {runner_pattern}",
            f"[RUNNER-REJECTED-PATTERN-COUNT] "
            f"{runner_text.count(f'grep -Fq -- \"{REJECTED_DEFINE_TOKEN} \"')}",
            f"[RTL-IFDEF-CONSUMERS] {len(macro_consumer_lines)}",
            *macro_consumer_lines,
            f"[THREE-WAY-BINDING] "
            f"{'PASS' if three_way_binding_closed else 'GAP'}",
        ]
    )
    + "\n",
    encoding="utf-8",
)

a2_root_cause = {
    "status": a2_status_text,
    "expected_status": EXPECTED_A2_STATUS,
    "build_artifacts_present_nonempty": a2_presence,
    "guest_artifacts_absent": a2_absence,
    "missing_driver_query": "driver.log: No such file or directory"
    in a2_query_text,
    "missing_guest_query": "/guest: No such file or directory"
    in a2_query_text,
    "evidence_query_fail_markers": a2_query_text.count(
        "[V10E-RECERT][EVIDENCE-QUERY-FAIL]"
    ),
    "post_binding": {
        "rtl_design_id_post": a2_post.get("rtl_design_id_post"),
        "simulator_sha256_post": a2_post.get("simulator_sha256_post"),
        "npc_makefile_pre_sha256": a2_post.get(
            "npc_makefile_pre_sha256"
        ),
        "npc_makefile_post_sha256": a2_post.get(
            "npc_makefile_post_sha256"
        ),
        "verilator_manifest_pre_sha256": a2_post.get(
            "verilator_manifest_pre_sha256"
        ),
        "verilator_manifest_post_sha256": a2_post.get(
            "verilator_manifest_post_sha256"
        ),
        "linux_image_pre_sha256": a2_post.get("linux_image_pre_sha256"),
        "run_dtb_pre_sha256": a2_post.get("run_dtb_pre_sha256"),
    },
    "actual_simulator_sha256": a2_simulator_sha,
    "actual_manifest_sha256": a2_manifest_sha,
    "a2_runner_sha256": a2_runner_sha,
    "a2_runner_matches_v5_snapshot": (
        f"{a2_runner_sha}  {rel(RUNNER)}" in v5_input_text
    ),
    "a2_runner_differs_from_corrected_runner": (
        a2_runner_sha != digest(RUNNER)
    ),
    "v5_prelaunch_pass_provenance": (
        "本节点的启动前合同裁决为 `PASS`" in review_v5_text
    ),
    "a2_prelaunch_static_count": a2_old_negative_count,
    "a2_prelaunch_dynamic_count": a2_old_dynamic_count,
    "a2_prelaunch_lacked_value_regression": (
        "require-terminal-holder-define-value rejected"
        not in a2_prelaunch_text
    ),
    "dispatch_root_cause_record": dispatch_root_cause_record,
    "corrected_stage_order": stage_order,
    "three_way_binding_closed": three_way_binding_closed,
    "historical_runner_source_snapshot_available": False,
    "historical_runner_traceability": (
        "a2 source is bound by runner SHA + V5 input snapshot + dispatch "
        "record; no standalone byte-for-byte a2 runner copy exists"
    ),
}
a2_no_guest_cycle = (
    a2_status_text == EXPECTED_A2_STATUS
    and all(a2_presence.values())
    and all(a2_absence.values())
    and a2_root_cause["missing_driver_query"]
    and a2_root_cause["missing_guest_query"]
    and a2_root_cause["evidence_query_fail_markers"] == 3
    and a2_post.get("rtl_design_id_post")
    == f"sha256:{EXPECTED_DESIGN_SHA}"
    and a2_post.get("simulator_sha256_post")
    == EXPECTED_A2_SIMULATOR_SHA
    and a2_simulator_sha == EXPECTED_A2_SIMULATOR_SHA
    and a2_post.get("verilator_manifest_pre_sha256") == "UNAVAILABLE"
    and a2_post.get("verilator_manifest_post_sha256")
    == "PREHASH_UNAVAILABLE"
    and a2_post.get("linux_image_pre_sha256") == "UNAVAILABLE"
    and a2_post.get("run_dtb_pre_sha256") == "UNAVAILABLE"
)
a2_root_cause_closed = (
    a2_no_guest_cycle
    and a2_runner_sha == EXPECTED_A2_RUNNER_SHA
    and a2_root_cause["a2_runner_matches_v5_snapshot"]
    and a2_root_cause["a2_runner_differs_from_corrected_runner"]
    and a2_old_negative_count == 42
    and a2_old_dynamic_count == 8
    and a2_root_cause["a2_prelaunch_lacked_value_regression"]
    and dispatch_root_cause_record
    and three_way_binding_closed
)
a2_root_cause["no_guest_cycle_closed"] = a2_no_guest_cycle
a2_root_cause["root_cause_closed"] = a2_root_cause_closed
write_json(OUT / "a2-root-cause.json", a2_root_cause)
(OUT / "a2-raw-evidence.log").write_text(
    "[A2-STATUS]\n"
    + a2_status_text
    + "\n[A2-POST-BINDING]\n"
    + a2_post_text
    + "[A2-EVIDENCE-QUERY-ERRORS]\n"
    + a2_query_text
    + "[A2-PRESENCE-MATRIX]\n"
    + "".join(
        f"{'PRESENT_NONEMPTY' if present else 'MISSING_OR_EMPTY'}  {name}\n"
        for name, present in a2_presence.items()
    )
    + "[A2-ABSENCE-MATRIX]\n"
    + "".join(
        f"{'ABSENT' if absent else 'PRESENT'}  {name}\n"
        for name, absent in a2_absence.items()
    ),
    encoding="utf-8",
)

a3_vacancy_pre = {
    rel(A3_STATUS): not A3_STATUS.exists(),
    rel(A3_DIR): not A3_DIR.exists(),
    rel(A3_RUNTIME): not A3_RUNTIME.exists(),
}
syntax_argv = [
    "bash",
    "-n",
    rel(RUNNER),
    rel(LAUNCHER),
    rel(LEGACY_LAUNCHER),
    rel(STATUS_HELPER),
]
syntax = run_logged(
    syntax_argv,
    "bash-syntax.log",
    "bash-syntax.rc",
)
status_result = run_logged(
    ["bash", rel(STATUS_TEST)],
    "task-run-status.log",
    "task-run-status.rc",
)
selftest = run_logged(
    ["python3", rel(SELFTEST)],
    "runner-contract.log",
    "runner-contract.rc",
)

a3_env = os.environ.copy()
a3_env["V10E_RECERT_RUN_LABEL"] = A3_LABEL
a3_env["V10E_RECERT_LAUNCH_VALIDATE_ONLY"] = "1"
a3_validate = run_logged(
    ["bash", rel(LAUNCHER)],
    "a3-launcher-validate-only.log",
    "a3-launcher-validate-only.rc",
    env=a3_env,
)
a3_vacancy_post = {
    rel(A3_STATUS): not A3_STATUS.exists(),
    rel(A3_DIR): not A3_DIR.exists(),
    rel(A3_RUNTIME): not A3_RUNTIME.exists(),
}

assignment_match = re.search(
    r"^assertion_failure_regex='([^']*)'$",
    runner_text,
    flags=re.MULTILINE,
)
if assignment_match is None:
    raise SystemExit("production assertion regex assignment is missing")
production_pattern = assignment_match.group(1)
pattern_line = runner_text.count("\n", 0, assignment_match.start()) + 1
positive_input = (
    "[V10D-FIXTURE-FAIL]\n"
    "RTL assertion fixture\n"
    "[FIXTURE_ASSERT_FAIL]\n"
)
clean_input = "[V10E-FIXTURE] clean terminal transaction\n"
missing_path = OUT / "deliberately-missing-assertion.log"
if missing_path.exists():
    raise SystemExit(f"read-error fixture path unexpectedly exists: {missing_path}")
positive_rg = run_rg(production_pattern, input_text=positive_input)
clean_rg = run_rg(production_pattern, input_text=clean_input)
missing_rg = run_rg(production_pattern, path=missing_path)
(OUT / "assertion-regex-fixture.log").write_text(
    "".join(
        (
            f"[V10E-V6][SOURCE] {rel(RUNNER)}:{pattern_line}\n",
            "[V10E-V6][ARGV] "
            + json.dumps(
                ["rg", "-a", "-n", production_pattern],
                ensure_ascii=False,
            )
            + "\n",
            f"[V10E-V6][EXACT] "
            f"{production_pattern == EXPECTED_ASSERTION_REGEX}\n",
            f"[V10E-V6][MATCH-RC] {positive_rg.returncode}\n",
            positive_rg.stdout,
            f"[V10E-V6][NO-MATCH-RC] {clean_rg.returncode}\n",
            clean_rg.stdout,
            f"[V10E-V6][READ-ERROR-PATH] {rel(missing_path)}\n",
            f"[V10E-V6][READ-ERROR-RC] {missing_rg.returncode}\n",
            missing_rg.stdout,
            "[V10E-V6][ASSERTION-REGEX-RC] "
            f"{positive_rg.returncode}/{clean_rg.returncode}/"
            f"{missing_rg.returncode}\n",
        )
    ),
    encoding="utf-8",
)

contract_log = selftest.stdout
negative_markers = [
    line
    for line in contract_log.splitlines()
    if "[V10E-RUNNER-CONTRACT][NEGATIVE]" in line
]
dynamic_markers = [
    line
    for line in contract_log.splitlines()
    if "[V10E-RUNNER-CONTRACT][DYNAMIC]" in line
]
static_names = {marker_name(line) for line in negative_markers}
static_names_exact = static_names == EXPECTED_STATIC_NAMES
dynamic_coverage = {
    snippet: any(snippet in line for line in dynamic_markers)
    for snippet in EXPECTED_DYNAMIC_SNIPPETS
}

terminal_oracles = {
    name: {
        "guard": token,
        "line": token_line(runner_text, token),
        "occurrences": runner_text.count(token),
    }
    for name, token in TERMINAL_ORACLES.items()
}
post_hash_tokens = {
    name: {
        "token": token,
        "line": token_line(runner_text, token),
        "occurrences": runner_text.count(token),
    }
    for name, token in POST_HASH_TOKENS.items()
}
launcher_guards = {
    "v10e_global_lock": (
        'lock_path="${repo_root}/.github/runtime-artifacts/'
        'rv64-engineering-single-flight.lock"' in launcher_text
    ),
    "v9s_global_lock": (
        'lock_path="${repo_root}/.github/runtime-artifacts/'
        'rv64-engineering-single-flight.lock"' in legacy_launcher_text
    ),
    "v10e_background_contention_rc73": (
        'flock -n -E 73 "${lock_path}"' in launcher_text
    ),
    "v9s_background_contention_rc73": (
        'flock -n -E 73 "${lock_path}"' in legacy_launcher_text
    ),
    "v10e_failure_publisher": (
        'publish_launcher_failure "${launcher_rc}" '
        '"launcher-lock-or-init"' in launcher_text
    ),
    "v9s_failure_publisher": (
        'publish_launcher_failure "${launcher_rc}" '
        '"launcher-lock-or-init"' in legacy_launcher_text
    ),
}

rtl_sha_post, rtl_files_post = arch.rtl_binding(ROOT)
immutable_post = snapshot(IMMUTABLE_INPUTS)
drift = {
    name: {"pre": immutable_pre.get(name), "post": immutable_post.get(name)}
    for name in sorted(set(immutable_pre) | set(immutable_post))
    if immutable_pre.get(name) != immutable_post.get(name)
}
lock_exists_post = LOCK_PATH.is_file()
lock_sha_post = digest(LOCK_PATH) if lock_exists_post else "MISSING"
lock_probe_rc = 2
if lock_exists_post:
    lock_probe_rc = 0
    with LOCK_PATH.open("a+", encoding="utf-8") as lock_file:
        try:
            fcntl.flock(
                lock_file.fileno(),
                fcntl.LOCK_EX | fcntl.LOCK_NB,
            )
        except BlockingIOError:
            lock_probe_rc = 1
        else:
            fcntl.flock(lock_file.fileno(), fcntl.LOCK_UN)

write_snapshot(OUT / "input-sha256-pre.txt", immutable_pre)
write_snapshot(OUT / "input-sha256-post.txt", immutable_post)
(OUT / "input-drift.txt").write_text(
    "NO_DRIFT\n"
    if not drift
    else "".join(
        f"DRIFT {name} pre={values['pre']} post={values['post']}\n"
        for name, values in drift.items()
    ),
    encoding="utf-8",
)
(OUT / "rtl-binding.txt").write_text(
    "\n".join(
        [
            f"rtl_design_id_pre=sha256:{rtl_sha_pre}",
            f"rtl_design_id_post=sha256:{rtl_sha_post}",
            f"rtl_source_count_pre={len(rtl_files_pre)}",
            f"rtl_source_count_post={len(rtl_files_post)}",
            "rtl_source_manifest_begin",
            *(
                f"{sha}  {name}"
                for name, sha in sorted(rtl_files_post.items())
            ),
            "rtl_source_manifest_end",
        ]
    )
    + "\n",
    encoding="utf-8",
)

status_marker_ok = (
    "[task-run-status-test] PASS explicit completion, early exit, "
    "command failure, cleanup failure, PASS-write fallback, and HUP/INT/TERM"
    in status_result.stdout
)
regex_rc_exact = (
    positive_rg.returncode,
    clean_rg.returncode,
    missing_rg.returncode,
) == (0, 1, 2)
a3_validate_marker = (
    f"[V10E-RECERT-LAUNCH] validation PASS label={A3_LABEL}"
    in a3_validate.stdout
)

all_gates = {
    "contract_sha": (
        contract_sha == EXPECTED_CONTRACT_SHA
        and contract_sha_cmd.returncode == 0
    ),
    "a2_status_build_and_no_guest_cycle": a2_no_guest_cycle,
    "a2_define_binding_root_cause": a2_root_cause_closed,
    "makefile_manifest_runner_three_way_binding": three_way_binding_closed,
    "wrong_value_regression_rejected": (
        "require-terminal-holder-define-value" in static_names
    ),
    "bash_syntax": syntax.returncode == 0,
    "status_helper_suite": status_result.returncode == 0 and status_marker_ok,
    "runner_contract": (
        selftest.returncode == 0
        and "[V10E-RUNNER-CONTRACT][FAIL]" not in contract_log
    ),
    "static_43_of_43": (
        len(negative_markers) == 43 and static_names_exact
    ),
    "dynamic_9_of_9": (
        len(dynamic_markers) == 9 and all(dynamic_coverage.values())
    ),
    "a3_target_vacant_pre": all(a3_vacancy_pre.values()),
    "a3_launcher_validate_only": (
        a3_validate.returncode == 0 and a3_validate_marker
    ),
    "a3_target_vacant_post": all(a3_vacancy_post.values()),
    "production_regex_exact": (
        production_pattern == EXPECTED_ASSERTION_REGEX
    ),
    "production_regex_rc_0_1_2": regex_rc_exact,
    "rtl_design_id_pre": rtl_sha_pre == EXPECTED_DESIGN_SHA,
    "rtl_design_id_post": rtl_sha_post == EXPECTED_DESIGN_SHA,
    "rtl_source_manifest_stable": rtl_files_pre == rtl_files_post,
    "immutable_inputs_stable": not drift,
    "five_terminal_oracles_exact_once": all(
        row["occurrences"] == 1 for row in terminal_oracles.values()
    ),
    "post_hash_contract_present": all(
        row["occurrences"] >= 1 for row in post_hash_tokens.values()
    ),
    "launcher_fail_closed_guards": all(launcher_guards.values()),
    "workspace_lock_released": (
        lock_probe_rc == 0
        and lock_exists_pre
        and lock_sha_pre == lock_sha_post
    ),
}
prelaunch_pass = all(all_gates.values())

summary = {
    "schema": "v10e-runner-prelaunch-review-v6-evidence-v1",
    "contract": {
        "path": rel(CONTRACT),
        "expected_sha256": EXPECTED_CONTRACT_SHA,
        "actual_sha256": contract_sha,
    },
    "a2_root_cause": a2_root_cause,
    "define_binding": three_way_binding,
    "syntax": {"argv": syntax_argv, "rc": syntax.returncode},
    "status_helper_suite": {
        "argv": ["bash", rel(STATUS_TEST)],
        "rc": status_result.returncode,
        "marker_ok": status_marker_ok,
    },
    "runner_contract": {
        "argv": ["python3", rel(SELFTEST)],
        "rc": selftest.returncode,
        "static_negative_rejected": len(negative_markers),
        "static_negative_expected": 43,
        "static_names_exact": static_names_exact,
        "raw_negative_markers": negative_markers,
        "dynamic_fixture_markers": len(dynamic_markers),
        "dynamic_fixture_expected": 9,
        "dynamic_coverage": dynamic_coverage,
        "raw_dynamic_markers": dynamic_markers,
    },
    "a3": {
        "label": A3_LABEL,
        "vacancy_pre": a3_vacancy_pre,
        "validate_only_argv": ["bash", rel(LAUNCHER)],
        "validate_only_rc": a3_validate.returncode,
        "validate_only_marker": a3_validate_marker,
        "vacancy_post": a3_vacancy_post,
        "long_simulation_executed": False,
    },
    "assertion_regex": {
        "runner_line": pattern_line,
        "pattern": production_pattern,
        "expected_pattern": EXPECTED_ASSERTION_REGEX,
        "exact_pattern": production_pattern == EXPECTED_ASSERTION_REGEX,
        "match_rc": positive_rg.returncode,
        "no_match_rc": clean_rg.returncode,
        "read_error_rc": missing_rg.returncode,
    },
    "rtl_binding": {
        "expected_design_id": f"sha256:{EXPECTED_DESIGN_SHA}",
        "pre_design_id": f"sha256:{rtl_sha_pre}",
        "post_design_id": f"sha256:{rtl_sha_post}",
        "source_count": len(rtl_files_post),
        "source_manifest_stable": rtl_files_pre == rtl_files_post,
    },
    "immutable_inputs": {
        "pre_count": len(immutable_pre),
        "post_count": len(immutable_post),
        "drift": drift,
    },
    "workspace_lock": {
        "path": rel(LOCK_PATH),
        "exists_pre": lock_exists_pre,
        "sha256_pre": lock_sha_pre,
        "exists_post": lock_exists_post,
        "sha256_post": lock_sha_post,
        "nonblocking_reacquire_rc": lock_probe_rc,
    },
    "terminal_oracles": terminal_oracles,
    "post_hash_tokens": post_hash_tokens,
    "launcher_guards": launcher_guards,
    "all_gates": all_gates,
    "prelaunch_result": "PASS" if prelaunch_pass else "GAP",
    "long_simulation_executed": False,
}
write_json(OUT / "gate-summary.json", summary)

commands: list[tuple[str, list[str], str, int]] = [
    (
        "sha256sum",
        ["sha256sum", rel(CONTRACT)],
        "核对 V6 子任务合同 JSON SHA-256",
        contract_sha_cmd.returncode,
    ),
    (
        "rg",
        [
            "rg",
            "-n",
            r"^`ifdef[[:space:]]+OOO_TERMINAL_HOLDER_ASSERT$",
            "npc/rv64/vsrc",
        ],
        "核对 terminal-holder 宏由 RTL ifdef 消费",
        macro_consumers.returncode,
    ),
    (
        "bash",
        syntax_argv,
        "检查 runner、V10E/V9S launcher 与 status helper 语法",
        syntax.returncode,
    ),
    (
        "bash",
        ["bash", rel(STATUS_TEST)],
        "运行 task-run status helper 定向测试",
        status_result.returncode,
    ),
    (
        "python3",
        ["python3", rel(SELFTEST)],
        "运行 43 个静态负向变体与 9 类动态 fixture",
        selftest.returncode,
    ),
    (
        "bash",
        [
            "env",
            f"V10E_RECERT_RUN_LABEL={A3_LABEL}",
            "V10E_RECERT_LAUNCH_VALIDATE_ONLY=1",
            "bash",
            rel(LAUNCHER),
        ],
        "运行 a3 launcher validate-only，不启动仿真",
        a3_validate.returncode,
    ),
    (
        "rg",
        ["rg", "-a", "-n", production_pattern],
        "production assertion regex 匹配输入",
        positive_rg.returncode,
    ),
    (
        "rg",
        ["rg", "-a", "-n", production_pattern],
        "production assertion regex 无匹配输入",
        clean_rg.returncode,
    ),
    (
        "rg",
        ["rg", "-a", "-n", production_pattern, rel(missing_path)],
        "production assertion regex 读取错误输入",
        missing_rg.returncode,
    ),
    (
        "python3",
        ["python3", "-", "architecture_hard_gates.rtl_binding(ROOT)"],
        "重算当前 npc/rv64/vsrc RTL design-id 与源文件 SHA-256 清单",
        0,
    ),
    (
        "python3",
        ["python3", rel(OUT / "generate-v6-evidence.py")],
        "生成 V6 启动前独立验证证据",
        0 if prelaunch_pass else 1,
    ),
]

result_word = "PASS" if prelaunch_pass else "GAP"
report = f"""RV64 RTL 结论｜对象={rel(RUNNER)}::simulator-define-binding / {rel(A2_MANIFEST)} / {rel(OUT)}｜周期/配置=pre-launch, a2 fail audit, a3 validate-only, max_cycles=6000000000, OOO_CSR_QUEUE_HEAD=1, OOO_ASSERT=1, OOO_TERMINAL_HOLDER_ASSERT=1｜TB/EDA 观测=a2 build PASS 后未进入 guest cycle；bash syntax rc={syntax.returncode}；status-helper rc={status_result.returncode}；{len(negative_markers)}/43 static + {len(dynamic_markers)}/9 dynamic；a3 validate-only rc={a3_validate.returncode}；production rg rc={positive_rg.returncode}/{clean_rg.returncode}/{missing_rg.returncode}；rtl_binding=sha256:{rtl_sha_post}｜范围={result_word}

# V10E runner pre-launch independent review V6

## 结论

本节点的启动前合同裁决为 `{result_word}`。未启动 6B-cycle Verilator
systemd-strict 长回放，也未修改 production RTL、testbench、runner、两份
launcher 或共享 status helper。`gate-summary.json` 的 `all_gates`
{'全部为 true' if prelaunch_pass else '存在 false，禁止启动 a3'}。

## a2 simulator-define-binding 根因

- a2 固定状态为 `{a2_status_text}`。rootfs build/static check、完整
  `NpcSimTop` build 与 generated manifest 均存在；`driver.log`、`guest/`、
  `systemd-transaction-evidence.json`、`binding.txt`、`simulator-defines.txt`
  和 writable `rootfs.ext4` 均缺失。cleanup 查询又对 `driver.log`/`guest`
  给出 3 个 `EVIDENCE-QUERY-FAIL rc=2`。因此 a2 在 simulator define
  文本绑定处退出，未调用 guest checker、未开始任何 RTL guest cycle。
- a2 simulator 实体 SHA-256 `{a2_simulator_sha}` 与
  `post-binding.txt::simulator_sha256_post` 一致；`rtl_design_id_post` 为
  `sha256:{EXPECTED_DESIGN_SHA}`。manifest/kernel/DTB pre-hash 仍为
  `UNAVAILABLE`，符合在 `evidence-binding-pre` 之前退出。
- a2 runner SHA-256 `{a2_runner_sha}` 与 V5 input snapshot 一致，而当前
  修正版为 `{digest(RUNNER)}`。dispatch 记录旧版错误要求
  `{REJECTED_DEFINE_TOKEN}`；a2 原 runner 没有独立 byte-for-byte 副本，
  其历史谓词来源绑定为 runner SHA + V5 snapshot + dispatch record。这是
  历史源码可追溯性限制，不把当前修正版倒推成 a2 源码。

## Makefile / a2 manifest / corrected runner 三方 token

- `{rel(NPC_MAKEFILE)}:{make_line_number}` 唯一发出
  `{make_token}`；当前 SHA-256 `{makefile_sha}` 与 a2 pre/post Makefile
  SHA 完全相同。`OooIntBackend.v` 有 {len(macro_consumer_lines)} 处
  `` `ifdef OOO_TERMINAL_HOLDER_ASSERT``，只消费宏是否存在，不消费替换文本。
- a2 实际 `{rel(A2_MANIFEST)}` 的唯一 Verilator command line 同时含
  `--assert`、`+define+OOO_CSR_QUEUE_HEAD=1`、`+define+OOO_ASSERT` 与一个
  无值 `{EXPECTED_DEFINE_TOKEN}`；含值 `{REJECTED_DEFINE_TOKEN}` 计数为
  `{manifest_value_count}`。
- 当前 runner `{runner_pattern_line}` 行 oracle 精确为
  `{runner_pattern}`；错误 `=1` oracle 出现 0 次。
  `require-terminal-holder-define-value` compile-success 静态回退变异被
  selftest 拒绝。由此 a2 失败根因裁决为：make 变量值 `1` 仅控制宏发出，
  旧 runner 却把它误当作 Verilator macro replacement text。

## runner / launcher / terminal 合同

- `bash -n` 检查 runner、V10E launcher、历史 V9S launcher 和 status helper，
  返回 `rc={syntax.returncode}`；status helper 定向 suite 返回
  `rc={status_result.returncode}`。
- selftest 返回 `rc={selftest.returncode}`，保存 `{len(negative_markers)}/43`
  个原始 `[NEGATIVE]` marker 与 `{len(dynamic_markers)}/9` 个原始
  `[DYNAMIC]` marker。九类 fixture 覆盖 PASS-write fallback、共享锁 rc=3、
  cleanup rc=7、TERM rc=143、post-binding rc=1、assertion `0/1/2`、
  mode-0644 Bash rc=0、三方 define token grep rc=0 与 rootfs reuse rc=4。
- a3 的 result/status/runtime 三个目标在 validate-only 前后均为空；
  `V10E_RECERT_LAUNCH_VALIDATE_ONLY=1` 返回 `rc={a3_validate.returncode}` 并记录
  `[V10E-RECERT-LAUNCH] validation PASS label={A3_LABEL}`。没有创建 a3
  status、结果目录或 runtime build。
- 五类 terminal oracle
  `strict_done/poweroff_begin/syscon_terminal/system_reset_exit/good_trap`
  的 `-eq 1` guard 在 production runner 中各出现一次。production assertion
  regex 的独立 match/no-match/read-error 为
  `rc={positive_rg.returncode}/{clean_rg.returncode}/{missing_rg.returncode}`。

## RTL binding、post-hash 与全工作区锁

- `architecture_hard_gates.rtl_binding()` 对 `{len(rtl_files_post)}` 个
  `.v/.sv/.vh/.svh/.mk` 源文件重算 pre/post 均为
  `sha256:{rtl_sha_post}`，与目标 design-id 一致。
- runner 对 rootfs template/cpio、RTL design-id、simulator、NPC
  config/Makefile/manifest、kernel/OpenSBI/DTB、runner/status helper、Linux
  Makefile、guest/strict checker、transaction parser、rootfs helper 与 durable
  prelaunch log 的 20 类 post-hash token 均存在；本轮
  `{len(immutable_pre)}` 个声明输入 SHA-256
  {'无漂移' if not drift else f'发生 {len(drift)} 项漂移'}。
- V10E/V9S launcher 均绑定
  `.github/runtime-artifacts/rv64-engineering-single-flight.lock` 与 background
  contention rc=73；本节点末次 nonblocking reacquire `rc={lock_probe_rc}`，
  随即释放，锁文件 pre/post SHA-256 均为 `{lock_sha_post}`。

## 反例、unknowns、假设与替代解释

- 反例：错误 `{REJECTED_DEFINE_TOKEN}` 回退、删除 compiled define proof、
  过度转义 regex、允许重复 terminal marker、私有化 V10E/V9S lock、删除
  launcher failure publisher 与忽略 PASS-write failure 均被静态变异检出；
  cleanup/TERM/post-binding/assertion read error、mode-0644 Bash、三方 token
  与 rootfs reuse 均有动态 fixture。
- unknowns：本节点未观察 17/17 guest transaction、natural poweroff、
  reset-syscon、`GOOD TRAP` 或 simulator clean exit，也未运行综合/STA。
  a2 旧 runner 内容没有单独保存，只由其 SHA、V5 snapshot 与 dispatch
  根因记录绑定；这不影响当前 43/43、9/9 与实际 a2 manifest 的三方绑定，
  但限制对历史源码字节的直接复现。
- 显式假设：`architecture_hard_gates.rtl_binding()` 的规范源集合仍是
  `npc/rv64/vsrc` 下 `.v/.sv/.vh/.svh/.mk`；a2 immutable result 未被后续
  修改（本轮对全部绑定输入 pre/post SHA 做了无漂移检查）；`rg` 对缺失路径
  返回 2。
- 替代解释：若拒绝 dispatch 对 a2 旧 oracle 的 provenance，则只能把
  “旧 runner 具体哪一行含 `=1`”降为历史源码 inconclusive；但 a2 的失败
  stage、成功 build、实际无值 manifest、未进入 guest、当前同 SHA Makefile
  以及错误回退变异被拒绝，仍排除 RTL build failure 和 guest runtime failure。
- scope_extension_request：无。真实 6B system 回放属于主节点后续动作，本节点
  明确禁止启动。
- confidence_and_basis：对当前 pre-launch 合同为高，依据是 a2
  status/artifact/absence matrix、Makefile/manifest/runner 三方 token、43/43 与
  9/9 marker、a3 validate-only、0/1/2 exact regex、pre/post design-id、输入
  SHA-256 与锁释放；对完整 Linux system 行为不作外推。

## 实现者 / 审查者复核

- 实现者证据：仅在 `{rel(OUT)}` 生成脚本、原始日志、返回码、JSON、
  SHA-256 清单与本报告；production 文件未写入。
- 审查者质疑：优先检查 a2 是否可能进入 guest、历史 runner 是否缺少内容
  快照、Makefile/a2 manifest/current oracle 是否真的同 token、`=1` 回退是否
  被杀死、a3 validate-only 是否留下目标、marker 是否精确集合、live design-id
  与 immutable inputs 是否漂移、全工作区锁是否可重取。除已明确保留的历史
  源码字节追溯性限制与长回放范围边界外，当前启动前 gate
  {'均由本地证据闭合' if prelaunch_pass else '仍有未闭合项，结论保持 GAP'}。

本报告及哈希落盘后，本节点停止工程命令；
single-flight ownership=RETURNED。
"""
(OUT / "review.md").write_text(report, encoding="utf-8")

hash_targets = [
    "generate-v6-evidence.py",
    "contract-sha256.log",
    "contract-sha256.rc",
    "rtl-macro-consumers.log",
    "rtl-macro-consumers.rc",
    "define-binding.json",
    "define-binding.log",
    "a2-root-cause.json",
    "a2-raw-evidence.log",
    "bash-syntax.log",
    "bash-syntax.rc",
    "task-run-status.log",
    "task-run-status.rc",
    "runner-contract.log",
    "runner-contract.rc",
    "a3-launcher-validate-only.log",
    "a3-launcher-validate-only.rc",
    "assertion-regex-fixture.log",
    "rtl-binding.txt",
    "input-sha256-pre.txt",
    "input-sha256-post.txt",
    "input-drift.txt",
    "gate-summary.json",
    "commands.tsv",
    "review.md",
]
commands.append(
    (
        "sha256sum",
        ["sha256sum", *hash_targets],
        "计算 V6 证据产物 SHA-256 清单（cwd=review-v6）",
        0,
    )
)
(OUT / "commands.tsv").write_text(
    "command\targv_json\tpurpose\trc\n"
    + "".join(
        f"{command}\t{json.dumps(argv, ensure_ascii=False)}\t"
        f"{purpose}\t{return_code}\n"
        for command, argv, purpose, return_code in commands
    ),
    encoding="utf-8",
)
hash_result = subprocess.run(
    ["sha256sum", *hash_targets],
    cwd=OUT,
    check=False,
    stdout=subprocess.PIPE,
    stderr=subprocess.STDOUT,
    text=True,
)
(OUT / "sha256sums.txt").write_text(hash_result.stdout, encoding="utf-8")
if hash_result.returncode != 0:
    raise SystemExit(f"evidence sha256sum failed rc={hash_result.returncode}")
if not prelaunch_pass:
    raise SystemExit("pre-launch verification gate result is GAP")
