#!/usr/bin/env bash

set -euo pipefail

repo_root=/home/lyg/PA/ysyx-workbench
run_dir="${repo_root}/.github/task-runs/2026-08-06-rv64-v15p-adapter-final-b-fallthrough-f7a"
fixture="${run_dir}/driver/sta-export-compat-fixture.v"
sta_tcl="${run_dir}/driver/opensta-read-smoke.tcl"
evidence_dir="${run_dir}/evidence/mapped-sta-ab/sta-export-smoke"
status_path="${evidence_dir}/status.txt"
runtime_base="${repo_root}/.github/runtime-artifacts/v15p-sta-export-smoke"
std_lib="${repo_root}/yosys-sta/pdk/icsprout55/IP/STD_cell/ics55_LLSC_H7C_V1p10C100/ics55_LLSC_H7CL/liberty/ics55_LLSC_H7CL_typ_tt_1p2_25_nldm.lib"
opensta=/home/lyg/tools/OpenSTA/build/sta
yosys="${repo_root}/oss-cad-suite/bin/yosys"
runtime_dir=
runtime_bytes=0
cleanup_rc=0

mkdir -p -- "${runtime_base}" "${evidence_dir}"
runtime_dir=$(mktemp -d "${runtime_base}/run.XXXXXX")

cleanup() {
  local resolved
  if [[ -z "${runtime_dir}" || ! -e "${runtime_dir}" ]]; then
    return 0
  fi
  resolved=$(realpath -m -- "${runtime_dir}") || return 1
  case "${resolved}" in
    "${runtime_base}"/run.*) rm -r -- "${resolved}" ;;
    *) return 2 ;;
  esac
}

finish() {
  local command_rc=$?
  if [[ -n "${runtime_dir}" && -e "${runtime_dir}" ]]; then
    runtime_bytes=$(du -sb "${runtime_dir}" | awk '{print $1}')
  fi
  cleanup || cleanup_rc=$?
  rmdir --ignore-fail-on-non-empty "${runtime_base}" 2>/dev/null || true
  if [[ "${command_rc}" -eq 0 && "${cleanup_rc}" -eq 0 && ! -e "${runtime_dir}" ]]; then
    printf 'PASS runtime_bytes_deleted=%s cleanup_rc=0\n' "${runtime_bytes}" >"${status_path}"
  else
    printf 'FAIL rc=%s runtime_bytes_deleted=%s cleanup_rc=%s\n' \
      "${command_rc}" "${runtime_bytes}" "${cleanup_rc}" >"${status_path}"
  fi
}
trap finish EXIT

result_root="${runtime_dir}/sta"
mapped_dir="${result_root}/StaExportCompatFixture-200MHz"
netlist="${mapped_dir}/StaExportCompatFixture.netlist.v"
marker="${runtime_dir}/opensta-read-smoke.marker"

/usr/bin/timeout --signal=TERM --kill-after=10s 300s \
  make -C "${repo_root}/yosys-sta" syn \
    O="${result_root}" DESIGN=StaExportCompatFixture PDK=icsprout55 \
    CLK_FREQ_MHZ=200 CLK_PORT_NAME=clk RTL_FILES="${fixture}" \
    VERILOG_INCLUDE_DIRS= VERILOG_DEFINES= SYNTH_FLATTEN=0 SYNTH_SHARE=0 \
    SYNTH_PUBLIC_AUTONAME=0 SYNTH_DFF_AUTONAME=0 \
    SYNTH_STA_FLATTEN_EXPORT=1 SYNTH_STAGE_SCC=1 \
    KEEP_HIERARCHY_MODULES=StaExportLeaf \
    YOSYS="${yosys}" YOSYS_ARGS="-q -Q -T" YOSYS_LOG_ARGS= \
    >"${evidence_dir}/yosys-console.log" 2>&1

for path in "${netlist}" "${mapped_dir}/synth_check.txt" \
  "${mapped_dir}/synth_stat.txt" "${mapped_dir}/sta_export_check.txt" \
  "${mapped_dir}/synth_scc_post_abc.txt" \
  "${mapped_dir}/synth_scc_post_hilomap.txt" \
  "${mapped_dir}/synth_scc_post_export.txt"; do
  [[ -s "${path}" && ! -L "${path}" ]]
done
grep -Fq 'Found and reported 0 problems.' "${mapped_dir}/synth_check.txt"
grep -Fq 'Found and reported 0 problems.' "${mapped_dir}/sta_export_check.txt"
for stage in post_abc post_hilomap post_export; do
  grep -Fq 'Found 0 SCCs.' "${mapped_dir}/synth_scc_${stage}.txt"
  cp -- "${mapped_dir}/synth_scc_${stage}.txt" \
    "${evidence_dir}/synth_scc_${stage}.txt"
  cp -- "${mapped_dir}/synth_scc_${stage}_dump.txt" \
    "${evidence_dir}/synth_scc_${stage}_dump.txt"
done
if rg -n '\\$paramod|wire signed' "${netlist}" \
    >"${evidence_dir}/forbidden-netlist-patterns.txt"; then
  exit 1
fi

/usr/bin/timeout --signal=TERM --kill-after=10s 120s \
  /usr/bin/env V15P_SMOKE_STD_LIB="${std_lib}" V15P_SMOKE_NETLIST="${netlist}" \
    V15P_SMOKE_MARKER="${marker}" "${opensta}" "${sta_tcl}" \
    >"${evidence_dir}/opensta-console.log" 2>&1
grep -Fxq 'status=PASS' "${marker}"

cp -- "${mapped_dir}/synth_check.txt" "${evidence_dir}/synth_check.txt"
cp -- "${mapped_dir}/synth_stat.txt" "${evidence_dir}/synth_stat.txt"
cp -- "${mapped_dir}/sta_export_check.txt" "${evidence_dir}/sta_export_check.txt"
sha256sum "${netlist}" >"${evidence_dir}/netlist.sha256"
stat -c 'netlist_size_bytes=%s' "${netlist}" >"${evidence_dir}/netlist.size"
printf 'fixture_sha256=%s\nyosys_tcl_sha256=%s\nopensta_sha256=%s\n' \
  "$(sha256sum "${fixture}" | awk '{print $1}')" \
  "$(sha256sum "${repo_root}/yosys-sta/scripts/yosys.tcl" | awk '{print $1}')" \
  "$(sha256sum "${opensta}" | awk '{print $1}')" \
  >"${evidence_dir}/provenance.txt"
