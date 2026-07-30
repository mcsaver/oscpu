# V10G queue-head serialization currentness report

## 状态

`BOUNDED_COMPLETE`。

本轮闭合本地 RV64 双发射 OoO 核的 `SERIALIZE-G1` Phase1
split-domain：合法非 FP lane0/head0 CSR 走 queue-head retirement；
lane1/FP CSR、其余 SYSTEM、architectural trap 与 simulation exit
继续由 pending/full-drain owner 管理。

当前 production-default design-id：

`sha256:04c5458ff274b7b30e0629fc20ccef4ffa958dee3b80595ee4b46faf17a73897`

## 实现与 transaction 证据

- `product-rtl-defaults.mk` 统一产品配置为
  `OOO_CSR_QUEUE_HEAD=1`、`OOO_TERMINAL_HOLDER_ASSERT=1`。
- queue-head CSR 原始 C0/C1/C2 计数在 assertion/release 两种编译配置
  均通过；每种配置含 3 个 committed 与 2 个 killed transaction。
- 两个 C2 compile-success RTL 版本分别破坏 typed apply 与 CsrFile
  request 路径，均被定向 testbench 动态拒绝。
- SYSTEM product-default 矩阵为 3/3 baseline PASS、14/14
  compile-success RTL 版本被拒绝；SATP、SFENCE、FENCE.I、FENCE、
  WFI、CSR exact owner/PC、holder/stop clear 均保留各自观测。
- current-design replay 为 26/26 PASS：module 113/113、official
  177/177、AM 59/59、DiffTest mismatch 0、CoreMark/Dhrystone marker
  PASS、架构门 9/9 GREEN。
- production RTL 在最终 currentness 维护阶段没有语义修改；没有增加
  terminal 去重，也没有削弱断言。

权威复核命令：

`python3 .github/task-runs/2026-07-28-rv64-v10g-serialize-currentness-closure/verify_serialize_g1_closure.py`

结果：

`raw_c0_c1_c2=PASS c2_negative=2/2 system=3/3+14/14 replay=26/26 review=APPROVED`

## A3/A4 系统事务边界

- A3 原始 published gate 保持 `FAIL rc=1`，未改写历史状态。
- A3 的 execution、DUT terminal、binding、raw artifact 与 RTL
  assertion 分别为 `COMPLETE / COMPLETE / NO_DRIFT / VALID / CLEAN`。
- 唯一失败来自旧 dmesg oracle 将 `printk: debug:` 误判；冻结输入重放
  和正负向单测已独立证明修订后的 checker 接受该行并拒绝真正的
  `BUG:`。
- A4 保持 `FAIL rc=143 signal=TERM`，不作为 PASS 证据。
- production core RTL、实际 elaborated RTL、device model、
  simulator execution semantics 与 A3 所需原始输入均未触发完整系统
  重跑条件，因此 `full_system_rerun_required=NO`。

## 独立审查

final-review v2 对候选、合同、raw counter、两份 C2 负向版本、
SYSTEM 矩阵、26-stage replay 与 A3 分类执行只读反例优先复核。
historical gate 与 checker-currentness 维护完成后，final-review v3
通过隔离合同再次核验 historical depth、9/9 checker replay、
XRET holder-onehot 负向观测、4 份 cohort contract、V9O 167/167
逐项索引及 A3/A4 状态边界。

裁决：

`APPROVED_FOR_CURRENT_SCOPE`

两次审查均未发现未解决的 Phase1 RTL counterexample。v3 还确认
`GAP_MARKER_SCHEMA_ONLY` 只是旧 marker schema 记录；当前
owner-bound raw scoreboard 会以 `rc=1` 拒绝同一 compile-success
RTL version，并记录 repeated/unowned transaction。审查不覆盖
Phase2–5、正式 architecture freeze 或 PPA promotion。

## 历史缺陷 backfill

