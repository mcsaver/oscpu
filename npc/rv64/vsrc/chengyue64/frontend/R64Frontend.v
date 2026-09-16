// Ordered fetch transport -> translation -> synchronous I-cache -> alignment
// -> local prediction -> four-entry instruction FIFO. Recovery drains accepted
// memory owners. Prediction redirects only after its branch enters the FIFO.
module R64Frontend #(
  parameter PREPARED_PROTECTION=0,
  parameter [63:0] RESET_PC=64'h80000000,
  parameter integer FETCH_PTR_W=2,
  parameter integer EARLY_PREDICT=1,
  parameter integer ICACHE_SET_W=6
)(
  input clk_i,input rst_i,input run_i,
  input redirect_i,input [63:0] redirect_pc_i,
  input [1:0] priv_i,input [63:0] mstatus_i,input [63:0] satp_i,input pbmt_enable_i,
  input icache_invalidate_i,
  input tlb_invalidate_i,input tlb_all_vaddr_i,input tlb_all_asid_i,
  input [26:0] tlb_vpn_i,input [15:0] tlb_asid_i,
  output [1:0] valid_o,input [1:0] consume_i,
  output [65:0] canonical_o,output [69:0] control_o,output [127:0] sequential_npc_o,
  output [127:0] pc_o,output [127:0] raw_o,output [7:0] length_o,
  output [127:0] predicted_npc_o,output [1:0] fault_o,
  output [9:0] cause_o,output [127:0] tval_o,
  input prediction_update_i,input [63:0] prediction_pc_i,
  input prediction_conditional_i,input prediction_indirect_i,
  input prediction_taken_i,input [63:0] prediction_target_i,
  // Platform protection denies individual halfwords in this physical sector.
  // Privilege belongs to the captured translation, not a newer CSR context.
  output [63:0] protect_paddr_o,output [1:0] protect_priv_o,
  input [7:0] protect_fault_mask_i,input protect_uncached_i,
  input [129:0] protect_facts_i,
  output cache_cmd_valid_o,input cache_cmd_ready_i,
  output [63:0] cache_cmd_addr_o,output [7:0] cache_cmd_len_o,output [2:0] cache_cmd_size_o,
  input cache_beat_valid_i,output cache_beat_ready_o,
  input [63:0] cache_beat_data_i,input [1:0] cache_beat_resp_i,input cache_beat_last_i,
  output pte_valid_o,input pte_ready_i,output pte_compare_or_o,
  output [55:0] pte_addr_o,output [63:0] pte_expected_o,output [63:0] pte_or_mask_o,
  input pte_rsp_valid_i,output pte_rsp_ready_o,input [63:0] pte_rdata_i,
  input pte_error_i,input pte_compare_ok_i
);
  wire fetch_v_w,fetch_r_w,cache_v_w,cache_r_w,cache_fault_w;
  wire [63:0] fetch_pc_w;
  wire [127:0] cache_data_w;
  wire [4:0] cache_cause_w;
  wire [7:0] cache_mask_w;
  wire packet_v_w,packet_r_w,packet_fault_w;
  wire [63:0] packet_pc_w;
  wire [127:0] packet_data_w;
  wire [4:0] packet_cause_w;
  wire [7:0] packet_mask_w;
  wire translation_v_w,translation_r_w,translation_fault_w,translation_ad_w;
  wire [1:0] translation_pbmt_w;
  wire [4:0] translation_cause_w;
  wire [1:0] align_v_w,align_take_w,align_fault_w,predicted_taken_w,predicted_divert_w,predicted_match_w;
  wire [127:0] align_pc_w,align_raw_w,align_tval_w,predicted_pc_w;
  wire [7:0] align_length_w;
  wire [9:0] align_cause_w;
  wire packet_plan_v_w,packet_plan_word_w;
  wire [2:0] packet_plan_offset_w;wire [62:0] packet_plan_target_w;
  wire [1:0] plan_at_w,plan_bad_w;
  wire [63:0] plan_target_w,plan_source_w;
  wire planned_jump_w,plan_repair_w;
  wire predicted_redirect_w;
  // A late redirect is a one-cycle record. Instruction FIFO admission and
  // RAS mutation happen at the original prediction edge. At the next edge
  // the record flushes only younger byte/bundle owners and retargets fetch.
  // The existing unconditional PC/target registers below are its payload.
  reg [3:0] pending_kind_q; // predicted lane0/lane1, repair lane0/lane1
  reg [4:0] pending_source_q;
  wire pending_redirect_w=|pending_kind_q;
  wire stream_redirect_w=redirect_i||pending_redirect_w;
  wire [63:0] pending_target_w=
      ({64{pending_kind_q[0]}}&learn_target_q[63:0])|
      ({64{pending_kind_q[1]}}&learn_target_q[127:64])|
      ({64{pending_kind_q[2]}}&learn_pc_q[63:0])|
      ({64{pending_kind_q[3]}}&learn_pc_q[127:64]);
  wire [63:0] stream_target_w=redirect_i?redirect_pc_i:pending_target_w;
  always @(posedge clk_i)begin
    pending_source_q<=plan_source_w[8:4];
    if(rst_i||redirect_i)pending_kind_q<=0;
    else pending_kind_q<={predicted_redirect_w&&plan_repair_w&&!repair0_w,
        predicted_redirect_w&&plan_repair_w&&repair0_w,
        predicted_redirect_w&&!plan_repair_w&&align_take_w==2,
        predicted_redirect_w&&!plan_repair_w&&align_take_w!=2};
  end

  // Prediction training is a separate, cancellable hint transaction. The
  // late admission decision marks one lane; neither PC nor target waits for
  // that decision before its register boundary.
  reg [1:0] learn_valid_q;
  reg [127:0] learn_pc_q,learn_target_q;
  reg [7:0] learn_length_q;
  always @(posedge clk_i)begin
    learn_pc_q<=align_pc_w;learn_target_q<=predicted_pc_w;
    learn_length_q<=align_length_w;
    if(rst_i||redirect_i||icache_invalidate_i)learn_valid_q<=0;
    else learn_valid_q<={(align_take_w==2&&divert1_w),
        (align_take_w==1&&divert0_w)};
  end
  R64FetchStream #(.DEPTH(1<<FETCH_PTR_W),.PTR_W(FETCH_PTR_W),.EARLY_PREDICT(EARLY_PREDICT),.RESET_PC(RESET_PC)) u_stream(
    .clk_i(clk_i),.rst_i(rst_i),.run_i(run_i),.redirect_i(stream_redirect_w),
    .redirect_block_i(stream_target_w[63:4]),.redirect_offset_i(stream_target_w[3:1]),
    .invalidate_i(icache_invalidate_i),
    .learn_i((|learn_valid_q)&&!redirect_i&&!icache_invalidate_i),
    .learn_pc_i(learn_valid_q[1]?learn_pc_q[127:64]:learn_pc_q[63:0]),
    .learn_length_i(learn_valid_q[1]?learn_length_q[7:4]:learn_length_q[3:0]),
    .learn_target_i(learn_valid_q[1]?learn_target_q[127:64]:learn_target_q[63:0]),
    .resolve_i(prediction_update_i),.resolve_pc_i(prediction_pc_i),.resolve_taken_i(prediction_taken_i),
    .resolve_target_i(prediction_target_i),
    .repair_i((|pending_kind_q[3:2])&&!redirect_i),.repair_block_i({55'b0,pending_source_q,4'b0}),
    .req_valid_o(fetch_v_w),.req_ready_i(fetch_r_w),
    .req_pc_o(fetch_pc_w),.rsp_valid_i(cache_v_w),.rsp_ready_o(cache_r_w),
    .rsp_data_i(cache_data_w),.rsp_fault_i(cache_fault_w),.rsp_cause_i(cache_cause_w),
    .rsp_access_mask_i(cache_mask_w),.packet_valid_o(packet_v_w),.packet_ready_i(packet_r_w),
    .packet_pc_o(packet_pc_w),.packet_data_o(packet_data_w),.packet_fault_o(packet_fault_w),
    .packet_cause_o(packet_cause_w),.packet_access_mask_o(packet_mask_w),
    .packet_plan_valid_o(packet_plan_v_w),.packet_plan_offset_o(packet_plan_offset_w),
    .packet_plan_word_o(packet_plan_word_w),.packet_plan_target_o(packet_plan_target_w)
  );
  // The Stream accepts against an explicit free owner, not a combinational
  // result from the current translation. Empty ingress stays transparent;
  // only a blocked transfer occupies this slot. Every accepted owner drains.
  reg if_req_valid_q,if_req_poison_q;
  reg [135:0] if_req_payload_q;
  wire if_req_ready_w;
  wire [63:0] if_req_va_w,if_req_satp_w;
  wire [1:0] if_req_priv_w;
  wire [4:0] if_req_status_w;
  wire if_req_pbmt_w;
  wire [63:0] if_req_mstatus_w={44'b0,if_req_status_w[4:2],4'b0,
      if_req_status_w[1:0],11'b0};
  wire if_req_cancel_w=stream_redirect_w||tlb_invalidate_i;
  wire if_req_poison_w=if_req_cancel_w||(if_req_valid_q&&if_req_poison_q);
  assign fetch_r_w=!rst_i&&!if_req_valid_q;
  assign {if_req_va_w,if_req_priv_w,if_req_satp_w,if_req_status_w,if_req_pbmt_w}=
    if_req_valid_q?if_req_payload_q:
      {fetch_pc_w,priv_i,satp_i,mstatus_i[19:17],mstatus_i[12:11],pbmt_enable_i};
  // Free payload writes do not wait for the long Translation ready decision.
  always @(posedge clk_i)if(!if_req_valid_q)
    if_req_payload_q<={fetch_pc_w,priv_i,satp_i,mstatus_i[19:17],mstatus_i[12:11],pbmt_enable_i};
  always @(posedge clk_i)begin
    if(rst_i)begin if_req_valid_q<=0;if_req_poison_q<=0;end
    else if(if_req_valid_q)begin
      if(if_req_cancel_w)if_req_poison_q<=1;
      if(if_req_ready_w)if_req_valid_q<=0;
    end else if(fetch_v_w&&!if_req_ready_w)begin
      if_req_valid_q<=1;if_req_poison_q<=if_req_cancel_w;
    end
  end
  R64FetchTranslation u_translation(
    .req_protection_i(4'b0),.rsp_protection_o(),.rsp_last_o(),
    .clk_i(clk_i),.rst_i(rst_i),.req_valid_i(if_req_valid_q||fetch_v_w),.req_ready_o(if_req_ready_w),
    .req_poison_i(if_req_poison_w),
    .req_vaddr_i(if_req_va_w),.req_access_i(2'd0),.req_priv_i(if_req_priv_w),
    .req_mstatus_i(if_req_mstatus_w),.req_satp_i(if_req_satp_w),.req_ad_update_i(1'b1),.req_pbmt_enable_i(if_req_pbmt_w),
    .rsp_valid_o(translation_v_w),.rsp_ready_i(translation_r_w),
    .rsp_priv_o(protect_priv_o),.rsp_paddr_o(protect_paddr_o),.rsp_pbmt_o(translation_pbmt_w),
    .rsp_needs_ad_o(translation_ad_w),.rsp_fault_o(translation_fault_w),.rsp_cause_o(translation_cause_w),
    .invalidate_i(tlb_invalidate_i),.invalidate_all_vaddr_i(tlb_all_vaddr_i),
    .invalidate_all_asid_i(tlb_all_asid_i),.invalidate_vpn_i(tlb_vpn_i),.invalidate_asid_i(tlb_asid_i),
    .mem_valid_o(pte_valid_o),.mem_ready_i(pte_ready_i),.mem_compare_or_o(pte_compare_or_o),
    .mem_addr_o(pte_addr_o),.mem_expected_o(pte_expected_o),.mem_or_mask_o(pte_or_mask_o),
    .mem_rsp_valid_i(pte_rsp_valid_i),.mem_rsp_ready_o(pte_rsp_ready_o),
    .mem_rdata_i(pte_rdata_i),.mem_error_i(pte_error_i),.mem_compare_ok_i(pte_compare_ok_i)
  );
  R64ICache #(.SET_W(ICACHE_SET_W),.PREPARED_PROTECTION(PREPARED_PROTECTION)) u_cache(
    .clk_i(clk_i),.rst_i(rst_i),.invalidate_i(icache_invalidate_i),
    .req_valid_i(translation_v_w),.req_ready_o(translation_r_w),.req_paddr_i(protect_paddr_o),
    .req_uncached_i(protect_uncached_i||translation_pbmt_w!=0),
    .req_fault_i(translation_fault_w),.req_cause_i(translation_cause_w),
    .req_access_mask_i(protect_fault_mask_i),.req_protection_facts_i(protect_facts_i),.rsp_valid_o(cache_v_w),.rsp_ready_i(cache_r_w),
    .rsp_data_o(cache_data_w),.rsp_fault_o(cache_fault_w),.rsp_cause_o(cache_cause_w),
    .rsp_access_mask_o(cache_mask_w),.cmd_valid_o(cache_cmd_valid_o),.cmd_ready_i(cache_cmd_ready_i),
    .cmd_addr_o(cache_cmd_addr_o),.cmd_len_o(cache_cmd_len_o),.cmd_size_o(cache_cmd_size_o),
    .beat_valid_i(cache_beat_valid_i),.beat_ready_o(cache_beat_ready_o),
    .beat_data_i(cache_beat_data_i),.beat_resp_i(cache_beat_resp_i),.beat_last_i(cache_beat_last_i)
  );
  // Alignment publishes complete instruction owners into two fixed bundles.
  // Credit is Q-only: prediction and downstream READY cannot feed length decode.
  wire [1:0] raw_align_v_w,raw_align_fault_w,raw_plan_at_w,raw_plan_bad_w;
  wire [127:0] raw_align_pc_w,raw_align_raw_w,raw_align_tval_w;
  wire [7:0] raw_align_length_w;
  wire [9:0] raw_align_cause_w;
  wire [63:0] raw_plan_target_w,raw_plan_source_w;
  wire [125:0] lookup_target_w;
  wire [1:0] lookup_target_hit_w,lookup_direction_valid_w,lookup_direction_w;
  reg [201:0] bundle_inst_q[0:3];
  reg [1:0] bundle_valid_q[0:1],bundle_at_q[0:1],bundle_bad_q[0:1];
  reg [63:0] bundle_target_q[0:1],bundle_source_q[0:1];
  reg bundle_head_q,bundle_tail_q,align_barrier_q;
  reg fault_barrier_q;
  reg [1:0] bundle_count_q;
  wire capture_w=run_i&&bundle_count_q<2&&!align_barrier_q&&!fault_barrier_q&&
      (raw_align_v_w[0]||raw_plan_bad_w[0]);
  wire [1:0] capture_take_w=!capture_w||raw_plan_bad_w[0]?2'd0:
      raw_align_v_w[1]&&!raw_plan_at_w[0]&&!raw_plan_bad_w[1]?2'd2:2'd1;
  wire capture_second_w=capture_take_w==2||
      (capture_w&&!raw_plan_bad_w[0]&&!raw_plan_at_w[0]&&raw_plan_bad_w[1]);
  wire capture_jump_w=(capture_take_w==1&&raw_plan_at_w[0])||
      (capture_take_w==2&&raw_plan_at_w[1]);
  wire [1:0] prep_in_align_v_w,prep_in_align_fault_w,prep_in_plan_at_w,prep_in_plan_bad_w;
  wire [127:0] prep_in_align_pc_w,prep_in_align_raw_w,prep_in_align_tval_w;
  wire [7:0] prep_in_align_length_w;
  wire [9:0] prep_in_align_cause_w;
  wire [63:0] prep_in_plan_target_w,prep_in_plan_source_w;
  wire [341:0] preparation_w;
  reg [471:0] token_inst_q[0:3]; // canonical33 + prediction preparation + original fetch
  reg [1:0] token_valid_q[0:1],token_at_q[0:1],token_bad_q[0:1];
  reg [63:0] token_target_q[0:1],token_source_q[0:1];
  reg token_head_q,token_tail_q;
  reg [1:0] token_count_q;
  wire token_capture_w=bundle_count_q!=0&&token_count_q<2&&!pending_redirect_w&&!fault_barrier_q;
  wire bundle_pop_w=token_capture_w;
  wire result_capture_w;
  wire [1:0] prediction_take_w;
  wire token_pop_w=result_capture_w;
  assign prep_in_align_v_w=bundle_count_q!=0?bundle_valid_q[bundle_head_q]:2'b0;
  assign {prep_in_align_tval_w[63:0],prep_in_align_cause_w[4:0],prep_in_align_fault_w[0],
      prep_in_align_length_w[3:0],prep_in_align_raw_w[63:0],prep_in_align_pc_w[63:0]}=
      bundle_inst_q[{bundle_head_q,1'b0}];
  assign {prep_in_align_tval_w[127:64],prep_in_align_cause_w[9:5],prep_in_align_fault_w[1],
      prep_in_align_length_w[7:4],prep_in_align_raw_w[127:64],prep_in_align_pc_w[127:64]}=
      bundle_inst_q[{bundle_head_q,1'b1}];
  assign prep_in_plan_at_w=bundle_count_q!=0?bundle_at_q[bundle_head_q]:2'b0;
  assign prep_in_plan_bad_w=bundle_count_q!=0?bundle_bad_q[bundle_head_q]:2'b0;
  assign prep_in_plan_target_w=bundle_target_q[bundle_head_q];
  assign prep_in_plan_source_w=bundle_source_q[bundle_head_q];
  always @(posedge clk_i)begin
    if(rst_i||stream_redirect_w)begin
      bundle_head_q<=0;bundle_tail_q<=0;bundle_count_q<=0;align_barrier_q<=0;
      bundle_valid_q[0]<=0;bundle_valid_q[1]<=0;
    end else begin
      bundle_count_q<=bundle_count_q+{1'b0,capture_w}-{1'b0,bundle_pop_w};
      if(bundle_pop_w)bundle_head_q<=!bundle_head_q;
      if(capture_w)begin
        bundle_tail_q<=!bundle_tail_q;
        bundle_valid_q[bundle_tail_q]<={capture_second_w,1'b1};
        bundle_at_q[bundle_tail_q]<=raw_plan_at_w&{capture_second_w,1'b1};
        bundle_bad_q[bundle_tail_q]<=raw_plan_bad_w&{capture_second_w,1'b1};

        if(raw_plan_bad_w[0]||(capture_second_w&&raw_plan_bad_w[1]))align_barrier_q<=1;
      end
    end
  end

  // A admission snapshots predictor tables from old Q at this same edge.
  // Registered bundle PC lookup runs beside expansion/arithmetic; held A
  // owners keep their snapshot across all later training generations.
  // A complete pair moves once into preparation storage. The A stage never
  // mutates the RAS; B admission remains the only prediction-side effect.
  // Normative compressed expansion runs in parallel with prediction prepare.
  // The original raw/length/fault fields remain intact for architectural trace
  // and exception TVAL; expansion shares their existing token lifetime.
  wire [65:0] prep_canonical_w,prediction_canonical_w,align_canonical_w;
  genvar prep_lane;
  generate for(prep_lane=0;prep_lane<2;prep_lane=prep_lane+1)begin:g_prepare
    wire [31:0] expanded_w;wire compressed_illegal_w;
    wire compressed_w=prep_in_align_length_w[prep_lane*4+:4]==2;
    R64Rvc rvc(.c_i(prep_in_align_raw_w[prep_lane*64+:16]),
      .inst_o(expanded_w),.illegal_o(compressed_illegal_w));
    assign prep_canonical_w[prep_lane*33+:33]={compressed_w&&compressed_illegal_w,
      compressed_w?expanded_w:prep_in_align_raw_w[prep_lane*64+:32]};
    R64PredictionPrepare prepare(
      .pc_i(prep_in_align_pc_w[prep_lane*64+:64]),
      .inst_i(prep_in_align_raw_w[prep_lane*64+:32]),
      .length_i(prep_in_align_length_w[prep_lane*4+:4]),
      .fault_i(prep_in_align_fault_w[prep_lane]),
      .planned_target_i(prep_in_plan_target_w),
      .previous_pc_i(prep_in_align_pc_w[63:0]),.previous_length_i(prep_in_align_length_w[3:0]),
      .preparation_o(preparation_w[prep_lane*171+:171]));
  end endgenerate
  wire [1:0] prediction_align_v_w,prediction_align_fault_w,prediction_plan_at_w,prediction_plan_bad_w;
  wire [127:0] prediction_align_pc_w,prediction_align_raw_w,prediction_align_tval_w;
  wire [7:0] prediction_align_length_w;
  wire [9:0] prediction_align_cause_w;
  wire [125:0] prediction_target_snapshot_w;
  wire [1:0] prediction_target_hit_snapshot_w,prediction_direction_valid_snapshot_w,prediction_direction_snapshot_w;
  wire [63:0] prediction_plan_target_w,prediction_plan_source_w;
  wire [341:0] prediction_preparation_snapshot_w;
  wire [127:0] prediction_pc_w,prediction_return_pc_w;
  wire [1:0] prediction_taken_w,prediction_push_w,unused_prediction_divert_w,unused_prediction_match_w;
  wire [5:0] prediction_write_index_w,prediction_post_pointer_w;
  wire [7:0] prediction_post_count_w;
  assign prediction_align_v_w=token_count_q!=0?token_valid_q[token_head_q]:2'b0;
  assign {prediction_canonical_w[32:0],prediction_preparation_snapshot_w[170:0],prediction_target_snapshot_w[62:0],prediction_target_hit_snapshot_w[0],
      prediction_direction_valid_snapshot_w[0],prediction_direction_snapshot_w[0],prediction_align_tval_w[63:0],prediction_align_cause_w[4:0],prediction_align_fault_w[0],
      prediction_align_length_w[3:0],prediction_align_raw_w[63:0],prediction_align_pc_w[63:0]}=
      token_inst_q[{token_head_q,1'b0}];
  assign {prediction_canonical_w[65:33],prediction_preparation_snapshot_w[341:171],prediction_target_snapshot_w[125:63],prediction_target_hit_snapshot_w[1],
      prediction_direction_valid_snapshot_w[1],prediction_direction_snapshot_w[1],prediction_align_tval_w[127:64],prediction_align_cause_w[9:5],prediction_align_fault_w[1],
      prediction_align_length_w[7:4],prediction_align_raw_w[127:64],prediction_align_pc_w[127:64]}=
      token_inst_q[{token_head_q,1'b1}];
  assign prediction_plan_at_w=token_count_q!=0?token_at_q[token_head_q]:2'b0;
  assign prediction_plan_bad_w=token_count_q!=0?token_bad_q[token_head_q]:2'b0;
  assign prediction_plan_target_w=token_target_q[token_head_q];
  assign prediction_plan_source_w=token_source_q[token_head_q];
  always @(posedge clk_i)begin
    if(rst_i||stream_redirect_w)begin
      token_head_q<=0;token_tail_q<=0;token_count_q<=0;
      token_valid_q[0]<=0;token_valid_q[1]<=0;
    end else begin
      token_count_q<=token_count_q+{1'b0,token_capture_w}-{1'b0,token_pop_w};
      if(token_pop_w)token_head_q<=!token_head_q;
      if(token_capture_w)begin
        token_tail_q<=!token_tail_q;
        token_valid_q[token_tail_q]<=bundle_valid_q[bundle_head_q];
        token_at_q[token_tail_q]<=bundle_at_q[bundle_head_q];
        token_bad_q[token_tail_q]<=bundle_bad_q[bundle_head_q];

      end
    end
  end
  // Producers may prepare payload in the currently unowned tail slot.
  // Admission/redirect updates only ownership; a live slot is never overwritten.
  // A partially consumed result selects its remaining physical lane instead
  // of moving 410 data bits through the late validation/consume path.
  always @(posedge clk_i)begin
    if(bundle_count_q<2)begin
        bundle_target_q[bundle_tail_q]<=raw_plan_target_w;
        bundle_source_q[bundle_tail_q]<=raw_plan_source_w;
        bundle_inst_q[{bundle_tail_q,1'b0}]<={raw_align_tval_w[63:0],
            raw_align_cause_w[4:0],raw_align_fault_w[0],raw_align_length_w[3:0],
            raw_align_raw_w[63:0],raw_align_pc_w[63:0]};
        bundle_inst_q[{bundle_tail_q,1'b1}]<={raw_align_tval_w[127:64],
            raw_align_cause_w[9:5],raw_align_fault_w[1],raw_align_length_w[7:4],
            raw_align_raw_w[127:64],raw_align_pc_w[127:64]};
    end
  end
  always @(posedge clk_i)begin
    if(token_count_q<2)begin
        token_target_q[token_tail_q]<=bundle_target_q[bundle_head_q];
        token_source_q[token_tail_q]<=bundle_source_q[bundle_head_q];
        token_inst_q[{token_tail_q,1'b0}]<={prep_canonical_w[32:0],preparation_w[170:0],
            lookup_target_w[62:0],lookup_target_hit_w[0],
            lookup_direction_valid_w[0],lookup_direction_w[0],
            bundle_inst_q[{bundle_head_q,1'b0}]};
        token_inst_q[{token_tail_q,1'b1}]<={prep_canonical_w[65:33],preparation_w[341:171],
            lookup_target_w[125:63],lookup_target_hit_w[1],
            lookup_direction_valid_w[1],lookup_direction_w[1],
            bundle_inst_q[{bundle_head_q,1'b1}]};
    end
  end
  always @(posedge clk_i)begin
    if(result_count_q<2)begin
        result_target_q[result_tail_q]<=prediction_plan_target_w;result_source_q[result_tail_q]<=prediction_plan_source_w;
        result_inst_q[{result_tail_q,1'b0}]<={prediction_control_w[34:0],prediction_canonical_w[32:0],prediction_post_count_w[3:0],prediction_post_pointer_w[2:0],
            prediction_write_index_w[2:0],prediction_push_w[0],prediction_taken_w[0],
            prediction_return_pc_w[63:0],prediction_pc_w[63:0],
            prediction_align_tval_w[63:0],prediction_align_cause_w[4:0],prediction_align_fault_w[0],
            prediction_align_length_w[3:0],prediction_align_raw_w[63:0],prediction_align_pc_w[63:0]};
        result_inst_q[{result_tail_q,1'b1}]<={prediction_control_w[69:35],prediction_canonical_w[65:33],prediction_post_count_w[7:4],prediction_post_pointer_w[5:3],
            prediction_write_index_w[5:3],prediction_push_w[1],prediction_taken_w[1],
            prediction_return_pc_w[127:64],prediction_pc_w[127:64],
            prediction_align_tval_w[127:64],prediction_align_cause_w[9:5],prediction_align_fault_w[1],
            prediction_align_length_w[7:4],prediction_align_raw_w[127:64],prediction_align_pc_w[127:64]};
    end
  end
  R64Align #(.RESET_PC(RESET_PC),.EARLY_PREDICT(EARLY_PREDICT)) u_align(
    .clk_i(clk_i),.rst_i(rst_i),.redirect_i(stream_redirect_w),.redirect_pc_i(stream_target_w),
    .packet_valid_i(packet_v_w),.packet_ready_o(packet_r_w),.packet_pc_i(packet_pc_w),
    .packet_data_i(packet_data_w),.packet_fault_i(packet_fault_w),.packet_cause_i(packet_cause_w),
    .packet_access_mask_i(packet_mask_w),
    .packet_plan_valid_i(packet_plan_v_w),.packet_plan_offset_i(packet_plan_offset_w),
    .packet_plan_word_i(packet_plan_word_w),.packet_plan_target_i(packet_plan_target_w),
    .jump_i(capture_jump_w),.jump_pc_i(raw_plan_target_w),
    .plan_at_o(raw_plan_at_w),.plan_bad_o(raw_plan_bad_w),.plan_target_o(raw_plan_target_w),.plan_source_o(raw_plan_source_w),
    .valid_o(raw_align_v_w),.consume_i(capture_take_w),
    .pc0_o(raw_align_pc_w[63:0]),.pc1_o(raw_align_pc_w[127:64]),
    .inst0_o(raw_align_raw_w[63:0]),.inst1_o(raw_align_raw_w[127:64]),
    .length0_o(raw_align_length_w[3:0]),.length1_o(raw_align_length_w[7:4]),
    .fault0_o(raw_align_fault_w[0]),.fault1_o(raw_align_fault_w[1]),
    .cause0_o(raw_align_cause_w[4:0]),.cause1_o(raw_align_cause_w[9:5]),
    .tval0_o(raw_align_tval_w[63:0]),.tval1_o(raw_align_tval_w[127:64])
  );

  // Static encoding work shares the existing A -> B edge with prediction.
  // Its raw/length/canonical owner is unchanged by later dynamic exceptions.
  wire [69:0] prediction_control_w,align_control_w;
  genvar control_lane;
  generate for(control_lane=0;control_lane<2;control_lane=control_lane+1)begin:gen_encoding_control
    R64DecodeControl prepare(
      .canonical_i(prediction_canonical_w[control_lane*33+:33]),
      .raw_i(prediction_align_raw_w[control_lane*64+:64]),
      .length_i(prediction_align_length_w[control_lane*4+:4]),
      .control_o(prediction_control_w[control_lane*35+:35]));
  end endgenerate

  // B materializes a prediction token. C owns validation and actual admission.
  // Speculative RAS writes stay in these owners until C confirms their prefix.
  reg [409:0] result_inst_q[0:3]; // original202 + NPC64 + return64 + taken/push/index/post
  reg [1:0] result_valid_q[0:1],result_at_q[0:1],result_bad_q[0:1],result_ras_valid_q[0:1];
  reg [63:0] result_target_q[0:1],result_source_q[0:1];
  reg result_head_q,result_tail_q;
  reg [1:0] result_half_q;
  reg [1:0] result_count_q;
  wire [1:0] result_ras_valid_w,result_push_w;
  wire [5:0] result_index_w,result_pointer_w;
  wire [7:0] result_count_w;
  wire [127:0] result_return_pc_w;
  wire [3:0] ras_journal_valid_w;
  wire [11:0] ras_journal_index_w;
  wire [251:0] ras_journal_data_w;
  assign result_capture_w=token_count_q!=0&&result_count_q<2&&!pending_redirect_w&&!fault_barrier_q;
  assign prediction_take_w=!result_capture_w?2'd0:(prediction_align_v_w[1]?2'd2:2'd1);
  wire result_pop_w=align_take_w!=0&&
      (align_take_w==2||!align_v_w[1]||divert0_w||plan_at_w[0]);
  assign align_v_w=result_count_q!=0?result_valid_q[result_head_q]:2'b0;
  assign {align_control_w[34:0],align_canonical_w[32:0],result_count_w[3:0],result_pointer_w[2:0],result_index_w[2:0],result_push_w[0],
      predicted_taken_w[0],result_return_pc_w[63:0],predicted_pc_w[63:0],
      align_tval_w[63:0],align_cause_w[4:0],align_fault_w[0],align_length_w[3:0],align_raw_w[63:0],align_pc_w[63:0]}=
      result_inst_q[{result_head_q,result_half_q[result_head_q]}];
  assign {align_control_w[69:35],align_canonical_w[65:33],result_count_w[7:4],result_pointer_w[5:3],result_index_w[5:3],result_push_w[1],
      predicted_taken_w[1],result_return_pc_w[127:64],predicted_pc_w[127:64],
      align_tval_w[127:64],align_cause_w[9:5],align_fault_w[1],align_length_w[7:4],align_raw_w[127:64],align_pc_w[127:64]}=
      result_inst_q[{result_head_q,1'b1}];
  assign result_ras_valid_w=result_ras_valid_q[result_head_q];
  assign plan_at_w=result_count_q!=0?result_at_q[result_head_q]:2'b0;
  assign plan_bad_w=result_count_q!=0?result_bad_q[result_head_q]:2'b0;
  assign plan_target_w=result_target_q[result_head_q];assign plan_source_w=result_source_q[result_head_q];
  assign predicted_match_w={predicted_pc_w[127:64]==plan_target_w,predicted_pc_w[63:0]==plan_target_w};
  assign predicted_divert_w=predicted_taken_w&
      {predicted_pc_w[127:64]!=result_return_pc_w[127:64],predicted_pc_w[63:0]!=result_return_pc_w[63:0]};
  genvar journal_lane;
  generate for(journal_lane=0;journal_lane<4;journal_lane=journal_lane+1)begin:g_result_journal
    wire pair_w=journal_lane<2?result_head_q:!result_head_q;
    wire lane_w=(journal_lane%2)!=0;
    wire physical_lane_w=lane_w||result_half_q[pair_w];
    wire [341:0] payload_w=result_inst_q[{pair_w,physical_lane_w}][341:0];
    assign ras_journal_valid_w[journal_lane]=result_count_q>journal_lane/2&&
      result_valid_q[pair_w][lane_w]&&result_ras_valid_q[pair_w][lane_w]&&payload_w[331];
    assign ras_journal_index_w[journal_lane*3+:3]=payload_w[334:332];
    assign ras_journal_data_w[journal_lane*63+:63]=payload_w[329:267];
  end endgenerate
  always @(posedge clk_i)begin
    if(rst_i||stream_redirect_w)begin
      result_head_q<=0;result_tail_q<=0;result_count_q<=0;result_half_q<=0;
      result_valid_q[0]<=0;result_valid_q[1]<=0;
      result_ras_valid_q[0]<=0;result_ras_valid_q[1]<=0;
    end else begin
      result_count_q<=result_count_q+{1'b0,result_capture_w}-{1'b0,result_pop_w};
      if(result_pop_w)result_head_q<=!result_head_q;
      else if(align_take_w==1)begin
        result_half_q[result_head_q]<=1'b1;
        result_valid_q[result_head_q]<=2'b01;
        result_at_q[result_head_q]<={1'b0,result_at_q[result_head_q][1]};
        result_bad_q[result_head_q]<={1'b0,result_bad_q[result_head_q][1]};
        result_ras_valid_q[result_head_q]<={1'b0,result_ras_valid_q[result_head_q][1]};
      end
      if(result_capture_w)begin
        result_tail_q<=!result_tail_q;
        result_half_q[result_tail_q]<=0;
        result_valid_q[result_tail_q]<=prediction_align_v_w;
        result_at_q[result_tail_q]<=prediction_plan_at_w;result_bad_q[result_tail_q]<=prediction_plan_bad_w;

        result_ras_valid_q[result_tail_q]<=prediction_align_v_w;

      end
      // Old prediction hints may remain, but no pre-invalidate journal or
      // checkpoint can resurrect its stack history. This also covers birth.
      if(icache_invalidate_i)begin result_ras_valid_q[0]<=0;result_ras_valid_q[1]<=0;end
    end
  end
  R64Predictor u_predictor(
    .rollback_i(pending_redirect_w),
    .confirm_i(align_take_w),.confirm_state_valid_i(result_ras_valid_w),.confirm_push_i(result_push_w),
    .confirm_index_i(result_index_w),.confirm_pointer_i(result_pointer_w),.confirm_count_i(result_count_w),
    .confirm_data_i({result_return_pc_w[127:65],result_return_pc_w[63:1]}),
    .journal_valid_i(ras_journal_valid_w),.journal_index_i(ras_journal_index_w),.journal_data_i(ras_journal_data_w),
    .write_index_o(prediction_write_index_w),.post_pointer_o(prediction_post_pointer_w),
    .post_count_o(prediction_post_count_w),.push_o(prediction_push_w),.return_pc_o(prediction_return_pc_w),
    .consume_i(prediction_take_w),.recover_i(redirect_i),.preparation_i(prediction_preparation_snapshot_w),
    .clk_i(clk_i),.rst_i(rst_i),.invalidate_i(icache_invalidate_i),
    .lookup_pc_i(prep_in_align_pc_w),.lookup_target_o(lookup_target_w),
    .lookup_target_hit_o(lookup_target_hit_w),.lookup_direction_valid_o(lookup_direction_valid_w),
    .lookup_direction_o(lookup_direction_w),.target_snapshot_i(prediction_target_snapshot_w),
    .target_hit_snapshot_i(prediction_target_hit_snapshot_w),.direction_valid_snapshot_i(prediction_direction_valid_snapshot_w),
    .direction_snapshot_i(prediction_direction_snapshot_w),
    .pc_i(prediction_align_pc_w),.inst_i({prediction_align_raw_w[95:64],prediction_align_raw_w[31:0]}),
    .length_i(prediction_align_length_w),.fault_i(prediction_align_fault_w),
    .planned_target_i(prediction_plan_target_w),.planned_match_o(unused_prediction_match_w),
    .next_pc_o(prediction_pc_w),.taken_o(prediction_taken_w),.divert_o(unused_prediction_divert_w),
    .update_i(prediction_update_i),.update_pc_i(prediction_pc_i),
    .update_conditional_i(prediction_conditional_i),.update_indirect_i(prediction_indirect_i),
    .update_taken_i(prediction_taken_i),.update_target_i(prediction_target_i)
  );

  // Once an instruction fault is admitted, younger instruction owners stay
  // buffered until architectural recovery. The FIFO ends at that exact fault.
  always @(posedge clk_i)begin
    if(rst_i||redirect_i)fault_barrier_q<=0;
    else if((align_take_w!=0&&align_fault_w[0])||
        (align_take_w==2&&align_fault_w[1]))fault_barrier_q<=1;
  end
  reg [397:0] instruction_q[0:3]; // sequential NPC and canonical33 share the same owner
  reg [1:0] head_q,tail_q;
  reg [2:0] count_q;
  wire [1:0] head1_w=head_q+2'd1,tail1_w=tail_q+2'd1;
  wire [2:0] room_w=3'd4-count_q;
  wire divert0_w=predicted_divert_w[0],divert1_w=predicted_divert_w[1];
  wire repair0_w=plan_bad_w[0]||(plan_at_w[0]&&
      (align_fault_w[0]||!predicted_taken_w[0]||!predicted_match_w[0]));
  wire repair1_w=plan_bad_w[1]||(plan_at_w[1]&&
      (align_fault_w[1]||!predicted_taken_w[1]||!predicted_match_w[1]));
  wire [1:0] base_take_w=redirect_i||pending_redirect_w||fault_barrier_q||!align_v_w[0]||room_w==0?2'd0:
    (align_v_w[1]&&!divert0_w&&!plan_at_w[0]&&room_w>=2?2'd2:2'd1);
  // A stale cut may lie inside a 32/64-bit instruction. Repair before that
  // instruction is admitted; a preceding complete lane can still enter FIFO.
  assign plan_repair_w=!redirect_i&&!pending_redirect_w&&!fault_barrier_q&&(repair0_w||(base_take_w==2&&repair1_w));
  assign align_take_w=redirect_i||pending_redirect_w||repair0_w?2'd0:
    ((base_take_w==2&&repair1_w)?2'd1:base_take_w);
  assign planned_jump_w=!redirect_i&&!plan_repair_w&&
    ((align_take_w==1&&plan_at_w[0])||(align_take_w==2&&plan_at_w[1]));
  assign predicted_redirect_w=plan_repair_w||(!planned_jump_w&&
    ((align_take_w==1&&divert0_w)||(align_take_w==2&&divert1_w)));
  assign valid_o=rst_i||redirect_i?2'b0:{count_q>=2,count_q!=0};
  assign {control_o[34:0],sequential_npc_o[63:0],canonical_o[32:0],tval_o[63:0],cause_o[4:0],fault_o[0],predicted_npc_o[63:0],length_o[3:0],raw_o[63:0],pc_o[63:0]}=
    instruction_q[head_q];
  assign {control_o[69:35],sequential_npc_o[127:64],canonical_o[65:33],tval_o[127:64],cause_o[9:5],fault_o[1],predicted_npc_o[127:64],length_o[7:4],raw_o[127:64],pc_o[127:64]}=
    instruction_q[head1_w];
  always @(posedge clk_i) begin
    if(rst_i||redirect_i) begin head_q<=0;tail_q<=0;count_q<=0;end
    else begin
      head_q<=head_q+consume_i;tail_q<=tail_q+align_take_w;
      count_q<=count_q+{1'b0,align_take_w}-{1'b0,consume_i};
    end
  end
  // Payload may be prepared only in a slot unowned in the current Q state.
  // Current backend consumption never grants combinational credit. Real admission
  // advances tail/count and grants ownership. This removes late prediction/
  // repair decisions from the instruction storage write-enable cone.
  // Flushing clears all owners at the same edge; payload needs no flush gate.
  always @(posedge clk_i)begin
    if(room_w>=1)
      instruction_q[tail_q]<={align_control_w[34:0],result_return_pc_w[63:0],align_canonical_w[32:0],align_tval_w[63:0],align_cause_w[4:0],align_fault_w[0],
        predicted_pc_w[63:0],align_length_w[3:0],align_raw_w[63:0],align_pc_w[63:0]};
    if(room_w>=2)
      instruction_q[tail1_w]<={align_control_w[69:35],result_return_pc_w[127:64],align_canonical_w[65:33],align_tval_w[127:64],align_cause_w[9:5],align_fault_w[1],
        predicted_pc_w[127:64],align_length_w[7:4],align_raw_w[127:64],align_pc_w[127:64]};
  end
  wire unused_translation_ad_w=translation_ad_w;
`ifdef R64_ASSERT
  genvar static_check_lane;
  generate for(static_check_lane=0;static_check_lane<2;static_check_lane=static_check_lane+1)begin:gen_control_owner_check
    wire [34:0] b_expected_w,c_expected_w;
    R64DecodeControl b_checker(.canonical_i(align_canonical_w[static_check_lane*33+:33]),
      .raw_i(align_raw_w[static_check_lane*64+:64]),.length_i(align_length_w[static_check_lane*4+:4]),
      .control_o(b_expected_w));
    R64DecodeControl c_checker(.canonical_i(canonical_o[static_check_lane*33+:33]),
      .raw_i(raw_o[static_check_lane*64+:64]),.length_i(length_o[static_check_lane*4+:4]),
      .control_o(c_expected_w));
    always @(posedge clk_i)if(!rst_i&&!redirect_i)begin
      if(align_v_w[static_check_lane]&&align_control_w[static_check_lane*35+:35]!==b_expected_w)
        $fatal(1,"B static controls separated from canonical raw/length owner");
      if(valid_o[static_check_lane]&&control_o[static_check_lane*35+:35]!==c_expected_w)
        $fatal(1,"C static controls separated from canonical raw/length owner");
    end
  end endgenerate

  genvar npc_lane;
  generate for(npc_lane=0;npc_lane<2;npc_lane=npc_lane+1)begin:gen_sequential_npc_check
    always @(posedge clk_i)if(!rst_i&&!redirect_i)begin
      if(align_take_w>npc_lane&&result_return_pc_w[npc_lane*64+:64]!==align_pc_w[npc_lane*64+:64]+{60'b0,align_length_w[npc_lane*4+:4]})
        $fatal(1,"frontend prepared sequential NPC disagrees with its instruction owner");
      if(valid_o[npc_lane]&&sequential_npc_o[npc_lane*64+:64]!==pc_o[npc_lane*64+:64]+{60'b0,length_o[npc_lane*4+:4]})
        $fatal(1,"frontend sequential NPC separated from held instruction");
    end
  end endgenerate

  always @(posedge clk_i) if(!rst_i) begin
    if(!redirect_i&&({1'b0,consume_i}>count_q||consume_i==3))
      $fatal(1,"frontend consumed beyond valid instruction prefix");
    if(pending_redirect_w&&(align_take_w!=0||predicted_redirect_w))
      $fatal(1,"frontend admitted a young instruction behind pending redirect");
    if((pending_kind_q&(pending_kind_q-4'd1))!=0)
      $fatal(1,"frontend redirect record has multiple owners");
    if(result_count_q!=0&&align_fault_w[0]&&align_v_w[1])
      $fatal(1,"frontend bundle admitted a lane after an instruction fault");
    if(!redirect_i)begin
      if(room_w>=1&&{1'b0,tail_q-head_q}<count_q)
        $fatal(1,"frontend prepared payload overwrote unconsumed lane0 owner");
      if(room_w>=2&&{1'b0,tail1_w-head_q}<count_q)
        $fatal(1,"frontend prepared payload overwrote unconsumed lane1 owner");
    end
    if(result_count_q>2)$fatal(1,"frontend prediction result overflow");
    if(token_count_q>2)$fatal(1,"frontend prediction token overflow");
    if(bundle_count_q>2)$fatal(1,"frontend alignment bundle overflow");
    if(count_q>4)$fatal(1,"frontend instruction FIFO overflow");
    if(translation_v_w&&!translation_fault_w&&translation_ad_w)
      $fatal(1,"fetch translation returned unauthorized A update");
  end
`endif
endmodule
