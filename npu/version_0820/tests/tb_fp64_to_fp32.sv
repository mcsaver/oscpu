`timescale 1ns/1ps

module tb_fp64_to_fp32;

    logic        clk_i;
    logic        rst_i;
    logic        req_valid_i;
    wire         req_ready_o;
    logic [63:0] operand_i;
    wire         rsp_valid_o;
    logic        rsp_ready_i;
    wire [31:0]  result_o;
    wire [4:0]   flags_o;
    wire         error_o;

    TensorNpuFp64ToFp32 dut (
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
        input logic [63:0] request_bits,
        input logic [31:0] expected_result,
        input logic [4:0]  expected_flags,
        input logic        expected_error,
        input logic        exercise_hold_and_busy
    );
        logic [31:0] held_result;
        logic [4:0]  held_flags;
        logic        held_error;
        begin
            @(negedge clk_i);
            if (req_ready_o !== 1'b1 || rsp_valid_o !== 1'b0) begin
                $fatal(1, "F64->F32 request slot not EMPTY before request");
            end
            operand_i   = request_bits;
            req_valid_i = 1'b1;
            rsp_ready_i = 1'b0;

            @(posedge clk_i);
            #1;
            req_valid_i = 1'b0;
            if (rsp_valid_o !== 1'b1 || req_ready_o !== 1'b0) begin
                $fatal(1, "F64->F32 response timing/occupancy mismatch input=%h", request_bits);
            end
            if (result_o !== expected_result || flags_o !== expected_flags ||
                error_o !== expected_error) begin
                $fatal(1,
                    "F64->F32 mismatch input=%h got=%h/%h err=%b expected=%h/%h err=%b",
                    request_bits, result_o, flags_o, error_o,
                    expected_result, expected_flags, expected_error);
            end

            if (exercise_hold_and_busy) begin
                held_result = result_o;
                held_flags  = flags_o;
                held_error  = error_o;
                @(negedge clk_i);
                operand_i   = 64'h47effffffff00000;
                req_valid_i = 1'b1;
                repeat (2) begin
                    @(posedge clk_i);
                    #1;
                    if (req_ready_o !== 1'b0 || rsp_valid_o !== 1'b1 ||
                        result_o !== held_result || flags_o !== held_flags ||
                        error_o !== held_error) begin
                        $fatal(1, "F64->F32 held response changed under backpressure/busy request");
                    end
                end
                @(negedge clk_i);
                req_valid_i = 1'b0;
                operand_i   = 64'b0;
            end

            @(negedge clk_i);
            rsp_ready_i = 1'b1;
            @(posedge clk_i);
            #1;
            if (rsp_valid_o !== 1'b0) begin
                $fatal(1, "F64->F32 response did not retire on handshake");
            end
            @(negedge clk_i);
            rsp_ready_i = 1'b0;
        end
    endtask

    task automatic check_inflight_reset;
        begin
            @(negedge clk_i);
            operand_i   = 64'h3ff0000000000000;
            req_valid_i = 1'b1;
            rsp_ready_i = 1'b0;
            @(posedge clk_i);
            #1;
            req_valid_i = 1'b0;
            if (rsp_valid_o !== 1'b1) begin
                $fatal(1, "F64->F32 reset probe request was not accepted");
            end

            @(negedge clk_i);
            rst_i = 1'b1;
            #1;
            if (req_ready_o !== 1'b0 || rsp_valid_o !== 1'b0) begin
                $fatal(1, "F64->F32 interface active while reset asserted");
            end
            @(posedge clk_i);
            #1;
            if (rsp_valid_o !== 1'b0) begin
                $fatal(1, "F64->F32 reset did not cancel resident response");
            end
            @(negedge clk_i);
            rst_i = 1'b0;
            #1;
            if (req_ready_o !== 1'b1 || rsp_valid_o !== 1'b0) begin
                $fatal(1, "F64->F32 did not return to EMPTY after reset");
            end
            @(posedge clk_i);
            #1;
            if (rsp_valid_o !== 1'b0) begin
                $fatal(1, "F64->F32 stale response appeared after reset");
            end
        end
    endtask

    initial begin
        rst_i       = 1'b1;
        req_valid_i = 1'b0;
        operand_i   = 64'b0;
        rsp_ready_i = 1'b0;

        repeat (3) begin
            @(posedge clk_i);
            #1;
            if (req_ready_o !== 1'b0 || rsp_valid_o !== 1'b0) begin
                $fatal(1, "F64->F32 initial reset protocol violation");
            end
        end
        @(negedge clk_i);
        rst_i = 1'b0;
        #1;
        if (req_ready_o !== 1'b1 || rsp_valid_o !== 1'b0) begin
            $fatal(1, "F64->F32 initial reset left stale state");
        end

        // NORM_RTL_CONTRACT.md 的全部 RNE/tininess-after raw-bit oracle。
        check_response(64'h3ff0000010000000, 32'h3f800000, 5'h01, 1'b0, 1'b1);
        check_response(64'h3ff0000030000000, 32'h3f800002, 5'h01, 1'b0, 1'b0);
        check_response(64'h3ff0000010000001, 32'h3f800001, 5'h01, 1'b0, 1'b0);
        check_response(64'h36a0000000000000, 32'h00000001, 5'h00, 1'b0, 1'b0);
        check_response(64'h3690000000000000, 32'h00000000, 5'h03, 1'b0, 1'b0);
        check_response(64'h380fffffc0000000, 32'h007fffff, 5'h00, 1'b0, 1'b0);
        check_response(64'h380fffffe0000000, 32'h00800000, 5'h03, 1'b0, 1'b0);
        check_response(64'h380fffffe1000000, 32'h00800000, 5'h03, 1'b0, 1'b0);
        check_response(64'h380ffffff0000000, 32'h00800000, 5'h01, 1'b0, 1'b0);
        check_response(64'h47efffffefffffff, 32'h7f7fffff, 5'h01, 1'b0, 1'b0);
        check_response(64'h47effffff0000000, 32'h7f800000, 5'h05, 1'b0, 1'b0);

        // +0 合法；negative sign、NaN、Inf 原子 fail-closed。
        check_response(64'h0000000000000000, 32'h00000000, 5'h00, 1'b0, 1'b0);
        check_response(64'h8000000000000000, 32'h00000000, 5'h00, 1'b1, 1'b0);
        check_response(64'hbff0000000000000, 32'h00000000, 5'h00, 1'b1, 1'b0);
        check_response(64'h7ff0000000000000, 32'h00000000, 5'h00, 1'b1, 1'b0);
        check_response(64'h7ff8123456789abc, 32'h00000000, 5'h00, 1'b1, 1'b0);

        check_inflight_reset();

        $display("[NPU-FP64-FP32][PASS]");
        $finish;
    end

endmodule
