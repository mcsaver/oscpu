# Dispatch Log

- `inventory`: 主执行者完成 top-level、task-run、Git object、EDA
  log/build 与三个 dirty worktree 的只读容量盘点。
- `review-v1`: 独立 artifact-retention reviewer 返回 BLOCK。
- `revision`: 删除集收窄到 `.vvp`、`obj_dir`、`.Xil`；增加 retained
  reference closure、executor binding、dirfd quarantine、signal/status
  和 protected diff digest。
- `review-v2`: 独立 reviewer 对最终 plan
  `44c796ccad0f2082d2546ab31f131b4e1cd3c0266bdb609268f1d544c00f7884`
  返回 APPROVE。
- `execute`: 主执行者取得唯一 Windows→WSL 工程命令 lane，通过冻结
  wrapper 执行并在完成后归还；未启动并行 EDA 工程进程。
- `postflight`: artifact audit PASS；strict guard 的任务外 `nemu-dev`
  evidence 缺口原样记录为范围豁免。
