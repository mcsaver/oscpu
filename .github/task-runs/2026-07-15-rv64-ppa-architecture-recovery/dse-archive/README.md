# 可执行 DSE archive companion

本目录只执行 `global-dse-archive-companion-policy.md` 的候选保留与淘汰纪律，
不修改或替代任何 hash-bound contract、policy 或 baseline。当前状态保持
`architecture_feasible_seed_id=null`、formal front/canonical/champion 为空；S1 typed ABI
只登记在 `development` 与 `high_uncertainty`，没有被工具伪造成 architecture-feasible seed
或 PPA 胜者。完全空的初始化状态保存在 `tests/fixtures/initial-ledger.jsonl` 并由正例测试覆盖。

## 检查

```bash
python3 .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/dse-archive/check_archive.py \
  --registry .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/dse-archive/registry.json

python3 -m unittest discover \
  -s .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/dse-archive/tests \
  -p 'test_*.py' -v
```

checker fail closed 地验证：严格 JSON、所有路径/SHA、content-addressed point/inventory/source
bundle、完整点 hard-gate 顺序、逐 workload 最差项、Power activity/macro 资格、同一 seed、
三轴 Pareto、四个持久 pool、K=4 global thaw 和 append-only hash-chain ledger。

## 登记协议

1. 每个候选使用独立 `design_id`；point manifest 文件名必须是其 SHA-256 加 `.json`，并由
   `registry.json/point_manifests` 引用。不得覆盖旧 point；状态变化写新 design point/event。
2. `intermediate_checkpoint` 的 Performance/Area/Power 必须全部 `unqualified/null`，只能留在
   development/high-uncertainty/diversity，不得进入任何 Pareto 或 promotion。
3. `complete_design_point` 必须绑定文件名以 SHA 开头、同时包含 source/config 的 immutable
   design bundle，并令 `design_id=sha256:<bundle_sha256>`；另绑定内容寻址的 required-test
   inventory，并报告全部 hard gates、两个冻结 workload 和固定 evaluation order。
4. ledger 每行一个 event；`event_sha256` 是删除自身字段后 canonical JSON（key 排序、无空格、
   UTF-8）的 SHA-256，`previous_event_sha256` 串起链。Git 历史加 hash chain 提供 append-only
   provenance；任何重写/断链/registry head 漂移都会被拒绝。
5. 每 4 个 `complete_point_evaluated` 后 `thaw_due=true`，下一条 event 必须是
   `global_thaw_opened`；它至少绑定两个完成父点、一个固定强耦合块和 completion definition。
6. 当前 TESTS 实算 103、normative policy 仍为 102，故 `drift_blocker_active=true`。这个 blocker
   未经 contract/policy/provenance/tests 原子更新前，formal Pareto/promotion 必须为空。

registry、point、ledger event 与 inventory 的机器定义位于 `schemas/`；JSON Schema 用于编辑器
提示，跨文件/跨字段安全不变量以 `check_archive.py` 为准。
