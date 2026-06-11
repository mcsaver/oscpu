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
- `scripts/agent-env.sh`：非交互 agent/e2e 的仓库软环境入口，设置 `YSYX_HOME/NEMU_HOME/AM_HOME/NPC_HOME/NVBOARD_HOME` 并接入本机可发现的 RISC-V、oss-cad-suite、mill/Java 工具链 PATH。
- `scripts/agent-run.sh`：手动 WSL 工程命令入口，先 source `scripts/agent-env.sh` 再 `exec` 目标命令；Codex 工具命令字符串里不要用 `source ...; make ...` 这类控制符串联来证明软环境生效。外层工具控制符也会影响检索命令，`rg` 正则不要把 `|` 直接写进工具命令字符串，优先用多个 `rg -e` 模式或 pattern 文件。Codex 侧不要并发启动多个 `wsl.exe` 做工程命令；真实构建、e2e、grep 和 git 状态应尽量串行进入同一个 `wsl.exe -d Ubuntu --cd ... -- bash scripts/agent-run.sh ...` 入口，遇到 `Wsl/Service/E_UNEXPECTED` 先做 `wsl.exe -l -v` 健康检查并重试，不能直接归因到 NEMU/Linux gate。
- `scripts/agent-e2e.sh`：profile 调度入口，只负责展开 profile、调用模块函数和生成 task-run。
- `scripts/e2e/lib/*.sh`：公共工具与报告层；`report.sh` 在 profile 节点派发前默认调用 `github-index brief` 生成 `context-brief.md`，记录本轮开工从 DB-backed 开发记忆系统加载的压缩上下文；同时调用 `resolve-profile` 生成 `profile-resolve.md`，记录本轮 profile 的 include 闭包和展开节点序列；`e2e_render_report` 收口时统一清理当前 task-run 文本证据的行尾空白和 CR，并默认调用 `archive-markdown` 把当前 run 的 Markdown 报告/调度日志/context brief/profile resolve 归档进开发记忆数据库，live 文件只保留 DB-backed shim。
- `scripts/e2e/modules/*.sh`：模块执行库，承载具体 gate。

## 执行入口

```bash
scripts/agent-e2e.sh --list-profiles
scripts/agent-e2e.sh --validate-all-profiles
scripts/agent-e2e.sh --profile discovery
scripts/agent-e2e.sh --profile software-flow
scripts/agent-e2e.sh --profile github-index
scripts/agent-e2e.sh --profile contracts
scripts/agent-e2e.sh --profile abstract-machine
scripts/agent-e2e.sh --profile nemu
scripts/agent-e2e.sh --profile nemu-ubuntu
AGENT_E2E_NEMU_UBUNTU_GATE=1 scripts/agent-e2e.sh --profile nemu-ubuntu-gate
AGENT_E2E_NEMU_UBUNTU_FULL_GATE=1 scripts/agent-e2e.sh --profile nemu-ubuntu-full-gate
AGENT_E2E_NEMU_UBUNTU_FULL_SOAK_GATE=1 scripts/agent-e2e.sh --profile nemu-ubuntu-full-soak
scripts/agent-e2e.sh --profile npc
```

`--validate-profile` / `--validate-all-profiles` 只展开 profile 并检查 TSV 字段、模块函数绑定，不执行 NEMU/NPC/回归命令，适合在新增模块或重构 runner 后快速做全量覆盖检查。实际运行任一 profile 时，`agent-e2e.sh` 会先 source `scripts/agent-env.sh`；`discovery` 的 `tool-env-check` 会检查该软环境入口是否真实生效，避免 Codex/WSL 非交互 shell 因 `~/.bashrc` 早退而没有加载用户工具链。`agent-system` discovery 还会检查 `.github/agents`、`.github/e2e/{modules,profiles}`、`.github/instructions`、`.github/memory/modules` 和 `scripts/e2e/modules` 等持久 agent/e2e 源目录没有未跟踪文件；`.github/task-runs` 是运行时证据包，Markdown 报告/派发日志生成后默认归档为 DB-owned stored documents，非 Markdown 日志和二进制证据仍保留在 run 目录。

