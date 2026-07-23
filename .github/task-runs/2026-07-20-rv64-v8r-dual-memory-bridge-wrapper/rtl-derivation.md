# v8r/F1 RTL 四段式推导

## A. 需求语言

两份独立 bridge/cache 必须在同拍承接两个已预热 load，并在一侧 miss 占用共享 AXI 时继续让
另一侧 hot load 前进。两份 cache 可能因 page walk 或原型复制而持有同一物理 line；任一已授权
store/A-D 外部写到达真实 B terminal 后，peer 旧 alias 必须立刻不可用于 hit。

## B. 结构语言

新增无自有状态的 `OooDualMemBridgeWrapper`：两份 bridge 位于 F0 arbiter 上游，cache-hit response
直接返回各 lane，raw miss AXI 才进入 registered-owner arbiter。每份 bridge 从既有 local cache
maintenance authority 导出 valid/address/wstrb，wrapper 交叉连接到另一份 D-cache。

D-cache peer 维护只写 valid bitmap，不成为单口 SRAM owner；首行和跨线次行在 local valid 更新
之后清零。判决拍用锁存 lookup exact line 与当拍 peer event 比较，命中则组合屏蔽 hit。

## C. RTL 语言

- 所有可综合文件为单 module Verilog-2001 `.v`，组合 `always @(*)`、时序
  `always @(posedge clk)`，过程式立即断言，不使用 SVA/`always_ff`。
- bridge/cache 增加 `ENABLE_PEER_INVALIDATE=0` 参数；legacy 实例即使不连接新 input，也因参数
  常量关闭而保持原行为。F1 wrapper 显式设为 1 并完整接线。
- bridge output assign 精确复用 `dcache_store_commit_w`、同一 local address/wstrb expression；
  不复刻 B/owner 判定。
- cache 计算 gated peer valid、首/次 line、lookup exact conflict；`lookup_hit_o` 增加 conflict
  negation，valid always block 中 peer clear 最后执行，DMA 外层优先级不变。
- wrapper 两套端口逐字段连接 bridge；两 raw AXI 全字段连接 F0；不得生成 lane READY/response mux。
- `OOO_ASSERT` 增加 peer same-cycle block、next-cycle valid clear、bridge authority equality、wrapper
  cross-wire/response independence 等局部断言。

## D. 行为与声明语言

可执行证据必须从真实 bridge miss/fill 建热，而不是直接 XMR 篡改 valid。双 hit 检查同拍 request
fire、无 downstream AR、同拍双 response 与 exact token；hit-under-miss 检查 F0 owner仍锁定而
peer bridge 完成；B/lookup 冲突检查绝不出现 stale response并随后从 AXI取 fresh data。mutation
必须保持编译/展开成功且由目标 oracle拒绝。

通过这些叶级证据后仍只能声明 `dual_bridge_cache_hit_leaf_verified`。未接 backend 的 wrapper、
复制 cache 容量和缺失 final-PA query/WB credit 使 DI-5、OOO-3、overall 与 PPA promotion保持关闭。
