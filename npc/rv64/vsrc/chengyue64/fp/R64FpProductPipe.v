// Five numerical stages, independently enabled by the enclosing FMA owner.
// Unsigned 53x53 product. No tag, cancellation or second validity state here.
module R64FpProductPipe(input clk,input [4:0] enable_i,
 input [52:0] a_i,b_i,output [105:0] product_o);
 wire [105:0] rows0_w[0:27];
 genvar tile,s,j;
 generate for(tile=0;tile<14;tile=tile+1)begin:partial
  localparam BITS=tile==13?1:4,FULL=53+BITS;
  wire [FULL-1:0] sum_w,carry_w;
  reg [FULL-1:0] sum_q,carry_q;
  R64ProductTree #(.WIDTH(53),.BWIDTH(BITS)) tree(.a_i(a_i),.b_i(b_i[tile*4+:BITS]),
   .sum_o(sum_w),.carry_o(carry_w));
  always @(posedge clk)if(enable_i[0])begin sum_q<=sum_w;carry_q<=carry_w;end
  assign rows0_w[2*tile]={{(106-FULL){1'b0}},sum_q}<<(tile*4);
  assign rows0_w[2*tile+1]={{(106-FULL){1'b0}},carry_q}<<(tile*4);
 end endgenerate
 function integer rows_after;
  input integer n,levels;integer k;
  begin for(k=0;k<levels;k=k+1)n=2*(n/3)+(n%3);rows_after=n;end
 endfunction
 generate for(s=0;s<=4;s=s+1)begin:first
  localparam N=rows_after(28,s);
  wire [105:0] row_w[0:N-1];
  if(s==0)begin
   for(j=0;j<N;j=j+1)begin:source assign row_w[j]=rows0_w[j];end
  end else begin
   localparam PREV=rows_after(28,s-1),GROUPS=PREV/3;
   for(j=0;j<GROUPS;j=j+1)begin:triple
    wire [105:0] a=first[s-1].row_w[3*j],b=first[s-1].row_w[3*j+1],c=first[s-1].row_w[3*j+2];
    assign row_w[2*j]=a^b^c;assign row_w[2*j+1]=((a&b)|(a&c)|(b&c))<<1;
   end
   for(j=0;j<PREV%3;j=j+1)begin:remain assign row_w[2*GROUPS+j]=first[s-1].row_w[3*GROUPS+j];end
  end
 end endgenerate
 reg [105:0] middle_q[0:5];
 generate for(j=0;j<6;j=j+1)begin:middle
  always @(posedge clk)if(enable_i[1])middle_q[j]<=first[4].row_w[j];
 end
 for(s=0;s<=3;s=s+1)begin:second
  localparam N=rows_after(6,s);
  wire [105:0] row_w[0:N-1];
  if(s==0)begin
   for(j=0;j<N;j=j+1)begin:source assign row_w[j]=middle_q[j];end
  end else begin
   localparam PREV=rows_after(6,s-1),GROUPS=PREV/3;
   for(j=0;j<GROUPS;j=j+1)begin:triple
    wire [105:0] a=second[s-1].row_w[3*j],b=second[s-1].row_w[3*j+1],c=second[s-1].row_w[3*j+2];
    assign row_w[2*j]=a^b^c;assign row_w[2*j+1]=((a&b)|(a&c)|(b&c))<<1;
   end
   for(j=0;j<PREV%3;j=j+1)begin:remain assign row_w[2*GROUPS+j]=second[s-1].row_w[3*GROUPS+j];end
  end
 end endgenerate
 reg [105:0] sum2_q,carry2_q,base3_q,product4_q;
 wire [105:0] base_w,product_w;
 reg [26:0] propagate3_q,generate3_q;
 wire [26:0] propagate_w,generate_w;
 R64CarryPrepare #(.WIDTH(106),.BLOCK(4)) prepare(.a_i(sum2_q),.b_i(carry2_q),.base_o(base_w),
  .propagate_o(propagate_w),.generate_o(generate_w));
 R64CarryFinish #(.WIDTH(106),.BLOCK(4)) finish(.base_i(base3_q),.propagate_i(propagate3_q),
  .generate_i(generate3_q),.carry_i(1'b0),.sum_o(product_w),.carry_o());
 always @(posedge clk)begin
  if(enable_i[2])begin sum2_q<=second[3].row_w[0];carry2_q<=second[3].row_w[1];end
  if(enable_i[3])begin base3_q<=base_w;propagate3_q<=propagate_w;generate3_q<=generate_w;end
  if(enable_i[4])product4_q<=product_w;
 end
 assign product_o=product4_q;
endmodule
