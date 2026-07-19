# RV64 v8d integer EX completion kill-cut contract

## Design state 与 completion definition

- 状态：`intermediate_checkpoint`，父切片为 v8c FP completion kill-cut 与 producer identity P0。
- source parent：当前 dirty worktree；最终证据必须记录本切片实际源文件 SHA-256，不能引用历史网表。
- 联合修改块：`OooIntBackend` 的 EX0/EX1 raw stage、completion arbitration、PRF/BusyTable/IQ/ROB
  formal-WB 入口，以及对应 focused TB/spec。
- 本切片完成条件：pre-fix 可执行 RED；release/assert GREEN；严格年轻/equal/older 与环回年龄覆盖；
  killed slot 可让 live lower-priority completion 使用；compile-success mutation 被精确杀死；current module
  aggregate、RTL style 与 contract gate 通过。
- 回退点：只回退本切片新增的 effective-valid/age cut、TB 与文档，不动 v8c FP 或 P0 census。
- 停止条件：若真实调用链证明 EX completion 在 PRF/BusyTable/IQ 前已有等价 kill authorization，或
  修复需要先完成 full ProducerId，则保留 RED 证据并停止写 RTL。
- 非完成项：generation-safe full identity、ROB slot no-live-reuse、memory/FP/long-op 全 carrier、Q1/CSR
  live owner、DI/OOO 九门、Linux、fresh synthesis/STA/area/power、Pareto/promotion。

## 图节点

| node_id | owner | depends_on | inputs | outputs | success_criteria | fallback |
| --- | --- | --- | --- | --- | --- | --- |
| R0 | root | — | bounded brief、current memory/spec/source | root-cause 数据流 | 副作用点早于 ROB 被证实 | 证否则停止 |
| R1 | root | R0 | current RTL + focused TB | pre-fix RED | compile/elaborate 成功且只因错误 completion 资格失败 | 修 TB，不改 oracle |
| R2 | root | R1 | 本合同 | 最小 RTL cut | raw/effective valid 分层且无新状态/端口 | 回退 R2 |
| R3 | root | R2 | current RTL/TB | GREEN + mutations | 正例全过、可编译 mutant 全被杀 | 定位 contract/实现缺口 |
| R4 | root | R3 | current source inventory | module/style/contract/lint | 与声明范围匹配的 gate 通过 | 只交付 RED/剩余风险 |
| R5 | root | R4 | memory/e2e rules | retained memory + profile + guard | 业务证据与工作流证据分层可审计 | 明示豁免，不造绿 |

## 阶段 0：六类接口/控制契约冻结

| 类别 | 冻结合同 |
| --- | --- |
| 握手 | EX0/EX1 `PipeStageReg` 的 raw `down_valid` 仍是内部占用事实；只有 effective-valid 才是 formal-WB event。严格年轻且同拍命中 branch kill 的 raw completion 不得被 ROB/PRF/BusyTable/IQ 消费。被杀 slot 当拍视为可用，允许一个 live lower-priority completion 占用，但不得重复 ack。 |
| stall/backpressure | EX stage 继续 `down_ready=1`，不新增反压/FIFO。kill 拍 IQ 已禁止新 issue；older/equal survivor 仍正常单拍消费，younger raw stage 在沿上清空。 |
| flush/redirect | 优先级为 `rst/full flush/checkpoint restore > selective branch kill > live completion > normal load`。selective kill 只命中 `age(ex)>age(boundary)`；boundary branch 与更老 completion 保留。 |
| 异常序 | younger EX exception/result 在 kill 拍不得写 ROB done/data/exception，也不得先写 speculative PRF 或唤醒依赖者；boundary branch 自身 completion 必须保留，退休全序不变。 |
| 访存序 | MIQ/SQ/AXI 语义不改。killed EX 释放的 WB slot可接收已经 live/authorized 的 memory/long/FP completion；本切片不改变它们的 owner、kill 或 ready 规则。 |
| 投机恢复/单一真源 | 年龄唯一真源为 `rob_idx - rob_head_idx` 的等宽环形差；kill boundary 唯一来自 staged branch resolve。raw stage valid 只表示物理寄存器占用，effective completion valid 才能驱动所有副作用。 |

