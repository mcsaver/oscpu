# 规范：物理寄存器堆 OooPhysRegFile

> 模块：`vsrc/regread_bypass/OooPhysRegFile.v`。模板见 `../arch/SPEC-TEMPLATE.md`。
> 状态：已实现并验证；T3M 起五个读口全部 stored-only。

## 1. 目的与范围

统一整数 PRF，容量 PHY_REG_COUNT=64（`OOO_PHY_REG_ADDR_W`=6），实体接口为 5R2W：read0-3
服务 issue0/1 的 src1/src2，read8 服务 FP 簇 GPR 源，两个写口服务整数正式 writeback。
历史 read4-7/9 死读口已随消费端物理删除。T3M 与 IQ sticky 边界原子对齐：正式 WB 在 N 沿
写状态，dependent N+1 才读新值；不存在同拍 write-through。不含 FP（见 OooFpPhysRegFile）。

## 2. 接口与端口

- 读：`readN_addr_i -> readN_data_o`，组合读取已落账 `regs_q`；preg0 恒返回 0。
- 写：`write0/1_valid_i + write0/1_addr_i + write0/1_data_i`，时序写入所有正式 WB source。
- 无 bypass 端口；read0-3/read8 均不得直接消费 completion payload。
- 复位：`regs_q` 全 0（x0 物理寄存器恒 0）。
- 恢复：`recover_i` 时 preg1..31 载入已提交架构 GPR（`recover_gprs_i`），preg32..63 清零；
  rename map/free-list 必须同拍归位到恒等映射。

## 3. 写读时序与优先级

- 全部读口在 full write 的 N 沿前读取旧 `regs_q`，上升沿写入后于 N+1 读取新值。
- write1 优先于 write0；同地址双写时 write1 的后写值胜出。
- preg0 的任何写都忽略，任何读都返回 0。
- `rst > recover > write0/write1`；flush recover 不得被同拍 speculative WB 覆盖。

## 4. 不变量

- **PRF-I1 x0 恒 0**：任何对 preg0 的读返回 0，写无效。
- **PRF-I2 stored-only**：任一正式 write 同拍，read0-3/read8 均沿前旧、沿后新；
  `[PRF-INT-READ-STORED-ONLY]` 逐口看护。
- **PRF-I3 容量**：addr ∈ [0,63]，由 rename/free-list 保证不越界。
- **PRF-I4 单一真源**：full write 是 `regs_q` 唯一更新真源；读路径不得重建 completion
  payload mux 或第二份 operand state。

## 5. 关键路径

T3M 前 EX fast payload 经 read0-3 write-through 进入 ALU/控制长锥；T3M 删除该 ABI 后，PRF
前向路径从 `regs_q Q` 开始。Vivado OOC 的 PRF 本体约 3 逻辑级/logic 0.4ns；全芯片仍需
fresh 5ns STA 裁决，不能由 OOC 越级声明 200MHz。

## 6. 验证

- 模块 TB `tb_ooo_phys_reg_file` 覆盖五口 N/N+1、双写同址、64 位高半、x0；
  write-through 可编译 mutation 必须被杀死。
- 集成 `tb_ooo_int_issue_queue`/`tb_ooo_int_backend` 证明 IQ sticky 与 PRF 写入同沿原子发生；
  riscv-tests/AM/CoreMark 覆盖数据相关与恢复。

## 7. 变更记录

- 2026-06-28：逆向文档化（多读 2 写 / 写-读旁路 / write1>write0 / x0）。
- 2026-07-13：T3B 把 read0-3 收窄为 EX/MEM fast bypass；T3F 删除 read8 同拍旁路；
  T3G 再将 read0-3 fast 收紧为 EX-only，MEM 在 formal WB 后 N+1 读取。
- 2026-07-13 T3M：删除 read0-3 的 EX bypass 端口；全部五个读口只读 `regs_q`，合同见
  `ooo-ex-sticky-wakeup-barrier.md`。
