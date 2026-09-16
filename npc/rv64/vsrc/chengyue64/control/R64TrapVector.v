// mtvec/stvec store a four-byte-aligned base and the supported direct/vector
// mode. The six-bit cause only selects a prepared high part after a small add;
// it never ripples a carry through the full 64-bit destination address.
module R64TrapVector(
 input [63:0] vector_i,input interrupt_i,input [5:0] cause_i,
 output [63:0] target_o
);
 wire [5:0] offset_w=(interrupt_i&&vector_i[0]) ? cause_i:6'b0;
 wire [6:0] low_w={1'b0,vector_i[7:2]}+{1'b0,offset_w};
 wire [55:0] incremented_w;
 genvar b;
 generate for(b=0;b<7;b=b+1)begin:g_byte
  wire carry_w;
  if(b==0)begin:g_first assign carry_w=1'b1;end
  else begin:g_high assign carry_w=&vector_i[b*8+7:8];end
  assign incremented_w[b*8+:8]=vector_i[b*8+8+:8]+{7'b0,carry_w};
 end endgenerate
 assign target_o={low_w[6] ? incremented_w:vector_i[63:8],low_w[5:0],2'b0};
endmodule

// One prepare edge; final three-bit carry selection is after the registers.
// This avoids cause -> full low add -> delegation mux -> target D.
module R64TrapVectorStage(
 input clk_i,input prepare_i,input [63:0] vector_i,input interrupt_i,input [5:0] cause_i,
 output [63:0] target_o
);
 wire [5:0] offset_w=(interrupt_i&&vector_i[0])?cause_i:6'b0;
 wire [3:0] low_w={1'b0,vector_i[4:2]}+{1'b0,offset_w[2:0]};
 wire [3:0] high0_w={1'b0,vector_i[7:5]}+{1'b0,offset_w[5:3]};
 wire [3:0] high1_w={1'b0,vector_i[7:5]}+{1'b0,offset_w[5:3]}+4'd1;
 wire carry_w=low_w[3]?high1_w[3]:high0_w[3];
 wire [55:0] incremented_w;
 genvar b;
 generate for(b=0;b<7;b=b+1)begin:g_byte
  wire carry_w;
  if(b==0)begin:g_first assign carry_w=1'b1;end
  else begin:g_high assign carry_w=&vector_i[b*8+7:8];end
  assign incremented_w[b*8+:8]=vector_i[b*8+8+:8]+{7'b0,carry_w};
 end endgenerate
 reg [55:0] high_q;
 reg [2:0] low_q,mid0_q,mid1_q;
 reg carry_q;
 always @(posedge clk_i)if(prepare_i)begin
  high_q<=carry_w?incremented_w:vector_i[63:8];
  low_q<=low_w[2:0];carry_q<=low_w[3];
  mid0_q<=high0_w[2:0];mid1_q<=high1_w[2:0];
 end
 assign target_o={high_q,carry_q?mid1_q:mid0_q,low_q,2'b0};
endmodule
