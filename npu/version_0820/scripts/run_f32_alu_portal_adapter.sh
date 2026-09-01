#!/usr/bin/env bash
set -euo pipefail

ROOT=/home/lyg/PA/ysyx-workbench/npu/version_0820
RUN_ID="f32-alu-portal-$(date -u +%Y%m%dT%H%M%S)-$$"
BUILD_DIR="${ROOT}/tmp/build/${RUN_ID}"
LOG_DIR="${ROOT}/tmp/logs/${RUN_ID}"
OBJ_DIR="${BUILD_DIR}/obj_dir"
COMPILER_TMP_DIR="${ROOT}/tmp/compiler/${RUN_ID}"
ADAPTER="${ROOT}/rtl/TensorNpuF32AluPortalAdapter.v"
LEGACY="${ROOT}/rtl/TensorNpuVectorF32Adapter.v"
CORE="${ROOT}/rtl/TensorNpuF32AluSimdCore.v"
TB="${ROOT}/tests/tb_f32_alu_portal_adapter.sv"
RUNNER="${ROOT}/scripts/run_f32_alu_portal_adapter.sh"

mkdir -p "${OBJ_DIR}" "${LOG_DIR}" "${COMPILER_TMP_DIR}"
export TMPDIR="${COMPILER_TMP_DIR}"
export TMP="${COMPILER_TMP_DIR}"
export TEMP="${COMPILER_TMP_DIR}"
unset MAKEFLAGS MFLAGS

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
    "${ROOT}/third_party/fpu-sp/verilog/src/float/fp_rnd.sv"
    "${ROOT}/rtl/TensorNpuFp32AddMul.v"
    "${CORE}"
    "${ADAPTER}"
    "${TB}"
)
printf '%s\n' "${SOURCES[@]}" >"${LOG_DIR}/sources.f"

if rg -n --pcre2 \
    '(^|[^[:alnum:]_])(force|release|shortreal|real)([^[:alnum:]_]|$)|DPI-C|DPI|\$bitstoshortreal|\$shortrealtobits|\$itor|\$rtoi|\$(sqrt|ln|log10|exp|pow)|[[:space:]]dut_(main|tail)[[:space:]]*\.' \
    "${TB}" >"${LOG_DIR}/host-hierarchy-audit.log"; then
    printf '[FAIL] forbidden host arithmetic or hierarchy construct\n' \
        >>"${LOG_DIR}/host-hierarchy-audit.log"
    exit 1
fi
printf '[PASS] raw-bit public-port RTL oracle only\n' \
    >>"${LOG_DIR}/host-hierarchy-audit.log"

if rg -n --pcre2 \
    '\$(dumpfile|dumpvars|dumpon|dumpoff|dumpall|dumpflush)|traceEverOn|\.(vcd|fst|lxt|lxt2)([^[:alnum:]_]|$)' \
    "${ADAPTER}" "${TB}" >"${LOG_DIR}/waveform-static-audit.log"; then
    printf '[FAIL] waveform construct found\n' \
        >>"${LOG_DIR}/waveform-static-audit.log"
    exit 1
fi
printf '[PASS] no waveform construct; --no-trace build\n' \
    >>"${LOG_DIR}/waveform-static-audit.log"

if rg -n --pcre2 \
    'gmem_req_(valid|ready|write|addr|wdata|wstrb)|gmem_rsp_(valid|ready|rdata|error)' \
    "${ADAPTER}" >"${LOG_DIR}/raw-gmem-audit.log"; then
    printf '[FAIL] raw GMEM transport leaked into portal adapter\n' \
        >>"${LOG_DIR}/raw-gmem-audit.log"
    exit 1
fi
if [[ "$(grep -Ec 'assign gmem_(read|write)_bytes_o = 64.b0;' "${ADAPTER}")" != 2 \
      || "$(grep -Ec 'assign expected_gmem_(read|write)_bytes_o = 64.b0;' "${ADAPTER}")" != 2 \
      || "$(grep -Ec 'assign gmem_outstanding_o = 1.b0;' "${ADAPTER}")" != 1 ]]; then
    printf '[FAIL] legacy GMEM ledger is not explicitly zero\n' \
        >>"${LOG_DIR}/raw-gmem-audit.log"
    exit 1
fi
printf '[PASS] no raw GMEM; legacy GMEM ledgers/outstanding are zero\n' \
    >>"${LOG_DIR}/raw-gmem-audit.log"

