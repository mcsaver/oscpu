---
description: "本地 RV64 CPU Architect Agent 的保守语义路由。只有存在开放的跨流水/事务/架构状态设计决策，并能形成正确性与 CPI/PPA 可证伪闭环时才启动；根因未知先探索，方案已定交给实现者。"
applyTo: "npc/rv64/**"
---

# CPU Architect 路由与验证预算

本文件决定是否启动 `cpu_architect`。它不是 CPU 关键词匹配器，也不以文件数量、修改行数或用户是否说了
“优化”作为启动条件。路由机器真源为
`.github/ai-env/contracts/cpu-architect-routing-v1.json`，确定性入口为：

```bash
python3 scripts/cpu_architect_route.py classify --input <task-packet.json>
```

## 1. 路由类型

| route | 责任 | 默认 owner |
| --- | --- | --- |
| `ARCHITECT` | 开放的微架构决策、Architecture IR 变换、因果实验与多目标取舍 | `cpu_architect` |
| `EXPLORER` | 根因、模块、transaction 或周期边界尚未定位，只做轻量事实发现 | built-in explorer / `npc` 只读探索 |
| `WORKER` | 方案已经确定，执行局部 RTL、TB、脚本或工具实现 | worker / 对应 domain agent |
| `REVIEWER` | 候选已存在，仅审查不变量、证据边界或晋级资格 | 独立 reviewer |
| `CLARIFY` | 缺少无法从仓库发现、且会实质改变设计的目标/授权 | 主 agent 向用户确认 |
| `NON_ARCH` | 文档、环境、CI、报表、通用软件、状态汇报或概念解释 | 普通任务分类器 |

## 2. `ARCHITECT` 硬门

必须同时满足：

1. 对象是当前工作区的本地 RV64 CPU spec、production RTL、testbench 或 EDA/性能证据。
2. 存在尚未决定的结构选择，不是已经批准的机械实现。
3. 至少触碰一类架构深度：跨 module transaction/背压/恢复/生命周期；流水周期边界或共享资源拓扑；
   commit、precise trap、CSR、FENCE、memory ordering、redirect 或 architectural visibility 不变量。
4. 目标可证伪：必须包含 correctness，并至少包含 CPI、timing、area、power、complexity 中一项。
5. baseline、因果根因和本地 evidence path 足以形成
   `current evidence → candidate transform → directed evidence → same-design measurement → retain/rollback`。
6. 用户或父任务已授权架构级改动。

任何硬门未知都不能靠高置信度、关键词或文件数绕过。根因/基线不足时先 `EXPLORER`；授权缺失时
`CLARIFY`；方案固定时 `WORKER`；只有候选裁决时 `REVIEWER`。

## 3. 工作区发散范围

通过 `ARCHITECT` 硬门后，先读取 `npc/rv64/ARCHITECTURE.md` 或执行
`python3 npc/rv64/eval/ppa/tools/architecture_registry.py query --capability <name>`，取得同一 snapshot 下的
owner、filelist、NpcTop reachability、dynamic、mapped 与 STA/PPA 边界；再沿 EvidenceRef 打开所需 RTL/spec。
registry/view/schema 的日常维护仍是 `WORKER/NON_ARCH`，不得反向触发 Architect。

通用大核示例只作为搜索维度。先从本地源码和证据确认，再实例化为 IR 节点：

- frontend：取指供给、分支预测/RAS、packet/cache、redirect 与 outstanding transaction；
- decode/rename/allocate：双发射配对、ProducerId、free-list/map/busy 与分配回滚；
- scheduling/regread/bypass：issue/select、wakeup、bank/port、依赖与公平性；
- execute/writeback/ROB：完成资格、长延迟单元、精确提交、异常与恢复；
- memory/cache/MMU/bus：LSQ/MIQ/SQ、forward/replay、owner/epoch、AMO/LRSC、PMA/PMP、AXI；
- control/system：CSR、trap/return、FENCE、序列化事务、flush/redirect 与架构可见性；
- physical evidence：CPI attribution、关键路径/控制锥、WNS/TNS、逻辑/宏面积、合格功耗和系统层级。

只有被 `rg`、spec、波形、计数器、仿真或 EDA 报告确认的对象才进入 Architecture IR。不存在于当前核的
ROB 深度、cache 层级、预测器 topology 或宽度参数不得从示例直接复制。

## 4. 不启动的明确边界

- README、格式、命名、注释、端口机械贯穿或普通 lint；
- 已知根因且没有开放结构取舍的单点 bug；
- 单个 testbench、报表解析器、agent-flow、EDA 安装或 CI 故障；
- 单独校验/整理 CapabilityGraph、ExperienceRecord、KnowledgeGap 或训练候选；这些是已启动架构切片的
  证据维护，由普通 WORKER/NON_ARCH 工具完成，不能反向触发 Architect；
- architecture registry 的 inventory、owner/lifecycle、树/图/网视图生成或 schema/报表维护；只有其中
  暴露的真实产品 GAP 另行满足全部 `ARCHITECT` 硬门时，那个结构决策才路由给 Architect；
- 重新执行一次已有综合/仿真并汇总结果；
- 只读状态、RISC-V 概念解释或普通软件任务；
- 只有“CoreMark 慢”“做到 200 MHz”而没有本地因果链与冻结基线的模糊请求。

一行 `commit_valid` 若改变 precise trap/commit visibility，仍可命中架构深度；跨 20 个文件的纯重命名仍是
`WORKER`。分类看语义，不看表面规模。

## 5. 验证预算

确定性证据默认执行一次，必须绑定：

```text
command + input/source manifest + config/design_id + tool/seed/thread + rc + parsed result + artifact pointer
```

只有下列情况才允许或要求重复同一命令：随机/并发/CDC/RDC/race、已有 flaky、未固定 seed/thread、
wall-clock/analog/variable-PPA 噪声、机器/工具异常证据，或用户明确要求。重复必须写出 `repeat_reason`、
次数、接受阈值与停止条件；没有理由的重复应取消。

`determinism=unknown` 本身不触发重跑：先冻结输入、seed/thread 与 oracle；仍无法判定时输出 GAP，不能
用多跑几次代替实验设计。

A/B baseline/candidate、正向/负向 oracle、不同 corner/config、不同 mutation 和实现后必要的不同层级证据，
是互补实验，不是“复验”。高风险、migration、release 或正式架构晋级默认要求独立审查；若底层命令是
确定性的，独立审查优先复算输入/命令/身份和检查反例，不机械重跑同一命令。

## 6. 路由示例

- 已确认 owner terminal → drain → trap/redirect 是 mapped critical path，需要重构生命周期并保持 CSR、
  FENCE、precise trap，再用 TB/CPI/STA 决定保留：`ARCHITECT`。
- “CoreMark 太慢”但根因未知：`EXPLORER`。
- 按已批准方案实现一个 permit register：`WORKER`。
- 判断已有候选是否可晋级 Pareto：`REVIEWER`。
- 修改 traceability 正则或 CI timeout：`WORKER`/`NON_ARCH`。
- 选择 ROB/IQ 深度并比较 CPI/timing/area：`ARCHITECT`；仅把已参数化 ROB 改到给定值：`WORKER`。
- 测量失败后按既有 schema 补一条 KnowledgeGap：`WORKER`；只有该 gap 重新形成开放的本地结构取舍并
  再次通过全部硬门，后续设计切片才是 `ARCHITECT`。
