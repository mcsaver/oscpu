# Modular Agent E2E

本目录把原本分散在 `AGENTS.md`、`.github/agents/*.agent.md`、`.github/instructions/*.instructions.md`、`.github/memory/**` 中的“语言规则”，转换成可执行、可记录、可扩展的 e2e 流水线配置。

## 分层

| 层级 | 内容 | 产物 |
| --- | --- | --- |
| L0 发现层 | 规则入口、profile、模块契约、工具链 | discovery 证据 |
| L1 模块层 | 每个 agent/module 的最小 contract gate | module profile 报告 |
| L2 跨模块层 | AM/NEMU、NPC target、SoC/DiffTest 等闭环 | cross-module profile 报告 |
| L3 系统层 | RV64 Linux/Ubuntu、display、tapeout readiness | system profile 报告 |
| L4 记录/优化层 | task-run、memory、known-issues、模板升级 | 可追溯闭环 |

## 文件职责

- `profiles/*.tsv`：profile 编排。每行一个节点，格式为 `node_id|module|function|owner_agent|inputs|outputs`。
- `modules/*.md`：每个 agent/module 的 e2e 合约，说明上下游、gate、证据和升级路线。
- `scripts/agent-e2e.sh`：profile 调度入口，只负责展开 profile、调用模块函数和生成 task-run。
- `scripts/e2e/lib/*.sh`：公共工具与报告层。
- `scripts/e2e/modules/*.sh`：模块执行库，承载具体 gate。

## 执行入口

```bash
scripts/agent-e2e.sh --list-profiles
scripts/agent-e2e.sh --validate-all-profiles
scripts/agent-e2e.sh --profile discovery
scripts/agent-e2e.sh --profile contracts
scripts/agent-e2e.sh --profile abstract-machine
scripts/agent-e2e.sh --profile nemu
scripts/agent-e2e.sh --profile nemu-ubuntu
AGENT_E2E_NEMU_UBUNTU_GATE=1 scripts/agent-e2e.sh --profile nemu-ubuntu-gate
scripts/agent-e2e.sh --profile npc
```

`--validate-profile` / `--validate-all-profiles` 只展开 profile 并检查 TSV 字段、模块函数绑定，不执行 NEMU/NPC/回归命令，适合在新增模块或重构 runner 后快速做全量覆盖检查。

`contracts` profile 会实际执行所有低成本模块 contract gate，用于检查 agent/module 的规则入口、上游/下游合约和关键文件是否存在，但不替代 smoke、DiffTest 或 Linux/Ubuntu gate。

`nemu-ubuntu` profile 是 NEMU Ubuntu 切片开发的快速生产守门：检查 Linux/NEMU rootfs 脚本语法、DTS 生成器、NEMU rootfs DTB 1GiB memory/现代 RISC-V ISA 属性、NEMU performance config、NEMU `--machine-info` 机器清单（含 B/E/cache 关闭状态、1GiB memory、CLINT timebase/CSR time source、UART/virtio/syscon MMIO/IRQ、实际 MMIO map、SMP/PCI/QMP/GDB/snapshot/async 等 QEMU-like 能力边界，以及 virtio-blk detached/attached、device id、容量、只读状态、raw image mmap read cache、同步多队列和 threaded-poll 后端状态）、`--monitor-cmd='info r'` 一次性管理入口 smoke、`--qmp=<port>` 启动前/运行期 QMP 查询、cont/stop/quit 与 query-block/query-blockstats attached smoke、`--gdbstub=<port>` 启动前 GDB remote smoke，以及近期 `virtio-rng` VERSION_1/EVENT_IDX/QueueReady layout、`goldfish-rtc`、`virtio-net` 可见性与 hostless DHCP/DNS/TCP burst/ARP/ICMP echo、`virtio-blk MQ/threaded-poll/topology`、`CONFIG_WCE/cache_type`、`virtio event idx`、`DISCARD/WRITE_ZEROES`、`pread/pwrite` 后端、virtio-blk direct guest-buffer I/O、virtio-blk raw mmap read cache、virtio-blk QueueNum/vring layout 校验、串口 TX 宿主缓冲、vaddr PMEM direct fast path、Sv39 host-page TLB、iTLB/dTLB 分离、保守 interpreter basic-block/TB 边界批执行、RVC wide ifetch、解释器预译码 cache、TB 边界中断 fast flag、`time/timeh -> clint_mtime`、AMO/LR/SC misaligned precise exception smoke 等切片是否仍然挂入 guest-check、设备 hook 或 NEMU 裸机 smoke；它还检查真实 guest gate 的 MemTotal hard gate、MemTotal 位于 UART RX stress 之前的顺序断言、guest-check base64 上传/bytes+sha256 校验执行与 prompt 静音钩子、`NEMU_SYSTEMD_INPUT_CHUNK_BYTES/input_chunk_bytes/input_chunk_delay` 串口输入证据、virtio-blk IRQ read-growth 诊断 marker，以及 host console clean 负向断言没有被删掉。`monitor.oneshot_cmd=enabled` 只代表本地脚本化 SDB 命令入口；`monitor.qmp=startup-query-cont-stop-runtime-query` 只代表启动前 QMP greeting、capabilities、query-status/memory/machines/cpus/block/blockstats(detached/attached)/commands、cont/stop/quit，以及 cont 后同连接 `query-status`/`query-blockstats`/`stop`/`cont`/`quit` 的窄 runtime-query/pause 基线，不代表完整 QMP schema、热插拔、migration、blockdev、event、chardev 或完整运行中异步控制；`debug.gdbstub=remote-readonly` 只代表启动前可读寄存器/PMEM 的 GDB remote 基线，不代表运行中异步暂停、断点、写寄存器或完整 GDB server；`device.virtio_blk.multiqueue=enabled` 只代表多个 virtqueue；`device.virtio_blk.async=threaded-poll` 代表 host block I/O 已由后台 worker 执行、guest used ring/IRQ 仍由主线程轮询完成，不代表 PCI/SMP/QEMU 通用 block layer 或多 outstanding 性能签核。`nemu-ubuntu-gate` 在此基础上提供可选真实 guest gate，并扫描已修启动日志 warning/error 回归；默认 SKIP，只有设置 `AGENT_E2E_NEMU_UBUNTU_GATE=1` 才会运行耗时较长的 `check-nemu-systemd-guest`。

