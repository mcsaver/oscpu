`timescale 1ns/1ps

// SPDX-License-Identifier: BSD-3-Clause
//
// 严格 lane 顺序的 FP32 square / exact F64 widen / serial FP64 add。
//
// 协议与原子性：
//   * start、lane 与三个 child 都只在 valid && ready 时采样；
//   * 每个 REQ 态保持 child valid/payload，后继 WAIT 态独占 response credit；
//   * row_buffer_q 在命令执行期间是私有存储，最后一次 FP64 add 成功前
//     committed_row_valid_o 恒为 0；
//   * ERROR 同样不发布 sum/row，并同步复位所有 child resident transaction；
//   * UF/NX 是可提交 IEEE 状态，NV/DZ/OF、child error 或 nonfinite 是 fatal。
module TensorNpuFp32SquareSum64 #(
    parameter integer MAX_D = 1024,
    parameter [31:0] STALL_TIMEOUT_CYCLES = 32'd64,
    parameter [31:0] COMMAND_TIMEOUT_CYCLES = 32'd65536
) (
    input  wire                                      clk_i,
    input  wire                                      rst_i,

    input  wire                                      start_i,
    output wire                                      ready_o,
    output wire                                      busy_o,
    input  wire [$clog2(MAX_D + 1)-1:0]             element_count_i,

    input  wire                                      lane_valid_i,
    output wire                                      lane_ready_o,
    input  wire [31:0]                               lane_bits_i,

    output wire                                      done_o,
    output wire                                      error_o,
    output wire [3:0]                                error_code_o,
    output wire [63:0]                               sum_bits_o,
    output wire [4:0]                                flags_o,

    output wire                                      committed_row_valid_o,
    output wire [$clog2(MAX_D + 1)-1:0]             committed_count_o,
    input  wire [$clog2(MAX_D + 1)-1:0]             replay_index_i,
    output wire                                      replay_valid_o,
    output reg  [31:0]                               replay_bits_o,

    output wire [$clog2(MAX_D + 1)-1:0]             elements_accepted_o,
    output wire [31:0]                               active_cycles_o
);

    localparam integer COUNT_WIDTH = $clog2(MAX_D + 1);
    localparam integer INDEX_WIDTH = (MAX_D <= 1) ? 1 : $clog2(MAX_D);

    localparam [3:0] ST_IDLE        = 4'd0;
    localparam [3:0] ST_WAIT_LANE   = 4'd1;
    localparam [3:0] ST_SQUARE_REQ  = 4'd2;
    localparam [3:0] ST_SQUARE_WAIT = 4'd3;
    localparam [3:0] ST_WIDEN_REQ   = 4'd4;
    localparam [3:0] ST_WIDEN_WAIT  = 4'd5;
    localparam [3:0] ST_ADD64_REQ   = 4'd6;
    localparam [3:0] ST_ADD64_WAIT  = 4'd7;
    localparam [3:0] ST_DONE        = 4'd8;
    localparam [3:0] ST_ERROR       = 4'd9;

    // error_code_o 的分类固定为父状态机观测到的第一个 fatal 原因。
    localparam [3:0] ERR_NONE             = 4'd0;
    localparam [3:0] ERR_COUNT            = 4'd1;
    localparam [3:0] ERR_INPUT_NONFINITE  = 4'd2;
    localparam [3:0] ERR_SQUARE_NV_DZ     = 4'd3;
    localparam [3:0] ERR_SQUARE_OVERFLOW  = 4'd4;
    localparam [3:0] ERR_WIDEN_FATAL      = 4'd5;
    localparam [3:0] ERR_ADD_DOMAIN       = 4'd6;
    localparam [3:0] ERR_ADD_NV_DZ        = 4'd7;
    localparam [3:0] ERR_ADD_OVERFLOW     = 4'd8;
    localparam [3:0] ERR_STALL_TIMEOUT    = 4'd9;
    localparam [3:0] ERR_COMMAND_TIMEOUT  = 4'd10;
    localparam [3:0] ERR_ILLEGAL_STATE    = 4'd11;

    // MAX_D 是 32-bit integer parameter；常量 part-select 明确形成端口同宽比较值。
    localparam [COUNT_WIDTH-1:0] MAX_D_COUNT = MAX_D[COUNT_WIDTH-1:0];

    reg [3:0] state_q;
    reg [COUNT_WIDTH-1:0] element_count_q;
    reg [COUNT_WIDTH-1:0] lane_index_q;
    reg [COUNT_WIDTH-1:0] elements_accepted_q;
    reg [31:0] active_cycles_q;
    reg [31:0] stall_cycles_q;
    reg [31:0] command_cycles_q;

    reg [31:0] lane_operand_q;
    reg [31:0] square_bits_q;
    reg [63:0] term64_q;
    reg [63:0] sum_work_q;
    reg [4:0]  flags_accum_q;

    reg [63:0] sum_bits_q;
    reg [4:0]  flags_q;
    reg [3:0]  error_code_q;
    reg         committed_row_valid_q;
    reg [COUNT_WIDTH-1:0] committed_count_q;

    // 该存储综合时对应一份 MAX_D x 32 单写/组合读 row buffer；本任务只做功能仿真。
    reg [31:0] row_buffer_q [0:MAX_D-1];

    wire state_valid_w =
        (state_q == ST_IDLE)        || (state_q == ST_WAIT_LANE)   ||
        (state_q == ST_SQUARE_REQ)  || (state_q == ST_SQUARE_WAIT) ||
        (state_q == ST_WIDEN_REQ)   || (state_q == ST_WIDEN_WAIT)  ||
        (state_q == ST_ADD64_REQ)   || (state_q == ST_ADD64_WAIT)  ||
        (state_q == ST_DONE)        || (state_q == ST_ERROR);
    wire processing_w =
        (state_q == ST_WAIT_LANE)   || (state_q == ST_SQUARE_REQ)  ||
        (state_q == ST_SQUARE_WAIT) || (state_q == ST_WIDEN_REQ)   ||
        (state_q == ST_WIDEN_WAIT)  || (state_q == ST_ADD64_REQ)   ||
        (state_q == ST_ADD64_WAIT);

    assign ready_o  = !rst_i && (state_q == ST_IDLE);
    assign busy_o   = !rst_i && (state_q != ST_IDLE);
    assign done_o   = !rst_i && ((state_q == ST_DONE) || (state_q == ST_ERROR));
    assign error_o  = !rst_i && (state_q == ST_ERROR);

    // error_code is architecturally meaningful only on the ERROR terminal
    // beat; never leak a stale failure code after returning to IDLE.
    assign error_code_o = (state_q == ST_ERROR) ? error_code_q : ERR_NONE;
    assign sum_bits_o   = sum_bits_q;
    assign flags_o      = flags_q;

    assign committed_row_valid_o = !rst_i && committed_row_valid_q;
    assign committed_count_o     = committed_count_q;
    assign elements_accepted_o   = elements_accepted_q;
    assign active_cycles_o       = active_cycles_q;

    wire start_fire_w = start_i && ready_o;
    assign lane_ready_o = !rst_i && (state_q == ST_WAIT_LANE);
    wire lane_fire_w = lane_valid_i && lane_ready_o;

    assign replay_valid_o =
        !rst_i && committed_row_valid_q &&
        (replay_index_i < committed_count_q) &&
        (replay_index_i < MAX_D_COUNT);

    // replay_index_i 可能编码 MAX_D 及以上；范围判断必须先于数组索引。
    always @(*) begin
        replay_bits_o = 32'b0;
        if (replay_valid_o) begin
            replay_bits_o = row_buffer_q[replay_index_i[INDEX_WIDTH-1:0]];
        end
    end

    // ERROR 保持整拍 child reset，有效清除 request、inflight 或 held response。
    wire child_rst_w = rst_i || (state_q == ST_ERROR) || !state_valid_w;

    wire        square_req_valid_w;
    wire        square_req_ready_w;
    wire        square_rsp_valid_w;
    wire        square_rsp_ready_w;
    wire [31:0] square_result_w;
    wire [4:0]  square_flags_w;

    assign square_req_valid_w = !child_rst_w && (state_q == ST_SQUARE_REQ);
    assign square_rsp_ready_w = !child_rst_w && (state_q == ST_SQUARE_WAIT);

    TensorNpuFp32AddMul u_square (
        .clk_i         (clk_i),
        .rst_i         (child_rst_w),
        .req_valid_i   (square_req_valid_w),
        .req_ready_o   (square_req_ready_w),
        .op_mul_i      (1'b1),
        .lhs_bits_i    (lane_operand_q),
        .rhs_bits_i    (lane_operand_q),
        .rsp_valid_o   (square_rsp_valid_w),
        .rsp_ready_i   (square_rsp_ready_w),
        .result_bits_o (square_result_w),
        .flags_o       (square_flags_w)
    );

    wire        widen_req_valid_w;
    wire        widen_req_ready_w;
    wire        widen_rsp_valid_w;
    wire        widen_rsp_ready_w;
    wire [63:0] widen_result_w;
    wire [4:0]  widen_flags_w;
    wire        widen_error_w;

    assign widen_req_valid_w = !child_rst_w && (state_q == ST_WIDEN_REQ);
    assign widen_rsp_ready_w = !child_rst_w && (state_q == ST_WIDEN_WAIT);

    TensorNpuFp32ToFp64 u_widen (
        .clk_i       (clk_i),
        .rst_i       (child_rst_w),
        .req_valid_i (widen_req_valid_w),
        .req_ready_o (widen_req_ready_w),
        .operand_i   (square_bits_q),
        .rsp_valid_o (widen_rsp_valid_w),
        .rsp_ready_i (widen_rsp_ready_w),
        .result_o    (widen_result_w),
        .flags_o     (widen_flags_w),
        .error_o     (widen_error_w)
    );

    wire        add_req_valid_w;
    wire        add_req_ready_w;
    wire        add_rsp_valid_w;
    wire        add_rsp_ready_w;
    wire [63:0] add_result_w;
    wire [4:0]  add_flags_w;
    wire        add_error_w;

    assign add_req_valid_w = !child_rst_w && (state_q == ST_ADD64_REQ);
    assign add_rsp_ready_w = !child_rst_w && (state_q == ST_ADD64_WAIT);

    TensorNpuFp64Add u_add64 (
        .clk_i       (clk_i),
        .rst_i       (child_rst_w),
        .req_valid_i (add_req_valid_w),
        .req_ready_o (add_req_ready_w),
        .operand_a_i (sum_work_q),
        .operand_b_i (term64_q),
        .rsp_valid_o (add_rsp_valid_w),
        .rsp_ready_i (add_rsp_ready_w),
        .result_o    (add_result_w),
        .flags_o     (add_flags_w),
        .error_o     (add_error_w)
    );

    wire square_req_fire_w = square_req_valid_w && square_req_ready_w;
    wire square_rsp_fire_w = square_rsp_valid_w && square_rsp_ready_w;
    wire widen_req_fire_w  = widen_req_valid_w && widen_req_ready_w;
    wire widen_rsp_fire_w  = widen_rsp_valid_w && widen_rsp_ready_w;
    wire add_req_fire_w    = add_req_valid_w && add_req_ready_w;
    wire add_rsp_fire_w    = add_rsp_valid_w && add_rsp_ready_w;

    wire progress_w =
        lane_fire_w       || square_req_fire_w || square_rsp_fire_w ||
        widen_req_fire_w  || widen_rsp_fire_w  || add_req_fire_w    ||
        add_rsp_fire_w;

    wire input_nonfinite_w = lane_fire_w && (lane_bits_i[30:23] == 8'hff);
    wire square_nv_dz_w =
        square_rsp_fire_w && (square_flags_w[4] || square_flags_w[3]);
    wire square_overflow_w =
        square_rsp_fire_w &&
        (square_flags_w[2] || (square_result_w[30:23] == 8'hff));
    wire widen_fatal_w =
        widen_rsp_fire_w &&
        (widen_error_w || widen_flags_w[4] || widen_flags_w[3] ||
         widen_flags_w[2] || widen_result_w[63] ||
         (widen_result_w[62:52] == 11'h7ff));
    wire add_domain_w = add_rsp_fire_w && add_error_w;
    wire add_nv_dz_w =
        add_rsp_fire_w && !add_error_w && (add_flags_w[4] || add_flags_w[3]);
    wire add_overflow_w =
        add_rsp_fire_w && !add_error_w &&
        (add_flags_w[2] || add_result_w[63] ||
         (add_result_w[62:52] == 11'h7ff));

    wire fatal_event_w =
        input_nonfinite_w || square_nv_dz_w || square_overflow_w ||
        widen_fatal_w || add_domain_w || add_nv_dz_w || add_overflow_w;

    reg [3:0] fatal_code_r;
    reg [4:0] fatal_flags_r;
    always @(*) begin
        fatal_code_r  = ERR_NONE;
        fatal_flags_r = 5'b0;
        if (input_nonfinite_w) begin
            fatal_code_r = ERR_INPUT_NONFINITE;
        end else if (square_nv_dz_w) begin
            fatal_code_r  = ERR_SQUARE_NV_DZ;
            fatal_flags_r = square_flags_w;
        end else if (square_overflow_w) begin
            fatal_code_r  = ERR_SQUARE_OVERFLOW;
            fatal_flags_r = square_flags_w;
        end else if (widen_fatal_w) begin
            fatal_code_r  = ERR_WIDEN_FATAL;
            fatal_flags_r = widen_flags_w;
        end else if (add_domain_w) begin
            fatal_code_r  = ERR_ADD_DOMAIN;
            fatal_flags_r = add_flags_w;
        end else if (add_nv_dz_w) begin
            fatal_code_r  = ERR_ADD_NV_DZ;
            fatal_flags_r = add_flags_w;
        end else if (add_overflow_w) begin
            fatal_code_r  = ERR_ADD_OVERFLOW;
            fatal_flags_r = add_flags_w;
        end
    end

    wire [31:0] stall_cycles_next_w = stall_cycles_q + 32'd1;
    wire [31:0] command_cycles_next_w = command_cycles_q + 32'd1;
    wire stall_timeout_w =
        processing_w && !progress_w &&
        ((STALL_TIMEOUT_CYCLES == 32'd0) ||
         (stall_cycles_next_w >= STALL_TIMEOUT_CYCLES));
    wire command_timeout_w =
        processing_w &&
        ((COMMAND_TIMEOUT_CYCLES == 32'd0) ||
         (command_cycles_next_w >= COMMAND_TIMEOUT_CYCLES));

    // 状态更新优先级：reset > 非法状态 > fatal > watchdog > 正常握手。
    always @(posedge clk_i) begin
        if (rst_i) begin
            state_q               <= ST_IDLE;
            element_count_q       <= {COUNT_WIDTH{1'b0}};
            lane_index_q          <= {COUNT_WIDTH{1'b0}};
            elements_accepted_q   <= {COUNT_WIDTH{1'b0}};
            active_cycles_q       <= 32'b0;
            stall_cycles_q        <= 32'b0;
            command_cycles_q      <= 32'b0;
            lane_operand_q        <= 32'b0;
            square_bits_q         <= 32'b0;
            term64_q              <= 64'b0;
            sum_work_q            <= 64'b0;
            flags_accum_q         <= 5'b0;
            sum_bits_q            <= 64'b0;
            flags_q               <= 5'b0;
            error_code_q          <= ERR_NONE;
            committed_row_valid_q <= 1'b0;
            committed_count_q     <= {COUNT_WIDTH{1'b0}};
        end else begin
            if (!processing_w) begin
                stall_cycles_q   <= 32'b0;
                command_cycles_q <= 32'b0;
            end else begin
                command_cycles_q <= command_cycles_next_w;
                if (progress_w) begin
                    stall_cycles_q <= 32'b0;
                end else begin
                    stall_cycles_q <= stall_cycles_next_w;
                end
                active_cycles_q <= active_cycles_q + 32'd1;
            end

            if (!state_valid_w) begin
                state_q               <= ST_ERROR;
                error_code_q          <= ERR_ILLEGAL_STATE;
                sum_bits_q            <= 64'b0;
                flags_q               <= flags_accum_q;
                committed_row_valid_q <= 1'b0;
                committed_count_q     <= {COUNT_WIDTH{1'b0}};
            end else if (fatal_event_w) begin
                state_q               <= ST_ERROR;
                error_code_q          <= fatal_code_r;
                sum_bits_q            <= 64'b0;
                flags_q               <= flags_accum_q | fatal_flags_r;
                committed_row_valid_q <= 1'b0;
                committed_count_q     <= {COUNT_WIDTH{1'b0}};
                if (input_nonfinite_w) begin
                    // 非有限 lane 也发生了真实 input handshake；只记入私有证据，绝不提交。
                    row_buffer_q[lane_index_q[INDEX_WIDTH-1:0]] <= lane_bits_i;
                    lane_operand_q      <= lane_bits_i;
                    elements_accepted_q <= elements_accepted_q + {{(COUNT_WIDTH-1){1'b0}}, 1'b1};
                end
            end else if (command_timeout_w) begin
                state_q               <= ST_ERROR;
                error_code_q          <= ERR_COMMAND_TIMEOUT;
                sum_bits_q            <= 64'b0;
                flags_q               <= flags_accum_q;
                committed_row_valid_q <= 1'b0;
                committed_count_q     <= {COUNT_WIDTH{1'b0}};
            end else if (stall_timeout_w) begin
                state_q               <= ST_ERROR;
                error_code_q          <= ERR_STALL_TIMEOUT;
                sum_bits_q            <= 64'b0;
                flags_q               <= flags_accum_q;
                committed_row_valid_q <= 1'b0;
                committed_count_q     <= {COUNT_WIDTH{1'b0}};
            end else begin
                case (state_q)
                    ST_IDLE: begin
                        if (start_fire_w) begin
                            element_count_q       <= element_count_i;
                            lane_index_q          <= {COUNT_WIDTH{1'b0}};
                            elements_accepted_q   <= {COUNT_WIDTH{1'b0}};
                            active_cycles_q       <= 32'b0;
                            lane_operand_q        <= 32'b0;
                            square_bits_q         <= 32'b0;
                            term64_q              <= 64'b0;
                            sum_work_q            <= 64'b0;
                            flags_accum_q         <= 5'b0;
                            sum_bits_q            <= 64'b0;
                            flags_q               <= 5'b0;
                            error_code_q          <= ERR_NONE;
                            committed_row_valid_q <= 1'b0;
                            committed_count_q     <= {COUNT_WIDTH{1'b0}};
                            if ((element_count_i == {COUNT_WIDTH{1'b0}}) ||
                                (element_count_i > MAX_D_COUNT)) begin
                                state_q      <= ST_ERROR;
                                error_code_q <= ERR_COUNT;
                            end else begin
                                state_q <= ST_WAIT_LANE;
                            end
                        end
                    end

                    ST_WAIT_LANE: begin
                        if (lane_fire_w) begin
                            // lane_index_q < latched D <= MAX_D，故截取 INDEX_WIDTH 安全。
                            row_buffer_q[lane_index_q[INDEX_WIDTH-1:0]] <= lane_bits_i;
                            lane_operand_q      <= lane_bits_i;
                            elements_accepted_q <= elements_accepted_q + {{(COUNT_WIDTH-1){1'b0}}, 1'b1};
                            state_q             <= ST_SQUARE_REQ;
                        end
                    end

                    ST_SQUARE_REQ: begin
                        if (square_req_fire_w) begin
                            state_q <= ST_SQUARE_WAIT;
                        end
                    end

                    ST_SQUARE_WAIT: begin
                        if (square_rsp_fire_w) begin
                            square_bits_q <= square_result_w;
                            flags_accum_q <= flags_accum_q | square_flags_w;
                            state_q       <= ST_WIDEN_REQ;
                        end
                    end

                    ST_WIDEN_REQ: begin
                        if (widen_req_fire_w) begin
                            state_q <= ST_WIDEN_WAIT;
                        end
                    end

                    ST_WIDEN_WAIT: begin
                        if (widen_rsp_fire_w) begin
                            term64_q      <= widen_result_w;
                            flags_accum_q <= flags_accum_q | widen_flags_w;
                            state_q       <= ST_ADD64_REQ;
                        end
                    end

                    ST_ADD64_REQ: begin
                        if (add_req_fire_w) begin
                            state_q <= ST_ADD64_WAIT;
                        end
                    end

                    ST_ADD64_WAIT: begin
                        if (add_rsp_fire_w) begin
                            sum_work_q    <= add_result_w;
                            flags_accum_q <= flags_accum_q | add_flags_w;
                            if ((lane_index_q + {{(COUNT_WIDTH-1){1'b0}}, 1'b1}) ==
                                element_count_q) begin
                                // 最后一个 serial add 是 sum 与 replay row 的唯一提交点。
                                sum_bits_q            <= add_result_w;
                                flags_q               <= flags_accum_q | add_flags_w;
                                committed_count_q     <= element_count_q;
                                committed_row_valid_q <= 1'b1;
                                state_q               <= ST_DONE;
                            end else begin
                                lane_index_q <= lane_index_q + {{(COUNT_WIDTH-1){1'b0}}, 1'b1};
                                state_q      <= ST_WAIT_LANE;
                            end
                        end
                    end

                    ST_DONE: begin
                        state_q <= ST_IDLE;
                    end

                    ST_ERROR: begin
                        // child_rst_w 在本整拍为 1；此边沿完成同步取消后再回 IDLE。
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
