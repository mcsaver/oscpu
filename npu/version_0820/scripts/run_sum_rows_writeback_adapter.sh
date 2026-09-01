#!/usr/bin/env bash
set -euo pipefail

ROOT=/home/lyg/PA/ysyx-workbench/npu/version_0820
MANIFEST="${ROOT}/tmp/logs/qwen-graph-manifest-v5/dispatch.manifest.json"
RUN_STAMP=${EPOCHREALTIME//./}
RUN_ID="sum-rows-writeback-${RUN_STAMP}-$$"
BUILD_DIR="${ROOT}/tmp/build/${RUN_ID}"
LOG_DIR="${ROOT}/tmp/logs/${RUN_ID}"
OBJ_DIR="${BUILD_DIR}/obj_dir"
COMPILER_TMP="${ROOT}/tmp/compiler/${RUN_ID}"
PROFILE_CENSUS="${LOG_DIR}/manifest-profile-census.tsv"
EXPECTED_CENSUS="${LOG_DIR}/expected-profile-census.tsv"

# mkdir is deliberately the first external command in this runner.  It creates
# the unique project-owned compiler directory before jq, Verilator, a compiler,
# or any build process can observe TMPDIR/TMP/TEMP.
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

# Machine-derive every descriptor field used by hardware admission.  The 64B
# manifest op_params record is represented by an all-zero predicate because
# the hardware interface carries low128 plus an explicit tail-zero witness.
jq -r '
    [.manifest.nodes[]
     | select(.descriptor.op_name == "SUM_ROWS")
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
         src_ne: (.sources[0].descriptor.ne | join("x")),
         src_nb: (.sources[0].descriptor.nb | join(",")),
         src_dtype: .sources[0].descriptor.type_name,
         src_type_id: .sources[0].descriptor.type_id,
         src_flags: .sources[0].descriptor.flags,
         src_view: .sources[0].descriptor.view_offs
       }]
    | group_by([.op, .op_id, .dst_ne, .dst_nb, .dst_dtype,
                .dst_type_id, .dst_flags, .dst_view, .op_params_chars,
                .op_params_zero, .arity, .src_ne, .src_nb, .src_dtype,
                .src_type_id, .src_flags, .src_view])[]
    | [length, .[0].op, .[0].op_id, .[0].dst_ne, .[0].dst_nb,
       .[0].dst_dtype, .[0].dst_type_id, .[0].dst_flags, .[0].dst_view,
       .[0].op_params_chars, .[0].op_params_zero, .[0].arity,
       .[0].src_ne, .[0].src_nb, .[0].src_dtype, .[0].src_type_id,
       .[0].src_flags, .[0].src_view]
    | @tsv
' "${MANIFEST}" > "${PROFILE_CENSUS}"

printf '%s\n' \
    $'36\tSUM_ROWS\t15\t1x128x16x1\t4,4,512,8192\tf32\t0\t16\t0\t128\ttrue\t1\t128x128x16x1\t4,512,65536,1048576\tf32\t0\t16\t0' \
    > "${EXPECTED_CENSUS}"

diff -u "${EXPECTED_CENSUS}" "${PROFILE_CENSUS}" \
    > "${LOG_DIR}/manifest-profile-diff.log"

jq -e '
    ([.manifest.nodes[] | select(.descriptor.op_name == "SUM_ROWS")]
        | length) == 36
    and
    ([.manifest.nodes[] | select(.descriptor.op_name == "SUM_ROWS")
      | [.descriptor.op_name, .descriptor.op_id, .descriptor.ne,
         .descriptor.nb, .descriptor.type_id, .descriptor.flags,
         .descriptor.view_offs, .descriptor.op_params_hex,
         (.sources | length), .sources[0].descriptor.ne,
         .sources[0].descriptor.nb, .sources[0].descriptor.type_id,
         .sources[0].descriptor.flags,
         .sources[0].descriptor.view_offs]] | unique | length) == 1
' "${MANIFEST}" > "${LOG_DIR}/manifest-total-census.log"

jq -r '
    .manifest.nodes[] | select(.descriptor.op_name == "SUM_ROWS")
    | [.index, .canonical_id, .descriptor_sha256,
       .semantic_key.layer_index, .semantic_key.path]
    | @tsv
