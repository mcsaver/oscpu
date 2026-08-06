---
description: "本地 RV64 RTL 主/子 agent 任务范围契约。派发 Verilog/SystemVerilog 设计、审查、验证或 PPA 子任务前，必须显式声明工程领域、RTL/spec/TB/evidence 输入、输出路径、工程命令、产物与成功条件。"
applyTo: "npc/rv64/**"
---

# RTL Agent Task Contract

本规则解决任务描述歧义、工程范围过宽和节点状态误传播，不削弱任何 RTL 实现、验证或独立反例复核能力。适用于主 agent 向子 agent、并行 reviewer 或其它模型派发本地 RV64 RTL 设计、验证、PPA 和只读复核。子 agent 渲染提示使用 `rv64-hardware-professional` 措辞剖面；协调层状态只保留在 JSON、dispatch log 与主 agent 上下文中。

## 派发前硬门

每个子任务必须具备以下字段；缺任一项不得派发：

1. `engineering_domain`：固定为 `local-rv64-rtl`，正文说明是本地 Verilog/SystemVerilog 数字电路设计、验证或 PPA。
2. `task_kind`：`read-only-review | implementation | verification | ppa-analysis`。
3. `goal`：单一、可验证，不夹带父目标的全部历史。
4. `allowed_paths`：规范化的仓库相对路径集合；不含绝对路径、`..` 和工作区外路径。
5. `write_paths`：允许落盘的最小子集。`read-only-review` 必须为空；实现任务必须显式列出。
6. `allowed_commands`：每项固定为 `command/mode/purpose` 三元组；`mode` 只能是 `read-only` 或
   `write-within-scope`。任务只能选择 canonical command，`mode/purpose` 必须逐字匹配 canonical catalog，不能提交自由 purpose；中文用途标签也由 catalog 固定。详细意图只能放在 `goal/deliverables/success_criteria`，不会扩大命令集合。只读任务只接受 canonical 只读命令类，写型命令必须绑定非空 `write_paths`。未列出的命令不属于当前合同。
   默认使用 `workspace-files`；只有问题已经冻结、无需发现遗漏且只审查随附证据的限定材料复核，才允许
   `self-contained-no-tools` 使该数组为空。此时 `context.material_mode` 必须是
   `prompt-supplied-self-contained`，并由非空、单行的 `supplied_material` 承载全部可用事实。
7. `required_context`：完成该子任务真正需要的规则、spec、RTL/TB；以最小充分为准。原生 no-tools
   模式中的这些路径仅作 provenance，子 agent 不自行读取。不得为了缩小工程范围而删掉已知必要的
   上下游、调用链或证据来源；边界暂时未知时，先给模块级只读范围，再由结果收窄。
8. `deliverables` 与 `success_criteria`：分别声明输出和客观验收条件。
9. 工程输入边界：canonical v2 `scope` 只包含 `workspace_root/allowed_paths/write_paths/allowed_commands`，
   输入来源由 `allowed_paths` 精确表达；v1 扩展字段只用于历史 JSON 兼容，新派发不再生成。
10. 状态分流：当前节点未产出技术结论时只影响该节点；默认父目标保持 `active`。
11. 合同证据绑定：渲染提示必须同时给出 JSON 的仓库相对路径与该文件 SHA-256，并明确哈希只绑定该 JSON，不绑定设计 `contract.md` 或其它上下文。
12. WSL 调度：Windows/Codex 访问本 WSL 工作区时，工程 shell 为 single-flight；主 agent 可以把当前
    唯一 shell ownership 交给一个契约授权的子 agent，但该节点执行期间主 agent 与其它子 agent
    不得并发运行工程命令。ownership 只绑定合同中的一个有界命令批次；节点完成、GAP、异常或被中止时
    必须停止工程进程并明确归还。节点无响应时，主 agent 中止节点并从 Windows 进程表确认没有指向本
    工作区的 `wsl.exe` 工程进程后才可强制回收。只有无 shell 推理或自包含材料复核可以并行。
