`ifndef __NPC_RV64_OOO_DATA_WORD_CACHE_FACTS_VH__
`define __NPC_RV64_OOO_DATA_WORD_CACHE_FACTS_VH__

// OoO D-cache 外部观测 facts。
// 归属：OooDataWordCache 的 debug/common 三层观测模型第 3 层。
// 用途：给仿真 checker 和 focused TB 一个稳定的语义位号表，不规定综合 RTL 的物理编码。
//
// 【SRAM 同步读参照系】读口为单口两拍协议：LOOKUP_ISSUE 在发射拍(en=1)，
// LOOKUP_HIT/LOOKUP_MISS 在次拍(判决拍)、针对上拍锁存的 lookup 地址。
// 原 REQ_HIT/WALK_HIT 双组合视图随 req/walk 读口合并为单 lookup 口而统一；
// 跨线阻断与窗口移位职责移至桥判决拍(read_cross_q/paddr_q[2:0])。
// REQ_UNCACHED/REQ_LINE_CROSS 仍是纯地址 0-cycle 组合视图。
//
// 【store RMW 参照系(2026-07-09 write-update 赎回)】真 store commit 走 2 拍
// RMW：STORE_RMW_ISSUE 在 commit 拍(占宏口读)，STORE_RMW_BUSY 在次拍(判决拍，
// 占宏口判 tag/写 data 字节，桥须压 req_ready)。A/D PTE 写回维护路
// (store_rmw_en=0)保持无条件失效，无 RMW 两拍窗口。

`define OOO_DWC_REQ_UNCACHED       0  // req 地址不在 PMEM cacheable 窗口(组合)
`define OOO_DWC_REQ_LINE_CROSS     1  // req 字节窗口跨 8B line(组合), 桥侧必按 miss 处理且不 fill
`define OOO_DWC_LOOKUP_ISSUE       2  // 单读口发射拍(lookup_en), 次拍判决
`define OOO_DWC_LOOKUP_HIT         3  // 判决拍命中(锁存地址 cacheable+valid+tag)
`define OOO_DWC_LOOKUP_MISS        4  // 判决拍未命中
`define OOO_DWC_FILL               5  // 对齐 8B line fill(全 1 掩码整行写)
`define OOO_DWC_STORE_COMMIT       6  // store/A-D 写回维护拍(RMW 发射或无条件失效)
`define OOO_DWC_STORE_LINE_CROSS   7  // store 字节窗口跨 8B line: p1 行保守失效
`define OOO_DWC_STORE_RMW_ISSUE    8  // 真 store commit 拍(RMW 发射, 占宏口读 st_idx)
`define OOO_DWC_STORE_RMW_BUSY     9  // RMW 判决拍(占宏口, 桥压 req_ready=store 后 1 bubble)
`define OOO_DWC_DMA_INVALIDATE_ALL 10 // 同步 DMA batch 完成后的全 valid 清除事件
`define OOO_DWC_PEER_INVALIDATE    11 // 已授权 peer B-terminal valid-only 维护事件
`define OOO_DWC_PEER_LINE_CROSS    12 // peer 规范化 byte window 跨到相邻 8B line
`define OOO_DWC_FACTS_W            13

`endif
