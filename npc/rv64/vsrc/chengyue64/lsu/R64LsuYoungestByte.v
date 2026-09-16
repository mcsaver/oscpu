// Carry the byte through the age tree; do not follow selection with an indexed
// 18-way data read. PA equality and older-than-load qualification are shared.
module R64LsuYoungestByte #(parameter N=18,parameter SLOT_W=5,parameter AGE_W=5)(
 input [N-1:0] valid_i,input [N*AGE_W-1:0] age_i,input [N*8-1:0] data_i,
 output valid_o,output [7:0] data_o,output [AGE_W-1:0] age_o
);
 localparam LEAVES=1<<SLOT_W;
 genvar n;
 generate for(n=1;n<2*LEAVES;n=n+1)begin:tree
  wire valid;wire [AGE_W-1:0] age;wire [7:0] data;
  if(n>=LEAVES)begin:leaf
   if(n-LEAVES<N)begin:present
    assign valid=valid_i[n-LEAVES];assign age=age_i[(n-LEAVES)*AGE_W+:AGE_W];
    assign data=data_i[(n-LEAVES)*8+:8];
   end else begin:pad
    assign valid=0;assign age=0;assign data=0;
   end
  end else begin:merge
   wire left=tree[2*n].valid&&(!tree[2*n+1].valid||tree[2*n].age>=tree[2*n+1].age);
   assign valid=tree[2*n].valid||tree[2*n+1].valid;
   assign age=left?tree[2*n].age:tree[2*n+1].age;
   assign data=left?tree[2*n].data:tree[2*n+1].data;
  end
 end endgenerate
 assign age_o=tree[1].age;assign valid_o=tree[1].valid;assign data_o=tree[1].valid?tree[1].data:8'b0;
endmodule
