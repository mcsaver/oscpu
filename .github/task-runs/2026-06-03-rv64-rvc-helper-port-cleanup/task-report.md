# RV64 RVC Helper Port Cleanup

## 背景

本轮继续清理活动 RV64 RTL 中的仿真式 lint waiver。目标文件为 `npc/rv64/vsrc/ooo/frontend/OooRvcDecompressor.v`。

旧实现把压缩指令解压器的大段 helper 函数包在 `verilator lint_off/on UNUSEDSIGNAL` 内。根因不是解压行为本身需要 unused，而是多个 helper 接收完整 `inst[15:0]`，实际只使用 RVC 格式中的部分字段；`enc_b/enc_j` 也接收包含 bit0 的立即数，但 RISC-V B/J 指令编码不携带对齐 bit0。

## RTL 推导摘要

### 需求

- 删除 `OooRvcDecompressor` 的整段 `UNUSEDSIGNAL` waiver。
- 保持 16-bit RVC 半字到 32-bit 标准指令展开结果等价。
- 不扩展 RVC ISA 覆盖，不改变非法/保留压缩编码输出 0 的既有策略。

### 协议规则

- `OooRvcDecompressor` 是纯组合模块，无时钟、复位或 ready/valid。
- `inst_i` 同拍决定 `inst_o`。
- 上游 `OooAluFetchCore` 负责半字 packet 选择、压缩/非压缩指令拼接、fetch FIFO、trap/flush；本模块只负责 RVC decode table。
- B/J 类立即数 bit0 是对齐隐含位，不编码到 32-bit 指令里。

### 状态机

- 无状态机。
- 本轮不新增寄存器或控制状态。

### 不变量

- 所有 helper 入参必须只覆盖该 helper 实际消费的 RVC 字段。
- `enc_b` 只消费 `imm[12:1]`，`enc_j` 只消费 `imm[20:1]`。
- 既有解压 case 的 opcode、funct、rd/rs、立即数 bit layout 不变。
- 未匹配或未支持的压缩编码仍保持 `decompress_rvc = 32'h0`。

### 数据通路约束

- 保留原 `decompress_rvc()` case 表结构。
- 将 `rvc_rdp/rvc_rs1p/rvc_rs2p/rvc_imm_* /rvc_shamt` 的完整 `inst` 入参改为精确字段切片。
- 将调用点显式传入 `inst[10:7]`、`inst[12:11]`、`inst[6:2]` 等格式字段。
- 不改变 `OooAluFetchCore` 实例化、不改 filelist、不改 testbench。

## 变更

- 删除 `OooRvcDecompressor.v` 的 `verilator lint_off/on UNUSEDSIGNAL`。
- `enc_b` 入参从 `imm[12:0]` 收窄为 `imm[12:1]`。
- `enc_j` 入参从 `imm[20:0]` 收窄为 `imm[20:1]`。
- RVC register/imm/shamt helper 入参从完整 `inst[15:0]` 收窄为实际字段。
- `decompress_rvc()` 调用点同步传入字段切片。

## 验证

- `verilator --lint-only -Wall -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC +incdir+./npc/rv64/vsrc/include --top-module OooRvcDecompressor npc/rv64/vsrc/ooo/frontend/OooRvcDecompressor.v`：PASS。
- `make -C npc/rv64/testbench TESTS="tb_ooo_alu_fetch_core tb_ooo_fetch_trap_gate tb_ooo_sv39_boot" RESULT_TIMESTAMP=20260603-rvc-helper-port-cleanup run`：3/3 PASS。
- `make -C npc/rv64 lint`：PASS。
- `make -C npc/rv64 -j2`：PASS。
- `make -C Linux/tools smoke-branch-raw smoke-sret-user-sv39-halfword smoke-fp-loadstore smoke-fp-fcsr smoke-fp-fmv-fclass`：全部 GOOD TRAP。
- `rg -n "lint_off|lint_on|UNUSED|UNOPT|BLKSEQ" npc/rv64/vsrc/ooo/frontend/OooRvcDecompressor.v`：无命中。
- `git diff --check -- npc/rv64/vsrc/ooo/frontend/OooRvcDecompressor.v`：PASS。

## 剩余边界

活动 RTL 排除 `legacy/` 后剩余 waiver：

- `OooAluDecodeBackend.v`：`UNUSEDSIGNAL`、`UNOPTFLAT`
- `OooIntBackend.v`：`UNUSEDSIGNAL`
- `OooAluFetchCore.v`：多处 `UNOPTFLAT`

下一轮可优先处理 `OooIntBackend` 的局部 `UNUSEDSIGNAL`，风险小于 `UNOPTFLAT` 组合环类问题。
