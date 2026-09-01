`timescale 1ns/1ps

// Raw-bit oracle for the full-width signed-int32 to IEEE binary32 converter.
// No host floating-point, DPI, real/shortreal, assertion mode, or waveform is
// needed to determine the expected result.
module tb_int32_to_fp32;

    reg  signed [31:0] int_i;
    wire        [31:0] fp32_bits_o;
    wire               inexact_o;
    integer            checks;

    TensorNpuInt32ToFp32 dut (
        .int_i       (int_i),
        .fp32_bits_o (fp32_bits_o),
        .inexact_o   (inexact_o)
    );

    task automatic check_case;
        input signed [31:0] value;
        input        [31:0] expected_bits;
        input               expected_inexact;
        begin
            int_i = value;
            #1;
            if ((fp32_bits_o !== expected_bits)
                    || (inexact_o !== expected_inexact)) begin
                $display("[NPU-I32-FP32][FAIL] int=0x%08x got=0x%08x inexact=%0d expected=0x%08x inexact=%0d",
                         value, fp32_bits_o, inexact_o,
                         expected_bits, expected_inexact);
                $fatal(1);
            end
            checks = checks + 1;
        end
    endtask

    initial begin
        int_i = 32'sd0;
        checks = 0;

        check_case( 32'sd0,          32'h00000000, 1'b0);
        check_case( 32'sd1,          32'h3f800000, 1'b0);
        check_case(-32'sd1,          32'hbf800000, 1'b0);

        // Frozen Q8_0 block-dot reference values and full 32-lane bound.
        check_case( 32'sd44421,      32'h472d8500, 1'b0);
        check_case(-32'sd191,        32'hc33f0000, 1'b0);
        check_case( 32'sd524288,     32'h49000000, 1'b0);
        check_case(-32'sd524288,     32'hc9000000, 1'b0);

        // Last exact integer below 2^24 and 2^24 itself.
        check_case( 32'sd16777215,   32'h4b7fffff, 1'b0);
        check_case( 32'sd16777216,   32'h4b800000, 1'b0);

        // Halfway cases: even retained LSB rounds down; odd rounds up.
        check_case( 32'sd16777217,   32'h4b800000, 1'b1);
        check_case( 32'sd16777219,   32'h4b800002, 1'b1);
        check_case(-32'sd16777217,   32'hcb800000, 1'b1);
        check_case(-32'sd16777219,   32'hcb800002, 1'b1);

        // Full signed-int32 endpoints exercise rounding carry and INT_MIN abs.
        check_case( 32'sh7fffffff,   32'h4f000000, 1'b1);
        check_case( 32'sh80000000,   32'hcf000000, 1'b0);

        $display("[NPU-I32-FP32][PASS] checks=%0d full_int32_rne=1 q8_dot_range_exact=1",
                 checks);
        $finish;
    end

endmodule
