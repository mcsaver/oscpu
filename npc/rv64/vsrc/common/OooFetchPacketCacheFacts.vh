`ifndef __NPC_RV64_OOO_FETCH_PACKET_CACHE_FACTS_VH__
`define __NPC_RV64_OOO_FETCH_PACKET_CACHE_FACTS_VH__

// OoO fetch packet cache 外部观测 facts。
// 归属：OooFetchPacketCache 的 debug/common 三层观测模型第 3 层。
// 用途：给仿真 checker 和 focused TB 一个稳定的语义位号表，不规定综合 RTL 的物理编码。
// 参照系(SRAM 同步读两拍协议)：LOOKUP_READ 是物理 SRAM 读窗，LOOKUP_ACCEPT 是
// 语义请求 accept；lookup 命中类 facts 在判决拍(LOOKUP_ACCEPT 的次拍)投影，针对
// accept 拍锁存的请求；fill/invalidate/clear 类 facts 仍在请求当拍投影。

`define OOO_FPC_LOOKUP_CONTEXT_HIT      0  // index/context 命中(判决拍, 对 accept 拍锁存请求)
`define OOO_FPC_LOOKUP_HIT              1  // context + exact PC + 两拍窗口无 store footprint(判决拍)
`define OOO_FPC_LOOKUP_INVALIDATED      2  // 锁存 lookup PC 与 accept 拍或判决拍 store footprint 重叠
`define OOO_FPC_FILL                    3  // fill 请求
`define OOO_FPC_FILL_BLOCKED_BY_STORE   4  // fill PC 与同拍 store footprint 重叠，fill 必须被阻止
`define OOO_FPC_INVALIDATE              5  // store-driven invalidate 请求(盲失效 7 邻域 index)
`define OOO_FPC_CLEAR                   6  // clear_i/fence.i/sfence/satp 类整体失效
`define OOO_FPC_PAGED_LOOKUP            7  // lookup 使用 paging context(accept 拍输入投影)
`define OOO_FPC_BARE_LOOKUP             8  // lookup bare mode，不比较 priv/satp(accept 拍输入投影)
`define OOO_FPC_LOOKUP_READ             9  // 物理 SRAM 同步读窗；允许没有语义 accept 的 dummy read
`define OOO_FPC_LOOKUP_ACCEPT          10  // 语义请求 accept；必须蕴含 LOOKUP_READ
`define OOO_FPC_FACTS_W                11

`endif
