#!/usr/bin/env bash
set -Eeuo pipefail

readonly ROOT=/home/lyg/PA/ysyx-workbench/npu/version_0820
readonly RUN_STAMP=${EPOCHREALTIME//[.,]/}
readonly RUN_ID="coprocessor-mover-attention-softmax-rope-${RUN_STAMP}-$$"
readonly COMPILER_TMP="${ROOT}/tmp/compiler/${RUN_ID}"
readonly BUILD_DIR="${ROOT}/tmp/build/${RUN_ID}"
readonly LOG_DIR="${ROOT}/tmp/logs/${RUN_ID}"
readonly MANIFEST="${ROOT}/tmp/logs/qwen-graph-manifest-v5/dispatch.manifest.json"

# Deliberately the first external command.  jq, Verilator, make, every C++
# compiler process and every executable inherit this project-private temp.
mkdir -p "${COMPILER_TMP}" "${BUILD_DIR}" "${LOG_DIR}"
export TMPDIR="${COMPILER_TMP}"
export TMP="${COMPILER_TMP}"
export TEMP="${COMPILER_TMP}"
unset MAKEFLAGS MFLAGS
printf 'TMPDIR=%s\nTMP=%s\nTEMP=%s\n' \
  "${TMPDIR}" "${TMP}" "${TEMP}" > "${LOG_DIR}/compiler-temp.txt"

die() {
  printf '[NPU-COPROC-BATCH2-RUNNER][FAIL] %s\n' "$*" >&2
  exit 1
}

[[ -r "${MANIFEST}" ]] || die "missing frozen v5 manifest"

# Normalize every manifest field material to this batch's fourteen physical
# profiles.  The hard-coded SHA is over the sorted canonical JSONL below; a
# one-bit change in dtype, flag, ne/nb, view, op id, any source, or any of the
# complete 512 op-parameter bits makes the diff fail.
cat > "${LOG_DIR}/manifest-profile-census.jq" <<'JQ'
def wanted:
 (.descriptor.op_name == "CPY") or
 (.descriptor.op_name == "CONT") or
 (.descriptor.op_name == "CONCAT") or
 (.descriptor.op_name == "SET_ROWS") or
 (.descriptor.op_name == "SOFT_MAX") or
 (.descriptor.op_name == "ROPE" and .descriptor.op_id == 48) or
 (.descriptor.op_name == "MUL_MAT" and .descriptor.op_id == 29
  and .sources[0].descriptor.type_id == 1);
def family:
 if (.descriptor.op_name == "CPY" or .descriptor.op_name == "CONT"
     or .descriptor.op_name == "CONCAT") then "mover"
 elif .descriptor.op_name == "SET_ROWS" then "set_rows"
 elif .descriptor.op_name == "MUL_MAT" then "attention"
 elif .descriptor.op_name == "SOFT_MAX" then "softmax"
 else "rope" end;
def pid:
 if .descriptor.op_name == "CONCAT" then 0
 elif .descriptor.op_name == "CONT" then
   (if .sources[0].descriptor.view_offs == 0 then 1 else 2 end)
 elif .descriptor.op_name == "CPY" then
   (if .descriptor.ne[1] == 0 and .descriptor.ne[0] == 18432 then 3
    elif .descriptor.ne[1] == 1 and .descriptor.ne[0] == 18432 then 4
    elif .descriptor.ne[1] == 0 then 5 else 6 end)
 elif .descriptor.op_name == "SET_ROWS" then
   (if .descriptor.nb[1] == 2 then 7 else 8 end)
 elif .descriptor.op_name == "MUL_MAT" then
   (if (.descriptor.op_params_hex | startswith("0a000000")) then 0 else 1 end)
 elif .descriptor.op_name == "SOFT_MAX" then 0
 else (if .descriptor.ne[1] == 8 then 0 else 1 end) end;
[.manifest.nodes[] | select(wanted) |
 {family: family, profile: pid,
  sig: {op:.descriptor.op_name, desc:.descriptor.op_desc,
        id:.descriptor.op_id, ne:.descriptor.ne, nb:.descriptor.nb,
        type:.descriptor.type_id, flags:.descriptor.flags,
        view:.descriptor.view_offs, params:.descriptor.op_params_hex,
        srcs:[.sources[] |
          {slot:.slot, ne:.descriptor.ne, nb:.descriptor.nb,
           type:.descriptor.type_id, flags:.descriptor.flags,
           view:.descriptor.view_offs}]}}]
| sort_by(.family,.profile,(.sig|tojson))
| group_by([.family,.profile,.sig])
| .[]
| {family:.[0].family, profile:.[0].profile,
   count:length, signature:.[0].sig}
JQ

jq -cS -f "${LOG_DIR}/manifest-profile-census.jq" "${MANIFEST}" \
  > "${LOG_DIR}/manifest-profiles.actual.jsonl"
printf '%s  %s\n' \
  'b1a0c480cd652e83b40401d27ecca686b500a6eda79ec4ea3aea55c9f5e6f17b' \
  'manifest-profiles.actual.jsonl' \
  > "${LOG_DIR}/manifest-profiles.expected.sha256"
(cd "${LOG_DIR}" && sha256sum manifest-profiles.actual.jsonl) \
  > "${LOG_DIR}/manifest-profiles.actual.sha256"
diff -u "${LOG_DIR}/manifest-profiles.expected.sha256" \
  "${LOG_DIR}/manifest-profiles.actual.sha256" \
  > "${LOG_DIR}/manifest-profiles.diff"

jq -e '
  ([.manifest.nodes[] | select(.descriptor.op_name == "CPY")] | length) == 72
  and ([.manifest.nodes[] | select(.descriptor.op_name == "CONT")] | length) == 12
  and ([.manifest.nodes[] | select(.descriptor.op_name == "CONCAT")] | length) == 18
  and ([.manifest.nodes[] | select(.descriptor.op_name == "SET_ROWS")] | length) == 12
  and ([.manifest.nodes[] | select(.descriptor.op_name == "MUL_MAT"
       and .descriptor.op_id == 29
       and .sources[0].descriptor.type_id == 1)] | length) == 12
  and ([.manifest.nodes[] | select(.descriptor.op_name == "SOFT_MAX")] | length) == 6
  and ([.manifest.nodes[] | select(.descriptor.op_name == "ROPE"
       and .descriptor.op_id == 48)] | length) == 12
' "${MANIFEST}" > "${LOG_DIR}/manifest-node-census.log"
[[ "$(wc -l < "${LOG_DIR}/manifest-profiles.actual.jsonl")" == 14 ]] ||
  die "manifest physical profile count is not 14"
[[ "$(jq -s 'map(.count) | add' \
       "${LOG_DIR}/manifest-profiles.actual.jsonl")" == 144 ]] ||
  die "manifest selected node count is not 144"

jq -r '
 .manifest.nodes[]
 | select(.descriptor.op_name == "CPY"
          or .descriptor.op_name == "CONT"
          or .descriptor.op_name == "CONCAT"
          or .descriptor.op_name == "SET_ROWS"
          or .descriptor.op_name == "SOFT_MAX"
          or (.descriptor.op_name == "ROPE" and .descriptor.op_id == 48)
          or (.descriptor.op_name == "MUL_MAT" and .descriptor.op_id == 29
              and .sources[0].descriptor.type_id == 1))
 | [.index,.canonical_id,.descriptor_sha256,.descriptor.op_name,
    .descriptor.op_id,.semantic_key.layer_index,.semantic_key.path]
 | @tsv
' "${MANIFEST}" > "${LOG_DIR}/manifest-node-identities.tsv"
[[ "$(wc -l < "${LOG_DIR}/manifest-node-identities.tsv")" == 144 ]] ||
  die "canonical identity census is not 144"

printf '%s\n' \
  'common: flags=0x11 context=0x43414e01 dtype=F32 epoch=1 node_count=1 deadline=0' \
  'common: element=dst.ne0 outer=dst.ne1*dst.ne2*dst.ne3' \
  'common: src0_stride=src0.nb1 src1_stride=src1.nb1 src2_stride=src0.nb2 dst_stride=dst.nb1' \
  'MOVER_F32 kernel=0x514e0007 op=22/35/34 profiles=0..6' \
  'SET_ROWS_F32 kernel=0x514e0008 op=42 profiles=7..8 src2_iova=dst_iova' \
  'ATTENTION_F16 kernel=0x514e0009 op=29 profiles=0..1' \
  'ROPE_F32 kernel=0x514e000a op=48 profiles=0..1 full_op_params=512b' \
  'SOFTMAX_F32 kernel=0x514e0011 op=6 profile=0' \
  'unused public scalar/iova/stride/tail fields are exactly zero' \
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
  "${ROOT}/rtl/TensorNpuTensorMover.v"
  "${ROOT}/rtl/TensorNpuSetRowsEngine.v"
  "${ROOT}/rtl/TensorNpuMoverSetRowsWritebackAdapter.v"
  "${ROOT}/rtl/TensorNpuFp32Fma.v"
  "${ROOT}/rtl/TensorNpuF16AttentionMatmulWritebackAdapter.v"
  "${ROOT}/rtl/TensorNpuSoftmaxWritebackAdapter.v"
  "${ROOT}/rtl/TensorNpuFp32SincosCordic.v"
  "${ROOT}/rtl/TensorNpuRopeWritebackAdapter.v"
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

verilator --lint-only "${COMMON_FLAGS[@]}" \
  --top-module tb_coprocessor_mover_attention_softmax_rope \
  "${RTL_SOURCES[@]}" \
  "${ROOT}/tests/tb_coprocessor_mover_attention_softmax_rope.sv" \
  > "${LOG_DIR}/ownership-lint.log" 2>&1
if rg '^%Warning.*(rtl/TensorNpuCoprocessor\.v|tests/tb_coprocessor_mover_attention_softmax_rope\.sv)' \
    "${LOG_DIR}/ownership-lint.log" \
    > "${LOG_DIR}/owned-warning-audit.log"; then
  die "owned Coprocessor/new-TB warning found"
fi

if rg -n '\b(dut|u_coprocessor)\.|\bforce\b|\brelease\b|DPI|shortreal|\breal\b|\$dump|trace' \
    "${ROOT}/tests/tb_coprocessor_mover_attention_softmax_rope.sv" \
    > "${LOG_DIR}/hierarchy-host-wave-audit.log"; then
  die "forbidden hierarchy/host-float/waveform construct in public TB"
fi

for child in \
  u_mover_set_rows_writeback_adapter \
  u_f16_attention_matmul_writeback_adapter \
  u_softmax_writeback_adapter \
  u_rope_writeback_adapter; do
  [[ "$(rg -c "${child} \\(" "${ROOT}/rtl/TensorNpuCoprocessor.v")" == 1 ]] ||
    die "Coprocessor child cardinality: ${child}"
done
[[ "$(rg -c 'localparam \[511:0\] ROPE_FROZEN_OP_PARAMS' \
      "${ROOT}/rtl/TensorNpuCoprocessor.v")" == 1 ]] ||
  die "full-width RoPE params witness missing"

sha256sum "${MANIFEST}" "${RTL_SOURCES[@]}" \
  "${ROOT}/tests/tb_coprocessor_mover_attention_softmax_rope.sv" \
  "${ROOT}/tests/tb_coprocessor.sv" \
  "${ROOT}/tests/tb_coprocessor_q8_get_rows.sv" \
  "${ROOT}/tests/tb_coprocessor_q8_gemv.sv" \
  "${ROOT}/tests/tb_coprocessor_f32_gather_repeat.sv" \
  "${ROOT}/tests/tb_coprocessor_unary_norm_sum_ssm.sv" \
  "${ROOT}/scripts/run_coprocessor_mover_attention_softmax_rope.sh" \
  > "${LOG_DIR}/source-sha256.txt"

build_public_tb() {
  local top=$1 tb=$2
  local obj_dir="${BUILD_DIR}/${top}/obj_dir"
  local build_log="${LOG_DIR}/${top}.build.log"
  local warning_log="${LOG_DIR}/${top}.owned-warning.log"
  mkdir -p "${obj_dir}"
  verilator --binary "${COMMON_FLAGS[@]}" -Wno-WIDTH \
    --Mdir "${obj_dir}" --top-module "${top}" \
    "${RTL_SOURCES[@]}" "${tb}" > "${build_log}" 2>&1
  if rg '^%Warning.*(rtl/TensorNpuCoprocessor\.v|tests/tb_coprocessor.*\.sv)' \
      "${build_log}" > "${warning_log}"; then
    die "project-owned warning while building ${top}"
  fi
}

run_public_tb() {
  local top=$1 tb=$2 marker=$3 timeout_seconds=$4
  local obj_dir="${BUILD_DIR}/${top}/obj_dir"
  local run_log="${LOG_DIR}/${top}.run.log"
  build_public_tb "${top}" "${tb}"
  set -o pipefail
  timeout "${timeout_seconds}" "${obj_dir}/V${top}" | tee "${run_log}"
  [[ "$(grep -Fc "${marker}" "${run_log}")" == 1 ]] ||
    die "${top} PASS marker cardinality"
  if rg '\[FAIL\]|%Error|%Fatal' "${run_log}" > /dev/null; then
    die "${top} emitted a failure marker"
  fi
}

run_batch2_groups() {
  local top=tb_coprocessor_mover_attention_softmax_rope
  local tb="${ROOT}/tests/tb_coprocessor_mover_attention_softmax_rope.sv"
  local binary="${BUILD_DIR}/${top}/obj_dir/V${top}"
  local group status bitmap aggregate=0 failed=0
  local -a expected_bitmap=(01ff 0200 0400 3800)
  local -a expected_profiles=(9 1 1 3)
  local -a pids=()

  build_public_tb "${top}" "${tb}"
  for group in 0 1 2 3; do
    timeout 3600 "${binary}" +GROUP="${group}" \
      > "${LOG_DIR}/${top}.group${group}.run.log" 2>&1 &
    pids[${group}]=$!
  done

  printf 'group\texit\tmarker\tprofiles\tfailure_text\n' \
    > "${LOG_DIR}/batch2-group-status.tsv"
  for group in 0 1 2 3; do
    set +e
    wait "${pids[${group}]}"
    status=$?
    set -e
    local marker_count profile_count failure_count
    marker_count=$(grep -Fc \
      "[NPU-COPROC-BATCH2][GROUP-PASS] group=${group} profile_bitmap=${expected_bitmap[${group}]}" \
      "${LOG_DIR}/${top}.group${group}.run.log" || true)
    profile_count=$(grep -Fc '[NPU-COPROC-BATCH2][PROFILE-PASS]' \
      "${LOG_DIR}/${top}.group${group}.run.log" || true)
    failure_count=$(grep -Ec '\[FAIL\]|%Error|%Fatal' \
      "${LOG_DIR}/${top}.group${group}.run.log" || true)
    printf '%s\t%s\t%s\t%s\t%s\n' "${group}" "${status}" \
      "${marker_count}" "${profile_count}" "${failure_count}" \
      >> "${LOG_DIR}/batch2-group-status.tsv"
    if [[ "${status}" != 0 || "${marker_count}" != 1 ||
          "${profile_count}" != "${expected_profiles[${group}]}" ||
          "${failure_count}" != 0 ]]; then
      failed=1
    fi
    if [[ "${status}" == 0 && "${marker_count}" == 1 &&
          "${profile_count}" == "${expected_profiles[${group}]}" &&
          "${failure_count}" == 0 ]]; then
      bitmap=${expected_bitmap[${group}]}
      aggregate=$((aggregate | 16#${bitmap}))
    fi
    rg '\[NPU-COPROC-BATCH2\]\[(START|PROFILE-PASS|GROUP-PASS)\]' \
      "${LOG_DIR}/${top}.group${group}.run.log" || true
  done
  printf 'profile_bitmap=%04x\n' "${aggregate}" \
    > "${LOG_DIR}/batch2-profile-aggregate.log"
  [[ "${failed}" == 0 && "${aggregate}" == 16383 ]] ||
    die "batch2 group aggregate failed; all four children were reaped"
  printf '[NPU-COPROC-BATCH2][PASS] frozen_nodes=144 exact_profiles=14 mover=7 set_rows=2 attention=2 softmax=1 rope=2 static=8 late=2 timeout_drain=1 identity_backpressure=2 single_outstanding=1 host_float=0\n' \
    | tee -a "${LOG_DIR}/batch2-profile-aggregate.log"
}

run_batch2_groups

if [[ "${NPU_BATCH2_FOCUS:-full}" != new ]]; then
  run_public_tb tb_coprocessor \
    "${ROOT}/tests/tb_coprocessor.sv" '[NPU-COPROCESSOR][PASS]' 60
  run_public_tb tb_coprocessor_q8_get_rows \
    "${ROOT}/tests/tb_coprocessor_q8_get_rows.sv" \
    '[NPU-COPROCESSOR-Q8-GET-ROWS][PASS]' 120
  run_public_tb tb_coprocessor_q8_gemv \
    "${ROOT}/tests/tb_coprocessor_q8_gemv.sv" \
    '[NPU-COPROCESSOR-Q8-GEMV][PASS]' 120
  run_public_tb tb_coprocessor_f32_gather_repeat \
    "${ROOT}/tests/tb_coprocessor_f32_gather_repeat.sv" \
    '[NPU-COPROCESSOR-F32-GATHER-REPEAT][PASS]' 120
  run_public_tb tb_coprocessor_unary_norm_sum_ssm \
    "${ROOT}/tests/tb_coprocessor_unary_norm_sum_ssm.sv" \
    '[NPU-COPROCESSOR-UNARY-NORM-SUM-SSM][PASS]' 300
fi

if find "${BUILD_DIR}" "${LOG_DIR}" "${COMPILER_TMP}" -type f \
    \( -name '*.vcd' -o -name '*.fst' -o -name '*.ghw' -o -name '*.lxt' \
       -o -name '*.lxt2' -o -name '*.vpd' \) -print -quit | grep -q .; then
  die "waveform artifact found in fresh run"
fi

printf '[NPU-COPROC-BATCH2-RUNNER][PASS] frozen_nodes=144 exact_profiles=14 new_public=1 legacy_public=%s warning_owned=0 host_float=0 hierarchy=0 waveform=0\n' \
  "$([[ "${NPU_BATCH2_FOCUS:-full}" == new ]] && printf 0 || printf 5)"
printf 'build_dir=%s\nlog_dir=%s\ncompiler_tmp=%s\n' \
  "${BUILD_DIR}" "${LOG_DIR}" "${COMPILER_TMP}"
