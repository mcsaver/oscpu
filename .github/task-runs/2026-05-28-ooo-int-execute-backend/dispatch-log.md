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
- 当前 `npc/single/vsrc/ooo/*.v`
- 当前 `npc/single/vsrc/execute/ALU.v`
- 当前 `npc/single/vsrc/include/define.v`

关键结论：

- RTL 改动前必须写清需求、协议规则、状态机、不变量和数据通路约束。
- 现有 ALU 是纯组合，适合作为 ALU-only execute 单元复用。
- `OooIntIssueQueue` 的 wakeup 是组合参与 ready 判断，因此执行单元必须寄存 writeback，避免同拍 issue 生产者零周期唤醒消费者。
- WBU/ROB commit 是统一提交点，OoO 方向必须保持 ROB 顺序提交。

## PLAN

1. 复核 ALU、ctrl bus、PRF、ROB、IssueQueue、DispatchBackend 接口。
2. 推导 ALU-only OoO execute/writeback 协议。
3. 新增 `OooIntBackend` 和 `tb_ooo_int_backend`。
4. 跑新增 testbench、OoO 子集、lint、全量 testbench、build、`cpu-tests add`。
5. 更新 memory 与 task-run。

## DISPATCH

改动文件：

- `npc/single/vsrc/ooo/OooIntBackend.v`
- `npc/single/vsrc/filelist.mk`
- `npc/single/testbench/Makefile`
- `npc/single/testbench/tests/tb_ooo_int_backend.sv`
- `.github/memory/project-status.md`
- `.github/memory/modules/npc.md`
- `.github/task-runs/2026-05-28-ooo-int-execute-backend/task-report.md`
- `.github/task-runs/2026-05-28-ooo-int-execute-backend/dispatch-log.md`

## VERIFY

执行过的验证：

- `make -C npc/single/testbench BUILD_DIR=/tmp/npc-ooo-int-backend-build RESULT_DIR=/tmp/npc-ooo-int-backend-results /tmp/npc-ooo-int-backend-results/logs/tb_ooo_int_backend.log`
- OoO 相关 8 个 testbench，结果均 `[RESULT] PASS`
- `make -C npc/single lint`
- `make -C npc/single/testbench BUILD_DIR=/tmp/npc-single-full-tb-build RESULT_DIR=/tmp/npc-single-full-tb-results run`
- `make -C npc/single -j4`
- `AM_HOME=/home/lyg/PA/ysyx-workbench/abstract-machine make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc ALL=add run`
- `git diff --check`

结果摘要：

- 模块 testbench 35/35 PASS。
- `cpu-tests add` GOOD TRAP，`cycles=1509`、`commits=838`、`CPI=1.801`。
- CPI 未变化是预期现象：新后端还未接入当前主 `NpcCore`。

## ADAPT

遇到的问题：

- 第一次运行 `cpu-tests add` 未设置 `AM_HOME`，AM 生成的临时 Makefile 试图 include `/Makefile`，因此测试入口失败；随后显式设置 `AM_HOME=/home/lyg/PA/ysyx-workbench/abstract-machine` 后 PASS。

本轮 RTL 定向测试未出现功能失败。

## RECORD

长期结论已写入：

- `.github/memory/project-status.md`
- `.github/memory/modules/npc.md`

本轮仍不标记 goal 完成，因为尚未接入主 CPU，也未达到或验证 CPI=0.5。
