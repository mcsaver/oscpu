# AI Environment

本文件是仓库级 AI 开发环境入口索引。原则：Git 中只保留 source、contract、shim、template、manifest；生成物、运行物、历史大包、重型证据和 cache DB 不进入 tracked source。

## 日常开工（最短路径）

1. 从 `AGENTS.md` 和 `.github/instructions/agent-lightweight-workflow.instructions.md` 分类任务。
   `review/analysis` 直接读取相关代码/spec，不运行 guard。
2. 有落盘修改时运行 `scripts/agent-flow.sh begin --task <id> --class <class>`；每批修改用
   `record --path` 登记，不扫描 Git。用户追加范围跨入另一任务 class 时使用带 reason 的
   `reclassify`，保留原记录并递增 generation，不手改运行态或复制任务。
3. 只读取相关 `instructions/*.instructions.md`、module memory 和模块 README/spec。只有需要历史事实
   或跨模块 profile 上下文时才运行 bounded `brief`。
4. 业务开发选择 domain test/仿真/综合/STA 作为开发验证，并用 `agent-flow evidence` 登记结果；
   AI 环境 profile 不能代替业务 gate。
5. 派发本地 RV64 RTL 子 agent 时，用 `.github/skills/prepare-rtl-task-contract/` 的 canonical
    `create → validate → render` 生成并原样派发最小充分工程契约；validate 失败或手改边界的结果只记
   `candidate-only`，范围扩展另建 versioned JSON。主 agent 使用 `rv64-hardware-professional` 术语描述任务，
   `render` 追加 RV64 微架构/RTL/验证/PPA 语境、正向本地作用域声明和多义术语的对象/层级/作用域/
   工程目的限定，且不改变既有工具或推理能力；节点状态留在主 agent 的结构化记录中。用户可见进度与终审摘要也先写具体 module/signal/transaction、EDA 动作和证据，
   协调状态单独落 task-run，不反复复制到 RTL 技术正文；该分层不得削减负向 RTL 版本、断言或覆盖能力。
   创建该子 agent 时使用 `fork_turns="none"`，只把已校验的渲染结果作为初始提示；所需设计事实由
   `allowed_paths`、`required_context` 或 `supplied_material` 提供，不继承父任务完整对话历史。
   子 agent 最终回复首段按“RV64 RTL 对象或本地证据文件 → 周期或编译配置 → testbench/EDA 观测 →
   PASS/GAP 范围”组织；本地 JSON 证据校验出现意外接受或拒绝时，写明具体 schema 字段、工作区相对
   路径、定向单测和返回结果，并保留反例、未知项、原始日志 marker 和真实文件名。
   `render` 只保留上述硬件事实、合同绑定、输入/输出和工程命令；派发管线、父任务历史、协调状态与
   措辞策略不进入子 agent 技术提示。证据工具复核也必须以具体 CPU 债务项、RTL 证据文件、字段、
   测试名和返回码组织。长期 goal 只引用该措辞剖面，不重复展开协调场景。
6. 一轮目标达到确定性交付点后，需要独立审查的任务先运行
   `scripts/agent-flow.sh finish --task <id> --candidate`，审查无改动后再正式 `finish`；小型任务可
   直接正式收尾。C 调度器只调用路径对应的固定 gate pointer；流程占用约 40% 是非阻断复盘目标，
   不设置精确时间门禁。strict e2e guard 仅用于 release/迁移，且必须显式传入 paths-file/path。

源码树/索引清理使用固定 C 指针 `source-artifact-hygiene`：只在 `.gitignore` 或清理检查器变化时读取
Git 索引，拒绝把可再生 build、bytecode、仿真波形、Yosys 结果和 runtime artifact 纳入版本控制；
日常 RTL 开发仍按显式修改路径工作，不用 Git 枚举本轮改动。

同一 domain 有 fast/link/workload 等层级时，机器可读 profile 必须列出客观变化触发与留存边界；
C pointer 默认选择最小充分层，显式重层包含并替代轻层，禁止重复执行。仅 checker/profile/report
变化且冻结执行输入、终端、工具、production manifest 与 link 语义输入哈希完整时，可用独立
versioned replay 组合原始 link PASS 与当前 fast PASS；原始 FAIL/PASS 均不回写。production RTL、
elaboration、simulator/device 语义或必要身份漂移时不得 replay。review/analysis 仍不因此增加 gate。

