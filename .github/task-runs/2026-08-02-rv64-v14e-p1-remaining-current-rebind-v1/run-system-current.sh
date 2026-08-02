#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
task_run_dir="${repo_root}/.github/task-runs/2026-08-02-rv64-v14e-p1-remaining-current-rebind-v1"
run_label="${V14E_SYSTEM_RUN_LABEL:-rootfs-093c2380-systemd-strict-6b-v14e-a2}"
result_dir="${task_run_dir}/${run_label}"
status_path="${task_run_dir}/${run_label}.status"
runtime_root="${repo_root}/.github/runtime-artifacts/rv64-systemd-strict"
runtime_dir="${runtime_root}/${run_label}"
build_dir="${runtime_dir}/sim-build"
simulator="${build_dir}/NpcSimTop"
verilator_manifest="${build_dir}/obj_dir/VNpcSimTop__verFiles.dat"
rootfs_run_image="${runtime_dir}/rootfs.ext4"

expected_design_id="${V14E_SYSTEM_EXPECTED_DESIGN_ID:-sha256:093c2380b997029944aa4462015d83711d7c5f1d52b15b4803c4515a581a7488}"
expected_file_count="${V14E_SYSTEM_EXPECTED_FILE_COUNT:-146}"
host_timeout_seconds="${V14E_SYSTEM_HOST_TIMEOUT_SECONDS:-100000}"
max_cycles="${V14E_SYSTEM_MAX_CYCLES:-6000000000}"
min_max_cycles=6000000000
commit_gap_limit_cycles="${V14E_SYSTEM_COMMIT_GAP_LIMIT_CYCLES:-1000000}"
progress_interval="${V14E_SYSTEM_PROGRESS_INTERVAL:-5000000}"

status_helper="${repo_root}/scripts/task-run-status.sh"
snapshot_tool="${repo_root}/npc/rv64/eval/ppa/tools/control_event_sq_retry_evidence.py"
summary_builder="${task_run_dir}/build-system-current-summary.py"
runner_script="${task_run_dir}/run-system-current.sh"
launcher_script="${task_run_dir}/launch-system-current.sh"
prelaunch_binding="${result_dir}/launch-binding.txt"
prelaunch_contract_log="${result_dir}/prelaunch-contract.log"

config_path="${repo_root}/npc/rv64/.config"
auto_conf_path="${repo_root}/npc/rv64/include/config/auto.conf"
autoconf_header_path="${repo_root}/npc/rv64/include/generated/autoconf.h"
default_defconfig="${repo_root}/npc/rv64/configs/default_defconfig"
linux_image="${repo_root}/Linux/env/platforms/npc/build/linux/arch/riscv/boot/Image"
opensbi_fw="${repo_root}/Linux/env/platforms/npc/build/opensbi/rootfs/platform/generic/firmware/fw_jump.bin"
run_dtb="${repo_root}/Linux/build/riscv64-npc/npc-rv64-rootfs.dtb"
rootfs_template="${repo_root}/Linux/env/platforms/npc/images/ubuntu2204/ubuntu-22.04-riscv64-strict.ext4"
rootfs_cpio="${repo_root}/Linux/env/platforms/npc/images/ubuntu2204/ubuntu-22.04-riscv64-strict-rootfs.cpio"

guest_checker="${repo_root}/Linux/scripts/check-npc-systemd-guest.sh"
strict_checker="${repo_root}/Linux/scripts/npc-systemd-strict-check.sh"
transaction_parser="${repo_root}/Linux/scripts/npc_systemd_transaction_evidence.py"
rootfs_copy_helper="${repo_root}/Linux/scripts/prepare-npc-rootfs-run-image.sh"
strict_checker_test="${repo_root}/Linux/scripts/tests/test_npc_systemd_strict_check.py"
guest_checker_test="${repo_root}/Linux/scripts/tests/test_check_npc_systemd_guest_contract.py"
transaction_parser_test="${repo_root}/Linux/scripts/tests/test_npc_systemd_transaction_evidence.py"
debug_flags_contract="${repo_root}/npc/rv64/testbench/scripts/test_debug_ooo_flags_contract.py"

