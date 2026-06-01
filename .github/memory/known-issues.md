# 已知问题与调试历史

> 本文件记录遇到的 bug、调试过程和解决方案，避免重复踩坑。

## 活跃问题
<!-- 当前未解决的问题 -->

### [43] RV64 Ubuntu 长跑中 Verilator 8 线程比单线程更慢

- **模块**: NPC RV64 / Verilator / Ubuntu 性能仿真
- **现象**: 用户允许在 14-core 主机上调用 8 core 后，按 Ubuntu shell initramfs 而不是轻量 smoke 做实测。单线程 `threads()=1` 的 `smoke-ubuntu-shell-watch UBUNTU_INITRAMFS_MAX_CYCLES=120000000` 已进入 Linux 并到 `clocksource: Switched to clocksource riscv_clocksource`，最终 `cycles=120000000/commits=24517449/CPI=4.894`，host time `362499028 us`，`67634 inst/s`。显式 `VERILATOR_THREADS=8` 重编后生成物确认 `threads()=8`，同一窗口 guest 进度和 commits 完全一致，但 host time `731380226 us`，`33522 inst/s`，约为单线程 0.50x；因此当前默认不应启用 8 线程。
- **根因**: Verilator 5.020 对当前 RTL 报 `UNOPTTHREADS`，提示调度器无法提供请求的并行度。当前 RV64 sim top/core 被大量跨模块组合依赖、DPI memory/MMIO 边界和单 hart 单时钟热路径限制，mtask 同步/worker 调度开销超过并行收益；多线程只保证 host 并行执行，不会改善 guest CPI 或 Linux 真实进度。
- **修复**: 已按用户要求回退当前活动 `npc/rv64/build/NpcSimTop` 到单线程，重建后确认 `VNpcSimTop::threads() const { return 1; }`。Makefile 默认仍 `VERILATOR_THREADS ?= 1`；仅保留显式实验入口，`VERILATOR_THREADS>1` 时追加 `-Wno-UNOPTTHREADS` 使该警告作为性能诊断而非 fatal，并用 `VERILATOR_BUILD_JOBS` 控制生成物编译并行度。后续若要再尝试多核，应先用 `--prof-exec`/mtask profile 或重构 sim top/RTL 分区，再用同类 Ubuntu 窗口 A/B，不能凭轻量 smoke 或线程数假设收益。
- **教训**: Verilator 多线程不是免费加速开关；对单 hart、DPI 密集、组合依赖重的 RTL，8 线程可能显著变慢。Ubuntu 长跑瓶颈目前仍优先看 guest CPI、cache/mem wait、control wait、rootfs/initramfs 进度和仿真热路径，而不是盲目增大 `--threads`。

### [42] RV64 Ubuntu 22.04 probe 已完整可见，官方 `/bin/sh` 与 rootfs 仍未闭合

- **模块**: NPC RV64 / Linux bring-up / Ubuntu rootfs / 平台设备
- **现象**: 已修复旧现象“`/init` 多次 `write()` 返回成功但 `[ysyx-init]` 不可见”，并进一步闭合到 Ubuntu probe os-release 关键字段可见。修复前，NPC 已到 `Run /init as init process`，`write_all+0x10` 返回点 `pc=0x10130` 至少 7 次返回成功；新增 `NPC_UART_ACCESS_TRACE`/`NPC_IRQ_TRACE` 后，负证据显示 UART IER lane1 写入后 `uart_irq=1/plic_irq=1`，但没有 THR lane0 写和 `uart-trace tx=`。修复后，`codex-sei-fix-ubuntu-ysyx-init` 已能输出 `[ysyx-init`；随后干净默认 `smoke-ubuntu-probe-watch` 在 NPC 上命中 `PRETTY_NAME="Ubuntu 22.04.5 LTS"`，`exit via guest-watch, cycles=948286162, commits=148231451`。QEMU reference 同一 probe 镜像完整打印 Ubuntu 22.04.5 os-release 与 `UBUNTU_CODENAME=jammy`。官方 Ubuntu full-shell gate 已新增：QEMU `qemu-ubuntu-shell-initramfs` 已实际执行 `/bin/sh -c` 并打印 `[ysyx-sh] /bin/sh -c marker`。本轮补出并修复 direct JAL link-address 回归：修复前 `smoke-ubuntu-shell-watch` 在 OpenSBI `fw_boot_hart` 处循环，`jal-link-smoke` 复现 BAD TRAP code=1；修复后 `smoke-jal-link` GOOD TRAP（`cycles=74/commits=16`），且 full-shell watch 已越过 OpenSBI 和 Linux early boot，到 `Unpacking initramfs...`、`ttyS0 enabled`、`SuperH (H)SCI(F) driver initialized` 后因 12 亿 cycles 到期退出（`commits=180848360/CPI=6.635`），尚未到 `/init` 或 `[ysyx-sh]`。本轮 NPC 也继续通过 `fp-fcsr` focused gate与短回归：`smoke-fp-fcsr`（`492/88`）、`smoke-fp-loadstore`（`216/34`）、`smoke-fp-convert`（`320/65`）GOOD TRAP。此前 `smoke-fp-fmv-fclass`、`smoke-fp-compare-sgnj`、`smoke-fp-minmax`、`smoke-fp-addsub`、`smoke-fp-mul`、`smoke-fp-div`、`smoke-fp-sqrt` 也已闭合；但尚未通过 `smoke-ubuntu-shell-watch`。上传文档里的显示/存储/中断/输入闭环提醒仍有效：当前 Linux-visible framebuffer、virtio-blk/rootfs、多源 PLIC、UART RX/TTY 和完整 rv64gc/lp64d 用户态仍是后续 gate。
- **根因**: 已修复的 probe 可见性根因是 CSR 外部中断 delegation 语义错误。`CsrFile` 之前用 `csr_mideleg_q[IRQ_CAUSE_MEI]` 生成 S 态 `MIP_SEIP`，并用同一错误 bit 在 S/U 态屏蔽 `MIP_MEIP`；但 Linux/OpenSBI 按 RISC-V 语义设置的是 supervisor external interrupt 的 delegation 位 `SEI(cause=9)`。结果是 PLIC 输出已到 core 外部中断线，但 S 态 Linux 8250 中断服务没有按 `SEIP` 入口推进，TTY 队列不会写 THR。F/D 前沿另有三类已修 root cause：FP 串行路径曾在 backend drain 前提前抓取 GPR 地址/数据；drain-complete 后旧 `pending_fp_q`/exit 状态未清，导致后续 `ebreak` 被上一条 FP 重放覆盖；早期 fast direct JAL 的 ROB `next_pc` 元数据曾保存 fallthrough 而非 jump target。2026-06-01 又定位到相反方向的 direct JAL link 写回回归：fetch/control 层为了提交/redirect 把 jump target 作为 backend `next_pc`，而 `OooIntBackend/WBU` 的 `WB_SEL_PC4` 把 issue `next_pc` 当 link value，导致 `ra=target`。该类问题不应再归因于 UART THRE、DPI TX capture、`/init` 未执行或 syscall 失败。
- **修复**: 已完成 L4 probe 可见性修复：`CsrFile.v` 改为用 `IRQ_CAUSE_SEI` 生成 `MIP_SEIP`，并在 lower privilege 下按 `SEI` delegation 屏蔽同一外部线对应的 `MIP_MEIP`；`tb_ooo_priv_system.sv` 的 S external IRQ 小程序改为设置 `mideleg` bit 9。验证：`tb_axi_lite_to_uart` PASS；`tb_ooo_priv_system` PASS；`make -C npc/rv64 default` PASS；短跑 `OpenSBI v1.8` PASS；Ubuntu `ysyx-init` watch PASS；默认 Ubuntu `PRETTY_NAME` watch PASS。L5 gate 配置也已完成：`build-ubuntu-base-initramfs.sh` 的 shell init 增加 `[ysyx-sh]` marker；Makefile 拆分 probe/full initrd，新增 QEMU/NPC shell watch 入口；shell DTB 与 OpenSBI firmware 可生成。本轮 direct JAL 修复：新增 `jal-link-smoke.S` 与 `smoke-jal-link`；`OooAluFetchCore` direct JAL 派发到 backend 的 `next_pc` 改回 fallthrough，提交 mux 对 JAL 重新计算 `pc + imm_j` 输出架构 next_pc。F/D 前沿修复：FP load/store 与 move/class/convert/compare/sign-inject/minmax/add-sub/mul/div/sqrt 操作数改为 backend drain 后解析；新增 `FMV.X.{W,D}`、`FCLASS.{S,D}`、`FCVT.D.{W,WU,L,LU}`、`FCVT.{W,WU,L,LU}.D`、`FSGNJ/FSGNJN/FSGNJX.{S,D}`、`FEQ/FLT/FLE.{S,D}`、`FMIN/FMAX.{S,D}`、`FADD.{S,D}`、`FSUB.{S,D}`、`FMUL.{S,D}`、`FDIV.{S,D}` 与 `FSQRT.{S,D}` focused 路径；新增 `fp-fcsr` focused gate 覆盖 FCSR/FRM/FFLAGS 的 CSR RMW 软件路径，但仍不声明 FP 算术自动置 full fflags 或最终 FPU PPA。验证：`smoke-jal-link`、`smoke-fp-fcsr`、`smoke-fp-loadstore`、`smoke-fp-fmv-fclass`、`smoke-fp-convert`、`smoke-fp-compare-sgnj`、`smoke-fp-minmax`、`smoke-fp-addsub`、`smoke-fp-mul`、`smoke-fp-div`、`smoke-fp-sqrt` 均 GOOD TRAP。仍未完成：arithmetic exception flags/dynamic rounding 全矩阵、NPC 官方 Ubuntu `/bin/sh`、rv64gc/lp64d 动态用户态、rootfs mount/virtio、Linux-visible framebuffer 等更高 gate。
- **教训**: `/init` handoff、用户态入口指令退休、syscall 返回、UART THR 写、用户 marker 可见、完整 `/etc/os-release`、官方 `/bin/sh`、rootfs mount 和 Linux-visible framebuffer 是不同 gate。PLIC/CSR 中断问题必须用“source line -> PLIC pending/claim -> CSR pending cause -> handler MMIO”的链条定位；看到 `plic_irq=1` 不等于 S 态已经获得 `SEIP`。OpenSBI 使用 `FW_FDT_PATH` 时，改 DTB 后仍必须重建 firmware。QEMU `/bin/sh` PASS 只能作为 reference，不能替代 NPC；Ubuntu `/bin/dash` 和 `libc.so.6` 包含 `fdiv/fmul/fcvt/fmv.x/frrm/fsflags/fclass/feq/flt/fle/fmin/fmax` 等 F/D 指令。串行 FP 边界必须等更老整数 ROB drain 后再读 GPR/FPR 操作数，FPR->GPR 还必须同步 ArchRegFile、PRF 与 RenameMap；FCSR CSR 软件读改写、FCVT、FCMP/FSGNJ、FMIN/FMAX、FADD/FSUB、FMUL、FDIV 与 FSQRT focused gate 已过，下一层继续按 rv64gc/lp64d ladder 推进 arithmetic fflags/dynamic rounding、官方 `/bin/sh` 和 dynamic linker/libc gate。上传文档中的核心提醒继续适用：当前 VGA/SDL 不是 Linux framebuffer/DRM 设备，virtio-blk/rootfs 和多源 PLIC 也不能被 Ubuntu probe 通过所替代；Verilator 是近期真实系统仿真的主线，流片/FPGA 原型应在设备契约和可综合边界更清晰后再接。

