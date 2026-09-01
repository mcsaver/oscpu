`timescale 1ns/1ps
`default_nettype none

// Single-outstanding IEEE-754 binary32 fused multiply-add adapter.
//
// Every accepted request computes one RNE operation of the form a*b+c with a
// single final rounding.  The pinned fpu-sp fp_fma block is the numerical
// owner; this wrapper only supplies class metadata and ready/valid retention.
module TensorNpuFp32Fma (
    input  wire        clk_i,
    input  wire        rst_i,

    input  wire        req_valid_i,
    output wire        req_ready_o,
    input  wire [31:0] multiplicand_a_bits_i,
    input  wire [31:0] multiplicand_b_bits_i,
    input  wire [31:0] addend_bits_i,

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

    lzc_wire::lzc_32_in_type  lzc_a_i;
    lzc_wire::lzc_32_out_type lzc_a_o;
    lzc_wire::lzc_32_in_type  lzc_b_i;
    lzc_wire::lzc_32_out_type lzc_b_o;
    lzc_wire::lzc_32_in_type  lzc_c_i;
    lzc_wire::lzc_32_out_type lzc_c_o;
    lzc_wire::lzc_128_in_type  lzc_fma_i;
    lzc_wire::lzc_128_out_type lzc_fma_o;

    fp_wire::fp_ext_in_type  fp_ext_a_i;
    fp_wire::fp_ext_out_type fp_ext_a_o;
    fp_wire::fp_ext_in_type  fp_ext_b_i;
    fp_wire::fp_ext_out_type fp_ext_b_o;
    fp_wire::fp_ext_in_type  fp_ext_c_i;
    fp_wire::fp_ext_out_type fp_ext_c_o;
    fp_wire::fp_fma_in_type  fp_fma_i;
    fp_wire::fp_fma_out_type fp_fma_o;
    fp_wire::fp_rnd_out_type fp_rnd_o;

    assign req_ready_o = !rst_i && !inflight_q && !rsp_valid_q;
    assign req_fire_w = req_valid_i && req_ready_o;
    assign core_ready_w = fp_fma_o.ready;
    assign rsp_valid_o = rsp_valid_q;
    assign result_bits_o = result_bits_q;
    assign flags_o = flags_q;

    always @(*) begin
        fp_ext_a_i.data = multiplicand_a_bits_i;
        fp_ext_a_i.fmt = 2'b00;
        fp_ext_b_i.data = multiplicand_b_bits_i;
        fp_ext_b_i.fmt = 2'b00;
        fp_ext_c_i.data = addend_bits_i;
        fp_ext_c_i.fmt = 2'b00;

        fp_fma_i.data1 = fp_ext_a_o.result;
        fp_fma_i.data2 = fp_ext_b_o.result;
        fp_fma_i.data3 = fp_ext_c_o.result;
        fp_fma_i.class1 = fp_ext_a_o.classification;
        fp_fma_i.class2 = fp_ext_b_o.classification;
        fp_fma_i.class3 = fp_ext_c_o.classification;
        fp_fma_i.op = '0;
        fp_fma_i.fmt = 2'b00;
        fp_fma_i.rm = 3'b000;
        if (req_fire_w)
            fp_fma_i.op.fmadd = 1'b1;
    end

    lzc_32 u_lzc_a (
        .a(lzc_a_i.a), .c(lzc_a_o.c), .v(lzc_a_o.v)
    );
    lzc_32 u_lzc_b (
        .a(lzc_b_i.a), .c(lzc_b_o.c), .v(lzc_b_o.v)
    );
    lzc_32 u_lzc_c (
        .a(lzc_c_i.a), .c(lzc_c_o.c), .v(lzc_c_o.v)
    );

    fp_ext u_fp_ext_a (
        .fp_ext_i(fp_ext_a_i), .fp_ext_o(fp_ext_a_o),
        .lzc_o(lzc_a_o), .lzc_i(lzc_a_i)
    );
    fp_ext u_fp_ext_b (
        .fp_ext_i(fp_ext_b_i), .fp_ext_o(fp_ext_b_o),
        .lzc_o(lzc_b_o), .lzc_i(lzc_b_i)
    );
    fp_ext u_fp_ext_c (
        .fp_ext_i(fp_ext_c_i), .fp_ext_o(fp_ext_c_o),
        .lzc_o(lzc_c_o), .lzc_i(lzc_c_i)
    );

    lzc_128 u_lzc_fma (
        .a(lzc_fma_i.a), .c(lzc_fma_o.c), .v(lzc_fma_o.v)
    );

    fp_fma u_fp_fma (
        .reset(~rst_i),
        .clock(clk_i),
        .fp_fma_i(fp_fma_i),
        .fp_fma_o(fp_fma_o),
        .lzc_o(lzc_fma_o),
        .lzc_i(lzc_fma_i),
        .clear(1'b0)
    );

    fp_rnd u_fp_rnd (
        .fp_rnd_i(fp_fma_o.fp_rnd), .fp_rnd_o(fp_rnd_o)
    );

    always @(posedge clk_i) begin
        if (rst_i) begin
            inflight_q <= 1'b0;
            rsp_valid_q <= 1'b0;
            result_bits_q <= 32'b0;
            flags_q <= 5'b0;
        end else begin
            if (req_fire_w)
                inflight_q <= 1'b1;

            if (rsp_valid_q && rsp_ready_i)
                rsp_valid_q <= 1'b0;

            // Ignore a stale core-ready pulse unless this wrapper owns the
            // corresponding request.  A held response cannot be overwritten.
            if (core_ready_w && inflight_q) begin
                inflight_q <= 1'b0;
                rsp_valid_q <= 1'b1;
                result_bits_q <= fp_rnd_o.result;
                flags_q <= fp_rnd_o.flags;
            end
        end
    end

endmodule

`default_nettype wire
