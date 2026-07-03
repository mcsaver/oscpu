# design/arch/history —— 已归档架构过程文档

> 与 `../../specs/history/` 同规约：存放**已完成使命**的一次性评估/专项设计文档（`git mv` 保留历史）。
> 归档不等于删除，但**不再描述当前 RTL**；现状以 `../rtl-ground-truth-2026-07-03.md` 与
> `../ooo-core-architecture.md` 为准。

## 归档清单（2026-07-03，全 RTL 重读审计）

| 文件 | 类别 | 归档原因 | 现状参考 |
| --- | --- | --- | --- |
| `EVAL-REPORT-2026-06-28.md` | SUPERSEDED | 时点评估快照；其"暂缓"决策（LSQ/前递/分支预测增强）均已被后续落地取代 | `../rtl-ground-truth-2026-07-03.md` + `.github/memory/project-status.md` |
| `b2-branch-spec-redirect.md` | SUPERSEDED | B2 专项设计（方案评审+负结论记录）；分支/JALR 迁域 A + ROB-walk + 显式 mispredict 已以 F2 形态落地。残余（pending 死壳删除、RedirectArbiter 接线）归宪法 §8.3 | 宪法 §8.3 + 真相基线 §2.4/§4 |
| `mem-store-decouple.md` | SUPERSEDED | B1 专项设计,机制已实现验证且至今在役（bpend/store_decouple_w）；桥现行 FSM 语义由 `specs/ooo-mem-axi-bridge-fsm.md` 承载 | `../../specs/ooo-mem-axi-bridge-fsm.md` |
