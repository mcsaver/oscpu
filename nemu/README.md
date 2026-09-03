# NEMU

NEMU(NJU Emulator) is a simple but complete full-system emulator designed for teaching purpose.
Currently it supports x86, mips32, riscv32 and riscv64.
To build programs run above NEMU, refer to the [AM project](https://github.com/NJU-ProjectN/abstract-machine).

## Configuration policy

[`Kconfig`](./Kconfig) is the only Kconfig entry in NEMU. It contains choices that
change the build artifact, guest-visible ISA, platform ABI, or an observable
runtime capability. One-value implementation policy (the interpreter engine,
full-system mode, internal trace predicates, host monotonic clock, runtime
checks, device-poll granularity, and the virtio-blk completion pending flag) lives in
[`include/nemu-config.h`](./include/nemu-config.h) instead of being exposed as a
menu option. Guest-visible machine selection remains a real Kconfig decision,
but each selected machine owns a fixed address contract: the generic map lives
in [`include/platform/generic-map.h`](./include/platform/generic-map.h), while
the NEMU-side mirror of the external ysyxSoC contract lives in
[`include/platform/ysyxsoc-map.h`](./include/platform/ysyxsoc-map.h).
[`include/device/device_address.h`](./include/device/device_address.h) is only a
compatibility naming layer for existing generic `DEV_*` consumers; it is not a
second address source.

The native artifact name follows that fixed policy as well: `ENGINE` is forced
to `interpreter` by the Makefile, so an environment or command-line override
cannot silently create a differently named artifact while Linux keeps running
an old `riscv64-nemu-interpreter` binary.

## Platform profiles and physical-address ownership

`CONFIG_SOC_SIM` selects a complete ysyxSoC platform profile; it is not a
priority hint layered over generic IOMap devices.  The two profiles assign the
overlapping apertures different device semantics:

| Address aperture | generic profile | ysyxSoC profile |
| --- | --- | --- |
| `0x02000000..0x0200ffff` | RISC-V CLINT | unmapped |
| `0x0c000000..0x0effffff` | RISC-V PLIC | unmapped |
| `0x0f000000..0x0f001fff` | RISC-V PLIC aperture | ysyxSoC SRAM |
| `0x0f002000..0x0fffffff` | RISC-V PLIC aperture | unmapped |
| `0x10000000..0x10000fff` | generic 16550 UART | ysyxSoC UART |
| `0x10001000..0x10001fff` | virtio-blk | ysyxSoC SPI |
| `0x10002000..0x10002fff` | virtio-rng | ysyxSoC GPIO owns only `0x10002000..0x1000200f` |
| primary memory | `CONFIG_MBASE..CONFIG_MBASE + CONFIG_MSIZE - 1` (default base `0x80000000`) | fixed PSRAM `0x80000000..0x803fffff` |

Consequently a SOC build does not compile or initialize the generic serial,
timer, keyboard, VGA, audio, block, virtio RNG/net, or SD-card providers.  The
Goldfish RTC is also generic-only because its alarm is delivered through the
generic PLIC.  The non-overlapping syscon may remain as an explicit NEMU service
extension when selected by Kconfig; it is not presented as a native ysyxSoC
device.  Kconfig expresses this guest ABI choice; `include/nemu-config.h`
repeats the impossible combinations as compile-time invariants for stale or
hand-written generated configurations.

The external ysyxSoC contains neither a CLINT nor a PLIC.  Its APB UART wrapper
does not export the UART interrupt output, and the full-SoC top level ties the
CPU external-interrupt input low.  The SOC profile therefore compiles out both
controller apertures and all PLIC injection paths; UART IER/IIR state remains
modelled, but it has no CPU interrupt route.  NEMU still advances an internal
instruction-time counter for the architectural `time/timeh` CSR.  Machine info
reports that counter separately from `time.clint.enabled=0`, so an implementation
detail cannot masquerade as a physical CLINT.  Software that expects the older
`0x0200bff8` CLINT-like simulator extension requires a distinct platform or an
explicit future service extension; it is not part of the ysyxSoC contract.

`src/memory/soc.c` is the executable ysyxSoC address manual.  One enumerable
region table describes each region's name, base, size, memory/MMIO kind,
read-only property, DiffTest policy, and backend.  Physical reads, writes,
DiffTest copies, machine-info output, and cross-layer IOMap overlap rejection
all consume that same table.  Registering any generic IOMap that intersects a
SOC-owned region is an initialization error; decoder order is never used to
choose a winner between two owners.  The generic profile applies the same
overlap rule to its fixed CLINT and PLIC apertures.

In the SOC defconfig, NEMU's primary-memory allocation is exactly the 4 MiB
PSRAM region.  It is listed in the same platform manifest but marked internally
as PMEM-backed, so there is one guest-visible region and one byte backing rather
than a hidden 128 MiB generic RAM plus a duplicate PSRAM model.
The reset vector is independently fixed at the MROM base `0x20000000`; built-in
and `-i` images are loaded through the selected physical region rather than
assuming that every boot image belongs in primary memory.  File loading and
DiffTest copies accept SRAM/MROM/SDRAM (or the PMEM-backed PSRAM) but reject
SPI/GPIO/PS2/VGA register windows.  Every accepted `--load` span is also copied
from the DUT's final physical-memory view into an enabled DiffTest reference, so
multi-image boot state cannot exist on the DUT alone.  This native/reference
platform model is not offered when NEMU itself is built as an Abstract-Machine
application.

## RV64 指令语义与 decode cache

RV64 解释器按手册中的概念组织成一条单向数据流：

```text
raw instruction bits
  -> RvDecodedInstruction（手册 mnemonic、operands、immediate）
  -> rv_execute_decoded_instruction()
  -> architectural state
```

`inst/decode.c` 是编码到语义描述符的唯一总入口：它认领整个 32-bit opcode
空间，并把 SYSTEM、A、F/D 等交给对应的共享纯 decoder；
`inst/compressed.c` 只把 16-bit RVC 编码翻译成同一种描述。二者都不提交
GPR/CSR/PC/memory。`local-include/instruction.h` 中的 `RvOperation` 直接使用
手册 mnemonic 命名，因此执行层按 `ADDI`、`MULH`、`REV8`、`LW`、`MRET`、
`C.JALR` 等操作阅读，而不是再次解释 opcode/funct 字段。保留编码、未实现
编码和配置关闭的扩展都保持 `ILLEGAL` descriptor，并由唯一执行入口统一
产生 Illegal Instruction；不存在 legacy decoder/executor fallback。

`inst/decode_cache.c` 不是另一套 decode 或 executor。它只把已经由
`decode.c` 得到的完整 `RvDecodedInstruction` 做 memoization：direct-mapped
索引取 `(PC >> 1) & (entries - 1)`，命中条件同时比较完整 PC 与规范化原始
指令（RVC 比较低 16 位，普通指令比较 32 位），并只提供
lookup/insert/flush。非法 descriptor 不入 cache；cache hit 和 miss 都进入
`inst/execute.c` 的同一个 `rv_execute_decoded_instruction()`。cache 文件不能
读取或修改 GPR、CSR、PC 或 memory，也不能产生 trap；`fence.i` 由共享执行
语义请求 flush。

这是固定的 RV64 解释器实现策略：`include/nemu-config.h` 定义
`NEMU_RV64_DECODE_CACHE=1` 和 `NEMU_RV64_DECODE_CACHE_ENTRIES=32768`，不再在
Kconfig/defconfig 中重复 enable、容量或 dispatch 选择。需要做正确性/性能
A/B 时，唯一运行期开关是 `NEMU_INTERPRETER_DECODE_CACHE=0`，它只跳过元数据
cache，不改变 guest ISA、异常或执行语义。

## syscon reset 寄存器语义

`src/device/syscon.c` 把 `0x00100000` 的 offset 0 描述为唯一一个自然对齐的
32-bit read/write 控制字；byte、halfword、doubleword、未对齐访问和其余
4 KiB aperture hole 都不是合法寄存器事务。普通值会锁存并可读回，写入
`0x5555` 触发 poweroff，写入 `0x7777` 触发 reboot，低 16 位为 `0x3333`
的值携带 AM test-finisher 失败码。

这里不能把控制字简化成 write-only 端口：标准 OpenSBI
`syscon-poweroff`/`syscon-reboot` 用 `regmap_update_bits()` 实现 device-tree 的
mask/value binding，真实总线顺序是 read current word、merge mask/value、
write new word。AM 回归 `syscon-reset-manual` 直接执行同型 read-modify-write；
Linux `check-nemu-systemd-guest` 还要求 systemd poweroff、Linux SBI SRST、
OpenSBI syscon write 与 NEMU GOOD TRAP 依次且各出现一次。

The main features of NEMU include
* a small monitor with a simple debugger
  * single step
  * register/memory examination
  * expression evaluation without the support of symbols
  * watch point
  * differential testing with reference design (e.g. QEMU)
  * snapshot
* CPU core with support of most common used instructions
  * x86
    * real mode is not supported
    * x87 floating point instructions are not supported
  * mips32
    * CP1 floating point instructions are not supported
  * riscv32
    * RV32I/E with configurable M/A/F/D/B/C extensions
  * riscv64
    * RV64I with configurable M/A/F/D/B/C extensions and privileged system support
* memory
* paging
  * TLB is optional (but necessary for mips32)
  * protection is not supported
* interrupt and exception
  * protection is not supported
* 5 devices
  * serial, timer, keyboard, VGA, audio
  * most of them are simplified and unprogrammable
* 2 types of I/O
  * port-mapped I/O and memory-mapped I/O
