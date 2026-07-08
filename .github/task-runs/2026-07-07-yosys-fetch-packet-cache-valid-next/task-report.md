# 2026-07-07 Yosys Fetch Packet Cache Valid Next

## 目标

承接 `.github/memory/known-issues.md` 的 `[112]`：`NpcTop` full stdcell synthesis 的首个阻塞点在 `OooFetchPacketCache`，Yosys fine/simplemap 会把 `valid_next_r[invalidate_idx]` 动态位写展开成巨量 shift/mux。本轮先只处理 `OooFetchPacketCache` 的 valid next-state 结构，不推进 Ubuntu/rootfs boot，也不宣称 STA-ready。

## RTL 推导摘要

### 需求

- 功能目标：保持 fetch packet cache 的组合 lookup、fill、store/fence 定点 invalidate、reset/clear 语义不变。
- 端口边界：不改 `OooFetchPacketCache` 端口，不改 `OooFetchAxiBridge` 调用方式，不改 `fill_valid_i` / `invalidate_valid_i` 时序。
- 时序目标：`valid_q` 仍在 `posedge clk` 更新；payload arrays 仍只在有效 fill 时写入。
- 综合目标：消除 4096-bit vector 的动态索引写，避免 Yosys 将 `valid_next_r` 建模成大规模动态 shift/mux。
- Out-of-scope：不做 RAM 化、不改 cache 容量、不改 SMC/fence.i 协议、不改 PMP/ITLB/cache hit 组合路径。

### 协议规则

- Lookup 是组合读：`lookup_hit_o = context_hit && pc_tag_match && !lookup_invalidated_w`。
- Fill 是时钟沿写：`fill_valid_i && !fill_invalidated_w` 时写 payload，并在对应 entry 置 valid。
- Invalidate 是同拍 next-state：7 个候选 index `{base-6, base-4, base-2, base, base+2, base+4, base+6}` 命中时清对应 valid。
- 同拍 fill 与 invalidate：若 fill 自身被 `fill_invalidated_w` 覆盖，则不得新建 valid；若 fill 与旧命中 entry alias 但 fill 自身不被覆盖，则 fill 写入并保持 valid。

### 状态机

本模块无新增 FSM。状态仍为：

- `valid_q[ENTRY_COUNT-1:0]`
- `paging_q/priv_q/satp_q/pc_q/inst*_q/resp*_q` payload arrays

复位/clear：`valid_q <= 0`，payload don't-care。
正常推进：只在少数候选 invalidate 命中时对对应 `valid_q[idx]` 清零；未被覆盖的 fill 最后置位对应 `valid_q[fill_idx]`。payload 仅在有效 fill 写入。

### 不变量

- I1：`rst || clear_i` 后所有 entry invalid，旧 payload 不能命中。
- I2：`valid_q[idx]=0` 时 lookup 不得 hit。
- I3：invalidate 只清 7 个候选 index 中经过 `same_fetch_window(pc_q[candidate], invalidate_addr_i)` 复验的 entry。
- I4：同拍 store 覆盖 fill packet 时，fill 不得建立 hit。
- I5：fill packet 未被 store 覆盖时，即使同 index 旧 entry 被 invalidate，fill 后该 index 仍 valid 且 payload 为新 fill。

### 数据通路拓扑

- 保留 7 个候选 invalidate hit wire，继续只对候选 entry 做 `same_fetch_window` 复验。
- 最终落地方案删除组合 `valid_next_r/valid_next_w`，在 `always @(posedge clk)` 内直接对 7 个候选命中 bit 清零。
- `fill_valid_i && !fill_invalidated_w` 的置位保持在 invalidate 清零之后，保留原有“同拍 fill 自身未被覆盖时 fill 胜出”的语义。
- 负实验：尝试过 per-entry generate，把动态 vector 写改成每 entry 的常量 index decode；功能可过，但 OOC coarse 变成 `100534 cells`、`30716 $eq`、`4096 $sdffe`，full stdcell 仍不友好，已放弃。
- 最终结构的 OOC coarse 统计降为 `245 cells`、`4 $eq`、`1 $sdff`、`8 $mem_v2`，确认原动态 next-state/simplemap 爆炸已消除。

## 验证计划

- `make -C npc/rv64/testbench TESTS="tb_ooo_fetch_packet_cache" run`
- `make -C npc/rv64 check-rtl-style`
- OOC Yosys smoke：`make -C npc/rv64 syn STA_DESIGN=OooFetchPacketCache STA_CLK_FREQ_MHZ=100 ...`
- 顶层 coarse 回归：`make -C npc/rv64 syn STA_CLK_FREQ_MHZ=100 STA_SYNTH_STOP_AFTER_COARSE=1`

## 执行结果

- RTL 改动：`npc/rv64/vsrc/cache/OooFetchPacketCache.v` 的 `valid_q` 更新改为 clocked direct bit update；端口、payload array、lookup/fill/invalidate 协议未改。
- 功能验证：`make -C npc/rv64/testbench TESTS="tb_ooo_fetch_packet_cache" run` PASS，结果目录 `npc/rv64/perf/results/20260707-235454/module-testbench/`。
- 静态/构建验证：`make -C npc/rv64 check-rtl-style` PASS；`make -C npc/rv64 lint` PASS；`make -C npc/rv64 -j2` PASS。
- OOC coarse：`make -C npc/rv64 syn STA_DESIGN=OooFetchPacketCache STA_CLK_FREQ_MHZ=100 STA_SYNTH_STOP_AFTER_COARSE=1` PASS，`synth_check` 为 0 problems，统计见 `evidence/syn-100mhz/synth_stat.fetch-cache.clocked-coarse.txt`。
- OOC full stdcell：`timeout 600s make -C npc/rv64 syn STA_DESIGN=OooFetchPacketCache STA_CLK_FREQ_MHZ=100 STA_SYNTH_PUBLIC_AUTONAME=0` 仍 timeout；日志已从原先动态 valid next-state 爆炸推进到 `MEMORY_MAP/TECHMAP/ABC`，最后停在 ABC 抽取/映射阶段。
- 顶层 coarse 回归：`timeout 900s make -C npc/rv64 syn STA_CLK_FREQ_MHZ=100 STA_SYNTH_STOP_AFTER_COARSE=1` PASS，`synth_check` 为 0 problems；产物 `NpcTop.netlist.v` 8.3M/248839 行、`NpcTop.netlist.v.il` 45M/726380 行、`NpcTop.netlist.v.json` 90M。
- 工程流程验证：`git diff --check` PASS；`scripts/agent-e2e.sh --profile npc-dev --task-slug yosys-fetch-packet-cache-valid-next-npc-dev --stop-on-fail` PASS；`scripts/agent-e2e.sh --profile yosys-sta --task-slug yosys-fetch-packet-cache-valid-next-yosys-sta --stop-on-fail` PASS；`scripts/agent-e2e.sh --guard --guard-mode strict` PASS。

## 当前结论

本轮已经完成 `OooFetchPacketCache` 第一处 Yosys 表达式级阻塞的结构优化：动态 4096-bit valid next-state 不再是 full stdcell 的首个简单爆点。但该模块若继续做 full stdcell，仍会因为 4096-entry payload/valid 存储在 `memory_map` 后进入超大门级/ABC 映射压力区。因此下一步不应继续微调 valid 表达式，而应转向 fetch packet cache 存储策略：例如容量/分片评估、综合期 memory blackbox/macro 策略、或将 payload/valid 拆成更明确的 SRAM/寄存器 bank 边界；并并行处理 `PmpChecker` 的 OOC ABC hotspot。
