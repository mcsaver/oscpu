#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
run_rel=".github/task-runs/2026-08-07-rv64-v15s-f784-named-timing-path-a1"
contract_rel="${run_rel}/subagent-contracts/v15s-owner-any-live-material-review-v2.json"

cd "${repo_root}"

python3 .github/skills/prepare-rtl-task-contract/scripts/rtl_task_contract.py create \
  --task-id v15s-owner-any-live-material-review-v2 \
  --task-kind read-only-review \
  --goal '复核 OooIntBackend 的 mem_idle_o 是否可由 OooMemOwnerTracker.live_mask_o 的归约或替代 live_count_o==0，并判断 e7da 设计点是否可作为下一轮 RV64 时序候选保留。' \
  --allow-path npc/rv64/vsrc/execute/OooIntBackend.v \
  --allow-path npc/rv64/vsrc/execute/OooMemOwnerTracker.v \
  --allow-path npc/rv64/design/specs/ooo-serialize-memory-owner-terminal.md \
  --allow-path "${run_rel}/evidence/owner-any-live-validation-v1" \
  --allow-path "${run_rel}/evidence/ppa-owner-any-live-e7da-a1" \
  --allow-path .github/task-runs/2026-08-07-rv64-v15s-owner-any-live-e7da-a1/evidence \
  --self-contained-no-tools \
  --supplied-material 'OooMemOwnerTracker 的 32-bit live_q 是 owner token 的唯一 Q 状态；live_mask_o=live_q，live_count_o 是同一 live_q 的组合 popcount，当前修改没有改变分配、释放、kill、flush 或 terminal transaction。' \
  --supplied-material 'OooIntBackend 中 v15s_mem_owner_any_live_w=|mem_owner_live_mask_w，mem_idle_o 使用 !v15s_mem_owner_any_live_w；mem_owner_live_count_w 保留给守恒检查与观测，OOO_ASSERT 每拍检查 v15s_mem_owner_any_live_w 等价于 mem_owner_live_count_w!=0。' \
  --supplied-material '冻结 f784 5ns Top40 的 launch 仅 1 类、endpoint 40 个；38 个 jalr_prefetch_hit_available、2 个 redirect_valid，40/40 均经过 free0_ready_o 相关 owner cone、mem_owner_live_count_w、mem_idle_o、ROB control_event_pregrant_w 与 fetch outstanding 状态。' \
  --supplied-material '定向验证状态为 PASS：manifest、OOO_ASSERT off/on、compile-success mutation 与 cleanup 全部 rc=0；负向变体把 any-live 常量化为 0 后，由 HIST-QH younger-store oracle 以 mem_idle got=1 expected=0 检出，生产 RTL SHA 前后不变。' \
  --supplied-material '同一 5ns Liberty/config 的 f784→e7da mapped 对比：WNS -17.869169235→-17.592411041ns，TNS -488025.46875→-468716.46875ns，area 2181526.48→2181644.08，cells 929441→929222，loops 均为 0；40/40 路径仍违例，power 仅 fixed-toggle relative-only。' \
  --supplied-material 'e7da 的 L0/L1 证据为 PASS：module 113/113、official 177/177、AM 61/61、DiffTest mismatch=0、CoreMark 10 iterations CRC 0xfcaf GOOD TRAP、Dhrystone 10000 runs GOOD TRAP、11/11 schema-valid evidence mutations rejected；compiled intermediates retained=0。' \
  --supplied-material '结论边界：e7da 仅是可回退 engineering candidate；未满足 5ns timing hard gate，不得声明 PPA qualified、canonical、Pareto、ARCH_STABLE 或 release；本轮未运行 L2/L3/Ubuntu。' \
  --deliverable '给出 RTL 等价性、owner/holder 合同、定向反例、STA 改善与剩余 GAP 的独立限定材料复核，并列出明确的保留或回滚条件。' \
  --success-criterion '首行按 RV64 RTL 结论格式给出 PASS/GAP；明确判断归约或与 popcount 非零是否同拍等价，不把 STA 采集 PASS 误写为 5ns timing PASS，并保留 unknowns、替代假设、scope_extension_request 与 confidence_and_basis。' \
  --out "${contract_rel}"

python3 .github/skills/prepare-rtl-task-contract/scripts/rtl_task_contract.py validate "${contract_rel}"
python3 .github/skills/prepare-rtl-task-contract/scripts/rtl_task_contract.py render "${contract_rel}"
