# Evidence Index

## 主要审计产物

| 资产 | 类型 | 用途 | SHA-256 |
|---|---|---|---|
| `audit-results/2026-07-11-rv64-ooo-blind/PHASE1_FROZEN.txt` | frozen baseline | 代码优先事实与证据等级 | `3aa04ab0e911161c5dacfe5e9ce91454e5a57b595c50b8bf065f5628c27e0d2d` |
| `audit-results/2026-07-11-rv64-ooo-blind/04_DOCUMENT_COMPARISON.txt` | comparison | current/snapshot/history 对照 | `8d57e7eff3c9ce6005c396d220d86d1aeda17ed95bc27a179d9858dd02280862` |
| `audit-results/2026-07-11-rv64-ooo-blind/05_FINAL_ARCHITECTURE_ASSESSMENT.txt` | final report | 拓扑、优缺点、能力边界、优先级 | `411003c371fcb5fd7069fec0d5cbba33884c787acb256e5deecbda0048bb0ae8` |
| `audit-results/2026-07-11-rv64-ooo-blind/INDEX.txt` | index | 阅读顺序与证据入口 | `b14c4e21955a303abcbda55a24159fb5cd45167de47eef6cb8c07de0a670d037` |

## 定向 RTL 检查

| 检查 | 结果文件 | 裁决 |
|---|---|---|
| FP legality + dispatch | `fp_legality_classify_result.txt` | 四类 trap-classified 同时 backend-present；合法正对照通过 |
| xRET current mode | `xret_privilege_result.txt` | 三类 current-mode 缺口复现；TSR 正对照通过 |
| page-end C fault | `fetch_page_end_c_fault_result.txt` | 下一页 fault 提前归属当前 C 指令 |
| IFU A-update flush | `fetch_ad_flush_partial_result.txt` | AW-only 后 flush 丢写通道状态 |
| MIQ flush + DRAIN pop | `miq_flush_drain_pop_result.txt` | ghost entry 复现 |
| MIQ full + pop + push | `miq_full_pop_result.txt` | 模块合同复现；当前默认整核不可达 |

## 既有工程证据

- `npc/rv64/perf/results/20260711-125729/module-testbench/summary.txt`: 86/86 PASS。
- `npc/rv64/perf/results/core-regress/20260711-133547-973361/{summary,status}.txt`: module/lint/build/AM PASS，177 riscv-tests，overall_rc=0。
- `npc/rv64/build/sta/NpcTop-100MHz/NpcTop.opensta.rpt`: WNS about -5.35ns；IFU/frontend next-PC path。

## 收尾证据

- `evidence/directed-tests.md`: 2026-07-11 15:38 前后重跑，exit 0。
- `evidence/final-guard.md`: strict guard、diff check、词汇与 dirty-tree 边界。
- `evidence/db-memory.md`: stored memory 更新、bounded readback 与 DB-first audit 均通过。
