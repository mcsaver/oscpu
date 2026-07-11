# Profile Resolve

规划阶段不执行业务 profile，只冻结后续证据闭包：

- `npc-dev`: NPC workspace contract；不能证明 RTL 功能或时序；
- `difftest`: current RTL 逐退休状态对拍；
- `rv64-linux`: current OpenSBI/Linux/Ubuntu 分层 gate；
- `verilator-tapeout`: 仿真真实性与可综合边界；
- `yosys-sta`: 综合/STA 工具合同；不能替代正式 5 ns 报告；
- `agent-system`: 仅在本轮修改 `.github` 规则/DB 边界时需要。

最终 strict guard 仍按实际触碰路径选择 fresh profiles。
