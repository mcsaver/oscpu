#!/usr/bin/env bash
set -euo pipefail

# 本地 RV64 F32 ALU compile-only 证据链的 CMake 工具资格化：
# 只读复核 v3 已发布安装树，不执行安装、解包、configure/build、RTL binary、model 或 PPA。

REPO_ROOT=$(cd "$(dirname "$0")/../../.." && pwd)
NPU_ROOT="$REPO_ROOT/npu/version_0820"
TASK_ID="qwen-f32-alu-cmake-tool-v4"
RUNNER_REL="npu/version_0820/scripts/run-qwen-f32-alu-cmake-tool-v4.sh"
RUNNER="$REPO_ROOT/$RUNNER_REL"
LOG_ROOT="$NPU_ROOT/tmp/logs/$TASK_ID"
TOOLS_ROOT="$NPU_ROOT/tmp/tools"
V3_STAGING_ROOT="$TOOLS_ROOT/qwen-f32-alu-cmake-tool-v3-staging"
INSTALL_ROOT="$TOOLS_ROOT/cmake-3.31.12"
CMAKE_BIN="$INSTALL_ROOT/bin/cmake"

CONTRACT="$NPU_ROOT/tmp/contracts/qwen-f32-alu-cmake-tool-v4.json"
MATERIAL="$NPU_ROOT/tmp/contracts/qwen-f32-alu-cmake-tool-v4-material.md"
STATUS_HELPER="$REPO_ROOT/scripts/task-run-status.sh"
STATUS_HELPER_TEST="$REPO_ROOT/scripts/tests/test-task-run-status.sh"
V3_CONTRACT="$NPU_ROOT/tmp/contracts/qwen-f32-alu-cmake-tool-v3.json"
V3_MATERIAL="$NPU_ROOT/tmp/contracts/qwen-f32-alu-cmake-tool-v3-material.md"
V3_INSTALLER="$NPU_ROOT/scripts/install-cmake-local-v3.py"
V3_RUNNER="$NPU_ROOT/scripts/run-qwen-f32-alu-cmake-tool-v3.sh"
V3_LOG_ROOT="$NPU_ROOT/tmp/logs/qwen-f32-alu-cmake-tool-v3"
V2_CONTRACT="$NPU_ROOT/tmp/contracts/qwen-f32-alu-cmake-tool-v2.json"
V2_MATERIAL="$NPU_ROOT/tmp/contracts/qwen-f32-alu-cmake-tool-v2-material.md"
V2_INSTALLER="$NPU_ROOT/scripts/install-cmake-local-v2.py"
V2_RUNNER="$NPU_ROOT/scripts/run-qwen-f32-alu-cmake-tool-v2.sh"
V2_LOG_ROOT="$NPU_ROOT/tmp/logs/qwen-f32-alu-cmake-tool-v2"

STATUS_PATH="$LOG_ROOT/run.status"
EXPECTED_STATUS="$LOG_ROOT/expected.status"
RECEIPT="$LOG_ROOT/receipt.json"
BOUND_MANIFEST="$LOG_ROOT/bound-artifacts.json"
FINAL_BINDING="$LOG_ROOT/final-binding.json"
FALSE_SYSTEMEXIT="$LOG_ROOT/v3-false-systemexit-classification.json"
PROVENANCE_BINDING="$LOG_ROOT/v3-source-provenance-binding.json"
TREE_AUDIT_PRE="$LOG_ROOT/installed-tree-audit.pre.json"
TREE_AUDIT_POST="$LOG_ROOT/installed-tree-audit.post.json"
PARENT_PRE="$LOG_ROOT/parent-membership.pre.json"
PARENT_POST="$LOG_ROOT/parent-membership.post.json"
TASK_STATUS_TEST_STDOUT="$LOG_ROOT/task-run-status-test.stdout.log"
TASK_STATUS_TEST_STDERR="$LOG_ROOT/task-run-status-test.stderr.log"
TASK_STATUS_TEST_RC="$LOG_ROOT/task-run-status-test.rc"
VERSION_STDOUT="$LOG_ROOT/cmake-version.stdout.log"
VERSION_STDERR="$LOG_ROOT/cmake-version.stderr.log"
VERSION_RC="$LOG_ROOT/cmake-version.rc"
CMAKE_IDENTITY="$LOG_ROOT/cmake-identity.json"
ACTION_COUNTS="$LOG_ROOT/action-counts.json"
PROCESS_AUDIT="$LOG_ROOT/process-cleanup.json"
RUNTIME_TMP="$LOG_ROOT/runtime-tmp"
LOCAL_HOME="$LOG_ROOT/local-home"
LOCAL_CACHE="$LOG_ROOT/local-cache"

CONTRACT_SHA256="57b509770958913cbbe7fe843f09688156f53d6726ff7d58937fc4a98b570f5f"
MATERIAL_SHA256="527ed1b0b3fdeac18ef7a6e78f3f86a847cea3854d613f7779e825bdeeda4846"
STATUS_HELPER_SHA256="43977d9787cb41cc541eafa68f1c98f5e4504684b1104398274b07bc8155b7c6"
STATUS_HELPER_TEST_SHA256="35ba14c15c31a291e6a5db8b436d584d0535bd69d11db5495f00232e371a0640"
V3_CONTRACT_SHA256="5753882d61b8220a18bf29c3e3dad864d26c762f29cc40daa597b8594ffb3b39"
V3_MATERIAL_SHA256="65eb2968a890f45d9c0a4a6da790ecd9f031cbab28e818e405a90374390d3789"
V3_INSTALLER_SHA256="13408f4afb94e5cef0559575554997a09f55f684b37d943841fff32ced07e5f9"
V3_RUNNER_SHA256="462d4d6648b03f8a3f6fa9dfed748268c554a87191a0c10d15a66ebb5ce771c9"
V3_ARCHIVE_SHA256="0dc2e9a6860f06bf10bd8fadc03e35d9eeb4df46e33763a7e480e987758f385c"
V3_ARCHIVE_AUDIT_SHA256="8e4746dbbd3110a4d26f3e235156e105d5e63b613891f06ff843620801819997"
V3_TREE_MANIFEST_SHA256="a37e0b13ee2c83ae6b12ca75b424109d038f700757f2cfb7fdf9b3e804383a1f"
V3_INSTALLER_RESULT_SHA256="e640cda8b6310be33b396a44de0a863ba5a3386a5b94dfd074321b2e23af53a8"
V3_RUN_STATUS_SHA256="0e84b16b06de7bc09ae78d1965d262fe6d0633ddbc8e6590547c4afc446f8a6a"
V3_INSTALLER_STDOUT_SHA256="c19c967a0b15db1c6e26cea0242e76f54fde2c473b15f60f1254746c5b382b1c"
V3_INSTALLER_STDERR_SHA256="a1c47ca3be4eda14b3c89c360ffcc657d9950da4d78c6fcdd929506bc82ef756"
CMAKE_SHA256="d8ed20c9688adaf5ee8d387072424aa732c5f589e860347e0dfa51cca37dc863"
EXPECTED_CMAKE_SIZE=17241856
EXPECTED_TREE_ENTRIES=8173

export PYTHONDONTWRITEBYTECODE=1
export LC_ALL=C
umask 077

# helper 在 source 前先绑定冻结字节，避免漂移脚本先于 admission 执行。
STATUS_HELPER_OBSERVED=$(sha256sum "$STATUS_HELPER")
[[ "${STATUS_HELPER_OBSERVED%% *}" == "$STATUS_HELPER_SHA256" ]] || {
    printf '%s\n' \
        "[NPU-QWEN-F32-ALU-CMAKE-TOOL-V4][FAIL] status helper hash mismatch before source" >&2
    exit 1
}

# shellcheck source=/dev/null
source "$STATUS_HELPER"

STATUS_INITIALIZED=0
TERMINAL_SUCCESS=0
FORCED_CLEANUP_RC=0
PATH_SNAPSHOT="$PATH"

fail() {
    printf '%s\n' "[NPU-QWEN-F32-ALU-CMAKE-TOOL-V4][FAIL] $*" >&2
    return 1
}

fail_rc() {
    local rc="${1:?return code is required}"
    shift
    printf '%s\n' "[NPU-QWEN-F32-ALU-CMAKE-TOOL-V4][FAIL] $*" >&2
    return "$rc"
}

path_absent() {
    [[ ! -e "$1" && ! -L "$1" ]]
}

file_sha() {
    local value
    value=$(sha256sum "$1")
    printf '%s\n' "${value%% *}"
}

require_file() {
    [[ -f "$1" && ! -L "$1" ]] ||
        fail "required regular file missing/aliased=$1"
}

require_exact_hash() {
    local path="$1"
    local expected="$2"
    require_file "$path"
    [[ "$(file_sha "$path")" == "$expected" ]] ||
        fail "frozen hash mismatch path=$path expected=$expected"
}

# canonical helper 决定 RUNNING/PASS/FAIL；覆盖只收紧为 same-directory exclusive temp。
_task_run_status_write() {
    local status_line="${1:?status line is required}"
    [[ -n "${TASK_RUN_STATUS_PATH}" ]] || {
        printf '%s\n' "[task-run-status] status path is not initialized" >&2
        return 2
    }
    python3 - "$TASK_RUN_STATUS_PATH" "$status_line" <<'PY'
import os
import pathlib
import stat
import sys

path = pathlib.Path(sys.argv[1])
payload = (sys.argv[2] + "\n").encode("utf-8")
parent_stat = path.parent.lstat()
if not stat.S_ISDIR(parent_stat.st_mode) or stat.S_ISLNK(parent_stat.st_mode):
    raise SystemExit("status parent is not a real directory")
try:
    current = path.lstat()
except FileNotFoundError:
    current = None
if current is not None and (
    not stat.S_ISREG(current.st_mode) or stat.S_ISLNK(current.st_mode)
):
    raise SystemExit("status destination is not a regular file")
temporary = path.parent / f".{path.name}.tmp.{os.getpid()}"
flags = os.O_WRONLY | os.O_CREAT | os.O_EXCL | getattr(os, "O_NOFOLLOW", 0)
descriptor = os.open(temporary, flags, 0o600)
try:
    offset = 0
    while offset < len(payload):
        count = os.write(descriptor, payload[offset:])
        if count <= 0:
            raise OSError("short status write")
        offset += count
    os.fsync(descriptor)
finally:
    os.close(descriptor)
os.replace(temporary, path)
directory_fd = os.open(
    path.parent, os.O_RDONLY | getattr(os, "O_DIRECTORY", 0)
)
try:
    os.fsync(directory_fd)
finally:
    os.close(directory_fd)
PY
}

publish_text_no_replace() {
    local output="${1:?output is required}"
    local value="${2-}"
    python3 - "$output" "$value" <<'PY'
import os
import pathlib
import stat
import sys

path = pathlib.Path(sys.argv[1])
payload = sys.argv[2].encode("utf-8")
parent_stat = path.parent.lstat()
if not stat.S_ISDIR(parent_stat.st_mode) or stat.S_ISLNK(parent_stat.st_mode):
    raise SystemExit("publication parent is not a real directory")
try:
    path.lstat()
except FileNotFoundError:
    pass
else:
    raise SystemExit("refusing to replace retained output: " + str(path))
temporary = path.parent / f".{path.name}.tmp.{os.getpid()}"
flags = os.O_WRONLY | os.O_CREAT | os.O_EXCL | getattr(os, "O_NOFOLLOW", 0)
descriptor = os.open(temporary, flags, 0o600)
try:
    offset = 0
    while offset < len(payload):
        count = os.write(descriptor, payload[offset:])
        if count <= 0:
            raise OSError("short publication write")
        offset += count
    os.fsync(descriptor)
finally:
    os.close(descriptor)
try:
    os.link(temporary, path, follow_symlinks=False)
finally:
    temporary.unlink(missing_ok=True)
directory_fd = os.open(
    path.parent, os.O_RDONLY | getattr(os, "O_DIRECTORY", 0)
)
try:
    os.fsync(directory_fd)
finally:
    os.close(directory_fd)
PY
}

