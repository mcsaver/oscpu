#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
task_root="${repo_root}/.github/task-runs/2026-08-02-rv64-v13p-store-b-terminal-cpi-architecture-v1"
result_root="${task_root}/evidence/yosys-bridge-structural"
source_rtl="${repo_root}/npc/rv64/vsrc/memory/OooMemAxiBridge.v"
yosys_bin="${repo_root}/oss-cad-suite/bin/yosys"
tmp_root="$(mktemp -d)"

cleanup() {
  rm -rf -- "${tmp_root}"
}
trap cleanup EXIT

mkdir -p "${result_root}/baseline" "${result_root}/candidate"

if [[ ! -x "${yosys_bin}" ]]; then
  printf '%s\n' '[V13P-YOSYS][FAIL] bundled Yosys executable is missing' >&2
  exit 2
fi
if [[ "$(grep -c '^  assign data_store_b_response_fusion_w =$' "${source_rtl}")" != "1" ]]; then
  printf '%s\n' '[V13P-YOSYS][FAIL] fusion assignment anchor is not unique' >&2
  exit 3
fi

baseline_rtl="${tmp_root}/baseline/OooMemAxiBridge.v"
mkdir -p "$(dirname "${baseline_rtl}")"
sed "/^  assign data_store_b_response_fusion_w =$/ {
  n
  c\\      1'b0;
}" "${source_rtl}" > "${baseline_rtl}"
if ! grep -A1 '^  assign data_store_b_response_fusion_w =$' "${baseline_rtl}" |
     grep -Fxq "      1'b0;"; then
  printf '%s\n' '[V13P-YOSYS][FAIL] baseline tie-off was not applied' >&2
  exit 4
fi

set +e
diff -u --label baseline/OooMemAxiBridge.v --label candidate/OooMemAxiBridge.v \
  "${baseline_rtl}" "${source_rtl}" > "${result_root}/baseline-to-candidate.patch"
diff_rc=$?
set -e
if [[ "${diff_rc}" != "1" ]]; then
  printf '[V13P-YOSYS][FAIL] expected one non-empty baseline delta, diff_rc=%s\n' \
    "${diff_rc}" >&2
  exit 5
fi

sources=(
  "${repo_root}/npc/rv64/vsrc/memory/PmpChecker.v"
  "${repo_root}/npc/rv64/vsrc/memory/OooTypedPmaChecker.v"
  "${repo_root}/npc/rv64/vsrc/memory/OooTypedMemoryClassifier.v"
  "${repo_root}/npc/rv64/vsrc/memory/OooPmaChecker.v"
  "${repo_root}/npc/rv64/vsrc/memory/OooPostTranslateMemoryClass.v"
  "${repo_root}/npc/rv64/vsrc/cache/OooDataWordCache.v"
  "${repo_root}/npc/rv64/vsrc/sram/Sram4096x113.v"
  "${repo_root}/npc/rv64/vsrc/memory/OooSv39Tlb.v"
)

run_variant() {
  local name="$1"
  local bridge_rtl="$2"
  local out="${result_root}/${name}"
  local ys="${tmp_root}/${name}.ys"
  local source

  {
    printf 'read_verilog -sv -I %s -I %s' \
      "${repo_root}/npc/rv64/vsrc" "${repo_root}/npc/rv64/vsrc/include"
    for source in "${sources[@]}"; do
      printf ' %s' "${source}"
    done
    printf ' %s\n' "${bridge_rtl}"
    printf '%s\n' \
      'blackbox PmpChecker OooTypedPmaChecker OooTypedMemoryClassifier OooPmaChecker OooPostTranslateMemoryClass OooDataWordCache OooSv39Tlb' \
      'hierarchy -check -top OooMemAxiBridge' \
      'synth -top OooMemAxiBridge -flatten -run :fine' \
      'opt_clean -purge' \
      "tee -o ${out}/stats.json stat -json" \
      'select -module OooMemAxiBridge' \
      'select -set bfanout i:lsu_axi_bvalid_i i:lsu_axi_bresp_i %u %coe*' \
      'select -set sink o:mem0_rsp_* %cie*' \
      'select -set bpath @bfanout @sink %i' \
      "tee -o ${out}/bpath-count.txt select -count @bpath" \
      "tee -o ${out}/bpath-ltp.txt ltp -noff @bpath"
  } > "${ys}"

  "${yosys_bin}" -Q -l "${out}/yosys.log" -s "${ys}"
  sha256sum "${bridge_rtl}" > "${out}/bridge-source.sha256"
  sha256sum "${sources[@]}" > "${out}/dependency-sources.sha256"
}

