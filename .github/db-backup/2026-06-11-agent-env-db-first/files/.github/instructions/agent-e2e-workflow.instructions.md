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
6. 非交互软环境真实加载：`scripts/agent-e2e.sh` 必须先 source `scripts/agent-env.sh`，`tool-env-check` 必须证明 `YSYX_HOME/NEMU_HOME/AM_HOME/NPC_HOME` 等变量和本机可选工具链 PATH 生效，不能只依赖交互式 `~/.bashrc`；手动 WSL 工程命令优先走 `scripts/agent-run.sh <command> ...`，不要用 `source ...; command` 这类在外层工具里可能被控制符切分的写法作为软环境证据；外层工具控制符也会影响检索命令，`rg` 正则不要把 `|` 写进工具命令字符串，优先用多个 `rg -e` 模式或 pattern 文件；Codex 侧不要并发启动多个 `wsl.exe` 做工程命令，真实构建/e2e/grep/git 应尽量串行落到同一个 `wsl.exe -d Ubuntu --cd ... -- bash scripts/agent-run.sh ...` 入口，遇到 `Wsl/Service/E_UNEXPECTED` 先用 `wsl.exe -l -v` 做宿主健康检查并重试，而不是把它当成 NEMU/Linux gate 失败；`agent-system` 还必须检查 `scripts/agent-env.sh` 能修复只继承 sourced marker、但工作区变量缺失的半初始化环境。
7. 持久 agent/e2e 源文件可复现：`agent-system` 必须检查 `.github/agents`、`.github/e2e/{modules,profiles}`、`.github/instructions`、`.github/memory/modules` 和 `scripts/e2e/modules` 等目录没有未跟踪文件；`.github/task-runs` 属于运行时证据包，生成后由任务收尾阶段按大小和类型审计后纳入跟踪。

## 命令入口

```bash
scripts/agent-e2e.sh --list-profiles
scripts/agent-e2e.sh --validate-all-profiles
scripts/agent-e2e.sh --profile discovery
scripts/agent-e2e.sh --profile agent-system
scripts/agent-e2e.sh --profile software-flow
scripts/agent-e2e.sh --profile github-index
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
AGENT_E2E_NEMU_UBUNTU_FULL_GATE=1 scripts/agent-e2e.sh --profile nemu-ubuntu-full-gate
AGENT_E2E_NEMU_UBUNTU_FULL_SOAK_GATE=1 scripts/agent-e2e.sh --profile nemu-ubuntu-full-soak
scripts/agent-e2e.sh --profile rv64-linux
```

profile 语义：

