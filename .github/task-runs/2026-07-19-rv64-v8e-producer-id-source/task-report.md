# RV64 v8e ProducerId allocation source 任务报告

## 结论

本轮只签收 `PRODUCER_ID_ALLOCATION_SHADOW=LOCAL_GREEN`：canonical `OooRob` 已有参数化
4+4 ProducerId 编码真源，且 dispatch/head/commit/walk 七个 ROB 自有载体同源。它不是 active
ProducerId；全局无活跃复用、全 holder 传播和 exact completion authorization 继续为 RED。

## 实现边界

- `define.v` 新增独立 `OOO_PRODUCER_GEN_W=4` 与 `OOO_PRODUCER_ID_W`，不复用 context/MMU epoch。
- `OooRob` 新增 16x4 per-slot generation。只有 accepted allocation 推进；普通 flush、commit、
  selective recovery 和 WB 均保持；硬复位全 1，首个候选为 generation0。
- ProducerId 固定 `{generation,rob_idx}`；raw idx 继续负责寻址与环形年龄。
- 双 lane dispatch candidate、head、双 commit、双 walk 均从同一槽 generation 产生。
- 独立审查发现 reset/flush 拍 ready 可宣告伪接受；现已在 `OooRob` leaf 与
  `OooDispatchBackend` parent 同源 fail-closed。功能拍 ready/fire 不变。
- `OooDispatchBackend` 当前只连接并终止这些 shadow 观察口，不向 IQ/EX/WB/PRF/Busy/FPR
  传播；综合可能删除未消费 shadow，故本轮没有 PPA 改善或中性声明。

## 可重放证据

| gate | 结果 | 证据 |
|---|---|---|
| leaf + dispatch release/assert source | PASS | `evidence/source/{release,ooo_assert,dispatch_release,dispatch_ooo_assert}.*.log` |
| compile-success semantic mutations | 13/13 被测试检出 | `evidence/source/mutation-summary.log` |
| reset/flush presented-valid | parent + leaf PASS | source/dispatch TB 精确 marker |
| full stall | candidate 逐沿稳定、valid-not-fire 不推进 | source TB + mutation |
| commit + natural ring + real branch walk | tail 15 双 lane 到 slot15/slot0；old@0 被 walk 流水取消；new@0 generation 精确递增 | source TB |
| finite `GEN_W=1` | full ID 回绕且 allocation 仍 ready，EXPECTED RED | `evidence/source/finite-wrap.sim.log` |
| P0 raw-index late-old-WB | release/assert 见证 + normal-new-WB 正控，EXPECTED RED | `evidence/source/raw-index-*` |
| focused integration | 6/6 PASS | `evidence/focused/summary.txt` |
| current module aggregate | 104/104 PASS | `evidence/module-full/summary.txt` |
| RTL style / contract / diff | PASS / PASS (`298>=89`) / PASS | `evidence/{rtl-style,contract,diff-check}.*` |
| strict Verilator lint | RED，115 warnings；与 v8a baseline normalized signature byte-match | `evidence/lint{.log,.normalized,-status.txt}` |

`evidence/source/complete.marker` 对 source pre/post manifest、release/assert logs、13 个 mutation
的 mutator/compile/sim logs、finite-wrap、复制后的 P0 witness/positive/source manifest 和 summary
共 59 项做 SHA-256 承重；最后一行固定本地 GREEN / 全局 RED 边界。审计时必须同时验证
该 marker 与嵌套的 `sources.post.sha256`，不能只验证外层 manifest。

根目录 `complete.marker` 另对最终报告/dispatch/合同/census、runner/mutator、source nested
marker、focused/module/style/contract/diff/lint/strict-guard 证据，以及最终三 profile 的
completion marker/publication 共 22 项做 SHA-256 绑定；它不替代每个嵌套 marker 自身的校验。

## 实现者与审查者切换

- 实现者：完成 4+4 编码源、七载体、reset/flush 握手修正、正向/回绕/变异用例以及 104 项回归。
- 审查者首轮：拒绝最初签收，指出 parent/leaf 伪接受、真实 walk/reuse 覆盖不足、runner
  依赖与 raw witness 不自包含、canonical WB pdest 悬空。
- 修正：ready 双层门控；补 reset/flush presented-valid、逐沿 stall、commit 后自然 15→0、真实
  walk squash old@0 后 new@0；新增 commit/recovery/parent-ready mutations；连接并驱动 WB pdest；
  runner 纳入 20 个直接/复用依赖并复制验证 raw witness/positive，marker 精确一次且拒绝失败标记。
- 最终裁决：若独立复核仍有阻断项，本报告必须降级；无阻断时只允许本地 source GREEN。

独立复核最终裁决为 scoped blocker=0。复核同时限定：focused 6/6 与 module 104/104 是本轮旁证，
不在 source completion manifest 内，不能把它们越级解释为 active identity 或完整功能签核。
复核提出的 dispatch TB 五个 dangling inputs、报告 55/59 计数差异与双层 manifest audit 均已修正；
`evidence/source/manifest-audit.log` 显示外层 59 项和内层 20 个 source 均校验通过。

## AI 环境实战回路

- 首个 task-specific `npc-dev` slug `rv64-v8e-producer-id-source-e2e` 的五个业务节点均 PASS，
  但 bounded recall 因关键词没有独立 primary focus 而 fail-closed；该 blocked run 保留。
- 三份 retained memory 更新并 `update-stored` 后，`brief rv64 producer identity generation
  --profile npc-dev --focus-scope non-history` 为 complete、2001/2400。
- 使用由当前 non-history memory 支持的 slug `rv64-producer-identity-generation` 重跑，5/5 nodes
  completed。规则修正：task slug 必须由当前可召回事实支持，不能仅由未索引 task-run 自证。
- 最终 strict guard 先因当前 changed paths 的语义完成时间晚于旧证据而 fail-closed；完成最终
  retained-memory 同步后，新跑 `agent-system/agent-rtl-3` 与
  `npc-dev/rv64-producer-identity-generation-3`，两者均 completed。
  strict guard 最终以这两份新证据和仍新鲜的 `github-index/slug-recall-3` 对三个必需 profile
  全部 PASS。
- 本 task-run 的 185 个普通 evidence asset 已写入 `evidence-index.md`；顶层 marker 作为闭包
  元数据单列，不计入普通资产。stored snapshot、doctor
  (`blocking_drift=0`)、DB-first audit 与 Markdown coverage (`live_evidence=0`) 均 PASS。

## 明确非声明

不声明 generation-safe full identity、global no-live-reuse、WB/PRF/Busy/IQ/FPR/public completion
授权、全 carrier 传播、reset-domain late response 安全、Q1/CSR、双 memory、Linux、完整功能门、
综合/STA/power、200 MHz、Area/Power/PPA 或 Pareto promotion。
