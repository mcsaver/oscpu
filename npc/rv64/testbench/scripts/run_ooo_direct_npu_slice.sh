#!/usr/bin/env bash
set -euo pipefail

workspace_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
result_root="${workspace_root}/npu/version_0820/tmp/rv64-direct-npu-slice"
obj_dir="${result_root}/obj"
compiler_tmp_dir="${workspace_root}/npu/version_0820/tmp/compiler/rv64-direct-npu-slice"

mkdir -p "${obj_dir}" "${compiler_tmp_dir}"
export TMPDIR="${compiler_tmp_dir}"
export TMP="${compiler_tmp_dir}"
export TEMP="${compiler_tmp_dir}"
unset MAKEFLAGS MFLAGS
cd "${workspace_root}"

verilator --binary --timing --no-assert --no-trace \
  --top-module tb_ooo_direct_npu_slice \
  -DCONFIG_NPC_OOO_STATS \
  -O3 -CFLAGS "-O3 -DNDEBUG -march=native" \
  -Wall -Wno-fatal -Wno-TIMESCALEMOD -Wno-UNUSEDSIGNAL \
  --Mdir "${obj_dir}" \
  -Inpc/rv64/vsrc/include \
  -Inpu/version_0820/rtl \
  npc/rv64/vsrc/frontend/OooTensorPairOwner.v \
  npc/rv64/vsrc/rename_allocate/OooTensorRobSidecar.v \
  npu/version_0820/rtl/TensorNpuCommandDecoder.v \
  npc/rv64/testbench/tests/tb_ooo_direct_npu_slice.sv \
  >"${result_root}/build.log" 2>&1

"${obj_dir}/Vtb_ooo_direct_npu_slice" | tee "${result_root}/run.log"
