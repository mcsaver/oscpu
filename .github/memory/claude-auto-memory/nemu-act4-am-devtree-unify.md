---
name: nemu-act4-am-devtree-unify
description: "NEMU ACT4 priv/Sv 0→161/161(9层修复,含dcache↔PTW真bug/VS总闸/Sv48-57泛化) + AM guest 真正统一到设备树(halt→syscon/timer→goldfish)"
metadata: 
  node_type: memory
  type: project
  originSessionId: 18feeedd-841d-4011-b4e4-e15d123c655b
---

2026-07-01 会话。NEMU 跑 ACT4 排查 → priv/Sv 0/97 全灭 → 逐层修到 161/161 → 再把 AM guest 真正统一到设备树让 CoreMark/cpu-tests 跑通。完整记录见 task-run `2026-07-01-nemu-act4-fullgreen-am-devtree-unify`,模块笔记见 [[device-address-unified-map]] 延续。

**NEMU ACT4 九层 root-cause（priv/Sv 0→97,I/M 一直 64/64）**：
1. **dcache↔Sv39 PTW 一致性真bug（最重要,反直觉）**：NEMU 是真 write-back dcache(`cache.c`,dirty 只在 evict/flush 回写 pmem)。guest 用普通 store 运行时构建页表→PTE dirty 停 dcache 未回 pmem；而 Sv39 walker(`mmu.c`)用 `paddr_read` 直读 pmem→读到 stale 0→虚假 invalid-pte page fault→fault-on-fault 死循环。**连 Linux 都没暴露(启动路径长,dirty line 自然 evict 侥幸躲过)**。A/B 铁证:同一 bin 只切 dcache,cache-on FAIL→cache-off GOOD TRAP。修=新增 `dcache_peek_read`/`dcache_coherent_write`(命中取 dcache dirty、未命中读 pmem,不 fill/evict/计统计=零性能基线扰动),walker PTE 读写走一致视图。
2. satp WARL 写非法 MODE 保持旧值(非清0)。3. 越界抬 guest access-fault 非 host assert(`paddr_is_accessible`+vaddr 预检,rv64dv 前提)。4. **VS 字段总闸**:sail-rv64-max(max 含 V)启动置 mstatus VS=Dirty,ACT harness 每 trap 把 sstatus 打包签名字与金标准逐位比对,VS 差 2 位就第一条 trap 失配死循环→一修解锁18个。5. Sv48/Sv57 walker N级泛化(3/4/5 级,对 Sv39 bit-exact)。6. TVM。7. menvcfg CSR 0x30a。8. Svnapot 64KiB NAPOT 翻译。9. Svrsw60t59b(PTE bits[60:59]=RSW 须忽略)。

**大坑（判定方向必须看金标准,不能只看测试名/注释）**：sail-rv64-max 是「max」config,实现了 V/Svnapot/Svrsw60t59b。所以名为 `svnapot_not_supported`/`svpbmt_disabled`/`pte_reserved_field` 的测试,金标准(.sig/.results)反而期望**翻译成功**(NAPOT)或**只对更窄的保留位 fault**——objdump 源码注释("required Page Fault")会误导。定方向必须对金标准逐 trap 比对。

