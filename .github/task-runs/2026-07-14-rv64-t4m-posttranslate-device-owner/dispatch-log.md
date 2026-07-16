# Dispatch log

- 2026-07-14：完成代码调用链审计，确认 VA 早分类、bridge 最终 PA owner、MIQ ROB-walk kill 与
  bridge global flush 是三套不同事件。
- 方案裁决：采用 bridge `S_DEVICE_WAIT` + backend 精确 `release/cancel`，拒绝将全部 Sv39 load
  永久串行到 ROB head。
- 范围：相关 RTL、focused TB、spec 与本 task-run；不改 memory、不提交、不跑全量/综合。
- 验证完成：bridge GREEN PASS；旧 leaf 分流 mutation RED 命中 PLIC AR 泄漏；backend contract
  PASS；顶层 Sv39 PASS；diff-check PASS。
- strict guard 已执行但因共享工作树 4478 个 changed paths 要求无关 `am-kernels` 与全量
  `npc-dev` profile 而失败；按本任务“不得跑全量”约束显式豁免，保留原始 guard log。