`OooIntBackend` memory-request holder的固定开发轮为
`check_v14r_memory_request_hold.sh --tier fast|link`，C指针分别是
`rv64-memory-request-hold-fast|link`。fast承载双/单bank focused与4项专属marker mutation，link包含并
替代fast后追加四项关联回归；workload探针不由finish自动触发。只有显式提供
`--evidence-dir .github/task-runs/.../<empty-subdir>`时才保留bounded result/log/diff/manifest，build/VVP/
mutant工作副本始终清理。production RTL变化后允许单次current-design invalid probe以旧baseline作
counter reference，但必须绑定当前manifest、前后hash、simulator与cleanup，并声明
`observer_noninterference_qualified=false`、`PPA=UNQUALIFIED`；完整A/B和PPA仍要求重新取得同设计
ARCH_STABLE/cohort。若仅修跨设计checker，保留原始FAIL并用`--mode current-design`冻结输入replay。

全核 module/official/AM/DiffTest/benchmark 的唯一长跑入口是
`npc/rv64/eval/ppa/run-full-core-current.sh --run-dir .github/task-runs/<new-run-id>`；机器合同见
`npc/rv64/design/arch/full-core-functional-run-policy-v1.json`。它只写新 task-run，当前 NPC/NEMU 配置
作为只读输入，NEMU/AM/Verilator 可再生编译物进入临时根；默认不发布 current，显式 publication 以
已完成的执行 PASS 为前置条件，并以独立 fail-closed publication 状态和 binding-last 事务提交；执行
result 不被发布动作回写。下游 F0/ARCH_STABLE 消费者同时核验不可变 source run-result、同轮 module
result/status/log、live RTL/official-177/AM 输入闭包、execution/publication 两个精确 PASS 状态、
source/canonical hash、14 项 mutation 的只读重放、逐项重开的 official/AM source-log、唯一且无矛盾值的
benchmark guest 行与字节级终端收据；同轮路径任一层含 symlink 即拒绝，不能绕过 binding
直接消费三项 canonical data。C 指针 `rv64-full-core-runner-contract` 只在上述 runner/policy/tool/测试或相关
构建入口改变时运行定向单测与隔离构建 smoke，不在普通 RTL 编辑、review 或每次收尾运行完整 cohort。
CoreMark/Dhrystone、cpu-tests、NEMU、AM/klib 及 platform script 的构建入口变化都映射到同一 C 指针；smoke
真实构建 NEMU reference、AM dummy、CoreMark 和 Dhrystone，启动前和结束后均要求 source tree 中不存在
`.result`、`Makefile.*`、`build` 或 `obj_dir` 二级产物，全部新产物位于临时根。执行 PASS 要求
module/functional/verifier 各自恰好一个 PASS 且无同阶段 FAIL；module 输入组精确闭包、benchmark guest 输出
行、冻结终端摘要与 canonical 14 项 mutation 的只读重放逐项复核。`scripts/task-run-status.sh` 既是通用
fail-closed helper，也是该全核入口的承重依赖；修改 helper 或其单测时，C 同时选择 helper 单测和全核
runner contract，避免只验证孤立状态机而遗漏接线。

全核 producer 在创建 attempt 目录或登记 artifact 前按 lexical path 逐层检查，父目录别名与最终文件
symlink 均不得先 `resolve()` 后放行；official/AM guest 段分别要求恰好一个 architectural PASS terminal，
AM 还要求恰好一个 `Difftest: ON` 且不存在 `OFF`。入口 shell 对原始 `--run-dir` 做同样的 lexical
final-component 检查；simulator-build、official、AM 与 benchmark wrapper 的 source-log path/hash 必须
回绑同轮 retained raw log，delimiter 以 bytes 解析且内嵌段与 raw 文件逐字节一致。canonical publication
对 destination 与 `.tmp-full-core-current` 逐层做 lexical 检查，并以 exclusive/no-follow 创建临时文件。

