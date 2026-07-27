#!/usr/bin/env bash
set -euo pipefail

run_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(git -C "${run_dir}" rev-parse --show-toplevel)"
tb_dir="${repo_root}/npc/rv64/testbench"
build_dir="${tb_dir}/build-v9v-full-core-cohort-scope"
result_dir="${run_dir}/focused"
evidence_dir="${run_dir}/evidence"
source_id_tool="${repo_root}/.github/task-runs/2026-07-23-rv64-v9o-control-event-current-design/evidence_source_set.py"
audit_tool="${repo_root}/npc/rv64/eval/ppa/tools/arch_stable_freeze.py"
candidate="${repo_root}/npc/rv64/eval/ppa/arch-stable/full-core-current.json"

mkdir -p "${result_dir}" "${evidence_dir}"

rtl_design_sha() {
  python3 - "${repo_root}" <<'PY'
import pathlib
import sys

root = pathlib.Path(sys.argv[1]).resolve()
sys.path.insert(0, str(root / "npc/rv64/eval/ppa/tools"))
import architecture_hard_gates as arch

print(arch.rtl_binding(root)[0])
PY
}

design_sha_before="$(rtl_design_sha)"
verification_sha_before="$(
  python3 "${source_id_tool}" \
    --root "${repo_root}" \
    --kind verification
)"

tests=(
  tb_decode_unit
  tb_csr_file
  tb_ooo_fetch_head_classify_gate
  tb_ooo_priv_system
  tb_ooo_int_backend
  tb_ooo_mem_owner_terminal_collector
  tb_ooo_int_backend_v9r_sq_retry_c0
  tb_ooo_mem_axi_bridge_v9r_sq_retry_c0
)

make -B -C "${tb_dir}" \
  "TESTS=${tests[*]}" \
  EXTRA_TESTS= \
  "BUILD_DIR=${build_dir}" \
  "RESULT_DIR=${result_dir}" \
  "RTL_EVIDENCE_SHA=${design_sha_before}" \
  run 2>&1 | tee "${evidence_dir}/focused-run.log"

