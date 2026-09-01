`timescale 1ns/1ps

// SPDX-License-Identifier: BSD-3-Clause
//
// 完整 signed-I32 到 IEEE binary64 的精确转换 wrapper。
// HardFloat 负责组合数值路径；本模块拥有唯一的 EMPTY/FULL response holding slot。
module TensorNpuInt32ToFp64 (
    input  wire        clk_i,
    input  wire        rst_i,

    input  wire        req_valid_i,
    output wire        req_ready_o,
    input  wire [31:0] operand_i,

    output wire        rsp_valid_o,
    input  wire        rsp_ready_i,
    output wire [63:0] result_o,
    output wire [4:0]  flags_o
);

    // 组合数据通路：signed I32 -> recF64 -> IEEE F64。
    // 关键路径经过符号幅值归一化、RMM rounding shell 和 recFN decode；
    // binary64 的 53-bit significand 可精确容纳全部 signed-I32 输入。
    wire [64:0] result_rec_f64;
    wire [63:0] result_hf;
    wire [4:0]  flags_hf;

    iNToRecFN #(
        .intWidth(32),
        .expWidth(11),
        .sigWidth(53)
    ) u_i32_to_rec_f64 (
        .control       (1'b1),
        .signedIn      (1'b1),
        .in            (operand_i),
        .roundingMode  (3'b100), // fixed RMM; exact I32 inputs never round
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

    // rsp_valid_reg=0/1 分别对应 EMPTY/FULL；FULL 时 payload 原子保持。
    reg        rsp_valid_reg;
    reg [63:0] result_reg;
    reg [4:0]  flags_reg;

    assign req_ready_o = !rst_i && !rsp_valid_reg;
    assign rsp_valid_o = !rst_i && rsp_valid_reg;
    assign result_o    = result_reg;
    assign flags_o     = flags_reg;

    // 控制优先级：synchronous reset > FULL retire/hold > EMPTY capture。
    // FULL 分支优先于 capture，从结构上禁止同拍 retire+accept。
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
