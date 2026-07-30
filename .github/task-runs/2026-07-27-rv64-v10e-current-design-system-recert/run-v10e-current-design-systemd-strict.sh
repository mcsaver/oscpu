#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
task_run_dir="${repo_root}/.github/task-runs/2026-07-27-rv64-v10e-current-design-system-recert"
run_label="${V10E_RECERT_RUN_LABEL:-rootfs-5f9dd068-systemd-strict-6b-a4}"
result_dir="${task_run_dir}/${run_label}"
status_path="${task_run_dir}/${run_label}.status"
prelaunch_contract_log="${result_dir}/prelaunch-contract.log"
runner_contract="${task_run_dir}/test-runner-contract.py"
runtime_dir="${repo_root}/.github/runtime-artifacts/rv64-systemd-strict/${run_label}"
build_dir="${runtime_dir}/sim-build"
simulator="${build_dir}/NpcSimTop"
verilator_manifest="${build_dir}/obj_dir/VNpcSimTop__verFiles.dat"
config_path="${repo_root}/npc/rv64/.config"
auto_conf_path="${repo_root}/npc/rv64/include/config/auto.conf"
autoconf_header_path="${repo_root}/npc/rv64/include/generated/autoconf.h"
linux_image="${repo_root}/Linux/env/platforms/npc/build/linux/arch/riscv/boot/Image"
opensbi_fw="${repo_root}/Linux/env/platforms/npc/build/opensbi/rootfs/platform/generic/firmware/fw_jump.bin"
run_dtb="${repo_root}/Linux/build/riscv64-npc/npc-rv64-rootfs.dtb"
rootfs_template="${repo_root}/Linux/env/platforms/npc/images/ubuntu2204/ubuntu-22.04-riscv64-strict.ext4"
rootfs_cpio="${repo_root}/Linux/env/platforms/npc/images/ubuntu2204/ubuntu-22.04-riscv64-strict-rootfs.cpio"
rootfs_run_image="${runtime_dir}/rootfs.ext4"
expected_design_sha="5f9dd06860a91dfc5461357c731fa2d4c34b91cb3b3cdedc754f0972f8bf4c5a"
host_timeout_seconds="${V10E_RECERT_HOST_TIMEOUT_SECONDS:-100000}"
max_cycles="${V10E_RECERT_MAX_CYCLES:-6000000000}"
min_max_cycles="6000000000"
commit_gap_limit_cycles="${V10E_RECERT_COMMIT_GAP_LIMIT_CYCLES:-1000000}"
progress_interval="${V10E_RECERT_PROGRESS_INTERVAL:-5000000}"
status_helper="${repo_root}/scripts/task-run-status.sh"
guest_checker="${repo_root}/Linux/scripts/check-npc-systemd-guest.sh"
strict_checker="${repo_root}/Linux/scripts/npc-systemd-strict-check.sh"
transaction_parser="${repo_root}/Linux/scripts/npc_systemd_transaction_evidence.py"
rootfs_copy_helper="${repo_root}/Linux/scripts/prepare-npc-rootfs-run-image.sh"
strict_checker_test="${repo_root}/Linux/scripts/tests/test_npc_systemd_strict_check.py"
guest_checker_test="${repo_root}/Linux/scripts/tests/test_check_npc_systemd_guest_contract.py"
transaction_parser_test="${repo_root}/Linux/scripts/tests/test_npc_systemd_transaction_evidence.py"
debug_flags_contract="${repo_root}/npc/rv64/testbench/scripts/test_debug_ooo_flags_contract.py"
assertion_failure_regex='\[(V9Q-(BRIDGE-HOLDER|TRANSIENT-HOLDER|TRANSIENT-BRIDGE|DUAL-REQ-TOKEN)-DISJOINT|V9R-(MEM-)?SQ-RETRY-C0-HANDOFF|S2-G1-TCOLL-INGRESS-DUP|V10D-[^]]*FAIL)\]|%Error:|Assertion failed|RTL assertion|\[.*ASSERT.*FAIL'
terminal_evidence_regex='OpenSBI v[0-9]|Platform (Reboot|Shutdown) Device|SBI SRST extension detected|__NPC_SYSTEMD_STRICT_(BEGIN|DONE)__|__NPC_SYSTEMD_POWEROFF_BEGIN__|reboot: Power down|syscon-reset: poweroff requested value=0x00005555|exit via system-reset, code=0|HIT GOOD TRAP|npc-systemd-check.*PASS strict guest'
rootfs_template_sha=""
rootfs_cpio_sha=""
simulator_sha_pre=""
design_sha_pre=""
config_sha_pre=""
auto_conf_sha_pre=""
autoconf_header_sha_pre=""
npc_makefile_sha_pre=""
verilator_manifest_sha_pre=""
linux_image_sha_pre=""
opensbi_fw_sha_pre=""
run_dtb_sha_pre=""
runner_sha_pre=""
status_helper_sha_pre=""
linux_makefile_sha_pre=""
guest_checker_sha_pre=""
strict_checker_sha_pre=""
transaction_parser_sha_pre=""
rootfs_copy_helper_sha_pre=""
prelaunch_contract_sha_pre=""
runner_contract_sha_pre=""
strict_checker_test_sha_pre=""
guest_checker_test_sha_pre=""
transaction_parser_test_sha_pre=""
debug_flags_contract_sha_pre=""
config_restored=0

