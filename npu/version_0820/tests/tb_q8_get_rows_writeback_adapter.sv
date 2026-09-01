`timescale 1ns/1ps
`default_nettype none

// Directed raw-bit verification for the committed GET_ROWS_Q8_0 writeback
// slice.  No real/shortreal, DPI, host floating-point oracle, assertion,
// waveform or trace is used.
module tb_q8_get_rows_writeback_adapter;

    localparam integer MAX_D      = 64;
    localparam integer MAX_IDS    = 4;
    localparam integer ID_COUNT_W = $clog2(MAX_IDS + 1);
    localparam integer D_COUNT_W  = $clog2(MAX_D + 1);
    localparam integer MEM_BYTES  = 8192;

    localparam logic [63:0] MEM_BASE  = 64'h0000_0000_0000_1000;
    localparam logic [63:0] MEM_LIMIT = 64'h0000_0000_0000_3000;
    localparam logic [31:0] KERNEL_ID = 32'h514e0001;

    localparam logic [3:0] ST_GMEM_DRAIN = 4'd6;

    localparam logic [4:0] ERR_DESCRIPTOR      = 5'd1;
    localparam logic [4:0] ERR_DEST_BOUNDS     = 5'd4;
    localparam logic [4:0] ERR_OVERLAP         = 5'd5;
    localparam logic [4:0] ERR_ENGINE          = 5'd6;
    localparam logic [4:0] ERR_GMEM_RESPONSE   = 5'd8;
    localparam logic [4:0] ERR_STALL_TIMEOUT   = 5'd9;
    localparam logic [4:0] ENGINE_ERR_ID_RANGE = 5'd3;

    reg clk_i;
    reg rst_i;
    reg start_i;
    wire ready_o;
    wire busy_o;
    reg [63:0] command_id_i;
    reg dst_shadow_private_i;
    reg [63:0] src_slice_base_i;
    reg [63:0] idx_slice_base_i;
    reg [63:0] dst_slice_base_i;
    reg [63:0] dst_window_bytes_i;
    reg [63:0] gmem_floor_i;
    reg [63:0] gmem_limit_i;
    reg [31:0] source_row_count_i;
    reg [ID_COUNT_W-1:0] index_count_i;
    reg [D_COUNT_W-1:0] element_count_i;
    reg [63:0] src_row_stride_i;
    reg [63:0] idx_stride_i;
    reg [63:0] dst_row_stride_i;

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

    wire completion_valid_o;
    wire dst_commit_o;
    wire [63:0] completion_command_id_o;
    wire [31:0] completion_kernel_id_o;
    wire done_o;
    wire error_o;
    wire [4:0] error_code_o;
    wire [4:0] engine_error_code_o;
    wire [31:0] ids_scanned_o;
    wire [31:0] blocks_done_o;
    wire [31:0] outputs_accepted_o;
    wire [31:0] gmem_read_beats_o;
    wire [31:0] read_payload_bytes_o;
    wire [31:0] gmem_write_beats_o;
    wire [31:0] writes_completed_o;
    wire [31:0] write_bytes_o;
    wire [31:0] engine_active_cycles_o;
    wire [63:0] active_cycles_o;
    wire gmem_outstanding_o;

    reg [7:0] gmem [0:MEM_BYTES-1];
    reg allow_requests_q;
    reg request_backpressure_q;
    integer read_response_delay_q;
    integer write_response_delay_q;
    integer write_error_ordinal_q;
    reg check_write_order_q;

    reg pending_q;
    reg pending_write_q;
    reg [63:0] pending_addr_q;
    reg [63:0] pending_wdata_q;
    reg [7:0] pending_wstrb_q;
    integer pending_delay_q;
    integer pending_write_ordinal_q;

    integer global_cycles;
    integer accepted_read_requests;
    integer accepted_write_requests;
    integer successful_write_responses;
    integer completion_pulse_count;
    integer commit_pulse_count;
    reg drain_seen_q;

    reg request_hold_q;
    reg held_request_write_q;
    reg [63:0] held_request_addr_q;
    reg [63:0] held_request_wdata_q;
    reg [7:0] held_request_wstrb_q;

    integer bus_lane;

    TensorNpuQ8GetRowsWritebackAdapter #(
        .MAX_D                  (MAX_D),
        .MAX_IDS                (MAX_IDS),
        .STALL_TIMEOUT_CYCLES   (512),
        .COMMAND_TIMEOUT_CYCLES (200000)
    ) dut (
        .clk_i                    (clk_i),
        .rst_i                    (rst_i),
        .start_i                  (start_i),
        .ready_o                  (ready_o),
        .busy_o                   (busy_o),
        .command_id_i             (command_id_i),
        .dst_shadow_private_i     (dst_shadow_private_i),
        .src_slice_base_i         (src_slice_base_i),
        .idx_slice_base_i         (idx_slice_base_i),
        .dst_slice_base_i         (dst_slice_base_i),
        .dst_window_bytes_i       (dst_window_bytes_i),
        .gmem_floor_i             (gmem_floor_i),
        .gmem_limit_i             (gmem_limit_i),
        .source_row_count_i       (source_row_count_i),
        .index_count_i            (index_count_i),
        .element_count_i          (element_count_i),
        .src_row_stride_i         (src_row_stride_i),
        .idx_stride_i             (idx_stride_i),
        .dst_row_stride_i         (dst_row_stride_i),
        .gmem_req_valid_o         (gmem_req_valid_o),
        .gmem_req_ready_i         (gmem_req_ready_i),
        .gmem_req_write_o         (gmem_req_write_o),
        .gmem_req_addr_o          (gmem_req_addr_o),
        .gmem_req_wdata_o         (gmem_req_wdata_o),
        .gmem_req_wstrb_o         (gmem_req_wstrb_o),
        .gmem_rsp_valid_i         (gmem_rsp_valid_i),
        .gmem_rsp_ready_o         (gmem_rsp_ready_o),
        .gmem_rsp_rdata_i         (gmem_rsp_rdata_i),
        .gmem_rsp_error_i         (gmem_rsp_error_i),
        .completion_valid_o       (completion_valid_o),
        .dst_commit_o             (dst_commit_o),
        .completion_command_id_o  (completion_command_id_o),
        .completion_kernel_id_o   (completion_kernel_id_o),
        .done_o                    (done_o),
        .error_o                   (error_o),
        .error_code_o              (error_code_o),
        .engine_error_code_o       (engine_error_code_o),
        .ids_scanned_o             (ids_scanned_o),
        .blocks_done_o             (blocks_done_o),
        .outputs_accepted_o        (outputs_accepted_o),
        .gmem_read_beats_o         (gmem_read_beats_o),
        .read_payload_bytes_o      (read_payload_bytes_o),
        .gmem_write_beats_o        (gmem_write_beats_o),
        .writes_completed_o        (writes_completed_o),
        .write_bytes_o             (write_bytes_o),
        .engine_active_cycles_o    (engine_active_cycles_o),
        .active_cycles_o           (active_cycles_o),
        .gmem_outstanding_o        (gmem_outstanding_o)
    );

    initial clk_i = 1'b0;
    always #5 clk_i <= ~clk_i;

    assign gmem_req_ready_i = allow_requests_q
                            && !pending_q
                            && !gmem_rsp_valid_i
                            && (!request_backpressure_q
                                || (global_cycles[2:0] != 3'd2));

    function automatic logic [31:0] expected_source_bits(
        input integer source_id,
        input integer lane
    );
        begin
            expected_source_bits = 32'h00000000;
            if (source_id == 0) begin
                case (lane)
                    0:  expected_source_bits = 32'h3f800000;
                    1:  expected_source_bits = 32'hbf800000;
                    31: expected_source_bits = 32'h42fe0000;
                    default: begin
                    end
                endcase
            end else begin
                expected_source_bits = 32'h80000000;
                case (lane)
                    0:  expected_source_bits = 32'h3f800000;
                    1:  expected_source_bits = 32'hbf800000;
                    31: expected_source_bits = 32'h42800000;
                    default: begin
                    end
                endcase
            end
        end
    endfunction

    function automatic logic [31:0] expected_position_bits(
        input integer position,
        input integer lane
    );
        integer source_id;
        begin
            source_id = (position == 1) ? 0 : 1;
            expected_position_bits = expected_source_bits(source_id, lane);
        end
    endfunction

    // Pure combinational monitor expressions.  Keeping these outside the
    // clocked GMEM model avoids sequential blocking assignments while still
    // checking the request accepted on the current cycle.
    wire response_error_w = pending_write_q
                         && (write_error_ordinal_q >= 0)
                         && (pending_write_ordinal_q == write_error_ordinal_q);
    wire [31:0] memory_index_w = pending_addr_q[31:0]
                               - MEM_BASE[31:0];
    wire [31:0] write_position_w = accepted_write_requests / 32;
    wire [31:0] write_lane_w = accepted_write_requests % 32;
    wire [63:0] expected_semantic_addr_w = dst_slice_base_i
        + (write_position_w * dst_row_stride_i)
        + (write_lane_w * 4);
    wire [63:0] expected_request_addr_w = {
        expected_semantic_addr_w[63:3], 3'b000
    };
    wire [31:0] expected_write_bits_w = expected_position_bits(
        write_position_w, write_lane_w
    );
    wire [63:0] expected_write_data_w = expected_semantic_addr_w[2]
        ? {expected_write_bits_w, 32'b0}
        : {32'b0, expected_write_bits_w};
    wire [7:0] expected_write_strb_w = expected_semantic_addr_w[2]
        ? 8'hf0 : 8'h0f;

    task automatic fail_case(input string reason);
        begin
            $display("[NPU-Q8-GET-ROWS-WRITEBACK][FAIL] %s cycle=%0d state=%0d read_req=%0d write_req=%0d write_rsp=%0d err=%0d child_err=%0d",
                     reason, global_cycles, dut.state_q,
                     accepted_read_requests, accepted_write_requests,
                     successful_write_responses, error_code_o,
                     engine_error_code_o);
            $display("[NPU-Q8-GET-ROWS-WRITEBACK][FAIL-EVIDENCE] ids=%0d blocks=%0d outputs=%0d read_beats=%0d read_bytes=%0d write_beats=%0d writes_done=%0d write_bytes=%0d commit=%0d completion=%0d pending=%0b active=%0d",
                     ids_scanned_o, blocks_done_o, outputs_accepted_o,
                     gmem_read_beats_o, read_payload_bytes_o,
                     gmem_write_beats_o, writes_completed_o, write_bytes_o,
                     commit_pulse_count, completion_pulse_count, pending_q,
                     active_cycles_o);
            $fatal(1);
        end
    endtask

    // Single-outstanding raw-byte GMEM model.  Writes update only their
    // strobed private bytes and only when the modeled response is successful.
    always @(posedge clk_i) begin
        if (rst_i) begin
            pending_q                    <= 1'b0;
            pending_write_q              <= 1'b0;
            pending_addr_q               <= 64'b0;
            pending_wdata_q              <= 64'b0;
            pending_wstrb_q              <= 8'b0;
            pending_delay_q              <= 0;
            pending_write_ordinal_q      <= -1;
            gmem_rsp_valid_i             <= 1'b0;
            gmem_rsp_rdata_i             <= 64'b0;
            gmem_rsp_error_i             <= 1'b0;
            accepted_read_requests       <= 0;
            accepted_write_requests      <= 0;
            successful_write_responses   <= 0;
        end else begin
            if (gmem_rsp_valid_i && gmem_rsp_ready_o) begin
                if (pending_write_q && !gmem_rsp_error_i)
                    successful_write_responses
                        <= successful_write_responses + 1;
                gmem_rsp_valid_i <= 1'b0;
                gmem_rsp_error_i <= 1'b0;
                pending_q        <= 1'b0;
            end

            if (pending_q && !gmem_rsp_valid_i) begin
                if (pending_delay_q == 0) begin
                    if ((pending_addr_q < MEM_BASE)
                            || ((pending_addr_q + 64'd8) > MEM_LIMIT)) begin
                        fail_case("GMEM model received out-of-range beat");
                    end
                    gmem_rsp_error_i <= response_error_w;
                    gmem_rsp_rdata_i <= 64'b0;
                    if (pending_write_q) begin
                        if (!response_error_w) begin
                            for (bus_lane = 0; bus_lane < 8;
                                    bus_lane = bus_lane + 1) begin
                                if (pending_wstrb_q[bus_lane]) begin
                                    gmem[memory_index_w + bus_lane]
                                        <= pending_wdata_q[
                                            {bus_lane[2:0], 3'b000} +: 8
                                        ];
                                end
                            end
                        end
                    end else begin
                        for (bus_lane = 0; bus_lane < 8;
                                bus_lane = bus_lane + 1) begin
                            gmem_rsp_rdata_i[
                                {bus_lane[2:0], 3'b000} +: 8
                            ] <= gmem[memory_index_w + bus_lane];
                        end
                    end
                    gmem_rsp_valid_i <= 1'b1;
                end else begin
                    pending_delay_q <= pending_delay_q - 1;
                end
            end

            if (gmem_req_valid_o && gmem_req_ready_i) begin
                if (pending_q || gmem_rsp_valid_i)
                    fail_case("more than one GMEM transaction outstanding");
                if (gmem_req_addr_o[2:0] != 3'b000)
                    fail_case("unaligned GMEM request address");
                pending_q       <= 1'b1;
                pending_write_q <= gmem_req_write_o;
                pending_addr_q  <= gmem_req_addr_o;
                pending_wdata_q <= gmem_req_wdata_o;
                pending_wstrb_q <= gmem_req_wstrb_o;
                if (gmem_req_write_o) begin
                    if (!((gmem_req_wstrb_o == 8'h0f)
                            || (gmem_req_wstrb_o == 8'hf0))) begin
                        fail_case("write request did not select one FP32 lane");
                    end
                    pending_delay_q <= write_response_delay_q;
                    pending_write_ordinal_q <= accepted_write_requests;

                    if (check_write_order_q) begin
                        if ((expected_semantic_addr_w[1:0] != 2'b00)
                                || (gmem_req_addr_o
                                != expected_request_addr_w)
                                || (gmem_req_wdata_o
                                    != expected_write_data_w)
                                || (gmem_req_wstrb_o
                                    != expected_write_strb_w)) begin
                            fail_case("write address/raw-bit/order mismatch");
                        end
                    end
                    accepted_write_requests
                        <= accepted_write_requests + 1;
                end else begin
                    if ((gmem_req_wdata_o != 64'b0)
                            || (gmem_req_wstrb_o != 8'b0)) begin
                        fail_case("read request carried write payload");
                    end
                    pending_delay_q <= read_response_delay_q;
                    pending_write_ordinal_q <= -1;
                    accepted_read_requests
                        <= accepted_read_requests + 1;
                end
            end
        end
    end

    // Procedural protocol monitors keep the release-style build free of RTL
    // assertions while checking the same observable invariants.
    always @(posedge clk_i) begin
        global_cycles <= global_cycles + 1;
        if (rst_i) begin
            request_hold_q          <= 1'b0;
            completion_pulse_count  <= 0;
            commit_pulse_count      <= 0;
            drain_seen_q            <= 1'b0;
        end else begin
            if (done_o && error_o)
                fail_case("done/error overlap");
            if (ready_o && busy_o)
                fail_case("ready/busy overlap");
            if (completion_valid_o != (done_o || error_o))
                fail_case("completion validity did not match terminal pulse");
            if (completion_valid_o && gmem_outstanding_o)
                fail_case("terminal completion retained a GMEM response credit");
            if (dst_commit_o != done_o)
                fail_case("destination publication was not success-only");
            if (!completion_valid_o
                    && ((completion_command_id_o != 64'b0)
                        || (completion_kernel_id_o != 32'b0))) begin
                fail_case("stale completion identity outside terminal");
            end
            if (completion_valid_o) begin
                completion_pulse_count <= completion_pulse_count + 1;
                if ((completion_command_id_o != command_id_i)
                        || (completion_kernel_id_o != KERNEL_ID)) begin
                    fail_case("completion identity mismatch");
                end
            end
            if (dst_commit_o)
                commit_pulse_count <= commit_pulse_count + 1;
            if (dut.state_q == ST_GMEM_DRAIN)
                drain_seen_q <= 1'b1;

            if (request_hold_q) begin
                if (!gmem_req_valid_o
                        || (gmem_req_write_o != held_request_write_q)
                        || (gmem_req_addr_o != held_request_addr_q)
                        || (gmem_req_wdata_o != held_request_wdata_q)
                        || (gmem_req_wstrb_o != held_request_wstrb_q)) begin
                    fail_case("GMEM request changed under backpressure");
                end
            end
            if (gmem_req_valid_o && !gmem_req_ready_i) begin
                request_hold_q       <= 1'b1;
                held_request_write_q <= gmem_req_write_o;
                held_request_addr_q  <= gmem_req_addr_o;
                held_request_wdata_q <= gmem_req_wdata_o;
                held_request_wstrb_q <= gmem_req_wstrb_o;
            end else begin
                request_hold_q <= 1'b0;
            end
        end

        if (global_cycles > 800000)
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
            if ((address < MEM_BASE) || (address >= MEM_LIMIT))
                fail_case("test write_byte outside GMEM model");
            write_index = address[31:0] - MEM_BASE[31:0];
            gmem[write_index] = data_bits;
        end
    endtask

    task automatic write_i32(
        input logic [63:0] address,
        input logic [31:0] bits
    );
        begin
            write_byte(address + 64'd0, bits[7:0]);
            write_byte(address + 64'd1, bits[15:8]);
            write_byte(address + 64'd2, bits[23:16]);
            write_byte(address + 64'd3, bits[31:24]);
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
                write_byte(address + 64'd2 + 64'(lane), default_q);
        end
    endtask

    task automatic write_block_q(
        input logic [63:0] address,
        input integer lane,
        input logic [7:0] q_bits
    );
        begin
            write_byte(address + 64'd2 + 64'(lane), q_bits);
        end
    endtask

    function automatic logic [31:0] read_u32(input logic [63:0] address);
        integer read_index;
        begin
            read_index = address[31:0] - MEM_BASE[31:0];
            read_u32 = {
                gmem[read_index + 3],
                gmem[read_index + 2],
                gmem[read_index + 1],
                gmem[read_index + 0]
            };
        end
    endfunction

    task automatic check_destination_poison(input integer byte_count);
        integer byte_index;
        integer absolute_index;
        reg [7:0] expected_poison;
        begin
            for (byte_index = 0; byte_index < byte_count;
                    byte_index = byte_index + 1) begin
                absolute_index = dst_slice_base_i[31:0]
                               - MEM_BASE[31:0] + byte_index;
                expected_poison = 8'hd3 ^ absolute_index[7:0];
                if (gmem[absolute_index] != expected_poison)
                    fail_case("destination changed without a write request");
            end
        end
    endtask

    task automatic clear_bus_controls;
        begin
            allow_requests_q        = 1'b1;
            request_backpressure_q  = 1'b1;
            read_response_delay_q   = 1;
            write_response_delay_q  = 2;
            write_error_ordinal_q   = -1;
            check_write_order_q     = 1'b1;
        end
    endtask

    task automatic prepare_success_descriptor;
        begin
            poison_memory();
            clear_bus_controls();
            command_id_i           = 64'h0123_4567_89ab_cdef;
            dst_shadow_private_i   = 1'b1;
            src_slice_base_i       = 64'h0000_0000_0000_1200;
            idx_slice_base_i       = 64'h0000_0000_0000_1080;
            dst_slice_base_i       = 64'h0000_0000_0000_2004;
            dst_window_bytes_i     = 64'd400;
            gmem_floor_i           = MEM_BASE;
            gmem_limit_i           = MEM_LIMIT;
            source_row_count_i     = 32'd2;
            index_count_i          = ID_COUNT_W'(3);
            element_count_i        = D_COUNT_W'(32);
            src_row_stride_i       = 64'd40;
            idx_stride_i           = 64'd4;
            dst_row_stride_i       = 64'd136;

            write_i32(64'h1080, 32'd1);
            write_i32(64'h1084, 32'd0);
            write_i32(64'h1088, 32'd1);

            write_block(64'h1200, 16'h3c00, 8'h00);
            write_block_q(64'h1200, 0, 8'h01);
            write_block_q(64'h1200, 1, 8'hff);
            write_block_q(64'h1200, 31, 8'h7f);

            write_block(64'h1228, 16'hb800, 8'h00);
            write_block_q(64'h1228, 0, 8'hfe);
            write_block_q(64'h1228, 1, 8'h02);
            write_block_q(64'h1228, 31, 8'h80);
        end
    endtask

    task automatic reset_adapter;
        begin
            rst_i   = 1'b1;
            start_i = 1'b0;
            repeat (3) @(posedge clk_i);
            @(negedge clk_i);
            if (ready_o || busy_o || completion_valid_o || dst_commit_o
                    || gmem_req_valid_o || gmem_rsp_ready_o) begin
                fail_case("reset did not quiesce adapter");
            end
            rst_i = 1'b0;
            repeat (2) begin
                @(posedge clk_i);
                @(negedge clk_i);
            end
            if (!ready_o || busy_o || completion_valid_o || dst_commit_o)
                fail_case("adapter did not reopen after reset");
        end
    endtask

    task automatic launch_command;
        begin
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
        reg [63:0] resident_id;
        reg [63:0] resident_dst;
        begin
            resident_id  = dut.command_id_q;
            resident_dst = dut.dst_slice_base_q;
            command_id_i     = ~resident_id;
            dst_slice_base_i = ~resident_dst;
            start_i          = 1'b1;
            @(posedge clk_i);
            @(negedge clk_i);
            start_i = 1'b0;
            if ((dut.command_id_q != resident_id)
                    || (dut.dst_slice_base_q != resident_dst)) begin
                fail_case("busy start mutated resident descriptor");
            end
            command_id_i     = resident_id;
            dst_slice_base_i = resident_dst;
        end
    endtask

    task automatic wait_for_error(
        input logic [4:0] expected_code,
        input logic [4:0] expected_child_code,
        input integer max_cycles
    );
        integer wait_cycles;
        begin
            wait_cycles = 0;
            while (!error_o) begin
                if (done_o || dst_commit_o)
                    fail_case("failure path published destination");
                @(posedge clk_i);
                @(negedge clk_i);
                wait_cycles = wait_cycles + 1;
                if (wait_cycles > max_cycles)
                    fail_case("error terminal timeout");
            end
            if (!completion_valid_o || done_o || dst_commit_o || !busy_o
                    || ready_o || (error_code_o != expected_code)
                    || (engine_error_code_o != expected_child_code)
                    || (completion_command_id_o != command_id_i)
                    || (completion_kernel_id_o != KERNEL_ID)) begin
                fail_case("malformed error completion");
            end
            @(posedge clk_i);
            @(negedge clk_i);
            if (error_o || done_o || completion_valid_o || dst_commit_o
                    || busy_o || !ready_o || pending_q
                    || gmem_rsp_valid_i) begin
                fail_case("error completion was not one cycle/fully drained");
            end
        end
    endtask

    task automatic wait_for_success(input integer max_cycles);
        integer wait_cycles;
        begin
            wait_cycles = 0;
            while (!done_o) begin
                if (error_o || dst_commit_o)
                    fail_case("success path terminated/published early");
                @(posedge clk_i);
                @(negedge clk_i);
                wait_cycles = wait_cycles + 1;
                if (wait_cycles > max_cycles)
                    fail_case("success completion timeout");
            end
            if (!completion_valid_o || !dst_commit_o || error_o || !busy_o
                    || ready_o || (error_code_o != 5'b0)
                    || (engine_error_code_o != 5'b0)
                    || (completion_command_id_o != command_id_i)
                    || (completion_kernel_id_o != KERNEL_ID)
                    || pending_q || gmem_rsp_valid_i) begin
                fail_case("malformed success completion");
            end
            @(posedge clk_i);
            @(negedge clk_i);
            if (error_o || done_o || completion_valid_o || dst_commit_o
                    || busy_o || !ready_o) begin
                fail_case("success completion was not one cycle");
            end
        end
    endtask

    task automatic verify_success_memory;
        integer position;
        integer lane;
        integer padding_index;
        reg [63:0] row_base;
        reg [31:0] expected_bits;
        integer absolute_index;
        reg [7:0] expected_poison;
        begin
            for (position = 0; position < 3; position = position + 1) begin
                row_base = dst_slice_base_i + (position * dst_row_stride_i);
                for (lane = 0; lane < 32; lane = lane + 1) begin
                    expected_bits = expected_position_bits(position, lane);
                    if (read_u32(row_base + (lane * 4))
                            != expected_bits) begin
                        fail_case("destination FP32 raw-bit image mismatch");
                    end
                end
                if (position < 2) begin
                    for (padding_index = 128; padding_index < 136;
                            padding_index = padding_index + 1) begin
                        absolute_index = row_base[31:0]
                                       - MEM_BASE[31:0] + padding_index;
                        expected_poison = 8'hd3 ^ absolute_index[7:0];
                        if (gmem[absolute_index] != expected_poison)
                            fail_case("destination row padding was modified");
                    end
                end
            end
        end
    endtask

    task automatic run_success_case;
        begin
            prepare_success_descriptor();
            reset_adapter();
            launch_command();
            probe_busy_start();
            wait_for_success(30000);

            if ((ids_scanned_o != 32'd3)
                    || (blocks_done_o != 32'd3)
                    || (outputs_accepted_o != 32'd96)
                    || (gmem_read_beats_o != 32'd18)
                    || (read_payload_bytes_o != 32'd114)
                    || (gmem_write_beats_o != 32'd96)
                    || (writes_completed_o != 32'd96)
                    || (write_bytes_o != 32'd384)
                    || (accepted_read_requests != 18)
                    || (accepted_write_requests != 96)
                    || (successful_write_responses != 96)
                    || (engine_active_cycles_o == 32'b0)
                    || (active_cycles_o
                        <= {32'b0, engine_active_cycles_o})
                    || (completion_pulse_count != 1)
                    || (commit_pulse_count != 1)) begin
                fail_case("success completion counters did not close");
            end
            verify_success_memory();
        end
    endtask

    task automatic run_invalid_descriptor_cases;
        begin
            prepare_success_descriptor();
            dst_window_bytes_i = 64'd399;
            command_id_i = 64'h1000_0000_0000_0001;
            reset_adapter();
            launch_command();
            wait_for_error(ERR_DEST_BOUNDS, 5'b0, 20);
            if ((accepted_read_requests != 0)
                    || (accepted_write_requests != 0)
                    || (completion_pulse_count != 1)
                    || (commit_pulse_count != 0)) begin
                fail_case("undersized destination issued traffic/commit");
            end
            check_destination_poison(400);

            prepare_success_descriptor();
            dst_shadow_private_i = 1'b0;
            command_id_i = 64'h1000_0000_0000_0002;
            reset_adapter();
            launch_command();
            wait_for_error(ERR_DESCRIPTOR, 5'b0, 20);
            if ((accepted_read_requests != 0)
                    || (accepted_write_requests != 0)
                    || (commit_pulse_count != 0)) begin
                fail_case("non-private destination issued traffic/commit");
            end
            check_destination_poison(400);

            prepare_success_descriptor();
            gmem_limit_i = 64'h0000_0000_0000_2197;
            command_id_i = 64'h1000_0000_0000_0003;
            reset_adapter();
            launch_command();
            wait_for_error(ERR_DEST_BOUNDS, 5'b0, 20);
            if ((accepted_read_requests != 0)
                    || (accepted_write_requests != 0)
                    || (commit_pulse_count != 0)) begin
                fail_case("last aligned destination beat escaped preflight");
            end
            check_destination_poison(400);

            prepare_success_descriptor();
            dst_slice_base_i   = 64'h0000_0000_0000_1200;
            dst_window_bytes_i = 64'd400;
            command_id_i       = 64'h1000_0000_0000_0004;
            check_write_order_q = 1'b0;
            reset_adapter();
            launch_command();
            wait_for_error(ERR_OVERLAP, 5'b0, 20);
            if ((accepted_read_requests != 0)
                    || (accepted_write_requests != 0)
                    || (commit_pulse_count != 0)) begin
                fail_case("source/destination alias issued traffic/commit");
            end
        end
    endtask

    task automatic run_invalid_id_case;
        begin
            prepare_success_descriptor();
            write_i32(64'h1084, 32'd2);
            command_id_i = 64'h2000_0000_0000_0001;
            reset_adapter();
            launch_command();
            wait_for_error(ERR_ENGINE, ENGINE_ERR_ID_RANGE, 100);
            if ((ids_scanned_o != 32'd2)
                    || (blocks_done_o != 32'd0)
                    || (outputs_accepted_o != 32'd0)
                    || (gmem_read_beats_o != 32'd2)
                    || (read_payload_bytes_o != 32'd8)
                    || (gmem_write_beats_o != 32'd0)
                    || (accepted_write_requests != 0)
                    || (commit_pulse_count != 0)) begin
                fail_case("invalid id was not fail-closed before source/write");
            end
            check_destination_poison(400);
        end
    endtask

    task automatic run_write_error_case;
        begin
            prepare_success_descriptor();
            write_error_ordinal_q = 5;
            command_id_i = 64'h3000_0000_0000_0001;
            reset_adapter();
            launch_command();
            wait_for_error(ERR_GMEM_RESPONSE, 5'b0, 30000);
            if ((ids_scanned_o != 32'd3)
                    || (blocks_done_o != 32'd3)
                    || (outputs_accepted_o != 32'd6)
                    || (gmem_read_beats_o != 32'd18)
                    || (gmem_write_beats_o != 32'd6)
                    || (writes_completed_o != 32'd5)
                    || (write_bytes_o != 32'd20)
                    || (accepted_write_requests != 6)
                    || (successful_write_responses != 5)
                    || (commit_pulse_count != 0)) begin
                fail_case("write response error counters did not close");
            end
            // Earlier successful bytes exist only in private staging.  The
            // failed lane remains poison and no publication pulse occurred.
            if ((read_u32(dst_slice_base_i + 64'd0)
                    != expected_position_bits(0, 0))
                    || (read_u32(dst_slice_base_i + 64'd16)
                        != expected_position_bits(0, 4))) begin
                fail_case("private prefix writes missing before injected fault");
            end
            if (read_u32(dst_slice_base_i + 64'd20)
                    == expected_position_bits(0, 5)) begin
                fail_case("faulting private write was incorrectly committed");
            end
        end
    endtask

    task automatic run_write_timeout_drain_case;
        begin
            prepare_success_descriptor();
            write_response_delay_q = 520;
            command_id_i = 64'h4000_0000_0000_0001;
            reset_adapter();
            launch_command();
            wait_for_error(ERR_STALL_TIMEOUT, 5'b0, 30000);
            if (!drain_seen_q || pending_q || gmem_rsp_valid_i
                    || (accepted_write_requests != 1)
                    || (successful_write_responses != 1)
                    || (gmem_write_beats_o != 32'd1)
                    || (writes_completed_o != 32'd1)
                    || (write_bytes_o != 32'd4)
                    || (outputs_accepted_o != 32'd1)
                    || (commit_pulse_count != 0)) begin
                fail_case("accepted write timeout did not drain exactly once");
            end
        end
    endtask

    initial begin
        global_cycles                 = 0;
        rst_i                         = 1'b1;
        start_i                       = 1'b0;
        command_id_i                  = 64'b0;
        dst_shadow_private_i          = 1'b0;
        src_slice_base_i              = 64'b0;
        idx_slice_base_i              = 64'b0;
        dst_slice_base_i              = 64'b0;
        dst_window_bytes_i            = 64'b0;
        gmem_floor_i                  = 64'b0;
        gmem_limit_i                  = 64'b0;
        source_row_count_i            = 32'b0;
        index_count_i                 = {ID_COUNT_W{1'b0}};
        element_count_i               = {D_COUNT_W{1'b0}};
        src_row_stride_i              = 64'b0;
        idx_stride_i                  = 64'b0;
        dst_row_stride_i              = 64'b0;
        allow_requests_q              = 1'b1;
        request_backpressure_q        = 1'b1;
        read_response_delay_q         = 1;
        write_response_delay_q        = 2;
        write_error_ordinal_q         = -1;
        check_write_order_q           = 1'b0;
        pending_q                     = 1'b0;
        pending_write_q               = 1'b0;
        pending_addr_q                = 64'b0;
        pending_wdata_q               = 64'b0;
        pending_wstrb_q               = 8'b0;
        pending_delay_q               = 0;
        pending_write_ordinal_q       = -1;
        gmem_rsp_valid_i              = 1'b0;
        gmem_rsp_rdata_i              = 64'b0;
        gmem_rsp_error_i              = 1'b0;
        accepted_read_requests        = 0;
        accepted_write_requests       = 0;
        successful_write_responses    = 0;
        completion_pulse_count        = 0;
        commit_pulse_count            = 0;
        drain_seen_q                  = 1'b0;
        request_hold_q                = 1'b0;
        held_request_write_q          = 1'b0;
        held_request_addr_q           = 64'b0;
        held_request_wdata_q          = 64'b0;
        held_request_wstrb_q          = 8'b0;

        run_success_case();
        run_invalid_descriptor_cases();
        run_invalid_id_case();
        run_write_error_case();
        run_write_timeout_drain_case();

        $display("[NPU-Q8-GET-ROWS-WRITEBACK][INFO] success=ids3/blocks3/read_beats18/read_bytes114/outputs96/write_beats96/write_bytes384 descriptor_errors=4 invalid_id_atomic=1 write_error_private_only=1 write_timeout_drain=1 identity=64b kernel=514e0001 assertions=off waveform=off");
        $display("[NPU-Q8-GET-ROWS-WRITEBACK][PASS]");
        $finish;
    end

endmodule

`default_nettype wire
