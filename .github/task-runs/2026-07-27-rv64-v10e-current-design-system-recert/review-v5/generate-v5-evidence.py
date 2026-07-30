#!/usr/bin/env python3
from __future__ import annotations

import fcntl
import hashlib
import json
import os
import pathlib
import re
import stat
import subprocess
import sys
from typing import Any


ROOT = pathlib.Path(".").resolve()
RUN_DIR = (
    ROOT
    / ".github/task-runs/2026-07-27-rv64-v10e-current-design-system-recert"
)
OUT = RUN_DIR / "review-v5"
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
    / "subagent-contracts/v10e_runner_prelaunch_review_v5.json"
)
LOCK_PATH = (
    ROOT
    / ".github/runtime-artifacts/rv64-engineering-single-flight.lock"
)
ARCH_TOOL = ROOT / "npc/rv64/eval/ppa/tools/architecture_hard_gates.py"
GUEST_CHECKER = ROOT / "Linux/scripts/check-npc-systemd-guest.sh"
DISPATCH_LOG = RUN_DIR / "dispatch-log.md"
V4_INPUT_SHA = RUN_DIR / "review-v4/input-sha256-pre.txt"
A1_LABEL = "rootfs-c1b531-systemd-strict-6b-a1"
A2_LABEL = "rootfs-c1b531-systemd-strict-6b-a2"
A1_DIR = RUN_DIR / A1_LABEL
A1_STATUS = RUN_DIR / f"{A1_LABEL}.status"
A1_QUERY_LOG = A1_DIR / "evidence-query-errors.log"
A1_POST_BINDING = A1_DIR / "post-binding.txt"
A1_LAUNCH_BINDING = A1_DIR / "launch-binding.txt"
A2_DIR = RUN_DIR / A2_LABEL
A2_STATUS = RUN_DIR / f"{A2_LABEL}.status"
A2_RUNTIME = (
    ROOT
    / ".github/runtime-artifacts/rv64-systemd-strict"
    / A2_LABEL
)

EXPECTED_CONTRACT_SHA = (
    "fe7adac029fa7341f8b44c74b734ce21d3ce804403919740aedaaac36e7f1760"
)
EXPECTED_DESIGN_SHA = (
    "c1b5317212bfe47e507eac83a28dff405527f50493e3709e96ffbec2dc3bb594"
)
EXPECTED_A1_RUNNER_SHA = (
    "63e2d9f1cb1a3a2d74efadb02e1daae5d6168c291b6d21d443b11f26614da8f9"
)
EXPECTED_GUEST_CHECKER_SHA = (
    "1b3cc4695f2f4c40627a5e792ae67d7ab06a434636e5ecf287000aa645d56cda"
)
EXPECTED_ASSERTION_REGEX = (
    r"\[(V9Q-(BRIDGE-HOLDER|TRANSIENT-HOLDER|TRANSIENT-BRIDGE|"
    r"DUAL-REQ-TOKEN)-DISJOINT|S2-G1-TCOLL-INGRESS-DUP|"
    r"V10D-[^]]*FAIL)\]|%Error:|Assertion failed|RTL assertion|"
    r"\[.*ASSERT.*FAIL"
)
EMPTY_TREE = "4b825dc642cb6eb9a060e54bf8d69288fbee4904"

