#!/usr/bin/env python3
from __future__ import annotations

import pathlib
import fcntl
import os
import re
import subprocess
import sys
import tempfile


EXPECTED_DESIGN = (
    "5f9dd06860a91dfc5461357c731fa2d4c34b91cb3b3cdedc754f0972f8bf4c5a"
)
GLOBAL_LOCK = (
    'lock_path="${repo_root}/.github/runtime-artifacts/'
    'rv64-engineering-single-flight.lock"'
)
EXPECTED_ASSERTION_REGEX = (
    r"\[(V9Q-(BRIDGE-HOLDER|TRANSIENT-HOLDER|TRANSIENT-BRIDGE|"
    r"DUAL-REQ-TOKEN)-DISJOINT|V9R-(MEM-)?SQ-RETRY-C0-HANDOFF|"
    r"S2-G1-TCOLL-INGRESS-DUP|"
    r"V10D-[^]]*FAIL)\]|%Error:|Assertion failed|RTL assertion|"
    r"\[.*ASSERT.*FAIL"
)


def validate(
    text: str,
    launcher_text: str,
    legacy_launcher_text: str,
) -> list[str]:
    required = {
        "current design binding": f'expected_design_sha="{EXPECTED_DESIGN}"',
        "six-billion-cycle floor": 'min_max_cycles="6000000000"',
        "canonical simulator config": (
            'task_run_status_stage "simulator-config-canonical"'
        ),
        "simulator config hash binding": (
            '"${repo_root}/npc/rv64/configs/default_defconfig"'
        ),
        "queue-head build config": "  OOO_CSR_QUEUE_HEAD=1 \\",
        "queue-head evidence binding": (
            'printf \'%s\\n\' "OOO_CSR_QUEUE_HEAD=1"'
        ),
        "queue-head compiled define": (
            'grep -Fq -- "+define+OOO_CSR_QUEUE_HEAD=1 "'
        ),
        "ordinary RTL assertion compiled define": (
            'grep -Fq -- "+define+OOO_ASSERT "'
        ),
        "terminal-holder build config": (
            "  OOO_TERMINAL_HOLDER_ASSERT=1 \\"
        ),
        "terminal-holder compiled define": (
            'grep -Fq -- "+define+OOO_TERMINAL_HOLDER_ASSERT "'
        ),
        "verilator assertion mode": 'grep -Fq -- "--assert"',
        "makefile pre-hash": (
            'npc_makefile_sha_pre="$(\n'
            '  sha256sum "${repo_root}/npc/rv64/Makefile"'
        ),
        "verilator manifest pre-hash": (
            'verilator_manifest_sha_pre="$(\n'
            '  sha256sum "${verilator_manifest}"'
        ),
        "zero-UART mode": "NPC_SYSTEMD_GUEST_COMMAND_MODE=systemd-strict",
        "isolated rootfs": "NPC_SYSTEMD_ROOTFS_WORK_IMAGE=",
        "rootfs copy helper binding": (
            '"${repo_root}/Linux/scripts/prepare-npc-rootfs-run-image.sh"'
        ),
        "rootfs run-image pre-hash proof": (
            "rootfs_run_image_sha256_pre=${rootfs_template_sha}"
        ),
        "transaction evidence": "NPC_SYSTEMD_TRANSACTION_EVIDENCE=",
        "bounded ecall trace": "NPC_USER_ECALL_TRACE=1 \\",
        "privileged ecall trap trace": "NPC_USER_ECALL_TRACE_PRIV=1 \\",
        "late ecall trace floor": "NPC_USER_ECALL_MIN_COMMIT=1100000000 \\",
        "bounded ecall trace limit": "NPC_USER_ECALL_TRACE_LIMIT=8192 \\",
        "ecall path trace disabled": "NPC_USER_ECALL_PATH_TRACE=0 \\",
        "ecall tail evidence": '"${result_dir}/user-ecall-tail.txt"',
        "raw kernel terminal capture": "reboot: Power down",
        "raw syscon terminal capture": (
            "syscon-reset: poweroff requested value=0x00005555"
        ),
        "strict 17-label oracle": "strict_expected_count != 17",
        "clean RTL assertion oracle": 'test ! -s "${result_dir}/rtl-assertion-failures.txt"',
        "fail-closed helper": 'source "${status_helper}"',
        "evidence completion": "task_run_status_mark_evidence_complete",
        "no shared build directory": 'build_dir="${runtime_dir}/sim-build"',
        "missing simulator post failure": (
            "simulator_sha256_post=MISSING_OR_NOT_EXECUTABLE"
        ),
        "config post hash": 'verify_post_hash "npc_config"',
        "makefile post hash": 'verify_post_hash \\\n      "npc_makefile"',
        "manifest post hash": 'verify_post_hash \\\n      "verilator_manifest"',
        "kernel post hash": 'verify_post_hash "linux_image"',
        "opensbi post hash": 'verify_post_hash "opensbi_fw"',
        "dtb post hash": 'verify_post_hash "run_dtb"',
        "cleanup generic signal deferral": (
            "trap 'defer_cleanup_signal CLEANUP 143' HUP INT TERM"
        ),
        "cleanup HUP deferral": (
            "trap 'defer_cleanup_signal HUP 129' HUP"
        ),
        "cleanup INT deferral": (
            "trap 'defer_cleanup_signal INT 130' INT"
        ),
        "cleanup TERM deferral": (
            "trap 'defer_cleanup_signal TERM 143' TERM"
        ),
        "atomic post-binding temporary": (
            'post_binding_tmp="${result_dir}/post-binding.txt.tmp.$$"'
        ),
        "post-binding write failure capture": (
            '} >"${post_binding_tmp}"; then'
        ),
        "post-binding rename failure capture": (
            '"${result_dir}/post-binding.txt" || post_binding_rc=$?'
        ),
        "assertion query error distinction": "record_optional_rg()",
        "assertion query error marker": "EVIDENCE-QUERY-FAIL",
        "occurrence-level terminal counter": (
            "count_fixed_terminal_occurrences() {"
        ),
        "same-line terminal occurrence extraction": (
            'grep -a -F -o -- "${marker}" "${path}"'
        ),
        "terminal count query error marker": "TERMINAL-QUERY-FAIL",
        "production assertion regex": (
            f"assertion_failure_regex='{EXPECTED_ASSERTION_REGEX}'"
        ),
        "production assertion regex use": '"${assertion_failure_regex}"',
        "production terminal regex use": '"${terminal_evidence_regex}"',
        "guest checker readable preflight": 'test -r "${guest_checker}"',
        "guest checker nonempty preflight": 'test -s "${guest_checker}"',
        "guest checker Bash invocation": 'bash "${guest_checker}"',
        "runner script post hash": (
            'verify_post_hash \\\n      "runner_script"'
        ),
        "status helper post hash": (
            'verify_post_hash \\\n      "task_run_status_helper"'
        ),
        "guest checker post hash": (
            'verify_post_hash \\\n      "guest_checker"'
        ),
        "strict checker post hash": (
            'verify_post_hash \\\n      "strict_checker"'
        ),
        "transaction parser post hash": (
            'verify_post_hash \\\n      "transaction_parser"'
        ),
        "rootfs helper post hash": (
            'verify_post_hash \\\n      "rootfs_copy_helper"'
        ),
        "prelaunch contract log post hash": (
            'verify_post_hash \\\n      "prelaunch_contract_log"'
        ),
        "runner contract post hash": (
            'verify_post_hash \\\n      "runner_contract"'
        ),
        "strict checker test post hash": (
            'verify_post_hash \\\n      "strict_checker_test"'
        ),
        "guest checker test post hash": (
            'verify_post_hash \\\n      "guest_checker_test"'
        ),
        "transaction parser test post hash": (
            'verify_post_hash \\\n      "transaction_parser_test"'
        ),
        "debug flags contract post hash": (
            'verify_post_hash \\\n      "debug_flags_contract"'
        ),
        "status-covered runner preflight": (
            'task_run_status_stage "runner-preflight"'
        ),
        "strict done exactly once": (
            '[[ "${strict_done_count}" -eq 1 ]]'
        ),
        "poweroff begin exactly once": (
            '[[ "${poweroff_begin_count}" -eq 1 ]]'
        ),
        "kernel power down exactly once": (
            '[[ "${kernel_power_down_count}" -eq 1 ]]'
        ),
        "syscon terminal exactly once": (
            '[[ "${syscon_terminal_count}" -eq 1 ]]'
        ),
        "system reset exit exactly once": (
            '[[ "${system_reset_exit_count}" -eq 1 ]]'
        ),
        "good trap exactly once": (
            '[[ "${good_trap_count}" -eq 1 ]]'
        ),
    }
    missing = [name for name, token in required.items() if token not in text]
    if "System Power Off" in text:
        missing.append("systemd milestone must not be a terminal oracle")
    terminal_pattern_match = re.search(
        r"^terminal_evidence_regex='([^']*)'$",
        text,
        flags=re.MULTILINE,
    )
    required_terminal_markers = (
        "reboot: Power down",
        "syscon-reset: poweroff requested value=0x00005555",
        "exit via system-reset, code=0",
        "HIT GOOD TRAP",
    )
    if terminal_pattern_match is None:
        missing.append("production terminal regex assignment")
    else:
        terminal_pattern = terminal_pattern_match.group(1)
        missing.extend(
            f"terminal capture marker {marker}"
            for marker in required_terminal_markers
            if marker not in terminal_pattern
        )
    evidence_tokens = {
        "queue-head verified evidence records": (
            'printf \'%s\\n\' "OOO_CSR_QUEUE_HEAD=1"'
        ),
        "ordinary assertion verified evidence records": (
            'printf \'%s\\n\' "OOO_ASSERT=1"'
        ),
        "terminal-holder verified evidence records": (
            'printf \'%s\\n\' "OOO_TERMINAL_HOLDER_ASSERT=1"'
        ),
    }
    for name, token in evidence_tokens.items():
        if text.count(token) < 2:
            missing.append(name)

    restore_start = text.find("restore_npc_config() {")
    restore_end = text.find("\n}\n\nverify_post_hash() {", restore_start)
    if restore_start < 0 or restore_end < 0:
        missing.append("bounded restore function")
    else:
        restore_body = text[restore_start:restore_end]
        if "set -e" in restore_body or "set +e" in restore_body:
            missing.append("restore must not mutate errexit")

    record_start = text.find("record_optional_rg() {")
    count_start = text.find("count_fixed_terminal_occurrences() {")
    capture_start = text.find("capture_terminal_evidence() {")
    capture_end = text.find("\n}\n\ndefer_cleanup_signal() {", capture_start)
    if (
        record_start < 0
        or count_start < 0
        or capture_start < 0
        or capture_end < 0
    ):
        missing.append("bounded terminal evidence capture")
    elif "|| true" in text[record_start:capture_end]:
        missing.append("terminal evidence query errors must not be ignored")
    else:
        count_body = text[count_start:capture_start]
        if 'grep -a -F -o -- "${marker}" "${path}"' not in count_body:
            missing.append("terminal evidence must count marker occurrences")
        if 'return "${query_rc}"' not in count_body:
            missing.append("terminal occurrence query must fail closed")

    finish_start = text.find("finish() {")
    restore_call = text.find("\n  restore_npc_config\n", finish_start)
    finalize_call = text.find(
        'task_run_status_finalize "${command_rc}" "${cleanup_rc}"',
        finish_start,
    )
    if (
        finish_start < 0
        or restore_call < 0
        or finalize_call < 0
        or restore_call > finalize_call
    ):
        missing.append("cleanup before status finalize")
    trap_install = text.find("task_run_status_install_signal_traps")
    preflight_stage = text.find('task_run_status_stage "runner-preflight"')
    rootfs_stage = text.find(
        'task_run_status_stage "rootfs-template-rebuild"'
    )
    linux_makefile_prehash = text.find('linux_makefile_sha_pre="$(\n')
    strict_checker_prehash = text.find(
        'strict_checker_sha_pre="$(sha256sum'
    )
    if (
        trap_install < 0
        or preflight_stage < 0
        or trap_install > preflight_stage
    ):
        missing.append("runner preflight must follow status traps")
    if (
        rootfs_stage < 0
        or linux_makefile_prehash < 0
        or strict_checker_prehash < 0
        or linux_makefile_prehash > rootfs_stage
        or strict_checker_prehash > rootfs_stage
    ):
        missing.append("rootfs control hashes must precede rootfs build")

    if GLOBAL_LOCK not in launcher_text:
        missing.append("V10E workspace-global lock")
    if GLOBAL_LOCK not in legacy_launcher_text:
        missing.append("V9S workspace-global lock")
    launcher_required = {
        "V10E background lock rc": 'flock -n -E 73 "${lock_path}"',
        "V10E launcher failure status": (
            'publish_launcher_failure "${launcher_rc}" '
            '"launcher-lock-or-init"'
        ),
        "V10E bounded status wait": "for _ in $(seq 1 300)",
        "V10E durable prelaunch selftest": (
            'python3 "${selftest}" '
            '>"${result_dir}/prelaunch-contract.log" 2>&1'
        ),
    }
    missing.extend(
        name
        for name, token in launcher_required.items()
        if token not in launcher_text
    )
    legacy_launcher_required = {
        "V9S background lock rc": 'flock -n -E 73 "${lock_path}"',
        "V9S launcher failure status": (
            'publish_launcher_failure "${launcher_rc}" '
            '"launcher-lock-or-init"'
        ),
        "V9S bounded status wait": "for _ in $(seq 1 300)",
    }
    missing.extend(
        name
        for name, token in legacy_launcher_required.items()
        if token not in legacy_launcher_text
    )
    return missing


