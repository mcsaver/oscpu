# NPC Agent

## RTL 实现与接口正确性

写或改 `npc/rv64` 可综合 Verilog 时遵循
`.github/instructions/rtl-generation-workflow.instructions.md` 的真实接口、结构和最小验证原则。触碰握手、
stall、flush/redirect/trap、异常/访存序、投机恢复或跨模块事务时，确认 transaction ownership、payload
hold 与同拍优先级；已有 contract 足够时直接使用，含义缺失时再修订 SPEC/断言并运行相关
`make -C npc/rv64 check-contract`。不要求六段留痕或固定阶段后才允许编辑。

## 可选 E2E 场景

普通局部 NPC 开发使用直接相关 lint/build/TB/sim。需要显式 NPC-only 端到端场景时使用：

- 快速 NPC 合同：`scripts/agent-e2e.sh --profile npc-dev`

## 子 agent 任务契约

复杂、并行或跨会话的 `npc/rv64` RTL/验证/PPA 子任务可以用
`.github/instructions/rtl-agent-task-contract.instructions.md` 和 prepare skill 组织 objective、RTL/spec/TB、
write ownership、建议命令与 acceptance criteria。它是可选 handoff，不是路径/命令权限白名单，也不要求
SHA、固定 fork 模式或逐字 render。局部任务直接派发，并允许检查判断 root cause 所需的调用链。

## RV64 PPA 持续优化

准备对双发射完整 OoO 核作全局性能、面积、时序、功耗或正式 promotion 结论时，读取
`.github/instructions/rv64-ppa-optimization-workflow.instructions.md` 与
`npc/rv64/design/arch/rv64-architecture-ppa-contract.md`；中间检查点只能留开发证据，不能进入全局 Pareto、seed 或 champion。

`npc-dev` 只包含 `npc-sim-contract`、`npc-single-contract`、`npc-soc-contract` 和 `npc-rv64-contract`；它不把
`software-flow` 方法检查注入业务验证，也不得包含 `nemu-dev`、`nemu-ubuntu`、`nemu-ubuntu-full-gate`
或 NEMU full Ubuntu gate。

## 软件流程

NPC 仿真、Verilator harness、RTL-adjacent C++ 和 Linux host 工具遵循 `software-flow` 的 root-cause 与
focused-test 原则，不要求先完成固定软件流程记录。NPC 相关问题不能用 NEMU-only profile 证明完成；
NEMU reference 也不能靠 NPC profile 混过去。

## 边界

- NPC-only 环境 bug 要修 `npc-dev` 和相关 module contract。
- 跨 NEMU/NPC/RV64 Linux 的集成验证继续使用旧集成 profile，例如 `nemu-ubuntu-full-gate` 或 `rv64-linux`。
- NPC Ubuntu/systemd 的 known-issues 仅作历史线索；当前状态以实际 worktree、runner/config 和最近直接
  evidence 为准。NEMU-only 进展不能自动关闭 NPC GAP。
- rv64 核改动若还无法解释受影响接口的 flush/stall/同拍优先级，就先读取上下游、波形或已有 spec，直到
  能提出可检验假设；必要时补契约或定向 assertion。是否先做小型 RTL/TB 探针由可逆性和诊断价值决定，
  不把表格填写或任务节点状态当作编辑权限。
