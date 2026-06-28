# 派发日志

## 节点表

| node_id | owner_agent | module | status | inputs | outputs | evidence |
| --- | --- | --- | --- | --- | --- | --- |
| recall | codex | repo-memory | PASS | AGENTS、RTL workflow、npc memory、pending specs | 确认 lane1 facts bus 与 pending arbiter 当前边界 | `.github/memory/modules/npc.md` |
| rtl-protocol | codex | npc/rv64/control | PASS | 需求、协议规则、状态机、不变量、数据通路约束 | `OooPendingLane1CaptureGate` 纯组合协议 | `task-report.md` |
| rtl-edit | codex | npc/rv64/vsrc | PASS | `OooPendingDispatchArbiter` lane1 inline logic | 新模块、父模块实例、filelist 接线 | `npc/rv64/vsrc/control/OooPendingLane1CaptureGate.v` |
| tb | codex | npc/rv64/testbench | PASS | lane1 gate 协议 | 新增 `tb_ooo_pending_lane1_capture_gate` | `npc/rv64/testbench/tests/tb_ooo_pending_lane1_capture_gate.sv` |
| verify-focused | codex | npc/rv64/testbench | PASS | 新 gate、parent arbiter、facts users | 1/1 PASS，focused 6/6 PASS | `npc/rv64/perf/results/20260627-ooo-pending-lane1-capture-gate/focused/` |
| verify-regress | codex | npc/rv64/testbench/lint/build | PASS | 默认 module TB、lint、build | 103/103 PASS，lint PASS，build PASS | `npc/rv64/perf/results/20260627-ooo-pending-lane1-capture-gate/all/` |
| record | codex | repo-memory | PASS | 修改与验证结果 | specs、README、project/module memory、task-run | `.github/task-runs/2026-06-27-npc-rv64-ooo-pending-lane1-capture-gate/` |

## 时间线

- 读取 pending dispatch arbiter 当前实现，定位 lane1 typed capture 与 trap/exit payload 的局部组合区域。
- 按 RTL 四段式确认新模块无状态机，只抽取 lane1 本槽 facts 计算。
- 新增 `OooPendingLane1CaptureGate`，父 arbiter 保留全局优先级和 clear。
- 新增 focused TB 并接入 filelist/Makefile。
- 运行 focused、默认 module TB、lint、build。
- 更新 specs、README、memory 和 task-run 证据包。

