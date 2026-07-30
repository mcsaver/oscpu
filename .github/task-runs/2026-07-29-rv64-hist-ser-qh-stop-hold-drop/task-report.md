# HIST-SER-QH-STOP-HOLD-DROP 任务报告

## 1. 状态与本轮边界

`COMPLETED_BOUNDED_VD3`

本轮只处理本地 RV64 双发射 OoO 核的
`HIST-SER-QH-STOP-HOLD-DROP`。production core RTL、端口、状态位宽与组合数据
路径均未修改；改动限于 product glue testbench、focused Make target、架构规范和
可审计 task-run。

长期 RV64 架构/PPA goal 保持 active。A3 原始
`FAIL / strict 16/17 / rc=1` 保持不变；其系统事务完成、旧
`dmesg-no-critical` oracle 误判的分类不被本轮覆盖。本轮没有改变 production
core RTL、当前 elaborated system RTL、device model 或 simulator 执行语义，也
没有发现 A3 terminal/post-hash 缺口，因此不启动完整系统重跑。

## 2. RTL 对象与事务链

- birth：
  `OooFrontend.head0_csr_dispatch_fire_w`
  → `head0_csr_inflight_q`
  → `OooControlPlane.v9x_head0_csr_owner_birth_w`；
- state：
  `OooStopPendingSequencer.stop_pending_o`；
- owner-to-busy：
  `OooFrontendRunGate.stop_pending_owner_w`
  → `orphan_stop_pending_o`
  → `stop_pending_busy_o`
  → `can_run_o`；
- younger transaction：
  successor packet lane1 CSR
  → `OooPendingDispatchArbiter.pending_system_capture_lane1_o`
  → `OooPendingSystemSequencer`；
- terminal：
  queue-head CSR C0 commit/barrier/CsrFile request
  → C1 typed apply/serial flush
  → C2 raw quiet。

## 3. 初始假设与纠偏

初始计划把根因限定为 sequencer 的
`head0_csr_inflight_i && !head0_csr_owner_kill_i` 保持臂，并预测删除该臂后
ordinary drain 会清 stop。

product TB 实测拒绝了这个单臂假设：

- `head0_csr_inflight && drain_complete && !head0_csr_commit` 为 0；
- 正确 BNE resolve 时 `branch_spec_resolve_valid=0`、
  `branch_resolve_untracked=0`；
- 只删除 sequencer hold 的 compile-success 版本仍得到 zero owner gap、
  zero stop drop、zero inflight run、zero lane1 overlap。

当前 `OooPendingDrainResolveGate.backend_drained_o` 要求 ROB empty，所以
queue-head CSR 仍在 ROB 时 ordinary drain root 不可达。后续源码核对发现真正的
互补合同还包括 `OooFrontendRunGate` 的 queue-head inflight owner。

历史边界为：

- `7f66f9d9d4badc08e0c51dc65c4db2b99683de46^`：两项均缺失；
- `7f66f9d9...`：只补 sequencer inflight hold；
- `2a77fd4b6b69b75f45f651722e17a7c214a2d55c`：补 RunGate inflight
  owner 与 `[T3U-CSR-STOP-OWNER]`。

因此 ledger 原先“单一 hold 臂 + ordinary drain”的因果表述需要修正为
“owner state + owner-to-busy 双合同”；历史症状材料保留，但不能代替当前拓扑
的 raw 证据。

## 4. Product testbench 与 raw scoreboard

`tb_ooo_core_top_glue.sv` 新增 mode 27：

```text
0x80000000  auipc x2
0x80000004  addi x3, x0, 0x55
0x80000008  lw x1, 0x40(x2)       # 返回 0
0x8000000c  bne x1, x0, +12       # correct not-taken
0x80000010  csrrw x0, mscratch,x0 # older queue-head CSR
0x80000014  addi x4, x0, 4
0x80000018  addi x5, x0, 5        # successor lane0
0x8000001c  csrrs x0, mstatus,x0  # younger lane1 CSR
0x80000020  addi x6, x0, 6
0x80000024  ebreak
```

所有 birth/capture/commit 来自真实 frontend/control-plane 数据流，没有 force
内部 owner、stop、inflight 或 lane1 capture。scoreboard 每拍计数，不使用
sticky 去重，覆盖：

