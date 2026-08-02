#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
task_root="${repo_root}/.github/task-runs/2026-08-02-rv64-v13r-store-b-multicycle-retire-hold-v1"
result_root="${task_root}/evidence/v13r-focused"
bridge_log="${result_root}/logs/tb_ooo_mem_axi_bridge_v13r_store_b_multicycle_hold.log"
backend_log="${result_root}/logs/tb_ooo_int_backend_v13r_store_b_multicycle_retire_hold.log"
binding_path="${result_root}/critical-source-binding.sha256"
result_json="${result_root}/result.json"
bridge_vvp="${repo_root}/npc/rv64/testbench/build/tb_ooo_mem_axi_bridge_v13r_store_b_multicycle_hold.vvp"
backend_vvp="${repo_root}/npc/rv64/testbench/build/tb_ooo_int_backend_v13r_store_b_multicycle_retire_hold.vvp"

mkdir -p "${result_root}/logs"
tmp_root="$(mktemp -d "${result_root}/.focused-run.XXXXXX")"

critical_sources=(
  npc/rv64/vsrc/filelist.mk
  npc/rv64/design/specs/ooo-store-bresp-precise-terminal.md
  .github/task-runs/2026-08-02-rv64-v13r-store-b-multicycle-retire-hold-v1/driver/run-v13r-focused.sh
  .github/task-runs/2026-08-02-rv64-v13r-store-b-multicycle-retire-hold-v1/driver/run-v13r-mutations.sh
  .github/task-runs/2026-08-02-rv64-v13r-store-b-multicycle-retire-hold-v1/driver/run-v13r-regressions.sh
)

cleanup() {
  rm -rf -- "${tmp_root}"
  rm -f -- "${bridge_vvp}" "${backend_vvp}"
}
trap cleanup EXIT

rm -f -- "${result_json}" "${binding_path}" "${bridge_log}" \
  "${backend_log}" "${bridge_vvp}" "${backend_vvp}"

# Ask the same Make variables used by RUN_TEST for the exact focused source,
# TB dependency, common include and result-checker closure.  This avoids a
# hand-maintained manifest silently omitting dispatch/IQ/FP/memory producers.
make -s -C "${repo_root}/npc/rv64/testbench" \
  print-v13r-store-b-source-closure > "${tmp_root}/compile-sources.raw"
while IFS= read -r source_path; do
  [[ -n "${source_path}" ]] || continue
  if [[ "${source_path}" == /* ]]; then
    if [[ "${source_path}" != "${repo_root}/"* ]]; then
      printf '[V13R-FOCUSED][FAIL] compile source escapes repository: %s\n' \
        "${source_path}" >&2
      exit 20
    fi
    critical_sources+=("${source_path#${repo_root}/}")
  else
    critical_sources+=("npc/rv64/testbench/${source_path}")
  fi
done < "${tmp_root}/compile-sources.raw"
mapfile -t critical_sources < <(
  printf '%s\n' "${critical_sources[@]}" | LC_ALL=C sort -u
)
if [[ "${#critical_sources[@]}" -lt 20 ]]; then
  printf '[V13R-FOCUSED][FAIL] source closure unexpectedly small: %s\n' \
    "${#critical_sources[@]}" >&2
  exit 20
fi

(
  cd "${repo_root}"
  sha256sum "${critical_sources[@]}"
) > "${tmp_root}/pre.sha256"

set +e
make -C "${repo_root}/npc/rv64/testbench" \
  "RESULT_DIR=${result_root}" \
  v13r-store-b-multicycle-retire-hold-focused
make_rc=$?
set -e

(
  cd "${repo_root}"
  sha256sum "${critical_sources[@]}"
) > "${tmp_root}/post.sha256"

if [[ "${make_rc}" != "0" ]]; then
  printf '[V13R-FOCUSED][FAIL] make rc=%s\n' "${make_rc}" >&2
  exit 21
fi
if ! cmp -s "${tmp_root}/pre.sha256" "${tmp_root}/post.sha256"; then
  printf '%s\n' '[V13R-FOCUSED][FAIL] critical source binding drifted' >&2
  exit 22
fi
if ! grep -Fq '[V13R-B-FUSION-MULTICYCLE][PASS] decerr=1 poisoned_b=1 s_resp_stall_edges=3 exact_owner=1 exact_tval=1 consume=1' "${bridge_log}"; then
  printf '%s\n' '[V13R-FOCUSED][FAIL] bridge multi-cycle marker missing' >&2
  exit 23
fi
if ! grep -Fq '[V13R-BACKEND-FAIRNESS] first_wave_full=1 lane1_refill_blocked=1 second_wave_partial=1 response_bound=C_B+1 PASS' "${backend_log}" || \
   ! grep -Fq '[V13R-BACKEND-B-HOLD] decerr_fallback=1 requested_alu_waves=2 anti_starvation_bound=1 commit_stall_cycles=3 cause7=1 original_tval=1 exact_terminal=1 owner_hold=1 quiet=3 PASS' "${backend_log}"; then
  printf '%s\n' '[V13R-FOCUSED][FAIL] backend lifecycle marker missing' >&2
  exit 24
fi
if ! grep -Fq '[PASS] tb_ooo_mem_axi_bridge_v13r_store_b_multicycle_hold' "${bridge_log}" || \
   ! grep -Fq '[RESULT] PASS' "${bridge_log}" || \
   ! grep -Fq '[PASS] tb_ooo_int_backend_v13r_store_b_multicycle_retire_hold' "${backend_log}" || \
   ! grep -Fq '[RESULT] PASS' "${backend_log}"; then
  printf '%s\n' '[V13R-FOCUSED][FAIL] terminal PASS markers missing' >&2
  exit 25
fi

mv -- "${tmp_root}/pre.sha256" "${binding_path}"
binding_sha="$(sha256sum "${binding_path}" | awk '{print $1}')"
bridge_log_sha="$(sha256sum "${bridge_log}" | awk '{print $1}')"
backend_log_sha="$(sha256sum "${backend_log}" | awk '{print $1}')"
printf '%s\n' \
  '{' \
  '  "schema_version": 1,' \
  '  "test": "v13r-store-b-multicycle-retire-hold-focused",' \
  "  \"make_rc\": ${make_rc}," \
  "  \"critical_source_count\": ${#critical_sources[@]}," \
  '  "source_closure_target": "print-v13r-store-b-source-closure",' \
  "  \"critical_source_binding_sha256\": \"${binding_sha}\"," \
  "  \"bridge_log_sha256\": \"${bridge_log_sha}\"," \
  "  \"backend_log_sha256\": \"${backend_log_sha}\"," \
  '  "bridge_multicycle_marker_detected": true,' \
  '  "backend_fairness_marker_detected": true,' \
  '  "backend_retirement_hold_marker_detected": true,' \
  '  "terminal_pass_detected": true,' \
  '  "status": "PASS"' \
  '}' > "${tmp_root}/result.json"
mv -- "${tmp_root}/result.json" "${result_json}"

printf '%s\n' '[V13R-FOCUSED][PASS] source-binding=stable bridge=PASS backend=PASS'