### [41] RV64 CoreMark 已恢复 PASS，但当前 CPI 从历史 0.783 回退到 0.828

- **模块**: NPC RV64 / OoO control-flow / memory flush / CoreMark
- **现象**: fault-trap 后的 CoreMark no-progress 已不再复现，CoreMark `ITERATIONS=10` 当前可以 PASS，且 memory request/response 已平衡；但性能从历史好点 `CPI=0.783/0.779` 回退到 `cycles=2661725/commits=3216115/CPI=0.828`，未满足 CPI<0.8 目标。top control wait 集中在 CoreMark `core_bench_list` 的 load-dependent branch，尤其 `0x80000b2c`，整体 control wait cycles 为 `stop=814454/branch=795811/jump=18641`。
- **根因**: 已确认不是旧 orphan memory response 死锁；当前更像后续正确性修复或性能实验恢复后的控制流/访存吞吐回归。负实验显示，简单加大 ROB/IQ、过度门控 issue1、ROB 同拍借 commit 槽、BPU local strong-only、branch prefetch same-cycle dispatch 都不能恢复 0.8；load-branch fast resolve 甚至把 CoreMark 退化到 `CPI=0.907`，推测它过早 redirect 干扰了 branch shadow prefetch 的收益。
- **修复**: 暂未完成。当前保留能稳定 PASS 的基线：focused `branch-resolve-loop ooo-mem-order linux-mini-boot` 3/3 PASS，CoreMark10 PASS。后续应先对比 `0.783` 好点之后的 `OooRob/NpcAxiBus/OooFetchAxiBridge/OooMemAxiBridge/OooAluFetchCore` 变更，再设计保持 branch shadow prefetch 的 load-dependent branch resolve，或引入更系统的 response queue/LSQ/ROB-age selective squash；禁止用会形成 ready/valid 组合环或破坏 memory response ownership 的症状级补丁。
- **教训**: CoreMark PASS 不等于性能目标达标；CoreMark no-progress 修复后必须同时看 `mem req/rsp` 平衡、branch wait 分布和历史 CPI A/B。对 OoO 控制流，越早 resolve 不一定越快，如果它抢掉已经成熟的影子预取，反而会增加 refetch 和 wait。

### [40] RV64 真实 Linux kernel 已越过 MMU relocation，但仍未完整 boot

- **模块**: NPC RV64 / CSR / OoO frontend RAS / Sv39 / Linux boot
- **现象**: 真实 Debian `vmlinux-6.12.90+deb13-riscv64` 经真实 OpenSBI v1.8 handoff 后，已不再停在 early `stvec` 的 `0xffffffff800010bc`/`wfi` 循环。当前 20M cycles smoke 到 `pc=0xffffffff8051be34`、`commits=6637254`，40M cycles smoke 到 `pc=0xffffffff8021531e`、`commits=8830390`，说明 Linux kernel 仍在继续退休推进；但两次仍因 `--max` 到期退出，尚无完整 Linux banner/rootfs boot 成功证据。
- **根因**: 本轮修掉两个真实 kernel 前置缺口：一是 OpenSBI SBI base `get_mimpid` 需要 `CSR_MIMPID`，此前 CSR 未实现；二是 Linux `relocate_enable_mmu` 在低地址 call 后把真实 `ra` 改到高半区，最终 high-only `satp` 后 `ret`，旧 OoO frontend 仍把 RAS 低地址项当成架构返回目标，导致取低地址 `0x80201152` 时 instruction page fault 并进入 early trap loop。剩余未完整 boot 的问题还未收敛，可能继续涉及 kernel 后续设备模型、console/earlycon、virtio/rootfs、内核初始化工作量与当前仿真性能。
- **修复**: 部分完成：`define.v/CsrFile.v` 新增只读 `mimpid=0`；`OooAluFetchCore` 在 `satp` CSR 写提交边界清 RAS、return continuation、synthetic lane1 return、branch target cache 与 JALR BTB；`sv39-ras-relocate` cpu-test 复现并锁定该 RAS/SATP 边界；`smoke-linux-kernel` target 允许装载真实 OpenSBI、真实 Debian kernel 和 DTB。后续应继续分析 40M 后的内核路径，补齐真实 Linux 所需设备/console/rootfs，并把 smoke 从“越过 relocation 并持续退休”推进到“打印 Linux banner/进入 initramfs 或 rootfs”。
- **教训**: RAS/BTB/target cache 这类预测状态不能跨地址空间切换复用；`satp` 写提交是精确清理边界。真实 kernel smoke 还要区分“卡在同一 PC/无退休”和“max-cycles 到期但 commits 持续增加”，否则容易把慢启动误判成死锁。

### [39] RV64 OpenSBI/mini payload 已闭合，真实 Linux kernel smoke 已进入下一阶段

- **模块**: NPC RV64 / CSR / SBI / Linux boot platform
- **现象**: `counteren-time/sbi-timer/sbi-base-console/linux-handoff/sbi-ipi-reset-hsm` 已覆盖 counter、timer、console、handoff、IPI/HSM/reset ABI 等 mini SBI 路径；host 侧 `--load=ADDR:FILE`、reset trampoline、`npc-rv64.dts`、`smoke-dtb` 已能验证多镜像装载和真实 DTB handoff。当前已跑通真实 OpenSBI v1.8 `fw_jump.bin`：OpenSBI banner 完整输出，Domain0 handoff 到 `0x80200000` 的 S-mode payload；直接 payload 可验证 `a0=0/a1=DTB` 后 UART 输出 `S`；runtime SBI payload 还能通过真实 OpenSBI 调 SBI base probe、legacy console putchar 输出 `B`、SBI TIME `set_timer` 并接收 S-mode timer interrupt。2026-05-31 已开始真实 Linux kernel smoke 并越过 early relocation，后续仍依赖真实镜像、virtio/blk、多源 PLIC、更完整 DTB/设备模型和更完整 OpenSBI/Linux 驱动闭环。
- **根因**: 真实 OpenSBI 闭环已证明核心 privilege/SBI/DTB/entry ABI 与 base/console/time runtime SBI 的关键边界；此前 next stage 仍是 repo 内小型 payload，不是 Linux kernel。当前真实 kernel smoke 已暴露更深一层的 CSR/RAS/Sv39 与后续平台缺口；平台设备仍只有单 hart、最小 UART/CLINT/PLIC smoke，没有 virtio block/rootfs、真实多源中断和 kernel driver 所需的完整设备行为。OpenSBI smoke `CPI=0.944~0.946` 还高于 0.8，主要受 banner/UART 输出与控制等待影响；性能目标目前只由 CoreMark `CPI=0.779/0.783` 支撑。
- **修复**: 部分完成：2026-05-30 已补 counter/SBI/DTB/reset trampoline/multi-image loader，并新增真实 OpenSBI smoke。关键修复包括 `misa` 报告 RV64 I/M/A/B/C/S/U，默认 OpenSBI text start + `FW_FDT_PATH` embedded DTB，semihosting magic `ebreak` 走架构 breakpoint trap而普通 `ebreak` 继续作为 AM halt，`smoke-opensbi` 装载 OpenSBI、payload 和 DTB@`0x82200000`。2026-05-31 新增 `smoke-opensbi-sbi`，验证真实 OpenSBI base/console/time runtime path；同日开始真实 Linux kernel smoke，详见 [40]。后续应继续补 virtio/blk、多源 PLIC、kernel 期望的 DTB 和更完整设备模型。
- **教训**: “真实 OpenSBI 能启动”已经比 mini SBI 更接近 Linux boot，但仍不能等同于 Linux kernel boot。每一层验收要标明 next stage 是 toy payload 还是真实 kernel，并单独记录功能 CPI 与 benchmark CPI。

### [38] RV64 SBI timer 仍是 mini service，不是完整 OpenSBI

- **模块**: NPC RV64 / CLINT / SBI / Linux boot platform
- **现象**: `sbi-timer` 已覆盖 S-mode `ecall` 进入 M-mode timer handler、M handler 写 CLINT `mtimecmp`、返回 S-mode 后触发 delegated `STIP` 并 `sret`，证明 Linux early timer 的关键控制链路已闭合。但这仍只是 TIME extension 的最小 smoke，不代表真实 OpenSBI 已能运行，也不能覆盖 Linux 后续依赖的 console、IPI、reset、HSM、hart state、firmware payload handoff 等 SBI 行为。
- **根因**: 当前 `AxiLiteClint` 已具备 `mtime/mtimecmp/msip` 的基础寄存器和 RV64 aligned lane 兼容，但平台固件仍由 cpu-test 内的裸汇编 trap handler 模拟；没有真实 OpenSBI 镜像装载、设备树传参、hart boot 参数、SBI extension 分发表，也没有多 hart IPI 语义。`sbi-timer` 为了验证 CLINT 高 lane 和 STIP，直接把 `mtimecmp` 写成 pending，不建模真实固件里的计时目标、返回结构和错误码矩阵。
- **修复**: 部分完成：2026-05-30 已修复 CLINT `mtimecmp+4/mtime+4` 在 RV64 8-byte aligned LSU 下的高 lane 访问，并新增 `sbi-timer` mini boot 测试。后续若要推进真实 Linux boot，应先建立 OpenSBI/kernel 镜像加载与 DTB/hart 参数，再逐步补 SBI console、IPI、reset/HSM、真实 set_timer 参数路径和多 hart/多中断源联动。
- **教训**: SBI 测试要区分“控制链路能进 trap 并返回”和“固件 ABI 完整”。mini boot 可以用于锁定硬件边界，但不能用一个裸 handler 的 PASS 代替真实 OpenSBI 启动证据。

### [37] RV64 PLIC/UART 目前仍是 mini boot 单源模型，不是完整 Linux 平台设备栈

