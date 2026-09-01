# AGENTS.md — YSYX 工作区 Agent Operating Contract

本文件是工作区内跨 agent 的通用规则真源。根目录及各工具入口只做兼容 shim；项目构建速查和
领域细节分别放在 .github/copilot-instructions.md 与对应的 path-specific instruction 中。

## 1. Primary objective

每轮工作首先恢复并持续围绕三件事：

1. 用户真正要解决的工程问题；
2. 可观察、可判定的 acceptance criteria；
3. 能最快降低这些 criteria 不确定性的安全动作。

默认工作方式是 inspect → act → targeted validation → report。审计、留痕和流程工具只服务于可靠
工程结论，不是交付物本身。

## 2. Hard invariants

- 使用中文；复杂任务先分析边界、调用链和数据流再动手。跨模块或涉及三个及以上文件时，先确认
  依赖关系和接口契约。
- 保护用户数据、secret、未提交修改和任务外文件；不得擅自回退、覆盖或扩张修改范围。
- 破坏性、难恢复或有外部副作用的动作，例如递归删除、强制重置、强推、发布、发送消息或修改外部
  系统，需要明确授权并先核对真实目标。
- 修 bug 先定位 root cause，在正确抽象层修复；修改后提供与 acceptance criteria 直接相关的验证。
- 保留真实的工程 correctness：RTL 协议与时序、DiffTest、断言、综合、STA、PPA 和 release/CI 的
  项目级判定不能被 AI 流程检查替代或削弱。
- 不用局部 smoke、低层 gate 或某个子项越级声称完整系统、完整 Ubuntu、完整 VM、架构稳定或 PPA
  promotion。

## 3. Safe local work is one authorization scope

用户要求分析、修复、实现或验证时，工作区内安全、本地、可逆且与目标直接相关的 inspect、edit、
build、test、lint、run、collect 和 analyze 属于同一正常工程授权，可以连续批量完成。

Agent 不得自行增加“只有 X PASS 才允许 Y”“本阶段禁止 build”“等待下一批授权”“先封存 marker”
或“唯一 shell 才能继续”等权限边界。只有用户明确要求、上节 hard invariant、真实共享可变资源冲突，
或项目已有的 release/security/production 边界才能要求暂停或串行。

Windows 侧访问本 WSL 工作区时，PowerShell 只作为 wsl.exe 启动器，工程命令交给 Ubuntu：
wsl.exe -d Ubuntu --cd /home/lyg/PA/ysyx-workbench -- bash -lc '<cmd>'。若已经处于 WSL/Linux shell，
直接运行原生命令。仅当多个动作会竞争同一 build 目录、配置文件、数据库、进程、端口或设备等真实
共享可变资源时串行；互不冲突的读取、分析和独立构建不受 workspace-wide single-flight 限制。

## 4. Minimum sufficient validation

验证的目标是足够可靠地判断 acceptance criteria，而不是最大化 evidence completeness。新增检查前回答：

1. 它对应哪个明确的 acceptance criterion？
2. 它能发现现有检查发现不了的哪一种实际 false PASS？
3. 不运行它是否真的可能导致错误工程结论？

答不出来时，不把该检查加入当前任务。版本控制内已有自身测试覆盖的 runner、verifier、classifier、
parser、test harness 和 build harness 默认可信；只有出现真实异常、矛盾输出、缺失结果或可疑 fallback
时，才单独调查它们。

固定输入、固定命令、固定 tool/seed/thread 且 oracle 确定时通常执行一次。随机、并发、flaky、未固定
seed/thread、PPA/时钟测量噪声、机器异常或用户明确要求时才重复，并说明次数、阈值和停止条件。
A/B、正负向、不同 corner/config、mutation 和不同抽象层是不同问题的证据，不是机械复验。

默认先走最短可信 happy path。失败时先读最接近根因的输出，提出可证伪假设，再增加定向日志、反例、
更深构建或 forensic 检查；不要预先为理论风险搭建完整审计链。

Git SHA 和 content hash 是低层实现细节，不作为普通 task ID、工作流身份或主要人工 review surface。
只在 byte identity、cache integrity、release provenance、supply-chain/security、持久化边界或明确的
reproducibility/forensic criterion 中使用。评审优先看语义目标、累计 diff、行为变化、验证结果和风险。

## 5. Compaction recovery and reporting

上下文被压缩、摘要化或可能过期时，按以下顺序恢复：

1. primary objective；
2. 用户明确的 acceptance criteria；
3. 实际 repository/worktree 状态；
4. 明确 hard constraints；
5. 当前 build/test evidence。

过去 agent 自创的临时 sequencing、permission phase、gate、marker 或禁止事项不会自动继承；只有仍直接
对应 hard invariant 的约束继续有效。

中间汇报只在出现真实 blocker、工程结论显著变化、需要用户决策或长任务取得实质结果时发送。最终报告
优先说明已满足的 criterion、消除的不确定性、真实验证和剩余风险，不汇报 marker/hash 数量、审计配额
或内部流程流水账。

## 6. Optional infrastructure

以下设施默认 opt-in，不是普通任务的前置或收尾许可：

