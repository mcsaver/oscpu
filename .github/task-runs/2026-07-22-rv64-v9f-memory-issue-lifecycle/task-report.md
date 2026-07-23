# RV64 V9F 内存发射生命周期当前设计闭环报告

## 状态

- `state`: 当前设计 architecture evidence slice 已闭合并完成 DB/e2e/strict-guard 收尾
- `design_id`: `sha256:6236b176da0c10bccac9c2feb405a0d65ba586d826616f0beaeee0cbbfe2f3dc`
- `classification`: architecture closure；`PPA=UNQUALIFIED`；`promotion_eligible=false`
- `debts`: `MEM-ISSUE-G1` P0、`MIQ-FLUSH-G1` P1
- `production_rtl`: 本切片没有修改生产 `.v`；完整 RTL design-id 保持不变

## 根因与真实 owner/dataflow

生产 RTL 已包含两项预期机制，受阻点是历史证据没有绑定当前设计。旧 MEM
证据假设 lane1 在 lane0 本地异常同拍直接透传到外部请求；当前单内存端口
拓扑实际先把一对内存事务原子捕获到两个 reservation terminal，再按 edge-old
terminal0 优先级排空。因此当前证明必须覆盖“捕获”和“请求 fire”两个不同阶段，
并分别绑定 terminal consume、request mux owner 与 MIQ owner birth。

MIQ 当前实现仍是 `filter_DRAIN(Q_old - fired_head)`。同拍全局流水线 flush
必须先减去 exact-owner response fire 已消费的 DRAIN head，再按 FIFO 顺序保留
未消费 DRAIN；仅有 valid 而没有 `pop_fire` 的 head 也必须保留。DRAIN 在这里是
transport-irrevocable/nokill 的已接受物理写事务，不被误述为已经架构退休。

## 实现者交付

生产 RTL 只读。本轮只增加测试可观测性、当前设计静态绑定、证据构建器和
compile-success RTL 验证变异：

- `tb_ooo_int_backend.sv` 增加单端口两 terminal 捕获、terminal0 本地异常、
  terminal1 后续自身 request fire、竞争 owner、两拍 ready backpressure、
  15 字段身份和发射后 3 拍安静窗口；
- `tb_ooo_mem_inflight_queue.sv` 增加 fired DRAIN、未消费 DRAIN、valid/no-pop
  DRAIN head、绕回混合集合身份和 FIFO 顺序；
- 证据构建器现场复算 source/provenance、focused marker、109 模块集合和
  11 个变异；arch-stable debt validator 只接受同一 design-id 的精确结果；
- `make -C npc/rv64 check-memory-issue-lifecycle` 成为永久入口。

接口合同见 `contract.md`，RTL 推导见 `rtl-derivation.md`。

## 当前设计证据

Canonical 命令：`make -C npc/rv64 check-memory-issue-lifecycle`。

- focused：2/2 PASS；
- 内存 pair 捕获：2 个 terminal；terminal0 本地完成 1，terminal1 保持 1；
- terminal1：自身 request fire/consume/MIQ birth 各 1，15/15 身份字段一致；
- 竞争 owner：terminal0 fire 时 terminal1 保持、consume=0、birth=0，之后
  terminal1 自身 release fire=1；
- backpressure：连续 2 拍 valid 保持，blocked 周期 request/consume/birth 均 0；
- bounded exactly-once：成功发射后的 `t+1..t+3` 无重复 request fire 或 MIQ birth；
- MIQ flush：已消费 DRAIN 移除、未消费 DRAIN 保留、valid/no-pop DRAIN head
  保留、survivor 身份和绕回 FIFO 顺序均通过；
- compile-success RTL 验证变异：`MEM-ISSUE-G1 8/8`、`MIQ-FLUSH-G1 3/3`，
  合计 11/11 全部被指定动态 oracle 检出；
- 动态派生模块 aggregate：109/109；variant 前后生产源码 byte-identical。

证据结果 SHA-256：

