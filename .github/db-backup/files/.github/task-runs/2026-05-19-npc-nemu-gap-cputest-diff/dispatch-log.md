# Dispatch Log

## 基本信息

- `task_id`: `2026-05-19-npc-nemu-gap-cputest-diff`
- `task_slug`: `npc-nemu-gap-cputest-diff`
- `graph_template`: `rv32-reference-loop`
- `log_policy`: `append-only`

## 记录格式

每次节点派发、状态变化、失败恢复、handoff 或证据补充时，追加一个条目。

---

### [2026-05-19 22:07] `recall` - `completed`

- `owner_agent`: `codex`
- `trigger`: 用户要求对比 NEMU 与 NPC 并跑全量 cpu-tests difftest。
- `depends_on`: 无
- `inputs`: `.github/AGENTS.md`、`.github/copilot-instructions.md`、`.github/memory/**`、`npc/single/design/study/**`
- `action`: 读取项目规则、模块记忆和 NPC study 索引/专题笔记。
- `outputs`: 明确需先比较范围、再用真实回归决定是否修复。
- `evidence`: 已读取相关文件。
- `handoff_to`: 无
- `next_step`: `compare-scope`
- `notes`: 涉及 NPC/RTL，但本轮尚未触发 RTL 修改。

### [2026-05-19 22:10] `compare-scope` - `completed`

- `owner_agent`: `codex`
- `trigger`: 需要确认“未实现功能”的实际边界。
- `depends_on`: `recall`
- `inputs`: `abstract-machine/scripts/riscv32-npc.mk`、`nemu/.config`、`npc/single/.config`、`npc/single/vsrc/DecodeUnit.v`、`npc/single/vsrc/NpcCore.v`
- `action`: 对比 guest 编译 ISA、NEMU 可选扩展、NPC 译码/CSR/trap/difftest 接口。
- `outputs`: cpu-tests 的 NPC guest 固定为 `rv32i_zicsr`；NPC 已覆盖 RV32I、Zicsr、MRET/WFI/FENCE、基础 PMEM/MMIO skip-ref 和提交级 GPR/PC difftest。
- `evidence`: `COMMON_CFLAGS += -march=rv32i_zicsr -mabi=ilp32`；NEMU `.config` 额外开启 M/B/C/cache/BPU。
- `handoff_to`: 无
- `next_step`: `build-ref`
- `notes`: NEMU 额外扩展不是本轮 cpu-tests 的硬前置。

### [2026-05-19 22:11] `build-ref` - `completed`

- `owner_agent`: `codex`
- `trigger`: 需要在当前工作区状态下验证构建。
- `depends_on`: `compare-scope`
- `inputs`: 当前源码
- `action`: 构建 difftest reference、lint NPC RTL、确认 NPC 默认构建。
- `outputs`: 构建侧无失败。
- `evidence`: `make -C npc/single difftest-ref` 通过；`make -C npc/single lint` 通过；`make -C npc/single` 显示 `Nothing to be done for 'default'`。
- `handoff_to`: 无
- `next_step`: `npc-cputest-diff`
- `notes`: 未进入修复分支。

### [2026-05-19 22:13] `npc-cputest-diff` - `completed`

- `owner_agent`: `codex`
- `trigger`: 用户要求全量 cpu-tests difftest。
- `depends_on`: `build-ref`
- `inputs`: `riscv32-npc` cpu-tests、NPC difftest reference
- `action`: 运行全量回归。
- `outputs`: 35/35 PASS。
- `evidence`: `timeout 300s make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc run NPC_RUN_ARGS='--diff=default -m 0'`
- `handoff_to`: 无
- `next_step`: `nemu-reference-regression`
- `notes`: `add` 代表项为 `cycles=2319, commits=839, CPI=2.764`。

### [2026-05-19 22:16] `nemu-reference-regression` - `completed`

- `owner_agent`: `codex`
- `trigger`: 对比 NEMU 与 NPC 时补充参考路径健康度。
- `depends_on`: `npc-cputest-diff`
- `inputs`: `riscv32-nemu` cpu-tests、当前 NEMU 配置
- `action`: 运行 NEMU 全量 cpu-tests。
- `outputs`: 35/35 PASS。
- `evidence`: `timeout 180s make -C am-kernels/tests/cpu-tests ARCH=riscv32-nemu run`
- `handoff_to`: 无
- `next_step`: `record`
- `notes`: NEMU 自身回归开启 Spike difftest，并输出 cache/BPU 统计。

### [2026-05-19 22:17] `record` - `completed`

- `owner_agent`: `codex`
- `trigger`: 按 memory protocol 记录稳定结论。
- `depends_on`: `nemu-reference-regression`
- `inputs`: 回归结果与静态对比结论
- `action`: 更新 task-run 与 memory。
- `outputs`: 任务记录完成。
- `evidence`: 本文件、`task-report.md`、相关 memory 文件。
- `handoff_to`: 无
- `next_step`: 无
- `notes`: 本轮无源码改动。
