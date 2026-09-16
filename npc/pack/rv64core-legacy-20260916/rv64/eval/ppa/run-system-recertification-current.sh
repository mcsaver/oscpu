#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
runner_script="${repo_root}/npc/rv64/eval/ppa/run-system-recertification-current.sh"
summary_tool="${repo_root}/npc/rv64/eval/ppa/tools/system_recertification_run.py"
policy_path="${repo_root}/npc/rv64/design/arch/system-recertification-run-policy-v1.json"
status_helper="${repo_root}/scripts/task-run-status.sh"
lock_path="${repo_root}/.github/runtime-artifacts/rv64-engineering-single-flight.lock"
runtime_root="${repo_root}/.github/runtime-artifacts/rv64-system-recertification"

mode="launch"
validate_only=0
run_dir_arg=""
expected_design_id=""
expected_file_count=""
host_timeout_seconds=100000
max_cycles=6000000000
commit_gap_limit_cycles=1000000
progress_interval=5000000
jobs=2
user_authorized_full_ubuntu=0

usage() {
  cat <<'EOF'
usage:
  npc/rv64/eval/ppa/run-system-recertification-current.sh --validate-only
  npc/rv64/eval/ppa/run-system-recertification-current.sh \
    --run-dir .github/task-runs/<new-run-id> \
    --expected-design-id sha256:<64-hex> --expected-file-count N [options]

options:
  --host-timeout-seconds N
  --max-cycles N                 minimum 6000000000
  --commit-gap-limit-cycles N
  --progress-interval N
  --jobs N
  --user-authorized-full-ubuntu  Required explicit authorization for every
                                 Ubuntu 22.04 launch or internal execution.

The normal entry validates the runner and starts one detached, single-flight
execution.  Full Ubuntu is optional recertification: launch is rejected unless
--user-authorized-full-ubuntu is present.  --execute is internal and is accepted
only while the global RV64 engineering lock is held and carries the same flag.
EOF
}

workspace_config_fingerprint() {
  local path
  for path in \
    "${repo_root}/npc/rv64/.config" \
    "${repo_root}/npc/rv64/include/config/auto.conf" \
    "${repo_root}/npc/rv64/include/generated/autoconf.h"; do
    if [[ -f "${path}" && ! -L "${path}" ]]; then
      printf '%s:%s\n' "${path#${repo_root}/}" \
        "$(sha256sum "${path}" | awk '{print $1}')"
    elif [[ ! -e "${path}" && ! -L "${path}" ]]; then
      printf '%s:MISSING\n' "${path#${repo_root}/}"
    else
      printf '%s:INVALID\n' "${path#${repo_root}/}"
    fi
  done
}

config_isolation_smoke() {
  local smoke_root=""
  local before=""
  local after=""
  local smoke_rc=0
  smoke_root="$(mktemp -d -t rv64-system-recert-config.XXXXXX)"
  before="$(workspace_config_fingerprint)"
  set +e
  mkdir -p "${smoke_root}/npc-source-sandbox/npc/rv64"
  cp -a -- "${repo_root}/Makefile" \
    "${smoke_root}/npc-source-sandbox/Makefile" || smoke_rc=$?
  cp -a -- \
    "${repo_root}/npc/rv64/Makefile" \
    "${repo_root}/npc/rv64/Kconfig" \
    "${repo_root}/npc/rv64/configs" \
    "${repo_root}/npc/rv64/scripts" \
    "${repo_root}/npc/rv64/csrc" \
    "${repo_root}/npc/rv64/vsrc" \
    "${smoke_root}/npc-source-sandbox/npc/rv64/" || smoke_rc=$?
  if [[ "${smoke_rc}" -eq 0 ]]; then
    env NEMU_HOME="${repo_root}/nemu" YSYX_HOME="${repo_root}" \
      make -s -C "${smoke_root}/npc-source-sandbox/npc/rv64" \
      WORK_BRANCH=system-recertification-sandbox default_defconfig \
      >"${smoke_root}/config.log" 2>&1 || smoke_rc=$?
  fi
  if [[ "${smoke_rc}" -eq 0 ]]; then
    grep -Fqx "CONFIG_NPC_DIFFTEST=y" \
      "${smoke_root}/npc-source-sandbox/npc/rv64/.config" || smoke_rc=$?
    grep -Fqx "# CONFIG_NPC_DEBUG_PORTS is not set" \
      "${smoke_root}/npc-source-sandbox/npc/rv64/.config" || smoke_rc=$?
  fi
  after="$(workspace_config_fingerprint)"
  if [[ "${before}" != "${after}" ]]; then
    smoke_rc=1
  fi
  case "${smoke_root}" in
    /tmp/rv64-system-recert-config.*)
      rm -rf -- "${smoke_root}" || smoke_rc=$?
      ;;
    *)
      printf '%s\n' \
        "[RV64-SYSTEM-RECERT-CONFIG-SMOKE][FAIL] unsafe temp root" >&2
      smoke_rc=2
      ;;
  esac
  set -e
  if [[ "${smoke_rc}" -eq 0 ]]; then
    printf '%s\n' \
      "[RV64-SYSTEM-RECERT-CONFIG-SMOKE] PASS workspace_config_drift=0"
  fi
  return "${smoke_rc}"
}

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --validate-only)
      validate_only=1
      shift
      ;;
    --execute)
      mode="execute"
      shift
      ;;
    --run-dir)
      run_dir_arg="${2:?--run-dir requires a value}"
      shift 2
      ;;
    --expected-design-id)
      expected_design_id="${2:?--expected-design-id requires a value}"
      shift 2
      ;;
    --expected-file-count)
      expected_file_count="${2:?--expected-file-count requires a value}"
      shift 2
      ;;
    --host-timeout-seconds)
      host_timeout_seconds="${2:?--host-timeout-seconds requires a value}"
      shift 2
      ;;
    --max-cycles)
      max_cycles="${2:?--max-cycles requires a value}"
      shift 2
      ;;
    --commit-gap-limit-cycles)
      commit_gap_limit_cycles="${2:?--commit-gap-limit-cycles requires a value}"
      shift 2
      ;;
    --progress-interval)
      progress_interval="${2:?--progress-interval requires a value}"
      shift 2
      ;;
    --jobs)
      jobs="${2:?--jobs requires a value}"
      shift 2
      ;;
    --user-authorized-full-ubuntu)
      user_authorized_full_ubuntu=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf '%s\n' "[RV64-SYSTEM-RECERT-LAUNCH][FAIL] unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

