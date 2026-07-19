# S2-Q1 canonical runner expected RED

> 日期：2026-07-17
>
> 目的：把 checkpoint 中“旧 canonical runner 不可用”的静态审查结论升级为真实执行证据；本 RED
> 不计入 Q1 leaf GREEN。

实际以独立 evidence 目录运行：

```text
S2_Q1_BUILD_DIR=evidence/r4-s2-q1-mmu-epoch-owner-canonical-red \
  bash run-s2-q1-mmu-epoch-owner-focused.sh
```

结果 `rc=1` 且未产生 summary。release/assert 正向、4 个 assertion-negative 与前六个 mutation 均已
执行；runner 在 `saturating-epoch` mutant 的 compile 阶段被 `set -e` 终止。故障 mutant 第 87 行为：

```verilog
mmu_epoch_q <= (&mmu_epoch_q) ? mmu_epoch_q : (mmu_epoch_q + 2.b01);
```

Icarus 精确报 `syntax error` / `Malformed statement`。根因是旧 runner 的 sed replacement 把合法
`2'b01` 写成 `2.b01`；这不是 mutation kill，不能计 GREEN。完整现场位于：

```text
evidence/r4-s2-q1-mmu-epoch-owner-canonical-red/
```

该目录已通过 `github_index_db.py index-evidence --write-index` 写入 DB。只有修正 replacement、确认
该 mutant compile rc=0 后再由 wrap oracle 命中 `[MMU-EPOCH-Q1][FAIL]`，canonical runner 才可替代
已通过 7/7 的 v2 并解除这一 adoption HOLD。
