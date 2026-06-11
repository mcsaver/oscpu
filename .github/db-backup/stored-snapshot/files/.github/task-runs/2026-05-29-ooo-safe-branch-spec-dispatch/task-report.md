# OoO Safe Branch Speculative Dispatch

## 目标

把已验证的后端 checkpoint/restore 地基接到 branch 控制面上，先实现一个保守、可回归的单分支 speculative dispatch 闭环，再观察 AM `add` CPI 是否下降。

## RTL 推导摘要

- 需求：branch dispatch 后可在安全窗口 capture 后端 checkpoint，并沿静态预测 PC 派发年轻 ALU-only packet；mispredict 时恢复后端 checkpoint 并重定向。
- 协议：仅当 branch dispatch 前后端已 drain，且 lane1 branch 的 lane0 不是 memory 时启动 spec；capture 周期阻塞 issue/commit；spec active 期间阻塞 commit 与 memory/control/ebreak/fault packet dispatch。
- 状态机：`OooAluFetchCore` 新增 `branch_spec_checkpoint_pending_q -> branch_spec_active_q -> resolve clear/restore`。预测正确释放 spec；预测错误或 target misaligned 触发 restore 并清 fetch FIFO/outstanding。
- 不变量：错路径 packet 不得 commit，不得发起 store/memory side effect；restore 后 rename/free/busy/ROB/IQ 回到 checkpoint；前端错路径 FIFO/outstanding 被丢弃。
- 数据通路：checkpoint 信号从 `OooAluFetchCore` 透传到 `OooAluCoreSlice/OooAluDecodeBackend/OooIntBackend/OooDispatchBackend`；`OooIntBackend` 在 capture 停 issue/commit，在 restore 清 execute/memory 暂存。

## 修改内容

- `OooAluFetchCore`：新增 branch spec 状态、预测 PC、ALU-only spec dispatch gate、resolve correct/recover 逻辑。
- `OooAluCoreSlice/OooAluDecodeBackend/OooIntBackend`：透传 checkpoint capture/restore。
- `OooIntBackend`：capture 周期阻塞 issue/commit；restore 周期清 execute/memory 暂存。
- `tb_ooo_alu_fetch_core`：增加 branch spec capture/correct/restore 观测，并兼容 shadow prefetch 与 spec dispatch 两条安全路径。

## 验证

- `make -C npc/single/testbench TESTS=tb_ooo_alu_fetch_core RESULT_DIR=/tmp/ysyx-ooo-spec-dispatch-fetchcore run`
  - 结果：`1/1` PASS。
- `make -C npc/single/testbench RESULT_DIR=/tmp/ysyx-ooo-spec-dispatch-module run`
  - 结果：`38/38` PASS。
- `make -C npc/single BUILD_DIR=/tmp/npc-ooo-spec-dispatch-build NPC_OOO_ALU_EXPERIMENT=1 -j4`
  - 结果：PASS。
- `/tmp/npc-ooo-spec-dispatch-build/NpcSimTop am-kernels/tests/cpu-tests/build/add-riscv32-npc.bin --no-progress -m 5000`
  - 结果：GOOD TRAP，`cycles=1086/commits=839/CPI=1.294`。
- 默认非实验构建与 AM `add`
  - 结果：GOOD TRAP，`cycles=1509/commits=838/CPI=1.801`。
- scoped `git diff --check`
  - 结果：PASS。

## 结论

保守 spec dispatch 正确性回归通过，但 AM `add` CPI 未改善，说明当前安全启动条件过窄。下一步需要从 full-snapshot 走向更宽的精确协议：要么 spec active 时阻塞 commit/store 但允许已有老 ALU 驻留并继续被重放，要么实现基于 ROB age 的 selective younger squash，避免误回滚老指令。