IMMUTABLE_INPUTS = (
    CONTRACT,
    RUNNER,
    LAUNCHER,
    LEGACY_LAUNCHER,
    SELFTEST,
    STATUS_HELPER,
    STATUS_TEST,
    ROOT / "Linux/Makefile",
    GUEST_CHECKER,
    ROOT / "Linux/scripts/npc-systemd-strict-check.sh",
    ROOT / "Linux/scripts/npc_systemd_transaction_evidence.py",
    ROOT / "Linux/scripts/prepare-npc-rootfs-run-image.sh",
    ROOT / "npc/rv64/Makefile",
    ROOT / "npc/rv64/scripts/config.mk",
    ROOT / "npc/rv64/configs/default_defconfig",
    ARCH_TOOL,
    DISPATCH_LOG,
    A1_STATUS,
    A1_QUERY_LOG,
    A1_POST_BINDING,
    A1_LAUNCH_BINDING,
    V4_INPUT_SHA,
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
dispatch_text = DISPATCH_LOG.read_text(encoding="utf-8")
a1_status_text = A1_STATUS.read_text(encoding="utf-8").strip()
a1_query_text = A1_QUERY_LOG.read_text(encoding="utf-8")
a1_post_text = A1_POST_BINDING.read_text(encoding="utf-8")
a1_launch_text = A1_LAUNCH_BINDING.read_text(encoding="utf-8")
v4_input_text = V4_INPUT_SHA.read_text(encoding="utf-8")
a1_post = key_values(a1_post_text)

git_mode = run_logged(
    [
        "git",
        "diff",
        "--raw",
        EMPTY_TREE,
        "--",
        rel(GUEST_CHECKER),
    ],
    "guest-checker-git-mode.log",
    "guest-checker-git-mode.rc",
)
git_head = run_logged(
    ["git", "diff", "--raw", "HEAD", "--", rel(GUEST_CHECKER)],
    "guest-checker-head-drift.log",
    "guest-checker-head-drift.rc",
)
tracked_mode_match = re.search(
    r"^:000000 ([0-7]{6}) [0-9a-f]+ [0-9a-f]+ A\t"
    + re.escape(rel(GUEST_CHECKER))
    + r"$",
    git_mode.stdout.strip(),
)
tracked_mode = tracked_mode_match.group(1) if tracked_mode_match else "UNKNOWN"
current_mode = stat.S_IMODE(GUEST_CHECKER.stat().st_mode)
guest_checker_sha = digest(GUEST_CHECKER)
guest_checker_readable = os.access(GUEST_CHECKER, os.R_OK)
guest_checker_executable = os.access(GUEST_CHECKER, os.X_OK)
guest_checker_nonempty = GUEST_CHECKER.stat().st_size > 0
readable_token = 'test -r "${guest_checker}"'
nonempty_token = 'test -s "${guest_checker}"'
executable_token = 'test -x "${guest_checker}"'
bash_call_token = 'bash "${guest_checker}"'
guest_contract = {
    "path": rel(GUEST_CHECKER),
    "git_empty_tree_raw": git_mode.stdout.strip(),
    "git_head_diff_empty": git_head.stdout == "",
    "tracked_mode": tracked_mode,
    "current_mode_octal": f"{current_mode:04o}",
    "sha256": guest_checker_sha,
    "readable": guest_checker_readable,
    "nonempty": guest_checker_nonempty,
    "executable": guest_checker_executable,
    "runner_readable_guard": {
        "line": token_line(runner_text, readable_token),
        "occurrences": runner_text.count(readable_token),
    },
    "runner_nonempty_guard": {
        "line": token_line(runner_text, nonempty_token),
        "occurrences": runner_text.count(nonempty_token),
    },
    "runner_executable_guard": {
        "line": token_line(runner_text, executable_token),
        "occurrences": runner_text.count(executable_token),
    },
    "runner_bash_call": {
        "line": token_line(runner_text, bash_call_token),
        "occurrences": runner_text.count(bash_call_token),
    },
}
write_json(OUT / "guest-checker-mode.json", guest_contract)

a1_absent_paths = (
    A1_DIR / "config-canonical.log",
    A1_DIR / "rootfs-build.log",
    A1_DIR / "rootfs-check.log",
    A1_DIR / "sim-build.log",
    A1_DIR / "simulator-defines.txt",
    A1_DIR / "binding.txt",
    A1_DIR / "driver.log",
    A1_DIR / "guest",
    ROOT
    / ".github/runtime-artifacts/rv64-systemd-strict"
    / A1_LABEL,
)
a1_absence = {rel(path): not path.exists() for path in a1_absent_paths}
a1_expected_status = (
    "FAIL rc=1 stage=runner-preflight evidence_complete=0 cleanup_rc=2"
)
a1_runner_sha = a1_post.get("runner_script_pre_sha256", "MISSING")
a1_root_cause = {
    "status": a1_status_text,
    "expected_status": a1_expected_status,
    "launcher_prelaunch_contract_pass": "prelaunch_contract=PASS" in a1_launch_text,
    "max_cycles_6b": "max_cycles=6000000000" in a1_launch_text,
    "missing_driver_log_query": "driver.log: No such file or directory"
    in a1_query_text,
    "missing_guest_query": "/guest: No such file or directory" in a1_query_text,
    "evidence_query_fail_markers": a1_query_text.count(
        "[V10E-RECERT][EVIDENCE-QUERY-FAIL]"
    ),
    "prehash_unavailable": {
        "rtl_design_id_post": a1_post.get("rtl_design_id_post"),
        "npc_makefile_pre_sha256": a1_post.get("npc_makefile_pre_sha256"),
        "guest_checker_pre_sha256": a1_post.get(
            "guest_checker_pre_sha256"
        ),
    },
    "a1_runner_sha256": a1_runner_sha,
    "a1_runner_matches_v4_snapshot": (
        f"{a1_runner_sha}  {rel(RUNNER)}" in v4_input_text
    ),
    "a1_runner_differs_from_corrected_runner": a1_runner_sha != digest(RUNNER),
    "guest_checker_unchanged_from_v4": (
        f"{guest_checker_sha}  {rel(GUEST_CHECKER)}" in v4_input_text
    ),
    "dispatch_root_cause_record": all(
        token in dispatch_text
        for token in (
            "has Git mode `100644`",
            'invoked as `bash "${guest_checker}"`',
            'incorrectly required\n  `test -x "${guest_checker}"`',
        )
    ),
    "no_build_or_sim_artifacts": a1_absence,
    "launcher_log_size": (A1_DIR / "launcher.log").stat().st_size,
}
write_json(OUT / "a1-root-cause.json", a1_root_cause)
(OUT / "a1-raw-evidence.log").write_text(
    "[A1-STATUS]\n"
    + a1_status_text
    + "\n[A1-LAUNCH-BINDING]\n"
    + a1_launch_text
    + "[A1-EVIDENCE-QUERY-ERRORS]\n"
    + a1_query_text
    + "[A1-POST-BINDING]\n"
    + a1_post_text
    + "[A1-ABSENCE-MATRIX]\n"
    + "".join(
        f"{'ABSENT' if absent else 'PRESENT'}  {name}\n"
        for name, absent in a1_absence.items()
    ),
    encoding="utf-8",
)

a2_vacancy_pre = {
    rel(A2_STATUS): not A2_STATUS.exists(),
    rel(A2_DIR): not A2_DIR.exists(),
    rel(A2_RUNTIME): not A2_RUNTIME.exists(),
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

a2_env = os.environ.copy()
a2_env["V10E_RECERT_RUN_LABEL"] = A2_LABEL
a2_env["V10E_RECERT_LAUNCH_VALIDATE_ONLY"] = "1"
a2_validate = run_logged(
    ["bash", rel(LAUNCHER)],
    "a2-launcher-validate-only.log",
    "a2-launcher-validate-only.rc",
    env=a2_env,
)
a2_vacancy_post = {
    rel(A2_STATUS): not A2_STATUS.exists(),
    rel(A2_DIR): not A2_DIR.exists(),
    rel(A2_RUNTIME): not A2_RUNTIME.exists(),
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
            f"[V10E-V5][SOURCE] {rel(RUNNER)}:{pattern_line}\n",
            "[V10E-V5][ARGV] "
            + json.dumps(
                ["rg", "-a", "-n", production_pattern],
                ensure_ascii=False,
            )
            + "\n",
            f"[V10E-V5][EXACT] {production_pattern == EXPECTED_ASSERTION_REGEX}\n",
            f"[V10E-V5][MATCH-RC] {positive_rg.returncode}\n",
            positive_rg.stdout,
            f"[V10E-V5][NO-MATCH-RC] {clean_rg.returncode}\n",
            clean_rg.stdout,
            f"[V10E-V5][READ-ERROR-PATH] {rel(missing_path)}\n",
            f"[V10E-V5][READ-ERROR-RC] {missing_rg.returncode}\n",
            missing_rg.stdout,
            "[V10E-V5][ASSERTION-REGEX-RC] "
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
static_set_exact = static_names == EXPECTED_STATIC_NAMES
dynamic_coverage = {
    snippet: any(snippet in line for line in dynamic_markers)
    for snippet in EXPECTED_DYNAMIC_SNIPPETS
}

terminal_oracles = {
    name: {"guard": token, "occurrences": runner_text.count(token)}
    for name, token in TERMINAL_ORACLES.items()
}
post_hash_tokens = {
    name: {"token": token, "occurrences": runner_text.count(token)}
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
a1_no_build_sim = all(a1_absence.values())
a1_root_cause_closed = (
    a1_status_text == a1_expected_status
    and a1_root_cause["launcher_prelaunch_contract_pass"]
    and a1_root_cause["max_cycles_6b"]
    and a1_root_cause["missing_driver_log_query"]
    and a1_root_cause["missing_guest_query"]
    and a1_root_cause["evidence_query_fail_markers"] == 3
    and a1_post.get("rtl_design_id_post") == "PREHASH_UNAVAILABLE"
    and a1_post.get("npc_makefile_pre_sha256") == "UNAVAILABLE"
    and a1_post.get("guest_checker_pre_sha256") == "UNAVAILABLE"
    and a1_runner_sha == EXPECTED_A1_RUNNER_SHA
    and a1_root_cause["a1_runner_matches_v4_snapshot"]
    and a1_root_cause["a1_runner_differs_from_corrected_runner"]
    and a1_root_cause["guest_checker_unchanged_from_v4"]
    and a1_root_cause["dispatch_root_cause_record"]
    and a1_no_build_sim
)
guest_mode_closed = (
    git_mode.returncode == 0
    and tracked_mode == "100644"
    and git_head.returncode == 0
    and git_head.stdout == ""
    and current_mode == 0o644
    and guest_checker_sha == EXPECTED_GUEST_CHECKER_SHA
    and guest_checker_readable
    and guest_checker_nonempty
    and not guest_checker_executable
)
guest_runner_contract_closed = (
    guest_contract["runner_readable_guard"]["occurrences"] == 1
    and guest_contract["runner_nonempty_guard"]["occurrences"] == 1
    and guest_contract["runner_executable_guard"]["occurrences"] == 0
    and guest_contract["runner_bash_call"]["occurrences"] == 1
)
a2_validate_marker = (
    f"[V10E-RECERT-LAUNCH] validation PASS label={A2_LABEL}"
    in a2_validate.stdout
)

all_gates = {
    "contract_sha": contract_sha == EXPECTED_CONTRACT_SHA
    and contract_sha_cmd.returncode == 0,
    "a1_status_and_no_build_sim": a1_root_cause_closed,
    "guest_checker_tracked_current_mode_100644": guest_mode_closed,
    "guest_checker_readable_nonempty_bash_contract": guest_runner_contract_closed,
    "bash_syntax": syntax.returncode == 0,
    "status_helper_suite": status_result.returncode == 0 and status_marker_ok,
    "runner_contract": selftest.returncode == 0
    and "[V10E-RUNNER-CONTRACT][FAIL]" not in contract_log,
    "static_42_of_42": len(negative_markers) == 42 and static_set_exact,
    "dynamic_8_of_8": len(dynamic_markers) == 8
    and all(dynamic_coverage.values()),
    "test_x_counterexample_rejected": (
        "require-guest-checker-executable" in static_names
    ),
    "a2_target_vacant_pre": all(a2_vacancy_pre.values()),
    "a2_launcher_validate_only": a2_validate.returncode == 0
    and a2_validate_marker,
    "a2_target_vacant_post": all(a2_vacancy_post.values()),
    "production_regex_exact": production_pattern == EXPECTED_ASSERTION_REGEX,
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
    "workspace_lock_released": lock_probe_rc == 0
    and lock_sha_pre == lock_sha_post,
}
prelaunch_pass = all(all_gates.values())

summary = {
    "schema": "v10e-runner-prelaunch-review-v5-evidence-v1",
    "contract": {
        "path": rel(CONTRACT),
        "expected_sha256": EXPECTED_CONTRACT_SHA,
        "actual_sha256": contract_sha,
    },
    "a1_root_cause": a1_root_cause,
    "guest_checker": guest_contract,
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
        "static_negative_expected": 42,
        "static_names_exact": static_set_exact,
        "raw_negative_markers": negative_markers,
        "dynamic_fixture_markers": len(dynamic_markers),
        "dynamic_fixture_expected": 8,
        "dynamic_coverage": dynamic_coverage,
        "raw_dynamic_markers": dynamic_markers,
    },
    "a2": {
        "label": A2_LABEL,
        "vacancy_pre": a2_vacancy_pre,
        "validate_only_argv": ["bash", rel(LAUNCHER)],
        "validate_only_rc": a2_validate.returncode,
        "validate_only_marker": a2_validate_marker,
        "vacancy_post": a2_vacancy_post,
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
        "核对 V5 子任务合同 JSON SHA-256",
        contract_sha_cmd.returncode,
    ),
    (
        "git diff",
        ["git", "diff", "--raw", EMPTY_TREE, "--", rel(GUEST_CHECKER)],
        "证明 guest checker tracked mode",
        git_mode.returncode,
    ),
    (
        "git diff",
        ["git", "diff", "--raw", "HEAD", "--", rel(GUEST_CHECKER)],
        "证明 guest checker 工作树 mode/content 无漂移",
        git_head.returncode,
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
        "运行 42 个静态负向变体与 8 类动态 fixture",
        selftest.returncode,
    ),
    (
        "bash",
        [
            "env",
            f"V10E_RECERT_RUN_LABEL={A2_LABEL}",
            "V10E_RECERT_LAUNCH_VALIDATE_ONLY=1",
            "bash",
            rel(LAUNCHER),
        ],
        "运行 a2 launcher validate-only，不启动仿真",
        a2_validate.returncode,
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
        ["python3", rel(OUT / "generate-v5-evidence.py")],
        "生成 V5 启动前独立验证证据",
        0 if prelaunch_pass else 1,
    ),
]

result_word = "PASS" if prelaunch_pass else "GAP"
report = f"""RV64 RTL 结论｜对象={rel(RUNNER)}::runner-preflight / {rel(GUEST_CHECKER)} / {rel(OUT)}｜周期/配置=pre-launch, a1 fail audit, a2 validate-only, max_cycles=6000000000, OOO_CSR_QUEUE_HEAD=1, OOO_ASSERT=1, OOO_TERMINAL_HOLDER_ASSERT=1｜TB/EDA 观测=a1 未进入 build/sim；bash syntax rc={syntax.returncode}；status-helper rc={status_result.returncode}；{len(negative_markers)}/42 static + {len(dynamic_markers)}/8 dynamic；a2 validate-only rc={a2_validate.returncode}；production rg rc={positive_rg.returncode}/{clean_rg.returncode}/{missing_rg.returncode}；rtl_binding=sha256:{rtl_sha_post}｜范围={result_word}

# V10E runner pre-launch independent review V5

## 结论

本节点的启动前合同裁决为 `{result_word}`。未启动 6B-cycle Verilator
systemd-strict 长回放，也未修改 production RTL、testbench、runner、两份
launcher 或共享 status helper。`gate-summary.json` 的 `all_gates`
{'全部为 true' if prelaunch_pass else '存在 false，禁止启动 a2'}。

## a1 runner-preflight 根因

- a1 固定状态为 `{a1_status_text}`；`evidence-query-errors.log` 对尚未生成的
  `driver.log`/`guest` 返回读取错误，`post-binding.txt` 的
  `rtl_design_id_post=PREHASH_UNAVAILABLE`、`npc_makefile_pre_sha256=UNAVAILABLE`
  和 `guest_checker_pre_sha256=UNAVAILABLE` 与 {len(a1_absence)}/{len(a1_absence)}
  build/sim 路径缺失共同证明它未进入构建或 guest cycle。
- a1 runner SHA-256 `{a1_runner_sha}` 与 V4 pre-snapshot 相同，而当前修正版
  runner SHA-256 为 `{digest(RUNNER)}`。`dispatch-log.md:205-207` 记录旧版在
  `runner-preflight` 错误要求 `test -x "${{guest_checker}}"`；a1 原 runner
  源码没有单独快照，因而该旧谓词的来源绑定为 V4 SHA + dispatch record，
  不把当前修正版倒推成旧源码。
- `git diff --raw {EMPTY_TREE}` 给出
  `{git_mode.stdout.strip()}`，且相对 `HEAD` 的 raw diff 为空；当前文件 mode
  为 `{current_mode:04o}`、SHA-256 为 `{guest_checker_sha}`，可读、非空且不可执行。
  当前 runner `{guest_contract['runner_readable_guard']['line']}` /
  `{guest_contract['runner_nonempty_guard']['line']}` 行使用 `test -r`/`test -s`，
  `{guest_contract['runner_bash_call']['line']}` 行通过 `bash "${{guest_checker}}"`
  调用。因此修正后的前置条件与实际 Bash 输入合同一致。

## runner / launcher / terminal 合同

- `bash -n` 检查 runner、V10E launcher、历史 V9S launcher 和 status helper，
  返回 `rc={syntax.returncode}`；status helper 定向 suite 返回
  `rc={status_result.returncode}`。
- selftest 返回 `rc={selftest.returncode}`，保存 `{len(negative_markers)}/42`
  个原始 `[NEGATIVE]` marker 与 `{len(dynamic_markers)}/8` 个原始
  `[DYNAMIC]` marker；`require-guest-checker-executable` 回退变异被拒绝，
  mode-0644 Bash fixture 返回 0。
- a2 的 result/status/runtime 三个目标在 validate-only 前后均为空；
  `V10E_RECERT_LAUNCH_VALIDATE_ONLY=1` 返回 `rc={a2_validate.returncode}` 并记录
  `{f'[V10E-RECERT-LAUNCH] validation PASS label={A2_LABEL}'}`。没有创建 a2
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
  prelaunch log 的 post-hash token 均存在；本轮 `{len(immutable_pre)}` 个输入
  SHA-256 {'无漂移' if not drift else f'发生 {len(drift)} 项漂移'}。
- V10E/V9S launcher 均绑定
  `.github/runtime-artifacts/rv64-engineering-single-flight.lock` 与 background
  contention rc=73；本节点末次 nonblocking reacquire `rc={lock_probe_rc}`，
  随即释放，锁文件 pre/post SHA-256 均为 `{lock_sha_post}`。

## 反例、unknowns、假设与替代解释

- 反例：`test -x` 回退、过度转义 regex、允许重复 terminal marker、私有化
  V10E/V9S lock、删除 launcher failure publisher 与忽略 PASS-write failure
  均被静态变异检出；cleanup rc=7、TERM rc=143、post-binding rc=1、
  assertion read-error rc=2、mode-0644 Bash 输入与 rootfs reuse rc=4 均有动态
  fixture。
- unknowns：本节点未观察 17/17 guest transaction、natural poweroff、
  reset-syscon、`GOOD TRAP` 或 simulator clean exit，也未运行综合/STA。a1
  的旧 runner 内容没有单独保存，只由其 SHA、V4 snapshot 与 dispatch 根因记录
  绑定；这不影响当前 42/42 变异与 mode-0644 动态反例，但属于历史源码可追溯性
  限制。
- 显式假设：Git empty-tree raw diff + HEAD 空 diff 足以绑定 tracked/current
  mode；`rg` 对不存在路径返回 2；`rtl_binding()` 的规范源集合仍是
  `npc/rv64/vsrc` 下 `.v/.sv/.vh/.svh/.mk`。
- 替代解释：a1 的 cleanup rc=2 是早期 terminal evidence 路径不存在的次生
  结果，不是 runner-preflight command rc=1 的起因；若否认 dispatch 中的旧
  `test -x` 记录，则只能把历史根因降为 inconclusive，但当前 `test -r`/`test -s`
  与 Bash 调用合同仍由独立静态/动态证据闭合。
- scope_extension_request：无。真实 6B system 回放属于主节点后续动作，本节点
  明确禁止启动。
- confidence_and_basis：对当前 pre-launch 合同为高，依据是原始 a1 rc/缺失
  artifact、Git/文件 mode、42/42 与 8/8 marker、a2 validate-only、0/1/2
  exact regex、pre/post design-id、输入 SHA-256 与锁释放；对完整 Linux system
  行为不作外推。

## 实现者 / 审查者复核

- 实现者证据：仅在 `{rel(OUT)}` 生成脚本、原始日志、返回码、JSON、SHA-256
  清单与本报告；production 文件未写入。
- 审查者质疑：优先检查 a1 是否可能进入 build/sim、旧 runner 是否缺少内容
  快照、tracked/current mode 是否真正为 100644、`test -x` 回退是否被杀死、
  a2 validate-only 是否留下目标、静态/dynamic marker 是否精确集合、live
  design-id 与 immutable inputs 是否漂移、全工作区锁是否可重取。除已明确保留
  的旧源码追溯性限制与长回放范围边界外，当前启动前 gate
  {'均由本地证据闭合' if prelaunch_pass else '仍有未闭合项，结论保持 GAP'}。

本报告及哈希落盘后，本节点停止工程命令；
single-flight ownership=RETURNED。
"""
(OUT / "review.md").write_text(report, encoding="utf-8")

hash_targets = [
    "generate-v5-evidence.py",
    "contract-sha256.log",
    "contract-sha256.rc",
    "guest-checker-git-mode.log",
    "guest-checker-git-mode.rc",
    "guest-checker-head-drift.log",
    "guest-checker-head-drift.rc",
    "guest-checker-mode.json",
    "a1-root-cause.json",
    "a1-raw-evidence.log",
    "bash-syntax.log",
    "bash-syntax.rc",
    "task-run-status.log",
    "task-run-status.rc",
    "runner-contract.log",
    "runner-contract.rc",
    "a2-launcher-validate-only.log",
    "a2-launcher-validate-only.rc",
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
        "计算 V5 证据产物 SHA-256 清单（cwd=review-v5）",
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
