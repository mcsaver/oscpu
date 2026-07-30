# V11E `OooRob.slot_generation_q` 语义覆盖报告

## 状态

- 当前节点：`COMPLETED_BOUNDED_PASS`
- 分类：`verification`
- production RTL modified：`false`
- design-id：
  `sha256:b27ac45028e2b1261a93463b030e6f7953dfc3b9a071ee83bea1a2b11234c375`

## 实现者结果

- independent testbench model 每沿比较全部 slot，并覆盖
  `PRODUCER_GEN_W=1/4`。
- canonical attempt-3：
  - baseline 4/4 PASS；
  - compile-success RTL variants 17；
  - release mutation simulations 34/34 rejected；
  - pre/post 146-file RTL binding identical。
- normal `tb_ooo_rob` regression PASS。
- evidence tool 9/9 与 semantic ledger 13/13 Python tests 分别归档，
  合计 22/22 PASS。
- semantic ledger：7 PASS / 37 GAP / 44；`rob-slot-generation=PASS`。
- ARCH_STABLE：51/53 expected GAP，V11E 新增失败 0。
- task-specific `npc-dev`：终审前 run `2026-07-30-rob-slot-generation`
  与规格同步后的 current-source run
  `2026-07-30-rob-slot-generation-final` 均 completed 5/5。

## 纠偏记录

- attempt-1 的 walk carrier generation=0 假绿和 attempt-2 的
  reset-to-ones generation=1 假绿均原样保留。
- attempt-3 使用同一 recovery pair 的 generation 0/1 混合状态，使零
  carrier 与 reset-to-ones 两类错误都可判别。
- 首次 e2e slug 的 recall terms 过宽而 blocked；用已单独验证可召回的
  `rob slot generation` 硬件对象重跑，不修改召回门。

## 工作流收口

- 终审后 current-source `npc-dev`
  `.github/task-runs/2026-07-30-rob-slot-generation-final/` completed 5/5。
- 7-path scoped strict guard PASS；全工作树 guard 的唯一失败仍是共享
  `Linux/scripts/check-ubuntu-rootfs.sh` 缺 `rv64-linux` evidence，按
  mixed-origin 范围外 GAP 保留。
- final identity 重算 146-file RTL snapshot，核对 attempt-3 executable
  inputs、canonical summary、current ledger、publication receipt 与
  22/22 tests 后 PASS。
- V11E 609 个 raw evidence assets 已索引；8 份技术 Markdown 与两份
  memory 已通过 `update-stored` 发布，snapshot-stored、DB-first、
  Markdown coverage 与 runtime-artifact audit 均 PASS。
- commit gate 观察 `ai@af027d1b…`、251 个 tracked 修改、1,611 个
  untracked 文件与一个无关 staged profile；保持 mixed-origin GAP，
  未 stage/commit。

## 结论边界

独立 final reviewer 已核对源绑定、assert/release 配置、vvp、变体 receipt、
ledger 单元集与范围，给出 `blocker=0`、bounded APPROVE；因此
`rob-slot-generation` 登记为本轮局部 PASS。终审发现的规格页首旧计数与
13 项 ledger unittest 日志缺口均已补齐。规格同步作为独立
post-review publication receipt 保存；attempt-3 原始 summary/source
binding 不重写，evidence builder 对该文档哈希变化继续 fail closed。global holder collision fence、
whole architecture、system、synthesis、STA、power 与 PPA 不由本轮关闭。

本轮没有 production core RTL、当前配置 elaborated RTL、设备模型或 simulator
执行语义变化，也不缺 A3 原始输入、终端链或 post-hash 证据；A3 保持
“原始 FAIL、系统事务完成、旧 dmesg oracle 误判、checker-replay PASS”，
不触发完整系统重跑。
