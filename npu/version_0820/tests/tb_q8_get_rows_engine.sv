`timescale 1ns/1ps
`default_nettype none

// Self-checking raw-bit GMEM verification for TensorNpuQ8GetRowsEngine.
// Numeric expectations are frozen IEEE-754 bit patterns.  The testbench uses
// no real/shortreal, DPI, host floating point, assertions, trace, or waveform.
module tb_q8_get_rows_engine;

    localparam integer MAX_D   = 1024;
    localparam integer MAX_IDS = 16;
    localparam integer ID_COUNT_W = $clog2(MAX_IDS + 1);
    localparam integer D_COUNT_W  = $clog2(MAX_D + 1);
    localparam integer MEM_BYTES  = 32768;
    localparam logic [63:0] MEM_BASE = 64'h0000_0000_0000_1000;
    localparam logic [63:0] MEM_LIMIT = 64'h0000_0000_0000_9000;

    localparam logic [5:0] ST_ID_REQ        = 6'd4;
    localparam logic [5:0] ST_ID_WAIT       = 6'd5;
    localparam logic [5:0] ST_BLOCK_REQ     = 6'd9;
    localparam logic [5:0] ST_BLOCK_WAIT    = 6'd10;
    localparam logic [5:0] ST_DEQUANT_RUN   = 6'd12;
    localparam logic [5:0] ST_OUTPUT_STREAM = 6'd15;
    localparam logic [5:0] ST_GMEM_DRAIN    = 6'd18;

    localparam logic [4:0] ERR_HEADER          = 5'd1;
    localparam logic [4:0] ERR_INDEX_ADDRESS   = 5'd2;
    localparam logic [4:0] ERR_ID_RANGE        = 5'd3;
    localparam logic [4:0] ERR_ROW_ADDRESS     = 5'd4;
    localparam logic [4:0] ERR_GMEM_RESPONSE   = 5'd5;
    localparam logic [4:0] ERR_CHILD           = 5'd6;
    localparam logic [4:0] ERR_CHILD_PROTOCOL  = 5'd7;
    localparam logic [4:0] ERR_STALL_TIMEOUT   = 5'd8;
    localparam logic [4:0] ERR_COMMAND_TIMEOUT = 5'd9;

    reg clk_i;
    reg rst_i;
    reg start_i;
    wire ready_o;
    wire busy_o;
    reg [63:0] src_slice_base_i;
    reg [63:0] idx_slice_base_i;
    reg [63:0] gmem_floor_i;
    reg [63:0] gmem_limit_i;
    reg [31:0] source_row_count_i;
    reg [ID_COUNT_W-1:0] index_count_i;
    reg [D_COUNT_W-1:0] element_count_i;
    reg [63:0] src_row_stride_i;
    reg [63:0] idx_stride_i;

    wire gmem_req_valid_o;
    wire gmem_req_ready_i;
    wire gmem_req_write_o;
    wire [63:0] gmem_req_addr_o;
    wire [63:0] gmem_req_wdata_o;
    wire [7:0] gmem_req_wstrb_o;
    reg gmem_rsp_valid_i;
    wire gmem_rsp_ready_o;
    reg [63:0] gmem_rsp_rdata_i;
    reg gmem_rsp_error_i;

    wire out_valid_o;
    reg out_ready_i;
    wire [31:0] out_bits_o;
    wire [ID_COUNT_W-1:0] out_id_position_o;
    wire [31:0] out_source_id_o;
    wire [D_COUNT_W-1:0] out_lane_index_o;
    wire out_row_last_o;
    wire out_last_o;

    wire done_o;
    wire error_o;
    wire [4:0] error_code_o;
    wire [31:0] ids_scanned_o;
    wire [31:0] blocks_done_o;
    wire [31:0] outputs_emitted_o;
    wire [31:0] gmem_beats_o;
    wire [31:0] payload_bytes_o;
    wire [31:0] active_cycles_o;

    reg [7:0] gmem [0:MEM_BYTES-1];
    reg allow_requests_q;
    reg request_backpressure_q;
    reg pending_q;
    reg [63:0] pending_addr_q;
    integer pending_delay_q;
    integer response_delay_q;
    reg inject_error_enable_q;
    reg inject_error_consumed_q;
    reg [63:0] inject_error_addr_q;

    integer cycle_count;
    integer accepted_request_count;
    integer accepted_index_request_count;
    integer accepted_source_request_count;
    integer observed_output_handshakes;
    integer expected_error_cases;
    integer drain_error_cases;
    integer successful_recovery_cases;
    integer reset_cancel_cases;
    integer bus_lane;
    wire [14:0] pending_memory_base_w;

    reg [63:0] watch_addr0_q;
    reg [63:0] watch_addr1_q;
    reg [63:0] watch_addr2_q;
    reg [63:0] watch_addr3_q;
    reg watch_addr0_seen_q;
    reg watch_addr1_seen_q;
    reg watch_addr2_seen_q;
    reg watch_addr3_seen_q;

    reg request_hold_q;
    reg [63:0] held_request_addr_q;
    reg held_request_write_q;
    reg [63:0] held_request_wdata_q;
    reg [7:0] held_request_wstrb_q;
    reg output_hold_q;
    reg [31:0] held_output_bits_q;
    reg [ID_COUNT_W-1:0] held_output_position_q;
    reg [31:0] held_output_source_q;
    reg [D_COUNT_W-1:0] held_output_lane_q;
    reg held_output_row_last_q;
    reg held_output_last_q;

    TensorNpuQ8GetRowsEngine #(
        .MAX_D                  (MAX_D),
        .MAX_IDS                (MAX_IDS),
        .STALL_TIMEOUT_CYCLES   (512),
        .COMMAND_TIMEOUT_CYCLES (200000)
    ) dut (
        .clk_i                 (clk_i),
        .rst_i                 (rst_i),
        .start_i               (start_i),
        .ready_o               (ready_o),
        .busy_o                (busy_o),
        .src_slice_base_i      (src_slice_base_i),
        .idx_slice_base_i      (idx_slice_base_i),
        .gmem_floor_i          (gmem_floor_i),
        .gmem_limit_i          (gmem_limit_i),
        .source_row_count_i    (source_row_count_i),
        .index_count_i         (index_count_i),
        .element_count_i       (element_count_i),
        .src_row_stride_i      (src_row_stride_i),
        .idx_stride_i          (idx_stride_i),
        .gmem_req_valid_o      (gmem_req_valid_o),
        .gmem_req_ready_i      (gmem_req_ready_i),
        .gmem_req_write_o      (gmem_req_write_o),
        .gmem_req_addr_o       (gmem_req_addr_o),
        .gmem_req_wdata_o      (gmem_req_wdata_o),
        .gmem_req_wstrb_o      (gmem_req_wstrb_o),
        .gmem_rsp_valid_i      (gmem_rsp_valid_i),
        .gmem_rsp_ready_o      (gmem_rsp_ready_o),
        .gmem_rsp_rdata_i      (gmem_rsp_rdata_i),
        .gmem_rsp_error_i      (gmem_rsp_error_i),
        .out_valid_o           (out_valid_o),
        .out_ready_i           (out_ready_i),
        .out_bits_o            (out_bits_o),
        .out_id_position_o     (out_id_position_o),
        .out_source_id_o       (out_source_id_o),
        .out_lane_index_o      (out_lane_index_o),
        .out_row_last_o        (out_row_last_o),
        .out_last_o            (out_last_o),
        .done_o                (done_o),
        .error_o               (error_o),
        .error_code_o          (error_code_o),
        .ids_scanned_o         (ids_scanned_o),
        .blocks_done_o         (blocks_done_o),
        .outputs_emitted_o     (outputs_emitted_o),
        .gmem_beats_o          (gmem_beats_o),
        .payload_bytes_o       (payload_bytes_o),
        .active_cycles_o       (active_cycles_o)
    );

    initial clk_i = 1'b0;
    always #5 clk_i <= ~clk_i;

    assign gmem_req_ready_i = allow_requests_q
                            && !pending_q
                            && !gmem_rsp_valid_i
                            && (!request_backpressure_q
                                || (cycle_count[2:0] != 3'd2));
    assign pending_memory_base_w = pending_addr_q[14:0]
                                      - MEM_BASE[14:0];

    task automatic fail_case(input string reason);
        begin
            $display("[NPU-Q8-GET-ROWS][FAIL] %s cycle=%0d state=%0d req=%0d idx_req=%0d src_req=%0d out=%0d err=%0d",
                     reason, cycle_count, dut.state_q,
                     accepted_request_count, accepted_index_request_count,
                     accepted_source_request_count,
                     observed_output_handshakes, error_code_o);
            $display("[NPU-Q8-GET-ROWS][FAIL-EVIDENCE] ids=%0d blocks=%0d emitted=%0d beats=%0d payload=%0d watch=%0b%0b%0b%0b active=%0d",
                     ids_scanned_o, blocks_done_o, outputs_emitted_o,
                     gmem_beats_o, payload_bytes_o,
                     watch_addr0_seen_q, watch_addr1_seen_q,
                     watch_addr2_seen_q, watch_addr3_seen_q,
                     active_cycles_o);
            $fatal(1);
        end
    endtask

    // Single-outstanding GMEM model.  Data bytes are returned in increasing
    // absolute address order; no arithmetic oracle is computed here.
    always @(posedge clk_i) begin
        if (rst_i) begin
            pending_q                     <= 1'b0;
            pending_addr_q                <= 64'b0;
            pending_delay_q               <= 0;
            gmem_rsp_valid_i              <= 1'b0;
            gmem_rsp_rdata_i              <= 64'b0;
            gmem_rsp_error_i              <= 1'b0;
            inject_error_consumed_q       <= 1'b0;
            accepted_request_count        <= 0;
            accepted_index_request_count  <= 0;
            accepted_source_request_count <= 0;
            watch_addr0_seen_q             <= 1'b0;
            watch_addr1_seen_q             <= 1'b0;
            watch_addr2_seen_q             <= 1'b0;
            watch_addr3_seen_q             <= 1'b0;
        end else begin
            if (gmem_rsp_valid_i && gmem_rsp_ready_o) begin
                gmem_rsp_valid_i <= 1'b0;
                gmem_rsp_error_i <= 1'b0;
                pending_q        <= 1'b0;
            end

            if (pending_q && !gmem_rsp_valid_i) begin
                if (pending_delay_q == 0) begin
                    if ((pending_addr_q < MEM_BASE)
                            || ((pending_addr_q + 64'd8) > MEM_LIMIT)) begin
                        fail_case("GMEM model received out-of-range address");
                    end
                    for (bus_lane = 0; bus_lane < 8;
                            bus_lane = bus_lane + 1) begin
                        gmem_rsp_rdata_i[{bus_lane[2:0], 3'b000} +: 8]
                            <= gmem[pending_memory_base_w
                                    + {12'b0, bus_lane[2:0]}];
                    end
                    gmem_rsp_error_i <= inject_error_enable_q
                                      && !inject_error_consumed_q
                                      && (pending_addr_q
                                          == inject_error_addr_q);
                    if (inject_error_enable_q
                            && !inject_error_consumed_q
                            && (pending_addr_q == inject_error_addr_q)) begin
                        inject_error_consumed_q <= 1'b1;
                    end
                    gmem_rsp_valid_i <= 1'b1;
                end else begin
                    pending_delay_q <= pending_delay_q - 1;
                end
            end

            if (gmem_req_valid_o && gmem_req_ready_i) begin
                if (pending_q || gmem_rsp_valid_i) begin
                    fail_case("more than one GMEM transaction outstanding");
                end
                if (gmem_req_write_o || (gmem_req_wdata_o != 64'b0)
                        || (gmem_req_wstrb_o != 8'b0)
                        || (gmem_req_addr_o[2:0] != 3'b000)) begin
                    fail_case("GMEM read request payload malformed");
                end
                pending_q         <= 1'b1;
                pending_addr_q    <= gmem_req_addr_o;
                pending_delay_q   <= response_delay_q;
                accepted_request_count <= accepted_request_count + 1;
                if (dut.state_q == ST_ID_REQ) begin
                    accepted_index_request_count
                        <= accepted_index_request_count + 1;
                end else if (dut.state_q == ST_BLOCK_REQ) begin
                    accepted_source_request_count
                        <= accepted_source_request_count + 1;
                    if ((ids_scanned_o
                            != {{(32-ID_COUNT_W){1'b0}}, index_count_i})
                            || (dut.row_preflight_pos_q
                                != (index_count_i - 1'b1))) begin
                        fail_case("source request preceded full id/row preflight");
                    end
                end else begin
                    fail_case("GMEM request accepted outside request owner state");
                end

                if (gmem_req_addr_o == watch_addr0_q)
                    watch_addr0_seen_q <= 1'b1;
                if (gmem_req_addr_o == watch_addr1_q)
                    watch_addr1_seen_q <= 1'b1;
                if (gmem_req_addr_o == watch_addr2_q)
                    watch_addr2_seen_q <= 1'b1;
                if (gmem_req_addr_o == watch_addr3_q)
                    watch_addr3_seen_q <= 1'b1;
            end
        end
    end

    // Protocol monitors are procedural equivalents of the required hold and
    // cardinality checks; this functional build intentionally uses no assert.
    always @(posedge clk_i) begin
        cycle_count <= cycle_count + 1;

        if (rst_i) begin
            request_hold_q              <= 1'b0;
            output_hold_q               <= 1'b0;
            observed_output_handshakes  <= 0;
        end else begin
            if (done_o && error_o)
                fail_case("done/error overlap");
            if (ready_o && busy_o)
                fail_case("ready/busy overlap");
            if (out_valid_o && (dut.state_q != ST_OUTPUT_STREAM))
                fail_case("output valid outside committed stream");
            if (gmem_rsp_ready_o
                    && (dut.state_q != ST_ID_WAIT)
                    && (dut.state_q != ST_BLOCK_WAIT)
                    && (dut.state_q != ST_GMEM_DRAIN))
                fail_case("response credit outside matching WAIT state");

            if (request_hold_q) begin
                if ((gmem_req_addr_o != held_request_addr_q)
                        || (gmem_req_write_o != held_request_write_q)
                        || (gmem_req_wdata_o != held_request_wdata_q)
                        || (gmem_req_wstrb_o != held_request_wstrb_q)) begin
                    fail_case("request payload changed under backpressure");
                end
            end
            if (gmem_req_valid_o && !gmem_req_ready_i) begin
                request_hold_q        <= 1'b1;
                held_request_addr_q   <= gmem_req_addr_o;
                held_request_write_q  <= gmem_req_write_o;
                held_request_wdata_q  <= gmem_req_wdata_o;
                held_request_wstrb_q  <= gmem_req_wstrb_o;
            end else begin
                request_hold_q <= 1'b0;
            end

            if (output_hold_q) begin
                if (!out_valid_o
                        || (out_bits_o != held_output_bits_q)
                        || (out_id_position_o != held_output_position_q)
                        || (out_source_id_o != held_output_source_q)
                        || (out_lane_index_o != held_output_lane_q)
                        || (out_row_last_o != held_output_row_last_q)
                        || (out_last_o != held_output_last_q)) begin
                    fail_case("output payload changed under backpressure");
                end
            end
            if (out_valid_o && !out_ready_i) begin
                output_hold_q          <= 1'b1;
                held_output_bits_q     <= out_bits_o;
                held_output_position_q <= out_id_position_o;
                held_output_source_q   <= out_source_id_o;
                held_output_lane_q     <= out_lane_index_o;
                held_output_row_last_q <= out_row_last_o;
                held_output_last_q     <= out_last_o;
            end else begin
                output_hold_q <= 1'b0;
            end

            if (out_valid_o && out_ready_i)
                observed_output_handshakes
                    <= observed_output_handshakes + 1;
        end

        if (cycle_count >= 400000)
            fail_case("global timeout");
    end

    task automatic poison_memory;
        integer fill_index;
        begin
            for (fill_index = 0; fill_index < MEM_BYTES;
                    fill_index = fill_index + 1) begin
                gmem[fill_index] = 8'hd3 ^ fill_index[7:0];
            end
        end
    endtask

    task automatic write_byte(
        input logic [63:0] address,
        input logic [7:0] data_bits
    );
        integer write_index;
        begin
            if ((address < MEM_BASE)
                    || (address >= MEM_LIMIT)) begin
                fail_case("write_byte address outside GMEM model");
            end
            write_index = address[31:0] - MEM_BASE[31:0];
            gmem[write_index] = data_bits;
        end
    endtask

    task automatic write_i32(
        input logic [63:0] address,
        input logic [31:0] data_bits
    );
        begin
            write_byte(address + 64'd0, data_bits[7:0]);
            write_byte(address + 64'd1, data_bits[15:8]);
            write_byte(address + 64'd2, data_bits[23:16]);
            write_byte(address + 64'd3, data_bits[31:24]);
        end
    endtask

    task automatic write_block(
        input logic [63:0] address,
        input logic [15:0] scale_bits,
        input logic [7:0] default_q
    );
        integer lane;
        begin
            write_byte(address + 64'd0, scale_bits[7:0]);
            write_byte(address + 64'd1, scale_bits[15:8]);
            for (lane = 0; lane < 32; lane = lane + 1)
                write_byte(address + 64'd2 + {32'b0, lane}, default_q);
        end
    endtask

    task automatic write_block_q(
        input logic [63:0] address,
        input integer lane,
        input logic [7:0] q_bits
    );
        begin
            write_byte(address + 64'd2 + {32'b0, lane}, q_bits);
        end
    endtask

    task automatic poison_row_padding(
        input logic [63:0] row_base,
        input integer packed_bytes,
        input integer stride_bytes
    );
        integer pad_index;
        begin
            for (pad_index = packed_bytes; pad_index < stride_bytes;
                    pad_index = pad_index + 1)
                write_byte(row_base + {32'b0, pad_index}, 8'ha5);
        end
    endtask

    task automatic clear_fault_controls;
        begin
            allow_requests_q        = 1'b1;
            request_backpressure_q  = 1'b1;
            response_delay_q        = 1;
            inject_error_enable_q   = 1'b0;
            inject_error_addr_q     = 64'b0;
            watch_addr0_q           = 64'hffff_ffff_ffff_fff8;
            watch_addr1_q           = 64'hffff_ffff_ffff_fff0;
            watch_addr2_q           = 64'hffff_ffff_ffff_ffe8;
            watch_addr3_q           = 64'hffff_ffff_ffff_ffe0;
        end
    endtask

    task automatic drive_base_command;
        begin
            src_slice_base_i    = 64'h0000_0000_0000_1400;
            idx_slice_base_i    = 64'h0000_0000_0000_1080;
            gmem_floor_i        = 64'h0000_0000_0000_1000;
            gmem_limit_i        = 64'h0000_0000_0000_3000;
            source_row_count_i  = 32'd3;
            index_count_i       = 1;
            element_count_i     = 32;
            src_row_stride_i    = 64'd64;
            idx_stride_i        = 64'd4;
        end
    endtask

    task automatic reset_engine;
        begin
            rst_i       = 1'b1;
            start_i     = 1'b0;
            out_ready_i = 1'b0;
            repeat (3) @(posedge clk_i);
            @(negedge clk_i);
            if (ready_o || busy_o || out_valid_o || done_o || error_o
                    || (active_cycles_o != 32'b0)) begin
                fail_case("reset did not quiesce engine");
            end
            rst_i = 1'b0;
            @(posedge clk_i);
            @(negedge clk_i);
            if (!ready_o || busy_o || out_valid_o || done_o || error_o)
                fail_case("engine did not reopen after reset");
        end
    endtask

    task automatic launch_command;
        begin
            start_i = 1'b0;
            while (!ready_o) begin
                @(posedge clk_i);
                @(negedge clk_i);
            end
            @(negedge clk_i);
            start_i = 1'b1;
            @(posedge clk_i);
            @(negedge clk_i);
            start_i = 1'b0;
            if (!busy_o || ready_o)
                fail_case("accepted command did not become resident");
        end
    endtask

    task automatic probe_busy_start;
        reg [63:0] resident_src;
        reg [63:0] resident_idx;
        reg [63:0] resident_row_stride;
        reg [63:0] resident_idx_stride;
        reg [ID_COUNT_W-1:0] resident_n;
        reg [D_COUNT_W-1:0] resident_d;
        begin
            resident_src        = dut.src_slice_base_q;
            resident_idx        = dut.idx_slice_base_q;
            resident_row_stride = dut.src_row_stride_q;
            resident_idx_stride = dut.idx_stride_q;
            resident_n          = dut.index_count_q;
            resident_d          = dut.element_count_q;

            src_slice_base_i = ~resident_src;
            idx_slice_base_i = ~resident_idx;
            src_row_stride_i = ~resident_row_stride;
            idx_stride_i     = ~resident_idx_stride;
            index_count_i    = ID_COUNT_W'(MAX_IDS);
            element_count_i  = D_COUNT_W'(MAX_D);
            start_i          = 1'b1;
            @(posedge clk_i);
            @(negedge clk_i);
            start_i = 1'b0;
            if ((dut.src_slice_base_q != resident_src)
                    || (dut.idx_slice_base_q != resident_idx)
                    || (dut.src_row_stride_q != resident_row_stride)
                    || (dut.idx_stride_q != resident_idx_stride)
                    || (dut.index_count_q != resident_n)
                    || (dut.element_count_q != resident_d)) begin
                fail_case("busy start mutated resident command");
            end

            src_slice_base_i = resident_src;
            idx_slice_base_i = resident_idx;
            src_row_stride_i = resident_row_stride;
            idx_stride_i     = resident_idx_stride;
            index_count_i    = resident_n;
            element_count_i  = resident_d;
        end
    endtask

    task automatic wait_for_error(
        input string case_name,
        input logic [4:0] expected_code,
        input integer max_wait_cycles
    );
        integer wait_cycles;
        begin
            wait_cycles = 0;
            out_ready_i = 1'b1;
            while (!error_o) begin
                if (out_valid_o || done_o
                        || (observed_output_handshakes != 0)) begin
                    fail_case({case_name, " leaked committed output"});
                end
                @(posedge clk_i);
                @(negedge clk_i);
                wait_cycles = wait_cycles + 1;
                if (wait_cycles > max_wait_cycles)
                    fail_case({case_name, " error terminal timeout"});
            end
            if (done_o || !busy_o || ready_o || out_valid_o
                    || (error_code_o != expected_code)
                    || (outputs_emitted_o != 32'b0)
                    || (observed_output_handshakes != 0)) begin
                fail_case({case_name, " malformed ERROR terminal"});
            end
            expected_error_cases = expected_error_cases + 1;
            @(posedge clk_i);
            @(negedge clk_i);
            if (error_o || done_o || busy_o || !ready_o || out_valid_o)
                fail_case({case_name, " ERROR was not exactly one cycle"});
            out_ready_i = 1'b0;
        end
    endtask

    task automatic wait_for_drain_error(
        input string case_name,
        input logic [4:0] expected_cause,
        input logic [4:0] expected_terminal_code,
        input integer max_wait_cycles
    );
        integer wait_cycles;
        integer accepted_requests_at_drain;
        reg [31:0] ids_at_drain;
        reg [31:0] blocks_at_drain;
        reg [31:0] emitted_at_drain;
        reg [31:0] beats_at_drain;
        reg [31:0] payload_at_drain;
        reg [31:0] active_at_drain;
        reg [31:0] command_at_drain;
        reg [31:0] stall_at_drain;
        reg [31:0] id_word_at_drain;
        reg [271:0] block_at_drain;
        begin
            wait_cycles = 0;
            out_ready_i = 1'b1;
            while (dut.state_q != ST_GMEM_DRAIN) begin
                if (error_o || done_o || out_valid_o
                        || (observed_output_handshakes != 0)) begin
                    fail_case({case_name,
                               " terminated/published before drain"});
                end
                @(posedge clk_i);
                @(negedge clk_i);
                wait_cycles = wait_cycles + 1;
                if (wait_cycles > max_wait_cycles)
                    fail_case({case_name, " drain entry timeout"});
            end

            if (!busy_o || ready_o || error_o || done_o
                    || gmem_req_valid_o || !gmem_rsp_ready_o
                    || out_valid_o || !pending_q
                    || (dut.drain_error_code_q != expected_cause)) begin
                fail_case({case_name, " malformed drain entry"});
            end

            accepted_requests_at_drain = accepted_request_count;
            ids_at_drain       = ids_scanned_o;
            blocks_at_drain    = blocks_done_o;
            emitted_at_drain   = outputs_emitted_o;
            beats_at_drain     = gmem_beats_o;
            payload_at_drain   = payload_bytes_o;
            active_at_drain    = active_cycles_o;
            command_at_drain   = dut.command_cycles_q;
            stall_at_drain     = dut.stall_cycles_q;
            id_word_at_drain   = dut.id_word_q;
            block_at_drain     = dut.block_buffer_q;

            wait_cycles = 0;
            while (!error_o) begin
                if ((dut.state_q != ST_GMEM_DRAIN)
                        || gmem_req_valid_o || !gmem_rsp_ready_o
                        || out_valid_o || done_o
                        || (dut.drain_error_code_q != expected_cause)
                        || (accepted_request_count
                            != accepted_requests_at_drain)
                        || (ids_scanned_o != ids_at_drain)
                        || (blocks_done_o != blocks_at_drain)
                        || (outputs_emitted_o != emitted_at_drain)
                        || (gmem_beats_o != beats_at_drain)
                        || (payload_bytes_o != payload_at_drain)
                        || (active_cycles_o != active_at_drain)
                        || (dut.command_cycles_q != command_at_drain)
                        || (dut.stall_cycles_q != stall_at_drain)
                        || (dut.id_word_q != id_word_at_drain)
                        || (dut.block_buffer_q != block_at_drain)
                        || (observed_output_handshakes != 0)) begin
                    fail_case({case_name,
                               " drain changed resident transaction"});
                end
                @(posedge clk_i);
                @(negedge clk_i);
                wait_cycles = wait_cycles + 1;
                if (wait_cycles > max_wait_cycles)
                    fail_case({case_name, " late response timeout"});
            end

            if (done_o || !busy_o || ready_o || out_valid_o
                    || (error_code_o != expected_terminal_code)
                    || pending_q || gmem_rsp_valid_i
                    || (outputs_emitted_o != 32'b0)
                    || (observed_output_handshakes != 0)) begin
                fail_case({case_name,
                           " drain terminal/outstanding mismatch"});
            end
            expected_error_cases = expected_error_cases + 1;
            drain_error_cases    = drain_error_cases + 1;
            @(posedge clk_i);
            @(negedge clk_i);
            if (error_o || done_o || busy_o || !ready_o || out_valid_o
                    || pending_q || gmem_rsp_valid_i) begin
                fail_case({case_name,
                           " drained ERROR did not reopen cleanly"});
            end
            out_ready_i = 1'b0;
        end
    endtask

    function automatic logic [31:0] canonical_expected(
        input integer position,
        input integer lane
    );
        integer source_id;
        begin
            case (position)
                0, 3: source_id = 1;
                1:    source_id = 0;
                default: source_id = 2;
            endcase

            canonical_expected = 32'h00000000;
            case (source_id)
                0: begin
                    if (lane == 0)
                        canonical_expected = 32'h40c00000;
                    else if (lane == 31)
                        canonical_expected = 32'hc1000000;
                end
                1: begin
                    if (lane >= 32)
                        canonical_expected = 32'h80000000;
                    case (lane)
                        0:  canonical_expected = 32'hc3000000;
                        1:  canonical_expected = 32'hbf800000;
                        2:  canonical_expected = 32'h00000000;
                        3:  canonical_expected = 32'h3f800000;
                        4:  canonical_expected = 32'h42fe0000;
                        32: canonical_expected = 32'h42800000;
                        33: canonical_expected = 32'h3f800000;
                        34: canonical_expected = 32'h3f000000;
                        35: canonical_expected = 32'h80000000;
                        36: canonical_expected = 32'hbf000000;
                        37: canonical_expected = 32'hbf800000;
                        38: canonical_expected = 32'hc27e0000;
                        default: begin
                        end
                    endcase
                end
                default: begin
                    if (lane >= 32)
                        canonical_expected = 32'h80000000;
                    if (lane == 0)
                        canonical_expected = 32'h33800000;
                    else if (lane == 1)
                        canonical_expected = 32'hb3800000;
                end
            endcase
        end
    endfunction

    function automatic logic [31:0] qwen_expected(input integer lane);
        begin
            qwen_expected = 32'h00000000;
            case (lane)
                480: qwen_expected = 32'h40c00000;
                511: qwen_expected = 32'hc1000000;
                960: qwen_expected = 32'hc2800000;
                961: qwen_expected = 32'h427e0000;
                962: qwen_expected = 32'hbf800000;
                default: begin
                end
            endcase
        end
    endfunction

    task automatic prepare_canonical_memory;
        logic [63:0] row0;
        logic [63:0] row1;
        logic [63:0] row2;
        begin
            poison_memory();
            drive_base_command();
            src_slice_base_i   = 64'h1194;
            idx_slice_base_i   = 64'h1026;
            gmem_floor_i       = 64'h1000;
            gmem_limit_i       = 64'h2000;
            source_row_count_i = 32'd3;
            index_count_i      = 5'd4;
            element_count_i    = 11'd64;
            src_row_stride_i   = 64'd96;
            idx_stride_i       = 64'd7;

            write_i32(64'h1026, 32'd1);
            write_i32(64'h102d, 32'd0);
            write_i32(64'h1034, 32'd2);
            write_i32(64'h103b, 32'd1);

            row0 = 64'h1194;
            row1 = 64'h11f4;
            row2 = 64'h1254;

            write_block(row0 + 64'd0, 16'h4000, 8'h00);
            write_block_q(row0 + 64'd0, 0, 8'h03);
            write_block_q(row0 + 64'd0, 31, 8'hfc);
            write_block(row0 + 64'd34, 16'h3c00, 8'h00);

            write_block(row1 + 64'd0, 16'h3c00, 8'h00);
            write_block_q(row1 + 64'd0, 0, 8'h80);
            write_block_q(row1 + 64'd0, 1, 8'hff);
            write_block_q(row1 + 64'd0, 2, 8'h00);
            write_block_q(row1 + 64'd0, 3, 8'h01);
            write_block_q(row1 + 64'd0, 4, 8'h7f);
            write_block(row1 + 64'd34, 16'hb800, 8'h00);
            write_block_q(row1 + 64'd34, 0, 8'h80);
            write_block_q(row1 + 64'd34, 1, 8'hfe);
            write_block_q(row1 + 64'd34, 2, 8'hff);
            write_block_q(row1 + 64'd34, 3, 8'h00);
            write_block_q(row1 + 64'd34, 4, 8'h01);
            write_block_q(row1 + 64'd34, 5, 8'h02);
            write_block_q(row1 + 64'd34, 6, 8'h7f);

            write_block(row2 + 64'd0, 16'h0001, 8'h00);
            write_block_q(row2 + 64'd0, 0, 8'h01);
            write_block_q(row2 + 64'd0, 1, 8'hff);
            write_block(row2 + 64'd34, 16'h8000, 8'h00);
            write_block_q(row2 + 64'd34, 0, 8'h01);

            poison_row_padding(row0, 68, 96);
            poison_row_padding(row1, 68, 96);
            poison_row_padding(row2, 68, 96);

            watch_addr0_q = 64'h11f0;
            watch_addr1_q = 64'h1200;
            watch_addr2_q = 64'hffff_ffff_ffff_ffe8;
            watch_addr3_q = 64'hffff_ffff_ffff_ffe0;
        end
    endtask

    task automatic run_canonical_success;
        integer position;
        integer lane;
        integer source_id;
        integer wait_cycles;
        begin
            clear_fault_controls();
            prepare_canonical_memory();
            reset_engine();
            launch_command();
            probe_busy_start();

            out_ready_i = 1'b0;
            for (position = 0; position < 4; position = position + 1) begin
                case (position)
                    0, 3: source_id = 1;
                    1:    source_id = 0;
                    default: source_id = 2;
                endcase
                for (lane = 0; lane < 64; lane = lane + 1) begin
                    wait_cycles = 0;
                    while (!out_valid_o) begin
                        if (done_o || error_o)
                            fail_case("canonical terminated before all lanes");
                        @(posedge clk_i);
                        @(negedge clk_i);
                        wait_cycles = wait_cycles + 1;
                        if (wait_cycles > 20000)
                            fail_case("canonical output wait timeout");
                    end
                    if ((out_id_position_o != ID_COUNT_W'(position))
                            || (out_source_id_o != source_id)
                            || (out_lane_index_o != D_COUNT_W'(lane))
                            || (out_bits_o
                                != canonical_expected(position, lane))
                            || (out_row_last_o != (lane == 63))
                            || (out_last_o
                                != ((position == 3) && (lane == 63)))) begin
                        fail_case("canonical raw-bit lane/order mismatch");
                    end

                    if (((position == 0) && (lane == 7))
                            || ((position == 2) && (lane == 33))) begin
                        repeat (3) begin
                            @(posedge clk_i);
                            @(negedge clk_i);
                        end
                    end
                    out_ready_i = 1'b1;
                    @(posedge clk_i);
                    @(negedge clk_i);
                    out_ready_i = 1'b0;
                end
            end

            if (!done_o || error_o || !busy_o || ready_o || out_valid_o)
                fail_case("canonical missing post-last DONE terminal");
            if ((ids_scanned_o != 32'd4)
                    || (blocks_done_o != 32'd8)
                    || (outputs_emitted_o != 32'd256)
                    || (gmem_beats_o != 32'd46)
                    || (payload_bytes_o != 32'd288)
                    || (accepted_request_count != 46)
                    || (accepted_index_request_count != 6)
                    || (accepted_source_request_count != 40)
                    || (observed_output_handshakes != 256)
                    || !watch_addr0_seen_q || !watch_addr1_seen_q) begin
                fail_case("canonical evidence counters/cross-line mismatch");
            end
            @(posedge clk_i);
            @(negedge clk_i);
            if (done_o || error_o || busy_o || !ready_o)
                fail_case("canonical DONE was not exactly one cycle");
        end
    endtask

    task automatic prepare_qwen_memory;
        integer block_number;
        logic [63:0] row_base;
        begin
            poison_memory();
            drive_base_command();
            src_slice_base_i   = 64'h1800;
            idx_slice_base_i   = 64'h1080;
            gmem_floor_i       = 64'h1000;
            gmem_limit_i       = 64'h3000;
            source_row_count_i = 32'd1;
            index_count_i      = 5'd1;
            element_count_i    = 11'd1024;
            src_row_stride_i   = 64'd1088;
            idx_stride_i       = 64'd4;
            write_i32(64'h1080, 32'd0);
            row_base = 64'h1800;
            for (block_number = 0; block_number < 32;
                    block_number = block_number + 1)
                write_block(row_base + (block_number * 34),
                            16'h3c00, 8'h00);

            write_block(row_base + (15 * 34), 16'h4000, 8'h00);
            write_block_q(row_base + (15 * 34), 0, 8'h03);
            write_block_q(row_base + (15 * 34), 31, 8'hfc);
            write_block(row_base + (30 * 34), 16'h3800, 8'h00);
            write_block_q(row_base + (30 * 34), 0, 8'h80);
            write_block_q(row_base + (30 * 34), 1, 8'h7f);
            write_block_q(row_base + (30 * 34), 2, 8'hfe);

            watch_addr0_q = 64'h19f8;
            watch_addr1_q = 64'h1a00;
            watch_addr2_q = 64'h1bf8;
            watch_addr3_q = 64'h1c00;
        end
    endtask

    task automatic run_qwen_success;
        integer lane;
        integer wait_cycles;
        begin
            clear_fault_controls();
            prepare_qwen_memory();
            reset_engine();
            launch_command();
            out_ready_i = 1'b0;

            for (lane = 0; lane < 1024; lane = lane + 1) begin
                wait_cycles = 0;
                while (!out_valid_o) begin
                    if (done_o || error_o)
                        fail_case("D1024 terminated before all lanes");
                    @(posedge clk_i);
                    @(negedge clk_i);
                    wait_cycles = wait_cycles + 1;
                    if (wait_cycles > 100000)
                        fail_case("D1024 output wait timeout");
                end
                if ((out_id_position_o != 0)
                        || (out_source_id_o != 0)
                        || (out_lane_index_o != D_COUNT_W'(lane))
                        || (out_bits_o != qwen_expected(lane))
                        || (out_row_last_o != (lane == 1023))
                        || (out_last_o != (lane == 1023))) begin
                    fail_case("D1024 raw-bit lane/order mismatch");
                end
                if ((lane == 480) || (lane == 960)) begin
                    repeat (2) begin
                        @(posedge clk_i);
                        @(negedge clk_i);
                    end
                end
                out_ready_i = 1'b1;
                @(posedge clk_i);
                @(negedge clk_i);
                out_ready_i = 1'b0;
            end

            if (!done_o || error_o
                    || (ids_scanned_o != 32'd1)
                    || (blocks_done_o != 32'd32)
                    || (outputs_emitted_o != 32'd1024)
                    || (gmem_beats_o != 32'd161)
                    || (payload_bytes_o != 32'd1092)
                    || (accepted_index_request_count != 1)
                    || (accepted_source_request_count != 160)
                    || (observed_output_handshakes != 1024)
                    || !watch_addr0_seen_q || !watch_addr1_seen_q
                    || !watch_addr2_seen_q || !watch_addr3_seen_q) begin
                fail_case("D1024 evidence counters/cross-line mismatch");
            end
            @(posedge clk_i);
            @(negedge clk_i);
        end
    endtask

    task automatic prepare_one_block;
        begin
            poison_memory();
            drive_base_command();
            write_i32(idx_slice_base_i, 32'd0);
            write_block(src_slice_base_i, 16'h3c00, 8'h00);
            write_block_q(src_slice_base_i, 0, 8'h01);
        end
    endtask

    task automatic run_one_block_recovery(input string case_name);
        integer lane;
        integer wait_cycles;
        integer requests_before;
        integer index_requests_before;
        integer source_requests_before;
        integer outputs_before;
        reg [31:0] expected_bits;
        begin
            if (!ready_o || busy_o || pending_q || gmem_rsp_valid_i)
                fail_case({case_name, " recovery did not start cleanly"});

            allow_requests_q       = 1'b1;
            request_backpressure_q = 1'b1;
            response_delay_q       = 1;
            inject_error_enable_q  = 1'b0;
            out_ready_i            = 1'b0;
            requests_before        = accepted_request_count;
            index_requests_before  = accepted_index_request_count;
            source_requests_before = accepted_source_request_count;
            outputs_before         = observed_output_handshakes;

            launch_command();
            for (lane = 0; lane < 32; lane = lane + 1) begin
                wait_cycles = 0;
                while (!out_valid_o) begin
                    if (done_o || error_o)
                        fail_case({case_name,
                                   " recovery terminated before output"});
                    @(posedge clk_i);
                    @(negedge clk_i);
                    wait_cycles = wait_cycles + 1;
                    if (wait_cycles > 2000)
                        fail_case({case_name,
                                   " recovery output timeout"});
                end
                expected_bits = (lane == 0)
                              ? 32'h3f800000 : 32'h00000000;
                if ((out_id_position_o != 0)
                        || (out_source_id_o != 0)
                        || (out_lane_index_o != D_COUNT_W'(lane))
                        || (out_bits_o != expected_bits)
                        || (out_row_last_o != (lane == 31))
                        || (out_last_o != (lane == 31))) begin
                    fail_case({case_name,
                               " recovery raw-bit lane mismatch"});
                end
                if (lane == 5) begin
                    repeat (2) begin
                        @(posedge clk_i);
                        @(negedge clk_i);
                    end
                end
                out_ready_i = 1'b1;
                @(posedge clk_i);
                @(negedge clk_i);
                out_ready_i = 1'b0;
            end

            if (!done_o || error_o || out_valid_o
                    || (ids_scanned_o != 32'd1)
                    || (blocks_done_o != 32'd1)
                    || (outputs_emitted_o != 32'd32)
                    || (gmem_beats_o != 32'd6)
                    || (payload_bytes_o != 32'd38)
                    || ((accepted_request_count - requests_before) != 6)
                    || ((accepted_index_request_count
                         - index_requests_before) != 1)
                    || ((accepted_source_request_count
                         - source_requests_before) != 5)
                    || ((observed_output_handshakes
                         - outputs_before) != 32)
                    || pending_q || gmem_rsp_valid_i) begin
                fail_case({case_name, " recovery evidence mismatch"});
            end
            @(posedge clk_i);
            @(negedge clk_i);
            if (done_o || error_o || busy_o || !ready_o
                    || pending_q || gmem_rsp_valid_i) begin
                fail_case({case_name,
                           " recovery DONE did not reopen cleanly"});
            end
            successful_recovery_cases = successful_recovery_cases + 1;
        end
    endtask

    task automatic run_wait_drain_cases;
        integer wait_cycles;
        begin
            // ID_WAIT response delay exceeds the complete stall window.  The
            // timeout cause is retained while the accepted beat is drained.
            clear_fault_controls();
            prepare_one_block();
            response_delay_q = 520;
            reset_engine();
            launch_command();
            wait_for_drain_error("id-wait-response-stall-drain",
                                 ERR_STALL_TIMEOUT,
                                 ERR_STALL_TIMEOUT, 700);
            run_one_block_recovery("id-wait-stall-recovery");

            // Reach BLOCK_REQ with a normal index response, then make the
            // accepted source beat late and inject command timeout in WAIT.
            clear_fault_controls();
            prepare_one_block();
            reset_engine();
            launch_command();
            wait_cycles = 0;
            while (dut.state_q != ST_BLOCK_REQ) begin
                @(posedge clk_i);
                @(negedge clk_i);
                wait_cycles = wait_cycles + 1;
                if (wait_cycles > 100)
                    fail_case("block-wait command drain request timeout");
            end
            response_delay_q = 100;
            wait_cycles = 0;
            while (!((dut.state_q == ST_BLOCK_WAIT) && pending_q)) begin
                @(posedge clk_i);
                @(negedge clk_i);
                wait_cycles = wait_cycles + 1;
                if (wait_cycles > 40)
                    fail_case("block-wait command drain accept timeout");
            end
            force dut.command_cycles_q = 32'd199999;
            @(posedge clk_i);
            @(negedge clk_i);
            release dut.command_cycles_q;
            wait_for_drain_error("block-wait-command-timeout-drain",
                                 ERR_COMMAND_TIMEOUT,
                                 ERR_COMMAND_TIMEOUT, 200);
            run_one_block_recovery("block-wait-command-recovery");

            // A late response error overrides the already-latched command
            // timeout cause, while still draining exactly the accepted beat.
            clear_fault_controls();
            prepare_one_block();
            response_delay_q        = 100;
            inject_error_enable_q   = 1'b1;
            inject_error_addr_q     = 64'h1080;
            reset_engine();
            launch_command();
            wait_cycles = 0;
            while (!((dut.state_q == ST_ID_WAIT) && pending_q)) begin
                @(posedge clk_i);
                @(negedge clk_i);
                wait_cycles = wait_cycles + 1;
                if (wait_cycles > 40)
                    fail_case("id-wait error override accept timeout");
            end
            force dut.command_cycles_q = 32'd199999;
            @(posedge clk_i);
            @(negedge clk_i);
            release dut.command_cycles_q;
            wait_for_drain_error("id-wait-error-overrides-timeout",
                                 ERR_COMMAND_TIMEOUT,
                                 ERR_GMEM_RESPONSE, 200);
            if (!inject_error_consumed_q)
                fail_case("late response error override was not injected");
            run_one_block_recovery("id-wait-error-override-recovery");
        end
    endtask

    task automatic run_header_error;
        begin
            clear_fault_controls();
            prepare_one_block();
            element_count_i = 11'd33;
            reset_engine();
            launch_command();
            wait_for_error("invalid-header-D33", ERR_HEADER, 20);
            if (accepted_request_count != 0)
                fail_case("invalid header issued GMEM request");
        end
    endtask

    task automatic run_invalid_id_cases;
        begin
            clear_fault_controls();
            poison_memory();
            drive_base_command();
            index_count_i     = 5'd3;
            element_count_i   = 11'd64;
            src_row_stride_i  = 64'd96;
            idx_stride_i      = 64'd7;
            write_i32(64'h1080, 32'd1);
            write_i32(64'h1087, 32'hffff_ffff);
            write_i32(64'h108e, 32'd2);
            reset_engine();
            launch_command();
            wait_for_error("negative-id", ERR_ID_RANGE, 200);
            if (accepted_source_request_count != 0)
                fail_case("negative id issued source-row request");

            clear_fault_controls();
            poison_memory();
            drive_base_command();
            index_count_i     = 5'd3;
            element_count_i   = 11'd64;
            src_row_stride_i  = 64'd96;
            idx_stride_i      = 64'd7;
            write_i32(64'h1080, 32'd1);
            write_i32(64'h1087, 32'd3);
            write_i32(64'h108e, 32'd2);
            reset_engine();
            launch_command();
            wait_for_error("id-equals-V", ERR_ID_RANGE, 200);
            if (accepted_source_request_count != 0)
                fail_case("id equal V issued source-row request");
        end
    endtask

    task automatic run_index_boundary_cases;
        begin
            clear_fault_controls();
            poison_memory();
            drive_base_command();
            gmem_floor_i     = 64'h1003;
            idx_slice_base_i = 64'h1004;
            write_i32(64'h1004, 32'd0);
            reset_engine();
            launch_command();
            wait_for_error("index-first-beat-below-floor",
                           ERR_INDEX_ADDRESS, 40);
            if (accepted_request_count != 0)
                fail_case("bad first index beat was requested");

            clear_fault_controls();
            poison_memory();
            drive_base_command();
            gmem_limit_i     = 64'h100b;
            idx_slice_base_i = 64'h1007;
            write_i32(64'h1007, 32'd0);
            reset_engine();
            launch_command();
            wait_for_error("index-last-beat-above-limit",
                           ERR_INDEX_ADDRESS, 40);
            if (accepted_request_count != 0)
                fail_case("bad last index beat was requested");
        end
    endtask

    task automatic run_row_address_cases;
        begin
            clear_fault_controls();
            poison_memory();
            drive_base_command();
            src_slice_base_i   = 64'hffff_ffff_ffff_fff0;
            src_row_stride_i   = 64'h40;
            source_row_count_i = 32'd2;
            gmem_limit_i       = 64'hffff_ffff_ffff_fff8;
            write_i32(idx_slice_base_i, 32'd1);
            reset_engine();
            launch_command();
            wait_for_error("row-multiply-add-wrap", ERR_ROW_ADDRESS, 100);
            if (accepted_source_request_count != 0)
                fail_case("wrapped row issued source request");

            clear_fault_controls();
            poison_memory();
            drive_base_command();
            gmem_floor_i       = 64'h1104;
            idx_slice_base_i   = 64'h1110;
            src_slice_base_i   = 64'h1104;
            write_i32(64'h1110, 32'd0);
            reset_engine();
            launch_command();
            wait_for_error("row-first-beat-below-floor",
                           ERR_ROW_ADDRESS, 100);
            if (accepted_source_request_count != 0)
                fail_case("bad first row beat was requested");

            clear_fault_controls();
            poison_memory();
            drive_base_command();
            gmem_limit_i       = 64'h112a;
            idx_slice_base_i   = 64'h1010;
            src_slice_base_i   = 64'h1108;
            write_i32(64'h1010, 32'd0);
            reset_engine();
            launch_command();
            wait_for_error("row-last-beat-above-limit",
                           ERR_ROW_ADDRESS, 100);
            if (accepted_source_request_count != 0)
                fail_case("bad last row beat was requested");
        end
    endtask

    task automatic run_gmem_error_cases;
        begin
            clear_fault_controls();
            prepare_one_block();
            inject_error_enable_q = 1'b1;
            inject_error_addr_q   = 64'h1080;
            reset_engine();
            launch_command();
            wait_for_error("index-response-error", ERR_GMEM_RESPONSE, 100);
            if ((accepted_index_request_count != 1)
                    || (accepted_source_request_count != 0)
                    || !inject_error_consumed_q)
                fail_case("index response error evidence mismatch");

            clear_fault_controls();
            prepare_one_block();
            inject_error_enable_q = 1'b1;
            inject_error_addr_q   = 64'h1400;
            reset_engine();
            launch_command();
            wait_for_error("block-response-error", ERR_GMEM_RESPONSE, 200);
            if ((accepted_source_request_count != 1)
                    || !inject_error_consumed_q)
                fail_case("block response error evidence mismatch");
        end
    endtask

    task automatic run_child_fault_cases;
        integer wait_cycles;
        begin
            clear_fault_controls();
            prepare_one_block();
            reset_engine();
            launch_command();
            wait_cycles = 0;
            while (dut.state_q != ST_DEQUANT_RUN) begin
                @(posedge clk_i);
                @(negedge clk_i);
                wait_cycles = wait_cycles + 1;
                if (wait_cycles > 200)
                    fail_case("child-fault injection point timeout");
            end
            force dut.child_error_w = 1'b1;
            force dut.child_error_code_w = 4'h3;
            @(posedge clk_i);
            @(negedge clk_i);
            release dut.child_error_w;
            release dut.child_error_code_w;
            wait_for_error("child-error", ERR_CHILD, 20);

            clear_fault_controls();
            prepare_one_block();
            reset_engine();
            launch_command();
            wait_cycles = 0;
            while (!((dut.state_q == ST_DEQUANT_RUN)
                    && dut.child_lane_valid_w)) begin
                @(posedge clk_i);
                @(negedge clk_i);
                wait_cycles = wait_cycles + 1;
                if (wait_cycles > 1000)
                    fail_case("child-cardinality injection point timeout");
            end
            force dut.child_lane_index_w = 6'd1;
            @(posedge clk_i);
            @(negedge clk_i);
            release dut.child_lane_index_w;
            wait_for_error("child-lane-cardinality",
                           ERR_CHILD_PROTOCOL, 20);
        end
    endtask

    task automatic run_watchdog_cases;
        integer wait_cycles;
        begin
            clear_fault_controls();
            prepare_one_block();
            allow_requests_q = 1'b0;
            reset_engine();
            launch_command();
            wait_cycles = 0;
            while (!((dut.state_q == ST_ID_REQ)
                    && (dut.stall_cycles_q >= 32'd511))) begin
                @(posedge clk_i);
                @(negedge clk_i);
                wait_cycles = wait_cycles + 1;
                if (wait_cycles > 600)
                    fail_case("stall-timeout priority point timeout");
            end
            // Ready arrives exactly when the watchdog is terminal.  Timeout
            // must win and the previously unaccepted request must not fire.
            request_backpressure_q = 1'b0;
            allow_requests_q = 1'b1;
            wait_for_error("request-stall-timeout", ERR_STALL_TIMEOUT, 20);
            if (accepted_request_count != 0)
                fail_case("stall timeout unexpectedly accepted request");

            clear_fault_controls();
            prepare_one_block();
            allow_requests_q = 1'b0;
            reset_engine();
            launch_command();
            wait_cycles = 0;
            while (dut.state_q != ST_ID_REQ) begin
                @(posedge clk_i);
                @(negedge clk_i);
                wait_cycles = wait_cycles + 1;
                if (wait_cycles > 40)
                    fail_case("command-timeout injection point timeout");
            end
            request_backpressure_q = 1'b0;
            allow_requests_q = 1'b1;
            force dut.command_cycles_q = 32'd199999;
            @(posedge clk_i);
            @(negedge clk_i);
            release dut.command_cycles_q;
            wait_for_error("command-timeout", ERR_COMMAND_TIMEOUT, 20);
            if (accepted_request_count != 0)
                fail_case("command timeout lost priority to request ready");
        end
    endtask

    task automatic run_resident_reset_case;
        integer wait_cycles;
        begin
            clear_fault_controls();
            prepare_one_block();
            element_count_i = 11'd64;
            src_row_stride_i = 64'd96;
            write_block(src_slice_base_i + 64'd34, 16'h3c00, 8'h00);
            reset_engine();
            launch_command();
            wait_cycles = 0;
            while (accepted_source_request_count == 0) begin
                @(posedge clk_i);
                @(negedge clk_i);
                wait_cycles = wait_cycles + 1;
                if (wait_cycles > 200)
                    fail_case("resident-reset injection point timeout");
            end
            rst_i = 1'b1;
            repeat (2) begin
                @(posedge clk_i);
                @(negedge clk_i);
                if (ready_o || busy_o || out_valid_o || done_o || error_o
                        || (observed_output_handshakes != 0)) begin
                    fail_case("resident reset leaked protocol state");
                end
            end
            rst_i = 1'b0;
            repeat (4) begin
                @(posedge clk_i);
                @(negedge clk_i);
                if (!ready_o || busy_o || out_valid_o || done_o || error_o)
                    fail_case("stale transaction survived resident reset");
            end
            reset_cancel_cases = reset_cancel_cases + 1;
        end
    endtask

    initial begin
        cycle_count                       = 0;
        accepted_request_count            = 0;
        accepted_index_request_count      = 0;
        accepted_source_request_count     = 0;
        observed_output_handshakes        = 0;
        expected_error_cases              = 0;
        drain_error_cases                 = 0;
        successful_recovery_cases         = 0;
        reset_cancel_cases                = 0;
        rst_i                             = 1'b1;
        start_i                           = 1'b0;
        out_ready_i                       = 1'b0;
        src_slice_base_i                  = 64'b0;
        idx_slice_base_i                  = 64'b0;
        gmem_floor_i                      = 64'b0;
        gmem_limit_i                      = 64'b0;
        source_row_count_i                = 32'b0;
        index_count_i                     = {ID_COUNT_W{1'b0}};
        element_count_i                   = {D_COUNT_W{1'b0}};
        src_row_stride_i                  = 64'b0;
        idx_stride_i                      = 64'b0;
        allow_requests_q                  = 1'b1;
        request_backpressure_q            = 1'b1;
        pending_q                         = 1'b0;
        pending_addr_q                    = 64'b0;
        pending_delay_q                   = 0;
        response_delay_q                  = 1;
        inject_error_enable_q             = 1'b0;
        inject_error_consumed_q           = 1'b0;
        inject_error_addr_q               = 64'b0;
        gmem_rsp_valid_i                  = 1'b0;
        gmem_rsp_rdata_i                  = 64'b0;
        gmem_rsp_error_i                  = 1'b0;
        watch_addr0_q                     = 64'hffff_ffff_ffff_fff8;
        watch_addr1_q                     = 64'hffff_ffff_ffff_fff0;
        watch_addr2_q                     = 64'hffff_ffff_ffff_ffe8;
        watch_addr3_q                     = 64'hffff_ffff_ffff_ffe0;
        watch_addr0_seen_q                = 1'b0;
        watch_addr1_seen_q                = 1'b0;
        watch_addr2_seen_q                = 1'b0;
        watch_addr3_seen_q                = 1'b0;
        request_hold_q                    = 1'b0;
        held_request_addr_q               = 64'b0;
        held_request_write_q              = 1'b0;
        held_request_wdata_q              = 64'b0;
        held_request_wstrb_q              = 8'b0;
        output_hold_q                     = 1'b0;
        held_output_bits_q                = 32'b0;
        held_output_position_q            = {ID_COUNT_W{1'b0}};
        held_output_source_q              = 32'b0;
        held_output_lane_q                = {D_COUNT_W{1'b0}};
        held_output_row_last_q            = 1'b0;
        held_output_last_q                = 1'b0;

        run_canonical_success();
        run_qwen_success();
        run_header_error();
        run_invalid_id_cases();
        run_index_boundary_cases();
        run_row_address_cases();
        run_gmem_error_cases();
        run_child_fault_cases();
        run_watchdog_cases();
        run_resident_reset_case();
        run_wait_drain_cases();

        if (expected_error_cases != 17)
            fail_case("negative-case terminal count mismatch");
        if (drain_error_cases != 3)
            fail_case("drained-error case count mismatch");
        if (successful_recovery_cases != 3)
            fail_case("post-drain recovery count mismatch");
        if (reset_cancel_cases != 1)
            fail_case("resident reset case count mismatch");

        $display("[NPU-Q8-GET-ROWS][INFO] canonical=ids4/blocks8/beats46/payload288/outputs256 D1024=blocks32/beats161/payload1092/outputs1024 original_v2_errors=14 drain_errors=%0d drain_recoveries=%0d total_errors=%0d reset_cancels=%0d single_outstanding=1 atomic_commit=1",
                 drain_error_cases, successful_recovery_cases,
                 expected_error_cases, reset_cancel_cases);
        $display("[NPU-Q8-GET-ROWS][PASS]");
        $finish;
    end

endmodule

`default_nettype wire
