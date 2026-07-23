# v8k pending-system/CSR holder census delta

## 边界

- capture source：frontend head0/lane1 的 SYSTEM 分类；此时尚未入 ROB。
- birth source：`system_csr_dispatch_fire` 对应的 backend lane0 ROB allocation。
- stateful holder：`OooPendingSystemSequencer` 的 pending payload 与新增 full ProducerId lease。
- co-holder：ROB slot；提交观察身份为 ROB head full ProducerId。
- authority sink：pending CSR CsrFile write、SATP/serial boundary、pending clear、redirect/retirement。
- birth fence sink：`OooIntBackend.producer_live_mask_w`。

## v8k 前现状风险

| holder/capability | 当前身份 | 当前资格 | 风险 |
|---|---|---|---|
| pre-ROB pending SYSTEM | PC/inst/type | capture/stop/drain | 合理地没有 P；不得伪造 |
| dispatched pending CSR | PC/inst + dispatched bit | PC 等于 commit0 PC | 同 PC 或 raw index 重用可误授权；无 generation |
| ROB commit head | full ProducerId 已存在但未导出控制面 | core commit valid | 控制面无法 exact compare |
| pending external live set | 未登记 | 无 | holder 若残留，generation birth fence 不可见 |
| head0 fallback | `!pending_system_csr_commit` | queue-head CSR | exact-match 失败会回退成 head0 commit，破坏 fail-closed |

## v8k 目标状态

- pre-ROB pending 保持无 P；只在真实 CSR dispatch fire 锁存该次 full P。
- sequencer 在 dispatch→clear 全生命周期持有 Q-only P，并把 lease 并入全局 external live mask。
- pending commit 需要 `claim_active && producer_valid && commit_pid==held_pid && pc_match`。
- `claim_active` 时 head0 回退无条件封口；mismatch 两路均静默并报错。
- live holder 拒绝 recapture 与 orphan clear-dispatched，避免附加 P 与 ROB 事务脱钩。

## v8k 实现后状态

- `producer_valid_q/producer_id_q` 仅在真实 pending CSR lane0 ROB enqueue 沿出生，保持到 exact commit、
  reset 或与 ROB 同沿的 backend global flush；普通 clear 与 `clear_dispatched` 不能切断 live lease。
- raw Q lease 直接形成 pending external live mask，并逐层并入 `OooIntBackend.producer_live_mask_w`；
  dispatch birth 与 death edge 都按 edge-old live fence 阻止同名 ProducerId 复用。
- `OooCsrAccessRequestMux` 以 full P exact match + PC coherence 授权 pending CSR；raw lease 或 logical
  claim 任一存在即封住 queue-head fallback，mismatch 两路静默。
- admission cancel 只读取反馈无关的 reset/core-local flush/ordinary-clear witnesses；jump resolve 必须
  `ready && outcome`，裸 ready 不具备取消能力。pending-system owner 与 direct frontend flush 的结构互斥
  由 ControlPlane assertion 约束。
- focused release/assert、两个 expected-fail assertion probes、10 个 compile-success semantic mutation、
  legacy v8d-v8j 6/6、module aggregate 106/106 均通过。full lint 仍为继承 rc=2/115 warnings，normalized
  SHA 与 v8j 基线相同；真实 architecture inventory 仍 `OVERALL: RED`。

## 仍不覆盖

- 非 CSR pending 控制事件没有 ROB ProducerId，本切片不改变其执行模型。
- 其余未枚举 holder、全核 last-reference 证明与 generation 整圈回绕形式证明。
- Linux/full-system、综合/STA/PPA promotion。
