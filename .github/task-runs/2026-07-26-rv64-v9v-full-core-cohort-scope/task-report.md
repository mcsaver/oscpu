# RV64 V9V full-core capability cohort 报告

## 结果

当前本地 RTL
`sha256:3460e14b8e06452017a20d0b35a552cf4e28966fcaeaf3dd747518760300df92`
的 terminal collector、producer/holder C0 交接和四项 capability cohort
合同均通过本轮定向验证。生产 RTL 在本 V9V 切片内无需新增修改。

full-core 仍为 `architecture_freeze=GAP`，PPA 为 `UNQUALIFIED`，
`promotion_eligible=false`。本轮没有关闭 `SERIALIZE-G1`，也没有用局部
module PASS 替代完整 producer-holder census 或 freeze-input inventory。

## 历史 rootfs 终态核验

`.github/task-runs/2026-07-23-rv64-v9p-serialize-current-design/`
中的 `rootfs-v9q-terminal-pair-a1` 已终止为 `FAIL rc=2`：

- RTL design-id：
  `sha256:4655eabea13d2ecce9ac94784bbcb0a8bd2151b65bcd7325f950c6abb9b91380`；
- simulator SHA-256：
  `669c983b22ce52beb433e50870e8950c522f8fd2a1072798fb86489bc2af6c87`；
- 配置：`OOO_CSR_QUEUE_HEAD=1`、
  `OOO_TERMINAL_HOLDER_ASSERT=1`、host window 21600 秒；
- 最后 progress：405,000,000 committed instructions，
  `pc=0xffffffff80002f68`；
- `terminal-markers.txt` 为空，guest/driver 日志未出现
  `S2-G1-TCOLL`、`V9Q-` 或 assertion-failure marker；
- guest runner 因未通过 reset-syscon 自然终止而返回 timeout/rc=124，
  外层 make 最终 rc=2。

因此该运行只形成旧设计上的有界未复现，不证明 terminal pair、不证明系统
完成，也不能绑定当前 `3460…` 设计。

## Terminal lane 与 owner/holder 合同

当前 `OooIntBackend` 向 `OooMemOwnerTerminalCollector` 提供 12 路真实 ingress：

| lane | terminal source |
| ---: | --- |
| 0/1 | bank0/bank1 response |
| 2/3 | bank0 active/station drop |
| 4/5 | bank1 active/station drop |
| 6/7 | reservation0/reservation1 terminal |
| 8 | legacy buffer terminal |
| 9 | AMO interphase terminal |
| 10/11 | retry0/retry1 terminal |

collector 只接受与 `OooMemOwnerTracker` edge-old
`{kind,token,epoch}` 完全一致的 terminal，并保留 duplicate、pending、
same-edge-reenqueue 与 conservation fail-loud 断言。历史根因对应的最小生产
修复仍是 V9R producer-side C0 barrier：

- backend 在 `control_full_flush_barrier_w` 下关闭 bank0/bank1
  SQ-query retry READY/capture；
- bridge 在 `control_full_flush_barrier_i` 下关闭
  `sq_query_retry_fire_w`；
- collector 没有增加去重或吞事件逻辑，断言没有削弱。

## Cohort 能力边界

规范 cohort
`full-core-single-hart-rv64-dual-issue-ooo-v1` 绑定当前 design-id：

- `A-COHERENCE-G1=EXCLUDED_BY_COHORT`：承诺单 hart 本地 LR/SC
  reservation 与本地 store/AMO/SC invalidation；不承诺 coherent/exclusive peer。
- `WFI-G1=EXCLUDED_BY_COHORT`：WFI 保留为 serialized immediate-resume
  hint，TW legality 不变；排除 true sleep/wakeup 能力。
- `SFENCE-SINVAL-G1=EXCLUDED_BY_COHORT`：accepted encoding 保守形成
  global `mmu_flush`；排除 address/ASID selective invalidation。
- `DEBUG-TRIGGER-G1=EXCLUDED_BY_COHORT`：保留 simulation checker 与
  semihost EBREAK；不广告 Debug Module、debug mode、halt/resume 或 executable
  trigger。

规范真源为 `npc/rv64/design/arch/full-core-cohort-scope-v1.md`，四份
machine-readable 合同位于 `npc/rv64/design/arch/cohort/`。任一 design-id
变化、coherent peer、真实 sleep state、selective invalidation 或 Debug transport
加入都必须重开对应决议。

## 验证证据

- V9V focused：8/8 PASS，包括 decode、CSR、fetch-head classification、
  priv-system、int-backend、12-lane collector 和两项 V9R C0 handoff。
- collector exact marker：
  `pending=12`、`seen=12`，同一 sparse token mask `aa8a28a8`。
- backend/bridge marker：
  `banks=2 forced=2 natural_trap=1`；
  `state=S_SQ_QUERY held=1 release=1`。
- `test_arch_stable_freeze`：48/48 PASS。
- V9O evidence index：165 个精确 artifact，verify PASS。
- canonical architecture hard gates：9/9 GREEN。
- full-core audit：四个 exclusion 与 exact membership PASS；
  15 个 CLOSED debt current binding PASS；blocker 32。
- V9V summary SHA-256：
  `794b49a44d8d0d431ed36114ce8ce22f73126fcb92e4e5355b128547c37c7ea2`。
- V9O evidence-index SHA-256：
  `d9cb25a07bd5c8398a421ce318ec63503cce962ba2a8f5db92f4cdce9a9515cd`。
- final architecture result SHA-256：
  `a882b838f6bf3107732938b0e0da7ea98f82daa46966393f6e9627b8ceceea7b`。

## AI 开发环境与收尾门禁

- `npc-dev` e2e task-run
  `.github/task-runs/2026-07-26-rv64-full-core-capability-cohort-v9v/`
  已完成，5/5 节点 PASS。
- V9V raw evidence 已写入 evidence index；DB-first audit 在 memory
  stored/materialized 同步后 PASS。
- strict guard 已执行：`npc-dev`、`difftest` 与 `github-index` 满足当前证据
  要求；剩余非绿项仅为 `agent-system` 的既有 Markdown coverage 集合和
  `rv64-linux` 的 V9S systemd-strict 未完成。这两项保留为显式 GAP，不追认为
  RTL、Linux 或全核 PASS。
- `git diff --check`、V9V runner `bash -n`、相关 JSON `jq empty` 与 summary
  边界断言均 PASS。

## 实现者 / 审查者复核

实现者复核：

- design-id 在 V9V 验证前后相同；
- 8 个 log 各自只有一个 native PASS、一个 design-id marker、一个
  verification-source marker 与一个 result PASS；
- collector 与 holder marker 均为 exact-once；
- ledger 与 roadmap hash 已在架构重放后重新绑定。

审查者优先检查的反例边界：

- stale contract hash、错误 cohort/design-id、缺失 rationale 与
  candidate/ledger 排除集漂移均由 validator 负向测试拒绝；
- historical rootfs 空 terminal marker 没有被解释为 current-design PASS；
- `SERIALIZE-G1.resolved=GAP`、census GAP、freeze-input inventory GAP 均仍出现在
  canonical audit；
- 没有新增 terminal-event 去重，没有关闭或放宽 RTL assertion；
- 未从 9/9 directed gates 或 8/8 focused 推导正式 PPA。

审查结论：本轮 capability-scope 与 terminal owner/holder 局部合同 PASS；
full-core freeze、systemd-strict 完成与正式 PPA 仍为 GAP/UNQUALIFIED。