validate_contract() {
  bash -n "${runner_script}"
  python3 -B "${summary_tool}" self-test
  python3 -B -m unittest -q \
    npc.rv64.eval.ppa.tests.test_system_recertification_runner
  bash "${repo_root}/scripts/tests/test-task-run-status.sh"
  python3 -B "${repo_root}/Linux/scripts/tests/test_npc_systemd_strict_check.py"
  python3 -B "${repo_root}/Linux/scripts/tests/test_check_npc_systemd_guest_contract.py"
  python3 -B "${repo_root}/Linux/scripts/tests/test_npc_systemd_transaction_evidence.py"
  python3 -B "${repo_root}/npc/rv64/testbench/scripts/test_debug_ooo_flags_contract.py"
  config_isolation_smoke
  printf '%s\n' \
    "[RV64-SYSTEM-RECERT-PRELAUNCH] status=PASS checker_suites=7"
}

for command_name in \
  awk bash clang++ cmp cp flock grep make nohup python3 readlink realpath \
  rg setsid sha256sum tail verilator; do
  command -v "${command_name}" >/dev/null
done
for required_file in \
  "${runner_script}" "${summary_tool}" "${policy_path}" "${status_helper}"; do
  test -s "${required_file}"
done

if [[ "${validate_only}" -eq 1 ]]; then
  [[ "${mode}" == "launch" ]]
  [[ -z "${run_dir_arg}" ]]
  validate_contract
  exit 0
fi

if [[ "${user_authorized_full_ubuntu}" -ne 1 ]]; then
  printf '%s\n' \
    '[RV64-SYSTEM-RECERT-LAUNCH][FAIL] Ubuntu 22.04 execution requires --user-authorized-full-ubuntu from an explicit user request' >&2
  exit 2
fi

for numeric_value in \
  "${expected_file_count}" "${host_timeout_seconds}" "${max_cycles}" \
  "${commit_gap_limit_cycles}" "${progress_interval}" "${jobs}"; do
  [[ "${numeric_value}" =~ ^[0-9]+$ ]]
done
[[ "${expected_design_id}" =~ ^sha256:[0-9a-f]{64}$ ]]
(( expected_file_count > 0 ))
(( host_timeout_seconds >= 50400 ))
(( max_cycles >= 6000000000 ))
(( commit_gap_limit_cycles > 0 ))
(( progress_interval > 0 ))
(( jobs > 0 && jobs <= 64 ))

if [[ ! "${run_dir_arg}" =~ ^\.github/task-runs/[A-Za-z0-9][A-Za-z0-9._-]*$ ]]; then
  printf '%s\n' \
    "[RV64-SYSTEM-RECERT-LAUNCH][FAIL] --run-dir must be one new direct task-runs child" >&2
  exit 2
fi
for parent_path in "${repo_root}/.github" "${repo_root}/.github/task-runs"; do
  [[ -d "${parent_path}" && ! -L "${parent_path}" ]]
done

run_label="${run_dir_arg##*/}"
run_dir="${repo_root}/${run_dir_arg}"
result_dir="${run_dir}/system"
status_path="${run_dir}/system.status"
runtime_dir="${runtime_root}/${run_label}"
sandbox_workspace="${runtime_dir}/npc-source-sandbox"
npc_source_sandbox="${sandbox_workspace}/npc/rv64"
build_dir="${runtime_dir}/sim-build"
simulator="${build_dir}/NpcSimTop"
verilator_manifest="${build_dir}/obj_dir/VNpcSimTop__verFiles.dat"
rootfs_run_image="${runtime_dir}/rootfs.ext4"

publish_launcher_failure() {
  local launcher_rc="${1:?launcher return code is required}"
  local launcher_stage="${2:?launcher stage is required}"
  local finalize_rc=0

  source "${status_helper}"
  task_run_status_init "${status_path}"
  task_run_status_stage "${launcher_stage}"
  set +e
  task_run_status_finalize "${launcher_rc}" 0
  finalize_rc=$?
  set -e
  return "${finalize_rc}"
}