仅当完整 guest 阶段已结束、原始 FAIL 精确落在 benchmark `GOOD TRAP` 终端 oracle、冻结输入前后相同，
且当前 live 漂移唯一为 `functional_aggregate.py` 时，使用
`npc/rv64/eval/ppa/replay-full-core-functional-current.sh` 生成独立 L1 checker-replay。原始 FAIL 不回写，
replay 不发布 canonical execution binding；RTL/elaboration/simulator/device 或其它输入变化仍必须重跑。

当前默认系统签核采用
`L0 directed RTL + L1 full-core DiffTest + L2 mini-system + L3 lightweight Linux` 合取，机器策略见
`npc/rv64/design/arch/layered-system-signoff-policy-v1.json`。L2 入口为
`npc/rv64/eval/ppa/run-mini-system-current.sh --run-dir .github/task-runs/<new-run-id>`，可选七个定向 case，
只有 `--case all` 形成完整 L2；固定 C 指针 `rv64-mini-system-runner-contract` 只做静态合同与 oracle 单测。
其中 L3 是当前最高优先级，入口为
`npc/rv64/eval/ppa/run-lightweight-linux-current.sh --run-dir .github/task-runs/<new-run-id>`。该入口复用
production `NpcSimTop`、Linux 6.6、OpenSBI 与设备模型，只替换为最小内核配置和静态 PID1/initramfs，
覆盖 Sv39、SBI、进程/COW、timer、tmpfs、AMO/LRSC、PLIC/UART 与自然 poweroff，并用 fail-closed status、
前后哈希、UART/PLIC cycle/commit 窗口、带计数的 syscon 终端顺序、零 RTL assertion failure，以及清理后的
最终 evidence-file seal 收口。构建树和临时 rootfs 位于 runtime，task-run
只保留结果、身份、bounded 日志/marker 与 cleanup receipt；当前有效的轻量 guest 产物和 `NpcSimTop`
各只保留一份内容绑定缓存。L3 可选九个短事务，只有 `--case all` 形成完整 L3。固定 C 指针
`rv64-lightweight-linux-runner-contract` 只跑脚本合同与正负向 oracle 单测，不启动 guest；真实 L3 回放
作为本轮 domain evidence 显式执行一次。
当前 `NpcSimTop` 缓存由 `build-current-simulator-cache.sh` 构建，并用
`rv64-simulator-source-id.sh` 同时绑定 vsrc、csrc、Makefile 和生效配置；固定 C 指针
`rv64-current-simulator-cache-contract` 只做静态合同检查，不触发编译。
L2/L3 另由 `rv64-layer-source-id.sh` 绑定 payload/kernel、OpenSBI、DTB、PID1 与构建入口，并在真实执行
前后复核；checker replay 只有在当前 RTL、simulator、层级源码、运行产物和 runner/policy 全部一致时有效。

四层默认结果由 `npc/rv64/eval/ppa/tools/layered_system_signoff.py` 聚合，当前机器收据为
`npc/rv64/eval/ppa/evidence/layered-system-signoff-current.json`，固定 C 指针是
`rv64-layered-system-signoff-current`。该 checker 复核 L0 的 113 项 `-DOOO_ASSERT` 编译与日志、L1
冻结 cohort、L2/L3 原始 console/npc 事务、当前输入 manifest 和 seal；只读执行，不启动任何 guest。

完整 Ubuntu 22.04/systemd 仅作为可选再认证。其入口仍是
`npc/rv64/eval/ppa/run-system-recertification-current.sh`，但每次真实执行必须同时提供
`--user-authorized-full-ubuntu`，且只在用户明确要求时启动；普通 RTL 修改、候选收尾、自动化唤醒或 L3
失败都不得自动转入该路径。`--validate-only` 仍可做静态合同检查。历史 Ubuntu PASS/FAIL 保持不可改写，
缺少新的可选 Ubuntu 运行不阻断默认分层系统签核。

