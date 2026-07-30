#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "${script_dir}/../../../.." && pwd)"
npc_root="${repo_root}/npc/rv64"
vsrc_root="${npc_root}/vsrc"

top_xml="${1:-/tmp/rv64-study-npctop.xml}"
sim_xml="${2:-/tmp/rv64-study-simtop.xml}"

mapfile -t core_sources < <(
  make -s -C "${npc_root}" print-synth-rtl | tr ' ' '\n' | sed '/^$/d'
)
if ((${#core_sources[@]} == 0)); then
  printf '[elaboration-xml] ERROR: empty RTL_CORE_SRCS\n' >&2
  exit 2
fi

product_config="$(make -s -C "${npc_root}" print-product-rtl-config)"
csr_queue_head="$(
  awk -F= '$1 == "OOO_CSR_QUEUE_HEAD" { print $2 }' <<<"${product_config}"
)"
terminal_holder_assert="$(
  awk -F= '$1 == "OOO_TERMINAL_HOLDER_ASSERT" { print $2 }' <<<"${product_config}"
)"

verilator_defines=()
if [[ "${csr_queue_head}" == "1" || "${csr_queue_head}" == "y" ]]; then
  verilator_defines+=(+define+OOO_CSR_QUEUE_HEAD=1)
fi
if [[ "${terminal_holder_assert}" == "1" || "${terminal_holder_assert}" == "y" ]]; then
  verilator_defines+=(+define+OOO_TERMINAL_HOLDER_ASSERT)
fi

common_flags=(
  --xml-only
  --timescale 1ns/1ps
  -Wall
  -Wno-DECLFILENAME
  -Wno-WIDTHEXPAND
  -Wno-WIDTHTRUNC
  -Wno-UNUSEDSIGNAL
  -I"${vsrc_root}"
  -I"${vsrc_root}/include"
  "${verilator_defines[@]}"
)

sim_sources=(
  "${vsrc_root}/sim/AxiDpiSlave.sv"
  "${vsrc_root}/sim/AxiVirtioBlk.sv"
  "${vsrc_root}/sim/NpcSimTop.sv"
  "${vsrc_root}/debug/OooRedirectMuxChecker.sv"
  "${vsrc_root}/debug/OooRedirectSeqChecker.sv"
  "${vsrc_root}/debug/OooAdUpdateChecker.sv"
)

mkdir -p -- "$(dirname -- "${top_xml}")" "$(dirname -- "${sim_xml}")"

verilator "${common_flags[@]}" \
  --top-module NpcTop \
  --xml-output "${top_xml}" \
  "${core_sources[@]}"

verilator "${common_flags[@]}" \
  +define+OOO_ASSERT \
  --top-module NpcSimTop \
  --xml-output "${sim_xml}" \
  "${core_sources[@]}" \
  "${sim_sources[@]}"

printf '[elaboration-xml] product OOO_CSR_QUEUE_HEAD=%s OOO_TERMINAL_HOLDER_ASSERT=%s\n' \
  "${csr_queue_head}" "${terminal_holder_assert}"
printf '[elaboration-xml] top=%s\n' "${top_xml}"
printf '[elaboration-xml] sim=%s\n' "${sim_xml}"
printf '[elaboration-xml] PASS\n'
