`timescale 1ns/1ps

// SPDX-License-Identifier: MIT
//
// Single-outstanding FP32 add/multiply adapter for the pinned fpu-sp core.
// The upstream core is SystemVerilog and exposes packed package types.  This
// .v wrapper deliberately uses fp_wire::/lzc_wire:: qualified types as the one
// SystemVerilog package-adapter exception; its own control logic remains plain
// always @(*) / always @(posedge clk_i) RTL.
//
// Protocol invariants:
//   * an upstream operation bit is asserted for exactly a req_fire cycle;
//   * at most one operation is resident in fp_fma;
//   * a response is captured only for that resident operation;
//   * response payload is held stable until rsp_ready_i consumes it.
module TensorNpuFp32AddMul (
    input  wire        clk_i,
    input  wire        rst_i,

    input  wire        req_valid_i,
    output wire        req_ready_o,
    input  wire        op_mul_i,
    input  wire [31:0] lhs_bits_i,
    input  wire [31:0] rhs_bits_i,

    output wire        rsp_valid_o,
    input  wire        rsp_ready_i,
    output wire [31:0] result_bits_o,
    output wire [4:0]  flags_o
);

    reg        inflight_q;
    reg        rsp_valid_q;
    reg [31:0] result_bits_q;
    reg [4:0]  flags_q;

    wire req_fire_w;
    wire core_ready_w;

    lzc_wire::lzc_32_in_type  lzc_lhs_i;
    lzc_wire::lzc_32_out_type lzc_lhs_o;
    lzc_wire::lzc_32_in_type  lzc_rhs_i;
    lzc_wire::lzc_32_out_type lzc_rhs_o;
    lzc_wire::lzc_32_in_type  lzc_zero_i;
    lzc_wire::lzc_32_out_type lzc_zero_o;
    lzc_wire::lzc_128_in_type  lzc_fma_i;
    lzc_wire::lzc_128_out_type lzc_fma_o;

    fp_wire::fp_ext_in_type  fp_ext_lhs_i;
    fp_wire::fp_ext_out_type fp_ext_lhs_o;
    fp_wire::fp_ext_in_type  fp_ext_rhs_i;
    fp_wire::fp_ext_out_type fp_ext_rhs_o;
    fp_wire::fp_ext_in_type  fp_ext_zero_i;
    fp_wire::fp_ext_out_type fp_ext_zero_o;
    fp_wire::fp_fma_in_type  fp_fma_i;
    fp_wire::fp_fma_out_type fp_fma_o;
    fp_wire::fp_rnd_out_type fp_rnd_o;

    // Reset is a protocol quiescence window: no request handshake is exposed
    // until both this adapter and the active-low upstream pipeline are live.
    assign req_ready_o   = !rst_i && !inflight_q && !rsp_valid_q;
    assign req_fire_w    = req_valid_i && req_ready_o;
    assign core_ready_w  = fp_fma_o.ready;
    assign rsp_valid_o   = rsp_valid_q;
    assign result_bits_o = result_bits_q;
    assign flags_o       = flags_q;

    // Feed all three operands through fp_ext.  fp_fma internally rewrites its
    // third operand for fadd/fmul, but classifying +0 here keeps its input
    // contract complete and avoids an unclassified special-value operand.
    always @(*) begin
        fp_ext_lhs_i.data  = lhs_bits_i;
        fp_ext_lhs_i.fmt   = 2'b00;
        fp_ext_rhs_i.data  = rhs_bits_i;
        fp_ext_rhs_i.fmt   = 2'b00;
        fp_ext_zero_i.data = 32'h00000000;
        fp_ext_zero_i.fmt  = 2'b00;

        fp_fma_i.data1  = fp_ext_lhs_o.result;
        fp_fma_i.data2  = fp_ext_rhs_o.result;
        fp_fma_i.data3  = fp_ext_zero_o.result;
        fp_fma_i.class1 = fp_ext_lhs_o.classification;
        fp_fma_i.class2 = fp_ext_rhs_o.classification;
        fp_fma_i.class3 = fp_ext_zero_o.classification;
        fp_fma_i.op     = '0;
        fp_fma_i.fmt    = 2'b00;
        fp_fma_i.rm     = 3'b000;

        if (req_fire_w) begin
            if (op_mul_i) begin
                fp_fma_i.op.fmul = 1'b1;
            end else begin
                fp_fma_i.op.fadd = 1'b1;
            end
        end
    end

    lzc_32 u_lzc_lhs (
        .a (lzc_lhs_i.a),
        .c (lzc_lhs_o.c),
        .v (lzc_lhs_o.v)
    );

    lzc_32 u_lzc_rhs (
        .a (lzc_rhs_i.a),
        .c (lzc_rhs_o.c),
        .v (lzc_rhs_o.v)
    );

    lzc_32 u_lzc_zero (
        .a (lzc_zero_i.a),
        .c (lzc_zero_o.c),
        .v (lzc_zero_o.v)
    );

    fp_ext u_fp_ext_lhs (
        .fp_ext_i (fp_ext_lhs_i),
        .fp_ext_o (fp_ext_lhs_o),
        .lzc_o    (lzc_lhs_o),
        .lzc_i    (lzc_lhs_i)
    );

    fp_ext u_fp_ext_rhs (
        .fp_ext_i (fp_ext_rhs_i),
        .fp_ext_o (fp_ext_rhs_o),
        .lzc_o    (lzc_rhs_o),
        .lzc_i    (lzc_rhs_i)
    );

    fp_ext u_fp_ext_zero (
        .fp_ext_i (fp_ext_zero_i),
        .fp_ext_o (fp_ext_zero_o),
        .lzc_o    (lzc_zero_o),
        .lzc_i    (lzc_zero_i)
    );

    lzc_128 u_lzc_fma (
        .a (lzc_fma_i.a),
        .c (lzc_fma_o.c),
        .v (lzc_fma_o.v)
    );

    fp_fma u_fp_fma (
        .reset    (~rst_i),
        .clock    (clk_i),
        .fp_fma_i (fp_fma_i),
        .fp_fma_o (fp_fma_o),
        .lzc_o    (lzc_fma_o),
        .lzc_i    (lzc_fma_i),
        .clear    (1'b0)
    );

    fp_rnd u_fp_rnd (
        .fp_rnd_i (fp_fma_o.fp_rnd),
        .fp_rnd_o (fp_rnd_o)
    );

    always @(posedge clk_i) begin
        if (rst_i) begin
            inflight_q    <= 1'b0;
            rsp_valid_q   <= 1'b0;
            result_bits_q <= 32'b0;
            flags_q       <= 5'b0;
        end else begin
            if (req_fire_w) begin
                inflight_q <= 1'b1;
            end

            if (rsp_valid_q && rsp_ready_i) begin
                rsp_valid_q <= 1'b0;
            end

            // fp_fma_o.ready without a matching resident request is ignored.
            // In particular, it cannot overwrite a held response payload.
            if (core_ready_w && inflight_q) begin
                inflight_q    <= 1'b0;
                rsp_valid_q   <= 1'b1;
                result_bits_q <= fp_rnd_o.result;
                flags_q       <= fp_rnd_o.flags;
            end
        end
    end

endmodule