- `--validate-all-profiles`：展开全部 profile，检查 TSV 字段和 `scripts/e2e/modules/*.sh` 函数绑定，不执行具体 gate。
- `discovery`：规则发现、非交互软环境自检、工具自检和 `npc/sim status`，不跑仿真。
- `software-flow`：检查软件开发全流程 agent、模块记忆、profile 和 e2e 合约入口，并检查 `hardware-aware-software-loop` 是否接入 `software-flow`、`hardware-flow`、`nemu`、coordinator、蓝图和 e2e workflow。它证明 NEMU/RV64/Linux 这类 C/Python/Shell/Make/Kconfig 软件硬件模型任务会先叠加软开闭环，再由 `nemu-ubuntu`、`hardware-flow`、`rv64-linux`、`difftest` 或 target gate 做系统/硬件语义收口；`nemu-ubuntu` profile 已显式 include `software-flow`，节点表必须出现 `software-flow-contract`。
- `github-index`：检查 `.github` 本地 SQLite 开发记忆系统。该 profile 用临时数据库实际执行 `rebuild/stat/ls/tree/show AGENTS.md/query/summary/load/doctor`，证明索引器能读取 `.github/**` 原始文件和根目录/多 AI 入口 shim，生成目录视图、元数据、状态、查询入口、chunk/token 压缩概览和按需加载结果；维护 smoke 在临时 mini repo 执行 `add/search/load/refresh/remove`，证明增删入口只在 `.github` 范围内操作真实文件并同步索引与 chunk；DB-first smoke 在临时 mini repo 执行 `migrate --yes -> load --source stored -> materialize -> restore --yes`，证明 stored documents、兼容 shim、备份目录和恢复链路可逆；默认数据库 `.github/cache/github-index.sqlite` 被 Git 忽略。它不替代 Git 历史、人工审阅或各模块业务 gate。
- `contracts`：实际执行所有低成本模块 contract gate，覆盖 `ysyx-coordinator`、`agent-system`、`hardware-flow`、`software-flow`、`github-index`、`abstract-machine`、`am-kernels`、`nemu`、`npc`、`ysyx-soc`、`difftest`、`yosys-sta`、`rv64-linux`、`linux-device`、`display-vga`、`verilator-tapeout`、`fceux-am`、`nvboard`、`digital-logic` 等 agent/module 的规则入口和关键文件存在性。
- `quick`：`discovery` + 当前 NEMU AM-compatible ISA 对应的 `cpu-tests add` 最小参考烟测；若当前 NEMU 不是 `CONFIG_TARGET_AM=y`，该 smoke 会记录为 `SKIP`，不改写用户正在使用的 NEMU 配置。
- `nemu-ubuntu`：NEMU Ubuntu rootfs 切片开发的快速生产守门，检查 Linux/NEMU rootfs 脚本语法、DTS 生成器、rootfs DTB 1GiB memory/现代 RISC-V ISA 属性、performance config、NEMU `--machine-info` 机器清单（B/E/cache 状态、memory、RV64 basic PMP entries/active 状态、device_update host poll 512 指令节流、CLINT 10MHz timebase、CSR time source、CLINT/PLIC interrupt source map、UART/virtio/syscon MMIO/IRQ、实际 MMIO map、SMP/PCI/QMP/GDB/snapshot/async 等 QEMU-like 能力边界，以及 virtio-blk detached/attached、device id、容量、只读状态、raw image mmap read cache、同步多队列、threaded-poll 后端状态和 completion fast flag），并运行 `--monitor-cmd='info r'` 一次性管理入口 smoke、`--qmp=<port>` 启动前/运行期 QMP 查询、cont/stop/system_reset/system_powerdown/quit、RESET/STOP/RESUME/SHUTDOWN event、query-block/query-blockstats attached smoke、query-chardev serial0、query-serial serial0、query-netdev net0、query-rng rng0、query-rtc rtc0、query-interrupts 与 query-pci/query-version/query-kvm/query-qmp-schema/query-events smoke、`--gdbstub=<port>` GDB remote reg/mem RW + single-step/continue/software-breakpoint/hardware-exec-breakpoint/Z2/Z3/Z4 数据 watchpoint/vCont/single-thread query、运行中 Ctrl-C async halt + target XML/memory-map/no-ack smoke 与 `nemu-rootfs-overlay-machine-info` rootfs + sparse overlay 检查；overlay gate 验证 `overlay=enabled/write_target=overlay/overlay_dirty_sectors=0`、初始 0 blocks 和临时文件清理；`memory.pmp.mode=rv64-basic` 只代表 16-entry PMP CSR + OFF/TOR/NA4/NAPOT + R/W/X/L + 翻译后访问检查 + Sv39 page-table walk PTE read/write 检查基线，不代表完整 PMA/ePMP、所有 PMP 模式/权限/跨页矩阵、多 hart 保护模型或 security signoff；`config.device_update_check_interval=512` 只代表 host 设备轮询第一层 guest 指令数节流，不改变后续 60Hz host time gate；`monitor.oneshot_cmd=enabled` 只代表本地脚本化 SDB 命令入口；`monitor.qmp=startup-query-cont-stop-events-guest-shutdown-runtime-query-chardev-netdev-rng-rtc-interrupts-serial-version-kvm-pci-schema-id-echo-query-events-system-reset-system-powerdown` 只代表启动前 greeting、capabilities、query-status/memory/machines/cpus/block/blockstats(detached/attached)/query-chardev/query-serial/query-netdev/query-rng/query-rtc/query-interrupts/query-pci/query-version/query-kvm/query-qmp-schema/query-events/query-commands、请求 id 回显、cont/stop/system_reset/system_powerdown/quit，以及 cont 后同连接 `query-status`/`query-blockstats`/`query-chardev`/`query-serial`/`query-netdev`/`query-rng`/`query-rtc`/`query-interrupts`/`stop`/`cont`/`system_powerdown`/`quit` 和 `STOP/RESUME/SHUTDOWN` 事件的窄 runtime-query/pause/event/device/interrupt introspection 基线，只代表 command 级最小 schema introspection、基础请求/响应关联和事件列表 introspection，不代表完整 QMP/QAPI schema、完整 JSON parser、完整中断控制器模型、event 总线、热插拔、migration、blockdev、chardev-add/remove、TAP/NAT 外网或完整运行中异步控制；`debug.gdbstub=remote-startup-rw-step-cont-swbreak-hbreak-watch-vcont-async-stop-target-xml-memory-map-noack` 只代表单 hart 可读写寄存器/PMEM、同步单步执行一条指令、continue-until-exit、Z0/z0 PC-match 软件断点、Z1/z1 PC-match 硬件执行断点、Z2/z2 write watchpoint、Z3/z3 read watchpoint、Z4/z4 access watchpoint、vCont;c/s、运行中 Ctrl-C async halt、单 hart 线程查询并提供 RV64 target.xml、单 RAM memory-map 与 QStartNoAckMode no-ack 协商的 GDB remote 基线，不代表 pre-access rollback、DMA/设备写监控、多 hart/thread 调度、non-stop/async notification 或完整 GDB server；`device.virtio_blk.multiqueue=enabled` 只代表多个 virtqueue；`device.virtio_blk.async=threaded-poll` 代表 host block I/O 已由后台 worker 执行、guest used ring/IRQ 仍由主线程轮询完成；`device.virtio_blk.async_completion_fast_flag=1` 只代表空闲 poll 可跳过 completion mutex，不代表 eventfd/epoll、PCI/SMP/QEMU 通用 block layer 或多 outstanding 性能签核；同时检查近期设备/性能/ISA 切片（含 virtio-rng VERSION_1/INDIRECT_DESC/EVENT_IDX/QueueReady layout、goldfish-rtc、virtio-net 可见性与 hostless DHCP/DNS/TCP burst/ARP/ICMP echo、virtio-blk MQ/threaded-poll/async completion fast flag/topology、CONFIG_WCE/cache_type、event idx、DISCARD/WRITE_ZEROES、pread/pwrite 后端、virtio-blk direct guest-buffer I/O、virtio-blk raw mmap read cache、virtio-blk QueueNum/vring layout 校验、串口 TX 宿主缓冲、vaddr PMEM direct fast path、Sv39 host-page TLB、iTLB/dTLB 分离、保守 interpreter basic-block/TB 边界批执行、RVC wide ifetch、解释器预译码 cache、decode-cache direct dispatch、TB 边界中断 fast flag、`time/timeh -> clint_mtime`、AMO/LR/SC misaligned precise exception、LR/SC reservation、PMP access-fault 与 PMP page-table-walk read-deny/A-D-write-deny smokes）的 guest-check marker、设备 hook 或 NEMU 裸机 smoke 是否仍在闭环中；同时检查真实 guest gate 的 MemTotal、MemTotal 位于 UART RX stress 之前的顺序断言、guest-check base64 上传/bytes+sha256 校验执行与 prompt 静音钩子、`NEMU_SYSTEMD_INPUT_CHUNK_BYTES/input_chunk_bytes/input_chunk_delay` 串口输入证据、virtio-blk IRQ read-growth 诊断 marker 与 host console clean 负向断言仍覆盖已修 warning/error 模式。
  `goldfish-rtc` 不再只以 `/dev/rtc0`、sysfs 或 `query-rtc` 可见为完成证据；真实 guest gate 必须硬检查 `hwclock --show --rtc=/dev/rtc0`，static/QMP gate 必须检查 `time-source=host-realtime-epoch+clint-mtime`、10MHz virtual timebase，以及 `interrupt_line == interrupt_pending && irq_enabled`。
  `system_reset` 不再只以命令名进入 `query-commands` 为完成证据；QMP smoke 必须在 startup/prelaunch 连接上执行 `system_reset`，并同时看到 `RESET` event、QMP return、`query-status=prelaunch`、随后 `cont` 从 reset vector 进入和 `QMP system_reset requested` 日志。该钩子只证明启动前 CPU/CLINT/PLIC/PC reset 基线，不代表运行中热复位、guest reboot、设备全量 reset、migration 或 QEMU 管理面完成。
  `system_powerdown` 不再只以命令名进入 `query-commands` 为完成证据；QMP smoke 必须在 runtime 连接上执行 `cont -> system_powerdown`，并同时看到 `RESUME/SHUTDOWN` event、QMP return、NEMU `rc=0` 和 `QMP system_powerdown requested` 日志。该钩子只证明管理端主动停机命令基线，不代表完整 QAPI 电源管理、guest graceful shutdown、运行中热复位、migration 或 QEMU 管理面完成。
  `virtio-blk` 错误路径不再只以源码中存在 `VIRTIO_BLK_S_IOERR`/`VIRTIO_BLK_S_UNSUPP` 为完成证据；static gate 必须运行 `make -C Linux/tools smoke-nemu-virtio-blk-error`，证明错误方向、非法 DMA range、超容量 sector 和未知 request type 都能写 status、推进 used ring、产生/ACK IRQ，同时证明 direct descriptor cycle 与 nested indirect table 这类链收集失败路径不会写 status byte、会以 used.len=0 完成并产生/ACK IRQ，最终 GOOD TRAP。
  `config.interpreter_ifetch_page_cache=1` 是该 profile 的取指 host-page cache 防回归字段：它只说明 RV64 宽取指路径会缓存当前虚拟页对应的 PMEM host page，tag 包含虚拟页、`satp` 和特权级；`sfence.vma`/TLB flush、`fence.i` 和写入当前缓存物理页都会清空该单页 cache。它不代表完整物理代码页失效体系、TB cache、host code cache、DBT 或 JIT。
  `config.interpreter_decode_cache_entries=32768` 是该 profile 的容量防回归字段：它只说明 RV64 解释器 direct-mapped 预译码 cache 在 Ubuntu performance 配置下为 32768 项，仍按 `PC + raw-inst` 比对并由 `fence.i` 清空，不代表完整 TB cache、host code cache、代码页失效体系、DBT 或 JIT。
  `config.interpreter_decode_direct_dispatch=1` 是该 profile 的 decode-cache 命中分发防回归字段：它只说明 RV64 预译码 cache 命中后使用 computed-goto 分发表减少 `switch(kind)` 分发开销；取指、原始指令比对、`fence.i` 失效、异常和执行 helper 语义不变，不代表完整 direct-threaded interpreter、TB chaining、host code cache、DBT 或 JIT。
  `config.interpreter_tb_max_inst=32` 是该 profile 的 basic-block interpreter 长度防回归字段：它只说明 Ubuntu performance 配置下单个保守 TB 最多退休 32 条 guest 指令；branch/jump、SYSTEM、store/AMO、fence 和压缩控制/存储指令仍会提前收束，不代表 TB chaining、host code cache、DBT 或 JIT。
  `device.serial.host_rx_poll_interval=4` 是该 profile 的串口宿主输入轮询防回归字段：它只说明全局 device tick 每 4 次才 poll 一次 stdin/FIFO；UART MMIO read 仍立即 poll host，staging bytes 仍按 16550 FIFO room 投递，不代表 epoll/eventfd、PTY/socket 或完整交互终端完成。
  该 profile 还会运行 `make ARCH=riscv64-nemu check-nemu-kernel-config`，检查当前实际 Linux `.config` 中 autofs、BPF syscall、cgroup-BPF 和 seccomp filter 等 Ubuntu/systemd 启动能力，并要求 `$(LINUX_IMAGE)` 依赖 `build-linux.sh`，避免配置脚本变更后旧 Image 继续制造 `autofs4 Function not implemented` 或 BPF/cgroup firewalling warning。
  该 profile 还会检查串口输入链路：host 自动化只注入 FIFO/stdin 字节流，NEMU `SerialPort` staging 按 16550 RX FIFO room 分批投递，Linux 通过 DTS `serial0:115200n8` 接到 `ttyS0`。`NEMU_SYSTEMD_INPUT_CHUNK_BYTES`、base64 上传、bytes+sha256 校验和 serial input model 日志都属于生产输入契约，用来防止长脚本重新出现 shell 命令粘连/截断。
  该 profile 还会检查 Ubuntu 常用命令的 rootfs 契约：systemd rootfs 默认包清单必须包含 `lsb-release`，rootfs 实物检查必须看到 `/usr/bin/lsb_release`，guest-check 必须看到 `lsb_release -a` 报告 Ubuntu 22.04。`htop` 是 minimized rootfs 上的可选交互工具，不作为启动正确性 hard gate。
  该 profile 还检查 RV32/RV64 ISA 命名边界：RV64 源码必须使用 `isa_riscv64_*`，RV64 `inst.c` 只作为抽象组织层 include `inst/*.c`，基础/压缩 helper 必须在 RV64 inst 文件集合中使用 `exec_rv64i_*`/`exec_rv64c`，`riscv64/filelist.mk` 必须排除 unity-included `inst/*.c` 独立编译，RV64 `isa-def.h` 只导出 `riscv64_*` CPU/CSR/decode 类型；RV32 源码继续使用 `isa_riscv32_*` 和 `riscv32_*` 类型，CPU/设备/内存/monitor 通用层只使用 `isa_riscv_*` 别名；`nemu/Kconfig` 必须按 RV64/RV32 条件 source 对应 Kconfig 文件，且 `RVE`/`SOC_SIM` 等 RV32-only 配置不得残留在 RV64 Kconfig 中。
