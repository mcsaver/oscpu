`timescale 1ns/1ps
`default_nettype none

// Full frozen-v5 F16 attention MUL_MAT transaction test.  Numerical expected
// values are literal IEEE-754 raw words.  The testbench performs only integer
// address/census bookkeeping; all conversion, FMA, and add work is Verilated.
module tb_f16_attention_matmul_writeback_adapter;

    localparam integer K = 256;
    localparam integer ROWS = 256;
    localparam integer HEADS = 8;
    localparam integer OUTPUTS = 2048;
    localparam integer SRC0_BYTES = 262144;
    localparam integer SRC1_BYTES = 8192;
    localparam integer DST_BYTES = 8192;
    localparam integer SRC1_BEATS = 1024;
    localparam integer SRC0_BEATS = 131072;
    localparam integer READ_BEATS = 132096;
    localparam integer READ_BYTES = 1056768;
    localparam integer MACS = 524288;
    localparam integer REDUCTIONS = 73728;
    localparam integer STALL_TIMEOUT = 24;
    localparam integer MEM_BYTES = 327680;

    localparam logic [63:0] SRC0_BASE = 64'h0000_0000_0000_0000;
    localparam logic [63:0] SRC1_BASE = 64'h0000_0000_0004_0000;
    localparam logic [63:0] DST_BASE = 64'h0000_0000_0004_4000;
    localparam logic [63:0] ACTIVE_ROOT_BASE = 64'h0000_0000_0004_8000;
    localparam logic [31:0] KERNEL_F16_ATTENTION = 32'h514e0009;
    localparam logic [15:0] MANIFEST_MUL_MAT = 16'd29;
    localparam logic [7:0] PROFILE_KQ = 8'd0;
    localparam logic [7:0] PROFILE_KQV = 8'd1;

    localparam logic [4:0] ERR_DESCRIPTOR = 5'd1;
    localparam logic [4:0] ERR_SRC0 = 5'd2;
    localparam logic [4:0] ERR_SRC1 = 5'd3;
    localparam logic [4:0] ERR_DST = 5'd4;
    localparam logic [4:0] ERR_ALIAS = 5'd5;
    localparam logic [4:0] ERR_GMEM = 5'd6;
    localparam logic [4:0] ERR_STALL = 5'd8;

    reg clk_i, rst_i, start_i;
    wire ready_o, busy_o;
    reg [15:0] manifest_op_id_i;
    reg [2:0] source_arity_i;
    reg [127:0] op_params_i;
    reg op_params_tail_zero_i, npu_required_i;
    reg [63:0] command_id_i;
    reg [63:0] canonical_node_id_lo_i, canonical_node_id_hi_i;
    reg dst_shadow_private_i, windows_generation_valid_i;

    reg [7:0] src0_dtype_i, src1_dtype_i, dst_dtype_i;
    reg [31:0] src0_flags_i, src1_flags_i, dst_flags_i;
    reg [63:0] src0_view_off_i, src1_view_off_i, dst_view_off_i;
    reg [31:0] src0_ne0_i, src0_ne1_i, src0_ne2_i, src0_ne3_i;
    reg [31:0] src1_ne0_i, src1_ne1_i, src1_ne2_i, src1_ne3_i;
    reg [31:0] dst_ne0_i, dst_ne1_i, dst_ne2_i, dst_ne3_i;
    reg [63:0] src0_base_i, src1_base_i, dst_base_i;
    reg [63:0] src0_nb0_i, src0_nb1_i, src0_nb2_i, src0_nb3_i;
    reg [63:0] src1_nb0_i, src1_nb1_i, src1_nb2_i, src1_nb3_i;
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
    wire [15:0] completion_manifest_op_id_o;
    wire [2:0] completion_source_arity_o;
    wire [7:0] completion_profile_id_o;
    wire [31:0] completion_kernel_id_o;
    wire [31:0] completion_operator_census_o;
    wire [31:0] completion_profile_census_o;
    wire done_o, error_o;
    wire [4:0] error_code_o, numeric_flags_o;
    wire [2:0] conversion_flags_o;
    wire poisoned_o;
    wire [63:0] outputs_computed_o, outputs_completed_o;
    wire [63:0] source0_half_words_completed_o;
    wire [63:0] source1_float_words_completed_o;
    wire [63:0] conversion_words_completed_o, work_items_completed_o;
    wire [63:0] gmem_read_requests_o, gmem_read_responses_o;
    wire [63:0] read_payload_bytes_o;
    wire [63:0] gmem_write_requests_o, gmem_write_responses_o;
    wire [63:0] write_payload_bytes_o;
    wire [63:0] fma_requests_o, fma_responses_o;
    wire [63:0] reduction_requests_o, reduction_responses_o;
    wire [63:0] active_cycles_o;
    wire gmem_outstanding_o, numeric_outstanding_o, gmem_drain_o;

    TensorNpuF16AttentionMatmulWritebackAdapter #(
        .STALL_TIMEOUT_CYCLES(STALL_TIMEOUT),
        .COMMAND_TIMEOUT_CYCLES(64'd10000000),
        .DRAIN_TIMEOUT_CYCLES(32'd64),
        .ABORT_HOLD_TIMEOUT_CYCLES(32'd64)
    ) dut (
        .clk_i(clk_i), .rst_i(rst_i), .start_i(start_i),
        .ready_o(ready_o), .busy_o(busy_o),
        .manifest_op_id_i(manifest_op_id_i),
        .source_arity_i(source_arity_i), .op_params_i(op_params_i),
        .op_params_tail_zero_i(op_params_tail_zero_i),
        .npu_required_i(npu_required_i), .command_id_i(command_id_i),
        .canonical_node_id_lo_i(canonical_node_id_lo_i),
        .canonical_node_id_hi_i(canonical_node_id_hi_i),
        .dst_shadow_private_i(dst_shadow_private_i),
        .windows_generation_valid_i(windows_generation_valid_i),
        .src0_dtype_i(src0_dtype_i), .src0_flags_i(src0_flags_i),
        .src0_view_off_i(src0_view_off_i),
        .src0_ne0_i(src0_ne0_i), .src0_ne1_i(src0_ne1_i),
        .src0_ne2_i(src0_ne2_i), .src0_ne3_i(src0_ne3_i),
        .src0_base_i(src0_base_i), .src0_nb0_i(src0_nb0_i),
        .src0_nb1_i(src0_nb1_i), .src0_nb2_i(src0_nb2_i),
        .src0_nb3_i(src0_nb3_i),
        .src1_dtype_i(src1_dtype_i), .src1_flags_i(src1_flags_i),
        .src1_view_off_i(src1_view_off_i),
        .src1_ne0_i(src1_ne0_i), .src1_ne1_i(src1_ne1_i),
        .src1_ne2_i(src1_ne2_i), .src1_ne3_i(src1_ne3_i),
        .src1_base_i(src1_base_i), .src1_nb0_i(src1_nb0_i),
        .src1_nb1_i(src1_nb1_i), .src1_nb2_i(src1_nb2_i),
        .src1_nb3_i(src1_nb3_i),
        .dst_dtype_i(dst_dtype_i), .dst_flags_i(dst_flags_i),
        .dst_view_off_i(dst_view_off_i),
        .dst_ne0_i(dst_ne0_i), .dst_ne1_i(dst_ne1_i),
        .dst_ne2_i(dst_ne2_i), .dst_ne3_i(dst_ne3_i),
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
        .completion_valid_o(completion_valid_o),
        .dst_commit_o(dst_commit_o),
        .completion_command_id_o(completion_command_id_o),
        .completion_canonical_node_id_lo_o(
            completion_canonical_node_id_lo_o),
        .completion_canonical_node_id_hi_o(
            completion_canonical_node_id_hi_o),
        .completion_npu_required_o(completion_npu_required_o),
        .completion_manifest_op_id_o(completion_manifest_op_id_o),
        .completion_source_arity_o(completion_source_arity_o),
        .completion_profile_id_o(completion_profile_id_o),
        .completion_kernel_id_o(completion_kernel_id_o),
        .completion_operator_census_o(completion_operator_census_o),
        .completion_profile_census_o(completion_profile_census_o),
        .done_o(done_o), .error_o(error_o), .error_code_o(error_code_o),
        .numeric_flags_o(numeric_flags_o),
        .conversion_flags_o(conversion_flags_o), .poisoned_o(poisoned_o),
        .outputs_computed_o(outputs_computed_o),
        .outputs_completed_o(outputs_completed_o),
        .source0_half_words_completed_o(source0_half_words_completed_o),
        .source1_float_words_completed_o(source1_float_words_completed_o),
        .conversion_words_completed_o(conversion_words_completed_o),
        .work_items_completed_o(work_items_completed_o),
        .gmem_read_requests_o(gmem_read_requests_o),
        .gmem_read_responses_o(gmem_read_responses_o),
        .read_payload_bytes_o(read_payload_bytes_o),
        .gmem_write_requests_o(gmem_write_requests_o),
        .gmem_write_responses_o(gmem_write_responses_o),
        .write_payload_bytes_o(write_payload_bytes_o),
        .fma_requests_o(fma_requests_o), .fma_responses_o(fma_responses_o),
        .reduction_requests_o(reduction_requests_o),
        .reduction_responses_o(reduction_responses_o),
        .active_cycles_o(active_cycles_o),
        .gmem_outstanding_o(gmem_outstanding_o),
        .numeric_outstanding_o(numeric_outstanding_o),
        .gmem_drain_o(gmem_drain_o)
    );

    // A second public instance provides direct ready/valid and fused-operation
    // coverage without observing any adapter internals.
    reg probe_req_valid_q, probe_rsp_ready_q;
    reg [31:0] probe_a_q, probe_b_q, probe_c_q;
    wire probe_req_ready_w, probe_rsp_valid_w;
    wire [31:0] probe_result_w;
    wire [4:0] probe_flags_w;
    TensorNpuFp32Fma fma_probe (
        .clk_i(clk_i), .rst_i(rst_i),
        .req_valid_i(probe_req_valid_q), .req_ready_o(probe_req_ready_w),
        .multiplicand_a_bits_i(probe_a_q),
        .multiplicand_b_bits_i(probe_b_q), .addend_bits_i(probe_c_q),
        .rsp_valid_o(probe_rsp_valid_w), .rsp_ready_i(probe_rsp_ready_q),
        .result_bits_o(probe_result_w), .flags_o(probe_flags_w)
    );

    initial clk_i = 1'b0;
    always #5 clk_i <= ~clk_i;

    reg [7:0] gmem [0:MEM_BYTES-1];
    reg allow_requests_q, request_backpressure_q, check_order_q;
    integer active_profile_q;
    integer normal_response_delay_q;
    integer inject_read_error_ordinal_q, inject_write_error_ordinal_q;
    integer late_response_ordinal_q, late_response_delay_q;
    reg pending_q, pending_write_q, pending_error_q;
    reg [63:0] pending_addr_q, pending_wdata_q;
    reg [7:0] pending_wstrb_q;
    integer pending_delay_q;
    integer global_cycles, accepted_requests, accepted_reads, accepted_writes;
    integer response_count, successful_writes, completion_count, commit_count;
    integer held_stability_cycles, drain_seen_count;
    reg request_hold_q, held_request_write_q;
    reg [63:0] held_request_addr_q, held_request_wdata_q;
    reg [7:0] held_request_wstrb_q;
    integer order_phase_q, order_head_q, order_src1_beat_q;
    integer order_row_q, order_src0_beat_q;
    integer lane;

    assign gmem_req_ready_i = !rst_i && allow_requests_q && !pending_q
                            && !gmem_rsp_valid_i
                            && (!request_backpressure_q || request_hold_q);

    task automatic fail_case(input string reason);
        begin
            $display("[NPU-F16-ATTENTION][FAIL] %s cycle=%0d busy=%0b done=%0b error=%0b err=%0d req=%0d/%0d rsp=%0d commit=%0d",
                     reason, global_cycles, busy_o, done_o, error_o,
                     error_code_o, accepted_reads, accepted_writes,
                     response_count, commit_count);
            $display("[NPU-F16-ATTENTION][EVIDENCE] out=%0d/%0d src=%0d/%0d conv=%0d work=%0d read=%0d/%0d/%0dB write=%0d/%0d/%0dB fma=%0d/%0d red=%0d/%0d flags=%02x/%01x owner=%0b/%0b drain=%0b",
                     outputs_computed_o, outputs_completed_o,
                     source0_half_words_completed_o,
                     source1_float_words_completed_o,
                     conversion_words_completed_o, work_items_completed_o,
                     gmem_read_requests_o, gmem_read_responses_o,
                     read_payload_bytes_o, gmem_write_requests_o,
                     gmem_write_responses_o, write_payload_bytes_o,
                     fma_requests_o, fma_responses_o,
                     reduction_requests_o, reduction_responses_o,
                     numeric_flags_o, conversion_flags_o,
                     gmem_outstanding_o, numeric_outstanding_o, gmem_drain_o);
            $fatal(1);
        end
    endtask

    function automatic [63:0] memory_read64(input logic [63:0] address);
        integer byte_address;
        integer read_lane;
        begin
            byte_address = address;
            memory_read64 = 64'b0;
            for (read_lane = 0; read_lane < 8; read_lane = read_lane + 1)
                memory_read64[(read_lane * 8) +: 8]
                    = gmem[byte_address + read_lane];
        end
    endfunction

    function automatic integer src0_address(
        input integer profile,
        input integer source_head,
        input integer row,
        input integer element
    );
        begin
            if (profile == 0)
                src0_address = row * 1024 + source_head * 512
                             + element * 2;
            else
                src0_address = source_head * 131072 + row * 512
                             + element * 2;
        end
    endfunction

    function automatic [31:0] expected_raw(
        input integer head,
        input integer row
    );
        begin
            case (row & 7)
                0: expected_raw = 32'h0000_0000;
                1: expected_raw = 32'h3f80_0000;
                2: expected_raw = 32'h3f80_4000;
                3: expected_raw = 32'h3f80_0000;
                4: expected_raw = 32'h4000_0000;
                5: expected_raw = 32'h3f80_0000;
                6: expected_raw = 32'h3400_0000;
                default: expected_raw = (head < 4) ? 32'h3f80_0000
                                                   : 32'h4000_0000;
            endcase
        end
    endfunction

    /* verilator lint_off BLKSEQ */
    always @(posedge clk_i) begin
        integer expected_chunk;
        integer expected_group;
        integer expected_beat;
        integer expected_source_head;
        integer expected_address;
        if (rst_i) begin
            pending_q <= 1'b0;
            pending_write_q <= 1'b0;
            pending_error_q <= 1'b0;
            pending_addr_q <= 64'b0;
            pending_wdata_q <= 64'b0;
            pending_wstrb_q <= 8'b0;
            pending_delay_q <= 0;
            gmem_rsp_valid_i <= 1'b0;
            gmem_rsp_rdata_i <= 64'b0;
            gmem_rsp_error_i <= 1'b0;
            global_cycles <= 0;
            accepted_requests <= 0;
            accepted_reads <= 0;
            accepted_writes <= 0;
            response_count <= 0;
            successful_writes <= 0;
            completion_count <= 0;
            commit_count <= 0;
            held_stability_cycles <= 0;
            drain_seen_count <= 0;
            request_hold_q <= 1'b0;
            held_request_write_q <= 1'b0;
            held_request_addr_q <= 64'b0;
            held_request_wdata_q <= 64'b0;
            held_request_wstrb_q <= 8'b0;
            order_phase_q <= 0;
            order_head_q <= 0;
            order_src1_beat_q <= 0;
            order_row_q <= 0;
            order_src0_beat_q <= 0;
        end else begin
            global_cycles <= global_cycles + 1;
            if (completion_valid_o)
                completion_count <= completion_count + 1;
            if (dst_commit_o)
                commit_count <= commit_count + 1;
            if (gmem_drain_o)
                drain_seen_count <= drain_seen_count + 1;

            if (request_hold_q) begin
                if (!gmem_req_valid_o)
                    fail_case("held request withdrew valid");
                if ((gmem_req_write_o !== held_request_write_q)
                        || (gmem_req_addr_o !== held_request_addr_q)
                        || (gmem_req_wdata_o !== held_request_wdata_q)
                        || (gmem_req_wstrb_o !== held_request_wstrb_q))
                    fail_case("held request payload changed");
                held_stability_cycles <= held_stability_cycles + 1;
            end
            request_hold_q <= gmem_req_valid_o && !gmem_req_ready_i;
            if (gmem_req_valid_o && !gmem_req_ready_i) begin
                held_request_write_q <= gmem_req_write_o;
                held_request_addr_q <= gmem_req_addr_o;
                held_request_wdata_q <= gmem_req_wdata_o;
                held_request_wstrb_q <= gmem_req_wstrb_o;
            end

            if (gmem_req_valid_o && gmem_req_ready_i) begin
                if (pending_q || gmem_rsp_valid_i || gmem_outstanding_o)
                    fail_case("more than one GMEM owner");
                if ((gmem_req_addr_o[2:0] != 3'b000)
                        || (gmem_req_addr_o >= 64'(MEM_BYTES)))
                    fail_case("GMEM address/alignment");
                pending_q <= 1'b1;
                pending_write_q <= gmem_req_write_o;
                pending_addr_q <= gmem_req_addr_o;
                pending_wdata_q <= gmem_req_wdata_o;
                pending_wstrb_q <= gmem_req_wstrb_o;
                pending_error_q <= (!gmem_req_write_o
                        && (accepted_reads == inject_read_error_ordinal_q))
                    || (gmem_req_write_o
                        && (accepted_writes == inject_write_error_ordinal_q));
                pending_delay_q <= (accepted_requests
                                    == late_response_ordinal_q)
                                 ? late_response_delay_q
                                 : normal_response_delay_q;
                accepted_requests <= accepted_requests + 1;

                if (check_order_q) begin
                    if (order_phase_q == 0) begin
                        expected_address = SRC1_BASE + order_head_q * 1024
                                           + order_src1_beat_q * 8;
                        if (gmem_req_write_o
                                || (gmem_req_addr_o != 64'(expected_address)))
                            fail_case("src1 preload order");
                        if (order_src1_beat_q == 127) begin
                            order_phase_q <= 1;
                            order_src1_beat_q <= 0;
                            order_row_q <= 0;
                            order_src0_beat_q <= 0;
                        end else begin
                            order_src1_beat_q <= order_src1_beat_q + 1;
                        end
                    end else if (order_phase_q == 1) begin
                        expected_chunk = order_src0_beat_q / 8;
                        expected_group = (order_src0_beat_q % 8) / 2;
                        expected_beat = order_src0_beat_q % 2;
                        expected_source_head = order_head_q / 4;
                        expected_address = SRC0_BASE
                            + src0_address(active_profile_q,
                                           expected_source_head,
                                           order_row_q,
                                           expected_chunk * 32
                                           + expected_group * 8)
                            + expected_beat * 8;
                        if (gmem_req_write_o
                                || (gmem_req_addr_o != 64'(expected_address)))
                            fail_case("src0 lane/chunk order");
                        if (order_src0_beat_q == 63) begin
                            order_phase_q <= 2;
                            order_src0_beat_q <= 0;
                        end else begin
                            order_src0_beat_q <= order_src0_beat_q + 1;
                        end
                    end else begin
                        expected_address = DST_BASE + order_head_q * 1024
                                           + order_row_q * 4;
                        if (!gmem_req_write_o
                                || (gmem_req_addr_o
                                    != (64'(expected_address)
                                        & 64'hffff_ffff_ffff_fff8)))
                            fail_case("destination order");
                        if (order_row_q == 255) begin
                            if (order_head_q != 7) begin
                                order_head_q <= order_head_q + 1;
                                order_phase_q <= 0;
                                order_src1_beat_q <= 0;
                                order_row_q <= 0;
                            end
                        end else begin
                            order_row_q <= order_row_q + 1;
                            order_phase_q <= 1;
                        end
                    end
                end

                if (gmem_req_write_o) begin
                    if (((accepted_writes[0] == 1'b0)
                            && (gmem_req_wstrb_o != 8'h0f))
                            || ((accepted_writes[0] == 1'b1)
                                && (gmem_req_wstrb_o != 8'hf0)))
                        fail_case("destination F32 strobe");
                    accepted_writes <= accepted_writes + 1;
                end else begin
                    if ((gmem_req_wdata_o != 64'b0)
                            || (gmem_req_wstrb_o != 8'b0))
                        fail_case("read carried write payload");
                    accepted_reads <= accepted_reads + 1;
                end
            end

            if (pending_q && !gmem_rsp_valid_i) begin
                if (pending_delay_q == 0) begin
                    gmem_rsp_valid_i <= 1'b1;
                    gmem_rsp_error_i <= pending_error_q;
                    gmem_rsp_rdata_i <= pending_write_q
                                      ? 64'b0 : memory_read64(pending_addr_q);
                end else begin
                    pending_delay_q <= pending_delay_q - 1;
                end
            end
            if (gmem_rsp_valid_i && gmem_rsp_ready_o) begin
                if (!pending_q)
                    fail_case("response without accepted owner");
                if (pending_write_q && !gmem_rsp_error_i) begin
                    for (lane = 0; lane < 8; lane = lane + 1)
                        if (pending_wstrb_q[lane])
                            gmem[pending_addr_q + lane]
                                <= pending_wdata_q[(lane * 8) +: 8];
                    successful_writes <= successful_writes + 1;
                end
                response_count <= response_count + 1;
                pending_q <= 1'b0;
                pending_write_q <= 1'b0;
                pending_error_q <= 1'b0;
                gmem_rsp_valid_i <= 1'b0;
                gmem_rsp_error_i <= 1'b0;
                gmem_rsp_rdata_i <= 64'b0;
            end
        end
    end
    /* verilator lint_on BLKSEQ */

    task automatic set_valid_descriptor(input integer profile);
        begin
            active_profile_q = profile;
            start_i = 1'b0;
            manifest_op_id_i = MANIFEST_MUL_MAT;
            source_arity_i = 3'd2;
            op_params_i = (profile == 0) ? 128'd10 : 128'b0;
            op_params_tail_zero_i = 1'b1;
            npu_required_i = 1'b1;
            command_id_i = 64'h1357_9bdf_2468_ace0 + 64'(profile);
            canonical_node_id_lo_i = 64'h0123_4567_89ab_cdef
                                   + 64'(profile);
            canonical_node_id_hi_i = 64'hfedc_ba98_7654_3210
                                   - 64'(profile);
            dst_shadow_private_i = 1'b1;
            windows_generation_valid_i = 1'b1;
            src0_dtype_i = 8'd1;
            src0_flags_i = 32'd16;
            src0_view_off_i = 64'b0;
            src0_ne0_i = 32'd256;
            src0_ne1_i = 32'd256;
            src0_ne2_i = 32'd2;
            src0_ne3_i = 32'd1;
            src0_base_i = SRC0_BASE;
            src0_nb0_i = 64'd2;
            src0_nb1_i = (profile == 0) ? 64'd1024 : 64'd512;
            src0_nb2_i = (profile == 0) ? 64'd512 : 64'd131072;
            src0_nb3_i = 64'd262144;
            src1_dtype_i = 8'd0;
            src1_flags_i = 32'd16;
            src1_view_off_i = 64'b0;
            src1_ne0_i = 32'd256;
            src1_ne1_i = 32'd1;
            src1_ne2_i = 32'd8;
            src1_ne3_i = 32'd1;
            src1_base_i = SRC1_BASE;
            src1_nb0_i = 64'd4;
            src1_nb1_i = (profile == 0) ? 64'd8192 : 64'd1024;
            src1_nb2_i = 64'd1024;
            src1_nb3_i = 64'd8192;
            dst_dtype_i = 8'd0;
            dst_flags_i = 32'd16;
            dst_view_off_i = 64'b0;
            dst_ne0_i = 32'd256;
            dst_ne1_i = 32'd1;
            dst_ne2_i = 32'd8;
            dst_ne3_i = 32'd1;
            dst_base_i = DST_BASE;
            dst_nb0_i = 64'd4;
            dst_nb1_i = 64'd1024;
            dst_nb2_i = 64'd1024;
            dst_nb3_i = 64'd8192;
            src0_window_base_i = SRC0_BASE;
            src0_window_bytes_i = 64'(SRC0_BYTES);
            src0_window_read_i = 1'b1;
            src0_window_write_i = 1'b0;
            src1_window_base_i = SRC1_BASE;
            src1_window_bytes_i = 64'(SRC1_BYTES);
            src1_window_read_i = 1'b1;
            src1_window_write_i = 1'b0;
            dst_window_base_i = DST_BASE;
            dst_window_bytes_i = 64'(DST_BYTES);
            dst_window_read_i = 1'b0;
            dst_window_write_i = 1'b1;
        end
    endtask

    task automatic set_bus_defaults;
        begin
            allow_requests_q = 1'b1;
            request_backpressure_q = 1'b0;
            check_order_q = 1'b1;
            normal_response_delay_q = 0;
            inject_read_error_ordinal_q = -1;
            inject_write_error_ordinal_q = -1;
            late_response_ordinal_q = -1;
            late_response_delay_q = 0;
        end
    endtask

    task automatic pulse_reset;
        begin
            start_i = 1'b0;
            probe_req_valid_q = 1'b0;
            probe_rsp_ready_q = 1'b0;
            rst_i = 1'b1;
            repeat (3) @(posedge clk_i);
            @(negedge clk_i);
            rst_i = 1'b0;
            repeat (2) @(negedge clk_i);
            if (!ready_o || busy_o || completion_valid_o
                    || gmem_outstanding_o || numeric_outstanding_o)
                fail_case("reset quiescence");
        end
    endtask

    task automatic pulse_start;
        begin
            while (!ready_o)
                @(negedge clk_i);
            start_i = 1'b1;
            @(posedge clk_i);
            @(negedge clk_i);
            start_i = 1'b0;
        end
    endtask

    task automatic wait_terminal(input integer limit, input string label);
        integer cycles;
        begin
            cycles = 0;
            while (!completion_valid_o && (cycles < limit)) begin
                @(negedge clk_i);
                cycles = cycles + 1;
            end
            if (!completion_valid_o)
                fail_case($sformatf("%s terminal timeout", label));
            if (done_o == error_o)
                fail_case($sformatf("%s terminal polarity", label));
            if (gmem_outstanding_o || numeric_outstanding_o)
                fail_case($sformatf("%s terminal retained owner", label));
        end
    endtask

    task automatic check_identity(
        input logic [63:0] expected_command,
        input logic [63:0] expected_lo,
        input logic [63:0] expected_hi,
        input logic [7:0] expected_profile,
        input logic [31:0] expected_operator_census,
        input logic [31:0] expected_profile_census
    );
        begin
            if ((completion_command_id_o !== expected_command)
                    || (completion_canonical_node_id_lo_o !== expected_lo)
                    || (completion_canonical_node_id_hi_o !== expected_hi)
                    || !completion_npu_required_o
                    || (completion_manifest_op_id_o !== MANIFEST_MUL_MAT)
                    || (completion_source_arity_o !== 3'd2)
                    || (completion_profile_id_o !== expected_profile)
                    || (completion_kernel_id_o !== KERNEL_F16_ATTENTION)
                    || (completion_operator_census_o
                        !== expected_operator_census)
                    || (completion_profile_census_o
                        !== expected_profile_census))
                fail_case("resident identity/census");
        end
    endtask

    task automatic finish_terminal(input string label);
        begin
            @(negedge clk_i);
            if (completion_valid_o || done_o || error_o || !ready_o)
                fail_case($sformatf("%s terminal width", label));
        end
    endtask

    task automatic run_static_reject(
        input logic [4:0] expected_error,
        input string label
    );
        integer before_requests;
        begin
            before_requests = accepted_requests;
            pulse_start();
            wait_terminal(32, label);
            if (!error_o || done_o || dst_commit_o
                    || (error_code_o != expected_error)
                    || (accepted_requests != before_requests)
                    || (gmem_read_requests_o != 64'b0)
                    || (gmem_write_requests_o != 64'b0)
                    || (fma_requests_o != 64'b0)
                    || (reduction_requests_o != 64'b0))
                fail_case($sformatf("%s static zero-traffic", label));
            finish_terminal(label);
        end
    endtask

    task automatic put_word(input integer address, input logic [31:0] raw);
        begin
            gmem[address] = raw[7:0];
            gmem[address + 1] = raw[15:8];
            gmem[address + 2] = raw[23:16];
            gmem[address + 3] = raw[31:24];
        end
    endtask

    task automatic put_half(input integer address, input logic [15:0] raw);
        begin
            gmem[address] = raw[7:0];
            gmem[address + 1] = raw[15:8];
        end
    endtask

    function automatic [31:0] get_word(input integer address);
        begin
            get_word = {gmem[address + 3], gmem[address + 2],
                        gmem[address + 1], gmem[address]};
        end
    endfunction

    task automatic set_src0_half(
        input integer profile,
        input integer source_head,
        input integer row,
        input integer element,
        input logic [15:0] raw
    );
        begin
            put_half(SRC0_BASE + src0_address(profile, source_head,
                                              row, element), raw);
        end
    endtask

    task automatic set_src1_word(
        input integer head,
        input integer element,
        input logic [31:0] raw
    );
        begin
            put_word(SRC1_BASE + head * 1024 + element * 4, raw);
        end
    endtask

    task automatic prepare_vectors(input integer profile);
        integer address;
        integer head;
        integer source_head;
        integer row;
        integer mode;
        begin
            for (address = 0; address < SRC0_BYTES; address = address + 1)
                gmem[SRC0_BASE + address] = 8'h00;
            for (address = 0; address < SRC1_BYTES; address = address + 1)
                gmem[SRC1_BASE + address] = 8'h00;
            for (address = 0; address < DST_BYTES; address = address + 1) begin
                gmem[DST_BASE + address] = 8'hc3;
                gmem[ACTIVE_ROOT_BASE + address] = 8'ha5;
            end

            for (head = 0; head < HEADS; head = head + 1) begin
                set_src1_word(head, 0, 32'h3f80_1000);
                set_src1_word(head, 1, 32'h3f80_3000);
                set_src1_word(head, 2, 32'h4400_0000);
                set_src1_word(head, 34, 32'h3f80_0000);
                set_src1_word(head, 66, 32'h4400_0000);
                set_src1_word(head, 98, 32'h3f80_0000);
                set_src1_word(head, 128, 32'h4400_0000);
                set_src1_word(head, 136, 32'h3f80_0000);
                set_src1_word(head, 144, 32'h4400_0000);
                set_src1_word(head, 152, 32'h3f80_0000);
                set_src1_word(head, 160, 32'h4400_0000);
                set_src1_word(head, 161, 32'h3f80_0000);
                set_src1_word(head, 162, 32'h4400_0000);
                set_src1_word(head, 163, 32'h3f80_0000);
                set_src1_word(head, 250, 32'h3380_0000);
                set_src1_word(head, 251, 32'h3f80_0000);
                set_src1_word(head, 254, 32'h3f80_0000);
                set_src1_word(head, 255, 32'h3f80_0000);
            end

            for (source_head = 0; source_head < 2;
                    source_head = source_head + 1) begin
                for (row = 0; row < ROWS; row = row + 1) begin
                    mode = row & 7;
                    case (mode)
                        0: set_src0_half(profile, source_head, row, 254,
                                         16'h8000);
                        1: set_src0_half(profile, source_head, row, 0,
                                         16'h3c00);
                        2: set_src0_half(profile, source_head, row, 1,
                                         16'h3c00);
                        3: begin
                            set_src0_half(profile, source_head, row, 2,
                                         16'h7800);
                            set_src0_half(profile, source_head, row, 34,
                                         16'h3c00);
                            set_src0_half(profile, source_head, row, 66,
                                         16'hf800);
                            set_src0_half(profile, source_head, row, 98,
                                         16'h3c00);
                        end
                        4: begin
                            set_src0_half(profile, source_head, row, 128,
                                         16'h7800);
                            set_src0_half(profile, source_head, row, 136,
                                         16'h3c00);
                            set_src0_half(profile, source_head, row, 144,
                                         16'hf800);
                            set_src0_half(profile, source_head, row, 152,
                                         16'h3c00);
                        end
                        5: begin
                            set_src0_half(profile, source_head, row, 160,
                                         16'h7800);
                            set_src0_half(profile, source_head, row, 161,
                                         16'h3c00);
                            set_src0_half(profile, source_head, row, 162,
                                         16'hf800);
                            set_src0_half(profile, source_head, row, 163,
                                         16'h3c00);
                        end
                        6: begin
                            set_src0_half(profile, source_head, row, 250,
                                         16'h3c00);
                            set_src0_half(profile, source_head, row, 251,
                                         16'h0001);
                        end
                        default: set_src0_half(
                            profile, source_head, row, 255,
                            (source_head == 0) ? 16'h3c00 : 16'h4000);
                    endcase
                end
            end
        end
    endtask

    task automatic check_active_root(input string label);
        integer address;
        begin
            for (address = 0; address < DST_BYTES; address = address + 1)
                if (gmem[ACTIVE_ROOT_BASE + address] !== 8'ha5)
                    fail_case($sformatf("%s active-root canary", label));
        end
    endtask

    task automatic run_fma_probe;
        integer wait_cycles;
        integer hold_cycles;
        begin
            pulse_reset();
            probe_a_q = 32'h3f80_0001;
            probe_b_q = 32'h3f7f_ffff;
            probe_c_q = 32'hbf80_0000;
            probe_rsp_ready_q = 1'b0;
            while (!probe_req_ready_w)
                @(negedge clk_i);
            probe_req_valid_q = 1'b1;
            @(posedge clk_i);
            @(negedge clk_i);
            probe_req_valid_q = 1'b0;
            wait_cycles = 0;
            while (!probe_rsp_valid_w && (wait_cycles < 32)) begin
                @(negedge clk_i);
                wait_cycles = wait_cycles + 1;
            end
            if (!probe_rsp_valid_w || probe_req_ready_w
                    || (probe_result_w != 32'h337f_fffe)
                    || (probe_flags_w != 5'b0))
                fail_case("public FMA fused result/cardinality");
            for (hold_cycles = 0; hold_cycles < 4;
                    hold_cycles = hold_cycles + 1) begin
                @(negedge clk_i);
                if (!probe_rsp_valid_w
                        || (probe_result_w != 32'h337f_fffe)
                        || (probe_flags_w != 5'b0))
                    fail_case("public FMA held response");
            end
            probe_rsp_ready_q = 1'b1;
            @(posedge clk_i);
            @(negedge clk_i);
            probe_rsp_ready_q = 1'b0;
            if (probe_rsp_valid_w || !probe_req_ready_w)
                fail_case("public FMA response retirement");
            repeat (6) @(negedge clk_i);
            if (probe_rsp_valid_w)
                fail_case("public FMA duplicate response");
            $display("[NPU-F16-ATTENTION][FMA] fused=337ffffe split-result-would-be-zero hold=4 cardinality=1");
        end
    endtask

    task automatic run_reset_abort;
        integer cycles;
        begin
            pulse_reset();
            set_valid_descriptor(0);
            set_bus_defaults();
            prepare_vectors(0);
            normal_response_delay_q = 40;
            pulse_start();
            cycles = 0;
            while ((accepted_requests == 0) && (cycles < 64)) begin
                @(negedge clk_i);
                cycles = cycles + 1;
            end
            if ((accepted_requests != 1) || !gmem_outstanding_o)
                fail_case("reset fixture owner");
            rst_i = 1'b1;
            repeat (3) @(posedge clk_i);
            if (completion_valid_o || dst_commit_o)
                fail_case("reset emitted completion");
            @(negedge clk_i);
            rst_i = 1'b0;
            repeat (2) @(negedge clk_i);
            if (!ready_o || busy_o || gmem_outstanding_o
                    || numeric_outstanding_o || (accepted_requests != 0)
                    || (completion_count != 0) || (commit_count != 0))
                fail_case("reset cleanup");
        end
    endtask

    task automatic run_late_read_error;
        begin
            pulse_reset();
            set_valid_descriptor(0);
            set_bus_defaults();
            prepare_vectors(0);
            inject_read_error_ordinal_q = 128;
            pulse_start();
            wait_terminal(4096, "late src0 read error");
            if (!error_o || dst_commit_o || (error_code_o != ERR_GMEM)
                    || (gmem_read_requests_o != 64'd129)
                    || (gmem_read_responses_o != 64'd129)
                    || (read_payload_bytes_o != 64'd1024)
                    || (source0_half_words_completed_o != 64'b0)
                    || (source1_float_words_completed_o != 64'd256)
                    || (conversion_words_completed_o != 64'd256)
                    || (fma_requests_o != 64'b0)
                    || (gmem_write_requests_o != 64'b0)
                    || (commit_count != 0))
                fail_case("late read fault accounting");
            check_identity(command_id_i, canonical_node_id_lo_i,
                           canonical_node_id_hi_i, PROFILE_KQ, 32'd12, 32'd6);
            check_active_root("late src0 read error");
            finish_terminal("late src0 read error");
        end
    endtask

    task automatic run_timeout_drain;
        begin
            pulse_reset();
            set_valid_descriptor(0);
            set_bus_defaults();
            prepare_vectors(0);
            late_response_ordinal_q = 0;
            late_response_delay_q = STALL_TIMEOUT + 8;
            pulse_start();
            wait_terminal(512, "accepted timeout drain");
            if (!error_o || dst_commit_o || (error_code_o != ERR_STALL)
                    || (drain_seen_count == 0)
                    || (gmem_read_requests_o != 64'd1)
                    || (gmem_read_responses_o != 64'd1)
                    || (read_payload_bytes_o != 64'b0)
                    || (source1_float_words_completed_o != 64'b0)
                    || (commit_count != 0))
                fail_case("accepted timeout drain accounting");
            check_identity(command_id_i, canonical_node_id_lo_i,
                           canonical_node_id_hi_i, PROFILE_KQ, 32'd12, 32'd6);
            finish_terminal("accepted timeout drain");
        end
    endtask

    task automatic run_late_write_error;
        begin
            pulse_reset();
            set_valid_descriptor(0);
            set_bus_defaults();
            prepare_vectors(0);
            inject_write_error_ordinal_q = 1;
            pulse_start();
            wait_terminal(20000, "late write error");
            if (!error_o || dst_commit_o || (error_code_o != ERR_GMEM)
                    || (outputs_computed_o != 64'd2)
                    || (outputs_completed_o != 64'd1)
                    || (source0_half_words_completed_o != 64'd512)
                    || (source1_float_words_completed_o != 64'd256)
                    || (conversion_words_completed_o != 64'd256)
                    || (gmem_read_requests_o != 64'd256)
                    || (gmem_read_responses_o != 64'd256)
                    || (read_payload_bytes_o != 64'd2048)
                    || (fma_requests_o != 64'd512)
                    || (fma_responses_o != 64'd512)
                    || (reduction_requests_o != 64'd72)
                    || (reduction_responses_o != 64'd72)
                    || (gmem_write_requests_o != 64'd2)
                    || (gmem_write_responses_o != 64'd2)
                    || (write_payload_bytes_o != 64'd4)
                    || (commit_count != 0))
                fail_case("late write fault accounting");
            if ((get_word(DST_BASE) !== expected_raw(0, 0))
                    || (get_word(DST_BASE + 4) !== 32'hc3c3_c3c3))
                fail_case("private write prefix");
            check_identity(command_id_i, canonical_node_id_lo_i,
                           canonical_node_id_hi_i, PROFILE_KQ, 32'd12, 32'd6);
            check_active_root("late write error");
            finish_terminal("late write error");
        end
    endtask

    task automatic run_full_profile(input integer profile);
        integer head;
        integer row;
        integer cycles;
        reg busy_start_sent;
        reg [63:0] expected_command, expected_lo, expected_hi;
        begin
            pulse_reset();
            set_valid_descriptor(profile);
            set_bus_defaults();
            request_backpressure_q = 1'b1;
            prepare_vectors(profile);
            expected_command = command_id_i;
            expected_lo = canonical_node_id_lo_i;
            expected_hi = canonical_node_id_hi_i;
            pulse_start();
            cycles = 0;
            busy_start_sent = 1'b0;
            while (!completion_valid_o && (cycles < 6000000)) begin
                @(negedge clk_i);
                cycles = cycles + 1;
                if (!busy_start_sent && (accepted_reads >= 132)) begin
                    if (ready_o || !busy_o)
                        fail_case("busy identity fixture");
                    command_id_i = 64'hffff_eeee_dddd_cccc;
                    canonical_node_id_lo_i = 64'hbbbb_aaaa_9999_8888;
                    canonical_node_id_hi_i = 64'h7777_6666_5555_4444;
                    manifest_op_id_i = 16'd28;
                    start_i = 1'b1;
                    @(posedge clk_i);
                    @(negedge clk_i);
                    start_i = 1'b0;
                    busy_start_sent = 1'b1;
                end
            end
            if (!completion_valid_o)
                fail_case("full profile timeout");
            if (!done_o || error_o || !dst_commit_o || poisoned_o)
                fail_case("full profile terminal/commit");
            check_identity(expected_command, expected_lo, expected_hi,
                           profile == 0 ? PROFILE_KQ : PROFILE_KQV,
                           32'd12, 32'd6);
            for (head = 0; head < HEADS; head = head + 1)
                for (row = 0; row < ROWS; row = row + 1)
                    if (get_word(DST_BASE + head * 1024 + row * 4)
                            !== expected_raw(head, row))
                        fail_case($sformatf(
                            "raw oracle p=%0d head=%0d row=%0d actual=%08x expected=%08x",
                            profile, head, row,
                            get_word(DST_BASE + head * 1024 + row * 4),
                            expected_raw(head, row)));
            if ((outputs_computed_o != 64'(OUTPUTS))
                    || (outputs_completed_o != 64'(OUTPUTS))
                    || (source0_half_words_completed_o != 64'(MACS))
                    || (source1_float_words_completed_o != 64'd2048)
                    || (conversion_words_completed_o != 64'd2048)
                    || (work_items_completed_o != 64'(MACS))
                    || (gmem_read_requests_o != 64'(READ_BEATS))
                    || (gmem_read_responses_o != 64'(READ_BEATS))
                    || (read_payload_bytes_o != 64'(READ_BYTES))
                    || (gmem_write_requests_o != 64'(OUTPUTS))
                    || (gmem_write_responses_o != 64'(OUTPUTS))
                    || (write_payload_bytes_o != 64'(DST_BYTES))
                    || (fma_requests_o != 64'(MACS))
                    || (fma_responses_o != 64'(MACS))
                    || (reduction_requests_o != 64'(REDUCTIONS))
                    || (reduction_responses_o != 64'(REDUCTIONS))
                    || (numeric_flags_o != 5'h01)
                    || (conversion_flags_o != 3'b001)
                    || (active_cycles_o == 64'b0))
                fail_case("full exact counters/flags");
            if ((accepted_reads != READ_BEATS)
                    || (accepted_writes != OUTPUTS)
                    || (response_count != (READ_BEATS + OUTPUTS))
                    || (successful_writes != OUTPUTS)
                    || (held_stability_cycles == 0) || !busy_start_sent)
                fail_case("full independent transport/backpressure");
            check_active_root("full profile");
            $display("[NPU-F16-ATTENTION][FULL] profile=%0d outputs=%0d reads=%0d/%0dB writes=%0d/%0dB fma=%0d reduction=%0d flags=%02x/%01x held=%0d cycles=%0d",
                     profile, outputs_completed_o, gmem_read_requests_o,
                     read_payload_bytes_o, gmem_write_requests_o,
                     write_payload_bytes_o, fma_responses_o,
                     reduction_responses_o, numeric_flags_o,
                     conversion_flags_o, held_stability_cycles,
                     active_cycles_o);
            finish_terminal("full profile");
            if ((completion_count != 1) || (commit_count != 1))
                fail_case("full completion/commit pulses");
        end
    endtask

    initial begin
        integer address;
        rst_i = 1'b1;
        start_i = 1'b0;
        probe_req_valid_q = 1'b0;
        probe_rsp_ready_q = 1'b0;
        probe_a_q = 32'b0;
        probe_b_q = 32'b0;
        probe_c_q = 32'b0;
        set_valid_descriptor(0);
        set_bus_defaults();
        gmem_rsp_valid_i = 1'b0;
        gmem_rsp_rdata_i = 64'b0;
        gmem_rsp_error_i = 1'b0;
        for (address = 0; address < MEM_BYTES; address = address + 1)
            gmem[address] = 8'h00;
        repeat (3) @(posedge clk_i);
        @(negedge clk_i);
        rst_i = 1'b0;
        repeat (2) @(negedge clk_i);

        run_fma_probe();

        set_valid_descriptor(0); manifest_op_id_i = 16'd28;
        run_static_reject(ERR_DESCRIPTOR, "op id");
        set_valid_descriptor(0); source_arity_i = 3'd1;
        run_static_reject(ERR_DESCRIPTOR, "arity");
        set_valid_descriptor(0); op_params_tail_zero_i = 1'b0;
        run_static_reject(ERR_DESCRIPTOR, "op params tail");
        set_valid_descriptor(0); npu_required_i = 1'b0;
        run_static_reject(ERR_DESCRIPTOR, "required");
        set_valid_descriptor(0); dst_shadow_private_i = 1'b0;
        run_static_reject(ERR_DESCRIPTOR, "private destination");
        set_valid_descriptor(0); src0_dtype_i = 8'd0;
        run_static_reject(ERR_DESCRIPTOR, "src0 dtype");
        set_valid_descriptor(0); src1_flags_i = 32'd0;
        run_static_reject(ERR_DESCRIPTOR, "src1 flags");
        set_valid_descriptor(0); dst_ne0_i = 32'd255;
        run_static_reject(ERR_DESCRIPTOR, "destination shape");
        set_valid_descriptor(0); src0_nb1_i = 64'd512;
        run_static_reject(ERR_DESCRIPTOR, "mixed profile stride");
        set_valid_descriptor(1); op_params_i = 128'd10;
        run_static_reject(ERR_DESCRIPTOR, "profile op params");
        set_valid_descriptor(0); src0_window_read_i = 1'b0;
        run_static_reject(ERR_SRC0, "src0 capability");
        set_valid_descriptor(0); src0_base_i = 64'hffff_ffff_ffff_fff8;
        src0_window_base_i = 64'hffff_ffff_ffff_fff8;
        src0_window_bytes_i = 64'd8;
        run_static_reject(ERR_SRC0, "src0 overflow");
        set_valid_descriptor(0); src1_window_write_i = 1'b1;
        run_static_reject(ERR_SRC1, "src1 capability");
        set_valid_descriptor(0); dst_window_write_i = 1'b0;
        run_static_reject(ERR_DST, "dst capability");
        set_valid_descriptor(0); dst_base_i = 64'hffff_ffff_ffff_fffc;
        dst_window_base_i = 64'hffff_ffff_ffff_fff8;
        dst_window_bytes_i = 64'd8;
        run_static_reject(ERR_DST, "dst overflow");
        set_valid_descriptor(0); src1_base_i = SRC0_BASE;
        src1_window_base_i = SRC0_BASE;
        run_static_reject(ERR_ALIAS, "source physical alias");
        set_valid_descriptor(0); dst_base_i = 64'd4;
        dst_window_base_i = SRC0_BASE;
        dst_window_bytes_i = 64'(SRC0_BYTES);
        run_static_reject(ERR_ALIAS, "destination physical alias");
        $display("[NPU-F16-ATTENTION][STATIC] exact rejects=17 zero-traffic");

        run_reset_abort();
        run_late_read_error();
        run_timeout_drain();
        run_late_write_error();
        run_full_profile(0);
        run_full_profile(1);

        $display("[NPU-F16-ATTENTION][PASS] frozen_nodes=12 profiles=2 outputs_each=2048 raw_modes=8 static=17 fma_probe=1 reset=1 late_read=1 timeout_drain=1 late_write=1 backpressure=2 busy=2");
        $finish;
    end

endmodule

`default_nettype wire
