# RV64 ImmGen 端口收窄与 waiver 清理

## 目标

继续按商业 ASIC RTL 风格清理 RV64 活动 RTL 中的端口过宽和 lint waiver。本轮聚焦：

- `npc/rv64/vsrc/decode/ImmGen.v`
- `npc/rv64/vsrc/decode/DecodeStage.v`
- `npc/rv64/testbench/tests/tb_immgen.sv`

目标是删除 `ImmGen` 中因为 opcode 低 7 位未使用而产生的 `UNUSED` waiver，让立即数生成器的输入边界准确表达其硬件职责。

## RTL 推导

### 需求

`ImmGen` 的功能目标是根据 `imm_type_i` 组合生成 RV64 立即数，包括 I/S/B/U/J 五类拼接和符号扩展。opcode、funct、rs/rd 等译码字段属于 `DecodeUnit` 职责，不应长期穿过 `ImmGen`。

旧实现让 `ImmGen` 接收完整 `inst_i[31:0]`，但只使用 `inst_i[31:7]`。为了压低 `inst_i[6:0]` 的 unused warning，文件中增加了 `opcode_bits_unused_w` 和 `verilator lint_off UNUSED`。这类“假消费未用位”的写法不利于模块接口审查，也会模糊 DecodeUnit 与 ImmGen 的职责边界。

### 协议规则

- `ImmGen` 是纯组合模块，无 valid/ready、无内部寄存器、无复位。
- `DecodeStage` 同拍把完整指令送入 `DecodeUnit`，由 `DecodeUnit` 产出控制包中的 `imm_type`。
- `DecodeStage` 同拍把 `inst_i[31:7]` 送入 `ImmGen`，`ImmGen` 按 `imm_type` 返回 `imm_o`。
- 低 7-bit opcode 不参与立即数结果；opcode 对立即数类型的影响只通过 `DecodeUnit -> imm_type` 体现。

### 状态机/不变量

- 无状态机；任意输入变化后组合输出在同一组合求值中更新。
- 不变量 1：`IMM_TYPE_I` 使用 `{inst[31], inst[31:20]}` 完成 12-bit sign-extension。
- 不变量 2：`IMM_TYPE_S` 使用 `{inst[31], inst[31:25], inst[11:7]}` 完成 12-bit sign-extension。
- 不变量 3：`IMM_TYPE_B` 使用 `{inst[31], inst[7], inst[30:25], inst[11:8], 1'b0}` 完成 13-bit branch offset sign-extension。
- 不变量 4：`IMM_TYPE_U` 使用 `{inst[31:12], 12'b0}` 并扩展到 XLEN。
- 不变量 5：`IMM_TYPE_J` 使用 `{inst[31], inst[19:12], inst[20], inst[30:21], 1'b0}` 完成 21-bit jump offset sign-extension。
- 不变量 6：default/`IMM_TYPE_X` 输出 0。
- 不变量 7：`inst[6:0]` 改变不能直接改变 `ImmGen` 输出；若 opcode 改变导致立即数类型变化，必须由 `DecodeUnit` 显式改变 `imm_type`。

### 数据通路约束

- `ImmGen` 端口从 `input [31:0] inst_i` 收窄为 `input [31:7] inst_imm_i`。
- `DecodeStage` 连接改为 `.inst_imm_i(inst_i[31:7])`。
- `tb_immgen` 直接实例化时同样传 `.inst_imm_i(inst[31:7])`。
- 不新增寄存器、不改变 `ctrl_o` 编码、不改变 OoO backend/front-end 任何握手或 filelist。

## 代码改动

- `ImmGen.v` 删除 `opcode_bits_unused_w` 与 `UNUSED` waiver。
- `ImmGen.v` 内部所有立即数字段引用改为 `inst_imm_i[...]`。
- `DecodeStage.v` 与 `tb_immgen.sv` 更新实例化端口名和切片。

## 验证

- `verilator --lint-only -Wall -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC +incdir+./npc/rv64/vsrc/include --top-module ImmGen npc/rv64/vsrc/decode/ImmGen.v`: PASS
- `make -C npc/rv64/testbench TESTS="tb_immgen tb_decode_stage" RESULT_TIMESTAMP=20260603-immgen-port-cleanup-focused run`: PASS 2/2
- `make -C npc/rv64/testbench TESTS="tb_ooo_alu_decode_backend tb_ooo_int_backend tb_ooo_alu_fetch_core" RESULT_TIMESTAMP=20260603-immgen-port-cleanup-ooo run`: PASS 3/3
- `make -C npc/rv64 lint`: PASS
- `make -C npc/rv64 -j2`: PASS
- `make -C Linux/tools smoke-jal-link smoke-branch-raw smoke-muldiv smoke-sret-user-sv39`: GOOD TRAP
  - `smoke-jal-link`: cycles=41, commits=16
  - `smoke-branch-raw`: cycles=188448, commits=122893
  - `smoke-muldiv`: cycles=634, commits=88
  - `smoke-sret-user-sv39`: cycles=287, commits=107
- `rg -n "lint_off|lint_on|UNUSED|UNOPT|BLKSEQ" npc/rv64/vsrc/decode/ImmGen.v npc/rv64/vsrc/decode/DecodeStage.v`: 无命中
- Focused `git diff --check` on本轮触及文件: PASS

## 边界

- 本轮只收敛立即数模块接口，不改变 decode 控制包、RVC 解压、CSR/FP/LSU/branch 语义。
- `npc/rv64/vsrc` 活动路径仍存在其它 waiver：`CsrFile`/`OooRvcDecompressor`/`OooAluDecodeBackend`/`OooIntBackend` 的 `UNUSEDSIGNAL`，以及 `OooAluFetchCore`/`OooAluDecodeBackend` 的 `UNOPTFLAT`。
- 后续若继续小步 lint 收敛，优先处理能通过端口收窄或 helper 入参收窄表达真实硬件边界的 waiver，避免只加无意义的 dummy unused 聚合。