if [[ "${mode}" == "launch" ]]; then
  if [[ -e "${run_dir}" || -L "${run_dir}" || -e "${runtime_dir}" || -L "${runtime_dir}" ]]; then
    printf '%s\n' \
      "[RV64-SYSTEM-RECERT-LAUNCH][FAIL] run/runtime already exists: ${run_label}" >&2
    exit 2
  fi
  mkdir -p "$(dirname -- "${lock_path}")" "${runtime_root}"
  [[ ! -L "${runtime_root}" ]]
  if ! flock -n "${lock_path}" true; then
    printf '%s\n' \
      "[RV64-SYSTEM-RECERT-LAUNCH][FAIL] RV64 engineering lane is occupied" >&2
    exit 3
  fi

  mkdir -p "${result_dir}"
  set +e
  validate_contract >"${result_dir}/prelaunch-contract.log" 2>&1
  contract_rc=$?
  set -e
  if [[ "${contract_rc}" -ne 0 ]]; then
    set +e
    publish_launcher_failure "${contract_rc}" "launcher-contract"
    publish_rc=$?
    set -e
    printf '%s\n' \
      "[RV64-SYSTEM-RECERT-LAUNCH][FAIL] contract rc=${publish_rc}" >&2
    exit "${publish_rc}"
  fi

  {
    printf '%s\n' "schema=npc-rv64-system-recertification-launch-v1"
    printf 'run_label=%s\n' "${run_label}"
    printf 'runner=%s\n' "${runner_script}"
    printf 'runtime_dir=%s\n' "${runtime_dir}"
    printf 'lock_path=%s\n' "${lock_path}"
    printf 'expected_design_id=%s\n' "${expected_design_id}"
    printf 'expected_file_count=%s\n' "${expected_file_count}"
    printf 'max_cycles=%s\n' "${max_cycles}"
    printf 'host_timeout_seconds=%s\n' "${host_timeout_seconds}"
    printf 'commit_gap_limit_cycles=%s\n' "${commit_gap_limit_cycles}"
    printf 'progress_interval=%s\n' "${progress_interval}"
    printf 'jobs=%s\n' "${jobs}"
    printf '%s\n' "launch_authorization=explicit-user-request"
    printf '%s\n' "session_mode=setsid-no-tty"
    printf '%s\n' "stdin=dev-null"
    printf '%s\n' "prelaunch_contract=PASS"
  } >"${result_dir}/launch-binding.txt"
  date -Ins >"${result_dir}/launched-at.txt"

  nohup setsid flock -n -E 73 "${lock_path}" \
    "${runner_script}" --execute \
      --run-dir "${run_dir_arg}" \
      --expected-design-id "${expected_design_id}" \
      --expected-file-count "${expected_file_count}" \
      --host-timeout-seconds "${host_timeout_seconds}" \
      --max-cycles "${max_cycles}" \
      --commit-gap-limit-cycles "${commit_gap_limit_cycles}" \
      --progress-interval "${progress_interval}" \
      --jobs "${jobs}" \
      --user-authorized-full-ubuntu \
    >"${result_dir}/launcher.log" 2>&1 </dev/null &
  launcher_pid=$!
  printf '%s\n' "${launcher_pid}" >"${result_dir}/launcher.pid"

  for _ in $(seq 1 300); do
    if [[ -s "${status_path}" ]]; then
      break
    fi
    if ! kill -0 "${launcher_pid}" 2>/dev/null; then
      break
    fi
    sleep 0.1
  done
  if [[ ! -s "${status_path}" ]]; then
    launcher_rc=0
    if kill -0 "${launcher_pid}" 2>/dev/null; then
      kill -TERM -- "-${launcher_pid}" 2>/dev/null || \
        kill -TERM "${launcher_pid}" 2>/dev/null || true
      set +e
      wait "${launcher_pid}"
      set -e
      launcher_rc=124
    else
      set +e
      wait "${launcher_pid}"
      launcher_rc=$?
      set -e
      [[ "${launcher_rc}" -ne 0 ]] || launcher_rc=4
    fi
    set +e
    publish_launcher_failure "${launcher_rc}" "launcher-lock-or-init"
    publish_rc=$?
    set -e
    printf '%s\n' \
      "[RV64-SYSTEM-RECERT-LAUNCH][FAIL] status not published rc=${publish_rc}" >&2
    sed -n '1,100p' "${result_dir}/launcher.log" >&2 || true
    exit "${publish_rc}"
  fi
  status_text="$(sed -n '1p' "${status_path}")"
  if [[ "${status_text}" != "RUNNING" ]]; then
    printf '%s\n' \
      "[RV64-SYSTEM-RECERT-LAUNCH][FAIL] initial status=${status_text}" >&2
    sed -n '1,100p' "${result_dir}/launcher.log" >&2 || true
    exit 5
  fi
  printf '%s\n' \
    "[RV64-SYSTEM-RECERT-LAUNCH] RUNNING run=${run_dir_arg} launcher_pid=${launcher_pid}"
  exit 0
fi

[[ "${mode}" == "execute" ]]
[[ -d "${run_dir}" && ! -L "${run_dir}" ]]
[[ -d "${result_dir}" && ! -L "${result_dir}" ]]
test ! -e "${status_path}"
if flock -n "${lock_path}" true; then
  printf '%s\n' \
    "[RV64-SYSTEM-RECERT][FAIL] internal execute mode lacks single-flight ownership" >&2
  exit 3
fi

linux_image="${repo_root}/Linux/env/platforms/npc/build/linux/arch/riscv/boot/Image"
opensbi_fw="${repo_root}/Linux/env/platforms/npc/build/opensbi/rootfs/platform/generic/firmware/fw_jump.bin"
run_dtb="${repo_root}/Linux/build/riscv64-npc/npc-rv64-rootfs.dtb"
rootfs_template="${repo_root}/Linux/env/platforms/npc/images/ubuntu2204/ubuntu-22.04-riscv64-strict.ext4"
rootfs_cpio="${repo_root}/Linux/env/platforms/npc/images/ubuntu2204/ubuntu-22.04-riscv64-strict-rootfs.cpio"
nemu_reference="${repo_root}/nemu/build/riscv64-nemu-interpreter-so"
capstone_library="${repo_root}/nemu/tools/capstone/repo/libcapstone.so.5"
kconfig_conf="${repo_root}/tool/kconfig/build/conf"
fixdep_bin="${repo_root}/tool/fixdep/build/fixdep"
guest_checker="${repo_root}/Linux/scripts/check-npc-systemd-guest.sh"
rootfs_checker="${repo_root}/Linux/scripts/check-ubuntu-rootfs.sh"
transaction_parser="${repo_root}/Linux/scripts/npc_systemd_transaction_evidence.py"
rootfs_copy_helper="${repo_root}/Linux/scripts/prepare-npc-rootfs-run-image.sh"

