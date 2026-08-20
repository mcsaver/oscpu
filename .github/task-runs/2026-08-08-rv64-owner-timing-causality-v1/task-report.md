# RV64 f72e serialized drain owner-timing slice

## Classification and current authority

- task class: `longrun`；archive: `durable`。
- live design-id at start: `sha256:f72e1fb439364378649b7b03db5cb7a52cf42367022cb0c6e07348a0e3659a42`。
- canonical selector at start: `NO_ELIGIBLE / HOLD`，原因是 current owner-timing/PPA 已完成，
  performance floor 未达、timing hard gate FAIL，且
  `serialized-mem-terminal-readiness-register-v1` 缺少跨周期 owner lifetime 证明。
- current mapped reference: WNS `-13.38258934 ns`、TNS `-315554.09375 ns`、
  logic-area proxy `2181706.52`；Power 与 macro-inclusive total area 均未资格化。

长期 Goal 保持 active。本轮只能形成一个 candidate-only timing experiment；不得宣称 PPA、5 ns、
system recertification 或 promotion 完成。

## Root-cause / source chain

两轮 exact top40 的 40/40 路径共同经过
`OooIntBackend.mem_owner_terminalized_o → OooPendingDrainResolveGate.drain_complete_o →`
`OooCsrTrapRequestMux/OooTrapExitEventMux → redirect/fetch-PC`。组合 scalar 本身对 holder、accepted
transfer、collector pending、tracker live 与 same-edge birth 的归约正确；问题是它把 memory/LSQ/PMP
大锥直接接到 serialized control 与 fetch 端点。

独立 reviewer 拒绝“无 owner 身份的一 bit readiness”。主线扩展读取后确认：live serialized owner
通过 `OooFrontendRunGate` 令 `can_run=0`，pending arbiter不能 birth 新 owner；current raw
`backend_drained_o` 与 FENCE `mem_idle_i` 可以在 permit 消费拍继续作为安全 backstop。因此候选收窄为
带 system/arch-trap/exit one-hot owner identity 的 cancellable permit，而不是缓存完整 memory state。

## Interface contract freeze

规范真源：`npc/rv64/design/specs/ooo-serialized-mem-terminal-permit.md`。

- handshake/stall：permit 是一次性 Moore completion资格，不是 ready/valid payload；不产生 backpressure。
- flush/redirect：reset/global-local flush、ROB-head trap、older recovery、head0 CSR commit clear-dominant；
  direct frontend fire 与 live serialized owner 必须互斥。
- exception order：ROB-head trap 继续压住 pending arch/system/exit；C0 fire 后 C1 清 owner、stop、permit。
- memory order：不释放 collector/tracker token、不清 committed store、不 kill AXI；FENCE 继续读取 current
  `mem_idle_i`。
- speculation/single source：permit只保存当前 registered owner one-hot用于防 stale reuse，不重新分类指令。
- same-cycle priority：reset/flush > architectural cancel > consume > owner mismatch/stop drop > arm > hold。

## RTL derivation summary

### Stage 1 — requirement

增加 1-bit valid + 3-bit owner permit，把 `mem_owner_terminalized_i` 只送入寄存器 D；permit Q 必须与
当前 exact-one serialized owner匹配，且 drain消费拍仍重查 raw ROB/IQ/SQ drain 与 FENCE current idle。
目标是移除 mapped top40 的 memory-owner terminal组合段，不改变任何架构 transaction。

### Stage 2a — protocol

IDLE 在 `stop && backend_drained_q && mem_terminalized && owner_exact_one` 的沿上 arm；ARMED 在同 owner、
无 cancel/consume 时保持。consumer 不反压；consume exact-once clear。owner mismatch使 `ready` 当拍失效。

### Stage 2b — FSM

`IDLE -> ARMED(owner)`；`ARMED -> IDLE` 的条件为 reset/cancel/consume/stop drop/owner mismatch；
其余保持。不存在第三状态或非法恢复路径。

### Stage 2c — invariants

- valid owner one-hot；ready 必须匹配 current owner与 stop。
- cancel/consume/mismatch 后下一拍不得继续 ready。
- FENCE 必须同时满足 current `mem_idle`。
- 合法域禁止 `permit_ready && raw_backend_drained && !current_mem_terminalized`；若出现说明 memory holder
  在 drain backstop之外复活，必须 fail loud并回退候选。

### Stage 2d/2e — datapath and topology

memory exact scalar → permit D；permit Q → 3-bit equality/exact-one → drain serialized qualifier。
raw backend drain、FENCE mem idle和priority mux保持原组合位置。状态只有 valid/owner四个 FF；无 function、
payload mux、共享资源或 ready环。预期新关键路径为 permit Q→owner compare→drain/redirect/fetch；
fresh STA是唯一物理裁决。

