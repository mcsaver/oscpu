#!/usr/bin/env bash
set -euo pipefail

# Keep the fixed project root explicit so no path-discovery utility runs before
# the compiler-private directory is created.  EPOCHREALTIME and BASHPID are
# Bash builtins, so mkdir is the runner's first external tool.
ROOT=/home/lyg/PA/ysyx-workbench/npu/version_0820
RUN_STAMP="${EPOCHREALTIME//./}"
RUN_ID="mover-set-rows-${RUN_STAMP}-${BASHPID}"
COMPILER_TMP_DIR="${ROOT}/tmp/compiler/${RUN_ID}"
BUILD_DIR="${ROOT}/tmp/build/${RUN_ID}"
LOG_DIR="${ROOT}/tmp/logs/${RUN_ID}"
OBJ_DIR="${BUILD_DIR}/obj_dir"
MANIFEST="${ROOT}/tmp/logs/qwen-graph-manifest-v5/dispatch.manifest.json"
FP32_TO_FP16_RTL="${ROOT}/rtl/TensorNpuFp32ToFp16.v"
MOVER_RTL="${ROOT}/rtl/TensorNpuTensorMover.v"
SET_ROWS_RTL="${ROOT}/rtl/TensorNpuSetRowsEngine.v"
ADAPTER_RTL="${ROOT}/rtl/TensorNpuMoverSetRowsWritebackAdapter.v"
TB="${ROOT}/tests/tb_mover_set_rows_writeback_adapter.sv"
RUNNER="${ROOT}/scripts/run_mover_set_rows_writeback_adapter.sh"

mkdir -p "${COMPILER_TMP_DIR}" "${OBJ_DIR}" "${LOG_DIR}"
export TMPDIR="${COMPILER_TMP_DIR}"
export TMP="${COMPILER_TMP_DIR}"
export TEMP="${COMPILER_TMP_DIR}"
unset MAKEFLAGS MFLAGS

# ---------------------------------------------------------------------------
# Frozen-manifest census.  The manifest is parsed in one jq pass; all later
# reports operate on the small derived object.  Names and producer references
# are deliberately excluded from profile equality, while dtype/flags/ne/nb,
# views, arity and the complete zero op-params condition remain identity.
# ---------------------------------------------------------------------------
for REQUIRED_TOOL in jq rg diff find sha256sum verilator; do
    command -v "${REQUIRED_TOOL}"
done >"${LOG_DIR}/tools.log"

cat >"${LOG_DIR}/manifest-census.jq" <<'JQ'
def wanted:
       (.descriptor.op_name == "CPY")
    or (.descriptor.op_name == "CONT")
    or (.descriptor.op_name == "CONCAT")
    or (.descriptor.op_name == "SET_ROWS");

[.manifest.nodes[] | select(wanted)] as $nodes
| ($nodes
   | map({profile: {
       op: .descriptor.op_name,
       flags: .descriptor.flags,
       dst: {
         type_id: .descriptor.type_id,
         ne: .descriptor.ne,
         nb: .descriptor.nb,
         view_offs: .descriptor.view_offs,
         is_view: (.descriptor.view_src != null),
         params_zero: (.descriptor.op_params_hex
           == "00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000")
       },
       srcs: [.sources[] | {
         slot: .slot,
         type_id: .descriptor.type_id,
         flags: .descriptor.flags,
         ne: .descriptor.ne,
         nb: .descriptor.nb,
         view_offs: .descriptor.view_offs,
         is_view: (.descriptor.view_src != null)
       }]
     }})
   | sort_by(.profile | tojson)
   | group_by(.profile)
   | map(({count: length} + .[0].profile))
   | sort_by(.op, (.dst.ne | tojson), (.srcs | tojson))) as $profiles
| {
    schema: .schema,
    manifest_sha256: .manifest_sha256,
    header_node_count: .manifest.header.node_count,
    selected_total: ($nodes | length),
    counts: ($nodes
      | group_by(.descriptor.op_name)
      | map({key: .[0].descriptor.op_name, value: length})
      | from_entries),
    signature_count: ($profiles | length),
    identities: ($nodes | map({
      index: .index,
      canonical_id: .canonical_id,
      descriptor_sha256: .descriptor_sha256,
      op: .descriptor.op_name,
      flags: .descriptor.flags,
      classification: .classification,
      subtype: .semantic_key.subtype
    }) | sort_by(.index)),
    profiles: $profiles
  }
