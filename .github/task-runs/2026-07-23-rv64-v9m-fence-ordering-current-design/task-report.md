# V9M FENCE-G1 current-design closure

## 状态

`COMPLETED`。仅关闭当前 design-id 下的 `FENCE-G1`；full-core ARCH_STABLE 仍为
`GAP`，PPA 仍为 `UNQUALIFIED`，promotion 保持 `false`。

## Root cause / 本轮边界

T4L 已修复 ordinary `FENCE` 被当作普通 backend 指令以及仅等待退休侧 memory quiet
的问题；随后 production RTL 继续演进，旧证据不再绑定当前 design-id。本轮不重新修改
功能逻辑，根因是证据 provenance 过期，而不是重新出现同一 RTL 缺陷。

本轮 reviewer 进一步定位了五类可构造假绿：负向日志只看 JSON 自报字段、允许额外
`[CHECK-FAIL]`、正向模块日志未拒绝失败诊断、运行日志可被重新绑定到新 design-id，以及
CoreGlue→ControlPlane `mem_idle` 连接没有 full-core 运行时反例。实现者逐项关闭后，最后一个
残余为目标行/`errors`/`status` 只做前缀或子串匹配；现已改为精确逐行判定。

## RTL 与证据实现

- `tb_ooo_priv_system.sv` 增加普通 `FENCE` 等待期间
  `u_control_plane.mem_idle_i === core_mem_idle_w` 的运行时连接检查，并把
  `mem_idle_binding=1` 纳入唯一 `[FENCE-G1-PROGRAM] ... PASS` marker。
- focused 与 109 个模块日志在强制重编译/仿真后写入同一
  `[RTL-DESIGN-ID] sha256:2eff867b...c8b2`，证据 builder 逐日志校验 exact-one marker。
- 两份可编译负向 RTL 版本分别常量化 drain gate 的 FENCE memory-idle 条件和
  CoreGlue→ControlPlane `mem_idle` 端口连接；两者均成功编译，并只被各自指定检查检出。
- runner、evidence builder 与 ARCH_STABLE semantic validator 均要求唯一完整目标
  `[CHECK-FAIL]`、唯一 `[FAIL] <test> errors=1`、唯一 `[RESULT] FAIL status=1`，并拒绝
  其它检查失败或正向日志中的 `ERROR:`/`FATAL:`。
- `FENCE-G1` 已写入 `architecture-debt-ledger.json`，并由独立
  `validate_fence_debt()` 重建 live RTL/source/log/variant 绑定。

## 交付证据

- design-id：`sha256:2eff867b20012e0c004fb03431a2f0604f22c471d0b115fd2e02eb5a51b2c8b2`
- canonical：`make -C npc/rv64 check-fence-ordering`，PASS。
- focused：2/2；`tb_ooo_priv_system` 与 `tb_ooo_pending_drain_resolve_gate` 均 PASS。
- module aggregate：109/109 PASS。
- compile-success negative RTL variants：2/2 被指定 testbench 精确检出，production source
  前后 SHA 不变。
- validator unittest：12/12 PASS，覆盖目标行尾缀、`errors=2`、`status=7`、缺失编译行、
  额外检查失败与正向 `ERROR:` 诊断。
- 共享 provenance 刷新：9/9 既有架构 canonical target PASS；九门 architecture aggregate
  重新生成后为 GREEN，PPA 仍 UNQUALIFIED。
- ARCH_STABLE：`run-arch-stable-audit.sh` 的 audit/verify 与 134 项单测 PASS；最终
  `status=GAP`、`blockers=38`、`ppa=UNQUALIFIED`、`promotion_eligible=false`。

关键产物 SHA-256：

- `npc/rv64/eval/ppa/evidence/fence-ordering-current.json`：
  `792b8c2c9454d01eb5143019136d6b3add734019ff20cd66cd36efef961e2ec0`
