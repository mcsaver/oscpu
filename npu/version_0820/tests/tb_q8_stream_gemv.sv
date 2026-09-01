`timescale 1ns/1ps
`default_nettype none

// TensorNpuQ8StreamGemv self-checking raw-bit 定向 testbench。
// 数值 oracle 全部是冻结的 IEEE/Q8_0 bit pattern；空泡使用固定伪随机
// 序列。验证环境只驱动/观测 RTL stream，不代算 activation 或 dot。
module tb_q8_stream_gemv;

    localparam logic [7:0] ERROR_NONE                = 8'h00;
    localparam logic [7:0] ERROR_ROW_COUNT_ZERO      = 8'h10;
    localparam logic [7:0] ERROR_BLOCK_COUNT_ZERO    = 8'h11;
    localparam logic [7:0] ERROR_BLOCK_COUNT_EXCEEDS = 8'h12;
    localparam logic [7:0] ERROR_QUANT_NONFINITE     = 8'h21;
    localparam logic [7:0] ERROR_ACC_NONFINITE_SCALE = 8'h32;
    localparam logic [7:0] ERROR_ACTIVATION_STALL    = 8'h40;
    localparam logic [7:0] ERROR_WEIGHT_STALL        = 8'h41;
    localparam logic [7:0] ERROR_RESULT_STALL        = 8'h42;
    localparam logic [7:0] ERROR_COMMAND_TIMEOUT     = 8'h50;

    localparam logic [3:0] STATE_QUANT_WAIT  = 4'd3;
    localparam logic [3:0] STATE_WEIGHT_STREAM = 4'd5;
    localparam logic [3:0] ACC_STATE_DOT_WAIT = 4'd2;
    localparam logic [3:0] QUANT_STATE_D_DIV_WAIT = 4'd3;

    logic clk_i;
    logic rst_i;

    logic         start_i;
    wire          ready_o;
    wire          busy_o;
    logic [31:0]  row_count_i;
    logic [31:0]  block_count_i;
    logic         activation_valid_i;
    wire          activation_ready_o;
    logic [31:0]  activation_bits_i;
    logic         weight_valid_i;
    wire          weight_ready_o;
    logic [271:0] weight_block_i;
    wire          result_valid_o;
    logic         result_ready_i;
    wire [31:0]   result_bits_o;
    wire [31:0]   result_row_index_o;
    wire          done_o;
    wire          error_o;
    wire [7:0]    error_code_o;
    wire [63:0]   active_cycles_o;
    wire [31:0]   activation_words_accepted_o;
    wire [63:0]   weight_blocks_accepted_o;
    wire [31:0]   rows_emitted_o;

    logic         stall_start_i;
    wire          stall_ready_o;
    wire          stall_busy_o;
    logic [31:0]  stall_row_count_i;
    logic [31:0]  stall_block_count_i;
    logic         stall_activation_valid_i;
    wire          stall_activation_ready_o;
    logic [31:0]  stall_activation_bits_i;
    logic         stall_weight_valid_i;
    wire          stall_weight_ready_o;
    logic [271:0] stall_weight_block_i;
    wire          stall_result_valid_o;
    logic         stall_result_ready_i;
    wire [31:0]   stall_result_bits_o;
    wire [31:0]   stall_result_row_index_o;
    wire          stall_done_o;
    wire          stall_error_o;
    wire [7:0]    stall_error_code_o;
    wire [63:0]   stall_active_cycles_o;
    wire [31:0]   stall_activation_words_o;
    wire [63:0]   stall_weight_blocks_o;
    wire [31:0]   stall_rows_o;

    logic         cmd_start_i;
    wire          cmd_ready_o;
    wire          cmd_busy_o;
    logic [31:0]  cmd_row_count_i;
    logic [31:0]  cmd_block_count_i;
    logic         cmd_activation_valid_i;
    wire          cmd_activation_ready_o;
    logic [31:0]  cmd_activation_bits_i;
    logic         cmd_weight_valid_i;
    wire          cmd_weight_ready_o;
    logic [271:0] cmd_weight_block_i;
    wire          cmd_result_valid_o;
    logic         cmd_result_ready_i;
    wire [31:0]   cmd_result_bits_o;
    wire [31:0]   cmd_result_row_index_o;
    wire          cmd_done_o;
    wire          cmd_error_o;
    wire [7:0]    cmd_error_code_o;
    wire [63:0]   cmd_active_cycles_o;
    wire [31:0]   cmd_activation_words_o;
    wire [63:0]   cmd_weight_blocks_o;
    wire [31:0]   cmd_rows_o;

    integer cycle_count;
    integer provisional_rows;
    integer committed_rows;
    integer positive_results;
    integer error_commands;
    integer reset_cancels;

    TensorNpuQ8StreamGemv dut (
        .clk_i                       (clk_i),
        .rst_i                       (rst_i),
        .start_i                     (start_i),
        .ready_o                     (ready_o),
        .busy_o                      (busy_o),
        .row_count_i                 (row_count_i),
        .block_count_i               (block_count_i),
        .activation_valid_i          (activation_valid_i),
        .activation_ready_o          (activation_ready_o),
        .activation_bits_i           (activation_bits_i),
        .weight_valid_i              (weight_valid_i),
        .weight_ready_o              (weight_ready_o),
        .weight_block_i              (weight_block_i),
        .result_valid_o              (result_valid_o),
        .result_ready_i              (result_ready_i),
        .result_bits_o               (result_bits_o),
        .result_row_index_o          (result_row_index_o),
        .done_o                      (done_o),
        .error_o                     (error_o),
        .error_code_o                (error_code_o),
        .active_cycles_o             (active_cycles_o),
        .activation_words_accepted_o (activation_words_accepted_o),
        .weight_blocks_accepted_o    (weight_blocks_accepted_o),
        .rows_emitted_o              (rows_emitted_o)
    );

    // 相对正式 4096-cycle threshold 缩小，仍高于合法 quantizer
    // resident latency；同一实例分别区分 activation/weight/result stall。
    TensorNpuQ8StreamGemv #(
        .MAX_BLOCKS             (4),
        .MAC_LANES              (8),
        .STALL_TIMEOUT_CYCLES   (32'd600),
        .COMMAND_TIMEOUT_CYCLES (64'd10000)
    ) dut_stall (
        .clk_i                       (clk_i),
        .rst_i                       (rst_i),
        .start_i                     (stall_start_i),
        .ready_o                     (stall_ready_o),
        .busy_o                      (stall_busy_o),
        .row_count_i                 (stall_row_count_i),
        .block_count_i               (stall_block_count_i),
        .activation_valid_i          (stall_activation_valid_i),
        .activation_ready_o          (stall_activation_ready_o),
        .activation_bits_i           (stall_activation_bits_i),
        .weight_valid_i              (stall_weight_valid_i),
        .weight_ready_o              (stall_weight_ready_o),
        .weight_block_i              (stall_weight_block_i),
        .result_valid_o              (stall_result_valid_o),
        .result_ready_i              (stall_result_ready_i),
        .result_bits_o               (stall_result_bits_o),
        .result_row_index_o          (stall_result_row_index_o),
        .done_o                      (stall_done_o),
        .error_o                     (stall_error_o),
        .error_code_o                (stall_error_code_o),
        .active_cycles_o             (stall_active_cycles_o),
        .activation_words_accepted_o (stall_activation_words_o),
        .weight_blocks_accepted_o    (stall_weight_blocks_o),
        .rows_emitted_o              (stall_rows_o)
    );

    // 6-cycle command threshold 必须先于 100-cycle phase stall 报 0x50。
    TensorNpuQ8StreamGemv #(
        .MAX_BLOCKS             (2),
        .MAC_LANES              (8),
        .STALL_TIMEOUT_CYCLES   (32'd100),
        .COMMAND_TIMEOUT_CYCLES (64'd6)
    ) dut_command_timeout (
        .clk_i                       (clk_i),
        .rst_i                       (rst_i),
        .start_i                     (cmd_start_i),
        .ready_o                     (cmd_ready_o),
        .busy_o                      (cmd_busy_o),
        .row_count_i                 (cmd_row_count_i),
        .block_count_i               (cmd_block_count_i),
        .activation_valid_i          (cmd_activation_valid_i),
        .activation_ready_o          (cmd_activation_ready_o),
        .activation_bits_i           (cmd_activation_bits_i),
        .weight_valid_i              (cmd_weight_valid_i),
        .weight_ready_o              (cmd_weight_ready_o),
        .weight_block_i              (cmd_weight_block_i),
        .result_valid_o              (cmd_result_valid_o),
        .result_ready_i              (cmd_result_ready_i),
        .result_bits_o               (cmd_result_bits_o),
        .result_row_index_o          (cmd_result_row_index_o),
        .done_o                      (cmd_done_o),
        .error_o                     (cmd_error_o),
        .error_code_o                (cmd_error_code_o),
        .active_cycles_o             (cmd_active_cycles_o),
        .activation_words_accepted_o (cmd_activation_words_o),
        .weight_blocks_accepted_o    (cmd_weight_blocks_o),
        .rows_emitted_o              (cmd_rows_o)
    );

    initial clk_i = 1'b0;
    always #5 clk_i <= ~clk_i;

    always @(posedge clk_i) begin
        cycle_count <= cycle_count + 1;
        if (cycle_count >= 100000) begin
            $display("[NPU-Q8-GEMV][FAIL] global timeout cycle=%0d",
                     cycle_count + 1);
            $fatal(1);
        end

        if (!rst_i) begin
            if (done_o && error_o) begin
                $fatal(1, "main DONE/ERROR overlap");
            end
            if (stall_done_o && stall_error_o) begin
                $fatal(1, "stall DUT DONE/ERROR overlap");
            end
            if (cmd_done_o && cmd_error_o) begin
                $fatal(1, "command DUT DONE/ERROR overlap");
            end
            if (weight_ready_o && (dut.state_q != STATE_WEIGHT_STREAM)) begin
                $fatal(1, "weight credit leaked before activation bank complete");
            end
        end
    end

    function automatic [31:0] tv1_activation_word(input integer lane);
        begin
            case (lane)
                0: tv1_activation_word = 32'hc2fe0000;
                1: tv1_activation_word = 32'hc2800000;
                2: tv1_activation_word = 32'hbf800000;
                3: tv1_activation_word = 32'h00000000;
                4: tv1_activation_word = 32'h3f800000;
                5: tv1_activation_word = 32'h427c0000;
                6: tv1_activation_word = 32'h42800000;
                7: tv1_activation_word = 32'h42fe0000;
                default: tv1_activation_word = 32'h00000000;
            endcase
        end
    endfunction

    function automatic [271:0] make_zero_block(input [15:0] scale_bits);
        reg [271:0] value;
        begin
            value = 272'b0;
            value[15:0] = scale_bits;
            make_zero_block = value;
        end
    endfunction

    // 该循环只构造验证 stimulus，不进入 DUT 硬件。
    function automatic [271:0] make_fill_block(
        input [15:0] scale_bits,
        input [7:0] quant_bits
    );
        reg [271:0] value;
        integer lane;
        begin
            value = 272'b0;
            value[15:0] = scale_bits;
            for (lane = 0; lane < 32; lane = lane + 1) begin
                value[16 + (lane * 8) +: 8] = quant_bits;
            end
            make_fill_block = value;
        end
    endfunction

    function automatic [271:0] make_single_block(
        input [15:0] scale_bits,
        input [7:0] quant_bits
    );
        reg [271:0] value;
        begin
            value = 272'b0;
            value[15:0] = scale_bits;
            value[23:16] = quant_bits;
            make_single_block = value;
        end
    endfunction

    function automatic [271:0] make_tv1_block;
        reg [271:0] value;
        begin
            value = 272'b0;
            value[15:0] = 16'h3c00;
            value[16 + (0 * 8) +: 8] = 8'h81;
            value[16 + (1 * 8) +: 8] = 8'hc0;
            value[16 + (2 * 8) +: 8] = 8'hff;
            value[16 + (3 * 8) +: 8] = 8'h00;
            value[16 + (4 * 8) +: 8] = 8'h01;
            value[16 + (5 * 8) +: 8] = 8'h3f;
            value[16 + (6 * 8) +: 8] = 8'h40;
            value[16 + (7 * 8) +: 8] = 8'h7f;
            make_tv1_block = value;
        end
    endfunction

    task automatic step_cycle;
        begin
            @(posedge clk_i);
            #1;
        end
    endtask

    task automatic fail_main(input string reason);
        begin
            $display("[NPU-Q8-GEMV][FAIL] %s cycle=%0d state=%0d",
                     reason, cycle_count, dut.state_q);
            $fatal(1);
        end
    endtask

    task automatic wait_main_idle;
        integer guard;
        begin
            guard = 0;
            while (ready_o !== 1'b1) begin
                step_cycle();
                guard = guard + 1;
                if (guard > 2000) begin
                    fail_main("timeout waiting for main IDLE");
                end
            end
        end
    endtask

    task automatic launch_main(
        input [31:0] rows,
        input [31:0] blocks,
        output integer launch_cycle
    );
        begin
            wait_main_idle();
            if (activation_ready_o || weight_ready_o || result_valid_o) begin
                fail_main("IDLE leaked stream credit/payload");
            end
            row_count_i = rows;
            block_count_i = blocks;
            @(negedge clk_i);
            start_i = 1'b1;
            step_cycle();
            launch_cycle = cycle_count;
            start_i = 1'b0;

            if (!busy_o || ready_o) begin
                fail_main("accepted start did not enter busy/terminal");
            end
            if ((activation_words_accepted_o != 32'b0)
                || (weight_blocks_accepted_o != 64'b0)
                || (rows_emitted_o != 32'b0)
                || result_valid_o) begin
                fail_main("new command did not clear public stream state");
            end
        end
    endtask

    task automatic send_main_activation(
        input [31:0] bits,
        input integer bubble_cycles,
        input integer probe_busy_start
    );
        integer guard;
        integer bubble;
        reg [31:0] accepted_before;
        reg [31:0] held_rows;
        reg [31:0] held_blocks;
        begin
            guard = 0;
            while (activation_ready_o !== 1'b1) begin
                if (weight_ready_o || result_valid_o) begin
                    fail_main("downstream stream opened during activation phase");
                end
                step_cycle();
                guard = guard + 1;
                if (guard > 1000) begin
                    fail_main("timeout waiting for activation credit");
                end
            end

            for (bubble = 0; bubble < bubble_cycles;
                 bubble = bubble + 1) begin
                if (activation_ready_o !== 1'b1) begin
                    fail_main("activation credit changed during input bubble");
                end
                step_cycle();
            end

            accepted_before = activation_words_accepted_o;
            held_rows = dut.row_count_q;
            held_blocks = dut.block_count_q;
            @(negedge clk_i);
            activation_bits_i = bits;
            activation_valid_i = 1'b1;
            if (probe_busy_start != 0) begin
                row_count_i = 32'd77;
                block_count_i = 32'd77;
                start_i = 1'b1;
            end
            step_cycle();
            activation_valid_i = 1'b0;
            start_i = 1'b0;
            row_count_i = held_rows;
            block_count_i = held_blocks;

            if (activation_words_accepted_o
                != (accepted_before + 32'd1)) begin
                fail_main("activation handshake accounting mismatch");
            end
            if ((dut.row_count_q != held_rows)
                || (dut.block_count_q != held_blocks)) begin
                fail_main("busy activation start changed latched shape");
            end
        end
    endtask

    task automatic send_main_weight(
        input [271:0] block_bits,
        input integer bubble_cycles,
        input integer hold_while_backpressured,
        input integer probe_busy_start
    );
        integer guard;
        integer bubble;
        reg saw_backpressure;
        reg [63:0] accepted_before;
        reg [31:0] held_rows;
        reg [31:0] held_blocks;
        begin
            saw_backpressure = 1'b0;
            guard = 0;

            if (hold_while_backpressured == 0) begin
                while (weight_ready_o !== 1'b1) begin
                    step_cycle();
                    guard = guard + 1;
                    if (guard > 1000) begin
                        fail_main("timeout waiting for weight credit");
                    end
                end
                for (bubble = 0; bubble < bubble_cycles;
                     bubble = bubble + 1) begin
                    if (weight_ready_o !== 1'b1) begin
                        fail_main("weight credit changed during input bubble");
                    end
                    step_cycle();
                end
            end

            accepted_before = weight_blocks_accepted_o;
            held_rows = dut.row_count_q;
            held_blocks = dut.block_count_q;
            @(negedge clk_i);
            weight_block_i = block_bits;
            weight_valid_i = 1'b1;
            if (probe_busy_start != 0) begin
                row_count_i = 32'd91;
                block_count_i = 32'd91;
                start_i = 1'b1;
            end

            guard = 0;
            while (weight_ready_o !== 1'b1) begin
                saw_backpressure = 1'b1;
                step_cycle();
                start_i = 1'b0;
                guard = guard + 1;
                if (weight_block_i !== block_bits) begin
                    fail_main("weight payload changed while backpressured");
                end
                if (guard > 1000) begin
                    fail_main("weight valid hold exceeded guard");
                end
            end

            step_cycle();
            weight_valid_i = 1'b0;
            start_i = 1'b0;
            row_count_i = held_rows;
            block_count_i = held_blocks;

            if (weight_blocks_accepted_o
                != (accepted_before + 64'd1)) begin
                fail_main("weight handshake accounting mismatch");
            end
            if ((hold_while_backpressured != 0) && !saw_backpressure) begin
                fail_main("weight block did not encounter requested backpressure");
            end
            if ((dut.row_count_q != held_rows)
                || (dut.block_count_q != held_blocks)) begin
                fail_main("busy weight start changed latched shape");
            end
        end
    endtask

    task automatic accept_main_result(
        input [31:0] expected_bits,
        input [31:0] expected_row,
        input integer hold_cycles,
        input integer probe_busy_start
    );
        integer guard;
        integer hold_index;
        reg [31:0] held_bits;
        reg [31:0] held_row;
        reg [31:0] emitted_before;
        reg [31:0] shape_rows;
        reg [31:0] shape_blocks;
        begin
            guard = 0;
            result_ready_i = 1'b0;
            while (result_valid_o !== 1'b1) begin
                step_cycle();
                guard = guard + 1;
                if (guard > 1000) begin
                    fail_main("timeout waiting for row result");
                end
            end

            if ((result_bits_o !== expected_bits)
                || (result_row_index_o !== expected_row)) begin
                fail_main($sformatf(
                    "result mismatch row=%0d got=%08x expected=%08x index=%0d",
                    expected_row, result_bits_o, expected_bits,
                    result_row_index_o));
            end

            held_bits = result_bits_o;
            held_row = result_row_index_o;
            emitted_before = rows_emitted_o;
            shape_rows = dut.row_count_q;
            shape_blocks = dut.block_count_q;

            for (hold_index = 0; hold_index < hold_cycles;
                 hold_index = hold_index + 1) begin
                if ((hold_index == 0) && (probe_busy_start != 0)) begin
                    @(negedge clk_i);
                    row_count_i = 32'd123;
                    block_count_i = 32'd123;
                    start_i = 1'b1;
                end
                step_cycle();
                start_i = 1'b0;
                if (!result_valid_o || (result_bits_o !== held_bits)
                    || (result_row_index_o !== held_row)
                    || (rows_emitted_o !== emitted_before)) begin
                    fail_main("result payload/count changed under backpressure");
                end
            end

            row_count_i = shape_rows;
            block_count_i = shape_blocks;
            @(negedge clk_i);
            result_ready_i = 1'b1;
            step_cycle();
            result_ready_i = 1'b0;

            if (rows_emitted_o != (emitted_before + 32'd1)) begin
                fail_main("result handshake accounting mismatch");
            end
            provisional_rows = provisional_rows + 1;
            positive_results = positive_results + 1;
        end
    endtask

    task automatic check_main_terminal(
        input integer expect_error,
        input [7:0] expected_code,
        input integer launch_cycle,
        input [31:0] expected_activation_words,
        input [63:0] expected_weight_blocks,
        input [31:0] expected_rows
    );
        integer guard;
        reg [63:0] expected_active;
        reg [63:0] held_active;
        reg [7:0] held_error_code;
        reg [31:0] held_activation_words;
        reg [63:0] held_weight_blocks;
        reg [31:0] held_rows;
        begin
            guard = 0;
            while (!done_o && !error_o) begin
                step_cycle();
                guard = guard + 1;
                if (guard > 2000) begin
                    fail_main("timeout waiting for main terminal");
                end
            end

            expected_active = {32'b0, cycle_count[31:0]}
                            - {32'b0, launch_cycle[31:0]} + 64'd1;
            if (expect_error != 0) begin
                if (!error_o || done_o || (error_code_o !== expected_code)) begin
                    fail_main($sformatf(
                        "error terminal mismatch got=%02x expected=%02x",
                        error_code_o, expected_code));
                end
                provisional_rows = 0;
                error_commands = error_commands + 1;
            end else begin
                if (!done_o || error_o || (error_code_o !== ERROR_NONE)) begin
                    fail_main("success terminal mismatch");
                end
                committed_rows = committed_rows + provisional_rows;
                provisional_rows = 0;
            end

            if ((active_cycles_o !== expected_active)
                || (activation_words_accepted_o
                    !== expected_activation_words)
                || (weight_blocks_accepted_o !== expected_weight_blocks)
                || (rows_emitted_o !== expected_rows)
                || result_valid_o || ready_o || !busy_o
                || activation_ready_o || weight_ready_o) begin
                fail_main($sformatf(
                    "terminal accounting/protocol mismatch active=%0d/%0d a=%0d/%0d w=%0d/%0d r=%0d/%0d",
                    active_cycles_o, expected_active,
                    activation_words_accepted_o, expected_activation_words,
                    weight_blocks_accepted_o, expected_weight_blocks,
                    rows_emitted_o, expected_rows));
            end

            held_active = active_cycles_o;
            held_error_code = error_code_o;
            held_activation_words = activation_words_accepted_o;
            held_weight_blocks = weight_blocks_accepted_o;
            held_rows = rows_emitted_o;

            // terminal busy 拍中的 start 必须被忽略；该 posedge 同时保证
            // ERROR 的 child reset 至少覆盖一个完整同步边沿。
            @(negedge clk_i);
            row_count_i = 32'd17;
            block_count_i = 32'd17;
            start_i = 1'b1;
            step_cycle();
            start_i = 1'b0;

            if (!ready_o || busy_o || done_o || error_o
                || (active_cycles_o !== held_active)
                || (error_code_o !== held_error_code)
                || (activation_words_accepted_o
                    !== held_activation_words)
                || (weight_blocks_accepted_o !== held_weight_blocks)
                || (rows_emitted_o !== held_rows)) begin
                fail_main("terminal was not single-cycle or busy start restarted");
            end
        end
    endtask

    task automatic run_positive_m2_b2;
        integer launch_cycle;
        integer lane;
        integer bubble;
        reg [271:0] tv1_block;
        reg [271:0] plus_one_block;
        reg [271:0] plus_two_half_block;
        reg [271:0] minus_two_one_block;
        begin
            tv1_block = make_tv1_block();
            plus_one_block = make_fill_block(16'h3c00, 8'h01);
            plus_two_half_block = make_fill_block(16'h3800, 8'h02);
            minus_two_one_block = make_fill_block(16'hc000, 8'h01);

            launch_main(32'd2, 32'd2, launch_cycle);
            for (lane = 0; lane < 64; lane = lane + 1) begin
                bubble = ((lane * 13 + 7) % 4 == 0) ? 1 : 0;
                if (lane < 32) begin
                    send_main_activation(tv1_activation_word(lane), bubble,
                                         (lane == 5) ? 1 : 0);
                end else begin
                    send_main_activation(32'h42fe0000, bubble, 0);
                end
            end

            if ((activation_words_accepted_o != 32'd64)
                || weight_ready_o) begin
                fail_main("activation census/weight phase boundary mismatch");
            end

            send_main_weight(tv1_block, 1, 0, 0);
            send_main_weight(plus_one_block, 0, 1, 1);
            accept_main_result(32'h473d6500, 32'd0, 3, 1);

            send_main_weight(plus_two_half_block, 2, 0, 0);
            send_main_weight(minus_two_one_block, 0, 1, 1);
            accept_main_result(32'hc5fc0800, 32'd1, 4, 1);
            check_main_terminal(0, ERROR_NONE, launch_cycle,
                                32'd64, 64'd4, 32'd2);

            if (committed_rows != 2) begin
                fail_main("DONE did not commit exactly two provisional rows");
            end
        end
    endtask

    task automatic run_signed_minus128;
        integer launch_cycle;
        integer lane;
        begin
            launch_main(32'd1, 32'd1, launch_cycle);
            for (lane = 0; lane < 32; lane = lane + 1) begin
                send_main_activation((lane == 0)
                                     ? 32'h42fe0000 : 32'h00000000,
                                     (((lane * 5 + 1) % 7) == 0) ? 1 : 0,
                                     0);
            end
            send_main_weight(make_single_block(16'h3c00, 8'h80),
                             0, 0, 0);
            accept_main_result(32'hc67e0000, 32'd0, 1, 0);
            check_main_terminal(0, ERROR_NONE, launch_cycle,
                                32'd32, 64'd1, 32'd1);
        end
    endtask

    task automatic run_shape_error(
        input [31:0] rows,
        input [31:0] blocks,
        input [7:0] expected_code
    );
        integer launch_cycle;
        begin
            activation_valid_i = 1'b1;
            weight_valid_i = 1'b1;
            result_ready_i = 1'b1;
            launch_main(rows, blocks, launch_cycle);
            if (activation_ready_o || weight_ready_o || result_valid_o) begin
                fail_main("invalid shape exposed stream handshake");
            end
            activation_valid_i = 1'b0;
            weight_valid_i = 1'b0;
            result_ready_i = 1'b0;
            check_main_terminal(1, expected_code, launch_cycle,
                                32'd0, 64'd0, 32'd0);
        end
    endtask

    task automatic run_late_activation_nonfinite;
        integer launch_cycle;
        integer lane;
        begin
            launch_main(32'd1, 32'd1, launch_cycle);
            for (lane = 0; lane < 31; lane = lane + 1) begin
                send_main_activation(32'h00000000,
                                     (((lane * 9 + 2) % 5) == 0) ? 1 : 0,
                                     0);
            end
            send_main_activation(32'h7fc12345, 0, 0);
            check_main_terminal(1, ERROR_QUANT_NONFINITE, launch_cycle,
                                32'd32, 64'd0, 32'd0);
        end
    endtask

    task automatic run_provisional_poison;
        integer launch_cycle;
        integer lane;
        integer committed_before;
        begin
            committed_before = committed_rows;
            launch_main(32'd2, 32'd1, launch_cycle);
            for (lane = 0; lane < 32; lane = lane + 1) begin
                send_main_activation(tv1_activation_word(lane),
                                     (((lane * 3 + 1) % 6) == 0) ? 1 : 0,
                                     0);
            end
            send_main_weight(make_tv1_block(), 0, 0, 0);
            accept_main_result(32'h472d8500, 32'd0, 3, 0);
            if (provisional_rows != 1) begin
                fail_main("first poisoned-command row was not provisional");
            end
            send_main_weight(make_zero_block(16'h7c00), 0, 0, 0);
            check_main_terminal(1, ERROR_ACC_NONFINITE_SCALE, launch_cycle,
                                32'd32, 64'd2, 32'd1);
            if ((provisional_rows != 0)
                || (committed_rows != committed_before)) begin
                fail_main("ERROR did not discard the complete provisional set");
            end
        end
    endtask

    // Distinguishes the parent FSM from the historical implementation that
    // observed accumulator terminal only after the last block had been sent.
    // With B=2 an error on block 0 occurs while the parent is still in
    // WEIGHT_STREAM; it must be consumed immediately rather than degrade into
    // a later producer-stall timeout.
    task automatic run_early_block_error;
        integer launch_cycle;
        integer lane;
        begin
            launch_main(32'd1, 32'd2, launch_cycle);
            for (lane = 0; lane < 64; lane = lane + 1) begin
                send_main_activation(32'h00000000,
                                     (((lane * 7 + 3) % 11) == 0) ? 1 : 0,
                                     0);
            end
            send_main_weight(make_zero_block(16'h7c00), 0, 0, 0);
            check_main_terminal(1, ERROR_ACC_NONFINITE_SCALE, launch_cycle,
                                32'd64, 64'd1, 32'd0);
        end
    endtask

    task automatic run_quantizer_reset_cancel;
        integer launch_cycle;
        integer lane;
        integer watch;
        begin
            launch_main(32'd1, 32'd1, launch_cycle);
            if (launch_cycle <= 0) begin
                fail_main("quantizer reset command launch cycle invalid");
            end
            for (lane = 0; lane < 32; lane = lane + 1) begin
                send_main_activation((lane == 0)
                                     ? 32'h42fe0000 : 32'h00000000,
                                     0, 0);
            end

            watch = 0;
            while (dut.u_quantizer.state_q != QUANT_STATE_D_DIV_WAIT) begin
                step_cycle();
                watch = watch + 1;
                if (watch > 200) begin
                    fail_main("quantizer divider transaction not observed");
                end
            end
            if (dut.state_q != STATE_QUANT_WAIT) begin
                fail_main("parent was not waiting for quantizer at reset");
            end

            @(negedge clk_i);
            rst_i = 1'b1;
            step_cycle();
            if (ready_o || busy_o || done_o || error_o || result_valid_o
                || (activation_words_accepted_o != 32'b0)
                || (weight_blocks_accepted_o != 64'b0)
                || (rows_emitted_o != 32'b0)) begin
                fail_main("reset did not cancel quantizer transaction");
            end
            step_cycle();
            @(negedge clk_i);
            rst_i = 1'b0;
            for (watch = 0; watch < 80; watch = watch + 1) begin
                step_cycle();
                if (!ready_o || busy_o || done_o || error_o
                    || result_valid_o) begin
                    fail_main("stale quantizer response after reset");
                end
            end
            reset_cancels = reset_cancels + 1;
        end
    endtask

    task automatic run_accumulator_reset_cancel;
        integer launch_cycle;
        integer lane;
        integer watch;
        begin
            launch_main(32'd1, 32'd1, launch_cycle);
            if (launch_cycle <= 0) begin
                fail_main("accumulator reset command launch cycle invalid");
            end
            for (lane = 0; lane < 32; lane = lane + 1) begin
                send_main_activation(32'h00000000, 0, 0);
            end
            send_main_weight(make_zero_block(16'h3c00), 0, 0, 0);
            if (dut.u_accumulator.state_q != ACC_STATE_DOT_WAIT) begin
                fail_main("accumulator resident dot transaction not observed");
            end

            @(negedge clk_i);
            rst_i = 1'b1;
            step_cycle();
            if (ready_o || busy_o || done_o || error_o || result_valid_o
                || (activation_words_accepted_o != 32'b0)
                || (weight_blocks_accepted_o != 64'b0)
                || (rows_emitted_o != 32'b0)) begin
                fail_main("reset did not cancel accumulator transaction");
            end
            step_cycle();
            @(negedge clk_i);
            rst_i = 1'b0;
            for (watch = 0; watch < 80; watch = watch + 1) begin
                step_cycle();
                if (!ready_o || busy_o || done_o || error_o
                    || result_valid_o) begin
                    fail_main("stale accumulator response after reset");
                end
            end
            reset_cancels = reset_cancels + 1;
        end
    endtask

    task automatic stall_wait_idle;
        integer guard;
        begin
            guard = 0;
            while (stall_ready_o !== 1'b1) begin
                step_cycle();
                guard = guard + 1;
                if (guard > 2000) begin
                    $fatal(1, "stall DUT idle timeout");
                end
            end
        end
    endtask

    task automatic stall_launch;
        begin
            stall_wait_idle();
            stall_row_count_i = 32'd1;
            stall_block_count_i = 32'd1;
            @(negedge clk_i);
            stall_start_i = 1'b1;
            step_cycle();
            stall_start_i = 1'b0;
            if (!stall_busy_o || stall_ready_o) begin
                $fatal(1, "stall DUT start failed");
            end
        end
    endtask

    task automatic stall_send_zero_activation;
        integer lane;
        integer guard;
        begin
            for (lane = 0; lane < 32; lane = lane + 1) begin
                guard = 0;
                while (stall_activation_ready_o !== 1'b1) begin
                    step_cycle();
                    guard = guard + 1;
                    if (guard > 1000) begin
                        $fatal(1, "stall DUT activation credit timeout");
                    end
                end
                @(negedge clk_i);
                stall_activation_bits_i = 32'b0;
                stall_activation_valid_i = 1'b1;
                step_cycle();
                stall_activation_valid_i = 1'b0;
            end
        end
    endtask

    task automatic stall_send_zero_weight;
        integer guard;
        begin
            guard = 0;
            while (stall_weight_ready_o !== 1'b1) begin
                step_cycle();
                guard = guard + 1;
                if (guard > 1000) begin
                    $fatal(1, "stall DUT weight credit timeout");
                end
            end
            @(negedge clk_i);
            stall_weight_block_i = make_zero_block(16'h3c00);
            stall_weight_valid_i = 1'b1;
            step_cycle();
            stall_weight_valid_i = 1'b0;
        end
    endtask

    task automatic stall_expect_error(
        input [7:0] expected_code,
        input [31:0] expected_activation_words,
        input [63:0] expected_weight_blocks,
        input [31:0] expected_rows
    );
        integer guard;
        begin
            guard = 0;
            while (!stall_error_o && !stall_done_o) begin
                step_cycle();
                guard = guard + 1;
                if (guard > 12000) begin
                    $fatal(1, "stall DUT terminal timeout");
                end
            end
            if (!stall_error_o || stall_done_o
                || (stall_error_code_o !== expected_code)
                || stall_result_valid_o
                || (stall_result_bits_o != 32'b0)
                || (stall_result_row_index_o != 32'b0)
                || (stall_activation_words_o !== expected_activation_words)
                || (stall_weight_blocks_o !== expected_weight_blocks)
                || (stall_rows_o !== expected_rows)
                || (stall_active_cycles_o == 64'b0)) begin
                $fatal(1,
                    "stall DUT error mismatch code=%02x expected=%02x a=%0d w=%0d r=%0d",
                    stall_error_code_o, expected_code,
                    stall_activation_words_o, stall_weight_blocks_o,
                    stall_rows_o);
            end
            step_cycle();
            if (!stall_ready_o || stall_busy_o
                || stall_error_o || stall_done_o) begin
                $fatal(1, "stall DUT terminal/reset recovery failed");
            end
        end
    endtask

    task automatic run_watchdog_matrix;
        integer guard;
        begin
            // activation producer不发送任何 word，phase threshold报0x40。
            stall_launch();
            guard = 0;
            while (stall_activation_ready_o !== 1'b1) begin
                step_cycle();
                guard = guard + 1;
                if (guard > 20) begin
                    $fatal(1, "activation-stall LOAD32 not reached");
                end
            end
            stall_expect_error(ERROR_ACTIVATION_STALL,
                               32'd0, 64'd0, 32'd0);

            // activation成功后不发送weight，必须区分为0x41。
            stall_launch();
            stall_send_zero_activation();
            guard = 0;
            while ((dut_stall.state_q != STATE_WEIGHT_STREAM)
                   && !stall_error_o) begin
                step_cycle();
                guard = guard + 1;
                if (guard > 1000) begin
                    $fatal(1, "weight-stall phase not reached");
                end
            end
            stall_expect_error(ERROR_WEIGHT_STALL,
                               32'd32, 64'd0, 32'd0);

            // 在真实 RESULT_HOLD 把 command counter推到边界，证明0x50
            // 优先于尚未到阈值的 result stall。
            stall_launch();
            stall_send_zero_activation();
            stall_send_zero_weight();
            guard = 0;
            while (stall_result_valid_o !== 1'b1) begin
                step_cycle();
                guard = guard + 1;
                if (guard > 1000) begin
                    $fatal(1, "command-priority RESULT_HOLD not reached");
                end
            end
            force dut_stall.command_cycles_q = 64'd9999;
            step_cycle();
            release dut_stall.command_cycles_q;
            stall_expect_error(ERROR_COMMAND_TIMEOUT,
                               32'd32, 64'd1, 32'd0);

            // 相同 RESULT_HOLD 不改 command counter，600-cycle consumer
            // stall先到，必须精确报0x42且不伪增rows。
            stall_launch();
            stall_send_zero_activation();
            stall_send_zero_weight();
            guard = 0;
            while (stall_result_valid_o !== 1'b1) begin
                step_cycle();
                guard = guard + 1;
                if (guard > 1000) begin
                    $fatal(1, "result-stall RESULT_HOLD not reached");
                end
            end
            stall_expect_error(ERROR_RESULT_STALL,
                               32'd32, 64'd1, 32'd0);
        end
    endtask

    task automatic run_small_command_timeout;
        integer guard;
        begin
            while (cmd_ready_o !== 1'b1) begin
                step_cycle();
            end
            cmd_row_count_i = 32'd1;
            cmd_block_count_i = 32'd1;
            @(negedge clk_i);
            cmd_start_i = 1'b1;
            step_cycle();
            cmd_start_i = 1'b0;

            guard = 0;
            while (!cmd_error_o && !cmd_done_o) begin
                step_cycle();
                guard = guard + 1;
                if (guard > 20) begin
                    $fatal(1, "small command timeout did not terminate");
                end
            end
            if (!cmd_error_o || cmd_done_o
                || (cmd_error_code_o !== ERROR_COMMAND_TIMEOUT)
                || (cmd_active_cycles_o !== 64'd6)
                || (cmd_activation_words_o != 32'b0)
                || (cmd_weight_blocks_o != 64'b0)
                || (cmd_rows_o != 32'b0)
                || cmd_activation_ready_o || cmd_weight_ready_o
                || cmd_result_valid_o
                || (cmd_result_bits_o != 32'b0)
                || (cmd_result_row_index_o != 32'b0)) begin
                $fatal(1,
                    "command timeout priority/accounting mismatch code=%02x active=%0d",
                    cmd_error_code_o, cmd_active_cycles_o);
            end
            step_cycle();
            if (!cmd_ready_o || cmd_busy_o || cmd_error_o || cmd_done_o) begin
                $fatal(1, "command timeout did not recover through child reset");
            end
        end
    endtask

    integer startup_watch;

    initial begin
        cycle_count = 0;
        provisional_rows = 0;
        committed_rows = 0;
        positive_results = 0;
        error_commands = 0;
        reset_cancels = 0;

        rst_i = 1'b1;
        start_i = 1'b0;
        row_count_i = 32'b0;
        block_count_i = 32'b0;
        activation_valid_i = 1'b0;
        activation_bits_i = 32'b0;
        weight_valid_i = 1'b0;
        weight_block_i = 272'b0;
        result_ready_i = 1'b0;

        stall_start_i = 1'b0;
        stall_row_count_i = 32'b0;
        stall_block_count_i = 32'b0;
        stall_activation_valid_i = 1'b0;
        stall_activation_bits_i = 32'b0;
        stall_weight_valid_i = 1'b0;
        stall_weight_block_i = 272'b0;
        stall_result_ready_i = 1'b0;

        cmd_start_i = 1'b0;
        cmd_row_count_i = 32'b0;
        cmd_block_count_i = 32'b0;
        cmd_activation_valid_i = 1'b0;
        cmd_activation_bits_i = 32'b0;
        cmd_weight_valid_i = 1'b0;
        cmd_weight_block_i = 272'b0;
        cmd_result_ready_i = 1'b0;

        repeat (3) step_cycle();
        if (ready_o || busy_o || done_o || error_o
            || activation_ready_o || weight_ready_o || result_valid_o) begin
            fail_main("reset output protocol mismatch");
        end
        @(negedge clk_i);
        rst_i = 1'b0;
        step_cycle();
        if (!ready_o || busy_o || done_o || error_o
            || !stall_ready_o || !cmd_ready_o) begin
            fail_main("IDLE did not open after reset");
        end

        if ((dut.MAX_BLOCKS != 128)
            || (dut.STALL_TIMEOUT_CYCLES != 32'd4096)
            || (dut.COMMAND_TIMEOUT_CYCLES != 64'd1000000000)) begin
            fail_main("formal parameter defaults changed");
        end

        run_positive_m2_b2();
        run_signed_minus128();

        run_shape_error(32'd0, 32'd1, ERROR_ROW_COUNT_ZERO);
        run_shape_error(32'd1, 32'd0, ERROR_BLOCK_COUNT_ZERO);
        run_shape_error(32'd1, 32'd129, ERROR_BLOCK_COUNT_EXCEEDS);

        run_late_activation_nonfinite();
        run_provisional_poison();
        run_early_block_error();
        run_quantizer_reset_cancel();
        run_accumulator_reset_cancel();

        run_watchdog_matrix();
        run_small_command_timeout();

        // reset/ERROR后留出窗口，禁止任何 child stale terminal污染IDLE。
        for (startup_watch = 0; startup_watch < 80;
             startup_watch = startup_watch + 1) begin
            step_cycle();
            if (!ready_o || busy_o || done_o || error_o || result_valid_o
                || !stall_ready_o || stall_busy_o
                || !cmd_ready_o || cmd_busy_o) begin
                fail_main("final stale-response observation failed");
            end
        end

        if ((positive_results != 4)
            || (error_commands != 6)
            || (reset_cancels != 2)
            || (committed_rows != 3)
            || (provisional_rows != 0)) begin
            fail_main($sformatf(
                "census mismatch results=%0d errors=%0d resets=%0d committed=%0d provisional=%0d",
                positive_results, error_commands, reset_cancels,
                committed_rows, provisional_rows));
        end

        $display("[NPU-Q8-GEMV][PASS] oracle=473d6500,c5fc0800 signed_i8=-128 rows=ordered backpressure=stable counts=64/4/2 poison=atomic early_child_terminal=caught reset=child-cancel watchdog=40,41,42,50 timeout_priority=command");
        $finish;
    end

endmodule

`default_nettype wire
