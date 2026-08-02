# V13N 独立终审

结论：`PASS_CURRENT_CONFIG_SIMULATION_ONLY_MEMORY_LIFECYCLE_V3`。本轮可交付的是当前配置
CoreMark 的守恒 full-`ProducerId` memory-holder lifecycle 观测、counter schema v3 与 v7 consumer；
不能交付性能 baseline、完整 causal CPI、production/elaboration identity closure、synthesis/STA 或系统级结论。

## 实现者证据

- production core RTL 无改动；`NpcSimTop.sv` 仿真 observer 以完整 ROB-head `ProducerId` 查找既有
  memory owner、bridge active/station token、collector pending/accepted 与 LQ terminal identity，未按 opcode
  猜测，也未向 DUT 反馈。
- 当前 CoreMark region 为 `5,395,310 cycles / 3,183,617 retired`。cycle memory aggregate
  `2,564,756` 守恒拆成 reservation/queue `623,012`、translation/order `234,156`、request-outstanding
  `1,111,757`、response-terminal `595,831`、retry `0`、lifecycle-unknown `0`；slot aggregate
  `5,448,883` 同样守恒。
- 周期、退休、`head_not_complete=3,172,886` 与 `memory_latency=2,564,756` 均与 V13M bit-exact；
  GOOD TRAP 一次，无 DiffTest mismatch 或 RTL assertion failure。
- 56 项 parser/policy 正负向单测、Verilator lint、full build、DiffTest、`OOO_ASSERT` 与
  task-run-status fail-closed 自测通过；simulator executable SHA 已在运行前持久化。230,213,569 bytes
  build 产物已删除。

## 审查者反例与处理

- **同一 token 多处命中**：owner table 要求 zero-or-one full-`ProducerId` 命中；一个 token 同时成为两个
  bridge active token 会触发 `OOO_ASSERT`，不会靠去重隐藏重复 terminal 或 holder 事件。
- **状态优先级误归类**：WALK/AD_UPDATE/SQ_QUERY 优先归 translation/order；LOOKUP、DEVICE_WAIT、
  AXI read/write phase 归 request-outstanding；S_RESP、collector accepted/pending 或 LQ terminal_seen 归
  response-terminal。active bridge 的未识别状态先归 lifecycle-unknown，不能退化为 queue/reservation 假绿。
- **主账本漂移**：v7 consumer 分别校验六个 memory 子桶之和等于旧 memory aggregate、五个 head 子类之和
  等于旧 head aggregate，并保留 cycle/slot 双守恒、phase、overflow、invalid 与 unknown ratio 拒绝条件。
  单测包含 aggregate drift、encoding drift、真实 unknown 超限、零 dependency 合法与 v6 历史兼容。
- **首次构建失败**：A1 在使用全部 16 个 4-bit reason code 后，两个旧的范围比较成为 CMPCONST；full build
  在 CoreMark 启动前 fail-closed。删除无信息量的常量比较而保留 `$isunknown`、onehot、identity 与状态断言后，
  A2 独立 PASS；A1 status、build log 与 attempt-result 原样保留。
- **过度因果结论**：这些桶记录 exact-token holder residency，不证明根因或优化收益。特别是
  request-outstanding 仍把 cache lookup、device wait、AXI read/write 各 phase 合并；本轮 baseline=false。

## 下一主线

`memory_request_outstanding` 为 memory aggregate 的约 43.35%，也是全部 region 周期的约 20.61%。下一轮优先
在不扰动 v3 主 reason 编码的前提下增加一个守恒的 request 子账本，区分 cache lookup、device wait、AXI read
address/data 与 write request/response；然后用该证据选择真正的 RTL/PPA 改动。所有新桶继续使用 exact
full-`ProducerId`，不得按 opcode 猜测、不得去重 terminal 事件、不得削弱断言。
