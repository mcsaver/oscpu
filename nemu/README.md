# NEMU

NEMU(NJU Emulator) is a simple but complete full-system emulator designed for teaching purpose.
Currently it supports x86, mips32, riscv32 and riscv64.
To build programs run above NEMU, refer to the [AM project](https://github.com/NJU-ProjectN/abstract-machine).

## Configuration policy

[`Kconfig`](./Kconfig) is the only Kconfig entry in NEMU. It contains choices that
change the build artifact, guest-visible ISA, platform ABI, or an observable
runtime capability. One-value implementation policy (the interpreter engine,
full-system mode, and internal trace predicates) lives in
[`include/nemu-config.h`](./include/nemu-config.h) instead of being exposed as a
menu option. Shared fixed device MMIO addresses have a separate single source of
truth in [`include/device/device_address.h`](./include/device/device_address.h);
changing a dead address entry in a defconfig must never appear to change the
machine map. An explicitly platform-selectable NEMU-only address (currently the
SD-card controller) remains a real Kconfig ABI choice.

The native artifact name follows that fixed policy as well: `ENGINE` is forced
to `interpreter` by the Makefile, so an environment or command-line override
cannot silently create a differently named artifact while Linux keeps running
an old `riscv64-nemu-interpreter` binary.

## RV64 指令语义与 decode cache

RV64 解释器按手册中的概念组织成一条单向数据流：

```text
raw instruction bits
  -> RvDecodedInstruction（手册 mnemonic、operands、immediate）
  -> rv_execute_decoded_instruction()
  -> architectural state
```

`inst/decode.c` 负责把 32-bit 编码翻译成上述体系结构描述，
`inst/compressed.c` 只负责把 16-bit RVC 编码翻译成同一种描述；它们不各自
拥有一套执行语义。`local-include/instruction.h` 中的 `RvOperation` 直接使用
手册 mnemonic 命名，因此执行层按 `ADDI`、`LW`、`MRET`、`C.JALR` 等操作
阅读，而不是再次解释 opcode/funct 字段。尚未拆分完内部 decoder 的扩展会
以显式 `*_ADAPTER` operation 标出迁移边界，不伪装成已经完成的手册语义。

`inst/decode_cache.c` 不是另一套 decode 或 executor。它只以
`PC + raw instruction` 为 key 保存完整的 `RvDecodedInstruction`，只提供
lookup/insert/flush；cache hit 和 miss 都进入 `inst/execute.c` 的同一个
`rv_execute_decoded_instruction()`。cache 文件不能读取或修改 GPR、CSR、PC
或 memory，也不能产生 trap；`fence.i` 由共享执行语义请求 flush。

这是固定的 RV64 解释器实现策略：`include/nemu-config.h` 定义
`NEMU_RV64_DECODE_CACHE=1` 和 `NEMU_RV64_DECODE_CACHE_ENTRIES=32768`，不再在
Kconfig/defconfig 中重复 enable、容量或 dispatch 选择。需要做正确性/性能
A/B 时，唯一运行期开关是 `NEMU_INTERPRETER_DECODE_CACHE=0`，它只跳过元数据
cache，不改变 guest ISA、异常或执行语义。

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
