#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
run_rel=".github/task-runs/2026-08-07-rv64-v15s-f784-named-timing-path-a1"
review_version="${V15S_REVIEW_VERSION:-v3}"
contract_rel="${run_rel}/subagent-contracts/v15s-owner-any-live-material-review-${review_version}.json"

cd "${repo_root}"

python3 .github/skills/prepare-rtl-task-contract/scripts/rtl_task_contract.py create \
  --task-id "v15s-owner-any-live-material-review-${review_version}" \
  --task-kind read-only-review \
  --goal '复核 OooIntBackend.mem_idle_o 的 owner-set emptiness 归约、OooMemOwnerTracker 的计数位宽与现有边界覆盖，并判断 e7da 是否可作为下一轮 RV64 时序工程候选保留。' \
  --allow-path npc/rv64/vsrc/execute/OooIntBackend.v \
  --allow-path npc/rv64/vsrc/memory/OooMemOwnerTracker.v \
  --allow-path npc/rv64/testbench/tests/tb_ooo_mem_owner_tracker.sv \
  --allow-path npc/rv64/design/specs/ooo-serialize-memory-owner-terminal.md \
  --allow-path "${run_rel}/evidence/owner-any-live-validation-v1" \
  --allow-path "${run_rel}/evidence/ppa-owner-any-live-e7da-a1" \
  --allow-path .github/task-runs/2026-08-07-rv64-v15s-owner-any-live-e7da-a1/evidence \
  --self-contained-no-tools \
  --supplied-material 'OooMemOwnerTracker 位于 npc/rv64/vsrc/memory/OooMemOwnerTracker.v；默认 TOKEN_COUNT=32、TOKEN_W=5、COUNT_W=6，PARAM_SHAPE_VALID 要求 (1<<COUNT_W)>TOKEN_COUNT，live_mask_o=live_q，live_count_o 是同一 live_q 的精确组合 popcount。' \
  --supplied-material 'OooIntBackend 中 mem_owner_live_mask_w 为 32 bit、mem_owner_live_count_w 为 6 bit、v15s_mem_owner_any_live_w=|mem_owner_live_mask_w；mem_idle_o 使用 !v15s_mem_owner_any_live_w，计数仍供守恒与观测，OOO_ASSERT 用 case-inequality 检查 any-live 与 count!=0。' \
  --supplied-material 'tb_ooo_mem_owner_tracker 以 TOKEN_COUNT=4、COUNT_W=3 运行独立 live-mask/count 模型，覆盖空集合、逐次 birth/death、双分配、exact free、bulk release 与 4-token full tracker；现有冻结证据没有单独的 production 32-token all-live 动态用例。' \
  --supplied-material '冻结 f784 5ns Top40 为 1 类 launch、40 个 endpoint；38 个 jalr_prefetch_hit_available、2 个 redirect_valid，40/40 均经过 free0_ready_o 相关 owner cone、mem_owner_live_count_w、mem_idle_o、ROB control_event_pregrant_w 与 fetch outstanding 状态。' \
  --supplied-material '定向验证状态为 PASS：manifest、OOO_ASSERT off/on、compile-success mutation 与 cleanup 全部 rc=0；把 any-live 常量化为 0 后，HIST-QH younger-store oracle 以 mem_idle got=1 expected=0 检出；生产 RTL SHA 前后不变。' \
  --supplied-material '同一 5ns Liberty/config 的 f784→e7da mapped 对比：WNS -17.869169235→-17.592411041ns，TNS -488025.46875→-468716.46875ns，area 2181526.48→2181644.08，cells 929441→929222，loops 均为 0；40/40 路径仍违例，power 仅 fixed-toggle relative-only。' \
  --supplied-material 'e7da L0/L1 为 PASS：module 113/113、official 177/177、AM 61/61、DiffTest mismatch=0、CoreMark 10 iterations CRC 0xfcaf GOOD TRAP、Dhrystone 10000 runs GOOD TRAP、11/11 schema-valid evidence mutations rejected；compiled intermediates retained=0。' \
  --supplied-material '边界：e7da 仅为可回退 engineering candidate，未满足 5ns hard gate，不得声明 PPA qualified、canonical、Pareto、ARCH_STABLE 或 release；本轮未运行 L2/L3，Ubuntu 始终是用户显式请求才运行的可选层，不能列为本候选保留条件。' \
  --deliverable '给出二值 RTL 等价性、owner/holder 合同、32-token 位宽与覆盖边界、STA 改善和剩余 GAP 的独立限定材料复核，并明确是否必须补测试才能保留 engineering candidate。' \
  --success-criterion '首行按 RV64 RTL 结论格式给出 PASS/GAP；区分候选保留与 5ns/signoff，指出现有 4-token full coverage 能否结合参数约束支撑 32-token二值等价，保留 unknowns、替代假设、scope_extension_request 与 confidence_and_basis。' \
  --out "${contract_rel}"

python3 .github/skills/prepare-rtl-task-contract/scripts/rtl_task_contract.py validate "${contract_rel}"
python3 .github/skills/prepare-rtl-task-contract/scripts/rtl_task_contract.py render "${contract_rel}"