- queue-head CSR birth 与 inflight hold；
- ordinary drain/non-kill resolve candidate root；
- orphan owner gap、stop drop、inflight `can_run`；
- successor packet 与真实 lane1 system capture；
- older PC `0x80000010`、younger PC `0x8000001c` 及 CSR decode fact；
- C0 commit/barrier/CsrFile、C1 apply、C2 quiet。

新增 Make target：
`tb_ooo_core_top_glue_hist_ser_qh_stop_hold`。

## 5. Compile-success 八 case 矩阵

runner：
`.github/task-runs/2026-07-29-rv64-hist-ser-qh-stop-hold-drop/run-stop-hold-matrix.py`

矩阵为四种 RTL 语义 × assertion on/off：

| 语义 | assertion | compile | raw 观测 | oracle |
|---|---:|---:|---|---|
| current | on/off | 2/2 | gap/drop/run/overlap 全 0 | PASS |
| drop-stop-hold | on/off | 2/2 | gap/drop/run/overlap 全 0 | PASS，successor owner witness |
| drop-RunGate-owner | on/off | 2/2 | gap=2，run=2，real overlap=1，stop drop=0 | 两个配置均拒绝 |
| historical-pre-T3U | on | 1/1 | gap=1，run=1，drop=1；既有 assertion 先终止 | 拒绝 |
| historical-pre-T3U | off | 1/1 | gap=1，run=2，drop=1，real overlap=1 | raw scoreboard 拒绝 |

总计 `cases=8/8, compile=8/8, status=PASS`。

current 与 drop-stop-hold 的 raw marker 均为：

```text
hold_cycles=6 nonkill_resolve_root=0 ordinary_drain_root=0
orphan_owner_gap=0 stop_drop=0 inflight_can_run=0
successor_packet_cycles=0 lane1_overlap=0 C0=2 C1=2 C2_quiet=2
```

drop-RunGate-owner 在 cycle 6 观察到：

```text
older_pc=0x80000010 younger_pc=0x8000001c stop=1 can_run=1
```

historical-pre-T3U assertion-off 在 cycle 5 先出现 owner gap，cycle 6 观察到
`stop=0, can_run=1` 与同一真实 lane1 capture。assertion-on 保留
`[V9X-STOP-QCSR-HOLD]` 和 `[T3U-CSR-STOP-OWNER]`，没有为收集 overlap
削弱断言。

## 6. Checker、重放与分层回归

- runner/oracle 定向单测：
  `test-stop-hold-matrix-runner.py`，`7/7 PASS`；
- 首次单测因动态模块未注册 `sys.modules` 而失败；只修正测试夹具装载，
  RTL/matrix oracle 未改变，重跑 `7/7 PASS`；
- replay：
  `check-stop-hold-matrix-replay.py`；
  summary bytes、8 个 case logs、8 个归一化 VVP identities 全部稳定，
  `status=PASS`；
- raw VVP bytes 含 allocator 标识，重放可变化，明确不作为 semantic identity；
- `tb_ooo_core_top_glue_v9o_csr_qh` assertion on/off：均 PASS，五个既有
  queue-head CSR positive/kill/callback 程序保持 C0/C1/C2 合同；
- `tb_ooo_stop_pending_sequencer` assertion on/off：均 PASS；
- assertion-on module aggregate：`113/113 PASS`，结果目录
  `evidence/module-aggregate-assert-on/`。

reviewer 指出的 BNE “competing clear”注释已修正；该注释改动不改变 RTL/TB
语义，但仍重新执行 8-case matrix/replay、V9O assertion on/off 与 module
aggregate，最终结果保持 `8/8`、replay PASS、V9O PASS、`113/113 PASS`。

## 7. 诊断性失败与假绿边界

以下目录只记录假设淘汰过程，不作为 green evidence：

- `evidence/diagnostic-current-assert`
- `evidence/current-correct-resolve-assert`
- `evidence/diagnostic-correct-resolve-v2`
- `evidence/current-nonkill-resolve-assert`

它们证明 ordinary drain/non-kill resolve 候选根在当前 product sequence 不成立。
最终 positive/mutation 证据只取：

- `evidence/stop-hold-matrix/summary.json`
- `evidence/replay-stability.json`
- `evidence/v9o-assert-on/`
- `evidence/v9o-assert-off/`
- `evidence/stop-sequencer-assert-on/`
- `evidence/stop-sequencer-assert-off/`

