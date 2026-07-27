#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
task_run_dir="${repo_root}/.github/task-runs/2026-07-23-rv64-v9p-serialize-current-design"
result_dir="${task_run_dir}/terminal-duplicate-focused/diagnostic-mutation"
testbench_dir="${repo_root}/npc/rv64/testbench"
backend="${repo_root}/npc/rv64/vsrc/execute/OooIntBackend.v"
bridge="${repo_root}/npc/rv64/vsrc/memory/OooMemAxiBridge.v"
mutator="${repo_root}/.github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/mutate-v8s-dual-memory-core.py"
holder_mutator="${task_run_dir}/mutate-terminal-holder-identity.py"
temp_dir="$(mktemp -d "${TMPDIR:-/tmp}/v9p-terminal-duplicate.XXXXXX")"

cleanup() {
  case "${temp_dir}" in
    "${TMPDIR:-/tmp}"/v9p-terminal-duplicate.*)
      rm -rf -- "${temp_dir}"
      ;;
  esac
}
trap cleanup EXIT

mkdir -p "${result_dir}"

positive_build="${temp_dir}/positive-build"
positive_result="${temp_dir}/positive-result"
positive_log="${positive_result}/logs/tb_ooo_int_backend.log"
make -B -C "${testbench_dir}" \
  BUILD_DIR="${positive_build}" \
  RESULT_DIR="${positive_result}" \
  IVFLAGS='-g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -DOOO_TERMINAL_HOLDER_ASSERT -DV8S_DUAL_MEMORY_FOCUSED' \
  "${positive_log}" > "${result_dir}/positive-driver.log" 2>&1
cp -- "${positive_log}" "${result_dir}/positive.log"
grep -Fq "[V8S-DUAL-MEMORY-CORE]" "${result_dir}/positive.log"
if grep -Fq "[S2-G1-TCOLL-INGRESS-DUP]" "${result_dir}/positive.log"; then
  printf '%s\n' "[V9P-TERMINAL-DIAGNOSTIC][FAIL] positive RTL emitted duplicate ingress"
  exit 1
fi

bridge_positive_build="${temp_dir}/bridge-positive-build"
bridge_positive_result="${temp_dir}/bridge-positive-result"
bridge_positive_log="${bridge_positive_result}/logs/tb_ooo_int_backend_v8x_backend_bridge_recovery.log"
make -B -C "${testbench_dir}" \
  BUILD_DIR="${bridge_positive_build}" \
  RESULT_DIR="${bridge_positive_result}" \
  IVFLAGS='-g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -DOOO_TERMINAL_HOLDER_ASSERT' \
  "${bridge_positive_log}" > "${result_dir}/bridge-positive-driver.log" 2>&1
cp -- "${bridge_positive_log}" "${result_dir}/bridge-positive.log"
grep -Fq "[V8X-BACKEND-BRIDGE-RECOVERY]" \
  "${result_dir}/bridge-positive.log"
if grep -Eq '\[V9Q-(BRIDGE-HOLDER|TRANSIENT-HOLDER|TRANSIENT-BRIDGE|DUAL-REQ-TOKEN)-DISJOINT\]' \
    "${result_dir}/bridge-positive.log"; then
  printf '%s\n' "[V9P-TERMINAL-DIAGNOSTIC][FAIL] positive bridge lifecycle violated holder matrix"
  exit 1
fi

mutant="${temp_dir}/mutant/OooIntBackend.v"
python3 "${mutator}" duplicate_bridge_drop_token "${backend}" "${mutant}" \
  > "${result_dir}/mutator.log" 2>&1

negative_build="${temp_dir}/negative-build"
negative_result="${temp_dir}/negative-result"
negative_log="${negative_result}/logs/tb_ooo_int_backend.log"
set +e
make -B -C "${testbench_dir}" \
  BUILD_DIR="${negative_build}" \
  RESULT_DIR="${negative_result}" \
  RTL_OOO_INT_BACKEND="${mutant}" \
  IVFLAGS='-g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -DOOO_TERMINAL_HOLDER_ASSERT -DV8S_DUAL_MEMORY_FOCUSED' \
  "${negative_log}" > "${result_dir}/negative-driver.log" 2>&1
negative_rc=$?
set -e

