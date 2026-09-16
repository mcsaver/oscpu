// Three fixed packet banks decouple Q-only packet credit from instruction consumption.
// PC is stored once for the byte stream, not duplicated for every halfword.
// Only head and its next bank supply instruction bytes; the third is lookahead credit.
// Payload banks never shift on consumption; only offset/head advance.
module R64AlignBaseline #(
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
  reg [127:0] data_q [0:2];
  // Instruction-length metadata is born with each real packet bank. A custom
  // eight-byte instruction needs its low halfword header and the following
  // halfword's upper-field test. Keeping those tests separate also handles the
  // last halfword of a sector using the next actual bank, without speculation.
  reg [7:0] short_q[0:2],tensor_prefix_q[0:2],tensor_upper_q[0:2];
  wire [15:0] short_flags_w={short_q[next_head_w],short_q[head_q]};
  wire [15:0] tensor_flags_w={tensor_prefix_q[next_head_w],tensor_prefix_q[head_q]};
  wire [15:0] upper_flags_w={tensor_upper_q[next_head_w],tensor_upper_q[head_q]};
  wire [15:0] long_flags_w=tensor_flags_w&(upper_flags_w>>1);
  function [3:0] decoded_length;
    input short_flag,long_flag;
    begin
      if(short_flag)decoded_length=4'd2;
      else if(long_flag)decoded_length=4'd8;
      else decoded_length=4'd4;
    end
  endfunction
  genvar halfword;
  generate for(halfword=0;halfword<8;halfword=halfword+1)begin:gen_length_metadata
    wire [15:0] bits_w=packet_data_i[halfword*16+:16];
    always @(posedge clk_i)if(push_w)begin
      short_q[tail_q][halfword]<=bits_w[1:0]!=2'b11;
      tensor_prefix_q[tail_q][halfword]<=bits_w[6:0]==7'b1011011&&bits_w[14:12]==3'b011;
      tensor_upper_q[tail_q][halfword]<=bits_w[15:11]==0&&bits_w[9];
    end
  end endgenerate
  reg [7:0] fault_mask_q[0:2];
  reg [4:0] cause_q [0:2];
  reg [2:0] plan_valid_q,plan_word_q;
  reg [2:0] plan_offset_q[0:2];
  reg [62:0] plan_target_q[0:2];
  reg [1:0] head_q,tail_q;
  wire [1:0] next_head_w=head_q==2?2'd0:head_q+2'd1;
  wire [1:0] after_next_head_w=head_q==0?2'd2:head_q-2'd1;
  wire [1:0] next_tail_w=tail_q==2?2'd0:tail_q+2'd1;
  reg [1:0] count_q;
  reg [63:0] pc_q,fill_pc_q;
  wire [3:0] offset_q=pc_q[3:0];
  // Q prepares next block address independently of late length/plan/consume.
  // Full byte PC is retained; this arithmetic identity holds even for odd inputs.
  wire [59:0] next_block_w=pc_q[63:4]+60'd1;

  wire [247:0] blocks_w = {data_q[next_head_w][119:0],data_q[head_q]};
  wire [127:0] aligned_w = blocks_w[{1'b0,offset_q,3'b0} +: 128];
  wire head_plan_w=EARLY_PREDICT!=0&&count_q!=0&&plan_valid_q[head_q];
  // A target sector is not a continuation sector, even if both banks are
  // occupied. Never assemble an instruction from unrelated target bytes.
  wire [5:0] available_w = (head_plan_w?6'd16:{count_q,4'b0}) - {2'b0,offset_q};
  wire [4:0] boundary_w = 5'd16 - {1'b0,offset_q};

  // The existing accelerator encoding is a low custom-2 word followed by
  // its high word; it is one eight-byte instruction in the native pipeline.
  // Invalid high words are rejected by decode, never issued independently.
  function [3:0] instruction_length;
    input [6:0] opcode;
    input [2:0] funct3;
    input [4:0] funct5;
    input pair_bit;
    begin
      if (opcode[1:0] != 2'b11) instruction_length = 4'd2;
      else if (opcode == 7'b1011011 && funct3 == 3'b011 &&
               funct5 == 5'b0 && pair_bit)
        instruction_length = 4'd8;
      else instruction_length = 4'd4;
    end
  endfunction

  function [63:0] instruction_bits;
    input [63:0] bits;
    input [3:0] length;
    begin
      case (length)
        4'd2: instruction_bits = {48'b0,bits[15:0]};
        4'd4: instruction_bits = {32'b0,bits[31:0]};
        default: instruction_bits = bits;
      endcase
    end
  endfunction

  wire [15:0] masks_w={fault_mask_q[next_head_w],fault_mask_q[head_q]};
  wire [7:0] aligned_masks_w=masks_w[{1'b0,offset_q[3:1]}+:8];
  wire prefix_fault0_w = aligned_masks_w[0];
  wire [3:0] len0_w = prefix_fault0_w ? 4'd2 : decoded_length(short_flags_w[{1'b0,offset_q[3:1]}],long_flags_w[{1'b0,offset_q[3:1]}]);
  wire [63:0] lane1_w = len0_w == 2 ? aligned_w[79:16] :
      (len0_w == 4 ? aligned_w[95:32] : aligned_w[127:64]);
  wire next_plan_w=EARLY_PREDICT!=0&&count_q>=2&&!head_plan_w&&plan_valid_q[next_head_w];
  wire any_plan_w=head_plan_w||next_plan_w;
  wire [1:0] plan_bank_w=head_plan_w?head_q:next_head_w;
  wire [4:0] plan_position_w={next_plan_w,plan_offset_q[plan_bank_w],1'b0};
  wire [3:0] plan_length_w=plan_word_q[plan_bank_w]?4'd4:4'd2;
  // Complete three fixed first-length views in parallel. Late len0 selects
  // metadata after lane1 length, fault/boundary and plan classification.
  wire [49:0] pair_view_w[0:2];
  genvar pair_case;
  generate for(pair_case=0;pair_case<3;pair_case=pair_case+1)begin:g_pair_view
    R64AlignPairViewBaseline #(.FIRST_BYTES(2<<pair_case)) u_view(
      .offset_i(offset_q),.available_i(available_w),.present_i(count_q!=0),
      .masks_i(aligned_masks_w),.short_i(short_flags_w),.long_i(long_flags_w),
      .plan_i(any_plan_w),.plan_position_i(plan_position_w),.plan_length_i(plan_length_w),
      .view_o(pair_view_w[pair_case]));
  end endgenerate
  wire [49:0] selected_view_w=({50{len0_w==2}}&pair_view_w[0])|
      ({50{len0_w==4}}&pair_view_w[1])|({50{len0_w==8}}&pair_view_w[2]);
  wire [3:0] lane1_mask_w,len1_w,bad0_w,bad1_w;
  wire [4:0] end1_w,fault1_offset_w,first_new_offset_w,pair_new_offset_w;
  wire [2:0] first0_w,first1_w;
  wire valid0_w,valid1_w,fault0_w,fault1_w;
  wire prefix_fault1_w=lane1_mask_w[0];
  assign {lane1_mask_w,len1_w,end1_w,bad0_w,bad1_w,first0_w,first1_w,
      fault1_offset_w,valid0_w,valid1_w,fault0_w,fault1_w,plan_bad_o,plan_at_o,
      first_new_offset_w,pair_new_offset_w}=selected_view_w;
  assign plan_target_o={plan_target_q[plan_bank_w],1'b0};
  assign plan_source_o={next_plan_w?next_block_w:pc_q[63:4],4'b0};

  assign valid_o = rst_i ? 2'b00 : {valid1_w,valid0_w};
  assign pc0_o = pc_q;
  wire [4:0] lane1_pc_offset_w={1'b0,offset_q}+{1'b0,len0_w};
  wire [4:0] fault0_pc_offset_w={1'b0,offset_q}+{2'b0,first0_w};
  wire [4:0] fault1_pc_offset_w={1'b0,offset_q}+fault1_offset_w;
  assign pc1_o={lane1_pc_offset_w[4]?next_block_w:pc_q[63:4],lane1_pc_offset_w[3:0]};
  assign length0_o = len0_w;
  assign length1_o = len1_w;
  assign inst0_o = fault0_w ? 64'b0 : instruction_bits(aligned_w[63:0],len0_w);
  assign inst1_o = fault1_w ? 64'b0 : instruction_bits(lane1_w[63:0],len1_w);
  assign fault0_o = valid0_w && fault0_w;
  assign fault1_o = valid1_w && fault1_w;
  assign cause0_o = {2'b0,first0_w}<boundary_w ? cause_q[head_q] : cause_q[next_head_w];
  assign cause1_o = fault1_offset_w<boundary_w ? cause_q[head_q] : cause_q[next_head_w];
  assign tval0_o={fault0_pc_offset_w[4]?next_block_w:pc_q[63:4],fault0_pc_offset_w[3:0]};
  assign tval1_o={fault1_pc_offset_w[4]?next_block_w:pc_q[63:4],fault1_pc_offset_w[3:0]};

  wire [4:0] consumed_w = consume_i == 2 ? end1_w :
      (consume_i == 1 ? {1'b0,len0_w} : 5'b0);
  wire [4:0] new_offset_w = consume_i==2?pair_new_offset_w:
      consume_i==1?first_new_offset_w:{1'b0,offset_q};
  wire jump_w=EARLY_PREDICT!=0&&jump_i;
  wire [1:0] pop_count_w=jump_w?(next_plan_w?2'd2:2'd1):
      ((new_offset_w>=5'd16&&consume_i!=0)?2'd1:2'd0);
  wire pop_w=pop_count_w!=0;
  assign packet_ready_o = !rst_i && !redirect_i && count_q < 3;
  wire push_w = packet_valid_i && packet_ready_o;

  always @(posedge clk_i) begin
    if (rst_i || redirect_i) begin
      head_q <= 2'b0;
      tail_q <= 2'b0;
      count_q <= 0;plan_valid_q<=0;
      pc_q <= rst_i ? RESET_PC : redirect_pc_i;
      fill_pc_q <= EARLY_PREDICT!=0?(rst_i?RESET_PC:redirect_pc_i):
        (rst_i ? {RESET_PC[63:4],4'b0} : {redirect_pc_i[63:4],4'b0});
    end else begin
      if (push_w) begin
        data_q[tail_q] <= packet_data_i;
        plan_valid_q[tail_q]<=EARLY_PREDICT!=0&&packet_plan_valid_i;
        plan_offset_q[tail_q]<=packet_plan_offset_i;plan_word_q[tail_q]<=packet_plan_word_i;
        plan_target_q[tail_q]<=packet_plan_target_i;
        fault_mask_q[tail_q] <= packet_fault_i?8'hff:packet_access_mask_i;
        cause_q[tail_q] <= packet_fault_i?packet_cause_i:5'd1;
        tail_q <= next_tail_w;
        fill_pc_q <= EARLY_PREDICT!=0&&packet_plan_valid_i?{packet_plan_target_i,1'b0}:
          {packet_pc_i[63:4],4'b0}+64'd16;
      end
      if (consume_i != 0) begin
        pc_q <= jump_w?jump_pc_i:{new_offset_w[4]?next_block_w:pc_q[63:4],new_offset_w[3:0]};
      end
      if(pop_count_w[1])head_q<=after_next_head_w;
      else if(pop_count_w[0])head_q<=next_head_w;
      count_q<=count_q+{1'b0,push_w}-pop_count_w;
    end
  end

`ifdef R64_ASSERT
  wire [2:0] next_count_check_w={1'b0,count_q}+{2'b0,push_w}-{1'b0,pop_count_w};
  wire [3:0] original_length0_w=prefix_fault0_w?4'd2:
      instruction_length(aligned_w[6:0],aligned_w[14:12],aligned_w[31:27],aligned_w[25]);
  wire [3:0] original_length1_w=prefix_fault1_w?4'd2:
      instruction_length(lane1_w[6:0],lane1_w[14:12],lane1_w[31:27],lane1_w[25]);
  always @(posedge clk_i) if (!rst_i && !redirect_i) begin
    if(valid0_w&&len0_w!==original_length0_w)$fatal(1,"predecoded lane0 length differs from raw instruction");
    if(valid1_w&&len1_w!==original_length1_w)$fatal(1,"predecoded lane1 length differs from raw instruction");
    if ((consume_i == 1 && !valid0_w) || (consume_i == 2 && !valid1_w) || consume_i == 3)
      $fatal(1,"align consume exceeds valid prefix");
    if (push_w && packet_pc_i != fill_pc_q)
      $fatal(1,"align noncontiguous block");
    if(jump_w&&(!any_plan_w||consume_i==0||{1'b0,pop_count_w}>{1'b0,count_q}))
      $fatal(1,"align prediction cut without complete owner");
    if (next_count_check_w > 3 || head_q>2 || tail_q>2 || pc_q[0]) $fatal(1,"align state invariant");
  end
`endif
endmodule


// No state or ownership lives in a view. Its input bytes/metadata are exactly
// the current pair of real packet banks; unavailable or planned target bytes
// cannot grant a valid instruction. FIRST_BYTES is a compile-time cofactor.
module R64AlignPairViewBaseline #(parameter integer FIRST_BYTES=2)(
 input [3:0] offset_i,input [5:0] available_i,input present_i,
 input [7:0] masks_i,input [15:0] short_i,long_i,
 input plan_i,input [4:0] plan_position_i,input [3:0] plan_length_i,
 output [49:0] view_o
);
 localparam [3:0] FIRST=FIRST_BYTES[3:0];
 localparam [3:0] STEP=FIRST_BYTES[4:1];
 wire [3:0] second_index_w={1'b0,offset_i[3:1]}+STEP;
 wire [3:0] second_mask_w=masks_i[FIRST_BYTES/2+:4];
 function [3:0] decode_length;
  input short_flag,long_flag;
  begin if(short_flag)decode_length=4'd2;else if(long_flag)decode_length=4'd8;else decode_length=4'd4;end
 endfunction
 wire [3:0] second_length_w=second_mask_w[0]?4'd2:
     decode_length(short_i[second_index_w],long_i[second_index_w]);
 wire [4:0] end_w={1'b0,FIRST}+{1'b0,second_length_w};
 wire [3:0] bad0_w=masks_i[3:0]&(FIRST_BYTES==2?4'b1:FIRST_BYTES==4?4'b11:4'b1111);
 wire [3:0] bad1_w=second_mask_w&(second_length_w==2?4'b1:second_length_w==4?4'b11:4'b1111);
 wire fault0_w=|bad0_w,fault1_w=|bad1_w;
 wire [2:0] first0_w=bad0_w[0]?3'd0:bad0_w[1]?3'd2:bad0_w[2]?3'd4:3'd6;
 wire [2:0] first1_w=bad1_w[0]?3'd0:bad1_w[1]?3'd2:bad1_w[2]?3'd4:3'd6;
 wire [4:0] fault_offset_w={1'b0,FIRST}+{2'b0,first1_w};
 wire valid0_w=present_i&&available_i>={2'b0,FIRST};
 wire present1_w=valid0_w&&!fault0_w&&available_i>={2'b0,FIRST}+6'd2;
 wire valid1_w=present1_w&&available_i>={1'b0,end_w};
 wire [4:0] start0_w={1'b0,offset_i},start1_w=start0_w+{1'b0,FIRST};
 wire [5:0] end0_w={1'b0,start0_w}+{2'b0,FIRST};
 wire [5:0] finish1_w={1'b0,start1_w}+{2'b0,second_length_w};
 wire [1:0] bad_w,at_w;
 assign bad_w[0]=plan_i&&present_i&&
     ((start0_w<plan_position_i&&end0_w>{1'b0,plan_position_i})||
      start0_w>plan_position_i||(start0_w==plan_position_i&&FIRST!=plan_length_i));
 assign bad_w[1]=plan_i&&present1_w&&
     ((start1_w<plan_position_i&&finish1_w>{1'b0,plan_position_i})||
      start1_w>plan_position_i||(start1_w==plan_position_i&&second_length_w!=plan_length_i));
 assign at_w[0]=plan_i&&present_i&&start0_w==plan_position_i&&!bad_w[0];
 assign at_w[1]=plan_i&&present1_w&&start1_w==plan_position_i&&!bad_w[1];
 wire [4:0] pair_offset_w=start0_w+end_w;
 assign view_o={second_mask_w,second_length_w,end_w,bad0_w,bad1_w,first0_w,first1_w,
     fault_offset_w,valid0_w,valid1_w,fault0_w,fault1_w,bad_w,at_w,start1_w,pair_offset_w};
endmodule
