#!/usr/bin/env bash
set -euo pipefail

run_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(git -C "$run_dir" rev-parse --show-toplevel)
evidence_dir="${V9R_REBIND_EVIDENCE_DIR_OVERRIDE:-$run_dir/evidence}"
log_dir="$evidence_dir/logs"
mkdir -p "$log_dir"

v9o_dir="$repo_root/.github/task-runs/2026-07-23-rv64-v9o-control-event-current-design"
v9r_dir="$repo_root/.github/task-runs/2026-07-24-rv64-v9r-sq-retry-c0-handoff"
v10c_dir="$repo_root/.github/task-runs/2026-07-27-rv64-v10c-current-design-evidence-replay"
v10c_start_stage="${V9R_V10C_START_STAGE:-control-event-mutations}"
v10c_attempt="${V9R_V10C_ATTEMPT:-14}"
refresh_closed_evidence="${V9R_REFRESH_CLOSED_EVIDENCE:-0}"
if [[ ! "$v10c_attempt" =~ ^[1-9][0-9]*$ ]]; then
  printf '%s\n' \
    "[V9R-CURRENT-SOURCE-REBIND][FAIL] V9R_V10C_ATTEMPT must be a positive integer" \
    >&2
  exit 2
fi
if [[ "$refresh_closed_evidence" != "0" &&
      "$refresh_closed_evidence" != "1" ]]; then
  printf '%s\n' \
    "[V9R-CURRENT-SOURCE-REBIND][FAIL] V9R_REFRESH_CLOSED_EVIDENCE must be 0 or 1" \
    >&2
  exit 2
fi

run_logged() {
  local name=$1
  shift
  local log="$log_dir/$name.log"
  local rc

  set +e
  "$@" 2>&1 | tee "$log"
  rc=${PIPESTATUS[0]}
  set -e
  printf '%s\n' "$rc" > "$log_dir/$name.rc"
  if [[ "$rc" -ne 0 ]]; then
    printf '[V9R-CURRENT-SOURCE-REBIND][FAIL] step=%s rc=%s\n' \
      "$name" "$rc" >&2
    return "$rc"
  fi
  printf '[V9R-CURRENT-SOURCE-REBIND][PASS] step=%s\n' "$name"
}

python3 - "$repo_root" "$evidence_dir/preflight.json" <<'PY'
import hashlib
import importlib.util
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1]).resolve()
output = pathlib.Path(sys.argv[2])
arch_path = root / "npc/rv64/eval/ppa/tools/architecture_hard_gates.py"
spec = importlib.util.spec_from_file_location("v9r_rebind_arch_pre", arch_path)
assert spec and spec.loader
arch = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = arch
spec.loader.exec_module(arch)
rtl_sha, rtl_files = arch.rtl_binding(root)

def sha(relative: str) -> str:
    return hashlib.sha256((root / relative).read_bytes()).hexdigest()

payload = {
    "schema": "npc-rv64-control-event-source-rebind-receipt-v1",
    "phase": "preflight",
    "design_id": f"sha256:{rtl_sha}",
    "rtl_file_count": len(rtl_files),
    "verification_source_id": "sha256:" + __import__("subprocess").check_output(
        [
            "python3",
            str(root / ".github/task-runs/2026-07-23-rv64-v9o-control-event-current-design/evidence_source_set.py"),
            "--root",
            str(root),
            "--kind",
            "verification",
        ],
        text=True,
    ).strip(),
    "files": {
        relative: sha(relative)
        for relative in (
            "npc/rv64/vsrc/execute/OooIntBackend.v",
            "npc/rv64/vsrc/memory/OooMemAxiBridge.v",
            "npc/rv64/testbench/Makefile",
            "npc/rv64/testbench/tests/tb_ooo_int_backend.sv",
            ".github/task-runs/2026-07-23-rv64-v9o-control-event-current-design/evidence-index.json",
            ".github/task-runs/2026-07-24-rv64-v9r-sq-retry-c0-handoff/evidence/summary.json",
            "npc/rv64/design/arch/architecture-debt-ledger.json",
        )
    },
}
output.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
PY

run_logged context-brief \
  python3 "$repo_root/scripts/github_index_db.py" brief \
    control event current design \
    --profile npc-dev \
    --focus-scope non-history \
    --max-tokens 7000

run_logged v9o-focused \
  bash "$v9o_dir/run-focused.sh"
run_logged v9o-config-variants \
  bash "$v9o_dir/run-v9o-config-variants.sh"
