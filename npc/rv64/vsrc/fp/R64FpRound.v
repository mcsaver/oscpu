// Combinational composition of the same transforms used by the FMA pipeline.
// Other FP engines retain their existing interfaces and cycle boundaries.
module R64FpRound(input sign_i,double_i,input [2:0] rounding_i,
 input signed [13:0] exponent_i,input [55:0] significand_i,
 input [1:0] special_i,input [4:0] flags_i,
 output [63:0] value_o,output [4:0] flags_o);
 wire [13:0] shift_w;wire [33:0] range_w;
 wire [55:0] shifted_w;wire [52:0] fraction_w;
 wire increment_w,inexact_w;
 wire [53:0] rounded_w={1'b0,fraction_w}+{53'b0,increment_w};
 R64FpRoundRange range_calc(.sign_i(sign_i),.double_i(double_i),.rounding_i(rounding_i),
  .exponent_i(exponent_i),.significand_i(significand_i),.shift_o(shift_w),.range_o(range_w));
 R64FpRoundShift shift(.significand_i(significand_i),.shift_i(shift_w),.shifted_o(shifted_w));
 R64FpRoundSelect select(.sign_i(sign_i),.double_i(double_i),.rounding_i(rounding_i),
  .shifted_i(shifted_w),.fraction_o(fraction_w),.increment_o(increment_w),.inexact_o(inexact_w));
 R64FpRoundPack pack(.sign_i(sign_i),.double_i(double_i),.special_i(special_i),.flags_i(flags_i),
  .range_i(range_w),.inexact_i(inexact_w),.rounded_i(rounded_w),.value_o(value_o),.flags_o(flags_o));
endmodule
