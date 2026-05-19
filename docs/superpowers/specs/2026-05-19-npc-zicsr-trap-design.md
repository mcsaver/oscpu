# NPC Zicsr Trap Design

## 背景

当前 `npc/single` 已有一版 RV32I 非流水线多周期核心和 NEMU 风格 Verilator/DPI 宿主环境。核心能运行基础 AM 程序，并用 `ebreak + a0` 作为退出协议；但 `ecall` 仍在 RTL 内直接进入 `HALT`，`SYSTEM` 指令只覆盖 `ecall/ebreak`，缺少 Zicsr、`mret` 和最小 machine CSR/trap 闭环。

NEMU 当前参考路径已经实现 RV32I + Zicsr 的核心语义：`csrrw/csrrs/csrrc/csrrwi/csrrsi/csrrci`、`ecall -> mtvec`、`mret -> mepc`、`wfi` no-op，以及 `mstatus/mepc/mcause/mtval/mtvec/mscratch/mie/mip/misa/mhartid` 的最小 CSR 状态。NPC 第一阶段目标是先对齐这条参考语义，再继续做 RV32M 和流水线。

## 目标

- 保留现有 `NpcCore` 单在途多周期结构，不在本阶段引入流水线。
- 在 NPC RTL 中新增最小 machine CSR block 和 trap controller 行为。
- 让 `ecall` 进入 trap handler，而不是直接让仿真器退出。
- 保留 `ebreak + a0` 作为 AM/NPC `halt()` 的退出协议，避免破坏现有 hello/cpu-tests 路径。
- 支持 Zicsr 基础 CSR 指令和 `mret/wfi`。
- 补齐 `abstract-machine/am/src/riscv/npc/cte.c` 与 `trap.S` 的上下文保存、恢复、`kcontext()` 路径。
- 验证 `ecall -> mtvec -> __am_asm_trap -> __am_irq_handle -> mret` 在 NPC 上真实闭环。

## 非目标

- 不在本阶段实现 RV32M、B、C 扩展。
- 不在本阶段把 `NpcCore` 改成流水线。
- 不实现 S/U 模式、页表、PMP、delegation、真实外部中断或 timer interrupt。
- 不实现 cache/BPU；NEMU 的 cache/BPU 当前只是性能模型，不是 NPC 第一阶段功能前置。
- 不改变 NPC 宿主侧 MMIO 地址图，除非验证发现 CSR/trap 闭环必须补最小日志或观测口。

## 设计结论

采用“先补 machine-level 功能闭环，再做结构优化”的路线。原因是当前 NPC 已经能跑基础 RV32I 程序，最缺的是特权入口和 CTE 语义；如果现在直接流水线化，会把已有缺口和流水线冒险混在一起，导致验证定位成本升高。

## RTL 架构

### CSR 状态

新增 `CSRFile` 或在 `NpcCore` 内等价收口一组 CSR 状态。推荐独立模块，便于后续流水线阶段复用。

第一阶段 CSR：

- `mstatus`: 支持 `MIE`、`MPIE`、`MPP` 的读写和 trap/mret 更新。
- `mtvec`: 可写；第一阶段只按 Direct 模式使用 `BASE`。
- `mscratch`: 可读写。
- `mepc`: 可读写；RV32I-only 下写入时清低 2 位。
- `mcause`: 可读写。
- `mtval`: 可读写；异常入口写 fault address 或非法指令值。
- `mie/mip`: 可读写或读写保留，但当前不触发真实中断。
- `misa`: 只读，按 NEMU 当前策略返回 RV32I 能力位；`Zicsr` 不在 `misa` 中单独声明，不声明 M/B/C。
- `mhartid`: 只读 0。

### Decode 扩展

`DecodeUnit` 扩展 `SYSTEM` 控制字段，覆盖：

- CSR register form: `csrrw/csrrs/csrrc`
- CSR immediate form: `csrrwi/csrrsi/csrrci`
- privileged/system: `ecall/ebreak/mret/wfi`

控制包需要新增或等价表达这些信息：

- `csr_en`
- `csr_addr[11:0]`
- `csr_op`
- `csr_imm_mode`
- `csr_zimm[4:0]`
- `mret`
- `wfi`
- `trap_enter`

### Execute/Writeback

CSR 指令走现有单在途状态机即可，不需要新握手：

1. `DECODE` 锁存 CSR 控制、`rs1`、`rd`。
2. `EXEC` 读取旧 CSR，计算新 CSR。
3. `WB` 写回旧 CSR 到 `rd`，同时在需要时写 CSR。

