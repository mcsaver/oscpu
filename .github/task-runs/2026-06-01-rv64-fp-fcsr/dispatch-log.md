# Dispatch Log

## 2026-06-01

- `node_id`: `recall`
- `owner_agent`: `rv64-linux`
- `status`: completed
- `inputs`: AGENTS、Copilot 规则、project-status、known-issues、npc memory、rv64gc-userland instructions、rv64 README/env/study
- `outputs`: 当前目标处于 L5 官方 Ubuntu 用户态前沿；probe L4 已闭合，`/bin/sh` 仍需完整 rv64gc/lp64d 与 F/D CSR/rounding/fflags 证据。

- `node_id`: `audit-fcsr-gap`
- `owner_agent`: `npc`
- `status`: completed
- `inputs`: `npc/rv64/tools/Makefile`、`fp-loadstore-smoke.S`、`CsrFile.v`
- `outputs`: 现有 load/store smoke 只覆盖浅层 `csrw/csrr`，缺少独立 FCSR CSR RMW focused gate。

- `node_id`: `implement-fcsr-smoke`
- `owner_agent`: `npc`
- `status`: completed
- `outputs`: 新增 `fp-fcsr-smoke.S` 与 `smoke-fp-fcsr`。
- `notes`: 本轮不改 RTL，因此不触发 RTL 四段式；边界记录为 CSR 软件路径，不声明算术 fflags。

- `node_id`: `verify`
- `owner_agent`: `npc`
- `status`: completed
- `evidence`: `smoke-fp-fcsr` GOOD TRAP `cycles=492/commits=88`；相邻 FP smoke 回归 GOOD；`git diff --check` PASS。

- `node_id`: `record`
- `owner_agent`: `rv64-linux`
- `status`: completed
- `outputs`: 更新 task-run、project-status、npc memory、known-issues [42]。
