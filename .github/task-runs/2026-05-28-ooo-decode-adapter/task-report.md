# OoO Decode Adapter Stage

## 任务

继续推进“完成一个乱序超标量处理器，目标 CPI=0.5”。本轮不直接替换当前顺序 `NpcCore`，而是在已有 ALU-only OoO 后端前补一个真实指令译码适配层，让后端能接收 `pc+inst`，而不是只能接收 testbench 手工拼出的 uop。

新增模块：

- `npc/single/vsrc/ooo/OooAluDecodeBackend.v`

同步更新：

- `npc/single/vsrc/filelist.mk`
- `npc/single/testbench/Makefile`
- `npc/single/testbench/tests/tb_ooo_alu_decode_backend.sv`

## RTL 推导摘要

需求：

- 接收两路原始 `pc+inst` dispatch 输入。
- 复用既有 `DecodeStage` 生成统一 ctrl bus 和寄存器/立即数字段。
- 只允许当前 `OooIntBackend` 已闭合的 ALU-only 子集进入后端。
- 对未支持指令暴露 `unsupported_o` 并阻止 ready/fire。
- 保持后端 ROB 顺序 commit 输出，便于下一步接主核提交边界。

协议规则：

- 两路输入仍采用 valid/ready。
- lane0 可独立 fire；lane1 继续遵守后端 lane1 与 lane0 的程序序约束。
- unsupported 指令 ready=0、unsupported=1，不消耗 ROB、IQ 或 FreeList。
- `flush_i` 透传到 `OooIntBackend`，清空后端 speculative 状态。
- `commit_ready_i` 继续由外部控制 ROB commit 接收。

状态机：

- `OooAluDecodeBackend` 不新增时序状态。
- 两个 `DecodeStage` 组合输出 decode 结果。
- 状态仍集中在 `OooIntBackend` 及其子模块。

不变量：

- 只有 `ctrl_valid && !ctrl_illegal && ctrl_need_exec` 的基础 ALU 指令可进入后端。
- load/store/branch/jal/jalr/system/csr/fence/mret/wfi/muldiv/bitmanip 均必须被挡在适配层外。
- unsupported 指令不能改变 rename map、free list、busy table、ROB 或 issue queue。
- lane1 不越过 lane0 单独分配资源。
- x0、物理寄存器和 ROB commit 规则沿用后端既有不变量。

数据通路约束：

- `DecodeStage` 输出的 `pc/inst/ctrl/rs1/rs2/rd/imm` 原样映射到后端 dispatch 端口。
- 适配层不重新手写 opcode/funct 译码，避免和主 decode 路径分叉。
- `execute*_valid_o`、ROB commit 输出、队列计数等 debug/观测口透传自 `OooIntBackend`。

## 实现要点

- `OooAluDecodeBackend` 实例化两个 `DecodeStage` 和一个 `OooIntBackend`。
- `ctrl_supported()` 依据 ctrl bus 字段过滤当前后端未实现的指令类型。
- `tb_ooo_alu_decode_backend` 使用 `rv32_encode.svh` 生成真实 RV32 指令编码，覆盖：
  - 双路独立 `ADDI` 到双 commit。
  - `ADDI` RAW 依赖，消费者等待生产者写回后提交正确值。
  - `LUI/AUIPC` U-type 立即数与 PC 操作数选择。
  - `ADD/SUB` R-type 读取此前已提交 mapping。
  - lane1 branch unsupported 背压且不被 dispatch。

## 验证

- `tb_ooo_alu_decode_backend` PASS。
- OoO 相关 9 个 testbench PASS：
  - `tb_ooo_rename_map`
  - `tb_ooo_free_list`
  - `tb_ooo_rob`
  - `tb_ooo_phys_reg_file`
  - `tb_ooo_busy_table`
  - `tb_ooo_int_issue_queue`
  - `tb_ooo_dispatch_backend`
  - `tb_ooo_int_backend`
  - `tb_ooo_alu_decode_backend`
- `make -C npc/single lint` PASS。
- `make -C npc/single/testbench BUILD_DIR=/tmp/npc-single-full-tb2-build RESULT_DIR=/tmp/npc-single-full-tb2-results run` PASS，36/36。
- `make -C npc/single -j4` PASS。
- `AM_HOME=/home/lyg/PA/ysyx-workbench/abstract-machine make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc ALL=add run` PASS / GOOD TRAP。
  - cycles = 1509
  - commits = 838
  - CPI = 1.801
- `git diff --check` PASS。

## 当前限制

- `OooAluDecodeBackend` 尚未接入 `NpcCore`，当前 `cpu-tests add` 的 CPI 仍来自顺序流水线主路径。
- 当前只接 ALU-only 子集，无法运行含分支、访存、CSR/trap 的真实程序片段。
- 尚无 LSQ、分支 checkpoint/rollback、精确异常/CSR 提交。
- 因此 CPI=0.5 目标仍未达成。

## 下一步

优先做主核接入边界设计：

1. 明确 `NpcCore` 中旧顺序写回路径与 OoO ROB commit 的互斥关系。
2. 先用受控开关或子集模式让 ALU-only 指令片段由 `OooAluDecodeBackend` 驱动提交。
3. 接入架构 GPR/commit debug/difftest 观测。
4. 再扩展 LSU/分支 checkpoint/CSR trap，最后用真实程序与 CPI 指标闭环。
