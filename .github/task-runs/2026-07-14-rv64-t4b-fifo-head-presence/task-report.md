# RV64 200MHz T4B：FIFO head presence registered projection

## 基本信息

- `task_id`: `2026-07-14-rv64-t4b-fifo-head-presence`
- `task_slug`: `rv64-t4b-fifo-head-presence`
- `graph_template`: `custom`
- `graph_mode`: `dynamic`
- `status`: `in-progress`
- `owner`: `/root`
- `started_at`: `2026-07-14`
- `updated_at`: `2026-07-14`

## 任务目标

- `source_request`: 持续优化 RV64 架构，直到功能完整且 exact 5.000ns STA 达到 200MHz。
- `goal`: 从 T4A fresh top40 的共同起点移除 FIFO occupancy zero-compare，保持 FIFO 周期语义完全不变。
- `scope`: `OooFetchPacketFifo` 的 head presence 投影、模块 TB、契约/spec、负向变异、完整回归与 fresh synthesis/STA。
- `out_of_scope`: 本切片不修改 downstream classify/dispatch 逻辑，不修改 FIFO 深度/吞吐，也不声称 pre-layout 之外的 CTS/SPEF/OCV signoff。

## 选图说明

- `selected_template`: 动态 `recon -> contract -> implement -> directed-verify -> regression -> fresh-sta -> record`。
- `why_this_graph`: exact STA 已把 40/40 违例收敛到单一起点，但 0.130ns 缺口接近单个比较锥延迟，必须用 source/netlist/功能/时序四层证据防止估算假绿。
- `dynamic_nodes_added`: `sta-startpoint-map`、`mutation-negative`、`frozen-input-audit`。
- `why_dynamic_nodes_were_needed`: 需要证明被移除的是实际物理锥，同时证明影子状态不会在稀有 FIFO 事件下漂移。

## 节点概览

| 节点ID | 负责 Agent | 状态 | 输入 | 输出 | 成功标准 |
| --- | --- | --- | --- | --- | --- |
| `t4b-recon` | `/root/t4b_startpoint_map` | completed | T4A top40/netlist/RTL | 起点与公共路径映射 | 40/40 路径及 RTL owner 精确映射 |
| `t4b-contract` | `/root` | completed | FIFO spec/RTL/TB | 本报告与 §2/§3 冻结 | 事件、优先级、不变量、拓扑完整 |
| `t4b-implement` | `/root` | in-progress | 冻结契约 | `head_valid_q` projection | 不改变端口与周期语义 |
| `t4b-directed` | `/root` | pending | RTL/TB/audit | GREEN + mutation RED | 每个关键事件可达且违约会响 |
| `t4b-regression` | `/root` | pending | current source | module/lint/style/contract | 所有适用 gate 全绿 |
| `t4b-fresh-sta` | `/root` | pending | 冻结 source/tool/input | fresh netlist + exact 5ns STA | loops=0，报告 WNS/TNS；仅非负才称 200MHz |
| `t4b-record` | `/root` | pending | 全部证据 | memory/task-run/tmp archive | 实现者/审查者冲突与剩余风险显式记录 |

## 接口契约冻结

### 六类跨模块契约

1. **握手**：本 FIFO 无 ready；`enqueue_i/pop_i` 是 parent 已判合法的单拍动作。reset 释放后 clear/enqueue/pop 必须为已知二值，否则立即断言 fail closed。head packet 仅在 `head_valid_o=1` 时可消费。
2. **反压/stall**：idle 即所有 FIFO 状态保持；真正进入 normal-event 分支的 full 单 enqueue 与 empty pop 是 parent 违约，已有立即断言 fail closed；clear 同拍吞掉的动作不适用该断言。
3. **clear/flush**：本模块只见 `clear_i`，优先级为 `rst > clear_i > normal event > idle`。clear 清 pointer/count/valid，payload shadow 可保留但因 valid=0 不可消费。
4. **异常序**：不解释异常；response code 与 packet payload 原子存取，head presence 不改变年龄序。
5. **访存序**：不拥有访存事务；不适用。
6. **投机恢复/单一真源**：`count_q` 仍是 occupancy 真源；`head_valid_q` 是仅为切断物理零比较而维护的 registered projection，必须始终与 `count_q!=0` 等价，不能成为第二套 occupancy 算法。

### 同拍优先级与状态表

| 条件（按优先级） | `count_q` | `head_valid_q` | head payload |
| --- | --- | --- | --- |
| `rst` | 0 | 0 | 清零 |
| `clear_i` | 0 | 0 | 保持、不可见 |
| enqueue only | `+1` | 1 | empty 时装 enqueue bundle |
| pop only，旧 count=1 | `-1` | 0 | 保持、不可见 |
| pop only，旧 count>1 | `-1` | 1 | 装旧 ring[head+1] |
| enqueue+pop | 保持 | 保持为 1 | count=1 时装 enqueue；否则装旧 ring[head+1] |
| idle | 保持 | 保持 | 保持 |