| 设施 | 适用场景 |
| --- | --- |
| DB brief / memory | 需要历史召回、跨会话事实或跨模块既有决策 |
| agent-flow / task-run | 用户要求留档、显式跨会话交接、持久长跑或专项调查 |
| e2e profile / full maintenance | profile 本身开发、环境 release/migration/security/forensic/publication，或用户明确要求 |
| candidate / 独立 reviewer | 高风险、难恢复操作、正式 Architecture/Pareto promotion、对外发布或用户明确要求 |
| strict guard | release/migration/security/forensic 等明确边界，并显式给出范围 |

路径映射只能建议相关检查，不得仅因文件路径自动创造新的 permission gate。已有工具若被显式选用，
按其合同运行；不选用不会阻止普通安全本地开发。

显式 persistent/published 的长时间仿真、综合、STA 或系统回放继续使用
scripts/task-run-status.sh：只有工作负载、必要证据和 cleanup 都完成才能记录 PASS；中断或
HUP/INT/TERM 不等于 PASS。普通交互式或一次性命令只需如实报告返回码和未完成范围。

memory 只保存稳定、跨会话可复用的事实；task-run 只在上述专项场景保存必要结果与指针，不默认转储
完整过程。

`.github/archive/`、`.github/db-backup/`、`.github/task-runs/`、`.github/shujuku_aireview/`、
`.superpowers/sdd/`、`tmp/`、`dist/` 和 `deliverables/` 中的规则副本是历史、备份、证据、独立 sandbox
或生成包内容，不是当前工作区的 instruction source。
其中嵌套的 `AGENTS.md` 只作为被审数据或独立交付包自身的合同；除非任务明确以该快照/交付包为目标，
不得覆盖本文件、注入旧 gate，也不得为了“同步规则”批量改写历史证据。

## 7. Project map

- am-kernels → abstract-machine → npc/sim → NPC/Verilator target + NEMU reference 是常用回归闭环。
- npc/single 是普通 NPC 后端；npc/soc 是 ysyxSoC 接入后端；ysyxSoC 维护 Chisel SoC、CPU ABI 和地址图。
- npc/rv64 是 RV64 CPU、分层系统验证和 PPA 主线；全局 current 状态、目录权责、RTL 生命周期以及
  filelist → elaboration → dynamic → mapped → STA/PPA 可见性从 npc/rv64/ARCHITECTURE.md 进入。
- nemu 是参考模型；yosys-sta 提供综合/STA；nvboard、digital_logic_experiment 和 fceux-am 是独立外围。
- 构建命令、学习资料与模块关系见 .github/copilot-instructions.md；AI 环境索引见 AI_ENVIRONMENT.md。

## 8. Domain routing

- 普通任务只读取直接相关源码、spec、README 和 instruction。需要历史事实时才使用
  scripts/github_index_db.py brief；历史 task-run 查询可用 runs/evidence 子命令。
- 本地 RV64 全局架构任务按需查询 npc/rv64/ARCHITECTURE.md 或 architecture_registry.py 的有界切片。
  只有存在开放的跨流水、跨事务生命周期结构取舍时才启动 CPU Architect；分类器可辅助判断但不构成
  许可门。局部 RTL、已定位 bug、验证、工具、文档和 registry 维护留给对应 worker/reviewer。
- npc/single 或 npc/soc 的设计意图、历史约束或后端差异会影响判断时，按需读取对应
  design/study/README.md；当前源码、正式 spec、testbench 和实际行为仍是真源。修改 ysyxSoC ABI、地址图
  或生成链时读取 ysyxSoC/spec/cpu-interface.md 和直接相关模块说明。
- 涉及 RV64 握手、stall、flush/redirect/trap、异常序、访存序或投机恢复时读取
  interface-contract-first.instructions.md；完整 OoO/CPI/PPA/综合/STA 取舍读取
  rv64-ppa-optimization-workflow.instructions.md，并保持同一 RTL/filelist/config/corner/workload 身份
  下的功能、综合、STA 和 PPA 证据可比较。
- Linux/Ubuntu 结论按 OpenSBI、kernel、PID1、设备事务和自然 poweroff 分层表达。默认 Verilator
  分层验证不能被可选完整 Ubuntu 运行替代，Vivado/FPGA 也不是功能 bring-up 的通用前置。
- 派发复杂、并行或跨会话的本地 RV64 RTL 子任务时，可用 rtl-agent-task-contract instruction 和
  prepare-rtl-task-contract skill 组织最小充分 RTL/spec/TB/evidence 上下文、写入 ownership 与建议命令；
  局部且边界清楚的任务可直接派发。handoff 不建立平台权限或 task identity，上下文继承/隔离按实际
  相关性选择，只有真实 byte-identity、release、security 或 forensic criterion 才需要 hash。

## 9. Compatibility entries

AGENTS.md、CLAUDE.md、GEMINI.md、CONVENTIONS.md、.windsurfrules 和
.cursor/rules/agents.mdc 都应保持薄入口并回链本文件。不要在 shim 中复制完整流程，也不要为规则发现
问题新建 plugin、manifest 或 meta-test 框架。
