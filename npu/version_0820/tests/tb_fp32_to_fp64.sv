`timescale 1ns/1ps

module tb_fp32_to_fp64;

    logic        clk_i;
    logic        rst_i;
    logic        req_valid_i;
    wire         req_ready_o;
    logic [31:0] operand_i;
    wire         rsp_valid_o;
    logic        rsp_ready_i;
    wire [63:0]  result_o;
    wire [4:0]   flags_o;
    wire         error_o;

    TensorNpuFp32ToFp64 dut (
        .clk_i      (clk_i),
        .rst_i      (rst_i),
        .req_valid_i(req_valid_i),
        .req_ready_o(req_ready_o),
        .operand_i  (operand_i),
        .rsp_valid_o(rsp_valid_o),
        .rsp_ready_i(rsp_ready_i),
        .result_o   (result_o),
        .flags_o    (flags_o),
        .error_o    (error_o)
    );

    initial clk_i = 1'b0;
    always #5 clk_i <= ~clk_i;

    task automatic check_response(
        input logic [31:0] request_bits,
        input logic [63:0] expected_result,
        input logic [4:0]  expected_flags,
        input logic        expected_error,
        input logic        exercise_hold_and_busy
    );
        logic [63:0] held_result;
        logic [4:0]  held_flags;
        logic        held_error;
        begin
            @(negedge clk_i);
            if (req_ready_o !== 1'b1 || rsp_valid_o !== 1'b0) begin
                $fatal(1, "F32->F64 request slot not EMPTY before request");
            end
            operand_i   = request_bits;
            req_valid_i = 1'b1;
            rsp_ready_i = 1'b0;

            // request fire；registered response 必须在随后的事务周期可见。
            @(posedge clk_i);
            #1;
            req_valid_i = 1'b0;
            if (rsp_valid_o !== 1'b1 || req_ready_o !== 1'b0) begin
                $fatal(1, "F32->F64 response timing/occupancy mismatch input=%h", request_bits);
            end
            if (result_o !== expected_result || flags_o !== expected_flags ||
                error_o !== expected_error) begin
                $fatal(1,
                    "F32->F64 mismatch input=%h got=%h/%h err=%b expected=%h/%h err=%b",
                    request_bits, result_o, flags_o, error_o,
                    expected_result, expected_flags, expected_error);
            end

            if (exercise_hold_and_busy) begin
                held_result = result_o;
                held_flags  = flags_o;
                held_error  = error_o;
                @(negedge clk_i);
                // FULL 时持续给出另一 request；req_ready 必须拒绝且 payload 不得覆盖。
                operand_i   = 32'h7f7fffff;
                req_valid_i = 1'b1;
                repeat (2) begin
                    @(posedge clk_i);
                    #1;
                    if (req_ready_o !== 1'b0 || rsp_valid_o !== 1'b1 ||
                        result_o !== held_result || flags_o !== held_flags ||
                        error_o !== held_error) begin
                        $fatal(1, "F32->F64 held response changed under backpressure/busy request");
                    end
                end
                @(negedge clk_i);
                req_valid_i = 1'b0;
                operand_i   = 32'b0;
            end

            @(negedge clk_i);
            rsp_ready_i = 1'b1;
            @(posedge clk_i);
            #1;
            if (rsp_valid_o !== 1'b0) begin
                $fatal(1, "F32->F64 response did not retire on handshake");
            end
            @(negedge clk_i);
            rsp_ready_i = 1'b0;
        end
    endtask

    task automatic check_inflight_reset;
        begin
            @(negedge clk_i);
            operand_i   = 32'h3f800000;
            req_valid_i = 1'b1;
            rsp_ready_i = 1'b0;
            @(posedge clk_i);
            #1;
            req_valid_i = 1'b0;
            if (rsp_valid_o !== 1'b1) begin
                $fatal(1, "F32->F64 reset probe request was not accepted");
            end

            @(negedge clk_i);
            rst_i = 1'b1;
            #1;
            if (req_ready_o !== 1'b0 || rsp_valid_o !== 1'b0) begin
                $fatal(1, "F32->F64 interface active while reset asserted");
            end
            @(posedge clk_i);
            #1;
            if (rsp_valid_o !== 1'b0) begin
                $fatal(1, "F32->F64 reset did not cancel resident response");
            end
            @(negedge clk_i);
            rst_i = 1'b0;
            #1;
            if (req_ready_o !== 1'b1 || rsp_valid_o !== 1'b0) begin
                $fatal(1, "F32->F64 did not return to EMPTY after reset");
            end
            @(posedge clk_i);
            #1;
            if (rsp_valid_o !== 1'b0) begin
                $fatal(1, "F32->F64 stale response appeared after reset");
            end
        end
    endtask

    initial begin
        rst_i       = 1'b1;
        req_valid_i = 1'b0;
        operand_i   = 32'b0;
        rsp_ready_i = 1'b0;

        repeat (3) begin
            @(posedge clk_i);
            #1;
            if (req_ready_o !== 1'b0 || rsp_valid_o !== 1'b0) begin
                $fatal(1, "F32->F64 initial reset protocol violation");
            end
        end
        @(negedge clk_i);
        rst_i = 1'b0;
        #1;
        if (req_ready_o !== 1'b1 || rsp_valid_o !== 1'b0) begin
            $fatal(1, "F32->F64 initial reset left stale state");
        end

        // NORM_RTL_CONTRACT.md 的全部 finite F32 widening raw-bit oracle。
        check_response(32'h00000000, 64'h0000000000000000, 5'h00, 1'b0, 1'b1);
        check_response(32'h80000000, 64'h8000000000000000, 5'h00, 1'b0, 1'b0);
        check_response(32'h00000001, 64'h36a0000000000000, 5'h00, 1'b0, 1'b0);
        check_response(32'h007fffff, 64'h380fffffc0000000, 5'h00, 1'b0, 1'b0);
        check_response(32'h00800000, 64'h3810000000000000, 5'h00, 1'b0, 1'b0);
        check_response(32'h7f7fffff, 64'h47efffffe0000000, 5'h00, 1'b0, 1'b0);

        // NaN/Inf 均原子 fail-closed，第三方 payload 与 flags 不得外泄。
        check_response(32'h7f800000, 64'h0000000000000000, 5'h00, 1'b1, 1'b0);
        check_response(32'hff800000, 64'h0000000000000000, 5'h00, 1'b1, 1'b0);
        check_response(32'h7fc12345, 64'h0000000000000000, 5'h00, 1'b1, 1'b0);

        check_inflight_reset();

        $display("[NPU-FP32-FP64][PASS]");
        $finish;
    end

endmodule