L2/L3 checker-only 修正使用 `npc/rv64/eval/ppa/replay-layer-checker-current.sh`。该轮子只读取一个已有
FAIL task-run 的冻结日志，写入新的小型 replay task-run 并保持原状态不变；任何 RTL、simulator、设备、
guest 或配置语义变化仍必须重跑受影响层。replay 必须现场重算当前 RTL identity，并与冻结 binding 和
新 summary 同时一致，才能使用 `CURRENT_IDENTITY` 措辞。

task-run 按 `none/compact/durable` 留存：review/analysis 默认不建，落盘开发和环境修改保存 compact
结果，长仿真/综合/STA/系统回放及 release 保存 durable 结果。只归档修改目录、验证指针、结构化工程
决策轨迹、门禁结果和 bounded 日志，不复制完整上下文或重型 payload。

以下 bounded brief、publication、manifest 与 DB 精确集合说明只适用于真实
`agent-e2e.sh --profile ...` dispatch，不是普通任务的默认步骤。

`brief` 只有在 Markdown/JSON 明确给出 `recall_status=complete` 时才算召回成功；显式 profile、
canonical 规则或独立关键词 focus 缺失，以及任何必需 chunk 装不进 `max_tokens`，都会非零退出并
标记 `recall_status=failed`。CLI/API 与 e2e runner 的 bounded brief 默认预算统一为 2400 tokens，
runner 可用 `E2E_CONTEXT_BRIEF_MAX_TOKENS` 显式覆盖；调用方不得把预算失败降级为 WARN 后继续宣称 profile GREEN。

runner 从 `task_slug` 提取独立 focus 时会过滤生命周期噪声。版本/迭代身份必须写成受控相邻片段 `revtag-v<数字><可选字母>`，只有该显式片段会从 focus 删除；裸 `v8`、`v2ray`、内部 `v8a` 等继续参与召回，畸形或重复 `revtag` 直接失败。task slug 本身仍原样进入 report/manifest/DB，因此身份可审计、领域语义不靠启发式猜测，non-history fail-closed 边界不变。

收尾阶段若用本轮稳定结论作为 task-specific e2e 的独立 focus，先通过 `update-stored` 发布 project/module memory，再使用其中已经存在的领域词构造 slug。旧 task-run 仍不得自证，`no independent primary focus match` 的 blocked run 只保留为顺序反例，不能替代 completed evidence。

e2e runner 只接受原子落盘且顶层头字段唯一的召回产物：`context-brief.md` 必须以
`# Agent Brief` 开头并绑定 `ok=true`、`recall_status=complete`、请求 profile、硬 token budget，且
`Chunks` 顺序包含 canonical 规则、请求 profile 与独立 focus，每个 chunk 都必须带完整 metadata 和
非空正文；`profile-resolve.md` 必须以
`# E2E Resolved Profile` 开头，绑定 `ok=True` 与同一 profile，并让 node count 与 `Nodes`/run manifest
闭包一致，节点序号必须连续且 ID 唯一。completed run 必须全节点 PASS，并把 run/report/manifest/index/
dispatch 的 task/trace/slug、report/manifest 语义时间，以及 resolve/manifest/report/dispatch/`nodes.tsv`
中的 `node_id/source_profile/module/owner/function/status/inputs/outputs/evidence` 全元组逐项绑定；validator 还会现场递归解析当前 `.github/e2e/profiles/<profile>.tsv` include closure，把前八项逐节点回绑 live profile，不能靠一致改写多份产物伪造节点。dispatch 必须严格按 startup 两个 PASS、随后每个节点 `in-progress -> PASS` 的全局顺序出现，11 个 payload 字段全部匹配；每个节点的首要 evidence 必须是该节点 canonical `evidence/<node_id>.log`，可选辅助指针也必须落到 actual indexed ordinary evidence。`evidence-index.md` 会重算每个普通 evidence 文件的路径、尺寸和 SHA-256。
召回、profile resolve、报告渲染、sanitizer、evidence index 或 DB 归档任一阶段失败都必须传播为
非零/blocked，不能由后续成功覆盖。completed 发布采用两阶段契约：先用 `archive-markdown --sync-task-run` 精确同步 staged Markdown；该通用同步既不能创建，也不能撤销已经提交的 publication。随后原子准备绑定 report、manifest、recall、resolve、index、dispatch 与 `nodes.tsv` 哈希的 `complete.marker` 和严格 EOF 的 `completion-publication.md`，最后由专用 `publish-task-run` 在单个 SQLite 事务内复核 marker/artifact/staged DB 快照并提交完成记录。普通归档、promotion、migration、backup 与 rehydrate 都不得创建 completion publication；`runs` 只承认 canonical report header 中的 `db-marker-v1` 和有效 publication。任一 pre-commit 失败都会撤销本次 live marker/publication 并重渲染 blocked；既有已提交 publication 不会被通用同步误删，且 blocked report 不会被 `runs --status completed` 接受。strict guard 同时复核 marker、publication 与 DB/live 精确集合。

