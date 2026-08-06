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
| `docs` | 普通说明、交付摘要与日志指针修改 | 允许 | 不派生 domain gate；显式 gate 仍可选 | `none` |
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
- `docs` 只对普通 `.md/.rst/.adoc/.txt` 说明面跳过路径派生门；task-run 中仅
  `delivery-summary.md`/`dispatch-log.md` 属于这种说明面，terminal marker、receipt、checker log 与
  runtime evidence 不按后缀豁免。`npc/rv64/design/arch/` 下的 architecture contract 即使是 Markdown
  也保留对应 domain pointer；`ROADMAP.md` 只是机器账本/收据的说明镜像，单独修改它不重建 stale
  current-design receipt。AI 环境 instruction 仍必须改类为 `environment`。这既避免交付摘要触发
  RTL 复核，也不允许用文件后缀绕过承重合同或机器账本。
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

# 用户追加要求使任务跨入另一 class 时，显式升级并留下原因；generation 会递增
scripts/agent-flow.sh reclassify \
  --task <task-id> \
  --class environment \
  --reason '<新增范围及为何需要改类>'

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

任务开始后若用户追加的新范围属于另一 class，使用 `reclassify --reason`，不要放弃旧 runtime state、
手改 meta 或另建重复 task。reclassify 保留既有路径/evidence/decision，写入 class 变更轨迹并递增
generation，因此此前 candidate gate 自动失效；最终仍按新 class 与全部显式路径重新校验。它不改变
archive 档位，也不能把已有路径伪装成 `review/analysis/verification` 后通过收尾。

长时间等待或用户暂时切走时可用 `pause`，恢复工作用 `resume`，让事后占用估算更容易解释。工具在
本轮中途首次引入或恢复旧任务时可用兼容参数 `--initial-work-seconds` 导入已发生的工作时间，但
必须用 `decision` 说明来源；它只影响观测值，不授权或阻断 PASS。

Windows→WSL 的 single-flight ownership 只覆盖合同列出的一个有界命令批次；子节点完成、GAP、异常或
被中止时必须停止其工程进程并明确归还。节点无响应时，主节点先中止该节点，再用 Windows 进程表确认
没有指向本工作区的 `wsl.exe` 工程进程后回收 ownership，并把 forced reclaim 记入 decision trace。
长仿真本身交给 fail-closed runner 和 task-run status，不用无限占用 reviewer 的交互式 shell。

## 4. 门禁指针

`scripts/agent-flow.c` 内的 gate registry 是固定入口。C 只允许调用注册 ID，不接受任意命令字符串。
当前指针包括：

- `flow-self-test`
- `flow-observation-smoke`
- `source-artifact-hygiene`
- `rv64-soc-delivery-gates`
- `rv64-full-core-runner-contract`
- `rv64-mini-system-runner-contract`
- `rv64-lightweight-linux-runner-contract`
- `rv64-layered-system-signoff-current`
- `rv64-system-recertification-runner-contract`
- `rv64-architecture-debt-current`
- `rv64-terminal-collector-lane-contract`
- `rv64-historical-defect-ledger-audit`
- `rv64-historical-defect-current-contract`
- `rv64-historical-defect-current`
- `rv64-arch-stable-current`
- `rv64-owner-timing-fast`
- `rv64-owner-timing-link`
- `rv64-memory-request-hold-fast`
- `rv64-memory-request-hold-link`
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
路径自动触发 AI 环境 profile。`rv64-soc-delivery-gates` 只验证三级触发配置、稳定入口和留存边界，
不运行 RTL 仿真/综合/STA；真实 domain evidence 仍按本轮受影响配置选择，并对每个不可变
design/config identity 只登记一次。身份字段或执行语义变化后旧证据失效，不能把“一次”解释成项目
生命周期内永久有效。

`task-run-status-test` 验证通用长跑状态机；当 `scripts/task-run-status.sh` 或其单测变化时，C 还必须同时
选择 `rv64-full-core-runner-contract`、`rv64-mini-system-runner-contract`、
`rv64-lightweight-linux-runner-contract` 与
`rv64-system-recertification-runner-contract`，复核各自执行入口的实际接线与 marker 基数。多个入口共享
helper 单测时允许由复合门禁内部复用执行，但不得以孤立 helper PASS 外推任一 RV64 长跑入口 PASS。
DiffTest profile schema、RTL design-id helper、official inventory runner 与 AM result checker 也直接映射到
`rv64-full-core-runner-contract`；该复合门禁拒绝跨轮 symlink 路径、重绑后失真的 official/AM guest 段、
benchmark 重复或矛盾值，以及 smoke 启动前已存在的 AM/benchmark 二级产物。
全核 producer 的 output/artifact helper 同样属于该门禁：必须在创建或哈希前逐层拒绝 parent/final-file
symlink；official/AM source-log 的 architectural terminal 与 DiffTest 状态使用 exact-one cardinality。
入口 shell、Python producer、aggregate writer 与 F0 consumer 共同执行 lexical path 合同；build、official、
AM、benchmark wrapper 的 source-log path/hash 和 retained raw bytes 属于同一复合门禁，不允许只验 wrapper。
该“raw bytes”不经过 universal-newline 文本归一化；canonical destination 与临时提交文件在写入前均拒绝
parent/final/dangling symlink，临时文件使用 exclusive/no-follow 创建。

