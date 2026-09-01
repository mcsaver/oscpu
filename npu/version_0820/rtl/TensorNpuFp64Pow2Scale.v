`timescale 1ns/1ps

// Power-of-two binary64 scaler for the RMS ordered-square-sum provenance.
// The accepted nonzero domain is deliberately narrower than generic IEEE-754:
// only positive normal sums described by NORM_RTL_CONTRACT.md are admitted.
module TensorNpuFp64Pow2Scale (
    input  wire        clk_i,
    input  wire        rst_i,

    input  wire        req_valid_i,
    output wire        req_ready_o,
    input  wire [63:0] req_sum_i,
    input  wire [10:0] req_d_i,

    output reg         rsp_valid_o,
    input  wire        rsp_ready_i,
    output reg  [63:0] rsp_result_o,
    output wire [4:0]  rsp_flags_o,
    output reg         rsp_error_o
);

    reg        d_supported;
    reg [10:0] scale_k;
    reg [10:0] scaled_exp;
    reg [63:0] classified_result;
    reg        classified_error;

    // A held response is the only outstanding transaction.  Requests that
    // arrive while it is held receive no credit and cannot overwrite payload.
    assign req_ready_o = !rst_i && !rsp_valid_o;

    // Dividing an accepted normal binary64 value by 2^k is exact: no rounding
    // boundary is crossed and the fraction field is preserved bit-for-bit.
    assign rsp_flags_o = 5'b00000;

    // D decode, domain classification, and the sole exponent subtractor.
    // There is intentionally no divider or iterative arithmetic state here.
    always @(*) begin
        d_supported      = 1'b1;
        scale_k          = 11'd0;
        scaled_exp       = 11'd0;
        classified_result = 64'h0000_0000_0000_0000;
        classified_error  = 1'b1;

        case (req_d_i)
            11'd128:  scale_k = 11'd7;
            11'd256:  scale_k = 11'd8;
            11'd1024: scale_k = 11'd10;
            default: begin
                d_supported = 1'b0;
                scale_k     = 11'd0;
            end
        endcase

        if (d_supported) begin
            // Positive zero bypasses exponent classification and remains +0.
            if (req_sum_i == 64'h0000_0000_0000_0000) begin
                classified_result = 64'h0000_0000_0000_0000;
                classified_error  = 1'b0;
            end else if ((req_sum_i[63] == 1'b0) &&
                         (req_sum_i[62:52] >= 11'h36A) &&
                         (req_sum_i[62:52] <= 11'h488) &&
                         (req_sum_i[62:52] > scale_k)) begin
                scaled_exp        = req_sum_i[62:52] - scale_k;
                classified_result = {1'b0, scaled_exp, req_sum_i[51:0]};
                classified_error  = 1'b0;
            end
        end
    end

    // EMPTY/HELD state machine.  Reset has highest priority and atomically
    // cancels a resident response, preventing any post-reset stale completion.
    always @(posedge clk_i) begin
        if (rst_i) begin
            rsp_valid_o  <= 1'b0;
            rsp_result_o <= 64'h0000_0000_0000_0000;
            rsp_error_o  <= 1'b0;
        end else if (rsp_valid_o) begin
            if (rsp_ready_i) begin
                rsp_valid_o  <= 1'b0;
                rsp_result_o <= 64'h0000_0000_0000_0000;
                rsp_error_o  <= 1'b0;
            end
        end else if (req_valid_i) begin
            rsp_valid_o  <= 1'b1;
            rsp_result_o <= classified_result;
            rsp_error_o  <= classified_error;
        end
    end

endmodule
