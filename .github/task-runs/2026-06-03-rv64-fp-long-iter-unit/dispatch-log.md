# Dispatch Log

- 需求：`OooAluFetchCore` 中 FDIV/FSQRT 不应继续依赖功能仿真式单周期宽组合 `/`、`%`、integer sqrt/square compare。
- 协议：pending_fp 是精确串行边界，后端 drain 后才允许 FP 副作用；长操作 done 前必须继续停在 pending_fp。
- 状态机：父级新增 `pending_fp_long_pending_q/done_q/result_q`；子级 div/sqrt 各自 idle/busy/done。
- 不变量：
  - FP load/store 只走 memory 子流程。
  - 非 div/sqrt FP 指令仍走原组合 helper 并在 drain_complete 提交。
  - div/sqrt done 后只读锁存结果提交，避免提交组合锥重新穿过迭代单元输出。
  - reset/flush/新 pending 捕获清空 long 状态。
- 数据通路：
  - `OooFpDivIter`: dividend/divisor -> quotient/remainder_nonzero。
  - `OooFpSqrtIter`: radicand -> root/remainder_nonzero。
  - 原 FP helper 保留特例、规格化、舍入、pack。
- 验证证据：见 `task-report.md`。
