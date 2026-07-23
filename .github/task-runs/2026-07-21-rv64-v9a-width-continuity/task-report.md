# RV64 V9A DI-2 双发射宽度连续性硬门报告

## 工程范围

本轮仅处理授权工作区内的本地 RV64 双发射 OoO Verilog/SystemVerilog 核、Icarus RTL 仿真、架构证据检查器和任务审计产物。文中的事务、端口、队列、反压、变异、载荷、身份和生命周期均指处理器 RTL/EDA 对象；所有验证变异都只作用于临时 RTL 副本。该措辞规范用于准确标明硬件对象、层级、范围和验证目的，不降低反例构造、动态检查或模型推理能力。

## 本轮结论

- V9A `DI-2 width_continuity` 在冻结的证明域和最终 suite/design 绑定内为 scoped `GREEN`。
- 同一 `design_id` 下 `DI-1/DI-2/DI-3/DI-4/DI-5/OOO-1/OOO-2/OOO-3/OOO-4` 九项架构硬门全部 `GREEN`。
- 本轮没有修改 `npc/rv64/vsrc/**` 生产 RTL；交付内容是 DI-2 focused TB、证据构建器、架构门、验证变异、永久命令和审计材料。
- PPA 仍为 `UNQUALIFIED`，`promotion_eligible=false`。本轮只关闭架构宽度连续性缺口，不宣称正式 PPA 已完成。
- 长期 RV64 OoO/PPA 目标保持 active；下一步是架构稳定冻结及正式 PPA 基线资格检查。

## 实现者交付

1. 在真实 `NpcCoreTop -> OooCoreTopGlue -> OooFrontend/OooExecuteBackend -> OooAluCoreSlice -> OooAluDecodeBackend -> OooIntBackend -> OooDispatchBackend` 链路上加入 `MODE_WIDTH_CONTINUITY` focused 模式，使用按 PC 独立派生的 RV64I `ADDI rd,x0,imm` 流。
2. 以唯一首个 fetch request fire 为锚点，固定预热 24 周期并采样固定 64 周期；fetch、decode、rename、dispatch、issue、execute、retire 七个边界每拍都必须恰为 2 个 uop。
3. 以 PC 派生 `inst/rd/imm/result`，并跟踪完整 `ProducerId` 的 `allocated -> issued -> executed -> retired` 生命周期；rename、ROB、IQ、EX stage、WB/ROB 和 commit 均使用独立 sink witness。
4. EX→WB 对真实 `PipeStageReg` 建立 N→N+1 逐 lane 全字段 ledger，核对 `ProducerId/pdest/result/exception/cause/tval/fwd`，因此 valid 保持为 1 时的 lane payload 串接也不能假绿。
5. drain 只关闭新的 fetch request admission，继续开放已接纳 response、后端消费与 commit；最终检查请求/响应/入队守恒、FIFO/ROB/IQ/EX holder 清零、free-list 回到 32、无活动 ProducerId。
6. 固定窗口负例在测量段第 17 个 trace cycle 形成一次 request-admission 缺口；七边界都变成 `126/peak2/dual63`、IPC 1.968，并被动态拒绝，证明窗口不会滑到后续干净区段。
7. 十一项 compile-success RTL 验证变异覆盖 fetch payload、decode→backend、rename/ROB/IQ sink、issue terminal、EX capture、EX full payload、WB→ROB、retire 和 lane1 immediate。11/11 均编译成功、形成非同一临时 RTL 镜像，并被对应动态 oracle 拒绝；生产源 pre/post 不变。
8. 新增永久入口 `make -C npc/rv64 check-width-continuity`。canonical runner 会在当前完整 design 上重建八项 predecessor 证据，再发布 DI-2 并检查 sibling preservation、source/provenance 哈希和九项架构门。

## 规范运行证据

- canonical command：`make -C npc/rv64 check-width-continuity`
- suite：`v9a-di2-20260721T101435Z-1815092`
- design_id：`sha256:6236b176da0c10bccac9c2feb405a0d65ba586d826616f0beaeee0cbbfe2f3dc`
- 完整可综合 RTL 源集：145 个文件
- focused assert/release：`2/2 PASS`，逐周期 trace SHA-256 `1bb38f328b19b3c1f6371b513883975e5cc3756bb49365ffdd1245f2ef966ab1`
- 七边界：每个边界均为 `cycles=64,total=128,peak=2,dual=64`；独立整数 ALU IPC=`2.000`
- identity：`fetched=decoded=renamed=dispatched=issued=executed=retired=178`，`active_pid=0`，payload/lifecycle error=0
- drain：`requests=responses=enqueues=89`，FIFO/ROB/IQ/EX holder=0，free-list=32
- 固定窗口扰动：`DYNAMIC_REJECT`，七边界均为 `total=126,dual=63`，retire IPC=`1.968`
- compile-success RTL 验证变异：`11/11` 动态拒绝，且 production source unchanged
- 相邻回归：`8/8 PASS`
- 同设计 predecessor：8 项全部重建并绑定当前 design_id
- source manifest：43 个唯一文件，聚合 SHA-256 `d293f713eb1a0ec92e8bf547e6b86957daf61bea39820f404453ce518b416870`
- source pre/post 文件 SHA-256：均为 `175e936535f57e665029fdcbf0a6de3b31d2813dfde63c05403ec4023e0c6c3a`
- provenance：73 个唯一文件，聚合 SHA-256 `180630f9d64dfe0585a556d41133451350e0267a10f9eabf533b17739debc2f7`
- 九项架构硬门：全部 `GREEN`