- result：`a7d87c174882a1acdf7fefd9df3199cefbf2b758d359418595c11fd6d3d334c8`；
- raw log：`71131cf79e86c99b1d82d982bc08eda5f5ecbe9cb8853a582c69ded9ac218983`；
- ROADMAP：`e0c8738165948161db36d3711bcb2b1dcbdc5123770c83c52798d904760a6543`；
- architecture debt ledger：`7138a51464007d01453b5807d3adc63c1dc07b6f753db328f8541cc331140aa4`。

账本 revision 为 `v9f-20260722`；两项 debt 均为 `CLOSED`、
`current_design_bound=true`，并绑定同一 design-id、result 和 raw log。

## 架构来源绑定与下游 gate

新增 Makefile/TB 证据入口使九条旧 architecture record 的来源哈希按设计
fail closed。V9F rebind 工具只允许三个实际漂移路径：

- `npc/rv64/Makefile`；
- `npc/rv64/testbench/tests/tb_ooo_int_backend.sv`；
- `npc/rv64/testbench/tests/tb_ooo_mem_inflight_queue.sv`。

工具逐字节重建三份旧文件、检查 9 个 record 的 13 个 provenance/
source-manifest section、确认非来源语义投影不变、重放当前 109/109 模块集合，
再原子发布。结果为
`paths=3 records=9 sections=13 pre=RED post=GREEN projection=UNCHANGED PASS`。
最终 `architecture-current.json` SHA-256 为
`f5acbfd9aea4c43bd229671268ffada9ec6ee621b5f34b9ae1c99f279319948a`，
九项 directed architecture hard gate 为 9/9 GREEN。

相关当前设计债务入口也已重放：

- INSTRET：109/109、3/3 变异 PASS；
- FDG：109/109、6/6 变异、1/1 observation probe PASS；
- XRET：109/109、8/8 变异、2/2 observation probe PASS。

## Arch-stable 与 PPA 边界

最终 arch-stable 审计的 77 个单元测试全部通过，但审计结果仍诚实保持
`GAP`、41 个 blocker、`PPA=UNQUALIFIED`、`promotion_eligible=false`；结果
SHA-256 为
`0f5330758f3175996e7df0b9ab361b01b4fced71aece9c3621d1c7970d609f32`。
剩余 blocker 包括其它架构债务、full-core holder/lifecycle census、当前同设计
functional aggregate、规范 cohort inventory 和完整 freeze inputs。本轮没有
声称 area、timing、power、200 MHz 或 Pareto 晋级。

## 审查者结论

四轮 proof-model 审查把 backpressure、bounded exactly-once、竞争 owner、
valid/no-pop DRAIN 和 grant/fire/pop 可达性逐步补入证据。最终独立合同
`a530367efc4e1fade81bb8134c537695e36006d3901a2f4b8c337a0be8d4d221`
通过 canonical `create → validate → render` 并原样派发给 no-tools reviewer。

终审给出“限定性 PASS”：没有发现能推翻两项 debt 当前闭环的合法输入反例；
两项 debt 可在当前 design-id、单内存端口配置和给定证据边界内保持 CLOSED。
审查者保留以下边界：exact-owner 上游合同没有在冻结摘要内独立证明；竞争
场景只抽查 5 个身份字段；两拍 backpressure 和 3 拍安静窗口是有界观测；
11 个变异不是形式完备集。完整过程见 `review-summary.md` 与 `dispatch-log.md`。

## 明确不外推

- 不覆盖双内存端口全部交错；
- 不覆盖任意长度 backpressure 或 `t+4` 之后的无限时域 exactly-once；
- 不替代完整程序级 DiffTest/Linux 或 full-core functional census；
- 不证明全部架构 debt 清零、full-core arch-stable 或正式 PPA；
- design-id 变化后必须重跑并重新绑定。

## AI 工作流与数据库收尾

本轮所有子 agent 均使用本地 RV64 微架构专业合同，JSON 路径和自身 SHA
逐轮绑定；no-tools 节点没有 shell ownership、文件写入或外部依赖。早期 GAP
没有被覆盖，而是转成 testbench 场景、静态审计和变异后再复核。

- project/module 稳定事实已通过 `github_index_db.py update-stored` 发布；
- bounded brief 使用 `rv64 memory issue lifecycle`、profile `npc-dev`、
  `focus_scope=non-history`，得到 `recall_status=complete`，独立 focus 来自
  当前 DB-owned NPC memory，不由旧 task-run 自证；
