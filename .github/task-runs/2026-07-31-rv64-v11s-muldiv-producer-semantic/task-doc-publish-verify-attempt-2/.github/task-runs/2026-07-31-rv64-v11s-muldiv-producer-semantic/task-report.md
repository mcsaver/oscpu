# V11S task report

本地 RV64 `OooMulDivUnit.producer_id_q` transaction lifecycle 已在当前
`OooIntBackend` product instance 上关闭限定的 `muldiv-producer` 语义单元。
最终结论为 `APPROVED_NOT_PROMOTION_ELIGIBLE`；production RTL 未修改。

## RTL 与周期合同

- design-id：
  `sha256:b0c794797242aba9bcd93079b269d843f4f27b85bc6b93623d4a6c4f2b0e1043`。
- production `OooIntBackend.v`、`OooMulDivUnit.v`、`define.v` 无本轮
  diff，SHA-256 分别为 `49ec3d7e…cca5a`、`c28ad0cf…eed`、
  `1ce15fae…694`。
- request acceptance 捕获 stimulus-owned full `ProducerId`；
  `producer_id_q` 在 Mul/Div variable-latency 迭代期间保持不变。
- completion 必须通过同一 full `ProducerId` 的 exact-open 授权；
  response handshake 后 holder 释放，full flush 使该 transaction 失效。
- generation width 1/4、assert/release、非零 generation、非零 ROB index、
  八个 younger dual-issue transaction、wrong-generation query 与 terminal
  release 均被观测。

## 验证结果

- canonical focused：
  `evidence/focused-attempt-4/summary.json`，22/22 profile PASS。
- baseline 4/4；9 类 compile-success RTL semantic variant × 2 generation
  width 为 18/18，全部在声明的 exact stage 被 oracle 拒绝。
- ordinary regression 4/4：
  `tb_ooo_muldiv_unit`、`tb_ooo_int_backend`、
  `tb_ooo_int_backend_v11r_int_lane1_packet`、
  `tb_ooo_int_backend_v11i_terminal_lifecycle`。
- V11S runner unit 10/10；graph unit 19/19；V11H replay unit 6/6；
  semantic unit 85/85。
- final static gate PASS，production/test source SHA、source pre/post、
  graph、ledger、review contract 与 JSON 均完成交叉绑定。

## Current graph 与 ledger

- product configuration 只绑定
  `npc/rv64/configs/product-rtl-defaults.mk`；当前
  `print-synth-rtl` 精确 source list 另行哈希。
- 该修正使 evidence-path-only 的 `npc/rv64/Makefile` 变化不再被误判为
  elaborated RTL 漂移，同时保留 define drift 与 source-list drift 的
  fail-closed 单测。
- current graph 为 15 holder modules、17 holder instances、
  2 duplicate modules、194 reachable modules；frozen audit PASS。
- ledger 为 44 semantic units、17 holder instances、50 bindings，
  35 PASS / 9 GAP；本轮只将 `muldiv-producer` 从 GAP 晋为 PASS。
- live ledger 与 canonical `ledger-attempt-9` byte-exact。

## A3 系统证据边界

- A3 已完成 1,223,536,213 commits、5,071,521,696 cycles。
- `reboot: Power down`、syscon poweroff、GOOD TRAP、clean system-reset
  各出现一次；RTL assertion 文件为空。
- 设计、仿真器、配置、guest/boot artifact 的 pre/post binding 无漂移。
- A3 原始 `FAIL rc=1`、strict 16/17 保持不可变；旧
  `dmesg-no-critical` oracle 将 `printk: debug:` 误判为 `BUG:`。
- 独立 versioned checker replay 接受 `printk: debug:`，同时拒绝真实
  `BUG:`，结论为
  `A3_SYSTEM_TRANSACTION_COMPLETE_LEGACY_ORACLE_FALSE_POSITIVE`。
- 本轮没有改变 A3 production/elaborated RTL、device model、host
  execution semantics 或 simulator semantics，原始输入、terminal chain
  与 post-hash 证据完整，因此 `full_system_rerun_required=NO`。

## 独立审查

- reviewer 通过 SHA 绑定合同并以反例优先方式复核 product-path
  request/hold/completion/release/flush 数据流，bounded verdict 为 PASS，
  blocker=0。
- reviewer contract SHA-256：
  `11c12f24688d9570081c3940ac04e9dbde7d21cb7860aa900986219816eba378`。
- 保留的覆盖洞：
  product-path 未分别枚举 vacant/done-closed 状态；
  forced wrong-generation response 不构成真实 handshake；
  代表性运算只覆盖 MUL 与 DIVU；
  selective kill 的细粒度覆盖主要来自 leaf TB，product path 使用 full
  flush。
- formal、综合、STA、功耗未运行；这些缺口不阻止当前单一 semantic unit
  的 bounded closure，但阻止架构与 PPA 晋级。

## AI 环境与 guard

- module/project memory 已按 DB-first 协议更新；bounded brief 为
  `recall_status=complete`，8 chunks，token estimate 1,523。
- `npc-dev` e2e run
  `.github/task-runs/2026-07-31-OooMulDivUnit-producer-lifecycle-revtag-v11s/`
  completed 5/5，publication valid。
- 16-path scoped strict guard PASS。
- full-worktree strict guard 保留 FAIL：当前 586 个混合 dirty path 中，
  唯一缺失 profile 是范围外
  `nemu/src/isa/riscv64/inst/amo.c → nemu-dev`。本轮不替 NEMU ownership
  运行或背书。
- raw evidence 985 项、1,165,310,081 bytes 已按 `INDEX_ONLY` 合同登记；
  大型 `.vvp`、Yosys full JSON gzip 与仿真日志不进入 DB full-content。
- task report、contract、review 与 evidence map 已提升为 DB-backed stored
  document，并通过逐文件 materialize/cmp。
- DB-first audit、Markdown coverage 与 runtime-artifact audit 全部 PASS；
  `live_evidence=0`、tracked heavy runtime file 为 0。
- 工作区包含用户与其他 RTL 轮次的混合修改，无法形成不夹带内容的原子
  staged diff；因此本轮不执行 `git add` 或 `git commit`。

## 晋级边界与下一动作

- bounded verdict：`APPROVED_NOT_PROMOTION_ELIGIBLE`。
- whole architecture：`RED`。
- PPA：`UNPROMOTED`。
- 剩余 9 个 semantic GAP：
  `clmul-producer`、`pending-system-producer` 与七个 FP producer unit。
- 下一项最高信息增益动作是
  `clmul-producer` current product-path lifecycle：它是剩余 GAP 中唯一
  没有 candidate source drift 的单实例整数执行 producer，适合先用
  generation width 1/4、compile-success mutation 与 ordinary regression
  完成低成本判别。

## 证据入口

- `verification-receipt.json`
- `evidence/focused-attempt-4/summary.json`
- `evidence/current-instance-graph-rebind-attempt-1/holder-instance-graph.json`
- `evidence/ledger-attempt-9/producer-holder-semantic-coverage.json`
- `evidence/v11h-checker-replay-after-graph-attempt-9-receipt.json`
- `final-static-gates-attempt-1.stdout.log`
- `evidence-index.md`
- `audit-db-first-attempt-1.log`
- `audit-markdown-coverage-attempt-1.log`
- `artifact-audit-global-attempt-1.log`
- `scoped-strict-guard-attempt-1.stdout.log`
- `full-worktree-strict-guard-attempt-1.stdout.log`
- `attempt-ledger.json`
- `final-review-result.md`
