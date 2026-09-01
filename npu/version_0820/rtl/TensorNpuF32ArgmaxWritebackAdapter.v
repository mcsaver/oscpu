`timescale 1ns/1ps
`default_nettype none

// Clocked raw-GMEM F32 ARGMAX owner.
//
// The host-facing memory service may only return the requested 64-bit beat
// and accept the final four index bytes.  Every FP32 classification,
// comparison, tie decision, address, counter and commit decision is made in
// this synthesizable module.  The destination is transaction-private until a
// successful terminal raises dst_commit_o.
module TensorNpuF32ArgmaxWritebackAdapter #(
    parameter integer MAX_ELEMENTS = 1048576
) (
    input  wire         clk_i,
    input  wire         rst_i,

    input  wire         start_i,
    output wire         ready_o,
    output wire         busy_o,
    input  wire         npu_required_i,
    input  wire [63:0]  command_id_i,
    input  wire [63:0]  canonical_node_id_lo_i,
    input  wire [63:0]  canonical_node_id_hi_i,
    input  wire         dst_shadow_private_i,
    input  wire         windows_generation_valid_i,

    input  wire [63:0]  src_base_i,
    input  wire [63:0]  dst_base_i,
    input  wire [63:0]  element_count_i,
    input  wire [63:0]  src_stride_i,
    input  wire [63:0]  dst_stride_i,

    input  wire [63:0]  src_window_base_i,
    input  wire [63:0]  src_window_bytes_i,
    input  wire         src_window_read_i,
    input  wire         src_window_write_i,
    input  wire [63:0]  dst_window_base_i,
    input  wire [63:0]  dst_window_bytes_i,
    input  wire         dst_window_read_i,
    input  wire         dst_window_write_i,

    output wire         gmem_req_valid_o,
    input  wire         gmem_req_ready_i,
    output wire         gmem_req_write_o,
    output wire [63:0]  gmem_req_addr_o,
    output wire [63:0]  gmem_req_wdata_o,
    output wire [7:0]   gmem_req_wstrb_o,
    input  wire         gmem_rsp_valid_i,
    output wire         gmem_rsp_ready_o,
    input  wire [63:0]  gmem_rsp_rdata_i,
    input  wire         gmem_rsp_error_i,

    output wire         completion_valid_o,
    output wire         dst_commit_o,
    output wire [63:0]  completion_command_id_o,
    output wire [63:0]  completion_canonical_node_id_lo_o,
    output wire [63:0]  completion_canonical_node_id_hi_o,
    output wire         completion_npu_required_o,
    output wire [31:0]  completion_kernel_id_o,
    output wire         done_o,
    output wire         error_o,
    output wire [4:0]   error_code_o,

    output wire [63:0]  elements_scanned_o,
    output wire [63:0]  comparisons_o,
    output wire [63:0]  gmem_read_requests_o,
    output wire [63:0]  gmem_read_responses_o,
    output wire [63:0]  read_payload_bytes_o,
    output wire [63:0]  gmem_write_requests_o,
    output wire [63:0]  gmem_write_responses_o,
    output wire [63:0]  write_payload_bytes_o,
    output wire [63:0]  active_cycles_o,
    output wire         gmem_outstanding_o
);

    localparam [31:0] KERNEL_F32_ARGMAX = 32'h514e0030;

    localparam [3:0] ST_IDLE       = 4'd0;
    localparam [3:0] ST_PREFLIGHT  = 4'd1;
    localparam [3:0] ST_READ_REQ   = 4'd2;
    localparam [3:0] ST_READ_RSP   = 4'd3;
    localparam [3:0] ST_WRITE_REQ  = 4'd4;
    localparam [3:0] ST_WRITE_RSP  = 4'd5;
    localparam [3:0] ST_DONE       = 4'd6;
    localparam [3:0] ST_ERROR      = 4'd7;

    localparam [4:0] ERR_NONE          = 5'd0;
    localparam [4:0] ERR_DESCRIPTOR    = 5'd1;
    localparam [4:0] ERR_SOURCE_WINDOW = 5'd2;
    localparam [4:0] ERR_DEST_WINDOW   = 5'd3;
    localparam [4:0] ERR_ALIAS         = 5'd4;
    localparam [4:0] ERR_GMEM          = 5'd6;
    localparam [4:0] ERR_INTERNAL      = 5'd7;

    reg [3:0] state_q;
    reg npu_required_q;
    reg [63:0] command_id_q;
    reg [63:0] canonical_node_id_lo_q;
    reg [63:0] canonical_node_id_hi_q;
    reg dst_shadow_private_q;
    reg windows_generation_valid_q;
    reg [63:0] src_base_q;
    reg [63:0] dst_base_q;
    reg [63:0] element_count_q;
    reg [63:0] src_stride_q;
    reg [63:0] dst_stride_q;
    reg [63:0] src_window_base_q;
    reg [63:0] src_window_bytes_q;
    reg src_window_read_q;
    reg src_window_write_q;
    reg [63:0] dst_window_base_q;
    reg [63:0] dst_window_bytes_q;
    reg dst_window_read_q;
    reg dst_window_write_q;

    reg [63:0] element_index_q;
    reg [31:0] best_bits_q;
    reg [31:0] best_index_q;
    reg [4:0]  error_code_q;
    reg        outstanding_q;
    reg [63:0] elements_scanned_q;
    reg [63:0] comparisons_q;
    reg [63:0] gmem_read_requests_q;
    reg [63:0] gmem_read_responses_q;
    reg [63:0] read_payload_bytes_q;
    reg [63:0] gmem_write_requests_q;
    reg [63:0] gmem_write_responses_q;
    reg [63:0] write_payload_bytes_q;
    reg [63:0] active_cycles_q;

    // Exact scalar oracle used by ggml_vec_argmax_f32:
    //   max = MAX(max, x[i]); if (max == x[i]) idx = i;
    // where MAX(a,b) is `(a > b ? a : b)`.  In particular, equality chooses
    // the newest value/index, either NaN operand makes `>` false, and a NaN
    // input therefore replaces the running max without updating the index.
    /* verilator lint_off UNUSEDSIGNAL */
    function automatic fp32_is_nan;
        input [31:0] value;
        begin
            fp32_is_nan = (value[30:23] == 8'hff)
                        && (value[22:0] != 23'b0);
        end
    endfunction
    /* verilator lint_on UNUSEDSIGNAL */

    function automatic fp32_ordered_greater;
        input [31:0] lhs;
        input [31:0] rhs;
        reg lhs_zero;
        reg rhs_zero;
        begin
            lhs_zero = (lhs[30:0] == 31'b0);
            rhs_zero = (rhs[30:0] == 31'b0);
            if (fp32_is_nan(lhs) || fp32_is_nan(rhs))
                fp32_ordered_greater = 1'b0;
            else if (lhs_zero && rhs_zero)
                fp32_ordered_greater = 1'b0;
            else if (lhs == rhs)
                fp32_ordered_greater = 1'b0;
            else if (lhs[31] != rhs[31])
                fp32_ordered_greater = !lhs[31];
            else if (!lhs[31])
                fp32_ordered_greater = lhs[30:0] > rhs[30:0];
            else
                fp32_ordered_greater = lhs[30:0] < rhs[30:0];
        end
    endfunction

    wire [127:0] src_semantic_end_w;
    wire [127:0] src_window_end_w;
    wire [127:0] dst_semantic_end_w;
    wire [127:0] dst_window_end_w;
    wire [127:0] src_phys_start_w;
    wire [127:0] src_phys_end_w;
    wire [127:0] dst_phys_start_w;
    wire [127:0] dst_phys_end_w;
    assign src_semantic_end_w = {64'b0, src_base_q}
                              + ({64'b0, element_count_q} << 2);
    assign src_window_end_w = {64'b0, src_window_base_q}
                            + {64'b0, src_window_bytes_q};
    assign dst_semantic_end_w = {64'b0, dst_base_q} + 128'd4;
    assign dst_window_end_w = {64'b0, dst_window_base_q}
                            + {64'b0, dst_window_bytes_q};
    assign src_phys_start_w =
        {64'b0, (src_base_q & 64'hffff_ffff_ffff_fff8)};
    assign src_phys_end_w =
        ((src_semantic_end_w + 128'd7) >> 3) << 3;
    assign dst_phys_start_w =
        {64'b0, (dst_base_q & 64'hffff_ffff_ffff_fff8)};
    assign dst_phys_end_w =
        ((dst_semantic_end_w + 128'd7) >> 3) << 3;

    wire descriptor_ok_w;
    wire source_window_ok_w;
    wire dest_window_ok_w;
    wire alias_ok_w;
    assign descriptor_ok_w = npu_required_q && dst_shadow_private_q
                           && windows_generation_valid_q
                           && ((canonical_node_id_lo_q != 64'b0)
                               || (canonical_node_id_hi_q != 64'b0))
                           && (element_count_q >= 64'd1)
                           && (element_count_q <= 64'(MAX_ELEMENTS))
                           && (src_stride_q == 64'd4)
                           && (dst_stride_q == 64'd4);
    assign source_window_ok_w =
        (src_semantic_end_w[127:64] == 64'b0)
        && (src_window_end_w[127:64] == 64'b0)
        && (src_phys_end_w[127:64] == 64'b0)
        && (src_base_q[1:0] == 2'b00)
        && (src_window_base_q[2:0] == 3'b000)
        && (src_window_bytes_q[2:0] == 3'b000)
        && (src_window_bytes_q != 64'b0)
        && src_window_read_q && !src_window_write_q
        && (src_phys_start_w >= {64'b0, src_window_base_q})
        && (src_phys_end_w <= src_window_end_w);
    assign dest_window_ok_w =
        (dst_semantic_end_w[127:64] == 64'b0)
        && (dst_window_end_w[127:64] == 64'b0)
        && (dst_phys_end_w[127:64] == 64'b0)
        && (dst_base_q[1:0] == 2'b00)
        && (dst_window_base_q[2:0] == 3'b000)
        && (dst_window_bytes_q[2:0] == 3'b000)
        && (dst_window_bytes_q != 64'b0)
        && !dst_window_read_q && dst_window_write_q
        && (dst_phys_start_w >= {64'b0, dst_window_base_q})
        && (dst_phys_end_w <= dst_window_end_w);
    assign alias_ok_w = (src_phys_end_w <= dst_phys_start_w)
                     || (dst_phys_end_w <= src_phys_start_w);

    wire [63:0] current_element_addr_w;
    wire [63:0] current_read_addr_w;
    wire [31:0] first_word_w;
    wire [31:0] second_word_w;
    wire second_word_valid_w;
    assign current_element_addr_w = src_base_q + (element_index_q << 2);
    assign current_read_addr_w =
        current_element_addr_w & 64'hffff_ffff_ffff_fff8;
    assign first_word_w = current_element_addr_w[2]
                        ? gmem_rsp_rdata_i[63:32]
                        : gmem_rsp_rdata_i[31:0];
    assign second_word_w = gmem_rsp_rdata_i[63:32];
    assign second_word_valid_w = !current_element_addr_w[2]
                               && ((element_index_q + 64'd1)
                                   < element_count_q);

    reg [31:0] best_after_first_bits_r;
    reg [31:0] best_after_first_index_r;
    reg [31:0] best_after_second_bits_r;
    reg [31:0] best_after_second_index_r;
    always @(*) begin
        best_after_first_bits_r = best_bits_q;
        best_after_first_index_r = best_index_q;
        if (!fp32_ordered_greater(best_bits_q, first_word_w)) begin
            best_after_first_bits_r = first_word_w;
            if (!fp32_is_nan(first_word_w))
                best_after_first_index_r = element_index_q[31:0];
        end
        best_after_second_bits_r = best_after_first_bits_r;
        best_after_second_index_r = best_after_first_index_r;
        if (second_word_valid_w
                && !fp32_ordered_greater(
                    best_after_first_bits_r, second_word_w)) begin
            best_after_second_bits_r = second_word_w;
            if (!fp32_is_nan(second_word_w))
                best_after_second_index_r =
                    element_index_q[31:0] + 32'd1;
        end
    end

    assign ready_o = !rst_i && (state_q == ST_IDLE);
    assign busy_o = !rst_i && (state_q != ST_IDLE);
    assign done_o = !rst_i && (state_q == ST_DONE);
    assign error_o = !rst_i && (state_q == ST_ERROR);
    assign completion_valid_o = done_o || error_o;
    assign dst_commit_o = done_o;
    assign completion_command_id_o = completion_valid_o
                                   ? command_id_q : 64'b0;
    assign completion_canonical_node_id_lo_o = completion_valid_o
                                            ? canonical_node_id_lo_q : 64'b0;
    assign completion_canonical_node_id_hi_o = completion_valid_o
                                            ? canonical_node_id_hi_q : 64'b0;
    assign completion_npu_required_o = completion_valid_o
                                    ? npu_required_q : 1'b0;
    assign completion_kernel_id_o = completion_valid_o
                                  ? KERNEL_F32_ARGMAX : 32'b0;
    assign error_code_o = error_code_q;

    assign gmem_req_valid_o = !rst_i
                            && ((state_q == ST_READ_REQ)
                                || (state_q == ST_WRITE_REQ));
    assign gmem_req_write_o = (state_q == ST_WRITE_REQ);
    assign gmem_req_addr_o = (state_q == ST_READ_REQ)
                           ? current_read_addr_w
                           : ((state_q == ST_WRITE_REQ)
                              ? (dst_base_q
                                 & 64'hffff_ffff_ffff_fff8) : 64'b0);
    assign gmem_req_wdata_o = (state_q == ST_WRITE_REQ)
                           ? (dst_base_q[2]
                              ? {best_index_q, 32'b0}
                              : {32'b0, best_index_q}) : 64'b0;
    assign gmem_req_wstrb_o = (state_q == ST_WRITE_REQ)
                           ? (dst_base_q[2] ? 8'hf0 : 8'h0f) : 8'b0;
    assign gmem_rsp_ready_o = !rst_i
                            && ((state_q == ST_READ_RSP)
                                || (state_q == ST_WRITE_RSP));

    assign elements_scanned_o = elements_scanned_q;
    assign comparisons_o = comparisons_q;
    assign gmem_read_requests_o = gmem_read_requests_q;
    assign gmem_read_responses_o = gmem_read_responses_q;
    assign read_payload_bytes_o = read_payload_bytes_q;
    assign gmem_write_requests_o = gmem_write_requests_q;
    assign gmem_write_responses_o = gmem_write_responses_q;
    assign write_payload_bytes_o = write_payload_bytes_q;
    assign active_cycles_o = active_cycles_q;
    assign gmem_outstanding_o = outstanding_q;

    always @(posedge clk_i) begin
        if (rst_i) begin
            state_q <= ST_IDLE;
            npu_required_q <= 1'b0;
            command_id_q <= 64'b0;
            canonical_node_id_lo_q <= 64'b0;
            canonical_node_id_hi_q <= 64'b0;
            dst_shadow_private_q <= 1'b0;
            windows_generation_valid_q <= 1'b0;
            src_base_q <= 64'b0;
            dst_base_q <= 64'b0;
            element_count_q <= 64'b0;
            src_stride_q <= 64'b0;
            dst_stride_q <= 64'b0;
            src_window_base_q <= 64'b0;
            src_window_bytes_q <= 64'b0;
            src_window_read_q <= 1'b0;
            src_window_write_q <= 1'b0;
            dst_window_base_q <= 64'b0;
            dst_window_bytes_q <= 64'b0;
            dst_window_read_q <= 1'b0;
            dst_window_write_q <= 1'b0;
            element_index_q <= 64'b0;
            best_bits_q <= 32'hff800000;
            best_index_q <= 32'b0;
            error_code_q <= ERR_NONE;
            outstanding_q <= 1'b0;
            elements_scanned_q <= 64'b0;
            comparisons_q <= 64'b0;
            gmem_read_requests_q <= 64'b0;
            gmem_read_responses_q <= 64'b0;
            read_payload_bytes_q <= 64'b0;
            gmem_write_requests_q <= 64'b0;
            gmem_write_responses_q <= 64'b0;
            write_payload_bytes_q <= 64'b0;
            active_cycles_q <= 64'b0;
        end else begin
            if (state_q != ST_IDLE)
                active_cycles_q <= active_cycles_q + 64'd1;

            case (state_q)
                ST_IDLE: begin
                    if (start_i && ready_o) begin
                        npu_required_q <= npu_required_i;
                        command_id_q <= command_id_i;
                        canonical_node_id_lo_q <=
                            canonical_node_id_lo_i;
                        canonical_node_id_hi_q <=
                            canonical_node_id_hi_i;
                        dst_shadow_private_q <= dst_shadow_private_i;
                        windows_generation_valid_q <=
                            windows_generation_valid_i;
                        src_base_q <= src_base_i;
                        dst_base_q <= dst_base_i;
                        element_count_q <= element_count_i;
                        src_stride_q <= src_stride_i;
                        dst_stride_q <= dst_stride_i;
                        src_window_base_q <= src_window_base_i;
                        src_window_bytes_q <= src_window_bytes_i;
                        src_window_read_q <= src_window_read_i;
                        src_window_write_q <= src_window_write_i;
                        dst_window_base_q <= dst_window_base_i;
                        dst_window_bytes_q <= dst_window_bytes_i;
                        dst_window_read_q <= dst_window_read_i;
                        dst_window_write_q <= dst_window_write_i;
                        element_index_q <= 64'b0;
                        best_bits_q <= 32'hff800000;
                        best_index_q <= 32'b0;
                        error_code_q <= ERR_NONE;
                        outstanding_q <= 1'b0;
                        elements_scanned_q <= 64'b0;
                        comparisons_q <= 64'b0;
                        gmem_read_requests_q <= 64'b0;
                        gmem_read_responses_q <= 64'b0;
                        read_payload_bytes_q <= 64'b0;
                        gmem_write_requests_q <= 64'b0;
                        gmem_write_responses_q <= 64'b0;
                        write_payload_bytes_q <= 64'b0;
                        active_cycles_q <= 64'b0;
                        state_q <= ST_PREFLIGHT;
                    end
                end

                ST_PREFLIGHT: begin
                    if (!descriptor_ok_w) begin
                        error_code_q <= ERR_DESCRIPTOR;
                        state_q <= ST_ERROR;
                    end else if (!source_window_ok_w) begin
                        error_code_q <= ERR_SOURCE_WINDOW;
                        state_q <= ST_ERROR;
                    end else if (!dest_window_ok_w) begin
                        error_code_q <= ERR_DEST_WINDOW;
                        state_q <= ST_ERROR;
                    end else if (!alias_ok_w) begin
                        error_code_q <= ERR_ALIAS;
                        state_q <= ST_ERROR;
                    end else begin
                        state_q <= ST_READ_REQ;
                    end
                end

                ST_READ_REQ: begin
                    if (gmem_req_valid_o && gmem_req_ready_i) begin
                        outstanding_q <= 1'b1;
                        gmem_read_requests_q <=
                            gmem_read_requests_q + 64'd1;
                        state_q <= ST_READ_RSP;
                    end
                end

                ST_READ_RSP: begin
                    if (gmem_rsp_valid_i && gmem_rsp_ready_o) begin
                        outstanding_q <= 1'b0;
                        gmem_read_responses_q <=
                            gmem_read_responses_q + 64'd1;
                        if (gmem_rsp_error_i) begin
                            error_code_q <= ERR_GMEM;
                            state_q <= ST_ERROR;
                        end else begin
                            read_payload_bytes_q <=
                                read_payload_bytes_q + 64'd8;
                            best_bits_q <= best_after_second_bits_r;
                            best_index_q <= best_after_second_index_r;
                            elements_scanned_q <= elements_scanned_q
                                + (second_word_valid_w ? 64'd2 : 64'd1);
                            comparisons_q <= comparisons_q
                                + (second_word_valid_w ? 64'd2 : 64'd1);
                            if (element_index_q
                                    + (second_word_valid_w ? 64'd2 : 64'd1)
                                    >= element_count_q) begin
                                state_q <= ST_WRITE_REQ;
                            end else begin
                                element_index_q <= element_index_q
                                    + (second_word_valid_w
                                       ? 64'd2 : 64'd1);
                                state_q <= ST_READ_REQ;
                            end
                        end
                    end
                end

                ST_WRITE_REQ: begin
                    if (gmem_req_valid_o && gmem_req_ready_i) begin
                        outstanding_q <= 1'b1;
                        gmem_write_requests_q <=
                            gmem_write_requests_q + 64'd1;
                        state_q <= ST_WRITE_RSP;
                    end
                end

                ST_WRITE_RSP: begin
                    if (gmem_rsp_valid_i && gmem_rsp_ready_o) begin
                        outstanding_q <= 1'b0;
                        gmem_write_responses_q <=
                            gmem_write_responses_q + 64'd1;
                        if (gmem_rsp_error_i) begin
                            error_code_q <= ERR_GMEM;
                            state_q <= ST_ERROR;
                        end else begin
                            write_payload_bytes_q <=
                                write_payload_bytes_q + 64'd4;
                            state_q <= ST_DONE;
                        end
                    end
                end

                ST_DONE: state_q <= ST_IDLE;
                ST_ERROR: state_q <= ST_IDLE;

                default: begin
                    error_code_q <= ERR_INTERNAL;
                    outstanding_q <= 1'b0;
                    state_q <= ST_ERROR;
                end
            endcase
        end
    end

`ifdef NPU_ASSERT
    always @(posedge clk_i) begin
        if (!rst_i && gmem_req_valid_o && (gmem_req_addr_o[2:0] != 3'b000))
            $error("F32 ARGMAX emitted an unaligned GMEM beat");
        if (!rst_i && gmem_outstanding_o && gmem_req_valid_o)
            $error("F32 ARGMAX emitted a second outstanding request");
        if (!rst_i && dst_commit_o && (error_code_q != ERR_NONE))
            $error("F32 ARGMAX committed a failed destination");
        if (!rst_i && done_o &&
                ((elements_scanned_q != element_count_q)
                 || (comparisons_q != element_count_q)))
            $error("F32 ARGMAX terminal census mismatch");
    end
`endif

endmodule

`default_nettype wire
