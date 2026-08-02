#!/usr/bin/env bash

set -uo pipefail

repo_root=/home/lyg/PA/ysyx-workbench
run_dir="${repo_root}/.github/task-runs/2026-08-02-rv64-v13p-store-b-terminal-cpi-architecture-v1"
evidence_root="${run_dir}/evidence/coremark-b-fusion-ab"
status_path="${run_dir}/coremark-b-fusion-ab.status"
image_path="${repo_root}/.github/task-runs/2026-08-01-rv64-v13i-int-iq-survivor-map/evidence/full-core-functional-attempt1/images/benchmarks/coremark.bin"
config_path="${repo_root}/npc/rv64/.config"
candidate_bridge="${repo_root}/npc/rv64/vsrc/memory/OooMemAxiBridge.v"
tmp_root="$(mktemp -d)"
baseline_bridge="${tmp_root}/OooMemAxiBridge.v"
finalized=0
cleanup_rc=0

source "${repo_root}/scripts/task-run-status.sh"
mkdir -p "${evidence_root}"
task_run_status_init "${status_path}"
task_run_status_install_signal_traps

cleanup_one_build() {
  local mode=$1
  local build_dir="${repo_root}/npc/rv64/build-v13p-b-fusion-${mode}"
  local resolved
  resolved=$(realpath -m -- "${build_dir}") || return 1
  if [[ "${resolved}" != "/home/lyg/PA/ysyx-workbench/npc/rv64/build-v13p-b-fusion-${mode}" ]]; then
    printf '%s\n' "[v13p-coremark] refusing cleanup target: ${resolved}" >&2
    return 2
  fi
  if [[ -d "${resolved}" ]]; then
    rm -rf -- "${resolved}"
  fi
  [[ ! -e "${resolved}" ]]
}

cleanup_all() {
  local rc=0
  cleanup_one_build baseline || rc=$?
  cleanup_one_build candidate || rc=$?
  local resolved_tmp
  resolved_tmp=$(realpath -m -- "${tmp_root}") || rc=$?
  if [[ "${resolved_tmp}" == /tmp/tmp.* && -d "${resolved_tmp}" ]]; then
    rm -rf -- "${resolved_tmp}" || rc=$?
  elif [[ -e "${tmp_root}" ]]; then
    printf '%s\n' "[v13p-coremark] refusing temporary cleanup: ${resolved_tmp}" >&2
    rc=3
  fi
  return "${rc}"
}

finalize_on_exit() {
  local command_rc=$?
  cleanup_all || cleanup_rc=$?
  if [[ "${finalized}" -eq 0 ]]; then
    task_run_status_stage "exit-trap"
    task_run_status_finalize "${command_rc}" "${cleanup_rc}" || true
  fi
}
trap finalize_on_exit EXIT

task_run_status_stage "input-binding"
input_rc=0
image_sha256=""
config_sha256=""
if [[ -f "${image_path}" && -f "${config_path}" && -f "${candidate_bridge}" ]]; then
  image_sha256=$(sha256sum "${image_path}" | awk '{print $1}')
  config_sha256=$(sha256sum "${config_path}" | awk '{print $1}')
else
  input_rc=1
fi
if [[ "${image_sha256}" != "a7117f7490f6ff0e23008f631f2f0977b9d0e269380931e2079ae5c1e0cb238b" ||
      "${config_sha256}" != "63ecfda4b377430c468116a77efb77345705c3fcf9aca499b641b287cc6da5ce" ]]; then
  input_rc=1
fi

if [[ "${input_rc}" -eq 0 ]]; then
  sed "/^  assign data_store_b_response_fusion_w =$/ {
    n
    c\\      1'b0;
  }" "${candidate_bridge}" > "${baseline_bridge}"
  diff -u --label candidate/OooMemAxiBridge.v \
    --label baseline-tieoff/OooMemAxiBridge.v \
    "${candidate_bridge}" "${baseline_bridge}" \
    > "${evidence_root}/baseline-tieoff.diff"
  diff_rc=$?
  PYTHONDONTWRITEBYTECODE=1 python3 - \
      "${candidate_bridge}" "${baseline_bridge}" <<'PY'