' "${MANIFEST}" > "${LOG_DIR}/manifest-node-identities.tsv"

SOURCES=(
    "${ROOT}/third_party/hardfloat/source/HardFloat_primitives.v"
    "${ROOT}/third_party/hardfloat/source/HardFloat_rawFN.v"
    "${ROOT}/third_party/hardfloat/source/RISCV/HardFloat_specialize.v"
    "${ROOT}/third_party/hardfloat/source/fNToRecFN.v"
    "${ROOT}/third_party/hardfloat/source/recFNToFN.v"
    "${ROOT}/third_party/hardfloat/source/recFNToRecFN.v"
    "${ROOT}/third_party/hardfloat/source/addRecFN.v"
    "${ROOT}/rtl/TensorNpuFp32ToFp64Ieee.v"
    "${ROOT}/rtl/TensorNpuFp64AddIeee.v"
    "${ROOT}/rtl/TensorNpuFp64ToFp32Ieee.v"
    "${ROOT}/rtl/TensorNpuOrderedSumRows.v"
    "${ROOT}/rtl/TensorNpuSumRowsWritebackAdapter.v"
    "${ROOT}/tests/tb_sum_rows_writeback_adapter.sv"
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
    --top-module tb_sum_rows_writeback_adapter \
    "${SOURCES[@]}" \
    > "${LOG_DIR}/build.log" 2>&1

if grep -F '%Warning' "${LOG_DIR}/build.log" \
        > "${LOG_DIR}/project-warning-audit.log"; then
    printf 'Verilator warning found; see %s\n' \
        "${LOG_DIR}/project-warning-audit.log" >&2
    exit 1
fi

if rg -n '\bdut\.|\bu_ordered_sum_rows\.|\bforce\b|\brelease\b|shortreal|\breal\b|DPI|\$dump|trace' \
        "${ROOT}/tests/tb_sum_rows_writeback_adapter.sv" \
        > "${LOG_DIR}/hierarchy-host-audit.log"; then
    printf 'forbidden hierarchy/host arithmetic/trace construct found; see %s\n' \
        "${LOG_DIR}/hierarchy-host-audit.log" >&2
    exit 1
fi

if [[ "$(rg -c 'TensorNpuOrderedSumRows #' \
        "${ROOT}/rtl/TensorNpuSumRowsWritebackAdapter.v")" != 1 ]]; then
    printf 'adapter must instantiate exactly one public OrderedSumRows Engine\n' >&2
    exit 1
fi

if rg -n 'TensorNpuFp(32|64)' \
        "${ROOT}/rtl/TensorNpuSumRowsWritebackAdapter.v" \
        > "${LOG_DIR}/numeric-bypass-audit.log"; then
    printf 'adapter instantiated a numeric bypass outside OrderedSumRows\n' >&2
    exit 1
fi

sha256sum \
    "${MANIFEST}" \
    "${ROOT}/rtl/TensorNpuOrderedSumRows.v" \
    "${ROOT}/rtl/TensorNpuSumRowsWritebackAdapter.v" \
    "${ROOT}/tests/tb_sum_rows_writeback_adapter.sv" \
    "${ROOT}/scripts/run_sum_rows_writeback_adapter.sh" \
    > "${LOG_DIR}/source-sha256.txt"

set -o pipefail
"${OBJ_DIR}/Vtb_sum_rows_writeback_adapter" \
    | tee "${LOG_DIR}/run.log"
grep -Fq '[NPU-SUM-ROWS-WRITEBACK][PASS]' "${LOG_DIR}/run.log"

if find "${BUILD_DIR}" "${LOG_DIR}" "${COMPILER_TMP}" -type f \
        \( -name '*.vcd' -o -name '*.fst' -o -name '*.lxt' \
           -o -name '*.lxt2' -o -name '*.vpd' \) -print -quit \
        | grep -q .; then
    printf 'waveform artifact found in fresh run\n' >&2
    exit 1
fi

printf 'build_dir=%s\nlog_dir=%s\ncompiler_tmp=%s\nprofile_census=%s\n' \
    "${BUILD_DIR}" "${LOG_DIR}" "${COMPILER_TMP}" "${PROFILE_CENSUS}"
