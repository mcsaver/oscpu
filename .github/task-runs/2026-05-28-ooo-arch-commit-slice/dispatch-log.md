# Dispatch Log

## RECALL

读取并采用以下约束：

- `.github/AGENTS.md`
- `.github/copilot-instructions.md`
- `.github/memory/project-status.md`
- `.github/memory/known-issues.md`
- `.github/memory/modules/npc.md`
- `.github/instructions/rtl-generation-workflow.instructions.md`
- `.github/instructions/npc-study.instructions.md`
- `npc/single/design/study/README.md`
- `npc/single/design/study/RV32I-ai-notes.md`
- `npc/single/design/study/RV32I-implementation-checklist.md`
- 当前 `NpcCore/RegisterFile` 提交与 debug GPR 接口
- 当前 `OooAluDecodeBackend/OooIntBackend/OooRob` commit 协议

关键结论：

- RTL 改动前必须写清需求、协议规则、状态机、不变量和数据通路约束。
- RV32I 笔记强调 WBU/commit 是统一提交点，不能让执行单元直接成为架构状态。
- `OooRob` 当前的 `commit*_valid_o` 由 `commit_ready_i` 门控，语义上已经是 commit fire。
- 下一步主核接入必须先有一份退休后的架构 GPR/debug 状态，否则 OoO 后端仍停留在“内部可测”而不是“CPU 可观察状态”。

## PLAN

1. 复核现有 `NpcCore` 的 `commit_*`、`RegisterFile` 和 OoO ROB commit 输出。
2. 设计 `OooArchRegFile` 双提交写入协议。
3. 新增 `OooAluCoreSlice` 串接 decode backend 与架构 GPR。
4. 新增 testbench 覆盖双写、WAW、背压和 flush。
5. 跑新增 testbench、OoO 子集、lint、全量 testbench、build、`cpu-tests add`。
6. 更新 memory 与 task-run。

## DISPATCH

改动文件：

- `npc/single/vsrc/ooo/OooArchRegFile.v`
- `npc/single/vsrc/ooo/OooAluCoreSlice.v`
- `npc/single/vsrc/filelist.mk`
- `npc/single/testbench/Makefile`
- `npc/single/testbench/tests/tb_ooo_alu_core_slice.sv`
- `.github/memory/project-status.md`
- `.github/memory/modules/npc.md`
- `.github/task-runs/2026-05-28-ooo-arch-commit-slice/task-report.md`
- `.github/task-runs/2026-05-28-ooo-arch-commit-slice/dispatch-log.md`

## VERIFY

执行过的验证：

- `make -C npc/single/testbench BUILD_DIR=/tmp/npc-ooo-core-slice-build RESULT_DIR=/tmp/npc-ooo-core-slice-results /tmp/npc-ooo-core-slice-results/logs/tb_ooo_alu_core_slice.log`
- OoO 相关 10 个 testbench，结果均 `[RESULT] PASS`
- `make -C npc/single lint`
- `make -C npc/single/testbench BUILD_DIR=/tmp/npc-single-full-tb3-build RESULT_DIR=/tmp/npc-single-full-tb3-results run`
- `make -C npc/single -j4`
- `AM_HOME=/home/lyg/PA/ysyx-workbench/abstract-machine make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc ALL=add run`
- `git diff --check`

结果摘要：

- 模块 testbench 37/37 PASS。
- `cpu-tests add` GOOD TRAP，`cycles=1509`、`commits=838`、`CPI=1.801`。
- CPI 未变化是预期现象：新 slice 还未接入当前主 `NpcCore`。

## ADAPT

遇到的问题：

- 第一次批量跑 OoO suite 时 shell 变量在目标路径中展开异常，make 试图创建 `/logs`；改用显式绝对 `/tmp/...` 目标后同一组测试 PASS。该问题是命令包装问题，不是 RTL 功能问题。

本轮 RTL 定向测试未出现功能失败。

## RECORD

长期结论已写入：

- `.github/memory/project-status.md`
- `.github/memory/modules/npc.md`

本轮仍不标记 goal 完成，因为尚未接入主 CPU，也未达到或验证 CPI=0.5。
