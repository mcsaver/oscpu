# RV64 写路径固定空拍资格化结果

资格化通过，并只授权下一步实验候选
`axi-crossbar-held-grant-target-offer-v1`：crossbar 已经拥有完整、注册的 AW/W holder 且本拍 grant
唯一确定时，直接向 target 呈现 VALID/payload；target READY 只写入下一拍的 per-channel sent bit，
不得回灌 master READY、grant、owner 或 B route。

## 冻结 workload 结果

| workload | ROI cycles / retired | held grants | READY 11/10/01/00 | grant 同拍 BVALID | head write-response | live-pair narrow |
|---|---:|---:|---:|---:|---:|---:|
| CoreMark | 4,785,064 / 3,183,617 | 144,201 | 144,201 / 0 / 0 / 0 | 0 | 138,965 | 144,201 |
| Dhrystone | 8,481,505 / 4,250,000 | 600,000 | 600,000 / 0 / 0 / 0 | 0 | 599,999 | 600,000 |

两项 diagnostic build 都与 source candidate 完全保持 cycles、retired、full cycles、full commits、
GOOD TRAP、DiffTest、功能输出及 SQ receipt。probe 为 complete/available、overflow=0、invalid=0，
arbiter/source/READY、crossbar READY/master/target 与 live-pair bucket 全部精确守恒。

CoreMark 的 grant event 占 ROI 3.0136%，其中 96.37%（138,965 次）直接落在 ROB-head
AXI write-response 临界拍；Dhrystone 为 600,000 次 grant，599,999 次 head-critical，占 ROI
7.0742%。这只是结构机会与临界性证据，不预支一比一 CPI 收益；最终 oracle 仍是功能实现后的
exact-predecessor A/B。

## 架构裁决

- 首选 held-grant target offer：其仲裁、target、owner、address/data/ID 都来自注册 holder Q；
  master READY 保持本地 holder-space 公式，所以边界最窄且没有 target READY→master READY 环。
- grant 拍只允许 AW/W VALID/payload；`s_bready` 与 `m_bvalid` 继续要求 registered
  `wr_active_q && wr_aw_sent_q && wr_w_sent_q`，禁止 ownerless/zero-cycle B terminal。
- dual-memory arbiter 的 `S_IDLE` quiet 是当前 F0 version 的显式 contract、assertion 与 mutation
  boundary；未来可重签新微架构，但本轮不授权修改。
- live-pair direct-active 与 held-grant offer在常见同拍 pair上都把 target offer从 C2移到 C1，不能
  简单相加；前者只保留为 held-grant 若 mapped timing失败时的 registered-output替代。

## 声明边界

本轮只完成 stats-only 资格化。功能候选尚未实现，也没有 fresh mapped synthesis/STA/area/power；
因此固定为 `PPA=UNQUALIFIED`、`promotion_eligible=false`，不宣称 cycle reduction、频率、面积或
功耗收益。
