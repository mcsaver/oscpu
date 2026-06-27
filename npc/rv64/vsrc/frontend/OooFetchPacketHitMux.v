`include "define.v"

// Selects a prefetch-hit packet from same-cycle response capture or buffer.
module OooFetchPacketHitMux (
  input rsp_select_i,

  input [`XLEN-1:0] rsp_pc0_i,
  input [`XLEN-1:0] rsp_pc1_i,
  input [`XLEN-1:0] rsp_next_pc0_i,
  input [`XLEN-1:0] rsp_next_pc1_i,
  input [`XLEN-1:0] rsp_packet_next_pc_i,
  input [`INST_W-1:0] rsp_inst0_i,
  input [`INST_W-1:0] rsp_inst1_i,
  input [1:0] rsp_resp0_i,
  input [1:0] rsp_resp1_i,

  input [`XLEN-1:0] buf_pc0_i,
  input [`XLEN-1:0] buf_pc1_i,
  input [`XLEN-1:0] buf_next_pc0_i,
  input [`XLEN-1:0] buf_next_pc1_i,
  input [`XLEN-1:0] buf_packet_next_pc_i,
  input [`INST_W-1:0] buf_inst0_i,
  input [`INST_W-1:0] buf_inst1_i,
  input [1:0] buf_resp0_i,
  input [1:0] buf_resp1_i,

  output [`XLEN-1:0] hit_pc0_o,
  output [`XLEN-1:0] hit_pc1_o,
  output [`XLEN-1:0] hit_next_pc0_o,
  output [`XLEN-1:0] hit_next_pc1_o,
  output [`XLEN-1:0] hit_packet_next_pc_o,
  output [`INST_W-1:0] hit_inst0_o,
  output [`INST_W-1:0] hit_inst1_o,
  output [1:0] hit_resp0_o,
  output [1:0] hit_resp1_o
);

  assign hit_pc0_o = rsp_select_i ? rsp_pc0_i : buf_pc0_i;
  assign hit_pc1_o = rsp_select_i ? rsp_pc1_i : buf_pc1_i;
  assign hit_next_pc0_o = rsp_select_i ? rsp_next_pc0_i : buf_next_pc0_i;
  assign hit_next_pc1_o = rsp_select_i ? rsp_next_pc1_i : buf_next_pc1_i;
  assign hit_packet_next_pc_o = rsp_select_i ? rsp_packet_next_pc_i :
                                               buf_packet_next_pc_i;
  assign hit_inst0_o = rsp_select_i ? rsp_inst0_i : buf_inst0_i;
  assign hit_inst1_o = rsp_select_i ? rsp_inst1_i : buf_inst1_i;
  assign hit_resp0_o = rsp_select_i ? rsp_resp0_i : buf_resp0_i;
  assign hit_resp1_o = rsp_select_i ? rsp_resp1_i : buf_resp1_i;

endmodule

