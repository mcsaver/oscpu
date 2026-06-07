---
description: "模块化 AI 开发环境 e2e 流程。用于把 agent/instructions/memory 的语言配置转换为 profile、模块合约、可执行 gate 和 task-run 证据包。"
applyTo: ".github/**, AGENTS.md, CLAUDE.md, GEMINI.md, CONVENTIONS.md, .windsurfrules, .cursor/rules/agents.mdc, scripts/agent-e2e.sh, scripts/e2e/**"
---

# Agent E2E Workflow

当用户要求“搭建/验证 AI 开发环境”“降低 AI 不确定性”“跑一遍 e2e 流程”“检查 agent 规则是否生效”或修改 `.github/` 工作流体系后，应优先使用本流程。当前目标不是单脚本自检，而是将各模块 agent 转换为可独立演进的 e2e profile。

## 目标

把 AI 的判断前提从“读到一些规则后主观相信”降到“有一份可复核证据包”：

1. 规则发现链存在：根入口、`.github/AGENTS.md`、Copilot 补充规则、memory、task-run 模板都能被找到。
2. 模块合约存在：`.github/e2e/modules/*.md` 为每个 agent/module 写清上游、下游、gate、证据和升级路线。
3. profile 可执行：`.github/e2e/profiles/*.tsv` 将模块合约编排为节点图。
4. 模块库分层：`scripts/e2e/lib/*.sh` 负责公共能力和记录，`scripts/e2e/modules/*.sh` 负责具体模块 gate。
5. 证据落盘：每轮生成 `.github/task-runs/<日期>-agent-e2e-*/task-report.md` 与 `dispatch-log.md`。

## 命令入口

```bash
scripts/agent-e2e.sh --list-profiles
scripts/agent-e2e.sh --validate-all-profiles
scripts/agent-e2e.sh --profile discovery
scripts/agent-e2e.sh --profile agent-system
scripts/agent-e2e.sh --profile contracts
scripts/agent-e2e.sh --profile quick
scripts/agent-e2e.sh --profile reference
scripts/agent-e2e.sh --profile full
scripts/agent-e2e.sh --profile npc
scripts/agent-e2e.sh --profile abstract-machine
scripts/agent-e2e.sh --profile am-kernels
scripts/agent-e2e.sh --profile nemu
scripts/agent-e2e.sh --profile nemu-ubuntu
AGENT_E2E_NEMU_UBUNTU_GATE=1 scripts/agent-e2e.sh --profile nemu-ubuntu-gate
scripts/agent-e2e.sh --profile rv64-linux
```

profile 语义：

- `--validate-all-profiles`：展开全部 profile，检查 TSV 字段和 `scripts/e2e/modules/*.sh` 函数绑定，不执行具体 gate。
- `discovery`：规则发现、工具自检和 `npc/sim status`，不跑仿真。
- `contracts`：实际执行所有低成本模块 contract gate，覆盖 `ysyx-coordinator`、`agent-system`、`hardware-flow`、`abstract-machine`、`am-kernels`、`nemu`、`npc`、`ysyx-soc`、`difftest`、`yosys-sta`、`rv64-linux`、`linux-device`、`display-vga`、`verilator-tapeout`、`fceux-am`、`nvboard`、`digital-logic` 等 agent/module 的规则入口和关键文件存在性。
- `quick`：`discovery` + 当前 NEMU AM-compatible ISA 对应的 `cpu-tests add` 最小参考烟测；若当前 NEMU 不是 `CONFIG_TARGET_AM=y`，该 smoke 会记录为 `SKIP`，不改写用户正在使用的 NEMU 配置。
- `nemu-ubuntu`：NEMU Ubuntu rootfs 切片开发的快速生产守门，检查 Linux/NEMU rootfs 脚本语法、DTS 生成器、performance config，以及近期设备/性能切片（含 virtio-rng、goldfish-rtc、virtio-blk topology、CONFIG_WCE/cache_type、event idx、DISCARD/WRITE_ZEROES、pread/pwrite 后端、串口 TX 宿主缓冲、vaddr PMEM direct fast path、Sv39 host-page TLB、iTLB/dTLB 分离、保守 interpreter basic-block/TB 边界批执行、RVC wide ifetch、解释器预译码 cache、TB 边界中断 fast flag）的 guest-check marker 或设备 hook 是否仍在闭环中。
- `nemu-ubuntu-gate`：`nemu-ubuntu` + 可选真实 focused guest gate；默认 SKIP，只有设置 `AGENT_E2E_NEMU_UBUNTU_GATE=1` 才运行耗时较长的 `make -C Linux ARCH=riscv64-nemu check-nemu-systemd-guest`。
- `reference`：`discovery` + `scripts/am-regression.sh --no-bench --skip-devscan`。
- `full`：`discovery` + 完整 `scripts/am-regression.sh`。
- `npc`：`discovery` + `am-kernels/abstract-machine` contract + `npc/sim` contract + `riscv32-npc` 全量 cpu-tests target gate；该 gate 跟随当前 `npc/sim` 后端配置，不自动切换 single/soc/rv64。
- 模块 profile：如 `abstract-machine`、`am-kernels`、`nemu`、`npc-single`、`ysyx-soc`、`rv64-linux` 等，先跑 contract gate，再按 profile 深度逐步升级。

