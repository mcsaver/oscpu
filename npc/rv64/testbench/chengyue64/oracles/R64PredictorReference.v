// Two instruction-local prediction lookups. Direct targets use fixed immediate
// wiring; a 256-entry bimodal table predicts conditional direction, and a
// 64-entry tagged table supplies other indirect targets. An eight-entry RAS
// predicts x1/x5 returns and is cleared on recovery. All prediction state may
// be inaccurate without affecting architectural ownership or correctness.
module R64PredictorReference #(parameter RAS_PTR_W=3)(
  // consume_i accepts the actual B prediction-result token. C confirms
  // a (possibly smaller) prefix later; only that prefix writes backing RAS.
  input [1:0] consume_i,input recover_i,input rollback_i,
  input [1:0] confirm_i,input [1:0] confirm_state_valid_i,confirm_push_i,
  input [2*RAS_PTR_W-1:0] confirm_index_i,confirm_pointer_i,
  input [2*(RAS_PTR_W+1)-1:0] confirm_count_i,
  input [125:0] confirm_data_i,
  input [3:0] journal_valid_i,input [4*RAS_PTR_W-1:0] journal_index_i,
  input [251:0] journal_data_i,
  output [2*RAS_PTR_W-1:0] write_index_o,post_pointer_o,
  output [2*(RAS_PTR_W+1)-1:0] post_count_o,
  output [1:0] push_o,output [127:0] return_pc_o,
  input clk_i,input rst_i,input invalidate_i,
  input [127:0] pc_i,input [63:0] inst_i,input [7:0] length_i,input [1:0] fault_i,
  // Table lookup belongs to the upstream complete-instruction capture.
  // These combinational outputs read old Q when captured on a training edge.
  input [127:0] lookup_pc_i,
  output [125:0] lookup_target_o,
  output [1:0] lookup_target_hit_o,lookup_direction_valid_o,lookup_direction_o,
  // Snapshot payload belongs to the current admitted instruction bundle;
  // intervening training does not change that owner's chosen prediction.
  input [125:0] target_snapshot_i,
  input [1:0] target_hit_snapshot_i,direction_valid_snapshot_i,direction_snapshot_i,
  input [341:0] preparation_i,
  input [63:0] planned_target_i,
  output [127:0] next_pc_o,output [1:0] taken_o,output [1:0] divert_o,
  output [1:0] planned_match_o,
  input update_i,input [63:0] update_pc_i,input update_conditional_i,
  input update_indirect_i,input update_taken_i,input [63:0] update_target_i
);
  // Prediction-only return stack. Advance exactly on FIFO admission, never
  // merely on a repeated lookup under backpressure. Recovery clears validity;
  // no architectural owner depends on stack contents or finite depth.
  localparam RAS_DEPTH=1<<RAS_PTR_W;
  reg [62:0] ras_q[0:RAS_DEPTH-1];
  reg [RAS_PTR_W-1:0] ras_pointer_q;
  reg [RAS_PTR_W:0] ras_count_q;
  wire [1:0] ras_push_w;
  assign push_o=ras_push_w;
  reg [RAS_PTR_W-1:0] confirmed_pointer_q;
  reg [RAS_PTR_W:0] confirmed_count_q;
  wire [62:0] ras_write_data_w[0:1];
  // Logical stack pointer/count advance at the original admission edge.
  // Wide array writes use last cycle's physical records. Every lookup sees
  // those records before backing storage, so consecutive call/return pairs
  // have exactly the same predictions without an extra pipeline stage.
  reg [1:0] ras_pending_valid_q;
  reg [RAS_PTR_W-1:0] ras_pending_index_q[0:1];
  reg [62:0] ras_pending_data_q[0:1];
  // C-confirmed writes are one-cycle records, always visible to B lookup.
  // Late prediction rollback preserves them; architectural reset/invalidate
  // clears all logical ownership without resetting the data array.
  always @(posedge clk_i)begin
    ras_pending_index_q[0]<=confirm_index_i[0+:RAS_PTR_W];
    ras_pending_index_q[1]<=confirm_index_i[RAS_PTR_W+:RAS_PTR_W];
    ras_pending_data_q[0]<=confirm_data_i[62:0];
    ras_pending_data_q[1]<=confirm_data_i[125:63];
    if(rst_i||invalidate_i||recover_i)ras_pending_valid_q<=0;
    else ras_pending_valid_q<={confirm_i==2&&confirm_state_valid_i[1]&&confirm_push_i[1],
        confirm_i>=1&&confirm_state_valid_i[0]&&confirm_push_i[0]};
  end
  always @(posedge clk_i)begin
    if(rst_i||invalidate_i||recover_i)begin
      ras_pointer_q<=0;ras_count_q<=0;confirmed_pointer_q<=0;confirmed_count_q<=0;
    end else begin
      // At the rollback edge C is barred by the existing pending redirect Q.
      // Its confirmed Q already includes the exact preceding admitted prefix.
      if(rollback_i)begin ras_pointer_q<=confirmed_pointer_q;ras_count_q<=confirmed_count_q;end
      else begin
        ras_pointer_q<=consume_i==2 ? g_lookup[1].next_pointer_w:consume_i==1 ? g_lookup[0].next_pointer_w:ras_pointer_q;
        ras_count_q<=consume_i==2 ? g_lookup[1].next_count_w:consume_i==1 ? g_lookup[0].next_count_w:ras_count_q;
      end
      if(confirm_i==2&&confirm_state_valid_i[1])begin
        confirmed_pointer_q<=confirm_pointer_i[RAS_PTR_W+:RAS_PTR_W];
        confirmed_count_q<=confirm_count_i[(RAS_PTR_W+1)+:(RAS_PTR_W+1)];
      end else if(confirm_i>=1&&confirm_state_valid_i[0])begin
        confirmed_pointer_q<=confirm_pointer_i[0+:RAS_PTR_W];
        confirmed_count_q<=confirm_count_i[0+:(RAS_PTR_W+1)];
      end
      if(ras_pending_valid_q[0])ras_q[ras_pending_index_q[0]]<=ras_pending_data_q[0];
      if(ras_pending_valid_q[1])ras_q[ras_pending_index_q[1]]<=ras_pending_data_q[1];
    end
  end
  reg [255:0] direction_valid_q;
  reg [1:0] direction_q[0:255];
  reg [63:0] target_valid_q;
  reg [15:0] target_tag_q[0:63];
  reg [62:0] target_q[0:63];
  wire [7:0] direction_index_w=update_pc_i[8:1];
  wire [5:0] target_index_w=update_pc_i[6:1];
  wire [1:0] old_counter_w=direction_q[direction_index_w];
  always @(posedge clk_i) begin
    if(rst_i||invalidate_i) begin direction_valid_q<=0;target_valid_q<=0;end
    else if(update_i) begin
      if(update_conditional_i) begin
        direction_valid_q[direction_index_w]<=1;
        if(!direction_valid_q[direction_index_w])
          direction_q[direction_index_w]<=update_taken_i?2'b10:2'b01;
        else if(update_taken_i&&old_counter_w!=3)
          direction_q[direction_index_w]<=old_counter_w+1'b1;
        else if(!update_taken_i&&old_counter_w!=0)
          direction_q[direction_index_w]<=old_counter_w-1'b1;
      end
      if(update_indirect_i) begin
        target_valid_q[target_index_w]<=1;
        target_tag_q[target_index_w]<=update_pc_i[22:7];
        target_q[target_index_w]<=update_target_i[63:1];
      end
    end
  end
  genvar lane;
  generate for(lane=0;lane<2;lane=lane+1) begin:g_lookup
    wire [RAS_PTR_W-1:0] pointer_w,write_index_w,next_pointer_w;
    wire [RAS_PTR_W:0] count_w,next_count_w;
    assign write_index_o[lane*RAS_PTR_W+:RAS_PTR_W]=write_index_w;
    assign post_pointer_o[lane*RAS_PTR_W+:RAS_PTR_W]=next_pointer_w;
    assign post_count_o[lane*(RAS_PTR_W+1)+:(RAS_PTR_W+1)]=next_count_w;
    if(lane==0)begin
      assign pointer_w=ras_pointer_q;assign count_w=ras_count_q;
    end else begin
      assign pointer_w=g_lookup[0].next_pointer_w;assign count_w=g_lookup[0].next_count_w;
    end
    wire [63:0] pc_w=pc_i[lane*64+:64];
    wire [31:0] inst_w=inst_i[lane*32+:32];
    wire [3:0] length_w=length_i[lane*4+:4];
    wire [170:0] prepared_w=preparation_i[lane*171+:171];
    wire [79:0] direct_add_w=prepared_w[79:0],return_add_w=prepared_w[159:80];
    wire jump_w=prepared_w[160],branch_w=prepared_w[161],indirect_w=prepared_w[162];
    wire pop_hint_w=prepared_w[163],push_hint_w=prepared_w[164];
    wire ras_offset_zero_w=prepared_w[165],default_direction_w=prepared_w[166];
    wire direct_divert_w=prepared_w[167],direct_match_w=prepared_w[168];
    wire pop_w=pop_hint_w&&count_w!=0;
    assign ras_push_w[lane]=push_hint_w;
    assign write_index_w=pointer_w-{{(RAS_PTR_W-1){1'b0}},pop_w};
    wire [63:0] return_pc_w,direct_target_w;
    wire unused_direct_carry_w,unused_return_carry_w;
    R64CarryFinish #(.WIDTH(64),.BLOCK(8)) direct_finish(
      .base_i(direct_add_w[63:0]),.propagate_i(direct_add_w[71:64]),
      .generate_i(direct_add_w[79:72]),.carry_i(1'b0),
      .sum_o(direct_target_w),.carry_o(unused_direct_carry_w));
    R64CarryFinish #(.WIDTH(64),.BLOCK(8)) return_finish(
      .base_i(return_add_w[63:0]),.propagate_i(return_add_w[71:64]),
      .generate_i(return_add_w[79:72]),.carry_i(1'b0),
      .sum_o(return_pc_w),.carry_o(unused_return_carry_w));
    assign ras_write_data_w[lane]=return_pc_w[63:1];
    assign return_pc_o[lane*64+:64]=return_pc_w;
    assign next_pointer_w=write_index_w+{{(RAS_PTR_W-1){1'b0}},ras_push_w[lane]};
    assign next_count_w=ras_push_w[lane] ?
      (pop_w||count_w==RAS_DEPTH ? count_w:count_w+1'b1):
      pop_w ? count_w-1'b1:count_w;
    wire [RAS_PTR_W-1:0] top_index_w=pointer_w-1'b1;
    wire [62:0] return_target_w;
    // Last admitted lane1 is younger than lane0 on a same-index collision.
    // A same-cycle lane0 push is younger again when predicting lane1.
    wire [62:0] confirmed_target_w=
        ras_pending_valid_q[1]&&ras_pending_index_q[1]==top_index_w?ras_pending_data_q[1]:
        ras_pending_valid_q[0]&&ras_pending_index_q[0]==top_index_w?ras_pending_data_q[0]:
        ras_q[top_index_w];
    // Older confirmed records precede every unconfirmed result journal.
    // Journal inputs are explicitly ordered oldest to youngest by their queue
    // owner; a later matching write wins, then current lane0 wins for lane1.
    genvar entry;
    for(entry=0;entry<=4;entry=entry+1)begin:g_journal_forward
      wire [62:0] target_w;
      if(entry==0)assign target_w=confirmed_target_w;
      else assign target_w=journal_valid_i[entry-1]&&
          journal_index_i[(entry-1)*RAS_PTR_W+:RAS_PTR_W]==top_index_w?
          journal_data_i[(entry-1)*63+:63]:g_journal_forward[entry-1].target_w;
    end
    wire [62:0] stored_target_w=g_journal_forward[4].target_w;
    wire pair_forward_w;
    if(lane==0)begin
      assign pair_forward_w=1'b0;
      assign return_target_w=stored_target_w;
    end else begin
      assign pair_forward_w=ras_push_w[0]&&g_lookup[0].write_index_w==top_index_w;
      assign return_target_w=pair_forward_w ?
       ras_write_data_w[0]:stored_target_w;
    end
    // General JALR offsets retain the target-table path; ordinary returns use
    // the stack without an additional 64-bit address adder on the lookup cone.
    wire ras_hit_w=pop_w&&ras_offset_zero_w;
    wire [63:0] query_pc_w=lookup_pc_i[lane*64+:64];
    wire [7:0] di_w=query_pc_w[8:1];
    wire [5:0] ti_w=query_pc_w[6:1];
    wire [1:0] counter_w=direction_q[di_w];
    assign lookup_target_o[lane*63+:63]=target_q[ti_w];
    assign lookup_target_hit_o[lane]=target_valid_q[ti_w]&&target_tag_q[ti_w]==query_pc_w[22:7];
    assign lookup_direction_valid_o[lane]=direction_valid_q[di_w];
    assign lookup_direction_o[lane]=counter_w[1];
    wire predicted_direction_w=direction_valid_snapshot_i[lane]?
        direction_snapshot_i[lane]:default_direction_w;
    wire target_hit_w=target_hit_snapshot_i[lane];
    wire [62:0] target_value_w=target_snapshot_i[lane*63+:63];
    wire take_w=!fault_i[lane]&&(jump_w||(branch_w&&predicted_direction_w)||
                (indirect_w&&(target_hit_w||ras_hit_w)));
    assign taken_o[lane]=take_w;
    // Direct control-flow discontinuity is an immediate comparison, independent
    // of the 64-bit target adder. Indirect targets compare with the return PC.
    wire [63:0] indirect_target_w=ras_hit_w?{return_target_w,1'b0}:{target_value_w,1'b0};
    assign planned_match_o[lane]=indirect_w?
        (ras_hit_w&&pair_forward_w?preparation_i[169]:
          indirect_target_w==planned_target_i):direct_match_w;
    assign divert_o[lane]=take_w&&(indirect_w?
        (ras_hit_w&&pair_forward_w?!prepared_w[170]:
          indirect_target_w!=return_pc_w):direct_divert_w);
    assign next_pc_o[lane*64+:64]=!take_w?return_pc_w:
      (indirect_w?(ras_hit_w?{return_target_w,1'b0}:{target_value_w,1'b0}):direct_target_w);
`ifdef R64_ASSERT
    always @(posedge clk_i)if(!rst_i&&taken_o[lane]&&
        planned_match_o[lane]!=(next_pc_o[lane*64+:64]==planned_target_i))
      $fatal(1,"predictor plan-match disagrees with actual predicted target");
    always @(posedge clk_i)if(!rst_i&&
        divert_o[lane]!=(taken_o[lane]&&next_pc_o[lane*64+:64]!=pc_w+{60'b0,length_w}))
      $fatal(1,"predictor discontinuity disagrees with actual predicted target");
`endif
    wire unused_counter_low_w=counter_w[0];
    wire unused_instruction_w=|inst_w;
  end endgenerate
`ifdef R64_ASSERT
  always @(posedge clk_i)if(!rst_i)begin
    if(consume_i==3)$fatal(1,"predictor admitted a non-prefix count");
    if(ras_count_q>RAS_DEPTH)$fatal(1,"predictor RAS count overflow");
  end
`endif
  wire unused_update_pc_w=|{update_pc_i[63:23],update_pc_i[0]};
  wire unused_target_lsb_w=update_target_i[0];
endmodule
