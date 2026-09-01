`timescale 1ns/1ps

// SPDX-License-Identifier: BSD-3-Clause
//
// IEEE binary64 到 signed-I32 的 RMM 转换 wrapper。
// HardFloat 负责组合数值路径；本模块拥有唯一的 EMPTY/FULL response holding slot。
module TensorNpuFp64ToInt32Rmm (
    input  wire        clk_i,
    input  wire        rst_i,

    input  wire        req_valid_i,
    output wire        req_ready_o,
    input  wire [63:0] operand_i,

    output wire        rsp_valid_o,
    input  wire        rsp_ready_i,
    output wire [31:0] result_o,
    output wire [2:0]  int_flags_o,
    output wire [4:0]  flags_o
);

    // 组合数据通路：IEEE F64 -> recF64 -> signed I32 (RMM)。
    // 关键路径经过 recode、定点对齐、RMM 舍入和整数范围判定。
    wire [64:0] operand_rec_f64;
    wire [31:0] result_hf;
    wire [2:0]  int_flags_hf;
    wire [4:0]  flags_hf;

    fNToRecFN #(
        .expWidth(11),
        .sigWidth(53)
    ) u_f64_to_rec (
        .in (operand_i),
        .out(operand_rec_f64)
    );

    recFNToIN #(
        .expWidth(11),
        .sigWidth(53),
        .intWidth(32)
    ) u_rec_f64_to_i32 (
        .control          (1'b1),
        .in               (operand_rec_f64),
        .roundingMode     (3'b100), // round-near, ties to maximum magnitude
        .signedOut        (1'b1),
        .out              (result_hf),
        .intExceptionFlags(int_flags_hf)
    );

    // HardFloat integer overflow 是整数转换异常，不是 IEEE floating overflow。
    assign flags_hf = {
        int_flags_hf[2] | int_flags_hf[1],
        3'b000,
        int_flags_hf[0]
    };

    // rsp_valid_reg=0/1 分别对应 EMPTY/FULL；FULL 时 payload 原子保持。
    reg        rsp_valid_reg;
    reg [31:0] result_reg;
    reg [2:0]  int_flags_reg;
    reg [4:0]  flags_reg;

    assign req_ready_o = !rst_i && !rsp_valid_reg;
    assign rsp_valid_o = !rst_i && rsp_valid_reg;
    assign result_o    = result_reg;
    assign int_flags_o = int_flags_reg;
    assign flags_o     = flags_reg;

    // 控制优先级：synchronous reset > FULL retire/hold > EMPTY capture。
    // FULL 分支优先于 capture，从结构上禁止同拍 retire+accept。
    always @(posedge clk_i) begin
        if (rst_i) begin
            rsp_valid_reg <= 1'b0;
            result_reg    <= 32'b0;
            int_flags_reg <= 3'b0;
            flags_reg     <= 5'b0;
        end else if (rsp_valid_reg) begin
            if (rsp_ready_i) begin
                rsp_valid_reg <= 1'b0;
            end
        end else if (req_valid_i && req_ready_o) begin
            rsp_valid_reg <= 1'b1;
            result_reg    <= result_hf;
            int_flags_reg <= int_flags_hf;
            flags_reg     <= flags_hf;
        end
    end

endmodule