## 根因与纠偏

1. DI-2 先前缺少对整条七边界双宽连续性的专用、固定窗口、完整身份和独立 sink 证据；已有局部吞吐或 sibling 证据不能替代端到端 width continuity。
2. v1 合同审查指出父层 fire 不能替代 ROB/IQ/EX/WB 内部 sink、PC/PID 不能替代 payload、可滑动窗口会假绿，以及 drain 不能依赖 flush。上述反例均转成 focused ledger、固定窗口扰动、natural drain 和编译成功的 RTL 验证变异。
3. v2 终审进一步发现两个真实缺口：EX→WB 尚未显式做前一拍完整 stage payload 到后一拍 down-side 的核对；相邻回归日志虽已绑定，但其 TB 源未全部进入精确 provenance。两项均在最终 canonical run 前修复，并新增 `ex1_stage_payload_alias` 变异。
4. 最终 runner 先重建全部八项 predecessor，再用原子 merge 发布 `width_continuity`；发布前后 sibling records 保持不变，避免旧 design 混用或 DI-2 自证循环。

## 独立审查

- v3 只读终审合同：`subagent-contracts/v9a-di2-final-evidence-review-v3.json`
- 合同 SHA-256：`386e81af255c9277db304abaf455327dc3f3743462c8efce7123c7396940de2b`
- 审查结论：boundary/event/identity/window/sink/mutation/provenance/drain/claim 九类均 `PASS`；v2 两项阻塞已闭合。
- 审查未修改工作区或生产 RTL；完整裁决见 `final-review-v3-result.md`。
- 非阻塞边界：聚焦 ADDI 流中的异常字段多数为常量；drain 最后一拍对部分内部控制线的直接观测较窄；178 条 uop 覆盖多次 ROB 环绕，但未覆盖完整 8-bit ProducerId 命名空间回卷。

## AI 工作流收尾

- `project-status`、`modules/npc` 和 `modules/agent-system` 已通过 `update-stored --refresh-shim` 更新 DB-backed memory；`doctor --fail-on-drift` 为 `blocking_drift=0`，未直接编辑 memory shim。
- bounded recall `brief "RV64 DI-2 width_continuity ProducerId" --profile npc-dev --focus-scope non-history --max-tokens 2400` 为 `complete`，`focus_match_count=2`，primary focus 命中 `modules/npc` 的 V9A DI-2 新事实。第一次同时使用英文 `stable/freeze` 的查询因中英文词形不一致而无独立 focus，已明确重试并未掩盖失败。
- task-specific `npc-dev` e2e `.github/task-runs/2026-07-21-2026-07-21-rv64-di2-width-continuity-final-rerun/` 为 `completed`，5 个展开节点全部 PASS，`publication_contract=db-marker-v1` 且 DB 查询确认 `publication_valid=true`。第一次 launcher 的短时 timeout 不作为交付依据，最终使用独立 rerun。
- fresh `agent-system` e2e `.github/task-runs/2026-07-21-rv64-di2-width-continuity-producerid/` 为 `completed`，10 个展开节点全部 PASS，`publication_valid=true`。前一个 `hardware-wording-final` run 的 10 个执行节点虽全部 PASS，但 task slug 无法形成独立 non-history focus，因 `context-brief=WARN` 被正确标为 blocked；最终通过更准确的 RV64 门名和 ProducerId 检索键重跑，没有改变 profile 或降低门槛。
- 本 task-run raw evidence 已由 `index-evidence --write-index` 登记 44 个资产，生成的 `evidence-index.md` 已同步进入 DB/backup。
- `audit-db-first` PASS：`candidates=6829/stored=6871/materialized=6619/shims=28`；`audit-markdown-coverage --fail-on-live-evidence` PASS：`live_evidence=0`。
- `scripts/agent-e2e.sh --guard --guard-mode strict` PASS；当前工作树要求 `agent-system`、`npc-dev`、`github-index` 三个 profile，分别命中有效 completed evidence。
- 两个本轮可再生 smoke build 目录在确认绝对路径位于 `npc/rv64/testbench/` 后已清理；canonical task-run evidence 保留。

该归档层不属于已冻结的 43 项 DI-2 source manifest，不会反向使当前架构证据失效。

## 主要产物

- 任务合同：`contract.md`
- RTL/边界推导：`rtl-derivation.md`
- holder census：`holder-census-delta.md`
- canonical runner：`run-focused.sh`
- 验证变异 runner：`run-v9a-mutations.py`
- 最终机器结果：`evidence/final-run/result.json`
- 架构结果：`evidence/final-run/static/architecture-result.json`
- 最终独立审查：`final-review-v3-result.md`
- 子任务派发审计：`dispatch-log.md`
- raw evidence 索引：`evidence-index.md`

## 下一步

以当前九项架构门同 design_id 全绿为输入，执行架构稳定冻结检查，明确 freeze manifest、允许变更边界和失效条件；只有冻结完成且正式 PPA 入口满足资格合同后，才进入 timing/area/power 的基线采集、热点归因和单变量优化闭环。
