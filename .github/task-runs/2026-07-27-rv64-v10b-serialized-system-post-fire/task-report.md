# V10B serialized SYSTEM post-fire report

## 状态

`BOUNDED_COMPLETE`。

本切片只裁决本地 RV64 双发射 OoO 核中
`OooPendingSystemSequencer` 的八类 canonical kind：

`CSR / ECALL / XRET / WFI / SFENCE_FAMILY / FENCEI / FENCE / IRQ`

从 accepted owner 到 C0 fire、C1 registered state/architectural side effect、
C2 no-repeat 的 transaction 合同。V10A pending architectural-trap clocked
exactly-once 与 V9Y/V9Z memory-owner terminal 作为前置，不在本轮改写。

入口 design-id：
`sha256:13d868334de2a0813f91af318f25434f8e93c581adc67d0b562fcc1f6f8dc951`。

## 本轮执行记录

- 主要任务分类：`verification`。
- 辅助分类：
  - `architecture evidence maintenance`：四份 cohort exclusion 的
    current-design rebind；
  - `tooling/workflow`：V3 oracle identity、versioned reviewer contract
    与 dispatch/provenance。
- production RTL 修改：`NONE`。
- 作用范围：八类 canonical pending-system transaction 的 C0/C1/C2
  side effect、holder/stop death、typed redirect、MMU/FPC consumer 与
  CSR exact commit lease。
- 当前分支/HEAD：`ai` /
  `af027d1bce085bace474b748dcd89113145f8772`。
- 工作区：存在本轮证据、验证文件及其它既有 dirty/untracked 文件；
  staged 为空，不把来源不同的修改混入提交。
- 原始失败：
  pre-change `tb_ooo_priv_system` 在切断 FENCE.I MMU input 后仍 PASS，
  证明旧 oracle 对真实 MMU side effect 不敏感；final-review v1 另发现
  cohort identity、真实 bridge 路径、辅助 TB SHA 与局部 marker 四项
  provenance/假绿风险。
- architecture debt：`SERIALIZE-G1`，P1/OPEN。
- 根因假设：production 八类 kind 路径本身满足既有合同，主要缺口是
  testbench 未观察 raw MMU/FPC 与 C1/C2 side effect。
- 竞争假设：SATP/SFENCE/FENCE.I wiring、FENCE full-idle、CSR exact
  lease 或 holder/stop clear 存在真实 production 缺陷。
- 最高信息增益实验：同一 production-module scoreboard 直接计 raw
  pulse，再用 14 个语义最小、compile-success RTL 版本逐项切断合同。
- 运行预算：17 个 focused case、113 个 module test；production RTL
  未变化时复用同 design-id 的 functional/architecture canonical run。
- promotion：`false`；本轮为 intermediate checkpoint，不具备
  architecture-stable/PPA 晋级资格。

## 图任务

| node_id | owner_agent | depends_on | inputs | outputs | success_criteria | fallback |
| --- | --- | --- | --- | --- | --- | --- |
| V10B-R0 | root | V10A | production RTL/spec/current evidence | 八类逐拍调用链和 side-effect census | 区分 immediate drain 与 CSR post-dispatch lease | 扩大只读路径 |
| V10B-R1 | independent reviewer | V10B-R0 | versioned local RTL contract | counterexample-first pre-review | 找出重复、遗漏、priority 或 coverage gap | 保留 GAP |
| V10B-V0 | root | V10B-R1 | production modules + clocked TB | current RED/GREEN matrix | 八类逐项观察 request/redirect/MMU/CSR/owner/stop | 缩小到单 kind |
| V10B-I0 | root | V10B-V0 | frozen contract | minimal RTL/assertion/TB change | 不增加 terminal 去重、不削弱断言 | 若 RTL 已满足则只补验证 |
| V10B-V1 | root | V10B-I0 | current source | mutation + layered evidence | compile-success variants 动态拒绝并绑定 design-id | 局部 GAP |
| V10B-R2 | independent reviewer | V10B-V1 | frozen evidence | final review | 优先寻找假绿与越级结论 | 不关闭 SERIALIZE-G1 |
| V10B-C0 | root | V10B-R2 | report/evidence/reviewer | memory/DB/e2e/guard | 可发现、可重放、可审计 | 明示系统层豁免 |

