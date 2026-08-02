# V13M 独立终审

结论：`PASS_PARTIAL_EVIDENCE_WITH_PRESERVED_ORIGINAL_ORACLE_FAIL`。本轮可交付的是当前配置
CoreMark 的守恒 ROB-head lifecycle 观测与 v6 consumer；不能交付性能 baseline、完整 causal CPI、
exact simulator executable identity、synthesis/STA 或系统级结论。

## 实现者证据

- production core RTL 无改动；仿真 observer 使用 exact full-`ProducerId`、IQ resident sticky-ready、
  memory/execution resident mask，未新增 scoreboard 或 DUT 反馈。
- 当前 CoreMark region 周期/退休与 V13L/V13K bit-exact；cycle/slot 的旧
  `head_not_complete` aggregate 均等于五个新子桶之和，unknown 与 head-unknown 都为 0。
- 54 项 parser/policy 正负向单测、Verilator lint、DiffTest、`OOO_ASSERT` 和 task-run-status
  fail-closed 自测通过；227,337,411 bytes build 产物已删除。

## 审查者反例与处理

- **零桶假失败**：原 driver 要求 dependency/issue/execution/memory 全部非零。CoreMark 实测
  dependency=0，证明该规则把合法微架构结果误判为失败。原 status/command/raw log 均保持不变；
  独立 replay 删除该无效规则，单测新增“dependency=0 可接受”，同时保留 aggregate、守恒、unknown
  超限等负向拒绝。
- **身份重叠**：FP load 可同时保留 FP completion 与 LQ/memory owner identity。schema 明确在 IQ
  之外优先归 memory；`OOO_ASSERT` 继续拒绝一个 head `ProducerId` 同时驻留整数/FP IQ。
- **过度因果结论**：`issue_terminal` 仍合并 selector、terminal、universal owner、memory pair 与
  downstream admission；dependency=0 只描述“最老 incomplete head 未在 IQ 等 operand”，不能推出
  全局依赖代价为零。schema 与 memory 已保留这一边界。
- **观测干扰**：`print-synth-rtl` 不含仿真 observer/host；当前周期/退休与 V13L/V13K 相同。但缺少
  typed production/elaboration closure 与 stats-off cohort，因此不能宣称完整 non-interference。
- **可执行文件摘要缺口**：原 driver 虽计算 binary SHA，但在错误 oracle 返回前未持久化。build 已按
  保留策略删除，无法事后恢复 exact digest。replay 明确将其置为 GAP；不为补一个 partial checkpoint
  重复 540 万周期回放。下一次生产 RTL、elaborated RTL、device/simulator 语义改变或需要 baseline
  资格时，新的 driver 必须在运行前先持久化 binary digest。

## 下一主线

memory-latency 占 `head_not_complete` 周期约 80.8%，是下一轮优先拆分对象；建议依据现有 memory
owner kind、reservation、translation、SQ ordering、request/response 与 terminal holder 状态形成新的
互斥子账本。任何新桶仍必须保持 full-`ProducerId`、不按 opcode 猜测、不去重终端事件、不削弱断言。
