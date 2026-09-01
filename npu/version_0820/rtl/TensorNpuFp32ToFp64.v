`timescale 1ns/1ps

// SPDX-License-Identifier: BSD-3-Clause
//
// 有限 IEEE binary32 到 binary64 的精确转换 wrapper。
// HardFloat 只负责组合数值路径；本模块拥有请求/响应事务状态。
module TensorNpuFp32ToFp64 (
    input  wire        clk_i,
    input  wire        rst_i,

    input  wire        req_valid_i,
    output wire        req_ready_o,
    input  wire [31:0] operand_i,

    output wire        rsp_valid_o,
    input  wire        rsp_ready_i,
    output wire [63:0] result_o,
    output wire [4:0]  flags_o,
    output wire        error_o
);

    // 只有 IEEE exponent 全 1 属于 v1 非法域；负数、subnormal 和 -0 均合法。
    wire operand_is_special = (operand_i[30:23] == 8'hff);

    // 组合数据通路：IEEE F32 -> recF32 -> recF64 -> IEEE F64。
    // 关键路径位于 recode、格式扩展和 decode；扩展本身必须精确。
    wire [32:0] operand_rec_f32;
    wire [64:0] result_rec_f64;
    wire [63:0] result_hf;
    wire [4:0]  flags_hf;

    fNToRecFN #(
        .expWidth(8),
        .sigWidth(24)
    ) u_f32_to_rec (
        .in (operand_i),
        .out(operand_rec_f32)
    );

    recFNToRecFN #(
        .inExpWidth (8),
        .inSigWidth (24),
        .outExpWidth(11),
        .outSigWidth(53)
    ) u_rec_f32_to_rec_f64 (
        .control       (1'b1), // tininess after rounding
        .in            (operand_rec_f32),
        .roundingMode  (3'b000), // round-near-even
        .out           (result_rec_f64),
        .exceptionFlags(flags_hf)
    );

    recFNToFN #(
        .expWidth(11),
        .sigWidth(53)
    ) u_rec_f64_to_f64 (
        .in (result_rec_f64),
        .out(result_hf)
    );

    // rsp_valid_reg=0/1 分别对应 EMPTY/FULL；FULL 期间禁止覆盖 payload。
    reg        rsp_valid_reg;
    reg [63:0] result_reg;
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
            result_reg    <= 64'b0;
            flags_reg     <= 5'b0;
            error_reg     <= 1'b0;
        end else if (rsp_valid_reg) begin
            if (rsp_ready_i) begin
                rsp_valid_reg <= 1'b0;
            end
        end else if (req_valid_i && req_ready_o) begin
            rsp_valid_reg <= 1'b1;
            if (operand_is_special) begin
                // 非法域原子 fail-closed：不提交 HardFloat NaN/Inf payload。
                result_reg <= 64'b0;
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
