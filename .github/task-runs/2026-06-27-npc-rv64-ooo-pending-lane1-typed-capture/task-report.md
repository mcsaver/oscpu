# 任务报告

## 基本信息

- `task_id`: `2026-06-27-npc-rv64-ooo-pending-lane1-typed-capture`
- `task_slug`: `npc-rv64-ooo-pending-lane1-typed-capture`
- `graph_template`: `custom`
- `graph_mode`: `dynamic`
- `status`: `completed`
- `owner`: `codex`
- `started_at`: `2026-06-27`
- `updated_at`: `2026-06-27`

## 任务目标

- `source_request`: 用户要求继续优化 RTL 架构。
- `goal`: 继续收口 pending capture 协议，让 lane1 capture 输出从 generic barrier 改为按 slot facts 分型。
- `scope`: `npc/rv64` pending dispatch arbiter、pending arbiter TB、pending/trap-exit spec、RTL README 和 memory。

## 节点概览

| 节点ID (`node_id`) | 负责 Agent (`owner_agent`) | 状态 (`status`) | 输入 (`inputs`) | 输出 (`outputs`) | 证据 (`evidence`) |
| ------------------ | -------------------------- | --------------- | --------------- | --------------- | ----------------- |
| `recall` | `codex` | `completed` | AGENTS、项目记忆、pending facts bus 上一刀 | 选择 lane1 typed capture 作为小切片 | 对话工具输出 |
| `rtl` | `codex` | `completed` | `OooPendingDispatchArbiter.v` | lane1 branch/jump/mem/FP/SYSTEM typed capture | `tb_ooo_pending_dispatch_arbiter` PASS |
| `test` | `codex` | `completed` | 旧 generic barrier TB | 空 barrier 与 typed capture 互斥覆盖 | focused 5/5 PASS |
| `regression` | `codex` | `completed` | 最新 RTL/TB/spec | 默认 module、lint、build 证据 | 102/102 PASS；lint/build PASS |
| `record` | `codex` | `completed` | 验证输出和改动列表 | spec、README、memory、task-run 更新 | 本报告与派发日志 |

## RTL 推导摘要

- `需求要点`: pending owner capture 的输出协议应表达真实 owner 类型，不能长期依赖下游 valid 信号吞掉无关 generic capture。
- `协议规则`: lane1 capture 先受 `lane1_barrier_base` 限定，再由 `head1_facts_i` 的 `BRANCH/JUMP/MEM/FP_ENABLED/SYSTEM` bit 分型；trap-exit lane1 capture 仍对任意 lane1 barrier 拉高，用 capture-valid 清理或保留 entry。
- `状态机`: 无新增状态机，`OooPendingDispatchArbiter` 仍为纯组合模块。
- `不变量`: IRQ/lane0/fetch fault/arch trap/exit/FP/SYSTEM/branch/jump/lane1/unsupported 优先级不变；`OooPendingTrapExitSequencer` 的 capture-valid=0 scrub 语义不变。
- `数据通路骨架`: `OooFetchHeadPairGate` 输出 `head1_facts_w` -> `OooAluFetchCore` 传入 pending arbiter -> arbiter 切 facts bit -> typed owner capture 输出到对应 pending sequencer。

## 验证结果

- `make -C npc/rv64/testbench RESULT_DIR=../perf/results/20260627-ooo-pending-lane1-typed TESTS="tb_ooo_pending_dispatch_arbiter" run` PASS 1/1。
- `make -C npc/rv64/testbench RESULT_DIR=../perf/results/20260627-ooo-pending-lane1-typed/focused TESTS="tb_ooo_pending_dispatch_arbiter tb_ooo_fetch_head_classify_gate tb_ooo_fetch_head_pair_gate tb_ooo_alu_fetch_core tb_decode_unit" run` PASS 5/5。
- `make -C npc/rv64/testbench RESULT_DIR=../perf/results/20260627-ooo-pending-lane1-typed/all run` PASS 102/102。
- scoped `git diff --check` PASS。
- `make -C npc/rv64 lint` PASS。
- `make -C npc/rv64 -j2` PASS。

## 当前阻塞点

- `blockers`: 无
- `missing_dependencies`: 无
- `risk_assessment`: 本轮主要风险是误删 trap/exit lane1 scrub 语义或改变 lane1 owner 优先级；已保留 `trap_exit_capture_lane1_w = lane1_barrier_base_w` 并用 pending arbiter TB、父模块 focused、默认 module、lint/build 覆盖。剩余风险属于后续删除旧散线、完整 PendingCaptureGate/OwnerArbiter、FP 拆分、Linux/full-system、formal/PPA/timing/CDC/reset/物理签核等非本轮范围。

## 收尾结论

- `final_result`: 完成。lane1 branch/jump/memory/FP/SYSTEM capture 已按 `head1_facts_i` 分型输出，trap-exit lane1 capture 保留 scrub 行为。
- `evidence_summary`: focused 5/5 PASS；默认 module testbench 102/102 PASS；`make -C npc/rv64 lint` PASS；`make -C npc/rv64 -j2` PASS。
- `notes`: 未 stage、未 commit，避免触碰工作区已有非本轮 testsuite 改动。
