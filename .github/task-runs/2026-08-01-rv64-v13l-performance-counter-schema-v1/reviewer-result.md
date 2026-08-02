# V13L 独立审查结论

结论：`PASS`，范围仅限 partial conserving retirement-observation v1、v5 consumer 与当前
CoreMark 观测；不授予完整 causal CPI stack、baseline 或 PPA promotion。

审查者优先检查了以下反例：

- 同周期 lane0 start→lane1 end：完整周期 delta 为 0，代码先加 start 的 lane0/lane1，再减
  end 的 lane1，结果保留 1 个 lane0 slot；容量式同样得到 1。旧 V13K dummy 已证明该 committed
  lane 次序可出现，但本轮没有为 v5 重新构建该 dummy，故记为静态闭合而非新增动态证据。
- 跨周期不同 lane 相位：host 使用 `2*cycles+end_lane-start_lane`，但 policy 明确要求
  `start_lane==end_lane`；phase marker、boundary lane 或 capacity 任一漂移均被结构性拒绝。
- 假 retired：RTL assertion 与 host 双重检查 reason 中 retired popcount、lane1→lane0 顺序和
  `core_retire_count_w`；当前 assertion-on 5,485,583 cycles 无错误。
- 漏计/重复 DPI cycle、未知 reason、uint64 overflow：分别落入 unavailable/invalid/unknown/
  overflow，v5 consumer fail-closed；marker 缺失、重复、守恒破坏、retired mismatch、unknown>1%
  均有负向测试。
- 观测反馈到 production：`print-synth-rtl` 不含 `NpcSimTop.sv`/`cpu-exec.cpp`，新增 XMR/reason
  不进入 DUT ready/valid、payload、flush 或状态输入；Verilator lint 与联合编译均 PASS。
- 假哈希绑定：policy 中 measurement contract 与 counter schema 的 path/ID/SHA 均由 checker
  重算；缺失、翻转 ID、内容漂移和缺 binding 反例全部返回结构错误。

当前 CoreMark 的周期/退休与 V13K 精确相同，cycle 与 slot reason 均重新求和守恒，unknown=0。
仍保留四项关键 GAP：typed production/elaboration identity、stats-off A/B、完整因果拆分、两 workload
各三次 deterministic cohort。`head_not_complete` 是当前最大桶，但不能直接解释为某一个优化根因。
