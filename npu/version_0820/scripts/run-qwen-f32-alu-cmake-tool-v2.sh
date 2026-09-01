#!/usr/bin/env bash
set -euo pipefail

# 本地 RV64 F32 ALU O3 compile-only 证据链的工具前置：本 runner 只安装并识别
# workspace-local CMake；不运行 configure/build、RTL binary、model、Qwen、综合或 STA/PPA。

REPO_ROOT=$(cd "$(dirname "$0")/../../.." && pwd)
NPU_ROOT="$REPO_ROOT/npu/version_0820"
TASK_ID="qwen-f32-alu-cmake-tool-v2"
RUNNER_REL="npu/version_0820/scripts/run-qwen-f32-alu-cmake-tool-v2.sh"
RUNNER="$REPO_ROOT/$RUNNER_REL"
INSTALLER_REL="npu/version_0820/scripts/install-cmake-local-v2.py"
INSTALLER="$REPO_ROOT/$INSTALLER_REL"
LOG_ROOT="$NPU_ROOT/tmp/logs/$TASK_ID"
TOOLS_ROOT="$NPU_ROOT/tmp/tools"
STAGING_ROOT="$TOOLS_ROOT/${TASK_ID}-staging"
INSTALL_ROOT="$TOOLS_ROOT/cmake-3.31.12"
CMAKE_BIN="$INSTALL_ROOT/bin/cmake"

CONTRACT="$NPU_ROOT/tmp/contracts/qwen-f32-alu-cmake-tool-v2.json"
MATERIAL="$NPU_ROOT/tmp/contracts/qwen-f32-alu-cmake-tool-v2-material.md"
STATUS_HELPER="$REPO_ROOT/scripts/task-run-status.sh"
STATUS_HELPER_TEST="$REPO_ROOT/scripts/tests/test-task-run-status.sh"
COMPILE_CONTRACT="$NPU_ROOT/tmp/contracts/qwen-f32-alu-families-compile-v2.json"
COMPILE_MATERIAL="$NPU_ROOT/tmp/contracts/qwen-f32-alu-families-compile-v2-material.md"
COMPILE_RUNNER="$NPU_ROOT/scripts/run-qwen-f32-alu-families-compile-v2.sh"
COMPILE_STATUS="$NPU_ROOT/tmp/logs/qwen-f32-alu-families-compile-v2/preflight.status"
V1_CONTRACT="$NPU_ROOT/tmp/contracts/qwen-f32-alu-cmake-tool-v1.json"
V1_MATERIAL="$NPU_ROOT/tmp/contracts/qwen-f32-alu-cmake-tool-v1-material.md"
V1_INSTALLER="$NPU_ROOT/scripts/install-cmake-local-v1.py"
V1_RUNNER="$NPU_ROOT/scripts/run-qwen-f32-alu-cmake-tool-v1.sh"

STATUS_PATH="$LOG_ROOT/run.status"
EXPECTED_STATUS="$LOG_ROOT/expected.status"
RECEIPT="$LOG_ROOT/receipt.json"
BOUND_MANIFEST="$LOG_ROOT/bound-artifacts.json"
FINAL_BINDING="$LOG_ROOT/final-binding.json"
PREDECESSOR_BINDING="$LOG_ROOT/predecessor-syntax-failure.json"
PARENT_PRE="$LOG_ROOT/parent-membership.pre.json"
PARENT_POST="$LOG_ROOT/parent-membership.post.json"
TASK_STATUS_TEST_STDOUT="$LOG_ROOT/task-run-status-test.stdout.log"
TASK_STATUS_TEST_STDERR="$LOG_ROOT/task-run-status-test.stderr.log"
TASK_STATUS_TEST_RC="$LOG_ROOT/task-run-status-test.rc"
INSTALLER_STDOUT="$LOG_ROOT/installer.stdout.log"
INSTALLER_STDERR="$LOG_ROOT/installer.stderr.log"
INSTALLER_RC="$LOG_ROOT/installer.rc"
VERSION_STDOUT="$LOG_ROOT/cmake-version.stdout.log"
VERSION_STDERR="$LOG_ROOT/cmake-version.stderr.log"
VERSION_RC="$LOG_ROOT/cmake-version.rc"
CMAKE_IDENTITY="$LOG_ROOT/cmake-identity.json"
ACTION_COUNTS="$LOG_ROOT/action-counts.json"
PROCESS_AUDIT="$LOG_ROOT/process-cleanup.json"
RUNTIME_TMP="$LOG_ROOT/runtime-tmp"
LOCAL_HOME="$LOG_ROOT/local-home"
LOCAL_CACHE="$LOG_ROOT/local-cache"

CONTRACT_SHA256="4a5dcacd8e532b136a5b55142b9822c942c4018f707de0dc0efcb6cc77fafa9c"
MATERIAL_SHA256="c1798abb87655273e1729c9faa07c0873676d6ade44187e116a155e22d291195"
STATUS_HELPER_SHA256="43977d9787cb41cc541eafa68f1c98f5e4504684b1104398274b07bc8155b7c6"
STATUS_HELPER_TEST_SHA256="35ba14c15c31a291e6a5db8b436d584d0535bd69d11db5495f00232e371a0640"
COMPILE_CONTRACT_SHA256="e76c1b81191cf80eab84aeb9be432beabb6ed81750cff7322769fb8b8264a2ce"
COMPILE_MATERIAL_SHA256="9c10941115ee6775380ed9992122349ac3ef4588fe6dd1ea819a9549f7c7a4de"
COMPILE_RUNNER_SHA256="d13b483c6e6b20b20a00bb5ce0309c0d700434177f6f8d2c090de048127ba055"
COMPILE_STATUS_SHA256="288d115afc3b200dc305d9cad2794d907fce96332a3cb44819c8471463539b84"
V1_CONTRACT_SHA256="9662c2c5dce959f74ffeed703687f2ac69696247ed8e21794d0670d7f40812ca"
V1_MATERIAL_SHA256="4650bd94b3c4bcaab9b6037104b7a71b782f22569bee8bbed777ab21d04668bd"
V1_INSTALLER_SHA256="0451d1ae01aa19f87b2bd4b35412ab1e0d5ae1476fcb14fad9d293a743074996"
V1_RUNNER_SHA256="e50cef598a65cae02099f3f741e61fbc039dbab33d821c971c986b39004e6c2b"
INSTALLER_SHA256="748dda6fbabdfbae0ed0622ddac2c99a0a52da027c716cd6265b957d3bebce40"
CHECKSUM_FILE_SHA256="159eb3b123ba8c8403a154c9d3389432276bf3bd21b274f0396fe17a6a7a7d9d"
ARCHIVE_SHA256="0dc2e9a6860f06bf10bd8fadc03e35d9eeb4df46e33763a7e480e987758f385c"
COMPILE_STATUS_EXPECTED="FAIL rc=1 stage=preflight-input-snapshot evidence_complete=0 cleanup_rc=0"