RV64 完整双发射/OoO/PPA 的稳定入口是
`.github/instructions/rv64-ppa-optimization-workflow.instructions.md`；架构能力和 promotion 阈值
仍以 `npc/rv64/design/arch/rv64-architecture-ppa-contract.md` 为规范真源。公开 SoC 方法适配后的
`fast/scheduled/candidate` 触发配置位于
`npc/rv64/design/arch/rv64-soc-delivery-gates.tsv`；它决定何时选择证据，不替代任何功能或 PPA 合同。
domain evidence 的“一次登记”以不可变 design/config identity 为单位；RTL、filelist、parameter/define、
约束、工具执行语义或 workload/input 身份变化后必须重新取得对应证据。

RV64 CPI/PPA 日常优化在上述 hard gate 与 promotion 工具之间增加中型 next-slice selector：固定策略为
`npc/rv64/design/arch/optimization-slice-selector-policy-v1.json`，活动候选为
`npc/rv64/eval/ppa/optimization-slices-current.json`，稳定校验入口为
`npc/rv64/eval/ppa/run-optimization-slice-selector.sh --validate-only`。它只从同一 live design-id 的 current
receipt/census 选择下一次状态对账、因果量测、PPA 资格化或可回退 RTL 实验；多目标关系不确定时输出
`RESEARCH_REQUIRED`，不生成新合同、不运行仿真/综合/STA，也不替代 `front.py` promotion。
research-state 不能直接写入 causal/PPA 布尔授权；owner-timing、accepted PPA、decision schema 与对应
verifier 都必须经同 design-id canonical 校验并绑定 hash，输入语义变化后旧 decision 自动失效。

流程判断分为三个正交轴：轻量工作流定义 task class，`rv64-soc-delivery-gates.tsv` 定义
`fast/scheduled/candidate` execution tier，`rv64-soc-maturity-stages.tsv` 定义
`ARCH_DISCOVERY` 到 `PROMOTABLE` 的 design maturity。checker/schema/source 改动由
`rv64-arch-stable-checker-contract` 运行定向单测；只有 current receipt/audit 入口或 current evidence 改动才选择
`rv64-arch-stable-current`。后者只复核已生成的 exact-input current result，不在 agent 收尾重复运行
testbench/仿真/综合/STA；业务验证先执行并用 evidence 登记。
`ARCH_STABLE` 只在独立审查合同、报告和机器 receipt 同时绑定 exact candidate SHA 与 current design-id
后签发；这项检查不进入普通 RTL development 或只读 review。

当前架构债务的机器入口为 `npc/rv64/design/arch/architecture-debt-ledger.json`，其当前设计收据为
`npc/rv64/eval/ppa/evidence/architecture-debt-current.json`。固定 C 指针
`rv64-architecture-debt-current` 只在候选交付阶段复核 retained execution/replay、cohort 与 design-id；
它不替代原始 RTL gate，也不把债务账本层的闭合外推为 whole-architecture 或 PPA promotion。
`rv64-historical-defect-current`采用同一边界。两者只由账本、current receipt、cohort、冻结历史输入或
checker/runner维护面自动选择；普通RTL/TB/product config变化记录旧current失效和maturity GAP，先跑
受影响domain fast，不在日常finish执行必然过期的current-result gate。candidate/release仍必须显式重建。

## 入口文件

