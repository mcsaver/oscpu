`timescale 1ns/1ps
`default_nettype none

// Self-checking raw-bit verification for TensorNpuQ8DequantBlock.
// All arithmetic oracles are frozen IEEE-754 bit patterns.  This testbench
// deliberately uses no real/shortreal, DPI, host floating point, assertion
// mode, or waveform output.
module tb_q8_dequant_block;

    localparam logic [3:0] ST_MUL_WAIT = 4'd3;

    reg          clk_i;
    reg          rst_i;
    reg          start_i;
    wire         ready_o;
    wire         busy_o;
    reg  [271:0] block_i;
    wire         lane_valid_o;
    reg          lane_ready_i;
    wire [5:0]   lane_index_o;
    wire [31:0]  lane_bits_o;
    wire         lane_last_o;
    wire         done_o;
    wire         error_o;
    wire [3:0]   error_code_o;
    wire [15:0]  active_cycles_o;

    reg [271:0] stimulus_block;
    reg [31:0]  expected_lane [0:31];

    integer cycle_count;
    integer successful_blocks;
    integer expected_error_cases;
    integer observed_lane_handshakes;
    integer vector_index;

    TensorNpuQ8DequantBlock #(
        .CHILD_TIMEOUT_CYCLES (16'd12)
    ) dut (
        .clk_i           (clk_i),
        .rst_i           (rst_i),
        .start_i         (start_i),
        .ready_o         (ready_o),
        .busy_o          (busy_o),
        .block_i         (block_i),
        .lane_valid_o    (lane_valid_o),
        .lane_ready_i    (lane_ready_i),
        .lane_index_o    (lane_index_o),
        .lane_bits_o     (lane_bits_o),
        .lane_last_o     (lane_last_o),
        .done_o          (done_o),
        .error_o         (error_o),
        .error_code_o    (error_code_o),
        .active_cycles_o (active_cycles_o)
    );

    initial clk_i = 1'b0;
    always #5 clk_i <= ~clk_i;

    always @(posedge clk_i) begin
        cycle_count <= cycle_count + 1;

        if (!rst_i) begin
            if (done_o && error_o) begin
                $display("[NPU-Q8-DEQUANT][FAIL] done/error overlap cycle=%0d",
                         cycle_count);
                $fatal(1);
            end
            if (ready_o && busy_o) begin
                $display("[NPU-Q8-DEQUANT][FAIL] ready/busy overlap cycle=%0d",
                         cycle_count);
                $fatal(1);
            end
            if (lane_valid_o && !busy_o) begin
                $display("[NPU-Q8-DEQUANT][FAIL] lane valid outside busy cycle=%0d",
                         cycle_count);
                $fatal(1);
            end
            if (lane_valid_o && lane_ready_i) begin
                observed_lane_handshakes <= observed_lane_handshakes + 1;
            end
        end

        if (cycle_count >= 6000) begin
            $display("[NPU-Q8-DEQUANT][FAIL] global timeout cycle=%0d",
                     cycle_count);
            $fatal(1);
        end
    end

    task automatic fail_case(input string reason);
        begin
            $display("[NPU-Q8-DEQUANT][FAIL] %s cycle=%0d state=%0d mul_lane=%0d lane=%0d active=%0d",
                     reason, cycle_count, dut.state_q, dut.mul_index_q,
                     lane_index_o, active_cycles_o);
            $fatal(1);
        end
    endtask

    task automatic init_vector(
        input logic [15:0] scale_bits,
        input logic [31:0] default_expected
    );
        integer lane;
        begin
            stimulus_block       = 272'b0;
            stimulus_block[15:0] = scale_bits;
            for (lane = 0; lane < 32; lane = lane + 1) begin
                // Verification loop fills the 32 frozen expected entries; it
                // does not model or calculate floating-point arithmetic.
                stimulus_block[16 + (lane * 8) +: 8] = 8'h00;
                expected_lane[lane] = default_expected;
            end
        end
    endtask

    task automatic set_vector_lane(
        input integer      lane,
        input logic [7:0]  q_bits,
        input logic [31:0] expected_bits
    );
        begin
            stimulus_block[16 + (lane * 8) +: 8] = q_bits;
            expected_lane[lane] = expected_bits;
        end
    endtask

    task automatic launch_current_block;
        begin
            lane_ready_i = 1'b0;
            start_i      = 1'b0;
            while (ready_o !== 1'b1) begin
                @(posedge clk_i);
                @(negedge clk_i);
            end

            // Drive block and start for one complete setup half-cycle before
            // the accepting edge.
            @(negedge clk_i);
            block_i = stimulus_block;
            start_i = 1'b1;
            @(posedge clk_i);
            @(negedge clk_i);
            start_i = 1'b0;

            if ((busy_o !== 1'b1) || (ready_o !== 1'b0)) begin
                fail_case("accepted start did not enter busy state");
            end
        end
    endtask

    task automatic check_error_terminal(
        input string      case_name,
        input logic [3:0] expected_code
    );
        begin
            if (lane_valid_o !== 1'b0) begin
                fail_case({case_name, " published a lane on error"});
            end
            if ((error_o !== 1'b1) || (done_o !== 1'b0)
                    || (busy_o !== 1'b1) || (ready_o !== 1'b0)) begin
                fail_case({case_name, " missing single busy error terminal"});
            end
            if (error_code_o !== expected_code) begin
                fail_case({case_name, " wrong error_code_o"});
            end
            if (active_cycles_o == 16'b0) begin
                fail_case({case_name, " active cycle count stayed zero"});
            end

            expected_error_cases = expected_error_cases + 1;
            @(posedge clk_i);
            @(negedge clk_i);
            if ((error_o !== 1'b0) || (done_o !== 1'b0)
                    || (busy_o !== 1'b0) || (ready_o !== 1'b1)
                    || (lane_valid_o !== 1'b0)) begin
                fail_case({case_name, " terminal was not exactly one cycle"});
            end
            lane_ready_i = 1'b0;
        end
    endtask

    task automatic run_success_case(
        input string  case_name,
        input integer held_lane,
        input integer hold_cycles,
        input integer probe_busy_start
    );
        integer lane;
        integer wait_cycles;
        integer hold_index;
        reg [5:0]  held_index;
        reg [31:0] held_bits;
        reg        held_last;
        reg [15:0] terminal_active_cycles;
        begin
            launch_current_block();

            // A changing block_i and asserted start_i while busy must neither
            // replace the resident block nor create another transaction.
            if (probe_busy_start != 0) begin
                block_i = ~stimulus_block;
                start_i = 1'b1;
                @(posedge clk_i);
                @(negedge clk_i);
                if ((ready_o !== 1'b0) || (busy_o !== 1'b1)) begin
                    fail_case({case_name, " exposed ready during busy start"});
                end
                start_i = 1'b0;
                block_i = stimulus_block;
            end

            lane_ready_i = 1'b0;
            for (lane = 0; lane < 32; lane = lane + 1) begin
                wait_cycles = 0;
                while (lane_valid_o !== 1'b1) begin
                    if ((done_o === 1'b1) || (error_o === 1'b1)) begin
                        fail_case({case_name, " terminated before all lanes"});
                    end
                    @(posedge clk_i);
                    @(negedge clk_i);
                    wait_cycles = wait_cycles + 1;
                    if (wait_cycles > 800) begin
                        fail_case({case_name, " lane wait timeout"});
                    end
                end

                if (lane_index_o !== lane[5:0]) begin
                    fail_case({case_name, " lane index/order mismatch"});
                end
                if (lane_bits_o !== expected_lane[lane]) begin
                    fail_case({case_name, " raw FP32 lane mismatch"});
                end
                if (lane_last_o !== (lane == 31)) begin
                    fail_case({case_name, " lane_last_o mismatch"});
                end

                held_index = lane_index_o;
                held_bits  = lane_bits_o;
                held_last  = lane_last_o;
                if (lane == held_lane) begin
                    for (hold_index = 0; hold_index < hold_cycles;
                            hold_index = hold_index + 1) begin
                        @(posedge clk_i);
                        @(negedge clk_i);
                        if ((lane_valid_o !== 1'b1)
                                || (lane_index_o !== held_index)
                                || (lane_bits_o !== held_bits)
                                || (lane_last_o !== held_last)) begin
                            fail_case({case_name,
                                       " payload changed under backpressure"});
                        end
                    end
                end

                lane_ready_i = 1'b1;
                @(posedge clk_i);
                @(negedge clk_i);
                lane_ready_i = 1'b0;

                if ((lane != 31)
                        && ((done_o === 1'b1) || (error_o === 1'b1))) begin
                    fail_case({case_name, " terminal before last handshake"});
                end
            end

            if ((done_o !== 1'b1) || (error_o !== 1'b0)
                    || (busy_o !== 1'b1) || (ready_o !== 1'b0)
                    || (lane_valid_o !== 1'b0)) begin
                fail_case({case_name, " missing post-last DONE cycle"});
            end
            terminal_active_cycles = active_cycles_o;
            if (terminal_active_cycles == 16'b0) begin
                fail_case({case_name, " active cycle count stayed zero"});
            end

            @(posedge clk_i);
            @(negedge clk_i);
            if ((done_o !== 1'b0) || (error_o !== 1'b0)
                    || (busy_o !== 1'b0) || (ready_o !== 1'b1)
                    || (lane_valid_o !== 1'b0)) begin
                fail_case({case_name, " DONE was not exactly one cycle"});
            end
            if (active_cycles_o !== terminal_active_cycles) begin
                fail_case({case_name, " terminal cycle count was not retained"});
            end
            successful_blocks = successful_blocks + 1;
        end
    endtask

    task automatic run_invalid_scale_case(
        input string      case_name,
        input logic [15:0] scale_bits
    );
        integer wait_cycles;
        begin
            init_vector(scale_bits, 32'h00000000);
            launch_current_block();
            lane_ready_i = 1'b1;
            wait_cycles  = 0;
            while (error_o !== 1'b1) begin
                if (lane_valid_o === 1'b1) begin
                    fail_case({case_name, " published before scale rejection"});
                end
                @(posedge clk_i);
                @(negedge clk_i);
                wait_cycles = wait_cycles + 1;
                if (wait_cycles > 8) begin
                    fail_case({case_name, " scale rejection timeout"});
                end
            end
            check_error_terminal(case_name, 4'h1);
        end
    endtask

    task automatic run_child_flags_case;
        integer wait_cycles;
        begin
            init_vector(16'h3c00, 32'h3f800000);
            for (vector_index = 0; vector_index < 32;
                    vector_index = vector_index + 1) begin
                set_vector_lane(vector_index, 8'h01, 32'h3f800000);
            end
            launch_current_block();
            lane_ready_i = 1'b1;
            wait_cycles  = 0;
            while (!((dut.state_q == ST_MUL_WAIT)
                    && (dut.mul_index_q == 5'd5)
                    && (dut.mul_rsp_valid_w === 1'b1))) begin
                if (lane_valid_o === 1'b1) begin
                    fail_case("child-flags published provisional lanes");
                end
                @(posedge clk_i);
                @(negedge clk_i);
                wait_cycles = wait_cycles + 1;
                if (wait_cycles > 200) begin
                    fail_case("child-flags injection point timeout");
                end
            end

            // Testbench-only fault injection changes the resident child
            // response flags on lane 5; it never calculates a numeric result.
            force dut.mul_rsp_flags_w = 5'b00001;
            @(posedge clk_i);
            @(negedge clk_i);
            release dut.mul_rsp_flags_w;
            check_error_terminal("child-flags", 4'h3);
        end
    endtask

    task automatic run_mid_multiply_reset_case;
        integer wait_cycles;
        integer idle_probe;
        begin
            init_vector(16'h3c00, 32'h3f800000);
            for (vector_index = 0; vector_index < 32;
                    vector_index = vector_index + 1) begin
                set_vector_lane(vector_index, 8'h01, 32'h3f800000);
            end
            launch_current_block();
            lane_ready_i = 1'b1;
            wait_cycles  = 0;
            while (!((dut.state_q == ST_MUL_WAIT)
                    && (dut.mul_index_q == 5'd2))) begin
                if ((lane_valid_o === 1'b1) || (done_o === 1'b1)
                        || (error_o === 1'b1)) begin
                    fail_case("mid-reset transaction published early state");
                end
                @(posedge clk_i);
                @(negedge clk_i);
                wait_cycles = wait_cycles + 1;
                if (wait_cycles > 120) begin
                    fail_case("mid-reset injection point timeout");
                end
            end

            rst_i = 1'b1;
            repeat (2) begin
                @(posedge clk_i);
                @(negedge clk_i);
                if ((ready_o !== 1'b0) || (busy_o !== 1'b0)
                        || (lane_valid_o !== 1'b0) || (done_o !== 1'b0)
                        || (error_o !== 1'b0) || (active_cycles_o !== 16'b0)) begin
                    fail_case("mid-multiply reset did not quiesce outputs");
                end
            end
            rst_i = 1'b0;
            lane_ready_i = 1'b0;

            // Several clean idle cycles exclude a stale child response after
            // reset cancellation; the following success vector proves reuse.
            for (idle_probe = 0; idle_probe < 4; idle_probe = idle_probe + 1) begin
                @(posedge clk_i);
                @(negedge clk_i);
                if ((ready_o !== 1'b1) || (busy_o !== 1'b0)
                        || (lane_valid_o !== 1'b0) || (done_o !== 1'b0)
                        || (error_o !== 1'b0)) begin
                    fail_case("canceled multiply produced stale response");
                end
            end
        end
    endtask

    task automatic run_child_timeout_case;
        integer wait_cycles;
        begin
            init_vector(16'h3c00, 32'h3f800000);
            for (vector_index = 0; vector_index < 32;
                    vector_index = vector_index + 1) begin
                set_vector_lane(vector_index, 8'h01, 32'h3f800000);
            end
            launch_current_block();
            lane_ready_i = 1'b1;
            wait_cycles  = 0;
            while (!((dut.state_q == ST_MUL_WAIT)
                    && (dut.mul_index_q == 5'd3))) begin
                if (lane_valid_o === 1'b1) begin
                    fail_case("child-timeout published provisional lanes");
                end
                @(posedge clk_i);
                @(negedge clk_i);
                wait_cycles = wait_cycles + 1;
                if (wait_cycles > 160) begin
                    fail_case("child-timeout injection point timeout");
                end
            end

            // Suppress only the parent-visible response-valid qualification.
            // The watchdog must poison the block, reset the resident child,
            // and publish zero lanes.
            force dut.mul_rsp_valid_w = 1'b0;
            wait_cycles = 0;
            while (error_o !== 1'b1) begin
                if (lane_valid_o === 1'b1) begin
                    fail_case("child-timeout published a lane");
                end
                @(posedge clk_i);
                @(negedge clk_i);
                wait_cycles = wait_cycles + 1;
                if (wait_cycles > 20) begin
                    fail_case("response watchdog did not fire");
                end
            end
            release dut.mul_rsp_valid_w;
            check_error_terminal("child-timeout", 4'h6);
        end
    endtask

    initial begin
        cycle_count              = 0;
        successful_blocks        = 0;
        expected_error_cases     = 0;
        observed_lane_handshakes = 0;
        vector_index             = 0;
        rst_i                    = 1'b1;
        start_i                  = 1'b0;
        block_i                  = 272'b0;
        lane_ready_i             = 1'b0;
        stimulus_block           = 272'b0;

        repeat (3) @(posedge clk_i);
        @(negedge clk_i);
        if ((ready_o !== 1'b0) || (busy_o !== 1'b0)
                || (lane_valid_o !== 1'b0) || (done_o !== 1'b0)
                || (error_o !== 1'b0) || (active_cycles_o !== 16'b0)) begin
            fail_case("startup reset did not clear protocol state");
        end
        rst_i = 1'b0;

        // Oracle A0: full signed byte decoding and lane order at scale +1.
        init_vector(16'h3c00, 32'h00000000);
        set_vector_lane(0, 8'h80, 32'hc3000000);
        set_vector_lane(1, 8'hff, 32'hbf800000);
        set_vector_lane(2, 8'h00, 32'h00000000);
        set_vector_lane(3, 8'h01, 32'h3f800000);
        set_vector_lane(4, 8'h7f, 32'h42fe0000);
        for (vector_index = 5; vector_index < 32;
                vector_index = vector_index + 1) begin
            case (vector_index % 5)
                0: set_vector_lane(vector_index, 8'h80, 32'hc3000000);
                1: set_vector_lane(vector_index, 8'hff, 32'hbf800000);
                2: set_vector_lane(vector_index, 8'h00, 32'h00000000);
                3: set_vector_lane(vector_index, 8'h01, 32'h3f800000);
                default:
                   set_vector_lane(vector_index, 8'h7f, 32'h42fe0000);
            endcase
        end
        run_success_case("scale-plus-one", 7, 3, 1);

        // Non-finite scale classes fail before issuing or publishing a lane.
        run_invalid_scale_case("scale-positive-inf", 16'h7c00);
        run_invalid_scale_case("scale-quiet-nan", 16'h7e01);

        // A late child flag still poisons all provisional buffered lanes.
        run_child_flags_case();

        // Reset while the shared multiplier owns lane 2, then prove recovery.
        run_mid_multiply_reset_case();

        // Oracle A1: finite negative scale and negative-zero lanes.
        init_vector(16'hc000, 32'h80000000);
        set_vector_lane(0, 8'h80, 32'h43800000);
        set_vector_lane(1, 8'hff, 32'h40000000);
        set_vector_lane(2, 8'h01, 32'hc0000000);
        set_vector_lane(3, 8'h7f, 32'hc37e0000);
        run_success_case("scale-negative-two-after-reset", -1, 0, 0);

        // Suppress one resident child response until the watchdog aborts it.
        run_child_timeout_case();

        // Oracle B0 also proves clean reuse after a child timeout reset.
        init_vector(16'h0001, 32'h00000000);
        set_vector_lane(0, 8'h40, 32'h36800000);
        set_vector_lane(1, 8'h80, 32'hb7000000);
        run_success_case("half-subnormal-after-timeout", -1, 0, 0);

        // Oracle B1: -0 scale must preserve IEEE product sign per q sign.
        init_vector(16'h8000, 32'h80000000);
        set_vector_lane(0, 8'hff, 32'h00000000);
        set_vector_lane(1, 8'h00, 32'h80000000);
        set_vector_lane(2, 8'h01, 32'h80000000);
        run_success_case("negative-zero-sign", 31, 3, 0);

        if (successful_blocks != 4) begin
            fail_case("successful block count mismatch");
        end
        if (expected_error_cases != 4) begin
            fail_case("error case count mismatch");
        end
        if (observed_lane_handshakes != 128) begin
            fail_case("successful lane handshake count was not exactly 128");
        end

        $display("[NPU-Q8-DEQUANT][INFO] success_blocks=%0d error_cases=%0d lane_handshakes=%0d atomic_buffer=1 busy_start=ignored reset=child-cancel timeout=fail-closed",
                 successful_blocks, expected_error_cases,
                 observed_lane_handshakes);
        $display("[NPU-Q8-DEQUANT][PASS]");
        $finish;
    end

endmodule

`default_nettype wire
