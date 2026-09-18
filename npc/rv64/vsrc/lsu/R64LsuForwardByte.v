// Youngest matching store byte from a registered total-order relation.
// Valid is a shallow independent reduction; byte data follows onehot OR trees.
module R64LsuForwardByte #(parameter N=18,parameter SLOT_W=5)(
 input [N-1:0] valid_i,input [N*N-1:0] younger_i,input [N*8-1:0] data_i,
 output valid_o,output [7:0] data_o,output [N-1:0] winner_mask_o
);
 localparam LEAVES=1<<SLOT_W;
 genvar q,n;
 generate for(q=0;q<N;q=q+1)begin:gen_winner
  assign winner_mask_o[q]=valid_i[q]&&!(|(valid_i&younger_i[q*N+:N]));
 end
 for(n=1;n<2*LEAVES;n=n+1)begin:tree
  wire [7:0] data_w;
  if(n>=LEAVES)begin:leaf
   if(n-LEAVES<N)begin:present
    assign data_w={8{winner_mask_o[n-LEAVES]}}&data_i[(n-LEAVES)*8+:8];
   end else begin:pad
    assign data_w=0;
   end
  end else begin:merge
   assign data_w=tree[2*n].data_w|tree[2*n+1].data_w;
  end
 end endgenerate
 assign valid_o=|valid_i;assign data_o=tree[1].data_w;
endmodule
