`timescale 1ns/1ps

// SPDX-License-Identifier: BSD-3-Clause
//
// 非负有限 IEEE binary64 到 binary32 的 RNE/tininess-after 转换 wrapper。
// overflow、underflow 和 inexact 由 HardFloat flags 原样报告。
module TensorNpuFp64ToFp32 (
    input  wire        clk_i,
    input  wire        rst_i,

    input  wire        req_valid_i,
    output wire        req_ready_o,
    input  wire [63:0] operand_i,

    output wire        rsp_valid_o,
    input  wire        rsp_ready_i,
    output wire [31:0] result_o,
    output wire [4:0]  flags_o,
    output wire        error_o
);

    // v1 只接受 sign=0 且 finite；-0、负数、NaN 与 Inf 均非法。
    wire operand_is_invalid =
        operand_i[63] || (operand_i[62:52] == 11'h7ff);

    // 组合数据通路：IEEE F64 -> recF64 -> recF32 -> IEEE F32。
    // 关键路径经过格式缩窄、RNE/tininess-after 判定和 decode。
    wire [64:0] operand_rec_f64;
    wire [32:0] result_rec_f32;
    wire [31:0] result_hf;
    wire [4:0]  flags_hf;

    fNToRecFN #(
        .expWidth(11),
        .sigWidth(53)
    ) u_f64_to_rec (
        .in (operand_i),
        .out(operand_rec_f64)
    );

    recFNToRecFN #(
        .inExpWidth (11),
        .inSigWidth (53),
        .outExpWidth(8),
        .outSigWidth(24)
    ) u_rec_f64_to_rec_f32 (
        .control       (1'b1), // tininess after rounding
        .in            (operand_rec_f64),
        .roundingMode  (3'b000), // round-near-even
        .out           (result_rec_f32),
        .exceptionFlags(flags_hf)
    );

    recFNToFN #(
        .expWidth(8),
        .sigWidth(24)
    ) u_rec_f32_to_f32 (
        .in (result_rec_f32),
        .out(result_hf)
    );

    // rsp_valid_reg=0/1 分别对应 EMPTY/FULL；FULL 时 payload 保持。
    reg        rsp_valid_reg;
    reg [31:0] result_reg;
    reg [4:0]  flags_reg;
    reg        error_reg;

    assign req_ready_o = !rst_i && !rsp_valid_reg;
    assign rsp_valid_o = !rst_i && rsp_valid_reg;
    assign result_o    = result_reg;
    assign flags_o     = flags_reg;
    assign error_o     = error_reg;

    always @(posedge clk_i) begin
        if (rst_i) begin
            rsp_valid_reg <= 1'b0;
            result_reg    <= 32'b0;
            flags_reg     <= 5'b0;
            error_reg     <= 1'b0;
        end else if (rsp_valid_reg) begin
            if (rsp_ready_i) begin
                rsp_valid_reg <= 1'b0;
            end
        end else if (req_valid_i && req_ready_o) begin
            rsp_valid_reg <= 1'b1;
            if (operand_is_invalid) begin
                // 非法域 response 固定清零，原子阻断第三方特殊值 payload。
                result_reg <= 32'b0;
                flags_reg  <= 5'b0;
                error_reg  <= 1'b1;
            end else begin
                result_reg <= result_hf;
                flags_reg  <= flags_hf;
                error_reg  <= 1'b0;
            end
        end
    end

endmodule
