# Evidence Index

## F0 truthful-regression evidence（2026-07-11）

- `.github/task-runs/2026-07-11-rv64-f0-truthful-regression/task-report.md`: F0 根因、提交、
  配置 provenance 与完整 gate 汇总；
- `.../evidence/module-testbench-summary.log` + `module-testbench/logs/`: 86/86 真 PASS；
- `.../evidence/am-59-full.log`: 59/59 PASS，`fp-difftest-probe` 明确 Difftest ON；
- `.../evidence/core-regress/latest/status.txt`: module/lint/build/AM PASS，official 177/177；
- `.github/task-runs/2026-07-11-rv64-f0-closeout-final-npc-dev/`: final 新鲜 npc-dev workflow evidence；
- `.../evidence/strict-guard-after-npc-dev.log`: strict guard 两个 required profile PASS。

## Superseded pre-F0 functional evidence

- `npc/rv64/perf/results/core-regress/20260711-133547-973361/status.txt`: official 177 项逐项 PASS；
- `.../am-cpu-tests.log`: F0 前 `fp-difftest-probe ***FAIL***`，AM 58/59；
- `.../module-tests/`: F0 前三个 sequencer TB 原始 FAIL 后仍出现 `[RESULT] PASS`；
- `npc/rv64/README.md`: current 判读边界与 Difftest 未启用说明；
- `npc/rv64/design/arch/rtl-ground-truth-2026-07-11.md`: current topology/open contracts。

## Current timing evidence

- `npc/rv64/build/sta/NpcTop-100MHz/NpcTop.opensta.rpt`: 10 ns WNS −5.35 ns、TNS −34779.97 ns；
- `npc/rv64/build/sta/NpcTop-100MHz/topo40.rpt`: top40 path-family；
- `npc/rv64/build/sta/NpcTop-100MHz/abc.sdc`: generic drive/load；
- `yosys-sta/scripts/opensta-fullcore.tcl`: current diagnostic OpenSTA entry；
- `npc/rv64/Makefile`: `STA_CLK_FREQ_MHZ` production synthesis entry。

## Evidence limits

- 网表没有嵌入 RTL hash/commit，只能建立强一致性线索；
- ideal clock、无 SPEF/CTS/OCV/uncertainty；
- SRAM/BPU/FP 宏含近似或 placeholder；
- 旧 ACT4/Linux 日志不能替代 current RTL fresh evidence。

## Active design and implementation state

- `npc/rv64/design/arch/rv64-200mhz-completion-design.md`: 功能/时序双 gate 总体设计；
- `npc/rv64/design/arch/history/f0-truthful-regression-implementation-plan.md`: 已完成并归档的
  F0 TDD 实施清单；
- `npc/rv64/vsrc/execute/OooFpBackend.v`: 已以 `valid && frd` 资格化 FPR 域；
- `npc/rv64/perf/results/core-regress/20260711-133547-973361/am-cpu-tests.log`: PC
  `0x80000120` 的 reference/DUT 原始失配；
- `am-kernels/tests/cpu-tests/build/fp-difftest-probe-riscv64-npc.txt`: FSQRT/FMV.X.D 指令链。
