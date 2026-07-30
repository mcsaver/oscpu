# V11F `OooIntIssueQueue.producer_id_q` 语义覆盖报告

## 状态

- 当前节点：`COMPLETED_BOUNDED_PASS`
- 分类：`verification`
- production RTL modified：`false`
- design-id：
  `sha256:b27ac45028e2b1261a93463b030e6f7953dfc3b9a071ee83bea1a2b11234c375`

## 实现者结果

- testbench-owned 八槽 full-ProducerId model 每个 directed edge 比较 raw Q、
  full-P live mask、count 与 regular/pair carriers，不从 DUT Q 或 mask
  反喂 expected。
- canonical attempt-3：
  - assert/release × `PRODUCER_GEN_W=1/4` baseline 4/4 PASS；
  - compile-success RTL variants 20；
  - release mutation simulations 40/40 rejected；
  - focused 16-source manifest 与 146-file RTL pre/post binding identical。
- normal `tb_ooo_int_issue_queue` regression PASS。
- evidence tool 8/8 与 semantic ledger 22/22 tests PASS。
- semantic ledger：8 PASS / 36 GAP / 44；
  `integer-iq-producers=PASS`。
- ARCH_STABLE：51/53 expected GAP，V11F 新增失败 0。

## 独立复核

- 预审未发现合法 IQ-I6 输入下的 production RTL 反例，裁决为
  verification-only。
- final reviewer contract SHA-256：
  `b41dab889c477796f8397cde8dccf7eecc457524c70c193ea8c508e86bda9234`。
- final reviewer 给出
  `APPROVED_BOUNDED_INTEGER_IQ_PRODUCER_SCOPE`、blocker=0。
- reviewer 逐项确认 production scoped diff 为空、oracle independence、
  4/4 positive profiles、20 个真实 compile-success variants、40/40
  release rejection、PID-X 首个拒绝点、normal regression 与 V11E→V11F
  唯一 unit 状态迁移。

## 纠偏记录

- 首次尝试把 semantic audit 接入 `npc/rv64/Makefile` 时，V11A
  instance-graph receipt 因 Makefile 属于冻结 product-config 输入而按设计
  fail closed。该改动已撤回，V11A fresh elaboration 重跑恢复 PASS，
  design-id 仍为 `b27ac…c375`。
- 为避免篡改已冻结的产品配置，本轮可执行入口保留在 versioned
  `run-int-iq-producer-focused.sh`，由 source manifest、semantic policy、
  unit tests、task-specific e2e 与 strict guard 共同发现和审计。
- attempt-1/2 保留为开发期原始证据，不进入 policy；只有 current-source
  attempt-3 晋级。
- 首次对技术 task-run 调用 `runtime-artifact-audit --run-id` 时，工具因该
  非 e2e 目录没有 `run-manifest.json` 而 fail closed；改用与 V11E 一致的
  仓库级 artifact audit 后通过，不伪造 e2e manifest。

## 工作流收口

- task-specific `npc-dev`
  `.github/task-runs/2026-07-30-integer-iq-producer-semantic-revtag-v11f/`
  completed 5/5。
- 8-path scoped strict guard PASS；全工作树 strict guard 的唯一失败仍是
  shared `Linux/scripts/check-ubuntu-rootfs.sh` 缺 `rv64-linux` evidence，
  按 mixed-origin 范围外 GAP 保留。
- final identity 重算当前 146-file RTL、16-source manifest、summary、
  semantic ledger、reviewer contracts、module regression、ARCH_STABLE 与
  guard marker 后 PASS。
- V11F 873 个 raw evidence assets 已建立 index-only 索引。
- 9 份技术 Markdown 与 project/NPC memory 已通过 `update-stored` 发布；
  snapshot-stored、DB-first、Markdown coverage 与 repository-level
  runtime-artifact audit 均 PASS。
- commit gate 观察 `ai@af027d1bce085bace474b748dcd89113145f8772`、
  253 个 tracked 修改、1,639 个 untracked 文件与一个无关 staged
  `.github/e2e/profiles/rv64-systemd-contract.tsv`；未 stage/commit。

## 结论边界

本轮 bounded PASS 仅覆盖 `integer-iq-producers`。IQ-I6 上游 kill/flush
transaction barrier、其余 36 个 semantic unit、global no-live-reuse、
whole architecture、system、synthesis、STA、power 与 PPA 均未闭合。

本轮没有 production core RTL、当前配置 elaborated RTL、设备模型或
simulator 执行语义变化，也不缺 A3 原始输入、终端链或 post-hash 证据；
A3 保持“原始 FAIL、系统事务完成、旧 dmesg oracle 误判、
checker-replay PASS”，不触发完整系统重跑。