case "${run_label}" in
  *[!A-Za-z0-9._-]*|"")
    printf '%s\n' "[V10E-RECERT] invalid run label: ${run_label}" >&2
    exit 2
    ;;
esac
test -f "${status_helper}"
test ! -e "${status_path}"
test ! -e "${runtime_dir}"
command -v sha256sum >/dev/null
runner_sha_pre="$(
  sha256sum \
    "${task_run_dir}/run-v10e-current-design-systemd-strict.sh" |
    awk '{print $1}'
)"
status_helper_sha_pre="$(sha256sum "${status_helper}" | awk '{print $1}')"

mkdir -p "${result_dir}"
source "${status_helper}"
task_run_status_init "${status_path}"

restore_npc_config() {
  local rc=0
  if [[ "${config_restored}" -eq 0 ]]; then
    if make -C "${repo_root}/npc/rv64" default_defconfig \
      >"${result_dir}/config-restore.log" 2>&1; then
      config_restored=1
    else
      rc=$?
    fi
  fi
  return "${rc}"
}

verify_post_hash() {
  local label="${1:?hash label is required}"
  local path="${2:?artifact path is required}"
  local expected="${3:-}"
  local actual=""

  printf '%s_pre_sha256=%s\n' "${label}" "${expected:-UNAVAILABLE}"
  if [[ -z "${expected}" ]]; then
    printf '%s_post_sha256=PREHASH_UNAVAILABLE\n' "${label}"
    binding_rc=1
    return 0
  fi
  if [[ ! -f "${path}" ]]; then
    printf '%s_post_sha256=MISSING\n' "${label}"
    binding_rc=1
    return 0
  fi
  if ! actual="$(sha256sum "${path}" | awk '{print $1}')"; then
    printf '%s_post_sha256=HASH_FAILED\n' "${label}"
    binding_rc=1
    return 0
  fi
  printf '%s_post_sha256=%s\n' "${label}" "${actual}"
  if [[ "${actual}" != "${expected}" ]]; then
    binding_rc=1
  fi
}

record_optional_rg() {
  local output_path="${1:?output path is required}"
  shift
  local rg_rc=0

  rg "$@" >"${output_path}" \
    2>>"${result_dir}/evidence-query-errors.log" || rg_rc=$?
  if [[ "${rg_rc}" -eq 0 || "${rg_rc}" -eq 1 ]]; then
    return 0
  fi
  printf '%s\n' \
    "[V10E-RECERT][EVIDENCE-QUERY-FAIL] rc=${rg_rc} output=${output_path}" \
    >>"${result_dir}/evidence-query-errors.log"
  return "${rg_rc}"
}

count_fixed_terminal_occurrences() {
  local label="${1:?terminal label is required}"
  local marker="${2:?terminal marker is required}"
  local path="${3:?terminal log path is required}"
  local matches=""
  local query_rc=0

  matches="$(
    grep -a -F -o -- "${marker}" "${path}" \
      2>>"${result_dir}/evidence-query-errors.log"
  )" || query_rc=$?
  if [[ "${query_rc}" -eq 1 ]]; then
    printf '0\n'
    return 0
  fi
  if [[ "${query_rc}" -ne 0 ]]; then
    printf '%s\n' \
      "[V10E-RECERT][TERMINAL-QUERY-FAIL] label=${label} rc=${query_rc}" \
      >&2
    return "${query_rc}"
  fi
  printf '%s\n' "${matches}" | wc -l
}

