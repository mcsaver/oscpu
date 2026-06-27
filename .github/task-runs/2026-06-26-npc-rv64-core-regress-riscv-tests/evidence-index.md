# Evidence Index

- `npc/rv64/perf/results/core-regress/20260626-160919/status.txt`
  - Final core regression status.
  - Key lines: `module-testbench PASS`, `verilator-lint PASS`, `npc-build PASS`, `am-cpu-tests PASS`, `riscv-tests-count INFO 111 tests attempted`.
- `npc/rv64/perf/results/core-regress/20260626-160919/summary.txt`
  - Full run timeline and final `overall_rc=0`.
- `npc/rv64/perf/results/core-regress/20260626-160435/status.txt`
  - Targeted `rv64ui` rerun after byte-addressed LSU/DPI fix.
  - Confirms `rv64ui-p-ma_data PASS`.
- `npc/rv64/perf/results/20260626-160907/module-testbench/summary.txt`
  - Focused module rerun after updating LSU-related tests.
  - Confirms `total: 52`, `passed: 52`, `failed: 0`.
