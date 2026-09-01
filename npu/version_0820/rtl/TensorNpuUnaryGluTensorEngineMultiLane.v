`timescale 1ns/1ps

// SPDX-License-Identifier: MIT
//
// TENSOR_NPU_UNARY_GLU_F32_RNE_V1 多 lane tensor reference engine。
// 阶段1/2a--2e与九项RTL topology冻结见：
// docs/UNARY_GLU_TENSOR_MULTILANE_RTL_CONTRACT.md
//
// 每个lane独占一个TensorNpuUnaryGluElement，并按index=k+m*LANES
// static residue工作。source staging、双result bank、2-entry order FIFO
// 与natural-order output gather仍是parent共享资源。
module TensorNpuUnaryGluTensorEngineMultiLane #(
    parameter integer MAX_ELEMS = 6144,
    parameter integer ELEMENT_TIMEOUT_CYCLES = 256,
    parameter integer LANES = 4
) (
    input  wire        clk_i,
    input  wire        rst_i,

    input  wire        cmd_valid_i,
    output wire        cmd_ready_o,
    input  wire [2:0]  cmd_opcode_i,
    input  wire [12:0] cmd_length_i,
    input  wire [7:0]  cmd_tag_i,
    output wire        busy_o,

    input  wire        in_valid_i,
    output wire        in_ready_o,
    input  wire [31:0] in_src0_bits_i,
    input  wire [31:0] in_src1_bits_i,

    output wire        out_valid_o,
    input  wire        out_ready_i,
    output wire        out_sop_o,
    output wire        out_last_o,
    output wire        out_keep_o,
    output wire [31:0] out_result_bits_o,
    output wire [4:0]  out_flags_o,
    output wire [12:0] out_elem_index_o,

    output wire [7:0]  out_tag_o,
    output wire [2:0]  out_opcode_o,
    output wire [12:0] out_length_o,
    output wire        out_error_o,
    output wire [3:0]  out_error_code_o,
    output wire [63:0] out_active_cycles_o,

    output wire [12:0] out_capture_count_o,
    output wire [12:0] out_scalar_launch_count_o,
    output wire [12:0] out_scalar_terminal_count_o,
    output wire [12:0] out_success_result_count_o,
    output wire [4:0]  out_child_call_mask_o,
    output wire [12:0] out_exp_req_count_o,
    output wire [12:0] out_add_req_count_o,
    output wire [12:0] out_div_req_count_o,
    output wire [12:0] out_log_req_count_o,
    output wire [12:0] out_mul_req_count_o,
    output wire [12:0] out_bypass_count_o,
    output wire [4:0]  out_tensor_flags_or_o,
    output wire        out_fail_elem_valid_o,
    output wire [12:0] out_fail_elem_index_o
);

    localparam [2:0] OP_SOFTPLUS = 3'd1;
    localparam [2:0] OP_SWIGLU   = 3'd3;

    localparam [3:0] ERR_OK          = 4'd0;
    localparam [3:0] ERR_UNSUPPORTED = 4'd1;
    localparam [3:0] ERR_PROTOCOL    = 4'd4;

    localparam [2:0] CTRL_IDLE       = 3'd0;
    localparam [2:0] CTRL_CAPTURE    = 3'd1;
    localparam [2:0] CTRL_EXEC       = 3'd2;
    localparam [2:0] CTRL_QUARANTINE = 3'd3;

    localparam [1:0] LANE_IDLE = 2'd0;
    localparam [1:0] LANE_REQ  = 2'd1;
    localparam [1:0] LANE_WAIT = 2'd2;

    localparam [2:0] BANK_FREE      = 3'd0;
    localparam [2:0] BANK_FILL      = 3'd1;
    localparam [2:0] BANK_READY_OK  = 3'd2;
    localparam [2:0] BANK_DRAIN     = 3'd3;
    localparam [2:0] BANK_READY_ERR = 3'd4;

    // 非法参数仍保持合法数组深度；PARAM_VALID使所有外部credit fail closed。
    localparam integer SAFE_STORAGE_ELEMS =
        ((MAX_ELEMS >= 1) && (MAX_ELEMS <= 6144)) ? MAX_ELEMS : 1;
    localparam integer SAFE_RESULT_ELEMS = 2 * SAFE_STORAGE_ELEMS;
    localparam integer PHYS_LANES =
        ((LANES == 4) || (LANES == 8)) ? LANES : 1;
    localparam [0:0] PARAM_VALID =
        ((LANES == 4) || (LANES == 8)) &&
        (MAX_ELEMS >= 1) && (MAX_ELEMS <= 6144) &&
        (ELEMENT_TIMEOUT_CYCLES > 0);
    localparam [31:0] MAX_ELEMS_U32 = MAX_ELEMS;
    localparam [12:0] LANES_U13 =
        (PHYS_LANES == 8) ? 13'd8 :
        (PHYS_LANES == 4) ? 13'd4 : 13'd1;
    localparam [13:0] SAFE_STORAGE_U14 = 14'(SAFE_STORAGE_ELEMS);

    function external_nonfinite;
        input [7:0] exponent;
        begin
            external_nonfinite = (exponent == 8'hff);
        end
    endfunction

    // ------------------------------------------------------------------
    // Shared source staging与parent controller。
    // ------------------------------------------------------------------
    reg [31:0] src0_mem_q [0:SAFE_STORAGE_ELEMS-1];
    reg [31:0] src1_mem_q [0:SAFE_STORAGE_ELEMS-1];

    reg [2:0]  ctrl_state_q;
    reg        ctrl_state_valid_r;
    reg        source_owner_valid_q;
    reg        active_bank_q;
    reg [2:0]  active_opcode_q;
    reg [12:0] active_length_q;
    reg [7:0]  generation_q;
    reg [7:0]  active_generation_q;
    reg [63:0] start_ts_q;
    reg [63:0] wall_ts_q;

    reg [12:0] capture_count_q;
    reg        external_bad_seen_q;
    reg [12:0] external_bad_index_q;

    reg [12:0] work_scalar_launch_count_q;
    reg [12:0] work_scalar_terminal_count_q;
    reg [12:0] work_success_result_count_q;
    reg [4:0]  work_child_call_mask_q;
    reg [12:0] work_exp_req_count_q;
    reg [12:0] work_add_req_count_q;
    reg [12:0] work_div_req_count_q;
    reg [12:0] work_log_req_count_q;
    reg [12:0] work_mul_req_count_q;
    reg [12:0] work_bypass_count_q;
    reg [4:0]  work_tensor_flags_or_q;

    // ------------------------------------------------------------------
    // Lane-local state。for-loop在综合时展开为PHYS_LANES份比较/owner逻辑。
    // ------------------------------------------------------------------
    reg [1:0]  lane_state_q [0:PHYS_LANES-1];
    reg        lane_owner_valid_q [0:PHYS_LANES-1];
    reg [12:0] lane_index_q [0:PHYS_LANES-1];
    reg [7:0]  lane_generation_q [0:PHYS_LANES-1];

    // ------------------------------------------------------------------
    // 两个逻辑result bank共享一个flat storage；bank offset显式选择。
    // 最多PHYS_LANES个互异static-residue地址同拍写入。
    // ------------------------------------------------------------------
    reg [31:0] result_mem_q [0:SAFE_RESULT_ELEMS-1];
    reg [4:0]  result_flags_mem_q [0:SAFE_RESULT_ELEMS-1];

    reg [2:0]  bank_state_q [0:1];
    reg [7:0]  bank_tag_q [0:1];
    reg [2:0]  bank_opcode_q [0:1];
    reg [12:0] bank_length_q [0:1];
    reg [3:0]  bank_error_code_q [0:1];
    reg [63:0] bank_active_cycles_q [0:1];
    reg [12:0] bank_capture_count_q [0:1];
    reg [12:0] bank_scalar_launch_count_q [0:1];
    reg [12:0] bank_scalar_terminal_count_q [0:1];
    reg [12:0] bank_success_result_count_q [0:1];
    reg [4:0]  bank_child_call_mask_q [0:1];
    reg [12:0] bank_exp_req_count_q [0:1];
    reg [12:0] bank_add_req_count_q [0:1];
    reg [12:0] bank_div_req_count_q [0:1];
    reg [12:0] bank_log_req_count_q [0:1];
    reg [12:0] bank_mul_req_count_q [0:1];
    reg [12:0] bank_bypass_count_q [0:1];
    reg [4:0]  bank_tensor_flags_or_q [0:1];
    reg        bank_fail_elem_valid_q [0:1];
    reg [12:0] bank_fail_elem_index_q [0:1];
    reg [12:0] bank_out_index_q [0:1];

    reg order_fifo_q [0:1];
    reg fifo_rd_ptr_q;
    reg fifo_wr_ptr_q;
    reg [1:0] fifo_count_q;

    wire bank0_free = (bank_state_q[0] == BANK_FREE);
    wire bank1_free = (bank_state_q[1] == BANK_FREE);
    wire exists_free_bank = bank0_free || bank1_free;
    wire alloc_bank = bank0_free ? 1'b0 : 1'b1;

    wire command_length_valid =
        (cmd_length_i != 13'b0) &&
        ({19'b0, cmd_length_i} <= MAX_ELEMS_U32);
    wire command_is_valid =
        PARAM_VALID && (cmd_opcode_i <= OP_SWIGLU) && command_length_valid;

    always @(*) begin
        ctrl_state_valid_r = 1'b1;
        case (ctrl_state_q)
            CTRL_IDLE, CTRL_CAPTURE, CTRL_EXEC,
            CTRL_QUARANTINE: ctrl_state_valid_r = 1'b1;
            default: ctrl_state_valid_r = 1'b0;
        endcase
    end

    wire controller_state_illegal = !ctrl_state_valid_r;

    // ------------------------------------------------------------------
    // PHYS_LANES份真实scalar child。resource不跨lane共享。
    // ------------------------------------------------------------------
    wire [PHYS_LANES-1:0] lane_req_valid;
    wire [PHYS_LANES-1:0] lane_req_ready;
    wire [PHYS_LANES-1:0] lane_rsp_valid;
    wire [PHYS_LANES-1:0] lane_rsp_ready;
    wire [PHYS_LANES-1:0] lane_error;
    wire [31:0] lane_result_bits [0:PHYS_LANES-1];
    wire [4:0]  lane_flags [0:PHYS_LANES-1];
    wire [3:0]  lane_error_code [0:PHYS_LANES-1];
    wire [4:0]  lane_child_call_mask [0:PHYS_LANES-1];
    /* verilator lint_off UNUSEDSIGNAL */
    wire [31:0] lane_active_cycles_unused [0:PHYS_LANES-1];
    /* verilator lint_on UNUSEDSIGNAL */

    reg [PHYS_LANES-1:0] lane_fault_mask_r;
    reg lane_protocol_fault_r;
    reg lane_fault_min_valid_r;
    reg [12:0] lane_fault_min_index_r;
    reg parent_lifecycle_fault_r;
    reg parent_participant_min_valid_r;
    reg [12:0] parent_participant_min_index_r;
    wire protocol_fault_now =
        controller_state_illegal || parent_lifecycle_fault_r ||
        lane_protocol_fault_r;

    // Scalar error response edge先归约；registered QUARANTINE随后提供完整同步reset周期。
    // parent literal illegal可安全即时assert reset，因为它不依赖child rsp_valid。
    wire lane_child_rst =
        rst_i || controller_state_illegal ||
        (ctrl_state_q == CTRL_QUARANTINE);

    genvar gen_lane;
    generate
        for (gen_lane = 0; gen_lane < PHYS_LANES; gen_lane = gen_lane + 1) begin : g_lane
            wire [12:0] safe_source_index =
                ({19'b0, lane_index_q[gen_lane]} < SAFE_STORAGE_ELEMS) ?
                    lane_index_q[gen_lane] : 13'b0;
            wire rsp_ready_credit;

            assign lane_req_valid[gen_lane] =
                !rst_i && !protocol_fault_now && source_owner_valid_q &&
                (ctrl_state_q == CTRL_EXEC) &&
                (lane_state_q[gen_lane] == LANE_REQ);
            assign rsp_ready_credit =
                !rst_i && !protocol_fault_now && source_owner_valid_q &&
                (ctrl_state_q == CTRL_EXEC) &&
                (lane_state_q[gen_lane] == LANE_WAIT) &&
                lane_owner_valid_q[gen_lane];
            assign lane_rsp_ready[gen_lane] = rsp_ready_credit;

            TensorNpuUnaryGluElement #(
                .COMMAND_TIMEOUT_CYCLES(ELEMENT_TIMEOUT_CYCLES)
            ) u_element (
                .clk_i            (clk_i),
                .rst_i            (lane_child_rst),
                .req_valid_i      (lane_req_valid[gen_lane]),
                .req_ready_o      (lane_req_ready[gen_lane]),
                .opcode_i         (active_opcode_q),
                .src0_bits_i      (src0_mem_q[safe_source_index]),
                .src1_bits_i      (src1_mem_q[safe_source_index]),
                .rsp_valid_o      (lane_rsp_valid[gen_lane]),
                .rsp_ready_i      (rsp_ready_credit),
                .result_bits_o    (lane_result_bits[gen_lane]),
                .flags_o          (lane_flags[gen_lane]),
                .error_o          (lane_error[gen_lane]),
                .error_code_o     (lane_error_code[gen_lane]),
                .child_call_mask_o(lane_child_call_mask[gen_lane]),
                .active_cycles_o  (lane_active_cycles_unused[gen_lane])
            );
        end
    endgenerate

    // Parent/lane protocol checker展开为每lane比较器与两套独立优先编码器：
    // lane fault encoder只接收真实fault lane；parent participant encoder只在
    // controller/lifecycle fault时提供最低active logical index。二者不得互用。
    integer check_lane;
    always @(*) begin
        lane_fault_mask_r = {PHYS_LANES{1'b0}};
        lane_protocol_fault_r = 1'b0;
        lane_fault_min_valid_r = 1'b0;
        lane_fault_min_index_r = 13'b0;
        parent_lifecycle_fault_r = 1'b0;
        parent_participant_min_valid_r = 1'b0;
        parent_participant_min_index_r = capture_count_q;

        if ((ctrl_state_q == CTRL_CAPTURE) || (ctrl_state_q == CTRL_EXEC)) begin
            if (!source_owner_valid_q) begin
                parent_lifecycle_fault_r = 1'b1;
            end
        end else if ((ctrl_state_q == CTRL_IDLE) && source_owner_valid_q) begin
            parent_lifecycle_fault_r = 1'b1;
        end

        if (ctrl_state_q != CTRL_QUARANTINE) begin
            for (check_lane = 0; check_lane < PHYS_LANES;
                 check_lane = check_lane + 1) begin
                // Parent-only fault的participant集合独立于lane fault cause。
                // for-loop综合为PHYS_LANES路participant比较与最低index编码器。
                if (((lane_state_q[check_lane] != LANE_IDLE) ||
                     lane_owner_valid_q[check_lane] ||
                     lane_rsp_valid[check_lane]) &&
                    (!parent_participant_min_valid_r ||
                     (lane_index_q[check_lane] <
                      parent_participant_min_index_r))) begin
                    parent_participant_min_valid_r = 1'b1;
                    parent_participant_min_index_r =
                        lane_index_q[check_lane];
                end

                // controller literal illegal本身是parent-only fault；此时合法
                // resident lane只能作为participant，不能反向被标成lane fault。
                if (ctrl_state_valid_r) begin
                    if (ctrl_state_q == CTRL_EXEC) begin
                        case (lane_state_q[check_lane])
                            LANE_IDLE: begin
                                if (lane_owner_valid_q[check_lane]) begin
                                    lane_fault_mask_r[check_lane] = 1'b1;
                                end
                            end
                            LANE_REQ: begin
                                if (lane_owner_valid_q[check_lane] ||
                                    (lane_index_q[check_lane] >=
                                     active_length_q) ||
                                    ((lane_index_q[check_lane] % LANES_U13) !=
                                     check_lane[12:0]) ||
                                    (lane_generation_q[check_lane] !=
                                     active_generation_q)) begin
                                    lane_fault_mask_r[check_lane] = 1'b1;
                                end
                            end
                            LANE_WAIT: begin
                                if (!lane_owner_valid_q[check_lane] ||
                                    (lane_index_q[check_lane] >=
                                     active_length_q) ||
                                    ((lane_index_q[check_lane] % LANES_U13) !=
                                     check_lane[12:0]) ||
                                    (lane_generation_q[check_lane] !=
                                     active_generation_q)) begin
                                    lane_fault_mask_r[check_lane] = 1'b1;
                                end
                            end
                            default: begin
                                lane_fault_mask_r[check_lane] = 1'b1;
                            end
                        endcase

                        if (lane_rsp_valid[check_lane] &&
                            ((lane_state_q[check_lane] != LANE_WAIT) ||
                             !lane_owner_valid_q[check_lane] ||
                             (lane_generation_q[check_lane] !=
                              active_generation_q))) begin
                            lane_fault_mask_r[check_lane] = 1'b1;
                        end
                    end else begin
                        if ((lane_state_q[check_lane] != LANE_IDLE) ||
                            lane_owner_valid_q[check_lane] ||
                            lane_rsp_valid[check_lane]) begin
                            lane_fault_mask_r[check_lane] = 1'b1;
                        end
                    end
                end

                // 只有实际fault lane可进入cause encoder；合法低编号participant
                // 不再覆盖高编号fault lane的logical index。
                if (lane_fault_mask_r[check_lane]) begin
                    lane_protocol_fault_r = 1'b1;
                    if (!lane_fault_min_valid_r ||
                        (lane_index_q[check_lane] <
                         lane_fault_min_index_r)) begin
                        lane_fault_min_valid_r = 1'b1;
                        lane_fault_min_index_r = lane_index_q[check_lane];
                    end
                end
            end
        end
    end

    assign cmd_ready_o =
        !rst_i && PARAM_VALID && !protocol_fault_now &&
        (ctrl_state_q == CTRL_IDLE) && !source_owner_valid_q &&
        (fifo_count_q < 2'd2) && exists_free_bank;
    wire cmd_fire = cmd_valid_i && cmd_ready_o;

    assign busy_o = !rst_i && (fifo_count_q != 2'd0);

    assign in_ready_o =
        !rst_i && !protocol_fault_now && source_owner_valid_q &&
        (ctrl_state_q == CTRL_CAPTURE);
    wire in_fire = in_valid_i && in_ready_o;
    wire [12:0] capture_count_next = capture_count_q + 13'd1;
    wire capture_bad_this =
        external_nonfinite(in_src0_bits_i[30:23]) ||
        ((active_opcode_q == OP_SWIGLU) &&
         external_nonfinite(in_src1_bits_i[30:23]));
    wire capture_bad_next = external_bad_seen_q || capture_bad_this;
    wire capture_last_fire =
        in_fire && (capture_count_next == active_length_q);
    wire capture_bad_terminal = capture_last_fire && capture_bad_next;

    // ------------------------------------------------------------------
    // 真实event mask与next-popcount归约。for-loop展开为最多8路加法/OR树。
    // ------------------------------------------------------------------
    wire [PHYS_LANES-1:0] lane_req_fire = lane_req_valid & lane_req_ready;
    wire [PHYS_LANES-1:0] lane_rsp_fire = lane_rsp_valid & lane_rsp_ready;
    wire [PHYS_LANES-1:0] lane_rsp_ok = lane_rsp_fire & ~lane_error;
    wire [PHYS_LANES-1:0] lane_rsp_bad = lane_rsp_fire & lane_error;

    reg [3:0] req_fire_popcount_r;
    reg [3:0] rsp_fire_popcount_r;
    reg [3:0] rsp_ok_popcount_r;
    reg [3:0] exp_popcount_r;
    reg [3:0] add_popcount_r;
    reg [3:0] div_popcount_r;
    reg [3:0] log_popcount_r;
    reg [3:0] mul_popcount_r;
    reg [3:0] bypass_popcount_r;
    reg [4:0] event_call_mask_or_r;
    reg [4:0] event_flags_or_r;
    reg       rsp_error_any_r;
    reg [12:0] lowest_error_index_r;
    reg [3:0] lowest_error_code_r;
    reg       all_lanes_idle_after_r;

    integer reduce_lane;
    always @(*) begin
        req_fire_popcount_r = 4'b0;
        rsp_fire_popcount_r = 4'b0;
        rsp_ok_popcount_r = 4'b0;
        exp_popcount_r = 4'b0;
        add_popcount_r = 4'b0;
        div_popcount_r = 4'b0;
        log_popcount_r = 4'b0;
        mul_popcount_r = 4'b0;
        bypass_popcount_r = 4'b0;
        event_call_mask_or_r = 5'b0;
        event_flags_or_r = 5'b0;
        rsp_error_any_r = 1'b0;
        lowest_error_index_r = 13'b0;
        lowest_error_code_r = ERR_OK;
        all_lanes_idle_after_r = 1'b1;

        for (reduce_lane = 0; reduce_lane < PHYS_LANES;
             reduce_lane = reduce_lane + 1) begin
            if (lane_req_fire[reduce_lane]) begin
                req_fire_popcount_r = req_fire_popcount_r + 4'd1;
            end
            if (lane_rsp_fire[reduce_lane]) begin
                rsp_fire_popcount_r = rsp_fire_popcount_r + 4'd1;
                event_call_mask_or_r =
                    event_call_mask_or_r | lane_child_call_mask[reduce_lane];
                if (lane_child_call_mask[reduce_lane][0]) begin
                    exp_popcount_r = exp_popcount_r + 4'd1;
                end
                if (lane_child_call_mask[reduce_lane][1]) begin
                    add_popcount_r = add_popcount_r + 4'd1;
                end
                if (lane_child_call_mask[reduce_lane][2]) begin
                    div_popcount_r = div_popcount_r + 4'd1;
                end
                if (lane_child_call_mask[reduce_lane][3]) begin
                    log_popcount_r = log_popcount_r + 4'd1;
                end
                if (lane_child_call_mask[reduce_lane][4]) begin
                    mul_popcount_r = mul_popcount_r + 4'd1;
                end
            end
            if (lane_rsp_ok[reduce_lane]) begin
                rsp_ok_popcount_r = rsp_ok_popcount_r + 4'd1;
                event_flags_or_r = event_flags_or_r | lane_flags[reduce_lane];
                if ((active_opcode_q == OP_SOFTPLUS) &&
                    (lane_child_call_mask[reduce_lane] == 5'b0)) begin
                    bypass_popcount_r = bypass_popcount_r + 4'd1;
                end
            end
            if (lane_rsp_bad[reduce_lane]) begin
                if (!rsp_error_any_r ||
                    (lane_index_q[reduce_lane] < lowest_error_index_r)) begin
                    lowest_error_index_r = lane_index_q[reduce_lane];
                    lowest_error_code_r =
                        (lane_error_code[reduce_lane] == ERR_OK) ?
                            ERR_PROTOCOL : lane_error_code[reduce_lane];
                end
                rsp_error_any_r = 1'b1;
            end

            case (lane_state_q[reduce_lane])
                LANE_IDLE: begin
                    // 已idle。
                end
                LANE_WAIT: begin
                    if (!(lane_rsp_ok[reduce_lane] &&
                          ((lane_index_q[reduce_lane] + LANES_U13) >=
                           active_length_q))) begin
                        all_lanes_idle_after_r = 1'b0;
                    end
                end
                default: all_lanes_idle_after_r = 1'b0;
            endcase
        end
    end

    wire [12:0] launch_next = work_scalar_launch_count_q +
        {9'b0, req_fire_popcount_r};
    wire [12:0] terminal_next = work_scalar_terminal_count_q +
        {9'b0, rsp_fire_popcount_r};
    wire [12:0] success_next = work_success_result_count_q +
        {9'b0, rsp_ok_popcount_r};
    wire [4:0] call_mask_next =
        work_child_call_mask_q | event_call_mask_or_r;
    wire [12:0] exp_count_next =
        work_exp_req_count_q + {9'b0, exp_popcount_r};
    wire [12:0] add_count_next =
        work_add_req_count_q + {9'b0, add_popcount_r};
    wire [12:0] div_count_next =
        work_div_req_count_q + {9'b0, div_popcount_r};
    wire [12:0] log_count_next =
        work_log_req_count_q + {9'b0, log_popcount_r};
    wire [12:0] mul_count_next =
        work_mul_req_count_q + {9'b0, mul_popcount_r};
    wire [12:0] bypass_count_next =
        work_bypass_count_q + {9'b0, bypass_popcount_r};
    wire [4:0] tensor_flags_next =
        work_tensor_flags_or_q | event_flags_or_r;

    wire scalar_error_terminal =
        source_owner_valid_q && (ctrl_state_q == CTRL_EXEC) &&
        rsp_error_any_r && !protocol_fault_now;
    wire scalar_success_terminal =
        source_owner_valid_q && (ctrl_state_q == CTRL_EXEC) &&
        !protocol_fault_now && !rsp_error_any_r && (|lane_rsp_ok) &&
        (launch_next == active_length_q) &&
        (terminal_next == active_length_q) &&
        (success_next == active_length_q) && all_lanes_idle_after_r;
    wire controller_fault_terminal =
        source_owner_valid_q && protocol_fault_now;

    wire tensor_terminal =
        capture_bad_terminal || scalar_error_terminal ||
        scalar_success_terminal || controller_fault_terminal;
    wire tensor_terminal_ok =
        scalar_success_terminal && !controller_fault_terminal;
    wire [3:0] tensor_terminal_error_code =
        controller_fault_terminal ? ERR_PROTOCOL :
        capture_bad_terminal ? ERR_UNSUPPORTED :
        scalar_error_terminal ? lowest_error_code_r : ERR_OK;
    wire [63:0] tensor_terminal_active_cycles =
        wall_ts_q - start_ts_q + 64'd1;
    wire [12:0] tensor_terminal_capture_count =
        capture_bad_terminal ? capture_count_next : capture_count_q;
    wire tensor_terminal_fail_elem_valid =
        capture_bad_terminal || scalar_error_terminal ||
        controller_fault_terminal;
    wire [12:0] tensor_terminal_fail_elem_index =
        controller_fault_terminal ?
            (lane_fault_min_valid_r ? lane_fault_min_index_r :
             parent_participant_min_valid_r ?
                 parent_participant_min_index_r : capture_count_q) :
        capture_bad_terminal ?
            (external_bad_seen_q ? external_bad_index_q : capture_count_q) :
        lowest_error_index_r;

    // ------------------------------------------------------------------
    // FIFO head-only output mux。READY_ERR永不读取pending result memory。
    // ------------------------------------------------------------------
    wire fifo_head_bank = order_fifo_q[fifo_rd_ptr_q];
    wire [2:0] fifo_head_state = bank_state_q[fifo_head_bank];
    wire fifo_head_success =
        (fifo_head_state == BANK_READY_OK) ||
        (fifo_head_state == BANK_DRAIN);
    wire fifo_head_error = (fifo_head_state == BANK_READY_ERR);
    wire [13:0] fifo_result_address = fifo_head_bank ?
        (SAFE_STORAGE_U14 + {1'b0, bank_out_index_q[fifo_head_bank]}) :
        {1'b0, bank_out_index_q[fifo_head_bank]};

    reg        out_valid_r;
    reg        out_sop_r;
    reg        out_last_r;
    reg        out_keep_r;
    reg [31:0] out_result_bits_r;
    reg [4:0]  out_flags_r;
    reg [12:0] out_elem_index_r;
    reg [7:0]  out_tag_r;
    reg [2:0]  out_opcode_r;
    reg [12:0] out_length_r;
    reg        out_error_r;
    reg [3:0]  out_error_code_r;
    reg [63:0] out_active_cycles_r;
    reg [12:0] out_capture_count_r;
    reg [12:0] out_scalar_launch_count_r;
    reg [12:0] out_scalar_terminal_count_r;
    reg [12:0] out_success_result_count_r;
    reg [4:0]  out_child_call_mask_r;
    reg [12:0] out_exp_req_count_r;
    reg [12:0] out_add_req_count_r;
    reg [12:0] out_div_req_count_r;
    reg [12:0] out_log_req_count_r;
    reg [12:0] out_mul_req_count_r;
    reg [12:0] out_bypass_count_r;
    reg [4:0]  out_tensor_flags_or_r;
    reg        out_fail_elem_valid_r;
    reg [12:0] out_fail_elem_index_r;

    always @(*) begin
        out_valid_r = 1'b0;
        out_sop_r = 1'b0;
        out_last_r = 1'b0;
        out_keep_r = 1'b0;
        out_result_bits_r = 32'b0;
        out_flags_r = 5'b0;
        out_elem_index_r = 13'b0;
        out_tag_r = 8'b0;
        out_opcode_r = 3'b0;
        out_length_r = 13'b0;
        out_error_r = 1'b0;
        out_error_code_r = ERR_OK;
        out_active_cycles_r = 64'b0;
        out_capture_count_r = 13'b0;
        out_scalar_launch_count_r = 13'b0;
        out_scalar_terminal_count_r = 13'b0;
        out_success_result_count_r = 13'b0;
        out_child_call_mask_r = 5'b0;
        out_exp_req_count_r = 13'b0;
        out_add_req_count_r = 13'b0;
        out_div_req_count_r = 13'b0;
        out_log_req_count_r = 13'b0;
        out_mul_req_count_r = 13'b0;
        out_bypass_count_r = 13'b0;
        out_tensor_flags_or_r = 5'b0;
        out_fail_elem_valid_r = 1'b0;
        out_fail_elem_index_r = 13'b0;

        if (!rst_i && (fifo_count_q != 2'd0) &&
            (fifo_head_success || fifo_head_error)) begin
            out_valid_r = 1'b1;
            out_tag_r = bank_tag_q[fifo_head_bank];
            out_opcode_r = bank_opcode_q[fifo_head_bank];
            out_length_r = bank_length_q[fifo_head_bank];
            out_active_cycles_r = bank_active_cycles_q[fifo_head_bank];
            out_capture_count_r = bank_capture_count_q[fifo_head_bank];
            out_scalar_launch_count_r =
                bank_scalar_launch_count_q[fifo_head_bank];
            out_scalar_terminal_count_r =
                bank_scalar_terminal_count_q[fifo_head_bank];
            out_success_result_count_r =
                bank_success_result_count_q[fifo_head_bank];
            out_child_call_mask_r = bank_child_call_mask_q[fifo_head_bank];
            out_exp_req_count_r = bank_exp_req_count_q[fifo_head_bank];
            out_add_req_count_r = bank_add_req_count_q[fifo_head_bank];
            out_div_req_count_r = bank_div_req_count_q[fifo_head_bank];
            out_log_req_count_r = bank_log_req_count_q[fifo_head_bank];
            out_mul_req_count_r = bank_mul_req_count_q[fifo_head_bank];
            out_bypass_count_r = bank_bypass_count_q[fifo_head_bank];
            out_fail_elem_valid_r =
                bank_fail_elem_valid_q[fifo_head_bank];
            out_fail_elem_index_r =
                bank_fail_elem_index_q[fifo_head_bank];

            if (fifo_head_success) begin
                out_sop_r = (bank_out_index_q[fifo_head_bank] == 13'd0);
                out_last_r =
                    ((bank_out_index_q[fifo_head_bank] + 13'd1) ==
                     bank_length_q[fifo_head_bank]);
                out_keep_r = 1'b1;
                out_elem_index_r = bank_out_index_q[fifo_head_bank];
                out_result_bits_r = result_mem_q[fifo_result_address];
                out_flags_r = result_flags_mem_q[fifo_result_address];
                out_error_r = 1'b0;
                out_error_code_r = ERR_OK;
                out_tensor_flags_or_r =
                    bank_tensor_flags_or_q[fifo_head_bank];
            end else begin
                out_sop_r = 1'b1;
                out_last_r = 1'b1;
                out_keep_r = 1'b0;
                out_error_r = 1'b1;
                out_error_code_r = bank_error_code_q[fifo_head_bank];
                out_tensor_flags_or_r = 5'b0;
            end
        end
    end

    assign out_valid_o = out_valid_r;
    assign out_sop_o = out_sop_r;
    assign out_last_o = out_last_r;
    assign out_keep_o = out_keep_r;
    assign out_result_bits_o = out_result_bits_r;
    assign out_flags_o = out_flags_r;
    assign out_elem_index_o = out_elem_index_r;
    assign out_tag_o = out_tag_r;
    assign out_opcode_o = out_opcode_r;
    assign out_length_o = out_length_r;
    assign out_error_o = out_error_r;
    assign out_error_code_o = out_error_code_r;
    assign out_active_cycles_o = out_active_cycles_r;
    assign out_capture_count_o = out_capture_count_r;
    assign out_scalar_launch_count_o = out_scalar_launch_count_r;
    assign out_scalar_terminal_count_o = out_scalar_terminal_count_r;
    assign out_success_result_count_o = out_success_result_count_r;
    assign out_child_call_mask_o = out_child_call_mask_r;
    assign out_exp_req_count_o = out_exp_req_count_r;
    assign out_add_req_count_o = out_add_req_count_r;
    assign out_div_req_count_o = out_div_req_count_r;
    assign out_log_req_count_o = out_log_req_count_r;
    assign out_mul_req_count_o = out_mul_req_count_r;
    assign out_bypass_count_o = out_bypass_count_r;
    assign out_tensor_flags_or_o = out_tensor_flags_or_r;
    assign out_fail_elem_valid_o = out_fail_elem_valid_r;
    assign out_fail_elem_index_o = out_fail_elem_index_r;

    wire out_fire = out_valid_o && out_ready_i;
    wire out_pop = out_fire && out_last_o;

    // ------------------------------------------------------------------
    // 单一posedge owner。所有lane/bank/FIFO状态更新均映射到§3--§7合同。
    // ------------------------------------------------------------------
    integer seq_lane;
    integer seq_bank;
    always @(posedge clk_i) begin
        if (rst_i) begin
            wall_ts_q <= 64'b0;
            ctrl_state_q <= CTRL_IDLE;
            source_owner_valid_q <= 1'b0;
            active_bank_q <= 1'b0;
            active_opcode_q <= 3'b0;
            active_length_q <= 13'b0;
            generation_q <= 8'b0;
            active_generation_q <= 8'b0;
            start_ts_q <= 64'b0;
            capture_count_q <= 13'b0;
            external_bad_seen_q <= 1'b0;
            external_bad_index_q <= 13'b0;
            work_scalar_launch_count_q <= 13'b0;
            work_scalar_terminal_count_q <= 13'b0;
            work_success_result_count_q <= 13'b0;
            work_child_call_mask_q <= 5'b0;
            work_exp_req_count_q <= 13'b0;
            work_add_req_count_q <= 13'b0;
            work_div_req_count_q <= 13'b0;
            work_log_req_count_q <= 13'b0;
            work_mul_req_count_q <= 13'b0;
            work_bypass_count_q <= 13'b0;
            work_tensor_flags_or_q <= 5'b0;

            for (seq_lane = 0; seq_lane < PHYS_LANES;
                 seq_lane = seq_lane + 1) begin
                lane_state_q[seq_lane] <= LANE_IDLE;
                lane_owner_valid_q[seq_lane] <= 1'b0;
                lane_index_q[seq_lane] <= 13'b0;
                lane_generation_q[seq_lane] <= 8'b0;
            end

            for (seq_bank = 0; seq_bank < 2; seq_bank = seq_bank + 1) begin
                bank_state_q[seq_bank] <= BANK_FREE;
                bank_tag_q[seq_bank] <= 8'b0;
                bank_opcode_q[seq_bank] <= 3'b0;
                bank_length_q[seq_bank] <= 13'b0;
                bank_error_code_q[seq_bank] <= ERR_OK;
                bank_active_cycles_q[seq_bank] <= 64'b0;
                bank_capture_count_q[seq_bank] <= 13'b0;
                bank_scalar_launch_count_q[seq_bank] <= 13'b0;
                bank_scalar_terminal_count_q[seq_bank] <= 13'b0;
                bank_success_result_count_q[seq_bank] <= 13'b0;
                bank_child_call_mask_q[seq_bank] <= 5'b0;
                bank_exp_req_count_q[seq_bank] <= 13'b0;
                bank_add_req_count_q[seq_bank] <= 13'b0;
                bank_div_req_count_q[seq_bank] <= 13'b0;
                bank_log_req_count_q[seq_bank] <= 13'b0;
                bank_mul_req_count_q[seq_bank] <= 13'b0;
                bank_bypass_count_q[seq_bank] <= 13'b0;
                bank_tensor_flags_or_q[seq_bank] <= 5'b0;
                bank_fail_elem_valid_q[seq_bank] <= 1'b0;
                bank_fail_elem_index_q[seq_bank] <= 13'b0;
                bank_out_index_q[seq_bank] <= 13'b0;
            end

            order_fifo_q[0] <= 1'b0;
            order_fifo_q[1] <= 1'b0;
            fifo_rd_ptr_q <= 1'b0;
            fifo_wr_ptr_q <= 1'b0;
            fifo_count_q <= 2'b0;
        end else begin
            wall_ts_q <= wall_ts_q + 64'd1;

            // Head output只由真实handshake推进；hold时全部寄存器自然稳定。
            if (out_fire) begin
                if (out_last_o) begin
                    bank_state_q[fifo_head_bank] <= BANK_FREE;
                    bank_out_index_q[fifo_head_bank] <= 13'b0;
                end else begin
                    bank_state_q[fifo_head_bank] <= BANK_DRAIN;
                    bank_out_index_q[fifo_head_bank] <=
                        bank_out_index_q[fifo_head_bank] + 13'd1;
                end
            end

            // FIFO push/pop四种边界显式守恒。
            case ({cmd_fire, out_pop})
                2'b10: begin
                    order_fifo_q[fifo_wr_ptr_q] <= alloc_bank;
                    fifo_wr_ptr_q <= ~fifo_wr_ptr_q;
                    fifo_count_q <= fifo_count_q + 2'd1;
                end
                2'b01: begin
                    fifo_rd_ptr_q <= ~fifo_rd_ptr_q;
                    fifo_count_q <= fifo_count_q - 2'd1;
                end
                2'b11: begin
                    order_fifo_q[fifo_wr_ptr_q] <= alloc_bank;
                    fifo_wr_ptr_q <= ~fifo_wr_ptr_q;
                    fifo_rd_ptr_q <= ~fifo_rd_ptr_q;
                    fifo_count_q <= fifo_count_q;
                end
                default: begin
                    fifo_wr_ptr_q <= fifo_wr_ptr_q;
                    fifo_rd_ptr_q <= fifo_rd_ptr_q;
                    fifo_count_q <= fifo_count_q;
                end
            endcase

            // command edge原子建立bank descriptor；bad command同edge terminal=1。
            if (cmd_fire) begin
                bank_state_q[alloc_bank] <=
                    command_is_valid ? BANK_FILL : BANK_READY_ERR;
                bank_tag_q[alloc_bank] <= cmd_tag_i;
                bank_opcode_q[alloc_bank] <= cmd_opcode_i;
                bank_length_q[alloc_bank] <= cmd_length_i;
                bank_error_code_q[alloc_bank] <=
                    command_is_valid ? ERR_OK : ERR_UNSUPPORTED;
                bank_active_cycles_q[alloc_bank] <=
                    command_is_valid ? 64'b0 : 64'd1;
                bank_capture_count_q[alloc_bank] <= 13'b0;
                bank_scalar_launch_count_q[alloc_bank] <= 13'b0;
                bank_scalar_terminal_count_q[alloc_bank] <= 13'b0;
                bank_success_result_count_q[alloc_bank] <= 13'b0;
                bank_child_call_mask_q[alloc_bank] <= 5'b0;
                bank_exp_req_count_q[alloc_bank] <= 13'b0;
                bank_add_req_count_q[alloc_bank] <= 13'b0;
                bank_div_req_count_q[alloc_bank] <= 13'b0;
                bank_log_req_count_q[alloc_bank] <= 13'b0;
                bank_mul_req_count_q[alloc_bank] <= 13'b0;
                bank_bypass_count_q[alloc_bank] <= 13'b0;
                bank_tensor_flags_or_q[alloc_bank] <= 5'b0;
                bank_fail_elem_valid_q[alloc_bank] <= 1'b0;
                bank_fail_elem_index_q[alloc_bank] <= 13'b0;
                bank_out_index_q[alloc_bank] <= 13'b0;

                if (command_is_valid) begin
                    ctrl_state_q <= CTRL_CAPTURE;
                    source_owner_valid_q <= 1'b1;
                    active_bank_q <= alloc_bank;
                    active_opcode_q <= cmd_opcode_i;
                    active_length_q <= cmd_length_i;
                    generation_q <= generation_q + 8'd1;
                    active_generation_q <= generation_q + 8'd1;
                    start_ts_q <= wall_ts_q;
                    capture_count_q <= 13'b0;
                    external_bad_seen_q <= 1'b0;
                    external_bad_index_q <= 13'b0;
                    work_scalar_launch_count_q <= 13'b0;
                    work_scalar_terminal_count_q <= 13'b0;
                    work_success_result_count_q <= 13'b0;
                    work_child_call_mask_q <= 5'b0;
                    work_exp_req_count_q <= 13'b0;
                    work_add_req_count_q <= 13'b0;
                    work_div_req_count_q <= 13'b0;
                    work_log_req_count_q <= 13'b0;
                    work_mul_req_count_q <= 13'b0;
                    work_bypass_count_q <= 13'b0;
                    work_tensor_flags_or_q <= 5'b0;
                    for (seq_lane = 0; seq_lane < PHYS_LANES;
                         seq_lane = seq_lane + 1) begin
                        lane_state_q[seq_lane] <= LANE_IDLE;
                        lane_owner_valid_q[seq_lane] <= 1'b0;
                        lane_index_q[seq_lane] <= 13'b0;
                        lane_generation_q[seq_lane] <= generation_q + 8'd1;
                    end
                end
            end

            // work counters只从本拍真实event mask推进。
            if ((ctrl_state_q == CTRL_EXEC) && !protocol_fault_now) begin
                if (|lane_req_fire) begin
                    work_scalar_launch_count_q <= launch_next;
                end
                if (|lane_rsp_fire) begin
                    work_scalar_terminal_count_q <= terminal_next;
                    work_success_result_count_q <= success_next;
                    work_child_call_mask_q <= call_mask_next;
                    work_exp_req_count_q <= exp_count_next;
                    work_add_req_count_q <= add_count_next;
                    work_div_req_count_q <= div_count_next;
                    work_log_req_count_q <= log_count_next;
                    work_mul_req_count_q <= mul_count_next;
                    work_bypass_count_q <= bypass_count_next;
                    work_tensor_flags_or_q <= tensor_flags_next;
                end

                // 同拍error时success pending write仍真实发生，但错误bank永不可读。
                for (seq_lane = 0; seq_lane < PHYS_LANES;
                     seq_lane = seq_lane + 1) begin
                    if (lane_rsp_ok[seq_lane]) begin
                        if (!active_bank_q) begin
                            result_mem_q[{1'b0, lane_index_q[seq_lane]}] <=
                                lane_result_bits[seq_lane];
                            result_flags_mem_q[
                                {1'b0, lane_index_q[seq_lane]}] <=
                                lane_flags[seq_lane];
                        end else begin
                            result_mem_q[SAFE_STORAGE_U14 +
                                         {1'b0, lane_index_q[seq_lane]}] <=
                                lane_result_bits[seq_lane];
                            result_flags_mem_q[SAFE_STORAGE_U14 +
                                               {1'b0, lane_index_q[seq_lane]}] <=
                                lane_flags[seq_lane];
                        end
                    end
                end
            end

            // Protocol fault与scalar error均清除parent owner并进入完整registered quarantine。
            if (protocol_fault_now) begin
                ctrl_state_q <= CTRL_QUARANTINE;
                source_owner_valid_q <= 1'b0;
                for (seq_lane = 0; seq_lane < PHYS_LANES;
                     seq_lane = seq_lane + 1) begin
                    lane_state_q[seq_lane] <= LANE_IDLE;
                    lane_owner_valid_q[seq_lane] <= 1'b0;
                end
            end else if (scalar_error_terminal) begin
                ctrl_state_q <= CTRL_QUARANTINE;
                source_owner_valid_q <= 1'b0;
                for (seq_lane = 0; seq_lane < PHYS_LANES;
                     seq_lane = seq_lane + 1) begin
                    lane_state_q[seq_lane] <= LANE_IDLE;
                    lane_owner_valid_q[seq_lane] <= 1'b0;
                end
            end else begin
                case (ctrl_state_q)
                    CTRL_IDLE: begin
                        // command accept由上方原子块建立owner。
                    end

                    CTRL_CAPTURE: begin
                        if (in_fire) begin
                            src0_mem_q[capture_count_q] <= in_src0_bits_i;
                            src1_mem_q[capture_count_q] <= in_src1_bits_i;
                            capture_count_q <= capture_count_next;
                            if (capture_bad_this && !external_bad_seen_q) begin
                                external_bad_seen_q <= 1'b1;
                                external_bad_index_q <= capture_count_q;
                            end
                            if (capture_last_fire) begin
                                if (capture_bad_next) begin
                                    ctrl_state_q <= CTRL_IDLE;
                                    source_owner_valid_q <= 1'b0;
                                end else begin
                                    ctrl_state_q <= CTRL_EXEC;
                                    for (seq_lane = 0; seq_lane < PHYS_LANES;
                                         seq_lane = seq_lane + 1) begin
                                        lane_owner_valid_q[seq_lane] <= 1'b0;
                                        lane_generation_q[seq_lane] <=
                                            active_generation_q;
                                        lane_index_q[seq_lane] <= seq_lane[12:0];
                                        if (seq_lane[12:0] < active_length_q) begin
                                            lane_state_q[seq_lane] <= LANE_REQ;
                                        end else begin
                                            lane_state_q[seq_lane] <= LANE_IDLE;
                                        end
                                    end
                                end
                            end
                        end
                    end

                    CTRL_EXEC: begin
                        for (seq_lane = 0; seq_lane < PHYS_LANES;
                             seq_lane = seq_lane + 1) begin
                            case (lane_state_q[seq_lane])
                                LANE_IDLE: begin
                                    lane_owner_valid_q[seq_lane] <= 1'b0;
                                end
                                LANE_REQ: begin
                                    if (lane_req_fire[seq_lane]) begin
                                        lane_owner_valid_q[seq_lane] <= 1'b1;
                                        lane_state_q[seq_lane] <= LANE_WAIT;
                                    end
                                end
                                LANE_WAIT: begin
                                    if (lane_rsp_fire[seq_lane]) begin
                                        lane_owner_valid_q[seq_lane] <= 1'b0;
                                        if (!lane_error[seq_lane]) begin
                                            if ((lane_index_q[seq_lane] +
                                                 LANES_U13) < active_length_q) begin
                                                lane_index_q[seq_lane] <=
                                                    lane_index_q[seq_lane] +
                                                    LANES_U13;
                                                lane_state_q[seq_lane] <= LANE_REQ;
                                            end else begin
                                                lane_state_q[seq_lane] <= LANE_IDLE;
                                            end
                                        end
                                    end
                                end
                                default: begin
                                    lane_state_q[seq_lane] <= LANE_IDLE;
                                    lane_owner_valid_q[seq_lane] <= 1'b0;
                                end
                            endcase
                        end
                        if (scalar_success_terminal) begin
                            ctrl_state_q <= CTRL_IDLE;
                            source_owner_valid_q <= 1'b0;
                        end
                    end

                    CTRL_QUARANTINE: begin
                        // lane_child_rst在本完整active周期为1；下一拍才开放IDLE credit。
                        ctrl_state_q <= CTRL_IDLE;
                        source_owner_valid_q <= 1'b0;
                    end

                    default: begin
                        ctrl_state_q <= CTRL_QUARANTINE;
                        source_owner_valid_q <= 1'b0;
                    end
                endcase
            end

            // 单一terminal edge以本拍next event归约原子快照bank metadata。
            if (tensor_terminal) begin
                bank_state_q[active_bank_q] <=
                    tensor_terminal_ok ? BANK_READY_OK : BANK_READY_ERR;
                bank_error_code_q[active_bank_q] <=
                    tensor_terminal_error_code;
                bank_active_cycles_q[active_bank_q] <=
                    tensor_terminal_active_cycles;
                bank_capture_count_q[active_bank_q] <=
                    tensor_terminal_capture_count;
                bank_scalar_launch_count_q[active_bank_q] <= launch_next;
                bank_scalar_terminal_count_q[active_bank_q] <= terminal_next;
                bank_success_result_count_q[active_bank_q] <= success_next;
                bank_child_call_mask_q[active_bank_q] <= call_mask_next;
                bank_exp_req_count_q[active_bank_q] <= exp_count_next;
                bank_add_req_count_q[active_bank_q] <= add_count_next;
                bank_div_req_count_q[active_bank_q] <= div_count_next;
                bank_log_req_count_q[active_bank_q] <= log_count_next;
                bank_mul_req_count_q[active_bank_q] <= mul_count_next;
                bank_bypass_count_q[active_bank_q] <= bypass_count_next;
                bank_tensor_flags_or_q[active_bank_q] <= tensor_flags_next;
                bank_fail_elem_valid_q[active_bank_q] <=
                    tensor_terminal_fail_elem_valid;
                bank_fail_elem_index_q[active_bank_q] <=
                    tensor_terminal_fail_elem_index;
                bank_out_index_q[active_bank_q] <= 13'b0;
            end
        end
    end

endmodule