`software-flow` profile 会检查软件开发全流程 agent、模块记忆、e2e 合约入口和 `hardware-aware-software-loop` 组合钩子，证明软开 agent 不只是可发现，也会被 NEMU/RV64/Linux 这类软件硬件模型任务叠加使用；`nemu-ubuntu` profile 已显式 include `software-flow`，因此后续 NEMU Ubuntu 切片生产守门会先经过软开合约。

`github-index` profile 会检查 `.github` 本地 SQLite 开发记忆系统：实现必须位于 `scripts/dev_memory/` 工程目录，`scripts/github_index_db.py` 只作为兼容 wrapper；默认从文件系统 `.github/**` 和根目录/多 AI 入口 shim 读取原始产物，把索引数据库放到被 Git 忽略的 `.github/cache/github-index.sqlite`，并用临时数据库实际执行 `rebuild/stat/ls/tree/show AGENTS.md/query/summary/load/doctor`；维护 smoke 在临时 mini repo 中执行 `add/search/load/refresh/remove`，证明增删入口只在 `.github` 范围内操作真实文件并同步索引与 chunk；DB-first smoke 在临时 mini repo 中执行 `migrate --yes -> load --source stored -> update-stored -> api --jsonl -> brief/API brief -> brief profile suggestions -> profiles/API profiles catalog -> resolve-profile/API include closure -> archive-markdown task-run -> runs/API runs catalog -> snapshot-stored -> 删除临时 DB -> rehydrate -> audit-db-first -> audit-markdown-coverage --fail-on-live-evidence -> materialize -> restore --yes`，并检查 e2e runner 会在 dispatch 前生成 DB-backed `context-brief.md` 与 `profile-resolve.md`，证明 stored documents、兼容 shim、数据库原文更新、外部 agent bounded startup context、按关键词推荐/列出/展开 e2e profile、每轮 run 的 include closure 证据、历史 task-run 结构化回查、缓存丢失后重灌、task-run Markdown 归档、外部 AI JSONL 只读调用、备份目录、audit 和恢复链路可逆。它只证明目录浏览、检索入口、元数据、压缩概览、按需加载、外部调用协议、agent brief/profile suggestion/profile catalog/profile resolve/runs catalog、DB-first 迁移/归档/重灌能力和状态巡检可用，不替代 Git 历史、人工审阅或模块业务 gate。

NEMU C 侧重构、QMP/GDB、virtio/device model、Linux tools、guest check 或 rootfs 脚本这类任务应理解为 `software-flow` 软件闭环 + `nemu-ubuntu`/`hardware-flow`/对应系统 gate 的组合流程；前者证明软件开发质量，后者证明硬件或系统语义。`nemu-ubuntu` 的节点表必须出现 `software-flow-contract`，否则不能声称软开环境已参与该生产链路。

`nemu-ubuntu` static gate 中的 Linux/tools system-mode NEMU smoke 必须通过 `scripts/nemu-preserved-run.sh` 运行，并用 `smoke-nemu-config-preserve` 输出 `NEMU_CONFIG_HASH_BEFORE/AFTER` 与 `PASS nemu-config-preserve`，证明临时 `riscv64-linux_defconfig` 构建不会永久污染用户当前 NEMU `.config`/`include/config`/`include/generated`。该保护目前是 source-tree 快照/恢复，不等同于完整 `O=build/e2e` out-of-tree 构建。

`contracts` profile 会实际执行所有低成本模块 contract gate，用于检查 agent/module 的规则入口、上游/下游合约和关键文件是否存在，包括 `github-index` 这类开发环境检索辅助层，但不替代 smoke、DiffTest 或 Linux/Ubuntu gate。