## 初始 transaction 分类

| kind | C0 authority | architectural/observable action | expected owner lifetime |
| --- | --- | --- | --- |
| CSR | `system_csr_dispatch_fire_w` | ROB lease；exact PID/PC commit 才写 CSR并 redirect | fire 后保持至 exact commit |
| ECALL | `drain_complete_w` | selected trap-ex record + trap redirect | C1 clear |
| XRET | `drain_complete_w` | selected xRET state transition + redirect | C1 clear |
| WFI | `drain_complete_w` | cohort 定义的 immediate-resume serial redirect | C1 clear |
| SFENCE_FAMILY | `pending_system_sfence_commit_w` | typed SFENCE redirect + MMU flush | C1 clear |
| FENCEI | `pending_system_fencei_commit_w` | typed FENCEI redirect + MMU/I-side flush | C1 clear |
| FENCE | `drain_complete_w && mem_idle_i` | serial redirect；无伪 CSR/trap/MMU action | C1 clear |
| IRQ | `drain_complete_w` | selected irq trap record + trap redirect | C1 clear |

上表是待审合同，不是已证明结论。

## 当前边界

- simulation exit/semihost `pending_exit` 是相邻 transaction，不与 ECALL
  architectural trap 混为一类；在八类闭合后单独裁决。
- `SERIALIZE-G1=OPEN`，Linux terminal、architecture-stable 与正式 PPA
  保持 `GAP/UNQUALIFIED`。

## 独立预审

`pre-reviewer-v1` 只读核验后的总体裁决为 `GAP`：

- canonical kind、CSR exact ProducerId/PC lease、非 CSR holder/stop clear
  的静态拓扑未发现已确认 production RTL bug。
- 既有 `tb_ooo_priv_system` 未直接观察 `mmu_flush_o`，因此切断
  FENCE.I MMU action 后 typed redirect marker 仍可能为绿。
- WFI/FENCE 的零 CSR/trap/MMU action、四种 SFENCE-family 编码和若干
  C1/C2 no-repeat 也缺少同一 production-glue scoreboard。

完整裁决见 `reviewer-report-v1.md`；合同 SHA-256 为
`fb88f47b1d59abf01ea637db7f3a57fee6e76fe58451946025ad40fdbcb84a5e`。

## Pre-change 验证缺口证据

`run-prechange-mmu-gap-probe.py` 在修改 TB 前保存了不可覆盖证据：

- baseline `tb_ooo_priv_system`：compile success，`[RESULT] PASS`。
- 仅将 `OooMemoryAccess.pending_system_fencei_commit_i` 接为 `1'b0`
  的 production-module 版本：compile success，仍 `[RESULT] PASS`。
- pre-change TB SHA-256：
  `dac1001f56de1eec9f5fee4ea23987abc626094a81e3c6ccd11d08fdf760cc56`。
- 结果：
  `evidence/prechange-mmu-observation-gap/report.json`，
  `gap_proven=true`。

这证明修订前绿灯不能支持 FENCE.I MMU action 结论。

## Testbench 修订

生产 RTL 未改。`tb_ooo_priv_system.sv` 新增 raw-pulse scoreboard：

- `C0`：逐个计数 pending CSR exact commit 或 non-CSR E6 terminal，
  核对 exact-one kind、typed reason/PC/backend action 和 selected
  `CsrFile` request。
- `C1`：直接核对 `pending_system_q=0 && stop_pending_q=0`。
- `C2`：直接核对同一 kind/PC/inst 不重复 terminal；不使用 seen-bit
  去重。
- 直接连接并逐拍核对注册 `mmu_flush_o` 与前一拍
  SATP/SFENCE/FENCEI raw source。
- WFI/FENCE 明确要求零 CSR/trap/MMU source。
- 程序新增 `SFENCE.W.INVAL` 与 `SFENCE.INVAL.IR`，与
  SFENCE.VMA/SINVAL.VMA 一起形成四编码 mask。