import pathlib
import sys

candidate = pathlib.Path(sys.argv[1]).read_text(encoding="utf-8").splitlines()
baseline = pathlib.Path(sys.argv[2]).read_text(encoding="utf-8").splitlines()
diffs = [(i, a, b) for i, (a, b) in enumerate(zip(candidate, baseline), 1)
         if a != b]
if (len(candidate) != len(baseline) or len(diffs) != 1 or
        diffs[0][1:] != (
            "      data_store_b_terminal_w && fsm_normal_w;",
            "      1'b0;")):
    raise SystemExit(f"unexpected baseline mutation: {diffs}")
PY
  mutation_rc=$?
  if [[ "${diff_rc}" -ne 1 || "${mutation_rc}" -ne 0 ]]; then
    input_rc=1
  fi
fi

declare -A build_rc identity_rc run_rc parser_rc build_bytes
for mode in baseline candidate; do
  build_rc[${mode}]=1
  identity_rc[${mode}]=1
  run_rc[${mode}]=1
  parser_rc[${mode}]=1
  build_bytes[${mode}]=0
done

for mode in baseline candidate; do
  mode_dir="${evidence_root}/${mode}"
  build_dir="${repo_root}/npc/rv64/build-v13p-b-fusion-${mode}"
  binary_path="${build_dir}/NpcSimTop"
  build_log="${mode_dir}/build.log"
  raw_log="${mode_dir}/coremark-v8.raw.log"
  identity_path="${mode_dir}/pre-run-identity.json"
  result_path="${mode_dir}/counter-result.json"
  binding_path="${mode_dir}/post-run-binding.json"
  mkdir -p "${mode_dir}"

  if [[ "${input_rc}" -eq 0 ]]; then
    task_run_status_stage "verilator-build-${mode}"
    mkdir -p "${build_dir}"
    if [[ "${mode}" == baseline ]]; then
      make -C "${repo_root}/npc/rv64" \
        BUILD_DIR="${build_dir}" \
        VERILATOR_BUILD_JOBS=1 \
        RTL_OOO_MEM_AXI_BRIDGE="${baseline_bridge}" \
        "${binary_path}" > "${build_log}" 2>&1
    else
      make -C "${repo_root}/npc/rv64" \
        BUILD_DIR="${build_dir}" \
        VERILATOR_BUILD_JOBS=1 \
        "${binary_path}" > "${build_log}" 2>&1
    fi
    build_rc[${mode}]=$?
  fi

  if [[ "${build_rc[${mode}]}" -eq 0 && -x "${binary_path}" ]]; then
    task_run_status_stage "pre-run-identity-${mode}"
    build_bytes[${mode}]=$(du -sb "${build_dir}" | awk '{print $1}')
    actual_bridge="${candidate_bridge}"
    if [[ "${mode}" == baseline ]]; then
      actual_bridge="${baseline_bridge}"
    fi
    PYTHONDONTWRITEBYTECODE=1 python3 - \
        "${repo_root}" "${mode}" "${actual_bridge}" \
        "${build_log}" "${build_dir}" "${binary_path}" \
        "${image_path}" "${config_path}" "${identity_path}" \
        "${build_bytes[${mode}]}" <<'PY'
import hashlib
import json
import pathlib
import re
import subprocess
import sys

(root_arg, mode, bridge_arg, build_log_arg, build_dir_arg, binary_arg,
 image_arg, config_arg, identity_arg, build_bytes_arg) = sys.argv[1:]
root = pathlib.Path(root_arg).resolve()
bridge = pathlib.Path(bridge_arg).resolve()
build_log = pathlib.Path(build_log_arg).resolve()
build_dir = pathlib.Path(build_dir_arg).resolve()
binary = pathlib.Path(binary_arg).resolve()
image = pathlib.Path(image_arg).resolve()
config = pathlib.Path(config_arg).resolve()
identity_path = pathlib.Path(identity_arg)

