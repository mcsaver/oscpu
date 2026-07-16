# RV64 200MHz T4C：PTW walk lookup fixed-role payload owner

## 基本信息

- `task_id`: `2026-07-14-rv64-t4c-walk-lookup-payload-owner`
- `task_slug`: `rv64-t4c-walk-lookup-payload-owner`
- `graph_template`: `custom`
- `graph_mode`: `dynamic`
- `status`: `completed`
- `owner`: `/root`
- `started_at`: `2026-07-14`
- `updated_at`: `2026-07-14`

## 任务目标

- `source_request`: 持续优化 RV64 架构，直到完整功能且 exact 5.000ns STA 达到 200MHz。
- `goal`: 切断 PTW leaf PMP/qualified-fire 对 D-cache SRAM address mux 的控制污染，不新增拍、不放宽权限。
- `scope`: `OooMemAxiBridge` walk lookup payload owner、bridge TB、契约/负向变异、完整回归、fresh synthesis/STA。
- `out_of_scope`: 不改 D-cache 宏、Xbar R owner、PMP 判定、PTW A/D write-PMP gap，也不在本切片改 PLIC 内部路径。

## 前序证据与根因

- T4B fresh exact 5ns：WNS/TNS=`-0.090/-1.39ns`，loops=0；旧 FIFO count 家族从 top40 的 40 条降为 0。
- 新 top40 前 10 条共同起点 `AxiXbar.rd_resp_valid_q[1]`，经 buffered RDATA mux、PTE leaf PA、`u_walk_leaf_pmp_checker`、`walk_read_lookup_fire_w`，终止于 D-cache SRAM `addr_i[10]`/`addr_i[0..8]`；最差 `-0.088ns`。
- 根因：permission-qualified valid 同时被当作 payload mux owner，使完整 leaf PMP 树进入地址锥；PMP deny 等周期 lookup enable 本来为 0，地址选择没有架构意义。

## 节点概览

| 节点ID | Owner | 状态 | 输入 | 输出 | 成功标准 |
| --- | --- | --- | --- | --- | --- |
| `t4c-recon` | `/root/t4c_dcache_path` | completed | T4B fresh top40/netlist/RTL | cell→RTL 路径与根因 | 起终点、公共锥、有效周期等价证明完整 |
| `t4c-contract` | `/root` | completed | mem bridge spec/FSM | §2/§3/六类契约/拓扑 | owner 与 permission enable 分责可判定 |
| `t4c-implement` | `/root` | completed | frozen contract | fixed-role owner RTL | 不改端口、状态、enable 或响应拍 |
| `t4c-directed` | `/root` | completed | RTL/TB/audit | GREEN + mutation RED | waiting/allow/deny/A-D/write/flush owner 场景闭合 |
| `t4c-regression` | `/root` | completed | current source | module/lint/style/contract | 适用 gate 全绿 |
| `t4c-fresh-sta` | `/root` | completed | frozen source/tool/input | fresh netlist/exact 5ns | leaf PMP→SRAM addr 断开；全局 WNS/TNS 如实裁决 |
| `t4c-record` | `/root` | completed | 全证据 | task-run/memory/tmp archive | task-run 已记录；父目标保持开放 |

## 接口契约冻结

### 六类跨模块契约

1. **握手**：D-cache 只在 `lookup_en_i=1` 的沿采样 lookup address/context；地址在 enable=0 周期是无事务 payload。
2. **stall**：`S_WALK_R` 可等待任意拍 RVALID；期间 payload owner 保持 walk role，lookup enable 必须为 0，不能捕获 context。
3. **flush/drop**：`fsm_normal_w` 继续 gate walk lookup enable；flush/drop 可让 state 当拍仍为 S_WALK_R，但不得发 lookup。fixed-role address 的无效切换不构成事务。
4. **异常序**：invalid/nonleaf/permission/PMP deny/A-D-needed/write 的原有 fault/update/写路径不变；特别是 leaf PMP deny 仍返回 access fault且不发 lookup。
5. **访存序**：不新增 AXI beat、fill、store 或 replacement；所有 meaningful lookup 的 address 与旧实现逐位相同。
6. **单一真源/恢复**：`state_q==S_WALK_R` 是 walk payload role 的单一真源；`walk_read_lookup_fire_w` 是权限许可真源。禁止 permission valid 反向决定 payload owner。

### 同拍优先级/owner 表

| 场景 | payload owner | `dcache_lookup_en_w` | meaningful address |
| --- | --- | --- | --- |
| request station read issue | request event | 1 | request candidate PA |
| S_WALK_R waiting/invalid/nonleaf/deny/A-D/write | walk state | 0 | don't-care，结构上仍为 leaf-derived payload |
| S_WALK_R qualified read leaf | walk state | 1 | `walk_leaf_paddr_w` |
| S_AD_UPDATE B-ok read continuation | fallback registered owner | 1 | `paddr_q` |
| flush/drop/RMW busy | owner 可存在 | 0 | 不采样 |

owner 优先级保持 `request issue > walk state > registered paddr fallback`；三类 meaningful event 由 FSM 状态互斥。

## RTL 推导摘要

### 阶段 1 — 需求

