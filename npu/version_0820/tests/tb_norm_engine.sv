`timescale 1ns/1ps

module tb_norm_engine;

    localparam integer MAX_D = 1024;
    localparam integer COUNT_WIDTH = $clog2(MAX_D + 1);

    localparam logic [1:0] MODE_RMS = 2'd0;
    localparam logic [1:0] MODE_L2  = 2'd1;

    localparam logic [4:0] ERR_NONE             = 5'd0;
    localparam logic [4:0] ERR_HEADER_MODE      = 5'd1;
    localparam logic [4:0] ERR_HEADER_D         = 5'd2;
    localparam logic [4:0] ERR_HEADER_EPS       = 5'd3;
    localparam logic [4:0] ERR_SUM_CHILD        = 5'd4;
    localparam logic [4:0] ERR_CONVERT_FATAL    = 5'd7;
    localparam logic [4:0] ERR_DEN_ZERO         = 5'd10;
    localparam logic [4:0] ERR_STALL_TIMEOUT    = 5'd14;
    localparam logic [4:0] ERR_COMMAND_TIMEOUT  = 5'd15;

    logic clk_i;
    logic rst_i;
    logic start_i;
    wire ready_o;
    wire busy_o;
    logic [1:0] mode_i;
    logic [COUNT_WIDTH-1:0] element_count_i;
    logic [31:0] eps_bits_i;
    logic lane_valid_i;
    wire lane_ready_o;
    logic [31:0] lane_bits_i;
    wire out_valid_o;
    logic out_ready_i;
    wire [31:0] out_bits_o;
    wire [COUNT_WIDTH-1:0] out_index_o;
    wire out_last_o;
    wire done_o;
    wire error_o;
    wire [4:0] error_code_o;
    wire [4:0] flags_o;
    wire [COUNT_WIDTH-1:0] elements_accepted_o;
    wire [COUNT_WIDTH-1:0] elements_emitted_o;
    wire [31:0] active_cycles_o;

    TensorNpuNormEngine #(
        .MAX_D                  (MAX_D),
        .STALL_TIMEOUT_CYCLES   (32'd64),
        .COMMAND_TIMEOUT_CYCLES (32'd262144)
    ) dut (
        .clk_i                (clk_i),
        .rst_i                (rst_i),
        .start_i              (start_i),
        .ready_o              (ready_o),
        .busy_o               (busy_o),
        .mode_i               (mode_i),
        .element_count_i      (element_count_i),
        .eps_bits_i           (eps_bits_i),
        .lane_valid_i         (lane_valid_i),
        .lane_ready_o         (lane_ready_o),
        .lane_bits_i          (lane_bits_i),
        .out_valid_o          (out_valid_o),
        .out_ready_i          (out_ready_i),
        .out_bits_o           (out_bits_o),
        .out_index_o          (out_index_o),
        .out_last_o           (out_last_o),
        .done_o               (done_o),
        .error_o              (error_o),
        .error_code_o         (error_code_o),
        .flags_o              (flags_o),
        .elements_accepted_o  (elements_accepted_o),
        .elements_emitted_o   (elements_emitted_o),
        .active_cycles_o      (active_cycles_o)
    );

    // 独立实例令command watchdog早于stall watchdog，固定覆盖父级超时分类。
    logic timeout_rst_i;
    logic timeout_start_i;
    wire timeout_ready_o;
    wire timeout_busy_o;
    logic [1:0] timeout_mode_i;
    logic [COUNT_WIDTH-1:0] timeout_element_count_i;
    logic [31:0] timeout_eps_bits_i;
    logic timeout_lane_valid_i;
    wire timeout_lane_ready_o;
    logic [31:0] timeout_lane_bits_i;
    wire timeout_out_valid_o;
    logic timeout_out_ready_i;
    wire [31:0] timeout_out_bits_o;
    wire [COUNT_WIDTH-1:0] timeout_out_index_o;
    wire timeout_out_last_o;
    wire timeout_done_o;
    wire timeout_error_o;
    wire [4:0] timeout_error_code_o;
    wire [4:0] timeout_flags_o;
    wire [COUNT_WIDTH-1:0] timeout_elements_accepted_o;
    wire [COUNT_WIDTH-1:0] timeout_elements_emitted_o;
    wire [31:0] timeout_active_cycles_o;

    TensorNpuNormEngine #(
        .MAX_D                  (MAX_D),
        .STALL_TIMEOUT_CYCLES   (32'd128),
        .COMMAND_TIMEOUT_CYCLES (32'd12)
    ) timeout_dut (
        .clk_i                (clk_i),
        .rst_i                (timeout_rst_i),
        .start_i              (timeout_start_i),
        .ready_o              (timeout_ready_o),
        .busy_o               (timeout_busy_o),
        .mode_i               (timeout_mode_i),
        .element_count_i      (timeout_element_count_i),
        .eps_bits_i           (timeout_eps_bits_i),
        .lane_valid_i         (timeout_lane_valid_i),
        .lane_ready_o         (timeout_lane_ready_o),
        .lane_bits_i          (timeout_lane_bits_i),
        .out_valid_o          (timeout_out_valid_o),
        .out_ready_i          (timeout_out_ready_i),
        .out_bits_o           (timeout_out_bits_o),
        .out_index_o          (timeout_out_index_o),
        .out_last_o           (timeout_out_last_o),
        .done_o               (timeout_done_o),
        .error_o              (timeout_error_o),
        .error_code_o         (timeout_error_code_o),
        .flags_o              (timeout_flags_o),
        .elements_accepted_o  (timeout_elements_accepted_o),
        .elements_emitted_o   (timeout_elements_emitted_o),
        .active_cycles_o      (timeout_active_cycles_o)
    );

    logic [31:0] input_mem [0:MAX_D-1];
    logic [31:0] expected_mem [0:MAX_D-1];

    integer cycle_count;
    integer completed_cases;

    integer sum_start_count;
    integer sum_terminal_count;
    integer square_req_count;
    integer square_rsp_count;
    integer widen_req_count;
    integer widen_rsp_count;
    integer add64_req_count;
    integer add64_rsp_count;
    integer scale_req_count;
    integer scale_rsp_count;
    integer convert_req_count;
    integer convert_rsp_count;
    integer eps_req_count;
    integer eps_rsp_count;
    integer sqrt_req_count;
    integer sqrt_rsp_count;
    integer div_req_count;
    integer div_rsp_count;
    integer mul_req_count;
    integer mul_rsp_count;
    integer output_fire_count;

    logic output_hold_active_q;
    logic [31:0] output_hold_bits_q;
    logic [COUNT_WIDTH-1:0] output_hold_index_q;
    logic output_hold_last_q;

    initial clk_i = 1'b0;
    always #5 clk_i <= ~clk_i;

    task automatic fail_case(input string reason);
        begin
            $display("[NPU-NORM][FAIL] %s cycle=%0d", reason, cycle_count);
            $fatal(1);
        end
    endtask

    always @(posedge clk_i) begin
        cycle_count <= cycle_count + 1;
        if (cycle_count >= 1000000) begin
            fail_case("global cycle bound exceeded");
        end

        if (!rst_i) begin
            if (dut.sum_start_fire_w) begin
                sum_start_count <= sum_start_count + 1;
            end
            if (dut.sum_terminal_w) begin
                sum_terminal_count <= sum_terminal_count + 1;
            end
            if (dut.u_sum.square_req_fire_w) begin
                square_req_count <= square_req_count + 1;
            end
            if (dut.u_sum.square_rsp_fire_w) begin
                square_rsp_count <= square_rsp_count + 1;
            end
            if (dut.u_sum.widen_req_fire_w) begin
                widen_req_count <= widen_req_count + 1;
            end
            if (dut.u_sum.widen_rsp_fire_w) begin
                widen_rsp_count <= widen_rsp_count + 1;
            end
            if (dut.u_sum.add_req_fire_w) begin
                add64_req_count <= add64_req_count + 1;
            end
            if (dut.u_sum.add_rsp_fire_w) begin
                add64_rsp_count <= add64_rsp_count + 1;
            end
            if (dut.scale_req_fire_w) begin
                scale_req_count <= scale_req_count + 1;
            end
            if (dut.scale_rsp_fire_w) begin
                scale_rsp_count <= scale_rsp_count + 1;
            end
            if (dut.convert_req_fire_w) begin
                convert_req_count <= convert_req_count + 1;
            end
            if (dut.convert_rsp_fire_w) begin
                convert_rsp_count <= convert_rsp_count + 1;
            end
            if (dut.eps_req_fire_w) begin
                eps_req_count <= eps_req_count + 1;
            end
            if (dut.eps_rsp_fire_w) begin
                eps_rsp_count <= eps_rsp_count + 1;
            end
            if (dut.sqrt_req_fire_w) begin
                sqrt_req_count <= sqrt_req_count + 1;
            end
            if (dut.sqrt_rsp_fire_w) begin
                sqrt_rsp_count <= sqrt_rsp_count + 1;
            end
            if (dut.div_req_fire_w) begin
                div_req_count <= div_req_count + 1;
            end
            if (dut.div_rsp_fire_w) begin
                div_rsp_count <= div_rsp_count + 1;
            end
            if (dut.mul_req_fire_w) begin
                mul_req_count <= mul_req_count + 1;
            end
            if (dut.mul_rsp_fire_w) begin
                mul_rsp_count <= mul_rsp_count + 1;
            end
            if (out_valid_o && out_ready_i) begin
                output_fire_count <= output_fire_count + 1;
            end

            // 独立逐拍监视stream反压保持，不依赖task采样时点。
            if (out_valid_o && !out_ready_i) begin
                if (output_hold_active_q) begin
                    if ((out_bits_o !== output_hold_bits_q) ||
                        (out_index_o !== output_hold_index_q) ||
                        (out_last_o !== output_hold_last_q)) begin
                        fail_case("output payload changed while backpressured");
                    end
                end else begin
                    output_hold_active_q <= 1'b1;
                    output_hold_bits_q   <= out_bits_o;
                    output_hold_index_q  <= out_index_o;
                    output_hold_last_q   <= out_last_o;
                end
            end else begin
                output_hold_active_q <= 1'b0;
            end

            if (out_valid_o &&
                (dut.replay_index_q != (dut.element_count_q - 1'b1))) begin
                fail_case("output credit appeared before final replay multiply index");
            end
        end else begin
            output_hold_active_q <= 1'b0;
        end
    end

    task automatic start_main(
        input logic [1:0] case_mode,
        input integer case_count,
        input logic [31:0] case_eps
    );
        begin
            while (ready_o !== 1'b1) begin
                @(negedge clk_i);
            end
            mode_i          = case_mode;
            element_count_i = case_count[COUNT_WIDTH-1:0];
            eps_bits_i      = case_eps;
            start_i         = 1'b1;
            @(posedge clk_i);
            #1;
            start_i = 1'b0;
            if (ready_o !== 1'b0 || busy_o !== 1'b1 ||
                lane_ready_o !== 1'b0 || out_valid_o !== 1'b0) begin
                fail_case($sformatf("command mode=%0d D=%0d was not atomically accepted",
                                    case_mode, case_count));
            end
            if (elements_accepted_o !== 0 || elements_emitted_o !== 0 ||
                flags_o !== 0) begin
                fail_case("new command did not clear row evidence");
            end
        end
    endtask

    task automatic send_main_lane(input logic [31:0] bits);
        logic [COUNT_WIDTH-1:0] accepted_before;
        begin
            while (lane_ready_o !== 1'b1) begin
                @(negedge clk_i);
                if (out_valid_o !== 1'b0 || done_o === 1'b1) begin
                    fail_case("row terminated or emitted before requested lane credit");
                end
            end
            accepted_before = elements_accepted_o;
            lane_bits_i  = bits;
            lane_valid_i = 1'b1;
            @(posedge clk_i);
            #1;
            lane_valid_i = 1'b0;
            if (elements_accepted_o !== (accepted_before + 1'b1)) begin
                fail_case($sformatf("lane handshake count mismatch bits=%08x", bits));
            end
            if (out_valid_o !== 1'b0 || elements_emitted_o !== 0) begin
                fail_case("input handshake exposed output credit");
            end
        end
    endtask

    task automatic probe_busy_start;
        logic [1:0] saved_mode;
        logic [COUNT_WIDTH-1:0] saved_count;
        logic [31:0] saved_eps;
        logic [COUNT_WIDTH-1:0] saved_accepted;
        begin
            while (lane_ready_o !== 1'b0) begin
                @(negedge clk_i);
            end
            saved_mode     = dut.mode_q;
            saved_count    = dut.element_count_q;
            saved_eps      = dut.eps_bits_q;
            saved_accepted = elements_accepted_o;

            mode_i          = 2'd3;
            element_count_i = 11'd1;
            eps_bits_i      = 32'hff800000;
            lane_bits_i     = 32'h7fc12345;
            start_i         = 1'b1;
            lane_valid_i    = 1'b1;
            @(posedge clk_i);
            #1;
            start_i      = 1'b0;
            lane_valid_i = 1'b0;
            if (ready_o !== 1'b0 || lane_ready_o !== 1'b0 ||
                dut.mode_q !== saved_mode || dut.element_count_q !== saved_count ||
                dut.eps_bits_q !== saved_eps ||
                elements_accepted_o !== saved_accepted || out_valid_o !== 1'b0) begin
                fail_case("busy start/backpressured poison lane changed resident row");
            end
        end
    endtask

    task automatic wait_main_error(
        input logic [4:0] expected_code,
        input logic [4:0] expected_flags,
        input integer expected_accepted
    );
        integer wait_cycles;
        begin
            wait_cycles = 0;
            while (done_o !== 1'b1) begin
                @(posedge clk_i);
                #1;
                wait_cycles = wait_cycles + 1;
                if (out_valid_o !== 1'b0 || elements_emitted_o !== 0) begin
                    fail_case("ERROR path exposed an output handshake opportunity");
                end
                if (wait_cycles > 300000) begin
                    fail_case("ERROR terminal exceeded bounded wait");
                end
            end
            if (error_o !== 1'b1 || error_code_o !== expected_code ||
                flags_o !== expected_flags ||
                elements_accepted_o !== expected_accepted[COUNT_WIDTH-1:0] ||
                elements_emitted_o !== 0 || out_valid_o !== 1'b0) begin
                fail_case($sformatf("ERROR terminal got code=%0d flags=%02x accepted=%0d expected=%0d/%02x/%0d",
                                    error_code_o, flags_o, elements_accepted_o,
                                    expected_code, expected_flags, expected_accepted));
            end
            @(posedge clk_i);
            #1;
            if (done_o !== 1'b0 || error_o !== 1'b0 ||
                error_code_o !== ERR_NONE || ready_o !== 1'b1 || busy_o !== 1'b0) begin
                fail_case("ERROR terminal/code was not one cycle");
            end
            completed_cases = completed_cases + 1;
        end
    endtask

    task automatic consume_success_stream(
        input string case_name,
        input integer element_total,
        input logic [4:0] expected_flags,
        input integer hold_index,
        input integer hold_cycles,
        input integer mul_rsp_before
    );
        integer wait_cycles;
        integer stream_i;
        integer hold_i;
        logic [31:0] held_bits;
        logic [COUNT_WIDTH-1:0] held_index;
        logic held_last;
        begin
            out_ready_i = 1'b0;
            wait_cycles = 0;
            while (out_valid_o !== 1'b1) begin
                @(posedge clk_i);
                #1;
                wait_cycles = wait_cycles + 1;
                if (done_o === 1'b1 || error_o === 1'b1 ||
                    elements_emitted_o !== 0) begin
                    fail_case({case_name, " terminated before committed stream"});
                end
                if (wait_cycles > 300000) begin
                    fail_case({case_name, " stream commit exceeded bounded wait"});
                end
            end

            if ((mul_rsp_count - mul_rsp_before) != element_total ||
                elements_emitted_o !== 0) begin
                fail_case({case_name, " output credit preceded all replay responses"});
            end

            for (stream_i = 0; stream_i < element_total; stream_i = stream_i + 1) begin
                if (out_valid_o !== 1'b1 ||
                    out_index_o !== stream_i[COUNT_WIDTH-1:0] ||
                    out_bits_o !== expected_mem[stream_i] ||
                    out_last_o !== (stream_i == (element_total - 1))) begin
                    fail_case($sformatf("%s output[%0d]=%08x index=%0d last=%b expected=%08x",
                                        case_name, stream_i, out_bits_o, out_index_o,
                                        out_last_o, expected_mem[stream_i]));
                end

                if (stream_i == hold_index) begin
                    held_bits  = out_bits_o;
                    held_index = out_index_o;
                    held_last  = out_last_o;
                    // 同时保持一个非法busy start，验证stream resident metadata不变。
                    start_i         = 1'b1;
                    mode_i          = 2'd3;
                    element_count_i = 11'd1;
                    eps_bits_i      = 32'hffc00000;
                    for (hold_i = 0; hold_i < hold_cycles; hold_i = hold_i + 1) begin
                        @(posedge clk_i);
                        #1;
                        if (out_valid_o !== 1'b1 || out_bits_o !== held_bits ||
                            out_index_o !== held_index || out_last_o !== held_last ||
                            done_o !== 1'b0 || error_o !== 1'b0) begin
                            fail_case({case_name, " output hold was not stable"});
                        end
                    end
                    start_i = 1'b0;
                end

                @(negedge clk_i);
                out_ready_i = 1'b1;
                @(posedge clk_i);
                #1;
                out_ready_i = 1'b0;
            end

            if (done_o !== 1'b1 || error_o !== 1'b0 ||
                error_code_o !== ERR_NONE || flags_o !== expected_flags ||
                elements_accepted_o !== element_total[COUNT_WIDTH-1:0] ||
                elements_emitted_o !== element_total[COUNT_WIDTH-1:0] ||
                out_valid_o !== 1'b0 || active_cycles_o == 0) begin
                fail_case($sformatf("%s DONE payload mismatch flags=%02x accepted=%0d emitted=%0d",
                                    case_name, flags_o, elements_accepted_o,
                                    elements_emitted_o));
            end
            @(posedge clk_i);
            #1;
            if (done_o !== 1'b0 || error_o !== 1'b0 || ready_o !== 1'b1 ||
                busy_o !== 1'b0) begin
                fail_case({case_name, " DONE was not one cycle"});
            end
        end
    endtask

    task automatic run_success(
        input string case_name,
        input logic [1:0] case_mode,
        input integer element_total,
        input logic [31:0] case_eps,
        input logic [4:0] expected_flags,
        input integer hold_index,
        input integer hold_cycles,
        input integer do_busy_probe
    );
        integer lane_i;
        integer sum_start_before;
        integer sum_terminal_before;
        integer square_req_before;
        integer square_rsp_before;
        integer widen_req_before;
        integer widen_rsp_before;
        integer add64_req_before;
        integer add64_rsp_before;
        integer scale_req_before;
        integer scale_rsp_before;
        integer convert_req_before;
        integer convert_rsp_before;
        integer eps_req_before;
        integer eps_rsp_before;
        integer sqrt_req_before;
        integer sqrt_rsp_before;
        integer div_req_before;
        integer div_rsp_before;
        integer mul_req_before;
        integer mul_rsp_before;
        integer output_before;
        begin
            sum_start_before    = sum_start_count;
            sum_terminal_before = sum_terminal_count;
            square_req_before   = square_req_count;
            square_rsp_before   = square_rsp_count;
            widen_req_before    = widen_req_count;
            widen_rsp_before    = widen_rsp_count;
            add64_req_before    = add64_req_count;
            add64_rsp_before    = add64_rsp_count;
            scale_req_before    = scale_req_count;
            scale_rsp_before    = scale_rsp_count;
            convert_req_before  = convert_req_count;
            convert_rsp_before  = convert_rsp_count;
            eps_req_before      = eps_req_count;
            eps_rsp_before      = eps_rsp_count;
            sqrt_req_before     = sqrt_req_count;
            sqrt_rsp_before     = sqrt_rsp_count;
            div_req_before      = div_req_count;
            div_rsp_before      = div_rsp_count;
            mul_req_before      = mul_req_count;
            mul_rsp_before      = mul_rsp_count;
            output_before       = output_fire_count;

            start_main(case_mode, element_total, case_eps);
            for (lane_i = 0; lane_i < element_total; lane_i = lane_i + 1) begin
                send_main_lane(input_mem[lane_i]);
                if ((do_busy_probe != 0) && (lane_i == 0)) begin
                    probe_busy_start();
                end
            end
            consume_success_stream(case_name, element_total, expected_flags,
                                   hold_index, hold_cycles, mul_rsp_before);

            if ((sum_start_count - sum_start_before) != 1 ||
                (sum_terminal_count - sum_terminal_before) != 1 ||
                (square_req_count - square_req_before) != element_total ||
                (square_rsp_count - square_rsp_before) != element_total ||
                (widen_req_count - widen_req_before) != element_total ||
                (widen_rsp_count - widen_rsp_before) != element_total ||
                (add64_req_count - add64_req_before) != element_total ||
                (add64_rsp_count - add64_rsp_before) != element_total ||
                (convert_req_count - convert_req_before) != 1 ||
                (convert_rsp_count - convert_rsp_before) != 1 ||
                (sqrt_req_count - sqrt_req_before) != 1 ||
                (sqrt_rsp_count - sqrt_rsp_before) != 1 ||
                (div_req_count - div_req_before) != 1 ||
                (div_rsp_count - div_rsp_before) != 1 ||
                (mul_req_count - mul_req_before) != element_total ||
                (mul_rsp_count - mul_rsp_before) != element_total ||
                (output_fire_count - output_before) != element_total) begin
                fail_case({case_name, " direct/ordered child cardinality mismatch"});
            end
            if (case_mode == MODE_RMS) begin
                if ((scale_req_count - scale_req_before) != 1 ||
                    (scale_rsp_count - scale_rsp_before) != 1 ||
                    (eps_req_count - eps_req_before) != 1 ||
                    (eps_rsp_count - eps_rsp_before) != 1) begin
                    fail_case({case_name, " RMS-only child cardinality mismatch"});
                end
            end else begin
                if ((scale_req_count - scale_req_before) != 0 ||
                    (scale_rsp_count - scale_rsp_before) != 0 ||
                    (eps_req_count - eps_req_before) != 0 ||
                    (eps_rsp_count - eps_rsp_before) != 0) begin
                    fail_case({case_name, " L2 unexpectedly used RMS-only child"});
                end
            end
            completed_cases = completed_cases + 1;
            $display("[NPU-NORM][CASE] %s D=%0d flags=%02x active=%0d",
                     case_name, element_total, expected_flags, active_cycles_o);
        end
    endtask

    task automatic run_header_error(
        input string case_name,
        input logic [1:0] case_mode,
        input integer case_count,
        input logic [31:0] case_eps,
        input logic [4:0] expected_code
    );
        integer sum_before;
        integer output_before;
        begin
            sum_before    = sum_start_count;
            output_before = output_fire_count;
            start_main(case_mode, case_count, case_eps);
            wait_main_error(expected_code, 5'b0, 0);
            if (sum_start_count != sum_before || output_fire_count != output_before) begin
                fail_case({case_name, " illegal header reached a child/output"});
            end
            $display("[NPU-NORM][CASE] %s atomic-header-error code=%0d",
                     case_name, expected_code);
        end
    endtask

    task automatic run_input_error(
        input string case_name,
        input logic [31:0] bad_bits,
        input logic [4:0] expected_flags,
        input integer expect_square_transaction
    );
        integer sum_start_before;
        integer sum_terminal_before;
        integer square_req_before;
        integer square_rsp_before;
        integer widen_before;
        integer output_before;
        begin
            sum_start_before    = sum_start_count;
            sum_terminal_before = sum_terminal_count;
            square_req_before   = square_req_count;
            square_rsp_before   = square_rsp_count;
            widen_before        = widen_req_count;
            output_before       = output_fire_count;
            start_main(MODE_RMS, 128, 32'h3f800000);
            send_main_lane(bad_bits);
            wait_main_error(ERR_SUM_CHILD, expected_flags, 1);
            if ((sum_start_count - sum_start_before) != 1 ||
                (sum_terminal_count - sum_terminal_before) != 1 ||
                (square_req_count - square_req_before) != expect_square_transaction ||
                (square_rsp_count - square_rsp_before) != expect_square_transaction ||
                widen_req_count != widen_before || output_fire_count != output_before) begin
                fail_case({case_name, " sum-child containment/cardinality mismatch"});
            end
            $display("[NPU-NORM][CASE] %s atomic-sum-error flags=%02x",
                     case_name, expected_flags);
        end
    endtask

    task automatic run_full_row_error(
        input string case_name,
        input logic [1:0] case_mode,
        input logic [31:0] case_eps,
        input logic [4:0] expected_code,
        input logic [4:0] expected_flags
    );
        integer lane_i;
        integer square_before;
        integer widen_before;
        integer add64_before;
        integer output_before;
        begin
            square_before = square_req_count;
            widen_before  = widen_req_count;
            add64_before  = add64_req_count;
            output_before = output_fire_count;
            start_main(case_mode, 128, case_eps);
            for (lane_i = 0; lane_i < 128; lane_i = lane_i + 1) begin
                send_main_lane(input_mem[lane_i]);
            end
            wait_main_error(expected_code, expected_flags, 128);
            if ((square_req_count - square_before) != 128 ||
                (widen_req_count - widen_before) != 128 ||
                (add64_req_count - add64_before) != 128 ||
                output_fire_count != output_before) begin
                fail_case({case_name, " full-row reduction cardinality mismatch"});
            end
            $display("[NPU-NORM][CASE] %s post-reduction atomic-error code=%0d flags=%02x",
                     case_name, expected_code, expected_flags);
        end
    endtask

    task automatic run_resident_reset;
        integer square_before;
        integer quiet_i;
        begin
            square_before = square_req_count;
            start_main(MODE_RMS, 128, 32'h41400000);
            send_main_lane(32'h40000000);
            while (square_req_count == square_before) begin
                @(posedge clk_i);
                #1;
            end
            @(negedge clk_i);
            rst_i = 1'b1;
            repeat (2) begin
                @(posedge clk_i);
                #1;
                if (ready_o !== 1'b0 || busy_o !== 1'b0 || done_o !== 1'b0 ||
                    error_o !== 1'b0 || lane_ready_o !== 1'b0 ||
                    out_valid_o !== 1'b0 || elements_emitted_o !== 0) begin
                    fail_case("resident reset did not quiesce parent and children");
                end
            end
            @(negedge clk_i);
            rst_i = 1'b0;
            #1;
            if (ready_o !== 1'b1 || done_o !== 1'b0 || out_valid_o !== 1'b0 ||
                elements_accepted_o !== 0 || flags_o !== 0) begin
                fail_case("reset did not restore clean parent epoch");
            end
            for (quiet_i = 0; quiet_i < 40; quiet_i = quiet_i + 1) begin
                @(posedge clk_i);
                #1;
                if (ready_o !== 1'b1 || done_o !== 1'b0 || error_o !== 1'b0 ||
                    out_valid_o !== 1'b0) begin
                    fail_case("canceled resident child produced a stale event");
                end
            end
            completed_cases = completed_cases + 1;
            $display("[NPU-NORM][CASE] resident-reset clean-no-stale-response");
        end
    endtask

    task automatic run_stall_timeout;
        integer sum_before;
        integer output_before;
        begin
            sum_before    = sum_start_count;
            output_before = output_fire_count;
            start_main(MODE_RMS, 128, 32'h00000000);
            wait_main_error(ERR_STALL_TIMEOUT, 5'b0, 0);
            if ((sum_start_count - sum_before) != 1 ||
                output_fire_count != output_before) begin
                fail_case("stall watchdog command reached output or missed sum start");
            end
            $display("[NPU-NORM][CASE] stall-timeout atomic-error active=%0d",
                     active_cycles_o);
        end
    endtask

    task automatic run_command_timeout;
        integer wait_cycles;
        begin
            while (timeout_ready_o !== 1'b1) begin
                @(negedge clk_i);
            end
            timeout_mode_i          = MODE_RMS;
            timeout_element_count_i = 11'd128;
            timeout_eps_bits_i      = 32'h00000000;
            timeout_start_i         = 1'b1;
            @(posedge clk_i);
            #1;
            timeout_start_i = 1'b0;
            if (timeout_busy_o !== 1'b1 || timeout_out_valid_o !== 1'b0) begin
                fail_case("command-timeout DUT did not accept header");
            end

            wait_cycles = 0;
            while (timeout_done_o !== 1'b1) begin
                @(posedge clk_i);
                #1;
                wait_cycles = wait_cycles + 1;
                if (timeout_out_valid_o !== 1'b0 ||
                    timeout_elements_emitted_o !== 0) begin
                    fail_case("command-timeout DUT exposed output");
                end
                if (wait_cycles > 20) begin
                    fail_case("command watchdog missed configured bound");
                end
            end
            if (timeout_error_o !== 1'b1 ||
                timeout_error_code_o !== ERR_COMMAND_TIMEOUT ||
                timeout_flags_o !== 0 || timeout_elements_accepted_o !== 0 ||
                timeout_elements_emitted_o !== 0 || timeout_out_valid_o !== 1'b0 ||
                timeout_lane_ready_o !== 1'b0 || timeout_out_bits_o !== 32'b0 ||
                timeout_out_index_o !== 0 || timeout_out_last_o !== 1'b0 ||
                timeout_active_cycles_o !== 12) begin
                fail_case($sformatf("command watchdog terminal mismatch code=%0d active=%0d",
                                    timeout_error_code_o, timeout_active_cycles_o));
            end
            @(posedge clk_i);
            #1;
            if (timeout_done_o !== 1'b0 || timeout_error_o !== 1'b0 ||
                timeout_error_code_o !== ERR_NONE || timeout_ready_o !== 1'b1 ||
                timeout_busy_o !== 1'b0) begin
                fail_case("command watchdog terminal/code was not one cycle");
            end
            completed_cases = completed_cases + 1;
            $display("[NPU-NORM][CASE] command-timeout atomic-error active=12");
        end
    endtask

    integer init_i;
    initial begin
        cycle_count       = 0;
        completed_cases   = 0;
        sum_start_count   = 0;
        sum_terminal_count = 0;
        square_req_count  = 0;
        square_rsp_count  = 0;
        widen_req_count   = 0;
        widen_rsp_count   = 0;
        add64_req_count   = 0;
        add64_rsp_count   = 0;
        scale_req_count   = 0;
        scale_rsp_count   = 0;
        convert_req_count = 0;
        convert_rsp_count = 0;
        eps_req_count     = 0;
        eps_rsp_count     = 0;
        sqrt_req_count    = 0;
        sqrt_rsp_count    = 0;
        div_req_count     = 0;
        div_rsp_count     = 0;
        mul_req_count     = 0;
        mul_rsp_count     = 0;
        output_fire_count = 0;
        output_hold_active_q = 1'b0;
        output_hold_bits_q   = 32'b0;
        output_hold_index_q  = {COUNT_WIDTH{1'b0}};
        output_hold_last_q   = 1'b0;

        rst_i           = 1'b1;
        start_i         = 1'b0;
        mode_i          = MODE_RMS;
        element_count_i = {COUNT_WIDTH{1'b0}};
        eps_bits_i      = 32'b0;
        lane_valid_i    = 1'b0;
        lane_bits_i     = 32'b0;
        out_ready_i     = 1'b0;

        timeout_rst_i           = 1'b1;
        timeout_start_i         = 1'b0;
        timeout_mode_i          = MODE_RMS;
        timeout_element_count_i = {COUNT_WIDTH{1'b0}};
        timeout_eps_bits_i      = 32'b0;
        timeout_lane_valid_i    = 1'b0;
        timeout_lane_bits_i     = 32'b0;
        timeout_out_ready_i     = 1'b0;

        for (init_i = 0; init_i < MAX_D; init_i = init_i + 1) begin
            input_mem[init_i]    = 32'b0;
            expected_mem[init_i] = 32'b0;
        end

        repeat (3) begin
            @(posedge clk_i);
            #1;
            if (ready_o !== 1'b0 || busy_o !== 1'b0 || done_o !== 1'b0 ||
                out_valid_o !== 1'b0 || timeout_ready_o !== 1'b0 ||
                timeout_busy_o !== 1'b0 || timeout_done_o !== 1'b0 ||
                timeout_out_valid_o !== 1'b0) begin
                fail_case("startup reset did not quiesce both engines");
            end
        end
        @(negedge clk_i);
        rst_i         = 1'b0;
        timeout_rst_i = 1'b0;
        #1;
        if (ready_o !== 1'b1 || timeout_ready_o !== 1'b1) begin
            fail_case("engines did not enter IDLE after reset release");
        end

        run_resident_reset();

        // RMS D=128: ordered mean=4, epsilon位置固定在F32 mean之后。
        for (init_i = 0; init_i < 128; init_i = init_i + 1) begin
            input_mem[init_i] = (init_i[0] == 1'b0) ? 32'h40000000 : 32'hc0000000;
            expected_mem[init_i] =
                (init_i[0] == 1'b0) ? 32'h3f000000 : 32'hbf000000;
        end
        run_success("rms-d128-alt2-eps12", MODE_RMS, 128, 32'h41400000,
                    5'h00, 3, 70, 1);

        // RMS Qwen最大D边界：mean=1、scale=1，逐bit重放输入。
        for (init_i = 0; init_i < 1024; init_i = init_i + 1) begin
            input_mem[init_i] =
                (init_i[0] == 1'b0) ? 32'h3f800000 : 32'hbf800000;
            expected_mem[init_i] = input_mem[init_i];
        end
        run_success("rms-d1024-alt1", MODE_RMS, 1024, 32'h00000000,
                    5'h00, -1, 0, 0);

        // 中间capability D=256同样走exact exponent subtract，不走F32 divide。
        for (init_i = 0; init_i < 256; init_i = init_i + 1) begin
            input_mem[init_i] =
                (init_i[0] == 1'b0) ? 32'h3f800000 : 32'hbf800000;
            expected_mem[init_i] = input_mem[init_i];
        end
        run_success("rms-d256-alt1", MODE_RMS, 256, 32'h00000000,
                    5'h00, -1, 0, 0);

        // L2 epsilon floor: x0=2、其余混合signed zero。
        for (init_i = 0; init_i < 128; init_i = init_i + 1) begin
            input_mem[init_i] =
                (init_i == 0) ? 32'h40000000 :
                ((init_i[0] == 1'b0) ? 32'h00000000 : 32'h80000000);
            expected_mem[init_i] =
                (init_i == 0) ? 32'h3f000000 : input_mem[init_i];
        end
        run_success("l2-floor-x2-eps4", MODE_L2, 128, 32'h40800000,
                    5'h00, 5, 4, 0);

        // L2 equality边界：norm=eps=4，maximumNumber保持norm。
        for (init_i = 0; init_i < 128; init_i = init_i + 1) begin
            input_mem[init_i] =
                (init_i == 0) ? 32'h40800000 :
                ((init_i[0] == 1'b0) ? 32'h00000000 : 32'h80000000);
            expected_mem[init_i] =
                (init_i == 0) ? 32'h3f800000 : input_mem[init_i];
        end
        run_success("l2-equal-x4-eps4", MODE_L2, 128, 32'h40800000,
                    5'h00, -1, 0, 0);

        // eps=0且norm=1，覆盖+0/-0乘正scale后的符号保持。
        for (init_i = 0; init_i < 128; init_i = init_i + 1) begin
            input_mem[init_i] =
                (init_i == 0) ? 32'h3f800000 :
                ((init_i[0] == 1'b0) ? 32'h00000000 : 32'h80000000);
            expected_mem[init_i] = input_mem[init_i];
        end
        run_success("l2-signed-zero-boundary", MODE_L2, 128, 32'h00000000,
                    5'h00, -1, 0, 0);

        // min-normal平方gradual underflow到+0；UF|NX必须sticky成功。
        for (init_i = 0; init_i < 128; init_i = init_i + 1) begin
            input_mem[init_i]    = 32'h00800000;
            expected_mem[init_i] = 32'h00800000;
        end
        run_success("rms-square-ufnx-continues", MODE_RMS, 128, 32'h3f800000,
                    5'h03, -1, 0, 0);

        // 2^-74平方为exact FP32 2^-148；mean=2^-155只在F64->F32
        // 窄化边界产生UF|NX，父事务仍须提交原输入乘1的逐bit结果。
        for (init_i = 0; init_i < 128; init_i = init_i + 1) begin
            input_mem[init_i]    = (init_i == 0) ? 32'h1a800000 : 32'h00000000;
            expected_mem[init_i] = input_mem[init_i];
        end
        run_success("rms-narrow-ufnx-continues", MODE_RMS, 128, 32'h3f800000,
                    5'h03, -1, 0, 0);

        run_header_error("illegal-mode", 2'd2, 128, 32'h00000000,
                         ERR_HEADER_MODE);
        run_header_error("rms-illegal-d", MODE_RMS, 127, 32'h00000000,
                         ERR_HEADER_D);
        run_header_error("l2-illegal-d", MODE_L2, 256, 32'h00000000,
                         ERR_HEADER_D);
        run_header_error("epsilon-negative-zero", MODE_RMS, 128, 32'h80000000,
                         ERR_HEADER_EPS);
        run_header_error("epsilon-negative-finite", MODE_RMS, 128, 32'hbf800000,
                         ERR_HEADER_EPS);
        run_header_error("epsilon-positive-inf", MODE_RMS, 128, 32'h7f800000,
                         ERR_HEADER_EPS);
        run_header_error("epsilon-qnan", MODE_RMS, 128, 32'h7fc12345,
                         ERR_HEADER_EPS);

        run_input_error("input-qnan", 32'h7fc12345, 5'h00, 0);
        run_input_error("input-negative-inf", 32'hff800000, 5'h00, 0);
        run_input_error("square-overflow", 32'h5f800000, 5'h05, 1);

        // 全零RMS且eps=0：sqrt结果+0，reciprocal前原子拒绝。
        for (init_i = 0; init_i < 128; init_i = init_i + 1) begin
            input_mem[init_i] = 32'h00000000;
        end
        run_full_row_error("zero-denominator", MODE_RMS, 32'h00000000,
                           ERR_DEN_ZERO, 5'h00);

        // 每项square有限，但L2 serial sum窄化至F32时overflow。
        for (init_i = 0; init_i < 128; init_i = init_i + 1) begin
            input_mem[init_i] = 32'h5f7fffff;
        end
        run_full_row_error("f64-to-f32-overflow", MODE_L2, 32'h00000000,
                           ERR_CONVERT_FATAL, 5'h05);

        run_stall_timeout();
        run_command_timeout();

        if (completed_cases != 23) begin
            fail_case($sformatf("completed_cases=%0d expected=23", completed_cases));
        end

        $display("[NPU-NORM][INFO] cases=%0d direct-child-cardinality=closed precommit=atomic stream-hold=stable",
                 completed_cases);
        $display("[NPU-NORM][PASS]");
        $finish;
    end

endmodule
