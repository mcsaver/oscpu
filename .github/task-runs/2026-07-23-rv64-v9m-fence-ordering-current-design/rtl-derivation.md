# V9M RTL derivation and verification topology

## 阶段 0 — 接口合同冻结

冻结对象为 `pending_system_fence_i`、`mem_retire_quiet_i`、`mem_idle_i` 与
`drain_complete_o`。本轮确认既有 RTL 已实现所需访存顺序合同，因此不修改可综合 RTL；
只增强验证与证据绑定。

## 阶段 1 — 需求

- 正向程序覆盖 older store、同包 lane1 `FENCE`、younger device read。
- 独立组合门 testbench 覆盖 SQ quiet 但完整 memory graph 非 idle 的状态。
- 两个负向 RTL 版本必须成功编译：一个删除 drain gate 完整 memory-idle
  条件，一个常量化 CoreGlue→ControlPlane 连接；每个版本只允许目标检查项失败。
- 当前 `TESTS` inventory 全量执行并逐日志校验，日志内嵌运行时 RTL SHA。

## 阶段 2a — 协议规则

- pending-system owner 保持到 drain complete；普通 `FENCE` 额外消费 `mem_idle_i`。
- `mem_retire_quiet_i` 与 `mem_idle_i` 是不同层级的静默条件，不得互相替代。
- 负向版本通过 Makefile 的单一 RTL 文件变量替换，不改工作区 production RTL。

## 阶段 2b — 状态机

无新增 FSM。沿用 pending-system capture → wait-for-drain → single retirement → clear
生命周期；testbench 只观测事件计数与顺序。

## 阶段 2c — 不变量

- ordinary FENCE：`drain_complete_o -> mem_idle_i`。
- ordinary FENCE：`retire -> older store drain observed`。
- younger device read：`request -> older store drained && FENCE retired`。
- 每个 store probe、store drain、FENCE retirement、device read 均 exact-one。

## 阶段 2d/2e — 数据通路与验证拓扑

production datapath 不变。验证拓扑为：

```text
tb_ooo_priv_system
  -> real decode / pending-system / SQ / MIQ / memory bridge path
  -> exact FENCE-G1 program marker

tb_ooo_pending_drain_resolve_gate
  -> mem_retire_quiet_i=1, mem_idle_i=0
  -> independent drain_complete_o oracle

compile-success local RTL source variant
  -> Makefile RTL_OOO_PENDING_DRAIN_RESOLVE_GATE override
  -> same independent oracle must report CHECK-FAIL

compile-success CoreGlue connection variant
  -> Makefile RTL_OOO_CORE_TOP_GLUE override
  -> full-core busy-memory binding oracle must report the sole CHECK-FAIL
```

## 阶段 3 — RTL 结论

当前 `OooPendingDrainResolveGate.v` 无需功能修改。唯一 SystemVerilog 改动是在
`tb_ooo_priv_system.sv` 增加精确 evidence marker，不参与综合；checker 与 evidence
tool 对现有组合条件做独立复核。