if [[ "$refresh_closed_evidence" == "1" ]]; then
  run_logged refresh-fdg-arch-trap \
    make -C "$repo_root/npc/rv64" check-fdg-arch-trap
  run_logged refresh-xret-current-mode \
    make -C "$repo_root/npc/rv64" check-xret-current-mode
  run_logged refresh-memory-issue-lifecycle \
    make -C "$repo_root/npc/rv64" check-memory-issue-lifecycle
  run_logged refresh-irrevocable-owner-residency \
    bash "$repo_root/.github/task-runs/2026-07-23-rv64-v9n-irrevocable-write-owner-residency/run-focused.sh"
  run_logged refresh-ifu-axi-flush-drain \
    make -C "$repo_root/npc/rv64" check-ifu-axi-flush-drain
  run_logged refresh-ifu-fetch-provenance \
    make -C "$repo_root/npc/rv64" check-ifu-fetch-provenance
  run_logged refresh-ifu-access \
    make -C "$repo_root/npc/rv64" check-ifu-access
  run_logged refresh-ifu-tval \
    make -C "$repo_root/npc/rv64" check-ifu-tval
  run_logged refresh-ptw-pmp \
    make -C "$repo_root/npc/rv64" check-ptw-pmp
  run_logged refresh-instret-retirement \
    make -C "$repo_root/npc/rv64" check-instret-retirement
  run_logged refresh-fence-ordering \
    make -C "$repo_root/npc/rv64" check-fence-ordering
  run_logged refresh-holder-lifecycle \
    make -C "$repo_root/npc/rv64" check-global-producer-no-live-reuse
fi
run_logged v10c-currentness-resume \
  env \
    V10C_ATTEMPT="$v10c_attempt" \
    V10C_START_STAGE="$v10c_start_stage" \
    V10C_EVIDENCE_DIR_OVERRIDE="$evidence_dir/v10c-replay" \
    V10C_DRIVER_LOG_OVERRIDE="$log_dir/v10c-replay-driver.log" \
    V10C_REPLAY_STATUS_PATH_OVERRIDE="$evidence_dir/v10c-replay.status" \
    V10C_TASK_STATUS_PATH_OVERRIDE="$evidence_dir/v10c-task-run.status" \
    bash "$v10c_dir/run-current-design-evidence-replay.sh"
run_logged arch-stable-currentness-tests \
  env PYTHONDONTWRITEBYTECODE=1 \
    python3 -m unittest npc.rv64.eval.ppa.tests.test_arch_stable_freeze
run_logged v9o-index-post-ledger-verify \
  python3 "$v9o_dir/build-evidence-index.py" --verify

python3 - "$repo_root" "$evidence_dir/preflight.json" \
  "$evidence_dir/postflight.json" <<'PY'
import hashlib
import importlib.util
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1]).resolve()
preflight = json.loads(pathlib.Path(sys.argv[2]).read_text(encoding="utf-8"))
output = pathlib.Path(sys.argv[3])
arch_path = root / "npc/rv64/eval/ppa/tools/architecture_hard_gates.py"
spec = importlib.util.spec_from_file_location("v9r_rebind_arch_post", arch_path)
assert spec and spec.loader
arch = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = arch
spec.loader.exec_module(arch)
rtl_sha, rtl_files = arch.rtl_binding(root)

def sha(relative: str) -> str:
    return hashlib.sha256((root / relative).read_bytes()).hexdigest()

design_id = f"sha256:{rtl_sha}"
if design_id != preflight["design_id"]:
    raise SystemExit(
        f"RTL design drifted: pre={preflight['design_id']} post={design_id}"
    )
payload = {
    "schema": "npc-rv64-control-event-source-rebind-receipt-v1",
    "phase": "postflight",
    "result": "PASS",
    "design_id": design_id,
    "rtl_file_count": len(rtl_files),
    "production_rtl_unchanged": all(
        preflight["files"][relative] == sha(relative)
        for relative in (
            "npc/rv64/vsrc/execute/OooIntBackend.v",
            "npc/rv64/vsrc/memory/OooMemAxiBridge.v",
        )
    ),
    "files": {
        relative: sha(relative)
        for relative in (
            "npc/rv64/vsrc/execute/OooIntBackend.v",
            "npc/rv64/vsrc/memory/OooMemAxiBridge.v",
            "npc/rv64/testbench/Makefile",
            "npc/rv64/testbench/tests/tb_ooo_int_backend.sv",
            ".github/task-runs/2026-07-23-rv64-v9o-control-event-current-design/evidence-index.json",
            ".github/task-runs/2026-07-24-rv64-v9r-sq-retry-c0-handoff/evidence/summary.json",
            "npc/rv64/design/arch/architecture-debt-ledger.json",
        )
    },
}
output.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
print(
    "[V9R-CURRENT-SOURCE-REBIND][PASS] "
    f"design_id={design_id} production_rtl_unchanged=true"
)
PY
