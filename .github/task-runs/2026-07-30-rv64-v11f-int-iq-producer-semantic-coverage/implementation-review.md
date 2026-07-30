# V11F implementer review

## RTL 对象与结论

- production `OooIntIssueQueue.producer_id_q` 未修改；source SHA-256 为
  `d8eb68b91fd971c3f8054280613c737f3cc951bf492888998e67ced94f9c218b`。
- 合法二态、IQ-I6 输入合同下未观察到 birth、hold、compaction、
  issue/pair carrier、selective kill、flush/reset 或 knownness 反例。
- 本轮分类保持 `verification`。

## 独立 oracle

- expected state 是 testbench 自有的八槽 full-ProducerId 有序列表。
- model 只消费 accepted stimulus 和显式周期日程；不从
  `producer_live_mask_o`、DUT `valid_q` 或 `producer_id_q` 推导 expected。
- 每个 directed edge 比较全部八槽、full-P live mask、count 和
  regular/pair carriers。
- raw identity knownness 由三项 PID-X 变体定向命中。

## 反例敏感性

- canonical attempt-3：4/4 positive profiles PASS。
- 二十个源码形态唯一命中的 compile-success RTL variants 在
  `GEN_W=1/4` 各运行一次；40 次仿真均显式关闭 `OOO_ASSERT`，并由
  `[V11F-INT-IQ-ORACLE][FAIL]` 拒绝。
- focused pre/post 16-source manifest 相同；146-file RTL pre/post snapshot
  相同。
- evidence tool 8/8、semantic ledger tests 与 normal IQ module regression
  均 PASS。

## 账本与范围

- semantic ledger 从 V11E 的 7 PASS / 37 GAP 精确变为
  8 PASS / 36 GAP；仅 `integer-iq-producers` 晋级 PASS。
- global producer no-live-reuse 仍为
  `SEMANTIC_COVERAGE_REQUIRED`，whole architecture 保持 RED，PPA 保持
  UNPROMOTED。
- 上游 kill/flush transaction barrier 的自然可达性、其余 36 个 semantic
  unit、system、synthesis、STA、power 与 PPA 均不由本轮关闭。
- production/elaborated RTL、device model 与 simulator 语义未变化；A3
  原始 FAIL、checker-replay PASS 和“不需完整重跑”分类保持冻结。