- **模块**: NPC RV64 / PLIC-like MMIO / Linux boot platform
- **现象**: `plic-sirq` 已能通过 MMIO pending 注入 source 1，`uart-plic-sirq` 也已能通过 UART THRE interrupt 驱动 PLIC source 1，让 S-mode `wfi` 进入 supervisor external interrupt handler 并完成 claim/complete；但这仍只能证明核心 external IRQ、UART THRE source、PLIC MMIO lane、S-mode trap 入口闭合。它还不能代表真实 Linux 已有完整平台设备栈，也不能直接替代 virtio/blk、DTB 或完整 QEMU `virt` 设备模型。
- **根因**: 当前 `AxiLitePlic` 仍是为了 Linux boot 前置验证而做的最小设备：单 source、M/S context、简化 gateway/in-service，没有多源优先级仲裁、claim priority、完整上下文 pending arbitration。`Uart` 已有 TX/IER/IIR/LSR、DLAB divisor 和 FCR FIFO enable 的基础寄存器语义，但仍没有 RX FIFO、真实输入、真实 baud/FIFO 深度和多 cause interrupt。另因 RV64 LSU 对 32-bit MMIO 访问使用 8-byte aligned beat，PLIC 对 `+4` lane 做了兼容，aligned threshold/claim 共 beat 读仍会触发 claim clear，尚未建成完全通用的 PLIC ABI 模型。
- **修复**: 部分完成：2026-05-30 已将 UART `irq_o` 接到 PLIC source 1，并为 PLIC 增加 in-service 网关语义。2026-05-31 UART THRE 改为适配当前零延迟 TX 的 level 条件，并补 DLAB/FCR/IIR focused 覆盖。后续真实 Linux boot 应补多 source PLIC/gateway/priority arbitration、virtio/blk source 接线、UART RX/输入、DTB/设备模型、真实 OpenSBI/kernel 镜像加载；如果要保持当前 8-byte aligned LSU 协议，也应明确处理同 beat 内 threshold/claim 的 side effect 边界或在总线侧保留原始低地址 lane 信息。
- **教训**: 小型 boot 测试要明确“验证了哪条系统路径”，不能把 UART THRE interrupt smoke 误当成完整平台设备模型。Linux boot 的下一步应把 PLIC、virtio/blk、DTB 和 SBI 服务一起闭合，而不是只看单个 SEIP 是否能进 handler。

### [34] 当前 Windows/WSL 会话存在 vsock/utility VM 不稳定

- **模块**: 宿主环境 / WSL
- **现象**: RV64 CoreMark 长跑或并行启动多个 WSL 命令后，可能出现 `Wsl/Service/E_UNEXPECTED`、`Wsl/Service/0x8007274c`、`UtilBindVsockAnyPort: bind failed`、`InitCreateProcessUtilityVm failed`。本轮串行短命令可恢复，说明不是项目代码直接把 Windows 资源耗尽；并发读文件时也复现过同类错误。
- **根因**: 当前机器 WSL 会话/vsock/utility VM 层不稳定，长时间 benchmark 或并发命令会放大问题；此前 dmesg 还出现过 unclean shutdown/journal corrupted。代码侧卡死会增加触发概率，但 WSL 报错本身属于环境层症状。
- **修复**: 本轮采用串行、短命令验证，避免并发 WSL 进程。长期应重启/修复 WSL 会话、减少并行命令，并把 benchmark 卡死先收敛成 NPC 超时而不是任其长跑。
- **教训**: 遇到 WSL `E_UNEXPECTED` 不要直接等同于 RTL OOM 或 benchmark 自身崩溃；先看 NPC 是否有 no-progress/commits 卡点，再单独评估宿主 WSL 稳定性。

### [33] `npc/rv64/testbench` 全量 run 仍会被旧 `tb_ooo_alu_fetch_core` 语义挡住

- **模块**: NPC RV64 / module testbench / OoO fetch-core focused test
- **现象**: 本轮 S-mode/A-extension 和 Sv39 bridge 改动后，focused 验证 `tb_ooo_sv39_boot tb_ooo_int_backend tb_ooo_priv_system` PASS，rv64 lint/build、cpu-tests 和 CoreMark 均 PASS；但直接执行 `make -C npc/rv64/testbench RESULT_DIR=/tmp/rv64-full-module run` 仍会在旧 `tb_ooo_alu_fetch_core` 失败。日志显示该旧 test 仍期待 `mret` 走 illegal trap、并按旧 32-bit 访存模型/退出模型断言 JALR/memory/ecall 行为。
- **根因**: `npc/rv64` 近期已经把 MRET/CSR/ECALL/64-bit LSU/OoO core-top 语义推进到新边界，但 `tb_ooo_alu_fetch_core` 仍继承较早 RV32/OoO focused 假设，没有同步到当前 RV64 “MRET 合法、ECALL 架构 trap、8-byte aligned LSU、priv SYSTEM drain” 的协议。
- **修复**: 暂未在本轮清理该旧 testbench；本轮新增/扩展的 `tb_ooo_sv39_boot` 已覆盖 IFU/LSU Sv39 success path、S-mode handoff、delegated ecall 和 `SRET` 小型 boot 骨架，`tb_ooo_priv_system` 覆盖当前 privilege/SYSTEM 验收点，`tb_ooo_int_backend` 覆盖 AMO/LR/SC，`tb_decode_unit` 覆盖 SRET/AMO decode。后续若要恢复 `testbench` 全量 run，应重写 `tb_ooo_alu_fetch_core` 的程序模型和断言，使其与当前 RV64 privilege/LSU/exit 协议一致，而不是把 RTL 回退到旧预期。
- **教训**: focused testbench 的历史预期本身也属于接口契约；当体系结构语义从“unsupported/illegal”推进到“合法精确控制事件”时，需要同步升级旧断言，否则全量 module run 会把已完成的能力误报成回归。

### [30] OoO 实验核接入真实 core-top 后，CPI=0.5 目标转为 core 内 cache/LSQ/control-flow 问题

- **模块**: NPC / `NpcCoreTop` / OoO experimental core / fetch-memory bridge
- **现象**: `NPC_OOO_ALU_EXPERIMENT=1` 已不再通过仿真顶层一拍双端口 PMEM 直连，而是经 `NpcCoreTop` 的 IFU/LSU 总线桥接入真实 core 边界。core-top 分离后全量 CPU-test 先稳定为 `40/40 PASS`、加权 `CPI=4.690321`；加入 packet I-cache 与 word D-cache bridge 后为 `0.973575`；两个 bridge cache 扩到 1024 项后为 `0.912113`；保留同周期 demand miss AR 后为 `0.870428`；no-link JALR 快路径后为 `0.865293`；lane1 return 快路径后为 `0.842238`；最新 resolved branch append + 16-entry branch target cache 后，全量 `40/40 GOOD`、`cycles=64609/commits=78679/weighted CPI=0.821172`，仍未达到 `CPI=0.5`。
- **根因**: 正确性优先后，性能瓶颈已从旧直连模型暴露为真实总线延迟、单 outstanding 结构限制和控制流屏障。packet I-cache 消除了大量重复取指，但仍是单 packet direct-mapped、miss 串行读两 word；`AxiLiteXbar` 当前用 `rd_master_busy/rd_active` 串行化每个 master/slave 的读事务，导致 fetch bridge 不能只靠两端改动就把 R0 返回和 AR1 授权重叠；D-cache 是单 word direct-mapped，load miss 仍阻塞单 LSU outstanding，store 只有 write-through/有限 write-allocate；控制流仍缺真正 branch/ret/JALR checkpoint 投机和更细粒度 commit 协议。最新全量画像显示 `recursion` 的 indirect JALR `pending_jump` 与 branch-heavy 样本的 pending branch wait 仍是高权重瓶颈，branch append 只能利用已解析且安全的同包机会，不能替代完整预测/rollback。
- **修复**: 已部分缓解：`OooFetchAxiBridge` 增加 1024-entry packet I-cache，store write fire 时按 packet/store word 重叠失效；`OooMemAxiBridge` 增加 1024-entry PMEM word D-cache，load hit 一拍返回、miss 填充、store 命中合并且 full-word miss 可分配；桥接 `S_RESP` 支持 response 消费同拍接新请求；fetch/mem bridge 保留同周期 demand miss AR；no-link 非 return `jalr x0, rs1, imm` 与 lane1 return 快路径保留。最新保留 resolved branch append：taken target cache full-PC tag 命中或 not-taken head1 safe 时可把真实下一条作为 optional lane1 派发，target cache 扩到 16 项并在 store/MISC_MEM 边界失效；CPU-test 全量 `40/40 GOOD`、weighted CPI `0.821172`。2048-entry bridge cache、`pc+4` packet 预填、D-cache 后台 next-word prefetch、fetch R0+AR1 同拍尝试等负优化均未保留。完整修复仍未完成，下一步优先有队列/多 outstanding 不变量的 line-based I/D cache 或 prefetch、xbar read completion/grant 重构、LSU response queue/LSQ/store commit，以及控制流预测/rollback。
- **教训**: 不能为了追 CPI 回到仿真顶层私有 PMEM 直连；优化必须落在 core 内可解释的结构边界上，并且每一轮都以 CPU-test 全量正确性作为门槛。缓存 payload array 不必在 reset 中清零，valid bit 复位即可，否则大数组 reset loop 容易触发 Verilator 初始化/展开问题。`add` 不能作为性能有效性的主证据；短样本或局部样本变快也不能替代全量正确性。后台预取/同拍 AR 重叠这类会改变总线时序所有权的实验必须先从 bridge、xbar、slave 的完整 ready/valid 调用链证明响应归属、busy 清除和 ordering；branch append 这类看似局部的 lane1 optional 优化也必须检查 ready/valid 回边，并对保存指令副本的 target cache 加 store/fence 失效边界。

### [29] OoO 实验核的完整 AM CPI 仍受 check() 控制流与 LSU/LSQ 缺口阻塞