`rv64-architecture-debt-current` 是候选交付前的本地 RV64 账本指针。它只校验当前 RTL design-id、
V14C/V14D/V14E 冻结证据、cohort 排除合同和账本 exact membership，不启动仿真、综合或 STA。
只有账本、architecture-debt 收据、cohort 合同或其专用校验轮发生变化时才自动选择；普通 RTL、
producer/historical evidence 或分层系统收据变化只登记 debt receipt 失效指针，待一轮债务迁移形成
确定性候选后再显式登记或更新该收据。

历史缺陷采用三段指针。`rv64-historical-defect-ledger-audit` 只检查库存 membership、SELECTED 优先级、
artifact hash 和 ledger 单测，开放项存在时命令仍可成功但输出域状态 `GAP`；
`rv64-historical-defect-current-contract` 只检查 receipt/schema/oracle 代码，并证明开放 blocker 在读取旧
系统收据前被快速拒绝；`rv64-historical-defect-current` 才校验全部已回填条目的同一 current design
receipt。它与 `rv64-architecture-debt-current` 各自绑定独立账本：只有直接修改各自 ledger、receipt 或
专用 checker 时才选择对应 current 门；分层系统 receipt/tool 只选择
`rv64-layered-system-signoff-current`，并使依赖它的其它 current receipt 显式过期，不在同一次普通交付中
自动重建。历史缺陷 ledger、历史重放、定向负向 RTL 版本和独立 review 不无条件牵引整套架构债务
current 门。production RTL、普通 TB、product config、guest image 或
通用 task-run status helper 的变化只使旧 current result 失效，不在日常 finish 自动运行必然过期的结果；
本轮 task report 记录 maturity GAP，到 blocker 清零后的 candidate/release 再显式重建并选择。

`rv64-terminal-collector-lane-contract` 是亚秒级静态轮，枚举 12 个 terminal ingress 的 66 个 lane pair，
区分 production response-credit、源/holder 断言和 collector-only fail-closed 范围；它不运行仿真，也不能
把 collector 拒绝等价为上游 owner 交接正确。`OooIntBackend`/collector 或该 checker 变化时可与受影响
domain fast gate 同次执行，不追加全核 current-result 门。

`rv64-arch-stable-current` 是设计成熟度从 `ARCH_CLOSED` 进入 `ARCH_STABLE` 后的 current-result
复核指针。C 只调用 `arch_stable_freeze.py verify --require-stable` 重算已经生成的 exact-input result，
其中包括 exact candidate/design-id 的独立审查 receipt，
不在收尾阶段重复执行 testbench、仿真、综合或 STA；完整正负向单测和业务 evidence 必须在实现阶段
先运行并登记。该指针只对 ARCH_STABLE checker/candidate/result 维护面自动选择，普通 RTL 开发仍先走
受影响 domain 的 `fast` evidence，达到新的 maturity 晋级候选时才更新 current candidate/result。

`rv64-owner-timing-fast` 只运行 owner-timing 合同、collector/workload consumer 正负向单测、SV lint
和 production manifest 身份检查；`rv64-owner-timing-link` 包含并替代 fast，再验证 Verilator/DPI
elaboration/link。workload A/B、单 workload invalid probe 与 checker replay 是显式 domain evidence，
不注册为自动 finish gate，避免收尾时意外重跑高成本 workload。

`rv64-memory-request-hold-fast` 是`OooIntBackend`双bank request admission holder的日常固定轮：运行
双bankexact-fire/recovery/capacity focused TB、single-bank older-probe TB，以及holder bypass、cancel
fallback、consume/MIQ live split、probe-order bypass四项compile-success mutation；每项要求专属拒绝
marker和最终FAIL。`rv64-memory-request-hold-link`包含并替代fast，再运行V8S双memory、default legacy、
V11L retry与V11M reservation；显式选择link时C会删除auto-fast，禁止重复。只有跨bank选择、MIQ/SQ
admission、retry/reservation或公共TB连接变化时才选link；确定性候选形成前不重复触发。CoreMark
invalid probe仍是显式longrun evidence，不进入finish gate。

