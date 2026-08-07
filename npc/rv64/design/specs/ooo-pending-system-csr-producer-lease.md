# 规范：pending-system CSR ProducerId lease 与精确提交（v8k）

> 状态：contract frozen；v8k scoped RTL、独立反例复核、focused/assert/mutation、legacy 6/6、
> module aggregate 106/106、task-run、agent-system/npc-dev e2e 与 strict guard 已闭合。该规范只覆盖 dispatched pending CSR；
> 非 CSR pending 控制事件仍在 drained pre-ROB 边界执行。全核 finite-generation no-live-reuse
> 继续 RED；`promotion_eligible=false`，未运行或声明 PPA。

## 1. 目的与范围

`OooPendingSystemSequencer` 在 frontend 先捕获 SYSTEM payload，待 backend 排空后仅把 CSR 注入
lane0/ROB。旧实现从 capture 到 commit 只保存 PC/inst/type，并以 commit PC 相等授权 CSR 副作用。
本规范要求在真实 ROB allocation 沿出生 full ProducerId，随后以 Q-only lease 保持到终止，并用
完整身份授权提交。

不改变 CSR 指令语义、drain 时机、非 CSR SYSTEM 控制、ROB allocation 算法或 redirect 优先级。

## 2. 状态与接口

`ProducerId={generation,rob_idx}`，宽度为 `ROB_INDEX_W+PRODUCER_GEN_W`。

新增状态：

| 状态 | 出生 | 保持 | 死亡 |
|---|---|---|---|
| `producer_valid_q` | 合法 pending CSR dispatch fire | dispatched pending CSR 等待提交 | reset/backend flush/exact pending commit |
| `producer_id_q` | 同沿锁存 backend dispatch0 full P | lease live 时不变 | death 后清零仅为可审计性 |

pre-ROB capture 必须保持 `producer_valid=0`。sequencer 对外 lease valid 必须原样导出 raw
`producer_valid_q`；`valid_q && csr_q && dispatched_q` 是 assertion/commit coherence，不得相与到
birth fence，否则部分 metadata 清除会打开 ProducerId 复用窗口。

## 3. 提交能力

pending commit 需要：pending valid、CSR、dispatched、lease valid、commit0 是无异常 CSR、commit0
full P 与 held P 相等、commit0 PC 与 held PC 相等。PC 是附加 coherence，不是身份主键。

raw lease 或 active dispatched logical claim 任一存在时，普通 queue-head CSR 回退必须关闭。因为
pending CSR 注入前 backend 已排空，此时 ROB 不允许另有合法 commit owner；identity mismatch 或
部分 metadata 清除必须两路静默。pending 尚未 dispatch 且 raw lease=0 时仍允许更老的 queue-head
CSR 提交，以保留同窗口 head0 CSR + younger lane1 pending SYSTEM 的既有中间态。

## 4. birth fence 与组合边界

pending raw lease 解码成 one-hot ProducerId live mask，并入 memory/MulDiv/CLMUL/FP external holder
mask。该 mask 只读 raw sequencer Q，禁止读取 metadata、ready/fire/commit/authorization。dispatch 出生沿看到旧 lease=0；
终止沿看到旧 lease=1，因此同沿不允许复用，下一拍释放。

backend dispatch full P 与 ROB head full P 逐层只作同名 observation transport，不进入 ready 或 credit。

## 5. 恢复、覆盖与优先级

- reset 或与 ROB 同沿生效的 backend global flush 清 payload 和 live lease。
- ordinary pending clear 只清 pre-ROB 状态；post-dispatch live lease 只有 exact pending commit 可清。
- empty 定义为 `!valid_q && !producer_valid_q`；任何 non-empty recapture 都必须被生产逻辑拒绝并报告。
- `clear_dispatched` 只允许无 lease 的 orphan cleanup；live lease 时不得切断 ROB/P 的归属。
- refresh CSR read data 只允许 pre-dispatch；lease live 后 payload 保持。
- 优先级：reset/backend-global-flush > exact live death > pre-ROB explicit clear > empty capture >
  legal dispatch birth > non-live clear-dispatched > pre-dispatch refresh > hold。
