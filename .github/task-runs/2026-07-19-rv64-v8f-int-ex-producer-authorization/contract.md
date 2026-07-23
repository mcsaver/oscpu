# RV64 v8f integer EX ProducerId formal-completion 合同

> Post-review notice: sections 2/3/5 中涉及 WB credit、ready 与 stale
> same-cycle replacement 的陈述由 `contract-amendment-v8f1.md` 取代。
> 原文保留，用于审计独立复核所发现并纠正的 pre-RTL 假设。

## 1. 设计状态与完成定义

- `design_state`: `intermediate_checkpoint`
- `parent`: v8e ProducerId allocation source；最终 runner 以源清单 SHA-256 绑定实际父状态。
- `scope`: 只闭合 integer IQ → issue → EX0/EX1 formal-completion 路径；EX0 同时包含
  memory reservation 的本地终结（SQ forward / failed SC / precise misalign）。
- `complete_when`: 该范围内每个 stateful holder 只保存完整 `{generation,rob_idx}`，legacy
  raw index 均由低位派生；ROB 以当前槽 `valid && !done && exact ProducerId` 形成唯一
  completion-open 事实；EX formal completion 和 fixed-GPR early wake 的所有下游副作用只认
  这个事实；wrong-generation 载体被消费但副作用为零，current-generation 正控仍完成。
- `activation_boundary`: 本刀直接激活上述 scoped gate，不把 carrier-only shadow 当成果；但它
  不是 Domain-A 或全核 identity closure。

状态账本固定为：

```text
INT_IQ_EX_PRODUCER_CARRIER=SCOPED_GREEN
INT_EX_FORMAL_COMPLETION_AUTH=SCOPED_GREEN
INT_FIXED_EARLY_WAKE_AUTH=SCOPED_GREEN
ASYNC_MEMORY_MULDIV_CLMUL_FP_BRANCH_AUTH=RED
GLOBAL_NO_LIVE_REUSE=RED
GENERATION_SAFE_FULL_IDENTITY=RED
```

## 2. 接口合同

### 2.1 ProducerId 单一 holder

```text
OooRob.dispatch{0,1}_producer_id
  -> OooIntIssueQueue.producer_id_q[entry]
  -> issue{0,1}_producer_id
  -> EX{0,1} PipeStage payload
  -> OooRob completion-open query
  -> effective_ex{0,1}_completion
```

memory reservation 的本地 EX0 分支为：

```text
issue0_producer_id
  -> mem_issue_res_producer_id_q
  -> EX0 PipeStage payload
  -> same completion-open query
```

- holder 不并排保存 raw `rob_idx` 与 full ID。IQ、memory reservation、EX stage 仅保存 full ID；
  所有数组寻址和环形年龄继续取 `producer_id[ROB_INDEX_W-1:0]`。
- ROB query 从 PID 低位选择 slot，并比较完整 `{slot_generation_q[idx],idx}`；completion query
  还要求 slot `valid && !done`。`rst || flush_i` 当拍 fail closed。
- query 只读 ROB Q，不读取 WB、ready 或下游副作用，不得形成 completion→ready 回边。

### 2.2 副作用共同有效位

```text
ex_pre_auth_valid = ex_stage_valid && !selective_kill_now
ex_effective_valid = ex_pre_auth_valid && rob_completion_open_exact
```

同一个 `ex_effective_valid` 必须在 WB source arbitration 之前控制：

1. shared formal WB valid 与 ROB done；
2. GPR PRF write；
3. BusyTable clear / integer IQ formal wake；
4. FP IQ 的 integer sticky wake；
5. registered EX forwarding；
6. public execute completion pulse；
7. WB slot credit/alternate-source arbitration。

fixed-GPR issue-time early wake 使用独立的 `ROB current exact` query：raw issue fire 可以执行，
但 PID 非当前时不得更新任何 IQ sticky-ready。该 query 不要求 `!done`，因为它发生在完成前。

## 3. 六类时序与状态合同

| 类别 | v8f 冻结合同 |
|---|---|
| 握手 | dispatch/issue/WB 的既有 valid-ready 公式不变；PID 只随同一 fire 被接受。query 无握手、无 transport backpressure。 |
| stall/backpressure | IQ compaction/hold、memory reservation hold 与 EX stage hold 必须连同 full PID 原子保持；PID 不进入 select/ready 锥。 |
| flush/kill/recovery | reset/flush 清 holder valid；payload 可留脏。IQ kill survivor 保持 PID，年轻项失效。v8d strict-younger kill 先于 exact completion；older/equal survivor 仍可通过。 |
| 异常序 | EX0/EX1 的 normal/exception formal completion 使用同一 exact gate；不改变 ROB Q-only commit 与 exception-lane0-only。 |
| 访存序 | 只覆盖 EX0 本地 memory terminal 的 formal completion；request、MIQ、SQ drain、AXI response 等异步路径仍是 raw-index/owner-token 域并保持 RED。 |
| 单一真源 | generation 只由 OooRob allocation source 产生；其余模块只能复制 full PID 或从低位派生 raw index，禁止重新读取当前 ROB generation 拼接“新身份”。 |

## 4. 有限位宽边界

本刀没有 `lease_live`、last-reference 守恒或 allocation collision fence。4-bit generation 回绕后，
旧引用可能再次与当前 PID 相等，因此 scoped exact gate 不能升级为 generation-safe full identity。
后续完整点必须把 `current/open target` 与 `lease_live` 分离，并用 edge-old registered lease state
阻止同 ID 再分配；禁止 same-edge clear→reuse，也禁止把 holder 组合比较树直接接回 ready。

## 5. 机器退出条件

1. ROB current/open query：current ID 通过；wrong generation、非当前 slot、done、flush 均拒绝。
2. IQ 双 lane dispatch、compaction、stall、kill survivor 后 full PID 不变；raw output 恒等于低位。
3. EX0/EX1 正常 current-ID completion 保持原时序与数据。
4. raw EX stage valid + wrong-generation PID 时，formal WB、PRF、Busy/IQ、FP-IQ、ROB、forward、
   public completion 全为零；沿后 raw stage 被消费，不能永久占 WB 优先级。
5. EX0 local-memory terminal 使用 reservation 保存的 PID；capture/hold/kill/consume 生命周期有断言。
6. wrong-generation fixed-GPR issue 不产生 early sticky wake；current-ID 正控仍在 N 沿粘住、N+1 发射。
7. lane swap、generation 截断、PID 不 compaction、EX packed offset、query 忽略 generation/done、
   effective-valid 恢复 raw-valid 等 compile-success mutations 必须被定向测试检出。
8. focused tests、current module aggregate、RTL style、contract 与独立审查完成；strict lint 和 PPA
   只按真实结果分层记录，不以历史数字越级签收。

## 6. 明确非声明

不声明 async memory、MulDiv、CLMUL、FP/FPR、branch redirect、Q1/CSR/system/trap、全 holder census、
global no-live-reuse、跨 reset 外部响应、完整双 memory、Linux、综合/STA/power、200 MHz、PPA/Pareto
或 canonical promotion。