该wheel默认把所有编译结果放入runtime并清理。只有需要为当前确定性交付点保存原始TB/mutation日志时，
才显式传`--evidence-dir <.github/task-runs/.../empty-subdir>`；脚本拒绝task-run以外或非空目标，且仍不
保留build、VVP、obj_dir与mutant工作副本。

`rv64-mini-system-runner-contract` 只调用 `run-mini-system-current.sh --validate-only`，校验 OpenSBI + S/U
payload、Sv39/异常恢复、timer、PLIC/UART、AMO/LRSC、MMIO、自然关机、终端/断言 oracle 及正负向单测，
不会启动 guest。真实 L2 回放按 `privilege/sv39/timer/interrupt/atomic-mmio/shutdown/all` 选择 case；只有
`all` 可以声明完整 L2，其余只形成定向证据。
L2/L3 真实执行还用 `rv64-layer-source-id.sh` 对 payload/kernel、OpenSBI、DTB、PID1 与构建入口做
执行前后内容身份复核；任一变化都令本轮 fail-closed，不能用 checker replay 代替重跑。

`rv64-lightweight-linux-runner-contract` 只校验 Linux 6.6 最小配置、静态 PID1/initramfs、OpenSBI/双 DTB
构建入口、当前 `NpcSimTop` 身份绑定、UART/PLIC 与 syscon cycle/commit 顺序、最终 evidence seal、
终端/phase/RTL assertion oracle 及其正负向单测；不会启动 guest。
真实 L3 轻量 Linux 回放是显式 domain evidence，并作为当前系统层最高优先级。完整 Ubuntu 22.04/systemd
入口由独立 `rv64-system-recertification-runner-contract` 管理，只有用户明确要求并提供
`--user-authorized-full-ubuntu` 时才允许执行；缺少该可选运行不阻断默认 L0/L1/L2/L3 分层签核。

`rv64-layered-system-signoff-current` 只重算当前 production RTL design-id，并复核已留存的 L0 module
113 项、L1 official/AM/DiffTest checker-replay、L2 `all`、L3 `all` 的输入前后哈希、原始日志、断言、
终端事务和 evidence seal；它不启动 guest，也不把可选 Ubuntu、ARCH_STABLE 或 PPA 外推为 PASS。
该指针仅由聚合 checker/schema/current receipt 或分层策略维护面选择；普通 RTL 编辑先使旧 receipt
失效并运行受影响 domain evidence，形成新的确定性候选时再重建 current receipt。

checker-only 修正使用 `replay-layer-checker-current.sh`。它只接受一个不可变 FAIL task-run，复核冻结
console/npc/binding/status 的前后哈希并生成新的 checker-only PASS/FAIL 收据；原 status 不改写，也不启动
guest。production/elaborated RTL、simulator/device、guest/config 输入语义变化时禁止用 replay 代替重跑。
replay 还必须现场重算当前 RTL identity，并与冻结 binding/summary 一致。
同时必须匹配当前 simulator source、layer source、runtime artifact 与对应 runner/policy 身份；这些对象漂移时
旧冻结输入只能保留为历史证据，不能升级成当前层级签核。

`rv64-current-simulator-cache-contract` 只执行 `build-current-simulator-cache.sh --validate-only`；真实编译是
显式 domain action。缓存必须同时绑定 production RTL identity 与 vsrc/csrc/Makefile/生效配置内容，只保留
一份当前可执行文件、Verilator manifest 和 source binding，`obj_dir` 在发布后清理。

门禁 stdout/stderr 写入 `.github/runtime-artifacts/agent-flow/<task>/gates/`。AI 默认只读取
`summary.txt`；只有摘要为 FAIL、TIMEOUT 或 GAP 时才打开对应单个 gate log。

`source-artifact-hygiene` 只在 `.gitignore` 或其检查脚本达到清理/同步交付点时运行。它用
`git ls-files` 检查索引本身（这是 Git 索引卫生的必要输入），拒绝已跟踪的 `build*`、`obj_dir`、
Python bytecode、仿真波形/VVP、Yosys 结果和 runtime artifact；SoftFloat 构建描述源码与 Chisel workflow
模板使用精确 allowlist。显式登记的 `build*`、`obj_dir`、`__pycache__`、bytecode 或波形路径在 C 路由
中先归入该清洁面并停止继续匹配历史 task-run 的 domain receipt；同目录下保留的 result/summary/manifest
仍按原 domain 指针处理。普通 RTL 开发仍只用 `record --path`，不会因此扫描 Git 工作树。

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
完整 console/dmesg、签发所需 baseline/mutation transcript 放 durable task-run evidence；二级编译物仍放
runtime-artifacts，并在 receipt 形成后清理。结果档案保存路径、哈希、marker 和摘要，不复制无承重 payload。

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
