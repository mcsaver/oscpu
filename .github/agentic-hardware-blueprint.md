# YSYX AI 驱动硬件开发环境蓝图

## 目标

- 把当前工作区从“模块专家集合”升级为“图任务调度 + 工作流 agent + 模块专家执行 + 经验沉淀”的 AI 驱动硬件开发环境。
- 先围绕当前工作区真正可执行的后端建立闭环：`NEMU + AbstractMachine + am-kernels`。
- `NPC/Verilator` 与 `difftest` 在目标实现后再作为下游节点接入。
- 真实 EDA 工具后续作为新节点加入，不阻塞当前设计、验证与 bring-up 环境搭建。

## Marco 思想在本工作区的映射

| Marco 思想 | YSYX 的落地方式 |
| ----------- | ---------------- |
| Graph-based task solving | 先选静态图模板，再按当前任务动态扩图 |
| Agent config per sub-task | 每个节点指定 owner agent、输入、输出、成功标准与回退策略 |
| Tool / skill config | 每个节点都绑定当前可用工具：Make、NEMU、Verilator、日志、study 笔记 |
| Memory / knowledge base | `.github/memory/`、`npc/single/design/study/`、README、Makefile、已有构建脚本 |
| Iterative self-debug | 采用“构建 → 运行 → 对比 → 定位 → 修复 → 回归”的循环，而不是一次性生成后结束 |

## 当前真实后端

- 当前默认后端：
  - `am-kernels`：测试与最小工作负载入口
  - `abstract-machine`：平台抽象、链接脚本、镜像封装
  - `nemu`：参考模型、设备模型、trace / watchpoint / batch 调试入口
- 未来接入节点：
  - `npc/single` + `Verilator`：目标 RTL 仿真后端
  - `difftest`：参考对比层
  - `yosys-sta`：后续阶段的综合 / 时序节点

## 图节点契约

每个任务节点至少包含以下字段：

```yaml
node_id:
goal:
owner_agent:
depends_on:
inputs:
outputs:
success_criteria:
fallback:
evidence:
```

其中：

- `inputs` 要明确依赖的源码、笔记、镜像、日志或配置
- `outputs` 要明确交付给下游节点的产物
- `success_criteria` 不能只写“完成”，要写可验证结果
- `fallback` 用来说明失败后改由哪个 agent 或哪种方案接手
- `evidence` 用来记录日志、测试、波形、记忆更新等验证证据

## 图选择规则

### 静态图优先条件

- 任务类别已反复出现，且已有模板能覆盖主要依赖链
- 节点输入、输出、成功标准在多轮任务中基本稳定
- 任务目标更像“执行一条已知流程”，而不是“探索未知边界”

### 动态图触发条件

- 现有模板无法表达当前任务的关键步骤或边界
- 某个节点连续失败，需要插入 `reproduce`、`collect-log`、`localize-boundary`、`config-bisect` 等诊断节点
- 出现新的跨模块依赖，必须先补“契约澄清”或“产物转换”节点
- 当前结果无法形成证据链，必须补充日志、trace、波形或对比摘要节点

### 模板升级条件

- 同类动态图在多轮任务中重复出现，且节点依赖、输入输出、成功标准趋于稳定
- 新流程已经不再依赖人工临时判断才能落地
- 升级后能减少重复扩图和重复解释成本

## 子任务智能体配置

- 默认每个节点只指定一个 `owner_agent`，由它对节点输出负责
- 当一个节点内部天然包含“规划 + 实施 + 审阅”或跨知识边界时，可以在节点内部使用 single-AI 或 multi-AI 配置，但对外仍暴露一个统一的 `owner_agent`
- 工作流 agent 负责图结构与节点交接，模块专家负责节点内部实现；不要把“图调度”和“模块实现”混成一个超大节点

## 动态图扩展规则

- 节点执行失败时，优先把失败节点拆成 `reproduce → collect-evidence → localize → fix → rerun`
- 若关键产物缺少证据，插入专门的 `collect-log`、`collect-trace`、`wave-summary` 或 `artifact-audit` 节点
- 若依赖的 target 路径尚未实现，应用“截断而非伪造”原则，把图收敛到当前可执行的参考闭环，并把缺口记录成基础设施节点
- 若需要对比或诊断，必须先确保两侧产物可比较；不能在只有参考输出或只有目标输出时创建 `compare-or-difftest` 节点

## 图质量门槛

- 每个非 `record` 节点都必须留下至少一条可复核证据
- 每条边都应能解释为“执行依赖”或“知识依赖”，不能只是模糊的顺序摆放
- 同一节点不要同时承担“构建、定位、修复、记录”四种职责；职责过宽时应拆节点
- 图中出现未来节点时，要明确它是“预留接入点”还是“当前硬依赖”，不能混写