## Verification obligations

- focused positive + A/B owner handoff + arm/cancel + no-repeat TB；
- compile-success negative for owner compare、cancel priority、FENCE current-idle；
- style/lint/contract与受影响 L0/L1；
- 保留候选后才运行相同 design/config/workload 的 CPI与两轮 fresh mapped STA；
- 任一功能、owner lifecycle、timing hard gate或证据 identity失败均不进入 Pareto。

## Current result

`IN_PROGRESS / ENGINEERING_CANDIDATE_ONLY`：owner-lifetime verifier 已给出
`TRACEABLE_SERIALIZED_OWNER_PERMIT_CANDIDATE_DEFINED`，selector policy/catalog 通过
versioned overlay 把当前有界动作更新为 `experiment.serialized-owner-terminal-permit / RTL_EXPERIMENT`；
旧 ownerless one-bit 候选仍明确拒绝，promotion 与 PPA 资格均为 false。

production RTL 已加入 `OooSerializedMemTerminalPermit`（valid + 3-bit exact-one owner），并把
`OooPendingDrainResolveGate.serialized_mem_terminal_ready_i` 限定到 non-CSR system、architectural trap
与 simulation exit。CSR raw eligibility 仍消费 current `mem_owner_terminalized_i`；raw
`backend_drained_o` 与普通 FENCE current `mem_idle_i` 均未移除。候选 production source set 为
147 个文件，design-id `sha256:93c8edcf798daecb4c0a12e37f86b11da4c2b47d70fedb9f96e3e51c4e9d2551`。

定向证据已 PASS：permit、drain gate、arch-trap terminal、serialized owner exactly-once、core-top glue；
四个 compile-success mutation 分别删除 owner match、cancel priority、FENCE current-idle 与 raw backend
drain，均被预期观测抓住且 production hash 不变。`check-rtl-style`、Verilator lint 与直接
`eval/check-contract.sh` PASS。聚合 `make check-contract` 当前仅因候选改变 design-id、而冻结的
producer-holder census/source closure 仍绑定 f72e 而 fail-closed；这不是行为 PASS，后续若保留候选必须
按新 design-id 重绑并再认证。

未完成门禁：两轮 fresh mapped synth/STA、候选 selector/research-state 更新、architecture/system
recertification、candidate review 与 Pareto/promotion 判定。现阶段不得宣称 5 ns、PPA、system 或
canonical-current 完成。

## Candidate CPI checkpoint

current 93c8 candidate 使用与 f72e frozen reference 完全相同的 CoreMark10/Dhrystone10000 image、
committed-PC ROI 与 stats configuration，各运行三次。CoreMark 为 `5262868 cycles / 3183617 retired`
（CPI `1.653109654836`），Dhrystone 为 `9751462 / 4250000`（CPI `2.294461647059`）；两项均在候选
三次之间位精确，且与 reference 的 region/counter payload 位精确，cycles/CPI delta 均为 0。
owner-timing 每项 84 行签名位精确、invalid-events=0，production manifest before/after 相同，runtime
清理完成，receipt 可重建。证据：
`.github/task-runs/2026-08-08-rv64-v16a-owner-permit-cpi-93c8-a1/evidence/owner-timing-current-candidate-ab/result.json`。

该 checkpoint 仅把 CPI hard floor 判为 PASS，从而允许 fresh mapped synth/STA；它没有 current
ARCH_STABLE、PPA 或 promotion 权限。

## Fresh mapped attempt A1 and trace-checker correction

首次 93c8 mapped A1 的 Yosys、synth checks、OpenSTA exact-5ns 与 summary parser 均成功，但原
task-run 保持 `FAIL rc=1 stage=evidence-complete`：旧 traceability shell regex 要求所有 endpoint
cell instance 名以 `_D` 结尾。A1 的 40/40 endpoint 实际均为 public `u_core_*_DFF*` capture flop，
且每条 OpenSTA header 都明确标为 `rising edge-triggered flip-flop clocked by core_clock`；其中 39 个
instance 由 Q-net 命名、1 个由 CK-net 命名，故旧 regex 仅计为 1/40。没有 opaque start/end，
并非 netlist traceability 丢失。

`traceable_path_inventory.py` 现精确要求 40 start + 40 endpoint、80 个 core-clock register 描述、
全部 public `u_core_*_DFF*` 且 zero opaque；D/Q/Q_N/CK 合法命名正向与 opaque/missing-description/
count-drift 负向单测 4/4 PASS。它对 A1 与 frozen f72e top40 replay 均 PASS。原 A1 status、旧
`traceability.txt` 与 FAIL 结果不改写；后续 fresh A1b/A2 使用修正后 checker 与相同综合/STA 配置。

## 93c8 mapped A1b、A2 与独立裁决

