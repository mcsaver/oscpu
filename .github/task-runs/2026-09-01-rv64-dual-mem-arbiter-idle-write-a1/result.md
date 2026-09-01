# dual-mem-arbiter-idle-write-admission-v1 本地 A/B 结果

## 裁决

`RETAIN_LOCAL_EXPLORATORY`。

候选在 exact predecessor `axi-crossbar-held-grant-target-offer-v1` 上同时改善 CoreMark 与
Dhrystone，功能终止、DiffTest、ROI retired、完整 commit、performance-counter守恒和 SQ receipt
均闭合。fresh production RTL design ID为
`sha256:c50a0c61b76a314939fb8b79eadab15cfdc5f0053623021ec06425d3304528fc`，155个生产 RTL文件；
构建前后 identity逐字节相同。候选模拟器 SHA-256为
`6e9745e5313f3885dca51eae962594d220630053d9535a5bc2be012bc9ab623d`。

该裁决只证明功能与本地确定性 CPI；没有 fresh mapped synthesis、STA、area或power结果，因此
`PPA=UNQUALIFIED`、`promotion_eligible=false`。

## Exact-predecessor workload A/B

| workload | predecessor ROI cycles | candidate ROI cycles | delta | cycle reduction | speedup | ROI retired |
|---|---:|---:|---:|---:|---:|---:|
| CoreMark | 4,667,639 | 4,570,581 | -97,058 | 2.079381% | 2.123537% | 3,183,617 = 3,183,617 |
| Dhrystone | 7,891,545 | 7,321,712 | -569,833 | 7.220804% | 7.782784% | 4,250,000 = 4,250,000 |

两项 speedup 的几何平均为 **4.915009%**。两项均满足：

- `HIT GOOD TRAP`恰好一次；
- DiffTest为 `ON`；
- ebreak termination code为0；
- CoreMark CRC/PASS输出保持，Dhrystone PASS输出保持；
- counter `complete=1`、`available=1`、`overflow=0`、`invalid_events=0`、`conservation=1`；
- SQ receipt的 region/final均 complete、available、conserving、zero malformed/invalid/overflow。

完整运行也没有 commit漂移：CoreMark为 4,747,345/3,218,532 →
4,649,043/3,218,532，Dhrystone为 7,921,677/4,260,624 →
7,351,802/4,260,624。

## Counter attribution

| workload / ROI counter | predecessor | candidate | delta |
|---|---:|---:|---:|
| CoreMark memory latency | 1,821,427 | 1,707,431 | -113,996 |
| CoreMark request outstanding | 746,240 | 621,783 | -124,457 |
| CoreMark AXI write request | 301,206 | 163,386 | -137,820 |
| CoreMark AXI write response | 276,554 | 277,651 | +1,097 |
| Dhrystone memory latency | 4,690,364 | 4,080,445 | -609,919 |
| Dhrystone request outstanding | 2,530,164 | 1,930,173 | -599,991 |
| Dhrystone AXI write request | 1,270,001 | 669,986 | -600,015 |
| Dhrystone AXI write response | 1,180,002 | 1,180,002 | 0 |

资格化探针在 predecessor上给出 CoreMark 144,201次、Dhrystone 600,000次 strict IDLE write
机会。候选分别回收97,058与569,833个 ROI cycles，约为 strict机会的67.31%与94.97%。尤其
Dhrystone write-response完全不变，而 write-request几乎精确减少600k，说明收益来自删除共享
arbiter写请求 admission空拍，不是把B延迟或benchmark边界重新分类。

本结果不声明“arbiter capture head-critical”计数；现有 crossbar head ledger观察的是更晚的
crossbar grant/write-response原因，不能冒充本候选的 capture拍因果证据。

## 实现与组合 DAG 闭合

`OooDualMemAxiArbiter`只在合法、精确已知的 IDLE write winner上直出 AW/W：

- read仍先寄存 owner，再进入 `S_READ_ADDR`；
- AW/W各自独立 fire，并分别播种 `aw_seen_q/w_seen_q`；
- READY `11/10/01/00`分别进入 registered B或仅重试尚未完成的channel；
- B只在 registered `S_WRITE_RESP`中按 `owner_q`授权；
- RR只在真实 R/B terminal更新；
- illegal dual-type、unknown、reset均 fail closed。

首次 full-top lint曾暴露一条真实 `UNOPTFLAT`：

```text
peer ARVALID -> arbiter census -> writer WREADY -> bridge w_fire
-> peer maintenance -> peer cache lookup suppression -> peer ARVALID
```

根因是旧 `OooMemAxiBridge.write_irrevocably_presented_w` 同时包含 `aw_fire/w_fire` 与
`registered write-state && AW/W VALID`。bridge的 AW/W VALID只可能来自这些registered write
state，因此 fire项被后一项严格吸收。删除冗余 fire项后，stalled VALID首拍的不可撤回与kill
maintenance authority仍保留，fire后的义务由 `write_escaped_q`保持；stats-on/off full-top lint均
重新 PASS且无 `UNOPTFLAT`。这没有改变RR或B/maintenance权限，只切断错误的READY反向依赖。

## 验证闭环

通过项包括：

- 正式 `dual-mem-arbiter-idle-write-focused`（默认 `OOO_ASSERT`）与独立 release profile；
- source `11/10/01`、READY `11/10/01/00`、AW-first、W-first、partial retry、poison payload；
- write/write与read/write竞争、RR lane0/lane1、提前B隐藏、5拍B反压、reset phase matrix；
- 双 lane持续AW/W时，RR=0只direct接受lane0 AW、RR=1只接受lane1 W，沿后只重试同一winner的
  另一channel，loser两个READY始终为0；
- `OOO_ASSERT + NEGATIVE_CLASS`只命中一次 `[ARB-REQ-CLASS-ONEHOT]` fatal；
- xbar、lane adapter、memory bridge、dual-memory wrapper四项断言回归；
- killed A/D maintenance、mismatched-owner fail-closed、pre-write kill no-authority、selective A/D
  drain；
- owner-timing causal probe：production store terminal=1/3/6、peer admission=2/4/7、B block=1/3/6；
- 去掉adapter input AW/W fall-through与去掉final-B fall-through两个mutation均被检测；候选存在时
  mutation peer admission的正确向量为3/5/8；
- targeted release/assert Verilator lint、stats-on/off full-top lint、`git diff --check`。

旧 `npc-rv64-owner-timing-causal-analysis-v1` 仍绑定 predecessor schema/design identity。它没有被
原地篡改，也没有把旧 receipt与本候选 probe拼接成当前证据；若后续需要正式 causal-analysis
receipt，应另建 candidate-aware版本并绑定本 design ID。

## 证据与回退边界

- 机器可读结果：`result.json`；
- SQ receipts：`coremark-sq-receipt.json`、`dhrystone-sq-receipt.json`；
- exact source/evidence SHA-256已写入 `result.json`；
- candidate raw logs位于
  `/tmp/dual-mem-arbiter-idle-write-20260901-a1/full-core/{coremark,dhrystone}.log`；
- candidate binary位于
  `/tmp/dual-mem-arbiter-idle-write-20260901-a1/candidate-build/NpcSimTop`。

若后续 physical timing或更广回归不合格，回退边界只包括：arbiter IDLE合法write直出、direct
fire的owner/state/seen播种、配套断言/TB，以及本候选要求的bridge等价READY→maintenance DAG
切断；不得回退已经保留的adapter input AW/W fall-through、SQ current-head fusion或crossbar
held-grant target offer。
