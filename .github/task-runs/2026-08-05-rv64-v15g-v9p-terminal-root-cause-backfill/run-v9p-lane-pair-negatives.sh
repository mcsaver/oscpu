#!/usr/bin/env bash
set -euo pipefail

repo_root=$(git rev-parse --show-toplevel)
run_rel=.github/task-runs/2026-08-05-rv64-v15g-v9p-terminal-root-cause-backfill
result_dir=${repo_root}/${run_rel}/evidence/v9p-lane-pairs
collector_rel=${run_rel}/evidence/v9p-exact-source/sources/npc/rv64/vsrc/memory/OooMemOwnerTerminalCollector.v
tb_rel=${run_rel}/tb_v9p_terminal_lane_pair.sv
collector=${repo_root}/${collector_rel}
testbench=${repo_root}/${tb_rel}
expected_collector_sha=be48ff513dcccbd5ea2dd7c15ac83832289753bf706c1efbeda6b4833807556c

[[ -f ${collector} && ! -L ${collector} ]]
[[ -f ${testbench} && ! -L ${testbench} ]]
[[ $(sha256sum -- "${collector}" | awk '{print $1}') == \
   ${expected_collector_sha} ]]
mkdir -p "${result_dir}"
[[ ! -L ${result_dir} ]]

tmp_dir=$(mktemp -d "${repo_root}/.github/runtime-artifacts/v9p-lane-pair.XXXXXX")
cleanup() {
  rm -rf -- "${tmp_dir}"
}
trap cleanup EXIT

publish_exact() {
  local candidate=$1
  local target=$2
  if [[ -e ${target} ]]; then
    [[ -f ${target} && ! -L ${target} ]]
    cmp -s -- "${candidate}" "${target}"
    rm -f -- "${candidate}"
    return
  fi
  mv -- "${candidate}" "${target}"
}

run_pair() {
  local name=$1
  local define=$2
  local expected_drop=$3
  local expected_retry=$4
  local image=${tmp_dir}/${name}.vvp
  local log=${tmp_dir}/${name}.log
  local compile_log=${tmp_dir}/${name}.compile.log

  iverilog -g2012 -Wall -Wno-timescale -DOOO_ASSERT ${define} \
    -s tb_v9p_terminal_lane_pair -o "${image}" \
    "${collector}" "${testbench}" >"${compile_log}" 2>&1
  [[ ! -s ${compile_log} ]]

  set +e
  vvp "${image}" >"${log}" 2>&1
  local return_code=$?
  set -e
  [[ ${return_code} -ne 0 ]]
  [[ $(grep -Fc '[S2-G1-TCOLL-INGRESS-DUP]' "${log}") == 1 ]]
  [[ $(grep -Fc '[V15G-V9P-LANE-PAIR-DRIVE]' "${log}") == 1 ]]
  [[ $(grep -Fc '[V15G-V9P-LANE-PAIR-ESCAPED]' "${log}") == 0 ]]
  grep -Fq "drop_lane=${expected_drop} retry_lane=${expected_retry}" "${log}"
  publish_exact "${log}" "${result_dir}/${name}.log"
}

run_pair bank0 '' 2 10
run_pair bank1 -DV9P_BANK1_PAIR 4 11

collector_sha=$(sha256sum -- "${collector}" | awk '{print $1}')
testbench_sha=$(sha256sum -- "${testbench}" | awk '{print $1}')
bank0_log_sha=$(sha256sum -- "${result_dir}/bank0.log" | awk '{print $1}')
bank1_log_sha=$(sha256sum -- "${result_dir}/bank1.log" | awk '{print $1}')
summary_candidate=${tmp_dir}/summary.json
jq -n \
  --arg schema npc-rv64-v9p-terminal-lane-pair-negative-v1 \
  --arg collector_path "${collector_rel}" \
  --arg collector_sha256 "${collector_sha}" \
  --arg testbench_path "${tb_rel}" \
  --arg testbench_sha256 "${testbench_sha}" \
  --arg bank0_path "${run_rel}/evidence/v9p-lane-pairs/bank0.log" \
  --arg bank0_sha256 "${bank0_log_sha}" \
  --arg bank1_path "${run_rel}/evidence/v9p-lane-pairs/bank1.log" \
  --arg bank1_sha256 "${bank1_log_sha}" \
  '{
    schema: $schema,
    status: "PASS",
    collector: {path: $collector_path, sha256: $collector_sha256},
    testbench: {path: $testbench_path, sha256: $testbench_sha256},
    cases: {
      bank0: {
        lanes: [2, 10],
        sources: ["mem_drop0", "mem_retry0_cancel"],
        expected_marker: "[S2-G1-TCOLL-INGRESS-DUP]",
        result: "REJECTED",
        log: {path: $bank0_path, sha256: $bank0_sha256}
      },
      bank1: {
        lanes: [4, 11],
        sources: ["mem1_drop0", "mem_retry1_cancel"],
        expected_marker: "[S2-G1-TCOLL-INGRESS-DUP]",
        result: "REJECTED",
        log: {path: $bank1_path, sha256: $bank1_sha256}
      }
    },
    assertion_policy: "fail-loud; no merge, deduplication, waiver or weakening"
  }' >"${summary_candidate}"
publish_exact "${summary_candidate}" "${result_dir}/summary.json"

printf '[RV64-V9P-LANE-PAIR-NEGATIVE][PASS] bank0=2,10 bank1=4,11 marker=S2-G1-TCOLL-INGRESS-DUP\n'