13. 硬件措辞剖面：`goal/deliverables/success_criteria/supplied_material` 直接使用 RV64 CPU 微架构、流水线、
    事务、时序、缓存一致性、验证或 PPA 术语；`render` 追加同一硬件语境前缀。反引号包裹的 RTL 标识符
    和 PMP、RISC-V 特权级、访问异常、内存保护、权限检查、store probe 等架构术语保持原样。合同验证器
    检查结构与证据绑定，不按单个自然语言词组裁剪合法任务，也不改变工具、shell、路径、上下文或推理能力。
14. 本地作用域开场：渲染提示首屏固定声明工作对象为本地 RV64 Verilog/SystemVerilog 处理器，工程输入、
    动作和产物覆盖合同授权的本地 RTL、spec、testbench、EDA 工具与生成证据。JSON 独立承载结构化边界。
15. 多义术语限定：自然语言首次使用可能跨领域解释的词时，补齐对象、层级、作用域和工程目的；例如
    “testbench 接口异常激励”“流水取消信号”“checkpoint 状态恢复”“load replay 生命周期”与
    “compile-success RTL source mutation”。这是语义完整性要求。
16. 字段级交互叙述：用户可见进度、子 agent 技术字段和终审摘要优先写明 `ARPROT[2]` instruction
    属性的 default-slave 选择、`ARVALID && !ARREADY` 周期的 `ARADDR/ARSIZE/ARPROT` 保持、
    `PmpChecker` 当前 halfword 的 2B EXEC 检查、PMEM 尾界 2B 读取边界 oracle，以及 lane0/lane1
    instruction fault 的 PC/cause/tval owner 生命周期。真实 module/signal/file/TB/log/schema 标识符
    原样保留；不得以措辞规范为理由减少工具、源码、负向 RTL 变体、断言、覆盖矩阵或成功条件。
17. 初始上下文隔离：本地 RV64 RTL 子 agent 必须以 `fork_turns="none"` 创建，并把通过校验的
    `render` 输出作为完整初始提示，不继承父任务完整对话历史。全部必要设计事实通过
    `allowed_paths`、`required_context` 或 `supplied_material` 提供；该规则不改变模型、推理、
    `workspace-files`、shell、实现、验证或 PPA 能力。
18. 最终回复证据顺序：子 agent 首段按“RV64 RTL 对象或本地证据文件 → 周期或编译配置 →
    testbench/EDA 观测 → PASS/GAP 范围”给出结论。本地 JSON 证据校验出现意外接受或拒绝时，必须
    写明具体 schema 字段、工作区相对路径、定向单测和返回结果；不得只给脱离处理器工程对象的泛化
    标签，也不得因此删除反例、未知项、原始日志 marker、真实文件名或范围扩展出口。
19. 精简技术提示：`render` 只输出本地 RV64 RTL/证据对象、合同路径与 SHA、输入/输出、工程命令、
    必读材料、交付、判定条件和技术回复格式。派发管线、父任务历史、措辞策略和协调状态只保留在
    JSON、dispatch log 与主 agent，不进入子 agent 技术提示。自由文本字段以具体
    module/signal/本地证据路径作主语；证据工具任务必须绑定 CPU 债务项、schema 字段、定向单测和
    返回码，不以泛化的软件校验活动作为任务主体。该分层不附加平台处理或关键词拒绝逻辑，也
    不改变工具、shell、路径、上下文或推理能力。

使用 `.github/skills/prepare-rtl-task-contract/SKILL.md` 和其中脚本生成、校验、渲染 JSON 契约。存在 task-run 时，契约保存到
`.github/task-runs/<run-id>/subagent-contracts/`，并在 `dispatch-log.md` 记录路径与 SHA-256；没有 task-run 的短任务也必须把渲染后的同等字段完整放进提示。
契约工具的仓库信任锚固定为脚本所在工作区；`--repo-root` 只允许显式重复同一 realpath，不能重绑定到工作区外伪根。
`create` 自动把输出 JSON 的精确路径加入 `allowed_paths`；旧 JSON 不含自路径时仍可校验和渲染。
`render` 从实际 JSON 文件计算证据绑定，禁止手工填写无路径 SHA 或把它与设计合同哈希混用。

