# ysyx-soc E2E Contract

- **范围**: Chisel SoC、CPU ABI、地址图、`ysyxSoCFull.v` 生成。
- **上游**: CPU wrapper、JDK21/mill、SoC spec。
- **下游**: `npc/soc`、SOC_SIM DiffTest、SoC lint。
- **L0 gate**: `ysyx-soc-contract` 检查 Makefile、spec、agent 和 memory。
- **L1 gate**: 后续升级为 `make -C ysyxSoC verilog` smoke。
- **证据**: CPU interface spec、生成日志、soc-lint。
- **升级路线**: 生成物 hash + wrapper ABI diff audit。
