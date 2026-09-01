`timescale 1ns/1ps
`default_nettype none

// RISC-V signed FCVT.W.S/RMM 的 raw-bit oracle；flags[4]=NV、flags[0]=NX。
module tb_fp32_to_int32_rmm;

    reg  [31:0] fp32_bits_i;
    wire [31:0] int32_bits_o;
    wire [4:0]  flags_o;
    wire        q8_range_o;

    integer checks;
    integer failures;

    TensorNpuFp32ToInt32Rmm dut (
        .fp32_bits_i (fp32_bits_i),
        .int32_bits_o(int32_bits_o),
        .flags_o     (flags_o),
        .q8_range_o  (q8_range_o)
    );

    task automatic check_case(
        input string       case_name,
        input logic [31:0] input_bits,
        input logic [31:0] expected_result,
        input logic [4:0]  expected_flags,
        input logic        expected_q8_range
    );
        begin
            fp32_bits_i = input_bits;
            #1;
            checks = checks + 1;
            if ((int32_bits_o !== expected_result)
                    || (flags_o !== expected_flags)
                    || (q8_range_o !== expected_q8_range)) begin
                failures = failures + 1;
                $display("[NPU-FP32-I32-RMM][FAIL] case=%0s in=%08h got=%08h flags=%02h q8=%0b expected=%08h flags=%02h q8=%0b",
                         case_name, input_bits, int32_bits_o, flags_o,
                         q8_range_o, expected_result, expected_flags,
                         expected_q8_range);
            end
        end
    endtask

    initial begin
        fp32_bits_i = 32'b0;
        checks      = 0;
        failures    = 0;

        check_case("positive_zero", 32'h00000000, 32'h00000000, 5'b00000, 1);
        check_case("negative_zero", 32'h80000000, 32'h00000000, 5'b00000, 1);
        check_case("positive_half", 32'h3f000000, 32'h00000001, 5'b00001, 1);
        check_case("negative_half", 32'hbf000000, 32'hffffffff, 5'b00001, 1);
        check_case("positive_2_5",  32'h40200000, 32'h00000003, 5'b00001, 1);
        check_case("negative_2_5",  32'hc0200000, 32'hfffffffd, 5'b00001, 1);
        check_case("positive_2_25", 32'h40100000, 32'h00000002, 5'b00001, 1);
        check_case("negative_2_75", 32'hc0300000, 32'hfffffffd, 5'b00001, 1);

        check_case("positive_126_5", 32'h42fd0000, 32'h0000007f, 5'b00001, 1);
        check_case("positive_127",   32'h42fe0000, 32'h0000007f, 5'b00000, 1);
        check_case("positive_127_5", 32'h42ff0000, 32'h00000080, 5'b00001, 0);
        check_case("positive_128",   32'h43000000, 32'h00000080, 5'b00000, 0);
        check_case("negative_126_5", 32'hc2fd0000, 32'hffffff81, 5'b00001, 1);
        check_case("negative_127",   32'hc2fe0000, 32'hffffff81, 5'b00000, 1);
        check_case("negative_127_5", 32'hc2ff0000, 32'hffffff80, 5'b00001, 0);
        check_case("negative_128",   32'hc3000000, 32'hffffff80, 5'b00000, 0);

        check_case("largest_in_range_int32", 32'h4effffff,
                   32'h7fffff80, 5'b00000, 0);
        check_case("int32_min_exact", 32'hcf000000,
                   32'h80000000, 5'b00000, 0);
        check_case("positive_out_of_range", 32'h4f000000,
                   32'h7fffffff, 5'b10000, 0);
        check_case("negative_out_of_range", 32'hcf000001,
                   32'h80000000, 5'b10000, 0);
        check_case("positive_inf", 32'h7f800000,
                   32'h7fffffff, 5'b10000, 0);
        check_case("negative_inf", 32'hff800000,
                   32'h80000000, 5'b10000, 0);
        check_case("quiet_nan", 32'h7fc00000,
                   32'h7fffffff, 5'b10000, 0);
        check_case("signaling_nan", 32'h7f800001,
                   32'h7fffffff, 5'b10000, 0);

        if (failures != 0) begin
            $fatal(1, "[NPU-FP32-I32-RMM][FAIL] checks=%0d failures=%0d",
                   checks, failures);
        end
        $display("[NPU-FP32-I32-RMM][PASS] checks=%0d riscv=1 rmm=1 q8_range=-127..127 nv_nx=checked",
                 checks);
        $finish;
    end

endmodule

`default_nettype wire