## RTL 推导摘要

### 阶段 1 — 需求

- 功能：保持现有 FIFO 外部行为和端口不变；`head_valid_o` 在所有合法事件后与新 occupancy 同拍可见。
- 性能：删除 `count_q[2:0] -> NOR3 -> INV -> head_valid_o` 组合锥，使 downstream 从 dedicated Q 起步；不增加气泡。
- 时钟/复位：单 `clk`，同步高有效 `rst`；不新增跨时钟域。
- 边界：parent 仍产生 enqueue/pop/clear 并负责容量合法性；downstream 仍只以 `head_valid_o` gate head packet。

### 阶段 2a — 协议规则

- `head_valid_o` 是 level 状态，不是可撤回的 transaction valid；在没有 occupancy 事件时必须保持。
- reset/clear 当沿清零，empty enqueue 当沿置一，last pop 当沿清零；这些与原 `count_q!=0` 的沿后可见语义完全一致。
- 合法 pop+enqueue 的旧 count 必为非零，因此 count 不变且 valid 保持一。

### 阶段 2b — 状态机

- 无独立 FSM；使用 `{enqueue_i,pop_i}` 四事件 Mealy-to-next-state 表。
- 非法 empty pop/full single enqueue 不定义功能推进，由立即断言中止验证。

### 阶段 2c — 不变量

- `head_valid_q === (count_q != 0)`，触发于 reset 释放后的每拍；违反意味着 occupancy projection 漂移并 `$error/$fatal`。
- reset/clear 优先于所有正常事件；clear+enqueue/pop 结果必须为空。
- underflow/overflow-request 断言必须以 `!clear_i` 限定 normal-event 作用域，防止 clear collision 误报。
- clear/enqueue/pop 任一含 X/Z 都必须命中 `[CONTRACT-FIFO-CONTROL-KNOWN]`，防止 pointer `if` 与 occupancy `case` 对未知控制作不同解释。
- count 始终在 `0..DEPTH`；pop 要求旧 count>0；单 enqueue 要求旧 count<DEPTH。
- head payload 与 ring owner 的 T3W 原子等价不变量保持不变。

### 阶段 2d — 数据通路约束

- 新增 1-bit `head_valid_q`，仅由与 `count_q` 相同的时序块更新；`head_valid_o` 只连该 Q。
- `count_o` 仍只连 `count_q`；ring、head/tail pointer 与 `head_packet_q` 数据通路不变。
- 禁止用 downstream ready、payload 内容或 pointer 推导 `head_valid_q`。
- 关键路径预算：旧 occupancy zero-compare 约 0.146ns；新路径从 `head_valid_q` clk-to-Q 直接进入 head classify。是否闭合只由 fresh STA 裁决。

### 阶段 2e — RTL 级电路拓扑及自审

1. **边界**：端口/位宽/单时钟域全部不变；enqueue/pop/clear 动作协议不变。
2. **寄存器**：只新增 `head_valid_q[0:0]`，reset=0；更新使能由 reset/clear/四事件表决定。
3. **组合块**：`assign head_valid_o = head_valid_q`；不新增宽 mux/比较器。
4. **FSM**：无；四事件表即完整 next-state。
5. **pipeline/valid**：不新增 stage；head packet shadow 与 presence Q 在同沿更新。
6. **优先级**：`rst > clear > normal event > idle`。
7. **资源**：ring 单 tail 写口、head shadow 读取方式均不变；presence Q 不共享/复用算术资源。
8. **critical path**：目标切除 count zero-compare；downstream classify/dispatch 保持原拓扑。
9. **function 划分**：`ptr_inc` 继续仅作小型纯组合 helper；valid next-state 显式留在时序 case，不放 function。

自审结论：事件表对 count=0/1/>1/full 以及 clear collision 均闭合；simultaneous pop+enqueue 保持 valid 仅依赖已有 empty-pop 禁止契约，不引入隐含前提。允许进入 RTL 实现阶段。

## 当前阻塞点

- `blockers`: 无。
- `missing_dependencies`: fresh synthesis/STA 与完整功能回归尚未执行。
- `risk_assessment`: 预估余量仅约 0.017ns，布局/映射变化可能使 T4B 仍未达到 200MHz；若未闭合必须以新 top paths 继续架构迭代。

## 收尾结论

- `final_result`: in-progress；不得声明 200MHz。
- `evidence_summary`: T4A exact STA 的 top40 40/40 共同起于 FIFO count zero-compare。
- `notes`: 父目标保持开放。