- **模块**: NPC / OoO experimental core / branch speculation / LSU
- **现象**: `NPC_OOO_ALU_EXPERIMENT=1` 在保留 RVC、JAL/RAS/branch/memory fast path、同拍 redirect fetch、branch shadow prefetch、后端单 checkpoint/restore、保守 speculative dispatch、ROB 写回同拍退休旁路、memory/ALU overlap、lane1 memory 同包发射、dispatch-ready direct branch 同拍 redirect、fetch response control-stop gate、memory response/request 同拍续发、dispatch branch issue-result bypass、memory-aware issue1 selection、lane1 return fallthrough fast path、issue queue dispatch-bypass compact 修复，以及受约束的双 load 读端口后，默认 AM `cpu-tests add` 可 GOOD TRAP，目前最好为 `cycles=537/commits=839/CPI=0.640`，距离完整程序 `CPI=0.5` 目标仍有明显差距。
- **根因**: 最新 trace 显示双 load 端口已经活跃（`mem req0/req1/rsp0/rsp1=95/62/95/62`），但只带来 4 cycles 收益；commit 分布为 `0:72, 1:101, 2:369`，剩余热点主要是 `jal check -> beqz -> ret` 控制流，尤其 `0x80000010 ret` 单提交 72 次。现有 `direct_branch0_lane1_ret` 只把前端 redirect 提前到 RAS target，并把 lane1 return 保存成 pending 单 uop；这保持了 RAS pop、dispatch 和 ROB commit 的精确边界，但 return 本身仍会单独派发/退休。若要继续压这部分 CPI，需要有证明的 branch/ret pairing、synthetic control commit 或更细粒度 speculative/commit 协议；此前 lane0 branch + lane1 return 同拍派发/commit 尝试会形成 dispatch ready 组合环或破坏 focused 断言，不能作为症状级补丁。memory 侧虽然已有第二只读端口，但仍没有真正多 outstanding、response queue、LSQ 和 commit-time store。
- **修复**: 部分缓解：2026-05-29 已把 unsafe normal FIFO prefetch 改为 one-packet shadow buffer，补齐后端单 checkpoint/restore，接入保守单分支 ALU-only speculative dispatch，并增加 ROB bypass、memory pending 期间 ALU overlap、1-entry memory issue buffer、lane1 memory request、writeback 端口仲裁修复、dispatch-ready branch 同拍 redirect、control packet fetch gate、memory response/request 同拍续发、dispatch branch compare 的 issue-result bypass、issue queue 的 memory-aware issue1 selection、lane1 return fallthrough fast path、dispatch-bypass 不再误删 IQ slot 的 compact 修复，以及当前保留的 `load+load` 双端口 issue/writeback。focused/module/AM 回归通过。完整修复仍未完成；下一步优先研究不引入 ready 环的 branch+ret 控制流折叠或 ROB-age selective younger squash，再补 LSU response queue/多 outstanding/LSQ 与 commit-time store。
- **教训**: 对 OoO 控制流和访存，提前取指/同拍续发/跨 lane 派发都不等于安全投机。只要年轻路径状态、dispatch ready 或 memory response 可能影响 commit/exit/fetch/LSU ownership，就必须隔离在影子结构里，或有系统性的 checkpoint/rollback/skid/queue；否则“看似命中才复用”的 FIFO 预取、组合 ready 环里的 lane1 控制快发、或“response 同拍 slot 空了但请求元数据未闭合”的续发，都会产生提前 GOOD TRAP、额外退休、load 读旧值、组合环或 ROB 项漏 done。当前可保留的 response/request 同拍续发只是在单槽协议内补齐了 fire/metadata 同拍所有权的局部优化，不能替代完整 LSQ。

### [28] NPC SoC 地址图预留使 Verilator host 仿真速度明显下降

- **模块**: NPC / NpcSimTop / AXI crossbar / 性能
- **现象**: `perf_defconfig` 下 CoreMark progress 的 `inst/s` 下降到约 1.31M；同一 500 万 cycles 短跑，当前工作树 `simulation frequency=1310861 inst/s`，干净 `HEAD` 基线为 `2176195 inst/s`。
- **根因**: ysyxSoC 地址图接入后，`NpcSimTop` 的 `AXI_S_COUNT` 从 5 扩到 15，并为多个未实现窗口实例化 `AxiDefaultSlave`。`AxiLiteXbar` 当前按 `S_COUNT` 循环执行地址译码、读仲裁和写仲裁，slave 数增加会直接抬高每拍 Verilator `eval()` 成本；guest 侧 `cycles/commits/CPI/branch/cache` 统计保持一致，因此不是核心执行效率退化。
- **修复**: 暂未修复；可选方向是为 perf/legacy 仿真保留精简 5-slot 地址图、把未实现窗口合并到单 default stub，或重写 crossbar 为层级/区间优先译码，避免每拍扫描所有预留窗口。
- **教训**: 为未来 SoC 预留地址窗口也会改变仿真模型的热路径复杂度；功能兼容改动如果落在每拍组合逻辑上，需要同步做 host 仿真性能 A/B。

### [23] 本机缺少 `oss-cad-suite/bin/yosys`，RTL cache 接入后的综合/STA 尚未复跑

- **模块**: NPC / Yosys-STA / 环境
- **现象**: `make -C npc/single syn-check-env` 直接失败，提示缺少 `/home/lyg/PA/ysyx-workbench/oss-cad-suite/bin/yosys`；因此本轮 ASIC 层级 I/D cache 接入后只完成了 Verilator lint/build 与 difftest/benchmark 功能验证，未产生新的综合网表、时序、面积、功耗报告。
- **根因**: 当前工作区期望的 oss-cad-suite 工具链路径不存在或未安装，`npc/single/Makefile` 的综合入口检查在进入 Yosys 前终止。
- **修复**: 暂未修复；恢复该路径下的 Yosys/OpenROAD 工具链，或调整 `YOSYS_STA_HOME`/相关工具路径后，再执行 `make -C npc/single syn` 与 `make -C npc/single sta`。
- **教训**: RTL 功能回归通过不等于 PPA 闭环完成；每次把 cache、BPU 这类大状态模块推进可综合层后，都要重新跑综合/STA 并更新面积/时序基线。

### [22] RTL cache 接管后 legacy host cache counter 会显示为 0

- **模块**: NPC / cache / 性能统计
- **现象**: 本轮 `IDCache.v` 接入后，`npc/single/csrc/dpi.c` 已改为 raw PMEM/MMIO 访问，host 侧 `memory/cache.c` 不再位于取指/访存路径上；因此程序结束时若仍打印 legacy `icache/dcache` counter，数值可能为 0 或不再代表真实 RTL cache 行为。
- **根因**: cache 微结构已经从 host bus 层下沉到 `NpcCore` 内部 RTL，原先的 C 侧 cache 统计自然失去数据源。继续让 host cache 和 RTL cache 同时工作会造成双重建模，反而破坏硬件语义。
- **修复**: 暂未修复；后续应在 RTL cache 内增加性能计数器，并通过仿真专用层次化读取或显式 debug/perf 端口暴露给 host。不要为了恢复旧 counter 而重新启用 host cache。
- **教训**: 性能统计的层次必须跟真实微结构层次一致；当 cache 从 simulator 优化变成硬件模块后，统计口也要迁移到 RTL，而不是继续复用 host 侧旧路径。

### [18] NPC 开启 stdin keyboard 后，终端输出会出现“越打越往右”的错位

- **模块**: NPC / 终端交互 / VGA 调试输出
- **现象**: 在 `riscv32-npc` 上运行 `make ARCH=riscv32-npc mainargs=v run` 一类会持续打印文本的程序时，即使 guest 代码只是普通 `printf("...\n")`，终端里的 `FPS = ...`、welcome 和 SDL 关闭日志也会逐行向右漂移，看起来像输出无法对齐；截图里 `[npc] stdin keyboard enabled` 同时出现时，几乎可以直接怀疑这条路径。
- **根因**: `npc/single/csrc/device/device.cpp` 的 `KeyboardDevice::Init()` 在把 TTY 切到“可轮询、无回显”的模式时额外执行了 `raw.c_oflag &= ~(OPOST)`。由于 stdin/stdout/stderr 共享同一个终端设备，这会关闭输出后处理，使 `\n` 不再被 TTY 转成回到列首的换行；而 guest 串口输出通过 `npc/single/csrc/monitor/log.cpp` 逐字符写 stdout，host `LogBoth()` 也直接 `printf("\n")`，于是列偏移会累积暴露出来。
- **修复**: 暂未修复；根治时应优先保留 `OPOST/ONLCR`，或者至少不要在只需要 raw input 的场景改动输出侧 termios。临时恢复宿主终端可用 `stty sane`。
- **教训**: 终端 raw mode 不是“只影响输入”的局部开关；凡是通过 `tcsetattr()` 修改同一个 TTY，输出行规程也会一起受影响。看到“文本错位”时先查 termios，再怀疑显示链路。

### [17] NPC 上直接跑 `am-tests mainargs=d` 时，当前主要卡在 `timer_test` 忙等与后续磁盘缺口，而不是 VGA

- **模块**: NPC / AM-Kernels / Abstract Machine
- **现象**: 在 `riscv32-npc` 上直接运行 `./npc/single/build/NpcSimTop ./am-kernels/tests/am-tests/build/amtest-riscv32-npc.bin --no-itrace --max-cycles 3000000` 时，输出只能到 `heap = ...` 和 `Input device test skipped.`，随后因周期上限在 `0x80000264` abort，看起来像 `devscan` 还没走通。
- **根因**: 这次停点位于 `devscan()` 里 `timer_test` 的 `for (volatile i = 0; i < 10000000; i++)` 忙等循环，本质上是当前多周期 NPC 对这种纯 CPU busy loop 太慢；而且即使越过这段，`storage_test()` 后面还会碰到 `riscv32-npc` 尚未实现的磁盘设备。高级 VGA ABI 本轮已经通过共享软件渲染层补齐，不再是这里的首要阻塞。
- **修复**: 暂未修复；若要让 `mainargs=d` 在 NPC 上更实用，可从“给 NPC 加快连续执行性能、为 `devscan` 增加 NPC 专用 smoke 入口、或补最小 disk config/blkio”几个方向继续推进。
- **教训**: 当一个跨设备测试在慢速 RTL 目标上跑不完时，不要直接把责任推回最近补的某个设备；先定位 PC 所在阶段，确认当前真正挡路的是功能缺口、性能预算，还是测试本身的前置 busy loop。

- 原 [3] 已在当前宿主环境中通过重装 SDL/Mesa 运行库暂时解除，见下方“已解决问题”。

### [15] NpcCore 在 500MHz STA 下时序满足，但时钟门控使能脚仍有最大电容违规

- **模块**: NPC / Yosys-STA
- **现象**: `npc/single/build/sta/NpcCore-500MHz/NpcCore.rpt` 显示 `core_clock` 的 `max/min TNS` 都为 `0.000`，最差 setup slack 约 `0.963ns`，但 `NpcCore.cap` 里 `mem_addr_raw_q_0__..._ICGX0P5H7L_E:ECK` 等时钟门控使能脚仍出现最大电容超限，最坏 `CapacitanceSlack` 约 `-0.074`。
- **根因**: 当前 `yosys-sta` 流程在综合阶段启用了 clockgate，`NpcCore` 又包含较宽的状态/调试寄存器扇出，导致部分 `ICGX0P5H7L` 的 `ECK` 使能脚负载偏大；这类问题不一定会立刻打穿逻辑级 WNS/TNS，但会先在电气约束报告里暴露出来。
- **修复**: 暂未修复；后续可从“收紧/调整 clockgate 策略、对高扇出的门控使能链补缓冲、降低调试扇出影响，或在更完整的物理实现阶段重新评估”几个方向处理。
- **教训**: 做综合验收时不能只看 `WNS/TNS`；对带 clock gating 的设计，还要同时检查 `cap/fanout/trans`，否则会把“时序过了但电气没过”的半成品误判成完全 clean。

## 已解决问题
<!--
### [编号] 问题标题
- **模块**: 出问题的模块
- **现象**: 具体表现
- **根因**: 根本原因分析
- **修复**: 如何修复的
- **教训**: 从中学到了什么
-->

