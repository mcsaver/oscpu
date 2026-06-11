# Task Report: NPC Pipelined Cache Hit Path

- `task_id`: `2026-05-26-npc-pipelined-cache`
- `task_slug`: `npc-pipelined-cache`
- `date`: `2026-05-26`
- `owner`: `Codex`
- `status`: `completed`

## Request

- `source_request`: 用户要求把严格同步 SRAM 后的 cache 改成流水线式，尽量做到每拍吞吐。
- `goal`: 在不恢复组合 SRAM 读的前提下，让 ICache/DCache hit path 尽量背靠背接受请求，降低同步 SRAM 暴露出来的 CPI 损失。
- `scope`: 覆盖 `npc/single` 与 `npc/soc` 的 `ICache`、`DCache`、`IfStage` 及对应 cache testbench。

## RTL 推导摘要

### 需求

- ICache hit 使用同步 SRAM 上一拍输出，但不能再固定进入 `S_RESP` 多等一拍。
- IfStage 在取指 response 被接收同拍应能发出下一条预测 PC，避免“返回后一拍才发请求”的气泡。
- DCache load hit/zero-store 应在 lookup 当拍响应；store hit 因 1RW data SRAM 写口冲突，只保证更短响应，不保证同拍接下一次读。
- miss、uncached、dirty writeback、`fence.i` dirty flush 与 backpressure 语义不能退化。

### 协议规则

- CPU/cache 侧继续使用 `req_valid/req_ready` 与 `rsp_valid/rsp_ready`。
- 只有当前 lookup 可当拍产生 response 且 response ready 时，cache 才允许同拍接受下一次请求。
- ICache hit/error 可同拍 response + next request；DCache load hit 可同拍 response + next load/read request；DCache store hit 不能，因为同周期要写 1RW data SRAM。
- response 未 ready 时进入 `S_RESP` holding，payload 保持不变直到 ready。

### 状态机骨架

- ICache: `S_IDLE -> S_LOOKUP` 后，hit/error 在 `S_LOOKUP` 直接对 CPU valid；ready 且有新请求则保持 `S_LOOKUP` 并发下一次 SRAM 读，否则回 `S_IDLE`；backpressure 才进 `S_RESP`。
- ICache miss/fill: miss 仍走 `S_FILL_AR/S_FILL_R`，fill 完整 line 后 `S_REFILL_LOOKUP` 重读 SRAM，再由 `S_LOOKUP` 快速响应。
- DCache: load hit/zero-store/store hit 在 `S_LOOKUP` 当拍响应；load hit 可背靠背接下一请求，store hit 因 data 写回回到 `S_IDLE`。
- DCache miss/writeback/flush: 保持原有 dirty victim writeback、line refill、store allocate read/update、flush scan/writeback 流程。

### 不变量

- `S_RESP` 中 response payload 不随新请求改变。
- 同一周期 DCache data SRAM 不能既做 store hit 写又做下一请求读。
- miss/uncached/refill/flush 期间 `cpu_req_ready` 必须为 0，阻止单 outstanding cache 接受乱序请求。
- ICache abort/invalidate 会清空当前 lookup/response 状态，不提交旧路径取指。
- `fence.i` 仍先等待 DCache dirty flush，再 invalidate I/D cache 并 redirect。

### 数据通路

- SRAM wrapper 保持同步读，`rd_data_o` 来自上一拍地址。
- ICache/DCache hit response 由 `S_LOOKUP` 的 SRAM 输出组合形成。
- IfStage 的 steady-state 下一请求地址来自 `fetch_rsp_pred_pc_w`，而不是旧 `fetch_pc_q`。
- DCache store hit 继续使用 `byte_mask32` 生成 masked word 写回 data SRAM，并设置 dirty bit。

## Changes

- `npc/single/vsrc/cache/ICache.v`、`npc/soc/vsrc/cache/ICache.v`: hit/error fast path 从 `S_LOOKUP` 直接输出 response，ready 时同拍接受下一请求。
- `npc/single/vsrc/frontend/IfStage.v`、`npc/soc/vsrc/frontend/IfStage.v`: late response 被接收同拍允许用预测 PC 发下一次 request，规避 same-cycle 兼容分支组合环。
- `npc/single/vsrc/cache/DCache.v`、`npc/soc/vsrc/cache/DCache.v`: load hit/zero-store/store hit 在 lookup 当拍响应；load hit 可背靠背接受下一次请求，store hit 保留 1RW 写口限制。
- `npc/{single,soc}/testbench/tests/tb_{icache,dcache}.sv`: 新增 ICache hit 与 DCache load hit 背靠背用例，并调整 DCache read task 在 request fire 后及时撤 `cpu_req_valid`。

## Verification

- `make -C npc/single lint` PASS
- `timeout 30s make -C npc/single/testbench run TESTS='tb_icache tb_dcache' RESULT_DIR=/tmp/npc-pipe-cache-hit-tests4` PASS
- `timeout 60s make -C npc/single/testbench pipe_test PIPE_RESULT_DIR=/tmp/npc-pipe-cache-pipe-tests2` PASS
- `timeout 120s make -C npc/single/testbench run RESULT_DIR=/tmp/npc-pipe-cache-module-tests2` PASS, 27/27
- `make -C npc/single -j4` PASS
- `make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc ALL=add run NPC_RUN_ARGS='--no-progress -m 0'` PASS, GOOD TRAP
- `make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc ALL=load-store run NPC_RUN_ARGS='--no-progress -m 0'` PASS, GOOD TRAP
- `make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc ALL=fence-i run NPC_RUN_ARGS='--no-progress -m 0'` PASS, GOOD TRAP
- `timeout 600s make -C am-kernels/benchmarks/coremark ARCH=riscv32-npc run NPC_RUN_ARGS='--no-progress -m 0'` PASS, `cycles=427772874`, `commits=303899791`, `CPI=1.408`
- `make -C npc/soc lint` PASS
- `timeout 30s make -C npc/soc/testbench run TESTS='tb_icache tb_dcache' RESULT_DIR=/tmp/npc-soc-pipe-cache-hit-tests2` PASS
- `timeout 60s make -C npc/soc/testbench pipe_test PIPE_RESULT_DIR=/tmp/npc-soc-pipe-cache-pipe-tests` PASS
- `make -C npc/soc -j4` PASS
- `make -C npc/soc soc-lint` PASS
- `make -C npc/soc soc` PASS
- `make -C npc/soc soc-run RUN_ARGS='--max-cycles 10000'` PASS, GOOD TRAP
- `git diff --check` PASS

## Result

- ICache steady-state hit path now supports one response and one next predicted request per cycle after the initial sync SRAM latency.
- DCache load hit path now supports back-to-back load hit requests at the cache interface.
- DCache store hit remains limited by 1RW data SRAM write conflict; hiding its one-cycle MEM wait requires a later core-level early-request or MEM latency-hiding change.
