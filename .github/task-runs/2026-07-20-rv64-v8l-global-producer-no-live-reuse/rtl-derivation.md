# RV64 v8l global ProducerId no-live-reuse RTL derivation

## 1. 语义拆解

v8e-v8k 已分别建立 ROB ProducerId 真源、整数 completion 授权、memory token lease、长延迟 lease、
FP completion-owner lease、branch resolve full-PID 授权和 pending CSR lease。剩余缺口不是某个 WB
比较式，而是完整 lease 证明面的拓扑缺口：`OooIntBackend.producer_live_mask_w` 尚未包含整数 IQ；
EX0/EX1、memory reservation、branch resolve 等 packed/direct Q holder也没有统一的显式 contributor。

有限 generation 的安全命题要求的是 holder 生命周期与新 birth 的互斥，而不是 generation 位数足够
大。只增加位宽会把反例推迟；只在 completion 端 exact-match会静默丢 stale effect，但仍允许同 P
在两个 incarnation 之间发生 ABA。修复点必须在 ROB dispatch birth 之前。

## 2. 现状 owner、根因与数据流

### owner/source-of-truth

- generation 真源：`OooRob.slot_generation_q`；
- birth owner：`OooDispatchBackend` 的 lane0/lane1真实 fire；
- resident owners：IntIQ、FP链、EX、branch、memory reservation/tracker/SQ/MIQ/bridge、MulDiv、CLMUL、
  pending CSR；
- side-effect authorities：ROB exact-open query、same-edge claim、memory token tuple/head、pending CSR
  exact P+PC；
- death witnesses：各 owner既有 consume/terminal/kill/flush/commit。

### root cause

当前 dispatch 只查：

```text
memory_tracker | muldiv | clmul | fp | pending_csr
```

因此完整 holder census与实际 birth fence不是同一个可审计对象；新增 holder也可能只传播 P而忘记
加入 fence。旧 v8c checker又只到 file/module lexical粒度，无法检测 packed stage、字段级 direct Q
或 token-indirect owner。

IntIQ source state 不是遗漏的 P 域：`src1_preg_q/src2_preg_q/fp_st_preg_q` 是
physical-register tag，配套 state 只有 sticky-ready；本核 wakeup 不以 ProducerId 匹配。IntIQ 唯一
full-P 字段是 owner `producer_id_q`。任何未来 full-P source dependency 会改变 static discovered set
并使 gate 先 RED。

## 3. 状态机与方程

对每个 direct holder `H={valid_q,pid_q}`：

```text
H_mask[P] = OR_k(H[k].valid_q && H[k].pid_q == P)

complete_mask = int_iq_mask
              | mem_res_mask | ex0_mask | ex1_mask | branch_mask
              | memory_tracker_mask
              | muldiv_mask | clmul_mask | fp_mask | pending_csr_mask

dispatch_lane_fire(P) = candidate_valid
                      && resource_ready
                      && !complete_mask[P]
                      && !dispatch_freeze
```

所有 `H_mask` 只读 Q。若 `death_H(N)` 在 N 的上升沿发生，N 沿之前组合观察仍是
`H.valid_q=1`，所以 N 沿不能 birth同 P；N+1 组合观察才允许。若 `birth_H(N)` 在 N 沿发生，N沿前
mask为0，不会自阻断；N+1开始持有。

### indirect memory holder

```text
token_live(t) -> tracker_pid(t)=P -> memory_tracker_mask[P]=1
SQ_valid(P) -> int_iq_mask[P] || memory_tracker_mask[P] || transient_mask[P]
```

SQ 在 dispatch edge与 IntIQ同时 birth；memory issue edge前 IntIQ仍 live，edge后 tracker与mem-res同时
birth；随后 MIQ/buffer/bridge/SQ只转移同一 token，tracker death直到最后 exact terminal/release。
逐-entry/逐-token assertion把这条手工时序推导变成运行时硬门。

memory admission 现有方程还给出原子性：`capture=capture_candidate&&tracker_alloc_ready`，IQ memory
ready 对 current P 读取同一个 `tracker_alloc_ready`；因此 alloc backpressure 时源不 pop、mem-res 不
capture、SQ 不 bind。v8l 把该同源关系和 `indirect_live->tracker_live/stable P/no token reuse` 升级为
显式 assertion 与 mutation，而不只引用代码形状。