`tb_ooo_fetch_axi_bridge.sv` 新增 cache-consumer directed case：

- 先把旧 instruction packet 填入 production FPC 并确认 warm hit；
- 单拍 `mmu_flush_i` 后同 PC 不得返回 stale response；
- 必须重新发 AXI read 并返回不同的新 instruction packet。

当前 direct evidence：

- `evidence/current-assert/logs/tb_ooo_priv_system.log`：
  `[RESULT] PASS`；mode 0 计数
  `CSR=5/ECALL=1/xRET=1/WFI=1/SFENCE=4/FENCEI=1`，
  MMU action `0+4+1=5`。
- mode 2：SATP/SFENCE source `1+1`，注册 MMU action `2`。
- mode 9：IRQ raw request、typed TRAP、C1 clear、C2 no-repeat 均为 1。
- mode 7：ordinary FENCE full-memory wait、SERIAL redirect、
  ctrl-commit、C1 clear、C2 no-repeat 均为 1，MMU action 为 0。
- `evidence/fencei-cache-consumer/logs/tb_ooo_fetch_axi_bridge.log`：
  `[V10B-FENCEI-STALE-INSTRUCTION] ... PASS` 与 `[RESULT] PASS`。

## Mutation 迭代

V1 有 13 个 compile-success RTL 版本，其中 12 个被动态拒绝。唯一幸存的
`remove-fence-mem-idle` 暴露的是测试相位重叠：

- 全核 FENCE 程序中的 active store 同时被
  `mem_owner_terminalized_i` 拒绝，不能单独观察额外 full-idle 项。
- production `OooPendingDrainResolveGate` 定向 TB 在
  collector-pending-only 相位直接报
  `fence waits for MIQ bridge reservation idle`，拒绝同一版本。

V2 因此保留全核 store-ordering 程序，并把该差分版本绑定到
`tb_ooo_pending_drain_resolve_gate`；同时新增切断 FPC
`clear_i(mmu_flush_i)` 的 cache-consumer 版本。最终结果：

- 3 个 current-design baseline（assert/release/CSR unit）全部 PASS；
- 14 个 RTL version 均 compile success；
- 14/14 均被对应仿真动态拒绝，包括 SATP/SFENCE/FENCE.I MMU action、
  typed reason、FENCE full-idle、owner/stop clear、CSR ProducerId/PC、
  WFI control commit、零伪 MMU action、SFENCE.INVAL.IR decode 与
  FENCE.I→FPC clear。

V2 暴露的证据身份和局部 marker 问题已由 V3 修正。当前权威汇总为
`evidence/v10b-focused-matrix-v3/summary.json` 与 `summary.md`：

- current design-id：
  `sha256:13d868334de2a0813f91af318f25434f8e93c581adc67d0b562fcc1f6f8dc951`；
- 3/3 baseline PASS；
- 14/14 compile-success RTL version 被动态拒绝；
- 四个 testbench path/SHA 与每 case oracle identity 均已绑定；
- typed-reason 版本的局部 marker 与最终 `[RESULT]` 均为 FAIL。

该矩阵证明列出的反例被拒绝，不单独外推为系统级闭合。

## 分层同源证据

- `module-current-v3/summary.txt`：113/113 PASS，113 份日志均携带
  current design-id。
- `functional-current/functional-aggregate-result.json`：PASS，
  module 113/113、official 177/177、AM 59/59、DiffTest mismatch 0，
  CoreMark/Dhrystone marker 通过。
- `architecture/final-architecture-hard-gates.json`：DI-1..DI-5 与
  OOO-1..OOO-4 共 9/9 GREEN。
- 三层结果均绑定
  `sha256:13d868334de2a0813f91af318f25434f8e93c581adc67d0b562fcc1f6f8dc951`。
- `layered-current.status` 为 PASS。由于 V3 最后一次只修正 testbench
  marker/provenance、production RTL 未变化，复跑 113/113 module
  用于确认 oracle currentness；未机械重复相同 official/AM/benchmark。

