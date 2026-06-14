# OoO Int Execute Backend Stage

## 任务

继续推进“完成一个乱序超标量处理器，目标 CPI=0.5”。本轮在已有 2-wide dispatch/rename 后端基础上，补一个独立可测的 ALU-only 整数执行闭环，而不是直接替换当前顺序 `NpcCore`。

新增模块：

- `npc/single/vsrc/ooo/OooIntBackend.v`

同步更新：

- `npc/single/vsrc/filelist.mk`
- `npc/single/testbench/Makefile`
- `npc/single/testbench/tests/tb_ooo_int_backend.sv`

## RTL 推导摘要

需求：

- 在独立 OoO 后端内闭合 `dispatch/rename -> issue -> execute -> writeback -> commit`。
- 支持两条 ALU uop 同拍 issue，并用两个现有 `ALU` 计算。
- 复用 `OooPhysRegFile` 作为 speculative 物理寄存器堆。
- writeback 同时写 PRF、唤醒 BusyTable、标记 ROB done。
- 保持 ROB 顺序 commit 和 old pdest 回收边界。

协议规则：

- `OooDispatchBackend` 继续负责 lane0/lane1 dispatch 资源仲裁、rename、ROB 和 IQ。
- execute 端口当前不背压，两个 issue 端口均可每拍接收。
- ALU 结果进入一拍 execute register 后才 writeback，避免“生产者刚 issue 同拍唤醒消费者”的零周期依赖。
- writeback valid 驱动 PRF 写端口、BusyTable wakeup 和 ROB done。
- commit 仍只来自 ROB head，且 commit1 不越过异常 head。

状态机：

- `OooIntBackend` 不新增多状态 FSM，只新增两个 execute pipeline valid/payload 寄存器。
- `rst || flush_i` 清 execute stage，并透传 flush 到 dispatch backend。
- 子模块内部状态仍由 rename map、free list、busy table、ROB、issue queue 自己维护。

不变量：

- p0/x0 永远读 0，不写 PRF，也不作为真实 wakeup/allocate 目标。
- issue valid 且 ready 才能进入 execute register。
- execute valid 才能产生 writeback。
- RAW 依赖消费者必须等到生产者 writeback wakeup 后才可 issue。
- commit 释放 old pdest，不释放本条 new pdest。

数据通路约束：

- PRF 使用 4R2W：issue0 读 read0/read1，issue1 读 read2/read3。
- OP1 支持 `RS1/PC/ZERO`，OP2 支持 `RS2/IMM/FOUR`。
- ALU op 使用 ctrl bus 的 `CTRL_ALU_OP_*` 字段。
- 当前异常固定为 0；LSU、branch、CSR/trap 不在本轮范围。

## 实现要点

- `OooIntBackend` 实例化：
  - `OooDispatchBackend`
  - `OooPhysRegFile`
  - 两个 `ALU`
- writeback 从 execute register 输出，形成一拍 ALU latency。
- PRF 写回和新发射读同拍时，依赖 `OooPhysRegFile` 既有 write/read bypass 让消费者读到生产者结果。
- 新增 `execute0_valid_o/execute1_valid_o` 作为 testbench 可观察的执行级状态。
- `tb_ooo_int_backend` 覆盖：
  - 双独立 ADDI 双发、双执行、双 commit。
  - RAW 依赖链：消费者等待生产者 writeback wakeup，并通过 PRF bypass 算出正确结果。
  - `COPY_B` 类 LUI 数据选择。
  - `PC+4` 操作数选择。
  - flush 清空 execute、ROB、IQ、FreeList 状态。

## 验证

- `tb_ooo_int_backend` PASS。
- OoO 相关 8 个 testbench PASS：
  - `tb_ooo_rename_map`
  - `tb_ooo_free_list`
  - `tb_ooo_rob`
  - `tb_ooo_phys_reg_file`
  - `tb_ooo_busy_table`
  - `tb_ooo_int_issue_queue`
  - `tb_ooo_dispatch_backend`
  - `tb_ooo_int_backend`
- `make -C npc/single lint` PASS。
- `make -C npc/single/testbench BUILD_DIR=/tmp/npc-single-full-tb-build RESULT_DIR=/tmp/npc-single-full-tb-results run` PASS，35/35。
- `make -C npc/single -j4` PASS。
- `AM_HOME=/home/lyg/PA/ysyx-workbench/abstract-machine make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc ALL=add run` PASS / GOOD TRAP。
  - cycles = 1509
  - commits = 838
  - CPI = 1.801
- `git diff --check` PASS。

## 当前限制

- `OooIntBackend` 尚未接入 `NpcCore`，当前 `cpu-tests add` 的 CPI 仍是顺序流水线主路径。
- 尚无前端双取/双译码接入。
- 尚无 LSQ、load/store ordering、store-to-load forwarding。
- 尚无 branch checkpoint/rollback、异常/CSR/trap 精确接入。
- 因此 CPI=0.5 尚未达成。

## 下一步

优先设计 `NpcCore` 接入边界：

1. 选择一条 ALU-only 受控路径把现有 decode ctrl 包喂入 `OooIntBackend`。
2. 明确旧流水线和 OoO 后端的互斥/切换方式，避免双写架构状态。
3. 接入提交级 GPR/CSR/debug/difftest 观测。
4. 再扩 LSU/branch checkpoint/precise trap，最后用 CoreMark 或微基准观察 CPI 是否向 0.5 收敛。
