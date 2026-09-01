`timescale 1ns/1ps

// SPDX-License-Identifier: BSD-3-Clause
//
// 单行 RMS/L2 norm engine，逐拍复用项目中已经冻结的 IEEE raw-bit primitive。
//
// 事务边界：
//   * start 只在 IDLE/ready 握手；非法 mode/D/epsilon 在任何 lane credit 前失败；
//   * ordered square/F64 serial sum 的 committed replay 是唯一输入二次读取源；
//   * epsilon add 与 replay multiply 共享一个 FP32 add/mul wrapper，REQ 态的
//     mux/payload 在 ready 前保持，WAIT 态独占对应 response credit；
//   * 所有 D 个 replay multiply 先写入父级私有 output_buffer_q，COMMIT 之后
//     才开放 output stream，因此任何可能 ERROR 都先于首个 output handshake；
//   * UF/NX sticky 继续，NV/DZ/OF、child error、nonfinite 或 denominator=0
//     令整行 fail-closed，并同步 reset resident child transaction。
module TensorNpuNormEngine #(
    parameter integer MAX_D = 1024,
    parameter [31:0] STALL_TIMEOUT_CYCLES = 32'd256,
    parameter [31:0] COMMAND_TIMEOUT_CYCLES = 32'd262144
) (
    input  wire                                      clk_i,
    input  wire                                      rst_i,

    input  wire                                      start_i,
    output wire                                      ready_o,
    output wire                                      busy_o,
    input  wire [1:0]                                mode_i,
    input  wire [$clog2(MAX_D + 1)-1:0]             element_count_i,
    input  wire [31:0]                               eps_bits_i,

    input  wire                                      lane_valid_i,
    output wire                                      lane_ready_o,
    input  wire [31:0]                               lane_bits_i,

    output wire                                      out_valid_o,
    input  wire                                      out_ready_i,
    output reg  [31:0]                               out_bits_o,
    output wire [$clog2(MAX_D + 1)-1:0]             out_index_o,
    output wire                                      out_last_o,

    output wire                                      done_o,
    output wire                                      error_o,
    output wire [4:0]                                error_code_o,
    output wire [4:0]                                flags_o,
    output wire [$clog2(MAX_D + 1)-1:0]             elements_accepted_o,
    output wire [$clog2(MAX_D + 1)-1:0]             elements_emitted_o,
    output wire [31:0]                               active_cycles_o
);

    localparam integer COUNT_WIDTH = $clog2(MAX_D + 1);
    localparam integer INDEX_WIDTH = (MAX_D <= 1) ? 1 : $clog2(MAX_D);

    localparam [1:0] MODE_RMS = 2'd0;
    localparam [1:0] MODE_L2  = 2'd1;

    localparam [4:0] ST_IDLE         = 5'd0;
    localparam [4:0] ST_SUM_START    = 5'd1;
    localparam [4:0] ST_SUM_RUN      = 5'd2;
    localparam [4:0] ST_SCALE_REQ    = 5'd3;
    localparam [4:0] ST_SCALE_WAIT   = 5'd4;
    localparam [4:0] ST_CONVERT_REQ  = 5'd5;
    localparam [4:0] ST_CONVERT_WAIT = 5'd6;
    localparam [4:0] ST_EPS_REQ      = 5'd7;
    localparam [4:0] ST_EPS_WAIT     = 5'd8;
    localparam [4:0] ST_SQRT_REQ     = 5'd9;
    localparam [4:0] ST_SQRT_WAIT    = 5'd10;
    localparam [4:0] ST_L2_MAX       = 5'd11;
    localparam [4:0] ST_RECIP_REQ    = 5'd12;
    localparam [4:0] ST_RECIP_WAIT   = 5'd13;
    localparam [4:0] ST_REPLAY_LOAD  = 5'd14;
    localparam [4:0] ST_MUL_REQ      = 5'd15;
    localparam [4:0] ST_MUL_WAIT     = 5'd16;
    localparam [4:0] ST_COMMIT       = 5'd17;
    localparam [4:0] ST_OUTPUT       = 5'd18;
    localparam [4:0] ST_DONE         = 5'd19;
    localparam [4:0] ST_ERROR        = 5'd20;

    // error_code_o 固定保留父状态机观测到的第一个 fatal 分类。
    localparam [4:0] ERR_NONE             = 5'd0;
    localparam [4:0] ERR_HEADER_MODE      = 5'd1;
    localparam [4:0] ERR_HEADER_D         = 5'd2;
    localparam [4:0] ERR_HEADER_EPS       = 5'd3;
    localparam [4:0] ERR_SUM_CHILD        = 5'd4;
    localparam [4:0] ERR_SCALE_CHILD      = 5'd5;
    localparam [4:0] ERR_CONVERT_CHILD    = 5'd6;
    localparam [4:0] ERR_CONVERT_FATAL    = 5'd7;
    localparam [4:0] ERR_EPS_ADD_FATAL    = 5'd8;
    localparam [4:0] ERR_SQRT_FATAL       = 5'd9;
    localparam [4:0] ERR_DEN_ZERO         = 5'd10;
    localparam [4:0] ERR_RECIP_FATAL      = 5'd11;
    localparam [4:0] ERR_REPLAY_SOURCE    = 5'd12;
    localparam [4:0] ERR_REPLAY_MUL_FATAL = 5'd13;
    localparam [4:0] ERR_STALL_TIMEOUT    = 5'd14;
    localparam [4:0] ERR_COMMAND_TIMEOUT  = 5'd15;
    localparam [4:0] ERR_ILLEGAL_STATE    = 5'd16;

    localparam [COUNT_WIDTH-1:0] MAX_D_COUNT = MAX_D[COUNT_WIDTH-1:0];
    localparam [COUNT_WIDTH-1:0] D128_COUNT  = 128;
    localparam [COUNT_WIDTH-1:0] D256_COUNT  = 256;
    localparam [COUNT_WIDTH-1:0] D1024_COUNT = 1024;
    localparam [COUNT_WIDTH-1:0] COUNT_ONE   = {{(COUNT_WIDTH-1){1'b0}}, 1'b1};

    reg [4:0] state_q;
    reg [1:0] mode_q;
    reg [COUNT_WIDTH-1:0] element_count_q;
    reg [31:0] eps_bits_q;

    reg [63:0] f64_value_q;
    reg [31:0] narrow_bits_q;
    reg [31:0] sqrt_operand_q;
    reg [31:0] root_bits_q;
    reg [31:0] denominator_bits_q;
    reg [31:0] reciprocal_bits_q;
    reg [31:0] replay_operand_q;

    reg [COUNT_WIDTH-1:0] replay_index_q;
    reg [COUNT_WIDTH-1:0] out_index_q;
    reg [COUNT_WIDTH-1:0] elements_accepted_q;
    reg [COUNT_WIDTH-1:0] elements_emitted_q;
    reg [31:0] active_cycles_q;
    reg [31:0] stall_cycles_q;
    reg [31:0] command_cycles_q;
    reg [4:0] flags_accum_q;
    reg [4:0] flags_q;
    reg [4:0] error_code_q;

    // 综合含义是一份 MAX_D x 32 单写/组合读私有 row output buffer；本任务
    // 只做 Verilator 功能仿真，不据此外推 RAM mapping、STA 或 PPA。
    reg [31:0] output_buffer_q [0:MAX_D-1];

    wire state_valid_w =
        (state_q == ST_IDLE)         || (state_q == ST_SUM_START)    ||
        (state_q == ST_SUM_RUN)      || (state_q == ST_SCALE_REQ)   ||
        (state_q == ST_SCALE_WAIT)   || (state_q == ST_CONVERT_REQ) ||
        (state_q == ST_CONVERT_WAIT) || (state_q == ST_EPS_REQ)     ||
        (state_q == ST_EPS_WAIT)     || (state_q == ST_SQRT_REQ)    ||
        (state_q == ST_SQRT_WAIT)    || (state_q == ST_L2_MAX)      ||
        (state_q == ST_RECIP_REQ)    || (state_q == ST_RECIP_WAIT)  ||
        (state_q == ST_REPLAY_LOAD)  || (state_q == ST_MUL_REQ)     ||
        (state_q == ST_MUL_WAIT)     || (state_q == ST_COMMIT)      ||
        (state_q == ST_OUTPUT)       || (state_q == ST_DONE)        ||
        (state_q == ST_ERROR);

    // Watchdogs只覆盖首个output beat之前的可失败阶段。COMMIT之后所有数值
    // child均已闭合；output backpressure可无限保持，不能在部分stream后报错。
    wire precommit_processing_w =
        (state_q == ST_SUM_START)    || (state_q == ST_SUM_RUN)      ||
        (state_q == ST_SCALE_REQ)    || (state_q == ST_SCALE_WAIT)   ||
        (state_q == ST_CONVERT_REQ)  || (state_q == ST_CONVERT_WAIT) ||
        (state_q == ST_EPS_REQ)      || (state_q == ST_EPS_WAIT)     ||
        (state_q == ST_SQRT_REQ)     || (state_q == ST_SQRT_WAIT)    ||
        (state_q == ST_L2_MAX)       || (state_q == ST_RECIP_REQ)    ||
        (state_q == ST_RECIP_WAIT)   || (state_q == ST_REPLAY_LOAD)  ||
        (state_q == ST_MUL_REQ)      || (state_q == ST_MUL_WAIT);
    wire active_w =
        (state_q != ST_IDLE) && (state_q != ST_DONE) && (state_q != ST_ERROR);

    assign ready_o = !rst_i && (state_q == ST_IDLE);
    assign busy_o  = !rst_i && (state_q != ST_IDLE);
    assign done_o  = !rst_i && ((state_q == ST_DONE) || (state_q == ST_ERROR));
    assign error_o = !rst_i && (state_q == ST_ERROR);
    assign error_code_o = (state_q == ST_ERROR) ? error_code_q : ERR_NONE;
    assign flags_o = flags_q;
    assign elements_accepted_o = elements_accepted_q;
    assign elements_emitted_o  = elements_emitted_q;
    assign active_cycles_o     = active_cycles_q;

    wire start_fire_w = start_i && ready_o;

    wire header_mode_valid_w = (mode_i == MODE_RMS) || (mode_i == MODE_L2);
    wire header_eps_valid_w =
        !eps_bits_i[31] && (eps_bits_i[30:23] != 8'hff);
    wire header_d_valid_w =
        ((mode_i == MODE_RMS) &&
         (((MAX_D >= 128)  && (element_count_i == D128_COUNT))  ||
          ((MAX_D >= 256)  && (element_count_i == D256_COUNT))  ||
          ((MAX_D >= 1024) && (element_count_i == D1024_COUNT)))) ||
        ((mode_i == MODE_L2) &&
         (MAX_D >= 128) && (element_count_i == D128_COUNT));

    assign out_valid_o = !rst_i && (state_q == ST_OUTPUT);
    assign out_index_o = out_index_q;
    assign out_last_o =
        out_valid_o && (out_index_q == (element_count_q - COUNT_ONE));
    wire out_fire_w = out_valid_o && out_ready_i;

    // out_index_q只在ST_OUTPUT且真实handshake后推进；buffer在COMMIT前已冻结，
    // 因此out_valid&&!out_ready期间bits/index/last均结构性稳定。
    always @(*) begin
        out_bits_o = 32'b0;
        if (out_valid_o && (out_index_q < element_count_q) &&
            (out_index_q < MAX_D_COUNT)) begin
            out_bits_o = output_buffer_q[out_index_q[INDEX_WIDTH-1:0]];
        end
    end

    // ERROR或非法父状态同步reset每个resident child，阻止stale response跨epoch。
    wire child_rst_w = rst_i || (state_q == ST_ERROR) || !state_valid_w;

    // ---------------------------------------------------------------------
    // Ordered FP32-square / exact-widen / serial-F64-sum child
    // ---------------------------------------------------------------------
    wire sum_start_ready_w;
    wire sum_busy_w;
    wire sum_lane_ready_w;
    wire sum_done_w;
    wire sum_error_w;
    wire [3:0] sum_error_code_w;
    wire [63:0] sum_bits_w;
    wire [4:0] sum_flags_w;
    wire sum_committed_valid_w;
    wire [COUNT_WIDTH-1:0] sum_committed_count_w;
    wire sum_replay_valid_w;
    wire [31:0] sum_replay_bits_w;
    wire [COUNT_WIDTH-1:0] sum_elements_accepted_w;
    wire [31:0] sum_active_cycles_w;

    wire sum_start_valid_w = !child_rst_w && (state_q == ST_SUM_START);
    wire sum_start_fire_w = sum_start_valid_w && sum_start_ready_w;
    wire sum_lane_valid_w =
        !child_rst_w && (state_q == ST_SUM_RUN) && lane_valid_i;
    assign lane_ready_o =
        !child_rst_w && (state_q == ST_SUM_RUN) && sum_lane_ready_w;
    wire lane_fire_w = lane_valid_i && lane_ready_o;

    TensorNpuFp32SquareSum64 #(
        .MAX_D                  (MAX_D),
        .STALL_TIMEOUT_CYCLES   (STALL_TIMEOUT_CYCLES),
        .COMMAND_TIMEOUT_CYCLES (COMMAND_TIMEOUT_CYCLES)
    ) u_sum (
        .clk_i                 (clk_i),
        .rst_i                 (child_rst_w),
        .start_i               (sum_start_valid_w),
        .ready_o               (sum_start_ready_w),
        .busy_o                (sum_busy_w),
        .element_count_i       (element_count_q),
        .lane_valid_i          (sum_lane_valid_w),
        .lane_ready_o          (sum_lane_ready_w),
        .lane_bits_i           (lane_bits_i),
        .done_o                (sum_done_w),
        .error_o               (sum_error_w),
        .error_code_o          (sum_error_code_w),
        .sum_bits_o            (sum_bits_w),
        .flags_o               (sum_flags_w),
        .committed_row_valid_o (sum_committed_valid_w),
        .committed_count_o     (sum_committed_count_w),
        .replay_index_i        (replay_index_q),
        .replay_valid_o        (sum_replay_valid_w),
        .replay_bits_o         (sum_replay_bits_w),
        .elements_accepted_o   (sum_elements_accepted_w),
        .active_cycles_o       (sum_active_cycles_w)
    );

    wire sum_terminal_w = (state_q == ST_SUM_RUN) && sum_done_w;
    wire sum_protocol_bad_w =
        sum_terminal_w && !sum_error_w &&
        (!sum_committed_valid_w ||
         (sum_committed_count_w != element_count_q) ||
         (sum_elements_accepted_w != element_count_q) ||
         !sum_busy_w || (sum_active_cycles_w == 32'b0));
    wire sum_value_bad_w =
        sum_terminal_w && !sum_error_w &&
        (sum_bits_w[63] || (sum_bits_w[62:52] == 11'h7ff) ||
         sum_flags_w[4] || sum_flags_w[3] || sum_flags_w[2]);
    wire sum_fatal_w =
        sum_terminal_w &&
        (sum_error_w || (sum_error_code_w != 4'b0) ||
         sum_protocol_bad_w || sum_value_bad_w);

    // ---------------------------------------------------------------------
    // RMS exact binary64 division by D=2^k
    // ---------------------------------------------------------------------
    wire scale_req_ready_w;
    wire scale_rsp_valid_w;
    wire [63:0] scale_result_w;
    wire [4:0] scale_flags_w;
    wire scale_error_w;
    wire scale_req_valid_w = !child_rst_w && (state_q == ST_SCALE_REQ);
    wire scale_rsp_ready_w = !child_rst_w && (state_q == ST_SCALE_WAIT);

    TensorNpuFp64Pow2Scale u_scale (
        .clk_i        (clk_i),
        .rst_i        (child_rst_w),
        .req_valid_i  (scale_req_valid_w),
        .req_ready_o  (scale_req_ready_w),
        .req_sum_i    (f64_value_q),
        .req_d_i      (element_count_q),
        .rsp_valid_o  (scale_rsp_valid_w),
        .rsp_ready_i  (scale_rsp_ready_w),
        .rsp_result_o (scale_result_w),
        .rsp_flags_o  (scale_flags_w),
        .rsp_error_o  (scale_error_w)
    );

    wire scale_req_fire_w = scale_req_valid_w && scale_req_ready_w;
    wire scale_rsp_fire_w = scale_rsp_valid_w && scale_rsp_ready_w;
    wire scale_fatal_w =
        scale_rsp_fire_w &&
        (scale_error_w || scale_flags_w[4] || scale_flags_w[3] ||
         scale_flags_w[2] || scale_result_w[63] ||
         (scale_result_w[62:52] == 11'h7ff));

    // ---------------------------------------------------------------------
    // Ordered F64 -> F32 narrowing
    // ---------------------------------------------------------------------
    wire convert_req_ready_w;
    wire convert_rsp_valid_w;
    wire [31:0] convert_result_w;
    wire [4:0] convert_flags_w;
    wire convert_error_w;
    wire convert_req_valid_w = !child_rst_w && (state_q == ST_CONVERT_REQ);
    wire convert_rsp_ready_w = !child_rst_w && (state_q == ST_CONVERT_WAIT);

    TensorNpuFp64ToFp32 u_convert (
        .clk_i       (clk_i),
        .rst_i       (child_rst_w),
        .req_valid_i (convert_req_valid_w),
        .req_ready_o (convert_req_ready_w),
        .operand_i   (f64_value_q),
        .rsp_valid_o (convert_rsp_valid_w),
        .rsp_ready_i (convert_rsp_ready_w),
        .result_o    (convert_result_w),
        .flags_o     (convert_flags_w),
        .error_o     (convert_error_w)
    );

    wire convert_req_fire_w = convert_req_valid_w && convert_req_ready_w;
    wire convert_rsp_fire_w = convert_rsp_valid_w && convert_rsp_ready_w;
    wire convert_value_fatal_w =
        convert_rsp_fire_w && !convert_error_w &&
        (convert_flags_w[4] || convert_flags_w[3] || convert_flags_w[2] ||
         convert_result_w[31] || (convert_result_w[30:23] == 8'hff));
    wire convert_child_fatal_w = convert_rsp_fire_w && convert_error_w;

    // ---------------------------------------------------------------------
    // Shared FP32 add/multiply: RMS epsilon add or committed-row replay mul
    // ---------------------------------------------------------------------
    wire post_req_ready_w;
    wire post_rsp_valid_w;
    wire [31:0] post_result_w;
    wire [4:0] post_flags_w;
    wire post_is_mul_w = (state_q == ST_MUL_REQ);
    wire post_req_valid_w =
        !child_rst_w && ((state_q == ST_EPS_REQ) || (state_q == ST_MUL_REQ));
    wire post_rsp_ready_w =
        !child_rst_w && ((state_q == ST_EPS_WAIT) || (state_q == ST_MUL_WAIT));
    wire [31:0] post_lhs_w = post_is_mul_w ? replay_operand_q : narrow_bits_q;
    wire [31:0] post_rhs_w = post_is_mul_w ? reciprocal_bits_q : eps_bits_q;

    TensorNpuFp32AddMul u_post_addmul (
        .clk_i         (clk_i),
        .rst_i         (child_rst_w),
        .req_valid_i   (post_req_valid_w),
        .req_ready_o   (post_req_ready_w),
        .op_mul_i      (post_is_mul_w),
        .lhs_bits_i    (post_lhs_w),
        .rhs_bits_i    (post_rhs_w),
        .rsp_valid_o   (post_rsp_valid_w),
        .rsp_ready_i   (post_rsp_ready_w),
        .result_bits_o (post_result_w),
        .flags_o       (post_flags_w)
    );

    wire post_req_fire_w = post_req_valid_w && post_req_ready_w;
    wire post_rsp_fire_w = post_rsp_valid_w && post_rsp_ready_w;
    wire eps_req_fire_w = post_req_fire_w && (state_q == ST_EPS_REQ);
    wire eps_rsp_fire_w = post_rsp_fire_w && (state_q == ST_EPS_WAIT);
    wire mul_req_fire_w = post_req_fire_w && (state_q == ST_MUL_REQ);
    wire mul_rsp_fire_w = post_rsp_fire_w && (state_q == ST_MUL_WAIT);
    wire eps_fatal_w =
        eps_rsp_fire_w &&
        (post_flags_w[4] || post_flags_w[3] || post_flags_w[2] ||
         post_result_w[31] || (post_result_w[30:23] == 8'hff));
    wire mul_fatal_w =
        mul_rsp_fire_w &&
        (post_flags_w[4] || post_flags_w[3] || post_flags_w[2] ||
         (post_result_w[30:23] == 8'hff));

    // ---------------------------------------------------------------------
    // Correctly-rounded FP32 sqrt
    // ---------------------------------------------------------------------
    wire sqrt_req_ready_w;
    wire sqrt_rsp_valid_w;
    wire [31:0] sqrt_result_w;
    wire [4:0] sqrt_flags_w;
    wire sqrt_req_valid_w = !child_rst_w && (state_q == ST_SQRT_REQ);
    wire sqrt_rsp_ready_w = !child_rst_w && (state_q == ST_SQRT_WAIT);

    TensorNpuFp32Sqrt u_sqrt (
        .clk_i            (clk_i),
        .rst_i            (child_rst_w),
        .req_valid_i      (sqrt_req_valid_w),
        .req_ready_o      (sqrt_req_ready_w),
        .operand_bits_i   (sqrt_operand_q),
        .rounding_mode_i  (3'b000),
        .rsp_valid_o      (sqrt_rsp_valid_w),
        .rsp_ready_i      (sqrt_rsp_ready_w),
        .result_bits_o    (sqrt_result_w),
        .flags_o          (sqrt_flags_w)
    );

    wire sqrt_req_fire_w = sqrt_req_valid_w && sqrt_req_ready_w;
    wire sqrt_rsp_fire_w = sqrt_rsp_valid_w && sqrt_rsp_ready_w;
    wire sqrt_value_fatal_w =
        sqrt_rsp_fire_w &&
        (sqrt_flags_w[4] || sqrt_flags_w[3] || sqrt_flags_w[2] ||
         sqrt_result_w[31] || (sqrt_result_w[30:23] == 8'hff));
    wire rms_sqrt_zero_w =
        sqrt_rsp_fire_w && (mode_q == MODE_RMS) &&
        (sqrt_result_w[30:0] == 31'b0);

    // L2 maximumNumber在accepted +0/positive-finite域等价于raw正数比较。
    wire [31:0] l2_den_candidate_w =
        (eps_bits_q > root_bits_q) ? eps_bits_q : root_bits_q;
    wire l2_den_zero_w =
        (state_q == ST_L2_MAX) && (l2_den_candidate_w[30:0] == 31'b0);

    // ---------------------------------------------------------------------
    // Correctly-rounded reciprocal 1.0f / denominator
    // ---------------------------------------------------------------------
    wire div_req_ready_w;
    wire div_rsp_valid_w;
    wire [31:0] div_result_w;
    wire [4:0] div_flags_w;
    wire div_req_valid_w = !child_rst_w && (state_q == ST_RECIP_REQ);
    wire div_rsp_ready_w = !child_rst_w && (state_q == ST_RECIP_WAIT);

    TensorNpuFp32Div u_recip (
        .clk_i         (clk_i),
        .rst_i         (child_rst_w),
        .req_valid_i   (div_req_valid_w),
        .req_ready_o   (div_req_ready_w),
        .lhs_bits_i    (32'h3f800000),
        .rhs_bits_i    (denominator_bits_q),
        .rsp_valid_o   (div_rsp_valid_w),
        .rsp_ready_i   (div_rsp_ready_w),
        .result_bits_o (div_result_w),
        .flags_o       (div_flags_w)
    );

    wire div_req_fire_w = div_req_valid_w && div_req_ready_w;
    wire div_rsp_fire_w = div_rsp_valid_w && div_rsp_ready_w;
    wire div_fatal_w =
        div_rsp_fire_w &&
        (div_flags_w[4] || div_flags_w[3] || div_flags_w[2] ||
         div_result_w[31] || (div_result_w[30:23] == 8'hff) ||
         (div_result_w[30:0] == 31'b0));

    wire replay_source_fatal_w =
        (state_q == ST_REPLAY_LOAD) &&
        (!sum_replay_valid_w || (replay_index_q >= element_count_q) ||
         (replay_index_q >= MAX_D_COUNT));

    wire fatal_event_w =
        sum_fatal_w || scale_fatal_w || convert_child_fatal_w ||
        convert_value_fatal_w || eps_fatal_w || sqrt_value_fatal_w ||
        rms_sqrt_zero_w || l2_den_zero_w || div_fatal_w ||
        replay_source_fatal_w || mul_fatal_w;

    reg [4:0] fatal_code_r;
    reg [4:0] fatal_flags_r;
    always @(*) begin
        fatal_code_r  = ERR_NONE;
        fatal_flags_r = 5'b0;
        if (sum_fatal_w) begin
            fatal_code_r  = ERR_SUM_CHILD;
            fatal_flags_r = sum_flags_w;
        end else if (scale_fatal_w) begin
            fatal_code_r  = ERR_SCALE_CHILD;
            fatal_flags_r = scale_flags_w;
        end else if (convert_child_fatal_w) begin
            fatal_code_r  = ERR_CONVERT_CHILD;
            fatal_flags_r = convert_flags_w;
        end else if (convert_value_fatal_w) begin
            fatal_code_r  = ERR_CONVERT_FATAL;
            fatal_flags_r = convert_flags_w;
        end else if (eps_fatal_w) begin
            fatal_code_r  = ERR_EPS_ADD_FATAL;
            fatal_flags_r = post_flags_w;
        end else if (sqrt_value_fatal_w) begin
            fatal_code_r  = ERR_SQRT_FATAL;
            fatal_flags_r = sqrt_flags_w;
        end else if (rms_sqrt_zero_w || l2_den_zero_w) begin
            fatal_code_r = ERR_DEN_ZERO;
            if (rms_sqrt_zero_w) begin
                fatal_flags_r = sqrt_flags_w;
            end
        end else if (div_fatal_w) begin
            fatal_code_r  = ERR_RECIP_FATAL;
            fatal_flags_r = div_flags_w;
        end else if (replay_source_fatal_w) begin
            fatal_code_r = ERR_REPLAY_SOURCE;
        end else if (mul_fatal_w) begin
            fatal_code_r  = ERR_REPLAY_MUL_FATAL;
            fatal_flags_r = post_flags_w;
        end
    end

    wire replay_load_progress_w =
        (state_q == ST_REPLAY_LOAD) && sum_replay_valid_w;
    wire l2_max_progress_w = (state_q == ST_L2_MAX) && !l2_den_zero_w;
    wire progress_w =
        sum_start_fire_w || lane_fire_w || sum_terminal_w ||
        scale_req_fire_w || scale_rsp_fire_w ||
        convert_req_fire_w || convert_rsp_fire_w ||
        eps_req_fire_w || eps_rsp_fire_w ||
        sqrt_req_fire_w || sqrt_rsp_fire_w || l2_max_progress_w ||
        div_req_fire_w || div_rsp_fire_w || replay_load_progress_w ||
        mul_req_fire_w || mul_rsp_fire_w;

    wire [31:0] stall_cycles_next_w = stall_cycles_q + 32'd1;
    wire [31:0] command_cycles_next_w = command_cycles_q + 32'd1;
    wire command_timeout_w =
        precommit_processing_w &&
        ((COMMAND_TIMEOUT_CYCLES == 32'd0) ||
         (command_cycles_next_w >= COMMAND_TIMEOUT_CYCLES));
    wire stall_timeout_w =
        precommit_processing_w && !progress_w &&
        ((STALL_TIMEOUT_CYCLES == 32'd0) ||
         (stall_cycles_next_w >= STALL_TIMEOUT_CYCLES));

    // 状态优先级：reset > corrupt state > child/domain fatal > command
    // watchdog > stall watchdog > normal ready/valid progress。
    always @(posedge clk_i) begin
        if (rst_i) begin
            state_q              <= ST_IDLE;
            mode_q               <= MODE_RMS;
            element_count_q      <= {COUNT_WIDTH{1'b0}};
            eps_bits_q           <= 32'b0;
            f64_value_q          <= 64'b0;
            narrow_bits_q        <= 32'b0;
            sqrt_operand_q       <= 32'b0;
            root_bits_q          <= 32'b0;
            denominator_bits_q   <= 32'b0;
            reciprocal_bits_q    <= 32'b0;
            replay_operand_q     <= 32'b0;
            replay_index_q       <= {COUNT_WIDTH{1'b0}};
            out_index_q          <= {COUNT_WIDTH{1'b0}};
            elements_accepted_q  <= {COUNT_WIDTH{1'b0}};
            elements_emitted_q   <= {COUNT_WIDTH{1'b0}};
            active_cycles_q      <= 32'b0;
            stall_cycles_q       <= 32'b0;
            command_cycles_q     <= 32'b0;
            flags_accum_q        <= 5'b0;
            flags_q              <= 5'b0;
            error_code_q         <= ERR_NONE;
        end else begin
            if (active_w) begin
                active_cycles_q <= active_cycles_q + 32'd1;
            end

            if (!precommit_processing_w) begin
                stall_cycles_q   <= 32'b0;
                command_cycles_q <= 32'b0;
            end else begin
                command_cycles_q <= command_cycles_next_w;
                if (progress_w) begin
                    stall_cycles_q <= 32'b0;
                end else begin
                    stall_cycles_q <= stall_cycles_next_w;
                end
            end

            if (!state_valid_w) begin
                state_q             <= ST_ERROR;
                error_code_q        <= ERR_ILLEGAL_STATE;
                flags_q             <= flags_accum_q;
                elements_emitted_q  <= {COUNT_WIDTH{1'b0}};
            end else if (fatal_event_w) begin
                state_q             <= ST_ERROR;
                error_code_q        <= fatal_code_r;
                flags_accum_q       <= flags_accum_q | fatal_flags_r;
                flags_q             <= flags_accum_q | fatal_flags_r;
                elements_emitted_q  <= {COUNT_WIDTH{1'b0}};
            end else if (command_timeout_w) begin
                state_q             <= ST_ERROR;
                error_code_q        <= ERR_COMMAND_TIMEOUT;
                flags_q             <= flags_accum_q;
                elements_emitted_q  <= {COUNT_WIDTH{1'b0}};
            end else if (stall_timeout_w) begin
                state_q             <= ST_ERROR;
                error_code_q        <= ERR_STALL_TIMEOUT;
                flags_q             <= flags_accum_q;
                elements_emitted_q  <= {COUNT_WIDTH{1'b0}};
            end else begin
                case (state_q)
                    ST_IDLE: begin
                        if (start_fire_w) begin
                            mode_q              <= mode_i;
                            element_count_q     <= element_count_i;
                            eps_bits_q          <= eps_bits_i;
                            f64_value_q         <= 64'b0;
                            narrow_bits_q       <= 32'b0;
                            sqrt_operand_q      <= 32'b0;
                            root_bits_q         <= 32'b0;
                            denominator_bits_q  <= 32'b0;
                            reciprocal_bits_q   <= 32'b0;
                            replay_operand_q    <= 32'b0;
                            replay_index_q      <= {COUNT_WIDTH{1'b0}};
                            out_index_q         <= {COUNT_WIDTH{1'b0}};
                            elements_accepted_q <= {COUNT_WIDTH{1'b0}};
                            elements_emitted_q  <= {COUNT_WIDTH{1'b0}};
                            active_cycles_q     <= 32'b0;
                            flags_accum_q       <= 5'b0;
                            flags_q             <= 5'b0;
                            error_code_q        <= ERR_NONE;
                            if (!header_mode_valid_w) begin
                                state_q      <= ST_ERROR;
                                error_code_q <= ERR_HEADER_MODE;
                            end else if (!header_d_valid_w ||
                                         (element_count_i == {COUNT_WIDTH{1'b0}}) ||
                                         (element_count_i > MAX_D_COUNT)) begin
                                state_q      <= ST_ERROR;
                                error_code_q <= ERR_HEADER_D;
                            end else if (!header_eps_valid_w) begin
                                state_q      <= ST_ERROR;
                                error_code_q <= ERR_HEADER_EPS;
                            end else begin
                                state_q <= ST_SUM_START;
                            end
                        end
                    end

                    ST_SUM_START: begin
                        if (sum_start_fire_w) begin
                            state_q <= ST_SUM_RUN;
                        end
                    end

                    ST_SUM_RUN: begin
                        if (lane_fire_w) begin
                            elements_accepted_q <= elements_accepted_q + COUNT_ONE;
                        end
                        if (sum_terminal_w) begin
                            flags_accum_q <= flags_accum_q | sum_flags_w;
                            f64_value_q   <= sum_bits_w;
                            if (mode_q == MODE_RMS) begin
                                state_q <= ST_SCALE_REQ;
                            end else begin
                                state_q <= ST_CONVERT_REQ;
                            end
                        end
                    end

                    ST_SCALE_REQ: begin
                        if (scale_req_fire_w) begin
                            state_q <= ST_SCALE_WAIT;
                        end
                    end

                    ST_SCALE_WAIT: begin
                        if (scale_rsp_fire_w) begin
                            flags_accum_q <= flags_accum_q | scale_flags_w;
                            f64_value_q   <= scale_result_w;
                            state_q       <= ST_CONVERT_REQ;
                        end
                    end

                    ST_CONVERT_REQ: begin
                        if (convert_req_fire_w) begin
                            state_q <= ST_CONVERT_WAIT;
                        end
                    end

                    ST_CONVERT_WAIT: begin
                        if (convert_rsp_fire_w) begin
                            flags_accum_q <= flags_accum_q | convert_flags_w;
                            narrow_bits_q <= convert_result_w;
                            if (mode_q == MODE_RMS) begin
                                state_q <= ST_EPS_REQ;
                            end else begin
                                sqrt_operand_q <= convert_result_w;
                                state_q         <= ST_SQRT_REQ;
                            end
                        end
                    end

                    ST_EPS_REQ: begin
                        if (eps_req_fire_w) begin
                            state_q <= ST_EPS_WAIT;
                        end
                    end

                    ST_EPS_WAIT: begin
                        if (eps_rsp_fire_w) begin
                            flags_accum_q  <= flags_accum_q | post_flags_w;
                            sqrt_operand_q <= post_result_w;
                            state_q        <= ST_SQRT_REQ;
                        end
                    end

                    ST_SQRT_REQ: begin
                        if (sqrt_req_fire_w) begin
                            state_q <= ST_SQRT_WAIT;
                        end
                    end

                    ST_SQRT_WAIT: begin
                        if (sqrt_rsp_fire_w) begin
                            flags_accum_q <= flags_accum_q | sqrt_flags_w;
                            root_bits_q   <= sqrt_result_w;
                            if (mode_q == MODE_RMS) begin
                                denominator_bits_q <= sqrt_result_w;
                                state_q            <= ST_RECIP_REQ;
                            end else begin
                                state_q <= ST_L2_MAX;
                            end
                        end
                    end

                    ST_L2_MAX: begin
                        denominator_bits_q <= l2_den_candidate_w;
                        state_q            <= ST_RECIP_REQ;
                    end

                    ST_RECIP_REQ: begin
                        if (div_req_fire_w) begin
                            state_q <= ST_RECIP_WAIT;
                        end
                    end

                    ST_RECIP_WAIT: begin
                        if (div_rsp_fire_w) begin
                            flags_accum_q     <= flags_accum_q | div_flags_w;
                            reciprocal_bits_q <= div_result_w;
                            replay_index_q    <= {COUNT_WIDTH{1'b0}};
                            state_q           <= ST_REPLAY_LOAD;
                        end
                    end

                    ST_REPLAY_LOAD: begin
                        replay_operand_q <= sum_replay_bits_w;
                        state_q          <= ST_MUL_REQ;
                    end

                    ST_MUL_REQ: begin
                        if (mul_req_fire_w) begin
                            state_q <= ST_MUL_WAIT;
                        end
                    end

                    ST_MUL_WAIT: begin
                        if (mul_rsp_fire_w) begin
                            flags_accum_q <= flags_accum_q | post_flags_w;
                            output_buffer_q[replay_index_q[INDEX_WIDTH-1:0]] <=
                                post_result_w;
                            if (replay_index_q == (element_count_q - COUNT_ONE)) begin
                                state_q <= ST_COMMIT;
                            end else begin
                                replay_index_q <= replay_index_q + COUNT_ONE;
                                state_q        <= ST_REPLAY_LOAD;
                            end
                        end
                    end

                    ST_COMMIT: begin
                        // 上一拍最后一个buffer写已完成；此拍仍无out_valid。
                        flags_q     <= flags_accum_q;
                        out_index_q <= {COUNT_WIDTH{1'b0}};
                        state_q     <= ST_OUTPUT;
                    end

                    ST_OUTPUT: begin
                        if (out_fire_w) begin
                            elements_emitted_q <= elements_emitted_q + COUNT_ONE;
                            if (out_last_o) begin
                                state_q <= ST_DONE;
                            end else begin
                                out_index_q <= out_index_q + COUNT_ONE;
                            end
                        end
                    end

                    ST_DONE: begin
                        state_q <= ST_IDLE;
                    end

                    ST_ERROR: begin
                        // child_rst_w在本整拍有效；本边沿完成同步取消后回IDLE。
                        state_q <= ST_IDLE;
                    end

                    default: begin
                        state_q <= ST_ERROR;
                    end
                endcase
            end
        end
    end

endmodule
