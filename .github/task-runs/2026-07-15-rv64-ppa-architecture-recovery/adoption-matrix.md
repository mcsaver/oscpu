# Global DSE 元策略采纳矩阵

> 本文件是 `design-inputs/global-dse-meta-strategy-input.txt` 的派生物，不能替代原文。
> 原文 SHA-256：
> `9729C31ED3773AE233AA88C9CA908728C0023C6F47225F2FED7614A34A418A24`。
> 裁决状态只允许 `adopt`、`partial`、`defer`、`not-applicable`；“已有文字”不等于
> “已有机器自动化”。

## 第 1～8 节

| 原文项 | 原始原则 | 当前已有机制 | 缺口 | 裁决 | 实施文件 | 验证证据 |
| --- | --- | --- | --- | --- | --- | --- |
| 第1节：完整配置 | 中间动作不按即时 PPA 淘汰；完整配置才给终局裁决，可用面向终局潜力的 shaping | `implementation_correctness_checkpoints` 已与 promotion 分离；新 checker 已机器区分 `intermediate_checkpoint/complete_design_point`，并强制中间点三轴 `unqualified/null` | 无代理终局潜力模型；当前还没有完整设计点运行证据 | `partial` | 伴随策略 §1、§3、§8；`dse-archive/check_archive.py`、design-point schema | archive 单测 12/12；S1 point `3440827d...abb19.json` 只进入 development/high-uncertainty，checker PASS |
| 第2节：多目标 Pareto | 不过早压成固定权重；硬约束先过滤；维护 Pareto front/hypervolume | v2 合同先 hard gates 后 Pareto；新 registry 持久化 design points，checker 先 gates/worst-workload 再算 qualified 三轴 front，scalar 只允许同一 front | 尚无 HV/contribution；当前 seed 为空且 Power/total area 未 qualified，formal front 必须为空 | `partial` | 伴随策略 §2～§3；`dse-archive/{registry.json,check_archive.py}` | snapshot/design-id、unqualified-power、intermediate-in-front 负例均被 12/12 单测杀死；production registry PASS |
| 第3节：多候选保留 | 同时保留 Pareto、高不确定度和多样性候选，避免单点覆盖种群 | registry 已固定 feasible/development/high-uncertainty/diversity 四池；S1 同时登记 development/high-uncertainty，证据不确定度和降低实验为必填 | 尚无 crowding/distance 数值、自动配额生成器或多个完整候选 | `partial` | 伴随策略 §2、§7、§10；`dse-archive/registry.json`、checker pools 规则 | S1 point/ledger 已内容寻址并通过 production checker；pool unknown/member-field 规则由 checker fail closed |
| 第4节：全局—局部—全局 | 先全局预算，再子系统条件优化，周期性联合解冻强耦合参数 | tournament 规定同 seed 三支；ledger 已计数完整点并在 `K=4` 后强制下一 event 为至少两父点的 `global_thaw_opened` | 无预算向量/联合候选生成器；seed 仍为 `null`，尚无真实 thaw 运行 | `partial` | 伴随策略 §4～§5；`dse-archive/check_archive.py` ledger/thaw | “四点后未 thaw 继续记录”负例被单测拒绝；当前计数 0、`thaw_due=false` |
| 第5节：交互建模 | 用联合扰动/交互增益识别强耦合参数；attention/SHAP 只作启发 | 当前候选由已知关键锥和架构块人工分组；P0 A/B/AB 曾做分离再组合思路 | 没有交互矩阵、单项/联合四点实验协议或校准模型 | `partial` | 伴随策略 §5；未来 thaw evidence/interaction matrix | `r4-p0-timing-recovery-contract.md:26-34,:78-81`；tournament 三个候选主锥 |
| 第6节：RL 防坍塌 | preference-conditioned policy、central critic/actors、探索下限、分层 replay buffer | 当前流程没有 RL、policy、critic 或 replay buffer | 全部 RL 基础设施与训练/验证协议均不存在 | `defer` | 伴随策略 §11；原文永久保留 | 仓内 PPA 流程为确定性 checker/front/synthesis/STA；不得把人工分支冒充 RL |
| 第7节：跨 workload 稳健 | workload-aware 目标，同时约束最差 workload/CVaR，避免 benchmark-specific 最优 | CoreMark/Dhrystone 各自 ratio `>=0.995`、retired equality；archive checker 重算最差 workload，并强制 performance axis 等于该最小值 | 只有两个冻结性能 workload；无 held-out 集、CVaR/尾部统计和 workload feature model | `partial` | 伴随策略 §6；policy benchmarks；`dse-archive/check_archive.py` | “平均值掩盖最差项”负例被单测拒绝；当前 S1 intermediate 不允许填任何 performance 数字 |
| 第8节：完整闭环 | 初始覆盖采样、真实评估、代理 ensemble、Pareto archive、批量主动采样、多保真、global thaw、held-out 最终验证 | 已有真实 cycle/fresh synth/STA/hard gates；现有 archive 新增持久 registry、不可变 bundle、test inventory 实算、ledger、四池、worst-case 和 thaw | 无参数化合法空间、Sobol/LHS、surrogate ensemble、主动采样、校准多保真和 held-out workload；102/103 漂移仍阻止 formal front | `partial` | 伴随策略 §3、§7～§10；`dse-archive/` | S1 138-file bundle逐 member 对 manifest复核；production checker PASS；12/12 archive tests；formal seed/front仍为空 |

