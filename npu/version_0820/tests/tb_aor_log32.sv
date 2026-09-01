`timescale 1ns/1ps

module tb_aor_log32;

    logic        clk_i;
    logic        rst_i;
    logic        req_valid_i;
    wire         req_ready_o;
    logic [31:0] operand_i;
    wire         rsp_valid_o;
    logic        rsp_ready_i;
    wire [31:0]  result_o;
    wire [4:0]   flags_o;
    wire         error_o;
    wire [3:0]   error_code_o;
    wire [31:0]  active_cycles_o;

    logic        timeout_rst_i;
    logic        timeout_req_valid_i;
    wire         timeout_req_ready_o;
    logic [31:0] timeout_operand_i;
    wire         timeout_rsp_valid_o;
    logic        timeout_rsp_ready_i;
    wire [31:0]  timeout_result_o;
    wire [4:0]   timeout_flags_o;
    wire         timeout_error_o;
    wire [3:0]   timeout_error_code_o;
    wire [31:0]  timeout_active_cycles_o;

    logic [31:0] table_input [0:15];
    logic [31:0] table_result [0:15];
    logic [31:0] leading_input [0:22];
    logic [31:0] leading_result [0:22];
    integer      idx;
    logic [3:0]  outstanding_owner_q;

    TensorNpuAorLog32 dut (
        .clk_i           (clk_i),
        .rst_i           (rst_i),
        .req_valid_i     (req_valid_i),
        .req_ready_o     (req_ready_o),
        .operand_i       (operand_i),
        .rsp_valid_o     (rsp_valid_o),
        .rsp_ready_i     (rsp_ready_i),
        .result_o        (result_o),
        .flags_o         (flags_o),
        .error_o         (error_o),
        .error_code_o    (error_code_o),
        .active_cycles_o (active_cycles_o)
    );

    TensorNpuAorLog32 #(
        // launch/classify/normalize/reduce=1..4，Z64 request accepted=5；WAIT response 与 timeout 同拍。
        .COMMAND_TIMEOUT_CYCLES(5)
    ) timeout_dut (
        .clk_i           (clk_i),
        .rst_i           (timeout_rst_i),
        .req_valid_i     (timeout_req_valid_i),
        .req_ready_o     (timeout_req_ready_o),
        .operand_i       (timeout_operand_i),
        .rsp_valid_o     (timeout_rsp_valid_o),
        .rsp_ready_i     (timeout_rsp_ready_i),
        .result_o        (timeout_result_o),
        .flags_o         (timeout_flags_o),
        .error_o         (timeout_error_o),
        .error_code_o    (timeout_error_code_o),
        .active_cycles_o (timeout_active_cycles_o)
    );

    initial clk_i = 1'b0;
    always #5 clk_i <= ~clk_i;

    function automatic logic more_than_one4(input logic [3:0] value);
        logic [3:0] value_minus_one;
        begin
            value_minus_one = value - 4'd1;
            more_than_one4 = (value != 4'b0) && (|(value & value_minus_one));
        end
    endfunction

    wire [3:0] child_req_vector = {
        dut.pack_req_valid, dut.kd_req_valid, dut.fma_req_valid, dut.z64_req_valid
    };
    wire [3:0] child_rsp_vector = {
        dut.pack_rsp_valid, dut.kd_rsp_valid, dut.fma_rsp_valid, dut.z64_rsp_valid
    };
    wire [3:0] child_req_handshake = {
        dut.pack_req_valid && dut.pack_req_ready,
        dut.kd_req_valid && dut.kd_req_ready,
        dut.fma_req_valid && dut.fma_req_ready,
        dut.z64_req_valid && dut.z64_req_ready
    };
    wire [3:0] child_rsp_handshake = {
        dut.pack_rsp_valid && dut.pack_rsp_ready,
        dut.kd_rsp_valid && dut.kd_rsp_ready,
        dut.fma_rsp_valid && dut.fma_rsp_ready,
        dut.z64_rsp_valid && dut.z64_rsp_ready
    };

    always @(posedge clk_i) begin
        if (rst_i) begin
            outstanding_owner_q <= 4'b0;
        end else if (dut.child_rst) begin
            // abort/HOLD synchronous reset 是 owner cancellation，不伪装成 response completion。
            outstanding_owner_q <= 4'b0;
        end else begin
            if (more_than_one4(child_req_vector) || more_than_one4(child_rsp_vector)) begin
                $fatal(1, "LOG child outstanding/request cardinality exceeded one");
            end
            if (more_than_one4(child_req_handshake) || more_than_one4(child_rsp_handshake)) begin
                $fatal(1, "LOG child handshake cardinality exceeded one");
            end
            if ((child_req_handshake != 4'b0) && (child_rsp_handshake != 4'b0)) begin
                $fatal(1, "LOG child request and response handshakes overlapped");
            end
            if (child_rsp_handshake != 4'b0) begin
                if (outstanding_owner_q !== child_rsp_handshake) begin
                    $fatal(1, "LOG child response owner mismatch owner=%b rsp=%b",
                           outstanding_owner_q, child_rsp_handshake);
                end
                outstanding_owner_q <= 4'b0;
            end
            if (child_req_handshake != 4'b0) begin
                if (outstanding_owner_q != 4'b0) begin
                    $fatal(1, "LOG second child request while owner outstanding=%b req=%b",
                           outstanding_owner_q, child_req_handshake);
                end
                outstanding_owner_q <= child_req_handshake;
            end
        end
    end

    always @(negedge clk_i) begin
        if (!rst_i && (dut.state_q == 5'd25)) begin
            if (dut.child_rst !== 1'b1 || child_rsp_vector !== 4'b0 ||
                outstanding_owner_q !== 4'b0) begin
                $fatal(1, "LOG HOLD child quarantine failed rst=%b rsp=%b owner=%b",
                       dut.child_rst, child_rsp_vector, outstanding_owner_q);
            end
        end
    end

    function automatic logic [63:0] log_invc_tb(input logic [3:0] index_raw);
        begin
            case (index_raw)
                4'd0:  log_invc_tb = 64'h3ff661ec79f8f3be;
                4'd1:  log_invc_tb = 64'h3ff571ed4aaf883d;
                4'd2:  log_invc_tb = 64'h3ff49539f0f010b0;
                4'd3:  log_invc_tb = 64'h3ff3c995b0b80385;
                4'd4:  log_invc_tb = 64'h3ff30d190c8864a5;
                4'd5:  log_invc_tb = 64'h3ff25e227b0b8ea0;
                4'd6:  log_invc_tb = 64'h3ff1bb4a4a1a343f;
                4'd7:  log_invc_tb = 64'h3ff12358f08ae5ba;
                4'd8:  log_invc_tb = 64'h3ff0953f419900a7;
                4'd9:  log_invc_tb = 64'h3ff0000000000000;
                4'd10: log_invc_tb = 64'h3fee608cfd9a47ac;
                4'd11: log_invc_tb = 64'h3feca4b31f026aa0;
                4'd12: log_invc_tb = 64'h3feb2036576afce6;
                4'd13: log_invc_tb = 64'h3fe9c2d163a1aa2d;
                4'd14: log_invc_tb = 64'h3fe886e6037841ed;
                4'd15: log_invc_tb = 64'h3fe767dcf5534862;
                default: log_invc_tb = 64'hxxxxxxxxxxxxxxxx;
            endcase
        end
    endfunction

    function automatic logic [63:0] log_logc_tb(input logic [3:0] index_raw);
        begin
            case (index_raw)
                4'd0:  log_logc_tb = 64'hbfd57bf7808caade;
                4'd1:  log_logc_tb = 64'hbfd2bef0a7c06ddb;
                4'd2:  log_logc_tb = 64'hbfd01eae7f513a67;
                4'd3:  log_logc_tb = 64'hbfcb31d8a68224e9;
                4'd4:  log_logc_tb = 64'hbfc6574f0ac07758;
                4'd5:  log_logc_tb = 64'hbfc1aa2bc79c8100;
                4'd6:  log_logc_tb = 64'hbfba4e76ce8c0e5e;
                4'd7:  log_logc_tb = 64'hbfb1973c5a611ccc;
                4'd8:  log_logc_tb = 64'hbfa252f438e10c1e;
                4'd9:  log_logc_tb = 64'h0000000000000000;
                4'd10: log_logc_tb = 64'h3faaa5aa5df25984;
                4'd11: log_logc_tb = 64'h3fbc5e53aa362eb4;
                4'd12: log_logc_tb = 64'h3fc526e57720db08;
                4'd13: log_logc_tb = 64'h3fcbc2860d224770;
                4'd14: log_logc_tb = 64'h3fd1058bc8a07ee1;
                4'd15: log_logc_tb = 64'h3fd4043057b6ee09;
                default: log_logc_tb = 64'hxxxxxxxxxxxxxxxx;
            endcase
        end
    endfunction

    function automatic logic [31:0] leading_ix_tb(input integer leading_position);
        logic [31:0] scaled_raw;
        begin
            scaled_raw = (leading_position + 1) << 23;
            leading_ix_tb = scaled_raw - 32'h0b800000;
        end
    endfunction

    function automatic logic [31:0] expected_active_cycles(
        input logic [31:0] request_raw,
        input logic [3:0]  expected_code
    );
        begin
            if (expected_code == 4'd1) begin
                expected_active_cycles = 32'd3;
            end else if ((request_raw == 32'h3f800000) ||
                         (request_raw[30:0] == 31'b0) ||
                         (request_raw == 32'h7f800000)) begin
                expected_active_cycles = 32'd2;
            end else begin
                // 固定 single-outstanding DAG：launch 到 PACK terminal 共 24 拍。
                expected_active_cycles = 32'd24;
            end
        end
    endfunction

    task automatic send_case(
        input logic [31:0] request_raw,
        input logic [31:0] expected_raw,
        input logic [4:0]  expected_flags,
        input logic        expected_error,
        input logic [3:0]  expected_code,
        input integer      hold_cycles,
        input logic        pulse_busy,
        input logic        check_table,
        input logic [3:0]  expected_index,
        input logic [31:0] expected_tmp,
        input logic        check_ix,
        input logic [31:0] expected_ix
    );
        logic [31:0] held_result;
        logic [4:0]  held_flags;
        logic        held_error;
        logic [3:0]  held_code;
        logic [31:0] held_cycles;
        integer      wait_cycles;
        integer      hold_index;
        begin
            @(negedge clk_i);
            if (req_ready_o !== 1'b1 || rsp_valid_o !== 1'b0) begin
                $fatal(1, "LOG not IDLE before input=%h", request_raw);
            end
            operand_i   = request_raw;
            req_valid_i = 1'b1;
            rsp_ready_i = 1'b0;
            @(posedge clk_i);
            #1;
            req_valid_i = 1'b0;
            if (req_ready_o !== 1'b0 || dut.flags_accum_q !== 5'b0) begin
                $fatal(1, "LOG launch did not enter busy state with cleared flags input=%h", request_raw);
            end

            if (pulse_busy) begin
                @(negedge clk_i);
                operand_i   = 32'hbf800000;
                req_valid_i = 1'b1;
                @(posedge clk_i);
                #1;
                if (req_ready_o !== 1'b0) begin
                    $fatal(1, "LOG busy request unexpectedly accepted");
                end
                @(negedge clk_i);
                req_valid_i = 1'b0;
                operand_i   = request_raw;
            end

            wait_cycles = 0;
            while ((rsp_valid_o !== 1'b1) && (wait_cycles < 160)) begin
                @(posedge clk_i);
                #1;
                wait_cycles = wait_cycles + 1;
                if ((rsp_valid_o !== 1'b1) && (req_ready_o !== 1'b0)) begin
                    $fatal(1, "LOG exposed request credit while command active input=%h", request_raw);
                end
            end
            if (rsp_valid_o !== 1'b1) begin
                $fatal(1, "LOG response timeout in TB input=%h", request_raw);
            end
            if (result_o !== expected_raw || flags_o !== expected_flags ||
                error_o !== expected_error || error_code_o !== expected_code) begin
                $fatal(1,
                    "LOG mismatch input=%h got=%h/%h/%b/code%0d expected=%h/%h/%b/code%0d",
                    request_raw, result_o, flags_o, error_o, error_code_o,
                    expected_raw, expected_flags, expected_error, expected_code);
            end
            if (active_cycles_o !== expected_active_cycles(request_raw, expected_code)) begin
                $fatal(1, "LOG launch-inclusive cycle mismatch input=%h got=%0d expected=%0d",
                       request_raw, active_cycles_o,
                       expected_active_cycles(request_raw, expected_code));
            end
            if (expected_error && ((result_o != 32'b0) || (flags_o != 5'b0))) begin
                $fatal(1, "LOG error response leaked partial numeric payload input=%h", request_raw);
            end
            if (check_table) begin
                if (dut.table_index_q !== expected_index || dut.tmp_q !== expected_tmp) begin
                    $fatal(1, "LOG range-reduce trace mismatch input=%h idx=%0d tmp=%h",
                           request_raw, dut.table_index_q, dut.tmp_q);
                end
                if (dut.log_invc_raw !== log_invc_tb(expected_index) ||
                    dut.log_logc_raw !== log_logc_tb(expected_index)) begin
                    $fatal(1, "LOG ROM pair mismatch input=%h index=%0d", request_raw, expected_index);
                end
            end
            if (check_ix && (dut.ix_q !== expected_ix)) begin
                $fatal(1, "LOG subnormal normalize mismatch input=%h got ix=%h expected=%h",
                       request_raw, dut.ix_q, expected_ix);
            end

            held_result = result_o;
            held_flags  = flags_o;
            held_error  = error_o;
            held_code   = error_code_o;
            held_cycles = active_cycles_o;
            for (hold_index = 0; hold_index < hold_cycles; hold_index = hold_index + 1) begin
                // testbench-only loop施加固定反压，验证完整原子response与active cycle稳定。
                @(posedge clk_i);
                #1;
                if (rsp_valid_o !== 1'b1 || req_ready_o !== 1'b0 ||
                    result_o !== held_result || flags_o !== held_flags ||
                    error_o !== held_error || error_code_o !== held_code ||
                    active_cycles_o !== held_cycles) begin
                    $fatal(1, "LOG held response changed at hold cycle %0d", hold_index);
                end
            end

            @(negedge clk_i);
            rsp_ready_i = 1'b1;
            @(posedge clk_i);
            #1;
            if (rsp_valid_o !== 1'b0) begin
                $fatal(1, "LOG response did not retire exactly once input=%h", request_raw);
            end
            @(negedge clk_i);
            rsp_ready_i = 1'b0;
            operand_i   = 32'b0;
        end
    endtask

    task automatic check_inflight_reset;
        begin
            @(negedge clk_i);
            operand_i   = 32'h40000000;
            req_valid_i = 1'b1;
            @(posedge clk_i);
            #1;
            req_valid_i = 1'b0;
            repeat (4) @(posedge clk_i);
            @(negedge clk_i);
            rst_i = 1'b1;
            #1;
            if (req_ready_o !== 1'b0 || rsp_valid_o !== 1'b0) begin
                $fatal(1, "LOG interface active during in-flight reset");
            end
            @(posedge clk_i);
            #1;
            @(negedge clk_i);
            rst_i = 1'b0;
            operand_i = 32'b0;
            #1;
            if (req_ready_o !== 1'b1 || rsp_valid_o !== 1'b0) begin
                $fatal(1, "LOG failed clean recovery after in-flight reset");
            end
            repeat (3) begin
                @(posedge clk_i);
                #1;
                if (rsp_valid_o !== 1'b0) begin
                    $fatal(1, "LOG stale completion appeared after in-flight reset");
                end
            end
        end
    endtask

    task automatic check_resident_reset;
        integer wait_cycles;
        begin
            @(negedge clk_i);
            operand_i   = 32'h3f330000;
            req_valid_i = 1'b1;
            @(posedge clk_i);
            #1;
            req_valid_i = 1'b0;
            wait_cycles = 0;
            while ((rsp_valid_o !== 1'b1) && (wait_cycles < 160)) begin
                @(posedge clk_i);
                #1;
                wait_cycles = wait_cycles + 1;
            end
            if (rsp_valid_o !== 1'b1) begin
                $fatal(1, "LOG resident reset probe never reached response");
            end
            @(negedge clk_i);
            rst_i = 1'b1;
            #1;
            if (rsp_valid_o !== 1'b0 || req_ready_o !== 1'b0) begin
                $fatal(1, "LOG resident response remained qualified during reset");
            end
            @(posedge clk_i);
            #1;
            if (result_o !== 32'b0 || flags_o !== 5'b0 || error_o !== 1'b0 ||
                error_code_o !== 4'b0 || active_cycles_o !== 32'b0) begin
                $fatal(1, "LOG reset failed to clear resident payload");
            end
            @(negedge clk_i);
            rst_i = 1'b0;
            operand_i = 32'b0;
            #1;
            if (req_ready_o !== 1'b1 || rsp_valid_o !== 1'b0) begin
                $fatal(1, "LOG resident reset did not return to IDLE");
            end
        end
    endtask

    task automatic check_timeout_instance;
        logic [31:0] held_cycles;
        begin
            @(negedge clk_i);
            timeout_rst_i       = 1'b0;
            timeout_operand_i   = 32'h40000000;
            timeout_req_valid_i = 1'b1;
            #1;
            if (timeout_req_ready_o !== 1'b1) begin
                $fatal(1, "LOG timeout instance was not IDLE before launch");
            end
            @(posedge clk_i);
            #1;
            timeout_req_valid_i = 1'b0;

            @(posedge clk_i); #1; // CLASSIFY -> NORMALIZE
            if (timeout_dut.state_q !== 5'd2) begin
                $fatal(1, "LOG timeout collision did not reach NORMALIZE");
            end
            @(posedge clk_i); #1; // NORMALIZE -> REDUCE
            if (timeout_dut.state_q !== 5'd3) begin
                $fatal(1, "LOG timeout collision did not reach REDUCE");
            end
            @(posedge clk_i); #1; // REDUCE -> Z64_REQ
            if (timeout_dut.state_q !== 5'd4) begin
                $fatal(1, "LOG timeout collision did not reach Z64_REQ");
            end
            @(posedge clk_i); #1; // accepted Z64 child response + watchdog=5
            if (timeout_dut.state_q !== 5'd5 ||
                timeout_dut.z64_rsp_valid !== 1'b1 ||
                timeout_dut.z64_rsp_ready !== 1'b1 ||
                timeout_dut.command_timeout_now !== 1'b1) begin
                $fatal(1, "LOG timeout/accepted-child-response collision was not constructed");
            end
            @(negedge clk_i);
            if (timeout_dut.z64_rsp_valid !== 1'b1 ||
                timeout_dut.command_timeout_now !== 1'b1) begin
                $fatal(1, "LOG timeout collision disappeared before arbitration edge");
            end

            @(posedge clk_i);
            #1;
            if (timeout_dut.state_q !== 5'd24 || timeout_rsp_valid_o !== 1'b0 ||
                timeout_dut.child_rst !== 1'b1 || timeout_dut.z64_rsp_valid !== 1'b0) begin
                $fatal(1, "LOG timeout collision bypassed full abort reset");
            end

            @(posedge clk_i);
            #1;
            if (timeout_rsp_valid_o !== 1'b1 || timeout_result_o !== 32'b0 ||
                timeout_flags_o !== 5'b0 || timeout_error_o !== 1'b1 ||
                timeout_error_code_o !== 4'd3 ||
                timeout_active_cycles_o !== 32'd7 ||
                timeout_dut.state_q !== 5'd25 || timeout_dut.child_rst !== 1'b1) begin
                $fatal(1, "LOG timeout instance did not fail closed with code3");
            end
            held_cycles = timeout_active_cycles_o;
            repeat (3) begin
                @(posedge clk_i);
                #1;
                if (timeout_active_cycles_o !== held_cycles || timeout_rsp_valid_o !== 1'b1) begin
                    $fatal(1, "LOG timeout response cycle/payload changed under hold");
                end
            end
            @(negedge clk_i);
            timeout_rsp_ready_i = 1'b1;
            @(posedge clk_i);
            #1;
            if (timeout_rsp_valid_o !== 1'b0) begin
                $fatal(1, "LOG timeout response did not retire");
            end
            @(negedge clk_i);
            timeout_rsp_ready_i = 1'b0;

            // 无外部 reset 的恢复：+1 special 在两拍内完成。
            timeout_operand_i   = 32'h3f800000;
            timeout_req_valid_i = 1'b1;
            if (timeout_req_ready_o !== 1'b1) begin
                $fatal(1, "LOG timeout instance did not recover request credit");
            end
            @(posedge clk_i);
            #1;
            timeout_req_valid_i = 1'b0;
            @(posedge clk_i);
            #1;
            if (timeout_rsp_valid_o !== 1'b1 || timeout_result_o !== 32'h00000000 ||
                timeout_flags_o !== 5'b0 || timeout_error_o !== 1'b0 ||
                timeout_error_code_o !== 4'd0 || timeout_active_cycles_o !== 32'd2) begin
                $fatal(1, "LOG timeout abort did not recover without external reset");
            end
            @(negedge clk_i);
            timeout_rsp_ready_i = 1'b1;
            @(posedge clk_i);
            #1;
            if (timeout_rsp_valid_o !== 1'b0) begin
                $fatal(1, "LOG timeout recovery terminal did not retire once");
            end
            @(negedge clk_i);
            timeout_rsp_ready_i = 1'b0;
            timeout_rst_i       = 1'b1;
            $display("[NPU-AOR-LOG32][TIMEOUT] collision=z64_rsp+timeout code=3 active_cycles=7 abort=1 hold_quarantine=1 recovery=1");
        end
    endtask

    task automatic retire_injected_error(
        input logic [3:0]  expected_code,
        input logic [31:0] expected_cycles
    );
        logic [31:0] held_cycles;
        integer hold_index;
        begin
            if (dut.state_q !== 5'd24 || rsp_valid_o !== 1'b0 ||
                dut.child_rst !== 1'b1) begin
                $fatal(1, "LOG injected fault did not enter ABORT_RESET code=%0d", expected_code);
            end
            @(posedge clk_i);
            #1;
            if (rsp_valid_o !== 1'b1 || result_o !== 32'b0 || flags_o !== 5'b0 ||
                error_o !== 1'b1 || error_code_o !== expected_code ||
                active_cycles_o !== expected_cycles || dut.state_q !== 5'd25 ||
                dut.child_rst !== 1'b1 || child_rsp_vector !== 4'b0) begin
                $fatal(1, "LOG injected fault terminal mismatch code=%0d", expected_code);
            end
            held_cycles = active_cycles_o;
            for (hold_index = 0; hold_index < 2; hold_index = hold_index + 1) begin
                @(posedge clk_i);
                #1;
                if (rsp_valid_o !== 1'b1 || result_o !== 32'b0 || flags_o !== 5'b0 ||
                    error_o !== 1'b1 || error_code_o !== expected_code ||
                    active_cycles_o !== held_cycles || dut.child_rst !== 1'b1 ||
                    child_rsp_vector !== 4'b0) begin
                    $fatal(1, "LOG injected fault terminal/quarantine changed code=%0d", expected_code);
                end
            end
            @(negedge clk_i);
            rsp_ready_i = 1'b1;
            @(posedge clk_i);
            #1;
            if (rsp_valid_o !== 1'b0 || req_ready_o !== 1'b1) begin
                $fatal(1, "LOG injected fault terminal did not retire once code=%0d", expected_code);
            end
            @(negedge clk_i);
            rsp_ready_i = 1'b0;
            repeat (3) begin
                @(posedge clk_i);
                #1;
                if (rsp_valid_o !== 1'b0 || req_ready_o !== 1'b1 ||
                    child_rsp_vector !== 4'b0 || outstanding_owner_q !== 4'b0) begin
                    $fatal(1, "LOG stale/duplicate terminal after injected code=%0d", expected_code);
                end
            end
        end
    endtask

    task automatic check_code2_injection;
        integer wait_cycles;
        begin
            @(negedge clk_i);
            operand_i   = 32'h40000000;
            req_valid_i = 1'b1;
            rsp_ready_i = 1'b0;
            if (req_ready_o !== 1'b1) begin
                $fatal(1, "LOG code2 injection did not start from IDLE");
            end
            @(posedge clk_i);
            #1;
            req_valid_i = 1'b0;

            wait_cycles = 0;
            while (((dut.state_q !== 5'd7) || (dut.fma_rsp_valid !== 1'b1)) &&
                   (wait_cycles < 24)) begin
                @(negedge clk_i);
                wait_cycles = wait_cycles + 1;
            end
            if (dut.state_q !== 5'd7 || dut.fma_rsp_valid !== 1'b1 ||
                dut.fma_rsp_ready !== 1'b1 || outstanding_owner_q !== 4'b0010) begin
                $fatal(1, "LOG code2 injection did not reach owned R response");
            end

            // 强制 child resident payload register，确保 parent consumer 观测 profile fault。
            force dut.u_fma.flags_reg = 5'b10000;
            #1;
            if (dut.child_profile_fault_now !== 1'b1) begin
                $fatal(1, "LOG code2 injected child flag did not reach parent fault detector");
            end
            @(posedge clk_i);
            #1;
            release dut.u_fma.flags_reg;
            if (dut.state_q !== 5'd24 || rsp_valid_o !== 1'b0) begin
                $fatal(1, "LOG code2 child fault lost fatal priority");
            end
            retire_injected_error(4'd2, 32'd9);

            send_case(32'h3f800000, 32'h00000000, 5'h00, 1'b0, 4'd0,
                      0, 1'b0, 1'b0, 4'd0, 32'd0, 1'b0, 32'd0);
            $display("[NPU-AOR-LOG32][FAULT] code=2 active_cycles=9 payload_zero=1 terminal_once=1 hold_quarantine=1 owner_cardinality=0or1 recovery=1");
        end
    endtask

    task automatic check_code4_injection;
        begin
            @(negedge clk_i);
            operand_i   = 32'h40000000;
            req_valid_i = 1'b1;
            rsp_ready_i = 1'b0;
            if (req_ready_o !== 1'b1) begin
                $fatal(1, "LOG code4 injection did not start from IDLE");
            end
            @(posedge clk_i);
            #1;
            req_valid_i = 1'b0;
            if (dut.state_q !== 5'd1 || outstanding_owner_q !== 4'b0) begin
                $fatal(1, "LOG code4 injection launch did not reach owner-free CLASSIFY");
            end
            @(negedge clk_i);

            force dut.fma_rsp_valid = 1'b1;
            @(posedge clk_i);
            #1;
            release dut.fma_rsp_valid;
            if (dut.state_q !== 5'd24 || rsp_valid_o !== 1'b0) begin
                $fatal(1, "LOG code4 ghost response did not enter ABORT_RESET");
            end
            retire_injected_error(4'd4, 32'd3);

            send_case(32'h3f800000, 32'h00000000, 5'h00, 1'b0, 4'd0,
                      0, 1'b0, 1'b0, 4'd0, 32'd0, 1'b0, 32'd0);
            $display("[NPU-AOR-LOG32][FAULT] code=4 active_cycles=3 payload_zero=1 terminal_once=1 hold_quarantine=1 owner_cardinality=0or1 recovery=1");
        end
    endtask

    initial begin
        rst_i               = 1'b1;
        req_valid_i         = 1'b0;
        operand_i           = 32'b0;
        rsp_ready_i         = 1'b0;
        timeout_rst_i       = 1'b1;
        timeout_req_valid_i = 1'b0;
        timeout_operand_i   = 32'b0;
        timeout_rsp_ready_i = 1'b0;
        outstanding_owner_q = 4'b0;

        table_input[0]  = 32'h3f330000; table_result[0]  = 32'hbeb73077;
        table_input[1]  = 32'h3f3b0000; table_result[1]  = 32'hbea0cda1;
        table_input[2]  = 32'h3f430000; table_result[2]  = 32'hbe8b5ae6;
        table_input[3]  = 32'h3f4b0000; table_result[3]  = 32'hbe6d89ee;
        table_input[4]  = 32'h3f530000; table_result[4]  = 32'hbe45f57f;
        table_input[5]  = 32'h3f5b0000; table_result[5]  = 32'hbe1fda2d;
        table_input[6]  = 32'h3f630000; table_result[6]  = 32'hbdf639cc;
        table_input[7]  = 32'h3f6b0000; table_result[7]  = 32'hbdaf4ad2;
        table_input[8]  = 32'h3f730000; table_result[8]  = 32'hbd557797;
        table_input[9]  = 32'h3f7b0000; table_result[9]  = 32'hbca19549;
        table_input[10] = 32'h3f830000; table_result[10] = 32'h3cbdc8d9;
        table_input[11] = 32'h3f8b0000; table_result[11] = 32'h3da8d83a;
        table_input[12] = 32'h3f930000; table_result[12] = 32'h3e0db957;
        table_input[13] = 32'h3f9b0000; table_result[13] = 32'h3e43fd03;
        table_input[14] = 32'h3fa30000; table_result[14] = 32'h3e77856e;
        table_input[15] = 32'h3fab0000; table_result[15] = 32'h3e944ad1;

        leading_input[0]  = 32'h00000001; leading_result[0]  = 32'hc2ce8ed0;
        leading_input[1]  = 32'h00000002; leading_result[1]  = 32'hc2cd2bec;
        leading_input[2]  = 32'h00000004; leading_result[2]  = 32'hc2cbc908;
        leading_input[3]  = 32'h00000008; leading_result[3]  = 32'hc2ca6623;
        leading_input[4]  = 32'h00000010; leading_result[4]  = 32'hc2c9033f;
        leading_input[5]  = 32'h00000020; leading_result[5]  = 32'hc2c7a05b;
        leading_input[6]  = 32'h00000040; leading_result[6]  = 32'hc2c63d77;
        leading_input[7]  = 32'h00000080; leading_result[7]  = 32'hc2c4da93;
        leading_input[8]  = 32'h00000100; leading_result[8]  = 32'hc2c377ae;
        leading_input[9]  = 32'h00000200; leading_result[9]  = 32'hc2c214ca;
        leading_input[10] = 32'h00000400; leading_result[10] = 32'hc2c0b1e6;
        leading_input[11] = 32'h00000800; leading_result[11] = 32'hc2bf4f02;
        leading_input[12] = 32'h00001000; leading_result[12] = 32'hc2bdec1e;
        leading_input[13] = 32'h00002000; leading_result[13] = 32'hc2bc8939;
        leading_input[14] = 32'h00004000; leading_result[14] = 32'hc2bb2655;
        leading_input[15] = 32'h00008000; leading_result[15] = 32'hc2b9c371;
        leading_input[16] = 32'h00010000; leading_result[16] = 32'hc2b8608d;
        leading_input[17] = 32'h00020000; leading_result[17] = 32'hc2b6fda9;
        leading_input[18] = 32'h00040000; leading_result[18] = 32'hc2b59ac5;
        leading_input[19] = 32'h00080000; leading_result[19] = 32'hc2b437e0;
        leading_input[20] = 32'h00100000; leading_result[20] = 32'hc2b2d4fc;
        leading_input[21] = 32'h00200000; leading_result[21] = 32'hc2b17218;
        leading_input[22] = 32'h00400000; leading_result[22] = 32'hc2b00f34;

        repeat (3) @(posedge clk_i);
        @(negedge clk_i);
        rst_i = 1'b0;
        $display("[NPU-AOR-LOG32][ORACLE] profile=AOR_AARCH64_FMA_RNE_V1 vectors_sha256=e635c1ce963bb814f746dc828d715bd6cc39841f11ed8551aa7b15f128fcaa41");

        // Special/domain classifier与1.0邻点。
        send_case(32'h3f800000, 32'h00000000, 5'h00, 1'b0, 4'd0, 0, 1'b0, 1'b0, 4'd0, 32'd0, 1'b0, 32'd0);
        send_case(32'h00000000, 32'hff800000, 5'h08, 1'b0, 4'd0, 0, 1'b0, 1'b0, 4'd0, 32'd0, 1'b0, 32'd0);
        send_case(32'h80000000, 32'hff800000, 5'h08, 1'b0, 4'd0, 0, 1'b0, 1'b0, 4'd0, 32'd0, 1'b0, 32'd0);
        send_case(32'h7f800000, 32'h7f800000, 5'h00, 1'b0, 4'd0, 0, 1'b0, 1'b0, 4'd0, 32'd0, 1'b0, 32'd0);
        send_case(32'hbf800000, 32'h00000000, 5'h00, 1'b1, 4'd1, 0, 1'b0, 1'b0, 4'd0, 32'd0, 1'b0, 32'd0);
        send_case(32'hff800000, 32'h00000000, 5'h00, 1'b1, 4'd1, 0, 1'b0, 1'b0, 4'd0, 32'd0, 1'b0, 32'd0);
        send_case(32'h7fc00001, 32'h00000000, 5'h00, 1'b1, 4'd1, 0, 1'b0, 1'b0, 4'd0, 32'd0, 1'b0, 32'd0);
        send_case(32'h7f800001, 32'h00000000, 5'h00, 1'b1, 4'd1, 0, 1'b0, 1'b0, 4'd0, 32'd0, 1'b0, 32'd0);
        send_case(32'h3f7fffff, 32'hb3800000, 5'h01, 1'b0, 4'd0, 0, 1'b0, 1'b0, 4'd0, 32'd0, 1'b0, 32'd0);
        send_case(32'h3f800001, 32'h33ffffff, 5'h01, 1'b0, 4'd0, 0, 1'b0, 1'b0, 4'd0, 32'd0, 1'b0, 32'd0);

        // 16个table index全部检查range-reduce tmp/index及两项ROM raw。
        for (idx = 0; idx < 16; idx = idx + 1) begin
            // testbench-only循环遍历manifest 16项ROM，不生成production硬件。
            send_case(table_input[idx], table_result[idx], 5'h01, 1'b0, 4'd0,
                      (idx == 1) ? 5 : 0, (idx == 2), 1'b1, idx[3:0],
                      idx[31:0] << 19, 1'b0, 32'd0);
        end

        // 23种positive-subnormal leading-one位置及精确normalize ix。
        for (idx = 0; idx < 23; idx = idx + 1) begin
            // testbench-only循环覆盖23-bit priority encoder每个可能winner。
            send_case(leading_input[idx], leading_result[idx], 5'h01, 1'b0, 4'd0,
                      0, 1'b0, 1'b0, 4'd0, 32'd0,
                      1'b1, leading_ix_tb(idx));
        end

        // 六个审计seed中的非leading-power补项；其余四项已由上述leading/min/max覆盖。
        send_case(32'h00000003, 32'hc2cc5c53, 5'h01, 1'b0, 4'd0, 0, 1'b0,
                  1'b0, 4'd0, 32'd0, 1'b1, 32'hf5c00000);
        send_case(32'h003fffff, 32'hc2b00f34, 5'h01, 1'b0, 4'd0, 0, 1'b0,
                  1'b0, 4'd0, 32'd0, 1'b1, 32'hfffffffc);
        send_case(32'h007fffff, 32'hc2aeac50, 5'h01, 1'b0, 4'd0, 0, 1'b0,
                  1'b0, 4'd0, 32'd0, 1'b1, 32'h007ffffe);

        // minimum normal / maximum finite frozen oracle。
        send_case(32'h00800000, 32'hc2aeac50, 5'h01, 1'b0, 4'd0, 0, 1'b0,
                  1'b0, 4'd0, 32'd0, 1'b0, 32'd0);
        send_case(32'h7f7fffff, 32'h42b17218, 5'h01, 1'b0, 4'd0, 0, 1'b0,
                  1'b0, 4'd0, 32'd0, 1'b0, 32'd0);

        // Mutation M23/M24/M26 strict中间raw witness。
        send_case(32'h3f32f800, 32'hbeb7475a, 5'h01, 1'b0, 4'd0, 0, 1'b0,
                  1'b0, 4'd0, 32'd0, 1'b0, 32'd0);
        if (dut.r_q !== 64'h3f97391028644091) $fatal(1, "LOG M23 strict r witness mismatch");
        send_case(32'h00000005, 32'hc2cb56c8, 5'h01, 1'b0, 4'd0, 0, 1'b0,
                  1'b0, 4'd0, 32'd0, 1'b0, 32'd0);
        if (dut.y0_q !== 64'hc0596b3fadcccd65) $fatal(1, "LOG M24 strict y0 witness mismatch");
        send_case(32'h3f32f812, 32'hbeb74726, 5'h01, 1'b0, 4'd0, 0, 1'b0,
                  1'b0, 4'd0, 32'd0, 1'b0, 32'd0);
        if (dut.y_q !== 64'hbfd6e8e4c5f86c19) $fatal(1, "LOG M26 strict y witness mismatch");
        $display("[NPU-AOR-LOG32][CYCLES] special=2 code1=3 normal=24 launch_inclusive=1 all_cases_checked=1");

        check_inflight_reset();
        check_resident_reset();
        check_timeout_instance();
        check_code2_injection();
        check_code4_injection();

        // 前一事务NX/error后+1 special必须清flags/code。
        send_case(32'h3f800000, 32'h00000000, 5'h00, 1'b0, 4'd0, 0, 1'b0,
                  1'b0, 4'd0, 32'd0, 1'b0, 32'd0);

        $display("[NPU-AOR-LOG32][PASS]");
        $finish;
    end

endmodule
