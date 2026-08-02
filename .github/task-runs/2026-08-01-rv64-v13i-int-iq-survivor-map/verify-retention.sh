#!/usr/bin/env bash
set -euo pipefail

readonly run_dir=".github/task-runs/2026-08-01-rv64-v13i-int-iq-survivor-map"
readonly retired_runtime=".github/runtime-artifacts/rv64-v13i-int-iq-survivor-map"

python3 -m json.tool "${run_dir}/evidence/ppa/local-v13i/summary.json" >/dev/null
python3 -m json.tool "${run_dir}/evidence/functional/cpi-neutral.json" >/dev/null
python3 -m json.tool "${run_dir}/cleanup-result.json" >/dev/null
sha256sum -c "${run_dir}/evidence/source/current/source-hashes.sha256"

rg -q '\[V13I-SURVIVOR-MATRIX\] remove_cases=37 append_cases=5 payload/order/prefix PASS' \
  "${run_dir}/evidence/functional/focused/logs/tb_ooo_int_issue_queue.log"
rg -q '\[PASS\] tb_ooo_int_issue_queue' \
  "${run_dir}/evidence/functional/focused/logs/tb_ooo_int_issue_queue.log"
rg -q '\[IQ-V13I-SURVIVOR-VALID\]' \
  "${run_dir}/evidence/functional/focused/logs/tb_ooo_int_issue_queue_v13i_negative.log"
rg -q '\[IQ-V13I-SURVIVOR-PAYLOAD\]' \
  "${run_dir}/evidence/functional/focused/logs/tb_ooo_int_issue_queue_v13i_negative.log"
rg -q '\[V13I-SURVIVOR-NEGATIVE-DONE\]' \
  "${run_dir}/evidence/functional/focused/logs/tb_ooo_int_issue_queue_v13i_negative.log"
rg -q -- '- total: 3' "${run_dir}/evidence/functional/integration/summary.txt"
rg -q -- '- failed: 0' "${run_dir}/evidence/functional/integration/summary.txt"
rg -q '`status`: PASS' "${run_dir}/agent-flow-result.md"
rg -q 'APPROVED_DEVELOPMENT_CHECKPOINT' "${run_dir}/review-result.md"

if [[ -e "${retired_runtime}" ]]; then
  printf 'VERIFY_FAIL runtime_still_exists=%s\n' "${retired_runtime}" >&2
  exit 2
fi

if find "${run_dir}" -type f \
  \( -name '*.vvp' -o -name '*.il' -o -name '*.netlist.v' -o \
     -name '*.netlist.v.sim' -o -name 'yosys.log' \) -print -quit | grep -q .; then
  printf 'VERIFY_FAIL generated_intermediate_retained\n' >&2
  exit 3
fi

if rg -q '判别尚未完成|V13I packed survivor/source 静态映射合同（RTL 前冻结）' \
  npc/rv64/design/specs/ooo-int-issue-queue.md; then
  printf 'VERIFY_FAIL stale_v13i_spec_status\n' >&2
  exit 4
fi

printf 'FINAL_INTEGRITY_PASS run_dir=%s\n' "${run_dir}"
