# V11G `OooStoreQueue` resident holder 语义覆盖报告

## 状态

- 当前节点：`COMPLETED_BOUNDED_PASS`
- 分类：`verification`
- production RTL modified：`false`
- design-id：
  `sha256:b27ac45028e2b1261a93463b030e6f7953dfc3b9a071ee83bea1a2b11234c375`

## 实现者结果

- `+V11G_SQ_HOLDER_ONLY` 使用 stimulus-owned 四槽 raw-Q model，沿
  allocation→bind→fill/request→terminal→release/flush 检查 full
  ProducerId、owner tuple、valid、owner-valid、head/tail/count 与
  knownness；expected 不从 DUT raw Q 或 snoop 输出反喂。
- canonical attempt-1：
  - assert/release × `PRODUCER_GEN_W=1/4` 正向 4/4 PASS；
  - compile-success RTL variants 24；
  - assertion-off mutation simulations 48/48 被定向拒绝；
  - focused 16-source manifest 与 146-file RTL pre/post binding 无漂移。
- normal `tb_ooo_store_queue` regression 1/1 PASS。
- evidence tool 8/8 与 semantic-ledger 15/15 tests PASS。
- semantic ledger 为 10 PASS / 34 GAP / 44；
  `store-queue-producers=PASS`、`store-queue-owner-tokens=PASS`。

## 独立复核

- 预审裁决 H1：production `OooStoreQueue` 在声明的合法接口合同内未见
  可达功能反例，当前缺口是 source-bound semantic evidence。
- final reviewer contract SHA-256：
  `60ae84f5ea0a1b09a337ec6f71f2d0a284cc9f1f9e59f7a3eaca5780cc888dd5`。
- final reviewer 给出 bounded APPROVE、blocker=0；逐项确认 production
  scoped diff 为空、oracle independence、4/4 positive profiles、24 个
  真实 compile-success variants、48/48 assertion-off rejection、普通
  回归与 V11F→V11G 两项精确 ledger 迁移。

## 结论边界

本轮 bounded PASS 只覆盖 production 四槽配置中
`store-queue-producers` 与 `store-queue-owner-tokens` 的
legal-interface resident 生命周期。upstream illegal-input reachability、
全局 holder collision fence、其余 34 个 semantic unit、global
no-live-reuse、whole architecture、system、synthesis、STA、power 与
PPA 均未闭合。

本轮没有 production core RTL、当前配置 elaborated RTL、设备模型或
simulator 执行语义变化，也不缺 A3 原始输入、终端链或 post-hash 证据；
A3 保持“原始 FAIL、系统事务完成、旧 dmesg oracle 误判、
checker-replay PASS”，不触发完整系统重跑。

## 工作流纠偏

- task-specific `npc-dev` 首轮在新 V11G memory 尚未 `update-stored` 时，
  bounded brief 因缺少独立 primary focus match 而 fail closed；五个
  module node 虽均 PASS，整体 blocked 状态仍原样保留。
- 保存 project/NPC memory 并重算 bounded brief 后，第二轮
  `.github/task-runs/2026-07-30-store-queue-holder-semantic-revtag-v11g-2/`
  recall complete、5/5 completed。该纠偏补齐证据可发现性，没有放宽
  recall、RTL 或 guard 门。

## 工作流收口

- task-specific `npc-dev`
  `.github/task-runs/2026-07-30-store-queue-holder-semantic-revtag-v11g-2/`
  completed 5/5。
- 8-path scoped strict guard PASS；全工作树 strict guard 的唯一失败仍是
  shared `Linux/scripts/check-ubuntu-rootfs.sh` 缺 `rv64-linux`
  evidence，按 mixed-origin 范围外 GAP 保留。
- final identity 重算 production SQ/TB SHA、16-source manifest、
  146-file RTL snapshot、summary、semantic ledger、两个 reviewer
  contract、普通回归、ARCH_STABLE 与 guard marker 后 PASS。
- 351 个 raw evidence assets 已建立 index-only 索引。
- 9 份技术 Markdown 与 project/NPC memory 通过 `update-stored`
  发布；`snapshot-stored`、DB-first、Markdown coverage 与
  repository-level runtime-artifact audit 均 PASS。
- commit gate 观察
  `ai@af027d1bce085bace474b748dcd89113145f8772`、254 个 tracked
  修改、1,688 个 untracked 文件与一个无关 staged
  `.github/e2e/profiles/rv64-systemd-contract.tsv`；未 stage/commit。
