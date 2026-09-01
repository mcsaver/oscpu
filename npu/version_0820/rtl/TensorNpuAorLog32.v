`timescale 1ns/1ps

// SPDX-License-Identifier: MIT
//
// AOR_AARCH64_FMA_RNE_V1 LOG32 source-replay datapath.
// Constants/table are derived from Arm optimized-routines commit
// 67126040cf80f956676fbf473c2d9bebdb475283, math/logf.c and math/logf_data.c.
// Copyright (c) 2018-2023, Arm Limited. SPDX MIT path selected by the manifest.
module TensorNpuAorLog32 #(
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
    localparam [4:0] ST_NORMALIZE     = 5'd2;
    localparam [4:0] ST_REDUCE        = 5'd3;
    localparam [4:0] ST_Z64_REQ       = 5'd4;
    localparam [4:0] ST_Z64_WAIT      = 5'd5;
    localparam [4:0] ST_R_REQ         = 5'd6;
    localparam [4:0] ST_R_WAIT        = 5'd7;
    localparam [4:0] ST_KD_REQ        = 5'd8;
    localparam [4:0] ST_KD_WAIT       = 5'd9;
    localparam [4:0] ST_Y0_REQ        = 5'd10;
    localparam [4:0] ST_Y0_WAIT       = 5'd11;
    localparam [4:0] ST_R2_REQ        = 5'd12;
    localparam [4:0] ST_R2_WAIT       = 5'd13;
    localparam [4:0] ST_P12_REQ       = 5'd14;
    localparam [4:0] ST_P12_WAIT      = 5'd15;
    localparam [4:0] ST_P0_REQ        = 5'd16;
    localparam [4:0] ST_P0_WAIT       = 5'd17;
    localparam [4:0] ST_TAIL_REQ      = 5'd18;
    localparam [4:0] ST_TAIL_WAIT     = 5'd19;
    localparam [4:0] ST_Y_REQ         = 5'd20;
    localparam [4:0] ST_Y_WAIT        = 5'd21;
    localparam [4:0] ST_PACK_REQ      = 5'd22;
    localparam [4:0] ST_PACK_WAIT     = 5'd23;
    localparam [4:0] ST_ABORT_RESET   = 5'd24;
    localparam [4:0] ST_HOLD_RESPONSE = 5'd25;

    localparam [31:0] TIMEOUT_LIMIT = COMMAND_TIMEOUT_CYCLES;

    localparam [63:0] F64_ZERO    = 64'h0000000000000000;
    localparam [63:0] F64_ONE     = 64'h3ff0000000000000;
    localparam [63:0] F64_NEG_ONE = 64'hbff0000000000000;
    localparam [63:0] LOG_LN2     = 64'h3fe62e42fefa39ef;
    localparam [63:0] LOG_A0      = 64'hbfd00ea348b88334;
    localparam [63:0] LOG_A1      = 64'h3fd5575b0be00b6a;
    localparam [63:0] LOG_A2      = 64'hbfdffffef20a4123;

    function [31:0] sat_inc32;
        input [31:0] value;
        begin
            sat_inc32 = (&value) ? value : (value + 32'd1);
        end
    endfunction

    // 23 项 if/else 综合为 23-bit leading-one priority encoder，返回 floor(log2(frac))。
    function [4:0] highest_one23;
        input [22:0] value;
        begin
            if      (value[22]) highest_one23 = 5'd22;
            else if (value[21]) highest_one23 = 5'd21;
            else if (value[20]) highest_one23 = 5'd20;
            else if (value[19]) highest_one23 = 5'd19;
            else if (value[18]) highest_one23 = 5'd18;
            else if (value[17]) highest_one23 = 5'd17;
            else if (value[16]) highest_one23 = 5'd16;
            else if (value[15]) highest_one23 = 5'd15;
            else if (value[14]) highest_one23 = 5'd14;
            else if (value[13]) highest_one23 = 5'd13;
            else if (value[12]) highest_one23 = 5'd12;
            else if (value[11]) highest_one23 = 5'd11;
            else if (value[10]) highest_one23 = 5'd10;
            else if (value[9])  highest_one23 = 5'd9;
            else if (value[8])  highest_one23 = 5'd8;
            else if (value[7])  highest_one23 = 5'd7;
            else if (value[6])  highest_one23 = 5'd6;
            else if (value[5])  highest_one23 = 5'd5;
            else if (value[4])  highest_one23 = 5'd4;
            else if (value[3])  highest_one23 = 5'd3;
            else if (value[2])  highest_one23 = 5'd2;
            else if (value[1])  highest_one23 = 5'd1;
            else if (value[0])  highest_one23 = 5'd0;
            else                highest_one23 = 5'd31;
        end
    endfunction

    reg [4:0] state_q;
    reg [31:0] operand_q;
    reg [31:0] ix_q;
    reg [31:0] tmp_q;
    reg [3:0] table_index_q;
    reg [31:0] k_q;
    reg [31:0] iz_q;
    reg [63:0] z_q;
    reg [63:0] r_q;
    reg [63:0] kd_q;
    reg [63:0] y0_q;
    reg [63:0] r2_q;
    reg [63:0] p12_q;
    reg [63:0] p0_q;
    reg [63:0] tail_q;
    reg [63:0] y_q;
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

    // Positive subnormal exact normalization network; shifts are raw U32 operations.
    wire [4:0] subnormal_m = highest_one23(operand_q[22:0]);
    wire [7:0] subnormal_y_exp = {3'b000, subnormal_m} + 8'd1;
    wire [22:0] subnormal_frac_shifted =
        operand_q[22:0] << (5'd23 - subnormal_m);
    wire [31:0] subnormal_iy =
        {1'b0, subnormal_y_exp, subnormal_frac_shifted};
    wire [31:0] subnormal_ix = subnormal_iy - 32'h0b800000;

    wire [31:0] tmp_comb = ix_q - 32'h3f330000;
    wire signed [31:0] tmp_signed = tmp_comb;
    wire [31:0] k_comb = tmp_signed >>> 23;
    wire [31:0] iz_comb = ix_q - (tmp_comb & 32'hff800000);

    // LOG ROM：16 对 invc/logc 综合为两棵只读 mux tree；default 触发内部 fault。
    reg [63:0] log_invc_raw;
    reg [63:0] log_logc_raw;
    reg        log_table_valid;
    always @(*) begin
        log_invc_raw    = 64'b0;
        log_logc_raw    = 64'b0;
        log_table_valid = 1'b1;
        case (table_index_q)
            4'd0:  begin log_invc_raw = 64'h3ff661ec79f8f3be; log_logc_raw = 64'hbfd57bf7808caade; end
            4'd1:  begin log_invc_raw = 64'h3ff571ed4aaf883d; log_logc_raw = 64'hbfd2bef0a7c06ddb; end
            4'd2:  begin log_invc_raw = 64'h3ff49539f0f010b0; log_logc_raw = 64'hbfd01eae7f513a67; end
            4'd3:  begin log_invc_raw = 64'h3ff3c995b0b80385; log_logc_raw = 64'hbfcb31d8a68224e9; end
            4'd4:  begin log_invc_raw = 64'h3ff30d190c8864a5; log_logc_raw = 64'hbfc6574f0ac07758; end
            4'd5:  begin log_invc_raw = 64'h3ff25e227b0b8ea0; log_logc_raw = 64'hbfc1aa2bc79c8100; end
            4'd6:  begin log_invc_raw = 64'h3ff1bb4a4a1a343f; log_logc_raw = 64'hbfba4e76ce8c0e5e; end
            4'd7:  begin log_invc_raw = 64'h3ff12358f08ae5ba; log_logc_raw = 64'hbfb1973c5a611ccc; end
            4'd8:  begin log_invc_raw = 64'h3ff0953f419900a7; log_logc_raw = 64'hbfa252f438e10c1e; end
            4'd9:  begin log_invc_raw = 64'h3ff0000000000000; log_logc_raw = 64'h0000000000000000; end
            4'd10: begin log_invc_raw = 64'h3fee608cfd9a47ac; log_logc_raw = 64'h3faaa5aa5df25984; end
            4'd11: begin log_invc_raw = 64'h3feca4b31f026aa0; log_logc_raw = 64'h3fbc5e53aa362eb4; end
            4'd12: begin log_invc_raw = 64'h3feb2036576afce6; log_logc_raw = 64'h3fc526e57720db08; end
            4'd13: begin log_invc_raw = 64'h3fe9c2d163a1aa2d; log_logc_raw = 64'h3fcbc2860d224770; end
            4'd14: begin log_invc_raw = 64'h3fe886e6037841ed; log_logc_raw = 64'h3fd1058bc8a07ee1; end
            4'd15: begin log_invc_raw = 64'h3fe767dcf5534862; log_logc_raw = 64'h3fd4043057b6ee09; end
            default: begin
                log_invc_raw    = 64'b0;
                log_logc_raw    = 64'b0;
                log_table_valid = 1'b0;
            end
        endcase
    end

    // Child 1：range-reduced F32 iz -> exact F64 z。
    wire        z64_req_valid = (state_q == ST_Z64_REQ);
    wire        z64_req_ready;
    wire        z64_rsp_valid;
    wire        z64_rsp_ready = (state_q == ST_Z64_WAIT);
    wire [63:0] z64_rsp_result;
    wire [4:0]  z64_rsp_flags;
    wire        z64_rsp_error;
    TensorNpuFp32ToFp64 u_z64 (
        .clk_i       (clk_i),
        .rst_i       (child_rst),
        .req_valid_i (z64_req_valid),
        .req_ready_o (z64_req_ready),
        .operand_i   (iz_q),
        .rsp_valid_o (z64_rsp_valid),
        .rsp_ready_i (z64_rsp_ready),
        .result_o    (z64_rsp_result),
        .flags_o     (z64_rsp_flags),
        .error_o     (z64_rsp_error)
    );

    // Child 2：唯一共享 FMA；MUL 与独立 y0+r ADD 都经此 mux。
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
            ST_R_REQ: begin
                fma_operand_a = z_q;
                fma_operand_b = log_invc_raw;
                fma_operand_c = F64_NEG_ONE;
                fma_req_valid = 1'b1;
            end
            ST_R_WAIT: fma_rsp_ready = 1'b1;
            ST_Y0_REQ: begin
                fma_operand_a = kd_q;
                fma_operand_b = LOG_LN2;
                fma_operand_c = log_logc_raw;
                fma_req_valid = 1'b1;
            end
            ST_Y0_WAIT: fma_rsp_ready = 1'b1;
            ST_R2_REQ: begin
                fma_operand_a = r_q;
                fma_operand_b = r_q;
                fma_operand_c = F64_ZERO;
                fma_req_valid = 1'b1;
            end
            ST_R2_WAIT: fma_rsp_ready = 1'b1;
            ST_P12_REQ: begin
                fma_operand_a = LOG_A1;
                fma_operand_b = r_q;
                fma_operand_c = LOG_A2;
                fma_req_valid = 1'b1;
            end
            ST_P12_WAIT: fma_rsp_ready = 1'b1;
            ST_P0_REQ: begin
                fma_operand_a = LOG_A0;
                fma_operand_b = r2_q;
                fma_operand_c = p12_q;
                fma_req_valid = 1'b1;
            end
            ST_P0_WAIT: fma_rsp_ready = 1'b1;
            ST_TAIL_REQ: begin
                fma_operand_a = F64_ONE;
                fma_operand_b = y0_q;
                fma_operand_c = r_q;
                fma_req_valid = 1'b1;
            end
            ST_TAIL_WAIT: fma_rsp_ready = 1'b1;
            ST_Y_REQ: begin
                fma_operand_a = p0_q;
                fma_operand_b = r2_q;
                fma_operand_c = tail_q;
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

    // Child 3：integer ASR range-reduction k -> exact F64 kd。
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

    // Child 4：signed finite F64 final y -> F32 pack。
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
        (state_q == ST_R_WAIT) || (state_q == ST_Y0_WAIT) ||
        (state_q == ST_R2_WAIT) || (state_q == ST_P12_WAIT) ||
        (state_q == ST_P0_WAIT) || (state_q == ST_TAIL_WAIT) ||
        (state_q == ST_Y_WAIT);
    wire any_child_rsp_valid =
        z64_rsp_valid || fma_rsp_valid || kd_rsp_valid || pack_rsp_valid;
    wire ghost_response_now =
        (z64_rsp_valid && (state_q != ST_Z64_WAIT)) ||
        (fma_rsp_valid && !fma_wait_state) ||
        (kd_rsp_valid && (state_q != ST_KD_WAIT)) ||
        (pack_rsp_valid && (state_q != ST_PACK_WAIT));

    wire z64_fault_now = (state_q == ST_Z64_WAIT) && z64_rsp_valid &&
        (z64_rsp_error || (z64_rsp_flags != 5'b0) ||
         (z64_rsp_result[62:52] == 11'h7ff));
    wire fma_fault_now = fma_wait_state && fma_rsp_valid &&
        ((fma_rsp_flags[4:1] != 4'b0) ||
         (fma_rsp_result[62:52] == 11'h7ff));
    wire kd_fault_now = (state_q == ST_KD_WAIT) && kd_rsp_valid &&
        ((kd_rsp_flags != 5'b0) || (kd_rsp_result[62:52] == 11'h7ff));
    wire pack_fault_now = (state_q == ST_PACK_WAIT) && pack_rsp_valid && pack_rsp_error;
    wire child_profile_fault_now =
        z64_fault_now || fma_fault_now || kd_fault_now || pack_fault_now;

    reg state_valid;
    always @(*) begin
        state_valid = 1'b1;
        case (state_q)
            ST_IDLE, ST_CLASSIFY, ST_NORMALIZE, ST_REDUCE,
            ST_Z64_REQ, ST_Z64_WAIT, ST_R_REQ, ST_R_WAIT,
            ST_KD_REQ, ST_KD_WAIT, ST_Y0_REQ, ST_Y0_WAIT,
            ST_R2_REQ, ST_R2_WAIT, ST_P12_REQ, ST_P12_WAIT,
            ST_P0_REQ, ST_P0_WAIT, ST_TAIL_REQ, ST_TAIL_WAIT,
            ST_Y_REQ, ST_Y_WAIT, ST_PACK_REQ, ST_PACK_WAIT,
            ST_ABORT_RESET, ST_HOLD_RESPONSE: state_valid = 1'b1;
            default: state_valid = 1'b0;
        endcase
    end

    wire rom_use_state =
        (state_q == ST_R_REQ) || (state_q == ST_R_WAIT) ||
        (state_q == ST_Y0_REQ) || (state_q == ST_Y0_WAIT);
    wire range_register_fault_now =
        (state_q == ST_Z64_REQ) &&
        ((tmp_q != (ix_q - 32'h3f330000)) ||
         (table_index_q != tmp_q[22:19]));
    wire internal_fault_now =
        !state_valid ||
        ((state_q != ST_ABORT_RESET) && (state_q != ST_HOLD_RESPONSE) &&
         (ghost_response_now || range_register_fault_now ||
          (rom_use_state && !log_table_valid)));
    wire command_timeout_now =
        (state_q != ST_IDLE) && (state_q != ST_ABORT_RESET) &&
        (state_q != ST_HOLD_RESPONSE) &&
        (watchdog_q >= TIMEOUT_LIMIT);

    assign req_ready_o = !rst_i && (state_q == ST_IDLE) &&
                         !rsp_valid_q && !any_child_rsp_valid;

    // 单一 posedge owner。全局优先级：reset > internal/child fault > timeout > normal progress。
    always @(posedge clk_i) begin
        if (rst_i) begin
            state_q              <= ST_IDLE;
            operand_q            <= 32'b0;
            ix_q                 <= 32'b0;
            tmp_q                <= 32'b0;
            table_index_q        <= 4'b0;
            k_q                  <= 32'b0;
            iz_q                 <= 32'b0;
            z_q                  <= 64'b0;
            r_q                  <= 64'b0;
            kd_q                 <= 64'b0;
            y0_q                 <= 64'b0;
            r2_q                 <= 64'b0;
            p12_q                <= 64'b0;
            p0_q                 <= 64'b0;
            tail_q               <= 64'b0;
            y_q                  <= 64'b0;
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
                        if (operand_q == 32'h3f800000) begin
                            rsp_valid_q       <= 1'b1;
                            result_q          <= 32'h00000000;
                            flags_q           <= 5'b0;
                            error_q           <= 1'b0;
                            error_code_q      <= ERR_OK;
                            response_cycles_q <= sat_inc32(active_cycles_q);
                            state_q           <= ST_HOLD_RESPONSE;
                        end else if (operand_q[30:0] == 31'b0) begin
                            rsp_valid_q       <= 1'b1;
                            result_q          <= 32'hff800000;
                            flags_q           <= 5'h08;
                            error_q           <= 1'b0;
                            error_code_q      <= ERR_OK;
                            response_cycles_q <= sat_inc32(active_cycles_q);
                            state_q           <= ST_HOLD_RESPONSE;
                        end else if (operand_q[30:23] == 8'hff) begin
                            if (!operand_q[31] && (operand_q[22:0] == 23'b0)) begin
                                rsp_valid_q       <= 1'b1;
                                result_q          <= 32'h7f800000;
                                flags_q           <= 5'b0;
                                error_q           <= 1'b0;
                                error_code_q      <= ERR_OK;
                                response_cycles_q <= sat_inc32(active_cycles_q);
                                state_q           <= ST_HOLD_RESPONSE;
                            end else begin
                                pending_error_code_q <= ERR_UNSUPPORTED;
                                state_q              <= ST_ABORT_RESET;
                            end
                        end else if (operand_q[31]) begin
                            pending_error_code_q <= ERR_UNSUPPORTED;
                            state_q              <= ST_ABORT_RESET;
                        end else begin
                            state_q <= ST_NORMALIZE;
                        end
                    end

                    ST_NORMALIZE: begin
                        if (operand_q[30:23] == 8'b0) begin
                            ix_q <= subnormal_ix;
                        end else begin
                            ix_q <= operand_q;
                        end
                        state_q <= ST_REDUCE;
                    end
                    ST_REDUCE: begin
                        tmp_q         <= tmp_comb;
                        table_index_q <= tmp_comb[22:19];
                        k_q           <= k_comb;
                        iz_q          <= iz_comb;
                        state_q       <= ST_Z64_REQ;
                    end
                    ST_Z64_REQ: begin
                        if (z64_req_valid && z64_req_ready) begin
                            state_q <= ST_Z64_WAIT;
                        end
                    end
                    ST_Z64_WAIT: begin
                        if (z64_rsp_valid && z64_rsp_ready) begin
                            z_q     <= z64_rsp_result;
                            state_q <= ST_R_REQ;
                        end
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
                            state_q <= ST_Y0_REQ;
                        end
                    end
                    ST_Y0_REQ: begin
                        if (fma_req_valid && fma_req_ready) begin
                            state_q <= ST_Y0_WAIT;
                        end
                    end
                    ST_Y0_WAIT: begin
                        if (fma_rsp_valid && fma_rsp_ready) begin
                            y0_q          <= fma_rsp_result;
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
                            state_q       <= ST_P12_REQ;
                        end
                    end
                    ST_P12_REQ: begin
                        if (fma_req_valid && fma_req_ready) begin
                            state_q <= ST_P12_WAIT;
                        end
                    end
                    ST_P12_WAIT: begin
                        if (fma_rsp_valid && fma_rsp_ready) begin
                            p12_q         <= fma_rsp_result;
                            flags_accum_q <= flags_accum_q | fma_rsp_flags;
                            state_q       <= ST_P0_REQ;
                        end
                    end
                    ST_P0_REQ: begin
                        if (fma_req_valid && fma_req_ready) begin
                            state_q <= ST_P0_WAIT;
                        end
                    end
                    ST_P0_WAIT: begin
                        if (fma_rsp_valid && fma_rsp_ready) begin
                            p0_q          <= fma_rsp_result;
                            flags_accum_q <= flags_accum_q | fma_rsp_flags;
                            state_q       <= ST_TAIL_REQ;
                        end
                    end
                    ST_TAIL_REQ: begin
                        if (fma_req_valid && fma_req_ready) begin
                            state_q <= ST_TAIL_WAIT;
                        end
                    end
                    ST_TAIL_WAIT: begin
                        if (fma_rsp_valid && fma_rsp_ready) begin
                            tail_q        <= fma_rsp_result;
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
