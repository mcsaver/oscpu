`include "R64Uop.vh"
// Final-operation ALU. Address/compare/shift-add use one carry chain; logical,
// arithmetic shifts, rotations and single-bit masks share one barrel network.
module R64Alu(
  input [63:0] a_i,b_i,input [7:0] function_i,input word_i,output reg [63:0] result_o
);
  wire uw_w=function_i>=`R64_F_ADDUW&&function_i<=`R64_F_SLLIUW;
  wire [63:0] a_w=uw_w  ?  {32'b0,a_i[31:0]}:a_i;
  wire sh1_w=function_i==`R64_F_SH1ADD||function_i==`R64_F_SH1ADDUW;
  wire sh2_w=function_i==`R64_F_SH2ADD||function_i==`R64_F_SH2ADDUW;
  wire sh3_w=function_i==`R64_F_SH3ADD||function_i==`R64_F_SH3ADDUW;
  wire [63:0] add_a_w=sh1_w  ?  {a_w[62:0],1'b0}:sh2_w  ?  {a_w[61:0],2'b0}:
                      sh3_w  ?  {a_w[60:0],3'b0}:a_w;
  wire subtract_w=function_i==`R64_F_SUB||function_i==`R64_F_SLT||
      function_i==`R64_F_SLTU||(function_i>=`R64_F_MIN&&function_i<=`R64_F_MAXU);
  wire [64:0] sum_w={1'b0,add_a_w}+{1'b0,(b_i^{64{subtract_w}})}+{64'b0,subtract_w};
  wire signed_less_w=a_i[63]!=b_i[63]  ?  a_i[63]:sum_w[63];
  wire unsigned_less_w=!sum_w[64];
  wire rotate_w=function_i==`R64_F_ROL||function_i==`R64_F_ROR;
  wire mask_w=function_i==`R64_F_BSET||function_i==`R64_F_BCLR||function_i==`R64_F_BINV;
  wire left_w=function_i==`R64_F_SLL||function_i==`R64_F_ROL||
      function_i==`R64_F_SLLIUW||mask_w;
  wire signed_shift_w=function_i==`R64_F_SRA;
  wire [5:0] amount_w=word_i  ?  {1'b0,b_i[4:0]}:b_i[5:0];
  wire [63:0] shift_a_w=mask_w  ?  64'd1:word_i  ?  
      (rotate_w  ?  {a_i[31:0],a_i[31:0]}:{{32{signed_shift_w&&a_i[31]}},a_i[31:0]}):a_w;
  wire [63:0] reverse_a_w,reverse_count_w,reverse_shift_w;
  wire [63:0] shift_input_w=left_w  ?  reverse_a_w:shift_a_w;
  wire [63:0] fill_w=rotate_w  ?  shift_input_w:{64{signed_shift_w&&shift_a_w[63]}};
  wire [127:0] barrel_w={fill_w,shift_input_w}>>amount_w;
  wire [63:0] shifted_w=left_w  ?  reverse_shift_w:barrel_w[63:0];
  wire [63:0] count_a_w=word_i  ?  {32'b0,a_i[31:0]}:a_i;
  genvar b;
  generate for(b=0;b<64;b=b+1)begin:gen_reverse
    assign reverse_a_w[b]=shift_a_w[63-b];
    assign reverse_shift_w[b]=barrel_w[63-b];
    assign reverse_count_w[b]=count_a_w[63-b];
  end endgenerate
  function [6:0] clz;
    input [63:0] value;
    reg [63:0] scan;
    reg [6:0] n;
    begin
      scan=value;n=0;
      if(scan[63:32]==0)begin n=n+32;scan=scan<<32;end
      if(scan[63:48]==0)begin n=n+16;scan=scan<<16;end
      if(scan[63:56]==0)begin n=n+8;scan=scan<<8;end
      if(scan[63:60]==0)begin n=n+4;scan=scan<<4;end
      if(scan[63:62]==0)begin n=n+2;scan=scan<<2;end
      if(!scan[63])n=n+1;
      clz=value==0  ?  7'd64:n;
    end
  endfunction
  function [3:0] pop8;
    input [7:0] v;
    reg [1:0] a,b,c,d;
    reg [2:0] e,f;
    begin
      a={1'b0,v[0]}+{1'b0,v[1]};b={1'b0,v[2]}+{1'b0,v[3]};
      c={1'b0,v[4]}+{1'b0,v[5]};d={1'b0,v[6]}+{1'b0,v[7]};
      e={1'b0,a}+{1'b0,b};f={1'b0,c}+{1'b0,d};pop8={1'b0,e}+{1'b0,f};
    end
  endfunction
  wire [3:0] pop_w[0:7];
  generate for(b=0;b<8;b=b+1)begin:gen_pop
    assign pop_w[b]=pop8(count_a_w[b*8+:8]);
  end endgenerate
  wire [4:0] pop01_w={1'b0,pop_w[0]}+{1'b0,pop_w[1]};
  wire [4:0] pop23_w={1'b0,pop_w[2]}+{1'b0,pop_w[3]};
  wire [4:0] pop45_w={1'b0,pop_w[4]}+{1'b0,pop_w[5]};
  wire [4:0] pop67_w={1'b0,pop_w[6]}+{1'b0,pop_w[7]};
  wire [5:0] pop03_w={1'b0,pop01_w}+{1'b0,pop23_w};
  wire [5:0] pop47_w={1'b0,pop45_w}+{1'b0,pop67_w};
  wire [6:0] population_w={1'b0,pop03_w}+{1'b0,pop47_w};
  wire [63:0] zero_input_w=function_i==`R64_F_CTZ  ?  reverse_count_w:
      word_i  ?  {a_i[31:0],32'b0}:a_i;
  wire [6:0] zero_count_w=(word_i&&a_i[31:0]==0)  ?  7'd32:clz(zero_input_w);
  wire [63:0] bytes_rev_w,bytes_or_w;
  generate for(b=0;b<8;b=b+1)begin:gen_bytes
    assign bytes_rev_w[b*8+:8]=a_i[(7-b)*8+:8];
    assign bytes_or_w[b*8+:8]={8{|a_i[b*8+:8]}};
  end endgenerate
  reg [63:0] value_w;
  always @(*) begin
    value_w=0;
    case(function_i)
      `R64_F_ADD,`R64_F_SUB,`R64_F_SH1ADD,`R64_F_SH2ADD,`R64_F_SH3ADD,
      `R64_F_ADDUW,`R64_F_SH1ADDUW,`R64_F_SH2ADDUW,`R64_F_SH3ADDUW:value_w=sum_w[63:0];
      `R64_F_SLT:value_w={63'b0,signed_less_w};
      `R64_F_SLTU:value_w={63'b0,unsigned_less_w};
      `R64_F_SLL,`R64_F_SRL,`R64_F_SRA,`R64_F_ROL,`R64_F_ROR,`R64_F_SLLIUW:value_w=shifted_w;
      `R64_F_XOR:value_w=a_i^b_i;
      `R64_F_OR:value_w=a_i|b_i;
      `R64_F_AND:value_w=a_i&b_i;
      `R64_F_COPY_B:value_w=b_i;
      `R64_F_ANDN:value_w=a_i&~b_i;
      `R64_F_ORN:value_w=a_i|~b_i;
      `R64_F_XNOR:value_w=~(a_i^b_i);
      `R64_F_MIN:value_w=signed_less_w  ?  a_i:b_i;
      `R64_F_MAX:value_w=signed_less_w  ?  b_i:a_i;
      `R64_F_MINU:value_w=unsigned_less_w  ?  a_i:b_i;
      `R64_F_MAXU:value_w=unsigned_less_w  ?  b_i:a_i;
      `R64_F_BSET:value_w=a_i|shifted_w;
      `R64_F_BCLR:value_w=a_i&~shifted_w;
      `R64_F_BINV:value_w=a_i^shifted_w;
      `R64_F_BEXT:value_w={63'b0,shifted_w[0]};
      `R64_F_CLZ,`R64_F_CTZ:value_w={57'b0,zero_count_w};
      `R64_F_CPOP:value_w={57'b0,population_w};
      `R64_F_SEXTB:value_w={{56{a_i[7]}},a_i[7:0]};
      `R64_F_SEXTH:value_w={{48{a_i[15]}},a_i[15:0]};
      `R64_F_ZEXTH:value_w={48'b0,a_i[15:0]};
      `R64_F_REV8:value_w=bytes_rev_w;
      `R64_F_ORCB:value_w=bytes_or_w;
      default:begin end
    endcase
    result_o=word_i  ?  {{32{value_w[31]}},value_w[31:0]}:value_w;
  end
endmodule


// Two compute phases: local 4-bit carry and byte shift/count preparation is registered;
// global carry, remaining shift and final selection feed the owner's terminal
// register. Metadata/VALID are owned by Execute, never inferred by this data path.
module R64AluControl(input [7:0] function_i,output [36:0] control_o);
 function [36:0] decode_control;
 input [7:0] function_i;
 reg [14:0] group_w;
 begin
  decode_control=0;
  group_w=0;
  case(function_i)
   `R64_F_ADD,`R64_F_SUB,`R64_F_SH1ADD,`R64_F_SH2ADD,`R64_F_SH3ADD,
   `R64_F_ADDUW,`R64_F_SH1ADDUW,`R64_F_SH2ADDUW,`R64_F_SH3ADDUW:group_w[1]=1;
   `R64_F_SLT:group_w[2]=1;`R64_F_SLTU:group_w[3]=1;
   `R64_F_SLL,`R64_F_SRL,`R64_F_SRA,`R64_F_ROL,`R64_F_ROR,`R64_F_SLLIUW:group_w[4]=1;
   `R64_F_BSET:group_w[5]=1;`R64_F_BCLR:group_w[6]=1;
   `R64_F_BINV:group_w[7]=1;`R64_F_BEXT:group_w[8]=1;
   `R64_F_MIN:group_w[9]=1;`R64_F_MAX:group_w[10]=1;
   `R64_F_MINU:group_w[11]=1;`R64_F_MAXU:group_w[12]=1;
   `R64_F_CLZ,`R64_F_CTZ:group_w[13]=1;`R64_F_CPOP:group_w[14]=1;
   default:group_w[0]=1;
  endcase

  decode_control[14:0]=group_w;
  decode_control[15]=function_i==`R64_F_XOR;
  decode_control[16]=function_i==`R64_F_OR;
  decode_control[17]=function_i==`R64_F_AND;
  decode_control[18]=function_i==`R64_F_COPY_B;
  decode_control[19]=function_i==`R64_F_ANDN;
  decode_control[20]=function_i==`R64_F_ORN;
  decode_control[21]=function_i==`R64_F_XNOR;
  decode_control[22]=function_i==`R64_F_SEXTB;
  decode_control[23]=function_i==`R64_F_SEXTH;
  decode_control[24]=function_i==`R64_F_ZEXTH;
  decode_control[25]=function_i==`R64_F_REV8;
  decode_control[26]=function_i==`R64_F_ORCB;
  decode_control[27]=function_i>=`R64_F_ADDUW&&function_i<=`R64_F_SLLIUW;
  decode_control[28]=function_i==`R64_F_SH1ADD||function_i==`R64_F_SH1ADDUW;
  decode_control[29]=function_i==`R64_F_SH2ADD||function_i==`R64_F_SH2ADDUW;
  decode_control[30]=function_i==`R64_F_SH3ADD||function_i==`R64_F_SH3ADDUW;
  decode_control[31]=function_i==`R64_F_SUB||function_i==`R64_F_SLT||function_i==`R64_F_SLTU;
  decode_control[32]=function_i==`R64_F_ROL||function_i==`R64_F_ROR;
  decode_control[33]=function_i==`R64_F_BSET||function_i==`R64_F_BCLR||function_i==`R64_F_BINV;
  decode_control[34]=function_i==`R64_F_SLL||function_i==`R64_F_ROL||function_i==`R64_F_SLLIUW||decode_control[33];
  decode_control[35]=function_i==`R64_F_SRA;
  decode_control[36]=function_i==`R64_F_CTZ;
 end
 endfunction
 assign control_o=decode_control(function_i);
endmodule
module R64AluPipe(input clk,input [63:0] a_i,b_i,input [7:0] function_i,input word_i,output [63:0] result_o);
 wire [36:0] control_w;wire [63:0] raw_w;wire word_w;
 R64AluControl control(.function_i(function_i),.control_o(control_w));
 R64AluDatapath datapath(.clk(clk),.a_i(a_i),.b_i(b_i),.add_a_i(a_i),.add_b_i(b_i),.shift_amount_i(b_i[5:0]),.control_i(control_w),.word_i(word_i),.result_o(raw_w),.word_o(word_w),.add_result_o());
 assign result_o=word_w ? {{32{raw_w[31]}},raw_w[31:0]}:raw_w;
endmodule

module R64AluDatapath(
 input clk,input [63:0] a_i,b_i,add_a_i,add_b_i,input [5:0] shift_amount_i,input [36:0] control_i,input word_i,
 output [63:0] result_o,output word_o,output [63:0] add_result_o
);
 wire [14:0] group_w=control_i[14:0];
 wire [11:0] simple_select_w=control_i[26:15];
 wire uw_w=control_i[27],sh1_w=control_i[28],sh2_w=control_i[29],sh3_w=control_i[30];
 wire subtract_w=control_i[31],rotate_w=control_i[32],mask_w=control_i[33];
 wire left_w=control_i[34],signed_shift_w=control_i[35];
 wire [63:0] a_w=uw_w ? {32'b0,a_i[31:0]}:a_i;
 wire [63:0] add_source_w=uw_w ? {32'b0,add_a_i[31:0]}:add_a_i;
 wire [63:0] add_a_w=({add_source_w[62:0],1'b0}&{64{sh1_w}})|
     ({add_source_w[61:0],2'b0}&{64{sh2_w}})|
     ({add_source_w[60:0],3'b0}&{64{sh3_w}})|
     (add_source_w&{64{!(sh1_w||sh2_w||sh3_w)}});
 wire [63:0] base_w;wire [15:0] propagate_w,generate_w;
 R64CarryPrepare #(.WIDTH(64),.BLOCK(4)) add_prepare(
  .a_i(add_a_w),.b_i(add_b_i^{64{subtract_w}}),.base_o(base_w),
  .propagate_o(propagate_w),.generate_o(generate_w));
 wire [5:0] amount_w=word_i ? {1'b0,shift_amount_i[4:0]}:shift_amount_i;
 wire [63:0] shift_a_w=mask_w ? 64'd1:word_i ? 
     (rotate_w ? {a_i[31:0],a_i[31:0]}:{{32{signed_shift_w&&a_i[31]}},a_i[31:0]}):a_w;
 wire [63:0] reverse_a_w,reverse_count_w;
 wire [63:0] shift_input_w=left_w ? reverse_a_w:shift_a_w;
 wire [63:0] fill_w=rotate_w ? shift_input_w:{64{signed_shift_w&&shift_a_w[63]}};
 wire [127:0] partial_shift_w={fill_w,shift_input_w}>>amount_w[2:0];
 wire [63:0] count_a_w=word_i ? {32'b0,a_i[31:0]}:a_i;
 wire [63:0] zero_input_w=control_i[36] ? reverse_count_w:
     word_i ? {a_i[31:0],32'b0}:a_i;
 wire [63:0] bytes_rev_w,bytes_or_w;
 genvar k;
 generate for(k=0;k<64;k=k+1)begin:reverse
  assign reverse_a_w[k]=shift_a_w[63-k];
  assign reverse_count_w[k]=count_a_w[63-k];
 end
 for(k=0;k<8;k=k+1)begin:bytes
  assign bytes_rev_w[k*8+:8]=a_i[(7-k)*8+:8];
  assign bytes_or_w[k*8+:8]={8{|a_i[k*8+:8]}};
 end endgenerate
 function [3:0] pop8;
  input [7:0] v;reg [1:0] a,b,c,d;reg [2:0] e,f;
  begin
   a={1'b0,v[0]}+{1'b0,v[1]};b={1'b0,v[2]}+{1'b0,v[3]};
   c={1'b0,v[4]}+{1'b0,v[5]};d={1'b0,v[6]}+{1'b0,v[7]};
   e={1'b0,a}+{1'b0,b};f={1'b0,c}+{1'b0,d};pop8={1'b0,e}+{1'b0,f};
  end
 endfunction
 function [2:0] clz8;
  input [7:0] v;
  begin clz8=v[7] ? 0:v[6] ? 1:v[5] ? 2:v[4] ? 3:v[3] ? 4:v[2] ? 5:v[1] ? 6:7;end
 endfunction
 wire [63:0] simple_w=((a_i^b_i)&{64{simple_select_w[0]}})|
     ((a_i|b_i)&{64{simple_select_w[1]}})|((a_i&b_i)&{64{simple_select_w[2]}})|
     (b_i&{64{simple_select_w[3]}})|((a_i&~b_i)&{64{simple_select_w[4]}})|
     ((a_i|~b_i)&{64{simple_select_w[5]}})|(~(a_i^b_i)&{64{simple_select_w[6]}})|
     ({{56{a_i[7]}},a_i[7:0]}&{64{simple_select_w[7]}})|
     ({{48{a_i[15]}},a_i[15:0]}&{64{simple_select_w[8]}})|
     ({48'b0,a_i[15:0]}&{64{simple_select_w[9]}})|
     (bytes_rev_w&{64{simple_select_w[10]}})|(bytes_or_w&{64{simple_select_w[11]}});
 reg [63:0] base_q,a_q,b_q,simple_q;
 reg [15:0] propagate_q,generate_q;
 reg [7:0] nonzero_q;
 reg [119:0] shift_q;
 reg [31:0] pop_q;reg [23:0] zero_q;
 reg [14:0] group_q;reg [2:0] amount_q;
 reg subtract_q,left_q,word_q;
 reg [15:0] compare_equal_q,compare_less_q;
 integer byte_index;
 always @(posedge clk)begin
  base_q<=base_w;propagate_q<=propagate_w;generate_q<=generate_w;
  a_q<=a_i;b_q<=b_i;simple_q<=simple_w;group_q<=group_w;
  shift_q<=partial_shift_w[119:0];amount_q<=amount_w[5:3];
  subtract_q<=subtract_w;left_q<=left_w;word_q<=word_i;
  for(byte_index=0;byte_index<16;byte_index=byte_index+1)begin
   compare_equal_q[byte_index]<=a_i[byte_index*4+:4]==b_i[byte_index*4+:4];
   compare_less_q[byte_index]<=a_i[byte_index*4+:4]<b_i[byte_index*4+:4];
  end
  for(byte_index=0;byte_index<8;byte_index=byte_index+1)begin
   pop_q[byte_index*4+:4]<=pop8(count_a_w[byte_index*8+:8]);
   zero_q[byte_index*3+:3]<=clz8(zero_input_w[byte_index*8+:8]);
   nonzero_q[byte_index]<=|zero_input_w[byte_index*8+:8];
  end
 end
 wire [63:0] sum_w;wire carry_w;
 R64CarryFinish #(.WIDTH(64),.BLOCK(4)) add_finish(
  .base_i(base_q),.propagate_i(propagate_q),.generate_i(generate_q),
  .carry_i(subtract_q),.sum_o(sum_w),.carry_o(carry_w));
 wire [15:0] less_hit_w;
 generate for(k=0;k<16;k=k+1)begin:compare
  if(k==15)assign less_hit_w[k]=compare_less_q[k];
  else assign less_hit_w[k]=compare_less_q[k]&&(&compare_equal_q[15:k+1]);
 end endgenerate
 wire unsigned_less_w=|less_hit_w;
 wire signed_less_w=a_q[63]!=b_q[63] ? a_q[63]:unsigned_less_w;
 wire [119:0] finish_shift_w=shift_q>>{amount_q,3'b0};
 wire [63:0] shifted_w;
 generate for(k=0;k<64;k=k+1)begin:finish_reverse
  assign shifted_w[k]=left_q ? finish_shift_w[63-k]:finish_shift_w[k];
 end endgenerate
 wire [4:0] pop01_w={1'b0,pop_q[3:0]}+{1'b0,pop_q[7:4]};
 wire [4:0] pop23_w={1'b0,pop_q[11:8]}+{1'b0,pop_q[15:12]};
 wire [4:0] pop45_w={1'b0,pop_q[19:16]}+{1'b0,pop_q[23:20]};
 wire [4:0] pop67_w={1'b0,pop_q[27:24]}+{1'b0,pop_q[31:28]};
 wire [5:0] pop03_w={1'b0,pop01_w}+{1'b0,pop23_w};
 wire [5:0] pop47_w={1'b0,pop45_w}+{1'b0,pop67_w};
 wire [6:0] population_w={1'b0,pop03_w}+{1'b0,pop47_w};
 wire [7:0] zero_hit_w;
 generate for(k=0;k<8;k=k+1)begin:zero_choice
  if(k==7)assign zero_hit_w[k]=nonzero_q[k];
  else assign zero_hit_w[k]=nonzero_q[k]&&!(|nonzero_q[7:k+1]);
 end endgenerate
 reg [6:0] zero_count_w;reg [2:0] zero_group_w;integer z;
 always @(*)begin
  zero_count_w=0;
  for(z=0;z<8;z=z+1)begin
   zero_group_w=3'b111-z[2:0];
   zero_count_w=zero_count_w|({1'b0,zero_group_w,zero_q[z*3+:3]}&{7{zero_hit_w[z]}});
  end
  if(nonzero_q==0)zero_count_w=word_q ? 7'd32:7'd64;
 end
 wire choose_a_w=(group_q[9]&&signed_less_w)||(group_q[10]&&!signed_less_w)||
     (group_q[11]&&unsigned_less_w)||(group_q[12]&&!unsigned_less_w);
 wire choose_b_w=(group_q[9]&&!signed_less_w)||(group_q[10]&&signed_less_w)||
     (group_q[11]&&!unsigned_less_w)||(group_q[12]&&unsigned_less_w);
 wire [63:0] value_w=(simple_q&{64{group_q[0]}})|(sum_w&{64{group_q[1]}})|
     {63'b0,(group_q[2]&&signed_less_w)||(group_q[3]&&unsigned_less_w)||(group_q[8]&&shifted_w[0])}|
     (shifted_w&{64{group_q[4]}})|((a_q|shifted_w)&{64{group_q[5]}})|
     ((a_q&~shifted_w)&{64{group_q[6]}})|((a_q^shifted_w)&{64{group_q[7]}})|
     (a_q&{64{choose_a_w}})|(b_q&{64{choose_b_w}})|
     {57'b0,(zero_count_w&{7{group_q[13]}})|(population_w&{7{group_q[14]}})};
 assign result_o=value_w;
 assign add_result_o=sum_w;
 assign word_o=word_q;
endmodule
