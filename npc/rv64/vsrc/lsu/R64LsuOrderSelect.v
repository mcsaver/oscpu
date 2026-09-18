// Queue admission establishes an immutable older-than relation until reuse.
// Select the first two eligible owners with parallel 0/1-older reductions.
module R64LsuOrderSelect #(parameter N=18,parameter SLOT_W=5)(
 input [N-1:0] valid_i,input [N*N-1:0] older_i,
 output first_valid_o,second_valid_o,output [N-1:0] first_mask_o,second_mask_o,
 output [SLOT_W-1:0] first_slot_o,second_slot_o
);
 localparam LEAVES=1<<SLOT_W;
 wire [N-1:0] first_hit_w,second_hit_w;
 genvar e,n;
 generate for(e=0;e<N;e=e+1)begin:entry
  for(n=1;n<2*LEAVES;n=n+1)begin:count
   wire any_w,two_w;
   if(n>=LEAVES)begin:leaf
    if(n-LEAVES<N)begin:present
     assign any_w=valid_i[n-LEAVES]&&older_i[e*N+n-LEAVES];
    end else begin:pad
     assign any_w=0;
    end
    assign two_w=0;
   end else begin:merge
    assign any_w=count[2*n].any_w||count[2*n+1].any_w;
    assign two_w=count[2*n].two_w||count[2*n+1].two_w||
      (count[2*n].any_w&&count[2*n+1].any_w);
   end
  end
  assign first_hit_w[e]=valid_i[e]&&!count[1].any_w;
  assign second_hit_w[e]=valid_i[e]&&count[1].any_w&&!count[1].two_w;
 end
 for(n=1;n<2*LEAVES;n=n+1)begin:encode
  wire [SLOT_W-1:0] first_w,second_w;
  if(n>=LEAVES)begin:leaf
   localparam integer NUMBER=n-LEAVES;
   if(n-LEAVES<N)begin:present
    assign first_w={SLOT_W{first_hit_w[n-LEAVES]}}&NUMBER[SLOT_W-1:0];
    assign second_w={SLOT_W{second_hit_w[n-LEAVES]}}&NUMBER[SLOT_W-1:0];
   end else begin:pad
    assign first_w=0;assign second_w=0;
   end
  end else begin:merge
   assign first_w=encode[2*n].first_w|encode[2*n+1].first_w;
   assign second_w=encode[2*n].second_w|encode[2*n+1].second_w;
  end
 end endgenerate
 assign first_mask_o=first_hit_w;assign second_mask_o=second_hit_w;
 assign first_valid_o=|first_hit_w;assign second_valid_o=|second_hit_w;
 assign first_slot_o=encode[1].first_w;assign second_slot_o=encode[1].second_w;
endmodule
