`timescale 1ns/1ps
`default_nettype none

module tb_rope_writeback_adapter;
    localparam [31:0] STALL_TIMEOUT = 32'd128;
    localparam [31:0] KERNEL_ID = 32'h514e000a;
    localparam [4:0] ERR_DESCRIPTOR = 5'd1;
    localparam [4:0] ERR_SRC0 = 5'd2;
    localparam [4:0] ERR_SRC1 = 5'd3;
    localparam [4:0] ERR_DST = 5'd4;
    localparam [4:0] ERR_ALIAS = 5'd5;
    localparam [4:0] ERR_GMEM = 5'd6;
    localparam [4:0] ERR_STALL = 5'd8;
    localparam [7:0] PROFILE_Q = 8'd0;
    localparam [7:0] PROFILE_K = 8'd1;
    localparam [63:0] SRC0_BASE = 64'h0000_0000_0001_0000;
    localparam [63:0] SRC1_BASE = 64'h0000_0000_0002_0000;
    localparam [63:0] DST_BASE = 64'h0000_0000_0003_0000;
    localparam integer MEM_BYTES = 262144;
    localparam [511:0] FROZEN_OP_PARAMS = {
        32'h00000000, 32'h00000000, 32'h0000000a, 32'h0000000b,
        32'h0000000b, 32'h3f800000, 32'h42000000, 32'h3f800000,
        32'h00000000, 32'h3f800000, 32'h4b189680, 32'h00040000,
        32'h00000000, 32'h00000028, 32'h00000040, 32'h00000000
    };

    reg clk_i, rst_i, start_i;
    wire ready_o, busy_o;
    reg [15:0] manifest_op_id_i;
    reg [2:0] source_arity_i;
    reg [511:0] op_params_i;
    reg npu_required_i;
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

    wire gmem_req_valid_o;
    reg gmem_req_ready_i;
    wire gmem_req_write_o;
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
    wire [63:0] source0_words_completed_o, position_words_completed_o;
    wire [63:0] position_conversions_completed_o;
    wire [63:0] raw_copy_words_completed_o, rotation_pairs_completed_o;
    wire [63:0] gmem_read_requests_o, gmem_read_responses_o;
    wire [63:0] read_payload_bytes_o;
    wire [63:0] gmem_write_requests_o, gmem_write_responses_o;
    wire [63:0] write_payload_bytes_o;
    wire [63:0] sincos_requests_o, sincos_responses_o;
    wire [63:0] theta_mul_requests_o, theta_mul_responses_o;
    wire [63:0] data_mul_requests_o, data_mul_responses_o;
    wire [63:0] fma_requests_o, fma_responses_o, active_cycles_o;
    wire gmem_outstanding_o, numeric_outstanding_o, gmem_drain_o;

    TensorNpuRopeWritebackAdapter #(
        .STALL_TIMEOUT_CYCLES(STALL_TIMEOUT),
        .COMMAND_TIMEOUT_CYCLES(64'd1000000),
        .DRAIN_TIMEOUT_CYCLES(32'd512),
        .ABORT_HOLD_TIMEOUT_CYCLES(32'd512)
    ) dut (
        .clk_i(clk_i), .rst_i(rst_i), .start_i(start_i),
        .ready_o(ready_o), .busy_o(busy_o),
        .manifest_op_id_i(manifest_op_id_i),
        .source_arity_i(source_arity_i), .op_params_i(op_params_i),
        .npu_required_i(npu_required_i), .command_id_i(command_id_i),
        .canonical_node_id_lo_i(canonical_node_id_lo_i),
        .canonical_node_id_hi_i(canonical_node_id_hi_i),
        .dst_shadow_private_i(dst_shadow_private_i),
        .windows_generation_valid_i(windows_generation_valid_i),
        .src0_dtype_i(src0_dtype_i), .src0_flags_i(src0_flags_i),
        .src0_view_off_i(src0_view_off_i), .src0_ne0_i(src0_ne0_i),
        .src0_ne1_i(src0_ne1_i), .src0_ne2_i(src0_ne2_i),
        .src0_ne3_i(src0_ne3_i), .src0_base_i(src0_base_i),
        .src0_nb0_i(src0_nb0_i), .src0_nb1_i(src0_nb1_i),
        .src0_nb2_i(src0_nb2_i), .src0_nb3_i(src0_nb3_i),
        .src1_dtype_i(src1_dtype_i), .src1_flags_i(src1_flags_i),
        .src1_view_off_i(src1_view_off_i), .src1_ne0_i(src1_ne0_i),
        .src1_ne1_i(src1_ne1_i), .src1_ne2_i(src1_ne2_i),
        .src1_ne3_i(src1_ne3_i), .src1_base_i(src1_base_i),
        .src1_nb0_i(src1_nb0_i), .src1_nb1_i(src1_nb1_i),
        .src1_nb2_i(src1_nb2_i), .src1_nb3_i(src1_nb3_i),
        .dst_dtype_i(dst_dtype_i), .dst_flags_i(dst_flags_i),
        .dst_view_off_i(dst_view_off_i), .dst_ne0_i(dst_ne0_i),
        .dst_ne1_i(dst_ne1_i), .dst_ne2_i(dst_ne2_i),
        .dst_ne3_i(dst_ne3_i), .dst_base_i(dst_base_i),
        .dst_nb0_i(dst_nb0_i), .dst_nb1_i(dst_nb1_i),
        .dst_nb2_i(dst_nb2_i), .dst_nb3_i(dst_nb3_i),
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
        .position_words_completed_o(position_words_completed_o),
        .position_conversions_completed_o(position_conversions_completed_o),
        .raw_copy_words_completed_o(raw_copy_words_completed_o),
        .rotation_pairs_completed_o(rotation_pairs_completed_o),
        .gmem_read_requests_o(gmem_read_requests_o),
        .gmem_read_responses_o(gmem_read_responses_o),
        .read_payload_bytes_o(read_payload_bytes_o),
        .gmem_write_requests_o(gmem_write_requests_o),
        .gmem_write_responses_o(gmem_write_responses_o),
        .write_payload_bytes_o(write_payload_bytes_o),
        .sincos_requests_o(sincos_requests_o),
        .sincos_responses_o(sincos_responses_o),
        .theta_mul_requests_o(theta_mul_requests_o),
        .theta_mul_responses_o(theta_mul_responses_o),
        .data_mul_requests_o(data_mul_requests_o),
        .data_mul_responses_o(data_mul_responses_o),
        .fma_requests_o(fma_requests_o), .fma_responses_o(fma_responses_o),
        .active_cycles_o(active_cycles_o),
        .gmem_outstanding_o(gmem_outstanding_o),
        .numeric_outstanding_o(numeric_outstanding_o),
        .gmem_drain_o(gmem_drain_o)
    );

    reg [7:0] memory_q [0:MEM_BYTES-1];
    reg pending_q, pending_write_q, pending_error_q;
    reg [31:0] pending_delay_q;
    reg [63:0] pending_addr_q, pending_wdata_q, pending_rdata_q;
    reg [7:0] pending_wstrb_q;
    integer accepted_requests_q;
    integer fault_ordinal_q, late_ordinal_q, late_delay_q;
    integer active_profile_q;
    reg exact_order_enable_q, backpressure_enable_q, backpressure_phase_q;
    reg held_request_q;
    reg held_write_q;
    reg [63:0] held_addr_q, held_wdata_q;
    reg [7:0] held_wstrb_q;
    integer held_stability_cycles_q;
    reg [31:0] public_canary_q;
    integer global_cycles_q;
    real ref_sin_q [0:31];
    real ref_cos_q [0:31];

    /* verilator lint_off BLKSEQ */
    always #1 clk_i = ~clk_i;
    /* verilator lint_on BLKSEQ */

    function automatic [31:0] load_word(input [63:0] addr);
        integer base;
        begin
            base = addr;
            load_word = {memory_q[base + 3], memory_q[base + 2],
                         memory_q[base + 1], memory_q[base]};
        end
    endfunction

    function automatic [63:0] load_beat(input [63:0] addr);
        begin
            load_beat = {load_word(addr + 64'd4), load_word(addr)};
        end
    endfunction

    task automatic store_word(input [63:0] addr, input [31:0] data);
        integer base;
        begin
            base = addr;
            memory_q[base] = data[7:0];
            memory_q[base + 1] = data[15:8];
            memory_q[base + 2] = data[23:16];
            memory_q[base + 3] = data[31:24];
        end
    endtask

    function automatic real pow2_integer(input integer exponent);
        integer step;
        real value;
        begin
            value = 1.0;
            if (exponent >= 0)
                for (step = 0; step < exponent; step = step + 1)
                    value = value * 2.0;
            else
                for (step = 0; step < -exponent; step = step + 1)
                    value = value * 0.5;
            pow2_integer = value;
        end
    endfunction

    function automatic real fp32_to_real(input [31:0] raw);
        integer exponent;
        real magnitude;
        begin
            exponent = raw[30:23];
            if (exponent == 0)
                magnitude = real'(raw[22:0]) * pow2_integer(-149);
            else if (exponent == 255)
                magnitude = 0.0;
            else
                magnitude = (1.0 + real'(raw[22:0]) / 8388608.0)
                          * pow2_integer(exponent - 127);
            fp32_to_real = raw[31] ? -magnitude : magnitude;
        end
    endfunction

    // Host-only binary32 RNE helper for the numerical oracle.  All values
    // passed here by this TB are finite normal ROPE intermediates.
    function automatic [31:0] real_to_fp32(input real input_value);
        reg sign;
        real magnitude, normalized, scaled, fractional;
        integer exponent, biased_exponent;
        integer mantissa;
        begin
            sign = input_value < 0.0;
            magnitude = sign ? -input_value : input_value;
            if (magnitude == 0.0) begin
                real_to_fp32 = {sign, 31'b0};
            end else begin
                normalized = magnitude;
                exponent = 0;
                while (normalized >= 2.0) begin
                    normalized = normalized * 0.5;
                    exponent = exponent + 1;
                end
                while (normalized < 1.0) begin
                    normalized = normalized * 2.0;
                    exponent = exponent - 1;
                end
                biased_exponent = exponent + 127;
                scaled = (normalized - 1.0) * 8388608.0;
                mantissa = $rtoi($floor(scaled));
                fractional = scaled - real'(mantissa);
                if ((fractional > 0.5)
                        || ((fractional == 0.5) && ((mantissa & 1) != 0)))
                    mantissa = mantissa + 1;
                if (mantissa == 8388608) begin
                    mantissa = 0;
                    biased_exponent = biased_exponent + 1;
                end
                real_to_fp32 = {sign, biased_exponent[7:0],
                                mantissa[22:0]};
            end
        end
    endfunction

    function automatic real abs_real(input real value);
        abs_real = value < 0.0 ? -value : value;
    endfunction

    function automatic [31:0] ordered_float(input [31:0] raw);
        ordered_float = raw[31] ? ~raw : (raw ^ 32'h80000000);
    endfunction

    function automatic [31:0] ulp_distance(
        input [31:0] lhs, input [31:0] rhs);
        reg [31:0] lhs_ordered, rhs_ordered;
        begin
            lhs_ordered = ordered_float(lhs);
            rhs_ordered = ordered_float(rhs);
            ulp_distance = lhs_ordered >= rhs_ordered
                         ? lhs_ordered - rhs_ordered
                         : rhs_ordered - lhs_ordered;
        end
    endfunction

    task automatic fail_case(input string reason);
        begin
            $display("[NPU-ROPE-WRITEBACK][FAIL] %s cycle=%0d busy=%0b done=%0b error=%0b err=%0d req=%0d commit=%0b",
                     reason, global_cycles_q, busy_o, done_o, error_o,
                     error_code_o, accepted_requests_q, dst_commit_o);
            $fatal(1);
        end
    endtask

    function automatic integer profile_heads(input integer profile);
        profile_heads = profile == 0 ? 8 : 2;
    endfunction

    task automatic check_request_order;
        integer ordinal, relative, head, within_head, pair, slot, copy_index;
        reg [63:0] expected_addr;
        reg expected_write;
        reg [7:0] expected_wstrb;
        begin
            if (!exact_order_enable_q)
                return;
            ordinal = accepted_requests_q;
            expected_addr = 64'b0;
            expected_write = 1'b0;
            expected_wstrb = 8'b0;
            if (ordinal < 2) begin
                expected_addr = SRC1_BASE + 64'(ordinal * 8);
            end else begin
                relative = ordinal - 2;
                head = relative / 288;
                within_head = relative % 288;
                if (head >= profile_heads(active_profile_q))
                    fail_case("request after complete profile");
                if (within_head < 128) begin
                    expected_addr = SRC0_BASE + 64'(head * 1024)
                                  + 64'(within_head * 8);
                end else if (within_head < 192) begin
                    expected_write = 1'b1;
                    pair = (within_head - 128) / 2;
                    slot = (within_head - 128) % 2;
                    expected_addr = DST_BASE + 64'(head * 1024)
                                  + 64'(((pair + (slot != 0 ? 32 : 0))
                                         / 2) * 8);
                    expected_wstrb = (pair & 1) != 0 ? 8'hf0 : 8'h0f;
                end else begin
                    expected_write = 1'b1;
                    copy_index = within_head - 192;
                    expected_addr = DST_BASE + 64'(head * 1024) + 64'd256
                                  + 64'(copy_index * 8);
                    expected_wstrb = 8'hff;
                end
            end
            if ((gmem_req_addr_o !== expected_addr)
                    || (gmem_req_write_o !== expected_write)
                    || (gmem_req_wstrb_o !== expected_wstrb))
                fail_case($sformatf("request order ordinal=%0d got=%h/%0b/%h expected=%h/%0b/%h",
                          ordinal, gmem_req_addr_o, gmem_req_write_o,
                          gmem_req_wstrb_o, expected_addr, expected_write,
                          expected_wstrb));
        end
    endtask

    always @(*) begin
        gmem_req_ready_i = !rst_i && !pending_q && !gmem_rsp_valid_i
                         && (!backpressure_enable_q || backpressure_phase_q);
    end

    integer byte_index;
    always @(posedge clk_i) begin
        global_cycles_q <= global_cycles_q + 1;
        if (rst_i) begin
            pending_q <= 1'b0;
            pending_delay_q <= 32'b0;
            gmem_rsp_valid_i <= 1'b0;
            gmem_rsp_rdata_i <= 64'b0;
            gmem_rsp_error_i <= 1'b0;
            accepted_requests_q <= 0;
            backpressure_phase_q <= 1'b0;
            held_request_q <= 1'b0;
            held_stability_cycles_q <= 0;
        end else begin
            backpressure_phase_q <= ~backpressure_phase_q;
            if (gmem_req_valid_o && !gmem_req_ready_i) begin
                if (!held_request_q) begin
                    held_request_q <= 1'b1;
                    held_write_q <= gmem_req_write_o;
                    held_addr_q <= gmem_req_addr_o;
                    held_wdata_q <= gmem_req_wdata_o;
                    held_wstrb_q <= gmem_req_wstrb_o;
                end else if ((held_write_q !== gmem_req_write_o)
                        || (held_addr_q !== gmem_req_addr_o)
                        || (held_wdata_q !== gmem_req_wdata_o)
                        || (held_wstrb_q !== gmem_req_wstrb_o))
                    fail_case("held GMEM request mutated");
                held_stability_cycles_q <= held_stability_cycles_q + 1;
            end else if (gmem_req_valid_o && gmem_req_ready_i) begin
                if (held_request_q && ((held_write_q !== gmem_req_write_o)
                        || (held_addr_q !== gmem_req_addr_o)
                        || (held_wdata_q !== gmem_req_wdata_o)
                        || (held_wstrb_q !== gmem_req_wstrb_o)))
                    fail_case("accepted held GMEM request mutated");
                held_request_q <= 1'b0;
            end else
                held_request_q <= 1'b0;

            if (gmem_req_valid_o && gmem_req_ready_i) begin
                if (pending_q || gmem_rsp_valid_i)
                    fail_case("multiple outstanding GMEM owners");
                check_request_order();
                pending_q <= 1'b1;
                pending_write_q <= gmem_req_write_o;
                pending_addr_q <= gmem_req_addr_o;
                pending_wdata_q <= gmem_req_wdata_o;
                pending_wstrb_q <= gmem_req_wstrb_o;
                pending_rdata_q <= load_beat(gmem_req_addr_o);
                pending_error_q <= accepted_requests_q == fault_ordinal_q;
                pending_delay_q <= accepted_requests_q == late_ordinal_q
                                 ? late_delay_q : 32'd1;
                accepted_requests_q <= accepted_requests_q + 1;
            end

            if (pending_q && !gmem_rsp_valid_i) begin
                if (pending_delay_q == 0) begin
                    pending_q <= 1'b0;
                    gmem_rsp_valid_i <= 1'b1;
                    gmem_rsp_rdata_i <= pending_rdata_q;
                    gmem_rsp_error_i <= pending_error_q;
                end else
                    pending_delay_q <= pending_delay_q - 1;
            end

            if (gmem_rsp_valid_i && gmem_rsp_ready_o) begin
                if (pending_write_q && !gmem_rsp_error_i) begin
                    for (byte_index = 0; byte_index < 8;
                            byte_index = byte_index + 1)
                        if (pending_wstrb_q[byte_index])
                            memory_q[pending_addr_q + byte_index]
                                <= pending_wdata_q[byte_index * 8 +: 8];
                end
                gmem_rsp_valid_i <= 1'b0;
                gmem_rsp_error_i <= 1'b0;
            end
        end
    end

    task automatic set_valid_descriptor(input integer profile);
        integer bytes;
        begin
            active_profile_q = profile;
            bytes = profile == 0 ? 8192 : 2048;
            manifest_op_id_i = 16'd48;
            source_arity_i = 3'd2;
            op_params_i = FROZEN_OP_PARAMS;
            npu_required_i = 1'b1;
            command_id_i = 64'h1020_3040_5060_7080 + 64'(profile);
            canonical_node_id_lo_i = 64'h0123_4567_89ab_cdef
                                    + 64'(profile);
            canonical_node_id_hi_i = 64'hfedc_ba98_7654_3210
                                    - 64'(profile);
            dst_shadow_private_i = 1'b1;
            windows_generation_valid_i = 1'b1;
            src0_dtype_i = 8'd0;
            src0_flags_i = 32'd16;
            src0_view_off_i = 64'b0;
            src0_ne0_i = 32'd256;
            src0_ne1_i = profile == 0 ? 32'd8 : 32'd2;
            src0_ne2_i = 32'd1;
            src0_ne3_i = 32'd1;
            src0_base_i = SRC0_BASE;
            src0_nb0_i = 64'd4;
            src0_nb1_i = 64'd1024;
            src0_nb2_i = profile == 0 ? 64'd8192 : 64'd2048;
            src0_nb3_i = src0_nb2_i;
            src1_dtype_i = 8'd26;
            src1_flags_i = 32'd1;
            src1_view_off_i = 64'b0;
            src1_ne0_i = 32'd4;
            src1_ne1_i = 32'd1;
            src1_ne2_i = 32'd1;
            src1_ne3_i = 32'd1;
            src1_base_i = SRC1_BASE;
            src1_nb0_i = 64'd4;
            src1_nb1_i = 64'd16;
            src1_nb2_i = 64'd16;
            src1_nb3_i = 64'd16;
            dst_dtype_i = 8'd0;
            dst_flags_i = 32'd16;
            dst_view_off_i = 64'b0;
            dst_ne0_i = 32'd256;
            dst_ne1_i = src0_ne1_i;
            dst_ne2_i = 32'd1;
            dst_ne3_i = 32'd1;
            dst_base_i = DST_BASE;
            dst_nb0_i = 64'd4;
            dst_nb1_i = 64'd1024;
            dst_nb2_i = src0_nb2_i;
            dst_nb3_i = src0_nb3_i;
            src0_window_base_i = SRC0_BASE;
            src0_window_bytes_i = bytes;
            src0_window_read_i = 1'b1;
            src0_window_write_i = 1'b0;
            src1_window_base_i = SRC1_BASE;
            src1_window_bytes_i = 64'd16;
            src1_window_read_i = 1'b1;
            src1_window_write_i = 1'b0;
            dst_window_base_i = DST_BASE;
            dst_window_bytes_i = bytes;
            dst_window_read_i = 1'b0;
            dst_window_write_i = 1'b1;
            fault_ordinal_q = -1;
            late_ordinal_q = -1;
            late_delay_q = 0;
            exact_order_enable_q = 1'b0;
            backpressure_enable_q = 1'b1;
        end
    endtask

    function automatic [31:0] rotated_x0_pattern(input integer index);
        if ((index & 1) == 0)
            rotated_x0_pattern = 32'h3f800000; // exposes cos/sin directly
        else if ((index & 2) == 0)
            rotated_x0_pattern = 32'hc4000000; // -512
        else
            rotated_x0_pattern = 32'hc4800000; // -1024
    endfunction

    function automatic [31:0] rotated_x1_pattern(input integer index);
        if ((index & 1) == 0)
            rotated_x1_pattern = 32'h00000000;
        else if ((index & 2) == 0)
            rotated_x1_pattern = 32'h43800000; // +256
        else
            rotated_x1_pattern = 32'h44c00000; // +1536
    endfunction

    function automatic [31:0] copy_pattern(input integer index);
        case (index & 7)
            0: copy_pattern = 32'h00000000;
            1: copy_pattern = 32'h80000000;
            2: copy_pattern = 32'h7f800000;
            3: copy_pattern = 32'hff800000;
            4: copy_pattern = 32'h7fc12345;
            5: copy_pattern = 32'h00000001;
            6: copy_pattern = 32'h7f7fffff;
            default: copy_pattern = 32'hdeadbeef;
        endcase
    endfunction

    task automatic prepare_memory(input integer profile);
        integer head, channel, heads, bytes;
        begin
            heads = profile_heads(profile);
            bytes = heads * 1024;
            store_word(SRC1_BASE + 64'd0, 32'd262143);
            store_word(SRC1_BASE + 64'd4, 32'd32767);
            store_word(SRC1_BASE + 64'd8, 32'd1);
            store_word(SRC1_BASE + 64'd12, 32'd17);
            for (head = 0; head < heads; head = head + 1)
                for (channel = 0; channel < 256; channel = channel + 1) begin
                    if (channel < 32)
                        store_word(SRC0_BASE + 64'(head * 1024 + channel * 4),
                                   rotated_x0_pattern(channel + head));
                    else if (channel < 64)
                        store_word(SRC0_BASE + 64'(head * 1024 + channel * 4),
                                   rotated_x1_pattern(channel + head));
                    else
                        store_word(SRC0_BASE + 64'(head * 1024 + channel * 4),
                                   copy_pattern(channel + head));
                end
            for (channel = 0; channel < bytes; channel = channel + 1)
                memory_q[DST_BASE + channel] = 8'ha5;
            public_canary_q = 32'h51c0_ffee;
        end
    endtask

    task automatic pulse_reset;
        begin
            rst_i = 1'b1;
            start_i = 1'b0;
            repeat (3) @(posedge clk_i);
            rst_i = 1'b0;
            repeat (2) @(posedge clk_i);
            if (!ready_o || busy_o || completion_valid_o
                    || gmem_outstanding_o || numeric_outstanding_o)
                fail_case("reset quiescence");
        end
    endtask

    task automatic launch;
        begin
            if (!ready_o)
                fail_case("launch while not ready");
            start_i = 1'b1;
            @(posedge clk_i);
            start_i = 1'b0;
        end
    endtask

    task automatic wait_terminal(input integer limit, input string label);
        integer cycles;
        begin
            cycles = 0;
            while (!completion_valid_o && cycles < limit) begin
                @(posedge clk_i);
                cycles = cycles + 1;
            end
            if (!completion_valid_o)
                fail_case({label, " terminal timeout"});
            if (gmem_outstanding_o || numeric_outstanding_o || gmem_drain_o)
                fail_case({label, " terminal outstanding"});
        end
    endtask

    task automatic finish_terminal;
        begin
            @(posedge clk_i);
            if (completion_valid_o)
                fail_case("terminal was not one cycle");
            @(posedge clk_i);
            if (!ready_o && !poisoned_o)
                fail_case("terminal did not return ready");
        end
    endtask

    task automatic check_identity(input integer profile);
        begin
            if ((completion_command_id_o !==
                    (64'h1020_3040_5060_7080 + 64'(profile)))
                    || (completion_canonical_node_id_lo_o !==
                        (64'h0123_4567_89ab_cdef + 64'(profile)))
                    || (completion_canonical_node_id_hi_o !==
                        (64'hfedc_ba98_7654_3210 - 64'(profile)))
                    || !completion_npu_required_o
                    || completion_manifest_op_id_o != 16'd48
                    || completion_source_arity_o != 3'd2
                    || completion_kernel_id_o != KERNEL_ID
                    || completion_operator_census_o != 32'd12)
                fail_case("resident completion identity");
        end
    endtask

    task automatic run_static_reject(
        input [4:0] expected_error, input string label);
        reg [63:0] expected_command, expected_lo, expected_hi;
        reg [15:0] expected_op;
        reg [2:0] expected_arity;
        begin
            expected_command = command_id_i;
            expected_lo = canonical_node_id_lo_i;
            expected_hi = canonical_node_id_hi_i;
            expected_op = manifest_op_id_i;
            expected_arity = source_arity_i;
            launch();
            wait_terminal(32, label);
            if (!error_o || done_o || dst_commit_o
                    || error_code_o != expected_error
                    || accepted_requests_q != 0
                    || outputs_completed_o != 0)
                fail_case({label, " static reject"});
            if ((completion_command_id_o !== expected_command)
                    || (completion_canonical_node_id_lo_o !== expected_lo)
                    || (completion_canonical_node_id_hi_o !== expected_hi)
                    || (completion_manifest_op_id_o !== expected_op)
                    || (completion_source_arity_o !== expected_arity)
                    || (completion_kernel_id_o !== KERNEL_ID)
                    || (completion_operator_census_o !== 32'd12))
                fail_case({label, " resident error identity"});
            finish_terminal();
        end
    endtask

    task automatic run_reset_abort;
        begin
            pulse_reset();
            set_valid_descriptor(1);
            launch();
            while (accepted_requests_q == 0)
                @(posedge clk_i);
            rst_i = 1'b1;
            repeat (2) @(posedge clk_i);
            if (completion_valid_o || dst_commit_o)
                fail_case("reset emitted completion");
            rst_i = 1'b0;
            repeat (2) @(posedge clk_i);
            if (!ready_o || busy_o || gmem_outstanding_o
                    || numeric_outstanding_o)
                fail_case("reset owner cleanup");
        end
    endtask

    task automatic run_late_read_error;
        begin
            pulse_reset();
            set_valid_descriptor(1);
            prepare_memory(1);
            fault_ordinal_q = 2;
            launch();
            wait_terminal(20000, "late source read error");
            if (!error_o || dst_commit_o || error_code_o != ERR_GMEM
                    || gmem_read_requests_o != 3
                    || gmem_write_requests_o != 0
                    || outputs_completed_o != 0
                    || public_canary_q != 32'h51c0_ffee)
                fail_case("late source read accounting");
            check_identity(1);
            finish_terminal();
        end
    endtask

    task automatic run_timeout_drain;
        begin
            pulse_reset();
            set_valid_descriptor(1);
            prepare_memory(1);
            late_ordinal_q = 0;
            late_delay_q = STALL_TIMEOUT + 16;
            launch();
            wait_terminal(1024, "accepted timeout drain");
            if (!error_o || dst_commit_o || error_code_o != ERR_STALL
                    || gmem_read_requests_o != 1
                    || gmem_read_responses_o != 1
                    || outputs_completed_o != 0
                    || public_canary_q != 32'h51c0_ffee)
                fail_case("accepted timeout drain accounting");
            check_identity(1);
            finish_terminal();
        end
    endtask

    task automatic run_late_write_error;
        begin
            pulse_reset();
            set_valid_descriptor(1);
            prepare_memory(1);
            fault_ordinal_q = 131;
            launch();
            wait_terminal(60000, "late second write error");
            if (!error_o || dst_commit_o || error_code_o != ERR_GMEM
                    || gmem_write_requests_o != 2
                    || gmem_write_responses_o != 2
                    || outputs_completed_o != 1
                    || load_word(DST_BASE) == 32'ha5a5a5a5
                    || public_canary_q != 32'h51c0_ffee)
                fail_case("late write private prefix accounting");
            check_identity(1);
            finish_terminal();
        end
    endtask

    task automatic build_reference_angles;
        real theta_t, theta_h, theta_w, selected, scale;
        integer lane;
        begin
            theta_t = fp32_to_real(real_to_fp32(262143.0));
            theta_h = fp32_to_real(real_to_fp32(32767.0));
            theta_w = fp32_to_real(real_to_fp32(1.0));
            scale = fp32_to_real(32'h3f1ab32b);
            for (lane = 0; lane < 32; lane = lane + 1) begin
                case (lane % 3)
                    0: selected = theta_t;
                    1: selected = theta_h;
                    default: selected = theta_w;
                endcase
                ref_sin_q[lane] = fp32_to_real(real_to_fp32($sin(selected)));
                ref_cos_q[lane] = fp32_to_real(real_to_fp32($cos(selected)));
                theta_t = fp32_to_real(real_to_fp32(theta_t * scale));
                theta_h = fp32_to_real(real_to_fp32(theta_h * scale));
                theta_w = fp32_to_real(real_to_fp32(theta_w * scale));
            end
        end
    endtask

    task automatic check_full_outputs(
        input integer profile,
        output real max_abs,
        output real max_rel,
        output integer max_ulp);
        integer head, lane, channel, heads;
        reg [31:0] x0_bits, x1_bits, got_bits, expected_bits;
        real x0, x1, tmp_product, expected_real, got_real;
        real abs_error, rel_error, denominator;
        integer ulp;
        begin
            max_abs = 0.0;
            max_rel = 0.0;
            max_ulp = 0;
            heads = profile_heads(profile);
            build_reference_angles();
            for (head = 0; head < heads; head = head + 1) begin
                for (lane = 0; lane < 32; lane = lane + 1) begin
                    x0_bits = load_word(SRC0_BASE
                                      + 64'(head * 1024 + lane * 4));
                    x1_bits = load_word(SRC0_BASE
                                      + 64'(head * 1024 + (lane + 32) * 4));
                    x0 = fp32_to_real(x0_bits);
                    x1 = fp32_to_real(x1_bits);
                    tmp_product = fp32_to_real(
                        real_to_fp32(x1 * ref_sin_q[lane]));
                    expected_bits = real_to_fp32(
                        x0 * ref_cos_q[lane] - tmp_product);
                    expected_real = fp32_to_real(expected_bits);
                    got_bits = load_word(DST_BASE
                                       + 64'(head * 1024 + lane * 4));
                    got_real = fp32_to_real(got_bits);
                    if ((head == 0) && (lane == 0))
                        $display("[NPU-ROPE-WRITEBACK][ORACLE] profile=%0d theta_lane0_sin=%h cos=%h x0=%h x1=%h out0_got=%h out0_ref=%h",
                                 profile, real_to_fp32(ref_sin_q[lane]),
                                 real_to_fp32(ref_cos_q[lane]), x0_bits,
                                 x1_bits, got_bits, expected_bits);
                    abs_error = abs_real(got_real - expected_real);
                    denominator = abs_real(expected_real);
                    if (denominator < 1.0e-7)
                        denominator = 1.0e-7;
                    rel_error = abs_error / denominator;
                    ulp = ulp_distance(got_bits, expected_bits);
                    if (abs_error > max_abs) max_abs = abs_error;
                    if (rel_error > max_rel) max_rel = rel_error;
                    if (ulp > max_ulp) max_ulp = ulp;
                    if (abs_error > 5.0e-4)
                        fail_case($sformatf("out0 numerical error profile=%0d head=%0d lane=%0d got=%h ref=%h abs=%g",
                                  profile, head, lane, got_bits,
                                  expected_bits, abs_error));

                    tmp_product = fp32_to_real(
                        real_to_fp32(x1 * ref_cos_q[lane]));
                    expected_bits = real_to_fp32(
                        x0 * ref_sin_q[lane] + tmp_product);
                    expected_real = fp32_to_real(expected_bits);
                    got_bits = load_word(DST_BASE
                                       + 64'(head * 1024
                                             + (lane + 32) * 4));
                    got_real = fp32_to_real(got_bits);
                    abs_error = abs_real(got_real - expected_real);
                    denominator = abs_real(expected_real);
                    if (denominator < 1.0e-7)
                        denominator = 1.0e-7;
                    rel_error = abs_error / denominator;
                    ulp = ulp_distance(got_bits, expected_bits);
                    if (abs_error > max_abs) max_abs = abs_error;
                    if (rel_error > max_rel) max_rel = rel_error;
                    if (ulp > max_ulp) max_ulp = ulp;
                    if (abs_error > 5.0e-4)
                        fail_case($sformatf("out1 numerical error profile=%0d head=%0d lane=%0d got=%h ref=%h abs=%g",
                                  profile, head, lane, got_bits,
                                  expected_bits, abs_error));
                end
                for (channel = 64; channel < 256; channel = channel + 1)
                    if (load_word(DST_BASE
                                  + 64'(head * 1024 + channel * 4))
                            !== load_word(SRC0_BASE
                                          + 64'(head * 1024 + channel * 4)))
                        fail_case($sformatf("raw copy mismatch profile=%0d head=%0d channel=%0d",
                                  profile, head, channel));
            end
        end
    endtask

    task automatic run_full_profile(input integer profile);
        integer outputs, reads, writes, data_ops, pairs, raw_words;
        integer limit, busy_start_sent, max_ulp;
        reg [63:0] expected_command, expected_lo, expected_hi;
        real max_abs, max_rel;
        begin
            pulse_reset();
            set_valid_descriptor(profile);
            prepare_memory(profile);
            exact_order_enable_q = 1'b1;
            expected_command = command_id_i;
            expected_lo = canonical_node_id_lo_i;
            expected_hi = canonical_node_id_hi_i;
            outputs = profile == 0 ? 2048 : 512;
            reads = profile == 0 ? 1026 : 258;
            writes = profile == 0 ? 1280 : 320;
            data_ops = profile == 0 ? 512 : 128;
            pairs = profile == 0 ? 256 : 64;
            raw_words = profile == 0 ? 1536 : 384;
            limit = profile == 0 ? 160000 : 60000;
            busy_start_sent = 0;
            launch();
            while (!completion_valid_o && active_cycles_o <= limit) begin
                @(posedge clk_i);
                if (!busy_start_sent && accepted_requests_q >= 16) begin
                    if (!busy_o || ready_o)
                        fail_case("busy identity fixture");
                    command_id_i = 64'hbad0_bad0_bad0_bad0;
                    canonical_node_id_lo_i = 64'h1111;
                    canonical_node_id_hi_i = 64'h2222;
                    start_i = 1'b1;
                    @(posedge clk_i);
                    start_i = 1'b0;
                    command_id_i = expected_command;
                    canonical_node_id_lo_i = expected_lo;
                    canonical_node_id_hi_i = expected_hi;
                    busy_start_sent = 1;
                end
                if (active_cycles_o > limit)
                    fail_case("full profile timeout");
            end
            if (!completion_valid_o)
                fail_case("full profile missing terminal");
            if (!done_o || error_o || !dst_commit_o || poisoned_o)
                fail_case("full profile terminal/commit");
            check_identity(profile);
            if (completion_profile_id_o != (profile == 0 ? PROFILE_Q : PROFILE_K)
                    || completion_profile_census_o != 32'd6)
                fail_case("full profile census");
            if (outputs_computed_o != outputs
                    || outputs_completed_o != outputs
                    || source0_words_completed_o != outputs
                    || position_words_completed_o != 4
                    || position_conversions_completed_o != 4
                    || raw_copy_words_completed_o != raw_words
                    || rotation_pairs_completed_o != pairs
                    || gmem_read_requests_o != reads
                    || gmem_read_responses_o != reads
                    || read_payload_bytes_o != reads * 8
                    || gmem_write_requests_o != writes
                    || gmem_write_responses_o != writes
                    || write_payload_bytes_o != outputs * 4
                    || sincos_requests_o != 32
                    || sincos_responses_o != 32
                    || theta_mul_requests_o != 96
                    || theta_mul_responses_o != 96
                    || data_mul_requests_o != data_ops
                    || data_mul_responses_o != data_ops
                    || fma_requests_o != data_ops
                    || fma_responses_o != data_ops
                    || public_canary_q != 32'h51c0_ffee
                    || held_stability_cycles_q == 0 || !busy_start_sent)
                fail_case("full profile exact counter/canary");
            check_full_outputs(profile, max_abs, max_rel, max_ulp);
            $display("[NPU-ROPE-WRITEBACK][FULL] profile=%0d outputs=%0d reads=%0d/%0dB writes=%0d/%0dB sincos=32 theta_mul=96 data_mul=%0d fma=%0d raw=%0d max_abs=%g max_rel=%g max_ulp=%0d flags=%02x held=%0d cycles=%0d",
                     profile, outputs, reads, reads * 8, writes, outputs * 4,
                     data_ops, data_ops, raw_words, max_abs, max_rel, max_ulp,
                     numeric_flags_o, held_stability_cycles_q,
                     active_cycles_o);
            finish_terminal();
        end
    endtask

    integer init_index;
    initial begin
        clk_i = 1'b0;
        rst_i = 1'b1;
        start_i = 1'b0;
        global_cycles_q = 0;
        public_canary_q = 32'h51c0_ffee;
        exact_order_enable_q = 1'b0;
        backpressure_enable_q = 1'b1;
        fault_ordinal_q = -1;
        late_ordinal_q = -1;
        late_delay_q = 0;
        for (init_index = 0; init_index < MEM_BYTES;
                init_index = init_index + 1)
            memory_q[init_index] = 8'b0;

        pulse_reset();

        set_valid_descriptor(0); manifest_op_id_i = 16'd47;
        run_static_reject(ERR_DESCRIPTOR, "op id");
        set_valid_descriptor(0); source_arity_i = 3'd1;
        run_static_reject(ERR_DESCRIPTOR, "arity");
        set_valid_descriptor(0); op_params_i[160] = ~op_params_i[160];
        run_static_reject(ERR_DESCRIPTOR, "full op params");
        set_valid_descriptor(0); npu_required_i = 1'b0;
        run_static_reject(ERR_DESCRIPTOR, "required");
        set_valid_descriptor(0); dst_shadow_private_i = 1'b0;
        run_static_reject(ERR_DESCRIPTOR, "private destination");
        set_valid_descriptor(0); windows_generation_valid_i = 1'b0;
        run_static_reject(ERR_DESCRIPTOR, "window generation");
        set_valid_descriptor(0); canonical_node_id_lo_i = 64'b0;
        canonical_node_id_hi_i = 64'b0;
        run_static_reject(ERR_DESCRIPTOR, "canonical identity");
        set_valid_descriptor(0); src0_dtype_i = 8'd1;
        run_static_reject(ERR_DESCRIPTOR, "src0 dtype");
        set_valid_descriptor(0); src1_flags_i = 32'b0;
        run_static_reject(ERR_DESCRIPTOR, "position flags");
        set_valid_descriptor(0); dst_ne1_i = 32'd2;
        run_static_reject(ERR_DESCRIPTOR, "mixed destination shape");
        set_valid_descriptor(0); src0_nb2_i = 64'd2048;
        run_static_reject(ERR_DESCRIPTOR, "mixed profile stride");
        set_valid_descriptor(0); src0_window_read_i = 1'b0;
        run_static_reject(ERR_SRC0, "src0 capability");
        set_valid_descriptor(0); src1_window_read_i = 1'b0;
        run_static_reject(ERR_SRC1, "src1 capability");
        set_valid_descriptor(0); dst_window_write_i = 1'b0;
        run_static_reject(ERR_DST, "dst capability");
        set_valid_descriptor(0); src0_base_i = 64'hffff_ffff_ffff_f000;
        src0_window_base_i = 64'hffff_ffff_ffff_f000;
        run_static_reject(ERR_SRC0, "src0 overflow");
        set_valid_descriptor(0); dst_base_i = 64'hffff_ffff_ffff_f000;
        dst_window_base_i = 64'hffff_ffff_ffff_f000;
        run_static_reject(ERR_DST, "dst overflow");
        set_valid_descriptor(0); src1_base_i = SRC0_BASE;
        src1_window_base_i = SRC0_BASE;
        run_static_reject(ERR_ALIAS, "source physical alias");
        set_valid_descriptor(0); dst_base_i = SRC0_BASE;
        dst_window_base_i = SRC0_BASE;
        run_static_reject(ERR_ALIAS, "destination physical alias");
        $display("[NPU-ROPE-WRITEBACK][STATIC] exact rejects=18 zero-traffic");

        run_reset_abort();
        run_late_read_error();
        run_timeout_drain();
        run_late_write_error();
        run_full_profile(0);
        run_full_profile(1);

        $display("[NPU-ROPE-WRITEBACK][PASS] frozen_nodes=12 profiles=2 full_q=2048 full_k=512 static=18 reset=1 late_read=1 timeout_drain=1 late_write=1 backpressure=2 busy=2 abs_threshold=5e-4 bit_exact_claim=0 raw_copy=1920");
        $finish;
    end
endmodule

`default_nettype wire
