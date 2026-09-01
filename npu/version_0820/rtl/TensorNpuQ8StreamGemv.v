`timescale 1ns/1ps
`default_nettype none

// SPDX-License-Identifier: MIT
//
// TensorNpuQ8StreamGemv
//
// 本地 Q8_0 weight × F32 activation 的单个向量 stream GEMV primitive。
//
// 需求/协议/FSM/不变量/数据通路拓扑：
//   * IDLE 只接受 start_i && ready_o；shape 在该边沿锁存，busy start
//     结构性忽略。row/block 非法时在任何 stream handshake 前 fail closed。
//   * 每个 activation block 先由一个共享 TensorNpuQ8ReferenceQuantizer
//     接收恰好 32 个 raw F32 word；成功 terminal 才写 272-bit bank。
//   * 所有 activation block 完成后，一个共享
//     TensorNpuQ8ScaleAccumulator 按 row-major 顺序接收 weight/bank block
//     对。weight 不缓存，bank 动态读口综合为 MAX_BLOCKS:1 mux。
//   * 每行结果用独立 payload/row/valid 寄存器持有；valid && !ready 时
//     payload 稳定。早期行都是 provisional，最终行 handshake 后才发 DONE。
//   * reset > command timeout > progress/stall watchdog > 正常 FSM。ERROR
//     整拍同步 reset 两个 child，随后才回 IDLE，避免 stale terminal。
//   * 32x32 shape product 先扩展为 64x64 运算；weight command accounting
//     全程保持 64-bit。所有公开计数只在真实 external handshake 上递增。
//   * 父层最长组合路径仅包含 bank mux、counter compare 和 FSM decode；
//     dot/F32 critical path 均保留在已寄存隔离的 child module 内。
module TensorNpuQ8StreamGemv #(
    parameter integer MAX_BLOCKS = 128,
    parameter integer MAC_LANES  = 8,
    parameter [31:0] STALL_TIMEOUT_CYCLES = 32'd4096,
    parameter [63:0] COMMAND_TIMEOUT_CYCLES = 64'd1000000000
) (
    input  wire         clk_i,
    input  wire         rst_i,

    input  wire         start_i,
    output wire         ready_o,
    output wire         busy_o,
    input  wire [31:0]  row_count_i,
    input  wire [31:0]  block_count_i,

    input  wire         activation_valid_i,
    output wire         activation_ready_o,
    input  wire [31:0]  activation_bits_i,

    input  wire         weight_valid_i,
    output wire         weight_ready_o,
    input  wire [271:0] weight_block_i,

    output wire         result_valid_o,
    input  wire         result_ready_i,
    output wire [31:0]  result_bits_o,
    output wire [31:0]  result_row_index_o,

    output wire         done_o,
    output wire         error_o,
    output wire [7:0]   error_code_o,
    output wire [63:0]  active_cycles_o,
    output wire [31:0]  activation_words_accepted_o,
    output wire [63:0]  weight_blocks_accepted_o,
    output wire [31:0]  rows_emitted_o
);

    localparam [7:0] ERROR_NONE                = 8'h00;
    localparam [7:0] ERROR_ROW_COUNT_ZERO      = 8'h10;
    localparam [7:0] ERROR_BLOCK_COUNT_ZERO    = 8'h11;
    localparam [7:0] ERROR_BLOCK_COUNT_EXCEEDS = 8'h12;
    localparam [7:0] ERROR_ACTIVATION_STALL    = 8'h40;
    localparam [7:0] ERROR_WEIGHT_STALL        = 8'h41;
    localparam [7:0] ERROR_RESULT_STALL        = 8'h42;
    localparam [7:0] ERROR_COMMAND_TIMEOUT     = 8'h50;
    localparam [7:0] ERROR_INTERNAL_STATE      = 8'hff;

    localparam [3:0] STATE_IDLE          = 4'd0;
    localparam [3:0] STATE_QUANT_START   = 4'd1;
    localparam [3:0] STATE_QUANT_LOAD32  = 4'd2;
    localparam [3:0] STATE_QUANT_WAIT    = 4'd3;
    localparam [3:0] STATE_ROW_START     = 4'd4;
    localparam [3:0] STATE_WEIGHT_STREAM = 4'd5;
    localparam [3:0] STATE_ROW_WAIT      = 4'd6;
    localparam [3:0] STATE_RESULT_HOLD   = 4'd7;
    localparam [3:0] STATE_DONE          = 4'd8;
    localparam [3:0] STATE_ERROR         = 4'd9;

    localparam integer BLOCK_INDEX_WIDTH =
        (MAX_BLOCKS <= 1) ? 1 : $clog2(MAX_BLOCKS);
    localparam [31:0] MAX_BLOCKS_U32 = MAX_BLOCKS;

    generate
        if (MAX_BLOCKS < 1) begin : gen_invalid_max_blocks
            initial begin
                $fatal(1, "TensorNpuQ8StreamGemv MAX_BLOCKS must be >= 1");
            end
        end
    endgenerate

    reg [3:0] state_q;
    reg [31:0] row_count_q;
    reg [31:0] block_count_q;

    reg [31:0] quant_block_index_q;
    reg [5:0]  quant_word_index_q;
    reg [31:0] row_index_q;
    reg [31:0] weight_block_index_q;

    // 该 bank 综合为 MAX_BLOCKS 组 272-bit activation block storage。
    // 所有 entry 都会在本命令读出前被成功 quant terminal 覆盖，因此无需
    // 大规模 reset mux；reset 只取消 resident child transaction。
    reg [271:0] activation_block_bank_q [0:MAX_BLOCKS-1];

    reg          result_valid_q;
    reg [31:0]   result_bits_q;
    reg [31:0]   result_row_index_q;
    reg [7:0]    error_code_q;

    reg [63:0] command_cycles_q;
    reg [63:0] active_cycles_q;
    reg [31:0] stall_cycles_q;
    reg [31:0] activation_words_accepted_q;
    reg [63:0] weight_blocks_accepted_q;
    reg [31:0] rows_emitted_q;
    reg [63:0] expected_activation_words_q;
    reg [63:0] expected_weight_blocks_q;

    reg quant_input_credit_prev_q;
    reg accumulator_block_credit_prev_q;

    wire start_fire_w;
    wire activation_fire_w;
    wire weight_fire_w;
    wire result_fire_w;
    wire child_rst_w;

    wire quant_start_w;
    wire quant_ready_w;
    wire quant_input_ready_w;
    wire quant_done_w;
    wire quant_error_w;
    wire [3:0] quant_error_code_w;
    wire [271:0] quant_block_w;

    wire accumulator_start_w;
    wire accumulator_ready_w;
    wire accumulator_block_ready_w;
    wire accumulator_done_w;
    wire accumulator_error_w;
    wire [3:0] accumulator_error_code_w;
    wire [31:0] accumulator_result_bits_w;

    wire quant_input_credit_rise_w;
    wire accumulator_block_credit_rise_w;
    reg  progress_event_r;
    reg [7:0] stall_error_code_r;

    assign ready_o  = !rst_i && (state_q == STATE_IDLE);
    assign busy_o   = !rst_i && (state_q != STATE_IDLE);
    assign done_o   = !rst_i && (state_q == STATE_DONE);
    assign error_o  = !rst_i && (state_q == STATE_ERROR);

    assign activation_ready_o = !rst_i
                              && (state_q == STATE_QUANT_LOAD32)
                              && quant_input_ready_w;
    assign weight_ready_o = !rst_i
                          && (state_q == STATE_WEIGHT_STREAM)
                          && accumulator_block_ready_w;
    assign result_valid_o = !rst_i && result_valid_q;

    assign result_bits_o               = result_bits_q;
    assign result_row_index_o          = result_row_index_q;
    assign error_code_o                = error_code_q;
    assign active_cycles_o             = active_cycles_q;
    assign activation_words_accepted_o = activation_words_accepted_q;
    assign weight_blocks_accepted_o    = weight_blocks_accepted_q;
    assign rows_emitted_o              = rows_emitted_q;

    assign start_fire_w      = start_i && ready_o;
    assign activation_fire_w = activation_valid_i && activation_ready_o;
    assign weight_fire_w     = weight_valid_i && weight_ready_o;
    assign result_fire_w     = result_valid_o && result_ready_i;

    // ERROR 必须完整覆盖一个 posedge：STATE_ERROR 当前拍 child_rst_w 为 1，
    // 下一 posedge child 完成同步 reset，父级同拍才回 IDLE。
    assign child_rst_w = rst_i || (state_q == STATE_ERROR);

    assign quant_start_w = (state_q == STATE_QUANT_START);
    assign accumulator_start_w = (state_q == STATE_ROW_START);

    assign quant_input_credit_rise_w =
        quant_input_ready_w && !quant_input_credit_prev_q;
    assign accumulator_block_credit_rise_w =
        accumulator_block_ready_w && !accumulator_block_credit_prev_q;

    // Stall progress 只认状态推进所依赖的真实事件。持续为高的 child
    // credit 不会永久掩盖外部 producer stall；credit 的 0->1 只清一次，
    // 从而也不会把合法 child resident latency误计为“没有新 credit”。
    always @(*) begin
        progress_event_r   = 1'b0;
        stall_error_code_r = ERROR_INTERNAL_STATE;

        case (state_q)
            STATE_QUANT_START: begin
                progress_event_r   = quant_ready_w;
                stall_error_code_r = ERROR_ACTIVATION_STALL;
            end

            STATE_QUANT_LOAD32: begin
                progress_event_r = activation_fire_w
                                 || quant_input_credit_rise_w;
                stall_error_code_r = ERROR_ACTIVATION_STALL;
            end

            STATE_QUANT_WAIT: begin
                progress_event_r   = quant_done_w || quant_error_w;
                stall_error_code_r = ERROR_ACTIVATION_STALL;
            end

            STATE_ROW_START: begin
                progress_event_r   = accumulator_ready_w;
                stall_error_code_r = ERROR_WEIGHT_STALL;
            end

            STATE_WEIGHT_STREAM: begin
                progress_event_r = weight_fire_w
                                 || accumulator_block_credit_rise_w
                                 || accumulator_done_w;
                stall_error_code_r = ERROR_WEIGHT_STALL;
            end

            STATE_ROW_WAIT: begin
                progress_event_r   = accumulator_done_w;
                stall_error_code_r = ERROR_WEIGHT_STALL;
            end

            STATE_RESULT_HOLD: begin
                progress_event_r   = result_fire_w;
                stall_error_code_r = ERROR_RESULT_STALL;
            end

            default: begin
                progress_event_r   = 1'b0;
                stall_error_code_r = ERROR_INTERNAL_STATE;
            end
        endcase
    end

    /* verilator lint_off PINCONNECTEMPTY */
    TensorNpuQ8ReferenceQuantizer u_quantizer (
        .clk_i           (clk_i),
        .rst_i           (child_rst_w),
        .start_i         (quant_start_w),
        .ready_o         (quant_ready_w),
        .busy_o          (),
        .input_valid_i   (activation_valid_i
                          && (state_q == STATE_QUANT_LOAD32)),
        .input_ready_o   (quant_input_ready_w),
        .input_bits_i    (activation_bits_i),
        .done_o          (quant_done_w),
        .error_o         (quant_error_w),
        .error_code_o    (quant_error_code_w),
        .block_o         (quant_block_w),
        .active_cycles_o ()
    );

    TensorNpuQ8ScaleAccumulator #(
        .MAC_LANES(MAC_LANES)
    ) u_accumulator (
        .clk_i         (clk_i),
        .rst_i         (child_rst_w),
        .start_i       (accumulator_start_w),
        .ready_o       (accumulator_ready_w),
        .busy_o        (),
        .block_count_i (block_count_q),
        .block_valid_i (weight_valid_i
                        && (state_q == STATE_WEIGHT_STREAM)),
        .block_ready_o (accumulator_block_ready_w),
        .x_block_i     (weight_block_i),
        .y_block_i     (activation_block_bank_q[
            weight_block_index_q[BLOCK_INDEX_WIDTH-1:0]]),
        .done_o        (accumulator_done_w),
        .error_o       (accumulator_error_w),
        .error_code_o  (accumulator_error_code_w),
        .result_bits_o (accumulator_result_bits_w)
    );
    /* verilator lint_on PINCONNECTEMPTY */

    // reset > terminal cleanup > command timeout > stall timeout > FSM event。
    // command-timeout 边沿若已有 external valid/ready，公开计数仍记录该
    // 真实 handshake；transaction 随后 ERROR poison，绝不把它当成功完成。
    always @(posedge clk_i) begin
        if (rst_i) begin
            state_q                       <= STATE_IDLE;
            row_count_q                   <= 32'b0;
            block_count_q                 <= 32'b0;
            quant_block_index_q           <= 32'b0;
            quant_word_index_q            <= 6'b0;
            row_index_q                   <= 32'b0;
            weight_block_index_q          <= 32'b0;
            result_valid_q                <= 1'b0;
            result_bits_q                 <= 32'b0;
            result_row_index_q            <= 32'b0;
            error_code_q                  <= ERROR_NONE;
            command_cycles_q              <= 64'b0;
            active_cycles_q               <= 64'b0;
            stall_cycles_q                <= 32'b0;
            activation_words_accepted_q   <= 32'b0;
            weight_blocks_accepted_q      <= 64'b0;
            rows_emitted_q                <= 32'b0;
            expected_activation_words_q   <= 64'b0;
            expected_weight_blocks_q      <= 64'b0;
            quant_input_credit_prev_q     <= 1'b0;
            accumulator_block_credit_prev_q <= 1'b0;
        end else begin
            quant_input_credit_prev_q <= quant_input_ready_w;
            accumulator_block_credit_prev_q <= accumulator_block_ready_w;

            case (state_q)
                STATE_IDLE: begin
                    if (start_fire_w) begin
                        row_count_q         <= row_count_i;
                        block_count_q       <= block_count_i;
                        quant_block_index_q <= 32'b0;
                        quant_word_index_q  <= 6'b0;
                        row_index_q         <= 32'b0;
                        weight_block_index_q <= 32'b0;
                        result_valid_q      <= 1'b0;
                        result_bits_q       <= 32'b0;
                        result_row_index_q  <= 32'b0;
                        error_code_q        <= ERROR_NONE;
                        command_cycles_q    <= 64'd1;
                        active_cycles_q     <= 64'b0;
                        stall_cycles_q      <= 32'b0;
                        activation_words_accepted_q <= 32'b0;
                        weight_blocks_accepted_q    <= 64'b0;
                        rows_emitted_q              <= 32'b0;
                        expected_activation_words_q
                            <= ({32'b0, block_count_i} << 5);
                        expected_weight_blocks_q
                            <= {32'b0, row_count_i}
                             * {32'b0, block_count_i};

                        if (row_count_i == 32'b0) begin
                            state_q          <= STATE_ERROR;
                            error_code_q     <= ERROR_ROW_COUNT_ZERO;
                            active_cycles_q  <= 64'd1;
                        end else if (block_count_i == 32'b0) begin
                            state_q          <= STATE_ERROR;
                            error_code_q     <= ERROR_BLOCK_COUNT_ZERO;
                            active_cycles_q  <= 64'd1;
                        end else if (block_count_i > MAX_BLOCKS_U32) begin
                            state_q          <= STATE_ERROR;
                            error_code_q     <= ERROR_BLOCK_COUNT_EXCEEDS;
                            active_cycles_q  <= 64'd1;
                        end else if (COMMAND_TIMEOUT_CYCLES <= 64'd1) begin
                            state_q          <= STATE_ERROR;
                            error_code_q     <= ERROR_COMMAND_TIMEOUT;
                            active_cycles_q  <= 64'd1;
                        end else begin
                            state_q <= STATE_QUANT_START;
                        end
                    end
                end

                STATE_DONE: begin
                    state_q <= STATE_IDLE;
                end

                STATE_ERROR: begin
                    // child_rst_w 在该 posedge 仍为 1，故两个 child 已完成
                    // 同步取消后才让父级重新开放 ready_o。
                    state_q <= STATE_IDLE;
                end

                default: begin
                    if ((command_cycles_q + 64'd1)
                        >= COMMAND_TIMEOUT_CYCLES) begin
                        state_q          <= STATE_ERROR;
                        error_code_q     <= ERROR_COMMAND_TIMEOUT;
                        command_cycles_q <= command_cycles_q + 64'd1;
                        active_cycles_q  <= command_cycles_q + 64'd1;
                        stall_cycles_q   <= 32'b0;
                        result_valid_q   <= 1'b0;
                        result_bits_q    <= 32'b0;
                        result_row_index_q <= 32'b0;

                        if (activation_fire_w) begin
                            activation_words_accepted_q
                                <= activation_words_accepted_q + 32'd1;
                        end
                        if (weight_fire_w) begin
                            weight_blocks_accepted_q
                                <= weight_blocks_accepted_q + 64'd1;
                        end
                        if (result_fire_w) begin
                            rows_emitted_q <= rows_emitted_q + 32'd1;
                        end
                    end else if (!progress_event_r
                                 && ((stall_cycles_q + 32'd1)
                                     >= STALL_TIMEOUT_CYCLES)) begin
                        state_q          <= STATE_ERROR;
                        error_code_q     <= stall_error_code_r;
                        command_cycles_q <= command_cycles_q + 64'd1;
                        active_cycles_q  <= command_cycles_q + 64'd1;
                        stall_cycles_q   <= 32'b0;
                        result_valid_q   <= 1'b0;
                        result_bits_q    <= 32'b0;
                        result_row_index_q <= 32'b0;
                    end else begin
                        command_cycles_q <= command_cycles_q + 64'd1;
                        if (progress_event_r) begin
                            stall_cycles_q <= 32'b0;
                        end else begin
                            stall_cycles_q <= stall_cycles_q + 32'd1;
                        end

                        case (state_q)
                            STATE_QUANT_START: begin
                                if (quant_ready_w) begin
                                    quant_word_index_q <= 6'b0;
                                    state_q            <= STATE_QUANT_LOAD32;
                                end
                            end

                            STATE_QUANT_LOAD32: begin
                                if (activation_fire_w) begin
                                    activation_words_accepted_q
                                        <= activation_words_accepted_q + 32'd1;
                                    if (quant_word_index_q == 6'd31) begin
                                        quant_word_index_q <= 6'd32;
                                        state_q            <= STATE_QUANT_WAIT;
                                    end else begin
                                        quant_word_index_q
                                            <= quant_word_index_q + 6'd1;
                                    end
                                end
                            end

                            STATE_QUANT_WAIT: begin
                                if (quant_error_w) begin
                                    state_q          <= STATE_ERROR;
                                    error_code_q     <= {4'h2,
                                                        quant_error_code_w};
                                    active_cycles_q  <= command_cycles_q
                                                      + 64'd1;
                                    result_valid_q   <= 1'b0;
                                    result_bits_q    <= 32'b0;
                                    result_row_index_q <= 32'b0;
                                end else if (quant_done_w) begin
                                    activation_block_bank_q[
                                        quant_block_index_q[
                                            BLOCK_INDEX_WIDTH-1:0]]
                                        <= quant_block_w;
                                    if (quant_block_index_q
                                        == (block_count_q - 32'd1)) begin
                                        row_index_q <= 32'b0;
                                        state_q     <= STATE_ROW_START;
                                    end else begin
                                        quant_block_index_q
                                            <= quant_block_index_q + 32'd1;
                                        state_q <= STATE_QUANT_START;
                                    end
                                end
                            end

                            STATE_ROW_START: begin
                                if (accumulator_ready_w) begin
                                    weight_block_index_q <= 32'b0;
                                    state_q <= STATE_WEIGHT_STREAM;
                                end
                            end

                            STATE_WEIGHT_STREAM: begin
                                // The accumulator may fail while processing
                                // any accepted block, before the parent has
                                // supplied the last block of the row.  Its
                                // terminal is a one-cycle pulse, so it must be
                                // consumed here as well as in ROW_WAIT.
                                if (accumulator_done_w) begin
                                    if (accumulator_error_w) begin
                                        state_q      <= STATE_ERROR;
                                        error_code_q <= {4'h3,
                                            accumulator_error_code_w};
                                        active_cycles_q
                                            <= command_cycles_q + 64'd1;
                                    end else begin
                                        // A successful child terminal before
                                        // all B weight handshakes violates the
                                        // parent/child transaction contract.
                                        state_q      <= STATE_ERROR;
                                        error_code_q <= ERROR_INTERNAL_STATE;
                                        active_cycles_q
                                            <= command_cycles_q + 64'd1;
                                    end
                                    result_valid_q     <= 1'b0;
                                    result_bits_q      <= 32'b0;
                                    result_row_index_q <= 32'b0;
                                end else if (weight_fire_w) begin
                                    weight_blocks_accepted_q
                                        <= weight_blocks_accepted_q + 64'd1;
                                    if (weight_block_index_q
                                        == (block_count_q - 32'd1)) begin
                                        state_q <= STATE_ROW_WAIT;
                                    end else begin
                                        weight_block_index_q
                                            <= weight_block_index_q + 32'd1;
                                    end
                                end
                            end

                            STATE_ROW_WAIT: begin
                                if (accumulator_done_w) begin
                                    if (accumulator_error_w) begin
                                        state_q      <= STATE_ERROR;
                                        error_code_q <= {4'h3,
                                            accumulator_error_code_w};
                                        active_cycles_q
                                            <= command_cycles_q + 64'd1;
                                        result_valid_q <= 1'b0;
                                        result_bits_q  <= 32'b0;
                                        result_row_index_q <= 32'b0;
                                    end else begin
                                        result_valid_q     <= 1'b1;
                                        result_bits_q
                                            <= accumulator_result_bits_w;
                                        result_row_index_q <= row_index_q;
                                        state_q <= STATE_RESULT_HOLD;
                                    end
                                end
                            end

                            STATE_RESULT_HOLD: begin
                                if (result_fire_w) begin
                                    result_valid_q <= 1'b0;
                                    rows_emitted_q <= rows_emitted_q + 32'd1;
                                    if (row_index_q
                                        == (row_count_q - 32'd1)) begin
                                        if (({32'b0,
                                              activation_words_accepted_q}
                                             == expected_activation_words_q)
                                            && (weight_blocks_accepted_q
                                                == expected_weight_blocks_q)
                                            && (({32'b0, rows_emitted_q}
                                                 + 64'd1)
                                                == {32'b0, row_count_q})) begin
                                            state_q         <= STATE_DONE;
                                            error_code_q    <= ERROR_NONE;
                                            active_cycles_q <= command_cycles_q
                                                             + 64'd1;
                                        end else begin
                                            state_q         <= STATE_ERROR;
                                            error_code_q    <= ERROR_INTERNAL_STATE;
                                            active_cycles_q <= command_cycles_q
                                                             + 64'd1;
                                            result_bits_q   <= 32'b0;
                                            result_row_index_q <= 32'b0;
                                        end
                                    end else begin
                                        row_index_q <= row_index_q + 32'd1;
                                        state_q     <= STATE_ROW_START;
                                    end
                                end
                            end

                            default: begin
                                state_q          <= STATE_ERROR;
                                error_code_q     <= ERROR_INTERNAL_STATE;
                                active_cycles_q  <= command_cycles_q + 64'd1;
                                result_valid_q   <= 1'b0;
                                result_bits_q    <= 32'b0;
                                result_row_index_q <= 32'b0;
                            end
                        endcase
                    end
                end
            endcase
        end
    end

endmodule

`default_nettype wire
