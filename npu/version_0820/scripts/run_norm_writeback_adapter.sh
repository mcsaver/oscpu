#!/usr/bin/env bash
set -euo pipefail

ROOT=/home/lyg/PA/ysyx-workbench/npu/version_0820
MANIFEST="${ROOT}/tmp/logs/qwen-graph-manifest-v5/dispatch.manifest.json"
RUN_ID="norm-writeback-$(date -u +%Y%m%dT%H%M%S)-$$"
BUILD_DIR="${ROOT}/tmp/build/${RUN_ID}"
LOG_DIR="${ROOT}/tmp/logs/${RUN_ID}"
OBJ_DIR="${BUILD_DIR}/obj_dir"
COMPILER_TMP="${ROOT}/tmp/compiler/${RUN_ID}"
PROFILE_CENSUS="${LOG_DIR}/manifest-profile-census.tsv"
EXPECTED_CENSUS="${LOG_DIR}/expected-profile-census.tsv"

# This project-owned compiler directory is created and exported before the
# first jq, Verilator, compiler, or build invocation.  No phase may fall back
# to the host/system temporary directory.
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

# Derive the complete destination/source profile key from the frozen v5
# manifest.  Source view offsets are reported, but are intentionally not part
# of the hardware profile key because runtime passes a post-view data pointer.
jq -r '
    [.manifest.nodes[]
     | select(.descriptor.op_name == "RMS_NORM"
              or .descriptor.op_name == "L2_NORM")
     | {
         op: .descriptor.op_name,
         op_id: .descriptor.op_id,
         ne: (.descriptor.ne | join("x")),
         dst_nb: (.descriptor.nb | join(",")),
         src_ne: (.sources[0].descriptor.ne | join("x")),
         src_nb: (.sources[0].descriptor.nb | join(",")),
         eps_le: .descriptor.op_params_hex[0:8],
         tail_zero: (.descriptor.op_params_hex[8:] | test("^0+$")),
         dtype: .descriptor.type_name,
         type_id: .descriptor.type_id,
         flags: .descriptor.flags,
         view_offs: .descriptor.view_offs,
         source_count: (.sources | length),
         src_dtype: .sources[0].descriptor.type_name,
         src_type_id: .sources[0].descriptor.type_id,
         src_flags: .sources[0].descriptor.flags,
         src_view: .sources[0].descriptor.view_offs
       }]
    | group_by([.op, .op_id, .ne, .dst_nb, .src_ne, .src_nb,
                .eps_le, .tail_zero, .dtype, .type_id, .flags,
                .view_offs, .source_count, .src_dtype, .src_type_id,
                .src_flags])[]
    | [length, .[0].op, .[0].op_id, .[0].ne, .[0].dst_nb,
       .[0].src_ne, .[0].src_nb, .[0].eps_le, .[0].tail_zero,
       .[0].dtype, .[0].type_id, .[0].flags, .[0].view_offs,
       .[0].source_count, .[0].src_dtype, .[0].src_type_id,
       .[0].src_flags,
       ([.[].src_view] | unique | map(tostring) | join(","))]
    | @tsv
' "${MANIFEST}" | sort -t $'\t' -k2,2 -k4,4 \
    > "${PROFILE_CENSUS}"

printf '%s\n' \
    $'36\tL2_NORM\t28\t128x16x1x1\t4,512,8192,8192\t128x16x1x1\t4,512,24576,24576\tbd378635\ttrue\tf32\t0\t16\t0\t1\tf32\t0\t16\t0,8192' \
    $'49\tRMS_NORM\t25\t1024x1x1x1\t4,4096,4096,4096\t1024x1x1x1\t4,4096,4096,4096\tbd378635\ttrue\tf32\t0\t16\t0\t1\tf32\t0\t16\t0' \
    $'18\tRMS_NORM\t25\t128x16x1x1\t4,512,8192,8192\t128x16x1x1\t4,512,4,8192\tbd378635\ttrue\tf32\t0\t16\t0\t1\tf32\t0\t16\t0' \
    $'6\tRMS_NORM\t25\t256x2x1x1\t4,1024,2048,2048\t256x2x1x1\t4,1024,2048,2048\tbd378635\ttrue\tf32\t0\t16\t0\t1\tf32\t0\t16\t0' \
    $'6\tRMS_NORM\t25\t256x8x1x1\t4,1024,8192,8192\t256x8x1x1\t4,2048,16384,16384\tbd378635\ttrue\tf32\t0\t16\t0\t1\tf32\t0\t16\t0' \
    > "${EXPECTED_CENSUS}"

diff -u "${EXPECTED_CENSUS}" "${PROFILE_CENSUS}" \
    > "${LOG_DIR}/manifest-profile-diff.log"