config_path="${npc_source_sandbox}/.config"
auto_conf_path="${npc_source_sandbox}/include/config/auto.conf"
autoconf_header_path="${npc_source_sandbox}/include/generated/autoconf.h"

runtime_owned=0
cleanup_signal_rc=0
post_binding_failed=0

declare -A pre_hashes=()
verilator_bin="$(readlink -f "$(command -v verilator)")"
clang_bin="$(readlink -f "$(command -v clang++)")"
make_bin="$(readlink -f "$(command -v make)")"

source "${status_helper}"
task_run_status_init "${status_path}"

run_bounded_log() {
  local full_log="${1:?full log is required}"
  local retained_log="${2:?retained log is required}"
  local command_rc=0
  shift 2
  set +e
  "$@" >"${full_log}" 2>&1
  command_rc=$?
  set -e
  tail -n 400 "${full_log}" >"${retained_log}" 2>/dev/null || true
  return "${command_rc}"
}

record_optional_rg() {
  local output_path="${1:?output path is required}"
  shift
  local query_rc=0
  local input_paths=()
  local argument
  while [[ "$#" -gt 0 ]]; do
    argument="$1"
    shift
    if [[ "${argument}" == "--" ]]; then
      input_paths=("$@")
      break
    fi
  done
  if [[ "${#input_paths[@]}" -eq 0 ]]; then
    : >"${output_path}"
    return 0
  fi
  rg -a -n "${RECORD_RG_PATTERN}" "${input_paths[@]}" \
    >"${output_path}" 2>>"${result_dir}/evidence-query-errors.log" || query_rc=$?
  if [[ "${query_rc}" -eq 0 || "${query_rc}" -eq 1 ]]; then
    return 0
  fi
  printf '%s\n' \
    "[RV64-SYSTEM-RECERT][EVIDENCE-QUERY-FAIL] rc=${query_rc}" \
    >>"${result_dir}/evidence-query-errors.log"
  return "${query_rc}"
}

capture_terminal_evidence() {
  local capture_rc=0
  local query_rc=0
  local scan_paths=()
  local progress_tmp="${result_dir}/.progress-all.tmp.$$"
  local ecall_tmp="${result_dir}/.user-ecall-all.tmp.$$"
  local path
  local assertion_failure_regex
  local terminal_evidence_regex

  assertion_failure_regex='\[(V[0-9]+[A-Z]?-[^]]*(DISJOINT|HANDOFF|INGRESS-DUP|ASSERT[^]]*FAIL)|S2-G1-TCOLL-INGRESS-DUP)\]|%Error:|Assertion failed|RTL assertion|\[[^]]*ASSERT[^]]*FAIL'
  terminal_evidence_regex='OpenSBI v[0-9]|Platform (Reboot|Shutdown) Device|SBI SRST extension detected|__NPC_SYSTEMD_STRICT_(BEGIN|DONE)__|__NPC_SYSTEMD_POWEROFF_BEGIN__|reboot: Power down|syscon-reset: poweroff requested value=0x00005555|exit via system-reset, code=0|HIT GOOD TRAP|npc-systemd-check.*PASS strict guest'

  for path in \
    "${result_dir}/driver.log" \
    "${result_dir}/guest/console.log" \
    "${result_dir}/guest/npc.log"; do
    [[ -f "${path}" ]] && scan_paths+=("${path}")
  done
  : >"${result_dir}/evidence-query-errors.log" || return 1
  RECORD_RG_PATTERN="${terminal_evidence_regex}" \
    record_optional_rg "${result_dir}/terminal-markers.txt" -- "${scan_paths[@]}" || {
      query_rc=$?
      capture_rc="${query_rc}"
    }
  RECORD_RG_PATTERN="${assertion_failure_regex}" \
    record_optional_rg "${result_dir}/rtl-assertion-failures.txt" -- "${scan_paths[@]}" || {
      query_rc=$?
      capture_rc="${query_rc}"
    }
  RECORD_RG_PATTERN='\[progress\]|user_progress|commit-gap' \
    record_optional_rg "${progress_tmp}" -- "${scan_paths[@]}" || {
      query_rc=$?
      capture_rc="${query_rc}"
    }
  tail -n 80 "${progress_tmp}" >"${result_dir}/progress-tail.txt" \
    2>>"${result_dir}/evidence-query-errors.log" || capture_rc=1
  RECORD_RG_PATTERN='user_ecall' \
    record_optional_rg "${ecall_tmp}" -- "${scan_paths[@]}" || {
      query_rc=$?
      capture_rc="${query_rc}"
    }
  tail -n 256 "${ecall_tmp}" >"${result_dir}/user-ecall-tail.txt" \
    2>>"${result_dir}/evidence-query-errors.log" || capture_rc=1
  RECORD_RG_PATTERN='exit via system-reset|total guest instructions|total guest cycles|CPI \(cycles/instruction\)|ooo cycles observed|retire hist|execute hist|dispatch hist|control wait cycles|cycle buckets|mem req0/req1/rsp0/rsp1' \
    record_optional_rg "${result_dir}/system-stats.txt" -- "${scan_paths[@]}" || {
      query_rc=$?
      capture_rc="${query_rc}"
    }
  rm -f -- "${progress_tmp}" "${ecall_tmp}"
  return "${capture_rc}"
}

remember_hash() {
  local label="${1:?hash label is required}"
  local path="${2:?hash path is required}"
  test -f "${path}"
  pre_hashes["${label}"]="$(sha256sum "${path}" | awk '{print $1}')"
}

