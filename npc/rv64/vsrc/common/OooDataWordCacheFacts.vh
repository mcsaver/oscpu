`ifndef __NPC_RV64_OOO_DATA_WORD_CACHE_FACTS_VH__
`define __NPC_RV64_OOO_DATA_WORD_CACHE_FACTS_VH__

// OoO D-cache 外部观测 facts。
// 归属：OooDataWordCache 的 debug/common 三层观测模型第 3 层。
// 用途：给仿真 checker 和 focused TB 一个稳定的语义位号表，不规定综合 RTL 的物理编码。

`define OOO_DWC_REQ_UNCACHED       0  // req 地址不在 PMEM cacheable 窗口
`define OOO_DWC_REQ_LINE_CROSS     1  // req 字节窗口跨 8B line，必须 miss 且桥侧不 fill
`define OOO_DWC_REQ_HIT            2  // req 命中当前 line
`define OOO_DWC_REQ_MISS           3  // req cacheable 且未命中或跨线
`define OOO_DWC_WALK_HIT           4  // PTW leaf PTE 8B 读命中 D-cache
`define OOO_DWC_WALK_MISS          5  // PTW leaf PTE cacheable 但未命中
`define OOO_DWC_FILL               6  // 对齐 8B line fill
`define OOO_DWC_STORE_COMMIT       7  // 已提交 store 或 A/D 写回维护 D-cache
`define OOO_DWC_STORE_LINE_CROSS   8  // store 字节窗口跨 8B line，保守失效两线
`define OOO_DWC_INVALIDATE_ALL     9  // 全失效维护事件
`define OOO_DWC_FACTS_W           10

`endif