def sha(path: pathlib.Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()

texts = [build_log.read_text(encoding="utf-8", errors="replace")]
for pattern in ("*__verFiles.dat", "*.d"):
    for path in build_dir.rglob(pattern):
        texts.append(path.read_text(encoding="utf-8", errors="replace"))

tokens = set()
for text in texts:
    tokens.update(re.findall(r"[^\s\"'()]+", text))

source_paths = {bridge}
for token in tokens:
    token = token.rstrip("\\:;,")
    if token.startswith("-I"):
        token = token[2:]
    path = pathlib.Path(token)
    if not path.is_absolute():
        path = (root / "npc/rv64" / path).resolve()
    else:
        path = path.resolve()
    if not path.is_file():
        continue
    try:
        rel = path.relative_to(root).as_posix()
    except ValueError:
        continue
    if rel.startswith(("npc/rv64/vsrc/", "npc/rv64/csrc/")):
        source_paths.add(path)

canonical_bridge = "npc/rv64/vsrc/memory/OooMemAxiBridge.v"
manifest = {}
actual_paths = {}
for path in sorted(source_paths):
    if path == bridge:
        key = canonical_bridge
    else:
        key = path.relative_to(root).as_posix()
    if key in manifest and actual_paths[key] != str(path):
        raise ValueError(f"duplicate canonical source key: {key}")
    manifest[key] = sha(path)
    actual_paths[key] = str(path)

required = {
    canonical_bridge,
    "npc/rv64/vsrc/sim/NpcSimTop.sv",
    "npc/rv64/csrc/cpu/cpu-exec.cpp",
}
if len(manifest) < 60 or not required.issubset(manifest):
    raise ValueError(
        f"incomplete actual compile manifest count={len(manifest)} "
        f"missing={sorted(required - set(manifest))}")

binding_files = [
    "npc/rv64/Makefile",
    "npc/rv64/vsrc/filelist.mk",
    "npc/rv64/configs/product-rtl-defaults.mk",
    "npc/rv64/design/arch/performance-counter-schema-v4.json",
    "npc/rv64/design/arch/performance-measurement-contract-v1.json",
    "npc/rv64/eval/ppa/policies/proxy-200mhz-v1.json",
    "npc/rv64/eval/ppa/tools/check.py",
]
binding_hashes = {rel: sha(root / rel) for rel in binding_files}
log_text = texts[0]
flags = {
    "verilator_assert": "--assert" in log_text,
    "ooo_assert_define": "+define+OOO_ASSERT" in log_text,
    "terminal_holder_assert_define":
        "+define+OOO_TERMINAL_HOLDER_ASSERT" in log_text,
}
if not all(flags.values()):
    raise ValueError(f"required assertion build flags missing: {flags}")

identity = {
    "schema": "npc-rv64-v13p-coremark-ab-pre-run-v1",
    "mode": mode,
    "single_mechanism": "aggregate_b_terminal_response_fusion",
    "baseline_tieoff": mode == "baseline",
    "simulator_executable_sha256": sha(binary),
    "build_log_sha256": sha(build_log),
    "coremark_image_sha256": sha(image),
    "config_sha256": sha(config),
    "build_bytes_before_cleanup": int(build_bytes_arg),
    "build_flags": flags,
    "tool": {
        "verilator": subprocess.check_output(
            ["verilator", "--version"], text=True).strip(),
        "compiler": subprocess.check_output(
            ["c++", "--version"], text=True).splitlines()[0],
    },
    "run_contract": {
        "image": str(image),
        "region_start_pc": "0x00000000800017a8",
        "region_end_pc": "0x00000000800017b0",
        "batch": True,
        "no_vga": True,
        "max_cycles": 6000000,
        "timeout_seconds": 240,
    },
    "actual_compile_source_sha256": dict(sorted(manifest.items())),
    "actual_compile_source_paths": dict(sorted(actual_paths.items())),
    "binding_file_sha256": binding_hashes,
}
identity_path.write_text(json.dumps(identity, indent=2) + "\n",
                         encoding="utf-8")
PY
    identity_rc[${mode}]=$?
  fi

  if [[ "${identity_rc[${mode}]}" -eq 0 && -s "${identity_path}" ]]; then
    task_run_status_stage "coremark-run-${mode}"
    NPC_REGION_START_PC=0x00000000800017a8 \
    NPC_REGION_END_PC=0x00000000800017b0 \
    timeout --signal=TERM 240s "${binary_path}" "${image_path}" \
      --batch --no-vga --max-cycles=6000000 > "${raw_log}" 2>&1
    run_rc[${mode}]=$?
  fi

  if [[ "${run_rc[${mode}]}" -eq 0 ]]; then
    task_run_status_stage "counter-parse-${mode}"
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONPATH="${repo_root}/npc/rv64/eval/ppa/tools" \
    python3 - "${repo_root}" "${mode}" "${raw_log}" \
        "${identity_path}" "${result_path}" "${binding_path}" \
        "${binary_path}" "${build_log}" "${image_path}" \
        "${config_path}" <<'PY'
import hashlib
import json
import pathlib
import re
import sys

import check

(root_arg, mode, raw_arg, identity_arg, result_arg, binding_arg,
 binary_arg, build_log_arg, image_arg, config_arg) = sys.argv[1:]
root = pathlib.Path(root_arg)
raw = pathlib.Path(raw_arg)
identity_path = pathlib.Path(identity_arg)
result_path = pathlib.Path(result_arg)
binding_path = pathlib.Path(binding_arg)
binary = pathlib.Path(binary_arg)
build_log = pathlib.Path(build_log_arg)
image = pathlib.Path(image_arg)
config = pathlib.Path(config_arg)

def sha(path: pathlib.Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()

identity = json.loads(identity_path.read_text(encoding="utf-8"))
if sha(binary) != identity["simulator_executable_sha256"]:
    raise ValueError("simulator executable drifted after identity freeze")
if sha(build_log) != identity["build_log_sha256"]:
    raise ValueError("build log drifted after identity freeze")
if sha(image) != identity["coremark_image_sha256"]:
    raise ValueError("CoreMark image drifted")
if sha(config) != identity["config_sha256"]:
    raise ValueError("configuration drifted")
for key, expected in identity["actual_compile_source_sha256"].items():
    path = pathlib.Path(identity["actual_compile_source_paths"][key])
    if not path.is_file() or sha(path) != expected:
        raise ValueError(f"compile source drifted: {key}")
for rel, expected in identity["binding_file_sha256"].items():
    if sha(root / rel) != expected:
        raise ValueError(f"binding file drifted: {rel}")

policy = json.loads((
    root / "npc/rv64/eval/ppa/policies/proxy-200mhz-v1.json"
).read_text(encoding="utf-8"))
counter_contract = json.loads((
    root / "npc/rv64/design/arch/performance-counter-schema-v4.json"
).read_text(encoding="utf-8"))
benchmark_contract = policy["performance_evidence"]["benchmark_contracts"][
    "coremark"]
parsed = check.parse_raw_benchmark_log(
    raw,
    "coremark",
    "pc_bounded_region_v1",
    benchmark_contract,
    "npc-rv64-performance-evidence-v8",
    counter_contract,
)
raw_text = raw.read_text(encoding="utf-8", errors="replace")
fatal_lines = [line for line in raw_text.splitlines() if re.search(
    r"(^%Error|Assertion failed|assertion failed|\\$fatal)", line)]
semantic = {
    "good_trap_count": parsed["good_trap_count"],
    "exit_code": parsed["exit_code"],
    "iterations": parsed["iterations"],
    "crc": parsed["crc"],
}
if semantic != {
        "good_trap_count": 1,
        "exit_code": 0,
        "iterations": 10,
        "crc": "0xfcaf",
}:
    raise ValueError(f"CoreMark semantic guardrail failed: {semantic}")
if fatal_lines:
    raise ValueError(f"RTL assertion/fatal markers present: {fatal_lines[:3]}")
if (parsed["cpi_stack"]["memory_lifecycle"]["lifecycle_unknown"] != 0 or
    parsed["cpi_stack"]["memory_request_detail"]["detail_unknown"] != 0 or
    parsed["retire_slots"]["unknown"] != 0 or
    parsed["retire_slots"]["head_lifecycle_unknown"] != 0):
    raise ValueError("performance counter conservation contains unknown cycles")

result = {
    "schema": "npc-rv64-v13p-coremark-ab-result-v1",
    "status": "PASS",
    "mode": mode,
    "cycles": parsed["cycles"],
    "retired_instructions": parsed["retired_instructions"],
    "cpi": parsed["cycles"] / parsed["retired_instructions"],
    "ipc": parsed["retired_instructions"] / parsed["cycles"],
    "semantic": semantic,
    "region": parsed["region"],
    "cpi_stack": parsed["cpi_stack"],
    "retire_slots": parsed["retire_slots"],
}
result_path.write_text(json.dumps(result, indent=2) + "\n",
                       encoding="utf-8")
binding = {
    "schema": "npc-rv64-v13p-coremark-ab-post-run-v1",
    "status": "PASS",
    "mode": mode,
    "transaction": {
        "build_rc": 0,
        "identity_rc": 0,
        "run_rc": 0,
        "parser_rc": 0,
        "good_trap_count": semantic["good_trap_count"],
        "rtl_assertion_failure_count": len(fatal_lines),
    },
    "artifacts": {
        "pre_run_identity_sha256": sha(identity_path),
        "build_log_sha256": sha(build_log),
        "simulator_executable_sha256": sha(binary),
        "raw_log_sha256": sha(raw),
        "counter_result_sha256": sha(result_path),
    },
    "post_run_source_identity_match": True,
    "region": {
        "cycles": parsed["cycles"],
        "retired_instructions": parsed["retired_instructions"],
    },
}
binding_path.write_text(json.dumps(binding, indent=2) + "\n",
                        encoding="utf-8")
PY
    parser_rc[${mode}]=$?
  fi

  task_run_status_stage "cleanup-build-${mode}"
  cleanup_one_build "${mode}" || cleanup_rc=$?
done

task_run_status_stage "pair-compare"
pair_rc=1
if [[ "${parser_rc[baseline]}" -eq 0 &&
      "${parser_rc[candidate]}" -eq 0 &&
      "${cleanup_rc}" -eq 0 ]]; then
  PYTHONDONTWRITEBYTECODE=1 python3 - \
      "${evidence_root}/baseline/pre-run-identity.json" \
      "${evidence_root}/candidate/pre-run-identity.json" \
      "${evidence_root}/baseline/counter-result.json" \
      "${evidence_root}/candidate/counter-result.json" \
      "${evidence_root}/comparison.json" <<'PY'
import json
import pathlib
import sys

bi_path, ci_path, br_path, cr_path, out_path = map(
    pathlib.Path, sys.argv[1:])
bi = json.loads(bi_path.read_text(encoding="utf-8"))
ci = json.loads(ci_path.read_text(encoding="utf-8"))
br = json.loads(br_path.read_text(encoding="utf-8"))
cr = json.loads(cr_path.read_text(encoding="utf-8"))

for key in ("coremark_image_sha256", "config_sha256", "tool",
            "run_contract", "binding_file_sha256"):
    if bi[key] != ci[key]:
        raise ValueError(f"baseline/candidate identity mismatch: {key}")
b_sources = bi["actual_compile_source_sha256"]
c_sources = ci["actual_compile_source_sha256"]
if set(b_sources) != set(c_sources):
    raise ValueError("baseline/candidate compile source key set differs")
diff_sources = sorted(
    key for key in b_sources if b_sources[key] != c_sources[key])
bridge_key = "npc/rv64/vsrc/memory/OooMemAxiBridge.v"
if diff_sources != [bridge_key]:
    raise ValueError(f"non-single-mechanism source drift: {diff_sources}")
if br["semantic"] != cr["semantic"]:
    raise ValueError("baseline/candidate software-visible semantic mismatch")
if br["retired_instructions"] != cr["retired_instructions"]:
    raise ValueError("baseline/candidate retired-instruction mismatch")
for key in ("start_pc", "stop_pc", "start_marker_semantics", "start_hits",
            "stop_hits", "start_retired", "stop_retired", "start_lane",
            "stop_lane", "retired_instructions", "final_schema",
            "final_total_hits"):
    if br["region"][key] != cr["region"][key]:
        raise ValueError(f"region contract mismatch: {key}")

cycles_delta = cr["cycles"] - br["cycles"]
cpi_delta = cr["cpi"] - br["cpi"]
response_delta = (
    cr["cpi_stack"]["memory_lifecycle"]["response_terminal"] -
    br["cpi_stack"]["memory_lifecycle"]["response_terminal"])
write_resp_delta = (
    cr["cpi_stack"]["memory_request_detail"]["axi_write_response"] -
    br["cpi_stack"]["memory_request_detail"]["axi_write_response"])
directional_support = cycles_delta < 0 and response_delta < 0
decision = ("DIRECTIONAL_CPI_GAIN_OBSERVED_CAUSAL_AND_PPA_PENDING"
            if directional_support else "REJECT_OR_CAUSAL_GAP")

comparison = {
    "schema": "npc-rv64-v13p-coremark-ab-comparison-v1",
    "status": "PASS",
    "single_mechanism_source_difference": diff_sources,
    "baseline": {
        "cycles": br["cycles"],
        "retired_instructions": br["retired_instructions"],
        "cpi": br["cpi"],
        "ipc": br["ipc"],
    },
    "candidate": {
        "cycles": cr["cycles"],
        "retired_instructions": cr["retired_instructions"],
        "cpi": cr["cpi"],
        "ipc": cr["ipc"],
    },
    "delta_candidate_minus_baseline": {
        "cycles": cycles_delta,
        "cycles_percent": cycles_delta * 100.0 / br["cycles"],
        "cpi": cpi_delta,
        "ipc": cr["ipc"] - br["ipc"],
        "memory_response_terminal": response_delta,
        "axi_write_response": write_resp_delta,
    },
    "semantic_equal": True,
    "retired_instruction_equal": True,
    "directional_supports_h1": directional_support,
    "causal_attribution": "GAP_NO_DIRECT_EVENT_COUNTER_AND_SINGLE_AB",
    "decision": decision,
    "promotion_state": "NOT_ELIGIBLE_PPA_PENDING",
}
out_path.write_text(json.dumps(comparison, indent=2) + "\n",
                    encoding="utf-8")
PY
  pair_rc=$?
fi

command_rc=1
if [[ "${input_rc}" -eq 0 &&
      "${build_rc[baseline]}" -eq 0 &&
      "${build_rc[candidate]}" -eq 0 &&
      "${identity_rc[baseline]}" -eq 0 &&
      "${identity_rc[candidate]}" -eq 0 &&
      "${run_rc[baseline]}" -eq 0 &&
      "${run_rc[candidate]}" -eq 0 &&
      "${parser_rc[baseline]}" -eq 0 &&
      "${parser_rc[candidate]}" -eq 0 &&
      "${pair_rc}" -eq 0 && "${cleanup_rc}" -eq 0 ]]; then
  command_rc=0
fi

printf '%s\n' \
  "input_rc=${input_rc}" \
  "baseline_build_rc=${build_rc[baseline]}" \
  "baseline_identity_rc=${identity_rc[baseline]}" \
  "baseline_run_rc=${run_rc[baseline]}" \
  "baseline_parser_rc=${parser_rc[baseline]}" \
  "candidate_build_rc=${build_rc[candidate]}" \
  "candidate_identity_rc=${identity_rc[candidate]}" \
  "candidate_run_rc=${run_rc[candidate]}" \
  "candidate_parser_rc=${parser_rc[candidate]}" \
  "pair_rc=${pair_rc}" \
  "cleanup_rc=${cleanup_rc}" \
  "baseline_build_bytes_deleted=${build_bytes[baseline]}" \
  "candidate_build_bytes_deleted=${build_bytes[candidate]}" \
  > "${evidence_root}/command-status.txt"

task_run_status_stage "evidence-complete"
if [[ "${command_rc}" -eq 0 &&
      -s "${evidence_root}/comparison.json" &&
      -s "${evidence_root}/baseline/post-run-binding.json" &&
      -s "${evidence_root}/candidate/post-run-binding.json" &&
      ! -e "${repo_root}/npc/rv64/build-v13p-b-fusion-baseline" &&
      ! -e "${repo_root}/npc/rv64/build-v13p-b-fusion-candidate" ]]; then
  task_run_status_mark_evidence_complete
fi
finalized=1
task_run_status_finalize "${command_rc}" "${cleanup_rc}"