verify_post_hash() {
  local label="${1:?hash label is required}"
  local path="${2:?hash path is required}"
  local expected="${pre_hashes[${label}]:-}"
  local actual=""
  printf '%s_pre_sha256=%s\n' "${label}" "${expected:-UNAVAILABLE}"
  if [[ -z "${expected}" || ! -f "${path}" ]]; then
    printf '%s_post_sha256=MISSING_OR_PREHASH_UNAVAILABLE\n' "${label}"
    post_binding_failed=1
    return 0
  fi
  actual="$(sha256sum "${path}" | awk '{print $1}')" || {
    printf '%s_post_sha256=HASH_FAILED\n' "${label}"
    post_binding_failed=1
    return 0
  }
  printf '%s_post_sha256=%s\n' "${label}" "${actual}"
  [[ "${actual}" == "${expected}" ]] || post_binding_failed=1
}

build_post_binding() {
  local body="${result_dir}/.post-binding-body.tmp.$$"
  local complete="${result_dir}/.post-binding.tmp.$$"
  post_binding_failed=0
  {
    if [[ ! -s "${result_dir}/input-manifest-before.json" ||
          ! -s "${result_dir}/input-manifest-after.json" ]] ||
       ! cmp -s "${result_dir}/input-manifest-before.json" \
         "${result_dir}/input-manifest-after.json"; then
      post_binding_failed=1
    fi
    verify_post_hash "input_manifest_before" "${result_dir}/input-manifest-before.json"
    verify_post_hash "simulator" "${simulator}"
    verify_post_hash "verilator_manifest" "${verilator_manifest}"
    verify_post_hash "npc_config" "${config_path}"
    verify_post_hash "npc_auto_conf" "${auto_conf_path}"
    verify_post_hash "npc_autoconf_header" "${autoconf_header_path}"
    verify_post_hash "runner_script" "${runner_script}"
    verify_post_hash "summary_tool" "${summary_tool}"
    verify_post_hash "policy" "${policy_path}"
    verify_post_hash "status_helper" "${status_helper}"
    verify_post_hash "guest_checker" "${guest_checker}"
    verify_post_hash "transaction_parser" "${transaction_parser}"
    verify_post_hash "rootfs_copy_helper" "${rootfs_copy_helper}"
    verify_post_hash "rootfs_template" "${rootfs_template}"
    verify_post_hash "rootfs_cpio" "${rootfs_cpio}"
    verify_post_hash "linux_image" "${linux_image}"
    verify_post_hash "opensbi_fw" "${opensbi_fw}"
    verify_post_hash "run_dtb" "${run_dtb}"
    verify_post_hash "nemu_reference" "${nemu_reference}"
    verify_post_hash "capstone_library" "${capstone_library}"
    verify_post_hash "kconfig_conf" "${kconfig_conf}"
    verify_post_hash "fixdep" "${fixdep_bin}"
    verify_post_hash "verilator_tool" "${verilator_bin}"
    verify_post_hash "clang_tool" "${clang_bin}"
    verify_post_hash "make_tool" "${make_bin}"
    verify_post_hash "launch_binding" "${result_dir}/launch-binding.txt"
    verify_post_hash "prelaunch_contract" "${result_dir}/prelaunch-contract.log"
    if [[ -f "${rootfs_run_image}" ]]; then
      printf 'rootfs_runtime_image_present=1\n'
      printf 'rootfs_runtime_image_size_bytes=%s\n' \
        "$(stat -c '%s' "${rootfs_run_image}")"
    else
      printf 'rootfs_runtime_image_present=0\n'
      post_binding_failed=1
    fi
  } >"${body}"
  {
    if [[ "${post_binding_failed}" -eq 0 ]]; then
      printf '%s\n' "binding_status=PASS"
    else
      printf '%s\n' "binding_status=FAIL"
    fi
    cat "${body}"
  } >"${complete}"
  mv -f -- "${complete}" "${result_dir}/post-binding.txt"
  rm -f -- "${body}"
  return "${post_binding_failed}"
}

remove_runtime_products() {
  local resolved_root=""
  local resolved_target=""
  local expected_target=""
  local path_validated=0
  local removed=0
  local remove_rc=0
  resolved_root="$(realpath -m -- "${runtime_root}")" || remove_rc=$?
  resolved_target="$(realpath -m -- "${runtime_dir}")" || remove_rc=$?
  expected_target="${resolved_root}/${run_label}"
  if [[ "${remove_rc}" -eq 0 &&
        "${resolved_target}" == "${expected_target}" &&
        "${resolved_target}" == "${resolved_root}/"* &&
        "${resolved_target}" != "${resolved_root}" ]]; then
    path_validated=1
  else
    remove_rc=2
  fi
  if [[ "${remove_rc}" -eq 0 && "${runtime_owned}" -eq 1 ]]; then
    rm -rf -- "${resolved_target}" || remove_rc=$?
    [[ ! -e "${resolved_target}" ]] || remove_rc=1
  fi
  if [[ "${remove_rc}" -eq 0 && ! -e "${resolved_target}" ]]; then
    removed=1
  fi
  {
    printf 'runtime_path=%s\n' "${resolved_target:-UNRESOLVED}"
    printf 'runtime_path_validated=%s\n' "${path_validated}"
    printf 'runtime_owned=%s\n' "${runtime_owned}"
    printf 'runtime_removed=%s\n' "${removed}"
    printf 'remove_rc=%s\n' "${remove_rc}"
  } >"${result_dir}/runtime-cleanup.txt"
  return "${remove_rc}"
}

note_cleanup_signal() {
  TASK_RUN_STATUS_SIGNAL="${1:?signal name is required}"
  cleanup_signal_rc="${2:?signal return code is required}"
}

