`timescale 1ns/1ps

// 所有 oracle 均为冻结的 IEEE-754 raw bits；不使用 real/shortreal、DPI
// 或 host 浮点计算。PERFORMANCE=0 的每笔事务均受 48-cycle timeout 约束。
module tb_fp32_div;

    reg         clk_i;
    reg         rst_i;
    reg         req_valid_i;
    wire        req_ready_o;
    reg  [31:0] lhs_bits_i;
    reg  [31:0] rhs_bits_i;
    wire        rsp_valid_o;
    reg         rsp_ready_i;
    wire [31:0] result_bits_o;
    wire [4:0]  flags_o;

    integer cycle_count;
    integer reference_latency;
    integer completed_cases;

    TensorNpuFp32Div dut (
        .clk_i         (clk_i),
        .rst_i         (rst_i),
        .req_valid_i   (req_valid_i),
        .req_ready_o   (req_ready_o),
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
        if (cycle_count >= 700) begin
            $display("[NPU-FP32-DIV][FAIL] global timeout cycle=%0d",
                     cycle_count + 1);
            $fatal(1);
        end
    end

    task automatic fail_case(input string reason);
        begin
            $display("[NPU-FP32-DIV][FAIL] %s cycle=%0d", reason,
                     cycle_count);
            $fatal(1);
        end
    endtask

    task automatic run_case(
        input string       case_name,
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

            lhs_bits_i  = case_lhs;
            rhs_bits_i  = case_rhs;
            req_valid_i = 1'b1;
            @(posedge clk_i);
            @(negedge clk_i);
            fire_cycle = cycle_count;

            if (req_ready_o !== 1'b0) begin
                fail_case($sformatf("%s did not enter CORE_BUSY", case_name));
            end

            // busy 周期保持另一个请求；ready 必须拒绝且 resident payload 不变。
            if (probe_busy != 0) begin
                lhs_bits_i = 32'h00000000;
                rhs_bits_i = 32'h00000000;
                @(posedge clk_i);
                @(negedge clk_i);
                if (req_ready_o !== 1'b0) begin
                    fail_case($sformatf("%s accepted request while busy",
                                        case_name));
                end
            end
            req_valid_i = 1'b0;

            wait_cycles = 0;
            while (rsp_valid_o !== 1'b1) begin
                if (req_ready_o !== 1'b0) begin
                    fail_case($sformatf("%s reopened request before response",
                                        case_name));
                end
                @(posedge clk_i);
                @(negedge clk_i);
                wait_cycles = wait_cycles + 1;
                if (wait_cycles > 48) begin
                    fail_case($sformatf("%s exceeded 48-cycle timeout",
                                        case_name));
                end
            end

            response_latency = cycle_count - fire_cycle;
            if (response_latency > 48) begin
                fail_case($sformatf("%s latency=%0d exceeds bound", case_name,
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
                fail_case($sformatf("%s request ready while response valid",
                                    case_name));
            end

            held_result = result_bits_o;
            held_flags  = flags_o;
            for (hold_index = 0; hold_index < hold_cycles;
                 hold_index = hold_index + 1) begin
                @(posedge clk_i);
                @(negedge clk_i);
                if (rsp_valid_o !== 1'b1) begin
                    fail_case($sformatf("%s dropped backpressured response",
                                        case_name));
                end
                if ((result_bits_o !== held_result) || (flags_o !== held_flags)) begin
                    fail_case($sformatf("%s changed backpressured payload",
                                        case_name));
                end
                if (req_ready_o !== 1'b0) begin
                    fail_case($sformatf("%s reopened request under backpressure",
                                        case_name));
                end
            end

            rsp_ready_i = 1'b1;
            @(posedge clk_i);
            @(negedge clk_i);
            if (rsp_valid_o !== 1'b0) begin
                fail_case($sformatf("%s response was not consumed", case_name));
            end
            if (req_ready_o !== 1'b1) begin
                fail_case($sformatf("%s did not return to IDLE", case_name));
            end

            @(posedge clk_i);
            @(negedge clk_i);
            if (rsp_valid_o !== 1'b0) begin
                fail_case($sformatf("%s response repeated", case_name));
            end
            rsp_ready_i = 1'b0;
            completed_cases = completed_cases + 1;
        end
    endtask

    initial begin
        cycle_count       = 0;
        reference_latency = -1;
        completed_cases   = 0;
        rst_i             = 1'b1;
        req_valid_i       = 1'b0;
        lhs_bits_i        = 32'b0;
        rhs_bits_i        = 32'b0;
        rsp_ready_i       = 1'b0;

        repeat (3) @(posedge clk_i);
        @(negedge clk_i);
        if ((req_ready_o !== 1'b0) || (rsp_valid_o !== 1'b0)
                || (result_bits_o !== 32'b0) || (flags_o !== 5'b0)) begin
            fail_case("startup reset did not clear protocol/payload");
        end
        rst_i = 1'b0;
        @(posedge clk_i);
        @(negedge clk_i);
        if (req_ready_o !== 1'b1) begin
            fail_case("request channel did not open after reset");
        end

        // 在途 reset：同时取消 wrapper resident transaction 与 fp_fdiv FSM。
        lhs_bits_i  = 32'h3f800000;
        rhs_bits_i  = 32'h42fe0000;
        req_valid_i = 1'b1;
        @(posedge clk_i);
        @(negedge clk_i);
        req_valid_i = 1'b0;
        repeat (5) begin
            @(posedge clk_i);
            @(negedge clk_i);
        end
        rst_i = 1'b1;
        repeat (2) @(posedge clk_i);
        @(negedge clk_i);
        if ((req_ready_o !== 1'b0) || (rsp_valid_o !== 1'b0)
                || (result_bits_o !== 32'b0) || (flags_o !== 5'b0)) begin
            fail_case("in-flight reset did not cancel/clear transaction");
        end
        rst_i = 1'b0;

        // 超过一次 PERFORMANCE=0 正常延迟，证明取消事务不会产生 stale response。
        repeat (40) begin
            @(posedge clk_i);
            @(negedge clk_i);
            if (rsp_valid_o !== 1'b0) begin
                fail_case("reset-canceled transaction produced stale response");
            end
            if (req_ready_o !== 1'b1) begin
                fail_case("request channel not idle after reset cancellation");
            end
        end

        run_case("one_over_127", 32'h3f800000, 32'h42fe0000,
                 32'h3c010204, 5'b00001, 3, 1);
        run_case("one_over_rounded_d", 32'h3f800000, 32'h3c010204,
                 32'h42fe0000, 5'b00001, 0, 0);
        run_case("positive_zero", 32'h00000000, 32'h40000000,
                 32'h00000000, 5'b00000, 0, 0);
        run_case("negative_zero", 32'h80000000, 32'h40000000,
                 32'h80000000, 5'b00000, 0, 0);
        run_case("ordinary_exact", 32'h40f00000, 32'h40000000,
                 32'h40700000, 5'b00000, 0, 0);
        run_case("normal_to_subnormal", 32'h00800000, 32'h40000000,
                 32'h00400000, 5'b00000, 0, 0);
        run_case("min_subnormal_identity", 32'h00000001, 32'h3f800000,
                 32'h00000001, 5'b00000, 0, 0);
        run_case("infinity", 32'h7f800000, 32'h40000000,
                 32'h7f800000, 5'b00000, 0, 0);
        run_case("finite_over_infinity", 32'h3f800000, 32'h7f800000,
                 32'h00000000, 5'b00000, 0, 0);
        run_case("quiet_nan", 32'h7fc12345, 32'h3f800000,
                 32'h7fc00000, 5'b00000, 0, 0);
        run_case("signaling_nan", 32'h7f800001, 32'h3f800000,
                 32'h7fc00000, 5'b10000, 0, 0);
        run_case("divide_by_zero", 32'h3f800000, 32'h00000000,
                 32'h7f800000, 5'b01000, 0, 0);
        run_case("zero_over_zero", 32'h00000000, 32'h00000000,
                 32'h7fc00000, 5'b10000, 0, 0);

        if (completed_cases != 13) begin
            fail_case($sformatf("completed_cases=%0d expected=13",
                                completed_cases));
        end
        $display("[NPU-FP32-DIV][PASS] cases=%0d latency=%0d performance=0 timeout=48 backpressure=stable reset=clean",
                 completed_cases, reference_latency);
        $finish;
    end

endmodule
