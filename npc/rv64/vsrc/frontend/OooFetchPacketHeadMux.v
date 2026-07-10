`include "define.v"

// Selects the dispatch-visible fetch packet head from response bypass or FIFO.
// Storage and flow-control decisions stay in OooCoreTopGlue.
module OooFetchPacketHeadMux (
  input bypass_valid_i,
  input fifo_head_valid_i,

  input [`XLEN-1:0] bypass_pc0_i,
  input [`XLEN-1:0] bypass_pc1_i,
  input [`XLEN-1:0] bypass_next_pc0_i,
  input [`XLEN-1:0] bypass_next_pc1_i,
  input [`XLEN-1:0] bypass_packet_next_pc_i,
  input [`INST_W-1:0] bypass_inst0_i,
  input [`INST_W-1:0] bypass_inst1_i,
  input [1:0] bypass_resp0_i,
  input [1:0] bypass_resp1_i,
  // 【B2 S1】per-slot 预测位管道化(bypass 臂上游 tie-0, 接 resp 拍 BPU 组合输出保同源)。
  input bypass_pred_taken0_i,
  input bypass_pred_taken1_i,
  input [`BPU_BHT_INDEX_W-1:0] bypass_bht_idx0_i,
  input [`BPU_BHT_INDEX_W-1:0] bypass_bht_idx1_i,
  input bypass_bht_valid0_i,
  input bypass_bht_valid1_i,
  // 【B2 S2】slot1 截断位管道化(bypass 臂上游 tie-0, 接 resp 拍组合输出保同源)。
  input bypass_slot1_valid_i,

  input [`XLEN-1:0] fifo_pc0_i,
  input [`XLEN-1:0] fifo_pc1_i,
  input [`XLEN-1:0] fifo_next_pc0_i,
  input [`XLEN-1:0] fifo_next_pc1_i,
  input [`XLEN-1:0] fifo_packet_next_pc_i,
  input [`INST_W-1:0] fifo_inst0_i,
  input [`INST_W-1:0] fifo_inst1_i,
  input [1:0] fifo_resp0_i,
  input [1:0] fifo_resp1_i,
  input fifo_pred_taken0_i,
  input fifo_pred_taken1_i,
  input [`BPU_BHT_INDEX_W-1:0] fifo_bht_idx0_i,
  input [`BPU_BHT_INDEX_W-1:0] fifo_bht_idx1_i,
  input fifo_bht_valid0_i,
  input fifo_bht_valid1_i,
  input fifo_slot1_valid_i,

  output head_has_packet_o,
  output [`XLEN-1:0] head_pc0_o,
  output [`XLEN-1:0] head_pc1_o,
  output [`XLEN-1:0] head_next_pc0_o,
  output [`XLEN-1:0] head_next_pc1_o,
  output [`XLEN-1:0] head_packet_next_pc_o,
  output [`INST_W-1:0] head_inst0_o,
  output [`INST_W-1:0] head_inst1_o,
  output [1:0] head_resp0_o,
  output [1:0] head_resp1_o,
  output head_pred_taken0_o,
  output head_pred_taken1_o,
  output [`BPU_BHT_INDEX_W-1:0] head_bht_idx0_o,
  output [`BPU_BHT_INDEX_W-1:0] head_bht_idx1_o,
  output head_bht_valid0_o,
  output head_bht_valid1_o,
  output head_slot1_valid_o
);

  assign head_has_packet_o = bypass_valid_i || fifo_head_valid_i;
  assign head_pc0_o = bypass_valid_i ? bypass_pc0_i : fifo_pc0_i;
  assign head_pc1_o = bypass_valid_i ? bypass_pc1_i : fifo_pc1_i;
  assign head_next_pc0_o = bypass_valid_i ? bypass_next_pc0_i :
                                            fifo_next_pc0_i;
  assign head_next_pc1_o = bypass_valid_i ? bypass_next_pc1_i :
                                            fifo_next_pc1_i;
  assign head_packet_next_pc_o = bypass_valid_i ? bypass_packet_next_pc_i :
                                                  fifo_packet_next_pc_i;
  assign head_inst0_o = bypass_valid_i ? bypass_inst0_i : fifo_inst0_i;
  assign head_inst1_o = bypass_valid_i ? bypass_inst1_i : fifo_inst1_i;
  assign head_resp0_o = bypass_valid_i ? bypass_resp0_i : fifo_resp0_i;
  assign head_resp1_o = bypass_valid_i ? bypass_resp1_i : fifo_resp1_i;
  assign head_pred_taken0_o = bypass_valid_i ? bypass_pred_taken0_i :
                                               fifo_pred_taken0_i;
  assign head_pred_taken1_o = bypass_valid_i ? bypass_pred_taken1_i :
                                               fifo_pred_taken1_i;
  assign head_bht_idx0_o = bypass_valid_i ? bypass_bht_idx0_i :
                                            fifo_bht_idx0_i;
  assign head_bht_idx1_o = bypass_valid_i ? bypass_bht_idx1_i :
                                            fifo_bht_idx1_i;
  assign head_bht_valid0_o = bypass_valid_i ? bypass_bht_valid0_i :
                                              fifo_bht_valid0_i;
  assign head_bht_valid1_o = bypass_valid_i ? bypass_bht_valid1_i :
                                              fifo_bht_valid1_i;
  assign head_slot1_valid_o = bypass_valid_i ? bypass_slot1_valid_i :
                                               fifo_slot1_valid_i;

endmodule
