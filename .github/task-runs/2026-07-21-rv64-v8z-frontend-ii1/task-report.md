# RV64 V8Z DI-1 Frontend II=1 硬门报告

## 工程范围

本轮只处理授权工作区内的本地 RV64 双发射 OoO Verilog/SystemVerilog 处理器前端、testbench、Icarus 仿真、静态 checker、架构证据与任务审计产物。多义术语均限定为 RTL 信号、流水线事务、cache-hit 取指包、断言反例或 compile-success RTL 验证变异；不涉及网络扫描、远程主机、账号、凭据、第三方服务或未授权系统。措辞约束用于准确界定硬件工程对象和权限，不改变验证强度、反例能力或平台审查边界。

## 交付结论

- DI-1 `frontend_ii1` 在最终 design/suite 绑定内为 scoped `GREEN`。
- `DI-1/DI-3/DI-4/DI-5/OOO-1/OOO-2/OOO-3/OOO-4=GREEN`；`DI-2/overall=RED`。
- PPA 仍为 `UNQUALIFIED`，`promotion_eligible=false`；本轮没有 production RTL 功能修改，也没有正式 PPA 晋级。
- 长期完整 OoO/PPA 目标保持 active；下一架构主线是 DI-2 fetch→decode→rename→dispatch→issue→execute→retire width continuity。

## 实现者交付

1. `tb_ooo_core_top_glue.sv` 新增专用 `MODE_FRONTEND_II1`，在真实 `OooCoreTopGlue/OooFrontend` 中持续提供两个独立整数 NOP 的 cache-hit packet。steady window 穿过 request、response、PacketDecode enqueue、registered FIFO dequeue、rename/dispatch/backend，而不是只测 Bridge leaf。
2. testbench 建立两个独立 PC ledger：request fire→response owner，以及 enqueue PC→FIFO dequeue PC；同时要求 successor request PC 等于当前 response owner PC+8。accepted、response、enqueue 与 produced 使用不同观测点，避免同源计数假绿。
3. backpressure 子段使用 `run_i=0` 在真实 outstanding response 上阻塞四拍，检查 valid、owner 和双 lane payload 保持，禁止 response fire、重复 enqueue 或 replacement request；恢复后连续完成 16 turnover。选择该阻塞点的依据是 `fifo_count+outstanding_count<=depth` reserve 不变量：合法 outstanding 已预留 FIFO slot，因此 full-FIFO held response 不可达。
4. epilogue 只关闭外部 successor admission并继续排空尾 response、FIFO 和 backend，最终精确得到 `requests=responses=enqueues=dequeues=83`，outstanding/FIFO/ROB/IQ/ghost 为零，free-list count 为 32。
5. 新增九项 production-RTL 临时副本验证变异，分别切断 Bridge H1 ready/state、semantic lookup、FlowControl outstanding/enqueue credit、Sequencer replacement、真实 sink dequeue、successor PC 和 blocked-response tail owner。九项都编译成功，且都被对应动态 oracle 拒绝；生产源码 pre/post 不变。
6. 新增永久入口 `make -C npc/rv64 check-frontend-ii1`、专用 evidence builder、parser/negative unit test 与 architecture hard-gate fail-closed inventory。builder 精确绑定命令、marker、metrics、source pre/post、变异、同设计 predecessors、日志和 provenance，并以原子 merge 发布 `frontend_ii1`。

## 规范运行证据

- canonical command：`make -C npc/rv64 check-frontend-ii1`
- 最终 suite：`v8z-di1-20260721T082600Z-1762933`
- design_id：`sha256:6236b176da0c10bccac9c2feb405a0d65ba586d826616f0beaeee0cbbfe2f3dc`
- 完整可综合 RTL 源集：145 个文件
- focused：Bridge assert/release + Frontend assert/release，`4/4 PASS`
- DI-1 hard metrics：`5/5 GREEN`
- steady frontend：`accepted=responses=enqueues=dequeues=64`、`max_ii=1`、`sequential=64`、`redirects=0`、`stalls=0`
- finite backpressure：`held_cycles=4`、`resume_turnovers=16`、payload/owner stable、duplicate enqueue=0
- tail conservation：`83/83/83/83`，所有 owner/storage/backend holder 归零
- compile-success RTL verification mutations：`9/9` 编译成功且均被定向 oracle 动态拒绝
- 相邻回归：`6/6 PASS`
- source manifest：29 个唯一 proof 文件，聚合 SHA-256 `0ad4ba30f61477ac3fe742ba0f3a662e444d51478a1f5da7ac3b3303072e7e64`
- source pre/post 文件 SHA-256：均为 `0d4c864fb4edbdfd77154920b54de53fbfba7fd040a0483aaf28c4785783b3f8`
- provenance：56 个唯一文件，聚合 SHA-256 `90af72cea16b6a94d6c20e21bc0ce6adcd5ab376f9cc4713ea2cad02768d3b27`
- frontend architecture gate 日志 SHA-256：`b9fa101a79f6a17a1bd8dccf3a0274e61c828de81ed4c4dea7dfef4bde585dd6`
- raw evidence index：42 个资产

## 根因与纠偏