## “最优先修改的五项”

| 原文项 | 原始原则 | 当前已有机制 | 缺口 | 裁决 | 实施文件 | 验证证据 |
| --- | --- | --- | --- | --- | --- | --- |
| 优先1：Pareto archive | 从单一最优点改成持久 Pareto archive | 持久 registry/四池/qualified front 已实现；完整点必须 `design_id=sha256:<bundle>`；S1 bundle与point已登记 | 无 HV/contribution且没有 architecture-feasible complete point；formal front仍空 | `partial` | 伴随策略 §2、§3、§10；`dse-archive/` | production checker PASS；snapshot伪绑定、Power未资格化和中间点进front负例均被杀死 |
| 优先2：完整配置终局裁决 | 从逐步即时奖励改成完整配置终局奖励或 HV 增益 | lifecycle、完整点 snapshot/test-inventory/hard-gate 顺序已机器编码；S1 三轴强制 null | 无 HV 工具，尚无完整设计点运行 | `partial` | 伴随策略 §1、§3、§8；design-point schema/checker | S1 intermediate point checker PASS；complete 缺 snapshot负例 FAIL |
| 优先3：周期性全局解冻 | 每 K 轮解冻，允许跨模块联合 mutation | ledger 已机器实现 `K=4`、至少两父点、固定耦合块与 completion definition | 无自动联合候选生成器；须等待 seed 与四个完整点产生首份运行证据 | `partial` | 伴随策略 §5；archive ledger/checker | K=4 负例 PASS（按预期被拒）；production `completed_points_since_last_thaw=0` |
| 优先4：workload-aware worst case | 加入 workload-aware 与 worst-case/CVaR | 每 benchmark floor/retired equality与 archive 最差项重算均 fail closed | 无 CVaR、尾部/held-out workload；两项样本不足以作统计声明 | `partial` | 伴随策略 §6；policy/front/archive checker | archive “平均掩盖最差项”负例与既有 PPA 回归均 PASS |
| 优先5：重启/不确定度/多样性 | 随机重启、uncertainty exploration、设计与目标空间多样性 | high-uncertainty/diversity 池及必填 reduction experiment/signature/distance basis 已机器化；S1 已登记 evidence uncertainty | 无 calibrated uncertainty、distance/crowding 数值、配额生成器与自动重启 | `partial` | 伴随策略 §2、§7、§10；archive registry/checker | production checker验证 S1 uncertainty 字段；尚不得声称模型 uncertainty |

## 当前阶段裁决

