# Task Report

## 基本信息

- `task_id`: `2026-05-21-npc-stage-pipe-bubble`
- `task_slug`: `npc-stage-pipe-bubble`
- `graph_template`: `custom`
- `graph_mode`: `dynamic`
- `status`: `completed`
- `owner`: `Codex`
- `started_at`: `2026-05-21`
- `updated_at`: `2026-05-21`

## 任务目标

- `source_request`: 用户要求按五级流水阶段分别仿真各模块，写专门顶层，减少 `cache -> IF`、`IF -> ID` 等边界中的无用气泡，降低整核 stall。
- `goal`: 找出并消除前端 hit response 进入 IF/ID 前多打一拍的气泡，并继续压掉 ID/EX load-use 固定插泡；同时补阶段级微基准持续观测前端、ID、MEM 边界气泡。
- `scope`: `npc/single/vsrc/IfStage.v`、`npc/single/vsrc/PipelineControl.v`、`npc/single/testbench` 阶段级 testbench、相关 README 与 memory 记录。

## 选图说明

- `selected_template`: `custom`
- `why_this_graph`: 任务是 NPC RTL 微结构优化 + 阶段级验证，现有模板没有直接覆盖“流水线边界气泡量化”。
- `dynamic_nodes_added`: `recall`、`localize-frontend-bubble`、`rtl-fix`、`stage-testbench`、`verify`、`record`、`localize-load-use`、`rtl-fix-load-use`、`verify-load-use`、`record-update`
- `why_dynamic_nodes_were_needed`: 需要先从现有 `pipe_test` 与 `IfStage/ICache/PipelineControl` 数据流定位可消除气泡，再落 RTL 与测试顶层。

## 节点概览

| node_id | owner_agent | status | inputs | outputs | evidence |
| ------- | ----------- | ------ | ------ | ------- | -------- |
| `recall` | Codex | completed | `.github/AGENTS.md`、Copilot 指令、memory、NPC study | 约束摘要：中文、RTL 四段式、改后验证和记录 | 已读取相关文件 |
| `localize-frontend-bubble` | Codex | completed | `pipe_test`、`IfStage.v`、`ICache.v`、`IfIdPipeReg.v` | 根因：ICache hit 可同拍返回，但空 buffer response 仍先写入 fetch buffer，下拍才送 IF/ID | `/tmp/npc-stage-baseline` 显示 MEM hit 已为 0，问题集中在前端 |
| `rtl-fix` | Codex | completed | RTL 推导 | `IfStage` 新增空 buffer direct-to-pipe 旁路，buffer 旧指令优先 | `tb_if_stage` 直通检查 PASS |
| `stage-testbench` | Codex | completed | 现有 testbench 框架 | 新增 `stage_pipe_test.sv`，`pipe_test` 汇总扩展为 MEM + Stage 指标 | `stage_pipe_test` PASS |
| `verify` | Codex | completed | RTL/testbench 改动 | 模块级、阶段级、lint/build、cpu-tests 验证 | 见“关键产物” |
| `record` | Codex | completed | 改动和验证结果 | 更新 project-status、NPC memory、本 task-run | 本文件与 `dispatch-log.md` |
| `localize-load-use` | Codex | completed | 用户要求“类似方法、很层次、对其他模块压 stall” | 复核 `NpcCore` 前递与 `PipelineControl` 背压链，确认 load-use 可从 ID 固定插泡改为 EX 等待 | EX/MEM load response 已有同拍前递；miss 时 `ex_mem_can_accept_w` 会阻塞 `ex_fire` |
| `rtl-fix-load-use` | Codex | completed | RTL 四段式推导 | `PipelineControl` 取消 `id_accept_o` 的 load-use 门控，保留 miss 背压等待；更新 `tb_pipeline_control`、`pipe_test`、`stage_pipe_test` | 阶段级指标 `id_stage_load_use_bubbles=0` |
| `verify-load-use` | Codex | completed | 第二阶段 RTL/testbench 改动 | 模块级、阶段级、lint/build、全量 cpu-tests 验证 | 见“关键产物” |
| `record-update` | Codex | completed | 第二阶段改动和验证结果 | 更新 project-status、NPC memory、本 task-run | 本文件与 `dispatch-log.md` |

## RTL 推导摘要

### 需求

- 在不改 `NpcCore` 外部接口的前提下，优化 `ICache -> IfStage -> IfIdPipeReg`。
- 当 fetch buffer 为空、IF/ID 可接收、response 到达时，response payload 本拍直达 `pipe_*` 输出并装入 IF/ID。
- 已有 buffer 指令必须优先输出；下游 backpressure 时仍存入 buffer。

### 协议规则

- `IfStage` 仍保持最多一个 outstanding fetch。
- `ifu_req_fire` 与 `ifu_rsp_valid` 可同拍；pending 的 late response 也可直通。
- 本工程中的 `pipe_valid_o` 是 “本拍装载 IF/ID” 脉冲，继续受 `pipe_ready_i` 门控。

### 状态机骨架

- 隐式状态保持为 `idle/no pending`、`pending`、`buffer valid` 三类。
- 新增 bypass 条件不是新状态，而是 `buffer invalid && pipe_ready && incoming response && active` 的组合路径。
- flush 优先清 pending/buffer，redirect 更新 fetch PC。

### 关键不变量

- 同周期最多向 IF/ID 送一条指令。
- buffer valid 时，pipe payload 必须来自 buffer，incoming response 只能补入 buffer。
- direct-to-pipe 的 response 不能再写 buffer，否则会重复进入 ID。
- halt/fatal/flush 下不接收 response、不产生 pipe load。

