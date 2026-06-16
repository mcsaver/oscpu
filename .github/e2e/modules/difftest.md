# difftest E2E Contract

- **范围**: NEMU reference so、Spike reference、NPC single/soc submit 对比。
- **上游**: NEMU config、NPC target、AM image。
- **下游**: rv32-bringup、soc-difftest-loop、性能优化安全门。
- **L0 gate**: `difftest-contract` 检查 spike-diff、npc/sim difftest-ref 与 memory。
- **L1 gate**: 后续升级为 `make -C npc/sim BACKEND=single difftest-ref` smoke。
- **证据**: reference so、DiffTest PASS/FAIL、first mismatch boundary。
- **升级路线**: 统一 mismatch 摘要格式，自动 handoff 到 regression-debug-loop。
