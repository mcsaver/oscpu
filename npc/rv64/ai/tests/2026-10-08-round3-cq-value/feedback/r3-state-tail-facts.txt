# LOCAL-TAIL-FACTS：R3 LSU state[18][2] 尾段只读复核

范围：仅核对冻结 B/R3 RTL 和本轮已经完成的实际路径报告；未运行新的综合/STA、未修改 RTL/SDC、未选择下一轮架构。供原网页 Pro 解释已测结果。

## 首要事实

**`state_q[18][2]` 的局部状态事件、next_state、cancel_free 和时钟边沿状态更新块在 B/R3 中逐字相同。** 不能把本轮尾段退化描述成“重写了 state 转移块而使它更深”。综合后的尾段确实改变，但其源级归因尚未通过单开关物理消融证明。

- B 冻结源：`/home/lyg/PA/ysyx-workbench/npc/rv64/build/ai-r3-20261008/baseline-vsrc/lsu/R64Lsu.v`，第 1713–1822 行。
- R3 冻结源：`/home/lyg/PA/ysyx-workbench/npc/rv64/build/ai-r3-20261008/candidate-vsrc/lsu/R64Lsu.v`，第 1803–1912 行。
- 这段完整 110 行状态控制前段的 UTF-8 SHA-256，两版均为 `14ec027f71a7a9139054d43d304f4e494cca849328a1e47960acbeb2075d6e26`。完整内容附后。这里没有声称整个 R64Lsu 文件或整个 gen_owner_state generate 后续数据更新都不变。

## fire 的真实含义与状态更新结构

本路径的 `core_backend_execute_lsu_fire_o[1]` 是 **Execute→LSU 的 operand bind/admission 握手**，连接到 `R64Lsu.in_fire_i[1]`；它不是 downstream RAM request 的 `mfire_w`。CoreTop 中 B 第347/570行、R3 第375/602行连接同一 `lsu_fire`，Memory 中 B 第281行、R3 第287行继续传入 `in_fire_i`。

两版相同的逻辑为：

1. `bind_mask_w[z][owner] = in_fire_i[z] && !rst_i && !killed_w[owner] && slot_match && alive_q && state_q==NEW && !bound_q && full_tag_match`，随后 `admit_w[z] = bind_mask_w[z][owner]`。位置：B 1724–1728，R3 1814–1818。
2. `admit_w` 一方面参与 `state_events_w` 的写入使能，另一方面选择 `admission_state_w`：普通 admission 为 NEW=1，指定 misalignment/FP 条件为 DONE=5。它还影响同一 always 中的 bound/checked 更新。因此 fire 到 state bit2 的路径可处在状态数据或 hold/update 选择逻辑中，不能仅用一个状态值表达式代替实际综合路径。
3. 状态寄存器优先级为 `rst→FREE；否则 cancel_free→FREE；否则 |state_events→next_state；否则保持`。`cancel_free` 仍保留已有 translation/memory 已发事务的排空条件。
4. 两版原本就有 `state_events_w = events_w & ~(26'b11 << 8)`，将 downstream `mem_start_w` 从 MEMORY→MEMORY 的无效重写中排除。该做法不是 R3 新增，不能把本次收益或尾段变化归因于刚加入这条 mask。

## 直接相关的外部输入和相邻结构改动