**AM guest 真正统一到设备树（让 CoreMark/cpu-tests 在统一后的 NEMU 上跑通）**：
- 病根:AM guest 原依赖 NEMU **未实现**的简易设备(RTC@0x12000048,device_address.h 只统一了定义层、NEMU 侧从未注册)+ **ebreak halt**(NEMU system 模式把 ebreak 当官方 breakpoint,ACT4 依赖)→dummy 空程序跑飞 pc=0。
- 正解=AM 的 TRM/timer/IOE **架构在设备树真实设备上**(与 Linux 同一套设备): **halt→reset_syscon**(SiFive Test Finisher: code0→0x5555 poweroff/GOOD TRAP, code≠0→`(code<<16)|0x3333` fail/BAD TRAP; NEMU `syscon.c` 加 fail-with-code)、**timer→goldfish-rtc**(先读 TIME_LOW(0)锁存、再 TIME_HIGH(4),纳秒→微秒)、putch→ns16550a(已一致)、gpu/input **present=false**(设备树无简易 VGA/KBD)。bitmanip 编译:`riscv64-nemu.mk` -march 加 B(`rv64g_zba_zbb_zbc_zbs`,NEMU 已实现 Zbs/Zbb)。所有 gate 用 `#if defined(__riscv)&&!defined(DEVICE_MAP_LEGACY)` 只作用 riscv64-nemu,legacy(rv32)不动。
- 关键区分:普通 AM 程序在 **M-mode Bare(satp=0)** 跑,halt→syscon(物理 0x100000)正常=53 cpu-tests+CoreMark PASS 81 Marks 的原因;4 个 Sv39/SBI 系统测试(sbi-timer/linux-mini-boot/sv39-ad-bits/sv39-ras-relocate)在 S-mode+Sv39 跑,halt 时 syscon vaddr 未被其页表映射→page fault(真实 Linux 会 ioremap syscon)=需测试侧 identity-map syscon+对齐 SBI/ebreak(用户已定深挖,下一步)。

**4 个 Sv39/SBI 系统测试深挖修复(cpu-tests 53→57/57 全绿)**——统一原则=**ebreak 保持官方 breakpoint 语义(ACT4/semihost 依赖), AM 系统测试一律用设备树 syscon 退出**(不再靠 ebreak 停机):
- linux-mini-boot: S-mode+Sv39 halt→syscon(vaddr 0x100000)未被其页表映射→page fault; 修=测试页表 identity-map 低 1GiB(含 syscon), 如真实 Linux ioremap 设备。
- sv39-ad-bits/sv39-ras-relocate: 原 ebreak 当退出与 system breakpoint 冲突→handler 循环; 修=M 态 trap handler 检测 breakpoint(mcause=3)→直写 reset_syscon(M 态无分页,物理 0x100000): a0==0→0x5555 GOOD 否则 (a0<<16)|0x3333 BAD。**坑: RISC-V ori 立即数仅 12-bit(±2047), 0x3333 必须 `li t2,0x3333; or`**。
- sbi-timer: 原 SBI mock 不转发 MTIP→STIP; NEMU 的 CLINT mtimecmp 只派生 MTIP(machine)且 mideleg 不委托 machine timer(**改 NEMU 按 mideleg 投递会破坏 OpenSBI/Linux, 不可取**); 修=测试补完整 SBI(ecall SBI_SET_TIMER 设 mtimecmp+mie.MTIE; MTIP 中断→清 machine timer+置 sip.STIP 交付 S; S handler 收 STI 后关 sie.STIE 收口, STIP 归 M 清)。
- 中途曾用 "--tohost 是否启用" 区分 ebreak 停机/breakpoint, 但 semihost-ebreak 无 tohost 却需 breakpoint(与 sv39-ad-bits 冲突)→已回退该 NEMU 改动。教训: **不同 AM 测试对 ebreak 期望冲突时, 正解是让测试统一用 syscon 退出, 而非在 NEMU 里区分 ebreak 语义**。

