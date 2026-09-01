#!/usr/bin/env bash
set -euo pipefail

ROOT=/home/lyg/PA/ysyx-workbench/npu/version_0820
MANIFEST="${ROOT}/tmp/logs/qwen-graph-manifest-v5/dispatch.manifest.json"
LLAMA_BUILD="${ROOT}/tmp/build/llama.cpp"
RUN_STAMP=${EPOCHREALTIME//./}
RUN_ID="f16-attention-matmul-${RUN_STAMP}-$$"
BUILD_DIR="${ROOT}/tmp/build/${RUN_ID}"
LOG_DIR="${ROOT}/tmp/logs/${RUN_ID}"
OBJ_DIR="${BUILD_DIR}/obj_dir"
COMPILER_TMP="${ROOT}/tmp/compiler/${RUN_ID}"
PROFILE_CENSUS="${LOG_DIR}/manifest-profile-census.tsv"
EXPECTED_CENSUS="${LOG_DIR}/expected-profile-census.tsv"

# This is deliberately the first external command.  Every later manifest,
# compiler, build, and executable process inherits this project-owned root.
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

# Derive both exact profiles, including the complete 64-byte op-params shape
# represented as low32, tail-zero, and total hexadecimal character count.
jq -r '
    [.manifest.nodes[]
     | select(.descriptor.op_name == "MUL_MAT"
              and .descriptor.op_id == 29
              and .sources[0].descriptor.type_name == "f16")
     | {
         profile: (if (.descriptor.op_params_hex | startswith("0a000000"))
                   then 0 else 1 end),
         op: .descriptor.op_name,
         op_id: .descriptor.op_id,
         dst_ne: (.descriptor.ne | join("x")),
         dst_nb: (.descriptor.nb | join(",")),
         dst_dtype: .descriptor.type_name,
         dst_type_id: .descriptor.type_id,
         dst_flags: .descriptor.flags,
         dst_view: .descriptor.view_offs,
         op_params_chars: (.descriptor.op_params_hex | length),
         op_params_low32: .descriptor.op_params_hex[0:8],
         op_params_tail_zero:
             (.descriptor.op_params_hex[8:] | test("^0+$")),
         arity: (.sources | length),
         src0_ne: (.sources[0].descriptor.ne | join("x")),
         src0_nb: (.sources[0].descriptor.nb | join(",")),
         src0_dtype: .sources[0].descriptor.type_name,
         src0_type_id: .sources[0].descriptor.type_id,
         src0_flags: .sources[0].descriptor.flags,
         src0_view: .sources[0].descriptor.view_offs,
         src1_ne: (.sources[1].descriptor.ne | join("x")),
         src1_nb: (.sources[1].descriptor.nb | join(",")),
         src1_dtype: .sources[1].descriptor.type_name,
         src1_type_id: .sources[1].descriptor.type_id,
         src1_flags: .sources[1].descriptor.flags,
         src1_view: .sources[1].descriptor.view_offs
       }]
    | group_by([.profile, .op, .op_id, .dst_ne, .dst_nb, .dst_dtype,
                .dst_type_id, .dst_flags, .dst_view, .op_params_chars,
                .op_params_low32, .op_params_tail_zero, .arity,
                .src0_ne, .src0_nb, .src0_dtype, .src0_type_id,
                .src0_flags, .src0_view, .src1_ne, .src1_nb,
                .src1_dtype, .src1_type_id, .src1_flags, .src1_view])
    | map({count: length, value: .[0]})
    | sort_by(.value.profile)[]
    | [.count, .value.profile, .value.op, .value.op_id,
       .value.dst_ne, .value.dst_nb, .value.dst_dtype,
       .value.dst_type_id, .value.dst_flags, .value.dst_view,
       .value.op_params_chars, .value.op_params_low32,
       .value.op_params_tail_zero, .value.arity,
       .value.src0_ne, .value.src0_nb, .value.src0_dtype,
       .value.src0_type_id, .value.src0_flags, .value.src0_view,
       .value.src1_ne, .value.src1_nb, .value.src1_dtype,
       .value.src1_type_id, .value.src1_flags, .value.src1_view]
    | @tsv
' "${MANIFEST}" > "${PROFILE_CENSUS}"

printf '%s\n' \
    $'6\t0\tMUL_MAT\t29\t256x1x8x1\t4,1024,1024,8192\tf32\t0\t16\t0\t128\t0a000000\ttrue\t2\t256x256x2x1\t2,1024,512,262144\tf16\t1\t16\t0\t256x1x8x1\t4,8192,1024,8192\tf32\t0\t16\t0' \
    $'6\t1\tMUL_MAT\t29\t256x1x8x1\t4,1024,1024,8192\tf32\t0\t16\t0\t128\t00000000\ttrue\t2\t256x256x2x1\t2,512,131072,262144\tf16\t1\t16\t0\t256x1x8x1\t4,1024,1024,8192\tf32\t0\t16\t0' \
    > "${EXPECTED_CENSUS}"

diff -u "${EXPECTED_CENSUS}" "${PROFILE_CENSUS}" \
    > "${LOG_DIR}/manifest-profile-diff.log"

jq -e '
    ([.manifest.nodes[]
      | select(.descriptor.op_name == "MUL_MAT"
               and .descriptor.op_id == 29
               and .sources[0].descriptor.type_name == "f16")]
        | length) == 12
    and
    ([.manifest.nodes[]
      | select(.descriptor.op_name == "MUL_MAT"
               and .descriptor.op_id == 29
               and .sources[0].descriptor.type_name == "f16")
      | [.descriptor.op_name, .descriptor.op_id, .descriptor.ne,
         .descriptor.nb, .descriptor.type_id, .descriptor.flags,
         .descriptor.view_offs, .descriptor.op_params_hex,
         (.sources | length), .sources[0].descriptor.ne,
         .sources[0].descriptor.nb, .sources[0].descriptor.type_id,
         .sources[0].descriptor.flags, .sources[0].descriptor.view_offs,
         .sources[1].descriptor.ne, .sources[1].descriptor.nb,
         .sources[1].descriptor.type_id, .sources[1].descriptor.flags,
         .sources[1].descriptor.view_offs]] | unique | length) == 2
    and
    ([.manifest.nodes[]
      | select(.descriptor.op_name == "MUL_MAT"
               and .descriptor.op_id == 29
               and .sources[0].descriptor.type_name == "f16")
      | .descriptor.op_params_hex]
      | group_by(.) | map(length) | sort) == [6, 6]
' "${MANIFEST}" > "${LOG_DIR}/manifest-total-census.log"

jq -r '
    .manifest.nodes[]
    | select(.descriptor.op_name == "MUL_MAT"
             and .descriptor.op_id == 29
             and .sources[0].descriptor.type_name == "f16")
    | [.index, .canonical_id, .descriptor_sha256,
       .semantic_key.layer_index, .semantic_key.path,
       .descriptor.op_params_hex[0:8]]
    | @tsv
' "${MANIFEST}" > "${LOG_DIR}/manifest-node-identities.tsv"

# Freeze the actual CPU oracle identity used during manifest collection.
grep -Fx 'GGML_CPU_ALL_VARIANTS:BOOL=ON' \
    "${LLAMA_BUILD}/CMakeCache.txt" > "${LOG_DIR}/cpu-path-audit.txt"
grep -Fx 'GGML_NATIVE:BOOL=OFF' "${LLAMA_BUILD}/CMakeCache.txt" \
    >> "${LOG_DIR}/cpu-path-audit.txt"
grep -Fx 'GGML_LLAMAFILE:BOOL=OFF' "${LLAMA_BUILD}/CMakeCache.txt" \
    >> "${LOG_DIR}/cpu-path-audit.txt"
grep -m1 'ggml_cpu_alderlake_EXPORTS' "${LLAMA_BUILD}/build.ninja" \
    >> "${LOG_DIR}/cpu-path-audit.txt"
grep -m1 -- '-mf16c -mfma .* -mavx -mavx2 -mavxvnni' \
    "${LLAMA_BUILD}/build.ninja" >> "${LOG_DIR}/cpu-path-audit.txt"
"${LLAMA_BUILD}/bin/llama-bench" -h \
    > "${LOG_DIR}/cpu-backend-help.log" 2>&1
grep -Fq 'libggml-cpu-alderlake.so' "${LOG_DIR}/cpu-backend-help.log"

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
    "${ROOT}/rtl/TensorNpuFp16ToFp32.v"
    "${ROOT}/rtl/TensorNpuFp32ToFp16.v"
    "${ROOT}/rtl/TensorNpuFp32AddMul.v"
    "${ROOT}/rtl/TensorNpuFp32Fma.v"
    "${ROOT}/rtl/TensorNpuF16AttentionMatmulWritebackAdapter.v"
    "${ROOT}/tests/tb_f16_attention_matmul_writeback_adapter.sv"
)

