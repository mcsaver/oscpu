# OoO Issue Backend Stage

## 任务

继续推进“完成一个乱序超标量处理器，目标 CPI=0.5”。本轮目标不是一次性替换现有顺序 `NpcCore`，而是在上一轮 `rename/free-list/ROB` 基础上补齐 issue 前后的核心后端基础件：

- `OooPhysRegFile`: 64-entry 物理寄存器堆，4R2W，同拍写读旁路。
- `OooBusyTable`: 物理寄存器 ready/busy 表，2 allocate + 2 wakeup，组合查询。
- `OooIntIssueQueue`: 8-entry 整数 issue queue，2-wide dispatch、2 wakeup、最多 2 条 oldest-ready 发射。

## 需求到 RTL 推导

需求层：

- OoO 后端必须能把 rename 后的源/目的物理寄存器从架构寄存器堆中拆出来。
- issue queue 必须能接住两个 dispatch lane，并根据 busy table/writeback wakeup 选择 ready uop。
- 当前先覆盖 ALU-only integer uop，不在本轮接 LSU、CSR、分支 checkpoint 或主 `NpcCore` commit。

协议层：

- PRF 组合读、时钟沿写；p0 固定为 0；同拍读写同一 pdest 时读端看到写数据，write1 高于 write0。
- BusyTable 组合查询需要看见同拍 allocate/wakeup；同一 preg 同拍 allocate+wakeup 时 allocate 优先，避免新分配物理寄存器被旧 wakeup 错认 ready。
- IssueQueue dispatch 使用 valid/ready；issue0 选择最老 ready entry，issue1 选择第二老 ready entry；issue1 只有 issue0 fire 时才允许 fire，保持按端口顺序提交到执行单元。

状态机/状态集合：

- PRF 维护 `regs_q[0..63]`，reset 清零。
- BusyTable 维护 `ready_q[0..63]`，reset/flush 全 ready。
- IssueQueue 维护 ordered compact queue：每拍先计算 wakeup 后 ready，发射 fire 的 entry 被删除，其余 entry 保序 compact，再 append dispatch0/dispatch1。

不变量：

- p0 永远为 0 且 ready。
- allocate 与 wakeup 同拍命中同一 pdest 后，该 preg 必须保持 busy。
- issue queue 内有效 entry 保持程序序；dispatch1 不能越过 dispatch0。
- 后端背压时 entry 不得丢失；issue1 不得在 issue0 未 fire 时单独 fire。

数据通路约束：

- `PHY_REG_ADDR_W=6`，`ROB_INDEX_W=4`。
- Issue payload 包含 `pc/inst/ctrl/rob_idx/src1_preg/src1_ready/src2_preg/src2_ready/pdest/imm`。
- 本轮只提供基础模块接口，不改变 `NpcCore` 现有 in-order 提交路径。

## 实现

- 新增 `npc/single/vsrc/ooo/OooPhysRegFile.v`
- 新增 `npc/single/vsrc/ooo/OooBusyTable.v`
- 新增 `npc/single/vsrc/ooo/OooIntIssueQueue.v`
- 更新 `npc/single/vsrc/filelist.mk`
- 更新 `npc/single/testbench/Makefile`
- 新增 `tb_ooo_phys_reg_file.sv`
- 新增 `tb_ooo_busy_table.sv`
- 新增 `tb_ooo_int_issue_queue.sv`

## 调试记录

- PRF 初版在 Icarus 下 `write0 bypass` 失败。根因是连续赋值调用的 function 只把 read addr 作为参数，function body 读取 `write*_valid/addr/data` 模块端口；Icarus 没有在 read addr 不变、write 端口变化时重新求值。修复：把 write 端口显式传入 `read_port_data()`。
- BusyTable 初版同类问题导致 `wakeup same-cycle ready` 失败。修复：把 allocate/wakeup 信号显式传入 `query_ready()`。
- IssueQueue 初版同类问题导致 wakeup 后等待 uop 没有同拍变 ready。修复：把 wakeup 信号显式传入 `wakeup_match()`。

## 验证

- `make -C npc/single/testbench BUILD_DIR=/tmp/npc-ooo2-tb-build RESULT_DIR=/tmp/npc-ooo2-tb-results ...`
  - `tb_ooo_phys_reg_file` PASS
  - `tb_ooo_busy_table` PASS
  - `tb_ooo_int_issue_queue` PASS
- `make -C npc/single lint` PASS
- `make -C npc/single/testbench BUILD_DIR=/tmp/npc-ooo2-full-tb-build RESULT_DIR=/tmp/npc-ooo2-full-tb-results` PASS，33/33
- `make -C npc/single -j4` PASS
- `make ARCH=riscv32-npc ALL=add run NPC_RUN_ARGS="--no-progress"` GOOD TRAP
  - cycles = 1509
  - commits = 838
  - CPI = 1.801
- `git diff --check` PASS

## 当前限制

- 新增模块还没有接入 `NpcCore`，因此当前实际 CPU 仍是顺序流水线，CPI=0.5 尚未达成。
- 下一步需要补 dispatch/rename adapter、双 ALU execute + wakeback、ROB commit 接管 old pdest free、分支 checkpoint/rollback、LSQ、CSR/异常精确处理和性能回归。
