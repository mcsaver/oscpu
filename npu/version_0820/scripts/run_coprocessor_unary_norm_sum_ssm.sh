#!/usr/bin/env bash
set -Eeuo pipefail

readonly ROOT=/home/lyg/PA/ysyx-workbench/npu/version_0820
readonly RUN_STAMP=${EPOCHREALTIME//[.,]/}
readonly RUN_ID="coprocessor-unary-norm-sum-ssm-${RUN_STAMP}-$$"
readonly COMPILER_TMP="${ROOT}/tmp/compiler/${RUN_ID}"
readonly BUILD_DIR="${ROOT}/tmp/build/${RUN_ID}"
readonly LOG_DIR="${ROOT}/tmp/logs/${RUN_ID}"
readonly MANIFEST="${ROOT}/tmp/logs/qwen-graph-manifest-v5/dispatch.manifest.json"
readonly PROFILE_CENSUS="${LOG_DIR}/manifest-profile-census.tsv"
readonly EXPECTED_CENSUS="${LOG_DIR}/expected-profile-census.tsv"

# Deliberately the first external command: every later tool, compiler and
# executable inherits one unique project-owned temporary directory.
mkdir -p "${COMPILER_TMP}" "${BUILD_DIR}" "${LOG_DIR}"
export TMPDIR="${COMPILER_TMP}"
export TMP="${COMPILER_TMP}"
export TEMP="${COMPILER_TMP}"
unset MAKEFLAGS MFLAGS
printf 'TMPDIR=%s\nTMP=%s\nTEMP=%s\n' \
    "${TMPDIR}" "${TMP}" "${TEMP}" > "${LOG_DIR}/compiler-temp.txt"

die() {
    printf '[NPU-COPROCESSOR-EXACT-RUNNER][FAIL] %s\n' "$*" >&2
    exit 1
}

[[ -r "${MANIFEST}" ]] || die "missing frozen v5 manifest: ${MANIFEST}"

# One normalized key covers every descriptor field material to the public
# admission table.  Source view offsets are aggregated rather than grouped:
# runtime passes post-view pointers, while the frozen child descriptor carries
# a zero view witness.  The L2 profile therefore remains one physical profile
# with the manifest-proven source views 0 and 8192.
jq -r '
  [.manifest.nodes[]
   | select(.descriptor.op_name == "UNARY"
            or .descriptor.op_name == "GLU"
            or .descriptor.op_name == "RMS_NORM"
            or .descriptor.op_name == "L2_NORM"
            or .descriptor.op_name == "SUM_ROWS"
            or .descriptor.op_name == "SSM_CONV")
   | {
       op: .descriptor.op_name,
       desc: (.descriptor.op_desc // "-"),
       id: .descriptor.op_id,
       dne: (.descriptor.ne | join("x")),
       dnb: (.descriptor.nb | join(",")),
       dt: .descriptor.type_id,
       df: .descriptor.flags,
       dv: .descriptor.view_offs,
       p0: .descriptor.op_params_hex[0:8],
       tz: (.descriptor.op_params_hex[8:] | test("^0+$")),
       arity: (.sources | length),
       s0ne: (.sources[0].descriptor.ne | join("x")),
       s0nb: (.sources[0].descriptor.nb | join(",")),
       s0t: .sources[0].descriptor.type_id,
       s0f: .sources[0].descriptor.flags,
       s0v: .sources[0].descriptor.view_offs,
       s1ne: (if (.sources | length) > 1
              then (.sources[1].descriptor.ne | join("x")) else "-" end),
       s1nb: (if (.sources | length) > 1
              then (.sources[1].descriptor.nb | join(",")) else "-" end),
       s1t: (if (.sources | length) > 1
             then .sources[1].descriptor.type_id else "-" end),
       s1f: (if (.sources | length) > 1
             then .sources[1].descriptor.flags else "-" end),
       s1v: (if (.sources | length) > 1
             then .sources[1].descriptor.view_offs else "-" end)
     }]
  | group_by([.op, .desc, .id, .dne, .dnb, .dt, .df, .dv, .p0,
              .tz, .arity, .s0ne, .s0nb, .s0t, .s0f,
              .s1ne, .s1nb, .s1t, .s1f])
  | map([length, .[0].op, .[0].desc, .[0].id, .[0].dne, .[0].dnb,
         .[0].dt, .[0].df, .[0].dv, .[0].p0, .[0].tz, .[0].arity,
         .[0].s0ne, .[0].s0nb, .[0].s0t, .[0].s0f,
         ([.[].s0v] | unique | map(tostring) | join(",")),
         .[0].s1ne, .[0].s1nb, .[0].s1t, .[0].s1f,
         ([.[].s1v] | unique | map(tostring) | join(","))])
  | sort_by(.[1], .[2], .[4])[]
  | @tsv
' "${MANIFEST}" > "${PROFILE_CENSUS}"

printf '%s\n' \
  $'24\tGLU\tSWIGLU\t100\t3584x1x1x1\t4,14336,14336,14336\t0\t16\t0\t02000000\ttrue\t2\t3584x1x1x1\t4,14336,14336,14336\t0\t16\t0\t3584x1x1x1\t4,14336,14336,14336\t0\t16\t0' \
  $'36\tL2_NORM\tL2_NORM\t28\t128x16x1x1\t4,512,8192,8192\t0\t16\t0\tbd378635\ttrue\t1\t128x16x1x1\t4,512,24576,24576\t0\t16\t0,8192\t-\t-\t-\t-\t-' \
  $'49\tRMS_NORM\tRMS_NORM\t25\t1024x1x1x1\t4,4096,4096,4096\t0\t16\t0\tbd378635\ttrue\t1\t1024x1x1x1\t4,4096,4096,4096\t0\t16\t0\t-\t-\t-\t-\t-' \
  $'18\tRMS_NORM\tRMS_NORM\t25\t128x16x1x1\t4,512,8192,8192\t0\t16\t0\tbd378635\ttrue\t1\t128x16x1x1\t4,512,4,8192\t0\t16\t0\t-\t-\t-\t-\t-' \
  $'6\tRMS_NORM\tRMS_NORM\t25\t256x2x1x1\t4,1024,2048,2048\t0\t16\t0\tbd378635\ttrue\t1\t256x2x1x1\t4,1024,2048,2048\t0\t16\t0\t-\t-\t-\t-\t-' \
  $'6\tRMS_NORM\tRMS_NORM\t25\t256x8x1x1\t4,1024,8192,8192\t0\t16\t0\tbd378635\ttrue\t1\t256x8x1x1\t4,2048,16384,16384\t0\t16\t0\t-\t-\t-\t-\t-' \
  $'18\tSSM_CONV\tSSM_CONV\t76\t6144x1x1x1\t4,24576,24576,24576\t0\t16\t0\t00000000\ttrue\t2\t4x6144x1x1\t4,16,98304,98304\t0\t16\t0\t4x6144x1x1\t4,16,98304,98304\t0\t0\t0' \
  $'36\tSUM_ROWS\tSUM_ROWS\t15\t1x128x16x1\t4,4,512,8192\t0\t16\t0\t00000000\ttrue\t1\t128x128x16x1\t4,512,65536,1048576\t0\t16\t0\t-\t-\t-\t-\t-' \
  $'18\tUNARY\tEXP\t91\t1x1x16x1\t4,4,4,64\t0\t16\t0\t0d000000\ttrue\t1\t1x1x16x1\t4,4,4,64\t0\t16\t0\t-\t-\t-\t-\t-' \
  $'18\tUNARY\tSIGMOID\t91\t1x16x1x1\t4,4,64,64\t0\t16\t0\t07000000\ttrue\t1\t1x16x1x1\t4,4,64,64\t0\t16\t0\t-\t-\t-\t-\t-' \
  $'6\tUNARY\tSIGMOID\t91\t2048x1x1x1\t4,8192,8192,8192\t0\t16\t0\t07000000\ttrue\t1\t2048x1x1x1\t4,8192,8192,8192\t0\t16\t0\t-\t-\t-\t-\t-' \
  $'18\tUNARY\tSILU\t91\t128x16x1x1\t4,512,8192,8192\t0\t16\t0\t0a000000\ttrue\t1\t128x16x1x1\t4,512,8192,8192\t0\t16\t0\t-\t-\t-\t-\t-' \
  $'18\tUNARY\tSILU\t91\t6144x1x1x1\t4,24576,24576,24576\t0\t16\t0\t0a000000\ttrue\t1\t6144x1x1x1\t4,24576,24576,24576\t0\t16\t0\t-\t-\t-\t-\t-' \
  $'18\tUNARY\tSOFTPLUS\t91\t16x1x1x1\t4,64,64,64\t0\t16\t0\t0f000000\ttrue\t1\t16x1x1x1\t4,64,64,64\t0\t16\t0\t-\t-\t-\t-\t-' \
  > "${EXPECTED_CENSUS}"

diff -u "${EXPECTED_CENSUS}" "${PROFILE_CENSUS}" \
    > "${LOG_DIR}/manifest-profile-diff.log"

jq -e '
  ([.manifest.nodes[] | select(.descriptor.op_name == "UNARY")] | length) == 96
  and ([.manifest.nodes[] | select(.descriptor.op_name == "GLU")] | length) == 24
  and ([.manifest.nodes[] | select(.descriptor.op_name == "RMS_NORM")] | length) == 79
  and ([.manifest.nodes[] | select(.descriptor.op_name == "L2_NORM")] | length) == 36
  and ([.manifest.nodes[] | select(.descriptor.op_name == "SUM_ROWS")] | length) == 36
  and ([.manifest.nodes[] | select(.descriptor.op_name == "SSM_CONV")] | length) == 18
' "${MANIFEST}" > "${LOG_DIR}/manifest-total-census.log"

[[ "$(wc -l < "${PROFILE_CENSUS}")" == 14 ]] ||
    die "manifest profile census is not exactly 14"
[[ "$(awk -F '\t' '{total += $1} END {print total}' \
        "${PROFILE_CENSUS}")" == 289 ]] ||
    die "manifest node census is not exactly 289"

jq -r '
  .manifest.nodes[]
  | select(.descriptor.op_name == "UNARY"
           or .descriptor.op_name == "GLU"
           or .descriptor.op_name == "RMS_NORM"
           or .descriptor.op_name == "L2_NORM"
           or .descriptor.op_name == "SUM_ROWS"
           or .descriptor.op_name == "SSM_CONV")
  | [.index, .canonical_id, .descriptor_sha256,
     .descriptor.op_name, .descriptor.op_desc,
     .semantic_key.layer_index, .semantic_key.path]
  | @tsv
' "${MANIFEST}" > "${LOG_DIR}/manifest-node-identities.tsv"

printf '%s\n' \
  'flags=0x11 dtype=F32 epoch=canonical node_count=1 deadline=0' \
  'element=dst.ne0 outer=dst.ne1*dst.ne2*dst.ne3' \
  'src0_stride=src0.nb1 src1_stride=src1.nb1 src2_stride=src0.nb2 dst_stride=dst.nb1' \
  'UNARY kernel=0x514e0005 op=subtype profile=exact-id src1=R-zero-sentinel' \
  'GLU kernel=0x514e0006 op=SWIGLU profile=6 src0/src1=R dst=W-private' \
  'REDUCE kernel=0x514e0011 op=1:SUM_ROWS,4:RMS,5:L2 profile=exact-id' \
  'SSM_CONV kernel=0x514e0022 op=76 profile=0 src0/src1=R dst=W-private' \
  'scalar0=0x358637bd only for norm; every unused scalar/iova/stride/tail field is zero' \
  > "${LOG_DIR}/public-abi-mapping.txt"

readonly -a RTL_SOURCES=(
  "${ROOT}/third_party/fpu-sp/verilog/src/lzc/lzc_wire.sv"
  "${ROOT}/third_party/fpu-sp/verilog/src/float/fp_wire.sv"
  "${ROOT}/third_party/fpu-sp/verilog/src/lzc/lzc_4.sv"
  "${ROOT}/third_party/fpu-sp/verilog/src/lzc/lzc_8.sv"
  "${ROOT}/third_party/fpu-sp/verilog/src/lzc/lzc_16.sv"
  "${ROOT}/third_party/fpu-sp/verilog/src/lzc/lzc_32.sv"
  "${ROOT}/third_party/fpu-sp/verilog/src/lzc/lzc_64.sv"
  "${ROOT}/third_party/fpu-sp/verilog/src/lzc/lzc_128.sv"
  "${ROOT}/third_party/fpu-sp/verilog/src/float/fp_ext.sv"
  "${ROOT}/third_party/fpu-sp/verilog/src/float/fp_fma.sv"
  "${ROOT}/third_party/fpu-sp/verilog/src/float/fp_fdiv.sv"
  "${ROOT}/third_party/fpu-sp/verilog/src/float/fp_rnd.sv"
  "${ROOT}/third_party/fpu-sp/verilog/src/float/fp_cvt.sv"
  "${ROOT}/third_party/hardfloat/source/RISCV/HardFloat_specialize.v"
  "${ROOT}/third_party/hardfloat/source/HardFloat_primitives.v"
  "${ROOT}/third_party/hardfloat/source/HardFloat_rawFN.v"
  "${ROOT}/third_party/hardfloat/source/isSigNaNRecFN.v"
  "${ROOT}/third_party/hardfloat/source/fNToRecFN.v"
  "${ROOT}/third_party/hardfloat/source/recFNToFN.v"
  "${ROOT}/third_party/hardfloat/source/recFNToRecFN.v"
  "${ROOT}/third_party/hardfloat/source/recFNToIN.v"
  "${ROOT}/third_party/hardfloat/source/iNToRecFN.v"
  "${ROOT}/third_party/hardfloat/source/mulAddRecFN.v"
  "${ROOT}/third_party/hardfloat/source/addRecFN.v"
  "${ROOT}/rtl/TensorNpuFp16ToFp32.v"
  "${ROOT}/rtl/TensorNpuInt32ToFp32.v"
  "${ROOT}/rtl/TensorNpuFp32AddMul.v"
  "${ROOT}/rtl/TensorNpuFp32Div.v"
  "${ROOT}/rtl/TensorNpuFp32ToFp16.v"
  "${ROOT}/rtl/TensorNpuFp32ToInt32Rmm.v"
  "${ROOT}/rtl/TensorNpuQ8DequantBlock.v"
  "${ROOT}/rtl/TensorNpuQ8GetRowsEngine.v"
  "${ROOT}/rtl/TensorNpuQ8GetRowsWritebackAdapter.v"
  "${ROOT}/rtl/TensorNpuQ8DotEngine.v"
  "${ROOT}/rtl/TensorNpuQ8ScaleAccumulator.v"
  "${ROOT}/rtl/TensorNpuQ8ReferenceQuantizer.v"
  "${ROOT}/rtl/TensorNpuQ8StreamGemv.v"
  "${ROOT}/rtl/TensorNpuQ8GemvWritebackAdapter.v"
  "${ROOT}/rtl/TensorNpuQ8RowSimdCore.v"
  "${ROOT}/rtl/TensorNpuQ8GemvPortalAdapter.v"
  "${ROOT}/rtl/TensorNpuF32GatherRepeatAdapter.v"
  "${ROOT}/rtl/TensorNpuF32TensorAlu.v"
  "${ROOT}/rtl/TensorNpuVectorF32Adapter.v"
  "${ROOT}/rtl/TensorNpuF32AluSimdCore.v"
  "${ROOT}/rtl/TensorNpuF32AluPortalAdapter.v"
  "${ROOT}/rtl/TensorNpuF32GatherRepeatPortalAdapter.v"
  "${ROOT}/rtl/TensorNpuFp32ToFp64.v"
  "${ROOT}/rtl/TensorNpuFp64Fma.v"
  "${ROOT}/rtl/TensorNpuFp64ToInt32Rmm.v"
  "${ROOT}/rtl/TensorNpuInt32ToFp64.v"
  "${ROOT}/rtl/TensorNpuFp64ToFp32Finite.v"
  "${ROOT}/rtl/TensorNpuAorExp32.v"
  "${ROOT}/rtl/TensorNpuAorLog32.v"
  "${ROOT}/rtl/TensorNpuUnaryGluElement.v"
  "${ROOT}/rtl/TensorNpuUnaryGluWritebackAdapter.v"
  "${ROOT}/rtl/TensorNpuFp32Sqrt.v"
  "${ROOT}/rtl/TensorNpuFp64Add.v"
  "${ROOT}/rtl/TensorNpuFp64ToFp32.v"
  "${ROOT}/rtl/TensorNpuFp32SquareSum64.v"
  "${ROOT}/rtl/TensorNpuFp64Pow2Scale.v"
  "${ROOT}/rtl/TensorNpuNormEngine.v"
  "${ROOT}/rtl/TensorNpuNormWritebackAdapter.v"
  "${ROOT}/rtl/TensorNpuFp32ToFp64Ieee.v"
  "${ROOT}/rtl/TensorNpuFp64AddIeee.v"
  "${ROOT}/rtl/TensorNpuFp64ToFp32Ieee.v"
  "${ROOT}/rtl/TensorNpuOrderedSumRows.v"
  "${ROOT}/rtl/TensorNpuSumRowsWritebackAdapter.v"
  "${ROOT}/rtl/TensorNpuSsmConvWritebackAdapter.v"
  "${ROOT}/rtl/TensorNpuCoprocessor.v"
  "${ROOT}/rtl/TensorNpuCommandDecoder.v"
  "${ROOT}/rtl/TensorNpuRegisterFile.v"
  "${ROOT}/rtl/TensorNpuMm2Engine.v"
  "${ROOT}/rtl/TensorNpuDmaEngine.v"
  "${ROOT}/rtl/TensorNpuLocalMemory.v"
)

readonly -a COMMON_FLAGS=(
  --timing -Wall -Wno-fatal
  -Wno-UNOPTFLAT -Wno-IMPORTSTAR -Wno-UNUSEDPARAM
  -Wno-UNUSEDSIGNAL -Wno-GENUNNAMED -Wno-DECLFILENAME
  -Wno-TIMESCALEMOD -Wno-VARHIDDEN
  --no-assert --no-trace -O3 -CFLAGS "-O3 -DNDEBUG"
  -I"${ROOT}/rtl"
  -I"${ROOT}/third_party/hardfloat/source/RISCV"
  -I"${ROOT}/third_party/hardfloat/source"
)

# The ownership lint deliberately enables WIDTH.  Every resulting WIDTH
# warning must be in vendored arithmetic; the two files owned by this slice
# must produce no warning of any class.  Builds then use the frozen public-test
# WIDTH waiver used by the existing Coprocessor closure.
verilator --lint-only "${COMMON_FLAGS[@]}" \
  --top-module tb_coprocessor_unary_norm_sum_ssm \
  "${RTL_SOURCES[@]}" \
  "${ROOT}/tests/tb_coprocessor_unary_norm_sum_ssm.sv" \
  > "${LOG_DIR}/ownership-lint.log" 2>&1

if rg '^%Warning.*(rtl/TensorNpuCoprocessor\.v|tests/tb_coprocessor_unary_norm_sum_ssm\.sv)' \
    "${LOG_DIR}/ownership-lint.log" \
    > "${LOG_DIR}/owned-warning-audit.log"; then
  die "owned Coprocessor/TB warning found"
fi
if rg '^%Warning-(WIDTHEXPAND|WIDTHTRUNC):' \
    "${LOG_DIR}/ownership-lint.log" \
    | rg -v '/third_party/(hardfloat|fpu-sp)/' \
    > "${LOG_DIR}/nonvendored-width-warning-audit.log"; then
  die "WIDTH warning escaped the exact vendored scope"
fi

if rg -n '\b(dut|u_coprocessor)\.|\bforce\b|\brelease\b|DPI|shortreal|\breal\b|\$dump|trace' \
    "${ROOT}/tests/tb_coprocessor_unary_norm_sum_ssm.sv" \
    > "${LOG_DIR}/hierarchy-host-wave-audit.log"; then
  die "forbidden hierarchy/host-float/waveform construct in public TB"
fi

[[ "$(rg -c 'TensorNpuUnaryGluWritebackAdapter u_unary_glu_writeback_adapter' \
      "${ROOT}/rtl/TensorNpuCoprocessor.v")" == 1 ]] ||
  die "Coprocessor unary/GLU child cardinality"
[[ "$(rg -c 'TensorNpuNormWritebackAdapter u_norm_writeback_adapter' \
      "${ROOT}/rtl/TensorNpuCoprocessor.v")" == 1 ]] ||
  die "Coprocessor norm child cardinality"
[[ "$(rg -c 'TensorNpuSumRowsWritebackAdapter u_sum_rows_writeback_adapter' \
      "${ROOT}/rtl/TensorNpuCoprocessor.v")" == 1 ]] ||
  die "Coprocessor SUM_ROWS child cardinality"
[[ "$(rg -c 'TensorNpuSsmConvWritebackAdapter u_ssm_conv_writeback_adapter' \
      "${ROOT}/rtl/TensorNpuCoprocessor.v")" == 1 ]] ||
  die "Coprocessor SSM_CONV child cardinality"

sha256sum "${MANIFEST}" "${RTL_SOURCES[@]}" \
  "${ROOT}/tests/tb_coprocessor_unary_norm_sum_ssm.sv" \
  "${ROOT}/tests/tb_coprocessor.sv" \
  "${ROOT}/tests/tb_coprocessor_q8_get_rows.sv" \
  "${ROOT}/tests/tb_coprocessor_q8_gemv.sv" \
  "${ROOT}/tests/tb_coprocessor_f32_gather_repeat.sv" \
  "${ROOT}/scripts/run_coprocessor_unary_norm_sum_ssm.sh" \
  > "${LOG_DIR}/source-sha256.txt"

run_public_tb() {
  local top=$1
  local tb=$2
  local marker=$3
  local timeout_seconds=$4
  local obj_dir="${BUILD_DIR}/${top}/obj_dir"
  local build_log="${LOG_DIR}/${top}.build.log"
  local run_log="${LOG_DIR}/${top}.run.log"
  local warning_log="${LOG_DIR}/${top}.owned-warning.log"

  mkdir -p "${obj_dir}"
  verilator --binary "${COMMON_FLAGS[@]}" -Wno-WIDTH \
    --Mdir "${obj_dir}" --top-module "${top}" \
    "${RTL_SOURCES[@]}" "${tb}" > "${build_log}" 2>&1

  if rg '^%Warning.*(rtl/TensorNpuCoprocessor\.v|tests/tb_coprocessor.*\.sv)' \
      "${build_log}" > "${warning_log}"; then
    die "project-owned warning while building ${top}"
  fi

  set -o pipefail
  timeout "${timeout_seconds}" "${obj_dir}/V${top}" | tee "${run_log}"
  [[ "$(grep -Fc "${marker}" "${run_log}")" == 1 ]] ||
    die "${top} final PASS marker cardinality"
  if rg '\[FAIL\]|%Error|%Fatal' "${run_log}" > /dev/null; then
    die "${top} emitted a failure marker"
  fi
}

run_public_tb tb_coprocessor_unary_norm_sum_ssm \
  "${ROOT}/tests/tb_coprocessor_unary_norm_sum_ssm.sv" \
  '[NPU-COPROCESSOR-UNARY-NORM-SUM-SSM][PASS]' 240
run_public_tb tb_coprocessor \
  "${ROOT}/tests/tb_coprocessor.sv" \
  '[NPU-COPROCESSOR][PASS]' 60
run_public_tb tb_coprocessor_q8_get_rows \
  "${ROOT}/tests/tb_coprocessor_q8_get_rows.sv" \
  '[NPU-COPROCESSOR-Q8-GET-ROWS][PASS]' 120
run_public_tb tb_coprocessor_q8_gemv \
  "${ROOT}/tests/tb_coprocessor_q8_gemv.sv" \
  '[NPU-COPROCESSOR-Q8-GEMV][PASS]' 120
run_public_tb tb_coprocessor_f32_gather_repeat \
  "${ROOT}/tests/tb_coprocessor_f32_gather_repeat.sv" \
  '[NPU-COPROCESSOR-F32-GATHER-REPEAT][PASS]' 120

if find "${BUILD_DIR}" "${LOG_DIR}" "${COMPILER_TMP}" -type f \
    \( -name '*.vcd' -o -name '*.fst' -o -name '*.ghw' -o -name '*.lxt' \
       -o -name '*.lxt2' -o -name '*.vpd' \) -print -quit | grep -q .; then
  die "waveform artifact found in fresh run"
fi

printf '[NPU-COPROCESSOR-EXACT-RUNNER][PASS] nodes=289 profiles=14 new_public=1 legacy_public=4 warning_owned=0 host_float=0 hierarchy=0 waveform=0\n'
printf 'build_dir=%s\nlog_dir=%s\ncompiler_tmp=%s\n' \
  "${BUILD_DIR}" "${LOG_DIR}" "${COMPILER_TMP}"
