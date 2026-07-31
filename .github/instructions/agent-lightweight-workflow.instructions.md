# Agent Lightweight Workflow

本文件是工作区日常 AI 任务分类、流程预算、门禁调度和 compact task-run 的规范真源。目标是让
工作流服务于 RV64 RTL/软件开发，而不是让环境维护成为主工作。

## 1. 总原则

1. 先分类，再决定是否需要流程；只读任务不能因为“非平凡”自动升级为重门禁。
2. 日常任务使用 `scripts/agent-flow.sh`。它只在 C 源变化或本机无缓存二进制时编译
   `scripts/agent-flow.c`，其余调用直接执行缓存二进制。
3. 一轮目标内只记录显式修改路径、验证证据和工程决策轨迹；确定性交付时才运行选中的固定门禁。
4. 以“流程时间约不高于开发时间的 40%”作为轻量化设计目标和事后复盘指标，不设置精确时间门禁；
   比例暂时超出只进入摘要，不得单独阻断交付。减少占用依靠任务分类、固定指针、低频触发和缓存，
   不能通过削弱 RTL 断言、测试、综合或 STA 硬门实现。
5. 业务编译、仿真、形式验证、综合、STA、PPA 测量属于开发验证，不属于 AI 环境门禁。
   这些结果用 `evidence` 登记，不在目标末尾重复运行。
6. 默认不使用 Git 枚举工作树。修改文件由 `record --path` 明确登记，目录自动进入
   `directories.log`；Git 只在用户要求同步、提交、分支或发布时使用。

## 2. 任务分类

| class | 适用操作 | 源码写入 | 默认流程 | 默认 task-run |
| --- | --- | --- | --- | --- |
| `review` | 代码审查、反例检查、接口审阅 | 禁止 | 零门禁 | `none` |
| `analysis` | 解释、状态盘点、方案比较、只读研究 | 禁止 | 零门禁 | `none` |
| `docs` | 普通说明文档修改 | 允许 | 不运行重门禁 | `none` |
| `development` | RTL、C/C++、脚本或软件实现 | 允许 | 要求至少一项真实开发验证 evidence；不自动跑 e2e guard | `compact` |
| `verification` | 运行已有测试、冻结输入 replay、读取波形/报告 | 禁止修改生产源码 | 要求 PASS evidence；不追加环境门禁 | `none` |
| `environment` | AI 规则、C 调度器、profile、contract、维护脚本 | 允许 | 目标末尾只运行路径映射到的门禁指针 | `compact` |
| `longrun` | 长仿真、综合、STA、Linux/Ubuntu 系统回放 | 允许 | 要求 `task-run-status` PASS evidence | `durable` |
| `cleanup` | 删除编译物、镜像、缓存与归档整理 | 允许 | 要求 preview/result 双证据 | `compact` |
| `release` | CI、商业包、外部发布与完整环境交付 | 允许 | 运行 release 门禁 | `durable` |

补充规则：

- `review`/`analysis` 一旦产生工作区修改，必须新开或重新分类为相应写入类任务；不能继续以零门禁
  身份交付修改。
- `review`/`analysis` 的零门禁不可用 `record --gate` 覆盖；C 在记录和派生两层都拒绝/清空 gate
  pointer。
- `.github/ai-env/`、`.github/e2e/`、`.github/skills/`、agent 工作流 instruction、
  `scripts/agent-*` 等环境面修改必须使用 `environment` 或 `release`。
- 只读代码 review 不要求 DB brief、task-run、strict guard、memory 写回或实现者/审查者二次套娃。
  审查结论本身就是该任务的交付。
- `--archive` 可以显式覆盖默认档位；需要把一次重要 review 留档时可用 `compact`，但仍不增加门禁。

## 3. 一轮目标的最短闭环

```bash
# 1. 开始：分类只做一次；40% 是可选的非阻断观测目标
scripts/agent-flow.sh begin \
  --task <task-id> \
  --class development \
  --overhead-target 40

# 2. 每批落盘后登记本轮拥有的路径，不扫描 Git
scripts/agent-flow.sh record \
  --task <task-id> \
  --path npc/rv64/vsrc/<module>.sv \
  --path npc/rv64/tb/<testbench>.sv

# 3. 登记真实开发验证和可复盘决策
scripts/agent-flow.sh evidence \
  --task <task-id> \
  --name rtl-focused-test \
  --status PASS \
  --artifact <result-path>
scripts/agent-flow.sh decision \
  --task <task-id> \
  --kind decision \
  --text '<假设、证据、选择理由、反例或回退摘要>' \
  --artifact <optional-path>

# 4. 需要独立审查时先形成候选；审查无改动后正式归档
scripts/agent-flow.sh finish --task <task-id> --candidate
# reviewer: 只读复核候选摘要、改动文件和失败反例
scripts/agent-flow.sh finish --task <task-id>
```

