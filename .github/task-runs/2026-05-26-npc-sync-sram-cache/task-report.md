# Task Report

## 基本信息

- `task_id`: `2026-05-26-npc-sync-sram-cache`
- `task_slug`: `npc-sync-sram-cache`
- `graph_template`: `npc-sim-regression`
- `graph_mode`: `static`
- `status`: `completed`
- `owner`: `Codex`
- `started_at`: `2026-05-26`
- `updated_at`: `2026-05-26`

## 任务目标

- `source_request`: 修正 cache 组合 hit 路径，使其更遵守外部 SRAM 读写规则。
- `goal`: `npc/single` 与 `npc/soc` 的 ICache/DCache 不再依赖 SRAM 组合读命中；cache array 改为同步读、时钟沿写，lookup 结果在发出读地址后一拍消费。
- `scope`: 覆盖 `npc/single` 和 `npc/soc`；`npc/soc` 保留 ICache 对 MROM 的 cacheable 特例。

## 选图说明

- `selected_template`: `npc-sim-regression`
- `why_this_graph`: 改动落在 NPC single cache、流水等待路径和模块 testbench，需要 lint、RTL testbench、pipe/stage pipe、Verilator build 与 AM on NPC 回归形成证据链。
- `dynamic_nodes_added`: 无
- `why_dynamic_nodes_were_needed`: 无

## RTL 推导摘要

### 需求

- 功能目标：cache 行为仍保持 ICache 取指、DCache load/store、write-back/write-allocate、dirty flush/fence.i 正确。
- 时序目标：CPU 请求地址不能在同一拍通过 SRAM array 组合读、tag compare、data mux 直接形成 hit response。
- SRAM 目标：array wrapper 表达同步读、时钟沿写；同一 transaction 不安排读写同一个 1RW/2R1W wrapper。
- 范围外：不改变外部 AXI/miss-side 协议，不处理 reset 全阵列 clear 到真实 SRAM init scan 的进一步替换。

### 协议规则

- `S_IDLE` 只在 CPU request handshake 时发出 SRAM 读地址并锁存请求。
- `S_LOOKUP` 消费上一拍 SRAM 输出，完成 tag compare、hit/miss 判定和响应/补线启动。
- ICache refill 完整写完 line 后进入 `S_REFILL_LOOKUP` 重新发读，再回 `S_LOOKUP` 命中新 line。
- DCache store hit 与 store allocate 都先读旧 word，再在独立周期用 byte mask 合并写回，避免读写同拍依赖。
- DCache dirty victim/writeback 与 flush 扫描在需要读取数据 word 前显式发出 data SRAM 读。

### 状态机

- ICache 新增 `S_REFILL_LOOKUP`，消除 fill 最后一拍后直接用新写数据 lookup 的假设。
- DCache 新增 `S_REFILL_LOOKUP`、`S_STORE_ALLOC_READ`、`S_FLUSH_READ`，把 refill lookup、store allocate read-modify-write、flush meta/data read 拆成同步 SRAM 友好的阶段。
- DCache dirty miss 在 `S_LOOKUP` 判定后同拍发 victim word0 的 data read，下一状态开始 AW/W/B；后续 word 在 B 响应后提前发下一 word read。

### 不变量

- `cpu_rsp_valid_o` 只由 `S_RESP` 产生，不再有 `S_IDLE` 组合 hit/misaligned response。
- ICache/DCache hit 至少晚于 request handshake 一拍，前端和 MEM 控制面通过既有 pending/ready 路径接收。
- fill 写 array 的周期不同时发 lookup 读；store update 写 data/dirty 的周期不同时依赖新读数据。
- `fence.i` dirty flush 仍必须先写回 DCache dirty line，再 invalidate I/D cache。

### 数据通路

- `Sram1Rw` 和 `Sram2R1W` 输出寄存化，`rd*_data_o` 来自上一拍采样结果。
- ICache 的 tag/data/valid read index 来自 `lookup_issue_addr_w`，只在 request fire 或 refill replay 时使能读。
- DCache 的 meta/data read enable 按 lookup、store allocate read、writeback word read、flush read 分离，数据 SRAM 地址用当前需要消费的 word 选择。
- `NpcSimTop` 性能事件改为观察 `S_LOOKUP` 阶段的注册请求和 `lookup_hit_w`，不再引用已删除的 `cur_*` 组合命中信号。

## 节点概览

| node_id | owner_agent | status | inputs | outputs | evidence |
| ------- | ----------- | ------ | ------ | ------- | -------- |
| recall | Codex | completed | AGENTS、Copilot、memory、NPC study | 约束与调用链 | 定位 `Sram1Rw/Sram2R1W` 组合读与 I/D cache `cur_*` hit 路径 |
| implement | Codex | completed | RTL 推导 | 同步 SRAM wrapper、ICache/DCache FSM、testbench/pipe 期望更新 | I/D cache 不再同拍 hit response，SoC MROM cacheable 特例保留 |
| verify | Codex | completed | 修改后的 `npc/single` 与 `npc/soc` | lint、module tests、pipe test、build、AM/soc smoke | 见下方证据 |
| record | Codex | completed | 本轮结论 | task-run 与 memory 更新 | 本文件、`dispatch-log.md`、memory 条目 |

## 关键产物

- `artifacts`: `npc/single/vsrc/common/Sram1Rw.v`、`npc/single/vsrc/common/Sram2R1W.v`、`npc/single/vsrc/cache/ICache.v`、`npc/single/vsrc/cache/DCache.v`、`npc/soc/vsrc/common/Sram1Rw.v`、`npc/soc/vsrc/common/Sram2R1W.v`、`npc/soc/vsrc/cache/ICache.v`、`npc/soc/vsrc/cache/DCache.v`
- `related_tests`: `npc/single/testbench/tests/tb_icache.sv`、`npc/single/testbench/tests/tb_dcache.sv`、`npc/single/testbench/tests/stage_pipe_test.sv`、`npc/soc/testbench/tests/tb_icache.sv`、`npc/soc/testbench/tests/tb_dcache.sv`、`npc/soc/testbench/tests/stage_pipe_test.sv`
- `logs_or_traces`: `/tmp/npc-sync-sram-cache-tests`、`/tmp/npc-sync-sram-pipe-tests`、`/tmp/npc-sync-sram-module-tests`、`/tmp/npc-soc-sync-sram-cache-tests2`、`/tmp/npc-soc-sync-sram-pipe-tests`
- `linked_memory_updates`: `.github/memory/project-status.md`、`.github/memory/modules/npc.md`

## 收尾结论

- `final_result`: `npc/single` 与 `npc/soc` cache 已切到同步 SRAM 读语义，组合 hit 路径移除；命中延迟按同步 SRAM 重新通过 pending/response 路径处理。
- `evidence_summary`: `make -C npc/single lint` PASS；single ICache/DCache 专项 PASS；single pipe/stage pipe PASS；single 模块 testbench 27/27 PASS；`make -C npc/single -j4` PASS；`riscv32-npc` 的 `add/load-store/fence-i` GOOD TRAP；`make -C npc/soc lint` PASS；SoC ICache/DCache 专项 PASS；SoC pipe/stage pipe PASS；`make -C npc/soc soc-lint` PASS；`make -C npc/soc -j4` PASS；`make -C npc/soc soc` PASS；`soc-run` smoke GOOD TRAP；`git diff --check` PASS。
- `notes`: `Sram1Rw/Sram2R1W` 仍保留 behavioral clear loop；若最终替换为真实 SRAM macro，还需要单独处理 reset/invalidate 初始化策略。
