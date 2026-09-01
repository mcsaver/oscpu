`timescale 1ns/1ps

// SPDX-License-Identifier: MIT
//
// TensorNpuInt32ToFp32
//
// Requirements:
//   Convert every signed 32-bit integer to IEEE-754 binary32 using
//   round-to-nearest, ties-to-even (RNE), and report discarded information.
// Protocol:
//   This is a stateless, purely combinational block.  fp32_bits_o and
//   inexact_o describe the current int_i without a request/response handshake.
// FSM:
//   None.  There is no retained transaction state.
// Invariants:
//   * zero is encoded as +0;
//   * magnitude formation is valid for INT_MIN;
//   * inexact_o is exactly the OR of all discarded magnitude bits;
//   * every integer with magnitude <= 2^24 is represented exactly.
// Data path / RTL topology:
//   sign + two's-complement magnitude -> leading-one priority encoder ->
//   24-bit retained significand + guard/sticky -> RNE increment -> pack.
// RTL evidence:
//   tests/tb_int32_to_fp32.sv carries raw-bit boundary and tie cases.  Dynamic
//   Dynamic simulation evidence is intentionally produced by the project's
//   functional regression rather than by this combinational source file.

module TensorNpuInt32ToFp32 (
    input  wire signed [31:0] int_i,
    output reg         [31:0] fp32_bits_o,
    output reg                inexact_o
);

    integer bit_index;
    integer msb_index;
    integer shift_amount;

    reg        sign_bit;
    reg [31:0] magnitude;
    reg        found_msb;
    reg [7:0]  biased_exponent;
    reg [23:0] retained_significand;
    reg [24:0] rounded_significand;
    reg        guard_bit;
    reg        sticky_bit;
    reg        round_increment;

    always @(*) begin
        // Complete defaults keep the combinational implementation latch-free.
        fp32_bits_o           = 32'b0;
        inexact_o             = 1'b0;
        sign_bit              = int_i[31];
        magnitude             = int_i[31] ? ((~int_i) + 32'd1) : int_i;
        found_msb             = 1'b0;
        msb_index             = 0;
        shift_amount          = 0;
        biased_exponent       = 8'b0;
        retained_significand  = 24'b0;
        rounded_significand   = 25'b0;
        guard_bit             = 1'b0;
        sticky_bit            = 1'b0;
        round_increment       = 1'b0;

        if (magnitude != 32'b0) begin
            // Fixed 32-bit loop implements a highest-set-bit priority encoder.
            for (bit_index = 31; bit_index >= 0; bit_index = bit_index - 1) begin
                if ((!found_msb) && magnitude[bit_index]) begin
                    found_msb = 1'b1;
                    msb_index = bit_index;
                end
            end

            biased_exponent = 8'd127 + msb_index[7:0];

            if (msb_index <= 23) begin
                // The complete magnitude fits in binary32's 24-bit precision.
                retained_significand = magnitude[23:0]
                                      << (23 - msb_index);
                fp32_bits_o = {
                    sign_bit,
                    biased_exponent,
                    retained_significand[22:0]
                };
            end else begin
                shift_amount = msb_index - 23;
                // The indexed part-select is a fixed-width right-shift mux:
                // shift_amount is in [1,8], so all 24 selected bits are valid.
                retained_significand = magnitude[shift_amount +: 24];
                guard_bit = magnitude[shift_amount - 1];

                // Fixed 32-bit loop implements the discarded-low-bits OR tree.
                sticky_bit = 1'b0;
                for (bit_index = 0; bit_index < 32; bit_index = bit_index + 1) begin
                    if (bit_index < (shift_amount - 1)) begin
                        sticky_bit = sticky_bit | magnitude[bit_index];
                    end
                end

                inexact_o = guard_bit | sticky_bit;
                round_increment = guard_bit
                                & (sticky_bit | retained_significand[0]);
                rounded_significand = {1'b0, retained_significand}
                                    + {{24{1'b0}}, round_increment};

                if (rounded_significand[24]) begin
                    // Rounding 1.111... carries into 10.000...; renormalize.
                    fp32_bits_o = {
                        sign_bit,
                        biased_exponent + 8'd1,
                        rounded_significand[23:1]
                    };
                end else begin
                    fp32_bits_o = {
                        sign_bit,
                        biased_exponent,
                        rounded_significand[22:0]
                    };
                end
            end
        end
    end

endmodule