受影响稳定 spec：`pipeline-stage-boundary.md`、`ooo-ex-sticky-wakeup-barrier.md` 与
`ooo-flush-redirect-contract.md` 必须同步删除“晚到 WB 只靠 ROB 吞”的过期表述。

## 阶段 1：需求

1. 同拍 mispredict 时，EX0/EX1 中严格年轻 completion 在组合面立即失去 WB/PRF/wakeup 资格。
2. equal boundary 与 older completion 保持 exactly-once。
3. raw stage 沿上清 younger；不引入新端口、FSM、队列或延迟。
4. lower-priority live completion 能使用被杀 EX 所释放的 slot。
5. 把可编码合同变成立即断言，并用 compile-success mutation 证明非真空。

## 阶段 2a：协议规则

- `raw_valid` 只由 `PipeStageReg` 持有；`effective_valid = raw_valid && !kill_now`。
- `kill_now = branch_mispredict && raw_valid &&
  ((raw_rob-head) > (boundary_rob-head))`，严格大于，等于不杀。
- stage `kill_i=kill_now`；WB arbitration、free-count、source onehot、PRF write、formal wake 和 ROB WB
  只能读 effective-valid。
- payload 在 raw valid=0 时仍可留脏；所有语义输出必须受 effective-valid 保护。

## 阶段 2b：状态/时序模型

本切片不新增状态。每 lane 仍只有 `PipeStageReg.valid_q/payload_q`：

| 当前拍 | kill 关系 | 组合输出 | 上升沿后 |
| --- | --- | --- | --- |
| raw invalid | 任意 | 无 EX completion | 依原装载规则 |
| raw valid | older/equal | formal WB 有效 | 正常消费/可装载 |
| raw valid | strictly younger | formal WB/PRF/wake/ROB 全无效 | `kill_i` 清 raw valid |

同拍优先级：`full flush > selective kill > up-load/down-consume`，由 `PipeStageReg` 既有优先级承载。

## 阶段 2c：不变量

- **INT-EX-K1**：`kill_now(exN) -> !exN_effective_valid`。
- **INT-EX-K2**：killed EX identity 不得出现在该 lane 的 formal WB/PRF write/wakeup/ROB update。
- **INT-EX-K3**：`raw_rob == boundary_rob` 必须保留；older 也必须保留。
- **INT-EX-K4**：环回年龄只用等宽模减，禁止 raw index `>`。
- **INT-EX-K5**：killed slot 不得阻塞一个 live lower-priority completion。
- **INT-EX-K6**：kill 沿后不得再出现 delayed EX completion pulse。

## 阶段 2d/2e：数据通路与 RTL 级拓扑

```text
branch_resolve_q.{valid,mispredict,rob_idx}    rob_head_idx
                 |                                  |
                 +------ equal-width age compare ---+
                                   |
exN PipeStageReg.raw_valid/payload --+--> kill_now --> PipeStageReg.kill_i
                                   |
                                   +--> effective_valid
                                          |
                                          +--> wb free-count/arbitration
                                          +--> WB payload/source onehot
                                          +--> PRF write
                                          +--> BusyTable/IQ formal wake
                                          +--> ROB done/data/exception
```

- module/端口：不变；单时钟同步高有效 `rst`，full flush/restore 沿用现有输入。
- 状态寄存器：只复用两个 `PipeStageReg`；复位值/更新块不变。
- 组合块：每 lane 一个等宽减法 age、严格比较、effective-valid；无循环、无 latch。
- pipeline/valid：EX raw stage→effective completion→既有无反压 WB。
- 资源：两个 lane 独立比较，kill boundary/head 共享；不封装进 function/仲裁器。
- critical path：branch resolve Q→age compare→WB select/PRF write enable；本刀是 correctness checkpoint，
  未经 fresh STA 不声称 timing/PPA 改善。
- 拓扑自审：boundary equal 保留；raw payload 位段不变；alternate owner 仍经既有优先 mux；无新跨模块 ABI。

