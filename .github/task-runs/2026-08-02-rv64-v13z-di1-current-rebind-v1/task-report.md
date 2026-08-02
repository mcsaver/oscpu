# RV64 V13Z — DI-1 current-design rebind

## 分类、身份与声明边界

- 主分类：`architecture`；轻量流程类：`development`。
- 辅助修改：verification/evidence tooling；当前不修改 `npc/rv64/vsrc/**` production RTL。
- debt：`DI-1 frontend_ii1`。规范条件为 cache hit、无 redirect、下游持续 ready，预热后
  连续 64 包每拍 accept/produce 一包，最大 initiation interval=1。
- branch：`ai`；开工 HEAD：`dc027b3988777cba9fdb2200d721d24bba6368fc`。
- current RTL：146 files，
  `design_id=sha256:093c2380b997029944aa4462015d83711d7c5f1d52b15b4803c4515a581a7488`。
- 本轮只允许发布 scoped DI-1；DI-2、overall architecture、CPI 与 PPA 均不得由本轮外推。

## 原始证据与可证伪假设

- 历史 V8Z 在 145-file design-id `6236b176…f2f3dc` 上完成 64-cycle frontend/Bridge
  II=1、4-cycle response backpressure、83 项尾部守恒、9/9 compile-success RTL
  验证变异和 6/6 相邻回归。
- 历史 source manifest 对 current 文件复核：全部 DI-1 production RTL、两个定向 TB、
  common header 与原 runner/变异脚本逐字不变；漂移集中在完整 design-id、两级 Makefile、
  architecture checker/tests。
- H1：current frontend active cone 语义未变，DI-1 硬件合同仍成立；失败根因仅是历史
  full-design/provenance 绑定陈旧。
- 竞争 H2：current Makefile/elaboration 或 checker 变化改变了实际仿真行为或 oracle，必须
  通过 fresh current 编译、仿真和负向版本排除。
- 最高信息增益实验：只运行 current assert frontend 与 Bridge。结果分别重现
  `64/64 accept/produce, max_ii=1`、4-cycle hold/16 turnovers、83/83/83/83 drain，及
  bare/paged 64-cycle H1 turnover；两者均 `[RESULT] PASS`，支持 H1、排除正向行为回归。

## 实现计划

1. 为 V8Z runner 增加显式 `--scoped-task-run-id`，在任何清理前验证 mode、run-id 和
   output root；scoped 模式不改写 canonical manifest 或历史 evidence。
2. 为 mutation runner 增加 bounded work/evidence 路径、current source/mutant/image SHA
   与唯一 anchor activation receipt；编译镜像只留在临时目录。
3. 为 DI-1 evidence builder/architecture checker增加 task-run-v1 source/proof role 绑定、
   simulator receipt 与精确路径检查；scoped manifest 只含 `frontend_ii1`。
4. fresh 运行 assert/release frontend+Bridge、9 个负向 RTL 版本、6 个相邻 frontend TB、
   focused checker unit；随后形成实现者与独立审查者结论。

## 实现与证据闭环

- `run-focused.sh` 新增显式 `--scoped-task-run-id`：先验证 task-run id 与四个精确输出根，
  再清理本轮可再生产物；scoped 模式不运行 predecessor replay、全量 `check-contract` 或 Git
  工作树扫描，也不写 canonical manifest、canonical gate log 或历史 V8Z evidence。
- mutation runner 将编译目录固定在受限 `/tmp` 子目录，task-run 只保留 9 份 bounded
  仿真日志与 `summary.json`；每个负向 RTL 版本记录 live source、mutant、compiled image SHA、
  anchor 数量与 activation 状态。
- DI-1 builder 新增 `task-run-v1`：绑定 27 个 source/tool/spec/TB 路径和 25 个 proof role；
  scoped-run receipt 明确 `canonical_manifest_write=0`、`historical_evidence_write=0`，simulator
  receipt 绑定 `iverilog`/`vvp` SHA 与 assert/release/mutation 编译 flags。
