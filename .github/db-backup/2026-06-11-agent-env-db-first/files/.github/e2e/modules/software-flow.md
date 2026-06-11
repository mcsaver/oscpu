# software-flow E2E Contract

- **范围**: 软件需求、脚本/工具链、NEMU/AM/am-kernels/Linux guest check、host side C/C++/Python/Shell/Make/Kconfig 的全流程编排；覆盖 NEMU 这类软件硬件模型与硬件/系统 gate 的组合使用。
- **上游**: 用户需求、模块 memory、现有 Makefile/Kconfig/e2e profile、相关模块 agent。
- **下游**: `nemu`、`abstract-machine`、`am-kernels`、`fceux-am`、`rv64-linux`、`linux-device`、`hardware-flow`、`difftest` 与 `agent-system`。
- **L0 gate**: `software-flow-contract` 检查 agent、模块记忆、profile、e2e 合约入口，以及 `hardware-aware-software-loop` 是否接入 software-flow、hardware-flow、nemu、coordinator、蓝图和 e2e workflow。该 gate 还硬检查 soft-flow 方法论本体：`software-dev-loop`、`software-bugfix-loop`、`software-refactor-loop`、`hardware-aware-software-loop` 的节点序列必须保留，`scope-contract/design-plan/unit-or-contract-test/integration-smoke/regression-or-e2e/hardware-semantic-contract/system-or-hardware-gate/review-record` 等节点产物必须保留，并检查“不把构建通过单独当成完成”“不把脚本外层退出码当唯一证据”“必须扫描 FAIL marker”“完成后更新 software-flow memory”等反假完成约束。
- **L1 gate**: `software-flow` profile 证明软开 agent 可被单独发现，并证明 NEMU/系统 bring-up 类 C/Python/Shell/Make/Kconfig 开发会叠加 software-flow；`nemu-ubuntu` profile 已显式 include `software-flow`，因此每次 NEMU Ubuntu 切片生产守门都会先执行软开合约；`contracts` profile 证明它进入全模块 contract 集合。
- **证据**: profile manifest、contract gate 输出、task-run 节点表和软件验证命令摘要。
- **升级路线**: 增加软件任务类型到 profile 的映射表，并把稳定的软件回归矩阵升级为专用 smoke gate；后续可继续让 `nemu` 基础 profile、Linux tools profile 或具体软件回归矩阵显式 include `software-flow-contract`。
