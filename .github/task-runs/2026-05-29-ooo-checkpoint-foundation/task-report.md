# OoO Branch Checkpoint Foundation

## 目标

为完整 AM `add` 向 CPI=0.5 收敛继续推进。上一轮 branch shadow prefetch 只能隐藏取指泡泡，不能让预测路径在 branch resolve 前进入后端。本轮先补后端单 checkpoint/restore 地基，避免后续放开 speculative dispatch 时出现 rename/free/ROB/IQ 状态泄漏。

## RTL 推导摘要

- 需求：支持一个活跃分支 checkpoint；capture 时保存 OoO 后端 speculative 状态，mispredict 时 restore 回该状态。
- 协议：`checkpoint_capture_i` 与 `checkpoint_restore_i` 由上层保证互斥，且当前实现要求 capture/restore 周期静止，不与 dispatch/issue/writeback/commit/alloc/free 同拍竞争。
- 状态机：本轮不改变前端/后端主状态机，只在状态拥有者内部增加 reset/flush > restore > capture > normal update 的优先级。
- 不变量：restore 后 rename map、freelist head/tail/count/FIFO、busy ready 位、ROB valid/done/payload/head/tail/count、IQ payload/count 回到 checkpoint；x0 与 reset/flush 初值语义不变。
- 数据通路：`OooDispatchBackend` 统一透传 checkpoint 信号到 `OooRenameMap/OooFreeList/OooBusyTable/OooRob/OooIntIssueQueue`；`OooIntBackend` 暂时 tie-off，保证当前实验路径行为不变。

## 修改内容

- `npc/single/vsrc/ooo/OooRenameMap.v`：新增完整 speculative map 快照与恢复。
- `npc/single/vsrc/ooo/OooFreeList.v`：新增 FIFO/head/tail/count 快照与恢复。
- `npc/single/vsrc/ooo/OooBusyTable.v`：新增 ready 位快照与恢复。
- `npc/single/vsrc/ooo/OooRob.v`：新增 ROB 全表、head/tail/count 快照与恢复。
- `npc/single/vsrc/ooo/OooIntIssueQueue.v`：新增 IQ 全表、count 快照与恢复。
- `npc/single/vsrc/ooo/OooDispatchBackend.v`：透传 checkpoint capture/restore。
- `npc/single/vsrc/ooo/OooIntBackend.v`：当前 tie-off checkpoint 信号。
- `npc/single/testbench/tests/*`：扩展 rename/free/busy/ROB/IQ/dispatch focused restore 覆盖。

## 验证

- `make -C npc/single/testbench TESTS="tb_ooo_rename_map tb_ooo_free_list tb_ooo_busy_table tb_ooo_rob tb_ooo_int_issue_queue tb_ooo_dispatch_backend" RESULT_DIR=/tmp/ysyx-ooo-checkpoint-foundation-focused run`
  - 结果：`6/6` PASS。
- `make -C npc/single/testbench RESULT_DIR=/tmp/ysyx-ooo-checkpoint-foundation-module run`
  - 结果：`38/38` PASS。
- `make -C npc/single BUILD_DIR=/tmp/npc-ooo-checkpoint-foundation-build NPC_OOO_ALU_EXPERIMENT=1 -j4`
  - 结果：PASS。
- `/tmp/npc-ooo-checkpoint-foundation-build/NpcSimTop am-kernels/tests/cpu-tests/build/add-riscv32-npc.bin --no-progress -m 5000`
  - 结果：GOOD TRAP，`cycles=1086/commits=839/CPI=1.294`。
- 默认非实验构建与 AM `add`
  - 结果：GOOD TRAP，`cycles=1509/commits=838/CPI=1.801`。

## 结论

本轮完成真实 branch speculation 前的后端可回滚基础，但没有直接改善 CPI。下一步应把 branch predictor/resolve 与 checkpoint 协议接起来：在预测路径 dispatch 前 capture，正确预测时释放，误预测时 restore 并 redirect；同时需要抑制错路径 writeback 和把 store side effect 移到 commit/LSQ 边界。
