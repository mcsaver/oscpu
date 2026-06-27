# 任务报告

## 基本信息

- `task_id`: `2026-06-27-npc-rv64-ooo-pending-dispatch-facts-bus`
- `task_slug`: `npc-rv64-ooo-pending-dispatch-facts-bus`
- `graph_template`: `custom`
- `graph_mode`: `dynamic`
- `status`: `completed`
- `owner`: `codex`
- `started_at`: `2026-06-27`
- `updated_at`: `2026-06-27`

## 任务目标

- `source_request`: 用户要求继续推进 OoO RTL 优化。
- `goal`: 让 `OooPendingDispatchArbiter` 开始消费统一 slot facts bus，同时保持旧散线接口与 capture 优先级等价。
- `scope`: `npc/rv64` pending dispatch arbiter、父模块接线、pending arbiter TB、spec、README 和 memory。

## 节点概览

| 节点ID (`node_id`) | 负责 Agent (`owner_agent`) | 状态 (`status`) | 输入 (`inputs`) | 输出 (`outputs`) | 证据 (`evidence`) |
| ------------------ | -------------------------- | --------------- | --------------- | --------------- | ----------------- |
| `recall` | `codex` | `completed` | slot facts bus、pending arbiter 接口、父模块接线 | 选择 facts bus 接入 arbiter 的小切片 | 对话工具输出 |
| `rtl` | `codex` | `completed` | `OooPendingDispatchArbiter.v`、`OooAluFetchCore.v` | `dispatch0_facts_i/head1_facts_i` 和内部 alias | pending arbiter 单测 PASS |
| `test` | `codex` | `completed` | 旧标量 stimulus | TB 自动构造 facts bus 并覆盖旧 case | focused 5/5 PASS |
| `regression` | `codex` | `completed` | 最新 RTL/TB | 默认 module、lint、build 证据 | 102/102 PASS；lint/build PASS |
| `record` | `codex` | `completed` | 验证输出和改动列表 | spec、task-run、README、memory 更新 | 本报告与派发日志 |

## RTL 推导摘要

- `需求要点`: pending capture/clear 仲裁应逐步从几十根散线迁移到统一 slot facts bus。
- `协议规则`: `dispatch0_facts_i` 是 dispatch-valid 门控后的 lane0 facts；lane1 facts 保持 raw；CSR illegal 仍由 CSR probe 输入提供。
- `状态机`: 无新增状态机，纯组合 alias。
- `不变量`: `dispatch0_jump` 继续读取 JALR fact；FS-off FP 仍走 arch trap；IRQ/fetch fault/arch trap/exit/FP/SYSTEM/branch/jump 优先级不变。
- `数据通路骨架`: pair gate 输出 head facts -> `OooAluFetchCore` 生成 dispatch0 gated facts -> pending arbiter 内部 facts alias -> 原 capture/clear 表。

## 验证结果

- `make -C npc/rv64/testbench RESULT_DIR=../perf/results/20260627-ooo-pending-facts-bus/focused TESTS="tb_ooo_pending_dispatch_arbiter" run` PASS 1/1。
- `make -C npc/rv64/testbench RESULT_DIR=../perf/results/20260627-ooo-pending-facts-bus/focused TESTS="tb_ooo_pending_dispatch_arbiter tb_ooo_fetch_head_classify_gate tb_ooo_fetch_head_pair_gate tb_ooo_alu_fetch_core tb_decode_unit" run` PASS 5/5。
- `make -C npc/rv64/testbench RESULT_DIR=../perf/results/20260627-ooo-pending-facts-bus/all run` PASS 102/102。
- `make -C npc/rv64 lint` PASS。
- `make -C npc/rv64 -j2` PASS。

## 当前阻塞点

- `blockers`: 无
- `missing_dependencies`: 无
- `risk_assessment`: 本轮主要风险是 facts bit 映射、dispatch0 JAL/JALR 旧语义和 pending 优先级表漂移；已用 pending arbiter 单测、父模块 focused、默认 module、lint/build 覆盖。剩余风险属于后续删除旧散线、完整 pending capture gate 拆分、Linux/full-system、formal/PPA/timing/CDC/reset/物理签核等非本轮范围。

## 收尾结论

- `final_result`: 完成。`OooPendingDispatchArbiter` 已接入 `dispatch0_facts_i/head1_facts_i`，内部组合判定开始消费 packed facts bus；旧散线端口保留。
- `evidence_summary`: focused 5/5 PASS；默认 module testbench 102/102 PASS；`make -C npc/rv64 lint` PASS；`make -C npc/rv64 -j2` PASS。
- `notes`: 未 stage、未 commit，避免触碰工作区已有非本轮变更。
