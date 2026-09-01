`timescale 1ns/1ps
`include "tensor_npu_defs.vh"

// Functional MM2 engine for the first Tensor-NPU simulation layer.
//
// The engine deliberately implements one small, explicit contract:
//   * rvt_mm2.nn only (variant 0, no requantization);
//   * continuous TR descriptors backed by LMEM;
//   * E8 x E8 -> E32 with optional scalar bias and ReLU;
//   * one byte from X and one byte from W per MAC cycle;
//   * one 32-bit little-endian result write per output element.
//
// Descriptor fields are the frozen project ABI derived from the extension PDF.
// All addresses exposed on the LMEM ports are byte addresses.  The LMEM read
// contract returns the requested byte in rd*_data_i[7:0].
module TensorNpuMm2Engine #(
    parameter LMEM_BYTES = 4096
) (
    input  wire                         clk,
    input  wire                         rst,

    input  wire                         start_i,
    input  wire [`NPU_OP_W-1:0]         op_i,
    input  wire [4:0]                   flags_i,

    input  wire [5:0]                   dst_id_i,
    input  wire [`NPU_DESC_W-1:0]       dst_desc_i,
    input  wire [4:0]                   dst_words_valid_i,
    input  wire [5:0]                   x_id_i,
    input  wire [`NPU_DESC_W-1:0]       x_desc_i,
    input  wire [4:0]                   x_words_valid_i,
    input  wire [5:0]                   w_id_i,
    input  wire [`NPU_DESC_W-1:0]       w_desc_i,
    input  wire [4:0]                   w_words_valid_i,
    input  wire [5:0]                   bias_id_i,
    input  wire [`NPU_DESC_W-1:0]       bias_desc_i,
    input  wire [4:0]                   bias_words_valid_i,
    input  wire [5:0]                   kzp_id_i,
    input  wire [`NPU_DESC_W-1:0]       kzp_desc_i,
    input  wire [4:0]                   kzp_words_valid_i,

    output reg                          busy_o,
    output reg                          done_o,
    output reg                          error_o,
    output reg  [`NPU_ERROR_W-1:0]      error_code_o,
    output reg  [63:0]                  cycles_o,

    output reg                          rd0_valid_o,
    output reg  [31:0]                  rd0_addr_o,
    output reg  [3:0]                   rd0_bytes_o,
    input  wire [63:0]                  rd0_data_i,
    input  wire                         rd0_oob_i,

    output reg                          rd1_valid_o,
    output reg  [31:0]                  rd1_addr_o,
    output reg  [3:0]                   rd1_bytes_o,
    input  wire [63:0]                  rd1_data_i,
    input  wire                         rd1_oob_i,

    output reg                          wr_valid_o,
    output reg  [31:0]                  wr_addr_o,
    output reg  [63:0]                  wr_data_o,
    output reg  [7:0]                   wr_strb_o,
    input  wire                         wr_oob_i
);

    localparam [3:0] ST_IDLE      = 4'd0;
    localparam [3:0] ST_SETUP     = 4'd1;
    localparam [3:0] ST_READ      = 4'd2;
    localparam [3:0] ST_MAC       = 4'd3;
    localparam [3:0] ST_BIAS_RELU = 4'd4;
    localparam [3:0] ST_WRITE     = 4'd5;
    localparam [3:0] ST_NEXT      = 4'd6;
    localparam [3:0] ST_DONE      = 4'd7;
    localparam [3:0] ST_ERROR     = 4'd8;

    localparam [3:0] LAYOUT_CONTINUOUS = 4'd1;
    localparam [3:0] TEEW_E8           = 4'd0;
    localparam [3:0] TEEW_E16          = 4'd1;
    localparam [3:0] TEEW_E32          = 4'd2;
    localparam [63:0] LMEM_BYTES_U64   = LMEM_BYTES;

    reg [3:0] state_q;
    reg [`NPU_ERROR_W-1:0] error_code_q;

    reg [`NPU_OP_W-1:0] op_q;
    reg [4:0] flags_q;

    reg [5:0] dst_id_q;
    // The continuous MVP consumes descriptor base/type/shape only.  Explicit
    // stride and reserved fields remain intentionally unused until FREE_MODE.
    /* verilator lint_off UNUSEDSIGNAL */
    reg [`NPU_DESC_W-1:0] dst_desc_q;
    reg [4:0] dst_words_valid_q;
    reg [5:0] x_id_q;
    reg [`NPU_DESC_W-1:0] x_desc_q;
    reg [4:0] x_words_valid_q;
    reg [5:0] w_id_q;
    reg [`NPU_DESC_W-1:0] w_desc_q;
    reg [4:0] w_words_valid_q;
    reg [5:0] bias_id_q;
    reg [`NPU_DESC_W-1:0] bias_desc_q;
    reg [4:0] bias_words_valid_q;
    reg [5:0] kzp_id_q;
    reg [`NPU_DESC_W-1:0] kzp_desc_q;
    /* verilator lint_on UNUSEDSIGNAL */
    reg [4:0] kzp_words_valid_q;

    reg [15:0] m_count_q;
    reg [15:0] n_count_q;
    reg [15:0] k_count_q;
    reg [15:0] m_index_q;
    reg [15:0] n_index_q;
    reg [15:0] k_index_q;

    reg [7:0] x_byte_q;
    reg [7:0] w_byte_q;
    reg signed [63:0] accumulator_q;
    reg [31:0] result_q;

    // Frozen TR word-0 descriptor fields.
    wire [31:0] x_base_w   = x_desc_q[31:0];
    wire [31:0] w_base_w   = w_desc_q[31:0];
    wire [31:0] dst_base_w = dst_desc_q[31:0];
    wire [3:0] x_layout_w   = x_desc_q[55:52];
    wire [3:0] w_layout_w   = w_desc_q[55:52];
    wire [3:0] dst_layout_w = dst_desc_q[55:52];
    wire       x_signed_w   = x_desc_q[59];
    wire       w_signed_w   = w_desc_q[59];
    wire       dst_signed_w = dst_desc_q[59];
    wire [3:0] x_teew_w     = x_desc_q[63:60];
    wire [3:0] w_teew_w     = w_desc_q[63:60];
    wire [3:0] dst_teew_w   = dst_desc_q[63:60];

    // Frozen TR shape fields: (n,c,h,w).
    wire [15:0] x_shape_w_w = x_desc_q[79:64];
    wire [15:0] x_shape_h_w = x_desc_q[95:80];
    wire [15:0] x_shape_c_w = x_desc_q[111:96];
    wire [15:0] x_shape_n_w = x_desc_q[127:112];
    wire [15:0] w_shape_w_w = w_desc_q[79:64];
    wire [15:0] w_shape_h_w = w_desc_q[95:80];
    wire [15:0] w_shape_c_w = w_desc_q[111:96];
    wire [15:0] w_shape_n_w = w_desc_q[127:112];
    wire [15:0] dst_shape_w_w = dst_desc_q[79:64];
    wire [15:0] dst_shape_h_w = dst_desc_q[95:80];
    wire [15:0] dst_shape_c_w = dst_desc_q[111:96];
    wire [15:0] dst_shape_n_w = dst_desc_q[127:112];

    // CR word-0 metadata and value.  ca0 is hard-wired to zero regardless of
    // its stored descriptor payload.
    wire       bias_signed_w = bias_desc_q[59];
    wire [3:0] bias_teew_w   = bias_desc_q[63:60];
    wire [3:0] kzp_teew_w    = kzp_desc_q[63:60];

    wire signed [63:0] bias_value_w =
        (bias_id_q == 6'd0) ? 64'sd0 :
        bias_signed_w ? $signed({{32{bias_desc_q[31]}}, bias_desc_q[31:0]}) :
                        $signed({32'd0, bias_desc_q[31:0]});
    wire signed [63:0] kzp_value_w =
        (kzp_id_q == 6'd0) ? 64'sd0 :
        $signed({{48{kzp_desc_q[15]}}, kzp_desc_q[15:0]});

    wire signed [63:0] x_value_w =
        x_signed_w ? $signed({{56{x_byte_q[7]}}, x_byte_q}) :
                     $signed({56'd0, x_byte_q});
    wire signed [63:0] w_value_w =
        w_signed_w ? $signed({{56{w_byte_q[7]}}, w_byte_q}) :
                     $signed({56'd0, w_byte_q});
    wire signed [63:0] centered_w_value_w = w_value_w - kzp_value_w;
    wire signed [63:0] product_w = x_value_w * centered_w_value_w;
    wire signed [63:0] biased_sum_w = accumulator_q + bias_value_w;
    wire signed [63:0] activated_sum_w =
        (flags_q[0] && biased_sum_w < 64'sd0) ? 64'sd0 : biased_sum_w;

    wire [63:0] m_index_u64_w = {48'd0, m_index_q};
    wire [63:0] n_index_u64_w = {48'd0, n_index_q};
    wire [63:0] k_index_u64_w = {48'd0, k_index_q};
    wire [63:0] n_count_u64_w = {48'd0, n_count_q};
    wire [63:0] k_count_u64_w = {48'd0, k_count_q};

    wire [63:0] x_read_addr_w = {32'd0, x_base_w}
                              + (m_index_u64_w * k_count_u64_w)
                              + k_index_u64_w;
    wire [63:0] w_read_addr_w = {32'd0, w_base_w}
                              + (k_index_u64_w * n_count_u64_w)
                              + n_index_u64_w;
    wire [63:0] dst_write_addr_w = {32'd0, dst_base_w}
                                 + (((m_index_u64_w * n_count_u64_w)
                                 + n_index_u64_w) * 64'd4);

    wire [63:0] x_m_u64_w = {48'd0, x_shape_c_w};
    wire [63:0] x_h_u64_w = {48'd0, x_shape_h_w};
    wire [63:0] x_k_u64_w = {48'd0, x_shape_w_w};
    wire [63:0] w_k_u64_w = {48'd0, w_shape_c_w};
    wire [63:0] w_h_u64_w = {48'd0, w_shape_h_w};
    wire [63:0] w_n_u64_w = {48'd0, w_shape_w_w};
    wire [63:0] dst_m_u64_w = {48'd0, dst_shape_c_w};
    wire [63:0] dst_h_u64_w = {48'd0, dst_shape_h_w};
    wire [63:0] dst_n_u64_w = {48'd0, dst_shape_w_w};

    wire [63:0] x_size_bytes_w = x_m_u64_w * x_h_u64_w * x_k_u64_w;
    wire [63:0] w_size_bytes_w = w_k_u64_w * w_h_u64_w * w_n_u64_w;
    wire [63:0] dst_size_bytes_w =
        dst_m_u64_w * dst_h_u64_w * dst_n_u64_w * 64'd4;

    function [31:0] saturate_e32;
        input signed [63:0] value_i;
        input               signed_result_i;
        begin
            if (signed_result_i) begin
                if (value_i > 64'sh000000007fffffff)
                    saturate_e32 = 32'h7fffffff;
                else if (value_i < -64'sd2147483648)
                    saturate_e32 = 32'h80000000;
                else
                    saturate_e32 = value_i[31:0];
            end else begin
                if (value_i < 64'sd0)
                    saturate_e32 = 32'h00000000;
                else if (value_i > 64'sh00000000ffffffff)
                    saturate_e32 = 32'hffffffff;
                else
                    saturate_e32 = value_i[31:0];
            end
        end
    endfunction

    // Every request payload is purely state/index derived, so it remains
    // stable for the entire corresponding READ or WRITE state.
    always @* begin
        busy_o       = (state_q != ST_IDLE) &&
                       (state_q != ST_DONE) &&
                       (state_q != ST_ERROR);
        done_o       = (state_q == ST_DONE);
        error_o      = (state_q == ST_ERROR);
        error_code_o = (state_q == ST_ERROR) ? error_code_q : `NPU_ERR_NONE;

        rd0_valid_o  = 1'b0;
        rd0_addr_o   = 32'd0;
        rd0_bytes_o  = 4'd0;
        rd1_valid_o  = 1'b0;
        rd1_addr_o   = 32'd0;
        rd1_bytes_o  = 4'd0;
        wr_valid_o   = 1'b0;
        wr_addr_o    = 32'd0;
        wr_data_o    = 64'd0;
        wr_strb_o    = 8'd0;

        if (state_q == ST_READ) begin
            rd0_valid_o = 1'b1;
            rd0_addr_o  = x_read_addr_w[31:0];
            rd0_bytes_o = 4'd1;
            rd1_valid_o = 1'b1;
            rd1_addr_o  = w_read_addr_w[31:0];
            rd1_bytes_o = 4'd1;
        end

        if (state_q == ST_WRITE) begin
            wr_valid_o = 1'b1;
            wr_addr_o  = dst_write_addr_w[31:0];
            wr_data_o  = {32'd0, result_q};
            wr_strb_o  = 8'h0f;
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            state_q              <= ST_IDLE;
            error_code_q         <= `NPU_ERR_NONE;
            cycles_o             <= 64'd0;
            op_q                 <= {`NPU_OP_W{1'b0}};
            flags_q              <= 5'd0;
            dst_id_q             <= 6'd0;
            dst_desc_q           <= {`NPU_DESC_W{1'b0}};
            dst_words_valid_q    <= 5'd0;
            x_id_q               <= 6'd0;
            x_desc_q             <= {`NPU_DESC_W{1'b0}};
            x_words_valid_q      <= 5'd0;
            w_id_q               <= 6'd0;
            w_desc_q             <= {`NPU_DESC_W{1'b0}};
            w_words_valid_q      <= 5'd0;
            bias_id_q            <= 6'd0;
            bias_desc_q          <= {`NPU_DESC_W{1'b0}};
            bias_words_valid_q   <= 5'd0;
            kzp_id_q             <= 6'd0;
            kzp_desc_q           <= {`NPU_DESC_W{1'b0}};
            kzp_words_valid_q    <= 5'd0;
            m_count_q            <= 16'd0;
            n_count_q            <= 16'd0;
            k_count_q            <= 16'd0;
            m_index_q            <= 16'd0;
            n_index_q            <= 16'd0;
            k_index_q            <= 16'd0;
            x_byte_q             <= 8'd0;
            w_byte_q             <= 8'd0;
            accumulator_q        <= 64'sd0;
            result_q             <= 32'd0;
        end else begin
            if ((state_q != ST_IDLE) &&
                (state_q != ST_DONE) &&
                (state_q != ST_ERROR))
                cycles_o <= cycles_o + 64'd1;

            case (state_q)
                ST_IDLE: begin
                    if (start_i) begin
                        op_q               <= op_i;
                        flags_q            <= flags_i;
                        dst_id_q           <= dst_id_i;
                        dst_desc_q         <= dst_desc_i;
                        dst_words_valid_q  <= dst_words_valid_i;
                        x_id_q             <= x_id_i;
                        x_desc_q           <= x_desc_i;
                        x_words_valid_q    <= x_words_valid_i;
                        w_id_q             <= w_id_i;
                        w_desc_q           <= w_desc_i;
                        w_words_valid_q    <= w_words_valid_i;
                        bias_id_q          <= bias_id_i;
                        bias_desc_q        <= bias_desc_i;
                        bias_words_valid_q <= bias_words_valid_i;
                        kzp_id_q           <= kzp_id_i;
                        kzp_desc_q         <= kzp_desc_i;
                        kzp_words_valid_q  <= kzp_words_valid_i;
                        error_code_q       <= `NPU_ERR_NONE;
                        cycles_o           <= 64'd0;
                        state_q            <= ST_SETUP;
                    end
                end

                ST_SETUP: begin
                    // Decode-level limitations are terminal and side-effect
                    // free: no LMEM valid is asserted before every check below
                    // has passed.
                    if ((op_q != `NPU_OP_MM2_NN) ||
                        (flags_q[4:2] != 3'd0) || flags_q[1]) begin
                        error_code_q <= `NPU_ERR_UNSUPPORTED;
                        state_q      <= ST_ERROR;
                    end else if ((x_id_q < 6'd8) || (x_id_q > 6'd31) ||
                                 (w_id_q < 6'd8) || (w_id_q > 6'd31) ||
                                 (dst_id_q < 6'd8) || (dst_id_q > 6'd31) ||
                                 (bias_id_q > 6'd7) || (kzp_id_q > 6'd7)) begin
                        error_code_q <= `NPU_ERR_DESC_ID;
                        state_q      <= ST_ERROR;
                    end else if ((x_words_valid_q != 5'b01111) ||
                                 (w_words_valid_q != 5'b01111) ||
                                 (dst_words_valid_q != 5'b01111) ||
                                 (bias_words_valid_q != 5'b00001) ||
                                 (kzp_words_valid_q != 5'b00001)) begin
                        error_code_q <= `NPU_ERR_DESC_INCOMPLETE;
                        state_q      <= ST_ERROR;
                    end else if ((x_teew_w != TEEW_E8) ||
                                 (w_teew_w != TEEW_E8) ||
                                 (dst_teew_w != TEEW_E32) ||
                                 ((bias_id_q != 6'd0) &&
                                  (bias_teew_w != TEEW_E32)) ||
                                 ((kzp_id_q != 6'd0) &&
                                  ((kzp_teew_w != TEEW_E16) ||
                                   !kzp_desc_q[59]))) begin
                        error_code_q <= `NPU_ERR_DESC_TYPE;
                        state_q      <= ST_ERROR;
                    end else if ((x_layout_w != LAYOUT_CONTINUOUS) ||
                                 (w_layout_w != LAYOUT_CONTINUOUS) ||
                                 (dst_layout_w != LAYOUT_CONTINUOUS)) begin
                        error_code_q <= `NPU_ERR_UNSUPPORTED;
                        state_q      <= ST_ERROR;
                    end else if ((x_shape_n_w != 16'd1) ||
                                 (x_shape_h_w != 16'd1) ||
                                 (w_shape_n_w != 16'd1) ||
                                 (w_shape_h_w != 16'd1) ||
                                 (dst_shape_n_w != 16'd1) ||
                                 (dst_shape_h_w != 16'd1) ||
                                 (x_shape_c_w == 16'd0) ||
                                 (x_shape_w_w == 16'd0) ||
                                 (w_shape_w_w == 16'd0) ||
                                 (w_shape_c_w != x_shape_w_w) ||
                                 (dst_shape_c_w != x_shape_c_w) ||
                                 (dst_shape_w_w != w_shape_w_w)) begin
                        error_code_q <= `NPU_ERR_SHAPE;
                        state_q      <= ST_ERROR;
                    end else if (({32'd0, x_base_w} + x_size_bytes_w >
                                  LMEM_BYTES_U64) ||
                                 ({32'd0, w_base_w} + w_size_bytes_w >
                                  LMEM_BYTES_U64) ||
                                 ({32'd0, dst_base_w} + dst_size_bytes_w >
                                  LMEM_BYTES_U64)) begin
                        error_code_q <= `NPU_ERR_LMEM_BOUNDS;
                        state_q      <= ST_ERROR;
                    end else begin
                        m_count_q     <= x_shape_c_w;
                        n_count_q     <= w_shape_w_w;
                        k_count_q     <= x_shape_w_w;
                        m_index_q     <= 16'd0;
                        n_index_q     <= 16'd0;
                        k_index_q     <= 16'd0;
                        accumulator_q <= 64'sd0;
                        state_q       <= ST_READ;
                    end
                end

                ST_READ: begin
                    if (rd0_oob_i || rd1_oob_i ||
                        (x_read_addr_w[63:32] != 32'd0) ||
                        (w_read_addr_w[63:32] != 32'd0)) begin
                        error_code_q <= `NPU_ERR_LMEM_BOUNDS;
                        state_q      <= ST_ERROR;
                    end else if ((rd0_data_i[63:8] != 56'd0) ||
                                 (rd1_data_i[63:8] != 56'd0)) begin
                        error_code_q <= `NPU_ERR_INTERNAL_STATE;
                        state_q      <= ST_ERROR;
                    end else begin
                        x_byte_q <= rd0_data_i[7:0];
                        w_byte_q <= rd1_data_i[7:0];
                        state_q  <= ST_MAC;
                    end
                end

                ST_MAC: begin
                    accumulator_q <= accumulator_q + product_w;
                    if ((k_index_q + 16'd1) == k_count_q) begin
                        state_q <= ST_BIAS_RELU;
                    end else begin
                        k_index_q <= k_index_q + 16'd1;
                        state_q   <= ST_READ;
                    end
                end

                ST_BIAS_RELU: begin
                    result_q <= saturate_e32(activated_sum_w, dst_signed_w);
                    state_q  <= ST_WRITE;
                end

                ST_WRITE: begin
                    if (wr_oob_i || (dst_write_addr_w[63:32] != 32'd0)) begin
                        error_code_q <= `NPU_ERR_LMEM_BOUNDS;
                        state_q      <= ST_ERROR;
                    end else begin
                        state_q <= ST_NEXT;
                    end
                end

                ST_NEXT: begin
                    accumulator_q <= 64'sd0;
                    k_index_q     <= 16'd0;
                    if ((n_index_q + 16'd1) < n_count_q) begin
                        n_index_q <= n_index_q + 16'd1;
                        state_q   <= ST_READ;
                    end else if ((m_index_q + 16'd1) < m_count_q) begin
                        n_index_q <= 16'd0;
                        m_index_q <= m_index_q + 16'd1;
                        state_q   <= ST_READ;
                    end else begin
                        state_q <= ST_DONE;
                    end
                end

                ST_DONE: begin
                    state_q <= ST_IDLE;
                end

                ST_ERROR: begin
                    state_q <= ST_IDLE;
                end

                default: begin
                    error_code_q <= `NPU_ERR_INTERNAL_STATE;
                    state_q      <= ST_ERROR;
                end
            endcase
        end
    end

`ifdef NPU_ASSERT
    // Simulation-only protocol guards.  Fast mode omits NPU_ASSERT entirely.
    always @(posedge clk) begin
        if (!rst && (state_q == ST_READ)) begin
            if (!rd0_valid_o || !rd1_valid_o)
                $error("MM2 READ state lost an LMEM read valid");
            if ((rd0_bytes_o != 4'd1) || (rd1_bytes_o != 4'd1))
                $error("MM2 READ state requested a non-byte operand");
        end
        if (!rst && (state_q == ST_WRITE)) begin
            if (!wr_valid_o || (wr_strb_o != 8'h0f))
                $error("MM2 WRITE state lost its 32-bit LMEM write");
        end
        if (!rst && done_o && error_o)
            $error("MM2 done and error terminals overlap");
    end
`endif

endmodule