- `npc/rv64/eval/ppa/evidence/fence-ordering.log`：
  `3481db6a72c52a786139231107d5ef6e8ba93f19a1018bbe33061ffb875e83c1`
- `evidence/rtl-variants/summary.json`：
  `f7a6a6ad904d26d4c72413f1bbeeccd477e30e1f17558cdfe952ee0dbc576af2`
- `evidence/module-aggregate/summary.txt`：
  `6d528dafac6addff4fbb93739a17b7744c7e8404123537e6f4edfc4dd667407e`
- `npc/rv64/eval/ppa/evidence/arch-stable-current.json`：
  `7b863eba1c299cec4ab6cf174c4b172e8fbf7e54746f4e9bd7da78b917555db3`

## 实现者 / 审查者分离

- 实现者负责 current-design 程序、端口连接检查、负向 RTL 版本、日志 design-id、证据 builder、
  账本与依赖 provenance 刷新。
- 审查者使用 v1/v2/v3 只读合同；v1 因缺少 `mem_idle_o` 生产/传递链而返回 INCONCLUSIVE，v2
  找出五项假绿边界。修正后复核确认 RTL 功能链没有新增缺口，仅剩精确日志匹配，随后实现者补齐。
- v3 直接核对 `arch-stable-current.json`：design-id 五侧一致，FENCE-G1 八项语义检查 PASS，
  focused/module/variants/unittest 为 2/2、109/109、2/2、12/12；全核继续为 `GAP`、38 blockers，
  PPA 为 `UNQUALIFIED`、promotion=false。终审结论为 `PASS`，且没有扩大 FENCE-G1 的声明边界。

## 失败与纠偏

- 共享 TB task 不能覆盖全部 109 个测试的 design-id marker，改为 testbench Makefile 在每个
  目标完成结果检查后统一写入；空变量时保持既有工作流不变。
- 负向仿真目标检查行包含 testbench 自动生成的 `got/expected`，且预期用 `$fatal` 结束；规格改为
  精确完整检查行，并仅拒绝额外 `ERROR:`，不把预期 `$fatal` 当作编译失败。
- `runtime_log_design_id` 一度误放到 XRET validator；已移回 FENCE binding，并通过所有 XRET/FENCE
  live validator 单测。
- 共享 Makefile/TB/freeze validator 变更使旧 provenance 失配；未手工重包装旧结果，而是顺序重跑
  9 个既有 canonical target 和九门 architecture aggregate 后更新账本 SHA。

## 工作流措辞固化

根 `AGENTS.md`、`.github/AGENTS.md`、`.github/copilot-instructions.md` 与
`AI_ENVIRONMENT.md` 已要求主/子 agent 的用户进度、终审和派发首句落到本地 RV64
module/signal/transaction、仿真/综合/STA 与证据产物；协调状态单独进入 task-run。该分层不建立
关键词黑名单，也不减少源码探索、命令、负向 RTL 版本、断言、覆盖矩阵、独立复核或 PPA 能力。

## 声明等级

- `FENCE-G1` architecture debt：`CLOSED`，仅对当前 design-id 与上述证据成立。
- full-core architecture freeze：`GAP`，仍有 38 个 blocker。
- PPA：`UNQUALIFIED`。
- promotion：`false`。

## 剩余风险

- `A-COHERENCE-G1`、`CONTROL-EVENT-G1`、`SERIALIZE-G1`、`WFI-G1`、
  `SFENCE-SINVAL-G1`、`VECTORED-TRAP-G1`、`DEBUG-TRIGGER-G1` 等仍未闭合。
- STORE/AMO outstanding owner 的同沿清除仍需要独立生命周期守恒断言：
  `request_sent && !terminal -> next(entry resident || terminal accepted)` 及 AMO 对应式。
- cohort inventory、完整 freeze inputs、full-core producer-holder semantic census 与正式 PPA
  输入仍缺失；本轮结果不得外推频率、面积或功耗结论。
