#!/usr/bin/env bash
set -euo pipefail

ROOT=/home/lyg/PA/ysyx-workbench/npu/version_0820
MANIFEST="${ROOT}/tmp/logs/qwen-graph-manifest-v5/dispatch.manifest.json"
RUN_STAMP=${EPOCHREALTIME//./}
RUN_ID="softmax-writeback-${RUN_STAMP}-$$"
BUILD_DIR="${ROOT}/tmp/build/${RUN_ID}"
LOG_DIR="${ROOT}/tmp/logs/${RUN_ID}"
LINT_DIR="${BUILD_DIR}/lint_obj"
OBJ_DIR="${BUILD_DIR}/obj_dir"
COMPILER_TMP="${ROOT}/tmp/compiler/${RUN_ID}"
PROFILE_CENSUS="${LOG_DIR}/manifest-profile-census.tsv"
EXPECTED_CENSUS="${LOG_DIR}/expected-profile-census.tsv"

# This is deliberately the first external command.  All manifest tools,
# Verilator processes, compiler processes, and the test executable inherit a
# unique project-owned temporary directory.
mkdir -p "${COMPILER_TMP}" "${LINT_DIR}" "${OBJ_DIR}" "${LOG_DIR}"
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

# Machine-derive every field admitted by the standalone owner.  reduce_op is
# the command-ABI encoding selected by the manifest op name.  The full 64-byte
# op_params record remains in the grouping key so that a low-word match cannot
# hide non-zero max_bias, padding, or future parameters.
jq -r '
    [.manifest.nodes[]
     | select(.descriptor.op_name == "SOFT_MAX")
     | {
         reduce_op: (if .descriptor.op_name == "SOFT_MAX" then 6 else -1 end),
         op: .descriptor.op_name,
         desc: .descriptor.op_desc,
         op_id: .descriptor.op_id,
         dst_ne: (.descriptor.ne | join("x")),
         dst_nb: (.descriptor.nb | join(",")),
         dst_dtype: .descriptor.type_name,
         dst_type_id: .descriptor.type_id,
         dst_flags: .descriptor.flags,
         dst_view: .descriptor.view_offs,
         params: .descriptor.op_params_hex,
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
    | group_by([.reduce_op, .op, .desc, .op_id, .dst_ne, .dst_nb,
                .dst_dtype, .dst_type_id, .dst_flags, .dst_view, .params,
                .arity, .src0_ne, .src0_nb, .src0_dtype, .src0_type_id,
                .src0_flags, .src0_view, .src1_ne, .src1_nb, .src1_dtype,
                .src1_type_id, .src1_flags, .src1_view])[]
    | [length, .[0].reduce_op, .[0].op, .[0].desc, .[0].op_id,
       .[0].dst_ne, .[0].dst_nb, .[0].dst_dtype, .[0].dst_type_id,
       .[0].dst_flags, .[0].dst_view, .[0].params, .[0].arity,
       .[0].src0_ne, .[0].src0_nb, .[0].src0_dtype, .[0].src0_type_id,
       .[0].src0_flags, .[0].src0_view, .[0].src1_ne, .[0].src1_nb,
       .[0].src1_dtype, .[0].src1_type_id, .[0].src1_flags, .[0].src1_view]
    | @tsv
' "${MANIFEST}" > "${PROFILE_CENSUS}"

printf '%s\n' \
    $'6\t6\tSOFT_MAX\tSOFT_MAX\t46\t256x1x8x1\t4,1024,1024,8192\tf32\t0\t16\t0\t0000803d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000\t2\t256x1x8x1\t4,1024,1024,8192\tf32\t0\t16\t0\t256x1x1x1\t4,1024,1024,1024\tf32\t0\t1\t0' \
    > "${EXPECTED_CENSUS}"

diff -u "${EXPECTED_CENSUS}" "${PROFILE_CENSUS}" \
    > "${LOG_DIR}/manifest-profile-diff.log"

jq -e '
    ([.manifest.nodes[] | select(.descriptor.op_name == "SOFT_MAX")]
        | length) == 6
    and
    ([.manifest.nodes[] | select(.descriptor.op_name == "SOFT_MAX")
      | [.descriptor.op_name, .descriptor.op_desc, .descriptor.op_id,
         .descriptor.ne, .descriptor.nb, .descriptor.type_name,
         .descriptor.type_id, .descriptor.flags, .descriptor.view_offs,
         .descriptor.op_params_hex, (.sources | length),
         .sources[0].descriptor.ne, .sources[0].descriptor.nb,
         .sources[0].descriptor.type_name, .sources[0].descriptor.type_id,
         .sources[0].descriptor.flags, .sources[0].descriptor.view_offs,
         .sources[1].descriptor.ne, .sources[1].descriptor.nb,
         .sources[1].descriptor.type_name, .sources[1].descriptor.type_id,
         .sources[1].descriptor.flags, .sources[1].descriptor.view_offs]]
        | unique | length) == 1
    and
    ([.manifest.nodes[] | select(.descriptor.op_name == "SOFT_MAX")
      | select(.descriptor.op_id == 46
               and .descriptor.ne == [256,1,8,1]
               and .descriptor.nb == [4,1024,1024,8192]
               and .descriptor.type_id == 0
               and .descriptor.flags == 16
               and .descriptor.view_offs == 0
               and .descriptor.op_params_hex ==
                   "0000803d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
               and (.sources | length) == 2
               and .sources[0].descriptor.ne == [256,1,8,1]
               and .sources[0].descriptor.nb == [4,1024,1024,8192]
               and .sources[0].descriptor.type_id == 0
               and .sources[0].descriptor.flags == 16
               and .sources[0].descriptor.view_offs == 0
               and .sources[1].descriptor.ne == [256,1,1,1]
               and .sources[1].descriptor.nb == [4,1024,1024,1024]
               and .sources[1].descriptor.type_id == 0
               and .sources[1].descriptor.flags == 1
               and .sources[1].descriptor.view_offs == 0)]
        | length) == 6
' "${MANIFEST}" > "${LOG_DIR}/manifest-total-census.log"

jq -r '
    .manifest.nodes[] | select(.descriptor.op_name == "SOFT_MAX")
    | [.index, .canonical_id, .descriptor_sha256,
       .semantic_key.layer_index, .semantic_key.path]
    | @tsv
' "${MANIFEST}" > "${LOG_DIR}/manifest-node-identities.tsv"

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
    "${ROOT}/third_party/fpu-sp/verilog/src/float/fp_fdiv.sv"
    "${ROOT}/third_party/fpu-sp/verilog/src/float/fp_rnd.sv"
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
    "${ROOT}/rtl/TensorNpuFp32ToFp64.v"
    "${ROOT}/rtl/TensorNpuFp64Fma.v"
    "${ROOT}/rtl/TensorNpuFp64ToInt32Rmm.v"
    "${ROOT}/rtl/TensorNpuInt32ToFp64.v"
    "${ROOT}/rtl/TensorNpuFp64ToFp32Finite.v"
    "${ROOT}/rtl/TensorNpuAorExp32.v"
    "${ROOT}/rtl/TensorNpuFp32AddMul.v"
    "${ROOT}/rtl/TensorNpuFp32Div.v"
    "${ROOT}/rtl/TensorNpuSoftmaxWritebackAdapter.v"
    "${ROOT}/tests/tb_softmax_writeback_adapter.sv"
)

VERILATOR_COMMON=(
    --timing
    -Wall
    -Wno-fatal
    -Wno-UNOPTFLAT
    -Wno-IMPORTSTAR
    -Wno-UNUSEDPARAM
    -Wno-UNUSEDSIGNAL
    -Wno-GENUNNAMED
    -Wno-DECLFILENAME
    -Wno-TIMESCALEMOD
    -Wno-WIDTH
    -Wno-VARHIDDEN
    --no-assert
    --no-trace
    -O3
    -I"${ROOT}/third_party/hardfloat/source/RISCV"
    -I"${ROOT}/third_party/hardfloat/source"
    --top-module tb_softmax_writeback_adapter
)

# Lint is an explicit first gate and uses a different fresh Mdir from the full
# compilation below.
verilator \
    --lint-only \
    "${VERILATOR_COMMON[@]}" \
    --Mdir "${LINT_DIR}" \
    "${SOURCES[@]}" \
    > "${LOG_DIR}/lint.log" 2>&1

if grep -E '%Warning.*(TensorNpuSoftmaxWritebackAdapter|tb_softmax_writeback_adapter)' \
        "${LOG_DIR}/lint.log" > "${LOG_DIR}/lint-project-warning-audit.log"; then
    printf 'project-owned lint warning found; see %s\n' \
        "${LOG_DIR}/lint-project-warning-audit.log" >&2
    exit 1
fi

if [[ "$(rg -c 'TensorNpuFp32AddMul u_addmul' \
        "${ROOT}/rtl/TensorNpuSoftmaxWritebackAdapter.v")" != 1 ]] \
        || [[ "$(rg -c 'TensorNpuAorExp32 #' \
        "${ROOT}/rtl/TensorNpuSoftmaxWritebackAdapter.v")" != 1 ]] \
        || [[ "$(rg -c 'TensorNpuFp32Div u_div' \
        "${ROOT}/rtl/TensorNpuSoftmaxWritebackAdapter.v")" != 1 ]]; then
    printf 'adapter must instantiate exactly one AddMul, AOR exp, and FP32 div owner\n' >&2
    exit 1
fi

if rg -n '\bdut\.|\bforce\b|\brelease\b|shortreal|DPI|\$dump|trace' \
        "${ROOT}/tests/tb_softmax_writeback_adapter.sv" \
        > "${LOG_DIR}/hierarchy-host-trace-audit.log"; then
    printf 'forbidden hierarchy/shortreal/DPI/trace construct found; see %s\n' \
        "${LOG_DIR}/hierarchy-host-trace-audit.log" >&2
    exit 1
fi

verilator \
    --binary \
    "${VERILATOR_COMMON[@]}" \
    -CFLAGS "-O3 -DNDEBUG" \
    -MAKEFLAGS "OPT_FAST=-O3 OPT_SLOW=-O3 OPT_GLOBAL=-O3" \
    --Mdir "${OBJ_DIR}" \
    "${SOURCES[@]}" \
    > "${LOG_DIR}/build.log" 2>&1

if grep -E '%Warning.*(TensorNpuSoftmaxWritebackAdapter|tb_softmax_writeback_adapter)' \
        "${LOG_DIR}/build.log" > "${LOG_DIR}/build-project-warning-audit.log"; then
    printf 'project-owned build warning found; see %s\n' \
        "${LOG_DIR}/build-project-warning-audit.log" >&2
    exit 1
fi

sha256sum \
    "${MANIFEST}" \
    "${ROOT}/rtl/TensorNpuFp32AddMul.v" \
    "${ROOT}/rtl/TensorNpuAorExp32.v" \
    "${ROOT}/rtl/TensorNpuFp32Div.v" \
    "${ROOT}/rtl/TensorNpuSoftmaxWritebackAdapter.v" \
    "${ROOT}/tests/tb_softmax_writeback_adapter.sv" \
    "${ROOT}/scripts/run_softmax_writeback_adapter.sh" \
    > "${LOG_DIR}/source-sha256.txt"

set -o pipefail
"${OBJ_DIR}/Vtb_softmax_writeback_adapter" \
    | tee "${LOG_DIR}/run.log"

grep -Fq '[NPU-SOFTMAX-WRITEBACK][NUMERIC]' "${LOG_DIR}/run.log"
grep -Fq 'oracle=host-double-exp' "${LOG_DIR}/run.log"
grep -Fq 'bit_exact_claim=0' "${LOG_DIR}/run.log"
grep -Fq '[NPU-SOFTMAX-WRITEBACK][PASS]' "${LOG_DIR}/run.log"

if find "${BUILD_DIR}" "${LOG_DIR}" "${COMPILER_TMP}" -type f \
        \( -name '*.vcd' -o -name '*.fst' -o -name '*.lxt' \
           -o -name '*.lxt2' -o -name '*.vpd' \) -print -quit \
        | grep -q .; then
    printf 'waveform artifact found in fresh run\n' >&2
    exit 1
fi

printf 'build_dir=%s\nlog_dir=%s\ncompiler_tmp=%s\nprofile_census=%s\n' \
    "${BUILD_DIR}" "${LOG_DIR}" "${COMPILER_TMP}" "${PROFILE_CENSUS}"
