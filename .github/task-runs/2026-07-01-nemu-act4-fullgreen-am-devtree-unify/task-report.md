# 任务报告：NEMU ACT4 全绿 + AM guest 真正统一到设备树

## 任务

用户要求：先用 NEMU 跑 ACT4 架构测试排查问题，问题清零后再引入 rv64dv(riscv-dv) 压测。
过程中发现 ACT4 priv/Sv 全灭，逐层攻克到 161/161；随后发现 AM guest(cpu-tests/CoreMark)
无法在统一后的 NEMU 上运行，用户进一步要求「把 AM 的地址管理真正统一，真正做到和设备树一致」。

## 成果一：NEMU ACT4 架构测试 0/97 → 161/161

初始：`rv64i/I` 51/51、`rv64i/M` 13/13 全绿，但 `priv/Sv` **0/97 全灭**。逐层 root cause + 每步验证无回归：

1. **dcache↔Sv39 PTW 一致性(真 bug, A/B 铁证)**：NEMU 是 write-back dcache，guest 用普通 store
   运行时构建页表，PTE dirty 停在 dcache 未回写 pmem；而 Sv39 walker 用 `paddr_read` 直读 pmem →
   读到 stale 0 → 虚假 page fault → fault-on-fault 死循环。**A/B**：`sv39_mstatus_mprv_Smode` 同一 bin，
   cache-on FAIL(3) → cache-off GOOD TRAP(2309 insts, 零 translate 失败)。这是连 Linux 都没暴露的
   latent bug(启动路径长, dirty line 自然 evict 侥幸躲过)。
   修复：新增 `dcache_peek_read`/`dcache_coherent_write`(命中取 dcache dirty 值、未命中读 pmem,
   不 fill/evict/计统计, 零性能基线扰动)，walker(mmu.c) PTE 读写改走一致视图。