无需独立审查的小型落盘任务可直接执行正式 `finish`。`--candidate` 只缓存同一 generation 的 PASS
门禁并写 `CANDIDATE_PASS` 摘要，不生成 task-run；审查发现问题并重新 `record` 后 generation 递增，
旧门禁不会复用。审查无改动时正式 `finish` 复用候选结果并完成归档。

长时间等待或用户暂时切走时可用 `pause`，恢复工作用 `resume`，让事后占用估算更容易解释。工具在
本轮中途首次引入或恢复旧任务时可用兼容参数 `--initial-work-seconds` 导入已发生的工作时间，但
必须用 `decision` 说明来源；它只影响观测值，不授权或阻断 PASS。

## 4. 门禁指针

`scripts/agent-flow.c` 内的 gate registry 是固定入口。C 只允许调用注册 ID，不接受任意命令字符串。
当前指针包括：

- `flow-self-test`
- `flow-observation-smoke`
- `profile-bindings`
- `policy-audit`
- `schema-audit`
- `artifact-audit`
- `delivery-audit`
- `trace-audit`
- `state-audit`
- `skill-audit`
- `rtl-task-contract`
- `task-run-status-test`
- `maintain-final`
- `maintain-release`

`environment` 根据显式路径选择相关指针。例如 profile/runner 变化才运行 `profile-bindings`，policy/CI
变化才运行 `policy-audit`，RTL 子任务合同变化才运行 `rtl-task-contract`。普通 RTL/软件开发不因源码
路径自动触发 AI 环境 profile。

门禁 stdout/stderr 写入 `.github/runtime-artifacts/agent-flow/<task>/gates/`。AI 默认只读取
`summary.txt`；只有摘要为 FAIL、TIMEOUT 或 GAP 时才打开对应单个 gate log。

## 5. task-run 留存判定

task-run 仍是正式工程记录，但只在目标轮次结束后生成，不承担实时调度。

### `none`

默认用于：

- 只读 review/analysis；
- 普通问答与状态查询；
- 无生产源码变化的验证 replay；
- 不形成长期工程决策的普通文档修改。

### `compact`

默认用于：

- 有落盘 RTL/软件修改并形成验证结论的开发轮次；
- AI 环境、规则或固定工具修改；
- 实际执行的清理/归档操作；
- 用户明确要求保留的重要 review。

只保存：

- `agent-flow-result.md`
- `agent-flow-changed-paths.tsv`
- `agent-flow-changed-directories.tsv`
- `agent-flow-evidence.tsv`
- `agent-flow-decision-trace.tsv`
- `agent-flow-gates.tsv`
- 每个已执行门禁最多 64 KiB 的头尾日志

### `durable`

默认用于：

- 长时间 RV64 仿真、综合、STA 和系统回放；
- release、CI、商业包或外部确定性交付；
- 失败后需要跨会话复现的高成本实验。

结构与 compact 相同，但每个选中门禁日志最多保留 256 KiB。波形、镜像、raw overlay、obj_dir、
完整 console/dmesg 和二级编译物仍放 runtime-artifacts 或现有专用 task-run evidence，只在结果档案
保存路径、哈希、marker 和摘要，不复制 payload。

## 6. 工程决策轨迹

允许并鼓励保留用于事后复盘的工程推理摘要，但应是可审计记录，而不是完整对话转储。支持：

- `hypothesis`：待验证的根因或性能假设；
- `evidence`：改变判断的 testbench/EDA/源码事实；
- `decision`：采用方案及主要理由；
- `counterexample`：否定候选方案的反例；
- `rollback`：撤回负优化或错误修改的原因；
- `note`：阶段性上下文。

每条记录最多 2048 字节、单行、可附本地 artifact。最终进入
`agent-flow-decision-trace.tsv`。不保存逐 token 私有内部思维、完整聊天记录、重复 startup context
或无法由工程事实复核的自述。

## 7. 维护脚本频率

- `scripts/agent-maintain.sh --mode quick`：仅 C 调度器与 shell 自测，不调用 Python/DB/profile。
- `--mode final`：一轮 AI 环境目标结束后运行非发布类完整审计；兼容名 `check` 等价于 `final`。
- `--mode release`：CI/nightly/商业交付使用，追加 package、delivery、branch-health 和 DB 审计。
- `--mode full`：仅需要完整 `agent-system` task-run 时使用。

不得在普通 review、每次文件编辑、每次用户追问或每个子 agent 返回后重复执行 final/release/full。

## 8. 旧 strict guard 的边界

`scripts/agent-e2e.sh --guard` 保留为 release/迁移兼容工具，但必须显式提供 `--paths-file` 或 `--path`；
它不再扫描 Git 工作树。日常任务由 C 调度器和真实 domain evidence 收口，不再默认要求 profile
publication、DB recall、evidence index 和 strict guard 同时存在。
