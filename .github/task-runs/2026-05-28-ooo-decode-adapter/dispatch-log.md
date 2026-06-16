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
- `npc/single/design/study/RISC-V-spec-functional-sim-notes.md`
- `npc/single/design/study/RISC-V-spec-hardware-architecture-notes.md`
- 当前 `DecodeStage/DecodeUnit/ImmGen`
- 当前 `OooIntBackend` 及 OoO 子模块

关键结论：

- RTL 改动前必须写清需求、协议规则、状态机、不变量和数据通路约束。
- 现有 `OooIntBackend` 已能闭合 ALU-only uop 的 rename/issue/execute/writeback/commit，但输入仍是手工 uop。
- 下一步最小安全推进不是立刻替换 `NpcCore`，而是先把真实 `pc+inst` 到后端 uop 的边界做出来，并显式挡住未支持指令。
- `DecodeStage` 已是当前主路径 decode 封装，应复用它，避免新适配层手写另一套译码。

## PLAN

1. 复核 `DecodeStage`、ctrl bus 与 `OooIntBackend` dispatch 接口。
2. 推导 ALU-only 指令支持边界和 unsupported 背压协议。
3. 新增 `OooAluDecodeBackend` 和真实指令 testbench。
4. 跑新增 testbench、OoO 子集、lint、全量 testbench、build、`cpu-tests add`。
5. 更新 memory 与 task-run，并保持 goal 未完成。

## DISPATCH

改动文件：

- `npc/single/vsrc/ooo/OooAluDecodeBackend.v`
- `npc/single/vsrc/filelist.mk`
- `npc/single/testbench/Makefile`
- `npc/single/testbench/tests/tb_ooo_alu_decode_backend.sv`
- `.github/memory/project-status.md`
- `.github/memory/modules/npc.md`
- `.github/task-runs/2026-05-28-ooo-decode-adapter/task-report.md`
- `.github/task-runs/2026-05-28-ooo-decode-adapter/dispatch-log.md`

## VERIFY

执行过的验证：

- `make -C npc/single/testbench BUILD_DIR=/tmp/npc-ooo-decode-build RESULT_DIR=/tmp/npc-ooo-decode-results /tmp/npc-ooo-decode-results/logs/tb_ooo_alu_decode_backend.log`
- OoO 相关 9 个 testbench，结果均 `[RESULT] PASS`
- `make -C npc/single lint`
- `make -C npc/single/testbench BUILD_DIR=/tmp/npc-single-full-tb2-build RESULT_DIR=/tmp/npc-single-full-tb2-results run`
- `make -C npc/single -j4`
- `AM_HOME=/home/lyg/PA/ysyx-workbench/abstract-machine make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc ALL=add run`
- `git diff --check`

结果摘要：

- 模块 testbench 36/36 PASS。
- `cpu-tests add` GOOD TRAP，`cycles=1509`、`commits=838`、`CPI=1.801`。
- CPI 未变化是预期现象：新 decode adapter 还未接入当前主 `NpcCore`。

## ADAPT

本轮 RTL 定向测试未出现功能失败。

保留观察：

- Icarus 在 OoO issue queue 一带仍会打印若干既有 sensitivity/array 相关 warning；本轮新增测试全部 PASS，且 warning 来源不是新增 decode adapter 的功能失败。
- WSL 并发状态查询偶发 `Wsl/Service/0x8007274c` 输出，本轮验证命令本身均已独立完成。

## RECORD

长期结论已写入：

- `.github/memory/project-status.md`
- `.github/memory/modules/npc.md`

本轮仍不标记 goal 完成，因为尚未接入主 CPU，也未达到或验证 CPI=0.5。