- `nemu-ubuntu-gate`：`nemu-ubuntu` + 可选默认 minimized/systemd 真实 focused guest gate；默认 SKIP，只有设置 `AGENT_E2E_NEMU_UBUNTU_GATE=1` 才运行耗时较长的 `make -C Linux ARCH=riscv64-nemu check-nemu-systemd-guest`，并扫描已修启动日志 warning/error 回归。该 gate 默认设置 `NEMU_SYSTEMD_ROOTFS_OVERLAY=$(NEMU_SYSTEMD_CHECK_LOG_DIR)/rootfs-overlay.raw`，用 `--block-overlay` 保护基准 rootfs，并要求 host 侧 backing `size:mtime` 不变；这只是生产隔离/快照第一阶段，不等同于 qcow2 或通用 snapshot/checkpoint。
- `nemu-ubuntu-full-gate`：`nemu-ubuntu` + 可选 full rootfs 真实 focused guest gate；默认 SKIP，只有设置 `AGENT_E2E_NEMU_UBUNTU_FULL_GATE=1` 才运行耗时较长的 `make -C Linux ARCH=riscv64-nemu check-nemu-systemd-guest-full`。该 profile 是 full server-like Ubuntu rootfs 的一等 e2e 入口，但仍不代表 QEMU 等价、SMP/PCI/TAP/NAT/snapshot/桌面 Ubuntu 或长期 soak。
- `nemu-ubuntu-full-soak`：`nemu-ubuntu` + 可选 full rootfs 重型稳定性 gate；默认 SKIP，只有设置 `AGENT_E2E_NEMU_UBUNTU_FULL_SOAK_GATE=1` 才运行耗时更长的 `make -C Linux ARCH=riscv64-nemu check-nemu-systemd-guest-full-soak`。该 profile 组合 full userland runtime hard gate、rootfs overlay 隔离、300s soak、32MiB rootfs stress、256 个元数据文件、128 轮进程循环、1024 行 UART RX stress 和 4 个 4MiB 并发 direct IO job，但仍不代表多小时 soak、QEMU 等价、SMP/PCI/TAP/NAT/snapshot 或桌面 Ubuntu。
  focused gate 还会检查 NEMU 退出时的 `virtio-blk async runtime submitted/completed/pending/done` 统计，要求 Ubuntu rootfs 压力期间 worker 实际处理过请求且无未完成请求，防止只靠 machine-info capability 字段误判 threaded-poll 已被真实路径覆盖；也会检查 `virtio-net runtime` TX/RX、ARP/ICMP/DHCP/DNS/TCP 和 HTTP health 统计，要求真实 Ubuntu 网络 probes 产生正向 reply 且无 `tx_errors/rx_drops/rx_pending` 残留，防止只看 guest marker 而漏掉 NEMU 设备侧数据路径证据。
  virtio-net feature 类 gate 需要三层证据：源码 feature bit 与 machine-info hook、QMP `query-netdev` 的 runtime JSON、guest `/sys` feature bit。MTU 这类带配置区语义的 feature 还必须额外检查 virtio-net config offset 10/11、machine-info/QMP `mtu=1500` 和 guest `/sys/class/net/<iface>/mtu=1500`；`SPEED_DUPLEX` 这类配置区账本 feature 还必须额外检查 config offset 12..16、machine-info/QMP `speed=1000`/`duplex=full` 和 guest `/sys/class/net/<iface>/speed`/`duplex`，但不能把名义链路设置越界说成真实吞吐、TAP/NAT 或 host 网络后端性能。CTRL_VQ 这类会改变队列拓扑的 feature 还必须额外检查 queue 数、control queue smoke、unsupported command ACK/used ring/IRQ completion 和 runtime `ctrl=<commands>/<errors>` 统计；CTRL_RX/CTRL_RX_EXTRA/CTRL_VLAN/GUEST_ANNOUNCE 这类具体 control command 还必须验证 device negotiated bit、对应 command payload 或 config status、ACK OK、状态账本和 QMP/machine-info 字段。guest `/sys` 只代表当前 Linux 驱动实际请求/协商的 feature；如果内核 UAPI 定义了某 bit 但驱动 feature table 未请求它，例如当前 Linux 6.6 的 `CTRL_RX_EXTRA`，focused gate 应输出 driver-optional marker，不能把驱动未协商误判成设备未实现。`MAC_TABLE_SET` 随 `CTRL_RX` 可用时，要单独证明 table payload 解析、ACK OK、unicast/multicast 账本和 focused `ctrl_errors=0`；`CTRL_RX_EXTRA` 可用时，要单独证明 `ALLUNI/NOMULTI/NOUNI/NOBCAST` 1-byte payload 的状态账本，但不能把它越界说成真实 RX 过滤；`CTRL_VLAN` 可用时，要单独证明 `ADD/DEL` 2-byte VLAN ID payload、ACK OK、filter-count/last-vid 账本、QMP/machine-info 字段和 guest bit19，但不能把它越界说成真实 VLAN 过滤；`GUEST_ANNOUNCE` 可用时，要单独证明 config status 的 `ANNOUNCE` 请求位、config-change IRQ、`CTRL_ANNOUNCE/ACK` 无 payload ACK OK、pending 清位账本、QMP/machine-info 字段和 guest bit21，但不能把它越界说成真实邻居广播传播；`CTRL_MAC_ADDR` 可用时，要单独证明 `MAC/ADDR_SET` payload、ACK OK、设备 MAC/config/QMP/runtime 账本和 guest feature bit，但不能把它越界说成真实 MAC 过滤或完整 host 网络后端。不能把 control queue 存在说成 `CTRL_RX/CTRL_RX_EXTRA/CTRL_VLAN/GUEST_ANNOUNCE/CTRL_MAC/MQ/offload` 已实现，也不能把 `CTRL_RX`/`CTRL_RX_EXTRA`/`CTRL_VLAN`/`GUEST_ANNOUNCE` 的状态命令越界说成 MQ/offload、过滤语义、TAP/NAT 或完整 QEMU 网络栈。源码 contract 不应直接匹配运行时 JSON 文本，尤其是 C 字符串里的 `\"...\"` 和 grep 正则特殊字符；运行时 JSON 由 QMP smoke 负责验证。
