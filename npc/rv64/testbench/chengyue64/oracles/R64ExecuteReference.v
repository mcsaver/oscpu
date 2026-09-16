`include "R64Uop.vh"
// Native execution boundary. ALUs each have a result holder; multiply,
// divide and carryless multiply own their internal state and independent WB
// holders. External owners receive admission pulses and retain transactions.
module R64ExecuteReference #(parameter PREPARED_CANCEL=0,parameter TAG_W=9,parameter ROB_W=5,parameter PREG_W=6,parameter LSQ_W=5,parameter RAW_SERIAL=0,parameter RAW_FP=0,parameter RAW_MEM=0)(
  input clk,input rst,input flush_i,input [(1<<ROB_W)-1:0] kill_mask_i,
  input [(1<<ROB_W)-1:0] cancel_candidates_i,input cancel_active_i,
  input [ROB_W-1:0] rob_head_i,
  input [1:0] in_valid_i,output reg [1:0] in_ready_o,
  input [2*TAG_W-1:0] in_tag_i,input [2*LSQ_W-1:0] in_mem_slot_i,input [2*`R64_UOP_W-1:0] in_uop_i,
  input [5:0] in_class_i,input [383:0] in_operand_i,
  input [2*PREG_W-1:0] in_gpr_dst_i,input [73:0] in_alu_control_i,input [9:0] in_add_source_i,input [11:0] in_shift_amount_i,
  input [41:0] in_branch_imm_i,input [9:0] in_branch_control_i,
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
    R64AluLane #(.TAG_W(TAG_W),.ROB_W(ROB_W),.PREG_W(PREG_W)) lane(
      .clk(clk),.rst(rst),.flush_i(flush_i),.kill_mask_i(kill_mask_i),
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
            if(mem_count<2)begin
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
    if(RAW_MEM!=0)begin
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
  always @(posedge clk)if(RAW_MEM!=0&&!rst&&!flush_i)begin
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
    if(lsu_fire_o[1]&&!lsu_fire_o[0])$fatal(1,"R64 LSU bind output lost dense lane packing");
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
