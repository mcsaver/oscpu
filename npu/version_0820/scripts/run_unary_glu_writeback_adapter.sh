#!/usr/bin/env bash
set -euo pipefail

ROOT=/home/lyg/PA/ysyx-workbench/npu/version_0820
MANIFEST="${ROOT}/tmp/logs/qwen-graph-manifest-v5/dispatch.manifest.json"
RUN_ID="unary-glu-writeback-$(date -u +%Y%m%dT%H%M%S)-$$"
BUILD_DIR="${ROOT}/tmp/build/${RUN_ID}"
LOG_DIR="${ROOT}/tmp/logs/${RUN_ID}"
OBJ_DIR="${BUILD_DIR}/obj_dir"
COMPILER_TMP_DIR="${ROOT}/tmp/compiler/${RUN_ID}"
PROFILE_CENSUS="${LOG_DIR}/manifest-profile-census.tsv"
EXPECTED_CENSUS="${LOG_DIR}/expected-profile-census.tsv"

mkdir -p "${OBJ_DIR}" "${LOG_DIR}" "${COMPILER_TMP_DIR}"
export TMPDIR="${COMPILER_TMP_DIR}"
export TMP="${COMPILER_TMP_DIR}"
export TEMP="${COMPILER_TMP_DIR}"
unset MAKEFLAGS MFLAGS

if [[ ! -r "${MANIFEST}" ]]; then
    printf 'missing frozen v5 manifest: %s\n' "${MANIFEST}" >&2
    exit 1
fi

# Derive the closed profile census directly from the frozen manifest.  The
# final two columns prove both source arity and exact F32 ne/nb/flags/view
# equality against the destination descriptor; they are not hand-entered RTL
# assumptions.
jq -r '
    [.manifest.nodes[]
     | select(.descriptor.op_name == "UNARY"
              or .descriptor.op_name == "GLU")
     | . as $node
     | {
         op: .descriptor.op_name,
         subtype: .descriptor.op_desc,
         op_id: .descriptor.op_id,
         ne: (.descriptor.ne | join("x")),
         nb: (.descriptor.nb | join(",")),
         param0: .descriptor.op_params_hex[0:2],
         tail_zero: (.descriptor.op_params_hex[2:] | test("^0+$")),
         dtype: .descriptor.type_name,
         type_id: .descriptor.type_id,
         flags: .descriptor.flags,
         view_offs: .descriptor.view_offs,
         source_count: (.sources | length),
         sources_exact:
             ([.sources[].descriptor
               | (.type_name == "f32"
                  and .type_id == 0
                  and .flags == 16
                  and .view_offs == 0
                  and .ne == $node.descriptor.ne
                  and .nb == $node.descriptor.nb)] | all)
       }]
    | group_by([.op, .subtype, .op_id, .ne, .nb, .param0,
                .tail_zero, .dtype, .type_id, .flags, .view_offs,
                .source_count, .sources_exact])[]
    | [length, .[0].op, .[0].subtype, .[0].op_id, .[0].ne,
       .[0].nb, .[0].param0, .[0].tail_zero, .[0].dtype,
       .[0].type_id, .[0].flags, .[0].view_offs,
       .[0].source_count, .[0].sources_exact]
    | @tsv
' "${MANIFEST}" | sort -t $'\t' -k2,2 -k3,3 -k5,5 \
    > "${PROFILE_CENSUS}"

printf '%s\n' \
    $'24\tGLU\tSWIGLU\t100\t3584x1x1x1\t4,14336,14336,14336\t02\ttrue\tf32\t0\t16\t0\t2\ttrue' \
    $'18\tUNARY\tEXP\t91\t1x1x16x1\t4,4,4,64\t0d\ttrue\tf32\t0\t16\t0\t1\ttrue' \
    $'18\tUNARY\tSIGMOID\t91\t1x16x1x1\t4,4,64,64\t07\ttrue\tf32\t0\t16\t0\t1\ttrue' \
    $'6\tUNARY\tSIGMOID\t91\t2048x1x1x1\t4,8192,8192,8192\t07\ttrue\tf32\t0\t16\t0\t1\ttrue' \
    $'18\tUNARY\tSILU\t91\t128x16x1x1\t4,512,8192,8192\t0a\ttrue\tf32\t0\t16\t0\t1\ttrue' \
    $'18\tUNARY\tSILU\t91\t6144x1x1x1\t4,24576,24576,24576\t0a\ttrue\tf32\t0\t16\t0\t1\ttrue' \
    $'18\tUNARY\tSOFTPLUS\t91\t16x1x1x1\t4,64,64,64\t0f\ttrue\tf32\t0\t16\t0\t1\ttrue' \
    > "${EXPECTED_CENSUS}"

