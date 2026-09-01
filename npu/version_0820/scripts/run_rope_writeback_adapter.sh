#!/usr/bin/env bash
set -euo pipefail

ROOT=/home/lyg/PA/ysyx-workbench/npu/version_0820
MANIFEST="${ROOT}/tmp/logs/qwen-graph-manifest-v5/dispatch.manifest.json"
LLAMA_BUILD="${ROOT}/tmp/build/llama.cpp"
RUN_STAMP=${EPOCHREALTIME//./}
RUN_ID="rope-writeback-${RUN_STAMP}-$$"
BUILD_DIR="${ROOT}/tmp/build/${RUN_ID}"
LOG_DIR="${ROOT}/tmp/logs/${RUN_ID}"
OBJ_DIR="${BUILD_DIR}/obj_dir"
COMPILER_TMP="${ROOT}/tmp/compiler/${RUN_ID}"
PROFILE_CENSUS="${LOG_DIR}/manifest-profile-census.tsv"
EXPECTED_CENSUS="${LOG_DIR}/expected-profile-census.tsv"

# Deliberately the first external command.  jq, Verilator, the compiler, and
# the executable all inherit the same unique project-owned compiler temp.
mkdir -p "${COMPILER_TMP}" "${OBJ_DIR}" "${LOG_DIR}"
export TMPDIR="${COMPILER_TMP}"
export TMP="${COMPILER_TMP}"
export TEMP="${COMPILER_TMP}"
unset MAKEFLAGS MFLAGS
printf 'TMPDIR=%s\nTMP=%s\nTEMP=%s\n' \
    "${TMPDIR}" "${TMP}" "${TEMP}" > "${LOG_DIR}/compiler-temp.txt"

if [[ ! -r "${MANIFEST}" ]]; then
    printf 'missing frozen v5 manifest: %s\n' "${MANIFEST}" >&2
    exit 1
fi

# Machine-derive both exact profiles and the complete 64-byte op-params
# record.  No hand-authored profile field is accepted silently.
jq -r '
    [.manifest.nodes[]
     | select(.descriptor.op_name == "ROPE"
              and .descriptor.op_id == 48)
     | {
         profile: (if .descriptor.ne[1] == 8 then 0 else 1 end),
         op: .descriptor.op_name,
         op_id: .descriptor.op_id,
         dst_ne: (.descriptor.ne | join("x")),
         dst_nb: (.descriptor.nb | join(",")),
         dst_dtype: .descriptor.type_name,
         dst_type: .descriptor.type_id,
         dst_flags: .descriptor.flags,
         dst_view: .descriptor.view_offs,
         op_params: .descriptor.op_params_hex,
         arity: (.sources | length),
         src0_ne: (.sources[0].descriptor.ne | join("x")),
         src0_nb: (.sources[0].descriptor.nb | join(",")),
         src0_dtype: .sources[0].descriptor.type_name,
         src0_type: .sources[0].descriptor.type_id,
         src0_flags: .sources[0].descriptor.flags,
         src0_view: .sources[0].descriptor.view_offs,
         src1_ne: (.sources[1].descriptor.ne | join("x")),
         src1_nb: (.sources[1].descriptor.nb | join(",")),
         src1_dtype: .sources[1].descriptor.type_name,
         src1_type: .sources[1].descriptor.type_id,
         src1_flags: .sources[1].descriptor.flags,
         src1_view: .sources[1].descriptor.view_offs
       }]
    | group_by([.profile, .op, .op_id, .dst_ne, .dst_nb, .dst_dtype,
                .dst_type, .dst_flags, .dst_view, .op_params, .arity,
                .src0_ne, .src0_nb, .src0_dtype, .src0_type, .src0_flags,
                .src0_view, .src1_ne, .src1_nb, .src1_dtype, .src1_type,
                .src1_flags, .src1_view])
    | sort_by(.[0].profile)[]
    | [length, .[0].profile, .[0].op, .[0].op_id,
       .[0].dst_ne, .[0].dst_nb, .[0].dst_dtype, .[0].dst_type,
       .[0].dst_flags, .[0].dst_view, .[0].op_params, .[0].arity,
       .[0].src0_ne, .[0].src0_nb, .[0].src0_dtype, .[0].src0_type,
       .[0].src0_flags, .[0].src0_view,
       .[0].src1_ne, .[0].src1_nb, .[0].src1_dtype, .[0].src1_type,
       .[0].src1_flags, .[0].src1_view]
    | @tsv
' "${MANIFEST}" > "${PROFILE_CENSUS}"

FROZEN_PARAMS=00000000400000002800000000000000000004008096184b0000803f000000000000803f000000420000803f0b0000000b0000000a0000000000000000000000
printf '%s\n' \
    "6"$'\t'"0"$'\t'"ROPE"$'\t'"48"$'\t'"256x8x1x1"$'\t'"4,1024,8192,8192"$'\t'"f32"$'\t'"0"$'\t'"16"$'\t'"0"$'\t'"${FROZEN_PARAMS}"$'\t'"2"$'\t'"256x8x1x1"$'\t'"4,1024,8192,8192"$'\t'"f32"$'\t'"0"$'\t'"16"$'\t'"0"$'\t'"4x1x1x1"$'\t'"4,16,16,16"$'\t'"i32"$'\t'"26"$'\t'"1"$'\t'"0" \
    "6"$'\t'"1"$'\t'"ROPE"$'\t'"48"$'\t'"256x2x1x1"$'\t'"4,1024,2048,2048"$'\t'"f32"$'\t'"0"$'\t'"16"$'\t'"0"$'\t'"${FROZEN_PARAMS}"$'\t'"2"$'\t'"256x2x1x1"$'\t'"4,1024,2048,2048"$'\t'"f32"$'\t'"0"$'\t'"16"$'\t'"0"$'\t'"4x1x1x1"$'\t'"4,16,16,16"$'\t'"i32"$'\t'"26"$'\t'"1"$'\t'"0" \
    > "${EXPECTED_CENSUS}"

diff -u "${EXPECTED_CENSUS}" "${PROFILE_CENSUS}" \
    > "${LOG_DIR}/manifest-profile-diff.log"

jq -e --arg params "${FROZEN_PARAMS}" '
    ([.manifest.nodes[]
      | select(.descriptor.op_name == "ROPE"
               and .descriptor.op_id == 48)] | length) == 12
    and
    ([.manifest.nodes[]
      | select(.descriptor.op_name == "ROPE"
               and .descriptor.op_id == 48)
      | [.descriptor.ne, .descriptor.nb, .sources[0].descriptor.ne,
         .sources[0].descriptor.nb, .sources[1].descriptor.ne,
         .sources[1].descriptor.nb]] | unique | length) == 2
    and
    (all(.manifest.nodes[]
      | select(.descriptor.op_name == "ROPE"
               and .descriptor.op_id == 48);
      .descriptor.op_params_hex == $params
      and (.descriptor.op_params_hex | length) == 128
      and (.sources | length) == 2))
' "${MANIFEST}" > "${LOG_DIR}/manifest-total-census.log"

jq -r '
    .manifest.nodes[]
    | select(.descriptor.op_name == "ROPE" and .descriptor.op_id == 48)
    | [.index, .canonical_id, .descriptor_sha256,
       .semantic_key.layer_index, .semantic_key.path,
       (.descriptor.ne | join("x"))]
    | @tsv
' "${MANIFEST}" > "${LOG_DIR}/manifest-node-identities.tsv"

# Record the host path whose disassembly established the comparison oracle.
grep -Fx 'GGML_CPU_ALL_VARIANTS:BOOL=ON' \
    "${LLAMA_BUILD}/CMakeCache.txt" > "${LOG_DIR}/cpu-path-audit.txt"
grep -Fx 'GGML_NATIVE:BOOL=OFF' "${LLAMA_BUILD}/CMakeCache.txt" \
    >> "${LOG_DIR}/cpu-path-audit.txt"
grep -m1 'ggml_cpu_alderlake_EXPORTS' "${LLAMA_BUILD}/build.ninja" \
    >> "${LOG_DIR}/cpu-path-audit.txt"
grep -m1 -- '-mf16c -mfma .* -mavx -mavx2 -mavxvnni' \
    "${LLAMA_BUILD}/build.ninja" >> "${LOG_DIR}/cpu-path-audit.txt"

SOURCES=(
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
    "${ROOT}/third_party/fpu-sp/verilog/src/float/fp_rnd.sv"
    "${ROOT}/rtl/TensorNpuInt32ToFp32.v"
    "${ROOT}/rtl/TensorNpuFp32SincosCordic.v"
    "${ROOT}/rtl/TensorNpuFp32AddMul.v"
    "${ROOT}/rtl/TensorNpuFp32Fma.v"
    "${ROOT}/rtl/TensorNpuRopeWritebackAdapter.v"
    "${ROOT}/tests/tb_rope_writeback_adapter.sv"
)

VERILATOR_WARNINGS=(
    -Wall -Wno-fatal -Wno-UNOPTFLAT -Wno-IMPORTSTAR
    -Wno-UNUSEDPARAM -Wno-UNUSEDSIGNAL -Wno-GENUNNAMED
    -Wno-DECLFILENAME -Wno-TIMESCALEMOD -Wno-WIDTH -Wno-VARHIDDEN
)

verilator --lint-only --timing "${VERILATOR_WARNINGS[@]}" \
    --no-assert --no-trace \
    --top-module tb_rope_writeback_adapter "${SOURCES[@]}" \
    > "${LOG_DIR}/lint.log" 2>&1

verilator --binary --timing "${VERILATOR_WARNINGS[@]}" \
    --no-assert --no-trace -O3 -CFLAGS "-O3 -DNDEBUG" \
    --Mdir "${OBJ_DIR}" --top-module tb_rope_writeback_adapter \
    "${SOURCES[@]}" > "${LOG_DIR}/build.log" 2>&1

if grep -F '%Warning' "${LOG_DIR}/lint.log" "${LOG_DIR}/build.log" \
        > "${LOG_DIR}/project-warning-audit.log"; then
    printf 'Verilator warning found; see %s\n' \
        "${LOG_DIR}/project-warning-audit.log" >&2
    exit 1
fi

if rg -n 'shortreal|\breal\b|DPI|\$sin|\$cos|\$tan|\$exp' \
        "${ROOT}/rtl/TensorNpuRopeWritebackAdapter.v" \
        > "${LOG_DIR}/rtl-host-arithmetic-audit.log"; then
    printf 'runtime RTL contains host numerical arithmetic\n' >&2
    exit 1
fi

if rg -n '\bdut\.|\bu_sincos\.|\bu_mul\.|\bu_fma\.|\bforce\b|\brelease\b|\$dump|trace' \
        "${ROOT}/tests/tb_rope_writeback_adapter.sv" \
        > "${LOG_DIR}/hierarchy-trace-audit.log"; then
    printf 'testbench hierarchy bypass or trace construct found\n' >&2
    exit 1
fi

[[ "$(rg -c 'TensorNpuInt32ToFp32 u_position_convert' \
        "${ROOT}/rtl/TensorNpuRopeWritebackAdapter.v")" == 1 ]]
[[ "$(rg -c 'TensorNpuFp32SincosCordic u_sincos' \
        "${ROOT}/rtl/TensorNpuRopeWritebackAdapter.v")" == 1 ]]
[[ "$(rg -c 'TensorNpuFp32AddMul u_mul' \
        "${ROOT}/rtl/TensorNpuRopeWritebackAdapter.v")" == 1 ]]
[[ "$(rg -c 'TensorNpuFp32Fma u_fma' \
        "${ROOT}/rtl/TensorNpuRopeWritebackAdapter.v")" == 1 ]]
: > "${LOG_DIR}/numeric-structure-audit.log"

sha256sum \
    "${MANIFEST}" \
    "${LLAMA_BUILD}/bin/libggml-cpu-alderlake.so" \
    "${ROOT}/rtl/TensorNpuInt32ToFp32.v" \
    "${ROOT}/rtl/TensorNpuFp32SincosCordic.v" \
    "${ROOT}/tests/tb_fp32_sincos_cordic.cpp" \
    "${ROOT}/scripts/run_fp32_sincos_cordic.sh" \
    "${ROOT}/rtl/TensorNpuFp32AddMul.v" \
    "${ROOT}/rtl/TensorNpuFp32Fma.v" \
    "${ROOT}/rtl/TensorNpuRopeWritebackAdapter.v" \
    "${ROOT}/tests/tb_rope_writeback_adapter.sv" \
    "${ROOT}/scripts/run_rope_writeback_adapter.sh" \
    > "${LOG_DIR}/source-sha256.txt"

set -o pipefail
"${OBJ_DIR}/Vtb_rope_writeback_adapter" | tee "${LOG_DIR}/run.log"
grep -Fq '[NPU-ROPE-WRITEBACK][PASS]' "${LOG_DIR}/run.log"
grep -Fq 'bit_exact_claim=0' "${LOG_DIR}/run.log"
grep -Fq 'abs_threshold=5e-4' "${LOG_DIR}/run.log"

if find "${BUILD_DIR}" "${LOG_DIR}" "${COMPILER_TMP}" -type f \
        \( -name '*.vcd' -o -name '*.fst' -o -name '*.lxt' \
           -o -name '*.lxt2' -o -name '*.vpd' \) -print -quit \
        | grep -q .; then
    printf 'waveform artifact found in fresh run\n' >&2
    exit 1
fi

printf 'build_dir=%s\nlog_dir=%s\ncompiler_tmp=%s\nprofile_census=%s\n' \
    "${BUILD_DIR}" "${LOG_DIR}" "${COMPILER_TMP}" "${PROFILE_CENSUS}"