- 128 个原始证据资产已由 `index-evidence --write-index` 建立尺寸、SHA-256、
  marker 和摘要索引，完整日志不进入长期上下文；
- task-specific `npc-dev` e2e 在
  `.github/task-runs/2026-07-22-rv64-memory-issue-lifecycle-revtag-v9f/`
  完成，5 个节点全 PASS 并完成 hash-bound publication；
- 收尾定向审计发现两个真实机器接线缺陷：`state-audit --run-id` 把裸
  `run_id` 当作 report root，及 `index-evidence` 未把 trace 合同要求的顶层
  `run-manifest.json` 纳入 DB；修复分别使用
  `.github/task-runs/<run_id>` 读取报告，并只额外允许规范 task-run 顶层唯一
  manifest；
- manifest/evidence-index 的 count、bytes、kind 和 list 继续只聚合普通
  `/evidence/` 资产；runtime validator 要求普通资产行数精确等于 manifest
  `asset_count`、canonical manifest 恰一行且 `kind=json`、没有其它顶层指针、
  DB 总行数精确为 ordinary+1。`evidence_assets.path` 为主键，因此重复路径
  不能用计数掩盖缺失的 distinct path；
- `github-index` 行为 probe 覆盖双次索引幂等、manifest SHA/size 更新、删除
  清理、peer-run 隔离及 `render manifest → index → validate`；`agent-system`
  行为 probe 直接验证 completed 七态 report 的 `run_id → run_root` 选择；
- 第一次真实 `github-index` forward-test 暴露测试夹具缺少生产 DB policy 且
  未归档夹具 Markdown；第二次节点 1/1 PASS，但 task slug 没有独立
  non-history focus，overall 正确保持 blocked。两份失败包原样保留，不计作
  完成证据；
- 最终 `.github/task-runs/2026-07-22-agent-system-observability-run-manifest-revtag-v9f/`
  的 `github-index` 1/1 completed，普通/DB 资产为 2/3；
  `.github/task-runs/2026-07-22-agent-system-state-traceability-observability-revtag-v9f/`
  的 `agent-system` 10/10 completed，普通/DB 资产为 12/13。两者
  artifact/trace/state targeted audit 均 PASS；关联 V9F `npc-dev` run 经
  DB-only reindex 后三项审计也 PASS，且未改写其 published evidence-index；
- 早期无正式合同的 AI delta reviewer 只记为 candidate review。最终正式
  no-tools 合同
  `subagent-contracts/v9f-ai-e2e-audit-final-review.json`，SHA-256
  `61220627819dec28e25d1d05ee24a1ed36cab46fff627f4b30016c3e6233d05c`，
  零命令、零写路径、无外部访问；reviewer 判 `PASS`、无 blocker，完整结论
  见 `ai-workflow-review.md`；
- 精确声明仅适用于 manifest 已写定、随后完成重新索引并验证的规范 final-state
  run。历史、blocked/non-final run 不自动迁移；最后一次索引后若 manifest
  再变化必须重索引；本轮没有证明并发写入或崩溃中间态原子性，也不接受
  一般性的 `DB count >= manifest count` 作为一致性证明；
- 第一次最终 strict guard 因 memory/arch-stable 产物晚于旧 profile evidence 而
  正确报告 `agent-system`/`npc-dev` freshness FAIL；没有复用旧 PASS。随后
  `.github/task-runs/2026-07-22-agent-system-manifest-state-traceback-revtag-v9f/`
  以 10/10 completed、普通/DB=12/13 重获三项 targeted audit PASS，
  `.github/task-runs/2026-07-22-rv64-memory-issue-lifecycle-revtag-v9f-guard-final/`
  以 5/5 completed、普通/DB=6/7 重获三项 targeted audit PASS；
- strict guard 最终检查 `changed_paths=2127`，要求并接受 `agent-system`、
  `npc-dev`、`github-index` 三个 profile；对应完成证据分别为上述最新两个
  freshness run 与
  `.github/task-runs/2026-07-22-agent-system-observability-run-manifest-revtag-v9f/`；
- 长期 `/goal` 继续 active；本报告只关闭 V9F 当前设计证据子切片。
