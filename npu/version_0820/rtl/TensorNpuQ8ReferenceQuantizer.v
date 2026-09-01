`timescale 1ns/1ps
`default_nettype none

// SPDX-License-Identifier: MIT
//
// b10507 reference F32 -> Q8_0 单 block 量化器。
//
// 命令协议：
//   * IDLE 中 start_i && ready_o 接受一条命令；busy 期间 start_i 被忽略；
//   * LOAD32 以 valid/ready 恰好接收 32 个 finite binary32 raw word；
//   * DONE/ERROR 各保持一拍，block_o 只在最终成功时原子发布；
//   * reset 具有最高优先级，并同时取消两个子运算器中的 resident transaction。
//
// 数值顺序：
//   amax = max(abs(x[i]))；d = RN32(amax / 127)；
//   stored_d = FP32_TO_FP16_RNE(d)；id = d != 0 ? RN32(1 / d) : +0；
//   q[i] = RMM_signed(RN32(x[i] * id))。
//
// 数据通路拓扑：32x32-bit word bank + raw magnitude comparator；一个共享
// TensorNpuFp32Div 顺序执行 d/id；一个共享 TensorNpuFp32AddMul 只执行
// 非融合 fmul；组合 FP16 pack 与组合 RMM converter。word_bank 的动态索引
// 综合为 32:1 operand mux。最长算术路径保留在既有 fp_fdiv/fp_fma 子模块内。
module TensorNpuQ8ReferenceQuantizer #(
    parameter [6:0]  DIV_TIMEOUT_CYCLES     = 7'd48,
    parameter [4:0]  MUL_TIMEOUT_CYCLES     = 5'd16,
    parameter [15:0] COMMAND_TIMEOUT_CYCLES = 16'd512
) (
    input  wire         clk_i,
    input  wire         rst_i,

    input  wire         start_i,
    output wire         ready_o,
    output wire         busy_o,

    input  wire         input_valid_i,
    output wire         input_ready_o,
    input  wire [31:0]  input_bits_i,

    output wire         done_o,
    output wire         error_o,
    output wire [3:0]   error_code_o,
    output wire [271:0] block_o,
    output wire [15:0]  active_cycles_o
);

    localparam [3:0] ERROR_NONE          = 4'h0;
    localparam [3:0] ERROR_INPUT_NONFINITE = 4'h1;
    localparam [3:0] ERROR_SCALE_PACK    = 4'h2;
    localparam [3:0] ERROR_DIV_NUMERIC   = 4'h3;
    localparam [3:0] ERROR_DIV_TIMEOUT   = 4'h4;
    localparam [3:0] ERROR_MUL_NUMERIC   = 4'h5;
    localparam [3:0] ERROR_MUL_TIMEOUT   = 4'h6;
    localparam [3:0] ERROR_RMM           = 4'h7;
    localparam [3:0] ERROR_COMMAND_TIMEOUT = 4'h8;
    localparam [3:0] ERROR_INTERNAL_STATE  = 4'hf;

    localparam [3:0] STATE_IDLE        = 4'd0;
    localparam [3:0] STATE_LOAD32      = 4'd1;
    localparam [3:0] STATE_D_DIV_REQ   = 4'd2;
    localparam [3:0] STATE_D_DIV_WAIT  = 4'd3;
    localparam [3:0] STATE_D_PACK      = 4'd4;
    localparam [3:0] STATE_ID_DIV_REQ  = 4'd5;
    localparam [3:0] STATE_ID_DIV_WAIT = 4'd6;
    localparam [3:0] STATE_MUL_REQ     = 4'd7;
    localparam [3:0] STATE_MUL_WAIT    = 4'd8;
    localparam [3:0] STATE_RMM_STORE   = 4'd9;
    localparam [3:0] STATE_DONE        = 4'd10;
    localparam [3:0] STATE_ERROR       = 4'd11;

    reg [3:0] state_q;
    reg [5:0] load_count_q;
    reg [5:0] mul_index_q;

    reg [31:0] word_bank_q [0:31];
    reg [31:0] amax_bits_q;
    reg [31:0] d_bits_q;
    reg [31:0] id_bits_q;
    reg [31:0] scaled_bits_q;

    // scale + q[0:30]；q[31] 在成功边沿直接拼到 block_q[271:264]。
    reg [263:0] work_block_q;
    reg [271:0] block_q;
    reg [3:0]   error_code_q;
    reg [15:0]  command_cycles_q;
    reg [15:0]  active_cycles_q;
    reg [6:0]   div_wait_cycles_q;
    reg [4:0]   mul_wait_cycles_q;

    integer reset_index;

    wire start_fire_w;
    wire input_fire_w;
    wire input_finite_w;
    wire [31:0] input_abs_bits_w;
    wire [31:0] amax_candidate_w;
    wire        child_rst_w;

    wire        div_req_valid_w;
    wire        div_req_ready_w;
    wire [31:0] div_lhs_bits_w;
    wire [31:0] div_rhs_bits_w;
    wire        div_rsp_valid_w;
    wire        div_rsp_ready_w;
    wire [31:0] div_result_bits_w;
    wire [4:0]  div_flags_w;
    wire        div_result_finite_w;
    wire        div_fatal_flags_w;

    wire [15:0] packed_scale_bits_w;
    wire        packed_scale_finite_w;
    wire        packed_scale_overflow_w;

    wire        mul_req_valid_w;
    wire        mul_req_ready_w;
    wire        mul_rsp_valid_w;
    wire        mul_rsp_ready_w;
    wire [31:0] mul_result_bits_w;
    wire [4:0]  mul_flags_w;
    wire        mul_result_finite_w;
    wire        mul_fatal_flags_w;

    wire [31:0] rmm_int32_bits_w;
    wire [4:0]  rmm_flags_w;
    wire        rmm_q8_range_w;
    wire        rmm_sign_extension_w;
    wire        rmm_fatal_flags_w;

    assign ready_o         = !rst_i && (state_q == STATE_IDLE);
    assign busy_o          = !rst_i && (state_q != STATE_IDLE);
    assign input_ready_o   = !rst_i && (state_q == STATE_LOAD32);
    assign done_o          = !rst_i && (state_q == STATE_DONE);
    assign error_o         = !rst_i && (state_q == STATE_ERROR);
    assign error_code_o    = error_code_q;
    assign block_o         = block_q;
    assign active_cycles_o = active_cycles_q;

    assign start_fire_w      = start_i && ready_o;
    assign input_fire_w      = input_valid_i && input_ready_o;
    assign input_finite_w    = (input_bits_i[30:23] != 8'hff);
    assign input_abs_bits_w  = {1'b0, input_bits_i[30:0]};
    assign amax_candidate_w  = (input_abs_bits_w > amax_bits_q)
                             ? input_abs_bits_w : amax_bits_q;
    // ERROR 一拍同时充当 child transaction cancel window；在 ERROR->IDLE
    // 边沿两个 wrapper 看到 reset，从而不会把 timeout 后的 stale response
    // 带入下一条命令。
    assign child_rst_w = rst_i || (state_q == STATE_ERROR);

    // 一个共享 divider 的 lhs/rhs mux 与 request enable 均由 FSM 显式控制。
    assign div_req_valid_w = (state_q == STATE_D_DIV_REQ)
                           || (state_q == STATE_ID_DIV_REQ);
    assign div_lhs_bits_w  = (state_q == STATE_D_DIV_REQ)
                           ? amax_bits_q : 32'h3f800000;
    assign div_rhs_bits_w  = (state_q == STATE_D_DIV_REQ)
                           ? 32'h42fe0000 : d_bits_q;
    assign div_rsp_ready_w = (state_q == STATE_D_DIV_WAIT)
                           || (state_q == STATE_ID_DIV_WAIT);
    assign div_result_finite_w = (div_result_bits_w[30:23] != 8'hff);
    // flags[1:0]=UF/NX 可以是合法 reference 舍入；任一高三位使
    // 5-bit unsigned flags 数值至少为 4。
    assign div_fatal_flags_w = (div_flags_w >= 5'd4);

    TensorNpuFp32Div u_div (
        .clk_i         (clk_i),
        .rst_i         (child_rst_w),
        .req_valid_i   (div_req_valid_w),
        .req_ready_o   (div_req_ready_w),
        .lhs_bits_i    (div_lhs_bits_w),
        .rhs_bits_i    (div_rhs_bits_w),
        .rsp_valid_o   (div_rsp_valid_w),
        .rsp_ready_i   (div_rsp_ready_w),
        .result_bits_o (div_result_bits_w),
        .flags_o       (div_flags_w)
    );

    // inexact 是允许的 RNE 舍入状态；本层只需 finite/overflow。
    /* verilator lint_off PINCONNECTEMPTY */
    TensorNpuFp32ToFp16 u_scale_pack (
        .fp32_bits_i (d_bits_q),
        .fp16_bits_o (packed_scale_bits_w),
        .finite_o    (packed_scale_finite_w),
        .overflow_o  (packed_scale_overflow_w),
        .inexact_o   ()
    );
    /* verilator lint_on PINCONNECTEMPTY */

    // 一个共享 multiplier 的 32:1 lhs mux；op_mul_i 固定为 1，禁止 FMA。
    assign mul_req_valid_w = (state_q == STATE_MUL_REQ);
    assign mul_rsp_ready_w = (state_q == STATE_MUL_WAIT);
    assign mul_result_finite_w = (mul_result_bits_w[30:23] != 8'hff);
    assign mul_fatal_flags_w = (mul_flags_w >= 5'd4);

    TensorNpuFp32AddMul u_mul (
        .clk_i         (clk_i),
        .rst_i         (child_rst_w),
        .req_valid_i   (mul_req_valid_w),
        .req_ready_o   (mul_req_ready_w),
        .op_mul_i      (1'b1),
        .lhs_bits_i    (word_bank_q[mul_index_q[4:0]]),
        .rhs_bits_i    (id_bits_q),
        .rsp_valid_o   (mul_rsp_valid_w),
        .rsp_ready_i   (mul_rsp_ready_w),
        .result_bits_o (mul_result_bits_w),
        .flags_o       (mul_flags_w)
    );

    TensorNpuFp32ToInt32Rmm u_rmm (
        .fp32_bits_i (scaled_bits_q),
        .int32_bits_o(rmm_int32_bits_w),
        .flags_o     (rmm_flags_w),
        .q8_range_o  (rmm_q8_range_w)
    );

    assign rmm_sign_extension_w = (rmm_int32_bits_w[31:8] == 24'h000000)
                                || (rmm_int32_bits_w[31:8] == 24'hffffff);
    // f2i 的合法非致命状态只有 exact(0) 或 NX(1)；NV 及任何异常高位
    // 均使 5-bit unsigned flags 至少为 2。
    assign rmm_fatal_flags_w = (rmm_flags_w >= 5'd2);

    // reset > 512-cycle command timeout > 当前 FSM 事件。
    always @(posedge clk_i) begin
        if (rst_i) begin
            state_q             <= STATE_IDLE;
            load_count_q        <= 6'b0;
            mul_index_q         <= 6'b0;
            amax_bits_q         <= 32'b0;
            d_bits_q            <= 32'b0;
            id_bits_q           <= 32'b0;
            scaled_bits_q       <= 32'b0;
            work_block_q        <= 264'b0;
            block_q             <= 272'b0;
            error_code_q        <= ERROR_NONE;
            command_cycles_q    <= 16'b0;
            active_cycles_q     <= 16'b0;
            div_wait_cycles_q   <= 7'b0;
            mul_wait_cycles_q   <= 5'b0;
            // 该循环综合为 32 组带同步清零的 32-bit 输入寄存器。
            for (reset_index = 0; reset_index < 32;
                 reset_index = reset_index + 1) begin
                word_bank_q[reset_index] <= 32'b0;
            end
        end else begin
            case (state_q)
                STATE_IDLE: begin
                    if (start_fire_w) begin
                        state_q           <= STATE_LOAD32;
                        load_count_q      <= 6'b0;
                        mul_index_q       <= 6'b0;
                        amax_bits_q       <= 32'b0;
                        d_bits_q          <= 32'b0;
                        id_bits_q         <= 32'b0;
                        scaled_bits_q     <= 32'b0;
                        work_block_q      <= 264'b0;
                        block_q           <= 272'b0;
                        error_code_q      <= ERROR_NONE;
                        command_cycles_q  <= 16'd1;
                        active_cycles_q   <= 16'b0;
                        div_wait_cycles_q <= 7'b0;
                        mul_wait_cycles_q <= 5'b0;
                        // 新命令清除旧输入，错误路径不会观察到上条命令数据。
                        for (reset_index = 0; reset_index < 32;
                             reset_index = reset_index + 1) begin
                            word_bank_q[reset_index] <= 32'b0;
                        end
                    end
                end

                STATE_DONE: begin
                    state_q <= STATE_IDLE;
                end

                STATE_ERROR: begin
                    state_q <= STATE_IDLE;
                end

                default: begin
                    // active_cycles 定义为 start 接受边沿到 DONE/ERROR 发布边沿，
                    // 两端均计数。第 512 个 active edge 尚未完成则 fail-closed。
                    if ((command_cycles_q + 16'd1)
                        >= COMMAND_TIMEOUT_CYCLES) begin
                        state_q          <= STATE_ERROR;
                        error_code_q     <= ERROR_COMMAND_TIMEOUT;
                        block_q          <= 272'b0;
                        active_cycles_q  <= command_cycles_q + 16'd1;
                        command_cycles_q <= command_cycles_q + 16'd1;
                    end else begin
                        command_cycles_q <= command_cycles_q + 16'd1;

                        case (state_q)
                            STATE_LOAD32: begin
                                if (input_fire_w) begin
                                    if (!input_finite_w) begin
                                        state_q         <= STATE_ERROR;
                                        error_code_q    <= ERROR_INPUT_NONFINITE;
                                        block_q         <= 272'b0;
                                        active_cycles_q <= command_cycles_q + 16'd1;
                                    end else begin
                                        word_bank_q[load_count_q[4:0]] <= input_bits_i;
                                        amax_bits_q <= amax_candidate_w;
                                        if (load_count_q == 6'd31) begin
                                            load_count_q <= 6'd32;
                                            state_q      <= STATE_D_DIV_REQ;
                                        end else begin
                                            load_count_q <= load_count_q + 6'd1;
                                        end
                                    end
                                end
                            end

                            STATE_D_DIV_REQ: begin
                                if (div_req_ready_w) begin
                                    div_wait_cycles_q <= 7'b0;
                                    state_q           <= STATE_D_DIV_WAIT;
                                end
                            end

                            STATE_D_DIV_WAIT: begin
                                if (div_rsp_valid_w) begin
                                    if (div_fatal_flags_w
                                            || !div_result_finite_w) begin
                                        state_q         <= STATE_ERROR;
                                        error_code_q    <= ERROR_DIV_NUMERIC;
                                        block_q         <= 272'b0;
                                        active_cycles_q <= command_cycles_q + 16'd1;
                                    end else begin
                                        d_bits_q <= div_result_bits_w;
                                        state_q  <= STATE_D_PACK;
                                    end
                                end else if ((div_wait_cycles_q + 7'd1)
                                             >= DIV_TIMEOUT_CYCLES) begin
                                    state_q         <= STATE_ERROR;
                                    error_code_q    <= ERROR_DIV_TIMEOUT;
                                    block_q         <= 272'b0;
                                    active_cycles_q <= command_cycles_q + 16'd1;
                                end else begin
                                    div_wait_cycles_q <= div_wait_cycles_q + 7'd1;
                                end
                            end

                            STATE_D_PACK: begin
                                if (!packed_scale_finite_w
                                    || packed_scale_overflow_w) begin
                                    state_q         <= STATE_ERROR;
                                    error_code_q    <= ERROR_SCALE_PACK;
                                    block_q         <= 272'b0;
                                    active_cycles_q <= command_cycles_q + 16'd1;
                                end else begin
                                    // bits[7:0] 是 byte0，故直接写 half raw bits
                                    // 即得到 little-endian scale bytes。
                                    work_block_q[15:0] <= packed_scale_bits_w;
                                    mul_index_q         <= 6'b0;
                                    if (d_bits_q[30:0] == 31'b0) begin
                                        id_bits_q <= 32'h00000000;
                                        state_q   <= STATE_MUL_REQ;
                                    end else begin
                                        state_q <= STATE_ID_DIV_REQ;
                                    end
                                end
                            end

                            STATE_ID_DIV_REQ: begin
                                if (div_req_ready_w) begin
                                    div_wait_cycles_q <= 7'b0;
                                    state_q           <= STATE_ID_DIV_WAIT;
                                end
                            end

                            STATE_ID_DIV_WAIT: begin
                                if (div_rsp_valid_w) begin
                                    if (div_fatal_flags_w
                                        || !div_result_finite_w) begin
                                        state_q         <= STATE_ERROR;
                                        error_code_q    <= ERROR_DIV_NUMERIC;
                                        block_q         <= 272'b0;
                                        active_cycles_q <= command_cycles_q + 16'd1;
                                    end else begin
                                        id_bits_q <= div_result_bits_w;
                                        state_q   <= STATE_MUL_REQ;
                                    end
                                end else if ((div_wait_cycles_q + 7'd1)
                                             >= DIV_TIMEOUT_CYCLES) begin
                                    state_q         <= STATE_ERROR;
                                    error_code_q    <= ERROR_DIV_TIMEOUT;
                                    block_q         <= 272'b0;
                                    active_cycles_q <= command_cycles_q + 16'd1;
                                end else begin
                                    div_wait_cycles_q <= div_wait_cycles_q + 7'd1;
                                end
                            end

                            STATE_MUL_REQ: begin
                                if (mul_req_ready_w) begin
                                    mul_wait_cycles_q <= 5'b0;
                                    state_q           <= STATE_MUL_WAIT;
                                end
                            end

                            STATE_MUL_WAIT: begin
                                if (mul_rsp_valid_w) begin
                                    if (mul_fatal_flags_w
                                        || !mul_result_finite_w) begin
                                        state_q         <= STATE_ERROR;
                                        error_code_q    <= ERROR_MUL_NUMERIC;
                                        block_q         <= 272'b0;
                                        active_cycles_q <= command_cycles_q + 16'd1;
                                    end else begin
                                        scaled_bits_q <= mul_result_bits_w;
                                        state_q       <= STATE_RMM_STORE;
                                    end
                                end else if ((mul_wait_cycles_q + 5'd1)
                                             >= MUL_TIMEOUT_CYCLES) begin
                                    state_q         <= STATE_ERROR;
                                    error_code_q    <= ERROR_MUL_TIMEOUT;
                                    block_q         <= 272'b0;
                                    active_cycles_q <= command_cycles_q + 16'd1;
                                end else begin
                                    mul_wait_cycles_q <= mul_wait_cycles_q + 5'd1;
                                end
                            end

                            STATE_RMM_STORE: begin
                                if (rmm_fatal_flags_w || !rmm_q8_range_w
                                    || !rmm_sign_extension_w) begin
                                    state_q         <= STATE_ERROR;
                                    error_code_q    <= ERROR_RMM;
                                    block_q         <= 272'b0;
                                    active_cycles_q <= command_cycles_q + 16'd1;
                                end else begin
                                    if (mul_index_q == 6'd31) begin
                                        // 最后一个 q byte 与此前 264 bits 同拍原子发布。
                                        block_q <= {rmm_int32_bits_w[7:0],
                                                    work_block_q[263:0]};
                                        error_code_q    <= ERROR_NONE;
                                        active_cycles_q <= command_cycles_q + 16'd1;
                                        state_q         <= STATE_DONE;
                                    end else begin
                                        // 该 indexed part-select 是 q[0:30]
                                        // 的单 byte write-enable mux。
                                        work_block_q[16 + (mul_index_q * 8) +: 8]
                                            <= rmm_int32_bits_w[7:0];
                                        mul_index_q <= mul_index_q + 6'd1;
                                        state_q     <= STATE_MUL_REQ;
                                    end
                                end
                            end

                            default: begin
                                state_q         <= STATE_ERROR;
                                error_code_q    <= ERROR_INTERNAL_STATE;
                                block_q         <= 272'b0;
                                active_cycles_q <= command_cycles_q + 16'd1;
                            end
                        endcase
                    end
                end
            endcase
        end
    end

endmodule

`default_nettype wire