`nemu-ubuntu` profile 是 NEMU Ubuntu 切片开发的快速生产守门：检查 Linux/NEMU rootfs 脚本语法、DTS 生成器、NEMU rootfs DTB 1GiB memory/现代 RISC-V ISA 属性、NEMU performance config、NEMU `--machine-info` 机器清单（含 B/E/cache 关闭状态、1GiB memory、RV64 basic PMP entries/active 状态、device_update host poll 512 指令节流、CLINT timebase/CSR time source、CLINT/PLIC interrupt source map、UART/virtio/syscon MMIO/IRQ、实际 MMIO map、SMP/PCI/QMP/GDB/snapshot/async 等 QEMU-like 能力边界，以及 virtio-blk detached/attached、device id、容量、只读状态、raw image mmap read cache、同步多队列、threaded-poll 后端状态和 completion fast flag）、`--monitor-cmd='info r'` 一次性管理入口 smoke、`--qmp=<port>` 启动前/运行期 QMP 查询、cont/stop/system_reset/system_powerdown/quit、RESET/STOP/RESUME/SHUTDOWN event、query-block/query-blockstats attached smoke、query-chardev serial0、query-serial serial0、query-netdev net0、query-rng rng0、query-rtc rtc0、query-interrupts 与 query-pci/query-version/query-kvm/query-qmp-schema/query-events smoke、`--gdbstub=<port>` GDB remote reg/mem RW + single-step/continue/software-breakpoint/hardware-exec-breakpoint/Z2/Z3/Z4 数据 watchpoint/vCont/single-thread query、运行中 Ctrl-C async halt 与 target XML/memory-map/no-ack smoke，以及近期 `virtio-rng` VERSION_1/INDIRECT_DESC/EVENT_IDX/QueueReady layout、`goldfish-rtc`、`virtio-net` 可见性与 hostless DHCP/DNS/TCP burst/ARP/ICMP echo、`virtio-blk MQ/threaded-poll/async completion fast flag/topology`、`CONFIG_WCE/cache_type`、`virtio event idx`、`DISCARD/WRITE_ZEROES`、`pread/pwrite` 后端、virtio-blk direct guest-buffer I/O、virtio-blk raw mmap read cache、virtio-blk QueueNum/vring layout 校验、virtio-blk error-path smoke、串口 TX 宿主缓冲、vaddr PMEM direct fast path、Sv39 host-page TLB、iTLB/dTLB 分离、保守 interpreter basic-block/TB 边界批执行、RVC wide ifetch、解释器预译码 cache、decode-cache direct dispatch、TB 边界中断 fast flag、`time/timeh -> clint_mtime`、AMO/LR/SC misaligned precise exception、LR/SC reservation、PMP access-fault 与 PMP page-table-walk read-deny/A-D-write-deny smokes 等切片是否仍然挂入 guest-check、设备 hook 或 NEMU 裸机 smoke；它还检查真实 guest gate 的 MemTotal hard gate、MemTotal 位于 UART RX stress 之前的顺序断言、guest-check base64 上传/bytes+sha256 校验执行与 prompt 静音钩子、`NEMU_SYSTEMD_INPUT_CHUNK_BYTES/input_chunk_bytes/input_chunk_delay` 串口输入证据、virtio-blk IRQ read-growth 诊断 marker，以及 host console clean 负向断言没有被删掉。`memory.pmp.mode=rv64-basic` 只代表 16-entry PMP CSR + OFF/TOR/NA4/NAPOT + R/W/X/L + 翻译后访问检查 + Sv39 page-table walk PTE read/write 检查基线，不代表完整 PMA/ePMP、所有 PMP 模式/权限/跨页矩阵、多 hart 保护模型或 security signoff；`config.device_update_check_interval=512` 只代表 host 设备轮询第一层 guest 指令数节流，不改变后续 60Hz host time gate；`monitor.oneshot_cmd=enabled` 只代表本地脚本化 SDB 命令入口；`monitor.qmp=startup-query-cont-stop-events-guest-shutdown-runtime-query-chardev-netdev-rng-rtc-interrupts-serial-version-kvm-pci-schema-id-echo-query-events-system-reset-system-powerdown` 只代表启动前 QMP greeting、capabilities、query-status/memory/machines/cpus/block/blockstats(detached/attached)/query-chardev/query-serial/query-netdev/query-rng/query-rtc/query-interrupts/query-pci/query-version/query-kvm/query-qmp-schema/query-events/query-commands、请求 `id` 回显、cont/stop/system_reset/system_powerdown/quit，以及 cont 后同连接 `query-status`/`query-blockstats`/`query-chardev`/`query-serial`/`query-netdev`/`query-rng`/`query-rtc`/`query-interrupts`/`stop`/`cont`/`system_powerdown`/`quit` 和 `STOP/RESUME/SHUTDOWN` 事件的窄 runtime-query/pause/event/device/interrupt introspection 基线，只代表 command 级最小 schema introspection、基础请求/响应关联和事件列表 introspection，不代表完整 QMP/QAPI schema、完整 JSON parser、完整中断控制器模型、热插拔、migration、blockdev、event 总线、chardev-add/remove、TAP/NAT 外网或完整运行中异步控制；`debug.gdbstub=remote-startup-rw-step-cont-swbreak-hbreak-watch-vcont-async-stop-target-xml-memory-map-noack` 只代表单 hart 可读写寄存器/PMEM、同步单步执行一条指令、continue-until-exit、Z0/z0 PC-match 软件断点、Z1/z1 PC-match 硬件执行断点、Z2/z2 write watchpoint、Z3/z3 read watchpoint、Z4/z4 access watchpoint、vCont;c/s、运行中 Ctrl-C async halt、单 hart 线程查询并提供 RV64 target.xml、单 RAM memory-map 与 QStartNoAckMode no-ack 协商的 GDB remote 基线，不代表 pre-access rollback、DMA/设备写监控、多 hart/thread 调度、non-stop/async notification 或完整 GDB server；`device.virtio_blk.multiqueue=enabled` 只代表多个 virtqueue；`device.virtio_blk.async=threaded-poll` 代表 host block I/O 已由后台 worker 执行、guest used ring/IRQ 仍由主线程轮询完成；`device.virtio_blk.async_completion_fast_flag=1` 只代表空闲 poll 可跳过 completion mutex，不代表 eventfd/epoll、PCI/SMP/QEMU 通用 block layer 或多 outstanding 性能签核；`smoke-nemu-virtio-blk-error` 只代表 4 个 collectable 错误请求 status 写回和 2 个 uncollectable 坏链 used.len=0/IRQ completion 基线，不代表随机 descriptor fuzz 或完整 QEMU block layer。`nemu-ubuntu-gate` 在此基础上提供可选默认 minimized/systemd 真实 guest gate，并扫描已修启动日志 warning/error 回归；默认 SKIP，只有设置 `AGENT_E2E_NEMU_UBUNTU_GATE=1` 才会运行耗时较长的 `check-nemu-systemd-guest`。`nemu-ubuntu-full-gate` 是 full rootfs 的一等 focused 入口，默认同样 SKIP，只有设置 `AGENT_E2E_NEMU_UBUNTU_FULL_GATE=1` 才会运行 `check-nemu-systemd-guest-full`，用于证明 full server-like Ubuntu rootfs 的真实 NEMU/systemd guest gate。`nemu-ubuntu-full-soak` 是 full rootfs 的重型稳定性入口，默认 SKIP，只有设置 `AGENT_E2E_NEMU_UBUNTU_FULL_SOAK_GATE=1` 才会运行 `check-nemu-systemd-guest-full-soak`，默认组合 full userland runtime hard gate、rootfs overlay、300s soak、32MiB rootfs stress、256 个元数据文件、128 轮进程循环、1024 行 UART RX stress 和 4 个 4MiB 并发 direct IO；它仍不替代多小时 soak、QEMU 等价、SMP/PCI/TAP/NAT/snapshot 或桌面 Ubuntu。

