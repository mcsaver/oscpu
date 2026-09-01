`timescale 1ns/1ps

module tb_fp64_add;

    logic        clk_i;
    logic        rst_i;
    logic        req_valid_i;
    wire         req_ready_o;
    logic [63:0] operand_a_i;
    logic [63:0] operand_b_i;
    wire         rsp_valid_o;
    logic        rsp_ready_i;
    wire [63:0]  result_o;
    wire [4:0]   flags_o;
    wire         error_o;

    TensorNpuFp64Add dut (
        .clk_i      (clk_i),
        .rst_i      (rst_i),
        .req_valid_i(req_valid_i),
        .req_ready_o(req_ready_o),
        .operand_a_i(operand_a_i),
        .operand_b_i(operand_b_i),
        .rsp_valid_o(rsp_valid_o),
        .rsp_ready_i(rsp_ready_i),
        .result_o   (result_o),
        .flags_o    (flags_o),
        .error_o    (error_o)
    );

    initial clk_i = 1'b0;
    always #5 clk_i <= ~clk_i;

    task automatic check_response(
        input logic [63:0] request_a,
        input logic [63:0] request_b,
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
                $fatal(1, "F64 add request slot not EMPTY before request");
            end
            operand_a_i = request_a;
            operand_b_i = request_b;
            req_valid_i = 1'b1;
            rsp_ready_i = 1'b0;

            @(posedge clk_i);
            #1;
            req_valid_i = 1'b0;
            if (rsp_valid_o !== 1'b1 || req_ready_o !== 1'b0) begin
                $fatal(1, "F64 add response timing/occupancy mismatch a=%h b=%h", request_a, request_b);
            end
            if (result_o !== expected_result || flags_o !== expected_flags ||
                error_o !== expected_error) begin
                $fatal(1,
                    "F64 add mismatch a=%h b=%h got=%h/%h err=%b expected=%h/%h err=%b",
                    request_a, request_b, result_o, flags_o, error_o,
                    expected_result, expected_flags, expected_error);
            end

            if (exercise_hold_and_busy) begin
                held_result = result_o;
                held_flags  = flags_o;
                held_error  = error_o;
                @(negedge clk_i);
                operand_a_i = 64'h7fefffffffffffff;
                operand_b_i = 64'h7fefffffffffffff;
                req_valid_i = 1'b1;
                repeat (2) begin
                    @(posedge clk_i);
                    #1;
                    if (req_ready_o !== 1'b0 || rsp_valid_o !== 1'b1 ||
                        result_o !== held_result || flags_o !== held_flags ||
                        error_o !== held_error) begin
                        $fatal(1, "F64 add held response changed under backpressure/busy request");
                    end
                end
                @(negedge clk_i);
                req_valid_i = 1'b0;
                operand_a_i = 64'b0;
                operand_b_i = 64'b0;
            end

            @(negedge clk_i);
            rsp_ready_i = 1'b1;
            @(posedge clk_i);
            #1;
            if (rsp_valid_o !== 1'b0) begin
                $fatal(1, "F64 add response did not retire on handshake");
            end
            @(negedge clk_i);
            rsp_ready_i = 1'b0;
        end
    endtask

    task automatic check_inflight_reset;
        begin
            @(negedge clk_i);
            operand_a_i = 64'h3ff0000000000000;
            operand_b_i = 64'h3ff0000000000000;
            req_valid_i = 1'b1;
            rsp_ready_i = 1'b0;
            @(posedge clk_i);
            #1;
            req_valid_i = 1'b0;
            if (rsp_valid_o !== 1'b1) begin
                $fatal(1, "F64 add reset probe request was not accepted");
            end

            @(negedge clk_i);
            rst_i = 1'b1;
            #1;
            if (req_ready_o !== 1'b0 || rsp_valid_o !== 1'b0) begin
                $fatal(1, "F64 add interface active while reset asserted");
            end
            @(posedge clk_i);
            #1;
            if (rsp_valid_o !== 1'b0) begin
                $fatal(1, "F64 add reset did not cancel resident response");
            end
            @(negedge clk_i);
            rst_i = 1'b0;
            #1;
            if (req_ready_o !== 1'b1 || rsp_valid_o !== 1'b0) begin
                $fatal(1, "F64 add did not return to EMPTY after reset");
            end
            @(posedge clk_i);
            #1;
            if (rsp_valid_o !== 1'b0) begin
                $fatal(1, "F64 add stale response appeared after reset");
            end
        end
    endtask

    initial begin
        rst_i       = 1'b1;
        req_valid_i = 1'b0;
        operand_a_i = 64'b0;
        operand_b_i = 64'b0;
        rsp_ready_i = 1'b0;

        repeat (3) begin
            @(posedge clk_i);
            #1;
            if (req_ready_o !== 1'b0 || rsp_valid_o !== 1'b0) begin
                $fatal(1, "F64 add initial reset protocol violation");
            end
        end
        @(negedge clk_i);
        rst_i = 1'b0;
        #1;
        if (req_ready_o !== 1'b1 || rsp_valid_o !== 1'b0) begin
            $fatal(1, "F64 add initial reset left stale state");
        end

        // NORM_RTL_CONTRACT.md 的全部 nonnegative finite F64 add oracle。
        check_response(64'h3ff8000000000000, 64'h3ff8000000000000,
                       64'h4008000000000000, 5'h00, 1'b0, 1'b1);
        check_response(64'h000fffffffffffff, 64'h0000000000000001,
                       64'h0010000000000000, 5'h00, 1'b0, 1'b0);
        check_response(64'h3ff0000000000000, 64'h3ca0000000000000,
                       64'h3ff0000000000000, 5'h01, 1'b0, 1'b0);
        check_response(64'h3ff0000000000001, 64'h3ca0000000000000,
                       64'h3ff0000000000002, 5'h01, 1'b0, 1'b0);
        check_response(64'h3ff0000000000000, 64'h3ca4000000000000,
                       64'h3ff0000000000001, 5'h01, 1'b0, 1'b0);
        check_response(64'h3ff0000000000000, 64'h0000000000000001,
                       64'h3ff0000000000000, 5'h01, 1'b0, 1'b0);
        check_response(64'h7fefffffffffffff, 64'h7fefffffffffffff,
                       64'h7ff0000000000000, 5'h05, 1'b0, 1'b0);

        // sign、NaN、Inf 非法域均必须清零；尤其 -0 不得被当成 +0。
        check_response(64'hbff0000000000000, 64'h3ff0000000000000,
                       64'h0000000000000000, 5'h00, 1'b1, 1'b0);
        check_response(64'h3ff0000000000000, 64'h8000000000000000,
                       64'h0000000000000000, 5'h00, 1'b1, 1'b0);
        check_response(64'h7ff0000000000000, 64'h0000000000000000,
                       64'h0000000000000000, 5'h00, 1'b1, 1'b0);
        check_response(64'h0000000000000000, 64'h7ff8123456789abc,
                       64'h0000000000000000, 5'h00, 1'b1, 1'b0);

        check_inflight_reset();

        $display("[NPU-FP64-ADD][PASS]");
        $finish;
    end

endmodule