JQ

jq -S -f "${LOG_DIR}/manifest-census.jq" "${MANIFEST}" \
    >"${LOG_DIR}/manifest-derived.json"

jq -e '
       .selected_total == 114
   and .counts.CPY == 72
   and .counts.CONT == 12
   and .counts.CONCAT == 18
   and .counts.SET_ROWS == 12
   and .signature_count == 9
   and ((.identities | length) == 114)
   and (([.identities[].canonical_id] | unique | length) == 114)
   and (([.identities[].descriptor_sha256] | unique | length) == 114)
   and all(.identities[];
       (.flags == 16)
       and (.canonical_id | test("^[0-9a-f]{64}$"))
       and (.descriptor_sha256 | test("^[0-9a-f]{64}$")))
   and all(.profiles[]; (.flags == 16) and .dst.params_zero)
   and (([.profiles[].count] | add) == 114)
' "${LOG_DIR}/manifest-derived.json" >/dev/null

printf 'index\tcanonical_id\tdescriptor_sha256\top\tflags\tclassification\tsubtype\n' \
    >"${LOG_DIR}/manifest-identities.tsv"
jq -r '.identities[]
       | [.index, .canonical_id, .descriptor_sha256, .op, .flags,
          .classification, .subtype]
       | @tsv' "${LOG_DIR}/manifest-derived.json" \
    >>"${LOG_DIR}/manifest-identities.tsv"

jq -S '{schema, manifest_sha256, header_node_count, selected_total,
        counts, signature_count,
        unique_canonical_ids: ([.identities[].canonical_id] | unique | length),
        unique_descriptor_hashes:
          ([.identities[].descriptor_sha256] | unique | length)}' \
    "${LOG_DIR}/manifest-derived.json" \
    >"${LOG_DIR}/manifest-census.json"

jq -cS '.profiles[]' "${LOG_DIR}/manifest-derived.json" \
    >"${LOG_DIR}/manifest-profiles.actual.jsonl"

