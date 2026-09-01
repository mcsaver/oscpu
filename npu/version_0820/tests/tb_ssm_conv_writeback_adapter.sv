`timescale 1ns/1ps
`default_nettype none

// Full frozen-v5 SSM_CONV transaction test.  Every numerical expected value
// below is a literal IEEE-754 raw word; address/census bookkeeping is integer
// only and no foreign numerical reference path is used.
module tb_ssm_conv_writeback_adapter;

    localparam integer CHANNELS = 6144;
    localparam integer TAPS = 4;
    localparam integer SOURCE_BYTES = 98304;
    localparam integer DEST_BYTES = 24576;
    localparam integer READ_BEATS = 24576;
    localparam integer WORK_ITEMS = 24576;
    localparam integer MEM_BYTES = 393216;
    localparam integer STALL_TIMEOUT = 24;

    localparam logic [63:0] SRC0_BASE = 64'h0000_0000_0000_0000;
    localparam logic [63:0] SRC1_BASE = 64'h0000_0000_0002_0000;
    localparam logic [63:0] DST_BASE = 64'h0000_0000_0004_0000;
    localparam logic [63:0] ACTIVE_ROOT_BASE = 64'h0000_0000_0005_0000;
    localparam logic [31:0] KERNEL_SSM_CONV = 32'h514e0022;
    localparam logic [15:0] MANIFEST_SSM_CONV = 16'd76;
    localparam logic [7:0] PROFILE_SSM_CONV = 8'd0;

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
    wire poisoned_o;
    wire [63:0] outputs_computed_o, outputs_completed_o;
    wire [63:0] source0_words_completed_o, source1_words_completed_o;
    wire [63:0] work_items_completed_o;
    wire [63:0] gmem_read_requests_o, gmem_read_responses_o;
    wire [63:0] read_payload_bytes_o;
    wire [63:0] gmem_write_requests_o, gmem_write_responses_o;
    wire [63:0] write_payload_bytes_o;
    wire [63:0] mul_requests_o, mul_responses_o;
    wire [63:0] add_requests_o, add_responses_o, active_cycles_o;
    wire gmem_outstanding_o, numeric_outstanding_o, gmem_drain_o;

    TensorNpuSsmConvWritebackAdapter #(
        .STALL_TIMEOUT_CYCLES(STALL_TIMEOUT),
        .COMMAND_TIMEOUT_CYCLES(64'd3000000),
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
        .numeric_flags_o(numeric_flags_o), .poisoned_o(poisoned_o),
        .outputs_computed_o(outputs_computed_o),
        .outputs_completed_o(outputs_completed_o),
        .source0_words_completed_o(source0_words_completed_o),
        .source1_words_completed_o(source1_words_completed_o),
        .work_items_completed_o(work_items_completed_o),
        .gmem_read_requests_o(gmem_read_requests_o),
        .gmem_read_responses_o(gmem_read_responses_o),
        .read_payload_bytes_o(read_payload_bytes_o),
        .gmem_write_requests_o(gmem_write_requests_o),
        .gmem_write_responses_o(gmem_write_responses_o),
        .write_payload_bytes_o(write_payload_bytes_o),
        .mul_requests_o(mul_requests_o), .mul_responses_o(mul_responses_o),
        .add_requests_o(add_requests_o), .add_responses_o(add_responses_o),
        .active_cycles_o(active_cycles_o),
        .gmem_outstanding_o(gmem_outstanding_o),
        .numeric_outstanding_o(numeric_outstanding_o),
        .gmem_drain_o(gmem_drain_o)
    );

    initial clk_i = 1'b0;
    always #5 clk_i <= ~clk_i;

    reg [7:0] gmem [0:MEM_BYTES-1];
    logic [31:0] expected_result [0:CHANNELS-1];
    reg allow_requests_q, request_backpressure_q, check_order_q;
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
    integer lane;

    assign gmem_req_ready_i = !rst_i && allow_requests_q && !pending_q
                            && !gmem_rsp_valid_i
                            // In backpressure mode, every newly presented
                            // request is held for one full cycle.  The monitor
                            // records that held request and enables its accept
                            // on the following cycle, independent of phase.
                            && (!request_backpressure_q || request_hold_q);

    task automatic fail_case(input string reason);
        begin
            $display("[NPU-SSM-CONV-WRITEBACK][FAIL] %s cycle=%0d busy=%0b done=%0b error=%0b err=%0d req=%0d/%0d rsp=%0d commit=%0d",
                     reason, global_cycles, busy_o, done_o, error_o,
                     error_code_o, accepted_reads, accepted_writes,
                     response_count, commit_count);
            $display("[NPU-SSM-CONV-WRITEBACK][EVIDENCE] out=%0d/%0d src=%0d/%0d work=%0d read=%0d/%0d/%0dB write=%0d/%0d/%0dB mul=%0d/%0d add=%0d/%0d flags=%02x owner=%0b/%0b drain=%0b",
                     outputs_computed_o, outputs_completed_o,
                     source0_words_completed_o, source1_words_completed_o,
                     work_items_completed_o, gmem_read_requests_o,
                     gmem_read_responses_o, read_payload_bytes_o,
                     gmem_write_requests_o, gmem_write_responses_o,
                     write_payload_bytes_o, mul_requests_o, mul_responses_o,
                     add_requests_o, add_responses_o, numeric_flags_o,
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

    /* verilator lint_off BLKSEQ */
    always @(posedge clk_i) begin
        integer read_group;
        integer read_channel;
        integer read_step;
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
                if (gmem_req_write_o) begin
                    if (check_order_q
                            && (gmem_req_addr_o
                                != ((DST_BASE
                                     + (64'(accepted_writes) * 64'd4))
                                    & 64'hffff_ffff_ffff_fff8)))
                        fail_case("destination write order");
                    if (((accepted_writes[0] == 1'b0)
                            && (gmem_req_wstrb_o != 8'h0f))
                            || ((accepted_writes[0] == 1'b1)
                                && (gmem_req_wstrb_o != 8'hf0)))
                        fail_case("destination F32 strobe");
                    accepted_writes <= accepted_writes + 1;
                end else begin
                    read_channel = accepted_reads / 4;
                    read_step = accepted_reads % 4;
                    read_group = (read_step < 2) ? 0 : 1;
                    if (check_order_q
                            && (gmem_req_addr_o
                                != ((read_group == 0 ? SRC0_BASE : SRC1_BASE)
                                    + (64'(read_channel) * 64'd16)
                                    + (64'(read_step & 1) * 64'd8))))
                        fail_case("source read order");
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

    task automatic set_valid_descriptor;
        begin
            start_i = 1'b0;
            manifest_op_id_i = MANIFEST_SSM_CONV;
            source_arity_i = 3'd2;
            op_params_i = 128'b0;
            op_params_tail_zero_i = 1'b1;
            npu_required_i = 1'b1;
            command_id_i = 64'h0123_4567_89ab_cdef;
            canonical_node_id_lo_i = 64'h89ab_cdef_0123_4567;
            canonical_node_id_hi_i = 64'h7654_3210_fedc_ba98;
            dst_shadow_private_i = 1'b1;
            windows_generation_valid_i = 1'b1;
            src0_dtype_i = 8'd0;
            src0_flags_i = 32'd16;
            src0_view_off_i = 64'b0;
            src0_ne0_i = 32'd4;
            src0_ne1_i = 32'd6144;
            src0_ne2_i = 32'd1;
            src0_ne3_i = 32'd1;
            src0_base_i = SRC0_BASE;
            src0_nb0_i = 64'd4;
            src0_nb1_i = 64'd16;
            src0_nb2_i = 64'd98304;
            src0_nb3_i = 64'd98304;
            src1_dtype_i = 8'd0;
            src1_flags_i = 32'd0;
            src1_view_off_i = 64'b0;
            src1_ne0_i = 32'd4;
            src1_ne1_i = 32'd6144;
            src1_ne2_i = 32'd1;
            src1_ne3_i = 32'd1;
            src1_base_i = SRC1_BASE;
            src1_nb0_i = 64'd4;
            src1_nb1_i = 64'd16;
            src1_nb2_i = 64'd98304;
            src1_nb3_i = 64'd98304;
            dst_dtype_i = 8'd0;
            dst_flags_i = 32'd16;
            dst_view_off_i = 64'b0;
            dst_ne0_i = 32'd6144;
            dst_ne1_i = 32'd1;
            dst_ne2_i = 32'd1;
            dst_ne3_i = 32'd1;
            dst_base_i = DST_BASE;
            dst_nb0_i = 64'd4;
            dst_nb1_i = 64'd24576;
            dst_nb2_i = 64'd24576;
            dst_nb3_i = 64'd24576;
            src0_window_base_i = SRC0_BASE;
            src0_window_bytes_i = 64'(SOURCE_BYTES);
            src0_window_read_i = 1'b1;
            src0_window_write_i = 1'b0;
            src1_window_base_i = SRC1_BASE;
            src1_window_bytes_i = 64'(SOURCE_BYTES);
            src1_window_read_i = 1'b1;
            src1_window_write_i = 1'b0;
            dst_window_base_i = DST_BASE;
            dst_window_bytes_i = 64'(DEST_BYTES);
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
        input logic [31:0] expected_census
    );
        begin
            if ((completion_command_id_o !== expected_command)
                    || (completion_canonical_node_id_lo_o !== expected_lo)
                    || (completion_canonical_node_id_hi_o !== expected_hi)
                    || !completion_npu_required_o
                    || (completion_manifest_op_id_o !== MANIFEST_SSM_CONV)
                    || (completion_source_arity_o !== 3'd2)
                    || (completion_profile_id_o !== expected_profile)
                    || (completion_kernel_id_o !== KERNEL_SSM_CONV)
                    || (completion_operator_census_o !== expected_census)
                    || (completion_profile_census_o !== expected_census))
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
                    || (mul_requests_o != 64'b0)
                    || (add_requests_o != 64'b0))
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

    function automatic [31:0] get_word(input integer address);
        begin
            get_word = {gmem[address + 3], gmem[address + 2],
                        gmem[address + 1], gmem[address]};
        end
    endfunction

    task automatic set_channel_word(
        input integer channel,
        input integer tap,
        input logic [31:0] src0_raw,
        input logic [31:0] src1_raw
    );
        begin
            put_word(SRC0_BASE + (channel * 16) + (tap * 4), src0_raw);
            put_word(SRC1_BASE + (channel * 16) + (tap * 4), src1_raw);
        end
    endtask

    task automatic prepare_vectors;
        integer channel;
        integer tap;
        integer mode;
        integer address;
        begin
            for (address = 0; address < SOURCE_BYTES; address = address + 1) begin
                gmem[SRC0_BASE + address] = 8'h00;
                gmem[SRC1_BASE + address] = 8'h00;
            end
            for (address = 0; address < DEST_BYTES; address = address + 1) begin
                gmem[DST_BASE + address] = 8'hc3;
                gmem[ACTIVE_ROOT_BASE + address] = 8'ha5;
            end
            for (channel = 0; channel < CHANNELS; channel = channel + 1) begin
                for (tap = 0; tap < TAPS; tap = tap + 1)
                    set_channel_word(channel, tap, 32'h0000_0000,
                                    32'h3f80_0000);
                mode = channel % 14;
                expected_result[channel] = 32'h0000_0000;
                case (mode)
                    0: begin
                        expected_result[channel] = 32'h0000_0000;
                    end
                    1: begin
                        set_channel_word(channel, 0, 32'h3fc0_0000,
                                        32'h3f80_0000);
                        expected_result[channel] = 32'h3fc0_0000;
                    end
                    2: begin
                        set_channel_word(channel, 0, 32'h8000_0000,
                                        32'h3f80_0000);
                        expected_result[channel] = 32'h0000_0000;
                    end
                    3: begin
                        set_channel_word(channel, 0, 32'h3f80_0000,
                                        32'h3f80_0000);
                        set_channel_word(channel, 1, 32'h3380_0000,
                                        32'h3f80_0000);
                        expected_result[channel] = 32'h3f80_0000;
                    end
                    4: begin
                        set_channel_word(channel, 0, 32'h3f80_0001,
                                        32'h3f80_0000);
                        set_channel_word(channel, 1, 32'h3380_0000,
                                        32'h3f80_0000);
                        expected_result[channel] = 32'h3f80_0002;
                    end
                    5: begin
                        set_channel_word(channel, 0, 32'h4b80_0000,
                                        32'h3f80_0000);
                        set_channel_word(channel, 1, 32'h3f80_0000,
                                        32'h3f80_0000);
                        set_channel_word(channel, 2, 32'hcb80_0000,
                                        32'h3f80_0000);
                        set_channel_word(channel, 3, 32'h3f80_0000,
                                        32'h3f80_0000);
                        expected_result[channel] = 32'h3f80_0000;
                    end
                    6: begin
                        set_channel_word(channel, 0, 32'h7f7f_ffff,
                                        32'h4000_0000);
                        expected_result[channel] = 32'h7f80_0000;
                    end
                    7: begin
                        set_channel_word(channel, 0, 32'h0000_0000,
                                        32'h7f80_0000);
                        expected_result[channel] = 32'h7fc0_0000;
                    end
                    8: begin
                        set_channel_word(channel, 0, 32'h4070_0000,
                                        32'h3f00_0000);
                        expected_result[channel] = 32'h3ff0_0000;
                    end
                    9: begin
                        set_channel_word(channel, 0, 32'h7f80_0000,
                                        32'h3f80_0000);
                        set_channel_word(channel, 1, 32'hff80_0000,
                                        32'h3f80_0000);
                        expected_result[channel] = 32'h7fc0_0000;
                    end
                    10: begin
                        set_channel_word(channel, 0, 32'h7fc1_2345,
                                        32'h3f80_0000);
                        expected_result[channel] = 32'h7fc0_0000;
                    end
                    11: begin
                        set_channel_word(channel, 0, 32'h7f80_0001,
                                        32'h3f80_0000);
                        expected_result[channel] = 32'h7fc0_0000;
                    end
                    12: begin
                        set_channel_word(channel, 0, 32'h0000_0001,
                                        32'h3f80_0000);
                        expected_result[channel] = 32'h0000_0001;
                    end
                    default: begin
                        set_channel_word(channel, 0, 32'h8000_0001,
                                        32'h3f80_0000);
                        expected_result[channel] = 32'h8000_0001;
                    end
                endcase
            end
        end
    endtask

    task automatic check_active_root(input string label);
        integer address;
        begin
            for (address = 0; address < DEST_BYTES; address = address + 1)
                if (gmem[ACTIVE_ROOT_BASE + address] !== 8'ha5)
                    fail_case($sformatf("%s active-root canary", label));
        end
    endtask

    task automatic run_reset_abort;
        integer cycles;
        begin
            pulse_reset();
            set_valid_descriptor();
            set_bus_defaults();
            prepare_vectors();
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
            set_valid_descriptor();
            set_bus_defaults();
            prepare_vectors();
            inject_read_error_ordinal_q = 0;
            pulse_start();
            wait_terminal(256, "late read error");
            if (!error_o || dst_commit_o || (error_code_o != ERR_GMEM)
                    || (gmem_read_requests_o != 64'd1)
                    || (gmem_read_responses_o != 64'd1)
                    || (read_payload_bytes_o != 64'b0)
                    || (source0_words_completed_o != 64'b0)
                    || (mul_requests_o != 64'b0)
                    || (gmem_write_requests_o != 64'b0)
                    || (commit_count != 0))
                fail_case("late read fault accounting");
            check_identity(command_id_i, canonical_node_id_lo_i,
                           canonical_node_id_hi_i, PROFILE_SSM_CONV, 32'd18);
            check_active_root("late read error");
            finish_terminal("late read error");
        end
    endtask

    task automatic run_timeout_drain;
        begin
            pulse_reset();
            set_valid_descriptor();
            set_bus_defaults();
            prepare_vectors();
            late_response_ordinal_q = 0;
            late_response_delay_q = STALL_TIMEOUT + 8;
            pulse_start();
            wait_terminal(512, "accepted timeout drain");
            if (!error_o || dst_commit_o || (error_code_o != ERR_STALL)
                    || (drain_seen_count == 0)
                    || (gmem_read_requests_o != 64'd1)
                    || (gmem_read_responses_o != 64'd1)
                    || (read_payload_bytes_o != 64'b0)
                    || (source0_words_completed_o != 64'b0)
                    || (commit_count != 0))
                fail_case("accepted timeout drain accounting");
            check_identity(command_id_i, canonical_node_id_lo_i,
                           canonical_node_id_hi_i, PROFILE_SSM_CONV, 32'd18);
            check_active_root("timeout drain");
            finish_terminal("accepted timeout drain");
        end
    endtask

    task automatic run_late_write_error;
        begin
            pulse_reset();
            set_valid_descriptor();
            set_bus_defaults();
            prepare_vectors();
            inject_write_error_ordinal_q = 1;
            pulse_start();
            wait_terminal(4096, "late write error");
            if (!error_o || dst_commit_o || (error_code_o != ERR_GMEM)
                    || (outputs_computed_o != 64'd2)
                    || (outputs_completed_o != 64'd1)
                    || (source0_words_completed_o != 64'd8)
                    || (source1_words_completed_o != 64'd8)
                    || (gmem_read_requests_o != 64'd8)
                    || (gmem_read_responses_o != 64'd8)
                    || (read_payload_bytes_o != 64'd64)
                    || (mul_requests_o != 64'd8)
                    || (mul_responses_o != 64'd8)
                    || (add_requests_o != 64'd8)
                    || (add_responses_o != 64'd8)
                    || (gmem_write_requests_o != 64'd2)
                    || (gmem_write_responses_o != 64'd2)
                    || (write_payload_bytes_o != 64'd4)
                    || (commit_count != 0))
                fail_case("late write fault accounting");
            if ((get_word(DST_BASE) !== expected_result[0])
                    || (get_word(DST_BASE + 4) !== 32'hc3c3_c3c3))
                fail_case("private write prefix");
            check_identity(command_id_i, canonical_node_id_lo_i,
                           canonical_node_id_hi_i, PROFILE_SSM_CONV, 32'd18);
            check_active_root("late write error");
            finish_terminal("late write error");
        end
    endtask

    task automatic run_full_success;
        integer channel;
        integer cycles;
        reg busy_start_sent;
        reg [63:0] expected_command, expected_lo, expected_hi;
        begin
            pulse_reset();
            set_valid_descriptor();
            set_bus_defaults();
            request_backpressure_q = 1'b1;
            prepare_vectors();
            expected_command = command_id_i;
            expected_lo = canonical_node_id_lo_i;
            expected_hi = canonical_node_id_hi_i;
            pulse_start();
            cycles = 0;
            busy_start_sent = 1'b0;
            while (!completion_valid_o && (cycles < 2000000)) begin
                @(negedge clk_i);
                cycles = cycles + 1;
                if (!busy_start_sent && (accepted_reads >= 4)) begin
                    if (ready_o || !busy_o)
                        fail_case("busy identity fixture");
                    command_id_i = 64'hffff_eeee_dddd_cccc;
                    canonical_node_id_lo_i = 64'hbbbb_aaaa_9999_8888;
                    canonical_node_id_hi_i = 64'h7777_6666_5555_4444;
                    manifest_op_id_i = 16'd75;
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
                           PROFILE_SSM_CONV, 32'd18);
            for (channel = 0; channel < CHANNELS; channel = channel + 1)
                if (get_word(DST_BASE + (channel * 4))
                        !== expected_result[channel])
                    fail_case($sformatf(
                        "raw ordered oracle channel=%0d actual=%08x expected=%08x",
                        channel, get_word(DST_BASE + (channel * 4)),
                        expected_result[channel]));
            if ((outputs_computed_o != 64'(CHANNELS))
                    || (outputs_completed_o != 64'(CHANNELS))
                    || (source0_words_completed_o != 64'(WORK_ITEMS))
                    || (source1_words_completed_o != 64'(WORK_ITEMS))
                    || (work_items_completed_o != 64'(WORK_ITEMS))
                    || (gmem_read_requests_o != 64'(READ_BEATS))
                    || (gmem_read_responses_o != 64'(READ_BEATS))
                    || (read_payload_bytes_o != 64'd196608)
                    || (gmem_write_requests_o != 64'(CHANNELS))
                    || (gmem_write_responses_o != 64'(CHANNELS))
                    || (write_payload_bytes_o != 64'(DEST_BYTES))
                    || (mul_requests_o != 64'(WORK_ITEMS))
                    || (mul_responses_o != 64'(WORK_ITEMS))
                    || (add_requests_o != 64'(WORK_ITEMS))
                    || (add_responses_o != 64'(WORK_ITEMS))
                    || (numeric_flags_o != 5'h15)
                    || (active_cycles_o == 64'b0))
                fail_case("full exact counters/flags");
            if ((accepted_reads != READ_BEATS)
                    || (accepted_writes != CHANNELS)
                    || (response_count != (READ_BEATS + CHANNELS))
                    || (successful_writes != CHANNELS)
                    || (held_stability_cycles == 0) || !busy_start_sent)
                fail_case("full independent transport/backpressure");
            check_active_root("full success");
            $display("[NPU-SSM-CONV-WRITEBACK][FULL] nodes=18 channels=%0d work=%0d read=%0d/%0dB write=%0d/%0dB flags=%02x held=%0d cycles=%0d",
                     outputs_completed_o, work_items_completed_o,
                     gmem_read_requests_o, read_payload_bytes_o,
                     gmem_write_requests_o, write_payload_bytes_o,
                     numeric_flags_o, held_stability_cycles,
                     active_cycles_o);
            finish_terminal("full success");
            if ((completion_count != 1) || (commit_count != 1))
                fail_case("full completion/commit pulses");
        end
    endtask

    initial begin
        integer address;
        rst_i = 1'b1;
        start_i = 1'b0;
        set_valid_descriptor();
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

        set_valid_descriptor(); manifest_op_id_i = 16'd75;
        run_static_reject(ERR_DESCRIPTOR, "op id");
        set_valid_descriptor(); source_arity_i = 3'd1;
        run_static_reject(ERR_DESCRIPTOR, "arity");
        set_valid_descriptor(); op_params_i = 128'd1;
        run_static_reject(ERR_DESCRIPTOR, "op params low128");
        set_valid_descriptor(); op_params_tail_zero_i = 1'b0;
        run_static_reject(ERR_DESCRIPTOR, "op params tail");
        set_valid_descriptor(); npu_required_i = 1'b0;
        run_static_reject(ERR_DESCRIPTOR, "required");
        set_valid_descriptor(); dst_shadow_private_i = 1'b0;
        run_static_reject(ERR_DESCRIPTOR, "private destination");
        set_valid_descriptor(); src0_flags_i = 32'd0;
        run_static_reject(ERR_DESCRIPTOR, "src0 flags");
        set_valid_descriptor(); src1_flags_i = 32'd16;
        run_static_reject(ERR_DESCRIPTOR, "src1 flags");
        set_valid_descriptor(); dst_ne0_i = 32'd6143;
        run_static_reject(ERR_DESCRIPTOR, "destination shape");
        set_valid_descriptor(); src0_nb1_i = 64'd24;
        run_static_reject(ERR_DESCRIPTOR, "source stride");
        set_valid_descriptor(); src0_window_read_i = 1'b0;
        run_static_reject(ERR_SRC0, "src0 capability");
        set_valid_descriptor(); src0_base_i = 64'hffff_ffff_ffff_fff8;
        src0_window_base_i = 64'hffff_ffff_ffff_fff8;
        src0_window_bytes_i = 64'd8;
        run_static_reject(ERR_SRC0, "src0 overflow");
        set_valid_descriptor(); src1_window_write_i = 1'b1;
        run_static_reject(ERR_SRC1, "src1 capability");
        set_valid_descriptor(); dst_window_write_i = 1'b0;
        run_static_reject(ERR_DST, "dst capability");
        set_valid_descriptor(); dst_base_i = 64'hffff_ffff_ffff_fffc;
        dst_window_base_i = 64'hffff_ffff_ffff_fff8;
        dst_window_bytes_i = 64'd8;
        run_static_reject(ERR_DST, "dst overflow");
        set_valid_descriptor(); src1_base_i = SRC0_BASE;
        src1_window_base_i = SRC0_BASE;
        run_static_reject(ERR_ALIAS, "source physical alias");
        set_valid_descriptor(); dst_base_i = 64'd4;
        dst_window_base_i = SRC0_BASE;
        dst_window_bytes_i = 64'(SOURCE_BYTES);
        run_static_reject(ERR_ALIAS, "destination physical alias");
        $display("[NPU-SSM-CONV-WRITEBACK][STATIC] exact rejects=17 zero-traffic");

        run_reset_abort();
        run_late_read_error();
        run_timeout_drain();
        run_late_write_error();
        run_full_success();

        $display("[NPU-SSM-CONV-WRITEBACK][PASS] frozen_nodes=18 profiles=1 channels=6144 raw_modes=14 static=17 reset=1 late_read=1 timeout_drain=1 late_write=1 backpressure=1 busy=1");
        $finish;
    end

endmodule

`default_nettype wire
