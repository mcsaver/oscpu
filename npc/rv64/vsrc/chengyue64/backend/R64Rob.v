// Native two-wide reorder buffer. Metadata is retire-only, not an execution uop.
// Tags are {generation, physical slot}; wb_accept is the sole authority for
// completion, PRF writes and wakeup. All completion inputs are drainable.
//
// kill_tag preserves its boundary and squashes only younger entries. Undo
// walks the retained rename history backwards, two entries per cycle. A new
// older redirect can extend a walk. Allocation and retirement pause during
// recovery; matching older completions remain accepted.
//
// reuse_block_i is the physical-slot mask of LSU/Tensor transactions still draining
// after squash/retirement. It prevents finite-generation aliasing without a
// distributed full-tag lease network. Cancellable FUs clear valids on kill.
module R64Rob #(
  parameter INDEX_W = 5,
  parameter GEN_W = 4,
  parameter META_W = 204,
  parameter NPC_LSB = 128,
  parameter PREG_W = 6,
  parameter TAG_W = INDEX_W + GEN_W,
  parameter N = (1 << INDEX_W),
  parameter OWNER_CERTIFICATE = 0,parameter SERIAL_PAYLOAD=0,parameter HEAD_SERIAL_CACHE=0,parameter LOCAL_KILL_FREEZE=0,
  parameter OWNER_BANK_BITS = (INDEX_W>2)?2:0,
  parameter OWNER_BANKS = (1<<OWNER_BANK_BITS)
) (
  input clk, input rst, input flush_i,
  input kill_pending_i,input kill_valid_i, input [TAG_W-1:0] kill_tag_i,
  input recovery_preview_valid_i,input [TAG_W-1:0] recovery_preview_tag_i,
  input [N-1:0] reuse_block_i,
  input resolve_valid_i, input [TAG_W-1:0] resolve_tag_i, input [63:0] resolve_npc_i,
  input [1:0] alloc_valid_i,
  output [1:0] alloc_ready_o,
  output [2*TAG_W-1:0] alloc_tag_o,
  input [2*META_W-1:0] alloc_meta_i,
  input [1:0] alloc_rd_write_i, input [1:0] alloc_rd_fp_i,
  input [1:0] alloc_serial_i,
  input [9:0] alloc_rd_arch_i,
  input [2*PREG_W-1:0] alloc_pnew_i, input [2*PREG_W-1:0] alloc_pold_i,
  input store_done_valid_i,output store_done_ready_o,
  input [TAG_W-1:0] store_done_tag_i,input store_done_error_i,
  input [63:0] store_done_tval_i,
  // Queries refer to the exact two current WB grants before their capture
  // edge. Responses are bank-local canonical metadata, not completion events.
  input [2*TAG_W-1:0] owner_query_tag_i,
  output [2*OWNER_BANKS*(PREG_W+3)-1:0] owner_query_cert_o,
  input [2*(PREG_W+3)-1:0] wb_owner_cert_i,
  input [1:0] wb_valid_i,
  input [2*TAG_W-1:0] wb_tag_i,
  input [127:0] wb_data_i,
  input [1:0] wb_exception_i,
  input [11:0] wb_cause_i, input [127:0] wb_tval_i,
  input [9:0] wb_fflags_i,
  output [1:0] wb_accept_o,
  output [1:0] wb_rd_write_o, output [1:0] wb_rd_fp_o,
  output [2*PREG_W-1:0] wb_preg_o,
  // Read-only authorization for early wake (0/1) and ALU bypass (2/3).
  // These queries do not complete or mutate an entry.
  input [3:0] short_valid_i,input [4*TAG_W-1:0] short_tag_i,
  input [4*PREG_W-1:0] short_preg_i,output [3:0] short_accept_o,
  input [1:0] commit_ready_i, input commit1_allow_i,
  output [1:0] commit_valid_o,output [1:0] commit_serial_o,
  output [2*TAG_W-1:0] commit_tag_o,
  output [2*META_W-1:0] commit_meta_o,
  output [127:0] commit_data_o,
  output [1:0] commit_exception_o,
  output [11:0] commit_cause_o, output [127:0] commit_tval_o,
  output [9:0] commit_fflags_o,
  output [1:0] commit_rd_write_o, output [1:0] commit_rd_fp_o,
  output [9:0] commit_rd_arch_o,
  output [2*PREG_W-1:0] commit_pnew_o, output [2*PREG_W-1:0] commit_pold_o,
  output [1:0] undo_valid_o,
  output [1:0] undo_rd_write_o, output [1:0] undo_rd_fp_o,
  output [9:0] undo_rd_arch_o,
  output [2*PREG_W-1:0] undo_pnew_o, output [2*PREG_W-1:0] undo_pold_o,
  output [N-1:0] kill_mask_o,
  output [N-1:0] cancel_candidates_o,output cancel_active_o,
  output recover_o,
  output head_exception_o,
  output serial_valid_o, output [INDEX_W-1:0] serial_slot_o,
  output [N-1:0] serial_active_o,serial_release_o,
  output [INDEX_W:0] count_o,
  output [INDEX_W-1:0] head_slot_o
);
  reg [N-1:0] valid_q, done_q, exception_q, rd_write_q, rd_fp_q, serial_q;
  reg [GEN_W-1:0] generation_q [0:N-1];
  reg [META_W-1:0] meta_q [0:N-1];
  reg [63:0] data_q [0:N-1];
  reg [5:0] cause_q [0:N-1];
  reg [63:0] tval_q [0:N-1];
  reg [4:0] fflags_q [0:N-1];
  reg [4:0] rd_arch_q [0:N-1];
  reg [PREG_W-1:0] pnew_q [0:N-1], pold_q [0:N-1];
  reg [INDEX_W-1:0] head_q, tail_q, undo_q;
  reg [INDEX_W:0] count_q, undo_count_q;
  genvar short_port;
  generate for(short_port=0;short_port<4;short_port=short_port+1)begin:gen_short_owner
    wire [TAG_W-1:0] query_tag_w=short_tag_i[short_port*TAG_W+:TAG_W];
    wire [PREG_W-1:0] query_preg_w=short_preg_i[short_port*PREG_W+:PREG_W];
    wire [INDEX_W-1:0] slot_w=query_tag_w[INDEX_W-1:0];
    assign short_accept_o[short_port]=short_valid_i[short_port]&&!rst&&!flush_i&&
        valid_q[slot_w]&&!done_q[slot_w]&&!kill_mask_o[slot_w]&&
        generation_q[slot_w]==query_tag_w[TAG_W-1:INDEX_W]&&
        rd_write_q[slot_w]&&!rd_fp_q[slot_w]&&query_preg_w!=0&&pnew_q[slot_w]==query_preg_w;
  end endgenerate
  wire [INDEX_W-1:0] tail1_w = tail_q + 1'b1;
  wire [INDEX_W-1:0] head1_w = head_q + 1'b1;
  wire [INDEX_W-1:0] undo1_w = undo_q - 1'b1;
  wire [INDEX_W-1:0] kill_slot_w = kill_tag_i[INDEX_W-1:0];
  wire canonical_kill_w = kill_valid_i && valid_q[kill_slot_w] &&
                generation_q[kill_slot_w] == kill_tag_i[TAG_W-1:INDEX_W];
  reg plan_valid_q;reg [N-1:0] plan_younger_q;
  reg [INDEX_W:0] plan_keep_q;
  reg [TAG_W-1:0] plan_tag_q;
  wire kill_w=kill_valid_i&&plan_valid_q;
  wire [INDEX_W-1:0] kill_age_w = kill_slot_w - head_q;
  wire [INDEX_W:0] reference_keep_w = {1'b0,kill_age_w} + 1'b1;
  wire [INDEX_W:0] keep_count_w = plan_keep_q;
  assign recover_o = undo_count_q != 0;
  // Native ALU resolution registers already own a pending redirect. Apply
  // reset/flush here once; routing their qualified result through Execute and
  // back into this same freeze OR creates a redundant long control path.
  // This summary only freezes birth/retirement. Real kill/undo still use the
  // canonical generation-matched redirect and the original recovery plan.
  wire freeze_kill_w=LOCAL_KILL_FREEZE ? kill_pending_i:kill_w;
  wire freeze_w = rst || flush_i || freeze_kill_w || recover_o;
  assign count_o = count_q;
  // Resident completion fact, independent of current retirement cancellation.
  // This certificate only stops younger birth; it never captures a trap.
  assign head_exception_o=count_q!=0&&valid_q[head_q]&&done_q[head_q]&&exception_q[head_q];
  assign head_slot_o = head_q;
  generate if(!HEAD_SERIAL_CACHE)begin:g_direct_head_class
    assign commit_serial_o={serial_q[head1_w],serial_q[head_q]};
  end else begin:g_head_class
    // Retained payload projection, including invalid head slots. Lookahead
    // reads and actual birth bypass finish before the late retirement prefix.
    reg [1:0] class_q;
    wire [3:0] projected_w;
    for(genvar offset=0;offset<4;offset=offset+1)begin:g_projection
      wire [INDEX_W-1:0] slot_w=head_q+INDEX_W'(offset);
      wire stored_w;
      if(offset<2)assign stored_w=class_q[offset];
      else assign stored_w=serial_q[slot_w];
      assign projected_w[offset]=(alloc_fire_w[1]&&tail1_w==slot_w)?alloc_serial_i[1]:
          (alloc_fire_w[0]&&tail_q==slot_w)?alloc_serial_i[0]:stored_w;
    end
    assign commit_serial_o=class_q;
    always @(posedge clk)begin
      if(rst)class_q<=0;
      else if(flush_i)begin
        if(SERIAL_PAYLOAD)class_q<={serial_q[1],serial_q[0]};
        else class_q<=0;
      end else begin
        class_q[0]<=commit_fire_w[1]?projected_w[2]:
                    commit_fire_w[0]?projected_w[1]:projected_w[0];
        class_q[1]<=commit_fire_w[1]?projected_w[3]:
                    commit_fire_w[0]?projected_w[2]:projected_w[1];
      end
    end
`ifdef R64_ASSERT
    always @(posedge clk)if(!rst)begin
      if(class_q!=={serial_q[head1_w],serial_q[head_q]})
        $fatal(1,"ROB cached head class lost retained payload projection");
    end
`endif
  end endgenerate
  wire [N-1:0] serial_live_w = serial_q & valid_q;
  assign serial_active_o=serial_live_w;
  wire [2*N-1:0] serial_rotated_w = {serial_live_w,serial_live_w} >> head_q;
  function [INDEX_W-1:0] first_serial;
    input [N-1:0] mask;
    reg [N-1:0] prefix,onehot;
    integer d,b;
    begin
      prefix=mask;
      for(d=1;d<N;d=d*2) prefix=prefix|(prefix<<d);
      onehot=mask&~(prefix<<1);
      first_serial=0;
      for(b=0;b<N;b=b+1)
        first_serial=first_serial|({INDEX_W{onehot[b]}}&b[INDEX_W-1:0]);
    end
  endfunction
  assign serial_valid_o=(|serial_live_w)&&!rst&&!flush_i;
  assign serial_slot_o=head_q+first_serial(serial_rotated_w[N-1:0]);
  wire alloc_credit0_w = !freeze_w && count_q < N && !reuse_block_i[tail_q];
  wire alloc_credit1_w = alloc_credit0_w && count_q < (N-1) && !reuse_block_i[tail1_w];
  assign alloc_ready_o = {alloc_credit1_w,alloc_credit0_w};
  wire [1:0] alloc_fire_w = alloc_valid_i & alloc_ready_o;
  assign alloc_tag_o[0 +: TAG_W] = {generation_q[tail_q] + {{(GEN_W-1){1'b0}},1'b1},tail_q};
  assign alloc_tag_o[TAG_W +: TAG_W] = {generation_q[tail1_w] + {{(GEN_W-1){1'b0}},1'b1},tail1_w};
  wire [META_W-1:0] npc_mask_w,npc_data_w;
  genvar np;
  generate for(np=0;np<META_W;np=np+1)begin:gen_npc_update
    if(np>=NPC_LSB&&np<NPC_LSB+64)begin
      assign npc_mask_w[np]=1'b1;
      assign npc_data_w[np]=resolve_npc_i[np-NPC_LSB];
    end else begin
      assign npc_mask_w[np]=1'b0;assign npc_data_w[np]=1'b0;
    end
  end endgenerate
  wire [INDEX_W-1:0] resolve_slot_w=resolve_tag_i[INDEX_W-1:0];
  wire resolve_accept_w=resolve_valid_i&&valid_q[resolve_slot_w]&&
      generation_q[resolve_slot_w]==resolve_tag_i[TAG_W-1:INDEX_W]&&
      !kill_mask_o[resolve_slot_w];
  // The native pending bit is the registered redirect fact before Execute's
  // reset/flush guard. Full flush absorbs that guard in the victim union:
  // F | (!F & pending & plan) == F | (pending & plan).
  // Keep reset local and retain the canonical kill for recovery state changes.
  // No cancellation edge is delayed and no owner qualification is removed.
  wire publication_kill_w=LOCAL_KILL_FREEZE ?
      (!rst&&kill_pending_i&&plan_valid_q):kill_w;
  assign cancel_active_o=flush_i||publication_kill_w;
  genvar k;
  generate for (k=0;k<N;k=k+1) begin : gen_kill
    wire [INDEX_W-1:0] age_w = k[INDEX_W-1:0] - head_q;
    assign cancel_candidates_o[k]=valid_q[k]&&(flush_i||plan_younger_q[k]);
    assign kill_mask_o[k] = valid_q[k] &&
                           (flush_i || (publication_kill_w && plan_younger_q[k]));
  end endgenerate
  wire commit_valid0_w = !freeze_w && count_q != 0 &&
                            valid_q[head_q] && done_q[head_q];
  wire commit_valid1_w = commit_valid0_w && commit_ready_i[0] &&
                            commit1_allow_i && !exception_q[head_q] &&
                            count_q > 1 && valid_q[head1_w] && done_q[head1_w];
  assign commit_valid_o = {commit_valid1_w,commit_valid0_w};
  wire [1:0] commit_fire_w = commit_valid_o & commit_ready_i;
  genvar release_slot;
  generate for(release_slot=0;release_slot<N;release_slot=release_slot+1)begin:gen_serial_release
    // This is an observation of existing commit/kill ownership transitions;
    // it cannot authorize completion, change cancellation, or retire early.
    assign serial_release_o[release_slot]=kill_mask_o[release_slot]||
        (commit_fire_w[0]&&head_q==release_slot)||
        (commit_fire_w[1]&&head1_w==release_slot);
  end endgenerate

  wire undo_valid0_w = recover_o && !rst && !flush_i && !kill_w;
  wire undo_valid1_w = undo_valid0_w && undo_count_q > 1;
  assign undo_valid_o = {undo_valid1_w,undo_valid0_w};
  wire [INDEX_W:0] alloc_count_w = {{INDEX_W{1'b0}},alloc_fire_w[0]} +
                                  {{INDEX_W{1'b0}},alloc_fire_w[1]};
  wire [INDEX_W:0] commit_count_w = {{INDEX_W{1'b0}},commit_fire_w[0]} +
                                   {{INDEX_W{1'b0}},commit_fire_w[1]};
  wire [INDEX_W:0] undo_step_w = {{INDEX_W{1'b0}},undo_valid_o[0]} +
                               {{INDEX_W{1'b0}},undo_valid_o[1]};
  // Preview runs beside the ALU final target/condition computation. A branch
  // cannot have completed before its terminal and resolve registers are born.
  // Geometry deliberately includes currently empty slots: births at this edge
  // are younger owners and must be cancelled by the following event as well.
  wire [INDEX_W-1:0] preview_slot_w=recovery_preview_tag_i[INDEX_W-1:0];
  wire [INDEX_W-1:0] preview_age_w=preview_slot_w-head_q;
  wire [INDEX_W:0] preview_keep_w={1'b0,preview_age_w}+1'b1;
  wire preview_wrap_w=preview_slot_w<head_q;
  wire preview_canonical_w=recovery_preview_valid_i&&valid_q[preview_slot_w]&&
      generation_q[preview_slot_w]==recovery_preview_tag_i[TAG_W-1:INDEX_W]&&
      !kill_mask_o[preview_slot_w]&&!done_q[preview_slot_w];
  genvar plan_slot;
  generate for(plan_slot=0;plan_slot<N;plan_slot=plan_slot+1)begin:gen_recovery_plan
    wire slot_after_w,slot_wrap_w;
    if(plan_slot==0)assign slot_after_w=1'b0;
    else assign slot_after_w=plan_slot[INDEX_W-1:0]>preview_slot_w;
    if(plan_slot==N-1)assign slot_wrap_w=1'b0;
    else assign slot_wrap_w=plan_slot[INDEX_W-1:0]<head_q;
    always @(posedge clk)
      plan_younger_q[plan_slot]<=slot_after_w^slot_wrap_w^preview_wrap_w;
  end endgenerate
  always @(posedge clk)begin
    plan_tag_q<=recovery_preview_tag_i;
    // Current retirement only removes older owners. Use its actual prefix
    // count so the registered retained count refers to the next-cycle head.
    plan_keep_q<=preview_keep_w-commit_count_w;
    if(rst||flush_i)plan_valid_q<=0;
    else plan_valid_q<=preview_canonical_w;
  end
  // Side effects remain at the same head through a younger branch recovery.
  // Decode KIND=store is authoritative; reduced-META unit fixtures have no
  // narrow store terminal. No PRF destination lookup or wide WB slot is used.
  wire ordinary_store_head_w;
  generate if(META_W>=204)begin:gen_store_kind
    assign ordinary_store_head_w=meta_q[head_q][196+:8]==8'd3;
  end else begin:gen_no_store_kind
    assign ordinary_store_head_w=1'b0;
  end endgenerate
  assign store_done_ready_o=!rst&&!flush_i&&count_q!=0&&valid_q[head_q]&&
      !done_q[head_q]&&!kill_mask_o[head_q]&&ordinary_store_head_w&&
      !rd_write_q[head_q]&&!serial_q[head_q]&&
      store_done_tag_i=={generation_q[head_q],head_q};
  wire store_done_fire_w=store_done_valid_i&&store_done_ready_o;
  localparam OWNER_LOCAL_BITS=INDEX_W-OWNER_BANK_BITS,OWNER_LOCAL_SLOTS=1<<OWNER_LOCAL_BITS;
  localparam CERT_W=PREG_W+3;
  // A certificate lasts exactly one WB output cycle. The current completion
  // edge may finish an otherwise live queried owner, so remove those owners
  // from the next certificate before it is sampled. Retirement cannot free an
  // unfinished owner; flush/kill are still checked at actual WB acceptance.
  wire [N-1:0] completing_w;
  genvar owner_row,owner_lane,owner_bank;
  generate for(owner_row=0;owner_row<N;owner_row=owner_row+1)begin:g_completing
    assign completing_w[owner_row]=
      (wb_accept_o[0]&&wb_tag_i[0+:INDEX_W]==owner_row)||
      (wb_accept_o[1]&&wb_tag_i[TAG_W+:INDEX_W]==owner_row)||
      (store_done_fire_w&&head_q==owner_row);
  end
  for(owner_lane=0;owner_lane<2;owner_lane=owner_lane+1)begin:g_owner_query_lane
    for(owner_bank=0;owner_bank<OWNER_BANKS;owner_bank=owner_bank+1)begin:g_owner_query_bank
      wire [TAG_W-1:0] query_tag_w=owner_query_tag_i[owner_lane*TAG_W+:TAG_W];
      wire [OWNER_LOCAL_BITS-1:0] local_slot_w=query_tag_w[OWNER_LOCAL_BITS-1:0];
      wire [OWNER_LOCAL_SLOTS-1:0] live_rows_w;
      wire [OWNER_LOCAL_SLOTS*(PREG_W+GEN_W+2)-1:0] metadata_w;
      for(genvar row=0;row<OWNER_LOCAL_SLOTS;row=row+1)begin:g_row
        localparam SLOT=owner_bank*OWNER_LOCAL_SLOTS+row;
        assign live_rows_w[row]=valid_q[SLOT]&&!done_q[SLOT]&&!completing_w[SLOT];
        assign metadata_w[row*(PREG_W+GEN_W+2)+:(PREG_W+GEN_W+2)]=
          {generation_q[SLOT],rd_write_q[SLOT]&&(rd_fp_q[SLOT]||rd_arch_q[SLOT]!=0),
           rd_fp_q[SLOT],pnew_q[SLOT]};
      end
      wire [PREG_W+GEN_W+1:0] selected_w=metadata_w[local_slot_w*(PREG_W+GEN_W+2)+:(PREG_W+GEN_W+2)];
      wire owner_w=live_rows_w[local_slot_w]&&
        selected_w[PREG_W+2+:GEN_W]==query_tag_w[TAG_W-1:INDEX_W];
      assign owner_query_cert_o[(owner_lane*OWNER_BANKS+owner_bank)*CERT_W+:CERT_W]=
        {owner_w,selected_w[PREG_W+1:0]};
    end
  end endgenerate
  genvar lane;
  generate for (lane=0;lane<2;lane=lane+1) begin : gen_ports
    wire [INDEX_W-1:0] wi_w = wb_tag_i[lane*TAG_W +: INDEX_W];
    wire [GEN_W-1:0] wg_w = wb_tag_i[lane*TAG_W+INDEX_W +: GEN_W];
    wire [INDEX_W-1:0] ci_w = lane == 0 ? head_q : head1_w;
    wire [INDEX_W-1:0] ui_w = lane == 0 ? undo_q : undo1_w;
    wire duplicate_w;
    if (lane == 0) begin
      assign duplicate_w = 1'b0;
    end else begin
      assign duplicate_w = wb_valid_i[0] &&
          (wb_tag_i[0 +: TAG_W] == wb_tag_i[TAG_W +: TAG_W]);
    end
    wire reference_accept_w = !rst && !flush_i && wb_valid_i[lane] &&
        valid_q[wi_w] && !done_q[wi_w] && !kill_mask_o[wi_w] &&
        generation_q[wi_w] == wg_w && !duplicate_w &&
        !(store_done_fire_w&&wi_w==head_q);
    if(OWNER_CERTIFICATE==0)begin:g_direct_owner
      assign wb_accept_o[lane]=reference_accept_w;
      assign wb_rd_write_o[lane]=wb_accept_o[lane]&&!wb_exception_i[lane]&&
          rd_write_q[wi_w]&&(rd_fp_q[wi_w]||rd_arch_q[wi_w]!=0);
      assign wb_rd_fp_o[lane]=rd_fp_q[wi_w];
      assign wb_preg_o[lane*PREG_W+:PREG_W]=pnew_q[wi_w];
    end else begin:g_captured_owner
      wire [CERT_W-1:0] cert_w=wb_owner_cert_i[lane*CERT_W+:CERT_W];
      wire permitted_w=!rst&&!flush_i&&wb_valid_i[lane]&&cert_w[CERT_W-1]&&
          !kill_mask_o[wi_w]&&!duplicate_w;
      assign wb_accept_o[lane]=permitted_w&&!(store_done_fire_w&&wi_w==head_q);
      // Ordinary narrow stores canonically have no PRF destination. Their
      // terminal-priority cone must not reconverge into every PRF data bit.
      assign wb_rd_write_o[lane]=permitted_w&&cert_w[PREG_W+1]&&!wb_exception_i[lane];
      assign wb_rd_fp_o[lane]=cert_w[PREG_W];
      assign wb_preg_o[lane*PREG_W+:PREG_W]=cert_w[PREG_W-1:0];
`ifdef R64_ASSERT
      always @(posedge clk)if(!rst)begin
        if(wb_accept_o[lane]!==reference_accept_w)
          $fatal(1,"WB owner certificate changed canonical ROB acceptance");
        if(wb_rd_write_o[lane] !== (reference_accept_w&&!wb_exception_i[lane]&&
            rd_write_q[wi_w]&&(rd_fp_q[wi_w]||rd_arch_q[wi_w]!=0)))
          $fatal(1,"WB owner certificate changed canonical PRF permission");
        if(wb_accept_o[lane]&&{wb_rd_fp_o[lane],wb_preg_o[lane*PREG_W+:PREG_W]}!==
             {rd_fp_q[wi_w],pnew_q[wi_w]})
          $fatal(1,"WB owner certificate lost physical destination identity");
      end
`endif
    end
    assign commit_tag_o[lane*TAG_W +: TAG_W] = {generation_q[ci_w],ci_w};
    assign commit_meta_o[lane*META_W +: META_W] = meta_q[ci_w];
    assign commit_data_o[lane*64 +: 64] = data_q[ci_w];
    assign commit_exception_o[lane] = exception_q[ci_w];
    assign commit_cause_o[lane*6 +: 6] = cause_q[ci_w];
    assign commit_tval_o[lane*64 +: 64] = tval_q[ci_w];
    assign commit_fflags_o[lane*5 +: 5] = fflags_q[ci_w];
    assign commit_rd_write_o[lane] = rd_write_q[ci_w] && !exception_q[ci_w];
    assign commit_rd_fp_o[lane] = rd_fp_q[ci_w];
    assign commit_rd_arch_o[lane*5 +: 5] = rd_arch_q[ci_w];
    assign commit_pnew_o[lane*PREG_W +: PREG_W] = pnew_q[ci_w];
    assign commit_pold_o[lane*PREG_W +: PREG_W] = pold_q[ci_w];
    assign undo_rd_write_o[lane] = rd_write_q[ui_w];
    assign undo_rd_fp_o[lane] = rd_fp_q[ui_w];
    assign undo_rd_arch_o[lane*5 +: 5] = rd_arch_q[ui_w];
    assign undo_pnew_o[lane*PREG_W +: PREG_W] = pnew_q[ui_w];
    assign undo_pold_o[lane*PREG_W +: PREG_W] = pold_q[ui_w];
  end endgenerate

  integer i;
  integer p;
  reg [INDEX_W-1:0] idx;
  always @(posedge clk) begin
    if (rst) begin
      valid_q <= {N{1'b0}}; done_q <= {N{1'b0}}; serial_q <= 0;
      exception_q <= {N{1'b0}}; rd_write_q <= {N{1'b0}}; rd_fp_q <= {N{1'b0}};
      head_q <= 0; tail_q <= 0; count_q <= 0; undo_q <= 0; undo_count_q <= 0;
      for (i=0;i<N;i=i+1) begin
        generation_q[i] <= 0;
        meta_q[i] <= 0; data_q[i] <= 0; cause_q[i] <= 0; tval_q[i] <= 0;
        fflags_q[i] <= 0; rd_arch_q[i] <= 0; pnew_q[i] <= 0; pold_q[i] <= 0;
      end
    end else if (flush_i) begin
      valid_q <= {N{1'b0}}; done_q <= {N{1'b0}};
      if(!SERIAL_PAYLOAD)serial_q<=0;
      head_q <= 0; tail_q <= 0; count_q <= 0; undo_count_q <= 0;
    end else begin
      if(resolve_accept_w)
        meta_q[resolve_slot_w]<=(meta_q[resolve_slot_w]&~npc_mask_w)|npc_data_w;
      for (p=0;p<2;p=p+1) begin
        if (wb_accept_o[p]) begin
          idx = wb_tag_i[p*TAG_W +: INDEX_W];
          done_q[idx] <= 1'b1;
          data_q[idx] <= wb_data_i[p*64 +: 64];
          exception_q[idx] <= wb_exception_i[p];
          cause_q[idx] <= wb_cause_i[p*6 +: 6];
          tval_q[idx] <= wb_tval_i[p*64 +: 64];
          fflags_q[idx] <= wb_fflags_i[p*5 +: 5];
        end
      end
      if(store_done_fire_w)begin
        done_q[head_q]<=1'b1;data_q[head_q]<=64'b0;
        exception_q[head_q]<=store_done_error_i;
        cause_q[head_q]<=store_done_error_i ? 6'd7:6'd0;
        tval_q[head_q]<=store_done_tval_i;fflags_q[head_q]<=5'b0;
      end
      if (kill_w) begin
        valid_q <= valid_q & ~kill_mask_o;
        done_q <= (done_q | (wb_accept_o[0] ? ({{(N-1){1'b0}},1'b1} << wb_tag_i[0 +: INDEX_W]) : {N{1'b0}}) |
                            (wb_accept_o[1] ? ({{(N-1){1'b0}},1'b1} << wb_tag_i[TAG_W +: INDEX_W]) : {N{1'b0}}) |
                            (store_done_fire_w ? ({{(N-1){1'b0}},1'b1} << head_q) : {N{1'b0}})) & ~kill_mask_o;
        tail_q <= kill_slot_w + 1'b1;
        count_q <= keep_count_w;
        undo_count_q <= undo_count_q + count_q - keep_count_w;
        if (!recover_o) undo_q <= tail_q - 1'b1;
      end else if (recover_o) begin
        undo_count_q <= undo_count_q - undo_step_w;
        undo_q <= undo_q - undo_step_w[INDEX_W-1:0];
      end else begin
        count_q <= count_q + alloc_count_w - commit_count_w;
        head_q <= head_q + commit_count_w[INDEX_W-1:0];
        tail_q <= tail_q + alloc_count_w[INDEX_W-1:0];
        for (p=0;p<2;p=p+1) begin
          if (commit_fire_w[p]) begin
            idx = head_q + p[INDEX_W-1:0];
            valid_q[idx] <= 1'b0; done_q[idx] <= 1'b0;
          end
          if (alloc_fire_w[p]) begin
            idx = tail_q + p[INDEX_W-1:0];
            valid_q[idx] <= 1'b1; done_q[idx] <= 1'b0; exception_q[idx] <= 1'b0;
            generation_q[idx] <= alloc_tag_o[p*TAG_W+INDEX_W +: GEN_W];
            meta_q[idx] <= alloc_meta_i[p*META_W +: META_W];
            rd_write_q[idx] <= alloc_rd_write_i[p]; rd_fp_q[idx] <= alloc_rd_fp_i[p];
            serial_q[idx] <= alloc_serial_i[p];
            rd_arch_q[idx] <= alloc_rd_arch_i[p*5 +: 5];
            pnew_q[idx] <= alloc_pnew_i[p*PREG_W +: PREG_W];
            pold_q[idx] <= alloc_pold_i[p*PREG_W +: PREG_W];
          end
        end
      end
    end
  end
`ifdef R64_ASSERT
  always @(posedge clk) if(!rst&&!flush_i&&store_done_fire_w)begin
    if((wb_valid_i[0]&&wb_tag_i[0+:TAG_W]==store_done_tag_i)||
       (wb_valid_i[1]&&wb_tag_i[TAG_W+:TAG_W]==store_done_tag_i))
      $fatal(1,"R64 store completed through both narrow and data WB paths");
  end

  always @(posedge clk)if(LOCAL_KILL_FREEZE&&!rst)begin
    if(cancel_active_o!==(flush_i||kill_w) ||
       kill_mask_o!==(valid_q&({N{flush_i}}|({N{kill_w}}&plan_younger_q))))
      $fatal(1,"ROB local cancellation differs from canonical same-edge victims");
  end
  always @(posedge clk)if(!rst&&!flush_i)begin
    if(LOCAL_KILL_FREEZE&&kill_pending_i!=kill_w)
      $fatal(1,"ROB local redirect freeze differs from canonical kill");
    if(recovery_preview_valid_i&&valid_q[preview_slot_w]&&
       generation_q[preview_slot_w]==recovery_preview_tag_i[TAG_W-1:INDEX_W]&&
       !kill_mask_o[preview_slot_w]&&done_q[preview_slot_w])
      $fatal(1,"recovery preview branch already completed");
    if(kill_valid_i)begin
      if(kill_w!=canonical_kill_w || (kill_w&&plan_tag_q!=kill_tag_i))
        $fatal(1,"recovery plan boundary generation mismatch");
      if(kill_w&&plan_keep_q!=reference_keep_w)
        $fatal(1,"recovery plan retained count differs from current ROB age");
    end
    if(kill_w)for(integer plan_check=0;plan_check<N;plan_check=plan_check+1)
      if(valid_q[plan_check]&&plan_younger_q[plan_check]!=
          ((plan_check[INDEX_W-1:0]-head_q)>kill_age_w))
        $fatal(1,"recovery plan victim differs from canonical age oracle");
  end
  always @(posedge clk) if (!rst) begin
    if (count_q > N || undo_count_q > N)
      $fatal(1,"R64 ROB capacity violated");
    if (alloc_valid_i[1] && !alloc_valid_i[0])
      $fatal(1,"R64 ROB allocation must be dense");
    if (commit_fire_w[1] && !commit_fire_w[0])
      $fatal(1,"R64 ROB retirement must be dense");
    if (wb_accept_o[0] && wb_accept_o[1] &&
        wb_tag_i[0 +: TAG_W] == wb_tag_i[TAG_W +: TAG_W])
      $fatal(1,"R64 ROB duplicate completion accepted");
  end
`endif
endmodule