`csrrs/csrrc` 在 `rs1 == x0` 时只读不写；立即数版本在 `zimm == 0` 时同理。`csrrw/csrrwi` 总是写 CSR。写 `x0` 仍由最终提交屏蔽。

### Trap Controller

本阶段 trap controller 可以集成在 `NpcCore` 状态机中，但逻辑必须集中，不能分散到 IFU/LSU/WBU 各自改 PC。

同步异常入口行为：

1. `mepc <- 当前异常指令 pc`
2. `mcause <- cause`
3. `mtval <- fault address / illegal inst / 0`
4. `mstatus.MPIE <- mstatus.MIE`
5. `mstatus.MIE <- 0`
6. `mstatus.MPP <- M`
7. `pc <- mtvec.BASE`
8. 返回 `FETCH_REQ` 继续执行 handler

`mret` 行为：

1. `pc <- mepc`
2. `mstatus.MIE <- mstatus.MPIE`
3. `mstatus.MPIE <- 1`
4. `mstatus.MPP <- 0`
5. 返回 `FETCH_REQ`

`wfi` 作为合法 no-op，顺序进入下一条。

`ebreak` 继续进入 `HALT` 并导出 `exit_code=a0`，这是 AM/NPC 当前 `halt()` 协议。

## 协议和不变量

- 单在途不变量：任意周期最多一条指令处于 decode/execute/mem/writeback 链路中。
- 提交不变量：发生 trap 的指令不产生普通 `commit_valid_o` 写回提交。
- CSR 原子不变量：CSR 指令读旧值、计算新值、写 `rd` 与写 CSR 对同一条指令保持原子语义；当前单在途结构天然保证无并发 CSR 冲突。
- x0 不变量：无论 CSR 指令还是普通指令，最终写 `x0` 都被屏蔽。
- trap 精确性不变量：`mepc` 指向导致 trap 的当前指令 PC，而不是 `pc+4` 或目标地址。
- `mret` 不变量：`mret` 不写 GPR，且下一条取指地址来自 `mepc`。
- `ebreak` 退出不变量：`ebreak` 不跳 `mtvec`，仍作为仿真退出协议，避免破坏现有 AM `halt()`。

## AM 侧设计

`abstract-machine/am/src/riscv/npc/cte.c` 需要对齐 NEMU 平台已完成的 CTE 语义：

- `cte_init()` 写 `mtvec=__am_asm_trap`。
- `__am_irq_handle()` 将 `mcause=11` 且 `a7=-1` 的 `ecall` 识别为 `EVENT_YIELD`。
- `kcontext()` 在任务栈顶构造初始 `Context`，设置 `mepc=entry`、`a0=arg`、返回地址兜底 panic。
- `yield()` 保持 `ecall`。

`trap.S` 需要确保：

- 保存通用寄存器、`mcause/mstatus/mepc`，布局与 `Context` 对齐。
- 调用 `__am_irq_handle(Context *)` 后使用返回的 `Context *` 作为恢复基址。
- 恢复 `mstatus/mepc` 与 GPR 后执行 `mret`。

## 验证计划

第一阶段最小验证：

- `make -C npc/single lint`
- `make -C npc/single`
- `make -C am-kernels/kernels/hello ARCH=riscv32-npc run`
- `make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc ALL=add run`
- `timeout 3s make -C am-kernels/tests/am-tests ARCH=riscv32-npc c mainargs=i NPC_RUN_ARGS='--max-cycles 0 --no-progress'`
- `timeout 3s make -C am-kernels/kernels/yield-os ARCH=riscv32-npc c NPC_RUN_ARGS='--max-cycles 0 --no-progress'`

若 `am-tests mainargs=i` 或 `yield-os` 因 NPC 性能超时，改用更短的专用 smoke 镜像验证：

- 设置 `mtvec`
- 执行 `ecall`
- handler 修改内存标志或寄存器
- 执行 `mret`
- 最后 `ebreak` good trap

## 后续阶段

第二阶段：在第一阶段验证稳定后，按 NEMU 参考语义补 RV32M。重点是 `mul/mulh/mulhsu/mulhu/div/divu/rem/remu` 的边界行为，尤其除 0 和 `INT_MIN / -1`。

第三阶段：在功能边界稳定后再流水线化。推荐从现有 `NpcCore` 抽出 IF/ID/EX/MEM/WB pipeline register、hazard unit、forwarding 和 flush 控制，而不是在 CSR/trap 仍缺失时直接推翻架构。
