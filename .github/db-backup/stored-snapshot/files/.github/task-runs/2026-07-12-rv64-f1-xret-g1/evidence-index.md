# Evidence Index

## 基本信息

- `task_id`: 2026-07-12-rv64-f1-xret-g1
- `task_slug`: rv64-f1-xret-g1
- `asset_count`: 1002 raw assets（已登记到 evidence DB）
- `total_size_bytes`: 6266137
- `retention`: raw evidence 留本地且被 Git ignore；本文件只保留 bounded 关键索引。

## 结论索引

| 证据组 | 结论 | 是否采信 |
| --- | --- | --- |
| old-RTL classifier RED | MRET@S/U、SRET@U 三类各缺 illegal/trap，共精确 6 fail | 是，失败证据 |
| focused current | classifier/head-pair/lane1/pending/priv-system 5/5 PASS | 是 |
| real-encoding integration | cause=2、mepc/mtval、handler return、no commit、no CsrFile xRET request | 是 |
| final module | 当前测试文件 87/87 PASS | 是 |
| bundled core-regress | Verilator 5.051；module/lint/build/AM/official；overall_rc=0 | 是 |
| current-config AM | 59/59，但日志明确 Difftest OFF | 只作功能 smoke |
| official | 177 tests attempted，177/177 PASS | 是，tohost/good-trap 范围 |
| independent Difftest ON AM | ON/reference enabled 各 59 次，59/59 PASS | 是 |
| config/artifact restore | 六配置逐字节 MATCH；clean OFF rebuild；fresh add 1/1 | 是 |
| structural | style PASS；contract current=35 baseline=35；lint PASS | 是 |
| independent review | privilege matrix、trap priority、integration 与 CsrFile request sticky 无 blocker | 是 |

## 关键资产

| 路径 | bytes | SHA-256 | 说明 |
| --- | ---: | --- | --- |
| `npc/rv64/perf/results/20260712-xret-g1/red/logs/tb_ooo_fetch_head_classify_gate.log` | 1078 | `273154ee03838318ce8b3dc8f87d254dbf32c97e3f0761ba47e1683a80d20ec7` | old-RTL 精确 6 fail |
| `evidence/focused-green/summary.txt` | 443 | `c38d880e8939334c18d923c242ab832fe43189d0cab3c58d98f1ce6ccbe40123` | focused 5/5 |
| `evidence/focused-green/logs/tb_ooo_priv_system.log` | 17346 | `27664acabfda43abfedc287eae986e5c1e00c21f3981fcc3443a53b184a97f00` | 真实 xRET 编码整核边界 |
| `evidence/module-final-current/summary.txt` | 2899 | `dfaa7abee70a41bf83db19e9f4cf66ee082bf67d73a8168d4fec89f2c8c7841b` | current 87/87 |
| `evidence/core-regress/20260712-105358-1383799/summary.txt` | 17976 | `3bb8b29bd7e4d1647c185e5c18421d5444a876c7444549e3fb374100b449af85` | bundled overall_rc=0 |
| `evidence/core-regress/20260712-105358-1383799/status.txt` | 17953 | `6331b8133bf6a2f9565da82d98a66e8297454f4b266e02bfba07741e38a5ce54` | 子层 rc 与 177 attempted |
| `evidence/am-difftest-on.log` | 433841 | `0a98f1f446dbf4213a9ff75cd04504d14b78195519b2a236a875a11a191f764d` | Difftest ON 59/59 |
| `evidence/am-difftest-on.status` | 266 | `eb08bac61998d11994cc8dc8493bd9781132ea68a52927ed554404b08914c2f8` | marker/count 摘要 |
| `evidence/config-restore.sha256` | 1202 | `f03f06bbf65ad0e86349260ddabf64412e334eb8a20e4d84a16ecb5a1efd7c87` | NPC/NEMU 六配置 MATCH |
| `evidence/restored-config-rebuild.log` | 54442 | `bd4e9cba8889c5d5becf92efb3aea6c767187f0733412c7ac8e6781df7c7b8a1` | clean OFF rebuild + add 1/1 |
| `evidence/structural/check-rtl-style.log` | 226 | `17538296cc5586b0985b48152f4764ea83c3f7a88fcfb1fdcbe6a20f8f625c7d` | style PASS |
| `evidence/structural/check-contract.log` | 271 | `b4e160756bc084a1b3ff5eb6b7836a2aac852965d18ee48e6a182ba55384f441` | contract 35/35 |
| `evidence/structural/lint.log` | 8830 | `39b982049fdd039041d764512c76e5537a100fa34c2f579b9a8b0cff1461e37d` | Verilator lint PASS |
| `evidence/strict-guard.log` | 761 | `8371b6d6c29db6502b09bd2fb47a4980c601e10f71a56665a1e4c754e96e5e37` | strict guard / npc-dev PASS |

## 证据边界

- core-regress 的 current-config AM 明确是 Difftest OFF；逐退休比较只引用独立 ON run。
- old-RTL RED 日志位于 `npc/rv64/perf/results`，未伪装成 current GREEN。
- 本切片关闭 XRET-G1 功能合同；没有新跑 5 ns STA，也不声明 200 MHz。
- raw asset 的完整列表与摘要已经写入 evidence DB；本索引刻意不复制 1002 个条目。
