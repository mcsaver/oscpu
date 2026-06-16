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

关键结论：

- RTL 改动必须按需求、协议、状态机、不变量、数据通路约束推导。
- 当前 OoO 模块尚未接入 `NpcCore`，CPI 仍是顺序流水线基线。
- WBU/commit 是统一提交点，OoO 方向必须保持 ROB 顺序提交和 old pdest 回收边界。

## PLAN

1. 修复 `OooRenameMap` 中潜在 function 隐式敏感列表问题。
2. 新增 `OooDispatchBackend` 串接 rename/free/busy/ROB/IQ。
3. 新增 `tb_ooo_dispatch_backend` 覆盖双发依赖、WAW、commit free、flush。
4. 跑定向 OoO 单测、lint、全量 testbench、build、`cpu-tests add`。
5. 更新 memory 与 task-run。

## DISPATCH

改动文件：

- `npc/single/vsrc/ooo/OooRenameMap.v`
- `npc/single/vsrc/ooo/OooDispatchBackend.v`
- `npc/single/vsrc/filelist.mk`
- `npc/single/testbench/Makefile`
- `npc/single/testbench/tests/tb_ooo_dispatch_backend.sv`
- `.github/memory/project-status.md`
- `.github/memory/modules/npc.md`
- `.github/task-runs/2026-05-28-ooo-dispatch-backend/task-report.md`
- `.github/task-runs/2026-05-28-ooo-dispatch-backend/dispatch-log.md`

## VERIFY

执行过的验证：

- `make -C npc/single/testbench BUILD_DIR=/tmp/npc-ooo3-tb-build RESULT_DIR=/tmp/npc-ooo3-tb-results /tmp/npc-ooo3-tb-results/logs/tb_ooo_dispatch_backend.log`
- OoO 相关 7 个 testbench，结果均 `[RESULT] PASS`
- `make -C npc/single lint`
- `make -C npc/single/testbench BUILD_DIR=/tmp/npc-ooo3-full-tb-build RESULT_DIR=/tmp/npc-ooo3-full-tb-results`
- `make -C npc/single -j4`
- `make ARCH=riscv32-npc ALL=add run NPC_RUN_ARGS="--no-progress"`
- `git diff --check`

## ADAPT

遇到的问题：

- `make -C npc/single lint` 初次失败于 `PINCONNECTEMPTY`，原因是 `OooDispatchBackend` 对 `OooFreeList.alloc*_ready_o` 使用了空连接。修复为显式接到内部 wire，并并入 unused 消耗线。

本轮未出现功能测试失败。

## RECORD

长期结论已写入：

- `.github/memory/project-status.md`
- `.github/memory/modules/npc.md`

本轮仍不标记 goal 完成，因为尚未接入主 CPU，也未达到或验证 CPI=0.5。
