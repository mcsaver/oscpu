`timescale 1ns/1ps

module tb_fp64_fma;

    logic        clk_i;
    logic        rst_i;
    logic        req_valid_i;
    wire         req_ready_o;
    logic [63:0] operand_a_i;
    logic [63:0] operand_b_i;
    logic [63:0] operand_c_i;
    wire         rsp_valid_o;
    logic        rsp_ready_i;
    wire [63:0]  result_o;
    wire [4:0]   flags_o;

    TensorNpuFp64Fma dut (
        .clk_i      (clk_i),
        .rst_i      (rst_i),
        .req_valid_i(req_valid_i),
        .req_ready_o(req_ready_o),
        .operand_a_i(operand_a_i),
        .operand_b_i(operand_b_i),
        .operand_c_i(operand_c_i),
        .rsp_valid_o(rsp_valid_o),
        .rsp_ready_i(rsp_ready_i),
        .result_o   (result_o),
        .flags_o    (flags_o)
    );

    initial clk_i = 1'b0;
    always #5 clk_i <= ~clk_i;

    task automatic check_response(
        input logic [63:0] request_a,
        input logic [63:0] request_b,
        input logic [63:0] request_c,
        input logic [63:0] expected_result,
        input logic [4:0]  expected_flags,
        input integer      hold_cycles,
        input logic        exercise_busy
    );
        logic [63:0] held_result;
        logic [4:0]  held_flags;
        integer      hold_index;
        begin
            @(negedge clk_i);
            if (req_ready_o !== 1'b1 || rsp_valid_o !== 1'b0) begin
                $fatal(1, "F64 FMA request slot not EMPTY before request");
            end

            operand_a_i = request_a;
            operand_b_i = request_b;
            operand_c_i = request_c;
            req_valid_i = 1'b1;
            rsp_ready_i = 1'b0;

            // request fire：result 与 flags 必须在同一边沿写入 holding slot。
            @(posedge clk_i);
            #1;
            req_valid_i = 1'b0;
            if (rsp_valid_o !== 1'b1 || req_ready_o !== 1'b0) begin
                $fatal(1,
                    "F64 FMA response timing/occupancy mismatch a=%h b=%h c=%h",
                    request_a, request_b, request_c);
            end
            if (result_o !== expected_result || flags_o !== expected_flags) begin
                $fatal(1,
                    "F64 FMA mismatch a=%h b=%h c=%h got=%h/%h expected=%h/%h",
                    request_a, request_b, request_c, result_o, flags_o,
                    expected_result, expected_flags);
            end

            held_result = result_o;
            held_flags  = flags_o;

            if (hold_cycles > 0) begin
                @(negedge clk_i);
                if (exercise_busy) begin
                    // FULL 期间持续给出会产生 invalid 的另一 request，必须完全忽略。
                    operand_a_i = 64'h0000000000000000;
                    operand_b_i = 64'h7ff0000000000000;
                    operand_c_i = 64'h3ff0000000000000;
                    req_valid_i = 1'b1;
                end

                for (hold_index = 0; hold_index < hold_cycles;
                     hold_index = hold_index + 1) begin
                    @(posedge clk_i);
                    #1;
                    if (req_ready_o !== 1'b0 || rsp_valid_o !== 1'b1 ||
                        result_o !== held_result || flags_o !== held_flags) begin
                        $fatal(1,
                            "F64 FMA held response changed at hold cycle %0d",
                            hold_index);
                    end
                end
                @(negedge clk_i);
            end else begin
                @(negedge clk_i);
            end

            // 若 busy request 仍有效，FULL 分支也只能消费 resident response，不能重接。
            rsp_ready_i = 1'b1;
            @(posedge clk_i);
            #1;
            if (rsp_valid_o !== 1'b0 || req_ready_o !== 1'b1) begin
                $fatal(1, "F64 FMA response did not retire exactly once");
            end
            req_valid_i = 1'b0;
            operand_a_i = 64'b0;
            operand_b_i = 64'b0;
            operand_c_i = 64'b0;

            // ready 保持一拍：被忽略的 busy request 不得变成 queued/duplicate response。
            @(posedge clk_i);
            #1;
            if (rsp_valid_o !== 1'b0 || req_ready_o !== 1'b1) begin
                $fatal(1, "F64 FMA duplicate response appeared after retire");
            end
            @(negedge clk_i);
            rsp_ready_i = 1'b0;
        end
    endtask

    task automatic check_inflight_reset;
        begin
            @(negedge clk_i);
            if (req_ready_o !== 1'b1 || rsp_valid_o !== 1'b0) begin
                $fatal(1, "F64 FMA reset probe did not start from EMPTY");
            end
            operand_a_i = 64'h3ff0000000000000;
            operand_b_i = 64'h3ff0000000000000;
            operand_c_i = 64'h0000000000000000;
            req_valid_i = 1'b1;
            rsp_ready_i = 1'b0;

            @(posedge clk_i);
            #1;
            req_valid_i = 1'b0;
            if (rsp_valid_o !== 1'b1 || result_o !== 64'h3ff0000000000000 ||
                flags_o !== 5'h00) begin
                $fatal(1, "F64 FMA reset probe request was not captured atomically");
            end

            @(negedge clk_i);
            rst_i       = 1'b1;
            req_valid_i = 1'b1;
            operand_a_i = 64'h7fefffffffffffff;
            operand_b_i = 64'h4000000000000000;
            operand_c_i = 64'h0000000000000000;
            #1;
            if (req_ready_o !== 1'b0 || rsp_valid_o !== 1'b0) begin
                $fatal(1, "F64 FMA interface active while reset asserted");
            end

            @(posedge clk_i);
            #1;
            if (req_ready_o !== 1'b0 || rsp_valid_o !== 1'b0 ||
                result_o !== 64'b0 || flags_o !== 5'b0) begin
                $fatal(1, "F64 FMA reset did not cancel resident response");
            end

            @(negedge clk_i);
            req_valid_i = 1'b0;
            operand_a_i = 64'b0;
            operand_b_i = 64'b0;
            operand_c_i = 64'b0;
            rst_i       = 1'b0;
            #1;
            if (req_ready_o !== 1'b1 || rsp_valid_o !== 1'b0) begin
                $fatal(1, "F64 FMA did not return to EMPTY after reset");
            end

            @(posedge clk_i);
            #1;
            if (rsp_valid_o !== 1'b0) begin
                $fatal(1, "F64 FMA stale response appeared after reset");
            end
        end
    endtask

    initial begin
        rst_i       = 1'b1;
        req_valid_i = 1'b0;
        operand_a_i = 64'b0;
        operand_b_i = 64'b0;
        operand_c_i = 64'b0;
        rsp_ready_i = 1'b0;

        repeat (3) begin
            @(posedge clk_i);
            #1;
            if (req_ready_o !== 1'b0 || rsp_valid_o !== 1'b0) begin
                $fatal(1, "F64 FMA initial reset protocol violation");
            end
        end
        @(negedge clk_i);
        rst_i = 1'b0;
        #1;
        if (req_ready_o !== 1'b1 || rsp_valid_o !== 1'b0) begin
            $fatal(1, "F64 FMA initial reset left stale state");
        end

        // FP64_FMA_RTL_CONTRACT.md 的全部 binary64 raw-bit oracle。
        check_response(64'h3ff8000000000000, 64'h4000000000000000,
                       64'h3fe0000000000000, 64'h400c000000000000,
                       5'h00, 3, 1'b1);
        check_response(64'hbff8000000000000, 64'h4000000000000000,
                       64'h3fe0000000000000, 64'hc004000000000000,
                       5'h00, 0, 1'b0);

        // 精确结果 -2^-104；split multiply+add 会错误退化为 +0。
        check_response(64'h3ff0000000000001, 64'h3feffffffffffffe,
                       64'hbff0000000000000, 64'hb970000000000000,
                       5'h00, 0, 1'b0);

        // RNE half-way：保留偶数 LSB，奇数 LSB 则进位到下一个偶数。
        check_response(64'h3ff0000000000000, 64'h3ff0000000000000,
                       64'h3ca0000000000000, 64'h3ff0000000000000,
                       5'h01, 0, 1'b0);
        check_response(64'h3ff0000000000001, 64'h3ff0000000000000,
                       64'h3ca0000000000000, 64'h3ff0000000000002,
                       5'h01, 0, 1'b0);

        check_response(64'h0010000000000000, 64'h3fe0000000000000,
                       64'h0000000000000000, 64'h0008000000000000,
                       5'h00, 0, 1'b0);
        check_response(64'h0000000000000001, 64'h3fe0000000000000,
                       64'h0000000000000000, 64'h0000000000000000,
                       5'h03, 0, 1'b0);
        check_response(64'h7fefffffffffffff, 64'h4000000000000000,
                       64'h0000000000000000, 64'h7ff0000000000000,
                       5'h05, 0, 1'b0);
        check_response(64'h0000000000000000, 64'h7ff0000000000000,
                       64'h3ff0000000000000, 64'h7ff8000000000000,
                       5'h10, 0, 1'b0);
        check_response(64'h7ff0000000000000, 64'h3ff0000000000000,
                       64'hfff0000000000000, 64'h7ff8000000000000,
                       5'h10, 0, 1'b0);
        check_response(64'h8000000000000000, 64'h4000000000000000,
                       64'h8000000000000000, 64'h8000000000000000,
                       5'h00, 0, 1'b0);

        check_inflight_reset();

        // deassert 后必须能干净接收新事务，不能复现 reset 前的 payload。
        check_response(64'h3ff0000000000000, 64'h4000000000000000,
                       64'h3fe0000000000000, 64'h4004000000000000,
                       5'h00, 0, 1'b0);

        $display("[NPU-FP64-FMA][PASS]");
        $finish;
    end

endmodule
