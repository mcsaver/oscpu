`timescale 1ns/1ps
`default_nettype none

// IEEE-754 binary32 raw bits 到 binary16 的 RNE 组合转换器。
//
// finite_o 表示输入不是 NaN/Inf；有限输入舍入成 half Inf 时由
// overflow_o 单独报告。inexact_o 只描述有限输入是否丢弃有效信息。
// NaN 输出保留可表达的高位 payload，并强制 quiet bit，避免产生 half Inf。
//
// 拓扑：class decode -> exponent rebias/subnormal barrel shift -> GRS/sticky
// OR tree -> ties-to-even increment -> carry/pack。无寄存器、FSM 或 handshake。
module TensorNpuFp32ToFp16 (
    input  wire [31:0] fp32_bits_i,
    output reg  [15:0] fp16_bits_o,
    output reg         finite_o,
    output reg         overflow_o,
    output reg         inexact_o
);

    wire        sign_i;
    wire [7:0]  exponent_i;
    wire [22:0] fraction_i;

    reg  [23:0] significand;
    reg  [34:0] extended_significand;
    reg  [10:0] retained_significand;
    reg  [11:0] rounded_significand;
    reg  [9:0]  nan_payload;
    reg          guard_bit;
    reg          sticky_bit;
    reg          round_increment;
    integer      unbiased_exponent;
    integer      half_exponent;
    integer      shift_amount;

    assign sign_i     = fp32_bits_i[31];
    assign exponent_i = fp32_bits_i[30:23];
    assign fraction_i = fp32_bits_i[22:0];

    // 固定 24 次循环综合为门控低位 OR 树，只用于纯组合 sticky 计算。
    function automatic low_bits_nonzero;
        input [23:0] value;
        input integer count;
        integer bit_index;
        begin
            low_bits_nonzero = 1'b0;
            for (bit_index = 0; bit_index < 24; bit_index = bit_index + 1) begin
                if (bit_index < count) begin
                    low_bits_nonzero = low_bits_nonzero | value[bit_index];
                end
            end
        end
    endfunction

    always @(*) begin
        fp16_bits_o            = {sign_i, 15'b0};
        finite_o               = 1'b1;
        overflow_o             = 1'b0;
        inexact_o              = 1'b0;
        significand            = {1'b1, fraction_i};
        extended_significand   = 35'b0;
        retained_significand   = 11'b0;
        rounded_significand    = 12'b0;
        nan_payload            = 10'b0;
        guard_bit              = 1'b0;
        sticky_bit             = 1'b0;
        round_increment        = 1'b0;
        unbiased_exponent      = 0;
        half_exponent          = 0;
        shift_amount           = 0;

        if (exponent_i == 8'hff) begin
            finite_o = 1'b0;
            if (fraction_i == 23'b0) begin
                fp16_bits_o = {sign_i, 5'h1f, 10'b0};
            end else begin
                nan_payload = fraction_i[22:13];
                nan_payload[9] = 1'b1;
                fp16_bits_o = {sign_i, 5'h1f, nan_payload};
            end
        end else if (exponent_i == 8'h00) begin
            if (fraction_i != 23'b0) begin
                // 任意 binary32 subnormal 都远小于 half 最小 subnormal。
                inexact_o = 1'b1;
            end
        end else begin
            unbiased_exponent = $signed({24'b0, exponent_i}) - 32'sd127;
            half_exponent = unbiased_exponent + 15;

            if (half_exponent >= 31) begin
                fp16_bits_o = {sign_i, 5'h1f, 10'b0};
                overflow_o  = 1'b1;
                inexact_o   = 1'b1;
            end else if (half_exponent <= 0) begin
                if (half_exponent < -10) begin
                    // 小于 half 最小 subnormal 的一半，RNE 得 signed zero。
                    fp16_bits_o = {sign_i, 15'b0};
                    inexact_o   = 1'b1;
                end else begin
                    // half subnormal：shift 范围为 14..24。
                    shift_amount = 14 - half_exponent;
                    // Zero extension makes every dynamic 11-bit window legal:
                    // shift_amount is 14..24, so [shift_amount +: 11]
                    // exactly equals the low 11 bits of a logical right shift.
                    extended_significand = {11'b0, significand};
                    retained_significand =
                        extended_significand[shift_amount +: 11];
                    guard_bit = significand[shift_amount - 1];
                    sticky_bit = low_bits_nonzero(significand,
                                                  shift_amount - 1);
                    inexact_o = guard_bit | sticky_bit;
                    round_increment = guard_bit
                                    & (sticky_bit | retained_significand[0]);
                    rounded_significand = {1'b0, retained_significand}
                                         + {{11{1'b0}}, round_increment};

                    if (rounded_significand[10]) begin
                        // 最大 subnormal 的进位成为最小 normal。
                        fp16_bits_o = {sign_i, 5'h01, 10'b0};
                    end else begin
                        fp16_bits_o = {sign_i, 5'h00,
                                       rounded_significand[9:0]};
                    end
                end
            end else begin
                retained_significand = significand[23:13];
                guard_bit = significand[12];
                sticky_bit = |significand[11:0];
                inexact_o = guard_bit | sticky_bit;
                round_increment = guard_bit
                                & (sticky_bit | retained_significand[0]);
                rounded_significand = {1'b0, retained_significand}
                                     + {{11{1'b0}}, round_increment};

                if (rounded_significand[11]) begin
                    half_exponent = half_exponent + 1;
                    if (half_exponent >= 31) begin
                        fp16_bits_o = {sign_i, 5'h1f, 10'b0};
                        overflow_o  = 1'b1;
                    end else begin
                        fp16_bits_o = {sign_i, half_exponent[4:0], 10'b0};
                    end
                end else begin
                    fp16_bits_o = {sign_i, half_exponent[4:0],
                                   rounded_significand[9:0]};
                end
            end
        end
    end

endmodule

`default_nettype wire