## 8. 接口、PPA 与系统边界

- production `OooStopPendingSequencer.v` 与 `OooFrontendRunGate.v` 未修改；
- 所有 negative RTL 只在隔离 `tmp/.../stop-hold-matrix/rtl/` 物化；
- 每个 case 保留 source diff/SHA、compile command、return code、raw log 与
  elaborated image receipt；
- 当前 design ID：
  `sha256:04c5458ff274b7b30e0629fc20ccef4ffa958dee3b80595ee4b46faf17a73897`；
- 本轮不做综合/STA/PPA promotion。drop-stop-hold 的 bounded survival 只说明
  当前 sequence 存在 successor contract，不能作为删除 production hold 的依据；
- 不运行 A3/full-system，原 A3 FAIL 与 checker-replay PASS 证据均不篡改。

## 9. 实现者结论

当前证据支持：

1. 原单臂/drain 因果假设被反证；
2. current owner-state + owner-to-busy 双合同在 product topology 下闭合；
3. compile-success historical-pre-T3U root-cone equivalent 在 assertion on/off
   下均被动态拒绝；
4. module aggregate 为 `113/113 PASS`；
5. 该 ledger 项具备 bounded VD3 证据，但不具备 VD4、exact-history 或 PPA
   promotion 证据。

该结论不关闭 formal、full-system、architecture-stable 或 PPA 范围。

## 10. 独立审查与 ledger

独立 reviewer 合同：

- JSON：
  `subagent-contracts/hist-qh-stop-hold-final-review-v1.json`
- SHA-256：
  `f585e77a3b99d950897d91c527f1c542cb5008445c0eaf26ad1ebce9ca693988`
- verdict：
  `PASS（仅 bounded VD3）`
- 报告：
  `independent-review.md`

reviewer 逐项核对了 owner birth、sequencer priority、RunGate
orphan/busy/run、DrainGate ROB-empty、TB raw scoreboard、source diff、
compile receipt、assertion on/off、case log hash 与 replay identity，未发现
否定 bounded VD3 的反例。其 residual GAP 为：

- combined version 是 current-topology root-cone equivalent，不是历史提交
  的逐字节 checkout；
- `successor_packet_cycles=0` 阻止 hold-only survival 外推为删除资格；
- `113/113` 不提升 VD4，不替代 formal/full-system/综合/STA/PPA。

ledger 已更新为：

```text
VD0=0 VD1=0 VD2=0 VD3=3 VD4=2
selected_id=NONE status=PASS
architecture_freeze=ELIGIBLE_FOR_REVIEW
ppa=UNQUALIFIED promotion_eligible=false
```

`historical_defect_backfill.py --require-clear` PASS，ledger 定向单测 `4/4
PASS`。共享 `test_arch_stable_freeze` 仍暴露三个本轮范围外的
`CONTROL-EVENT-G1/V9R` source-hash stale 失败；没有刷新或掩盖这些独立证据，
所以 full-core `ARCH_STABLE` 继续为 GAP。

## 11. 可发现、可执行与 DB-first 收尾

- task-specific e2e：
  `.github/task-runs/2026-07-29-rv64-queue-head-stop-owner-historical/`
  为 `npc-dev completed 5/5`，7 个 evidence asset 已索引；
- scoped strict guard：
  本轮 20 条精确路径只要求 `npc-dev`，结果 PASS；
- 本 task-run 的 raw evidence index：
  `285` 个 asset、`evidence-index.md` 已写入 stored index；
- `.github/memory/project-status.md` 与
  `.github/memory/modules/npc.md` 均按 DB-first load/materialize
  → append → `update-stored` → snapshot 发布，写回字节数均增长；
- `audit-db-first` 中本轮两份 memory 已无 missing/mismatch；全局 rc=1 只剩
  8 个既有历史 task-run `missing_backup`，不冒充本轮 PASS。

## 12. 最终范围

本子项 `HIST-SER-QH-STOP-HOLD-DROP` 完成 bounded VD3；长期 RV64 双发射
OoO 架构/PPA goal 继续 active。production core RTL 与 design ID 未变，A3
完整重跑触发条件未成立，A3 原始 FAIL 与独立 checker-replay PASS 均保持原样。