verilator \
    --binary \
    --timing \
    -Wall \
    -Wno-fatal \
    -Wno-UNOPTFLAT \
    -Wno-IMPORTSTAR \
    -Wno-UNUSEDPARAM \
    -Wno-UNUSEDSIGNAL \
    -Wno-GENUNNAMED \
    -Wno-DECLFILENAME \
    -Wno-TIMESCALEMOD \
    -Wno-WIDTH \
    -Wno-VARHIDDEN \
    --no-assert \
    --no-trace \
    -O3 \
    -CFLAGS "-O3 -DNDEBUG" \
    --Mdir "${OBJ_DIR}" \
    --top-module tb_f16_attention_matmul_writeback_adapter \
    "${SOURCES[@]}" \
    > "${LOG_DIR}/build.log" 2>&1

if grep -F '%Warning' "${LOG_DIR}/build.log" \
        > "${LOG_DIR}/project-warning-audit.log"; then
    printf 'Verilator warning found; see %s\n' \
        "${LOG_DIR}/project-warning-audit.log" >&2
    exit 1
fi

if rg -n '\bdut\.|\bu_fma\.|\bu_reduction_add\.|\bfma_probe\.|\bforce\b|\brelease\b|shortreal|\breal\b|DPI|\$dump|trace' \
        "${ROOT}/tests/tb_f16_attention_matmul_writeback_adapter.sv" \
        > "${LOG_DIR}/hierarchy-host-audit.log"; then
    printf 'forbidden hierarchy/host numerical/trace construct found; see %s\n' \
        "${LOG_DIR}/hierarchy-host-audit.log" >&2
    exit 1