- 通用入口：`AGENTS.md`、`.github/AGENTS.md`、`.github/copilot-instructions.md`。
- AI 环境说明：`.github/ai-env/README.md`。
- canonical contract：`.github/ai-env/contracts/agent-env-*.json`。
- live skill：`.github/skills/*/SKILL.md`。
- RTL 子任务契约：`.github/instructions/rtl-agent-task-contract.instructions.md`、
  `.github/skills/prepare-rtl-task-contract/` 与
  `.github/ai-env/contracts/agent-env-rtl-task-contract.json`。
- agent 索引：`.github/agents/AGENT_INDEX.md`，具体 agent 文件直接保留在 `.github/agents/*.agent.md`。
- e2e profile：`.github/e2e/profiles/*.tsv`，模块说明在 `.github/e2e/modules/*.md`。
- 维护脚本入口：`scripts/agent-maintain.sh`、`scripts/agent-e2e.sh`、`scripts/package-ai-dev-env.sh`、`scripts/github_index_db.py`。

## 单一真源与内容去向

| 内容 | 单一真源/去向 | 不应放在 |
| --- | --- | --- |
| 全局行为约束 | `.github/AGENTS.md` 与 path-specific instructions | 每个 agent 重复复制 |
| AI 环境日常导航 | 本文件 | 蓝图、contract JSON |
| 图任务/角色分层 | `.github/agentic-hardware-blueprint.md`、`.github/agents/` | memory 或单次 task-run |
| 可复用流程规则 | `.github/instructions/`；短小通用能力放 `.github/skills/` | DB snapshot、最终回复 |
| 可判定机器合同 | `.github/ai-env/contracts/`、domain checker/policy/schema | 兼容 shim、散文自报布尔值 |
| 自动执行与发现 | `.github/e2e/profiles/`、`scripts/e2e/` | 手工命令清单 |
| 当前稳定事实 | `.github/memory/` retained documents | instructions |
| 单次过程/证据 | `.github/task-runs/` + evidence index | memory 长篇日志 |
| cache/重型运行物 | `.github/cache/`、`.github/runtime-artifacts/` 或外部 object store | tracked source |

旧 `.github/agent-env-*.json` 只作兼容 shim；所有真实修改必须落到
`.github/ai-env/contracts/agent-env-*.json`。

## Database Scope

数据库只保留固定格式的长期记忆和 task-run 日志：`.github/memory/**`、`.github/task-runs/**/{task-report.md,dispatch-log.md,context-brief.md,profile-resolve.md,evidence-index.md,completion-publication.md}` 等；其中 `completion-publication.md` 只能由 `publish-task-run` 提交，不能从普通 archive/backup/snapshot/rehydrate 恢复。agent、instruction、e2e profile/module、contract 和说明文档直接保留为原文件；读取普通文档优先使用文件系统或 `load --source auto`：

```bash
python3 scripts/github_index_db.py load --source auto --path <path>
```

若 `.github/cache/github-index.sqlite` 丢失，可从备份重建：

```bash
python3 scripts/github_index_db.py rehydrate --backup-dir .github/db-backup/stored-snapshot --yes
python3 scripts/github_index_db.py rehydrate --backup-dir .github/db-backup/task-runs --yes
```

## 使用中迭代

AI 环境不是一次性整理项目，而是业务开发中的反馈控制面。每次发现入口冲突、假绿、证据断链或重复规则，都应在当前业务任务内完成最小纠偏：

```text
发现摩擦 / 假绿 / 入口冲突
 -> 归类（导航、规则、机器合同、执行器、证据或长期事实）
 -> 在唯一真源修复
 -> 用反例、mutation 或失败样本证明门禁能抓到问题
 -> 跑真实 domain validation，并用 agent-flow evidence 登记
 -> 目标末尾运行路径对应 gate，生成 compact/durable 结果；memory 只沉淀稳定结论
```

“写了规则但未接入发现与 gate”不算闭环；“命令为 0 但设计点或证据不完整”也不算成功。

## 维护 Gate

日常轻量自检（不调用 Python/DB/profile）：

```bash
scripts/agent-maintain.sh --mode quick
```

AI 环境目标轮次结束：

```bash
scripts/agent-maintain.sh --mode final
```

CI/nightly/商业包：