| 项目 | B | R3 | 冻结源码位置 |
|---|---|---|---|
| per-owner killed | `flush_i || kill_mask_i[tag_q[g][ROB_W-1:0]]` | `flush_i || owner_cancel(tag, candidates, canonical, active)`，local 模式取 `active && candidates[tag]` | B R64Lsu.v:153；R3:184，函数:99–105 |
| LSU partial publication | 使用原 canonical kill/cancel 输入 | ROB 另导出 `lsu_cancel_active_o=publication_kill_w` 和 `lsu_cancel_candidates_o=valid_q & plan_younger_q`；CoreTop 选择这些输入交给 memory | R3 R64Rob.v:255–256；R64CoreTop.v:594–596 |
| canonical kill 保持 | `valid_q[k] && (flush_i || publication_kill_w && plan_younger_q[k])` | 同表达式仍保留；未删 owner 资格 | B R64Rob.v:253；R3:262 |
| full flush 生成 | 旧 Commit 事件表达式 | 新 publish_q 的当前边界投影，`full_flush_o = !rst_i && publish_q`（启用模式） | R3 R64Commit.v:74,99,139–141 |
| admission/reserve 周围新增数据 | 无 value ticket | entry 在 reserve_mask 下捕获 8-bit ticket；raw/forward packet 和 CQ 传播 ticket | R3 R64Lsu.v:167–175,1311–1313,1385–1399,1531–1533,1567–1575 |
| 新 CQ 消费者 | 经既有后续路径消费 | CQ short_accept[5:4] 成为新 Issue early valid 和 RR 资格/数据来源 | R3 R64Backend.v:195–196 等；详细 delta 附件包含全部改动 |

这些事实表明：虽然局部 state 更新文本不变，`killed_w` 的组合结构、full_flush 驱动及其他共享输入/负载已经变化，整个 LSU 和相邻模块经过重新映射。R3 source 中 owner-denial 一致性断言位于 R64Lsu.v:108–114；它要求启用时 full-flush 与 partial 合并后的 owner 拒绝集合和 canonical 一致。断言及既有测试不是单项 PPA 消融证据。

## 同一实际路径的物理证据

此处引用两版各自到同一 D 位的最差实际路径。前段 B 经过 ROB cancel_candidates[15]，R3 经过 [9]，所以它们不是固定同一 cancel-bit 路径；没有拼接不同路径的阶段最大值。

| 指标 | B | R3 |
|---|---:|---:|
| state[18][2] D slack / ns | −1.855450273 | −2.127002716 |
| lsu_fire[1] arrival / ns | 2.224713087 | 2.072791338 |
| state D arrival / ns | 2.771011353 | 3.043039560 |
| state D required / ns | 0.915560961 | 0.916036963 |
| fire→D 尾段到达时间差 / ns | 0.546298266 | 0.970248222 |
| fire 之后、D 之前的实际组合 cell arc 数（含最后 buffer） | 10 | 13 |
| 这些逐 cell 增量之和 / ns | 0.546298125 | 0.970248134 |
| 同段 reported net 增量总和 / ns | 0 | 0 |

该同 bit slack 退化为 271.552443 ps；fire→D 尾段增加 423.949956 ps，但 fire 本身提前 151.921749 ps。逐 cell 增量求和与端点到达差的微小差额来自工具浮点及逐点打印舍入。zero net 是未提取互连的时序模型，不能解释成真实布线无延迟。

还须保留三个层次：整核 WNS 只退化 7.698297 ps；B 全 state D 族最差 −2.060335159 ns，距旧全局仅 58.969260 ps；同 bit 的 271.552443 ps 不是整核退化值。

### B fire 之后的全部已测组合单元

| 顺序 | 实际 cell 输出 pin | 类型 | cell 增量 / ns | arrival / ns | 输出 fanout |
|---:|---|---|---:|---:|---:|
| 1 | `core_memory_unit_lsu__052017_/Y` | NAND3X0P5H7L | 0.067358784 | 2.292071819 | 4 |
| 2 | `core_memory_unit_lsu__052018_/Y` | NOR2X0P5H7L | 0.072501786 | 2.364573717 | 2 |
| 3 | `core_memory_unit_lsu__052040_/Y` | NAND4X0P5H7L | 0.054659832 | 2.419233561 | 1 |
| 4 | `core_memory_unit_lsu__052041_/Y` | OR2X1P4H7L | 0.079495966 | 2.498729467 | 5 |
| 5 | `core_memory_unit_lsu__098167_/Y` | NAND4BX0P5H7L | 0.037842397 | 2.536571980 | 2 |
| 6 | `core_memory_unit_lsu__098208_/Y` | NOR4X0P5H7L | 0.027559066 | 2.564131021 | 1 |
| 7 | `core_memory_unit_lsu__098219_/Y` | NAND4X1P4H7L | 0.050224714 | 2.614355803 | 5 |
| 8 | `core_memory_unit_lsu__098231_/Y` | OAI211X1P4H7L | 0.044508841 | 2.658864498 | 2 |
| 9 | `core_memory_unit_lsu__106035_/Y` | OA221X1P4H7L | 0.075466745 | 2.734331369 | 1 |
| 10 | `core_memory_unit_lsu__106036_/Y` | BUFX5H7L | 0.036679994 | 2.771011353 | 1 |

