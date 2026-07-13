# T3K — CSR head probe isolation

## Objective

Remove the late commit/pending CSR-access selector from the current-head CSR
legality path that feeds pending-trap capture, while preserving complete CSR
functionality and exact pre-edge privileged-state semantics. The final timing
claim still requires a fresh current-source H7CL 5 ns synthesis/OpenSTA run.

## Root cause

The pre-T3K `OooCsrAccessRequestMux` multiplexes commit0, pending SYSTEM, lane1,
and lane0 onto one `csr_access_*` port. `CsrFile.csr_illegal_o` answers that
shared port, yet `OooCsrIllegalProbeGate` consumes it as the current-head
legality result. Consequently late execute/ROB completion and pending-state
selection enter the combinational cone to `OooPendingTrapExitSequencer`.

## Interface contract freeze

### Requirement and boundaries

- Keep the existing `csr_access_*` path, priority, readback, and architectural
  side effects unchanged.
- Add `csr_probe_valid/addr/funct3/rs1_idx`, produced only from current head0 or
  eligible head1. No GPR data is required and the probe has no side effects.
- `CsrFile.csr_illegal_o` becomes the probe answer. An internal
  `csr_access_illegal_w` independently guards the existing main access commit.
- Both answers use exactly one pure `csr_access_illegal_raw` definition.
- Out of scope: registering legality, false/multicycle paths, policy `S_next`
  bypass, CSR read-data redesign, pending priority changes, or ISA behavior
  changes.

### Protocol, state, flush/stall, and priority

- Both interfaces are same-cycle combinational views, not valid/ready
  handshakes; inactive payload is non-architectural.
- `OooCsrAccessRequestMux`, `OooControlPlane`, and glue add no state. `CsrFile`
  adds no state for this change.
- Main access priority remains `commit0 > pending SYSTEM > lane1 > lane0`.
  Probe priority is `eligible lane1 > lane0`, with valid
  `head0_csr_raw || head1_csr_probe`.
- Reset/stall/flush do not create probe storage. Existing upstream capture_base
  and trap/direct-flush gates own whether a combinational result is consumed.
- Precise priority remains trap/exit > CSR/xRET > branch > prediction > normal;
  a privileged-policy transition must squash/block a younger capture rather
  than feed post-edge policy into the same-cycle probe.

### State and data-flow model

```text
commit/pending/head fallback -> csr_access_* -> readback + main legality -> commit side effect
current head0/head1 only     -> csr_probe_*  -> probe legality          -> pending trap classify

main_illegal  = L(S_q, main_access)
probe_illegal = L(S_q, head_probe)
S_next        = T(S_q, trap/xRET/main_commit/fp_dirty)
```

Both legality evaluations see pre-edge `S_q`; only the main path may enter
`csr_new_value` or the sequential CSR update block.

### Invariants and executable evidence

1. Changing only commit/pending inputs cannot change any probe output.
2. Main and probe with identical payload/state return identical legality.
3. Main and probe may be valid simultaneously with different payloads and each
   result remains owned by its own interface.
4. Probe-only activity changes no architectural CSR state.
5. A policy-changing edge affects legality only on the following cycle.
6. Source/netlist checks must prove the commit/pending/access-selector cone is
   absent from pending-trap probe paths while a non-empty head/CSR-state path
   remains; empty object sets are failures.
7. Every assertion/checker must be exercised by a deliberate mutation or
   negative probe before it may count as GREEN evidence.

## RTL topology review

- Modules/interfaces: four new combinational wires pass through
  `OooCsrAccessRequestMux -> OooControlPlane -> OooCoreTopGlue -> NpcCoreTop -> CsrFile`.
- Registers/FSM/pipeline: none added; no reset or enable is added.
- Combinational blocks: a head-only lane selector and two elaborations of one
  small pure legality predicate.
- Shared/replicated resources: the legality definition is shared in source;
  synthesis may replicate decode logic for timing, but must not select between
  main/probe operands inside the probe cone.
- Critical path expectation: remove EX/ROB commit selection from probe;
  residual head instruction/state decode through illegal gate and pending
  arbiter remains real and must be measured.
- Function boundary: only `csr_access_illegal_raw` and small address/write
  predicates are functions. Arbitration, state update, trap/flush, and capture
  remain explicit RTL.

Topology review result: coherent; all producers/consumers, state ownership,
same-cycle semantics, and priority boundaries are frozen before RTL editing.