capture_terminal_evidence() {
  local capture_rc=0
  local query_rc=0
  local progress_all="${result_dir}/progress-all.txt"
  local ecall_all="${result_dir}/user-ecall-all.txt"

  : >"${result_dir}/evidence-query-errors.log" || return
  record_optional_rg \
    "${result_dir}/terminal-markers.txt" \
    -a -n \
    "${terminal_evidence_regex}" \
    "${result_dir}/driver.log" "${result_dir}/guest" || {
      query_rc=$?
      capture_rc="${query_rc}"
    }
  record_optional_rg \
    "${result_dir}/rtl-assertion-failures.txt" \
    -a -n \
    "${assertion_failure_regex}" \
    "${result_dir}/driver.log" "${result_dir}/guest" || {
      query_rc=$?
      capture_rc="${query_rc}"
    }
  record_optional_rg \
    "${progress_all}" \
    -a '\\[progress\\]|user_progress|commit-gap' \
    "${result_dir}/guest/console.log" "${result_dir}/guest/npc.log" || {
      query_rc=$?
      capture_rc="${query_rc}"
    }
  if ! tail -n 80 "${progress_all}" >"${result_dir}/progress-tail.txt" \
      2>>"${result_dir}/evidence-query-errors.log"; then
    capture_rc=1
  fi
  record_optional_rg \
    "${ecall_all}" \
    -a 'user_ecall' \
    "${result_dir}/guest/console.log" "${result_dir}/guest/npc.log" || {
      query_rc=$?
      capture_rc="${query_rc}"
    }
  if ! tail -n 256 "${ecall_all}" >"${result_dir}/user-ecall-tail.txt" \
      2>>"${result_dir}/evidence-query-errors.log"; then
    capture_rc=1
  fi
  return "${capture_rc}"
}

defer_cleanup_signal() {
  local signal_name="${1:?signal name is required}"
  local signal_rc="${2:?signal return code is required}"

  TASK_RUN_STATUS_SIGNAL="${signal_name}"
  cleanup_signal_rc="${signal_rc}"
}