## 主 agent 派发流程

1. 从当前图节点提取一个子目标，不把“持续优化完整 OoO/PPA”直接交给单个子 agent。
2. 创建契约并运行 `validate`；实现类任务还须把 `.github/instructions/rtl-generation-workflow.instructions.md` 放入 `required_context`。命令用 `--allow-read-command COMMAND` 或 `--allow-write-command COMMAND` 选择 catalog 项，不把完整 shell 片段或自定义 purpose 塞入命令字段。需要独立发现遗漏、追调用链或核对源码时默认使用 `workspace-files`。只有问题已经冻结且结论明确限定为随附材料时，才使用 `--self-contained-no-tools`，并以一个或多个 `--supplied-material '<单行事实>'` 提供完整材料；不得同时声明任何命令或写路径。
3. 新派发固定走 `create → validate → render`；主 agent 先用 `rv64-hardware-professional` 术语写清任务，
   再用 `render` 生成带硬件语境前缀的提示并原样派发，确认
   “合同 JSON 路径/合同 JSON SHA-256/只绑定该 JSON”三项齐全。主 agent 不另行改写边界，不用泛化动词替代
   可验证产物。JSON 未通过 validate、或提示手工漂移了工程范围/状态边界时，reviewer 输出只能记为
   `candidate-only`，不得进入下游硬证据。渲染提示只保留硬件任务语境、输入/输出范围和证据边界。
   创建子 agent 时固定使用 `fork_turns="none"`；若运行环境不支持该参数，则使用只包含渲染提示的新任务
   上下文。不要在渲染提示前后追加父任务历史摘要。
4. 派发后记录契约哈希。子 agent 若通过 `scope_extension_request` 请求扩大路径或命令，先返回主 agent，
   由主 agent决定是否创建新的 versioned 契约并重新 validate/render/绑定新 SHA；请求本身不改变当前
   节点范围，也不能在旧提示后口头追加。其它资料仍须拆成独立研究节点。
5. 接收结果时先审契约符合性，再审技术结论。越界结果不能作为下游硬依赖；需要时隔离为证据候选重新复核。
6. 文本反例不是验证证据。主 agent 必须把每个可操作反例映射到 spec/contract 修订，并至少落成
   定向 TB、compile-success mutation 或 fail-closed 静态审计之一；暂时无法落成时写入 task report
   的剩余风险，禁止只把 reviewer 的自然语言结论抄成 GREEN。
7. 仅当限定材料复核比源码探索更符合任务目标时，才生成原生 `prompt-supplied-self-contained`
   契约：JSON 精确声明 `allowed_commands=[]`、`write_paths=[]`，渲染提示声明只消费内嵌的
   `supplied_material`、不执行工程命令或仓库读取。该模式只能称为
   “限定材料复核”，不得宣称完整独立仓库审查，也不得用于证明不存在未随附的实现或证据。不得用
   “实际执行比 JSON 上限更窄”的口头约束代替机器可校验工程边界。

## 能力分档与推理出口

1. **默认只读探索**：`workspace-files + read-only-review`。用于阅读源码/spec、追踪必要调用链、寻找遗漏和
   独立反例；路径以模块级最小充分范围为起点，不默认退化成单文件或主 agent 摘要复述。
2. **限定材料复核**：`prompt-supplied-self-contained`。只用于冻结问题、固定证据摘要或第二遍逻辑检查；
   不具备源码独立性，不能替代 workspace review、TB、波形、综合或 STA。
3. **实现/验证/PPA 执行**：使用对应 `task_kind`，显式声明写路径和 write-scoped 命令；实现、验证和记录
   仍按图依赖串行推进，但不得因模板惯性一律降级为只读 reviewer。

所有分档都必须保留以下出口：`unknowns`、显式假设、反例、替代假设、`scope_extension_request`、
`confidence_and_basis`。信息不足时允许 `inconclusive`，禁止强制 PASS，也不得设置固定 blocker/发现数量
上限；可以按严重度排序，但不能截断仍影响结论的事项。新生成的 canonical 合同若在
`goal/deliverables/success_criteria` 中出现“最多 N 个反例/问题”或等价固定上限，校验器必须拒绝。
旧版仅含 `required_files` 的 context 只为历史证据保持 validate/render 兼容，不得直接复用为新派发模板。

