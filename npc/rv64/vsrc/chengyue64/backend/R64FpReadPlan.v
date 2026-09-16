// Pure FP port representation. No owner, clock, or readiness is held here.
// A row compacts its three FP requests before IQ selection. RegRead then
// relocates only the second lane, preserving even the legacy 2-bit rank wrap.
module R64FpReadCompact #(parameter PREG_W=6)(
 input [3*PREG_W-1:0] preg_i,input [2:0] used_i,fp_i,
 output [3*PREG_W+7:0] plan_o
);
 wire [2:0] request_w=used_i&fp_i;
 wire [1:0] count_w={1'b0,request_w[0]}+{1'b0,request_w[1]}+{1'b0,request_w[2]};
 wire [5:0] rank_w={{1'b0,request_w[0]}+{1'b0,request_w[1]},
                    1'b0,request_w[0],2'b0};
 wire [3*PREG_W-1:0] address_w;
 genvar port,source;
 generate for(port=0;port<3;port=port+1)begin:g_port
  wire [PREG_W-1:0] item_w[0:2];
  for(source=0;source<3;source=source+1)begin:g_source
   assign item_w[source]=preg_i[source*PREG_W+:PREG_W]&
       {PREG_W{request_w[source]&&rank_w[source*2+:2]==2'(port)}};
  end
  assign address_w[port*PREG_W+:PREG_W]=(item_w[0]|item_w[1])|item_w[2];
 end endgenerate
 assign plan_o={count_w,rank_w,address_w};
endmodule

module R64FpReadJoin #(parameter PREG_W=6)(
 input [2*(3*PREG_W+8)-1:0] plan_i,input [1:0] fire_i,
 output [3*PREG_W-1:0] address_o,output [11:0] rank_o
);
 localparam PLAN_W=3*PREG_W+8;
 wire [1:0] count0_w=plan_i[3*PREG_W+6+:2];
 wire [1:0] count1_w=plan_i[PLAN_W+3*PREG_W+6+:2];
 wire [1:0] offset_w=count0_w&{2{fire_i[0]}};
 genvar source,port;
 generate for(source=0;source<3;source=source+1)begin:g_rank
  assign rank_o[source*2+:2]=plan_i[3*PREG_W+source*2+:2]&{2{fire_i[0]}};
  assign rank_o[(source+3)*2+:2]=offset_w+
      (plan_i[PLAN_W+3*PREG_W+source*2+:2]&{2{fire_i[1]}});
 end
 for(port=0;port<3;port=port+1)begin:g_port
  wire [PREG_W-1:0] item_w[0:3];
  assign item_w[0]=plan_i[port*PREG_W+:PREG_W]&
      {PREG_W{fire_i[0]&&count0_w>2'(port)}};
  for(source=0;source<3;source=source+1)begin:g_second
   wire [1:0] destination_w=offset_w+2'(source);
   assign item_w[source+1]=plan_i[PLAN_W+source*PREG_W+:PREG_W]&
       {PREG_W{fire_i[1]&&count1_w>2'(source)&&destination_w==2'(port)}};
  end
  assign address_o[port*PREG_W+:PREG_W]=(item_w[0]|item_w[1])|(item_w[2]|item_w[3]);
 end endgenerate
endmodule
