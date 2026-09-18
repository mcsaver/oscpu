// Decode the architectural PMP configuration once, then share these boundaries
// across instruction, data and page-table ports. RV64 implements 56-bit PA.
module R64PmpDecode(
 input [127:0] config_i,input [863:0] address_i,
 output [15:0] active_o,output [895:0] lower_o,upper_o,output [63:0] permission_o
);
 genvar i;
 generate for(i=0;i<16;i=i+1)begin:g_entry
  wire [7:0] cfg_w=config_i[i*8+:8];
  wire [53:0] address_w=address_i[i*54+:54];
  wire [55:0] tor_lower_w;
  if(i==0)begin:g_first assign tor_lower_w=0;end
  else begin:g_previous assign tor_lower_w={address_i[(i-1)*54+:54],2'b0};end
  wire [53:0] napot_mask_w=address_w^(address_w+54'd1);
  wire [55:0] top_w={address_w,2'b0};
  wire [1:0] mode_w=cfg_w[4:3];
  assign active_o[i]=mode_w!=0&&(mode_w!=1||top_w>tor_lower_w);
  assign lower_o[i*56+:56]=mode_w==1?tor_lower_w:
       (mode_w==3?{address_w&~napot_mask_w,2'b0}:top_w);
  assign upper_o[i*56+:56]=mode_w==1?top_w-56'd1:
       (mode_w==3?{address_w|napot_mask_w,2'b11}:{address_w,2'b11});
  assign permission_o[i*4+:4]={cfg_w[7],cfg_w[2:0]};
  wire unused_reserved_config_w=|cfg_w[6:5];
 end endgenerate
endmodule