可选环境变量：

- `AGENT_E2E_NEMU_ARCH=riscv32-nemu|riscv64-nemu`：覆盖 NEMU reference smoke 的 AM 架构。
- `AGENT_E2E_FORCE_SMOKE=1`：即使当前 NEMU 不是 `CONFIG_TARGET_AM=y` 也强制运行 smoke；仅在你明确知道当前配置可兼容时使用。
- `AGENT_E2E_NPC_FULL_TIMEOUT=<seconds>`：覆盖 `npc` profile 全量 cpu-tests 的超时，默认 3600 秒。
- `AGENT_E2E_NPC_RUN_ARGS='<args>'`：覆盖 `npc` profile 传给 NPC target 的运行参数；未设置时默认 `--no-progress -m 0`，并仅在当前后端 `.config` 启用 `CONFIG_NPC_DIFFTEST=y` 时自动追加 `--diff=default`。
- `AGENT_E2E_NEMU_UBUNTU_GATE=1`：允许 `nemu-ubuntu-gate` profile 运行真实 NEMU Ubuntu focused guest gate；未设置时该节点 SKIP。
- `AGENT_E2E_NEMU_UBUNTU_TIMEOUT=<seconds>`：覆盖 focused guest gate 的 host timeout，默认 1700 秒。

## 解读规则

- `discovery/quick` 通过只说明 AI 规则入口、基础工具和最小参考路径可用，不证明 NPC/SoC/RV64/Linux/Ubuntu/PPA 正确。
- 含 `SKIP` 的报告只能证明跳过前的节点可用；被跳过节点不能当作已验证证据。
- 涉及 target 行为的任务，至少需要 `npc` profile 或任务对应静态图的 target/difftest 证据。
- 涉及 RV64 Linux/Ubuntu 的任务，必须继续使用 `rv64-ubuntu-probe-loop`、`rv64-ubuntu-rootfs-loop`、`rv64gc-userland-loop` 或相关 focused gate，不能用本 e2e gate 越级替代。
- 任一节点失败时，后续结论不得依赖该节点；应按 `regression-debug-loop` 插入 `reproduce / collect-log / localize / fix / rerun`。

## 记录要求

- 脚本自动生成 task-run 证据包；完成本类任务后，agent 仍必须手动更新 `.github/memory/project-status.md` 与 `.github/memory/modules/agent-system.md`。
- 若失败暴露新的稳定问题，应追加 `.github/memory/known-issues.md`。
- 记忆中只写稳定结论和影响范围；逐节点日志、命令和 stdout/stderr 保留在 task-run 的 `evidence/` 下。
- 新增模块或 agent 时，必须同时补 `.github/e2e/modules/<module>.md`、`.github/e2e/profiles/<module>.tsv` 和对应 `scripts/e2e/modules/` gate，避免退回纯提示词配置。