NEMU 当前=Linux 设备图 config(riscv64,MSIZE=1GiB,serial 0x10000000)。切 AM difftest config(riscv64-am_defconfig)会让 NEMU 变库模式无法独立 batch 跑——验证 AM 无回归用当前 Linux config+`make ARCH=riscv64-nemu c`(带 -b batch)或手动 `nemu -b bin`。cpu-test 改 .c 后 build 增量检测可能不触发, 需 `make clean` 强制重编。**#6 rv64dv(riscv-dv) 已引入 `am-kernels/rv64dv`(仅 NEMU difftest vs spike)——首轮压测即定位并修复 2 个真 NEMU bug**(arch-test/Linux/CoreMark 均未暴露):
1. **`csrw misa` 误判 illegal**: `inst/csr.c` 的 `csr_write` 缺 `CSR_MISA` case→`default: return false` 非法指令; misa 是 WARL, `csrw misa` 合法、写非法位应忽略。riscv-dv boot 在设 mtvec 前 `csrw 0x301`→NEMU 抛非法→trap mtvec=0 跑飞 pc=0。修=`csr_write` 补 `case CSR_MISA: return true`(读回仍 `csr_misa_value()`)。
2. **write-back dcache 的 store 绕过 tohost 退出检测**: guest store 走 `dcache_write` 只落 dirty、**绕过 `paddr_write` 的 `paddr_tohost_check_write`**,该 check 又用 `pmem_read(tohost)` 读到 stale 0→`write_tohost` 退出(尤其 `sw gp,tohost; j write_tohost` 反复写的 self-loop)漏判、不 `HIT GOOD TRAP` 跑满 max-insts(**与 Sv39 walker 读 PTE 的 dcache↔直读一致性坑完全同源**)。修 2 处=①`cache.c` 的 `dcache_write` 写后补 `paddr_tohost_check_write`;②`paddr.c` 的 check 把 `pmem_read` 换 `dcache_peek_read`(一致视图)。诊断诡异点: `set_nemu_state` 端连续读 `prev=END`、execute 循环端读 `RUNNING`,同一 `_Atomic` objdump 确认每次 `mov` 内存读——矛盾最终指向"store 根本没走 set END 的那条路径"(dcache 快速路径)。教训: **原子变量读写值不一致时先怀疑两条不同写路径,而非编译器缓存**。
基础设施: 编 `spike-diff` riscv64 ref-so(`make -C nemu/tools/spike-diff GUEST_ISA=riscv64`; `utils.h` 的 `_Atomic` 加 `#ifdef __cplusplus` gate 让 C++ difftest.cc 能编)。runner=`scripts/rv64dv-run.sh`+Makefile+README(判定=NEMU difftest DUT=NEMU/REF=spike, PASS 充要=干净 HIT GOOD+零 mismatch)。验证: `riscv_arithmetic_basic_test` difftest vs spike `HIT GOOD TRAP`(~4800 指令,修前跑满)+零 mismatch; ACT4 priv/Sv 97/97+I 51/51+M 13/13 零回归。`riscv-dv/`+`venv/`(278M)未入库(README 重建,Py3.12 需 patch `imp→importlib`)。**下一步(未做): 接 NPC↔NEMU difftest(NEMU 已确立为可信金标准)**。

**[2026-07-02 更新] rv64dv 2-bug 已正式提交(de5e86abd)+ 同源审计再挖出 DMA↔dcache 一致性家族(#109, 525e48080)**: 按"host 直访 guest 内存"清单全审计——写侧 `paddr_dma_write*` 直写 pmem 绕 dcache(guest 读 stale+dirty writeback 反向覆盖 DMA 数据)→改 `dcache_coherent_write`; 读侧 virtio rng/net/disk `guest_readXX`+disk 裸 memcpy→新增 `paddr_dma_read_value/paddr_dma_read`(peek 一致读); sdb 调试读同修。**清单=tohost 检查/MMU walker/设备 DMA 读+写/调试器读, write-back dcache 下漏一个=静默数据破坏**。另修 Linux/Makefile 残留 `--virtio-input --simple-framebuffer` 悬空 flag(该特性已在 tracer 45c148039 整体回退,唯漏 Makefile→run-ubuntu-* dtb 断 4 天; 特性本体在 45c148039^ 可找回)。验证: rv64dv 5/0 + cpu-tests 57/57 + ACT4 161/161 + run-ubuntu-rootfs 完整 boot 到 systemd/Welcome(virtio DMA 重度正向)。坑: tracer 自动 commit 会把回退态快照进历史, `git log --all -S` 命中的可能是删除 commit(父提交才有内容); 跑 AM 测试必须 `c` target(batch), `run` 是交互 sdb 管道下全 FAIL 假象。
