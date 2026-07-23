# RV64 v8l global ProducerId no-live-reuse task report

## Result

- `v8l/global_no_live_reuse`: **scoped GREEN**，仅绑定当前 manifest、checker、默认 RTL 配置、
  `PRODUCER_GEN_W=1` focused 配置和 focused source SHA 清单。
- field-level holder census：15 个 direct full-P Q、1 个显式组合 full-P reg 豁免、5 个
  ProducerId packed stage、12 个 token Q、1 个 generation authority，精确集合校验通过。
- architecture inventory：**OVERALL RED**；manifest 仍为
  `instance_graph_complete=false, semantic_complete=false`。
- PPA：`promotion_eligible=false`，本轮未运行或发布 fresh synthesis/STA/power/Pareto 结论。
- 长期 `/goal`：继续 active；本报告不把局部 GREEN 传播为父目标完成。

## Implemented contract

1. `OooIntIssueQueue` 从 edge-old `valid_q/producer_id_q` 生成 Q-only full-P mask；该核的 source
   dependency 仍是 preg + sticky-ready，不存在第二个 full-P source tag。
2. `OooDispatchBackend` 将 IntIQ mask 与外部 holder mask 合并；lane0、mandatory pair 和 optional
   lane1 的 birth guard 全部查询同一个 exported alloc full-P 和 complete mask。
3. `OooIntBackend` 把 mem-res、EX0、EX1、registered branch packet 纳入 direct transient union；
   tracker、MulDiv、CLMUL、FP 与 pending CSR 保持各自 Q-only contributor。MIQ/buffer/bridge/
   terminal/SQ token 由 tracker live/map assertion 承重，SQ raw full-P 另作独立 scan。
4. Memory IntIQ capture 与 pop 同源受 `tracker_alloc_ready` 控制；credit=0 时旧 IntIQ holder 保持，
   credit返回后 reservation 与 token 在同一沿出生，关闭 handoff 空窗。
5. `OooStoreQueue` 增加只读 owner-token snoop 输出，仅供独立 assertion reference；不进入功能授权。
6. 永久 checker/manifest/spec 已接入 `make check-producer-holder-census`，且该 target 已成为
   `make check-contract` 的前置门。
7. FP IQ/issue/arith/exec1/long/FIFO、MulDiv/CLMUL、memory tracker/MIQ/bridge/terminal 等 holder
   增加本地 `valid => P/token known` raw-state 断言；顶层 union/subset 继续作为独立第二层检查，
   避免 X 索引把覆盖关系空洞化。

## Implementer evidence

- focused runner：assert/release 共 8/8 baseline PASS；包括 IntIQ/tracker/SQ、`GEN_W=1`
  dispatch wrap、v8l transient/backpressure 和 legacy v8g cancel/recovery。
- finite wrap：production allocate→IQ→WB→commit 穿越 32 个 P；held P 回绕时在 edge-old death
  cycle 阻塞，下一 cycle 才开放。
- runtime mutation：9/9 均成功生成 vvp 后被独立后果捕获；没有把 compile failure 计为 mutation
  kill。canonical source pre/post SHA 清单一致。
- checker unit：9/9；新增 full-P Q、非 `_q` exact-width full-P reg、packed stage/token Q、删除
  IntIQ union、raw-index guard、assertion shadow 与 manifest 自晋级均有正反例。
- fresh regression：v8d..v8l focused 8/8；`OOO_ASSERT` module aggregate 106/106。
- static：RTL style PASS；census PASS；contract `400>=89` PASS；full lint 保持继承签名 rc=2/
  115 warnings，未冒充 lint PASS；architecture checker self-test 15/15，但真实 inventory RED。
- workflow e2e：最终 fresh `npc-dev`、`agent-system` 与 `github-index` 均 completed；首个
  `npc-dev` run 的五个工程节点虽全 PASS，但非语义化 slug 令 bounded brief 无独立命中，故整轮
  保持 blocked。该失败包与语义化重跑证据均保留。

## Reviewer evidence and correction

- 合同 reviewer 首轮指出 IntIQ source-P、memory handoff、packed holder、alloc-P 同源与独立 reference
  风险；核对实际 RTL 后明确 source dependency 无 full-P，并把其余风险转成合同、assertion、TB、
  checker 和 mutation。修订合同 verdict=pass，只释放实现门。
- 实现 reviewer 使用 SHA-256 绑定的 no-tools 合同，实际 tools/shell/filesystem/network/write 全为
  none，只消费提示内自包含本地 RTL 证据。首份 `pass` 使用旧键名且 `claim_boundary` 类型错误，故仍
  记 `review_pending`；原始失配 JSON保留。第二份严格符合 schema 后才归档 verdict=pass。
- reviewer 允许的声明仅为当前绑定证据下 scoped GREEN；明确禁止外推 instance/semantic complete、
  architecture GREEN、其它配置 GREEN 或 PPA GREEN。

## False-green found during this run

Icarus 对 procedural variable `force/release` 会在 release 后保留被 force 的值，直到下一次过程赋值。
最初四个 transient 探针复用同一 P，导致删除 EX1 union 的 mutation 被前一 holder 遮蔽。修复为四个
互异 full-P，每次 release 后跨 reset 并确认 complete mask 清零；此后删 EX1 mutation 被准确击杀。
该规则已写入 retained known-issues 与 agent workflow memory。

静态门复跑还发现 `check-contract.log` 已为 400 条断言，而 `summary.md` 仍硬编码旧值 391。门结果
本身正确，但摘要已陈旧；`run-static-gates.sh` 现从本轮 contract 日志和 census manifest 动态提取
计数，解析不到唯一值或发生回退即失败，避免派生摘要与原始证据分叉。

首个 `npc-dev` e2e 又暴露 task slug 会被拆成 bounded brief 的检索词；只写 `global-producer` 无法
命中 retained memory 中的 `ProducerId holder census`。失败 run 未改写，改用领域词 slug 后完成。
因此 slug 也按可执行召回合同维护，不再只作为展示名称。

## Residual boundary

- static checker 只声称 field-level completeness；未来新增 full-P/token/skid/replay/redirect holder 时
  必须先 RED、扩 manifest，并重跑动态证据。
- no-tools reviewer 未独立读取 RTL/日志或复算 SHA；其结论必须与父 agent 的原始 evidence 并列。
- official/Linux、完整形式证明、fresh synthesis/STA/power 与 architecture 其它 hard gate 未由本轮闭合。