- `reference`：`discovery` + `scripts/am-regression.sh --no-bench --skip-devscan`。
- `full`：`discovery` + 完整 `scripts/am-regression.sh`。
- `npc`：`discovery` + `am-kernels/abstract-machine` contract + `npc/sim` contract + `riscv32-npc` 全量 cpu-tests target gate；该 gate 跟随当前 `npc/sim` 后端配置，不自动切换 single/soc/rv64。
- 模块 profile：如 `abstract-machine`、`am-kernels`、`nemu`、`npc-single`、`ysyx-soc`、`rv64-linux` 等，先跑 contract gate，再按 profile 深度逐步升级。
- 软件硬件模型任务：如 NEMU C 侧重构、QMP/GDB、virtio/device model、Linux tools、guest check 或 rootfs 脚本，先跑或等价覆盖 `software-flow` contract，再叠加对应模块 profile；例如 NEMU Ubuntu 切片应按 `hardware-aware-software-loop` 解释为 `software-flow` 软件闭环 + `nemu-ubuntu`/`nemu-ubuntu-gate` 系统 gate。当前 `nemu-ubuntu.tsv` 已 include `software-flow`，若未来拆分 profile，必须保留同等节点或更强软件 gate。
- NEMU Ubuntu 切片中直接调用 `Linux/tools` 的 system-mode NEMU smoke 时，必须优先使用 `scripts/nemu-preserved-run.sh` 或同等保护；`smoke-nemu-config-preserve` 需要输出 `NEMU_CONFIG_HASH_BEFORE/AFTER` 和 `PASS nemu-config-preserve`，证明临时切到 `riscv64-linux_defconfig` 后会恢复用户原 `.config`、`.config.old`、`include/config` 与 `include/generated`。当前这是 source-tree 快照/恢复保护，不要把它越级描述成完整 `O=build/e2e` out-of-tree 构建。

