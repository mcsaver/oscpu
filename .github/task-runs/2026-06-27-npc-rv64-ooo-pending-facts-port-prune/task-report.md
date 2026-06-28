# 任务报告

## 基本信息

- task_id: `2026-06-27-npc-rv64-ooo-pending-facts-port-prune`
- 日期: `2026-06-27`
- 目标: 继续优化 `npc/rv64` OoO RTL 架构，把 `OooPendingDispatchArbiter` 中已经由 slot facts bus 覆盖的旧事实散线端口删除，形成 facts bus 单入口协议。
- 范围: `npc/rv64/vsrc/control/OooPendingDispatchArbiter.v`、`npc/rv64/vsrc/frontend/OooAluFetchCore.v`、`npc/rv64/testbench/tests/tb_ooo_pending_dispatch_arbiter.sv`、pending dispatch specs、`vsrc` README、memory 记录。

## RTL 推导摘要

- 需求: pending dispatch arbiter 不再同时接受 packed facts bus 和重复事实散线，避免后续 PendingCaptureGate/OwnerArbiter 抽取时出现双事实源漂移。
- 协议规则: slot facts 只允许通过 `dispatch0_facts_i` 和 `head1_facts_i` 输入；CSR illegal、direct branch/JAL fast-path、return、unsupported、dispatch1 barrier fire 属于独立控制/探针输入，继续保留为 scalar port。
- 状态机: 本切片不新增、不移动、不删除状态机；`OooPendingDispatchArbiter` 仍是纯组合优先级表。
- 不变量: dispatch0 jump capture 继续保持旧 JALR-only 语义；lane1 typed capture 继续按 `head1_facts_i` 分型；trap-exit lane1 capture 继续保留 scrub stale valid bit 语义；pending sequencer payload/state owner 不变。
- 数据通路约束: `OooAluFetchCore` 只向 arbiter 传入门控后的 `dispatch0_facts_w` 和 `head1_facts_w`，不再传重复 branch/system/FP/trap 等散线 facts；TB stimulus 通过 facts bus 构造同样的组合场景。

## 修改摘要

- `OooPendingDispatchArbiter.v`: 删除 dispatch0/head1 旧事实散线端口，内部只从 `OOO_SLOT_FACT_*` bit 建立组合 alias。
- `OooAluFetchCore.v`: 删除 `u_pending_dispatch_arbiter` 的重复事实端口连接。
- `tb_ooo_pending_dispatch_arbiter.sv`: DUT 实例与 RTL 接口同步，保留 facts bus 驱动和既有 capture/clear 断言。
- `ooo-pending-dispatch-facts-bus.md` 与 `ooo-pending-dispatch-arbiter.md`: 明确 slot facts bus 是 arbiter 的唯一事实入口。
- `npc/rv64/vsrc/README.md` 与 `npc/rv64/vsrc/control/README.md`: 更新 pending arbiter 的接口边界描述。

## 验证证据

- `make -C npc/rv64/testbench RESULT_DIR=../perf/results/20260627-ooo-pending-facts-port-prune/focused TESTS="tb_ooo_pending_dispatch_arbiter" run`: PASS。
- `make -C npc/rv64/testbench RESULT_DIR=../perf/results/20260627-ooo-pending-facts-port-prune/focused TESTS="tb_ooo_pending_dispatch_arbiter tb_ooo_fetch_head_classify_gate tb_ooo_fetch_head_pair_gate tb_ooo_alu_fetch_core tb_decode_unit" run`: 5/5 PASS。
- `make -C npc/rv64/testbench RESULT_DIR=../perf/results/20260627-ooo-pending-facts-port-prune/all run`: 102/102 PASS。
- `git diff --check -- npc/rv64/vsrc/control/OooPendingDispatchArbiter.v npc/rv64/vsrc/frontend/OooAluFetchCore.v npc/rv64/testbench/tests/tb_ooo_pending_dispatch_arbiter.sv npc/rv64/design/specs/ooo-pending-dispatch-facts-bus.md npc/rv64/design/specs/ooo-pending-dispatch-arbiter.md npc/rv64/vsrc/README.md npc/rv64/vsrc/control/README.md`: PASS。
- `make -C npc/rv64 lint`: PASS。
- `make -C npc/rv64 -j2`: PASS。

## 风险与边界

- 本切片只做接口去重和协议收口，不做功能重排。
- 未移动 `OooPendingBranchSequencer`、`OooPendingJumpSequencer`、`OooPendingMemSequencer`、`OooPendingFpSequencer`、`OooPendingSystemSequencer`、`OooPendingTrapExitSequencer` 的 payload/state owner。
- 未改变 CSR side effect、fetch redirect、backend drain、branch recovery 或 precise recovery 边界。
- 后续可继续把 capture/clear/fire/blocked reason 收拢成 `OooPendingCaptureGate` 与 `OooPendingOwnerArbiter`。

