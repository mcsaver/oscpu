# verilator-tapeout E2E Contract

- **范围**: Verilator-first 性能仿真、仿真-only 边界、可综合审计。
- **上游**: npc/rv64 core、Linux system gates、STA/PPA。
- **下游**: 流片水准收敛。
- **L0 gate**: `verilator-tapeout-contract` 检查 realism instruction 和 npc/rv64 Makefile。
- **L1 gate**: 后续 perf run + RTL invariant check。
- **证据**: host time、guest cycles/commits/CPI、仿真-only 边界记录。
- **升级路线**: 自动生成 tapeout readiness risk table。