finish() {
  local command_rc=$?
  local main_stage="${TASK_RUN_STATUS_STAGE}"
  local capture_rc=0
  local snapshot_rc=0
  local binding_rc=0
  local remove_rc=0
  local summary_rc=0
  local cleanup_rc=0
  local final_rc=0

  trap - EXIT
  trap 'note_cleanup_signal HUP 129' HUP
  trap 'note_cleanup_signal INT 130' INT
  trap 'note_cleanup_signal TERM 143' TERM
  set +e
  capture_terminal_evidence
  capture_rc=$?
  python3 -B "${summary_tool}" --root "${repo_root}" snapshot \
    --output "${result_dir}/input-manifest-after.json" \
    >"${result_dir}/input-manifest-after.log" 2>&1
  snapshot_rc=$?
  build_post_binding
  binding_rc=$?
  remove_runtime_products
  remove_rc=$?

  if [[ "${cleanup_signal_rc}" -ne 0 ]]; then
    cleanup_rc="${cleanup_signal_rc}"
  elif [[ "${capture_rc}" -ne 0 ]]; then
    cleanup_rc="${capture_rc}"
  elif [[ "${snapshot_rc}" -ne 0 ]]; then
    cleanup_rc="${snapshot_rc}"
  elif [[ "${binding_rc}" -ne 0 ]]; then
    cleanup_rc="${binding_rc}"
  elif [[ "${remove_rc}" -ne 0 ]]; then
    cleanup_rc="${remove_rc}"
  fi

  if [[ "${command_rc}" -eq 0 && "${cleanup_rc}" -eq 0 &&
        "${TASK_RUN_STATUS_SIGNAL}" == "none" ]]; then
    python3 -B "${summary_tool}" --root "${repo_root}" summary \
      --result-dir "${result_dir}" \
      --expected-design-id "${expected_design_id}" \
      --expected-file-count "${expected_file_count}" \
      --max-cycles "${max_cycles}" \
      --output "${result_dir}/system-recertification-summary.json" \
      >"${result_dir}/system-recertification-marker.txt" \
      2>"${result_dir}/summary-errors.log"
    summary_rc=$?
    if [[ "${summary_rc}" -eq 0 ]]; then
      task_run_status_stage "evidence-complete"
      task_run_status_mark_evidence_complete
    else
      cleanup_rc="${summary_rc}"
      TASK_RUN_STATUS_STAGE="summary-build"
    fi
  else
    TASK_RUN_STATUS_STAGE="${main_stage}"
  fi

  trap '' HUP INT TERM
  task_run_status_finalize "${command_rc}" "${cleanup_rc}"
  final_rc=$?
  trap - HUP INT TERM
  exit "${final_rc}"
}

trap finish EXIT
task_run_status_install_signal_traps

task_run_status_stage "runner-preflight"
for required_file in \
  "${linux_image}" "${opensbi_fw}" "${run_dtb}" "${rootfs_template}" \
  "${rootfs_cpio}" "${nemu_reference}" "${capstone_library}" \
  "${kconfig_conf}" "${fixdep_bin}" "${guest_checker}" "${rootfs_checker}" \
  "${transaction_parser}" "${rootfs_copy_helper}"; do
  test -s "${required_file}"
  test ! -L "${required_file}"
done
test ! -e "${runtime_dir}"
mkdir -p "${runtime_dir}"
runtime_owned=1

task_run_status_stage "input-binding-pre"
python3 -B "${summary_tool}" --root "${repo_root}" snapshot \
  --output "${result_dir}/input-manifest-before.json" \
  >"${result_dir}/input-manifest-before.log" 2>&1
readarray -t source_identity < <(
  python3 -B - "${result_dir}/input-manifest-before.json" <<'PY'
import json
import sys

data = json.load(open(sys.argv[1], encoding="utf-8"))
print(data.get("design_id", "MISSING"))
print(data.get("production_rtl_file_count", "MISSING"))
PY
)
design_id_pre="${source_identity[0]:-MISSING}"
source_file_count_pre="${source_identity[1]:-MISSING}"
[[ "${design_id_pre}" == "${expected_design_id}" ]]
[[ "${source_file_count_pre}" == "${expected_file_count}" ]]

task_run_status_stage "isolated-source-copy"
mkdir -p "${npc_source_sandbox}"
cp -a -- "${repo_root}/Makefile" "${sandbox_workspace}/Makefile"
cp -a -- \
  "${repo_root}/npc/rv64/Makefile" \
  "${repo_root}/npc/rv64/Kconfig" \
  "${repo_root}/npc/rv64/configs" \
  "${repo_root}/npc/rv64/scripts" \
  "${repo_root}/npc/rv64/csrc" \
  "${repo_root}/npc/rv64/vsrc" \
  "${npc_source_sandbox}/"
cmp -s "${repo_root}/Makefile" "${sandbox_workspace}/Makefile"
python3 -B "${summary_tool}" --root "${repo_root}" verify-sandbox \
  --snapshot "${result_dir}/input-manifest-before.json" \
  --sandbox-root "${npc_source_sandbox}" \
  >"${result_dir}/source-sandbox-check.log" 2>&1

task_run_status_stage "simulator-config-canonical"
run_bounded_log \
  "${runtime_dir}/config-canonical.full.log" \
  "${result_dir}/config-canonical-tail.log" \
  env NEMU_HOME="${repo_root}/nemu" YSYX_HOME="${repo_root}" \
    make -C "${npc_source_sandbox}" \
      WORK_BRANCH=system-recertification-sandbox default_defconfig
test -s "${config_path}"
test -s "${auto_conf_path}"
test -s "${autoconf_header_path}"
grep -Fqx "CONFIG_NPC_DIFFTEST=y" "${config_path}"
grep -Fqx "# CONFIG_NPC_DEBUG_PORTS is not set" "${config_path}"

