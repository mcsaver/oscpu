`timescale 1ns/1ps

// SPDX-License-Identifier: MIT
//
// AOR_AARCH64_FMA_RNE_V1 EXP32 source-replay datapath.
// Constants/table are derived from Arm optimized-routines commit
// 67126040cf80f956676fbf473c2d9bebdb475283, math/expf.c and math/exp2f_data.c.
// Copyright (c) 2018-2023, Arm Limited. SPDX MIT path selected by the manifest.
module TensorNpuAorExp32 #(
    parameter integer COMMAND_TIMEOUT_CYCLES = 128
) (
    input  wire        clk_i,
    input  wire        rst_i,

    input  wire        req_valid_i,
    output wire        req_ready_o,
    input  wire [31:0] operand_i,

    output wire        rsp_valid_o,
    input  wire        rsp_ready_i,
    output wire [31:0] result_o,
    output wire [4:0]  flags_o,
    output wire        error_o,
    output wire [3:0]  error_code_o,
    output wire [31:0] active_cycles_o
);

    localparam [3:0] ERR_OK          = 4'd0;
    localparam [3:0] ERR_UNSUPPORTED = 4'd1;
    localparam [3:0] ERR_CHILD       = 4'd2;
    localparam [3:0] ERR_TIMEOUT     = 4'd3;
    localparam [3:0] ERR_PROTOCOL    = 4'd4;

    localparam [4:0] ST_IDLE          = 5'd0;
    localparam [4:0] ST_CLASSIFY      = 5'd1;
    localparam [4:0] ST_X64_REQ       = 5'd2;
    localparam [4:0] ST_X64_WAIT      = 5'd3;
    localparam [4:0] ST_Z_REQ         = 5'd4;
    localparam [4:0] ST_Z_WAIT        = 5'd5;
    localparam [4:0] ST_K_REQ         = 5'd6;
    localparam [4:0] ST_K_WAIT        = 5'd7;
    localparam [4:0] ST_KD_REQ        = 5'd8;
    localparam [4:0] ST_KD_WAIT       = 5'd9;
    localparam [4:0] ST_KD_ZERO_SIGN  = 5'd10;
    localparam [4:0] ST_R_REQ         = 5'd11;
    localparam [4:0] ST_R_WAIT        = 5'd12;
    localparam [4:0] ST_SCALE_INTEGER = 5'd13;
    localparam [4:0] ST_P01_REQ       = 5'd14;
    localparam [4:0] ST_P01_WAIT      = 5'd15;
    localparam [4:0] ST_R2_REQ        = 5'd16;
    localparam [4:0] ST_R2_WAIT       = 5'd17;
    localparam [4:0] ST_P2_REQ        = 5'd18;
    localparam [4:0] ST_P2_WAIT       = 5'd19;
    localparam [4:0] ST_P_REQ         = 5'd20;
    localparam [4:0] ST_P_WAIT        = 5'd21;
    localparam [4:0] ST_Y_REQ         = 5'd22;
    localparam [4:0] ST_Y_WAIT        = 5'd23;
    localparam [4:0] ST_PACK_REQ      = 5'd24;
    localparam [4:0] ST_PACK_WAIT     = 5'd25;
    localparam [4:0] ST_ABORT_RESET   = 5'd26;
    localparam [4:0] ST_HOLD_RESPONSE = 5'd27;

    localparam [31:0] TIMEOUT_LIMIT = COMMAND_TIMEOUT_CYCLES;

    localparam [63:0] F64_ZERO          = 64'h0000000000000000;
    localparam [63:0] F64_ONE           = 64'h3ff0000000000000;
    localparam [63:0] F64_NEG_ONE       = 64'hbff0000000000000;
    localparam [63:0] EXP_INVLN2_SCALED = 64'h40471547652b82fe;
    localparam [63:0] EXP_C0            = 64'h3ebc6af84b912394;
    localparam [63:0] EXP_C1            = 64'h3f2ebfce50fac4f3;
    localparam [63:0] EXP_C2            = 64'h3f962e42ff0c52d6;

    function [31:0] sat_inc32;
        input [31:0] value;
        begin
            sat_inc32 = (&value) ? value : (value + 32'd1);
        end
    endfunction

    reg [4:0] state_q;
    reg [31:0] operand_q;
    reg [63:0] xd_q;
    reg [63:0] z_q;
    reg [31:0] k_q;
    reg [63:0] kd_q;
    reg [63:0] r_q;
    reg [63:0] scale_q;
    reg [63:0] p01_q;
    reg [63:0] r2_q;
    reg [63:0] p2_q;
    reg [63:0] p_q;
    reg [63:0] y_q;
    reg [4:0] table_index_q;
    reg [4:0] flags_accum_q;
    reg [31:0] watchdog_q;
    reg [31:0] active_cycles_q;
    reg [3:0] pending_error_code_q;

    reg        rsp_valid_q;
    reg [31:0] result_q;
    reg [4:0]  flags_q;
    reg        error_q;
    reg [3:0]  error_code_q;
    reg [31:0] response_cycles_q;

    wire abort_reset = (state_q == ST_ABORT_RESET);
    // terminal response 一经发布，HOLD 全段继续同步复位全部 child。
    // retire 边沿仍保持 quarantine，下一周期 IDLE 才允许新的 producer owner。
    wire terminal_quarantine = (state_q == ST_HOLD_RESPONSE);
    wire child_rst = rst_i || abort_reset || terminal_quarantine;

    assign rsp_valid_o     = !rst_i && rsp_valid_q;
    assign result_o        = result_q;
    assign flags_o         = flags_q;
    assign error_o         = error_q;
    assign error_code_o    = error_code_q;
    assign active_cycles_o = response_cycles_q;

    // EXP ROM：32 路 case 综合为只读 mux tree；default 只报告内部 fault。
    reg [63:0] exp_table_raw;
    reg        exp_table_valid;
    always @(*) begin
        exp_table_raw   = 64'b0;
        exp_table_valid = 1'b1;
        case (table_index_q)
            5'd0:  exp_table_raw = 64'h3ff0000000000000;
            5'd1:  exp_table_raw = 64'h3fefd9b0d3158574;
            5'd2:  exp_table_raw = 64'h3fefb5586cf9890f;
            5'd3:  exp_table_raw = 64'h3fef9301d0125b51;
            5'd4:  exp_table_raw = 64'h3fef72b83c7d517b;
            5'd5:  exp_table_raw = 64'h3fef54873168b9aa;
            5'd6:  exp_table_raw = 64'h3fef387a6e756238;
            5'd7:  exp_table_raw = 64'h3fef1e9df51fdee1;
            5'd8:  exp_table_raw = 64'h3fef06fe0a31b715;
            5'd9:  exp_table_raw = 64'h3feef1a7373aa9cb;
            5'd10: exp_table_raw = 64'h3feedea64c123422;
            5'd11: exp_table_raw = 64'h3feece086061892d;
            5'd12: exp_table_raw = 64'h3feebfdad5362a27;
            5'd13: exp_table_raw = 64'h3feeb42b569d4f82;
            5'd14: exp_table_raw = 64'h3feeab07dd485429;
            5'd15: exp_table_raw = 64'h3feea47eb03a5585;
            5'd16: exp_table_raw = 64'h3feea09e667f3bcd;
            5'd17: exp_table_raw = 64'h3fee9f75e8ec5f74;
            5'd18: exp_table_raw = 64'h3feea11473eb0187;
            5'd19: exp_table_raw = 64'h3feea589994cce13;
            5'd20: exp_table_raw = 64'h3feeace5422aa0db;
            5'd21: exp_table_raw = 64'h3feeb737b0cdc5e5;
            5'd22: exp_table_raw = 64'h3feec49182a3f090;
            5'd23: exp_table_raw = 64'h3feed503b23e255d;
            5'd24: exp_table_raw = 64'h3feee89f995ad3ad;
            5'd25: exp_table_raw = 64'h3feeff76f2fb5e47;
            5'd26: exp_table_raw = 64'h3fef199bdd85529c;
            5'd27: exp_table_raw = 64'h3fef3720dcef9069;
            5'd28: exp_table_raw = 64'h3fef5818dcfba487;
            5'd29: exp_table_raw = 64'h3fef7c97337b9b5f;
            5'd30: exp_table_raw = 64'h3fefa4afa2a490da;
            5'd31: exp_table_raw = 64'h3fefd0765b6e4540;
            default: begin
                exp_table_raw   = 64'b0;
                exp_table_valid = 1'b0;
            end
        endcase
    end

    wire [63:0] k_sign_extended = {{32{k_q[31]}}, k_q};
    wire [63:0] scale_shift_term = k_sign_extended << 47;
    wire [63:0] scale_comb = exp_table_raw + scale_shift_term;

    // Child 1：finite F32 -> F64 exact widen。
    wire        x64_req_ready;
    wire        x64_rsp_valid;
    wire [63:0] x64_rsp_result;
    wire [4:0]  x64_rsp_flags;
    wire        x64_rsp_error;
    wire        x64_req_valid = (state_q == ST_X64_REQ);
    wire        x64_rsp_ready = (state_q == ST_X64_WAIT);

    TensorNpuFp32ToFp64 u_x64 (
        .clk_i      (clk_i),
        .rst_i      (child_rst),
        .req_valid_i(x64_req_valid),
        .req_ready_o(x64_req_ready),
        .operand_i  (operand_q),
        .rsp_valid_o(x64_rsp_valid),
        .rsp_ready_i(x64_rsp_ready),
        .result_o   (x64_rsp_result),
        .flags_o    (x64_rsp_flags),
        .error_o    (x64_rsp_error)
    );

    // Child 2：唯一共享 FMA。状态 mux 明确选择每个 DAG node 的 A/B/C。
    reg [63:0] fma_operand_a;
    reg [63:0] fma_operand_b;
    reg [63:0] fma_operand_c;
    reg        fma_req_valid;
    reg        fma_rsp_ready;
    always @(*) begin
        fma_operand_a = F64_ZERO;
        fma_operand_b = F64_ZERO;
        fma_operand_c = F64_ZERO;
        fma_req_valid = 1'b0;
        fma_rsp_ready = 1'b0;
        case (state_q)
            ST_Z_REQ: begin
                fma_operand_a = EXP_INVLN2_SCALED;
                fma_operand_b = xd_q;
                fma_operand_c = F64_ZERO;
                fma_req_valid = 1'b1;
            end
            ST_Z_WAIT: fma_rsp_ready = 1'b1;
            ST_R_REQ: begin
                fma_operand_a = F64_NEG_ONE;
                fma_operand_b = kd_q;
                fma_operand_c = z_q;
                fma_req_valid = 1'b1;
            end
            ST_R_WAIT: fma_rsp_ready = 1'b1;
            ST_P01_REQ: begin
                fma_operand_a = EXP_C0;
                fma_operand_b = r_q;
                fma_operand_c = EXP_C1;
                fma_req_valid = 1'b1;
            end
            ST_P01_WAIT: fma_rsp_ready = 1'b1;
            ST_R2_REQ: begin
                fma_operand_a = r_q;
                fma_operand_b = r_q;
                fma_operand_c = F64_ZERO;
                fma_req_valid = 1'b1;
            end
            ST_R2_WAIT: fma_rsp_ready = 1'b1;
            ST_P2_REQ: begin
                fma_operand_a = EXP_C2;
                fma_operand_b = r_q;
                fma_operand_c = F64_ONE;
                fma_req_valid = 1'b1;
            end
            ST_P2_WAIT: fma_rsp_ready = 1'b1;
            ST_P_REQ: begin
                fma_operand_a = p01_q;
                fma_operand_b = r2_q;
                fma_operand_c = p2_q;
                fma_req_valid = 1'b1;
            end
            ST_P_WAIT: fma_rsp_ready = 1'b1;
            ST_Y_REQ: begin
                fma_operand_a = p_q;
                fma_operand_b = scale_q;
                fma_operand_c = F64_ZERO;
                fma_req_valid = 1'b1;
            end
            ST_Y_WAIT: fma_rsp_ready = 1'b1;
            default: begin
                fma_operand_a = F64_ZERO;
                fma_operand_b = F64_ZERO;
                fma_operand_c = F64_ZERO;
                fma_req_valid = 1'b0;
                fma_rsp_ready = 1'b0;
            end
        endcase
    end

    wire        fma_req_ready;
    wire        fma_rsp_valid;
    wire [63:0] fma_rsp_result;
    wire [4:0]  fma_rsp_flags;
    TensorNpuFp64Fma u_fma (
        .clk_i       (clk_i),
        .rst_i       (child_rst),
        .req_valid_i (fma_req_valid),
        .req_ready_o (fma_req_ready),
        .operand_a_i (fma_operand_a),
        .operand_b_i (fma_operand_b),
        .operand_c_i (fma_operand_c),
        .rsp_valid_o (fma_rsp_valid),
        .rsp_ready_i (fma_rsp_ready),
        .result_o    (fma_rsp_result),
        .flags_o     (fma_rsp_flags)
    );

    // Child 3：k 的生产者归属固定为 z_q；NX 仅作内部 trace，不进入 sticky flags。
    wire [63:0] k_operand = z_q;
    wire        k_req_valid = (state_q == ST_K_REQ);
    wire        k_req_ready;
    wire        k_rsp_valid;
    wire        k_rsp_ready = (state_q == ST_K_WAIT);
    wire [31:0] k_rsp_result;
    wire [2:0]  k_rsp_int_flags;
    wire [4:0]  k_rsp_flags;
    TensorNpuFp64ToInt32Rmm u_k (
        .clk_i       (clk_i),
        .rst_i       (child_rst),
        .req_valid_i (k_req_valid),
        .req_ready_o (k_req_ready),
        .operand_i   (k_operand),
        .rsp_valid_o (k_rsp_valid),
        .rsp_ready_i (k_rsp_ready),
        .result_o    (k_rsp_result),
        .int_flags_o (k_rsp_int_flags),
        .flags_o     (k_rsp_flags)
    );

    // Child 4：signed I32 k -> exact F64 kd。
    wire        kd_req_valid = (state_q == ST_KD_REQ);
    wire        kd_req_ready;
    wire        kd_rsp_valid;
    wire        kd_rsp_ready = (state_q == ST_KD_WAIT);
    wire [63:0] kd_rsp_result;
    wire [4:0]  kd_rsp_flags;
    TensorNpuInt32ToFp64 u_kd (
        .clk_i       (clk_i),
        .rst_i       (child_rst),
        .req_valid_i (kd_req_valid),
        .req_ready_o (kd_req_ready),
        .operand_i   (k_q),
        .rsp_valid_o (kd_rsp_valid),
        .rsp_ready_i (kd_rsp_ready),
        .result_o    (kd_rsp_result),
        .flags_o     (kd_rsp_flags)
    );

    // Child 5：signed finite F64 -> F32 final pack。
    wire        pack_req_valid = (state_q == ST_PACK_REQ);
    wire        pack_req_ready;
    wire        pack_rsp_valid;
    wire        pack_rsp_ready = (state_q == ST_PACK_WAIT);
    wire [31:0] pack_rsp_result;
    wire [4:0]  pack_rsp_flags;
    wire        pack_rsp_error;
    TensorNpuFp64ToFp32Finite u_pack (
        .clk_i       (clk_i),
        .rst_i       (child_rst),
        .req_valid_i (pack_req_valid),
        .req_ready_o (pack_req_ready),
        .operand_i   (y_q),
        .rsp_valid_o (pack_rsp_valid),
        .rsp_ready_i (pack_rsp_ready),
        .result_o    (pack_rsp_result),
        .flags_o     (pack_rsp_flags),
        .error_o     (pack_rsp_error)
    );

    wire fma_wait_state =
        (state_q == ST_Z_WAIT)   || (state_q == ST_R_WAIT) ||
        (state_q == ST_P01_WAIT) || (state_q == ST_R2_WAIT) ||
        (state_q == ST_P2_WAIT)  || (state_q == ST_P_WAIT) ||
        (state_q == ST_Y_WAIT);

    wire any_child_rsp_valid =
        x64_rsp_valid || fma_rsp_valid || k_rsp_valid ||
        kd_rsp_valid || pack_rsp_valid;
    wire ghost_response_now =
        (x64_rsp_valid && (state_q != ST_X64_WAIT)) ||
        (fma_rsp_valid && !fma_wait_state) ||
        (k_rsp_valid && (state_q != ST_K_WAIT)) ||
        (kd_rsp_valid && (state_q != ST_KD_WAIT)) ||
        (pack_rsp_valid && (state_q != ST_PACK_WAIT));

    wire x64_fault_now = (state_q == ST_X64_WAIT) && x64_rsp_valid &&
        (x64_rsp_error || (x64_rsp_flags != 5'b0) ||
         (x64_rsp_result[62:52] == 11'h7ff));
    wire fma_fault_now = fma_wait_state && fma_rsp_valid &&
        ((fma_rsp_flags[4:1] != 4'b0) ||
         (fma_rsp_result[62:52] == 11'h7ff));
    wire k_inexact_consistent = (k_rsp_flags[0] == k_rsp_int_flags[0]);
    wire k_range_fault =
        k_rsp_int_flags[2] || k_rsp_int_flags[1] || k_rsp_flags[4] ||
        (k_rsp_flags[3:1] != 3'b0) || !k_inexact_consistent ||
        ($signed(k_rsp_result) < -32'sd4800) ||
        ($signed(k_rsp_result) > 32'sd4096);
    wire k_fault_now = (state_q == ST_K_WAIT) && k_rsp_valid && k_range_fault;
    wire kd_fault_now = (state_q == ST_KD_WAIT) && kd_rsp_valid &&
        ((kd_rsp_flags != 5'b0) || (kd_rsp_result[62:52] == 11'h7ff));
    wire pack_fault_now = (state_q == ST_PACK_WAIT) && pack_rsp_valid && pack_rsp_error;
    wire scale_fault_now = (state_q == ST_SCALE_INTEGER) && exp_table_valid &&
        (scale_comb[62:52] == 11'h7ff);
    wire child_profile_fault_now =
        x64_fault_now || fma_fault_now || k_fault_now ||
        kd_fault_now || pack_fault_now || scale_fault_now;

    reg state_valid;
    always @(*) begin
        state_valid = 1'b1;
        case (state_q)
            ST_IDLE, ST_CLASSIFY, ST_X64_REQ, ST_X64_WAIT,
            ST_Z_REQ, ST_Z_WAIT, ST_K_REQ, ST_K_WAIT,
            ST_KD_REQ, ST_KD_WAIT, ST_KD_ZERO_SIGN,
            ST_R_REQ, ST_R_WAIT, ST_SCALE_INTEGER,
            ST_P01_REQ, ST_P01_WAIT, ST_R2_REQ, ST_R2_WAIT,
            ST_P2_REQ, ST_P2_WAIT, ST_P_REQ, ST_P_WAIT,
            ST_Y_REQ, ST_Y_WAIT, ST_PACK_REQ, ST_PACK_WAIT,
            ST_ABORT_RESET, ST_HOLD_RESPONSE: state_valid = 1'b1;
            default: state_valid = 1'b0;
        endcase
    end

    wire internal_fault_now =
        !state_valid ||
        ((state_q != ST_ABORT_RESET) && (state_q != ST_HOLD_RESPONSE) &&
         (ghost_response_now ||
          ((state_q == ST_SCALE_INTEGER) && !exp_table_valid)));
    wire command_timeout_now =
        (state_q != ST_IDLE) && (state_q != ST_ABORT_RESET) &&
        (state_q != ST_HOLD_RESPONSE) &&
        (watchdog_q >= TIMEOUT_LIMIT);

    // IDLE 仅在所有 child EMPTY 时提供新 request credit；ghost response先走 code4。
    assign req_ready_o = !rst_i && (state_q == ST_IDLE) &&
                         !rsp_valid_q && !any_child_rsp_valid;

    // 单一 posedge owner。全局优先级：reset > internal/child fault > timeout > normal progress。
    always @(posedge clk_i) begin
        if (rst_i) begin
            state_q              <= ST_IDLE;
            operand_q            <= 32'b0;
            xd_q                 <= 64'b0;
            z_q                  <= 64'b0;
            k_q                  <= 32'b0;
            kd_q                 <= 64'b0;
            r_q                  <= 64'b0;
            scale_q              <= 64'b0;
            p01_q                <= 64'b0;
            r2_q                 <= 64'b0;
            p2_q                 <= 64'b0;
            p_q                  <= 64'b0;
            y_q                  <= 64'b0;
            table_index_q        <= 5'b0;
            flags_accum_q        <= 5'b0;
            watchdog_q           <= 32'b0;
            active_cycles_q      <= 32'b0;
            pending_error_code_q <= ERR_OK;
            rsp_valid_q          <= 1'b0;
            result_q             <= 32'b0;
            flags_q              <= 5'b0;
            error_q              <= 1'b0;
            error_code_q         <= ERR_OK;
            response_cycles_q    <= 32'b0;
        end else begin
            if ((state_q != ST_IDLE) && (state_q != ST_HOLD_RESPONSE)) begin
                active_cycles_q <= sat_inc32(active_cycles_q);
                watchdog_q      <= sat_inc32(watchdog_q);
            end

            if (internal_fault_now) begin
                pending_error_code_q <= ERR_PROTOCOL;
                state_q              <= ST_ABORT_RESET;
            end else if (child_profile_fault_now) begin
                pending_error_code_q <= ERR_CHILD;
                state_q              <= ST_ABORT_RESET;
            end else if (command_timeout_now) begin
                pending_error_code_q <= ERR_TIMEOUT;
                state_q              <= ST_ABORT_RESET;
            end else begin
                case (state_q)
                    ST_IDLE: begin
                        if (req_valid_i && req_ready_o) begin
                            operand_q            <= operand_i;
                            flags_accum_q        <= 5'b0;
                            watchdog_q           <= 32'd1;
                            active_cycles_q      <= 32'd1;
                            pending_error_code_q <= ERR_OK;
                            rsp_valid_q          <= 1'b0;
                            result_q             <= 32'b0;
                            flags_q              <= 5'b0;
                            error_q              <= 1'b0;
                            error_code_q         <= ERR_OK;
                            response_cycles_q    <= 32'b0;
                            state_q              <= ST_CLASSIFY;
                        end
                    end

                    ST_CLASSIFY: begin
                        if (operand_q[30:0] == 31'b0) begin
                            rsp_valid_q       <= 1'b1;
                            result_q          <= 32'h3f800000;
                            flags_q           <= 5'b0;
                            error_q           <= 1'b0;
                            error_code_q      <= ERR_OK;
                            response_cycles_q <= sat_inc32(active_cycles_q);
                            state_q           <= ST_HOLD_RESPONSE;
                        end else if (operand_q[30:23] == 8'hff) begin
                            if (operand_q[22:0] != 23'b0) begin
                                pending_error_code_q <= ERR_UNSUPPORTED;
                                state_q              <= ST_ABORT_RESET;
                            end else begin
                                rsp_valid_q       <= 1'b1;
                                result_q          <= operand_q[31] ? 32'h00000000 : 32'h7f800000;
                                flags_q           <= 5'b0;
                                error_q           <= 1'b0;
                                error_code_q      <= ERR_OK;
                                response_cycles_q <= sat_inc32(active_cycles_q);
                                state_q           <= ST_HOLD_RESPONSE;
                            end
                        end else if (!operand_q[31] && (operand_q > 32'h42b17217)) begin
                            rsp_valid_q       <= 1'b1;
                            result_q          <= 32'h7f800000;
                            flags_q           <= 5'h05;
                            error_q           <= 1'b0;
                            error_code_q      <= ERR_OK;
                            response_cycles_q <= sat_inc32(active_cycles_q);
                            state_q           <= ST_HOLD_RESPONSE;
                        end else if (operand_q[31] &&
                                     (operand_q[30:0] > 31'h42cff1b4)) begin
                            rsp_valid_q       <= 1'b1;
                            result_q          <= 32'h00000000;
                            flags_q           <= 5'h03;
                            error_q           <= 1'b0;
                            error_code_q      <= ERR_OK;
                            response_cycles_q <= sat_inc32(active_cycles_q);
                            state_q           <= ST_HOLD_RESPONSE;
                        end else begin
                            state_q <= ST_X64_REQ;
                        end
                    end

                    ST_X64_REQ: begin
                        if (x64_req_valid && x64_req_ready) begin
                            state_q <= ST_X64_WAIT;
                        end
                    end
                    ST_X64_WAIT: begin
                        if (x64_rsp_valid && x64_rsp_ready) begin
                            xd_q    <= x64_rsp_result;
                            state_q <= ST_Z_REQ;
                        end
                    end
                    ST_Z_REQ: begin
                        if (fma_req_valid && fma_req_ready) begin
                            state_q <= ST_Z_WAIT;
                        end
                    end
                    ST_Z_WAIT: begin
                        if (fma_rsp_valid && fma_rsp_ready) begin
                            z_q           <= fma_rsp_result;
                            flags_accum_q <= flags_accum_q | fma_rsp_flags;
                            state_q       <= ST_K_REQ;
                        end
                    end
                    ST_K_REQ: begin
                        if (k_req_valid && k_req_ready) begin
                            state_q <= ST_K_WAIT;
                        end
                    end
                    ST_K_WAIT: begin
                        if (k_rsp_valid && k_rsp_ready) begin
                            k_q           <= k_rsp_result;
                            table_index_q <= k_rsp_result[4:0];
                            state_q       <= ST_KD_REQ;
                        end
                    end
                    ST_KD_REQ: begin
                        if (kd_req_valid && kd_req_ready) begin
                            state_q <= ST_KD_WAIT;
                        end
                    end
                    ST_KD_WAIT: begin
                        if (kd_rsp_valid && kd_rsp_ready) begin
                            kd_q    <= kd_rsp_result;
                            state_q <= ST_KD_ZERO_SIGN;
                        end
                    end
                    ST_KD_ZERO_SIGN: begin
                        if (k_q == 32'b0) begin
                            kd_q <= {z_q[63], kd_q[62:0]};
                        end
                        state_q <= ST_R_REQ;
                    end
                    ST_R_REQ: begin
                        if (fma_req_valid && fma_req_ready) begin
                            state_q <= ST_R_WAIT;
                        end
                    end
                    ST_R_WAIT: begin
                        if (fma_rsp_valid && fma_rsp_ready) begin
                            r_q           <= fma_rsp_result;
                            flags_accum_q <= flags_accum_q | fma_rsp_flags;
                            state_q       <= ST_SCALE_INTEGER;
                        end
                    end
                    ST_SCALE_INTEGER: begin
                        table_index_q <= k_q[4:0];
                        scale_q       <= scale_comb;
                        state_q       <= ST_P01_REQ;
                    end
                    ST_P01_REQ: begin
                        if (fma_req_valid && fma_req_ready) begin
                            state_q <= ST_P01_WAIT;
                        end
                    end
                    ST_P01_WAIT: begin
                        if (fma_rsp_valid && fma_rsp_ready) begin
                            p01_q         <= fma_rsp_result;
                            flags_accum_q <= flags_accum_q | fma_rsp_flags;
                            state_q       <= ST_R2_REQ;
                        end
                    end
                    ST_R2_REQ: begin
                        if (fma_req_valid && fma_req_ready) begin
                            state_q <= ST_R2_WAIT;
                        end
                    end
                    ST_R2_WAIT: begin
                        if (fma_rsp_valid && fma_rsp_ready) begin
                            r2_q          <= fma_rsp_result;
                            flags_accum_q <= flags_accum_q | fma_rsp_flags;
                            state_q       <= ST_P2_REQ;
                        end
                    end
                    ST_P2_REQ: begin
                        if (fma_req_valid && fma_req_ready) begin
                            state_q <= ST_P2_WAIT;
                        end
                    end
                    ST_P2_WAIT: begin
                        if (fma_rsp_valid && fma_rsp_ready) begin
                            p2_q          <= fma_rsp_result;
                            flags_accum_q <= flags_accum_q | fma_rsp_flags;
                            state_q       <= ST_P_REQ;
                        end
                    end
                    ST_P_REQ: begin
                        if (fma_req_valid && fma_req_ready) begin
                            state_q <= ST_P_WAIT;
                        end
                    end
                    ST_P_WAIT: begin
                        if (fma_rsp_valid && fma_rsp_ready) begin
                            p_q           <= fma_rsp_result;
                            flags_accum_q <= flags_accum_q | fma_rsp_flags;
                            state_q       <= ST_Y_REQ;
                        end
                    end
                    ST_Y_REQ: begin
                        if (fma_req_valid && fma_req_ready) begin
                            state_q <= ST_Y_WAIT;
                        end
                    end
                    ST_Y_WAIT: begin
                        if (fma_rsp_valid && fma_rsp_ready) begin
                            y_q           <= fma_rsp_result;
                            flags_accum_q <= flags_accum_q | fma_rsp_flags;
                            state_q       <= ST_PACK_REQ;
                        end
                    end
                    ST_PACK_REQ: begin
                        if (pack_req_valid && pack_req_ready) begin
                            state_q <= ST_PACK_WAIT;
                        end
                    end
                    ST_PACK_WAIT: begin
                        if (pack_rsp_valid && pack_rsp_ready) begin
                            rsp_valid_q       <= 1'b1;
                            result_q          <= pack_rsp_result;
                            flags_q           <= flags_accum_q | pack_rsp_flags;
                            error_q           <= 1'b0;
                            error_code_q      <= ERR_OK;
                            response_cycles_q <= sat_inc32(active_cycles_q);
                            state_q           <= ST_HOLD_RESPONSE;
                        end
                    end
                    ST_ABORT_RESET: begin
                        rsp_valid_q       <= 1'b1;
                        result_q          <= 32'b0;
                        flags_q           <= 5'b0;
                        error_q           <= 1'b1;
                        error_code_q      <= pending_error_code_q;
                        response_cycles_q <= sat_inc32(active_cycles_q);
                        state_q           <= ST_HOLD_RESPONSE;
                    end
                    ST_HOLD_RESPONSE: begin
                        if (rsp_valid_q && rsp_ready_i) begin
                            rsp_valid_q <= 1'b0;
                            state_q     <= ST_IDLE;
                        end
                    end
                    default: begin
                        pending_error_code_q <= ERR_PROTOCOL;
                        state_q              <= ST_ABORT_RESET;
                    end
                endcase
            end
        end
    end

endmodule
