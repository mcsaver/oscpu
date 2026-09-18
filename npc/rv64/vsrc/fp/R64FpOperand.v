// Format/boxing classification is separated from subnormal normalization.
// The FMA owner registers this compact form; other users compose both steps.
module R64FpDecompose #(parameter RAW_SPECIAL_NUMERIC=0)(
  input [63:0] value_i,input double_i,
  output [63:0] boxed_o,output sign_o,
  output nan_o,snan_o,inf_o,zero_o,
  output signed [13:0] base_exponent_o,output [52:0] raw_significand_o
);
  wire invalid_box_w=!double_i&&value_i[63:32]!=32'hffffffff;
  wire [31:0] single_w=invalid_box_w ? 32'h7fc00000:value_i[31:0];
  // FMA special values are resolved by class metadata, so its purely
  // numerical path need not broadcast the boxing predicate over 53 bits.
  // Other users retain canonical special numerical fields by default.
  wire [31:0] numerical_single_w=RAW_SPECIAL_NUMERIC?value_i[31:0]:single_w;
  assign boxed_o=double_i ? value_i:{32'hffffffff,single_w};
  wire [10:0] exp_w=double_i ? value_i[62:52]:{3'b0,numerical_single_w[30:23]};
  wire [51:0] fraction_w=double_i ? value_i[51:0]:{numerical_single_w[22:0],29'b0};
  // Per-format classification precedes the final format select. Numerical
  // boxing and special-result policy remain independent consumers.
  wire double_ones_w=&value_i[62:52],single_ones_w=&value_i[30:23];
  wire double_fraction_w=|value_i[51:0],single_fraction_w=|value_i[22:0];
  wire double_nan_w=double_ones_w&&double_fraction_w;
  wire single_nan_w=single_ones_w&&single_fraction_w;
  assign sign_o=double_i ? value_i[63]:single_w[31];
  assign nan_o=invalid_box_w||(double_i?double_nan_w:single_nan_w);
  assign snan_o=!invalid_box_w&&(double_i?
   double_nan_w&&!value_i[51]:single_nan_w&&!value_i[22]);
  assign inf_o=!invalid_box_w&&(double_i?
   double_ones_w&&!double_fraction_w:single_ones_w&&!single_fraction_w);
  assign zero_o=!invalid_box_w&&(double_i?value_i[62:0]==0:value_i[30:0]==0);
  wire [52:0] raw_sig_w={exp_w!=0,fraction_w};
  // Each format converts its fixed-width exponent in parallel. Format
  // selection is the final mux, not the start of a shared subtract chain.
  wire signed [11:0] double_base_w=value_i[62:52]==0 ? -12'sd1022:
   $signed({1'b0,value_i[62:52]})-12'sd1023;
  wire signed [8:0] single_base_w=numerical_single_w[30:23]==0 ? -9'sd126:
   $signed({1'b0,numerical_single_w[30:23]})-9'sd127;
  assign base_exponent_o=double_i ? {{2{double_base_w[11]}},double_base_w}:
   {{5{single_base_w[8]}},single_base_w};
  assign raw_significand_o=raw_sig_w;
endmodule

module R64FpNormalize #(parameter IEEE_INPUT=0)(
  input [52:0] raw_significand_i,input signed [13:0] base_exponent_i,
  output [52:0] significand_o,output signed [13:0] exponent_o
);
  wire [63:0] scan_w={raw_significand_i,11'b0};
  wire [7:0] nonzero_w,select_w;
  wire [5:0] count_part_w[0:7];
  wire [63:0] coarse_part_w[0:7];
  function [2:0] leading8;
    input [7:0] value;
    begin
      casez(value)
        8'b1???????:leading8=0;
        8'b01??????:leading8=1;
        8'b001?????:leading8=2;
        8'b0001????:leading8=3;
        8'b00001???:leading8=4;
        8'b000001??:leading8=5;
        8'b0000001?:leading8=6;
        default:leading8=7;
      endcase
    end
  endfunction
  genvar byte_index;
  generate for(byte_index=0;byte_index<8;byte_index=byte_index+1)begin:byte_lead
    wire [7:0] byte_w=scan_w[(7-byte_index)*8+:8];
    assign nonzero_w[byte_index]=|byte_w;
    if(byte_index==0)assign select_w[byte_index]=nonzero_w[byte_index];
    else assign select_w[byte_index]=nonzero_w[byte_index]&&!(|nonzero_w[byte_index-1:0]);
    assign count_part_w[byte_index]={6{select_w[byte_index]}}&{3'(byte_index),leading8(byte_w)};
    assign coarse_part_w[byte_index]={64{select_w[byte_index]}}&(scan_w<<(byte_index*8));
  end endgenerate
  wire [5:0] count_w=(count_part_w[0]|count_part_w[1])|(count_part_w[2]|count_part_w[3])|
    (count_part_w[4]|count_part_w[5])|(count_part_w[6]|count_part_w[7]);
  wire [63:0] coarse_w=(coarse_part_w[0]|coarse_part_w[1])|(coarse_part_w[2]|coarse_part_w[3])|
    (coarse_part_w[4]|coarse_part_w[5])|(coarse_part_w[6]|coarse_part_w[7]);
  wire [63:0] aligned_w=coarse_w<<count_w[2:0];
  wire [58:0] normalized_w={count_w,aligned_w[63:11]};
  generate if(IEEE_INPUT)begin:ieee_exponent
    // R64FpDecompose sets hidden=1 for every nonzero exponent. Otherwise
    // base is -126 or -1022, both congruent to 2 modulo 64. The upper
    // exponent borrow is therefore known directly from the raw leading
    // bits, in parallel with the low six-bit normalization count.
    wire borrow_w=(|raw_significand_i)&&!(|raw_significand_i[52:50]);
    wire [7:0] upper_w=borrow_w?base_exponent_i[13:6]-8'd1:base_exponent_i[13:6];
    wire [5:0] low_w=6'd2-normalized_w[58:53];
    assign exponent_o=raw_significand_i[52]?base_exponent_i:{upper_w,low_w};
  end else begin:general_exponent
    assign exponent_o=base_exponent_i-$signed({8'b0,normalized_w[58:53]});
  end endgenerate
  assign significand_o=normalized_w[52:0];
endmodule
