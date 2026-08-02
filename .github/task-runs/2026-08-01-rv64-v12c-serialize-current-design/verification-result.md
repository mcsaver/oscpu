# V12C 验证结果

- current design：`sha256:882111fb3d58039cb7414e6331dac0c10d848463df2228dff93ae22dafbed67b`
- queue-head CSR：assert/release `2/2`；编译成功负向 RTL 版本 `3/3`。新增 `OooRob.head0_queue_csr_w=0` 版本由 `[V10G queue-head CSR C0 commit/barrier diverged]` 与既有 assertion 检出。
- pending-SYSTEM：baseline `3/3`；编译成功负向 RTL 版本 `15/15`。新增 pending-owner 排除删除版本由 `[V9O-CONTROL-EVENT-FULL-PROJECTION]` 检出。
- functional current cohort：module `113/113`、official `177/177`、AM `61/61`、DiffTest mismatch `0`。
- 定向 Python 单测：`30/30 PASS`。
- currentness checker：`fast_gates=PASS full_system=RECERT_REQUIRED ledger=STALE_EVIDENCE arch_stable=GAP ppa=UNPROMOTED PASS`。
- cleanup：最终 queue-head 删除 `24` 个临时产物，pending-SYSTEM 删除 `88` 个临时产物；`retained_temporary_artifacts=0`。失败的 attempt-2 也执行 fail-closed 清理，仅保留日志与失败原因。
- scoped `git diff --check`：PASS；只检查本轮显式路径，未用 Git 推断修改目录。

完整系统边界：A3 原始 FAIL 与 checker replay PASS 均保留；A3 绑定 `c1b531...`，不是当前设计。为避免多十亿周期回放长期占用唯一 WSL 工程进程，本轮不在活跃 RTL 开发中启动完整系统重认证，留到确定性交付阶段执行。