jq -e '
    ([.manifest.nodes[] | select(.descriptor.op_name == "RMS_NORM")]
        | length) == 79
    and
    ([.manifest.nodes[] | select(.descriptor.op_name == "L2_NORM")]
        | length) == 36
' "${MANIFEST}" > "${LOG_DIR}/manifest-total-census.log"

SOURCES=(
    "${ROOT}/third_party/fpu-sp/verilog/src/float/fp_wire.sv"
    "${ROOT}/third_party/fpu-sp/verilog/src/lzc/lzc_wire.sv"
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
    "${ROOT}/third_party/hardfloat/source/HardFloat_primitives.v"
    "${ROOT}/third_party/hardfloat/source/isSigNaNRecFN.v"
    "${ROOT}/third_party/hardfloat/source/HardFloat_rawFN.v"
    "${ROOT}/third_party/hardfloat/source/fNToRecFN.v"
    "${ROOT}/third_party/hardfloat/source/recFNToFN.v"
    "${ROOT}/third_party/hardfloat/source/recFNToRecFN.v"
    "${ROOT}/third_party/hardfloat/source/addRecFN.v"
    "${ROOT}/rtl/TensorNpuFp32AddMul.v"
    "${ROOT}/rtl/TensorNpuFp32Div.v"
    "${ROOT}/rtl/TensorNpuFp32Sqrt.v"
    "${ROOT}/rtl/TensorNpuFp32ToFp64.v"
    "${ROOT}/rtl/TensorNpuFp64Add.v"
    "${ROOT}/rtl/TensorNpuFp64ToFp32.v"
    "${ROOT}/rtl/TensorNpuFp32SquareSum64.v"
    "${ROOT}/rtl/TensorNpuFp64Pow2Scale.v"
    "${ROOT}/rtl/TensorNpuNormEngine.v"
    "${ROOT}/rtl/TensorNpuNormWritebackAdapter.v"
    "${ROOT}/tests/tb_norm_writeback_adapter.sv"
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
    --top-module tb_norm_writeback_adapter \
    "${SOURCES[@]}" \
    > "${LOG_DIR}/build.log" 2>&1

if grep -F '%Warning' "${LOG_DIR}/build.log" \
        > "${LOG_DIR}/project-warning-audit.log"; then
    printf 'Verilator warning found; see %s\n' \
        "${LOG_DIR}/project-warning-audit.log" >&2
    exit 1
fi

if rg -n '\bdut\.|\bu_engine\.|\bforce\b|\brelease\b|shortreal|\breal\b|DPI|\$dump|trace' \
        "${ROOT}/tests/tb_norm_writeback_adapter.sv" \
        > "${LOG_DIR}/hierarchy-host-audit.log"; then
    printf 'forbidden hierarchy/host arithmetic/trace construct found; see %s\n' \
        "${LOG_DIR}/hierarchy-host-audit.log" >&2
    exit 1
fi

if [[ "$(rg -c 'TensorNpuNormEngine #' \
        "${ROOT}/rtl/TensorNpuNormWritebackAdapter.v")" != 1 ]]; then
    printf 'adapter must instantiate exactly one public NormEngine\n' >&2
    exit 1
fi

if rg -n 'TensorNpu(Fp32|Fp64)' \
        "${ROOT}/rtl/TensorNpuNormWritebackAdapter.v" \
        > "${LOG_DIR}/numeric-bypass-audit.log"; then
    printf 'adapter instantiated a numeric bypass outside NormEngine\n' >&2
    exit 1
fi

sha256sum \
    "${ROOT}/rtl/TensorNpuNormEngine.v" \
    "${ROOT}/rtl/TensorNpuNormWritebackAdapter.v" \
    "${ROOT}/tests/tb_norm_writeback_adapter.sv" \
    "${ROOT}/scripts/run_norm_writeback_adapter.sh" \
    > "${LOG_DIR}/source-sha256.txt"

set -o pipefail
"${OBJ_DIR}/Vtb_norm_writeback_adapter" | tee "${LOG_DIR}/run.log"
grep -Fq '[NPU-NORM-WRITEBACK][PASS]' "${LOG_DIR}/run.log"

if find "${BUILD_DIR}" "${LOG_DIR}" "${COMPILER_TMP}" -type f \
        \( -name '*.vcd' -o -name '*.fst' -o -name '*.lxt' \
           -o -name '*.lxt2' -o -name '*.vpd' \) -print -quit \
        | grep -q .; then
    printf 'waveform artifact found in fresh run\n' >&2
    exit 1
fi

printf 'build_dir=%s\nlog_dir=%s\ncompiler_tmp=%s\nprofile_census=%s\n' \
    "${BUILD_DIR}" "${LOG_DIR}" "${COMPILER_TMP}" "${PROFILE_CENSUS}"