## 实现者结论

- 实际结果支持“production 八类 kind 路径满足既有 bounded 合同，
  原主要问题是 verification observation gap”。
- `CSR / ECALL / XRET / WFI / SFENCE_FAMILY / FENCEI / FENCE / IRQ`
  均有 C0 raw authority、C1 owner/stop clear 或 architectural side
  effect、C2 no-repeat 的直接观测；CSR 另有错误 PID/PC 拒绝与 exact
  commit。
- verification 修改包括 raw scoreboard、四编码 SFENCE family、
  FENCE.I stale-instruction consumer、V3 oracle identity 与 marker
  fail-closed。
- production RTL、assertion 强度和 terminal-event 处理均未修改；
  没有添加去重或静默丢弃逻辑。
- pre-change 敏感性：切断 FENCE.I MMU input 的可编译版本在旧 TB 上
  仍 PASS；新 V3 中对应 MMU/FPC 断线版本均被目标 oracle 拒绝。
- 原始 Linux/system reproducer：`NOT_RUN`。本轮最低层验证已闭合，
  但系统级 terminal 是独立 P1 主线，不能由本切片替代。
- synthesis/STA/power：`NOT_RUN`；evidence class 为 RTL
  verification，promotion_eligible=false。

## 独立审查者结论

final-reviewer-v2 标准化裁决为：

`APPROVED_FOR_CURRENT_SCOPE`

审查者确认 v1 四项反证均已关闭，八类 bounded transaction 可 PASS。
最强被拒绝反例是断开
`OooFetchPacketCache.clear_i(mmu_flush_i)`：版本编译成功，但出现
stale response、无 AXI refetch 与旧 instruction packet，最终 FAIL。
完整报告见 `final-reviewer-report-v2.md`。

审查者保留以下边界：

- FENCE.I 是 production pulse、顶层静态连线和 bridge 动态 consumer
  的组合证明，不是 full-core self-modifying/Linux 证明；
- 没有形式穷举；
- `fdg-arch-trap-current.json` 仍是旧 design-id/111-module evidence；
- `SERIALIZE-G1`、simulation exit、Linux terminal、architecture-stable
  与 PPA 均未关闭。

## 当前声明等级与下一动作

- 本切片声明：八类 canonical SYSTEM post-fire
  `APPROVED_FOR_CURRENT_SCOPE`。
- 全核声明：`GAP`。
- PPA：`UNQUALIFIED`，promotion=false。
- 下一项最高信息增益动作：另立 architecture-evidence maintenance
  节点，重放 `make -C npc/rv64 check-fdg-arch-trap`，证明
  `fdg-arch-trap-current.json` 与 113-module current design 一致；
  随后重新运行 debt-ledger currentness updater。若 current P1 仍在，
  继续 `SERIALIZE-G1` simulation-exit/terminal 主线；只有不存在
  P0/P1 时才进入 historical-defect-backfill 默认队列。

## 工作流闭环

- task-run JSON：`round-state.json` 已记录分类、Git/设计身份、原始失败、
  假设/竞争假设、判别实验、运行预算、gate、reviewer verdict 与
  promotion=false。
- evidence index：已用 `github_index_db.py index-evidence` 登记 V10B
  raw evidence；最终文件新增后再次刷新。
- retained memory：`project-status.md` 与 `modules/npc.md` 已通过
  `update-stored` 写回 DB。
- task-specific e2e：
  `.github/task-runs/2026-07-27-serialized-system-revtag-v10b/`
  为 `npc-dev` completed，5/5 PASS，含 canonical recall、resolve、
  manifest、evidence index、complete marker 与 publication。
- strict guard：以 `guard-paths.txt` 限定本轮 15 个 source/contract/
  report 路径，要求一个 `npc-dev` profile；绑定上述 completed run 后
  PASS，exit 0。原始输出见 `strict-guard.log`。
- Git：staged 仍为空。当前工作区含来源混合的大量 tracked/untracked
  证据和生成物；尚未证明可安全组成原子提交，因此本切片不 commit，
  不执行 push/amend/reset/restore/clean/stash。