### R3 fire 之后的全部已测组合单元

| 顺序 | 实际 cell 输出 pin | 类型 | cell 增量 / ns | arrival / ns | 输出 fanout |
|---:|---|---|---:|---:|---:|
| 1 | `_1656058_/Y` | NOR3BX0P5H7L | 0.127367452 | 2.200158834 | 4 |
| 2 | `_1656059_/Z` | NOR2BX1P4H7L | 0.090437219 | 2.290596008 | 5 |
| 3 | `_1656060_/Y` | NAND3X0P5H7L | 0.084094070 | 2.374690056 | 5 |
| 4 | `_1656094_/Y` | NOR4X0P5H7L | 0.194419816 | 2.569109917 | 5 |
| 5 | `_1656116_/Y` | AOI21X0P5H7L | 0.077896357 | 2.647006273 | 3 |
| 6 | `_1656173_/Y` | NAND2BX0P5H7L | 0.069783516 | 2.716789722 | 2 |
| 7 | `_1703007_/Z` | NOR2BX1P4H7L | 0.051585626 | 2.768375397 | 2 |
| 8 | `_1703008_/Y` | NOR3BX0P5H7L | 0.038729019 | 2.807104349 | 2 |
| 9 | `_1703045_/Y` | NAND4X0P5H7L | 0.035050631 | 2.842154980 | 1 |
| 10 | `_1703046_/Y` | OR3X1H7L | 0.063148603 | 2.905303717 | 6 |
| 11 | `_1710214_/Y` | NAND4X0P5H7L | 0.052849725 | 2.958153248 | 1 |
| 12 | `_1710215_/Y` | OA211X1P4H7L | 0.050776273 | 3.008929729 | 1 |
| 13 | `_1710216_/Y` | BUFX3P5H7L | 0.034109827 | 3.043039560 | 1 |

R3 的 `_1656094_/Y`（NOR4X0P5H7L）单级增量 0.194419816 ns、fanout 5，是此尾段里最大的一段 cell 增量。B 对应“第几级”不具有一对一 RTL 等价映射；不得把不同布尔分解的节点按序号硬配成同一个逻辑事件。

## 能下的结论与不能下的结论

- 已证：局部状态更新文本相同；其取消输入表达和相邻结构不同；同 bit 实际最差尾段映射从 10 个 cell arc 变 13 个；同 bit setup 确实退化，不能只称作全局榜首换了端点。
- 合理但未独立验证的解释：取消信号因式分解、共享逻辑及负载变化影响了 ABC 布尔分解/映射，导致这个未改源块的末端路径变差。它是待验证解释，不是已完成的因果归因。
- 尚不能断言：单独 early-CQ、单独 local publish、单独 partial separation 哪一项造成这段代价；哪一个源级子表达式独占某个映射门；该 reset 启动路径是否能在任意正常运行场景功能激活；更换特定结构必然改善综合结果。已有组合网表和程序计数不能替代这些物理消融或形式证明。
- 本补充不提出新的 RTL 方案，也不据此选择下一轮架构。

## 原始证据

