`include "define.v"

module OooBranchTargetCache #(
  parameter INDEX_W = 4,
  parameter ENTRY_COUNT = (1 << INDEX_W)
) (
  input clk,
  input rst,
  input clear_i,

  input [`XLEN-1:0] lookup_branch_pc_i,
  input [`XLEN-1:0] lookup_target_pc_i,
  output [INDEX_W-1:0] lookup_idx_o,
  output lookup_hit_o,
  output [`XLEN-1:0] lookup_target_pc_o,
  output [`XLEN-1:0] lookup_next_pc_o,
  output [`INST_W-1:0] lookup_inst_o,

  input invalidate_all_i,
  input store_fire_i,
  input [`XLEN-1:0] store_addr_i,

  input capture_valid_i,
  input [`XLEN-1:0] capture_branch_pc_i,
  input [`XLEN-1:0] capture_target_pc_i,
  input [`XLEN-1:0] capture_next_pc_i,
  input [`INST_W-1:0] capture_inst_i
);

  reg valid_q [0:ENTRY_COUNT-1];
  reg [`XLEN-1:0] branch_pc_q [0:ENTRY_COUNT-1];
  reg [`XLEN-1:0] target_pc_q [0:ENTRY_COUNT-1];
  reg [`XLEN-1:0] next_pc_q [0:ENTRY_COUNT-1];
  reg [`INST_W-1:0] inst_q [0:ENTRY_COUNT-1];

  function same_fetch_word;
    input [`XLEN-1:0] lhs;
    input [`XLEN-1:0] rhs;
    begin
      same_fetch_word =
          lhs[`XLEN-1:`XLEN_BYTE_W] == rhs[`XLEN-1:`XLEN_BYTE_W];
    end
  endfunction

  wire [INDEX_W-1:0] capture_idx_w =
      capture_branch_pc_i[INDEX_W+1:2];
  wire [INDEX_W-1:0] lookup_idx_w =
      lookup_branch_pc_i[INDEX_W+1:2];

  assign lookup_idx_o = lookup_idx_w;
  assign lookup_hit_o =
      valid_q[lookup_idx_w] &&
      (branch_pc_q[lookup_idx_w] == lookup_branch_pc_i) &&
      (target_pc_q[lookup_idx_w] == lookup_target_pc_i);
  assign lookup_target_pc_o = target_pc_q[lookup_idx_w];
  assign lookup_next_pc_o = next_pc_q[lookup_idx_w];
  assign lookup_inst_o = inst_q[lookup_idx_w];

  integer reset_idx;
  integer invalidate_idx;

  always @(posedge clk) begin
    if (rst || clear_i) begin
      /* verilator lint_off BLKSEQ */
      for (reset_idx = 0; reset_idx < ENTRY_COUNT; reset_idx = reset_idx + 1) begin
        valid_q[reset_idx] = 1'b0;
        branch_pc_q[reset_idx] = {`XLEN{1'b0}};
        target_pc_q[reset_idx] = {`XLEN{1'b0}};
        next_pc_q[reset_idx] = {`XLEN{1'b0}};
        inst_q[reset_idx] = {`INST_W{1'b0}};
      end
      /* verilator lint_on BLKSEQ */
    end else if (invalidate_all_i) begin
      /* verilator lint_off BLKSEQ */
      for (invalidate_idx = 0; invalidate_idx < ENTRY_COUNT;
           invalidate_idx = invalidate_idx + 1) begin
        valid_q[invalidate_idx] = 1'b0;
      end
      /* verilator lint_on BLKSEQ */
    end else begin
      if (store_fire_i) begin
        /* verilator lint_off BLKSEQ */
        for (invalidate_idx = 0; invalidate_idx < ENTRY_COUNT;
             invalidate_idx = invalidate_idx + 1) begin
          if (valid_q[invalidate_idx] &&
              same_fetch_word(store_addr_i, target_pc_q[invalidate_idx])) begin
            valid_q[invalidate_idx] = 1'b0;
          end
        end
        /* verilator lint_on BLKSEQ */
      end

      if (capture_valid_i) begin
        if (!store_fire_i ||
            !same_fetch_word(store_addr_i, capture_target_pc_i)) begin
          valid_q[capture_idx_w] <= 1'b1;
          branch_pc_q[capture_idx_w] <= capture_branch_pc_i;
          target_pc_q[capture_idx_w] <= capture_target_pc_i;
          next_pc_q[capture_idx_w] <= capture_next_pc_i;
          inst_q[capture_idx_w] <= capture_inst_i;
        end
      end
    end
  end

endmodule