`system_reset` 的完成钩子必须看到 startup/prelaunch QMP 连接上 `system_reset`、`RESET` event、QMP return、`query-status=prelaunch`、随后 `cont` 仍从 reset vector 进入，以及 `QMP system_reset requested` 日志；这只是启动前 CPU/CLINT/PLIC/PC reset 基线，不是运行中热复位、guest reboot、设备全量 reset 或 migration 能力。

`system_powerdown` 的完成钩子必须看到 runtime QMP 连接上 `cont -> system_powerdown`、`RESUME/SHUTDOWN` event、NEMU `rc=0` 和 `QMP system_powerdown requested` 日志；这只是管理端主动停机命令基线，不是完整 QAPI 电源管理、guest graceful shutdown、运行中热复位或 migration 能力。

`goldfish-rtc` 的完成钩子已升级到 Linux RTC UIE/alarm 路径：真实 guest gate 必须出现 `__NEMU_CHECK_RTC0_HWCLOCK__` 与 `__NEMU_CHECK_PASS__:hwclock-rtc0-show`，static/QMP gate 必须证明 RTC 时间源为 `host-realtime-epoch+clint-mtime`、虚拟 timebase 为 10MHz，并且 PLIC interrupt line 只由 `interrupt_pending && irq_enabled` 拉高。这个钩子防止只用 `/dev/rtc0`、sysfs 或 QMP 可见性误判 RTC 已完成。

