---
name: prepare-rtl-task-contract
description: 为本地 RV64 Verilog/SystemVerilog 设计、探索式只读复核、冻结材料复核、实现、验证或 PPA 子任务生成并校验最小充分工程契约，并渲染 RV64 微架构专业提示，同时保留未知项、反例、替代假设和范围扩展出口。主 agent 准备派发子 agent、限定 RTL/spec/TB/evidence、工程命令与输出，或需要保持原始 RTL 语义时使用。
---

# Prepare RTL Task Contract

在派发本地 RTL 子任务前，先把目标、RTL 输入、输出路径、工程命令、产物和成功条件收敛为机器可校验的 JSON，再把同一份契约渲染成子 agent 提示。详细规则以
`.github/instructions/rtl-agent-task-contract.instructions.md` 为准。

主 agent 对 `goal/deliverables/success_criteria/supplied_material` 直接使用
`rv64-hardware-professional` 术语；`render` 生成精简的硬件事实提示，首行直接给出本地 RV64
module/signal/证据文件、周期或编译配置、testbench/EDA 观测和 PASS/GAP 边界。协调状态、派发管线、
父任务历史和措辞策略只保留在 JSON、dispatch log 与主 agent 记录中，不进入子 agent 渲染提示。
该措辞剖面不建立关键词黑名单、不拒绝单个词组，也不改变任何工具、shell、路径或推理能力。规范与保留词见
[`.github/agentic-hardware-blueprint.md`](../../agentic-hardware-blueprint.md#rv64-hardware-professional-task-wording)。
RV64 领域示例与术语限定见
[`npc/rv64/design/arch/rv64-hardware-wording-profile.md`](../../../npc/rv64/design/arch/rv64-hardware-wording-profile.md)。

技术叙述与机器边界必须分层：JSON 的 scope/status/language 字段保留完整工程边界；
`goal`、`deliverables`、`success_criteria`、`supplied_material` 只承载本地 RV64 RTL 工程事实，
不得重复协调层或平台层说明。使用一次正向本地作用域开场即可；这不删减任何真实硬件术语、
命令、上下文、反例或范围扩展出口。

新建合同使用 schema v2；`scope` 精确包含
`workspace_root/allowed_paths/write_paths/allowed_commands`。schema v1 仅用于历史 JSON 的
validate/render 兼容，不作为新派发模板。

自然语言字段以具体处理器对象作主语。若任务检查 Python/JSON 证据工具，也要写成“`OooRob`
`CONTROL-EVENT-G1` 本地证据文件中的 `architecture_hard_gates.result.path` 字段，经
`CurrentWorkspaceTests.test_...` 运行后应返回非零/GAP”，而不是把泛化的校验器、引用拓扑或输入空间
探索写成任务主体。真实脚本名、schema 字段、返回码与负向 fixture 仍原样保留在合同和结果中。

## 工作流

1. 只给子任务所需的最小充分上下文；不附带整轮历史或无关日志，也不删掉已知必要的上下游、调用链
   或证据来源。范围尚未收敛时，从模块级只读输入集合开始。
2. 用脚本创建契约。只读复核使用 `read-only-review`，落盘实现使用 `implementation`，验证与 PPA 分别使用 `verification`、`ppa-analysis`。

```bash
python3 .github/skills/prepare-rtl-task-contract/scripts/rtl_task_contract.py create \
  --task-id <task-id> \
  --task-kind read-only-review \
  --goal '<可验证目标>' \
  --allow-path npc/rv64/vsrc/<path> \
  --allow-read-command rg \
  --allow-read-command sed \
  --required-context npc/rv64/design/specs/<spec>.md \
  --deliverable '<输出内容>' \
  --success-criterion '<客观成功条件>' \
  --out .github/task-runs/<run-id>/subagent-contracts/<task-id>.json
```

3. 校验并渲染；新派发必须走 canonical `create → validate → render`，把渲染结果原样放进子 agent
提示，不要另写一份可能漂移的边界说明。历史 JSON 只保留 validate/render 兼容，不作为新模板。
创建本地 RV64 RTL 子 agent 时使用 `fork_turns="none"`，使通过校验的渲染结果成为完整初始提示；
全部必要设计事实放入 `allowed_paths`、`required_context` 或 `supplied_material`，不要继承父任务完整
对话历史。该上下文隔离不改变模型、推理、源码探索、shell、实现、验证或 PPA 能力。
`create` 会把输出 JSON 自身的仓库相对路径加入 `allowed_paths`；`render` 会从实际文件自动写出
该 JSON 的路径与 SHA-256，并明确该哈希只绑定 JSON，不绑定设计 spec、`contract.md`、RTL 或测试。
不要手工补一条无文件名的 SHA，也不要让子 agent 猜测它绑定哪个合同。
JSON 未通过 validate、或派发文本手工改写了渲染后的工程范围/状态边界时，该轮结果只能登记为
`candidate-only`，不得成为下游硬证据。`scope_extension_request` 必须生成新的 versioned JSON，
重新 validate/render 并绑定新 SHA；不能在旧提示后口头追加范围。

自然语言字段必须使用硬件专业语义。例如用“独立反例复核”“定向变异被测试检出”“取消更年轻流水事务”
和“生产者完成资格”，不把协调层状态或改变平台处理结果写成 RTL 子任务目标。反引号包裹的真实 RTL
标识符不参与措辞替换，`kill_valid_i`、PMP、RISC-V 特权级、访问异常、内存保护、权限检查和
store probe 等合法架构术语必须保留。

子 agent 最终回复第一行使用
`RV64 RTL 结论｜对象=<module/signal/本地证据路径>｜周期/配置=<cycle/config>｜TB/EDA 观测=<结果>｜范围=<PASS/GAP/inconclusive>`。
若本地 JSON 证据校验出现意外接受或拒绝，直接写明 CPU 证据对象、具体 schema 字段、工作区相对路径、
定向单测和返回码。该顺序不得删除反例、未知项、替代假设、原始日志 marker、真实文件名或
`scope_extension_request`。

用户可见进度、子 agent 的 `goal/deliverables/success_criteria/supplied_material` 与终审摘要应优先写成
可直接对应 RTL 的字段级事实：

- `ARPROT[2]` 的 instruction 属性如何参与 `AxiXbar` default-slave 选择；
- `ARVALID && !ARREADY` 周期内 `ARADDR/ARSIZE/ARPROT` 如何由已锁存 transaction owner 保持；
- `PmpChecker` 对当前 instruction halfword 的 2B EXEC 检查，以及 PMEM 尾界 2B 读取的边界 oracle；
- 编译成功的负向 RTL 变体由哪个定向 testbench 标记或断言检出；
- lane0/lane1 instruction page/access fault 的 PC、cause、tval owner 如何经过 capture、pending 与 drain。

真实文件名、module/signal 名、testbench 名、日志 marker 和 JSON schema 字段保持原样；这些标识符可以
包含历史命名。字段级叙述只提高可判别性，不删减源码探索、实现工具、负向 RTL 变体、断言、覆盖矩阵
或任何成功条件。

首次出现多义术语时，明确 module/signal/transaction、pipeline/privilege/memory level、path/cycle/config
范围，并补齐对象、层级、作用域和工程目的。例如写“testbench 在 `OooLoadQueue` response 接口第 N 拍施加异常激励”，或
“编译成功的负向 RTL 变体删除 final-PA query 的 exact-ProducerId 条件，并由指定 directed oracle
检出”。不要用缩写、代称、拆分描述或模糊动词隐藏真实工程动作；这条规则不扫描或拒绝单个词。

```bash
python3 .github/skills/prepare-rtl-task-contract/scripts/rtl_task_contract.py validate <contract.json>
python3 .github/skills/prepare-rtl-task-contract/scripts/rtl_task_contract.py render <contract.json>
```

工程命令不是自由文本。`--allow-read-command` 与 `--allow-write-command` 只接收 canonical `COMMAND`；
生成器从 JSON catalog 填入固定的 `mode/purpose` 枚举和中文标签，任务不能自定义 purpose。详细意图写在
`goal/deliverables/success_criteria`，不会增加命令变体。只读任务只允许 canonical 只读命令类，写型命令必须同时声明最小 `write_paths`。工具的 repo realpath 固定为本 skill 所在工作区，
`--repo-root` 不能改绑到其它目录。

需要发现遗漏、核对源码或追踪调用链的 reviewer 默认使用 `workspace-files`。只有问题已经冻结、无需
发现未随附事实且结论明确限定为给定证据时，才使用原生 no-tools 模式；不要给 JSON 虚列 `rg` 或
`sed` 再在提示中口头收紧。每个 `--supplied-material` 是一条单行工程事实，渲染后就是子 agent
可见的全部材料；来源路径仅保留为 provenance。

```bash
python3 .github/skills/prepare-rtl-task-contract/scripts/rtl_task_contract.py create \
  --task-id <task-id> \
  --task-kind read-only-review \
  --goal '<只依据随附事实完成的可验证复核>' \
  --allow-path npc/rv64/design/specs/<spec>.md \
  --self-contained-no-tools \
  --supplied-material '<单行事实 1>' \
  --supplied-material '<单行事实 2>' \
  --deliverable '<结构化复核结论>' \
  --success-criterion '<明确 PASS/GAP 及反例>' \
  --out .github/task-runs/<run-id>/subagent-contracts/<task-id>.json
```

该模式的校验结果必须精确为 `context.material_mode=prompt-supplied-self-contained`、
`allowed_commands=[]`、`write_paths=[]`，并拒绝非只读任务、缺失材料、任何命令、任何写路径或多行材料。
它只能称为“限定材料复核”，不能冒充完整独立仓库审查，也不能证明未随附事实不存在。

4. 在 `dispatch-log.md` 逐字记录渲染结果中的 JSON 路径和 SHA-256。子 agent 返回后，对照契约检查输入文件、RTL/证据输出、工程命令和缺失产物；需扩展范围时生成新版本契约，不在原提示后模糊追加。若误用了未校验合同，保留原始候选结果和失败原因，再以新 SHA 复核；不得把候选 PASS 追认为正式 PASS。
5. 若平台暂不展示或不处理某个合法 RTL 子任务，由主 agent 把该节点记为 `review_pending`，保留原始请求、契约哈希、时间和平台提示；该协调状态不得追加到子 agent 渲染提示，不得通过改变 RTL 语义来重试，也不得据此关闭长期父目标。
6. 将 reviewer 的每个可操作反例登记到 `dispatch-log.md`，并转成 spec 修订加定向 TB、
   compile-success mutation 或 fail-closed 静态审计；文本反例本身不能作为 GREEN 证据。若冻结摘要
   已充分且任务只需冻结材料复核，可以派发原生 `self-contained-no-tools` 契约，使该节点只消费提示
   中的 RTL 事实、不执行工程命令或仓库读取。

## 能力分档

- 默认只读探索：`workspace-files + read-only-review`，允许在模块级白名单内自主寻找遗漏、反例和必要调用链。
- 限定材料复核：`prompt-supplied-self-contained`，只用于冻结事实的第二遍逻辑检查。
- 实现/验证/PPA：使用相应 `task_kind`，显式声明最小写路径和 write-scoped 命令；不要因模板惯性一律
  降级为只读 reviewer。

措辞剖面与能力分档正交：不得为了获得“更像硬件”的文本而删减必要上下文、工具、反例出口或实现/验证能力。

渲染提示必须允许子 agent 报告 `unknowns`、显式假设、反例、替代假设、
`scope_extension_request` 与 `confidence_and_basis`。信息不足时允许 `inconclusive`，禁止强制 PASS；
不得设置固定 blocker/发现数量上限。新 canonical 合同中的“最多 N 个反例/问题”及等价写法必须由
校验器拒绝；旧 context 只为历史证据保持兼容，不作为新派发模板。范围扩展请求只说明需要什么及
原因，不自动改变当前节点范围。

## 边界

- 工程领域固定为本地 RV64 Verilog/SystemVerilog 数字电路设计、验证或 PPA。
- 工程输入固定为合同列出的本地 RTL/spec/TB/evidence；其它资料不属于该 RTL 节点，确有需要时另建研究节点。
- Windows/Codex 经 WSL 访问本仓库时，工程 shell 按 single-flight 串行调度；主 agent 可以把当前唯一
  shell ownership 交给一个契约授权的子 agent，该节点执行期间其它 agent 不运行工程命令。无 shell
  推理或自包含材料复核仍可并行。
- 真实 RTL 标识符保持代码格式；任务自然语言统一使用微架构、流水线、事务、时序、缓存一致性、验证或
  PPA 术语。不建立关键词黑名单，不因单个词组拒绝合同，也不改变原始技术含义。
- 本 skill 只规范任务边界和证据，不替代 RTL 四段式、接口契约、功能回归、综合/STA 或 PPA hard gate。

## 自检

```bash
python3 .github/skills/prepare-rtl-task-contract/scripts/rtl_task_contract.py audit
python3 .github/skills/prepare-rtl-task-contract/scripts/rtl_task_contract.py self-test
python3 .github/skills/prepare-rtl-task-contract/scripts/rtl_task_contract.py cli-self-test
```