- `adopt` 不用于伪装未完成自动化；当前 13 项中，立即生效的原则已写入伴随策略，但只要机器
  registry/generator/checker 或所需证据仍缺失，就保持 `partial`。
- RL 第6节保留为 `defer`，不是删除；未来若引入 RL，必须重新逐项评审 preference、critic、
  exploration 和 replay-buffer 四类机制。
- 当前 S1 typed ABI 已以 content-addressed bundle/point/ledger 登记在 development 与
  high-uncertainty；后续 S1-ID/S2 继续走同一 development path。九项 DI/OOO 未全绿前，
  任何点都不得进入 feasible Pareto/promotion。
- required module set 当前为 104，而历史 hash-bound 合同/policy 仍落后于 live inventory。typed
  classifier 与 Q1 epoch-owner 均已在 fresh development regression 中执行；在合同/provenance/test
  inventory 原子更新前，该漂移仍是 promotion blocker，不能用 102、103 或 104 的单一 PASS 数字掩盖。
- 新 archive 已强制完整点绑定 content-addressed source bundle，且 complete `design_id` 必须等于
  bundle SHA；S1 bundle 已逐 member 对 source-set manifest 复核。但现有 normative
  `front.py/check.py` 尚未改成从该 bundle 恢复执行，因此 formal promotion 仍不得借 companion
  registry 绕过原 checker。
- S2-Q0 bridge registered-fact idle 继续按第1节作为 intermediate checkpoint：正例、mutation
  反例和 source-bound wrapper 已闭合，但 epoch owner、完整 context barrier、第二 memory
  datapath 与 200 MHz 均未闭合，因此只保留在 development branch，不进入 feasible Pareto
  archive 或任何 champion 裁决。
- S2-Q1 epoch owner 已完成 source-catalog adoption：canonical exact-oracle runner 与正式
  104-test module aggregate GREEN；但 leaf 尚未 live 实例化，所有 PPA 轴仍为
  unqualified/null，继续只属于 development/high-uncertainty，不进入 feasible/front/champion。
- S2-Q2 已形成 `CAPTURE→SQUASH→WAIT_QUIET→GRANT` 的 mem0-only contract/checker hardening
  checkpoint，尚不称 implementation-ready/final interface freeze。v7 已冻结 identity-mismatch
  owner/CSR 原子 abort、generation-matched sticky IFU ack、独立 FENCE.I store+IFU serialization、
  deferred writer、active-source 预处理、精确 packed range、concrete payload/cause 宏值、registered
  quiet/memory ack、真实 IFU leaf、grant 原子 consumer、valid epoch-capture next-state、全 writer 唯一性、
  SQ fill epoch exact mux/MIQ provenance 与全实例名；release/`OOO_ASSERT` 双变体、elaborated generate、
  FENCE.I/MIQ/true memory-leaf producer、exact payload、guarded epoch/ROB/irrevocable storage 和
  set-dominant squash completion、reset/non-reset writer arm、exact positive reset/clock event、完整 ancestor
  guard path、module lexical declaration/source binding、唯一 module-scope continuous driver、internal any-generate、
  任意深度 concatenated/indexed LHS 与 escaped/imported/package/hierarchical/system task actual 也已 fail-closed；
  新增 exact `rst:false` non-reset path、statement event/delay/wait、embedded call actual、`always @ signal`
  procedural span、unknown child/primitive output driver、header/module-scope-only port direction/width、required
  port critical-symbol audit、canonical `clk/rst` input ownership，以及 runner 28-path pre/post source snapshot。
  当前 checker 自测 162/162，对 live RTL release/`OOO_ASSERT` 各列出 931 项、聚合
  1862 项 contract/baseline/RED-digest 锁定的预期 RED；它只形成
  下一实现切片的可审计缺口清单，
  不构成 architecture point。lane1 boundary、younger-SQ deadlock、IFU stale fill/old-generation ack、
  FENCE.I early-retire、same-edge ingress、dynamic epoch/wrap 与 atomic apply/abort 的 directed/mutation 未绿前，仍不得进入
  feasible/development complete point 或产生任何 PPA 数字。