### 数据通路骨架

- 新增 `fetch_direct_to_pipe_w`、`fetch_store_rsp_w`、`pipe_load_w`。
- `pipe_*` payload mux：buffer valid 优先，否则使用 incoming response 解压/BPU 预测结果。
- `fetch_pc_q` 对任何已接收 response 推进到预测 PC；只有非直通 response 写 `fetch_buf_*`。

## 第二阶段：ID/EX load-use 压 stall

### 需求

- 继续按流水级别分析 `IF/ID -> ID/EX -> EX/MEM -> MEM/WB` 的可消除气泡。
- 对典型 `lw xN, ...; use xN` 序列，不再在 ID 阶段无条件停 1 拍。
- 保持 load miss、异常、redirect、halt/fatal 的精确性。

### 协议规则

- `NpcCore` 已有 MEM response -> EX operand forwarding：当 `ex_mem_load_w && mem_response_w` 时，消费者 EX 源操作数可直接取 `lsu_mem_load_data_w`。
- `PipelineControl` 已有 MEM 阶段未响应时的背压：`ex_mem_valid_i && ex_mem_is_mem_i && !mem_response_i` 会让 `ex_fire_o=0`。
- 因此消费者可以先进入 ID/EX；如果 load hit，下拍 EX 同拍拿到返回数据；如果 load miss，则消费者在 EX 被背压等待。

### 关键不变量

- 不能让消费者越过尚未完成的 load 进入 EX/MEM。
- load hit 的返回数据必须优先于 EX/MEM 旧值和 MEM/WB 旧值前递。
- load miss 期间 IF/ID 和 ID/EX 受 EX 背压保持，不丢指令、不重复执行。
- flush、fatal、halt 仍优先于接受新 ID 指令。

### 数据通路骨架

- `id_accept_o` 不再用 `load_use_hazard_w` 门控，只保留 IF/ID valid、ID/EX slot free、flush/halt/fatal 等真实接收条件。
- 原 load-use hazard 关系保留为可审计信号，语义从“ID 插泡”变为“允许进入 EX 后由 MEM response/EX 背压处理”。
- `pipe_test` 和 `stage_pipe_test` 的 load-use 微基准同步改为：dependent 可立即进入 EX；miss 场景检查 `ex_fire=0` 背压。

## 关键产物

- `artifacts`: `npc/single/vsrc/IfStage.v`、`npc/single/vsrc/PipelineControl.v`、`npc/single/testbench/tests/stage_pipe_test.sv`、`npc/single/testbench/tests/pipe_test.sv`、`npc/single/testbench/tests/tb_if_stage.sv`、`npc/single/testbench/tests/tb_pipeline_control.sv`、`npc/single/testbench/Makefile`、`npc/single/testbench/README.md`
- `logs_or_traces`:
  - `make -C npc/single/testbench RESULT_DIR=/tmp/npc-loaduse-module-tests run`: 21/21 PASS
  - `make -C npc/single/testbench PIPE_RESULT_DIR=/tmp/npc-loaduse-stage-pipe pipe_test`: PASS；`frontend_icache_hit_to_ifid_wait_cycles=0`、`frontend_duplicate_buffer_bubbles=0`、`mem_stage_dcache_load_hit_wait_cycles=0`、`mem_stage_dcache_store_hit_wait_cycles=0`、`id_stage_load_use_bubbles=0`
  - `make -C npc/single lint`: PASS
  - `make -C npc/single -j4`: PASS
  - `AM_HOME=/home/lyg/PA/ysyx-workbench/abstract-machine timeout 300s make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc run NPC_RUN_ARGS='-m 0 --no-progress'`: 38/38 PASS
- `linked_memory_updates`: `.github/memory/project-status.md`、`.github/memory/modules/npc.md`

## 当前阻塞点

- `blockers`: 无
- `missing_dependencies`: difftest 当前构建显示 `CONFIG_NPC_DIFFTEST` 未启用，因此本轮 cpu-tests 用裸跑验证。
- `risk_assessment`: 前端直通拉长 IF 组合路径，load hit 同拍前递也让 MEM response -> EX operand path 更关键；功能仿真已过，后续做 STA/PPA 时需重新评估这两条路径时序。

## 下一步建议

1. 在恢复 Yosys/STA 环境后，重点检查 `fetch_pc -> ICache SRAM -> RVC decompress/BPU -> IF/ID` 和 `DCache/load response -> EX forwarding -> ALU/branch` 两条组合路径。
2. 若继续压低 stall，下一步可评估 store buffer、BPU RAS 投机更新或更细粒度前端队列。

## 模板升级候选

- `repeated_dynamic_subgraph`: 流水线边界气泡审计 + 专门 stage top + 指标回归
- `should_promote_to_static_template`: `yes`
- `reason`: NPC 性能优化会反复需要“定位边界气泡 -> 阶段级 top -> RTL 改动 -> 指标回归”的闭环。

## 收尾结论

- `final_result`: 前端 ICache hit response 已能在空 buffer 且 IF/ID ready 时同拍装入 IF/ID；ID/EX load-use 固定插泡已改为消费者先进 EX、hit 同拍前递、miss 由 EX 背压等待；阶段级顶层可持续覆盖前端/MEM/ID 边界气泡。
- `evidence_summary`: 模块级 21/21、阶段级指标、lint、Verilator build、全量 cpu-tests 38/38 均 PASS。
- `notes`: 当前构建关闭 difftest，因此全量 cpu-tests 是裸跑；若后续打开 `CONFIG_NPC_DIFFTEST`，建议补一轮 `--diff=default` 回归。
