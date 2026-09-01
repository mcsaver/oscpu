#!/usr/bin/env bash
set -euo pipefail

ROOT=/home/lyg/PA/ysyx-workbench/npu/version_0820
MANIFEST="${ROOT}/tmp/logs/qwen-graph-manifest-v5/dispatch.manifest.json"
RUN_STAMP=${EPOCHREALTIME//./}
RUN_ID="ssm-conv-writeback-${RUN_STAMP}-$$"
BUILD_DIR="${ROOT}/tmp/build/${RUN_ID}"
LOG_DIR="${ROOT}/tmp/logs/${RUN_ID}"
OBJ_DIR="${BUILD_DIR}/obj_dir"
COMPILER_TMP="${ROOT}/tmp/compiler/${RUN_ID}"
PROFILE_CENSUS="${LOG_DIR}/manifest-profile-census.tsv"
EXPECTED_CENSUS="${LOG_DIR}/expected-profile-census.tsv"

# This is intentionally the first external command.  jq, Verilator, the C++
# compiler, and the executable all inherit one unique project-owned temp root.
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

# Derive every frozen field used by admission.  op_params is a 64-byte record;
# hardware carries its low 128 bits plus an explicit tail-zero witness.
jq -r '
    [.manifest.nodes[]
     | select(.descriptor.op_name == "SSM_CONV")
     | {
         op: .descriptor.op_name,
         op_id: .descriptor.op_id,
         dst_ne: (.descriptor.ne | join("x")),
         dst_nb: (.descriptor.nb | join(",")),
         dst_dtype: .descriptor.type_name,
         dst_type_id: .descriptor.type_id,
         dst_flags: .descriptor.flags,
         dst_view: .descriptor.view_offs,
         op_params_chars: (.descriptor.op_params_hex | length),
         op_params_zero: (.descriptor.op_params_hex | test("^0+$")),
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
    | group_by([.op, .op_id, .dst_ne, .dst_nb, .dst_dtype,
                .dst_type_id, .dst_flags, .dst_view, .op_params_chars,
                .op_params_zero, .arity, .src0_ne, .src0_nb, .src0_dtype,
                .src0_type_id, .src0_flags, .src0_view, .src1_ne, .src1_nb,
                .src1_dtype, .src1_type_id, .src1_flags, .src1_view])[]
    | [length, .[0].op, .[0].op_id, .[0].dst_ne, .[0].dst_nb,
       .[0].dst_dtype, .[0].dst_type_id, .[0].dst_flags, .[0].dst_view,
       .[0].op_params_chars, .[0].op_params_zero, .[0].arity,
       .[0].src0_ne, .[0].src0_nb, .[0].src0_dtype, .[0].src0_type_id,
       .[0].src0_flags, .[0].src0_view,
       .[0].src1_ne, .[0].src1_nb, .[0].src1_dtype, .[0].src1_type_id,
       .[0].src1_flags, .[0].src1_view]
    | @tsv
' "${MANIFEST}" > "${PROFILE_CENSUS}"

printf '%s\n' \
    $'18\tSSM_CONV\t76\t6144x1x1x1\t4,24576,24576,24576\tf32\t0\t16\t0\t128\ttrue\t2\t4x6144x1x1\t4,16,98304,98304\tf32\t0\t16\t0\t4x6144x1x1\t4,16,98304,98304\tf32\t0\t0\t0' \
    > "${EXPECTED_CENSUS}"

diff -u "${EXPECTED_CENSUS}" "${PROFILE_CENSUS}" \
    > "${LOG_DIR}/manifest-profile-diff.log"

jq -e '
    ([.manifest.nodes[] | select(.descriptor.op_name == "SSM_CONV")]
        | length) == 18
    and
    ([.manifest.nodes[] | select(.descriptor.op_name == "SSM_CONV")
      | [.descriptor.op_name, .descriptor.op_id, .descriptor.ne,
         .descriptor.nb, .descriptor.type_id, .descriptor.flags,
         .descriptor.view_offs, .descriptor.op_params_hex,
         (.sources | length), .sources[0].descriptor.ne,
         .sources[0].descriptor.nb, .sources[0].descriptor.type_id,
         .sources[0].descriptor.flags, .sources[0].descriptor.view_offs,
         .sources[1].descriptor.ne, .sources[1].descriptor.nb,
         .sources[1].descriptor.type_id, .sources[1].descriptor.flags,
         .sources[1].descriptor.view_offs]] | unique | length) == 1
' "${MANIFEST}" > "${LOG_DIR}/manifest-total-census.log"

jq -r '
    .manifest.nodes[] | select(.descriptor.op_name == "SSM_CONV")
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
    "${ROOT}/third_party/fpu-sp/verilog/src/float/fp_rnd.sv"
    "${ROOT}/rtl/TensorNpuFp32AddMul.v"
    "${ROOT}/rtl/TensorNpuSsmConvWritebackAdapter.v"
    "${ROOT}/tests/tb_ssm_conv_writeback_adapter.sv"
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
    --top-module tb_ssm_conv_writeback_adapter \
    "${SOURCES[@]}" \
    > "${LOG_DIR}/build.log" 2>&1

if grep -E '%Warning.*(TensorNpuSsmConvWritebackAdapter|tb_ssm_conv_writeback_adapter)' \
        "${LOG_DIR}/build.log" > "${LOG_DIR}/project-warning-audit.log"; then
    printf 'project-owned Verilator warning found; see %s\n' \
        "${LOG_DIR}/project-warning-audit.log" >&2
    exit 1
fi

if rg -n '\bdut\.|\bu_numeric\.|\bforce\b|\brelease\b|shortreal|\breal\b|DPI|\$dump|trace' \
        "${ROOT}/tests/tb_ssm_conv_writeback_adapter.sv" \
        > "${LOG_DIR}/hierarchy-host-audit.log"; then
    printf 'forbidden hierarchy/host arithmetic/trace construct found; see %s\n' \
        "${LOG_DIR}/hierarchy-host-audit.log" >&2
    exit 1
fi

if [[ "$(rg -c 'TensorNpuFp32AddMul u_numeric' \
        "${ROOT}/rtl/TensorNpuSsmConvWritebackAdapter.v")" != 1 ]]; then
    printf 'adapter must instantiate exactly one public FP32 AddMul core\n' >&2
    exit 1
fi

if rg -n 'TensorNpu(Fp32|Fp64|Aor|.*Engine)' \
        "${ROOT}/rtl/TensorNpuSsmConvWritebackAdapter.v" \
        | grep -v 'TensorNpuFp32AddMul' \
        > "${LOG_DIR}/numeric-bypass-audit.log"; then
    printf 'adapter instantiated a numerical bypass outside public AddMul\n' >&2
    exit 1
fi

sha256sum \
    "${MANIFEST}" \
    "${ROOT}/rtl/TensorNpuFp32AddMul.v" \
    "${ROOT}/rtl/TensorNpuSsmConvWritebackAdapter.v" \
    "${ROOT}/tests/tb_ssm_conv_writeback_adapter.sv" \
    "${ROOT}/scripts/run_ssm_conv_writeback_adapter.sh" \
    > "${LOG_DIR}/source-sha256.txt"

set -o pipefail
"${OBJ_DIR}/Vtb_ssm_conv_writeback_adapter" \
    | tee "${LOG_DIR}/run.log"
grep -Fq '[NPU-SSM-CONV-WRITEBACK][PASS]' "${LOG_DIR}/run.log"

if find "${BUILD_DIR}" "${LOG_DIR}" "${COMPILER_TMP}" -type f \
        \( -name '*.vcd' -o -name '*.fst' -o -name '*.lxt' \
           -o -name '*.lxt2' -o -name '*.vpd' \) -print -quit \
        | grep -q .; then
    printf 'waveform artifact found in fresh run\n' >&2
    exit 1
fi

printf 'build_dir=%s\nlog_dir=%s\ncompiler_tmp=%s\nprofile_census=%s\n' \
    "${BUILD_DIR}" "${LOG_DIR}" "${COMPILER_TMP}" "${PROFILE_CENSUS}"