### [40] 真实 OpenSBI 先后卡在 `sbi_hart_hang` 和 semihosting `ebreak`

- **模块**: NPC RV64 / OpenSBI / CSR trap / boot tools
- **现象**: 真实 OpenSBI 初次推进时停在 `pc=0x80006656`，反查为 `sbi_hart_hang()` 的 WFI loop；改用默认 text start 后，OpenSBI 又在 semihosting probe 的 `slli x0,x0,0x1f; ebreak; srai x0,x0,7` 处被 NPC 当成 AM halt/BAD TRAP。
- **根因**: 第一层是用 `FW_TEXT_START=0x80001000` 给 reset trampoline 留洞，导致 OpenSBI `_fw_rw_start - _fw_start = 0x3f000`，不满足 `sbi_domain_init()` 对 `fw_rw_offset` power-of-2 的 sanity check。第二层是 NPC 此前把所有 `ebreak` 都作为实验壳退出边界，没有区分 OpenSBI semihosting magic 序列里的架构 breakpoint trap。
- **修复**: 2026-05-30 已修复。OpenSBI smoke 改为默认 text start，并用 `FW_FDT_PATH` embedded DTB；`OooAluFetchCore` 只把 semihost magic 序列中的 `ebreak` 转成 `EXC_BREAKPOINT` 精确 trap，普通 `ebreak` 仍驱动 AM halt。新增 `semihost-ebreak` 与 `misa-priv` cpu-test，`npc/rv64/tools` 新增 `smoke-opensbi` 和 `mini-linux-payload.S`。验证：真实 OpenSBI v1.8 banner 完整输出，handoff 到 S-mode payload，payload 打印 `S` 并 GOOD TRAP；`smoke-opensbi` 统计 `cycles=4366855/commits=4626201/CPI=0.944`。
- **教训**: OpenSBI 的链接地址、FDT 传参和 semihosting probe 都是固件 ABI 的一部分；为 toy trampoline 调整 text start 会破坏 OpenSBI 自身假设。`ebreak` 在 AM harness 和真实固件里语义不同，必须按上下文区分。

### [35] RV64 fault-trap 后 CoreMark 卡在固定 commit 点并触发 WSL 崩溃

- **模块**: NPC RV64 / OoO memory bridge / fault-trap flush / CoreMark
- **现象**: Sv39 fault-trap 改动后，CoreMark `ITERATIONS=10` 会在 `commits=325846` 附近长期无进展，`--max-cycles 1000000` 与 `20000000` 结果相同；统计曾显示 `mem req0/rsp0 = 72065/72064`，最后 itrace 在 `core_list_mergesort` 退栈 load 附近。长跑叠加当前 WSL 不稳定后，表现为 `Wsl/Service/E_UNEXPECTED`。
- **根因**: 两个边界叠加。第一层是后端 flush/exception 会清 `mem_pending_q`，但 `OooMemAxiBridge` 可能已经持有 CPU response 或已发 AXI 事务；没有 flush-drain/drop 规则时会留下 orphan response。第二层是原先 `branch_resolve_untracked_w` 在 `stop_pending_q` 期间仍可抢占状态机，使 `pending_arch_trap_q` 已经记录 IFU fault packet 时无法进入 drain 后 trap 处理，前端/后端被清空后停在 decode/stop 状态。
- **修复**: 2026-05-30 已修复。`OooMemAxiBridge` 新增 `flush_i/drop_rsp_q`，flush 后隐藏/丢弃 CPU response、drain 已发 R/B response、部分 write 补完剩余通道再 drain；`OooAluFetchCore` 新增 `mem_flush_o` 并由 `NpcCoreTop` 接到 bridge，trap flush 同拍、checkpoint restore 打一拍；`branch_resolve_untracked_w` 改为 `!stop_pending_q` 时才生效，并在 untracked 恢复路径清 `pending_arch_trap_q`。新增 `tb_ooo_mem_axi_bridge` 覆盖 held response、in-flight read、partial write 三类 flush。验证：focused 4/4 PASS，rv64 lint/build PASS；CoreMark 10 不再卡在 `325846`，最终 PASS 且 `CPI=0.783`。
- **教训**: OoO flush 不只清 ROB/IQ；所有跨模块 outstanding owner 都必须闭合。后端 pending 位清零后，bridge 仍需能够消费或明确丢弃已经返回/必将返回的总线响应。前端 stop/drain 期间也不能让无 owner 的 branch resolve 抢占 precise trap/exit 状态机。

### [36] AM `out_uint()` 在 RV64 高地址栈上生成 4GB 反向输出循环

- **模块**: Abstract Machine / klib stdio / RV64 CoreMark 输出
- **现象**: 修复 OoO no-progress 后，CoreMark 10 能继续退休到三千万级指令但长期停在 `out_uint` 的 CRC 输出循环，20M/80M 周期都只打印到 `seedcrc` 附近。临时 commit 探针显示 `sp=0x000000008010cda0`、`digit_count=1` 时终止寄存器变成 `a3=0xffffffff8010cda0`，`a5` 需要从 `0x000000008010cda0` 递减绕 4GB 才相等。
- **根因**: `while (digit_count > 0) tmp[--digit_count]` 被 GCC 在 RV64/Zba 下编成含 `zext.w` 的终止地址计算；在 PMEM/stack 低 32 位 bit31 为 1 的地址上，32-bit index 与 64-bit 指针混算形成远端终止地址。RTL 按语义执行该代码，所以表现为超长但仍退休的循环。
- **修复**: 2026-05-30 已修复。`out_uint()` 改为 `char *digit = tmp + digit_count; while (digit != tmp) out_ch(... *--digit);`，反汇编变成指针回走到 `tmp`，不再生成 `sp - 0xffffffff` 终止地址。新增 `stdio-format` cpu-test 覆盖 CoreMark CRC 输出样式。验证：`stdio-format` PASS；CoreMark 10 PASS，`cycles=2518692/commits=3216171/CPI=0.783`。
- **教训**: AM/klib 也会暴露 RV64 高地址与编译器优化交互问题。看到 NPC 仍在稳定退休且 CPI 正常时，不要继续按 RTL 死锁处理；应检查 guest 代码/反汇编和寄存器不变量。

### [32] RV64 CoreMark 迁移后 CPI 退化到 6.017

- **模块**: NPC RV64 / cache / OoO 性能后端 / CoreMark
- **现象**: `riscv64-npc` 跑 CoreMark 默认 1000 iterations 虽然 `CoreMark PASS`，但 NPC 统计 `cycles=1915750770`、`commits=318393500`、`CPI=6.017`，且截图中 ICache/DCache 统计全为 0；用户要求恢复到 RV32 历史基线 `0.78/0.8` 左右。
- **根因**: 第一层是 RV64 后端的 cacheable PMEM 范围仍配置成不覆盖 `0x8000_0000`，导致 I/D cache 被完全绕过，同时 ICache fill/line-byte 选择仍隐含 32-bit beat，RV64 下不能正确按 64-bit word 取线。第二层是即使恢复 cache，默认仍走顺序核，只能到 `CPI=1.274`；切到双发射 OoO 后又暴露 RV64 语义缺口：`ADDW/ADDIW/*W` 没有 sign-extend、RV64M/W 和 RV64B/Zba/Zbb/Zbc/Zbs 仍按 RV32 处理，memory path 的 `wstrb`/alignment/cache index 仍是 4-byte 假设，导致 `bitmanip`/访存类测试不能作为默认性能路径。
- **修复**: 2026-05-30 已修复。`npc/rv64` 恢复 `0x8000_0000..0x87ff_fffc` cacheable，I/D cache line 设为 `8 x 64-bit beat`，ICache refill/byte select 改用 `XLEN_BYTE_W/XLEN_BIT_SHIFT`；OoO 后端补齐 RV64 `*W` sign-extend、RV64M/W、RV64 bitmanip 和 8-bit `STRB_W` 访存链路，`OooMemAxiBridge` 按 8-byte aligned word 建 D-cache index/merge，最后将 `npc/rv64/Makefile` 默认切到已验证的双发射 OoO 后端。验证：默认 `make -C npc/sim BACKEND=rv64 lint` 与 build PASS；默认 cpu-tests `40/40 PASS`；默认 CoreMark `ITERATIONS=1000` 在当前性能配置 `Difftest: OFF` 下输出 `CoreMark PASS 8 Marks`、`cycles=247287515`、`commits=317356136`、`CPI=0.779`。
- **教训**: RV64 迁移不能只改 `XLEN` 和 ABI；cacheable 地址、line beat、byte lane、word-op sign-extension、bitmanip 宽度、访存 strobe/alignment 都是同一个数据通路契约。性能目标低于 1 CPI 时，顺序核即便 cache 正常也不可能达标，必须把性能后端作为默认路径前先用全量 cpu-tests 证明其 RV64 语义闭合。

### [31] RV64 NPC 没有可用 NEMU DiffTest reference

- **模块**: NPC RV64 / NEMU reference / DiffTest
- **现象**: `npc/rv64` 初始只能关闭 difftest 自检；直接构建 `GUEST_ISA=riscv64 SHARE=1` 时 NEMU 没有独立 `src/isa/riscv64`，绕到 RV32 源后又缺 RV64I load/store、OP-32、RV64M/B/C、CSR/misa 与 64-bit CPU_state 语义，不能作为逐条参考。
- **根因**: 本仓库的 `CONFIG_RV64` 过去主要切换 `word_t/CONFIG_ISA64`，ISA 源码目录、CSR 布局、扩展 Kconfig 和 `inst.c` 执行语义仍以 RV32 为主。后续 CoreMark 首次 difftest 还暴露出 NEMU `CONFIG_MEM_RANDOM=y` 与 NPC 零初始化 PMEM 不一致，读取未显式写满的栈槽时会在无关高字节上分叉。
- **修复**: 2026-05-30 已修复。`filelist.mk` 将 `riscv64` 映射到共享 RV32 源，`isa-def.h/inst.c/reg.c/intr.c` 补齐 RV64 CPU/CSR/指令/异常语义，`RISCV_EXT_M/B/C` 允许 RV64；新增 `riscv64-npc_defconfig` 并关闭 `MEM_RANDOM`。NPC 侧默认开启 RV64 difftest，补齐 RV64B/Zba `.uw` 与 RVC RV64 差异；AM 侧可随 `npc/sim BACKEND=rv64` 自动切到 `riscv64-npc/lp64`。验证：NEMU RV64 shared object 构建 PASS；`ARCH=riscv64-npc` cpu-tests `40/40 PASS`；CoreMark 默认 `1000` iterations + DiffTest ON `CoreMark PASS` / `HIT GOOD TRAP`。
- **教训**: Kconfig 名称不是 reference 能力证明；DiffTest reference 必须和 DUT 的 ISA/ABI、CSR 以及初始内存基线都对齐。CoreMark 这类 C 程序可能读到未显式写满但随后会被 mask 的栈字节，逐条 difftest 仍会比较完整寄存器值，因此 reference/DUT 的 PMEM 初始化也属于验收前提。