export PYTHONDONTWRITEBYTECODE=1
export LC_ALL=C

# helper 在 source 前先绑定冻结字节，避免漂移脚本先于 admission 执行。
STATUS_HELPER_OBSERVED=$(sha256sum "$STATUS_HELPER")
[[ "${STATUS_HELPER_OBSERVED%% *}" == "$STATUS_HELPER_SHA256" ]] || {
    printf '%s\n' \
        "[NPU-QWEN-F32-ALU-CMAKE-TOOL-V2][FAIL] status helper hash mismatch before source" >&2
    exit 1
}

# shellcheck source=/dev/null
source "$STATUS_HELPER"

STATUS_INITIALIZED=0
TERMINAL_SUCCESS=0
FORCED_CLEANUP_RC=0

fail() {
    printf '%s\n' "[NPU-QWEN-F32-ALU-CMAKE-TOOL-V2][FAIL] $*" >&2
    return 1
}

fail_rc() {
    local rc="${1:?return code is required}"
    shift
    printf '%s\n' "[NPU-QWEN-F32-ALU-CMAKE-TOOL-V2][FAIL] $*" >&2
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
    [[ -f "$1" && ! -L "$1" ]] || fail "required regular file missing/aliased=$1"
}

require_exact_hash() {
    local path="$1"
    local expected="$2"
    require_file "$path"
    [[ "$(file_sha "$path")" == "$expected" ]] ||
        fail "frozen hash mismatch path=$path expected=$expected"
}

# canonical helper 决定 RUNNING/PASS/FAIL；本覆盖只收紧为 same-directory
# exclusive temporary、nofollow destination check 和原子 replace 状态转换。
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
if current is not None and (not stat.S_ISREG(current.st_mode) or stat.S_ISLNK(current.st_mode)):
    raise SystemExit("status destination is not a regular file")
temporary = path.parent / f".{path.name}.tmp.{os.getpid()}"
flags = os.O_WRONLY | os.O_CREAT | os.O_EXCL | getattr(os, "O_NOFOLLOW", 0)
fd = os.open(temporary, flags, 0o600)
try:
    offset = 0
    while offset < len(payload):
        count = os.write(fd, payload[offset:])
        if count <= 0:
            raise OSError("short status write")
        offset += count
    os.fsync(fd)
finally:
    os.close(fd)
os.replace(temporary, path)
directory_fd = os.open(path.parent, os.O_RDONLY | getattr(os, "O_DIRECTORY", 0))
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
fd = os.open(temporary, flags, 0o600)
try:
    offset = 0
    while offset < len(payload):
        count = os.write(fd, payload[offset:])
        if count <= 0:
            raise OSError("short publication write")
        offset += count
    os.fsync(fd)
finally:
    os.close(fd)
try:
    os.link(temporary, path, follow_symlinks=False)
except BaseException:
    temporary.unlink(missing_ok=True)
    raise
temporary.unlink()
directory_fd = os.open(path.parent, os.O_RDONLY | getattr(os, "O_DIRECTORY", 0))
try:
    os.fsync(directory_fd)
finally:
    os.close(directory_fd)
PY
}

