# nvboard E2E Contract

- **范围**: 虚拟开发板、SDL、引脚绑定、数字逻辑实验可视化。
- **上游**: digital_logic_experiment、SDL toolchain。
- **下游**: 实验外设 smoke。
- **L0 gate**: `nvboard-contract` 检查 README、Makefile 和 agent。
- **L1 gate**: 后续 example build/run smoke。
- **证据**: build log、SDL/window 状态、引脚绑定文件。
- **升级路线**: headless/SDL 两种 profile 分离。
