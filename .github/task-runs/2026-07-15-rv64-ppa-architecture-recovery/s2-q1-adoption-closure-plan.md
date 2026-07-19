# S2-Q1 adoption closure record

> 日期：2026-07-18
>
> 状态：`source-catalog GREEN / live integration RED / parent RED`。

## 1. 历史 RED 与本轮关闭

2026-07-17 的 fail-closed checker 曾真实返回 `unresolved=30`：旧 canonical saturating mutation
生成非法字面量、v2/candidate 并存、helper oracle 不精确、release lint 有两个 unused、正式 PASS
缺失，且 filelist/Makefile/spec 未登记。该 RED 保存在
`evidence/r4-s2-q1-mmu-epoch-owner-adoption-red/`，不是被覆盖或改写成 GREEN。

2026-07-18 `apply_patch` helper 恢复后，原子补丁完成：

1. RTL 显式 timescale，生产 FSM 复用 `full_quiet_w`，assert-only legal-state wire 进入
   `OOO_ASSERT` scope；release/assert `-Wall` 均无错误。
2. TB helper 严格检查 pre-increment epoch，末尾输出共享精确 PASS。
3. leaf 进入 `RTL_CORE_SRCS`、正式 `TESTS/TB_SRCS` 与 specs index。
4. 只保留 executable canonical runner；4 negative 与 7 mutation 均绑定完整唯一 oracle，
   source/tool hashes 与 lint/style/Yosys/adoption 日志进入同一 evidence。
5. `check-s2-q1-adoption.py` 从 30 项 RED 转唯一 PASS。

## 2. GREEN 证据

- focused/adoption：`evidence/r4-s2-q1-mmu-epoch-owner-adoption-green/summary.txt`；
  release/assert `2/2`、negative `4/4`、exact mutations `7/7`。
- 正式 target：`module-focused/logs/tb_ooo_mmu_epoch_owner.log` 同时含 focused/shared/result PASS。
- fresh aggregate：`module-all-v2/summary.txt` 为 `104/104 PASS`。
- project gates：`check-rtl-style.log`、`check-contract.log`、`catalog-match.log` 与
  `adoption-check.log` 全 PASS；catalog match 行数为 1。
- source binding：`adoption-sources.sha256`；runner summary 另绑定 RTL/TB/negative/runner 与工具版本。

## 3. 反例与 broad-claim 限制

首次 aggregate 暴露 `tb_ooo_priv_system` typed-response 输入悬空；该问题通过真实 PMA 响应模型与
request→response owner provenance 锁存关闭，未 tie-off assertion。历史 canonical RED 与本轮
adoption GREEN 在 DB 证据索引中必须联合保留，避免单路径重建覆盖。

Q1 仍未实例化到 live core。precommit candidate、effective classifier、capture-only block、
selective squash、full quiet、grant-gated apply/invalidate/LR clear、live epoch、dual memory、
Linux/200 MHz/PPA 均未闭合；不得借 104/104 module aggregate越级。