sed -n '/case (vector_flags_q\[4:0\])/,/endcase/p' "${LEGACY}" \
    | tr -d '[:space:]' >"${LOG_DIR}/legacy-profile-table.txt"
sed -n '/case (vector_flags_q\[4:0\])/,/endcase/p' "${ADAPTER}" \
    | tr -d '[:space:]' >"${LOG_DIR}/portal-profile-table.txt"
diff -u "${LOG_DIR}/legacy-profile-table.txt" \
        "${LOG_DIR}/portal-profile-table.txt" \
    >"${LOG_DIR}/profile-table.diff"

sed -n '/assign abi_reject_w =/,/(src1_stride_q != 64.d0)));/p' "${LEGACY}" \
    | sed '/^[[:space:]]*\/\//d' | tr -d '[:space:]' \
    >"${LOG_DIR}/legacy-validation.txt"
sed -n '/assign abi_reject_w =/,/(src1_stride_q != 64.d0)));/p' "${ADAPTER}" \
    | sed '/^[[:space:]]*\/\//d' | tr -d '[:space:]' \
    >"${LOG_DIR}/portal-validation.txt"
diff -u "${LOG_DIR}/legacy-validation.txt" \
        "${LOG_DIR}/portal-validation.txt" \
    >"${LOG_DIR}/validation.diff"
sha256sum "${LOG_DIR}/portal-profile-table.txt" \
          "${LOG_DIR}/portal-validation.txt" \
    >"${LOG_DIR}/frozen-contract-sha256.log"
printf '[PASS] P00--P18 table and ABI/capability/layout/IOVA expressions exact\n' \
    >"${LOG_DIR}/frozen-contract-audit.log"

if [[ "$(grep -Ec '^[[:space:]]*TensorNpuF32AluSimdCore[[:space:]]*#\(' "${ADAPTER}")" != 1 \
      || "$(grep -Ec '^[[:space:]]*TensorNpuFp32AddMul[[:space:]]+u_oracle_addmul' "${TB}")" != 1 ]]; then
    printf '[FAIL] expected one generated SIMD child declaration and one independent oracle\n' \
        >"${LOG_DIR}/topology-audit.log"
    exit 1
fi
printf '[PASS] one SIMD numerical child declaration; one public AddMul oracle\n' \
    >"${LOG_DIR}/topology-audit.log"

verilator \
    --binary \
    --build-jobs 2 \
    --timing \
    --sv \
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
    -I"${ROOT}/rtl" \
    --Mdir "${OBJ_DIR}" \
    --top-module tb_f32_alu_portal_adapter \
    "${SOURCES[@]}" \
    >"${LOG_DIR}/build.log" 2>&1

if grep -Eq '^%Warning|^%Error|(^|[[:space:]:])(warning:|error:|fatal error:)' \
        "${LOG_DIR}/build.log"; then
    printf 'unexpected compiler diagnostic; see %s\n' "${LOG_DIR}/build.log" >&2
    exit 1
fi
printf 'diagnostic_count=0\n' >"${LOG_DIR}/diagnostic-count.log"

set -o pipefail
"${OBJ_DIR}/Vtb_f32_alu_portal_adapter" | tee "${LOG_DIR}/run.log"
grep -Fq '[NPU-F32-ALU-PORTAL][PASS]' "${LOG_DIR}/run.log"

find "${BUILD_DIR}" "${LOG_DIR}" "${COMPILER_TMP_DIR}" -type f \
    \( -iname '*.vcd' -o -iname '*.fst' -o -iname '*.lxt' \
       -o -iname '*.lxt2' -o -iname '*.ghw' \) -print \
    >"${LOG_DIR}/waveform-find.log"
if [[ -s "${LOG_DIR}/waveform-find.log" ]]; then
    printf 'waveform artifact found in fresh-run paths\n' >&2
    exit 1
fi

sha256sum "${ADAPTER}" "${TB}" "${RUNNER}" >"${LOG_DIR}/sha256.log"
printf '[NPU-F32-ALU-PORTAL-RUNNER][PASS] build=O3 assertions=off trace=off diagnostic_count=0\n'
printf 'build_dir=%s\nlog_dir=%s\ncompiler_tmp_dir=%s\nsha256=%s\n' \
    "${BUILD_DIR}" "${LOG_DIR}" "${COMPILER_TMP_DIR}" \
    "${LOG_DIR}/sha256.log"
