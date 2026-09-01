`timescale 1ns/1ps

module tb_q8_scale_accumulator;

    localparam integer MAX_WAIT_CYCLES = 512;

    reg          clk_i;
    reg          rst_i;
    reg          start_i;
    wire         ready_o;
    wire         busy_o;
    reg  [31:0]  block_count_i;
    reg          block_valid_i;
    wire         block_ready_o;
    reg  [271:0] x_block_i;
    reg  [271:0] y_block_i;
    wire         done_o;
    wire         error_o;
    wire [3:0]   error_code_o;
    wire [31:0]  result_bits_o;

    TensorNpuQ8ScaleAccumulator #(
        .MAC_LANES(8)
    ) dut (
        .clk_i         (clk_i),
        .rst_i         (rst_i),
        .start_i       (start_i),
        .ready_o       (ready_o),
        .busy_o        (busy_o),
        .block_count_i (block_count_i),
        .block_valid_i (block_valid_i),
        .block_ready_o (block_ready_o),
        .x_block_i     (x_block_i),
        .y_block_i     (y_block_i),
        .done_o        (done_o),
        .error_o       (error_o),
        .error_code_o  (error_code_o),
        .result_bits_o (result_bits_o)
    );

    always #5 clk_i <= ~clk_i;

    // All stimuli are raw Q8_0/IEEE bit patterns.  Byte i occupies
    // block[16+i*8 +: 8], matching the 2-byte half scale followed by 32 i8s.
    function automatic [271:0] make_zero_block(input [15:0] scale_bits);
        reg [271:0] value;
        begin
            value = 272'd0;
            value[15:0] = scale_bits;
            make_zero_block = value;
        end
    endfunction

    function automatic [271:0] make_single_block(
        input [15:0] scale_bits,
        input [7:0]  q0_bits
    );
        reg [271:0] value;
        begin
            value = 272'd0;
            value[15:0] = scale_bits;
            value[16 +: 8] = q0_bits;
            make_single_block = value;
        end
    endfunction

    function automatic [271:0] make_four_block(
        input [15:0] scale_bits,
        input [7:0]  q_bits
    );
        reg [271:0] value;
        begin
            value = 272'd0;
            value[15:0] = scale_bits;
            value[16 + (0*8) +: 8] = q_bits;
            value[16 + (1*8) +: 8] = q_bits;
            value[16 + (2*8) +: 8] = q_bits;
            value[16 + (3*8) +: 8] = q_bits;
            make_four_block = value;
        end
    endfunction

    // 127^2 + 127^2 + 110^2 + 7^2 + 3^2 + 2^2 + 1^2 = 44421.
    function automatic [271:0] make_tv1_block;
        reg [271:0] value;
        begin
            value = 272'd0;
            value[15:0] = 16'h3c00; // binary16 +1
            value[16 + (0*8) +: 8] = 8'h7f;
            value[16 + (1*8) +: 8] = 8'h7f;
            value[16 + (2*8) +: 8] = 8'h6e;
            value[16 + (3*8) +: 8] = 8'h07;
            value[16 + (4*8) +: 8] = 8'h03;
            value[16 + (5*8) +: 8] = 8'h02;
            value[16 + (6*8) +: 8] = 8'h01;
            make_tv1_block = value;
        end
    endfunction

    // Reassociation discriminator.  The first sixteen lanes contribute
    // (-128)*(-128), and lane 16 contributes 31*1, for sumi=262175.
    function automatic [271:0] make_grouping_x_block;
        reg [271:0] value;
        integer lane;
        begin
            value = 272'd0;
            value[15:0] = 16'h3c01; // dx = 1025/1024
            for (lane = 0; lane < 16; lane = lane + 1) begin
                value[16 + (lane*8) +: 8] = 8'h80;
            end
            value[16 + (16*8) +: 8] = 8'h1f;
            make_grouping_x_block = value;
        end
    endfunction

    function automatic [271:0] make_grouping_y_block;
        reg [271:0] value;
        integer lane;
        begin
            value = 272'd0;
            value[15:0] = 16'h3fff; // dy = 2047/1024
            for (lane = 0; lane < 16; lane = lane + 1) begin
                value[16 + (lane*8) +: 8] = 8'h80;
            end
            value[16 + (16*8) +: 8] = 8'h01;
            make_grouping_y_block = value;
        end
    endfunction

    task automatic step_cycle;
        begin
            @(posedge clk_i);
            #1;
        end
    endtask

    task automatic wait_for_idle;
        integer guard;
        begin
            guard = 0;
            while (!ready_o) begin
                step_cycle();
                guard = guard + 1;
                if (guard >= MAX_WAIT_CYCLES) begin
                    $fatal(1, "timeout waiting for command ready");
                end
            end
        end
    endtask

    task automatic launch_command(input [31:0] count);
        begin
            wait_for_idle();
            block_count_i = count;
            start_i = 1'b1;
            step_cycle();
            start_i = 1'b0;
            if (!busy_o) begin
                $fatal(1, "accepted command did not enter busy/terminal state");
            end
        end
    endtask

    task automatic send_block(
        input [271:0] x_value,
        input [271:0] y_value
    );
        integer guard;
        begin
            x_block_i = x_value;
            y_block_i = y_value;
            block_valid_i = 1'b1;
            guard = 0;

            while (!block_ready_o) begin
                step_cycle();
                guard = guard + 1;
                if (guard >= MAX_WAIT_CYCLES) begin
                    $fatal(1, "timeout waiting for block_ready_o");
                end
            end

            // ready is high before this edge, so exactly one block fires.
            step_cycle();
            block_valid_i = 1'b0;
        end
    endtask

    task automatic send_block_after_backpressure(
        input [271:0] x_value,
        input [271:0] y_value
    );
        integer guard;
        reg saw_backpressure;
        begin
            x_block_i = x_value;
            y_block_i = y_value;
            block_valid_i = 1'b1;
            guard = 0;
            saw_backpressure = 1'b0;

            while (!block_ready_o) begin
                saw_backpressure = 1'b1;
                step_cycle();
                guard = guard + 1;
                if (guard >= MAX_WAIT_CYCLES) begin
                    $fatal(1, "timeout holding a block through backpressure");
                end
            end

            if (!saw_backpressure) begin
                $fatal(1, "block_ready_o did not apply arithmetic backpressure");
            end

            step_cycle();
            block_valid_i = 1'b0;
        end
    endtask

    task automatic expect_terminal(
        input integer case_id,
        input integer expect_error,
        input [3:0] expected_code,
        input [31:0] expected_result
    );
        integer guard;
        begin
            guard = 0;
            while (!done_o) begin
                step_cycle();
                guard = guard + 1;
                if (guard >= MAX_WAIT_CYCLES) begin
                    $fatal(1, "case %0d timed out waiting for terminal pulse",
                           case_id);
                end
            end

            if (error_o !== (expect_error != 0)) begin
                $fatal(1, "case %0d error mismatch: got=%0b expected=%0d",
                       case_id, error_o, expect_error);
            end
            if (error_code_o !== expected_code) begin
                $fatal(1, "case %0d error code mismatch: got=%0d expected=%0d",
                       case_id, error_code_o, expected_code);
            end
            if (result_bits_o !== expected_result) begin
                $fatal(1, "case %0d result mismatch: got=%08x expected=%08x",
                       case_id, result_bits_o, expected_result);
            end
            if (!busy_o) begin
                $fatal(1, "case %0d terminal state was not busy", case_id);
            end
            if (ready_o || block_ready_o) begin
                $fatal(1, "case %0d terminal state leaked ready credit", case_id);
            end

            // DONE/ERROR must last exactly one cycle and return directly IDLE.
            step_cycle();
            if (done_o || error_o) begin
                $fatal(1, "case %0d terminal pulse lasted more than one cycle",
                       case_id);
            end
            if (!ready_o || busy_o || block_ready_o) begin
                $fatal(1, "case %0d did not return to clean IDLE", case_id);
            end
        end
    endtask

    integer watch_cycle;
    reg [271:0] tv1_block;
    reg [271:0] plus_x_block;
    reg [271:0] plus_y_block;
    reg [271:0] one_block;
    reg [271:0] minus_x_block;
    reg [271:0] minus_y_block;

    initial begin
        clk_i          = 1'b0;
        rst_i          = 1'b1;
        start_i        = 1'b0;
        block_count_i  = 32'd0;
        block_valid_i  = 1'b0;
        x_block_i      = 272'd0;
        y_block_i      = 272'd0;

        tv1_block    = make_tv1_block();
        plus_x_block = make_four_block(16'h5c00, 8'h40); // 4 * (+64)
        plus_y_block = make_four_block(16'h5800, 8'h02); // 4 * (+2)
        one_block    = make_single_block(16'h3c00, 8'h01);
        minus_x_block = make_four_block(16'h5c00, 8'hc0); // 4 * (-64)
        minus_y_block = make_four_block(16'h5800, 8'h02); // 4 * (+2)

        step_cycle();
        step_cycle();
        rst_i = 1'b0;
        step_cycle();
        if (!ready_o || busy_o || done_o || error_o) begin
            $fatal(1, "reset did not establish clean IDLE");
        end

        // TV0: zero dot, finite unit scales, one block -> +0.
        launch_command(32'd1);
        send_block(make_zero_block(16'h3c00),
                   make_zero_block(16'h3c00));
        expect_terminal(0, 0, 4'd0, 32'h00000000);

        // TV1: the hand-constructed self-dot is exactly 44421.0f.
        launch_command(32'd1);
        send_block(tv1_block, tv1_block);
        expect_terminal(1, 0, 4'd0, 32'h472d8500);

        // b10507 grouping discriminator.  The required grouping is
        // RN32(262175 * RN32((1025/1024) * (2047/1024))) = 0x490013dc.
        // Reassociating it as RN32(RN32(262175*dx)*dy) gives 0x490013dd.
        launch_command(32'd1);
        send_block(make_grouping_x_block(), make_grouping_y_block());
        expect_terminal(2, 0, 4'd0, 32'h490013dc);

        // Sequential-RN32 discriminator:
        //   [+2^24, +1, -2^24] -> +0
        // while reordering the latter two terms would produce +1.
        launch_command(32'd3);
        send_block(plus_x_block, plus_y_block);

        // A second start while busy must not replace count=3 or clear acc.
        block_count_i = 32'd1;
        start_i = 1'b1;
        step_cycle();
        start_i = 1'b0;
        if (!busy_o || done_o) begin
            $fatal(1, "busy start was not ignored");
        end

        // Present the next block early and hold it stable through backpressure.
        send_block_after_backpressure(one_block, one_block);
        send_block(minus_x_block, minus_y_block);
        expect_terminal(3, 0, 4'd0, 32'h00000000);

        // Finite negative binary16 scales are legal: 1 * (-1) * 1 = -1.
        launch_command(32'd1);
        send_block(make_single_block(16'hbc00, 8'h01),
                   make_single_block(16'h3c00, 8'h01));
        expect_terminal(4, 0, 4'd0, 32'hbf800000);

        // Minimum binary16 subnormal converts exactly to FP32 2^-24.
        launch_command(32'd1);
        send_block(make_single_block(16'h0001, 8'h01),
                   make_single_block(16'h3c00, 8'h01));
        expect_terminal(5, 0, 4'd0, 32'h33800000);

        // A zero count terminates immediately and must accept no block.
        block_valid_i = 1'b1;
        x_block_i = tv1_block;
        y_block_i = tv1_block;
        if (block_ready_o) begin
            $fatal(1, "IDLE illegally advertised block credit");
        end
        launch_command(32'd0);
        if (block_ready_o) begin
            $fatal(1, "invalid-count command accepted a block");
        end
        block_valid_i = 1'b0;
        expect_terminal(6, 1, 4'd1, 32'h00000000);

        // Infinity in either half scale is malformed and cannot publish a
        // partial result.
        launch_command(32'd1);
        send_block(make_zero_block(16'h7c00),
                   make_zero_block(16'h3c00));
        expect_terminal(7, 1, 4'd2, 32'h00000000);

        // Reset in flight cancels the dot/FPU transaction and suppresses any
        // stale terminal pulse after reset release.
        launch_command(32'd1);
        send_block(tv1_block, tv1_block);
        if (!busy_o || done_o) begin
            $fatal(1, "reset-cancel case was not in flight");
        end
        rst_i = 1'b1;
        step_cycle();
        if (done_o || error_o || busy_o || ready_o || block_ready_o) begin
            $fatal(1, "reset did not synchronously cancel without terminal");
        end
        step_cycle();
        rst_i = 1'b0;
        for (watch_cycle = 0; watch_cycle < MAX_WAIT_CYCLES;
             watch_cycle = watch_cycle + 1) begin
            step_cycle();
            if (done_o || error_o) begin
                $fatal(1, "stale terminal pulse appeared after reset cancel");
            end
            if (!ready_o || busy_o || block_ready_o) begin
                $fatal(1, "post-reset IDLE protocol mismatch");
            end
        end

        $display("[NPU-Q8-SCALE-ACC][PASS] cases=9 grouping=b10507 sequential=rn32 terminal=single-cycle reset=cancelled");
        $finish;
    end

endmodule