`smoke-nemu-pmp-pagewalk` 与 `smoke-nemu-pmp-pagewalk-ad` 是 PMP/Sv39 隐式页表访问防回归 gate：前者构造 S-mode 代码可正常取指、但测试 VA 第三级 PTE 页被 PMP 拒绝的场景，要求 walker 读 PTE 失败报告为原始 load 的 access fault，且 `mtval=TEST_VA`；后者把第三级 PTE 页设为 PMP 只读，并让叶 PTE 缺少 A/D 位，要求 walker 自动写回 A 位时被 PMP 拒绝，同样按原始 load 投递 access fault。slice contract 同时检查 `isa_riscv*_mmu_fault_cause`、`pmp-page-table-read/write`、`vaddr_translate_fault_cause_for_type`、两个 Makefile target 和 smoke marker；这补齐 page-table walk PMP cause 通道，但不声明完整 PMA/ePMP 或所有特权级/跨页矩阵。

`config.interpreter_ifetch_page_cache=1` 是 NEMU Ubuntu performance profile 的取指 host-page cache 防回归字段：它只说明 RV64 宽取指路径会缓存当前虚拟页对应的 PMEM host page，tag 包含虚拟页、`satp` 和特权级；`sfence.vma`/TLB flush、`fence.i` 和写入当前缓存物理页都会清空该单页 cache。它不代表完整物理代码页失效体系、TB cache、host code cache、DBT 或 JIT。

`config.interpreter_decode_cache_entries=32768` 是 NEMU Ubuntu performance profile 的容量防回归字段：它只说明 RV64 解释器 direct-mapped 预译码 cache 在该配置下为 32768 项，仍按 `PC + raw-inst` 比对并由 `fence.i` 清空，不代表完整 TB cache、host code cache、代码页失效体系、DBT 或 JIT。

`config.interpreter_decode_direct_dispatch=1` 是 NEMU Ubuntu performance profile 的 decode-cache 命中分发防回归字段：它只说明 RV64 预译码 cache 命中后使用 computed-goto 分发表减少 `switch(kind)` 分发开销；取指、原始指令比对、`fence.i` 失效、异常和执行 helper 语义不变，不代表完整 direct-threaded interpreter、TB chaining、host code cache、DBT 或 JIT。

`config.interpreter_tb_max_inst=32` 是 NEMU Ubuntu performance profile 的 basic-block 长度防回归字段：它只说明保守 interpreter TB 在该配置下单块最多退休 32 条 guest 指令；branch/jump、SYSTEM、store/AMO、fence 和压缩控制/存储指令仍会提前收束，不代表 TB chaining、host code cache、DBT 或 JIT。

`device.serial.host_rx_poll_interval=4` 是 NEMU Ubuntu performance profile 的串口宿主输入轮询防回归字段：它只说明全局 60Hz device tick 下每 4 次才做一次 stdin/FIFO `select/read`；guest 主动读 UART 寄存器仍会立即轮询宿主输入，staging 到 16550 FIFO 的投递仍按 FIFO room 进行，不代表事件驱动串口后端或完整交互终端。

`nemu-ubuntu` static gate 还会检查当前实际 Linux `.config`，要求 autofs 内建、BPF syscall、cgroup-BPF 和 seccomp filter 等 Ubuntu/systemd 启动能力存在；`Linux/Makefile` 把 `$(LINUX_IMAGE)` 显式依赖到 `build-linux.sh`，避免配置脚本修过后仍复用旧 Image，让 direct `make run` 再次出现 `autofs4 Function not implemented` 或 BPF/cgroup firewalling warning。
focused gate 对关机阶段的 `systemd-journald` `WATCHDOG=1` `Connection refused` 会做上下文分类：只有同时看到 `System Power Off`、`reboot: Power down`、`syscon-reset` poweroff 和 `HIT GOOD TRAP` 时才判为非致命 shutdown 收尾噪声；否则仍视为需要调查的 notify/socket 异常。

