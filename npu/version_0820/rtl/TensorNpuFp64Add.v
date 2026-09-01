`timescale 1ns/1ps

// SPDX-License-Identifier: BSD-3-Clause
//
// 两个非负有限 IEEE binary64 操作数的 RNE 加法 wrapper。
// 合法有限输入产生的 +Inf/OF/NX 是 primitive 结果，不提升为 domain error。
module TensorNpuFp64Add (
    input  wire        clk_i,
    input  wire        rst_i,

    input  wire        req_valid_i,
    output wire        req_ready_o,
    input  wire [63:0] operand_a_i,
    input  wire [63:0] operand_b_i,

    output wire        rsp_valid_o,
    input  wire        rsp_ready_i,
    output wire [63:0] result_o,
    output wire [4:0]  flags_o,
    output wire        error_o
);

    // v1 只接受 raw sign=0 且 finite；因此 -0 也明确非法。
    wire operand_a_is_invalid =
        operand_a_i[63] || (operand_a_i[62:52] == 11'h7ff);
    wire operand_b_is_invalid =
        operand_b_i[63] || (operand_b_i[62:52] == 11'h7ff);
    wire request_domain_error = operand_a_is_invalid || operand_b_is_invalid;

    // 组合数据通路：两路 IEEE F64 -> recF64 -> addRecFN -> IEEE F64。
    // 关键路径经过指数比较、尾数对齐、加法、规格化、RNE 舍入和 decode。
    wire [64:0] operand_a_rec_f64;
    wire [64:0] operand_b_rec_f64;
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

    addRecFN #(
        .expWidth(11),
        .sigWidth(53)
    ) u_add_rec_f64 (
        .control       (1'b1), // tininess after rounding
        .subOp         (1'b0),
        .a             (operand_a_rec_f64),
        .b             (operand_b_rec_f64),
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

    // rsp_valid_reg=0/1 分别对应 EMPTY/FULL；资源不跨 wrapper 共享。
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
            if (request_domain_error) begin
                // 非法符号/NaN/Inf 不得把第三方 payload 提交给上层。
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