# Independent, hard-coded oracle for the exact nine frozen profiles.  jq -cS
# canonicalizes key order before diffing against the machine-derived profiles.
cat >"${LOG_DIR}/manifest-profiles.expected.raw.jsonl" <<'JSONL'
{"count":18,"dst":{"is_view":false,"nb":[4,16,98304,98304],"ne":[4,6144,1,1],"params_zero":true,"type_id":0,"view_offs":0},"flags":16,"op":"CONCAT","srcs":[{"flags":16,"is_view":true,"nb":[4,12,73728,73728],"ne":[3,6144,1,1],"slot":0,"type_id":0,"view_offs":0},{"flags":16,"is_view":true,"nb":[24576,4,24576,24576],"ne":[1,6144,1,1],"slot":1,"type_id":0,"view_offs":0}]}
{"count":6,"dst":{"is_view":false,"nb":[4,8192,8192,8192],"ne":[2048,1,1,1],"params_zero":true,"type_id":0,"view_offs":0},"flags":16,"op":"CONT","srcs":[{"flags":16,"is_view":true,"nb":[4,1024,1024,8192],"ne":[256,8,1,1],"slot":0,"type_id":0,"view_offs":0}]}
{"count":6,"dst":{"is_view":false,"nb":[4,8192,8192,8192],"ne":[2048,1,1,1],"params_zero":true,"type_id":0,"view_offs":0},"flags":16,"op":"CONT","srcs":[{"flags":16,"is_view":true,"nb":[4,2048,16384,16384],"ne":[256,8,1,1],"slot":0,"type_id":0,"view_offs":1024}]}
{"count":18,"dst":{"is_view":true,"nb":[4,73728,0,0],"ne":[18432,0,1,1],"params_zero":true,"type_id":0,"view_offs":73728},"flags":16,"op":"CPY","srcs":[{"flags":16,"is_view":false,"nb":[4,73728,0,0],"ne":[18432,0,1,1],"slot":0,"type_id":0,"view_offs":0},{"flags":16,"is_view":true,"nb":[4,73728,0,0],"ne":[18432,0,1,1],"slot":1,"type_id":0,"view_offs":73728}]}
{"count":18,"dst":{"is_view":true,"nb":[4,73728,73728,73728],"ne":[18432,1,1,1],"params_zero":true,"type_id":0,"view_offs":0},"flags":16,"op":"CPY","srcs":[{"flags":16,"is_view":true,"nb":[4,16,98304,98304],"ne":[3,6144,1,1],"slot":0,"type_id":0,"view_offs":4},{"flags":16,"is_view":true,"nb":[4,73728,73728,73728],"ne":[18432,1,1,1],"slot":1,"type_id":0,"view_offs":0}]}
{"count":18,"dst":{"is_view":true,"nb":[4,1048576,0,0],"ne":[262144,0,1,1],"params_zero":true,"type_id":0,"view_offs":1048576},"flags":16,"op":"CPY","srcs":[{"flags":16,"is_view":false,"nb":[4,1048576,0,0],"ne":[262144,0,1,1],"slot":0,"type_id":0,"view_offs":0},{"flags":16,"is_view":true,"nb":[4,1048576,0,0],"ne":[262144,0,1,1],"slot":1,"type_id":0,"view_offs":1048576}]}
{"count":18,"dst":{"is_view":true,"nb":[4,1048576,1048576,1048576],"ne":[262144,1,1,1],"params_zero":true,"type_id":0,"view_offs":0},"flags":16,"op":"CPY","srcs":[{"flags":16,"is_view":false,"nb":[4,512,65536,1048576],"ne":[128,128,16,1],"slot":0,"type_id":0,"view_offs":0},{"flags":16,"is_view":true,"nb":[4,1048576,1048576,1048576],"ne":[262144,1,1,1],"slot":1,"type_id":0,"view_offs":0}]}
{"count":6,"dst":{"is_view":true,"nb":[2,2,262144,262144],"ne":[1,131072,1,1],"params_zero":true,"type_id":1,"view_offs":0},"flags":16,"op":"SET_ROWS","srcs":[{"flags":16,"is_view":true,"nb":[4,4,2048,2048],"ne":[1,512,1,1],"slot":0,"type_id":0,"view_offs":0},{"flags":1,"is_view":false,"nb":[8,4096,4096,4096],"ne":[512,1,1,1],"slot":1,"type_id":27,"view_offs":0},{"flags":16,"is_view":true,"nb":[2,2,262144,262144],"ne":[1,131072,1,1],"slot":2,"type_id":1,"view_offs":0}]}
{"count":6,"dst":{"is_view":true,"nb":[2,1024,262144,262144],"ne":[512,256,1,1],"params_zero":true,"type_id":1,"view_offs":0},"flags":16,"op":"SET_ROWS","srcs":[{"flags":16,"is_view":true,"nb":[4,2048,2048,2048],"ne":[512,1,1,1],"slot":0,"type_id":0,"view_offs":0},{"flags":1,"is_view":false,"nb":[8,8,8,8],"ne":[1,1,1,1],"slot":1,"type_id":27,"view_offs":0},{"flags":0,"is_view":false,"nb":[2,1024,262144,262144],"ne":[512,256,1,1],"slot":2,"type_id":1,"view_offs":0}]}
JSONL

jq -cS . "${LOG_DIR}/manifest-profiles.expected.raw.jsonl" \
    >"${LOG_DIR}/manifest-profiles.expected.jsonl"
if ! diff -u "${LOG_DIR}/manifest-profiles.expected.jsonl" \
        "${LOG_DIR}/manifest-profiles.actual.jsonl" \
        >"${LOG_DIR}/manifest-profiles.diff"; then
    printf 'frozen manifest profile mismatch:\n' >&2
    cat "${LOG_DIR}/manifest-profiles.diff" >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# Static ownership and anti-bypass audits.  The TB may manipulate raw fixture
