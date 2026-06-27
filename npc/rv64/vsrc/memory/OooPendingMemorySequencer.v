`include "define.v"

module OooPendingMemorySequencer (
  input clk,
  input rst,

  input late_clear_i,
  input clear_i,
  input clear_dispatched_i,
  input dispatch_fire_i,

  input capture_lane1_i,
  input capture_valid_i,
  input [`XLEN-1:0] capture_pc_i,
  input [`INST_W-1:0] capture_inst_i,
  input [`XLEN-1:0] capture_next_pc_i,

  output valid_o,
  output dispatched_o,
  output [`XLEN-1:0] pc_o,
  output [`INST_W-1:0] inst_o,
  output [`XLEN-1:0] next_pc_o
);

  reg valid_q;
  reg dispatched_q;
  reg [`XLEN-1:0] pc_q;
  reg [`INST_W-1:0] inst_q;
  reg [`XLEN-1:0] next_pc_q;

  always @(posedge clk) begin
    if (rst) begin
      valid_q <= 1'b0;
      dispatched_q <= 1'b0;
      pc_q <= {`XLEN{1'b0}};
      inst_q <= {`INST_W{1'b0}};
      next_pc_q <= {`XLEN{1'b0}};
    end else if (late_clear_i) begin
      valid_q <= 1'b0;
      dispatched_q <= 1'b0;
      next_pc_q <= {`XLEN{1'b0}};
    end else if (capture_lane1_i) begin
      valid_q <= capture_valid_i;
      dispatched_q <= 1'b0;
      pc_q <= capture_pc_i;
      inst_q <= capture_inst_i;
      next_pc_q <= capture_next_pc_i;
    end else if (clear_i) begin
      valid_q <= 1'b0;
      dispatched_q <= 1'b0;
      next_pc_q <= {`XLEN{1'b0}};
    end else if (dispatch_fire_i) begin
      dispatched_q <= 1'b1;
    end else if (clear_dispatched_i) begin
      dispatched_q <= 1'b0;
    end
  end

  assign valid_o = valid_q;
  assign dispatched_o = dispatched_q;
  assign pc_o = pc_q;
  assign inst_o = inst_q;
  assign next_pc_o = next_pc_q;

endmodule
