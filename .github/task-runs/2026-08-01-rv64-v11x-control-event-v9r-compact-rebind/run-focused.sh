#!/usr/bin/env bash
set -euo pipefail
export PYTHONDONTWRITEBYTECODE=1

root="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"
run_dir="$root/.github/task-runs/2026-08-01-rv64-v11x-control-event-v9r-compact-rebind"
evidence="$run_dir/evidence"
tool="$root/npc/rv64/eval/ppa/tools/control_event_sq_retry_evidence.py"
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

mkdir -p "$evidence/baseline/logs"
python3 "$tool" --root "$root" snapshot --output "$evidence/source-before.json"
design_id="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["design_id"].removeprefix("sha256:"))' "$evidence/source-before.json")"

baseline_result="$temp_dir/baseline-result"
baseline_build="$temp_dir/baseline-build"
make -B -C "$tb_dir" \
  TESTS='tb_ooo_int_backend_v9r_sq_retry_c0 tb_ooo_mem_axi_bridge_v9r_sq_retry_c0 tb_ooo_int_backend_v11l_memory_retry_holder' \
  EXTRA_TESTS= \
  BUILD_DIR="$baseline_build" \
  RESULT_DIR="$baseline_result" \
  RTL_EVIDENCE_SHA="$design_id" \
  run
test -s "$baseline_build/tb_ooo_int_backend_v9r_sq_retry_c0.vvp"
test -s "$baseline_build/tb_ooo_mem_axi_bridge_v9r_sq_retry_c0.vvp"
test -s "$baseline_build/tb_ooo_int_backend_v11l_memory_retry_holder.vvp"
for test_name in \
  tb_ooo_int_backend_v9r_sq_retry_c0 \
  tb_ooo_mem_axi_bridge_v9r_sq_retry_c0 \
  tb_ooo_int_backend_v11l_memory_retry_holder
do
  python3 "$tool" --root "$root" normalize-log \
    --input "$baseline_result/logs/$test_name.log" \
    --output "$evidence/baseline/logs/$test_name.log" \
    --temp-root "$temp_dir"
done
printf 'PASS TRANSIENT_COMPILED_IMAGES=3\n' > "$evidence/baseline/status"

run_variant() {
  local case_name="$1"
  local test_name="$2"
  local rtl_variable="$3"
  local rtl_name="$4"
  local variant_dir="$evidence/$case_name"
  local variant_rtl="$temp_dir/mutations/$case_name/$rtl_name"
  local variant_result="$temp_dir/$case_name-result"
  local variant_build="$temp_dir/$case_name-build"
  local variant_sha
  local rc

  mkdir -p "$variant_dir/logs"
  python3 "$tool" --root "$root" mutate \
    --case "$case_name" \
    --output "$variant_rtl"
  variant_sha="$(sha256sum "$variant_rtl" | cut -d ' ' -f 1)"
  set +e
  make -B -C "$tb_dir" \
    TESTS="$test_name" \
    EXTRA_TESTS= \
    "$rtl_variable=$variant_rtl" \
    BUILD_DIR="$variant_build" \
    RESULT_DIR="$variant_result" \
    RTL_EVIDENCE_SHA="$design_id" \
    run
  rc=$?
  set -e
  test "$rc" -eq 2
  test -s "$variant_build/$test_name.vvp"
  python3 "$tool" --root "$root" normalize-log \
    --input "$variant_result/logs/$test_name.log" \
    --output "$variant_dir/logs/$test_name.log" \
    --temp-root "$temp_dir"
  printf 'REJECTED_COMPILE_SUCCESS_VARIANT rc=2 variant_sha256=%s TRANSIENT_COMPILED_IMAGE=1\n' \
    "$variant_sha" > "$variant_dir/status"
}

run_variant \
  backend-bank0-ready-open \
  tb_ooo_int_backend_v9r_sq_retry_c0 \
  RTL_OOO_INT_BACKEND \
  OooIntBackend.v
run_variant \
  backend-bank1-ready-open \
  tb_ooo_int_backend_v9r_sq_retry_c0 \
  RTL_OOO_INT_BACKEND \
  OooIntBackend.v
run_variant \
  bridge-retry-fire-open \
  tb_ooo_mem_axi_bridge_v9r_sq_retry_c0 \
  RTL_OOO_MEM_AXI_BRIDGE \
  OooMemAxiBridge.v
run_variant \
  backend-bank0-resident-fire-open \
  tb_ooo_int_backend_v11l_memory_retry_holder \
  RTL_OOO_INT_BACKEND \
  OooIntBackend.v
run_variant \
  backend-bank1-resident-fire-open \
  tb_ooo_int_backend_v11l_memory_retry_holder \
  RTL_OOO_INT_BACKEND \
  OooIntBackend.v

python3 "$tool" --root "$root" materialize-patches

python3 "$tool" --root "$root" snapshot --output "$evidence/source-after.json"
cmp "$evidence/source-before.json" "$evidence/source-after.json"
python3 "$tool" --root "$root" build \
  --output "$root/npc/rv64/eval/ppa/evidence/control-event-sq-retry-current.json"
python3 "$tool" --root "$root" verify \
  --input "$root/npc/rv64/eval/ppa/evidence/control-event-sq-retry-current.json"
python3 -m unittest \
  npc.rv64.eval.ppa.tests.test_control_event_sq_retry_evidence -v
test -z "$(find "$run_dir" -type f -name '*.vvp' -print -quit)"

printf '%s\n' \
  '[V11X-CONTROL-EVENT-V9R] baseline=3/3 variants=5/5-rejected retained_vvp=0 PASS'