focused gate 对串口输入也有独立守卫：host 侧只向 FIFO/stdin 写字节，NEMU `SerialPort` 先进入 staging，再按 16550 RX FIFO 剩余空间投递给 guest，Linux 通过 DTS `serial0:115200n8` 把它接到 `/dev/ttyS0`。因此 `NEMU_SYSTEMD_INPUT_CHUNK_BYTES`、guest-check base64 上传、bytes+sha256 校验和 serial input model 日志都属于生产输入契约；删除这些钩子会让长脚本重新暴露 shell 命令粘连/截断风险。

`nemu-ubuntu` static/slice gate 还会检查 rootfs 默认包清单和 guest marker，确保 `lsb-release` 被纳入 Ubuntu systemd rootfs，并在 guest 内看到 `lsb_release -a` 报告 Ubuntu 22.04。`htop` 不进入 hard gate；它是 minimized rootfs 上的可选交互工具，不能和 `systemctl`、`hostnamectl`、`free/top/uptime` 或 `lsb_release` 这类基础启动/身份命令混为一类。

`nemu-ubuntu` slice contract 同时检查 RV32/RV64 ISA 命名边界：RV64 源码目录必须使用 `isa_riscv64_*` 平台符号，RV32 源码目录继续使用 `isa_riscv32_*`，CPU/设备/内存/monitor 通用层只使用 `isa_riscv_*` 中性别名；RV64 `inst.c` 只作为抽象组织层 include `inst/*.c`，热路径 helper 必须在 RV64 inst 文件集合中使用 `exec_rv64i_*`/`exec_rv64c`，并由 `riscv64/filelist.mk` 排除这些 unity-included 片段的独立编译；RV64/RV32 `isa-def.h` 只导出各自宽度的 CPU/CSR/decode 类型；Kconfig 也必须按 RV64/RV32 条件 source 对应目录，且 `RVE`/`SOC_SIM` 等 RV32-only 配置不得残留在 RV64 Kconfig 中，避免 menuconfig 或完成判定再次把 RV32 文件/函数名当作 RV64 事实。