assertion_failure_regex='\[(V9Q-(BRIDGE-HOLDER|TRANSIENT-HOLDER|TRANSIENT-BRIDGE|DUAL-REQ-TOKEN)-DISJOINT|V9R-(MEM-)?SQ-RETRY-C0-HANDOFF|S2-G1-TCOLL-INGRESS-DUP|V1[0-9][A-Z]?-[^]]*FAIL)\]|%Error:|Assertion failed|RTL assertion|\[[^]]*ASSERT[^]]*FAIL'
terminal_evidence_regex='OpenSBI v[0-9]|Platform (Reboot|Shutdown) Device|SBI SRST extension detected|__NPC_SYSTEMD_STRICT_(BEGIN|DONE)__|__NPC_SYSTEMD_POWEROFF_BEGIN__|reboot: Power down|syscon-reset: poweroff requested value=0x00005555|exit via system-reset, code=0|HIT GOOD TRAP|npc-systemd-check.*PASS strict guest'

runtime_owned=0
config_restore_required=0
cleanup_signal_rc=0
post_binding_failed=0

runner_sha_pre=""
launcher_sha_pre=""
summary_builder_sha_pre=""
status_helper_sha_pre=""
snapshot_tool_sha_pre=""
prelaunch_binding_sha_pre=""
prelaunch_contract_sha_pre=""
npc_makefile_sha_pre=""
linux_makefile_sha_pre=""
default_defconfig_sha_pre=""
guest_checker_sha_pre=""
strict_checker_sha_pre=""
transaction_parser_sha_pre=""
rootfs_copy_helper_sha_pre=""
strict_checker_test_sha_pre=""
guest_checker_test_sha_pre=""
transaction_parser_test_sha_pre=""
debug_flags_contract_sha_pre=""
source_before_sha=""
design_id_pre=""
source_file_count_pre=""
config_sha_pre=""
auto_conf_sha_pre=""
autoconf_header_sha_pre=""
rootfs_template_sha_pre=""
rootfs_cpio_sha_pre=""
linux_image_sha_pre=""
opensbi_fw_sha_pre=""
run_dtb_sha_pre=""
simulator_sha_pre=""
verilator_manifest_sha_pre=""

case "${run_label}" in
  *[!A-Za-z0-9._-]*|"")
    printf '%s\n' "[V14E-SERIALIZE-SYSTEM] invalid run label: ${run_label}" >&2
    exit 2
    ;;
esac

test -f "${status_helper}"
test ! -e "${status_path}"
test -d "${result_dir}"
source "${status_helper}"
task_run_status_init "${status_path}"

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
    "[V14E-SERIALIZE-SYSTEM][EVIDENCE-QUERY-FAIL] rc=${query_rc} output=${output_path}" \
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

restore_npc_config() {
  if [[ "${config_restore_required}" -eq 0 ]]; then
    printf '%s\n' "restore_required=0" >"${result_dir}/config-restore.log"
    return 0
  fi
  make -C "${repo_root}/npc/rv64" default_defconfig \
    >"${result_dir}/config-restore.log" 2>&1
}

verify_post_hash() {
  local label="${1:?hash label is required}"
  local path="${2:?artifact path is required}"
  local expected="${3:-}"
  local actual=""

  printf '%s_pre_sha256=%s\n' "${label}" "${expected:-UNAVAILABLE}"
  if [[ -z "${expected}" || ! -f "${path}" ]]; then
    printf '%s_post_sha256=%s\n' "${label}" "MISSING_OR_PREHASH_UNAVAILABLE"
    post_binding_failed=1
    return 0
  fi
  if ! actual="$(sha256sum "${path}" | awk '{print $1}')"; then
    printf '%s_post_sha256=HASH_FAILED\n' "${label}"
    post_binding_failed=1
    return 0
  fi
  printf '%s_post_sha256=%s\n' "${label}" "${actual}"
  [[ "${actual}" == "${expected}" ]] || post_binding_failed=1
}

