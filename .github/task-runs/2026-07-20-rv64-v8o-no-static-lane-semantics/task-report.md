# v8o 任务报告：把 DI-4 固化为工作区常驻硬门

## 本轮结果

本轮没有修改生产 RTL 功能，而是修复了一个会造成假绿的架构 checker，并把既有动态 capability steering 的 DI-4 证明固化到日常 Makefile 工作流。当前设计上 `DI-4`、`OOO-1`、`OOO-2` 为 GREEN；其余硬门和整体架构仍为 RED，PPA 未运行、未发布。

## 根因与修复

原 checker 没有识别生产 RTL 实际使用的 `ctrl_is_alu_terminal_capable`，因此在“未发现 capability restriction”时仍可能让 DI-4 source checks 通过。这不是 RTL 功能错误，而是证据门的 vacuous pass。

修复后，checker 对生产数据流执行 fail-closed 精确检查：predicate 定义与引用、每 entry metadata、两个 dispatch capture、compaction copy、selector projection/input，以及 swap 定义、两个 terminal 绑定和输出绑定都必须出现且计数无歧义。注释被剥离，不能充当实现证据；缺失 predicate、静态 entry 绑定、slot1 capture 丢失或 swap 丢失都会被单测拒绝。

## 动态行为证据

定向 TB 对 branch、JAL、JALR、load、store、MulDiv 各自在两个 accepted dispatch 位置运行，共 12 个排列。每例要求：

- 两个非空 uop 在同一上升沿接受；
- 两项先在 IQ 中完整驻留一拍，排除 dispatch bypass；
- 两个 physical terminal 在同一上升沿 actual-fire；
- complex uop 始终去 Universal，simple ALU 始终去 ALU terminal，与 dispatch 位置无关；
- 24 个 distinct、generation 非零的完整 ProducerId 从接受到 fire 一一匹配；
- 只有一个空闲 entry 时，slot0 接受、slot1 backpressure，且不会误记 pair/permutation coverage。

六个 compile-success 变异分别破坏 pair swap、把 capability 静态绑到 entry、丢掉 slot1 capability、把 MulDiv 误标为 ALU-capable、串行化第二 terminal、损坏完整 ProducerId。每个变异都记录 source/image SHA、编译/展开成功、激活 witness 与目标语义拒绝；编译失败、超时或无关 assertion 不算 mutation kill。

## 审查闭环

前置无工具审查以 `self-contained-no-tools` 合同运行，不涉及 shell、文件、网络、账户、凭据、外部服务或写操作，提出 G01–G09 九类缺口。本轮把它们逐一转化为可执行门：同沿接受、完整驻留、canonical fire、输入 ctrl 派生覆盖、immutable full-PID scoreboard、checker 非空匹配、mutation activation、双 profile/provenance、DI-4-only 原子发布。

实现后审查用同样的最小权限合同复核静态 dispatch 绑定、bypass、跨拍串行、ctrl alias、PID 替换、split-accept 假计数、vacuous checker、inactive mutant、stale evidence 与越级发布等反例，结论 PASS、blockers 为空。两份审查 JSON 的哈希与适用边界均登记在 `dispatch-log.md`；审查意见只生成/检查门，不直接充当架构证据。

这种协作方式已实战验证：子 agent 任务先声明纯文本输入、禁止工具和外部状态、只输出 schema 固定的审查结果；真正的 RTL/仿真/证据写入由主任务在工作区本地完成并经永久命令复验。它减少了与 RTL 无关的模糊措辞和过宽权限，也不会靠规避安全审查获得结果。

## 已知剩余风险

- 有限 directed/mutation evidence 不是形式化穷尽；绑定源变化后必须重跑。
- `DI-1/2/3/5`、`OOO-3/4` 仍为 RED；当前只有一个 Universal/memory terminal，不能声称双 memory issue。
- lint 仍有 115 条既有 warning；其中 LATCH/UNOPTFLAT 需单独原子任务定位，不能用本轮通过项掩盖。
- 在所有架构硬门关闭前，不进入 PPA 晋级或达标措辞。

## 工作流入口

日常修改触及 IQ capability/steering、相关 TB、checker、builder、Makefile 或证据合同时，必须运行：

`make -C npc/rv64 check-no-static-lane-semantics`

交付还必须继续经过工作区的 memory 更新、相关 agent-e2e profile 与 `scripts/agent-e2e.sh --guard --guard-mode strict`。完整路径和失效规则见 `evidence-index.md`。
