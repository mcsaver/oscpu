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

  input [`XLEN-1:0] fifo_pc0_i,
  input [`XLEN-1:0] fifo_pc1_i,
  input [`XLEN-1:0] fifo_next_pc0_i,
  input [`XLEN-1:0] fifo_next_pc1_i,
  input [`XLEN-1:0] fifo_packet_next_pc_i,
  input [`INST_W-1:0] fifo_inst0_i,
  input [`INST_W-1:0] fifo_inst1_i,
  input [1:0] fifo_resp0_i,
  input [1:0] fifo_resp1_i,

  output head_has_packet_o,
  output [`XLEN-1:0] head_pc0_o,
  output [`XLEN-1:0] head_pc1_o,
  output [`XLEN-1:0] head_next_pc0_o,
  output [`XLEN-1:0] head_next_pc1_o,
  output [`XLEN-1:0] head_packet_next_pc_o,
  output [`INST_W-1:0] head_inst0_o,
  output [`INST_W-1:0] head_inst1_o,
  output [1:0] head_resp0_o,
  output [1:0] head_resp1_o
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

endmodule
