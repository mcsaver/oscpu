`timescale 1ns/1ps

module tb_fp32_square_sum64;

    localparam integer MAX_D = 1024;
    localparam integer COUNT_WIDTH = $clog2(MAX_D + 1);

    localparam logic [3:0] ERR_NONE            = 4'd0;
    localparam logic [3:0] ERR_COUNT           = 4'd1;
    localparam logic [3:0] ERR_INPUT_NONFINITE = 4'd2;
    localparam logic [3:0] ERR_SQUARE_OVERFLOW = 4'd4;
    localparam logic [3:0] ERR_STALL_TIMEOUT   = 4'd9;
    localparam logic [3:0] ERR_COMMAND_TIMEOUT = 4'd10;

    logic clk_i;
    logic rst_i;

    logic                         start_i;
    wire                          ready_o;
    wire                          busy_o;
    logic [COUNT_WIDTH-1:0]       element_count_i;
    logic                         lane_valid_i;
    wire                          lane_ready_o;
    logic [31:0]                  lane_bits_i;
    wire                          done_o;
    wire                          error_o;
    wire [3:0]                    error_code_o;
    wire [63:0]                   sum_bits_o;
    wire [4:0]                    flags_o;
    wire                          committed_row_valid_o;
    wire [COUNT_WIDTH-1:0]        committed_count_o;
    logic [COUNT_WIDTH-1:0]       replay_index_i;
    wire                          replay_valid_o;
    wire [31:0]                   replay_bits_o;
    wire [COUNT_WIDTH-1:0]        elements_accepted_o;
    wire [31:0]                   active_cycles_o;

    TensorNpuFp32SquareSum64 #(
        .MAX_D                  (MAX_D),
        .STALL_TIMEOUT_CYCLES   (32'd12),
        .COMMAND_TIMEOUT_CYCLES (32'd50000)
    ) dut (
        .clk_i                  (clk_i),
        .rst_i                  (rst_i),
        .start_i                (start_i),
        .ready_o                (ready_o),
        .busy_o                 (busy_o),
        .element_count_i        (element_count_i),
        .lane_valid_i           (lane_valid_i),
        .lane_ready_o           (lane_ready_o),
        .lane_bits_i            (lane_bits_i),
        .done_o                 (done_o),
        .error_o                (error_o),
        .error_code_o           (error_code_o),
        .sum_bits_o             (sum_bits_o),
        .flags_o                (flags_o),
        .committed_row_valid_o  (committed_row_valid_o),
        .committed_count_o      (committed_count_o),
        .replay_index_i         (replay_index_i),
        .replay_valid_o         (replay_valid_o),
        .replay_bits_o          (replay_bits_o),
        .elements_accepted_o    (elements_accepted_o),
        .active_cycles_o        (active_cycles_o)
    );

    // 独立小参数实例让 command watchdog 在 stall watchdog 之前确定触发。
    logic       timeout_rst_i;
    logic       timeout_start_i;
    wire        timeout_ready_o;
    wire        timeout_busy_o;
    logic [2:0] timeout_element_count_i;
    logic       timeout_lane_valid_i;
    wire        timeout_lane_ready_o;
    logic [31:0] timeout_lane_bits_i;
    wire        timeout_done_o;
    wire        timeout_error_o;
    wire [3:0]  timeout_error_code_o;
    wire [63:0] timeout_sum_bits_o;
    wire [4:0]  timeout_flags_o;
    wire        timeout_committed_row_valid_o;
    wire [2:0]  timeout_committed_count_o;
    logic [2:0] timeout_replay_index_i;
    wire        timeout_replay_valid_o;
    wire [31:0] timeout_replay_bits_o;
    wire [2:0]  timeout_elements_accepted_o;
    wire [31:0] timeout_active_cycles_o;

    TensorNpuFp32SquareSum64 #(
        .MAX_D                  (4),
        .STALL_TIMEOUT_CYCLES   (32'd32),
        .COMMAND_TIMEOUT_CYCLES (32'd4)
    ) timeout_dut (
        .clk_i                  (clk_i),
        .rst_i                  (timeout_rst_i),
        .start_i                (timeout_start_i),
        .ready_o                (timeout_ready_o),
        .busy_o                 (timeout_busy_o),
        .element_count_i        (timeout_element_count_i),
        .lane_valid_i           (timeout_lane_valid_i),
        .lane_ready_o           (timeout_lane_ready_o),
        .lane_bits_i            (timeout_lane_bits_i),
        .done_o                 (timeout_done_o),
        .error_o                (timeout_error_o),
        .error_code_o           (timeout_error_code_o),
        .sum_bits_o             (timeout_sum_bits_o),
        .flags_o                (timeout_flags_o),
        .committed_row_valid_o  (timeout_committed_row_valid_o),
        .committed_count_o      (timeout_committed_count_o),
        .replay_index_i         (timeout_replay_index_i),
        .replay_valid_o         (timeout_replay_valid_o),
        .replay_bits_o          (timeout_replay_bits_o),
        .elements_accepted_o    (timeout_elements_accepted_o),
        .active_cycles_o        (timeout_active_cycles_o)
    );

    logic [31:0] vector_mem [0:MAX_D-1];

    integer cycle_count;
    integer completed_cases;
    integer square_req_count;
    integer square_rsp_count;
    integer widen_req_count;
    integer widen_rsp_count;
    integer add_req_count;
    integer add_rsp_count;

    initial clk_i = 1'b0;
    always #5 clk_i <= ~clk_i;

    always @(posedge clk_i) begin
        cycle_count <= cycle_count + 1;
        if (cycle_count >= 250000) begin
            $display("[NPU-FP32-SQUARE-SUM64][FAIL] global timeout cycle=%0d", cycle_count);
            $fatal(1);
        end

        if (!rst_i) begin
            if (dut.square_req_valid_w && dut.square_req_ready_w) begin
                square_req_count <= square_req_count + 1;
            end
            if (dut.square_rsp_valid_w && dut.square_rsp_ready_w) begin
                square_rsp_count <= square_rsp_count + 1;
            end
            if (dut.widen_req_valid_w && dut.widen_req_ready_w) begin
                widen_req_count <= widen_req_count + 1;
            end
            if (dut.widen_rsp_valid_w && dut.widen_rsp_ready_w) begin
                widen_rsp_count <= widen_rsp_count + 1;
            end
            if (dut.add_req_valid_w && dut.add_req_ready_w) begin
                add_req_count <= add_req_count + 1;
            end
            if (dut.add_rsp_valid_w && dut.add_rsp_ready_w) begin
                add_rsp_count <= add_rsp_count + 1;
            end
        end
    end

    task automatic fail_case(input string reason);
        begin
            $display("[NPU-FP32-SQUARE-SUM64][FAIL] %s cycle=%0d", reason, cycle_count);
            $fatal(1);
        end
    endtask

    task automatic start_main(input integer command_count);
        begin
            while (ready_o !== 1'b1) begin
                @(negedge clk_i);
            end
            element_count_i = command_count[COUNT_WIDTH-1:0];
            start_i = 1'b1;
            @(posedge clk_i);
            #1;
            start_i = 1'b0;
            if (ready_o !== 1'b0 || busy_o !== 1'b1) begin
                fail_case($sformatf("command count=%0d was not accepted", command_count));
            end
            if (committed_row_valid_o !== 1'b0 || sum_bits_o !== 64'b0) begin
                fail_case("new command did not atomically hide prior committed row/sum");
            end
        end
    endtask

    task automatic send_main_lane(input logic [31:0] lane_bits);
        logic [COUNT_WIDTH-1:0] accepted_before;
        begin
            while (lane_ready_o !== 1'b1) begin
                @(negedge clk_i);
            end
            accepted_before = elements_accepted_o;
            lane_bits_i  = lane_bits;
            lane_valid_i = 1'b1;
            @(posedge clk_i);
            #1;
            lane_valid_i = 1'b0;
            if (elements_accepted_o !==
                (accepted_before + {{(COUNT_WIDTH-1){1'b0}}, 1'b1})) begin
                fail_case($sformatf("lane handshake count mismatch bits=%08x", lane_bits));
            end
            if (lane_ready_o !== 1'b0) begin
                fail_case("lane_ready remained high with a resident element");
            end
        end
    endtask

    task automatic wait_main_terminal(
        input logic        expected_error,
        input logic [3:0]  expected_code,
        input logic [63:0] expected_sum,
        input logic [4:0]  expected_flags,
        input integer      expected_elements
    );
        integer wait_cycles;
        begin
            wait_cycles = 0;
            while (done_o !== 1'b1) begin
                @(posedge clk_i);
                #1;
                wait_cycles = wait_cycles + 1;
                // 最后一个 ADD edge 会原子产生 done 与 committed；只有仍未 terminal 才禁止可见。
                if ((done_o !== 1'b1) &&
                    (committed_row_valid_o !== 1'b0 || sum_bits_o !== 64'b0)) begin
                    fail_case("row/sum became visible before terminal commit");
                end
                if (wait_cycles > 50000) begin
                    fail_case("terminal response exceeded bounded TB wait");
                end
            end

            if (error_o !== expected_error || error_code_o !== expected_code) begin
                fail_case($sformatf("terminal class got error=%b code=%0d expected=%b/%0d",
                                    error_o, error_code_o, expected_error, expected_code));
            end
            if (sum_bits_o !== expected_sum || flags_o !== expected_flags) begin
                fail_case($sformatf("terminal payload got sum=%016x flags=%02x expected=%016x/%02x",
                                    sum_bits_o, flags_o, expected_sum, expected_flags));
            end
            if (elements_accepted_o !== expected_elements[COUNT_WIDTH-1:0]) begin
                fail_case($sformatf("elements_accepted=%0d expected=%0d",
                                    elements_accepted_o, expected_elements));
            end
            if (expected_error) begin
                if (committed_row_valid_o !== 1'b0 || committed_count_o !== 0) begin
                    fail_case("ERROR exposed a partial committed row");
                end
            end else begin
                if (committed_row_valid_o !== 1'b1 ||
                    committed_count_o !== expected_elements[COUNT_WIDTH-1:0]) begin
                    fail_case("successful terminal did not atomically publish row metadata");
                end
            end
            if (active_cycles_o == 0 && expected_code != ERR_COUNT) begin
                fail_case("active cycle evidence did not advance");
            end

            @(posedge clk_i);
            #1;
            if (done_o !== 1'b0 || error_o !== 1'b0 ||
                error_code_o !== ERR_NONE ||
                ready_o !== 1'b1 || busy_o !== 1'b0) begin
                fail_case("terminal/code was not one-cycle when returning to IDLE");
            end
            completed_cases = completed_cases + 1;
        end
    endtask

    task automatic check_replay(input integer element_total);
        integer replay_i;
        begin
            for (replay_i = 0; replay_i < element_total; replay_i = replay_i + 1) begin
                replay_index_i = replay_i[COUNT_WIDTH-1:0];
                #1;
                if (replay_valid_o !== 1'b1 || replay_bits_o !== vector_mem[replay_i]) begin
                    fail_case($sformatf("replay[%0d]=%08x valid=%b expected=%08x",
                                        replay_i, replay_bits_o, replay_valid_o,
                                        vector_mem[replay_i]));
                end
            end
            replay_index_i = element_total[COUNT_WIDTH-1:0];
            #1;
            if (replay_valid_o !== 1'b0 || replay_bits_o !== 32'b0) begin
                fail_case($sformatf("out-of-range replay index=%0d was observable", element_total));
            end
            replay_index_i = {COUNT_WIDTH{1'b1}};
            #1;
            if (replay_valid_o !== 1'b0 || replay_bits_o !== 32'b0) begin
                fail_case("maximum encoded out-of-range replay was observable");
            end
            replay_index_i = {COUNT_WIDTH{1'b0}};
        end
    endtask

    task automatic run_loaded_success(
        input string       case_name,
        input integer      element_total,
        input logic [63:0] expected_sum,
        input logic [4:0]  expected_flags
    );
        integer lane_i;
        integer square_req_before;
        integer square_rsp_before;
        integer widen_req_before;
        integer widen_rsp_before;
        integer add_req_before;
        integer add_rsp_before;
        begin
            square_req_before = square_req_count;
            square_rsp_before = square_rsp_count;
            widen_req_before  = widen_req_count;
            widen_rsp_before  = widen_rsp_count;
            add_req_before    = add_req_count;
            add_rsp_before    = add_rsp_count;

            start_main(element_total);
            for (lane_i = 0; lane_i < element_total; lane_i = lane_i + 1) begin
                send_main_lane(vector_mem[lane_i]);
            end
            wait_main_terminal(1'b0, ERR_NONE, expected_sum, expected_flags,
                               element_total);

            if ((square_req_count - square_req_before) != element_total ||
                (square_rsp_count - square_rsp_before) != element_total ||
                (widen_req_count  - widen_req_before)  != element_total ||
                (widen_rsp_count  - widen_rsp_before)  != element_total ||
                (add_req_count    - add_req_before)    != element_total ||
                (add_rsp_count    - add_rsp_before)    != element_total) begin
                fail_case($sformatf("%s child request/response census mismatch", case_name));
            end
            check_replay(element_total);
            $display("[NPU-FP32-SQUARE-SUM64][CASE] %s sum=%016x flags=%02x active=%0d",
                     case_name, sum_bits_o, flags_o, active_cycles_o);
        end
    endtask

    task automatic run_busy_and_lane_backpressure;
        integer square_req_before;
        integer square_rsp_before;
        integer widen_req_before;
        integer widen_rsp_before;
        integer add_req_before;
        integer add_rsp_before;
        logic [COUNT_WIDTH-1:0] accepted_before;
        begin
            vector_mem[0] = 32'h40000000;
            vector_mem[1] = 32'hc0000000;
            vector_mem[2] = 32'h40000000;
            vector_mem[3] = 32'hc0000000;

            square_req_before = square_req_count;
            square_rsp_before = square_rsp_count;
            widen_req_before  = widen_req_count;
            widen_rsp_before  = widen_rsp_count;
            add_req_before    = add_req_count;
            add_rsp_before    = add_rsp_count;

            start_main(4);
            send_main_lane(vector_mem[0]);
            accepted_before = elements_accepted_o;

            @(negedge clk_i);
            if (ready_o !== 1'b0 || lane_ready_o !== 1'b0) begin
                fail_case("busy/backpressure probe was not in a resident child transaction");
            end
            // 同一确定为 lane_ready=0 的周期同时给 busy start 与 poison lane。
            element_count_i = 1;
            start_i         = 1'b1;
            lane_bits_i     = 32'h7fc12345;
            lane_valid_i    = 1'b1;
            @(posedge clk_i);
            #1;
            start_i      = 1'b0;
            lane_valid_i = 1'b0;
            if (ready_o !== 1'b0 || elements_accepted_o !== accepted_before ||
                committed_row_valid_o !== 1'b0) begin
                fail_case("busy start or backpressured poison lane changed resident command");
            end

            send_main_lane(vector_mem[1]);
            send_main_lane(vector_mem[2]);
            send_main_lane(vector_mem[3]);
            wait_main_terminal(1'b0, ERR_NONE, 64'h4030000000000000, 5'h00, 4);

            if ((square_req_count - square_req_before) != 4 ||
                (square_rsp_count - square_rsp_before) != 4 ||
                (widen_req_count  - widen_req_before)  != 4 ||
                (widen_rsp_count  - widen_rsp_before)  != 4 ||
                (add_req_count    - add_req_before)    != 4 ||
                (add_rsp_count    - add_rsp_before)    != 4) begin
                fail_case("busy/backpressure case changed child transaction cardinality");
            end
            check_replay(4);
            $display("[NPU-FP32-SQUARE-SUM64][CASE] busy-start+lane-backpressure sum=16");
        end
    endtask

    task automatic run_input_error(
        input string       case_name,
        input logic [31:0] bad_bits
    );
        integer square_req_before;
        begin
            square_req_before = square_req_count;
            start_main(1);
            send_main_lane(bad_bits);
            wait_main_terminal(1'b1, ERR_INPUT_NONFINITE, 64'b0, 5'b0, 1);
            if (square_req_count != square_req_before) begin
                fail_case($sformatf("%s reached square child despite input-domain failure", case_name));
            end
            $display("[NPU-FP32-SQUARE-SUM64][CASE] %s atomically rejected", case_name);
        end
    endtask

    task automatic run_square_overflow;
        integer square_req_before;
        integer square_rsp_before;
        integer widen_req_before;
        integer add_req_before;
        begin
            square_req_before = square_req_count;
            square_rsp_before = square_rsp_count;
            widen_req_before  = widen_req_count;
            add_req_before    = add_req_count;
            start_main(1);
            send_main_lane(32'h5f800000); // 2^64；RN32 square 必须 +Inf, OF|NX。
            wait_main_terminal(1'b1, ERR_SQUARE_OVERFLOW, 64'b0, 5'h05, 1);
            if ((square_req_count - square_req_before) != 1 ||
                (square_rsp_count - square_rsp_before) != 1 ||
                widen_req_count != widen_req_before || add_req_count != add_req_before) begin
                fail_case("square overflow was not contained before widen/add");
            end
            $display("[NPU-FP32-SQUARE-SUM64][CASE] square-overflow flags=05 atomic-error");
        end
    endtask

    task automatic run_reset_cancel;
        integer quiet_i;
        begin
            start_main(1);
            while (lane_ready_o !== 1'b1) begin
                @(negedge clk_i);
            end
            lane_bits_i  = 32'h40000000;
            lane_valid_i = 1'b1;
            @(posedge clk_i);
            #1;
            lane_valid_i = 1'b0;
            if (busy_o !== 1'b1 || elements_accepted_o !== 1) begin
                fail_case("reset-cancel lane was not resident");
            end

            // 在 SQUARE_REQ 前同步 reset；parent 与所有 child 都必须取消事务。
            rst_i = 1'b1;
            repeat (2) begin
                @(posedge clk_i);
                #1;
                if (ready_o !== 1'b0 || busy_o !== 1'b0 || done_o !== 1'b0 ||
                    committed_row_valid_o !== 1'b0) begin
                    fail_case("reset did not quiesce parent protocol/commit state");
                end
            end
            @(negedge clk_i);
            rst_i = 1'b0;
            #1;
            if (ready_o !== 1'b1 || done_o !== 1'b0 ||
                committed_row_valid_o !== 1'b0 || sum_bits_o !== 64'b0) begin
                fail_case("reset did not return a clean IDLE parent state");
            end
            for (quiet_i = 0; quiet_i < 8; quiet_i = quiet_i + 1) begin
                @(posedge clk_i);
                #1;
                if (done_o !== 1'b0 || committed_row_valid_o !== 1'b0 ||
                    ready_o !== 1'b1) begin
                    fail_case("canceled child transaction produced a stale parent event");
                end
            end
            completed_cases = completed_cases + 1;
            $display("[NPU-FP32-SQUARE-SUM64][CASE] reset-cancel clean-no-stale-response");
        end
    endtask

    task automatic run_command_timeout;
        integer wait_cycles;
        begin
            while (timeout_ready_o !== 1'b1) begin
                @(negedge clk_i);
            end
            timeout_element_count_i = 3'd1;
            timeout_start_i = 1'b1;
            @(posedge clk_i);
            #1;
            timeout_start_i = 1'b0;
            if (timeout_busy_o !== 1'b1 || timeout_lane_ready_o !== 1'b1) begin
                fail_case("command-timeout DUT did not enter WAIT_LANE");
            end

            wait_cycles = 0;
            while (timeout_done_o !== 1'b1) begin
                @(posedge clk_i);
                #1;
                wait_cycles = wait_cycles + 1;
                if (timeout_committed_row_valid_o !== 1'b0 ||
                    timeout_sum_bits_o !== 64'b0) begin
                    fail_case("command-timeout DUT exposed partial state");
                end
                if (wait_cycles > 8) begin
                    fail_case("command watchdog did not trigger at configured bound");
                end
            end
            if (timeout_error_o !== 1'b1 ||
                timeout_error_code_o !== ERR_COMMAND_TIMEOUT ||
                timeout_flags_o !== 5'b0 || timeout_elements_accepted_o !== 0 ||
                timeout_committed_count_o !== 0 || timeout_active_cycles_o !== 4) begin
                fail_case($sformatf("command watchdog terminal mismatch code=%0d active=%0d",
                                    timeout_error_code_o, timeout_active_cycles_o));
            end
            timeout_replay_index_i = 3'd0;
            #1;
            if (timeout_replay_valid_o !== 1'b0 || timeout_replay_bits_o !== 32'b0) begin
                fail_case("command-timeout DUT exposed replay data");
            end
            @(posedge clk_i);
            #1;
            if (timeout_done_o !== 1'b0 || timeout_error_o !== 1'b0 ||
                timeout_error_code_o !== ERR_NONE ||
                timeout_ready_o !== 1'b1 || timeout_busy_o !== 1'b0) begin
                fail_case("command-timeout terminal/code was not one cycle");
            end
            completed_cases = completed_cases + 1;
            $display("[NPU-FP32-SQUARE-SUM64][CASE] command-timeout active=4 atomic-error");
        end
    endtask

    integer init_i;
    initial begin
        cycle_count      = 0;
        completed_cases  = 0;
        square_req_count = 0;
        square_rsp_count = 0;
        widen_req_count  = 0;
        widen_rsp_count  = 0;
        add_req_count    = 0;
        add_rsp_count    = 0;

        rst_i           = 1'b1;
        start_i         = 1'b0;
        element_count_i = {COUNT_WIDTH{1'b0}};
        lane_valid_i    = 1'b0;
        lane_bits_i     = 32'b0;
        replay_index_i  = {COUNT_WIDTH{1'b0}};

        timeout_rst_i           = 1'b1;
        timeout_start_i         = 1'b0;
        timeout_element_count_i = 3'b0;
        timeout_lane_valid_i    = 1'b0;
        timeout_lane_bits_i     = 32'b0;
        timeout_replay_index_i  = 3'b0;

        for (init_i = 0; init_i < MAX_D; init_i = init_i + 1) begin
            vector_mem[init_i] = 32'b0;
        end

        repeat (3) begin
            @(posedge clk_i);
            #1;
            if (ready_o !== 1'b0 || busy_o !== 1'b0 || done_o !== 1'b0 ||
                committed_row_valid_o !== 1'b0 || replay_valid_o !== 1'b0 ||
                timeout_ready_o !== 1'b0 || timeout_done_o !== 1'b0) begin
                fail_case("startup reset did not quiesce both DUTs");
            end
        end
        @(negedge clk_i);
        rst_i         = 1'b0;
        timeout_rst_i = 1'b0;
        #1;
        if (ready_o !== 1'b1 || timeout_ready_o !== 1'b1) begin
            fail_case("DUTs did not enter IDLE after reset release");
        end

        // 严格 serial RN64 反例：每个 2^-54 term 都单独舍入掉，最终必须仍为 1.0。
        vector_mem[0] = 32'h3f800000;
        vector_mem[1] = 32'h32000000;
        vector_mem[2] = 32'h32000000;
        vector_mem[3] = 32'h32000000;
        run_loaded_success("serial-order-counterexample", 4,
                           64'h3ff0000000000000, 5'h01);
        if (sum_bits_o === 64'h3ff0000000000001) begin
            fail_case("forbidden tree/exact-once result was published");
        end

        run_busy_and_lane_backpressure();

        // square gradual-underflow 的 UF|NX 合法继续并提交 +0。
        vector_mem[0] = 32'h00800000;
        run_loaded_success("square-underflow-legal", 1,
                           64'h0000000000000000, 5'h03);

        run_input_error("qnan-input", 32'h7fc12345);
        run_input_error("negative-infinity-input", 32'hff800000);
        run_square_overflow();

        // count=0 与 count>MAX_D 都在任何 lane/child/commit 前失败。
        start_main(0);
        wait_main_terminal(1'b1, ERR_COUNT, 64'b0, 5'b0, 0);
        $display("[NPU-FP32-SQUARE-SUM64][CASE] invalid-count-0 atomic-error");
        start_main(MAX_D + 1);
        wait_main_terminal(1'b1, ERR_COUNT, 64'b0, 5'b0, 0);
        $display("[NPU-FP32-SQUARE-SUM64][CASE] invalid-count-max-plus-1 atomic-error");

        // 主实例不提供 lane，固定 12 个无进展周期后触发 stall watchdog。
        start_main(1);
        wait_main_terminal(1'b1, ERR_STALL_TIMEOUT, 64'b0, 5'b0, 0);
        $display("[NPU-FP32-SQUARE-SUM64][CASE] stall-timeout active=%0d atomic-error",
                 active_cycles_o);

        run_command_timeout();
        run_reset_cancel();

        // reset-cancel 后再跑一条完整命令，证明无 stale child response 污染。
        vector_mem[0] = 32'h3f800000;
        run_loaded_success("post-reset-clean-command", 1,
                           64'h3ff0000000000000, 5'h00);

        // MAX_D 全零覆盖完整 row buffer 与 0..1023 的逐项 committed replay。
        for (init_i = 0; init_i < MAX_D; init_i = init_i + 1) begin
            vector_mem[init_i] = 32'h00000000;
        end
        run_loaded_success("max-d-1024-zero", MAX_D,
                           64'h0000000000000000, 5'h00);

        if (completed_cases != 13) begin
            fail_case($sformatf("completed_cases=%0d expected=13", completed_cases));
        end

        $display("[NPU-FP32-SQUARE-SUM64][PASS]");
        $finish;
    end

endmodule