run_variant baseline "${baseline_rtl}"
run_variant candidate "${source_rtl}"

baseline_cells="$(jq -r '.modules | to_entries[0].value.num_cells' "${result_root}/baseline/stats.json")"
candidate_cells="$(jq -r '.modules | to_entries[0].value.num_cells' "${result_root}/candidate/stats.json")"
baseline_wire_bits="$(jq -r '.modules | to_entries[0].value.num_wire_bits' "${result_root}/baseline/stats.json")"
candidate_wire_bits="$(jq -r '.modules | to_entries[0].value.num_wire_bits' "${result_root}/candidate/stats.json")"
baseline_path="$(sed -n 's/^Longest topological path.*length=\([0-9][0-9]*\).*/\1/p' "${result_root}/baseline/bpath-ltp.txt" | head -n 1)"
candidate_path="$(sed -n 's/^Longest topological path.*length=\([0-9][0-9]*\).*/\1/p' "${result_root}/candidate/bpath-ltp.txt" | head -n 1)"
baseline_objects="$(awk '/ objects\.$/{print $1; exit}' "${result_root}/baseline/bpath-count.txt")"
candidate_objects="$(awk '/ objects\.$/{print $1; exit}' "${result_root}/candidate/bpath-count.txt")"
baseline_path="${baseline_path:-null}"
candidate_path="${candidate_path:-null}"
baseline_objects="${baseline_objects:-0}"
candidate_objects="${candidate_objects:-0}"

yosys_version="$(${yosys_bin} -V)"
yosys_sha="$(sha256sum "${yosys_bin}" | awk '{print $1}')"
source_sha="$(sha256sum "${source_rtl}" | awk '{print $1}')"
baseline_sha="$(sha256sum "${baseline_rtl}" | awk '{print $1}')"

jq -n \
  --arg tool_version "${yosys_version}" \
  --arg tool_sha256 "${yosys_sha}" \
  --arg source_sha256 "${source_sha}" \
  --arg baseline_sha256 "${baseline_sha}" \
  --argjson baseline_cells "${baseline_cells}" \
  --argjson candidate_cells "${candidate_cells}" \
  --argjson baseline_wire_bits "${baseline_wire_bits}" \
  --argjson candidate_wire_bits "${candidate_wire_bits}" \
  --argjson baseline_bpath_objects "${baseline_objects}" \
  --argjson candidate_bpath_objects "${candidate_objects}" \
  --argjson baseline_bpath_length "${baseline_path}" \
  --argjson candidate_bpath_length "${candidate_path}" \
  '{
    schema_version: 1,
    scope: "OooMemAxiBridge generic structural diagnostic; leaf TLB/cache/checker modules blackboxed",
    tool: {version: $tool_version, sha256: $tool_sha256},
    source: {
      candidate_sha256: $source_sha256,
      baseline_sha256: $baseline_sha256,
      only_intended_delta: "data_store_b_response_fusion_w tied off in baseline"
    },
    baseline: {
      generic_cells: $baseline_cells,
      wire_bits: $baseline_wire_bits,
      b_to_response_cone_objects: $baseline_bpath_objects,
      b_to_response_ltp_length: $baseline_bpath_length
    },
    candidate: {
      generic_cells: $candidate_cells,
      wire_bits: $candidate_wire_bits,
      b_to_response_cone_objects: $candidate_bpath_objects,
      b_to_response_ltp_length: $candidate_bpath_length
    },
    delta: {
      generic_cells: ($candidate_cells - $baseline_cells),
      wire_bits: ($candidate_wire_bits - $baseline_wire_bits)
    },
    interpretation: "source-sensitive generic diagnostic only; not mapped area, STA, 200MHz closure, or promotion evidence",
    conclusion: "STRUCTURAL_B_TO_RESPONSE_PATH_PRESENT_PPA_PENDING",
    status: "PASS"
  }' > "${result_root}/comparison.json"

printf '[V13P-YOSYS][PASS] cells=%s->%s bpath=%s->%s objects=%s->%s\n' \
  "${baseline_cells}" "${candidate_cells}" \
  "${baseline_path}" "${candidate_path}" \
  "${baseline_objects}" "${candidate_objects}"