`nemu-ubuntu` static/QMP gate 还会跟踪 virtio-net 标准 feature ledger：machine-info 和 QMP `query-netdev` 必须暴露 `VERSION_1/MAC/MRG_RXBUF/STATUS/MTU/CTRL_VQ/CTRL_RX/CTRL_VLAN/CTRL_RX_EXTRA/GUEST_ANNOUNCE/CTRL_MAC_ADDR/SPEED_DUPLEX/INDIRECT_DESC/EVENT_IDX`，启动前 driver-feature 必须保持 zero baseline，并且 `device.virtio_net.mtu=1500`/QMP `mtu=1500` 要与 config offset 10/11 的 MTU 字段一致，`device.virtio_net.speed_mbps=1000`、`duplex=full` 和 QMP `speed-mbps=1000`/`duplex=full` 要与 config offset 12..16 的 SPEED_DUPLEX 字段一致；guest focused gate 继续逐 bit 检查 Linux 驱动实际协商的 feature，并要求 `/sys/class/net/<iface>/mtu=1500`、`speed=1000`、`duplex=full`，防止源码 feature bit、管理面账本、virtio config space 和 Linux 可见 feature 漂移。`SPEED_DUPLEX` 只代表 Linux 可见的名义链路速率/双工配置区账本，不代表真实吞吐、TAP/NAT 或 host 网络后端性能。`CTRL_VQ` 声明并实现第 3 个 control virtqueue 的完成路径；`CTRL_RX` 当前实现 hostless RX mode 的 `PROMISC`/`ALLMULTI` 1-byte payload 状态记录和 ACK OK，并支持随 `CTRL_RX` 可用的 `MAC/TABLE_SET`，只记录 unicast/multicast 表项计数，不执行真实过滤；`CTRL_VLAN` 当前实现 `ADD/DEL` 2-byte VLAN ID payload、ACK OK、filter-count/last-vid 账本和 runtime 统计，但不按 VLAN 表过滤以太帧；`CTRL_RX_EXTRA` 当前实现 `ALLUNI/NOMULTI/NOUNI/NOBCAST` 1-byte payload 状态记录和 ACK OK，只作为 RX mode 账本，不承诺真实过滤；当前 Linux 6.6 `virtio_net.c` 定义 UAPI bit20 但未把 `CTRL_RX_EXTRA` 列入驱动 feature table，因此 focused guest 若未协商 bit20 会记录 `virtio-net-feature-ctrl-rx-extra-driver-optional`，命令语义由裸机 control smoke 强验证。`GUEST_ANNOUNCE` 当前只实现 link announce 请求位、config-change IRQ 和 `CTRL_ANNOUNCE/ACK` 清位账本，不承诺真实邻居广播传播；`CTRL_MAC_ADDR` 当前只支持 `MAC/ADDR_SET` 改设备配置区和管理面可见 MAC，不承诺真实 MAC filter。`smoke-nemu-virtio-net-ctrl` 会依次提交 `CTRL_RX/PROMISC=1`、`MAC/TABLE_SET`、`MAC/ADDR_SET`、`CTRL_RX/ALLUNI=1`、`VLAN/ADD=42`、`VLAN/DEL=42`、`ANNOUNCE/ACK` 和未知 control command，要求 ACK OK/OK/OK/OK/OK/OK/OK/ERR、used.len=1、IRQ 可 ACK 和运行期 `ctrl=8/1 ctrl_rx=2 ctrl_rx_extra=1 ctrl_vlan=2 ctrl_announce=1 ctrl_mac_table=1 ctrl_mac_addr=1 promisc=1 alluni=1 vlan_active=0 vlan_last=42 announce_pending=0 announce_requested=1 mac_uni=1 mac_multi=1 mac=02:00:5e:00:53:02`；真实 focused guest 还会要求 `virtio-net-feature-ctrl-rx`、`virtio-net-feature-ctrl-vlan`、`virtio-net-feature-guest-announce`、`virtio-net-feature-ctrl-mac-addr` 与 `virtio-net-feature-speed-duplex`，并在退出统计中看到 Ubuntu 驱动实际下发过 RX mode、MAC table 和 announce ACK 命令且 `ctrl_errors=0`。该 gate 不代表真实 VLAN/MAC/RX 过滤、MQ/offload、TAP/NAT 外网、多队列网络或完整 QEMU virtio-net。

`nemu-ubuntu` static gate 还会运行 `nemu-rootfs-overlay-machine-info`，用真实 NEMU 打开 Ubuntu rootfs + sparse overlay，检查 `overlay=enabled/write_target=overlay/overlay_dirty_sectors=0`、overlay 初始 0 blocks 和临时文件清理。focused guest gate 默认给 Ubuntu rootfs 挂 `NEMU_SYSTEMD_ROOTFS_OVERLAY=$(NEMU_SYSTEMD_CHECK_LOG_DIR)/rootfs-overlay.raw`，NEMU 通过 `--block-overlay` 把写入落到 sparse overlay，host 侧再校验 backing rootfs `size:mtime` 前后不变。该证据只证明生产 gate 隔离和快照第一阶段，不替代 qcow2、通用 snapshot/checkpoint 或 QEMU 级 block layer。

`nemu-ubuntu-gate` focused guest gate 还会在 NEMU 退出后检查 `virtio-blk async runtime submitted=<n> completed=<n> pending=0 done=0`，要求 submitted 大于 0 且 completed 等于 submitted，用真实 Ubuntu rootfs 压力证明 threaded-poll worker 被实际使用；同一阶段还会检查 `virtio-net runtime ...` 统计，要求真实 Ubuntu DHCP/DNS/TCP/ICMP/ARP 路径让 TX/RX 与协议 reply 计数为正，且 `tx_errors/rx_drops/rx_pending=0`。

## 解读原则

- PASS 只证明该节点的 success criteria；不能越级证明未执行节点。
- SKIP 表示当前配置/依赖不满足该 gate，不能作为已验证证据。
- FAIL 后必须按 `regression-debug-loop` 扩图，而不是重复同一个命令。
- profile 是可升级配置；当一个 contract gate 变得稳定，应升级为 smoke/regression gate。
