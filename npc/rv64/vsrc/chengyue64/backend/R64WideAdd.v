// Eight-bit local adders and a parallel group carry prefix. There is no
// unbounded ripple from bit zero to the top of a wide numerical accumulator.
module R64WideAdd #(parameter WIDTH=128,parameter BLOCK=8)(
  input [WIDTH-1:0] a_i,b_i,input carry_i,
  output [WIDTH-1:0] sum_o,output carry_o
);
  localparam GROUPS=(WIDTH+BLOCK-1)/BLOCK;
  localparam LEVELS=$clog2(GROUPS);
  wire [GROUPS-1:0] p0_w,g0_w;
  wire [GROUPS:0] carry_w;
  genvar k,s;
  generate for(k=0;k<GROUPS;k=k+1)begin:chunk
    localparam N=(WIDTH-k*BLOCK<BLOCK)?WIDTH-k*BLOCK:BLOCK;
    wire [N:0] base_w={1'b0,a_i[k*BLOCK+:N]}+{1'b0,b_i[k*BLOCK+:N]};
    assign p0_w[k]=&(a_i[k*BLOCK+:N]^b_i[k*BLOCK+:N]);
    assign g0_w[k]=base_w[N];
    for(genvar bit_index=0;bit_index<N;bit_index=bit_index+1)begin:increment
      if(bit_index==0)assign sum_o[k*BLOCK+bit_index]=base_w[bit_index]^carry_w[k];
      else assign sum_o[k*BLOCK+bit_index]=base_w[bit_index]^
          (carry_w[k]&&(&base_w[bit_index-1:0]));
    end
  end
  for(s=0;s<=LEVELS;s=s+1)begin:prefix
    wire [GROUPS-1:0] p_w,g_w;
    if(s==0)begin
      assign p_w=p0_w;assign g_w=g0_w;
    end else begin
      for(k=0;k<GROUPS;k=k+1)begin:node
        if(k>=(1<<(s-1)))begin
          assign p_w[k]=prefix[s-1].p_w[k]&prefix[s-1].p_w[k-(1<<(s-1))];
          assign g_w[k]=prefix[s-1].g_w[k]|
              (prefix[s-1].p_w[k]&prefix[s-1].g_w[k-(1<<(s-1))]);
        end else begin
          assign p_w[k]=prefix[s-1].p_w[k];assign g_w[k]=prefix[s-1].g_w[k];
        end
      end
    end
  end
  for(k=1;k<=GROUPS;k=k+1)begin:carry
    assign carry_w[k]=prefix[LEVELS].g_w[k-1]|(prefix[LEVELS].p_w[k-1]&carry_i);
  end endgenerate
  assign carry_w[0]=carry_i;
  assign carry_o=carry_w[GROUPS];
endmodule
