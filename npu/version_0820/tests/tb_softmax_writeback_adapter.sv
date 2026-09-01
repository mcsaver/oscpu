`timescale 1ns/1ps
`default_nettype none

module tb_softmax_writeback_adapter;

    localparam integer ELEMENTS = 256;
    localparam integer HEADS = 8;
    localparam integer OUTPUTS = ELEMENTS * HEADS;
    localparam integer MEM_BYTES = 65536;
    localparam integer STALL_TIMEOUT = 32;
    localparam logic [63:0] SRC0_BASE = 64'h0000_0000_0000_0000;
    localparam logic [63:0] MASK_BASE = 64'h0000_0000_0000_4000;
    localparam logic [63:0] DST_BASE  = 64'h0000_0000_0000_8000;
    localparam logic [31:0] KERNEL_REDUCE_F32 = 32'h514e0011;

    localparam logic [4:0] ERR_DESCRIPTOR = 5'd1;
    localparam logic [4:0] ERR_SRC0 = 5'd2;
    localparam logic [4:0] ERR_SRC1 = 5'd3;
    localparam logic [4:0] ERR_DST = 5'd4;
    localparam logic [4:0] ERR_ALIAS = 5'd5;
    localparam logic [4:0] ERR_GMEM = 5'd6;
    localparam logic [4:0] ERR_NUMERIC = 5'd7;
    localparam logic [4:0] ERR_STALL = 5'd8;
    localparam logic [4:0] ERR_PROTOCOL = 5'd11;

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
    wire [2:0] completion_reduce_op_o;
    wire [15:0] completion_manifest_op_id_o;
    wire [2:0] completion_source_arity_o;
    wire [7:0] completion_profile_id_o;
    wire [31:0] completion_kernel_id_o;
    wire [31:0] completion_operator_census_o;
    wire [31:0] completion_profile_census_o;
    wire done_o, error_o;
    wire [4:0] error_code_o, numeric_flags_o;
    wire [3:0] exp_error_code_o;
    wire poisoned_o;
    wire [63:0] rows_completed_o, source0_words_completed_o;
    wire [63:0] mask_words_completed_o, outputs_computed_o;
    wire [63:0] outputs_completed_o, max_comparisons_o;
    wire [63:0] gmem_read_requests_o, gmem_read_responses_o;
    wire [63:0] read_payload_bytes_o;
    wire [63:0] gmem_write_requests_o, gmem_write_responses_o;
    wire [63:0] write_payload_bytes_o;
    wire [63:0] scale_requests_o, scale_responses_o;
    wire [63:0] mask_add_requests_o, mask_add_responses_o;
    wire [63:0] subtract_requests_o, subtract_responses_o;
    wire [63:0] exp_requests_o, exp_responses_o;
    wire [63:0] sum_add_requests_o, sum_add_responses_o;
    wire [63:0] div_requests_o, div_responses_o;
    wire [63:0] normalize_mul_requests_o, normalize_mul_responses_o;
    wire [63:0] exp_active_cycles_o, active_cycles_o;
    wire gmem_outstanding_o, addmul_outstanding_o;
    wire exp_outstanding_o, div_outstanding_o, gmem_drain_o;

    TensorNpuSoftmaxWritebackAdapter #(
        .STALL_TIMEOUT_CYCLES(STALL_TIMEOUT),
        .COMMAND_TIMEOUT_CYCLES(64'd2000000),
        .DRAIN_TIMEOUT_CYCLES(32'd96),
        .ABORT_HOLD_TIMEOUT_CYCLES(32'd96)
    ) dut (.*);

    initial clk_i = 1'b0;
    always #5 clk_i <= ~clk_i;

    reg [7:0] gmem [0:MEM_BYTES-1];
    real expected_value [0:OUTPUTS-1];
    reg allow_requests_q, backpressure_q, check_order_q;
    integer normal_delay_q;
    integer inject_read_error_ordinal_q, inject_write_error_ordinal_q;
    integer late_request_ordinal_q, late_delay_q;
    reg pending_q, pending_write_q, pending_error_q;
    reg [63:0] pending_addr_q, pending_wdata_q;
    reg [7:0] pending_wstrb_q;
    integer pending_delay_q;
    integer global_cycles, accepted_requests, accepted_reads, accepted_writes;
    integer responses, successful_writes, completions, commits, drain_seen;
    reg held_request_q, held_write_q;
    reg [63:0] held_addr_q, held_wdata_q;
    reg [7:0] held_wstrb_q;

    assign gmem_req_ready_i = !rst_i && allow_requests_q && !pending_q
                            && !gmem_rsp_valid_i
                            && (!backpressure_q || (global_cycles[1:0] != 2'b00));

    function automatic [63:0] memory_read64(input logic [63:0] address);
        integer base;
        integer lane;
        begin
            base = address;
            memory_read64 = 64'b0;
            for (lane = 0; lane < 8; lane = lane + 1)
                memory_read64[(lane*8) +: 8] = gmem[base + lane];
        end
    endfunction

    function automatic [31:0] memory_read32(input integer address);
        begin
            memory_read32 = {gmem[address+3], gmem[address+2],
                             gmem[address+1], gmem[address]};
        end
    endfunction

    task automatic memory_write32(input integer address, input logic [31:0] value);
        begin
            gmem[address]   = value[7:0];
            gmem[address+1] = value[15:8];
            gmem[address+2] = value[23:16];
            gmem[address+3] = value[31:24];
        end
    endtask

    function automatic [31:0] source_pattern(input integer head, input integer index);
        integer selector;
        begin
            selector = (index + head*7) % 16;
            case (selector)
                0: source_pattern = 32'hc0800000;
                1: source_pattern = 32'hc0600000;
                2: source_pattern = 32'hc0400000;
                3: source_pattern = 32'hc0200000;
                4: source_pattern = 32'hc0000000;
                5: source_pattern = 32'hbfc00000;
                6: source_pattern = 32'hbf800000;
                7: source_pattern = 32'hbf000000;
                8: source_pattern = 32'h00000000;
                9: source_pattern = 32'h3f000000;
                10: source_pattern = 32'h3f800000;
                11: source_pattern = 32'h3fc00000;
                12: source_pattern = 32'h40000000;
                13: source_pattern = 32'h40200000;
                14: source_pattern = 32'h40400000;
                default: source_pattern = 32'h40600000;
            endcase
        end
    endfunction

    function automatic [31:0] mask_pattern(input integer index);
        begin
            if (index >= 224)
                mask_pattern = 32'hc1800000;
            else begin
                case (index % 8)
                    0: mask_pattern = 32'h00000000;
                    1: mask_pattern = 32'hbe800000;
                    2: mask_pattern = 32'hbf000000;
                    3: mask_pattern = 32'hbf800000;
                    4: mask_pattern = 32'h00000000;
                    5: mask_pattern = 32'hc0000000;
                    6: mask_pattern = 32'hc0800000;
                    default: mask_pattern = 32'hc1000000;
                endcase
            end
        end
    endfunction

    // Independent test-only raw binary32 decoder.  It intentionally uses real
    // arithmetic and host $exp below rather than replaying the DUT's AOR DAG.
    function automatic real fp32_to_real(input logic [31:0] bits);
        integer exponent;
        integer mantissa;
        integer shift;
        real value;
        begin
            exponent = bits[30:23];
            mantissa = bits[22:0];
            if ((exponent == 0) && (mantissa == 0)) begin
                value = 0.0;
            end else if (exponent == 0) begin
                value = mantissa / 8388608.0;
                for (shift = 0; shift < 126; shift = shift + 1)
                    value = value / 2.0;
            end else begin
                value = 1.0 + mantissa / 8388608.0;
                if (exponent >= 127)
                    for (shift = 127; shift < exponent; shift = shift + 1)
                        value = value * 2.0;
                else
                    for (shift = exponent; shift < 127; shift = shift + 1)
                        value = value / 2.0;
            end
            fp32_to_real = bits[31] ? -value : value;
        end
    endfunction

    function automatic real abs_real(input real value);
        begin
            abs_real = (value < 0.0) ? -value : value;
        end
    endfunction

    task automatic fail_case(input string reason);
        begin
            $display("[NPU-SOFTMAX-WRITEBACK][FAIL] %s cycle=%0d state busy/done/error=%0b/%0b/%0b err=%0d exp_err=%0d poison=%0b",
                     reason, global_cycles, busy_o, done_o, error_o,
                     error_code_o, exp_error_code_o, poisoned_o);
            $display("[NPU-SOFTMAX-WRITEBACK][EVIDENCE] row=%0d src/mask/out=%0d/%0d/%0d/%0d max=%0d read=%0d/%0d/%0dB write=%0d/%0d/%0dB scale=%0d/%0d maskadd=%0d/%0d sub=%0d/%0d exp=%0d/%0d sum=%0d/%0d div=%0d/%0d norm=%0d/%0d owners=%0b%0b%0b%0b drain=%0b",
                     rows_completed_o, source0_words_completed_o,
                     mask_words_completed_o, outputs_computed_o,
                     outputs_completed_o, max_comparisons_o,
                     gmem_read_requests_o, gmem_read_responses_o,
                     read_payload_bytes_o, gmem_write_requests_o,
                     gmem_write_responses_o, write_payload_bytes_o,
                     scale_requests_o, scale_responses_o,
                     mask_add_requests_o, mask_add_responses_o,
                     subtract_requests_o, subtract_responses_o,
                     exp_requests_o, exp_responses_o,
                     sum_add_requests_o, sum_add_responses_o,
                     div_requests_o, div_responses_o,
                     normalize_mul_requests_o, normalize_mul_responses_o,
                     gmem_outstanding_o, addmul_outstanding_o,
                     exp_outstanding_o, div_outstanding_o, gmem_drain_o);
            $fatal(1);
        end
    endtask

    /* verilator lint_off BLKSEQ */
    always @(posedge clk_i) begin
        integer lane;
        reg request_error;
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
            responses <= 0;
            successful_writes <= 0;
            completions <= 0;
            commits <= 0;
            drain_seen <= 0;
            held_request_q <= 1'b0;
            held_write_q <= 1'b0;
            held_addr_q <= 64'b0;
            held_wdata_q <= 64'b0;
            held_wstrb_q <= 8'b0;
        end else begin
            global_cycles <= global_cycles + 1;
            if (gmem_drain_o)
                drain_seen <= drain_seen + 1;
            if (completion_valid_o)
                completions <= completions + 1;
            if (dst_commit_o)
                commits <= commits + 1;

            if (dst_commit_o !== done_o)
                fail_case("commit must equal successful terminal only");
            if (completion_valid_o && (gmem_outstanding_o
                    || addmul_outstanding_o || exp_outstanding_o
                    || div_outstanding_o || gmem_drain_o))
                fail_case("terminal published with outstanding owner");
            if ((addmul_outstanding_o + exp_outstanding_o
                    + div_outstanding_o) > 1)
                fail_case("more than one numeric owner resident");

            if (held_request_q) begin
                if (!gmem_req_valid_o || (gmem_req_write_o !== held_write_q)
                        || (gmem_req_addr_o !== held_addr_q)
                        || (gmem_req_wdata_o !== held_wdata_q)
                        || (gmem_req_wstrb_o !== held_wstrb_q))
                    fail_case("held GMEM request changed or withdrew");
                if (gmem_req_ready_i)
                    held_request_q <= 1'b0;
            end else if (gmem_req_valid_o && !gmem_req_ready_i) begin
                held_request_q <= 1'b1;
                held_write_q <= gmem_req_write_o;
                held_addr_q <= gmem_req_addr_o;
                held_wdata_q <= gmem_req_wdata_o;
                held_wstrb_q <= gmem_req_wstrb_o;
            end

            if (gmem_req_valid_o && gmem_req_ready_i) begin
                if (pending_q || gmem_rsp_valid_i)
                    fail_case("second request accepted while response resident");
                if (gmem_req_addr_o[2:0] != 3'b000)
                    fail_case("unaligned GMEM request");
                if (gmem_req_write_o) begin
                    if (gmem_req_wstrb_o != 8'hff)
                        fail_case("write was not a full private 8-byte beat");
                    if (check_order_q
                            && (gmem_req_addr_o !== DST_BASE + accepted_writes*8))
                        fail_case("destination write address/order mismatch");
                    accepted_writes <= accepted_writes + 1;
                end else begin
                    if ((gmem_req_wdata_o != 64'b0) || (gmem_req_wstrb_o != 8'b0))
                        fail_case("read request leaked write payload");
                    if (check_order_q) begin
                        if ((accepted_reads < 128)
                                && (gmem_req_addr_o !== MASK_BASE + accepted_reads*8))
                            fail_case("mask preload address/order mismatch");
                        if ((accepted_reads >= 128)
                                && (gmem_req_addr_o
                                    !== SRC0_BASE + (accepted_reads-128)*8))
                            fail_case("source address/order mismatch");
                    end
                    accepted_reads <= accepted_reads + 1;
                end
                request_error = (!gmem_req_write_o
                                 && (inject_read_error_ordinal_q
                                     == accepted_reads + 1))
                             || (gmem_req_write_o
                                 && (inject_write_error_ordinal_q
                                     == accepted_writes + 1));
                pending_q <= 1'b1;
                pending_write_q <= gmem_req_write_o;
                pending_error_q <= request_error;
                pending_addr_q <= gmem_req_addr_o;
                pending_wdata_q <= gmem_req_wdata_o;
                pending_wstrb_q <= gmem_req_wstrb_o;
                if (late_request_ordinal_q == accepted_requests + 1)
                    pending_delay_q <= late_delay_q;
                else
                    pending_delay_q <= normal_delay_q;
                accepted_requests <= accepted_requests + 1;
            end

            if (gmem_rsp_valid_i) begin
                if (gmem_rsp_ready_o) begin
                    if (pending_write_q && !gmem_rsp_error_i) begin
                        for (lane = 0; lane < 8; lane = lane + 1)
                            if (pending_wstrb_q[lane])
                                gmem[pending_addr_q + lane]
                                    = pending_wdata_q[(lane*8) +: 8];
                        successful_writes <= successful_writes + 1;
                    end
                    responses <= responses + 1;
                    gmem_rsp_valid_i <= 1'b0;
                    gmem_rsp_rdata_i <= 64'b0;
                    gmem_rsp_error_i <= 1'b0;
                end
            end else if (pending_q) begin
                if (pending_delay_q == 0) begin
                    gmem_rsp_valid_i <= 1'b1;
                    gmem_rsp_rdata_i <= pending_write_q
                                      ? 64'b0 : memory_read64(pending_addr_q);
                    gmem_rsp_error_i <= pending_error_q;
                    pending_q <= 1'b0;
                end else
                    pending_delay_q <= pending_delay_q - 1;
            end
        end
    end
    /* verilator lint_on BLKSEQ */

    task automatic set_valid_profile;
        begin
            reduce_op_i = 3'd6;
            manifest_op_id_i = 16'd46;
            source_arity_i = 3'd2;
            op_params_i = {96'b0, 32'h3d800000};
            op_params_tail_zero_i = 1'b1;
            npu_required_i = 1'b1;
            command_id_i = 64'h51a0_0000_0000_0046;
            canonical_node_id_lo_i = 64'h5ae4_9c2a_6ee4_77e1;
            canonical_node_id_hi_i = 64'h3351_a941_f5d9_8c44;
            dst_shadow_private_i = 1'b1;
            windows_generation_valid_i = 1'b1;
            src0_dtype_i = 8'd0; src0_flags_i = 32'd16; src0_view_off_i = 64'b0;
            src0_ne0_i = 32'd256; src0_ne1_i = 32'd1;
            src0_ne2_i = 32'd8; src0_ne3_i = 32'd1;
            src0_base_i = SRC0_BASE;
            src0_nb0_i = 64'd4; src0_nb1_i = 64'd1024;
            src0_nb2_i = 64'd1024; src0_nb3_i = 64'd8192;
            src1_dtype_i = 8'd0; src1_flags_i = 32'd1; src1_view_off_i = 64'b0;
            src1_ne0_i = 32'd256; src1_ne1_i = 32'd1;
            src1_ne2_i = 32'd1; src1_ne3_i = 32'd1;
            src1_base_i = MASK_BASE;
            src1_nb0_i = 64'd4; src1_nb1_i = 64'd1024;
            src1_nb2_i = 64'd1024; src1_nb3_i = 64'd1024;
            dst_dtype_i = 8'd0; dst_flags_i = 32'd16; dst_view_off_i = 64'b0;
            dst_ne0_i = 32'd256; dst_ne1_i = 32'd1;
            dst_ne2_i = 32'd8; dst_ne3_i = 32'd1;
            dst_base_i = DST_BASE;
            dst_nb0_i = 64'd4; dst_nb1_i = 64'd1024;
            dst_nb2_i = 64'd1024; dst_nb3_i = 64'd8192;
            src0_window_base_i = SRC0_BASE; src0_window_bytes_i = 64'd8192;
            src0_window_read_i = 1'b1; src0_window_write_i = 1'b0;
            src1_window_base_i = MASK_BASE; src1_window_bytes_i = 64'd1024;
            src1_window_read_i = 1'b1; src1_window_write_i = 1'b0;
            dst_window_base_i = DST_BASE; dst_window_bytes_i = 64'd8192;
            dst_window_read_i = 1'b0; dst_window_write_i = 1'b1;
        end
    endtask

    task automatic clear_model_controls;
        begin
            allow_requests_q = 1'b1;
            backpressure_q = 1'b0;
            check_order_q = 1'b0;
            normal_delay_q = 1;
            inject_read_error_ordinal_q = -1;
            inject_write_error_ordinal_q = -1;
            late_request_ordinal_q = -1;
            late_delay_q = 1;
        end
    endtask

    task automatic reset_model_counts;
        begin
            accepted_requests = 0;
            accepted_reads = 0;
            accepted_writes = 0;
            responses = 0;
            successful_writes = 0;
            completions = 0;
            commits = 0;
            drain_seen = 0;
        end
    endtask

    task automatic wait_idle;
        integer cycles;
        begin
            cycles = 0;
            while (!ready_o && (cycles < 200)) begin
                @(posedge clk_i); #1;
                cycles = cycles + 1;
            end
            if (!ready_o)
                fail_case("adapter did not return to ready");
        end
    endtask

    task automatic launch_command;
        begin
            wait_idle();
            @(negedge clk_i);
            start_i = 1'b1;
            @(posedge clk_i); #1;
            start_i = 1'b0;
            if (!busy_o)
                fail_case("start did not enter busy state");
        end
    endtask

    task automatic wait_terminal(input logic expect_error,
                                 input logic [4:0] expected_code,
                                 input integer timeout_cycles);
        integer cycles;
        begin
            cycles = 0;
            while (!completion_valid_o && (cycles < timeout_cycles)) begin
                @(posedge clk_i); #1;
                cycles = cycles + 1;
            end
            if (!completion_valid_o)
                fail_case("terminal timeout");
            if (error_o !== expect_error || error_code_o !== expected_code)
                fail_case("terminal kind/error code mismatch");
            if (completion_command_id_o !== command_id_i
                    || completion_canonical_node_id_lo_o
                        !== canonical_node_id_lo_i
                    || completion_canonical_node_id_hi_o
                        !== canonical_node_id_hi_i
                    || !completion_npu_required_o
                    || completion_reduce_op_o !== reduce_op_i
                    || completion_manifest_op_id_o !== manifest_op_id_i
                    || completion_source_arity_o !== source_arity_i)
                fail_case("terminal identity mismatch");
        end
    endtask

    task automatic initialize_numeric_data;
        integer address;
        integer head;
        integer index;
        real score;
        real maximum;
        real total;
        begin
            for (address = 0; address < MEM_BYTES; address = address + 1)
                gmem[address] = 8'h00;
            for (index = 0; index < ELEMENTS; index = index + 1)
                memory_write32(MASK_BASE + index*4, mask_pattern(index));
            for (head = 0; head < HEADS; head = head + 1)
                for (index = 0; index < ELEMENTS; index = index + 1)
                    memory_write32(SRC0_BASE + head*1024 + index*4,
                                   source_pattern(head,index));

            for (head = 0; head < HEADS; head = head + 1) begin
                maximum = -1.0e300;
                for (index = 0; index < ELEMENTS; index = index + 1) begin
                    score = fp32_to_real(source_pattern(head,index)) * 0.0625
                          + fp32_to_real(mask_pattern(index));
                    expected_value[head*ELEMENTS + index] = score;
                    if (score > maximum)
                        maximum = score;
                end
                total = 0.0;
                for (index = 0; index < ELEMENTS; index = index + 1) begin
                    expected_value[head*ELEMENTS + index]
                        = $exp(expected_value[head*ELEMENTS + index] - maximum);
                    total = total + expected_value[head*ELEMENTS + index];
                end
                for (index = 0; index < ELEMENTS; index = index + 1)
                    expected_value[head*ELEMENTS + index]
                        = expected_value[head*ELEMENTS + index] / total;
            end
        end
    endtask

    task automatic check_numerical_output;
        integer head;
        integer index;
        real actual;
        real expected;
        real absolute_error;
        real relative_error;
        real maximum_absolute_error;
        real maximum_relative_error;
        real row_sum;
        begin
            maximum_absolute_error = 0.0;
            maximum_relative_error = 0.0;
            for (head = 0; head < HEADS; head = head + 1) begin
                row_sum = 0.0;
                for (index = 0; index < ELEMENTS; index = index + 1) begin
                    actual = fp32_to_real(memory_read32(DST_BASE
                                             + head*1024 + index*4));
                    expected = expected_value[head*ELEMENTS + index];
                    absolute_error = abs_real(actual - expected);
                    relative_error = absolute_error
                                   / ((expected > 1.0e-30) ? expected : 1.0e-30);
                    if (absolute_error > maximum_absolute_error)
                        maximum_absolute_error = absolute_error;
                    if (relative_error > maximum_relative_error)
                        maximum_relative_error = relative_error;
                    if ((absolute_error > 2.0e-7) && (relative_error > 5.0e-5))
                        fail_case("AOR output exceeded explicit software-reference tolerance");
                    if (actual < 0.0)
                        fail_case("negative softmax output");
                    row_sum = row_sum + actual;
                end
                if (abs_real(row_sum - 1.0) > 2.0e-5)
                    fail_case("softmax row sum exceeded tolerance");
            end
            $display("[NPU-SOFTMAX-WRITEBACK][NUMERIC] oracle=host-double-exp tolerance_abs=2e-7 tolerance_rel=5e-5 max_abs=%e max_rel=%e bit_exact_claim=0",
                     maximum_absolute_error, maximum_relative_error);
        end
    endtask

    task automatic preflight_negative(input integer which,
                                      input logic [4:0] expected_error);
        begin
            set_valid_profile();
            case (which)
                0: reduce_op_i = 3'd5;
                1: src0_window_bytes_i = 64'd8184;
                2: src1_window_bytes_i = 64'd1016;
                3: dst_shadow_private_i = 1'b0;
                4: begin
                    dst_base_i = SRC0_BASE;
                    dst_window_base_i = SRC0_BASE;
                    dst_window_bytes_i = 64'd8192;
                end
                default: dst_window_bytes_i = 64'd8184;
            endcase
            reset_model_counts();
            launch_command();
            wait_terminal(1'b1, expected_error, 100);
            if ((accepted_requests != 0) || (commits != 0)
                    || (gmem_read_requests_o != 0)
                    || (gmem_write_requests_o != 0))
                fail_case("preflight failure produced traffic or commit");
        end
    endtask

    integer init_index;
    initial begin
        rst_i = 1'b1;
        start_i = 1'b0;
        gmem_rsp_valid_i = 1'b0;
        gmem_rsp_rdata_i = 64'b0;
        gmem_rsp_error_i = 1'b0;
        set_valid_profile();
        clear_model_controls();
        for (init_index = 0; init_index < MEM_BYTES; init_index = init_index + 1)
            gmem[init_index] = 8'b0;

        repeat (5) @(posedge clk_i);
        @(negedge clk_i);
        rst_i = 1'b0;
        #1;
        if (!ready_o)
            fail_case("adapter not ready after reset");

        preflight_negative(0, ERR_DESCRIPTOR);
        preflight_negative(1, ERR_SRC0);
        preflight_negative(2, ERR_SRC1);
        preflight_negative(3, ERR_DESCRIPTOR);
        preflight_negative(4, ERR_ALIAS);
        preflight_negative(5, ERR_DST);

        set_valid_profile();
        initialize_numeric_data();
        clear_model_controls();
        backpressure_q = 1'b1;
        check_order_q = 1'b1;
        reset_model_counts();
        launch_command();
        wait_terminal(1'b0, 5'd0, 800000);
        if (!dst_commit_o || (commits != 0))
            fail_case("successful terminal did not expose one private commit");
        if (completion_profile_id_o != 8'd0
                || completion_kernel_id_o != KERNEL_REDUCE_F32
                || completion_operator_census_o != 32'd6
                || completion_profile_census_o != 32'd1)
            fail_case("completion census/profile/kernel mismatch");
        if (rows_completed_o != 64'd8
                || source0_words_completed_o != 64'd2048
                || mask_words_completed_o != 64'd256
                || outputs_computed_o != 64'd2048
                || outputs_completed_o != 64'd2048
                || max_comparisons_o != 64'd2048
                || gmem_read_requests_o != 64'd1152
                || gmem_read_responses_o != 64'd1152
                || read_payload_bytes_o != 64'd9216
                || gmem_write_requests_o != 64'd1024
                || gmem_write_responses_o != 64'd1024
                || write_payload_bytes_o != 64'd8192)
            fail_case("successful transport/work counters mismatch");
        if (scale_requests_o != 64'd2048 || scale_responses_o != 64'd2048
                || mask_add_requests_o != 64'd2048
                || mask_add_responses_o != 64'd2048
                || subtract_requests_o != 64'd2048
                || subtract_responses_o != 64'd2048
                || exp_requests_o != 64'd2048 || exp_responses_o != 64'd2048
                || sum_add_requests_o != 64'd2048
                || sum_add_responses_o != 64'd2048
                || div_requests_o != 64'd8 || div_responses_o != 64'd8
                || normalize_mul_requests_o != 64'd2048
                || normalize_mul_responses_o != 64'd2048)
            fail_case("successful numeric request/response counters mismatch");
        if (numeric_flags_o[4:2] != 3'b0 || exp_error_code_o != 4'b0
                || exp_active_cycles_o == 64'b0)
            fail_case("unexpected successful numeric status");
        check_numerical_output();
        wait_idle();
        if (commits != 1)
            fail_case("successful private commit was not counted exactly once");

        // Accepted read error: no destination traffic and no commit.
        set_valid_profile(); initialize_numeric_data(); clear_model_controls();
        inject_read_error_ordinal_q = 5;
        reset_model_counts(); launch_command();
        wait_terminal(1'b1, ERR_GMEM, 1000);
        if ((accepted_writes != 0) || (commits != 0)
                || (gmem_write_requests_o != 0))
            fail_case("read error leaked destination traffic/commit");

        // A late private write failure may leave an unpublished prefix, but
        // must never publish it as a committed destination.
        wait_idle();
        set_valid_profile(); initialize_numeric_data(); clear_model_controls();
        inject_write_error_ordinal_q = 3;
        reset_model_counts(); launch_command();
        wait_terminal(1'b1, ERR_GMEM, 150000);
        if ((commits != 0) || (gmem_write_requests_o != 64'd3)
                || (gmem_write_responses_o != 64'd3)
                || (outputs_completed_o != 64'd4)
                || (write_payload_bytes_o != 64'd16))
            fail_case("late private write error accounting/commit mismatch");

        // An accepted request whose response crosses STALL_TIMEOUT must enter
        // drain and terminate only after the late response is consumed.
        wait_idle();
        set_valid_profile(); initialize_numeric_data(); clear_model_controls();
        late_request_ordinal_q = 1;
        late_delay_q = STALL_TIMEOUT + 8;
        reset_model_counts(); launch_command();
        wait_terminal(1'b1, ERR_STALL, 1000);
        if ((accepted_requests != 1) || (responses != 1)
                || (drain_seen == 0) || poisoned_o || (commits != 0))
            fail_case("late-response drain audit mismatch");

        // An unaccepted exposed request is held stable after timeout.  Once
        // accepted, it is drained rather than silently withdrawn.
        wait_idle();
        set_valid_profile(); initialize_numeric_data(); clear_model_controls();
        allow_requests_q = 1'b0;
        reset_model_counts(); launch_command();
        repeat (STALL_TIMEOUT + 5) @(posedge clk_i);
        if (!gmem_req_valid_o || accepted_requests != 0)
            fail_case("request-stall case did not retain exposed request");
        allow_requests_q = 1'b1;
        wait_terminal(1'b1, ERR_STALL, 500);
        if ((accepted_requests != 1) || (responses != 1)
                || (drain_seen == 0) || (commits != 0))
            fail_case("request-hold abort/drain accounting mismatch");

        // NaN is not admitted into the raw max tree or destination.
        wait_idle();
        set_valid_profile(); initialize_numeric_data();
        memory_write32(SRC0_BASE, 32'h7fc00000);
        clear_model_controls(); reset_model_counts(); launch_command();
        wait_terminal(1'b1, ERR_NUMERIC, 10000);
        if ((accepted_writes != 0) || (commits != 0)
                || (exp_requests_o != 0) || (div_requests_o != 0))
            fail_case("NaN numeric failure leaked later phase/write/commit");

        // An unsolicited response while a command is resident is a protocol
        // violation.  It poisons this owner, publishes no commit, and requires
        // reset before another command may be admitted.
        wait_idle();
        set_valid_profile(); initialize_numeric_data(); clear_model_controls();
        reset_model_counts(); launch_command();
        @(negedge clk_i);
        gmem_rsp_valid_i = 1'b1;
        gmem_rsp_rdata_i = 64'hfeed_face_dead_beef;
        gmem_rsp_error_i = 1'b0;
        wait_terminal(1'b1, ERR_PROTOCOL, 100);
        if (!poisoned_o || (accepted_requests != 0) || (commits != 0)
                || dst_commit_o)
            fail_case("unsolicited response protocol poison mismatch");

        @(negedge clk_i);
        rst_i = 1'b1;
        repeat (3) @(posedge clk_i);
        @(negedge clk_i);
        rst_i = 1'b0;
        #1;
        if (!ready_o || poisoned_o || completion_valid_o
                || gmem_outstanding_o || addmul_outstanding_o
                || exp_outstanding_o || div_outstanding_o)
            fail_case("reset did not recover protocol poison cleanly");

        $display("[NPU-SOFTMAX-WRITEBACK][PASS] census=6/1 profile=0 kernel=0x0011 rows=8 elements=2048 mask_broadcast=8 fixed_f32_sum_order=0..255 private_commit=1 negatives=descriptor,src0_bounds,src1_bounds,dst_bounds,dst_private,alias,read_error,write_error,response_drain,request_hold,nan,protocol_poison_reset");
        $finish;
    end

endmodule

`default_nettype wire
