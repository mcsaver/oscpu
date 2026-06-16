# RV64 OooIntBackend Bitmanip Helper Cleanup

## 背景

本轮继续按活动 RV64 RTL 的商业级语法/结构规范清理仿真式 lint waiver。目标文件为 `npc/rv64/vsrc/ooo/backend/OooIntBackend.v`。

旧 `rv32b_result()` helper 接收完整 `inst[31:0]`，但内部只使用 opcode、funct7/funct3 组合域、`inst[25:20]` shamt/imm，以及两个源操作数。rd/rs 字段不参与 B 扩展执行组合逻辑，因此只能用 `verilator lint_off/on UNUSEDSIGNAL` 包住函数输入。

## RTL 推导摘要

### 需求

- 删除 `OooIntBackend` 中 bitmanip helper 附近的局部 `UNUSEDSIGNAL` waiver。
- 保持 B 扩展 OP-IMM、OP-IMM-32、OP、OP-32 执行结果等价。
- 不改变 issue/forward/writeback 协议，不扩大本轮修改范围。

### 协议规则

- `bitmanip_result()` 是纯组合 helper，无状态、无 ready/valid。
- `CTRL_BITMANIP_BIT` 为 1 时，execute result 选择 bitmanip helper 输出。
- issue0 使用原始 PRF 读出的 `src1/src2`；issue1 必须继续使用 issue0 当拍执行结果 forward 后的 `issue1_src*_value_w`。
- 普通 ALU 的 word-op 截断、MulDiv ready/valid、LSU/WBU 仲裁路径不属于本 helper。

### 状态机

- 本轮不新增状态机。
- 不新增寄存器，不改变已有 issue、memory、muldiv、writeback FSM。

### 不变量

- helper 输入只能覆盖执行函数实际消费的 instruction fields。
- `funct10 = {inst[31:25], inst[14:12]}` 保持原 case 表的匹配位布局。
- `imm = inst[25:20]` 保持 immediate/shift amount 的 6-bit 语义，`imm5 = imm[4:0]`。
- OP-IMM-32 的 `{inst[31:26], funct3}` 由 `funct10[9:4]` 与 `funct10[2:0]` 推导，保留 `inst[25]` 在 `imm[5]` 中作为 shamt bit。
- 未匹配 bitmanip case 仍输出 0。

### 数据通路约束

- 调用点只切出 `issue*_inst_w[6:0]`、`{issue*_inst_w[31:25], issue*_inst_w[14:12]}`、`issue*_inst_w[25:20]`。
- 不传 `rd/rs1/rs2` 等执行 helper 不消费的字段。
- 不改 DecodeUnit 产生 `CTRL_BITMANIP_BIT` 的规则。
- 不改 testbench 行为，只复跑既有 focused tests。

## 变更

- `rv32b_result()` 重命名为 `bitmanip_result()`，名称更贴近 RV64 B extension helper。
- helper 入参从完整 `inst[31:0]` 收窄为：
  - `opcode[6:0]`
  - `funct10[9:0] = {inst[31:25], inst[14:12]}`
  - `imm[5:0] = inst[25:20]`
  - `src1/src2`
- 删除函数输入周围的 `verilator lint_off/on UNUSEDSIGNAL`。
- issue0/issue1 exec result 调用点同步只传实际消费字段。

## 验证

- `make -C npc/rv64/testbench /tmp/npc-ooo-intbackend-bitmanip-test/logs/tb_ooo_int_backend.log /tmp/npc-ooo-intbackend-bitmanip-test/logs/tb_ooo_alu_decode_backend.log /tmp/npc-ooo-intbackend-bitmanip-test/logs/tb_ooo_alu_fetch_core.log`：3/3 PASS。
- `make -C npc/rv64 lint`：PASS。
- `make -C npc/rv64 -j2`：PASS。
- `make -C Linux/tools smoke-branch-raw smoke-muldiv smoke-sret-user-sv39-halfword smoke-fp-loadstore`：全部 GOOD TRAP。
- `rg -n "UNUSEDSIGNAL|rv32b_result" npc/rv64/vsrc/ooo/backend/OooIntBackend.v`：无命中。
- `git diff --check -- npc/rv64/vsrc/ooo/backend/OooIntBackend.v`：PASS。

## 补充检查

- 运行不关闭 `UNUSEDSIGNAL` 的 `OooIntBackend` 局部 Verilator lint 时，当前工作树仍暴露既有 unused：
  - `issue0_ctrl_w[45:44]`、`issue1_ctrl_w[45:44]`
  - `load_branch_fast_valid_w`、`load_branch_fast_rsp_w`、`load_branch_fast_pc_match_w`
  - `is_fp_load_inst()` / `is_fp_store_inst()` 一类 helper 的宽输入位
  - `OooMulDivUnit` 内部 helper 的宽输入/宽积寄存器未消费位
- 上述告警不是本轮 bitmanip helper 的 `inst` 宽输入问题，后续应作为 `OooIntBackend/OooMulDivUnit` 的下一批商业 lint 收敛项单独处理。
- `make -C am-kernels/tests/cpu-tests ARCH=riscv64-npc ALL=bitmanip run` 未形成 RTL 证据，失败原因是测试工程入口报 `Makefile.bitmanip:3: /Makefile: No such file or directory`。

## 剩余边界

活动 RTL 排除 `legacy/` 后剩余显式 waiver：

- `OooAluDecodeBackend.v`：`UNUSEDSIGNAL`、`UNOPTFLAT`
- `OooAluFetchCore.v`：三段 `UNOPTFLAT`

下一轮建议先处理 `OooAluDecodeBackend` 的 `UNUSEDSIGNAL`，风险低于 `UNOPTFLAT` 组合环类问题。