## 实现结果

- `OooCsrAccessRequestMux` 产生 head-only probe：lane1 仅在 lane0 不是 CSR 且
  lane1 是可探测 CSR 时拥有 probe，否则选 lane0。probe 不携带 GPR data，也不引用
  commit/pending/main-access selector。
- 四根 wire 按同名 ABI 穿过 `OooControlPlane`、`OooCoreTopGlue`、`NpcCoreTop`，直达
  `CsrFile`。现有 main access 优先级、readback、CSR write、trap/xRET 与 flush owner 未改。
- `CsrFile` 以 `csr_addr_known`、`csr_addr_writable`、`csr_write_intent` 和唯一 7 参数
  `csr_access_illegal_raw` 表达 legality。main 与 probe 各调用一次；公开
  `csr_illegal_o` 回答 probe，顺序写只由内部 `csr_access_illegal_w` 守卫。没有新增寄存器、
  FSM 状态或 next-state bypass。
- `OOO_ASSERT` 下的 `[CSR-LEGAL-VIEW-EQUIV]` 只在两个 port 的 tuple 相同且同时 valid 时
  检查调用结果一致。它不是 predicate 语义正确性的证明；后者由独立穷举与 mutation 负责。

## 可执行合同与负向证据

Canonical evidence：`evidence/current-contract-root-final-v2/`。

- source contract：唯一 raw predicate 定义 1、调用 2、参数 7；probe cone 13 nodes；
  4 个 boundary、16 个 exact named connections。
- legality domain：raw 720896 cases、routing 45056、isolation 45056、valid gate 2，全部
  与独立 reference model 一致。
- mutation：10/10 expected RED，其中 6 个结构污染/cross-wire/side-effect guard 变异和
  4 个 TVM/counter/privilege/writable 语义变异。
- assertion negative：精确一次 `[CSR-LEGAL-VIEW-EQUIV]` 且前提 non-vacuous；缺 marker、
  重复 marker、false-green、sim nonzero、classifier input error 自测均 fail closed。
- `current-contract-root-rerun/` 在 checker 仍被编辑时启动，明确作废；其它旧版本见
  `evidence/superseded-evidence.md`，不得参与交付结论。

## 功能与可达性验证

- 独立审查发现首版 SRET/TSR 用例直接注入 S-mode + TSR=1；该状态不能由真实前端合法进入，
  属于证据假绿。最终 TB 从 M-mode 通过合法 CSRRC 清 TSR、保留 TVM/MPP=S，再经 MRET 进入
  S-mode，分别证明 reachable TVM=1/TSR=0/MPP=S、合法 MRET 与 SRET 的 pre/post-edge 语义。
- `tb_ooo_priv_system` 新增真实双发事件链：PC `0x80000008/0x8000000c` 的 lane0 ADDI +
  lane1 MTVEC CSRRW，精确一次 `dispatch1_barrier_fire`、lane1 pending capture 与
  probe tuple `{addr=0x305,funct3=001,rs1=1,illegal=0}`。人工不一致 tuple 只标作
  structural/mutation，不冒充可达微架构事件。
- reviewer-repaired focused 3/3 PASS；最终 module regression 为 96/96，summary SHA256
  `6d11123526638a0f0ea39e1be2ec3dd75cd7fa4bfcfffc7a65bb90a330a1903f`。
- protected core regression `evidence/core-regress/20260713-180949-3008402/`：module、
  Verilator lint、NPC build、AM cpu-tests、official+privileged 177/177，`overall_rc=0`。
  它早于 reviewer 的 test-only 可达性补强，但生产 RTL 完全相同；补强后的 96/96 final
  module run 单独覆盖最新 TB。
- CoreMark 10 iter：CRC `0xfcaf`、GOOD TRAP、3020147 cycles、3218532 commits、
  CPI `0.938`、3.379/MHz；与 T3J cycle-exact。
- final `make lint`、`check-rtl-style`、`check-contract`（88/88）与 `git diff --check`
  全 PASS，日志在 `evidence/final-static/`。
- 保护输入的 pre/post SHA 完全保持，见 `evidence/protected-inputs-status.txt`；
  `build/linux-logs/npc-linux.log` 与三个用户 dirty RTL 均不纳入本提交。

## Fresh synthesis 与 OpenSTA

### Synthesis identity

