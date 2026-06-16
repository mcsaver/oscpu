# am-kernels E2E Contract

- **范围**: CPU/ALU/KLIB/AM tests、benchmarks、回归脚本。
- **上游**: abstract-machine。
- **下游**: NEMU reference、NPC target、性能 profile。
- **L0 gate**: `am-kernels-contract` 检查测试目录、benchmark 和 `scripts/am-regression.sh`。
- **L1 gate**: `quick/reference/full` profile。
- **证据**: `.result`、benchmark marks、regression status。
- **升级路线**: 汇总 PASS/FAIL marker 为机器可读 TSV/JSON，避免只读 exit code。
