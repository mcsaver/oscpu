# v8j RTL 四段式推导

## 阶段 1 — 需求

- 功能：把 branch-resolve 从 raw stage event 提升为 ROB 签发的 full-PID actual capability。
- 边界：`OooIntBackend` 保存 candidate，`OooDispatchBackend` 只透传 query，`OooRob` 是 exact-open
  单一权威；frontend/ROB-walk/BPU/kill consumer ABI 保持不变。
- 性能：不新增流水拍、FSM、FIFO 或 backpressure；只增加一个 ROB 组合 query 和等宽 PID 比较。
- out-of-scope：pending-system/CSR、global generation reuse、PPA promotion。

## 阶段 2a — 协议规则

- branch q 是固定一拍、不可背压 transport；candidate 可静默排空。
- query valid 只表示候选身份可查询，不依赖 query match；match 不反向进入 issue/stage ready。
- actual capability 必须同时满足 cancel mask、ROB exact-open、raw registered EX0 full-PID coherence。
- downstream 继续消费现有 resolve ABI，但其 valid 语义升级为“已授权 capability”。

## 阶段 2b — 状态机

无新 FSM。已有时序：

```text
IDLE --issue0 control-flow fire/P--> RESOLVE_Q(P) --unconditional consume--> IDLE
                                  | reset/flush/checkpoint: silent clear
                                  | stale/mismatch/recovery: silent consume
```

ROB `valid/done/generation/recover_q` 是 query 的 edge-old 状态；query 本身无状态。

## 阶段 2c — 不变量

- I1：branch q 保存 full P，raw index仅为低位投影。
- I2：actual capability ⇒ ROB exact-open(P)。违反会错误 redirect/kill/BPU update。
- I3：actual capability ⇒ raw `ex0_valid_q` 且 `ex0_producer_id_q==branch.P`。违反会让不同
  generation 借同 raw index；若改读 EX0 completion/semantic valid，则会把 self-kill 组合环接回来。
- I4：prior recovery/reset/flush/checkpoint ⇒ actual=0。
- I5：current self-kill 不参与 resolve query，boundary P 不被自己拒绝且无组合反馈。
- I6：query 不影响 transport ready/占用。

## 阶段 2d — 数据通路约束

- branch payload 的 raw index字段替换为 `PRODUCER_ID_W` full P；payload 其它字段顺序保持。
- `OooRob` 用 P 低位选择 slot，以 `{slot_generation_q[idx],idx}==P` 比较 generation。
- `OooDispatchBackend` 是纯 named-port query proxy，不缓存身份。
- `OooIntBackend` 形成 candidate/query/coherence/authorized 四层 wire；coherence 只读 raw registered
  `ex0_valid_q/P`，不得读 completion-open、killed-now 或 WB-valid；所有对外 payload由 authorized
  统一 mask，raw stage valid 只负责物理消费。

## 阶段 2e — RTL 级拓扑与自审

1. module 边界：新增 resolve-query valid/PID/match 三根组合端口；时钟域仍为 core `clk`。
2. 状态寄存器：无新增；branch `PipeStageReg` 和 ROB 既有 arrays/recover_q 不变。
3. 组合块：PID pack/unpack、ROB dynamic slot exact compare、coherence compare、统一 payload mask。
4. FSM：无新增；已有一拍 q 无条件消费。
5. pipeline：issue fire→branch/ex0 q→同拍 query+actual effect，延迟不变。
6. 优先级：reset/flush > checkpoint/prior recovery > exact/coherence > effect > consume。
7. 资源：新增一组 slot generation/valid/done 读与 PID 比较；不共享 ready/arbiter。
8. critical path：ROB array read→PID compare→resolve valid→redirect/kill；这是诊断性时序风险，未测量前
   不作 PPA 结论。若成为 timing blocker，只能在保持 capability 语义下另立架构切片。
9. function 划分：query 显式 assign；不得调用读取 `kill_valid_i` 的 killed-now helper；coherence
   不得读取任何依赖该 helper 的 EX0 派生 valid；无新 function/FSM。
10. 结构前提：`kill_valid_i` 仍只由本 authorized resolve 产生，`flush/checkpoint` 不是 capability
    的组合后代；若接口演化打破此前提，必须重新审查 query，而不是静默复用。
11. 实现中暴露既有 `producer_target_killed_now(target_idx)` 的仿真敏感性缺口：多个连续赋值
    并行调用的函数通过函数体隐式读取 `kill/recover/head`，同 index 时 Icarus 可保留旧 killed。
    根因修复为 `function automatic`，并把六个输入全部作为显式参数；不增加逻辑状态。

自审结论：专用 query 是必要结构。复用 completion/current query 会读 self-generated kill，产生
query→mispredict→kill→query 组合 SCC；只比较 raw index则不能关闭 generation alias。

## 阶段 3 — 实现门

合同 reviewer 返回前不写 RTL。通过后按 payload→ROB query→proxy→authorization→assertion→TB/
mutation 的顺序实现，并以 source pre/post hash 证明 mutation 不污染 canonical RTL。