# bytes and compare fixed raw lookup values, but may not inspect DUT hierarchy,
# use host floating-point/DPI, force RTL, or generate waveforms.
# ---------------------------------------------------------------------------
: >"${LOG_DIR}/forbidden-host-hierarchy-audit.log"
if rg -n --pcre2 \
    '(^|[^[:alnum:]_])(force|release|shortreal|real)([^[:alnum:]_]|$)|DPI-C|DPI|\$bitstoshortreal|\$shortrealtobits|\$itor|\$rtoi|\$(sqrt|ln|log10|exp|pow)|[[:space:]]dut[[:space:]]*\.' \
    "${TB}" >>"${LOG_DIR}/forbidden-host-hierarchy-audit.log"; then
    printf '[FAIL] forbidden host arithmetic/hierarchy construct found\n' \
        >>"${LOG_DIR}/forbidden-host-hierarchy-audit.log"
    exit 1
fi
printf '[PASS] no dut hierarchy peek, force/release, DPI, real/shortreal, or host FP intrinsic\n' \
    >>"${LOG_DIR}/forbidden-host-hierarchy-audit.log"

MOVER_INSTANCE_COUNT="$(grep -Ec \
    '^[[:space:]]*TensorNpuTensorMover[[:space:]]*#\(' "${ADAPTER_RTL}")"
SET_ROWS_INSTANCE_COUNT="$(grep -Ec \
    '^[[:space:]]*TensorNpuSetRowsEngine[[:space:]]*#\(' "${ADAPTER_RTL}")"
TB_ADAPTER_INSTANCE_COUNT="$(grep -Ec \
    '^[[:space:]]*TensorNpuMoverSetRowsWritebackAdapter[[:space:]]*#\(' "${TB}")"
TB_DIRECT_CHILD_COUNT="$(grep -Ec \
    '^[[:space:]]*TensorNpu(TensorMover|SetRowsEngine|Fp32ToFp16)[[:space:]]*#?\(' \
    "${TB}" || true)"
ADAPTER_DIRECT_NUMERIC_COUNT="$(grep -Ec \
    '^[[:space:]]*TensorNpu(Fp32ToFp16|Fp16ToFp32|Q8|Fp(Add|Mul|Div|Fma))[[:alnum:]_]*[[:space:]]*#?\(' \
    "${ADAPTER_RTL}" || true)"
{
    printf 'mover_child_instances=%s\n' "${MOVER_INSTANCE_COUNT}"
    printf 'set_rows_child_instances=%s\n' "${SET_ROWS_INSTANCE_COUNT}"
    printf 'tb_adapter_instances=%s\n' "${TB_ADAPTER_INSTANCE_COUNT}"
    printf 'tb_direct_child_instances=%s\n' "${TB_DIRECT_CHILD_COUNT}"
    printf 'adapter_direct_numeric_bypass_instances=%s\n' \
        "${ADAPTER_DIRECT_NUMERIC_COUNT}"
} >"${LOG_DIR}/child-ownership-audit.log"
if [[ "${MOVER_INSTANCE_COUNT}" != 1 \
        || "${SET_ROWS_INSTANCE_COUNT}" != 1 \
        || "${TB_ADAPTER_INSTANCE_COUNT}" != 1 \
        || "${TB_DIRECT_CHILD_COUNT}" != 0 \
        || "${ADAPTER_DIRECT_NUMERIC_COUNT}" != 0 ]]; then
    printf '[FAIL] child ownership or numeric bypass audit\n' \
        >>"${LOG_DIR}/child-ownership-audit.log"
    exit 1
fi
printf '[PASS] real engines exclusively own mover/conversion/scatter semantics\n' \
    >>"${LOG_DIR}/child-ownership-audit.log"

: >"${LOG_DIR}/waveform-static-audit.log"
if rg -n --pcre2 \
    '\$(dumpfile|dumpvars|dumpon|dumpoff|dumpall|dumpflush)|traceEverOn|\.(vcd|fst|lxt|lxt2)([^[:alnum:]_]|$)' \
    "${ADAPTER_RTL}" "${TB}" >>"${LOG_DIR}/waveform-static-audit.log"; then
    printf '[FAIL] waveform construct found\n' \
        >>"${LOG_DIR}/waveform-static-audit.log"
    exit 1
