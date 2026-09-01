# NEMU Agent

## 可选 E2E 场景

普通 NEMU 局部开发优先使用直接相关的构建、单测和 focused make 入口。需要显式端到端场景时选择：

- 快速 NEMU 开发合同：`scripts/agent-e2e.sh --profile nemu-dev`
- NEMU focused gate：`scripts/agent-e2e.sh --profile nemu-dev-gate`
- NEMU full Ubuntu 22.04 gate：`AGENT_E2E_NEMU_UBUNTU_FULL_GATE=1 scripts/agent-e2e.sh --profile nemu-dev-full-gate`
- NEMU full soak：`AGENT_E2E_NEMU_UBUNTU_FULL_SOAK_GATE=1 scripts/agent-e2e.sh --profile nemu-dev-full-soak`
- NEMU full Ubuntu 性能 profile：`AGENT_E2E_NEMU_PROFILE_GATE=1 scripts/agent-e2e.sh --profile nemu-ubuntu-profile`

`nemu-dev*` 不应意外包含 `rv64-linux` 或 `npc-*` 节点；跨 NEMU/NPC/RV64 Linux 集成验证使用显式
`nemu-ubuntu-integrated` profile。profile 是特定工程 claim 的验证入口，不是所有 NEMU 编辑的默认门。

## 软件流程

NEMU 是用 C/Python/Shell/Make/Kconfig 写出的硬件和系统模型。跨 guest/设备/harness 的复杂任务可参考
`software-flow` 的 hardware-aware 原则，但不要求套固定阶段。先明确硬件语义和 acceptance criteria，再在
正确抽象层实现并运行最小充分的 focused test 或系统场景。

完成判定不能只看构建通过或外层退出码；运行 guest 场景时应结合适用的 guest marker、BAD/GOOD TRAP、
`__NEMU_CHECK_FAIL__` 负向扫描和 terminal 状态。task-run 只用于显式持久化，memory 只更新稳定事实，二者
不参与普通工程 PASS 的必要条件。

## 稳定边界

- NEMU-only 环境问题优先在直接 focused make/test 或选定的 `nemu-dev*` 场景中定位，不从
  `.github/db-backup` 或历史 task-run 绕过当前源码与环境。
- NPC/RTL/systemd 集成结论不能从 NEMU-only 结果外推；只在 acceptance criterion 需要跨栈时
  运行 `nemu-ubuntu-integrated` 或对应直接集成命令。
- 当前 blocker、历史性能数字和一次性调试开关属于 memory/known-issues 或模块调试文档，不固化为
  agent personality 的永久前置。
