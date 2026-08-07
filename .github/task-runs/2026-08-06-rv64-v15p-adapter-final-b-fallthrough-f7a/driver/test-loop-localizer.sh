#!/usr/bin/env bash
set -euo pipefail

repo_root=/home/lyg/PA/ysyx-workbench
run_root="${repo_root}/.github/task-runs/2026-08-06-rv64-v15p-adapter-final-b-fallthrough-f7a"
driver="${run_root}/driver"
fixture="${driver}/fixtures/loop-localize"
evidence="${run_root}/evidence/mapped-sta-ab"
tool="${driver}/v15p_mapped_sta.py"
std_lib="${repo_root}/yosys-sta/pdk/icsprout55/IP/STD_cell/ics55_LLSC_H7C_V1p10C100/ics55_LLSC_H7CL/liberty/ics55_LLSC_H7CL_typ_tt_1p2_25_nldm.lib"
positive="${evidence}/loop-localizer-selftest.json"
negative_output="${evidence}/loop-localizer-negative-mutation.json"
negative_log="${evidence}/loop-localizer-negative-mutation.log"

for command_name in python3 rg rm; do
  command -v "${command_name}" >/dev/null
done
for input in "${tool}" "${std_lib}" "${fixture}/NpcTop.netlist.v" \
  "${fixture}/NpcTop.broken-netlist.v" "${fixture}/opensta-check-setup.txt" \
  "${fixture}/opensta-top40.rpt"; do
  [[ -f "${input}" && ! -L "${input}" && -s "${input}" ]]
done

python3 -B "${tool}" loop-localize \
  --setup "${fixture}/opensta-check-setup.txt" \
  --top40 "${fixture}/opensta-top40.rpt" \
  --netlist "${fixture}/NpcTop.netlist.v" --std-lib "${std_lib}" \
  --output "${positive}"
rg -q '"status": "PASS"' "${positive}"
rg -q '"arc_count": 2' "${positive}"

rm -f -- "${negative_output}"
if python3 -B "${tool}" loop-localize \
    --setup "${fixture}/opensta-check-setup.txt" \
    --top40 "${fixture}/opensta-top40.rpt" \
    --netlist "${fixture}/NpcTop.broken-netlist.v" --std-lib "${std_lib}" \
    --output "${negative_output}" >"${negative_log}" 2>&1; then
  echo '[V15P-MAPPED-LOOP-LOCALIZE-SELFTEST][FAIL] broken loop net accepted' >&2
  exit 1
fi
[[ ! -e "${negative_output}" ]]
rg -q 'loop edge net mismatch' "${negative_log}"
printf '%s\n' 'positive_fixture=PASS' 'broken_net_mutation=REJECTED' \
  >"${evidence}/loop-localizer-selftest.txt"
echo '[V15P-MAPPED-LOOP-LOCALIZE-SELFTEST][PASS] positive=1 negative=1'
