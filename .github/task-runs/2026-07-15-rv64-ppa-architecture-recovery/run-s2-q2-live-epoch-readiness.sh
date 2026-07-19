#!/usr/bin/env bash
set -euo pipefail

RUN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${RUN_DIR}/../../.." && pwd)"
EVIDENCE_DIR="${1:-${RUN_DIR}/evidence/r4-s2-q2-live-epoch-readiness-red}"
CHECKER="${RUN_DIR}/check-s2-q2-live-epoch-readiness.py"
MANIFEST="${RUN_DIR}/s2-q2-live-epoch-interface.json"
EXPECTED_EVIDENCE_BASELINE_SHA256="abfe4e248f27e50d4f6cafc69f7429dba37e36544b3a5d6ec01248993ed1dc88"
COMPLETE_MARKER="${EVIDENCE_DIR}/complete.marker"

mkdir -p "${EVIDENCE_DIR}"
rm -f -- "${COMPLETE_MARKER}"
cd "${REPO_ROOT}"

hash_paths=(
  ".github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/s2-q2-live-epoch-atomic-slice-contract.md"
  ".github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/s2-q2-live-epoch-interface.json"
  ".github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/check-s2-q2-live-epoch-readiness.py"
  ".github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/run-s2-q2-live-epoch-readiness.sh"
  "npc/rv64/vsrc/core/NpcCoreTop.v"
  "npc/rv64/vsrc/core/OooCoreTopGlue.v"
  "npc/rv64/vsrc/execute/OooExecuteBackend.v"
  "npc/rv64/vsrc/execute/OooAluCoreSlice.v"
  "npc/rv64/vsrc/decode/OooAluDecodeBackend.v"
  "npc/rv64/vsrc/execute/OooIntBackend.v"
  "npc/rv64/vsrc/memory/OooMemOwnerTracker.v"
  "npc/rv64/vsrc/memory/OooMemInflightQueue.v"
  "npc/rv64/vsrc/memory/OooStoreQueue.v"
  "npc/rv64/vsrc/rename_allocate/OooDispatchBackend.v"
  "npc/rv64/vsrc/writeback/OooRob.v"
  "npc/rv64/vsrc/core/CsrFile.v"
  "npc/rv64/vsrc/control/OooControlPlane.v"
  "npc/rv64/vsrc/control/OooRedirectArbiter.v"
  "npc/rv64/vsrc/frontend/OooFrontend.v"
  "npc/rv64/vsrc/frontend/OooFetchPcOutstandingSequencer.v"
  "npc/rv64/vsrc/memory/OooMemoryAccess.v"
  "npc/rv64/vsrc/memory/OooMemoryRequestGate.v"
  "npc/rv64/vsrc/memory/OooMemAxiBridge.v"
  "npc/rv64/vsrc/memory/OooSv39Tlb.v"
  "npc/rv64/vsrc/memory/OooMmuEpochOwner.v"
  "npc/rv64/vsrc/frontend/OooFetchAxiBridge.v"
  "npc/rv64/vsrc/cache/OooFetchPacketCache.v"
  "npc/rv64/vsrc/include/define.v"
)
# readiness 读取前先冻结同一份 28-path inventory；后验 snapshot 必须逐字节一致。
sha256sum "${hash_paths[@]}" > "${EVIDENCE_DIR}/sources.pre.sha256"

python3 "${CHECKER}" --self-test > "${EVIDENCE_DIR}/checker-self-test.log"
python3 - "${MANIFEST}" "${EVIDENCE_DIR}/checker-self-test.log" <<'PY'
import json
import re
import sys

manifest = json.load(open(sys.argv[1], encoding="utf-8"))
lines = open(sys.argv[2], encoding="utf-8").read().splitlines()
actual = []
for line in lines:
    match = re.fullmatch(r"\[S2-Q2-CHECKER-SELFTEST\]\[PASS\] (.+)", line)
    if match and not match.group(1).startswith("mutations="):
        actual.append(match.group(1))
if actual != manifest["self_test_inventory"]:
    raise SystemExit("[S2-Q2-RUNNER][FAIL] checker self-test name/order drift")
PY
expected_self_tests="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1], encoding="utf-8"))["evidence_baseline"]["expected_self_test_mutations"])' "${MANIFEST}")"
if ! grep -Fqx "[S2-Q2-CHECKER-SELFTEST][PASS] mutations=${expected_self_tests}" \
    "${EVIDENCE_DIR}/checker-self-test.log"; then
  printf '[S2-Q2-RUNNER][FAIL] checker self-test baseline mismatch\n' >&2
  exit 1
fi

actual_baseline_sha256="$(python3 -c 'import hashlib,json,sys; value=json.load(open(sys.argv[1], encoding="utf-8"))["evidence_baseline"]; encoded=json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":")).encode(); print(hashlib.sha256(encoded).hexdigest())' "${MANIFEST}")"
if [[ "${actual_baseline_sha256}" != "${EXPECTED_EVIDENCE_BASELINE_SHA256}" ]]; then
  printf '[S2-Q2-RUNNER][FAIL] reviewed evidence-baseline digest drift\n' >&2
  exit 1
