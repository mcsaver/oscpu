// Native two-wide GPR/FPR mapping and free-list owner. All state changes consume explicit
// shared ROB allocation/retirement/undo events. Six source descriptors cover
// three FP operands per uop; integer execution still has four GPR read ports.
module R64Rename #(
  parameter PREG_W = 6,
  parameter PREG_N = (1 << PREG_W),
  parameter ROB_W = 5,
  parameter BATCH_SUFFIX_ROLLBACK = 0
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
  input  [         1:0] alloc_fire_i,
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
  input  [2*PREG_W-1:0] undo_pold_i,
  input batch_apply_i,
  input [(1<<ROB_W)-1:0] batch_mask_i,
  input [ROB_W-1:0] batch_head_i,
  input [(1<<ROB_W)*(7+2*PREG_W)-1:0] batch_desc_i,
  output [PREG_N-1:0] batch_greclaim_o,batch_freclaim_o
);
  reg [PREG_W-1:0] gmap_q[0:31], fmap_q[0:31];
  reg [PREG_W-1:0] gcommit_q[0:31], fcommit_q[0:31];
  reg [PREG_N-1:0] gfree_q, ffree_q;
  function [PREG_W-1:0] encode;
    input [PREG_N-1:0] onehot;
    integer n;
    begin
      encode = 0;
      for (n = 0; n < PREG_N; n = n + 1) encode = encode | ({PREG_W{onehot[n]}} & n[PREG_W-1:0]);
    end
  endfunction
  wire [PREG_N-1:0] gfirst_w, gsecond_w, ffirst_w, fsecond_w;
  R64FreeSelect #(
    .N(PREG_N)
  ) g_free (
    .free_i(gfree_q),
    .first_o(gfirst_w),
    .second_o(gsecond_w),
    .any_o(),
    .two_o()
  );
  R64FreeSelect #(
    .N(PREG_N)
  ) f_free (
    .free_i(ffree_q),
    .first_o(ffirst_w),
    .second_o(fsecond_w),
    .any_o(),
    .two_o()
  );
  wire write0_w = rd_write_i[0] && (rd_fp_i[0] || rd_arch_i[4:0] != 0);
  wire write1_w = rd_write_i[1] && (rd_fp_i[1] || rd_arch_i[9:5] != 0);
  wire first_g_w = request_valid_i[0] && write0_w && !rd_fp_i[0];
  wire first_f_w = request_valid_i[0] && write0_w && rd_fp_i[0];
  wire [PREG_N-1:0] gpick1_w = first_g_w ? gsecond_w : gfirst_w;
  wire [PREG_N-1:0] fpick1_w = first_f_w ? fsecond_w : ffirst_w;
  wire [PREG_W-1:0] new0_w = write0_w ? encode(rd_fp_i[0] ? ffirst_w : gfirst_w) : 0;
  wire [PREG_W-1:0] new1_w = write1_w ? encode(rd_fp_i[1] ? fpick1_w : gpick1_w) : 0;
  assign pnew_o = {new1_w, new0_w};
  assign pold_o[0+:PREG_W] = rd_fp_i[0] ? fmap_q[rd_arch_i[4:0]] : gmap_q[rd_arch_i[4:0]];
  wire waw_w = request_valid_i[0] && write0_w && rd_fp_i[0] == rd_fp_i[1] &&
      rd_arch_i[4:0] == rd_arch_i[9:5];
  assign pold_o[PREG_W+:PREG_W] = waw_w ? new0_w :
      rd_fp_i[1] ? fmap_q[rd_arch_i[9:5]] : gmap_q[rd_arch_i[9:5]];
  // Capacity is a Q-only resource fact, independent of which free register
  // the priority selectors choose. Each node summarizes zero/one/two-or-more.
  generate
    for (genvar n = 1; n < 2 * PREG_N; n = n + 1) begin : gen_capacity
      wire gany_w, gtwo_w, fany_w, ftwo_w;
      if (n >= PREG_N) begin : leaf
        assign gany_w = gfree_q[n-PREG_N];
        assign fany_w = ffree_q[n-PREG_N];
        assign gtwo_w = 1'b0;
        assign ftwo_w = 1'b0;
      end else begin : branch
        assign gany_w = gen_capacity[2*n].gany_w | gen_capacity[2*n+1].gany_w;
        assign fany_w = gen_capacity[2*n].fany_w | gen_capacity[2*n+1].fany_w;
        assign gtwo_w = gen_capacity[2*n].gtwo_w | gen_capacity[2*n+1].gtwo_w |
            (gen_capacity[2*n].gany_w & gen_capacity[2*n+1].gany_w);
        assign ftwo_w = gen_capacity[2*n].ftwo_w | gen_capacity[2*n+1].ftwo_w |
            (gen_capacity[2*n].fany_w & gen_capacity[2*n+1].fany_w);
      end
    end
  endgenerate
  wire alloc_credit0_w = !rst && !restore_i && !undo_valid_i[0] &&
      !((BATCH_SUFFIX_ROLLBACK != 0)&&batch_apply_i) &&
      (!write0_w || (rd_fp_i[0] ? gen_capacity[1].fany_w : gen_capacity[1].gany_w));
  wire alloc_credit1_w = alloc_credit0_w &&
      (!write1_w || (rd_fp_i[1] ? (first_f_w ? gen_capacity[1].ftwo_w : gen_capacity[1].fany_w) :
                     (first_g_w ? gen_capacity[1].gtwo_w : gen_capacity[1].gany_w)));
  assign alloc_ready_o = {alloc_credit1_w, alloc_credit0_w};
  genvar source;
  generate
    for (source = 0; source < 6; source = source + 1) begin : gen_source
      wire [4:0] arch_w = src_arch_i[source*5+:5];
      wire fp_w = src_fp_i[source];
      wire pair_raw_w = source >= 3 && request_valid_i[0] && write0_w && arch_w == rd_arch_i[4:0] &&
          fp_w == rd_fp_i[0];
      wire [PREG_W-1:0] mapped_w = fp_w ? fmap_q[arch_w] : gmap_q[arch_w];
      wire [PREG_W-1:0] preg_w = pair_raw_w ? new0_w : mapped_w;
      assign src_preg_o[source*PREG_W+:PREG_W] = src_used_i[source] ? preg_w : 0;
    end
  endgenerate

  reg [PREG_N-1:0] committed_g_used_w, committed_f_used_w;
  integer used;
  always @(*) begin
    committed_g_used_w = 0;
    committed_f_used_w = 0;
    for (used = 0; used < 32; used = used + 1) begin
      committed_g_used_w[gcommit_q[used]] = 1'b1;
      committed_f_used_w[fcommit_q[used]] = 1'b1;
    end
    committed_g_used_w[0] = 1'b1;
  end
  // Decode registered suffix rows at fixed physical positions. The balanced
  // priority tree selects the first matching row at/after the saved head, or
  // the first matching lower row after wrap. Reclaim is an independent union
  // of every victim pnew and remains visible even when batch_apply_i is low.
  localparam BATCH_N = (1 << ROB_W);
  localparam BATCH_DESC_W = 7 + 2 * PREG_W;
  wire [31:0] batch_grestore_w, batch_frestore_w;
  wire [32*PREG_W-1:0] batch_gmap_w, batch_fmap_w;
  wire [PREG_N-1:0] batch_gfree_w, batch_ffree_w;
  assign batch_greclaim_o = batch_gfree_w;
  assign batch_freclaim_o = batch_ffree_w;
  generate
    for (genvar row = 0; row < BATCH_N; row = row + 1) begin : gen_batch_row
      wire [BATCH_DESC_W-1:0] desc_w =
          batch_desc_i[row*BATCH_DESC_W+:BATCH_DESC_W];
      wire [4:0] arch_w = desc_w[2+:5];
      wire [PREG_W-1:0] pnew_w = desc_w[7+:PREG_W];
      wire [PREG_W-1:0] pold_w = desc_w[7+PREG_W+:PREG_W];
      wire victim_w = (BATCH_SUFFIX_ROLLBACK != 0) && batch_mask_i[row] && desc_w[0];
      wire gvalid_w = victim_w && !desc_w[1] && arch_w != 0;
      wire fvalid_w = victim_w && desc_w[1];
      wire upper_w;
      if (row == BATCH_N - 1) begin : last_row
        assign upper_w = 1'b1;
      end else begin : lower_row
        assign upper_w = ROB_W'(row) >= batch_head_i;
      end
    end
    for (genvar aidx = 0; aidx < 32; aidx = aidx + 1) begin : gen_batch_map
      for (genvar n = 1; n < 2 * BATCH_N; n = n + 1) begin : node
        wire gv_w, gh_w, fv_w, fh_w;
        wire [PREG_W-1:0] gd_w, fd_w;
        if (n >= BATCH_N) begin : leaf
          wire match_w = gen_batch_row[n-BATCH_N].arch_w == 5'(aidx);
          assign gv_w = gen_batch_row[n-BATCH_N].gvalid_w && match_w;
          assign fv_w = gen_batch_row[n-BATCH_N].fvalid_w && match_w;
          assign gh_w = gv_w && gen_batch_row[n-BATCH_N].upper_w;
          assign fh_w = fv_w && gen_batch_row[n-BATCH_N].upper_w;
          assign gd_w = gv_w ? gen_batch_row[n-BATCH_N].pold_w : {PREG_W{1'b0}};
          assign fd_w = fv_w ? gen_batch_row[n-BATCH_N].pold_w : {PREG_W{1'b0}};
        end else begin : branch
          wire gleft_w = node[2*n].gh_w || (!node[2*n+1].gh_w && node[2*n].gv_w);
          wire fleft_w = node[2*n].fh_w || (!node[2*n+1].fh_w && node[2*n].fv_w);
          assign gv_w = node[2*n].gv_w || node[2*n+1].gv_w;
          assign fv_w = node[2*n].fv_w || node[2*n+1].fv_w;
          assign gh_w = node[2*n].gh_w || node[2*n+1].gh_w;
          assign fh_w = node[2*n].fh_w || node[2*n+1].fh_w;
          assign gd_w = gleft_w ? node[2*n].gd_w : node[2*n+1].gd_w;
          assign fd_w = fleft_w ? node[2*n].fd_w : node[2*n+1].fd_w;
        end
      end
      assign batch_grestore_w[aidx] = node[1].gv_w;
      assign batch_frestore_w[aidx] = node[1].fv_w;
      assign batch_gmap_w[aidx*PREG_W+:PREG_W] = node[1].gd_w;
      assign batch_fmap_w[aidx*PREG_W+:PREG_W] = node[1].fd_w;
    end
    for (genvar pidx = 0; pidx < PREG_N; pidx = pidx + 1) begin : gen_batch_free
      for (genvar n = 1; n < 2 * BATCH_N; n = n + 1) begin : node
        wire gv_w, fv_w;
        if (n >= BATCH_N) begin : leaf
          wire match_w = gen_batch_row[n-BATCH_N].pnew_w == PREG_W'(pidx);
          assign gv_w = gen_batch_row[n-BATCH_N].gvalid_w && match_w;
          assign fv_w = gen_batch_row[n-BATCH_N].fvalid_w && match_w;
        end else begin : branch
          assign gv_w = node[2*n].gv_w || node[2*n+1].gv_w;
          assign fv_w = node[2*n].fv_w || node[2*n+1].fv_w;
        end
      end
      assign batch_gfree_w[pidx] = node[1].gv_w;
      assign batch_ffree_w[pidx] = node[1].fv_w;
    end
  endgenerate
  integer i, lane;
  reg [4:0] arch;
  reg [PREG_W-1:0] pn, po;
  always @(posedge clk) begin
    if (rst) begin
      gfree_q <= {PREG_N{1'b1}} << 32;
      ffree_q <= {PREG_N{1'b1}} << 32;
      for (i = 0; i < 32; i = i + 1) begin
        gmap_q[i] <= i[PREG_W-1:0];
        fmap_q[i] <= i[PREG_W-1:0];
        gcommit_q[i] <= i[PREG_W-1:0];
        fcommit_q[i] <= i[PREG_W-1:0];
      end
    end else if (restore_i) begin
      gfree_q <= ~committed_g_used_w;
      ffree_q <= ~committed_f_used_w;
      for (i = 0; i < 32; i = i + 1) begin
        gmap_q[i] <= gcommit_q[i];
        fmap_q[i] <= fcommit_q[i];
      end
    end else begin
      for (lane = 0; lane < 2; lane = lane + 1) begin
        arch = commit_rd_arch_i[lane*5+:5];
        pn   = commit_pnew_i[lane*PREG_W+:PREG_W];
        po   = commit_pold_i[lane*PREG_W+:PREG_W];
        if (commit_fire_i[lane] && commit_rd_write_i[lane]) begin
          if (commit_rd_fp_i[lane]) begin
            fcommit_q[arch] <= pn;
            ffree_q[po] <= 1'b1;
          end else if (arch != 0) begin
            gcommit_q[arch] <= pn;
            if (po != 0) gfree_q[po] <= 1'b1;
          end
        end
      end
      // Undo lane0 is youngest; lane1 is the next older entry and wins WAW.
      for (lane = 0; lane < 2; lane = lane + 1) begin
        arch = undo_rd_arch_i[lane*5+:5];
        pn   = undo_pnew_i[lane*PREG_W+:PREG_W];
        po   = undo_pold_i[lane*PREG_W+:PREG_W];
        if (undo_valid_i[lane] && undo_rd_write_i[lane]) begin
          if (undo_rd_fp_i[lane]) begin
            fmap_q[arch] <= po;
            ffree_q[pn]  <= 1'b1;
          end else if (arch != 0) begin
            gmap_q[arch] <= po;
            gfree_q[pn]  <= 1'b1;
          end
        end
      end
      if((BATCH_SUFFIX_ROLLBACK != 0)&&batch_apply_i)begin
        for(i=0;i<32;i=i+1)begin
          if(batch_grestore_w[i])gmap_q[i]<=batch_gmap_w[i*PREG_W+:PREG_W];
          if(batch_frestore_w[i])fmap_q[i]<=batch_fmap_w[i*PREG_W+:PREG_W];
        end
        for(i=0;i<PREG_N;i=i+1)begin
          if(batch_gfree_w[i])gfree_q[i]<=1;
          if(batch_ffree_w[i])ffree_q[i]<=1;
        end
      end
      for (lane = 0; lane < 2; lane = lane + 1) begin
        arch = rd_arch_i[lane*5+:5];
        pn   = pnew_o[lane*PREG_W+:PREG_W];
        if (alloc_fire_i[lane] && (lane == 0 ? write0_w : write1_w)) begin
          if (rd_fp_i[lane]) begin
            fmap_q[arch] <= pn;
            ffree_q[pn]  <= 1'b0;
          end else begin
            gmap_q[arch] <= pn;
            gfree_q[pn]  <= 1'b0;
          end
        end
      end
    end
  end
`ifdef R64_ASSERT
  always @(posedge clk)
    if (!rst) begin
      if ((alloc_fire_i & ~alloc_ready_o) != 0)
        $fatal(1, "R64 rename accepted without free register");
      if (alloc_fire_i[1] && !alloc_fire_i[0]) $fatal(1, "R64 rename allocation must be dense");
      if((BATCH_SUFFIX_ROLLBACK != 0)&&batch_apply_i&&
         ((|alloc_fire_i)||(|undo_valid_i)||batch_gfree_w[0]))
        $fatal(1,"R64 batch rename crossed allocation/legacy undo/x0 boundary");
      if (undo_valid_i != 0 && alloc_fire_i != 0)
        $fatal(1, "R64 rename allocation overlapped rollback");
      if (gmap_q[0] != 0 || gcommit_q[0] != 0 || gfree_q[0])
        $fatal(1, "R64 x0 physical mapping violated");
    end
`endif
endmodule
