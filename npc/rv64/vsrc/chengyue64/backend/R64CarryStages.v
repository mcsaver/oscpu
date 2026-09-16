// Owner-selected register boundary between local addition and global carry.
module R64CarryPrepare #(parameter WIDTH=128,parameter BLOCK=8)(
 input [WIDTH-1:0] a_i,b_i,output [WIDTH-1:0] base_o,
 output [(WIDTH+BLOCK-1)/BLOCK-1:0] propagate_o,generate_o
);
 localparam GROUPS=(WIDTH+BLOCK-1)/BLOCK;
 genvar k;
 generate for(k=0;k<GROUPS;k=k+1)begin:chunk
  localparam N=(WIDTH-k*BLOCK<BLOCK)?WIDTH-k*BLOCK:BLOCK;
  wire [N:0] sum_w={1'b0,a_i[k*BLOCK+:N]}+{1'b0,b_i[k*BLOCK+:N]};
  assign base_o[k*BLOCK+:N]=sum_w[N-1:0];
  assign propagate_o[k]=&(a_i[k*BLOCK+:N]^b_i[k*BLOCK+:N]);
  assign generate_o[k]=sum_w[N];
 end endgenerate
endmodule
module R64CarryFinish #(parameter WIDTH=128,parameter BLOCK=8)(
 input [WIDTH-1:0] base_i,input [(WIDTH+BLOCK-1)/BLOCK-1:0] propagate_i,generate_i,
 input carry_i,output [WIDTH-1:0] sum_o,output carry_o
);
 localparam GROUPS=(WIDTH+BLOCK-1)/BLOCK,LEVELS=$clog2(GROUPS);
 wire [GROUPS:0] carry_w;
 genvar k,s;
 generate for(s=0;s<=LEVELS;s=s+1)begin:prefix
  wire [GROUPS-1:0] p_w,g_w;
  if(s==0)begin assign p_w=propagate_i;assign g_w=generate_i;end
  else begin
   for(k=0;k<GROUPS;k=k+1)begin:node
    if(k>=(1<<(s-1)))begin
     assign p_w[k]=prefix[s-1].p_w[k]&prefix[s-1].p_w[k-(1<<(s-1))];
     assign g_w[k]=prefix[s-1].g_w[k]|(prefix[s-1].p_w[k]&prefix[s-1].g_w[k-(1<<(s-1))]);
    end else begin assign p_w[k]=prefix[s-1].p_w[k];assign g_w[k]=prefix[s-1].g_w[k];end
   end
  end
 end
 for(k=0;k<GROUPS;k=k+1)begin:chunk
  localparam N=(WIDTH-k*BLOCK<BLOCK)?WIDTH-k*BLOCK:BLOCK;
  assign carry_w[k+1]=prefix[LEVELS].g_w[k]|(prefix[LEVELS].p_w[k]&carry_i);
  for(genvar bit_index=0;bit_index<N;bit_index=bit_index+1)begin:increment
   if(bit_index==0)assign sum_o[k*BLOCK+bit_index]=base_i[k*BLOCK+bit_index]^carry_w[k];
   else assign sum_o[k*BLOCK+bit_index]=base_i[k*BLOCK+bit_index]^
       (carry_w[k]&&(&base_i[k*BLOCK+:bit_index]));
  end
 end endgenerate
 assign carry_w[0]=carry_i;
 assign carry_o=carry_w[GROUPS];
endmodule
