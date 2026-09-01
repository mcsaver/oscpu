`timescale 1ns/1ps

// One-block Q8_0 signed dot-product primitive.
//
// A packed block is exactly 34 bytes with byte 0 in bits [7:0]:
//   * bytes 0..1: little-endian fp16 scale raw bits;
//   * bytes 2..33: 32 signed int8 quants.
//
// This primitive deliberately performs no floating-point arithmetic.  It
// returns both scale bit patterns unchanged and only accumulates the int8
// products into a signed int32 result.
module TensorNpuQ8DotEngine #(
    parameter integer MAC_LANES = 8
) (
    input  wire                clk_i,
    input  wire                rst_i,

    input  wire                start_i,
    output wire                ready_o,
    output reg                 busy_o,
    input  wire [271:0]        x_block_i,
    input  wire [271:0]        y_block_i,

    output reg                 done_o,
    output reg signed [31:0]   sum_o,
    output reg [15:0]          x_scale_o,
    output reg [15:0]          y_scale_o
);

    // Invalid lane counts elaborate a small safe datapath and terminate the
    // simulation explicitly.  Every value from 1 through 32, including
    // non-powers of two, uses ceil(32/MAC_LANES) beats plus a final lane mask.
    localparam integer EFFECTIVE_MAC_LANES =
        ((MAC_LANES >= 1) && (MAC_LANES <= 32)) ? MAC_LANES : 1;
    localparam integer MAC_BEATS =
        (32 + EFFECTIVE_MAC_LANES - 1) / EFFECTIVE_MAC_LANES;
    localparam integer LAST_BEAT = MAC_BEATS - 1;

    generate
        if ((MAC_LANES < 1) || (MAC_LANES > 32)) begin : gen_invalid_mac_lanes
            initial begin
                $fatal(1, "TensorNpuQ8DotEngine MAC_LANES must be in [1,32]");
            end
        end
    endgenerate

    reg [271:0] x_block_q;
    reg [271:0] y_block_q;
    reg [31:0] quant_base_q;
    reg [31:0] beat_q;
    reg signed [31:0] accumulator_q;

    integer lane_index;
    integer quant_index;
    reg signed [7:0] x_quant_w;
    reg signed [7:0] y_quant_w;
    reg signed [15:0] product_w;
    reg signed [31:0] beat_sum_w;

    assign ready_o = ~busy_o;

    // The constant-bound loop elaborates EFFECTIVE_MAC_LANES parallel 8x8
    // signed multipliers followed by a 32-bit beat adder chain.  quant_base_q
    // selects one group of quants; the range guard masks unused lanes in the
    // last beat for non-power-of-two MAC_LANES values.
    always @(*) begin
        quant_index = 0;
        x_quant_w   = 8'sd0;
        y_quant_w   = 8'sd0;
        product_w   = 16'sd0;
        beat_sum_w  = 32'sd0;

        for (lane_index = 0;
             lane_index < EFFECTIVE_MAC_LANES;
             lane_index = lane_index + 1) begin
            quant_index = quant_base_q + lane_index;
            if (quant_index < 32) begin
                x_quant_w = $signed(
                    x_block_q[16 + (quant_index * 8) +: 8]);
                y_quant_w = $signed(
                    y_block_q[16 + (quant_index * 8) +: 8]);
                product_w = x_quant_w * y_quant_w;
                beat_sum_w = beat_sum_w
                           + $signed({{16{product_w[15]}}, product_w});
            end
        end
    end

    // reset > active transaction > idle launch.  The active branch never
    // samples start_i or either input block, so a start pulse while busy cannot
    // corrupt the accepted transaction.
    always @(posedge clk_i) begin
        if (rst_i) begin
            busy_o       <= 1'b0;
            done_o       <= 1'b0;
            sum_o        <= 32'sd0;
            x_scale_o    <= 16'd0;
            y_scale_o    <= 16'd0;
            x_block_q    <= 272'd0;
            y_block_q    <= 272'd0;
            quant_base_q <= 32'd0;
            beat_q       <= 32'd0;
            accumulator_q <= 32'sd0;
        end else begin
            done_o <= 1'b0;

            if (busy_o) begin
                if (beat_q == LAST_BEAT) begin
                    sum_o         <= accumulator_q + beat_sum_w;
                    accumulator_q <= accumulator_q + beat_sum_w;
                    busy_o        <= 1'b0;
                    done_o        <= 1'b1;
                end else begin
                    accumulator_q <= accumulator_q + beat_sum_w;
                    quant_base_q  <= quant_base_q + EFFECTIVE_MAC_LANES;
                    beat_q        <= beat_q + 32'd1;
                end
            end else if (start_i) begin
                busy_o        <= 1'b1;
                x_block_q     <= x_block_i;
                y_block_q     <= y_block_i;
                x_scale_o     <= x_block_i[15:0];
                y_scale_o     <= y_block_i[15:0];
                quant_base_q  <= 32'd0;
                beat_q        <= 32'd0;
                accumulator_q <= 32'sd0;
            end
        end
    end

endmodule