capture_parent_membership() {
    python3 - "$LOG_ROOT" "$STAGING_ROOT" "$INSTALL_ROOT" <<'PY'
import json
import pathlib
import stat
import sys

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
    return {"path": str(path), "present": True, "kind": kind}

value = {
    "schema_version": 1,
    "paths": [record(pathlib.Path(value)) for value in sys.argv[1:]],
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
        command = (entry / "cmdline").read_bytes().replace(b"\0", b" ").decode(errors="replace")
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
payload = (json.dumps(value, sort_keys=True, separators=(",", ":")) + "\n").encode()
temporary = output.parent / f".{output.name}.tmp.{os.getpid()}"
fd = os.open(temporary, os.O_WRONLY | os.O_CREAT | os.O_EXCL | getattr(os, "O_NOFOLLOW", 0), 0o600)
try:
    offset = 0
    while offset < len(payload):
        count = os.write(fd, payload[offset:])
        if count <= 0:
            raise OSError("short process audit write")
        offset += count
    os.fsync(fd)
finally:
    os.close(fd)
os.link(temporary, output, follow_symlinks=False)
temporary.unlink()
directory_fd = os.open(output.parent, os.O_RDONLY | getattr(os, "O_DIRECTORY", 0))
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
    if [[ $STATUS_INITIALIZED -eq 1 ]] && [[ $command_rc -ne 0 || $FORCED_CLEANUP_RC -ne 0 || $TERMINAL_SUCCESS -ne 1 ]]; then
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

write_predecessor_binding() {
    python3 - "$PREDECESSOR_BINDING" <<'PY'
import json
import os
import pathlib
import sys

output = pathlib.Path(sys.argv[1])
value = {
    "schema_version": 1,
    "task_id": "qwen-f32-alu-cmake-tool-v2",
    "predecessor_task_id": "qwen-f32-alu-cmake-tool-v1",
    "predecessor_result": "FAIL",
    "predecessor_bash_n_invocation_count": 1,
    "predecessor_bash_n_rc": 1,
    "predecessor_first_error_line": 886,
    "predecessor_first_error": "unexpected argument newline to conditional binary operator",
    "root_cause": "multiline-conditional-binary-operator-right-operand",
    "root_fix": "all Bash [[ lhs == rhs ]] operands are on one physical command line; prefix match uses case",
    "predecessor_rerun_count": 0,
    "v1_contract_sha256": "9662c2c5dce959f74ffeed703687f2ac69696247ed8e21794d0670d7f40812ca",
    "v1_material_sha256": "4650bd94b3c4bcaab9b6037104b7a71b782f22569bee8bbed777ab21d04668bd",
    "v1_installer_sha256": "0451d1ae01aa19f87b2bd4b35412ab1e0d5ae1476fcb14fad9d293a743074996",
    "v1_runner_sha256": "e50cef598a65cae02099f3f741e61fbc039dbab33d821c971c986b39004e6c2b",
    "evidence_source": "npu/version_0820/tmp/contracts/qwen-f32-alu-cmake-tool-v1-material.md",
}
payload = (json.dumps(value, sort_keys=True, separators=(",", ":")) + "\n").encode()
temporary = output.parent / f".{output.name}.tmp.{os.getpid()}"
fd = os.open(temporary, os.O_WRONLY | os.O_CREAT | os.O_EXCL | getattr(os, "O_NOFOLLOW", 0), 0o600)
try:
    offset = 0
    while offset < len(payload):
        count = os.write(fd, payload[offset:])
        if count <= 0:
            raise OSError("short predecessor binding write")
        offset += count
    os.fsync(fd)
finally:
    os.close(fd)
os.link(temporary, output, follow_symlinks=False)
temporary.unlink()
directory_fd = os.open(output.parent, os.O_RDONLY | getattr(os, "O_DIRECTORY", 0))
try:
    os.fsync(directory_fd)
finally:
    os.close(directory_fd)
PY
}

write_cmake_identity() {
    python3 - "$CMAKE_BIN" "$VERSION_STDOUT" "$VERSION_STDERR" "$VERSION_RC" "$CMAKE_IDENTITY" <<'PY'
import hashlib
import json
import os
import pathlib
import stat
import sys

binary, stdout_path, stderr_path, rc_path, output = map(pathlib.Path, sys.argv[1:])

def stable(path):
    fd = os.open(path, os.O_RDONLY | getattr(os, "O_NOFOLLOW", 0))
    try:
        before = os.fstat(fd)
        if not stat.S_ISREG(before.st_mode):
            raise SystemExit("identity input is not regular: " + str(path))
        chunks = []
        while True:
            chunk = os.read(fd, 1024 * 1024)
            if not chunk:
                break
            chunks.append(chunk)
        after = os.fstat(fd)
    finally:
        os.close(fd)
    data = b"".join(chunks)
    if (before.st_dev, before.st_ino, before.st_size, before.st_mtime_ns) != (
        after.st_dev, after.st_ino, after.st_size, after.st_mtime_ns
    ) or len(data) != before.st_size:
        raise SystemExit("identity input changed during read: " + str(path))
    return data, before

binary_data, binary_stat = stable(binary)
stdout_data, _ = stable(stdout_path)
stderr_data, _ = stable(stderr_path)
rc_data, _ = stable(rc_path)
if rc_data != b"0\n" or stderr_data != b"":
    raise SystemExit("version smoke rc/stderr mismatch")
version_text = stdout_data.decode("utf-8")
if version_text.splitlines()[0:1] != ["cmake version 3.31.12"]:
    raise SystemExit("version smoke first line mismatch")
value = {
    "schema_version": 1,
    "task_id": "qwen-f32-alu-cmake-tool-v2",
    "absolute_path": str(binary.resolve(strict=True)),
    "relative_path": "npu/version_0820/tmp/tools/cmake-3.31.12/bin/cmake",
    "kind": "regular",
    "mode": f"{stat.S_IMODE(binary_stat.st_mode):04o}",
    "size": len(binary_data),
    "sha256": hashlib.sha256(binary_data).hexdigest(),
    "version_invocation_count": 1,
    "version_argv": [str(binary.resolve(strict=True)), "--version"],
    "version_rc": 0,
    "version_first_line": "cmake version 3.31.12",
    "version_stdout": version_text,
    "version_stdout_sha256": hashlib.sha256(stdout_data).hexdigest(),
    "version_stderr_sha256": hashlib.sha256(stderr_data).hexdigest(),
}
payload = (json.dumps(value, sort_keys=True, separators=(",", ":")) + "\n").encode()
temporary = output.parent / f".{output.name}.tmp.{os.getpid()}"
fd = os.open(temporary, os.O_WRONLY | os.O_CREAT | os.O_EXCL | getattr(os, "O_NOFOLLOW", 0), 0o600)
try:
    offset = 0
    while offset < len(payload):
        count = os.write(fd, payload[offset:])
        if count <= 0:
            raise OSError("short CMake identity write")
        offset += count
    os.fsync(fd)
finally:
    os.close(fd)
os.link(temporary, output, follow_symlinks=False)
temporary.unlink()
directory_fd = os.open(output.parent, os.O_RDONLY | getattr(os, "O_DIRECTORY", 0))
try:
    os.fsync(directory_fd)
finally:
    os.close(directory_fd)
PY
}

seal_evidence() {
    python3 - "$REPO_ROOT" "$LOG_ROOT" "$INSTALL_ROOT" <<'PY'
import hashlib
import json
import os
import pathlib
import stat
import sys

root = pathlib.Path(sys.argv[1]).resolve(strict=True)
log_root = pathlib.Path(sys.argv[2])
install_root = pathlib.Path(sys.argv[3])

def stable(path):
    fd = os.open(path, os.O_RDONLY | getattr(os, "O_NOFOLLOW", 0))
    try:
        before = os.fstat(fd)
        if not stat.S_ISREG(before.st_mode):
            raise SystemExit("bound object is not regular: " + str(path))
        chunks = []
        while True:
            chunk = os.read(fd, 1024 * 1024)
            if not chunk:
                break
            chunks.append(chunk)
        after = os.fstat(fd)
    finally:
        os.close(fd)
    data = b"".join(chunks)
    if (before.st_dev, before.st_ino, before.st_size, before.st_mtime_ns) != (
        after.st_dev, after.st_ino, after.st_size, after.st_mtime_ns
    ) or len(data) != before.st_size:
        raise SystemExit("bound object changed during read: " + str(path))
    return data

def load_json(path):
    data = stable(path)
    return json.loads(data), data

def relative(path):
    return path.relative_to(root).as_posix()

def artifact(path, role):
    data = stable(path)
    return {
        "path": relative(path),
        "role": role,
        "size": len(data),
        "sha256": hashlib.sha256(data).hexdigest(),
    }

def publish(path, value=None, raw=None):
    if (value is None) == (raw is None):
        raise SystemExit("publication requires exactly one payload form")
    payload = raw if raw is not None else (
        json.dumps(value, sort_keys=True, separators=(",", ":")) + "\n"
    ).encode()
    try:
        path.lstat()
    except FileNotFoundError:
        pass
    else:
        raise SystemExit("refusing to replace seal path: " + str(path))
    temporary = path.parent / f".{path.name}.tmp.{os.getpid()}"
    fd = os.open(temporary, os.O_WRONLY | os.O_CREAT | os.O_EXCL | getattr(os, "O_NOFOLLOW", 0), 0o600)
    try:
        offset = 0
        while offset < len(payload):
            count = os.write(fd, payload[offset:])
            if count <= 0:
                raise OSError("short seal write")
            offset += count
        os.fsync(fd)
    finally:
        os.close(fd)
    os.link(temporary, path, follow_symlinks=False)
    temporary.unlink()
    directory_fd = os.open(path.parent, os.O_RDONLY | getattr(os, "O_DIRECTORY", 0))
    try:
        os.fsync(directory_fd)
    finally:
        os.close(directory_fd)
    return payload

paths = {
    "contract": root / "npu/version_0820/tmp/contracts/qwen-f32-alu-cmake-tool-v2.json",
    "material": root / "npu/version_0820/tmp/contracts/qwen-f32-alu-cmake-tool-v2-material.md",
    "status_helper": root / "scripts/task-run-status.sh",
    "status_helper_test": root / "scripts/tests/test-task-run-status.sh",
    "compile_contract": root / "npu/version_0820/tmp/contracts/qwen-f32-alu-families-compile-v2.json",
    "compile_material": root / "npu/version_0820/tmp/contracts/qwen-f32-alu-families-compile-v2-material.md",
    "compile_runner": root / "npu/version_0820/scripts/run-qwen-f32-alu-families-compile-v2.sh",
    "compile_status": root / "npu/version_0820/tmp/logs/qwen-f32-alu-families-compile-v2/preflight.status",
    "v1_contract": root / "npu/version_0820/tmp/contracts/qwen-f32-alu-cmake-tool-v1.json",
    "v1_material": root / "npu/version_0820/tmp/contracts/qwen-f32-alu-cmake-tool-v1-material.md",
    "v1_installer": root / "npu/version_0820/scripts/install-cmake-local-v1.py",
    "v1_runner": root / "npu/version_0820/scripts/run-qwen-f32-alu-cmake-tool-v1.sh",
    "installer": root / "npu/version_0820/scripts/install-cmake-local-v2.py",
    "runner": root / "npu/version_0820/scripts/run-qwen-f32-alu-cmake-tool-v2.sh",
    "predecessor_binding": log_root / "predecessor-syntax-failure.json",
    "checksum_download_log": log_root / "checksum-download.log",
    "checksum_download_rc": log_root / "checksum-download.rc",
    "archive_download_log": log_root / "archive-download.log",
    "archive_download_rc": log_root / "archive-download.rc",
    "checksum": log_root / "cmake-3.31.12-SHA-256.txt",
    "archive": log_root / "cmake-3.31.12-linux-x86_64.tar.gz",
    "provenance": log_root / "source-provenance.json",
    "archive_audit": log_root / "archive-audit.json",
    "tree_manifest": log_root / "installed-tree-manifest.json",
    "installer_result": log_root / "installer-result.json",
    "task_test_stdout": log_root / "task-run-status-test.stdout.log",
    "task_test_stderr": log_root / "task-run-status-test.stderr.log",
    "task_test_rc": log_root / "task-run-status-test.rc",
    "installer_stdout": log_root / "installer.stdout.log",
    "installer_stderr": log_root / "installer.stderr.log",
    "installer_rc": log_root / "installer.rc",
    "version_stdout": log_root / "cmake-version.stdout.log",
    "version_stderr": log_root / "cmake-version.stderr.log",
    "version_rc": log_root / "cmake-version.rc",
    "cmake_identity": log_root / "cmake-identity.json",
    "parent_pre": log_root / "parent-membership.pre.json",
    "parent_post": log_root / "parent-membership.post.json",
    "action_counts": log_root / "action-counts.json",
    "process_audit": log_root / "process-cleanup.json",
    "cmake_binary": install_root / "bin/cmake",
}
expected_hashes = {
    "contract": "4a5dcacd8e532b136a5b55142b9822c942c4018f707de0dc0efcb6cc77fafa9c",
    "material": "c1798abb87655273e1729c9faa07c0873676d6ade44187e116a155e22d291195",
    "status_helper": "43977d9787cb41cc541eafa68f1c98f5e4504684b1104398274b07bc8155b7c6",
    "status_helper_test": "35ba14c15c31a291e6a5db8b436d584d0535bd69d11db5495f00232e371a0640",
    "compile_contract": "e76c1b81191cf80eab84aeb9be432beabb6ed81750cff7322769fb8b8264a2ce",
    "compile_material": "9c10941115ee6775380ed9992122349ac3ef4588fe6dd1ea819a9549f7c7a4de",
    "compile_runner": "d13b483c6e6b20b20a00bb5ce0309c0d700434177f6f8d2c090de048127ba055",
    "compile_status": "288d115afc3b200dc305d9cad2794d907fce96332a3cb44819c8471463539b84",
    "v1_contract": "9662c2c5dce959f74ffeed703687f2ac69696247ed8e21794d0670d7f40812ca",
    "v1_material": "4650bd94b3c4bcaab9b6037104b7a71b782f22569bee8bbed777ab21d04668bd",
    "v1_installer": "0451d1ae01aa19f87b2bd4b35412ab1e0d5ae1476fcb14fad9d293a743074996",
    "v1_runner": "e50cef598a65cae02099f3f741e61fbc039dbab33d821c971c986b39004e6c2b",
    "installer": "748dda6fbabdfbae0ed0622ddac2c99a0a52da027c716cd6265b957d3bebce40",
    "checksum": "159eb3b123ba8c8403a154c9d3389432276bf3bd21b274f0396fe17a6a7a7d9d",
    "archive": "0dc2e9a6860f06bf10bd8fadc03e35d9eeb4df46e33763a7e480e987758f385c",
}
for name, expected in expected_hashes.items():
    actual = hashlib.sha256(stable(paths[name])).hexdigest()
    if actual != expected:
        raise SystemExit(f"seal frozen hash mismatch {name}: {actual}")

if stable(paths["compile_status"]) != b"FAIL rc=1 stage=preflight-input-snapshot evidence_complete=0 cleanup_rc=0\n":
    raise SystemExit("compile-v2 status no longer records the frozen build-free CMake gap")
predecessor, _ = load_json(paths["predecessor_binding"])
expected_predecessor = {
    "schema_version": 1,
    "task_id": "qwen-f32-alu-cmake-tool-v2",
    "predecessor_task_id": "qwen-f32-alu-cmake-tool-v1",
    "predecessor_result": "FAIL",
    "predecessor_bash_n_invocation_count": 1,
    "predecessor_bash_n_rc": 1,
    "predecessor_first_error_line": 886,
    "predecessor_first_error": "unexpected argument newline to conditional binary operator",
    "root_cause": "multiline-conditional-binary-operator-right-operand",
    "root_fix": "all Bash [[ lhs == rhs ]] operands are on one physical command line; prefix match uses case",
    "predecessor_rerun_count": 0,
    "v1_contract_sha256": expected_hashes["v1_contract"],
    "v1_material_sha256": expected_hashes["v1_material"],
    "v1_installer_sha256": expected_hashes["v1_installer"],
    "v1_runner_sha256": expected_hashes["v1_runner"],
    "evidence_source": "npu/version_0820/tmp/contracts/qwen-f32-alu-cmake-tool-v1-material.md",
}
if predecessor != expected_predecessor:
    raise SystemExit("v1 predecessor syntax-failure binding mismatch")

for name in ("checksum_download_rc", "archive_download_rc", "task_test_rc", "installer_rc", "version_rc"):
    if stable(paths[name]) != b"0\n":
        raise SystemExit("successful action rc is not exactly zero: " + name)
checksum_download, _ = load_json(paths["checksum_download_log"])
archive_download, _ = load_json(paths["archive_download_log"])
if checksum_download.get("return_code") != 0 or checksum_download.get("sha256") != expected_hashes["checksum"]:
    raise SystemExit("checksum download log/retained input mismatch")
if archive_download.get("return_code") != 0 or archive_download.get("sha256") != expected_hashes["archive"]:
    raise SystemExit("archive download log/retained input mismatch")
if stable(paths["task_test_stderr"]) or stable(paths["installer_stderr"]) or stable(paths["version_stderr"]):
    raise SystemExit("successful command emitted unexpected stderr")
if stable(paths["task_test_stdout"]) != (
    b"[task-run-status-test] PASS explicit completion, early exit, command failure, cleanup failure, "
    b"PASS-write fallback, and HUP/INT/TERM\n"
):
    raise SystemExit("task-status directed-test output mismatch")
if not stable(paths["installer_stdout"]).startswith(b"[NPU-QWEN-F32-ALU-CMAKE-TOOL-V2][INSTALLER-PASS] "):
    raise SystemExit("installer PASS marker mismatch")
version_stdout = stable(paths["version_stdout"])
if version_stdout.decode("utf-8").splitlines()[0:1] != ["cmake version 3.31.12"]:
    raise SystemExit("CMake version first line mismatch")

installer_result, _ = load_json(paths["installer_result"])
tree_manifest, tree_manifest_data = load_json(paths["tree_manifest"])
identity, _ = load_json(paths["cmake_identity"])
actions, _ = load_json(paths["action_counts"])
process, _ = load_json(paths["process_audit"])
parent_pre, _ = load_json(paths["parent_pre"])
parent_post, _ = load_json(paths["parent_post"])
if installer_result.get("result") != "PASS" or installer_result.get("staging_root_absent") is not True:
    raise SystemExit("installer result is not a closed PASS")
if installer_result.get("tree_manifest_sha256") != hashlib.sha256(tree_manifest_data).hexdigest():
    raise SystemExit("installer result/tree manifest binding mismatch")
if identity.get("version_first_line") != "cmake version 3.31.12" or identity.get("version_rc") != 0:
    raise SystemExit("installed CMake identity mismatch")
zero_names = (
    "cmake_configure", "cmake_build", "verilator", "make", "rtl_build", "binary_runs",
    "model_runs", "qwen_runs", "synthesis", "sta", "ppa", "system_writes",
    "v1_runner_invocations", "v1_bash_n_reruns",
)
if any(actions.get(name) != 0 for name in zero_names):
    raise SystemExit("a forbidden build/runtime/system/predecessor action count is nonzero")
required_counts = {
    "bash_n": 1,
    "bash_n_rc": 0,
    "runner_invocations": 1,
    "task_status_test": 1,
    "installer_invocations": 1,
    "installer_rc": 0,
    "downloads": 2,
    "download_rc_sum": 0,
    "cmake_version_smoke": 1,
    "cleanup_rc": 0,
}
if any(actions.get(name) != value for name, value in required_counts.items()):
    raise SystemExit("required unique action count mismatch")
if process != {
    "bash_job_count": 0,
    "cleanup_rc": 0,
    "owned_process_count": 0,
    "owned_processes": [],
    "schema_version": 1,
    "task_id": "qwen-f32-alu-cmake-tool-v2",
}:
    raise SystemExit("process cleanup audit mismatch")
if [item["present"] for item in parent_pre["paths"]] != [False, False, False]:
    raise SystemExit("pre parent membership was not fresh")
if [(item["present"], item["kind"]) for item in parent_post["paths"]] != [
    (True, "directory"), (False, "absent"), (True, "directory")
]:
    raise SystemExit("post parent membership mismatch")

frozen_roles = {
    "contract": "task-contract", "material": "task-material", "status_helper": "status-helper",
    "status_helper_test": "status-helper-directed-test", "compile_contract": "compile-v2-contract",
    "compile_material": "compile-v2-material", "compile_runner": "compile-v2-runner",
    "compile_status": "compile-v2-build-free-failure", "v1_contract": "v1-task-contract",
    "v1_material": "v1-task-material-and-syntax-failure", "v1_installer": "v1-installer-source",
    "v1_runner": "v1-runner-source", "installer": "v2-installer-source", "runner": "v2-runner-source",
}
evidence_roles = {
    "predecessor_binding": "v1-syntax-failure-binding",
    "checksum_download_log": "checksum-download-log", "checksum_download_rc": "checksum-download-rc",
    "archive_download_log": "archive-download-log", "archive_download_rc": "archive-download-rc",
    "checksum": "retained-official-checksum", "archive": "retained-official-archive",
    "provenance": "source-provenance", "archive_audit": "safe-archive-audit",
    "tree_manifest": "complete-installed-tree-manifest", "installer_result": "installer-result",
    "task_test_stdout": "task-status-test-stdout", "task_test_stderr": "task-status-test-stderr",
    "task_test_rc": "task-status-test-rc", "installer_stdout": "installer-stdout",
    "installer_stderr": "installer-stderr", "installer_rc": "installer-rc",
    "version_stdout": "cmake-version-stdout", "version_stderr": "cmake-version-stderr",
    "version_rc": "cmake-version-rc", "cmake_identity": "installed-cmake-identity",
    "parent_pre": "pre-parent-membership", "parent_post": "post-parent-membership",
    "action_counts": "zero-action-count-and-unique-invocations", "process_audit": "process-cleanup",
    "cmake_binary": "installed-cmake-binary",
}

tree_manifest_sha = hashlib.sha256(tree_manifest_data).hexdigest()
binary_data = stable(paths["cmake_binary"])
binary_sha = hashlib.sha256(binary_data).hexdigest()
receipt = {
    "schema_version": 1,
    "task_id": "qwen-f32-alu-cmake-tool-v2",
    "result": "PASS",
    "qualified_scope": "workspace-local pinned CMake tool only",
    "release_version": "3.31.12",
    "contract_sha256": expected_hashes["contract"],
    "checksum_file_sha256": expected_hashes["checksum"],
    "archive_sha256": expected_hashes["archive"],
    "tree_manifest_sha256": tree_manifest_sha,
    "installed_cmake_sha256": binary_sha,
    "installed_cmake_size": len(binary_data),
    "installed_cmake_path": relative(paths["cmake_binary"]),
    "cmake_version_first_line": "cmake version 3.31.12",
    "atomic_install_publication": "renameat2-RENAME_NOREPLACE",
    "staging_root_absent": True,
    "v1_syntax_failure": predecessor,
    "action_counts": actions,
    "process_cleanup": process,
    "status_expected": "PASS",
    "terminal_marker_expected": "[NPU-QWEN-F32-ALU-CMAKE-TOOL-V2][PASS] version=3.31.12",
    "compile_v2_status": "GAP-build-free-cmake-missing",
    "rtl_build_count": 0,
    "binary_run_count": 0,
    "model_run_count": 0,
    "qwen_run_count": 0,
    "synthesis_count": 0,
    "sta_count": 0,
    "ppa_count": 0,
    "canonical_completed": 0,
    "dynamic_profiles": "GAP",
    "strict_backend": "GAP",
}
receipt_path = log_root / "receipt.json"
receipt_data = publish(receipt_path, value=receipt)
receipt_sha = hashlib.sha256(receipt_data).hexdigest()
expected_status_path = log_root / "expected.status"
expected_status_data = publish(expected_status_path, raw=b"PASS\n")

artifacts = []
for name, role in sorted({**frozen_roles, **evidence_roles}.items()):
    artifacts.append(artifact(paths[name], role))
artifacts.append(artifact(receipt_path, "receipt"))
artifacts.append(artifact(expected_status_path, "expected-final-status"))
artifacts.sort(key=lambda item: item["path"])
manifest = {
    "schema_version": 1,
    "task_id": "qwen-f32-alu-cmake-tool-v2",
    "receipt_sha256": receipt_sha,
    "artifact_count": len(artifacts),
    "artifacts": artifacts,
}
manifest_path = log_root / "bound-artifacts.json"
manifest_data = publish(manifest_path, value=manifest)
manifest_sha = hashlib.sha256(manifest_data).hexdigest()
binding = {
    "schema_version": 1,
    "task_id": "qwen-f32-alu-cmake-tool-v2",
    "result": "PASS",
    "receipt_path": relative(receipt_path),
    "receipt_sha256": receipt_sha,
    "bound_artifacts_path": relative(manifest_path),
    "bound_artifacts_sha256": manifest_sha,
    "tree_manifest_path": relative(paths["tree_manifest"]),
    "tree_manifest_sha256": tree_manifest_sha,
    "installed_cmake_path": relative(paths["cmake_binary"]),
    "installed_cmake_sha256": binary_sha,
    "expected_status_path": relative(expected_status_path),
    "expected_status_sha256": hashlib.sha256(expected_status_data).hexdigest(),
    "status_path": relative(log_root / "run.status"),
    "status_publication_must_follow_binding": True,
    "pass_marker_is_final_successful_action": True,
}
binding_path = log_root / "final-binding.json"
binding_data = publish(binding_path, value=binding)
binding_sha = hashlib.sha256(binding_data).hexdigest()
print(receipt_sha, manifest_sha, binding_sha, tree_manifest_sha, binary_sha)
PY
}

late_revalidate() {
    local phase="${1:?phase is required}"
    local receipt_sha="${2:?receipt sha is required}"
    local manifest_sha="${3:?manifest sha is required}"
    local binding_sha="${4:?binding sha is required}"
    local tree_manifest_sha="${5:?tree manifest sha is required}"
    local binary_sha="${6:?binary sha is required}"
    python3 - "$REPO_ROOT" "$LOG_ROOT" "$INSTALL_ROOT" "$STAGING_ROOT" "$RUNTIME_TMP" \
        "$LOCAL_HOME" "$LOCAL_CACHE" "$phase" "$receipt_sha" "$manifest_sha" \
        "$binding_sha" "$tree_manifest_sha" "$binary_sha" <<'PY'
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
runtime_tmp = pathlib.Path(sys.argv[5])
local_home = pathlib.Path(sys.argv[6])
local_cache = pathlib.Path(sys.argv[7])
phase = sys.argv[8]
expected_receipt_sha, expected_manifest_sha, expected_binding_sha = sys.argv[9:12]
expected_tree_manifest_sha, expected_binary_sha = sys.argv[12:14]

def absent(path):
    try:
        path.lstat()
    except FileNotFoundError:
        return True
    return False

def stable(path):
    fd = os.open(path, os.O_RDONLY | getattr(os, "O_NOFOLLOW", 0))
    digest = hashlib.sha256()
    chunks = []
    try:
        before = os.fstat(fd)
        if not stat.S_ISREG(before.st_mode):
            raise SystemExit("late bound object is not regular: " + str(path))
        while True:
            chunk = os.read(fd, 1024 * 1024)
            if not chunk:
                break
            chunks.append(chunk)
            digest.update(chunk)
        after = os.fstat(fd)
    finally:
        os.close(fd)
    data = b"".join(chunks)
    if (before.st_dev, before.st_ino, before.st_size, before.st_mtime_ns) != (
        after.st_dev, after.st_ino, after.st_size, after.st_mtime_ns
    ) or len(data) != before.st_size:
        raise SystemExit("late bound object changed during read: " + str(path))
    return data, digest.hexdigest()

def load(path):
    data, digest = stable(path)
    return json.loads(data), digest

receipt, receipt_sha = load(log_root / "receipt.json")
manifest, manifest_sha = load(log_root / "bound-artifacts.json")
binding, binding_sha = load(log_root / "final-binding.json")
tree_manifest, observed_tree_manifest_sha = load(log_root / "installed-tree-manifest.json")
if (receipt_sha, manifest_sha, binding_sha, observed_tree_manifest_sha) != (
    expected_receipt_sha, expected_manifest_sha, expected_binding_sha, expected_tree_manifest_sha
):
    raise SystemExit("late final-document hash drift")
if manifest.get("receipt_sha256") != receipt_sha:
    raise SystemExit("late receipt/manifest binding drift")
if binding.get("receipt_sha256") != receipt_sha or binding.get("bound_artifacts_sha256") != manifest_sha:
    raise SystemExit("late final binding drift")
for record in manifest["artifacts"]:
    path = root / record["path"]
    data, digest = stable(path)
    if len(data) != record["size"] or digest != record["sha256"]:
        raise SystemExit("late bound artifact drift: " + record["path"])

entries = []
def visit(path, relative):
    observed = path.lstat()
    mode = stat.S_IMODE(observed.st_mode)
    if stat.S_ISDIR(observed.st_mode) and not stat.S_ISLNK(observed.st_mode):
        entries.append({"path": relative, "kind": "directory", "mode": f"{mode:04o}", "size": 0})
        for child in sorted(os.scandir(path), key=lambda item: item.name):
            child_relative = child.name if relative == "." else relative + "/" + child.name
            visit(path / child.name, child_relative)
    elif stat.S_ISREG(observed.st_mode):
        data, digest = stable(path)
        entries.append({
            "path": relative,
            "kind": "regular",
            "mode": f"{mode:04o}",
            "size": len(data),
            "sha256": digest,
        })
    else:
        raise SystemExit("late tree contains link/special object: " + str(path))

visit(install_root, ".")
if entries != tree_manifest.get("entries"):
    raise SystemExit("late installed tree differs from retained complete manifest")
binary_data, binary_sha = stable(install_root / "bin/cmake")
if binary_sha != expected_binary_sha or receipt.get("installed_cmake_size") != len(binary_data):
    raise SystemExit("late installed cmake identity drift")
if not absent(staging_root) or not absent(runtime_tmp) or not absent(local_home) or not absent(local_cache):
    raise SystemExit("late staging/temp/cache cleanup mismatch")
for scan_root in (log_root, install_root):
    for path in scan_root.rglob("*"):
        if path.name == "__pycache__" or path.suffix == ".pyc":
            raise SystemExit("Python cache residue found: " + str(path))
for path in log_root.iterdir():
    if path.name.startswith(".") and ".tmp." in path.name:
        raise SystemExit("atomic temporary evidence residue found: " + str(path))

status_data, status_sha = stable(log_root / "run.status")
expected_status_data, expected_status_sha = stable(log_root / "expected.status")
if expected_status_data != b"PASS\n" or binding.get("expected_status_sha256") != expected_status_sha:
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
    [[ "${QWEN_F32_CMAKE_V2_BASH_N_COUNT:-}" == "1" ]] || fail "external unique v2 bash-n count assertion must equal 1"
    [[ "${QWEN_F32_CMAKE_V2_BASH_N_RC:-}" == "0" ]] || fail "external unique v2 bash-n rc assertion must equal 0"

    path_absent "$LOG_ROOT" || fail "fresh log root already exists=$LOG_ROOT"
    path_absent "$STAGING_ROOT" || fail "fresh staging root already exists=$STAGING_ROOT"
    path_absent "$INSTALL_ROOT" || fail "fresh install root already exists=$INSTALL_ROOT"
    [[ -d "$TOOLS_ROOT" && ! -L "$TOOLS_ROOT" ]] || fail "tools parent is missing/aliased=$TOOLS_ROOT"
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

    task_run_status_stage "frozen-input-admission"
    require_exact_hash "$CONTRACT" "$CONTRACT_SHA256"
    require_exact_hash "$MATERIAL" "$MATERIAL_SHA256"
    require_exact_hash "$STATUS_HELPER" "$STATUS_HELPER_SHA256"
    require_exact_hash "$STATUS_HELPER_TEST" "$STATUS_HELPER_TEST_SHA256"
    require_exact_hash "$COMPILE_CONTRACT" "$COMPILE_CONTRACT_SHA256"
    require_exact_hash "$COMPILE_MATERIAL" "$COMPILE_MATERIAL_SHA256"
    require_exact_hash "$COMPILE_RUNNER" "$COMPILE_RUNNER_SHA256"
    require_exact_hash "$COMPILE_STATUS" "$COMPILE_STATUS_SHA256"
    [[ "$(<"$COMPILE_STATUS")" == "$COMPILE_STATUS_EXPECTED" ]] || fail "compile-v2 build-free CMake gap status mismatch"
    require_exact_hash "$V1_CONTRACT" "$V1_CONTRACT_SHA256"
    require_exact_hash "$V1_MATERIAL" "$V1_MATERIAL_SHA256"
    require_exact_hash "$V1_INSTALLER" "$V1_INSTALLER_SHA256"
    require_exact_hash "$V1_RUNNER" "$V1_RUNNER_SHA256"
    require_exact_hash "$INSTALLER" "$INSTALLER_SHA256"
    require_file "$RUNNER"
    write_predecessor_binding

    task_run_status_stage "task-status-directed-test"
    local task_test_rc=0
    set +e
    run_with_exclusive_logs "$TASK_STATUS_TEST_STDOUT" "$TASK_STATUS_TEST_STDERR" bash "$STATUS_HELPER_TEST"
    task_test_rc=$?
    set -e
    publish_text_no_replace "$TASK_STATUS_TEST_RC" "$task_test_rc"$'\n'
    [[ $task_test_rc -eq 0 ]] || fail_rc "$task_test_rc" "task-status directed test failed rc=$task_test_rc"
    [[ ! -s "$TASK_STATUS_TEST_STDERR" ]] || fail "task-status directed test emitted stderr"
    [[ "$(read_first_line "$TASK_STATUS_TEST_STDOUT")" == "[task-run-status-test] PASS explicit completion, early exit, command failure, cleanup failure, PASS-write fallback, and HUP/INT/TERM" ]] || fail "task-status directed-test marker mismatch"

    task_run_status_stage "pinned-installer"
    local installer_rc=0
    set +e
    run_with_exclusive_logs "$INSTALLER_STDOUT" "$INSTALLER_STDERR" python3 "$INSTALLER"
    installer_rc=$?
    set -e
    publish_text_no_replace "$INSTALLER_RC" "$installer_rc"$'\n'
    [[ $installer_rc -eq 0 ]] || fail_rc "$installer_rc" "pinned installer failed rc=$installer_rc"
    [[ ! -s "$INSTALLER_STDERR" ]] || fail "successful installer emitted stderr"
    local installer_marker
    installer_marker=$(read_first_line "$INSTALLER_STDOUT")
    case "$installer_marker" in
        "[NPU-QWEN-F32-ALU-CMAKE-TOOL-V2][INSTALLER-PASS] version=3.31.12 "*) ;;
        *) fail "installer PASS marker mismatch" ;;
    esac
    path_absent "$STAGING_ROOT" || fail "staging root remains after installer"
    require_file "$CMAKE_BIN"
    [[ -x "$CMAKE_BIN" ]] || fail "installed cmake is not executable"

    task_run_status_stage "cmake-version-smoke"
    local version_rc=0
    set +e
    run_with_exclusive_logs "$VERSION_STDOUT" "$VERSION_STDERR" "$CMAKE_BIN" --version
    version_rc=$?
    set -e
    publish_text_no_replace "$VERSION_RC" "$version_rc"$'\n'
    [[ $version_rc -eq 0 ]] || fail_rc "$version_rc" "cmake --version failed rc=$version_rc"
    [[ ! -s "$VERSION_STDERR" ]] || fail "cmake --version emitted unexpected stderr"
    [[ "$(read_first_line "$VERSION_STDOUT")" == "cmake version 3.31.12" ]] || fail "cmake --version first line mismatch"
    write_cmake_identity

    task_run_status_stage "zero-action-and-cleanup"
    publish_text_no_replace "$ACTION_COUNTS" \
        '{"bash_n":1,"bash_n_rc":0,"binary_runs":0,"cleanup_rc":0,"cmake_build":0,"cmake_configure":0,"cmake_version_smoke":1,"download_rc_sum":0,"downloads":2,"installer_invocations":1,"installer_rc":0,"make":0,"model_runs":0,"ppa":0,"qwen_runs":0,"rtl_build":0,"runner_invocations":1,"schema_version":1,"sta":0,"synthesis":0,"system_writes":0,"task_id":"qwen-f32-alu-cmake-tool-v2","task_status_test":1,"v1_bash_n_reruns":0,"v1_runner_invocations":0,"verilator":0}'$'\n'
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
    path_absent "$STAGING_ROOT" || {
        FORCED_CLEANUP_RC=95
        fail "staging root remains at cleanup"
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

    task_run_status_stage "receipt-binding-publication"
    local seal_result receipt_sha manifest_sha binding_sha tree_manifest_sha binary_sha
    seal_result=$(seal_evidence)
    read -r receipt_sha manifest_sha binding_sha tree_manifest_sha binary_sha <<<"$seal_result"
    for value in "$receipt_sha" "$manifest_sha" "$binding_sha" "$tree_manifest_sha" "$binary_sha"; do
        [[ "$value" =~ ^[0-9a-f]{64}$ ]] || fail "invalid seal hash=$value"
    done

    task_run_status_stage "late-revalidation-before-status"
    late_revalidate before-status "$receipt_sha" "$manifest_sha" "$binding_sha" "$tree_manifest_sha" "$binary_sha" >/dev/null

    task_run_status_stage "status-publication"
    task_run_status_mark_evidence_complete
    task_run_status_finalize 0 0

    task_run_status_stage "late-revalidation-after-status"
    local status_sha
    status_sha=$(late_revalidate after-status "$receipt_sha" "$manifest_sha" "$binding_sha" "$tree_manifest_sha" "$binary_sha")
    [[ "$status_sha" == "$(file_sha "$EXPECTED_STATUS")" ]] || fail "post-status hash differs from expected status"

    task_run_status_stage "single-terminal-marker"
    TERMINAL_SUCCESS=1
    printf '%s\n' \
        "[NPU-QWEN-F32-ALU-CMAKE-TOOL-V2][PASS] version=3.31.12 checksum_file_sha256=$CHECKSUM_FILE_SHA256 archive_sha256=$ARCHIVE_SHA256 cmake_sha256=$binary_sha tree_manifest_sha256=$tree_manifest_sha receipt_sha256=$receipt_sha manifest_sha256=$manifest_sha binding_sha256=$binding_sha status_sha256=$status_sha cleanup_rc=0 bash_n=1 bash_n_rc=0 runner_invocations=1 task_status_test=1 installer_invocations=1 installer_rc=0 download_count=2 download_rc_sum=0 cmake_version_smoke=1 cmake_configure=0 cmake_build=0 verilator=0 make=0 rtl_build=0 binary_runs=0 model_runs=0 qwen_runs=0 synthesis=0 sta=0 ppa=0 system_writes=0 owned_background_jobs=0 v1_bash_n_rc=1 v1_first_error_line=886 v1_rerun_count=0 compile_v2=GAP-build-free-cmake-missing canonical_completed=0 dynamic_profiles=GAP strict_backend=GAP"
}

run_once "$@"