- system CSR dispatch valid/fire 必须被 reset、core-local backend flush 与无反馈 ordinary-clear
  witness 门控；同拍取消时 ROB 不得 enqueue，避免 orphan P。完整 `pending_system_clear` 含
  backend-ready 派生的 direct frontend flush，禁止直接反喂 admission；pending-system owner 已令
  `can_run=0`，二者互斥由 assertion 独立守护，从而同时避免 orphan P 与组合环。
  `pending_jump_resolve_ready` 等 level 信号必须与真实 clear outcome 精确相与，裸 ready 不得取得
  cancel capability，避免 pre-ROB pending CSR 永久自锁。

### 5.1 admission-cancel 组合边界

`OooPendingSystemAdmissionCancelGate` 的两个输出承担不同职责，禁止再次合并成同一反馈锥：

| 输出/组合锥 | 允许输入 | 禁止用途 |
|---|---|---|
| `system_csr_admission_clear_o`（完整 ordinary-clear 观测） | 下列无反馈见证，以及兼容观测口 `pending_branch_commit_resolve_i` / `pending_branch_match_clear_i` | 不得直接驱动 `system_csr_dispatch_cancel_o` |
| `system_csr_dispatch_cancel_o`（ROB admission 权限） | reset、core-local flush、memory trap、branch-spec resolve、untracked branch resolve、已由 outcome 限定的 pending-jump clear、pending/head0 CSR commit | 不得读取 backend ready、direct fire、`direct_frontend_flush`，也不得读取任何由它们后置屏蔽得到的 branch terminal |

当前 ROB-walk 产品拓扑已把 `pending_branch_q` 与 `pending_branch_dispatched_q`硬连为 0；两个
`pending_branch_*clear` 端口仅为兼容观测。即使未来重新启用 pending-branch owner，也只能新增一个
不读取 ready/direct-fire 的 pre-priority cancel witness，不能把 post-priority terminal 重新接回
system CSR valid。组合方程固定为：

```text
feedback_free_clear = trap | branch_spec_resolve | branch_untracked |
                      qualified_jump_clear | pending_csr_commit | head0_csr_commit
full_observed_clear = feedback_free_clear | pending_branch_commit_resolve |
                      pending_branch_match_clear
dispatch_cancel     = reset | core_local_flush | feedback_free_clear
```

因此，单独翻转任一 pending-branch 兼容观测口可以改变完整 clear 观测，但不得改变 dispatch cancel；
其余每个真实无反馈 clear witness 必须同拍取消 admission。该区分由 standalone TB 正向矩阵和把
`full_observed_clear` 重新接回 cancel 的 compile-success 负向版本共同守护。

## 6. 不变量

1. lease valid 蕴含 pending valid/CSR/dispatched，且 P 在生命周期内稳定。
2. dispatch birth 蕴含 edge-old pre-ROB CSR；锁存 P 低位等于同次 ROB index。
3. pending commit 蕴含 full P exact match 与 PC match，且与 head0 commit 互斥；raw lease 或 logical
   claim 任一存在时 head0 commit 恒 0。
4. active claim mismatch 时所有 CSR 架构副作用静默。
5. non-empty 不接受 recapture；live lease 不接受 ordinary clear 或 orphan clear-dispatched。
6. live mask 直接读 raw Q lease，无 holder→ready 组合反馈。
7. lease fall 必有 exact commit/reset/backend-global-flush death witness；system enqueue 与 lease birth
   同沿，可达的无反馈 clear/flush witness 同拍不得 enqueue，direct frontend flush 与 pending-system
   owner 必须互斥。

## 7. 验证

- standalone sequencer：出生/保持/终止、nonzero generation、recapture/clear-dispatched 违约。
- CSR request mux：exact、stale generation、PC mismatch、head0 pre-dispatch coexist 与 active-claim
  fallback seal。
- backend/top：dispatch P 和 commit P transport、live mask birth fence、system dispatch fire coherence。
- OOO_ASSERT negative 与 compile-success mutation 覆盖所有承重 fence。
- legacy ProducerId slices、CSR/pending focused、fresh module aggregate、static/contract guard。

## 8. 声明边界

本规范通过后只允许称 dispatched pending CSR scoped GREEN；其它 holder census、generation 整圈回绕、
全核 architecture hard gate、Linux、物理实现和 PPA 仍需独立证据。