task_run_status_stage "rootfs-static-check"
run_bounded_log \
  "${runtime_dir}/rootfs-static-check.full.log" \
  "${result_dir}/rootfs-static-check-tail.log" \
  env \
    UBUNTU_ROOTFS_IMAGE="${rootfs_template}" \
    UBUNTU_ROOTFS_REQUIRE_SYSTEMD=1 \
    UBUNTU_ROOTFS_REQUIRE_NPC_CONSOLE_SHELL=1 \
    UBUNTU_ROOTFS_REQUIRE_NPC_STRICT_AUTORUN=1 \
    UBUNTU_ROOTFS_EXPECT_NPC_SYSTEMD_GENERATORS=disabled \
    UBUNTU_ROOTFS_FLAVOR=systemd-minimal \
    bash "${rootfs_checker}"

task_run_status_stage "simulator-build"
run_bounded_log \
  "${runtime_dir}/sim-build.full.log" \
  "${result_dir}/sim-build-tail.log" \
  env NEMU_HOME="${repo_root}/nemu" YSYX_HOME="${repo_root}" \
    make -C "${npc_source_sandbox}" \
      WORK_BRANCH=system-recertification-sandbox \
      BUILD_DIR="${build_dir}" \
      OOO_CSR_QUEUE_HEAD=1 \
      OOO_ASSERT=1 \
      OOO_TERMINAL_HOLDER_ASSERT=1 \
      CXX=/usr/bin/clang++ \
      LINK=/usr/bin/clang++ \
      'VERILATOR=verilator -Wno-fatal' \
      'VERILATOR_OPT_FAST=-O3 -march=native' \
      'VERILATOR_OPT_GLOBAL=-O3 -march=native' \
      -j"${jobs}"
test -x "${simulator}"
test -s "${verilator_manifest}"
grep -Fq -- "--assert" "${verilator_manifest}"
grep -Fq -- "+define+OOO_CSR_QUEUE_HEAD=1 " "${verilator_manifest}"
grep -Fq -- "+define+OOO_ASSERT " "${verilator_manifest}"
grep -Fq -- "+define+OOO_TERMINAL_HOLDER_ASSERT " "${verilator_manifest}"
cp -- "${verilator_manifest}" "${result_dir}/simulator-verFiles.dat"
{
  printf '%s\n' "verilator_assertions=enabled"
  printf '%s\n' "OOO_CSR_QUEUE_HEAD=1"
  printf '%s\n' "OOO_ASSERT=1"
  printf '%s\n' "OOO_TERMINAL_HOLDER_ASSERT=1"
} >"${result_dir}/simulator-defines.txt"
{
  printf 'verilator_path=%s\n' "${verilator_bin}"
  verilator --version
  printf 'verilator_sha256=%s\n' "$(sha256sum "${verilator_bin}" | awk '{print $1}')"
  printf 'clang_path=%s\n' "${clang_bin}"
  clang++ --version | sed -n '1,2p'
  printf 'clang_sha256=%s\n' "$(sha256sum "${clang_bin}" | awk '{print $1}')"
  printf 'make_path=%s\n' "${make_bin}"
  make --version | sed -n '1p'
  printf 'make_sha256=%s\n' "$(sha256sum "${make_bin}" | awk '{print $1}')"
} >"${result_dir}/tool-versions.txt"

task_run_status_stage "system-input-binding"
for pair in \
  "input_manifest_before:${result_dir}/input-manifest-before.json" \
  "simulator:${simulator}" \
  "verilator_manifest:${verilator_manifest}" \
  "npc_config:${config_path}" \
  "npc_auto_conf:${auto_conf_path}" \
  "npc_autoconf_header:${autoconf_header_path}" \
  "runner_script:${runner_script}" \
  "summary_tool:${summary_tool}" \
  "policy:${policy_path}" \
  "status_helper:${status_helper}" \
  "guest_checker:${guest_checker}" \
  "transaction_parser:${transaction_parser}" \
  "rootfs_copy_helper:${rootfs_copy_helper}" \
  "rootfs_template:${rootfs_template}" \
  "rootfs_cpio:${rootfs_cpio}" \
  "linux_image:${linux_image}" \
  "opensbi_fw:${opensbi_fw}" \
  "run_dtb:${run_dtb}" \
  "nemu_reference:${nemu_reference}" \
  "capstone_library:${capstone_library}" \
  "kconfig_conf:${kconfig_conf}" \
  "fixdep:${fixdep_bin}" \
  "verilator_tool:${verilator_bin}" \
  "clang_tool:${clang_bin}" \
  "make_tool:${make_bin}" \
  "launch_binding:${result_dir}/launch-binding.txt" \
  "prelaunch_contract:${result_dir}/prelaunch-contract.log"; do
  remember_hash "${pair%%:*}" "${pair#*:}"
done

{
  printf '%s\n' "schema=npc-rv64-system-recertification-binding-v1"
  printf 'run_label=%s\n' "${run_label}"
  printf 'rtl_design_id=%s\n' "${design_id_pre}"
  printf 'production_rtl_file_count=%s\n' "${source_file_count_pre}"
  printf 'simulator_sha256=%s\n' "${pre_hashes[simulator]}"
  printf 'verilator_manifest_sha256=%s\n' "${pre_hashes[verilator_manifest]}"
  printf 'nemu_reference_sha256=%s\n' "${pre_hashes[nemu_reference]}"
  printf 'npc_config_sha256=%s\n' "${pre_hashes[npc_config]}"
  printf 'npc_auto_conf_sha256=%s\n' "${pre_hashes[npc_auto_conf]}"
  printf 'npc_autoconf_header_sha256=%s\n' "${pre_hashes[npc_autoconf_header]}"
  printf 'rootfs_template_sha256=%s\n' "${pre_hashes[rootfs_template]}"
  printf 'rootfs_cpio_sha256=%s\n' "${pre_hashes[rootfs_cpio]}"
  printf 'linux_image_sha256=%s\n' "${pre_hashes[linux_image]}"
  printf 'opensbi_fw_sha256=%s\n' "${pre_hashes[opensbi_fw]}"
  printf 'run_dtb_sha256=%s\n' "${pre_hashes[run_dtb]}"
  printf 'host_timeout_seconds=%s\n' "${host_timeout_seconds}"
  printf 'max_cycles=%s\n' "${max_cycles}"
  printf 'commit_gap_limit_cycles=%s\n' "${commit_gap_limit_cycles}"
  printf 'progress_interval=%s\n' "${progress_interval}"
  printf 'jobs=%s\n' "${jobs}"
  printf '%s\n' "OOO_CSR_QUEUE_HEAD=1"
  printf '%s\n' "OOO_ASSERT=1"
  printf '%s\n' "OOO_TERMINAL_HOLDER_ASSERT=1"
  printf '%s\n' "NPC_SYSTEMD_GUEST_COMMAND_MODE=systemd-strict"
  printf '%s\n' "uart_rx_bytes=0"
} >"${result_dir}/binding.txt"

