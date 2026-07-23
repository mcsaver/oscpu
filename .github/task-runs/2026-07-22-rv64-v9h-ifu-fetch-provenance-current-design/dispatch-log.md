# V9H 派发与状态日志

## 2026-07-22 recall / scope

- 精确 brief 因缺少独立 focus 正确失败；较宽 `rv64 IFU fetch` brief 完成。
- 从 current debt ledger 选择 `IFU-FETCH-G2`，原因是它与 V9G 共用 bridge owner，且是
  下游 fault payload 语义的前置 byte-range 合同。
- 历史报告只作为范围与反例来源，不能替代当前 design-id 动态证据。

## 2026-07-22 contract freeze

- 冻结 successful-prefix/fault-suffix ABI、F=2/4/6 C/32 矩阵、invalid-tail noninterference、
  stall owner 与 source-mutation 成功条件。
- `IFU-ACCESS-G1`、`IFU-TVAL-G1`、`PTW-PMP-G1`、full-core arch-stable 与正式 PPA 均保持独立。

## 2026-07-22 coverage review and closure

- 首轮只读复核返回 GAP，指出缺少真实 bridge F0、反压期间事务 owner 绑定、成功 packet 后无复位
  stale-tail 反例、response 接受后静默以及监视器正控制。
- 主节点补齐这些周期级判别点，并将可区分的 current-source RTL 验证变体扩展到 16/16；固定
  4-byte slot1 起点在合法输入上观测等价，未计入 mutation kill。
- 最终无工具复核使用
  `subagent-contracts/v9h-ifu-fetch-final-evidence-review-v1.json`
  （SHA-256 `59e76299a8b2fc9f0c6711576b27ed7698f4aae8212484533915e7b5a750e50b`）
  的渲染文本，结论为高置信度 PASS：允许把当前 design_id 下的 `IFU-FETCH-G2`
  从 `STALE_EVIDENCE` 重绑为 `CLOSED`。
- 复核边界：不关闭 full-core architecture freeze，不合格化 PPA，也不覆盖 PMP/RRESP、完整物理
  footprint、lane1 capture、fault-`tval` lifecycle 或 PTW write PMP。

## 2026-07-22 provenance and full-core replay

- `npc/rv64/Makefile` 新增 canonical 入口导致 9 个定向架构门仅因来源哈希过期而暂时 RED；
  exact-byte 重构证明旧 `Makefile`、current `Makefile` 的门语义投影不变，来源摘要重绑定后
  9/9 GREEN。
- 公共冻结验证器与 `Makefile` 的扩展也使既有 CLOSED 条目的工具入口哈希过期；因此没有只改
  ledger 摘要，而是依次重放 FDG、XRET、memory lifecycle、IFU AXI、INSTRET 的 canonical
  本地仿真命令，所有 current-design 结果重新 PASS。
- 最终 `run-arch-stable-audit.sh` 返回 `architecture_freeze=GAP`、`ppa=UNQUALIFIED`、
  `promotion_eligible=false`、40 blockers；相较本轮前 41 blockers，净关闭 `IFU-FETCH-G2` 一项。

## 2026-07-22 e2e and strict guard

- `.github/task-runs/2026-07-22-rv64-ifu-fetch-provenance-v9h/`：`npc-dev` 5/5 completed。
- `.github/task-runs/2026-07-22-shared-validator-fail-closed-replay-v9h/`：10 个执行节点均
  PASS，但 bounded recall 缺少 profile 之外的独立业务 focus，整体按规则保留 blocked。
- NPC module memory 发布后，`.github/task-runs/2026-07-22-rv64-ifu-fetch-provenance-v9h-final/`
  的 `agent-system` 10/10 completed；最终 strict guard 对 `agent-system`、`npc-dev`、
  `github-index` 全部 PASS。
