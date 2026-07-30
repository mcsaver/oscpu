#!/usr/bin/env bash
set -euo pipefail

run_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(git -C "${run_dir}" rev-parse --show-toplevel)"
tool="${repo_root}/.github/skills/prepare-rtl-task-contract/scripts/rtl_task_contract.py"
contract="${run_dir}/subagent-contracts/v11h-load-queue-producer-pre-review.json"
rendered="${run_dir}/subagent-contracts/v11h-load-queue-producer-pre-review.rendered.txt"

mkdir -p "$(dirname "${contract}")"

python3 "${tool}" create \
  --task-id v11h-load-queue-producer-pre-review \
  --task-kind read-only-review \
  --goal '独立复核本地 RV64 `OooLoadQueue` 的 `producer_id_q` 在双 dispatch allocation、issue/launch、双 final-PA query、allow/replay、response/completion、normal/killed terminal、ROB release、selective/global recovery、killed tombstone drain 与同拍优先级中的 full-ProducerId holder 生命周期；判决 H1=production RTL 合同正确但缺 source-bound raw-Q 语义证据、H2=存在合法接口可达的 production RTL 合同违例、H3=V8V 既有 9 个变体已经充分闭合当前 semantic ledger 单元。' \
  --allow-path npc/rv64/vsrc/memory/OooLoadQueue.v \
  --allow-path npc/rv64/testbench/tests/tb_ooo_load_queue.sv \
  --allow-path npc/rv64/design/specs/ooo-load-queue.md \
  --allow-path npc/rv64/design/specs/ooo-global-producer-no-live-reuse.md \
  --allow-path npc/rv64/design/arch/producer-holder-census.json \
  --allow-path npc/rv64/design/arch/producer-holder-semantic-coverage-policy.json \
  --allow-path npc/rv64/eval/ppa/tools/producer_holder_semantic_coverage.py \
  --allow-path npc/rv64/eval/ppa/tests/test_producer_holder_semantic_coverage.py \
  --allow-path .github/task-runs/2026-07-21-rv64-v8v-memory-ordering/run-lq-mutations.py \
  --allow-path .github/task-runs/2026-07-21-rv64-v8v-memory-ordering/mutation-results.json \
  --allow-path .github/task-runs/2026-07-21-rv64-v8v-memory-ordering/evidence/final-run/lq/logs/tb_ooo_load_queue.log \
  --allow-path .github/task-runs/2026-07-30-rv64-v11g-store-queue-holder-semantic-coverage/pre-review-result.md \
  --allow-path .github/task-runs/2026-07-30-rv64-v11g-store-queue-holder-semantic-coverage/run-store-queue-holder-focused.sh \
  --allow-path npc/rv64/eval/ppa/tools/store_queue_holder_semantic_evidence.py \
  --allow-path npc/rv64/eval/ppa/tests/test_store_queue_holder_semantic_evidence.py \
  --allow-path .github/task-runs/2026-07-30-rv64-v11g-store-queue-holder-semantic-coverage/evidence/semantic-coverage-ledger.json \
  --allow-read-command rg \
  --allow-read-command sed \
  --allow-read-command git\ status \
  --allow-read-command git\ diff \
  --allow-read-command sha256sum \
  --required-context .github/AGENTS.md \
  --required-context .github/instructions/rtl-agent-task-contract.instructions.md \
  --required-context npc/rv64/design/specs/ooo-load-queue.md \
  --required-context npc/rv64/design/specs/ooo-global-producer-no-live-reuse.md \
  --deliverable '按 edge-old/edge-new 周期链审查 `valid_q`/`producer_id_q` 的创建、持有、精确 CAM 命中、recovery 转换、normal/killed terminal 与 release death；判决 H1/H2/H3，列出合法接口反例或其缺失依据，并给出 GEN_W=1/4、OOO_ASSERT on/off 的最小正向矩阵及断言关闭时仍应由刺激侧独立 raw-Q oracle 拒绝的 compile-success RTL 变体集合。' \
  --success-criterion '明确 production `OooLoadQueue.v` 是否需要修改；每项结论绑定真实 signal、周期优先级、完整 ProducerId 与现有/缺失 TB oracle。不得从 DUT snoop/mask 输出反推 expected raw-Q 状态，不得把带断言的 V8V FAIL 当作 assertion-off 独立 oracle，不得把 `load-queue-producers` 的局部闭合外推为全局 no-live-reuse 或 architecture gate PASS。' \
  --out "${contract}"

python3 "${tool}" validate "${contract}"
python3 "${tool}" render "${contract}" > "${rendered}"
sha256sum "${contract}" "${rendered}"
