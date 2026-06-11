# 2026-05-30 rv64 privileged SYSTEM baseline

## 请求

用户要求在 `rv64core` 中实现 Linux 启动需要的特权和非特权级别指令，并写复杂 testbench 观察是否正确。

## 结论

本轮完成的是第一阶段 M-mode/direct `mtvec` 控制面基线，不是完整 Linux 启动闭环。核心变化是把 RV64 OoO 的 `ECALL` 从实验壳退出改为架构 trap，并把 CSR、`MRET`、`WFI`、`SFENCE.VMA` 和 machine interrupt 接到精确 SYSTEM 边界。`EBREAK` 继续作为仿真退出。

## RTL 推导摘要

### 需求

- Linux 前置启动路径不能把 `ECALL` 当作仿真退出，必须进入特权 trap。
- CSR 指令需要返回旧 CSR 值，同时在精确提交点更新 CSR。
- `MRET/WFI/SFENCE.VMA` 不能再被当作 unsupported illegal 指令。
- timer/software/external interrupt 需要在指令边界进入 trap。

### 协议规则

- OoO 前端一次只允许一个 pending SYSTEM 事件。
- SYSTEM 事件先阻止后继 dispatch，再等待更老 ROB/IQ/retire drain。
- CSR 在 drain 后作为单 lane uop 派发，旧 CSR 值随 uop 写回 rd，CSR side effect 只在该 uop 提交时发生。
- `ECALL` 和 interrupt 不进入 ROB 提交，drain 后直接写 `mepc/mcause` 并 redirect 到 `mtvec`。
- `MRET` 在 drain 后更新 `mstatus`，redirect 到 `mepc`，并产生合成控制提交。
- `WFI/SFENCE.VMA` 在当前无 MMU 阶段作为合法序列化 no-op，产生合成控制提交。
- lane1 SYSTEM 允许 lane0 先入后端，再保存 lane1 为 pending SYSTEM，避免同包后继越过特权边界。

### 状态机与数据流

- `OooAluFetchCore` 持有 `pending_system_*` 状态，记录 PC、inst、next PC、CSR old value 和 interrupt cause。
- `CsrFile` 实例化在 OoO 前端，统一提供 CSR old value、illegal 判定、trap target、`mepc` 和 pending interrupt。
- CSR old value 通过 `OooAluFetchCore -> OooAluCoreSlice -> OooAluDecodeBackend -> OooIntBackend -> WBU` 写回 GPR。
- CSR 写操作的 rs1/zimm 值在 CSR commit 时从架构 GPR snapshot 取得，避免读取 rename 后端内部状态。
- 前端在 trap/return/serialized commit 后清空 fetch FIFO、outstanding fetch 和相关 pending 状态，随后从 `mtvec/mepc/next_pc` 继续取指。

### RTL 映射

- `npc/rv64/vsrc/include/define.v`: 新增 `SFENCE.VMA` decode 常量和 `CTRL_SFENCE_VMA_BIT`。
- `npc/rv64/vsrc/decode/DecodeUnit.v`: 识别合法 `SFENCE.VMA`。
- `npc/rv64/vsrc/ooo/OooAluFetchCore.v`: 接入 `CsrFile`、SYSTEM pending 状态、CSR 精确提交、`ECALL/MRET/WFI/SFENCE.VMA` 和 interrupt redirect。
- `npc/rv64/vsrc/ooo/OooAluDecodeBackend.v`: CSR uop 允许进入 ALU 后端，并携带 CSR old value。
- `npc/rv64/vsrc/ooo/OooAluCoreSlice.v`: 透传 CSR old value。
- `npc/rv64/vsrc/ooo/OooIntBackend.v`: CSR writeback 数据改为 CSR old value。
- `npc/rv64/vsrc/core/NpcCoreTop.v`: 接入 software/timer/external interrupt 输入。
- `npc/rv64/vsrc/filelist.mk`: RV64 OoO 默认源集纳入 `CsrFile`。
- `npc/rv64/testbench/tests/tb_ooo_priv_system.sv`: 新增复杂 SYSTEM/CSR/interrupt focused testbench。

## 验证

- `make -C npc/rv64/testbench TESTS=tb_ooo_priv_system RESULT_DIR=/tmp/rv64-ooo-priv-system run`: PASS。
- `make -C npc/sim BACKEND=rv64 lint`: PASS。
- `make -C npc/sim BACKEND=rv64 -j4`: PASS。存在 host `disasm.c` 的既有 `snprintf` 截断 warning，非本轮 RTL 问题。
- `AM_HOME=/home/lyg/PA/ysyx-workbench/abstract-machine make -C am-kernels/tests/cpu-tests ARCH=riscv64-npc run`: 全量 40/40 PASS。
- `git diff --check`: PASS。

## testbench 覆盖点

- lane0 普通 ALU + lane1 CSR 同包时，lane1 CSR 被作为 SYSTEM barrier 保存，lane0 先提交。
- CSR 指令写回旧值，随后 `csrrs` 能读到新 `mtvec/mcause/mepc`。
- `ECALL` 进入 `mtvec` handler，不触发仿真退出。
- handler 修改 `mepc` 后 `MRET` 返回 `mepc + 4`。
- `SFENCE.VMA` 和 `WFI` 为合法序列化 no-op，最终由 `EBREAK` 退出。
- timer interrupt 在 `mie.MTIE` 与 `mstatus.MIE` 打开后进入 trap，`mcause` 带 interrupt bit，`MRET` 返回被中断 PC。

## 已知限制

- 未实现完整 S-mode、`medeleg/mideleg` 委托路径、Sv39 页表/TLB 权限、A 扩展原子指令、PLIC/SBI。
- 旧 `tb_ooo_alu_fetch_core` 继承 RV32 focused 期望，仍包含旧 `ECALL` 仿真退出断言和若干 RV64 不适配断言，本轮不把它作为 RV64 特权控制面的验收门槛。
