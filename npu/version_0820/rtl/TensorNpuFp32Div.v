`timescale 1ns/1ps

// SPDX-License-Identifier: MIT
//
// 单在途 IEEE-754 binary32 RNE 除法适配器。
//
// 协议/FSM：
//   IDLE 在 req_valid_i && req_ready_o 时发出一个周期的 fdiv 请求；
//   CORE_BUSY 只等待该 resident transaction 的 core ready；
//   RESPONSE 保持 raw result/flags，直到 rsp_ready_i 消费。
//
// 不变量：
//   * busy 或 response-held 周期不接受第二个请求；
//   * core ready 只有在 CORE_BUSY 才能产生响应；
//   * RESPONSE 下 payload 在消费前保持稳定；
//   * rst_i 同时清 wrapper 与第三方低有效 reset 流水状态。
//
// 数据通路：lhs/rhs -> fp_ext/lzc -> fp_fdiv(PERFORMANCE=0) -> fp_rnd
// -> response registers。固定点 divider 是唯一共享运算资源；迭代状态显式
// 保留在 fp_fdiv 内部，wrapper 不把 divider/FSM 封装进 function。
module TensorNpuFp32Div (
    input  wire        clk_i,
    input  wire        rst_i,

    input  wire        req_valid_i,
    output wire        req_ready_o,
    input  wire [31:0] lhs_bits_i,
    input  wire [31:0] rhs_bits_i,

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

    lzc_wire::lzc_32_in_type  lzc_lhs_i;
    lzc_wire::lzc_32_out_type lzc_lhs_o;
    lzc_wire::lzc_32_in_type  lzc_rhs_i;
    lzc_wire::lzc_32_out_type lzc_rhs_o;

    fp_wire::fp_ext_in_type   fp_ext_lhs_i;
    fp_wire::fp_ext_out_type  fp_ext_lhs_o;
    fp_wire::fp_ext_in_type   fp_ext_rhs_i;
    fp_wire::fp_ext_out_type  fp_ext_rhs_o;
    fp_wire::fp_fdiv_in_type  fp_fdiv_i;
    fp_wire::fp_fdiv_out_type fp_fdiv_o;
    fp_wire::fp_mac_in_type   fp_mac_i_unused;
    fp_wire::fp_mac_out_type  fp_mac_o_tieoff;
    fp_wire::fp_rnd_out_type  fp_rnd_o;

    assign req_ready_o   = !rst_i && (state_q == STATE_IDLE);
    assign req_fire_w    = req_valid_i && req_ready_o;
    assign core_ready_w  = fp_fdiv_o.ready;
    assign rsp_valid_o   = (state_q == STATE_RESPONSE);
    assign result_bits_o = result_bits_q;
    assign flags_o       = flags_q;

    // PERFORMANCE=0 不使用 fp_mac 数据返回；显式 tie-off 避免未知值进入端口。
    always @(*) begin
        fp_mac_o_tieoff.d = 52'b0;

        fp_ext_lhs_i.data = lhs_bits_i;
        fp_ext_lhs_i.fmt  = 2'b00;
        fp_ext_rhs_i.data = rhs_bits_i;
        fp_ext_rhs_i.fmt  = 2'b00;

        fp_fdiv_i.data1  = fp_ext_lhs_o.result;
        fp_fdiv_i.data2  = fp_ext_rhs_o.result;
        fp_fdiv_i.class1 = fp_ext_lhs_o.classification;
        fp_fdiv_i.class2 = fp_ext_rhs_o.classification;
        fp_fdiv_i.op     = '0;
        fp_fdiv_i.fmt    = 2'b00;
        fp_fdiv_i.rm     = 3'b000;
        if (req_fire_w) begin
            fp_fdiv_i.op.fdiv = 1'b1;
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

    // reset > core completion > response consume/request launch。
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
                    // 非法编码 fail-closed 回到空闲，且不发布响应。
                    state_q       <= STATE_IDLE;
                    result_bits_q <= 32'b0;
                    flags_q       <= 5'b0;
                end
            endcase
        end
    end

endmodule
