`timescale 1ns/1ps
`default_nettype none

// Q8_0 reference quantizer 的 self-checking raw-bit testbench。
// 所有 FP oracle 都是冻结的 IEEE-754 bits；不使用 real/shortreal、DPI
// 或 host 浮点。主 DUT 使用正式 48/16/512 timeout；三个参数化 DUT 只用来
// 证明相同 timeout 电路在边界到达时 fail-closed 且不发布 partial block。
module tb_q8_reference_quantizer;

    localparam logic [3:0] ERROR_NONE            = 4'h0;
    localparam logic [3:0] ERROR_INPUT_NONFINITE = 4'h1;
    localparam logic [3:0] ERROR_SCALE_PACK      = 4'h2;
    localparam logic [3:0] ERROR_DIV_NUMERIC     = 4'h3;
    localparam logic [3:0] ERROR_DIV_TIMEOUT     = 4'h4;
    localparam logic [3:0] ERROR_MUL_NUMERIC     = 4'h5;
    localparam logic [3:0] ERROR_MUL_TIMEOUT     = 4'h6;
    localparam logic [3:0] ERROR_RMM             = 4'h7;
    localparam logic [3:0] ERROR_COMMAND_TIMEOUT = 4'h8;

    localparam logic [3:0] STATE_D_DIV_WAIT  = 4'd3;
    localparam logic [3:0] STATE_MUL_WAIT    = 4'd8;
    localparam logic [3:0] STATE_RMM_STORE   = 4'd9;

    logic clk_i;
    logic rst_i;

    logic         start_i;
    wire          ready_o;
    wire          busy_o;
    logic         input_valid_i;
    wire          input_ready_o;
    logic [31:0]  input_bits_i;
    wire          done_o;
    wire          error_o;
    wire [3:0]    error_code_o;
    wire [271:0]  block_o;
    wire [15:0]   active_cycles_o;

    logic         div_to_start_i;
    wire          div_to_ready_o;
    wire          div_to_busy_o;
    logic         div_to_input_valid_i;
    wire          div_to_input_ready_o;
    logic [31:0]  div_to_input_bits_i;
    wire          div_to_done_o;
    wire          div_to_error_o;
    wire [3:0]    div_to_error_code_o;
    wire [271:0]  div_to_block_o;
    wire [15:0]   div_to_active_cycles_o;

    logic         mul_to_start_i;
    wire          mul_to_ready_o;
    wire          mul_to_busy_o;
    logic         mul_to_input_valid_i;
    wire          mul_to_input_ready_o;
    logic [31:0]  mul_to_input_bits_i;
    wire          mul_to_done_o;
    wire          mul_to_error_o;
    wire [3:0]    mul_to_error_code_o;
    wire [271:0]  mul_to_block_o;
    wire [15:0]   mul_to_active_cycles_o;

    logic         cmd_to_start_i;
    wire          cmd_to_ready_o;
    wire          cmd_to_busy_o;
    logic         cmd_to_input_valid_i;
    wire          cmd_to_input_ready_o;
    logic [31:0]  cmd_to_input_bits_i;
    wire          cmd_to_done_o;
    wire          cmd_to_error_o;
    wire [3:0]    cmd_to_error_code_o;
    wire [271:0]  cmd_to_block_o;
    wire [15:0]   cmd_to_active_cycles_o;

    logic [31:0] main_words [0:31];
    logic [271:0] expected_block;

    integer cycle_count;
    integer completed_successes;
    integer completed_errors;
    integer check_index;

    TensorNpuQ8ReferenceQuantizer dut (
        .clk_i           (clk_i),
        .rst_i           (rst_i),
        .start_i         (start_i),
        .ready_o         (ready_o),
        .busy_o          (busy_o),
        .input_valid_i   (input_valid_i),
        .input_ready_o   (input_ready_o),
        .input_bits_i    (input_bits_i),
        .done_o          (done_o),
        .error_o         (error_o),
        .error_code_o    (error_code_o),
        .block_o         (block_o),
        .active_cycles_o (active_cycles_o)
    );

    TensorNpuQ8ReferenceQuantizer #(
        .DIV_TIMEOUT_CYCLES     (1),
        .MUL_TIMEOUT_CYCLES     (16),
        .COMMAND_TIMEOUT_CYCLES (512)
    ) dut_div_timeout (
        .clk_i           (clk_i),
        .rst_i           (rst_i),
        .start_i         (div_to_start_i),
        .ready_o         (div_to_ready_o),
        .busy_o          (div_to_busy_o),
        .input_valid_i   (div_to_input_valid_i),
        .input_ready_o   (div_to_input_ready_o),
        .input_bits_i    (div_to_input_bits_i),
        .done_o          (div_to_done_o),
        .error_o         (div_to_error_o),
        .error_code_o    (div_to_error_code_o),
        .block_o         (div_to_block_o),
        .active_cycles_o (div_to_active_cycles_o)
    );

    TensorNpuQ8ReferenceQuantizer #(
        .DIV_TIMEOUT_CYCLES     (48),
        .MUL_TIMEOUT_CYCLES     (1),
        .COMMAND_TIMEOUT_CYCLES (512)
    ) dut_mul_timeout (
        .clk_i           (clk_i),
        .rst_i           (rst_i),
        .start_i         (mul_to_start_i),
        .ready_o         (mul_to_ready_o),
        .busy_o          (mul_to_busy_o),
        .input_valid_i   (mul_to_input_valid_i),
        .input_ready_o   (mul_to_input_ready_o),
        .input_bits_i    (mul_to_input_bits_i),
        .done_o          (mul_to_done_o),
        .error_o         (mul_to_error_o),
        .error_code_o    (mul_to_error_code_o),
        .block_o         (mul_to_block_o),
        .active_cycles_o (mul_to_active_cycles_o)
    );

    TensorNpuQ8ReferenceQuantizer #(
        .DIV_TIMEOUT_CYCLES     (48),
        .MUL_TIMEOUT_CYCLES     (16),
        .COMMAND_TIMEOUT_CYCLES (8)
    ) dut_command_timeout (
        .clk_i           (clk_i),
        .rst_i           (rst_i),
        .start_i         (cmd_to_start_i),
        .ready_o         (cmd_to_ready_o),
        .busy_o          (cmd_to_busy_o),
        .input_valid_i   (cmd_to_input_valid_i),
        .input_ready_o   (cmd_to_input_ready_o),
        .input_bits_i    (cmd_to_input_bits_i),
        .done_o          (cmd_to_done_o),
        .error_o         (cmd_to_error_o),
        .error_code_o    (cmd_to_error_code_o),
        .block_o         (cmd_to_block_o),
        .active_cycles_o (cmd_to_active_cycles_o)
    );

    initial clk_i = 1'b0;
    always #5 clk_i <= ~clk_i;

    always @(posedge clk_i) begin
        cycle_count <= cycle_count + 1;
        if (cycle_count >= 12000) begin
            $display("[NPU-Q8-QUANT][FAIL] global timeout cycle=%0d",
                     cycle_count + 1);
            $fatal(1);
        end

        if (!rst_i) begin
            if (dut.div_rsp_ready_w
                && (dut.state_q != 4'd3) && (dut.state_q != 4'd6)) begin
                $display("[NPU-Q8-QUANT][FAIL] divider response ready outside WAIT state=%0d",
                         dut.state_q);
                $fatal(1);
            end
            if (dut.mul_rsp_ready_w && (dut.state_q != STATE_MUL_WAIT)) begin
                $display("[NPU-Q8-QUANT][FAIL] multiplier response ready outside WAIT state=%0d",
                         dut.state_q);
                $fatal(1);
            end
            if (done_o && error_o) begin
                $display("[NPU-Q8-QUANT][FAIL] done/error overlap");
                $fatal(1);
            end
        end
    end

    task automatic fail_case(input string reason);
        begin
            $display("[NPU-Q8-QUANT][FAIL] %s cycle=%0d state=%0d",
                     reason, cycle_count, dut.state_q);
            $fatal(1);
        end
    endtask

    task automatic clear_main_words;
        integer index;
        begin
            for (index = 0; index < 32; index = index + 1) begin
                main_words[index] = 32'h00000000;
            end
        end
    endtask

    task automatic start_main_command(output integer fire_cycle);
        begin
            while (ready_o !== 1'b1) begin
                @(negedge clk_i);
            end
            start_i = 1'b1;
            @(posedge clk_i);
            @(negedge clk_i);
            fire_cycle = cycle_count;
            start_i = 1'b0;

            if ((ready_o !== 1'b0) || (busy_o !== 1'b1)
                || (input_ready_o !== 1'b1)) begin
                fail_case("start handshake did not enter LOAD32");
            end
            if ((block_o !== 272'b0) || (active_cycles_o !== 16'b0)
                || (error_code_o !== ERROR_NONE)) begin
                fail_case("command initialization did not clear public result");
            end
        end
    endtask

    task automatic load_main_words(input integer probe_busy_start);
        integer index;
        begin
            for (index = 0; index < 32; index = index + 1) begin
                while (input_ready_o !== 1'b1) begin
                    @(negedge clk_i);
                end
                input_bits_i  = main_words[index];
                input_valid_i = 1'b1;
                if ((probe_busy_start != 0) && (index == 3)) begin
                    start_i = 1'b1;
                end
                @(posedge clk_i);
                @(negedge clk_i);
                input_valid_i = 1'b0;
                start_i       = 1'b0;

                if ((index != 31) && (input_ready_o !== 1'b1)) begin
                    fail_case($sformatf("input channel closed at word=%0d", index));
                end
                if ((index == 7) && (probe_busy_start != 0)) begin
                    // 一个空泡证明 LOAD32 ready 不依赖 valid。
                    @(posedge clk_i);
                    @(negedge clk_i);
                    if (input_ready_o !== 1'b1) begin
                        fail_case("input ready dropped during intentional bubble");
                    end
                end
            end
            if (input_ready_o !== 1'b0) begin
                fail_case("accepted more than exactly 32 input words");
            end
        end
    endtask

    task automatic check_terminal_accounting(
        input integer fire_cycle,
        input string  case_name
    );
        integer expected_cycles;
        begin
            expected_cycles = cycle_count - fire_cycle + 1;
            if ({16'b0, active_cycles_o} !== expected_cycles[31:0]) begin
                fail_case($sformatf("%s active_cycles=%0d expected=%0d",
                                    case_name, active_cycles_o,
                                    expected_cycles));
            end
            if ((busy_o !== 1'b1) || (ready_o !== 1'b0)
                || (input_ready_o !== 1'b0)) begin
                fail_case($sformatf("%s terminal handshake levels invalid",
                                    case_name));
            end
        end
    endtask

    task automatic leave_main_terminal(input string case_name);
        logic [271:0] held_block;
        logic [3:0]   held_error;
        logic [15:0]  held_cycles;
        begin
            held_block  = block_o;
            held_error  = error_code_o;
            held_cycles = active_cycles_o;

            // terminal busy 周期的 start 必须被忽略。
            start_i = 1'b1;
            @(posedge clk_i);
            @(negedge clk_i);
            start_i = 1'b0;

            if ((done_o !== 1'b0) || (error_o !== 1'b0)
                || (ready_o !== 1'b1) || (busy_o !== 1'b0)) begin
                fail_case($sformatf("%s terminal was not exactly one cycle",
                                    case_name));
            end
            if ((block_o !== held_block) || (error_code_o !== held_error)
                || (active_cycles_o !== held_cycles)) begin
                fail_case($sformatf("%s terminal payload changed in IDLE",
                                    case_name));
            end
        end
    endtask

    task automatic wait_main_success(
        input string        case_name,
        input integer       fire_cycle,
        input logic [271:0] expected
    );
        integer wait_cycles;
        begin
            wait_cycles = 0;
            while ((done_o !== 1'b1) && (error_o !== 1'b1)) begin
                if (block_o !== 272'b0) begin
                    fail_case($sformatf("%s published partial block", case_name));
                end
                @(posedge clk_i);
                @(negedge clk_i);
                wait_cycles = wait_cycles + 1;
                if (wait_cycles > 512) begin
                    fail_case($sformatf("%s exceeded command timeout", case_name));
                end
            end
            if ((done_o !== 1'b1) || (error_o !== 1'b0)
                || (error_code_o !== ERROR_NONE)) begin
                fail_case($sformatf("%s returned error code=%0h", case_name,
                                    error_code_o));
            end
            if (block_o !== expected) begin
                fail_case($sformatf("%s block mismatch got=%068h expected=%068h",
                                    case_name, block_o, expected));
            end
            check_terminal_accounting(fire_cycle, case_name);
            completed_successes = completed_successes + 1;
            leave_main_terminal(case_name);
        end
    endtask

    task automatic wait_main_error(
        input string      case_name,
        input integer     fire_cycle,
        input logic [3:0] expected_error
    );
        integer wait_cycles;
        begin
            wait_cycles = 0;
            while ((done_o !== 1'b1) && (error_o !== 1'b1)) begin
                if (block_o !== 272'b0) begin
                    fail_case($sformatf("%s published partial block before error",
                                        case_name));
                end
                @(posedge clk_i);
                @(negedge clk_i);
                wait_cycles = wait_cycles + 1;
                if (wait_cycles > 512) begin
                    fail_case($sformatf("%s error path exceeded timeout", case_name));
                end
            end
            if ((error_o !== 1'b1) || (done_o !== 1'b0)
                || (error_code_o !== expected_error)
                || (block_o !== 272'b0)) begin
                fail_case($sformatf("%s error result code=%0h expected=%0h block=%068h",
                                    case_name, error_code_o, expected_error,
                                    block_o));
            end
            check_terminal_accounting(fire_cycle, case_name);
            completed_errors = completed_errors + 1;
            leave_main_terminal(case_name);
        end
    endtask

    task automatic run_main_success(
        input string        case_name,
        input logic [271:0] expected,
        input integer       probe_busy_start
    );
        integer fire_cycle;
        begin
            start_main_command(fire_cycle);
            if (fire_cycle <= 0) begin
                fail_case("success command did not record start edge");
            end
            load_main_words(probe_busy_start);
            wait_main_success(case_name, fire_cycle, expected);
        end
    endtask

    task automatic run_main_loaded_error(
        input string      case_name,
        input logic [3:0] expected_error
    );
        integer fire_cycle;
        begin
            start_main_command(fire_cycle);
            load_main_words(0);
            wait_main_error(case_name, fire_cycle, expected_error);
        end
    endtask

    task automatic run_forced_div_error;
        integer fire_cycle;
        begin
            start_main_command(fire_cycle);
            load_main_words(0);
            while (dut.state_q != STATE_D_DIV_WAIT) begin
                @(posedge clk_i);
                @(negedge clk_i);
            end
            force dut.div_rsp_valid_w   = 1'b1;
            force dut.div_result_bits_w = 32'h7f800000;
            force dut.div_flags_w       = 5'b11000;
            // EDA 优化可把 driven child output 与其已折叠的派生 predicate
            // 分开调度；直接钉住 top 消费的 predicate，使 fault oracle
            // 精确落在 D_DIV_WAIT，而不是漂移到下一拍 D_PACK。
            force dut.div_result_finite_w = 1'b0;
            force dut.div_fatal_flags_w   = 1'b1;
            @(posedge clk_i);
            @(negedge clk_i);
            release dut.div_rsp_valid_w;
            release dut.div_result_bits_w;
            release dut.div_flags_w;
            release dut.div_result_finite_w;
            release dut.div_fatal_flags_w;
            wait_main_error("forced_div_nonfinite_nv_dz", fire_cycle,
                            ERROR_DIV_NUMERIC);
        end
    endtask

    task automatic run_forced_mul_error;
        integer fire_cycle;
        begin
            start_main_command(fire_cycle);
            load_main_words(0);
            while (dut.state_q != STATE_MUL_WAIT) begin
                @(posedge clk_i);
                @(negedge clk_i);
            end
            force dut.mul_rsp_valid_w   = 1'b1;
            force dut.mul_result_bits_w = 32'h7f800000;
            force dut.mul_flags_w       = 5'b11100;
            force dut.mul_result_finite_w = 1'b0;
            force dut.mul_fatal_flags_w   = 1'b1;
            @(posedge clk_i);
            @(negedge clk_i);
            release dut.mul_rsp_valid_w;
            release dut.mul_result_bits_w;
            release dut.mul_flags_w;
            release dut.mul_result_finite_w;
            release dut.mul_fatal_flags_w;
            wait_main_error("forced_mul_nonfinite_nv_dz_of", fire_cycle,
                            ERROR_MUL_NUMERIC);
        end
    endtask

    task automatic run_forced_rmm_error(
        input string       case_name,
        input logic [31:0] forced_scaled
    );
        integer fire_cycle;
        begin
            start_main_command(fire_cycle);
            load_main_words(0);
            while (dut.state_q != STATE_RMM_STORE) begin
                @(posedge clk_i);
                @(negedge clk_i);
            end
            force dut.scaled_bits_q = forced_scaled;
            @(posedge clk_i);
            @(negedge clk_i);
            release dut.scaled_bits_q;
            wait_main_error(case_name, fire_cycle, ERROR_RMM);
        end
    endtask

    task automatic run_reset_cancel;
        integer fire_cycle;
        integer idle_probe;
        begin
            start_main_command(fire_cycle);
            if (fire_cycle <= 0) begin
                fail_case("reset-cancel command did not record start edge");
            end
            load_main_words(0);
            while (dut.state_q != STATE_D_DIV_WAIT) begin
                @(posedge clk_i);
                @(negedge clk_i);
            end
            rst_i = 1'b1;
            repeat (2) @(posedge clk_i);
            @(negedge clk_i);
            if ((ready_o !== 1'b0) || (busy_o !== 1'b0)
                || (done_o !== 1'b0) || (error_o !== 1'b0)
                || (block_o !== 272'b0) || (active_cycles_o !== 16'b0)) begin
                fail_case("in-flight reset did not clear top transaction");
            end
            rst_i = 1'b0;
            for (idle_probe = 0; idle_probe < 60;
                 idle_probe = idle_probe + 1) begin
                @(posedge clk_i);
                @(negedge clk_i);
                if ((done_o !== 1'b0) || (error_o !== 1'b0)
                    || (ready_o !== 1'b1) || (busy_o !== 1'b0)) begin
                    fail_case("reset-canceled child produced stale response");
                end
            end
        end
    endtask

    task automatic load_div_timeout_zeros(output integer fire_cycle);
        integer index;
        begin
            while (div_to_ready_o !== 1'b1) @(negedge clk_i);
            div_to_start_i = 1'b1;
            @(posedge clk_i);
            @(negedge clk_i);
            fire_cycle = cycle_count;
            div_to_start_i = 1'b0;
            for (index = 0; index < 32; index = index + 1) begin
                while (div_to_input_ready_o !== 1'b1) @(negedge clk_i);
                div_to_input_bits_i  = 32'b0;
                div_to_input_valid_i = 1'b1;
                @(posedge clk_i);
                @(negedge clk_i);
                div_to_input_valid_i = 1'b0;
            end
        end
    endtask

    task automatic run_div_timeout_test;
        integer fire_cycle;
        integer expected_cycles;
        begin
            load_div_timeout_zeros(fire_cycle);
            while ((div_to_done_o !== 1'b1) && (div_to_error_o !== 1'b1)) begin
                @(posedge clk_i);
                @(negedge clk_i);
            end
            expected_cycles = cycle_count - fire_cycle + 1;
            if ((div_to_error_o !== 1'b1)
                || (div_to_error_code_o !== ERROR_DIV_TIMEOUT)
                || (div_to_done_o !== 1'b0) || (div_to_block_o !== 272'b0)
                || ({16'b0, div_to_active_cycles_o}
                    !== expected_cycles[31:0])) begin
                fail_case("parameterized divider-timeout branch failed");
            end
            @(posedge clk_i);
            @(negedge clk_i);
            if ((div_to_ready_o !== 1'b1) || (div_to_busy_o !== 1'b0)) begin
                fail_case("divider timeout did not cancel child and recover IDLE");
            end
        end
    endtask

    task automatic load_mul_timeout_zeros(output integer fire_cycle);
        integer index;
        begin
            while (mul_to_ready_o !== 1'b1) @(negedge clk_i);
            mul_to_start_i = 1'b1;
            @(posedge clk_i);
            @(negedge clk_i);
            fire_cycle = cycle_count;
            mul_to_start_i = 1'b0;
            for (index = 0; index < 32; index = index + 1) begin
                while (mul_to_input_ready_o !== 1'b1) @(negedge clk_i);
                mul_to_input_bits_i  = 32'b0;
                mul_to_input_valid_i = 1'b1;
                @(posedge clk_i);
                @(negedge clk_i);
                mul_to_input_valid_i = 1'b0;
            end
        end
    endtask

    task automatic run_mul_timeout_test;
        integer fire_cycle;
        integer expected_cycles;
        begin
            load_mul_timeout_zeros(fire_cycle);
            while ((mul_to_done_o !== 1'b1) && (mul_to_error_o !== 1'b1)) begin
                @(posedge clk_i);
                @(negedge clk_i);
            end
            expected_cycles = cycle_count - fire_cycle + 1;
            if ((mul_to_error_o !== 1'b1)
                || (mul_to_error_code_o !== ERROR_MUL_TIMEOUT)
                || (mul_to_done_o !== 1'b0) || (mul_to_block_o !== 272'b0)
                || ({16'b0, mul_to_active_cycles_o}
                    !== expected_cycles[31:0])) begin
                fail_case("parameterized multiplier-timeout branch failed");
            end
            @(posedge clk_i);
            @(negedge clk_i);
            if ((mul_to_ready_o !== 1'b1) || (mul_to_busy_o !== 1'b0)) begin
                fail_case("multiplier timeout did not cancel child and recover IDLE");
            end
        end
    endtask

    task automatic run_command_timeout_test;
        integer fire_cycle;
        integer expected_cycles;
        begin
            while (cmd_to_ready_o !== 1'b1) @(negedge clk_i);
            cmd_to_start_i = 1'b1;
            @(posedge clk_i);
            @(negedge clk_i);
            fire_cycle = cycle_count;
            cmd_to_start_i = 1'b0;
            if (cmd_to_input_ready_o !== 1'b1) begin
                fail_case("command-timeout DUT did not enter LOAD32");
            end
            while ((cmd_to_done_o !== 1'b1) && (cmd_to_error_o !== 1'b1)) begin
                @(posedge clk_i);
                @(negedge clk_i);
            end
            expected_cycles = cycle_count - fire_cycle + 1;
            if ((cmd_to_error_o !== 1'b1)
                || (cmd_to_error_code_o !== ERROR_COMMAND_TIMEOUT)
                || (cmd_to_done_o !== 1'b0) || (cmd_to_block_o !== 272'b0)
                || (cmd_to_active_cycles_o !== 16'd8)
                || ({16'b0, cmd_to_active_cycles_o}
                    !== expected_cycles[31:0])) begin
                fail_case("parameterized command-timeout branch failed");
            end
            @(posedge clk_i);
            @(negedge clk_i);
            if ((cmd_to_ready_o !== 1'b1) || (cmd_to_busy_o !== 1'b0)) begin
                fail_case("command timeout did not recover IDLE");
            end
        end
    endtask

    initial begin
        cycle_count               = 0;
        completed_successes       = 0;
        completed_errors          = 0;
        rst_i                     = 1'b1;
        start_i                   = 1'b0;
        input_valid_i             = 1'b0;
        input_bits_i              = 32'b0;
        div_to_start_i            = 1'b0;
        div_to_input_valid_i      = 1'b0;
        div_to_input_bits_i       = 32'b0;
        mul_to_start_i            = 1'b0;
        mul_to_input_valid_i      = 1'b0;
        mul_to_input_bits_i       = 32'b0;
        cmd_to_start_i            = 1'b0;
        cmd_to_input_valid_i      = 1'b0;
        cmd_to_input_bits_i       = 32'b0;
        expected_block            = 272'b0;
        clear_main_words();

        repeat (3) @(posedge clk_i);
        @(negedge clk_i);
        if ((ready_o !== 1'b0) || (busy_o !== 1'b0)
            || (done_o !== 1'b0) || (error_o !== 1'b0)
            || (block_o !== 272'b0) || (active_cycles_o !== 16'b0)) begin
            fail_case("startup reset outputs invalid");
        end
        rst_i = 1'b0;
        @(posedge clk_i);
        @(negedge clk_i);
        if ((ready_o !== 1'b1) || (busy_o !== 1'b0)) begin
            fail_case("IDLE did not open after reset");
        end

        if ((dut.DIV_TIMEOUT_CYCLES != 48)
            || (dut.MUL_TIMEOUT_CYCLES != 16)
            || (dut.COMMAND_TIMEOUT_CYCLES != 512)) begin
            fail_case("main DUT timeout defaults are not 48/16/512");
        end

        // reset 必须取消一个真实 resident divider transaction。
        clear_main_words();
        main_words[0] = 32'h42fe0000;
        run_reset_cancel();

        // TV0：34 bytes 全零。
        clear_main_words();
        expected_block = 272'b0;
        run_main_success("TV0_zero_block", expected_block, 1);

        // +0/-0 混合仍统一发布 +0 scale 和全零 q。
        clear_main_words();
        for (check_index = 0; check_index < 32;
             check_index = check_index + 1) begin
            if (check_index[0]) main_words[check_index] = 32'h80000000;
        end
        expected_block = 272'b0;
        run_main_success("signed_zero_block", expected_block, 0);

        // TV1：scale=1，前 8 个 signed q 与 JSON oracle bit-exact。
        clear_main_words();
        main_words[0] = 32'hc2fe0000;
        main_words[1] = 32'hc2800000;
        main_words[2] = 32'hbf800000;
        main_words[3] = 32'h00000000;
        main_words[4] = 32'h3f800000;
        main_words[5] = 32'h427c0000;
        main_words[6] = 32'h42800000;
        main_words[7] = 32'h42fe0000;
        expected_block = 272'b0;
        expected_block[15:0] = 16'h3c00;
        expected_block[16 + (0 * 8) +: 8] = 8'h81;
        expected_block[16 + (1 * 8) +: 8] = 8'hc0;
        expected_block[16 + (2 * 8) +: 8] = 8'hff;
        expected_block[16 + (3 * 8) +: 8] = 8'h00;
        expected_block[16 + (4 * 8) +: 8] = 8'h01;
        expected_block[16 + (5 * 8) +: 8] = 8'h3f;
        expected_block[16 + (6 * 8) +: 8] = 8'h40;
        expected_block[16 + (7 * 8) +: 8] = 8'h7f;
        run_main_success("TV1_unit_scale_signed", expected_block, 0);

        // amax=127 固定 d=id=1，证明 ±0.5/±2.5/±126.5 RMM away。
        clear_main_words();
        main_words[0] = 32'h3f000000;
        main_words[1] = 32'hbf000000;
        main_words[2] = 32'h40200000;
        main_words[3] = 32'hc0200000;
        main_words[4] = 32'h42fd0000;
        main_words[5] = 32'hc2fd0000;
        main_words[6] = 32'h42fe0000;
        main_words[7] = 32'hc2fe0000;
        expected_block = 272'b0;
        expected_block[15:0] = 16'h3c00;
        expected_block[16 + (0 * 8) +: 8] = 8'h01;
        expected_block[16 + (1 * 8) +: 8] = 8'hff;
        expected_block[16 + (2 * 8) +: 8] = 8'h03;
        expected_block[16 + (3 * 8) +: 8] = 8'hfd;
        expected_block[16 + (4 * 8) +: 8] = 8'h7f;
        expected_block[16 + (5 * 8) +: 8] = 8'h81;
        expected_block[16 + (6 * 8) +: 8] = 8'h7f;
        expected_block[16 + (7 * 8) +: 8] = 8'h81;
        run_main_success("RMM_halfway_away", expected_block, 0);

        // d=2^-30 非零但 binary16 RNE 为零；q 必须继续使用未舍入 d/id。
        clear_main_words();
        main_words[0] = 32'h33fe0000;
        main_words[1] = 32'hb3fe0000;
        main_words[2] = 32'h337e0000;
        main_words[3] = 32'hb37e0000;
        expected_block = 272'b0;
        expected_block[16 + (0 * 8) +: 8] = 8'h7f;
        expected_block[16 + (1 * 8) +: 8] = 8'h81;
        expected_block[16 + (2 * 8) +: 8] = 8'h40;
        expected_block[16 + (3 * 8) +: 8] = 8'hc0;
        run_main_success("stored_half_zero_unrounded_id", expected_block, 0);

        // 输入 NaN/Inf 均在 LOAD32 fail-closed；放在第 32 项还覆盖 late error。
        clear_main_words();
        main_words[31] = 32'h7fc12345;
        run_main_loaded_error("input_qnan", ERROR_INPUT_NONFINITE);
        clear_main_words();
        main_words[31] = 32'hff800000;
        run_main_loaded_error("input_negative_inf", ERROR_INPUT_NONFINITE);

        // 最大 finite / 127 仍远超 half finite range，pack 必须拒绝。
        clear_main_words();
        main_words[0] = 32'h7f7fffff;
        run_main_loaded_error("half_scale_overflow", ERROR_SCALE_PACK);

        // amax=2^-125：d 非零，但 1/d overflow；divider flags/result fail-closed。
        clear_main_words();
        main_words[0] = 32'h01000000;
        run_main_loaded_error("id_div_overflow", ERROR_DIV_NUMERIC);

        // 定向 child/RMM fault injection 覆盖无法由合法数学输入自然到达的
        // NV/DZ/OF、non-finite 和 q8 越界分支；ERROR 拍复位 child。
        clear_main_words();
        main_words[0] = 32'h42fe0000;
        run_forced_div_error();
        clear_main_words();
        main_words[0] = 32'h42fe0000;
        run_forced_mul_error();
        clear_main_words();
        main_words[0] = 32'h42fe0000;
        run_forced_rmm_error("forced_rmm_nv", 32'h7fc00000);
        clear_main_words();
        main_words[0] = 32'h42fe0000;
        run_forced_rmm_error("forced_rmm_q8_out_of_range", 32'h42ff0000);

        run_div_timeout_test();
        run_mul_timeout_test();
        run_command_timeout_test();

        if ((completed_successes != 5) || (completed_errors != 8)) begin
            fail_case($sformatf("completion census success=%0d/5 error=%0d/8",
                                completed_successes, completed_errors));
        end

        $display("[NPU-Q8-QUANT][PASS] success=%0d error=%0d tv0_tv1=bit_exact ties=RMM-away scale_half_zero=unrounded-d atomic=1 reset=child-cancel timeout_defaults=48/16/512 no_host_fp=1",
                 completed_successes, completed_errors);
        $finish;
    end

endmodule

`default_nettype wire
