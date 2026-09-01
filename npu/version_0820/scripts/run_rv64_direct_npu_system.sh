#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NPU_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
WORKSPACE_DIR="$(cd "${NPU_ROOT}/../.." && pwd)"
NPC_RV64_DIR="${WORKSPACE_DIR}/npc/rv64"
RUN_ID="rv64-direct-npu-system-$(date -u +%Y%m%dT%H%M%S)-$$"
NPU_TMP_DIR="${NPU_ROOT}/tmp/${RUN_ID}"
OBJ_DIR="${NPU_TMP_DIR}/obj"
COMPILER_TMP_DIR="${NPU_ROOT}/tmp/compiler/${RUN_ID}"
LOG_FILE="${NPU_TMP_DIR}/run.log"
NPC_OOO_STATS="${NPC_OOO_STATS:-1}"

case "${NPC_OOO_STATS}" in
  0)
    NPC_OOO_STATS_ARGS=()
    ;;
  1)
    # Keep the implication explicit at this standalone build boundary even
    # though NpcSimTop also provides an OOO=>SIM source-level closure.  Both
    # defines are read-only instrumentation and leave synthesized RTL intact.
    NPC_OOO_STATS_ARGS=(-DCONFIG_NPC_SIM_STATS -DCONFIG_NPC_OOO_STATS)
    ;;
  *)
    printf 'NPC_OOO_STATS must be 0 or 1 (got %s)\n' "${NPC_OOO_STATS}" >&2
    exit 2
    ;;
esac

mkdir -p "${OBJ_DIR}" "${COMPILER_TMP_DIR}"
export TMPDIR="${COMPILER_TMP_DIR}"
export TMP="${COMPILER_TMP_DIR}"
export TEMP="${COMPILER_TMP_DIR}"
unset MAKEFLAGS MFLAGS
mapfile -t NPC_RTL_SRCS < <(rg --files "${NPC_RV64_DIR}/vsrc" -g '*.v' -g '*.sv')
NPU_RTL_SRCS=(
  "${NPU_ROOT}/third_party/hardfloat/source/RISCV/HardFloat_specialize.v"
  "${NPU_ROOT}/third_party/hardfloat/source/HardFloat_primitives.v"
  "${NPU_ROOT}/third_party/hardfloat/source/HardFloat_rawFN.v"
  "${NPU_ROOT}/third_party/hardfloat/source/isSigNaNRecFN.v"
  "${NPU_ROOT}/third_party/hardfloat/source/fNToRecFN.v"
  "${NPU_ROOT}/third_party/hardfloat/source/recFNToFN.v"
  "${NPU_ROOT}/third_party/hardfloat/source/recFNToRecFN.v"
  "${NPU_ROOT}/third_party/hardfloat/source/recFNToIN.v"
  "${NPU_ROOT}/third_party/hardfloat/source/iNToRecFN.v"
  "${NPU_ROOT}/third_party/hardfloat/source/mulAddRecFN.v"
  "${NPU_ROOT}/third_party/hardfloat/source/addRecFN.v"
  "${NPU_ROOT}/rtl/TensorNpuFp16ToFp32.v"
  "${NPU_ROOT}/rtl/TensorNpuInt32ToFp32.v"
  "${NPU_ROOT}/rtl/TensorNpuFp32AddMul.v"
  "${NPU_ROOT}/rtl/TensorNpuFp32Div.v"
  "${NPU_ROOT}/rtl/TensorNpuFp32ToFp16.v"
  "${NPU_ROOT}/rtl/TensorNpuFp32ToInt32Rmm.v"
  "${NPU_ROOT}/rtl/TensorNpuQ8DequantBlock.v"
  "${NPU_ROOT}/rtl/TensorNpuQ8GetRowsEngine.v"
  "${NPU_ROOT}/rtl/TensorNpuQ8GetRowsWritebackAdapter.v"
  "${NPU_ROOT}/rtl/TensorNpuQ8DotEngine.v"
  "${NPU_ROOT}/rtl/TensorNpuQ8ScaleAccumulator.v"
  "${NPU_ROOT}/rtl/TensorNpuQ8ReferenceQuantizer.v"
  "${NPU_ROOT}/rtl/TensorNpuQ8StreamGemv.v"
  "${NPU_ROOT}/rtl/TensorNpuQ8GemvWritebackAdapter.v"
  "${NPU_ROOT}/rtl/TensorNpuQ8RowSimdCore.v"
  "${NPU_ROOT}/rtl/TensorNpuQ8GemvPortalAdapter.v"
  "${NPU_ROOT}/rtl/TensorNpuF32GatherRepeatAdapter.v"
  "${NPU_ROOT}/rtl/TensorNpuF32TensorAlu.v"
  "${NPU_ROOT}/rtl/TensorNpuVectorF32Adapter.v"
  "${NPU_ROOT}/rtl/TensorNpuF32AluSimdCore.v"
  "${NPU_ROOT}/rtl/TensorNpuF32AluPortalAdapter.v"
  "${NPU_ROOT}/rtl/TensorNpuF32GatherRepeatPortalAdapter.v"
  "${NPU_ROOT}/rtl/TensorNpuFp32ToFp64.v"
  "${NPU_ROOT}/rtl/TensorNpuFp64Fma.v"
  "${NPU_ROOT}/rtl/TensorNpuFp64ToInt32Rmm.v"
  "${NPU_ROOT}/rtl/TensorNpuInt32ToFp64.v"
  "${NPU_ROOT}/rtl/TensorNpuFp64ToFp32Finite.v"
  "${NPU_ROOT}/rtl/TensorNpuAorExp32.v"
  "${NPU_ROOT}/rtl/TensorNpuAorLog32.v"
  "${NPU_ROOT}/rtl/TensorNpuUnaryGluElement.v"
  "${NPU_ROOT}/rtl/TensorNpuUnaryGluWritebackAdapter.v"
  "${NPU_ROOT}/rtl/TensorNpuFp32Sqrt.v"
  "${NPU_ROOT}/rtl/TensorNpuFp64Add.v"
  "${NPU_ROOT}/rtl/TensorNpuFp64ToFp32.v"
  "${NPU_ROOT}/rtl/TensorNpuFp32SquareSum64.v"
  "${NPU_ROOT}/rtl/TensorNpuFp64Pow2Scale.v"
  "${NPU_ROOT}/rtl/TensorNpuNormEngine.v"
  "${NPU_ROOT}/rtl/TensorNpuNormWritebackAdapter.v"
  "${NPU_ROOT}/rtl/TensorNpuFp32ToFp64Ieee.v"
  "${NPU_ROOT}/rtl/TensorNpuFp64AddIeee.v"
  "${NPU_ROOT}/rtl/TensorNpuFp64ToFp32Ieee.v"
  "${NPU_ROOT}/rtl/TensorNpuOrderedSumRows.v"
  "${NPU_ROOT}/rtl/TensorNpuSumRowsWritebackAdapter.v"
  "${NPU_ROOT}/rtl/TensorNpuSsmConvWritebackAdapter.v"
  "${NPU_ROOT}/rtl/TensorNpuTensorMover.v"
  "${NPU_ROOT}/rtl/TensorNpuSetRowsEngine.v"
  "${NPU_ROOT}/rtl/TensorNpuMoverSetRowsWritebackAdapter.v"
  "${NPU_ROOT}/rtl/TensorNpuFp32Fma.v"
  "${NPU_ROOT}/rtl/TensorNpuF16AttentionMatmulWritebackAdapter.v"
  "${NPU_ROOT}/rtl/TensorNpuSoftmaxWritebackAdapter.v"
  "${NPU_ROOT}/rtl/TensorNpuFp32SincosCordic.v"
  "${NPU_ROOT}/rtl/TensorNpuRopeWritebackAdapter.v"
  "${NPU_ROOT}/rtl/TensorNpuCoprocessor.v"
  "${NPU_ROOT}/rtl/TensorNpuCommandDecoder.v"
  "${NPU_ROOT}/rtl/TensorNpuRegisterFile.v"
  "${NPU_ROOT}/rtl/TensorNpuMm2Engine.v"
  "${NPU_ROOT}/rtl/TensorNpuDmaEngine.v"
  "${NPU_ROOT}/rtl/TensorNpuLocalMemory.v"
)
mapfile -t LZC_SRCS < <(
  rg --files "${NPU_ROOT}/third_party/fpu-sp/verilog/src/lzc" -g '*.sv' |
    rg -v 'lzc_wire.sv$'
)
mapfile -t FP_SRCS < <(
  rg --files "${NPU_ROOT}/third_party/fpu-sp/verilog/src/float" -g '*.sv' |
    rg -v 'fp_wire.sv$'
)