build_post_binding() {
  local body="${result_dir}/.post-binding-body.tmp.$$"
  local complete="${result_dir}/.post-binding.tmp.$$"
  local design_id_post=""
  local source_file_count_post=""
  local rootfs_run_image_sha_post="MISSING"

  post_binding_failed=0
  {
    if [[ -s "${result_dir}/source-after.json" ]]; then
      readarray -t post_identity < <(
        python3 -B - "${result_dir}/source-after.json" <<'PY'
import json
import sys

data = json.load(open(sys.argv[1], encoding="utf-8"))
print(data.get("design_id", "MISSING"))
print(data.get("file_count", "MISSING"))
PY
      )
      design_id_post="${post_identity[0]:-MISSING}"
      source_file_count_post="${post_identity[1]:-MISSING}"
    else
      design_id_post="MISSING"
      source_file_count_post="MISSING"
    fi
    printf 'rtl_design_id_pre=%s\n' "${design_id_pre:-UNAVAILABLE}"
    printf 'rtl_design_id_post=%s\n' "${design_id_post}"
    printf 'source_file_count_pre=%s\n' "${source_file_count_pre:-UNAVAILABLE}"
    printf 'source_file_count_post=%s\n' "${source_file_count_post}"
    if [[ "${design_id_post}" != "${design_id_pre}" ||
          "${source_file_count_post}" != "${source_file_count_pre}" ||
          ! -s "${result_dir}/source-before.json" ||
          ! -s "${result_dir}/source-after.json" ]] ||
       ! cmp -s "${result_dir}/source-before.json" "${result_dir}/source-after.json"; then
      post_binding_failed=1
    fi
    verify_post_hash "source_before" "${result_dir}/source-before.json" "${source_before_sha}"
    verify_post_hash "simulator" "${simulator}" "${simulator_sha_pre}"
    verify_post_hash "verilator_manifest" "${verilator_manifest}" "${verilator_manifest_sha_pre}"
    verify_post_hash "npc_config" "${config_path}" "${config_sha_pre}"
    verify_post_hash "npc_auto_conf" "${auto_conf_path}" "${auto_conf_sha_pre}"
    verify_post_hash "npc_autoconf_header" "${autoconf_header_path}" "${autoconf_header_sha_pre}"
    verify_post_hash "rootfs_template" "${rootfs_template}" "${rootfs_template_sha_pre}"
    verify_post_hash "rootfs_cpio" "${rootfs_cpio}" "${rootfs_cpio_sha_pre}"
    verify_post_hash "linux_image" "${linux_image}" "${linux_image_sha_pre}"
    verify_post_hash "opensbi_fw" "${opensbi_fw}" "${opensbi_fw_sha_pre}"
    verify_post_hash "run_dtb" "${run_dtb}" "${run_dtb_sha_pre}"
    verify_post_hash "runner_script" "${runner_script}" "${runner_sha_pre}"
    verify_post_hash "launcher_script" "${launcher_script}" "${launcher_sha_pre}"
    verify_post_hash "summary_builder" "${summary_builder}" "${summary_builder_sha_pre}"
    verify_post_hash "status_helper" "${status_helper}" "${status_helper_sha_pre}"
    verify_post_hash "snapshot_tool" "${snapshot_tool}" "${snapshot_tool_sha_pre}"
    verify_post_hash "prelaunch_binding" "${prelaunch_binding}" "${prelaunch_binding_sha_pre}"
    verify_post_hash "prelaunch_contract" "${prelaunch_contract_log}" "${prelaunch_contract_sha_pre}"
    verify_post_hash "npc_makefile" "${repo_root}/npc/rv64/Makefile" "${npc_makefile_sha_pre}"
    verify_post_hash "linux_makefile" "${repo_root}/Linux/Makefile" "${linux_makefile_sha_pre}"
    verify_post_hash "default_defconfig" "${default_defconfig}" "${default_defconfig_sha_pre}"
    verify_post_hash "guest_checker" "${guest_checker}" "${guest_checker_sha_pre}"
    verify_post_hash "strict_checker" "${strict_checker}" "${strict_checker_sha_pre}"
    verify_post_hash "transaction_parser" "${transaction_parser}" "${transaction_parser_sha_pre}"
    verify_post_hash "rootfs_copy_helper" "${rootfs_copy_helper}" "${rootfs_copy_helper_sha_pre}"
    verify_post_hash "strict_checker_test" "${strict_checker_test}" "${strict_checker_test_sha_pre}"
    verify_post_hash "guest_checker_test" "${guest_checker_test}" "${guest_checker_test_sha_pre}"
    verify_post_hash "transaction_parser_test" "${transaction_parser_test}" "${transaction_parser_test_sha_pre}"
    verify_post_hash "debug_flags_contract" "${debug_flags_contract}" "${debug_flags_contract_sha_pre}"
    if [[ -f "${rootfs_run_image}" ]]; then
      rootfs_run_image_sha_post="$(sha256sum "${rootfs_run_image}" | awk '{print $1}')"
    fi
    printf 'rootfs_run_image_post_sha256=%s\n' "${rootfs_run_image_sha_post}"
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
  local signal_name="${1:?signal name is required}"
  local signal_rc="${2:?signal rc is required}"

  TASK_RUN_STATUS_SIGNAL="${signal_name}"
  cleanup_signal_rc="${signal_rc}"
}

finish() {
  local command_rc=$?
  local main_stage="${TASK_RUN_STATUS_STAGE}"
  local capture_rc=0
  local snapshot_rc=0
  local restore_rc=0
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
  if [[ -f "${snapshot_tool}" ]]; then
    python3 -B "${snapshot_tool}" --root "${repo_root}" snapshot \
      --output "${result_dir}/source-after.json" \
      >"${result_dir}/source-after.log" 2>&1
    snapshot_rc=$?
  else
    snapshot_rc=1
  fi
  restore_npc_config
  restore_rc=$?
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
  elif [[ "${restore_rc}" -ne 0 ]]; then
    cleanup_rc="${restore_rc}"
  elif [[ "${binding_rc}" -ne 0 ]]; then
    cleanup_rc="${binding_rc}"
  elif [[ "${remove_rc}" -ne 0 ]]; then
    cleanup_rc="${remove_rc}"
  fi

  if [[ "${command_rc}" -eq 0 && "${cleanup_rc}" -eq 0 &&
        "${TASK_RUN_STATUS_SIGNAL}" == "none" ]]; then
    python3 -B "${summary_builder}" \
      --repo-root "${repo_root}" \
      --result-dir "${result_dir}" \
      --expected-design-id "${expected_design_id}" \
      --expected-file-count "${expected_file_count}" \
      --max-cycles "${max_cycles}" \
      --output "${result_dir}/system-current-summary.json" \
      >"${result_dir}/system-current-marker.txt" \
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
for numeric_value in \
  "${expected_file_count}" "${host_timeout_seconds}" "${max_cycles}" \
  "${commit_gap_limit_cycles}" "${progress_interval}"; do
  [[ "${numeric_value}" =~ ^[0-9]+$ ]]
done
(( expected_file_count > 0 ))
(( host_timeout_seconds >= 50400 ))
(( max_cycles >= min_max_cycles ))
(( commit_gap_limit_cycles > 0 ))
(( progress_interval > 0 ))
[[ "${expected_design_id}" =~ ^sha256:[0-9a-f]{64}$ ]]
for command_name in \
  rg sha256sum python3 make grep tail realpath cmp awk; do
  command -v "${command_name}" >/dev/null
done
for required_file in \
  "${summary_builder}" "${runner_script}" "${launcher_script}" \
  "${snapshot_tool}" "${prelaunch_binding}" "${prelaunch_contract_log}" \
  "${guest_checker}" "${strict_checker}" "${transaction_parser}" \
  "${rootfs_copy_helper}" "${strict_checker_test}" \
  "${guest_checker_test}" "${transaction_parser_test}" \
  "${debug_flags_contract}" "${default_defconfig}"; do
  test -s "${required_file}"
done
test ! -e "${runtime_dir}"
mkdir -p "${runtime_dir}"
runtime_owned=1

runner_sha_pre="$(sha256sum "${runner_script}" | awk '{print $1}')"
launcher_sha_pre="$(sha256sum "${launcher_script}" | awk '{print $1}')"
summary_builder_sha_pre="$(sha256sum "${summary_builder}" | awk '{print $1}')"
status_helper_sha_pre="$(sha256sum "${status_helper}" | awk '{print $1}')"
snapshot_tool_sha_pre="$(sha256sum "${snapshot_tool}" | awk '{print $1}')"
prelaunch_binding_sha_pre="$(sha256sum "${prelaunch_binding}" | awk '{print $1}')"
prelaunch_contract_sha_pre="$(sha256sum "${prelaunch_contract_log}" | awk '{print $1}')"
npc_makefile_sha_pre="$(sha256sum "${repo_root}/npc/rv64/Makefile" | awk '{print $1}')"
linux_makefile_sha_pre="$(sha256sum "${repo_root}/Linux/Makefile" | awk '{print $1}')"
default_defconfig_sha_pre="$(sha256sum "${default_defconfig}" | awk '{print $1}')"
guest_checker_sha_pre="$(sha256sum "${guest_checker}" | awk '{print $1}')"
strict_checker_sha_pre="$(sha256sum "${strict_checker}" | awk '{print $1}')"
transaction_parser_sha_pre="$(sha256sum "${transaction_parser}" | awk '{print $1}')"
rootfs_copy_helper_sha_pre="$(sha256sum "${rootfs_copy_helper}" | awk '{print $1}')"
strict_checker_test_sha_pre="$(sha256sum "${strict_checker_test}" | awk '{print $1}')"
guest_checker_test_sha_pre="$(sha256sum "${guest_checker_test}" | awk '{print $1}')"
transaction_parser_test_sha_pre="$(sha256sum "${transaction_parser_test}" | awk '{print $1}')"
debug_flags_contract_sha_pre="$(sha256sum "${debug_flags_contract}" | awk '{print $1}')"

task_run_status_stage "runner-contract-bound"
grep -Fqx \
  "[V14E-SERIALIZE-SYSTEM-PRELAUNCH] status=PASS checker_suites=5" \
  "${prelaunch_contract_log}"

task_run_status_stage "rtl-binding-pre"
python3 -B "${snapshot_tool}" --root "${repo_root}" snapshot \
  --output "${result_dir}/source-before.json" \
  >"${result_dir}/source-before.log" 2>&1
readarray -t source_identity < <(
  python3 -B - "${result_dir}/source-before.json" <<'PY'
import json
import sys

data = json.load(open(sys.argv[1], encoding="utf-8"))
print(data.get("design_id", "MISSING"))
print(data.get("file_count", "MISSING"))
PY
)
design_id_pre="${source_identity[0]:-MISSING}"
source_file_count_pre="${source_identity[1]:-MISSING}"
[[ "${design_id_pre}" == "${expected_design_id}" ]]
[[ "${source_file_count_pre}" == "${expected_file_count}" ]]
source_before_sha="$(sha256sum "${result_dir}/source-before.json" | awk '{print $1}')"

task_run_status_stage "simulator-config-canonical"
config_restore_required=1
make -C "${repo_root}/npc/rv64" default_defconfig \
  >"${result_dir}/config-canonical.log" 2>&1
test -s "${config_path}"
test -s "${auto_conf_path}"
test -s "${autoconf_header_path}"
grep -Fqx "CONFIG_NPC_DIFFTEST=y" "${config_path}"
grep -Fqx "# CONFIG_NPC_DEBUG_PORTS is not set" "${config_path}"
config_sha_pre="$(sha256sum "${config_path}" | awk '{print $1}')"
auto_conf_sha_pre="$(sha256sum "${auto_conf_path}" | awk '{print $1}')"
autoconf_header_sha_pre="$(sha256sum "${autoconf_header_path}" | awk '{print $1}')"

task_run_status_stage "rootfs-template-rebuild"
make -C "${repo_root}/Linux" \
  ARCH=riscv64-npc ubuntu-rootfs-systemd-strict-image \
  >"${result_dir}/rootfs-build.log" 2>&1
test -s "${rootfs_template}"
test -s "${rootfs_cpio}"
rootfs_template_sha_pre="$(sha256sum "${rootfs_template}" | awk '{print $1}')"
rootfs_cpio_sha_pre="$(sha256sum "${rootfs_cpio}" | awk '{print $1}')"

task_run_status_stage "rootfs-static-check"
make -C "${repo_root}/Linux" \
  ARCH=riscv64-npc check-ubuntu-rootfs-systemd-strict \
  >"${result_dir}/rootfs-check.log" 2>&1

task_run_status_stage "simulator-build"
make -C "${repo_root}/npc/rv64" \
  BUILD_DIR="${build_dir}" \
  OOO_CSR_QUEUE_HEAD=1 \
  OOO_ASSERT=1 \
  OOO_TERMINAL_HOLDER_ASSERT=1 \
  CXX=/usr/bin/clang++ \
  LINK=/usr/bin/clang++ \
  VERILATOR='verilator -Wno-fatal' \
  VERILATOR_OPT_FAST='-O3 -march=native' \
  VERILATOR_OPT_GLOBAL='-O3 -march=native' \
  >"${result_dir}/sim-build.log" 2>&1
test -x "${simulator}"
test -s "${verilator_manifest}"
grep -Fq -- "--assert" "${verilator_manifest}"
grep -Fq -- "+define+OOO_CSR_QUEUE_HEAD=1 " "${verilator_manifest}"
grep -Fq -- "+define+OOO_ASSERT " "${verilator_manifest}"
grep -Fq -- "+define+OOO_TERMINAL_HOLDER_ASSERT " "${verilator_manifest}"
simulator_sha_pre="$(sha256sum "${simulator}" | awk '{print $1}')"
verilator_manifest_sha_pre="$(sha256sum "${verilator_manifest}" | awk '{print $1}')"
{
  printf '%s\n' "verilator_assertions=enabled"
  printf '%s\n' "OOO_CSR_QUEUE_HEAD=1"
  printf '%s\n' "OOO_ASSERT=1"
  printf '%s\n' "OOO_TERMINAL_HOLDER_ASSERT=1"
} >"${result_dir}/simulator-defines.txt"

task_run_status_stage "system-input-binding"
for system_input in "${linux_image}" "${opensbi_fw}" "${run_dtb}"; do
  test -s "${system_input}"
done
linux_image_sha_pre="$(sha256sum "${linux_image}" | awk '{print $1}')"
opensbi_fw_sha_pre="$(sha256sum "${opensbi_fw}" | awk '{print $1}')"
run_dtb_sha_pre="$(sha256sum "${run_dtb}" | awk '{print $1}')"
{
  printf '%s\n' "schema=rv64-v14e-system-current-binding-v1"
  printf 'run_label=%s\n' "${run_label}"
  printf 'rtl_design_id=%s\n' "${design_id_pre}"
  printf 'production_rtl_file_count=%s\n' "${source_file_count_pre}"
  printf 'simulator_sha256=%s\n' "${simulator_sha_pre}"
  printf 'verilator_manifest_sha256=%s\n' "${verilator_manifest_sha_pre}"
  printf 'npc_config_sha256=%s\n' "${config_sha_pre}"
  printf 'npc_auto_conf_sha256=%s\n' "${auto_conf_sha_pre}"
  printf 'npc_autoconf_header_sha256=%s\n' "${autoconf_header_sha_pre}"
  printf 'rootfs_template_sha256=%s\n' "${rootfs_template_sha_pre}"
  printf 'rootfs_cpio_sha256=%s\n' "${rootfs_cpio_sha_pre}"
  printf 'linux_image_sha256=%s\n' "${linux_image_sha_pre}"
  printf 'opensbi_fw_sha256=%s\n' "${opensbi_fw_sha_pre}"
  printf 'run_dtb_sha256=%s\n' "${run_dtb_sha_pre}"
  printf 'host_timeout_seconds=%s\n' "${host_timeout_seconds}"
  printf 'max_cycles=%s\n' "${max_cycles}"
  printf 'commit_gap_limit_cycles=%s\n' "${commit_gap_limit_cycles}"
  printf 'progress_interval=%s\n' "${progress_interval}"
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
NPC_SYSTEMD_ROOTFS_EXPECTED_TEMPLATE_SHA256="${rootfs_template_sha_pre}" \
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
strict = stages.get("strict") or {}
if data.get("status") != "PASS" or strict.get("status") != "PASS":
    raise SystemExit("strict transaction is not PASS")
if len(strict.get("expected_pass_labels", [])) != 17:
    raise SystemExit("strict expected label count is not 17")
if strict.get("pass_observation_count") != 17 or strict.get("done_rc") != 0:
    raise SystemExit("strict observed count/done_rc mismatch")
print("[V14E-SERIALIZE-SYSTEM-TRANSACTION] strict=17/17 done_rc=0 PASS")
PY
grep -F \
  "[npc-systemd-check] PASS strict guest + natural poweroff (mode=systemd-strict)" \
  "${result_dir}/driver.log" >/dev/null
grep -F "loaded bytes=0 file_bytes=0 text_bytes=0" \
  "${result_dir}/guest/console.log" >/dev/null
grep -F "rootfs_template_sha256_pre=${rootfs_template_sha_pre}" \
  "${result_dir}/guest/rootfs-binding.txt" >/dev/null
grep -F "rootfs_run_image_sha256_pre=${rootfs_template_sha_pre}" \
  "${result_dir}/guest/rootfs-binding.txt" >/dev/null
uart_scan_rc=0
rg -a -q 'uart-rx\][[:space:]]+pop=' \
  "${result_dir}/guest/console.log" "${result_dir}/guest/npc.log" || uart_scan_rc=$?
if [[ "${uart_scan_rc}" -eq 0 ]]; then
  printf '%s\n' "[V14E-SERIALIZE-SYSTEM][FAIL] unexpected UART RX byte" >&2
  exit 1
elif [[ "${uart_scan_rc}" -ne 1 ]]; then
  printf '%s\n' \
    "[V14E-SERIALIZE-SYSTEM][FAIL] UART evidence query rc=${uart_scan_rc}" >&2
  exit "${uart_scan_rc}"
fi

task_run_status_stage "systemd-strict-complete"
printf '%s\n' \
  "[V14E-SERIALIZE-SYSTEM] current RV64 system transaction complete; finalizing evidence"
