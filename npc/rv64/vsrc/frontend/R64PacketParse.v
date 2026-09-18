// Compact classification is captured at the raw packet owner boundary.
// [7:0] short, [14:8] complete long starts 0..6, [15] final prefix,
// [16] first halfword upper signature for the previous packet's final prefix.
module R64PacketHeader(input [127:0] data_i,output [16:0] header_o);
 wire [7:0] short_w,prefix_w,upper_w;
 genvar h;
 generate for(h=0;h<8;h=h+1)begin:g_header
  wire [15:0] bits_w=data_i[h*16+:16];
  assign short_w[h]=bits_w[1:0]!=2'b11;
  assign prefix_w[h]=bits_w[6:0]==7'b1011011&&bits_w[14:12]==3'b011;
  assign upper_w[h]=bits_w[15:11]==0&&bits_w[9];
 end endgenerate
 assign header_o={upper_w[0],prefix_w[7],prefix_w[6:0]&upper_w[7:1],short_w};
endmodule

// Producer-only map computation: all starts are fixed halfword positions.
// Missing successor bytes cannot authorize an instruction.
module R64PacketParse(
 input [16:0] source_header_i,next_header_i,input [7:0] source_mask_i,next_mask_i,
 input successor_i,input source_plan_i,next_plan_i,
 input [2:0] source_offset_i,next_offset_i,input source_word_i,next_word_i,
 output [287:0] map_o
);
 wire [15:0] mask_w={next_mask_i,source_mask_i};
 wire [15:0] short_w={next_header_i[7:0],source_header_i[7:0]};
 // Bit15 is never a complete long header without a third packet.
 wire [15:0] long_w={1'b0,next_header_i[14:8],
   source_header_i[15]&next_header_i[16],source_header_i[14:8]};
 wire use_next_w=successor_i&&!source_plan_i;
 wire plan_w=source_plan_i||(use_next_w&&next_plan_i);
 wire [4:0] position_w=source_plan_i?{1'b0,source_offset_i,1'b0}:{1'b1,next_offset_i,1'b0};
 wire [3:0] plan_length_w=(source_plan_i?source_word_i:next_word_i)?4'd4:4'd2;
 genvar s,k;
 generate for(s=0;s<8;s=s+1)begin:g_start
  localparam [3:0] OFFSET=s*2;
  wire [5:0] available_w=(use_next_w?6'd32:6'd16)-{2'b0,OFFSET};
  wire [7:0] masks_w=mask_w[s+:8];
  wire [3:0] length_w=masks_w[0]?4'd2:short_w[s]?4'd2:long_w[s]?4'd8:4'd4;
  wire [49:0] view_w[0:2];
  for(k=0;k<3;k=k+1)begin:g_length
   R64AlignPairView #(.FIRST_BYTES(2<<k)) view(
    .offset_i(OFFSET),.available_i(available_w),.present_i(1'b1),
    .masks_i(masks_w),.short_i(short_w),.long_i(long_w),
    .plan_i(plan_w),.plan_position_i(position_w),.plan_length_i(plan_length_w),
    .view_o(view_w[k]));
  end
  wire [49:0] selected_w=({50{length_w==2}}&view_w[0])|
    ({50{length_w==4}}&view_w[1])|({50{length_w==8}}&view_w[2]);
  wire [3:0] mask1_w,length1_w,bad0_w,bad1_w;
  wire [4:0] end_w,fault1_w,single_w,pair_w;
  wire [2:0] first0_w,first1_w;
  wire valid0_w,valid1_w,fault0_w,fault_second_w;
  wire [1:0] bad_w,at_w;
  assign {mask1_w,length1_w,end_w,bad0_w,bad1_w,first0_w,first1_w,
    fault1_w,valid0_w,valid1_w,fault0_w,fault_second_w,bad_w,at_w,
    single_w,pair_w}=selected_w;
  wire [4:0] fault0_pos_w={1'b0,OFFSET}+{2'b0,first0_w};
  wire [4:0] fault1_pos_w=fault1_w;
  assign map_o[s*36+:36]={length_w,length1_w,fault0_pos_w,fault1_pos_w,
    valid1_w,valid0_w,fault_second_w,fault0_w,bad_w,at_w,single_w,pair_w};
  wire unused_w=|{mask1_w,bad0_w,bad1_w,end_w,first1_w};
 end endgenerate
endmodule

module R64AlignPairView #(parameter integer FIRST_BYTES=2)(
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
 // Complete absolute fault position before selecting FIRST_BYTES view.
 wire [4:0] fault_offset_w={1'b0,offset_i}+{1'b0,FIRST}+{2'b0,first1_w};
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
