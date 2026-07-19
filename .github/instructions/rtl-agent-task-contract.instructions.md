---
description: "本地 RV64 RTL 主/子 agent 任务范围契约。派发 Verilog/SystemVerilog 设计、审查、验证或 PPA 子任务前，必须显式声明工程领域、允许路径、读写权限、命令、产物、成功条件与外部访问边界。"
applyTo: "npc/rv64/**"
---

# RTL Agent Task Contract

本规则解决的是任务描述歧义、权限过宽和受阻状态误传播，不改变任何平台检查，也不削弱工程审查。适用于主 agent 向子 agent、并行 reviewer 或其它模型派发本地 RV64 RTL 设计、验证、PPA 和只读复核。

## 派发前硬门

每个子任务必须具备以下字段；缺任一项不得派发：

1. `engineering_domain`：固定为 `local-rv64-rtl`，正文说明是本地 Verilog/SystemVerilog 数字电路设计、验证或 PPA。
2. `task_kind`：`read-only-review | implementation | verification | ppa-analysis`。
3. `goal`：单一、可验证，不夹带父目标的全部历史。
4. `allowed_paths`：仓库相对路径白名单；禁止绝对路径、`..` 和工作区外路径。
5. `write_paths`：允许落盘的最小子集。`read-only-review` 必须为空；实现任务必须显式列出。
6. `allowed_commands`：每项固定为 `command/mode/purpose` 三元组；`mode` 只能是 `read-only` 或
   `write-within-scope`。任务只能选择 canonical command，`mode/purpose` 必须逐字匹配 canonical catalog，不能提交自由 purpose；中文用途标签也由 catalog 固定。详细意图只能放在 `goal/deliverables/success_criteria`，不会扩大命令权限。只读任务只接受 canonical 只读命令类，写型命令必须绑定非空 `write_paths`。未列出的命令不自动获得许可。
7. `required_context`：完成该子任务真正需要的规则、spec、RTL/TB；以最小充分为准。
8. `deliverables` 与 `success_criteria`：分别声明输出和客观验收条件。
9. 外部访问边界：`network/accounts/credentials/external_services` 全部为 `false`。外部研究必须另建节点。
10. 状态分流：平台 review 只影响当前子任务；默认父目标保持 `active`。

使用 `.github/skills/prepare-rtl-task-contract/SKILL.md` 和其中脚本生成、校验、渲染 JSON 契约。存在 task-run 时，契约保存到
`.github/task-runs/<run-id>/subagent-contracts/`，并在 `dispatch-log.md` 记录路径与 SHA-256；没有 task-run 的短任务也必须把渲染后的同等字段完整放进提示。
契约工具的仓库信任锚固定为脚本所在工作区；`--repo-root` 只允许显式重复同一 realpath，不能重绑定到工作区外伪根。

## 主 agent 派发流程

1. 从当前图节点提取一个子目标，不把“持续优化完整 OoO/PPA”直接交给单个子 agent。
2. 创建契约并运行 `validate`；实现类任务还须把 `.github/instructions/rtl-generation-workflow.instructions.md` 放入 `required_context`。命令用 `--allow-read-command COMMAND` 或 `--allow-write-command COMMAND` 选择 catalog 项，不把完整 shell 片段或自定义 purpose 塞入权限字段。
3. 用 `render` 生成提示；主 agent 不另行改写边界，不用泛化动词替代可验证产物。
4. 派发后记录契约哈希。子 agent 若请求扩大路径、写权限或外部访问，先返回主 agent，由主 agent决定是否创建新版本契约。
5. 接收结果时先审契约符合性，再审技术结论。越界结果不能作为下游硬依赖；需要时隔离为证据候选重新复核。

## 领域措辞

- 保留真实标识符，例如 `kill_valid_i`、`flush_i`、`commit_valid_o`；在正文中补足“流水取消/分支恢复/退休资格”等硬件上下文，不改名、不改变信号语义。
- “攻击反例”写成“独立反例复核”；“mutation killed”写成“定向变异被测试检出”；“kill younger”写成“取消更年轻流水事务”；身份相关内容写成“生产者归属/事务标签/完成资格”。
- 不把减少平台检查、改变分类结果或绕开审查写成工程目标。目标只能是准确描述本地工作、最小权限和可审计证据。
- 不因术语消歧弱化审查：假绿、越级结论、未授权写入和验证覆盖洞仍必须明确指出。

## 受阻分流

平台暂不展示或不处理内容时：

1. 当前子任务进入 `review_pending`，停止重复提交同一请求。
2. 保存原始请求、契约 JSON 与 SHA-256、平台提示/截图、时间和已完成本地证据；不得只保存改写后的版本。
3. 不通过改变 RTL 信号含义、删去必要验证语义或伪装任务目的来重试。可在不改变目标的前提下补足真实工程上下文。
4. 有其它安全且已授权的本地节点时继续推进；没有时，把当前节点记为 blocker。单一子任务的 review 不自动把长期父目标改成 completed 或 global blocked。
5. 对明显误判使用产品官方反馈渠道；反馈记录进入 task-run，不进入 RTL 正确性证据。

## 模板

只读 reviewer 的最小提示必须明确：指定路径、只读、禁止联网/账号/凭据/外部服务、输出反例与证据，不修改文件。实现者除上述字段外，还必须列出可写文件、RTL 四段式与验证命令。不得使用“自行查看整个仓库”“按需修改任何文件”或“使用所有必要工具”等无限边界表述。

## 结论边界

任务契约通过只证明派发范围清晰且机器可校验；不证明子 agent 的技术结论正确，也不替代 `npc-dev`、模块 TB、DiffTest、lint、综合、STA、Power 或 Pareto gate。