finish() {
  local command_rc=$?
  local cleanup_rc=0
  local capture_rc=0
  local restore_rc=0
  local binding_rc=0
  local post_binding_rc=0
  local cleanup_signal_rc=0
  local post_binding_tmp="${result_dir}/post-binding.txt.tmp.$$"
  local final_rc

  trap 'defer_cleanup_signal CLEANUP 143' HUP INT TERM
  trap - EXIT
  if [[ "${TASK_RUN_STATUS_SIGNAL}" != "none" ]]; then
    cleanup_signal_rc="${command_rc}"
  fi
  trap 'defer_cleanup_signal HUP 129' HUP
  trap 'defer_cleanup_signal INT 130' INT
  trap 'defer_cleanup_signal TERM 143' TERM
  set +e
  capture_terminal_evidence
  capture_rc=$?
  if {
    printf 'rootfs_template_pre_sha256=%s\n' \
      "${rootfs_template_sha:-UNAVAILABLE}"
    if [[ -s "${rootfs_template}" ]]; then
      rootfs_template_post_sha="$(sha256sum "${rootfs_template}" | awk '{print $1}')"
      printf 'rootfs_template_post_sha256=%s\n' "${rootfs_template_post_sha}"
      if [[ -n "${rootfs_template_sha}" &&
            "${rootfs_template_post_sha}" != "${rootfs_template_sha}" ]]; then
        binding_rc=1
      fi
    else
      printf '%s\n' "rootfs_template_post_sha256=MISSING"
      binding_rc=1
    fi
    printf 'rootfs_cpio_pre_sha256=%s\n' "${rootfs_cpio_sha:-UNAVAILABLE}"
    if [[ -s "${rootfs_cpio}" ]]; then
      rootfs_cpio_post_sha="$(sha256sum "${rootfs_cpio}" | awk '{print $1}')"
      printf 'rootfs_cpio_post_sha256=%s\n' "${rootfs_cpio_post_sha}"
      if [[ -n "${rootfs_cpio_sha}" &&
            "${rootfs_cpio_post_sha}" != "${rootfs_cpio_sha}" ]]; then
        binding_rc=1
      fi
    else
      printf '%s\n' "rootfs_cpio_post_sha256=MISSING"
      binding_rc=1
    fi
    if [[ -z "${design_sha_pre}" ]]; then
      printf '%s\n' "rtl_design_id_post=PREHASH_UNAVAILABLE"
      binding_rc=1
    elif design_sha_post="$(
        python3 - "${repo_root}" <<'PY'
import pathlib
import sys

root = pathlib.Path(sys.argv[1]).resolve()
sys.path.insert(0, str(root / "npc/rv64/eval/ppa/tools"))
import architecture_hard_gates as arch

print(arch.rtl_binding(root)[0])
PY
      )"; then
      printf 'rtl_design_id_post=sha256:%s\n' "${design_sha_post}"
      [[ "${design_sha_post}" == "${design_sha_pre}" ]] || binding_rc=1
    else
      printf '%s\n' "rtl_design_id_post=HASH_FAILED"
      binding_rc=1
    fi
    if [[ -z "${simulator_sha_pre}" ]]; then
      printf '%s\n' "simulator_sha256_post=PREHASH_UNAVAILABLE"
      binding_rc=1
    elif [[ ! -x "${simulator}" ]]; then
      printf '%s\n' "simulator_sha256_post=MISSING_OR_NOT_EXECUTABLE"
      binding_rc=1
    elif simulator_sha_post="$(sha256sum "${simulator}" | awk '{print $1}')"; then
      printf 'simulator_sha256_post=%s\n' "${simulator_sha_post}"
      [[ "${simulator_sha_post}" == "${simulator_sha_pre}" ]] || binding_rc=1
    else
      printf '%s\n' "simulator_sha256_post=HASH_FAILED"
      binding_rc=1
    fi
    verify_post_hash "npc_config" "${config_path}" "${config_sha_pre}"
    verify_post_hash "npc_auto_conf" "${auto_conf_path}" "${auto_conf_sha_pre}"
    verify_post_hash \
      "npc_autoconf_header" "${autoconf_header_path}" \
      "${autoconf_header_sha_pre}"
    verify_post_hash \
      "npc_makefile" "${repo_root}/npc/rv64/Makefile" \
      "${npc_makefile_sha_pre}"
    verify_post_hash \
      "verilator_manifest" "${verilator_manifest}" \
      "${verilator_manifest_sha_pre}"
    verify_post_hash "linux_image" "${linux_image}" "${linux_image_sha_pre}"
    verify_post_hash "opensbi_fw" "${opensbi_fw}" "${opensbi_fw_sha_pre}"
    verify_post_hash "run_dtb" "${run_dtb}" "${run_dtb_sha_pre}"
    verify_post_hash \
      "runner_script" \
      "${task_run_dir}/run-v10e-current-design-systemd-strict.sh" \
      "${runner_sha_pre}"
    verify_post_hash \
      "task_run_status_helper" "${status_helper}" \
      "${status_helper_sha_pre}"
    verify_post_hash \
      "linux_makefile" "${repo_root}/Linux/Makefile" \
      "${linux_makefile_sha_pre}"
    verify_post_hash \
      "guest_checker" "${guest_checker}" \
      "${guest_checker_sha_pre}"
    verify_post_hash \
      "strict_checker" "${strict_checker}" \
      "${strict_checker_sha_pre}"
    verify_post_hash \
      "transaction_parser" "${transaction_parser}" \
      "${transaction_parser_sha_pre}"
    verify_post_hash \
      "rootfs_copy_helper" "${rootfs_copy_helper}" \
      "${rootfs_copy_helper_sha_pre}"
    verify_post_hash \
      "prelaunch_contract_log" "${prelaunch_contract_log}" \
      "${prelaunch_contract_sha_pre}"
    verify_post_hash \
      "runner_contract" "${runner_contract}" \
      "${runner_contract_sha_pre}"
    verify_post_hash \
      "strict_checker_test" "${strict_checker_test}" \
      "${strict_checker_test_sha_pre}"
    verify_post_hash \
      "guest_checker_test" "${guest_checker_test}" \
      "${guest_checker_test_sha_pre}"
    verify_post_hash \
      "transaction_parser_test" "${transaction_parser_test}" \
      "${transaction_parser_test_sha_pre}"
    verify_post_hash \
      "debug_flags_contract" "${debug_flags_contract}" \
      "${debug_flags_contract_sha_pre}"
  } >"${post_binding_tmp}"; then
    mv -f -- "${post_binding_tmp}" \
      "${result_dir}/post-binding.txt" || post_binding_rc=$?
  else
    post_binding_rc=$?
  fi
  restore_npc_config
  restore_rc=$?
  if [[ "${cleanup_signal_rc}" -ne 0 ]]; then
    cleanup_rc="${cleanup_signal_rc}"
  elif [[ "${restore_rc}" -ne 0 ]]; then
    cleanup_rc="${restore_rc}"
  elif [[ "${capture_rc}" -ne 0 ]]; then
    cleanup_rc="${capture_rc}"
  elif [[ "${post_binding_rc}" -ne 0 ]]; then
    cleanup_rc="${post_binding_rc}"
  elif [[ "${binding_rc}" -ne 0 ]]; then
    cleanup_rc="${binding_rc}"
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
for numeric_value in \
  "${host_timeout_seconds}" "${max_cycles}" \
  "${commit_gap_limit_cycles}" "${progress_interval}"; do
  [[ "${numeric_value}" =~ ^[0-9]+$ ]]
