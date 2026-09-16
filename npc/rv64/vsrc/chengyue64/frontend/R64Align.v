module R64Align #(
  parameter integer EARLY_PREDICT=0,
  parameter [63:0] RESET_PC = 64'h80000000
) (
  input clk_i,
  input rst_i,
  // Redirect discards buffered bytes at the edge. The caller decides whether
  // the current output bundle was accepted (prediction) or squashed (recovery).
  input redirect_i,
  input [63:0] redirect_pc_i,
  input packet_valid_i,
  output packet_ready_o,
  input [63:0] packet_pc_i,
  input [127:0] packet_data_i,
  input packet_fault_i,
  input [4:0] packet_cause_i,
  input [7:0] packet_access_mask_i,
  input packet_plan_valid_i,input [2:0] packet_plan_offset_i,
  input packet_plan_word_i,input [62:0] packet_plan_target_i,
  input jump_i,input [63:0] jump_pc_i,
  output [1:0] plan_at_o,output [1:0] plan_bad_o,
  output [63:0] plan_target_o,output [63:0] plan_source_o,
  output [1:0] valid_o,
  input [1:0] consume_i,
  output [63:0] pc0_o,
  output [63:0] pc1_o,
  output [63:0] inst0_o,
  output [63:0] inst1_o,
  output [3:0] length0_o,
  output [3:0] length1_o,
  output fault0_o,
  output fault1_o,
  output [4:0] cause0_o,
  output [4:0] cause1_o,
  output [63:0] tval0_o,
  output [63:0] tval1_o
);
  // P0 has two real packet owners. Q-only credit does not borrow a parse
  // completion, and parse capacity does not borrow a consumer release.
  reg [272:0] work_q[0:1];
  // Classified bytes and raw bytes share the same accepted packet owner.
  reg [16:0] work_header_q[0:1];
  wire [16:0] packet_header_w,source_header_w;
  R64PacketHeader capture_header(.data_i(packet_data_i),.header_o(packet_header_w));
  assign source_header_w=work_header_q[work_head_q];
  reg work_head_q,work_tail_q;
  reg [1:0] work_count_q;
  wire [63:0] source_pc_w;
  wire [127:0] source_data_w;
  wire [7:0] source_mask_w;
  wire [4:0] source_cause_w;
  wire [67:0] source_plan_w;
  assign {source_pc_w,source_data_w,source_mask_w,source_cause_w,source_plan_w}=work_q[work_head_q];
  wire source_planned_w=EARLY_PREDICT!=0&&source_plan_w[67];
  reg [63:0] fill_pc_q,pc_q;
  wire [3:0] offset_q=pc_q[3:0];
  wire [59:0] next_block_w=pc_q[63:4]+60'd1;
  assign packet_ready_o=!rst_i&&!redirect_i&&work_count_q<2;
  wire push_w=packet_valid_i&&packet_ready_o;

  // P1 results occupy fixed physical slots. Only producers write payload.
  reg [255:0] data_q[0:2];
  reg [287:0] map_q[0:2];
  reg [16:0] header_q[0:2];
  reg [7:0] mask_q[0:2];
  reg [4:0] cause_q[0:2],next_cause_q[0:2];
  reg [67:0] own_plan_q[0:2];
  reg [62:0] selected_target_q[0:2];
  reg [2:0] selected_next_q;
  reg [1:0] head_q,tail_q,count_q;
  wire [1:0] next_head_w=head_q==2?2'd0:head_q+2'd1;
  wire [1:0] after_next_head_w=head_q==0?2'd2:head_q-2'd1;
  wire [1:0] next_tail_w=tail_q==2?2'd0:tail_q+2'd1;
  wire [1:0] previous_tail_w=tail_q==0?2'd2:tail_q-2'd1;
  wire parse_w=work_count_q!=0&&count_q<3&&!rst_i&&!redirect_i;
  wire patch_w=parse_w&&count_q!=0&&!own_plan_q[previous_tail_w][67];
  wire [287:0] initial_map_w,completed_map_w;
  R64PacketParse initial_parse(
   .source_header_i(source_header_w),.next_header_i(17'hff),.source_mask_i(source_mask_w),.next_mask_i(8'b0),
   .successor_i(1'b0),.source_plan_i(source_planned_w),.next_plan_i(1'b0),
   .source_offset_i(source_plan_w[66:64]),.next_offset_i(3'b0),
   .source_word_i(source_plan_w[63]),.next_word_i(1'b0),.map_o(initial_map_w));
  R64PacketParse completion_parse(
   .source_header_i(header_q[previous_tail_w]),.next_header_i(source_header_w),
   .source_mask_i(mask_q[previous_tail_w]),.next_mask_i(source_mask_w),
   .successor_i(1'b1),.source_plan_i(1'b0),.next_plan_i(source_planned_w),
   .source_offset_i(3'b0),.next_offset_i(source_plan_w[66:64]),
   .source_word_i(1'b0),.next_word_i(source_plan_w[63]),.map_o(completed_map_w));

  // The consume loop selects a precomputed row. No length or plan parser lies
  // between cursor Q and cursor/head D.
  wire [35:0] row_w=map_q[head_q][offset_q[3:1]*36+:36];
  wire [3:0] len0_w,len1_w;
  wire [4:0] fault0_pos_w,fault1_pos_w,single_offset_w,pair_offset_w;
  wire [1:0] row_valid_w,row_fault_w,row_bad_w,row_at_w;
  assign {len0_w,len1_w,fault0_pos_w,fault1_pos_w,row_valid_w,row_fault_w,
    row_bad_w,row_at_w,single_offset_w,pair_offset_w}=row_w;
  wire present_w=count_q!=0&&!rst_i;
  assign valid_o={2{present_w}}&row_valid_w;
  assign plan_bad_o={2{present_w}}&row_bad_w;
  assign plan_at_o={2{present_w}}&row_at_w;
  assign plan_target_o={selected_target_q[head_q],1'b0};
  assign plan_source_o={selected_next_q[head_q]?next_block_w:pc_q[63:4],4'b0};
  wire [127:0] aligned_w=data_q[head_q][offset_q*8+:128];
  wire [63:0] lane1_w=len0_w==2?aligned_w[79:16]:
    len0_w==4?aligned_w[95:32]:aligned_w[127:64];
  function [63:0] instruction_bits;
   input [63:0] bits;input [3:0] length;
   begin case(length)
    4'd2:instruction_bits={48'b0,bits[15:0]};
    4'd4:instruction_bits={32'b0,bits[31:0]};
    default:instruction_bits=bits;
   endcase end
  endfunction
  assign pc0_o=pc_q;
  assign pc1_o={single_offset_w[4]?next_block_w:pc_q[63:4],single_offset_w[3:0]};
  assign length0_o=len0_w;assign length1_o=len1_w;
  assign inst0_o=row_fault_w[0]?64'b0:instruction_bits(aligned_w[63:0],len0_w);
  assign inst1_o=row_fault_w[1]?64'b0:instruction_bits(lane1_w,len1_w);
  assign fault0_o=valid_o[0]&&row_fault_w[0];
  assign fault1_o=valid_o[1]&&row_fault_w[1];
  assign cause0_o=!row_fault_w[0]?5'd1:(fault0_pos_w[4]?next_cause_q[head_q]:cause_q[head_q]);
  assign cause1_o=!row_fault_w[1]?5'd1:(fault1_pos_w[4]?next_cause_q[head_q]:cause_q[head_q]);
  assign tval0_o={fault0_pos_w[4]?next_block_w:pc_q[63:4],fault0_pos_w[3:0]};
  assign tval1_o={fault1_pos_w[4]?next_block_w:pc_q[63:4],fault1_pos_w[3:0]};
  wire [4:0] new_offset_w=consume_i==2?pair_offset_w:
    consume_i==1?single_offset_w:{1'b0,offset_q};
  wire jump_w=EARLY_PREDICT!=0&&jump_i;
  wire [1:0] pop_count_w=jump_w?(selected_next_q[head_q]?2'd2:2'd1):
    (consume_i!=0&&new_offset_w[4]?2'd1:2'd0);

  always @(posedge clk_i)begin
   if(rst_i||redirect_i)begin
    work_head_q<=0;work_tail_q<=0;work_count_q<=0;
    head_q<=0;tail_q<=0;count_q<=0;selected_next_q<=0;
    pc_q<=rst_i?RESET_PC:redirect_pc_i;
    fill_pc_q<=EARLY_PREDICT!=0?(rst_i?RESET_PC:redirect_pc_i):
      (rst_i?{RESET_PC[63:4],4'b0}:{redirect_pc_i[63:4],4'b0});
   end else begin
    if(push_w)begin
     work_header_q[work_tail_q]<=packet_header_w;
     work_q[work_tail_q]<={packet_pc_i,packet_data_i,
       packet_fault_i?8'hff:packet_access_mask_i,
       packet_fault_i?packet_cause_i:5'd1,
       EARLY_PREDICT!=0&&packet_plan_valid_i,packet_plan_offset_i,
       packet_plan_word_i,packet_plan_target_i};
     work_tail_q<=!work_tail_q;
     fill_pc_q<=EARLY_PREDICT!=0&&packet_plan_valid_i?{packet_plan_target_i,1'b0}:
       {packet_pc_i[63:4]+60'd1,4'b0};
    end
    if(parse_w)begin
     work_head_q<=!work_head_q;
     data_q[tail_q]<={128'b0,source_data_w};
     header_q[tail_q]<=source_header_w;
     map_q[tail_q]<=initial_map_w;mask_q[tail_q]<=source_mask_w;
     cause_q[tail_q]<=source_cause_w;next_cause_q[tail_q]<=5'd1;
     own_plan_q[tail_q]<={source_planned_w,source_plan_w[66:0]};
     selected_target_q[tail_q]<=source_plan_w[62:0];selected_next_q[tail_q]<=0;
     tail_q<=next_tail_w;
    end
    if(patch_w)begin
     data_q[previous_tail_w][255:128]<=source_data_w;
     map_q[previous_tail_w]<=completed_map_w;
     next_cause_q[previous_tail_w]<=source_cause_w;
     selected_target_q[previous_tail_w]<=source_plan_w[62:0];
     selected_next_q[previous_tail_w]<=source_planned_w;
    end
    work_count_q<=work_count_q+{1'b0,push_w}-{1'b0,parse_w};
    if(consume_i!=0)pc_q<=jump_w?jump_pc_i:
      {new_offset_w[4]?next_block_w:pc_q[63:4],new_offset_w[3:0]};
    if(pop_count_w[1])head_q<=after_next_head_w;
    else if(pop_count_w[0])head_q<=next_head_w;
    count_q<=count_q+{1'b0,parse_w}-pop_count_w;
   end
  end
`ifdef R64_ASSERT
  wire [2:0] next_count_check_w={1'b0,count_q}+{2'b0,parse_w}-{1'b0,pop_count_w};
  always @(posedge clk_i)if(!rst_i&&!redirect_i)begin
   if((consume_i==1&&!valid_o[0])||(consume_i==2&&!valid_o[1])||consume_i==3)
    $fatal(1,"packet map consume exceeds valid prefix");
   if(push_w&&EARLY_PREDICT!=0&&packet_plan_valid_i&&packet_plan_word_i&&packet_plan_offset_i==7)
    $fatal(1,"packet map source plan is not complete within its packet");
   if(push_w&&packet_pc_i!=fill_pc_q)$fatal(1,"packet map input discontinuity");
   if(jump_w&&(consume_i==0||pop_count_w>count_q))$fatal(1,"packet map cut without owners");
   if(next_count_check_w>3||work_count_q>2||head_q>2||tail_q>2||pc_q[0])
    $fatal(1,"packet map owner invariant");
   if(patch_w&&previous_tail_w==tail_q)$fatal(1,"packet map producer collision");
  end
`endif
  wire unused_source_pc_w=|source_pc_w;
endmodule
