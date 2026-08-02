#!/usr/bin/env bash
set -euo pipefail
export PYTHONDONTWRITEBYTECODE=1

root="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"
run_dir="$root/.github/task-runs/2026-08-01-rv64-v11x-control-event-v9r-compact-rebind"
evidence="$run_dir/evidence"
snapshot_tool="$root/npc/rv64/eval/ppa/tools/control_event_sq_retry_evidence.py"
tool="$root/npc/rv64/eval/ppa/tools/control_event_current_evidence.py"
mutation_runner="$root/.github/task-runs/2026-07-23-rv64-v9o-control-event-current-design/run-control-event-rtl-mutations.py"
tb_dir="$root/npc/rv64/testbench"
temp_dir="$(mktemp -d /tmp/rv64-control-event-v11x.XXXXXXXX)"
cd "$root"

cleanup() {
  case "$temp_dir" in
    /tmp/rv64-control-event-v11x.*) rm -rf -- "$temp_dir" ;;
    *) printf '%s\n' "refusing cleanup outside CONTROL-EVENT temp root: $temp_dir" >&2 ;;
  esac
}
trap cleanup EXIT HUP INT TERM

python3 "$snapshot_tool" --root "$root" snapshot \
  --output "$evidence/v9o-source-before.json"
design_id="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["design_id"].removeprefix("sha256:"))' "$evidence/v9o-source-before.json")"

focused_tests='tb_ooo_control_event_apply_sequencer tb_ooo_redirect_arbiter tb_ooo_frontend_action_gate tb_ooo_load_queue tb_ooo_rob tb_ooo_dispatch_backend tb_ooo_int_backend tb_ooo_mem_axi_bridge tb_ooo_dual_mem_bridge_wrapper tb_ooo_core_top_glue'
focused_result="$temp_dir/v9o-focused-result"
focused_build="$temp_dir/v9o-focused-build"
make -B -C "$tb_dir" \
  TESTS="$focused_tests" \
  EXTRA_TESTS= \
  BUILD_DIR="$focused_build" \
  RESULT_DIR="$focused_result" \
  RTL_EVIDENCE_SHA="$design_id" \
  run
mkdir -p "$evidence/v9o-focused/logs"
for test_name in $focused_tests
do
  test -s "$focused_build/$test_name.vvp"
  python3 "$snapshot_tool" --root "$root" normalize-log \
    --input "$focused_result/logs/$test_name.log" \
    --output "$evidence/v9o-focused/logs/$test_name.log" \
    --temp-root "$temp_dir"
done

config_tests='tb_ooo_rob tb_ooo_core_top_glue_v9o_csr_qh tb_ooo_core_top_glue'
config_result="$temp_dir/v9o-config-result"
config_build="$temp_dir/v9o-config-build"
ivflags="-g2012 -Wall -I$root/npc/rv64/vsrc -I$root/npc/rv64/vsrc/include -I$tb_dir/common -DOOO_ASSERT -DOOO_CSR_QUEUE_HEAD=1"
make -B -C "$tb_dir" \
  TESTS="$config_tests" \
  EXTRA_TESTS= \
  BUILD_DIR="$config_build" \
  RESULT_DIR="$config_result" \
  IVFLAGS="$ivflags" \
  RTL_EVIDENCE_SHA="$design_id" \
  run
mkdir -p "$evidence/v9o-config/logs"
for test_name in $config_tests
do
  test -s "$config_build/$test_name.vvp"
  python3 "$snapshot_tool" --root "$root" normalize-log \
    --input "$config_result/logs/$test_name.log" \
    --output "$evidence/v9o-config/logs/$test_name.log" \
    --temp-root "$temp_dir"
done

python3 "$mutation_runner" \
  --root "$root" \
  --output "$evidence/v9o-mutations/summary.json"
python3 "$tool" --root "$root" materialize-patches

python3 "$snapshot_tool" --root "$root" snapshot \
  --output "$evidence/v9o-source-after.json"
cmp "$evidence/v9o-source-before.json" "$evidence/v9o-source-after.json"
python3 "$tool" --root "$root" build \
  --output "$root/npc/rv64/eval/ppa/evidence/control-event-current.json"
python3 "$tool" --root "$root" verify \
  --input "$root/npc/rv64/eval/ppa/evidence/control-event-current.json"
python3 -m unittest \
  npc.rv64.eval.ppa.tests.test_control_event_current_evidence -v
test -z "$(find "$run_dir" -type f -name '*.vvp' -print -quit)"

printf '%s\n' \
  '[V11X-CONTROL-EVENT-CURRENT] focused=10/10 config=3/3 variants=11/11-rejected retained_vvp=0 PASS'
