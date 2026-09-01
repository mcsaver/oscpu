`timescale 1ns/1ps
`default_nettype none

// Raw-GMEM transaction verification for the frozen RMS_NORM/L2_NORM
// writeback profiles.  Expected tensors are literal raw-bit oracles.  This TB
// uses no host floating-point/foreign arithmetic and no hierarchical probes.
module tb_norm_writeback_adapter;

    localparam integer MEM_BYTES = 262144;
    localparam logic [63:0] MEM_BASE  = 64'h0000_0000_0000_1000;
    localparam logic [63:0] MEM_LIMIT = MEM_BASE + 64'(MEM_BYTES);

    localparam logic [2:0] REDUCE_RMS = 3'd4;
    localparam logic [2:0] REDUCE_L2  = 3'd5;
    localparam logic [31:0] EPSILON_QWEN = 32'h358637bd;
    localparam logic [31:0] KERNEL_REDUCE = 32'h514e0011;

    localparam logic [7:0] PROFILE_RMS_D1024_R1 = 8'd0;
    localparam logic [7:0] PROFILE_RMS_D128_R16 = 8'd1;
    localparam logic [7:0] PROFILE_RMS_D256_R2  = 8'd2;
    localparam logic [7:0] PROFILE_RMS_D256_R8  = 8'd3;
    localparam logic [7:0] PROFILE_L2_D128_R16  = 8'd4;
    localparam logic [7:0] PROFILE_INVALID      = 8'hff;

    localparam logic [4:0] ERR_PROFILE = 5'd1;
    localparam logic [4:0] ERR_SRC0    = 5'd2;
    localparam logic [4:0] ERR_SRC1    = 5'd3;
    localparam logic [4:0] ERR_DST     = 5'd4;
    localparam logic [4:0] ERR_ALIAS   = 5'd5;
    localparam logic [4:0] ERR_ENGINE  = 5'd6;
    localparam logic [4:0] ERR_GMEM    = 5'd7;
    localparam logic [4:0] ERR_STALL   = 5'd8;

    localparam logic [4:0] FLAGS_NONE = 5'b00000;
    localparam logic [4:0] FLAGS_NX   = 5'b00001;

    reg clk_i, rst_i, start_i;
    wire ready_o, busy_o;
    reg [2:0] reduce_op_i;
    reg [31:0] epsilon_bits_i;
    reg op_params_tail_zero_i, npu_required_i;
    reg [63:0] command_id_i;
    reg [63:0] canonical_node_id_lo_i, canonical_node_id_hi_i;
    reg dst_shadow_private_i, windows_generation_valid_i;
    reg [31:0] ne0_i, ne1_i, ne2_i, ne3_i;
    reg [63:0] src0_base_i;
    reg [63:0] src0_nb0_i, src0_nb1_i, src0_nb2_i, src0_nb3_i;
    reg [63:0] src1_base_i;
    reg [63:0] src1_nb0_i, src1_nb1_i, src1_nb2_i, src1_nb3_i;
    reg [63:0] dst_base_i;
    reg [63:0] dst_nb0_i, dst_nb1_i, dst_nb2_i, dst_nb3_i;
    reg [63:0] src0_window_base_i, src0_window_bytes_i;
    reg src0_window_read_i, src0_window_write_i;
    reg [63:0] src1_window_base_i, src1_window_bytes_i;
    reg src1_window_read_i, src1_window_write_i;
    reg [63:0] dst_window_base_i, dst_window_bytes_i;
    reg dst_window_read_i, dst_window_write_i;

    wire gmem_req_valid_o, gmem_req_ready_i, gmem_req_write_o;
    wire [63:0] gmem_req_addr_o, gmem_req_wdata_o;
    wire [7:0] gmem_req_wstrb_o;
    reg gmem_rsp_valid_i;
    wire gmem_rsp_ready_o;
    reg [63:0] gmem_rsp_rdata_i;
    reg gmem_rsp_error_i;

    wire completion_valid_o, dst_commit_o;
    wire [63:0] completion_command_id_o;
    wire [63:0] completion_canonical_node_id_lo_o;
    wire [63:0] completion_canonical_node_id_hi_o;
    wire completion_npu_required_o;
    wire [2:0] completion_reduce_op_o;
    wire [31:0] completion_epsilon_bits_o;
    wire [7:0] completion_profile_id_o;
    wire [31:0] completion_kernel_id_o;
    wire [31:0] completion_operator_census_o;
    wire [31:0] completion_profile_census_o;
    wire done_o, error_o;
    wire [4:0] error_code_o, engine_error_code_o;
    wire [63:0] rows_completed_o, source_words_completed_o;
    wire [63:0] engine_input_elements_o, engine_output_elements_o;
    wire [63:0] elements_completed_o;
    wire [63:0] engine_launches_o, engine_terminals_o, engine_aborts_o;
    wire [4:0] engine_flags_or_o;
    wire [63:0] engine_active_cycles_o;
    wire [63:0] gmem_read_beats_o, gmem_read_responses_o;
    wire [63:0] read_payload_bytes_o;
    wire [63:0] gmem_write_beats_o, gmem_write_responses_o;
    wire [63:0] write_payload_bytes_o, active_cycles_o;
    wire gmem_outstanding_o, engine_outstanding_o, gmem_drain_o;

    TensorNpuNormWritebackAdapter #(
        .STALL_TIMEOUT_CYCLES(32'd12),
        .COMMAND_TIMEOUT_CYCLES(64'd2000000),
        .ENGINE_STALL_TIMEOUT_CYCLES(32'd256),
        .ENGINE_COMMAND_TIMEOUT_CYCLES(32'd262144)
    ) dut (
        .clk_i(clk_i), .rst_i(rst_i), .start_i(start_i),
        .ready_o(ready_o), .busy_o(busy_o), .reduce_op_i(reduce_op_i),
        .epsilon_bits_i(epsilon_bits_i),
        .op_params_tail_zero_i(op_params_tail_zero_i),
        .npu_required_i(npu_required_i), .command_id_i(command_id_i),
        .canonical_node_id_lo_i(canonical_node_id_lo_i),
        .canonical_node_id_hi_i(canonical_node_id_hi_i),
        .dst_shadow_private_i(dst_shadow_private_i),
        .windows_generation_valid_i(windows_generation_valid_i),
        .ne0_i(ne0_i), .ne1_i(ne1_i), .ne2_i(ne2_i), .ne3_i(ne3_i),
        .src0_base_i(src0_base_i), .src0_nb0_i(src0_nb0_i),
        .src0_nb1_i(src0_nb1_i), .src0_nb2_i(src0_nb2_i),
        .src0_nb3_i(src0_nb3_i), .src1_base_i(src1_base_i),
        .src1_nb0_i(src1_nb0_i), .src1_nb1_i(src1_nb1_i),
        .src1_nb2_i(src1_nb2_i), .src1_nb3_i(src1_nb3_i),
        .dst_base_i(dst_base_i), .dst_nb0_i(dst_nb0_i),
        .dst_nb1_i(dst_nb1_i), .dst_nb2_i(dst_nb2_i),
        .dst_nb3_i(dst_nb3_i),
        .src0_window_base_i(src0_window_base_i),
        .src0_window_bytes_i(src0_window_bytes_i),
        .src0_window_read_i(src0_window_read_i),
        .src0_window_write_i(src0_window_write_i),
        .src1_window_base_i(src1_window_base_i),
        .src1_window_bytes_i(src1_window_bytes_i),
        .src1_window_read_i(src1_window_read_i),
        .src1_window_write_i(src1_window_write_i),
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
        .completion_valid_o(completion_valid_o), .dst_commit_o(dst_commit_o),
        .completion_command_id_o(completion_command_id_o),
        .completion_canonical_node_id_lo_o(
            completion_canonical_node_id_lo_o),
        .completion_canonical_node_id_hi_o(
            completion_canonical_node_id_hi_o),
        .completion_npu_required_o(completion_npu_required_o),
        .completion_reduce_op_o(completion_reduce_op_o),
        .completion_epsilon_bits_o(completion_epsilon_bits_o),
        .completion_profile_id_o(completion_profile_id_o),
        .completion_kernel_id_o(completion_kernel_id_o),
        .completion_operator_census_o(completion_operator_census_o),
        .completion_profile_census_o(completion_profile_census_o),
        .done_o(done_o), .error_o(error_o), .error_code_o(error_code_o),
        .engine_error_code_o(engine_error_code_o),
        .rows_completed_o(rows_completed_o),
        .source_words_completed_o(source_words_completed_o),
        .engine_input_elements_o(engine_input_elements_o),
        .engine_output_elements_o(engine_output_elements_o),
        .elements_completed_o(elements_completed_o),
        .engine_launches_o(engine_launches_o),
        .engine_terminals_o(engine_terminals_o),
        .engine_aborts_o(engine_aborts_o),
        .engine_flags_or_o(engine_flags_or_o),
        .engine_active_cycles_o(engine_active_cycles_o),
        .gmem_read_beats_o(gmem_read_beats_o),
        .gmem_read_responses_o(gmem_read_responses_o),
        .read_payload_bytes_o(read_payload_bytes_o),
        .gmem_write_beats_o(gmem_write_beats_o),
        .gmem_write_responses_o(gmem_write_responses_o),
        .write_payload_bytes_o(write_payload_bytes_o),
        .active_cycles_o(active_cycles_o),
        .gmem_outstanding_o(gmem_outstanding_o),
        .engine_outstanding_o(engine_outstanding_o),
        .gmem_drain_o(gmem_drain_o)
    );

    initial clk_i = 1'b0;
    always #5 clk_i <= ~clk_i;

    reg [7:0] gmem [0:MEM_BYTES-1];
    reg allow_requests_q, request_backpressure_q, sparse_mode_q;
    integer response_delay_q, inject_error_request_ordinal_q;
    reg [31:0] sparse_source_word_q;
    reg pending_q, pending_write_q;
    reg [63:0] pending_addr_q, pending_wdata_q;
    reg [7:0] pending_wstrb_q;
    integer pending_delay_q, pending_ordinal_q;
    integer global_cycles, accepted_requests, accepted_reads, accepted_writes;
    integer successful_writes, held_stability_cycles;
    reg [63:0] first_read_addr_q, first_write_addr_q;
    reg [63:0] injected_request_addr_q;
    reg drain_seen_q;
    reg request_hold_q, held_request_write_q;
    reg [63:0] held_request_addr_q, held_request_wdata_q;
    reg [7:0] held_request_wstrb_q;

    integer completion_count, commit_count;
    reg last_done_q, last_error_q, last_commit_q;
    reg [4:0] last_error_code_q, last_engine_error_code_q;
    reg [63:0] last_command_q, last_node_lo_q, last_node_hi_q;
    reg last_required_q;
    reg [2:0] last_reduce_op_q;
    reg [31:0] last_epsilon_q;
    reg [7:0] last_profile_q;
    reg [31:0] last_kernel_q, last_operator_census_q;
    reg [31:0] last_profile_census_q;
    reg [63:0] last_rows_q, last_source_words_q;
    reg [63:0] last_engine_inputs_q, last_engine_outputs_q;
    reg [63:0] last_elements_q, last_launches_q, last_terminals_q;
    reg [63:0] last_aborts_q;
    reg [4:0] last_flags_q;
    reg [63:0] last_engine_cycles_q;
    reg [63:0] last_read_beats_q, last_read_responses_q, last_read_bytes_q;
    reg [63:0] last_write_beats_q, last_write_responses_q;
    reg [63:0] last_write_bytes_q, last_active_cycles_q;
    reg last_gmem_outstanding_q, last_engine_outstanding_q;

    integer bus_lane, memory_index;
    reg [63:0] response_data_calc;
    reg response_error_calc;

    assign gmem_req_ready_i = allow_requests_q && !pending_q
                            && !gmem_rsp_valid_i
                            && (!request_backpressure_q
                                || (global_cycles[2:0] != 3'd3));

    task automatic fail_case(input string reason);
        begin
            $display("[NPU-NORM-WRITEBACK][FAIL] %s cycle=%0d err=%0d engine_err=%0d req=%0d/%0d terminal=%0d commit=%0d drain=%0b",
                     reason, global_cycles, error_code_o,
                     engine_error_code_o, accepted_reads, accepted_writes,
                     completion_count, commit_count, drain_seen_q);
            $display("[NPU-NORM-WRITEBACK][EVIDENCE] rows=%0d src=%0d engine=%0d/%0d launch=%0d/%0d/abort%0d elem=%0d read=%0d/%0d/%0dB write=%0d/%0d/%0dB flags=%02x ecycles=%0d active=%0d",
                     rows_completed_o, source_words_completed_o,
                     engine_input_elements_o, engine_output_elements_o,
                     engine_launches_o, engine_terminals_o, engine_aborts_o,
                     elements_completed_o, gmem_read_beats_o,
                     gmem_read_responses_o, read_payload_bytes_o,
                     gmem_write_beats_o, gmem_write_responses_o,
                     write_payload_bytes_o, engine_flags_or_o,
                     engine_active_cycles_o, active_cycles_o);
            $fatal(1);
        end
    endtask

    function automatic logic [63:0] sparse_read_data;
        begin
            sparse_read_data = {sparse_source_word_q,
                                sparse_source_word_q};
        end
    endfunction

    /* verilator lint_off BLKSEQ */
    always @(posedge clk_i) begin
        if (rst_i) begin
            pending_q <= 1'b0; pending_write_q <= 1'b0;
            pending_addr_q <= 0; pending_wdata_q <= 0; pending_wstrb_q <= 0;
            pending_delay_q <= 0; pending_ordinal_q <= -1;
            gmem_rsp_valid_i <= 1'b0; gmem_rsp_rdata_i <= 0;
            gmem_rsp_error_i <= 1'b0;
            accepted_requests <= 0; accepted_reads <= 0;
            accepted_writes <= 0; successful_writes <= 0;
            first_read_addr_q <= 64'hffff_ffff_ffff_ffff;
            first_write_addr_q <= 64'hffff_ffff_ffff_ffff;
            injected_request_addr_q <= 64'hffff_ffff_ffff_ffff;
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
                            response_data_calc = sparse_read_data();
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
                                bus_lane = bus_lane + 1)
                            if (pending_wstrb_q[bus_lane])
                                gmem[memory_index + bus_lane]
                                    <= pending_wdata_q[
                                        {bus_lane[2:0], 3'b000} +: 8
                                    ];
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
                    fail_case("multiple GMEM requests outstanding");
                if (gmem_req_addr_o[2:0] != 3'b000)
                    fail_case("unaligned GMEM beat");
                if (gmem_req_write_o
                        && !((gmem_req_wstrb_o == 8'h0f)
                             || (gmem_req_wstrb_o == 8'hf0)))
                    fail_case("write did not select exactly one F32 lane");
                if (!gmem_req_write_o && (gmem_req_wstrb_o != 8'b0))
                    fail_case("read carried write strobes");
                pending_q <= 1'b1;
                pending_write_q <= gmem_req_write_o;
                pending_addr_q <= gmem_req_addr_o;
                pending_wdata_q <= gmem_req_wdata_o;
                pending_wstrb_q <= gmem_req_wstrb_o;
                pending_delay_q <= response_delay_q;
                pending_ordinal_q <= accepted_requests;
                if ((inject_error_request_ordinal_q >= 0)
                        && (accepted_requests
                            == inject_error_request_ordinal_q))
                    injected_request_addr_q <= gmem_req_addr_o;
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

    always @(posedge clk_i) begin
        if (rst_i) begin
            request_hold_q <= 1'b0; held_request_write_q <= 1'b0;
            held_request_addr_q <= 0; held_request_wdata_q <= 0;
            held_request_wstrb_q <= 0; held_stability_cycles <= 0;
        end else if (gmem_req_valid_o && !gmem_req_ready_i) begin
            if (request_hold_q) begin
                if ((gmem_req_write_o != held_request_write_q)
                        || (gmem_req_addr_o != held_request_addr_q)
                        || (gmem_req_wdata_o != held_request_wdata_q)
                        || (gmem_req_wstrb_o != held_request_wstrb_q))
                    fail_case("request payload changed under backpressure");
            end else begin
                request_hold_q <= 1'b1;
                held_request_write_q <= gmem_req_write_o;
                held_request_addr_q <= gmem_req_addr_o;
                held_request_wdata_q <= gmem_req_wdata_o;
                held_request_wstrb_q <= gmem_req_wstrb_o;
            end
            held_stability_cycles <= held_stability_cycles + 1;
        end else begin
            request_hold_q <= 1'b0;
        end
    end

    always @(posedge clk_i) begin
        if (rst_i) begin
            global_cycles <= 0;
            drain_seen_q <= 1'b0;
        end else begin
            global_cycles <= global_cycles + 1;
            if (gmem_drain_o)
                drain_seen_q <= 1'b1;
        end
    end

    always @(posedge clk_i) begin
        if (rst_i) begin
            completion_count <= 0; commit_count <= 0;
            last_done_q <= 0; last_error_q <= 0; last_commit_q <= 0;
            last_error_code_q <= 0; last_engine_error_code_q <= 0;
            last_command_q <= 0; last_node_lo_q <= 0; last_node_hi_q <= 0;
            last_required_q <= 0; last_reduce_op_q <= 0; last_epsilon_q <= 0;
            last_profile_q <= 0; last_kernel_q <= 0;
            last_operator_census_q <= 0; last_profile_census_q <= 0;
            last_rows_q <= 0; last_source_words_q <= 0;
            last_engine_inputs_q <= 0; last_engine_outputs_q <= 0;
            last_elements_q <= 0; last_launches_q <= 0;
            last_terminals_q <= 0; last_aborts_q <= 0; last_flags_q <= 0;
            last_engine_cycles_q <= 0; last_read_beats_q <= 0;
            last_read_responses_q <= 0; last_read_bytes_q <= 0;
            last_write_beats_q <= 0; last_write_responses_q <= 0;
            last_write_bytes_q <= 0; last_active_cycles_q <= 0;
            last_gmem_outstanding_q <= 0; last_engine_outstanding_q <= 0;
        end else if (completion_valid_o) begin
            completion_count <= completion_count + 1;
            if (dst_commit_o)
                commit_count <= commit_count + 1;
            last_done_q <= done_o; last_error_q <= error_o;
            last_commit_q <= dst_commit_o; last_error_code_q <= error_code_o;
            last_engine_error_code_q <= engine_error_code_o;
            last_command_q <= completion_command_id_o;
            last_node_lo_q <= completion_canonical_node_id_lo_o;
            last_node_hi_q <= completion_canonical_node_id_hi_o;
            last_required_q <= completion_npu_required_o;
            last_reduce_op_q <= completion_reduce_op_o;
            last_epsilon_q <= completion_epsilon_bits_o;
            last_profile_q <= completion_profile_id_o;
            last_kernel_q <= completion_kernel_id_o;
            last_operator_census_q <= completion_operator_census_o;
            last_profile_census_q <= completion_profile_census_o;
            last_rows_q <= rows_completed_o;
            last_source_words_q <= source_words_completed_o;
            last_engine_inputs_q <= engine_input_elements_o;
            last_engine_outputs_q <= engine_output_elements_o;
            last_elements_q <= elements_completed_o;
            last_launches_q <= engine_launches_o;
            last_terminals_q <= engine_terminals_o;
            last_aborts_q <= engine_aborts_o;
            last_flags_q <= engine_flags_or_o;
            last_engine_cycles_q <= engine_active_cycles_o;
            last_read_beats_q <= gmem_read_beats_o;
            last_read_responses_q <= gmem_read_responses_o;
            last_read_bytes_q <= read_payload_bytes_o;
            last_write_beats_q <= gmem_write_beats_o;
            last_write_responses_q <= gmem_write_responses_o;
            last_write_bytes_q <= write_payload_bytes_o;
            last_active_cycles_q <= active_cycles_o;
            last_gmem_outstanding_q <= gmem_outstanding_o;
            last_engine_outstanding_q <= engine_outstanding_o;
        end
    end

    task automatic put_u32(
        input logic [63:0] address,
        input logic [31:0] value
    );
        integer offset;
        begin
            if ((address < MEM_BASE) || ((address + 64'd4) > MEM_LIMIT))
                fail_case("put_u32 escaped local memory");
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

    function automatic integer profile_d(input logic [7:0] profile);
        begin
            case (profile)
                PROFILE_RMS_D1024_R1: profile_d = 1024;
                PROFILE_RMS_D128_R16,
                PROFILE_L2_D128_R16: profile_d = 128;
                PROFILE_RMS_D256_R2,
                PROFILE_RMS_D256_R8: profile_d = 256;
                default: profile_d = 0;
            endcase
        end
    endfunction

    function automatic integer profile_rows(input logic [7:0] profile);
        begin
            case (profile)
                PROFILE_RMS_D1024_R1: profile_rows = 1;
                PROFILE_RMS_D128_R16,
                PROFILE_L2_D128_R16: profile_rows = 16;
                PROFILE_RMS_D256_R2: profile_rows = 2;
                PROFILE_RMS_D256_R8: profile_rows = 8;
                default: profile_rows = 0;
            endcase
        end
    endfunction

    function automatic logic [31:0] profile_census(
        input logic [7:0] profile
    );
        begin
            case (profile)
                PROFILE_RMS_D1024_R1: profile_census = 32'd49;
                PROFILE_RMS_D128_R16: profile_census = 32'd18;
                PROFILE_RMS_D256_R2,
                PROFILE_RMS_D256_R8: profile_census = 32'd6;
                PROFILE_L2_D128_R16: profile_census = 32'd36;
                default: profile_census = 32'b0;
            endcase
        end
    endfunction

    task automatic reset_case;
        begin
            start_i = 1'b0; rst_i = 1'b1;
            allow_requests_q = 1'b1; request_backpressure_q = 1'b0;
            response_delay_q = 0; inject_error_request_ordinal_q = -1;
            sparse_mode_q = 1'b0; sparse_source_word_q = 32'h3f800000;
            repeat (3) @(posedge clk_i);
            @(negedge clk_i); rst_i = 1'b0;
            @(posedge clk_i); #1;
            if (!ready_o || busy_o || completion_valid_o
                    || gmem_outstanding_o || engine_outstanding_o)
                fail_case("reset did not restore idle ownership");
        end
    endtask

    task automatic set_profile(input logic [7:0] profile);
        begin
            reduce_op_i = REDUCE_RMS;
            epsilon_bits_i = EPSILON_QWEN;
            op_params_tail_zero_i = 1'b1;
            npu_required_i = 1'b1;
            command_id_i = 64'h1000_2000_3000_0000 | {56'b0, profile};
            canonical_node_id_lo_i =
                64'h4444_5555_6666_0000 | {56'b0, profile};
            canonical_node_id_hi_i =
                64'haaaa_7777_8888_0000 | {56'b0, profile};
            dst_shadow_private_i = 1'b1;
            windows_generation_valid_i = 1'b1;
            ne0_i = 32'd1024; ne1_i = 32'd1;
            ne2_i = 32'd1; ne3_i = 32'd1;
            src0_nb0_i = 64'd4; src0_nb1_i = 64'd4096;
            src0_nb2_i = 64'd4096; src0_nb3_i = 64'd4096;
            dst_nb0_i = 64'd4; dst_nb1_i = 64'd4096;
            dst_nb2_i = 64'd4096; dst_nb3_i = 64'd4096;
            case (profile)
                PROFILE_RMS_D1024_R1: begin end
                PROFILE_RMS_D128_R16: begin
                    ne0_i = 32'd128; ne1_i = 32'd16;
                    src0_nb1_i = 64'd512; src0_nb2_i = 64'd4;
                    src0_nb3_i = 64'd8192;
                    dst_nb1_i = 64'd512; dst_nb2_i = 64'd8192;
                    dst_nb3_i = 64'd8192;
                end
                PROFILE_RMS_D256_R2: begin
                    ne0_i = 32'd256; ne1_i = 32'd2;
                    src0_nb1_i = 64'd1024; src0_nb2_i = 64'd2048;
                    src0_nb3_i = 64'd2048;
                    dst_nb1_i = 64'd1024; dst_nb2_i = 64'd2048;
                    dst_nb3_i = 64'd2048;
                end
                PROFILE_RMS_D256_R8: begin
                    ne0_i = 32'd256; ne1_i = 32'd8;
                    src0_nb1_i = 64'd2048; src0_nb2_i = 64'd16384;
                    src0_nb3_i = 64'd16384;
                    dst_nb1_i = 64'd1024; dst_nb2_i = 64'd8192;
                    dst_nb3_i = 64'd8192;
                end
                PROFILE_L2_D128_R16: begin
                    reduce_op_i = REDUCE_L2;
                    ne0_i = 32'd128; ne1_i = 32'd16;
                    src0_nb1_i = 64'd512; src0_nb2_i = 64'd24576;
                    src0_nb3_i = 64'd24576;
                    dst_nb1_i = 64'd512; dst_nb2_i = 64'd8192;
                    dst_nb3_i = 64'd8192;
                end
                default: begin end
            endcase
            src1_base_i = 64'b0; src1_nb0_i = 64'b0;
            src1_nb1_i = 64'b0; src1_nb2_i = 64'b0; src1_nb3_i = 64'b0;
            src0_base_i = 64'h0000_0000_0000_2004;
            src0_window_base_i = 64'h0000_0000_0000_2000;
            src0_window_bytes_i = 64'h0000_0000_0001_0000;
            src0_window_read_i = 1'b1; src0_window_write_i = 1'b0;
            src1_window_base_i = 64'b0; src1_window_bytes_i = 64'b0;
            src1_window_read_i = 1'b1; src1_window_write_i = 1'b0;
            dst_base_i = 64'h0000_0000_0001_8004;
            dst_window_base_i = 64'h0000_0000_0001_8000;
            dst_window_bytes_i = 64'h0000_0000_0001_0000;
            dst_window_read_i = 1'b0; dst_window_write_i = 1'b1;
        end
    endtask

    task automatic load_profile(input logic [7:0] profile);
        integer row, lane;
        logic [31:0] source_word;
        begin
            for (row = 0; row < profile_rows(profile); row = row + 1)
                for (lane = 0; lane < profile_d(profile); lane = lane + 1) begin
                    if (profile == PROFILE_L2_D128_R16) begin
                        source_word = (lane == 0) ? 32'h3f800000
                                    : lane[0] ? 32'h80000000
                                              : 32'h00000000;
                    end else begin
                        source_word = lane[0] ? 32'hbf800000
                                              : 32'h3f800000;
                    end
                    put_u32(src0_base_i + (row * src0_nb1_i)
                            + (lane * 4), source_word);
                    put_u32(dst_base_i + (row * dst_nb1_i)
                            + (lane * 4), 32'hcccccccc);
                end
        end
    endtask

    function automatic logic [31:0] expected_word(
        input logic [7:0] profile,
        input integer lane
    );
        begin
            if (profile == PROFILE_L2_D128_R16) begin
                expected_word = (lane == 0) ? 32'h3f800000
                              : lane[0] ? 32'h80000000
                                        : 32'h00000000;
            end else begin
                expected_word = lane[0] ? 32'hbf7ffff8
                                        : 32'h3f7ffff8;
            end
        end
    endfunction

    task automatic pulse_start;
        begin
            while (!ready_o)
                @(posedge clk_i);
            @(negedge clk_i); start_i = 1'b1;
            @(negedge clk_i); start_i = 1'b0;
        end
    endtask

    task automatic wait_completion(
        input bit expect_error,
        input logic [4:0] expected_code,
        input integer max_cycles
    );
        integer before_count, waited;
        begin
            before_count = completion_count;
            waited = 0;
            while ((completion_count == before_count)
                    && (waited < max_cycles)) begin
                @(posedge clk_i); #1;
                waited = waited + 1;
            end
            if (completion_count != (before_count + 1))
                fail_case("terminal completion timeout or duplicate");
            if (expect_error) begin
                if (!last_error_q || last_done_q || last_commit_q
                        || (last_error_code_q != expected_code))
                    fail_case("unexpected error terminal");
            end else begin
                if (!last_done_q || last_error_q || !last_commit_q
                        || (last_error_code_q != 5'b0))
                    fail_case("unexpected success terminal");
            end
            if (last_gmem_outstanding_q || last_engine_outstanding_q)
                fail_case("terminal retained GMEM/Engine ownership");
        end
    endtask

    task automatic check_identity(
        input logic [63:0] command,
        input logic [63:0] node_lo,
        input logic [63:0] node_hi,
        input logic [7:0] profile
    );
        logic [2:0] expected_reduce;
        logic [31:0] expected_operator_count;
        begin
            expected_reduce = (profile == PROFILE_L2_D128_R16)
                            ? REDUCE_L2 : REDUCE_RMS;
            expected_operator_count = (expected_reduce == REDUCE_L2)
                                    ? 32'd36 : 32'd79;
            if ((last_command_q != command) || (last_node_lo_q != node_lo)
                    || (last_node_hi_q != node_hi) || !last_required_q
                    || (last_reduce_op_q != expected_reduce)
                    || (last_epsilon_q != EPSILON_QWEN)
                    || (last_profile_q != profile)
                    || (last_kernel_q != KERNEL_REDUCE)
                    || (last_operator_census_q != expected_operator_count)
                    || (last_profile_census_q != profile_census(profile)))
                fail_case("completion identity/profile/census mismatch");
        end
    endtask

    task automatic run_success(
        input string label,
        input logic [7:0] profile,
        input logic [4:0] expected_flags,
        input bit exercise_backpressure,
        input bit exercise_busy
    );
        integer row, lane, total;
        logic [63:0] command, node_lo, node_hi;
        begin
            reset_case(); set_profile(profile); load_profile(profile);
            if (exercise_backpressure) begin
                request_backpressure_q = 1'b1;
                response_delay_q = 1;
            end
            command = command_id_i; node_lo = canonical_node_id_lo_i;
            node_hi = canonical_node_id_hi_i;
            pulse_start();
            if (exercise_busy) begin
                @(negedge clk_i);
                start_i = 1'b1; command_id_i = 64'hdeadbeefdeadbeef;
                canonical_node_id_lo_i = 0; canonical_node_id_hi_i = 0;
                reduce_op_i = 3'd7; epsilon_bits_i = 32'h7fc12345;
                repeat (3) begin
                    @(posedge clk_i); #1;
                    if (ready_o)
                        fail_case("busy command incorrectly accepted new credit");
                end
                @(negedge clk_i); start_i = 1'b0;
                set_profile(profile);
            end
            wait_completion(1'b0, 5'b0, 1500000);
            check_identity(command, node_lo, node_hi, profile);
            total = profile_d(profile) * profile_rows(profile);
            if ((last_rows_q != profile_rows(profile))
                    || (last_source_words_q != total)
                    || (last_engine_inputs_q != total)
                    || (last_engine_outputs_q != total)
                    || (last_elements_q != total)
                    || (last_launches_q != profile_rows(profile))
                    || (last_terminals_q != profile_rows(profile))
                    || (last_aborts_q != 0) || (last_flags_q != expected_flags)
                    || (last_engine_cycles_q == 0)
                    || (last_read_beats_q != total)
                    || (last_read_responses_q != total)
                    || (last_read_bytes_q != (total * 4))
                    || (last_write_beats_q != total)
                    || (last_write_responses_q != total)
                    || (last_write_bytes_q != (total * 4))
                    || (accepted_reads != total) || (accepted_writes != total)
                    || (successful_writes != total)
                    || (last_engine_error_code_q != 0)
                    || (last_active_cycles_q <= last_engine_cycles_q))
                fail_case("successful transaction counter oracle mismatch");
            for (row = 0; row < profile_rows(profile); row = row + 1)
                for (lane = 0; lane < profile_d(profile); lane = lane + 1)
                    if (get_u32(dst_base_i + (row * dst_nb1_i)
                                + (lane * 4))
                            !== expected_word(profile, lane))
                        fail_case({label, ": raw-bit destination mismatch"});
            if (exercise_backpressure && (held_stability_cycles == 0))
                fail_case("positive transaction missed request backpressure");
            $display("[NPU-NORM-WRITEBACK][INFO] %s profile=%0d D=%0d rows=%0d raw-bit=exact read/write=%0d engine=%0d/%0d cycles=%0d",
                     label, profile, profile_d(profile), profile_rows(profile),
                     total, last_launches_q, last_terminals_q,
                     last_engine_cycles_q);
        end
    endtask

    task automatic set_sparse_high_windows(input logic [7:0] profile);
        logic [63:0] source_bytes, destination_bytes;
        begin
            source_bytes = ((64'(profile_rows(profile) - 1)) * src0_nb1_i)
                         + (64'(profile_d(profile)) * 64'd4) + 64'd8;
            destination_bytes =
                ((64'(profile_rows(profile) - 1)) * dst_nb1_i)
              + (64'(profile_d(profile)) * 64'd4) + 64'd8;
            src0_base_i = 64'h0000_0001_0000_2004;
            src0_window_base_i = 64'h0000_0001_0000_2000;
            src0_window_bytes_i = source_bytes;
            dst_base_i = 64'h0000_0002_0000_2004;
            dst_window_base_i = 64'h0000_0002_0000_2000;
            dst_window_bytes_i = destination_bytes;
        end
    endtask

    task automatic test_d256_early_admission;
        logic [63:0] command, node_lo, node_hi;
        begin
            reset_case(); set_profile(PROFILE_RMS_D256_R2);
            set_sparse_high_windows(PROFILE_RMS_D256_R2);
            sparse_mode_q = 1'b1; inject_error_request_ordinal_q = 0;
            command = command_id_i; node_lo = canonical_node_id_lo_i;
            node_hi = canonical_node_id_hi_i;
            pulse_start(); wait_completion(1'b1, ERR_GMEM, 10000);
            check_identity(command, node_lo, node_hi, PROFILE_RMS_D256_R2);
            if ((accepted_reads != 1) || (accepted_writes != 0)
                    || (first_read_addr_q != {src0_base_i[63:3], 3'b000})
                    || (last_launches_q != 1) || (last_terminals_q != 0)
                    || (last_aborts_q != 1) || (last_source_words_q != 0)
                    || (last_read_beats_q != 1)
                    || (last_read_responses_q != 1)
                    || (last_read_bytes_q != 0))
                fail_case("D256x2 sparse admission mismatch");
            $display("[NPU-NORM-WRITEBACK][INFO] RMS-D256xrows2 high-address=%016x preflight=accepted early-read-error commit=0",
                     first_read_addr_q);
        end
    endtask

    task automatic test_d256_padding_stride;
        logic [63:0] command, node_lo, node_hi;
        logic [63:0] expected_padded_addr;
        begin
            reset_case(); set_profile(PROFILE_RMS_D256_R8);
            set_sparse_high_windows(PROFILE_RMS_D256_R8);
            sparse_mode_q = 1'b1; sparse_source_word_q = 32'h3f800000;
            // First row has 256 reads followed by 256 writes.  The next
            // accepted request is row1/lane0 and must use the 2048-byte source
            // stride rather than the packed 1024-byte destination stride.
            inject_error_request_ordinal_q = 512;
            command = command_id_i; node_lo = canonical_node_id_lo_i;
            node_hi = canonical_node_id_hi_i;
            pulse_start(); wait_completion(1'b1, ERR_GMEM, 300000);
            check_identity(command, node_lo, node_hi, PROFILE_RMS_D256_R8);
            expected_padded_addr = src0_base_i + 64'd2048;
            expected_padded_addr[2:0] = 3'b000;
            if ((injected_request_addr_q != expected_padded_addr)
                    || (last_rows_q != 1) || (last_source_words_q != 256)
                    || (last_engine_inputs_q != 256)
                    || (last_engine_outputs_q != 256)
                    || (last_elements_q != 256)
                    || (last_launches_q != 2) || (last_terminals_q != 1)
                    || (last_aborts_q != 1) || (accepted_reads != 257)
                    || (accepted_writes != 256)
                    || (last_read_beats_q != 257)
                    || (last_read_responses_q != 257)
                    || (last_read_bytes_q != 1024)
                    || (last_write_bytes_q != 1024))
                fail_case("D256x8 source padding runtime proof mismatch");
            $display("[NPU-NORM-WRITEBACK][INFO] RMS-D256xrows8 src-row-stride=2048 dst-row-stride=1024 observed-next-row=%016x commit=0",
                     injected_request_addr_q);
        end
    endtask

    task automatic run_zero_traffic_error(
        input string label,
        input logic [4:0] expected_error,
        input logic [7:0] expected_profile
    );
        begin
            pulse_start(); wait_completion(1'b1, expected_error, 1000);
            if ((accepted_requests != 0) || (last_read_beats_q != 0)
                    || (last_write_beats_q != 0) || (last_launches_q != 0)
                    || (last_terminals_q != 0) || (last_aborts_q != 0)
                    || (last_elements_q != 0)
                    || (last_profile_q != expected_profile))
                fail_case({label, ": static reject generated traffic"});
            $display("[NPU-NORM-WRITEBACK][INFO] %s error=%0d traffic=0 commit=0",
                     label, expected_error);
        end
    endtask

    task automatic test_static_rejects;
        begin
            reset_case(); set_profile(PROFILE_RMS_D128_R16);
            reduce_op_i = 3'd7;
            run_zero_traffic_error("unknown-reduce-op", ERR_PROFILE,
                                   PROFILE_INVALID);
            reset_case(); set_profile(PROFILE_RMS_D128_R16);
            epsilon_bits_i = 32'h00000000;
            run_zero_traffic_error("epsilon-mismatch", ERR_PROFILE,
                                   PROFILE_RMS_D128_R16);
            reset_case(); set_profile(PROFILE_RMS_D128_R16);
            op_params_tail_zero_i = 1'b0;
            run_zero_traffic_error("op-params-tail", ERR_PROFILE,
                                   PROFILE_RMS_D128_R16);
            reset_case(); set_profile(PROFILE_RMS_D256_R8);
            src0_nb1_i = 64'd1024;
            run_zero_traffic_error("source-padding-stride", ERR_PROFILE,
                                   PROFILE_INVALID);
            reset_case(); set_profile(PROFILE_RMS_D128_R16);
            src0_window_read_i = 1'b0;
            run_zero_traffic_error("source0-permission", ERR_SRC0,
                                   PROFILE_RMS_D128_R16);
            reset_case(); set_profile(PROFILE_RMS_D128_R16);
            src1_window_bytes_i = 64'd8;
            run_zero_traffic_error("source1-sentinel", ERR_SRC1,
                                   PROFILE_RMS_D128_R16);
            reset_case(); set_profile(PROFILE_RMS_D128_R16);
            dst_window_read_i = 1'b1;
            run_zero_traffic_error("destination-permission", ERR_DST,
                                   PROFILE_RMS_D128_R16);
            reset_case(); set_profile(PROFILE_RMS_D128_R16);
            dst_base_i = src0_base_i; dst_window_base_i = src0_window_base_i;
            dst_window_bytes_i = src0_window_bytes_i;
            run_zero_traffic_error("physical-alias", ERR_ALIAS,
                                   PROFILE_RMS_D128_R16);
            reset_case(); set_profile(PROFILE_RMS_D128_R16);
            src0_base_i = 64'hffff_ffff_ffff_fffc;
            src0_window_base_i = 64'hffff_ffff_ffff_fff8;
            src0_window_bytes_i = 64'd8;
            run_zero_traffic_error("source0-128b-overflow", ERR_SRC0,
                                   PROFILE_RMS_D128_R16);
        end
    endtask

    task automatic test_late_read_error;
        begin
            reset_case(); set_profile(PROFILE_RMS_D128_R16);
            load_profile(PROFILE_RMS_D128_R16);
            inject_error_request_ordinal_q = 4;
            pulse_start(); wait_completion(1'b1, ERR_GMEM, 10000);
            if ((accepted_reads != 5) || (accepted_writes != 0)
                    || (last_source_words_q != 4)
                    || (last_engine_inputs_q != 4)
                    || (last_launches_q != 1) || (last_terminals_q != 0)
                    || (last_aborts_q != 1) || (last_read_beats_q != 5)
                    || (last_read_responses_q != 5)
                    || (last_read_bytes_q != 16))
                fail_case("late read error counter mismatch");
            $display("[NPU-NORM-WRITEBACK][INFO] late-read-error accepted-input=4 engine-abort=1 commit=0");
        end
    endtask

    task automatic test_late_write_error;
        begin
            reset_case(); set_profile(PROFILE_RMS_D128_R16);
            load_profile(PROFILE_RMS_D128_R16);
            inject_error_request_ordinal_q = 131;
            pulse_start(); wait_completion(1'b1, ERR_GMEM, 100000);
            if ((accepted_reads != 128) || (accepted_writes != 4)
                    || (last_source_words_q != 128)
                    || (last_engine_inputs_q != 128)
                    || (last_engine_outputs_q != 3)
                    || (last_elements_q != 3)
                    || (last_launches_q != 1) || (last_terminals_q != 0)
                    || (last_aborts_q != 1)
                    || (last_write_beats_q != 4)
                    || (last_write_responses_q != 4)
                    || (last_write_bytes_q != 12))
                fail_case("late write error counter mismatch");
            $display("[NPU-NORM-WRITEBACK][INFO] late-write-error private-prefix=3 engine-abort=1 commit=0");
        end
    endtask

    task automatic test_engine_numeric_error;
        begin
            reset_case(); set_profile(PROFILE_RMS_D128_R16);
            load_profile(PROFILE_RMS_D128_R16);
            put_u32(src0_base_i, 32'h7fc12345);
            pulse_start(); wait_completion(1'b1, ERR_ENGINE, 10000);
            if ((last_engine_error_code_q == 0) || (last_terminals_q != 1)
                    || (last_launches_q != 1) || (last_aborts_q != 0)
                    || (last_elements_q != 0))
                fail_case("Engine numeric failure mapping mismatch");
            $display("[NPU-NORM-WRITEBACK][INFO] engine-numeric-error code=%0d commit=0 terminal-outstanding=0",
                     last_engine_error_code_q);
        end
    endtask

    task automatic test_response_timeout_drain;
        begin
            reset_case(); set_profile(PROFILE_RMS_D128_R16);
            load_profile(PROFILE_RMS_D128_R16);
            response_delay_q = 20;
            pulse_start(); wait_completion(1'b1, ERR_STALL, 1000);
            if (!drain_seen_q || (accepted_reads != 1)
                    || (last_read_beats_q != 1)
                    || (last_read_responses_q != 1)
                    || (last_read_bytes_q != 0)
                    || (last_launches_q != 1) || (last_terminals_q != 0)
                    || (last_aborts_q != 1))
                fail_case("accepted response timeout drain mismatch");
            $display("[NPU-NORM-WRITEBACK][INFO] response-timeout accepted=1 drained=1 engine-abort=1 commit=0");
        end
    endtask

    task automatic test_request_timeout;
        begin
            reset_case(); set_profile(PROFILE_RMS_D128_R16);
            allow_requests_q = 1'b0;
            pulse_start(); wait_completion(1'b1, ERR_STALL, 1000);
            if ((accepted_requests != 0) || (held_stability_cycles < 8)
                    || drain_seen_q || (last_launches_q != 1)
                    || (last_terminals_q != 0) || (last_aborts_q != 1))
                fail_case("request timeout/backpressure mismatch");
            $display("[NPU-NORM-WRITEBACK][INFO] request-timeout accepted=0 stable=%0d engine-abort=1 commit=0",
                     held_stability_cycles);
        end
    endtask

    task automatic test_resident_reset;
        begin
            reset_case(); set_profile(PROFILE_RMS_D128_R16);
            load_profile(PROFILE_RMS_D128_R16);
            response_delay_q = 20;
            pulse_start();
            while (accepted_requests == 0)
                @(posedge clk_i);
            @(negedge clk_i); rst_i = 1'b1;
            repeat (2) @(posedge clk_i);
            @(negedge clk_i); rst_i = 1'b0;
            @(posedge clk_i); #1;
            if (!ready_o || busy_o || completion_valid_o
                    || gmem_outstanding_o || engine_outstanding_o
                    || gmem_rsp_valid_i)
                fail_case("resident reset left stale credit/terminal");
            $display("[NPU-NORM-WRITEBACK][INFO] resident-reset canceled-GMEM+Engine no-stale-terminal");
        end
    endtask

    initial begin
        rst_i = 1'b1; start_i = 1'b0; reduce_op_i = 0;
        epsilon_bits_i = 0; op_params_tail_zero_i = 0;
        npu_required_i = 0; command_id_i = 0;
        canonical_node_id_lo_i = 0; canonical_node_id_hi_i = 0;
        dst_shadow_private_i = 0; windows_generation_valid_i = 0;
        ne0_i = 0; ne1_i = 0; ne2_i = 0; ne3_i = 0;
        src0_base_i = 0; src0_nb0_i = 0; src0_nb1_i = 0;
        src0_nb2_i = 0; src0_nb3_i = 0;
        src1_base_i = 0; src1_nb0_i = 0; src1_nb1_i = 0;
        src1_nb2_i = 0; src1_nb3_i = 0;
        dst_base_i = 0; dst_nb0_i = 0; dst_nb1_i = 0;
        dst_nb2_i = 0; dst_nb3_i = 0;
        src0_window_base_i = 0; src0_window_bytes_i = 0;
        src0_window_read_i = 0; src0_window_write_i = 0;
        src1_window_base_i = 0; src1_window_bytes_i = 0;
        src1_window_read_i = 0; src1_window_write_i = 0;
        dst_window_base_i = 0; dst_window_bytes_i = 0;
        dst_window_read_i = 0; dst_window_write_i = 0;
        allow_requests_q = 1'b1; request_backpressure_q = 1'b0;
        response_delay_q = 0; inject_error_request_ordinal_q = -1;
        sparse_mode_q = 1'b0; sparse_source_word_q = 32'h3f800000;
        repeat (4) @(posedge clk_i);

        run_success("RMS/D128/rows16/eps1e-6",
                    PROFILE_RMS_D128_R16, FLAGS_NX, 1'b1, 1'b1);
        run_success("L2/D128/rows16/signed-zero/eps1e-6",
                    PROFILE_L2_D128_R16, FLAGS_NONE, 1'b0, 1'b0);
        run_success("RMS/D1024/rows1/eps1e-6",
                    PROFILE_RMS_D1024_R1, FLAGS_NX, 1'b0, 1'b0);

        test_d256_early_admission();
        test_d256_padding_stride();
        test_static_rejects();
        test_late_read_error();
        test_late_write_error();
        test_engine_numeric_error();
        test_response_timeout_drain();
        test_request_timeout();
        test_resident_reset();

        $display("[NPU-NORM-WRITEBACK][PASS] manifest=RMS79+L2_36 profiles=5 kernel=514e0011 reduce-op=4/5 epsilon=358637bd raw-bit=exact preflight=128b R-R-W=proved padding=2048to1024 single-outstanding=1 transactional-commit=1 assertions=off waveform=off");
        $finish;
    end

endmodule

`default_nettype wire
