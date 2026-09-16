// Combinational public F/D unpack interface. The decomposition and
// normalization functions are also used at distinct FMA pipeline boundaries.
module R64FpUnpack(
  input [63:0] value_i,input double_i,
  output [63:0] boxed_o,output sign_o,
  output nan_o,snan_o,inf_o,zero_o,
  output signed [13:0] exponent_o,output [52:0] significand_o
);
  wire [52:0] raw_w;
  wire signed [13:0] base_w;
  R64FpDecompose decompose(.value_i(value_i),.double_i(double_i),.boxed_o(boxed_o),
    .sign_o(sign_o),.nan_o(nan_o),.snan_o(snan_o),.inf_o(inf_o),.zero_o(zero_o),
    .base_exponent_o(base_w),.raw_significand_o(raw_w));
  R64FpNormalize #(.IEEE_INPUT(1)) normalize(.raw_significand_i(raw_w),.base_exponent_i(base_w),
    .significand_o(significand_o),.exponent_o(exponent_o));
endmodule
