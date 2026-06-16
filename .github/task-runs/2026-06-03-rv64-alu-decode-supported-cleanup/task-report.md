# RV64 OooAluDecodeBackend Supported Gate Cleanup

## 背景

本轮继续清理活动 RV64 RTL 中的仿真式 lint waiver。目标文件为 `npc/rv64/vsrc/ooo/backend/OooAluDecodeBackend.v`。

旧 `ctrl_supported()` helper 接收完整 `CTRL_BUS`，但它的职责只是 decode-to-backend 的支持性门控：判断当前 uop 是否可以进入 `OooIntBackend`。函数实际只检查 valid、illegal、need_exec、system、csr、mret、sret、wfi 和 sfence.vma。其余控制位会在后端真实消费，不应由该 helper 用宽输入方式伪消费。

## RTL 推导摘要

### 需求

- 删除 `OooAluDecodeBackend` 中 `ctrl_supported()` 附近的 `UNUSEDSIGNAL` waiver。
- 保持 dispatch0/dispatch1 的 supported/unsupported 行为等价。
- 保持完整 decode 控制包继续传给 `OooIntBackend`。
- 不处理本文件现存 `UNOPTFLAT`，避免把 ready/valid 组合依赖问题混入宽输入清理。

### 协议规则

- `OooAluDecodeBackend` 是 `DecodeStage` 与 `OooIntBackend` 之间的组合/握手适配层。
- `dispatch*_valid_i && dispatch*_supported_w` 才能作为 backend dispatch valid。
- `dispatch*_ready_o` 必须同时满足 supported 和 backend ready。
- `dispatch*_unsupported_o` 在上游 valid 且 supported 为 0 时拉高。
- CSR 旧值通过 `backend_dispatch*_imm_w` 复用 imm payload 进入后端。

### 状态机

- 本模块本轮不新增状态机。
- DecodeStage 纯组合，supported helper 纯组合。
- OooIntBackend 内部 issue/ROB/LSU/MulDiv 状态机保持不变。

### 不变量

- `ILLEGAL=1` 的 uop 不进入后端，否则可能破坏精确 trap 边界。
- `NEED_EXEC=0` 的 uop 不进入后端，否则会制造无意义 ROB/issue 项。
- `SYSTEM=1 && CSR=0` 的 uop 不进入普通后端；xRET/WFI/SFENCE 继续由前端/特权序列化路径处理。
- `CSR=1` 且合法需要执行的 SYSTEM uop 仍允许进入后端，以便写回 CSR old value。
- supported helper 只能消费它用于判定的控制位，不伪消费整条 control bus。

### 数据通路约束

- `ctrl_supported()` 入参收窄为 9 个 1-bit 判定位：
  - `ctrl_valid`
  - `ctrl_illegal`
  - `ctrl_need_exec`
  - `ctrl_system`
  - `ctrl_csr`
  - `ctrl_mret`
  - `ctrl_sret`
  - `ctrl_wfi`
  - `ctrl_sfence_vma`
- dispatch0/dispatch1 调用点分别从 `decode*_ctrl_w` 显式切出上述位。
- `decode*_ctrl_w` 原样传入 `OooIntBackend.dispatch*_ctrl_i`，后端对 ALU/branch/load/store/MulDiv/bitmanip/AMO/WB 等控制位的消费不变。

## 变更

- 删除 `verilator lint_off/on UNUSEDSIGNAL`。
- `ctrl_supported()` 从完整 `CTRL_BUS` 入参改为 9 个明确判定位。
- dispatch0/dispatch1 supported 调用点显式传入对应控制位。
- 增加一条中文注释，说明该 helper 不再伪消费整条控制总线。

## 验证

- `make -C npc/rv64/testbench /tmp/npc-ooo-decode-supported-cleanup/logs/tb_ooo_alu_decode_backend.log /tmp/npc-ooo-decode-supported-cleanup/logs/tb_ooo_int_backend.log /tmp/npc-ooo-decode-supported-cleanup/logs/tb_ooo_alu_fetch_core.log`：3/3 PASS。
- `make -C npc/rv64 lint`：PASS。
- `make -C npc/rv64 -j2`：PASS。
- `make -C Linux/tools smoke-jal-link smoke-branch-raw smoke-muldiv smoke-sret-user-sv39-halfword smoke-fp-loadstore`：全部 GOOD TRAP。
- `rg -n "UNUSEDSIGNAL|rv32b_result" npc/rv64/vsrc/ooo/backend/OooAluDecodeBackend.v npc/rv64/vsrc/ooo/backend/OooIntBackend.v`：无命中。
- `rg -n "verilator lint_off (UNUSEDSIGNAL|UNOPTFLAT)|verilator lint_on (UNUSEDSIGNAL|UNOPTFLAT)" npc/rv64/vsrc/{core,decode,execute,memory,writeback,ooo,frontend,cache,bus,common} --glob '!legacy/**'`：活动 RTL 中 `UNUSEDSIGNAL` 无命中。
- `git diff --check -- npc/rv64/vsrc/ooo/backend/OooAluDecodeBackend.v`：PASS。

## 剩余边界

活动 RTL 排除 `legacy/` 后剩余显式 waiver：

- `OooAluDecodeBackend.v`：`UNOPTFLAT` 1 段。
- `OooAluFetchCore.v`：`UNOPTFLAT` 3 段。

下一轮建议先分析 `OooAluDecodeBackend` 的 `backend_dispatch*_valid/ready` 组合依赖，再决定是否能通过握手打拍、ready 分层或前端门控重构消除 `UNOPTFLAT`。