capture_parent_membership() {
    python3 - "$LOG_ROOT" "$V3_STAGING_ROOT" "$INSTALL_ROOT" <<'PY'
import json
import pathlib
import stat
import sys

def signature(observed):
    return {
        "dev": observed.st_dev,
        "ino": observed.st_ino,
        "mode": f"{stat.S_IMODE(observed.st_mode):04o}",
        "size": observed.st_size,
        "mtime_ns": observed.st_mtime_ns,
        "ctime_ns": observed.st_ctime_ns,
    }

def record(path):
    try:
        observed = path.lstat()
    except FileNotFoundError:
        return {"path": str(path), "present": False, "kind": "absent"}
    if stat.S_ISDIR(observed.st_mode) and not stat.S_ISLNK(observed.st_mode):
        kind = "directory"
    elif stat.S_ISREG(observed.st_mode):
        kind = "regular"
    elif stat.S_ISLNK(observed.st_mode):
        kind = "symlink"
    else:
        kind = "special"
    return {
        "path": str(path),
        "present": True,
        "kind": kind,
        "stat": signature(observed),
    }

value = {
    "schema_version": 1,
    "paths": [record(pathlib.Path(item)) for item in sys.argv[1:]],
}
print(json.dumps(value, sort_keys=True, separators=(",", ":")))
PY
}

run_with_exclusive_logs() {
    local stdout_path="${1:?stdout path is required}"
    local stderr_path="${2:?stderr path is required}"
    shift 2
    (
        set -o noclobber
        "$@" >"$stdout_path" 2>"$stderr_path"
    )
}

read_first_line() {
    local path="${1:?path is required}"
    local value=""
    IFS= read -r value <"$path" || [[ -n "$value" ]]
    printf '%s\n' "$value"
}

write_process_audit() {
    local bash_job_count="${1:?bash job count is required}"
    python3 - "$TASK_ID" "$bash_job_count" "$PROCESS_AUDIT" <<'PY'
import json
import os
import pathlib
import stat
import sys

task_id = sys.argv[1]
bash_job_count = int(sys.argv[2])
output = pathlib.Path(sys.argv[3])
excluded = set()
pid = os.getpid()
while pid > 0 and pid not in excluded:
    excluded.add(pid)
    try:
        pid = int(pathlib.Path(f"/proc/{pid}/stat").read_text().split()[3])
    except (OSError, ValueError, IndexError):
        break
owned = []
for entry in pathlib.Path("/proc").iterdir():
    if not entry.name.isdigit() or int(entry.name) in excluded:
        continue
    try:
        command = (
            (entry / "cmdline")
            .read_bytes()
            .replace(b"\0", b" ")
            .decode(errors="replace")
        )
    except OSError:
        continue
    if task_id in command:
        owned.append({"pid": int(entry.name), "cmdline": command})
if owned or bash_job_count != 0:
    raise SystemExit("owned process/job cleanup is incomplete")
value = {
    "schema_version": 1,
    "task_id": task_id,
    "bash_job_count": bash_job_count,
    "owned_process_count": len(owned),
    "owned_processes": owned,
    "cleanup_rc": 0,
}
payload = (
    json.dumps(value, sort_keys=True, separators=(",", ":")) + "\n"
).encode()
temporary = output.parent / f".{output.name}.tmp.{os.getpid()}"
descriptor = os.open(
    temporary,
    os.O_WRONLY | os.O_CREAT | os.O_EXCL | getattr(os, "O_NOFOLLOW", 0),
    0o600,
)
try:
    offset = 0
    while offset < len(payload):
        count = os.write(descriptor, payload[offset:])
        if count <= 0:
            raise OSError("short process audit write")
        offset += count
    os.fsync(descriptor)
finally:
    os.close(descriptor)
os.link(temporary, output, follow_symlinks=False)
temporary.unlink()
directory_fd = os.open(
    output.parent, os.O_RDONLY | getattr(os, "O_DIRECTORY", 0)
)
try:
    os.fsync(directory_fd)
finally:
    os.close(directory_fd)
PY
}

attempt_failure_cleanup() {
    local cleanup_rc=0
    local owned_jobs=""
    if ! path_absent "$LOCAL_HOME"; then
        cleanup_rc=91
    fi
    if ! path_absent "$LOCAL_CACHE" && [[ $cleanup_rc -eq 0 ]]; then
        cleanup_rc=92
    fi
    if ! path_absent "$RUNTIME_TMP"; then
        if ! rmdir -- "$RUNTIME_TMP" && [[ $cleanup_rc -eq 0 ]]; then
            cleanup_rc=93
        fi
    fi
    owned_jobs=$(jobs -pr)
    if [[ -n "$owned_jobs" && $cleanup_rc -eq 0 ]]; then
        cleanup_rc=96
    fi
    if path_absent "$PROCESS_AUDIT"; then
        local audit_rc=0
        if write_process_audit 0; then
            audit_rc=0
        else
            audit_rc=$?
        fi
        if [[ $audit_rc -ne 0 && $cleanup_rc -eq 0 ]]; then
            cleanup_rc=97
        fi
    fi
    FORCED_CLEANUP_RC=$cleanup_rc
}

finish_on_exit() {
    local command_rc=$?
    local effective_rc=$command_rc
    local finalize_rc=0
    trap - EXIT HUP INT TERM
    set +e
    if [[ $STATUS_INITIALIZED -eq 1 ]] &&
       [[ $command_rc -ne 0 || $FORCED_CLEANUP_RC -ne 0 || $TERMINAL_SUCCESS -ne 1 ]]; then
        attempt_failure_cleanup
        if [[ $effective_rc -eq 0 ]]; then
            if [[ $FORCED_CLEANUP_RC -ne 0 ]]; then
                effective_rc=$FORCED_CLEANUP_RC
            else
                effective_rc=1
            fi
        fi
        task_run_status_finalize "$effective_rc" "$FORCED_CLEANUP_RC"
        finalize_rc=$?
        if [[ $command_rc -eq 0 ]]; then
            command_rc=$finalize_rc
        fi
    elif [[ $command_rc -eq 0 && $FORCED_CLEANUP_RC -ne 0 ]]; then
        command_rc=$FORCED_CLEANUP_RC
    fi
    exit "$command_rc"
}

install_runner_traps() {
    trap finish_on_exit EXIT
    task_run_status_install_signal_traps
}