### [26] NPC 配置切换不会稳定触发 Verilator 二进制重建，可能继续沿用旧产物

- **模块**: NPC / Makefile / Kconfig
- **现象**: `.config` 与 `include/generated/autoconf.h` 已更新配置，但直接 `make run` 仍可能运行旧 `npc/single/build/NpcSimTop`，例如关闭 `CONFIG_NPC_PROGRESS_BY_DEFAULT` 后仍打印 `[progress] ...`，或切回 VGA 后仍显示 `NPC VGA disabled`。
- **根因**: `include/generated/autoconf.h` 只通过 `-include` 传给 Verilator CFLAGS，之前没有作为 `$(BIN)` 的显式依赖；配置切换后如果 RTL/C 源文件没变，`make` 会认为二进制仍是最新。
- **修复**: 2026-05-22 已修复：`npc/single/Makefile` 新增 `CONFIG_OUTPUTS := include/generated/autoconf.h include/config/auto.conf`，并把它们加入 `$(BIN)` 依赖。验证：`make -C npc/single -W /home/lyg/PA/ysyx-workbench/npc/single/include/generated/autoconf.h -n default` 会展开 Verilator 重建命令；普通 `make -n default` 在二进制晚于配置头时保持 no-op。
- **教训**: Kconfig 选项影响 CFLAGS/条件编译时，配置生成物必须进入最终产物依赖链；否则用户看到的是“配置明明关了/开了却无效”，实际只是二进制陈旧。

### [27] RT-Thread AM on NPC 在线程入口返回后触发 `context.c:69`

- **模块**: Abstract Machine / RT-Thread BSP / NPC
- **现象**: `riscv32-npc` 上 RT-Thread 已打印 banner、utest 和 `Hello RISC-V!` 后，立即报 `Assertion fail at .../context.c:69`，NPC 侧显示 `HIT BAD TRAP at pc = 0x80043f9a`、`exit via ebreak, code=1`。
- **根因**: `pc=0x80043f9a` 是 `halt(1)` 内的 `ebreak`，不是第一现场。真正问题是 `rt_hw_stack_init()` 只按 `RT_ALIGN_SIZE=8` 计算新线程栈布局，而 RISC-V AM 的 `kcontext()` 会把 `kstack.end` 再按 16 字节向下对齐并清零 `Context`。当 RT-Thread heap 返回的线程栈顶是 8-byte-only 对齐时，`kcontext()` 实际放置的 `Context` 会比 BSP 预估位置低 8 字节，覆盖 `RtAmThreadStart.exit` 字段；trampoline 随后看到 `exit == NULL`，跳过 `texit` 并触发第 69 行 `assert(0)`。
- **修复**: 2026-05-22 已修复：`Templates/rt-thread-am/bsp/abstract-machine/src/context.c::rt_hw_stack_init()` 先把 `kstack.end` 按 16 字节对齐，再在该边界下方布局 `Context` 和 `RtAmThreadStart`，使 BSP 预留空间与 RISC-V `kcontext()` 内部行为一致。复验 `timeout 30s make ARCH=riscv32-npc run` 已进入 RT-Thread `msh` 并执行 shell 命令；native 回归和 `yield-os` on NPC 均正常。
- **教训**: OS/BSP 桥接栈布局时不能只看上层 RTOS 的最小对齐，还必须匹配底层架构 `kcontext()` 的真实对齐和清零范围。看到 trap PC 落在 `halt/ebreak` 时，要先沿断言/退出路径回溯，不要把 ebreak 地址当作原始异常点。

### [24] NPC 默认 Verilator 构建携带 `--prof-cfuncs/-pg`，普通运行不再是干净性能基线

- **模块**: NPC / Verilator / 性能
- **现象**: `npc/single/Makefile` 默认 `VERILATOR_FLAGS` 含 `--prof-cfuncs`；生成的 `npc/single/build/obj_dir/VNpcSimTop.mk` 中 `VM_PROFC=1`，Verilator 公共 `verilated.mk` 会据此给编译和链接都追加 `-pg`。因此默认二进制适合 gprof 归因，但不适合作为普通仿真速度基线。
- **根因**: `--prof-cfuncs` 被当作“便于 profile 且运行期零开销”的默认选项保留在普通构建中；但 Verilator 5.020 的生成 makefile 会把它转成 profile build，并会拆分生成函数/影响内联。
- **修复**: 2026-05-21 已修复：默认 `VERILATOR_FLAGS` 移除 `--prof-cfuncs`，新增 `VERILATOR_PROFILE/VERILATOR_PROF_EXEC/VERILATOR_THREADS*` 显式开关；`gprof-build` 才设置 `VERILATOR_PROFILE=1`，`prof-exec-build` 才设置 `VERILATOR_PROF_EXEC=1`。复验 `VM_PROFC=0`，MicroBench 单线程性能约 `2.68-2.81M inst/s`。
- **教训**: 仿真性能基线必须区分“profile 构建”和“release/perf 构建”；任何用于定位热点的插桩都不能长期留在默认路径，否则后续比较会把工具开销误判成 RTL 或 Verilator 本身慢。

### [25] NPC perf 配置关闭 VGA 后仍会被 C fallback 重新打开

- **模块**: NPC / Kconfig / VGA / 性能配置
- **现象**: 使用 `perf_defconfig` 跑 benchmark 时仍可能出现 SDL/VGA 窗口；`perf_defconfig` 中 `CONFIG_NPC_HAS_VGA=n`，但运行时 `CoreMark -> ioe_init -> __am_gpu_init` 仍认为 GPU present 并写 `SYNC_ADDR`，host 侧随后创建窗口。
- **根因**: Kconfig 的 `bool=n` 在 `include/generated/autoconf.h` 中表现为没有对应宏；`npc/single/csrc/include/utils.h` 的 fallback 却把未定义的 `CONFIG_NPC_HAS_VGA` 定义为 1。同类扫描确认 `CONFIG_NPC_SDB/EXPR/WATCHPOINT` 也曾有关闭后被 fallback 为 1 的风险。
- **修复**: 将 `CONFIG_NPC_HAS_VGA`、`CONFIG_NPC_SDB`、`CONFIG_NPC_EXPR`、`CONFIG_NPC_WATCHPOINT` 的 fallback 统一改为 0，并补注释说明 bool fallback 必须保守处理 Kconfig not-set 语义。
- **教训**: 对 Kconfig bool，未定义不是“配置缺失”，而是合法的关闭态。手写兼容默认值只能让整数/字符串补默认值，bool 应默认关闭，否则性能配置和最小配置会被悄悄污染。

### [21] NPC cache 曾停留在 Verilator host bus 透明模型，还不是可综合 RTL cache

- **模块**: NPC / cache / RTL-PPA
- **现象**: 早期 `riscv32-npc` 虽可通过 `fence-i` 自修改代码测试，并能输出 ICache/DCache counter，但真正的 cache tag/data/miss/fill/writeback 位于 `npc/single/csrc/memory/cache.c`；DPI 取指/访存经 host bus cache 后再访问 PMEM/MMIO，`NpcCore` 的 IFU/LSU ready/valid 接口没有真实多拍 cache miss/fill 时序。
- **根因**: 当时优先目标是按 NEMU 可选功能闭合功能与 difftest 回归，先做对 RTL 透明的 simulator cache，避免一次性扩大流水线控制面、外部 memory protocol 和 PPA 闭环。
- **修复**: 2026-05-19 新增 `npc/single/vsrc/IDCache.v`，在 `NpcCore.v` 内部接入可综合阻塞式 ICache/DCache，host `dpi.c` 改为 raw PMEM/MMIO 访问，`NpcSimTop.sv` 通过层次化引用观察 `u_core.cache_flush_valid_w`。复验 `make -C npc/single lint`、`make -C npc/single`、全量 `cpu-tests` 38/38 difftest 与 MicroBench `mainargs=test` difftest 均 PASS。
- **教训**: “参考模型/仿真器可观察到 cache 行为”不等于“CPU RTL 已经实现 cache 微结构”。记录性能数据时需要明确层次边界，避免把 host 侧透明优化误当作硬件 PPA 结果。

### [20] NPC 流水线化后 PC 跑飞：IF 返回丢失与 load 响应未前递

- **模块**: NPC / RTL 流水线 / IFU/LSU 冒险
- **现象**: 初版流水线在简单 `add` 可继续跑通，但更复杂的 AM 路径会出现 PC 跑飞；`am-tests mainargs=i` 曾在跳表附近把 PC 带到 `0x00007980`，触发 fetch out of bound。
- **根因**: 两层问题叠加：① IF fetch buffer 的容量判断只看旧的 `fetch_buf_valid_q`，没有把本拍 incoming response 和本拍 buffer 消费一起纳入，后级背压时可能静默丢取指返回；② load-use 只做了 ID 阶段一拍停顿，消费者进入 EX 时若 load 数据正好在 MEM 响应同拍返回，EX 仍只能从旧寄存器/MEM-WB 取值，跳表索引路径会读到旧地址。
- **修复**: IF 侧新增基于 `fetch_rsp_slot_w/fetch_issue_slot_w` 的容量计算，保证不会在没有槽位时继续接收/覆盖返回；EX 操作数转发新增 `mem_response_w && ex_mem_load_q` 的同拍 LSU 响应前递，同时保留 EX/MEM、MEM/WB 转发和 load-use stall。随后 `make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc run` 35/35 PASS，`am-tests mainargs=i` 能稳定进入交互菜单并运行到超时，`yield-os` 持续输出 `ABAB...`。
- **教训**: 流水线冒险不能只用“停一拍”口头覆盖；需要逐拍确认数据在哪一级产生、哪一级消费。带 ready/valid 的 IF/MEM 也要把“本拍进出队”合并计算容量，否则 bug 会表现为远端 PC 跑飞，根因却在更早的握手边界。

### [19] fceux-am 在 NPC 上 BAD TRAP：FUNC_IDX 溢出 + 音频设备 panic

