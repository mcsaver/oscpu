`timescale 1ns/1ps

module tb_unary_glu_tensor_engine;
    localparam logic [2:0] OP_SIGMOID  = 3'd0;
    localparam logic [2:0] OP_SOFTPLUS = 3'd1;
    localparam logic [2:0] OP_SILU     = 3'd2;
    localparam logic [2:0] OP_SWIGLU   = 3'd3;

    localparam logic [3:0] ST_EXP_WAIT      = 4'd3;
    localparam logic [3:0] ST_ABORT_RESET   = 4'd12;
    localparam logic [2:0] BANK_READY_OK    = 3'd2;
    localparam logic [2:0] BANK_READY_ERR   = 3'd4;

    logic        clk_i;
    logic        rst_i;
    logic        cmd_valid_i;
    wire         cmd_ready_o;
    logic [2:0]  cmd_opcode_i;
    logic [12:0] cmd_length_i;
    logic [7:0]  cmd_tag_i;
    wire         busy_o;
    logic        in_valid_i;
    wire         in_ready_o;
    logic [31:0] in_src0_bits_i;
    logic [31:0] in_src1_bits_i;
    wire         out_valid_o;
    logic        out_ready_i;
    wire         out_sop_o;
    wire         out_last_o;
    wire         out_keep_o;
    wire [31:0]  out_result_bits_o;
    wire [4:0]   out_flags_o;
    wire [12:0]  out_elem_index_o;
    wire [7:0]   out_tag_o;
    wire [2:0]   out_opcode_o;
    wire [12:0]  out_length_o;
    wire         out_error_o;
    wire [3:0]   out_error_code_o;
    wire [63:0]  out_active_cycles_o;
    wire [12:0]  out_capture_count_o;
    wire [12:0]  out_scalar_launch_count_o;
    wire [12:0]  out_scalar_terminal_count_o;
    wire [12:0]  out_success_result_count_o;
    wire [4:0]   out_child_call_mask_o;
    wire [12:0]  out_exp_req_count_o;
    wire [12:0]  out_add_req_count_o;
    wire [12:0]  out_div_req_count_o;
    wire [12:0]  out_log_req_count_o;
    wire [12:0]  out_mul_req_count_o;
    wire [12:0]  out_bypass_count_o;
    wire [4:0]   out_tensor_flags_or_o;
    wire         out_fail_elem_valid_o;
    wire [12:0]  out_fail_elem_index_o;

    TensorNpuUnaryGluTensorEngine #(
        .MAX_ELEMS(6144),
        .ELEMENT_TIMEOUT_CYCLES(256)
    ) dut (
        .clk_i                         (clk_i),
        .rst_i                         (rst_i),
        .cmd_valid_i                   (cmd_valid_i),
        .cmd_ready_o                   (cmd_ready_o),
        .cmd_opcode_i                  (cmd_opcode_i),
        .cmd_length_i                  (cmd_length_i),
        .cmd_tag_i                     (cmd_tag_i),
        .busy_o                        (busy_o),
        .in_valid_i                    (in_valid_i),
        .in_ready_o                    (in_ready_o),
        .in_src0_bits_i                (in_src0_bits_i),
        .in_src1_bits_i                (in_src1_bits_i),
        .out_valid_o                   (out_valid_o),
        .out_ready_i                   (out_ready_i),
        .out_sop_o                     (out_sop_o),
        .out_last_o                    (out_last_o),
        .out_keep_o                    (out_keep_o),
        .out_result_bits_o             (out_result_bits_o),
        .out_flags_o                   (out_flags_o),
        .out_elem_index_o              (out_elem_index_o),
        .out_tag_o                     (out_tag_o),
        .out_opcode_o                  (out_opcode_o),
        .out_length_o                  (out_length_o),
        .out_error_o                   (out_error_o),
        .out_error_code_o              (out_error_code_o),
        .out_active_cycles_o           (out_active_cycles_o),
        .out_capture_count_o           (out_capture_count_o),
        .out_scalar_launch_count_o     (out_scalar_launch_count_o),
        .out_scalar_terminal_count_o   (out_scalar_terminal_count_o),
        .out_success_result_count_o    (out_success_result_count_o),
        .out_child_call_mask_o         (out_child_call_mask_o),
        .out_exp_req_count_o           (out_exp_req_count_o),
        .out_add_req_count_o           (out_add_req_count_o),
        .out_div_req_count_o           (out_div_req_count_o),
        .out_log_req_count_o           (out_log_req_count_o),
        .out_mul_req_count_o           (out_mul_req_count_o),
        .out_bypass_count_o            (out_bypass_count_o),
        .out_tensor_flags_or_o         (out_tensor_flags_or_o),
        .out_fail_elem_valid_o         (out_fail_elem_valid_o),
        .out_fail_elem_index_o         (out_fail_elem_index_o)
    );

    always #5 clk_i <= ~clk_i;

    // 所有公开output字段打包，用于success/error backpressure逐位稳定检查。
    wire [300:0] out_bundle = {
        out_valid_o, out_sop_o, out_last_o, out_keep_o,
        out_result_bits_o, out_flags_o, out_elem_index_o,
        out_tag_o, out_opcode_o, out_length_o, out_error_o,
        out_error_code_o, out_active_cycles_o,
        out_capture_count_o, out_scalar_launch_count_o,
        out_scalar_terminal_count_o, out_success_result_count_o,
        out_child_call_mask_o, out_exp_req_count_o, out_add_req_count_o,
        out_div_req_count_o, out_log_req_count_o, out_mul_req_count_o,
        out_bypass_count_o, out_tensor_flags_or_o,
        out_fail_elem_valid_o, out_fail_elem_index_o
    };

    localparam integer TB_MAX_DESCS = 512;

    longint unsigned tb_ts;
    longint unsigned tb_desc_start_ts [0:TB_MAX_DESCS-1];
    longint unsigned tb_desc_terminal_ts [0:TB_MAX_DESCS-1];
    logic [7:0] tb_desc_tag [0:TB_MAX_DESCS-1];
    bit tb_desc_terminal_seen [0:TB_MAX_DESCS-1];
    integer tb_order_desc [0:1];
    integer tb_order_rd_ptr;
    integer tb_order_wr_ptr;
    integer tb_order_count;
    integer tb_next_desc;

    bit tb_work_valid;
    integer tb_work_desc;
    logic [2:0] tb_work_opcode;
    logic [12:0] tb_work_length;
    logic [12:0] tb_capture_count;
    logic [12:0] tb_scalar_index;
    bit tb_bad_seen;
    bit tb_capture_complete;
    bit tb_scalar_outstanding;
    bit tb_parent_fault_pending;
    longint unsigned tb_parent_fault_ts;
    integer timestamp_negative_reject_count;

    bit hold_check_en;
    logic [300:0] held_out_bundle;

    wire tb_cmd_accept = cmd_valid_i && cmd_ready_o;
    wire tb_input_accept = in_valid_i && in_ready_o;
    wire tb_scalar_req_accept =
        dut.u_element.req_valid_i && dut.u_element.req_ready_o;
    wire tb_scalar_rsp_accept =
        dut.u_element.rsp_valid_o && dut.u_element.rsp_ready_i;
    wire tb_output_pop = out_valid_o && out_ready_i && out_last_o;

    function automatic bit tb_external_nonfinite(input logic [7:0] exponent);
        begin
            tb_external_nonfinite = (exponent == 8'hff);
        end
    endfunction

    function automatic bit tb_command_legal(
        input logic [2:0] opcode,
        input logic [12:0] length
    );
        begin
            tb_command_legal =
                (opcode <= OP_SWIGLU) && (length >= 13'd1) &&
                (length <= 13'd6144);
        end
    endfunction

    function automatic bit tb_timestamp_equals(
        input logic [63:0] observed,
        input longint unsigned expected
    );
        begin
            tb_timestamp_equals = (observed === expected[63:0]);
        end
    endfunction

    // 独立descriptor oracle：start只看公开command握手；terminal由TB保存的
    // op/length、input finite/capture与真实scalar端口边界推导。输出资格只依赖
    // 本scoreboard的head terminal，不读取parent内部状态或终止predicate。
    always @(posedge clk_i) begin
        if (rst_i) begin
            tb_ts <= 0;
            tb_order_desc[0] <= -1;
            tb_order_desc[1] <= -1;
            tb_order_rd_ptr <= 0;
            tb_order_wr_ptr <= 0;
            tb_order_count <= 0;
            tb_next_desc <= 0;
            tb_work_valid <= 1'b0;
            tb_work_desc <= -1;
            tb_work_opcode <= 3'b0;
            tb_work_length <= 13'b0;
            tb_capture_count <= 13'b0;
            tb_scalar_index <= 13'b0;
            tb_bad_seen <= 1'b0;
            tb_capture_complete <= 1'b0;
            tb_scalar_outstanding <= 1'b0;
            // descriptor arrays无需逐项reset：count/pointer归零后不可见，
            // 每个新slot又会在公开command握手edge完整覆盖。
        end else begin
            // 必须在本edge的terminal更新之前检查，故同edge提前公开也会失败。
            if (out_valid_o) begin
                if (tb_order_count <= 0) begin
                    $fatal(1, "output visible without accepted descriptor");
                end
                if (!tb_desc_terminal_seen[tb_order_desc[tb_order_rd_ptr]]) begin
                    $fatal(1, "descriptor became visible before independent terminal");
                end
                if (out_tag_o !==
                    tb_desc_tag[tb_order_desc[tb_order_rd_ptr]]) begin
                    $fatal(1, "output tag does not match independent FIFO head");
                end
            end

            if (tb_output_pop && (tb_order_count <= 0)) begin
                $fatal(1, "output pop underflowed independent descriptor FIFO");
            end
            if (tb_cmd_accept && !tb_output_pop &&
                (tb_order_count >= 2)) begin
                $fatal(1, "command overflowed independent descriptor FIFO");
            end

            if (tb_cmd_accept) begin
                if (tb_next_desc >= TB_MAX_DESCS) begin
                    $fatal(1, "independent descriptor storage exhausted");
                end
                tb_desc_start_ts[tb_next_desc] <= tb_ts;
                tb_desc_terminal_ts[tb_next_desc] <= 0;
                tb_desc_tag[tb_next_desc] <= cmd_tag_i;
                tb_desc_terminal_seen[tb_next_desc] <= 1'b0;
                tb_order_desc[tb_order_wr_ptr] <= tb_next_desc;
                tb_order_wr_ptr <= tb_order_wr_ptr ^ 1;

                if (tb_command_legal(cmd_opcode_i, cmd_length_i)) begin
                    if (tb_work_valid) begin
                        $fatal(1, "accepted second source owner");
                    end
                    tb_work_valid <= 1'b1;
                    tb_work_desc <= tb_next_desc;
                    tb_work_opcode <= cmd_opcode_i;
                    tb_work_length <= cmd_length_i;
                    tb_capture_count <= 13'b0;
                    tb_scalar_index <= 13'b0;
                    tb_bad_seen <= 1'b0;
                    tb_capture_complete <= 1'b0;
                    tb_scalar_outstanding <= 1'b0;
                end else begin
                    tb_desc_terminal_ts[tb_next_desc] <= tb_ts;
                    tb_desc_terminal_seen[tb_next_desc] <= 1'b1;
                end
                tb_next_desc <= tb_next_desc + 1;
            end

            if (tb_parent_fault_pending && (tb_ts == tb_parent_fault_ts)) begin
                if (!tb_work_valid || (tb_work_desc < 0)) begin
                    $fatal(1, "parent fault fixture had no live TB owner");
                end
                tb_desc_terminal_ts[tb_work_desc] <= tb_ts;
                tb_desc_terminal_seen[tb_work_desc] <= 1'b1;
                tb_work_valid <= 1'b0;
                tb_scalar_outstanding <= 1'b0;
            end else begin
                if (tb_input_accept) begin
                    if (!tb_work_valid || tb_capture_complete) begin
                        $fatal(1, "input accepted outside independent capture");
                    end
                    if (tb_external_nonfinite(in_src0_bits_i[30:23]) ||
                        ((tb_work_opcode == OP_SWIGLU) &&
                         tb_external_nonfinite(in_src1_bits_i[30:23]))) begin
                        tb_bad_seen <= 1'b1;
                    end
                    tb_capture_count <= tb_capture_count + 13'd1;
                    if ((tb_capture_count + 13'd1) > tb_work_length) begin
                        $fatal(1, "input exceeded independent authoritative length");
                    end
                    if ((tb_capture_count + 13'd1) == tb_work_length) begin
                        if (tb_bad_seen ||
                            tb_external_nonfinite(in_src0_bits_i[30:23]) ||
                            ((tb_work_opcode == OP_SWIGLU) &&
                             tb_external_nonfinite(in_src1_bits_i[30:23]))) begin
                            tb_desc_terminal_ts[tb_work_desc] <= tb_ts;
                            tb_desc_terminal_seen[tb_work_desc] <= 1'b1;
                            tb_work_valid <= 1'b0;
                        end else begin
                            tb_capture_complete <= 1'b1;
                        end
                    end
                end

                if (tb_scalar_req_accept) begin
                    if (!tb_work_valid || !tb_capture_complete ||
                        tb_bad_seen || tb_scalar_outstanding) begin
                        $fatal(1, "scalar request violated independent barrier/owner");
                    end
                    tb_scalar_outstanding <= 1'b1;
                end

                if (tb_scalar_rsp_accept) begin
                    if (!tb_work_valid || !tb_capture_complete ||
                        !tb_scalar_outstanding) begin
                        $fatal(1, "scalar terminal lacked independent resident request");
                    end
                    tb_scalar_outstanding <= 1'b0;
                    if (dut.u_element.error_o ||
                        ((tb_scalar_index + 13'd1) == tb_work_length)) begin
                        tb_desc_terminal_ts[tb_work_desc] <= tb_ts;
                        tb_desc_terminal_seen[tb_work_desc] <= 1'b1;
                        tb_work_valid <= 1'b0;
                    end else begin
                        tb_scalar_index <= tb_scalar_index + 13'd1;
                    end
                end
            end

            if (tb_output_pop) begin
                tb_order_rd_ptr <= tb_order_rd_ptr ^ 1;
            end
            case ({tb_cmd_accept, tb_output_pop})
                2'b10: tb_order_count <= tb_order_count + 1;
                2'b01: tb_order_count <= tb_order_count - 1;
                default: tb_order_count <= tb_order_count;
            endcase

            if (dut.element_req_valid &&
                ((dut.capture_count_q != dut.active_length_q) ||
                 dut.external_bad_seen_q || !dut.source_owner_valid_q)) begin
                $fatal(1, "scalar request crossed capture/preflight barrier");
            end
            if ((dut.ctrl_state_q == dut.CTRL_CAPTURE) && dut.element_req_valid) begin
                $fatal(1, "scalar request asserted in CAPTURE");
            end
            if ((dut.fifo_count_q == 2'd2) && cmd_ready_o) begin
                $fatal(1, "FIFO full exposed command credit");
            end
            if (dut.source_owner_valid_q && cmd_ready_o) begin
                $fatal(1, "source owner exposed command credit");
            end
            if (dut.work_scalar_terminal_count_q > dut.work_scalar_launch_count_q) begin
                $fatal(1, "scalar terminal count exceeded launch count");
            end
            if ((dut.work_scalar_launch_count_q - dut.work_scalar_terminal_count_q) > 13'd1) begin
                $fatal(1, "more than one scalar transaction resident");
            end
            tb_ts <= tb_ts + 1;
        end
    end

    always @(negedge clk_i) begin
        if (hold_check_en && (out_bundle !== held_out_bundle)) begin
            $fatal(1, "output payload changed under backpressure");
        end
    end

    task automatic wait_negedges(input integer cycles);
        integer k;
        begin
            for (k = 0; k < cycles; k = k + 1) begin
                @(negedge clk_i);
            end
        end
    endtask

    task automatic reset_dut;
        begin
            @(negedge clk_i);
            rst_i = 1'b1;
            cmd_valid_i = 1'b0;
            in_valid_i = 1'b0;
            out_ready_i = 1'b0;
            hold_check_en = 1'b0;
            wait_negedges(3);
            @(negedge clk_i);
            rst_i = 1'b0;
            @(negedge clk_i);
            if ((cmd_ready_o !== 1'b1) || (in_ready_o !== 1'b0) ||
                (out_valid_o !== 1'b0) || (busy_o !== 1'b0) ||
                (dut.fifo_count_q !== 2'd0) || dut.source_owner_valid_q ||
                (dut.bank0_state_q !== dut.BANK_FREE) ||
                (dut.bank1_state_q !== dut.BANK_FREE)) begin
                $fatal(1, "reset did not restore clean engine state");
            end
        end
    endtask

    task automatic issue_cmd(
        input logic [2:0] opcode,
        input logic [12:0] length,
        input logic [7:0] tag
    );
        integer guard;
        begin
            @(negedge clk_i);
            cmd_opcode_i = opcode;
            cmd_length_i = length;
            cmd_tag_i = tag;
            cmd_valid_i = 1'b1;
            guard = 0;
            while (cmd_ready_o !== 1'b1) begin
                @(negedge clk_i);
                guard = guard + 1;
                if (guard > 2000000) begin
                    $fatal(1, "command timeout tag=%0d", tag);
                end
            end
            @(posedge clk_i);
            @(negedge clk_i);
            cmd_valid_i = 1'b0;
        end
    endtask

    task automatic send_input(
        input logic [31:0] src0,
        input logic [31:0] src1
    );
        integer guard;
        begin
            @(negedge clk_i);
            in_src0_bits_i = src0;
            in_src1_bits_i = src1;
            in_valid_i = 1'b1;
            guard = 0;
            while (in_ready_o !== 1'b1) begin
                @(negedge clk_i);
                guard = guard + 1;
                if (guard > 2000000) begin
                    $fatal(1, "input timeout src0=%08x", src0);
                end
            end
            @(posedge clk_i);
            @(negedge clk_i);
            in_valid_i = 1'b0;
        end
    endtask

    task automatic wait_output(input logic [7:0] expected_tag);
        integer guard;
        begin
            guard = 0;
            while (out_valid_o !== 1'b1) begin
                @(negedge clk_i);
                guard = guard + 1;
                if (guard > 4000000) begin
                    $fatal(1, "output timeout tag=%0d", expected_tag);
                end
            end
            if (out_tag_o !== expected_tag) begin
                $fatal(1, "output order mismatch got=%0d expected=%0d",
                       out_tag_o, expected_tag);
            end
        end
    endtask

    task automatic check_timestamp(input logic [7:0] tag);
        longint unsigned expected_active;
        integer head_desc;
        begin
            if (tb_order_count <= 0) begin
                $fatal(1, "timestamp check had no independent FIFO head");
            end
            head_desc = tb_order_desc[tb_order_rd_ptr];
            if ((head_desc < 0) || !tb_desc_terminal_seen[head_desc]) begin
                $fatal(1, "timestamp event missing head descriptor tag=%0d", tag);
            end
            if (tb_desc_tag[head_desc] !== tag) begin
                $fatal(1, "timestamp head tag mismatch got=%0d expected=%0d",
                       tb_desc_tag[head_desc], tag);
            end
            expected_active =
                tb_desc_terminal_ts[head_desc] - tb_desc_start_ts[head_desc] + 1;
            if (!tb_timestamp_equals(out_active_cycles_o, expected_active)) begin
                $fatal(1, "active timestamp mismatch tag=%0d got=%0d expected=%0d",
                       tag, out_active_cycles_o, expected_active);
            end
            if (tb_timestamp_equals(out_active_cycles_o, expected_active - 1) ||
                tb_timestamp_equals(out_active_cycles_o, expected_active + 1)) begin
                $fatal(1, "timestamp oracle accepted an off-by-one terminal tag=%0d", tag);
            end
            timestamp_negative_reject_count =
                timestamp_negative_reject_count + 2;
        end
    endtask

    task automatic check_success_meta(
        input logic [7:0] tag,
        input logic [2:0] opcode,
        input logic [12:0] length,
        input logic [4:0] call_mask,
        input logic [12:0] exp_count,
        input logic [12:0] add_count,
        input logic [12:0] div_count,
        input logic [12:0] log_count,
        input logic [12:0] mul_count,
        input logic [12:0] bypass_count,
        input logic [4:0] flags_or
    );
        begin
            if ((out_tag_o !== tag) || (out_opcode_o !== opcode) ||
                (out_length_o !== length) || out_error_o ||
                (out_error_code_o !== 4'd0) ||
                (out_capture_count_o !== length) ||
                (out_scalar_launch_count_o !== length) ||
                (out_scalar_terminal_count_o !== length) ||
                (out_success_result_count_o !== length) ||
                (out_child_call_mask_o !== call_mask) ||
                (out_exp_req_count_o !== exp_count) ||
                (out_add_req_count_o !== add_count) ||
                (out_div_req_count_o !== div_count) ||
                (out_log_req_count_o !== log_count) ||
                (out_mul_req_count_o !== mul_count) ||
                (out_bypass_count_o !== bypass_count) ||
                (out_tensor_flags_or_o !== flags_or) ||
                out_fail_elem_valid_o) begin
                $fatal(1, "success metadata mismatch tag=%0d", tag);
            end
            check_timestamp(tag);
        end
    endtask

    task automatic consume_success_beat(
        input logic [7:0] tag,
        input logic [2:0] opcode,
        input logic [12:0] length,
        input logic [12:0] index,
        input logic [31:0] result_bits,
        input logic [4:0] flags,
        input logic [4:0] call_mask,
        input logic [12:0] exp_count,
        input logic [12:0] add_count,
        input logic [12:0] div_count,
        input logic [12:0] log_count,
        input logic [12:0] mul_count,
        input logic [12:0] bypass_count,
        input logic [4:0] flags_or
    );
        begin
            out_ready_i = 1'b0;
            wait_output(tag);
            if (!out_keep_o ||
                (out_sop_o !== (index == 13'd0)) ||
                (out_last_o !== ((index + 13'd1) == length)) ||
                (out_elem_index_o !== index) ||
                (out_result_bits_o !== result_bits) ||
                (out_flags_o !== flags)) begin
                $fatal(1, "success beat mismatch tag=%0d index=%0d", tag, index);
            end
            check_success_meta(tag, opcode, length, call_mask,
                               exp_count, add_count, div_count, log_count,
                               mul_count, bypass_count, flags_or);
            out_ready_i = 1'b1;
            @(posedge clk_i);
            @(negedge clk_i);
            out_ready_i = 1'b0;
        end
    endtask

    task automatic check_error_meta(
        input logic [7:0] tag,
        input logic [2:0] opcode,
        input logic [12:0] length,
        input logic [3:0] code,
        input logic [12:0] capture_count,
        input logic [12:0] launch_count,
        input logic [12:0] terminal_count,
        input logic [12:0] success_count,
        input logic [4:0] call_mask,
        input logic [12:0] exp_count,
        input logic [12:0] add_count,
        input logic [12:0] div_count,
        input logic [12:0] log_count,
        input logic [12:0] mul_count,
        input logic [12:0] bypass_count,
        input logic fail_valid,
        input logic [12:0] fail_index
    );
        begin
            if ((out_tag_o !== tag) || (out_opcode_o !== opcode) ||
                (out_length_o !== length) || !out_error_o ||
                (out_error_code_o !== code) || !out_sop_o || !out_last_o ||
                out_keep_o || (out_result_bits_o !== 32'b0) ||
                (out_flags_o !== 5'b0) || (out_elem_index_o !== 13'b0) ||
                (out_capture_count_o !== capture_count) ||
                (out_scalar_launch_count_o !== launch_count) ||
                (out_scalar_terminal_count_o !== terminal_count) ||
                (out_success_result_count_o !== success_count) ||
                (out_child_call_mask_o !== call_mask) ||
                (out_exp_req_count_o !== exp_count) ||
                (out_add_req_count_o !== add_count) ||
                (out_div_req_count_o !== div_count) ||
                (out_log_req_count_o !== log_count) ||
                (out_mul_req_count_o !== mul_count) ||
                (out_bypass_count_o !== bypass_count) ||
                (out_tensor_flags_or_o !== 5'b0) ||
                (out_fail_elem_valid_o !== fail_valid) ||
                (out_fail_elem_index_o !== fail_index)) begin
                $fatal(1, "error completion mismatch tag=%0d code=%0d", tag, code);
            end
            check_timestamp(tag);
        end
    endtask

    task automatic consume_error(
        input logic [7:0] tag,
        input logic [2:0] opcode,
        input logic [12:0] length,
        input logic [3:0] code,
        input logic [12:0] capture_count,
        input logic [12:0] launch_count,
        input logic [12:0] terminal_count,
        input logic [12:0] success_count,
        input logic [4:0] call_mask,
        input logic [12:0] exp_count,
        input logic [12:0] add_count,
        input logic [12:0] div_count,
        input logic [12:0] log_count,
        input logic [12:0] mul_count,
        input logic [12:0] bypass_count,
        input logic fail_valid,
        input logic [12:0] fail_index
    );
        begin
            out_ready_i = 1'b0;
            wait_output(tag);
            check_error_meta(tag, opcode, length, code, capture_count,
                             launch_count, terminal_count, success_count,
                             call_mask, exp_count, add_count, div_count,
                             log_count, mul_count, bypass_count,
                             fail_valid, fail_index);
            out_ready_i = 1'b1;
            @(posedge clk_i);
            @(negedge clk_i);
            out_ready_i = 1'b0;
        end
    endtask

    task automatic wait_element_exp_wait(input logic [12:0] wanted_index);
        integer guard;
        begin
            guard = 0;
            while ((dut.exec_index_q !== wanted_index) ||
                   (dut.u_element.state_q !== ST_EXP_WAIT)) begin
                @(negedge clk_i);
                guard = guard + 1;
                if (guard > 1000000) begin
                    $fatal(1, "did not reach scalar EXP_WAIT index=%0d", wanted_index);
                end
            end
        end
    endtask

    // 只改真实scalar FSM/pending code，使其通过原rsp接口发布terminal；不force parent错误谓词。
    task automatic inject_scalar_error(
        input logic [12:0] wanted_index,
        input logic [3:0] code,
        input integer pre_abort_hold_cycles
    );
        integer hold_cycle;
        begin
            wait_element_exp_wait(wanted_index);
            for (hold_cycle = 0; hold_cycle < pre_abort_hold_cycles;
                 hold_cycle = hold_cycle + 1) begin
                @(negedge clk_i);
                if (out_valid_o) begin
                    $fatal(1, "partial tensor became visible before injected terminal");
                end
                if (dut.u_element.state_q !== ST_EXP_WAIT) begin
                    $fatal(1, "scalar left EXP_WAIT during delayed error fixture");
                end
            end
            dut.u_element.owner_valid_q = 1'b0;
            dut.u_element.pending_error_code_q = code;
            dut.u_element.state_q = ST_ABORT_RESET;
            @(negedge clk_i);
        end
    endtask

    // deadline同拍注入真实EXP response：normal由scalar timeout产生code3，fatal优先产生code2。
    task automatic inject_deadline_exp_response(input bit fatal_response);
        begin
            wait_element_exp_wait(13'd0);
            dut.u_element.watchdog_q = 32'd256;
            force dut.u_element.exp_rsp_valid = 1'b1;
            force dut.u_element.exp_rsp_result = 32'h3f800000;
            force dut.u_element.exp_rsp_flags = 5'b0;
            if (fatal_response) begin
                force dut.u_element.exp_rsp_error = 1'b1;
                force dut.u_element.exp_rsp_error_code = 4'd2;
            end else begin
                force dut.u_element.exp_rsp_error = 1'b0;
                force dut.u_element.exp_rsp_error_code = 4'd0;
            end
            @(posedge clk_i);
            @(negedge clk_i);
            release dut.u_element.exp_rsp_valid;
            release dut.u_element.exp_rsp_result;
            release dut.u_element.exp_rsp_flags;
            release dut.u_element.exp_rsp_error;
            release dut.u_element.exp_rsp_error_code;
        end
    endtask

    // Literal parent-state corruption while a live scalar is resident.  The
    // independent terminal oracle is armed by the fixture edge, not DUT state.
    task automatic inject_parent_controller_fault;
        begin
            wait_element_exp_wait(13'd0);
            if (!dut.u_element.owner_valid_q) begin
                $fatal(1, "parent fault fixture did not have resident scalar");
            end
            tb_parent_fault_pending = 1'b1;
            tb_parent_fault_ts = tb_ts;
            dut.ctrl_state_q = 3'd7;
            #1;
            if (!dut.parent_element_rst || cmd_ready_o ||
                dut.element_req_valid || dut.element_rsp_ready) begin
                $fatal(1, "illegal parent state did not revoke/reset credits");
            end

            @(posedge clk_i);
            @(negedge clk_i);
            if ((dut.ctrl_state_q !== dut.CTRL_QUARANTINE) ||
                !dut.parent_element_rst || cmd_ready_o ||
                dut.u_element.owner_valid_q || dut.u_element.rsp_valid_o) begin
                $fatal(1, "parent scalar quarantine was not a full clean edge");
            end

            @(posedge clk_i);
            @(negedge clk_i);
            if ((dut.ctrl_state_q !== dut.CTRL_IDLE) ||
                dut.parent_element_rst || !cmd_ready_o ||
                dut.u_element.owner_valid_q || dut.u_element.rsp_valid_o) begin
                $fatal(1, "parent quarantine did not restore clean command credit");
            end
        end
    endtask

    integer i;
    logic [31:0] max_raw;
    integer blocked_cycles;
    integer third_desc_before;

    initial begin
        clk_i = 1'b0;
        rst_i = 1'b1;
        cmd_valid_i = 1'b0;
        cmd_opcode_i = 3'b0;
        cmd_length_i = 13'b0;
        cmd_tag_i = 8'b0;
        in_valid_i = 1'b0;
        in_src0_bits_i = 32'b0;
        in_src1_bits_i = 32'b0;
        out_ready_i = 1'b0;
        hold_check_en = 1'b0;
        held_out_bundle = 301'b0;
        timestamp_negative_reject_count = 0;
        tb_parent_fault_pending = 1'b0;
        tb_parent_fault_ts = 0;

        wait_negedges(4);
        rst_i = 1'b0;
        @(negedge clk_i);

        // 冻结向量：SIGMOID ordinary +1 -> 0x3f3b26a8,NX。
        issue_cmd(OP_SIGMOID, 13'd1, 8'd1);
        send_input(32'h3f800000, 32'hdeadbeef);
        consume_success_beat(8'd1, OP_SIGMOID, 13'd1, 13'd0,
                             32'h3f3b26a8, 5'h01, 5'h07,
                             13'd1, 13'd1, 13'd1, 13'd0, 13'd0,
                             13'd0, 5'h01);

        // SOFTPLUS {bypass,slow,bypass}，只slow element实际调用EXP/ADD/LOG。
        issue_cmd(OP_SOFTPLUS, 13'd3, 8'd2);
        send_input(32'h41a00001, 32'h11111111);
        send_input(32'h00000000, 32'h22222222);
        send_input(32'h41a00002, 32'h33333333);
        consume_success_beat(8'd2, OP_SOFTPLUS, 13'd3, 13'd0,
                             32'h41a00001, 5'h00, 5'h0b,
                             13'd1, 13'd1, 13'd0, 13'd1, 13'd0,
                             13'd2, 5'h01);
        consume_success_beat(8'd2, OP_SOFTPLUS, 13'd3, 13'd1,
                             32'h3f317218, 5'h01, 5'h0b,
                             13'd1, 13'd1, 13'd0, 13'd1, 13'd0,
                             13'd2, 5'h01);
        consume_success_beat(8'd2, OP_SOFTPLUS, 13'd3, 13'd2,
                             32'h41a00002, 5'h00, 5'h0b,
                             13'd1, 13'd1, 13'd0, 13'd1, 13'd0,
                             13'd2, 5'h01);

        // SILU ordinary +/-1。
        issue_cmd(OP_SILU, 13'd2, 8'd3);
        send_input(32'h3f800000, 32'haaaaaaaa);
        send_input(32'hbf800000, 32'hbbbbbbbb);
        consume_success_beat(8'd3, OP_SILU, 13'd2, 13'd0,
                             32'h3f3b26a8, 5'h01, 5'h07,
                             13'd2, 13'd2, 13'd2, 13'd0, 13'd0,
                             13'd0, 5'h01);
        consume_success_beat(8'd3, OP_SILU, 13'd2, 13'd1,
                             32'hbe89b2b1, 5'h01, 5'h07,
                             13'd2, 13'd2, 13'd2, 13'd0, 13'd0,
                             13'd0, 5'h01);

        // SWIGLU role/order向量，MUL actual mask/count与flags OR。
        issue_cmd(OP_SWIGLU, 13'd2, 8'd4);
        send_input(32'h3f800000, 32'h40000000);
        send_input(32'hbf800000, 32'h40000000);
        consume_success_beat(8'd4, OP_SWIGLU, 13'd2, 13'd0,
                             32'h3fbb26a8, 5'h01, 5'h17,
                             13'd2, 13'd2, 13'd2, 13'd0, 13'd2,
                             13'd0, 5'h01);
        consume_success_beat(8'd4, OP_SWIGLU, 13'd2, 13'd1,
                             32'hbf09b2b1, 5'h01, 5'h17,
                             13'd2, 13'd2, 13'd2, 13'd0, 13'd2,
                             13'd0, 5'h01);

        // 13-bit MAX_ELEMS成功tensor：SOFTPLUS全bypass使首/尾地址和6144计数可见。
        issue_cmd(OP_SOFTPLUS, 13'd6144, 8'd5);
        for (i = 0; i < 6144; i = i + 1) begin
            max_raw = 32'h41a00001 + i;
            send_input(max_raw, 32'h5a5a0000 ^ i);
        end
        if (out_valid_o) begin
            $fatal(1, "MAX tensor became visible before all scalar terminals");
        end
        for (i = 0; i < 6144; i = i + 1) begin
            max_raw = 32'h41a00001 + i;
            consume_success_beat(8'd5, OP_SOFTPLUS, 13'd6144, i[12:0],
                                 max_raw, 5'h00, 5'h00,
                                 13'd0, 13'd0, 13'd0, 13'd0, 13'd0,
                                 13'd6144, 5'h00);
        end

        // external nonfinite first：仍capture完整N，scalar/primitive全0。
        issue_cmd(OP_SIGMOID, 13'd3, 8'd10);
        send_input(32'h7f800000, 32'h0);
        send_input(32'h3f800000, 32'h0);
        send_input(32'hbf800000, 32'h0);
        consume_error(8'd10, OP_SIGMOID, 13'd3, 4'd1,
                      13'd3, 13'd0, 13'd0, 13'd0, 5'd0,
                      13'd0, 13'd0, 13'd0, 13'd0, 13'd0,
                      13'd0, 1'b1, 13'd0);

        // SWIGLU src1 middle nonfinite。
        issue_cmd(OP_SWIGLU, 13'd3, 8'd11);
        send_input(32'h3f800000, 32'h40000000);
        send_input(32'h3f800000, 32'h7fc00000);
        send_input(32'h3f800000, 32'h40000000);
        consume_error(8'd11, OP_SWIGLU, 13'd3, 4'd1,
                      13'd3, 13'd0, 13'd0, 13'd0, 5'd0,
                      13'd0, 13'd0, 13'd0, 13'd0, 13'd0,
                      13'd0, 1'b1, 13'd1);

        // last-beat bad_next反例：旧sticky仍0时也必须terminal，不得误进EXEC。
        issue_cmd(OP_SILU, 13'd3, 8'd12);
        send_input(32'h3f800000, 32'h0);
        send_input(32'hbf800000, 32'h0);
        send_input(32'h7fa00001, 32'h0);
        consume_error(8'd12, OP_SILU, 13'd3, 4'd1,
                      13'd3, 13'd0, 13'd0, 13'd0, 5'd0,
                      13'd0, 13'd0, 13'd0, 13'd0, 13'd0,
                      13'd0, 1'b1, 13'd2);

        // command preflight errors在cmd_fire edge terminal，active严格为1且fail index无效。
        issue_cmd(3'd4, 13'd1, 8'd13);
        consume_error(8'd13, 3'd4, 13'd1, 4'd1,
                      13'd0, 13'd0, 13'd0, 13'd0, 5'd0,
                      13'd0, 13'd0, 13'd0, 13'd0, 13'd0,
                      13'd0, 1'b0, 13'd0);
        issue_cmd(OP_SIGMOID, 13'd0, 8'd14);
        consume_error(8'd14, OP_SIGMOID, 13'd0, 4'd1,
                      13'd0, 13'd0, 13'd0, 13'd0, 5'd0,
                      13'd0, 13'd0, 13'd0, 13'd0, 13'd0,
                      13'd0, 1'b0, 13'd0);
        issue_cmd(OP_SIGMOID, 13'd6145, 8'd15);
        consume_error(8'd15, OP_SIGMOID, 13'd6145, 4'd1,
                      13'd0, 13'd0, 13'd0, 13'd0, 5'd0,
                      13'd0, 13'd0, 13'd0, 13'd0, 13'd0,
                      13'd0, 1'b0, 13'd0);

        // input stall由timestamp自然计入；capture期间scalar request保持0。
        issue_cmd(OP_SIGMOID, 13'd1, 8'd16);
        wait_negedges(9);
        if (dut.work_scalar_launch_count_q !== 13'd0) begin
            $fatal(1, "input stall launched scalar");
        end
        send_input(32'h00000000, 32'h0);
        consume_success_beat(8'd16, OP_SIGMOID, 13'd1, 13'd0,
                             32'h3f000000, 5'h00, 5'h07,
                             13'd1, 13'd1, 13'd1, 13'd0, 13'd0,
                             13'd0, 5'h00);

        // 双bank：旧tensor EXEC期间新command held；terminal后才接受年轻tensor。
        out_ready_i = 1'b0;
        issue_cmd(OP_SWIGLU, 13'd2, 8'd40);
        send_input(32'h3f800000, 32'h40000000);
        send_input(32'hbf800000, 32'h40000000);
        wait_element_exp_wait(13'd0);
        @(negedge clk_i);
        cmd_opcode_i = OP_SOFTPLUS;
        cmd_length_i = 13'd1;
        cmd_tag_i = 8'd41;
        cmd_valid_i = 1'b1;
        blocked_cycles = 0;
        while (cmd_ready_o !== 1'b1) begin
            if ((dut.src0_mem_q[1] !== 32'hbf800000) ||
                (dut.src1_mem_q[1] !== 32'h40000000)) begin
                $fatal(1, "SWIGLU source pair overwritten during older compute");
            end
            @(negedge clk_i);
            blocked_cycles = blocked_cycles + 1;
            if (blocked_cycles > 1000000) begin
                $fatal(1, "younger command never received post-terminal credit");
            end
        end
        if (blocked_cycles == 0) begin
            $fatal(1, "source owner did not block younger command");
        end
        @(posedge clk_i);
        @(negedge clk_i);
        cmd_valid_i = 1'b0;
        wait_output(8'd40);
        held_out_bundle = out_bundle;
        hold_check_en = 1'b1;
        send_input(32'h41a00001, 32'h33330000);
        while (dut.bank1_state_q !== BANK_READY_OK) begin
            @(negedge clk_i);
        end
        if ((out_tag_o !== 8'd40) || (dut.fifo_count_q !== 2'd2)) begin
            $fatal(1, "READY tail bypassed FILL/READY head order");
        end

        // 两bank full时第三command保持1000 cycles，不做pop fall-through。
        @(negedge clk_i);
        cmd_opcode_i = 3'd7;
        cmd_length_i = 13'd1;
        cmd_tag_i = 8'd42;
        cmd_valid_i = 1'b1;
        third_desc_before = tb_next_desc;
        for (i = 0; i < 1000; i = i + 1) begin
            @(negedge clk_i);
            if (cmd_ready_o || (dut.fifo_count_q !== 2'd2)) begin
                $fatal(1, "third command received credit while both banks occupied");
            end
        end
        hold_check_en = 1'b0;

        // Drain bank0 older两beat；last pop edge前count=2，所以第三command仍不能同拍接受。
        consume_success_beat(8'd40, OP_SWIGLU, 13'd2, 13'd0,
                             32'h3fbb26a8, 5'h01, 5'h17,
                             13'd2, 13'd2, 13'd2, 13'd0, 13'd2,
                             13'd0, 5'h01);
        consume_success_beat(8'd40, OP_SWIGLU, 13'd2, 13'd1,
                             32'hbf09b2b1, 5'h01, 5'h17,
                             13'd2, 13'd2, 13'd2, 13'd0, 13'd2,
                             13'd0, 5'h01);
        if (tb_next_desc !== third_desc_before) begin
            $fatal(1, "full FIFO used forbidden same-edge pop credit");
        end

        // 现在bank1是older head、bank0是FREE；接受第三错误command到bank0形成bank号逆序。
        while (cmd_ready_o !== 1'b1) begin
            @(negedge clk_i);
        end
        @(posedge clk_i);
        @(negedge clk_i);
        cmd_valid_i = 1'b0;
        if ((dut.fifo_count_q !== 2'd2) ||
            (dut.order_fifo_q[dut.fifo_rd_ptr_q] !== 1'b1) ||
            (dut.bank0_state_q !== BANK_READY_ERR) ||
            (out_tag_o !== 8'd41)) begin
            $fatal(1, "bank1 older/bank0 younger order topology mismatch");
        end
        consume_success_beat(8'd41, OP_SOFTPLUS, 13'd1, 13'd0,
                             32'h41a00001, 5'h00, 5'h00,
                             13'd0, 13'd0, 13'd0, 13'd0, 13'd0,
                             13'd1, 5'h00);
        consume_error(8'd42, 3'd7, 13'd1, 4'd1,
                      13'd0, 13'd0, 13'd0, 13'd0, 5'd0,
                      13'd0, 13'd0, 13'd0, 13'd0, 13'd0,
                      13'd0, 1'b0, 13'd0);

        // count=1时不同FREE bank push与head error pop同edge，count保持1。
        issue_cmd(3'd4, 13'd1, 8'd43);
        wait_output(8'd43);
        @(negedge clk_i);
        cmd_opcode_i = 3'd5;
        cmd_length_i = 13'd1;
        cmd_tag_i = 8'd44;
        cmd_valid_i = 1'b1;
        out_ready_i = 1'b1;
        if (!cmd_ready_o || !out_valid_o || !out_last_o ||
            (dut.fifo_count_q !== 2'd1)) begin
            $fatal(1, "push+pop setup invalid");
        end
        @(posedge clk_i);
        @(negedge clk_i);
        cmd_valid_i = 1'b0;
        out_ready_i = 1'b0;
        if ((dut.fifo_count_q !== 2'd1) || (out_tag_o !== 8'd44)) begin
            $fatal(1, "push+pop did not conserve FIFO/order");
        end
        consume_error(8'd44, 3'd5, 13'd1, 4'd1,
                      13'd0, 13'd0, 13'd0, 13'd0, 5'd0,
                      13'd0, 13'd0, 13'd0, 13'd0, 13'd0,
                      13'd0, 1'b0, 13'd0);

        // error completion hold同样逐位稳定且active snapshot不增长。
        issue_cmd(3'd6, 13'd1, 8'd45);
        wait_output(8'd45);
        held_out_bundle = out_bundle;
        hold_check_en = 1'b1;
        wait_negedges(320);
        hold_check_en = 1'b0;
        consume_error(8'd45, 3'd6, 13'd1, 4'd1,
                      13'd0, 13'd0, 13'd0, 13'd0, 5'd0,
                      13'd0, 13'd0, 13'd0, 13'd0, 13'd0,
                      13'd0, 1'b0, 13'd0);

        // 两个descriptor故意复用同一tag；order/timestamp必须以接受序号区分。
        issue_cmd(3'd4, 13'd1, 8'd46);
        issue_cmd(3'd5, 13'd1, 8'd46);
        consume_error(8'd46, 3'd4, 13'd1, 4'd1,
                      13'd0, 13'd0, 13'd0, 13'd0, 5'd0,
                      13'd0, 13'd0, 13'd0, 13'd0, 13'd0,
                      13'd0, 1'b0, 13'd0);
        consume_error(8'd46, 3'd5, 13'd1, 4'd1,
                      13'd0, 13'd0, 13'd0, 13'd0, 5'd0,
                      13'd0, 13'd0, 13'd0, 13'd0, 13'd0,
                      13'd0, 1'b0, 13'd0);

        // scalar code2位于element1：element0 partial raw不可见，失败actual mask仍聚合。
        issue_cmd(OP_SIGMOID, 13'd2, 8'd60);
        send_input(32'h3f800000, 32'h0);
        send_input(32'hbf800000, 32'h0);
        inject_scalar_error(13'd1, 4'd2, 7);
        consume_error(8'd60, OP_SIGMOID, 13'd2, 4'd2,
                      13'd2, 13'd2, 13'd2, 13'd1, 5'h07,
                      13'd2, 13'd1, 13'd1, 13'd0, 13'd0,
                      13'd0, 1'b1, 13'd1);

        // 第一项SOFTPLUS真实bypass后，第二项scalar error；empty completion仍保留bypass=1。
        issue_cmd(OP_SOFTPLUS, 13'd2, 8'd65);
        send_input(32'h41a00001, 32'h0);
        send_input(32'h3f800000, 32'h0);
        inject_scalar_error(13'd1, 4'd2, 7);
        consume_error(8'd65, OP_SOFTPLUS, 13'd2, 4'd2,
                      13'd2, 13'd2, 13'd2, 13'd1, 5'h01,
                      13'd1, 13'd0, 13'd0, 13'd0, 13'd0,
                      13'd1, 1'b1, 13'd1);

        // 防御性scalar code1与protocol code4逐码原样传播。
        issue_cmd(OP_SIGMOID, 13'd1, 8'd61);
        send_input(32'h3f800000, 32'h0);
        inject_scalar_error(13'd0, 4'd1, 0);
        consume_error(8'd61, OP_SIGMOID, 13'd1, 4'd1,
                      13'd1, 13'd1, 13'd1, 13'd0, 5'h01,
                      13'd1, 13'd0, 13'd0, 13'd0, 13'd0,
                      13'd0, 1'b1, 13'd0);
        issue_cmd(OP_SIGMOID, 13'd1, 8'd62);
        send_input(32'h3f800000, 32'h0);
        inject_scalar_error(13'd0, 4'd4, 0);
        consume_error(8'd62, OP_SIGMOID, 13'd1, 4'd4,
                      13'd1, 13'd1, 13'd1, 13'd0, 5'h01,
                      13'd1, 13'd0, 13'd0, 13'd0, 13'd0,
                      13'd0, 1'b1, 13'd0);

        // deadline normal response由timeout胜出code3；deadline fatal response由fatal优先code2。
        issue_cmd(OP_SIGMOID, 13'd1, 8'd63);
        send_input(32'h3f800000, 32'h0);
        inject_deadline_exp_response(1'b0);
        consume_error(8'd63, OP_SIGMOID, 13'd1, 4'd3,
                      13'd1, 13'd1, 13'd1, 13'd0, 5'h01,
                      13'd1, 13'd0, 13'd0, 13'd0, 13'd0,
                      13'd0, 1'b1, 13'd0);
        issue_cmd(OP_SIGMOID, 13'd1, 8'd64);
        send_input(32'h3f800000, 32'h0);
        inject_deadline_exp_response(1'b1);
        consume_error(8'd64, OP_SIGMOID, 13'd1, 4'd2,
                      13'd1, 13'd1, 13'd1, 13'd0, 5'h01,
                      13'd1, 13'd0, 13'd0, 13'd0, 13'd0,
                      13'd0, 1'b1, 13'd0);

        // resident scalar期间literal parent非法编码：唯一code4、完整quarantine，
        // 不施加global reset即可clean recovery，旧scalar不能留下held response。
        issue_cmd(OP_SIGMOID, 13'd1, 8'd66);
        send_input(32'h3f800000, 32'h0);
        inject_parent_controller_fault();
        consume_error(8'd66, OP_SIGMOID, 13'd1, 4'd4,
                      13'd1, 13'd1, 13'd0, 13'd0, 5'h00,
                      13'd0, 13'd0, 13'd0, 13'd0, 13'd0,
                      13'd0, 1'b1, 13'd0);
        issue_cmd(OP_SOFTPLUS, 13'd1, 8'd67);
        send_input(32'h41a00033, 32'h89abcdef);
        consume_success_beat(8'd67, OP_SOFTPLUS, 13'd1, 13'd0,
                             32'h41a00033, 5'h00, 5'h00,
                             13'd0, 13'd0, 13'd0, 13'd0, 13'd0,
                             13'd1, 5'h00);

        // reset取消CAPTURE，不产生补偿completion。
        issue_cmd(OP_SIGMOID, 13'd2, 8'd70);
        send_input(32'h3f800000, 32'h0);
        reset_dut();
        wait_negedges(5);
        if (out_valid_o) begin
            $fatal(1, "reset CAPTURE published stale completion");
        end

        // reset取消scalar resident。
        issue_cmd(OP_SIGMOID, 13'd1, 8'd71);
        send_input(32'h3f800000, 32'h0);
        wait_element_exp_wait(13'd0);
        reset_dut();
        wait_negedges(5);
        if (out_valid_o) begin
            $fatal(1, "reset scalar resident published stale completion");
        end

        // reset取消READY head/tail与两bank full。
        out_ready_i = 1'b0;
        issue_cmd(3'd4, 13'd1, 8'd72);
        issue_cmd(3'd5, 13'd1, 8'd73);
        if ((dut.fifo_count_q !== 2'd2) || !out_valid_o) begin
            $fatal(1, "reset full-bank fixture not established");
        end
        reset_dut();

        // reset后两个不同raw pattern clean recovery，证明data array stale无资格。
        issue_cmd(OP_SOFTPLUS, 13'd1, 8'd80);
        send_input(32'h41a00011, 32'h12345678);
        consume_success_beat(8'd80, OP_SOFTPLUS, 13'd1, 13'd0,
                             32'h41a00011, 5'h00, 5'h00,
                             13'd0, 13'd0, 13'd0, 13'd0, 13'd0,
                             13'd1, 5'h00);
        issue_cmd(OP_SOFTPLUS, 13'd1, 8'd81);
        send_input(32'h41a00022, 32'h87654321);
        consume_success_beat(8'd81, OP_SOFTPLUS, 13'd1, 13'd0,
                             32'h41a00022, 5'h00, 5'h00,
                             13'd0, 13'd0, 13'd0, 13'd0, 13'd0,
                             13'd1, 5'h00);

        wait_negedges(10);
        if (busy_o || out_valid_o || dut.source_owner_valid_q ||
            (dut.fifo_count_q !== 2'd0)) begin
            $fatal(1, "engine not quiescent at end of test");
        end
        if (timestamp_negative_reject_count < 2) begin
            $fatal(1, "timestamp oracle did not exercise off-by-one rejection");
        end

        $display("[NPU-UNARY-GLU-TENSOR][PASS]");
        $finish;
    end

endmodule
