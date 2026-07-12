# Evidence Index

## 基本信息

- `task_id`: 2026-07-12-rv64-f1-fdg-g1
- `task_slug`: rv64-f1-fdg-g1
- `raw_asset_count`: 1718
- `raw_total_size_bytes`: 7852362
- `retention`: raw evidence 位于被 Git ignore 的 `evidence/**`；本文件只保留 bounded 关键索引。
- `database`: 1718 项均已登记到 `evidence_assets`；回查使用
  `python3 scripts/github_index_db.py evidence --run-id 2026-07-12-rv64-f1-fdg-g1`。

## 裁决摘要

| 证据组 | 结果 | 是否采信 |
| --- | --- | --- |
| 旧 RTL 定向 RED | 四类非法 FP 均只错 backend-valid，`errors=4`、rc=1 | 是，作为缺口可达证据 |
| focused GREEN | 4/4 PASS，含合法 FADD.S 正对照 | 是 |
| assertion mutation | 强制违约触发唯一 `FDG-I1`，runner rc=1 | 是，作为断言非真空证据 |
| full module | 87/87 PASS | 是 |
| bundled core-regress | Verilator 5.051，module/lint/build/AM/official 全绿，overall_rc=0 | 是 |
| Difftest-ON AM | ON/reference 各 59 次，59/59 PASS | 是 |
| restored artifact | clean OFF rebuild；fresh `add` 明确 Difftest OFF、1/1 PASS | 是 |
| structural/guard | style PASS；contract 35=35；lint PASS；strict guard PASS | 是 |
| system-Verilator run | 5.020 不支持 `PROCASSINIT`，build/AM 失败，overall_rc=1 | 否；其后 official 可能复用旧 binary |

## 关键资产

| 路径（均相对本 task-run） | bytes | SHA-256 | 说明 |
| --- | ---: | --- | --- |
| `evidence/red/logs/tb_ooo_fp_legality_dispatch_path.log` | 1881 | `db92a4e55ac693e4a03f4dfdd3a9028ed85508b1c48bd03fa9a279ecfe804349` | 旧 RTL 精确 RED |
| `evidence/focused-green/summary.txt` | 379 | `e4269b916499857691a9f5ada91d2b98f0d6134c11007924dadd2a4c2a234f46` | focused 4/4 |
| `evidence/module-full/summary.txt` | 2860 | `61f9424b867f96bd10fd555f2a7536125f7a7b761793bf0dd7ae90e1e0b36672` | standalone full module 87/87 |
| `evidence/assert-negative/logs/tb_ooo_fetch_trap_gate.log` | 17672 | `6180ff7d228998de90f1fc71c3d56f2d2a6606e00a8bd7d15ddd6f257e65cc48` | FDG-I1 负探针 |
| `evidence/core-regress-agent-env/20260712-101738-1337411/summary.txt` | 17994 | `6579fff0530adedeed4481e68ccc3a5cdaa4b88c8892a82f95129173360d8142` | bundled run summary / overall_rc=0 |
| `evidence/core-regress-agent-env/20260712-101738-1337411/status.txt` | 17953 | `6331b8133bf6a2f9565da82d98a66e8297454f4b266e02bfba07741e38a5ce54` | 177 tests attempted 与逐项 rc |
| `evidence/am-difftest-on.log` | 433839 | `1eb14f62f21f7fef9db19cfb9957b0b5b84c1979e238055ac5120acd8b2d2dc5` | Difftest ON 59/59 原始日志 |
| `evidence/am-difftest-on.status` | 264 | `3c3356869e6eabf2394608145d138608ec533d6a3bafd7d99af625372e332c9d` | command/rc/count 摘要 |
| `evidence/config-restore.sha256` | 661 | `e16eae1e4b6aa28cbd464782b016aeea056dfa2be1211c595607ec7bf5ce1edf` | NPC/NEMU 六配置恢复哈希 |
| `evidence/restored-config-rebuild.log` | 55248 | `4198e7f3e0e97b05a5edbff919e998081848dd86ddb97d73fb28d8c39f806dd1` | clean OFF rebuild + fresh AM smoke |
| `evidence/structural/check-rtl-style.log` | 226 | `17538296cc5586b0985b48152f4764ea83c3f7a88fcfb1fdcbe6a20f8f625c7d` | RTL style PASS |
| `evidence/structural/check-contract.log` | 271 | `b4e160756bc084a1b3ff5eb6b7836a2aac852965d18ee48e6a182ba55384f441` | current=35 baseline=35 |
| `evidence/structural/lint.log` | 8830 | `fd4bfb3c0e086ce352b64df5a88f75298f231da67556b339771cb905e5799e7e` | Verilator 5.051 lint PASS |
| `evidence/strict-guard.log` | 911 | `ba2486399daec9949dee1a226f00329941409eed686cb8614cbad82624dd2e05` | final strict guard PASS |

## 明确排除的失败尝试

| 路径 | bytes | SHA-256 | 排除理由 |
| --- | ---: | --- | --- |
| `evidence/core-regress/20260712-101529-1308548/summary.txt` | 18269 | `d2e4a3b509326cc67801451c95e480aada28e6979cec2027cf104e5db242b2b9` | system Verilator 5.020 build/AM 失败，overall_rc=1 |
| `evidence/core-regress/20260712-101529-1308548/status.txt` | 18254 | `9d0dc64bc7418ec56a65337e64946dc3fc0388af6bd86977092f4a3b964746af` | 后续 official PASS 不能覆盖失败 build，也不能作为 GREEN |

## 边界

- 新整链 TB 观察到 ordinary-admission gate 输出；下游 mux 是直接 OR sink，并由既有 mux TB 覆盖。
- 本切片没有新 5 ns 重综合/STA，只关闭 FDG-G1 功能合同；200 MHz parent 目标仍开放。
- raw 日志、177×2 binary 与逐项日志不纳入 Git；其尺寸、哈希、marker 和摘要保留在数据库
  `evidence_assets`，避免重新引入超过 1 MiB 的 tracked evidence。
