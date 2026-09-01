`timescale 1ns/1ps
`default_nettype none

// Raw-byte, self-checking verification for the transactional Q8_0 GEMV GMEM
// adapter.  This testbench never computes floating-point values: it supplies
// only frozen IEEE/FP16/int8 bytes and compares frozen FP32 golden bits.
module tb_q8_gemv_writeback_adapter;

    localparam integer MEM_BYTES = 16384;
    localparam logic [63:0] MEM_BASE  = 64'h0000_0000_0000_1000;
    localparam logic [63:0] MEM_LIMIT = MEM_BASE + 64'(MEM_BYTES);
    localparam logic [31:0] KERNEL_ID = 32'h514e0002;

    localparam logic [63:0] ACT_BASE = 64'h0000_0000_0000_1104;
    localparam logic [63:0] ACT_WIN  = 64'h0000_0000_0000_1100;
    localparam logic [63:0] WT_BASE  = 64'h0000_0000_0000_1502;
    localparam logic [63:0] WT_WIN   = 64'h0000_0000_0000_1500;
    localparam logic [63:0] DST_BASE = 64'h0000_0000_0000_1804;
    localparam logic [63:0] DST_WIN  = 64'h0000_0000_0000_1800;

    localparam logic [4:0] ST_GMEM_DRAIN    = 5'd15;
    localparam logic [4:0] ERR_DESCRIPTOR   = 5'd1;
    localparam logic [4:0] ERR_ACTIVATION   = 5'd2;
    localparam logic [4:0] ERR_WEIGHT       = 5'd3;
    localparam logic [4:0] ERR_DEST         = 5'd4;
    localparam logic [4:0] ERR_ALIAS        = 5'd5;
    localparam logic [4:0] ERR_GMEM         = 5'd8;
    localparam logic [4:0] ERR_STALL        = 5'd9;

    reg clk_i;
    reg rst_i;
    reg start_i;
    wire ready_o;
    wire busy_o;
    reg [63:0] command_id_i;
    reg dst_shadow_private_i;
    reg windows_generation_valid_i;
    reg [63:0] activation_base_i;
    reg [63:0] weight_base_i;
    reg [63:0] dst_base_i;
    reg [31:0] row_count_i;
    reg [31:0] block_count_i;
    reg [63:0] weight_row_stride_i;
    reg [63:0] dst_row_stride_i;
    reg [63:0] activation_window_base_i;
    reg [63:0] activation_window_bytes_i;
    reg activation_window_read_i;
    reg activation_window_write_i;
    reg [63:0] weight_window_base_i;
    reg [63:0] weight_window_bytes_i;
    reg weight_window_read_i;
    reg weight_window_write_i;
    reg [63:0] dst_window_base_i;
    reg [63:0] dst_window_bytes_i;
    reg dst_window_read_i;
    reg dst_window_write_i;

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
    wire [31:0] completion_row_count_o;
    wire [31:0] completion_block_count_o;
    wire done_o;
    wire error_o;
    wire [4:0] error_code_o;
    wire [7:0] child_error_code_o;
    wire [31:0] activation_words_accepted_o;
    wire [63:0] weight_blocks_accepted_o;
    wire [31:0] rows_written_o;
    wire [63:0] gmem_read_beats_o;
    wire [63:0] gmem_read_beats_completed_o;
    wire [63:0] gmem_read_bytes_o;
    wire [63:0] activation_payload_bytes_o;
    wire [63:0] weight_payload_bytes_o;
    wire [31:0] gmem_write_beats_o;
    wire [31:0] writes_completed_o;
    wire [63:0] write_bytes_o;
    wire [63:0] child_active_cycles_o;
    wire [63:0] active_cycles_o;
    wire gmem_outstanding_o;

    TensorNpuQ8GemvWritebackAdapter #(
        .MAX_ROWS              (248320),
        .MAX_BLOCKS            (128),
        .MAC_LANES             (8),
        .STALL_TIMEOUT_CYCLES  (32'd512),
        .COMMAND_TIMEOUT_CYCLES(64'd200000)
    ) dut (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .start_i(start_i),
        .ready_o(ready_o),
        .busy_o(busy_o),
        .command_id_i(command_id_i),
        .dst_shadow_private_i(dst_shadow_private_i),
        .windows_generation_valid_i(windows_generation_valid_i),
        .activation_base_i(activation_base_i),
        .weight_base_i(weight_base_i),
        .dst_base_i(dst_base_i),
        .row_count_i(row_count_i),
        .block_count_i(block_count_i),
        .weight_row_stride_i(weight_row_stride_i),
        .dst_row_stride_i(dst_row_stride_i),
        .activation_window_base_i(activation_window_base_i),
        .activation_window_bytes_i(activation_window_bytes_i),
        .activation_window_read_i(activation_window_read_i),
        .activation_window_write_i(activation_window_write_i),
        .weight_window_base_i(weight_window_base_i),
        .weight_window_bytes_i(weight_window_bytes_i),
        .weight_window_read_i(weight_window_read_i),
        .weight_window_write_i(weight_window_write_i),
        .dst_window_base_i(dst_window_base_i),
        .dst_window_bytes_i(dst_window_bytes_i),
        .dst_window_read_i(dst_window_read_i),
        .dst_window_write_i(dst_window_write_i),
        .gmem_req_valid_o(gmem_req_valid_o),
        .gmem_req_ready_i(gmem_req_ready_i),
        .gmem_req_write_o(gmem_req_write_o),
        .gmem_req_addr_o(gmem_req_addr_o),
        .gmem_req_wdata_o(gmem_req_wdata_o),
        .gmem_req_wstrb_o(gmem_req_wstrb_o),
        .gmem_rsp_valid_i(gmem_rsp_valid_i),
        .gmem_rsp_ready_o(gmem_rsp_ready_o),
        .gmem_rsp_rdata_i(gmem_rsp_rdata_i),
        .gmem_rsp_error_i(gmem_rsp_error_i),
        .completion_valid_o(completion_valid_o),
        .dst_commit_o(dst_commit_o),
        .completion_command_id_o(completion_command_id_o),
        .completion_kernel_id_o(completion_kernel_id_o),
        .completion_row_count_o(completion_row_count_o),
        .completion_block_count_o(completion_block_count_o),
        .done_o(done_o),
        .error_o(error_o),
        .error_code_o(error_code_o),
        .child_error_code_o(child_error_code_o),
        .activation_words_accepted_o(activation_words_accepted_o),
        .weight_blocks_accepted_o(weight_blocks_accepted_o),
        .rows_written_o(rows_written_o),
        .gmem_read_beats_o(gmem_read_beats_o),
        .gmem_read_beats_completed_o(gmem_read_beats_completed_o),
        .gmem_read_bytes_o(gmem_read_bytes_o),
        .activation_payload_bytes_o(activation_payload_bytes_o),
        .weight_payload_bytes_o(weight_payload_bytes_o),
        .gmem_write_beats_o(gmem_write_beats_o),
        .writes_completed_o(writes_completed_o),
        .write_bytes_o(write_bytes_o),
        .child_active_cycles_o(child_active_cycles_o),
        .active_cycles_o(active_cycles_o),
        .gmem_outstanding_o(gmem_outstanding_o)
    );

    initial clk_i = 1'b0;
    always #5 clk_i <= ~clk_i;

    reg [7:0] gmem [0:MEM_BYTES-1];
    reg allow_requests_q;
    reg request_backpressure_q;
    integer read_response_delay_q;
    integer write_response_delay_q;
    reg inject_read_error_q;
    reg [63:0] read_error_addr_q;
    integer write_error_ordinal_q;
    reg check_unique_reads_q;
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
    integer accepted_activation_reads;
    integer accepted_weight_reads;
    integer accepted_write_requests;
    integer successful_write_responses;
    integer read_backpressure_cycles;
    integer write_backpressure_cycles;
    integer completion_pulse_count;
    integer commit_pulse_count;
    reg drain_seen_q;
    reg [63:0] accepted_read_addr_q [0:511];

    reg request_hold_q;
    reg held_request_write_q;
    reg [63:0] held_request_addr_q;
    reg [63:0] held_request_wdata_q;
    reg [7:0] held_request_wstrb_q;

    integer bus_lane;
    integer scan_index;

    assign gmem_req_ready_i = allow_requests_q
                            && !pending_q
                            && !gmem_rsp_valid_i
                            && (!request_backpressure_q
                                || (gmem_req_write_o
                                    ? (write_backpressure_cycles >= 2)
                                    : (read_backpressure_cycles >= 2)));

    task automatic fail_case(input string reason);
        begin
            $display("[NPU-Q8-GEMV-WRITEBACK][FAIL] %s cycle=%0d state=%0d err=%0d child=%0h outstanding=%0b",
                     reason, global_cycles, dut.state_q, error_code_o,
                     child_error_code_o, gmem_outstanding_o);
            $display("[NPU-Q8-GEMV-WRITEBACK][EVIDENCE] act_words=%0d weight_blocks=%0d rows=%0d read=%0d/%0d read_bytes=%0d act_bytes=%0d weight_bytes=%0d writes=%0d/%0d write_bytes=%0d read_bp=%0d write_bp=%0d completions=%0d commits=%0d",
                     activation_words_accepted_o,
                     weight_blocks_accepted_o, rows_written_o,
                     gmem_read_beats_o, gmem_read_beats_completed_o,
                     gmem_read_bytes_o, activation_payload_bytes_o,
                     weight_payload_bytes_o, gmem_write_beats_o,
                     writes_completed_o, write_bytes_o,
                     read_backpressure_cycles, write_backpressure_cycles,
                     completion_pulse_count, commit_pulse_count);
            $fatal(1);
        end
    endtask

    function automatic logic [31:0] frozen_result_bits(input integer row);
        begin
            frozen_result_bits = (row == 0) ? 32'h473d6500
                                            : 32'hc5fc0800;
        end
    endfunction

    // Combinational monitor expressions for the transaction accepted in the
    // current cycle.  The clocked raw-memory model therefore contains only
    // state updates and no sequential blocking temporaries.
    wire response_error_w = (!pending_write_q
                             && inject_read_error_q
                             && (pending_addr_q == read_error_addr_q))
                          || (pending_write_q
                              && (write_error_ordinal_q >= 0)
                              && (pending_write_ordinal_q
                                  == write_error_ordinal_q));
    wire [31:0] memory_index_w = pending_addr_q[31:0]
                               - MEM_BASE[31:0];
    wire [63:0] expected_semantic_addr_w = dst_base_i
        + (accepted_write_requests * dst_row_stride_i);
    wire [63:0] expected_aligned_addr_w = {
        expected_semantic_addr_w[63:3], 3'b000
    };
    wire [31:0] expected_result_bits_w = frozen_result_bits(
        accepted_write_requests
    );
    wire [63:0] expected_write_data_w = expected_semantic_addr_w[2]
        ? {expected_result_bits_w, 32'b0}
        : {32'b0, expected_result_bits_w};
    wire [7:0] expected_write_strb_w = expected_semantic_addr_w[2]
        ? 8'hf0 : 8'h0f;

    // Single-outstanding raw-byte memory.  Errors can be attached to one
    // accepted read address (including a sparse >4-GiB boundary probe) or one
    // write ordinal.  Successful writes update only private strobed bytes.
    always @(posedge clk_i) begin
        if (rst_i) begin
            pending_q <= 1'b0;
            pending_write_q <= 1'b0;
            pending_addr_q <= 64'b0;
            pending_wdata_q <= 64'b0;
            pending_wstrb_q <= 8'b0;
            pending_delay_q <= 0;
            pending_write_ordinal_q <= -1;
            gmem_rsp_valid_i <= 1'b0;
            gmem_rsp_rdata_i <= 64'b0;
            gmem_rsp_error_i <= 1'b0;
            accepted_read_requests <= 0;
            accepted_activation_reads <= 0;
            accepted_weight_reads <= 0;
            accepted_write_requests <= 0;
            successful_write_responses <= 0;
            read_backpressure_cycles <= 0;
            write_backpressure_cycles <= 0;
        end else begin
            if (gmem_req_valid_o && !gmem_req_ready_i) begin
                if (gmem_req_write_o)
                    write_backpressure_cycles
                        <= write_backpressure_cycles + 1;
                else
                    read_backpressure_cycles
                        <= read_backpressure_cycles + 1;
            end

            if (gmem_rsp_valid_i && gmem_rsp_ready_o) begin
                if (pending_write_q && !gmem_rsp_error_i)
                    successful_write_responses
                        <= successful_write_responses + 1;
                pending_q <= 1'b0;
                gmem_rsp_valid_i <= 1'b0;
                gmem_rsp_error_i <= 1'b0;
            end

            if (pending_q && !gmem_rsp_valid_i) begin
                if (pending_delay_q == 0) begin
                    gmem_rsp_error_i <= response_error_w;
                    gmem_rsp_rdata_i <= 64'b0;
                    if (!response_error_w) begin
                        if ((pending_addr_q < MEM_BASE)
                                || ((pending_addr_q + 64'd8)
                                    > MEM_LIMIT)) begin
                            fail_case("successful GMEM beat outside model");
                        end
                        if (pending_write_q) begin
                            for (bus_lane = 0; bus_lane < 8;
                                    bus_lane = bus_lane + 1) begin
                                if (pending_wstrb_q[bus_lane])
                                    gmem[memory_index_w + bus_lane]
                                        <= pending_wdata_q[
                                            (bus_lane * 8) +: 8];
                            end
                        end else begin
                            for (bus_lane = 0; bus_lane < 8;
                                    bus_lane = bus_lane + 1) begin
                                gmem_rsp_rdata_i[(bus_lane * 8) +: 8]
                                    <= gmem[memory_index_w + bus_lane];
                            end
                        end
                    end
                    gmem_rsp_valid_i <= 1'b1;
                end else begin
                    pending_delay_q <= pending_delay_q - 1;
                end
            end

            if (gmem_req_valid_o && gmem_req_ready_i) begin
                if (pending_q || gmem_rsp_valid_i)
                    fail_case("more than one GMEM request outstanding");
                if (gmem_req_addr_o[2:0] != 3'b000)
                    fail_case("GMEM request was not beat aligned");
                pending_q <= 1'b1;
                pending_write_q <= gmem_req_write_o;
                pending_addr_q <= gmem_req_addr_o;
                pending_wdata_q <= gmem_req_wdata_o;
                pending_wstrb_q <= gmem_req_wstrb_o;
                if (gmem_req_write_o) begin
                    if (!((gmem_req_wstrb_o == 8'h0f)
                            || (gmem_req_wstrb_o == 8'hf0))) begin
                        fail_case("write strobe was not one FP32 lane");
                    end
                    pending_delay_q <= write_response_delay_q;
                    pending_write_ordinal_q <= accepted_write_requests;
                    if (check_write_order_q) begin
                        if ((gmem_req_addr_o != expected_aligned_addr_w)
                                || (gmem_req_wdata_o
                                    != expected_write_data_w)
                                || (gmem_req_wstrb_o
                                    != expected_write_strb_w)) begin
                            fail_case("result address/order/raw bits mismatch");
                        end
                    end
                    accepted_write_requests
                        <= accepted_write_requests + 1;
                end else begin
                    if ((gmem_req_wdata_o != 64'b0)
                            || (gmem_req_wstrb_o != 8'b0)) begin
                        fail_case("read request carried write payload");
                    end
                    if (check_unique_reads_q) begin
                        for (scan_index = 0;
                                scan_index < accepted_read_requests;
                                scan_index = scan_index + 1) begin
                            if (accepted_read_addr_q[scan_index]
                                    == gmem_req_addr_o) begin
                                fail_case("raw source beat was fetched twice");
                            end
                        end
                        accepted_read_addr_q[accepted_read_requests]
                            <= gmem_req_addr_o;
                    end
                    if ((gmem_req_addr_o >= activation_window_base_i)
                            && (gmem_req_addr_o
                                < (activation_window_base_i
                                   + activation_window_bytes_i))) begin
                        accepted_activation_reads
                            <= accepted_activation_reads + 1;
                    end else if ((gmem_req_addr_o >= weight_window_base_i)
                                 && (gmem_req_addr_o
                                     < (weight_window_base_i
                                        + weight_window_bytes_i))) begin
                        accepted_weight_reads
                            <= accepted_weight_reads + 1;
                    end
                    pending_delay_q <= read_response_delay_q;
                    pending_write_ordinal_q <= -1;
                    accepted_read_requests
                        <= accepted_read_requests + 1;
                end
            end
        end
    end

    always @(posedge clk_i) begin
        global_cycles <= global_cycles + 1;
        if (rst_i) begin
            request_hold_q <= 1'b0;
            completion_pulse_count <= 0;
            commit_pulse_count <= 0;
            drain_seen_q <= 1'b0;
        end else begin
            if (done_o && error_o)
                fail_case("done and error overlapped");
            if (ready_o && busy_o)
                fail_case("ready and busy overlapped");
            if (completion_valid_o != (done_o || error_o))
                fail_case("completion_valid malformed");
            if (dst_commit_o != done_o)
                fail_case("private destination commit was not success-only");
            if (completion_valid_o && gmem_outstanding_o)
                fail_case("terminal retained outstanding GMEM debt");
            if (!completion_valid_o
                    && ((completion_command_id_o != 64'b0)
                        || (completion_kernel_id_o != 32'b0)
                        || (completion_row_count_o != 32'b0)
                        || (completion_block_count_o != 32'b0))) begin
                fail_case("completion identity leaked outside terminal");
            end
            if (completion_valid_o) begin
                completion_pulse_count <= completion_pulse_count + 1;
                if ((completion_command_id_o != command_id_i)
                        || (completion_kernel_id_o != KERNEL_ID)
                        || (completion_row_count_o != row_count_i)
                        || (completion_block_count_o != block_count_i)) begin
                    fail_case("completion identity/shape mismatch");
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
                request_hold_q <= 1'b1;
                held_request_write_q <= gmem_req_write_o;
                held_request_addr_q <= gmem_req_addr_o;
                held_request_wdata_q <= gmem_req_wdata_o;
                held_request_wstrb_q <= gmem_req_wstrb_o;
            end else begin
                request_hold_q <= 1'b0;
            end
        end

        if (global_cycles > 1000000)
            fail_case("global timeout");
    end

    task automatic poison_memory;
        integer idx;
        begin
            for (idx = 0; idx < MEM_BYTES; idx = idx + 1)
                gmem[idx] = 8'ha7 ^ idx[7:0];
        end
    endtask

    task automatic write_byte(
        input logic [63:0] address,
        input logic [7:0] bits
    );
        integer idx;
        begin
            if ((address < MEM_BASE) || (address >= MEM_LIMIT))
                fail_case("fixture byte outside local GMEM");
            idx = address[31:0] - MEM_BASE[31:0];
            gmem[idx] = bits;
        end
    endtask

    task automatic write_u32(
        input logic [63:0] address,
        input logic [31:0] bits
    );
        begin
            write_byte(address + 0, bits[7:0]);
            write_byte(address + 1, bits[15:8]);
            write_byte(address + 2, bits[23:16]);
            write_byte(address + 3, bits[31:24]);
        end
    endtask

    function automatic logic [31:0] read_u32(input logic [63:0] address);
        integer idx;
        begin
            idx = address[31:0] - MEM_BASE[31:0];
            read_u32 = {gmem[idx+3], gmem[idx+2], gmem[idx+1], gmem[idx]};
        end
    endfunction

    task automatic write_block(
        input logic [63:0] address,
        input logic [15:0] scale,
        input logic [7:0] default_q
    );
        integer lane;
        begin
            write_byte(address + 0, scale[7:0]);
            write_byte(address + 1, scale[15:8]);
            for (lane = 0; lane < 32; lane = lane + 1)
                write_byte(address + 64'd2 + 64'(lane), default_q);
        end
    endtask

    task automatic write_q(
        input logic [63:0] address,
        input integer lane,
        input logic [7:0] q
    );
        begin
            write_byte(address + 64'd2 + 64'(lane), q);
        end
    endtask

    task automatic load_m2_b2_fixture;
        integer lane;
        begin
            // Activation block 0: [-127,-64,-1,0,1,63,64,127,0...].
            write_u32(ACT_BASE + 0*4, 32'hc2fe0000);
            write_u32(ACT_BASE + 1*4, 32'hc2800000);
            write_u32(ACT_BASE + 2*4, 32'hbf800000);
            write_u32(ACT_BASE + 3*4, 32'h00000000);
            write_u32(ACT_BASE + 4*4, 32'h3f800000);
            write_u32(ACT_BASE + 5*4, 32'h427c0000);
            write_u32(ACT_BASE + 6*4, 32'h42800000);
            write_u32(ACT_BASE + 7*4, 32'h42fe0000);
            for (lane = 8; lane < 32; lane = lane + 1)
                write_u32(ACT_BASE + lane*4, 32'h00000000);
            // Activation block 1: 32 copies of +127.0f.
            for (lane = 0; lane < 32; lane = lane + 1)
                write_u32(ACT_BASE
                          + ((64'd32 + 64'(lane)) * 64'd4),
                          32'h42fe0000);

            write_block(WT_BASE + 0, 16'h3c00, 8'h00);
            write_q(WT_BASE + 0, 0, 8'h81);
            write_q(WT_BASE + 0, 1, 8'hc0);
            write_q(WT_BASE + 0, 2, 8'hff);
            write_q(WT_BASE + 0, 3, 8'h00);
            write_q(WT_BASE + 0, 4, 8'h01);
            write_q(WT_BASE + 0, 5, 8'h3f);
            write_q(WT_BASE + 0, 6, 8'h40);
            write_q(WT_BASE + 0, 7, 8'h7f);
            write_block(WT_BASE + 34, 16'h3c00, 8'h01);
            write_block(WT_BASE + 72, 16'h3800, 8'h02);
            write_block(WT_BASE + 72 + 34, 16'hc000, 8'h01);
        end
    endtask

    task automatic clear_bus_controls;
        begin
            allow_requests_q = 1'b1;
            request_backpressure_q = 1'b1;
            read_response_delay_q = 1;
            write_response_delay_q = 3;
            inject_read_error_q = 1'b0;
            read_error_addr_q = 64'b0;
            write_error_ordinal_q = -1;
            check_unique_reads_q = 1'b0;
            check_write_order_q = 1'b0;
        end
    endtask

    task automatic prepare_success_descriptor;
        begin
            poison_memory();
            clear_bus_controls();
            command_id_i = 64'h0123_4567_89ab_cdef;
            dst_shadow_private_i = 1'b1;
            windows_generation_valid_i = 1'b1;
            activation_base_i = ACT_BASE;
            weight_base_i = WT_BASE;
            dst_base_i = DST_BASE;
            row_count_i = 32'd2;
            block_count_i = 32'd2;
            weight_row_stride_i = 64'd72;
            dst_row_stride_i = 64'd12;
            activation_window_base_i = ACT_WIN;
            activation_window_bytes_i = 64'h108;
            activation_window_read_i = 1'b1;
            activation_window_write_i = 1'b0;
            weight_window_base_i = WT_WIN;
            weight_window_bytes_i = 64'h90;
            weight_window_read_i = 1'b1;
            weight_window_write_i = 1'b0;
            dst_window_base_i = DST_WIN;
            dst_window_bytes_i = 64'h18;
            dst_window_read_i = 1'b0;
            dst_window_write_i = 1'b1;
            load_m2_b2_fixture();
        end
    endtask

    task automatic reset_adapter;
        begin
            rst_i = 1'b1;
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
        reg [31:0] resident_rows;
        begin
            resident_id = dut.command_id_q;
            resident_rows = dut.row_count_q;
            command_id_i = ~resident_id;
            row_count_i = ~resident_rows;
            start_i = 1'b1;
            @(posedge clk_i);
            @(negedge clk_i);
            start_i = 1'b0;
            if ((dut.command_id_q != resident_id)
                    || (dut.row_count_q != resident_rows)) begin
                fail_case("busy start mutated resident descriptor");
            end
            command_id_i = resident_id;
            row_count_i = resident_rows;
        end
    endtask

    task automatic wait_for_error(
        input logic [4:0] expected_error,
        input integer max_cycles
    );
        integer cycles;
        begin
            cycles = 0;
            while (!error_o) begin
                if (done_o || dst_commit_o)
                    fail_case("failure path published destination");
                @(posedge clk_i);
                @(negedge clk_i);
                cycles = cycles + 1;
                if (cycles > max_cycles)
                    fail_case("error terminal timeout");
            end
            if (!completion_valid_o || done_o || dst_commit_o || !busy_o
                    || ready_o || (error_code_o != expected_error)
                    || (completion_command_id_o != command_id_i)
                    || (completion_kernel_id_o != KERNEL_ID)
                    || (completion_row_count_o != row_count_i)
                    || (completion_block_count_o != block_count_i)) begin
                fail_case("malformed error completion");
            end
            @(posedge clk_i);
            @(negedge clk_i);
            if (completion_valid_o || done_o || error_o || dst_commit_o
                    || busy_o || !ready_o || pending_q
                    || gmem_rsp_valid_i) begin
                fail_case("error completion was not one-cycle/drained");
            end
        end
    endtask

    task automatic wait_for_success(input integer max_cycles);
        integer cycles;
        begin
            cycles = 0;
            while (!done_o) begin
                if (error_o || dst_commit_o)
                    fail_case("success path terminated or committed early");
                @(posedge clk_i);
                @(negedge clk_i);
                cycles = cycles + 1;
                if (cycles > max_cycles)
                    fail_case("success terminal timeout");
            end
            if (!completion_valid_o || !dst_commit_o || error_o || !busy_o
                    || ready_o || (error_code_o != 5'b0)
                    || (child_error_code_o != 8'b0)
                    || (completion_command_id_o != command_id_i)
                    || (completion_kernel_id_o != KERNEL_ID)
                    || (completion_row_count_o != row_count_i)
                    || (completion_block_count_o != block_count_i)
                    || pending_q || gmem_rsp_valid_i) begin
                fail_case("malformed success completion");
            end
            @(posedge clk_i);
            @(negedge clk_i);
            if (completion_valid_o || done_o || error_o || dst_commit_o
                    || busy_o || !ready_o) begin
                fail_case("success completion was not one cycle");
            end
        end
    endtask

    task automatic expect_preflight_error(input logic [4:0] code);
        begin
            reset_adapter();
            launch_command();
            wait_for_error(code, 30);
            if ((accepted_read_requests != 0)
                    || (accepted_write_requests != 0)
                    || (commit_pulse_count != 0)) begin
                fail_case("preflight error issued traffic or commit");
            end
        end
    endtask

    task automatic run_success_case;
        begin
            prepare_success_descriptor();
            check_unique_reads_q = 1'b1;
            check_write_order_q = 1'b1;
            reset_adapter();
            launch_command();
            probe_busy_start();
            wait_for_success(50000);
            if ((activation_words_accepted_o != 32'd64)
                    || (weight_blocks_accepted_o != 64'd4)
                    || (rows_written_o != 32'd2)
                    || (gmem_read_beats_o != 64'd51)
                    || (gmem_read_beats_completed_o != 64'd51)
                    || (gmem_read_bytes_o != 64'd408)
                    || (activation_payload_bytes_o != 64'd256)
                    || (weight_payload_bytes_o != 64'd136)
                    || (gmem_write_beats_o != 32'd2)
                    || (writes_completed_o != 32'd2)
                    || (write_bytes_o != 64'd8)
                    || (accepted_activation_reads != 33)
                    || (accepted_weight_reads != 18)
                    || (accepted_write_requests != 2)
                    || (successful_write_responses != 2)
                    || (read_backpressure_cycles == 0)
                    || (write_backpressure_cycles == 0)
                    || (child_active_cycles_o == 64'b0)
                    || (active_cycles_o <= child_active_cycles_o)
                    || (completion_pulse_count != 1)
                    || (commit_pulse_count != 1)) begin
                fail_case("successful command counters did not close");
            end
            if ((read_u32(DST_BASE) != 32'h473d6500)
                    || (read_u32(DST_BASE + 12) != 32'hc5fc0800)) begin
                fail_case("M=2/B=2 frozen FP32 oracle mismatch");
            end
        end
    endtask

    task automatic run_preflight_fail_closed_cases;
        begin
            prepare_success_descriptor();
            dst_shadow_private_i = 1'b0;
            command_id_i = 64'h1000_0000_0000_0001;
            expect_preflight_error(ERR_DESCRIPTOR);

            prepare_success_descriptor();
            activation_window_bytes_i = 64'h100;
            command_id_i = 64'h1000_0000_0000_0002;
            expect_preflight_error(ERR_ACTIVATION);

            prepare_success_descriptor();
            weight_window_bytes_i = 64'h88;
            command_id_i = 64'h1000_0000_0000_0003;
            expect_preflight_error(ERR_WEIGHT);

            prepare_success_descriptor();
            dst_window_bytes_i = 64'h10;
            command_id_i = 64'h1000_0000_0000_0004;
            expect_preflight_error(ERR_DEST);

            prepare_success_descriptor();
            dst_base_i = ACT_BASE;
            dst_window_base_i = ACT_WIN;
            dst_window_bytes_i = 64'h18;
            command_id_i = 64'h1000_0000_0000_0005;
            expect_preflight_error(ERR_ALIAS);

            prepare_success_descriptor();
            activation_window_write_i = 1'b1;
            command_id_i = 64'h1000_0000_0000_0006;
            expect_preflight_error(ERR_DESCRIPTOR);

            prepare_success_descriptor();
            row_count_i = 32'd248321;
            command_id_i = 64'h1000_0000_0000_0007;
            expect_preflight_error(ERR_DESCRIPTOR);
        end
    endtask

    task automatic prepare_profile_descriptor(
        input logic [31:0] m,
        input logic [31:0] b,
        input logic [63:0] id
    );
        reg [63:0] activation_bytes;
        reg [63:0] row_bytes;
        reg [63:0] matrix_bytes;
        reg [63:0] dst_end_offset;
        begin
            clear_bus_controls();
            command_id_i = id;
            dst_shadow_private_i = 1'b1;
            windows_generation_valid_i = 1'b1;
            row_count_i = m;
            block_count_i = b;
            activation_bytes = {32'b0, b} * 64'd128;
            row_bytes = {32'b0, b} * 64'd34;
            matrix_bytes = {32'b0, m} * row_bytes;

            activation_window_base_i = 64'h0000_0001_0000_1000;
            activation_base_i = activation_window_base_i + 64'd4;
            activation_window_bytes_i = activation_bytes + 64'd8;
            activation_window_read_i = 1'b1;
            activation_window_write_i = 1'b0;

            weight_window_base_i = 64'h0000_0002_0000_0000;
            weight_base_i = weight_window_base_i + 64'd2;
            weight_row_stride_i = row_bytes;
            weight_window_bytes_i = matrix_bytes + 64'd8;
            weight_window_read_i = 1'b1;
            weight_window_write_i = 1'b0;

            dst_window_base_i = 64'h0000_0003_0000_0000;
            dst_base_i = dst_window_base_i + 64'd4;
            dst_row_stride_i = 64'd4;
            dst_end_offset = 64'd4 + ({32'b0, m} * 64'd4);
            dst_window_bytes_i = (dst_end_offset + 64'd7)
                               & 64'hffff_ffff_ffff_fff8;
            dst_window_read_i = 1'b0;
            dst_window_write_i = 1'b1;

            inject_read_error_q = 1'b1;
            read_error_addr_q = activation_window_base_i;
        end
    endtask

    task automatic run_one_profile_probe(
        input logic [31:0] m,
        input logic [31:0] b,
        input logic [63:0] id
    );
        reg [63:0] expected_weight_end;
        reg [63:0] expected_activation_end;
        reg [63:0] expected_dst_end;
        begin
            prepare_profile_descriptor(m, b, id);
            expected_activation_end = activation_base_i
                                    + ({32'b0, b} * 64'd128);
            expected_weight_end = weight_base_i
                                + ({32'b0, m}
                                   * ({32'b0, b} * 64'd34));
            expected_dst_end = dst_base_i + ({32'b0, m} * 64'd4);
            reset_adapter();
            launch_command();
            wait_for_error(ERR_GMEM, 80);
            if ((accepted_read_requests != 1)
                    || (accepted_write_requests != 0)
                    || (gmem_read_beats_o != 64'd1)
                    || (gmem_read_beats_completed_o != 64'd0)
                    || (dut.activation_semantic_end_q
                        != expected_activation_end)
                    || (dut.weight_semantic_end_q != expected_weight_end)
                    || (dut.dst_semantic_end_q != expected_dst_end)
                    || (commit_pulse_count != 0)) begin
                fail_case("Qwen profile did not pass full-width preflight");
            end
        end
    endtask

    task automatic run_profile_boundary_cases;
        begin
            // Real LM-head profile: M=248320, K=1024 (B=32).
            run_one_profile_probe(32'd248320, 32'd32,
                                  64'h2000_0000_0000_0020);
            run_one_profile_probe(32'd1, 32'd64,
                                  64'h2000_0000_0000_0040);
            run_one_profile_probe(32'd1, 32'd112,
                                  64'h2000_0000_0000_006f);
            // Preserve the wrapped core's complete B<=128 capability.
            run_one_profile_probe(32'd1, 32'd128,
                                  64'h2000_0000_0000_0080);
            // Independent worst-product address proof.  It intentionally
            // exceeds a current layer pairing while remaining in the declared
            // M/B capability rectangle.
            run_one_profile_probe(32'd248320, 32'd112,
                                  64'h2000_0000_0000_0070);

            // The last aligned beat of the 248320 x 112 x 34-byte matrix is
            // part of preflight; removing exactly one beat must issue nothing.
            prepare_profile_descriptor(32'd248320, 32'd112,
                                       64'h2000_0000_0000_0071);
            weight_window_bytes_i = weight_window_bytes_i - 64'd8;
            expect_preflight_error(ERR_WEIGHT);
        end
    endtask

    task automatic run_late_read_error_case;
        begin
            prepare_success_descriptor();
            command_id_i = 64'h3000_0000_0000_0001;
            inject_read_error_q = 1'b1;
            read_error_addr_q = 64'h0000_0000_0000_1548;
            reset_adapter();
            launch_command();
            wait_for_error(ERR_GMEM, 50000);
            if ((activation_words_accepted_o != 32'd64)
                    || (weight_blocks_accepted_o != 64'd2)
                    || (rows_written_o != 32'd1)
                    || (gmem_read_beats_o != 64'd43)
                    || (gmem_read_beats_completed_o != 64'd42)
                    || (gmem_write_beats_o != 32'd1)
                    || (writes_completed_o != 32'd1)
                    || (read_u32(DST_BASE) != 32'h473d6500)
                    || (commit_pulse_count != 0)) begin
                fail_case("late read error leaked/incorrectly counted prefix");
            end
        end
    endtask

    task automatic run_write_error_case;
        integer dst_row1_index;
        reg [31:0] poison_row1;
        begin
            prepare_success_descriptor();
            command_id_i = 64'h3000_0000_0000_0002;
            write_error_ordinal_q = 1;
            reset_adapter();
            dst_row1_index = (DST_BASE[31:0] + 32'd12)
                           - MEM_BASE[31:0];
            poison_row1 = {gmem[dst_row1_index+3], gmem[dst_row1_index+2],
                           gmem[dst_row1_index+1], gmem[dst_row1_index]};
            launch_command();
            wait_for_error(ERR_GMEM, 50000);
            if ((rows_written_o != 32'd2)
                    || (gmem_write_beats_o != 32'd2)
                    || (writes_completed_o != 32'd1)
                    || (write_bytes_o != 64'd4)
                    || (read_u32(DST_BASE) != 32'h473d6500)
                    || (read_u32(DST_BASE + 12) != poison_row1)
                    || (commit_pulse_count != 0)) begin
                fail_case("write response error exposed partial destination");
            end
        end
    endtask

    task automatic run_timeout_drain_case;
        begin
            prepare_success_descriptor();
            command_id_i = 64'h4000_0000_0000_0001;
            request_backpressure_q = 1'b0;
            read_response_delay_q = 520;
            reset_adapter();
            launch_command();
            wait_for_error(ERR_STALL, 2000);
            if (!drain_seen_q || pending_q || gmem_rsp_valid_i
                    || (accepted_read_requests != 1)
                    || (gmem_read_beats_o != 64'd1)
                    || (gmem_read_beats_completed_o != 64'd1)
                    || (activation_words_accepted_o != 32'd0)
                    || (accepted_write_requests != 0)
                    || (commit_pulse_count != 0)) begin
                fail_case("accepted read timeout did not drain exactly once");
            end
        end
    endtask

    initial begin
        global_cycles = 0;
        rst_i = 1'b1;
        start_i = 1'b0;
        command_id_i = 64'b0;
        dst_shadow_private_i = 1'b0;
        windows_generation_valid_i = 1'b0;
        activation_base_i = 64'b0;
        weight_base_i = 64'b0;
        dst_base_i = 64'b0;
        row_count_i = 32'b0;
        block_count_i = 32'b0;
        weight_row_stride_i = 64'b0;
        dst_row_stride_i = 64'b0;
        activation_window_base_i = 64'b0;
        activation_window_bytes_i = 64'b0;
        activation_window_read_i = 1'b0;
        activation_window_write_i = 1'b0;
        weight_window_base_i = 64'b0;
        weight_window_bytes_i = 64'b0;
        weight_window_read_i = 1'b0;
        weight_window_write_i = 1'b0;
        dst_window_base_i = 64'b0;
        dst_window_bytes_i = 64'b0;
        dst_window_read_i = 1'b0;
        dst_window_write_i = 1'b0;
        allow_requests_q = 1'b1;
        request_backpressure_q = 1'b0;
        read_response_delay_q = 0;
        write_response_delay_q = 0;
        inject_read_error_q = 1'b0;
        read_error_addr_q = 64'b0;
        write_error_ordinal_q = -1;
        check_unique_reads_q = 1'b0;
        check_write_order_q = 1'b0;
        pending_q = 1'b0;
        pending_write_q = 1'b0;
        pending_addr_q = 64'b0;
        pending_wdata_q = 64'b0;
        pending_wstrb_q = 8'b0;
        pending_delay_q = 0;
        pending_write_ordinal_q = -1;
        gmem_rsp_valid_i = 1'b0;
        gmem_rsp_rdata_i = 64'b0;
        gmem_rsp_error_i = 1'b0;
        accepted_read_requests = 0;
        accepted_activation_reads = 0;
        accepted_weight_reads = 0;
        accepted_write_requests = 0;
        successful_write_responses = 0;
        read_backpressure_cycles = 0;
        write_backpressure_cycles = 0;
        completion_pulse_count = 0;
        commit_pulse_count = 0;
        drain_seen_q = 1'b0;
        request_hold_q = 1'b0;
        held_request_write_q = 1'b0;
        held_request_addr_q = 64'b0;
        held_request_wdata_q = 64'b0;
        held_request_wstrb_q = 8'b0;

        run_success_case();
        run_preflight_fail_closed_cases();
        run_profile_boundary_cases();
        run_late_read_error_case();
        run_write_error_case();
        run_timeout_drain_case();

        $display("[NPU-Q8-GEMV-WRITEBACK][INFO] bit_exact=M2/B2 read_beats=51 act_words=64 weight_blocks=4 rows=2 profiles=B32/B64/B112 lm_head=M248320/B32 max_product=M248320/B112 core_B128=1 preflight=128b late_fault_atomic=1 timeout_drain=1 identity=64b kernel=514e0002 assertions=off waveform=off");
        $display("[NPU-Q8-GEMV-WRITEBACK][PASS]");
        $finish;
    end

endmodule

`default_nettype wire