def validate_status_helper(text: str) -> list[str]:
    required = {
        "PASS write checked": 'if _task_run_status_write "PASS"; then',
        "PASS write rc captured": "pass_write_rc=$?",
        "PASS write fallback status": "status_write_rc=${pass_write_rc}",
        "PASS write returns failure": 'return "${pass_write_rc}"',
    }
    return [name for name, token in required.items() if token not in text]


def main() -> int:
    runner = pathlib.Path(__file__).with_name(
        "run-v10e-current-design-systemd-strict.sh"
    )
    launcher = pathlib.Path(__file__).with_name(
        "launch-v10e-current-design-systemd-strict.sh"
    )
    repo_root = pathlib.Path(__file__).resolve().parents[3]
    legacy_launcher = (
        repo_root
        / ".github/task-runs/2026-07-24-rv64-v9s-serialize-default"
        / "launch-v9s-rootfs-csr-qh-systemd-strict.sh"
    )
    text = runner.read_text(encoding="utf-8")
    launcher_text = launcher.read_text(encoding="utf-8")
    legacy_launcher_text = legacy_launcher.read_text(encoding="utf-8")
    status_helper = repo_root / "scripts/task-run-status.sh"
    status_helper_text = status_helper.read_text(encoding="utf-8")
    npc_makefile = repo_root / "npc/rv64/Makefile"
    npc_makefile_text = npc_makefile.read_text(encoding="utf-8")
    missing = validate(text, launcher_text, legacy_launcher_text)
    missing.extend(validate_status_helper(status_helper_text))
    if missing:
        print(f"[V10E-RUNNER-CONTRACT][FAIL] missing={','.join(missing)}")
        return 1

    focused_contract_tests = (
        repo_root / "Linux/scripts/tests/test_npc_systemd_strict_check.py",
        repo_root / "Linux/scripts/tests/test_check_npc_systemd_guest_contract.py",
        repo_root
        / "Linux/scripts/tests/test_npc_systemd_transaction_evidence.py",
        repo_root
        / "npc/rv64/testbench/scripts/test_debug_ooo_flags_contract.py",
    )
    for contract_test in focused_contract_tests:
        probe = subprocess.run(
            [sys.executable, str(contract_test)],
            check=False,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
        )
        if probe.returncode != 0:
            print(
                "[V10E-RUNNER-CONTRACT][FAIL] focused contract "
                f"path={contract_test} rc={probe.returncode}\n{probe.stdout}"
            )
            return 1
        print(
            "[V10E-RUNNER-CONTRACT][DYNAMIC] "
            f"focused contract PASS path={contract_test.relative_to(repo_root)}"
        )

    overescaped_assertion_regex = EXPECTED_ASSERTION_REGEX.replace(
        r"\[", r"\\[", 1
    )
    mutations = {
        "stale-design": text.replace(EXPECTED_DESIGN, "0" * 64, 1),
        "lower-cycle-floor": text.replace(
            'min_max_cycles="6000000000"', 'min_max_cycles="3000000000"', 1
        ),
        "drop-canonical-config-stage": text.replace(
            'task_run_status_stage "simulator-config-canonical"', "", 1
        ),
        "drop-config-hash-binding": text.replace(
            '"${repo_root}/npc/rv64/configs/default_defconfig"',
            '"${repo_root}/npc/rv64/configs/default_defconfig.removed"',
            1,
        ),
        "drop-queue-head-build": text.replace(
            "  OOO_CSR_QUEUE_HEAD=1 \\", "", 1
        ),
        "drop-queue-head-evidence": text.replace(
            'printf \'%s\\n\' "OOO_CSR_QUEUE_HEAD=1"', "", 1
        ),
        "drop-queue-head-compiled-define": text.replace(
            'grep -Fq -- "+define+OOO_CSR_QUEUE_HEAD=1 "',
            "true # queue-head proof removed",
            1,
        ),
        "drop-assertion-compiled-define": text.replace(
            'grep -Fq -- "+define+OOO_ASSERT "',
            "true # OOO_ASSERT proof removed",
            1,
        ),
        "drop-terminal-holder-build": text.replace(
            "  OOO_TERMINAL_HOLDER_ASSERT=1 \\", "", 1
        ),
        "drop-terminal-holder-compiled-define": text.replace(
            'grep -Fq -- "+define+OOO_TERMINAL_HOLDER_ASSERT "',
            "true # terminal-holder proof removed",
            1,
        ),
        "require-terminal-holder-define-value": text.replace(
            'grep -Fq -- "+define+OOO_TERMINAL_HOLDER_ASSERT "',
            'grep -Fq -- "+define+OOO_TERMINAL_HOLDER_ASSERT=1 "',
            1,
        ),
        "drop-verilator-assert-mode": text.replace(
            'grep -Fq -- "--assert"',
            "true # verilator assertion proof removed",
            1,
        ),
        "drop-makefile-pre-hash": text.replace(
            'npc_makefile_sha_pre="$(\n'
            '  sha256sum "${repo_root}/npc/rv64/Makefile"',
            'npc_makefile_sha_pre="$(\n'
            '  printf "%s\\n" makefile-hash-removed',
            1,
        ),
        "drop-manifest-pre-hash": text.replace(
            'verilator_manifest_sha_pre="$(\n'
            '  sha256sum "${verilator_manifest}"',
            'verilator_manifest_sha_pre="$(\n'
            '  printf "%s\\n" manifest-hash-removed',
            1,
        ),
        "drop-rootfs-isolation": text.replace(
            "NPC_SYSTEMD_ROOTFS_WORK_IMAGE=", "ROOTFS_WORK_IMAGE_REMOVED=", 1
        ),
        "drop-rootfs-copy-helper-binding": text.replace(
            '"${repo_root}/Linux/scripts/prepare-npc-rootfs-run-image.sh"',
            '"${repo_root}/Linux/scripts/rootfs-helper-binding-removed.sh"',
            1,
        ),
        "drop-rootfs-pre-hash-proof": text.replace(
            "rootfs_run_image_sha256_pre=${rootfs_template_sha}",
            "rootfs_run_image_pre_hash_proof_removed",
            1,
        ),
        "drop-transaction-evidence": text.replace(
            "NPC_SYSTEMD_TRANSACTION_EVIDENCE=",
            "TRANSACTION_EVIDENCE_REMOVED=",
            1,
        ),
        "drop-kernel-terminal-capture": text.replace(
            "|reboot: Power down|",
            "|kernel-terminal-capture-removed|",
            1,
        ),
        "add-systemd-milestone-terminal-oracle": text.replace(
            "|reboot: Power down|",
            "|System Power Off|reboot: Power down|",
            1,
        ),
        "drop-strict-count": text.replace("strict_expected_count != 17", "False", 1),
        "drop-assertion-oracle": text.replace(
            'test ! -s "${result_dir}/rtl-assertion-failures.txt"', "true", 1
        ),
        "drop-evidence-completion": text.replace(
            "task_run_status_mark_evidence_complete", "true", 1
        ),
        "skip-missing-simulator-failure": text.replace(
            "simulator_sha256_post=MISSING_OR_NOT_EXECUTABLE",
            "simulator_sha256_post=SKIPPED",
            1,
        ),
        "drop-kernel-post-hash": text.replace(
            'verify_post_hash "linux_image"',
            "true # linux image post hash removed",
            1,
        ),
        "drop-opensbi-post-hash": text.replace(
            'verify_post_hash "opensbi_fw"',
            "true # OpenSBI post hash removed",
            1,
        ),
        "drop-dtb-post-hash": text.replace(
            'verify_post_hash "run_dtb"',
            "true # DTB post hash removed",
            1,
        ),
        "restore-reenables-errexit": text.replace(
            "restore_npc_config() {",
            "restore_npc_config() {\n  set -e",
            1,
        ),
        "cleanup-clears-signal-traps": text.replace(
            "trap 'defer_cleanup_signal CLEANUP 143' HUP INT TERM",
            "trap - HUP INT TERM",
            1,
        ),
        "drop-post-binding-write-check": text.replace(
            '} >"${post_binding_tmp}"; then',
            '} >"${result_dir}/post-binding.txt"; then',
            1,
        ),
        "ignore-terminal-query-errors": text.replace(
            'rg "$@" >"${output_path}" \\\n'
            '    2>>"${result_dir}/evidence-query-errors.log" || rg_rc=$?',
            'rg "$@" >"${output_path}" \\\n'
            '    2>>"${result_dir}/evidence-query-errors.log" || true',
            1,
        ),
        "count-terminal-lines-not-occurrences": text.replace(
            'grep -a -F -o -- "${marker}" "${path}"',
            'grep -a -F -- "${marker}" "${path}"',
            1,
        ),
        "ignore-terminal-count-query-error": text.replace(
            '    return "${query_rc}"\n'
            "  fi\n"
            "  printf '%s\\n' \"${matches}\" | wc -l",
            "    return 0\n"
            "  fi\n"
            "  printf '%s\\n' \"${matches}\" | wc -l",
            1,
        ),
        "overescape-assertion-regex": text.replace(
            f"assertion_failure_regex='{EXPECTED_ASSERTION_REGEX}'",
            f"assertion_failure_regex='{overescaped_assertion_regex}'",
            1,
        ),
        "require-guest-checker-executable": text.replace(
            'test -r "${guest_checker}"',
            'test -x "${guest_checker}"',
            1,
        ),
        "drop-guest-checker-post-hash": text.replace(
            'verify_post_hash \\\n      "guest_checker"',
            "true # guest checker post hash removed",
            1,
        ),
        "drop-transaction-parser-post-hash": text.replace(
            'verify_post_hash \\\n      "transaction_parser"',
            "true # transaction parser post hash removed",
            1,
        ),
        "drop-rootfs-helper-post-hash": text.replace(
            'verify_post_hash \\\n      "rootfs_copy_helper"',
            "true # rootfs helper post hash removed",
            1,
        ),
        "drop-prelaunch-log-post-hash": text.replace(
            'verify_post_hash \\\n      "prelaunch_contract_log"',
            "true # prelaunch log post hash removed",
            1,
        ),
        "allow-duplicate-strict-done": text.replace(
            '[[ "${strict_done_count}" -eq 1 ]]',
            '[[ "${strict_done_count}" -ge 1 ]]',
            1,
        ),
        "allow-duplicate-poweroff-begin": text.replace(
            '[[ "${poweroff_begin_count}" -eq 1 ]]',
            '[[ "${poweroff_begin_count}" -ge 1 ]]',
            1,
        ),
        "allow-duplicate-kernel-power-down": text.replace(
            '[[ "${kernel_power_down_count}" -eq 1 ]]',
            '[[ "${kernel_power_down_count}" -ge 1 ]]',
            1,
        ),
        "allow-duplicate-syscon-terminal": text.replace(
            '[[ "${syscon_terminal_count}" -eq 1 ]]',
            '[[ "${syscon_terminal_count}" -ge 1 ]]',
            1,
        ),
        "allow-duplicate-system-reset-exit": text.replace(
            '[[ "${system_reset_exit_count}" -eq 1 ]]',
            '[[ "${system_reset_exit_count}" -ge 1 ]]',
            1,
        ),
        "allow-duplicate-good-trap": text.replace(
            '[[ "${good_trap_count}" -eq 1 ]]',
            '[[ "${good_trap_count}" -ge 1 ]]',
            1,
        ),
        "preflight-before-status-traps": text.replace(
            "task_run_status_install_signal_traps\n\n"
            'task_run_status_stage "runner-preflight"',
            'task_run_status_stage "runner-preflight"\n\n'
            "task_run_status_install_signal_traps",
            1,
        ),
    }
    for name, mutant in mutations.items():
        if not validate(mutant, launcher_text, legacy_launcher_text):
            print(f"[V10E-RUNNER-CONTRACT][FAIL] mutation accepted: {name}")
            return 1
        print(f"[V10E-RUNNER-CONTRACT][NEGATIVE] {name} rejected")

    private_v10e_lock = launcher_text.replace(
        GLOBAL_LOCK,
        'lock_path="${task_run_dir}/rv64-engineering-single-flight.lock"',
        1,
    )
    if not validate(text, private_v10e_lock, legacy_launcher_text):
        print(
            "[V10E-RUNNER-CONTRACT][FAIL] "
            "mutation accepted: private-v10e-lock"
        )
        return 1
    print("[V10E-RUNNER-CONTRACT][NEGATIVE] private-v10e-lock rejected")

    private_v9s_lock = legacy_launcher_text.replace(
        GLOBAL_LOCK,
        'lock_path="${task_run_dir}/rv64-engineering-single-flight.lock"',
        1,
    )
    if not validate(text, launcher_text, private_v9s_lock):
        print(
            "[V10E-RUNNER-CONTRACT][FAIL] "
            "mutation accepted: private-v9s-lock"
        )
        return 1
    print("[V10E-RUNNER-CONTRACT][NEGATIVE] private-v9s-lock rejected")

    v10e_no_failure_status = launcher_text.replace(
        'publish_launcher_failure "${launcher_rc}" "launcher-lock-or-init"',
        "true # launcher failure status removed",
        1,
    )
    if not validate(text, v10e_no_failure_status, legacy_launcher_text):
        print(
            "[V10E-RUNNER-CONTRACT][FAIL] "
            "mutation accepted: v10e-no-launch-failure-status"
        )
        return 1
    print(
        "[V10E-RUNNER-CONTRACT][NEGATIVE] "
        "v10e-no-launch-failure-status rejected"
    )

    v9s_no_failure_status = legacy_launcher_text.replace(
        'publish_launcher_failure "${launcher_rc}" "launcher-lock-or-init"',
        "true # launcher failure status removed",
        1,
    )
    if not validate(text, launcher_text, v9s_no_failure_status):
        print(
            "[V10E-RUNNER-CONTRACT][FAIL] "
            "mutation accepted: v9s-no-launch-failure-status"
        )
        return 1
    print(
        "[V10E-RUNNER-CONTRACT][NEGATIVE] "
        "v9s-no-launch-failure-status rejected"
    )

    pass_write_ignored = status_helper_text.replace(
        'if _task_run_status_write "PASS"; then',
        '_task_run_status_write "PASS"\n  if true; then',
        1,
    )
    if not validate_status_helper(pass_write_ignored):
        print(
            "[V10E-RUNNER-CONTRACT][FAIL] "
            "mutation accepted: PASS-write-failure-ignored"
        )
        return 1
    print(
        "[V10E-RUNNER-CONTRACT][NEGATIVE] "
        "PASS-write-failure-ignored rejected"
    )

    status_suite = subprocess.run(
        [str(repo_root / "scripts/tests/test-task-run-status.sh")],
        check=False,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
    )
    if (
        status_suite.returncode != 0
        or "PASS-write fallback" not in status_suite.stdout
    ):
        print(
            "[V10E-RUNNER-CONTRACT][FAIL] task-run status suite "
            f"rc={status_suite.returncode}"
        )
        return 1
    print(
        "[V10E-RUNNER-CONTRACT][DYNAMIC] "
        "task-run status PASS-write fallback PASS"
    )

    lock_path = (
        repo_root
        / ".github/runtime-artifacts/rv64-engineering-single-flight.lock"
    )
    lock_path.parent.mkdir(parents=True, exist_ok=True)
    lock_env = os.environ.copy()
    lock_env["V9S_ROOTFS_LAUNCH_VALIDATE_ONLY"] = "1"
    lock_env["V9S_ROOTFS_RUN_LABEL"] = (
        f"v10e-global-lock-probe-{os.getpid()}"
    )
    with lock_path.open("a+", encoding="utf-8") as lock_file:
        lock_owned = False
        try:
            fcntl.flock(
                lock_file.fileno(),
                fcntl.LOCK_EX | fcntl.LOCK_NB,
            )
            lock_owned = True
        except BlockingIOError:
            pass
        lock_probe = subprocess.run(
            [str(legacy_launcher)],
            check=False,
            env=lock_env,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
        )
        if lock_owned:
            fcntl.flock(lock_file.fileno(), fcntl.LOCK_UN)
    if lock_probe.returncode != 3:
        print(
            "[V10E-RUNNER-CONTRACT][FAIL] global lock probe "
            f"rc={lock_probe.returncode}"
        )
        return 1
    print(
        "[V10E-RUNNER-CONTRACT][DYNAMIC] "
        "V9S launch rejected shared V10E lock rc=3"
    )

    with tempfile.TemporaryDirectory(prefix="v10e-status-") as tmp:
        status_path = pathlib.Path(tmp) / "cleanup-failure.status"
        status_probe = subprocess.run(
            [
                "bash",
                "-c",
                (
                    'set -u; source "$1"; task_run_status_init "$2"; '
                    'task_run_status_stage cleanup-fixture; set +e; '
                    "task_run_status_finalize 0 7"
                ),
                "v10e-status-probe",
                str(status_helper),
                str(status_path),
            ],
            check=False,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
        )
        expected_status = (
            "FAIL rc=7 stage=cleanup-fixture "
            "evidence_complete=0 cleanup_rc=7"
        )
        actual_status = status_path.read_text(encoding="utf-8").strip()
        if status_probe.returncode != 7 or actual_status != expected_status:
            print(
                "[V10E-RUNNER-CONTRACT][FAIL] cleanup status probe "
                f"rc={status_probe.returncode} status={actual_status!r}"
            )
            return 1
    print(
        "[V10E-RUNNER-CONTRACT][DYNAMIC] "
        "cleanup failure finalized as FAIL rc=7"
    )

    with tempfile.TemporaryDirectory(prefix="v10e-timeout-") as tmp:
        timeout_status = pathlib.Path(tmp) / "cycle-budget.status"
        timeout_probe = subprocess.run(
            [
                "bash",
                "-c",
                (
                    'set -u; source "$1"; task_run_status_init "$2"; '
                    'task_run_status_stage rv64-cycle-budget-fixture; set +e; '
                    "task_run_status_finalize 124 0"
                ),
                "v10e-timeout-probe",
                str(status_helper),
                str(timeout_status),
            ],
            check=False,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
        )
        expected_timeout_status = (
            "FAIL rc=124 stage=rv64-cycle-budget-fixture "
            "evidence_complete=0 cleanup_rc=0"
        )
        actual_timeout_status = timeout_status.read_text(
            encoding="utf-8"
        ).strip()
        if (
            timeout_probe.returncode != 124
            or actual_timeout_status != expected_timeout_status
        ):
            print(
                "[V10E-RUNNER-CONTRACT][FAIL] RV64 cycle-budget status probe "
                f"rc={timeout_probe.returncode} status={actual_timeout_status!r}"
            )
            return 1
    print(
        "[V10E-RUNNER-CONTRACT][DYNAMIC] "
        "RV64 cycle-budget rc=124 preserved in task-run status"
    )

    with tempfile.TemporaryDirectory(prefix="v10e-signal-") as tmp:
        signal_status = pathlib.Path(tmp) / "cleanup-signal.status"
        signal_probe = subprocess.run(
            [
                "bash",
                "-c",
                r'''
set -u
source "$1"
cleanup_signal_rc=0
defer_cleanup_signal() {
  TASK_RUN_STATUS_SIGNAL="$1"
  cleanup_signal_rc="$2"
}
finish_probe() {
  local command_rc=$?
  local cleanup_rc=0
  local final_rc=0
  trap 'defer_cleanup_signal CLEANUP 143' HUP INT TERM
  trap - EXIT
  trap 'defer_cleanup_signal HUP 129' HUP
  trap 'defer_cleanup_signal INT 130' INT
  trap 'defer_cleanup_signal TERM 143' TERM
  set +e
  kill -TERM "${BASHPID}"
  if [[ "${cleanup_signal_rc}" -ne 0 ]]; then
    cleanup_rc="${cleanup_signal_rc}"
  fi
  trap '' HUP INT TERM
  task_run_status_finalize "${command_rc}" "${cleanup_rc}"
  final_rc=$?
  trap - HUP INT TERM
  exit "${final_rc}"
}
task_run_status_init "$2"
task_run_status_stage cleanup-signal-fixture
task_run_status_mark_evidence_complete
trap finish_probe EXIT
exit 0
''',
                "v10e-cleanup-signal-probe",
                str(status_helper),
                str(signal_status),
            ],
            check=False,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
        )
        expected_signal_status = (
            "FAIL rc=143 stage=cleanup-signal-fixture "
            "evidence_complete=1 cleanup_rc=143 signal=TERM"
        )
        actual_signal_status = signal_status.read_text(
            encoding="utf-8"
        ).strip()
        if (
            signal_probe.returncode != 143
            or actual_signal_status != expected_signal_status
        ):
            print(
                "[V10E-RUNNER-CONTRACT][FAIL] cleanup signal probe "
                f"rc={signal_probe.returncode} "
                f"status={actual_signal_status!r}"
            )
            return 1
    print(
        "[V10E-RUNNER-CONTRACT][DYNAMIC] "
        "cleanup TERM deferred and finalized as FAIL rc=143"
    )

    with tempfile.TemporaryDirectory(prefix="v10e-post-binding-") as tmp:
        post_status = pathlib.Path(tmp) / "post-binding.status"
        unwritable_target = pathlib.Path(tmp) / "target-directory"
        unwritable_target.mkdir()
        post_probe = subprocess.run(
            [
                "bash",
                "-c",
                r'''
set -u
source "$1"
task_run_status_init "$2"
task_run_status_stage post-binding-fixture
task_run_status_mark_evidence_complete
set +e
post_binding_rc=0
if { printf '%s\n' post-binding; } >"$3"; then
  :
else
  post_binding_rc=$?
fi
task_run_status_finalize 0 "${post_binding_rc}"
''',
                "v10e-post-binding-probe",
                str(status_helper),
                str(post_status),
                str(unwritable_target),
            ],
            check=False,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
        )
        expected_post_status = (
            "FAIL rc=1 stage=post-binding-fixture "
            "evidence_complete=1 cleanup_rc=1"
        )
        actual_post_status = post_status.read_text(
            encoding="utf-8"
        ).strip()
        if (
            post_probe.returncode != 1
            or actual_post_status != expected_post_status
        ):
            print(
                "[V10E-RUNNER-CONTRACT][FAIL] post-binding probe "
                f"rc={post_probe.returncode} status={actual_post_status!r}"
            )
            return 1
    print(
        "[V10E-RUNNER-CONTRACT][DYNAMIC] "
        "post-binding redirection failure finalized as FAIL rc=1"
    )

    assertion_pattern_match = re.search(
        r"^assertion_failure_regex='([^']*)'$",
        text,
        flags=re.MULTILINE,
    )
    if assertion_pattern_match is None:
        print(
            "[V10E-RUNNER-CONTRACT][FAIL] "
            "production assertion regex assignment not found"
        )
        return 1
    production_assertion_regex = assertion_pattern_match.group(1)
    with tempfile.TemporaryDirectory(prefix="v10e-rg-") as tmp:
        tmp_path = pathlib.Path(tmp)
        assertion_log = tmp_path / "assertion-positive.log"
        clean_log = tmp_path / "assertion-clean.log"
        missing_log = tmp_path / "assertion-missing.log"
        assertion_log.write_text(
            "[V10D-FIXTURE-FAIL]\n"
            "[V9R-SQ-RETRY-C0-HANDOFF]\n"
            "[V9R-MEM-SQ-RETRY-C0-HANDOFF]\n"
            "RTL assertion fixture\n"
            "[FIXTURE_ASSERT_FAIL]\n",
            encoding="utf-8",
        )
        clean_log.write_text(
            "[V10E-FIXTURE] clean terminal transaction\n",
            encoding="utf-8",
        )
        positive_probe = subprocess.run(
            ["rg", "-a", "-n", production_assertion_regex, str(assertion_log)],
            check=False,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
        )
        clean_probe = subprocess.run(
            ["rg", "-a", "-n", production_assertion_regex, str(clean_log)],
            check=False,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
        )
        missing_probe = subprocess.run(
            ["rg", "-a", "-n", production_assertion_regex, str(missing_log)],
            check=False,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
        )
        positive_markers = (
            "[V10D-FIXTURE-FAIL]",
            "[V9R-SQ-RETRY-C0-HANDOFF]",
            "[V9R-MEM-SQ-RETRY-C0-HANDOFF]",
            "RTL assertion fixture",
            "[FIXTURE_ASSERT_FAIL]",
        )
        if (
            positive_probe.returncode != 0
            or any(
                marker not in positive_probe.stdout
                for marker in positive_markers
            )
            or clean_probe.returncode != 1
            or missing_probe.returncode <= 1
        ):
            print(
                "[V10E-RUNNER-CONTRACT][FAIL] production assertion regex "
                f"positive_rc={positive_probe.returncode} "
                f"clean_rc={clean_probe.returncode} "
                f"missing_rc={missing_probe.returncode}"
            )
            return 1
    print(
        "[V10E-RUNNER-CONTRACT][DYNAMIC] "
        "production assertion regex "
        f"match/no-match/read-error rc={positive_probe.returncode}/"
        f"{clean_probe.returncode}/{missing_probe.returncode}"
    )

    terminal_pattern_match = re.search(
        r"^terminal_evidence_regex='([^']*)'$",
        text,
        flags=re.MULTILINE,
    )
    if terminal_pattern_match is None:
        print(
            "[V10E-RUNNER-CONTRACT][FAIL] "
            "production terminal regex assignment not found"
        )
        return 1
    production_terminal_regex = terminal_pattern_match.group(1)
    with tempfile.TemporaryDirectory(prefix="v10e-terminal-rg-") as tmp:
        tmp_path = pathlib.Path(tmp)
        terminal_log = tmp_path / "terminal-positive.log"
        clean_log = tmp_path / "terminal-clean.log"
        missing_log = tmp_path / "terminal-missing.log"
        terminal_markers = (
            "reboot: Power down",
            "syscon-reset: poweroff requested value=0x00005555",
            "exit via system-reset, code=0",
            "HIT GOOD TRAP",
        )
        terminal_log.write_text(
            "\n".join(terminal_markers) + "\n",
            encoding="utf-8",
        )
        clean_log.write_text(
            "[V10E-FIXTURE] guest transaction is still running\n",
            encoding="utf-8",
        )
        terminal_probe = subprocess.run(
            ["rg", "-a", "-n", production_terminal_regex, str(terminal_log)],
            check=False,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
        )
        clean_terminal_probe = subprocess.run(
            ["rg", "-a", "-n", production_terminal_regex, str(clean_log)],
            check=False,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
        )
        missing_terminal_probe = subprocess.run(
            ["rg", "-a", "-n", production_terminal_regex, str(missing_log)],
            check=False,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
        )
        if (
            terminal_probe.returncode != 0
            or any(
                marker not in terminal_probe.stdout
                for marker in terminal_markers
            )
            or clean_terminal_probe.returncode != 1
            or missing_terminal_probe.returncode <= 1
        ):
            print(
                "[V10E-RUNNER-CONTRACT][FAIL] production terminal regex "
                f"positive_rc={terminal_probe.returncode} "
                f"clean_rc={clean_terminal_probe.returncode} "
                f"missing_rc={missing_terminal_probe.returncode}"
            )
            return 1
    print(
        "[V10E-RUNNER-CONTRACT][DYNAMIC] "
        "production terminal regex "
        f"match/no-match/read-error rc={terminal_probe.returncode}/"
        f"{clean_terminal_probe.returncode}/"
        f"{missing_terminal_probe.returncode}"
    )

    guest_checker = (
        repo_root / "Linux/scripts/check-npc-systemd-guest.sh"
    )
    if (
        not guest_checker.is_file()
        or guest_checker.stat().st_size == 0
        or not os.access(guest_checker, os.R_OK)
    ):
        print(
            "[V10E-RUNNER-CONTRACT][FAIL] "
            "guest checker is not a readable nonempty Bash input"
        )
        return 1
    with tempfile.TemporaryDirectory(prefix="v10e-guest-mode-") as tmp:
        mode_probe = pathlib.Path(tmp) / "guest-checker-mode-fixture.sh"
        mode_probe.write_text(
            "#!/usr/bin/env bash\n"
            "printf '%s\\n' '[V10E-GUEST-MODE-FIXTURE] PASS'\n",
            encoding="utf-8",
        )
        mode_probe.chmod(0o644)
        guest_mode_probe = subprocess.run(
            ["bash", str(mode_probe)],
            check=False,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
        )
        if (
            guest_mode_probe.returncode != 0
            or os.access(mode_probe, os.X_OK)
            or "[V10E-GUEST-MODE-FIXTURE] PASS"
            not in guest_mode_probe.stdout
        ):
            print(
                "[V10E-RUNNER-CONTRACT][FAIL] "
                "readable non-executable guest checker fixture "
                f"rc={guest_mode_probe.returncode}"
            )
            return 1
    print(
        "[V10E-RUNNER-CONTRACT][DYNAMIC] "
        "readable non-executable guest checker accepted via Bash "
        "rc=0 mode=0644"
    )

    terminal_holder_make_lines = [
        line.strip()
        for line in npc_makefile_text.splitlines()
        if line.startswith("RTL_VERILATOR_DEFINES +=")
        and "OOO_TERMINAL_HOLDER_ASSERT" in line
    ]
    if len(terminal_holder_make_lines) != 1:
        print(
            "[V10E-RUNNER-CONTRACT][FAIL] terminal-holder Makefile "
            f"definition count={len(terminal_holder_make_lines)}"
        )
        return 1
    terminal_holder_make_match = re.search(
        r",(\+define\+OOO_TERMINAL_HOLDER_ASSERT(?:=1)?)\)\s*$",
        terminal_holder_make_lines[0],
    )
    terminal_holder_runner_patterns = [
        pattern
        for pattern in re.findall(r'grep -Fq -- "([^"]+)"', text)
        if "OOO_TERMINAL_HOLDER_ASSERT" in pattern
    ]
    if (
        terminal_holder_make_match is None
        or len(terminal_holder_runner_patterns) != 1
    ):
        print(
            "[V10E-RUNNER-CONTRACT][FAIL] terminal-holder define "
            "binding could not be extracted"
        )
        return 1
    terminal_holder_make_token = terminal_holder_make_match.group(1)
    terminal_holder_runner_pattern = terminal_holder_runner_patterns[0]
    if terminal_holder_runner_pattern != f"{terminal_holder_make_token} ":
        print(
            "[V10E-RUNNER-CONTRACT][FAIL] terminal-holder define "
            f"Makefile={terminal_holder_make_token!r} "
            f"runner={terminal_holder_runner_pattern!r}"
        )
        return 1
    with tempfile.TemporaryDirectory(prefix="v10e-define-binding-") as tmp:
        manifest_fixture = pathlib.Path(tmp) / "VNpcSimTop__verFiles.dat"
        manifest_fixture.write_text(
            'C "--assert +define+OOO_CSR_QUEUE_HEAD=1 '
            f"{terminal_holder_make_token} +define+OOO_ASSERT "
            '--top-module NpcSimTop"\n',
            encoding="utf-8",
        )
        terminal_holder_probe = subprocess.run(
            [
                "grep",
                "-Fq",
                "--",
                terminal_holder_runner_pattern,
                str(manifest_fixture),
            ],
            check=False,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
        )
        if terminal_holder_probe.returncode != 0:
            print(
                "[V10E-RUNNER-CONTRACT][FAIL] terminal-holder generated "
                f"manifest fixture rc={terminal_holder_probe.returncode}"
            )
            return 1
    print(
        "[V10E-RUNNER-CONTRACT][DYNAMIC] "
        "Makefile/runner terminal-holder define binding "
        f"token={terminal_holder_make_token} grep_rc=0"
    )

    rootfs_helper = (
        repo_root / "Linux/scripts/prepare-npc-rootfs-run-image.sh"
    )
    with tempfile.TemporaryDirectory(prefix="v10e-rootfs-") as tmp:
        tmp_path = pathlib.Path(tmp)
        template = tmp_path / "template.ext4"
        run_image = tmp_path / "run.ext4"
        binding = tmp_path / "binding.txt"
        template.write_bytes(b"V10E rootfs pre-image binding fixture\n")
        first_copy = subprocess.run(
            [
                "bash",
                str(rootfs_helper),
                "--template",
                str(template),
                "--run-image",
                str(run_image),
                "--binding-out",
                str(binding),
            ],
            check=False,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
        )
        second_copy = subprocess.run(
            [
                "bash",
                str(rootfs_helper),
                "--template",
                str(template),
                "--run-image",
                str(run_image),
                "--binding-out",
                str(binding),
            ],
            check=False,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
        )
        binding_text = binding.read_text(encoding="utf-8")
        if (
            first_copy.returncode != 0
            or template.read_bytes() != run_image.read_bytes()
            or "rootfs_template_sha256_pre=" not in binding_text
            or "rootfs_run_image_sha256_pre=" not in binding_text
            or second_copy.returncode != 4
        ):
            print(
                "[V10E-RUNNER-CONTRACT][FAIL] rootfs isolation probe "
                f"first_rc={first_copy.returncode} "
                f"second_rc={second_copy.returncode}"
            )
            return 1
    print(
        "[V10E-RUNNER-CONTRACT][DYNAMIC] "
        "rootfs copy hash PASS; existing run image rejected rc=4"
    )

    print(
        "[V10E-RUNNER-CONTRACT][PASS] "
        "current-design + compiled-defines + global-lock + post-hashes + "
        "6B + isolated-rootfs + 17-label oracle"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
