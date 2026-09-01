`timescale 1ns/1ps

module tb_aor_exp32;

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

    logic [31:0] table_input [0:31];
    logic [31:0] table_result [0:31];
    integer      idx;
    logic [4:0]  outstanding_owner_q;

    TensorNpuAorExp32 dut (
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

    TensorNpuAorExp32 #(
        // launch=1, CLASSIFY=2, X64 request accepted=3；WAIT response 与 timeout 同拍。
        .COMMAND_TIMEOUT_CYCLES(3)
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

    function automatic logic more_than_one5(input logic [4:0] value);
        logic [4:0] value_minus_one;
        begin
            value_minus_one = value - 5'd1;
            more_than_one5 = (value != 5'b0) && (|(value & value_minus_one));
        end
    endfunction

    wire [4:0] child_req_vector = {
        dut.pack_req_valid, dut.kd_req_valid, dut.k_req_valid,
        dut.fma_req_valid, dut.x64_req_valid
    };
    wire [4:0] child_rsp_vector = {
        dut.pack_rsp_valid, dut.kd_rsp_valid, dut.k_rsp_valid,
        dut.fma_rsp_valid, dut.x64_rsp_valid
    };
    wire [4:0] child_req_handshake = {
        dut.pack_req_valid && dut.pack_req_ready,
        dut.kd_req_valid && dut.kd_req_ready,
        dut.k_req_valid && dut.k_req_ready,
        dut.fma_req_valid && dut.fma_req_ready,
        dut.x64_req_valid && dut.x64_req_ready
    };
    wire [4:0] child_rsp_handshake = {
        dut.pack_rsp_valid && dut.pack_rsp_ready,
        dut.kd_rsp_valid && dut.kd_rsp_ready,
        dut.k_rsp_valid && dut.k_rsp_ready,
        dut.fma_rsp_valid && dut.fma_rsp_ready,
        dut.x64_rsp_valid && dut.x64_rsp_ready
    };

    always @(posedge clk_i) begin
        if (rst_i) begin
            outstanding_owner_q <= 5'b0;
        end else if (dut.child_rst) begin
            // abort/HOLD synchronous reset 是 owner cancellation，不伪装成 response completion。
            outstanding_owner_q <= 5'b0;
        end else begin
            if (more_than_one5(child_req_vector) || more_than_one5(child_rsp_vector)) begin
                $fatal(1, "EXP child outstanding/request cardinality exceeded one");
            end
            if (more_than_one5(child_req_handshake) || more_than_one5(child_rsp_handshake)) begin
                $fatal(1, "EXP child handshake cardinality exceeded one");
            end
            if ((child_req_handshake != 5'b0) && (child_rsp_handshake != 5'b0)) begin
                $fatal(1, "EXP child request and response handshakes overlapped");
            end
            if (child_rsp_handshake != 5'b0) begin
                if (outstanding_owner_q !== child_rsp_handshake) begin
                    $fatal(1, "EXP child response owner mismatch owner=%b rsp=%b",
                           outstanding_owner_q, child_rsp_handshake);
                end
                outstanding_owner_q <= 5'b0;
            end
            if (child_req_handshake != 5'b0) begin
                if (outstanding_owner_q != 5'b0) begin
                    $fatal(1, "EXP second child request while owner outstanding=%b req=%b",
                           outstanding_owner_q, child_req_handshake);
                end
                outstanding_owner_q <= child_req_handshake;
            end
        end
    end

    // HOLD 的 negedge 观测避开 NBA race：quarantine 必须使全部 child response 失去资格。
    always @(negedge clk_i) begin
        if (!rst_i && (dut.state_q == 5'd27)) begin
            if (dut.child_rst !== 1'b1 || child_rsp_vector !== 5'b0 ||
                outstanding_owner_q !== 5'b0) begin
                $fatal(1, "EXP HOLD child quarantine failed rst=%b rsp=%b owner=%b",
                       dut.child_rst, child_rsp_vector, outstanding_owner_q);
            end
        end
    end

    // Independent TB copy of the frozen manifest table; case synthesizes only in the test model.
    function automatic logic [63:0] exp_table_raw_tb(input logic [4:0] index_raw);
        begin
            case (index_raw)
                5'd0:  exp_table_raw_tb = 64'h3ff0000000000000;
                5'd1:  exp_table_raw_tb = 64'h3fefd9b0d3158574;
                5'd2:  exp_table_raw_tb = 64'h3fefb5586cf9890f;
                5'd3:  exp_table_raw_tb = 64'h3fef9301d0125b51;
                5'd4:  exp_table_raw_tb = 64'h3fef72b83c7d517b;
                5'd5:  exp_table_raw_tb = 64'h3fef54873168b9aa;
                5'd6:  exp_table_raw_tb = 64'h3fef387a6e756238;
                5'd7:  exp_table_raw_tb = 64'h3fef1e9df51fdee1;
                5'd8:  exp_table_raw_tb = 64'h3fef06fe0a31b715;
                5'd9:  exp_table_raw_tb = 64'h3feef1a7373aa9cb;
                5'd10: exp_table_raw_tb = 64'h3feedea64c123422;
                5'd11: exp_table_raw_tb = 64'h3feece086061892d;
                5'd12: exp_table_raw_tb = 64'h3feebfdad5362a27;
                5'd13: exp_table_raw_tb = 64'h3feeb42b569d4f82;
                5'd14: exp_table_raw_tb = 64'h3feeab07dd485429;
                5'd15: exp_table_raw_tb = 64'h3feea47eb03a5585;
                5'd16: exp_table_raw_tb = 64'h3feea09e667f3bcd;
                5'd17: exp_table_raw_tb = 64'h3fee9f75e8ec5f74;
                5'd18: exp_table_raw_tb = 64'h3feea11473eb0187;
                5'd19: exp_table_raw_tb = 64'h3feea589994cce13;
                5'd20: exp_table_raw_tb = 64'h3feeace5422aa0db;
                5'd21: exp_table_raw_tb = 64'h3feeb737b0cdc5e5;
                5'd22: exp_table_raw_tb = 64'h3feec49182a3f090;
                5'd23: exp_table_raw_tb = 64'h3feed503b23e255d;
                5'd24: exp_table_raw_tb = 64'h3feee89f995ad3ad;
                5'd25: exp_table_raw_tb = 64'h3feeff76f2fb5e47;
                5'd26: exp_table_raw_tb = 64'h3fef199bdd85529c;
                5'd27: exp_table_raw_tb = 64'h3fef3720dcef9069;
                5'd28: exp_table_raw_tb = 64'h3fef5818dcfba487;
                5'd29: exp_table_raw_tb = 64'h3fef7c97337b9b5f;
                5'd30: exp_table_raw_tb = 64'h3fefa4afa2a490da;
                5'd31: exp_table_raw_tb = 64'h3fefd0765b6e4540;
                default: exp_table_raw_tb = 64'hxxxxxxxxxxxxxxxx;
            endcase
        end
    endfunction

    function automatic logic [63:0] expected_scale_raw(
        input logic [31:0] expected_k,
        input logic [4:0] expected_index
    );
        logic [63:0] sign_extended_k;
        begin
            sign_extended_k = {{32{expected_k[31]}}, expected_k};
            expected_scale_raw = exp_table_raw_tb(expected_index) +
                                 (sign_extended_k << 47);
        end
    endfunction

    function automatic logic [31:0] expected_active_cycles(
        input logic [31:0] request_raw,
        input logic [3:0]  expected_code
    );
        begin
            if (expected_code == 4'd1) begin
                // CLASSIFY detects unsupported input, then one full ABORT_RESET cycle.
                expected_active_cycles = 32'd3;
            end else if ((request_raw[30:0] == 31'b0) ||
                         (request_raw[30:23] == 8'hff) ||
                         (!request_raw[31] && (request_raw > 32'h42b17217)) ||
                         (request_raw[31] &&
                          (request_raw[30:0] > 31'h42cff1b4))) begin
                expected_active_cycles = 32'd2;
            end else begin
                // 固定 single-outstanding DAG：launch 到 PACK terminal 共 26 拍。
                expected_active_cycles = 32'd26;
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
        input logic [4:0]  expected_index,
        input logic [31:0] expected_k
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
                $fatal(1, "EXP not IDLE before input=%h", request_raw);
            end
            operand_i   = request_raw;
            req_valid_i = 1'b1;
            rsp_ready_i = 1'b0;
            @(posedge clk_i);
            #1;
            req_valid_i = 1'b0;
            if (req_ready_o !== 1'b0 || dut.flags_accum_q !== 5'b0) begin
                $fatal(1, "EXP launch did not enter busy state with cleared flags input=%h", request_raw);
            end

            if (pulse_busy) begin
                @(negedge clk_i);
                operand_i   = 32'h42b17218;
                req_valid_i = 1'b1;
                @(posedge clk_i);
                #1;
                if (req_ready_o !== 1'b0) begin
                    $fatal(1, "EXP busy request unexpectedly accepted");
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
                    $fatal(1, "EXP exposed request credit while command active input=%h", request_raw);
                end
            end
            if (rsp_valid_o !== 1'b1) begin
                $fatal(1, "EXP response timeout in TB input=%h", request_raw);
            end
            if (result_o !== expected_raw || flags_o !== expected_flags ||
                error_o !== expected_error || error_code_o !== expected_code) begin
                $fatal(1,
                    "EXP mismatch input=%h got=%h/%h/%b/code%0d expected=%h/%h/%b/code%0d",
                    request_raw, result_o, flags_o, error_o, error_code_o,
                    expected_raw, expected_flags, expected_error, expected_code);
            end
            if (active_cycles_o !== expected_active_cycles(request_raw, expected_code)) begin
                $fatal(1, "EXP launch-inclusive cycle mismatch input=%h got=%0d expected=%0d",
                       request_raw, active_cycles_o,
                       expected_active_cycles(request_raw, expected_code));
            end
            if (expected_error && ((result_o != 32'b0) || (flags_o != 5'b0))) begin
                $fatal(1, "EXP error response leaked partial numeric payload input=%h", request_raw);
            end
            if (check_table) begin
                if (dut.table_index_q !== expected_index || dut.k_q !== expected_k) begin
                    $fatal(1, "EXP table/k trace mismatch input=%h got idx=%0d k=%h expected idx=%0d k=%h",
                           request_raw, dut.table_index_q, dut.k_q, expected_index, expected_k);
                end
                if (dut.scale_q !== expected_scale_raw(expected_k, expected_index)) begin
                    $fatal(1, "EXP scale trace mismatch input=%h got=%h expected=%h",
                           request_raw, dut.scale_q,
                           expected_scale_raw(expected_k, expected_index));
                end
                if (dut.k_operand !== dut.z_q) begin
                    $fatal(1, "EXP z-to-k producer ownership violated input=%h", request_raw);
                end
            end

            held_result = result_o;
            held_flags  = flags_o;
            held_error  = error_o;
            held_code   = error_code_o;
            held_cycles = active_cycles_o;
            for (hold_index = 0; hold_index < hold_cycles; hold_index = hold_index + 1) begin
                // testbench-only loop施加固定拍数反压，验证整个原子response逐bit稳定。
                @(posedge clk_i);
                #1;
                if (rsp_valid_o !== 1'b1 || req_ready_o !== 1'b0 ||
                    result_o !== held_result || flags_o !== held_flags ||
                    error_o !== held_error || error_code_o !== held_code ||
                    active_cycles_o !== held_cycles) begin
                    $fatal(1, "EXP held response changed at hold cycle %0d", hold_index);
                end
            end

            @(negedge clk_i);
            rsp_ready_i = 1'b1;
            @(posedge clk_i);
            #1;
            if (rsp_valid_o !== 1'b0) begin
                $fatal(1, "EXP response did not retire exactly once input=%h", request_raw);
            end
            @(negedge clk_i);
            rsp_ready_i = 1'b0;
            operand_i   = 32'b0;
        end
    endtask

    task automatic check_inflight_reset;
        begin
            @(negedge clk_i);
            operand_i   = 32'h3f800000;
            req_valid_i = 1'b1;
            @(posedge clk_i);
            #1;
            req_valid_i = 1'b0;
            repeat (4) @(posedge clk_i);
            @(negedge clk_i);
            rst_i = 1'b1;
            #1;
            if (req_ready_o !== 1'b0 || rsp_valid_o !== 1'b0) begin
                $fatal(1, "EXP interface active during in-flight reset");
            end
            @(posedge clk_i);
            #1;
            @(negedge clk_i);
            rst_i = 1'b0;
            operand_i = 32'b0;
            #1;
            if (req_ready_o !== 1'b1 || rsp_valid_o !== 1'b0) begin
                $fatal(1, "EXP failed clean recovery after in-flight reset");
            end
            repeat (3) begin
                @(posedge clk_i);
                #1;
                if (rsp_valid_o !== 1'b0) begin
                    $fatal(1, "EXP stale completion appeared after in-flight reset");
                end
            end
        end
    endtask

    task automatic check_resident_reset;
        integer wait_cycles;
        begin
            @(negedge clk_i);
            operand_i   = 32'h3f317218;
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
                $fatal(1, "EXP resident reset probe never reached response");
            end
            @(negedge clk_i);
            rst_i = 1'b1;
            #1;
            if (rsp_valid_o !== 1'b0 || req_ready_o !== 1'b0) begin
                $fatal(1, "EXP resident response remained qualified during reset");
            end
            @(posedge clk_i);
            #1;
            if (result_o !== 32'b0 || flags_o !== 5'b0 || error_o !== 1'b0 ||
                error_code_o !== 4'b0 || active_cycles_o !== 32'b0) begin
                $fatal(1, "EXP reset failed to clear resident payload");
            end
            @(negedge clk_i);
            rst_i = 1'b0;
            operand_i = 32'b0;
            #1;
            if (req_ready_o !== 1'b1 || rsp_valid_o !== 1'b0) begin
                $fatal(1, "EXP resident reset did not return to IDLE");
            end
        end
    endtask

    task automatic check_timeout_instance;
        logic [31:0] held_cycles;
        begin
            @(negedge clk_i);
            timeout_rst_i       = 1'b0;
            timeout_operand_i   = 32'h3f800000;
            timeout_req_valid_i = 1'b1;
            #1;
            if (timeout_req_ready_o !== 1'b1) begin
                $fatal(1, "EXP timeout instance was not IDLE before launch");
            end
            @(posedge clk_i);
            #1;
            timeout_req_valid_i = 1'b0;

            // CLASSIFY -> X64_REQ。
            @(posedge clk_i);
            #1;
            if (timeout_dut.state_q !== 5'd2) begin
                $fatal(1, "EXP timeout collision did not reach X64_REQ");
            end

            // X64 request handshake 后 child resident response 已有效；watchdog 同时达到 3。
            @(posedge clk_i);
            #1;
            if (timeout_dut.state_q !== 5'd3 ||
                timeout_dut.x64_rsp_valid !== 1'b1 ||
                timeout_dut.x64_rsp_ready !== 1'b1 ||
                timeout_dut.command_timeout_now !== 1'b1) begin
                $fatal(1, "EXP timeout/accepted-child-response collision was not constructed");
            end
            @(negedge clk_i);
            if (timeout_dut.x64_rsp_valid !== 1'b1 ||
                timeout_dut.command_timeout_now !== 1'b1) begin
                $fatal(1, "EXP timeout collision disappeared before arbitration edge");
            end

            // timeout 必须压过同拍 normal child response，先进入完整 ABORT_RESET。
            @(posedge clk_i);
            #1;
            if (timeout_dut.state_q !== 5'd26 || timeout_rsp_valid_o !== 1'b0 ||
                timeout_dut.child_rst !== 1'b1 || timeout_dut.x64_rsp_valid !== 1'b0) begin
                $fatal(1, "EXP timeout collision bypassed full abort reset");
            end

            @(posedge clk_i);
            #1;
            if (timeout_rsp_valid_o !== 1'b1 || timeout_result_o !== 32'b0 ||
                timeout_flags_o !== 5'b0 || timeout_error_o !== 1'b1 ||
                timeout_error_code_o !== 4'd3 ||
                timeout_active_cycles_o !== 32'd5 ||
                timeout_dut.state_q !== 5'd27 || timeout_dut.child_rst !== 1'b1) begin
                $fatal(1, "EXP timeout instance did not fail closed with code3");
            end
            held_cycles = timeout_active_cycles_o;
            repeat (3) begin
                @(posedge clk_i);
                #1;
                if (timeout_active_cycles_o !== held_cycles || timeout_rsp_valid_o !== 1'b1) begin
                    $fatal(1, "EXP timeout response cycle/payload changed under hold");
                end
            end
            @(negedge clk_i);
            timeout_rsp_ready_i = 1'b1;
            @(posedge clk_i);
            #1;
            if (timeout_rsp_valid_o !== 1'b0) begin
                $fatal(1, "EXP timeout response did not retire");
            end
            @(negedge clk_i);
            timeout_rsp_ready_i = 1'b0;

            // 无外部 reset 的恢复：quarantine retire 后立即完成一个两拍 zero special。
            timeout_operand_i   = 32'h00000000;
            timeout_req_valid_i = 1'b1;
            if (timeout_req_ready_o !== 1'b1) begin
                $fatal(1, "EXP timeout instance did not recover request credit");
            end
            @(posedge clk_i);
            #1;
            timeout_req_valid_i = 1'b0;
            @(posedge clk_i);
            #1;
            if (timeout_rsp_valid_o !== 1'b1 || timeout_result_o !== 32'h3f800000 ||
                timeout_flags_o !== 5'b0 || timeout_error_o !== 1'b0 ||
                timeout_error_code_o !== 4'd0 || timeout_active_cycles_o !== 32'd2) begin
                $fatal(1, "EXP timeout abort did not recover without external reset");
            end
            @(negedge clk_i);
            timeout_rsp_ready_i = 1'b1;
            @(posedge clk_i);
            #1;
            if (timeout_rsp_valid_o !== 1'b0) begin
                $fatal(1, "EXP timeout recovery terminal did not retire once");
            end
            @(negedge clk_i);
            timeout_rsp_ready_i = 1'b0;
            timeout_rst_i       = 1'b1;
            $display("[NPU-AOR-EXP32][TIMEOUT] collision=x64_rsp+timeout code=3 active_cycles=5 abort=1 hold_quarantine=1 recovery=1");
        end
    endtask

    task automatic retire_injected_error(
        input logic [3:0]  expected_code,
        input logic [31:0] expected_cycles
    );
        logic [31:0] held_cycles;
        integer hold_index;
        begin
            // 调用点必须已完成 fatal arbitration 并处于整拍 ABORT_RESET。
            if (dut.state_q !== 5'd26 || rsp_valid_o !== 1'b0 ||
                dut.child_rst !== 1'b1) begin
                $fatal(1, "EXP injected fault did not enter ABORT_RESET code=%0d", expected_code);
            end
            @(posedge clk_i);
            #1;
            if (rsp_valid_o !== 1'b1 || result_o !== 32'b0 || flags_o !== 5'b0 ||
                error_o !== 1'b1 || error_code_o !== expected_code ||
                active_cycles_o !== expected_cycles || dut.state_q !== 5'd27 ||
                dut.child_rst !== 1'b1 || child_rsp_vector !== 5'b0) begin
                $fatal(1, "EXP injected fault terminal mismatch code=%0d", expected_code);
            end
            held_cycles = active_cycles_o;
            for (hold_index = 0; hold_index < 2; hold_index = hold_index + 1) begin
                @(posedge clk_i);
                #1;
                if (rsp_valid_o !== 1'b1 || result_o !== 32'b0 || flags_o !== 5'b0 ||
                    error_o !== 1'b1 || error_code_o !== expected_code ||
                    active_cycles_o !== held_cycles || dut.child_rst !== 1'b1 ||
                    child_rsp_vector !== 5'b0) begin
                    $fatal(1, "EXP injected fault terminal/quarantine changed code=%0d", expected_code);
                end
            end
            @(negedge clk_i);
            rsp_ready_i = 1'b1;
            @(posedge clk_i);
            #1;
            if (rsp_valid_o !== 1'b0 || req_ready_o !== 1'b1) begin
                $fatal(1, "EXP injected fault terminal did not retire once code=%0d", expected_code);
            end
            @(negedge clk_i);
            rsp_ready_i = 1'b0;
            repeat (3) begin
                @(posedge clk_i);
                #1;
                if (rsp_valid_o !== 1'b0 || req_ready_o !== 1'b1 ||
                    child_rsp_vector !== 5'b0 || outstanding_owner_q !== 5'b0) begin
                    $fatal(1, "EXP stale/duplicate terminal after injected code=%0d", expected_code);
                end
            end
        end
    endtask

    task automatic check_code2_injection;
        integer wait_cycles;
        begin
            @(negedge clk_i);
            operand_i   = 32'h3f800000;
            req_valid_i = 1'b1;
            rsp_ready_i = 1'b0;
            if (req_ready_o !== 1'b1) begin
                $fatal(1, "EXP code2 injection did not start from IDLE");
            end
            @(posedge clk_i);
            #1;
            req_valid_i = 1'b0;

            wait_cycles = 0;
            while (((dut.state_q !== 5'd5) || (dut.fma_rsp_valid !== 1'b1)) &&
                   (wait_cycles < 20)) begin
                @(negedge clk_i);
                wait_cycles = wait_cycles + 1;
            end
            if (dut.state_q !== 5'd5 || dut.fma_rsp_valid !== 1'b1 ||
                dut.fma_rsp_ready !== 1'b1 || outstanding_owner_q !== 5'b00010) begin
                $fatal(1, "EXP code2 injection did not reach owned Z response");
            end

            // compile-success TB fault injection：合法 owner 的 child profile flag 触发 code2。
            // 强制 child resident payload register，避免 simulator 对 output wire 的 alias 优化
            // 绕过父级 consumer；这是对真实 child response payload 的定向 profile fault。
            force dut.u_fma.flags_reg = 5'b10000;
            #1;
            if (dut.child_profile_fault_now !== 1'b1) begin
                $fatal(1, "EXP code2 injected child flag did not reach parent fault detector");
            end
            @(posedge clk_i);
            #1;
            release dut.u_fma.flags_reg;
            if (dut.state_q !== 5'd26 || rsp_valid_o !== 1'b0) begin
                $fatal(1, "EXP code2 child fault lost fatal priority");
            end
            retire_injected_error(4'd2, 32'd7);

            // 无外部 reset：下一事务必须清除 error/code/flags 并正常完成。
            send_case(32'h00000000, 32'h3f800000, 5'h00, 1'b0, 4'd0,
                      0, 1'b0, 1'b0, 5'd0, 32'd0);
            $display("[NPU-AOR-EXP32][FAULT] code=2 active_cycles=7 payload_zero=1 terminal_once=1 hold_quarantine=1 owner_cardinality=0or1 recovery=1");
        end
    endtask

    task automatic check_code4_injection;
        begin
            @(negedge clk_i);
            operand_i   = 32'h3f800000;
            req_valid_i = 1'b1;
            rsp_ready_i = 1'b0;
            if (req_ready_o !== 1'b1) begin
                $fatal(1, "EXP code4 injection did not start from IDLE");
            end
            @(posedge clk_i);
            #1;
            req_valid_i = 1'b0;
            if (dut.state_q !== 5'd1 || outstanding_owner_q !== 5'b0) begin
                $fatal(1, "EXP code4 injection launch did not reach owner-free CLASSIFY");
            end
            @(negedge clk_i);

            // compile-success TB fault injection：无 owner 的 FMA ghost response 触发 code4。
            force dut.fma_rsp_valid = 1'b1;
            @(posedge clk_i);
            #1;
            release dut.fma_rsp_valid;
            if (dut.state_q !== 5'd26 || rsp_valid_o !== 1'b0) begin
                $fatal(1, "EXP code4 ghost response did not enter ABORT_RESET");
            end
            retire_injected_error(4'd4, 32'd3);

            // 无外部 reset 的 clean recovery。
            send_case(32'h00000000, 32'h3f800000, 5'h00, 1'b0, 4'd0,
                      0, 1'b0, 1'b0, 5'd0, 32'd0);
            $display("[NPU-AOR-EXP32][FAULT] code=4 active_cycles=3 payload_zero=1 terminal_once=1 hold_quarantine=1 owner_cardinality=0or1 recovery=1");
        end
    endtask

    initial begin
        rst_i                   = 1'b1;
        req_valid_i             = 1'b0;
        operand_i               = 32'b0;
        rsp_ready_i             = 1'b0;
        timeout_rst_i           = 1'b1;
        timeout_req_valid_i     = 1'b0;
        timeout_operand_i       = 32'b0;
        timeout_rsp_ready_i     = 1'b0;
        outstanding_owner_q     = 5'b0;

        // Qualified JSONL e635c1ce... table-index records；index0 当前身份就是 +0 special。
        // table0 的实际 DAG/index/scale 另由下方 k=32 JSONL case 逐 bit 覆盖。
        table_input[0]  = 32'h00000000; table_result[0]  = 32'h3f800000;
        table_input[1]  = 32'h3cb17218; table_result[1]  = 32'h3f82cd87;
        table_input[2]  = 32'h3d317218; table_result[2]  = 32'h3f85aac3;
        table_input[3]  = 32'h3d851592; table_result[3]  = 32'h3f88980f;
        table_input[4]  = 32'h3db17218; table_result[4]  = 32'h3f8b95c2;
        table_input[5]  = 32'h3dddce9e; table_result[5]  = 32'h3f8ea43a;
        table_input[6]  = 32'h3e051592; table_result[6]  = 32'h3f91c3d3;
        table_input[7]  = 32'h3e1b43d5; table_result[7]  = 32'h3f94f4f0;
        table_input[8]  = 32'h3e317218; table_result[8]  = 32'h3f9837f0;
        table_input[9]  = 32'h3e47a05b; table_result[9]  = 32'h3f9b8d3a;
        table_input[10] = 32'h3e5dce9e; table_result[10] = 32'h3f9ef532;
        table_input[11] = 32'h3e73fce1; table_result[11] = 32'h3fa27043;
        table_input[12] = 32'h3e851592; table_result[12] = 32'h3fa5fed7;
        table_input[13] = 32'h3e902cb3; table_result[13] = 32'h3fa9a15b;
        table_input[14] = 32'h3e9b43d5; table_result[14] = 32'h3fad583f;
        table_input[15] = 32'h3ea65af6; table_result[15] = 32'h3fb123f5;
        table_input[16] = 32'h3eb17218; table_result[16] = 32'h3fb504f3;
        table_input[17] = 32'h3ebc8939; table_result[17] = 32'h3fb8fbaf;
        table_input[18] = 32'h3ec7a05b; table_result[18] = 32'h3fbd08a4;
        table_input[19] = 32'h3ed2b77c; table_result[19] = 32'h3fc12c4d;
        table_input[20] = 32'h3eddce9e; table_result[20] = 32'h3fc5672a;
        table_input[21] = 32'h3ee8e5bf; table_result[21] = 32'h3fc9b9bd;
        table_input[22] = 32'h3ef3fce1; table_result[22] = 32'h3fce248c;
        table_input[23] = 32'h3eff1402; table_result[23] = 32'h3fd2a81d;
        table_input[24] = 32'h3f051592; table_result[24] = 32'h3fd744fd;
        table_input[25] = 32'h3f0aa123; table_result[25] = 32'h3fdbfbb8;
        table_input[26] = 32'h3f102cb3; table_result[26] = 32'h3fe0ccdf;
        table_input[27] = 32'h3f15b844; table_result[27] = 32'h3fe5b907;
        table_input[28] = 32'h3f1b43d5; table_result[28] = 32'h3feac0c7;
        table_input[29] = 32'h3f20cf66; table_result[29] = 32'h3fefe4ba;
        table_input[30] = 32'h3f265af6; table_result[30] = 32'h3ff5257d;
        table_input[31] = 32'h3f2be687; table_result[31] = 32'h3ffa83b3;

        repeat (3) @(posedge clk_i);
        @(negedge clk_i);
        rst_i = 1'b0;
        $display("[NPU-AOR-EXP32][ORACLE] profile=AOR_AARCH64_FMA_RNE_V1 vectors_sha256=e635c1ce963bb814f746dc828d715bd6cc39841f11ed8551aa7b15f128fcaa41");

        // Special classifier与strict threshold邻点；error payload始终清零。
        send_case(32'h00000000, 32'h3f800000, 5'h00, 1'b0, 4'd0, 0, 1'b0, 1'b0, 5'd0, 32'd0);
        send_case(32'h80000000, 32'h3f800000, 5'h00, 1'b0, 4'd0, 0, 1'b0, 1'b0, 5'd0, 32'd0);
        send_case(32'h7f800000, 32'h7f800000, 5'h00, 1'b0, 4'd0, 0, 1'b0, 1'b0, 5'd0, 32'd0);
        send_case(32'hff800000, 32'h00000000, 5'h00, 1'b0, 4'd0, 0, 1'b0, 1'b0, 5'd0, 32'd0);
        send_case(32'h7fc00001, 32'h00000000, 5'h00, 1'b1, 4'd1, 0, 1'b0, 1'b0, 5'd0, 32'd0);
        send_case(32'h7f800001, 32'h00000000, 5'h00, 1'b1, 4'd1, 0, 1'b0, 1'b0, 5'd0, 32'd0);
        send_case(32'h42b17217, 32'h7f7fff84, 5'h01, 1'b0, 4'd0, 0, 1'b0, 1'b0, 5'd0, 32'd0);
        send_case(32'h42b17218, 32'h7f800000, 5'h05, 1'b0, 4'd0, 0, 1'b0, 1'b0, 5'd0, 32'd0);
        send_case(32'hc2cff1b4, 32'h00000001, 5'h03, 1'b0, 4'd0, 0, 1'b0, 1'b0, 5'd0, 32'd0);
        send_case(32'hc2cff1b5, 32'h00000000, 5'h03, 1'b0, 4'd0, 0, 1'b0, 1'b0, 5'd0, 32'd0);
        send_case(32'h00000001, 32'h3f800000, 5'h01, 1'b0, 4'd0, 0, 1'b0, 1'b1, 5'd0, 32'd0);
        send_case(32'h80000001, 32'h3f800000, 5'h01, 1'b0, 4'd0, 0, 1'b0, 1'b1, 5'd0, 32'd0);

        // 全32 table index；每项检查内部 k/index/scale和z->converter producer绑定。
        for (idx = 0; idx < 32; idx = idx + 1) begin
            // testbench-only循环顺序遍历manifest全部32个index，不生成production硬件。
            send_case(table_input[idx], table_result[idx],
                      (idx == 0) ? 5'h00 : 5'h01, 1'b0, 4'd0,
                      (idx == 1) ? 5 : 0, (idx == 2), (idx != 0), idx[4:0],
                      idx[31:0]);
        end

        // k=-33,-32,-31,-1,0,1,31,32,33 frozen integer-oracle recipes。
        send_case(32'hbf36fda9, 32'h3efa83b3, 5'h01, 1'b0, 4'd0, 0, 1'b0, 1'b1, 5'd31, -32'sd33);
        send_case(32'hbf317218, 32'h3f000000, 5'h01, 1'b0, 4'd0, 0, 1'b0, 1'b1, 5'd0,  -32'sd32);
        send_case(32'hbf2be687, 32'h3f02cd87, 5'h01, 1'b0, 4'd0, 0, 1'b0, 1'b1, 5'd1,  -32'sd31);
        send_case(32'hbcb17218, 32'h3f7a83b3, 5'h01, 1'b0, 4'd0, 0, 1'b0, 1'b1, 5'd31, -32'sd1);
        send_case(32'h00000000, 32'h3f800000, 5'h00, 1'b0, 4'd0, 0, 1'b0, 1'b0, 5'd0, 32'd0);
        send_case(32'h3cb17218, 32'h3f82cd87, 5'h01, 1'b0, 4'd0, 0, 1'b0, 1'b1, 5'd1, 32'd1);
        send_case(32'h3f2be687, 32'h3ffa83b3, 5'h01, 1'b0, 4'd0, 0, 1'b0, 1'b1, 5'd31, 32'd31);
        send_case(32'h3f317218, 32'h40000000, 5'h01, 1'b0, 4'd0, 0, 1'b0, 1'b1, 5'd0, 32'd32);
        send_case(32'h3f36fda9, 32'h4002cd87, 5'h01, 1'b0, 4'd0, 0, 1'b0, 1'b1, 5'd1, 32'd33);

        // Mutation audit六项中的EXP M09/M10/M12：检查strict中间raw，不把M11 GAP伪装成等价。
        send_case(32'h3e7ff823, 32'h3fa459af, 5'h01, 1'b0, 4'd0, 0, 1'b0, 1'b0, 5'd0, 32'd0);
        if (dut.p01_q !== 64'h3f2ea5abe5da46fb) $fatal(1, "EXP M09 strict p01 witness mismatch");
        send_case(32'h3a8000a7, 32'h3f802004, 5'h01, 1'b0, 4'd0, 0, 1'b0, 1'b0, 5'd0, 32'd0);
        if (dut.p2_q !== 64'h3ff0040005380343) $fatal(1, "EXP M10 strict p2 witness mismatch");
        send_case(32'h3a7ff802, 32'h3f802003, 5'h01, 1'b0, 4'd0, 0, 1'b0, 1'b0, 5'd0, 32'd0);
        if (dut.p_q !== 64'h3ff00400600af2f1) $fatal(1, "EXP M12 strict p witness mismatch");
        $display("[NPU-AOR-EXP32][CYCLES] special=2 code1=3 normal=26 launch_inclusive=1 all_cases_checked=1");
        $display("[NPU-AOR-EXP32][GAP] M11 bounded domain checked=71698 no witness; no equivalence claim");

        check_inflight_reset();
        check_resident_reset();
        check_timeout_instance();
        check_code2_injection();
        check_code4_injection();

        // 前一事务NX/OF/UF之后zero特殊路径必须清flags。
        send_case(32'h00000000, 32'h3f800000, 5'h00, 1'b0, 4'd0, 0, 1'b0, 1'b0, 5'd0, 32'd0);

        $display("[NPU-AOR-EXP32][PASS]");
        $finish;
    end

endmodule
