`timescale 1ns/1ps

module tb_q8_dot_engine;

    localparam integer EXPECTED_BEATS = 4;
    localparam integer MAX_WAIT_CYCLES = 16;

    // Exact byte semantics copied from tests/vectors/q8_0_reference.json.
    // Packed bit [7:0] is JSON byte 0, so the concatenation is byte-reversed.
    localparam [271:0] TV0_ZERO_BLOCK = 272'd0;
    localparam [271:0] TV1_UNIT_SIGNED_BLOCK = {
        192'd0,
        8'h7f, 8'h40, 8'h3f, 8'h01,
        8'h00, 8'hff, 8'hc0, 8'h81,
        8'h3c, 8'h00
    };

    // Scale raw bits are 0x3555.  The first eight signed quants are
    // [1,1,1,1,1,1,1,-1], followed by 24 zeroes.
    localparam [271:0] CROSS_Y_BLOCK = {
        192'd0,
        8'hff,
        8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01, 8'h01,
        8'h35, 8'h55
    };

    reg clk;
    reg rst;
    reg start;
    reg [271:0] x_block;
    reg [271:0] y_block;

    wire ready;
    wire busy;
    wire done;
    wire signed [31:0] sum;
    wire [15:0] x_scale;
    wire [15:0] y_scale;

    TensorNpuQ8DotEngine #(
        .MAC_LANES(8)
    ) dut (
        .clk_i      (clk),
        .rst_i      (rst),
        .start_i    (start),
        .ready_o    (ready),
        .busy_o     (busy),
        .x_block_i  (x_block),
        .y_block_i  (y_block),
        .done_o     (done),
        .sum_o      (sum),
        .x_scale_o  (x_scale),
        .y_scale_o  (y_scale)
    );

    task automatic fail;
        input string reason;
        begin
            $display("[NPU-Q8-DOT][FAIL] %s", reason);
            $fatal(1);
        end
    endtask

    task automatic check_reset_state;
        begin
            if (!ready || busy || done)
                fail("reset did not restore ready/idle protocol state");
            if (sum !== 32'sd0)
                fail("reset did not clear sum_o");
            if ((x_scale !== 16'h0000) || (y_scale !== 16'h0000))
                fail("reset did not clear scale outputs");
        end
    endtask

    task automatic reset_while_busy;
        begin
            @(negedge clk);
            x_block = TV1_UNIT_SIGNED_BLOCK;
            y_block = TV1_UNIT_SIGNED_BLOCK;
            start = 1'b1;
            @(posedge clk);
            #1;
            if (!busy || ready || done)
                fail("reset test transaction was not accepted");

            @(negedge clk);
            start = 1'b0;
            @(posedge clk);
            #1;
            if (!busy || done)
                fail("reset test transaction did not enter a MAC beat");

            @(negedge clk);
            rst = 1'b1;
            @(posedge clk);
            #1;
            check_reset_state();

            @(negedge clk);
            rst = 1'b0;
            #1;
            check_reset_state();
        end
    endtask

    task automatic run_case;
        input string case_name;
        input [271:0] x_value;
        input [271:0] y_value;
        input signed [31:0] expected_sum;
        input [15:0] expected_x_scale;
        input [15:0] expected_y_scale;
        input inject_busy_start;
        integer observed_cycles;
        begin
            if (!ready || busy || done)
                fail($sformatf("%s: engine was not ready before start", case_name));

            @(negedge clk);
            x_block = x_value;
            y_block = y_value;
            start = 1'b1;
            @(posedge clk);
            #1;
            if (!busy || ready || done)
                fail($sformatf("%s: start was not accepted", case_name));
            if ((x_scale !== expected_x_scale) ||
                (y_scale !== expected_y_scale))
                fail($sformatf("%s: accepted scale bits were not preserved", case_name));

            @(negedge clk);
            start = 1'b0;
            observed_cycles = 0;

            if (inject_busy_start) begin
                // Consume beat 0, then pulse a different transaction during
                // beat 1.  Accepting it would change both scales and the sum.
                @(posedge clk);
                #1;
                observed_cycles = observed_cycles + 1;
                if (!busy || ready || done)
                    fail("busy-start case terminated before the injected pulse");

                @(negedge clk);
                x_block = TV0_ZERO_BLOCK;
                y_block = CROSS_Y_BLOCK;
                start = 1'b1;
                @(posedge clk);
                #1;
                observed_cycles = observed_cycles + 1;
                if (!busy || ready || done)
                    fail("start while busy disturbed the RUN protocol state");
                if ((x_scale !== expected_x_scale) ||
                    (y_scale !== expected_y_scale))
                    fail("start while busy overwrote accepted scales");

                @(negedge clk);
                start = 1'b0;
            end

            while (!done && (observed_cycles < MAX_WAIT_CYCLES)) begin
                @(posedge clk);
                #1;
                observed_cycles = observed_cycles + 1;
            end

            if (!done)
                fail($sformatf("%s: timeout waiting for done", case_name));
            if (observed_cycles != EXPECTED_BEATS)
                fail($sformatf("%s: latency=%0d expected=%0d",
                               case_name, observed_cycles, EXPECTED_BEATS));
            if (busy || !ready)
                fail($sformatf("%s: terminal cycle did not return ready", case_name));
            if (sum !== expected_sum)
                fail($sformatf("%s: sum=0x%08x expected=0x%08x",
                               case_name, sum, expected_sum));
            if ((x_scale !== expected_x_scale) ||
                (y_scale !== expected_y_scale))
                fail($sformatf("%s: terminal scale bits changed", case_name));

            // done_o is a one-cycle pulse; the result and scales remain held.
            @(posedge clk);
            #1;
            if (done)
                fail($sformatf("%s: done lasted more than one cycle", case_name));
            if (busy || !ready)
                fail($sformatf("%s: engine did not remain idle after done", case_name));
            if ((sum !== expected_sum) ||
                (x_scale !== expected_x_scale) ||
                (y_scale !== expected_y_scale))
                fail($sformatf("%s: result was not held after done", case_name));
        end
    endtask

    always #5 clk <= ~clk;

    initial begin
        clk = 1'b0;
        rst = 1'b1;
        start = 1'b0;
        x_block = 272'd0;
        y_block = 272'd0;

        repeat (4) @(posedge clk);
        #1;
        check_reset_state();

        @(negedge clk);
        rst = 1'b0;
        #1;
        check_reset_state();

        reset_while_busy();

        run_case(
            "TV0 zero self-dot",
            TV0_ZERO_BLOCK,
            TV0_ZERO_BLOCK,
            32'sd0,
            16'h0000,
            16'h0000,
            1'b0);

        run_case(
            "TV1 unit-scale signed self-dot with busy start",
            TV1_UNIT_SIGNED_BLOCK,
            TV1_UNIT_SIGNED_BLOCK,
            32'sd44421,
            16'h3c00,
            16'h3c00,
            1'b1);

        // Manual cross oracle, not recomputed by a TB loop:
        // [-127,-64,-1,0,1,63,64,127] dot
        // [1,1,1,1,1,1,1,-1] = -191.
        run_case(
            "signed negative cross-dot",
            TV1_UNIT_SIGNED_BLOCK,
            CROSS_Y_BLOCK,
            -32'sd191,
            16'h3c00,
            16'h3555,
            1'b0);

        $display("[NPU-Q8-DOT][PASS] TV0/TV1 frozen blocks, signed cross-dot, busy-start ignore, reset, done pulse, cycles=%0d",
                 EXPECTED_BEATS);
        $finish;
    end

endmodule
