`timescale 1ns/1ps
`default_nettype none

// Directed raw-bit verification for TensorNpuF32AluSimdCore.
// A separate public TensorNpuFp32AddMul instance is the sole numerical oracle.
// The testbench only selects operands and compares raw result/flag fields.
module tb_f32_alu_simd_core;

    localparam integer ELEMENTS = 13;
    localparam logic [31:0] SCALE_BITS = 32'h3f000000;

    localparam logic [2:0] OP_ADD   = 3'd0;
    localparam logic [2:0] OP_MUL   = 3'd1;
    localparam logic [2:0] OP_SUB   = 3'd2;
    localparam logic [2:0] OP_SCALE = 3'd3;

    localparam logic [7:0] ERROR_INVALID_OPCODE = 8'h10;
    localparam logic [7:0] ERROR_INVALID_COUNT  = 8'h11;
    localparam logic [7:0] ERROR_BASE_INDEX     = 8'h12;
    localparam logic [7:0] ERROR_MASK           = 8'h13;

    logic clk_i;
    logic rst_i;

    logic        start_1;
    wire         ready_1;
    wire         busy_1;
    logic [2:0]  opcode_1;
    logic [63:0] element_count_1;
    logic [31:0] scale_bits_1;
    logic        input_valid_1;
    wire         input_ready_1;
    logic [31:0] lhs_bits_1;
    logic [31:0] rhs_bits_1;
    logic [0:0]  mask_1;
    logic [63:0] base_1;
    wire         result_valid_1;
    logic        result_ready_1;
    wire [31:0]  result_bits_1;
    wire [0:0]   result_mask_1;
    wire [63:0]  result_base_1;
    wire         done_1;
    wire         error_1;
    wire [7:0]   error_code_1;
    wire [63:0]  error_index_1;
    wire [4:0]   flags_or_1;
    wire [63:0]  input_batches_1;
    wire [63:0]  child_requests_1;
    wire [63:0]  child_responses_1;
    wire [63:0]  elements_emitted_1;
    wire [63:0]  active_cycles_1;

    logic        start_8;
    wire         ready_8;
    wire         busy_8;
    logic [2:0]  opcode_8;
    logic [63:0] element_count_8;
    logic [31:0] scale_bits_8;
    logic        input_valid_8;
    wire         input_ready_8;
    logic [255:0] lhs_bits_8;
    logic [255:0] rhs_bits_8;
    logic [7:0]   mask_8;
    logic [63:0]  base_8;
    wire          result_valid_8;
    logic         result_ready_8;
    wire [255:0]  result_bits_8;
    wire [7:0]    result_mask_8;
    wire [63:0]   result_base_8;
    wire          done_8;
    wire          error_8;
    wire [7:0]    error_code_8;
    wire [63:0]   error_index_8;
    wire [4:0]    flags_or_8;
    wire [63:0]   input_batches_8;
    wire [63:0]   child_requests_8;
    wire [63:0]   child_responses_8;
    wire [63:0]   elements_emitted_8;
    wire [63:0]   active_cycles_8;

    logic        oracle_req_valid;
    wire         oracle_req_ready;
    logic        oracle_op_mul;
    logic [31:0] oracle_lhs_bits;
    logic [31:0] oracle_rhs_bits;
    wire         oracle_rsp_valid;
    logic        oracle_rsp_ready;
    wire [31:0]  oracle_result_bits;
    wire [4:0]   oracle_flags;

    logic [31:0] expected_result [0:3][0:ELEMENTS-1];
    logic [4:0]  expected_flags  [0:3][0:ELEMENTS-1];
    logic [4:0]  expected_flags_or [0:3];

    integer cycle_count;
    integer opcode_index;
    integer element_index;
    integer input_hold_count;
    integer result_hold_count;
    integer serial_response_observed;
    logic [63:0] previous_child_responses_8;

    TensorNpuF32AluSimdCore #(
        .LANES(1)
    ) dut_lane1 (
        .clk_i                  (clk_i),
        .rst_i                  (rst_i),
        .start_i                (start_1),
        .ready_o                (ready_1),
        .busy_o                 (busy_1),
        .opcode_i               (opcode_1),
        .element_count_i        (element_count_1),
        .scale_bits_i           (scale_bits_1),
        .input_batch_valid_i    (input_valid_1),
        .input_batch_ready_o    (input_ready_1),
        .lhs_bits_i             (lhs_bits_1),
        .rhs_bits_i             (rhs_bits_1),
        .mask_i                 (mask_1),
        .base_index_i           (base_1),
        .result_batch_valid_o   (result_valid_1),
        .result_batch_ready_i   (result_ready_1),
        .result_bits_o          (result_bits_1),
        .result_mask_o          (result_mask_1),
        .result_base_index_o    (result_base_1),
        .done_o                 (done_1),
        .error_o                (error_1),
        .error_code_o           (error_code_1),
        .error_index_o          (error_index_1),
        .flags_or_o             (flags_or_1),
        .input_batches_o        (input_batches_1),
        .child_requests_o       (child_requests_1),
        .child_responses_o      (child_responses_1),
        .elements_emitted_o     (elements_emitted_1),
        .active_cycles_o        (active_cycles_1)
    );

    TensorNpuF32AluSimdCore #(
        .LANES(8)
    ) dut_lane8 (
        .clk_i                  (clk_i),
        .rst_i                  (rst_i),
        .start_i                (start_8),
        .ready_o                (ready_8),
        .busy_o                 (busy_8),
        .opcode_i               (opcode_8),
        .element_count_i        (element_count_8),
        .scale_bits_i           (scale_bits_8),
        .input_batch_valid_i    (input_valid_8),
        .input_batch_ready_o    (input_ready_8),
        .lhs_bits_i             (lhs_bits_8),
        .rhs_bits_i             (rhs_bits_8),
        .mask_i                 (mask_8),
        .base_index_i           (base_8),
        .result_batch_valid_o   (result_valid_8),
        .result_batch_ready_i   (result_ready_8),
        .result_bits_o          (result_bits_8),
        .result_mask_o          (result_mask_8),
        .result_base_index_o    (result_base_8),
        .done_o                 (done_8),
        .error_o                (error_8),
        .error_code_o           (error_code_8),
        .error_index_o          (error_index_8),
        .flags_or_o             (flags_or_8),
        .input_batches_o        (input_batches_8),
        .child_requests_o       (child_requests_8),
        .child_responses_o      (child_responses_8),
        .elements_emitted_o     (elements_emitted_8),
        .active_cycles_o        (active_cycles_8)
    );

    TensorNpuFp32AddMul u_oracle_addmul (
        .clk_i         (clk_i),
        .rst_i         (rst_i),
        .req_valid_i   (oracle_req_valid),
        .req_ready_o   (oracle_req_ready),
        .op_mul_i      (oracle_op_mul),
        .lhs_bits_i    (oracle_lhs_bits),
        .rhs_bits_i    (oracle_rhs_bits),
        .rsp_valid_o   (oracle_rsp_valid),
        .rsp_ready_i   (oracle_rsp_ready),
        .result_bits_o (oracle_result_bits),
        .flags_o       (oracle_flags)
    );

    initial clk_i = 1'b0;
    always #5 clk_i <= ~clk_i;

    always @(posedge clk_i) begin
        cycle_count <= cycle_count + 1;
        if (cycle_count >= 120000) begin
            $display("[NPU-F32-ALU-SIMD][FAIL] global timeout cycle=%0d",
                     cycle_count + 1);
            $fatal(1);
        end
        if (!rst_i) begin
            if (done_1 && error_1) begin
                $fatal(1, "LANES=1 DONE/ERROR overlap");
            end
            if (done_8 && error_8) begin
                $fatal(1, "LANES=8 DONE/ERROR overlap");
            end
        end
    end

    // Public response count reveals that the production core accepts at most
    // one child response per cycle, forcing all other valid children to hold.
    always @(negedge clk_i) begin
        if (rst_i) begin
            previous_child_responses_8 <= 64'b0;
        end else begin
            if (child_responses_8 > previous_child_responses_8) begin
                if (child_responses_8
                    != (previous_child_responses_8 + 64'd1)) begin
                    $fatal(1, "LANES=8 accepted multiple child responses");
                end
                if (child_requests_8 > child_responses_8) begin
                    serial_response_observed <= 1;
                end
            end
            previous_child_responses_8 <= child_responses_8;
        end
    end

    function automatic [31:0] raw_lhs(input integer index);
        begin
            case (index)
                0:  raw_lhs = 32'h00000000;
                1:  raw_lhs = 32'h80000000;
                2:  raw_lhs = 32'h00000001;
                3:  raw_lhs = 32'h807fffff;
                4:  raw_lhs = 32'h3f800000;
                5:  raw_lhs = 32'hc0200000;
                6:  raw_lhs = 32'h7f800000;
                7:  raw_lhs = 32'hff800000;
                8:  raw_lhs = 32'h7fc12345;
                9:  raw_lhs = 32'h7fa12345;
                10: raw_lhs = 32'h7f7fffff;
                11: raw_lhs = 32'h00800000;
                default: raw_lhs = 32'h40400000;
            endcase
        end
    endfunction

    function automatic [31:0] raw_rhs(input integer index);
        begin
            case (index)
                0:  raw_rhs = 32'h80000000;
                1:  raw_rhs = 32'h00000000;
                2:  raw_rhs = 32'h00000002;
                3:  raw_rhs = 32'h40000000;
                4:  raw_rhs = 32'hbf800000;
                5:  raw_rhs = 32'h7f800000;
                6:  raw_rhs = 32'h00000000;
                7:  raw_rhs = 32'hff800000;
                8:  raw_rhs = 32'h3f800000;
                9:  raw_rhs = 32'h7fc54321;
                10: raw_rhs = 32'h40000000;
                11: raw_rhs = 32'h00000001;
                default: raw_rhs = 32'hc0400000;
            endcase
        end
    endfunction

    function automatic [255:0] make_lhs_group8(input integer base_index);
        reg [255:0] value;
        integer lane;
        integer source_index;
        begin
            value = 256'b0;
            for (lane = 0; lane < 8; lane = lane + 1) begin
                source_index = (base_index + lane) % ELEMENTS;
                value[(lane*32) +: 32] = raw_lhs(source_index);
            end
            make_lhs_group8 = value;
        end
    endfunction

    function automatic [255:0] make_rhs_group8(input integer base_index);
        reg [255:0] value;
        integer lane;
        integer source_index;
        begin
            value = 256'b0;
            for (lane = 0; lane < 8; lane = lane + 1) begin
                source_index = (base_index + lane) % ELEMENTS;
                value[(lane*32) +: 32] = raw_rhs(source_index);
            end
            make_rhs_group8 = value;
        end
    endfunction

    function automatic [31:0] oracle_selected_rhs(
        input integer op,
        input integer index
    );
        reg [31:0] rhs;
        begin
            rhs = raw_rhs(index);
            if (op == OP_SUB) begin
                oracle_selected_rhs = {~rhs[31], rhs[30:0]};
            end else if (op == OP_SCALE) begin
                oracle_selected_rhs = SCALE_BITS;
            end else begin
                oracle_selected_rhs = rhs;
            end
        end
    endfunction

    task automatic step_cycle;
        begin
            @(posedge clk_i);
            #1;
        end
    endtask

    task automatic build_one_oracle(
        input integer op,
        input integer index
    );
        integer guard;
        integer hold_index;
        reg [31:0] held_result;
        reg [4:0]  held_flags;
        begin
            guard = 0;
            while (oracle_req_ready !== 1'b1) begin
                step_cycle();
                guard = guard + 1;
                if (guard > 1000) begin
                    $fatal(1, "oracle request timeout");
                end
            end
            oracle_op_mul   = (op == OP_MUL) || (op == OP_SCALE);
            oracle_lhs_bits = raw_lhs(index);
            oracle_rhs_bits = oracle_selected_rhs(op, index);
            oracle_rsp_ready = 1'b0;
            @(negedge clk_i);
            oracle_req_valid = 1'b1;
            step_cycle();
            oracle_req_valid = 1'b0;

            guard = 0;
            while (oracle_rsp_valid !== 1'b1) begin
                step_cycle();
                guard = guard + 1;
                if (guard > 1000) begin
                    $fatal(1, "oracle response timeout");
                end
            end
            held_result = oracle_result_bits;
            held_flags  = oracle_flags;
            for (hold_index = 0; hold_index < ((op + index) % 3) + 1;
                 hold_index = hold_index + 1) begin
                step_cycle();
                if (!oracle_rsp_valid
                    || (oracle_result_bits !== held_result)
                    || (oracle_flags !== held_flags)) begin
                    $fatal(1, "oracle child response hold mismatch");
                end
            end
            expected_result[op][index] = held_result;
            expected_flags[op][index]  = held_flags;
            expected_flags_or[op] = expected_flags_or[op] | held_flags;

            @(negedge clk_i);
            oracle_rsp_ready = 1'b1;
            step_cycle();
            oracle_rsp_ready = 1'b0;
            if (oracle_rsp_valid) begin
                $fatal(1, "oracle response did not consume");
            end
        end
    endtask

    task automatic build_oracle_table;
        integer op;
        integer index;
        begin
            for (op = 0; op < 4; op = op + 1) begin
                expected_flags_or[op] = 5'b0;
                for (index = 0; index < ELEMENTS; index = index + 1) begin
                    build_one_oracle(op, index);
                end
            end
        end
    endtask

    task automatic wait_both_idle;
        integer guard;
        begin
            guard = 0;
            while ((ready_1 !== 1'b1) || (ready_8 !== 1'b1)) begin
                step_cycle();
                guard = guard + 1;
                if (guard > 3000) begin
                    $fatal(1, "timeout waiting for both SIMD cores IDLE");
                end
            end
        end
    endtask

    task automatic launch_both(input integer op);
        begin
            wait_both_idle();
            opcode_1       = op[2:0];
            element_count_1 = ELEMENTS;
            scale_bits_1   = SCALE_BITS;
            opcode_8       = op[2:0];
            element_count_8 = ELEMENTS;
            scale_bits_8   = SCALE_BITS;
            @(negedge clk_i);
            start_1 = 1'b1;
            start_8 = 1'b1;
            step_cycle();
            start_1 = 1'b0;
            start_8 = 1'b0;
            if (!busy_1 || !busy_8 || ready_1 || ready_8
                || result_valid_1 || result_valid_8) begin
                $fatal(1, "command launch protocol mismatch op=%0d", op);
            end

            // Busy start must not mutate opcode/count/scale resident state.
            opcode_1 = 3'd7;
            opcode_8 = 3'd7;
            element_count_1 = 64'b0;
            element_count_8 = 64'b0;
            scale_bits_1 = 32'h7fc00000;
            scale_bits_8 = 32'h7fc00000;
            @(negedge clk_i);
            start_1 = 1'b1;
            start_8 = 1'b1;
            step_cycle();
            start_1 = 1'b0;
            start_8 = 1'b0;
            opcode_1 = op[2:0];
            opcode_8 = op[2:0];
            element_count_1 = ELEMENTS;
            element_count_8 = ELEMENTS;
            scale_bits_1 = SCALE_BITS;
            scale_bits_8 = SCALE_BITS;
            if (!busy_1 || !busy_8 || error_1 || error_8
                || (input_batches_1 != 0) || (input_batches_8 != 0)) begin
                $fatal(1, "busy start changed resident command");
            end
        end
    endtask

    task automatic send_input_lane1(
        input integer index,
        input integer hold_cycles
    );
        integer guard;
        integer hold_index;
        reg [31:0] held_lhs;
        reg [31:0] held_rhs;
        reg [63:0] input_before;
        reg [63:0] requests_before;
        begin
            guard = 0;
            while (input_ready_1 !== 1'b1) begin
                step_cycle();
                guard = guard + 1;
                if (guard > 2000) begin
                    $fatal(1, "LANES=1 input timeout index=%0d", index);
                end
            end
            held_lhs = raw_lhs(index);
            held_rhs = raw_rhs(index);
            input_before = input_batches_1;
            requests_before = child_requests_1;
            @(negedge clk_i);
            lhs_bits_1  = held_lhs;
            rhs_bits_1  = held_rhs;
            mask_1      = 1'b1;
            base_1      = index;
            input_valid_1 = 1'b1;
            step_cycle();
            if ((input_batches_1 != (input_before + 64'd1))
                || (child_requests_1 != (requests_before + 64'd1))) begin
                $fatal(1, "LANES=1 request accounting mismatch");
            end
            for (hold_index = 0; hold_index < hold_cycles;
                 hold_index = hold_index + 1) begin
                input_hold_count = input_hold_count + 1;
                step_cycle();
                if (input_ready_1 || !input_valid_1
                    || (lhs_bits_1 !== held_lhs)
                    || (rhs_bits_1 !== held_rhs)
                    || (mask_1 !== 1'b1) || (base_1 !== {32'b0, index[31:0]})
                    || (input_batches_1 != (input_before + 64'd1))
                    || (child_requests_1 != (requests_before + 64'd1))) begin
                    $fatal(1, "LANES=1 input hold/backpressure mismatch");
                end
            end
            input_valid_1 = 1'b0;
        end
    endtask

    task automatic send_input_lane8(
        input integer base_index,
        input [7:0] active_mask,
        input integer hold_cycles
    );
        integer guard;
        integer hold_index;
        reg [255:0] held_lhs;
        reg [255:0] held_rhs;
        reg [63:0] input_before;
        reg [63:0] requests_before;
        reg [63:0] lane_count;
        begin
            guard = 0;
            while (input_ready_8 !== 1'b1) begin
                step_cycle();
                guard = guard + 1;
                if (guard > 3000) begin
                    $fatal(1, "LANES=8 input timeout base=%0d", base_index);
                end
            end
            held_lhs = make_lhs_group8(base_index);
            held_rhs = make_rhs_group8(base_index);
            lane_count = (active_mask == 8'hff) ? 64'd8 : 64'd5;
            input_before = input_batches_8;
            requests_before = child_requests_8;
            @(negedge clk_i);
            lhs_bits_8  = held_lhs;
            rhs_bits_8  = held_rhs;
            mask_8      = active_mask;
            base_8      = base_index;
            input_valid_8 = 1'b1;
            step_cycle();
            if ((input_batches_8 != (input_before + 64'd1))
                || (child_requests_8 != (requests_before + lane_count))) begin
                $fatal(1, "LANES=8 atomic request accounting mismatch");
            end
            for (hold_index = 0; hold_index < hold_cycles;
                 hold_index = hold_index + 1) begin
                input_hold_count = input_hold_count + 1;
                step_cycle();
                if (input_ready_8 || !input_valid_8
                    || (lhs_bits_8 !== held_lhs)
                    || (rhs_bits_8 !== held_rhs)
                    || (mask_8 !== active_mask)
                    || (base_8 !== {32'b0, base_index[31:0]})
                    || (input_batches_8 != (input_before + 64'd1))
                    || (child_requests_8
                        != (requests_before + lane_count))) begin
                    $fatal(1, "LANES=8 input hold/backpressure mismatch");
                end
            end
            input_valid_8 = 1'b0;
        end
    endtask

    task automatic collect_result_lane1(
        input integer op,
        input integer index,
        input [4:0] expected_sticky
    );
        integer guard;
        integer hold_index;
        reg [31:0] held_result;
        reg [63:0] emitted_before;
        reg [63:0] inputs_held;
        reg [63:0] requests_held;
        reg [63:0] responses_held;
        begin
            guard = 0;
            result_ready_1 = 1'b0;
            while (result_valid_1 !== 1'b1) begin
                step_cycle();
                guard = guard + 1;
                if (guard > 3000) begin
                    $fatal(1, "LANES=1 result timeout index=%0d", index);
                end
            end
            if ((result_bits_1 !== expected_result[op][index])
                || (result_mask_1 !== 1'b1)
                || (result_base_1 !== {32'b0, index[31:0]})
                || (flags_or_1 !== expected_sticky)
                || (child_responses_1 !== child_requests_1)) begin
                $fatal(1,
                    "LANES=1 result mismatch op=%0d index=%0d got=%08x/%02x expected=%08x/%02x",
                    op, index, result_bits_1, flags_or_1,
                    expected_result[op][index], expected_sticky);
            end
            held_result = result_bits_1;
            emitted_before = elements_emitted_1;
            inputs_held = input_batches_1;
            requests_held = child_requests_1;
            responses_held = child_responses_1;
            for (hold_index = 0; hold_index < ((index % 2) + 2);
                 hold_index = hold_index + 1) begin
                result_hold_count = result_hold_count + 1;
                step_cycle();
                if (!result_valid_1 || (result_bits_1 !== held_result)
                    || (result_mask_1 !== 1'b1)
                    || (result_base_1 !== {32'b0, index[31:0]})
                    || (flags_or_1 !== expected_sticky)
                    || (input_batches_1 !== inputs_held)
                    || (child_requests_1 !== requests_held)
                    || (child_responses_1 !== responses_held)
                    || (elements_emitted_1 !== emitted_before)
                    || done_1 || error_1) begin
                    $fatal(1, "LANES=1 result hold mismatch");
                end
            end
            @(negedge clk_i);
            result_ready_1 = 1'b1;
            step_cycle();
            result_ready_1 = 1'b0;
            if (elements_emitted_1 != (emitted_before + 64'd1)) begin
                $fatal(1, "LANES=1 elements_emitted mismatch");
            end
            if (index == (ELEMENTS - 1)) begin
                if (!done_1 || error_1 || result_valid_1
                    || (input_batches_1 != 64'd13)
                    || (child_requests_1 != 64'd13)
                    || (child_responses_1 != 64'd13)
                    || (elements_emitted_1 != 64'd13)
                    || (active_cycles_1 == 64'b0)) begin
                    $fatal(1, "LANES=1 final fire/DONE mismatch");
                end
            end else if (done_1 || error_1) begin
                $fatal(1, "LANES=1 terminal before final result fire");
            end
        end
    endtask

    task automatic collect_result_lane8(
        input integer op,
        input integer base_index,
        input [7:0] active_mask,
        input [4:0] expected_sticky,
        input integer final_batch
    );
        integer guard;
        integer lane;
        integer source_index;
        integer hold_index;
        reg [255:0] held_result;
        reg [63:0] emitted_before;
        reg [63:0] inputs_held;
        reg [63:0] requests_held;
        reg [63:0] responses_held;
        reg [63:0] lane_count;
        begin
            guard = 0;
            lane_count = (active_mask == 8'hff) ? 64'd8 : 64'd5;
            result_ready_8 = 1'b0;
            while (result_valid_8 !== 1'b1) begin
                step_cycle();
                guard = guard + 1;
                if (guard > 4000) begin
                    $fatal(1, "LANES=8 result timeout base=%0d", base_index);
                end
            end
            if ((result_mask_8 !== active_mask)
                || (result_base_8 !== {32'b0, base_index[31:0]})
                || (flags_or_8 !== expected_sticky)
                || (child_responses_8 !== child_requests_8)) begin
                $fatal(1, "LANES=8 result metadata/flags mismatch");
            end
            for (lane = 0; lane < 8; lane = lane + 1) begin
                source_index = base_index + lane;
                if (active_mask[lane]) begin
                    if (result_bits_8[(lane*32) +: 32]
                        !== expected_result[op][source_index]) begin
                        $fatal(1,
                            "LANES=8 result mismatch op=%0d index=%0d got=%08x expected=%08x",
                            op, source_index,
                            result_bits_8[(lane*32) +: 32],
                            expected_result[op][source_index]);
                    end
                end else if (result_bits_8[(lane*32) +: 32] !== 32'b0) begin
                    $fatal(1, "inactive result lane leaked bits");
                end
            end
            held_result = result_bits_8;
            emitted_before = elements_emitted_8;
            inputs_held = input_batches_8;
            requests_held = child_requests_8;
            responses_held = child_responses_8;
            for (hold_index = 0; hold_index < (final_batch + 3);
                 hold_index = hold_index + 1) begin
                result_hold_count = result_hold_count + 1;
                step_cycle();
                if (!result_valid_8 || (result_bits_8 !== held_result)
                    || (result_mask_8 !== active_mask)
                    || (result_base_8 !== {32'b0, base_index[31:0]})
                    || (flags_or_8 !== expected_sticky)
                    || (input_batches_8 !== inputs_held)
                    || (child_requests_8 !== requests_held)
                    || (child_responses_8 !== responses_held)
                    || (elements_emitted_8 !== emitted_before)
                    || done_8 || error_8) begin
                    $fatal(1, "LANES=8 result hold mismatch");
                end
            end
            @(negedge clk_i);
            result_ready_8 = 1'b1;
            step_cycle();
            result_ready_8 = 1'b0;
            if (elements_emitted_8 != (emitted_before + lane_count)) begin
                $fatal(1, "LANES=8 elements_emitted popcount mismatch");
            end
            if (final_batch != 0) begin
                if (!done_8 || error_8 || result_valid_8
                    || (input_batches_8 != 64'd2)
                    || (child_requests_8 != 64'd13)
                    || (child_responses_8 != 64'd13)
                    || (elements_emitted_8 != 64'd13)
                    || (active_cycles_8 == 64'b0)) begin
                    $fatal(1, "LANES=8 final fire/DONE mismatch");
                end
            end else if (done_8 || error_8) begin
                $fatal(1, "LANES=8 terminal before tail result fire");
            end
        end
    endtask

    task automatic run_opcode(input integer op);
        integer index;
        integer lane;
        reg [4:0] sticky_1;
        reg [4:0] sticky_8;
        begin
            launch_both(op);
            sticky_1 = 5'b0;
            for (index = 0; index < ELEMENTS; index = index + 1) begin
                send_input_lane1(index, (index % 2) + 1);
                sticky_1 = sticky_1 | expected_flags[op][index];
                collect_result_lane1(op, index, sticky_1);
            end
            if (flags_or_1 !== expected_flags_or[op]) begin
                $fatal(1, "LANES=1 final flags OR mismatch op=%0d", op);
            end

            sticky_8 = 5'b0;
            send_input_lane8(0, 8'hff, 2);
            for (lane = 0; lane < 8; lane = lane + 1) begin
                sticky_8 = sticky_8 | expected_flags[op][lane];
            end
            collect_result_lane8(op, 0, 8'hff, sticky_8, 0);

            send_input_lane8(8, 8'h1f, 2);
            for (lane = 0; lane < 5; lane = lane + 1) begin
                sticky_8 = sticky_8 | expected_flags[op][8 + lane];
            end
            collect_result_lane8(op, 8, 8'h1f, sticky_8, 1);
            if (flags_or_8 !== expected_flags_or[op]) begin
                $fatal(1, "LANES=8 final flags OR mismatch op=%0d", op);
            end
            wait_both_idle();
        end
    endtask

    task automatic wait_lane8_idle;
        integer guard;
        begin
            guard = 0;
            while (ready_8 !== 1'b1) begin
                step_cycle();
                guard = guard + 1;
                if (guard > 2000) begin
                    $fatal(1, "LANES=8 IDLE timeout");
                end
            end
        end
    endtask

    task automatic launch_lane8(
        input [2:0] op,
        input [63:0] count
    );
        begin
            wait_lane8_idle();
            opcode_8 = op;
            element_count_8 = count;
            scale_bits_8 = SCALE_BITS;
            @(negedge clk_i);
            start_8 = 1'b1;
            step_cycle();
            start_8 = 1'b0;
        end
    endtask

    task automatic check_immediate_error(
        input [7:0] expected_code
    );
        begin
            if (!error_8 || done_8 || result_valid_8
                || (error_code_8 !== expected_code)
                || (error_index_8 !== 64'hffffffffffffffff)
                || (flags_or_8 != 0) || (input_batches_8 != 0)
                || (child_requests_8 != 0) || (child_responses_8 != 0)
                || (elements_emitted_8 != 0)) begin
                $fatal(1, "immediate command error mismatch code=%h",
                       expected_code);
            end
            step_cycle();
            if (!ready_8 || result_valid_8) begin
                $fatal(1, "immediate error cleanup mismatch");
            end
        end
    endtask

    task automatic run_invalid_commands;
        begin
            launch_lane8(3'd7, 64'd13);
            check_immediate_error(ERROR_INVALID_OPCODE);
            launch_lane8(OP_ADD, 64'd0);
            check_immediate_error(ERROR_INVALID_COUNT);
        end
    endtask

    task automatic run_bad_packet(
        input [63:0] packet_base,
        input [7:0] packet_mask,
        input [7:0] expected_code,
        input [63:0] expected_index
    );
        integer guard;
        begin
            launch_lane8(OP_ADD, 64'd13);
            guard = 0;
            while (input_ready_8 !== 1'b1) begin
                step_cycle();
                guard = guard + 1;
                if (guard > 2000) begin
                    $fatal(1, "bad-packet input timeout");
                end
            end
            @(negedge clk_i);
            lhs_bits_8 = make_lhs_group8(0);
            rhs_bits_8 = make_rhs_group8(0);
            base_8 = packet_base;
            mask_8 = packet_mask;
            input_valid_8 = 1'b1;
            result_ready_8 = 1'b1;
            step_cycle();
            input_valid_8 = 1'b0;
            result_ready_8 = 1'b0;
            if (!error_8 || done_8 || result_valid_8
                || (error_code_8 !== expected_code)
                || (error_index_8 !== expected_index)
                || (input_batches_8 != 64'd1)
                || (child_requests_8 != 0) || (child_responses_8 != 0)
                || (elements_emitted_8 != 0) || (flags_or_8 != 0)) begin
                $fatal(1,
                    "bad packet atomic failure mismatch code=%h index=%0d",
                    error_code_8, error_index_8);
            end
            step_cycle();
            if (!ready_8 || result_valid_8) begin
                $fatal(1, "bad-packet cleanup mismatch");
            end
        end
    endtask

    initial begin
        cycle_count = 0;
        input_hold_count = 0;
        result_hold_count = 0;
        serial_response_observed = 0;
        previous_child_responses_8 = 64'b0;

        rst_i = 1'b1;
        start_1 = 1'b0;
        opcode_1 = OP_ADD;
        element_count_1 = 64'b0;
        scale_bits_1 = 32'b0;
        input_valid_1 = 1'b0;
        lhs_bits_1 = 32'b0;
        rhs_bits_1 = 32'b0;
        mask_1 = 1'b0;
        base_1 = 64'b0;
        result_ready_1 = 1'b0;

        start_8 = 1'b0;
        opcode_8 = OP_ADD;
        element_count_8 = 64'b0;
        scale_bits_8 = 32'b0;
        input_valid_8 = 1'b0;
        lhs_bits_8 = 256'b0;
        rhs_bits_8 = 256'b0;
        mask_8 = 8'b0;
        base_8 = 64'b0;
        result_ready_8 = 1'b0;

        oracle_req_valid = 1'b0;
        oracle_op_mul = 1'b0;
        oracle_lhs_bits = 32'b0;
        oracle_rhs_bits = 32'b0;
        oracle_rsp_ready = 1'b0;

        repeat (4) step_cycle();
        if (ready_1 || ready_8 || busy_1 || busy_8
            || result_valid_1 || result_valid_8 || oracle_req_ready) begin
            $fatal(1, "reset protocol mismatch");
        end
        @(negedge clk_i);
        rst_i = 1'b0;
        step_cycle();
        if (!ready_1 || !ready_8 || busy_1 || busy_8
            || !oracle_req_ready) begin
            $fatal(1, "IDLE did not open after reset");
        end

        build_oracle_table();
        for (opcode_index = 0; opcode_index < 4;
             opcode_index = opcode_index + 1) begin
            run_opcode(opcode_index);
        end

        run_invalid_commands();
        run_bad_packet(64'd8, 8'hff, ERROR_BASE_INDEX, 64'd0);
        run_bad_packet(64'd0, 8'h7f, ERROR_MASK, 64'd7);

        if ((input_hold_count == 0) || (result_hold_count == 0)
            || (serial_response_observed == 0)) begin
            $fatal(1,
                "backpressure coverage missing input=%0d result=%0d child=%0d",
                input_hold_count, result_hold_count,
                serial_response_observed);
        end

        repeat (8) begin
            step_cycle();
            if (!ready_1 || !ready_8 || busy_1 || busy_8
                || done_1 || done_8 || error_1 || error_8
                || result_valid_1 || result_valid_8) begin
                $fatal(1, "final stale terminal observation failed");
            end
        end

        $display("[NPU-F32-ALU-SIMD][PASS] lanes=1,8 ops=ADD,MUL,SUB,SCALE elements=13 tail_mask=1f oracle=public-AddMul raw_bits_flags=exact specials=zeros,subnormals,finite,inf,qnan,snan request=atomic response=serialized holds=input,child,result counters=exact errors=opcode,count,base,mask");
        $finish;
    end

endmodule

`default_nettype wire
