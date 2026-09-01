`timescale 1ns/1ps

// SPDX-License-Identifier: BSD-3-Clause
//
// 全 finite IEEE binary64 到 binary32 的 RNE/tininess-after 转换 wrapper。
// Berkeley HardFloat Release 1 负责组合数值路径；本模块拥有 EMPTY/FULL 事务状态。
module TensorNpuFp64ToFp32Finite (
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

    // 合法域包含正负 finite、subnormal 与 signed zero；exponent 全1原子拒绝。
    wire operand_is_special = (operand_i[62:52] == 11'h7ff);

    // 组合拓扑：IEEE F64 -> recF64 -> recF32(RNE/tininess-after) -> IEEE F32。
    // HardFloat control=1 对应 corrected integer-oracle 身份：minimum-normal carry 的
    // UF 由 rounding-after tininess 判定，不允许从最终 F32 exponent field 反推。
    // 关键路径位于 HardFloat 格式缩窄、规格化与舍入；wrapper 不增添算术重构。
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
        .roundingMode  (3'b000),
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

    reg        rsp_valid_reg;
    reg [31:0] result_reg;
    reg [4:0]  flags_reg;
    reg        error_reg;

    assign req_ready_o = !rst_i && !rsp_valid_reg;
    assign rsp_valid_o = !rst_i && rsp_valid_reg;
    assign result_o    = result_reg;
    assign flags_o     = flags_reg;
    assign error_o     = error_reg;

    // 优先级：同步 reset > FULL hold/retire > EMPTY capture。
    // FULL 分支结构性禁止 response retire 与下一 request 同拍接受。
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
            if (operand_is_special) begin
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
