# Evidence Index

## 基本信息

- `task_id`: 2026-06-16-nemu-npc-parallel-runtime-policy
- `task_slug`: nemu-npc-parallel-runtime-policy
- `asset_count`: 1
- `index_mode`: manual-summary

## 证据资产

### .github/task-runs/2026-06-16-nemu-npc-parallel-runtime-policy/evidence/validation-summary.log

- `kind`: log
- `encoding`: utf-8
- `markers`: `PASS fake ps warn rc=0`; `PASS fake ps strict rc!=0`; `PASS runtime guard line`
- `summary`: 证明 active runtime guard 默认 warn 可继续并行开发，strict 保留 hard fail，off 可跳过；真实 `nemu-dev` dispatch 已越过 runtime guard，后续失败与本轮策略无关。

## 结论

- `parallel_default`: PASS
- `strict_repro_mode`: PASS
- `real_dispatch_runtime_guard`: PASS
- `residual_nemu_slice_contract`: BLOCKED_UNRELATED
