`timescale 1ns/1ps

module tb_unary_glu_element;

    localparam logic [3:0] ST_IDLE          = 4'd0;
    localparam logic [3:0] ST_EXP_REQ       = 4'd2;
    localparam logic [3:0] ST_EXP_WAIT      = 4'd3;
    localparam logic [3:0] ST_ADD_WAIT      = 4'd5;
    localparam logic [3:0] ST_DIV_WAIT      = 4'd7;
    localparam logic [3:0] ST_LOG_WAIT      = 4'd9;
    localparam logic [3:0] ST_MUL_WAIT      = 4'd11;
    localparam logic [3:0] ST_ABORT_RESET   = 4'd12;
    localparam logic [3:0] ST_HOLD_RESPONSE = 4'd13;

    localparam logic [2:0] CHILD_EXP = 3'd0;
    localparam logic [2:0] CHILD_ADD = 3'd1;
    localparam logic [2:0] CHILD_DIV = 3'd2;
    localparam logic [2:0] CHILD_LOG = 3'd3;
    localparam logic [2:0] CHILD_MUL = 3'd4;

    localparam logic [4:0] FLAGS_NONE     = 5'b00000;
    localparam logic [4:0] FLAGS_NX       = 5'b00001;
    localparam logic [4:0] FLAGS_UF_NX    = 5'b00011;
    localparam logic [4:0] FLAGS_OF_NX    = 5'b00101;
    localparam logic [4:0] FLAGS_OF_UF_NX = 5'b00111;

    // Phase-2 topology exact launch-inclusive parent cycles.
    localparam logic [31:0] CYCLES_BYPASS       = 32'd2;
    localparam logic [31:0] CYCLES_REJECT       = 32'd3;
    localparam logic [31:0] CYCLES_SIG_SILU_EXP_NORMAL = 32'd63;
    localparam logic [31:0] CYCLES_SIG_SILU_EXP_SPECIAL = 32'd39;
    localparam logic [31:0] CYCLES_SOFTPLUS_NORMAL = 32'd58;
    localparam logic [31:0] CYCLES_SOFTPLUS_EXP_SPECIAL = 32'd34;
    localparam logic [31:0] CYCLES_SWIGLU_EXP_NORMAL = 32'd67;
    localparam logic [31:0] CYCLES_SWIGLU_EXP_SPECIAL = 32'd43;
    localparam logic [31:0] CYCLES_EXP_NORMAL = 32'd29;
    localparam logic [31:0] CYCLES_EXP_SPECIAL = 32'd5;

    reg         clk_i;
    reg         rst_i;
    reg         req_valid_i;
    wire        req_ready_o;
    reg  [2:0]  opcode_i;
    reg  [31:0] src0_bits_i;
    reg  [31:0] src1_bits_i;
    wire        rsp_valid_o;
    reg         rsp_ready_i;
    wire [31:0] result_bits_o;
    wire [4:0]  flags_o;
    wire        error_o;
    wire [3:0]  error_code_o;
    wire [4:0]  child_call_mask_o;
    wire [31:0] active_cycles_o;

    TensorNpuUnaryGluElement dut (
        .clk_i            (clk_i),
        .rst_i            (rst_i),
        .req_valid_i      (req_valid_i),
        .req_ready_o      (req_ready_o),
        .opcode_i         (opcode_i),
        .src0_bits_i      (src0_bits_i),
        .src1_bits_i      (src1_bits_i),
        .rsp_valid_o      (rsp_valid_o),
        .rsp_ready_i      (rsp_ready_i),
        .result_bits_o    (result_bits_o),
        .flags_o          (flags_o),
        .error_o          (error_o),
        .error_code_o     (error_code_o),
        .child_call_mask_o(child_call_mask_o),
        .active_cycles_o  (active_cycles_o)
    );

    // Small watchdog instance: deadline collision、REQ-credit gate与fatal优先级。
    reg         timeout_req_valid_i;
    wire        timeout_req_ready_o;
    reg  [2:0]  timeout_opcode_i;
    reg  [31:0] timeout_src0_bits_i;
    reg  [31:0] timeout_src1_bits_i;
    wire        timeout_rsp_valid_o;
    reg         timeout_rsp_ready_i;
    wire [31:0] timeout_result_bits_o;
    wire [4:0]  timeout_flags_o;
    wire        timeout_error_o;
    wire [3:0]  timeout_error_code_o;
    wire [4:0]  timeout_child_call_mask_o;
    wire [31:0] timeout_active_cycles_o;

    TensorNpuUnaryGluElement #(
        .COMMAND_TIMEOUT_CYCLES(4)
    ) timeout_dut (
        .clk_i            (clk_i),
        .rst_i            (rst_i),
        .req_valid_i      (timeout_req_valid_i),
        .req_ready_o      (timeout_req_ready_o),
        .opcode_i         (timeout_opcode_i),
        .src0_bits_i      (timeout_src0_bits_i),
        .src1_bits_i      (timeout_src1_bits_i),
        .rsp_valid_o      (timeout_rsp_valid_o),
        .rsp_ready_i      (timeout_rsp_ready_i),
        .result_bits_o    (timeout_result_bits_o),
        .flags_o          (timeout_flags_o),
        .error_o          (timeout_error_o),
        .error_code_o     (timeout_error_code_o),
        .child_call_mask_o(timeout_child_call_mask_o),
        .active_cycles_o  (timeout_active_cycles_o)
    );

    integer cycle_count;
    integer completed_transactions;
    integer expected_count;
    integer launched_count;
    integer returned_count;
    integer scoreboard_outstanding;
    reg [2:0] scoreboard_owner;
    reg expected_check_enable;
    string current_case;

    reg [2:0]  expected_child_id [0:4];
    reg [31:0] expected_child_lhs [0:4];
    reg [31:0] expected_child_rhs [0:4];
    reg [31:0] expected_child_result [0:4];
    reg [4:0]  expected_child_flags [0:4];

    reg [31:0] nonfinite_raw [0:3];

    initial clk_i = 1'b0;
    always #5 clk_i <= ~clk_i;

    always @(posedge clk_i) begin
        cycle_count <= cycle_count + 1;
        if (cycle_count >= 20000) begin
            $display("[NPU-UNARY-GLU-ELEMENT][FAIL] global-timeout cycle=%0d case=%s",
                     cycle_count + 1, current_case);
            $fatal(1);
        end
    end

    task automatic fail_case(input string reason);
        begin
            $display("[NPU-UNARY-GLU-ELEMENT][FAIL] case=%s cycle=%0d reason=%s",
                     current_case, cycle_count, reason);
            $fatal(1);
        end
    endtask

    task automatic begin_expectations(input string case_name);
        integer index;
        begin
            current_case = case_name;
            expected_count = 0;
            launched_count = 0;
            returned_count = 0;
            expected_check_enable = 1'b1;
            for (index = 0; index < 5; index = index + 1) begin
                expected_child_id[index] = 3'b0;
                expected_child_lhs[index] = 32'b0;
                expected_child_rhs[index] = 32'b0;
                expected_child_result[index] = 32'b0;
                expected_child_flags[index] = 5'b0;
            end
        end
    endtask

    task automatic begin_unchecked(input string case_name);
        begin
            current_case = case_name;
            expected_count = 0;
            launched_count = 0;
            returned_count = 0;
            expected_check_enable = 1'b0;
        end
    endtask

    task automatic expect_child(
        input logic [2:0]  child_id,
        input logic [31:0] operand_lhs,
        input logic [31:0] operand_rhs,
        input logic [31:0] expected_result,
        input logic [4:0]  expected_flags
    );
        begin
            if (expected_count >= 5) begin
                fail_case("expected child array overflow");
            end
            expected_child_id[expected_count] = child_id;
            expected_child_lhs[expected_count] = operand_lhs;
            expected_child_rhs[expected_count] = operand_rhs;
            expected_child_result[expected_count] = expected_result;
            expected_child_flags[expected_count] = expected_flags;
            expected_count = expected_count + 1;
        end
    endtask

    // 独立owner scoreboard：逐child真实handshake检查顺序、operand、raw与flags。
    always @(posedge clk_i) begin : child_owner_monitor
        integer req_fires_now;
        integer rsp_fires_now;
        reg [2:0] req_id_now;
        reg [2:0] rsp_id_now;
        reg [31:0] req_lhs_now;
        reg [31:0] req_rhs_now;
        reg [31:0] rsp_result_now;
        reg [4:0]  rsp_flags_now;
        reg        rsp_child_error_now;
        begin
            req_fires_now = 0;
            rsp_fires_now = 0;
            req_id_now = 0;
            rsp_id_now = 0;
            req_lhs_now = 32'b0;
            req_rhs_now = 32'b0;
            rsp_result_now = 32'b0;
            rsp_flags_now = 5'b0;
            rsp_child_error_now = 1'b0;

            if (rst_i) begin
                scoreboard_outstanding <= 0;
                scoreboard_owner <= 0;
            end else if (dut.child_rst) begin
                if (dut.exp_req_valid || dut.addmul_req_valid ||
                    dut.div_req_valid || dut.log_req_valid ||
                    dut.exp_rsp_ready || dut.addmul_rsp_ready ||
                    dut.div_rsp_ready || dut.log_rsp_ready) begin
                    fail_case("child credit was nonzero during ABORT/HOLD quarantine");
                end
                scoreboard_outstanding <= 0;
                scoreboard_owner <= 0;
            end else begin
                if (dut.exp_req_valid && dut.exp_req_ready) begin
                    req_fires_now = req_fires_now + 1;
                    req_id_now = CHILD_EXP;
                    req_lhs_now = dut.exp_operand;
                    req_rhs_now = 32'b0;
                end
                if (dut.addmul_req_valid && dut.addmul_req_ready) begin
                    req_fires_now = req_fires_now + 1;
                    req_id_now = dut.addmul_op_mul ? CHILD_MUL : CHILD_ADD;
                    req_lhs_now = dut.addmul_lhs;
                    req_rhs_now = dut.addmul_rhs;
                end
                if (dut.div_req_valid && dut.div_req_ready) begin
                    req_fires_now = req_fires_now + 1;
                    req_id_now = CHILD_DIV;
                    req_lhs_now = dut.div_lhs;
                    req_rhs_now = dut.add_result_q;
                end
                if (dut.log_req_valid && dut.log_req_ready) begin
                    req_fires_now = req_fires_now + 1;
                    req_id_now = CHILD_LOG;
                    req_lhs_now = dut.add_result_q;
                    req_rhs_now = 32'b0;
                end

                if (dut.exp_rsp_valid && dut.exp_rsp_ready) begin
                    rsp_fires_now = rsp_fires_now + 1;
                    rsp_id_now = CHILD_EXP;
                    rsp_result_now = dut.exp_rsp_result;
                    rsp_flags_now = dut.exp_rsp_flags;
                    rsp_child_error_now = dut.exp_rsp_error ||
                                          (dut.exp_rsp_error_code != 4'd0);
                end
                if (dut.addmul_rsp_valid && dut.addmul_rsp_ready) begin
                    rsp_fires_now = rsp_fires_now + 1;
                    rsp_id_now = (dut.state_q == ST_MUL_WAIT) ? CHILD_MUL : CHILD_ADD;
                    rsp_result_now = dut.addmul_rsp_result;
                    rsp_flags_now = dut.addmul_rsp_flags;
                end
                if (dut.div_rsp_valid && dut.div_rsp_ready) begin
                    rsp_fires_now = rsp_fires_now + 1;
                    rsp_id_now = CHILD_DIV;
                    rsp_result_now = dut.div_rsp_result;
                    rsp_flags_now = dut.div_rsp_flags;
                end
                if (dut.log_rsp_valid && dut.log_rsp_ready) begin
                    rsp_fires_now = rsp_fires_now + 1;
                    rsp_id_now = CHILD_LOG;
                    rsp_result_now = dut.log_rsp_result;
                    rsp_flags_now = dut.log_rsp_flags;
                    rsp_child_error_now = dut.log_rsp_error ||
                                          (dut.log_rsp_error_code != 4'd0);
                end

                if (req_fires_now > 1) begin
                    fail_case("more than one child request handshake in one cycle");
                end
                if (rsp_fires_now > 1) begin
                    fail_case("more than one child response handshake in one cycle");
                end

                if (req_fires_now == 1) begin
                    if (scoreboard_outstanding != 0) begin
                        fail_case("child request launched while another owner outstanding");
                    end
                    if (expected_check_enable) begin
                        if (launched_count >= expected_count) begin
                            fail_case("unexpected extra child request");
                        end
                        if (req_id_now[2:0] !== expected_child_id[launched_count]) begin
                            fail_case($sformatf("child request id=%0d expected=%0d index=%0d",
                                               req_id_now,
                                               expected_child_id[launched_count], launched_count));
                        end
                        if ((req_lhs_now !== expected_child_lhs[launched_count]) ||
                            (req_rhs_now !== expected_child_rhs[launched_count])) begin
                            fail_case($sformatf(
                                "child operands id=%0d lhs=%08x rhs=%08x expected_lhs=%08x expected_rhs=%08x",
                                req_id_now, req_lhs_now, req_rhs_now,
                                expected_child_lhs[launched_count],
                                expected_child_rhs[launched_count]));
                        end
                    end
                    scoreboard_outstanding <= 1;
                    scoreboard_owner <= req_id_now;
                    launched_count <= launched_count + 1;
                end

                if (rsp_fires_now == 1) begin
                    if (scoreboard_outstanding != 1) begin
                        fail_case("child response consumed without an outstanding owner");
                    end
                    if (rsp_id_now != scoreboard_owner) begin
                        fail_case($sformatf("response owner=%0d expected_owner=%0d",
                                           rsp_id_now, scoreboard_owner));
                    end
                    if (expected_check_enable) begin
                        if (returned_count >= expected_count) begin
                            fail_case("unexpected extra child response");
                        end
                        if (rsp_id_now[2:0] !== expected_child_id[returned_count]) begin
                            fail_case($sformatf("child response id=%0d expected=%0d index=%0d",
                                               rsp_id_now,
                                               expected_child_id[returned_count], returned_count));
                        end
                        if (rsp_child_error_now) begin
                            fail_case("successful vector observed child error/code");
                        end
                        if ((rsp_result_now !== expected_child_result[returned_count]) ||
                            (rsp_flags_now !== expected_child_flags[returned_count])) begin
                            fail_case($sformatf(
                                "child response id=%0d raw=%08x flags=%02x expected_raw=%08x expected_flags=%02x",
                                rsp_id_now, rsp_result_now, rsp_flags_now,
                                expected_child_result[returned_count],
                                expected_child_flags[returned_count]));
                        end
                    end
                    scoreboard_outstanding <= 0;
                    scoreboard_owner <= 0;
                    returned_count <= returned_count + 1;
                end

                if ((scoreboard_outstanding < 0) || (scoreboard_outstanding > 1)) begin
                    fail_case("owner scoreboard left 0/1 range");
                end
            end
        end
    end

    task automatic run_transaction(
        input string       case_name,
        input logic [2:0]  case_opcode,
        input logic [31:0] case_src0,
        input logic [31:0] case_src1,
        input logic [31:0] expected_result,
        input logic [4:0]  expected_flags,
        input logic        expected_error,
        input logic [3:0]  expected_code,
        input logic [4:0]  expected_mask,
        input logic [31:0] expected_cycles,
        input integer      hold_cycles,
        input integer      probe_busy
    );
        integer wait_count;
        integer hold_index;
        reg [31:0] held_result;
        reg [4:0]  held_flags;
        reg        held_error;
        reg [3:0]  held_code;
        reg [4:0]  held_mask;
        reg [31:0] held_cycles;
        reg [31:0] held_internal_active;
        reg [31:0] held_watchdog;
        reg [2:0]  locked_opcode;
        reg [31:0] locked_src0;
        reg [31:0] locked_src1;
        begin
            current_case = case_name;
            rsp_ready_i = 1'b0;
            wait_count = 0;
            while (req_ready_o !== 1'b1) begin
                @(posedge clk_i);
                @(negedge clk_i);
                wait_count = wait_count + 1;
                if (wait_count > 64) begin
                    fail_case("request channel did not become ready");
                end
            end

            opcode_i = case_opcode;
            src0_bits_i = case_src0;
            src1_bits_i = case_src1;
            req_valid_i = 1'b1;
            @(posedge clk_i);
            @(negedge clk_i);
            req_valid_i = 1'b0;
            locked_opcode = dut.opcode_q;
            locked_src0 = dut.src0_q;
            locked_src1 = dut.src1_q;
            if ((locked_opcode !== case_opcode) ||
                (locked_src0 !== case_src0) || (locked_src1 !== case_src1)) begin
                fail_case("request payload was not atomically captured");
            end
            if (req_ready_o !== 1'b0) begin
                fail_case("request credit remained open after accept");
            end

            if (probe_busy != 0) begin
                opcode_i = 3'd7;
                src0_bits_i = 32'h7fc12345;
                src1_bits_i = 32'hff800000;
                req_valid_i = 1'b1;
                @(posedge clk_i);
                @(negedge clk_i);
                req_valid_i = 1'b0;
                if ((dut.opcode_q !== locked_opcode) ||
                    (dut.src0_q !== locked_src0) || (dut.src1_q !== locked_src1)) begin
                    fail_case("busy request changed resident payload");
                end
                if (req_ready_o !== 1'b0) begin
                    fail_case("busy request observed credit");
                end
            end

            wait_count = 0;
            while (rsp_valid_o !== 1'b1) begin
                if (req_ready_o !== 1'b0) begin
                    fail_case("request credit reopened before terminal response");
                end
                @(posedge clk_i);
                @(negedge clk_i);
                wait_count = wait_count + 1;
                if (wait_count > 1200) begin
                    fail_case("terminal response timeout");
                end
            end

            if ((result_bits_o !== expected_result) ||
                (flags_o !== expected_flags) ||
                (error_o !== expected_error) ||
                (error_code_o !== expected_code) ||
                (child_call_mask_o !== expected_mask) ||
                (active_cycles_o !== expected_cycles)) begin
                fail_case($sformatf(
                    "terminal raw=%08x flags=%02x error=%0d code=%0d mask=%02x cycles=%0d expected=%08x/%02x/%0d/%0d/%02x/%0d",
                    result_bits_o, flags_o, error_o, error_code_o,
                    child_call_mask_o, active_cycles_o, expected_result,
                    expected_flags, expected_error, expected_code,
                    expected_mask, expected_cycles));
            end
            if ((launched_count != expected_count) ||
                (returned_count != expected_count)) begin
                fail_case($sformatf("child count launch=%0d return=%0d expected=%0d",
                                    launched_count, returned_count, expected_count));
            end
            if (scoreboard_outstanding != 0) begin
                fail_case("terminal response published with child outstanding");
            end
            if ((dut.state_q !== ST_HOLD_RESPONSE) || (dut.child_rst !== 1'b1)) begin
                fail_case("terminal response was not in HOLD quarantine");
            end

            held_result = result_bits_o;
            held_flags = flags_o;
            held_error = error_o;
            held_code = error_code_o;
            held_mask = child_call_mask_o;
            held_cycles = active_cycles_o;
            held_internal_active = dut.active_cycles_q;
            held_watchdog = dut.watchdog_q;
            for (hold_index = 0; hold_index < hold_cycles; hold_index = hold_index + 1) begin
                opcode_i = hold_index[2:0];
                src0_bits_i = 32'h7f800000 ^ hold_index;
                src1_bits_i = 32'h80000000 | hold_index;
                req_valid_i = 1'b1;
                @(posedge clk_i);
                @(negedge clk_i);
                if ((rsp_valid_o !== 1'b1) ||
                    (result_bits_o !== held_result) ||
                    (flags_o !== held_flags) || (error_o !== held_error) ||
                    (error_code_o !== held_code) ||
                    (child_call_mask_o !== held_mask) ||
                    (active_cycles_o !== held_cycles)) begin
                    fail_case("response payload changed under backpressure");
                end
                if ((dut.active_cycles_q !== held_internal_active) ||
                    (dut.watchdog_q !== held_watchdog)) begin
                    fail_case("HOLD advanced active/watchdog counter");
                end
                if ((req_ready_o !== 1'b0) || (dut.child_rst !== 1'b1)) begin
                    fail_case("HOLD exposed request credit or dropped quarantine");
                end
            end
            req_valid_i = 1'b0;

            // retire边沿故意保持新request valid；同拍不得accept。
            opcode_i = 3'd7;
            src0_bits_i = 32'h7fc00000;
            src1_bits_i = 32'h7fc00000;
            req_valid_i = 1'b1;
            rsp_ready_i = 1'b1;
            @(posedge clk_i);
            @(negedge clk_i);
            req_valid_i = 1'b0;
            rsp_ready_i = 1'b0;
            if ((rsp_valid_o !== 1'b0) || (req_ready_o !== 1'b1) ||
                (dut.state_q !== ST_IDLE) || dut.resident_q) begin
                fail_case("response retire did not return to clean IDLE");
            end
            if ((dut.opcode_q !== locked_opcode) ||
                (dut.src0_q !== locked_src0) || (dut.src1_q !== locked_src1)) begin
                fail_case("response retire accepted a new request on the same edge");
            end

            @(posedge clk_i);
            @(negedge clk_i);
            if (rsp_valid_o !== 1'b0) begin
                fail_case("terminal response was published more than once");
            end
            expected_check_enable = 1'b0;
            completed_transactions = completed_transactions + 1;
        end
    endtask

    task automatic expect_sigmoid(
        input logic [31:0] src0,
        input logic [31:0] exp_raw,
        input logic [4:0]  exp_flags,
        input logic [31:0] add_raw,
        input logic [4:0]  add_flags,
        input logic [31:0] div_raw,
        input logic [4:0]  div_flags
    );
        begin
            expect_child(CHILD_EXP, src0 ^ 32'h80000000, 32'b0,
                         exp_raw, exp_flags);
            expect_child(CHILD_ADD, 32'h3f800000, exp_raw,
                         add_raw, add_flags);
            expect_child(CHILD_DIV, 32'h3f800000, add_raw,
                         div_raw, div_flags);
        end
    endtask

    task automatic expect_exp(
        input logic [31:0] src0,
        input logic [31:0] exp_raw,
        input logic [4:0]  exp_flags
    );
        begin
            expect_child(CHILD_EXP, src0, 32'b0, exp_raw, exp_flags);
        end
    endtask

    task automatic expect_softplus(
        input logic [31:0] src0,
        input logic [31:0] exp_raw,
        input logic [4:0]  exp_flags,
        input logic [31:0] add_raw,
        input logic [4:0]  add_flags,
        input logic [31:0] log_raw,
        input logic [4:0]  log_flags
    );
        begin
            expect_child(CHILD_EXP, src0, 32'b0, exp_raw, exp_flags);
            expect_child(CHILD_ADD, 32'h3f800000, exp_raw,
                         add_raw, add_flags);
            expect_child(CHILD_LOG, add_raw, 32'b0, log_raw, log_flags);
        end
    endtask

    task automatic expect_silu(
        input logic [31:0] src0,
        input logic [31:0] exp_raw,
        input logic [4:0]  exp_flags,
        input logic [31:0] add_raw,
        input logic [4:0]  add_flags,
        input logic [31:0] div_raw,
        input logic [4:0]  div_flags
    );
        begin
            expect_child(CHILD_EXP, src0 ^ 32'h80000000, 32'b0,
                         exp_raw, exp_flags);
            expect_child(CHILD_ADD, 32'h3f800000, exp_raw,
                         add_raw, add_flags);
            expect_child(CHILD_DIV, src0, add_raw, div_raw, div_flags);
        end
    endtask

    task automatic expect_swiglu(
        input logic [31:0] src0,
        input logic [31:0] src1,
        input logic [31:0] exp_raw,
        input logic [4:0]  exp_flags,
        input logic [31:0] add_raw,
        input logic [4:0]  add_flags,
        input logic [31:0] div_raw,
        input logic [4:0]  div_flags,
        input logic [31:0] mul_raw,
        input logic [4:0]  mul_flags
    );
        begin
            expect_child(CHILD_EXP, src0 ^ 32'h80000000, 32'b0,
                         exp_raw, exp_flags);
            expect_child(CHILD_ADD, 32'h3f800000, exp_raw,
                         add_raw, add_flags);
            expect_child(CHILD_DIV, src0, add_raw, div_raw, div_flags);
            expect_child(CHILD_MUL, div_raw, src1, mul_raw, mul_flags);
        end
    endtask

    task automatic start_main_unchecked(
        input string       case_name,
        input logic [2:0]  case_opcode,
        input logic [31:0] case_src0,
        input logic [31:0] case_src1
    );
        integer wait_count;
        begin
            begin_unchecked(case_name);
            rsp_ready_i = 1'b0;
            wait_count = 0;
            while (req_ready_o !== 1'b1) begin
                @(posedge clk_i);
                @(negedge clk_i);
                wait_count = wait_count + 1;
                if (wait_count > 64) fail_case("unchecked request did not get credit");
            end
            opcode_i = case_opcode;
            src0_bits_i = case_src0;
            src1_bits_i = case_src1;
            req_valid_i = 1'b1;
            @(posedge clk_i);
            @(negedge clk_i);
            req_valid_i = 1'b0;
        end
    endtask

    task automatic wait_main_state(
        input logic [3:0] target_state,
        input integer max_cycles
    );
        integer wait_count;
        begin
            wait_count = 0;
            while (dut.state_q !== target_state) begin
                @(posedge clk_i);
                @(negedge clk_i);
                wait_count = wait_count + 1;
                if (wait_count > max_cycles) begin
                    fail_case($sformatf("state wait timeout target=%0d current=%0d",
                                        target_state, dut.state_q));
                end
            end
        end
    endtask

    task automatic run_bypass_recovery(input string recovery_name);
        begin
            begin_expectations(recovery_name);
            run_transaction(recovery_name, 3'd1, 32'h41a00001, 32'h7fc12345,
                            32'h41a00001, FLAGS_NONE, 1'b0, 4'd0, 5'b00000,
                            CYCLES_BYPASS, 0, 0);
        end
    endtask

    task automatic reset_in_state(
        input string       case_name,
        input logic [3:0]  target_state,
        input logic [2:0]  case_opcode,
        input logic [31:0] case_src0,
        input logic [31:0] case_src1
    );
        integer idle_probe;
        begin
            start_main_unchecked(case_name, case_opcode, case_src0, case_src1);
            wait_main_state(target_state, 700);
            rst_i = 1'b1;
            #1;
            if ((req_ready_o !== 1'b0) || (rsp_valid_o !== 1'b0)) begin
                fail_case("reset did not immediately mask external credit/response");
            end
            repeat (2) @(posedge clk_i);
            @(negedge clk_i);
            if ((dut.state_q !== ST_IDLE) || dut.resident_q || dut.owner_valid_q ||
                (rsp_valid_o !== 1'b0) || (req_ready_o !== 1'b0)) begin
                fail_case("reset did not clear parent resident/owner/response");
            end
            rst_i = 1'b0;
            for (idle_probe = 0; idle_probe < 8; idle_probe = idle_probe + 1) begin
                @(posedge clk_i);
                @(negedge clk_i);
                if ((rsp_valid_o !== 1'b0) || (req_ready_o !== 1'b1) ||
                    (dut.state_q !== ST_IDLE)) begin
                    fail_case("reset cancellation produced stale completion or blocked credit");
                end
            end
            run_bypass_recovery($sformatf("%s-clean-recovery", case_name));
        end
    endtask

    task automatic check_main_error_response(
        input string       case_name,
        input logic [3:0]  expected_code,
        input logic [4:0]  expected_mask,
        input logic [31:0] expected_cycles,
        input integer      expected_launches
    );
        integer wait_count;
        integer hold_index;
        reg [31:0] held_cycles;
        begin
            current_case = case_name;
            wait_count = 0;
            while (rsp_valid_o !== 1'b1) begin
                @(posedge clk_i);
                @(negedge clk_i);
                wait_count = wait_count + 1;
                if (wait_count > 128) fail_case("error response timeout");
            end
            if ((result_bits_o !== 32'b0) || (flags_o !== 5'b0) ||
                (error_o !== 1'b1) || (error_code_o !== expected_code) ||
                (child_call_mask_o !== expected_mask) ||
                (active_cycles_o !== expected_cycles) ||
                (launched_count != expected_launches)) begin
                fail_case($sformatf(
                    "error payload raw=%08x flags=%02x error=%0d code=%0d mask=%02x cycles=%0d launches=%0d",
                    result_bits_o, flags_o, error_o, error_code_o,
                    child_call_mask_o, active_cycles_o, launched_count));
            end
            if ((dut.state_q !== ST_HOLD_RESPONSE) || (dut.child_rst !== 1'b1)) begin
                fail_case("error response did not enter HOLD quarantine");
            end
            held_cycles = active_cycles_o;
            for (hold_index = 0; hold_index < 3; hold_index = hold_index + 1) begin
                @(posedge clk_i);
                @(negedge clk_i);
                if ((rsp_valid_o !== 1'b1) ||
                    (active_cycles_o !== held_cycles) ||
                    (result_bits_o !== 32'b0) || (flags_o !== 5'b0) ||
                    (error_code_o !== expected_code) ||
                    (child_call_mask_o !== expected_mask) ||
                    (dut.child_rst !== 1'b1)) begin
                    fail_case("error HOLD payload/quarantine was not stable");
                end
            end
            rsp_ready_i = 1'b1;
            @(posedge clk_i);
            @(negedge clk_i);
            rsp_ready_i = 1'b0;
            if ((rsp_valid_o !== 1'b0) || (req_ready_o !== 1'b1) ||
                (dut.state_q !== ST_IDLE)) begin
                fail_case("error response retire did not recover without global reset");
            end
            completed_transactions = completed_transactions + 1;
        end
    endtask

    task automatic check_explicit_child_error;
        begin
            start_main_unchecked("explicit-exp-child-error", 3'd0,
                                 32'h3f800000, 32'b0);
            wait_main_state(ST_EXP_WAIT, 32);
            force dut.exp_rsp_valid = 1'b1;
            force dut.exp_rsp_result = 32'b0;
            force dut.exp_rsp_flags = 5'b0;
            force dut.exp_rsp_error = 1'b1;
            force dut.exp_rsp_error_code = 4'd2;
            @(posedge clk_i);
            @(negedge clk_i);
            release dut.exp_rsp_valid;
            release dut.exp_rsp_result;
            release dut.exp_rsp_flags;
            release dut.exp_rsp_error;
            release dut.exp_rsp_error_code;
            check_main_error_response("explicit-exp-child-error", 4'd2,
                                      5'b00001, 32'd5, 1);
            run_bypass_recovery("explicit-exp-child-error-clean-recovery");
        end
    endtask

    task automatic check_add_nan_child_error;
        begin
            start_main_unchecked("add-child-nan", 3'd0,
                                 32'h3f800000, 32'b0);
            wait_main_state(ST_ADD_WAIT, 128);
            force dut.addmul_rsp_valid = 1'b1;
            force dut.addmul_rsp_result = 32'h7fc00000;
            force dut.addmul_rsp_flags = 5'b0;
            @(posedge clk_i);
            @(negedge clk_i);
            release dut.addmul_rsp_valid;
            release dut.addmul_rsp_result;
            release dut.addmul_rsp_flags;
            check_main_error_response("add-child-nan", 4'd2,
                                      5'b00011, 32'd32, 2);
            run_bypass_recovery("add-child-nan-clean-recovery");
        end
    endtask

    task automatic check_div_dz_child_error;
        begin
            start_main_unchecked("div-child-dz", 3'd0,
                                 32'h3f800000, 32'b0);
            wait_main_state(ST_DIV_WAIT, 160);
            force dut.div_rsp_valid = 1'b1;
            force dut.div_rsp_result = 32'h7f800000;
            force dut.div_rsp_flags = 5'b01000;
            @(posedge clk_i);
            @(negedge clk_i);
            release dut.div_rsp_valid;
            release dut.div_rsp_result;
            release dut.div_rsp_flags;
            check_main_error_response("div-child-dz", 4'd2,
                                      5'b00111, 32'd36, 3);
            run_bypass_recovery("div-child-dz-clean-recovery");
        end
    endtask

    task automatic check_wrong_owner;
        begin
            start_main_unchecked("wrong-owner-add-response-during-exp", 3'd0,
                                 32'h3f800000, 32'b0);
            wait_main_state(ST_EXP_WAIT, 32);
            // Force the child holding register, not the flattened parent wire;
            // this makes the non-owner completion an actual visible child response.
            force dut.u_addmul.rsp_valid_q = 1'b1;
            #1;
            if ((dut.addmul_rsp_valid !== 1'b1) ||
                (dut.ghost_response_now !== 1'b1) ||
                (dut.normal_progress_enable !== 1'b0)) begin
                fail_case("wrong-owner injection did not reach parent ghost detector");
            end
            @(posedge clk_i);
            @(negedge clk_i);
            release dut.u_addmul.rsp_valid_q;
            if (dut.state_q !== ST_ABORT_RESET) begin
                fail_case("wrong-owner response did not enter ABORT_RESET");
            end
            check_main_error_response("wrong-owner-add-response-during-exp", 4'd4,
                                      5'b00001, 32'd5, 1);
            run_bypass_recovery("wrong-owner-clean-recovery");
        end
    endtask

    task automatic check_literal_illegal_state(
        input string      case_name,
        input logic [3:0] illegal_state
    );
        integer stale_probe;
        begin
            if ((illegal_state !== 4'd14) && (illegal_state !== 4'd15)) begin
                fail_case("literal illegal-state task only accepts 4'd14/4'd15");
            end
            start_main_unchecked(case_name, 3'd0,
                                 32'h3f800000, 32'b0);
            wait_main_state(ST_EXP_WAIT, 32);
            // wait_main_state在negedge观测点返回；用单次阻塞层次deposit
            // 把真实state_q改成两个未枚举literal。不使force/release，
            // 避免release遮蔽DUT在下一posedge对ABORT_RESET的NBA。
            // 该半拍直接覆盖state_valid default decoder、protocol abort
            // qualifier与完整parent/child credit gating。
            dut.state_q = illegal_state;
            #1;
            if ((dut.state_q !== illegal_state) ||
                (dut.state_valid !== 1'b0) ||
                (dut.internal_fault_now !== 1'b1) ||
                (dut.normal_progress_enable !== 1'b0) ||
                (req_ready_o !== 1'b0) ||
                (dut.exp_req_valid !== 1'b0) ||
                (dut.addmul_req_valid !== 1'b0) ||
                (dut.div_req_valid !== 1'b0) ||
                (dut.log_req_valid !== 1'b0) ||
                (dut.exp_rsp_ready !== 1'b0) ||
                (dut.addmul_rsp_ready !== 1'b0) ||
                (dut.div_rsp_ready !== 1'b0) ||
                (dut.log_rsp_ready !== 1'b0)) begin
                fail_case("literal illegal state did not close normal parent/child credit");
            end
            @(posedge clk_i);
            @(negedge clk_i);
            if ((dut.state_q !== ST_ABORT_RESET) ||
                (dut.child_rst !== 1'b1) ||
                (rsp_valid_o !== 1'b0)) begin
                fail_case("literal illegal state did not enter full ABORT quarantine");
            end
            check_main_error_response(case_name, 4'd4,
                                      5'b00001, 32'd5, 1);
            for (stale_probe = 0; stale_probe < 4;
                 stale_probe = stale_probe + 1) begin
                @(posedge clk_i);
                @(negedge clk_i);
                if ((rsp_valid_o !== 1'b0) ||
                    (req_ready_o !== 1'b1) ||
                    (dut.state_q !== ST_IDLE) || dut.resident_q) begin
                    fail_case("literal illegal state left a stale response/resident owner");
                end
            end
            run_bypass_recovery($sformatf("%s-clean-recovery", case_name));
        end
    endtask

    task automatic check_idle_ghost;
        integer probe;
        begin
            begin_unchecked("idle-ghost-log-response");
            if ((dut.state_q !== ST_IDLE) || dut.resident_q ||
                (req_ready_o !== 1'b1)) begin
                fail_case("ghost test did not start in clean IDLE");
            end
            force dut.u_log.rsp_valid_q = 1'b1;
            #1;
            if ((dut.log_rsp_valid !== 1'b1) ||
                (dut.ghost_response_now !== 1'b1) ||
                (req_ready_o !== 1'b0)) begin
                fail_case("IDLE ghost injection did not close credit/reach detector");
            end
            @(posedge clk_i);
            @(negedge clk_i);
            release dut.u_log.rsp_valid_q;
            if ((dut.state_q !== ST_ABORT_RESET) ||
                (rsp_valid_o !== 1'b0) || dut.resident_q) begin
                fail_case("IDLE ghost did not enter unmatched ABORT wash");
            end
            @(posedge clk_i);
            @(negedge clk_i);
            if ((dut.state_q !== ST_IDLE) || (rsp_valid_o !== 1'b0)) begin
                fail_case("IDLE ghost created an unmatched response");
            end
            for (probe = 0; probe < 6; probe = probe + 1) begin
                @(posedge clk_i);
                @(negedge clk_i);
                if ((rsp_valid_o !== 1'b0) || (req_ready_o !== 1'b1)) begin
                    fail_case("ghost wash did not leave clean reusable IDLE");
                end
            end
            run_bypass_recovery("idle-ghost-clean-recovery");
        end
    endtask

    task automatic start_timeout_request(input string case_name);
        integer wait_count;
        begin
            current_case = case_name;
            timeout_rsp_ready_i = 1'b0;
            wait_count = 0;
            while (timeout_req_ready_o !== 1'b1) begin
                @(posedge clk_i);
                @(negedge clk_i);
                wait_count = wait_count + 1;
                if (wait_count > 32) fail_case("timeout instance did not become ready");
            end
            timeout_opcode_i = 3'd0;
            timeout_src0_bits_i = 32'h3f800000;
            timeout_src1_bits_i = 32'b0;
            timeout_req_valid_i = 1'b1;
            @(posedge clk_i);
            @(negedge clk_i);
            timeout_req_valid_i = 1'b0;
        end
    endtask

    task automatic wait_timeout_state_watchdog(
        input logic [3:0] target_state,
        input logic [31:0] target_watchdog
    );
        integer wait_count;
        begin
            wait_count = 0;
            while ((timeout_dut.state_q !== target_state) ||
                   (timeout_dut.watchdog_q !== target_watchdog)) begin
                @(posedge clk_i);
                @(negedge clk_i);
                wait_count = wait_count + 1;
                if (wait_count > 64) begin
                    fail_case($sformatf(
                        "timeout state/watchdog wait failed state=%0d watchdog=%0d",
                        timeout_dut.state_q, timeout_dut.watchdog_q));
                end
            end
        end
    endtask

    task automatic check_timeout_response(
        input string       case_name,
        input logic [3:0]  expected_code,
        input logic [4:0]  expected_mask,
        input logic [31:0] expected_cycles
    );
        integer wait_count;
        integer hold_index;
        begin
            current_case = case_name;
            wait_count = 0;
            while (timeout_rsp_valid_o !== 1'b1) begin
                @(posedge clk_i);
                @(negedge clk_i);
                wait_count = wait_count + 1;
                if (wait_count > 32) fail_case("timeout/fatal response was not published");
            end
            if ((timeout_result_bits_o !== 32'b0) ||
                (timeout_flags_o !== 5'b0) ||
                (timeout_error_o !== 1'b1) ||
                (timeout_error_code_o !== expected_code) ||
                (timeout_child_call_mask_o !== expected_mask) ||
                (timeout_active_cycles_o !== expected_cycles) ||
                (timeout_dut.child_rst !== 1'b1)) begin
                fail_case($sformatf(
                    "timeout terminal raw=%08x flags=%02x err=%0d code=%0d mask=%02x cycles=%0d",
                    timeout_result_bits_o, timeout_flags_o, timeout_error_o,
                    timeout_error_code_o, timeout_child_call_mask_o,
                    timeout_active_cycles_o));
            end
            for (hold_index = 0; hold_index < 4; hold_index = hold_index + 1) begin
                @(posedge clk_i);
                @(negedge clk_i);
                if ((timeout_rsp_valid_o !== 1'b1) ||
                    (timeout_active_cycles_o !== expected_cycles) ||
                    (timeout_dut.child_rst !== 1'b1)) begin
                    fail_case("timeout HOLD snapshot/quarantine changed");
                end
            end
            timeout_rsp_ready_i = 1'b1;
            @(posedge clk_i);
            @(negedge clk_i);
            timeout_rsp_ready_i = 1'b0;
            if ((timeout_rsp_valid_o !== 1'b0) ||
                (timeout_req_ready_o !== 1'b1) ||
                (timeout_dut.state_q !== ST_IDLE)) begin
                fail_case("timeout instance did not recover without global reset");
            end
            completed_transactions = completed_transactions + 1;
        end
    endtask

    task automatic check_timeout_req_gate;
        begin
            start_timeout_request("timeout-req-ready-deadline-gate");
            wait_timeout_state_watchdog(ST_EXP_REQ, 32'd2);
            force timeout_dut.exp_req_ready = 1'b0;
            wait_timeout_state_watchdog(ST_EXP_REQ, 32'd4);
            release timeout_dut.exp_req_ready;
            #1;
            if ((timeout_dut.exp_req_ready !== 1'b1) ||
                (timeout_dut.exp_req_valid !== 1'b0)) begin
                fail_case("deadline REQ edge was not ready while parent valid remained gated");
            end
            @(posedge clk_i);
            @(negedge clk_i);
            check_timeout_response("timeout-req-ready-deadline-gate", 4'd3,
                                   5'b00000, 32'd6);
        end
    endtask

    task automatic check_timeout_normal_response_collision;
        begin
            start_timeout_request("timeout-normal-response-collision");
            wait_timeout_state_watchdog(ST_EXP_WAIT, 32'd4);
            force timeout_dut.exp_rsp_valid = 1'b1;
            force timeout_dut.exp_rsp_result = 32'h3ebc5ab2;
            force timeout_dut.exp_rsp_flags = FLAGS_NX;
            force timeout_dut.exp_rsp_error = 1'b0;
            force timeout_dut.exp_rsp_error_code = 4'd0;
            #1;
            if (timeout_dut.exp_rsp_ready !== 1'b0) begin
                fail_case("deadline normal response retained child credit");
            end
            @(posedge clk_i);
            @(negedge clk_i);
            release timeout_dut.exp_rsp_valid;
            release timeout_dut.exp_rsp_result;
            release timeout_dut.exp_rsp_flags;
            release timeout_dut.exp_rsp_error;
            release timeout_dut.exp_rsp_error_code;
            check_timeout_response("timeout-normal-response-collision", 4'd3,
                                   5'b00001, 32'd6);
        end
    endtask

    task automatic check_timeout_fatal_priority;
        begin
            start_timeout_request("deadline-child-fatal-priority");
            wait_timeout_state_watchdog(ST_EXP_WAIT, 32'd4);
            force timeout_dut.exp_rsp_valid = 1'b1;
            force timeout_dut.exp_rsp_result = 32'h7fc00000;
            force timeout_dut.exp_rsp_flags = 5'b10000;
            force timeout_dut.exp_rsp_error = 1'b1;
            force timeout_dut.exp_rsp_error_code = 4'd2;
            #1;
            if (timeout_dut.exp_rsp_ready !== 1'b0) begin
                fail_case("fatal deadline response retained normal response credit");
            end
            @(posedge clk_i);
            @(negedge clk_i);
            release timeout_dut.exp_rsp_valid;
            release timeout_dut.exp_rsp_result;
            release timeout_dut.exp_rsp_flags;
            release timeout_dut.exp_rsp_error;
            release timeout_dut.exp_rsp_error_code;
            check_timeout_response("deadline-child-fatal-priority", 4'd2,
                                   5'b00001, 32'd6);
        end
    endtask

    initial begin
        integer opcode_index;
        integer nonfinite_index;

        cycle_count = 0;
        completed_transactions = 0;
        expected_count = 0;
        launched_count = 0;
        returned_count = 0;
        scoreboard_outstanding = 0;
        scoreboard_owner = 0;
        expected_check_enable = 1'b0;
        current_case = "startup";

        rst_i = 1'b1;
        req_valid_i = 1'b0;
        opcode_i = 3'b0;
        src0_bits_i = 32'b0;
        src1_bits_i = 32'b0;
        rsp_ready_i = 1'b0;

        timeout_req_valid_i = 1'b0;
        timeout_opcode_i = 3'b0;
        timeout_src0_bits_i = 32'b0;
        timeout_src1_bits_i = 32'b0;
        timeout_rsp_ready_i = 1'b0;

        nonfinite_raw[0] = 32'h7f800000;
        nonfinite_raw[1] = 32'hff800000;
        nonfinite_raw[2] = 32'h7fc12345;
        nonfinite_raw[3] = 32'h7f800001;

        repeat (4) @(posedge clk_i);
        @(negedge clk_i);
        if ((req_ready_o !== 1'b0) || (rsp_valid_o !== 1'b0) ||
            (timeout_req_ready_o !== 1'b0) || (timeout_rsp_valid_o !== 1'b0)) begin
            fail_case("startup reset exposed protocol credit");
        end
        rst_i = 1'b0;
        repeat (3) @(posedge clk_i);
        @(negedge clk_i);
        if ((req_ready_o !== 1'b1) || (timeout_req_ready_o !== 1'b1) ||
            (rsp_valid_o !== 1'b0) || (timeout_rsp_valid_o !== 1'b0)) begin
            fail_case("reset deassert did not create clean IDLE");
        end

        // Frozen JSONL: ordinary +/-1 across all four DAGs.
        begin_expectations("sigmoid-ordinary-positive");
        expect_sigmoid(32'h3f800000, 32'h3ebc5ab2, FLAGS_NX,
                       32'h3faf16ac, FLAGS_NX, 32'h3f3b26a8, FLAGS_NX);
        run_transaction("sigmoid-ordinary-positive", 3'd0,
                        32'h3f800000, 32'h7fc12345,
                        32'h3f3b26a8, FLAGS_NX, 1'b0, 4'd0, 5'b00111,
                        CYCLES_SIG_SILU_EXP_NORMAL, 300, 1);

        begin_expectations("sigmoid-ordinary-negative");
        expect_sigmoid(32'hbf800000, 32'h402df854, FLAGS_NX,
                       32'h406df854, FLAGS_NONE, 32'h3e89b2b1, FLAGS_NX);
        run_transaction("sigmoid-ordinary-negative", 3'd0,
                        32'hbf800000, 32'hff800000,
                        32'h3e89b2b1, FLAGS_NX, 1'b0, 4'd0, 5'b00111,
                        CYCLES_SIG_SILU_EXP_NORMAL, 0, 0);

        begin_expectations("softplus-ordinary-positive");
        expect_softplus(32'h3f800000, 32'h402df854, FLAGS_NX,
                        32'h406df854, FLAGS_NONE, 32'h3fa818f5, FLAGS_NX);
        run_transaction("softplus-ordinary-positive", 3'd1,
                        32'h3f800000, 32'h7fc12345,
                        32'h3fa818f5, FLAGS_NX, 1'b0, 4'd0, 5'b01011,
                        CYCLES_SOFTPLUS_NORMAL, 0, 0);

        begin_expectations("softplus-ordinary-negative");
        expect_softplus(32'hbf800000, 32'h3ebc5ab2, FLAGS_NX,
                        32'h3faf16ac, FLAGS_NX, 32'h3ea063d5, FLAGS_NX);
        run_transaction("softplus-ordinary-negative", 3'd1,
                        32'hbf800000, 32'h7f800000,
                        32'h3ea063d5, FLAGS_NX, 1'b0, 4'd0, 5'b01011,
                        CYCLES_SOFTPLUS_NORMAL, 0, 0);

        begin_expectations("silu-ordinary-positive");
        expect_silu(32'h3f800000, 32'h3ebc5ab2, FLAGS_NX,
                    32'h3faf16ac, FLAGS_NX, 32'h3f3b26a8, FLAGS_NX);
        run_transaction("silu-ordinary-positive", 3'd2,
                        32'h3f800000, 32'h7fc12345,
                        32'h3f3b26a8, FLAGS_NX, 1'b0, 4'd0, 5'b00111,
                        CYCLES_SIG_SILU_EXP_NORMAL, 0, 0);

        begin_expectations("silu-ordinary-negative");
        expect_silu(32'hbf800000, 32'h402df854, FLAGS_NX,
                    32'h406df854, FLAGS_NONE, 32'hbe89b2b1, FLAGS_NX);
        run_transaction("silu-ordinary-negative", 3'd2,
                        32'hbf800000, 32'h7fc12345,
                        32'hbe89b2b1, FLAGS_NX, 1'b0, 4'd0, 5'b00111,
                        CYCLES_SIG_SILU_EXP_NORMAL, 0, 0);

        begin_expectations("swiglu-ordinary-positive-role-a");
        expect_swiglu(32'h3f800000, 32'h40000000,
                      32'h3ebc5ab2, FLAGS_NX,
                      32'h3faf16ac, FLAGS_NX,
                      32'h3f3b26a8, FLAGS_NX,
                      32'h3fbb26a8, FLAGS_NONE);
        run_transaction("swiglu-ordinary-positive-role-a", 3'd3,
                        32'h3f800000, 32'h40000000,
                        32'h3fbb26a8, FLAGS_NX, 1'b0, 4'd0, 5'b10111,
                        CYCLES_SWIGLU_EXP_NORMAL, 0, 0);

        begin_expectations("swiglu-ordinary-negative");
        expect_swiglu(32'hbf800000, 32'h40000000,
                      32'h402df854, FLAGS_NX,
                      32'h406df854, FLAGS_NONE,
                      32'hbe89b2b1, FLAGS_NX,
                      32'hbf09b2b1, FLAGS_NONE);
        run_transaction("swiglu-ordinary-negative", 3'd3,
                        32'hbf800000, 32'h40000000,
                        32'hbf09b2b1, FLAGS_NX, 1'b0, 4'd0, 5'b10111,
                        CYCLES_SWIGLU_EXP_NORMAL, 0, 0);

        // Public opcode 4 is the manifest UNARY/EXP operation.  It retires
        // exactly the one real AOR EXP child and preserves response hold
        // backpressure/cardinality like every pre-existing opcode.
        begin_expectations("exp-ordinary-positive");
        expect_exp(32'h3f800000, 32'h402df854, FLAGS_NX);
        run_transaction("exp-ordinary-positive", 3'd4,
                        32'h3f800000, 32'h7fc12345,
                        32'h402df854, FLAGS_NX, 1'b0, 4'd0, 5'b00001,
                        CYCLES_EXP_NORMAL, 300, 1);

        begin_expectations("exp-ordinary-negative");
        expect_exp(32'hbf800000, 32'h3ebc5ab2, FLAGS_NX);
        run_transaction("exp-ordinary-negative", 3'd4,
                        32'hbf800000, 32'hff800000,
                        32'h3ebc5ab2, FLAGS_NX, 1'b0, 4'd0, 5'b00001,
                        CYCLES_EXP_NORMAL, 0, 0);

        // signed zero、internal Inf continuation。
        begin_expectations("sigmoid-positive-zero");
        expect_sigmoid(32'h00000000, 32'h3f800000, FLAGS_NONE,
                       32'h40000000, FLAGS_NONE, 32'h3f000000, FLAGS_NONE);
        run_transaction("sigmoid-positive-zero", 3'd0,
                        32'h00000000, 32'h7fc12345,
                        32'h3f000000, FLAGS_NONE, 1'b0, 4'd0, 5'b00111,
                        CYCLES_SIG_SILU_EXP_SPECIAL, 0, 0);

        begin_expectations("silu-positive-zero");
        expect_silu(32'h00000000, 32'h3f800000, FLAGS_NONE,
                    32'h40000000, FLAGS_NONE, 32'h00000000, FLAGS_NONE);
        run_transaction("silu-positive-zero", 3'd2,
                        32'h00000000, 32'h7fc12345,
                        32'h00000000, FLAGS_NONE, 1'b0, 4'd0, 5'b00111,
                        CYCLES_SIG_SILU_EXP_SPECIAL, 0, 0);

        begin_expectations("silu-negative-zero");
        expect_silu(32'h80000000, 32'h3f800000, FLAGS_NONE,
                    32'h40000000, FLAGS_NONE, 32'h80000000, FLAGS_NONE);
        run_transaction("silu-negative-zero", 3'd2,
                        32'h80000000, 32'h7fc12345,
                        32'h80000000, FLAGS_NONE, 1'b0, 4'd0, 5'b00111,
                        CYCLES_SIG_SILU_EXP_SPECIAL, 0, 0);

        begin_expectations("softplus-positive-zero");
        expect_softplus(32'h00000000, 32'h3f800000, FLAGS_NONE,
                        32'h40000000, FLAGS_NONE, 32'h3f317218, FLAGS_NX);
        run_transaction("softplus-positive-zero", 3'd1,
                        32'h00000000, 32'h7fc12345,
                        32'h3f317218, FLAGS_NX, 1'b0, 4'd0, 5'b01011,
                        CYCLES_SOFTPLUS_EXP_SPECIAL, 0, 0);

        begin_expectations("exp-positive-zero");
        expect_exp(32'h00000000, 32'h3f800000, FLAGS_NONE);
        run_transaction("exp-positive-zero", 3'd4,
                        32'h00000000, 32'h7fc12345,
                        32'h3f800000, FLAGS_NONE, 1'b0, 4'd0, 5'b00001,
                        CYCLES_EXP_SPECIAL, 0, 0);

        begin_expectations("exp-finite-overflow");
        expect_exp(32'h42c80000, 32'h7f800000, FLAGS_OF_NX);
        run_transaction("exp-finite-overflow", 3'd4,
                        32'h42c80000, 32'h7fc12345,
                        32'h7f800000, FLAGS_OF_NX, 1'b0, 4'd0, 5'b00001,
                        CYCLES_EXP_SPECIAL, 0, 0);

        begin_expectations("exp-finite-underflow");
        expect_exp(32'hff7fffff, 32'h00000000, FLAGS_UF_NX);
        run_transaction("exp-finite-underflow", 3'd4,
                        32'hff7fffff, 32'h7fc12345,
                        32'h00000000, FLAGS_UF_NX, 1'b0, 4'd0, 5'b00001,
                        CYCLES_EXP_SPECIAL, 0, 0);

        begin_expectations("swiglu-zero-negative-gate");
        expect_swiglu(32'h00000000, 32'hbf800000,
                      32'h3f800000, FLAGS_NONE,
                      32'h40000000, FLAGS_NONE,
                      32'h00000000, FLAGS_NONE,
                      32'h80000000, FLAGS_NONE);
        run_transaction("swiglu-zero-negative-gate", 3'd3,
                        32'h00000000, 32'hbf800000,
                        32'h80000000, FLAGS_NONE, 1'b0, 4'd0, 5'b10111,
                        CYCLES_SWIGLU_EXP_SPECIAL, 0, 0);

        begin_expectations("sigmoid-negative-100-internal-inf");
        expect_sigmoid(32'hc2c80000, 32'h7f800000, FLAGS_OF_NX,
                       32'h7f800000, FLAGS_NONE, 32'h00000000, FLAGS_NONE);
        run_transaction("sigmoid-negative-100-internal-inf", 3'd0,
                        32'hc2c80000, 32'h7fc12345,
                        32'h00000000, FLAGS_OF_NX, 1'b0, 4'd0, 5'b00111,
                        CYCLES_SIG_SILU_EXP_SPECIAL, 0, 0);

        begin_expectations("silu-negative-100-internal-inf");
        expect_silu(32'hc2c80000, 32'h7f800000, FLAGS_OF_NX,
                    32'h7f800000, FLAGS_NONE, 32'h80000000, FLAGS_NONE);
        run_transaction("silu-negative-100-internal-inf", 3'd2,
                        32'hc2c80000, 32'h7fc12345,
                        32'h80000000, FLAGS_OF_NX, 1'b0, 4'd0, 5'b00111,
                        CYCLES_SIG_SILU_EXP_SPECIAL, 0, 0);

        // SOFTPLUS strict >20 threshold: equality is slow, successor is raw bypass。
        begin_expectations("softplus-below-twenty");
        expect_softplus(32'h419fffff, 32'h4de75827, FLAGS_NX,
                        32'h4de75827, FLAGS_NX, 32'h419fffff, FLAGS_NX);
        run_transaction("softplus-below-twenty", 3'd1,
                        32'h419fffff, 32'h7fc12345,
                        32'h419fffff, FLAGS_NX, 1'b0, 4'd0, 5'b01011,
                        CYCLES_SOFTPLUS_NORMAL, 0, 0);

        begin_expectations("softplus-equal-twenty");
        expect_softplus(32'h41a00000, 32'h4de75844, FLAGS_NX,
                        32'h4de75844, FLAGS_NX, 32'h41a00000, FLAGS_NX);
        run_transaction("softplus-equal-twenty", 3'd1,
                        32'h41a00000, 32'h7fc12345,
                        32'h41a00000, FLAGS_NX, 1'b0, 4'd0, 5'b01011,
                        CYCLES_SOFTPLUS_NORMAL, 0, 0);

        begin_expectations("softplus-above-twenty-bypass");
        run_transaction("softplus-above-twenty-bypass", 3'd1,
                        32'h41a00001, 32'h7fc12345,
                        32'h41a00001, FLAGS_NONE, 1'b0, 4'd0, 5'b00000,
                        CYCLES_BYPASS, 5, 0);

        // 三项 bounded mutation first witness均逐child operand/materialized raw检查。
        begin_expectations("mutation-silu-reciprocal-mul-first-witness");
        expect_silu(32'h3a7ff807, 32'h3f7fc00a, FLAGS_NX,
                    32'h3fffe005, FLAGS_NONE, 32'h3a000c03, FLAGS_NX);
        run_transaction("mutation-silu-reciprocal-mul-first-witness", 3'd2,
                        32'h3a7ff807, 32'h7fc12345,
                        32'h3a000c03, FLAGS_NX, 1'b0, 4'd0, 5'b00111,
                        CYCLES_SIG_SILU_EXP_NORMAL, 0, 0);

        begin_expectations("mutation-swiglu-numerator-first-witness");
        expect_swiglu(32'h00000001, 32'h40000000,
                      32'h3f800000, FLAGS_NX,
                      32'h40000000, FLAGS_NONE,
                      32'h00000000, FLAGS_UF_NX,
                      32'h00000000, FLAGS_NONE);
        run_transaction("mutation-swiglu-numerator-first-witness", 3'd3,
                        32'h00000001, 32'h40000000,
                        32'h00000000, FLAGS_UF_NX, 1'b0, 4'd0, 5'b10111,
                        CYCLES_SWIGLU_EXP_NORMAL, 0, 0);

        begin_expectations("mutation-swiglu-role-swap-witness-b");
        expect_swiglu(32'h40000000, 32'h3f800000,
                      32'h3e0a9555, FLAGS_NX,
                      32'h3f9152ab, FLAGS_NX,
                      32'h3fe17bea, FLAGS_NX,
                      32'h3fe17bea, FLAGS_NONE);
        run_transaction("mutation-swiglu-role-swap-witness-b", 3'd3,
                        32'h40000000, 32'h3f800000,
                        32'h3fe17bea, FLAGS_NX, 1'b0, 4'd0, 5'b10111,
                        CYCLES_SWIGLU_EXP_NORMAL, 0, 0);

        // minsub与source-role signed zero/finite overflow Inf。
        begin_expectations("silu-positive-minsub");
        expect_silu(32'h00000001, 32'h3f800000, FLAGS_NX,
                    32'h40000000, FLAGS_NONE, 32'h00000000, FLAGS_UF_NX);
        run_transaction("silu-positive-minsub", 3'd2,
                        32'h00000001, 32'h7fc12345,
                        32'h00000000, FLAGS_UF_NX, 1'b0, 4'd0, 5'b00111,
                        CYCLES_SIG_SILU_EXP_NORMAL, 0, 0);

        begin_expectations("silu-negative-minsub");
        expect_silu(32'h80000001, 32'h3f800000, FLAGS_NX,
                    32'h40000000, FLAGS_NONE, 32'h80000000, FLAGS_UF_NX);
        run_transaction("silu-negative-minsub", 3'd2,
                        32'h80000001, 32'h7fc12345,
                        32'h80000000, FLAGS_UF_NX, 1'b0, 4'd0, 5'b00111,
                        CYCLES_SIG_SILU_EXP_NORMAL, 0, 0);

        begin_expectations("swiglu-positive-minsub-src1");
        expect_swiglu(32'h3f800000, 32'h00000001,
                      32'h3ebc5ab2, FLAGS_NX,
                      32'h3faf16ac, FLAGS_NX,
                      32'h3f3b26a8, FLAGS_NX,
                      32'h00000001, FLAGS_UF_NX);
        run_transaction("swiglu-positive-minsub-src1", 3'd3,
                        32'h3f800000, 32'h00000001,
                        32'h00000001, FLAGS_UF_NX, 1'b0, 4'd0, 5'b10111,
                        CYCLES_SWIGLU_EXP_NORMAL, 0, 0);

        begin_expectations("swiglu-finite-overflow-positive");
        expect_swiglu(32'h7f7fffff, 32'h40000000,
                      32'h00000000, FLAGS_UF_NX,
                      32'h3f800000, FLAGS_NONE,
                      32'h7f7fffff, FLAGS_NONE,
                      32'h7f800000, FLAGS_OF_NX);
        run_transaction("swiglu-finite-overflow-positive", 3'd3,
                        32'h7f7fffff, 32'h40000000,
                        32'h7f800000, FLAGS_OF_UF_NX, 1'b0, 4'd0, 5'b10111,
                        CYCLES_SWIGLU_EXP_SPECIAL, 0, 0);

        begin_expectations("swiglu-finite-overflow-negative");
        expect_swiglu(32'h7f7fffff, 32'hc0000000,
                      32'h00000000, FLAGS_UF_NX,
                      32'h3f800000, FLAGS_NONE,
                      32'h7f7fffff, FLAGS_NONE,
                      32'hff800000, FLAGS_OF_NX);
        run_transaction("swiglu-finite-overflow-negative", 3'd3,
                        32'h7f7fffff, 32'hc0000000,
                        32'hff800000, FLAGS_OF_UF_NX, 1'b0, 4'd0, 5'b10111,
                        CYCLES_SWIGLU_EXP_SPECIAL, 0, 0);

        // 每个opcode consumed src0的 +/-Inf/qNaN/sNaN；SWIGLU独立src1 nonfinite。
        for (opcode_index = 0; opcode_index < 5; opcode_index = opcode_index + 1) begin
            for (nonfinite_index = 0; nonfinite_index < 4;
                 nonfinite_index = nonfinite_index + 1) begin
                begin_expectations($sformatf("reject-op%0d-src0-nonfinite-%0d",
                                             opcode_index, nonfinite_index));
                run_transaction($sformatf("reject-op%0d-src0-nonfinite-%0d",
                                          opcode_index, nonfinite_index),
                                opcode_index[2:0], nonfinite_raw[nonfinite_index],
                                (opcode_index == 3) ? 32'h3f800000 : 32'h7fc12345,
                                32'b0, FLAGS_NONE, 1'b1, 4'd1, 5'b00000,
                                CYCLES_REJECT, 0, 0);
            end
        end
        for (nonfinite_index = 0; nonfinite_index < 4;
             nonfinite_index = nonfinite_index + 1) begin
            begin_expectations($sformatf("reject-swiglu-src1-nonfinite-%0d",
                                         nonfinite_index));
            run_transaction($sformatf("reject-swiglu-src1-nonfinite-%0d",
                                      nonfinite_index),
                            3'd3, 32'h3f800000, nonfinite_raw[nonfinite_index],
                            32'b0, FLAGS_NONE, 1'b1, 4'd1, 5'b00000,
                            CYCLES_REJECT, 0, 0);
        end

        // 完整3-bit unsupported decode 5..7。
        for (opcode_index = 5; opcode_index < 8; opcode_index = opcode_index + 1) begin
            begin_expectations($sformatf("unsupported-opcode-%0d", opcode_index));
            run_transaction($sformatf("unsupported-opcode-%0d", opcode_index),
                            opcode_index[2:0], 32'h3f800000, 32'h40000000,
                            32'b0, FLAGS_NONE, 1'b1, 4'd1, 5'b00000,
                            CYCLES_REJECT, 0, 0);
        end

        // 五个WAIT与HOLD reset cancellation，逐项证明无stale且可clean recovery。
        reset_in_state("reset-exp-wait", ST_EXP_WAIT, 3'd0,
                       32'h3f800000, 32'b0);
        reset_in_state("reset-add-wait", ST_ADD_WAIT, 3'd0,
                       32'h3f800000, 32'b0);
        reset_in_state("reset-div-wait", ST_DIV_WAIT, 3'd0,
                       32'h3f800000, 32'b0);
        reset_in_state("reset-log-wait", ST_LOG_WAIT, 3'd1,
                       32'h3f800000, 32'b0);
        reset_in_state("reset-mul-wait", ST_MUL_WAIT, 3'd3,
                       32'h3f800000, 32'h40000000);
        reset_in_state("reset-hold", ST_HOLD_RESPONSE, 3'd1,
                       32'h41a00001, 32'h7fc12345);

        // child/profile/protocol faults与无全局reset recovery。
        check_explicit_child_error();
        check_add_nan_child_error();
        check_div_dz_child_error();
        check_wrong_owner();
        check_literal_illegal_state("illegal-state-literal-14", 4'd14);
        check_literal_illegal_state("illegal-state-literal-15", 4'd15);
        check_idle_ghost();

        // small watchdog：deadline REQ gate、normal response timeout、fatal优先。
        check_timeout_req_gate();
        check_timeout_normal_response_collision();
        check_timeout_fatal_priority();

        if (scoreboard_outstanding != 0) begin
            fail_case("final owner scoreboard was nonzero");
        end
        if (completed_transactions < 65) begin
            fail_case($sformatf("completed_transactions=%0d expected_at_least=65",
                                completed_transactions));
        end

        $display("[NPU-UNARY-GLU-ELEMENT][PASS]");
        $finish;
    end

endmodule