done
(( host_timeout_seconds >= 50400 ))
(( max_cycles >= min_max_cycles ))
(( commit_gap_limit_cycles > 0 ))
(( progress_interval > 0 ))
command -v rg >/dev/null
command -v sha256sum >/dev/null
command -v python3 >/dev/null
command -v make >/dev/null
command -v grep >/dev/null
command -v tail >/dev/null
test -r "${guest_checker}"
test -s "${guest_checker}"
test -x "${strict_checker}"
test -x "${transaction_parser}"
test -x "${rootfs_copy_helper}"
test -s "${prelaunch_contract_log}"
test -s "${runner_contract}"
test -s "${strict_checker_test}"
test -s "${guest_checker_test}"
test -s "${transaction_parser_test}"
test -s "${debug_flags_contract}"
status_helper_sha_after_source="$(
  sha256sum "${status_helper}" | awk '{print $1}'
)"
runner_sha_after_start="$(
  sha256sum \
    "${task_run_dir}/run-v10e-current-design-systemd-strict.sh" |
    awk '{print $1}'
)"
[[ "${status_helper_sha_after_source}" == "${status_helper_sha_pre}" ]]
[[ "${runner_sha_after_start}" == "${runner_sha_pre}" ]]
npc_makefile_sha_pre="$(
  sha256sum "${repo_root}/npc/rv64/Makefile" | awk '{print $1}'
)"
linux_makefile_sha_pre="$(
  sha256sum "${repo_root}/Linux/Makefile" | awk '{print $1}'
)"
guest_checker_sha_pre="$(sha256sum "${guest_checker}" | awk '{print $1}')"
strict_checker_sha_pre="$(sha256sum "${strict_checker}" | awk '{print $1}')"
transaction_parser_sha_pre="$(
  sha256sum "${transaction_parser}" | awk '{print $1}'
)"
rootfs_copy_helper_sha_pre="$(
  sha256sum "${rootfs_copy_helper}" | awk '{print $1}'
)"
prelaunch_contract_sha_pre="$(
  sha256sum "${prelaunch_contract_log}" | awk '{print $1}'
)"
runner_contract_sha_pre="$(sha256sum "${runner_contract}" | awk '{print $1}')"
strict_checker_test_sha_pre="$(
  sha256sum "${strict_checker_test}" | awk '{print $1}'
)"
guest_checker_test_sha_pre="$(
  sha256sum "${guest_checker_test}" | awk '{print $1}'
)"
transaction_parser_test_sha_pre="$(
  sha256sum "${transaction_parser_test}" | awk '{print $1}'
)"
debug_flags_contract_sha_pre="$(
  sha256sum "${debug_flags_contract}" | awk '{print $1}'
)"

task_run_status_stage "simulator-config-canonical"
make -C "${repo_root}/npc/rv64" default_defconfig \
  >"${result_dir}/config-canonical.log" 2>&1
