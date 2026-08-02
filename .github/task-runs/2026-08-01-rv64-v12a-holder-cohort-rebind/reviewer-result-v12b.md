# V12B independent RTL review

RV64 RTL 结论｜对象=`OooRob` pending-system `ProducerId` 出生/精确退休及三个 control module 的 attempt-9 编译输入闭包｜周期/配置=`OOO_PRODUCER_GEN_W={1,4}`、g4 `OOO_ASSERT`、design-id=`sha256:882111fb3d58039cb7414e6331dac0c10d848463df2228dff93ae22dafbed67b`｜TB/EDA 观测=41 个 profile record/48 次实际编译、三项新增 compile-success 变异均被检出、124 项 checker 单测 OK｜范围=PASS（仅 `pending-system-producer` local semantic closure）

- 实际 `iverilog` argv 与 `-Mprefix` dependency 同时覆盖 `OooRob.v`、`OooPendingDispatchArbiter.v`、`OooPendingDrainResolveGate.v`、`OooPendingSystemAdmissionCancelGate.v`。当前 live SHA 与 attempt-9 一致：`npc/rv64/testbench/Makefile=33723063…`、`npc/rv64/vsrc/filelist.mk=6529498b…`，四个 claim RTL 分别为 `bbb68a2a…`、`157608c4…`、`e03a6054…`、`b4e7b434…`。
- checker 对 `[COMPILE]`、真实 argv、dependency、Makefile/filelist、每个 live input SHA、169 项清理记录及 terminal `runner.status` 均 fail-closed；`test_v11u_compiler_closure_cannot_drop_rob`、Makefile digest 和 argv 缺字段等负向单测包含在 `Ran 124 tests ... OK` 中。
- `OooPendingDrainResolveGate.system_csr_dispatch_fire_o` 在 admission 未取消、drain/owner terminalized 且 `dispatch0_ready_i` 时产生 ROB allocation fire；`OooRob.dispatch0_producer_id_o={next_generation, rob_idx}` 形成出生身份；`head0_producer_id_o`/`commit0_producer_id_o={slot_generation_q[head_q],head_q}` 形成精确退休身份。
- 正向 marker：`[V11U-PRIV-INTEGRATION] dispatch=1 birth=1 exact_commit=1 death=1 PASS`；`[V11U-PRIV-FLUSH] birth=1 raw_lease=1 backend_mask=1 flush_death=1 PASS`。
- `rob-dispatch0-generation-dropped` 由 `[V8E-PRODUCER-ID-DISPATCH0]` 检出；`rob-head0-generation-flipped` 由 `[V8E-PRODUCER-ID-HEAD]` 及 `exact_commit=0 death=0 FAIL` 检出；`pending-drain-system-csr-fire-disconnected` 由 `dispatch=0 birth=0 exact_commit=0 death=0 FAIL` 检出。
- attempt-6/7 保留 `FAIL rc=1 stage=source-binding-post evidence_complete=0`、结果/日志与 source hash；attempt-9 为 `PASS rc=0 stage=complete evidence_complete=1 cleanup_rc=0`。三次尝试均无 `*.vvp`、`*.argv`、`*.deps`、`generated/**` 或 `variants/**` 残留。
- V11H receipt 保留原始 `FAIL`，明确未重跑 RTL/full-system、历史 full-RTL snapshot 非当前；44 项仅为局部 `units_semantic_pass=44`。总台账仍是 `status=GAP`、`whole_architecture=RED`、`ppa=UNPROMOTED`。

未知项与合同注记：本节点未重跑仿真，结论基于当前 live SHA、保存日志及当前 gate。合同误列不存在的 `npc/rv64/testbench/tb_ooo_priv_system.sv`，真实输入为 `npc/rv64/testbench/tests/tb_ooo_priv_system.sv`；现有 checker 已字节绑定真实路径，故不影响当前编译输入闭包判定。若以后要求逐行 TB/ControlPlane 独立源码审查，需在新合同加入真实 TB、`OooControlPlane.v` 与 `OooPendingSystemSequencer.v`。

Reviewer contract: `.github/task-runs/2026-08-01-rv64-v12a-holder-cohort-rebind/subagent-contracts/v12b-v11u-compile-input-closure-review.json` (`sha256:4095fcd6a664fe4bc6b6dca985dfd199cd4f54510ee5add6cf5d858ef6b16979`).
