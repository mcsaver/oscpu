`timescale 1ns/1ps
`default_nettype none

// Frozen raw-bit oracle for TensorNpuFp32Sqrt.  The testbench does not use
// real/shortreal, DPI, host libm, waveform output, or assertion mode.
module tb_fp32_sqrt;

    localparam logic [1:0] STATE_CORE_BUSY = 2'b01;

    reg         clk_i;
    reg         rst_i;
    reg         req_valid_i;
    wire        req_ready_o;
    reg  [31:0] operand_bits_i;
    reg  [2:0]  rounding_mode_i;
    wire        rsp_valid_o;
    reg         rsp_ready_i;
    wire [31:0] result_bits_o;
    wire [4:0]  flags_o;

    integer cycle_count;
    integer completed_cases;
    integer reference_latency;
    integer request_fire_count;
    integer core_completion_count;
    integer response_fire_count;

    TensorNpuFp32Sqrt dut (
        .clk_i           (clk_i),
        .rst_i           (rst_i),
        .req_valid_i     (req_valid_i),
        .req_ready_o     (req_ready_o),
        .operand_bits_i  (operand_bits_i),
        .rounding_mode_i (rounding_mode_i),
        .rsp_valid_o     (rsp_valid_o),
        .rsp_ready_i     (rsp_ready_i),
        .result_bits_o   (result_bits_o),
        .flags_o         (flags_o)
    );

    initial clk_i = 1'b0;
    always #5 clk_i <= ~clk_i;

    always @(posedge clk_i) begin
        cycle_count <= cycle_count + 1;

        if (rst_i) begin
            request_fire_count    <= 0;
            core_completion_count <= 0;
            response_fire_count   <= 0;
        end else begin
            if (dut.req_fire_w) begin
                request_fire_count <= request_fire_count + 1;
            end
            if (dut.core_ready_w && (dut.state_q == STATE_CORE_BUSY)) begin
                core_completion_count <= core_completion_count + 1;
            end
            if (rsp_valid_o && rsp_ready_i) begin
                response_fire_count <= response_fire_count + 1;
            end

            if (dut.core_ready_w && (dut.state_q != STATE_CORE_BUSY)) begin
                $display("[NPU-FP32-SQRT][FAIL] unowned core completion cycle=%0d state=%0d",
                         cycle_count, dut.state_q);
                $fatal(1);
            end
            if (rsp_valid_o && req_ready_o) begin
                $display("[NPU-FP32-SQRT][FAIL] response and request-ready overlap cycle=%0d",
                         cycle_count);
                $fatal(1);
            end
        end

        if (cycle_count >= 1000) begin
            $display("[NPU-FP32-SQRT][FAIL] global timeout cycle=%0d",
                     cycle_count);
            $fatal(1);
        end
    end

    task automatic fail_case(input string reason);
        begin
            $display("[NPU-FP32-SQRT][FAIL] %s cycle=%0d state=%0d req=%0d core=%0d rsp=%0d",
                     reason, cycle_count, dut.state_q, request_fire_count,
                     core_completion_count, response_fire_count);
            $fatal(1);
        end
    endtask

    task automatic run_case(
        input string       case_name,
        input logic [2:0]  case_rm,
        input logic [31:0] case_operand,
        input logic [31:0] expected_result,
        input logic [4:0]  expected_flags,
        input integer      hold_cycles,
        input integer      held_request_cycles
    );
        integer launch_cycle;
        integer response_latency;
        integer wait_cycles;
        integer hold_index;
        integer held_request_index;
        integer request_count_before;
        integer completion_count_before;
        integer response_count_before;
        reg [31:0] held_result;
        reg [4:0]  held_flags;
        begin
            rsp_ready_i = (hold_cycles == 0);
            req_valid_i = 1'b0;

            while (req_ready_o !== 1'b1) begin
                @(posedge clk_i);
                @(negedge clk_i);
            end

            @(negedge clk_i);
            operand_bits_i  = case_operand;
            rounding_mode_i = case_rm;
            req_valid_i     = 1'b1;
            request_count_before    = request_fire_count;
            completion_count_before = core_completion_count;
            response_count_before   = response_fire_count;

            @(posedge clk_i);
            @(negedge clk_i);
            launch_cycle = cycle_count;

            if (request_fire_count != (request_count_before + 1)) begin
                fail_case({case_name, " request did not fire exactly once"});
            end
            if (req_ready_o !== 1'b0) begin
                fail_case({case_name, " did not enter CORE_BUSY"});
            end

            // Keep valid high while changing operand and rounding mode.  Since
            // ready is low, none of these busy requests may acquire ownership
            // or overwrite the original resident operation.
            for (held_request_index = 0;
                    held_request_index < held_request_cycles;
                    held_request_index = held_request_index + 1) begin
                operand_bits_i  = 32'hbf800000;
                rounding_mode_i = 3'b011;
                @(posedge clk_i);
                @(negedge clk_i);
                if (req_ready_o !== 1'b0) begin
                    fail_case({case_name, " exposed ready to held-high request"});
                end
                if (request_fire_count != (request_count_before + 1)) begin
                    fail_case({case_name, " accepted held-high request twice"});
                end
            end
            req_valid_i = 1'b0;

            wait_cycles = 0;
            while (rsp_valid_o !== 1'b1) begin
                if (req_ready_o !== 1'b0) begin
                    fail_case({case_name, " reopened request before completion"});
                end
                @(posedge clk_i);
                @(negedge clk_i);
                wait_cycles = wait_cycles + 1;

                // Launch-inclusive age reaches 32 with no response only on a
                // deadlocked or miswired PERFORMANCE=0 core.
                if (((cycle_count - launch_cycle + 1) >= 32)
                        && (rsp_valid_o !== 1'b1)) begin
                    fail_case({case_name, " exceeded 32-cycle watchdog"});
                end
            end

            response_latency = cycle_count - launch_cycle + 1;
            if (response_latency != 28) begin
                fail_case({case_name, " launch-inclusive latency was not 28"});
            end
            if (reference_latency < 0) begin
                reference_latency = response_latency;
            end else if (response_latency != reference_latency) begin
                fail_case({case_name, " latency changed across transactions"});
            end
            if (core_completion_count != (completion_count_before + 1)) begin
                fail_case({case_name, " core completion count was not one"});
            end
            if (response_fire_count != response_count_before) begin
                fail_case({case_name, " response consumed before TB ready edge"});
            end

            if (result_bits_o !== expected_result) begin
                fail_case({case_name, " raw result mismatch"});
            end
            if (flags_o !== expected_flags) begin
                fail_case({case_name, " raw flags mismatch"});
            end
            if (req_ready_o !== 1'b0) begin
                fail_case({case_name, " request ready while response held"});
            end

            held_result = result_bits_o;
            held_flags  = flags_o;
            for (hold_index = 0; hold_index < hold_cycles;
                    hold_index = hold_index + 1) begin
                @(posedge clk_i);
                @(negedge clk_i);
                if (rsp_valid_o !== 1'b1) begin
                    fail_case({case_name, " dropped backpressured response"});
                end
                if ((result_bits_o !== held_result) || (flags_o !== held_flags)) begin
                    fail_case({case_name, " changed backpressured payload"});
                end
                if (req_ready_o !== 1'b0) begin
                    fail_case({case_name, " reopened request under backpressure"});
                end
            end

            rsp_ready_i = 1'b1;
            @(posedge clk_i);
            @(negedge clk_i);
            if (rsp_valid_o !== 1'b0) begin
                fail_case({case_name, " response was not consumed"});
            end
            if (req_ready_o !== 1'b1) begin
                fail_case({case_name, " did not return to IDLE"});
            end
            if (response_fire_count != (response_count_before + 1)) begin
                fail_case({case_name, " response handshake count was not one"});
            end

            // A second idle edge with ready high must not recreate completion
            // or consume the same held payload twice.
            @(posedge clk_i);
            @(negedge clk_i);
            if (rsp_valid_o !== 1'b0) begin
                fail_case({case_name, " response repeated"});
            end
            if (core_completion_count != (completion_count_before + 1)) begin
                fail_case({case_name, " core completion repeated"});
            end
            if (request_fire_count != (request_count_before + 1)) begin
                fail_case({case_name, " unexpected request fire after response"});
            end

            rsp_ready_i = 1'b0;
            completed_cases = completed_cases + 1;
        end
    endtask

    task automatic run_mid_operation_reset;
        integer reset_probe;
        begin
            while (req_ready_o !== 1'b1) begin
                @(posedge clk_i);
                @(negedge clk_i);
            end

            @(negedge clk_i);
            operand_bits_i  = 32'h40000000;
            rounding_mode_i = 3'b000;
            req_valid_i     = 1'b1;
            @(posedge clk_i);
            @(negedge clk_i);
            req_valid_i = 1'b0;
            if (req_ready_o !== 1'b0) begin
                fail_case("mid-reset request did not enter CORE_BUSY");
            end

            repeat (7) begin
                @(posedge clk_i);
                @(negedge clk_i);
                if (rsp_valid_o !== 1'b0) begin
                    fail_case("mid-reset request completed before reset");
                end
            end

            rst_i = 1'b1;
            repeat (2) begin
                @(posedge clk_i);
                @(negedge clk_i);
                if ((req_ready_o !== 1'b0) || (rsp_valid_o !== 1'b0)
                        || (result_bits_o !== 32'b0) || (flags_o !== 5'b0)) begin
                    fail_case("mid-operation reset did not clear protocol/payload");
                end
            end
            rst_i = 1'b0;

            // One full watchdog window proves the third-party active-low reset
            // canceled the resident fixed-point sqrt state with no stale pulse.
            for (reset_probe = 0; reset_probe < 32;
                    reset_probe = reset_probe + 1) begin
                @(posedge clk_i);
                @(negedge clk_i);
                if ((rsp_valid_o !== 1'b0) || (dut.core_ready_w !== 1'b0)) begin
                    fail_case("reset-canceled operation produced stale completion");
                end
                if (req_ready_o !== 1'b1) begin
                    fail_case("request channel not idle after reset cancellation");
                end
            end
            if ((request_fire_count != 0) || (core_completion_count != 0)
                    || (response_fire_count != 0)) begin
                fail_case("reset epoch did not clear protocol event counters");
            end
        end
    endtask

    initial begin
        cycle_count             = 0;
        completed_cases         = 0;
        reference_latency       = -1;
        request_fire_count      = 0;
        core_completion_count   = 0;
        response_fire_count     = 0;
        rst_i                   = 1'b1;
        req_valid_i             = 1'b0;
        operand_bits_i          = 32'b0;
        rounding_mode_i         = 3'b000;
        rsp_ready_i             = 1'b0;

        repeat (3) @(posedge clk_i);
        @(negedge clk_i);
        if ((req_ready_o !== 1'b0) || (rsp_valid_o !== 1'b0)
                || (result_bits_o !== 32'b0) || (flags_o !== 5'b0)) begin
            fail_case("initial reset did not clear protocol/payload");
        end
        rst_i = 1'b0;
        @(posedge clk_i);
        @(negedge clk_i);
        if (req_ready_o !== 1'b1) begin
            fail_case("request channel did not open after initial reset");
        end

        run_mid_operation_reset();

        // Contract oracle #1-#15.  All results and flags are frozen raw bits.
        // Case 1 holds request valid through five busy cycles and holds the
        // response for five cycles; case 11 covers a three-cycle response hold.
        run_case("positive-zero-rne", 3'b000, 32'h00000000,
                 32'h00000000, 5'h00, 5, 5);
        run_case("negative-zero-rne", 3'b000, 32'h80000000,
                 32'h80000000, 5'h00, 0, 0);
        run_case("sqrt-four-rne", 3'b000, 32'h40800000,
                 32'h40000000, 5'h00, 0, 0);
        run_case("min-normal-rne", 3'b000, 32'h00800000,
                 32'h20000000, 5'h00, 0, 0);
        run_case("min-subnormal-rne", 3'b000, 32'h00000001,
                 32'h1a3504f3, 5'h01, 0, 0);
        run_case("positive-inf-rne", 3'b000, 32'h7f800000,
                 32'h7f800000, 5'h00, 0, 0);
        run_case("negative-inf-rne", 3'b000, 32'hff800000,
                 32'h7fc00000, 5'h10, 0, 0);
        run_case("negative-one-rne", 3'b000, 32'hbf800000,
                 32'h7fc00000, 5'h10, 0, 0);
        run_case("quiet-nan-rne", 3'b000, 32'h7fc12345,
                 32'h7fc00000, 5'h00, 0, 0);
        run_case("signaling-nan-rne", 3'b000, 32'h7f812345,
                 32'h7fc00000, 5'h10, 0, 0);
        run_case("sqrt-two-rne", 3'b000, 32'h40000000,
                 32'h3fb504f3, 5'h01, 3, 0);
        run_case("sqrt-two-rtz", 3'b001, 32'h40000000,
                 32'h3fb504f3, 5'h01, 0, 0);
        run_case("sqrt-two-rdn", 3'b010, 32'h40000000,
                 32'h3fb504f3, 5'h01, 0, 0);
        run_case("sqrt-two-rup", 3'b011, 32'h40000000,
                 32'h3fb504f4, 5'h01, 0, 0);
        run_case("sqrt-two-rmm", 3'b100, 32'h40000000,
                 32'h3fb504f3, 5'h01, 0, 0);

        if (completed_cases != 15) begin
            fail_case("completed case count was not 15");
        end
        if (reference_latency != 28) begin
            fail_case("reference launch-inclusive latency was not 28");
        end
        if ((request_fire_count != 15) || (core_completion_count != 15)
                || (response_fire_count != 15)) begin
            fail_case("request/core/response event totals were not 15/15/15");
        end

        $display("[NPU-FP32-SQRT][INFO] requests=%0d completions=%0d responses=%0d",
                 request_fire_count, core_completion_count,
                 response_fire_count);
        $display("[NPU-FP32-SQRT][PASS] cases=15 latency=28 performance=0 timeout=32 backpressure=stable reset=clean");
        $finish;
    end

endmodule

`default_nettype wire