1. 初始 DI-1 为 RED 的直接原因不是本轮发现了新的 production RTL 功能错误，而是 architecture manifest 缺少专用 `frontend_ii1` record；已有 Bridge H1 吞吐证据不能独自证明真实 Frontend sink、PC identity、backpressure 恢复和尾部 owner 守恒。
2. 首轮 workspace reviewer 未在限定时间内给出可审计 verdict，节点被终止并撤回 shell ownership，只归档 `INCONCLUSIVE`，没有把部分核对当作 PASS。
3. v2 no-tools reviewer 指出 full-frontend backpressure、trailing owner、sink independence、跨边界 PC identity、sink/PC mutation 与实际 hash-bound evidence 六类缺口；这些均被转成 focused dynamic oracle、compile-success source mutation 或 fail-closed parser gate后才允许发布 DI-1。
4. canonical runner 会先在当前完整 design_id 上重建全部 predecessor records，再保存 `manifest-before-di1` 并原子加入 `frontend_ii1`；发布前后七个 sibling record 逐项相同，避免混用旧 design 或覆盖 sibling 的自证循环。
5. `dispatch-log.md`、最终审查合同与审查结果属于 task-run 审计层，不加入已冻结的 DI-1 proof source/provenance。这样 reviewer 返回后的正常审计写入不会反向改变已经签发的架构摘要。

## 审查者结论

- contract-review-v1：`INCONCLUSIVE`，仅记录调度生命周期，不提供技术 PASS。
- contract-review-v2：`GAP`，其反例已全部机械落地并在最终 canonical run 中关闭。
- final-review-v1 合同 `.github/task-runs/2026-07-21-rv64-v8z-frontend-ii1/subagent-contracts/v8z-frontend-ii1-final-review-v1.json`，SHA-256 `c8aae57c868da65250a8abd59b8c9115fd9de4a87d5f019e303ec81b51dbc58f`。独立 no-tools reviewer 对最终冻结材料给出 `PASS`，逐项签收 DI-1 metric、Bridge/Frontend 组合边界、真实 sink、PC/事务守恒、合法 backpressure、tail conservation、9 项变异、同一设计绑定和 sibling preservation，未留下 unresolved counterexample。
- reviewer 没有独立重算合同/proof-source/provenance/gate-log SHA，没有直接检查原始波形、mutation patch 或 RTL 源码。因此该结论只授权指定 cache-hit/无 redirect/合法 credit 场景的 DI-1 scoped GREEN，不授权 DI-2、overall architecture、PPA 或仓库级全量独立审计。

## AI 工作流收尾（已完成部分）

- `project-status` 与 `modules/npc` 已通过 `update-stored` 写入 DB-backed memory 并重新 snapshot；未直接编辑数据库所有的 live shim。
- bounded startup recall `brief "RV64 DI-1 frontend II=1 PC ledger FIFO sink" --profile npc-dev --focus-scope non-history` 为 `complete`，在 2400-token 上限内从当前 NPC memory 命中新事实，`focus_match_count=1`。
- task-specific `npc-dev` e2e `.github/task-runs/2026-07-21-rv64-di1-frontend-ii1-pc-ledger/` 已 `completed`，5 个展开节点全 PASS，`publication_contract=db-marker-v1` 且 DB 查询确认 `publication_valid=true`。
- 本 task-run raw evidence 已由 `index-evidence --write-index` 登记 42 个资产。
- `audit-db-first` PASS：`candidates=6814/stored=6856/materialized=6604/shims=28`；`audit-markdown-coverage --fail-on-live-evidence` PASS：`live_evidence=0`。
- strict guard PASS：当前工作树要求 `agent-system`、`npc-dev`、`github-index` 三个 profile，分别命中有效 completed evidence；本轮新生成的 `npc-dev` evidence 为上述 DI-1 task-specific run。

## 主要产物

- 设计/验证推导：`rtl-derivation.md`
- 任务合同：`contract.md`
- canonical runner：`run-focused.sh`
- 变异 runner：`run-v8z-mutations.py`
- 最终机器结果：`evidence/final-run/result.json`
- 架构硬门结果：`evidence/final-run/static/architecture-result.json`
- 最终审查：`final-review-v1-result.json`
- 子任务派发审计：`dispatch-log.md`
- raw evidence 索引：`evidence-index.md`

## 剩余风险与下一步

- DI-2 仍为 RED，因此全核 architecture 尚未稳定，不能冻结正式全核 PPA 基线。
- DI-1 证明限定于预热后的 cache-hit、无 redirect、合法 FIFO credit 与指定有限 backpressure；cache miss、redirect 性能和整条双发射宽度连续性不在本结论内。
- no-tools reviewer 的独立性边界由 canonical runner、pre/post manifest、动态变异、单元测试和硬门进行机器补强，但这些仍不表述为形式完备证明。
- 下一轮应为 DI-2 建立 fetch/decode/rename/dispatch/issue/execute/retire 各层独立 uop 计数、peak=2 与 sustained 1.90..2.00 uop/cycle 账本，再按合同—反例—focused—mutation—aggregate—同设计 evidence—独立审查闭合。
