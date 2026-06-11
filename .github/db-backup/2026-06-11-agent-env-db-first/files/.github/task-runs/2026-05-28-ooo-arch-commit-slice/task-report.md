# OoO Architectural Commit Slice

## 任务

继续推进“完成一个乱序超标量处理器，目标 CPI=0.5”。本轮在已有 `OooAluDecodeBackend` 之后补退休到架构状态的边界，让 ALU-only OoO 后端不只输出 ROB commit payload，还能按程序序更新一份架构 GPR 快照。

新增模块：

- `npc/single/vsrc/ooo/OooArchRegFile.v`
- `npc/single/vsrc/ooo/OooAluCoreSlice.v`

同步更新：

- `npc/single/vsrc/filelist.mk`
- `npc/single/testbench/Makefile`
- `npc/single/testbench/tests/tb_ooo_alu_core_slice.sv`

## RTL 推导摘要

需求：

- 将 `OooAluDecodeBackend` 的双路 ROB commit 输出接到架构寄存器状态。
- 支持同拍最多两条退休指令写 GPR。
- 输出 `debug_gprs_o`、`a0_data_o` 与 `retire_count_o`，为后续替换 `NpcCore` 写回/debug/difftest 边界做准备。
- 保持当前 ALU-only 子集限制，不在本轮接入 LSQ、branch、CSR/trap。

协议规则：

- `OooRob` 的 `commit*_valid_o` 当前由 `commit_ready_i` 门控，因此在 slice 内按 commit fire 使用。
- 架构寄存器写入条件为 `commit_valid && rd_en && !exception && rd!=x0`。
- lane0 和 lane1 同拍写同一个 rd 时，lane1 后写，代表程序序更年轻提交最终可见。
- `commit_ready_i=0` 时后端不产生 commit fire，架构寄存器不得提前改变。
- speculative `flush_i` 只清 OoO 后端状态，不清已退休架构状态。

状态机：

- `OooArchRegFile` 只有 32 个 GPR 寄存器数组；reset 清零，正常周期按 lane0 再 lane1 写。
- `OooAluCoreSlice` 不新增 FSM，只组合/连线 `OooAluDecodeBackend -> OooArchRegFile`。

不变量：

- x0 通过写入屏蔽和 debug 输出双重保证恒为 0。
- 未 fire 的 commit 不得改变 GPR。
- exception commit 不得写 GPR。
- lane1 同拍写入优先于 lane0，以维持双提交 WAW 程序序。
- flush 不回滚已经退休的架构 GPR。

数据通路约束：

- raw `pc+inst` 输入仍由 `DecodeStage` 生成 ctrl/uop。
- ALU execute 结果先进入物理寄存器和 ROB，再由 ROB 顺序 commit。
- `OooArchRegFile` 只消费 ROB commit data，不读取 speculative PRF。
- `debug_gprs_o` 表示已退休架构状态，不表示当前 speculative rename map。

## 实现要点

- `OooArchRegFile`：
  - 32-entry GPR，reset 清零。
  - 两个 commit 写口，lane1 后写。
  - 输出 `commit*_write_o` 便于 testbench 检查退休写入条件。
- `OooAluCoreSlice`：
  - 实例化 `OooAluDecodeBackend`。
  - 实例化 `OooArchRegFile`。
  - 暴露 commit payload、retire count、队列计数、execute valid、a0/debug GPR。
- `tb_ooo_alu_core_slice` 覆盖：
  - 双路 ADDI 退休后写 x1/x2。
  - 依赖 R-type 读取已退休 x1/x2 后写 x3/x4。
  - 同拍 WAW 写 x5，lane1 最终可见。
  - commit 背压期间 x6/x7 不提前改变。
  - flush 丢弃未退休 x8/x9。

## 验证

- `tb_ooo_alu_core_slice` PASS。
- OoO 相关 10 个 testbench PASS：
  - `tb_ooo_rename_map`
  - `tb_ooo_free_list`
  - `tb_ooo_rob`
  - `tb_ooo_phys_reg_file`
  - `tb_ooo_busy_table`
  - `tb_ooo_int_issue_queue`
  - `tb_ooo_dispatch_backend`
  - `tb_ooo_int_backend`
  - `tb_ooo_alu_decode_backend`
  - `tb_ooo_alu_core_slice`
- `make -C npc/single lint` PASS。
- `make -C npc/single/testbench BUILD_DIR=/tmp/npc-single-full-tb3-build RESULT_DIR=/tmp/npc-single-full-tb3-results run` PASS，37/37。
- `make -C npc/single -j4` PASS。
- `AM_HOME=/home/lyg/PA/ysyx-workbench/abstract-machine make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc ALL=add run` PASS / GOOD TRAP。
  - cycles = 1509
  - commits = 838
  - CPI = 1.801
- `git diff --check` PASS。

## 当前限制

- `OooAluCoreSlice` 尚未接入 `NpcCore`，当前 `cpu-tests add` 的 CPI 仍来自顺序流水线主路径。
- 当前没有真实 fetch 双取/指令包接口，testbench 仍直接喂两路指令。
- 当前只覆盖 ALU-only 指令，不支持 branch/load/store/CSR/trap/muldiv/bitmanip。
- CPI=0.5 目标仍未达成。

## 下一步

优先做 `NpcCore` 受控接入实验：

1. 设计一个 ALU-only experimental 模式，避免和旧流水线双写架构状态。
2. 从前端连续顺序取指形成两路 dispatch 包，先挡住 unsupported 指令。
3. 用 `OooAluCoreSlice` 的 commit/debug GPR 替代该模式下的旧 WBU/RF 可观察状态。
4. 再向 LSQ、branch checkpoint/rollback、CSR/trap 精确提交扩展。
