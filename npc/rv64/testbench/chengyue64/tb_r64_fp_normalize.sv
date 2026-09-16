`timescale 1ns/1ps
module tb_r64_fp_normalize;
 reg [63:0] value=0;reg df=0;
 wire [52:0] raw[0:1],normal[0:1];wire signed [13:0] base[0:1],exponent[0:1];
 reg [52:0] general_raw=0;reg signed [13:0] general_base=0;
 wire [52:0] general_sig;wire signed [13:0] general_exp;
 genvar mode;
 generate for(mode=0;mode<2;mode=mode+1)begin:decode
  R64FpDecompose #(.RAW_SPECIAL_NUMERIC(mode)) decompose(.value_i(value),.double_i(df),
   .boxed_o(),.sign_o(),.nan_o(),.snan_o(),.inf_o(),.zero_o(),
   .base_exponent_o(base[mode]),.raw_significand_o(raw[mode]));
  R64FpNormalize #(.IEEE_INPUT(1)) dut(.raw_significand_i(raw[mode]),.base_exponent_i(base[mode]),
   .significand_o(normal[mode]),.exponent_o(exponent[mode]));
 end endgenerate
 R64FpNormalize general(.raw_significand_i(general_raw),.base_exponent_i(general_base),
  .significand_o(general_sig),.exponent_o(general_exp));
 function [66:0] oracle(input [52:0] bits,input signed [13:0] exponent_base);
  integer k,count;reg found;reg signed [13:0] adjusted;
  begin
   found=0;count=0;
   for(k=52;k>=0;k=k-1)if(!found&&bits[k])begin found=1;count=52-k;end
   adjusted=exponent_base-14'(count);oracle={adjusted,bits<<count};
  end
 endfunction
 integer i,j;reg [66:0] expected;
 initial begin
  for(i=0;i<12000;i=i+1)begin
   value={$random,$random};df=i%2;
   case(i%6)
    0:value=64'b1<<((i/6)%52);
    1:value={32'hffffffff,32'b1<<((i/6)%23)};
    2:value=0;
    3:value=64'hffffffff00000000;
    default:begin end
   endcase
   general_raw=53'({$random,$random});general_base=14'($random);
   #1;
   for(j=0;j<2;j=j+1)begin
    if(!raw[j][52]&&base[j]!=-14'sd126&&base[j]!=-14'sd1022)
     $fatal(1,"Decompose IEEE-base contract changed");
    expected=oracle(raw[j],base[j]);
    if({exponent[j],normal[j]}!==expected)$fatal(1,"IEEE exponent/sig mismatch %d/%d",i,j);
   end
   expected=oracle(general_raw,general_base);
   if({general_exp,general_sig}!==expected)$fatal(1,"generic exponent/sig mismatch");
  end
  $display("[R64-FP-NORMALIZE] 24000 IEEE decomposed/boxing/subnormal +12000 arbitrary-base oracle PASS");
  $display("[PASS] tb_r64_fp_normalize");$finish;
 end
endmodule
