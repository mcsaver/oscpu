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
- `nemu-ubuntu`：NEMU Ubuntu rootfs 切片开发的快速生产守门，检查 Linux/NEMU rootfs 脚本语法、DTS 生成器、rootfs DTB 1GiB memory/现代 RISC-V ISA 属性、performance config、NEMU `--machine-info` 机器清单（B/E/cache 状态、memory、CLINT 10MHz timebase、CSR time source、UART/virtio/syscon MMIO/IRQ、实际 MMIO map、SMP/PCI/QMP/GDB/snapshot/async 等 QEMU-like 能力边界，以及 virtio-blk detached/attached、device id、容量、只读状态、raw image mmap read cache、同步多队列和 threaded-poll 后端状态），并运行 `--monitor-cmd='info r'` 一次性管理入口 smoke、`--qmp=<port>` 启动前/运行期 QMP 查询、cont/stop/quit 与 query-block/query-blockstats attached smoke、`--gdbstub=<port>` 启动前 GDB remote smoke 与 `nemu-rootfs-overlay-machine-info` rootfs + sparse overlay 检查；overlay gate 验证 `overlay=enabled/write_target=overlay/overlay_dirty_sectors=0`、初始 0 blocks 和临时文件清理；`monitor.oneshot_cmd=enabled` 只代表本地脚本化 SDB 命令入口；`monitor.qmp=startup-query-cont-stop-runtime-query` 只代表启动前 greeting、capabilities、query-status/memory/machines/cpus/block/blockstats(detached/attached)/commands、cont/stop/quit，以及 cont 后同连接 `query-status`/`query-blockstats`/`stop`/`cont`/`quit` 的窄 runtime-query/pause 基线，不代表完整 QMP schema、event、热插拔、migration、blockdev、chardev 或完整运行中异步控制；`debug.gdbstub=remote-readonly` 只代表启动前可读寄存器/PMEM 的 GDB remote 基线，不代表运行中异步暂停、断点、写寄存器或完整 GDB server；`device.virtio_blk.multiqueue=enabled` 只代表多个 virtqueue；`device.virtio_blk.async=threaded-poll` 代表 host block I/O 已由后台 worker 执行、guest used ring/IRQ 仍由主线程轮询完成，不代表 PCI/SMP/QEMU 通用 block layer 或多 outstanding 性能签核；同时检查近期设备/性能/ISA 切片（含 virtio-rng VERSION_1/EVENT_IDX/QueueReady layout、goldfish-rtc、virtio-net 可见性与 hostless DHCP/DNS/TCP burst/ARP/ICMP echo、virtio-blk MQ/threaded-poll/topology、CONFIG_WCE/cache_type、event idx、DISCARD/WRITE_ZEROES、pread/pwrite 后端、virtio-blk direct guest-buffer I/O、virtio-blk raw mmap read cache、virtio-blk QueueNum/vring layout 校验、串口 TX 宿主缓冲、vaddr PMEM direct fast path、Sv39 host-page TLB、iTLB/dTLB 分离、保守 interpreter basic-block/TB 边界批执行、RVC wide ifetch、解释器预译码 cache、TB 边界中断 fast flag、`time/timeh -> clint_mtime`、AMO/LR/SC misaligned precise exception smoke）的 guest-check marker、设备 hook 或 NEMU 裸机 smoke 是否仍在闭环中；同时检查真实 guest gate 的 MemTotal、MemTotal 位于 UART RX stress 之前的顺序断言、guest-check base64 上传/bytes+sha256 校验执行与 prompt 静音钩子、`NEMU_SYSTEMD_INPUT_CHUNK_BYTES/input_chunk_bytes/input_chunk_delay` 串口输入证据、virtio-blk IRQ read-growth 诊断 marker 与 host console clean 负向断言仍覆盖已修 warning/error 模式。
  该 profile 还会运行 `make ARCH=riscv64-nemu check-nemu-kernel-config`，检查当前实际 Linux `.config` 中 autofs、BPF syscall、cgroup-BPF 和 seccomp filter 等 Ubuntu/systemd 启动能力，并要求 `$(LINUX_IMAGE)` 依赖 `build-linux.sh`，避免配置脚本变更后旧 Image 继续制造 `autofs4 Function not implemented` 或 BPF/cgroup firewalling warning。
  该 profile 还会检查串口输入链路：host 自动化只注入 FIFO/stdin 字节流，NEMU `SerialPort` staging 按 16550 RX FIFO room 分批投递，Linux 通过 DTS `serial0:115200n8` 接到 `ttyS0`。`NEMU_SYSTEMD_INPUT_CHUNK_BYTES`、base64 上传、bytes+sha256 校验和 serial input model 日志都属于生产输入契约，用来防止长脚本重新出现 shell 命令粘连/截断。
  该 profile 还会检查 Ubuntu 常用命令的 rootfs 契约：systemd rootfs 默认包清单必须包含 `lsb-release`，rootfs 实物检查必须看到 `/usr/bin/lsb_release`，guest-check 必须看到 `lsb_release -a` 报告 Ubuntu 22.04。`htop` 是 minimized rootfs 上的可选交互工具，不作为启动正确性 hard gate。
  该 profile 还检查 RV32/RV64 ISA 命名边界：RV64 源码必须使用 `isa_riscv64_*`，RV64 `inst.c` 的基础/压缩 helper 必须使用 `exec_rv64i_*`/`exec_rv64c`，RV64 `isa-def.h` 只导出 `riscv64_*` CPU/CSR/decode 类型；RV32 源码继续使用 `isa_riscv32_*` 和 `riscv32_*` 类型，CPU/设备/内存/monitor 通用层只使用 `isa_riscv_*` 别名；`nemu/Kconfig` 必须按 RV64/RV32 条件 source 对应 Kconfig 文件，且 `RVE`/`SOC_SIM` 等 RV32-only 配置不得残留在 RV64 Kconfig 中。
- `nemu-ubuntu-gate`：`nemu-ubuntu` + 可选真实 focused guest gate；默认 SKIP，只有设置 `AGENT_E2E_NEMU_UBUNTU_GATE=1` 才运行耗时较长的 `make -C Linux ARCH=riscv64-nemu check-nemu-systemd-guest`，并扫描已修启动日志 warning/error 回归。该 gate 默认设置 `NEMU_SYSTEMD_ROOTFS_OVERLAY=$(NEMU_SYSTEMD_CHECK_LOG_DIR)/rootfs-overlay.raw`，用 `--block-overlay` 保护基准 rootfs，并要求 host 侧 backing `size:mtime` 不变；这只是生产隔离/快照第一阶段，不等同于 qcow2 或通用 snapshot/checkpoint。
  focused gate 还会检查 NEMU 退出时的 `virtio-blk async runtime submitted/completed/pending/done` 统计，要求 Ubuntu rootfs 压力期间 worker 实际处理过请求且无未完成请求，防止只靠 machine-info capability 字段误判 threaded-poll 已被真实路径覆盖。
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
