# NPC CSR File Refactor

## 任务

用户要求把 CSR 单独拉出来，避免继续集成在 `NpcCore.v` 中导致后续修改不方便。

## RTL 推导

- 需求：保持 `NpcCore` 外部接口、提交语义、异常行为不变，只把 CSR 状态与 CSR side effect 从核心大文件中拆出。
- 模块边界：`NpcCore` 向 `CsrFile` 提供 CSR 指令字段、前递后的 rs1、提交 fire、memory/EX trap、MRET 与 cycle enable；`CsrFile` 组合返回 CSR old value、illegal、trap target 与 `mepc`。
- 状态归属：`mstatus/mtvec/mscratch/mepc/mcause/mtval/mie/mip/mcycle/mcountinhibit` 迁入 `CsrFile`。
- 时序优先级：CSR side effect 保持原行为，按 memory trap > EX trap > MRET > CSR 指令写入更新。
- 计数器语义：保留上一轮 `mcycle/mcycleh/cycle/cycleh/mcountinhibit.CY` 语义，stall/cache miss 周期继续计入 `mcycle`，CSR 写 `mcycle/mcycleh` 覆盖同拍默认递增。

## 改动

- 新增 `npc/single/vsrc/CsrFile.v`：独立 machine CSR register file，包含 CSR 读改写、合法性判断、trap/MRET 更新、`mcycle` 计数。
- 精简 `npc/single/vsrc/NpcCore.v`：移除 CSR 寄存器和 helper function，实例化 `CsrFile` 并消费其输出。
- 更新 `npc/single/Makefile` 与 `npc/single/testbench/Makefile`：把 `CsrFile.v` 纳入 RTL 构建和核心相关 testbench 源列表。

## 验证

- `make -C npc/single/testbench RESULT_DIR=/tmp/npc-csrfile-refactor-tests2 run`: 22/22 PASS。
- `make -C npc/single lint`: PASS。
- `make -C npc/single -j14`: PASS。
- `AM_HOME=/home/lyg/PA/ysyx-workbench/abstract-machine make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc run`: 38/38 PASS。

## 备注

- 本轮只做 CSR 模块化，不扩展新的 CSR 权限模型或新的 counter CSR。
- 运行 testbench 会更新 `npc/single/testbench/build/*.vvp` 产物；这些属于本地构建输出。
