# V10A serialized-control clocked owner-clear report

## 状态

`PASS`（仅限 V10A pending architectural-trap clocked exactly-once 子范围）。

本切片只裁决本地 RV64 双发射 OoO 核中：

`OooPendingDrainResolveGate` C0 resolve
→ `OooPendingTrapExitSequencer` / `OooPendingSystemSequencer`
→ C1 holder/stop clear
→ `CsrFile` trap/return state update
→ frontend redirect boundary

的时钟化 exactly-once 合同。V9Z 已闭合的组合
pending architectural-trap memory-owner terminal 条件继续作为前置，不在本轮改写。

当前已验证 design-id：
`sha256:13d868334de2a0813f91af318f25434f8e93c581adc67d0b562fcc1f6f8dc951`。

上层状态保持：

- `SERIALIZE-G1=OPEN`
- `ppa=UNQUALIFIED`
- architecture-stable 尚未冻结

## 图任务

| node_id | owner_agent | depends_on | inputs | outputs | success_criteria | fallback |
| --- | --- | --- | --- | --- | --- | --- |
| V10A-R0 | root | V9Z | live RTL/spec/V9Z evidence | C0/C1 owner 与副作用调用链 | 给出逐拍状态、优先级、反例与未知项 | 扩大只读合同范围 |
| V10A-R1 | independent reviewer | V10A-R0 | versioned read-only RTL contract | pre-review report | 独立确认实际 bug 或验证缺口，不越级 | 保留 GAP 并生成 v2 合同 |
| V10A-V0 | root | V10A-R1 | production modules + TB | pre-fix/current RED/GREEN matrix | 观察 fire、next-edge clear、CSR/redirect 单次副作用 | 缩小到可判定 transaction |
| V10A-I0 | root | V10A-V0 | 冻结 §2/§3 合同 | 最小 RTL/assertion/TB 变更 | 不增加 terminal 去重，不削弱断言 | 若无需生产修复则只增强验证 |
| V10A-V1 | root | V10A-I0 | current source | focused/mutation/module/functional/architecture evidence | 同 design-id 分层 GREEN | 保留为局部 GAP |
| V10A-R2 | independent reviewer | V10A-V1 | frozen evidence bundle | final reviewer report | 优先寻找重复副作用、overlap 漏洞和假绿 | 不关闭 SERIALIZE-G1 |
| V10A-C0 | root | V10A-R2 | report/evidence/reviewer | task-run/memory/DB/e2e/guard | 证据可发现、可重放、可审计 | 明示豁免与剩余风险 |

## 初始接口契约冻结

### 受影响的六类合同

1. 握手：C0 `drain_complete` 是 registered holder 的单周期消费资格；holder 在该沿后必须清除，
   无新 capture 时 C1 不得再次形成 trap/return/redirect 请求。
2. 反压：活动 serialized owner 令 `stop_pending` 与 `OooFrontendRunGate.can_run=0`，
   阻止 drain 边沿同拍从 fetch head 建立第二个 pending owner。
3. flush/redirect：`rst/core_local_flush > selected trap > xRET > CSR write > ordinary clear/capture`；
   losing source 不得通过静默丢弃掩盖合法 overlap，合法性必须由显式 priority 或构造性不可达证明。
4. 异常序：pending architectural trap 只有在 backend drained、consumer ready、
   exact memory-owner terminal 成立时进入 CsrFile；该 C0 事务在 C1 只能留下一个选中 CSR record。
5. 访存序：沿用 V9Z/V9Y exact owner terminal；不得替换成 full idle，也不得改 collector ingress。
6. 单一真源：trap/exit payload 属于 `OooPendingTrapExitSequencer`，SYSTEM kind 属于
   `OooPendingSystemSequencer`，stop bit 属于 `OooStopPendingSequencer`，
   CSR architectural record 属于 `CsrFile`。

### C0/C1 状态模型

