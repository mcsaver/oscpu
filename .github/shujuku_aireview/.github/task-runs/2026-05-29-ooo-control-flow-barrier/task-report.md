# 2026-05-29 OoO control-flow barrier

## 目标

继续推进 `NPC_OOO_ALU_EXPERIMENT=1` 实验线，从仅支持直线 ALU packet 前进到能精确处理 lane0 条件分支。

## RTL 四段推导

### 需求

- 前端 2-wide packet 中 lane0 条件分支不再被当作 unsupported illegal trap。
- 分支前更老的已派发 OoO 指令必须先按序退休，分支方向使用已提交架构寄存器计算。
- 分支自身需要产生一条提交事件，便于 host commit/CPI 统计保持指令边界一致。
- taken 分支跳到 `pc + imm`；not-taken 分支跳到 `pc + 4`，lane1 通过重新取指执行，避免同 packet 分支后的 lane1 被错误提交。
- 已经发出的旧 packet 响应在 redirect 前要能被丢弃，避免 front-end/仿真取指源互相等待。

### 协议/状态机/不变量

- 分支进入 `stop_pending` 屏障，不再发新取指请求，也不再把当前 packet 派发给后端。
- `drain_complete = ROB empty && issue empty && no backend retire` 后，分支解析和合成提交发生在同一个时钟边界。
- redirect 清空 fetch FIFO、head/tail/count、outstanding 状态；stale fetch response 只 drop，不入 FIFO。
- 合成分支提交与后端提交互斥：只有排空后才发 `commit0`，`commit1` 置空。
- 分支本身不写 GPR；后续 `jal/jalr` 需要链接寄存器合成写回/架构态覆盖，不能混在本补丁里半做。

### 数据通路

- 复用 `DecodeStage` 得到 lane0 `ctrl/rs1/rs2/imm`。
- 用 `OooArchRegFile` 导出的 debug GPR 作为已提交架构态，送入 `CompareUnit` 计算条件。
- 解析目标：
  - taken: `pending_branch_pc + pending_branch_imm`
  - not taken: `pending_branch_pc + 4`
- misaligned taken target 报 `EXC_INST_ADDR_MISALIGN`，不产生分支提交。

### RTL

- `OooAluFetchCore` 增加 lane0 branch decode、pending branch metadata、stale fetch response drop、synthetic commit mux。
- `tb_ooo_alu_fetch_core` 增加 taken/not-taken 分支程序，并把旧 unsupported 边界改成 load。

## 当前限制

- 只处理 packet lane0 条件分支；lane1 分支仍走 unsupported 边界。
- `jal/jalr` 仍暂不支持，因为它们需要链接寄存器提交路径。
- 这是无预测的精确屏障方案，吞吐会在每个 lane0 分支处降级；后续应替换为 branch uop + checkpoint/rollback。

## 结果

- `OooAluFetchCore` 已实现 lane0 conditional branch pending 屏障、stale response drop、redirect FIFO/outstanding 清空、misaligned taken target trap 和 synthetic branch commit。
- `tb_ooo_alu_fetch_core` 已从“unsupported branch”改为“unsupported load”，并新增 taken/not-taken 分支覆盖。
- `npc/single/testbench/Makefile` 为 `tb_ooo_alu_fetch_core` 补入 `RTL_COMPARE_UNIT` 依赖。

## 验证

- `make -C npc/single/testbench BUILD_DIR=/tmp/npc-ooo-cf-tb-build RESULT_DIR=/tmp/npc-ooo-cf-tb-results /tmp/npc-ooo-cf-tb-results/logs/tb_ooo_alu_fetch_core.log` PASS。
- OoO 相关 11 个 testbench PASS。
- `make -C npc/single NPC_OOO_ALU_EXPERIMENT=1 lint` PASS。
- `make -C npc/single BUILD_DIR=/tmp/npc-ooo-cf-sim-build NPC_OOO_ALU_EXPERIMENT=1 -j4` PASS。
- Raw branch smoke `/tmp/ooo-cf-branch.bin` GOOD TRAP，`cycles=19`、`commits=6`、`CPI=3.167`。
- Raw 4096 independent ALU smoke `/tmp/ooo-cf-4096alu-ebreak.bin` GOOD TRAP，`cycles=2055`、`commits=4096`、`CPI=0.502`。
- 默认 `make -C npc/single lint` PASS。
- `make -C npc/single/testbench BUILD_DIR=/tmp/npc-ooo-cf-full-tb-build RESULT_DIR=/tmp/npc-ooo-cf-full-tb-results` 38/38 PASS。
- 默认 `make -C npc/single BUILD_DIR=/tmp/npc-ooo-cf-default-sim-build -j4` PASS。
- `AM_HOME=/home/lyg/PA/ysyx-workbench/abstract-machine make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc ALL=add run` PASS，默认 `cycles=1509`、`commits=838`、`CPI=1.801`。