## 结构化任务产物

- 任务级产物与长期记忆分离：
  - `.github/memory/` 保存稳定结论、长期经验和设计决策
  - `.github/task-runs/` 保存单次图任务的执行摘要和派发历史
- 模板入口：
  - `.github/task-runs/templates/task-report.template.md`
  - `.github/task-runs/templates/dispatch-log.template.md`
- 建议每个重要图任务创建一个目录：`.github/task-runs/YYYY-MM-DD-<task-slug>/`
- `task-report.md` 用于汇总当前任务的目标、选图、节点状态、关键产物、阻塞点、下一步和模板升级候选
- `dispatch-log.md` 用于追加记录节点派发、状态变更、输入输出、证据与 handoff

## 静态图模板

### `rv32-reference-loop`

```text
study-recall → image-build(am-kernels / AM) → nemu-reference → record
```

适用场景：当前阶段的功能验证、最小工作负载回归，以及为后续 target 路径接入准备稳定参考输出。

### `rv32-bringup`

```text
study-recall → image-build(am-kernels / AM) → nemu-reference → rtl-sim(npc / verilator) → compare-or-difftest → record
```

适用场景：NPC 已实现后的单周期 bring-up、指令实现、最小功能回归、目标仿真链路打通。

### `am-device-loop`

```text
device-contract → am-impl → nemu-device → am-test → compare → record
```

适用场景：IOE / 设备模型 / AM 平台联调。

### `agent-env-refactor`

```text
audit → blueprint → file-edits → validate-discovery → record
```

适用场景：重构 `.github/` 下的 agent、instructions、记忆协议与工作流环境。

### `regression-debug-loop`

```text
reproduce → collect-log-or-trace → localize-boundary → fix → rerun → record
```

适用场景：参考路径回归失败、设备联调失败、或需要先稳定证据链再修复的问题。

## Agent 分层

| 层级 | 角色 | 责任 |
| ------ | ------ | ------ |
| L0 | `ysyx-coordinator` | 选择静态图 / 动态图，切分节点，调度与记录 |
| L1 | `agent-system` | 重构 agent 架构、指令、记忆、蓝图 |
| L1 | `hardware-flow` | 管理 NEMU / AM / am-kernels 参考闭环，并为 target 节点接入做编排 |
| L2 | `npc`、`nemu`、`abstract-machine`、`am-kernels`、`difftest` 等 | 在各自模块内实现与调试 |
| L3 | `.github/memory/` 与 `study/` | 提供长期知识、经验和稳定入口 |

## 当前阶段门槛

### Gate 1：参考路径稳定

- AM 程序可以稳定构建镜像
- NEMU 可以稳定跑同一镜像并产生日志

### Gate 2：参考闭环结构化

- 调度结果能稳定产出结构化 task report / dispatch log
- 任务级产物能稳定落到 `.github/task-runs/` 统一目录，并与 `memory/` 分层保存
- `image-build` 与 `nemu-reference` 节点的命令、输入、输出、日志摘要可重复复用

### Gate 3：目标路径打通

- NPC / Verilator 能加载或对接同类工作负载
- 能输出最小可用的仿真日志或波形

### Gate 4：对比与扩展闭环

- 能把 NEMU 结果与 NPC 结果收敛到同一套比较与诊断流程
- `difftest` 或等价比较层开始稳定工作
- 在功能闭环稳定后，再把综合、STA、PPA 分析作为下游节点接入

## 分阶段路线图

1. **P0 骨架期**：落地图任务协议、`agent-system`、`hardware-flow`、蓝图与记忆入口
2. **P1 参考闭环期**：稳定 `am-kernels -> AM -> NEMU` 默认工作流，并补结构化 task report / dispatch log
3. **P2 目标接入期**：待 NPC 实现后，再补齐 `npc/single/Makefile` 与 `platform/npc.mk` 的真实运行链路
4. **P3 对比与扩展期**：接入 `difftest`，并逐步引入 `yosys-sta`、PPA、时序诊断等更强的 EDA 节点

## 当前落地原则

- 优先使用工作区已经具备的真实链路，而不是为了“像 EDA”而空转设计概念
- 先让 agent 能围绕镜像、NEMU 参考运行、日志与结构化记录工作，再在 NPC 就绪后接入 target 仿真与对比
- 每一轮重构都要留下明确的静态图模板、节点契约与记忆更新，避免体系再次退化成散乱规则