| 周期/边沿 | owner/holder | drain 与请求 | 边沿动作 | 下一周期必须观察 |
| --- | --- | --- | --- | --- |
| C0 active-memory | pending owner=1, stop=1 | exact terminal=0，drain/request=0 | 无消费 | holder/stop/payload 保持 |
| C0 exact-terminal | pending owner=1, stop=1 | drain=1，只允许该 owner 对应的一类请求 | CsrFile 采样一次；holder/stop clear | C1 owner=0, stop=0 |
| C1 no recapture | owner=0, stop=0 | trap/return/redirect side effect=0 | 正常前端恢复 | 不得出现第二次 CSR record |
| C1 new accepted owner | 仅新 capture 可重新置 owner | 与上一事务使用不同 capture witness | 建立新 transaction | 允许后续独立 resolve |

## RTL 推导摘要

### 阶段 1：需求

- 证明或修复 fire→next-edge holder/stop clear。
- 证明无新 capture 时 CsrFile 与 frontend redirect 不重复。
- 对 architectural trap 与 ECALL/IRQ/xRET/CSR/FENCE 建立显式 priority 或构造性不可达证据。
- 不修改 terminal collector/tracker 代数，不增加去重状态，不削弱 assertion。

### 阶段 2a–2e：协议、状态、不变量、数据通路与拓扑

- registered owner 由三个 sequencer 分别保存，组合 drain/mux 不保存状态。
- 预期拓扑为
  `holder Q → drain gate → request mux/CsrFile + pending clear → next-edge Q=0`。
- 关键不变量：
  `fire(C0) && !new_capture(C0) -> !owner(C1) && !stop(C1)`；
  `!owner(C1) -> !same_transaction_side_effect(C1)`；
  registered architectural-trap owner 与 registered pending-system owner 不得同时有效。
- 本轮先用生产模块组成 clocked TB 验证；若 current RTL 已满足合同，不为制造代码改动而新增状态。

## 当前边界

- V9Z 组合边界为前置 PASS。
- Linux terminal、simulation exit、七类全交叉、architecture-stable 与正式 PPA 尚未由本报告关闭。
- `SERIALIZE-G1=OPEN`，`ppa=UNQUALIFIED`。

## 实现结果

### Root cause

`OooCsrTrapRequestMux.pending_arch_trap_fire_o` 原先只要求
`stop_pending_i && drain_complete_i && pending_arch_trap_i`。当 ROB head commit
exception 与 pending architectural trap 同沿出现时，`CsrFile` 按
`mem > ex > irq` 选择 commit exception，但 raw pending trap request 仍然有效。
因此 raw request、priv predictor boundary 与真正被选中的 CSR transaction
不是同一个单一真源。

pre-fix clocked RED 在
`pre-fix/result/logs/tb_ooo_serialized_owner_exactly_once.log` 中只命中四个预期反例：

- commit trap 未屏蔽 pending architectural-trap request；
- commit trap 未屏蔽 raw trap-ex request；
- raw architectural-trap request 计数多一次；
- C1 no-repeat raw request 计数失败。

该 RED 能证明行为反例，但未保存完整历史源码快照 hash，故只作为
behavioral RED，不作为可重建的历史 design-id。

### 最小生产 RTL 修复

`npc/rv64/vsrc/control/OooCsrTrapRequestMux.v` 新增
`drained_pending_control_w`，将同沿 `core_commit_exception_trap_o`
提升为 pending control 请求的显式高优先级屏蔽条件。修复不增加 terminal
去重状态，不改变 memory-owner terminal 代数，也不放宽 drain 条件。

`npc/rv64/vsrc/control/OooControlPlane.v` 在 `OOO_ASSERT` 下新增：

- registered arch/system owner onehot；
- live serialized owner 必须保持 stop；
- architectural-trap request 不得与 selected mem trap、direct redirect、
  ECALL、IRQ、xRET side-effect pulse 重叠；
- C0 fire 后 C1 owner/stop/request 必须清除且不得重复。

