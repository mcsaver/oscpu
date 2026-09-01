`timescale 1ns/1ps

module tb_fp64_to_fp32_finite;

    logic        clk_i;
    logic        rst_i;
    logic        req_valid_i;
    wire         req_ready_o;
    logic [63:0] operand_i;
    wire         rsp_valid_o;
    logic        rsp_ready_i;
    wire [31:0]  result_o;
    wire [4:0]   flags_o;
    wire         error_o;

    integer accepted_count;
    integer retired_count;

    TensorNpuFp64ToFp32Finite dut (
        .clk_i       (clk_i),
        .rst_i       (rst_i),
        .req_valid_i (req_valid_i),
        .req_ready_o (req_ready_o),
        .operand_i   (operand_i),
        .rsp_valid_o (rsp_valid_o),
        .rsp_ready_i (rsp_ready_i),
        .result_o    (result_o),
        .flags_o     (flags_o),
        .error_o     (error_o)
    );

    initial clk_i = 1'b0;
    always #5 clk_i <= ~clk_i;

    task automatic send_case(
        input logic [63:0] request_raw,
        input logic [31:0] expected_raw,
        input logic [4:0]  expected_flags,
        input logic        expected_error,
        input integer      hold_cycles
    );
        logic [31:0] held_result;
        logic [4:0]  held_flags;
        logic        held_error;
        integer      cycle;
        begin
            @(negedge clk_i);
            if (req_ready_o !== 1'b1 || rsp_valid_o !== 1'b0) begin
                $fatal(1, "signed finite pack not EMPTY before input=%h", request_raw);
            end
            operand_i   = request_raw;
            req_valid_i = 1'b1;
            rsp_ready_i = 1'b0;
            @(posedge clk_i);
            #1;
            accepted_count = accepted_count + 1;
            req_valid_i = 1'b0;
            if (rsp_valid_o !== 1'b1 || req_ready_o !== 1'b0) begin
                $fatal(1, "signed finite pack response timing mismatch input=%h", request_raw);
            end
            if (result_o !== expected_raw || flags_o !== expected_flags ||
                error_o !== expected_error) begin
                $fatal(1,
                    "signed finite pack mismatch input=%h got=%h/%h/%b expected=%h/%h/%b",
                    request_raw, result_o, flags_o, error_o,
                    expected_raw, expected_flags, expected_error);
            end

            held_result = result_o;
            held_flags  = flags_o;
            held_error  = error_o;
            for (cycle = 0; cycle < hold_cycles; cycle = cycle + 1) begin
                // 循环综合无关：testbench procedural 逐拍施加五拍反压与变化中的 busy request。
                @(negedge clk_i);
                operand_i   = 64'hc7effffff0000000 ^ {32'b0, cycle[31:0]};
                req_valid_i = 1'b1;
                @(posedge clk_i);
                #1;
                if (req_ready_o !== 1'b0 || rsp_valid_o !== 1'b1 ||
                    result_o !== held_result || flags_o !== held_flags ||
                    error_o !== held_error) begin
                    $fatal(1, "signed finite pack held payload changed at hold cycle %0d", cycle);
                end
            end

            @(negedge clk_i);
            req_valid_i = 1'b0;
            operand_i   = 64'b0;
            rsp_ready_i = 1'b1;
            @(posedge clk_i);
            #1;
            retired_count = retired_count + 1;
            if (rsp_valid_o !== 1'b0) begin
                $fatal(1, "signed finite pack response did not retire");
            end
            @(negedge clk_i);
            rsp_ready_i = 1'b0;
        end
    endtask

    task automatic check_retire_then_accept;
        begin
            @(negedge clk_i);
            operand_i   = 64'h3ff0000000000000;
            req_valid_i = 1'b1;
            @(posedge clk_i);
            #1;
            accepted_count = accepted_count + 1;
            req_valid_i = 1'b0;
            if (rsp_valid_o !== 1'b1) begin
                $fatal(1, "retire/accept probe failed to create resident response");
            end

            @(negedge clk_i);
            operand_i   = 64'hbff0000000000000;
            req_valid_i = 1'b1;
            rsp_ready_i = 1'b1;
            if (req_ready_o !== 1'b0) begin
                $fatal(1, "retire/accept probe exposed request credit while FULL");
            end
            @(posedge clk_i);
            #1;
            retired_count = retired_count + 1;
            if (rsp_valid_o !== 1'b0 || req_ready_o !== 1'b1) begin
                $fatal(1, "retire/accept probe did not retire without same-edge accept");
            end

            rsp_ready_i = 1'b0;
            @(posedge clk_i);
            #1;
            accepted_count = accepted_count + 1;
            req_valid_i = 1'b0;
            if (rsp_valid_o !== 1'b1 || result_o !== 32'hbf800000 ||
                flags_o !== 5'b0 || error_o !== 1'b0) begin
                $fatal(1, "retire/accept probe next-cycle request was not captured cleanly");
            end
            @(negedge clk_i);
            rsp_ready_i = 1'b1;
            @(posedge clk_i);
            #1;
            retired_count = retired_count + 1;
            @(negedge clk_i);
            rsp_ready_i = 1'b0;
            operand_i   = 64'b0;
        end
    endtask

    task automatic check_resident_reset;
        begin
            @(negedge clk_i);
            operand_i   = 64'hbff0000000000000;
            req_valid_i = 1'b1;
            @(posedge clk_i);
            #1;
            accepted_count = accepted_count + 1;
            req_valid_i = 1'b0;
            if (rsp_valid_o !== 1'b1) begin
                $fatal(1, "resident reset probe request missing");
            end
            @(negedge clk_i);
            rst_i = 1'b1;
            #1;
            if (req_ready_o !== 1'b0 || rsp_valid_o !== 1'b0) begin
                $fatal(1, "signed finite pack interface active during reset");
            end
            @(posedge clk_i);
            #1;
            if (rsp_valid_o !== 1'b0 || result_o !== 32'b0 ||
                flags_o !== 5'b0 || error_o !== 1'b0) begin
                $fatal(1, "resident reset did not clear signed finite pack slot");
            end
            @(negedge clk_i);
            rst_i = 1'b0;
            operand_i = 64'b0;
            #1;
            if (req_ready_o !== 1'b1 || rsp_valid_o !== 1'b0) begin
                $fatal(1, "signed finite pack failed clean recovery after reset");
            end
            @(posedge clk_i);
            #1;
            if (rsp_valid_o !== 1'b0) begin
                $fatal(1, "signed finite pack emitted stale response after reset");
            end
        end
    endtask

    initial begin
        rst_i          = 1'b1;
        req_valid_i    = 1'b0;
        operand_i      = 64'b0;
        rsp_ready_i    = 1'b0;
        accepted_count = 0;
        retired_count  = 0;

        repeat (3) @(posedge clk_i);
        @(negedge clk_i);
        rst_i = 1'b0;

        // 固定 raw RNE/tininess-after oracle：signed zero、exact ±1。
        send_case(64'h0000000000000000, 32'h00000000, 5'h00, 1'b0, 0);
        send_case(64'h8000000000000000, 32'h80000000, 5'h00, 1'b0, 0);
        send_case(64'h3ff0000000000000, 32'h3f800000, 5'h00, 1'b0, 5);
        send_case(64'hbff0000000000000, 32'hbf800000, 5'h00, 1'b0, 0);

        // retained-even/odd ties与两侧非 tie，正负结果镜像但 flags完全一致。
        send_case(64'h3ff0000010000000, 32'h3f800000, 5'h01, 1'b0, 0);
        send_case(64'h3ff0000030000000, 32'h3f800002, 5'h01, 1'b0, 0);
        send_case(64'h3ff0000010000001, 32'h3f800001, 5'h01, 1'b0, 0);
        send_case(64'hbff0000010000000, 32'hbf800000, 5'h01, 1'b0, 0);
        send_case(64'hbff0000030000000, 32'hbf800002, 5'h01, 1'b0, 0);

        // F32 subnormal/normal边界、tininess-after和signed overflow。
        // minimum-normal 四项来自 generator d18d79a4... 的纯整数 oracle；
        // tiny 判定先做无限 exponent-range precision rounding，不能由最终 exponent field 反推。
        send_case(64'h36a0000000000000, 32'h00000001, 5'h00, 1'b0, 0);
        send_case(64'hb6a0000000000000, 32'h80000001, 5'h00, 1'b0, 0);
        send_case(64'h3690000000000000, 32'h00000000, 5'h03, 1'b0, 0);
        send_case(64'hb690000000000000, 32'h80000000, 5'h03, 1'b0, 0);
        send_case(64'h380fffffc0000000, 32'h007fffff, 5'h00, 1'b0, 0);
        send_case(64'hb80fffffc0000000, 32'h807fffff, 5'h00, 1'b0, 0);
        send_case(64'h380fffffdfffffff, 32'h007fffff, 5'h03, 1'b0, 0);
        send_case(64'hb80fffffdfffffff, 32'h807fffff, 5'h03, 1'b0, 0);
        send_case(64'h380fffffe0000000, 32'h00800000, 5'h03, 1'b0, 0);
        send_case(64'hb80fffffe0000000, 32'h80800000, 5'h03, 1'b0, 0);
        // Berkeley SoftFloat FAQ witness：final raw 已进位到 minimum normal，仍是 UF|NX。
        send_case(64'h380fffffe1000000, 32'h00800000, 5'h03, 1'b0, 0);
        send_case(64'hb80fffffe1000000, 32'h80800000, 5'h03, 1'b0, 0);
        // 真正 precision-only carry 边界：暂时精度舍入到 2^emin，所以仅 NX。
        send_case(64'h380ffffff0000000, 32'h00800000, 5'h01, 1'b0, 0);
        send_case(64'hb80ffffff0000000, 32'h80800000, 5'h01, 1'b0, 0);
        $display("[NPU-FP64-FP32-FINITE][TININESS-AFTER] uf_nx=380fffffdfffffff,380fffffe0000000,380fffffe1000000 nx=380ffffff0000000 sign_mirror=1");
        send_case(64'h47effffff0000000, 32'h7f800000, 5'h05, 1'b0, 0);
        send_case(64'hc7effffff0000000, 32'hff800000, 5'h05, 1'b0, 0);

        // NaN/Inf不是finite ABI：固定清零、error=1，不泄露HardFloat特殊payload。
        send_case(64'h7ff0000000000000, 32'h00000000, 5'h00, 1'b1, 0);
        send_case(64'hfff0000000000000, 32'h00000000, 5'h00, 1'b1, 0);
        send_case(64'h7ff8000000000001, 32'h00000000, 5'h00, 1'b1, 0);
        send_case(64'h7ff0000000000001, 32'h00000000, 5'h00, 1'b1, 0);

        check_retire_then_accept();
        check_resident_reset();
        // resident reset取消一个accepted事务，所以守恒允许最终差值1。
        if ((accepted_count - retired_count) != 1) begin
            $fatal(1, "signed finite pack accounting mismatch accepted=%0d retired=%0d",
                   accepted_count, retired_count);
        end

        // reset后的clean recovery同时证明flags/error不会跨事务泄漏。
        send_case(64'h0000000000000000, 32'h00000000, 5'h00, 1'b0, 0);

        $display("[NPU-FP64-FP32-FINITE][PASS]");
        $finish;
    end

endmodule