## 4. RTL 结构方案

1. `OooIntIssueQueue` 增加与 FP IQ同形的 Q-only PID mask输出；循环只读 `valid_q/producer_id_q`。
2. `OooDispatchBackend` 接收既有 external mask，本地 OR IntIQ mask，导出 complete mask；三处 ready
   与 lane fire assertions统一读取 complete mask。
3. `OooIntBackend` 把 mem-res、EX0、EX1、branch registered stage解码为 transient mask，再与既有
   memory/longop/FP/pending mask送入 DispatchBackend；`producer_live_mask_w`改为其 complete输出。
4. 增加 direct/indirect holder coverage assertions和 handoff assertions；不改变 completion/commit/
   launch authority。
5. 增加 production static checker + manifest，固定字段/packed/token分类和完整 union anchors；接入
   Make gate与 npc-dev e2e静态节点。
6. TB 增加独立 reference live scan，直接读取 raw valid/P 字段和 token table，不读取 production
   mask；production gate 与 reference assertion 不共享同一个 union 真源。

## 5. 端口、协议、复位、异常逐项检查

### 端口与宽度

- 所有新 mask端口宽度均为 `(1 << PRODUCER_ID_W)`；不新增 raw-index身份端口。
- 默认与 `PRODUCER_GEN_W=1` 两种 elaboration都必须编译；testbench移除任何要求 generation至少2位
  的 repeat表达式。

### 时序与无环

- IntIQ mask是 resident数组 Q的组合投影；transient mask是 stage Q的组合投影；tracker/pending/
  longop/FP mask已是 Q-only。
- dispatch candidate只索引 mask，mask生成不读 candidate/ready/fire，因此不会形成 ready闭环。
- wide OR/equality可能影响 timing，属于后续架构稳定后的诊断/PPA优化对象；本轮不以未测 timing
  宣称收益。

ROB candidate 使用 edge-old `slot_generation_q[index]+1`，且 ROB 明确不借用同拍 commit 空位；fire
时写入的 generation 就是 exported candidate 的高位。collision gate、actual allocation 和
downstream capture 必须连接该同一个 exported P，避免 guard P/birth P 分叉。

### reset/flush/recovery

- 新 mask没有独立状态，随既有 holder valid清零；dirty payload在 valid=0时不贡献bit。
- selective recovery仍按原年龄律更新 holder；dispatch freeze与 edge-old mask双重阻断恢复沿 birth。

### 异常与 stale

- 新 mask只阻断 birth，不把 stale packet变成合法 completion；所有既有 exact-open/token tuple/
  same-edge claim/PC coherence继续承重。
- duplicate contributor只产生同一bit，不增加权限；coherence assertion继续捕获异常分叉。

## 6. 反例设计

1. resident IntIQ P非零 generation，层级构造 ROB候选同 P；若 dispatch仍只读 external mask则误 fire。
2. 同一 resident在 issue/pop edge作为最后 holder；若 mask改读 next-state，death edge candidate提前 fire。
3. `GEN_W=1` 真实 allocate/WB/commit推进31个中间 transaction，使 slot0 candidate回到 held P；若
   lookup只用 raw index/错误 generation或无 lease则误 birth。
4. 分别删除 transient mask的 mem-res/EX0/EX1/branch contributor；focused holder probes必须看到对应
   complete bit缺失并失败。
5. 新增未登记 `producer_id_q` 或删除 packed/token anchor；static census必须 fail closed。
6. 允许 memory IQ 在 tracker alloc not-ready 时 pop、允许 downstream 在 alloc 失败时 capture，或
   允许 live token 被重分配；原子 handoff/reference assertion 必须击杀。

## 7. 声明边界

通过上述 focused、mutation、legacy与 static evidence后，只发布当前 production RTL的字段级 census
与有限 generation no-live-reuse scoped GREEN。完整 architecture inventory、full workload、Linux、
综合/STA/power和 Pareto仍由各自硬门决定；本切片不越级。