### 时钟级观测

生产模块组成的
`npc/rv64/testbench/tests/tb_ooo_serialized_owner_exactly_once.sv`
直接计数每个 raw request，不做去重：

| 观测 | 结果 |
| --- | --- |
| head0 arch/system 同沿 birth | onehot PASS |
| lane1 arch/system 同沿 birth | onehot PASS |
| IRQ/arch 同沿 birth | IRQ priority PASS |
| ECALL/IRQ/xRET/CSR/FENCE 单独 transaction | 五类 exact-one PASS |
| live arch owner 对五类 SYSTEM overlap | `stop -> !can_run`，五类均被阻止 |
| commit exception 与 pending arch 同沿 | selected mem trap PASS，pending raw request=0 |
| older active memory holder | drain/request 均被阻止 |
| C0 terminal fire | 单次 request PASS |
| C1 next edge | owner=0、stop=0、`CsrFile.mepc` 更新一次 |
| C2 no recapture | raw request 与 CSR record 均不重复 |

## 分层验证

- focused assertion-on：
  `focused/result/logs/tb_ooo_serialized_owner_exactly_once.log`，
  包含 `V10A-BIRTH-ONEHOT-PASS`、五个 `V10A-SYSTEM-KIND-PASS`、
  `V10A-LIVE-OWNER-OVERLAP-PASS`、
  `V10A-COMMIT-TRAP-PRIORITY-PASS`、
  `V10A-CLOCKED-EXACTLY-ONCE-PASS` 与最终 `RESULT PASS`。
- focused assertion-off：
  `focused-noassert/result/logs/tb_ooo_serialized_owner_exactly_once.log`，
  同一 clocked transaction matrix PASS。
- compile-success mutation：
  `mutations/summary.json`，6/6 变体均 `compile_rc=0` 且
  `simulation_rc=1`；覆盖 commit-trap mask、head0/lane1 birth onehot、
  IRQ birth priority、arch owner clear 与 stop clear。
- module aggregate：
  `module-current/summary.txt`，113/113 PASS。
- canonical functional：
  `npc/rv64/eval/ppa/evidence/functional-aggregate-result.json`，PASS；
  module 113/113、official 177/177、AM 59/59、DiffTest mismatch=0。
- architecture replay：
  `architecture/final-architecture-hard-gates.json`，DI-1..DI-5 与
  OOO-1..OOO-4 全部 GREEN。
- functional 与 architecture replay 均绑定 design-id
  `sha256:13d868334de2a0813f91af318f25434f8e93c581adc67d0b562fcc1f6f8dc951`。

## 实现者 / 审查者裁决

- 实现者：当前 RTL 对 pending architectural trap 的 C0 request、C1
  registered owner/stop clear 与 C2 no-repeat 已形成动态证据；同沿 commit
  exception 的 raw request priority 缺口已由最小组合修复闭合。
- 独立审查者：V10A bounded sub-slice `PASS`；没有发现重复 terminal
  side effect、去重掩盖或断言削弱。完整 `SERIALIZE-G1` 与长期目标仍为
  `GAP`。

独立审查保留以下证据边界：

- focused 日志没有内嵌 `[RTL-DESIGN-ID]`；当前身份由 mutation
  live-file hashes、canonical functional 与 architecture replay 交叉绑定；
- pre-fix RED 没有完整历史源码快照 hash；
- TB 没有独立逐拍计数最终 frontend redirect / `priv_predictor_boundary`；
  当前由 production 静态 OR 拓扑、模块 aggregate 与 functional gate
  提供间接覆盖；
- 本切片没有 synthesis、STA 或 power 证据。

## 后续主线

继续闭合八类 serialized SYSTEM post-fire transaction、simulation exit 与
Linux terminal；在全核 `SERIALIZE-G1` 和其它 P0/P1 架构债务清零前，
不得冻结 full-core architecture-stable，也不得将诊断性实现数据晋级为
正式 PPA 结论。
