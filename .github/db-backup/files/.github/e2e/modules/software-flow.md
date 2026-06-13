# software-flow e2e module

`software-flow` 是软件开发流程守门模块，用于防止 NEMU、NPC、工具脚本、guest check、QMP/GDB、virtio/device model 等软件产物只靠“构建通过”或人工判断收口。

## 必须保留的循环

- `software-dev-loop`: `scope-contract -> design-plan -> implement -> unit-or-contract-test -> integration-smoke -> regression-or-e2e -> review-record`
- `software-bugfix-loop`: `reproduce -> collect-log -> localize-root-cause -> fix -> focused-test -> regression -> record`
- `software-refactor-loop`: `inventory-callers -> preserve-contract -> mechanical-change -> focused-test -> consumer-regression -> record`
- `hardware-aware-software-loop`: `scope-contract -> hardware-semantic-contract -> design-plan -> implement -> software-focused-test -> system-or-hardware-gate -> review-record`

## 集成关系

NEMU-only 入口 `nemu-dev`/`nemu-ubuntu-focused` 和旧集成入口 `nemu-ubuntu` 都必须包含 `software-flow`。NPC-only 入口 `npc-dev` 也必须包含 `software-flow`，但不得引入 NEMU Ubuntu gate。场景隔离通过新增入口实现，不能删除旧 `nemu-ubuntu*` 集成功能。

## 完成判定

必须扫描 FAIL marker、BAD TRAP、assert、guest marker 和 task-run evidence；完成后必须更新 `.github/memory/modules/software-flow.md`。不能把脚本外层退出码当作唯一证据，也不能把构建通过单独当成软件任务完成。