test -s "${config_path}"
test -s "${auto_conf_path}"
test -s "${autoconf_header_path}"
grep -Fqx "CONFIG_NPC_DIFFTEST=y" "${config_path}"
grep -Fqx "# CONFIG_NPC_DEBUG_PORTS is not set" "${config_path}"
config_sha_pre="$(sha256sum "${config_path}" | awk '{print $1}')"
auto_conf_sha_pre="$(sha256sum "${auto_conf_path}" | awk '{print $1}')"
autoconf_header_sha_pre="$(
  sha256sum "${autoconf_header_path}" | awk '{print $1}'
)"

task_run_status_stage "rootfs-template-rebuild"
make -C "${repo_root}/Linux" \
  ARCH=riscv64-npc \
  ubuntu-rootfs-systemd-strict-image \
  >"${result_dir}/rootfs-build.log" 2>&1
test -s "${rootfs_template}"
test -s "${rootfs_cpio}"
rootfs_template_sha="$(sha256sum "${rootfs_template}" | awk '{print $1}')"
rootfs_cpio_sha="$(sha256sum "${rootfs_cpio}" | awk '{print $1}')"

task_run_status_stage "rootfs-static-check"
make -C "${repo_root}/Linux" \
  ARCH=riscv64-npc \
  check-ubuntu-rootfs-systemd-strict \
  >"${result_dir}/rootfs-check.log" 2>&1

task_run_status_stage "rtl-binding-pre"
design_sha_pre="$(
  python3 - "${repo_root}" <<'PY'
import pathlib
import sys

root = pathlib.Path(sys.argv[1]).resolve()
sys.path.insert(0, str(root / "npc/rv64/eval/ppa/tools"))
import architecture_hard_gates as arch

print(arch.rtl_binding(root)[0])
PY
)"
[[ "${design_sha_pre}" == "${expected_design_sha}" ]]

task_run_status_stage "simulator-build"
mkdir -p "${runtime_dir}"
make -C "${repo_root}/npc/rv64" \
  BUILD_DIR="${build_dir}" \
  OOO_CSR_QUEUE_HEAD=1 \
  OOO_TERMINAL_HOLDER_ASSERT=1 \
  CXX=/usr/bin/clang++ \
  LINK=/usr/bin/clang++ \
  VERILATOR='verilator -Wno-fatal' \
  VERILATOR_OPT_FAST='-O3 -march=native' \
  VERILATOR_OPT_GLOBAL='-O3 -march=native' \
  >"${result_dir}/sim-build.log" 2>&1
test -x "${simulator}"
simulator_sha_pre="$(sha256sum "${simulator}" | awk '{print $1}')"

task_run_status_stage "simulator-define-binding"
test -s "${verilator_manifest}"
grep -Fq -- "--assert" "${verilator_manifest}"
grep -Fq -- "+define+OOO_CSR_QUEUE_HEAD=1 " "${verilator_manifest}"
grep -Fq -- "+define+OOO_ASSERT " "${verilator_manifest}"
grep -Fq -- "+define+OOO_TERMINAL_HOLDER_ASSERT " \
  "${verilator_manifest}"
{
  printf '%s\n' "verilator_assertions=enabled"
  printf '%s\n' "OOO_CSR_QUEUE_HEAD=1"
  printf '%s\n' "OOO_ASSERT=1"
  printf '%s\n' "OOO_TERMINAL_HOLDER_ASSERT=1"
} >"${result_dir}/simulator-defines.txt"

