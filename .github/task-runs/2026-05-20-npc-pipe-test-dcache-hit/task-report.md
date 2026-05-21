# 2026-05-20 NPC pipe_test 与 DCache 命中读气泡优化

## 目标

- 在 `npc/single/testbench` 增加流水线级微基准 `pipe_test`，结果保存到 `npc/single/perf/results/<timestamp>/pipe-test/`。
- 用 `pipe_test` 提取流水线气泡，优先定位无用 stall。
- 对有明确证据的无用等待做首个 RTL 优化闭环。

## 基线证据

- 命令：`make -C npc/single/testbench pipe_test PIPE_EXPECT_LOAD_HIT_ZERO=0`
- 结果目录：`npc/single/perf/results/20260520-130540/pipe-test`
- 指标：
  - `mem_stage_load_miss_wait_cycles=51`
  - `mem_stage_dcache_load_hit_wait_cycles=2`
  - `mem_stage_store_write_through_wait_cycles=5`
  - `id_stage_load_use_bubbles=1`
  - `removable_load_hit_bubbles=2`

## 最终结果

- 新增 `pipe_test`：
  - `npc/single/testbench/tests/pipe_test.sv`
  - `make -C npc/single/testbench pipe_test`
  - 默认结果：`npc/single/perf/results/<timestamp>/pipe-test/summary.txt`
- RTL 优化：
  - `DCache.v` 对 cacheable load hit 增加 `S_IDLE` 组合返回。
  - `MemoryStageControl.v` 接受 `req_fire && lsu_rsp_valid_i` 同周期完成。
- 最终 `pipe_test`：`npc/single/perf/results/20260520-131123/pipe-test`
  - `mem_stage_load_miss_wait_cycles=51`
  - `mem_stage_dcache_load_hit_wait_cycles=0`
  - `mem_stage_store_write_through_wait_cycles=5`
  - `id_stage_load_use_bubbles=1`
  - `removable_load_hit_bubbles=0`
- 回归验证：
  - `make -C npc/single/testbench run`，结果目录 `npc/single/perf/results/20260520-130808/module-testbench`，21/21 PASS。
  - `make -C npc/single/testbench pipe_test`，结果目录 `npc/single/perf/results/20260520-131123/pipe-test`，PASS。
  - `make -C npc/single lint`，PASS。
  - `make -C am-kernels/tests/cpu-tests run ARCH=riscv32-npc ALL=load-store`，PASS。

## RTL 推导摘要

### 阶段 1：需求

- 功能目标：让 cacheable DCache load hit 在 `S_IDLE` 接收请求的同一周期组合返回，并让 `MemoryStageControl` 能消费同周期 req/rsp，消除命中读 MEM 级等待。
- 输入输出端口：`DCache` 与 `MemoryStageControl` 端口不变；仍使用 `clk/rst` 同步复位与现有 valid/ready、rsp valid/error 协议。
- 性能约束：load miss、uncached、store 维持原状态机；cacheable load hit 从基线 2 个等待周期降为 0 个等待周期。
- 上下游边界：`MemoryStage`/`LSU` 产生 CPU 侧访存请求，`DCache` 返回响应，`PipelineControl` 只消费 `mem_response_i` 推进 EX/MEM 和 MEM/WB。
- 不在范围：不改 write-through store、miss fill、uncached 访问、load-use 冒险、分支预测或流水线寄存器结构。

### 阶段 2a：协议规则

- CPU 侧请求在 `cpu_req_valid_i && cpu_req_ready_o` 时被接受；`DCache` 仅在 `S_IDLE` 可接受新请求。
- 新增允许：当 `S_IDLE` 遇到 cacheable read hit 时，`cpu_rsp_valid_o` 可在同一周期组合拉高，且 `cpu_rsp_error_o=0`。
- 对 miss、store、uncached 访问，仍按原状态机打拍并经内存侧请求返回。
- `MemoryStageControl` 的响应条件扩展为 pending 响应或同周期 `req_fire && lsu_rsp_valid_i`；同周期响应不得置起 `mem_pending_q`。
- 错误路径仅来自 `lsu_rsp_error_i`；combo load hit 无外部错误。

### 阶段 2b：状态机

- `DCache.S_IDLE`：
  - cacheable read hit：组合输出数据与 valid，时钟沿后保持 `S_IDLE`。
  - 其它请求：锁存 `req_*`，按原逻辑进入 `S_LOOKUP`。
- `DCache.S_LOOKUP/S_FILL*/S_STORE*/S_UNCACHED*/S_RESP`：保持原语义。
- `MemoryStageControl.mem_pending_q`：
  - reset/clear：清零。
  - pending 响应或同周期响应：清零。
  - 请求发出且未同周期响应：置一。
  - 无事务：保持。

### 阶段 2c：不变量

- 任意周期 `mem_pending_q` 最多表示一个已发未回的 LSU 请求。
- DCache 组合响应只允许出现在 `S_IDLE && cpu_req_valid_i && !cpu_req_write_i && cacheable && hit`。
- 组合响应不得发出内存侧请求，不得修改 cache 内容，不得把 store/miss/uncached 误判为命中。
- store 仍必须经 write-through 内存响应后才更新命中行，保持外部可见顺序。
- `response_o` 为 1 时，`fault_o` 必须等于该响应对应的 `lsu_rsp_error_i`。

### 阶段 2d：数据通路约束

- `DCache` 新增当前请求地址的 index/tag/word/data 组合网络，和既有 `req_*` 打拍查询路径并存。
- `cpu_rsp_*` 由 “当前请求组合命中” 与 “`S_RESP` 打拍响应” 二选一输出。
- `MemoryStageControl` 新增 `pending_rsp_w` 与 `same_cycle_rsp_w`，响应 mux 只影响 pending 生命周期，不改 LSU 地址/数据 lane。
- 关键路径为 DCache tag/data 读出到 `cpu_rsp_*` 再到 `MemoryStageControl.response_o`，只用于命中读快路径。
