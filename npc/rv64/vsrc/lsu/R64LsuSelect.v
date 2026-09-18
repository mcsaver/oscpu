// Bounded age-selection trees. Invalid leaves never participate.
module R64LsuSelect #(parameter N=18,parameter SLOT_W=5,parameter AGE_W=5)(
 input [N-1:0] valid_i,input [N*AGE_W-1:0] age_i,
 output first_valid_o,second_valid_o,output [SLOT_W-1:0] first_slot_o,second_slot_o,
 output [AGE_W-1:0] first_age_o,second_age_o
);
 localparam LEAVES=1<<SLOT_W;
 genvar n;
 generate for(n=1;n<2*LEAVES;n=n+1)begin:tree
  wire v0,v1;wire [AGE_W-1:0] a0,a1;wire [SLOT_W-1:0] s0,s1;
  if(n>=LEAVES)begin:leaf
   localparam integer LEAF=n-LEAVES;
   if(n-LEAVES<N)begin:present
    assign v0=valid_i[n-LEAVES];assign a0=age_i[(n-LEAVES)*AGE_W+:AGE_W];
   end else begin:pad
    assign v0=0;assign a0=0;
   end
   assign s0=LEAF[SLOT_W-1:0];assign v1=0;assign a1=0;assign s1=0;
  end else begin:merge
   wire left=tree[2*n].v0&&(!tree[2*n+1].v0||tree[2*n].a0<=tree[2*n+1].a0);
   wire av=left?tree[2*n].v1:tree[2*n].v0;
   wire bv=left?tree[2*n+1].v0:tree[2*n+1].v1;
   wire [AGE_W-1:0] aa=left?tree[2*n].a1:tree[2*n].a0;
   wire [AGE_W-1:0] ba=left?tree[2*n+1].a0:tree[2*n+1].a1;
   wire [SLOT_W-1:0] aslot=left?tree[2*n].s1:tree[2*n].s0;
   wire [SLOT_W-1:0] bslot=left?tree[2*n+1].s0:tree[2*n+1].s1;
   wire second_left=av&&(!bv||aa<=ba);
   assign v0=tree[2*n].v0||tree[2*n+1].v0;
   assign a0=left?tree[2*n].a0:tree[2*n+1].a0;
   assign s0=left?tree[2*n].s0:tree[2*n+1].s0;
   assign v1=av||bv;assign a1=second_left?aa:ba;assign s1=second_left?aslot:bslot;
  end
 end endgenerate
 assign first_valid_o=tree[1].v0;assign first_slot_o=tree[1].v0?tree[1].s0:0;assign first_age_o=tree[1].a0;
 assign second_age_o=tree[1].a1;
 assign second_valid_o=tree[1].v1;assign second_slot_o=tree[1].v1?tree[1].s1:0;
endmodule

