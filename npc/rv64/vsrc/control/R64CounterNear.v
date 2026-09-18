// Independent decode cones precede the counter's final write/advance choice.
module R64CounterNear #(parameter [1:0] STEP=0)(input [63:0] value_i,output [20:0] near_o);
 genvar bank,offset;
 generate for(bank=1;bank<8;bank=bank+1)begin:g_bank
  for(offset=0;offset<3;offset=offset+1)begin:g_offset
   localparam [2:0] LOW=3'd7-offset;
   wire [2:0] threshold_w=LOW-{1'b0,STEP};
   assign near_o[(bank-1)*3+offset]=(&value_i[bank*8-1:3])&&value_i[2:0]==threshold_w;
  end
 end endgenerate
endmodule