fi

set +e
python3 "${CHECKER}" > "${EVIDENCE_DIR}/readiness.log" 2>&1
readiness_rc=$?
set -e
printf '%s\n' "${readiness_rc}" > "${EVIDENCE_DIR}/readiness.rc"

expected_rc="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1], encoding="utf-8"))["evidence_baseline"]["expected_live_readiness_rc"])' "${MANIFEST}")"
if [[ "${readiness_rc}" -ne "${expected_rc}" ]]; then
  printf '[S2-Q2-RUNNER][FAIL] expected readiness rc=%s, got %s\n' \
      "${expected_rc}" "${readiness_rc}" >&2
  exit 1
fi

red_count="$(grep -c '^\[S2-Q2-READINESS\]\[RED\]' "${EVIDENCE_DIR}/readiness.log")"
if [[ "${red_count}" -le 0 ]]; then
  printf '[S2-Q2-RUNNER][FAIL] readiness RED list is empty\n' >&2
  exit 1
fi
expected_red_count="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1], encoding="utf-8"))["evidence_baseline"]["expected_red_count"])' "${MANIFEST}")"
if [[ "${red_count}" -ne "${expected_red_count}" ]]; then
  printf '[S2-Q2-RUNNER][FAIL] RED count drift: expected=%s actual=%s\n' \
      "${expected_red_count}" "${red_count}" >&2
  exit 1
fi

red_sha256="$(grep '^\[S2-Q2-READINESS\]\[RED\]' \
    "${EVIDENCE_DIR}/readiness.log" | sha256sum | awk '{print $1}')"
expected_red_sha256="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1], encoding="utf-8"))["evidence_baseline"]["expected_red_sha256"])' "${MANIFEST}")"
if [[ "${red_sha256}" != "${expected_red_sha256}" ]]; then
  printf '[S2-Q2-RUNNER][FAIL] RED digest drift: expected=%s actual=%s\n' \
      "${expected_red_sha256}" "${red_sha256}" >&2
  exit 1
fi

sha256sum "${hash_paths[@]}" > "${EVIDENCE_DIR}/sources.post.sha256"
if ! cmp -s -- "${EVIDENCE_DIR}/sources.pre.sha256" \
    "${EVIDENCE_DIR}/sources.post.sha256"; then
  printf '[S2-Q2-RUNNER][FAIL] source inventory changed during readiness\n' >&2
  exit 1
fi
cp -- "${EVIDENCE_DIR}/sources.post.sha256" "${EVIDENCE_DIR}/sources.sha256"
sha256sum -c "${EVIDENCE_DIR}/sources.sha256" > "${EVIDENCE_DIR}/sources-check.log"

{
  printf 'contract_schema=s2-q2-live-epoch-interface-v7\n'
  printf 'checker_self_test=PASS\n'
  printf 'live_readiness=RED\n'
  printf 'unresolved=%s\n' "${red_count}"
  printf 'red_sha256=%s\n' "${red_sha256}"
  printf 'scope=mem0-only; issue1 memory disabled; structural readiness necessary-only\n'
} > "${EVIDENCE_DIR}/summary.txt"

{
  printf 'status=complete\n'
  printf 'contract_schema=s2-q2-live-epoch-interface-v7\n'
  printf 'summary_sha256=%s\n' "$(sha256sum "${EVIDENCE_DIR}/summary.txt" | awk '{print $1}')"
  printf 'checker_self_test_sha256=%s\n' "$(sha256sum "${EVIDENCE_DIR}/checker-self-test.log" | awk '{print $1}')"
  printf 'readiness_sha256=%s\n' "$(sha256sum "${EVIDENCE_DIR}/readiness.log" | awk '{print $1}')"
  printf 'readiness_rc_sha256=%s\n' "$(sha256sum "${EVIDENCE_DIR}/readiness.rc" | awk '{print $1}')"
  printf 'sources_sha256=%s\n' "$(sha256sum "${EVIDENCE_DIR}/sources.sha256" | awk '{print $1}')"
  printf 'sources_pre_sha256=%s\n' "$(sha256sum "${EVIDENCE_DIR}/sources.pre.sha256" | awk '{print $1}')"
  printf 'sources_post_sha256=%s\n' "$(sha256sum "${EVIDENCE_DIR}/sources.post.sha256" | awk '{print $1}')"
  printf 'sources_check_sha256=%s\n' "$(sha256sum "${EVIDENCE_DIR}/sources-check.log" | awk '{print $1}')"
} > "${COMPLETE_MARKER}"

printf '[S2-Q2-RUNNER][PASS] expected live RED captured, unresolved=%s\n' "${red_count}"
