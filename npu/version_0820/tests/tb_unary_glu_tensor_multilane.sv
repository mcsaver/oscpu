`timescale 1ns/1ps

module tb_unary_glu_tensor_multilane #(
    parameter integer LANES = 4
);
    localparam logic [2:0] OP_SIGMOID  = 3'd0;
    localparam logic [2:0] OP_SOFTPLUS = 3'd1;
    localparam logic [2:0] OP_SILU     = 3'd2;
    localparam logic [2:0] OP_SWIGLU   = 3'd3;

    localparam integer TB_MAX_ELEMS = 6144;
    localparam integer TB_MAX_DESCS = 256;
    localparam logic [12:0] LANES_U13 =
        (LANES == 8) ? 13'd8 : 13'd4;
    localparam logic [3:0] LANES_U4 =
        (LANES == 8) ? 4'd8 : 4'd4;
    localparam integer HIGH_LANE = LANES - 1;
    localparam integer SECOND_HIGH_LANE = LANES - 2;
    localparam logic [12:0] HIGH_LANE_U13 =
        (LANES == 8) ? 13'd7 : 13'd3;
    localparam logic [12:0] SECOND_HIGH_LANE_U13 =
        (LANES == 8) ? 13'd6 : 13'd2;

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

    TensorNpuUnaryGluTensorEngineMultiLane #(
        .MAX_ELEMS(6144),
        .ELEMENT_TIMEOUT_CYCLES(256),
        .LANES(LANES)
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

    // ------------------------------------------------------------------
    // 独立descriptor/timestamp oracle，只以公开command/input/output和真实lane
    // boundary handshake建立terminal，不读取DUT tensor_terminal谓词。
    // ------------------------------------------------------------------
    longint unsigned tb_ts;
    longint unsigned desc_start_ts [0:TB_MAX_DESCS-1];
    longint unsigned desc_capture_complete_ts [0:TB_MAX_DESCS-1];
    longint unsigned desc_first_req_ts [0:TB_MAX_DESCS-1];
    longint unsigned desc_last_rsp_ts [0:TB_MAX_DESCS-1];
    longint unsigned desc_terminal_ts [0:TB_MAX_DESCS-1];
    logic [7:0] desc_tag [0:TB_MAX_DESCS-1];
    bit desc_terminal_seen [0:TB_MAX_DESCS-1];
    integer desc_fifo [0:1];
    integer desc_rd_ptr;
    integer desc_wr_ptr;
    integer desc_count;
    integer next_desc;

    bit work_valid;
    logic [7:0] work_desc;
    logic [2:0] work_opcode;
    logic [12:0] work_length;
    logic [12:0] work_capture_count;
    logic [12:0] work_success_count;
    bit work_bad_seen;
    bit protocol_terminal_arm;
    integer timestamp_exact_accept_count;
    integer timestamp_minus_one_reject_count;
    integer timestamp_plus_one_reject_count;

    wire tb_cmd_accept = cmd_valid_i && cmd_ready_o;
    wire tb_input_accept = in_valid_i && in_ready_o;
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

    // Production timestamp检查与expected+/-1 self-test共享同一4-state
    // comparator；只有真实返回reject才增加对应负向计数。
    function automatic bit timestamp_matches(
        input logic [63:0] observed,
        input logic [63:0] expected
    );
        begin
            timestamp_matches = (observed === expected);
        end
    endfunction

    // ------------------------------------------------------------------
    // Lane owner/residue/exact-once scoreboard。真实handshake逐index计数。
    // ------------------------------------------------------------------
    integer launch_hits [0:TB_MAX_ELEMS-1];
    integer terminal_hits [0:TB_MAX_ELEMS-1];
    bit lane_inflight [0:7];
    logic [12:0] lane_owned_index [0:7];
    bit track_lanes;
    integer track_length;
    integer inflight_count;
    integer max_inflight_count;
    integer max_global_inflight;
    bit rsp_group_seen [0:8];
    bit perf_desc_valid;
    integer perf_desc_id;
    integer perf_req_count;
    integer perf_rsp_count;
    integer perf_cmd_accept_ts;
    integer perf_capture_complete_ts;
    integer perf_first_req_ts;
    integer perf_last_rsp_ts;
    integer perf_bank_commit_ts;
    integer perf_compute_cycles;

    integer mon_lane;
    integer mon_rsp_count;
    integer mon_ok_count;
    integer mon_bad_count;
    integer mon_index;
    integer mon_next_inflight;
    task automatic scoreboard_step;
      begin
        if (rst_i) begin
            tb_ts = 0;
            desc_fifo[0] = -1;
            desc_fifo[1] = -1;
            desc_rd_ptr = 0;
            desc_wr_ptr = 0;
            desc_count = 0;
            next_desc = 0;
            work_valid = 1'b0;
            work_desc = 8'hff;
            work_opcode = 3'b0;
            work_length = 13'b0;
            work_capture_count = 13'b0;
            work_success_count = 13'b0;
            work_bad_seen = 1'b0;
            protocol_terminal_arm = 1'b0;
            perf_desc_valid = 1'b0;
            perf_desc_id = -1;
            perf_req_count = 0;
            perf_rsp_count = 0;
            inflight_count = 0;
            for (mon_lane = 0; mon_lane < 8; mon_lane = mon_lane + 1) begin
                lane_inflight[mon_lane] = 1'b0;
                lane_owned_index[mon_lane] = 13'b0;
            end
        end else begin
            mon_rsp_count = 0;
            mon_ok_count = 0;
            mon_bad_count = 0;
            mon_next_inflight = inflight_count;

            if (out_valid_o) begin
                if (desc_count <= 0) begin
                    $fatal(1, "output visible without accepted descriptor");
                end
                if (!desc_terminal_seen[desc_fifo[desc_rd_ptr]]) begin
                    $fatal(1, "output visible before independent terminal");
                end
                if (out_tag_o !== desc_tag[desc_fifo[desc_rd_ptr]]) begin
                    $fatal(1, "output tag does not match independent FIFO head");
                end
            end

            if (tb_cmd_accept) begin
                if (next_desc >= TB_MAX_DESCS) begin
                    $fatal(1, "descriptor storage exhausted");
                end
                desc_start_ts[next_desc] = tb_ts;
                desc_terminal_ts[next_desc] = 0;
                desc_capture_complete_ts[next_desc] = 0;
                desc_first_req_ts[next_desc] = 0;
                desc_last_rsp_ts[next_desc] = 0;
                desc_tag[next_desc] = cmd_tag_i;
                desc_terminal_seen[next_desc] = 1'b0;
                desc_fifo[desc_wr_ptr] = next_desc;
                desc_wr_ptr = desc_wr_ptr ^ 1;
                if (cmd_tag_i === 8'd24) begin
                    if ((cmd_opcode_i !== OP_SIGMOID) ||
                        (cmd_length_i !== 13'd32)) begin
                        $fatal(1, "PERF descriptor identity drift");
                    end
                    if (perf_desc_valid) begin
                        $fatal(1, "duplicate PERF descriptor identity");
                    end
                    perf_desc_valid = 1'b1;
                    perf_desc_id = next_desc;
                    perf_req_count = 0;
                    perf_rsp_count = 0;
                end
                if (tb_command_legal(cmd_opcode_i, cmd_length_i)) begin
                    if (work_valid) begin
                        $fatal(1, "accepted a second source owner");
                    end
                    work_valid = 1'b1;
                    work_desc = next_desc[7:0];
                    work_opcode = cmd_opcode_i;
                    work_length = cmd_length_i;
                    work_capture_count = 13'b0;
                    work_success_count = 13'b0;
                    work_bad_seen = 1'b0;
                end else begin
                    desc_terminal_ts[next_desc] = tb_ts;
                    desc_terminal_seen[next_desc] = 1'b1;
                end
                next_desc = next_desc + 1;
            end

            if (tb_input_accept) begin
                if (!work_valid || (work_capture_count >= work_length)) begin
                    $fatal(1, "input accepted outside independent capture");
                end
                if (tb_external_nonfinite(in_src0_bits_i[30:23]) ||
                    ((work_opcode == OP_SWIGLU) &&
                     tb_external_nonfinite(in_src1_bits_i[30:23]))) begin
                    work_bad_seen = 1'b1;
                end
                work_capture_count = work_capture_count + 13'd1;
                if (perf_desc_valid &&
                    (work_desc == perf_desc_id[7:0]) &&
                    (work_capture_count == work_length)) begin
                    desc_capture_complete_ts[work_desc] = tb_ts;
                end
                if (work_capture_count == work_length) begin
                    if (work_bad_seen) begin
                        desc_terminal_ts[work_desc] = tb_ts;
                        desc_terminal_seen[work_desc] = 1'b1;
                        work_valid = 1'b0;
                    end
                end
            end

            if (dut.ctrl_state_q == dut.CTRL_QUARANTINE) begin
                mon_next_inflight = 0;
                for (mon_lane = 0; mon_lane < LANES;
                     mon_lane = mon_lane + 1) begin
                    lane_inflight[mon_lane] = 1'b0;
                end
            end

            for (mon_lane = 0; mon_lane < LANES;
                 mon_lane = mon_lane + 1) begin
                if (dut.lane_req_fire[mon_lane] &&
                    dut.lane_rsp_fire[mon_lane]) begin
                    $fatal(1,
                           "same lane performed response-to-request fall-through lane=%0d",
                           mon_lane);
                end
                if (dut.lane_req_fire[mon_lane]) begin
                    mon_index = {19'b0, dut.lane_index_q[mon_lane]};
                    if (!work_valid ||
                        (work_capture_count != work_length) || work_bad_seen) begin
                        $fatal(1, "lane request crossed independent capture barrier");
                    end
                    if ((mon_index < 0) || (mon_index >= work_length) ||
                        ((mon_index % LANES) != mon_lane)) begin
                        $fatal(1, "lane residue/tail mismatch lane=%0d index=%0d",
                               mon_lane, mon_index);
                    end
                    if (lane_inflight[mon_lane]) begin
                        $fatal(1, "lane accepted a second resident request");
                    end
                    lane_inflight[mon_lane] = 1'b1;
                    lane_owned_index[mon_lane] = mon_index[12:0];
                    mon_next_inflight = mon_next_inflight + 1;
                    if (perf_desc_valid &&
                        (work_desc == perf_desc_id[7:0])) begin
                        if (perf_req_count == 0) begin
                            desc_first_req_ts[work_desc] = tb_ts;
                        end
                        perf_req_count = perf_req_count + 1;
                    end
                    if (track_lanes) begin
                        launch_hits[mon_index] = launch_hits[mon_index] + 1;
                        if (launch_hits[mon_index] != 1) begin
                            $fatal(1, "logical index launched more than once index=%0d",
                                   mon_index);
                        end
                    end
                end

                if (dut.lane_rsp_fire[mon_lane]) begin
                    mon_rsp_count = mon_rsp_count + 1;
                    if (!lane_inflight[mon_lane]) begin
                        $fatal(1, "lane terminal lacked TB owner lane=%0d", mon_lane);
                    end
                    mon_index = {19'b0, dut.lane_index_q[mon_lane]};
                    if (lane_owned_index[mon_lane] !== mon_index[12:0]) begin
                        $fatal(1, "lane terminal index changed from owner payload");
                    end
                    lane_inflight[mon_lane] = 1'b0;
                    mon_next_inflight = mon_next_inflight - 1;
                    if (perf_desc_valid &&
                        (work_desc == perf_desc_id[7:0])) begin
                        perf_rsp_count = perf_rsp_count + 1;
                        if (perf_rsp_count == 32) begin
                            desc_last_rsp_ts[work_desc] = tb_ts;
                        end
                    end
                    if (track_lanes) begin
                        terminal_hits[mon_index] = terminal_hits[mon_index] + 1;
                        if (terminal_hits[mon_index] != 1) begin
                            $fatal(1, "logical index terminal repeated index=%0d",
                                   mon_index);
                        end
                    end
                    if (dut.lane_error[mon_lane]) begin
                        mon_bad_count = mon_bad_count + 1;
                    end else begin
                        mon_ok_count = mon_ok_count + 1;
                    end
                end
            end

            inflight_count = mon_next_inflight;
            if (inflight_count > max_inflight_count) begin
                max_inflight_count = inflight_count;
            end
            if (inflight_count > max_global_inflight) begin
                max_global_inflight = inflight_count;
            end
            if ((mon_rsp_count >= 0) && (mon_rsp_count <= 8) &&
                (mon_rsp_count != 0)) begin
                rsp_group_seen[mon_rsp_count] = 1'b1;
            end

            if (protocol_terminal_arm) begin
                if (!work_valid) begin
                    $fatal(1, "protocol fixture lacked live descriptor");
                end
                desc_terminal_ts[work_desc] = tb_ts;
                desc_terminal_seen[work_desc] = 1'b1;
                work_valid = 1'b0;
                protocol_terminal_arm = 1'b0;
            end else if (mon_rsp_count != 0) begin
                if (!work_valid) begin
                    $fatal(1, "lane terminal lacked live tensor descriptor");
                end
                if (mon_bad_count != 0) begin
                    desc_terminal_ts[work_desc] = tb_ts;
                    desc_terminal_seen[work_desc] = 1'b1;
                    work_valid = 1'b0;
                end else begin
                    if ((work_success_count + mon_ok_count[12:0]) ==
                        work_length) begin
                        desc_terminal_ts[work_desc] = tb_ts;
                        desc_terminal_seen[work_desc] = 1'b1;
                        work_valid = 1'b0;
                    end
                    work_success_count =
                        work_success_count + mon_ok_count[12:0];
                end
            end

            if (tb_output_pop) begin
                if (desc_count <= 0) begin
                    $fatal(1, "independent descriptor FIFO underflow");
                end
                desc_rd_ptr = desc_rd_ptr ^ 1;
            end
            case ({tb_cmd_accept, tb_output_pop})
                2'b10: desc_count = desc_count + 1;
                2'b01: desc_count = desc_count - 1;
                default: desc_count = desc_count;
            endcase

            if ((dut.ctrl_state_q == dut.CTRL_CAPTURE) &&
                (|dut.lane_req_valid)) begin
                $fatal(1, "lane request valid asserted before complete capture");
            end
            if ((dut.fifo_count_q == 2'd2) && cmd_ready_o) begin
                $fatal(1, "FIFO full exposed command credit");
            end
            if (dut.source_owner_valid_q && cmd_ready_o) begin
                $fatal(1, "source owner exposed command credit");
            end
            if (dut.work_scalar_terminal_count_q >
                dut.work_scalar_launch_count_q) begin
                $fatal(1, "terminal count exceeded launch count");
            end
            if (({19'b0, dut.work_scalar_launch_count_q} -
                 {19'b0, dut.work_scalar_terminal_count_q}) > LANES) begin
                $fatal(1, "resident lane count exceeded LANES");
            end

            tb_ts = tb_ts + 1;
        end
      end
    endtask

    initial begin : scoreboard_process
      forever begin
        @(posedge clk_i);
        scoreboard_step();
      end
    end

    bit hold_check_en;
    logic [300:0] held_out_bundle;
    always @(negedge clk_i) begin
        if (hold_check_en && (out_bundle !== held_out_bundle)) begin
            $fatal(1, "output bundle changed under backpressure");
        end
    end

    task automatic wait_negedges(input integer cycles);
        integer wait_i;
        begin
            for (wait_i = 0; wait_i < cycles; wait_i = wait_i + 1) begin
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
            if (!cmd_ready_o || in_ready_o || out_valid_o || busy_o ||
                (dut.fifo_count_q != 2'd0) || dut.source_owner_valid_q ||
                (dut.bank_state_q[0] != dut.BANK_FREE) ||
                (dut.bank_state_q[1] != dut.BANK_FREE)) begin
                $fatal(1, "reset did not restore clean multilane engine");
            end
        end
    endtask

    task automatic begin_track(input integer length);
        integer track_i;
        begin
            track_lanes = 1'b0;
            for (track_i = 0; track_i < length; track_i = track_i + 1) begin
                launch_hits[track_i] = 0;
                terminal_hits[track_i] = 0;
            end
            for (track_i = 0; track_i < 8; track_i = track_i + 1) begin
                lane_inflight[track_i] = 1'b0;
                lane_owned_index[track_i] = 13'b0;
            end
            track_length = length;
            inflight_count = 0;
            max_inflight_count = 0;
            track_lanes = 1'b1;
        end
    endtask

    task automatic check_exact_success(input integer expected_max_inflight);
        integer check_i;
        begin
            for (check_i = 0; check_i < track_length; check_i = check_i + 1) begin
                if ((launch_hits[check_i] != 1) ||
                    (terminal_hits[check_i] != 1)) begin
                    $fatal(1, "exact-once mismatch index=%0d launch=%0d terminal=%0d",
                           check_i, launch_hits[check_i], terminal_hits[check_i]);
                end
            end
            if (inflight_count != 0) begin
                $fatal(1, "successful tensor left TB lane owners resident");
            end
            if (max_inflight_count != expected_max_inflight) begin
                $fatal(1, "max inflight mismatch got=%0d expected=%0d",
                       max_inflight_count, expected_max_inflight);
            end
            track_lanes = 1'b0;
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
            while (!cmd_ready_o) begin
                @(negedge clk_i);
                guard = guard + 1;
                if (guard > 3000000) begin
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
            while (!in_ready_o) begin
                @(negedge clk_i);
                guard = guard + 1;
                if (guard > 3000000) begin
                    $fatal(1, "input timeout raw=%08x", src0);
                end
            end
            @(posedge clk_i);
            @(negedge clk_i);
            in_valid_i = 1'b0;
        end
    endtask

    task automatic wait_output(input logic [7:0] tag);
        integer guard;
        begin
            guard = 0;
            while (!out_valid_o) begin
                @(negedge clk_i);
                guard = guard + 1;
                if (guard > 5000000) begin
                    $fatal(1, "output timeout tag=%0d", tag);
                end
            end
            if (out_tag_o !== tag) begin
                $fatal(1, "output order mismatch got=%0d expected=%0d",
                       out_tag_o, tag);
            end
        end
    endtask

    task automatic check_timestamp(input logic [7:0] tag);
        integer head_desc;
        longint unsigned expected_active;
        begin
            if (desc_count <= 0) begin
                $fatal(1, "timestamp check lacked descriptor head");
            end
            head_desc = desc_fifo[desc_rd_ptr];
            if ((head_desc < 0) || !desc_terminal_seen[head_desc]) begin
                $fatal(1, "timestamp terminal missing tag=%0d", tag);
            end
            expected_active =
                desc_terminal_ts[head_desc] - desc_start_ts[head_desc] + 1;
            if (!timestamp_matches(out_active_cycles_o,
                                   expected_active[63:0])) begin
                $fatal(1, "active timestamp mismatch tag=%0d got=%0d expected=%0d",
                       tag, out_active_cycles_o, expected_active);
            end
            timestamp_exact_accept_count =
                timestamp_exact_accept_count + 1;
            if (timestamp_matches(out_active_cycles_o,
                                  expected_active[63:0] - 64'd1)) begin
                $fatal(1, "timestamp oracle accepted expected-1 tag=%0d", tag);
            end else begin
                timestamp_minus_one_reject_count =
                    timestamp_minus_one_reject_count + 1;
            end
            if (timestamp_matches(out_active_cycles_o,
                                  expected_active[63:0] + 64'd1)) begin
                $fatal(1, "timestamp oracle accepted expected+1 tag=%0d", tag);
            end else begin
                timestamp_plus_one_reject_count =
                    timestamp_plus_one_reject_count + 1;
            end
        end
    endtask

    task automatic check_success_meta(
        input logic [7:0] tag,
        input logic [2:0] opcode,
        input logic [12:0] length,
        input logic [4:0] call_mask,
        input logic [4:0] flags_or
    );
        logic [12:0] exp_count;
        logic [12:0] add_count;
        logic [12:0] div_count;
        logic [12:0] log_count;
        logic [12:0] mul_count;
        logic [12:0] bypass_count;
        begin
            exp_count = call_mask[0] ? length : 13'b0;
            add_count = call_mask[1] ? length : 13'b0;
            div_count = call_mask[2] ? length : 13'b0;
            log_count = call_mask[3] ? length : 13'b0;
            mul_count = call_mask[4] ? length : 13'b0;
            bypass_count =
                ((opcode == OP_SOFTPLUS) && (call_mask == 5'b0)) ?
                    length : 13'b0;
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
        end
    endtask

    longint unsigned cross_signature;
    task automatic consume_constant_success(
        input logic [7:0] tag,
        input logic [2:0] opcode,
        input logic [12:0] length,
        input logic [31:0] expected_raw,
        input logic [4:0] expected_flags,
        input logic [4:0] expected_mask,
        input bit update_signature
    );
        integer beat;
        begin
            out_ready_i = 1'b0;
            for (beat = 0; beat < length; beat = beat + 1) begin
                wait_output(tag);
                if (!out_keep_o ||
                    (out_sop_o !== (beat == 0)) ||
                    (out_last_o !==
                     (beat == ({19'b0, length} - 32'd1))) ||
                    (out_elem_index_o !== beat[12:0]) ||
                    (out_result_bits_o !== expected_raw) ||
                    (out_flags_o !== expected_flags)) begin
                    $fatal(1, "success beat mismatch tag=%0d index=%0d",
                           tag, beat);
                end
                check_success_meta(tag, opcode, length,
                                   expected_mask, expected_flags);
                if (beat == 0) begin
                    check_timestamp(tag);
                end
                if (update_signature) begin
                    cross_signature =
                        {cross_signature[62:0], cross_signature[63]} ^
                        {19'b0, out_elem_index_o, out_result_bits_o};
                end
                out_ready_i = 1'b1;
                @(posedge clk_i);
                @(negedge clk_i);
                out_ready_i = 1'b0;
            end
        end
    endtask

    task automatic run_constant_success(
        input logic [7:0] tag,
        input logic [2:0] opcode,
        input integer length,
        input logic [31:0] src0,
        input logic [31:0] src1,
        input logic [31:0] expected_raw,
        input logic [4:0] expected_flags,
        input logic [4:0] expected_mask,
        input bit update_signature
    );
        integer element_i;
        integer expected_max;
        begin
            begin_track(length);
            issue_cmd(opcode, length[12:0], tag);
            for (element_i = 0; element_i < length;
                 element_i = element_i + 1) begin
                send_input(src0, src1);
            end
            consume_constant_success(tag, opcode, length[12:0],
                                     expected_raw, expected_flags,
                                     expected_mask, update_signature);
            expected_max = (length < LANES) ? length : LANES;
            check_exact_success(expected_max);
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
                $fatal(1, "error metadata mismatch tag=%0d code=%0d", tag, code);
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
            track_lanes = 1'b0;
        end
    endtask

    task automatic check_quarantine_and_recovery;
        integer q_lane;
        begin
            @(negedge clk_i);
            if ((dut.ctrl_state_q !== dut.CTRL_QUARANTINE) ||
                !dut.lane_child_rst || cmd_ready_o || in_ready_o ||
                (|dut.lane_req_valid) || (|dut.lane_rsp_ready)) begin
                $fatal(1,
                       "quarantine mismatch state=%0d child_rst=%0b cmd=%0b in=%0b req=%b rsp=%b",
                       dut.ctrl_state_q, dut.lane_child_rst,
                       cmd_ready_o, in_ready_o,
                       dut.lane_req_valid, dut.lane_rsp_ready);
            end
            for (q_lane = 0; q_lane < LANES; q_lane = q_lane + 1) begin
                if (dut.lane_owner_valid_q[q_lane]) begin
                    $fatal(1, "quarantine retained a lane parent owner");
                end
            end
            @(posedge clk_i);
            @(negedge clk_i);
            if ((dut.ctrl_state_q !== dut.CTRL_IDLE) ||
                dut.lane_child_rst || !cmd_ready_o ||
                (|dut.lane_rsp_valid)) begin
                $fatal(1, "quarantine did not restore clean command credit");
            end
        end
    endtask

    task automatic arm_protocol_terminal;
        begin
            protocol_terminal_arm = 1'b1;
            #1;
            if (!dut.protocol_fault_now || cmd_ready_o || in_ready_o ||
                (|dut.lane_req_valid) || (|dut.lane_rsp_ready)) begin
                $fatal(1, "protocol fault did not revoke same-cycle credits");
            end
        end
    endtask

    task automatic wait_lane_state(
        input integer lane,
        input logic [1:0] wanted_state
    );
        integer guard;
        begin
            guard = 0;
            while (dut.lane_state_q[lane] !== wanted_state) begin
                @(negedge clk_i);
                guard = guard + 1;
                if (guard > 1000000) begin
                    $fatal(1, "lane state timeout lane=%0d state=%0d",
                           lane, wanted_state);
                end
            end
        end
    endtask

    task automatic wait_lane0_exp_wait;
        integer guard;
        begin
            guard = 0;
            while (dut.g_lane[0].u_element.state_q !== 4'd3) begin
                @(negedge clk_i);
                guard = guard + 1;
                if (guard > 1000000) begin
                    $fatal(1, "lane0 scalar did not reach EXP_WAIT");
                end
            end
        end
    endtask

    integer i;
    integer group_size;
    integer blocked_cycles;
    integer before_desc;
    logic [31:0] held_req_src0;
    logic [31:0] held_req_src1;
    logic [7:0] held_req_generation;
    logic [31:0] held_rsp_result;
    logic [4:0] held_rsp_flags;
    logic [12:0] held_lane_index;
    logic [31:0] max_raw;

    initial begin
        if ((LANES != 4) && (LANES != 8)) begin
            $fatal(1, "TB LANES must be 4 or 8");
        end

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
        track_lanes = 1'b0;
        track_length = 0;
        inflight_count = 0;
        max_inflight_count = 0;
        max_global_inflight = 0;
        perf_cmd_accept_ts = 0;
        perf_capture_complete_ts = 0;
        perf_first_req_ts = 0;
        perf_last_rsp_ts = 0;
        perf_bank_commit_ts = 0;
        perf_compute_cycles = 0;
        protocol_terminal_arm = 1'b0;
        timestamp_exact_accept_count = 0;
        timestamp_minus_one_reject_count = 0;
        timestamp_plus_one_reject_count = 0;
        cross_signature = 64'h6d756c74696c616e;
        for (i = 0; i < 9; i = i + 1) begin
            rsp_group_seen[i] = 1'b0;
        end
        for (i = 0; i < 8; i = i + 1) begin
            lane_inflight[i] = 1'b0;
            lane_owned_index[i] = 13'b0;
        end

        wait_negedges(4);
        rst_i = 1'b0;
        @(negedge clk_i);

        // 四opcode + 冻结长度集合1,L-1,L,L+1,2L+3。
        run_constant_success(8'd1, OP_SIGMOID, 1,
                             32'h3f800000, 32'h0,
                             32'h3f3b26a8, 5'h01, 5'h07, 1'b0);
        run_constant_success(8'd2, OP_SOFTPLUS, LANES-1,
                             32'h00000000, 32'h0,
                             32'h3f317218, 5'h01, 5'h0b, 1'b0);
        run_constant_success(8'd3, OP_SILU, LANES,
                             32'h3f800000, 32'h0,
                             32'h3f3b26a8, 5'h01, 5'h07, 1'b0);
        run_constant_success(8'd4, OP_SWIGLU, LANES+1,
                             32'h3f800000, 32'h40000000,
                             32'h3fbb26a8, 5'h01, 5'h17, 1'b0);
        run_constant_success(8'd5, OP_SOFTPLUS, (2*LANES)+3,
                             32'h41a00001, 32'hdeadbeef,
                             32'h41a00001, 5'h00, 5'h00, 1'b0);

        // canonical special/bypass/flags向量。
        run_constant_success(8'd6, OP_SIGMOID, 1,
                             32'hc2c80000, 32'h0,
                             32'h00000000, 5'h05, 5'h07, 1'b0);
        run_constant_success(8'd7, OP_SOFTPLUS, 1,
                             32'h41a00000, 32'h0,
                             32'h41a00000, 5'h01, 5'h0b, 1'b0);
        run_constant_success(8'd8, OP_SILU, 1,
                             32'h00000001, 32'h0,
                             32'h00000000, 5'h03, 5'h07, 1'b0);
        run_constant_success(8'd9, OP_SWIGLU, 1,
                             32'h00000001, 32'h40000000,
                             32'h00000000, 5'h03, 5'h17, 1'b0);

        // 2..LANES路同拍success response的next-popcount覆盖。
        for (group_size = 2; group_size <= LANES;
             group_size = group_size + 1) begin
            run_constant_success(8'd10 + group_size[7:0], OP_SOFTPLUS,
                                 group_size,
                                 32'h41a00021, 32'h0,
                                 32'h41a00021, 5'h00, 5'h00, 1'b0);
        end

        // 相同N=32 no-stall non-bypass cross-config case；runner比较从首个
        // child req_fire到最后child rsp_fire（含首尾edge）的compute cycles。
        cross_signature = 64'h6d756c74696c616e;
        perf_cmd_accept_ts = 0;
        perf_capture_complete_ts = 0;
        perf_first_req_ts = 0;
        perf_last_rsp_ts = 0;
        perf_bank_commit_ts = 0;
        perf_compute_cycles = 0;
        begin_track(32);
        issue_cmd(OP_SIGMOID, 13'd32, 8'd24);
        for (i = 0; i < 32; i = i + 1) begin
            send_input(32'h3f800000, 32'h0);
        end
        perf_cmd_accept_ts = desc_start_ts[perf_desc_id][31:0];
        perf_capture_complete_ts =
            desc_capture_complete_ts[perf_desc_id][31:0];
        if (!perf_desc_valid || (perf_desc_id < 0) ||
            (desc_tag[perf_desc_id] !== 8'd24) ||
            (perf_cmd_accept_ts == 0) ||
            (perf_capture_complete_ts == 0) ||
            (perf_cmd_accept_ts != desc_start_ts[perf_desc_id][31:0]) ||
            (perf_capture_complete_ts !=
             (tb_ts[31:0] - 32'd1))) begin
            $fatal(1,
                   "PERF command/capture observation mismatch valid=%0d desc=%0d cmd=%0d desc_start=%0d capture=%0d tb_prev=%0d",
                   perf_desc_valid, perf_desc_id, perf_cmd_accept_ts,
                   desc_start_ts[perf_desc_id], perf_capture_complete_ts,
                   tb_ts - 64'd1);
        end
        wait_output(8'd24);
        perf_first_req_ts = desc_first_req_ts[perf_desc_id][31:0];
        perf_last_rsp_ts = desc_last_rsp_ts[perf_desc_id][31:0];
        perf_bank_commit_ts = tb_ts[31:0] - 32'd1;
        perf_compute_cycles =
            perf_last_rsp_ts - perf_first_req_ts + 1;
        if ((perf_req_count != 32) || (perf_rsp_count != 32) ||
            (perf_capture_complete_ts < perf_cmd_accept_ts) ||
            (perf_first_req_ts != (perf_capture_complete_ts + 1)) ||
            (perf_last_rsp_ts < perf_first_req_ts) ||
            (perf_first_req_ts == 0) || (perf_last_rsp_ts == 0) ||
            (perf_last_rsp_ts != desc_terminal_ts[perf_desc_id][31:0]) ||
            (perf_bank_commit_ts != perf_last_rsp_ts) ||
            (perf_compute_cycles <= 1) ||
            (dut.bank_state_q[dut.fifo_head_bank] !== dut.BANK_READY_OK) ||
            (out_active_cycles_o !==
             {32'b0, (perf_bank_commit_ts - perf_cmd_accept_ts + 32'd1)})) begin
            $fatal(1,
                   "PERF timestamp mismatch cmd=%0d capture=%0d first_req=%0d last_rsp=%0d commit=%0d compute=%0d req=%0d rsp=%0d active=%0d",
                   perf_cmd_accept_ts, perf_capture_complete_ts,
                   perf_first_req_ts, perf_last_rsp_ts,
                   perf_bank_commit_ts, perf_compute_cycles,
                   perf_req_count, perf_rsp_count, out_active_cycles_o);
        end
        consume_constant_success(8'd24, OP_SIGMOID, 13'd32,
                                 32'h3f3b26a8, 5'h01, 5'h07, 1'b1);
        check_exact_success(LANES);
        $display("[NPU-UNARY-GLU-TENSOR-MULTILANE][PERF] LANES=%0d N=32 OP=SIGMOID BYPASS=0 CMD_ACCEPT=%0d CAPTURE_COMPLETE=%0d FIRST_REQ=%0d LAST_RSP=%0d BANK_COMMIT=%0d COMPUTE_CYCLES=%0d SIGNATURE=%016x RAW=3f3b26a8 FLAGS=01 MASK=07 CAPTURE=32 LAUNCH=32 TERMINAL=32 SUCCESS=32 EXP=32 ADD=32 DIV=32 LOG=0 MUL=0 BYPASS_COUNT=0",
                 LANES, perf_cmd_accept_ts, perf_capture_complete_ts,
                 perf_first_req_ts, perf_last_rsp_ts,
                 perf_bank_commit_ts, perf_compute_cycles,
                 cross_signature);

        // 完整capture前零launch；lane2独立REQ stall并保持payload/index/generation。
        begin_track(LANES + 3);
        issue_cmd(OP_SOFTPLUS, LANES_U13 + 13'd3, 8'd30);
        force dut.g_lane[2].u_element.req_ready_o = 1'b0;
        for (i = 0; i < (LANES + 3); i = i + 1) begin
            send_input(32'h41a00031, 32'h12340000 + i);
        end
        wait_lane_state(2, dut.LANE_REQ);
        held_lane_index = dut.lane_index_q[2];
        held_req_src0 = dut.g_lane[2].u_element.src0_bits_i;
        held_req_src1 = dut.g_lane[2].u_element.src1_bits_i;
        held_req_generation = dut.lane_generation_q[2];
        wait_negedges(6);
        if (!dut.lane_req_valid[2] || dut.lane_req_fire[2] ||
            (dut.lane_index_q[2] !== held_lane_index) ||
            (dut.g_lane[2].u_element.src0_bits_i !== held_req_src0) ||
            (dut.g_lane[2].u_element.src1_bits_i !== held_req_src1) ||
            (dut.lane_generation_q[2] !== held_req_generation) ||
            dut.lane_owner_valid_q[2]) begin
            $fatal(1, "lane2 REQ payload/owner changed under independent stall");
        end
        if (max_inflight_count != (LANES - 1)) begin
            $fatal(1, "unstalled lanes did not establish LANES-1 residents");
        end
        release dut.g_lane[2].u_element.req_ready_o;
        #1;
        if (!dut.lane_req_fire[2] || dut.lane_owner_valid_q[2]) begin
            $fatal(1, "released stalled lane lacked its unique request edge");
        end
        consume_constant_success(8'd30, OP_SOFTPLUS,
                                 LANES_U13 + 13'd3,
                                 32'h41a00031, 5'h00, 5'h00, 1'b0);
        check_exact_success(LANES - 1);

        // lane0 response hold：parent credit被fixture拉低时child完整payload稳定。
        begin_track(LANES);
        issue_cmd(OP_SOFTPLUS, LANES_U13, 8'd31);
        for (i = 0; i < LANES; i = i + 1) begin
            send_input(32'h41a00041, 32'h0);
        end
        while (!dut.lane_rsp_valid[0]) begin
            @(negedge clk_i);
        end
        force dut.g_lane[0].rsp_ready_credit = 1'b0;
        #1;
        if (dut.g_lane[0].rsp_ready_credit || dut.lane_rsp_ready[0] ||
            dut.g_lane[0].u_element.rsp_ready_i ||
            dut.lane_rsp_fire[0]) begin
            $fatal(1, "lane0 response credit force did not reach both owners");
        end
        held_rsp_result = dut.lane_result_bits[0];
        held_rsp_flags = dut.lane_flags[0];
        held_lane_index = dut.lane_index_q[0];
        wait_negedges(7);
        if (!dut.lane_rsp_valid[0] ||
            dut.g_lane[0].rsp_ready_credit || dut.lane_rsp_ready[0] ||
            dut.g_lane[0].u_element.rsp_ready_i ||
            dut.lane_rsp_fire[0] ||
            !dut.lane_owner_valid_q[0] ||
            (dut.lane_result_bits[0] !== held_rsp_result) ||
            (dut.lane_flags[0] !== held_rsp_flags) ||
            (dut.lane_index_q[0] !== held_lane_index)) begin
            $fatal(1, "lane0 response payload changed under hold");
        end
        release dut.g_lane[0].rsp_ready_credit;
        #1;
        if (!dut.g_lane[0].rsp_ready_credit ||
            !dut.lane_rsp_ready[0] ||
            !dut.g_lane[0].u_element.rsp_ready_i ||
            !dut.lane_rsp_fire[0] || !dut.lane_owner_valid_q[0] ||
            (dut.lane_result_bits[0] !== held_rsp_result) ||
            (dut.lane_flags[0] !== held_rsp_flags) ||
            (dut.lane_index_q[0] !== held_lane_index)) begin
            $fatal(1, "released response did not retain owner through fire edge");
        end
        consume_constant_success(8'd31, OP_SOFTPLUS, LANES_U13,
                                 32'h41a00041, 5'h00, 5'h00, 1'b0);
        check_exact_success(LANES);

        // external nonfinite first/middle/last均完整capture且零lane launch。
        begin_track(LANES + 1);
        issue_cmd(OP_SIGMOID, LANES_U13 + 13'd1, 8'd40);
        for (i = 0; i < (LANES + 1); i = i + 1) begin
            send_input((i == 0) ? 32'h7f800000 : 32'h3f800000, 32'h0);
        end
        consume_error(8'd40, OP_SIGMOID, LANES_U13 + 13'd1, 4'd1,
                      LANES_U13 + 13'd1, 13'd0, 13'd0, 13'd0, 5'd0,
                      13'd0, 13'd0, 13'd0, 13'd0, 13'd0,
                      13'd0, 1'b1, 13'd0);

        begin_track(LANES + 1);
        issue_cmd(OP_SWIGLU, LANES_U13 + 13'd1, 8'd41);
        for (i = 0; i < (LANES + 1); i = i + 1) begin
            send_input(32'h3f800000,
                       (i == (LANES/2)) ? 32'h7fc12345 : 32'h40000000);
        end
        consume_error(8'd41, OP_SWIGLU, LANES_U13 + 13'd1, 4'd1,
                      LANES_U13 + 13'd1, 13'd0, 13'd0, 13'd0, 5'd0,
                      13'd0, 13'd0, 13'd0, 13'd0, 13'd0,
                      13'd0, 1'b1, (LANES_U13 >> 1));

        begin_track(LANES + 1);
        issue_cmd(OP_SILU, LANES_U13 + 13'd1, 8'd42);
        for (i = 0; i < (LANES + 1); i = i + 1) begin
            send_input((i == LANES) ? 32'h7f800001 : 32'h3f800000, 32'h0);
        end
        consume_error(8'd42, OP_SILU, LANES_U13 + 13'd1, 4'd1,
                      LANES_U13 + 13'd1, 13'd0, 13'd0, 13'd0, 5'd0,
                      13'd0, 13'd0, 13'd0, 13'd0, 13'd0,
                      13'd0, 1'b1, LANES_U13);

        // immediate bad command terminal=cmd edge、active=1、零capture/scalar。
        issue_cmd(3'd7, 13'd1, 8'd43);
        consume_error(8'd43, 3'd7, 13'd1, 4'd1,
                      13'd0, 13'd0, 13'd0, 13'd0, 5'd0,
                      13'd0, 13'd0, 13'd0, 13'd0, 13'd0,
                      13'd0, 1'b0, 13'd0);
        issue_cmd(OP_SIGMOID, 13'd0, 8'd44);
        consume_error(8'd44, OP_SIGMOID, 13'd0, 4'd1,
                      13'd0, 13'd0, 13'd0, 13'd0, 5'd0,
                      13'd0, 13'd0, 13'd0, 13'd0, 13'd0,
                      13'd0, 1'b0, 13'd0);
        issue_cmd(OP_SIGMOID, 13'd6145, 8'd45);
        consume_error(8'd45, OP_SIGMOID, 13'd6145, 4'd1,
                      13'd0, 13'd0, 13'd0, 13'd0, 5'd0,
                      13'd0, 13'd0, 13'd0, 13'd0, 13'd0,
                      13'd0, 1'b0, 13'd0);

        // 同拍success+error：两个bad中最低逻辑index=1，code3；其余success/bypass保留。
        begin_track(LANES);
        issue_cmd(OP_SOFTPLUS, LANES_U13, 8'd50);
        for (i = 0; i < LANES; i = i + 1) begin
            send_input(32'h41a00051, 32'h0);
        end
        while ((dut.lane_rsp_valid & dut.lane_rsp_ready) != {LANES{1'b1}}) begin
            @(negedge clk_i);
        end
        force dut.g_lane[1].u_element.response_error_q = 1'b1;
        force dut.g_lane[1].u_element.response_error_code_q = 4'd3;
        force dut.g_lane[3].u_element.response_error_q = 1'b1;
        force dut.g_lane[3].u_element.response_error_code_q = 4'd2;
        #1;
        if ((dut.lane_rsp_fire !== {LANES{1'b1}}) ||
            !dut.lane_rsp_bad[1] || !dut.lane_rsp_bad[3] ||
            dut.lane_rsp_ok[1] || dut.lane_rsp_ok[3] ||
            (dut.rsp_fire_popcount_r !== LANES_U4) ||
            (dut.rsp_ok_popcount_r !== (LANES_U4 - 4'd2)) ||
            (dut.terminal_next !== LANES_U13) ||
            (dut.success_next !== (LANES_U13 - 13'd2)) ||
            (dut.lowest_error_index_r !== 13'd1) ||
            (dut.lowest_error_code_r !== 4'd3) ||
            !dut.scalar_error_terminal || !dut.tensor_terminal ||
            (dut.tensor_terminal_error_code !== 4'd3)) begin
            $fatal(1,
                   "fault-edge reduction mismatch fire=%b bad=%b ok=%b term=%0d success=%0d low=%0d code=%0d",
                   dut.lane_rsp_fire, dut.lane_rsp_bad, dut.lane_rsp_ok,
                   dut.terminal_next, dut.success_next,
                   dut.lowest_error_index_r, dut.lowest_error_code_r);
        end
        @(posedge clk_i);
        #1;
        release dut.g_lane[1].u_element.response_error_q;
        release dut.g_lane[1].u_element.response_error_code_q;
        release dut.g_lane[3].u_element.response_error_q;
        release dut.g_lane[3].u_element.response_error_code_q;
        if ((dut.ctrl_state_q !== dut.CTRL_QUARANTINE) ||
            (dut.bank_state_q[dut.active_bank_q] !== dut.BANK_READY_ERR) ||
            (dut.bank_scalar_launch_count_q[dut.active_bank_q] !== LANES_U13) ||
            (dut.bank_scalar_terminal_count_q[dut.active_bank_q] !== LANES_U13) ||
            (dut.bank_success_result_count_q[dut.active_bank_q] !==
             (LANES_U13 - 13'd2)) ||
            (dut.bank_bypass_count_q[dut.active_bank_q] !==
             (LANES_U13 - 13'd2)) ||
            !dut.bank_fail_elem_valid_q[dut.active_bank_q] ||
            (dut.bank_fail_elem_index_q[dut.active_bank_q] !== 13'd1)) begin
            $fatal(1,
                   "post-fault snapshot mismatch state=%0d bank=%0d launch=%0d terminal=%0d success=%0d bypass=%0d fail=%0d/%0d",
                   dut.ctrl_state_q,
                   dut.bank_state_q[dut.active_bank_q],
                   dut.bank_scalar_launch_count_q[dut.active_bank_q],
                   dut.bank_scalar_terminal_count_q[dut.active_bank_q],
                   dut.bank_success_result_count_q[dut.active_bank_q],
                   dut.bank_bypass_count_q[dut.active_bank_q],
                   dut.bank_fail_elem_valid_q[dut.active_bank_q],
                   dut.bank_fail_elem_index_q[dut.active_bank_q]);
        end
        check_quarantine_and_recovery();
        consume_error(8'd50, OP_SOFTPLUS, LANES_U13, 4'd3,
                      LANES_U13, LANES_U13, LANES_U13,
                      LANES_U13 - 13'd2, 5'd0,
                      13'd0, 13'd0, 13'd0, 13'd0, 13'd0,
                      LANES_U13 - 13'd2, 1'b1, 13'd1);
        run_constant_success(8'd51, OP_SOFTPLUS, 1,
                             32'h41a00052, 32'h0,
                             32'h41a00052, 5'h00, 5'h00, 1'b0);

        // 单lane timeout；其它lane WAIT、lane2 REQ共存。error edge释放lane2，
        // 其真实launch与lane0 terminal同拍进入next诊断后再被quarantine取消。
        begin_track(LANES);
        issue_cmd(OP_SIGMOID, LANES_U13, 8'd52);
        force dut.g_lane[2].u_element.req_ready_o = 1'b0;
        for (i = 0; i < LANES; i = i + 1) begin
            send_input(32'h3f800000, 32'h0);
        end
        wait_lane0_exp_wait();
        force dut.g_lane[0].u_element.watchdog_q = 32'd256;
        while (!dut.lane_rsp_valid[0]) begin
            @(negedge clk_i);
        end
        release dut.g_lane[0].u_element.watchdog_q;
        if (!dut.lane_error[0] ||
            (dut.lane_error_code[0] != 4'd3) ||
            (dut.lane_state_q[2] != dut.LANE_REQ)) begin
            $fatal(1, "timeout fixture did not preserve REQ/WAIT coexistence");
        end
        release dut.g_lane[2].u_element.req_ready_o;
        @(posedge clk_i);
        check_quarantine_and_recovery();
        consume_error(8'd52, OP_SIGMOID, LANES_U13, 4'd3,
                      LANES_U13, LANES_U13, 13'd1, 13'd0, 5'h01,
                      13'd1, 13'd0, 13'd0, 13'd0, 13'd0,
                      13'd0, 1'b1, 13'd0);
        run_constant_success(8'd53, OP_SOFTPLUS, 1,
                             32'h41a00053, 32'h0,
                             32'h41a00053, 5'h00, 5'h00, 1'b0);

        // 高lane wrong-owner：所有lane已launch但零terminal，合法lane0不得
        // 抢占actual fault lane的logical index（L4必须命中lane3）。
        begin_track(LANES);
        issue_cmd(OP_SIGMOID, LANES_U13, 8'd54);
        for (i = 0; i < LANES; i = i + 1) begin
            send_input(32'h3f800000, 32'h0);
        end
        wait_lane_state(HIGH_LANE, dut.LANE_WAIT);
        dut.lane_owner_valid_q[HIGH_LANE] = 1'b0;
        #1;
        if ((dut.lane_owner_valid_q[HIGH_LANE] !== 1'b0) ||
            !dut.lane_fault_mask_r[HIGH_LANE] ||
            !dut.lane_fault_min_valid_r ||
            (dut.lane_fault_min_index_r !== HIGH_LANE_U13)) begin
            $fatal(1,
                   "high-lane wrong-owner cause mismatch lane=%0d mask=%b min=%0d/%0d",
                   HIGH_LANE, dut.lane_fault_mask_r,
                   dut.lane_fault_min_valid_r,
                   dut.lane_fault_min_index_r);
        end
        arm_protocol_terminal();
        @(posedge clk_i);
        check_quarantine_and_recovery();
        consume_error(8'd54, OP_SIGMOID, LANES_U13, 4'd4,
                      LANES_U13, LANES_U13, 13'd0, 13'd0, 5'd0,
                      13'd0, 13'd0, 13'd0, 13'd0, 13'd0,
                      13'd0, 1'b1, HIGH_LANE_U13);

        // L8专属lane7 generation mismatch；低lane均保持合法resident。
        if (LANES == 8) begin
            begin_track(LANES);
            issue_cmd(OP_SIGMOID, LANES_U13, 8'd92);
            for (i = 0; i < LANES; i = i + 1) begin
                send_input(32'h3f800000, 32'h0);
            end
            wait_lane_state(HIGH_LANE, dut.LANE_WAIT);
            dut.lane_generation_q[HIGH_LANE] =
                dut.active_generation_q ^ 8'h01;
            #1;
            if (!dut.lane_fault_mask_r[HIGH_LANE] ||
                !dut.lane_fault_min_valid_r ||
                (dut.lane_fault_min_index_r !== HIGH_LANE_U13)) begin
                $fatal(1,
                       "lane7 generation fault cause mismatch mask=%b min=%0d/%0d",
                       dut.lane_fault_mask_r,
                       dut.lane_fault_min_valid_r,
                       dut.lane_fault_min_index_r);
            end
            arm_protocol_terminal();
            @(posedge clk_i);
            check_quarantine_and_recovery();
            consume_error(8'd92, OP_SIGMOID, LANES_U13, 4'd4,
                          LANES_U13, LANES_U13, 13'd0, 13'd0, 5'd0,
                          13'd0, 13'd0, 13'd0, 13'd0, 13'd0,
                          13'd0, 1'b1, HIGH_LANE_U13);
        end

        // 高lane literal illegal state也必须报告actual fault index。
        begin_track(LANES);
        issue_cmd(OP_SIGMOID, LANES_U13, 8'd55);
        for (i = 0; i < LANES; i = i + 1) begin
            send_input(32'h3f800000, 32'h0);
        end
        wait_lane_state(HIGH_LANE, dut.LANE_WAIT);
        dut.lane_state_q[HIGH_LANE] = 2'b11;
        #1;
        if ((dut.lane_state_q[HIGH_LANE] !== 2'b11) ||
            !dut.lane_fault_mask_r[HIGH_LANE] ||
            !dut.lane_fault_min_valid_r ||
            (dut.lane_fault_min_index_r !== HIGH_LANE_U13)) begin
            $fatal(1, "illegal-high-lane cause mismatch lane=%0d min=%0d/%0d",
                   HIGH_LANE, dut.lane_fault_min_valid_r,
                   dut.lane_fault_min_index_r);
        end
        arm_protocol_terminal();
        @(posedge clk_i);
        check_quarantine_and_recovery();
        consume_error(8'd55, OP_SIGMOID, LANES_U13, 4'd4,
                      LANES_U13, LANES_U13, 13'd0, 13'd0, 5'd0,
                      13'd0, 13'd0, 13'd0, 13'd0, 13'd0,
                      13'd0, 1'b1, HIGH_LANE_U13);

        // 高tail lane处于IDLE却持有owner；低lane0是合法REQ participant，
        // 仍只能报告实际fault的高lane index。
        begin_track(1);
        issue_cmd(OP_SIGMOID, 13'd1, 8'd93);
        send_input(32'h3f800000, 32'h0);
        while (!((dut.ctrl_state_q == dut.CTRL_EXEC) &&
                 (dut.lane_state_q[0] == dut.LANE_REQ) &&
                 (dut.lane_state_q[HIGH_LANE] == dut.LANE_IDLE))) begin
            @(negedge clk_i);
        end
        dut.lane_owner_valid_q[HIGH_LANE] = 1'b1;
        #1;
        if (!dut.lane_fault_mask_r[HIGH_LANE] ||
            !dut.lane_fault_min_valid_r ||
            (dut.lane_fault_min_index_r !== HIGH_LANE_U13)) begin
            $fatal(1,
                   "IDLE-with-owner high-lane cause mismatch mask=%b min=%0d/%0d",
                   dut.lane_fault_mask_r,
                   dut.lane_fault_min_valid_r,
                   dut.lane_fault_min_index_r);
        end
        arm_protocol_terminal();
        @(posedge clk_i);
        check_quarantine_and_recovery();
        consume_error(8'd93, OP_SIGMOID, 13'd1, 4'd4,
                      13'd1, 13'd0, 13'd0, 13'd0, 5'd0,
                      13'd0, 13'd0, 13'd0, 13'd0, 13'd0,
                      13'd0, 1'b1, HIGH_LANE_U13);

        // 同拍两个真实lane-local fault：合法低lane不参与，actual fault集合
        // {LANES-2,LANES-1}必须编码出LANES-2。
        begin_track(LANES);
        issue_cmd(OP_SIGMOID, LANES_U13, 8'd94);
        for (i = 0; i < LANES; i = i + 1) begin
            send_input(32'h3f800000, 32'h0);
        end
        wait_lane_state(HIGH_LANE, dut.LANE_WAIT);
        dut.lane_owner_valid_q[SECOND_HIGH_LANE] = 1'b0;
        dut.lane_owner_valid_q[HIGH_LANE] = 1'b0;
        #1;
        if (!dut.lane_fault_mask_r[SECOND_HIGH_LANE] ||
            !dut.lane_fault_mask_r[HIGH_LANE] ||
            !dut.lane_fault_min_valid_r ||
            (dut.lane_fault_min_index_r !== SECOND_HIGH_LANE_U13)) begin
            $fatal(1,
                   "two-lane actual fault min mismatch mask=%b min=%0d/%0d",
                   dut.lane_fault_mask_r,
                   dut.lane_fault_min_valid_r,
                   dut.lane_fault_min_index_r);
        end
        arm_protocol_terminal();
        @(posedge clk_i);
        check_quarantine_and_recovery();
        consume_error(8'd94, OP_SIGMOID, LANES_U13, 4'd4,
                      LANES_U13, LANES_U13, 13'd0, 13'd0, 5'd0,
                      13'd0, 13'd0, 13'd0, 13'd0, 13'd0,
                      13'd0, 1'b1, SECOND_HIGH_LANE_U13);

        // parent literal illegal state with resident scalar。
        begin_track(LANES);
        issue_cmd(OP_SIGMOID, LANES_U13, 8'd56);
        for (i = 0; i < LANES; i = i + 1) begin
            send_input(32'h3f800000, 32'h0);
        end
        wait_lane_state(0, dut.LANE_WAIT);
        dut.ctrl_state_q = 3'd7;
        #1;
        if ((dut.ctrl_state_q !== 3'd7) || dut.ctrl_state_valid_r ||
            !dut.controller_state_illegal ||
            dut.lane_fault_min_valid_r ||
            !dut.parent_participant_min_valid_r ||
            (dut.parent_participant_min_index_r !== 13'd0)) begin
            $fatal(1, "illegal-parent-state deposit did not reach controller");
        end
        arm_protocol_terminal();
        if (!dut.lane_child_rst) begin
            $fatal(1, "parent illegal state did not assert immediate child reset");
        end
        @(posedge clk_i);
        #1;
        if ((dut.ctrl_state_q !== dut.CTRL_QUARANTINE) ||
            (dut.bank_state_q[dut.active_bank_q] !== dut.BANK_READY_ERR) ||
            (dut.bank_error_code_q[dut.active_bank_q] !== 4'd4) ||
            !dut.bank_fail_elem_valid_q[dut.active_bank_q] ||
            (dut.bank_fail_elem_index_q[dut.active_bank_q] !== 13'd0)) begin
            $fatal(1,
                   "illegal parent state did not atomically snapshot code4 quarantine");
        end
        check_quarantine_and_recovery();
        consume_error(8'd56, OP_SIGMOID, LANES_U13, 4'd4,
                      LANES_U13, LANES_U13, 13'd0, 13'd0, 5'd0,
                      13'd0, 13'd0, 13'd0, 13'd0, 13'd0,
                      13'd0, 1'b1, 13'd0);

        // 有owner高lane ghost：首组bypass已真实success，高lane IDLE时伪造
        // held response；低lane0仍是合法REQ participant且不得抢cause index。
        begin_track(LANES + 1);
        issue_cmd(OP_SOFTPLUS, LANES_U13 + 13'd1, 8'd57);
        for (i = 0; i < (LANES + 1); i = i + 1) begin
            send_input(32'h41a00057, 32'h0);
        end
        while (!((dut.lane_state_q[HIGH_LANE] == dut.LANE_IDLE) &&
                 (dut.lane_state_q[0] == dut.LANE_REQ))) begin
            @(negedge clk_i);
        end
        force dut.g_lane[HIGH_LANE].u_element.rsp_valid_q = 1'b1;
        force dut.g_lane[HIGH_LANE].u_element.response_error_q = 1'b0;
        #1;
        if (!dut.lane_fault_mask_r[HIGH_LANE] ||
            !dut.lane_fault_min_valid_r ||
            (dut.lane_fault_min_index_r !== HIGH_LANE_U13)) begin
            $fatal(1,
                   "high-lane ghost cause mismatch mask=%b min=%0d/%0d",
                   dut.lane_fault_mask_r,
                   dut.lane_fault_min_valid_r,
                   dut.lane_fault_min_index_r);
        end
        arm_protocol_terminal();
        @(posedge clk_i);
        #1;
        release dut.g_lane[HIGH_LANE].u_element.rsp_valid_q;
        release dut.g_lane[HIGH_LANE].u_element.response_error_q;
        check_quarantine_and_recovery();
        consume_error(8'd57, OP_SOFTPLUS, LANES_U13 + 13'd1, 4'd4,
                      LANES_U13 + 13'd1, LANES_U13, LANES_U13,
                      LANES_U13, 5'd0,
                      13'd0, 13'd0, 13'd0, 13'd0, 13'd0,
                      LANES_U13, 1'b1, HIGH_LANE_U13);

        // 无owner ghost只清洗，不发布unmatched completion。
        if (busy_o || (dut.fifo_count_q != 0)) begin
            $fatal(1, "idle ghost fixture started with a descriptor");
        end
        force dut.g_lane[1].u_element.rsp_valid_q = 1'b1;
        #1;
        if (!dut.protocol_fault_now) begin
            $fatal(1, "idle ghost did not trigger parent protocol fault");
        end
        @(posedge clk_i);
        #1;
        release dut.g_lane[1].u_element.rsp_valid_q;
        check_quarantine_and_recovery();
        wait_negedges(3);
        if (out_valid_o || busy_o || (dut.fifo_count_q != 0)) begin
            $fatal(1, "ownerless ghost manufactured a completion");
        end
        run_constant_success(8'd58, OP_SOFTPLUS, 1,
                             32'h41a00058, 32'h0,
                             32'h41a00058, 5'h00, 5'h00, 1'b0);

        // 双bank：300-cycle held older output，younger compute成READY但不得越head。
        begin_track(2);
        issue_cmd(OP_SOFTPLUS, 13'd2, 8'd60);
        send_input(32'h41a00060, 32'h0);
        send_input(32'h41a00060, 32'h0);
        wait_output(8'd60);
        check_exact_success(2);
        held_out_bundle = out_bundle;
        hold_check_en = 1'b1;

        begin_track(1);
        issue_cmd(OP_SOFTPLUS, 13'd1, 8'd61);
        send_input(32'h41a00061, 32'h0);
        while (dut.bank_state_q[1] != dut.BANK_READY_OK) begin
            @(negedge clk_i);
        end
        check_exact_success(1);
        if ((out_tag_o != 8'd60) || (dut.fifo_count_q != 2'd2)) begin
            $fatal(1, "READY tail bypassed held FIFO head");
        end
        wait_negedges(300);

        // FIFO full禁止第三command，head last pop edge仍不fall-through。
        @(negedge clk_i);
        cmd_opcode_i = 3'd7;
        cmd_length_i = 13'd1;
        cmd_tag_i = 8'd62;
        cmd_valid_i = 1'b1;
        before_desc = next_desc;
        for (blocked_cycles = 0; blocked_cycles < 100;
             blocked_cycles = blocked_cycles + 1) begin
            @(negedge clk_i);
            if (cmd_ready_o || (dut.fifo_count_q != 2'd2)) begin
                $fatal(1, "third command received FIFO-full credit");
            end
        end
        hold_check_en = 1'b0;
        consume_constant_success(8'd60, OP_SOFTPLUS, 13'd2,
                                 32'h41a00060, 5'h00, 5'h00, 1'b0);
        if (next_desc != before_desc) begin
            $fatal(1, "FIFO full used forbidden same-edge pop credit");
        end
        while (!cmd_ready_o) begin
            @(negedge clk_i);
        end
        @(posedge clk_i);
        @(negedge clk_i);
        cmd_valid_i = 1'b0;
        consume_constant_success(8'd61, OP_SOFTPLUS, 13'd1,
                                 32'h41a00061, 5'h00, 5'h00, 1'b0);
        consume_error(8'd62, 3'd7, 13'd1, 4'd1,
                      13'd0, 13'd0, 13'd0, 13'd0, 5'd0,
                      13'd0, 13'd0, 13'd0, 13'd0, 13'd0,
                      13'd0, 1'b0, 13'd0);

        // count=1时不同FREE bank push + error head pop同edge守恒。
        issue_cmd(3'd4, 13'd1, 8'd63);
        wait_output(8'd63);
        @(negedge clk_i);
        cmd_opcode_i = 3'd5;
        cmd_length_i = 13'd1;
        cmd_tag_i = 8'd64;
        cmd_valid_i = 1'b1;
        out_ready_i = 1'b1;
        if (!cmd_ready_o || !out_valid_o || !out_last_o ||
            (dut.fifo_count_q != 2'd1)) begin
            $fatal(1, "push+pop setup invalid");
        end
        @(posedge clk_i);
        @(negedge clk_i);
        cmd_valid_i = 1'b0;
        out_ready_i = 1'b0;
        if ((dut.fifo_count_q != 2'd1) || (out_tag_o != 8'd64)) begin
            $fatal(1, "same-edge push+pop did not conserve order/count");
        end
        consume_error(8'd64, 3'd5, 13'd1, 4'd1,
                      13'd0, 13'd0, 13'd0, 13'd0, 5'd0,
                      13'd0, 13'd0, 13'd0, 13'd0, 13'd0,
                      13'd0, 1'b0, 13'd0);

        // duplicate tag按接受序号/FIFO order区分。
        issue_cmd(3'd4, 13'd1, 8'd65);
        issue_cmd(3'd5, 13'd1, 8'd65);
        consume_error(8'd65, 3'd4, 13'd1, 4'd1,
                      13'd0, 13'd0, 13'd0, 13'd0, 5'd0,
                      13'd0, 13'd0, 13'd0, 13'd0, 13'd0,
                      13'd0, 1'b0, 13'd0);
        consume_error(8'd65, 3'd5, 13'd1, 4'd1,
                      13'd0, 13'd0, 13'd0, 13'd0, 5'd0,
                      13'd0, 13'd0, 13'd0, 13'd0, 13'd0,
                      13'd0, 1'b0, 13'd0);

        // MAX_ELEMS=6144：全bypass，检查首尾、13-bit count、每index exact once。
        begin_track(6144);
        issue_cmd(OP_SOFTPLUS, 13'd6144, 8'd70);
        for (i = 0; i < 6144; i = i + 1) begin
            max_raw = 32'h41a10000 + i;
            send_input(max_raw, 32'h5a5a0000 ^ i);
        end
        out_ready_i = 1'b0;
        for (i = 0; i < 6144; i = i + 1) begin
            wait_output(8'd70);
            max_raw = 32'h41a10000 + i;
            if (!out_keep_o || (out_elem_index_o != i[12:0]) ||
                (out_result_bits_o != max_raw) || (out_flags_o != 0) ||
                (out_sop_o != (i == 0)) || (out_last_o != (i == 6143))) begin
                $fatal(1, "MAX_ELEMS output mismatch index=%0d", i);
            end
            check_success_meta(8'd70, OP_SOFTPLUS, 13'd6144, 5'd0, 5'd0);
            if (i == 0) begin
                check_timestamp(8'd70);
            end
            out_ready_i = 1'b1;
            @(posedge clk_i);
            @(negedge clk_i);
            out_ready_i = 1'b0;
        end
        check_exact_success(LANES);

        // global reset五阶段：CAPTURE、REQ hold、WAIT、last multiresponse、READY/output。
        issue_cmd(OP_SIGMOID, 13'd2, 8'd80);
        send_input(32'h3f800000, 32'h0);
        reset_dut();
        wait_negedges(2);
        if (out_valid_o) begin
            $fatal(1, "reset in CAPTURE published compensation output");
        end

        issue_cmd(OP_SOFTPLUS, LANES_U13, 8'd81);
        force dut.g_lane[0].u_element.req_ready_o = 1'b0;
        for (i = 0; i < LANES; i = i + 1) begin
            send_input(32'h41a00081, 32'h0);
        end
        wait_lane_state(0, dut.LANE_REQ);
        @(negedge clk_i);
        rst_i = 1'b1;
        release dut.g_lane[0].u_element.req_ready_o;
        wait_negedges(3);
        rst_i = 1'b0;
        @(negedge clk_i);
        if (out_valid_o || busy_o) begin
            $fatal(1, "reset in REQ hold left output/busy");
        end

        issue_cmd(OP_SIGMOID, LANES_U13, 8'd82);
        for (i = 0; i < LANES; i = i + 1) begin
            send_input(32'h3f800000, 32'h0);
        end
        wait_lane_state(0, dut.LANE_WAIT);
        reset_dut();
        if (out_valid_o) begin
            $fatal(1, "reset in WAIT published stale output");
        end

        issue_cmd(OP_SOFTPLUS, LANES_U13, 8'd83);
        for (i = 0; i < LANES; i = i + 1) begin
            send_input(32'h41a00083, 32'h0);
        end
        while ((dut.lane_rsp_valid & dut.lane_rsp_ready) != {LANES{1'b1}}) begin
            @(negedge clk_i);
        end
        rst_i = 1'b1;
        @(posedge clk_i);
        wait_negedges(2);
        rst_i = 1'b0;
        @(negedge clk_i);
        if (out_valid_o || busy_o) begin
            $fatal(1, "reset on last multiresponse edge committed a bank");
        end

        issue_cmd(OP_SOFTPLUS, 13'd1, 8'd84);
        send_input(32'h41a00084, 32'h0);
        wait_output(8'd84);
        held_out_bundle = out_bundle;
        hold_check_en = 1'b1;
        wait_negedges(5);
        reset_dut();
        if (out_valid_o || busy_o) begin
            $fatal(1, "reset in READY/output retained a bank");
        end

        // reset后两组不同raw pattern clean recovery。
        run_constant_success(8'd90, OP_SOFTPLUS, 1,
                             32'h41a00111, 32'h12345678,
                             32'h41a00111, 5'h00, 5'h00, 1'b0);
        run_constant_success(8'd91, OP_SOFTPLUS, 1,
                             32'h41a00222, 32'h87654321,
                             32'h41a00222, 5'h00, 5'h00, 1'b0);

        wait_negedges(10);
        if (busy_o || out_valid_o || dut.source_owner_valid_q ||
            (dut.fifo_count_q != 0) || (inflight_count != 0)) begin
            $fatal(1, "multilane engine not quiescent at end of TB");
        end
        for (group_size = 2; group_size <= LANES;
             group_size = group_size + 1) begin
            if (!rsp_group_seen[group_size]) begin
                $fatal(1, "missing multiresponse group size=%0d", group_size);
            end
        end
        if (max_global_inflight < LANES) begin
            $fatal(1, "never observed max simultaneous inflight=LANES");
        end
        if ((timestamp_exact_accept_count == 0) ||
            (timestamp_minus_one_reject_count == 0) ||
            (timestamp_plus_one_reject_count == 0)) begin
            $fatal(1,
                   "timestamp comparator coverage missing exact=%0d minus=%0d plus=%0d",
                   timestamp_exact_accept_count,
                   timestamp_minus_one_reject_count,
                   timestamp_plus_one_reject_count);
        end
        $display("[NPU-UNARY-GLU-TENSOR-MULTILANE][TIMESTAMP] LANES=%0d EXACT_ACCEPT=%0d EXPECTED_MINUS_ONE_REJECT=%0d EXPECTED_PLUS_ONE_REJECT=%0d",
                 LANES, timestamp_exact_accept_count,
                 timestamp_minus_one_reject_count,
                 timestamp_plus_one_reject_count);

        if (LANES == 4) begin
            $display("[NPU-UNARY-GLU-TENSOR-MULTILANE][LANES=4][PASS]");
        end else begin
            $display("[NPU-UNARY-GLU-TENSOR-MULTILANE][LANES=8][PASS]");
        end
        $finish;
    end

endmodule
