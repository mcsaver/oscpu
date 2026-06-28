# 派发日志

## 节点表

| node_id | owner_agent | module | status | inputs | outputs | evidence |
| --- | --- | --- | --- | --- | --- | --- |
| recall | codex | repo-memory | PASS | AGENTS 契约、project/module memory、pending specs | 当前 pending facts bus 边界与上一轮 lane1 typed capture 约束 | `.github/memory/project-status.md`, `.github/memory/modules/npc.md` |
| rtl-protocol | codex | npc/rv64/control | PASS | 需求、协议规则、状态机、不变量、数据通路约束 | facts bus 单入口协议，scalar control/probe 保留清单 | `task-report.md` |
| rtl-edit | codex | npc/rv64/vsrc | PASS | `OooPendingDispatchArbiter` 旧兼容端口、`OooAluFetchCore` 连接、TB 实例 | 删除重复事实散线端口，保留 packed facts bus 与独立控制输入 | `npc/rv64/vsrc/control/OooPendingDispatchArbiter.v` |
| docs | codex | npc/rv64/docs | PASS | pending dispatch facts bus spec、arbiter spec、README | 记录 slot facts 唯一入口和 pending arbiter 边界 | `npc/rv64/design/specs/ooo-pending-dispatch-facts-bus.md` |
| verify-focused | codex | npc/rv64/testbench | PASS | pending arbiter 与相关 facts users | 1/1 PASS，focused 5/5 PASS | `npc/rv64/perf/results/20260627-ooo-pending-facts-port-prune/focused/` |
| verify-regress | codex | npc/rv64/testbench/lint/build | PASS | 默认 module TB、lint、build | 102/102 PASS，lint PASS，build PASS | `npc/rv64/perf/results/20260627-ooo-pending-facts-port-prune/all/` |
| record | codex | repo-memory | PASS | 验证结果与设计边界 | project-status、module memory、task-run 记录 | `.github/task-runs/2026-06-27-npc-rv64-ooo-pending-facts-port-prune/` |

## 时间线

- 读取 pending arbiter、父模块连接和 testbench，确认上一轮 facts bus 与 lane1 typed capture 已稳定。
- 按 RTL 四段推导确认本切片无状态机迁移，风险集中在接口连接和旧事实源删除。
- 修改 arbiter port list、父模块实例和 testbench 实例，保留 CSR/direct/return/unsupported/barrier 等独立输入。
- 更新 pending dispatch facts bus/arbiter specs 与 vsrc README。
- 运行 focused、默认 module 回归、lint、build。
- 同步 project/module memory 与本 task-run 证据包。

