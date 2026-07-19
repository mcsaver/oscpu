# NPC Agent

## RTL 生成强制工作流（最高优先级）

写或改任何 `npc/rv64` 可综合 Verilog 前，必须遵循
`.github/instructions/rtl-generation-workflow.instructions.md`（需求→协议+FSM+不变量+拓扑→RTL，六段留痕）。
其中触碰握手 / stall / flush·redirect·trap / 异常序 / 访存序 / 投机恢复 或跨模块的改动，
**先走阶段 0**：按 `.github/instructions/interface-contract-first.instructions.md` 冻结六类跨模块契约、
填满目标模块 SPEC-TEMPLATE §2/§3，并让能编码的契约过 `make -C npc/rv64 check-contract` gate（决策见 `decisions.md` [38]）。

## 默认开发环境

NPC 开发默认使用 NPC-only profile：

- 快速 NPC 合同：`scripts/agent-e2e.sh --profile npc-dev`

## 子 agent 任务契约

派发 `npc/rv64` RTL、验证或 PPA 子任务前，读取
`.github/instructions/rtl-agent-task-contract.instructions.md`，并用
`.github/skills/prepare-rtl-task-contract/` 生成、校验和渲染最小权限契约。只读复核必须限定路径、
命令和输出，禁止写文件、联网、账号、凭据和外部服务；实现任务必须显式列出可写文件并继续满足
RTL 四段式与接口契约硬门。

## RV64 PPA 持续优化

涉及双发射完整 OoO 核的性能、面积、时序或功耗时，必须读取
`.github/instructions/rv64-ppa-optimization-workflow.instructions.md` 与
`npc/rv64/design/arch/rv64-architecture-ppa-contract.md`；中间检查点只能留开发证据，不能进入全局 Pareto、seed 或 champion。

`npc-dev` 包含 `software-flow`、`npc-sim-contract`、`npc-single-contract`、`npc-soc-contract` 和 `npc-rv64-contract`。它不得包含 `nemu-dev`、`nemu-ubuntu`、`nemu-ubuntu-full-gate` 或 NEMU full Ubuntu gate。

## 软件流程

NPC 仿真、Verilator harness、RTL-adjacent C++、Linux boot/systemd 观察和 RV64 contract 都要先走 `software-flow` 的软件闭环，再按需要交给硬件或系统 gate。NPC 相关问题不要用 NEMU-only profile 证明完成；NEMU 问题也不要靠 NPC profile 混过去。

## 边界

- NPC-only 环境 bug 要修 `npc-dev` 和相关 module contract。
- 跨 NEMU/NPC/RV64 Linux 的集成验证继续使用旧集成 profile，例如 `nemu-ubuntu-full-gate` 或 `rv64-linux`。
- 当前 NPC Ubuntu/systemd 长门状态以 known-issues 为准，不因 NEMU full Ubuntu 进展自动关闭。
- （契约先行硬门槛）rv64 核改动若填不出受影响模块的接口/控制契约（§2/§3 的 flush「谁清谁保持」表、stall 语义、同拍优先级表出现填不出的格子），即视为尚未理解上下游业务，禁止落 RTL；先补齐契约或显式上升为“契约缺口”任务节点，不得先写 RTL 再撞死锁回填。
