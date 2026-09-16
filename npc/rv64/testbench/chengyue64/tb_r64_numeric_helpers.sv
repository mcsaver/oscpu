`timescale 1ns/1ps
module tb_r64_numeric_helpers;
  reg [127:0] a=0,b=0;
  reg cin=0;
  wire [127:0] sum128;
  wire [105:0] sum106;
  wire [65:0] sum66;
  wire [63:0] sum64;
  wire co128,co106,co66,co64;
  wire [79:0] ts64,tc64;
  wire [68:0] ts53,tc53;
  wire [57:0] ts5,tc5;
  reg [1023:0] rows=0;
  wire [127:0] rs,rc;
  reg [128:0] golden;
  reg [127:0] total;
  integer i,j;
  wire [4:0] carry_ok_w;
  genvar h;
  generate for(h=0;h<5;h=h+1)begin:carry_boundary
    localparam W=h==0?53:h==1?64:h==2?66:h==3?106:128;
    localparam G=(W+7)/8;
    wire [W-1:0] base_w,sum_w;
    wire [G-1:0] p_w,g_w;
    wire c_w;
    R64CarryPrepare #(.WIDTH(W)) prepare(.a_i(a[W-1:0]),.b_i(b[W-1:0]),.base_o(base_w),
      .propagate_o(p_w),.generate_o(g_w));
    R64CarryFinish #(.WIDTH(W)) finish(.base_i(base_w),.propagate_i(p_w),.generate_i(g_w),
      .carry_i(cin),.sum_o(sum_w),.carry_o(c_w));
    assign carry_ok_w[h]={c_w,sum_w}==({1'b0,a[W-1:0]}+{1'b0,b[W-1:0]}+cin);
  end endgenerate
  R64WideAdd #(.WIDTH(128)) a128(.a_i(a),.b_i(b),.carry_i(cin),.sum_o(sum128),.carry_o(co128));
  R64WideAdd #(.WIDTH(106)) a106(.a_i(a[105:0]),.b_i(b[105:0]),.carry_i(cin),.sum_o(sum106),.carry_o(co106));
  R64WideAdd #(.WIDTH(66)) a66(.a_i(a[65:0]),.b_i(b[65:0]),.carry_i(cin),.sum_o(sum66),.carry_o(co66));
  R64WideAdd #(.WIDTH(64)) a64(.a_i(a[63:0]),.b_i(b[63:0]),.carry_i(cin),.sum_o(sum64),.carry_o(co64));
  R64ProductTree #(.WIDTH(64),.BWIDTH(16)) t64(.a_i(a[63:0]),.b_i(b[15:0]),.sum_o(ts64),.carry_o(tc64));
  R64ProductTree #(.WIDTH(53),.BWIDTH(16)) t53(.a_i(a[52:0]),.b_i(b[15:0]),.sum_o(ts53),.carry_o(tc53));
  R64ProductTree #(.WIDTH(53),.BWIDTH(5)) t5(.a_i(a[52:0]),.b_i(b[4:0]),.sum_o(ts5),.carry_o(tc5));
  R64CsaReduce #(.WIDTH(128),.ROWS(8)) merge(.rows_i(rows),.sum_o(rs),.carry_o(rc));
  initial begin
    for(i=0;i<5000;i=i+1)begin
      a={$random,$random,$random,$random};b={$random,$random,$random,$random};cin=i[0];
      if(i<256)begin a=(128'b1<<(i/2))-1'b1;b=0;cin=1;end
      if(i>=256&&i<512)begin a=-128'd1;b=128'b1<<((i-256)/2);end
      if(i>=512&&i<768)b=~a;
      for(j=0;j<8;j=j+1)rows[j*128+:128]={$random,$random,$random,$random};
      #1;
      if(!(&carry_ok_w))$fatal(1,"two-boundary carry vector %0d",i);
      golden={1'b0,a}+{1'b0,b}+cin;
      if({co128,sum128}!==golden)$fatal(1,"128-bit prefix carry vector %0d",i);
      golden={23'b0,a[105:0]}+{23'b0,b[105:0]}+cin;
      if({co106,sum106}!==golden[106:0])$fatal(1,"106-bit partial group carry vector %0d",i);
      golden={63'b0,a[65:0]}+{63'b0,b[65:0]}+cin;
      if({co66,sum66}!==golden[66:0])$fatal(1,"66-bit partial group carry vector %0d",i);
      golden={65'b0,a[63:0]}+{65'b0,b[63:0]}+cin;
      if({co64,sum64}!==golden[64:0])$fatal(1,"64-bit prefix carry vector %0d",i);
      if((ts64+tc64)!==(80'(a[63:0])*80'(b[15:0])))$fatal(1,"64x16 tile vector %0d",i);
      if((ts53+tc53)!==(69'(a[52:0])*69'(b[15:0])))$fatal(1,"53x16 tile vector %0d",i);
      if((ts5+tc5)!==(58'(a[52:0])*58'(b[4:0])))$fatal(1,"53x5 tile vector %0d",i);
      total=0;for(j=0;j<8;j=j+1)total=total+rows[j*128+:128];
      if(rs+rc!==total)$fatal(1,"8-row complete modular sum vector %0d",i);
    end
    $display("[R64-NUMERIC-HELPERS] vectors=5000 widths=64/66/106/128 carry/borrow/tile/overflow PASS");
    $display("[PASS] tb_r64_numeric_helpers");$finish;
  end
endmodule
