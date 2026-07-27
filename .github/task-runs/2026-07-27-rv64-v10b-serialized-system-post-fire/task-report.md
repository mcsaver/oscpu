# V10B serialized SYSTEM post-fire report

## 状态

`IN_PROGRESS`。

本切片只裁决本地 RV64 双发射 OoO 核中
`OooPendingSystemSequencer` 的八类 canonical kind：

`CSR / ECALL / XRET / WFI / SFENCE_FAMILY / FENCEI / FENCE / IRQ`

从 accepted owner 到 C0 fire、C1 registered state/architectural side effect、
C2 no-repeat 的 transaction 合同。V10A pending architectural-trap clocked
exactly-once 与 V9Y/V9Z memory-owner terminal 作为前置，不在本轮改写。

入口 design-id：
`sha256:13d868334de2a0813f91af318f25434f8e93c581adc67d0b562fcc1f6f8dc951`。

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

权威汇总为
`evidence/v10b-focused-matrix-v2/summary.json` 与 `summary.md`，
`all_pass=true`。该矩阵证明列出的反例被拒绝，不单独外推为系统级闭合。
