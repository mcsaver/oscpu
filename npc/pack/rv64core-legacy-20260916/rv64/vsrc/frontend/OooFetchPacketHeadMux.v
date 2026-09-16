`include "define.v"
`include "common/OooSlotFacts.v"

// Exposes the registered FIFO packet to dispatch.  The response-bypass arm was
// structurally unreachable in the production ROB-walk configuration and is
// physically removed so hierarchy-preserving synthesis cannot retain its muxes.
module OooFetchPacketHeadMux (
  input fifo_head_valid_i,

  input [`XLEN-1:0] fifo_pc0_i,
  input [`XLEN-1:0] fifo_pc1_i,
  input [`XLEN-1:0] fifo_next_pc0_i,
  input [`XLEN-1:0] fifo_next_pc1_i,
  input [`XLEN-1:0] fifo_packet_next_pc_i,
  input [`INST_W-1:0] fifo_inst0_i,
  input [`INST_W-1:0] fifo_inst1_i,
  input [`CTRL_BUS_W-1:0] fifo_ctrl0_i,
  input [`CTRL_BUS_W-1:0] fifo_ctrl1_i,
  input [`OOO_SLOT_STATIC_FACTS_W-1:0] fifo_static_facts0_i,
  input [`OOO_SLOT_STATIC_FACTS_W-1:0] fifo_static_facts1_i,
  input [`REG_ADDR_W-1:0] fifo_rs1_0_i,
  input [`REG_ADDR_W-1:0] fifo_rs2_0_i,
  input [`REG_ADDR_W-1:0] fifo_rd0_i,
  input [`XLEN-1:0] fifo_imm0_i,
  input [`REG_ADDR_W-1:0] fifo_rs1_1_i,
  input [`REG_ADDR_W-1:0] fifo_rs2_1_i,
  input [`REG_ADDR_W-1:0] fifo_rd1_i,
  input [`XLEN-1:0] fifo_imm1_i,
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
  output [`CTRL_BUS_W-1:0] head_ctrl0_o,
  output [`CTRL_BUS_W-1:0] head_ctrl1_o,
  output [`OOO_SLOT_STATIC_FACTS_W-1:0] head_static_facts0_o,
  output [`OOO_SLOT_STATIC_FACTS_W-1:0] head_static_facts1_o,
  output [`REG_ADDR_W-1:0] head_rs1_0_o,
  output [`REG_ADDR_W-1:0] head_rs2_0_o,
  output [`REG_ADDR_W-1:0] head_rd0_o,
  output [`XLEN-1:0] head_imm0_o,
  output [`REG_ADDR_W-1:0] head_rs1_1_o,
  output [`REG_ADDR_W-1:0] head_rs2_1_o,
  output [`REG_ADDR_W-1:0] head_rd1_o,
  output [`XLEN-1:0] head_imm1_o,
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

  assign head_has_packet_o = fifo_head_valid_i;
  assign head_pc0_o = fifo_pc0_i;
  assign head_pc1_o = fifo_pc1_i;
  assign head_next_pc0_o = fifo_next_pc0_i;
  assign head_next_pc1_o = fifo_next_pc1_i;
  assign head_packet_next_pc_o = fifo_packet_next_pc_i;
  assign head_inst0_o = fifo_inst0_i;
  assign head_inst1_o = fifo_inst1_i;
  assign head_ctrl0_o = fifo_ctrl0_i;
  assign head_ctrl1_o = fifo_ctrl1_i;
  assign head_static_facts0_o = fifo_static_facts0_i;
  assign head_static_facts1_o = fifo_static_facts1_i;
  assign head_rs1_0_o = fifo_rs1_0_i;
  assign head_rs2_0_o = fifo_rs2_0_i;
  assign head_rd0_o = fifo_rd0_i;
  assign head_imm0_o = fifo_imm0_i;
  assign head_rs1_1_o = fifo_rs1_1_i;
  assign head_rs2_1_o = fifo_rs2_1_i;
  assign head_rd1_o = fifo_rd1_i;
  assign head_imm1_o = fifo_imm1_i;
  assign head_resp0_o = fifo_resp0_i;
  assign head_resp1_o = fifo_resp1_i;
  assign head_pred_taken0_o = fifo_pred_taken0_i;
  assign head_pred_taken1_o = fifo_pred_taken1_i;
  assign head_bht_idx0_o = fifo_bht_idx0_i;
  assign head_bht_idx1_o = fifo_bht_idx1_i;
  assign head_bht_valid0_o = fifo_bht_valid0_i;
  assign head_bht_valid1_o = fifo_bht_valid1_i;
  assign head_slot1_valid_o = fifo_slot1_valid_i;

endmodule