- fresh result：`tmp/2026-07-13-rv64-t3k-csr-probe-isolation/sta-build/NpcTop-200MHz/`；netlist SHA256
  `0161d3d41300cd41a80f4da3cd649cc8defb98548c23eb324efc140fec583b32`，known area
  `1573200.16`，runtime `1349.67s`，110 modules、0 error、3 次 zero-problem check。
- pre/post freeze：110 RTL、完整 133-entry vsrc tree、14 flow、5 liberty、9 synthesis
  evidence scripts、6 tool binaries与 exact parameter/version 全 PASS。综合网表后续修 checker
  前的 9 个 evidence scripts 已原样复制到 `synthesis-frozen-evidence-scripts/`，hash 与 synth
  pre-manifest 完全一致。
- 审计明确 `dynamic_libraries_frozen=false`、`tool_support_tree_frozen=false`。此外 netlist
  包含共享工作树中受保护的用户 dirty RTL；manifest 能绑定本次输入，但 clean Git HEAD 不能
  单独复现。因此这是一份扩展 provenance 的 fresh 逻辑级证据，不是物理 signoff。

### Directed physical proof

Canonical tag 为 `-root-final-v6`：

- structure cone：旧 `csr_illegal=legacy:19`；fresh `csr_illegal=probe:19`；probe mux 只由
  current head 45 位输入驱动，commit/pending 不在 probe cone。旧网表冒充 fresh 精确 RED。
- old focused pending endpoint intersection：
  `legacy/head/state/illegal/probe=133/133/133/133/0`。
- fresh focused：`0/133/133/133/133`。这证明共享 main-access legality 物理路径被移除且
  live probe/head/state/illegal residual 保留；不声称所有 commit→pending 控制路径消失。

### Global 5 ns result

- OpenSTA 3.1.0，40 paths、0 combinational loops；WNS `-8.720ns`、TNS
  `-199154.36ns`、vectorless power `0.117W`。
- warning closure 精确为 missing input delay 303、missing output delay 1861、
  unconstrained endpoints 1863；无第四类 warning/error。
- target checker `--expect miss` PASS，`--expect met` 精确 rc=1。故 T3K 的物理切点成功，
  但 200MHz 父目标明确未完成。
- 新 top path arrival 约 13.688ns：fetch bridge/ITLB/PMP/cache-hit payload 经 packet/RVC
  decode、lane1 B-imm 与 64-bit target add，同拍落 `fetch_pc_outstanding`；top40 约 13 条
  落 outstanding、其余落 fetch packet FIFO。T3L 应切 response→decode/decision 边界或先
  对窄 immediate/target ABI 做可信 A/B，禁止 false path。

## 归档、DB 与 e2e 收尾

- workspace fresh STA archive：108 entries、950626698 logical bytes，archive SHA256
  `e1326a5795f2965b3f14ca9afa5aa987eadb2323dd53f98b179439ddb6109a93`；zstd、tar list、
  pre/post inventory 与源 hash 检查均 PASS。
- OS `/tmp` 精确枚举到 4 个 T3K root：三个 focused/integration 目录与
  `/tmp/ysyx-t3k-user-npc-linux.log`。41 entries、16986222 logical bytes 已归档到 workspace，
  archive SHA256 `031297be37c1ee454c1d0b9d6ec4539befedbe2877a5e856d83844fa68ea7620`；
  pre/post inventory、archive-vs-source compare 与保护日志 hash PASS，源文件未删除。
- DB-first：四份 stored memory 均从完整 materialization 追加后 `update-stored
  --refresh-shim`；`snapshot-stored`、`audit-db-first`、`audit-markdown-coverage` 全 PASS。
- `npc-dev`、`agent-system`、`yosys-sta` 三个最终 profile task-run 全 PASS；
  `scripts/agent-e2e.sh --guard --guard-mode strict` PASS。

## 实现者/审查者裁决

实现者证据证明 T3K 在当前冻结输入上保持功能并真实移除了目标共享 CSR legality 长链。
审查者曾找到不可达 SRET 测试、失败 TB stub、checker fail-open/空对象和过强
“all commit paths”方法等反例；所有冲突均以可达 TB、mutation、自测和 v6 物理方法关闭。
剩余风险只有父目标本身与已明示的逻辑级 STA/provenance 边界：WNS 仍为负，不能交付
“200MHz 已达”。下一刀 T3L 从 bridge 组合 response 到 decode/predict/outstanding/FIFO 的
单拍融合入手，继续执行同样的 fresh current-source 5ns 验收。