test "${negative_rc}" -ne 0
test -f "${negative_log}"
cp -- "${negative_log}" "${result_dir}/negative.log"
grep -Fq "[S2-G1-TCOLL-INGRESS-DUP]" "${result_dir}/negative.log"
grep -Eq '\[S2-G1-TCOLL-INGRESS\] lane=2 .*duplicate=1' \
  "${result_dir}/negative.log"
grep -Eq '\[S2-G1-TCOLL-INGRESS\] lane=4 .*duplicate=1' \
  "${result_dir}/negative.log"

python3 - "${result_dir}/negative.log" <<'PY'
import pathlib
import re
import sys

text = pathlib.Path(sys.argv[1]).read_text(encoding="utf-8", errors="replace")
rows = {}
for lane, token in re.findall(
    r"\[S2-G1-TCOLL-INGRESS\] lane=(\d+).*?token=(\d+).*?duplicate=1",
    text,
):
    rows[int(lane)] = int(token)
if rows.get(2) != rows.get(4):
    raise SystemExit(
        f"diagnostic token mismatch: lane2={rows.get(2)} lane4={rows.get(4)}"
    )
print(
    "[V9P-TERMINAL-DIAGNOSTIC] "
    f"pair=2,4 token={rows[2]} positive=PASS negative=REJECTED"
)
PY

request_alias_backend="${temp_dir}/request-alias/OooIntBackend.v"
python3 "${holder_mutator}" dual_req_token_alias "${backend}" \
  "${request_alias_backend}" > "${result_dir}/request-alias-mutator.log" 2>&1
request_alias_build="${temp_dir}/request-alias-build"
request_alias_result="${temp_dir}/request-alias-result"
request_alias_log="${request_alias_result}/logs/tb_ooo_int_backend.log"
set +e
make -B -C "${testbench_dir}" \
  BUILD_DIR="${request_alias_build}" \
  RESULT_DIR="${request_alias_result}" \
  RTL_OOO_INT_BACKEND="${request_alias_backend}" \
  IVFLAGS='-g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -DOOO_TERMINAL_HOLDER_ASSERT -DV8S_DUAL_MEMORY_FOCUSED' \
  "${request_alias_log}" > "${result_dir}/request-alias-driver.log" 2>&1
request_alias_rc=$?
set -e
test "${request_alias_rc}" -ne 0
test -f "${request_alias_log}"
cp -- "${request_alias_log}" "${result_dir}/request-alias.log"
grep -Fq "[V9Q-DUAL-REQ-TOKEN-DISJOINT]" \
  "${result_dir}/request-alias.log"

station_retain_bridge="${temp_dir}/station-retain/OooMemAxiBridge.v"
python3 "${holder_mutator}" station_retain_after_advance "${bridge}" \
  "${station_retain_bridge}" > "${result_dir}/station-retain-mutator.log" 2>&1
station_retain_build="${temp_dir}/station-retain-build"
station_retain_result="${temp_dir}/station-retain-result"
station_retain_log="${station_retain_result}/logs/tb_ooo_int_backend_v8x_backend_bridge_recovery.log"
set +e
make -B -C "${testbench_dir}" \
  BUILD_DIR="${station_retain_build}" \
  RESULT_DIR="${station_retain_result}" \
  RTL_OOO_MEM_AXI_BRIDGE="${station_retain_bridge}" \
  IVFLAGS='-g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -DOOO_TERMINAL_HOLDER_ASSERT' \
  "${station_retain_log}" > "${result_dir}/station-retain-driver.log" 2>&1
station_retain_rc=$?
set -e
test "${station_retain_rc}" -ne 0
test -f "${station_retain_log}"
cp -- "${station_retain_log}" "${result_dir}/station-retain.log"
grep -Fq "[V9Q-BRIDGE-HOLDER-DISJOINT]" \
  "${result_dir}/station-retain.log"

printf '%s\n' \
  "positive=PASS" \
  "bridge_positive=PASS" \
  "negative=REJECTED" \
  "request_alias=REJECTED" \
  "station_retain=REJECTED" \
  "expected_pair=2,4" \
  "oracle=[S2-G1-TCOLL-INGRESS-DUP]" \
  > "${result_dir}/summary.txt"
