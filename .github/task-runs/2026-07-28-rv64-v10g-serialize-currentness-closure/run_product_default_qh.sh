#!/usr/bin/env bash
set -euo pipefail

run_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(git -C "${run_dir}" rev-parse --show-toplevel)"
npc_home="${repo_root}/npc/rv64"
tb_home="${npc_home}/testbench"
vsrc="${npc_home}/vsrc"
out="${run_dir}/product-default-qh-v2"
common_flags="-g2012 -Wall -I${vsrc} -I${vsrc}/include -I${tb_home}/common"

receipt="$(make -C "${npc_home}" -s print-product-rtl-config)"
grep -Fxq "OOO_CSR_QUEUE_HEAD=1" <<<"${receipt}"
grep -Fq "+define+OOO_CSR_QUEUE_HEAD=1" <<<"${receipt}"

run_one() {
  local mode="$1"
  local ivflags="$2"
  local result_dir="${out}/${mode}"
  local log="${result_dir}/logs/tb_ooo_core_top_glue_v9o_csr_qh.log"
  mkdir -p "${result_dir}"
  make -C "${tb_home}" \
    RESULT_DIR="${result_dir}" \
    BUILD_DIR="${result_dir}/build" \
    IVFLAGS="${ivflags}" \
    "${log}" > "${result_dir}/make.log" 2>&1
  grep -Fxq "[RESULT] PASS" "${log}"
  if grep -Fq -- "-DOOO_CSR_QUEUE_HEAD" "${result_dir}/make.log"; then
    printf '[V10G-PRODUCT-DEFAULT-QH][FAIL] mode=%s used command override\n' \
      "${mode}" >&2
    return 1
  fi
  printf '[V10G-PRODUCT-DEFAULT-QH][PASS] mode=%s fallback=1\n' "${mode}"
}

run_one "assert" \
  "${common_flags} -DOOO_ASSERT -DV9O_CSR_QH_FOCUSED"
run_one "release" \
  "${common_flags} -DV9O_CSR_QH_FOCUSED"

printf '%s\n' "${receipt}" > "${out}/product-config-receipt.txt"
printf '[V10G-PRODUCT-DEFAULT-QH] assert=PASS release=PASS override=none PASS\n'
