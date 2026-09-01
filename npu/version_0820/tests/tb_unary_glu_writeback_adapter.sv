`timescale 1ns/1ps
`default_nettype none

// Standalone raw-GMEM verification for the frozen Qwen v5 UNARY/GLU
// writeback profiles.  Numeric expected values are literal raw-bit oracles
// already frozen by tb_unary_glu_element.sv; this testbench performs no
// host floating-point or foreign arithmetic and never observes hierarchy state.
module tb_unary_glu_writeback_adapter;

    localparam integer MEM_BYTES = 131072;
    localparam logic [63:0] MEM_BASE  = 64'h0000_0000_0000_1000;
    localparam logic [63:0] MEM_LIMIT = MEM_BASE + 64'(MEM_BYTES);

    localparam logic [7:0] PROFILE_SIGMOID_16   = 8'd0;
    localparam logic [7:0] PROFILE_SIGMOID_2048 = 8'd1;
    localparam logic [7:0] PROFILE_SOFTPLUS_16  = 8'd2;
    localparam logic [7:0] PROFILE_SILU_2048    = 8'd3;
    localparam logic [7:0] PROFILE_SILU_6144    = 8'd4;
    localparam logic [7:0] PROFILE_EXP_16       = 8'd5;
    localparam logic [7:0] PROFILE_SWIGLU_3584  = 8'd6;
    localparam logic [7:0] PROFILE_INVALID      = 8'hff;

    localparam logic [31:0] KERNEL_UNARY = 32'h514e0005;
    localparam logic [31:0] KERNEL_GLU   = 32'h514e0006;

    localparam logic [4:0] ERR_PROFILE = 5'd1;
    localparam logic [4:0] ERR_SRC0    = 5'd2;
    localparam logic [4:0] ERR_SRC1    = 5'd3;
    localparam logic [4:0] ERR_DST     = 5'd4;
    localparam logic [4:0] ERR_ALIAS   = 5'd5;
    localparam logic [4:0] ERR_GMEM    = 5'd7;
    localparam logic [4:0] ERR_STALL   = 5'd8;

    localparam logic [4:0] FLAGS_NX = 5'b00001;
    localparam logic [4:0] MASK_SIGMOID = 5'b00111;
    localparam logic [4:0] MASK_SOFTPLUS = 5'b01011;
    localparam logic [4:0] MASK_SILU = 5'b00111;
    localparam logic [4:0] MASK_EXP = 5'b00001;
    localparam logic [4:0] MASK_SWIGLU = 5'b10111;

    localparam logic [31:0] CYCLES_SIGMOID = 32'd63;
    localparam logic [31:0] CYCLES_SOFTPLUS = 32'd58;
    localparam logic [31:0] CYCLES_SILU = 32'd63;
    localparam logic [31:0] CYCLES_EXP = 32'd29;
    localparam logic [31:0] CYCLES_SWIGLU = 32'd67;

    reg clk_i;
    reg rst_i;
    reg start_i;
    wire ready_o;
    wire busy_o;
    reg operation_glu_i;
    reg [7:0] subtype_i;
    reg op_params_tail_zero_i;
    reg npu_required_i;
    reg [63:0] command_id_i;
    reg [63:0] canonical_node_id_lo_i;
    reg [63:0] canonical_node_id_hi_i;
    reg dst_shadow_private_i;
    reg windows_generation_valid_i;
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
    wire completion_operation_glu_o;
    wire [7:0] completion_subtype_o;
    wire [7:0] completion_profile_id_o;
    wire [31:0] completion_kernel_id_o;
    wire [31:0] completion_operator_census_o;
    wire [31:0] completion_subtype_census_o;
    wire [31:0] completion_profile_census_o;
    wire done_o;
    wire error_o;
    wire [4:0] error_code_o;
    wire [3:0] element_error_code_o;
    wire [63:0] src0_words_completed_o;
    wire [63:0] src1_words_completed_o;
    wire [63:0] scalar_launches_o;
    wire [63:0] scalar_terminals_o;
    wire [63:0] elements_completed_o;
    wire [4:0] element_flags_or_o;
    wire [4:0] element_child_call_mask_or_o;
    wire [63:0] element_active_cycles_o;
    wire [63:0] gmem_read_beats_o;
    wire [63:0] gmem_read_responses_o;
    wire [63:0] read_payload_bytes_o;
    wire [63:0] gmem_write_beats_o;
    wire [63:0] gmem_write_responses_o;
    wire [63:0] write_payload_bytes_o;
    wire [63:0] active_cycles_o;
    wire gmem_outstanding_o;
    wire element_outstanding_o;
    wire gmem_drain_o;

    TensorNpuUnaryGluWritebackAdapter #(
        .STALL_TIMEOUT_CYCLES(32'd12),
        .COMMAND_TIMEOUT_CYCLES(64'd2000000)
    ) dut (
        .clk_i(clk_i), .rst_i(rst_i), .start_i(start_i),
        .ready_o(ready_o), .busy_o(busy_o),
        .operation_glu_i(operation_glu_i), .subtype_i(subtype_i),
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
        .completion_operation_glu_o(completion_operation_glu_o),
        .completion_subtype_o(completion_subtype_o),
        .completion_profile_id_o(completion_profile_id_o),
        .completion_kernel_id_o(completion_kernel_id_o),
        .completion_operator_census_o(completion_operator_census_o),
        .completion_subtype_census_o(completion_subtype_census_o),
        .completion_profile_census_o(completion_profile_census_o),
        .done_o(done_o), .error_o(error_o), .error_code_o(error_code_o),
        .element_error_code_o(element_error_code_o),
        .src0_words_completed_o(src0_words_completed_o),
        .src1_words_completed_o(src1_words_completed_o),
        .scalar_launches_o(scalar_launches_o),
        .scalar_terminals_o(scalar_terminals_o),
        .elements_completed_o(elements_completed_o),
        .element_flags_or_o(element_flags_or_o),
        .element_child_call_mask_or_o(element_child_call_mask_or_o),
        .element_active_cycles_o(element_active_cycles_o),
        .gmem_read_beats_o(gmem_read_beats_o),
        .gmem_read_responses_o(gmem_read_responses_o),
        .read_payload_bytes_o(read_payload_bytes_o),
        .gmem_write_beats_o(gmem_write_beats_o),
        .gmem_write_responses_o(gmem_write_responses_o),
        .write_payload_bytes_o(write_payload_bytes_o),
        .active_cycles_o(active_cycles_o),
        .gmem_outstanding_o(gmem_outstanding_o),
        .element_outstanding_o(element_outstanding_o),
        .gmem_drain_o(gmem_drain_o)
    );

    initial clk_i = 1'b0;
    always #5 clk_i <= ~clk_i;

    reg [7:0] gmem [0:MEM_BYTES-1];
    reg allow_requests_q;
    reg request_backpressure_q;
    integer response_delay_q;
    integer inject_error_request_ordinal_q;
    reg sparse_mode_q;
    reg [31:0] sparse_src0_word_q, sparse_src1_word_q;

    reg pending_q, pending_write_q;
    reg [63:0] pending_addr_q, pending_wdata_q;
    reg [7:0] pending_wstrb_q;
    integer pending_delay_q, pending_ordinal_q;
    integer global_cycles;
    integer accepted_requests, accepted_reads, accepted_writes;
    integer successful_writes, held_stability_cycles;
    reg [63:0] first_read_addr_q, first_write_addr_q;
    reg drain_seen_q;

    reg request_hold_q, held_request_write_q;
    reg [63:0] held_request_addr_q, held_request_wdata_q;
    reg [7:0] held_request_wstrb_q;

    integer completion_count, commit_count;
    reg last_done_q, last_error_q, last_commit_q;
    reg [4:0] last_error_code_q;
    reg [3:0] last_element_error_code_q;
    reg [63:0] last_command_q, last_node_lo_q, last_node_hi_q;
    reg last_required_q, last_glu_q;
    reg [7:0] last_subtype_q, last_profile_q;
    reg [31:0] last_kernel_q;
    reg [31:0] last_operator_census_q, last_subtype_census_q;
    reg [31:0] last_profile_census_q;
    reg [63:0] last_src0_words_q, last_src1_words_q;
    reg [63:0] last_launches_q, last_terminals_q, last_elements_q;
    reg [4:0] last_flags_q, last_child_mask_q;
    reg [63:0] last_element_cycles_q;
    reg [63:0] last_read_beats_q, last_read_responses_q, last_read_bytes_q;
    reg [63:0] last_write_beats_q, last_write_responses_q;
    reg [63:0] last_write_bytes_q, last_active_cycles_q;
    reg last_gmem_outstanding_q, last_element_outstanding_q;

    integer bus_lane, memory_index;
    reg [63:0] response_data_calc;
    reg response_error_calc;

    assign gmem_req_ready_i = allow_requests_q && !pending_q
                            && !gmem_rsp_valid_i
                            && (!request_backpressure_q
                                || (global_cycles[2:0] != 3'd2));

    task automatic fail_case(input string reason);
        begin
            $display("[NPU-UNARY-GLU-WRITEBACK][FAIL] %s cycle=%0d err=%0d req=%0d/%0d completion=%0d commit=%0d drain=%0b",
                     reason, global_cycles, error_code_o, accepted_reads,
                     accepted_writes, completion_count, commit_count,
                     drain_seen_q);
            $display("[NPU-UNARY-GLU-WRITEBACK][EVIDENCE] src=%0d/%0d scalar=%0d/%0d elem=%0d read=%0d/%0d/%0dB write=%0d/%0d/%0dB flags=%02x mask=%02x ecycles=%0d active=%0d",
                     src0_words_completed_o, src1_words_completed_o,
                     scalar_launches_o, scalar_terminals_o,
                     elements_completed_o, gmem_read_beats_o,
                     gmem_read_responses_o, read_payload_bytes_o,
                     gmem_write_beats_o, gmem_write_responses_o,
                     write_payload_bytes_o, element_flags_or_o,
                     element_child_call_mask_or_o, element_active_cycles_o,
                     active_cycles_o);
            $fatal(1);
        end
    endtask

    function automatic logic [63:0] sparse_read_data(
        input logic [63:0] beat_addr
    );
        begin
            if ((beat_addr >= {src1_base_i[63:3], 3'b000})
                    && (src1_window_bytes_i != 64'b0))
                sparse_read_data = {sparse_src1_word_q, sparse_src1_word_q};
            else
                sparse_read_data = {sparse_src0_word_q, sparse_src0_word_q};
        end
    endfunction

    // One accepted request and one accepted response at most.  The model only
    // transports bytes; it contains no unary/GLU calculation.
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
                    fail_case("more than one GMEM request outstanding");
                if (gmem_req_addr_o[2:0] != 3'b000)
                    fail_case("unaligned GMEM request");
                if (gmem_req_write_o
                        && !((gmem_req_wstrb_o == 8'h0f)
                             || (gmem_req_wstrb_o == 8'hf0)))
                    fail_case("write did not select one F32 lane");
                if (!gmem_req_write_o && (gmem_req_wstrb_o != 8'b0))
                    fail_case("read carried write strobes");
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
            completion_count <= 0;
            commit_count <= 0;
            last_done_q <= 1'b0; last_error_q <= 1'b0;
            last_commit_q <= 1'b0; last_error_code_q <= 5'b0;
            last_element_error_code_q <= 4'b0;
            last_command_q <= 64'b0; last_node_lo_q <= 64'b0;
            last_node_hi_q <= 64'b0; last_required_q <= 1'b0;
            last_glu_q <= 1'b0; last_subtype_q <= 8'b0;
            last_profile_q <= 8'b0; last_kernel_q <= 32'b0;
            last_operator_census_q <= 32'b0;
            last_subtype_census_q <= 32'b0;
            last_profile_census_q <= 32'b0;
            last_src0_words_q <= 64'b0; last_src1_words_q <= 64'b0;
            last_launches_q <= 64'b0; last_terminals_q <= 64'b0;
            last_elements_q <= 64'b0; last_flags_q <= 5'b0;
            last_child_mask_q <= 5'b0; last_element_cycles_q <= 64'b0;
            last_read_beats_q <= 64'b0; last_read_responses_q <= 64'b0;
            last_read_bytes_q <= 64'b0; last_write_beats_q <= 64'b0;
            last_write_responses_q <= 64'b0; last_write_bytes_q <= 64'b0;
            last_active_cycles_q <= 64'b0;
            last_gmem_outstanding_q <= 1'b0;
            last_element_outstanding_q <= 1'b0;
        end else if (completion_valid_o) begin
            completion_count <= completion_count + 1;
            if (dst_commit_o)
                commit_count <= commit_count + 1;
            last_done_q <= done_o; last_error_q <= error_o;
            last_commit_q <= dst_commit_o; last_error_code_q <= error_code_o;
            last_element_error_code_q <= element_error_code_o;
            last_command_q <= completion_command_id_o;
            last_node_lo_q <= completion_canonical_node_id_lo_o;
            last_node_hi_q <= completion_canonical_node_id_hi_o;
            last_required_q <= completion_npu_required_o;
            last_glu_q <= completion_operation_glu_o;
            last_subtype_q <= completion_subtype_o;
            last_profile_q <= completion_profile_id_o;
            last_kernel_q <= completion_kernel_id_o;
            last_operator_census_q <= completion_operator_census_o;
            last_subtype_census_q <= completion_subtype_census_o;
            last_profile_census_q <= completion_profile_census_o;
            last_src0_words_q <= src0_words_completed_o;
            last_src1_words_q <= src1_words_completed_o;
            last_launches_q <= scalar_launches_o;
            last_terminals_q <= scalar_terminals_o;
            last_elements_q <= elements_completed_o;
            last_flags_q <= element_flags_or_o;
            last_child_mask_q <= element_child_call_mask_or_o;
            last_element_cycles_q <= element_active_cycles_o;
            last_read_beats_q <= gmem_read_beats_o;
            last_read_responses_q <= gmem_read_responses_o;
            last_read_bytes_q <= read_payload_bytes_o;
            last_write_beats_q <= gmem_write_beats_o;
            last_write_responses_q <= gmem_write_responses_o;
            last_write_bytes_q <= write_payload_bytes_o;
            last_active_cycles_q <= active_cycles_o;
            last_gmem_outstanding_q <= gmem_outstanding_o;
            last_element_outstanding_q <= element_outstanding_o;
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

    function automatic integer profile_elements(input logic [7:0] profile);
        begin
            case (profile)
                PROFILE_SIGMOID_16: profile_elements = 16;
                PROFILE_SIGMOID_2048: profile_elements = 2048;
                PROFILE_SOFTPLUS_16: profile_elements = 16;
                PROFILE_SILU_2048: profile_elements = 2048;
                PROFILE_SILU_6144: profile_elements = 6144;
                PROFILE_EXP_16: profile_elements = 16;
                PROFILE_SWIGLU_3584: profile_elements = 3584;
                default: profile_elements = 0;
            endcase
        end
    endfunction

    function automatic logic [31:0] profile_subtype_census(
        input logic [7:0] profile
    );
        begin
            case (profile)
                PROFILE_SIGMOID_16,
                PROFILE_SIGMOID_2048: profile_subtype_census = 32'd24;
                PROFILE_SOFTPLUS_16,
                PROFILE_EXP_16: profile_subtype_census = 32'd18;
                PROFILE_SILU_2048,
                PROFILE_SILU_6144: profile_subtype_census = 32'd36;
                PROFILE_SWIGLU_3584: profile_subtype_census = 32'd24;
                default: profile_subtype_census = 32'b0;
            endcase
        end
    endfunction

    function automatic logic [31:0] profile_count(
        input logic [7:0] profile
    );
        begin
            case (profile)
                PROFILE_SIGMOID_2048: profile_count = 32'd6;
                PROFILE_SWIGLU_3584: profile_count = 32'd24;
                PROFILE_SIGMOID_16,
                PROFILE_SOFTPLUS_16,
                PROFILE_SILU_2048,
                PROFILE_SILU_6144,
                PROFILE_EXP_16: profile_count = 32'd18;
                default: profile_count = 32'b0;
            endcase
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
            sparse_src0_word_q = 32'h3f80_0000;
            sparse_src1_word_q = 32'h4000_0000;
            repeat (3) @(posedge clk_i);
            @(negedge clk_i);
            rst_i = 1'b0;
            @(posedge clk_i);
            #1;
            if (!ready_o || busy_o || completion_valid_o
                    || gmem_outstanding_o || element_outstanding_o)
                fail_case("reset did not restore idle ownership");
        end
    endtask

    task automatic set_profile(input logic [7:0] profile);
        begin
            operation_glu_i = 1'b0;
            subtype_i = 8'h07;
            op_params_tail_zero_i = 1'b1;
            npu_required_i = 1'b1;
            command_id_i = 64'h0102_0304_0506_0000 | {56'b0, profile};
            canonical_node_id_lo_i =
                64'h1111_2222_3333_0000 | {56'b0, profile};
            canonical_node_id_hi_i =
                64'haaaa_bbbb_cccc_0000 | {56'b0, profile};
            dst_shadow_private_i = 1'b1;
            windows_generation_valid_i = 1'b1;
            ne0_i = 32'd1; ne1_i = 32'd16; ne2_i = 32'd1; ne3_i = 32'd1;
            src0_nb0_i = 64'd4; src0_nb1_i = 64'd4;
            src0_nb2_i = 64'd64; src0_nb3_i = 64'd64;
            src1_nb0_i = 64'b0; src1_nb1_i = 64'b0;
            src1_nb2_i = 64'b0; src1_nb3_i = 64'b0;
            dst_nb0_i = 64'd4; dst_nb1_i = 64'd4;
            dst_nb2_i = 64'd64; dst_nb3_i = 64'd64;

            case (profile)
                PROFILE_SIGMOID_16: begin end
                PROFILE_SIGMOID_2048: begin
                    ne0_i = 32'd2048; ne1_i = 32'd1;
                    src0_nb1_i = 64'd8192; src0_nb2_i = 64'd8192;
                    src0_nb3_i = 64'd8192;
                    dst_nb1_i = 64'd8192; dst_nb2_i = 64'd8192;
                    dst_nb3_i = 64'd8192;
                end
                PROFILE_SOFTPLUS_16: begin
                    subtype_i = 8'h0f;
                    ne0_i = 32'd16; ne1_i = 32'd1;
                    src0_nb1_i = 64'd64; dst_nb1_i = 64'd64;
                end
                PROFILE_SILU_2048: begin
                    subtype_i = 8'h0a;
                    ne0_i = 32'd128; ne1_i = 32'd16;
                    src0_nb1_i = 64'd512; src0_nb2_i = 64'd8192;
                    src0_nb3_i = 64'd8192;
                    dst_nb1_i = 64'd512; dst_nb2_i = 64'd8192;
                    dst_nb3_i = 64'd8192;
                end
                PROFILE_SILU_6144: begin
                    subtype_i = 8'h0a;
                    ne0_i = 32'd6144; ne1_i = 32'd1;
                    src0_nb1_i = 64'd24576; src0_nb2_i = 64'd24576;
                    src0_nb3_i = 64'd24576;
                    dst_nb1_i = 64'd24576; dst_nb2_i = 64'd24576;
                    dst_nb3_i = 64'd24576;
                end
                PROFILE_EXP_16: begin
                    subtype_i = 8'h0d;
                    ne0_i = 32'd1; ne1_i = 32'd1; ne2_i = 32'd16;
                    src0_nb1_i = 64'd4; src0_nb2_i = 64'd4;
                    src0_nb3_i = 64'd64;
                    dst_nb1_i = 64'd4; dst_nb2_i = 64'd4;
                    dst_nb3_i = 64'd64;
                end
                PROFILE_SWIGLU_3584: begin
                    operation_glu_i = 1'b1;
                    subtype_i = 8'h02;
                    ne0_i = 32'd3584; ne1_i = 32'd1;
                    src0_nb1_i = 64'd14336; src0_nb2_i = 64'd14336;
                    src0_nb3_i = 64'd14336;
                    src1_nb0_i = 64'd4; src1_nb1_i = 64'd14336;
                    src1_nb2_i = 64'd14336; src1_nb3_i = 64'd14336;
                    dst_nb1_i = 64'd14336; dst_nb2_i = 64'd14336;
                    dst_nb3_i = 64'd14336;
                end
                default: begin end
            endcase

            src0_base_i = 64'h0000_0000_0000_2004;
            src0_window_base_i = 64'h0000_0000_0000_2000;
            src0_window_bytes_i = 64'h0000_0000_0000_7000;
            src0_window_read_i = 1'b1; src0_window_write_i = 1'b0;
            if (operation_glu_i) begin
                src1_base_i = 64'h0000_0000_0000_a004;
                src1_window_base_i = 64'h0000_0000_0000_a000;
                src1_window_bytes_i = 64'h0000_0000_0000_5000;
            end else begin
                src1_base_i = 64'b0;
                src1_window_base_i = 64'b0;
                src1_window_bytes_i = 64'b0;
            end
            src1_window_read_i = 1'b1; src1_window_write_i = 1'b0;
            dst_base_i = 64'h0000_0000_0001_0004;
            dst_window_base_i = 64'h0000_0000_0001_0000;
            dst_window_bytes_i = 64'h0000_0000_0000_7000;
            dst_window_read_i = 1'b0; dst_window_write_i = 1'b1;
        end
    endtask

    task automatic load_uniform(
        input logic [7:0] profile,
        input logic [31:0] src0_word,
        input logic [31:0] src1_word
    );
        integer index;
        begin
            for (index = 0; index < profile_elements(profile);
                    index = index + 1) begin
                put_u32(src0_base_i + (index * 4), src0_word);
                if (operation_glu_i)
                    put_u32(src1_base_i + (index * 4), src1_word);
                put_u32(dst_base_i + (index * 4), 32'hcccc_cccc);
            end
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
        integer before_count, waited;
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
                if (!last_error_q || last_done_q || last_commit_q
                        || (last_error_code_q != expected_code))
                    fail_case("unexpected error terminal status");
            end else begin
                if (!last_done_q || last_error_q || !last_commit_q
                        || (last_error_code_q != 5'b0))
                    fail_case("unexpected success terminal status");
            end
            if (last_gmem_outstanding_q || last_element_outstanding_q)
                fail_case("terminal completion retained outstanding work");
        end
    endtask

    task automatic check_identity_profile(
        input logic [63:0] command,
        input logic [63:0] node_lo,
        input logic [63:0] node_hi,
        input logic [7:0] profile
    );
        logic expected_glu;
        logic [31:0] expected_kernel;
        begin
            expected_glu = (profile == PROFILE_SWIGLU_3584);
            expected_kernel = expected_glu ? KERNEL_GLU : KERNEL_UNARY;
            if ((last_command_q != command) || (last_node_lo_q != node_lo)
                    || (last_node_hi_q != node_hi) || !last_required_q
                    || (last_glu_q != expected_glu)
                    || (last_subtype_q != subtype_i)
                    || (last_profile_q != profile)
                    || (last_kernel_q != expected_kernel)
                    || (last_operator_census_q
                        != (expected_glu ? 32'd24 : 32'd96))
                    || (last_subtype_census_q
                        != profile_subtype_census(profile))
                    || (last_profile_census_q != profile_count(profile)))
                fail_case("completion identity/profile/census mismatch");
        end
    endtask

    task automatic check_success_counters(
        input logic [7:0] profile,
        input logic [31:0] child_cycles,
        input logic [4:0] child_mask
    );
        integer count, reads;
        begin
            count = profile_elements(profile);
            reads = (profile == PROFILE_SWIGLU_3584) ? (count * 2) : count;
            if ((last_src0_words_q != count)
                    || (last_src1_words_q
                        != ((profile == PROFILE_SWIGLU_3584) ? count : 0))
                    || (last_launches_q != count)
                    || (last_terminals_q != count)
                    || (last_elements_q != count)
                    || (last_read_beats_q != reads)
                    || (last_read_responses_q != reads)
                    || (last_read_bytes_q != (reads * 4))
                    || (last_write_beats_q != count)
                    || (last_write_responses_q != count)
                    || (last_write_bytes_q != (count * 4))
                    || (last_flags_q != FLAGS_NX)
                    || (last_child_mask_q != child_mask)
                    || (last_element_cycles_q != (count * child_cycles))
                    || (last_active_cycles_q <= last_element_cycles_q)
                    || (accepted_reads != reads)
                    || (accepted_writes != count)
                    || (successful_writes != count)
                    || (last_element_error_code_q != 4'b0))
                fail_case("success counter/cardinality oracle mismatch");
        end
    endtask

    task automatic run_success(
        input string label,
        input logic [7:0] profile,
        input logic [31:0] expected_word,
        input logic [31:0] child_cycles,
        input logic [4:0] child_mask,
        input bit exercise_backpressure
    );
        integer index;
        logic [63:0] command, node_lo, node_hi;
        begin
            reset_case();
            set_profile(profile);
            load_uniform(profile, 32'h3f80_0000, 32'h4000_0000);
            if (exercise_backpressure) begin
                request_backpressure_q = 1'b1;
                response_delay_q = 2;
            end
            command = command_id_i; node_lo = canonical_node_id_lo_i;
            node_hi = canonical_node_id_hi_i;
            pulse_start();
            // Live input mutation cannot change the resident command.
            command_id_i = 64'hdead_beef_dead_beef;
            canonical_node_id_lo_i = 64'b0;
            canonical_node_id_hi_i = 64'b0;
            subtype_i = 8'h55;
            wait_completion(1'b0, 5'b0, 1200000);
            // Restore expected subtype for the common identity checker.
            case (profile)
                PROFILE_SIGMOID_16,
                PROFILE_SIGMOID_2048: subtype_i = 8'h07;
                PROFILE_SOFTPLUS_16: subtype_i = 8'h0f;
                PROFILE_SILU_2048,
                PROFILE_SILU_6144: subtype_i = 8'h0a;
                PROFILE_EXP_16: subtype_i = 8'h0d;
                default: subtype_i = 8'h02;
            endcase
            check_identity_profile(command, node_lo, node_hi, profile);
            check_success_counters(profile, child_cycles, child_mask);
            for (index = 0; index < profile_elements(profile);
                    index = index + 1)
                if (get_u32(dst_base_i + (index * 4)) !== expected_word)
                    fail_case({label, ": raw-bit destination mismatch"});
            if (exercise_backpressure && (held_stability_cycles == 0))
                fail_case("positive case did not exercise request backpressure");
            $display("[NPU-UNARY-GLU-WRITEBACK][INFO] %s profile=%0d elements=%0d raw=%08x read=%0d write=%0d child-cycles=%0d",
                     label, profile, profile_elements(profile), expected_word,
                     accepted_reads, accepted_writes,
                     last_element_cycles_q);
        end
    endtask

    task automatic set_sparse_high_windows(input logic [7:0] profile);
        logic [63:0] bytes;
        begin
            bytes = (64'(profile_elements(profile)) * 64'd4) + 64'd8;
            src0_base_i = 64'h0000_0001_0000_2004;
            src0_window_base_i = 64'h0000_0001_0000_2000;
            src0_window_bytes_i = bytes;
            if (operation_glu_i) begin
                src1_base_i = 64'h0000_0002_0000_2004;
                src1_window_base_i = 64'h0000_0002_0000_2000;
                src1_window_bytes_i = bytes;
            end
            dst_base_i = 64'h0000_0003_0000_2004;
            dst_window_base_i = 64'h0000_0003_0000_2000;
            dst_window_bytes_i = bytes;
        end
    endtask

    task automatic run_sparse_admission(
        input string label,
        input logic [7:0] profile
    );
        logic [63:0] command, node_lo, node_hi;
        begin
            reset_case();
            set_profile(profile);
            set_sparse_high_windows(profile);
            sparse_mode_q = 1'b1;
            inject_error_request_ordinal_q = 0;
            command = command_id_i; node_lo = canonical_node_id_lo_i;
            node_hi = canonical_node_id_hi_i;
            pulse_start();
            wait_completion(1'b1, ERR_GMEM, 1000);
            check_identity_profile(command, node_lo, node_hi, profile);
            if ((accepted_requests != 1) || (accepted_reads != 1)
                    || (accepted_writes != 0)
                    || (first_read_addr_q
                        != {src0_base_i[63:3], 3'b000})
                    || (last_read_beats_q != 64'd1)
                    || (last_read_responses_q != 64'd1)
                    || (last_read_bytes_q != 64'b0)
                    || (last_src0_words_q != 64'b0)
                    || (last_launches_q != 64'b0)
                    || (last_elements_q != 64'b0))
                fail_case("sparse full-width admission counter mismatch");
            $display("[NPU-UNARY-GLU-WRITEBACK][INFO] %s profile=%0d ne=%0dx%0dx%0dx%0d high-read=%016x preflight=accepted commit=0",
                     label, profile, ne0_i, ne1_i, ne2_i, ne3_i,
                     first_read_addr_q);
        end
    endtask

    task automatic run_zero_traffic_error(
        input string label,
        input logic [4:0] expected_error,
        input logic [7:0] expected_profile
    );
        begin
            pulse_start();
            wait_completion(1'b1, expected_error, 1000);
            if ((accepted_requests != 0) || (accepted_reads != 0)
                    || (accepted_writes != 0) || (last_read_beats_q != 0)
                    || (last_read_responses_q != 0)
                    || (last_write_beats_q != 0)
                    || (last_write_responses_q != 0)
                    || (last_launches_q != 0) || (last_terminals_q != 0)
                    || (last_elements_q != 0)
                    || (last_profile_q != expected_profile))
                fail_case({label, ": zero-traffic preflight mismatch"});
            $display("[NPU-UNARY-GLU-WRITEBACK][INFO] %s error=%0d traffic=0 commit=0",
                     label, expected_error);
        end
    endtask

    task automatic test_preflight_failures;
        begin
            reset_case(); set_profile(PROFILE_SIGMOID_16);
            subtype_i = 8'h55;
            run_zero_traffic_error("unknown-subtype", ERR_PROFILE,
                                   PROFILE_INVALID);

            reset_case(); set_profile(PROFILE_SIGMOID_16);
            op_params_tail_zero_i = 1'b0;
            run_zero_traffic_error("op-params-tail", ERR_PROFILE,
                                   PROFILE_SIGMOID_16);

            reset_case(); set_profile(PROFILE_SIGMOID_16);
            src0_nb1_i = 64'd8;
            run_zero_traffic_error("profile-stride", ERR_PROFILE,
                                   PROFILE_INVALID);

            reset_case(); set_profile(PROFILE_SIGMOID_16);
            src0_window_read_i = 1'b0;
            run_zero_traffic_error("source0-permission", ERR_SRC0,
                                   PROFILE_SIGMOID_16);

            reset_case(); set_profile(PROFILE_SWIGLU_3584);
            src1_window_write_i = 1'b1;
            run_zero_traffic_error("source1-permission", ERR_SRC1,
                                   PROFILE_SWIGLU_3584);

            reset_case(); set_profile(PROFILE_SIGMOID_16);
            dst_window_read_i = 1'b1;
            run_zero_traffic_error("destination-permission", ERR_DST,
                                   PROFILE_SIGMOID_16);

            reset_case(); set_profile(PROFILE_SIGMOID_16);
            dst_base_i = src0_base_i;
            dst_window_base_i = src0_window_base_i;
            dst_window_bytes_i = src0_window_bytes_i;
            run_zero_traffic_error("physical-alias", ERR_ALIAS,
                                   PROFILE_SIGMOID_16);

            reset_case(); set_profile(PROFILE_SIGMOID_16);
            src0_base_i = 64'hffff_ffff_ffff_fffc;
            src0_window_base_i = 64'hffff_ffff_ffff_fff8;
            src0_window_bytes_i = 64'd8;
            run_zero_traffic_error("source0-128b-overflow", ERR_SRC0,
                                   PROFILE_SIGMOID_16);
        end
    endtask

    task automatic test_late_read_error;
        begin
            reset_case();
            set_profile(PROFILE_SIGMOID_16);
            load_uniform(PROFILE_SIGMOID_16, 32'h3f80_0000, 32'b0);
            inject_error_request_ordinal_q = 4;
            pulse_start();
            wait_completion(1'b1, ERR_GMEM, 10000);
            if ((accepted_reads != 3) || (accepted_writes != 2)
                    || (last_src0_words_q != 2)
                    || (last_launches_q != 2) || (last_terminals_q != 2)
                    || (last_elements_q != 2)
                    || (last_read_beats_q != 3)
                    || (last_read_responses_q != 3)
                    || (last_read_bytes_q != 8)
                    || (last_write_beats_q != 2)
                    || (last_write_responses_q != 2)
                    || (last_write_bytes_q != 8))
                fail_case("late read error accounting mismatch");
            $display("[NPU-UNARY-GLU-WRITEBACK][INFO] late-read-error private-elements=2 commit=0 terminal-outstanding=0");
        end
    endtask

    task automatic test_late_write_error;
        begin
            reset_case();
            set_profile(PROFILE_SIGMOID_16);
            load_uniform(PROFILE_SIGMOID_16, 32'h3f80_0000, 32'b0);
            inject_error_request_ordinal_q = 5;
            pulse_start();
            wait_completion(1'b1, ERR_GMEM, 10000);
            if ((accepted_reads != 3) || (accepted_writes != 3)
                    || (last_src0_words_q != 3)
                    || (last_launches_q != 3) || (last_terminals_q != 3)
                    || (last_elements_q != 2)
                    || (last_read_beats_q != 3)
                    || (last_read_responses_q != 3)
                    || (last_read_bytes_q != 12)
                    || (last_write_beats_q != 3)
                    || (last_write_responses_q != 3)
                    || (last_write_bytes_q != 8))
                fail_case("late write error accounting mismatch");
            $display("[NPU-UNARY-GLU-WRITEBACK][INFO] late-write-error successful-private-elements=2 commit=0 terminal-outstanding=0");
        end
    endtask

    task automatic test_response_timeout_drain;
        begin
            reset_case();
            set_profile(PROFILE_SIGMOID_16);
            load_uniform(PROFILE_SIGMOID_16, 32'h3f80_0000, 32'b0);
            response_delay_q = 20;
            pulse_start();
            wait_completion(1'b1, ERR_STALL, 1000);
            if (!drain_seen_q || (accepted_requests != 1)
                    || (accepted_reads != 1) || (accepted_writes != 0)
                    || (last_read_beats_q != 1)
                    || (last_read_responses_q != 1)
                    || (last_read_bytes_q != 0)
                    || (last_src0_words_q != 0) || (last_launches_q != 0)
                    || (last_elements_q != 0))
                fail_case("accepted-response timeout did not drain exactly once");
            $display("[NPU-UNARY-GLU-WRITEBACK][INFO] response-timeout accepted=1 drained=1 payload=0 commit=0");
        end
    endtask

    task automatic test_request_timeout;
        begin
            reset_case();
            set_profile(PROFILE_SIGMOID_16);
            allow_requests_q = 1'b0;
            pulse_start();
            wait_completion(1'b1, ERR_STALL, 1000);
            if ((accepted_requests != 0) || (held_stability_cycles < 8)
                    || drain_seen_q || (last_read_beats_q != 0)
                    || (last_read_responses_q != 0))
                fail_case("unaccepted request timeout accounting mismatch");
            $display("[NPU-UNARY-GLU-WRITEBACK][INFO] request-timeout accepted=0 stable-cycles=%0d commit=0",
                     held_stability_cycles);
        end
    endtask

    initial begin
        rst_i = 1'b1;
        start_i = 1'b0;
        operation_glu_i = 1'b0;
        subtype_i = 8'b0;
        op_params_tail_zero_i = 1'b0;
        npu_required_i = 1'b0;
        command_id_i = 64'b0;
        canonical_node_id_lo_i = 64'b0;
        canonical_node_id_hi_i = 64'b0;
        dst_shadow_private_i = 1'b0;
        windows_generation_valid_i = 1'b0;
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
        allow_requests_q = 1'b1;
        request_backpressure_q = 1'b0;
        response_delay_q = 0;
        inject_error_request_ordinal_q = -1;
        sparse_mode_q = 1'b0;
        sparse_src0_word_q = 32'h3f80_0000;
        sparse_src1_word_q = 32'h4000_0000;

        repeat (4) @(posedge clk_i);

        run_success("SIGMOID/[1,16,1,1]", PROFILE_SIGMOID_16,
                    32'h3f3b_26a8, CYCLES_SIGMOID, MASK_SIGMOID, 1'b1);
        run_success("SOFTPLUS/[16,1,1,1]", PROFILE_SOFTPLUS_16,
                    32'h3fa8_18f5, CYCLES_SOFTPLUS, MASK_SOFTPLUS, 1'b0);
        run_success("EXP/[1,1,16,1]", PROFILE_EXP_16,
                    32'h402d_f854, CYCLES_EXP, MASK_EXP, 1'b0);
        run_success("SILU/[128,16,1,1]", PROFILE_SILU_2048,
                    32'h3f3b_26a8, CYCLES_SILU, MASK_SILU, 1'b0);
        run_success("SWIGLU/[3584,1,1,1]", PROFILE_SWIGLU_3584,
                    32'h3fbb_26a8, CYCLES_SWIGLU, MASK_SWIGLU, 1'b0);

        run_sparse_admission("SIGMOID-max-profile",
                             PROFILE_SIGMOID_2048);
        run_sparse_admission("SILU-max-profile", PROFILE_SILU_6144);
        run_sparse_admission("SWIGLU-dual-source-profile",
                             PROFILE_SWIGLU_3584);

        test_preflight_failures();
        test_late_read_error();
        test_late_write_error();
        test_response_timeout_drain();
        test_request_timeout();

        $display("[NPU-UNARY-GLU-WRITEBACK][PASS] manifest=UNARY96+GLU24 profiles=7 subtypes=SIGMOID24/SOFTPLUS18/SILU36/EXP18/SWIGLU24 raw-bit=exact preflight=128b R-R-W=proved single-outstanding=1 transactional-commit=1 assertions=off waveform=off");
        $finish;
    end

endmodule

`default_nettype wire
