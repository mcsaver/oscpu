#!/usr/bin/env python3
from __future__ import annotations

import fcntl
import hashlib
import json
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
OUT = RUN_DIR / "review-v4"
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
    / "subagent-contracts/v10e_runner_prelaunch_review_v4.json"
)
LOCK_PATH = (
    ROOT
    / ".github/runtime-artifacts/rv64-engineering-single-flight.lock"
)
ARCH_TOOL = ROOT / "npc/rv64/eval/ppa/tools/architecture_hard_gates.py"

EXPECTED_CONTRACT_SHA = (
    "e15a69c817ff6ee1e45e84419be653fae70c3502cc477b0de6748e216654c931"
)
EXPECTED_DESIGN_SHA = (
    "c1b5317212bfe47e507eac83a28dff405527f50493e3709e96ffbec2dc3bb594"
)
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
    ROOT / "npc/rv64/Makefile",
    ROOT / "npc/rv64/scripts/config.mk",
    ROOT / "npc/rv64/configs/default_defconfig",
    ARCH_TOOL,
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
) -> subprocess.CompletedProcess[str]:
    result = subprocess.run(
        argv,
        cwd=ROOT,
        check=False,
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


OUT.mkdir(parents=True, exist_ok=True)
contract_sha = digest(CONTRACT)
if contract_sha != EXPECTED_CONTRACT_SHA:
    raise SystemExit(
        f"contract SHA mismatch: expected={EXPECTED_CONTRACT_SHA} "
        f"actual={contract_sha}"
    )

sys.path.insert(0, str(ARCH_TOOL.parent))
import architecture_hard_gates as arch  # noqa: E402

immutable_pre = snapshot(IMMUTABLE_INPUTS)
lock_exists_pre = LOCK_PATH.is_file()
lock_sha_pre = digest(LOCK_PATH) if lock_exists_pre else "MISSING"
rtl_sha_pre, rtl_files_pre = arch.rtl_binding(ROOT)

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
status = run_logged(
    ["bash", rel(STATUS_TEST)],
    "task-run-status.log",
    "task-run-status.rc",
)
selftest = run_logged(
    ["python3", rel(SELFTEST)],
    "runner-contract.log",
    "runner-contract.rc",
)

runner_text = RUNNER.read_text(encoding="utf-8")
launcher_text = LAUNCHER.read_text(encoding="utf-8")
legacy_launcher_text = LEGACY_LAUNCHER.read_text(encoding="utf-8")
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

regex_parts = [
    (
        "[V10E-V4][ASSERTION-REGEX-SOURCE] "
        f"{rel(RUNNER)}:{pattern_line}\n"
    ),
    (
        "[V10E-V4][ASSERTION-REGEX-ARGV] "
        + json.dumps(
            ["rg", "-a", "-n", production_pattern],
            ensure_ascii=False,
        )
        + "\n"
    ),
    f"[V10E-V4][ASSERTION-REGEX-EXACT] {production_pattern == EXPECTED_ASSERTION_REGEX}\n",
    f"[V10E-V4][MATCH-INPUT] {positive_input!r}\n",
    f"[V10E-V4][MATCH-RC] {positive_rg.returncode}\n",
    "[V10E-V4][MATCH-OUTPUT-BEGIN]\n",
    positive_rg.stdout,
    "[V10E-V4][MATCH-OUTPUT-END]\n",
    f"[V10E-V4][NO-MATCH-INPUT] {clean_input!r}\n",
    f"[V10E-V4][NO-MATCH-RC] {clean_rg.returncode}\n",
    "[V10E-V4][NO-MATCH-OUTPUT-BEGIN]\n",
    clean_rg.stdout,
    "[V10E-V4][NO-MATCH-OUTPUT-END]\n",
    f"[V10E-V4][READ-ERROR-PATH] {rel(missing_path)}\n",
    f"[V10E-V4][READ-ERROR-RC] {missing_rg.returncode}\n",
    "[V10E-V4][READ-ERROR-OUTPUT-BEGIN]\n",
    missing_rg.stdout,
    "[V10E-V4][READ-ERROR-OUTPUT-END]\n",
    (
        "[V10E-V4][ASSERTION-REGEX-RC] "
        f"{positive_rg.returncode}/{clean_rg.returncode}/"
        f"{missing_rg.returncode}\n"
    ),
]
(OUT / "assertion-regex-fixture.log").write_text(
    "".join(regex_parts),
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

terminal_oracles = {
    name: {
        "guard": token,
        "occurrences": runner_text.count(token),
    }
    for name, token in TERMINAL_ORACLES.items()
}
post_hash_tokens = {
    name: {
        "token": token,
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
lock_probe_rc = 0
if lock_exists_post:
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
else:
    lock_probe_rc = 2

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

rtl_lines = [
    f"rtl_design_id_pre=sha256:{rtl_sha_pre}",
    f"rtl_design_id_post=sha256:{rtl_sha_post}",
    f"rtl_source_count_pre={len(rtl_files_pre)}",
    f"rtl_source_count_post={len(rtl_files_post)}",
    "rtl_source_manifest_begin",
]
rtl_lines.extend(
    f"{sha}  {name}" for name, sha in sorted(rtl_files_post.items())
)
rtl_lines.append("rtl_source_manifest_end")
(OUT / "rtl-binding.txt").write_text(
    "\n".join(rtl_lines) + "\n",
    encoding="utf-8",
)

dynamic_coverage = {
    snippet: any(snippet in line for line in dynamic_markers)
    for snippet in EXPECTED_DYNAMIC_SNIPPETS
}
static_set_exact = static_names == EXPECTED_STATIC_NAMES
regex_rc_exact = (
    positive_rg.returncode,
    clean_rg.returncode,
    missing_rg.returncode,
) == (0, 1, 2)
status_marker_ok = (
    "[task-run-status-test] PASS explicit completion, early exit, "
    "command failure, cleanup failure, PASS-write fallback, and HUP/INT/TERM"
    in status.stdout
)
all_gates = {
    "contract_sha": contract_sha == EXPECTED_CONTRACT_SHA,
    "bash_syntax": syntax.returncode == 0,
    "status_helper_suite": status.returncode == 0 and status_marker_ok,
    "runner_contract": selftest.returncode == 0
    and "[V10E-RUNNER-CONTRACT][FAIL]" not in contract_log,
    "static_41_of_41": len(negative_markers) == 41 and static_set_exact,
    "dynamic_7_of_7": len(dynamic_markers) == 7
    and all(dynamic_coverage.values()),
    "production_regex_exact": production_pattern == EXPECTED_ASSERTION_REGEX,
    "production_regex_rc_0_1_2": regex_rc_exact,
    "v3_overescape_counterexample_rejected": (
        "overescape-assertion-regex" in static_names
    ),
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
    "workspace_lock_released": lock_probe_rc == 0,
}
prelaunch_pass = all(all_gates.values())

summary = {
    "schema": "v10e-runner-prelaunch-review-v4-evidence-v1",
    "contract": {
        "path": rel(CONTRACT),
        "expected_sha256": EXPECTED_CONTRACT_SHA,
        "actual_sha256": contract_sha,
    },
    "syntax": {
        "argv": syntax_argv,
        "rc": syntax.returncode,
    },
    "status_helper_suite": {
        "argv": ["bash", rel(STATUS_TEST)],
        "rc": status.returncode,
        "marker_ok": status_marker_ok,
    },
    "runner_contract": {
        "argv": ["python3", rel(SELFTEST)],
        "rc": selftest.returncode,
        "static_negative_rejected": len(negative_markers),
        "static_negative_expected": 41,
        "static_names_exact": static_set_exact,
        "raw_negative_markers": negative_markers,
        "dynamic_fixture_markers": len(dynamic_markers),
        "dynamic_fixture_expected": 7,
        "dynamic_coverage": dynamic_coverage,
        "raw_dynamic_markers": dynamic_markers,
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
        "核对 V4 子任务合同 JSON SHA-256",
        0,
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
        status.returncode,
    ),
    (
        "python3",
        ["python3", rel(SELFTEST)],
        "运行 41 个静态负向变体与 7 类动态 fixture",
        selftest.returncode,
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
        [
            "python3",
            "-",
            "architecture_hard_gates.rtl_binding(ROOT)",
        ],
        "重算当前 npc/rv64/vsrc RTL design-id 与源文件 SHA-256 清单",
        0,
    ),
    (
        "python3",
        ["python3", rel(OUT / "generate-v4-evidence.py")],
        "生成 V4 启动前独立验证证据",
        0,
    ),
]

result_word = "PASS" if prelaunch_pass else "GAP"
report = f"""RV64 RTL 结论｜对象={rel(RUNNER)}::capture_terminal_evidence / {rel(OUT)}｜周期/配置=pre-launch, max_cycles=6000000000, OOO_CSR_QUEUE_HEAD=1, OOO_ASSERT=1, OOO_TERMINAL_HOLDER_ASSERT=1｜TB/EDA 观测=bash syntax rc={syntax.returncode}；status-helper rc={status.returncode}；{len(negative_markers)}/41 static + {len(dynamic_markers)}/7 dynamic；production rg rc={positive_rg.returncode}/{clean_rg.returncode}/{missing_rg.returncode}；rtl_binding=sha256:{rtl_sha_post}｜范围={result_word}

# V10E runner pre-launch independent review V4

## 结论

本节点的启动前合同裁决为 `{result_word}`。未启动 6B-cycle Verilator
systemd-strict 长回放，也未修改 production RTL、testbench、runner、两份
launcher 或共享 status helper。`gate-summary.json` 的
`all_gates` {'全部为 true' if prelaunch_pass else '存在 false，禁止启动'}。

## V3 blocker 与 design-id scope GAP

- V3 assertion regex blocker：生产赋值位于 `{rel(RUNNER)}:{pattern_line}`，
  V4 独立 exact-pattern fixture 得到 match/no-match/read-error
  `rc={positive_rg.returncode}/{clean_rg.returncode}/{missing_rg.returncode}`；
  `overescape-assertion-regex` 静态反例被定向测试拒绝。与 V3 的双反斜杠
  `rg rc=2` 反例相比，此 blocker {'已闭合' if regex_rc_exact else '未闭合'}。
- V3 design-id scope GAP：`architecture_hard_gates.rtl_binding()` 对
  `{len(rtl_files_post)}` 个 `.v/.sv/.vh/.svh/.mk` 源文件重算 pre/post 均为
  `sha256:{rtl_sha_post}`，与合同目标
  `sha256:{EXPECTED_DESIGN_SHA}` {'一致，scope GAP 已闭合' if rtl_sha_post == EXPECTED_DESIGN_SHA else '不一致，scope GAP 未闭合'}。

## runner / launcher / terminal 合同

- `bash -n` 同时检查 runner、V10E launcher、历史 V9S launcher 和
  `scripts/task-run-status.sh`，返回 `rc={syntax.returncode}`。
- status helper 定向 suite 返回 `rc={status.returncode}`；PASS-write 失败、
  early exit、command failure、cleanup failure 与 HUP/INT/TERM 均有
  fail-closed marker。
- selftest 返回 `rc={selftest.returncode}`，保存
  `{len(negative_markers)}/41` 个原始 `[NEGATIVE]` marker 和
  `{len(dynamic_markers)}/7` 个原始 `[DYNAMIC]` marker。
- 五类 terminal oracle
  `strict_done/poweroff_begin/syscon_terminal/system_reset_exit/good_trap`
  的 `-eq 1` guard 在 production runner 中各出现一次；
  `allow-duplicate-strict-done` 与 `allow-duplicate-good-trap` 反例被拒绝。
- 两份 launcher 均绑定
  `.github/runtime-artifacts/rv64-engineering-single-flight.lock`、
  background contention `rc=73` 与 failure publisher；动态 V9S probe
  返回 `rc=3`。fixture 结束后该锁 nonblocking reacquire `rc={lock_probe_rc}`，
  未遗留本节点锁持有者。

## post-hash 与漂移

production runner 的 rootfs template/cpio、RTL design-id、simulator、NPC
config/Makefile/manifest、kernel/OpenSBI/DTB、runner/status helper、Linux
Makefile、guest/strict checker、transaction parser、rootfs helper 与 durable
prelaunch log 的 post-hash token 均存在。V4 验证前后
`{len(immutable_pre)}` 个声明控制输入 SHA-256
{'无漂移' if not drift else f'发生 {len(drift)} 项漂移'}；完整清单见
`input-sha256-pre.txt`、`input-sha256-post.txt` 和 `rtl-binding.txt`。

## 反例、unknowns、假设与替代解释

- 反例：过度转义 production regex、两类允许重复 terminal marker、私有化
  V10E/V9S lock、删除 launcher failure publisher、忽略 PASS-write failure
  均被静态变异检出；cleanup rc=7、TERM rc=143、post-binding rc=1、
  assertion read-error rc=2 与 rootfs reuse rc=4 均不能产生 PASS。
- unknowns：本节点没有观察 17/17 guest transaction、natural poweroff、
  reset-syscon、`GOOD TRAP`、实际 simulator clean exit，也没有运行综合或 STA；
  因而 `{result_word}` 只覆盖 pre-launch runner 合同，不是 system recert PASS。
- 显式假设：当前 `rg` 对不存在路径稳定返回 2；`rtl_binding()` 的规范源集合
  仍是 `npc/rv64/vsrc` 下 `.v/.sv/.vh/.svh/.mk`。工具文件本身已纳入
  immutable input pre/post hash。
- 替代解释：静态 token/变异测试可以证明声明的 fail-closed 结构，却不能排除
  6B 长回放中才出现的 runtime artifact mutation、guest progress 或 terminal
  lifecycle 缺陷；这些只能由后续真实 systemd-strict 运行裁决。
- scope_extension_request：无。合同 V4 已授权关闭 design-id gate；真实 6B
  system 回放属于主节点后续动作，且本节点明确禁止启动。
- confidence_and_basis：对 pre-launch 合同为高；依据是原始 rc、41/41 与
  7/7 marker、0/1/2 exact regex、pre/post design-id、输入 SHA-256 与锁释放
  观测。对完整 Linux system 行为不作置信外推。

## 实现者 / 审查者复核

- 实现者证据：只在 `{rel(OUT)}` 生成验证脚本、原始日志、返回码、JSON、
  SHA-256 清单与本报告；production 文件未写入。
- 审查者质疑：优先复跑 V3 exact-regex 反例、核对静态 marker 集合而非只看
  overall PASS、重算 live RTL design-id、比较 immutable inputs pre/post，
  并复取全工作区锁排除遗留 owner。上述质疑
  {'均由本地证据闭合' if prelaunch_pass else '仍有未闭合 gate，结论保持 GAP'}；
  长回放未运行是明确范围边界，不作假绿推断。

本报告及哈希落盘后，本节点停止工程命令；
single-flight ownership=RETURNED。
"""
(OUT / "review.md").write_text(report, encoding="utf-8")

hash_targets = [
    "generate-v4-evidence.py",
    "bash-syntax.log",
    "bash-syntax.rc",
    "task-run-status.log",
    "task-run-status.rc",
    "runner-contract.log",
    "runner-contract.rc",
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
        "计算 V4 证据产物 SHA-256 清单（cwd=review-v4）",
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
(OUT / "sha256sums.txt").write_text(
    hash_result.stdout,
    encoding="utf-8",
)
if hash_result.returncode != 0:
    raise SystemExit(f"evidence sha256sum failed rc={hash_result.returncode}")
if not prelaunch_pass:
    raise SystemExit("pre-launch verification gate result is GAP")

print(
    "[V10E-V4][PASS] syntax=0 status=0 static=41/41 dynamic=7/7 "
    "assertion_regex=0/1/2 "
    f"rtl_design_id=sha256:{rtl_sha_post} lock_reacquire=0"
)