- 负向仿真的真实失败出口是唯一 `[FAIL] <tb> errors=…` 加唯一 `FATAL:`，而不是
  `[RESULT] FAIL`；checker 现接受这两种互斥的合法 TB 失败终态，仍同时要求编译成功、
  非零仿真返回码、定向观测存在且无任何 PASS。重复的逐周期 `[CHECK-FAIL]` 被保留，未用
  去重逻辑掩盖吞吐断点。

## Fresh current-design 验证

- suite：`v13z-di1-20260802T032848Z-328215`。
- assert/release 完整 frontend：各自 `accepted=responses=enqueues=produced=64`，
  `max_ii=1`，`sequential=64`，`redirects=stalls=0`；run-gate 反压
  `held_cycles=4`、`resume_turnovers=16`、payload/owner stable、无 duplicate enqueue；
  drain 为 `83/83/83/83`，所有 holder 与 ghost 计数为 0。
- assert/release Bridge：bare H1 64 次、paging-context H1 64 次、elastic-skid 恢复均 PASS。
- 9/9 compile-success RTL source mutation 均实际改变指定 source、生成独立 image，并被
  对应 Bridge/frontend TB 拒绝；覆盖 accept、produce、II、PC ledger、backpressure recovery
  与 final conservation 六个验证维度。
- 6/6 相邻 frontend TB 在 `OOO_ASSERT` 下 PASS；相关 evidence/architecture 单测 45/45 PASS。
- scoped manifest 仅含 `frontend_ii1`：DI-1 GREEN；其余 8 个 architecture gate 均 RED，
  `overall=RED`、`ppa=UNQUALIFIED`、`promotion_eligible=false`。
- current design-id 为
  `sha256:093c2380b997029944aa4462015d83711d7c5f1d52b15b4803c4515a581a7488`
  （146 RTL files）；source pre/post 字节相同。canonical manifest SHA 仍为
  `a0bd58bf4ef9bdfa7724087af3dcef79a72cb8384d8e1e8131d20957897c1bc1`。
- task-run 约 1.5 MiB；未保留 `.vvp`、`.o`、`.a`、`.pyc`、Yosys 中间脚本或 generated build tree。
- final-only evidence index 登记 41 个原始/汇总资产；本轮索引耗时约 40 秒，因此仍只在确定性交付点
  执行，不进入逐次 RTL 编辑循环。

## 实现者结论

`PASS_FOR_CURRENT_DI1_SCOPE`。H1 得到 fresh current-design 正向与负向证据支持；H2 未出现。
该结论只关闭当前 design-id 的 DI-1 frontend initiation-interval 债务，不提升 canonical 架构、
DI-2、CPI baseline 或 PPA。

## 独立审查者结论与保留边界

- `v13z-di1-frozen-review-v1`：`PASS`，未发现能推翻 current-design DI-1 局部 GREEN 的
  假绿、身份漂移、canonical 越界写入或整体架构/PPA 越级结论。
- reviewer 认为 64-cycle 四级计数、83 项 drain、反压保持/恢复、9 个合同断点负向版本、
  6 个相邻 TB 与 source/tool/config 哈希形成了当前 scope 的正负闭环。
- 非阻断 GAP：冻结摘要未独立重算 measurement-window 起止；当前证据不提升为所有 payload/tag
  bit 的逐 packet 双射证明，也不覆盖 FIFO/tag 多次 wrap；本轮没有综合或 STA，不能评价 ready path
  频率或 PPA。这些 GAP 在未来声称逐 payload、wrap 安全或 PPA 时必须落成定向 TB/mutation/EDA 证据，
  当前不属于 DI-1 cache-hit ready-window 的晋级依据。
- `scope_extension_request=none`；对 scoped DI-1 为高置信，对 payload 双射与 wrap 为中等置信，
  对整体架构/PPA 不作正向判断。

本轮状态：`PASS_FOR_CURRENT_DI1_SCOPE`。长期 goal 保持 active；下一架构债务指针为 DI-2。
