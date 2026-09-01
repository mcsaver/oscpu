`timescale 1ns/1ps
`include "tensor_npu_defs.vh"

module tb_mm2_engine;

    localparam integer LMEM_BYTES = 512;
    localparam integer TIMEOUT_CYCLES = 2000;

    localparam [31:0] MAIN_X_BASE   = 32'd0;
    localparam [31:0] MAIN_W_BASE   = 32'd64;
    localparam [31:0] MAIN_DST_BASE = 32'd128;
    localparam [31:0] UINT_X_BASE   = 32'd192;
    localparam [31:0] UINT_W_BASE   = 32'd208;
    localparam [31:0] UINT_DST_BASE = 32'd224;

    reg clk;
    reg rst;

    reg                         start;
    reg [`NPU_OP_W-1:0]         op;
    reg [4:0]                   flags;
    reg [5:0]                   dst_id;
    reg [`NPU_DESC_W-1:0]       dst_desc;
    reg [4:0]                   dst_words_valid;
    reg [5:0]                   x_id;
    reg [`NPU_DESC_W-1:0]       x_desc;
    reg [4:0]                   x_words_valid;
    reg [5:0]                   w_id;
    reg [`NPU_DESC_W-1:0]       w_desc;
    reg [4:0]                   w_words_valid;
    reg [5:0]                   bias_id;
    reg [`NPU_DESC_W-1:0]       bias_desc;
    reg [4:0]                   bias_words_valid;
    reg [5:0]                   kzp_id;
    reg [`NPU_DESC_W-1:0]       kzp_desc;
    reg [4:0]                   kzp_words_valid;

    wire                        engine_busy;
    wire                        engine_done;
    wire                        engine_error;
    wire [`NPU_ERROR_W-1:0]     engine_error_code;
    wire [63:0]                 engine_cycles;

    wire                        engine_rd0_valid;
    wire [31:0]                 engine_rd0_addr;
    wire [3:0]                  engine_rd0_bytes;
    wire [63:0]                 engine_rd0_data;
    wire                        engine_rd0_oob;
    wire                        engine_rd1_valid;
    wire [31:0]                 engine_rd1_addr;
    wire [3:0]                  engine_rd1_bytes;
    wire [63:0]                 engine_rd1_data;
    wire                        engine_rd1_oob;
    wire                        engine_wr_valid;
    wire [31:0]                 engine_wr_addr;
    wire [63:0]                 engine_wr_data;
    wire [7:0]                  engine_wr_strb;
    wire                        engine_wr_oob;

    reg                         tb_rd0_valid;
    reg [31:0]                  tb_rd0_addr;
    reg [3:0]                   tb_rd0_bytes;
    reg                         tb_rd1_valid;
    reg [31:0]                  tb_rd1_addr;
    reg [3:0]                   tb_rd1_bytes;
    reg                         tb_wr_valid;
    reg [31:0]                  tb_wr_addr;
    reg [63:0]                  tb_wr_data;
    reg [7:0]                   tb_wr_strb;

    wire                        lmem_rd0_valid;
    wire [31:0]                 lmem_rd0_addr;
    wire [3:0]                  lmem_rd0_bytes;
    wire [63:0]                 lmem_rd0_data;
    wire                        lmem_rd0_oob;
    wire                        lmem_rd1_valid;
    wire [31:0]                 lmem_rd1_addr;
    wire [3:0]                  lmem_rd1_bytes;
    wire [63:0]                 lmem_rd1_data;
    wire                        lmem_rd1_oob;
    wire                        lmem_wr_valid;
    wire [31:0]                 lmem_wr_addr;
    wire [63:0]                 lmem_wr_data;
    wire [7:0]                  lmem_wr_strb;
    wire                        lmem_wr_oob;

    integer engine_write_count;

    // The active MM2 transaction owns LMEM.  At every other time the TB may
    // use the same public ports to preload operands or inspect results.
    assign lmem_rd0_valid = engine_busy ? engine_rd0_valid : tb_rd0_valid;
    assign lmem_rd0_addr  = engine_busy ? engine_rd0_addr  : tb_rd0_addr;
    assign lmem_rd0_bytes = engine_busy ? engine_rd0_bytes : tb_rd0_bytes;
    assign lmem_rd1_valid = engine_busy ? engine_rd1_valid : tb_rd1_valid;
    assign lmem_rd1_addr  = engine_busy ? engine_rd1_addr  : tb_rd1_addr;
    assign lmem_rd1_bytes = engine_busy ? engine_rd1_bytes : tb_rd1_bytes;
    assign lmem_wr_valid  = engine_busy ? engine_wr_valid  : tb_wr_valid;
    assign lmem_wr_addr   = engine_busy ? engine_wr_addr   : tb_wr_addr;
    assign lmem_wr_data   = engine_busy ? engine_wr_data   : tb_wr_data;
    assign lmem_wr_strb   = engine_busy ? engine_wr_strb   : tb_wr_strb;

    assign engine_rd0_data = lmem_rd0_data;
    assign engine_rd0_oob  = lmem_rd0_oob;
    assign engine_rd1_data = lmem_rd1_data;
    assign engine_rd1_oob  = lmem_rd1_oob;
    assign engine_wr_oob   = lmem_wr_oob;

    TensorNpuMm2Engine #(
        .LMEM_BYTES(LMEM_BYTES)
    ) dut (
        .clk(clk),
        .rst(rst),
        .start_i(start),
        .op_i(op),
        .flags_i(flags),
        .dst_id_i(dst_id),
        .dst_desc_i(dst_desc),
        .dst_words_valid_i(dst_words_valid),
        .x_id_i(x_id),
        .x_desc_i(x_desc),
        .x_words_valid_i(x_words_valid),
        .w_id_i(w_id),
        .w_desc_i(w_desc),
        .w_words_valid_i(w_words_valid),
        .bias_id_i(bias_id),
        .bias_desc_i(bias_desc),
        .bias_words_valid_i(bias_words_valid),
        .kzp_id_i(kzp_id),
        .kzp_desc_i(kzp_desc),
        .kzp_words_valid_i(kzp_words_valid),
        .busy_o(engine_busy),
        .done_o(engine_done),
        .error_o(engine_error),
        .error_code_o(engine_error_code),
        .cycles_o(engine_cycles),
        .rd0_valid_o(engine_rd0_valid),
        .rd0_addr_o(engine_rd0_addr),
        .rd0_bytes_o(engine_rd0_bytes),
        .rd0_data_i(engine_rd0_data),
        .rd0_oob_i(engine_rd0_oob),
        .rd1_valid_o(engine_rd1_valid),
        .rd1_addr_o(engine_rd1_addr),
        .rd1_bytes_o(engine_rd1_bytes),
        .rd1_data_i(engine_rd1_data),
        .rd1_oob_i(engine_rd1_oob),
        .wr_valid_o(engine_wr_valid),
        .wr_addr_o(engine_wr_addr),
        .wr_data_o(engine_wr_data),
        .wr_strb_o(engine_wr_strb),
        .wr_oob_i(engine_wr_oob)
    );

    TensorNpuLocalMemory #(
        .LMEM_BYTES(LMEM_BYTES)
    ) lmem (
        .clk(clk),
        .rd0_valid_i(lmem_rd0_valid),
        .rd0_addr_i(lmem_rd0_addr),
        .rd0_bytes_i(lmem_rd0_bytes),
        .rd0_data_o(lmem_rd0_data),
        .rd0_oob_o(lmem_rd0_oob),
        .rd1_valid_i(lmem_rd1_valid),
        .rd1_addr_i(lmem_rd1_addr),
        .rd1_bytes_i(lmem_rd1_bytes),
        .rd1_data_o(lmem_rd1_data),
        .rd1_oob_o(lmem_rd1_oob),
        .wr_valid_i(lmem_wr_valid),
        .wr_addr_i(lmem_wr_addr),
        .wr_data_i(lmem_wr_data),
        .wr_strb_i(lmem_wr_strb),
        .wr_oob_o(lmem_wr_oob)
    );

    function automatic [`NPU_DESC_W-1:0] make_tr_desc;
        input [31:0] base;
        input        subtype;
        input [3:0]  teew;
        input [15:0] shape_n;
        input [15:0] shape_c;
        input [15:0] shape_h;
        input [15:0] shape_w;
        reg [`NPU_DESC_W-1:0] value;
        begin
            value = {`NPU_DESC_W{1'b0}};
            value[31:0]    = base;
            value[55:52]   = 4'd1; // CONTINUOUS: strides are intentionally 0.
            value[59]      = subtype;
            value[63:60]   = teew;
            value[79:64]   = shape_w;
            value[95:80]   = shape_h;
            value[111:96]  = shape_c;
            value[127:112] = shape_n;
            make_tr_desc = value;
        end
    endfunction

    function automatic [`NPU_DESC_W-1:0] make_cr_desc;
        input [55:0] scalar_value;
        input        subtype;
        input [3:0]  teew;
        reg [`NPU_DESC_W-1:0] value;
        begin
            value = {`NPU_DESC_W{1'b0}};
            value[55:0]  = scalar_value;
            value[59]    = subtype;
            value[63:60] = teew;
            make_cr_desc = value;
        end
    endfunction

    task automatic fail;
        input string reason;
        begin
            $display("[NPU-MM2][FAIL] %s", reason);
            $fatal(1);
        end
    endtask

    task automatic clear_tb_ports;
        begin
            tb_rd0_valid = 1'b0;
            tb_rd0_addr  = 32'd0;
            tb_rd0_bytes = 4'd0;
            tb_rd1_valid = 1'b0;
            tb_rd1_addr  = 32'd0;
            tb_rd1_bytes = 4'd0;
            tb_wr_valid  = 1'b0;
            tb_wr_addr   = 32'd0;
            tb_wr_data   = 64'd0;
            tb_wr_strb   = 8'd0;
        end
    endtask

    task automatic lmem_write;
        input [31:0] addr;
        input [63:0] data;
        input [7:0]  strb;
        begin
            if (engine_busy)
                fail("TB attempted an LMEM write while the engine owned LMEM");
            @(negedge clk);
            tb_wr_addr  = addr;
            tb_wr_data  = data;
            tb_wr_strb  = strb;
            tb_wr_valid = 1'b1;
            #1;
            if (lmem_wr_oob)
                fail($sformatf("TB preload unexpectedly OOB at 0x%08x", addr));
            @(posedge clk);
            #1;
            @(negedge clk);
            tb_wr_valid = 1'b0;
            tb_wr_addr  = 32'd0;
            tb_wr_data  = 64'd0;
            tb_wr_strb  = 8'd0;
        end
    endtask

    task automatic lmem_write_byte;
        input [31:0] addr;
        input [7:0]  value;
        begin
            lmem_write(addr, {56'd0, value}, 8'h01);
        end
    endtask

    task automatic lmem_write_word32;
        input [31:0] addr;
        input [31:0] value;
        begin
            lmem_write(addr, {32'd0, value}, 8'h0f);
        end
    endtask

    task automatic expect_word32;
        input [31:0] addr;
        input [31:0] expected;
        begin
            if (engine_busy)
                fail("TB attempted an LMEM read while the engine owned LMEM");
            @(negedge clk);
            tb_rd0_addr  = addr;
            tb_rd0_bytes = 4'd4;
            tb_rd0_valid = 1'b1;
            #1;
            if (lmem_rd0_oob)
                fail($sformatf("result read unexpectedly OOB at 0x%08x", addr));
            if (lmem_rd0_data[31:0] !== expected)
                fail($sformatf("little-endian result at 0x%08x: got 0x%08x expected 0x%08x",
                               addr, lmem_rd0_data[31:0], expected));
            @(negedge clk);
            tb_rd0_valid = 1'b0;
            tb_rd0_addr  = 32'd0;
            tb_rd0_bytes = 4'd0;
        end
    endtask

    task automatic configure_main_case;
        begin
            op                  = `NPU_OP_MM2_NN;
            flags               = 5'b00001; // variant=0, rq=0, relu=1
            dst_id              = 6'd8;
            dst_desc            = make_tr_desc(MAIN_DST_BASE, 1'b1, 4'd2,
                                               16'd1, 16'd2, 16'd1, 16'd2);
            dst_words_valid     = 5'b01111;
            x_id                = 6'd9;
            x_desc              = make_tr_desc(MAIN_X_BASE, 1'b1, 4'd0,
                                               16'd1, 16'd2, 16'd1, 16'd3);
            x_words_valid       = 5'b01111;
            w_id                = 6'd10;
            w_desc              = make_tr_desc(MAIN_W_BASE, 1'b0, 4'd0,
                                               16'd1, 16'd3, 16'd1, 16'd2);
            w_words_valid       = 5'b01111;
            bias_id             = 6'd1;
            bias_desc           = make_cr_desc(-56'sd5, 1'b1, 4'd2);
            bias_words_valid    = 5'b00001;
            kzp_id              = 6'd2;
            kzp_desc            = make_cr_desc(56'sd5, 1'b1, 4'd1);
            kzp_words_valid     = 5'b00001;
        end
    endtask

    task automatic run_engine;
        input                        expect_error;
        input [`NPU_ERROR_W-1:0]     expected_error_code;
        integer guard;
        reg seen_busy;
        begin
            if (engine_busy || engine_done || engine_error)
                fail("engine was not idle before start");
            if (tb_rd0_valid || tb_rd1_valid || tb_wr_valid)
                fail("TB LMEM port remained active at engine start");

            seen_busy = 1'b0;
            @(negedge clk);
            start = 1'b1;
            @(posedge clk);
            #1;
            if (engine_busy)
                seen_busy = 1'b1;
            @(negedge clk);
            start = 1'b0;

            guard = 0;
            while (!engine_done && !engine_error &&
                   (guard < TIMEOUT_CYCLES)) begin
                @(posedge clk);
                #1;
                if (engine_busy)
                    seen_busy = 1'b1;
                guard = guard + 1;
            end

            if (guard >= TIMEOUT_CYCLES)
                fail("engine timeout");
            if (!seen_busy)
                fail("busy never asserted during transaction");
            if (engine_cycles == 64'd0)
                fail("cycles_o was zero at terminal");
            if (engine_done && engine_error)
                fail("done and error asserted together");
            if (engine_busy)
                fail("busy remained asserted at terminal");

            if (expect_error) begin
                if (!engine_error || engine_done)
                    fail("expected error terminal was not observed");
                if (engine_error_code !== expected_error_code)
                    fail($sformatf("error code got 0x%0x expected 0x%0x",
                                   engine_error_code, expected_error_code));
            end else begin
                if (!engine_done || engine_error)
                    fail("expected done terminal was not observed");
                if (engine_error_code !== `NPU_ERR_NONE)
                    fail("done terminal exposed a nonzero error code");
            end

            // The terminal indication must be exactly one clock wide.
            @(posedge clk);
            #1;
            if (engine_done || engine_error)
                fail("done/error terminal lasted more than one cycle");
            if (engine_busy)
                fail("engine did not return idle after terminal");
        end
    endtask

    task automatic expect_error_without_write;
        input [`NPU_ERROR_W-1:0] expected_error_code;
        integer writes_before;
        begin
            writes_before = engine_write_count;
            run_engine(1'b1, expected_error_code);
            if (engine_write_count != writes_before)
                fail("negative transaction issued an LMEM output write");
        end
    endtask

    always #5 clk <= ~clk;

    always @(posedge clk) begin
        if (rst)
            engine_write_count <= 0;
        else if (engine_wr_valid)
            engine_write_count <= engine_write_count + 1;
    end

    initial begin
        integer writes_before;

        clk = 1'b0;
        rst = 1'b1;
        start = 1'b0;
        op = {`NPU_OP_W{1'b0}};
        flags = 5'd0;
        dst_id = 6'd0;
        dst_desc = {`NPU_DESC_W{1'b0}};
        dst_words_valid = 5'd0;
        x_id = 6'd0;
        x_desc = {`NPU_DESC_W{1'b0}};
        x_words_valid = 5'd0;
        w_id = 6'd0;
        w_desc = {`NPU_DESC_W{1'b0}};
        w_words_valid = 5'd0;
        bias_id = 6'd0;
        bias_desc = {`NPU_DESC_W{1'b0}};
        bias_words_valid = 5'd0;
        kzp_id = 6'd0;
        kzp_desc = {`NPU_DESC_W{1'b0}};
        kzp_words_valid = 5'd0;
        clear_tb_ports();

        repeat (4) @(posedge clk);
        @(negedge clk);
        rst = 1'b0;

        // Main 2x3 * 3x2 case:
        //   X(S8) = [[ 1,-2, 3],[-4, 5,-6]]
        //   W(U8) = [[ 2, 4],[ 6, 8],[10,12]], kzp=5, bias=-5
        //   ReLU(X*(W-kzp)+bias) = [[5,9],[0,0]].
        lmem_write_byte(MAIN_X_BASE + 32'd0, 8'h01);
        lmem_write_byte(MAIN_X_BASE + 32'd1, 8'hfe);
        lmem_write_byte(MAIN_X_BASE + 32'd2, 8'h03);
        lmem_write_byte(MAIN_X_BASE + 32'd3, 8'hfc);
        lmem_write_byte(MAIN_X_BASE + 32'd4, 8'h05);
        lmem_write_byte(MAIN_X_BASE + 32'd5, 8'hfa);
        lmem_write_byte(MAIN_W_BASE + 32'd0, 8'h02);
        lmem_write_byte(MAIN_W_BASE + 32'd1, 8'h04);
        lmem_write_byte(MAIN_W_BASE + 32'd2, 8'h06);
        lmem_write_byte(MAIN_W_BASE + 32'd3, 8'h08);
        lmem_write_byte(MAIN_W_BASE + 32'd4, 8'h0a);
        lmem_write_byte(MAIN_W_BASE + 32'd5, 8'h0c);
        lmem_write_word32(MAIN_DST_BASE + 32'd0, 32'hdeadbeef);
        lmem_write_word32(MAIN_DST_BASE + 32'd4, 32'hdeadbeef);
        lmem_write_word32(MAIN_DST_BASE + 32'd8, 32'hdeadbeef);
        lmem_write_word32(MAIN_DST_BASE + 32'd12, 32'hdeadbeef);

        configure_main_case();
        writes_before = engine_write_count;
        run_engine(1'b0, `NPU_ERR_NONE);
        if ((engine_write_count - writes_before) != 4)
            fail($sformatf("main case issued %0d writes instead of 4",
                           engine_write_count - writes_before));
        expect_word32(MAIN_DST_BASE + 32'd0, 32'sd5);
        expect_word32(MAIN_DST_BASE + 32'd4, 32'sd9);
        expect_word32(MAIN_DST_BASE + 32'd8, 32'sd0);
        expect_word32(MAIN_DST_BASE + 32'd12, 32'sd0);

        // Reverse signedness coverage: U8 [2,3] * S8 [-2,5] = U32 11.
        lmem_write_byte(UINT_X_BASE + 32'd0, 8'h02);
        lmem_write_byte(UINT_X_BASE + 32'd1, 8'h03);
        lmem_write_byte(UINT_W_BASE + 32'd0, 8'hfe);
        lmem_write_byte(UINT_W_BASE + 32'd1, 8'h05);
        lmem_write_word32(UINT_DST_BASE, 32'hdeadbeef);
        flags              = 5'b00000;
        dst_id             = 6'd8;
        dst_desc           = make_tr_desc(UINT_DST_BASE, 1'b0, 4'd2,
                                          16'd1, 16'd1, 16'd1, 16'd1);
        dst_words_valid    = 5'b01111;
        x_id               = 6'd9;
        x_desc             = make_tr_desc(UINT_X_BASE, 1'b0, 4'd0,
                                          16'd1, 16'd1, 16'd1, 16'd2);
        x_words_valid      = 5'b01111;
        w_id               = 6'd10;
        w_desc             = make_tr_desc(UINT_W_BASE, 1'b1, 4'd0,
                                          16'd1, 16'd2, 16'd1, 16'd1);
        w_words_valid      = 5'b01111;
        bias_id            = 6'd0;
        bias_desc          = make_cr_desc(56'd0, 1'b1, 4'd2);
        bias_words_valid   = 5'b00001;
        kzp_id             = 6'd0;
        kzp_desc           = make_cr_desc(56'd0, 1'b1, 4'd1);
        kzp_words_valid    = 5'b00001;
        writes_before = engine_write_count;
        run_engine(1'b0, `NPU_ERR_NONE);
        if ((engine_write_count - writes_before) != 1)
            fail("reverse-signedness case did not issue exactly one write");
        expect_word32(UINT_DST_BASE, 32'd11);

        // rq=1 is unsupported and must terminate before any LMEM side effect.
        configure_main_case();
        flags[1] = 1'b1;
        expect_error_without_write(`NPU_ERR_UNSUPPORTED);

        // K dimension mismatch between X and W.
        configure_main_case();
        w_desc = make_tr_desc(MAIN_W_BASE, 1'b0, 4'd0,
                              16'd1, 16'd4, 16'd1, 16'd2);
        expect_error_without_write(`NPU_ERR_SHAPE);

        // Missing TR word3 must be rejected even though CONTINUOUS ignores the
        // stored stride payloads; descriptor completeness is still mandatory.
        configure_main_case();
        x_words_valid = 5'b00111;
        expect_error_without_write(`NPU_ERR_DESC_INCOMPLETE);

        // The complete 2x2 E32 destination range crosses the LMEM boundary.
        configure_main_case();
        dst_desc = make_tr_desc(LMEM_BYTES - 4, 1'b1, 4'd2,
                                16'd1, 16'd2, 16'd1, 16'd2);
        expect_error_without_write(`NPU_ERR_LMEM_BOUNDS);

        $display("[NPU-MM2][PASS] continuous NN signed/unsigned arithmetic, little-endian results, protocol, and negative guards");
        $finish;
    end

endmodule