可选环境变量：

- `AGENT_E2E_NEMU_ARCH=riscv32-nemu|riscv64-nemu`：覆盖 NEMU reference smoke 的 AM 架构。
- `AGENT_E2E_FORCE_SMOKE=1`：即使当前 NEMU 不是 `CONFIG_TARGET_AM=y` 也强制运行 smoke；仅在你明确知道当前配置可兼容时使用。
- `AGENT_E2E_NPC_FULL_TIMEOUT=<seconds>`：覆盖 `npc` profile 全量 cpu-tests 的超时，默认 3600 秒。
- `AGENT_E2E_NPC_RUN_ARGS='<args>'`：覆盖 `npc` profile 传给 NPC target 的运行参数；未设置时默认 `--no-progress -m 0`，并仅在当前后端 `.config` 启用 `CONFIG_NPC_DIFFTEST=y` 时自动追加 `--diff=default`。
- `AGENT_E2E_NEMU_UBUNTU_GATE=1`：允许 `nemu-ubuntu-gate` profile 运行真实 NEMU Ubuntu focused guest gate；未设置时该节点 SKIP。
- `AGENT_E2E_NEMU_UBUNTU_TIMEOUT=<seconds>`：覆盖 focused guest gate 的 host timeout，默认 1700 秒。
- `AGENT_E2E_NEMU_UBUNTU_FULL_GATE=1`：允许 `nemu-ubuntu-full-gate` profile 运行真实 full rootfs focused guest gate；未设置时该节点 SKIP。
- `AGENT_E2E_NEMU_UBUNTU_FULL_TIMEOUT=<seconds>`：覆盖 full rootfs focused guest gate 的 host timeout；未设置时退回 `AGENT_E2E_NEMU_UBUNTU_TIMEOUT` 或默认 1700 秒。
- `AGENT_E2E_NEMU_UBUNTU_FULL_SOAK_GATE=1`：允许 `nemu-ubuntu-full-soak` profile 运行真实 full rootfs soak guest gate；未设置时该节点 SKIP。
- `AGENT_E2E_NEMU_UBUNTU_FULL_SOAK_TIMEOUT=<seconds>`：覆盖 full rootfs soak guest gate 的 host timeout；未设置时 profile 默认 2400 秒，与直接运行 Make target 的 `NEMU_SYSTEMD_SOAK_CHECK_TIMEOUT=2400` 对齐。
- `YSYX_AGENT_ENV_ENABLE_XILINX=1`：允许 `scripts/agent-env.sh` 额外 source Vivado/Vitis 设置；默认关闭，避免普通 NEMU/Ubuntu e2e 被重型 EDA 初始化拖慢。

