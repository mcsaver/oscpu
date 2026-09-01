`timescale 1ns/1ps

module tb_int32_to_fp64;

    logic        clk_i;
    logic        rst_i;
    logic        req_valid_i;
    wire         req_ready_o;
    logic [31:0] operand_i;
    wire         rsp_valid_o;
    logic        rsp_ready_i;
    wire [63:0]  result_o;
    wire [4:0]   flags_o;

    integer accepted_count;
    integer retired_count;

    TensorNpuInt32ToFp64 dut (
        .clk_i       (clk_i),
        .rst_i       (rst_i),
        .req_valid_i (req_valid_i),
        .req_ready_o (req_ready_o),
        .operand_i   (operand_i),
        .rsp_valid_o (rsp_valid_o),
        .rsp_ready_i (rsp_ready_i),
        .result_o    (result_o),
        .flags_o     (flags_o)
    );

    initial clk_i = 1'b0;
    always #5 clk_i <= ~clk_i;

    // Procedural transaction monitor: every reset starts a fresh occupancy epoch.
    always @(posedge clk_i) begin
        if (rst_i) begin
            accepted_count <= 0;
            retired_count  <= 0;
        end else begin
            if ((req_valid_i && req_ready_o) &&
                (rsp_valid_o && rsp_ready_i)) begin
                $fatal(1, "I32->F64 accepted and retired in the same cycle");
            end
            if (req_valid_i && req_ready_o) begin
                accepted_count <= accepted_count + 1;
            end
            if (rsp_valid_o && rsp_ready_i) begin
                retired_count <= retired_count + 1;
            end
        end
    end

    // At every half-cycle boundary the accepted-retired difference must equal FULL.
    always @(negedge clk_i) begin
        if (!rst_i) begin
            if ((accepted_count < retired_count) ||
                ((accepted_count - retired_count) > 1)) begin
                $fatal(1,
                    "I32->F64 outstanding cardinality violation accepted=%0d retired=%0d",
                    accepted_count, retired_count);
            end
            if ((accepted_count - retired_count) !=
                (rsp_valid_o ? 1 : 0)) begin
                $fatal(1,
                    "I32->F64 occupancy/state mismatch accepted=%0d retired=%0d valid=%b",
                    accepted_count, retired_count, rsp_valid_o);
            end
        end
    end

    task automatic check_case(
        input logic [31:0] request_bits,
        input logic [63:0] expected_result,
        input logic [4:0]  expected_flags,
        input integer      hold_cycles,
        input logic        drive_busy_requests
    );
        logic [63:0] held_result;
        logic [4:0]  held_flags;
        integer      accepted_before;
        integer      retired_before;
        integer      timeout_cycles;
        integer      hold_index;
        begin
            @(negedge clk_i);
            if (req_ready_o !== 1'b1 || rsp_valid_o !== 1'b0) begin
                $fatal(1, "I32->F64 request slot not EMPTY before input=%h", request_bits);
            end

            operand_i       = request_bits;
            req_valid_i     = 1'b1;
            rsp_ready_i     = 1'b0;
            accepted_before = accepted_count;

            // request fire；valid 只在该握手之后撤销。
            @(posedge clk_i);
            #1;
            req_valid_i = 1'b0;
            if (accepted_count !== (accepted_before + 1)) begin
                $fatal(1, "I32->F64 request was not accepted exactly once input=%h", request_bits);
            end

            timeout_cycles = 0;
            while ((rsp_valid_o !== 1'b1) && (timeout_cycles < 32)) begin
                @(posedge clk_i);
                #1;
                timeout_cycles = timeout_cycles + 1;
            end
            if (rsp_valid_o !== 1'b1 || req_ready_o !== 1'b0) begin
                $fatal(1, "I32->F64 response timeout/occupancy mismatch input=%h", request_bits);
            end

            held_result = result_o;
            held_flags  = flags_o;

            // 特定 case 将 response 反压至少5拍，并持续改变 busy request。
            for (hold_index = 0; hold_index < hold_cycles; hold_index = hold_index + 1) begin
                @(negedge clk_i);
                req_valid_i = drive_busy_requests;
                operand_i   = 32'h01000000 ^ {28'b0, hold_index[3:0]};
                @(posedge clk_i);
                #1;
                if (rsp_valid_o !== 1'b1 || req_ready_o !== 1'b0 ||
                    result_o !== held_result || flags_o !== held_flags) begin
                    $fatal(1,
                        "I32->F64 held response changed under backpressure input=%h hold=%0d",
                        request_bits, hold_index);
                end
                if (accepted_count !== (accepted_before + 1)) begin
                    $fatal(1, "I32->F64 busy request was sampled while FULL");
                end
            end

            @(negedge clk_i);
            req_valid_i = 1'b0;
            operand_i   = 32'b0;
            rsp_ready_i = 1'b1;
            retired_before = retired_count;

            // 只在 response handshake 上比较并消费 fixed raw-bit oracle。
            @(posedge clk_i);
            #1;
            if (result_o !== expected_result || flags_o !== expected_flags) begin
                $fatal(1,
                    "I32->F64 oracle mismatch input=%h got=%h/%h expected=%h/%h",
                    request_bits, result_o, flags_o, expected_result, expected_flags);
            end
            if (rsp_valid_o !== 1'b0 || req_ready_o !== 1'b1 ||
                retired_count !== (retired_before + 1)) begin
                $fatal(1, "I32->F64 response did not retire exactly once input=%h", request_bits);
            end

            // ready 多保持一拍也不能重复消费同一 response。
            @(posedge clk_i);
            #1;
            if (rsp_valid_o !== 1'b0 || retired_count !== (retired_before + 1)) begin
                $fatal(1, "I32->F64 response was consumed more than once input=%h", request_bits);
            end
            @(negedge clk_i);
            rsp_ready_i = 1'b0;
        end
    endtask

    task automatic check_retire_accept_separation;
        integer accepted_before_new;
        integer retired_before_old;
        integer retired_before_new;
        begin
            // 先建立 resident +1 response。
            @(negedge clk_i);
            operand_i   = 32'h00000001;
            req_valid_i = 1'b1;
            rsp_ready_i = 1'b0;
            @(posedge clk_i);
            #1;
            req_valid_i = 1'b0;
            if (rsp_valid_o !== 1'b1) begin
                $fatal(1, "I32->F64 separation probe did not become resident");
            end

            // FULL retire 同拍保持新 -1 request valid；该拍只能 retire。
            @(negedge clk_i);
            operand_i           = 32'hffffffff;
            req_valid_i         = 1'b1;
            rsp_ready_i         = 1'b1;
            accepted_before_new = accepted_count;
            retired_before_old  = retired_count;
            @(posedge clk_i);
            #1;
            if (result_o !== 64'h3ff0000000000000 || flags_o !== 5'h00) begin
                $fatal(1, "I32->F64 old response corrupted at retire+request cycle");
            end
            if (accepted_count !== accepted_before_new ||
                retired_count !== (retired_before_old + 1) ||
                rsp_valid_o !== 1'b0 || req_ready_o !== 1'b1) begin
                $fatal(1, "I32->F64 accepted new request in old-response retire cycle");
            end

            // request 保持到下一上升沿，此时 EMPTY 才允许 capture。
            @(posedge clk_i);
            #1;
            req_valid_i = 1'b0;
            rsp_ready_i = 1'b0;
            if (accepted_count !== (accepted_before_new + 1) ||
                rsp_valid_o !== 1'b1 || req_ready_o !== 1'b0) begin
                $fatal(1, "I32->F64 deferred request was not accepted on following cycle");
            end

            @(negedge clk_i);
            rsp_ready_i       = 1'b1;
            retired_before_new = retired_count;
            @(posedge clk_i);
            #1;
            if (result_o !== 64'hbff0000000000000 || flags_o !== 5'h00) begin
                $fatal(1, "I32->F64 deferred request oracle mismatch");
            end
            if (rsp_valid_o !== 1'b0 ||
                retired_count !== (retired_before_new + 1)) begin
                $fatal(1, "I32->F64 deferred response retire mismatch");
            end
            @(posedge clk_i);
            #1;
            if (retired_count !== (retired_before_new + 1)) begin
                $fatal(1, "I32->F64 deferred response consumed more than once");
            end
            @(negedge clk_i);
            rsp_ready_i = 1'b0;
            operand_i   = 32'b0;
        end
    endtask

    task automatic check_idle_reset;
        begin
            @(negedge clk_i);
            operand_i   = 32'h00001000;
            req_valid_i = 1'b1;
            rsp_ready_i = 1'b0;
            rst_i       = 1'b1;
            #1;
            if (req_ready_o !== 1'b0 || rsp_valid_o !== 1'b0) begin
                $fatal(1, "I32->F64 interface active during IDLE reset");
            end
            @(posedge clk_i);
            #1;
            if (result_o !== 64'b0 || flags_o !== 5'b0) begin
                $fatal(1, "I32->F64 IDLE reset did not clear payload registers");
            end
            @(negedge clk_i);
            req_valid_i = 1'b0;
            operand_i   = 32'b0;
            rst_i       = 1'b0;
            #1;
            if (req_ready_o !== 1'b1 || rsp_valid_o !== 1'b0) begin
                $fatal(1, "I32->F64 did not recover EMPTY after IDLE reset");
            end
            @(posedge clk_i);
            #1;
            if (rsp_valid_o !== 1'b0) begin
                $fatal(1, "I32->F64 stale response appeared after IDLE reset");
            end
        end
    endtask

    task automatic check_resident_reset;
        begin
            @(negedge clk_i);
            operand_i   = 32'h00001000;
            req_valid_i = 1'b1;
            rsp_ready_i = 1'b0;
            @(posedge clk_i);
            #1;
            req_valid_i = 1'b0;
            if (rsp_valid_o !== 1'b1) begin
                $fatal(1, "I32->F64 resident-reset probe was not accepted");
            end

            @(negedge clk_i);
            rst_i = 1'b1;
            #1;
            if (req_ready_o !== 1'b0 || rsp_valid_o !== 1'b0) begin
                $fatal(1, "I32->F64 resident response remained qualified during reset");
            end
            @(posedge clk_i);
            #1;
            if (result_o !== 64'b0 || flags_o !== 5'b0) begin
                $fatal(1, "I32->F64 resident reset did not clear payload registers");
            end
            @(negedge clk_i);
            rst_i     = 1'b0;
            operand_i = 32'b0;
            #1;
            if (req_ready_o !== 1'b1 || rsp_valid_o !== 1'b0) begin
                $fatal(1, "I32->F64 resident reset did not recover EMPTY");
            end
            @(posedge clk_i);
            #1;
            if (rsp_valid_o !== 1'b0) begin
                $fatal(1, "I32->F64 cancelled resident response reappeared");
            end
        end
    endtask

    task automatic check_reset_over_retire;
        begin
            @(negedge clk_i);
            operand_i   = 32'h00000001;
            req_valid_i = 1'b1;
            rsp_ready_i = 1'b0;
            @(posedge clk_i);
            #1;
            req_valid_i = 1'b0;
            if (rsp_valid_o !== 1'b1) begin
                $fatal(1, "I32->F64 reset-over-retire probe was not accepted");
            end

            // reset 与 ready 同拍时 reset 取消 resident，不发生 response fire。
            @(negedge clk_i);
            rsp_ready_i = 1'b1;
            rst_i       = 1'b1;
            #1;
            if (rsp_valid_o !== 1'b0 || req_ready_o !== 1'b0) begin
                $fatal(1, "I32->F64 reset did not dominate retire qualification");
            end
            @(posedge clk_i);
            #1;
            if (result_o !== 64'b0 || flags_o !== 5'b0) begin
                $fatal(1, "I32->F64 reset-over-retire did not clear payload");
            end
            @(negedge clk_i);
            rst_i       = 1'b0;
            rsp_ready_i = 1'b0;
            operand_i   = 32'b0;
            #1;
            if (req_ready_o !== 1'b1 || rsp_valid_o !== 1'b0) begin
                $fatal(1, "I32->F64 reset-over-retire did not recover EMPTY");
            end
            @(posedge clk_i);
            #1;
            if (rsp_valid_o !== 1'b0) begin
                $fatal(1, "I32->F64 stale completion after reset-over-retire");
            end
        end
    endtask

    initial begin
        rst_i          = 1'b1;
        req_valid_i    = 1'b0;
        operand_i      = 32'b0;
        rsp_ready_i    = 1'b0;
        accepted_count = 0;
        retired_count  = 0;

        repeat (3) begin
            @(posedge clk_i);
            #1;
            if (req_ready_o !== 1'b0 || rsp_valid_o !== 1'b0 ||
                result_o !== 64'b0 || flags_o !== 5'b0) begin
                $fatal(1, "I32->F64 initial synchronous reset violation");
            end
        end
        @(negedge clk_i);
        rst_i = 1'b0;
        #1;
        if (req_ready_o !== 1'b1 || rsp_valid_o !== 1'b0) begin
            $fatal(1, "I32->F64 initial reset left stale state");
        end

        check_idle_reset();

        // FP64_INTEGER_CONVERSION_RTL_CONTRACT.md §5 的全部9项 raw-bit oracle。
        check_case(32'h00000000, 64'h0000000000000000, 5'h00, 5, 1'b1);
        check_case(32'h00000001, 64'h3ff0000000000000, 5'h00, 0, 1'b0);
        check_case(32'hffffffff, 64'hbff0000000000000, 5'h00, 0, 1'b0);
        check_case(32'h7fffffff, 64'h41dfffffffc00000, 5'h00, 0, 1'b0);
        check_case(32'h80000000, 64'hc1e0000000000000, 5'h00, 0, 1'b0);
        check_case(32'h00001000, 64'h40b0000000000000, 5'h00, 0, 1'b0);
        check_case(32'hffffed40, 64'hc0b2c00000000000, 5'h00, 0, 1'b0);
        check_case(32'h01000001, 64'h4170000010000000, 5'h00, 0, 1'b0);
        check_case(32'hfeffffff, 64'hc170000010000000, 5'h00, 0, 1'b0);

        check_retire_accept_separation();
        check_resident_reset();
        // resident reset 后的 clean recovery。
        check_case(32'h00001000, 64'h40b0000000000000, 5'h00, 0, 1'b0);
        check_reset_over_retire();
        // reset-over-retire 后的 clean recovery。
        check_case(32'hffffed40, 64'hc0b2c00000000000, 5'h00, 0, 1'b0);

        $display("[NPU-I32-FP64][PASS]");
        $finish;
    end

endmodule