diff -u "${EXPECTED_CENSUS}" "${PROFILE_CENSUS}" \
    > "${LOG_DIR}/manifest-profile-diff.log"

jq -e '
    ([.manifest.nodes[] | select(.descriptor.op_name == "UNARY")]
        | length) == 96
    and
    ([.manifest.nodes[] | select(.descriptor.op_name == "GLU")]
        | length) == 24
' "${MANIFEST}" > "${LOG_DIR}/manifest-total-census.log"

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
    "${ROOT}/rtl/TensorNpuAorLog32.v"
    "${ROOT}/rtl/TensorNpuFp32AddMul.v"
    "${ROOT}/rtl/TensorNpuFp32Div.v"
    "${ROOT}/rtl/TensorNpuUnaryGluElement.v"
    "${ROOT}/rtl/TensorNpuUnaryGluWritebackAdapter.v"
    "${ROOT}/tests/tb_unary_glu_writeback_adapter.sv"
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
    -I"${ROOT}/third_party/hardfloat/source/RISCV" \
    -I"${ROOT}/third_party/hardfloat/source" \
    --Mdir "${OBJ_DIR}" \
    --top-module tb_unary_glu_writeback_adapter \
    "${SOURCES[@]}" \
    > "${LOG_DIR}/build.log" 2>&1

if grep -E '%Warning.*(TensorNpuUnaryGluElement|TensorNpuUnaryGluWritebackAdapter|tb_unary_glu_writeback_adapter)' \
        "${LOG_DIR}/build.log" > "${LOG_DIR}/project-warning-audit.log"; then
    printf 'project-owned Verilator warning found; see %s\n' \
        "${LOG_DIR}/project-warning-audit.log" >&2
    exit 1
fi

if rg -n '\bdut\.|\bu_element\.|\bforce\b|\brelease\b|shortreal|\breal\b|DPI|\$dump|trace' \
        "${ROOT}/tests/tb_unary_glu_writeback_adapter.sv" \
        > "${LOG_DIR}/hierarchy-host-audit.log"; then
    printf 'forbidden hierarchy/host arithmetic/trace construct found; see %s\n' \
        "${LOG_DIR}/hierarchy-host-audit.log" >&2
    exit 1
fi

if [[ "$(rg -c 'TensorNpuUnaryGluElement u_element' \
        "${ROOT}/rtl/TensorNpuUnaryGluWritebackAdapter.v")" != 1 ]]; then
    printf 'adapter must instantiate exactly one public unary/GLU element\n' >&2
    exit 1
fi

if rg -n 'TensorNpu(Aor|Fp32|Fp64)' \
        "${ROOT}/rtl/TensorNpuUnaryGluWritebackAdapter.v" \
        > "${LOG_DIR}/numeric-bypass-audit.log"; then
    printf 'adapter instantiated a numeric bypass outside the public element\n' >&2
    exit 1
fi

set -o pipefail
"${OBJ_DIR}/Vtb_unary_glu_writeback_adapter" \
    | tee "${LOG_DIR}/run.log"

grep -Fq '[NPU-UNARY-GLU-WRITEBACK][PASS]' "${LOG_DIR}/run.log"

printf 'build_dir=%s\nlog_dir=%s\ncompiler_tmp_dir=%s\nprofile_census=%s\n' \
    "${BUILD_DIR}" "${LOG_DIR}" "${COMPILER_TMP_DIR}" "${PROFILE_CENSUS}"
