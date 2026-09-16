#!/usr/bin/env bash

set -euo pipefail

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(CDPATH= cd -- "${script_dir}/../../../.." && pwd)
tool="${script_dir}/tools/optimization_slice_selector.py"
current="${script_dir}/evidence/optimization-slice-current.json"
runtime_root="${repo_root}/.github/runtime-artifacts/tests"
validation_root=""

cleanup_validation_root() {
  if [[ -n "${validation_root}" &&
        "${validation_root}" == "${runtime_root}"/optimization-selector-validate.* ]]; then
    rm -rf -- "${validation_root}"
  fi
}

trap cleanup_validation_root EXIT

run_regression() {
  cd "${repo_root}"
  python3 -B -m unittest \
    npc.rv64.eval.ppa.tests.test_current_timing_path_analysis \
    npc.rv64.eval.ppa.tests.test_serialized_drain_owner_lifetime_analysis \
    npc.rv64.eval.ppa.tests.test_optimization_slice_selector -v 2>&1
}

validate_current_or_stale() {
  mkdir -p -- "${runtime_root}"
  validation_root=$(mktemp -d \
    "${runtime_root}/optimization-selector-validate.XXXXXX")
  local canonical_log="${validation_root}/canonical-verify.log"
  local live_log="${validation_root}/live-state.log"
  local live_state="${validation_root}/live-state.json"

  if ! python3 -B "${tool}" build --output "${live_state}" --report-only \
      >"${live_log}" 2>&1; then
    cat "${live_log}" >&2
    return 1
  fi
  if ! python3 -B "${tool}" verify --input "${live_state}" --report-only \
      >>"${live_log}" 2>&1; then
    cat "${live_log}" >&2
    return 1
  fi

  local canonical_rc=0
  if python3 -B "${tool}" verify --input "${current}" --report-only \
      >"${canonical_log}" 2>&1; then
    if ! python3 -B -c \
        'import json,sys; old=json.load(open(sys.argv[1],encoding="utf-8")); new=json.load(open(sys.argv[2],encoding="utf-8")); assert old["live_design_id"] == new["live_design_id"]' \
        "${current}" "${live_state}"; then
      cat "${canonical_log}" "${live_log}" >&2
      return 1
    fi
    current_state="canonical"
    return 0
  else
    canonical_rc=$?
  fi
  if [[ ${canonical_rc} -ne 2 ]] ||
      ! grep -Eq \
        'optimization research state design-id mismatch|stored selector decision is not canonical' \
        "${canonical_log}"; then
    cat "${canonical_log}" >&2
    return 1
  fi

  if ! python3 -B -c \
      'import json,sys; old=json.load(open(sys.argv[1],encoding="utf-8")); new=json.load(open(sys.argv[2],encoding="utf-8")); assert old["live_design_id"] != new["live_design_id"]; assert new["decision"] == "STATE_CONFLICT"; assert new["next_action"] == "STATE_RECONCILIATION"' \
      "${current}" "${live_state}"; then
    cat "${canonical_log}" "${live_log}" >&2
    return 1
  fi
  current_state="stale-fail-closed"
}

case "${1:-}" in
  --validate-only)
    [[ $# -eq 1 ]] || {
      printf '%s\n' "usage: $0 --validate-only" >&2
      exit 2
    }
    run_regression
    cd "${repo_root}"
    python3 -B "${script_dir}/tools/performance_bottleneck_census.py" verify \
      --input "${script_dir}/evidence/cpi-bottleneck-census-current.json"
    validate_current_or_stale
    ;;
  --output)
    [[ $# -eq 2 ]] || {
      printf '%s\n' "usage: $0 --output <workspace-path>" >&2
      exit 2
    }
    cd "${repo_root}"
    python3 -B "${tool}" build --output "$2"
    python3 -B "${tool}" verify --input "$2"
    ;;
  *)
    printf '%s\n' \
      "usage: $0 --validate-only | --output <workspace-path>" >&2
    exit 2
    ;;
esac

printf '%s\n' \
  "[RV64-OPTIMIZATION-SLICE-SELECTOR][PASS] policy=v2 current=${current_state:-generated}"
