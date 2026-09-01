# Agent E2E Workflow

`scripts/agent-e2e.sh` 用于用户明确要求的端到端场景、profile 本身开发、跨栈集成、持久长跑以及
release/security/forensic/publication。它不是普通 review、实现、修 bug 或局部验证的默认前置/收尾门。

## Pick the profile that matches the claim

- NEMU-only 开发：`scripts/agent-e2e.sh --profile nemu-dev`
- NEMU-only full gate：`AGENT_E2E_NEMU_UBUNTU_FULL_GATE=1 scripts/agent-e2e.sh --profile nemu-dev-full-gate`
- NPC-only 开发：`scripts/agent-e2e.sh --profile npc-dev`
- 跨栈集成：`scripts/agent-e2e.sh --profile nemu-ubuntu-integrated`
- AI 环境显式发布检查：`scripts/agent-e2e.sh --profile agent-system --publish`

profile 名称限定它能支持的工程结论。NEMU-only 结果不代表 NPC，NPC-only 结果不代表完整 Linux/Ubuntu，
focused case 不代表 profile 的完整合取，低层 smoke 不得越级。

选择最小能判断 acceptance criterion 的 profile 或 node。不要因为修改路径、文件数或存在 e2e 工具就
自动运行 profile；也不要在目标已经由直接组件测试判定后再跑 e2e 复制同一结论。

## Scenario isolation is a resource rule

`nemu-dev*` 和 `npc-dev` 保持场景隔离，`nemu-ubuntu-integrated` 保留显式跨栈能力。profile validator 与
dispatch 可以检查节点归属，防止 NEMU-only 配置意外拉入 NPC 节点，反之亦然。

runtime isolation 只处理真实共享资源：同一 build/scratch、current artifact、数据库、端口、许可证或设备。
宽泛进程名扫描默认只是 advisory，`off` 可跳过它；调用者显式选择 `strict`/`fail` 时，可把匹配作为保守
preflight 并 fail closed，但匹配本身仍不证明真实冲突。严格可复现实验以具体 runner 的规范化路径、
端口、设备或 lock identity 排它为准。历史 stale client 若确实占用上述资源，应先确认目标进程再清理。
互不冲突的读取、分析和独立 scratch 构建可以并行，不存在 workspace-wide single-flight shell。

## Context and task labels

只加载当前 profile、相关 module contract、直接源码/配置与 acceptance criteria。需要历史 task-run 或
跨会话决定时才运行 bounded brief、`runs --profile` 或 `evidence --run-id`；普通 e2e smoke 不要求先刷新
所有 DB、发布 memory 或构造 recall 闭包。

`task_slug` 是人类可读的运行标签和目录区分符，不是授权身份或语义检索 gate。使用稳定、可辨识的短名；
不需要从 slug 推导最多八个 focus token，也不因历史文档缺少同词而拒绝执行当前工程场景。

复杂 RV64 子任务可以使用可选结构化 handoff，原则见
`.github/instructions/rtl-agent-task-contract.instructions.md`。profile 不要求每轮生成/校验 JSON contract、
绑定 SHA、固定 `fork_turns`、设置 `review_pending` 或把普通结果降成 candidate-only。只有 profile 的明确
acceptance criterion 就是兼容 generator 时，才运行它的直接自测。

## Execution and evidence

每个实际运行的 node 必须对应一个清楚的工程 claim，并保存判断该 claim 所需的结果。真实性能、RTL、
Linux/Ubuntu 和设备 profile 的具体 markers、oracles、negative scans 与结论边界由对应
`.github/e2e/modules/*.md` 和 runner 定义。

以下规则保持 fail-closed：

- non-zero exit、timeout、signal、中断或缺失 terminal evidence 不得写成 PASS；
- persistent/published 长跑只有 workload、必要 evidence 与 cleanup 都完成后才能 PASS；
- DiffTest/compare 必须绑定两侧可比较产物；
- PPA 必须绑定相同 RTL/filelist/config/tool/corner/workload；
- full profile 的 PASS 只代表该 profile 明示的合取，不代表未运行场景。

固定输入、固定命令、固定 tool/seed/thread 且 oracle 确定时运行一次。随机、并发、flaky、测量噪声、
机器异常或用户明确要求时才重复，并在运行前说明次数、阈值与停止条件。

版本控制内未修改且有自身测试的 runner/checker/parser 默认可信。只有本次修改了它、观察到异常接受/
拒绝、矛盾输出、缺失文件或可疑 fallback 时，才运行相应 verifier 自测；不要先重验 validator 再验证
真实 workload。

## Persistence and publication

普通显式 e2e 默认使用 runner 的 compact/direct 模式，只保留本轮直接结果。需要跨会话继续、正式
release/security/forensic/publication 或用户明确要求时，才选择 durable；`--publish` 才启用 DB recall、
manifest、SHA/size 绑定和 publication。独立 reviewer 仍只由高风险边界决定，不因 durable 自动出现。

- `compact` 保存结论、输入范围、命令、返回码和必要指针；
- `durable` 保存长期运行恢复与正式 publication 所需的有界 evidence；
- hash 只用于 byte identity、cache integrity、release provenance、security 或明确 reproducibility；
- strict guard 只用于显式 release/migration/security/forensic，并提供准确 path/paths-file；
- candidate/reviewer 只用于高风险、难恢复、正式 Architecture/Pareto promotion、对外发布或用户要求。

archive、backup、rehydrate、memory 更新和 report 生成不应改变工程 PASS/FAIL；它们失败时只影响对应的
persistence/publication criterion，不能回写或伪造原始 workload 结果。

## Result review

运行后先看实际 node 的命令、配置、返回码、terminal marker 和最接近根因的日志。最终报告说明：

1. 哪个 profile/node 在什么配置下运行；
2. 哪些 acceptance criteria 得到满足；
3. 哪些层级或场景没有运行；
4. 是否存在 timeout、信号、缺失 evidence、异常 fallback 或资源冲突。

不要只引用外层 task-run 状态，也不要用 profile resolve、hash、marker 数量、memory 更新或 verifier PASS
替代实际工程行为。