`nemu-ubuntu` static gate 还会检查当前实际 Linux `.config`，要求 autofs 内建、BPF syscall、cgroup-BPF 和 seccomp filter 等 Ubuntu/systemd 启动能力存在；`Linux/Makefile` 把 `$(LINUX_IMAGE)` 显式依赖到 `build-linux.sh`，避免配置脚本修过后仍复用旧 Image，让 direct `make run` 再次出现 `autofs4 Function not implemented` 或 BPF/cgroup firewalling warning。
focused gate 对关机阶段的 `systemd-journald` `WATCHDOG=1` `Connection refused` 会做上下文分类：只有同时看到 `System Power Off`、`reboot: Power down`、`syscon-reset` poweroff 和 `HIT GOOD TRAP` 时才判为非致命 shutdown 收尾噪声；否则仍视为需要调查的 notify/socket 异常。

focused gate 对串口输入也有独立守卫：host 侧只向 FIFO/stdin 写字节，NEMU `SerialPort` 先进入 staging，再按 16550 RX FIFO 剩余空间投递给 guest，Linux 通过 DTS `serial0:115200n8` 把它接到 `/dev/ttyS0`。因此 `NEMU_SYSTEMD_INPUT_CHUNK_BYTES`、guest-check base64 上传、bytes+sha256 校验和 serial input model 日志都属于生产输入契约；删除这些钩子会让长脚本重新暴露 shell 命令粘连/截断风险。

`nemu-ubuntu` static/slice gate 还会检查 rootfs 默认包清单和 guest marker，确保 `lsb-release` 被纳入 Ubuntu systemd rootfs，并在 guest 内看到 `lsb_release -a` 报告 Ubuntu 22.04。`htop` 不进入 hard gate；它是 minimized rootfs 上的可选交互工具，不能和 `systemctl`、`hostnamectl`、`free/top/uptime` 或 `lsb_release` 这类基础启动/身份命令混为一类。

`nemu-ubuntu` slice contract 同时检查 RV32/RV64 ISA 命名边界：RV64 源码目录必须使用 `isa_riscv64_*` 平台符号，RV32 源码目录继续使用 `isa_riscv32_*`，CPU/设备/内存/monitor 通用层只使用 `isa_riscv_*` 中性别名；RV64 `inst.c` 里的热路径 helper 必须使用 `exec_rv64i_*`/`exec_rv64c`，RV64/RV32 `isa-def.h` 只导出各自宽度的 CPU/CSR/decode 类型；Kconfig 也必须按 RV64/RV32 条件 source 对应目录，且 `RVE`/`SOC_SIM` 等 RV32-only 配置不得残留在 RV64 Kconfig 中，避免 menuconfig 或完成判定再次把 RV32 文件/函数名当作 RV64 事实。

`nemu-ubuntu` static gate 还会运行 `nemu-rootfs-overlay-machine-info`，用真实 NEMU 打开 Ubuntu rootfs + sparse overlay，检查 `overlay=enabled/write_target=overlay/overlay_dirty_sectors=0`、overlay 初始 0 blocks 和临时文件清理。focused guest gate 默认给 Ubuntu rootfs 挂 `NEMU_SYSTEMD_ROOTFS_OVERLAY=$(NEMU_SYSTEMD_CHECK_LOG_DIR)/rootfs-overlay.raw`，NEMU 通过 `--block-overlay` 把写入落到 sparse overlay，host 侧再校验 backing rootfs `size:mtime` 前后不变。该证据只证明生产 gate 隔离和快照第一阶段，不替代 qcow2、通用 snapshot/checkpoint 或 QEMU 级 block layer。

`nemu-ubuntu-gate` focused guest gate 还会在 NEMU 退出后检查 `virtio-blk async runtime submitted=<n> completed=<n> pending=0 done=0`，要求 submitted 大于 0 且 completed 等于 submitted，用真实 Ubuntu rootfs 压力证明 threaded-poll worker 被实际使用。

## 解读原则

- PASS 只证明该节点的 success criteria；不能越级证明未执行节点。
- SKIP 表示当前配置/依赖不满足该 gate，不能作为已验证证据。
- FAIL 后必须按 `regression-debug-loop` 扩图，而不是重复同一个命令。
- profile 是可升级配置；当一个 contract gate 变得稳定，应升级为 smoke/regression gate。