## 领域措辞

- 任务目标、交付和成功条件要能回答四个问题：作用于哪个 module/signal/transaction，位于哪个流水级、
  特权级或存储层级，覆盖哪些 path/cycle/config，以及用来实现或验证什么工程性质。
- 保留真实标识符，例如 `kill_valid_i`、`flush_i`、`commit_valid_o`；在正文首次出现可能跨领域歧义的
  术语时补足“流水取消/分支恢复/退休资格”等硬件上下文，不改名、不改变信号语义，也不建立关键词黑名单。
- 审查动作写成“独立反例复核”；“mutation killed”写成“定向变异被测试检出”；“kill younger”写成“取消更年轻流水事务”；身份相关内容写成“生产者归属/事务标签/完成资格”。
- 描述 producer result 时使用“producer completion eligibility/生产者完成资格”；这只规范任务自然语言，不重命名已有文件、task id 或 RTL 标识符。
- 对 IFU/AXI/PMP 交互，不使用脱离信号的简称：写成“`ARPROT[2]` instruction 属性选择 default slave”、
  “AR 通道反压周期保持 `ARADDR/ARSIZE/ARPROT`”、“PMEM 尾界 2B 读取边界 oracle”、
  “编译成功的负向 RTL 变体被指定 testbench/断言检出”和“lane0/lane1 fetch-fault owner 生命周期”。
  真实测试名或日志 marker 即使沿用历史命名也必须原样引用，并在邻近正文说明其硬件含义。
- 不因术语消歧弱化审查：假绿、越级结论、合同外写入和验证覆盖洞仍必须明确指出。
- 技术目标完整写明真实 RTL 动作、对象、层级、周期条件和工程目的；JSON 独立承载机器可审计边界。
- 子 agent 最终回复第一行使用
  `RV64 RTL 结论｜对象=<module/signal/本地证据路径>｜周期/配置=<cycle/config>｜TB/EDA 观测=<结果>｜范围=<PASS/GAP/inconclusive>`。
  证据校验器的意外接受或拒绝必须关联 CPU 证据对象、具体 schema 字段、工作区相对路径、定向单测和
  返回码，不得只写泛化分类。
- 结构化边界在 JSON 字段中表达一次；`goal/deliverables/success_criteria/supplied_material` 使用正向
  本地 RV64 作用域，协调层说明进入 dispatch log。该分层不得删除任何真实硬件术语、工程命令或验证反例。
- `workspace-files`、no-tools、实现、验证和 PPA 的既有能力分档保持不变；不得以措辞规范为理由删减独立源码探索、必要命令、未知项、替代假设或范围扩展出口。

## 节点状态分流

1. 未产出技术结论的当前子任务记为 `review_pending`；该状态由主 agent 记录，不追加到子 agent 渲染提示。
2. 保存原始请求、契约 JSON 与 SHA-256、时间和已完成的本地 RTL 证据。
3. 其它合同内 RTL 节点继续推进；单一节点状态不自动改变长期父目标。
4. 协调记录进入 task-run，不进入 RTL 正确性证据。

## 模板

只读 reviewer 的最小提示必须明确：合同 JSON 路径与 SHA、RTL/spec/TB/evidence 输入、只读工程命令、反例与证据交付、是否持有 shell ownership，以及上述推理出口。原生 no-tools 模式还必须让 JSON 的命令数组为空、把来源路径标为 provenance、直接附上完整冻结材料，并明确它只是限定材料复核。实现者除上述字段外，还必须列出可写文件、RTL 四段式与验证命令。不得使用“自行查看整个仓库”“按需修改任何文件”或“使用所有必要工具”等无限边界表述。

## 结论边界

任务契约通过只证明派发范围清晰且机器可校验；不证明子 agent 的技术结论正确，也不替代 `npc-dev`、模块 TB、DiffTest、lint、综合、STA、Power 或 Pareto gate。
