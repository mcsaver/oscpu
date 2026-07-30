#!/usr/bin/env bash
set -euo pipefail

run_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(git -C "${run_dir}" rev-parse --show-toplevel)"
tool="${repo_root}/.github/skills/prepare-rtl-task-contract/scripts/rtl_task_contract.py"
contract_rel=".github/task-runs/2026-07-27-rv64-v10c-current-design-evidence-replay/subagent-contracts/final-reviewer-v1.json"
contract="${repo_root}/${contract_rel}"
rendered="${run_dir}/subagent-contracts/final-reviewer-v1.rendered.txt"

if [[ -e "${contract}" || -e "${rendered}" ]]; then
  printf 'refusing to overwrite existing V10C final-review artifacts\n' >&2
  exit 2
fi

python3 "${tool}" create \
  --task-id rv64-v10c-current-design-evidence-final-review-v1 \
  --task-kind read-only-review \
  --goal '独立复审本地 RV64 V10C 当前设计证据回放。核对 attempt 6 从 V9R SQ retry 到 control-event index/hash verify、debt ledger 与 closed-evidence audit 的有序 PASS；核对 RTL design-id 始终为 sha256:13d868334de2a0813f91af318f25434f8e93c581adc67d0b562fcc1f6f8dc951，15 个 CLOSED 条目和 35 个 artifact hash 当前化。逐项检查 XRET lane1 expected-marker、IFU-TVAL current-source mutation anchor 与 grouped-clear static anchor 三处验证工具变更确实保持 compile-success、exact RTL assertion/FAIL、无 PASS、完整 source binding，且没有改动生产 RTL、削弱断言、减少负向版本或接受通用非零返回。核对 architecture hard gates 9/9 GREEN，同时 full-core candidate 必须保持 architecture_freeze=GAP、ppa=UNQUALIFIED、promotion_eligible=false，SERIALIZE-G1 必须保持 P1 OPEN。核对 V9P rootfs 仅为旧 design-id/config 的历史 FAIL 且 terminal-marker 为空，不得升级为当前终端事务 PASS。' \
  --allow-path .github/task-runs/2026-07-27-rv64-v10c-current-design-evidence-replay \
  --allow-path .github/task-runs/2026-07-21-rv64-v9e-xret-current-design \
  --allow-path .github/task-runs/2026-07-22-rv64-v9j-ifu-tval-current-design \
  --allow-path .github/task-runs/2026-07-22-rv64-v9l-functional-aggregate-current-design \
  --allow-path .github/task-runs/2026-07-23-rv64-v9o-control-event-current-design \
  --allow-path .github/task-runs/2026-07-23-rv64-v9p-serialize-current-design \
  --allow-path .github/task-runs/2026-07-24-rv64-v9r-sq-retry-c0-handoff \
  --allow-path npc/rv64/eval/ppa/tools/ifu_tval_evidence.py \
  --allow-path npc/rv64/eval/ppa/evidence \
  --allow-path npc/rv64/eval/ppa/arch-stable/full-core-current.json \
  --allow-path npc/rv64/design/arch/architecture-debt-ledger.json \
  --allow-path npc/rv64/design/arch/producer-holder-census.json \
  --allow-path npc/rv64/design/specs/ooo-pending-system-sequencer.md \
  --allow-path npc/rv64/design/specs/ooo-serialize-memory-owner-terminal.md \
  --allow-path npc/rv64/vsrc/control/OooPendingLane1CaptureGate.v \
  --allow-path npc/rv64/vsrc/control/OooControlPlane.v \
  --allow-path npc/rv64/vsrc/control/OooStopPendingSequencer.v \
  --allow-path npc/rv64/vsrc/control/OooPendingSystemSequencer.v \
  --allow-path npc/rv64/vsrc/frontend/OooFrontend.v \
  --allow-path npc/rv64/vsrc/writeback/OooRob.v \
  --allow-path npc/rv64/vsrc/core/NpcCoreTop.v \
  --allow-path npc/rv64/Makefile \
  --allow-path npc/rv64/testbench/Makefile \
  --allow-path npc/rv64/testbench/tests/tb_ooo_priv_system.sv \
  --allow-path npc/rv64/testbench/tests/tb_ooo_ifu_lane1_fault_owner.sv \
  --allow-path npc/rv64/testbench/tests/tb_ooo_core_top_glue.sv \
  --allow-path .github/AGENTS.md \
  --allow-path .github/instructions/rtl-agent-task-contract.instructions.md \
  --allow-read-command rg \
  --allow-read-command sed \
  --allow-read-command 'git status' \
  --allow-read-command 'git diff' \
  --allow-read-command 'git show' \
  --allow-read-command sha256sum \
  --required-context .github/AGENTS.md \
  --required-context .github/instructions/rtl-agent-task-contract.instructions.md \
  --required-context .github/task-runs/2026-07-27-rv64-v10c-current-design-evidence-replay/task-report.md \
  --required-context .github/task-runs/2026-07-27-rv64-v10c-current-design-evidence-replay/round-state.json \
  --required-context .github/task-runs/2026-07-27-rv64-v10c-current-design-evidence-replay/closed-evidence-currentness.json \
  --required-context npc/rv64/design/arch/architecture-debt-ledger.json \
  --required-context npc/rv64/eval/ppa/arch-stable/full-core-current.json \
  --deliverable '按“本地 RV64 RTL/证据对象 → 周期或 compile/config → raw TB/EDA observation → PASS/GAP 范围”输出独立终审。先列 findings（按严重度，包含真实文件名/marker/hash）；再裁决三处验证工具纠偏是否保持负向敏感度；再裁决 V10C currentness PASS 是否成立；最后单列 SERIALIZE-G1、历史 V9P、arch-stable 与 PPA 边界、未知项和最强反例。若无阻断项，结论写 APPROVED_FOR_CURRENT_SCOPE；否则写 CHANGES_REQUIRED。' \
  --success-criterion '只读复核真实本地 RTL、TB、日志、JSON 与 git diff，不运行仿真/综合/STA、不修改文件。必须确认 XRET 负向 RTL 版本编译成功、命中精确 V10A onehot marker、最终 FAIL 且无 PASS；IFU-TVAL 12/12 compile-success 和动态拒绝、当前 grouped-clear 静态绑定；attempt 6 全阶段、9/9 architecture gates、15/15 CLOSED 和 35/35 hash；candidate GAP/UNQUALIFIED/false；SERIALIZE-G1 OPEN；V9P 旧 design/simulator/config、rc=2、terminal-marker empty。不得把局部 PASS 外推为 SERIALIZE、rootfs、arch-stable 或 PPA closure；结束时显式归还 Windows→WSL 唯一工程命令 lane。' \
  --out "${contract_rel}"

python3 "${tool}" validate "${contract_rel}"
python3 "${tool}" render "${contract_rel}" | tee "${rendered}"
