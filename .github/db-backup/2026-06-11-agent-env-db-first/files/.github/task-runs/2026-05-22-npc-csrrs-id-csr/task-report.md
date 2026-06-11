# NPC CSRRS 与身份 CSR

## 任务

在 NPC 中实现/覆盖 `CSRRS` 指令，并让 `mvendorid` 读出 `ysyx` 的 ASCII 编码 `0x79737978`，`marchid` 读出学号 `ysyx_26010035` 数字部分的十进制整数值。

## RTL 推导摘要

### 需求

- `CSRRS rd, csr, rs1` 返回 CSR 旧值到 `rd`。
- `rs1=x0` 时只读 CSR，不产生写访问。
- `rs1!=x0` 时对可写 CSR 执行 `old | rs1` 写回。
- `mvendorid` 固定读出 `32'h7973_7978`。
- `marchid` 固定读出 `32'd26010035`。
- `mvendorid/marchid` 为只读 CSR，带写语义访问应触发 illegal。

### 协议规则

- `DecodeUnit` 已按 `funct3=010` 将 `CSRRS` 归入 Zicsr 指令，`NpcCore` 将 CSR 字段和前递后的 rs1 送入 `CsrFile`。
- `CsrFile` 组合返回 CSR old value 与 illegal；`csr_commit_i` 有效时才允许可写 CSR 改变状态。
- `CSRRS rd, csr, x0` 对只读 CSR 不触发写非法。

### 状态机

- 不新增状态机；CSR read/illegal 是组合路径。
- CSR 状态更新仍使用 `CsrFile` 原有时序优先级：memory trap > EX trap > MRET > CSR commit。

### 不变量

- `mvendorid/marchid` 没有状态寄存器，不会被 CSR 写改变。
- known CSR 包含 `mvendorid/marchid`，writable CSR 不包含它们。
- `CSRRS rs1=x0` 不写 CSR；`CSRRS rs1!=0` 写只读 CSR 必须 illegal。

### 数据通路骨架

- `define.v` 新增 CSR 地址宏。
- `CsrFile.csr_known()` 新增两个地址。
- `CsrFile.csr_rdata_o` 读 mux 新增两个只读常量分支。
- `tb_npc_core_mcycle` 使用 `CSRRS rd, csr, x0` 读 `mvendorid/marchid`，同时保留原 `CSRRS` 设置 `mcountinhibit.CY` 的覆盖。

## 验证

- `make -C npc/single/testbench RESULT_DIR=/tmp/npc-csrrs-id-tests run`: 22/22 PASS。
- `make -C npc/single lint`: PASS。
- `make -C npc/single -j14`: PASS。
- `AM_HOME=/home/lyg/PA/ysyx-workbench/abstract-machine make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc run`: 38/38 PASS。

## 备注

- `32'd26010035` 对应十六进制 `32'h018c_e1b3`，代码中保留十进制写法以贴合学号数字部分语义。
