`timescale 1ns/1ps

module tb_fp32_addmul;

    reg         clk_i;
    reg         rst_i;
    reg         req_valid_i;
    wire        req_ready_o;
    reg         op_mul_i;
    reg  [31:0] lhs_bits_i;
    reg  [31:0] rhs_bits_i;
    wire        rsp_valid_o;
    reg         rsp_ready_i;
    wire [31:0] result_bits_o;
    wire [4:0]  flags_o;

    integer cycle_count;
    integer reference_latency;
    integer completed_cases;

    TensorNpuFp32AddMul dut (
        .clk_i         (clk_i),
        .rst_i         (rst_i),
        .req_valid_i   (req_valid_i),
        .req_ready_o   (req_ready_o),
        .op_mul_i      (op_mul_i),
        .lhs_bits_i    (lhs_bits_i),
        .rhs_bits_i    (rhs_bits_i),
        .rsp_valid_o   (rsp_valid_o),
        .rsp_ready_i   (rsp_ready_i),
        .result_bits_o (result_bits_o),
        .flags_o       (flags_o)
    );

    initial clk_i = 1'b0;
    always #5 clk_i <= ~clk_i;

    always @(posedge clk_i) begin
        cycle_count <= cycle_count + 1;
        if (cycle_count >= 180) begin
            $display("[NPU-FP32-ADDMUL][FAIL] global timeout cycle=%0d", cycle_count + 1);
            $fatal(1);
        end
    end

    task automatic fail_case(input string reason);
        begin
            $display("[NPU-FP32-ADDMUL][FAIL] %s cycle=%0d", reason, cycle_count);
            $fatal(1);
        end
    endtask

    task automatic run_case(
        input string       case_name,
        input logic        case_mul,
        input logic [31:0] case_lhs,
        input logic [31:0] case_rhs,
        input logic [31:0] expected_result,
        input logic [4:0]  expected_flags,
        input integer      hold_cycles,
        input integer      probe_busy
    );
        integer fire_cycle;
        integer response_latency;
        integer wait_cycles;
        integer hold_index;
        reg [31:0] held_result;
        reg [4:0]  held_flags;
        begin
            rsp_ready_i = (hold_cycles == 0);

            while (req_ready_o !== 1'b1) begin
                @(negedge clk_i);
            end

            op_mul_i    = case_mul;
            lhs_bits_i  = case_lhs;
            rhs_bits_i  = case_rhs;
            req_valid_i = 1'b1;

            // Request is accepted at this edge.  Observe the registered busy
            // state at the following negedge to avoid testbench/NBA races.
            @(posedge clk_i);
            @(negedge clk_i);
            fire_cycle = cycle_count;
            if (req_ready_o !== 1'b0) begin
                fail_case($sformatf("%s did not enter busy state", case_name));
            end

            // Keep a different request asserted for one busy cycle.  Because
            // req_ready_o is low, it must neither issue nor corrupt the first
            // operation's result.
            if (probe_busy != 0) begin
                op_mul_i   = ~case_mul;
                lhs_bits_i = 32'h00000000;
                rhs_bits_i = 32'h7f800000;
                @(posedge clk_i);
                @(negedge clk_i);
                if (req_ready_o !== 1'b0) begin
                    fail_case($sformatf("%s accepted a request while busy", case_name));
                end
            end
            req_valid_i = 1'b0;

            wait_cycles = 0;
            while (rsp_valid_o !== 1'b1) begin
                if (req_ready_o !== 1'b0) begin
                    fail_case($sformatf("%s reopened request channel before response", case_name));
                end
                @(posedge clk_i);
                @(negedge clk_i);
                wait_cycles = wait_cycles + 1;
                if (wait_cycles > 16) begin
                    fail_case($sformatf("%s exceeded 16-cycle response timeout", case_name));
                end
            end

            response_latency = cycle_count - fire_cycle;
            if (response_latency > 16) begin
                fail_case($sformatf("%s latency=%0d exceeds limit", case_name,
                                    response_latency));
            end
            if (reference_latency < 0) begin
                reference_latency = response_latency;
            end else if (response_latency != reference_latency) begin
                fail_case($sformatf("%s latency=%0d expected=%0d", case_name,
                                    response_latency, reference_latency));
            end

            if (result_bits_o !== expected_result) begin
                fail_case($sformatf("%s result=%08x expected=%08x", case_name,
                                    result_bits_o, expected_result));
            end
            if (flags_o !== expected_flags) begin
                fail_case($sformatf("%s flags=%02x expected=%02x", case_name,
                                    flags_o, expected_flags));
            end
            if (req_ready_o !== 1'b0) begin
                fail_case($sformatf("%s request channel open while response held", case_name));
            end

            held_result = result_bits_o;
            held_flags  = flags_o;
            for (hold_index = 0; hold_index < hold_cycles; hold_index = hold_index + 1) begin
                @(posedge clk_i);
                @(negedge clk_i);
                if (rsp_valid_o !== 1'b1) begin
                    fail_case($sformatf("%s dropped response under backpressure", case_name));
                end
                if ((result_bits_o !== held_result) || (flags_o !== held_flags)) begin
                    fail_case($sformatf("%s changed payload under backpressure", case_name));
                end
                if (req_ready_o !== 1'b0) begin
                    fail_case($sformatf("%s reopened request channel under backpressure", case_name));
                end
            end

            rsp_ready_i = 1'b1;
            @(posedge clk_i);
            @(negedge clk_i);
            if (rsp_valid_o !== 1'b0) begin
                fail_case($sformatf("%s response was not consumed", case_name));
            end
            if (req_ready_o !== 1'b1) begin
                fail_case($sformatf("%s did not return to idle", case_name));
            end

            // Leave ready asserted for another edge: the same response must
            // not be reported or consumed a second time.
            @(posedge clk_i);
            @(negedge clk_i);
            if (rsp_valid_o !== 1'b0) begin
                fail_case($sformatf("%s response was presented more than once", case_name));
            end

            rsp_ready_i = 1'b0;
            completed_cases = completed_cases + 1;
        end
    endtask

    initial begin
        cycle_count      = 0;
        reference_latency = -1;
        completed_cases  = 0;
        rst_i            = 1'b1;
        req_valid_i      = 1'b0;
        op_mul_i         = 1'b0;
        lhs_bits_i       = 32'b0;
        rhs_bits_i       = 32'b0;
        rsp_ready_i      = 1'b0;

        repeat (3) @(posedge clk_i);
        @(negedge clk_i);
        if ((rsp_valid_o !== 1'b0) || (req_ready_o !== 1'b0) ||
            (result_bits_o !== 32'b0) || (flags_o !== 5'b0)) begin
            fail_case("startup reset did not clear protocol and payload state");
        end
        rst_i = 1'b0;

        // Start an operation and reset it while in flight.  Both the wrapper
        // state and the upstream active-low-reset pipeline must discard it.
        @(negedge clk_i);
        op_mul_i    = 1'b1;
        lhs_bits_i  = 32'h7f7fffff;
        rhs_bits_i  = 32'h40000000;
        req_valid_i = 1'b1;
        @(posedge clk_i);
        @(negedge clk_i);
        req_valid_i = 1'b0;
        if (req_ready_o !== 1'b0) begin
            fail_case("reset test request did not enter busy state");
        end
        rst_i = 1'b1;
        repeat (2) @(posedge clk_i);
        @(negedge clk_i);
        if ((rsp_valid_o !== 1'b0) || (req_ready_o !== 1'b0) ||
            (result_bits_o !== 32'b0) || (flags_o !== 5'b0)) begin
            fail_case("in-flight reset did not clear protocol and payload state");
        end
        rst_i = 1'b0;

        // A few idle edges prove that the canceled upstream ready pulse cannot
        // recreate a response after reset.
        repeat (4) begin
            @(posedge clk_i);
            @(negedge clk_i);
            if (rsp_valid_o !== 1'b0) begin
                fail_case("canceled operation produced a stale response");
            end
            if (req_ready_o !== 1'b1) begin
                fail_case("request channel did not reopen after reset deassertion");
            end
        end

        // All arithmetic oracles below are frozen IEEE-754 raw-bit constants;
        // no real/shortreal, DPI, or host floating-point arithmetic is used.
        run_case("1.5_plus_2.25", 1'b0, 32'h3fc00000, 32'h40100000,
                 32'h40700000, 5'b00000, 0, 1);
        run_case("44421_times_1", 1'b1, 32'h472d8500, 32'h3f800000,
                 32'h472d8500, 5'b00000, 0, 0);
        run_case("3.75_times_0.5_backpressured", 1'b1, 32'h40700000, 32'h3f000000,
                 32'h3ff00000, 5'b00000, 3, 0);
        run_case("rne_even_tie", 1'b0, 32'h3f800000, 32'h33800000,
                 32'h3f800000, 5'b00001, 0, 0);
        run_case("rne_odd_tie", 1'b0, 32'h3f800001, 32'h33800000,
                 32'h3f800002, 5'b00001, 0, 0);
        run_case("overflow", 1'b1, 32'h7f7fffff, 32'h40000000,
                 32'h7f800000, 5'b00101, 0, 0);
        run_case("zero_times_infinity", 1'b1, 32'h00000000, 32'h7f800000,
                 32'h7fc00000, 5'b10000, 0, 0);

        if (completed_cases != 7) begin
            fail_case($sformatf("completed_cases=%0d expected=7", completed_cases));
        end
        $display("[NPU-FP32-ADDMUL][PASS] cases=%0d latency=%0d max_latency=16 backpressure=stable reset=clean",
                 completed_cases, reference_latency);
        $finish;
    end

endmodule
