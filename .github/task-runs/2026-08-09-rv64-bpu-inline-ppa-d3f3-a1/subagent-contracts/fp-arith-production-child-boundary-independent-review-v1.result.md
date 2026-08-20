RV64 RTL 结论｜对象=OooFpArithGate 与五个 production child；合同=.github/task-runs/2026-08-09-rv64-bpu-inline-ppa-d3f3-a1/subagent-contracts/fp-arith-production-child-boundary-independent-review-v1.json｜周期/配置=launch→out 5 cycles、1/cycle；NpcTop 5.0ns inline/stdcell｜TB/EDA 观测=无 production focused/mutation/mapped 证据，旧 probe 与 ABC timeout 不绑定当前设计｜范围=GAP

裁决：**FIX**。Production child split 仍是所列候选中唯一可逆首方向，但冻结方案尚不能 RETAIN：

- `OooFpPredicates/OooFpRound` 若是 wrapper module 内的 include/function，child 在 lexical scope 外不可见；若把 rounding 留在 wrapper，又违反 child 数值状态独占。必须改成 package/import，或在每个使用 child 的合法作用域 include，并证明 include guard、类型宽度及综合绑定唯一。
- mixed-precision 必须仅由 `double_s5` 原子选择 `{value,fflags}`；AddSub/Mul 的 single/double value+fflags 一起延迟 S3→S4→S5，FMA 在 S5 直达。使用当前周期 `double/kind`、分开选择 flags、或 OR 各 child flags，均立即回滚。
- Mul 的 S1→S2、FMA 的 S3→S4 必须是 producer Q 直接驱动下一阶段组合逻辑，边界不得再打一拍。FMA 边界所列 `mag/ref/sign/rm/special/spval/spff` 未明确 sticky；必须规定 `mag[0]` 为 jam，或增加显式 sticky，否则远距对齐会破坏 fused single-round。

Wrapper 只拥有 meta/kill、AddSub/Mul S4-S5 对齐及最终 mux；child 不得拥有 valid/ROB/commit。Kill/flush 只制造 bubble、不得压缩流水，S5 kill 必须先于授权、FIFO、wakeup 和 fflags 提交。

修正后按同一 design identity 串行通过 focused、结构化 state-owner mutation、动态 oracle，再做 mapped visibility；精确 1×wrapper+5×child、各 child 非零面积、无 placeholder/unknown、内部路径可归因、loops=0 才可 RETAIN，仍不等于 PPA promotion。

`unknowns`：helper 实际定义域、边界 jam 编码、legacy done/kill 优先级未给出。需扩展合同绑定真实 RTL/helper/TB 路径后才能升格。替代解释仅可能是 helper 已为 package、`mag` 已隐式 jam；当前材料未证明。置信度：中高。

