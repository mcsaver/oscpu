`timescale 1ns/1ps
`default_nettype none

// binary32->binary16 的 raw-bit oracle；无 host 浮点或 DPI。
module tb_fp32_to_fp16;

    reg  [31:0] fp32_bits_i;
    wire [15:0] fp16_bits_o;
    wire        finite_o;
    wire        overflow_o;
    wire        inexact_o;

    integer checks;
    integer failures;

    TensorNpuFp32ToFp16 dut (
        .fp32_bits_i (fp32_bits_i),
        .fp16_bits_o (fp16_bits_o),
        .finite_o    (finite_o),
        .overflow_o  (overflow_o),
        .inexact_o   (inexact_o)
    );

    task automatic check_case(
        input string       case_name,
        input logic [31:0] input_bits,
        input logic [15:0] expected_bits,
        input logic        expected_finite,
        input logic        expected_overflow,
        input logic        expected_inexact
    );
        begin
            fp32_bits_i = input_bits;
            #1;
            checks = checks + 1;
            if ((fp16_bits_o !== expected_bits)
                    || (finite_o !== expected_finite)
                    || (overflow_o !== expected_overflow)
                    || (inexact_o !== expected_inexact)) begin
                failures = failures + 1;
                $display("[NPU-FP32-FP16][FAIL] case=%0s in=%08h got=%04h finite=%0b overflow=%0b inexact=%0b expected=%04h finite=%0b overflow=%0b inexact=%0b",
                         case_name, input_bits, fp16_bits_o, finite_o,
                         overflow_o, inexact_o, expected_bits,
                         expected_finite, expected_overflow, expected_inexact);
            end
        end
    endtask

    initial begin
        fp32_bits_i = 32'b0;
        checks      = 0;
        failures    = 0;

        check_case("positive_zero", 32'h00000000, 16'h0000, 1, 0, 0);
        check_case("negative_zero", 32'h80000000, 16'h8000, 1, 0, 0);
        check_case("positive_one",  32'h3f800000, 16'h3c00, 1, 0, 0);
        check_case("negative_one",  32'hbf800000, 16'hbc00, 1, 0, 0);

        check_case("min_half_normal",    32'h38800000, 16'h0400, 1, 0, 0);
        check_case("max_half_subnormal", 32'h387fc000, 16'h03ff, 1, 0, 0);
        check_case("min_half_subnormal", 32'h33800000, 16'h0001, 1, 0, 0);
        check_case("subnormal_even_tie", 32'h33000000, 16'h0000, 1, 0, 1);
        check_case("subnormal_above_tie",32'h33000001, 16'h0001, 1, 0, 1);
        check_case("fp32_subnormal",     32'h00000001, 16'h0000, 1, 0, 1);

        check_case("rne_even_tie", 32'h3f801000, 16'h3c00, 1, 0, 1);
        check_case("rne_odd_tie",  32'h3f803000, 16'h3c02, 1, 0, 1);
        check_case("round_carry",  32'h3ffff000, 16'h4000, 1, 0, 1);

        check_case("max_half_finite",    32'h477fe000, 16'h7bff, 1, 0, 0);
        check_case("below_overflow_tie", 32'h477fefff, 16'h7bff, 1, 0, 1);
        check_case("overflow_tie",       32'h477ff000, 16'h7c00, 1, 1, 1);
        check_case("finite_overflow",    32'h47800000, 16'h7c00, 1, 1, 1);

        check_case("positive_inf", 32'h7f800000, 16'h7c00, 0, 0, 0);
        check_case("negative_inf", 32'hff800000, 16'hfc00, 0, 0, 0);
        check_case("quiet_nan",    32'h7fc00000, 16'h7e00, 0, 0, 0);
        check_case("signaling_nan",32'h7f800001, 16'h7e00, 0, 0, 0);

        if (failures != 0) begin
            $fatal(1, "[NPU-FP32-FP16][FAIL] checks=%0d failures=%0d",
                   checks, failures);
        end
        $display("[NPU-FP32-FP16][PASS] checks=%0d rne=1 raw_bits=1 finite_overflow_inexact=checked",
                 checks);
        $finish;
    end

endmodule

`default_nettype wire
