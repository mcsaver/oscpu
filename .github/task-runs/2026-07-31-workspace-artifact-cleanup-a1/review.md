# Independent Artifact Retention Review

## First review

Verdict: `BLOCK`

主要反例：

- 全量 preflight 与逐项字符串路径删除之间存在 TOCTOU；
- nested Git 只在 prepare 阶段检查；
- 缺 manifest/index 的历史 run 可能只在 `task-report.md` 引用临时产物；
- `Linux/env/build` 与命名 NPC build 尚未绑定 current resolver；
- signal 中断可能留下 `PREPARED` 假状态；
- porcelain 摘要不能证明已 dirty 的 tracked RTL 内容未变化。

## Final review

Verdict: `APPROVE`

审查绑定：

- plan SHA-256：
  `44c796ccad0f2082d2546ab31f131b4e1cd3c0266bdb609268f1d544c00f7884`
- Python executor SHA-256：
  `94b7d6d26be41893f6aa396cead313be0cd5739d084eb649bbd7c247837156bb`
- status wrapper SHA-256：
  `c192f2dad3d33f6001a4be926240ac2b378d86dc85411fb6d01e3cebc702e137`

在本地 Windows→WSL single-flight 契约下，未发现会实际造成 RTL 或
evidence 丢失的剩余 blocker。7,094 个目标仅含 7,077 个 `.vvp`、
16 个 `obj_dir` 和 1 个 `.Xil`；NPC/Linux build、三个脏工作树、
tracked/evidence-ref 均已排除。dirfd `O_NOFOLLOW`、原子 quarantine、
全量 guard 复核后才 purge，staging 异常可回滚。

Residual risk：不遵守 workspace lock 的外部并发仍可能在 purge 窗口新增
引用；7.59 GB 是 allocated upper bound，实际释放量可能更少。
