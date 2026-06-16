# OoO Dispatch Backend Stage

## 任务

继续推进“完成一个乱序超标量处理器，目标 CPI=0.5”。本轮在前两阶段独立 OoO 基础件之上，新增一个可测试的 2-wide dispatch/rename 后端边界，而不是直接替换当前顺序 `NpcCore`。

新增模块：

- `npc/single/vsrc/ooo/OooDispatchBackend.v`

同步更新：

- `npc/single/vsrc/ooo/OooRenameMap.v`
- `npc/single/vsrc/filelist.mk`
- `npc/single/testbench/Makefile`
- `npc/single/testbench/tests/tb_ooo_dispatch_backend.sv`

## RTL 推导摘要

需求：

- 把 `OooRenameMap`、`OooFreeList`、`OooBusyTable`、`OooRob`、`OooIntIssueQueue` 串成 2-wide dispatch/rename 后端边界。
- 输入两条已译码 uop 的 `pc/inst/ctrl/rs1_arch/rs2_arch/rd_arch/imm`。
- 输出两个 issue 端口和两个 ROB commit 端口。
- writeback 端口同时完成 BusyTable wakeup 与 ROB done。
- 本轮不实现 execute、PRF 读数据、LSQ、branch checkpoint，也不接入 `NpcCore`。

协议规则：

- lane0 先于 lane1；lane1 只有 lane0 fire 后才可 fire。
- 只有 `rd_en && rd!=x0` 的 uop 才消耗 FreeList。
- FreeList alloc 端口按 accepted 写 rd uop 压缩：lane0 不写 rd、lane1 写 rd 时，lane1 使用 alloc0。
- dispatch 同时要求 ROB、IssueQueue 有空间且 FreeList 有足够物理寄存器。
- BusyTable 查询组合看见同拍 allocate/wakeup；allocate 优先于 wakeup。
- ROB commit 后 old pdest 自动回收到 FreeList。

状态机：

- wrapper 本身不新增大状态机，只组合计算 `dispatch_fire/alloc_valid/ready`。
- speculative 状态分别由子模块维护：rename map、freelist FIFO、busy bits、ROB ring、issue compact queue。
- `flush_i` 同时送入所有子模块，恢复 OoO speculative 状态。

不变量：

- x0/p0 不分配、不置 busy、不释放。
- lane1 不越过 lane0。
- 同拍 RAW/WAW 时，lane1 看到 lane0 的新 mapping。
- 任一资源背压时不得消耗 FreeList、ROB 或 IssueQueue。
- 只有 ROB commit valid 的 old pdest 才进入 FreeList。

数据通路约束：

- `PHY_REG_ADDR_W=6`，`ROB_INDEX_W=4`。
- source preg 来自 RenameMap，source ready 来自 BusyTable。
- IssueQueue payload 保留 `pc/inst/ctrl/rob_idx/src_preg/src_ready/pdest/imm`。
- commit payload 仍由 ROB 统一输出，后续接架构提交或 old pdest 回收。

## 实现要点

- `OooDispatchBackend` 实例化并串接 `FreeList/RenameMap/BusyTable/ROB/IntIssueQueue`。
- 修正 `OooRenameMap::map_after_lane0()`：把 lane0 write 相关信号显式作为 function 参数，避免 Icarus 在 arch index 不变时漏掉 lane0 write 变化导致 lane1 RAW/WAW 不重算。
- 新增 `tb_ooo_dispatch_backend` 覆盖：
  - 双发依赖链：lane1 读 lane0 rd，必须等待 wakeup。
  - writeback wakeup 同拍释放 issue queue 等待项。
  - ROB commit 后 old pdest 回收到 FreeList。
  - 同拍 WAW：lane1 old pdest 等于 lane0 new pdest。
  - flush 清空 ROB/IQ 并恢复 FreeList。

## 验证

- `tb_ooo_dispatch_backend` PASS。
- OoO 相关 7 个 testbench PASS。
- `make -C npc/single lint` PASS。
- `make -C npc/single/testbench BUILD_DIR=/tmp/npc-ooo3-full-tb-build RESULT_DIR=/tmp/npc-ooo3-full-tb-results` PASS，34/34。
- `make -C npc/single -j4` PASS。
- `make ARCH=riscv32-npc ALL=add run NPC_RUN_ARGS="--no-progress"` GOOD TRAP。
  - cycles = 1509
  - commits = 838
  - CPI = 1.801
- `git diff --check` PASS。

## 当前限制

- `OooDispatchBackend` 仍是独立后端基础件，未接入主 `NpcCore`。
- 尚无 execute/writeback 小闭环，PRF 也还没有被发射端口读取。
- 尚无 LSQ、branch checkpoint/rollback、CSR/trap 精确接入。
- 因此 CPI=0.5 尚未达成，当前 `cpu-tests add` 的 CPI 仍是顺序流水线基线。

## 下一步

优先补一个独立的双 ALU execute/writeback 小闭环：

1. Issue 端口读取 PRF。
2. 用现有 `ALU` 或轻量 OoO integer execute 计算 ALU-only uop。
3. 写回 PRF，同时 wakeup BusyTable、完成 ROB。
4. 用 testbench 跑 `dispatch -> issue -> execute -> writeback -> commit` 的最小指令片段。
