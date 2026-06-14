# NPC Cache CPU Response Ready 显式握手

## 需求

用户希望把图示中的 `respReady` 这类显式接口加到 IFU/cache 与 LSU/cache 之间，避免 cache 响应只靠隐式时序被消费。目标是让处理器在暂时不能接收返回数据时，cache 能保持响应并等待上游 ready。

## RTL 推导

- CPU/cache 边界采用两条独立握手：请求侧 `req_valid/req_ready`，响应侧 `rsp_valid/rsp_ready`。
- cache 一旦产生 response，如果上游 ready 为 1，则 response 可同拍完成；如果 ready 为 0，则必须锁存 payload 并进入 `S_RESP`。
- `S_RESP` 中 `rsp_valid` 保持为 1，data/error 保持稳定，直到 `rsp_ready` 为 1 后才回到 `S_IDLE`。
- ICache 的响应消费者是 IF 前端，ready 应表达“当前能否接收一条取指返回”，因此由 active 状态和 fetch buffer/直通槽位决定。
- DCache 的响应消费者是 MEM 阶段，ready 应表达“当前 MEM 阶段是否持有有效访存指令”，不应组合依赖全局流水推进信号；否则会和 `mem_response` 形成组合环。

## 改动清单

- `npc/single/vsrc/ICache.v`
  - 新增 `cpu_rsp_ready_i`。
  - hit、未对齐错误、miss/uncached 返回在 ready 低时锁存到 `S_RESP`。
- `npc/single/vsrc/DCache.v`
  - 新增 `cpu_rsp_ready_i`。
  - load/store hit、nop store、miss/uncached 返回在 ready 低时锁存到 `S_RESP`。
- `npc/single/vsrc/IfStage.v`
  - 新增 `ifu_rsp_ready_o`。
  - response 只有 `ifu_rsp_valid_i & ifu_rsp_ready_o` 时才被接受。
- `npc/single/vsrc/MemoryStageControl.v`、`MemoryStage.v`
  - 新增 `lsu_rsp_ready_o`。
  - `rsp_fire = lsu_rsp_valid_i & lsu_rsp_ready_o`，MEM response 只在握手完成后生效。
- `npc/single/vsrc/NpcCore.v`
  - 连接 IF/ICache 和 MEM/DCache 的 response ready。
- testbench
  - 更新 ICache/DCache/IF/MEM 相关 testbench 端口。
  - 增加 ICache hit response backpressure 和 DCache load-hit response backpressure 覆盖。

## 验证

- `make -C npc/single/testbench RESULT_DIR=/tmp/npc-cache-rsp-ready-tests2 run`
  - 22/22 PASS。
- `make -C npc/single lint`
  - PASS。
- `make -C npc/single/testbench PIPE_RESULT_DIR=/tmp/npc-cache-rsp-ready-pipe pipe_test`
  - PASS。
  - `frontend_icache_hit_to_ifid_wait_cycles=0`
  - `frontend_duplicate_buffer_bubbles=0`
  - `mem_stage_dcache_load_hit_wait_cycles=0`
  - `mem_stage_dcache_store_hit_wait_cycles=0`
  - `id_stage_load_use_bubbles=0`
- `make -C npc/single -j14`
  - PASS，重建 `build/NpcSimTop`。
- `AM_HOME=/home/lyg/PA/ysyx-workbench/abstract-machine make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc run`
  - 38/38 PASS。

## 风险与后续

- 本轮只补齐 CPU/cache response 侧 ready；AXI/mem 侧原有 `arready/rready/awready/wready/bvalid` 握手保持不变。
- `MemoryStageControl.lsu_rsp_ready_o` 不接 `update_en_i` 是刻意设计，用于避免组合环；流水是否推进仍由现有 `response_o` 和全局控制处理。
- 运行 testbench 会刷新已跟踪的 `npc/single/testbench/build/*.vvp` 生成物，提交前应按项目策略决定是否保留这些生成文件变化。