## 解读规则

- `discovery/quick` 通过只说明 AI 规则入口、基础工具和最小参考路径可用，不证明 NPC/SoC/RV64/Linux/Ubuntu/PPA 正确。
- 含 `SKIP` 的报告只能证明跳过前的节点可用；被跳过节点不能当作已验证证据。
- 涉及 target 行为的任务，至少需要 `npc` profile 或任务对应静态图的 target/difftest 证据。
- 涉及 RV64 Linux/Ubuntu 的任务，必须继续使用 `rv64-ubuntu-probe-loop`、`rv64-ubuntu-rootfs-loop`、`rv64gc-userland-loop` 或相关 focused gate，不能用本 e2e gate 越级替代。
- 任一节点失败时，后续结论不得依赖该节点；应按 `regression-debug-loop` 插入 `reproduce / collect-log / localize / fix / rerun`。

## 记录要求

- 脚本自动生成 task-run 证据包；完成本类任务后，agent 仍必须手动更新 `.github/memory/project-status.md` 与 `.github/memory/modules/agent-system.md`。
- `scripts/e2e/lib/report.sh` 必须在 `e2e_render_report` 收口时清理当前 task-run 下 `.md/.tsv/.log/.cmd/.txt` 的行尾空白和 CR；`agent-system` profile 要保留 sanitizer 定义、调用和 run-dir 限制检查，避免证据包生成后再人工修 `git diff --check`。
- 若失败暴露新的稳定问题，应追加 `.github/memory/known-issues.md`。
- 记忆中只写稳定结论和影响范围；逐节点日志、命令和 stdout/stderr 保留在 task-run 的 `evidence/` 下。
- 新增模块或 agent 时，必须同时补 `.github/e2e/modules/<module>.md`、`.github/e2e/profiles/<module>.tsv` 和对应 `scripts/e2e/modules/` gate，避免退回纯提示词配置。