fi

if [[ "$(rg -c 'TensorNpuFp32Fma u_fma' \
        "${ROOT}/rtl/TensorNpuF16AttentionMatmulWritebackAdapter.v")" != 1 ]] \
        || [[ "$(rg -c 'TensorNpuFp32AddMul u_reduction_add' \
        "${ROOT}/rtl/TensorNpuF16AttentionMatmulWritebackAdapter.v")" != 1 ]]; then
    printf 'adapter numerical core census mismatch\n' >&2
    exit 1
fi

if ! rg -Fq 'fp_fma_i.op.fmadd = 1' "${ROOT}/rtl/TensorNpuFp32Fma.v" \
        || rg -n 'fp_fma_i\.op\.(fmul|fadd)' "${ROOT}/rtl/TensorNpuFp32Fma.v" \
        > "${LOG_DIR}/fma-structure-audit.log"; then
    printf 'public FMA wrapper is not fused-only\n' >&2
    exit 1
fi

if rg -n 'TensorNpu(Fp32Div|Fp32Sqrt|Fp64|Aor)|op_mul_i\(1.b1\)' \
        "${ROOT}/rtl/TensorNpuF16AttentionMatmulWritebackAdapter.v" \
        > "${LOG_DIR}/numeric-bypass-audit.log"; then
    printf 'adapter instantiated a forbidden numerical bypass\n' >&2
    exit 1
fi

sha256sum \
    "${MANIFEST}" \
    "${ROOT}/third_party/SOURCES.lock.json" \
    "${LLAMA_BUILD}/CMakeCache.txt" \
    "${LLAMA_BUILD}/build.ninja" \
    "${LLAMA_BUILD}/bin/libggml-cpu-alderlake.so" \
    "${ROOT}/rtl/TensorNpuFp16ToFp32.v" \
    "${ROOT}/rtl/TensorNpuFp32ToFp16.v" \
    "${ROOT}/rtl/TensorNpuFp32AddMul.v" \
    "${ROOT}/rtl/TensorNpuFp32Fma.v" \
    "${ROOT}/rtl/TensorNpuF16AttentionMatmulWritebackAdapter.v" \
    "${ROOT}/tests/tb_f16_attention_matmul_writeback_adapter.sv" \
    "${ROOT}/scripts/run_f16_attention_matmul_writeback_adapter.sh" \
    > "${LOG_DIR}/source-sha256.txt"

set -o pipefail
"${OBJ_DIR}/Vtb_f16_attention_matmul_writeback_adapter" \
    | tee "${LOG_DIR}/run.log"
grep -Fq '[NPU-F16-ATTENTION][PASS]' "${LOG_DIR}/run.log"

if find "${BUILD_DIR}" "${LOG_DIR}" "${COMPILER_TMP}" -type f \
        \( -name '*.vcd' -o -name '*.fst' -o -name '*.lxt' \
           -o -name '*.lxt2' -o -name '*.vpd' \) -print -quit \
        | grep -q .; then
    printf 'waveform artifact found in fresh run\n' >&2
    exit 1
fi

printf 'build_dir=%s\nlog_dir=%s\ncompiler_tmp=%s\nprofile_census=%s\n' \
    "${BUILD_DIR}" "${LOG_DIR}" "${COMPILER_TMP}" "${PROFILE_CENSUS}"