for log_path in "${result_dir}"/logs/*.log; do
  printf '[V9V-VERIFICATION-SOURCE-ID] sha256:%s\n' \
    "${verification_sha_before}" >> "${log_path}"
done

python3 -m unittest \
  npc.rv64.eval.ppa.tests.test_arch_stable_freeze \
  2>&1 | tee "${evidence_dir}/arch-stable-unittest.log"

python3 \
  "${repo_root}/.github/task-runs/2026-07-23-rv64-v9o-control-event-current-design/build-evidence-index.py" \
  --verify 2>&1 | tee "${evidence_dir}/control-event-index-verify.log"

python3 "${audit_tool}" audit "${candidate}" \
  --output "${evidence_dir}/arch-stable-audit.json" \
  2>&1 | tee "${evidence_dir}/arch-stable-audit.log"

design_sha_after="$(rtl_design_sha)"
verification_sha_after="$(
  python3 "${source_id_tool}" \
    --root "${repo_root}" \
    --kind verification
)"
test "${design_sha_after}" = "${design_sha_before}"
test "${verification_sha_after}" = "${verification_sha_before}"

python3 - \
  "${repo_root}" \
  "${run_dir}" \
  "${design_sha_before}" \
  "${design_sha_after}" \
  "${verification_sha_before}" \
  "${tests[@]}" <<'PY'
import datetime
import hashlib
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1]).resolve()
run_dir = pathlib.Path(sys.argv[2]).resolve()
design_before = sys.argv[3]
design_after = sys.argv[4]
verification_sha = sys.argv[5]
tests = sys.argv[6:]


def sha256(path: pathlib.Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def artifact(path: pathlib.Path) -> dict[str, object]:
    resolved = path.resolve(strict=True)
    resolved.relative_to(root)
    return {
        "path": resolved.relative_to(root).as_posix(),
        "sha256": sha256(resolved),
        "size_bytes": resolved.stat().st_size,
    }


logs: dict[str, dict[str, object]] = {}
for test in tests:
    path = run_dir / "focused/logs" / f"{test}.log"
    text = path.read_text(encoding="utf-8")
    required = (
        f"[PASS] {test}",
        f"[RTL-DESIGN-ID] sha256:{design_before}",
        f"[V9V-VERIFICATION-SOURCE-ID] sha256:{verification_sha}",
        "[RESULT] PASS",
    )
    if any(text.count(marker) != 1 for marker in required):
        raise SystemExit(f"{test}: PASS/source binding marker mismatch")
    logs[test] = artifact(path)

collector = (
    run_dir / "focused/logs/tb_ooo_mem_owner_terminal_collector.log"
).read_text(encoding="utf-8")
backend = (
    run_dir / "focused/logs/tb_ooo_int_backend_v9r_sq_retry_c0.log"
).read_text(encoding="utf-8")
bridge = (
    run_dir / "focused/logs/tb_ooo_mem_axi_bridge_v9r_sq_retry_c0.log"
).read_text(encoding="utf-8")
markers = {
    "collector_capture": (
        "[V8P-TCOLL-12INGRESS-CAPTURE] pending=12 "
        "mask=aa8a28a8 PASS"
    ),
    "collector_drain": (
        "[V8P-TCOLL-12INGRESS-DRAIN] seen=12 "
        "mask=aa8a28a8 PASS"
    ),
    "backend_natural_trap": (
        "[V9R-SQ-RETRY-NATURAL-TRAP] rob_head=1 bank1=1 PASS"
    ),
    "backend_two_banks": (
        "[V9R-SQ-RETRY-C0-HANDOFF-PASS] "
        "banks=2 forced=2 natural_trap=1 PASS"
    ),
    "bridge_hold_release": (
        "[V9R-MEM-SQ-RETRY-C0-HANDOFF-PASS] "
        "state=S_SQ_QUERY held=1 release=1 PASS"
    ),
}
marker_sources = {
    "collector_capture": collector,
    "collector_drain": collector,
    "backend_natural_trap": backend,
    "backend_two_banks": backend,
    "bridge_hold_release": bridge,
}
for name, marker in markers.items():
    if marker_sources[name].count(marker) != 1:
        raise SystemExit(f"missing exact terminal/holder marker: {name}")

audit_path = run_dir / "evidence/arch-stable-audit.json"
audit = json.loads(audit_path.read_text(encoding="utf-8"))
checks = {
    item["check_id"]: item["status"] for item in audit["checks"]
}
exclusions = (
    "A-COHERENCE-G1",
    "DEBUG-TRIGGER-G1",
    "SFENCE-SINVAL-G1",
    "WFI-G1",
)
for debt_id in exclusions:
    if checks.get(f"debt.{debt_id}.cohort_exclusion") != "PASS":
        raise SystemExit(f"{debt_id}: cohort exclusion is not PASS")
if checks.get("debt.cohort_exclusions.exact") != "PASS":
    raise SystemExit("candidate/ledger exclusion membership is not exact")
if checks.get("debt.SERIALIZE-G1.resolved") != "GAP":
    raise SystemExit("SERIALIZE-G1 boundary was not preserved")
if not (
    audit.get("architecture_freeze") == "GAP"
    and audit.get("ppa") == "UNQUALIFIED"
    and audit.get("promotion_eligible") is False
):
    raise SystemExit("full-core/PPA boundary was promoted")

payload = {
    "schema": "npc-rv64-v9v-full-core-cohort-scope-evidence-v1",
    "generated_at_utc": datetime.datetime.now(
        datetime.timezone.utc
    ).isoformat(),
    "status": "PASS",
    "cohort_id": "full-core-single-hart-rv64-dual-issue-ooo-v1",
    "design_id": f"sha256:{design_before}",
    "rtl_design_id_before": f"sha256:{design_before}",
    "rtl_design_id_after": f"sha256:{design_after}",
    "rtl_source_unchanged": design_before == design_after,
    "verification_source_id": f"sha256:{verification_sha}",
    "focused": {
        "required": len(tests),
        "passed": len(logs),
        "logs": logs,
    },
    "terminal_owner_holder_markers": markers,
    "cohort_exclusions": {
        debt_id: checks[f"debt.{debt_id}.cohort_exclusion"]
        for debt_id in exclusions
    },
    "exact_exclusion_membership": checks[
        "debt.cohort_exclusions.exact"
    ],
    "serialize_status": checks["debt.SERIALIZE-G1.resolved"],
    "architecture_freeze": audit["architecture_freeze"],
    "ppa": audit["ppa"],
    "promotion_eligible": audit["promotion_eligible"],
    "blocker_count": len(audit["blockers"]),
    "artifacts": {
        "focused_summary": artifact(run_dir / "focused/summary.txt"),
        "audit": artifact(audit_path),
        "audit_log": artifact(
            run_dir / "evidence/arch-stable-audit.log"
        ),
        "arch_stable_unittest": artifact(
            run_dir / "evidence/arch-stable-unittest.log"
        ),
        "control_event_index_verify": artifact(
            run_dir / "evidence/control-event-index-verify.log"
        ),
    },
}
(run_dir / "evidence/summary.json").write_text(
    json.dumps(payload, indent=2, sort_keys=True) + "\n",
    encoding="utf-8",
)
print(
    "[V9V-COHORT-SCOPE] "
    f"focused={len(logs)}/{len(tests)} "
    "exclusions=4/4 exact=true "
    f"architecture={audit['architecture_freeze']} "
    f"ppa={audit['ppa']} status=PASS"
)
PY
