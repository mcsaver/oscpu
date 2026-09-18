// Shared pure rounding transforms. Range bits:
// [13:0] biased exponent, [27:14] biased+1, [28] tiny-after-round,
// [29] exponent>max, [30] exponent==max, [31] signed14 wrap guard,
// [32] zero significand, [33] rounding chooses infinity on overflow.
module R64FpRoundRange(input sign_i,double_i,input [2:0] rounding_i,
 input signed [13:0] exponent_i,input [55:0] significand_i,
 output [13:0] shift_o,output [33:0] range_o);
 wire signed [13:0] minimum_w=double_i?-14'sd1022:-14'sd126;
 wire signed [13:0] maximum_w=double_i?14'sd1023:14'sd127;
 wire signed [13:0] bias_w=double_i?14'sd1023:14'sd127;
 wire below_w=exponent_i<minimum_w;
 assign shift_o=below_w?minimum_w-exponent_i:14'b0;
 wire pre_guard_w=double_i?significand_i[2]:significand_i[31];
 wire pre_sticky_w=double_i?(|significand_i[1:0]):(|significand_i[30:0]);
 wire pre_lsb_w=double_i?significand_i[3]:significand_i[32];
 wire pre_all_w=double_i?(&significand_i[55:3]):(&significand_i[55:32]);
 wire pre_increment_w=(rounding_i==0&&pre_guard_w&&(pre_sticky_w||pre_lsb_w))||
  (rounding_i==2&&sign_i&&(pre_guard_w||pre_sticky_w))||
  (rounding_i==3&&!sign_i&&(pre_guard_w||pre_sticky_w))||
  (rounding_i==4&&pre_guard_w);
 wire tiny_w=below_w&&!(exponent_i==minimum_w-14'sd1&&pre_all_w&&pre_increment_w);
 wire [13:0] encoded_w=below_w?14'd1:exponent_i+bias_w;
 wire to_infinity_w=rounding_i==0||rounding_i==4||
  (rounding_i==2&&sign_i)||(rounding_i==3&&!sign_i);
 assign range_o={to_infinity_w,significand_i==0,exponent_i==14'sd8191,
  exponent_i==maximum_w,exponent_i>maximum_w,tiny_w,encoded_w+14'd1,encoded_w};
endmodule
module R64FpRoundShift(input [55:0] significand_i,input [13:0] shift_i,output [55:0] shifted_o);
  function [55:0] shift_jam;
    input [55:0] value;input [13:0] distance;
    reg [55:0] shifted;
    begin
      shifted=value;
      if(distance[0])shifted={1'b0,shifted[55:1]}|{55'b0,(|shifted[0:0])};
      if(distance[1])shifted={2'b0,shifted[55:2]}|{55'b0,(|shifted[1:0])};
      if(distance[2])shifted={4'b0,shifted[55:4]}|{55'b0,(|shifted[3:0])};
      if(distance[3])shifted={8'b0,shifted[55:8]}|{55'b0,(|shifted[7:0])};
      if(distance[4])shifted={16'b0,shifted[55:16]}|{55'b0,(|shifted[15:0])};
      if(distance[5])shifted={32'b0,shifted[55:32]}|{55'b0,(|shifted[31:0])};
      shift_jam=(|distance[13:6]) ? {55'b0,|value}:shifted;
    end
  endfunction
 assign shifted_o=shift_jam(significand_i,shift_i);
endmodule
module R64FpRoundDecision(input sign_i,input [2:0] rounding_i,input guard_i,sticky_i,lsb_i,
 output reg increment_o,output inexact_o);
 assign inexact_o=guard_i|sticky_i;
 always @(*)begin
  case(rounding_i)
   0:increment_o=guard_i&&(sticky_i||lsb_i);
   1:increment_o=0;
   2:increment_o=sign_i&&inexact_o;
   3:increment_o=!sign_i&&inexact_o;
   4:increment_o=guard_i;
   default:increment_o=0;
  endcase
 end
endmodule
module R64FpRoundSelect(input sign_i,double_i,input [2:0] rounding_i,
 input [55:0] shifted_i,output [52:0] fraction_o,output increment_o,output inexact_o);
 assign fraction_o=double_i?shifted_i[55:3]:{29'b0,shifted_i[55:32]};
 wire guard_w=double_i?shifted_i[2]:shifted_i[31];
 wire sticky_w=double_i?(|shifted_i[1:0]):(|shifted_i[30:0]);
 R64FpRoundDecision decision(.sign_i(sign_i),.rounding_i(rounding_i),
  .guard_i(guard_w),.sticky_i(sticky_w),.lsb_i(fraction_o[0]),.increment_o(increment_o),.inexact_o(inexact_o));
endmodule
// Select G/R/S positions directly from the unshifted significand. Prefix
// sticky runs in parallel with the fraction barrel shifter, not after it.
module R64FpRoundIndexedDecision(input sign_i,double_i,input [2:0] rounding_i,
 input [55:0] significand_i,input [13:0] shift_i,output increment_o,inexact_o);
 wire [6:0] guard_index_w={1'b0,shift_i[5:0]}+(double_i?7'd2:7'd31);
 wire guard_valid_w=!(|shift_i[13:6])&&guard_index_w<56;
 wire [56:0] prefix_w;
 assign prefix_w[0]=0;
 genvar bit_index;
 generate for(bit_index=1;bit_index<=56;bit_index=bit_index+1)begin:prefix
  assign prefix_w[bit_index]=|significand_i[bit_index-1:0];
 end endgenerate
 wire guard_w=guard_valid_w&&significand_i[guard_index_w[5:0]];
 wire sticky_w=guard_valid_w?prefix_w[guard_index_w[5:0]]:prefix_w[56];
 wire lsb_w=guard_valid_w&&guard_index_w<55?significand_i[guard_index_w[5:0]+6'd1]:1'b0;
 R64FpRoundDecision decision(.sign_i(sign_i),.rounding_i(rounding_i),
  .guard_i(guard_w),.sticky_i(sticky_w),.lsb_i(lsb_w),.increment_o(increment_o),.inexact_o(inexact_o));
endmodule
module R64FpRoundPack(input sign_i,double_i,input [1:0] special_i,input [4:0] flags_i,
 input [33:0] range_i,input inexact_i,input [53:0] rounded_i,
 output reg [63:0] value_o,output reg [4:0] flags_o);
 wire carry_w=double_i?rounded_i[53]:rounded_i[24];
 wire [52:0] mantissa_w=carry_w?rounded_i[53:1]:rounded_i[52:0];
 wire normal_w=double_i?mantissa_w[52]:mantissa_w[23];
 wire [13:0] exponent_w=normal_w?(carry_w?range_i[27:14]:range_i[13:0]):14'b0;
 wire overflow_w=(range_i[29]&&!(range_i[31]&&carry_w))||(range_i[30]&&carry_w);
 always @(*)begin
  flags_o=flags_i;
  value_o=double_i?{sign_i,exponent_w[10:0],mantissa_w[51:0]}:
   {32'hffffffff,sign_i,exponent_w[7:0],mantissa_w[22:0]};
  if(special_i==3)value_o=double_i?64'h7ff8000000000000:64'hffffffff7fc00000;
  else if(special_i==2)value_o=double_i?{sign_i,11'h7ff,52'b0}:{32'hffffffff,sign_i,8'hff,23'b0};
  else if(special_i==1||range_i[32])value_o=double_i?{sign_i,63'b0}:{32'hffffffff,sign_i,31'b0};
  else if(overflow_w)begin
   flags_o=flags_i|5'b00101;
   value_o=double_i?
    (range_i[33]?{sign_i,11'h7ff,52'b0}:{sign_i,11'h7fe,52'hfffffffffffff}):
    (range_i[33]?{32'hffffffff,sign_i,8'hff,23'b0}:{32'hffffffff,sign_i,8'hfe,23'h7fffff});
  end else begin
   flags_o[0]=flags_i[0]|inexact_i;
   flags_o[1]=flags_i[1]|(inexact_i&&range_i[28]);
  end
 end
endmodule
// Five independently enabled numerical stages. The surrounding FMA keeps
// the sole transaction owner: range -> jam/GRS -> local carry -> global carry -> pack.
module R64FpRoundPipe(input clk,input [4:0] enable_i,
 input sign_i,double_i,input [2:0] rounding_i,input signed [13:0] exponent_i,
 input [55:0] significand_i,input [1:0] special_i,input [4:0] flags_i,
 output [63:0] value_o,output [4:0] flags_o);
 wire [13:0] shift_w;wire [33:0] range_w;
 R64FpRoundRange range_calc(.sign_i(sign_i),.double_i(double_i),.rounding_i(rounding_i),
  .exponent_i(exponent_i),.significand_i(significand_i),.shift_o(shift_w),.range_o(range_w));
 reg [55:0] sig0_q;reg [13:0] shift0_q;reg [2:0] rm0_q;
 reg [33:0] range0_q,range1_q,range2_q;
 // {sign,double,special[1:0],flags[4:0]}
 reg [8:0] control0_q,control1_q,control2_q;
 wire [55:0] shifted_w;wire [52:0] fraction_w;wire increment_w,inexact_w;
 R64FpRoundShift shift(.significand_i(sig0_q),.shift_i(shift0_q),.shifted_o(shifted_w));
 R64FpRoundSelect select(.sign_i(control0_q[8]),.double_i(control0_q[7]),.rounding_i(rm0_q),
  .shifted_i(shifted_w),.fraction_o(fraction_w),.increment_o(),.inexact_o());
 R64FpRoundIndexedDecision direct_grs(.sign_i(control0_q[8]),.double_i(control0_q[7]),.rounding_i(rm0_q),
  .significand_i(sig0_q),.shift_i(shift0_q),.increment_o(increment_w),.inexact_o(inexact_w));
 reg [52:0] fraction1_q;reg increment1_q,inexact1_q,inexact2_q;
 wire [53:0] base_w,rounded_w;wire [13:0] propagate_w,generate_w;
 reg [53:0] base2_q;reg [13:0] propagate2_q,generate2_q;
 R64CarryPrepare #(.WIDTH(54),.BLOCK(4)) prepare(.a_i({1'b0,fraction1_q}),.b_i({53'b0,increment1_q}),
  .base_o(base_w),.propagate_o(propagate_w),.generate_o(generate_w));
 R64CarryFinish #(.WIDTH(54),.BLOCK(4)) finish(.base_i(base2_q),.propagate_i(propagate2_q),
  .generate_i(generate2_q),.carry_i(1'b0),.sum_o(rounded_w),.carry_o());
 wire [63:0] value_w;wire [4:0] flags_w;
 reg [53:0] rounded3_q;
 reg [33:0] range3_q;reg [8:0] control3_q;reg inexact3_q;
 reg [63:0] value4_q;reg [4:0] flags4_q;
 R64FpRoundPack pack(.sign_i(control3_q[8]),.double_i(control3_q[7]),.special_i(control3_q[6:5]),
  .flags_i(control3_q[4:0]),.range_i(range3_q),.inexact_i(inexact3_q),.rounded_i(rounded3_q),
  .value_o(value_w),.flags_o(flags_w));
 always @(posedge clk)begin
  if(enable_i[0])begin
   sig0_q<=significand_i;shift0_q<=shift_w;range0_q<=range_w;rm0_q<=rounding_i;
   control0_q<={sign_i,double_i,special_i,flags_i};
  end
  if(enable_i[1])begin
   fraction1_q<=fraction_w;increment1_q<=increment_w;inexact1_q<=inexact_w;
   range1_q<=range0_q;control1_q<=control0_q;
  end
  if(enable_i[2])begin
   base2_q<=base_w;propagate2_q<=propagate_w;generate2_q<=generate_w;
   range2_q<=range1_q;control2_q<=control1_q;inexact2_q<=inexact1_q;
  end
  if(enable_i[3])begin
   rounded3_q<=rounded_w;range3_q<=range2_q;control3_q<=control2_q;inexact3_q<=inexact2_q;
  end
  if(enable_i[4])begin value4_q<=value_w;flags4_q<=flags_w;end
 end
 assign value_o=value4_q;assign flags_o=flags4_q;
endmodule