{
  verilator --cc --exe --build -j 0 -O3 --no-assert --no-trace \
    "${NPC_OOO_STATS_ARGS[@]}" \
    -CFLAGS "-O3 -DNDEBUG -march=native -DNPC_DIRECT_NPU_SYSTEM_OOO_STATS=${NPC_OOO_STATS}" \
    -MAKEFLAGS "OPT_FAST=-O3 OPT_SLOW=-O3 OPT_GLOBAL=-O3" \
    --top-module NpcTensorNpuSystemTop \
    -Wno-fatal \
    -Wno-DECLFILENAME \
    -Wno-WIDTHEXPAND \
    -Wno-WIDTHTRUNC \
    -Wno-UNUSEDSIGNAL \
    -Wno-TIMESCALEMOD \
    -Wno-PINMISSING \
    -Wno-UNOPTFLAT \
    -I"${NPC_RV64_DIR}/vsrc" \
    -I"${NPC_RV64_DIR}/vsrc/include" \
    -I"${NPU_ROOT}/rtl" \
    -I"${NPU_ROOT}/third_party/hardfloat/source/RISCV" \
    -I"${NPU_ROOT}/third_party/hardfloat/source" \
    --Mdir "${OBJ_DIR}" \
    "${NPU_ROOT}/third_party/fpu-sp/verilog/src/float/fp_wire.sv" \
    "${NPU_ROOT}/third_party/fpu-sp/verilog/src/lzc/lzc_wire.sv" \
    "${LZC_SRCS[@]}" \
    "${FP_SRCS[@]}" \
    "${NPC_RTL_SRCS[@]}" \
    "${NPU_RTL_SRCS[@]}" \
    "${NPU_ROOT}/sim/NpcTensorNpuSystemTop.sv" \
    "${NPU_ROOT}/sim/npc_tensor_npu_system_tb.cpp"

  "${OBJ_DIR}/VNpcTensorNpuSystemTop"
} 2>&1 | tee "${LOG_FILE}"

printf 'run_dir=%s\ncompiler_tmp_dir=%s\nlog=%s\nooo_stats=%s\n' \
  "${NPU_TMP_DIR}" "${COMPILER_TMP_DIR}" "${LOG_FILE}" "${NPC_OOO_STATS}"
