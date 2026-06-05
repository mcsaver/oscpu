# RV64 FP short-compute register boundary dispatch log

- 需求：在 FDIV/FSQRT 长操作和 divider 内部移位器已经收敛后，继续处理 `OooAluFetchCore` 中非 memory、非 long-op 的 FP helper 结果同拍直达提交/写回的问题，降低 helper 到 commit/FPR/ArchRegFile serial write 的组合路径压力。
- 协议：pending FP 仍必须等 `backend_drained_q && pending_fp_mem_done_q`；load/store 只看 memory done，FDIV/FSQRT 只看 long-op done，short-compute FP 先锁存 helper result，下一拍才允许 drain complete。
- 状态机：在既有 `pending_fp_q` 父状态下新增 `pending_fp_compute_done_q` 子状态，`0 -> pending_fp_compute_start_w capture -> 1 -> commit clear`。
- 不变量：
  - 一条 pending FP 的 short-compute result 只锁存一次。
  - `pending_fp_compute_done_q=0` 时不能提交该 pending FP。
  - reset、flush/trap、新 pending capture 和 commit clear 必须清空 compute latch。
  - load/store 与 FDIV/FSQRT 不进入 short-compute latch，保持原子流程。
- 数据通路约束：
  - `pending_fp_compute_value_w` 是唯一消费 short FP helper 输出的 mux。
  - `pending_fp_result_value_w` 对 long-op 选 `pending_fp_long_result_q`，否则只选寄存后的 `pending_fp_compute_result_q`。
  - serial write、FPR write 和 commit old-value 路径不得再直接消费 short FP helper 输出。
- 验证证据：见 `task-report.md`。