qualification_window() {
    local phase="${1:?qualification phase is required}"
    python3 - "$REPO_ROOT" "$LOG_ROOT" "$INSTALL_ROOT" "$V3_STAGING_ROOT" \
        "$phase" <<'PY'
import ast
import hashlib
import json
import os
import pathlib
import re
import stat
import sys

root = pathlib.Path(sys.argv[1]).resolve(strict=True)
log_root = pathlib.Path(sys.argv[2])
install_root = pathlib.Path(sys.argv[3])
staging_root = pathlib.Path(sys.argv[4])
phase = sys.argv[5]

if phase not in {"pre", "post"}:
    raise SystemExit("unknown qualification phase")

v2_log = root / "npu/version_0820/tmp/logs/qwen-f32-alu-cmake-tool-v2"
v3_log = root / "npu/version_0820/tmp/logs/qwen-f32-alu-cmake-tool-v3"
v3_installer = root / "npu/version_0820/scripts/install-cmake-local-v3.py"
cmake_bin = install_root / "bin/cmake"

paths = {
    "v4_contract": root / "npu/version_0820/tmp/contracts/qwen-f32-alu-cmake-tool-v4.json",
    "v4_material": root / "npu/version_0820/tmp/contracts/qwen-f32-alu-cmake-tool-v4-material.md",
    "status_helper": root / "scripts/task-run-status.sh",
    "status_helper_test": root / "scripts/tests/test-task-run-status.sh",
    "v2_contract": root / "npu/version_0820/tmp/contracts/qwen-f32-alu-cmake-tool-v2.json",
    "v2_material": root / "npu/version_0820/tmp/contracts/qwen-f32-alu-cmake-tool-v2-material.md",
    "v2_installer": root / "npu/version_0820/scripts/install-cmake-local-v2.py",
    "v2_runner": root / "npu/version_0820/scripts/run-qwen-f32-alu-cmake-tool-v2.sh",
    "v2_checksum_download": v2_log / "checksum-download.log",
    "v2_archive_download": v2_log / "archive-download.log",
    "v2_source_provenance": v2_log / "source-provenance.json",
    "v2_checksum": v2_log / "cmake-3.31.12-SHA-256.txt",
    "v2_archive": v2_log / "cmake-3.31.12-linux-x86_64.tar.gz",
    "v3_contract": root / "npu/version_0820/tmp/contracts/qwen-f32-alu-cmake-tool-v3.json",
    "v3_material": root / "npu/version_0820/tmp/contracts/qwen-f32-alu-cmake-tool-v3-material.md",
    "v3_installer": v3_installer,
    "v3_runner": root / "npu/version_0820/scripts/run-qwen-f32-alu-cmake-tool-v3.sh",
    "v3_predecessor_binding": v3_log / "predecessor-failure-binding.json",
    "v3_input_binding": v3_log / "predecessor-input-binding.json",
    "v3_checksum": v3_log / "cmake-3.31.12-SHA-256.txt",
    "v3_archive": v3_log / "cmake-3.31.12-linux-x86_64.tar.gz",
    "v3_archive_audit": v3_log / "archive-audit.json",
    "v3_tree_manifest": v3_log / "installed-tree-manifest.json",
    "v3_installer_result": v3_log / "installer-result.json",
    "v3_installer_stdout": v3_log / "installer.stdout.log",
    "v3_installer_stderr": v3_log / "installer.stderr.log",
    "v3_installer_rc": v3_log / "installer.rc",
    "v3_run_status": v3_log / "run.status",
    "v3_process_cleanup": v3_log / "process-cleanup.json",
    "v3_parent_pre": v3_log / "parent-membership.pre.json",
    "v3_task_test_stdout": v3_log / "task-run-status-test.stdout.log",
    "v3_task_test_stderr": v3_log / "task-run-status-test.stderr.log",
    "v3_task_test_rc": v3_log / "task-run-status-test.rc",
}

expected_hashes = {
    "v4_contract": "57b509770958913cbbe7fe843f09688156f53d6726ff7d58937fc4a98b570f5f",
    "v4_material": "527ed1b0b3fdeac18ef7a6e78f3f86a847cea3854d613f7779e825bdeeda4846",
    "status_helper": "43977d9787cb41cc541eafa68f1c98f5e4504684b1104398274b07bc8155b7c6",
    "status_helper_test": "35ba14c15c31a291e6a5db8b436d584d0535bd69d11db5495f00232e371a0640",
    "v2_contract": "4a5dcacd8e532b136a5b55142b9822c942c4018f707de0dc0efcb6cc77fafa9c",
    "v2_material": "c1798abb87655273e1729c9faa07c0873676d6ade44187e116a155e22d291195",
    "v2_installer": "748dda6fbabdfbae0ed0622ddac2c99a0a52da027c716cd6265b957d3bebce40",
    "v2_runner": "d59b403330d7d6bda83f727d9bda15a68f6d6b20ecb4b43fa1bba61b94afcd36",
    "v2_checksum_download": "a1e4dea26b1feb265500df8ac0f4f67e10b95606601bb69032143a06fd6a9288",
    "v2_archive_download": "2761148ced5c427be716eaae78cca64043030523241d2ba7bb218dc2a38f55ff",
    "v2_source_provenance": "2c23184af1e1ae90c6acc14a2c9c95e35f92878e1d54dd23084f301a72b2e6f3",
    "v2_checksum": "159eb3b123ba8c8403a154c9d3389432276bf3bd21b274f0396fe17a6a7a7d9d",
    "v2_archive": "0dc2e9a6860f06bf10bd8fadc03e35d9eeb4df46e33763a7e480e987758f385c",
    "v3_contract": "5753882d61b8220a18bf29c3e3dad864d26c762f29cc40daa597b8594ffb3b39",
    "v3_material": "65eb2968a890f45d9c0a4a6da790ecd9f031cbab28e818e405a90374390d3789",
    "v3_installer": "13408f4afb94e5cef0559575554997a09f55f684b37d943841fff32ced07e5f9",
    "v3_runner": "462d4d6648b03f8a3f6fa9dfed748268c554a87191a0c10d15a66ebb5ce771c9",
    "v3_predecessor_binding": "344c339bd6f78984e897a03aae726a82c45dc9d2b5b368152e2ec3899cb2da47",
    "v3_input_binding": "b3d7148d3686f6efe2964ebd8705eb90bb43d758fd39427bbfa772b19098c24b",
    "v3_checksum": "159eb3b123ba8c8403a154c9d3389432276bf3bd21b274f0396fe17a6a7a7d9d",
    "v3_archive": "0dc2e9a6860f06bf10bd8fadc03e35d9eeb4df46e33763a7e480e987758f385c",
    "v3_archive_audit": "8e4746dbbd3110a4d26f3e235156e105d5e63b613891f06ff843620801819997",
    "v3_tree_manifest": "a37e0b13ee2c83ae6b12ca75b424109d038f700757f2cfb7fdf9b3e804383a1f",
    "v3_installer_result": "e640cda8b6310be33b396a44de0a863ba5a3386a5b94dfd074321b2e23af53a8",
    "v3_installer_stdout": "c19c967a0b15db1c6e26cea0242e76f54fde2c473b15f60f1254746c5b382b1c",
    "v3_installer_stderr": "a1c47ca3be4eda14b3c89c360ffcc657d9950da4d78c6fcdd929506bc82ef756",
    "v3_installer_rc": "4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865",
    "v3_run_status": "0e84b16b06de7bc09ae78d1965d262fe6d0633ddbc8e6590547c4afc446f8a6a",
    "v3_process_cleanup": "867f9a358212055494a1624af13e76efc1d4aa5a6d122055e008052bc2d20f14",
    "v3_parent_pre": "0abc508a1b996f89c14c3b4e8f96f0762515a839c1e800f8d8fd627237e13255",
    "v3_task_test_stdout": "33fc3f7f53ad33d89c1d11ea0185f2e1eb21e1ff4346d6a8e0579005b71a3292",
    "v3_task_test_stderr": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
    "v3_task_test_rc": "9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa",
}

roles = {
    "v4_contract": "v4-task-contract",
    "v4_material": "v4-task-material",
    "status_helper": "fail-closed-status-helper",
    "status_helper_test": "status-helper-directed-test",
    "v2_contract": "v2-task-contract",
    "v2_material": "v2-task-material",
    "v2_installer": "v2-installer-source",
    "v2_runner": "v2-runner-source",
    "v2_checksum_download": "v2-checksum-download-log",
    "v2_archive_download": "v2-archive-download-log",
    "v2_source_provenance": "v2-source-provenance",
    "v2_checksum": "v2-retained-official-checksum",
    "v2_archive": "v2-retained-official-archive",
    "v3_contract": "v3-task-contract",
    "v3_material": "v3-task-material",
    "v3_installer": "v3-installer-source",
    "v3_runner": "v3-runner-source",
    "v3_predecessor_binding": "v3-predecessor-failure-binding",
    "v3_input_binding": "v3-source-reuse-binding",
    "v3_checksum": "v3-copied-official-checksum",
    "v3_archive": "v3-copied-official-archive",
    "v3_archive_audit": "v3-complete-archive-audit",
    "v3_tree_manifest": "v3-complete-installed-tree-manifest",
    "v3_installer_result": "v3-installer-pass-result",
    "v3_installer_stdout": "v3-installer-pass-stdout",
    "v3_installer_stderr": "v3-false-systemexit-stderr",
    "v3_installer_rc": "v3-wrapper-rc",
    "v3_run_status": "v3-fail-closed-run-status",
    "v3_process_cleanup": "v3-process-cleanup",
    "v3_parent_pre": "v3-pre-publication-membership",
    "v3_task_test_stdout": "v3-status-test-stdout",
    "v3_task_test_stderr": "v3-status-test-stderr",
    "v3_task_test_rc": "v3-status-test-rc",
}

def path_absent(path):
    try:
        path.lstat()
    except FileNotFoundError:
        return True
    return False

def require_parent_chain_real(path):
    relative = path.absolute().relative_to(root)
    current = root
    for component in relative.parts[:-1]:
        current = current / component
        observed = current.lstat()
        if not stat.S_ISDIR(observed.st_mode) or stat.S_ISLNK(observed.st_mode):
            raise SystemExit("non-directory or symlink parent: " + str(current))

def stat_signature(observed):
    return (
        observed.st_dev,
        observed.st_ino,
        observed.st_mode,
        observed.st_size,
        observed.st_mtime_ns,
        observed.st_ctime_ns,
    )

def stat_json(observed):
    return {
        "dev": observed.st_dev,
        "ino": observed.st_ino,
        "mode": f"{stat.S_IMODE(observed.st_mode):04o}",
        "size": observed.st_size,
        "mtime_ns": observed.st_mtime_ns,
        "ctime_ns": observed.st_ctime_ns,
    }

def stable_regular(path, capture=False):
    require_parent_chain_real(path)
    flags = os.O_RDONLY | getattr(os, "O_CLOEXEC", 0) | getattr(os, "O_NOFOLLOW", 0)
    descriptor = os.open(path, flags)
    digest = hashlib.sha256()
    chunks = [] if capture else None
    total = 0
    try:
        before = os.fstat(descriptor)
        if not stat.S_ISREG(before.st_mode):
            raise SystemExit("stable input is not regular: " + str(path))
        while True:
            chunk = os.read(descriptor, 1024 * 1024)
            if not chunk:
                break
            total += len(chunk)
            digest.update(chunk)
            if chunks is not None:
                chunks.append(chunk)
        after = os.fstat(descriptor)
    finally:
        os.close(descriptor)
    if stat_signature(before) != stat_signature(after) or total != before.st_size:
        raise SystemExit("stable input changed during no-follow read: " + str(path))
    return (
        b"".join(chunks) if chunks is not None else None,
        before,
        digest.hexdigest(),
    )

def stable_bytes(path):
    data, observed, digest = stable_regular(path, capture=True)
    return data, observed, digest

def relative(path):
    return path.absolute().relative_to(root).as_posix()

def artifact(path, role):
    _, observed, digest = stable_regular(path)
    return {
        "path": relative(path),
        "role": role,
        "size": observed.st_size,
        "sha256": digest,
    }

def load_json(path):
    data, _, digest = stable_bytes(path)
    try:
        value = json.loads(data)
    except (UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise SystemExit(f"invalid JSON {path}: {exc}") from exc
    return value, data, digest

def publish_json(path, value):
    payload = (
        json.dumps(value, sort_keys=True, separators=(",", ":")) + "\n"
    ).encode()
    parent_stat = path.parent.lstat()
    if not stat.S_ISDIR(parent_stat.st_mode) or stat.S_ISLNK(parent_stat.st_mode):
        raise SystemExit("publication parent is not a real directory")
    try:
        path.lstat()
    except FileNotFoundError:
        pass
    else:
        raise SystemExit("refusing to replace qualification artifact: " + str(path))
    temporary = path.parent / f".{path.name}.tmp.{os.getpid()}"
    descriptor = os.open(
        temporary,
        os.O_WRONLY
        | os.O_CREAT
        | os.O_EXCL
        | getattr(os, "O_CLOEXEC", 0)
        | getattr(os, "O_NOFOLLOW", 0),
        0o600,
    )
    try:
        offset = 0
        while offset < len(payload):
            count = os.write(descriptor, payload[offset:])
            if count <= 0:
                raise OSError("short qualification artifact write")
            offset += count
        os.fsync(descriptor)
    finally:
        os.close(descriptor)
    try:
        os.link(temporary, path, follow_symlinks=False)
    finally:
        temporary.unlink(missing_ok=True)
    directory_fd = os.open(
        path.parent, os.O_RDONLY | getattr(os, "O_DIRECTORY", 0)
    )
    try:
        os.fsync(directory_fd)
    finally:
        os.close(directory_fd)
    return payload

def require_real_directory(path):
    require_parent_chain_real(path)
    observed = path.lstat()
    if not stat.S_ISDIR(observed.st_mode) or stat.S_ISLNK(observed.st_mode):
        raise SystemExit("required real directory missing/aliased: " + str(path))
    descriptor = os.open(
        path,
        os.O_RDONLY
        | getattr(os, "O_DIRECTORY", 0)
        | getattr(os, "O_CLOEXEC", 0)
        | getattr(os, "O_NOFOLLOW", 0),
    )
    try:
        opened = os.fstat(descriptor)
    finally:
        os.close(descriptor)
    if (observed.st_dev, observed.st_ino) != (opened.st_dev, opened.st_ino):
        raise SystemExit("directory identity changed during no-follow open: " + str(path))
    return observed

def canonical_relative(value, allow_root=False):
    if not isinstance(value, str) or not value or "\0" in value or "\\" in value:
        raise SystemExit("invalid manifest/census path spelling")
    if value == ".":
        if allow_root:
            return value
        raise SystemExit("root path is not allowed in this record")
    pure = pathlib.PurePosixPath(value)
    if pure.is_absolute() or pure.as_posix() != value:
        raise SystemExit("non-canonical relative path: " + value)
    if any(part in {"", ".", ".."} for part in pure.parts):
        raise SystemExit("unsafe relative path: " + value)
    return value

def validate_frozen():
    records = []
    for name in sorted(paths):
        _, observed, digest = stable_regular(paths[name])
        expected = expected_hashes[name]
        if digest != expected:
            raise SystemExit(
                f"frozen artifact hash mismatch {name}: expected={expected} actual={digest}"
            )
        records.append(
            {
                "path": relative(paths[name]),
                "role": roles[name],
                "size": observed.st_size,
                "sha256": digest,
            }
        )
    return records

def validate_archive_audit(value):
    exact = {
        "schema_version": 1,
        "task_id": "qwen-f32-alu-cmake-tool-v3",
        "archive_sha256": expected_hashes["v3_archive"],
        "archive_size_bytes": 55005786,
        "top_level_directory": "cmake-3.31.12-linux-x86_64",
        "explicit_top_directory_count": 0,
        "implicit_top_directory": True,
        "implicit_top_directory_synthesized_mode": "0755",
        "descendant_member_count": 8172,
        "member_count": 8172,
        "member_census_count": 8172,
        "member_census_complete": True,
        "regular_file_count": 8035,
        "directory_count": 137,
        "symlink_count": 0,
        "hardlink_count": 0,
        "special_count": 0,
        "sparse_count": 0,
        "setid_sticky_mode_count": 0,
        "total_regular_size_bytes": 157953708,
        "duplicate_canonical_name_count": 0,
        "path_escape_count": 0,
        "member_policy": "regular-files-and-directories-only-below-single-top",
    }
    for key, expected in exact.items():
        if value.get(key) != expected:
            raise SystemExit(f"v3 archive audit field mismatch {key}")
    census = value.get("member_census")
    if not isinstance(census, list) or len(census) != 8172:
        raise SystemExit("v3 archive complete census missing")
    seen = set()
    regular_count = 0
    directory_count = 0
    total_size = 0
    prefix = "cmake-3.31.12-linux-x86_64/"
    for index, item in enumerate(census):
        if not isinstance(item, dict) or set(item) != {
            "archive_index",
            "path",
            "kind",
            "mode",
            "size",
        }:
            raise SystemExit("v3 archive census schema mismatch")
        if item["archive_index"] != index:
            raise SystemExit("v3 archive census index is not contiguous")
        name = canonical_relative(item["path"])
        if not name.startswith(prefix) or name in seen:
            raise SystemExit("v3 archive census path/duplicate mismatch")
        seen.add(name)
        if not re.fullmatch(r"[0-7]{4}", item["mode"]):
            raise SystemExit("v3 archive census mode is not canonical")
        mode = int(item["mode"], 8)
        if mode & 0o7000:
            raise SystemExit("v3 archive census contains set-id/sticky mode")
        if item["kind"] == "directory":
            if item["size"] != 0:
                raise SystemExit("v3 archive directory has nonzero size")
            directory_count += 1
        elif item["kind"] == "regular":
            if not isinstance(item["size"], int) or item["size"] < 0:
                raise SystemExit("v3 archive regular size invalid")
            regular_count += 1
            total_size += item["size"]
        else:
            raise SystemExit("v3 archive census contains rejected object kind")
    if (regular_count, directory_count, total_size) != (8035, 137, 157953708):
        raise SystemExit("v3 archive census recomputed totals mismatch")

def validate_manifest(value):
    exact = {
        "schema_version": 1,
        "task_id": "qwen-f32-alu-cmake-tool-v3",
        "release_version": "3.31.12",
        "archive_top_level": "cmake-3.31.12-linux-x86_64",
        "published_install_name": "cmake-3.31.12",
        "archive_sha256": expected_hashes["v3_archive"],
        "archive_audit_sha256": expected_hashes["v3_archive_audit"],
        "implicit_top_directory": True,
        "explicit_top_directory_count": 0,
        "entry_count": 8173,
        "regular_file_count": 8035,
        "directory_count": 138,
        "symlink_count": 0,
    }
    for key, expected in exact.items():
        if value.get(key) != expected:
            raise SystemExit(f"v3 installed manifest field mismatch {key}")
    entries = value.get("entries")
    if not isinstance(entries, list) or len(entries) != 8173:
        raise SystemExit("v3 installed manifest entry list missing")
    seen = set()
    regular_count = 0
    directory_count = 0
    for index, item in enumerate(entries):
        if not isinstance(item, dict):
            raise SystemExit("v3 installed manifest record is not an object")
        path = canonical_relative(item.get("path"), allow_root=True)
        if (index == 0) != (path == ".") or path in seen:
            raise SystemExit("v3 installed manifest root/order/duplicate mismatch")
        seen.add(path)
        if not re.fullmatch(r"[0-7]{4}", item.get("mode", "")):
            raise SystemExit("v3 installed manifest mode is not canonical")
        mode = int(item["mode"], 8)
        if mode & 0o7000:
            raise SystemExit("v3 installed manifest contains set-id/sticky mode")
        if item.get("kind") == "directory":
            if set(item) != {"path", "kind", "mode", "size"} or item["size"] != 0:
                raise SystemExit("v3 installed directory record schema mismatch")
            directory_count += 1
        elif item.get("kind") == "regular":
            if set(item) != {"path", "kind", "mode", "size", "sha256"}:
                raise SystemExit("v3 installed regular record schema mismatch")
            if (
                not isinstance(item["size"], int)
                or item["size"] < 0
                or not re.fullmatch(r"[0-9a-f]{64}", item["sha256"])
            ):
                raise SystemExit("v3 installed regular identity invalid")
            regular_count += 1
        else:
            raise SystemExit("v3 installed manifest contains link/special kind")
        if path != "." and (
            path.split("/")[-1] == "__pycache__" or path.endswith(".pyc")
        ):
            raise SystemExit("v3 installed manifest contains Python cache residue")
    if (regular_count, directory_count) != (8035, 138):
        raise SystemExit("v3 installed manifest recomputed totals mismatch")
    return entries

def validate_installer_result(value):
    exact = {
        "schema_version": 1,
        "task_id": "qwen-f32-alu-cmake-tool-v3",
        "result": "PASS",
        "release_version": "3.31.12",
        "installer_path": str(v3_installer),
        "installer_sha256": expected_hashes["v3_installer"],
        "installer_invocation_count": 1,
        "network_download_count": 0,
        "qualified_predecessor_download_count": 2,
        "copied_source_object_count": 2,
        "checksum_file_sha256": expected_hashes["v3_checksum"],
        "archive_sha256": expected_hashes["v3_archive"],
        "predecessor_input_binding_sha256": expected_hashes["v3_input_binding"],
        "archive_audit_sha256": expected_hashes["v3_archive_audit"],
        "explicit_top_directory_count": 0,
        "implicit_top_directory": True,
        "member_count": 8172,
        "member_census_complete": True,
        "tree_manifest_path": str(v3_log / "installed-tree-manifest.json"),
        "tree_manifest_sha256": expected_hashes["v3_tree_manifest"],
        "tree_entry_count": 8173,
        "install_root": str(install_root),
        "staging_root_absent": True,
        "atomic_publication": "renameat2-RENAME_NOREPLACE",
        "share_tree": "share/cmake-3.31",
        "symlink_count": 0,
        "system_write_count": 0,
    }
    for key, expected in exact.items():
        if value.get(key) != expected:
            raise SystemExit(f"v3 installer result field mismatch {key}")
    required = {
        "cmake_binary": (
            "bin/cmake",
            "0755",
            17241856,
            "d8ed20c9688adaf5ee8d387072424aa732c5f589e860347e0dfa51cca37dc863",
        ),
        "ctest_binary": (
            "bin/ctest",
            "0755",
            18771296,
            "4569f74f29abcc549e2b4bd5a4fdb755c5be4e6794e02ef4fc1d9acb8962bba9",
        ),
        "cpack_binary": (
            "bin/cpack",
            "0755",
            17741632,
            "0fafc5ac96e238601de688982d3efa2a8199cb322e5cc6b1bace3191c0787647",
        ),
        "ccmake_binary": (
            "bin/ccmake",
            "0755",
            17173408,
            "e4e3337dac326a3ed9de58e9cadc55c355ecdb2413e93bfad6423741c65f7834",
        ),
    }
    for key, (path, mode, size, digest) in required.items():
        if value.get(key) != {
            "relative_path": path,
            "mode": mode,
            "size": size,
            "sha256": digest,
        }:
            raise SystemExit(f"v3 installer result required binary mismatch {key}")
    return required

def validate_v3_control_flow(installer_result):
    installer_data, _, _ = stable_bytes(paths["v3_installer"])
    try:
        module = ast.parse(installer_data, filename=str(paths["v3_installer"]))
    except SyntaxError as exc:
        raise SystemExit(f"v3 installer AST parse failed: {exc}") from exc
    main_defs = [
        item
        for item in module.body
        if isinstance(item, (ast.FunctionDef, ast.AsyncFunctionDef))
        and item.name == "main"
    ]
    if len(main_defs) != 1 or not main_defs[0].body:
        raise SystemExit("v3 installer main definition cardinality mismatch")
    final_main = main_defs[0].body[-1]
    if not (
        isinstance(final_main, ast.Return)
        and isinstance(final_main.value, ast.Constant)
        and final_main.value.value == 0
    ):
        raise SystemExit("v3 installer main does not end in return 0")
    if not module.body or not isinstance(module.body[-1], ast.If):
        raise SystemExit("v3 installer __main__ guard is not final")
    guard = module.body[-1]
    if not (
        isinstance(guard.test, ast.Compare)
        and isinstance(guard.test.left, ast.Name)
        and guard.test.left.id == "__name__"
        and len(guard.test.ops) == 1
        and isinstance(guard.test.ops[0], ast.Eq)
        and len(guard.test.comparators) == 1
        and isinstance(guard.test.comparators[0], ast.Constant)
        and guard.test.comparators[0].value == "__main__"
        and len(guard.body) == 1
        and not guard.orelse
        and isinstance(guard.body[0], ast.Try)
    ):
        raise SystemExit("v3 installer __main__ guard topology mismatch")
    wrapper = guard.body[0]
    if len(wrapper.body) != 1 or wrapper.orelse or wrapper.finalbody:
        raise SystemExit("v3 installer wrapper try topology mismatch")
    raise_main = wrapper.body[0]
    if not (
        isinstance(raise_main, ast.Raise)
        and isinstance(raise_main.exc, ast.Call)
        and isinstance(raise_main.exc.func, ast.Name)
        and raise_main.exc.func.id == "SystemExit"
        and len(raise_main.exc.args) == 1
        and isinstance(raise_main.exc.args[0], ast.Call)
        and isinstance(raise_main.exc.args[0].func, ast.Name)
        and raise_main.exc.args[0].func.id == "main"
        and not raise_main.exc.args[0].args
        and not raise_main.exc.args[0].keywords
    ):
        raise SystemExit("v3 installer wrapper does not raise SystemExit(main())")
    if len(wrapper.handlers) != 2:
        raise SystemExit("v3 installer wrapper handler cardinality mismatch")
    handler_names = []
    for handler in wrapper.handlers:
        if not isinstance(handler.type, ast.Name):
            raise SystemExit("v3 installer wrapper handler type mismatch")
        handler_names.append(handler.type.id)
        if not handler.body:
            raise SystemExit("v3 installer wrapper handler body empty")
        final_raise = handler.body[-1]
        if not (
            isinstance(final_raise, ast.Raise)
            and isinstance(final_raise.exc, ast.Call)
            and isinstance(final_raise.exc.func, ast.Name)
            and final_raise.exc.func.id == "SystemExit"
            and len(final_raise.exc.args) == 1
            and isinstance(final_raise.exc.args[0], ast.Constant)
            and final_raise.exc.args[0].value == 1
        ):
            raise SystemExit("v3 installer wrapper handler does not convert to rc1")
    if handler_names != ["InstallFailure", "BaseException"]:
        raise SystemExit("v3 installer wrapper handler ordering mismatch")
    if not issubclass(SystemExit, BaseException) or issubclass(SystemExit, Exception):
        raise SystemExit("Python SystemExit inheritance witness mismatch")

    expected_stdout = (
        "[NPU-QWEN-F32-ALU-CMAKE-TOOL-V3][INSTALLER-PASS] "
        "version=3.31.12 "
        "checksum_file_sha256=159eb3b123ba8c8403a154c9d3389432276bf3bd21b274f0396fe17a6a7a7d9d "
        "archive_sha256=0dc2e9a6860f06bf10bd8fadc03e35d9eeb4df46e33763a7e480e987758f385c "
        "archive_audit_sha256=8e4746dbbd3110a4d26f3e235156e105d5e63b613891f06ff843620801819997 "
        "tree_manifest_sha256=a37e0b13ee2c83ae6b12ca75b424109d038f700757f2cfb7fdf9b3e804383a1f "
        "explicit_top_directory_count=0 implicit_top_directory=1 "
        "network_download_count=0 staging_absent=1\n"
    ).encode()
    expected_stderr = (
        "[NPU-QWEN-F32-ALU-CMAKE-TOOL-V3][INSTALLER-FAIL] "
        "stage=unexpected-exception type=SystemExit reason=0\n"
    ).encode()
    expected_status = (
        b"FAIL rc=1 stage=pinned-reuse-installer evidence_complete=0 cleanup_rc=0\n"
    )
    stdout, _, _ = stable_bytes(paths["v3_installer_stdout"])
    stderr, _, _ = stable_bytes(paths["v3_installer_stderr"])
    rc_data, _, _ = stable_bytes(paths["v3_installer_rc"])
    status_data, _, _ = stable_bytes(paths["v3_run_status"])
    if (
        stdout != expected_stdout
        or stderr != expected_stderr
        or rc_data != b"1\n"
        or status_data != expected_status
    ):
        raise SystemExit("v3 retained false-failure transcript mismatch")
    if installer_result.get("result") != "PASS":
        raise SystemExit("v3 retained installer result no longer proves PASS")
    return {
        "schema_version": 1,
        "task_id": "qwen-f32-alu-cmake-tool-v4",
        "classified_object": "v3 installer __main__ wrapper control flow",
        "v3_task_id": "qwen-f32-alu-cmake-tool-v3",
        "v3_install_result": "PASS",
        "v3_runner_result": "FAIL",
        "v3_runner_failure_class": "false-wrapper-failure-after-successful-install",
        "successful_main_caught_by_baseexception": True,
        "main_returns_zero": True,
        "wrapper_statement": "raise SystemExit(main())",
        "handler_order": handler_names,
        "systemexit_is_baseexception": True,
        "systemexit_is_exception": False,
        "wrapper_raise_lineno": raise_main.lineno,
        "baseexception_handler_lineno": wrapper.handlers[1].lineno,
        "v3_contract_sha256": expected_hashes["v3_contract"],
        "v3_installer_sha256": expected_hashes["v3_installer"],
        "v3_runner_sha256": expected_hashes["v3_runner"],
        "v3_installer_result_sha256": expected_hashes["v3_installer_result"],
        "v3_installer_stdout_sha256": expected_hashes["v3_installer_stdout"],
        "v3_installer_stderr_sha256": expected_hashes["v3_installer_stderr"],
        "v3_run_status_sha256": expected_hashes["v3_run_status"],
        "v3_installer_rc": 1,
        "v3_runner_rc": 1,
        "v3_rerun_count": 0,
        "v4_installer_invocation_count": 0,
    }

def validate_provenance(input_binding):
    if (
        input_binding.get("schema_version") != 1
        or input_binding.get("task_id") != "qwen-f32-alu-cmake-tool-v3"
        or input_binding.get("predecessor_task_id")
        != "qwen-f32-alu-cmake-tool-v2"
        or input_binding.get("release_version") != "3.31.12"
        or input_binding.get("network_download_count") != 0
        or input_binding.get("qualified_predecessor_download_count") != 2
        or input_binding.get("copied_source_object_count") != 2
        or input_binding.get("workspace_local_only") is not True
    ):
        raise SystemExit("v3 source provenance binding header mismatch")
    copies = {
        "checksum_copy": (
            paths["v2_checksum"],
            paths["v3_checksum"],
            expected_hashes["v3_checksum"],
            1663,
        ),
        "archive_copy": (
            paths["v2_archive"],
            paths["v3_archive"],
            expected_hashes["v3_archive"],
            55005786,
        ),
    }
    for key, (source, copied, digest, size) in copies.items():
        value = input_binding.get(key)
        if value != {
            "source_path": str(source),
            "source_size": size,
            "source_sha256": digest,
            "copied_path": str(copied),
            "copied_size": size,
            "copied_sha256": digest,
            "same_bytes": True,
            "exclusive_no_follow_copy": True,
        }:
            raise SystemExit(f"v3 source provenance copy mismatch {key}")
    checksum_audit = input_binding.get("checksum_audit", {})
    if checksum_audit != {
        "archive_entry_count": 1,
        "archive_line": (
            "0dc2e9a6860f06bf10bd8fadc03e35d9eeb4df46e33763a7e480e987758f385c  "
            "cmake-3.31.12-linux-x86_64.tar.gz"
        ),
        "line_count": 17,
        "sha256": expected_hashes["v3_checksum"],
        "size_bytes": 1663,
    }:
        raise SystemExit("v3 checksum provenance audit mismatch")
    predecessor = input_binding.get("predecessor_download_provenance", {})
    if (
        predecessor.get("network_download_count") != 0
        or predecessor.get("qualified_predecessor_download_count") != 2
        or predecessor.get("checksum_download_log", {}).get("sha256")
        != expected_hashes["v2_checksum_download"]
        or predecessor.get("archive_download_log", {}).get("sha256")
        != expected_hashes["v2_archive_download"]
        or predecessor.get("source_provenance", {}).get("sha256")
        != expected_hashes["v2_source_provenance"]
    ):
        raise SystemExit("v3 predecessor download provenance mismatch")

def tree_window(expected_entries, required_bins):
    require_real_directory(install_root)
    entries = []

    def visit(path, relative_path):
        require_parent_chain_real(path)
        observed = path.lstat()
        mode = stat.S_IMODE(observed.st_mode)
        if stat.S_ISLNK(observed.st_mode):
            raise SystemExit("installed tree contains symlink: " + str(path))
        if stat.S_ISDIR(observed.st_mode):
            descriptor = os.open(
                path,
                os.O_RDONLY
                | getattr(os, "O_DIRECTORY", 0)
                | getattr(os, "O_CLOEXEC", 0)
                | getattr(os, "O_NOFOLLOW", 0),
            )
            try:
                before = os.fstat(descriptor)
                if not stat.S_ISDIR(before.st_mode):
                    raise SystemExit("installed directory changed kind: " + str(path))
                names = sorted(os.listdir(descriptor))
                entries.append(
                    {
                        "path": relative_path,
                        "kind": "directory",
                        "mode": f"{mode:04o}",
                        "size": 0,
                    }
                )
                for name in names:
                    canonical_relative(name)
                    child_relative = (
                        name
                        if relative_path == "."
                        else f"{relative_path}/{name}"
                    )
                    visit(path / name, child_relative)
                after = os.fstat(descriptor)
            finally:
                os.close(descriptor)
            if stat_signature(before) != stat_signature(after):
                raise SystemExit(
                    "installed directory changed during deterministic walk: "
                    + str(path)
                )
            return
        if stat.S_ISREG(observed.st_mode):
            _, opened, digest = stable_regular(path)
            if (observed.st_dev, observed.st_ino) != (
                opened.st_dev,
                opened.st_ino,
            ):
                raise SystemExit(
                    "installed regular identity changed before no-follow read: "
                    + str(path)
                )
            entries.append(
                {
                    "path": relative_path,
                    "kind": "regular",
                    "mode": f"{mode:04o}",
                    "size": opened.st_size,
                    "sha256": digest,
                }
            )
            return
        raise SystemExit("installed tree contains special object: " + str(path))

    visit(install_root, ".")
    if entries != expected_entries:
        raise SystemExit(
            "installed tree differs from frozen 8173-entry manifest in " + phase
        )
    if len(entries) != 8173:
        raise SystemExit("installed tree entry count mismatch")
    required_paths = {}
    for key, (relative_path, expected_mode, expected_size, expected_digest) in required_bins.items():
        matches = [
            item
            for item in entries
            if item["path"] == relative_path and item["kind"] == "regular"
        ]
        if len(matches) != 1:
            raise SystemExit(f"required executable cardinality mismatch {relative_path}")
        record = matches[0]
        if (
            record["mode"] != expected_mode
            or record["size"] != expected_size
            or record["sha256"] != expected_digest
            or int(record["mode"], 8) & 0o111 == 0
        ):
            raise SystemExit(f"required executable identity mismatch {relative_path}")
        required_paths[key] = record
    share_matches = [
        item
        for item in entries
        if item["path"] == "share/cmake-3.31" and item["kind"] == "directory"
    ]
    if len(share_matches) != 1:
        raise SystemExit("share/cmake-3.31 real-directory cardinality mismatch")
    canonical = json.dumps(
        entries, sort_keys=True, separators=(",", ":")
    ).encode()
    root_stat = install_root.lstat()
    return {
        "schema_version": 1,
        "task_id": "qwen-f32-alu-cmake-tool-v4",
        "result": "PASS",
        "audit_window": phase,
        "install_root": str(install_root),
        "install_root_real_directory": True,
        "install_root_stat": stat_json(root_stat),
        "manifest_path": relative(paths["v3_tree_manifest"]),
        "manifest_sha256": expected_hashes["v3_tree_manifest"],
        "entry_count": len(entries),
        "regular_file_count": sum(item["kind"] == "regular" for item in entries),
        "directory_count": sum(item["kind"] == "directory" for item in entries),
        "symlink_count": 0,
        "special_count": 0,
        "missing_count": 0,
        "extra_count": 0,
        "duplicate_count": 0,
        "entry_equality": True,
        "observed_entries_sha256": hashlib.sha256(canonical).hexdigest(),
        "required_executables": required_paths,
        "required_share_directory": share_matches[0],
        "tree_write_count": 0,
        "walk_invocation_count": 1,
    }

frozen_records = validate_frozen()
if not path_absent(staging_root):
    raise SystemExit("v3 staging root is present")
require_real_directory(v3_log)
require_real_directory(install_root)

archive_audit, _, archive_audit_sha = load_json(paths["v3_archive_audit"])
manifest, _, manifest_sha = load_json(paths["v3_tree_manifest"])
installer_result, _, installer_result_sha = load_json(paths["v3_installer_result"])
input_binding, _, input_binding_sha = load_json(paths["v3_input_binding"])
process_cleanup, _, _ = load_json(paths["v3_process_cleanup"])

if (
    archive_audit_sha != expected_hashes["v3_archive_audit"]
    or manifest_sha != expected_hashes["v3_tree_manifest"]
    or installer_result_sha != expected_hashes["v3_installer_result"]
    or input_binding_sha != expected_hashes["v3_input_binding"]
):
    raise SystemExit("v3 core JSON identity mismatch")

validate_archive_audit(archive_audit)
expected_entries = validate_manifest(manifest)
required_bins = validate_installer_result(installer_result)
validate_provenance(input_binding)
classification = validate_v3_control_flow(installer_result)
if process_cleanup != {
    "schema_version": 1,
    "task_id": "qwen-f32-alu-cmake-tool-v3",
    "bash_job_count": 0,
    "owned_process_count": 0,
    "owned_processes": [],
    "cleanup_rc": 0,
}:
    raise SystemExit("v3 process cleanup receipt mismatch")

tree_audit = tree_window(expected_entries, required_bins)
provenance = {
    "schema_version": 1,
    "task_id": "qwen-f32-alu-cmake-tool-v4",
    "result": "PASS",
    "qualification_window": phase,
    "release_version": "3.31.12",
    "origin": "official Kitware archive retained by v2 and atomically published by v3",
    "v2_qualified_download_count": 2,
    "v3_network_download_count": 0,
    "v4_network_download_count": 0,
    "v3_install_result": "PASS",
    "v3_runner_result": "FAIL-control-flow",
    "v3_archive_sha256": expected_hashes["v3_archive"],
    "v3_archive_audit_sha256": expected_hashes["v3_archive_audit"],
    "v3_tree_manifest_sha256": expected_hashes["v3_tree_manifest"],
    "v3_installer_result_sha256": expected_hashes["v3_installer_result"],
    "v3_input_binding_sha256": expected_hashes["v3_input_binding"],
    "frozen_artifact_count": len(frozen_records),
    "frozen_artifacts": frozen_records,
}

classification_path = log_root / "v3-false-systemexit-classification.json"
provenance_path = log_root / "v3-source-provenance-binding.json"
pre_audit_path = log_root / "installed-tree-audit.pre.json"
post_audit_path = log_root / "installed-tree-audit.post.json"

if phase == "pre":
    publish_json(classification_path, classification)
    publish_json(provenance_path, provenance)
    publish_json(pre_audit_path, tree_audit)
    raise SystemExit(0)

classification_retained, _, classification_sha = load_json(classification_path)
provenance_retained, _, provenance_sha = load_json(provenance_path)
pre_audit, _, pre_audit_sha = load_json(pre_audit_path)
if (
    classification_retained != classification
    or classification_retained.get("successful_main_caught_by_baseexception")
    is not True
):
    raise SystemExit("retained v3 false-SystemExit classification drift")
if (
    provenance_retained.get("v3_installer_result_sha256")
    != expected_hashes["v3_installer_result"]
    or provenance_retained.get("v3_tree_manifest_sha256")
    != expected_hashes["v3_tree_manifest"]
):
    raise SystemExit("retained v3 provenance binding drift")
if (
    pre_audit.get("entry_count") != 8173
    or pre_audit.get("entry_equality") is not True
    or pre_audit.get("observed_entries_sha256")
    != tree_audit["observed_entries_sha256"]
    or pre_audit.get("install_root_stat") != tree_audit["install_root_stat"]
):
    raise SystemExit("pre/post installed-tree audit mismatch")

expected_task_test = (
    b"[task-run-status-test] PASS explicit completion, early exit, command failure, "
    b"cleanup failure, PASS-write fallback, and HUP/INT/TERM\n"
)
task_stdout, _, _ = stable_bytes(log_root / "task-run-status-test.stdout.log")
task_stderr, _, _ = stable_bytes(log_root / "task-run-status-test.stderr.log")
task_rc, _, _ = stable_bytes(log_root / "task-run-status-test.rc")
if task_stdout != expected_task_test or task_stderr != b"" or task_rc != b"0\n":
    raise SystemExit("v4 status-helper directed test transcript mismatch")

expected_version_stdout = (
    b"cmake version 3.31.12\n\n"
    b"CMake suite maintained and supported by Kitware (kitware.com/cmake).\n"
)
version_stdout, _, version_stdout_sha = stable_bytes(
    log_root / "cmake-version.stdout.log"
)
version_stderr, _, version_stderr_sha = stable_bytes(
    log_root / "cmake-version.stderr.log"
)
version_rc, _, version_rc_sha = stable_bytes(log_root / "cmake-version.rc")
if (
    version_stdout != expected_version_stdout
    or version_stderr != b""
    or version_rc != b"0\n"
):
    raise SystemExit("unique CMake version smoke transcript mismatch")
binary_data, binary_stat, binary_sha = stable_bytes(cmake_bin)
if (
    binary_sha
    != "d8ed20c9688adaf5ee8d387072424aa732c5f589e860347e0dfa51cca37dc863"
    or len(binary_data) != 17241856
    or stat.S_IMODE(binary_stat.st_mode) != 0o755
    or not stat.S_ISREG(binary_stat.st_mode)
):
    raise SystemExit("qualified CMake executable identity mismatch")

action_counts, _, _ = load_json(log_root / "action-counts.json")
process_audit, _, _ = load_json(log_root / "process-cleanup.json")
parent_pre, _, _ = load_json(log_root / "parent-membership.pre.json")
parent_post, _, _ = load_json(log_root / "parent-membership.post.json")

zero_actions = (
    "network_download_count",
    "installer_invocations",
    "archive_extract_count",
    "install_publication_count",
    "installed_tree_write_count",
    "cmake_configure",
    "cmake_build",
    "verilator",
    "make",
    "rtl_build",
    "binary_runs",
    "model_runs",
    "qwen_runs",
    "synthesis",
    "sta",
    "ppa",
    "system_writes",
    "path_mutation_count",
    "v3_installer_reruns",
    "v3_runner_reruns",
)
if any(action_counts.get(name) != 0 for name in zero_actions):
    raise SystemExit("forbidden v4 action count is nonzero")
required_actions = {
    "bash_n": 1,
    "bash_n_rc": 0,
    "runner_invocations": 1,
    "task_status_test": 1,
    "cmake_version_smoke": 1,
    "cmake_invocation_total": 1,
    "tree_rehash_windows": 2,
    "tree_entry_rehash_count": 16346,
    "cleanup_rc": 0,
}
if any(action_counts.get(name) != value for name, value in required_actions.items()):
    raise SystemExit("required v4 unique action count mismatch")
if process_audit != {
    "schema_version": 1,
    "task_id": "qwen-f32-alu-cmake-tool-v4",
    "bash_job_count": 0,
    "owned_process_count": 0,
    "owned_processes": [],
    "cleanup_rc": 0,
}:
    raise SystemExit("v4 process cleanup receipt mismatch")
if [item["present"] for item in parent_pre.get("paths", [])] != [
    False,
    False,
    True,
]:
    raise SystemExit("v4 pre parent membership mismatch")
if [
    (item["present"], item["kind"]) for item in parent_post.get("paths", [])
] != [(True, "directory"), (False, "absent"), (True, "directory")]:
    raise SystemExit("v4 post parent membership mismatch")
if (
    parent_pre["paths"][2].get("stat")
    != parent_post["paths"][2].get("stat")
    or parent_pre["paths"][2].get("stat") != tree_audit["install_root_stat"]
):
    raise SystemExit("installed root parent identity changed across v4")

post_audit_data = publish_json(post_audit_path, tree_audit)
post_audit_sha = hashlib.sha256(post_audit_data).hexdigest()
identity = {
    "schema_version": 1,
    "task_id": "qwen-f32-alu-cmake-tool-v4",
    "absolute_path": str(cmake_bin),
    "relative_path": relative(cmake_bin),
    "kind": "regular",
    "mode": "0755",
    "size": len(binary_data),
    "sha256": binary_sha,
    "argv": [str(cmake_bin), "--version"],
    "invocation_count": 1,
    "rc": 0,
    "stdout_exact": True,
    "stdout_sha256": version_stdout_sha,
    "stderr_sha256": version_stderr_sha,
    "rc_file_sha256": version_rc_sha,
    "first_line": "cmake version 3.31.12",
    "persistent_path_modified": False,
}
identity_path = log_root / "cmake-identity.json"
identity_data = publish_json(identity_path, identity)
identity_sha = hashlib.sha256(identity_data).hexdigest()

runner_path = root / "npu/version_0820/scripts/run-qwen-f32-alu-cmake-tool-v4.sh"
_, _, runner_sha = stable_regular(runner_path)
receipt = {
    "schema_version": 1,
    "task_id": "qwen-f32-alu-cmake-tool-v4",
    "result": "PASS",
    "qualified_scope": "absolute workspace-local CMake 3.31.12 executable only",
    "future_compile_identity_only": True,
    "release_version": "3.31.12",
    "contract_sha256": expected_hashes["v4_contract"],
    "runner_sha256": runner_sha,
    "v3_contract_sha256": expected_hashes["v3_contract"],
    "v3_installer_sha256": expected_hashes["v3_installer"],
    "v3_runner_sha256": expected_hashes["v3_runner"],
    "v3_archive_sha256": expected_hashes["v3_archive"],
    "v3_archive_audit_sha256": expected_hashes["v3_archive_audit"],
    "v3_tree_manifest_sha256": expected_hashes["v3_tree_manifest"],
    "v3_installer_result_sha256": expected_hashes["v3_installer_result"],
    "v3_run_status_sha256": expected_hashes["v3_run_status"],
    "v3_installer_stderr_sha256": expected_hashes["v3_installer_stderr"],
    "successful_main_caught_by_baseexception": True,
    "v3_install_result": "PASS",
    "v3_runner_result": "FAIL-control-flow",
    "tree_rehash_windows": 2,
    "tree_entry_count_per_window": 8173,
    "pre_tree_audit_sha256": pre_audit_sha,
    "post_tree_audit_sha256": post_audit_sha,
    "tree_entries_sha256": tree_audit["observed_entries_sha256"],
    "installed_cmake_path": relative(cmake_bin),
    "installed_cmake_sha256": binary_sha,
    "installed_cmake_size": len(binary_data),
    "cmake_identity_sha256": identity_sha,
    "cmake_version_first_line": "cmake version 3.31.12",
    "cmake_version_stdout_exact": True,
    "action_counts": action_counts,
    "process_cleanup": process_audit,
    "network_download_count": 0,
    "installer_invocation_count": 0,
    "archive_extract_count": 0,
    "install_publication_count": 0,
    "installed_tree_write_count": 0,
    "cmake_configure_count": 0,
    "cmake_build_count": 0,
    "rtl_build_count": 0,
    "binary_run_count": 0,
    "model_run_count": 0,
    "qwen_run_count": 0,
    "synthesis_count": 0,
    "sta_count": 0,
    "ppa_count": 0,
    "status_expected": "PASS",
    "terminal_marker_expected": (
        "[NPU-QWEN-F32-ALU-CMAKE-TOOL-V4][PASS] version=3.31.12"
    ),
    "compile_performed": False,
    "rtl_dynamic_qualification": "GAP",
    "strict_backend": "GAP",
    "canonical_coverage": "GAP",
    "parent_qwen_shell_goal": "GAP",
}
receipt_path = log_root / "receipt.json"
receipt_data = publish_json(receipt_path, receipt)
receipt_sha = hashlib.sha256(receipt_data).hexdigest()

expected_status_path = log_root / "expected.status"
expected_status_payload = b"PASS\n"
try:
    expected_status_path.lstat()
except FileNotFoundError:
    pass
else:
    raise SystemExit("expected status destination already exists")
temporary = expected_status_path.parent / (
    f".{expected_status_path.name}.tmp.{os.getpid()}"
)
descriptor = os.open(
    temporary,
    os.O_WRONLY | os.O_CREAT | os.O_EXCL | getattr(os, "O_NOFOLLOW", 0),
    0o600,
)
try:
    os.write(descriptor, expected_status_payload)
    os.fsync(descriptor)
finally:
    os.close(descriptor)
try:
    os.link(temporary, expected_status_path, follow_symlinks=False)
finally:
    temporary.unlink(missing_ok=True)
directory_fd = os.open(
    expected_status_path.parent,
    os.O_RDONLY | getattr(os, "O_DIRECTORY", 0),
)
try:
    os.fsync(directory_fd)
finally:
    os.close(directory_fd)
expected_status_sha = hashlib.sha256(expected_status_payload).hexdigest()

evidence_roles = {
    "v3-false-systemexit-classification.json": "v3-false-SystemExit-classification",
    "v3-source-provenance-binding.json": "v3-source-provenance-binding",
    "installed-tree-audit.pre.json": "first-8173-entry-tree-rehash",
    "installed-tree-audit.post.json": "second-8173-entry-tree-rehash",
    "parent-membership.pre.json": "pre-parent-membership",
    "parent-membership.post.json": "post-parent-membership",
    "task-run-status-test.stdout.log": "status-test-stdout",
    "task-run-status-test.stderr.log": "status-test-stderr",
    "task-run-status-test.rc": "status-test-rc",
    "cmake-version.stdout.log": "unique-version-smoke-stdout",
    "cmake-version.stderr.log": "unique-version-smoke-stderr",
    "cmake-version.rc": "unique-version-smoke-rc",
    "cmake-identity.json": "qualified-cmake-identity",
    "action-counts.json": "unique-and-zero-action-counts",
    "process-cleanup.json": "process-cleanup",
}
artifacts = list(frozen_records)
artifacts.append(artifact(runner_path, "v4-runner-source"))
for name, role in sorted(evidence_roles.items()):
    artifacts.append(artifact(log_root / name, role))
artifacts.append(artifact(cmake_bin, "qualified-cmake-executable"))
artifacts.append(artifact(receipt_path, "receipt"))
artifacts.append(artifact(expected_status_path, "expected-final-status"))
artifacts.sort(key=lambda item: item["path"])
artifact_paths = [item["path"] for item in artifacts]
if len(artifact_paths) != len(set(artifact_paths)):
    raise SystemExit("bound artifact manifest contains duplicate path")
bound = {
    "schema_version": 1,
    "task_id": "qwen-f32-alu-cmake-tool-v4",
    "receipt_sha256": receipt_sha,
    "artifact_count": len(artifacts),
    "artifacts": artifacts,
}
bound_path = log_root / "bound-artifacts.json"
bound_data = publish_json(bound_path, bound)
bound_sha = hashlib.sha256(bound_data).hexdigest()

binding = {
    "schema_version": 1,
    "task_id": "qwen-f32-alu-cmake-tool-v4",
    "result": "PASS",
    "receipt_path": relative(receipt_path),
    "receipt_sha256": receipt_sha,
    "bound_artifacts_path": relative(bound_path),
    "bound_artifacts_sha256": bound_sha,
    "false_systemexit_path": relative(classification_path),
    "false_systemexit_sha256": classification_sha,
    "provenance_path": relative(provenance_path),
    "provenance_sha256": provenance_sha,
    "pre_tree_audit_path": relative(pre_audit_path),
    "pre_tree_audit_sha256": pre_audit_sha,
    "post_tree_audit_path": relative(post_audit_path),
    "post_tree_audit_sha256": post_audit_sha,
    "tree_entries_sha256": tree_audit["observed_entries_sha256"],
    "cmake_identity_path": relative(identity_path),
    "cmake_identity_sha256": identity_sha,
    "installed_cmake_path": relative(cmake_bin),
    "installed_cmake_sha256": binary_sha,
    "expected_status_path": relative(expected_status_path),
    "expected_status_sha256": expected_status_sha,
    "status_path": relative(log_root / "run.status"),
    "status_publication_must_follow_binding": True,
    "pass_marker_is_final_successful_action": True,
}
binding_path = log_root / "final-binding.json"
binding_data = publish_json(binding_path, binding)
binding_sha = hashlib.sha256(binding_data).hexdigest()
print(
    receipt_sha,
    bound_sha,
    binding_sha,
    classification_sha,
    provenance_sha,
    pre_audit_sha,
    post_audit_sha,
    identity_sha,
    binary_sha,
    tree_audit["observed_entries_sha256"],
)
PY
}

late_revalidate() {
    local phase="${1:?phase is required}"
    local receipt_sha="${2:?receipt sha is required}"
    local manifest_sha="${3:?manifest sha is required}"
    local binding_sha="${4:?binding sha is required}"
    local classification_sha="${5:?classification sha is required}"
    local provenance_sha="${6:?provenance sha is required}"
    local pre_audit_sha="${7:?pre audit sha is required}"
    local post_audit_sha="${8:?post audit sha is required}"
    local identity_sha="${9:?identity sha is required}"
    shift 9
    local binary_sha="${1:?binary sha is required}"
    local entries_sha="${2:?entries sha is required}"
    python3 - "$REPO_ROOT" "$LOG_ROOT" "$INSTALL_ROOT" "$V3_STAGING_ROOT" \
        "$phase" "$receipt_sha" "$manifest_sha" "$binding_sha" \
        "$classification_sha" "$provenance_sha" "$pre_audit_sha" \
        "$post_audit_sha" "$identity_sha" "$binary_sha" "$entries_sha" <<'PY'
import hashlib
import json
import os
import pathlib
import stat
import sys

root = pathlib.Path(sys.argv[1]).resolve(strict=True)
log_root = pathlib.Path(sys.argv[2])
install_root = pathlib.Path(sys.argv[3])
staging_root = pathlib.Path(sys.argv[4])
phase = sys.argv[5]
expected = sys.argv[6:16]

def absent(path):
    try:
        path.lstat()
    except FileNotFoundError:
        return True
    return False

def stable(path):
    descriptor = os.open(
        path,
        os.O_RDONLY | getattr(os, "O_CLOEXEC", 0) | getattr(os, "O_NOFOLLOW", 0),
    )
    digest = hashlib.sha256()
    chunks = []
    try:
        before = os.fstat(descriptor)
        if not stat.S_ISREG(before.st_mode):
            raise SystemExit("late bound object is not regular: " + str(path))
        while True:
            chunk = os.read(descriptor, 1024 * 1024)
            if not chunk:
                break
            chunks.append(chunk)
            digest.update(chunk)
        after = os.fstat(descriptor)
    finally:
        os.close(descriptor)
    data = b"".join(chunks)
    signature_before = (
        before.st_dev,
        before.st_ino,
        before.st_mode,
        before.st_size,
        before.st_mtime_ns,
        before.st_ctime_ns,
    )
    signature_after = (
        after.st_dev,
        after.st_ino,
        after.st_mode,
        after.st_size,
        after.st_mtime_ns,
        after.st_ctime_ns,
    )
    if signature_before != signature_after or len(data) != before.st_size:
        raise SystemExit("late bound object changed during read: " + str(path))
    return data, digest.hexdigest()

def load(path):
    data, digest = stable(path)
    return json.loads(data), digest

receipt, receipt_sha = load(log_root / "receipt.json")
manifest, manifest_sha = load(log_root / "bound-artifacts.json")
binding, binding_sha = load(log_root / "final-binding.json")
classification, classification_sha = load(
    log_root / "v3-false-systemexit-classification.json"
)
provenance, provenance_sha = load(
    log_root / "v3-source-provenance-binding.json"
)
pre_audit, pre_audit_sha = load(log_root / "installed-tree-audit.pre.json")
post_audit, post_audit_sha = load(log_root / "installed-tree-audit.post.json")
identity, identity_sha = load(log_root / "cmake-identity.json")
observed = [
    receipt_sha,
    manifest_sha,
    binding_sha,
    classification_sha,
    provenance_sha,
    pre_audit_sha,
    post_audit_sha,
    identity_sha,
    receipt.get("installed_cmake_sha256"),
    pre_audit.get("observed_entries_sha256"),
]
if observed != expected:
    raise SystemExit("late final-document hash drift")
if (
    manifest.get("receipt_sha256") != receipt_sha
    or binding.get("receipt_sha256") != receipt_sha
    or binding.get("bound_artifacts_sha256") != manifest_sha
):
    raise SystemExit("late receipt/manifest/binding relationship drift")
if (
    binding.get("false_systemexit_sha256") != classification_sha
    or binding.get("provenance_sha256") != provenance_sha
    or binding.get("pre_tree_audit_sha256") != pre_audit_sha
    or binding.get("post_tree_audit_sha256") != post_audit_sha
    or binding.get("cmake_identity_sha256") != identity_sha
):
    raise SystemExit("late qualification sub-binding drift")

artifact_paths = []
for record in manifest.get("artifacts", []):
    path = root / record["path"]
    data, digest = stable(path)
    if len(data) != record["size"] or digest != record["sha256"]:
        raise SystemExit("late bound artifact drift: " + record["path"])
    artifact_paths.append(record["path"])
if (
    manifest.get("artifact_count") != len(artifact_paths)
    or artifact_paths != sorted(artifact_paths)
    or len(artifact_paths) != len(set(artifact_paths))
):
    raise SystemExit("late bound artifact membership/order drift")

if (
    classification.get("successful_main_caught_by_baseexception") is not True
    or classification.get("v3_install_result") != "PASS"
    or classification.get("v3_runner_result") != "FAIL"
):
    raise SystemExit("late v3 false-SystemExit classification drift")
if (
    provenance.get("v3_archive_sha256")
    != "0dc2e9a6860f06bf10bd8fadc03e35d9eeb4df46e33763a7e480e987758f385c"
    or provenance.get("v3_tree_manifest_sha256")
    != "a37e0b13ee2c83ae6b12ca75b424109d038f700757f2cfb7fdf9b3e804383a1f"
    or provenance.get("v3_installer_result_sha256")
    != "e640cda8b6310be33b396a44de0a863ba5a3386a5b94dfd074321b2e23af53a8"
):
    raise SystemExit("late v3 provenance drift")
if (
    pre_audit.get("entry_count") != 8173
    or post_audit.get("entry_count") != 8173
    or pre_audit.get("entry_equality") is not True
    or post_audit.get("entry_equality") is not True
    or pre_audit.get("observed_entries_sha256")
    != post_audit.get("observed_entries_sha256")
    or pre_audit.get("install_root_stat") != post_audit.get("install_root_stat")
):
    raise SystemExit("late two-window tree audit drift")
if (
    identity.get("absolute_path") != str(install_root / "bin/cmake")
    or identity.get("sha256")
    != "d8ed20c9688adaf5ee8d387072424aa732c5f589e860347e0dfa51cca37dc863"
    or identity.get("size") != 17241856
    or identity.get("first_line") != "cmake version 3.31.12"
    or identity.get("invocation_count") != 1
    or identity.get("rc") != 0
    or identity.get("stdout_exact") is not True
):
    raise SystemExit("late CMake identity drift")
if (
    receipt.get("result") != "PASS"
    or receipt.get("tree_rehash_windows") != 2
    or receipt.get("tree_entry_count_per_window") != 8173
    or receipt.get("successful_main_caught_by_baseexception") is not True
    or receipt.get("network_download_count") != 0
    or receipt.get("installer_invocation_count") != 0
    or receipt.get("archive_extract_count") != 0
    or receipt.get("install_publication_count") != 0
    or receipt.get("installed_tree_write_count") != 0
    or receipt.get("cmake_configure_count") != 0
    or receipt.get("cmake_build_count") != 0
    or receipt.get("rtl_build_count") != 0
    or receipt.get("binary_run_count") != 0
    or receipt.get("model_run_count") != 0
    or receipt.get("qwen_run_count") != 0
    or receipt.get("synthesis_count") != 0
    or receipt.get("sta_count") != 0
    or receipt.get("ppa_count") != 0
):
    raise SystemExit("late receipt acceptance fields drift")

if not absent(staging_root):
    raise SystemExit("late v3 staging root is present")
root_stat = install_root.lstat()
if not stat.S_ISDIR(root_stat.st_mode) or stat.S_ISLNK(root_stat.st_mode):
    raise SystemExit("late installed root is not a real directory")
for path in log_root.rglob("*"):
    if path.name == "__pycache__" or path.suffix == ".pyc":
        raise SystemExit("Python cache residue found: " + str(path))
for path in log_root.iterdir():
    if path.name.startswith(".") and ".tmp." in path.name:
        raise SystemExit("atomic temporary evidence residue found: " + str(path))

status_data, status_sha = stable(log_root / "run.status")
expected_status_data, expected_status_sha = stable(log_root / "expected.status")
if (
    expected_status_data != b"PASS\n"
    or binding.get("expected_status_sha256") != expected_status_sha
):
    raise SystemExit("late expected status drift")
if phase == "before-status":
    if status_data != b"RUNNING\n":
        raise SystemExit("PASS status became visible before binding completion")
elif phase == "after-status":
    if status_data != expected_status_data:
        raise SystemExit("final PASS status mismatch")
else:
    raise SystemExit("unknown late revalidation phase")
print(status_sha)
PY
}

run_once() {
    [[ $# -eq 0 ]] || fail "usage: bash $RUNNER_REL"
    [[ "${QWEN_F32_CMAKE_V4_BASH_N_COUNT:-}" == "1" ]] ||
        fail "external unique v4 bash-n count assertion must equal 1"
    [[ "${QWEN_F32_CMAKE_V4_BASH_N_RC:-}" == "0" ]] ||
        fail "external unique v4 bash-n rc assertion must equal 0"

    path_absent "$LOG_ROOT" || fail "fresh v4 log root already exists=$LOG_ROOT"
    path_absent "$V3_STAGING_ROOT" ||
        fail "v3 staging root must remain absent=$V3_STAGING_ROOT"
    [[ -d "$INSTALL_ROOT" && ! -L "$INSTALL_ROOT" ]] ||
        fail "installed CMake tree is missing/aliased=$INSTALL_ROOT"
    [[ -d "$TOOLS_ROOT" && ! -L "$TOOLS_ROOT" ]] ||
        fail "tools parent is missing/aliased=$TOOLS_ROOT"

    local pre_membership
    pre_membership=$(capture_parent_membership)
    mkdir -m 700 -- "$LOG_ROOT"
    publish_text_no_replace "$PARENT_PRE" "$pre_membership"$'\n'

    task_run_status_init "$STATUS_PATH"
    STATUS_INITIALIZED=1
    install_runner_traps

    export TMPDIR="$RUNTIME_TMP"
    export HOME="$LOCAL_HOME"
    export XDG_CACHE_HOME="$LOCAL_CACHE"
    mkdir -m 700 -- "$RUNTIME_TMP"

    task_run_status_stage "frozen-v3-and-pre-tree-qualification"
    require_exact_hash "$CONTRACT" "$CONTRACT_SHA256"
    require_exact_hash "$MATERIAL" "$MATERIAL_SHA256"
    require_exact_hash "$STATUS_HELPER" "$STATUS_HELPER_SHA256"
    require_exact_hash "$STATUS_HELPER_TEST" "$STATUS_HELPER_TEST_SHA256"
    require_exact_hash "$V3_CONTRACT" "$V3_CONTRACT_SHA256"
    require_exact_hash "$V3_MATERIAL" "$V3_MATERIAL_SHA256"
    require_exact_hash "$V3_INSTALLER" "$V3_INSTALLER_SHA256"
    require_exact_hash "$V3_RUNNER" "$V3_RUNNER_SHA256"
    require_exact_hash "$V3_LOG_ROOT/archive-audit.json" "$V3_ARCHIVE_AUDIT_SHA256"
    require_exact_hash "$V3_LOG_ROOT/installed-tree-manifest.json" "$V3_TREE_MANIFEST_SHA256"
    require_exact_hash "$V3_LOG_ROOT/installer-result.json" "$V3_INSTALLER_RESULT_SHA256"
    require_exact_hash "$V3_LOG_ROOT/run.status" "$V3_RUN_STATUS_SHA256"
    require_exact_hash "$V3_LOG_ROOT/installer.stdout.log" "$V3_INSTALLER_STDOUT_SHA256"
    require_exact_hash "$V3_LOG_ROOT/installer.stderr.log" "$V3_INSTALLER_STDERR_SHA256"
    require_file "$RUNNER"
    qualification_window pre

    task_run_status_stage "task-status-directed-test"
    local task_test_rc=0
    set +e
    run_with_exclusive_logs \
        "$TASK_STATUS_TEST_STDOUT" "$TASK_STATUS_TEST_STDERR" \
        bash "$STATUS_HELPER_TEST"
    task_test_rc=$?
    set -e
    publish_text_no_replace "$TASK_STATUS_TEST_RC" "$task_test_rc"$'\n'
    [[ $task_test_rc -eq 0 ]] ||
        fail_rc "$task_test_rc" "task-status directed test failed rc=$task_test_rc"
    [[ ! -s "$TASK_STATUS_TEST_STDERR" ]] ||
        fail "task-status directed test emitted stderr"
    [[ "$(read_first_line "$TASK_STATUS_TEST_STDOUT")" == \
        "[task-run-status-test] PASS explicit completion, early exit, command failure, cleanup failure, PASS-write fallback, and HUP/INT/TERM" ]] ||
        fail "task-status directed-test marker mismatch"

    task_run_status_stage "unique-cmake-version-smoke"
    local version_rc=0
    set +e
    run_with_exclusive_logs \
        "$VERSION_STDOUT" "$VERSION_STDERR" "$CMAKE_BIN" --version
    version_rc=$?
    set -e
    publish_text_no_replace "$VERSION_RC" "$version_rc"$'\n'
    [[ $version_rc -eq 0 ]] ||
        fail_rc "$version_rc" "cmake --version failed rc=$version_rc"
    [[ ! -s "$VERSION_STDERR" ]] ||
        fail "cmake --version emitted unexpected stderr"
    [[ "$(read_first_line "$VERSION_STDOUT")" == "cmake version 3.31.12" ]] ||
        fail "cmake --version first line mismatch"
    [[ "$PATH" == "$PATH_SNAPSHOT" ]] ||
        fail "runner modified process PATH"

    task_run_status_stage "zero-action-and-cleanup"
    publish_text_no_replace "$ACTION_COUNTS" \
        '{"archive_extract_count":0,"bash_n":1,"bash_n_rc":0,"binary_runs":0,"cleanup_rc":0,"cmake_build":0,"cmake_configure":0,"cmake_invocation_total":1,"cmake_version_smoke":1,"install_publication_count":0,"installed_tree_write_count":0,"installer_invocations":0,"make":0,"model_runs":0,"network_download_count":0,"path_mutation_count":0,"ppa":0,"qwen_runs":0,"rtl_build":0,"runner_invocations":1,"schema_version":1,"sta":0,"synthesis":0,"system_writes":0,"task_id":"qwen-f32-alu-cmake-tool-v4","task_status_test":1,"tree_entry_rehash_count":16346,"tree_rehash_windows":2,"v3_installer_reruns":0,"v3_runner_reruns":0,"verilator":0}'$'\n'
    path_absent "$LOCAL_HOME" || {
        FORCED_CLEANUP_RC=91
        fail "workspace-local HOME unexpectedly materialized"
    }
    path_absent "$LOCAL_CACHE" || {
        FORCED_CLEANUP_RC=92
        fail "workspace-local cache unexpectedly materialized"
    }
    if ! rmdir -- "$RUNTIME_TMP"; then
        FORCED_CLEANUP_RC=93
        fail "workspace-local runtime tmp is not empty/removable"
    fi
    path_absent "$RUNTIME_TMP" || {
        FORCED_CLEANUP_RC=94
        fail "workspace-local runtime tmp remains"
    }
    path_absent "$V3_STAGING_ROOT" || {
        FORCED_CLEANUP_RC=95
        fail "v3 staging root appeared"
    }
    local owned_jobs
    owned_jobs=$(jobs -pr)
    [[ -z "$owned_jobs" ]] || {
        FORCED_CLEANUP_RC=96
        fail "owned background Bash jobs remain"
    }
    write_process_audit 0
    local post_membership
    post_membership=$(capture_parent_membership)
    publish_text_no_replace "$PARENT_POST" "$post_membership"$'\n'

    task_run_status_stage "post-tree-rehash-and-receipt-binding"
    local seal_result receipt_sha manifest_sha binding_sha classification_sha
    local provenance_sha pre_audit_sha post_audit_sha identity_sha binary_sha
    local entries_sha
    seal_result=$(qualification_window post)
    read -r receipt_sha manifest_sha binding_sha classification_sha \
        provenance_sha pre_audit_sha post_audit_sha identity_sha binary_sha \
        entries_sha <<<"$seal_result"
    for value in \
        "$receipt_sha" "$manifest_sha" "$binding_sha" "$classification_sha" \
        "$provenance_sha" "$pre_audit_sha" "$post_audit_sha" \
        "$identity_sha" "$binary_sha" "$entries_sha"; do
        [[ "$value" =~ ^[0-9a-f]{64}$ ]] || fail "invalid seal hash=$value"
    done
    [[ "$binary_sha" == "$CMAKE_SHA256" ]] ||
        fail "sealed cmake hash mismatch"

    task_run_status_stage "late-revalidation-before-status"
    late_revalidate before-status \
        "$receipt_sha" "$manifest_sha" "$binding_sha" "$classification_sha" \
        "$provenance_sha" "$pre_audit_sha" "$post_audit_sha" \
        "$identity_sha" "$binary_sha" "$entries_sha" >/dev/null

    task_run_status_stage "status-publication"
    task_run_status_mark_evidence_complete
    task_run_status_finalize 0 0

    task_run_status_stage "late-revalidation-after-status"
    local status_sha
    status_sha=$(late_revalidate after-status \
        "$receipt_sha" "$manifest_sha" "$binding_sha" "$classification_sha" \
        "$provenance_sha" "$pre_audit_sha" "$post_audit_sha" \
        "$identity_sha" "$binary_sha" "$entries_sha")
    [[ "$status_sha" == "$(file_sha "$EXPECTED_STATUS")" ]] ||
        fail "post-status hash differs from expected status"

    task_run_status_stage "single-terminal-marker"
    TERMINAL_SUCCESS=1
    printf '%s\n' \
        "[NPU-QWEN-F32-ALU-CMAKE-TOOL-V4][PASS] version=3.31.12 cmake_sha256=$binary_sha v3_contract_sha256=$V3_CONTRACT_SHA256 v3_installer_sha256=$V3_INSTALLER_SHA256 v3_runner_sha256=$V3_RUNNER_SHA256 v3_archive_sha256=$V3_ARCHIVE_SHA256 v3_archive_audit_sha256=$V3_ARCHIVE_AUDIT_SHA256 tree_manifest_sha256=$V3_TREE_MANIFEST_SHA256 v3_installer_result_sha256=$V3_INSTALLER_RESULT_SHA256 v3_run_status_sha256=$V3_RUN_STATUS_SHA256 v3_installer_stderr_sha256=$V3_INSTALLER_STDERR_SHA256 classification_sha256=$classification_sha provenance_sha256=$provenance_sha pre_tree_audit_sha256=$pre_audit_sha post_tree_audit_sha256=$post_audit_sha tree_entries_sha256=$entries_sha receipt_sha256=$receipt_sha manifest_sha256=$manifest_sha binding_sha256=$binding_sha status_sha256=$status_sha tree_entry_count=$EXPECTED_TREE_ENTRIES tree_rehash_windows=2 successful_main_caught_by_baseexception=1 v3_install_result=PASS v3_runner_result=FAIL-control-flow cleanup_rc=0 bash_n=1 bash_n_rc=0 runner_invocations=1 task_status_test=1 cmake_version_smoke=1 cmake_invocation_total=1 network_download_count=0 installer_invocations=0 archive_extract_count=0 install_publication_count=0 installed_tree_write_count=0 cmake_configure=0 cmake_build=0 verilator=0 make=0 rtl_build=0 binary_runs=0 model_runs=0 qwen_runs=0 synthesis=0 sta=0 ppa=0 system_writes=0 path_mutation_count=0 owned_background_jobs=0 v3_rerun_count=0 compile_performed=0 rtl_dynamic_qualification=GAP strict_backend=GAP canonical_coverage=GAP parent_qwen_shell_goal=GAP"
}

run_once "$@"
