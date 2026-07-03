# design/specs/history —— 已归档规范

> 这里存放**已过时/已完成使命**的 spec，从 `design/specs/` 移入（`git mv`，保留历史）。
> 归档不等于删除：它们仍是有用的历史记录，但**不再描述当前 RTL**，不应作为现状参考。
> 归档依据：2026-06-29 对全部 ~78 份 spec 的逐份审计（CURRENT/OUTDATED/ORPHAN/SUPERSEDED），
> task-run `.github/task-runs/2026-06-29-rv64-ooo-core-architecture-constitution/`（spec 三角分类）。

## 归档清单（2026-06-29）

| 文件 | 类别 | 归档原因 | 现状参考 |
| --- | --- | --- | --- |
| `ooo-fp-pending-exec-decompose.md` | SUPERSEDED | 一次性拆分**计划**文档；战线已收口（OooFpPendingExec 已降到薄壳 + 7 个 owner gate 均落地） | `ooo-fp-pending-exec.md` + 各 `OooFp*Gate.v` |
| `ooo-int-backend-decompose.md` | SUPERSEDED | 一次性拆分**计划**文档；已执行（OooBitmanipGate/OooAmoGate 已抽出，OooIntBackend 已收口） | `OooIntBackend.v` 注释 / 各 gate |
| `ooo-pending-dispatch-facts-bus.md` | SUPERSEDED | 一次性**迁移步骤**文档；slot facts bus 已成为 arbiter 唯一事实入口，旧散线端口已删 | `ooo-pending-dispatch-arbiter.md` |
| `ooo-slot-facts-bus.md` | SUPERSEDED | 一次性**迁移步骤**文档；描述的父模块 `OooAluFetchCore` 已不存在；facts bus 已被多模块采用 | `OooSlotFacts.v` / 消费者 spec |
| `ooo-pending-lane1-ret-dead-cleanup.md` | SUPERSEDED | 一次性 **dead-state 清理**文档；引用的 `OooAluFetchCore` 已不存在，`pending_lane1_ret` 标识符全核已无 | `ooo-synthetic-lane1-ret-sequencer.md` |
| `ooo-fp-fma-fused-topology.md` | OUTDATED→被取代 | 描述 FMA 为**单拍纯组合**（pre-pipelining）；已被多周期流水化取代（OooFpArithGate 现有 clk/start/done + 流水寄存器） | `ooo-fp-arith-pipeline.md` |

## 归档清单（2026-07-03，全 RTL 重读审计）

> 依据：2026-07-03 无文档依赖的全 RTL 重读（9 路审计+矛盾裁定+追问验证，真相基线
> `../../arch/rtl-ground-truth-2026-07-03.md`，task-run
> `.github/task-runs/2026-07-03-rv64-rtl-reread-audit/`）后对全部 85 份文档的逐份审计
> （6 CURRENT / 67 DRIFT_FIXED / 12 归档，另 3 份 arch 过程文档归 `../../arch/history/`）。

| 文件 | 类别 | 归档原因 | 现状参考 |
| --- | --- | --- | --- |
| `ooo-fp-pending-exec.md` | ORPHAN | 描述的 `OooFpPendingExec` 已随 pending-FP 壳拆除物理删除（2026-07-02） | `vsrc/execute/OooFpBackend.v`（FP 真乱序簇） |
| `ooo-pending-fp-sequencer.md` | ORPHAN | 同上，`OooPendingFpSequencer` 已删除 | 同上 |
| `ooo-fp-cluster-implementation-plan.md` | SUPERSEDED | B-FP 一次性实施方案，已全部落地（自带 §8/§9/§10 落地实录；E2/E3 消除） | FP 簇 RTL + 真相基线 §2.1 + 宪法 §8.3 |
| `ooo-fp-arith-pipeline.md` | SUPERSEDED | 流水化改造记录：切级成果（FADD3/FMUL3/FMA5）存活，但 start/done 控制接口已被 5 级 meta 链自流水取代、串行前提已消失 | `vsrc/execute/OooFpArithGate.v` |
| `ooo-lsq-implementation-plan.md` | SUPERSEDED | B-LSQ 一次性实施方案，主体（SQ4+probe/drain+前递、MIQ、dcache 8B line）已落地；未做件（LQ/replay/MSHR/多 outstanding）登记于宪法 §8.3 与真相基线 §3.3 | 真相基线 §2.3/§3.3 |
| `ooo-f2-per-packet-pred-implementation-plan.md` | SUPERSEDED | F2 真分支预测一次性实施方案，已整体落地为生产配置（OOO_ROB_WALK_MODE=1） | 真相基线 §2.4 + known-issues #110 |
| `ooo-frontend.md` | SUPERSEDED | 一次性 wrapper 抽取记录（非现状 spec）；实例普查/owner 表已大幅漂移且多成员判死 | `vsrc/frontend/OooFrontend.v` + report-0 |
| `ooo-structure-params.md` | SUPERSEDED | 一次性参数化重构切片；传递链引用已消失的 `OooAluFetchCore` | `vsrc/include/define.v` + 真相基线 §1 参数表 |
| `ooo-memory-request-gate.md` | SUPERSEDED | 抽取切片 spec；核心机制（pending-FP 直写旁路 mux）已拆，现模块仅纯透传+2 OR | `vsrc/memory/OooMemoryRequestGate.v` |

## 未归档但已知漂移（历史注记）

2026-06-29 标注的 4 份 ⚠ 待校正 spec 已于 2026-07-03 处置完毕：
`ooo-fp-arith-pipeline.md`/`ooo-fp-pending-exec.md`/`ooo-pending-fp-sequencer.md` 归档（见上表），
`ooo-branch-prefetch-request-gate.md` 已加死硅状态注记并校正（仍在 `design/specs/`）。
