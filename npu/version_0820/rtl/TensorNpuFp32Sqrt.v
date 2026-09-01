`timescale 1ns/1ps
`default_nettype none

// SPDX-License-Identifier: MIT
//
// TensorNpuFp32Sqrt
//
// Project-owned single-outstanding wrapper around the pinned fpu-sp
// fp_fdiv #(.PERFORMANCE(0)) FSQRT path.
//
// Protocol/FSM:
//   IDLE accepts req_valid_i && req_ready_o and pulses op.fsqrt for one cycle.
//   CORE_BUSY owns the resident third-party operation until fp_fdiv_o.ready.
//   RESPONSE holds raw result/flags until rsp_ready_i consumes them.
//
// Invariants:
//   * busy and held-response cycles reject every additional request;
//   * only a CORE_BUSY completion can create a wrapper response;
//   * result_bits_q/flags_q remain stable for the full response backpressure;
//   * synchronous rst_i clears both wrapper epoch and the active-low core FSM;
//   * third-party clear is tied low because it is not a transaction cancel.
//
// Datapath/topology:
//   raw FP32 operand -> fp_ext/lzc_32 pseudo extension and classification ->
//   fp_fdiv PERFORMANCE=0 fsqrt iteration -> fp_rnd -> held response register.
//   data2/class2 and the unused PERFORMANCE=0 MAC return are tied to zero.
module TensorNpuFp32Sqrt (
    input  wire        clk_i,
    input  wire        rst_i,

    input  wire        req_valid_i,
    output wire        req_ready_o,
    input  wire [31:0] operand_bits_i,
    input  wire [2:0]  rounding_mode_i,

    output wire        rsp_valid_o,
    input  wire        rsp_ready_i,
    output wire [31:0] result_bits_o,
    output wire [4:0]  flags_o
);

    localparam [1:0] STATE_IDLE      = 2'b00;
    localparam [1:0] STATE_CORE_BUSY = 2'b01;
    localparam [1:0] STATE_RESPONSE  = 2'b10;

    reg [1:0]  state_q;
    reg [31:0] result_bits_q;
    reg [4:0]  flags_q;

    wire req_fire_w;
    wire core_ready_w;

    // fp_ext and lzc_32 deliberately form the pinned upstream normalization
    // feedback topology.  Verilator otherwise reports that topology as a
    // false-positive UNOPTFLAT loop at the packed lzc output declaration.
    /* verilator lint_off UNOPTFLAT */
    lzc_wire::lzc_32_in_type  lzc_operand_i;
    lzc_wire::lzc_32_out_type lzc_operand_o;
    /* verilator lint_on UNOPTFLAT */

    fp_wire::fp_ext_in_type   fp_ext_operand_i;
    fp_wire::fp_ext_out_type  fp_ext_operand_o;
    fp_wire::fp_fdiv_in_type  fp_fdiv_i;
    fp_wire::fp_fdiv_out_type fp_fdiv_o;
    fp_wire::fp_mac_out_type  fp_mac_o_tieoff;

    // PERFORMANCE=0 drives this port to zeros and never consumes the value.
    /* verilator lint_off UNUSEDSIGNAL */
    fp_wire::fp_mac_in_type   fp_mac_i_unused;
    /* verilator lint_on UNUSEDSIGNAL */

    fp_wire::fp_rnd_out_type  fp_rnd_o;

    assign req_ready_o   = !rst_i && (state_q == STATE_IDLE);
    assign req_fire_w    = req_valid_i && req_ready_o;
    assign core_ready_w  = fp_fdiv_o.ready;
    assign rsp_valid_o   = !rst_i && (state_q == STATE_RESPONSE);
    assign result_bits_o = result_bits_q;
    assign flags_o       = flags_q;

    // Launch mux and enable are explicit: only req_fire_w selects fsqrt.  The
    // third-party core captures operand/class/rm into its resident fixed-point
    // state at that launch edge, so later busy inputs cannot overwrite it.
    always @(*) begin
        fp_mac_o_tieoff.d = 52'b0;

        fp_ext_operand_i.data = operand_bits_i;
        fp_ext_operand_i.fmt  = 2'b00;

        fp_fdiv_i.data1  = fp_ext_operand_o.result;
        fp_fdiv_i.data2  = 33'b0;
        fp_fdiv_i.class1 = fp_ext_operand_o.classification;
        fp_fdiv_i.class2 = 10'b0;
        fp_fdiv_i.op     = fp_wire::init_fp_operation;
        fp_fdiv_i.fmt    = 2'b00;
        fp_fdiv_i.rm     = rounding_mode_i;
        if (req_fire_w) begin
            fp_fdiv_i.op.fsqrt = 1'b1;
        end
    end

    lzc_32 u_lzc_operand (
        .a (lzc_operand_i.a),
        .c (lzc_operand_o.c),
        .v (lzc_operand_o.v)
    );

    fp_ext u_fp_ext_operand (
        .fp_ext_i (fp_ext_operand_i),
        .fp_ext_o (fp_ext_operand_o),
        .lzc_o    (lzc_operand_o),
        .lzc_i    (lzc_operand_i)
    );

    fp_fdiv #(
        .PERFORMANCE (0)
    ) u_fp_fdiv (
        .reset      (~rst_i),
        .clock      (clk_i),
        .fp_fdiv_i  (fp_fdiv_i),
        .fp_fdiv_o  (fp_fdiv_o),
        .fp_mac_o   (fp_mac_o_tieoff),
        .fp_mac_i   (fp_mac_i_unused),
        .clear      (1'b0)
    );

    fp_rnd u_fp_rnd (
        .fp_rnd_i (fp_fdiv_o.fp_rnd),
        .fp_rnd_o (fp_rnd_o)
    );

    // Synchronous priority: reset > resident completion > response consume.
    // A response consume deliberately returns to IDLE with one bubble; it does
    // not combine consume and relaunch on the same edge.
    always @(posedge clk_i) begin
        if (rst_i) begin
            state_q       <= STATE_IDLE;
            result_bits_q <= 32'b0;
            flags_q       <= 5'b0;
        end else begin
            case (state_q)
                STATE_IDLE: begin
                    if (req_fire_w) begin
                        state_q <= STATE_CORE_BUSY;
                    end
                end

                STATE_CORE_BUSY: begin
                    if (core_ready_w) begin
                        state_q       <= STATE_RESPONSE;
                        result_bits_q <= fp_rnd_o.result;
                        flags_q       <= fp_rnd_o.flags;
                    end
                end

                STATE_RESPONSE: begin
                    if (rsp_ready_i) begin
                        state_q <= STATE_IDLE;
                    end
                end

                default: begin
                    // An illegal local state never publishes a stale response.
                    state_q       <= STATE_IDLE;
                    result_bits_q <= 32'b0;
                    flags_q       <= 5'b0;
                end
            endcase
        end
    end

endmodule

`default_nettype wire
