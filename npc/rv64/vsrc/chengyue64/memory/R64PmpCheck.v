// Parallel range checks followed by a lowest-overlap one-hot selection.
// Partial overlap fails even for unlocked M-mode accesses, as required by PMP.
// Access bits are {execute, write, read}; zero disables the query.
module R64PmpCheck(
 input [63:0] address_i,input [4:0] size_i,input [1:0] privilege_i,input [2:0] access_i,
 input [15:0] active_i,input [895:0] lower_i,upper_i,input [63:0] permission_i,
 output fault_o
);
 wire [64:0] last_w={1'b0,address_i}+{60'b0,size_i}-65'd1;
 wire [15:0] overlap_w,denied_w;
 genvar i;
 generate for(i=0;i<16;i=i+1)begin:g_check
  wire [63:0] lo_w={8'b0,lower_i[i*56+:56]},hi_w={8'b0,upper_i[i*56+:56]};
  wire [3:0] permission_w=permission_i[i*4+:4];
  wire selected_w;
  assign overlap_w[i]=active_i[i]&&address_i<=hi_w&&last_w[63:0]>=lo_w;
  if(i==0)begin:g_first assign selected_w=overlap_w[i];end
  else begin:g_previous assign selected_w=overlap_w[i]&&!(|overlap_w[i-1:0]);end
  wire partial_w=address_i<lo_w||last_w[63:0]>hi_w;
  wire mode_enforces_w=privilege_i!=3||permission_w[3];
  assign denied_w[i]=selected_w&&(partial_w||(mode_enforces_w&&
      (|(access_i&~permission_w[2:0]))));
 end endgenerate
 assign fault_o=(|access_i)&&(size_i==0||last_w[64]||(|denied_w)||
      (!(|overlap_w)&&privilege_i!=3));
endmodule
