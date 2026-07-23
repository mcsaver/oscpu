# V9K PTW-PMP-G1 RTL derivation

## IFU path

`S_WALK_R` leaf response → `walk_pte_addr_q` →
`u_walk_pte_write_pmp_checker(8B,S-mode,WRITE)` →
`walk_ad_write_deny_w` → access-fault `S_RESP` 或 granted `S_AD_UPDATE` →
AXI AW/W/B → local-level re-walk。`AWADDR=walk_pte_addr_q`，`WDATA=ad_pte_q`；
AW/W 独立握手并由 `aw_done_q/w_done_q` 各记账一次，两者与 B 均完成
后才结束 owner。Second-page deny 还必须保留
`fetch_offset_q=F`，因此 F=2/4/6 的 successful prefix 与 fault suffix 是同一事务 owner。

## LSU path

`S_WALK_R` leaf response → `walk_pte_addr_w` →
`u_walk_pte_write_pmp_checker(8B,S-mode,WRITE)` →
`walk_ad_write_deny_w` → registered access-fault `S_RESP` 或 granted
`S_AD_UPDATE` → AXI AW/W/B → original load SQ query/data AR 或 original store AW/W。
PTE 写通道中 `AWADDR=walk_pte_addr_w`、`WDATA=ad_pte_q`；load-A 行以 W-first、
store-D 行以 AW-first 直接覆盖两种合法顺序。
`mem0_rsp_owner_kind/token/mmu_epoch/fault_tval` 来自已接受 request snapshot，不得从测试后续
改变的 live inputs 重建。READY 延迟 0/1/2/3/5 拍分别驱动三类 deny 场景；
`v9k_ptw_pmp_deny_pending_q` 从 checker deny 拍跟踪到 response handshake/drop terminal，
同时保持 `AWREADY=WREADY=1`，因此任何非法 AW/W VALID 都会成为可观测的当拍 handshake。

不定长 response stall 由生产 RTL 状态译码直接闭合，不从 5 拍动态样本外推：
`lsu_axi_awvalid_o` 与 `lsu_axi_wvalid_o` 的完整赋值只在 `S_WRITE_REQ`
或 `S_AD_UPDATE` 为真，而 checker deny 进入 `S_RESP`。`rsp_ready_w=0`
时 queued station 不能 `stage_advance_w`，正常 `S_RESP` 分支无 state assignment，
因此对任意周期数保持 AW/W VALID 为零；kill 则以 `mem0_drop0_valid_o`
结束该 owner 区间。`validate_lsu_unbounded_deny_quiet_structure` 精确绑定这些
赋值与状态分支，静态负例向 AW VALID 译码加入 `S_RESP` 后必须 RED。

## 反例映射

- checker tuple：WRITE bit、PTE address、S-mode、8B 各有独立 compile-success RTL variant。
- branch polarity：deny 被忽略与 grant 被强制 deny 各有独立 variant。
- response class：access fault 被改为 page fault由定向 response oracle 检出。
- channel quiet：deny 拍错误呈现 AW 或 W 由定向检查检出；跨拍周期监视器
  `[V9K-LSU-PTW-PMP-DENY-QUIET]` 进一步覆盖到 response terminal 的不定长静默区间。
- allow sensitivity：IFU、LSU A/D allow 用例直接检查 checker grant、`S_AD_UPDATE`、AW/W、
  `AWSIZE=3`、checker address-to-`AWADDR` 绑定、两拍 stall payload 保持与独立
  channel exactly-once handshake，避免只证明 deny 而未证明正向路径。
- response snapshot：LSU 三类 deny 行均 sweep READY 延迟 0/1/2/3/5 拍，并有将
  `rsp_owner_token_q` 改接 live request token 的 compile-success variant。
- late channel leak：三个 compile-success variant 分别在第 3 个 stalled-response 周期
  脉冲 AW、W 或 AW+W；必须由跨拍监视器与 READY-high 定向行动态拒绝。
- unbounded state decode：静态证书精确限定 AW/W VALID 的状态集，并将
  `S_RESP` 违规加入 AW 译码作为 fail-closed 反例，避免用更长但仍有限的延迟表代替结构证明。

## IFU 下游责任边界

PTW-PMP-G1 证明 bridge 生成 `resp0_bytes=F` 和 instruction access-fault。F=2/4/6
之后的 lane owner、fault PC 与 `tval` 投影不属于 PTE WRITE checker 边界；它们
分别由 current-design `IFU-ACCESS-G1` 和 `IFU-TVAL-G1` 的独立证据闭合。
