`timescale 1ns/1ps
`default_nettype none

// 全 IEEE binary64 -> binary32 RNE/tininess-after wrapper。
module TensorNpuFp64ToFp32Ieee (
    input  wire        clk_i,
    input  wire        rst_i,
    input  wire        req_valid_i,
    output wire        req_ready_o,
    input  wire [63:0] operand_i,
    output wire        rsp_valid_o,
    input  wire        rsp_ready_i,
    output wire [31:0] result_o,
    output wire [4:0]  flags_o
);

    wire [64:0] operand_rec_w;
    wire [32:0] result_rec_w;
    wire [31:0] result_hf_w;
    wire [4:0]  flags_hf_w;
    wire        result_is_nan_w;
    wire [31:0] result_canonical_w;

    fNToRecFN #(
        .expWidth(11),
        .sigWidth(53)
    ) u_f64_to_rec (
        .in (operand_i),
        .out(operand_rec_w)
    );

    recFNToRecFN #(
        .inExpWidth (11),
        .inSigWidth (53),
        .outExpWidth(8),
        .outSigWidth(24)
    ) u_narrow (
        .control       (1'b1),
        .in            (operand_rec_w),
        .roundingMode  (3'b000),
        .out           (result_rec_w),
        .exceptionFlags(flags_hf_w)
    );

    recFNToFN #(
        .expWidth(8),
        .sigWidth(24)
    ) u_rec_to_f32 (
        .in (result_rec_w),
        .out(result_hf_w)
    );

    assign result_is_nan_w = (result_hf_w[30:23] == 8'hff)
                           && (result_hf_w[22:0] != 23'b0);
    assign result_canonical_w = result_is_nan_w
                              ? 32'h7fc0_0000 : result_hf_w;

    reg        rsp_valid_q;
    reg [31:0] result_q;
    reg [4:0]  flags_q;

    assign req_ready_o = !rst_i && !rsp_valid_q;
    assign rsp_valid_o = !rst_i && rsp_valid_q;
    assign result_o    = result_q;
    assign flags_o     = flags_q;

    always @(posedge clk_i) begin
        if (rst_i) begin
            rsp_valid_q <= 1'b0;
            result_q    <= 32'b0;
            flags_q     <= 5'b0;
        end else if (rsp_valid_q) begin
            if (rsp_ready_i)
                rsp_valid_q <= 1'b0;
        end else if (req_valid_i && req_ready_o) begin
            rsp_valid_q <= 1'b1;
            result_q    <= result_canonical_w;
            flags_q     <= flags_hf_w;
        end
    end

endmodule

`default_nettype wire
