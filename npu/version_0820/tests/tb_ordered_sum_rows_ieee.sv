`timescale 1ns/1ps
`default_nettype none

module tb_ordered_sum_rows_ieee;
    logic clk_i;
    logic rst_i;

    logic        widen_req_valid_i;
    wire         widen_req_ready_o;
    logic [31:0] widen_operand_i;
    wire         widen_rsp_valid_o;
    logic        widen_rsp_ready_i;
    wire [63:0]  widen_result_o;
    wire [4:0]   widen_flags_o;

    logic        add_req_valid_i;
    wire         add_req_ready_o;
    logic [63:0] add_operand_a_i;
    logic [63:0] add_operand_b_i;
    wire         add_rsp_valid_o;
    logic        add_rsp_ready_i;
    wire [63:0]  add_result_o;
    wire [4:0]   add_flags_o;

    logic        narrow_req_valid_i;
    wire         narrow_req_ready_o;
    logic [63:0] narrow_operand_i;
    wire         narrow_rsp_valid_o;
    logic        narrow_rsp_ready_i;
    wire [31:0]  narrow_result_o;
    wire [4:0]   narrow_flags_o;

    integer cycle_count;
    integer widen_req_count;
    integer widen_rsp_count;
    integer add_req_count;
    integer add_rsp_count;
    integer narrow_req_count;
    integer narrow_rsp_count;
    integer directed_cases;

    TensorNpuFp32ToFp64Ieee u_widen (
        .clk_i(clk_i), .rst_i(rst_i),
        .req_valid_i(widen_req_valid_i), .req_ready_o(widen_req_ready_o),
        .operand_i(widen_operand_i),
        .rsp_valid_o(widen_rsp_valid_o), .rsp_ready_i(widen_rsp_ready_i),
        .result_o(widen_result_o), .flags_o(widen_flags_o)
    );

    TensorNpuFp64AddIeee u_add (
        .clk_i(clk_i), .rst_i(rst_i),
        .req_valid_i(add_req_valid_i), .req_ready_o(add_req_ready_o),
        .operand_a_i(add_operand_a_i), .operand_b_i(add_operand_b_i),
        .rsp_valid_o(add_rsp_valid_o), .rsp_ready_i(add_rsp_ready_i),
        .result_o(add_result_o), .flags_o(add_flags_o)
    );

    TensorNpuFp64ToFp32Ieee u_narrow (
        .clk_i(clk_i), .rst_i(rst_i),
        .req_valid_i(narrow_req_valid_i), .req_ready_o(narrow_req_ready_o),
        .operand_i(narrow_operand_i),
        .rsp_valid_o(narrow_rsp_valid_o), .rsp_ready_i(narrow_rsp_ready_i),
        .result_o(narrow_result_o), .flags_o(narrow_flags_o)
    );

    // One procedural writer keeps the timing-only testbench clock outside the
    // sequential-RTL assignment rules checked by Verilator.
    initial begin
        clk_i = 1'b0;
        forever begin
            #5 clk_i = ~clk_i;
        end
    end

    task automatic fail_case(input string reason);
        begin
            $display("[NPU-ORDERED-SUM-ROWS-IEEE][FAIL] %s cycle=%0d", reason, cycle_count);
            $fatal(1);
        end
    endtask

    always @(posedge clk_i) begin
        cycle_count <= cycle_count + 1;
        if (cycle_count > 2000)
            fail_case("global-timeout");
        if (!rst_i) begin
            if (widen_req_valid_i && widen_req_ready_o)
                widen_req_count <= widen_req_count + 1;
            if (widen_rsp_valid_o && widen_rsp_ready_i)
                widen_rsp_count <= widen_rsp_count + 1;
            if (add_req_valid_i && add_req_ready_o)
                add_req_count <= add_req_count + 1;
            if (add_rsp_valid_o && add_rsp_ready_i)
                add_rsp_count <= add_rsp_count + 1;
            if (narrow_req_valid_i && narrow_req_ready_o)
                narrow_req_count <= narrow_req_count + 1;
            if (narrow_rsp_valid_o && narrow_rsp_ready_i)
                narrow_rsp_count <= narrow_rsp_count + 1;
        end
    end

    task automatic check_widen(
        input logic [31:0] operand,
        input logic [63:0] expected_result,
        input logic [4:0] expected_flags,
        input integer hold_cycles,
        input logic exercise_busy
    );
        logic [63:0] held_result;
        logic [4:0] held_flags;
        integer index;
        begin
            @(negedge clk_i);
            if (!widen_req_ready_o || widen_rsp_valid_o)
                fail_case("widen-not-empty");
            widen_operand_i   = operand;
            widen_req_valid_i = 1'b1;
            @(posedge clk_i); #1;
            widen_req_valid_i = 1'b0;
            if (!widen_rsp_valid_o || widen_req_ready_o
                    || widen_result_o !== expected_result
                    || widen_flags_o !== expected_flags)
                fail_case($sformatf("widen %08x got=%016x/%02x expected=%016x/%02x",
                    operand, widen_result_o, widen_flags_o,
                    expected_result, expected_flags));
            held_result = widen_result_o;
            held_flags  = widen_flags_o;
            @(negedge clk_i);
            if (exercise_busy) begin
                widen_operand_i   = 32'h7f80_0001;
                widen_req_valid_i = 1'b1;
            end
            for (index = 0; index < hold_cycles; index = index + 1) begin
                @(posedge clk_i); #1;
                if (!widen_rsp_valid_o || widen_req_ready_o
                        || widen_result_o !== held_result
                        || widen_flags_o !== held_flags)
                    fail_case("widen-FULL-hold");
            end
            @(negedge clk_i);
            widen_rsp_ready_i = 1'b1;
            @(posedge clk_i); #1;
            widen_req_valid_i = 1'b0;
            widen_rsp_ready_i = 1'b0;
            if (widen_rsp_valid_o || !widen_req_ready_o)
                fail_case("widen-retire");
            directed_cases = directed_cases + 1;
        end
    endtask

    task automatic check_add(
        input logic [63:0] operand_a,
        input logic [63:0] operand_b,
        input logic [63:0] expected_result,
        input logic [4:0] expected_flags,
        input integer hold_cycles,
        input logic exercise_busy
    );
        logic [63:0] held_result;
        logic [4:0] held_flags;
        integer index;
        begin
            @(negedge clk_i);
            if (!add_req_ready_o || add_rsp_valid_o)
                fail_case("add-not-empty");
            add_operand_a_i  = operand_a;
            add_operand_b_i  = operand_b;
            add_req_valid_i  = 1'b1;
            @(posedge clk_i); #1;
            add_req_valid_i  = 1'b0;
            if (!add_rsp_valid_o || add_req_ready_o
                    || add_result_o !== expected_result
                    || add_flags_o !== expected_flags)
                fail_case($sformatf("add %016x+%016x got=%016x/%02x expected=%016x/%02x",
                    operand_a, operand_b, add_result_o, add_flags_o,
                    expected_result, expected_flags));
            held_result = add_result_o;
            held_flags  = add_flags_o;
            @(negedge clk_i);
            if (exercise_busy) begin
                add_operand_a_i = 64'h7ff0_0000_0000_0000;
                add_operand_b_i = 64'hfff0_0000_0000_0000;
                add_req_valid_i = 1'b1;
            end
            for (index = 0; index < hold_cycles; index = index + 1) begin
                @(posedge clk_i); #1;
                if (!add_rsp_valid_o || add_req_ready_o
                        || add_result_o !== held_result
                        || add_flags_o !== held_flags)
                    fail_case("add-FULL-hold");
            end
            @(negedge clk_i);
            add_rsp_ready_i = 1'b1;
            @(posedge clk_i); #1;
            add_req_valid_i = 1'b0;
            add_rsp_ready_i = 1'b0;
            if (add_rsp_valid_o || !add_req_ready_o)
                fail_case("add-retire");
            directed_cases = directed_cases + 1;
        end
    endtask

    task automatic check_narrow(
        input logic [63:0] operand,
        input logic [31:0] expected_result,
        input logic [4:0] expected_flags,
        input integer hold_cycles,
        input logic exercise_busy
    );
        logic [31:0] held_result;
        logic [4:0] held_flags;
        integer index;
        begin
            @(negedge clk_i);
            if (!narrow_req_ready_o || narrow_rsp_valid_o)
                fail_case("narrow-not-empty");
            narrow_operand_i   = operand;
            narrow_req_valid_i = 1'b1;
            @(posedge clk_i); #1;
            narrow_req_valid_i = 1'b0;
            if (!narrow_rsp_valid_o || narrow_req_ready_o
                    || narrow_result_o !== expected_result
                    || narrow_flags_o !== expected_flags)
                fail_case($sformatf("narrow %016x got=%08x/%02x expected=%08x/%02x",
                    operand, narrow_result_o, narrow_flags_o,
                    expected_result, expected_flags));
            held_result = narrow_result_o;
            held_flags  = narrow_flags_o;
            @(negedge clk_i);
            if (exercise_busy) begin
                narrow_operand_i   = 64'h7ff0_0000_0000_0001;
                narrow_req_valid_i = 1'b1;
            end
            for (index = 0; index < hold_cycles; index = index + 1) begin
                @(posedge clk_i); #1;
                if (!narrow_rsp_valid_o || narrow_req_ready_o
                        || narrow_result_o !== held_result
                        || narrow_flags_o !== held_flags)
                    fail_case("narrow-FULL-hold");
            end
            @(negedge clk_i);
            narrow_rsp_ready_i = 1'b1;
            @(posedge clk_i); #1;
            narrow_req_valid_i = 1'b0;
            narrow_rsp_ready_i = 1'b0;
            if (narrow_rsp_valid_o || !narrow_req_ready_o)
                fail_case("narrow-retire");
            directed_cases = directed_cases + 1;
        end
    endtask

    task automatic reset_resident_slots;
        begin
            @(negedge clk_i);
            widen_operand_i     = 32'h3f80_0000;
            add_operand_a_i     = 64'h3ff0_0000_0000_0000;
            add_operand_b_i     = 64'h3ff0_0000_0000_0000;
            narrow_operand_i    = 64'h3ff0_0000_0000_0000;
            widen_req_valid_i   = 1'b1;
            add_req_valid_i     = 1'b1;
            narrow_req_valid_i  = 1'b1;
            @(posedge clk_i); #1;
            widen_req_valid_i   = 1'b0;
            add_req_valid_i     = 1'b0;
            narrow_req_valid_i  = 1'b0;
            if (!widen_rsp_valid_o || !add_rsp_valid_o || !narrow_rsp_valid_o)
                fail_case("reset-probe-responses-not-resident");
            @(negedge clk_i);
            rst_i = 1'b1;
            #1;
            if (widen_req_ready_o || widen_rsp_valid_o || add_req_ready_o
                    || add_rsp_valid_o || narrow_req_ready_o || narrow_rsp_valid_o)
                fail_case("child-interface-active-during-reset");
            @(posedge clk_i); #1;
            if (widen_result_o !== 64'b0 || widen_flags_o !== 5'b0
                    || add_result_o !== 64'b0 || add_flags_o !== 5'b0
                    || narrow_result_o !== 32'b0 || narrow_flags_o !== 5'b0)
                fail_case("reset-did-not-clear-resident-payload");
            @(negedge clk_i);
            rst_i = 1'b0;
            #1;
            if (!widen_req_ready_o || !add_req_ready_o || !narrow_req_ready_o
                    || widen_rsp_valid_o || add_rsp_valid_o || narrow_rsp_valid_o)
                fail_case("children-not-empty-after-reset");
        end
    endtask

    initial begin
        cycle_count = 0;
        widen_req_count = 0;
        widen_rsp_count = 0;
        add_req_count = 0;
        add_rsp_count = 0;
        narrow_req_count = 0;
        narrow_rsp_count = 0;
        directed_cases = 0;
        rst_i = 1'b1;
        widen_req_valid_i = 1'b0;
        widen_operand_i = 32'b0;
        widen_rsp_ready_i = 1'b0;
        add_req_valid_i = 1'b0;
        add_operand_a_i = 64'b0;
        add_operand_b_i = 64'b0;
        add_rsp_ready_i = 1'b0;
        narrow_req_valid_i = 1'b0;
        narrow_operand_i = 64'b0;
        narrow_rsp_ready_i = 1'b0;
        repeat (3) @(posedge clk_i);
        @(negedge clk_i);
        rst_i = 1'b0;

        check_widen(32'h0000_0000, 64'h0000_0000_0000_0000, 5'h00, 3, 1'b1);
        check_widen(32'h8000_0000, 64'h8000_0000_0000_0000, 5'h00, 0, 1'b0);
        check_widen(32'h0000_0001, 64'h36a0_0000_0000_0000, 5'h00, 0, 1'b0);
        check_widen(32'h3fc0_0000, 64'h3ff8_0000_0000_0000, 5'h00, 0, 1'b0);
        check_widen(32'h7f80_0000, 64'h7ff0_0000_0000_0000, 5'h00, 0, 1'b0);
        check_widen(32'hff80_0000, 64'hfff0_0000_0000_0000, 5'h00, 0, 1'b0);
        check_widen(32'h7fc1_2345, 64'h7ff8_0000_0000_0000, 5'h00, 0, 1'b0);
        check_widen(32'h7f81_2345, 64'h7ff8_0000_0000_0000, 5'h10, 0, 1'b0);

        check_add(64'h0000_0000_0000_0000, 64'h8000_0000_0000_0000,
                  64'h0000_0000_0000_0000, 5'h00, 3, 1'b1);
        check_add(64'h8000_0000_0000_0000, 64'h8000_0000_0000_0000,
                  64'h8000_0000_0000_0000, 5'h00, 0, 1'b0);
        check_add(64'h3ff0_0000_0000_0000, 64'hbff0_0000_0000_0000,
                  64'h0000_0000_0000_0000, 5'h00, 0, 1'b0);
        check_add(64'h0000_0000_0000_0001, 64'h0000_0000_0000_0001,
                  64'h0000_0000_0000_0002, 5'h00, 0, 1'b0);
        check_add(64'h3ff0_0000_0000_0000, 64'h3ca0_0000_0000_0000,
                  64'h3ff0_0000_0000_0000, 5'h01, 0, 1'b0);
        check_add(64'h7fefff_ffffffffff, 64'h7fefff_ffffffffff,
                  64'h7ff0_0000_0000_0000, 5'h05, 0, 1'b0);
        check_add(64'h7ff0_0000_0000_0000, 64'h3ff0_0000_0000_0000,
                  64'h7ff0_0000_0000_0000, 5'h00, 0, 1'b0);
        check_add(64'h7ff0_0000_0000_0000, 64'hfff0_0000_0000_0000,
                  64'h7ff8_0000_0000_0000, 5'h10, 0, 1'b0);
        check_add(64'h7ff8_1234_5678_9abc, 64'h3ff0_0000_0000_0000,
                  64'h7ff8_0000_0000_0000, 5'h00, 0, 1'b0);
        check_add(64'h7ff0_0000_0000_0001, 64'h3ff0_0000_0000_0000,
                  64'h7ff8_0000_0000_0000, 5'h10, 0, 1'b0);
        check_add(64'hc000_0000_0000_0000, 64'h3ff0_0000_0000_0000,
                  64'hbff0_0000_0000_0000, 5'h00, 0, 1'b0);

        check_narrow(64'h0000_0000_0000_0000, 32'h0000_0000, 5'h00, 3, 1'b1);
        check_narrow(64'h8000_0000_0000_0000, 32'h8000_0000, 5'h00, 0, 1'b0);
        check_narrow(64'h3ff0_0000_0000_0000, 32'h3f80_0000, 5'h00, 0, 1'b0);
        check_narrow(64'h36a0_0000_0000_0000, 32'h0000_0001, 5'h00, 0, 1'b0);
        check_narrow(64'h0000_0000_0000_0001, 32'h0000_0000, 5'h03, 0, 1'b0);
        check_narrow(64'h3ff0_0000_1000_0000, 32'h3f80_0000, 5'h01, 0, 1'b0);
        check_narrow(64'h7fef_ffff_ffff_ffff, 32'h7f80_0000, 5'h05, 0, 1'b0);
        check_narrow(64'h7ff0_0000_0000_0000, 32'h7f80_0000, 5'h00, 0, 1'b0);
        check_narrow(64'hfff0_0000_0000_0000, 32'hff80_0000, 5'h00, 0, 1'b0);
        check_narrow(64'h7ff8_1234_5678_9abc, 32'h7fc0_0000, 5'h00, 0, 1'b0);
        check_narrow(64'h7ff0_0000_0000_0001, 32'h7fc0_0000, 5'h10, 0, 1'b0);

        reset_resident_slots();

        // clean recovery after a simultaneous reset-cancelled resident response.
        check_widen(32'h4000_0000, 64'h4000_0000_0000_0000, 5'h00, 0, 1'b0);
        check_add(64'h3ff0_0000_0000_0000, 64'h4000_0000_0000_0000,
                  64'h4008_0000_0000_0000, 5'h00, 0, 1'b0);
        check_narrow(64'h4008_0000_0000_0000, 32'h4040_0000, 5'h00, 0, 1'b0);

        if (directed_cases != 33)
            fail_case($sformatf("directed_cases=%0d expected=33", directed_cases));
        if (widen_req_count != (widen_rsp_count + 1)
                || add_req_count != (add_rsp_count + 1)
                || narrow_req_count != (narrow_rsp_count + 1))
            fail_case("single-outstanding-cardinality");

        $display("[NPU-ORDERED-SUM-ROWS-IEEE][INFO] cases=%0d widen=%0d/%0d add=%0d/%0d narrow=%0d/%0d reset_cancelled=3",
            directed_cases, widen_req_count, widen_rsp_count,
            add_req_count, add_rsp_count, narrow_req_count, narrow_rsp_count);
        $display("[NPU-ORDERED-SUM-ROWS-IEEE][PASS]");
        $finish;
    end
endmodule

`default_nettype wire