fi
NO_ASSERT_COUNT="$(grep -Ec \
    '^[[:space:]]*--no-assert[[:space:]]+\\$' "${RUNNER}")"
NO_TRACE_COUNT="$(grep -Ec \
    '^[[:space:]]*--no-trace[[:space:]]+\\$' "${RUNNER}")"
POSITIVE_TRACE_COUNT="$(grep -Ec \
    '(^|[[:space:]])--trace(-fst|-vcd)?([[:space:]\\]|$)' "${RUNNER}" || true)"
{
    printf 'runner_no_assert_count=%s\n' "${NO_ASSERT_COUNT}"
    printf 'runner_no_trace_count=%s\n' "${NO_TRACE_COUNT}"
    printf 'runner_positive_trace_count=%s\n' "${POSITIVE_TRACE_COUNT}"
} >>"${LOG_DIR}/waveform-static-audit.log"
if [[ "${NO_ASSERT_COUNT}" != 1 || "${NO_TRACE_COUNT}" != 1 \
        || "${POSITIVE_TRACE_COUNT}" != 0 ]]; then
    printf '[FAIL] runner assertion/trace flags\n' \
        >>"${LOG_DIR}/waveform-static-audit.log"
    exit 1
fi
printf '[PASS] no waveform code; --no-assert/--no-trace frozen\n' \
    >>"${LOG_DIR}/waveform-static-audit.log"

verilator \
    --binary \
    --timing \
    -Wall \
    -Wno-fatal \
    --no-assert \
    --no-trace \
    -O3 \
    -CFLAGS "-O3 -DNDEBUG" \
    --Mdir "${OBJ_DIR}" \
    --top-module tb_mover_set_rows_writeback_adapter \
    "${FP32_TO_FP16_RTL}" \
    "${MOVER_RTL}" \
    "${SET_ROWS_RTL}" \
    "${ADAPTER_RTL}" \
    "${TB}" \
    >"${LOG_DIR}/build.log" 2>&1

if grep -Eq '%Warning|%Error' "${LOG_DIR}/build.log"; then
    printf 'project-owned Verilator diagnostic found in %s\n' \
        "${LOG_DIR}/build.log" >&2
    exit 1
fi

set -o pipefail
"${OBJ_DIR}/Vtb_mover_set_rows_writeback_adapter" \
    | tee "${LOG_DIR}/run.log"

grep -Fq \
    '[NPU-MOVER-SET-ROWS][PASS]' \
    "${LOG_DIR}/run.log"

find "${BUILD_DIR}" "${LOG_DIR}" "${COMPILER_TMP_DIR}" -type f \
    \( -iname '*.vcd' -o -iname '*.fst' -o -iname '*.lxt' \
       -o -iname '*.lxt2' -o -iname '*.ghw' \) -print \
    >"${LOG_DIR}/waveform-find.log"
if [[ -s "${LOG_DIR}/waveform-find.log" ]]; then
    printf 'waveform artifact found in fresh-run paths\n' >&2
    exit 1
fi

sha256sum \
    "${MANIFEST}" \
    "${FP32_TO_FP16_RTL}" \
    "${MOVER_RTL}" \
    "${SET_ROWS_RTL}" \
    "${ADAPTER_RTL}" \
    "${TB}" \
    "${RUNNER}" \
    >"${LOG_DIR}/sha256.log"

printf 'manifest_census='
jq -c . "${LOG_DIR}/manifest-census.json"
printf 'manifest_identities=%s rows=114\n' \
    "${LOG_DIR}/manifest-identities.tsv"
printf 'manifest_profile_diff=%s bytes=%s\n' \
    "${LOG_DIR}/manifest-profiles.diff" \
    "$(wc -c <"${LOG_DIR}/manifest-profiles.diff")"
printf 'run_id=%s\nbuild_dir=%s\nlog_dir=%s\ncompiler_tmp_dir=%s\n' \
    "${RUN_ID}" "${BUILD_DIR}" "${LOG_DIR}" "${COMPILER_TMP_DIR}"
