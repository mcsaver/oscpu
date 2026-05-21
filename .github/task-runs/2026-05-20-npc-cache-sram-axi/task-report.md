# NPC cache SRAM/AXI 改造任务报告

- 时间：2026-05-20 17:20 +0800
- 范围：`npc/single` RTL cache、核心总线边界、DPI 仿真顶层、cache/流水线 testbench

## 需求拆解

- CPU 前端到 ICache 保持专用低延迟接口，ICache hit 不走总线。
- ICache 内部 valid/tag/data 使用 SRAM macro 风格专用端口；miss/uncached fetch 走 I-side AXI read。
- DCache 内部 valid/tag/dirty/data 使用 SRAM macro 风格专用端口；load/store hit 不走总线。
- DCache miss/refill、dirty victim writeback、uncached load/store 走 D-side AXI read/write。
- write-back DCache 下，`fence.i` 必须先写回脏数据，再失效 I/D cache。

## RTL 设计

- 新增 `Sram1Rw.v` 与 `Sram2R1W.v`：组合读、时钟沿 masked write，用作本阶段可仿真/可综合的 SRAM-like wrapper。
- `ICache.v`：valid/tag/data 改为 SRAM wrapper，data line 为 512-bit；CPU hit 组合返回，miss/refill 使用单 outstanding AXI read。
- `DCache.v`：valid/tag/dirty/data 改为 SRAM wrapper；策略升级为 write-back/write-allocate；dirty victim 和 flush dirty line 逐 word 通过 AXI writeback，refill 逐 word 通过 AXI read。
- `NpcCore.v`：外部原 IFU/LSU 简化存储端口拆为 I-side AXI read 与 D-side AXI read/write；`fence.i` 在 EX 阶段启动 DCache flush 并等待 `flush_done` 后再触发原 cache flush/redirect。
- `NpcSimTop.sv`：DPI 平台壳改为最小 AXI slave，AR/R 调用 `npc_ifetch/npc_mem_read`，AW/W/B 调用 `npc_mem_write`。
- `Makefile`：Verilator 构建拆为 generate + PCH 头别名 + 子 make，规避本机 `--build` PCH include 缺普通头文件的问题。

## 协议与不变量

- CPU 请求只在 `req_valid && req_ready` 被 cache 接收；hit 可同拍响应，miss/flush 期间 `ready=0`。
- 每个 cache miss-side 最多一个 AXI transaction 在途；DCache writeback 每个 word 完成 AW/W/B 后才推进下一个 word。
- Cache line 只在整条 refill 完成后置 valid/tag；DCache dirty 只在 store hit/store allocate 后置位，writeback 完成后清 dirty。
- Uncached 地址不写入 cache SRAM。
- `fence.i` 的 ICache invalidate 发生在 DCache dirty flush 完成之后，避免自修改代码读到旧 PMEM。

## 验证

- `make -C npc/single lint`：PASS。
- `make -C npc/single/testbench RESULT_DIR=/tmp/npc-cache-sram-axi-tests run`：21/21 PASS。
- `make -C npc/single/testbench PIPE_RESULT_DIR=/tmp/npc-cache-sram-axi-pipe pipe_test`：PASS；`mem_stage_dcache_load_hit_wait_cycles=0`，`mem_stage_store_write_through_wait_cycles=0`。
- `make -C npc/single -j4`：PASS。
- `make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc ALL=load-store run NPC_RUN_ARGS='-m 0'`：PASS。
- `make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc ALL=fence-i run NPC_RUN_ARGS='-m 0'`：PASS；结束统计 `dcache writeback = 32`。

## 残留

- 当前 AXI 子集仍是单 beat、32-bit、无 ID、无 burst、无多 outstanding 的 AXI4-Lite 风格接口；后续若接真实总线，可在 cache miss-side 再扩 burst/ID。
- 未运行综合/STA；本任务验证重点是 RTL lint、Icarus 单测、Verilator build 和 AM 功能回归。
