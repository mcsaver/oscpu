# V11S implementer result

本地 RV64 `OooMulDivUnit.producer_id_q` 已增加 product-path
stimulus-owned ProducerId 周期检查、双 generation width、assert/release、
compile-success RTL 负向版本与 current graph/ledger 绑定；production RTL
未修改。

## 实现

- 新增 `tb_ooo_int_backend_v11s_muldiv_producer.svh`：
  - request birth、REQ_BUF/iterative hold、wrong-generation reject；
  - authorized WB、terminal release、ordered retirement 与 flush death；
  - MUL、DIVU 各叠加八条 younger dual-issue pressure。
- 新增 `run_v11s_muldiv_producer_semantic.py`：
  - 从 V11R base TB 与 V11S fragment 生成 byte-bound overlay；
  - 生成 4 个 baseline、18 个 compile-success mutation profile；
  - 绑定 4 个普通回归与 source pre/post manifest。
- semantic policy/evaluator 只为 `muldiv-producer` 增加 COMPLETE evidence
  set，并独立重构 overlay、mutation stage、selected source 与 A3 边界。
- runner 单测增加 overlay 锚点唯一性、byte-for-byte 重构与 fail-closed
  负例。

## instance-graph 绑定纠偏

- combined gate 的首个 FAIL 证明 graph checker 把整个
  `npc/rv64/Makefile` SHA 当作 product config；仅更新 task-run 证据路径也会
  被误判为 elaborated RTL 漂移。
- product config 现只绑定
  `npc/rv64/configs/product-rtl-defaults.mk` 中的两个 production define；
  `print-synth-rtl` 精确源列表、graph tool、Yosys script、完整 JSON 与
  instance declaration 仍分别哈希。
- 19 项 graph 单测证明：
  - define 改动仍 fail closed；
  - `print-synth-rtl` 源列表改动仍 fail closed；
  - 不改变 elaboration 的 Makefile 证据注释不再制造假漂移。
- 新 V11S graph 与 V11R graph 的 design-id、194 个 reachable instance、
  15 个 holder module、17 个 holder instance、graph SHA、source-list SHA、
  完整 Yosys JSON、script、log 与 receipt 全部相同。

## 仿真与 checker 结果

- focused canonical：22/22 profile PASS；
  4/4 baseline、18/18 compile-success mutation profile、4/4 regression。
- focused summary SHA-256：
  `2eb4984961fe34bdac751ae2dfb455de7c9256dd03bab4c31e25de0948a8e93b`。
- source pre/post manifest SHA-256 均为
  `e2835dbc1f7e49dce10f8d168eeb93694d0b46e2a6669b90297595fd14cedff1`。
- generated overlay SHA-256：
  `604e9a3c7cd45dcb586ba17c97c37927065f88aacd6a822adc4ae6721f96188e`。
- V11S runner unit：10/10 PASS。
- final graph unit：19/19 PASS；V11H replay unit：6/6 PASS；
  semantic-ledger unit：85/85 PASS。
- combined semantic gate：`rc=0`；
  graph 19/19、census 15/15、replay＋semantic 91/91。
- combined stdout SHA-256：
  `2934233ee184031f94025300bd824170c667496836989a0360c7aa3d0e20d216`。

## 当前语义状态

- design-id：
  `sha256:b0c794797242aba9bcd93079b269d843f4f27b85bc6b93623d4a6c4f2b0e1043`。
- ledger：44 units、17 holder instances、50 bindings；
  35 PASS / 9 GAP。
- live/frozen ledger SHA-256：
  `80d50ba80916a4823479748cfa69dc4ecea1a4025abf50ff3414caa0a7205944`。
- 本轮只把 `muldiv-producer` 从 GAP 晋为 PASS。
- 剩余 GAP：
  `clmul-producer`、`pending-system-producer`、
  `fp-iq-producers`、`fp-issue-packet`、
  `fp-arith-stage-producers`、`fp-long-producer`、
  `fp-done-fifo-producers`、`fp-exec1-packed-alias`、
  `fp-exec1-packet`。

## A3 系统证据边界

- A3 原始 `FAIL rc=1` 与 strict 16/17 保持不可变。
- 冻结 dmesg/console 的独立 checker replay 为 PASS；接受
  `printk: debug:`，拒绝真实 `BUG:` fixture。
- A3 replay evidence SHA-256：
  `5274b0d67eae3472e8fe8df86b4fbf49b7783eacc375d8b5e2e11c96b7881af8`。
- 本轮 production RTL、实际 elaborated topology、device model 与
  simulator execution semantics 未改变，因此不触发完整系统重跑。

## 过程证据

- focused attempt-1、ledger attempt-1 至 attempt-4、combined attempt-1/2、
  ledger attempt-6/7 均保留原始 FAIL 与 stage。
- canonical 结论只使用 focused attempt-4、graph rebind attempt-1、
  ledger attempt-9、materialize attempt-3 与 combined attempt-3。
- 没有覆盖、改写或删除 V11R/A3 历史 artifact。