- **模块**: FCEUX-AM / Abstract Machine / NPC
- **现象**: `make ARCH=riscv32-npc mainargs=mario3 run` 先因 `FUNC_IDX_MAX=16` 溢出 `halt(1)`，修复后又因 `io_read(AM_AUDIO_CONFIG)` 触发 `access nonexist register` panic。
- **根因**: 两层问题：① `fceux-am/src/config.h` 未识别 `__PLATFORM_NPC`，落入 `PERF_LOW` → `FUNC_IDX_MAX16`，MMC3 mapper 注册超 16 个唯一函数指针时 assert 失败；② 修成 `PERF_MIDDLE` 后 `SOUND_CONFIG` 变成 `SOUND_LQ`，`sdl-sound.cpp` 中 `io_read(AM_AUDIO_CONFIG)` 被编译进来，但 `riscv32-npc` 的 `ioe.c` 没有注册编号 14 的 `AM_AUDIO_CONFIG`。
- **修复**: ① 在 `config.h` 的 `#elif` 分支加上 `|| defined(__PLATFORM_NPC)` 使 NPC 获得 `PERF_MIDDLE`；② 在 `abstract-machine/am/src/riscv/npc/ioe.c` 新增 `__am_audio_config` 空桩（`present=false, bufsize=0`）并注册到 lut。修复后 mario3 在 NPC 上成功加载运行。
- **教训**: 跨平台的性能/功能配置层（如 `config.h`）在新增平台时必须显式接入，否则会静默退回最低档位带来意料之外的功能裁剪。IOE 设备查找表对所有 AM 定义的设备至少应提供 `present=false` 回应，避免任何程序碰未实现设备就直接 panic。后续实现 NPC 真实音频时，需把空桩替换为真实实现并同时注册 `AM_AUDIO_CTRL/STATUS/PLAY`。

### [8] am-tests 的 devscan 在 NEMU 上访问 GPU 高级接口时触发 BAD TRAP

- **模块**: AM-Kernels / Abstract Machine / NEMU
- **现象**: 早期执行 `make -C am-kernels/tests/am-tests ARCH=riscv32-nemu run mainargs=d NEMUFLAGS=-b` 时，日志会先打印 `Screen size: 400 x 300`，随后报 `AM Panic: access nonexist register`，NEMU 最终 `HIT BAD TRAP`。
- **根因**: `am-kernels/tests/am-tests/src/tests/devscan.c` 会调用 `io_write(AM_GPU_MEMCPY, ...)` 和 `io_write(AM_GPU_RENDER, ...)`；当时 `abstract-machine/am/src/platform/nemu/ioe/ioe.c` 只注册了 `AM_GPU_CONFIG`、`AM_GPU_FBDRAW`、`AM_GPU_STATUS`，没有注册 12/13 号 GPU 高级寄存器，因此访问时会落到 `fail()` 并 panic。
- **修复**: 2026-04-14 已通过共享软件渲染层 `abstract-machine/am/src/platform/gpu_soft.h` 补齐 NEMU/NPC 两条平台的 `AM_GPU_MEMCPY/AM_GPU_RENDER`，`platform/nemu/ioe/ioe.c` 现在已注册这两个寄存器，`platform/nemu/ioe/gpu.c` 会把 canvas/texture 数据写入 512KB 软显存并渲染到 framebuffer。历史验证显示 NEMU `am-tests mainargs=d` 已到达 `Test End!`。
- **教训**: 做回归归因时不要只看“最近改过什么”，还要先核对平台设备分发表和 AM 抽象 ABI 是否一致；这类 `access nonexist register` 更像平台能力缺口，不应直接归因到 `stdlib` 或其它最近改动上。

### [16] NPC 开启基础 VGA 后，AM 带 IOE 的程序一度在 `__am_gpu_init` 阶段提前超时

- **模块**: NPC / Abstract Machine
- **现象**: 给 `riscv32-npc` 平台补上 `VGACTL_ADDR/FB_ADDR` 和基础 GPU IOE 后，`am-tests mainargs=k/v` 在刚启动时就反复卡在 `0x80001624/0x8000162c`，也就是 `__am_gpu_init()` 的 `sw zero, 0(a5)` 清屏循环；即使用户真正想验证的是 keyboard 或 `AM_GPU_FBDRAW`，程序也会先在 GPU 初始化阶段把默认周期预算烧光。
- **根因**: `abstract-machine/am/src/riscv/npc/gpu.c` 起初沿用了 guest 侧逐像素清 400x300 framebuffer 的写法，这在 NEMU 上问题不大，但对当前多周期 NPC 来说会先消耗数十万次 `store` 提交；而宿主 `VgaDevice::Init()` 实际上已经把 framebuffer 后端清零了，这段 guest 清屏因此变成了纯冗余开销。
- **修复**: 把 `__am_gpu_init()` 收敛成“只做一次 sync”，把初始黑屏语义交给宿主 `VgaDevice::Init()` 负责；随后重新执行 `printf 'a' | ./npc/single/build/NpcSimTop ... mainargs=k --stdin-kbd --no-itrace --max-cycles 500000`，确认 `readkey test` 已输出 `A DOWN/UP`，并复验 `mainargs=v` 的停点已推进到 `__am_gpu_fbdraw` 的像素拷贝循环。
- **教训**: 对 RTL 目标上的平台初始化，不能机械照搬参考模型的 guest 侧大块清屏/搬运逻辑；只要宿主后端能在更低成本的抽象层提供同样的初始状态，就应该把这类 bulk 操作下沉到宿主，否则功能还没开始，性能预算就先被平台 glue 烧掉。

### [14] NPC 开启波形时启动阶段反复报 `previous dump`，日志文件也缺少可读的 guest 输出

- **模块**: NPC / cpu-exec / monitor / device
- **现象**: 打开默认波形后，程序刚启动就打印 `%Warning: previous dump at t=9, requesting t=0, dump call ignored` 一串 warning；即使 `npc-log.txt` 已经打开，文件里也主要只有 host 侧欢迎信息和收尾摘要，guest 串口文本不完整，离线排查体验很差。
- **根因**: `apply_reset()` 的 warmup 已经把 VCD 时间推进到 `t=9`，但后续 `clear_runtime_state()` 又经由 `reset_npc_state()` 把整份 `NpcStats` 连同 `sim_time` 一起清零，导致正式执行重新从 `t=0` dump；同时日志系统此前只镜像 `Log(...)`，guest 串口输出直接写 stdout，没有进入文件日志。
- **修复**: 把运行态清理收窄成“只清 `NpcState`，不重置 `NpcStats::sim_time`”，确保 VCD 时间轴持续单调；同时新增 `NPC_ITRACE_BY_DEFAULT`、`NPC_MTRACE_BY_DEFAULT`、`NPC_DTRACE_BY_DEFAULT` 默认运行态开关，并把 guest 串口输出整理成 `[guest] ...` 行写入日志文件。复验 `make -C am-kernels/kernels/hello ARCH=riscv32-npc run` 后，warning 已消失，`npc/single/build/npc-log.txt` 也能直接看到 `[guest] Hello, AbstractMachine!`。
- **教训**: “状态复位”和“trace 时间轴复位”不是一回事；只要 VCD 已经开始 dump，就不能再把时间戳回卷。另一方面，若希望日志文件承担 NEMU 风格的离线调试作用，就必须同时保留 host trace 和 guest 串口文本，不能只镜像其中一边。

### [13] NPC 长时间 batch 跑分时完全静默，容易被误判为卡死

- **模块**: NPC / cpu-exec / monitor
- **现象**: 跑 `coremark` 这类需要数分钟的 `riscv32-npc` 长测试时，终端长时间没有任何新输出；即使仿真实际上还在持续推进，使用者也很难区分“只是没跑完”和“真的卡住了”。
- **根因**: `npc/single` 的执行循环此前只有“开始 welcome”和“最终退出/异常/超时”这两类输出，中间没有任何连续执行期间的可观测反馈。
- **修复**: 新增 `CONFIG_NPC_DEFAULT_PROGRESS_INTERVAL` 和 `--progress/--no-progress/--progress-interval`，并在 `cpu_exec()` 的连续运行路径按提交指令数周期性打印 `[progress] <commits> insts, pc=..., <inst/s> inst/s`；`si` 这类短命令默认不打印，避免刷屏。
- **教训**: 长时间仿真除了功能正确性，还要考虑“宿主层可观测性”；否则用户会在没有故障证据的情况下先怀疑卡死，调试效率会被交互体验拖慢。

### [12] klib 的 printf 缺少无符号/十六进制格式，导致 CoreMark 打印成 `0x%x`

- **模块**: Abstract Machine / klib / AM-Kernels
- **现象**: `coremark` 中的 `seedcrc/crclist/crcmatrix/crcstate/crcfinal` 会显示成 `0x%x`，`devscan` 之类使用 `%08x` 的路径也会把格式串近似原样吐出来。
- **根因**: `abstract-machine/klib/src/stdio.c` 的 `kvsnprintf()` 早先只覆盖 `%d/%s/%c/%%` 的窄子集，虽然解析了宽度和前导 `0`，但没有把这些能力真正接到 `%u/%x/%p` 等常用整数格式上。
- **修复**: 把整数格式统一收口到共享输出路径，补齐 `d/i/u/x/X/p`、`l/ll`、字段宽度和补零支持，并在 `am-kernels/tests/klib-tests/tests/klib_fmt.c` 中新增 `%u/%04x/%08x/%X/%p` 回归；随后在 `riscv32-nemu` 和 `riscv32-npc` 上复跑 `klib-tests`，并用 `coremark` 验证 CRC 已恢复真实十六进制输出。
- **教训**: 这类问题必须在公共格式化层根治，不能为单个 benchmark 临时改打印语句；同时一旦扩 `printf` 能力，就要补回归测试，否则下次仍会静默退化。

### [11] NPC 停在 `(npc)` 提示符时按 `Ctrl-C` 不能退出

- **模块**: NPC / monitor / cpu-exec
- **现象**: 进程停在 `Welcome to riscv32-NPC! ... (npc)` 提示符时，按 `Ctrl-C` 只会在终端上看到 `^C`，但 NPC 进程并不会退出，用户只能直接关掉整个终端标签页。
- **根因**: `SIGINT` 处理原先只把一个停止标志写到 `cpu-exec.cpp` 内部，而这个标志只会在 `cpu_exec()` 的运行循环中被消费；当 monitor 空闲停在 `std::getline()` 读命令时，没有任何代码去处理这次中断，而且 `signal()` 默认的重启语义会让阻塞读继续挂着。
- **修复**: 改为使用不带 `SA_RESTART` 的 `sigaction(SIGINT, ...)` 安装处理器，并把 `SIGINT` 标志通过 `consume_sigint_request()` 暴露给 `sdb_mainloop()`；现在连续执行中的 `Ctrl-C` 仍然只会中断回 prompt，而 prompt 态 `Ctrl-C` 会直接退出整个 NPC 进程。
- **教训**: 交互式仿真器不能只处理“运行态中断”，还要处理“提示符阻塞读”的中断路径；否则用户看到的会是典型的“终端已经收到了 Ctrl-C，但应用层没退”的假死体验。

### [10] NPC 默认 `itrace` 条件 `true` 一度被误判为非法表达式