- 功能：所有合法 PTW load 的 lookup、cache hit/miss、response 和 fault 行为不变。
- 性能：从 D-cache SRAM address select 中移除 leaf PMP/qualified-fire 组合树；不新增 pipeline stage 或 CPI。
- 接口：端口、位宽、单时钟同步复位均不变；只新增内部组合 owner wire。
- 边界：D-cache enable 仍是唯一采样许可，PTW/PMP 仍是权限 owner。

### 阶段 2a — 协议规则

- `walk_read_lookup_fire_w` 必须继续蕴含 S_WALK_R、RVALID/OK、valid leaf、permission、PMP allow、A/D ready、read access；实际 lookup 另由既有 `fsm_normal_w && !rmw_busy` 外层 gate。
- `walk_lookup_payload_owner_w` 只表达当前 FSM 的 payload role，不可用于状态推进或 enable。
- `lookup_en=1` 时地址必须匹配唯一 event owner；`lookup_en=0` 时地址变化不得触发 cache 状态变化。

### 阶段 2b — 状态机

- 不新增/删除状态和转移。
- S_WALK_R qualified read 仍同拍发 lookup并转 S_LOOKUP；deny/fault/A-D/write/nonleaf 分支完全不变。
- S_AD_UPDATE continuation 仍使用锁存 `paddr_q`。

### 阶段 2c — 不变量

- `walk_read_lookup_fire_w -> walk_lookup_payload_owner_w`；`fsm_normal_w && !rmw_busy && walk_read_lookup_fire_w -> dcache_lookup_en_w`。
- S_WALK_R 且非 qualified fire 时 `dcache_lookup_en_w=0`。
- fixed-role walk owner 有效时，地址 mux 输出必须等于 `walk_leaf_paddr_w`，即使 enable=0。
- 任一 `dcache_lookup_en_w` 拍按 request/walk/A-D owner 逐位核对地址；RMW 互斥、T3W req-side valid/payload split 断言保持。

### 阶段 2d — 数据通路约束

- 新增 `walk_lookup_payload_owner_w=(state_q==S_WALK_R)`。
- 地址 mux 从 `req_owner ? req_candidate : walk_fire ? leaf_pa : paddr_q` 改为 `req_owner ? req_candidate : walk_owner ? leaf_pa : paddr_q`。
- `dcache_lookup_en_w`、`walk_read_lookup_fire_w`、PMP checker、D-cache 实例端口均不改。
- 目标关键路径删除约 2.27ns 的 leaf PMP→qualified select 段；实际收益只由 fresh STA 裁决。

### 阶段 2e — RTL 级电路拓扑及自审

1. **module/接口**：`OooMemAxiBridge` 外部端口不变；D-cache lookup 为 enable+address 同时序接口。
2. **状态寄存器**：无新增寄存器；`state_q` 继续拥有 FSM role。
3. **组合块**：新增 1-bit state decode；只替换 64-bit mux 的 select，不改 data arms。
4. **FSM**：状态/转移/复位零改动。
5. **pipeline**：无新 stage；qualified leaf 的 lookup 与 S_LOOKUP 转移仍同拍。
6. **优先级**：request event > walk state > paddr fallback；flush/drop/RMW 只 gate enable。
7. **资源**：无复制 PMP/adder/cache；复用现有 leaf PA 数据臂。
8. **critical path**：Xbar RDATA→leaf PA 仍存在；leaf PA→PMP→address select 被切断，PMP 只留在 enable/状态控制锥。
9. **function 划分**：`leaf_paddr` 保持纯组合 helper；owner/enable/断言显式 RTL，不封装 FSM 逻辑。

自审结论：对所有 `lookup_en=1` 周期，新旧地址相同；差异集合严格包含于 enable=0 周期，因此不改变任何被采样状态。允许进入实现阶段。

## 验证与 fresh STA 结果

- 定向 bridge TB PASS，唯一正向标记为 `[T4C-WALK-PAYLOAD-OWNER]`。
- 源审计 PASS，并拒绝旧 select、错误状态、放宽 enable、删除断言和无效 poison 共 6 个变异。
- 动态负向变异 3/3：旧 select、错误 owner、放宽 walk enable 均以精确 T4C 断言一次命中并非零退出。
- focused 5/5、全模块 98/98、Verilator lint、RTL style、contract `172>=89`、`git diff --check` 全部 PASS。
- fresh netlist SHA256 `6d7c5d4a06cfb94b19676324bf95d3205df815d854cc4a440cc64d76978110f9`；所有输入/工具/参数冻结比较 PASS。
- exact 5.000ns OpenSTA：WNS/TNS=`-0.05/-0.61ns`、loops=0、power=0.117W。T4B 的 D-cache/PMP→SRAM address 家族从 top40 清零；剩余 40 条均为 PLIC 内部 claim side-effect 路径。

## 当前阻塞点

- `blockers`: T4C 子任务无阻塞；父目标尚未满足 exact 200MHz。
- `missing_dependencies`: 父目标仍需优化 PLIC 内部 `threshold -> claim winner -> pending/in_service D` 路径，并补最终系统级回归。
- `risk_assessment`: 当前 WNS 仍约 `-0.053ns`，不能把 T4C 子任务 PASS 越级为 200MHz 完成。

## 收尾结论

- `final_result`: T4C completed；切点功能与结构证据闭合，但父目标未完成。
- `notes`: fresh STA 已证明目标 D-cache 家族退出 top40；下一切片为 T4D PLIC priority WARL 收窄。
