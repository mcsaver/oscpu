`timescale 1ns/1ps

module tb_fp64_pow2_scale;

    logic        clk_i;
    logic        rst_i;
    logic        req_valid_i;
    logic        req_ready_o;
    logic [63:0] req_sum_i;
    logic [10:0] req_d_i;
    logic        rsp_valid_o;
    logic        rsp_ready_i;
    logic [63:0] rsp_result_o;
    logic [4:0]  rsp_flags_o;
    logic        rsp_error_o;

    int unsigned checks;
    int unsigned failures;

    TensorNpuFp64Pow2Scale dut (
        .clk_i        (clk_i),
        .rst_i        (rst_i),
        .req_valid_i  (req_valid_i),
        .req_ready_o  (req_ready_o),
        .req_sum_i    (req_sum_i),
        .req_d_i      (req_d_i),
        .rsp_valid_o  (rsp_valid_o),
        .rsp_ready_i  (rsp_ready_i),
        .rsp_result_o (rsp_result_o),
        .rsp_flags_o  (rsp_flags_o),
        .rsp_error_o  (rsp_error_o)
    );

    initial clk_i = 1'b0;
    always #5 clk_i <= ~clk_i;

    task automatic check_true(input logic condition, input string label_text);
        begin
            checks = checks + 1;
            if (condition !== 1'b1) begin
                failures = failures + 1;
                $display("[NPU-FP64-POW2-SCALE][FAIL] %s", label_text);
            end
        end
    endtask

    task automatic transact_and_check(
        input logic [63:0] sum_bits,
        input logic [10:0] d_value,
        input logic [63:0] expected_result,
        input logic expected_error,
        input string label_text
    );
        begin
            check_true(req_ready_o === 1'b1,
                       $sformatf("%s request credit", label_text));

            @(negedge clk_i);
            req_sum_i   = sum_bits;
            req_d_i     = d_value;
            req_valid_i = 1'b1;
            rsp_ready_i = 1'b0;

            @(posedge clk_i);
            #1;
            check_true(rsp_valid_o === 1'b1,
                       $sformatf("%s registered response", label_text));
            check_true(req_ready_o === 1'b0,
                       $sformatf("%s single-outstanding backpressure", label_text));
            check_true(rsp_result_o === expected_result,
                       $sformatf("%s result got=%016h expected=%016h",
                                 label_text, rsp_result_o, expected_result));
            check_true(rsp_flags_o === 5'b00000,
                       $sformatf("%s flags got=%02h", label_text, rsp_flags_o));
            check_true(rsp_error_o === expected_error,
                       $sformatf("%s error got=%0b expected=%0b",
                                 label_text, rsp_error_o, expected_error));

            @(negedge clk_i);
            req_valid_i = 1'b0;
            rsp_ready_i = 1'b1;

            @(posedge clk_i);
            #1;
            check_true(rsp_valid_o === 1'b0,
                       $sformatf("%s response consumed", label_text));
            check_true(req_ready_o === 1'b1,
                       $sformatf("%s request credit restored", label_text));

            @(negedge clk_i);
            rsp_ready_i = 1'b0;
        end
    endtask

    task automatic test_held_response_and_busy_request;
        logic [63:0] held_result;
        logic [4:0]  held_flags;
        logic        held_error;
        int unsigned hold_cycle;
        begin
            @(negedge clk_i);
            req_sum_i   = 64'h4078_0000_0000_0000; // 384 / 256 = 1.5
            req_d_i     = 11'd256;
            req_valid_i = 1'b1;
            rsp_ready_i = 1'b0;

            @(posedge clk_i);
            #1;
            check_true(rsp_valid_o === 1'b1,
                       "held-response setup valid");
            check_true(rsp_result_o === 64'h3FF8_0000_0000_0000,
                       "held-response setup result");
            held_result = rsp_result_o;
            held_flags  = rsp_flags_o;
            held_error  = rsp_error_o;

            // Present a different request throughout backpressure.  Because
            // req_ready_o is low, it must neither replace nor queue a response.
            @(negedge clk_i);
            req_sum_i   = 64'h7FF8_0000_0000_0001;
            req_d_i     = 11'd127;
            req_valid_i = 1'b1;

            for (hold_cycle = 0; hold_cycle < 3; hold_cycle = hold_cycle + 1) begin
                @(posedge clk_i);
                #1;
                check_true(req_ready_o === 1'b0,
                           $sformatf("busy request denied cycle=%0d", hold_cycle));
                check_true(rsp_valid_o === 1'b1,
                           $sformatf("held valid cycle=%0d", hold_cycle));
                check_true(rsp_result_o === held_result,
                           $sformatf("held result stable cycle=%0d", hold_cycle));
                check_true(rsp_flags_o === held_flags,
                           $sformatf("held flags stable cycle=%0d", hold_cycle));
                check_true(rsp_error_o === held_error,
                           $sformatf("held error stable cycle=%0d", hold_cycle));
            end

            @(negedge clk_i);
            req_valid_i = 1'b0;
            rsp_ready_i = 1'b1;

            @(posedge clk_i);
            #1;
            check_true(rsp_valid_o === 1'b0,
                       "held response consumed once");

            @(negedge clk_i);
            rsp_ready_i = 1'b0;
            repeat (2) begin
                @(posedge clk_i);
                #1;
                check_true(rsp_valid_o === 1'b0,
                           "busy request did not queue stale response");
            end
        end
    endtask

    task automatic test_reset_cancellation;
        begin
            @(negedge clk_i);
            req_sum_i   = 64'h4090_0000_0000_0000;
            req_d_i     = 11'd1024;
            req_valid_i = 1'b1;
            rsp_ready_i = 1'b0;

            @(posedge clk_i);
            #1;
            check_true(rsp_valid_o === 1'b1,
                       "reset-cancel resident response exists");

            @(negedge clk_i);
            req_valid_i = 1'b0;
            rst_i       = 1'b1;

            @(posedge clk_i);
            #1;
            check_true(rsp_valid_o === 1'b0,
                       "reset cancels resident response");
            check_true(rsp_result_o === 64'h0000_0000_0000_0000,
                       "reset clears resident payload");
            check_true(rsp_error_o === 1'b0,
                       "reset clears resident error");
            check_true(rsp_flags_o === 5'b00000,
                       "reset leaves constant flags clear");

            @(negedge clk_i);
            rst_i = 1'b0;

            repeat (2) begin
                @(posedge clk_i);
                #1;
                check_true(rsp_valid_o === 1'b0,
                           "no stale post-reset response");
            end
        end
    endtask

    initial begin
        rst_i        = 1'b1;
        req_valid_i  = 1'b0;
        req_sum_i    = 64'h0000_0000_0000_0000;
        req_d_i      = 11'd0;
        rsp_ready_i  = 1'b0;
        checks       = 0;
        failures     = 0;

        repeat (2) @(posedge clk_i);
        #1;
        check_true(req_ready_o === 1'b0,
                   "reset suppresses request credit");
        check_true(rsp_valid_o === 1'b0,
                   "reset suppresses response");
        @(negedge clk_i);
        rst_i = 1'b0;
        @(posedge clk_i);
        #1;
        check_true(req_ready_o === 1'b1, "reset enters EMPTY state");
        check_true(rsp_valid_o === 1'b0, "deasserted reset has no response");

        // +0 bypass for every supported power-of-two divisor.
        transact_and_check(64'h0000_0000_0000_0000, 11'd128,
                           64'h0000_0000_0000_0000, 1'b0, "+0 D=128");
        transact_and_check(64'h0000_0000_0000_0000, 11'd256,
                           64'h0000_0000_0000_0000, 1'b0, "+0 D=256");
        transact_and_check(64'h0000_0000_0000_0000, 11'd1024,
                           64'h0000_0000_0000_0000, 1'b0, "+0 D=1024");

        // D/D and 1.5 fraction preservation for all supported D values.
        transact_and_check(64'h4060_0000_0000_0000, 11'd128,
                           64'h3FF0_0000_0000_0000, 1'b0, "128/128");
        transact_and_check(64'h4070_0000_0000_0000, 11'd256,
                           64'h3FF0_0000_0000_0000, 1'b0, "256/256");
        transact_and_check(64'h4090_0000_0000_0000, 11'd1024,
                           64'h3FF0_0000_0000_0000, 1'b0, "1024/1024");
        transact_and_check(64'h4068_0000_0000_0000, 11'd128,
                           64'h3FF8_0000_0000_0000, 1'b0, "1.5 fraction D=128");
        transact_and_check(64'h4078_0000_0000_0000, 11'd256,
                           64'h3FF8_0000_0000_0000, 1'b0, "1.5 fraction D=256");
        transact_and_check(64'h4098_0000_0000_0000, 11'd1024,
                           64'h3FF8_0000_0000_0000, 1'b0, "1.5 fraction D=1024");

        // Minimum nonzero F32-square provenance, 2^-149, remains normal in F64.
        transact_and_check(64'h36A0_0000_0000_0000, 11'd128,
                           64'h3630_0000_0000_0000, 1'b0, "2^-149 / 128");
        transact_and_check(64'h36A0_0000_0000_0000, 11'd256,
                           64'h3620_0000_0000_0000, 1'b0, "2^-149 / 256");
        transact_and_check(64'h36A0_0000_0000_0000, 11'd1024,
                           64'h3600_0000_0000_0000, 1'b0, "2^-149 / 1024");

        // Arbitrary fraction bits and the accepted upper exponent boundary.
        transact_and_check(64'h4001_2345_6789_ABCD, 11'd256,
                           64'h3F81_2345_6789_ABCD, 1'b0, "fraction bit preservation");
        transact_and_check(64'h488F_EDCB_A987_6543, 11'd1024,
                           64'h47EF_EDCB_A987_6543, 1'b0, "upper provenance boundary");

        // Unsupported D and every rejected binary64 class/range fail atomically.
        transact_and_check(64'h4060_0000_0000_0000, 11'd0,
                           64'h0000_0000_0000_0000, 1'b1, "illegal D=0");
        transact_and_check(64'h4060_0000_0000_0000, 11'd127,
                           64'h0000_0000_0000_0000, 1'b1, "illegal D=127");
        transact_and_check(64'h4060_0000_0000_0000, 11'd512,
                           64'h0000_0000_0000_0000, 1'b1, "illegal D=512");
        transact_and_check(64'h8000_0000_0000_0000, 11'd128,
                           64'h0000_0000_0000_0000, 1'b1, "negative zero");
        transact_and_check(64'hBFF0_0000_0000_0000, 11'd128,
                           64'h0000_0000_0000_0000, 1'b1, "negative normal");
        transact_and_check(64'h0000_0000_0000_0001, 11'd128,
                           64'h0000_0000_0000_0000, 1'b1, "positive subnormal");
        transact_and_check(64'h7FF0_0000_0000_0000, 11'd128,
                           64'h0000_0000_0000_0000, 1'b1, "positive infinity");
        transact_and_check(64'h7FF8_0000_0000_0001, 11'd128,
                           64'h0000_0000_0000_0000, 1'b1, "quiet NaN");
        transact_and_check(64'h3690_0000_0000_0000, 11'd128,
                           64'h0000_0000_0000_0000, 1'b1, "exponent below 36A");
        transact_and_check(64'h4890_0000_0000_0000, 11'd1024,
                           64'h0000_0000_0000_0000, 1'b1, "exponent above 488");
        transact_and_check(64'h0070_0000_0000_0000, 11'd128,
                           64'h0000_0000_0000_0000, 1'b1, "exponent cannot subtract k");

        test_held_response_and_busy_request();
        test_reset_cancellation();

        if (failures == 0) begin
            $display("[NPU-FP64-POW2-SCALE][PASS] checks=%0d assertions=off waveform=off optimization=O3",
                     checks);
            $finish;
        end else begin
            $fatal(1, "[NPU-FP64-POW2-SCALE][FAIL] failures=%0d checks=%0d",
                   failures, checks);
        end
    end

endmodule
