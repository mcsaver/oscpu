`timescale 1ns/1ps
`default_nettype none

// Transaction-level verification for the frozen-v5 SUM_ROWS profile.
// Numerical expected values are literal raw-bit vectors transcribed from the
// public TensorNpuOrderedSumRows ordered-DAG contract.  The TB performs no
// floating-point arithmetic and uses no hierarchical observation/bypass.
module tb_sum_rows_writeback_adapter;

    localparam integer MEM_BYTES = 2097152;
    localparam integer SRC_BYTES = 1048576;
    localparam integer DST_BYTES = 8192;
    localparam integer ROWS = 2048;
    localparam integer ELEMENTS = 262144;
    localparam integer READ_BEATS = 131072;
    localparam integer STALL_TIMEOUT = 12;

    localparam logic [63:0] SRC_BASE = 64'h0000_0000_0000_0000;
    localparam logic [63:0] SRC1_SENTINEL = 64'h0000_0000_0014_0000;
    localparam logic [63:0] DST_BASE = 64'h0000_0000_0018_0000;
    localparam logic [63:0] ACTIVE_ROOT_BASE = 64'h0000_0000_001a_0000;
    localparam logic [31:0] KERNEL_REDUCE_F32 = 32'h514e0011;
    localparam logic [2:0] REDUCE_SUM_ROWS = 3'd1;
    localparam logic [15:0] MANIFEST_SUM_ROWS = 16'd15;
    localparam logic [7:0] PROFILE_SUM_ROWS = 8'd0;

    localparam logic [4:0] ERR_DESCRIPTOR = 5'd1;
    localparam logic [4:0] ERR_SRC0 = 5'd2;
    localparam logic [4:0] ERR_SRC1 = 5'd3;
    localparam logic [4:0] ERR_DST = 5'd4;
    localparam logic [4:0] ERR_ALIAS = 5'd5;
    localparam logic [4:0] ERR_ENGINE = 5'd6;
    localparam logic [4:0] ENGINE_ERR_GMEM = 5'd9;
    localparam logic [4:0] ENGINE_ERR_STALL = 5'd12;

    reg clk_i, rst_i, start_i;
    wire ready_o, busy_o;
    reg [2:0] reduce_op_i;
    reg [15:0] manifest_op_id_i;
    reg [2:0] source_arity_i;
    reg [127:0] op_params_i;
    reg op_params_tail_zero_i, npu_required_i;
    reg [63:0] command_id_i;
    reg [63:0] canonical_node_id_lo_i, canonical_node_id_hi_i;
    reg dst_shadow_private_i, windows_generation_valid_i;

    reg [7:0] src0_dtype_i;
    reg [31:0] src0_flags_i;
    reg [63:0] src0_view_off_i;
    reg [31:0] src0_ne0_i, src0_ne1_i, src0_ne2_i, src0_ne3_i;
    reg [63:0] src0_base_i;
    reg [63:0] src0_nb0_i, src0_nb1_i, src0_nb2_i, src0_nb3_i;
    reg [63:0] src1_base_i;
    reg [63:0] src1_nb0_i, src1_nb1_i, src1_nb2_i, src1_nb3_i;
    reg [7:0] dst_dtype_i;
    reg [31:0] dst_flags_i;
    reg [63:0] dst_view_off_i;
    reg [31:0] dst_ne0_i, dst_ne1_i, dst_ne2_i, dst_ne3_i;
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
    wire [15:0] completion_manifest_op_id_o;
    wire [2:0] completion_source_arity_o;
    wire [7:0] completion_profile_id_o;
    wire [31:0] completion_kernel_id_o;
    wire [31:0] completion_operator_census_o;
    wire [31:0] completion_profile_census_o;
    wire done_o, error_o;
    wire [4:0] error_code_o, engine_error_code_o, engine_flags_o;
    wire poisoned_o;
    wire [63:0] rows_reduced_o, elements_processed_o;
    wire [63:0] reduction_operations_o, results_generated_o;
    wire [63:0] gmem_read_requests_o, gmem_read_responses_o;
    wire [63:0] read_payload_bytes_o;
    wire [63:0] gmem_write_requests_o, gmem_write_responses_o;
    wire [63:0] write_payload_bytes_o;
    wire [63:0] widen_requests_o, widen_responses_o;
    wire [63:0] add_requests_o, add_responses_o;
    wire [63:0] narrow_requests_o, narrow_responses_o;
    wire [63:0] engine_launches_o, engine_terminals_o;
    wire [63:0] engine_active_cycles_o, active_cycles_o;
    wire gmem_outstanding_o, engine_outstanding_o, gmem_drain_o;
    wire engine_fault_valid_o;
    wire [63:0] engine_first_fault_cycle_o;
    wire [127:0] engine_first_fault_coordinate_o;
    wire [63:0] engine_first_fault_gmem_addr_o;

    TensorNpuSumRowsWritebackAdapter #(
        .ENGINE_STALL_TIMEOUT_CYCLES(STALL_TIMEOUT),
        .ENGINE_COMMAND_TIMEOUT_CYCLES(8388608),
        .ENGINE_DRAIN_TIMEOUT_CYCLES(64),
        .ENGINE_ABORT_HOLD_TIMEOUT_CYCLES(64)
    ) dut (
        .clk_i(clk_i), .rst_i(rst_i), .start_i(start_i),
        .ready_o(ready_o), .busy_o(busy_o),
        .reduce_op_i(reduce_op_i),
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
        .src0_nb3_i(src0_nb3_i), .src1_base_i(src1_base_i),
        .src1_nb0_i(src1_nb0_i), .src1_nb1_i(src1_nb1_i),
        .src1_nb2_i(src1_nb2_i), .src1_nb3_i(src1_nb3_i),
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
        .completion_reduce_op_o(completion_reduce_op_o),
        .completion_manifest_op_id_o(completion_manifest_op_id_o),
        .completion_source_arity_o(completion_source_arity_o),
        .completion_profile_id_o(completion_profile_id_o),
        .completion_kernel_id_o(completion_kernel_id_o),
        .completion_operator_census_o(completion_operator_census_o),
        .completion_profile_census_o(completion_profile_census_o),
        .done_o(done_o), .error_o(error_o), .error_code_o(error_code_o),
        .engine_error_code_o(engine_error_code_o),
        .engine_flags_o(engine_flags_o), .poisoned_o(poisoned_o),
        .rows_reduced_o(rows_reduced_o),
        .elements_processed_o(elements_processed_o),
        .reduction_operations_o(reduction_operations_o),
        .results_generated_o(results_generated_o),
        .gmem_read_requests_o(gmem_read_requests_o),
        .gmem_read_responses_o(gmem_read_responses_o),
        .read_payload_bytes_o(read_payload_bytes_o),
        .gmem_write_requests_o(gmem_write_requests_o),
        .gmem_write_responses_o(gmem_write_responses_o),
        .write_payload_bytes_o(write_payload_bytes_o),
        .widen_requests_o(widen_requests_o),
        .widen_responses_o(widen_responses_o),
        .add_requests_o(add_requests_o), .add_responses_o(add_responses_o),
        .narrow_requests_o(narrow_requests_o),
        .narrow_responses_o(narrow_responses_o),
        .engine_launches_o(engine_launches_o),
        .engine_terminals_o(engine_terminals_o),
        .engine_active_cycles_o(engine_active_cycles_o),
        .active_cycles_o(active_cycles_o),
        .gmem_outstanding_o(gmem_outstanding_o),
        .engine_outstanding_o(engine_outstanding_o),
        .gmem_drain_o(gmem_drain_o),
        .engine_fault_valid_o(engine_fault_valid_o),
        .engine_first_fault_cycle_o(engine_first_fault_cycle_o),
        .engine_first_fault_coordinate_o(engine_first_fault_coordinate_o),
        .engine_first_fault_gmem_addr_o(engine_first_fault_gmem_addr_o)
    );

    initial clk_i = 1'b0;
    always #5 clk_i <= ~clk_i;

    reg [7:0] gmem [0:MEM_BYTES-1];
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
                            && (!request_backpressure_q
                                || (global_cycles[1:0] != 2'b01));

    task automatic fail_case(input string reason);
        begin
            $display("[NPU-SUM-ROWS-WRITEBACK][FAIL] %s cycle=%0d state busy=%0b done=%0b error=%0b err=%0d engine_err=%0d req=%0d/%0d rsp=%0d commit=%0d",
                     reason, global_cycles, busy_o, done_o, error_o,
                     error_code_o, engine_error_code_o, accepted_reads,
                     accepted_writes, response_count, commit_count);
            $display("[NPU-SUM-ROWS-WRITEBACK][EVIDENCE] rows=%0d elements=%0d reductions=%0d results=%0d read=%0d/%0d/%0dB write=%0d/%0d/%0dB child=%0d/%0d/%0d flags=%02x outstanding=%0b/%0b drain=%0b",
                     rows_reduced_o, elements_processed_o,
                     reduction_operations_o, results_generated_o,
                     gmem_read_requests_o, gmem_read_responses_o,
                     read_payload_bytes_o, gmem_write_requests_o,
                     gmem_write_responses_o, write_payload_bytes_o,
                     widen_responses_o, add_responses_o, narrow_responses_o,
                     engine_flags_o, gmem_outstanding_o,
                     engine_outstanding_o, gmem_drain_o);
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
                    fail_case("held GMEM request withdrew valid");
                if ((gmem_req_write_o !== held_request_write_q)
                        || (gmem_req_addr_o !== held_request_addr_q)
                        || (gmem_req_wdata_o !== held_request_wdata_q)
                        || (gmem_req_wstrb_o !== held_request_wstrb_q))
                    fail_case("held GMEM request payload changed");
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
                    fail_case("more than one GMEM request outstanding");
                if ((gmem_req_addr_o[2:0] != 3'b000)
                        || (gmem_req_addr_o >= 64'(MEM_BYTES)))
                    fail_case("GMEM request address/alignment");
                pending_q <= 1'b1;
                pending_write_q <= gmem_req_write_o;
                pending_addr_q <= gmem_req_addr_o;
                pending_wdata_q <= gmem_req_wdata_o;
                pending_wstrb_q <= gmem_req_wstrb_o;
                pending_error_q <= (!gmem_req_write_o
                        && (accepted_reads == inject_read_error_ordinal_q))
                    || (gmem_req_write_o
                        && (accepted_writes == inject_write_error_ordinal_q));
                if (accepted_requests == late_response_ordinal_q)
                    pending_delay_q <= late_response_delay_q;
                else
                    pending_delay_q <= normal_response_delay_q;
                accepted_requests <= accepted_requests + 1;
                if (gmem_req_write_o) begin
                    if (check_order_q
                            && (gmem_req_addr_o
                                != ((DST_BASE
                                     + (64'(accepted_writes) * 64'd4))
                                    & 64'hffff_ffff_ffff_fff8)))
                        fail_case("private write address order");
                    if (((accepted_writes[0] == 1'b0)
                            && (gmem_req_wstrb_o != 8'h0f))
                            || ((accepted_writes[0] == 1'b1)
                                && (gmem_req_wstrb_o != 8'hf0)))
                        fail_case("private F32 write strobe");
                    accepted_writes <= accepted_writes + 1;
                end else begin
                    if (check_order_q
                            && (gmem_req_addr_o
                                != (SRC_BASE + (64'(accepted_reads) * 64'd8))))
                        fail_case("source read address order");
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
                                      ? 64'b0
                                      : memory_read64(pending_addr_q);
                end else begin
                    pending_delay_q <= pending_delay_q - 1;
                end
            end

            if (gmem_rsp_valid_i && gmem_rsp_ready_o) begin
                if (!pending_q)
                    fail_case("response without pending request");
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
            reduce_op_i = REDUCE_SUM_ROWS;
            manifest_op_id_i = MANIFEST_SUM_ROWS;
            source_arity_i = 3'd1;
            op_params_i = 128'b0;
            op_params_tail_zero_i = 1'b1;
            npu_required_i = 1'b1;
            command_id_i = 64'hfedc_ba98_7654_3210;
            canonical_node_id_lo_i = 64'h79d7_a04c_08c2_b2c1;
            canonical_node_id_hi_i = 64'hddc4_fc0b_00f1_7fb1;
            dst_shadow_private_i = 1'b1;
            windows_generation_valid_i = 1'b1;
            src0_dtype_i = 8'd0;
            src0_flags_i = 32'd16;
            src0_view_off_i = 64'b0;
            src0_ne0_i = 32'd128;
            src0_ne1_i = 32'd128;
            src0_ne2_i = 32'd16;
            src0_ne3_i = 32'd1;
            src0_base_i = SRC_BASE;
            src0_nb0_i = 64'd4;
            src0_nb1_i = 64'd512;
            src0_nb2_i = 64'd65536;
            src0_nb3_i = 64'd1048576;
            src1_base_i = SRC1_SENTINEL;
            src1_nb0_i = 64'b0;
            src1_nb1_i = 64'b0;
            src1_nb2_i = 64'b0;
            src1_nb3_i = 64'b0;
            dst_dtype_i = 8'd0;
            dst_flags_i = 32'd16;
            dst_view_off_i = 64'b0;
            dst_ne0_i = 32'd1;
            dst_ne1_i = 32'd128;
            dst_ne2_i = 32'd16;
            dst_ne3_i = 32'd1;
            dst_base_i = DST_BASE;
            dst_nb0_i = 64'd4;
            dst_nb1_i = 64'd4;
            dst_nb2_i = 64'd512;
            dst_nb3_i = 64'd8192;
            src0_window_base_i = SRC_BASE;
            src0_window_bytes_i = 64'(SRC_BYTES);
            src0_window_read_i = 1'b1;
            src0_window_write_i = 1'b0;
            src1_window_base_i = SRC1_SENTINEL;
            src1_window_bytes_i = 64'b0;
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
            rst_i = 1'b1;
            repeat (3) @(posedge clk_i);
            @(negedge clk_i);
            rst_i = 1'b0;
            repeat (2) @(negedge clk_i);
            if (!ready_o || busy_o || completion_valid_o
                    || gmem_outstanding_o || engine_outstanding_o)
                fail_case("reset did not restore quiescent ready state");
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
            if (gmem_outstanding_o || engine_outstanding_o)
                fail_case($sformatf("%s terminal retained outstanding", label));
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
                    || (completion_reduce_op_o !== REDUCE_SUM_ROWS)
                    || (completion_manifest_op_id_o !== MANIFEST_SUM_ROWS)
                    || (completion_source_arity_o !== 3'd1)
                    || (completion_profile_id_o !== expected_profile)
                    || (completion_kernel_id_o !== KERNEL_REDUCE_F32)
                    || (completion_operator_census_o !== expected_census)
                    || (completion_profile_census_o !== expected_census))
                fail_case("resident identity/census mismatch");
        end
    endtask

    task automatic finish_terminal_cycle(input string label);
        begin
            @(negedge clk_i);
            if (completion_valid_o || done_o || error_o || !ready_o)
                fail_case($sformatf("%s terminal was not one cycle", label));
        end
    endtask

    task automatic run_static_reject(
        input logic [4:0] expected_error,
        input string label
    );
        integer before_requests;
        logic [63:0] saved_command, saved_lo, saved_hi;
        begin
            before_requests = accepted_requests;
            saved_command = command_id_i;
            saved_lo = canonical_node_id_lo_i;
            saved_hi = canonical_node_id_hi_i;
            pulse_start();
            wait_terminal(32, label);
            if (!error_o || done_o || dst_commit_o
                    || (error_code_o != expected_error)
                    || (engine_launches_o != 64'b0)
                    || (engine_terminals_o != 64'b0)
                    || (accepted_requests != before_requests)
                    || (gmem_read_requests_o != 64'b0)
                    || (gmem_write_requests_o != 64'b0))
                fail_case($sformatf("%s static rejection contract", label));
            if ((completion_command_id_o !== saved_command)
                    || (completion_canonical_node_id_lo_o !== saved_lo)
                    || (completion_canonical_node_id_hi_o !== saved_hi)
                    || (completion_kernel_id_o !== KERNEL_REDUCE_F32))
                fail_case($sformatf("%s static identity", label));
            finish_terminal_cycle(label);
        end
    endtask

    task automatic put_source_word(
        input integer row,
        input integer element,
        input logic [31:0] raw
    );
        integer address;
        begin
            address = ((row * 128) + element) * 4;
            gmem[address] = raw[7:0];
            gmem[address + 1] = raw[15:8];
            gmem[address + 2] = raw[23:16];
            gmem[address + 3] = raw[31:24];
        end
    endtask

    task automatic fill_source_row(
        input integer row,
        input logic [31:0] raw
    );
        integer element;
        begin
            for (element = 0; element < 128; element = element + 1)
                put_source_word(row, element, raw);
        end
    endtask

    task automatic source_run_raw(
        input integer row,
        input integer first,
        input integer count,
        input logic [31:0] raw
    );
        integer element;
        begin
            for (element = first; element < (first + count);
                    element = element + 1)
                put_source_word(row, element, raw);
        end
    endtask

    function automatic [31:0] get_word(input integer address);
        begin
            get_word = {gmem[address + 3], gmem[address + 2],
                        gmem[address + 1], gmem[address]};
        end
    endfunction

    logic [31:0] expected_result [0:ROWS-1];

    task automatic prepare_ordered_vectors;
        integer row;
        integer address;
        begin
            for (address = 0; address < SRC_BYTES; address = address + 1)
                gmem[address] = 8'h00;
            for (address = 0; address < DST_BYTES; address = address + 1) begin
                gmem[DST_BASE + address] = 8'hc3;
                gmem[ACTIVE_ROOT_BASE + address] = 8'ha5;
            end
            for (row = 0; row < ROWS; row = row + 1)
                expected_result[row] = 32'h0000_0000;

            // Exact serial-DAG edge vectors from the existing public Engine
            // oracle: +0 seed, signed zero, subnormals, cancellation, ordered
            // rounding, overflow, infinities, qNaN/sNaN and NaN precedence.
            fill_source_row(1, 32'h8000_0000);
            put_source_word(2, 0,   32'h8000_0000);
            put_source_word(3, 127, 32'h8000_0000);
            put_source_word(4, 0,   32'h3f80_0000);
            put_source_word(5, 127, 32'h3f80_0000);
            put_source_word(6, 0,   32'hbf80_0000);
            put_source_word(6, 127, 32'h3f80_0000);
            put_source_word(7, 0,   32'h3f80_0000);
            put_source_word(7, 127, 32'hbf80_0000);
            put_source_word(8, 0,   32'h0000_0001);
            put_source_word(9, 0,   32'h8000_0001);
            fill_source_row(10, 32'h0000_0001);
            source_run_raw(11, 0, 127, 32'h0000_0001);
            put_source_word(12, 0, 32'h0080_0000);
            put_source_word(13, 0, 32'h0080_0000);
            put_source_word(13, 1, 32'h8000_0001);
            put_source_word(14, 0, 32'h007f_ffff);
            put_source_word(14, 1, 32'h0000_0001);
            put_source_word(15, 0, 32'h0000_0001);
            put_source_word(15, 1, 32'h8000_0001);
            put_source_word(16, 0, 32'h0080_0000);
            put_source_word(16, 1, 32'h807f_ffff);
            put_source_word(17, 0, 32'h007f_ffff);
            put_source_word(17, 1, 32'h007f_ffff);
            put_source_word(18, 0, 32'h4b80_0000);
            put_source_word(18, 1, 32'h3f80_0000);
            put_source_word(18, 2, 32'h3f80_0000);
            put_source_word(19, 0, 32'h4b80_0000);
            put_source_word(19, 1, 32'h3f80_0000);
            put_source_word(19, 2, 32'hcb80_0000);
            put_source_word(20, 0, 32'hcb80_0000);
            put_source_word(20, 1, 32'hbf80_0000);
            put_source_word(20, 2, 32'hbf80_0000);
            put_source_word(21, 0, 32'h3f80_0000);
            put_source_word(21, 1, 32'h3380_0000);
            put_source_word(21, 2, 32'h3380_0000);
            put_source_word(22, 0, 32'h3f80_0000);
            put_source_word(22, 1, 32'h3380_0000);
            put_source_word(23, 0, 32'h3f80_0000);
            put_source_word(23, 1, 32'h3440_0000);
            put_source_word(24, 0, 32'h4b80_0000);
            put_source_word(24, 1, 32'h3f80_0000);
            put_source_word(25, 0, 32'h4b80_0000);
            put_source_word(25, 1, 32'h4040_0000);
            put_source_word(26, 0, 32'hcb80_0000);
            put_source_word(26, 1, 32'hbf80_0000);
            put_source_word(27, 0, 32'hcb80_0000);
            put_source_word(27, 1, 32'hc040_0000);
            put_source_word(28, 0, 32'h7180_0000);
            put_source_word(28, 1, 32'h3f80_0000);
            put_source_word(28, 2, 32'hf180_0000);
            put_source_word(29, 0, 32'h7180_0000);
            put_source_word(29, 1, 32'hf180_0000);
            put_source_word(29, 2, 32'h3f80_0000);
            put_source_word(30, 0, 32'h7180_0000);
            put_source_word(30, 1, 32'h3f80_0000);
            put_source_word(30, 2, 32'hf180_0000);
            put_source_word(30, 3, 32'h3f80_0000);
            put_source_word(31, 0, 32'h7180_0000);
            put_source_word(31, 1, 32'h5700_0000);
            put_source_word(31, 2, 32'hf180_0000);
            put_source_word(32, 0, 32'h7180_0000);
            put_source_word(32, 1, 32'h5780_0000);
            put_source_word(32, 2, 32'h5700_0000);
            put_source_word(32, 3, 32'hf180_0000);
            put_source_word(33, 0, 32'h7180_0000);
            put_source_word(33, 1, 32'h56ff_ffff);
            put_source_word(33, 2, 32'hf180_0000);
            put_source_word(34, 0, 32'h7180_0000);
            put_source_word(34, 1, 32'h5700_0001);
            put_source_word(34, 2, 32'hf180_0000);
            put_source_word(35, 0, 32'hf180_0000);
            put_source_word(35, 1, 32'hd700_0000);
            put_source_word(35, 2, 32'h7180_0000);
            put_source_word(36, 0, 32'hf180_0000);
            put_source_word(36, 1, 32'hd780_0000);
            put_source_word(36, 2, 32'hd700_0000);
            put_source_word(36, 3, 32'h7180_0000);
            put_source_word(37, 0, 32'h7180_0000);
            put_source_word(37, 1, 32'h5700_0000);
            put_source_word(37, 2, 32'h5700_0000);
            put_source_word(37, 3, 32'hf180_0000);
            put_source_word(38, 0, 32'h7f7f_ffff);
            put_source_word(39, 0, 32'h7f7f_ffff);
            put_source_word(39, 1, 32'h72ff_ffff);
            put_source_word(40, 0, 32'h7f7f_ffff);
            put_source_word(40, 1, 32'h7300_0000);
            put_source_word(41, 0, 32'h7f7f_ffff);
            put_source_word(41, 1, 32'h7300_0001);
            put_source_word(42, 0, 32'h7f7f_ffff);
            put_source_word(42, 1, 32'h7f7f_ffff);
            put_source_word(43, 0, 32'hff7f_ffff);
            put_source_word(43, 1, 32'hf2ff_ffff);
            put_source_word(44, 0, 32'hff7f_ffff);
            put_source_word(44, 1, 32'hf300_0000);
            put_source_word(45, 0, 32'h7f7f_ffff);
            put_source_word(45, 1, 32'h7300_0000);
            put_source_word(45, 2, 32'hf300_0000);
            put_source_word(46, 0, 32'h7f7f_ffff);
            put_source_word(46, 1, 32'h7f7f_ffff);
            put_source_word(46, 2, 32'hff7f_ffff);
            put_source_word(47, 0, 32'h7f80_0000);
            put_source_word(48, 0, 32'hff80_0000);
            put_source_word(49, 0, 32'h7f80_0000);
            put_source_word(49, 1, 32'hff80_0000);
            put_source_word(50, 0, 32'h7f80_0000);
            put_source_word(50, 1, 32'h7f80_0000);
            put_source_word(51, 0, 32'h7fc1_2345);
            put_source_word(52, 0, 32'hffc1_2345);
            put_source_word(53, 0, 32'h7f80_0001);
            put_source_word(54, 0, 32'hff80_0001);
            put_source_word(55, 0,   32'h7fc1_2345);
            put_source_word(55, 127, 32'h7f80_0001);
            put_source_word(56, 0,   32'h7f80_0000);
            put_source_word(56, 127, 32'hff80_0000);
            put_source_word(57, 0,   32'h7f80_0000);
            put_source_word(57, 127, 32'h7f80_0001);
            put_source_word(58, 0,   32'h7180_0000);
            put_source_word(58, 1,   32'h3f80_0000);
            put_source_word(58, 127, 32'h7f80_0001);
            put_source_word(59, 0, 32'h7180_0000);
            put_source_word(59, 1, 32'h5700_0000);
            put_source_word(59, 2, 32'hf180_0000);
            put_source_word(59, 3, 32'h5700_0000);

            expected_result[4]  = 32'h3f80_0000;
            expected_result[5]  = 32'h3f80_0000;
            expected_result[8]  = 32'h0000_0001;
            expected_result[9]  = 32'h8000_0001;
            expected_result[10] = 32'h0000_0080;
            expected_result[11] = 32'h0000_007f;
            expected_result[12] = 32'h0080_0000;
            expected_result[13] = 32'h007f_ffff;
            expected_result[14] = 32'h0080_0000;
            expected_result[16] = 32'h0000_0001;
            expected_result[17] = 32'h00ff_fffe;
            expected_result[18] = 32'h4b80_0001;
            expected_result[19] = 32'h3f80_0000;
            expected_result[20] = 32'hcb80_0001;
            expected_result[21] = 32'h3f80_0001;
            expected_result[22] = 32'h3f80_0000;
            expected_result[23] = 32'h3f80_0002;
            expected_result[24] = 32'h4b80_0000;
            expected_result[25] = 32'h4b80_0002;
            expected_result[26] = 32'hcb80_0000;
            expected_result[27] = 32'hcb80_0002;
            expected_result[29] = 32'h3f80_0000;
            expected_result[30] = 32'h3f80_0000;
            expected_result[32] = 32'h5800_0000;
            expected_result[34] = 32'h5780_0000;
            expected_result[36] = 32'hd800_0000;
            expected_result[38] = 32'h7f7f_ffff;
            expected_result[39] = 32'h7f7f_ffff;
            expected_result[40] = 32'h7f80_0000;
            expected_result[41] = 32'h7f80_0000;
            expected_result[42] = 32'h7f80_0000;
            expected_result[43] = 32'hff7f_ffff;
            expected_result[44] = 32'hff80_0000;
            expected_result[45] = 32'h7f7f_ffff;
            expected_result[46] = 32'h7f7f_ffff;
            expected_result[47] = 32'h7f80_0000;
            expected_result[48] = 32'hff80_0000;
            expected_result[49] = 32'h7fc0_0000;
            expected_result[50] = 32'h7f80_0000;
            expected_result[51] = 32'h7fc0_0000;
            expected_result[52] = 32'h7fc0_0000;
            expected_result[53] = 32'h7fc0_0000;
            expected_result[54] = 32'h7fc0_0000;
            expected_result[55] = 32'h7fc0_0000;
            expected_result[56] = 32'h7fc0_0000;
            expected_result[57] = 32'h7fc0_0000;
            expected_result[58] = 32'h7fc0_0000;
            expected_result[59] = 32'h5700_0000;
        end
    endtask

    task automatic prepare_zero_vectors;
        integer address;
        begin
            for (address = 0; address < SRC_BYTES; address = address + 1)
                gmem[address] = 8'h00;
            for (address = 0; address < DST_BYTES; address = address + 1) begin
                gmem[DST_BASE + address] = 8'hc3;
                gmem[ACTIVE_ROOT_BASE + address] = 8'ha5;
            end
        end
    endtask

    task automatic check_active_root_canary(input string label);
        integer address;
        begin
            for (address = 0; address < DST_BYTES; address = address + 1)
                if (gmem[ACTIVE_ROOT_BASE + address] !== 8'ha5)
                    fail_case($sformatf("%s active-root publication", label));
        end
    endtask

    task automatic run_full_success;
        integer row;
        integer cycles;
        reg busy_start_sent;
        reg [63:0] expected_command, expected_lo, expected_hi;
        begin
            pulse_reset();
            set_valid_descriptor();
            set_bus_defaults();
            request_backpressure_q = 1'b1;
            prepare_ordered_vectors();
            expected_command = command_id_i;
            expected_lo = canonical_node_id_lo_i;
            expected_hi = canonical_node_id_hi_i;
            pulse_start();
            cycles = 0;
            busy_start_sent = 1'b0;
            while (!completion_valid_o && (cycles < 4000000)) begin
                @(negedge clk_i);
                cycles = cycles + 1;
                if (!busy_start_sent && (accepted_reads >= 4)) begin
                    if (ready_o || !busy_o)
                        fail_case("busy-start fixture was not resident");
                    command_id_i = 64'h1111_2222_3333_4444;
                    canonical_node_id_lo_i = 64'h5555_6666_7777_8888;
                    canonical_node_id_hi_i = 64'h9999_aaaa_bbbb_cccc;
                    reduce_op_i = 3'd7;
                    start_i = 1'b1;
                    @(posedge clk_i);
                    @(negedge clk_i);
                    start_i = 1'b0;
                    busy_start_sent = 1'b1;
                end
            end
            if (!completion_valid_o)
                fail_case("full success terminal timeout");
            if (!done_o || error_o || !dst_commit_o || poisoned_o)
                fail_case("full success terminal/commit");
            check_identity(expected_command, expected_lo, expected_hi,
                           PROFILE_SUM_ROWS, 32'd36);
            for (row = 0; row < ROWS; row = row + 1)
                if (get_word(DST_BASE + (row * 4)) !== expected_result[row])
                    fail_case($sformatf(
                        "ordered raw oracle row=%0d actual=%08x expected=%08x",
                        row, get_word(DST_BASE + (row * 4)),
                        expected_result[row]));
            if ((engine_flags_o != 5'h15)
                    || (rows_reduced_o != 64'(ROWS))
                    || (elements_processed_o != 64'(ELEMENTS))
                    || (reduction_operations_o != 64'(ELEMENTS))
                    || (results_generated_o != 64'(ROWS))
                    || (gmem_read_requests_o != 64'(READ_BEATS))
                    || (gmem_read_responses_o != 64'(READ_BEATS))
                    || (read_payload_bytes_o != 64'(SRC_BYTES))
                    || (gmem_write_requests_o != 64'(ROWS))
                    || (gmem_write_responses_o != 64'(ROWS))
                    || (write_payload_bytes_o != 64'(DST_BYTES))
                    || (widen_requests_o != 64'(ELEMENTS))
                    || (widen_responses_o != 64'(ELEMENTS))
                    || (add_requests_o != 64'(ELEMENTS))
                    || (add_responses_o != 64'(ELEMENTS))
                    || (narrow_requests_o != 64'(ROWS))
                    || (narrow_responses_o != 64'(ROWS))
                    || (engine_launches_o != 64'd1)
                    || (engine_terminals_o != 64'd1)
                    || (engine_active_cycles_o == 64'b0)
                    || (active_cycles_o == 64'b0))
                fail_case("full success exact cardinality");
            if ((accepted_reads != READ_BEATS) || (accepted_writes != ROWS)
                    || (response_count != (READ_BEATS + ROWS))
                    || (successful_writes != ROWS)
                    || (held_stability_cycles == 0) || !busy_start_sent)
                fail_case("independent full transport/backpressure census");
            if (engine_fault_valid_o
                    || (engine_first_fault_cycle_o != 64'b0)
                    || (engine_first_fault_coordinate_o != 128'b0)
                    || (engine_first_fault_gmem_addr_o != 64'b0))
                fail_case("success exposed a first fault");
            check_active_root_canary("full success");
            $display("[NPU-SUM-ROWS-WRITEBACK][FULL] nodes=36 profile=128x128x16x1 rows=%0d elements=%0d read=%0d/%0dB write=%0d/%0dB held=%0d flags=%02x cycles=%0d/%0d",
                     rows_reduced_o, elements_processed_o,
                     gmem_read_requests_o, read_payload_bytes_o,
                     gmem_write_requests_o, write_payload_bytes_o,
                     held_stability_cycles, engine_flags_o,
                     engine_active_cycles_o, active_cycles_o);
            finish_terminal_cycle("full success");
            if ((completion_count != 1) || (commit_count != 1))
                fail_case("full completion/commit pulse census");
        end
    endtask

    task automatic run_late_read_error;
        begin
            pulse_reset();
            set_valid_descriptor();
            set_bus_defaults();
            prepare_zero_vectors();
            inject_read_error_ordinal_q = 0;
            pulse_start();
            wait_terminal(256, "late read error");
            if (!error_o || dst_commit_o || (error_code_o != ERR_ENGINE)
                    || (engine_error_code_o != ENGINE_ERR_GMEM)
                    || (engine_launches_o != 64'd1)
                    || (engine_terminals_o != 64'd1)
                    || (gmem_read_requests_o != 64'd1)
                    || (gmem_read_responses_o != 64'd1)
                    || (read_payload_bytes_o != 64'b0)
                    || (gmem_write_requests_o != 64'b0)
                    || (rows_reduced_o != 64'b0)
                    || (elements_processed_o != 64'b0)
                    || (commit_count != 0))
                fail_case("late read error accounting/commit");
            check_identity(command_id_i, canonical_node_id_lo_i,
                           canonical_node_id_hi_i, PROFILE_SUM_ROWS, 32'd36);
            check_active_root_canary("late read error");
            finish_terminal_cycle("late read error");
        end
    endtask

    task automatic run_response_timeout_drain;
        begin
            pulse_reset();
            set_valid_descriptor();
            set_bus_defaults();
            prepare_zero_vectors();
            late_response_ordinal_q = 0;
            late_response_delay_q = STALL_TIMEOUT + 6;
            pulse_start();
            wait_terminal(512, "accepted response timeout");
            if (!error_o || dst_commit_o || (error_code_o != ERR_ENGINE)
                    || (engine_error_code_o != ENGINE_ERR_STALL)
                    || !engine_fault_valid_o || (drain_seen_count == 0)
                    || (gmem_read_requests_o != 64'd1)
                    || (gmem_read_responses_o != 64'd1)
                    || (read_payload_bytes_o != 64'b0)
                    || (engine_launches_o != 64'd1)
                    || (engine_terminals_o != 64'd1)
                    || (commit_count != 0))
                fail_case("accepted timeout/drain accounting");
            check_identity(command_id_i, canonical_node_id_lo_i,
                           canonical_node_id_hi_i, PROFILE_SUM_ROWS, 32'd36);
            check_active_root_canary("accepted timeout");
            finish_terminal_cycle("accepted response timeout");
        end
    endtask

    task automatic run_reset_abort;
        integer wait_cycles;
        begin
            pulse_reset();
            set_valid_descriptor();
            set_bus_defaults();
            prepare_zero_vectors();
            normal_response_delay_q = 40;
            pulse_start();
            wait_cycles = 0;
            while ((accepted_requests == 0) && (wait_cycles < 64)) begin
                @(negedge clk_i);
                wait_cycles = wait_cycles + 1;
            end
            if ((accepted_requests != 1) || !gmem_outstanding_o)
                fail_case("reset fixture did not accept one owner");
            rst_i = 1'b1;
            repeat (3) @(posedge clk_i);
            if (completion_valid_o || dst_commit_o)
                fail_case("reset emitted a terminal/commit");
            @(negedge clk_i);
            rst_i = 1'b0;
            repeat (2) @(negedge clk_i);
            if (!ready_o || busy_o || completion_valid_o
                    || gmem_outstanding_o || engine_outstanding_o
                    || (accepted_requests != 0) || (completion_count != 0)
                    || (commit_count != 0))
                fail_case("reset did not cancel resident transaction");
        end
    endtask

    task automatic run_late_write_error;
        integer address;
        begin
            pulse_reset();
            set_valid_descriptor();
            set_bus_defaults();
            prepare_zero_vectors();
            inject_write_error_ordinal_q = 1;
            pulse_start();
            wait_terminal(4000000, "late write error");
            if (!error_o || dst_commit_o || (error_code_o != ERR_ENGINE)
                    || (engine_error_code_o != ENGINE_ERR_GMEM)
                    || (rows_reduced_o != 64'(ROWS))
                    || (elements_processed_o != 64'(ELEMENTS))
                    || (reduction_operations_o != 64'(ELEMENTS))
                    || (results_generated_o != 64'(ROWS))
                    || (gmem_read_requests_o != 64'(READ_BEATS))
                    || (gmem_read_responses_o != 64'(READ_BEATS))
                    || (read_payload_bytes_o != 64'(SRC_BYTES))
                    || (gmem_write_requests_o != 64'd2)
                    || (gmem_write_responses_o != 64'd2)
                    || (write_payload_bytes_o != 64'd4)
                    || (engine_launches_o != 64'd1)
                    || (engine_terminals_o != 64'd1)
                    || (commit_count != 0))
                fail_case("late write failure accounting/commit");
            if ((get_word(DST_BASE) !== 32'h0000_0000)
                    || (get_word(DST_BASE + 4) !== 32'hc3c3_c3c3))
                fail_case("private prefix/error response model");
            for (address = 8; address < DST_BYTES; address = address + 1)
                if (gmem[DST_BASE + address] !== 8'hc3)
                    fail_case("write error changed unacknowledged private tail");
            check_identity(command_id_i, canonical_node_id_lo_i,
                           canonical_node_id_hi_i, PROFILE_SUM_ROWS, 32'd36);
            check_active_root_canary("late write error");
            $display("[NPU-SUM-ROWS-WRITEBACK][LATE-WRITE] private_prefix_bytes=%0d commit=%0d rows=%0d elements=%0d",
                     write_payload_bytes_o, commit_count,
                     rows_reduced_o, elements_processed_o);
            finish_terminal_cycle("late write error");
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

        // Exact descriptor and 128-bit capability/static rejects.  Every case
        // must complete with zero GMEM traffic and zero Engine launch.
        set_valid_descriptor(); reduce_op_i = 3'd7;
        run_static_reject(ERR_DESCRIPTOR, "unknown reduce subtype");
        set_valid_descriptor(); manifest_op_id_i = 16'd14;
        run_static_reject(ERR_DESCRIPTOR, "manifest op id");
        set_valid_descriptor(); source_arity_i = 3'd2;
        run_static_reject(ERR_DESCRIPTOR, "arity");
        set_valid_descriptor(); src0_dtype_i = 8'd1;
        run_static_reject(ERR_DESCRIPTOR, "source dtype");
        set_valid_descriptor(); dst_flags_i = 32'd0;
        run_static_reject(ERR_DESCRIPTOR, "destination flags");
        set_valid_descriptor(); src0_view_off_i = 64'd8;
        run_static_reject(ERR_DESCRIPTOR, "manifest view offset");
        set_valid_descriptor(); op_params_i = 128'd1;
        run_static_reject(ERR_DESCRIPTOR, "op params low128");
        set_valid_descriptor(); op_params_tail_zero_i = 1'b0;
        run_static_reject(ERR_DESCRIPTOR, "op params tail");
        set_valid_descriptor(); npu_required_i = 1'b0;
        run_static_reject(ERR_DESCRIPTOR, "required bit");
        set_valid_descriptor(); src0_nb2_i = 64'd65528;
        run_static_reject(ERR_DESCRIPTOR, "source stride");
        set_valid_descriptor(); dst_ne0_i = 32'd2;
        run_static_reject(ERR_DESCRIPTOR, "destination shape");
        set_valid_descriptor(); src0_window_read_i = 1'b0;
        run_static_reject(ERR_SRC0, "source permission");
        set_valid_descriptor(); src0_base_i = 64'hffff_ffff_ffff_fff8;
        src0_window_base_i = 64'hffff_ffff_ffff_fff8;
        src0_window_bytes_i = 64'd8;
        run_static_reject(ERR_SRC0, "source 128-bit overflow");
        set_valid_descriptor(); src1_window_bytes_i = 64'd8;
        run_static_reject(ERR_SRC1, "nonzero sentinel span");
        set_valid_descriptor(); src1_window_write_i = 1'b1;
        run_static_reject(ERR_SRC1, "sentinel permission");
        set_valid_descriptor(); dst_window_write_i = 1'b0;
        run_static_reject(ERR_DST, "destination permission");
        set_valid_descriptor(); dst_base_i = 64'hffff_ffff_ffff_fffc;
        dst_window_base_i = 64'hffff_ffff_ffff_fff8;
        dst_window_bytes_i = 64'd8;
        run_static_reject(ERR_DST, "destination 128-bit overflow");
        set_valid_descriptor(); dst_base_i = 64'd4;
        dst_window_base_i = 64'd0;
        dst_window_bytes_i = 64'(SRC_BYTES);
        run_static_reject(ERR_ALIAS, "aligned physical alias");
        $display("[NPU-SUM-ROWS-WRITEBACK][STATIC] exact descriptor/capability rejects=18 zero-traffic");

        run_reset_abort();
        run_late_read_error();
        run_response_timeout_drain();
        run_full_success();
        run_late_write_error();

        $display("[NPU-SUM-ROWS-WRITEBACK][PASS] frozen_nodes=36 profiles=1 full_oracle=1 static=18 reset=1 late_read=1 timeout_drain=1 late_write=1 backpressure=1 busy=1");
        $finish;
    end

endmodule

`default_nettype wire
