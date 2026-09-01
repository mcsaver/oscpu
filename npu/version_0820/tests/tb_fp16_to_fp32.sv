`timescale 1ns/1ps
`default_nettype none

module tb_fp16_to_fp32;

    reg  [15:0] fp16_bits_i;
    wire [31:0] fp32_bits_o;
    wire        finite_o;
    wire        zero_o;

    integer checks;
    integer failures;

    TensorNpuFp16ToFp32 dut (
        .fp16_bits_i (fp16_bits_i),
        .fp32_bits_o (fp32_bits_o),
        .finite_o    (finite_o),
        .zero_o      (zero_o)
    );

    // All expected values are frozen IEEE-754 raw bits.  The testbench never
    // uses host real/shortreal conversion as an oracle.
    task automatic check_case (
        input string       case_name,
        input reg [15:0]   input_bits,
        input reg [31:0]   expected_bits,
        input reg          expected_finite,
        input reg          expected_zero
    );
        begin
            fp16_bits_i = input_bits;
            #1;
            checks = checks + 1;
            if ((fp32_bits_o !== expected_bits)
                    || (finite_o !== expected_finite)
                    || (zero_o !== expected_zero)) begin
                failures = failures + 1;
                $display("[NPU-FP16-EXPAND][FAIL] case=%0s in=%04h got=%08h finite=%0b zero=%0b expected=%08h finite=%0b zero=%0b",
                         case_name, input_bits, fp32_bits_o, finite_o, zero_o,
                         expected_bits, expected_finite, expected_zero);
            end
        end
    endtask

    initial begin
        fp16_bits_i = 16'h0000;
        checks      = 0;
        failures    = 0;

        check_case("positive-zero",  16'h0000, 32'h00000000, 1'b1, 1'b1);
        check_case("negative-zero",  16'h8000, 32'h80000000, 1'b1, 1'b1);
        check_case("positive-one",   16'h3c00, 32'h3f800000, 1'b1, 1'b0);
        check_case("negative-one",   16'hbc00, 32'hbf800000, 1'b1, 1'b0);
        check_case("normal-0x3555",  16'h3555, 32'h3eaaa000, 1'b1, 1'b0);
        check_case("min-subnormal",  16'h0001, 32'h33800000, 1'b1, 1'b0);
        check_case("max-subnormal",  16'h03ff, 32'h387fc000, 1'b1, 1'b0);
        check_case("min-normal",     16'h0400, 32'h38800000, 1'b1, 1'b0);
        check_case("max-finite",     16'h7bff, 32'h477fe000, 1'b1, 1'b0);
        check_case("positive-inf",   16'h7c00, 32'h7f800000, 1'b0, 1'b0);
        check_case("negative-inf",   16'hfc00, 32'hff800000, 1'b0, 1'b0);
        check_case("quiet-nan",      16'h7e55, 32'h7fcaa000, 1'b0, 1'b0);
        check_case("signed-snan",    16'hfd01, 32'hffa02000, 1'b0, 1'b0);

        if (failures != 0) begin
            $fatal(1, "[NPU-FP16-EXPAND][FAIL] checks=%0d failures=%0d",
                   checks, failures);
        end

        $display("[NPU-FP16-EXPAND][PASS]");
        $finish;
    end

endmodule

`default_nettype wire
