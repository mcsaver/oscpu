# RV64 AxiCrossbar held-grant target offer 本地候选契约

## 目标

候选 `axi-crossbar-held-grant-target-offer-v1` 删除 crossbar 已经拥有完整 AW/W holder、target
空闲且 `wr_grant_valid_r` 已唯一确定之后，仍需先锁 `wr_active_q`、下一拍才向 target 呈现
AW/W 的固定空拍。

资格化前驱 `rv64-write-path-bubble-qualification-a1` 在冻结 workload 中测得：

- CoreMark：144,201 次 grant，READY `11/10/01/00=144201/0/0/0`，head-critical=138,965；
- Dhrystone：600,000 次 grant，READY `11/10/01/00=600000/0/0/0`，head-critical=599,999；
- 两项同拍 BVALID 均为 0，observer invalid/overflow=0 且全守恒。

## 精确时序与 owner 契约

只允许以下 direct offer：

```text
!rst && !wr_active_q[target] && wr_grant_valid_r[target]
```

grant 的 master、target、AWADDR/AWSIZE/AWID、WDATA/WSTRB 都必须来自既有完整 holder Q；不得读取
live master payload 来构造 target offer。grant 拍：

- `s_awvalid/s_wvalid` 同时为 1，payload 精确等于 selected holder Q；
- target READY 只决定对应 channel 的 `direct_fire`；
- master `m_awready/m_wready` 保持当前 `!holder && !busy` 公式，不读取任何 target READY/BVALID；
- 该 direct target 的 `s_bready=0`，selected master 不得因这笔尚未注册 owner 的 grant 获得
  `m_bvalid`；其他 target/master 已有的合法 registered B 并行响应不受影响，禁止 ownerless B。

grant 边沿仍原子锁存 `wr_active_q/owner/payload/id`、清 selected master holders、置 master busy并更新
RR；同时：

- READY=`11`：`aw_sent=w_sent=1`，下一拍只等待 registered B；
- READY=`10/01`：只记录已 fire channel，下一拍 registered active path仅重发另一 channel；
- READY=`00`：两 sent 位均为 0，下一拍以锁存 payload继续发两 channel。

B route 继续严格要求 edge-old registered
`wr_active_q && wr_aw_sent_q && wr_w_sent_q`；不得改成 next/fire 组合条件。未来 target 即使 grant 拍
拉高 BVALID，也必须在 BREADY=0 时保持；crossbar 只能在下一拍 registered owner/sent 成立后接收。

## 必须保持

- read path、master read response registered slice、write round-robin与 target decode不变；
- AW-first/W-first、partial holder、同 target contention、不同 target并行语义不变；
- selected master holder 在 grant 拍不能同时接收下一事务，busy 在 B terminal前不释放；
- 已接受 channel绝不重复 VALID/fire，未接受 channel跨 direct→registered边界 payload逐位稳定；
- B backpressure 下 owner/id/resp与 active保持，唯一 B fire 后才释放 busy/target active；
- reset期间本候选新增的 target AW/W direct offer 必须静默；不完整 holder、active target、非法/unknown
  grant绝不 direct offer。既有 master READY 等非候选输出保持原模块 reset 合同，不在本候选中扩改。

## Acceptance criteria

1. `tb_axi_xbar` 非真空覆盖 READY `11/10/01/00` 四象限、direct payload、sent seed、partial-only retry、
   poison live input、grant-cycle BVALID、B backpressure及 same-target RR contention。
2. `OOO_ASSERT` 锁定 direct source、payload、per-channel exact fire→sent、B registered authorization、
   owner稳定、per-master单 grant、target onehot与 direct stall handoff。
3. xbar focused、adapter、dual-memory wrapper、bus/device/default-slave直接相关回归和 Verilator lint
   全部 PASS；lint 不得出现 `UNOPTFLAT`。
4. exact-predecessor CoreMark/Dhrystone 两边均 GOOD TRAP、DiffTest ON、code 0；ROI retired及功能校验
   保持；任一 workload ROI cycles不得回退，至少一项严格改善。
5. performance counter 与 SQ receipt继续 complete/available/conservation=1、overflow/invalid=0；归因应
   主要降低 AXI write-response residency，不能把 grant次数机械解释为全局周期收益。

## 声明与回退边界

新组合锥为 `holder Q + target/RR grant -> target AW/W VALID/payload mux`。在同身份 mapped
synthesis/STA/area/power 前固定 `PPA=UNQUALIFIED`、`promotion_eligible=false`。若 correctness、
CPI 或后续 timing 不合格，只回退本候选 direct-offer mux和 grant-edge sent初始化，不回退 crossbar
既有 holder/owner、adapter fall-through、SQ fusion或 stats probe。
