`include "define.v"

module OooDirectBranchWaitBuffer (
  input clk,
  input rst,

  input clear_i,

  input resolve_match_i,

  input branch_fire_i,
  input branch_resolve_valid_i,
  input [`XLEN-1:0] branch_pc_i,

  output pending_o,
  output [`XLEN-1:0] pc_o
);

  reg pending_q;
  reg [`XLEN-1:0] pc_q;

  assign pending_o = pending_q;
  assign pc_o = pc_q;

  always @(posedge clk) begin
    if (rst || clear_i) begin
      pending_q <= 1'b0;
      pc_q <= {`XLEN{1'b0}};
    end else begin
      if (resolve_match_i) begin
        pending_q <= 1'b0;
        pc_q <= {`XLEN{1'b0}};
      end
      if (branch_fire_i) begin
        pending_q <= !branch_resolve_valid_i;
        pc_q <= branch_resolve_valid_i ? {`XLEN{1'b0}} : branch_pc_i;
      end
    end
  end

endmodule
