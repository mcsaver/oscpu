# Dispatch Log

## 读取上下文

- `.github/AGENTS.md`
- `.github/copilot-instructions.md`
- `.github/memory/project-status.md`
- `.github/memory/known-issues.md`
- `.github/memory/modules/npc.md`
- `.github/instructions/rtl-generation-workflow.instructions.md`
- `.github/instructions/npc-study.instructions.md`
- `npc/single/design/study/README.md`
- `npc/single/design/study/RV32I-ai-notes.md`
- `npc/single/vsrc/ooo/*.v`
- `npc/single/vsrc/filelist.mk`

## 决策

- 继续保持 OoO 模块独立落地，不直接修改当前 `NpcCore`，避免在缺少完整 commit/flush/LSQ 协议时破坏现有 difftest 基线。
- 第二阶段优先补 issue 前后最小闭环：PRF、BusyTable、Integer IssueQueue。
- 单测优先覆盖协议不变量，而不是只测 reset/基本入队。

## 文件改动

- `npc/single/vsrc/ooo/OooPhysRegFile.v`
- `npc/single/vsrc/ooo/OooBusyTable.v`
- `npc/single/vsrc/ooo/OooIntIssueQueue.v`
- `npc/single/vsrc/filelist.mk`
- `npc/single/testbench/Makefile`
- `npc/single/testbench/tests/tb_ooo_phys_reg_file.sv`
- `npc/single/testbench/tests/tb_ooo_busy_table.sv`
- `npc/single/testbench/tests/tb_ooo_int_issue_queue.sv`
- `.github/memory/project-status.md`
- `.github/memory/modules/npc.md`
- `.github/task-runs/2026-05-28-ooo-issue-backend/task-report.md`
- `.github/task-runs/2026-05-28-ooo-issue-backend/dispatch-log.md`

## 验证命令

- `wsl.exe -d Ubuntu -- make -C npc/single/testbench BUILD_DIR=/tmp/npc-ooo2-tb-build RESULT_DIR=/tmp/npc-ooo2-tb-results /tmp/npc-ooo2-tb-results/logs/tb_ooo_phys_reg_file.log /tmp/npc-ooo2-tb-results/logs/tb_ooo_busy_table.log /tmp/npc-ooo2-tb-results/logs/tb_ooo_int_issue_queue.log`
- `wsl.exe -d Ubuntu -- make -C npc/single lint`
- `wsl.exe -d Ubuntu -- make -C npc/single/testbench BUILD_DIR=/tmp/npc-ooo2-full-tb-build RESULT_DIR=/tmp/npc-ooo2-full-tb-results`
- `wsl.exe -d Ubuntu -- make -C npc/single -j4`
- `wsl.exe -d Ubuntu -- sh -lc 'export AM_HOME=/home/lyg/PA/ysyx-workbench/abstract-machine NPC_HOME=/home/lyg/PA/ysyx-workbench/npc NEMU_HOME=/home/lyg/PA/ysyx-workbench/nemu; cd /home/lyg/PA/ysyx-workbench/am-kernels/tests/cpu-tests && make ARCH=riscv32-npc ALL=add run NPC_RUN_ARGS="--no-progress"'`
- `git -c safe.directory=//wsl$/Ubuntu/home/lyg/PA/ysyx-workbench diff --check -- ...`

## 下一跳建议

1. 增加 `OooDispatchRename` 或等价 wrapper，把 decode lane、rename map、free list、busy table、ROB dispatch、issue queue dispatch 串成一个 2-wide 前端后端边界。
2. 增加双 ALU execute + writeback wakeup 模块，先跑无 load/store 的小型 OoO 后端仿真。
3. 让 ROB commit 驱动 old pdest free，并为 branch flush 设计 rename checkpoint/restore。
4. 再接 LSQ 和 CSR/trap，最后才把主 `NpcCore` 从顺序流水线切到 OoO 路径。
