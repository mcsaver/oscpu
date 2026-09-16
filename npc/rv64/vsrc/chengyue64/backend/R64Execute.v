`include "R64Uop.vh"
// Native execution boundary. ALUs each have a result holder; multiply,
// divide and carryless multiply own their internal state and independent WB
// holders. External owners receive admission pulses and retain transactions.
module R64Execute #(parameter PREPARED_CANCEL=0,parameter TAG_W=9,parameter ROB_W=5,parameter PREG_W=6,parameter LSQ_W=5,parameter RAW_SERIAL=0,parameter RAW_FP=0,parameter RAW_MEM=0,parameter DIRECT_MEM_BIND=0,parameter EARLY_ALU_WAKE=0)(
  input clk,input rst,input flush_i,input [(1<<ROB_W)-1:0] kill_mask_i,
  input [(1<<ROB_W)-1:0] cancel_candidates_i,input cancel_active_i,
  input [ROB_W-1:0] rob_head_i,
  input [1:0] in_valid_i,output reg [1:0] in_ready_o,
  input [2*TAG_W-1:0] in_tag_i,input [2*LSQ_W-1:0] in_mem_slot_i,input [2*`R64_UOP_W-1:0] in_uop_i,
  input [5:0] in_class_i,input [383:0] in_operand_i,
  input [2*PREG_W-1:0] in_gpr_dst_i,input [73:0] in_alu_control_i,input [9:0] in_add_source_i,input [11:0] in_shift_amount_i,
  input [41:0] in_branch_imm_i,input [9:0] in_branch_control_i,
  output [5:0] rr_fu_credit_o,
  output [1:0] early_valid_o,output [2*PREG_W-1:0] early_preg_o,
  output [2*TAG_W-1:0] early_tag_o,
  output [1:0] alu_bypass_valid_o,output [2*PREG_W-1:0] alu_bypass_preg_o,
  output [127:0] alu_bypass_data_o,
  output [4:0] result_valid_o,input [4:0] result_ready_i,
  output [5*TAG_W-1:0] result_tag_o,output [5*`R64_RESULT_W-1:0] result_o,
  output recovery_preview_valid_o,output [TAG_W-1:0] recovery_preview_tag_o,
  output resolve_valid_o,output [TAG_W-1:0] resolve_tag_o,
  output [63:0] resolve_npc_o,output redirect_valid_o,output redirect_pending_o,
  output [63:0] resolve_pc_o,output resolve_conditional_o,
  output resolve_indirect_o,output resolve_taken_o,
  input [1:0] lsu_ready_i,output reg [1:0] lsu_fire_o,
  output reg [2*TAG_W-1:0] lsu_tag_o,output reg [2*`R64_UOP_W-1:0] lsu_uop_o,
  output reg [383:0] lsu_operand_o,output reg [2*LSQ_W-1:0] lsu_slot_o,
  input fp_ready_i,output reg fp_fire_o,output reg [TAG_W-1:0] fp_tag_o,
  output reg [`R64_UOP_W-1:0] fp_uop_o,output reg [191:0] fp_operand_o,
  input serial_ready_i,output reg serial_fire_o,output reg [TAG_W-1:0] serial_tag_o,
  output reg [`R64_UOP_W-1:0] serial_uop_o,output reg [191:0] serial_operand_o
);
  // Select this registered owner's candidate bit before applying the late
  // redirect enable. The ordinary mask remains the default module contract.
  function cancel_selected;
    input [ROB_W-1:0] slot;
    input [(1<<ROB_W)-1:0] candidates,mask;
    input active;
    begin cancel_selected=PREPARED_CANCEL ?
        (active&&candidates[slot]):mask[slot];end
  endfunction

  wire [`R64_UOP_W-1:0] uop_w[0:1];
  wire [TAG_W-1:0] tag_w[0:1];
  wire [2:0] class_w[0:1];
  wire [191:0] operand_w[0:1];
  wire [ROB_W-1:0] age_w[0:1];
  wire [1:0] live_w;
  genvar l;
  generate for(l=0;l<2;l=l+1)begin:gen_input
    assign uop_w[l]=in_uop_i[l*`R64_UOP_W+:`R64_UOP_W];
    assign tag_w[l]=in_tag_i[l*TAG_W+:TAG_W];
    assign class_w[l]=in_class_i[l*3+:3];
    assign operand_w[l]=in_operand_i[l*192+:192];
    assign age_w[l]=tag_w[l][ROB_W-1:0]-rob_head_i;
    assign live_w[l]=in_valid_i[l]&&!rst&&!flush_i&&!cancel_selected(tag_w[l][ROB_W-1:0],cancel_candidates_i,kill_mask_i,cancel_active_i);
  end endgenerate
  wire older1_w=age_w[1]<age_w[0];
  wire [1:0] alu_candidate_w;
  wire [1:0] alu_ready_w,alu_fire_w;

  wire [1:0] branch_w,branch_resolve_w,branch_redirect_w,branch_pending_w;
  wire [1:0] branch_preview_w;wire [2*TAG_W-1:0] branch_preview_tag_w;
  reg resolve_lane_q;
  always @(posedge clk) resolve_lane_q<=!branch_preview_w[0];
  assign recovery_preview_valid_o=|branch_preview_w;
  assign recovery_preview_tag_o=branch_preview_w[0] ? branch_preview_tag_w[0+:TAG_W]:branch_preview_tag_w[TAG_W+:TAG_W];
  wire [2*TAG_W-1:0] branch_tag_w;
  wire [127:0] branch_npc_w,branch_pc_w;
  wire [1:0] branch_conditional_w,branch_indirect_w,branch_taken_w;
  generate for(l=0;l<2;l=l+1)begin:gen_alu
    assign branch_w[l]=live_w[l]&&class_w[l]==`R64_C_BRANCH;
    wire competing_branch_w=branch_w[1-l]&&(l==0 ? older1_w:!older1_w);
    assign alu_candidate_w[l]=live_w[l]&&(class_w[l]==`R64_C_ALU||
        (class_w[l]==`R64_C_BRANCH&&!competing_branch_w));
    assign alu_fire_w[l]=alu_candidate_w[l]&&alu_ready_w[l];
    R64AluLane #(.TAG_W(TAG_W),.ROB_W(ROB_W),.PREG_W(PREG_W),.EARLY_ACCEPT(EARLY_ALU_WAKE)) lane(
      .clk(clk),.rst(rst),.flush_i(flush_i),.kill_mask_i(kill_mask_i),
      .early_candidate_i(in_valid_i[l]&&class_w[l]==`R64_C_ALU),
      .in_fire_i(alu_fire_w[l]),.in_ready_o(alu_ready_w[l]),
      .in_tag_i(tag_w[l]),.in_uop_i(uop_w[l]),.in_branch_i(class_w[l]==`R64_C_BRANCH),
      .in_branch_imm_i(in_branch_imm_i[l*21+:21]),.in_branch_control_i(in_branch_control_i[l*5+:5]),
      .in_control_i(in_alu_control_i[l*37+:37]),.in_add_source_i(in_add_source_i[l*5+:5]),.in_shift_amount_i(in_shift_amount_i[l*6+:6]),.in_operand_i(operand_w[l]),
      .in_preg_i(in_gpr_dst_i[l*PREG_W+:PREG_W]),
      .early_valid_o(early_valid_o[l]),.early_preg_o(early_preg_o[l*PREG_W+:PREG_W]),
      .early_tag_o(early_tag_o[l*TAG_W+:TAG_W]),
      .bypass_valid_o(alu_bypass_valid_o[l]),.bypass_preg_o(alu_bypass_preg_o[l*PREG_W+:PREG_W]),
      .bypass_data_o(alu_bypass_data_o[l*64+:64]),
      .out_valid_o(result_valid_o[l]),.out_ready_i(result_ready_i[l]),
      .out_tag_o(result_tag_o[l*TAG_W+:TAG_W]),.out_result_o(result_o[l*`R64_RESULT_W+:`R64_RESULT_W]),
      .recovery_preview_valid_o(branch_preview_w[l]),.recovery_preview_tag_o(branch_preview_tag_w[l*TAG_W+:TAG_W]),
      .resolve_valid_o(branch_resolve_w[l]),.redirect_o(branch_redirect_w[l]),.redirect_pending_o(branch_pending_w[l]),
      .resolve_tag_o(branch_tag_w[l*TAG_W+:TAG_W]),.resolve_npc_o(branch_npc_w[l*64+:64]),
      .resolve_pc_o(branch_pc_w[l*64+:64]),.conditional_o(branch_conditional_w[l]),
      .indirect_o(branch_indirect_w[l]),.taken_o(branch_taken_w[l]));
  end endgenerate
  assign resolve_valid_o=|branch_resolve_w;
  assign redirect_valid_o=|(branch_resolve_w&branch_redirect_w);
  assign redirect_pending_o=|branch_pending_w;
  assign resolve_tag_o=resolve_lane_q ? branch_tag_w[TAG_W+:TAG_W]:branch_tag_w[0+:TAG_W];
  assign resolve_npc_o=resolve_lane_q ? branch_npc_w[64+:64]:branch_npc_w[0+:64];
  assign resolve_pc_o=resolve_lane_q ? branch_pc_w[64+:64]:branch_pc_w[0+:64];
  assign resolve_conditional_o=resolve_lane_q ? branch_conditional_w[1]:branch_conditional_w[0];
  assign resolve_indirect_o=resolve_lane_q ? branch_indirect_w[1]:branch_indirect_w[0];
  assign resolve_taken_o=resolve_lane_q ? branch_taken_w[1]:branch_taken_w[0];
  wire [2:0] long_ready_w;
  // These capacities do not depend on the selected RR class/tag or fire.
  // Only a fire publishes the chosen RR candidate to a downstream owner.
  assign rr_fu_credit_o={fp_ready_i,long_ready_w,alu_ready_w};
  wire [2:0] long_valid_w;
  reg [2:0] long_fire_w;
  reg [TAG_W-1:0] long_tag_w[0:2];
  reg [63:0] long_a_w[0:2],long_b_w[0:2];
  reg [2:0] long_function_w[0:2];
  reg [2:0] long_word_w;
  wire [TAG_W-1:0] long_result_tag_w[0:2];
  wire [63:0] long_result_data_w[0:2];
  R64Multiply #(.PREQUALIFIED_INPUT(1)) multiply(.clk(clk),.rst(rst),.flush_i(flush_i),.kill_mask_i(kill_mask_i),
    .in_valid_i(long_fire_w[0]),.in_ready_o(long_ready_w[0]),.in_tag_i(long_tag_w[0]),
    .a_i(long_a_w[0]),.b_i(long_b_w[0]),.function_i(long_function_w[0]),.word_i(long_word_w[0]),
    .out_valid_o(long_valid_w[0]),.out_ready_i(result_ready_i[2]),
    .out_tag_o(long_result_tag_w[0]),.out_data_o(long_result_data_w[0]));
  R64Divide #(.PREQUALIFIED_INPUT(1)) divide(.clk(clk),.rst(rst),.flush_i(flush_i),.kill_mask_i(kill_mask_i),
    .in_valid_i(long_fire_w[1]),.in_ready_o(long_ready_w[1]),.in_tag_i(long_tag_w[1]),
    .a_i(long_a_w[1]),.b_i(long_b_w[1]),.function_i(long_function_w[1]),.word_i(long_word_w[1]),
    .out_valid_o(long_valid_w[1]),.out_ready_i(result_ready_i[3]),
    .out_tag_o(long_result_tag_w[1]),.out_data_o(long_result_data_w[1]));
  R64Clmul #(.PREQUALIFIED_INPUT(1)) clmul(.clk(clk),.rst(rst),.flush_i(flush_i),.kill_mask_i(kill_mask_i),
    .in_valid_i(long_fire_w[2]),.in_ready_o(long_ready_w[2]),.in_tag_i(long_tag_w[2]),
    .a_i(long_a_w[2]),.b_i(long_b_w[2]),.function_i(long_function_w[2][1:0]),
    .out_valid_o(long_valid_w[2]),.out_ready_i(result_ready_i[4]),
    .out_tag_o(long_result_tag_w[2]),.out_data_o(long_result_data_w[2]));
  generate for(l=0;l<3;l=l+1)begin:gen_long_result
    assign result_valid_o[l+2]=long_valid_w[l];
    assign result_tag_o[(l+2)*TAG_W+:TAG_W]=long_result_tag_w[l];
    assign result_o[(l+2)*`R64_RESULT_W+:`R64_RESULT_W]={{(`R64_RESULT_W-64){1'b0}},long_result_data_w[l]};
  end endgenerate
  // Actual closed backend guarantees at most one raw Serial owner across
  // RR ingress and terminals. Raw VALID is Q-only; current kill/flush gates
  // admission below, not the wide data projection. Default generic mode keeps
  // exact empty/cancelled payload values and arbitrary dual-Serial arbitration.
  wire [1:0] raw_serial_w={
    in_valid_i[1]&&class_w[1]==`R64_C_SERIAL,
    in_valid_i[0]&&class_w[0]==`R64_C_SERIAL};
  // Raw RR terminal owners exclude registered tombstones. In a closed
  // ROB window, a suffix kill cannot discard the older FP and keep the
  // younger FP. Choose data from Q owners; keep actual live/fire below.
  wire [1:0] raw_fp_w={
    in_valid_i[1]&&class_w[1]==`R64_C_FP,
    in_valid_i[0]&&class_w[0]==`R64_C_FP};
  wire raw_fp1_w=raw_fp_w[1]&&(!raw_fp_w[0]||older1_w);
  wire raw_fp0_w=raw_fp_w[0]&&!raw_fp1_w;
  // Each effective MEM is a prefix of raw MEM in a legal ROB suffix kill.
  // Project both payload lanes from terminal Q; admission still uses live_w.
  wire [1:0] raw_mem_w={
    in_valid_i[1]&&class_w[1]==`R64_C_MEM,
    in_valid_i[0]&&class_w[0]==`R64_C_MEM};
  wire raw_mem_first1_w=raw_mem_w[1]&&(!raw_mem_w[0]||older1_w);
  wire raw_mem_first0_w=raw_mem_w[0]&&!raw_mem_first1_w;
  wire raw_mem_second1_w=raw_mem_w==3&&!older1_w;
  wire raw_mem_second0_w=raw_mem_w==3&&older1_w;
  integer priority_lane,second_lane,j,unit,mem_count;
  reg [2:0] long_taken;
  reg fp_taken,serial_taken;
  always @(*)begin
    in_ready_o=alu_fire_w;lsu_fire_o=0;lsu_tag_o=0;lsu_uop_o=0;lsu_operand_o=0;lsu_slot_o=0;
    fp_fire_o=0;fp_tag_o=0;fp_uop_o=0;fp_operand_o=0;
    serial_fire_o=0;serial_tag_o=0;serial_uop_o=0;serial_operand_o=0;
    long_fire_w=0;long_word_w=0;long_taken=0;fp_taken=0;serial_taken=0;mem_count=0;unit=0;
    for(j=0;j<3;j=j+1)begin long_tag_w[j]=0;long_a_w[j]=0;long_b_w[j]=0;long_function_w[j]=0;end
    priority_lane=live_w[1]&&(!live_w[0]||older1_w) ? 1:0;
    second_lane=1-priority_lane;
    // At most two held RR packets participate; age orders shared resources.
    for(j=0;j<2;j=j+1)begin
      if(j==0)priority_lane=1-second_lane;else priority_lane=second_lane;
      if(live_w[priority_lane])begin
        case(class_w[priority_lane])
          `R64_C_MDU:begin
            unit=uop_w[priority_lane][199] ? 2:(uop_w[priority_lane][198] ? 1:0);
            if(!long_taken[unit])begin
              long_taken[unit]=1;
              long_tag_w[unit]=tag_w[priority_lane];long_a_w[unit]=operand_w[priority_lane][63:0];
              long_b_w[unit]=operand_w[priority_lane][127:64];
              long_function_w[unit]=uop_w[priority_lane][198:196];long_word_w[unit]=uop_w[priority_lane][`R64_U_WORD];
              long_fire_w[unit]=long_ready_w[unit];in_ready_o[priority_lane]=long_ready_w[unit];
            end
          end
          `R64_C_MEM:begin
            if(DIRECT_MEM_BIND!=0)begin
              // LSQ age/slot belongs to dispatch, not the order of operand
              // arrival. Each RR physical lane binds its existing owner.
              lsu_fire_o[priority_lane]=lsu_ready_i[priority_lane];
              in_ready_o[priority_lane]=lsu_ready_i[priority_lane];
            end else if(mem_count<2)begin
              lsu_tag_o[mem_count*TAG_W+:TAG_W]=tag_w[priority_lane];
              lsu_slot_o[mem_count*LSQ_W+:LSQ_W]=in_mem_slot_i[priority_lane*LSQ_W+:LSQ_W];
              lsu_uop_o[mem_count*`R64_UOP_W+:`R64_UOP_W]=uop_w[priority_lane];
              lsu_operand_o[mem_count*192+:192]=operand_w[priority_lane];
              lsu_fire_o[mem_count]=lsu_ready_i[mem_count]&&(mem_count==0||lsu_fire_o[0]);
              in_ready_o[priority_lane]=lsu_fire_o[mem_count];mem_count=mem_count+1;
            end
          end
          `R64_C_FP:if(!fp_taken)begin
            fp_taken=1;fp_fire_o=fp_ready_i;in_ready_o[priority_lane]=fp_ready_i;
            fp_tag_o=tag_w[priority_lane];fp_uop_o=uop_w[priority_lane];fp_operand_o=operand_w[priority_lane];
          end
          `R64_C_SERIAL:if(!serial_taken)begin
            serial_taken=1;serial_fire_o=serial_ready_i;in_ready_o[priority_lane]=serial_ready_i;
            if(RAW_SERIAL==0)begin
            serial_tag_o=tag_w[priority_lane];serial_uop_o=uop_w[priority_lane];serial_operand_o=operand_w[priority_lane];
            end
          end
          default:begin end
        endcase
      end
    end
    if(DIRECT_MEM_BIND!=0)begin
      // Payload has no age, live, or cancellation selector. The independent
      // fire still requires the original canonical live predicate above.
      lsu_tag_o=in_tag_i;lsu_slot_o=in_mem_slot_i;
      lsu_uop_o=in_uop_i;lsu_operand_o=in_operand_i;
    end else if(RAW_MEM!=0)begin
      lsu_tag_o[0*TAG_W+:TAG_W]=(tag_w[0]&{TAG_W{raw_mem_first0_w}})|(tag_w[1]&{TAG_W{raw_mem_first1_w}});
      lsu_slot_o[0*LSQ_W+:LSQ_W]=(in_mem_slot_i[0+:LSQ_W]&{LSQ_W{raw_mem_first0_w}})|(in_mem_slot_i[LSQ_W+:LSQ_W]&{LSQ_W{raw_mem_first1_w}});
      lsu_uop_o[0*`R64_UOP_W+:`R64_UOP_W]=(uop_w[0]&{`R64_UOP_W{raw_mem_first0_w}})|(uop_w[1]&{`R64_UOP_W{raw_mem_first1_w}});
      lsu_operand_o[0*192+:192]=(operand_w[0]&{192{raw_mem_first0_w}})|(operand_w[1]&{192{raw_mem_first1_w}});
      lsu_tag_o[1*TAG_W+:TAG_W]=(tag_w[0]&{TAG_W{raw_mem_second0_w}})|(tag_w[1]&{TAG_W{raw_mem_second1_w}});
      lsu_slot_o[1*LSQ_W+:LSQ_W]=(in_mem_slot_i[0+:LSQ_W]&{LSQ_W{raw_mem_second0_w}})|(in_mem_slot_i[LSQ_W+:LSQ_W]&{LSQ_W{raw_mem_second1_w}});
      lsu_uop_o[1*`R64_UOP_W+:`R64_UOP_W]=(uop_w[0]&{`R64_UOP_W{raw_mem_second0_w}})|(uop_w[1]&{`R64_UOP_W{raw_mem_second1_w}});
      lsu_operand_o[1*192+:192]=(operand_w[0]&{192{raw_mem_second0_w}})|(operand_w[1]&{192{raw_mem_second1_w}});
    end
    if(RAW_FP!=0)begin
      fp_tag_o=(tag_w[0]&{TAG_W{raw_fp0_w}})|(tag_w[1]&{TAG_W{raw_fp1_w}});
      fp_uop_o=(uop_w[0]&{`R64_UOP_W{raw_fp0_w}})|
               (uop_w[1]&{`R64_UOP_W{raw_fp1_w}});
      fp_operand_o=(operand_w[0]&{192{raw_fp0_w}})|
                   (operand_w[1]&{192{raw_fp1_w}});
    end
    if(RAW_SERIAL!=0)begin
      serial_tag_o=(tag_w[0]&{TAG_W{raw_serial_w[0]}})|(tag_w[1]&{TAG_W{raw_serial_w[1]}});
      serial_uop_o=(uop_w[0]&{`R64_UOP_W{raw_serial_w[0]}})|
                   (uop_w[1]&{`R64_UOP_W{raw_serial_w[1]}});
      serial_operand_o=(operand_w[0]&{192{raw_serial_w[0]}})|
                       (operand_w[1]&{192{raw_serial_w[1]}});
    end
  end
`ifdef R64_ASSERT
  // Independent original live selection checks every actually consumed field.
  wire [1:0] shadow_live_mem_w={
    live_w[1]&&class_w[1]==`R64_C_MEM,live_w[0]&&class_w[0]==`R64_C_MEM};
  wire shadow_mem_first1_w=shadow_live_mem_w[1]&&(!shadow_live_mem_w[0]||older1_w);
  wire shadow_mem_first0_w=shadow_live_mem_w[0]&&!shadow_mem_first1_w;
  wire shadow_mem_second1_w=shadow_live_mem_w==3&&!older1_w;
  wire shadow_mem_second0_w=shadow_live_mem_w==3&&older1_w;
  wire [1:0] shadow_mem_select0_w={shadow_mem_second0_w,shadow_mem_first0_w};
  wire [1:0] shadow_mem_select1_w={shadow_mem_second1_w,shadow_mem_first1_w};
  integer check_mem;
  always @(posedge clk)if(RAW_MEM!=0&&DIRECT_MEM_BIND==0&&!rst&&!flush_i)begin
    if(raw_mem_w==3&&
       ((raw_mem_first0_w&&kill_mask_i[tag_w[0][ROB_W-1:0]]&&!kill_mask_i[tag_w[1][ROB_W-1:0]])||
        (raw_mem_first1_w&&kill_mask_i[tag_w[1][ROB_W-1:0]]&&!kill_mask_i[tag_w[0][ROB_W-1:0]])))
      $fatal(1,"Execute raw MEM cancellation was not a ROB suffix");
    for(check_mem=0;check_mem<2;check_mem=check_mem+1)
      if(lsu_fire_o[check_mem]&&
        {lsu_tag_o[check_mem*TAG_W+:TAG_W],lsu_slot_o[check_mem*LSQ_W+:LSQ_W],
         lsu_uop_o[check_mem*`R64_UOP_W+:`R64_UOP_W],lsu_operand_o[check_mem*192+:192]}!==(
         ({tag_w[0],in_mem_slot_i[0+:LSQ_W],uop_w[0],operand_w[0]}&
          {(TAG_W+LSQ_W+`R64_UOP_W+192){shadow_mem_select0_w[check_mem]}})|
         ({tag_w[1],in_mem_slot_i[LSQ_W+:LSQ_W],uop_w[1],operand_w[1]}&
          {(TAG_W+LSQ_W+`R64_UOP_W+192){shadow_mem_select1_w[check_mem]}})))
        $fatal(1,"Execute raw MEM fire payload differs from original live owner");
  end

  generate if(DIRECT_MEM_BIND!=0)begin:gen_direct_mem_contract
    for(genvar dm=0;dm<2;dm=dm+1)begin:gen_lane
      always @(posedge clk)if(!rst)begin
        if(lsu_fire_o[dm]&&
           (!in_valid_i[dm]||class_w[dm]!=`R64_C_MEM||flush_i||
            kill_mask_i[tag_w[dm][ROB_W-1:0]]||!lsu_ready_i[dm]))
          $fatal(1,"Execute direct MEM bind lacks canonical live owner");
        if(lsu_fire_o[dm]&&
           {lsu_tag_o[dm*TAG_W+:TAG_W],lsu_slot_o[dm*LSQ_W+:LSQ_W],
            lsu_uop_o[dm*`R64_UOP_W+:`R64_UOP_W],lsu_operand_o[dm*192+:192]}!==
           {in_tag_i[dm*TAG_W+:TAG_W],in_mem_slot_i[dm*LSQ_W+:LSQ_W],
            in_uop_i[dm*`R64_UOP_W+:`R64_UOP_W],in_operand_i[dm*192+:192]})
          $fatal(1,"Execute direct MEM bind changed its physical-lane owner");
      end
    end
  end endgenerate

  // Original oldest-live FP predicate remains independent of raw projection.
  wire [1:0] shadow_live_fp_w={
    live_w[1]&&class_w[1]==`R64_C_FP,live_w[0]&&class_w[0]==`R64_C_FP};
  wire shadow_fp1_w=shadow_live_fp_w[1]&&(!shadow_live_fp_w[0]||older1_w);
  wire shadow_fp0_w=shadow_live_fp_w[0]&&!shadow_fp1_w;
  always @(posedge clk)if(RAW_FP!=0&&!rst&&!flush_i)begin
    if(raw_fp_w==3&&
       ((raw_fp0_w&&kill_mask_i[tag_w[0][ROB_W-1:0]]&&!kill_mask_i[tag_w[1][ROB_W-1:0]])||
        (raw_fp1_w&&kill_mask_i[tag_w[1][ROB_W-1:0]]&&!kill_mask_i[tag_w[0][ROB_W-1:0]])))
      $fatal(1,"Execute raw FP cancellation was not a ROB suffix");
    if(fp_fire_o&&
       {fp_tag_o,fp_uop_o,fp_operand_o}!==(
        ({tag_w[0],uop_w[0],operand_w[0]}&{(TAG_W+`R64_UOP_W+192){shadow_fp0_w}})|
        ({tag_w[1],uop_w[1],operand_w[1]}&{(TAG_W+`R64_UOP_W+192){shadow_fp1_w}})))
      $fatal(1,"Execute raw FP fire payload differs from original live owner");
  end

  always @(posedge clk)if(!rst)begin
    if(RAW_SERIAL!=0&&raw_serial_w==2'b11)
      $fatal(1,"Execute raw Serial owners are not unique");
    if(serial_fire_o&&(flush_i||!serial_ready_i||kill_mask_i[serial_tag_o[ROB_W-1:0]]))
      $fatal(1,"Execute serial admission violated live-owner contract");
  end
  integer admission_unit;
  always @(posedge clk)begin
    for(admission_unit=0;admission_unit<3;admission_unit=admission_unit+1)
      if(long_fire_w[admission_unit]&&
          (rst||flush_i||cancel_selected(long_tag_w[admission_unit][ROB_W-1:0],cancel_candidates_i,kill_mask_i,cancel_active_i)))
        $fatal(1,"Execute long admission violated prequalified-live contract");
  end
  always @(posedge clk)if(!rst&&!flush_i)begin
    if(DIRECT_MEM_BIND==0&&lsu_fire_o[1]&&!lsu_fire_o[0])$fatal(1,"R64 LSU bind output lost dense lane packing");
    if(branch_resolve_w==3)$fatal(1,"R64 delayed branch resolution collision");
    if((alu_fire_w&branch_w)==3)$fatal(1,"R64 branch resolution collision");
  end
`endif
`ifdef R64_ASSERT
  generate if(PREPARED_CANCEL)begin:gen_cancel_contract
    always @(posedge clk)if(!rst)
      if(kill_mask_i!==({(1<<ROB_W){cancel_active_i}}&cancel_candidates_i))
        $fatal(1,"prepared cancellation does not match canonical kill mask");
  end endgenerate
`endif
endmodule


// Two-phase ALU/branch computation advances every cycle. Admission reserves one
// of four terminal positions until the real completion is consumed (or a killed
// tombstone reaches the head). No downstream READY traverses arithmetic stages.
module R64AluLane #(parameter TAG_W=9,ROB_W=5,PREG_W=6,EARLY_ACCEPT=0)(
 input clk,input rst,input flush_i,input [(1<<ROB_W)-1:0] kill_mask_i,
 input in_fire_i,input early_candidate_i,output in_ready_o,input [TAG_W-1:0] in_tag_i,
 input [`R64_UOP_W-1:0] in_uop_i,input in_branch_i,input [36:0] in_control_i,input [4:0] in_add_source_i,input [5:0] in_shift_amount_i,
 input [20:0] in_branch_imm_i,input [4:0] in_branch_control_i,
 input [191:0] in_operand_i,input [PREG_W-1:0] in_preg_i,
 output early_valid_o,output [PREG_W-1:0] early_preg_o,output [TAG_W-1:0] early_tag_o,
 output bypass_valid_o,output [PREG_W-1:0] bypass_preg_o,output [63:0] bypass_data_o,
 output out_valid_o,input out_ready_i,output [TAG_W-1:0] out_tag_o,
 output [`R64_RESULT_W-1:0] out_result_o,
 output recovery_preview_valid_o,output [TAG_W-1:0] recovery_preview_tag_o,
 output resolve_valid_o,output redirect_o,output redirect_pending_o,output [TAG_W-1:0] resolve_tag_o,
 output [63:0] resolve_npc_o,resolve_pc_o,output conditional_o,indirect_o,taken_o
);
 wire [63:0] pc_w=in_uop_i[`R64_U_PC];
 wire indirect_w=in_branch_control_i[1],conditional_w=in_branch_control_i[0];
 // Source categories were resolved at the register-read snapshot boundary.
 // There is no opcode/branch decision tree in front of the adder.
 wire [63:0] normal_b_w=(in_uop_i[`R64_U_ARG]&{64{in_add_source_i[3]}})|
     (in_operand_i[127:64]&{64{in_add_source_i[2]}});
 wire [63:0] a_w=(pc_w&{64{in_add_source_i[1]}})|
     (in_operand_i[63:0]&{64{in_add_source_i[0]}});
 wire [63:0] b_w=normal_b_w|
     ({{43{in_branch_imm_i[20]}},in_branch_imm_i}&{64{in_add_source_i[4]}});
 wire [36:0] control_w=in_control_i;
 wire [63:0] result_w,add_result_w;wire result_word_w;
 // PC/branch source selection belongs only to the address/add path.
 // Decode only selects PC for AUIPC; bit operations use the original register
 // source, so an unrelated PC mux does not precede their shift/count tree.
 wire [63:0] data_a_w=in_operand_i[63:0];
 R64AluDatapath alu(.clk(clk),.a_i(data_a_w),.b_i(normal_b_w),
   .add_a_i(a_w),.add_b_i(b_w),.shift_amount_i(in_shift_amount_i),.control_i(control_w),
   .word_i(in_uop_i[`R64_U_WORD]),.result_o(result_w),.word_o(result_word_w),.add_result_o(add_result_w));
 wire [63:0] seq_base_w,seq_w;wire [15:0] seq_p_w,seq_g_w;
 reg [63:0] seq_base_q;reg [15:0] seq_p_q,seq_g_q;
 R64CarryPrepare #(.WIDTH(64),.BLOCK(4)) sequential_prepare(
   .a_i(pc_w),.b_i({60'b0,in_uop_i[`R64_U_LEN]}),.base_o(seq_base_w),
   .propagate_o(seq_p_w),.generate_o(seq_g_w));
 R64CarryFinish #(.WIDTH(64),.BLOCK(4)) sequential_finish(
   .base_i(seq_base_q),.propagate_i(seq_p_q),.generate_i(seq_g_q),
   .carry_i(1'b0),.sum_o(seq_w),.carry_o());

 reg token_q,branch_q,exception_q,conditional_q,indirect_q;
 reg [TAG_W-1:0] token_tag_q;reg [PREG_W-1:0] token_preg_q;
 reg [63:0] token_pc_q,prediction_q,tval_q;
 reg [5:0] cause_q;reg [2:0] condition_q;
 reg [7:0] compare_eq_q,compare_lt_q;
 reg a_sign_q,b_sign_q;
 wire [7:0] less_hit_w;
 genvar byte_index;
 generate for(byte_index=0;byte_index<8;byte_index=byte_index+1)begin:compare
   if(byte_index==7)assign less_hit_w[byte_index]=compare_lt_q[byte_index];
   else assign less_hit_w[byte_index]=compare_lt_q[byte_index]&&(&compare_eq_q[7:byte_index+1]);
 end endgenerate
 wire equal_w=&compare_eq_q,unsigned_less_w=|less_hit_w;
 wire signed_less_w=a_sign_q!=b_sign_q ? a_sign_q:unsigned_less_w;
 reg condition_taken_w;
 always @(*)begin
   case(condition_q)
    0:condition_taken_w=equal_w;1:condition_taken_w=!equal_w;
    4:condition_taken_w=signed_less_w;5:condition_taken_w=!signed_less_w;
    6:condition_taken_w=unsigned_less_w;7:condition_taken_w=!unsigned_less_w;
    default:condition_taken_w=0;
   endcase
 end
 wire taken_w=!conditional_q||condition_taken_w;
 wire [63:0] npc_w=conditional_q&&!taken_w ? seq_w:
     indirect_q ? {add_result_w[63:1],1'b0}:add_result_w;
 assign recovery_preview_valid_o=token_q&&branch_q&&!exception_q;
 assign recovery_preview_tag_o=token_tag_q;
 wire token_killed_w=kill_mask_i[token_tag_q[ROB_W-1:0]];
 wire token_live_w=token_q&&!rst&&!flush_i&&!token_killed_w;

 reg [TAG_W-1:0] tag_q[0:3];reg [PREG_W-1:0] preg_q[0:3];
 reg [`R64_RESULT_W-1:0] result_q[0:3];reg [3:0] dead_q,word_q,woke_q;
 reg [1:0] head_q,tail_q;reg [2:0] count_q,reserved_q;
 wire pop_w=count_q!=0&&(dead_q[head_q]||out_ready_i);
 assign in_ready_o=reserved_q<3'd4;
 assign out_valid_o=count_q!=0&&!dead_q[head_q];
 assign out_tag_o=tag_q[head_q];
 wire [`R64_RESULT_W-1:0] head_result_w=result_q[head_q];
 // Complete word packing independently in each resident owner before selecting
 // the head. The head-select tree no longer drives a second sign fanout mux.
 wire [63:0] packed_data_w[0:3];
 genvar pack_slot;
 generate for(pack_slot=0;pack_slot<4;pack_slot=pack_slot+1)begin:gen_terminal_pack
   assign packed_data_w[pack_slot]=word_q[pack_slot] ?
       {{32{result_q[pack_slot][31]}},result_q[pack_slot][31:0]}:result_q[pack_slot][63:0];
 end endgenerate
 wire [63:0] head_data_w=packed_data_w[head_q];
 assign out_result_o={head_result_w[`R64_RESULT_W-1:64],head_data_w};
 // Raw short-owner publications are authorized by ROB at the Backend
 // consumer boundary. Current kill/reset/flush cannot propagate through
 // arithmetic or terminal selection; local cancellation is recorded below.
 assign bypass_valid_o=out_valid_o&&preg_q[head_q]!=0&&!head_result_w[`R64_R_EXCEPTION];
 assign bypass_preg_o=preg_q[head_q];assign bypass_data_o=head_data_w;
 // The finished operation may wake at its terminal-capture edge only if it
 // will become the bypass head. A queued result wakes when it really reaches
 // that head; no input acceptance predicts a fixed future data availability.
 wire becoming_head_w=count_q==0||(count_q==1&&pop_w);
 wire early_token_w=token_q&&becoming_head_w&&!exception_q&&token_preg_q!=0;
 wire early_head_w=bypass_valid_o&&!woke_q[head_q];
 // With no older numerical/result reservation, this accepted short ALU owns
 // the next bypass head. Its result precedes an awakened consumer's RR read,
 // even if WB never grants the lane. Branch/fault/queued owners do not predict.
 // Query only the raw resident candidate. Final ROB short-owner acceptance
 // applies current cancellation; taking the qualified fire through this tag
 // mux would send flush/kill through admission and then through ROB again.
 wire early_accept_w=EARLY_ACCEPT!=0&&early_candidate_i&&reserved_q==0&&
     !in_branch_i&&!in_uop_i[`R64_U_EXCEPTION]&&in_preg_i!=0;
 // Keep the finish pulse: a DEFER_READY entry born on the accept pulse
 // initializes on the following edge and must still observe its producer.
 assign early_valid_o=early_accept_w||early_token_w||early_head_w;
 assign early_preg_o=early_accept_w ? in_preg_i:early_token_w ? token_preg_q:bypass_preg_o;
 assign early_tag_o=early_accept_w ? in_tag_i:early_token_w ? token_tag_q:out_tag_o;
 reg resolve_q,redirect_q;
 reg [TAG_W-1:0] resolve_tag_q;reg [63:0] resolve_npc_q,resolve_pc_q;
 reg resolve_conditional_q,resolve_indirect_q,resolve_taken_q;
 assign resolve_valid_o=resolve_q&&!rst&&!flush_i;
 // Raw registered resolution summary for a consumer that owns its own
 // reset/flush priority. This is not the externally visible redirect event.
 assign redirect_pending_o=resolve_q&&redirect_q;
 assign redirect_o=redirect_q;assign resolve_tag_o=resolve_tag_q;
 assign resolve_npc_o=resolve_npc_q;assign resolve_pc_o=resolve_pc_q;
 assign conditional_o=resolve_conditional_q;assign indirect_o=resolve_indirect_q;assign taken_o=resolve_taken_q;
 integer k;
 always @(posedge clk)begin
   // Unowned arithmetic bits may toggle; only token_q carries an instruction.
   seq_base_q<=seq_base_w;seq_p_q<=seq_p_w;seq_g_q<=seq_g_w;
   for(k=0;k<8;k=k+1)begin
     compare_eq_q[k]<=in_operand_i[k*8+:8]==in_operand_i[64+k*8+:8];
     compare_lt_q[k]<=in_operand_i[k*8+:8]<in_operand_i[64+k*8+:8];
   end
   a_sign_q<=in_operand_i[63];b_sign_q<=in_operand_i[127];
   token_tag_q<=in_tag_i;token_preg_q<=in_preg_i;token_pc_q<=pc_w;
   branch_q<=in_branch_i;exception_q<=in_uop_i[`R64_U_EXCEPTION];
   prediction_q<=in_uop_i[`R64_U_ARG];tval_q<=in_uop_i[`R64_U_ARG];
   cause_q<=in_uop_i[`R64_U_CAUSE];condition_q<=in_branch_control_i[4:2];
   conditional_q<=conditional_w;indirect_q<=indirect_w;
   if(rst||flush_i)begin
     token_q<=0;head_q<=0;tail_q<=0;count_q<=0;reserved_q<=0;dead_q<=0;word_q<=0;woke_q<=0;
     resolve_q<=0;redirect_q<=0;
   end else begin
     token_q<=in_fire_i;
     reserved_q<=reserved_q+{2'b0,in_fire_i}-{2'b0,pop_w};
     count_q<=count_q+{2'b0,token_q}-{2'b0,pop_w};
     if(pop_w)head_q<=head_q+2'd1;
     if(early_head_w)woke_q[head_q]<=1;
     for(k=0;k<4;k=k+1)
       if(kill_mask_i[tag_q[k][ROB_W-1:0]])dead_q[k]<=1;
     if(token_q)begin
       tail_q<=tail_q+2'd1;tag_q[tail_q]<=token_tag_q;preg_q[tail_q]<=token_preg_q;
       dead_q[tail_q]<=token_killed_w;word_q[tail_q]<=result_word_w&&!branch_q;
       woke_q[tail_q]<=early_token_w;
       result_q[tail_q]<=0;
       result_q[tail_q][`R64_R_DATA]<=branch_q ? seq_w:result_w;
       result_q[tail_q][`R64_R_EXCEPTION]<=exception_q;
       result_q[tail_q][`R64_R_CAUSE]<=cause_q;
       result_q[tail_q][`R64_R_TVAL]<=tval_q;
     end
     resolve_q<=token_live_w&&branch_q&&!exception_q;
     if(token_live_w&&branch_q&&!exception_q)begin
       resolve_tag_q<=token_tag_q;resolve_npc_q<=npc_w;resolve_pc_q<=token_pc_q;
       resolve_conditional_q<=conditional_q;resolve_indirect_q<=indirect_q;resolve_taken_q<=taken_w;
       redirect_q<=npc_w!=prediction_q;
     end
   end
 end
`ifdef R64_ASSERT
 // The raw query may advertise a cancelled candidate, as existing head
 // wake does. Once live-qualified, it must equal the original accept event.
 wire canonical_accept_w=EARLY_ACCEPT!=0&&in_fire_i&&reserved_q==0&&
     !in_branch_i&&!in_uop_i[`R64_U_EXCEPTION]&&in_preg_i!=0;
 always @(posedge clk)if(EARLY_ACCEPT!=0&&!rst&&!flush_i)begin
   if((early_accept_w&&!kill_mask_i[in_tag_i[ROB_W-1:0]])!==canonical_accept_w)
     $fatal(1,"ALU raw accept query changed its live wake event");
 end
 reg accept_promise_q;reg [TAG_W-1:0] accept_promise_tag_q;
 always @(posedge clk)begin
   if(rst||flush_i)accept_promise_q<=0;
   else begin
     accept_promise_q<=early_accept_w&&in_fire_i;accept_promise_tag_q<=in_tag_i;
     if(accept_promise_q&&!kill_mask_i[accept_promise_tag_q[ROB_W-1:0]]&&
         (!token_q||token_tag_q!=accept_promise_tag_q||!becoming_head_w))
       $fatal(1,"ALU accepted wake lost its guaranteed next result head");
   end
 end
 always @(posedge clk)if(!rst&&!flush_i)begin
   if(in_fire_i&&!in_branch_i&&!in_uop_i[`R64_U_EXCEPTION]&&(|in_control_i[8:4])&&
       in_shift_amount_i!=normal_b_w[5:0])
     $fatal(1,"R64 prepared shift amount disagrees with captured source value");
   if(in_fire_i&&!in_branch_i&&in_uop_i[`R64_U_OP1_ZERO]&&!in_control_i[1]&&!in_control_i[18])
     $fatal(1,"R64 zero source selected outside ADD/COPY_B");
   if(in_fire_i&&!in_branch_i&&in_uop_i[`R64_U_OP1_PC]&&!in_control_i[1])
     $fatal(1,"R64 PC source selected outside the ADD datapath");
   if(in_fire_i&&(!in_ready_o||kill_mask_i[in_tag_i[ROB_W-1:0]]))
     $fatal(1,"R64 ALU admitted without a live terminal reservation");
   if(reserved_q!=count_q+{2'b0,token_q}||reserved_q>4||count_q>reserved_q)
     $fatal(1,"R64 ALU lost its in-flight/terminal conservation");
 end
`endif
endmodule