- `[RESULT.json](/home/lyg/PA/ysyx-workbench/npc/rv64/results/ai-r3-20261008/physical-diagnostics/RESULT.json)` 中 `state_pair` 含两版所有实际路径点及精确边界。
- [B 同位全时钟展开路径](/home/lyg/PA/ysyx-workbench/npc/rv64/results/ai-r3-20261008/physical-diagnostics/baseline-state/r3-pair_state_18_2-max.rpt)。
- [R3 global32 全时钟展开路径](/home/lyg/PA/ysyx-workbench/npc/rv64/results/ai-r3-20261008/physical-diagnostics/candidate/r3-global_top32-max.rpt)，第一条为 state[18][2]。
- [完整物理报告](/home/lyg/PA/ysyx-workbench/npc/rv64/ai/tests/2026-10-08-round3-cq-value/PHYSICAL.md)。

## 附录：两版逐字相同的完整状态控制源块

以下为上述 110 行原块，直接取冻结源，未为说明修改逻辑。

```verilog
  // Each physical entry has a bounded local state controller. Events are
  // mutually exclusive before explicit cancellation; no inferred multiwrite RAM.
  genvar owner;
  generate
    for (owner = 0; owner < ENTRIES; owner = owner + 1) begin : gen_owner_state
      localparam [INDEX_W-1:0] SLOT = owner[INDEX_W-1:0];
      wire [1:0] admit_w, reserve_w, trans_start_w, trans_end_w, mem_start_w, mem_end_w,
          forward_end_w, select_mem_w, fault_end_w, drain_w, local_fault_w;
      wire [2:0] admission_state_w[0:1], translation_state_w[0:1], response_state_w[0:1];
      for (z = 0; z < 2; z = z + 1) begin : gen_event
        assign reserve_w[z] = reserve_mask_w[z][owner];
        assign bind_mask_w[z][owner] = in_fire_i[z] && !rst_i && !killed_w[owner] &&
            in_slot_i[z*INDEX_W+:INDEX_W] == SLOT && alive_q[owner] && state_q[owner] == NEW &&
            !bound_q[owner] && tag_q[owner] == in_tag_i[z*TAG_W+:TAG_W];
        assign admit_w[z] = bind_mask_w[z][owner];
        assign trans_start_w[z] = trans_owner_select_w[z][owner];
        assign trans_end_w[z] = translation_response_mask_w[z][owner];
        assign mem_start_w[z] = mfire_w[z] && physical_slot_w[z] == SLOT;
        assign mem_end_w[z] = mem_rsp_valid_i[z] && mem_rsp_ready_o[z] &&
            input_response_live_w[z] && input_response_slot_w[z] == SLOT;
        assign drain_w[z] = mem_rsp_valid_i[z] && mem_rsp_ready_o[z] && !input_response_live_w[z] &&
            input_response_slot_w[z] == SLOT;
        assign forward_end_w[z] = forward_take_w[z] && query_slot_w[z] == SLOT;
        assign select_mem_w[z] = mem_owner_select_w[z][owner];
        assign local_fault_w[z] = admission_check_mask_q[z][owner];
        assign fault_end_w[z] = fault_capture_mask_w[z][owner];
        assign admission_state_w[z] =
            ((input_misaligned_w[z] &&
              (input_func_w[z][7] || (translate_active_i && input_cross_page_w[z]))) ||
             (input_func_w[z][6] && !input_func_w[z][7] && !fp_enable_i)) ? 3'd5 : 3'd1;
        assign translation_state_w[z] = (!alive_q[owner] || killed_w[owner]) ?
            3'd0 : ((tr_fault_i[z] || (misaligned_q[owner] && tr_class_i[z*2+:2] == 2)) ?
                    3'd5 : (translation_query_mask_w[z][owner] ? 3'd4 : 3'd3));
        assign response_state_w[z] = (alive_q[owner] && !killed_w[owner] && side_effect_w[owner] &&
                                      !mem_rsp_error_i[z]) ? 3'd7 : 3'd0;
      end
      wire prepared_event_w = prepared_take_w && prepared_slot_q == SLOT;
      wire store_event_w = store_response_fire_w && mem_store_rsp_token_i == SLOT;
      wire commit_event_w = state_q[owner] == RETIRE &&
          ((commit_fire_i[0] && tag_q[owner] == commit_tag_i[0+:TAG_W]) ||
           (commit_fire_i[1] && tag_q[owner] == commit_tag_i[TAG_W+:TAG_W]));
      wire release_alive_w = (|fault_end_w) || (|forward_end_w) || commit_event_w || (|drain_w) ||
          (mem_end_w[0] && (!side_effect_w[owner] || mem_rsp_error_i[0])) ||
          (mem_end_w[1] && (!side_effect_w[owner] || mem_rsp_error_i[1])) ||
          (store_event_w && (!store_response_live_w || mem_store_rsp_error_i));
      always @(posedge clk_i) begin
        if (rst_i) alive_q[owner] <= 0;
        else if ((state_q[owner] != FREE && killed_w[owner]) || release_alive_w)
          alive_q[owner] <= 0;
        else if (|reserve_w) alive_q[owner] <= 1;
      end
      wire pin_release_w = state_q[owner] == PINNED && !source_pin_w[owner];
      wire [25:0] events_w = {
        reserve_w,
        local_fault_w,
        pin_release_w,
        drain_w,
        commit_event_w,
        store_event_w,
        prepared_event_w,
        admit_w,
        trans_start_w,
        trans_end_w,
        mem_start_w,
        mem_end_w,
        forward_end_w,
        select_mem_w,
        fault_end_w
      };
      // A physical issue already owns MEMORY; its handshake only sets issued/effect state.
      // Do not feed downstream ready back into a MEMORY-to-MEMORY state rewrite.
      wire [25:0] state_events_w = events_w & ~(26'b11 << 8);
      wire [2:0] next_state_w =
          ({3{|reserve_w}} & 3'd1) |
          ({3{local_fault_w[0]}} & (checked_cause_w[0] != 0 ? 3'd5 : 3'd1)) |
          ({3{local_fault_w[1]}} & (checked_cause_w[1] != 0 ? 3'd5 : 3'd1)) |
          ({3{admit_w[0]}} & admission_state_w[0]) |
          ({3{admit_w[1]}} & admission_state_w[1]) |
          ({3{|trans_start_w}} & 3'd2) |
          ({3{trans_end_w[0]}} & translation_state_w[0]) |
          ({3{trans_end_w[1]}} & translation_state_w[1]) |
          ({3{(|select_mem_w) || prepared_event_w}} & 3'd4) |
          ({3{mem_end_w[0]}} & response_state_w[0]) |
          ({3{mem_end_w[1]}} & response_state_w[1]) |
          ({3{store_event_w && store_response_live_w && !mem_store_rsp_error_i}} & 3'd7) |
          ({3{commit_event_w && source_pin_w[owner]}} & 3'd6);
      wire cancel_free_w=state_q[owner]!=FREE&&killed_w[owner]&&
     !((state_q[owner]==TRANSLATING&&tr_issued_q[owner])||(state_q[owner]==MEMORY&&mem_issued_q[owner]));
      always @(posedge clk_i) begin
        if (rst_i) begin
          state_q[owner] <= FREE;
          tag_q[owner] <= 0;
          checked_q[owner] <= 0;
          bound_q[owner] <= 0;
        end else begin
          if (|reserve_w) begin
            bound_q[owner]   <= 0;
            checked_q[owner] <= 0;
          end else if (|admit_w) begin
            bound_q[owner]   <= 1;
            checked_q[owner] <= !trigger_active_w;
          end else if (killed_w[owner]) checked_q[owner] <= 0;
          else if (|local_fault_w) checked_q[owner] <= 1;
          if (cancel_free_w) state_q[owner] <= FREE;
          else if (|state_events_w) state_q[owner] <= next_state_w;
          if (|reserve_w)
            tag_q[owner] <= ({TAG_W{reserve_w[0]}} & reserve_tag_i[0+:TAG_W]) |
                ({TAG_W{reserve_w[1]}} & reserve_tag_i[TAG_W+:TAG_W]);
        end
      end
```
