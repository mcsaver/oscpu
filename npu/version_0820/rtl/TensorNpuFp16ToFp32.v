`timescale 1ns/1ps
`default_nettype none

// Exact IEEE-754 binary16 raw-bit expansion to binary32.
//
// Requirement/contract:
//   * Preserve the sign, including negative zero and signed Inf/NaN values.
//   * Preserve every NaN payload bit by placing binary16 fraction[9:0] in
//     binary32 fraction[22:13]; no quieting or canonicalization is performed.
//   * Report finite_o for zero/subnormal/normal inputs and zero_o only for
//     either signed zero.
//
// Protocol/FSM:
//   This is a pure combinational raw-bit transform.  There is no clock,
//   handshake, retained state, or FSM.
//
// Datapath/topology:
//   sign/exponent/fraction split -> class decode -> normal exponent bias or
//   subnormal leading-one normalization -> binary32 raw-bit assembly.
module TensorNpuFp16ToFp32 (
    input  wire [15:0] fp16_bits_i,
    output reg  [31:0] fp32_bits_o,
    output reg         finite_o,
    output reg         zero_o
);

    wire        sign_i;
    wire [4:0]  exponent_i;
    wire [9:0]  fraction_i;

    reg  [3:0]  subnormal_msb_index;
    reg         subnormal_msb_found;
    reg  [9:0]  subnormal_remainder;
    reg  [22:0] subnormal_fraction;
    reg  [7:0]  expanded_exponent;
    integer     bit_index;

    assign sign_i     = fp16_bits_i[15];
    assign exponent_i = fp16_bits_i[14:10];
    assign fraction_i = fp16_bits_i[9:0];

    always @(*) begin
        // Complete defaults make every class path combinational and latch-free.
        fp32_bits_o           = 32'b0;
        finite_o              = 1'b1;
        zero_o                = 1'b0;
        subnormal_msb_index   = 4'd0;
        subnormal_msb_found   = 1'b0;
        subnormal_remainder   = 10'b0;
        subnormal_fraction    = 23'b0;
        expanded_exponent     = 8'b0;

        if (exponent_i == 5'b00000) begin
            if (fraction_i == 10'b0) begin
                // Signed zero is the only class that asserts zero_o.
                fp32_bits_o = {sign_i, 31'b0};
                zero_o      = 1'b1;
            end else begin
                // Ten-bit high-to-low priority encoder.  The first set bit is
                // the normalization leading one for the binary16 subnormal.
                for (bit_index = 9; bit_index >= 0; bit_index = bit_index - 1) begin
                    if (!subnormal_msb_found && fraction_i[bit_index]) begin
                        subnormal_msb_index = bit_index[3:0];
                        subnormal_msb_found = 1'b1;
                    end
                end

                // For highest set bit p, unbiased exponent is p-24, hence the
                // binary32 biased exponent is p+103.  Remove that implicit one
                // and align the remaining exact bits below binary32 bit 23.
                expanded_exponent = 8'd103
                                  + {4'b0000, subnormal_msb_index};
                subnormal_remainder = fraction_i;
                subnormal_remainder[subnormal_msb_index] = 1'b0;
                subnormal_fraction = {13'b0, subnormal_remainder}
                                     << (23 - subnormal_msb_index);
                fp32_bits_o = {sign_i, expanded_exponent, subnormal_fraction};
            end
        end else if (exponent_i == 5'b11111) begin
            // Inf and NaN map to exponent 255; payload and sign remain exact.
            fp32_bits_o = {sign_i, 8'hff, fraction_i, 13'b0};
            finite_o    = 1'b0;
        end else begin
            // Normal binary16 exponent bias conversion: 127 - 15 = 112.
            expanded_exponent = {3'b000, exponent_i} + 8'd112;
            fp32_bits_o = {sign_i, expanded_exponent, fraction_i, 13'b0};
        end
    end

endmodule

`default_nettype wire
