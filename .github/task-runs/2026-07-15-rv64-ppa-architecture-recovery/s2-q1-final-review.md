# S2-Q1 final reviewer report

> 日期：2026-07-18
>
> 最终裁决：`source-catalog adoption GREEN / live integration RED / parent architecture goal active`。

## 最终裁决

- P0：无。
- P1：无。canonical runner 已成为唯一 runnable entry；旧 v2/candidate 歧义、非法 saturating mutant、
  module PASS marker、source catalog、release lint 与文档状态均已闭合。
- P2：审查发现 spec 在 manifest 生成后被更新，造成 source binding 漂移；实现者刷新
  `adoption-sources.sha256` 后 9/9 校验通过，P2 已关闭。manifest SHA-256 为
  `b621e47a71cc566d0733f137567ede4b60b267471195aa162536a1caf9757f12`。

## 独立复核证据

- release/assert 正例 2/2 PASS，且 focused 与共享 `[PASS]` marker 各精确一次；
- 4/4 assertion-negative 以完整预期消息、非零 rc 命中；
- 7/7 source mutation 均先证明 source changed、编译成功，再由各自 exact oracle 杀死；
- helper 严格检查 held pre-increment epoch，未保留“只要不等于 expected”弱 oracle；
- release/assert Verilator lint、RTL style、Yosys structural check、adoption checker 全 PASS；
- fresh module aggregate 为 `104/104 PASS`；
- 首轮 aggregate 暴露的 `tb_ooo_priv_system` typed-response/owner 悬空 X 已以真实
  `OooTypedPmaChecker` 和 request provenance latch 修复，断言未绕过；focused 与 aggregate 均 PASS；
- evidence manifest 当前 9/9 OK，checker 当前实跑 PASS。

## 边界与禁止越级

`OooMmuEpochOwner` 在 live `npc/rv64/vsrc` 仍只有定义、没有实例。这个 GREEN 只覆盖 leaf 的
source-catalog adoption 和 fresh module regression，不覆盖 ROB precommit、effective CsrFile
old→next、selective squash、完整 backend/SQ/bridge/IFU quiet、grant-time apply/invalidate/LR clear、
dynamic epoch/wrap、stale response、双 memory、Linux、200 MHz 或 PPA。上述 live integration 继续 RED。