新增 versioned ledger、JSON schema、检查器和 4 个负向单测。验证深度
为 VD0–VD4，且 VD0/VD1 会阻止 architecture freeze。

当前 5 项状态：

- VD4：simulation-exit active-memory early terminal；
- VD4：A3 dmesg oracle；
- VD3：V8L force/release stale-holder false green；
- VD1：queue-head CSR 与 younger SQ store 的历史 wait-for cycle；
- VD1：stop/holder drop 历史缺陷。

最高优先级选择为 `HIST-SER-QH-YOUNGER-STORE-CYCLE`。当前 positive
older-store case 不能替代该 younger-store 历史反例，因此保持 VD1，
不得越级标记为清零。

## Checker identity 与架构证据维护

将 historical gate 接入 `arch_stable_freeze.py` 后，旧 closed-debt
结果因 checker identity 变化而诚实失效。本轮没有重复 113 项模块或
Linux/system 仿真，而是：

- 从冻结 module/program 日志和 RTL-version summary 重放 9 个
  closed-debt checker，9/9 PASS；
- 对全部重放输入做前后 SHA-256 比对，结果完全不变；
- 重新生成 XRET 8 个 RTL 版本与 2 个 observer probe，全部编译成功
  且被动态拒绝；
- 重建 DI-1/DI-2 根链，得到架构门 9/9 GREEN、30/30 负向单测 PASS；
- 重绑 4 份 cohort exclusion、holder census 与 V9R SQ-retry；
- 重建 V9O index：167/167 artifact PASS、module 113/113；
- `test_arch_stable_freeze`：48/48 PASS。

## 当前硬门

最终 current audit 可校验、共有 32 个 blocker；其中不再含任何
CLOSED debt 的 hash、semantic evidence、cohort contract 或
architecture provenance 漂移。

保留 blocker：

- 两个 VD1 historical defect；
- whole-core holder census 尚未达到 full instance/semantic closure；
- `full-core-current.json` 尚未构造 cohort inventory 与 binaries、
  config、filelists、generated headers、images、liberty、macros、
  specifications、test sources、tool versions、constraints、workflow
  的正式 freeze-input inventory。

因此：

- `SERIALIZE-G1=CLOSED`（仅 Phase1 current scope）；
- `ARCH_STABLE=GAP`；
- `PPA=UNQUALIFIED`；
- `promotion_eligible=false`。

## 工作流闭环

- project-status 与 NPC module memory 已通过 DB-owned
  `update-stored` 发布。
- `rv64-historical-defect-backfill-loop` 已写入硬件开发蓝图；使用
  `RV64 historical defect backfill VD0 VD1` 的 `npc-dev` bounded brief
  可独立命中该非历史入口。
- 首个含 `v10g` 的 e2e slug 因没有独立 focus 命中而保留为
  `blocked`，5 个 profile 节点的 PASS 不被越级发布。
- 修正后的 `npc-dev` task-run 为 completed、5/5 PASS。
- `agent-system` task-run 为 completed、11/11 PASS，覆盖规则发现、
  三层环境、RTL task contract、状态机、reviewer/inspector 和
  fail-closed task status。
- strict guard 以 42 个 V10G-owned source/contract/report 路径运行，
  `npc-dev` 与 `agent-system` 两个 required profile 均 PASS。
- 当前 mixed-origin 工作树含既有 staged 用户文件和大量其它生成物；
  本轮不创建 commit，不执行 push/amend/reset/restore/clean/stash。

## 下一项

默认继续最高优先级历史缺陷
`HIST-SER-QH-YOUNGER-STORE-CYCLE`：重建“head CSR 等待
`mem_idle && sq_empty`、younger SQ store 又等待 CSR retirement”的
最小历史 RTL 版本，要求 compile success，并由当前 queue-head
testbench 动态拒绝。只有该项达到至少 VD3 后才处理下一 VD1；VD0/VD1
全部清零前不发布 architecture-stable，也不进入正式 PPA promotion。
