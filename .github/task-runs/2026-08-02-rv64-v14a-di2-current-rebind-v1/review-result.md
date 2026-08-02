# RV64 V14A DI-2 independent frozen review

RV64 RTL 结论｜对象=当前 design-id
`sha256:093c2380b997029944aa4462015d83711d7c5f1d52b15b4803c4515a581a7488`
的七级双-lane transaction 边界 DI-2 `width_continuity`｜周期/配置=assert/release，首次 fetch
request fire 后预热 24 周期并固定观测 64 周期｜TB/EDA 观测=七边界均
`total=128, peak=2, dual_cycles=64`，11/11 production RTL mutation 被拒绝，8/8
`OOO_ASSERT` 邻接 TB PASS；未运行综合/STA/workload CPI｜范围=scoped DI-2 PASS；aggregate
architecture/PPA GAP

## 审查结论

- current 146-file design-id 与历史 V9A 不同，本轮 source/proof 重新绑定；11 个 mutation 使用
  current 唯一 anchor，mutant image SHA 非空且 production source pre/post SHA 不变，因此旧 PASS
  未被直接沿用，变异也未污染当前 RTL。
- assert/release 的固定 64-cycle trace 字节相同；七边界每拍两个 transaction，完整运行的
  ProducerId/payload count=178，`active_pid=0`、`payload_mismatch=0`、`lifecycle_error=0`；
  自然 drain 后 request/response/enqueue=89，FIFO/ROB/IQ/EX holder 全为 0。
- cycle 17 admission stall 以编译成功、动态非零结束和唯一
  `[V9A-WIDTH][FAIL] cycle=17 boundary=0 width=0 expected=2` 证明 oracle 未移动固定窗口。
- 11/11 compile-success RTL mutation 和 8/8 邻接回归降低了纯计数、lane payload 串线、
  ProducerId 生命周期或 sink 未接受导致的假绿风险。
- task-run-v1 只声明 `width_continuity`；DI-2 GREEN、其余八门 RED、overall RED、exit_code=1。
  canonical manifest SHA 未变化，故 scoped/canonical 写边界成立。

## 反例、未知项与 GAP

- cycle 17 反例只验证 testbench admission 固定窗口，不证明内部 backpressure、flush、replay 或资源
  耗尽时仍持续双发。
- 固定 independent-ALU stimulus 不覆盖分支、访存、异常、依赖链、ProducerId wrap/reuse、长期公平性
  或 workload 行为；`IPC=2.000` 只能用于该 64-cycle 定向窗口。
- 11 个变异是有限且定向的 mutation set，不构成形式完备性；八个邻接 TB 未给出覆盖率或门级结果。
- 冻结材料没有内联 146-file design-id 算法与 41-file scoped manifest 的逐项对应，因此独立 provenance
  重算置信度为中等；不过当前 proof role/hash/source checker 已由实现侧运行。
- aggregate architecture 继续为 RED；综合、STA、功耗和 workload CPI 均未运行，PPA 保持
  `UNQUALIFIED`，不得晋级。

## 置信度

对“冻结材料支持 current scoped DI-2 GREEN”为高置信；对独立重放 provenance 为中等置信；对
aggregate architecture、通用 workload CPI 与 PPA 不给出 PASS。当前 scoped 结论无需
`scope_extension_request`。

