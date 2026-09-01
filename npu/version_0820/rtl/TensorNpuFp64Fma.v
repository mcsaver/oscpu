`timescale 1ns/1ps

// SPDX-License-Identifier: BSD-3-Clause
//
// IEEE binary64 fused multiply-add wrapper：单次 RNE 舍入计算 a*b+c。
// HardFloat 只构成组合数值路径；本模块拥有 EMPTY/FULL 请求/响应事务状态。
module TensorNpuFp64Fma (
    input  wire        clk_i,
    input  wire        rst_i,

    input  wire        req_valid_i,
    output wire        req_ready_o,
    input  wire [63:0] operand_a_i,
    input  wire [63:0] operand_b_i,
    input  wire [63:0] operand_c_i,

    output wire        rsp_valid_o,
    input  wire        rsp_ready_i,
    output wire [63:0] result_o,
    output wire [4:0]  flags_o
);

    // 组合数据通路：三路 IEEE F64 -> recF64 -> fused mul-add -> IEEE F64。
    // 关键路径经过 recode、53x53 乘积、C 对齐/加减、规格化、RNE 舍入和 decode。
    wire [64:0] operand_a_rec_f64;
    wire [64:0] operand_b_rec_f64;
    wire [64:0] operand_c_rec_f64;
    wire [64:0] result_rec_f64;
    wire [63:0] result_hf;
    wire [4:0]  flags_hf;

    fNToRecFN #(
        .expWidth(11),
        .sigWidth(53)
    ) u_f64_a_to_rec (
        .in (operand_a_i),
        .out(operand_a_rec_f64)
    );

    fNToRecFN #(
        .expWidth(11),
        .sigWidth(53)
    ) u_f64_b_to_rec (
        .in (operand_b_i),
        .out(operand_b_rec_f64)
    );

    fNToRecFN #(
        .expWidth(11),
        .sigWidth(53)
    ) u_f64_c_to_rec (
        .in (operand_c_i),
        .out(operand_c_rec_f64)
    );

    mulAddRecFN #(
        .expWidth(11),
        .sigWidth(53)
    ) u_fma_rec_f64 (
        .control       (1'b1),   // tininess after rounding
        .op            (2'b00),  // a*b+c
        .a             (operand_a_rec_f64),
        .b             (operand_b_rec_f64),
        .c             (operand_c_rec_f64),
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

    // rsp_valid_reg=0/1 分别对应 EMPTY/FULL；FULL 时禁止覆盖原子 result/flags。
    reg        rsp_valid_reg;
    reg [63:0] result_reg;
    reg [4:0]  flags_reg;

    assign req_ready_o = !rst_i && !rsp_valid_reg;
    assign rsp_valid_o = !rst_i && rsp_valid_reg;
    assign result_o    = result_reg;
    assign flags_o     = flags_reg;

    // 同步 reset 优先取消 resident response；FULL retire 当拍不接受新 request。
    always @(posedge clk_i) begin
        if (rst_i) begin
            rsp_valid_reg <= 1'b0;
            result_reg    <= 64'b0;
            flags_reg     <= 5'b0;
        end else if (rsp_valid_reg) begin
            if (rsp_ready_i) begin
                rsp_valid_reg <= 1'b0;
            end
        end else if (req_valid_i && req_ready_o) begin
            rsp_valid_reg <= 1'b1;
            result_reg    <= result_hf;
            flags_reg     <= flags_hf;
        end
    end

endmodule
