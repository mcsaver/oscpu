#!/usr/bin/env bash

set -uo pipefail
export PYTHONDONTWRITEBYTECODE=1

repo_root=$(pwd -P)
run_dir=${repo_root}/.github/task-runs/2026-08-05-rv64-v15g-v9p-terminal-root-cause-backfill
evidence=${run_dir}/evidence/historical-current-f7a-run-1
status_path=${run_dir}/historical-current-f7a-run-1.status
runtime_root=${repo_root}/.github/runtime-artifacts/v15g-historical-current-f7a-run-1
command_rc=0
cleanup_rc=0
finalized=0

[[ -d ${repo_root}/npc/rv64 && -d ${repo_root}/.github ]] || exit 2
case $(realpath -m "${runtime_root}") in
  "${repo_root}/.github/runtime-artifacts/"*) ;;
  *) exit 2 ;;
esac
if [[ -e ${evidence} || -e ${status_path} || -e ${runtime_root} ]]; then
  printf '%s\n' '[RV64-HISTORICAL-CURRENT-F7A][FAIL] output already exists' >&2
  exit 2
fi
mkdir -p "${evidence}" "${runtime_root}"
source "${repo_root}/scripts/task-run-status.sh"
task_run_status_init "${status_path}"
task_run_status_install_signal_traps

cleanup_runtime() {
  case $(realpath -m "${runtime_root}") in
    "${repo_root}/.github/runtime-artifacts/"*)
      rm -rf -- "${runtime_root}" || cleanup_rc=$?
      ;;
    *) cleanup_rc=1 ;;
  esac
}

finalize_on_exit() {
  local exit_rc=$?
  if [[ ${command_rc} -eq 0 && ${exit_rc} -ne 0 ]]; then
    command_rc=${exit_rc}
  fi
  cleanup_runtime
  if [[ ${finalized} -eq 0 ]]; then
    task_run_status_stage exit-trap
    task_run_status_finalize "${command_rc}" "${cleanup_rc}" || true
  fi
}
trap finalize_on_exit EXIT

task_run_status_stage queue-head-current
python3 -B npc/rv64/testbench/scripts/run_v12c_serialize_qh_current.py \
  --repo-root "${repo_root}" --output-dir "${evidence}/qh" \
  >"${evidence}/qh.driver.log" 2>&1 || command_rc=$?

if [[ ${command_rc} -eq 0 ]]; then
  task_run_status_stage stop-hold-current
  python3 -B npc/rv64/testbench/scripts/run_v12c_serialize_system_current.py \
    --repo-root "${repo_root}" --output-dir "${evidence}/system" \
    >"${evidence}/system.driver.log" 2>&1 || command_rc=$?
fi

if [[ ${command_rc} -eq 0 ]]; then
  task_run_status_stage exit-active-memory-current
  python3 -B npc/rv64/testbench/scripts/run_historical_exit_current.py \
    --result-dir "${evidence}/exit" \
    >"${evidence}/exit.driver.log" 2>&1 || command_rc=$?
fi

if [[ ${command_rc} -eq 0 ]]; then
  task_run_status_stage v14g-owner-fence-current
  python3 -B npc/rv64/testbench/scripts/run_v14g_global_producer_owner_fence.py \
    --result-dir "${evidence}/v14g" --timeout-seconds 180 \
    >"${evidence}/v14g.driver.log" 2>&1 || command_rc=$?
fi

if [[ ${command_rc} -eq 0 ]]; then
  task_run_status_stage v14g-snapshot
  python3 -B "${run_dir}/capture-v14g-current.py" \
    --root "${repo_root}" --result-dir "${evidence}/v14g" \
    --output "${evidence}/holder-current.json" \
    >"${evidence}/holder-current.log" 2>&1 || command_rc=$?
fi

if [[ ${command_rc} -eq 0 ]]; then
  task_run_status_stage identity-and-cleanup
  python3 -B - "${repo_root}" "${evidence}" <<'PY' || command_rc=$?
import importlib.util
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1]).resolve()
evidence = pathlib.Path(sys.argv[2]).resolve()
spec = importlib.util.spec_from_file_location(
    "v15g_historical_current_arch", root / "npc/rv64/eval/ppa/tools/architecture_hard_gates.py"
)
assert spec is not None and spec.loader is not None
module = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = module
spec.loader.exec_module(module)
digest, files = module.rtl_binding(root)
design_id = f"sha256:{digest}"
if len(files) != 146:
    raise SystemExit("RTL file count drift")
for relative in ("qh/summary.json", "system/summary.json", "exit/summary.json", "holder-current.json"):
    value = json.loads((evidence / relative).read_text(encoding="utf-8"))
    observed = value.get("design_id")
    if observed != design_id:
        raise SystemExit(f"design-id drift: {relative}: {observed}")
    if value.get("status") != "PASS":
        raise SystemExit(f"status drift: {relative}")
images = sorted(path.relative_to(root).as_posix() for path in evidence.rglob("*.vvp"))
if images:
    raise SystemExit(f"compiled images retained: {images}")
print(
    "[RV64-HISTORICAL-CURRENT-F7A][PASS] "
    f"design_id={design_id} qh=PASS stop=PASS exit=PASS v14g=4/4+22/22 compiled-images=0"
)
PY
fi

if [[ ${command_rc} -eq 0 ]]; then
  task_run_status_stage evidence-complete
  task_run_status_mark_evidence_complete
fi
cleanup_runtime
task_run_status_finalize "${command_rc}" "${cleanup_rc}" || command_rc=$?
finalized=1
exit "${command_rc}"
