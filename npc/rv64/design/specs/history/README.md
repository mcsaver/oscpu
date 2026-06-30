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

## 未归档但已知漂移（仍在 `design/specs/`，标了 ⚠ 待校正）

以下 spec 对应的模块**仍在用**，只是接口/细节随近期 FP 流水化等小改动漂移——归档会让活模块失去 spec，
故**保留并标注**，待 B-FP（FP 执行簇重写）或专项校正时更新：
`ooo-fp-arith-pipeline.md`、`ooo-fp-pending-exec.md`、`ooo-pending-fp-sequencer.md`、`ooo-branch-prefetch-request-gate.md`。
