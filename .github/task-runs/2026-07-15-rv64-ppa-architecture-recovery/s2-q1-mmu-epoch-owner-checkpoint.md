# S2-Q1 `OooMmuEpochOwner` checkpoint

> 日期：2026-07-18
>
> 裁决：`leaf focused + source-catalog adoption GREEN / live integration RED / parent R4-S1-ID RED`。
>
> 本 checkpoint 证明 Q1 叶模块已成为共享 source catalog 与正式 module harness 的可自动发现目标；
> 不证明 live ROB/CsrFile/MMU barrier、双 memory、Linux、200 MHz 或 PPA。

## 1. 实现者交付

- RTL：`npc/rv64/vsrc/memory/OooMmuEpochOwner.v`。
- 规范：`npc/rv64/design/specs/ooo-mmu-epoch-owner.md`。
- 正向 TB：`npc/rv64/testbench/tests/tb_ooo_mmu_epoch_owner.sv`。
- assertion-negative TB：`tb_s2_q1_mmu_epoch_owner_assert_negative.sv`。
- 唯一 canonical runner：`run-s2-q1-mmu-epoch-owner-focused.sh`；旧 v2/candidate 已删除，入口可执行。
- fail-closed catalog gate：`check-s2-q1-adoption.py`。
- 证据：`evidence/r4-s2-q1-mmu-epoch-owner-adoption-green/`。

## 2. 证据

Canonical summary：

```text
release_positive=PASS
assert_positive=PASS
assert_negative=4/4 PASS
source_mutations=7/7 KILLED_BY_EXACT_ORACLE
verilator_release_lint=PASS
verilator_assert_lint=PASS
rtl_style=PASS
yosys_check=PASS
adoption_contract=PASS
rtl_sha256=73450c506bd84afcad24abe6f96e3176dfa1349405f1185eb6f54139a93f86b4
tb_sha256=1b64aff15b5044aa67699b71eaf1a5cc277fd6e17ee500c860c4a4cb159c7a10
negative_tb_sha256=5ff425e9ffa8ee73b76116025c6286e22f272db2b13836fd9ccbf12aba78a6b5
runner_sha256=008b39a6a43a82a35670b3c14afbac25720b69a399b3c08dc75b568a086bd01f
```

- 两个 positive 都要求 focused marker 与共享 `[PASS] tb_ooo_mmu_epoch_owner` 各恰好一次。
- 4 个 negative 均先编译成功，再以非零 rc 命中各自完整且唯一的命名 assertion 行。
- 7 个 mutant 均先确认源码改变、编译成功，再以非零 rc 命中各自唯一完整 directed FAIL；
  编译失败、其他 FAIL 或多 FAIL 都不能计 kill。
- helper 的 pre-increment epoch oracle 为严格 `expected_epoch - 1 mod 4`。
- release/assert Verilator `-Wall`、leaf style、Yosys hierarchy/proc/opt/check 全 PASS。
- adoption checker 从历史 `unresolved=30` RED 转为唯一 PASS；source catalog 精确含 leaf 一次。
- 正式 Q1 target 同时含 focused marker、共享 PASS 与 `[RESULT] PASS`。
- fresh module aggregate：`module-all-v2/summary.txt` 为 `104/104 PASS`，SHA256
  `b38760222f6c4bf7acd37e3c3c7e963f4ba9d8ec0559189bc3f620d0ba638660`。

## 3. Aggregate 中发现并关闭的真实回归

首次 104-test aggregate 在 `tb_ooo_priv_system` 命中 `[S1-TYPED-RSP-LEGACY]`：该 TB 只接了旧
`mem_rsp_cacheable_i`，新 typed response/owner/epoch 输入悬空为 X。修复复用平台
`OooTypedPmaChecker` 生成 Bare-mode post-translate provenance，并在 request fire 锁存
`owner_kind/token/epoch/fault_tval` 到 response；drop/residency/query 输入显式建模，断言保持开启。
单项复跑与第二次 fresh aggregate 均 PASS。该修复不把 typed class 常量化，也没有关闭 assertion。

## 4. 声明边界

允许声明：Q1 leaf 的指定握手/quiet/sticky-grant/modulo-4 行为、命名 assertion 非真空、
mutation sensitivity、共享 source catalog/正式 module harness adoption，以及本工作树当前 104 项
module aggregate 未退化。

禁止声明：live context barrier 已集成、effective old→next classifier 已闭合、完整 quiet、
grant-gated CSR/trap/xRET/SFENCE apply、TLB/FPC invalidate、LR clear、response epoch alias safety、
真实第二 memory datapath、Linux、200 MHz、面积/时序/功耗改善或 architecture-feasible seed。

## 5. 下一原子步

Q2 接口已在 `s2-q2-live-epoch-atomic-slice-contract.md` 与机器 manifest 冻结。实施顺序必须是
`CAPTURE→SQUASH→WAIT_QUIET→GRANT`：先按 held ROB age 清除 younger SQ/fetch，再等待旧
reservation/buffer/SQ nokill/AMO/bridge/IFU drain；full quiet 不得回灌现有 ROB `mem_quiet_i`。
任何 potential boundary 禁止 commit1，Q1 只接受 head0 identity。grant 必须让 commit0、normalized
apply、typed invalidate/LR clear 与 epoch+1 同沿；完整设计仍按真实 mem0 先闭合，不能把 single
mem0 冒充 dual-memory。
