`timescale 1ns/1ps

// SPDX-License-Identifier: MIT
//
// TENSOR_NPU_UNARY_GLU_F32_RNE_V1 单元素 reference transaction。
//
// 阶段 1/2a--2e 推导见 tmp/logs/unary-glu-element/rtl-derivation.md。
// 本模块严格顺序 materialize EXP/ADD/DIV/LOG/MUL child response；公开
// opcode 4直接提交第一阶段EXP结果，其余opcode保持既有严格DAG。不做
// reciprocal*mul、numerator-first、LOG1P、FMA 或跨节点重结合。
module TensorNpuUnaryGluElement #(
    parameter integer COMMAND_TIMEOUT_CYCLES = 256
) (
    input  wire        clk_i,
    input  wire        rst_i,

    input  wire        req_valid_i,
    output wire        req_ready_o,
    input  wire [2:0]  opcode_i,
    input  wire [31:0] src0_bits_i,
    input  wire [31:0] src1_bits_i,

    output wire        rsp_valid_o,
    input  wire        rsp_ready_i,
    output wire [31:0] result_bits_o,
    output wire [4:0]  flags_o,
    output wire        error_o,
    output wire [3:0]  error_code_o,
    output wire [4:0]  child_call_mask_o,
    output wire [31:0] active_cycles_o
);

    localparam [2:0] OP_SIGMOID = 3'd0;
    localparam [2:0] OP_SOFTPLUS = 3'd1;
    localparam [2:0] OP_SWIGLU = 3'd3;
    localparam [2:0] OP_EXP = 3'd4;

    localparam [3:0] ERR_OK          = 4'd0;
    localparam [3:0] ERR_UNSUPPORTED = 4'd1;
    localparam [3:0] ERR_CHILD       = 4'd2;
    localparam [3:0] ERR_TIMEOUT     = 4'd3;
    localparam [3:0] ERR_PROTOCOL    = 4'd4;

    localparam [3:0] ST_IDLE          = 4'd0;
    localparam [3:0] ST_PREFLIGHT     = 4'd1;
    localparam [3:0] ST_EXP_REQ       = 4'd2;
    localparam [3:0] ST_EXP_WAIT      = 4'd3;
    localparam [3:0] ST_ADD_REQ       = 4'd4;
    localparam [3:0] ST_ADD_WAIT      = 4'd5;
    localparam [3:0] ST_DIV_REQ       = 4'd6;
    localparam [3:0] ST_DIV_WAIT      = 4'd7;
    localparam [3:0] ST_LOG_REQ       = 4'd8;
    localparam [3:0] ST_LOG_WAIT      = 4'd9;
    localparam [3:0] ST_MUL_REQ       = 4'd10;
    localparam [3:0] ST_MUL_WAIT      = 4'd11;
    localparam [3:0] ST_ABORT_RESET   = 4'd12;
    localparam [3:0] ST_HOLD_RESPONSE = 4'd13;

    localparam [2:0] OWNER_EXP = 3'd0;
    localparam [2:0] OWNER_ADD = 3'd1;
    localparam [2:0] OWNER_DIV = 3'd2;
    localparam [2:0] OWNER_LOG = 3'd3;
    localparam [2:0] OWNER_MUL = 3'd4;

    localparam [31:0] F32_ONE = 32'h3f800000;
    localparam [31:0] F32_TWENTY = 32'h41a00000;
    localparam [31:0] TIMEOUT_LIMIT = COMMAND_TIMEOUT_CYCLES;

    function [31:0] sat_inc32;
        input [31:0] value;
        begin
            sat_inc32 = (&value) ? value : (value + 32'd1);
        end
    endfunction

    // 小型 raw predicate 综合为 exponent/fraction 比较器，不包含算术状态。
    function is_nan31;
        input [30:0] value;
        begin
            is_nan31 = (value[30:23] == 8'hff) && (value[22:0] != 23'b0);
        end
    endfunction

    reg [3:0] state_q;
    reg       resident_q;
    reg       owner_valid_q;
    reg [2:0] owner_q;

    reg [2:0]  opcode_q;
    reg [31:0] src0_q;
    reg [31:0] src1_q;
    reg [31:0] exp_result_q;
    reg [31:0] add_result_q;
    reg [31:0] div_result_q;
    reg [4:0]  flags_accum_q;
    reg [4:0]  call_mask_q;
    reg [31:0] watchdog_q;
    reg [31:0] active_cycles_q;
    reg [3:0]  pending_error_code_q;

    reg        rsp_valid_q;
    reg [31:0] response_result_q;
    reg [4:0]  response_flags_q;
    reg        response_error_q;
    reg [3:0]  response_error_code_q;
    reg [4:0]  response_call_mask_q;
    reg [31:0] response_cycles_q;

    // child_rst 只由当前注册态产生；父 holding payload不受 child_rst 清除。
    wire abort_reset = (state_q == ST_ABORT_RESET);
    wire terminal_quarantine = (state_q == ST_HOLD_RESPONSE);
    wire child_rst = rst_i || abort_reset || terminal_quarantine;

    assign rsp_valid_o       = !rst_i && rsp_valid_q;
    assign result_bits_o     = response_result_q;
    assign flags_o           = response_flags_q;
    assign error_o           = response_error_q;
    assign error_code_o      = response_error_code_q;
    assign child_call_mask_o = response_call_mask_q;
    assign active_cycles_o   = response_cycles_q;

    // Child 0：AOR EXP32。SOFTPLUS不取反，其余本地 raw sign XOR。
    wire [31:0] exp_operand =
        ((opcode_q == OP_SOFTPLUS) || (opcode_q == OP_EXP))
            ? src0_q : (src0_q ^ 32'h80000000);
    wire        exp_req_valid;
    wire        exp_req_ready;
    wire        exp_rsp_valid;
    wire        exp_rsp_ready;
    wire [31:0] exp_rsp_result;
    wire [4:0]  exp_rsp_flags;
    wire        exp_rsp_error;
    wire [3:0]  exp_rsp_error_code;
    /* verilator lint_off UNUSEDSIGNAL */
    wire [31:0] exp_rsp_active_cycles_unused;
    /* verilator lint_on UNUSEDSIGNAL */

    TensorNpuAorExp32 #(
        .COMMAND_TIMEOUT_CYCLES(128)
    ) u_exp (
        .clk_i          (clk_i),
        .rst_i          (child_rst),
        .req_valid_i    (exp_req_valid),
        .req_ready_o    (exp_req_ready),
        .operand_i      (exp_operand),
        .rsp_valid_o    (exp_rsp_valid),
        .rsp_ready_i    (exp_rsp_ready),
        .result_o       (exp_rsp_result),
        .flags_o        (exp_rsp_flags),
        .error_o        (exp_rsp_error),
        .error_code_o   (exp_rsp_error_code),
        .active_cycles_o(exp_rsp_active_cycles_unused)
    );

    // Child 1/4：ADD 与 MUL共享一个 registered fp_fma wrapper；state显式选择op/mux。
    wire        addmul_req_valid;
    wire        addmul_req_ready;
    wire        addmul_rsp_valid;
    wire        addmul_rsp_ready;
    wire        addmul_op_mul = (state_q == ST_MUL_REQ) || (state_q == ST_MUL_WAIT);
    wire [31:0] addmul_lhs = addmul_op_mul ? div_result_q : F32_ONE;
    wire [31:0] addmul_rhs = addmul_op_mul ? src1_q : exp_result_q;
    wire [31:0] addmul_rsp_result;
    wire [4:0]  addmul_rsp_flags;

    TensorNpuFp32AddMul u_addmul (
        .clk_i         (clk_i),
        .rst_i         (child_rst),
        .req_valid_i   (addmul_req_valid),
        .req_ready_o   (addmul_req_ready),
        .op_mul_i      (addmul_op_mul),
        .lhs_bits_i    (addmul_lhs),
        .rhs_bits_i    (addmul_rhs),
        .rsp_valid_o   (addmul_rsp_valid),
        .rsp_ready_i   (addmul_rsp_ready),
        .result_bits_o (addmul_rsp_result),
        .flags_o       (addmul_rsp_flags)
    );

    // Child 2：固定 PERFORMANCE=0 DIV wrapper；SIGMOID numerator固定1.0。
    wire        div_req_valid;
    wire        div_req_ready;
    wire        div_rsp_valid;
    wire        div_rsp_ready;
    wire [31:0] div_lhs = (opcode_q == OP_SIGMOID) ? F32_ONE : src0_q;
    wire [31:0] div_rsp_result;
    wire [4:0]  div_rsp_flags;

    TensorNpuFp32Div u_div (
        .clk_i         (clk_i),
        .rst_i         (child_rst),
        .req_valid_i   (div_req_valid),
        .req_ready_o   (div_req_ready),
        .lhs_bits_i    (div_lhs),
        .rhs_bits_i    (add_result_q),
        .rsp_valid_o   (div_rsp_valid),
        .rsp_ready_i   (div_rsp_ready),
        .result_bits_o (div_rsp_result),
        .flags_o       (div_rsp_flags)
    );

    // Child 3：AOR LOG32只在SOFTPLUS slow path拥有事务。
    wire        log_req_valid;
    wire        log_req_ready;
    wire        log_rsp_valid;
    wire        log_rsp_ready;
    wire [31:0] log_rsp_result;
    wire [4:0]  log_rsp_flags;
    wire        log_rsp_error;
    wire [3:0]  log_rsp_error_code;
    /* verilator lint_off UNUSEDSIGNAL */
    wire [31:0] log_rsp_active_cycles_unused;
    /* verilator lint_on UNUSEDSIGNAL */

    TensorNpuAorLog32 #(
        .COMMAND_TIMEOUT_CYCLES(128)
    ) u_log (
        .clk_i          (clk_i),
        .rst_i          (child_rst),
        .req_valid_i    (log_req_valid),
        .req_ready_o    (log_req_ready),
        .operand_i      (add_result_q),
        .rsp_valid_o    (log_rsp_valid),
        .rsp_ready_i    (log_rsp_ready),
        .result_o       (log_rsp_result),
        .flags_o        (log_rsp_flags),
        .error_o        (log_rsp_error),
        .error_code_o   (log_rsp_error_code),
        .active_cycles_o(log_rsp_active_cycles_unused)
    );

    wire any_child_rsp_valid =
        exp_rsp_valid || addmul_rsp_valid || div_rsp_valid || log_rsp_valid;

    // 状态本身是response owner；任一其它child completion都是wrong-owner/ghost。
    wire ghost_response_now =
        (exp_rsp_valid && (state_q != ST_EXP_WAIT)) ||
        (addmul_rsp_valid &&
         (state_q != ST_ADD_WAIT) && (state_q != ST_MUL_WAIT)) ||
        (div_rsp_valid && (state_q != ST_DIV_WAIT)) ||
        (log_rsp_valid && (state_q != ST_LOG_WAIT));

    reg state_valid;
    always @(*) begin
        state_valid = 1'b1;
        case (state_q)
            ST_IDLE, ST_PREFLIGHT,
            ST_EXP_REQ, ST_EXP_WAIT,
            ST_ADD_REQ, ST_ADD_WAIT,
            ST_DIV_REQ, ST_DIV_WAIT,
            ST_LOG_REQ, ST_LOG_WAIT,
            ST_MUL_REQ, ST_MUL_WAIT,
            ST_ABORT_RESET, ST_HOLD_RESPONSE: state_valid = 1'b1;
            default: state_valid = 1'b0;
        endcase
    end

    // owner/state守恒：WAIT必须有matching owner，其余执行态不得残留owner。
    reg owner_state_fault;
    always @(*) begin
        owner_state_fault = 1'b0;
        case (state_q)
            ST_EXP_WAIT: owner_state_fault = !owner_valid_q || (owner_q != OWNER_EXP);
            ST_ADD_WAIT: owner_state_fault = !owner_valid_q || (owner_q != OWNER_ADD);
            ST_DIV_WAIT: owner_state_fault = !owner_valid_q || (owner_q != OWNER_DIV);
            ST_LOG_WAIT: owner_state_fault = !owner_valid_q || (owner_q != OWNER_LOG);
            ST_MUL_WAIT: owner_state_fault = !owner_valid_q || (owner_q != OWNER_MUL);
            ST_ABORT_RESET, ST_HOLD_RESPONSE: owner_state_fault = 1'b0;
            default: owner_state_fault = owner_valid_q;
        endcase
    end

    wire exp_child_fault = (state_q == ST_EXP_WAIT) && exp_rsp_valid &&
        (exp_rsp_error || (exp_rsp_error_code != ERR_OK) ||
         exp_rsp_flags[4] || exp_rsp_flags[3] || is_nan31(exp_rsp_result[30:0]));
    wire add_child_fault = (state_q == ST_ADD_WAIT) && addmul_rsp_valid &&
        (addmul_rsp_flags[4] || addmul_rsp_flags[3] ||
         is_nan31(addmul_rsp_result[30:0]));
    wire div_child_fault = (state_q == ST_DIV_WAIT) && div_rsp_valid &&
        (div_rsp_flags[4] || div_rsp_flags[3] || is_nan31(div_rsp_result[30:0]));
    wire log_child_fault = (state_q == ST_LOG_WAIT) && log_rsp_valid &&
        (log_rsp_error || (log_rsp_error_code != ERR_OK) ||
         log_rsp_flags[4] || log_rsp_flags[3] || is_nan31(log_rsp_result[30:0]));
    wire mul_child_fault = (state_q == ST_MUL_WAIT) && addmul_rsp_valid &&
        (addmul_rsp_flags[4] || addmul_rsp_flags[3] ||
         is_nan31(addmul_rsp_result[30:0]));
    wire child_fault_now =
        exp_child_fault || add_child_fault || div_child_fault ||
        log_child_fault || mul_child_fault;

    wire internal_fault_now =
        !state_valid ||
        (((state_q != ST_ABORT_RESET) && (state_q != ST_HOLD_RESPONSE)) &&
         (ghost_response_now || owner_state_fault));

    wire command_timeout_now =
        (state_q != ST_IDLE) &&
        (state_q != ST_ABORT_RESET) &&
        (state_q != ST_HOLD_RESPONSE) &&
        (watchdog_q >= TIMEOUT_LIMIT);

    // normal credit同拍受所有更高优先级事件gate，防止deadline/fatal边沿误launch/consume。
    wire normal_progress_enable =
        !internal_fault_now && !child_fault_now && !command_timeout_now;

    assign exp_req_valid = (state_q == ST_EXP_REQ) && normal_progress_enable;
    assign exp_rsp_ready = (state_q == ST_EXP_WAIT) && normal_progress_enable;
    assign addmul_req_valid =
        ((state_q == ST_ADD_REQ) || (state_q == ST_MUL_REQ)) &&
        normal_progress_enable;
    assign addmul_rsp_ready =
        ((state_q == ST_ADD_WAIT) || (state_q == ST_MUL_WAIT)) &&
        normal_progress_enable;
    assign div_req_valid = (state_q == ST_DIV_REQ) && normal_progress_enable;
    assign div_rsp_ready = (state_q == ST_DIV_WAIT) && normal_progress_enable;
    assign log_req_valid = (state_q == ST_LOG_REQ) && normal_progress_enable;
    assign log_rsp_ready = (state_q == ST_LOG_WAIT) && normal_progress_enable;

    // IDLE先拒绝ghost response，且response retire同拍保持无request credit。
    assign req_ready_o =
        !rst_i && (state_q == ST_IDLE) && !resident_q && !owner_valid_q &&
        !rsp_valid_q && !any_child_rsp_valid;

    // 阶段3：单一posedge owner。优先级严格为 reset > protocol/child fatal > timeout > progress。
    always @(posedge clk_i) begin
        if (rst_i) begin
            state_q                 <= ST_IDLE;
            resident_q              <= 1'b0;
            owner_valid_q           <= 1'b0;
            owner_q                 <= OWNER_EXP;
            opcode_q                <= 3'b0;
            src0_q                  <= 32'b0;
            src1_q                  <= 32'b0;
            exp_result_q            <= 32'b0;
            add_result_q            <= 32'b0;
            div_result_q            <= 32'b0;
            flags_accum_q           <= 5'b0;
            call_mask_q             <= 5'b0;
            watchdog_q              <= 32'b0;
            active_cycles_q         <= 32'b0;
            pending_error_code_q    <= ERR_OK;
            rsp_valid_q             <= 1'b0;
            response_result_q       <= 32'b0;
            response_flags_q        <= 5'b0;
            response_error_q        <= 1'b0;
            response_error_code_q   <= ERR_OK;
            response_call_mask_q    <= 5'b0;
            response_cycles_q       <= 32'b0;
        end else begin
            if ((state_q != ST_IDLE) && (state_q != ST_HOLD_RESPONSE)) begin
                watchdog_q      <= sat_inc32(watchdog_q);
                active_cycles_q <= sat_inc32(active_cycles_q);
            end

            if (internal_fault_now) begin
                owner_valid_q        <= 1'b0;
                pending_error_code_q <= ERR_PROTOCOL;
                state_q              <= ST_ABORT_RESET;
            end else if (child_fault_now) begin
                owner_valid_q        <= 1'b0;
                pending_error_code_q <= ERR_CHILD;
                state_q              <= ST_ABORT_RESET;
            end else if (command_timeout_now) begin
                owner_valid_q        <= 1'b0;
                pending_error_code_q <= ERR_TIMEOUT;
                state_q              <= ST_ABORT_RESET;
            end else begin
                case (state_q)
                    ST_IDLE: begin
                        if (req_valid_i && req_ready_o) begin
                            resident_q            <= 1'b1;
                            owner_valid_q         <= 1'b0;
                            opcode_q              <= opcode_i;
                            src0_q                <= src0_bits_i;
                            src1_q                <= src1_bits_i;
                            exp_result_q          <= 32'b0;
                            add_result_q          <= 32'b0;
                            div_result_q          <= 32'b0;
                            flags_accum_q         <= 5'b0;
                            call_mask_q           <= 5'b0;
                            watchdog_q            <= 32'd1;
                            active_cycles_q       <= 32'd1;
                            pending_error_code_q  <= ERR_OK;
                            rsp_valid_q           <= 1'b0;
                            response_result_q     <= 32'b0;
                            response_flags_q      <= 5'b0;
                            response_error_q      <= 1'b0;
                            response_error_code_q <= ERR_OK;
                            response_call_mask_q  <= 5'b0;
                            response_cycles_q     <= 32'b0;
                            state_q               <= ST_PREFLIGHT;
                        end
                    end

                    ST_PREFLIGHT: begin
                        if ((opcode_q > OP_EXP) ||
                            (src0_q[30:23] == 8'hff) ||
                            ((opcode_q == OP_SWIGLU) &&
                             (src1_q[30:23] == 8'hff))) begin
                            pending_error_code_q <= ERR_UNSUPPORTED;
                            state_q              <= ST_ABORT_RESET;
                        end else if ((opcode_q == OP_SOFTPLUS) && !src0_q[31] &&
                                     (src0_q > F32_TWENTY)) begin
                            rsp_valid_q            <= 1'b1;
                            response_result_q      <= src0_q;
                            response_flags_q       <= 5'b0;
                            response_error_q       <= 1'b0;
                            response_error_code_q  <= ERR_OK;
                            response_call_mask_q   <= call_mask_q;
                            response_cycles_q      <= sat_inc32(active_cycles_q);
                            state_q                <= ST_HOLD_RESPONSE;
                        end else begin
                            state_q <= ST_EXP_REQ;
                        end
                    end

                    ST_EXP_REQ: begin
                        if (exp_req_valid && exp_req_ready) begin
                            owner_valid_q <= 1'b1;
                            owner_q       <= OWNER_EXP;
                            call_mask_q[0] <= 1'b1;
                            state_q       <= ST_EXP_WAIT;
                        end
                    end

                    ST_EXP_WAIT: begin
                        if (exp_rsp_valid && exp_rsp_ready) begin
                            owner_valid_q <= 1'b0;
                            exp_result_q  <= exp_rsp_result;
                            flags_accum_q <= flags_accum_q | exp_rsp_flags;
                            if (opcode_q == OP_EXP) begin
                                rsp_valid_q            <= 1'b1;
                                response_result_q      <= exp_rsp_result;
                                response_flags_q       <= flags_accum_q
                                                        | exp_rsp_flags;
                                response_error_q       <= 1'b0;
                                response_error_code_q  <= ERR_OK;
                                response_call_mask_q   <= call_mask_q;
                                response_cycles_q      <= sat_inc32(
                                                            active_cycles_q);
                                state_q                <= ST_HOLD_RESPONSE;
                            end else begin
                                state_q <= ST_ADD_REQ;
                            end
                        end
                    end

                    ST_ADD_REQ: begin
                        if (addmul_req_valid && addmul_req_ready) begin
                            owner_valid_q <= 1'b1;
                            owner_q       <= OWNER_ADD;
                            call_mask_q[1] <= 1'b1;
                            state_q       <= ST_ADD_WAIT;
                        end
                    end

                    ST_ADD_WAIT: begin
                        if (addmul_rsp_valid && addmul_rsp_ready) begin
                            owner_valid_q <= 1'b0;
                            add_result_q  <= addmul_rsp_result;
                            flags_accum_q <= flags_accum_q | addmul_rsp_flags;
                            if (opcode_q == OP_SOFTPLUS) begin
                                state_q <= ST_LOG_REQ;
                            end else begin
                                state_q <= ST_DIV_REQ;
                            end
                        end
                    end

                    ST_DIV_REQ: begin
                        if (div_req_valid && div_req_ready) begin
                            owner_valid_q <= 1'b1;
                            owner_q       <= OWNER_DIV;
                            call_mask_q[2] <= 1'b1;
                            state_q       <= ST_DIV_WAIT;
                        end
                    end

                    ST_DIV_WAIT: begin
                        if (div_rsp_valid && div_rsp_ready) begin
                            owner_valid_q <= 1'b0;
                            div_result_q  <= div_rsp_result;
                            flags_accum_q <= flags_accum_q | div_rsp_flags;
                            if (opcode_q == OP_SWIGLU) begin
                                state_q <= ST_MUL_REQ;
                            end else begin
                                rsp_valid_q            <= 1'b1;
                                response_result_q      <= div_rsp_result;
                                response_flags_q       <= flags_accum_q | div_rsp_flags;
                                response_error_q       <= 1'b0;
                                response_error_code_q  <= ERR_OK;
                                response_call_mask_q   <= call_mask_q;
                                response_cycles_q      <= sat_inc32(active_cycles_q);
                                state_q                <= ST_HOLD_RESPONSE;
                            end
                        end
                    end

                    ST_LOG_REQ: begin
                        if (log_req_valid && log_req_ready) begin
                            owner_valid_q <= 1'b1;
                            owner_q       <= OWNER_LOG;
                            call_mask_q[3] <= 1'b1;
                            state_q       <= ST_LOG_WAIT;
                        end
                    end

                    ST_LOG_WAIT: begin
                        if (log_rsp_valid && log_rsp_ready) begin
                            owner_valid_q          <= 1'b0;
                            flags_accum_q          <= flags_accum_q | log_rsp_flags;
                            rsp_valid_q            <= 1'b1;
                            response_result_q      <= log_rsp_result;
                            response_flags_q       <= flags_accum_q | log_rsp_flags;
                            response_error_q       <= 1'b0;
                            response_error_code_q  <= ERR_OK;
                            response_call_mask_q   <= call_mask_q;
                            response_cycles_q      <= sat_inc32(active_cycles_q);
                            state_q                <= ST_HOLD_RESPONSE;
                        end
                    end

                    ST_MUL_REQ: begin
                        if (addmul_req_valid && addmul_req_ready) begin
                            owner_valid_q <= 1'b1;
                            owner_q       <= OWNER_MUL;
                            call_mask_q[4] <= 1'b1;
                            state_q       <= ST_MUL_WAIT;
                        end
                    end

                    ST_MUL_WAIT: begin
                        if (addmul_rsp_valid && addmul_rsp_ready) begin
                            owner_valid_q          <= 1'b0;
                            flags_accum_q          <= flags_accum_q | addmul_rsp_flags;
                            rsp_valid_q            <= 1'b1;
                            response_result_q      <= addmul_rsp_result;
                            response_flags_q       <= flags_accum_q | addmul_rsp_flags;
                            response_error_q       <= 1'b0;
                            response_error_code_q  <= ERR_OK;
                            response_call_mask_q   <= call_mask_q;
                            response_cycles_q      <= sat_inc32(active_cycles_q);
                            state_q                <= ST_HOLD_RESPONSE;
                        end
                    end

                    ST_ABORT_RESET: begin
                        owner_valid_q <= 1'b0;
                        if (resident_q) begin
                            rsp_valid_q            <= 1'b1;
                            response_result_q      <= 32'b0;
                            response_flags_q       <= 5'b0;
                            response_error_q       <= 1'b1;
                            response_error_code_q  <= pending_error_code_q;
                            response_call_mask_q   <= call_mask_q;
                            response_cycles_q      <= sat_inc32(active_cycles_q);
                            state_q                <= ST_HOLD_RESPONSE;
                        end else begin
                            // 无 resident ghost只清洗child；禁止制造unmatched response。
                            rsp_valid_q           <= 1'b0;
                            flags_accum_q         <= 5'b0;
                            call_mask_q           <= 5'b0;
                            watchdog_q            <= 32'b0;
                            active_cycles_q       <= 32'b0;
                            pending_error_code_q <= ERR_OK;
                            state_q               <= ST_IDLE;
                        end
                    end

                    ST_HOLD_RESPONSE: begin
                        if (rsp_valid_q && rsp_ready_i) begin
                            rsp_valid_q         <= 1'b0;
                            resident_q          <= 1'b0;
                            owner_valid_q       <= 1'b0;
                            flags_accum_q       <= 5'b0;
                            call_mask_q         <= 5'b0;
                            watchdog_q          <= 32'b0;
                            active_cycles_q     <= 32'b0;
                            pending_error_code_q <= ERR_OK;
                            state_q             <= ST_IDLE;
                        end
                    end

                    default: begin
                        owner_valid_q        <= 1'b0;
                        pending_error_code_q <= ERR_PROTOCOL;
                        state_q              <= ST_ABORT_RESET;
                    end
                endcase
            end
        end
    end

endmodule