task_run_status_stage "evidence-binding-pre"
test -s "${linux_image}"
test -s "${opensbi_fw}"
test -s "${run_dtb}"
verilator_manifest_sha_pre="$(
  sha256sum "${verilator_manifest}" | awk '{print $1}'
)"
linux_image_sha_pre="$(sha256sum "${linux_image}" | awk '{print $1}')"
opensbi_fw_sha_pre="$(sha256sum "${opensbi_fw}" | awk '{print $1}')"
run_dtb_sha_pre="$(sha256sum "${run_dtb}" | awk '{print $1}')"
{
  printf 'git_head=%s\n' "$(git -C "${repo_root}" rev-parse HEAD)"
  printf 'git_branch=%s\n' "$(git -C "${repo_root}" branch --show-current)"
  printf 'rtl_design_id=sha256:%s\n' "${design_sha_pre}"
  printf 'simulator_sha256=%s\n' "${simulator_sha_pre}"
  printf 'npc_config_sha256=%s\n' "${config_sha_pre}"
  printf 'npc_auto_conf_sha256=%s\n' "${auto_conf_sha_pre}"
  printf 'npc_autoconf_header_sha256=%s\n' "${autoconf_header_sha_pre}"
  printf 'npc_makefile_sha256=%s\n' "${npc_makefile_sha_pre}"
  printf 'verilator_manifest_sha256=%s\n' "${verilator_manifest_sha_pre}"
  printf 'linux_image_sha256=%s\n' "${linux_image_sha_pre}"
  printf 'opensbi_fw_sha256=%s\n' "${opensbi_fw_sha_pre}"
  printf 'run_dtb_sha256=%s\n' "${run_dtb_sha_pre}"
  printf 'runner_sha256=%s\n' "${runner_sha_pre}"
  printf 'status_helper_sha256=%s\n' "${status_helper_sha_pre}"
  printf 'linux_makefile_sha256=%s\n' "${linux_makefile_sha_pre}"
  printf 'guest_checker_sha256=%s\n' "${guest_checker_sha_pre}"
  printf 'strict_checker_sha256=%s\n' "${strict_checker_sha_pre}"
  printf 'transaction_parser_sha256=%s\n' "${transaction_parser_sha_pre}"
  printf 'rootfs_copy_helper_sha256=%s\n' "${rootfs_copy_helper_sha_pre}"
  printf 'prelaunch_contract_log_sha256=%s\n' \
    "${prelaunch_contract_sha_pre}"
  printf 'runner_contract_sha256=%s\n' "${runner_contract_sha_pre}"
  printf 'strict_checker_test_sha256=%s\n' "${strict_checker_test_sha_pre}"
  printf 'guest_checker_test_sha256=%s\n' "${guest_checker_test_sha_pre}"
  printf 'transaction_parser_test_sha256=%s\n' \
    "${transaction_parser_test_sha_pre}"
  printf 'debug_flags_contract_sha256=%s\n' \
    "${debug_flags_contract_sha_pre}"
  sha256sum \
    "${config_path}" \
    "${auto_conf_path}" \
    "${autoconf_header_path}" \
    "${repo_root}/npc/rv64/configs/default_defconfig"
  printf '%s\n' "OOO_CSR_QUEUE_HEAD=1"
  printf '%s\n' "OOO_ASSERT=1"
  printf '%s\n' "OOO_TERMINAL_HOLDER_ASSERT=1"
  printf '%s\n' "NPC_SYSTEMD_GUEST_COMMAND_MODE=systemd-strict"
  printf '%s\n' "uart_rx_bytes=0"
  printf 'host_timeout_seconds=%s\n' "${host_timeout_seconds}"
  printf 'max_cycles=%s\n' "${max_cycles}"
  printf 'NPC_COMMIT_GAP_LIMIT_CYCLES=%s\n' "${commit_gap_limit_cycles}"
  printf 'progress_interval=%s\n' "${progress_interval}"
  printf '%s\n' "NPC_USER_ECALL_TRACE=1"
  printf '%s\n' "NPC_USER_ECALL_TRACE_PRIV=1"
  printf '%s\n' "NPC_USER_ECALL_MIN_COMMIT=1100000000"
  printf '%s\n' "NPC_USER_ECALL_TRACE_LIMIT=8192"
  printf '%s\n' "NPC_USER_ECALL_PATH_TRACE=0"
  printf 'rootfs_template=%s\n' "${rootfs_template}"
  printf 'rootfs_run_image=%s\n' "${rootfs_run_image}"
  printf 'rootfs_template_sha256_pre=%s\n' "${rootfs_template_sha}"
  printf 'rootfs_cpio_sha256=%s\n' "${rootfs_cpio_sha}"
  sha256sum \
    "${task_run_dir}/run-v10e-current-design-systemd-strict.sh" \
    "${repo_root}/scripts/task-run-status.sh" \
    "${repo_root}/npc/rv64/Makefile" \
    "${repo_root}/Linux/Makefile" \
    "${guest_checker}" \
    "${strict_checker}" \
    "${transaction_parser}" \
    "${rootfs_copy_helper}" \
    "${runner_contract}" \
    "${strict_checker_test}" \
    "${guest_checker_test}" \
    "${transaction_parser_test}" \
    "${debug_flags_contract}" \
    "${verilator_manifest}" \
    "${linux_image}" \
    "${opensbi_fw}" \
    "${run_dtb}"
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
NPC_SYSTEMD_ROOTFS_EXPECTED_TEMPLATE_SHA256="${rootfs_template_sha}" \
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
  bash "${guest_checker}" \
  >"${result_dir}/driver.log" 2>&1

task_run_status_stage "strict-marker-check"
python3 - "${result_dir}/systemd-transaction-evidence.json" <<'PY'
import json
import sys

data = json.load(open(sys.argv[1], encoding="utf-8"))
stages = {stage["name"]: stage for stage in data.get("stages", [])}
strict = stages.get("strict") or {}
strict_expected_count = len(strict.get("expected_pass_labels", []))
strict_observed_count = strict.get("pass_observation_count")
if data.get("status") != "PASS":
    raise SystemExit("transaction status is not PASS")
if strict.get("status") != "PASS":
    raise SystemExit("strict stage is not PASS")
if strict_expected_count != 17 or strict_observed_count != 17:
    raise SystemExit(
        f"strict count mismatch expected={strict_expected_count} "
        f"observed={strict_observed_count}"
    )
if strict.get("done_rc") != 0:
    raise SystemExit(f"strict done_rc={strict.get('done_rc')}")
print("[V10E-RECERT-TRANSACTION] strict=17/17 done_rc=0 PASS")
PY
grep -F "[npc-systemd-check] PASS strict guest + natural poweroff (mode=systemd-strict)" \
  "${result_dir}/driver.log"
grep -F "loaded bytes=0 file_bytes=0 text_bytes=0" \
  "${result_dir}/guest/console.log"
grep -F "rootfs_template_sha256_pre=${rootfs_template_sha}" \
  "${result_dir}/guest/rootfs-binding.txt"
grep -F "rootfs_run_image_sha256_pre=${rootfs_template_sha}" \
  "${result_dir}/guest/rootfs-binding.txt"
uart_scan_rc=0
rg -a -q 'uart-rx\][[:space:]]+pop=' \
  "${result_dir}/guest/console.log" "${result_dir}/guest/npc.log" ||
  uart_scan_rc=$?
if [[ "${uart_scan_rc}" -eq 0 ]]; then
  printf '%s\n' "[V10E-RECERT][FAIL] unexpected UART RX byte" >&2
  exit 1
elif [[ "${uart_scan_rc}" -ne 1 ]]; then
  printf '%s\n' \
    "[V10E-RECERT][FAIL] UART evidence query rc=${uart_scan_rc}" >&2
  exit "${uart_scan_rc}"
fi

capture_terminal_evidence
test ! -s "${result_dir}/rtl-assertion-failures.txt"
strict_done_count="$(
  count_fixed_terminal_occurrences \
    "strict-done" "__NPC_SYSTEMD_STRICT_DONE__ rc=0" \
    "${result_dir}/guest/console.log"
)"
poweroff_begin_count="$(
  count_fixed_terminal_occurrences \
    "poweroff-begin" "__NPC_SYSTEMD_POWEROFF_BEGIN__" \
    "${result_dir}/guest/console.log"
)"
kernel_power_down_count="$(
  count_fixed_terminal_occurrences \
    "kernel-power-down" "reboot: Power down" \
    "${result_dir}/guest/console.log"
)"
syscon_terminal_count="$(
  count_fixed_terminal_occurrences \
    "syscon-terminal" \
    "syscon-reset: poweroff requested value=0x00005555" \
    "${result_dir}/guest/console.log"
)"
system_reset_exit_count="$(
  count_fixed_terminal_occurrences \
    "system-reset-exit" "exit via system-reset, code=0" \
    "${result_dir}/guest/console.log"
)"
good_trap_count="$(
  count_fixed_terminal_occurrences \
    "good-trap" "HIT GOOD TRAP" \
    "${result_dir}/guest/console.log"
)"
[[ "${strict_done_count}" -eq 1 ]]
[[ "${poweroff_begin_count}" -eq 1 ]]
[[ "${kernel_power_down_count}" -eq 1 ]]
[[ "${syscon_terminal_count}" -eq 1 ]]
[[ "${system_reset_exit_count}" -eq 1 ]]
[[ "${good_trap_count}" -eq 1 ]]

task_run_status_stage "evidence-verified"
printf '%s\n' \
  "[V10E-CURRENT-DESIGN-SYSTEM-RECERT] strict=17/17 natural-poweroff PASS"
task_run_status_mark_evidence_complete