2. **satp WARL 违规(#2a)**：写非法 MODE 清 0 违反 WARL；改为保持旧值(csr.c csr_sanitize_satp)。
3. **越界优雅 access-fault(#2b)**：guest 可控越界地址原先 host assert/panic 崩进程；新增
   `paddr_is_accessible`(pmem 快速通过)+ vaddr 层翻译后预检 → 抬 guest access-fault 而非崩溃。
   这是 rv64dv 把 NEMU 当 reference 跑随机程序的可靠性前提。
4. **VS 字段总闸(mstatus/sstatus bits[10:9])**：sail-rv64-max(max 含 V)启动把 FS+VS 都置 Dirty，
   ACT harness 每次 trap 把 sstatus 打包成签名字与金标准逐位比对，VS 差 2 位则第一条 trap 就失配 →
   死循环。一修解锁 18 个 sv39。修：isa-def.h 暴露 MSTATUS_VS_MASK/DIRTY 为可写 WARL + SD 兼顾 VS。
5. **Sv48/Sv57 N 级泛化**：walker 从硬编码 3 级泛化为 3/4/5 级(sv_levels_for_mode)，VPN 提取
   `(va>>(12+9*level))&0x1ff`，PA 用统一 low_mask 公式(对 Sv39 bit-exact)，canonical 按 mode 位宽。
   解锁近 64 个 sv48/sv57。
6. **TVM**：新增 MSTATUS_TVM(bit20)，S 态+TVM=1 时访问 satp / 执行 SFENCE.VMA → illegal instruction。
7. **menvcfg CSR(0x30a)**：svpbmt_disabled 测试 `csrc menvcfg` 清 PBMTE；NEMU 未实现 0x30a → illegal。
   新增 menvcfg WARL 寄存器(读写不陷阱)。PTE_PBMT 非0 仍 fault(未实现 Svpbmt)。
8. **Svnapot NAPOT 翻译**：sail-rv64-max 实现 Svnapot 1.0.0，金标准期望 N=1 叶页 NAPOT 翻译成功
   (非 fault)。实现 64KiB NAPOT(level0 + ppn[3:0]==0b1000, 低4位取自 VA)；非叶 N=1 仍 fault。
9. **Svrsw60t59b**：sail-rv64-max 把 PTE bits[60:59] 重定义为 RSW(软件可用位)，walker 须忽略；
   保留位收窄为 bits[58:54](PTE_RSVD=0x1f<<54)。

关键源码：`nemu/src/isa/riscv64/system/mmu.c`(walker/pte_invalid/NAPOT)、
`nemu/src/isa/riscv64/inst/csr.c`(satp WARL/VS SD/TVM/menvcfg)、
`nemu/src/isa/riscv64/inst/rv64i.c`(sfence TVM)、`nemu/src/isa/riscv64/include/isa-def.h`(VS/TVM/menvcfg)、
`nemu/src/memory/{cache.c,paddr.c,vaddr.c}`(dcache 一致探针/access-fault)、`nemu/src/device/io/{mmio.c,map.c}`。

## 成果二：AM guest 真正统一到设备树

Root Cause：AM guest 原依赖 NEMU **未实现**的简易设备(RTC@0x12000048)+ **ebreak halt**(与 NEMU
system 模式的官方 breakpoint 语义冲突, ACT4 依赖)；dummy 空程序都跑飞到 pc=0(pre-existing, pre-#1
binary 亦崩)。device_address.h 只统一了「地址定义」，实现层 NEMU 侧从未注册简易设备。

真正统一：让 AM 的 TRM/timer/IOE **架构在设备树真实设备上**(与 Linux 同一套设备)：
- **putch → ns16550a** @ 0x10000000(已一致)
- **halt → reset_syscon(SiFive Test Finisher)** @ 0x00100000：code=0→0x5555(poweroff/GOOD TRAP)，
  code≠0→(code<<16)|0x3333(fail/BAD TRAP)。NEMU syscon.c 扩展支持 fail-with-code。
- **timer → goldfish-rtc** @ 0x10003000：先读 TIME_LOW(0)锁存、再 TIME_HIGH(4)，纳秒→微秒。
- **gpu/input**：设备树无简易 VGA/KBD → present=false 且不触碰 0x12000xxx(否则 #2b access-fault)。
- **bitmanip 编译**：NEMU 实现了 Zbs/Zbb 指令，riscv64-nemu.mk 的 -march 加 B(rv64g_zba_zbb_zbc_zbs)。
- gate 一律 `#if defined(__riscv) && !defined(DEVICE_MAP_LEGACY)`，只作用 riscv64-nemu，legacy(rv32)不动。

改动文件：`abstract-machine/am/include/device_address.h`(加 DEV_SYSCON_BASE/DEV_GOLDFISH_RTC_BASE)、
`abstract-machine/am/src/platform/nemu/include/nemu.h`(SYSCON_ADDR/GOLDFISH_RTC_ADDR/RANGE)、
`.../nemu/trm.c`(halt→syscon)、`.../nemu/ioe/{timer.c(goldfish),gpu.c(gate),input.c(gate),ioe.c(input present)}`、
`abstract-machine/scripts/riscv64-nemu.mk`(march+B)、`nemu/src/device/syscon.c`(fail-code)。

## 验证

- ACT4：`priv/Sv 97/97`、`rv64i/I 51/51`、`rv64i/M 13/13` = **161/161**(config 恢复后复验仍全绿)。
- 无回归：pmp-pagewalk/ad/sfence-asid smoke 全 GOOD TRAP；I 的大量 load/store 全绿(证 #2b 不误判)。
- AM 统一：**CoreMark PASS 81 Marks + HIT GOOD TRAP**(Total time 35892ms 证 timer→goldfish 计时正确)；
  cpu-tests **0 → 53 GOOD**(含 bitmanip)；三侧设备地址门禁 `check-device-address-map.sh` PASS。
- dummy：`syscon poweroff(0x5555) → HIT GOOD TRAP`(halt→syscon 生效)。

## 成果三：4 个 Sv39/SBI 系统测试深挖修复(用户要求) —— cpu-tests 53→57/57 全绿

统一原则: **ebreak 保持官方 breakpoint 语义(ACT4/semihost 依赖), AM 系统测试一律用设备树 syscon 退出**。
- **linux-mini-boot**: S-mode+Sv39 下 halt→syscon(vaddr 0x100000)未被其页表映射 → page fault。修=测试
  页表 identity-map 低 1GiB(含 syscon), 如真实 Linux ioremap 设备(`mini_root[VPN2(0)]=...`)。
- **sv39-ad-bits / sv39-ras-relocate**: 原用 ebreak 当退出(旧 AM nemu_trap 语义), 与 system 模式官方
  breakpoint 冲突→handler 循环。修=M-mode trap handler 检测 breakpoint(mcause=3)→直写 reset_syscon
  (M 态无分页, 物理 0x100000): a0==0→0x5555(GOOD), 否则 (a0<<16)|0x3333(BAD)。ebreak 各退出点保持,
  语义交给 handler 统一到 syscon。(注: RISC-V ori 立即数仅 12-bit, 0x3333 需 `li t2,0x3333; or`。)
- **sbi-timer**: 原 SBI mock 不完整(不转发 MTIP→STIP)。NEMU 的 CLINT mtimecmp 只派生 MTIP(machine),
  mideleg 不委托 machine timer(改 NEMU 会破坏 OpenSBI/Linux, 不可取)。修=测试的 M-mode handler 补成
  完整 SBI: ecall SBI_SET_TIMER→设 mtimecmp+使能 mie.MTIE; MTIP 中断→清 machine timer+置 sip.STIP
  交付 S-mode; S-mode timer handler 收 STI 后关 sie.STIE 收口(STIP 归 M-mode 清)。
- 中途一度用 "--tohost 是否启用" 区分 ebreak(停机 vs breakpoint), 但 semihost-ebreak 无 tohost 却需
  breakpoint, 与 sv39-ad-bits 期望冲突→已回退该 NEMU 改动(csr.c/paddr.c 恢复原状), 改走上述"ebreak
  恒 breakpoint + 测试用 syscon 退出"的统一路径。

**最终验证(全部无回归)**: cpu-tests **57/57 GOOD**(含全部 4 个系统测试); ACT4 **161/161**(I/M/priv-Sv);
CoreMark **PASS 81 Marks + GOOD TRAP**; 三侧设备地址门禁 PASS。

## rv64dv(#6) —— riscv-dv 压测引入 + 首轮抓修 2 个 NEMU 准确性 bug

**目标**：把 chipsalliance/riscv-dv 约束随机指令流作为平台无关重型压测引入 `am-kernels/rv64dv`，
压 arch-test 定向用例覆盖不到的组合空间。**仅 NEMU**（暂不接 NPC——NPC 自身有 bug，先用 riscv-dv
死磕、把 NEMU 确立为可信金标准，再做 NPC↔NEMU difftest）。判定=复用 NEMU 自带 difftest（DUT=NEMU、
REF=`spike-diff` riscv64-so，逐指令逐寄存器比对），PASS 充要=干净 `HIT GOOD TRAP`+全程零 mismatch。

**通路打通**：riscv-dv pyflow（`--target rv64imafdc`，pyflow 无 rv64gc target）生成随机 .S →
`riscv-none-elf-gcc` 编译 → NEMU difftest。venv 装 pyvsc/pyyaml/bitstring/pandas/tabulate；
Python 3.12 需把 riscv-dv 的 `from imp import reload` patch 成 `importlib`。

**发现并修复的 2 个真 NEMU bug**（arch-test/Linux/CoreMark 均未暴露，是 rv64dv 的直接价值）：

1. **`csrw misa` 被误判 illegal**。`inst/csr.c` 的 `csr_read` 有 `CSR_MISA`（返回固定扩展集
   `csr_misa_value()`），但 `csr_write` **缺** `CSR_MISA` case → 落 `default: return false` →
   非法指令异常。misa 是 **WARL**：`csrw misa` 是合法指令，写非法/所有位应被忽略而非抛异常。
   riscv-dv boot code 在设 mtvec 之前 `csrw 0x301,x6` → NEMU 抛非法 → trap 到 mtvec=0 → 跑飞
   pc=0。修=`csr_write` 补 `case CSR_MISA: return true;`（接受并忽略，读回仍固定值）。Spike 正常执行。

2. **write-back dcache 的 store 绕过 tohost 退出检测**。NEMU 是真 write-back dcache
   （`CONFIG_CACHE=y`），guest store 走 `dcache_write()` 只落 dirty 行、不到 pmem，**绕过了
   `paddr_write()` 里的 `paddr_tohost_check_write`**；而该检查又用 `pmem_read(tohost)` 读值→
   读到 stale 0。于是 `write_tohost` 退出——尤其 riscv-dv 那种 `sw gp,tohost; j write_tohost`
   反复写的 self-loop——被彻底漏判，NEMU 不 `HIT GOOD TRAP`、跑满 `--max-insts`。arch-test 侥幸能停
   是因其退出为 `sw tohost; 1:j 1b`（只写一次 + 不同 store 路径时序）。**与本轮 NEMU 修复链 ①
   Sv39 walker 读 PTE 的 dcache↔直读一致性坑完全同源**。修 2 处：①`cache.c` 的 `dcache_write`
   写后补 `paddr_tohost_check_write(addr,len)`；②`paddr.c` 的 `paddr_tohost_check_write` 把
   `pmem_read` 换成 `dcache_peek_read`（dcache 一致视图，读到刚写入仍 dirty 的 tohost）。
   - **诊断诡异点**（值得记）：`set_nemu_state` 端连续读 `prev=END`，但 execute 循环端读 `RUNNING`，
     同一 `_Atomic int state` objdump 确认每次 `mov` 内存读、`xchg` 原子写——排除编译器缓存后，
     矛盾最终指向"store 根本没走 set END 的那条路径"（dcache 快速路径绕过 check）。**教训：原子变量
     读写值不一致时，先怀疑是否两条不同的写路径，而非编译器缓存**。

**基础设施**：
- 编译 `spike-diff` riscv64 ref-so：`make -C nemu/tools/spike-diff GUEST_ISA=riscv64`（复用
  已编译的 `repo/build/*.a`，只重链 wrapper）。`utils.h` 的 `NEMUState.state`（C11 `_Atomic int`）
  会让 C++ 的 difftest.cc 报 `'_Atomic' does not name a type`；修=`#ifdef __cplusplus` gate，
  C++ 侧 `std::atomic<int>`、C 侧 `_Atomic int`（ABI 兼容，difftest 只读结构布局）。
- runner `am-kernels/rv64dv/scripts/rv64dv-run.sh` + Makefile（`run`/`run-all`/`robustness`）
  + README + .gitignore。`riscv-dv/`+`venv/`(~278M)未入库，README 给重建步骤。

**验证**：`riscv_arithmetic_basic_test` difftest vs spike `HIT GOOD TRAP`（~4800 指令，修前跑满
max-insts）+ 全程零 mismatch；runner 端到端 1 PASS/0 FAIL。**回归**（dcache_write 每次 store 补
tohost check）：ACT4 priv/Sv 97/97 + I 51/51 + M 13/13 零回归（tohost 未启用时 `overlap` 检查
立即 return，Linux 场景零开销）。

## 边界

本轮闭合 NEMU 单机 ACT4 I/M/priv-Sv 全绿 + AM guest 在设备树统一图上跑通（cpu-tests 57/57 +
CoreMark）+ **rv64dv(riscv-dv) 引入并抓修 2 个 NEMU 准确性 bug**。
未闭合：**NPC 侧 difftest**——用户指示 NPC 有 bug，先把 NEMU 确立为可信金标准（rv64dv 已验证），
下一步接 NPC↔NEMU difftest。NEMU 当前为 Linux 设备图 config(riscv64, MSIZE=1GiB, serial 0x10000000)。