```bash
scripts/agent-maintain.sh --mode release
```

生成包输出到 `dist/ai-dev-env-commercial-v1/package/ysyx-ai-dev-env-commercial/`，不写回 `deliverables/`。

## 新增规则

- 新增长时间仿真/综合/系统回放 runner：复用 `scripts/task-run-status.sh`，只有本轮 marker、内容哈希和
  cleanup 全部通过后调用 evidence-complete；`EXIT`、clean early-exit 或 `HUP/INT/TERM` 本身不能
  产生 `PASS`。运行 `scripts/tests/test-task-run-status.sh`，并由 `agent-system` profile 的
  `task-run-status-fail-closed` 节点检查 helper、反例和 runner 接线。
- 新增 skill：创建 `.github/skills/<name>/SKILL.md`，再运行 `python3 scripts/github_index_db.py skill-audit`。
- 本地 RTL 子任务派发：先运行 `rtl_task_contract.py create/validate/render`；`create` 自动声明输出
  JSON 自路径，并生成只含 `workspace_root/allowed_paths/write_paths/allowed_commands` 的 schema v2
  `scope`；schema v1 只保留历史 validate/render 兼容。`render` 自动绑定该 JSON 的路径与 SHA-256
  （不绑定设计 `contract.md`）。把这两项
  逐字写入当前 task-run 的 dispatch log。Windows/Codex→WSL 工程命令按 single-flight 调度，当前唯一
  shell ownership 可以交给一个契约授权节点，且只覆盖合同中的一个有界命令批次；完成、GAP、异常或
  中止后必须停止工程进程并归还，无响应节点需经 Windows 进程表确认后强制回收。需要发现遗漏或核对
  源码时默认使用 `workspace-files`；
  只有限定材料复核才使用 `--self-contained-no-tools` 和 `--supplied-material`，使 JSON 原生声明
  `allowed_commands=[]`、无写路径，并只消费提示中冻结的 RTL 材料。所有模式都保留 unknowns、替代假设、反例、
  `scope_extension_request`、置信依据和 `inconclusive` 出口，不得强制 PASS 或设置固定发现数量上限。
  任务自然语言使用 `rv64-hardware-professional` 术语；子 agent 渲染提示不携带 `review_pending` 等协调
  状态，真实 RTL 标识符及 CPU 特权/保护/访问异常术语不改写。该措辞剖面不使用关键词黑名单，并与
  能力分档正交。`agent-system` profile 的 `rtl-task-contract` 节点负责 workspace-files、no-tools、硬件
  语境渲染和合同范围反例门禁。
- 新增 agent：创建或更新 `.github/agents/<name>.agent.md`，并同步 `.github/agents/AGENT_INDEX.md`。
- 新增长期工作流：先写 path-specific instruction，再接入相关 agent、profile/module contract 和反例 gate；单次 task-run 只能留证，不能成为规则依赖。
- 新增 e2e profile：添加 `.github/e2e/profiles/<name>.tsv`，必要时补 `.github/e2e/modules/<module>.md` 和 `scripts/e2e/modules/*.sh`，再运行 `scripts/agent-e2e.sh --validate-all-profiles`。
- 修改 live skill/instruction/profile 后，手工 `brief` 前对相关路径运行 `github_index_db.py refresh`；正式 `agent-e2e.sh` 会在生成 startup brief 前自动重建 active live 索引并留下 `context-live-index-refresh.log`，目录级排除 retained/history，且 missing 状态只更新实际扫描且未排除的路径，从流程上拒绝旧规则 chunk 假装成当前召回而不破坏 DB-first memory 状态。

## 禁放目录

- `.github/cache/`、`.github/runtime-artifacts/`：运行态 cache/payload。
- `.github/task-runs/**/evidence/`：原始证据 payload，只保留 `evidence-index.md` 和 `run-manifest.json` 指针。
- `.github/archive/`：只保留 `ARCHIVE_MANIFEST.md`、`CHECKSUMS.txt`、`POINTERS.md`。
- `.github/shujuku_aireview/`：一次性审计材料，不作为 active 配置目录。
- `deliverables/**/package/`、`dist/`、`build/`：生成物目录。
