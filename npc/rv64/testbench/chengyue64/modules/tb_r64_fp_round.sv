`timescale 1ns/1ps
module tb_r64_fp_round;
  reg [63:0] a;
  reg src_double,dst_double;
  reg [2:0] rm;
  wire sign,nan,snan,inf,zero;
  wire signed [13:0] exp;
  wire [52:0] sig;
  wire [63:0] result;
  wire [4:0] flags;
  integer file,status,n,sf,df,mode;
  reg [63:0] expected;
  reg [4:0] expected_flags;
  reg [1023:0] path;
  R64FpUnpack unpack(.value_i(a),.double_i(src_double),.boxed_o(),
    .sign_o(sign),.nan_o(nan),.snan_o(snan),.inf_o(inf),.zero_o(zero),
    .exponent_o(exp),.significand_o(sig));
  R64FpRound round(.sign_i(sign),.double_i(dst_double),.rounding_i(rm),
    .exponent_i(exp),.significand_i({sig,3'b0}),
    .special_i(nan ? 2'd3:inf ? 2'd2:zero ? 2'd1:2'd0),.flags_i({snan,4'b0}),
    .value_o(result),.flags_o(flags));
  initial begin
    if(!$value$plusargs("vectors=%s",path))path="fp-round-vectors.txt";
    file=$fopen(path,"r");if(!file)$fatal(1,"missing SoftFloat oracle vectors");n=0;
    while(!$feof(file))begin
      status=$fscanf(file,"%d %d %d %h %h %h\n",sf,df,mode,a,expected,expected_flags);
      if(status==6)begin
        src_double=sf;dst_double=df;rm=mode;#1;
        if(result!==expected||flags!==expected_flags)
          $fatal(1,"round vector=%0d src=%0d dst=%0d rm=%0d a=%h exp=%0d sig=%h got=%h/%h expected=%h/%h",
            n,sf,df,mode,a,exp,sig,result,flags,expected,expected_flags);
        n=n+1;
      end else if(!$feof(file))$fatal(1,"malformed SoftFloat vector");
    end
    if(n!=40000)$fatal(1,"oracle workload truncated");
    $display("[R64-FP-ROUND] SoftFloat RISCV vectors=%0d mixed S/D all-rounding boxing/subnormal/flags PASS",n);
    $display("[PASS] tb_r64_fp_round");$finish;
  end
endmodule