task_run_status_stage "systemd-strict-guest"
NPC_COMMIT_GAP_LIMIT_CYCLES="${commit_gap_limit_cycles}" \
NPC_USER_PROGRESS_INTERVAL="${progress_interval}" \
NPC_USER_PROGRESS_LIMIT=512 \
NPC_USER_ECALL_TRACE=1 \
NPC_USER_ECALL_TRACE_PRIV=1 \
NPC_USER_ECALL_MIN_COMMIT=1100000000 \
NPC_USER_ECALL_TRACE_LIMIT=8192 \
NPC_USER_ECALL_PATH_TRACE=0 \
NPC_SYSTEMD_HOST_TIMEOUT="${host_timeout_seconds}" \
NPC_SYSTEMD_CHECK_MAX_CYCLES="${max_cycles}" \
NPC_SYSTEMD_ROOTFS_WORK_IMAGE="${rootfs_run_image}" \
NPC_SYSTEMD_ROOTFS_EXPECTED_TEMPLATE_SHA256="${pre_hashes[rootfs_template]}" \
NPC_SYSTEMD_GUEST_COMMAND_MODE=systemd-strict \
NPC_SYSTEMD_REQUIRE_PROMPT=0 \
NPC_SYSTEMD_STRICT_CHECK=1 \
NPC_SYSTEMD_GUEST_POWEROFF=1 \
NPC_SYSTEMD_UART_TRACE=1 \
NPC_SYSTEMD_UART_TRACE_LIMIT=128 \
NPC_SYSTEMD_PROGRESS="${progress_interval}" \
NPC_SYSTEMD_TRANSACTION_EVIDENCE="${result_dir}/systemd-transaction-evidence.json" \
LOG_DIR="${result_dir}/guest" \
CONSOLE_LOG="${result_dir}/guest/console.log" \
NPC_LOG="${result_dir}/guest/npc.log" \
NPC_SIM="${simulator}" \
LINUX_IMAGE="${linux_image}" \
RUN_FW="${opensbi_fw}" \
RUN_DTB="${run_dtb}" \
RUN_ROOTFS="${rootfs_template}" \
NEXT_ADDR=0x80200000 \
DTB_ADDR=0x82200000 \
  bash "${guest_checker}" >"${result_dir}/driver.log" 2>&1

task_run_status_stage "systemd-strict-transaction"
python3 -B - "${result_dir}/systemd-transaction-evidence.json" <<'PY'
import json
import sys

data = json.load(open(sys.argv[1], encoding="utf-8"))
stages = {stage.get("name"): stage for stage in data.get("stages", [])}
expected = {"preflight": 6, "autocheck": 6, "strict": 17}
if data.get("status") != "PASS" or set(stages) != set(expected):
    raise SystemExit("transaction stage set/status mismatch")
for name, count in expected.items():
    stage = stages[name]
    if (
        stage.get("status") != "PASS"
        or stage.get("done_rc") != 0
        or stage.get("pass_observation_count") != count
        or len(stage.get("expected_pass_labels", [])) != count
    ):
        raise SystemExit(f"transaction stage mismatch: {name}")
print("[RV64-SYSTEM-RECERT-TRANSACTION] preflight=6/6 autocheck=6/6 strict=17/17 PASS")
PY
grep -Fqx \
  "[npc-systemd-check] PASS strict guest + natural poweroff (mode=systemd-strict)" \
  "${result_dir}/driver.log"
grep -F "loaded bytes=0 file_bytes=0 text_bytes=0" \
  "${result_dir}/guest/console.log" >/dev/null
grep -F "rootfs_template_sha256_pre=${pre_hashes[rootfs_template]}" \
  "${result_dir}/guest/rootfs-binding.txt" >/dev/null
grep -F "rootfs_run_image_sha256_pre=${pre_hashes[rootfs_template]}" \
  "${result_dir}/guest/rootfs-binding.txt" >/dev/null
uart_scan_rc=0
rg -a -q 'uart-rx\][[:space:]]+pop=' \
  "${result_dir}/guest/console.log" "${result_dir}/guest/npc.log" || uart_scan_rc=$?
if [[ "${uart_scan_rc}" -eq 0 ]]; then
  printf '%s\n' "[RV64-SYSTEM-RECERT][FAIL] unexpected UART RX byte" >&2
  exit 1
elif [[ "${uart_scan_rc}" -ne 1 ]]; then
  printf '%s\n' \
    "[RV64-SYSTEM-RECERT][FAIL] UART evidence query rc=${uart_scan_rc}" >&2
  exit "${uart_scan_rc}"
fi

task_run_status_stage "systemd-strict-complete"
printf '%s\n' \
  "[RV64-SYSTEM-RECERT] current RV64 system transaction complete; finalizing evidence"
