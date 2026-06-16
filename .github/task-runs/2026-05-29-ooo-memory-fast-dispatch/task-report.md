# OoO memory fast-dispatch increment

## 背景

`NPC_OOO_ALU_EXPERIMENT=1` 在 RVC 与 JAL 快速重定向后，默认 AM `cpu-tests add` 已能 GOOD TRAP，但 CPI 仍为 `3.645`。上一轮默认主线统计显示该程序有大量访存；当前实验前端对 lane0 load/store 的策略仍是先等待 ROB/IQ/retire 全排空，再单发 memory uop，最后提交后重取 fallthrough，导致每个访存都支付一次预 drain。

## 四阶段记录

### 1. 需求

- 只优化 lane0 load/store；lane1 memory 仍保持半包屏障，避免一次改动扩大到 lane1 memory 支持。
- lane0 memory 仍作为前端停止边界：memory 之后的年轻指令不继续派发，直到该 memory uop 与更老项全部退休。
- memory uop 必须真实进入现有 OoO 后端/ROB/LSU，不走 synthetic commit；load 写回、store 提交语义继续复用既有后端。

### 2. 协议 / 状态机 / 不变量

- 发现 lane0 memory 且 dispatch0 ready/supported 时，当拍派发 memory uop、弹出并清空 fetch FIFO、清 outstanding request，并设置 `stop_pending_q + pending_mem_q + pending_mem_dispatched_q`。
- 若当拍已有旧 outstanding response，则通过已有/新增 discard response 状态把它 ready/drop，不能写入重定向后的 FIFO。
- `stop_pending_q` 期间不发新 fetch；待 `backend_drained_w` 后，说明更老项和 memory uop 都已退休，再从保存的 `head_next_pc0_w` 恢复顺序取指。
- lane0 memory 之前不再要求 `backend_drained_w`；精确性依赖当前实验子集里 older ALU/JAL 不产生异常，且旧 memory 屏障保证不会有未退休 older memory。

### 3. 数据通路

- 在 `OooAluFetchCore` 增加 `direct_mem0_dispatch_valid_w/direct_mem0_fire_w`，并纳入 `core_dispatch0_valid_w`。
- `fifo_pop_w` 与 fetch response drop 逻辑纳入 `direct_mem0_fire_w`，与 JAL redirect 共用 stale response discard 机制。
- 时序侧在 `direct_mem0_fire_w` 当拍锁存 `pending_mem_pc_q/inst_q/next_pc_q`，直接标记 `pending_mem_dispatched_q=1`，后续复用既有 `drain_complete_w -> pending_mem_q` 恢复取指逻辑。

### 4. RTL 实施计划

- 修改 `npc/single/vsrc/ooo/OooAluFetchCore.v` 的 dispatch 分类、fetch drop 和 always 块。
- 扩展 `tb_ooo_alu_fetch_core`，用 lane0 memory case 观察至少一次 dual commit，证明不再先预 drain。
- 回归 fetch-core、全量模块 testbench、实验构建与 AM add。

## 结果

- 已保留该增量。lane0 memory 可在后端 ready 时直接作为真实 uop 派发，不再在派发前等待 ROB/IQ/retire 全 drain。
- 实验 OoO AM `cpu-tests/add` GOOD TRAP：`cycles=2886`，`commits=839`，`CPI=3.440`，日志 `/tmp/ysyx-ooo-memory-fast-add.log`。
- 后续增量继续把 lane1 memory 和 memory streaming 放开；该阶段仍不等价于 LSQ。
