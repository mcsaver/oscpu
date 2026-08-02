# RV64 V14A — DI-2 current-design width-continuity rebind

## 分类与范围

- 主分类：`architecture`；轻量流程类：`development`。
- debt：`DI-2 width_continuity`。合同要求无访存、无控制流、无异常的独立 RV64I ADDI 流，
  在固定预热 24 周期后的 64-cycle 窗口内，使 fetch/decode/rename/dispatch/issue/execute/retire
  七个语义边界每拍各通过两个不同 transaction，并保持 payload/full ProducerId 生命周期。
- 默认不修改 `npc/rv64/vsrc/**`；只有 current focused baseline 证明真实断点时才扩大 production RTL
  写范围。本轮不得由 DI-2 外推整体 architecture、CPI 或 PPA。

## Currentness 与竞争假设

- 历史 V9A 绑定 145-file design-id `sha256:6236b176…f2f3dc`；最终 assert/release 2/2、
  fixed-window stall probe、11/11 compile-success RTL mutation 与 8/8 相邻回归均闭合。
- 历史 43-file source manifest 对 current workspace 复核：核心 frontend/decode/dispatch/backend/
  ROB/EX-stage RTL 大多字节相同，但 `OooIntIssueQueue.v` 已发生真实 production RTL 演进；Makefile、
  三个相邻 TB、架构 checker/tests 与部分 spec 也已漂移。旧完整设计和旧 mutation 证据不可直接晋级。
- H1：后续 packed IQ state/compaction 改造保持双 lane issue 与 payload/ProducerId 连续性，当前硬件合同
  仍成立；需要适配 live mutation anchor 并重建 current proof binding。
- H2：IQ compaction、lane1 resident field 或 sink holder 改造引入真实 width/payload 断点；current
  assert focused baseline 将在固定窗口或身份账本首先失败。
- 第一实验：只编译/运行 current `v9a-width-continuity` assert profile，不发布任何 manifest；它是区分
  H1/H2 的最低成本动态观测。

## 当前状态

`IMPLEMENTER_PASS / REVIEWER_PASS_WITH_GAPS`。current design-id 为
`sha256:093c2380b997029944aa4462015d83711d7c5f1d52b15b4803c4515a581a7488`
（146 个 RTL 文件）；长期 goal 保持 active。

## 根因与实现

- current assert 判别实验得到七边界精确双 transaction，因此 H1 成立，H2 在本合同范围内被否定：
  `OooIntIssueQueue` packed state/compaction 演进没有破坏本地独立 ADDI 流的双 lane 连续性。
- 本轮根因不是 production RTL 断点，而是历史 V9A 的 design-id、变异 anchor 和证据路径均不能代表
  current workspace。修复集中在 DI-2 证据工具：增加 `task-run-v1` scoped publication，绑定 current
  RTL/source/proof SHA，并保持 canonical 架构 manifest 和历史 V9A evidence 只读。
- scoped runner 跳过八个 sibling gate 重放、常规开发不需要的 `check-contract` 和 Git 全量检查；仍保留
  assert/release、固定窗口停顿反例、11 个 compile-success production RTL mutation、8 个邻接回归
  及 evidence checker 单测。所有 Python 调用使用 `-B`，避免 task-run 内重建 bytecode。
- production `npc/rv64/vsrc/**` 未由本任务改写；pre/post 41-file source manifest 字节相同。

## 实现者证据

| 层次 | current 配置与观测 | 结果 |
|---|---|---|
| focused | assert/release；first fetch request fire 后 warmup=24，固定 64 cycles | 2/2 PASS |
| 七边界 | fetch/decode/rename/dispatch/issue/execute/retire 各 total=128、peak=2、dual=64 | PASS |
| 身份/holder | 七边界 ProducerId/payload count=178；active/mismatch/lifecycle=0；自然 drain request/response/enqueue=89，所有 holder=0 | PASS |
| 固定窗口反例 | cycle 17 阻断 request admission；编译成功，动态非零结束并命中 width=0/expected=2 | 1/1 REJECT |
| RTL 变异 | current 唯一 anchor；11/11 编译成功；11/11 由对应 sink/payload/ProducerId oracle 检出 | PASS |
| 邻接回归 | core glue、fetch FIFO、decode、dispatch、IQ、int backend、ROB、pipe stage | 8/8 PASS |
| evidence 单测 | width-continuity + architecture hard-gate 定向单测 | 48/48 PASS |
| scoped aggregate | manifest 仅含 `width_continuity`；41 source files、28 proof roles | DI-2 GREEN；其余 8 门 RED；overall RED |

- suite：`v14a-di2-20260802T035719Z-335896`。
- 结果：`evidence/di2-current/result.json`；架构 scoped manifest：
  `evidence/architecture-current.json`；完整日志 marker：
  `[V9A-DI2-RUNNER][PASS]`。
- canonical `npc/rv64/eval/ppa/evidence/architecture-current.json` SHA-256 保持
  `a0bd58bf4ef9bdfa7724087af3dcef79a72cb8384d8e1e8131d20957897c1bc1`。
- compact task-run 为约 1.7 MiB；未保留 `.vvp`、`.o`、`.a`、`.pyc` 或临时 JSON。

## 结论边界

- implementer candidate：current-design `DI-2 width_continuity` 可限定为 GREEN。
- aggregate 仍为 RED；本轮没有 workload CPI、综合、STA 或功耗观测，故 PPA 为 `UNQUALIFIED`，
  `promotion_eligible=false`。
- 独立审查合同：`subagent-contracts/v14a-di2-frozen-review.json`，SHA-256
  `a77bf62d72a341568424213df9dc6c683826b94a9464e9eb9a097370e2830137`。审查者对 current scoped
  DI-2 GREEN 给出高置信 PASS，未发现推翻证据；对内部 backpressure/flush、ProducerId wrap/reuse、
  workload CPI、aggregate architecture、综合/STA/PPA 明确保留 GAP。完整结论见
  `review-result.md`。