A1b 在修正后的 traceability checker 下完成且 task status 为 PASS；这只表示工具、manifest、Top40、
summary、hash 与 cleanup 证据闭合。exact-5ns timing 仍为 hard-gate FAIL：WNS
`-11.550187111 ns`、TNS `-285529.625 ns`、Top40 `40/40` 违例。相对 f72e 的 WNS 改善
`+1.832402229 ns`、TNS 改善 `+30024.46875 ns`；logic-area proxy 增加 `75.32`，known standard
cells 增加 29，sequential area 增加 `24.64`。固定 toggle vectorless power `0.136 W` 与 unknown
macro-inclusive area 均不具正式 qualification。

路径迁移成立但只限原目标族：f72e 的 40/40
`terminal→drain_complete→fetch/redirect` 端点在 93c8 Top40 中消失；93c8 新端点为 35 条 terminal
collector capture、4 条 serialized permit register、1 条既有 CSR dispatch permit。不得扩写为
terminal logic 全部离开 Top40。

A2 由用户取消，status 为 `FAIL rc=143 stage=signal-TERM evidence_complete=0`；它既不是完整 PPA
测量，也不是候选失败，禁止机械重跑。独立 reviewer 合同
`b651f6bc7b7d4e881666cae370e2e24fe9feb6390795d08269499ca22c996c91` 裁决
`retain_for_reconciliation`，完整边界记录在
`subagent-contracts/v16a-owner-permit-independent-review-v1.result.md`。

## V16B held-permit cancel-cycle closure

Reviewer 构造出 93c8 未覆盖反例：permit 已持有、owner match、stop/raw-drain/control-ready 均为 1，
同时出现高优先级 cancel。旧 `ready_o` 不读 cancel，可能在 clear 沿前暴露 `drain_complete`。直接把
完整 holder clear 反喂 ready 不可行，因为完整 clear 含 `drain_complete` 自身，会形成组合环。

V16B 将两条因果边界拆开：

- `cancel_i = core_local_flush_w || system_csr_admission_clear_w`，只接已经审计为 feedback-free 的
  ROB-head trap、older recovery、jump terminal 与 CSR exact commit 单向见证；
- 完整 pending holder clear 继续负责 sequencer 沿上状态死亡，可包含正常 consume 派生的
  `drain_complete`，但不再进入 permit ready 组合边界；
- `ready_o` 增加 `!cancel_i`，从而 held permit 与高优先级 cancel 同周期立即 `ready=0/drain=0`；
  direct frontend flush 仍由 live-owner mutex 与各真实消费 mux 的高优先级门控负责，避免重建
  ready/flush 组合环。

新增而非重复的验证一次通过：

- focused：`[V16B-SERIALIZED-PERMIT-CANCEL-CYCLE-BLOCK] arm-held-cancel PASS`；
- integration：held arch permit 与 ROB-head trap 碰撞得到
  `mem-selected=1 arch-request=0 ready=0 drain=0 C1-clear=1 C2-repeat=0`；
- `OOO_ASSERT_OFF` compile-success mutation 从 4 项扩为 5 项，新增删除 cancel-cycle ready gate 的
  负向变体；`MUTATION_COUNT=5 COMPILE_SUCCESS_COUNT=5 DETECTED_COUNT=5`；
- production Verilator lint PASS。

证据根：`.github/task-runs/2026-08-08-rv64-owner-timing-causality-v1/evidence/v16b-cancel-cycle`。
当前 production design-id 已变为
`sha256:d3f3e7ffd6a3ca9f5e4249b945f74b935cd45182f97e0e6dd3e6377eca4f52af`；93c8 的 CPI/PPA
只能作为 predecessor 经验，不能冒充 d3f3 current receipt。

## Grounded Experience Loop 与当前 selector

93c8 的“目标路径族移出、CPI 零回退、5ns 仍失败、cancel-cycle 推理缺口”已写成经过 schema 校验的
`ExperienceRecord`；held-cancel 反例、最低成本区分实验、V16B 修正与 5/5 mutation 已写成状态
`validated` 的 `KnowledgeGap`。两份记录均明确 `training.eligible=false`：没有 unseen exam、93c8
timing hard gate FAIL，且 post-fix d3f3 尚未完成同设计再认证。记录路径：

- `learning/experience-v16a-owner-permit-93c8.json`
- `learning/gap-serialized-permit-cancel-cycle.json`

对 d3f3 只构建了一次 report-only selector：
`evidence/selector-live-v16b.json` 返回
`STATE_CONFLICT / STATE_RECONCILIATION / selected_slice=null`。architecture、layered-system、
performance 与 PPA current authorities 仍绑定 f72e；因此下一有界动作是按 d3f3 重新建立必要的
current receipts，而不是覆盖 selector、复用 93c8 身份或宣称 promotion。
