`include "define.v"

module OooBranchPrefetchBuffer (
  input clk,
  input rst,

  input clear_i,

  input req_fire_i,
  input [`XLEN-1:0] req_pc_i,

  input rsp_capture_i,
  input [`XLEN-1:0] rsp_pc0_i,
  input [`XLEN-1:0] rsp_pc1_i,
  input [`XLEN-1:0] rsp_next_pc0_i,
  input [`XLEN-1:0] rsp_next_pc1_i,
  input [`XLEN-1:0] rsp_packet_next_pc_i,
  input [`INST_W-1:0] rsp_inst0_i,
  input [`INST_W-1:0] rsp_inst1_i,
  input [1:0] rsp_resp0_i,
  input [1:0] rsp_resp1_i,

  output active_o,
  output buffer_valid_o,
  output [`XLEN-1:0] pc_o,
  output [`XLEN-1:0] buf_pc0_o,
  output [`XLEN-1:0] buf_pc1_o,
  output [`XLEN-1:0] buf_next_pc0_o,
  output [`XLEN-1:0] buf_next_pc1_o,
  output [`XLEN-1:0] buf_packet_next_pc_o,
  output [`INST_W-1:0] buf_inst0_o,
  output [`INST_W-1:0] buf_inst1_o,
  output [1:0] buf_resp0_o,
  output [1:0] buf_resp1_o
);

  reg active_q;
  reg buffer_valid_q;
  reg [`XLEN-1:0] pc_q;
  reg [`XLEN-1:0] buf_pc0_q;
  reg [`XLEN-1:0] buf_pc1_q;
  reg [`XLEN-1:0] buf_next_pc0_q;
  reg [`XLEN-1:0] buf_next_pc1_q;
  reg [`XLEN-1:0] buf_packet_next_pc_q;
  reg [`INST_W-1:0] buf_inst0_q;
  reg [`INST_W-1:0] buf_inst1_q;
  reg [1:0] buf_resp0_q;
  reg [1:0] buf_resp1_q;

  assign active_o = active_q;
  assign buffer_valid_o = buffer_valid_q;
  assign pc_o = pc_q;
  assign buf_pc0_o = buf_pc0_q;
  assign buf_pc1_o = buf_pc1_q;
  assign buf_next_pc0_o = buf_next_pc0_q;
  assign buf_next_pc1_o = buf_next_pc1_q;
  assign buf_packet_next_pc_o = buf_packet_next_pc_q;
  assign buf_inst0_o = buf_inst0_q;
  assign buf_inst1_o = buf_inst1_q;
  assign buf_resp0_o = buf_resp0_q;
  assign buf_resp1_o = buf_resp1_q;

  always @(posedge clk) begin
    if (rst) begin
      active_q <= 1'b0;
      buffer_valid_q <= 1'b0;
      pc_q <= {`XLEN{1'b0}};
      buf_pc0_q <= {`XLEN{1'b0}};
      buf_pc1_q <= {`XLEN{1'b0}};
      buf_next_pc0_q <= {`XLEN{1'b0}};
      buf_next_pc1_q <= {`XLEN{1'b0}};
      buf_packet_next_pc_q <= {`XLEN{1'b0}};
      buf_inst0_q <= {`INST_W{1'b0}};
      buf_inst1_q <= {`INST_W{1'b0}};
      buf_resp0_q <= 2'b00;
      buf_resp1_q <= 2'b00;
    end else if (clear_i) begin
      active_q <= 1'b0;
      buffer_valid_q <= 1'b0;
      pc_q <= {`XLEN{1'b0}};
    end else begin
      if (req_fire_i) begin
        active_q <= 1'b1;
        buffer_valid_q <= 1'b0;
        pc_q <= req_pc_i;
      end
      if (rsp_capture_i) begin
        buffer_valid_q <= 1'b1;
        buf_pc0_q <= rsp_pc0_i;
        buf_pc1_q <= rsp_pc1_i;
        buf_next_pc0_q <= rsp_next_pc0_i;
        buf_next_pc1_q <= rsp_next_pc1_i;
        buf_packet_next_pc_q <= rsp_packet_next_pc_i;
        buf_inst0_q <= rsp_inst0_i;
        buf_inst1_q <= rsp_inst1_i;
        buf_resp0_q <= rsp_resp0_i;
        buf_resp1_q <= rsp_resp1_i;
      end
    end
  end

endmodule
