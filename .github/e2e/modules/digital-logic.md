# digital-logic E2E Contract

- **范围**: 数字逻辑实验目录、scpu、NVBoard 实验入口。
- **上游**: nvboard、Verilator/Make。
- **下游**: 实验级 smoke 与报告。
- **L0 gate**: `digital-logic-contract` 检查实验目录和 agent。
- **L1 gate**: 后续按实验编号选择 Make smoke。
- **证据**: 实验目录、构建日志、NVBoard 输出。
- **升级路线**: 为 `e_2/e_3/e_6/e_7/e_8/scpu` 建子 profile。
