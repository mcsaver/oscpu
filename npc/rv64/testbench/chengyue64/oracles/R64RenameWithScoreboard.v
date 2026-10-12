// Test-only adapter joining production mapping and execution scoreboard.
// Frozen pre-domain scoreboard owner: verification oracle only.
// Native two-wide GPR/FPR rename state. All state changes consume explicit
// shared ROB allocation/retirement/undo events. Six source descriptors cover
// three FP operands per uop; integer execution still has four GPR read ports.
module R64RenameWithScoreboard #(
  parameter PREG_W = 6,
  parameter PREG_N = (1 << PREG_W)
) (
  input                 clk,
  input                 rst,
  input                 restore_i,
  input  [         1:0] request_valid_i,
  input  [         1:0] rd_write_i,
  input  [         1:0] rd_fp_i,
  input  [         9:0] rd_arch_i,
  input  [        29:0] src_arch_i,
  input  [         5:0] src_fp_i,
  input  [         5:0] src_used_i,
  output [         1:0] alloc_ready_o,
  output [2*PREG_W-1:0] pnew_o,
  output [2*PREG_W-1:0] pold_o,
  output [6*PREG_W-1:0] src_preg_o,
  output [         5:0] src_ready_o,
  // Probes use physical identities fixed by a previous atomic birth.
  input  [6*PREG_W-1:0] ready_query_preg_i,
  input  [         5:0] ready_query_fp_i,
  output [         5:0] ready_query_ready_o,
  input  [         1:0] alloc_fire_i,
  input  [         1:0] wb_accept_i,
  input  [         1:0] wb_fp_i,
  input  [2*PREG_W-1:0] wb_preg_i,
  input  [         1:0] commit_fire_i,
  input  [         1:0] commit_rd_write_i,
  input  [         1:0] commit_rd_fp_i,
  input  [         9:0] commit_rd_arch_i,
  input  [2*PREG_W-1:0] commit_pnew_i,
  input  [2*PREG_W-1:0] commit_pold_i,
  input  [         1:0] undo_valid_i,
  input  [         1:0] undo_rd_write_i,
  input  [         1:0] undo_rd_fp_i,
  input  [         9:0] undo_rd_arch_i,
  input  [2*PREG_W-1:0] undo_pnew_i,
  input  [2*PREG_W-1:0] undo_pold_i
);
  R64Rename #(.PREG_W(PREG_W),.PREG_N(PREG_N)) mapping (
    .batch_apply_i(1'b0),.batch_mask_i('0),.batch_head_i('0),.batch_desc_i('0),.batch_greclaim_o(),.batch_freclaim_o(),

    .clk(clk), .rst(rst),
    .restore_i(restore_i),
    .request_valid_i(request_valid_i),
    .rd_write_i(rd_write_i),
    .rd_fp_i(rd_fp_i),
    .rd_arch_i(rd_arch_i),
    .src_arch_i(src_arch_i),
    .src_fp_i(src_fp_i),
    .src_used_i(src_used_i),
    .alloc_ready_o(alloc_ready_o),
    .pnew_o(pnew_o),
    .pold_o(pold_o),
    .src_preg_o(src_preg_o),
    .alloc_fire_i(alloc_fire_i),
    .commit_fire_i(commit_fire_i),
    .commit_rd_write_i(commit_rd_write_i),
    .commit_rd_fp_i(commit_rd_fp_i),
    .commit_rd_arch_i(commit_rd_arch_i),
    .commit_pnew_i(commit_pnew_i),
    .commit_pold_i(commit_pold_i),
    .undo_valid_i(undo_valid_i),
    .undo_rd_write_i(undo_rd_write_i),
    .undo_rd_fp_i(undo_rd_fp_i),
    .undo_rd_arch_i(undo_rd_arch_i),
    .undo_pnew_i(undo_pnew_i),
    .undo_pold_i(undo_pold_i)
  );
  wire [1:0] birth_write, reclaim_write;
  wire [11:0] ready;
  generate
    for (genvar lane=0; lane<2; lane=lane+1) begin : gen_event
      assign birth_write[lane]=alloc_fire_i[lane] && rd_write_i[lane] &&
          (rd_fp_i[lane] || rd_arch_i[lane*5+:5] != 0);
      assign reclaim_write[lane]=undo_valid_i[lane] && undo_rd_write_i[lane] &&
          (undo_rd_fp_i[lane] || undo_rd_arch_i[lane*5+:5] != 0);
    end
    for (genvar src=0; src<6; src=src+1) begin : gen_ready
      wire pair_raw=src>=3 && request_valid_i[0] && rd_write_i[0] &&
          (rd_fp_i[0] || rd_arch_i[4:0] != 0) &&
          src_arch_i[src*5+:5] == rd_arch_i[4:0] && src_fp_i[src] == rd_fp_i[0];
      assign src_ready_o[src]=!src_used_i[src] ||
          (!src_fp_i[src] && src_arch_i[src*5+:5] == 0) || (!pair_raw && ready[src]);
    end
  endgenerate
  R64Scoreboard #(.PREG_W(PREG_W),.PREG_N(PREG_N),.QUERIES(12)) scoreboard (
    .batch_apply_i(1'b0),.batch_greclaim_i('0),.batch_freclaim_i('0),

    .clk(clk),.rst(rst),.flush_i(restore_i),
    .birth_write_i(birth_write),.birth_fp_i(rd_fp_i),.birth_preg_i(pnew_o),
    .wb_write_i(wb_accept_i),.wb_fp_i(wb_fp_i),.wb_preg_i(wb_preg_i),
    .reclaim_write_i(reclaim_write),.reclaim_fp_i(undo_rd_fp_i),.reclaim_preg_i(undo_pnew_i),
    .query_preg_i({ready_query_preg_i,src_preg_o}),.query_fp_i({ready_query_fp_i,src_fp_i}),
    .query_ready_o(ready)
  );
  assign ready_query_ready_o=ready[11:6];
  wire [1:0] reference_alloc_ready_o;
  wire [2*PREG_W-1:0] reference_pnew_o;
  wire [2*PREG_W-1:0] reference_pold_o;
  wire [6*PREG_W-1:0] reference_src_preg_o;
  wire [5:0] reference_src_ready_o;
  wire [5:0] reference_ready_query_ready_o;
  R64RenameReference #(.PREG_W(PREG_W),.PREG_N(PREG_N)) reference (
    .clk(clk), .rst(rst),
    .restore_i(restore_i),
    .request_valid_i(request_valid_i),
    .rd_write_i(rd_write_i),
    .rd_fp_i(rd_fp_i),
    .rd_arch_i(rd_arch_i),
    .src_arch_i(src_arch_i),
    .src_fp_i(src_fp_i),
    .src_used_i(src_used_i),
    .alloc_ready_o(reference_alloc_ready_o),
    .pnew_o(reference_pnew_o),
    .pold_o(reference_pold_o),
    .src_preg_o(reference_src_preg_o),
    .src_ready_o(reference_src_ready_o),
    .ready_query_preg_i(ready_query_preg_i),
    .ready_query_fp_i(ready_query_fp_i),
    .ready_query_ready_o(reference_ready_query_ready_o),
    .alloc_fire_i(alloc_fire_i),
    .wb_accept_i(wb_accept_i),
    .wb_fp_i(wb_fp_i),
    .wb_preg_i(wb_preg_i),
    .commit_fire_i(commit_fire_i),
    .commit_rd_write_i(commit_rd_write_i),
    .commit_rd_fp_i(commit_rd_fp_i),
    .commit_rd_arch_i(commit_rd_arch_i),
    .commit_pnew_i(commit_pnew_i),
    .commit_pold_i(commit_pold_i),
    .undo_valid_i(undo_valid_i),
    .undo_rd_write_i(undo_rd_write_i),
    .undo_rd_fp_i(undo_rd_fp_i),
    .undo_rd_arch_i(undo_rd_arch_i),
    .undo_pnew_i(undo_pnew_i),
    .undo_pold_i(undo_pold_i)
  );
  always @(negedge clk) if (!rst) begin
    if (alloc_ready_o !== reference_alloc_ready_o) $fatal(1,"Split rename/scoreboard mismatch alloc_ready_o");
    if (pnew_o !== reference_pnew_o) $fatal(1,"Split rename/scoreboard mismatch pnew_o");
    if (pold_o !== reference_pold_o) $fatal(1,"Split rename/scoreboard mismatch pold_o");
    if (src_preg_o !== reference_src_preg_o) $fatal(1,"Split rename/scoreboard mismatch src_preg_o");
    if (src_ready_o !== reference_src_ready_o) $fatal(1,"Split rename/scoreboard mismatch src_ready_o");
    if (ready_query_ready_o !== reference_ready_query_ready_o) $fatal(1,"Split rename/scoreboard mismatch ready_query_ready_o");
    if ({scoreboard.gbusy_q,scoreboard.fbusy_q} !== {reference.gbusy_q,reference.fbusy_q})
      $fatal(1,"Split readiness state differs from frozen combined Rename");
  end
endmodule
