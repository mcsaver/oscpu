`include "define.v"

module OooReturnContBuffer (
  input clk,
  input rst,

  input clear_i,
  input consume_i,

  input capture_i,
  input capture_valid_i,
  input [`XLEN-1:0] capture_pc_i,
  input [`XLEN-1:0] capture_next_pc_i,
  input [`INST_W-1:0] capture_inst_i,

  output valid_o,
  output [`XLEN-1:0] pc_o,
  output [`XLEN-1:0] next_pc_o,
  output [`INST_W-1:0] inst_o
);

  reg valid_q;
  reg [`XLEN-1:0] pc_q;
  reg [`XLEN-1:0] next_pc_q;
  reg [`INST_W-1:0] inst_q;

  assign valid_o = valid_q;
  assign pc_o = pc_q;
  assign next_pc_o = next_pc_q;
  assign inst_o = inst_q;

  always @(posedge clk) begin
    if (rst || clear_i) begin
      valid_q <= 1'b0;
      pc_q <= {`XLEN{1'b0}};
      next_pc_q <= {`XLEN{1'b0}};
      inst_q <= {`INST_W{1'b0}};
    end else if (capture_i) begin
      valid_q <= capture_valid_i;
      pc_q <= capture_valid_i ? capture_pc_i : {`XLEN{1'b0}};
      next_pc_q <= capture_valid_i ? capture_next_pc_i : {`XLEN{1'b0}};
      inst_q <= capture_valid_i ? capture_inst_i : {`INST_W{1'b0}};
    end else if (consume_i) begin
      valid_q <= 1'b0;
      pc_q <= {`XLEN{1'b0}};
      next_pc_q <= {`XLEN{1'b0}};
      inst_q <= {`INST_W{1'b0}};
    end
  end

endmodule
