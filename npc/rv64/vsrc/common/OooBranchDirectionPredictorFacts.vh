`ifndef __NPC_RV64_OOO_BRANCH_DIRECTION_PREDICTOR_FACTS_VH__
`define __NPC_RV64_OOO_BRANCH_DIRECTION_PREDICTOR_FACTS_VH__

// OoO branch direction predictor 外部观测 facts。
// 归属：OooBranchDirectionPredictor 的 debug/common 三层观测模型第 3 层。
// 用途：给仿真 checker 和 focused TB 一个稳定的语义位号表，不规定预测表的物理编码。

`define OOO_BPU_LOOKUP0_VALID          0  // lookup0 命中已训练 gshare BHT entry
`define OOO_BPU_LOOKUP0_TAKEN          1  // lookup0 最终方向预测
`define OOO_BPU_LOOKUP0_STRONG         2  // lookup0 gshare/local 至少一侧为强计数器
`define OOO_BPU_LOOKUP1_VALID          3  // lookup1 命中已训练 gshare BHT entry
`define OOO_BPU_LOOKUP1_TAKEN          4  // lookup1 最终方向预测
`define OOO_BPU_LOOKUP1_STRONG         5  // lookup1 gshare/local 至少一侧为强计数器
`define OOO_BPU_UPDATE                 6  // issue-resolve 单源更新
`define OOO_BPU_UPDATE_TAKEN           7  // update 真实方向
`define OOO_BPU_CLEAR                  8  // clear_i/预测边界清表
`define OOO_BPU_LOOKUP0_STATIC_TAKEN   9  // lookup0 静态 backward-taken fallback
`define OOO_BPU_LOOKUP1_STATIC_TAKEN  10  // lookup1 静态 backward-taken fallback
`define OOO_BPU_FACTS_W               11

`endif
