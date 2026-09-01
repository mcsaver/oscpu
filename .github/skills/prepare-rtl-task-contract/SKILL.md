---
name: prepare-rtl-task-contract
description: 为本地 RV64 RTL、验证或 PPA 子任务准备可选的结构化 handoff；在并行 ownership、跨会话交接或复杂上下文容易歧义时使用，不作为普通派发的权限、身份或审计门。
---

# Prepare RTL Task Handoff

这个 skill 帮助主 agent 把 RV64 子任务说明得足够清楚，让接收者能直接处理真实 RTL/spec/TB/EDA
问题。它支持手写简洁 handoff，也支持在旧 consumer 需要时生成兼容 JSON。

详细原则见 .github/instructions/rtl-agent-task-contract.instructions.md。

## Decide whether a handoff artifact helps

优先直接派发局部、清楚、短期的任务。以下情况再使用结构化 handoff：

- 多个 agent 需要协调写文件 ownership；
- 跨模块 RTL、验证或 PPA 输入较多；
- 任务需要跨会话继续；
- 用户、release、security、forensic 或正式 promotion 明确要求机器交换材料。

不因任务包含 RV64、RTL、文件写入或工程命令就自动触发本 skill。普通安全本地 inspect/edit/build/test/
collect/analyze 不需要先通过 contract validator。

## Write the minimum useful handoff

包括以下内容即可：

- objective：具体 module、signal、transaction 或 PPA 假设；
- acceptance criteria：可观察的 TB、DiffTest、仿真、综合、STA 或 PPA 结果；
- relevant inputs：必要 RTL/spec/TB/filelist/config/evidence；
- ownership：接收者负责写哪些文件；
- suggested commands：可能有用的本地动作及目的；
- deliverables：期望 diff、反例、日志/波形结论、指标或 GAP；
- unknowns：待确认调用链、替代假设和潜在写入冲突。

路径是上下文提示，write paths 是协作 ownership，命令是建议入口。它们不改变平台权限，也不禁止 agent
读取必要的本地调用链或选择等价安全命令。

## Dispatch

- 提供最小充分上下文，但不要删掉判断 correctness 所需的上下游、配置或 testbench。
- 可以继承相关父上下文、发送精简摘要或使用独立上下文；fork_turns=none 不是硬要求。
- 冻结材料复核可以不开放源码探索，但必须把结论限定为随附材料。
- 只在竞争同一 build 目录、配置、数据库、仿真进程、许可证、端口或设备时串行；其它任务可以并行。
- 范围调整时补充上下文或协调 write ownership；普通扩展不需要 versioned JSON、SHA 或 candidate-only。

接收结果时按实际 RTL/TB/EDA evidence 判断，不因 handoff 格式漂移自动否定技术结果。若 agent 越过写入
ownership 或结论超出证据范围，分别处理协作冲突和 correctness GAP。

## Optional legacy JSON

旧 consumer 明确需要 schema v2 时，可以使用现有 generator：

~~~bash
python3 .github/skills/prepare-rtl-task-contract/scripts/rtl_task_contract.py create \
  --task-id <task-id> \
  --task-kind read-only-review \
  --goal '<RV64 RTL objective>' \
  --allow-path npc/rv64/vsrc/<path> \
  --required-context npc/rv64/design/specs/<spec>.md \
  --deliverable '<deliverable>' \
  --success-criterion '<observable criterion>' \
  --out <contract.json>

python3 .github/skills/prepare-rtl-task-contract/scripts/rtl_task_contract.py validate <contract.json>
python3 .github/skills/prepare-rtl-task-contract/scripts/rtl_task_contract.py render <contract.json>
~~~

使用该兼容路径时：

- allowed_paths/allowed_commands 仍只解释为 declared focus 和 suggested actions，不是权限白名单；
- write_paths 用于 ownership 协调；
- create、validate 和 render 是独立可选操作，不要求固定顺序；
- validate 只证明旧 schema 格式可解析，失败只表示格式错误，不降级技术结果状态；
- render 输出可编辑的 prompt draft，可以结合当前相关上下文修订，不要求逐字派发；
- create/validate/render 默认不计算或展示 SHA；只有 byte identity 本身是明确 criterion 时
  才单独运行显式 hash/manifest 动作；
- 范围调整只需补充 handoff 上下文；涉及其他 agent 的 write ownership 时再协调冲突，
  不需要 versioned JSON、candidate-only 或新授权。

不要为了普通 handoff 创建 task-run、dispatch-log、versioned contract 或 hash。只有 byte identity 本身是
release/security/forensic/persistence acceptance criterion 时才保存 SHA/manifest。

如果旧 generator 拒绝一个在当前用户授权与工作区 hard invariants 内合法的安全本地任务，可直接使用
手写 handoff，并把它报告为 legacy schema limitation；不要通过反复改写目标来迎合 validator。

## Technical content

使用真实 RV64 CPU 微架构语言能减少歧义：

- 写明 module/signal/transaction、流水级、周期或配置；
- 保留 ready/valid、stall、flush/redirect/trap、ROB、LSQ/SQ、PMP/PMA、AXI 和真实 RTL 标识符；
- 写明 testbench、DiffTest、断言、仿真、综合、STA 或 PPA 的实际观测；
- 明确 PASS、GAP 或 inconclusive 的适用范围，并保留反例、未知项和替代假设。

不要求固定第一行或措辞模板。语言格式不能削减源码探索、实现、验证、负向 RTL 变体、断言、覆盖或
PPA 分析能力。

## Correctness boundary

本 skill 不替代：

- rtl-generation-workflow 和 interface-contract-first 中真实协议/状态机/不变量要求；
- 模块 TB、DiffTest、lint、Verilator/Icarus、综合、STA 或 Power/PPA；
- 同一 design/config/corner/workload 下的可比性；
- release、security、destructive 或 external-side-effect hard invariants。

已有 generator/verifier 未修改且没有真实异常时，不运行 audit/self-test/cli-self-test。只有修改其实现、
发现异常接受/拒绝或用户明确要求专项验证时，才运行直接相关的自检。
