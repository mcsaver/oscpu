`timescale 1ns/1ps
`default_nettype none

// Self-checking raw-bit verification for the LANES=16 production portal.
// The portal model performs only four-byte loads/stores at RTL-issued
// addresses.  Tensor-coordinate arithmetic appears solely in the independent
// software oracle checks after a command reaches its terminal pulse.
module tb_f32_gather_repeat_portal_adapter;

    /* verilator lint_off WIDTHTRUNC */
    /* verilator lint_off WIDTHEXPAND */
    /* verilator lint_off BLKSEQ */

    localparam integer LANES = 16;
    localparam integer MEM_BYTES = 65536;
    localparam integer MAX_WAIT_CYCLES = 20000;

    localparam OP_GET_ROWS_F32 = 1'b0;
    localparam OP_REPEAT_F32   = 1'b1;
    localparam [31:0] KERNEL_GET_ROWS = 32'h514e0003;
    localparam [31:0] KERNEL_REPEAT   = 32'h514e0004;

    localparam [4:0] ERR_ALIAS        = 5'd5;
    localparam [4:0] ERR_INDEX_RANGE  = 5'd6;
    localparam [4:0] ERR_PORTAL       = 5'd7;

    localparam [63:0] SRC_WINDOW_BASE = 64'h0000_0000_0000_1000;
    localparam [63:0] SRC_WINDOW_SIZE = 64'h0000_0000_0000_2000;
    localparam [63:0] GET_SRC_BASE    = 64'h0000_0000_0000_1104;
    localparam [63:0] REP_SRC_BASE    = 64'h0000_0000_0000_2104;
    localparam [63:0] INDEX_WINDOW_BASE = 64'h0000_0000_0000_3000;
    localparam [63:0] INDEX_WINDOW_SIZE = 64'h0000_0000_0000_0800;
    localparam [63:0] GET_INDEX_BASE  = 64'h0000_0000_0000_3104;
    localparam [63:0] DST_WINDOW_BASE = 64'h0000_0000_0000_4000;
    localparam [63:0] DST_WINDOW_SIZE = 64'h0000_0000_0000_4000;
    localparam [63:0] GET_DST_BASE    = 64'h0000_0000_0000_4104;
    localparam [63:0] REP_DST_BASE    = 64'h0000_0000_0000_5104;

    localparam integer GET_ELEMENTS = 19;
    localparam integer GET_SOURCE_ROWS = 6;
    localparam integer GET_INDICES = 5;
    localparam integer GET_SRC_STRIDE = 88;
    localparam integer GET_INDEX_STRIDE = 8;
    localparam integer GET_DST_STRIDE = 84;

    localparam integer REP_ELEMENTS = 18;
    localparam integer REP_OUTER = 3;
    localparam integer REP_COUNT = 4;
    localparam integer REP_SRC_STRIDE = 80;
    localparam integer REP_DST_STRIDE = 76;
    localparam integer REP_DST_OUTER_STRIDE = 320;

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
    reg gmem_req_ready_i;
    wire gmem_req_write_o;
    wire [63:0] gmem_req_addr_o;
    wire [63:0] gmem_req_wdata_o;
    wire [7:0] gmem_req_wstrb_o;
    reg gmem_rsp_valid_i;
    wire gmem_rsp_ready_o;
    reg [63:0] gmem_rsp_rdata_i;
    reg gmem_rsp_error_i;

    wire portal_req_valid_o;
    wire portal_req_ready_i;
    wire portal_req_write_o;
    wire [LANES-1:0] portal_req_mask_o;
    wire [(LANES*64)-1:0] portal_req_addr_o;
    wire [(LANES*32)-1:0] portal_req_wdata_o;
    reg portal_rsp_valid_i;
    wire portal_rsp_ready_o;
    reg [LANES-1:0] portal_rsp_mask_i;
    reg [(LANES*32)-1:0] portal_rsp_rdata_i;
    reg portal_rsp_error_i;

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
    wire [63:0] portal_request_groups_o;
    wire [63:0] portal_response_groups_o;
    wire [63:0] portal_read_groups_o;
    wire [63:0] portal_write_groups_o;
    wire [63:0] portal_read_words_o;
    wire [63:0] portal_write_words_o;
    wire [63:0] portal_read_bytes_o;
    wire [63:0] portal_write_bytes_o;
    wire portal_outstanding_o;
    wire [63:0] gmem_read_beats_o;
    wire [63:0] gmem_read_responses_o;
    wire [63:0] read_payload_bytes_o;
    wire [63:0] gmem_write_beats_o;
    wire [63:0] gmem_write_responses_o;
    wire [63:0] write_payload_bytes_o;
    wire [63:0] expected_gmem_read_bytes_o;
    wire [63:0] expected_gmem_write_bytes_o;
    wire [63:0] active_cycles_o;
    wire gmem_outstanding_o;

    TensorNpuF32GatherRepeatPortalAdapter #(
        .LANES(LANES),
        .MAX_ELEMENTS(262144),
        .MAX_INDICES(16),
        .MAX_REPEAT(128),
        .MAX_OUTER(16),
        .STALL_TIMEOUT_CYCLES(32'd32),
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
        .portal_req_valid_o(portal_req_valid_o),
        .portal_req_ready_i(portal_req_ready_i),
        .portal_req_write_o(portal_req_write_o),
        .portal_req_mask_o(portal_req_mask_o),
        .portal_req_addr_o(portal_req_addr_o),
        .portal_req_wdata_o(portal_req_wdata_o),
        .portal_rsp_valid_i(portal_rsp_valid_i),
        .portal_rsp_ready_o(portal_rsp_ready_o),
        .portal_rsp_mask_i(portal_rsp_mask_i),
        .portal_rsp_rdata_i(portal_rsp_rdata_i),
        .portal_rsp_error_i(portal_rsp_error_i),
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
        .portal_request_groups_o(portal_request_groups_o),
        .portal_response_groups_o(portal_response_groups_o),
        .portal_read_groups_o(portal_read_groups_o),
        .portal_write_groups_o(portal_write_groups_o),
        .portal_read_words_o(portal_read_words_o),
        .portal_write_words_o(portal_write_words_o),
        .portal_read_bytes_o(portal_read_bytes_o),
        .portal_write_bytes_o(portal_write_bytes_o),
        .portal_outstanding_o(portal_outstanding_o),
        .gmem_read_beats_o(gmem_read_beats_o),
        .gmem_read_responses_o(gmem_read_responses_o),
        .read_payload_bytes_o(read_payload_bytes_o),
        .gmem_write_beats_o(gmem_write_beats_o),
        .gmem_write_responses_o(gmem_write_responses_o),
        .write_payload_bytes_o(write_payload_bytes_o),
        .expected_gmem_read_bytes_o(expected_gmem_read_bytes_o),
        .expected_gmem_write_bytes_o(expected_gmem_write_bytes_o),
        .active_cycles_o(active_cycles_o),
        .gmem_outstanding_o(gmem_outstanding_o)
    );

    initial clk_i = 1'b0;
    always #5 clk_i <= ~clk_i;

    reg [7:0] memory [0:MEM_BYTES-1];
    integer global_cycles;
    integer checks;
    integer accepted_commands;
    integer busy_start_attempts;
    integer commit_pulses;
    integer accepted_requests;
    integer accepted_responses;
    integer accepted_read_groups;
    integer accepted_write_groups;
    integer accepted_read_words;
    integer accepted_write_words;
    integer request_backpressure_cycles;
    integer response_backpressure_cycles;
    integer partial_group_count;

    function automatic [31:0] load32(input [63:0] address);
        begin
            load32 = {memory[address+3], memory[address+2],
                      memory[address+1], memory[address+0]};
        end
    endfunction

    task automatic store32(input [63:0] address, input [31:0] data);
        begin
            memory[address+0] = data[7:0];
            memory[address+1] = data[15:8];
            memory[address+2] = data[23:16];
            memory[address+3] = data[31:24];
        end
    endtask

    function automatic [31:0] get_source_pattern(
        input integer row,
        input integer element
    );
        begin
            get_source_pattern = 32'h8100_0000
                               ^ (row * 32'h0001_0101)
                               ^ (element * 32'h0000_1003);
        end
    endfunction

    function automatic [31:0] repeat_source_pattern(
        input integer outer,
        input integer element
    );
        begin
            repeat_source_pattern = 32'h7f40_0001
                                  ^ (outer * 32'h0010_0101)
                                  ^ (element * 32'h0000_2005);
        end
    endfunction

    function automatic integer count_mask(input [LANES-1:0] mask);
        integer lane;
        begin
            count_mask = 0;
            for (lane = 0; lane < LANES; lane = lane + 1)
                count_mask = count_mask + mask[lane];
        end
    endfunction

    task automatic fail(input string reason);
        begin
            $display("[NPU-F32-GATHER-REPEAT-PORTAL][FAIL] %s cycle=%0d state=%0d req=%0d/%0d groups=%0d/%0d/%0d/%0d words=%0d/%0d out=%0b commit=%0d",
                     reason, global_cycles, dut.state_q,
                     accepted_requests, accepted_responses,
                     portal_request_groups_o, portal_response_groups_o,
                     portal_read_groups_o, portal_write_groups_o,
                     portal_read_words_o, portal_write_words_o,
                     portal_outstanding_o, commit_pulses);
            $fatal(1);
        end
    endtask

    // ------------------------------------------------------------------
    // Raw portal memory model.  This block performs no tensor operation: it
    // only copies raw32 at active addresses supplied by RTL.
    // ------------------------------------------------------------------
    reg allow_portal_requests_q;
    reg request_backpressure_enable_q;
    integer inject_wrong_mask_ordinal_q;
    integer command_request_ordinal_q;
    reg pending_q;
    reg pending_write_q;
    reg [LANES-1:0] pending_mask_q;
    reg [(LANES*64)-1:0] pending_addr_q;
    reg [(LANES*32)-1:0] pending_wdata_q;
    integer pending_delay_q;
    integer pending_ordinal_q;

    reg req_hold_q;
    reg req_held_write_q;
    reg [LANES-1:0] req_held_mask_q;
    reg [(LANES*64)-1:0] req_held_addr_q;
    reg [(LANES*32)-1:0] req_held_wdata_q;
    reg rsp_hold_q;
    reg [LANES-1:0] rsp_held_mask_q;
    reg [(LANES*32)-1:0] rsp_held_rdata_q;
    reg rsp_held_error_q;

    assign portal_req_ready_i = !rst_i && allow_portal_requests_q
                              && !pending_q && !portal_rsp_valid_i
                              && (!request_backpressure_enable_q
                                  || (global_cycles[2:0] != 3'd3));

    integer model_lane;
    integer active_words_r;
    reg [63:0] model_addr_r;
    reg [LANES-1:0] expected_low_mask_r;
    always @(posedge clk_i) begin
        global_cycles <= global_cycles + 1;
        if (rst_i) begin
            portal_rsp_valid_i <= 1'b0;
            portal_rsp_mask_i <= {LANES{1'b0}};
            portal_rsp_rdata_i <= {(LANES*32){1'b0}};
            portal_rsp_error_i <= 1'b0;
            pending_q <= 1'b0;
            pending_write_q <= 1'b0;
            pending_mask_q <= {LANES{1'b0}};
            pending_addr_q <= {(LANES*64){1'b0}};
            pending_wdata_q <= {(LANES*32){1'b0}};
            pending_delay_q <= 0;
            pending_ordinal_q <= 0;
            command_request_ordinal_q <= 0;
            req_hold_q <= 1'b0;
            rsp_hold_q <= 1'b0;
            accepted_commands <= 0;
            busy_start_attempts <= 0;
            commit_pulses <= 0;
            accepted_requests <= 0;
            accepted_responses <= 0;
            accepted_read_groups <= 0;
            accepted_write_groups <= 0;
            accepted_read_words <= 0;
            accepted_write_words <= 0;
            request_backpressure_cycles <= 0;
            response_backpressure_cycles <= 0;
            partial_group_count <= 0;
        end else begin
            if (start_i && ready_o) begin
                accepted_commands <= accepted_commands + 1;
                command_request_ordinal_q <= 0;
            end else if (start_i && !ready_o) begin
                busy_start_attempts <= busy_start_attempts + 1;
            end
            if (dst_commit_o)
                commit_pulses <= commit_pulses + 1;

            if (gmem_req_valid_o || gmem_req_write_o
                    || (gmem_req_addr_o != 64'b0)
                    || (gmem_req_wdata_o != 64'b0)
                    || (gmem_req_wstrb_o != 8'b0)
                    || gmem_rsp_ready_o
                    || (gmem_read_beats_o != 64'b0)
                    || (gmem_read_responses_o != 64'b0)
                    || (read_payload_bytes_o != 64'b0)
                    || (gmem_write_beats_o != 64'b0)
                    || (gmem_write_responses_o != 64'b0)
                    || (write_payload_bytes_o != 64'b0)
                    || (expected_gmem_read_bytes_o != 64'b0)
                    || (expected_gmem_write_bytes_o != 64'b0)
                    || gmem_outstanding_o)
                fail("portal branch exposed a nonzero raw-GMEM signal");

            if (portal_req_valid_o && !portal_req_ready_i) begin
                request_backpressure_cycles
                    <= request_backpressure_cycles + 1;
                if (!req_hold_q) begin
                    req_hold_q <= 1'b1;
                    req_held_write_q <= portal_req_write_o;
                    req_held_mask_q <= portal_req_mask_o;
                    req_held_addr_q <= portal_req_addr_o;
                    req_held_wdata_q <= portal_req_wdata_o;
                end else if ((req_held_write_q != portal_req_write_o)
                        || (req_held_mask_q != portal_req_mask_o)
                        || (req_held_addr_q != portal_req_addr_o)
                        || (req_held_wdata_q != portal_req_wdata_o)) begin
                    fail("portal request payload changed under backpressure");
                end
            end else if (req_hold_q) begin
                if (!(portal_req_valid_o && portal_req_ready_i))
                    fail("portal request retracted before handshake");
                req_hold_q <= 1'b0;
            end

            if (portal_rsp_valid_i && !portal_rsp_ready_o) begin
                response_backpressure_cycles
                    <= response_backpressure_cycles + 1;
                if (!rsp_hold_q) begin
                    rsp_hold_q <= 1'b1;
                    rsp_held_mask_q <= portal_rsp_mask_i;
                    rsp_held_rdata_q <= portal_rsp_rdata_i;
                    rsp_held_error_q <= portal_rsp_error_i;
                end else if ((rsp_held_mask_q != portal_rsp_mask_i)
                        || (rsp_held_rdata_q != portal_rsp_rdata_i)
                        || (rsp_held_error_q != portal_rsp_error_i)) begin
                    fail("portal response payload changed under backpressure");
                end
            end else if (rsp_hold_q) begin
                if (!(portal_rsp_valid_i && portal_rsp_ready_o))
                    fail("portal response retracted before handshake");
                rsp_hold_q <= 1'b0;
            end

            if (portal_req_valid_o && portal_req_ready_i) begin
                active_words_r = count_mask(portal_req_mask_o);
                if ((active_words_r < 1) || (active_words_r > LANES))
                    fail("portal request has empty/oversized mask");
                expected_low_mask_r = {LANES{1'b0}};
                for (model_lane = 0; model_lane < active_words_r;
                     model_lane = model_lane + 1)
                    expected_low_mask_r[model_lane] = 1'b1;
                if (portal_req_mask_o != expected_low_mask_r)
                    fail("portal request mask is not an exact low-lane tail");
                if (active_words_r != LANES)
                    partial_group_count <= partial_group_count + 1;

                for (model_lane = 0; model_lane < LANES;
                     model_lane = model_lane + 1) begin
                    model_addr_r = portal_req_addr_o[
                        (model_lane*64) +: 64];
                    if (portal_req_mask_o[model_lane]) begin
                        if ((model_addr_r[1:0] != 2'b00)
                                || ((model_addr_r + 64'd4)
                                    > MEM_BYTES))
                            fail("portal raw32 address invalid");
                        if (portal_req_write_o) begin
                            if ((model_addr_r < DST_WINDOW_BASE)
                                    || ((model_addr_r + 64'd4)
                                        > (DST_WINDOW_BASE
                                           + DST_WINDOW_SIZE)))
                                fail("portal write escaped destination");
                        end else begin
                            if (!(((model_addr_r >= SRC_WINDOW_BASE)
                                   && ((model_addr_r + 64'd4)
                                       <= (SRC_WINDOW_BASE
                                           + SRC_WINDOW_SIZE)))
                                  || ((model_addr_r
                                       >= INDEX_WINDOW_BASE)
                                      && ((model_addr_r + 64'd4)
                                          <= (INDEX_WINDOW_BASE
                                              + INDEX_WINDOW_SIZE)))))
                                fail("portal read escaped source/index");
                            if (portal_req_wdata_o[
                                    (model_lane*32) +: 32] != 32'b0)
                                fail("portal read carried write data");
                        end
                    end else if ((model_addr_r != 64'b0)
                            || (portal_req_wdata_o[
                                (model_lane*32) +: 32] != 32'b0)) begin
                        fail("inactive portal lane payload was nonzero");
                    end
                end

                pending_q <= 1'b1;
                pending_write_q <= portal_req_write_o;
                pending_mask_q <= portal_req_mask_o;
                pending_addr_q <= portal_req_addr_o;
                pending_wdata_q <= portal_req_wdata_o;
                pending_delay_q <= (accepted_requests % 3) + 1;
                pending_ordinal_q <= command_request_ordinal_q + 1;
                command_request_ordinal_q
                    <= command_request_ordinal_q + 1;
                accepted_requests <= accepted_requests + 1;
                if (portal_req_write_o) begin
                    accepted_write_groups <= accepted_write_groups + 1;
                end else begin
                    accepted_read_groups <= accepted_read_groups + 1;
                end
            end

            if (pending_q && !portal_rsp_valid_i) begin
                if (pending_delay_q > 0) begin
                    pending_delay_q <= pending_delay_q - 1;
                end else begin
                    pending_q <= 1'b0;
                    portal_rsp_valid_i <= 1'b1;
                    portal_rsp_mask_i <=
                        (pending_ordinal_q == inject_wrong_mask_ordinal_q)
                        ? (pending_mask_q
                           ^ {{(LANES-1){1'b0}}, 1'b1})
                        : pending_mask_q;
                    portal_rsp_rdata_i <= {(LANES*32){1'b0}};
                    for (model_lane = 0; model_lane < LANES;
                         model_lane = model_lane + 1) begin
                        if (pending_mask_q[model_lane]
                                && !pending_write_q) begin
                            portal_rsp_rdata_i[(model_lane*32) +: 32]
                                <= load32(pending_addr_q[
                                    (model_lane*64) +: 64]);
                        end
                    end
                    portal_rsp_error_i <= 1'b0;
                end
            end

            if (portal_rsp_valid_i && portal_rsp_ready_o) begin
                accepted_responses <= accepted_responses + 1;
                if (pending_write_q
                        && (pending_ordinal_q
                            != inject_wrong_mask_ordinal_q)
                        && !portal_rsp_error_i) begin
                    for (model_lane = 0; model_lane < LANES;
                         model_lane = model_lane + 1) begin
                        if (pending_mask_q[model_lane]) begin
                            store32(pending_addr_q[
                                        (model_lane*64) +: 64],
                                    pending_wdata_q[
                                        (model_lane*32) +: 32]);
                        end
                    end
                    accepted_write_words <= accepted_write_words
                        + count_mask(pending_mask_q);
                end else if (!pending_write_q
                        && (pending_ordinal_q
                            != inject_wrong_mask_ordinal_q)
                        && !portal_rsp_error_i) begin
                    accepted_read_words <= accepted_read_words
                        + count_mask(pending_mask_q);
                end
                portal_rsp_valid_i <= 1'b0;
            end
        end
    end

    integer init_byte;
    integer init_row;
    integer init_element;
    integer init_outer;
    integer get_index_values [0:GET_INDICES-1];

    task automatic initialize_memory;
        begin
            for (init_byte = 0; init_byte < MEM_BYTES;
                 init_byte = init_byte + 1)
                memory[init_byte] = 8'hc7;
            for (init_row = 0; init_row < GET_SOURCE_ROWS;
                 init_row = init_row + 1) begin
                for (init_element = 0; init_element < GET_ELEMENTS;
                     init_element = init_element + 1) begin
                    store32(GET_SRC_BASE + init_row*GET_SRC_STRIDE
                            + init_element*4,
                            get_source_pattern(init_row, init_element));
                end
            end
            get_index_values[0] = 4;
            get_index_values[1] = 1;
            get_index_values[2] = 5;
            get_index_values[3] = 0;
            get_index_values[4] = 3;
            for (init_row = 0; init_row < GET_INDICES;
                 init_row = init_row + 1)
                store32(GET_INDEX_BASE + init_row*GET_INDEX_STRIDE,
                        get_index_values[init_row]);
            for (init_outer = 0; init_outer < REP_OUTER;
                 init_outer = init_outer + 1) begin
                for (init_element = 0; init_element < REP_ELEMENTS;
                     init_element = init_element + 1) begin
                    store32(REP_SRC_BASE + init_outer*REP_SRC_STRIDE
                            + init_element*4,
                            repeat_source_pattern(init_outer,
                                                  init_element));
                end
            end
        end
    endtask

    task automatic fill_get_destination(input [31:0] value);
        integer row;
        integer element;
        begin
            for (row = 0; row < GET_INDICES; row = row + 1) begin
                for (element = 0; element < GET_ELEMENTS;
                     element = element + 1)
                    store32(GET_DST_BASE + row*GET_DST_STRIDE
                            + element*4, value);
            end
        end
    endtask

    task automatic fill_repeat_destination(input [31:0] value);
        integer outer;
        integer repeat_index;
        integer element;
        begin
            for (outer = 0; outer < REP_OUTER; outer = outer + 1) begin
                for (repeat_index = 0; repeat_index < REP_COUNT;
                     repeat_index = repeat_index + 1) begin
                    for (element = 0; element < REP_ELEMENTS;
                         element = element + 1)
                        store32(REP_DST_BASE
                                + outer*REP_DST_OUTER_STRIDE
                                + repeat_index*REP_DST_STRIDE
                                + element*4, value);
                end
            end
        end
    endtask

    task automatic configure_get(input [63:0] command_value);
        begin
            operation_i = OP_GET_ROWS_F32;
            npu_required_i = 1'b1;
            command_id_i = command_value;
            canonical_node_id_lo_i = 64'h0606_0000_0000_0000
                                   | command_value;
            canonical_node_id_hi_i = 64'h1212_0000_0000_0000
                                   | command_value;
            dst_shadow_private_i = 1'b1;
            windows_generation_valid_i = 1'b1;
            src_base_i = GET_SRC_BASE;
            index_base_i = GET_INDEX_BASE;
            dst_base_i = GET_DST_BASE;
            element_count_i = GET_ELEMENTS;
            source_row_count_i = GET_SOURCE_ROWS;
            index_count_i = GET_INDICES;
            outer_count_i = 32'b0;
            repeat_count_i = 32'b0;
            src_row_stride_i = GET_SRC_STRIDE;
            index_stride_i = GET_INDEX_STRIDE;
            dst_row_stride_i = GET_DST_STRIDE;
            dst_outer_stride_i = 64'b0;
            src_window_base_i = SRC_WINDOW_BASE;
            src_window_bytes_i = SRC_WINDOW_SIZE;
            src_window_read_i = 1'b1;
            src_window_write_i = 1'b0;
            index_window_base_i = INDEX_WINDOW_BASE;
            index_window_bytes_i = INDEX_WINDOW_SIZE;
            index_window_read_i = 1'b1;
            index_window_write_i = 1'b0;
            dst_window_base_i = DST_WINDOW_BASE;
            dst_window_bytes_i = DST_WINDOW_SIZE;
            dst_window_read_i = 1'b0;
            dst_window_write_i = 1'b1;
        end
    endtask

    task automatic configure_repeat(input [63:0] command_value);
        begin
            operation_i = OP_REPEAT_F32;
            npu_required_i = 1'b1;
            command_id_i = command_value;
            canonical_node_id_lo_i = 64'h0606_1000_0000_0000
                                   | command_value;
            canonical_node_id_hi_i = 64'h1212_1000_0000_0000
                                   | command_value;
            dst_shadow_private_i = 1'b1;
            windows_generation_valid_i = 1'b1;
            src_base_i = REP_SRC_BASE;
            index_base_i = 64'b0;
            dst_base_i = REP_DST_BASE;
            element_count_i = REP_ELEMENTS;
            source_row_count_i = 32'b0;
            index_count_i = 32'b0;
            outer_count_i = REP_OUTER;
            repeat_count_i = REP_COUNT;
            src_row_stride_i = REP_SRC_STRIDE;
            index_stride_i = 64'b0;
            dst_row_stride_i = REP_DST_STRIDE;
            dst_outer_stride_i = REP_DST_OUTER_STRIDE;
            src_window_base_i = SRC_WINDOW_BASE;
            src_window_bytes_i = SRC_WINDOW_SIZE;
            src_window_read_i = 1'b1;
            src_window_write_i = 1'b0;
            index_window_base_i = 64'b0;
            index_window_bytes_i = 64'b0;
            index_window_read_i = 1'b1;
            index_window_write_i = 1'b0;
            dst_window_base_i = DST_WINDOW_BASE;
            dst_window_bytes_i = DST_WINDOW_SIZE;
            dst_window_read_i = 1'b0;
            dst_window_write_i = 1'b1;
        end
    endtask

    task automatic poison_descriptor;
        begin
            operation_i = OP_GET_ROWS_F32;
            npu_required_i = 1'b0;
            command_id_i = 64'hffff_ffff_ffff_ffff;
            canonical_node_id_lo_i = 64'b0;
            canonical_node_id_hi_i = 64'b0;
            dst_shadow_private_i = 1'b0;
            windows_generation_valid_i = 1'b0;
            src_base_i = 64'hffff_ffff_ffff_fffc;
            index_base_i = 64'hffff_ffff_ffff_fffc;
            dst_base_i = 64'hffff_ffff_ffff_fffc;
            element_count_i = 32'hffff_ffff;
            source_row_count_i = 32'hffff_ffff;
            index_count_i = 32'hffff_ffff;
            outer_count_i = 32'hffff_ffff;
            repeat_count_i = 32'hffff_ffff;
            src_row_stride_i = 64'hffff_ffff_ffff_fffc;
            index_stride_i = 64'hffff_ffff_ffff_fffc;
            dst_row_stride_i = 64'hffff_ffff_ffff_fffc;
            dst_outer_stride_i = 64'hffff_ffff_ffff_fffc;
            src_window_base_i = 64'hffff_ffff_ffff_fff8;
            src_window_bytes_i = 64'hffff_ffff_ffff_fff8;
            src_window_read_i = 1'b0;
            src_window_write_i = 1'b1;
            index_window_base_i = 64'hffff_ffff_ffff_fff8;
            index_window_bytes_i = 64'hffff_ffff_ffff_fff8;
            index_window_read_i = 1'b0;
            index_window_write_i = 1'b1;
            dst_window_base_i = 64'hffff_ffff_ffff_fff8;
            dst_window_bytes_i = 64'hffff_ffff_ffff_fff8;
            dst_window_read_i = 1'b1;
            dst_window_write_i = 1'b0;
        end
    endtask

    reg [63:0] expected_command_q;
    reg [63:0] expected_node_lo_q;
    reg [63:0] expected_node_hi_q;
    reg expected_operation_q;
    task automatic execute_command(
        input bit expect_error,
        input [4:0] expected_error,
        input bit inject_busy_start
    );
        integer waited;
        begin
            expected_command_q = command_id_i;
            expected_node_lo_q = canonical_node_id_lo_i;
            expected_node_hi_q = canonical_node_id_hi_i;
            expected_operation_q = operation_i;
            // Drive start only from a negedge so it is sampled exactly once;
            // callers may otherwise enter this task from a posedge event.
            @(negedge clk_i);
            while (!ready_o) @(negedge clk_i);
            start_i = 1'b1;
            @(posedge clk_i);
            @(negedge clk_i);
            start_i = 1'b0;
            if (inject_busy_start) begin
                command_id_i = 64'hbad0_bad0_bad0_bad0;
                canonical_node_id_lo_i = 64'hbad1_bad1_bad1_bad1;
                canonical_node_id_hi_i = 64'hbad2_bad2_bad2_bad2;
                start_i = 1'b1;
                @(posedge clk_i);
                @(negedge clk_i);
                start_i = 1'b0;
            end
            poison_descriptor();

            waited = 0;
            while (!completion_valid_o && (waited < MAX_WAIT_CYCLES)) begin
                @(negedge clk_i);
                waited = waited + 1;
            end
            if (!completion_valid_o)
                fail("timed out waiting for completion");
            checks = checks + 1;
            if ((done_o != !expect_error)
                    || (error_o != expect_error)
                    || (dst_commit_o != !expect_error)
                    || (error_code_o != expected_error)
                    || (completion_command_id_o != expected_command_q)
                    || (completion_canonical_node_id_lo_o
                        != expected_node_lo_q)
                    || (completion_canonical_node_id_hi_o
                        != expected_node_hi_q)
                    || !completion_npu_required_o
                    || (completion_operation_o != expected_operation_q)
                    || (completion_kernel_id_o
                        != (expected_operation_q
                            ? KERNEL_REPEAT : KERNEL_GET_ROWS))
                    || portal_outstanding_o
                    || gmem_outstanding_o
                    || (portal_request_groups_o
                        != portal_response_groups_o)
                    || (portal_request_groups_o
                        != (portal_read_groups_o
                            + portal_write_groups_o))
                    || (portal_read_bytes_o
                        != (portal_read_words_o * 64'd4))
                    || (portal_write_bytes_o
                        != (portal_write_words_o * 64'd4))
                    || (active_cycles_o == 64'b0))
                fail("terminal identity/closure mismatch");
            @(posedge clk_i);
            @(negedge clk_i);
            if (completion_valid_o || busy_o || !ready_o)
                fail("terminal pulse failed to return to idle");
        end
    endtask

    integer oracle_row;
    integer oracle_element;
    integer oracle_outer;
    integer oracle_repeat;
    integer before_requests;
    integer before_responses;
    integer before_reads;
    integer before_writes;
    integer before_read_words;
    integer before_write_words;
    integer before_backpressure;
    integer before_partial;
    integer before_commits;
    integer before_busy_attempts;
    initial begin
        global_cycles = 0;
        checks = 0;
        rst_i = 1'b1;
        start_i = 1'b0;
        gmem_req_ready_i = 1'b1;
        gmem_rsp_valid_i = 1'b1;
        gmem_rsp_rdata_i = 64'h0123_4567_89ab_cdef;
        gmem_rsp_error_i = 1'b1;
        portal_rsp_valid_i = 1'b0;
        portal_rsp_mask_i = {LANES{1'b0}};
        portal_rsp_rdata_i = {(LANES*32){1'b0}};
        portal_rsp_error_i = 1'b0;
        allow_portal_requests_q = 1'b1;
        request_backpressure_enable_q = 1'b1;
        inject_wrong_mask_ordinal_q = -1;
        initialize_memory();
        poison_descriptor();
        repeat (5) @(posedge clk_i);
        @(negedge clk_i);
        rst_i = 1'b0;
        repeat (2) @(posedge clk_i);

        // GET_ROWS: five selected rows, D=19 produces a 16+3 data tail; all
        // five I32 indices share one 5-lane portal group.
        fill_get_destination(32'hdead_beef);
        configure_get(64'h0000_0000_0000_0601);
        before_requests = accepted_requests;
        before_responses = accepted_responses;
        before_reads = accepted_read_groups;
        before_writes = accepted_write_groups;
        before_read_words = accepted_read_words;
        before_write_words = accepted_write_words;
        before_backpressure = request_backpressure_cycles;
        before_partial = partial_group_count;
        before_commits = commit_pulses;
        before_busy_attempts = busy_start_attempts;
        execute_command(1'b0, 5'd0, 1'b1);
        checks = checks + 1;
        if ((portal_request_groups_o != 64'd21)
                || (portal_response_groups_o != 64'd21)
                || (portal_read_groups_o != 64'd11)
                || (portal_write_groups_o != 64'd10)
                || (portal_read_words_o != 64'd100)
                || (portal_write_words_o != 64'd95)
                || (portal_read_bytes_o != 64'd400)
                || (portal_write_bytes_o != 64'd380)
                || (indices_completed_o != 64'd5)
                || (source_words_completed_o != 64'd95)
                || (elements_completed_o != 64'd95)
                || (accepted_requests-before_requests != 21)
                || (accepted_responses-before_responses != 21)
                || (accepted_read_groups-before_reads != 11)
                || (accepted_write_groups-before_writes != 10)
                || (accepted_read_words-before_read_words != 100)
                || (accepted_write_words-before_write_words != 95)
                || (request_backpressure_cycles-before_backpressure == 0)
                || (partial_group_count-before_partial == 0)
                || (commit_pulses-before_commits != 1)
                || (busy_start_attempts-before_busy_attempts != 1))
            fail("GET_ROWS portal ledger/backpressure mismatch");
        for (oracle_row = 0; oracle_row < GET_INDICES;
             oracle_row = oracle_row + 1) begin
            for (oracle_element = 0; oracle_element < GET_ELEMENTS;
                 oracle_element = oracle_element + 1) begin
                if (load32(GET_DST_BASE + oracle_row*GET_DST_STRIDE
                           + oracle_element*4)
                        !== load32(GET_SRC_BASE
                            + get_index_values[oracle_row]*GET_SRC_STRIDE
                            + oracle_element*4))
                    fail("GET_ROWS software oracle raw-bit mismatch");
            end
        end

        // GET_ROWS index range error: the entire raw index group completes,
        // but no source or destination group may be issued or published.
        fill_get_destination(32'hca11_ab1e);
        store32(GET_INDEX_BASE + 2*GET_INDEX_STRIDE, GET_SOURCE_ROWS);
        configure_get(64'h0000_0000_0000_0602);
        before_requests = accepted_requests;
        before_responses = accepted_responses;
        before_writes = accepted_write_groups;
        before_commits = commit_pulses;
        execute_command(1'b1, ERR_INDEX_RANGE, 1'b0);
        checks = checks + 1;
        if ((portal_request_groups_o != 64'd1)
                || (portal_response_groups_o != 64'd1)
                || (portal_read_groups_o != 64'd1)
                || (portal_write_groups_o != 64'd0)
                || (portal_read_words_o != 64'd5)
                || (portal_read_bytes_o != 64'd20)
                || (portal_write_words_o != 64'd0)
                || (indices_completed_o != 64'd5)
                || (source_words_completed_o != 64'd0)
                || (elements_completed_o != 64'd0)
                || (accepted_requests-before_requests != 1)
                || (accepted_responses-before_responses != 1)
                || (accepted_write_groups != before_writes)
                || (commit_pulses != before_commits))
            fail("GET_ROWS index-range atomic error mismatch");
        for (oracle_row = 0; oracle_row < GET_INDICES;
             oracle_row = oracle_row + 1) begin
            for (oracle_element = 0; oracle_element < GET_ELEMENTS;
                 oracle_element = oracle_element + 1) begin
                if (load32(GET_DST_BASE + oracle_row*GET_DST_STRIDE
                           + oracle_element*4) !== 32'hca11_ab1e)
                    fail("GET_ROWS index error changed destination");
            end
        end
        store32(GET_INDEX_BASE + 2*GET_INDEX_STRIDE, 5);

        // Exact response mask is resident-request identity.  A mismatch is a
        // protocol response error with no accepted payload or publication.
        fill_get_destination(32'h1357_9bdf);
        configure_get(64'h0000_0000_0000_0603);
        inject_wrong_mask_ordinal_q = 1;
        before_requests = accepted_requests;
        before_responses = accepted_responses;
        before_commits = commit_pulses;
        execute_command(1'b1, ERR_PORTAL, 1'b0);
        inject_wrong_mask_ordinal_q = -1;
        checks = checks + 1;
        if ((portal_request_groups_o != 64'd1)
                || (portal_response_groups_o != 64'd1)
                || (portal_read_groups_o != 64'd1)
                || (portal_write_groups_o != 64'd0)
                || (portal_read_words_o != 64'd0)
                || (portal_write_words_o != 64'd0)
                || (indices_completed_o != 64'd0)
                || (accepted_requests-before_requests != 1)
                || (accepted_responses-before_responses != 1)
                || (commit_pulses != before_commits))
            fail("GET_ROWS wrong-mask fail-closed mismatch");
        for (oracle_row = 0; oracle_row < GET_INDICES;
             oracle_row = oracle_row + 1) begin
            for (oracle_element = 0; oracle_element < GET_ELEMENTS;
                 oracle_element = oracle_element + 1) begin
                if (load32(GET_DST_BASE + oracle_row*GET_DST_STRIDE
                           + oracle_element*4) !== 32'h1357_9bdf)
                    fail("wrong-mask error changed destination");
            end
        end

        // REPEAT: O=3,R=4,D=18 exercises two-dimensional broadcast and a
        // 16+2 lane tail.  Each source word is read once per outer plane.
        fill_repeat_destination(32'hfeed_face);
        configure_repeat(64'h0000_0000_0000_1201);
        before_requests = accepted_requests;
        before_responses = accepted_responses;
        before_reads = accepted_read_groups;
        before_writes = accepted_write_groups;
        before_read_words = accepted_read_words;
        before_write_words = accepted_write_words;
        before_backpressure = request_backpressure_cycles;
        before_partial = partial_group_count;
        before_commits = commit_pulses;
        execute_command(1'b0, 5'd0, 1'b0);
        checks = checks + 1;
        if ((portal_request_groups_o != 64'd30)
                || (portal_response_groups_o != 64'd30)
                || (portal_read_groups_o != 64'd6)
                || (portal_write_groups_o != 64'd24)
                || (portal_read_words_o != 64'd54)
                || (portal_write_words_o != 64'd216)
                || (portal_read_bytes_o != 64'd216)
                || (portal_write_bytes_o != 64'd864)
                || (indices_completed_o != 64'd0)
                || (source_words_completed_o != 64'd54)
                || (elements_completed_o != 64'd216)
                || (accepted_requests-before_requests != 30)
                || (accepted_responses-before_responses != 30)
                || (accepted_read_groups-before_reads != 6)
                || (accepted_write_groups-before_writes != 24)
                || (accepted_read_words-before_read_words != 54)
                || (accepted_write_words-before_write_words != 216)
                || (request_backpressure_cycles-before_backpressure == 0)
                || (partial_group_count-before_partial == 0)
                || (commit_pulses-before_commits != 1))
            fail("REPEAT portal ledger/backpressure mismatch");
        for (oracle_outer = 0; oracle_outer < REP_OUTER;
             oracle_outer = oracle_outer + 1) begin
            for (oracle_repeat = 0; oracle_repeat < REP_COUNT;
                 oracle_repeat = oracle_repeat + 1) begin
                for (oracle_element = 0; oracle_element < REP_ELEMENTS;
                     oracle_element = oracle_element + 1) begin
                    if (load32(REP_DST_BASE
                               + oracle_outer*REP_DST_OUTER_STRIDE
                               + oracle_repeat*REP_DST_STRIDE
                               + oracle_element*4)
                            !== load32(REP_SRC_BASE
                                + oracle_outer*REP_SRC_STRIDE
                                + oracle_element*4))
                        fail("REPEAT software oracle raw-bit mismatch");
                end
            end
        end

        // REPEAT destination/source overlap is rejected wholly in preflight.
        configure_repeat(64'h0000_0000_0000_1202);
        dst_base_i = REP_SRC_BASE + 64'd4;
        dst_window_base_i = SRC_WINDOW_BASE;
        dst_window_bytes_i = SRC_WINDOW_SIZE;
        before_requests = accepted_requests;
        before_responses = accepted_responses;
        before_commits = commit_pulses;
        execute_command(1'b1, ERR_ALIAS, 1'b0);
        checks = checks + 1;
        if ((portal_request_groups_o != 64'd0)
                || (portal_response_groups_o != 64'd0)
                || (portal_read_groups_o != 64'd0)
                || (portal_write_groups_o != 64'd0)
                || (portal_read_words_o != 64'd0)
                || (portal_write_words_o != 64'd0)
                || (accepted_requests != before_requests)
                || (accepted_responses != before_responses)
                || (commit_pulses != before_commits))
            fail("REPEAT alias preflight rejection mismatch");

        checks = checks + 1;
        if ((accepted_commands != 5) || (commit_pulses != 2)
                || (busy_start_attempts != 1)
                || (request_backpressure_cycles == 0)
                || portal_outstanding_o || busy_o)
            fail("aggregate command/commit closure mismatch");

        $display("[NPU-F32-GATHER-REPEAT-PORTAL][INFO] lanes=16 get_rows=N5/D19 groups=21 read/write_words=100/95 repeat=O3/R4/D18 groups=30 read/write_words=54/216 errors=index_range+wrong_mask+alias raw_gmem=0 bit_exact=1 checks=%0d",
                 checks);
        $display("[NPU-F32-GATHER-REPEAT-PORTAL][PASS] scenarios=5 lanes=16 assertions=off waveform=off");
        $finish;
    end

    /* verilator lint_on BLKSEQ */
    /* verilator lint_on WIDTHEXPAND */
    /* verilator lint_on WIDTHTRUNC */

endmodule

`default_nettype wire
