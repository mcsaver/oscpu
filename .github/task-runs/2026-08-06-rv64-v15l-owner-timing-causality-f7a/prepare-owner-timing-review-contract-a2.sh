#!/usr/bin/env bash
set -Eeuo pipefail

repo_root=/home/lyg/PA/ysyx-workbench
task_root=${repo_root}/.github/task-runs/2026-08-06-rv64-v15l-owner-timing-causality-f7a
contract=${task_root}/subagent-contracts/v15l-owner-timing-independent-review-f7a-a2.json
rendered=${task_root}/subagent-contracts/v15l-owner-timing-independent-review-f7a-a2.rendered.txt
contract_hash=${task_root}/subagent-contracts/v15l-owner-timing-independent-review-f7a-a2.sha256
tool=${repo_root}/.github/skills/prepare-rtl-task-contract/scripts/rtl_task_contract.py

cd -- "${repo_root}"
mkdir -p -- "${task_root}/subagent-contracts"
python3 -B "${tool}" create \
  --task-id v15l-owner-timing-independent-review-f7a-a2 \
  --task-kind verification \
  --goal '独立复核本地 RV64 双发射 OoO 核 CoreMark/Dhrystone owner-timing A2 receipt：核对同一 design-id 下 ARCH_STABLE successor 与冻结 PERF_BASELINE 的 NpcSimTop、.config 和 workload image 身份，六次 PC-bounded diagnostic 事务的 cycles/retired 与 owner signature bit-exact、owner state/interval 守恒、overflow/invalid 为零、production RTL 前后无漂移及 runtime build 清理；根据 ROB-head 周期、事务频率、固定时长和 peer overlap 比较 H1 B-response、H2 write concurrency、H3 head residency 与 H4 reservation/SQ-query，但不得把相关性越级写成已授权 RTL 候选。' \
  --allow-path npc/rv64/eval/ppa/instrumentation \
  --allow-path npc/rv64/eval/ppa/tools/owner_timing_workload_ab.py \
  --allow-path npc/rv64/eval/ppa/tools/optimization_slice_selector.py \
  --allow-path npc/rv64/eval/ppa/tools/performance_baseline_current.py \
  --allow-path npc/rv64/eval/ppa/tests/test_owner_timing_workload_ab.py \
  --allow-path npc/rv64/eval/ppa/tests/test_optimization_slice_selector.py \
  --allow-path npc/rv64/eval/ppa/run-owner-timing-workload-ab.sh \
  --allow-path npc/rv64/eval/ppa/evidence/performance-baseline-current.json \
  --allow-path npc/rv64/eval/ppa/evidence/optimization-slice-current.json \
  --allow-path npc/rv64/design/arch/optimization-slice-selector-policy-v1.json \
  --allow-path npc/rv64/eval/ppa/optimization-slices-current.json \
  --allow-path .github/task-runs/2026-08-06-rv64-v15l-owner-timing-workload-ab-f7a-a2 \
  --allow-path .github/task-runs/2026-08-06-rv64-v15l-owner-timing-workload-ab-f7a-a1 \
  --allow-path .github/task-runs/2026-08-06-rv64-v15l-owner-timing-causality-f7a/evidence \
  --allow-path .github/task-runs/2026-08-06-rv64-v15k-performance-baseline-f7a-a1/evidence \
  --allow-path .github/runtime-artifacts \
  --allow-read-command rg \
  --allow-read-command sed \
  --allow-read-command sha256sum \
  --allow-write-command python3 \
  --write-path .github/runtime-artifacts/tests \
  --required-context .github/instructions/rv64-ppa-optimization-workflow.instructions.md \
  --required-context npc/rv64/eval/ppa/instrumentation/owner-timing-contract-v1.json \
  --required-context npc/rv64/eval/ppa/instrumentation/owner-timing-validation-profile-v1.json \
  --required-context npc/rv64/eval/ppa/tools/owner_timing_workload_ab.py \
  --required-context npc/rv64/eval/ppa/run-owner-timing-workload-ab.sh \
  --required-context npc/rv64/eval/ppa/tests/test_owner_timing_workload_ab.py \
  --required-context npc/rv64/eval/ppa/tests/test_optimization_slice_selector.py \
  --required-context npc/rv64/eval/ppa/evidence/performance-baseline-current.json \
  --required-context npc/rv64/eval/ppa/evidence/optimization-slice-current.json \
  --required-context .github/task-runs/2026-08-06-rv64-v15l-owner-timing-causality-f7a/evidence/arch-stable-current-f7a-v4.json \
  --required-context .github/task-runs/2026-08-06-rv64-v15l-owner-timing-workload-ab-f7a-a2/owner-timing-workload-ab.status \
  --required-context .github/task-runs/2026-08-06-rv64-v15l-owner-timing-workload-ab-f7a-a2/evidence/owner-timing-workload-ab/command-status.txt \
  --required-context .github/task-runs/2026-08-06-rv64-v15l-owner-timing-workload-ab-f7a-a2/evidence/owner-timing-workload-ab/result.json \
  --required-context .github/task-runs/2026-08-06-rv64-v15l-owner-timing-causality-f7a/evidence/optimization-research-state-owner-timing-a2.json \
  --required-context .github/task-runs/2026-08-06-rv64-v15l-owner-timing-causality-f7a/evidence/owner-timing-selector-tests.log \
  --deliverable '首行按 RV64 RTL 结论格式给出 A2 receipt 与 selector 的 PASS/GAP/inconclusive；列出 exact hash、六次事务 marker/bit-exact、守恒、前后 RTL identity、cleanup、反例、unknowns、替代假设、scope_extension_request 与 confidence_and_basis；给出 H1–H4 的证据排序和仍需区分的替代解释，但保持 hypothesis_selection_authorized=false、optimization_candidate_authorized=false、PPA UNQUALIFIED。若无 blocker，输出唯一 exact approval marker。' \
  --success-criterion '独立执行 receipt rebuild/verify 和 owner-timing+selector 定向测试，确认 A2 status PASS、全部 stage rc=0、result SHA-256 为 1a99bd6ae38d4b672c20d263834ccddc13203d377777888203b935698ce2afef、CoreMark 5380028/3183617 与 Dhrystone 10351427/4250000 不受 observer 影响、每 workload 三次 owner signature bit-exact、owner overflow/invalid 为零、148 项 production manifest 前后均为 33df2e297514d267c941546410f89f6ca934d1ea0ccfa66b915bb78e0d23a557、runtime_absent=true，并确认 selector SHA-256 51841c120668a264ddba2b8b3a89ad46f147ca9e6ba5aa669bc24c8c897fcd0b 只选择 analyze.owner-timing-hypothesis。若且仅若不存在 blocker，报告中恰好一次输出 [OWNER-TIMING-INDEPENDENT-REVIEW][APPROVE] design_id=sha256:f7a6845564f2d697fca9eac8bf9424136508a62c7fcc7851ad56c688dc2053f9 result_sha256=1a99bd6ae38d4b672c20d263834ccddc13203d377777888203b935698ce2afef selector_sha256=51841c120668a264ddba2b8b3a89ad46f147ca9e6ba5aa669bc24c8c897fcd0b；否则不得输出该 marker。' \
  --out "${contract}"
python3 -B "${tool}" validate "${contract}"
python3 -B "${tool}" render "${contract}" >"${rendered}"
sha256sum "${contract}" >"${contract_hash}"
printf '[RTL-TASK-CONTRACT][PASS] contract=%s rendered=%s\n' \
  "${contract#${repo_root}/}" "${rendered#${repo_root}/}"
