`timescale 1ns/1ps

// SPDX-License-Identifier: MIT
//
// binary32 到 signed int32 的 RISC-V RMM 组合转换器。
// fp_cvt 固定 RISCV=1：NaN/+overflow 饱和为 INT_MAX，负 overflow 饱和为
// INT_MIN，并以 flags_o[4]/flags_o[0] 分别报告 NV/NX。
// q8_range_o 只允许已完成且无 NV 的 [-127, 127] 结果。
//
// 拓扑：fp_ext/classification -> fp_cvt(RISCV=1, signed, RMM) ->
// signed Q8 range compare。无寄存器、FSM 或 handshake。
module TensorNpuFp32ToInt32Rmm (
    input  wire [31:0] fp32_bits_i,
    output wire [31:0] int32_bits_o,
    output wire [4:0]  flags_o,
    output wire        q8_range_o
);

    lzc_wire::lzc_32_in_type  lzc_ext_i;
    lzc_wire::lzc_32_out_type lzc_ext_o;
    lzc_wire::lzc_32_in_type  lzc_cvt_i;
    lzc_wire::lzc_32_out_type lzc_cvt_o;

    fp_wire::fp_ext_in_type       fp_ext_i;
    fp_wire::fp_ext_out_type      fp_ext_o;
    fp_wire::fp_cvt_f2i_in_type   fp_cvt_f2i_i;
    fp_wire::fp_cvt_f2i_out_type  fp_cvt_f2i_o;
    fp_wire::fp_cvt_i2f_in_type   fp_cvt_i2f_i;
    fp_wire::fp_cvt_i2f_out_type  fp_cvt_i2f_o_unused;

    assign int32_bits_o = fp_cvt_f2i_o.result;
    assign flags_o      = fp_cvt_f2i_o.flags;
    assign q8_range_o   = !fp_cvt_f2i_o.flags[4]
                        && ($signed(fp_cvt_f2i_o.result) >= -32'sd127)
                        && ($signed(fp_cvt_f2i_o.result) <=  32'sd127);

    always @(*) begin
        fp_ext_i.data = fp32_bits_i;
        fp_ext_i.fmt  = 2'b00;

        fp_cvt_f2i_i.data           = fp_ext_o.result;
        fp_cvt_f2i_i.op             = '0;
        fp_cvt_f2i_i.op.fcvt_f2i    = 1'b1;
        fp_cvt_f2i_i.op.fcvt_op     = 2'b00;
        fp_cvt_f2i_i.rm             = 3'b100;
        fp_cvt_f2i_i.classification = fp_ext_o.classification;

        // fp_cvt 的 i2f 组合端口与 f2i 独立；固定零值并给它独立 LZC，
        // 避免与 fp_ext 的 LZC 产生多驱动或隐式资源共享。
        fp_cvt_i2f_i.data = 32'b0;
        fp_cvt_i2f_i.op   = '0;
        fp_cvt_i2f_i.fmt  = 2'b00;
        fp_cvt_i2f_i.rm   = 3'b000;
    end

    lzc_32 u_lzc_ext (
        .a (lzc_ext_i.a),
        .c (lzc_ext_o.c),
        .v (lzc_ext_o.v)
    );

    fp_ext u_fp_ext (
        .fp_ext_i (fp_ext_i),
        .fp_ext_o (fp_ext_o),
        .lzc_o    (lzc_ext_o),
        .lzc_i    (lzc_ext_i)
    );

    lzc_32 u_lzc_cvt (
        .a (lzc_cvt_i.a),
        .c (lzc_cvt_o.c),
        .v (lzc_cvt_o.v)
    );

    fp_cvt #(
        .RISCV (1)
    ) u_fp_cvt (
        .fp_cvt_f2i_i (fp_cvt_f2i_i),
        .fp_cvt_f2i_o (fp_cvt_f2i_o),
        .fp_cvt_i2f_i (fp_cvt_i2f_i),
        .fp_cvt_i2f_o (fp_cvt_i2f_o_unused),
        .lzc_o        (lzc_cvt_o),
        .lzc_i        (lzc_cvt_i)
    );

endmodule