- **模块**: NPC / monitor / trace
- **现象**: 即使没有显式打开 `itrace`，只要默认配置里保留 `CONFIG_NPC_ITRACE_COND="true"`，启动 batch `--mtrace --dtrace` 或 monitor `info t` 时也会先打印 `[npc] bad itrace condition 'true', fallback to true.`。
- **根因**: `trace.cpp` 会在初始化阶段预校验 `itrace` 条件，但当前表达式求值器只认识数字、寄存器和运算符，不认识裸布尔字面量 `true/false`，导致默认条件字符串被错误地视为非法表达式。
- **修复**: 在 `npc/single/csrc/monitor/trace.cpp` 里先对 `true/false/0/1` 做字面量兼容，再把其他情况交给 `expr()`；修复后默认配置和 `trace cond true` 都不再报错。
- **教训**: 配置层默认值如果打算直接喂给表达式求值器，就不能只验证“典型复杂表达式”，还要覆盖最常见的字面量语义，否则看似无害的默认配置也会在启动路径上制造误报警。

### [9] NPC 的 `si 1` 在 monitor 中一度停在旧 PC

- **模块**: NPC / monitor / cpu-exec
- **现象**: 对 hello 镜像执行 `si 1` 后，`info s` 会显示 `commits = 1`，但 `pc` 仍停在 `0x80000000`，看起来像没有前进到下一条待执行指令。
- **根因**: `cpu_exec()` 原先在命中最后一次提交后立刻返回，而 RTL 导出的 `debug_pc_o` 仍对应当前在途状态；host 正好在提交边界采样，导致 monitor 看到的是“刚完成提交的旧 PC”。
- **修复**: 在 `npc/single/csrc/cpu/cpu-exec.cpp` 中，当 `si`/定步命中最后一次提交后，额外推进一个不产生新提交的收尾周期，再返回 monitor；复验后 `si 1` 已能稳定看到 `pc = 0x80000004`。
- **教训**: 单步调试的用户观感不只取决于“提交是否发生”，还取决于 host 选择在哪个微状态对外暴露调试信号；如果直接在提交边界返回，monitor 很容易比用户预期落后半拍。

### [1] AM hello 访问串口地址触发 pmem 越界

- **模块**: NEMU / Abstract Machine
- **现象**: 运行 hello 时在 pc = 0x80000090 访问 0xa00003f8，报 address out of bound of pmem [0x80000000, 0x87ffffff]
- **根因**: AM 的 putch 会向 SERIAL_PORT 写字符；该地址位于 DEVICE_BASE = 0xa0000000 的设备区。若 nemu/.config 中 CONFIG_DEVICE 未开启，且未使用 AM 目标配置，paddr_read/paddr_write 不会转到 mmio_read/mmio_write，而是直接按普通物理内存越界处理。
- **修复**: 切回 riscv32-am_defconfig 或在 menuconfig 中重新开启 CONFIG_TARGET_AM 和 CONFIG_DEVICE 后重编 NEMU。
- **教训**: 跑 AM 程序前不要直接沿用普通 system 模式配置；先确认 NEMU 目标配置与镜像类型匹配。

### [2] fceux-am 在无 ROM 时编译失败并误以为“游戏未移植”

- **模块**: FCEUX-AM
- **现象**: 执行 `make ARCH=riscv32-nemu run mainargs=mario` 时，早期版本会在 `src/emufile.cpp` 报 `roms.h: No such file or directory`；修复后可构建运行，但会明确提示 `No embedded ROM found. Put a .nes file under nes/rom/ and rebuild.`。
- **根因**: `fceux-am/Makefile` 用 `ls` 枚举 `nes/rom/*.nes`；当目录为空时，`ROM_SRC` 为空导致 `rom` 规则不触发，`nes/gen/roms.h` 根本不会生成。与此同时，运行逻辑默认假设至少有一个 ROM 可供选择，容易把“缺 ROM 文件”误判成“超级玛丽没有移植好”。
- **修复**: 改为用 `wildcard`/`patsubst` 生成 ROM 列表，并让 FCEUX 源文件总依赖 `rom` 规则；`build-roms.py` 在零 ROM 时也生成占位 `roms.h`，`emufile.cpp` 在 `nroms <= 0` 时给出明确提示。
- **教训**: 对编译期资源生成链，不能把“输入为空”直接退化成“生成规则不执行”；否则错误会以缺头文件的形式在下游爆出来，定位成本很高。

### [4] cpu-exec 优化后在 TRACE/DIFFTEST/WATCHPOINT 全开时编译失败

- **模块**: NEMU / CPU Exec
- **现象**: 打开 `CONFIG_ITRACE`、`CONFIG_DIFFTEST`、`CONFIG_WATCHPOINT` 后，`cpu-exec.c` 编译报 `g_print_step undeclared`、`watchpoint_enabled undeclared`，并连带触发 `need_itrace_logbuf()` 的 `return-type` 警告。
- **根因**: 优化时新增的 `need_itrace_logbuf()` 放在 `g_print_step` 定义之前，C 编译器不会为后面的文件作用域变量做提前声明；同时 `cpu-exec.c` 直接使用了 `watchpoint_enabled` 快路径，却没有在该编译单元中包含声明它的 `watchpoint.h`。
- **修复**: 将 `g_print_step` 前移到 ITRACE 辅助函数之前，并在 `CONFIG_WATCHPOINT` 下显式包含 `src/monitor/sdb/watchpoint.h`；这样既保留懒构造 logbuf 和监视点快路径，又恢复所有调试开关组合下的可编译性。
- **教训**: 对热路径做局部优化时，不能只在“当前配置能过”下验证；凡是新引入的 helper、全局状态和快路径标志，都要重新检查它们在不同 `#ifdef` 组合中的声明顺序和可见性。

### [5] 当前宿主环境中的 SDL/Mesa 泄漏报错经重装运行库后消失

- **模块**: NEMU / 宿主 SDL-Mesa 环境
- **现象**: 此前 `make ARCH=riscv32-nemu run mainargs=v` 与类似 VGA 路径会在退出时触发 `LeakSanitizer: detected memory leaks`，调用栈落在 `libGLX_mesa.so`、`libSDL2.so` 和 `src/device/vga.c:init_screen()`。
- **根因**: 代码层面存在上游 NEMU 也具备的 SDL 生命周期缺口；但在本机这次案例中，宿主 SDL/Mesa 运行库或其后端状态也是触发“由噪音升级为报错”的关键因素，因为单改运行库状态后问题即消失。
- **修复**: 用户在宿主机执行 `sudo apt install --reinstall -y libsdl2-2.0-0 libglx-mesa0 libgl1-mesa-dri libegl-mesa0 mesa-vulkan-drivers` 后反馈“没问题了”。
- **教训**: 当 SDL/GLX/Mesa 调用栈只在某一台机器稳定复现时，不要只盯 guest 程序或上游代码；先核对宿主图形运行库、显示后端和 sanitizer 配置，低风险重装运行库往往能快速区分“代码问题”和“环境问题”。

### [6] AM 目标下监视点符号在链接阶段未定义

- **模块**: NEMU / CPU Exec / AM Target
- **现象**: 执行 `make ARCH=riscv32-nemu` 时，链接 `riscv32-nemu-interpreter-riscv32-nemu.elf` 报 `undefined reference to 'watchpoint_enabled'` 和 `undefined reference to 'compare_assert'`。
- **根因**: `ARCH=riscv32-nemu` 对应 `CONFIG_TARGET_AM=y`，而 `src/filelist.mk` 会在该目标下把 `src/monitor/sdb` 整个排除出构建，所以 `watchpoint.c` 不会参与链接；但 `src/cpu/cpu-exec.c` 里的监视点路径仍可能因为当时的 AM 配置开启了 `CONFIG_WATCHPOINT`，或复用了旧的 `build/riscv32-nemu/src/cpu/cpu-exec.o`，从而继续引用这两个符号。
- **修复**: 已在 `nemu/Kconfig` 中为 `WATCHPOINT` 增加 `depends on !TARGET_AM`，并在 `nemu/src/cpu/cpu-exec.c` 中把监视点相关包含与执行分支都改成“`CONFIG_WATCHPOINT` 且非 `CONFIG_TARGET_AM`”才编译；随后复现 `make -C am-kernels/kernels/nemu ARCH=riscv32-nemu mainargs=/home/lyg/PA/ysyx-workbench/am-kernels/kernels/hello/build/hello-riscv32-nemu.bin`，确认链接恢复正常并成功运行到 `HIT GOOD TRAP`。
- **教训**: 分析链接错误时不能只看当前根目录 `.config`；还要同时核对目标类型对应的源码黑名单和该目标目录中的对象文件是否为旧配置残留。对这类不合法配置组合，优先在 Kconfig 和源码使用点两层同时收口，比只在 Makefile 或生成宏文件里做单点修补更稳。

### [7] 定宽宽度宏直接参与位宽算术时触发告警

- **模块**: NPC / IFU / BHT
- **现象**: 在 `npc/single/vsrc/IFU/bh_bt.v` 中把 `DATA_WIDTH_pc`、`BHT_ADDR_WIDTH` 直接拿来做 localparam 减法、移位和位选边界计算时，文件级检查报 `expects 32 bits ... generates 4 bits/6 bits` 一类位宽不匹配错误。
- **根因**: `npc/single/vsrc/IFU/define.v` 把宽度宏定义成了 `6'b100000`、`4'b1000` 这样的定宽常量；它们直接参与参数算术时会保留原始位宽，检查器不会自动提升到 32 位。
- **修复**: 在 `bh_bt.v` 中先把 `DATA_WIDTH_pc`、`BHT_ADDR_WIDTH` 零扩展成 32 位 localparam，再参与 BHT 表深、tag 宽度和 part-select 边界计算；修改后文件级检查恢复无报错。
- **教训**: 宽度类宏如果写成定宽二进制常量，拿来做参数算术前要先显式扩展；更稳的长期方案是把这类宏改成无位宽十进制常量或 `localparam`。

## 调试技巧备忘
<!-- 在调试过程中发现的有用技巧 -->
- 像 ITRACE 这类调试功能不能只看“是否输出日志”，还要看“是否为了日志提前做了额外工作”；若 logbuf、反汇编、预取指在每条指令上无条件执行，即使最后没打印，也已经把开销付掉了。
- 宿主时间查询也是 NEMU 的常见隐藏热点：如果设备更新逻辑在每条 guest 指令后都调用 `get_time()`，即便大多数时候只是立即返回，也会形成稳定开销；可先按指令数做粗粒度节流，再用真实时间做精细门控。
- NEMU 性能排查不要只盯着 `inst.c`：若 `.config` 同时开了 `CONFIG_CC_ASAN`、`CONFIG_ITRACE`、`CONFIG_DTRACE`、`CONFIG_FTRACE`、`CONFIG_DIFFTEST`、`CONFIG_RT_CHECK`，这些调试/检测功能叠加后的开销通常远大于单条指令取值代码本身，先关掉不需要的开关再看热点更有效。
- NEMU/SDB 调试优先用可脚本化路径：`--batch`、日志、trace、watchpoint、表达式求值和专用测试程序；当前 agent 工具不能可靠向已运行的前台 readline monitor 连续发送输入，因此不要默认依赖“启动后再人工键入命令”的流程。
