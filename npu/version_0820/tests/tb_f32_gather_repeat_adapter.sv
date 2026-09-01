`timescale 1ns/1ps
`default_nettype none

// Directed raw-bit verification for TensorNpuF32GatherRepeatAdapter.  The
// testbench contains no real/shortreal, DPI, host tensor arithmetic, assertion
// construct, trace or waveform path.
module tb_f32_gather_repeat_adapter;

    localparam integer MEM_BYTES = 65536;
    localparam logic [63:0] MEM_BASE  = 64'h0000_0000_0000_1000;
    localparam logic [63:0] MEM_LIMIT = MEM_BASE + 64'(MEM_BYTES);

    localparam logic OP_GET_ROWS_F32 = 1'b0;
    localparam logic OP_REPEAT_F32   = 1'b1;
    localparam logic [31:0] KERNEL_GET_ROWS = 32'h514e0003;
    localparam logic [31:0] KERNEL_REPEAT   = 32'h514e0004;

    localparam logic [4:0] ST_GMEM_DRAIN = 5'd11;
    localparam logic [4:0] ERR_DESCRIPTOR = 5'd1;
    localparam logic [4:0] ERR_SOURCE     = 5'd2;
    localparam logic [4:0] ERR_INDEX      = 5'd3;
    localparam logic [4:0] ERR_DEST       = 5'd4;
    localparam logic [4:0] ERR_ALIAS      = 5'd5;
    localparam logic [4:0] ERR_INDEX_RANGE = 5'd6;
    localparam logic [4:0] ERR_GMEM       = 5'd7;
    localparam logic [4:0] ERR_STALL      = 5'd8;

    reg clk_i;
    reg rst_i;
    reg start_i;
    wire ready_o;
    wire busy_o;
    reg operation_i;
    reg npu_required_i;
    reg [63:0] command_id_i;
    reg [63:0] canonical_node_id_lo_i;
    reg [63:0] canonical_node_id_hi_i;
    reg dst_shadow_private_i;
    reg windows_generation_valid_i;
    reg [63:0] src_base_i;
    reg [63:0] index_base_i;
    reg [63:0] dst_base_i;
    reg [31:0] element_count_i;
    reg [31:0] source_row_count_i;
    reg [31:0] index_count_i;
    reg [31:0] outer_count_i;
    reg [31:0] repeat_count_i;
    reg [63:0] src_row_stride_i;
    reg [63:0] index_stride_i;
    reg [63:0] dst_row_stride_i;
    reg [63:0] dst_outer_stride_i;
    reg [63:0] src_window_base_i;
    reg [63:0] src_window_bytes_i;
    reg src_window_read_i;
    reg src_window_write_i;
    reg [63:0] index_window_base_i;
    reg [63:0] index_window_bytes_i;
    reg index_window_read_i;
    reg index_window_write_i;
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
    wire [63:0] completion_canonical_node_id_lo_o;
    wire [63:0] completion_canonical_node_id_hi_o;
    wire completion_npu_required_o;
    wire completion_operation_o;
    wire [31:0] completion_kernel_id_o;
    wire done_o;
    wire error_o;
    wire [4:0] error_code_o;
    wire [63:0] indices_completed_o;
    wire [63:0] source_words_completed_o;
    wire [63:0] elements_completed_o;
    wire [63:0] gmem_read_beats_o;
    wire [63:0] gmem_read_responses_o;
    wire [63:0] read_payload_bytes_o;
    wire [63:0] gmem_write_beats_o;
    wire [63:0] gmem_write_responses_o;
    wire [63:0] write_payload_bytes_o;
    wire [63:0] active_cycles_o;
    wire gmem_outstanding_o;

    TensorNpuF32GatherRepeatAdapter #(
        .MAX_ELEMENTS(262144),
        .MAX_INDICES(16),
        .MAX_REPEAT(128),
        .MAX_OUTER(16),
        .STALL_TIMEOUT_CYCLES(32'd12),
        .COMMAND_TIMEOUT_CYCLES(64'd2000000)
    ) dut (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .start_i(start_i),
        .ready_o(ready_o),
        .busy_o(busy_o),
        .operation_i(operation_i),
        .npu_required_i(npu_required_i),
        .command_id_i(command_id_i),
        .canonical_node_id_lo_i(canonical_node_id_lo_i),
        .canonical_node_id_hi_i(canonical_node_id_hi_i),
        .dst_shadow_private_i(dst_shadow_private_i),
        .windows_generation_valid_i(windows_generation_valid_i),
        .src_base_i(src_base_i),
        .index_base_i(index_base_i),
        .dst_base_i(dst_base_i),
        .element_count_i(element_count_i),
        .source_row_count_i(source_row_count_i),
        .index_count_i(index_count_i),
        .outer_count_i(outer_count_i),
        .repeat_count_i(repeat_count_i),
        .src_row_stride_i(src_row_stride_i),
        .index_stride_i(index_stride_i),
        .dst_row_stride_i(dst_row_stride_i),
        .dst_outer_stride_i(dst_outer_stride_i),
        .src_window_base_i(src_window_base_i),
        .src_window_bytes_i(src_window_bytes_i),
        .src_window_read_i(src_window_read_i),
        .src_window_write_i(src_window_write_i),
        .index_window_base_i(index_window_base_i),
        .index_window_bytes_i(index_window_bytes_i),
        .index_window_read_i(index_window_read_i),
        .index_window_write_i(index_window_write_i),
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
        .completion_canonical_node_id_lo_o(
            completion_canonical_node_id_lo_o),
        .completion_canonical_node_id_hi_o(
            completion_canonical_node_id_hi_o),
        .completion_npu_required_o(completion_npu_required_o),
        .completion_operation_o(completion_operation_o),
        .completion_kernel_id_o(completion_kernel_id_o),
        .done_o(done_o),
        .error_o(error_o),
        .error_code_o(error_code_o),
        .indices_completed_o(indices_completed_o),
        .source_words_completed_o(source_words_completed_o),
        .elements_completed_o(elements_completed_o),
        .gmem_read_beats_o(gmem_read_beats_o),
        .gmem_read_responses_o(gmem_read_responses_o),
        .read_payload_bytes_o(read_payload_bytes_o),
        .gmem_write_beats_o(gmem_write_beats_o),
        .gmem_write_responses_o(gmem_write_responses_o),
        .write_payload_bytes_o(write_payload_bytes_o),
        .active_cycles_o(active_cycles_o),
        .gmem_outstanding_o(gmem_outstanding_o)
    );

    initial clk_i = 1'b0;
    always #5 clk_i <= ~clk_i;

    reg [7:0] gmem [0:MEM_BYTES-1];
    reg allow_requests_q;
    reg request_backpressure_q;
    integer response_delay_q;
    integer inject_error_request_ordinal_q;
    reg sparse_mode_q;
    reg [63:0] sparse_index_semantic_addr_q;
    reg [31:0] sparse_index_bits_q;
    reg [31:0] sparse_source_bits_q;

    reg pending_q;
    reg pending_write_q;
    reg [63:0] pending_addr_q;
    reg [63:0] pending_wdata_q;
    reg [7:0] pending_wstrb_q;
    integer pending_delay_q;
    integer pending_ordinal_q;

    integer global_cycles;
    integer accepted_requests;
    integer accepted_reads;
    integer accepted_writes;
    integer successful_writes;
    integer held_stability_cycles;
    reg [63:0] first_read_addr_q;
    reg [63:0] first_write_addr_q;
    reg drain_seen_q;

    reg request_hold_q;
    reg held_request_write_q;
    reg [63:0] held_request_addr_q;
    reg [63:0] held_request_wdata_q;
    reg [7:0] held_request_wstrb_q;

    integer completion_count;
    integer commit_count;
    reg last_done_q;
    reg last_error_q;
    reg [4:0] last_error_code_q;
    reg [63:0] last_command_id_q;
    reg [63:0] last_node_lo_q;
    reg [63:0] last_node_hi_q;
    reg last_required_q;
    reg last_operation_q;
    reg [31:0] last_kernel_id_q;
    reg last_outstanding_q;
    reg [63:0] last_indices_q;
    reg [63:0] last_source_words_q;
    reg [63:0] last_elements_q;
    reg [63:0] last_read_beats_q;
    reg [63:0] last_read_responses_q;
    reg [63:0] last_read_bytes_q;
    reg [63:0] last_write_beats_q;
    reg [63:0] last_write_responses_q;
    reg [63:0] last_write_bytes_q;
    reg [63:0] last_cycles_q;

    integer bus_lane;
    integer memory_index;
    reg [63:0] response_data_calc;
    reg response_error_calc;

    assign gmem_req_ready_i = allow_requests_q
                            && !pending_q
                            && !gmem_rsp_valid_i
                            && (!request_backpressure_q
                                || (global_cycles[2:0] != 3'd2));

    function automatic logic [31:0] raw_source_pattern(
        input integer row,
        input integer lane
    );
        begin
            raw_source_pattern = 32'ha500_0000
                               ^ (32'(row) << 12)
                               ^ 32'(lane);
        end
    endfunction

    function automatic logic [63:0] sparse_read_data(
        input logic [63:0] beat_addr
    );
        logic [63:0] value;
        begin
            value = {sparse_source_bits_q, sparse_source_bits_q};
            if ((sparse_index_semantic_addr_q[1:0] == 2'b00)
                    && ({sparse_index_semantic_addr_q[63:3], 3'b000}
                        == beat_addr)) begin
                if (sparse_index_semantic_addr_q[2])
                    value[63:32] = sparse_index_bits_q;
                else
                    value[31:0] = sparse_index_bits_q;
            end
            sparse_read_data = value;
        end
    endfunction

    task automatic fail_case(input string reason);
        begin
            $display("[NPU-F32-GATHER-REPEAT][FAIL] %s cycle=%0d state=%0d err=%0d outstanding=%0b req=%0d/%0d completion=%0d commit=%0d",
                     reason, global_cycles, dut.state_q, error_code_o,
                     gmem_outstanding_o, accepted_reads, accepted_writes,
                     completion_count, commit_count);
            $display("[NPU-F32-GATHER-REPEAT][EVIDENCE] idx=%0d src=%0d elem=%0d read=%0d/%0d/%0dB write=%0d/%0d/%0dB active=%0d drain=%0b",
                     indices_completed_o, source_words_completed_o,
                     elements_completed_o, gmem_read_beats_o,
                     gmem_read_responses_o, read_payload_bytes_o,
                     gmem_write_beats_o, gmem_write_responses_o,
                     write_payload_bytes_o, active_cycles_o, drain_seen_q);
            $fatal(1);
        end
    endtask

    // Single-outstanding raw-byte GMEM.  Sparse mode permits >4-GiB boundary
    // probes without allocating a giant host array; it still supplies and
    // consumes only raw beats and never evaluates either tensor operation.
    /* verilator lint_off BLKSEQ */
    always @(posedge clk_i) begin
        if (rst_i) begin
            pending_q <= 1'b0;
            pending_write_q <= 1'b0;
            pending_addr_q <= 64'b0;
            pending_wdata_q <= 64'b0;
            pending_wstrb_q <= 8'b0;
            pending_delay_q <= 0;
            pending_ordinal_q <= -1;
            gmem_rsp_valid_i <= 1'b0;
            gmem_rsp_rdata_i <= 64'b0;
            gmem_rsp_error_i <= 1'b0;
            accepted_requests <= 0;
            accepted_reads <= 0;
            accepted_writes <= 0;
            successful_writes <= 0;
            first_read_addr_q <= 64'hffff_ffff_ffff_ffff;
            first_write_addr_q <= 64'hffff_ffff_ffff_ffff;
        end else begin
            if (gmem_rsp_valid_i && gmem_rsp_ready_o) begin
                if (pending_write_q && !gmem_rsp_error_i)
                    successful_writes <= successful_writes + 1;
                pending_q <= 1'b0;
                gmem_rsp_valid_i <= 1'b0;
                gmem_rsp_error_i <= 1'b0;
            end

            if (pending_q && !gmem_rsp_valid_i) begin
                if (pending_delay_q == 0) begin
                    response_error_calc =
                        (inject_error_request_ordinal_q >= 0)
                        && (pending_ordinal_q
                            == inject_error_request_ordinal_q);
                    response_data_calc = 64'b0;
                    if (!pending_write_q) begin
                        if (sparse_mode_q) begin
                            response_data_calc = sparse_read_data(
                                pending_addr_q);
                        end else begin
                            if ((pending_addr_q < MEM_BASE)
                                    || ((pending_addr_q + 64'd8)
                                        > MEM_LIMIT))
                                fail_case("local GMEM read escaped memory");
                            memory_index = pending_addr_q[31:0]
                                         - MEM_BASE[31:0];
                            for (bus_lane = 0; bus_lane < 8;
                                    bus_lane = bus_lane + 1)
                                response_data_calc[
                                    {bus_lane[2:0], 3'b000} +: 8
                                ] = gmem[memory_index + bus_lane];
                        end
                    end else if (!response_error_calc && !sparse_mode_q) begin
                        if ((pending_addr_q < MEM_BASE)
                                || ((pending_addr_q + 64'd8) > MEM_LIMIT))
                            fail_case("local GMEM write escaped memory");
                        memory_index = pending_addr_q[31:0]
                                     - MEM_BASE[31:0];
                        for (bus_lane = 0; bus_lane < 8;
                                bus_lane = bus_lane + 1) begin
                            if (pending_wstrb_q[bus_lane])
                                gmem[memory_index + bus_lane]
                                    <= pending_wdata_q[
                                        {bus_lane[2:0], 3'b000} +: 8
                                    ];
                        end
                    end
                    gmem_rsp_rdata_i <= response_data_calc;
                    gmem_rsp_error_i <= response_error_calc;
                    gmem_rsp_valid_i <= 1'b1;
                end else begin
                    pending_delay_q <= pending_delay_q - 1;
                end
            end

            if (gmem_req_valid_o && gmem_req_ready_i) begin
                if (pending_q || gmem_rsp_valid_i)
                    fail_case("more than one GMEM request outstanding");
                if (gmem_req_addr_o[2:0] != 3'b000)
                    fail_case("unaligned GMEM request");
                if (gmem_req_write_o
                        && !((gmem_req_wstrb_o == 8'h0f)
                             || (gmem_req_wstrb_o == 8'hf0)))
                    fail_case("write did not select one F32 lane");
                if (!gmem_req_write_o && (gmem_req_wstrb_o != 8'b0))
                    fail_case("read request carried write strobes");
                pending_q <= 1'b1;
                pending_write_q <= gmem_req_write_o;
                pending_addr_q <= gmem_req_addr_o;
                pending_wdata_q <= gmem_req_wdata_o;
                pending_wstrb_q <= gmem_req_wstrb_o;
                pending_delay_q <= response_delay_q;
                pending_ordinal_q <= accepted_requests;
                accepted_requests <= accepted_requests + 1;
                if (gmem_req_write_o) begin
                    if (accepted_writes == 0)
                        first_write_addr_q <= gmem_req_addr_o;
                    accepted_writes <= accepted_writes + 1;
                end else begin
                    if (accepted_reads == 0)
                        first_read_addr_q <= gmem_req_addr_o;
                    accepted_reads <= accepted_reads + 1;
                end
            end
        end
    end
    /* verilator lint_on BLKSEQ */

    // A request blocked by ready must remain stable bit-for-bit.
    always @(posedge clk_i) begin
        if (rst_i) begin
            request_hold_q <= 1'b0;
            held_request_write_q <= 1'b0;
            held_request_addr_q <= 64'b0;
            held_request_wdata_q <= 64'b0;
            held_request_wstrb_q <= 8'b0;
            held_stability_cycles <= 0;
        end else if (gmem_req_valid_o && !gmem_req_ready_i) begin
            if (request_hold_q) begin
                if ((gmem_req_write_o != held_request_write_q)
                        || (gmem_req_addr_o != held_request_addr_q)
                        || (gmem_req_wdata_o != held_request_wdata_q)
                        || (gmem_req_wstrb_o != held_request_wstrb_q))
                    fail_case("request changed under backpressure");
                held_stability_cycles <= held_stability_cycles + 1;
            end else begin
                request_hold_q <= 1'b1;
                held_request_write_q <= gmem_req_write_o;
                held_request_addr_q <= gmem_req_addr_o;
                held_request_wdata_q <= gmem_req_wdata_o;
                held_request_wstrb_q <= gmem_req_wstrb_o;
                held_stability_cycles <= held_stability_cycles + 1;
            end
        end else begin
            request_hold_q <= 1'b0;
        end
    end

    // Completion snapshot.  Identity and counters are sampled only while the
    // adapter qualifies them with completion_valid_o.
    always @(posedge clk_i) begin
        if (rst_i) begin
            completion_count <= 0;
            commit_count <= 0;
            last_done_q <= 1'b0;
            last_error_q <= 1'b0;
            last_error_code_q <= 5'b0;
            last_command_id_q <= 64'b0;
            last_node_lo_q <= 64'b0;
            last_node_hi_q <= 64'b0;
            last_required_q <= 1'b0;
            last_operation_q <= 1'b0;
            last_kernel_id_q <= 32'b0;
            last_outstanding_q <= 1'b0;
            last_indices_q <= 64'b0;
            last_source_words_q <= 64'b0;
            last_elements_q <= 64'b0;
            last_read_beats_q <= 64'b0;
            last_read_responses_q <= 64'b0;
            last_read_bytes_q <= 64'b0;
            last_write_beats_q <= 64'b0;
            last_write_responses_q <= 64'b0;
            last_write_bytes_q <= 64'b0;
            last_cycles_q <= 64'b0;
        end else if (completion_valid_o) begin
            completion_count <= completion_count + 1;
            if (dst_commit_o)
                commit_count <= commit_count + 1;
            last_done_q <= done_o;
            last_error_q <= error_o;
            last_error_code_q <= error_code_o;
            last_command_id_q <= completion_command_id_o;
            last_node_lo_q <= completion_canonical_node_id_lo_o;
            last_node_hi_q <= completion_canonical_node_id_hi_o;
            last_required_q <= completion_npu_required_o;
            last_operation_q <= completion_operation_o;
            last_kernel_id_q <= completion_kernel_id_o;
            last_outstanding_q <= gmem_outstanding_o;
            last_indices_q <= indices_completed_o;
            last_source_words_q <= source_words_completed_o;
            last_elements_q <= elements_completed_o;
            last_read_beats_q <= gmem_read_beats_o;
            last_read_responses_q <= gmem_read_responses_o;
            last_read_bytes_q <= read_payload_bytes_o;
            last_write_beats_q <= gmem_write_beats_o;
            last_write_responses_q <= gmem_write_responses_o;
            last_write_bytes_q <= write_payload_bytes_o;
            last_cycles_q <= active_cycles_o;
        end
    end

    always @(posedge clk_i) begin
        if (rst_i) begin
            global_cycles <= 0;
            drain_seen_q <= 1'b0;
        end else begin
            global_cycles <= global_cycles + 1;
            if (dut.state_q == ST_GMEM_DRAIN)
                drain_seen_q <= 1'b1;
        end
    end

    task automatic put_u32(
        input logic [63:0] address,
        input logic [31:0] value
    );
        integer offset;
        begin
            if ((address < MEM_BASE) || ((address + 64'd4) > MEM_LIMIT))
                fail_case("put_u32 address escaped local memory");
            offset = address[31:0] - MEM_BASE[31:0];
            gmem[offset + 0] = value[7:0];
            gmem[offset + 1] = value[15:8];
            gmem[offset + 2] = value[23:16];
            gmem[offset + 3] = value[31:24];
        end
    endtask

    function automatic logic [31:0] get_u32(input logic [63:0] address);
        integer offset;
        begin
            if ((address < MEM_BASE) || ((address + 64'd4) > MEM_LIMIT)) begin
                get_u32 = 32'hxxxx_xxxx;
            end else begin
                offset = address[31:0] - MEM_BASE[31:0];
                get_u32 = {gmem[offset + 3], gmem[offset + 2],
                           gmem[offset + 1], gmem[offset + 0]};
            end
        end
    endfunction

    task automatic reset_case;
        begin
            start_i = 1'b0;
            rst_i = 1'b1;
            allow_requests_q = 1'b1;
            request_backpressure_q = 1'b0;
            response_delay_q = 0;
            inject_error_request_ordinal_q = -1;
            sparse_mode_q = 1'b0;
            sparse_index_semantic_addr_q = 64'b0;
            sparse_index_bits_q = 32'b0;
            sparse_source_bits_q = 32'h89ab_cdef;
            repeat (3) @(posedge clk_i);
            @(negedge clk_i);
            rst_i = 1'b0;
            @(posedge clk_i);
            #1;
            if (!ready_o || busy_o || completion_valid_o
                    || gmem_outstanding_o)
                fail_case("reset did not restore idle owner");
        end
    endtask

    task automatic set_identity(
        input logic [63:0] command,
        input logic [63:0] node_lo,
        input logic [63:0] node_hi
    );
        begin
            command_id_i = command;
            canonical_node_id_lo_i = node_lo;
            canonical_node_id_hi_i = node_hi;
            npu_required_i = 1'b1;
        end
    endtask

    task automatic set_small_get_descriptor;
        begin
            operation_i = OP_GET_ROWS_F32;
            set_identity(64'h0102_0304_0506_0708,
                         64'h1111_2222_3333_4444,
                         64'haaaa_bbbb_cccc_dddd);
            dst_shadow_private_i = 1'b1;
            windows_generation_valid_i = 1'b1;
            src_base_i = 64'h0000_0000_0000_1104;
            index_base_i = 64'h0000_0000_0000_1404;
            dst_base_i = 64'h0000_0000_0000_1804;
            element_count_i = 32'd5;
            source_row_count_i = 32'd3;
            index_count_i = 32'd2;
            outer_count_i = 32'b0;
            repeat_count_i = 32'b0;
            src_row_stride_i = 64'd24;
            index_stride_i = 64'd8;
            dst_row_stride_i = 64'd24;
            dst_outer_stride_i = 64'b0;
            src_window_base_i = 64'h0000_0000_0000_1100;
            src_window_bytes_i = 64'h0000_0000_0000_0100;
            src_window_read_i = 1'b1;
            src_window_write_i = 1'b0;
            index_window_base_i = 64'h0000_0000_0000_1400;
            index_window_bytes_i = 64'h0000_0000_0000_0100;
            index_window_read_i = 1'b1;
            index_window_write_i = 1'b0;
            dst_window_base_i = 64'h0000_0000_0000_1800;
            dst_window_bytes_i = 64'h0000_0000_0000_0100;
            dst_window_read_i = 1'b0;
            dst_window_write_i = 1'b1;
        end
    endtask

    task automatic load_small_get_data;
        integer row;
        integer lane;
        integer byte_index;
        integer destination_offset;
        begin
            for (row = 0; row < 3; row = row + 1) begin
                for (lane = 0; lane < 5; lane = lane + 1)
                    put_u32(src_base_i + (row * 24) + (lane * 4),
                            raw_source_pattern(row, lane));
            end
            put_u32(index_base_i + 64'd0, 32'd2);
            put_u32(index_base_i + 64'd8, 32'd0);
            destination_offset = dst_base_i[31:0] - MEM_BASE[31:0];
            for (byte_index = 0; byte_index < 48;
                    byte_index = byte_index + 1)
                gmem[destination_offset + byte_index] = 8'hcc;
        end
    endtask

    task automatic pulse_start;
        begin
            while (!ready_o)
                @(posedge clk_i);
            @(negedge clk_i);
            start_i = 1'b1;
            @(negedge clk_i);
            start_i = 1'b0;
        end
    endtask

    task automatic wait_completion(
        input bit expect_error,
        input logic [4:0] expected_code,
        input integer max_cycles
    );
        integer before_count;
        integer waited;
        begin
            before_count = completion_count;
            waited = 0;
            while ((completion_count == before_count)
                    && (waited < max_cycles)) begin
                @(posedge clk_i);
                #1;
                waited = waited + 1;
            end
            if (completion_count != (before_count + 1))
                fail_case("terminal completion timeout or duplicate");
            if (expect_error) begin
                if (!last_error_q || last_done_q
                        || (last_error_code_q != expected_code))
                    fail_case("unexpected error terminal status");
            end else begin
                if (!last_done_q || last_error_q
                        || (last_error_code_q != 5'b0))
                    fail_case("unexpected success terminal status");
            end
            if (last_outstanding_q)
                fail_case("terminal completion retained GMEM credit");
        end
    endtask

    task automatic check_identity(
        input logic [63:0] command,
        input logic [63:0] node_lo,
        input logic [63:0] node_hi,
        input logic operation,
        input logic [31:0] kernel
    );
        begin
            if ((last_command_id_q != command)
                    || (last_node_lo_q != node_lo)
                    || (last_node_hi_q != node_hi)
                    || !last_required_q
                    || (last_operation_q != operation)
                    || (last_kernel_id_q != kernel))
                fail_case("completion identity was not exact");
        end
    endtask

    task automatic test_small_get_success;
        integer row_position;
        integer lane;
        integer source_row;
        logic [63:0] original_command;
        logic [63:0] original_lo;
        logic [63:0] original_hi;
        begin
            reset_case();
            set_small_get_descriptor();
            load_small_get_data();
            request_backpressure_q = 1'b1;
            response_delay_q = 2;
            original_command = command_id_i;
            original_lo = canonical_node_id_lo_i;
            original_hi = canonical_node_id_hi_i;
            pulse_start();

            // A busy start with hostile identity/descriptor values must not
            // mutate the resident command.
            while (!busy_o)
                @(posedge clk_i);
            @(negedge clk_i);
            start_i = 1'b1;
            command_id_i = 64'hffff_ffff_ffff_ffff;
            canonical_node_id_lo_i = 64'b0;
            canonical_node_id_hi_i = 64'b0;
            dst_base_i = 64'hffff_ffff_ffff_fffc;
            @(negedge clk_i);
            start_i = 1'b0;
            command_id_i = original_command;
            canonical_node_id_lo_i = original_lo;
            canonical_node_id_hi_i = original_hi;
            dst_base_i = 64'h0000_0000_0000_1804;

            wait_completion(1'b0, 5'b0, 5000);
            check_identity(original_command, original_lo, original_hi,
                           OP_GET_ROWS_F32, KERNEL_GET_ROWS);
            if ((commit_count != 1) || (accepted_reads != 12)
                    || (accepted_writes != 10)
                    || (successful_writes != 10)
                    || (last_indices_q != 64'd2)
                    || (last_source_words_q != 64'd10)
                    || (last_elements_q != 64'd10)
                    || (last_read_beats_q != 64'd12)
                    || (last_read_responses_q != 64'd12)
                    || (last_read_bytes_q != 64'd48)
                    || (last_write_beats_q != 64'd10)
                    || (last_write_responses_q != 64'd10)
                    || (last_write_bytes_q != 64'd40)
                    || (last_cycles_q == 64'b0)
                    || (held_stability_cycles == 0))
                fail_case("small GET_ROWS counters/backpressure mismatch");
            for (row_position = 0; row_position < 2;
                    row_position = row_position + 1) begin
                source_row = (row_position == 0) ? 2 : 0;
                for (lane = 0; lane < 5; lane = lane + 1) begin
                    if (get_u32(64'h1804 + (row_position * 24)
                                + (lane * 4))
                            !== raw_source_pattern(source_row, lane))
                        fail_case("small GET_ROWS raw-bit oracle mismatch");
                end
                if (get_u32(64'h1804 + (row_position * 24) + 20)
                        !== 32'hcccc_cccc)
                    fail_case("GET_ROWS changed destination padding");
            end
            $display("[NPU-F32-GATHER-REPEAT][INFO] get-small=idx2/D5/read12/write10/raw-bit-exact identity=64+128 backpressure=stable");
        end
    endtask

    task automatic test_empty_get(input integer dimension);
        logic [63:0] row_bytes;
        begin
            reset_case();
            set_small_get_descriptor();
            row_bytes = 64'(dimension) * 64'd4;
            set_identity(64'h2000_0000_0000_0000 + 64'(dimension),
                         64'h2020_2020_2020_2020,
                         64'h3030_3030_3030_3030);
            element_count_i = 32'(dimension);
            source_row_count_i = 32'b0;
            index_count_i = 32'b0;
            src_row_stride_i = row_bytes;
            index_stride_i = 64'd4;
            dst_row_stride_i = row_bytes;
            src_base_i = 64'h0000_0000_0000_4000;
            index_base_i = 64'h0000_0000_0000_5000;
            dst_base_i = 64'h0000_0000_0000_6000;
            src_window_base_i = src_base_i;
            src_window_bytes_i = 64'b0;
            index_window_base_i = index_base_i;
            index_window_bytes_i = 64'b0;
            dst_window_base_i = dst_base_i;
            dst_window_bytes_i = 64'b0;
            pulse_start();
            wait_completion(1'b0, 5'b0, 50);
            check_identity(command_id_i, canonical_node_id_lo_i,
                           canonical_node_id_hi_i, OP_GET_ROWS_F32,
                           KERNEL_GET_ROWS);
            if ((accepted_requests != 0) || (commit_count != 1)
                    || (last_indices_q != 0) || (last_source_words_q != 0)
                    || (last_elements_q != 0) || (last_read_beats_q != 0)
                    || (last_write_beats_q != 0))
                fail_case("empty GET_ROWS was not zero-traffic success");
            $display("[NPU-F32-GATHER-REPEAT][INFO] get-empty=D%0d/N0 zero-traffic commit=1",
                     dimension);
        end
    endtask

    task automatic test_sparse_get_boundary(input integer dimension);
        logic [63:0] row_bytes;
        logic [63:0] source_window_size;
        logic [63:0] destination_window_size;
        begin
            reset_case();
            set_small_get_descriptor();
            row_bytes = 64'(dimension) * 64'd4;
            source_window_size = (row_bytes * 64'd2) + 64'd8;
            destination_window_size = row_bytes + 64'd8;
            set_identity(64'h3000_0000_0000_0000 + 64'(dimension),
                         64'h4040_4040_4040_4040,
                         64'h5050_5050_5050_5050);
            element_count_i = 32'(dimension);
            source_row_count_i = 32'd2;
            index_count_i = 32'd1;
            src_row_stride_i = row_bytes;
            index_stride_i = 64'd4;
            dst_row_stride_i = row_bytes;
            src_base_i = 64'h0000_0001_0000_1004;
            index_base_i = 64'h0000_0002_0000_1004;
            dst_base_i = 64'h0000_0003_0000_1004;
            src_window_base_i = 64'h0000_0001_0000_1000;
            src_window_bytes_i = source_window_size;
            index_window_base_i = 64'h0000_0002_0000_1000;
            index_window_bytes_i = 64'd8;
            dst_window_base_i = 64'h0000_0003_0000_1000;
            dst_window_bytes_i = destination_window_size;
            sparse_mode_q = 1'b1;
            sparse_index_semantic_addr_q = index_base_i;
            sparse_index_bits_q = 32'd0;
            inject_error_request_ordinal_q = 1;
            pulse_start();
            wait_completion(1'b1, ERR_GMEM, 100);
            check_identity(command_id_i, canonical_node_id_lo_i,
                           canonical_node_id_hi_i, OP_GET_ROWS_F32,
                           KERNEL_GET_ROWS);
            if ((accepted_reads != 2) || (accepted_writes != 0)
                    || (last_read_beats_q != 2)
                    || (last_read_responses_q != 2)
                    || (last_read_bytes_q != 4)
                    || (last_indices_q != 1)
                    || (last_source_words_q != 0)
                    || (last_elements_q != 0) || (commit_count != 0))
                fail_case("sparse GET_ROWS boundary proof mismatch");
            $display("[NPU-F32-GATHER-REPEAT][INFO] get-boundary=D%0d/N1 128b-preflight=accepted first-source-error=no-publication",
                     dimension);
        end
    endtask

    task automatic set_small_repeat_descriptor;
        begin
            operation_i = OP_REPEAT_F32;
            set_identity(64'h6060_0000_0000_0001,
                         64'h6161_6161_6161_6161,
                         64'h7171_7171_7171_7171);
            dst_shadow_private_i = 1'b1;
            windows_generation_valid_i = 1'b1;
            src_base_i = 64'h0000_0000_0000_2104;
            index_base_i = 64'h0000_0000_0000_2800;
            dst_base_i = 64'h0000_0000_0000_3004;
            element_count_i = 32'd3;
            source_row_count_i = 32'b0;
            index_count_i = 32'b0;
            outer_count_i = 32'd2;
            repeat_count_i = 32'd4;
            src_row_stride_i = 64'd16;
            index_stride_i = 64'b0;
            dst_row_stride_i = 64'd16;
            dst_outer_stride_i = 64'd64;
            src_window_base_i = 64'h0000_0000_0000_2100;
            src_window_bytes_i = 64'h0000_0000_0000_0100;
            src_window_read_i = 1'b1;
            src_window_write_i = 1'b0;
            index_window_base_i = 64'h0000_0000_0000_2800;
            index_window_bytes_i = 64'b0;
            index_window_read_i = 1'b1;
            index_window_write_i = 1'b0;
            dst_window_base_i = 64'h0000_0000_0000_3000;
            dst_window_bytes_i = 64'h0000_0000_0000_0200;
            dst_window_read_i = 1'b0;
            dst_window_write_i = 1'b1;
        end
    endtask

    task automatic test_small_repeat_success;
        integer outer;
        integer lane;
        integer repetition;
        integer byte_index;
        integer destination_offset;
        begin
            reset_case();
            set_small_repeat_descriptor();
            for (outer = 0; outer < 2; outer = outer + 1) begin
                for (lane = 0; lane < 3; lane = lane + 1)
                    put_u32(src_base_i + (outer * 16) + (lane * 4),
                            raw_source_pattern(outer + 8, lane));
            end
            destination_offset = dst_base_i[31:0] - MEM_BASE[31:0];
            for (byte_index = 0; byte_index < 128;
                    byte_index = byte_index + 1)
                gmem[destination_offset + byte_index] = 8'hcc;
            request_backpressure_q = 1'b1;
            response_delay_q = 1;
            pulse_start();
            wait_completion(1'b0, 5'b0, 5000);
            check_identity(command_id_i, canonical_node_id_lo_i,
                           canonical_node_id_hi_i, OP_REPEAT_F32,
                           KERNEL_REPEAT);
            if ((commit_count != 1) || (accepted_reads != 6)
                    || (accepted_writes != 24)
                    || (successful_writes != 24)
                    || (last_indices_q != 0)
                    || (last_source_words_q != 6)
                    || (last_elements_q != 24)
                    || (last_read_beats_q != 6)
                    || (last_read_responses_q != 6)
                    || (last_read_bytes_q != 24)
                    || (last_write_beats_q != 24)
                    || (last_write_responses_q != 24)
                    || (last_write_bytes_q != 96))
                fail_case("small REPEAT counters mismatch");
            for (outer = 0; outer < 2; outer = outer + 1) begin
                for (repetition = 0; repetition < 4;
                        repetition = repetition + 1) begin
                    for (lane = 0; lane < 3; lane = lane + 1) begin
                        if (get_u32(dst_base_i + (outer * 64)
                                    + (repetition * 16) + (lane * 4))
                                !== raw_source_pattern(outer + 8, lane))
                            fail_case("small REPEAT raw-bit oracle mismatch");
                    end
                    if (get_u32(dst_base_i + (outer * 64)
                                + (repetition * 16) + 12)
                            !== 32'hcccc_cccc)
                        fail_case("REPEAT changed destination padding");
                end
            end
            $display("[NPU-F32-GATHER-REPEAT][INFO] repeat-small=D3/R4/O2 source-read-once=6 writes=24 raw-bit-exact");
        end
    endtask

    task automatic test_qwen_repeat_boundary;
        begin
            reset_case();
            set_small_repeat_descriptor();
            set_identity(64'h7070_0000_0000_0001,
                         64'h8181_8181_8181_8181,
                         64'h9191_9191_9191_9191);
            src_base_i = 64'h0000_0001_1000_1004;
            index_base_i = 64'h0000_0002_1000_1000;
            dst_base_i = 64'h0000_0003_1000_1004;
            element_count_i = 32'd128;
            outer_count_i = 32'd16;
            repeat_count_i = 32'd128;
            src_row_stride_i = 64'd512;
            dst_row_stride_i = 64'd512;
            dst_outer_stride_i = 64'd65536;
            src_window_base_i = 64'h0000_0001_1000_1000;
            src_window_bytes_i = 64'd8200;
            index_window_base_i = index_base_i;
            index_window_bytes_i = 64'b0;
            dst_window_base_i = 64'h0000_0003_1000_1000;
            dst_window_bytes_i = 64'd1048584;
            sparse_mode_q = 1'b1;
            sparse_source_bits_q = 32'hdeed_beef;
            inject_error_request_ordinal_q = 1;
            pulse_start();
            wait_completion(1'b1, ERR_GMEM, 100);
            check_identity(command_id_i, canonical_node_id_lo_i,
                           canonical_node_id_hi_i, OP_REPEAT_F32,
                           KERNEL_REPEAT);
            if ((accepted_reads != 1) || (accepted_writes != 1)
                    || (first_read_addr_q
                        != 64'h0000_0001_1000_1000)
                    || (first_write_addr_q
                        != 64'h0000_0003_1000_1000)
                    || (last_source_words_q != 1)
                    || (last_read_bytes_q != 4)
                    || (last_write_bytes_q != 0)
                    || (last_elements_q != 0) || (commit_count != 0))
                fail_case("Qwen REPEAT sparse admission mismatch");
            $display("[NPU-F32-GATHER-REPEAT][INFO] repeat-qwen=[128,1,16]->[128,128,16] 128b-preflight=accepted RTL-read/write=observed failed-private-commit=0");
        end
    endtask

    task automatic test_negative_index;
        begin
            reset_case();
            set_small_get_descriptor();
            element_count_i = 32'd2;
            index_count_i = 32'd1;
            src_row_stride_i = 64'd8;
            dst_row_stride_i = 64'd8;
            put_u32(index_base_i, 32'hffff_ffff);
            pulse_start();
            wait_completion(1'b1, ERR_INDEX_RANGE, 100);
            check_identity(command_id_i, canonical_node_id_lo_i,
                           canonical_node_id_hi_i, OP_GET_ROWS_F32,
                           KERNEL_GET_ROWS);
            if ((accepted_reads != 1) || (accepted_writes != 0)
                    || (last_indices_q != 1) || (last_read_bytes_q != 4)
                    || (last_elements_q != 0) || (commit_count != 0))
                fail_case("negative index was not rejected before source");
            $display("[NPU-F32-GATHER-REPEAT][INFO] get-negative-index=runtime-rejected writes=0 commit=0");
        end
    endtask

    task automatic expect_preflight_error(
        input logic [4:0] expected_code,
        input string label_text
    );
        begin
            pulse_start();
            wait_completion(1'b1, expected_code, 50);
            if ((accepted_requests != 0) || (commit_count != 0)
                    || (last_read_beats_q != 0)
                    || (last_write_beats_q != 0))
                fail_case("preflight error emitted GMEM traffic");
            $display("[NPU-F32-GATHER-REPEAT][INFO] preflight-%s=error%0d traffic=0",
                     label_text, expected_code);
        end
    endtask

    task automatic test_preflight_failures;
        begin
            reset_case();
            set_small_get_descriptor();
            source_row_count_i = 32'b0;
            expect_preflight_error(ERR_DESCRIPTOR, "row-count");

            reset_case();
            set_small_get_descriptor();
            src_row_stride_i = 64'd16;
            expect_preflight_error(ERR_DESCRIPTOR, "row-stride");

            reset_case();
            set_small_get_descriptor();
            src_window_write_i = 1'b1;
            expect_preflight_error(ERR_DESCRIPTOR, "permission");

            reset_case();
            set_small_get_descriptor();
            src_window_bytes_i = 64'd8;
            expect_preflight_error(ERR_SOURCE, "source-span");

            reset_case();
            set_small_get_descriptor();
            index_window_bytes_i = 64'd8;
            expect_preflight_error(ERR_INDEX, "index-span");

            reset_case();
            set_small_get_descriptor();
            dst_window_bytes_i = 64'd8;
            expect_preflight_error(ERR_DEST, "destination-span");

            reset_case();
            set_small_get_descriptor();
            dst_base_i = src_base_i;
            dst_window_base_i = src_window_base_i;
            dst_window_bytes_i = src_window_bytes_i;
            expect_preflight_error(ERR_ALIAS, "physical-alias");

            reset_case();
            set_small_get_descriptor();
            element_count_i = 32'd1;
            source_row_count_i = 32'd1;
            index_count_i = 32'd1;
            src_row_stride_i = 64'd4;
            dst_row_stride_i = 64'd4;
            src_base_i = 64'hffff_ffff_ffff_fffc;
            src_window_base_i = 64'hffff_ffff_ffff_fff8;
            src_window_bytes_i = 64'd8;
            expect_preflight_error(ERR_SOURCE, "128b-overflow");
        end
    endtask

    task automatic test_partial_private_write_failure;
        logic [31:0] first_expected;
        begin
            reset_case();
            set_small_get_descriptor();
            element_count_i = 32'd3;
            index_count_i = 32'd1;
            src_row_stride_i = 64'd16;
            dst_row_stride_i = 64'd16;
            put_u32(index_base_i, 32'd2);
            put_u32(src_base_i + 64'd32, raw_source_pattern(2, 0));
            put_u32(src_base_i + 64'd36, raw_source_pattern(2, 1));
            put_u32(src_base_i + 64'd40, raw_source_pattern(2, 2));
            put_u32(dst_base_i + 64'd0, 32'hcccc_cccc);
            put_u32(dst_base_i + 64'd4, 32'hcccc_cccc);
            put_u32(dst_base_i + 64'd8, 32'hcccc_cccc);
            inject_error_request_ordinal_q = 4;
            pulse_start();
            wait_completion(1'b1, ERR_GMEM, 200);
            check_identity(command_id_i, canonical_node_id_lo_i,
                           canonical_node_id_hi_i, OP_GET_ROWS_F32,
                           KERNEL_GET_ROWS);
            first_expected = raw_source_pattern(2, 0);
            if ((get_u32(dst_base_i) !== first_expected)
                    || (get_u32(dst_base_i + 64'd4) !== 32'hcccc_cccc)
                    || (last_elements_q != 1)
                    || (last_write_bytes_q != 4)
                    || (last_write_beats_q != 2)
                    || (last_write_responses_q != 2)
                    || (commit_count != 0))
                fail_case("private partial write escaped publication rule");
            $display("[NPU-F32-GATHER-REPEAT][INFO] write-error=private-bytes1 publication-commit0 terminal-outstanding0");
        end
    endtask

    task automatic test_timeout_drain;
        begin
            reset_case();
            set_small_get_descriptor();
            put_u32(index_base_i, 32'd0);
            response_delay_q = 24;
            pulse_start();
            wait_completion(1'b1, ERR_STALL, 100);
            check_identity(command_id_i, canonical_node_id_lo_i,
                           canonical_node_id_hi_i, OP_GET_ROWS_F32,
                           KERNEL_GET_ROWS);
            if (!drain_seen_q || (accepted_requests != 1)
                    || (last_read_beats_q != 1)
                    || (last_read_responses_q != 1)
                    || (last_read_bytes_q != 0)
                    || (commit_count != 0) || last_outstanding_q)
                fail_case("accepted timeout did not drain exactly once");
            $display("[NPU-F32-GATHER-REPEAT][INFO] response-timeout=drained-one-credit payload-consumed0 commit0");
        end
    endtask

    task automatic test_request_timeout_stability;
        begin
            reset_case();
            set_small_get_descriptor();
            allow_requests_q = 1'b0;
            pulse_start();
            wait_completion(1'b1, ERR_STALL, 100);
            check_identity(command_id_i, canonical_node_id_lo_i,
                           canonical_node_id_hi_i, OP_GET_ROWS_F32,
                           KERNEL_GET_ROWS);
            if ((accepted_requests != 0) || (held_stability_cycles < 4)
                    || drain_seen_q || (commit_count != 0))
                fail_case("request timeout/backpressure stability mismatch");
            $display("[NPU-F32-GATHER-REPEAT][INFO] request-timeout=stable-cycles%0d accepted0 outstanding0",
                     held_stability_cycles);
        end
    endtask

    integer init_index;
    initial begin
        rst_i = 1'b1;
        start_i = 1'b0;
        operation_i = OP_GET_ROWS_F32;
        npu_required_i = 1'b0;
        command_id_i = 64'b0;
        canonical_node_id_lo_i = 64'b0;
        canonical_node_id_hi_i = 64'b0;
        dst_shadow_private_i = 1'b0;
        windows_generation_valid_i = 1'b0;
        src_base_i = 64'b0;
        index_base_i = 64'b0;
        dst_base_i = 64'b0;
        element_count_i = 32'b0;
        source_row_count_i = 32'b0;
        index_count_i = 32'b0;
        outer_count_i = 32'b0;
        repeat_count_i = 32'b0;
        src_row_stride_i = 64'b0;
        index_stride_i = 64'b0;
        dst_row_stride_i = 64'b0;
        dst_outer_stride_i = 64'b0;
        src_window_base_i = 64'b0;
        src_window_bytes_i = 64'b0;
        src_window_read_i = 1'b0;
        src_window_write_i = 1'b0;
        index_window_base_i = 64'b0;
        index_window_bytes_i = 64'b0;
        index_window_read_i = 1'b0;
        index_window_write_i = 1'b0;
        dst_window_base_i = 64'b0;
        dst_window_bytes_i = 64'b0;
        dst_window_read_i = 1'b0;
        dst_window_write_i = 1'b0;
        allow_requests_q = 1'b0;
        request_backpressure_q = 1'b0;
        response_delay_q = 0;
        inject_error_request_ordinal_q = -1;
        sparse_mode_q = 1'b0;
        sparse_index_semantic_addr_q = 64'b0;
        sparse_index_bits_q = 32'b0;
        sparse_source_bits_q = 32'h89ab_cdef;
        for (init_index = 0; init_index < MEM_BYTES;
                init_index = init_index + 1)
            gmem[init_index] = 8'hcc;

        test_small_get_success();
        test_empty_get(18432);
        test_empty_get(262144);
        test_sparse_get_boundary(1024);
        test_sparse_get_boundary(18432);
        test_sparse_get_boundary(262144);
        test_small_repeat_success();
        test_qwen_repeat_boundary();
        test_negative_index();
        test_preflight_failures();
        test_partial_private_write_failure();
        test_timeout_drain();
        test_request_timeout_stability();

        $display("[NPU-F32-GATHER-REPEAT][PASS] get=D1024/18432/262144,N0+N1 repeat=small+qwen identity=64+128 windows=R/R/W preflight=128b single_outstanding=1 assertions=off waveform=off checks=20");
        $finish;
    end

endmodule

`default_nettype wire
