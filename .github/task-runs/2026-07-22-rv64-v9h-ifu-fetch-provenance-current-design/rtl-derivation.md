# V9H IFU-FETCH-G2 RTL 推导记录

## Phase 0：待裁决状态

当前 architecture debt ledger 将 `IFU-FETCH-G2` 标为 `STALE_EVIDENCE`。历史 scoped
实现曾闭合，但当前 design-id、模块 aggregate、source provenance 与 RTL 验证变异尚未重新绑定。

## Phase 1：调用链与数据流

`OooFetchAxiBridge` 逐 2B 获取 packet，在首个失败 frontier 停止年轻访问，并输出 raw packet、
`resp0/resp1` 与 `resp0_bytes=F`。该元组经 `NpcCoreTop`、`OooCoreTopGlue`、`OooFrontend`
到达 `OooFetchPacketDecode`。decoder 先验证 prefix range，再读取 C/32 长度，最后按完整
instruction range 生成 per-slot response；faulted range 的 raw instruction 被净化为 NOP。

## Phase 2：待验证方程

`range_resp(start,len,F) = resp1` 当 `start+len > F`，否则为 `resp0`；若 range 在 F 前
但 `resp0` 自身非 OK，则 `resp0` 优先。

slot0 prefix 只有 `[0,2)` 为 OK 才能决定 L0；slot1 prefix 只有 slot0 完整 range 与
`[L0,L0+2)` 都 OK 才能决定 L1。slot0 fault 后 slot1 没有独立架构 owner，继承 slot0 fault。

## Phase 3：决策规则

先运行当前 source 的 page-end 与 packet-decode focused tests。若 RED，沿 bridge frontier、
透传 ABI、decoder range owner 和 NOP 净化定位根因；若 GREEN，则生产 `.v` 保持不变，转入
marker 加固、当前源码变异、动态模块 aggregate、证据生成器与 arch-stable fail-closed 绑定。
