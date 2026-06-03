`include "define.v"

module OooJalrBtb (
  input clk,
  input rst,
  input clear_i,

  input lookup_enable_i,
  input [`XLEN-1:0] lookup_pc_i,
  output [`BPU_BTB_INDEX_W-1:0] lookup_idx_o,
  output lookup_entry_hit_o,
  output lookup_hit_o,
  output [`XLEN-1:0] lookup_target_o,

  input update_valid_i,
  input [`XLEN-1:0] update_pc_i,
  input [`XLEN-1:0] update_target_i
);

  reg valid_q [0:`BPU_BTB_ENTRIES-1];
  reg [`XLEN-1:0] pc_q [0:`BPU_BTB_ENTRIES-1];
  reg [`XLEN-1:0] target_q [0:`BPU_BTB_ENTRIES-1];

  wire [`BPU_BTB_INDEX_W-1:0] update_idx_w =
      update_pc_i[`BPU_BTB_INDEX_W:1];
  wire [`BPU_BTB_INDEX_W-1:0] lookup_idx_w =
      lookup_pc_i[`BPU_BTB_INDEX_W:1];

  assign lookup_idx_o = lookup_idx_w;
  assign lookup_entry_hit_o =
      valid_q[lookup_idx_w] && (pc_q[lookup_idx_w] == lookup_pc_i);
  assign lookup_hit_o = lookup_enable_i && lookup_entry_hit_o;
  assign lookup_target_o = target_q[lookup_idx_w];

  integer reset_idx;

  always @(posedge clk) begin
    if (rst || clear_i) begin
      /* verilator lint_off BLKSEQ */
      for (reset_idx = 0; reset_idx < `BPU_BTB_ENTRIES;
           reset_idx = reset_idx + 1) begin
        valid_q[reset_idx] = 1'b0;
        pc_q[reset_idx] = {`XLEN{1'b0}};
        target_q[reset_idx] = {`XLEN{1'b0}};
      end
      /* verilator lint_on BLKSEQ */
    end else if (update_valid_i) begin
      valid_q[update_idx_w] <= 1'b1;
      pc_q[update_idx_w] <= update_pc_i;
      target_q[update_idx_w] <= update_target_i;
    end
  end

endmodule
