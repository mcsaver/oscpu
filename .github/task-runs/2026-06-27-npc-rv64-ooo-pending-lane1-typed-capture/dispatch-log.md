# 派发日志

## 节点表

| 节点ID (`node_id`) | 负责 Agent (`owner_agent`) | 模块 (`module`) | 状态 (`status`) | 输入 (`inputs`) | 输出 (`outputs`) | 证据 (`evidence`) |
| ------------------ | -------------------------- | --------------- | --------------- | --------------- | --------------- | ----------------- |
| `read-rules` | `codex` | repo-rules | `completed` | `.github/AGENTS.md`、`.github/copilot-instructions.md`、memory | 确认 RTL 四段推导和记录要求 | 对话工具输出 |
| `select-slice` | `codex` | npc/rv64/control | `completed` | pending facts bus、arbiter TB、父模块接线 | 选择 lane1 typed capture，不移动状态机 | `OooPendingDispatchArbiter.v` diff |
| `rtl-edit` | `codex` | npc/rv64/control | `completed` | `head1_facts_i` packed bus | branch/jump/mem/FP/SYSTEM typed capture；trap-exit scrub 保留 | `tb_ooo_pending_dispatch_arbiter` PASS |
| `test-edit` | `codex` | npc/rv64/testbench | `completed` | 旧 generic barrier 预期 | 空 barrier 不误触发、typed capture 互斥测试 | focused 5/5 PASS |
| `docs` | `codex` | specs/memory | `completed` | 改动和验证结果 | spec、README、memory、task-run 更新 | 本目录 |

## 时间线

- 读取项目规范和当前 OoO memory，确认本轮属于跨文件 RTL 架构切片，需要先给出需求、协议规则、状态机、不变量、数据通路约束。
- 定位 `OooPendingDispatchArbiter` 中 lane1 generic capture：旧实现对 branch/jump/FP/memory 都直接输出 `lane1_barrier_base_w`。
- 实现 typed capture：新增 lane1 facts alias，按 `BRANCH/JUMP/MEM/FP_ENABLED/SYSTEM` 分型输出。
- 保留 trap-exit scrub：`trap_exit_capture_lane1_w` 继续等于 `lane1_barrier_base_w`，避免非 trap/exit lane1 owner 不能清 stale valid bit。
- 更新 TB：空 barrier 不再打开 branch/jump/fp/mem capture；branch/jump/fp/mem 各自只打开对应 capture。
- 运行验证并同步 spec、README、memory。

## 验证证据

- `npc/rv64/perf/results/20260627-ooo-pending-lane1-typed/`
- `npc/rv64/perf/results/20260627-ooo-pending-lane1-typed/focused/`
- `npc/rv64/perf/results/20260627-ooo-pending-lane1-typed/all/`
- `make -C npc/rv64 lint` PASS。
- `make -C npc/rv64 -j2` PASS。
