# 任务报告

## 基本信息

- `task_id`: `2026-06-27-npc-rv64-ooo-slot-facts-bus`
- `task_slug`: `npc-rv64-ooo-slot-facts-bus`
- `graph_template`: `custom`
- `graph_mode`: `dynamic`
- `status`: `completed`
- `owner`: `codex`
- `started_at`: `2026-06-27`
- `updated_at`: `2026-06-27`

## 任务目标

- `source_request`: 用户要求继续按 OoO RTL 优化路线推进。
- `goal`: 启用 `vsrc/common/`，为 fetch/decode slot facts 建立统一 packed bus，同时保持旧散线接口等价。
- `scope`: `npc/rv64` RTL common header、fetch head classifier/pair gate、父模块接线、focused TB、spec、README 和 memory。

## 节点概览

| 节点ID (`node_id`) | 负责 Agent (`owner_agent`) | 状态 (`status`) | 输入 (`inputs`) | 输出 (`outputs`) | 证据 (`evidence`) |
| ------------------ | -------------------------- | --------------- | --------------- | --------------- | ----------------- |
| `recall` | `codex` | `completed` | 用户路线图、第 0 步结果、fetch head classifier/pair gate | 选择 slot facts bus 小切片 | 对话工具输出 |
| `spec` | `codex` | `completed` | 现有散线 facts 与 common/pipeline 目录边界 | `npc/rv64/design/specs/ooo-slot-facts-bus.md` | 文件已落盘 |
| `rtl` | `codex` | `completed` | `OooFetchHeadClassifyGate`、`OooFetchHeadPairGate`、`OooAluFetchCore` | `common/OooSlotFacts.vh`、facts bus 输出和父模块接线 | focused 2/2 PASS |
| `test` | `codex` | `completed` | facts bus alias 风险 | classifier/pair gate facts alias 断言 | focused 4/4 PASS |
| `regression` | `codex` | `completed` | 最新 RTL/TB | 默认 module、lint、build 证据 | 102/102 PASS；lint/build PASS |
| `record` | `codex` | `completed` | 验证输出和文件列表 | README、memory、task-run 更新 | 本报告与派发日志 |

## RTL 推导摘要

- `需求要点`: 将 head0/head1 decode facts 从散线星形总线逐步收口为跨阶段共享载体。
- `协议规则`: facts bus bit 必须 alias 旧散线；不携带 ready/fire/payload 状态；`dispatch0_jump` 继续表示 JALR。
- `状态机`: 无状态机，纯组合 alias。
- `不变量`: `OOO_SLOT_FACT_JUMP=JAL|JALR`；fetch fault 通过 `ARCH_TRAP/STOP` 进入 facts；本轮不改变 pending/CSR/fetch 时序 owner。
- `数据通路骨架`: classifier 生成散线 facts -> packed bus alias -> pair gate 用 bus bit 做局部组合判断 -> 父模块接收 bus 备用。

## 验证结果

- `make -C npc/rv64/testbench RESULT_DIR=../perf/results/20260627-ooo-slot-facts-common/focused TESTS="tb_ooo_fetch_head_classify_gate tb_ooo_fetch_head_pair_gate" run` PASS 2/2。
- `make -C npc/rv64/testbench RESULT_DIR=../perf/results/20260627-ooo-slot-facts-common/focused TESTS="tb_ooo_fetch_head_classify_gate tb_ooo_fetch_head_pair_gate tb_ooo_alu_fetch_core tb_decode_unit" run` PASS 4/4。
- `make -C npc/rv64/testbench RESULT_DIR=../perf/results/20260627-ooo-slot-facts-common/all run` PASS 102/102。
- `make -C npc/rv64 lint` PASS。
- `make -C npc/rv64 -j2` PASS。

## 当前阻塞点

- `blockers`: 无
- `missing_dependencies`: 无
- `risk_assessment`: 本轮是组合 alias 和接线切片，主要风险是 bit 错位和旧 JAL/JALR 语义漂移；已用 alias 断言、focused、默认 module、lint/build 覆盖。剩余风险属于后续 pending owner 收口、Linux/full-system、formal/PPA/timing/CDC/reset/物理签核等非本轮范围。

## 收尾结论

- `final_result`: 完成。`vsrc/common/OooSlotFacts.vh` 已成为 slot facts 的统一宏定义，classifier/pair gate 和父模块已接入 packed bus，同时保留旧散线兼容。
- `evidence_summary`: focused 4/4 PASS；默认 module testbench 102/102 PASS；`make -C npc/rv64 lint` PASS；`make -C npc/rv64 -j2` PASS。
- `notes`: 未 stage、未 commit，避免触碰工作区已有非本轮变更。
