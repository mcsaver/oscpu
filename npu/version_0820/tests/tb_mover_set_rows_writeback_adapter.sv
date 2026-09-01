`timescale 1ns/1ps
`default_nettype none

module tb_mover_set_rows_writeback_adapter;
    localparam int MEM_ADDR_W = 20;
    localparam int MEM_BYTES = (1 << MEM_ADDR_W);
    localparam logic [2:0] OP_CPY = 3'd0;
    localparam logic [2:0] OP_CONT = 3'd1;
    localparam logic [2:0] OP_CONCAT = 3'd2;
    localparam logic [2:0] OP_SET_NATIVE = 3'd3;
    localparam logic [2:0] OP_SET_TRANS = 3'd4;

    logic clk;
    logic rst;
    logic start;
    wire ready;
    wire busy;
    logic [2:0] operation;
    logic npu_required;
    logic [63:0] command_id;
    logic [63:0] node_lo;
    logic [63:0] node_hi;
    logic dst_private;
    logic windows_valid;
    logic [31:0] dst_flags;
    logic [511:0] op_params;
    logic [2:0] source_arity;
    logic [31:0] src0_flags;
    logic [31:0] src1_flags;
    logic [31:0] src2_flags;
    logic src2_matches_dst;

    logic [7:0] src0_dtype;
    logic [63:0] src0_region_base;
    logic [63:0] src0_region_size;
    logic [63:0] src0_view_off;
    logic [31:0] src0_ne0, src0_ne1, src0_ne2, src0_ne3;
    logic [63:0] src0_nb0, src0_nb1, src0_nb2, src0_nb3;
    logic [7:0] src1_dtype;
    logic [63:0] src1_region_base;
    logic [63:0] src1_region_size;
    logic [63:0] src1_view_off;
    logic [31:0] src1_ne0, src1_ne1, src1_ne2, src1_ne3;
    logic [63:0] src1_nb0, src1_nb1, src1_nb2, src1_nb3;
    logic [7:0] dst_dtype;
    logic [63:0] dst_region_base;
    logic [63:0] dst_region_size;
    logic [63:0] dst_view_off;
    logic [31:0] dst_ne0, dst_ne1, dst_ne2, dst_ne3;
    logic [63:0] dst_nb0, dst_nb1, dst_nb2, dst_nb3;
    logic [31:0] cache_capacity;
    logic [31:0] physical_slot;

    logic [63:0] src0_window_base, src0_window_bytes;
    logic src0_window_read, src0_window_write;
    logic [63:0] src1_window_base, src1_window_bytes;
    logic src1_window_read, src1_window_write;
    logic [63:0] dst_window_base, dst_window_bytes;
    logic dst_window_read, dst_window_write;

    wire gmem_req_valid;
    logic gmem_req_ready;
    wire gmem_req_write;
    wire [63:0] gmem_req_addr;
    wire [63:0] gmem_req_wdata;
    wire [7:0] gmem_req_wstrb;
    wire gmem_rsp_valid;
    wire gmem_rsp_ready;
    wire [63:0] gmem_rsp_rdata;
    wire gmem_rsp_error;

    wire completion_valid;
    wire dst_commit;
    wire [63:0] completion_command_id;
    wire [63:0] completion_node_lo;
    wire [63:0] completion_node_hi;
    wire completion_required;
    wire [2:0] completion_operation;
    wire [31:0] completion_kernel_id;
    wire done;
    wire error;
    wire [4:0] error_code;
    wire [4:0] child_error_code;
    wire [63:0] indices_completed;
    wire [63:0] source_elements_completed;
    wire [63:0] elements_completed;
    wire [63:0] read_beats;
    wire [63:0] read_responses;
    wire [63:0] read_bytes;
    wire [63:0] write_beats;
    wire [63:0] write_responses;
    wire [63:0] write_bytes;
    wire [63:0] child_active_cycles;
    wire [63:0] active_cycles;
    wire gmem_outstanding;
    wire [63:0] required_issued;
    wire [63:0] required_completed;

    logic [7:0] memory [0:MEM_BYTES-1];
    logic response_pending;
    logic [3:0] response_delay;
    logic [63:0] response_rdata;
    logic response_error;
    logic response_write;
    logic [63:0] response_addr;
    logic [63:0] response_wdata;
    logic [7:0] response_wstrb;
    logic hold_response;
    logic fail_next_read;
    logic fail_next_write;
    logic [63:0] command_req_count;
    logic [63:0] command_rsp_count;
    logic [63:0] last_req_addr;
    logic last_req_write;
    logic memory_model_error;

    logic [63:0] expected_id;
    logic [63:0] expected_node_lo;
    logic [63:0] expected_node_hi;
    logic [2:0] expected_operation;
    logic [63:0] expected_issued;
    logic [63:0] expected_completed;
    integer failures;
    integer i;

    TensorNpuMoverSetRowsWritebackAdapter #(
        .STALL_TIMEOUT_CYCLES(8),
        .COMMAND_TIMEOUT_CYCLES(200000)
    ) dut (
        .clk_i(clk), .rst_i(rst),
        .start_i(start), .ready_o(ready), .busy_o(busy),
        .operation_i(operation), .npu_required_i(npu_required),
        .command_id_i(command_id),
        .canonical_node_id_lo_i(node_lo),
        .canonical_node_id_hi_i(node_hi),
        .dst_shadow_private_i(dst_private),
        .windows_generation_valid_i(windows_valid),
        .dst_descriptor_flags_i(dst_flags), .op_params_i(op_params),
        .source_arity_i(source_arity),
        .src0_descriptor_flags_i(src0_flags),
        .src1_descriptor_flags_i(src1_flags),
        .src2_descriptor_flags_i(src2_flags),
        .src2_matches_dst_i(src2_matches_dst),
        .src0_dtype_i(src0_dtype),
        .src0_region_base_i(src0_region_base),
        .src0_region_size_i(src0_region_size),
        .src0_view_off_i(src0_view_off),
        .src0_ne0_i(src0_ne0), .src0_ne1_i(src0_ne1),
        .src0_ne2_i(src0_ne2), .src0_ne3_i(src0_ne3),
        .src0_nb0_i(src0_nb0), .src0_nb1_i(src0_nb1),
        .src0_nb2_i(src0_nb2), .src0_nb3_i(src0_nb3),
        .src1_dtype_i(src1_dtype),
        .src1_region_base_i(src1_region_base),
        .src1_region_size_i(src1_region_size),
        .src1_view_off_i(src1_view_off),
        .src1_ne0_i(src1_ne0), .src1_ne1_i(src1_ne1),
        .src1_ne2_i(src1_ne2), .src1_ne3_i(src1_ne3),
        .src1_nb0_i(src1_nb0), .src1_nb1_i(src1_nb1),
        .src1_nb2_i(src1_nb2), .src1_nb3_i(src1_nb3),
        .dst_dtype_i(dst_dtype),
        .dst_region_base_i(dst_region_base),
        .dst_region_size_i(dst_region_size),
        .dst_view_off_i(dst_view_off),
        .dst_ne0_i(dst_ne0), .dst_ne1_i(dst_ne1),
        .dst_ne2_i(dst_ne2), .dst_ne3_i(dst_ne3),
        .dst_nb0_i(dst_nb0), .dst_nb1_i(dst_nb1),
        .dst_nb2_i(dst_nb2), .dst_nb3_i(dst_nb3),
        .cache_capacity_i(cache_capacity),
        .physical_slot_i(physical_slot),
        .src0_window_base_i(src0_window_base),
        .src0_window_bytes_i(src0_window_bytes),
        .src0_window_read_i(src0_window_read),
        .src0_window_write_i(src0_window_write),
        .src1_window_base_i(src1_window_base),
        .src1_window_bytes_i(src1_window_bytes),
        .src1_window_read_i(src1_window_read),
        .src1_window_write_i(src1_window_write),
        .dst_window_base_i(dst_window_base),
        .dst_window_bytes_i(dst_window_bytes),
        .dst_window_read_i(dst_window_read),
        .dst_window_write_i(dst_window_write),
        .gmem_req_valid_o(gmem_req_valid),
        .gmem_req_ready_i(gmem_req_ready),
        .gmem_req_write_o(gmem_req_write),
        .gmem_req_addr_o(gmem_req_addr),
        .gmem_req_wdata_o(gmem_req_wdata),
        .gmem_req_wstrb_o(gmem_req_wstrb),
        .gmem_rsp_valid_i(gmem_rsp_valid),
        .gmem_rsp_ready_o(gmem_rsp_ready),
        .gmem_rsp_rdata_i(gmem_rsp_rdata),
        .gmem_rsp_error_i(gmem_rsp_error),
        .completion_valid_o(completion_valid),
        .dst_commit_o(dst_commit),
        .completion_command_id_o(completion_command_id),
        .completion_canonical_node_id_lo_o(completion_node_lo),
        .completion_canonical_node_id_hi_o(completion_node_hi),
        .completion_npu_required_o(completion_required),
        .completion_operation_o(completion_operation),
        .completion_kernel_id_o(completion_kernel_id),
        .done_o(done), .error_o(error),
        .error_code_o(error_code),
        .child_error_code_o(child_error_code),
        .indices_completed_o(indices_completed),
        .source_elements_completed_o(source_elements_completed),
        .elements_completed_o(elements_completed),
        .gmem_read_beats_o(read_beats),
        .gmem_read_responses_o(read_responses),
        .read_payload_bytes_o(read_bytes),
        .gmem_write_beats_o(write_beats),
        .gmem_write_responses_o(write_responses),
        .write_payload_bytes_o(write_bytes),
        .child_active_cycles_o(child_active_cycles),
        .active_cycles_o(active_cycles),
        .gmem_outstanding_o(gmem_outstanding),
        .npu_required_issued_o(required_issued),
        .npu_required_completed_o(required_completed)
    );

    always #5 clk <= ~clk;

    assign gmem_rsp_valid = response_pending
                          && (response_delay == 4'b0)
                          && !hold_response;
    assign gmem_rsp_rdata = response_rdata;
    assign gmem_rsp_error = response_error;

    task automatic fail(input string message);
        begin
            $display("[NPU-MOVER-SET-ROWS][FAIL] %s", message);
            failures = failures + 1;
        end
    endtask

    task automatic check(input logic condition, input string message);
        begin
            if (!condition)
                fail(message);
        end
    endtask

    task automatic put32(input logic [63:0] address,
                         input logic [31:0] value);
        begin
            if (address[63:MEM_ADDR_W] != '0) begin
                fail("put32 address outside local memory");
            end else begin
                memory[address[MEM_ADDR_W-1:0] | MEM_ADDR_W'(0)] = value[7:0];
                memory[address[MEM_ADDR_W-1:0] | MEM_ADDR_W'(1)] = value[15:8];
                memory[address[MEM_ADDR_W-1:0] | MEM_ADDR_W'(2)] = value[23:16];
                memory[address[MEM_ADDR_W-1:0] | MEM_ADDR_W'(3)] = value[31:24];
            end
        end
    endtask

    task automatic put64(input logic [63:0] address,
                         input logic [63:0] value);
        begin
            if (address[63:MEM_ADDR_W] != '0) begin
                fail("put64 address outside local memory");
            end else begin
                memory[address[MEM_ADDR_W-1:0] | MEM_ADDR_W'(0)] = value[7:0];
                memory[address[MEM_ADDR_W-1:0] | MEM_ADDR_W'(1)] = value[15:8];
                memory[address[MEM_ADDR_W-1:0] | MEM_ADDR_W'(2)] = value[23:16];
                memory[address[MEM_ADDR_W-1:0] | MEM_ADDR_W'(3)] = value[31:24];
                memory[address[MEM_ADDR_W-1:0] | MEM_ADDR_W'(4)] = value[39:32];
                memory[address[MEM_ADDR_W-1:0] | MEM_ADDR_W'(5)] = value[47:40];
                memory[address[MEM_ADDR_W-1:0] | MEM_ADDR_W'(6)] = value[55:48];
                memory[address[MEM_ADDR_W-1:0] | MEM_ADDR_W'(7)] = value[63:56];
            end
        end
    endtask

    function automatic logic [31:0] get32(input logic [63:0] address);
        begin
            if (address[63:MEM_ADDR_W] != '0)
                get32 = 32'b0;
            else
                get32 = {memory[address[MEM_ADDR_W-1:0] | MEM_ADDR_W'(3)],
                         memory[address[MEM_ADDR_W-1:0] | MEM_ADDR_W'(2)],
                         memory[address[MEM_ADDR_W-1:0] | MEM_ADDR_W'(1)],
                         memory[address[MEM_ADDR_W-1:0] | MEM_ADDR_W'(0)]};
        end
    endfunction

    function automatic logic [15:0] get16(input logic [63:0] address);
        begin
            if (address[63:MEM_ADDR_W] != '0)
                get16 = 16'b0;
            else
                get16 = {memory[address[MEM_ADDR_W-1:0] | MEM_ADDR_W'(1)],
                         memory[address[MEM_ADDR_W-1:0] | MEM_ADDR_W'(0)]};
        end
    endfunction

    function automatic logic [31:0] raw_pattern(input integer slot);
        begin
            case (slot & 7)
                0: raw_pattern = 32'h00000000;
                1: raw_pattern = 32'h80000000;
                2: raw_pattern = 32'h3f800000;
                3: raw_pattern = 32'hc0000000;
                4: raw_pattern = 32'h33800000;
                5: raw_pattern = 32'h38800000;
                6: raw_pattern = 32'h477fe000;
                default: raw_pattern = 32'hb8000000;
            endcase
        end
    endfunction

    function automatic logic [15:0] half_pattern(input integer slot);
        begin
            case (slot & 7)
                0: half_pattern = 16'h0000;
                1: half_pattern = 16'h8000;
                2: half_pattern = 16'h3c00;
                3: half_pattern = 16'hc000;
                4: half_pattern = 16'h0001;
                5: half_pattern = 16'h0400;
                6: half_pattern = 16'h7bff;
                default: half_pattern = 16'h8200;
            endcase
        end
    endfunction

    always @(posedge clk) begin
        if (rst) begin
            response_pending <= 1'b0;
            response_delay <= 4'b0;
            response_rdata <= 64'b0;
            response_error <= 1'b0;
            response_write <= 1'b0;
            response_addr <= 64'b0;
            response_wdata <= 64'b0;
            response_wstrb <= 8'b0;
            fail_next_read <= 1'b0;
            fail_next_write <= 1'b0;
            command_req_count <= 64'b0;
            command_rsp_count <= 64'b0;
            last_req_addr <= 64'b0;
            last_req_write <= 1'b0;
            memory_model_error <= 1'b0;
        end else begin
            if (response_pending && (response_delay != 4'b0)
                    && !hold_response)
                response_delay <= response_delay - 4'd1;

            if (gmem_req_valid && gmem_req_ready) begin
                if (response_pending) begin
                    memory_model_error <= 1'b1;
                end else begin
                    response_pending <= 1'b1;
                    response_delay <= 4'd1;
                    response_write <= gmem_req_write;
                    response_addr <= gmem_req_addr;
                    response_wdata <= gmem_req_wdata;
                    response_wstrb <= gmem_req_wstrb;
                    command_req_count <= command_req_count + 64'd1;
                    last_req_addr <= gmem_req_addr;
                    last_req_write <= gmem_req_write;
                    if (gmem_req_addr[63:MEM_ADDR_W] != '0) begin
                        response_error <= 1'b1;
                        response_rdata <= 64'b0;
                    end else if (gmem_req_write) begin
                        response_error <= fail_next_write;
                        response_rdata <= 64'b0;
                        fail_next_write <= 1'b0;
                    end else begin
                        response_error <= fail_next_read;
                        fail_next_read <= 1'b0;
                        response_rdata <= {
                            memory[gmem_req_addr[MEM_ADDR_W-1:0] | MEM_ADDR_W'(7)],
                            memory[gmem_req_addr[MEM_ADDR_W-1:0] | MEM_ADDR_W'(6)],
                            memory[gmem_req_addr[MEM_ADDR_W-1:0] | MEM_ADDR_W'(5)],
                            memory[gmem_req_addr[MEM_ADDR_W-1:0] | MEM_ADDR_W'(4)],
                            memory[gmem_req_addr[MEM_ADDR_W-1:0] | MEM_ADDR_W'(3)],
                            memory[gmem_req_addr[MEM_ADDR_W-1:0] | MEM_ADDR_W'(2)],
                            memory[gmem_req_addr[MEM_ADDR_W-1:0] | MEM_ADDR_W'(1)],
                            memory[gmem_req_addr[MEM_ADDR_W-1:0] | MEM_ADDR_W'(0)]};
                    end
                end
            end

            if (gmem_rsp_valid && gmem_rsp_ready) begin
                command_rsp_count <= command_rsp_count + 64'd1;
                if (response_write && !response_error) begin
                    if (response_addr[63:MEM_ADDR_W] != '0) begin
                        memory_model_error <= 1'b1;
                    end else begin
                        if (response_wstrb[0])
                            memory[response_addr[MEM_ADDR_W-1:0] | MEM_ADDR_W'(0)]
                                <= response_wdata[7:0];
                        if (response_wstrb[1])
                            memory[response_addr[MEM_ADDR_W-1:0] | MEM_ADDR_W'(1)]
                                <= response_wdata[15:8];
                        if (response_wstrb[2])
                            memory[response_addr[MEM_ADDR_W-1:0] | MEM_ADDR_W'(2)]
                                <= response_wdata[23:16];
                        if (response_wstrb[3])
                            memory[response_addr[MEM_ADDR_W-1:0] | MEM_ADDR_W'(3)]
                                <= response_wdata[31:24];
                        if (response_wstrb[4])
                            memory[response_addr[MEM_ADDR_W-1:0] | MEM_ADDR_W'(4)]
                                <= response_wdata[39:32];
                        if (response_wstrb[5])
                            memory[response_addr[MEM_ADDR_W-1:0] | MEM_ADDR_W'(5)]
                                <= response_wdata[47:40];
                        if (response_wstrb[6])
                            memory[response_addr[MEM_ADDR_W-1:0] | MEM_ADDR_W'(6)]
                                <= response_wdata[55:48];
                        if (response_wstrb[7])
                            memory[response_addr[MEM_ADDR_W-1:0] | MEM_ADDR_W'(7)]
                                <= response_wdata[63:56];
                    end
                end
                response_pending <= 1'b0;
            end
        end
    end

    task automatic clear_descriptor;
        begin
            start = 1'b0;
            operation = OP_CPY;
            npu_required = 1'b1;
            command_id = 64'h100;
            node_lo = 64'h0123456789abcdef;
            node_hi = 64'hfedcba9876543210;
            dst_private = 1'b1;
            windows_valid = 1'b1;
            dst_flags = 32'h10;
            op_params = 512'b0;
            source_arity = 3'd2;
            src0_flags = 32'h10;
            src1_flags = 32'h10;
            src2_flags = 32'b0;
            src2_matches_dst = 1'b0;
            src0_dtype = 8'd0;
            src0_region_base = 64'h1000;
            src0_region_size = 64'h100;
            src0_view_off = 64'h4;
            src0_ne0 = 32'd2; src0_ne1 = 32'd2;
            src0_ne2 = 32'd1; src0_ne3 = 32'd1;
            src0_nb0 = 64'd8; src0_nb1 = 64'd32;
            src0_nb2 = 64'd64; src0_nb3 = 64'd64;
            src1_dtype = 8'd0;
            src1_region_base = 64'h4000;
            src1_region_size = 64'h100;
            src1_view_off = 64'h10;
            src1_ne0 = 32'd4; src1_ne1 = 32'd1;
            src1_ne2 = 32'd1; src1_ne3 = 32'd1;
            src1_nb0 = 64'd4; src1_nb1 = 64'd16;
            src1_nb2 = 64'd16; src1_nb3 = 64'd16;
            dst_dtype = 8'd0;
            dst_region_base = 64'h8000;
            dst_region_size = 64'h100;
            dst_view_off = 64'h10;
            dst_ne0 = 32'd4; dst_ne1 = 32'd1;
            dst_ne2 = 32'd1; dst_ne3 = 32'd1;
            dst_nb0 = 64'd4; dst_nb1 = 64'd16;
            dst_nb2 = 64'd16; dst_nb3 = 64'd16;
            cache_capacity = 32'b0;
            physical_slot = 32'b0;
            src0_window_base = 64'h1000;
            src0_window_bytes = 64'h100;
            src0_window_read = 1'b1;
            src0_window_write = 1'b0;
            src1_window_base = 64'h4000;
            src1_window_bytes = 64'h100;
            src1_window_read = 1'b1;
            src1_window_write = 1'b0;
            dst_window_base = 64'h8000;
            dst_window_bytes = 64'h100;
            dst_window_read = 1'b0;
            dst_window_write = 1'b1;
            gmem_req_ready = 1'b1;
            hold_response = 1'b0;
            fail_next_read = 1'b0;
            fail_next_write = 1'b0;
            command_req_count = 64'b0;
            command_rsp_count = 64'b0;
        end
    endtask

    task automatic issue_command;
        begin
            while (!ready)
                @(negedge clk);
            expected_id = command_id;
            expected_node_lo = node_lo;
            expected_node_hi = node_hi;
            expected_operation = operation;
            expected_issued = expected_issued + 64'd1;
            @(negedge clk);
            start = 1'b1;
            @(negedge clk);
            start = 1'b0;
        end
    endtask

    task automatic wait_terminal(input logic expect_success,
                                 input integer limit_cycles);
        integer cycles;
        logic [31:0] expected_kernel;
        begin
            cycles = 0;
            while (!completion_valid && (cycles < limit_cycles)) begin
                @(negedge clk);
                cycles = cycles + 1;
            end
            check(completion_valid, "terminal timeout");
            if (completion_valid) begin
                expected_kernel = (expected_operation <= OP_CONCAT)
                                ? 32'h514e0007 : 32'h514e0008;
                check(completion_command_id == expected_id,
                      "command identity changed while resident");
                check(completion_node_lo == expected_node_lo,
                      "node hash low changed while resident");
                check(completion_node_hi == expected_node_hi,
                      "node hash high changed while resident");
                check(completion_required, "REQUIRED echo missing");
                check(completion_operation == expected_operation,
                      "operation identity mismatch");
                check(completion_kernel_id == expected_kernel,
                      "kernel identity mismatch");
                check((^child_error_code) !== 1'bx,
                      "child error payload contained unknown bits");
                check(required_issued == expected_issued,
                      "REQUIRED issued count mismatch");
                check(!gmem_outstanding,
                      "terminal published with GMEM response credit");
                check(command_req_count == command_rsp_count,
                      "terminal request/response imbalance");
                check(active_cycles != 64'b0,
                      "active cycle count was zero");
                if (expect_success) begin
                    expected_completed = expected_completed + 64'd1;
                    if (!done)
                        $display("[NPU-MOVER-SET-ROWS][TERMINAL-DEBUG] op=%0d error=%0d child=%0d reads=%0d writes=%0d",
                                 expected_operation, error_code,
                                 child_error_code, read_beats, write_beats);
                    check(done && !error && dst_commit,
                          "success did not commit exactly once");
                    check(error_code == 5'b0,
                          "success carried an error code");
                end else begin
                    check(error && !done && !dst_commit,
                          "failure became publication-visible");
                    check(error_code != 5'b0,
                          "failure carried no error code");
                end
                check(required_completed == expected_completed,
                      "REQUIRED completed count mismatch");
            end
            @(negedge clk);
            check(!completion_valid, "terminal pulse lasted more than one cycle");
        end
    endtask

    task automatic check_counters(
        input logic [63:0] exp_indices,
        input logic [63:0] exp_source_elements,
        input logic [63:0] exp_elements,
        input logic [63:0] exp_reads,
        input logic [63:0] exp_read_bytes,
        input logic [63:0] exp_writes,
        input logic [63:0] exp_write_bytes);
        begin
            check(indices_completed == exp_indices,
                  "indices_completed mismatch");
            check(source_elements_completed == exp_source_elements,
                  "source_elements_completed mismatch");
            check(elements_completed == exp_elements,
                  "elements_completed mismatch");
            check(read_beats == exp_reads, "read beat count mismatch");
            check(read_responses == exp_reads,
                  "read response count mismatch");
            check(read_bytes == exp_read_bytes,
                  "read payload byte count mismatch");
            check(write_beats == exp_writes,
                  "write beat count mismatch");
            check(write_responses == exp_writes,
                  "write response count mismatch");
            check(write_bytes == exp_write_bytes,
                  "write payload byte count mismatch");
            check(child_active_cycles != 64'b0 || exp_elements == 64'b0,
                  "non-empty child reported zero active cycles");
        end
    endtask

    task automatic seed_small_cpy;
        begin
            put32(64'h1004, 32'h7fc00001);
            put32(64'h100c, 32'h80000000);
            put32(64'h1024, 32'h7f800000);
            put32(64'h102c, 32'h00000001);
            for (i = 32'h00003ff0; i < 32'h00004020; i = i + 1)
                memory[i] = 8'h5a;
            for (i = 32'h00007ff0; i < 32'h00008030; i = i + 1)
                memory[i] = 8'ha5;
        end
    endtask

    task automatic configure_cont_small;
        begin
            clear_descriptor();
            operation = OP_CONT;
            command_id = 64'h202;
            source_arity = 3'd1;
            src1_flags = 32'b0;
            src1_region_base = 64'b0;
            src1_region_size = 64'b0;
            src1_view_off = 64'b0;
            src1_ne0 = 32'b0; src1_ne1 = 32'b0;
            src1_ne2 = 32'b0; src1_ne3 = 32'b0;
            src1_nb0 = 64'b0; src1_nb1 = 64'b0;
            src1_nb2 = 64'b0; src1_nb3 = 64'b0;
            src1_window_base = 64'b0;
            src1_window_bytes = 64'b0;
            src0_view_off = 64'b0;
            src0_nb0 = 64'd4; src0_nb1 = 64'd16;
            src0_nb2 = 64'd32; src0_nb3 = 64'd32;
            put32(64'h1000, 32'h11111111);
            put32(64'h1004, 32'h22222222);
            put32(64'h1010, 32'h33333333);
            put32(64'h1014, 32'h44444444);
        end
    endtask

    task automatic configure_concat_small;
        begin
            clear_descriptor();
            operation = OP_CONCAT;
            command_id = 64'h303;
            src0_view_off = 64'b0;
            src0_ne0 = 32'd2; src0_ne1 = 32'd2;
            src0_nb0 = 64'd4; src0_nb1 = 64'd16;
            src0_nb2 = 64'd32; src0_nb3 = 64'd32;
            src1_view_off = 64'b0;
            src1_ne0 = 32'd1; src1_ne1 = 32'd2;
            src1_ne2 = 32'd1; src1_ne3 = 32'd1;
            src1_nb0 = 64'd8; src1_nb1 = 64'd4;
            src1_nb2 = 64'd8; src1_nb3 = 64'd8;
            dst_ne0 = 32'd3; dst_ne1 = 32'd2;
            dst_nb0 = 64'd4; dst_nb1 = 64'd12;
            dst_nb2 = 64'd24; dst_nb3 = 64'd24;
            put32(64'h1000, 32'ha0a0a0a0);
            put32(64'h1004, 32'hb0b0b0b0);
            put32(64'h1010, 32'hc0c0c0c0);
            put32(64'h1014, 32'hd0d0d0d0);
            put32(64'h4000, 32'he0e0e0e0);
            put32(64'h4004, 32'hf0f0f0f0);
        end
    endtask

    task automatic configure_empty_cpy(input logic [31:0] width,
                                       input logic [63:0] view_bytes,
                                       input logic [63:0] cmd);
        begin
            clear_descriptor();
            operation = OP_CPY;
            command_id = cmd;
            src0_view_off = view_bytes;
            src0_region_size = view_bytes;
            src0_ne0 = width; src0_ne1 = 32'b0;
            src0_ne2 = 32'd1; src0_ne3 = 32'd1;
            src0_nb0 = 64'd4; src0_nb1 = view_bytes;
            src0_nb2 = 64'b0; src0_nb3 = 64'b0;
            src0_window_bytes = view_bytes + 64'd8;
            src1_view_off = view_bytes;
            src1_region_size = view_bytes;
            src1_ne0 = width; src1_ne1 = 32'b0;
            src1_ne2 = 32'd1; src1_ne3 = 32'd1;
            src1_nb0 = 64'd4; src1_nb1 = view_bytes;
            src1_nb2 = 64'b0; src1_nb3 = 64'b0;
            src1_window_bytes = view_bytes + 64'd8;
            dst_view_off = view_bytes;
            dst_region_size = view_bytes;
            dst_ne0 = width; dst_ne1 = 32'b0;
            dst_ne2 = 32'd1; dst_ne3 = 32'd1;
            dst_nb0 = 64'd4; dst_nb1 = view_bytes;
            dst_nb2 = 64'b0; dst_nb3 = 64'b0;
            dst_window_bytes = view_bytes + 64'd8;
        end
    endtask

    task automatic configure_high_profile(input integer profile);
        begin
            clear_descriptor();
            src0_region_base = 64'h0000000200000000;
            src0_window_base = src0_region_base;
            src1_region_base = 64'h0000000300000000;
            src1_window_base = src1_region_base;
            dst_region_base = 64'h0000000400000000;
            dst_window_base = dst_region_base;
            src0_view_off = 64'b0;
            src1_view_off = 64'b0;
            dst_view_off = 64'b0;
            case (profile)
                0: begin
                    operation = OP_CPY;
                    command_id = 64'h500;
                    src0_view_off = 64'd4;
                    src0_ne0 = 32'd3; src0_ne1 = 32'd6144;
                    src0_ne2 = 32'd1; src0_ne3 = 32'd1;
                    src0_nb0 = 64'd4; src0_nb1 = 64'd16;
                    src0_nb2 = 64'd98304; src0_nb3 = 64'd98304;
                    src0_region_size = 64'd98304;
                    src0_window_bytes = 64'd98304;
                    src1_ne0 = 32'd18432; src1_ne1 = 32'd1;
                    src1_ne2 = 32'd1; src1_ne3 = 32'd1;
                    src1_nb0 = 64'd4; src1_nb1 = 64'd73728;
                    src1_nb2 = 64'd73728; src1_nb3 = 64'd73728;
                    src1_region_size = 64'd73728;
                    src1_window_bytes = 64'd73728;
                    dst_ne0 = 32'd18432; dst_ne1 = 32'd1;
                    dst_ne2 = 32'd1; dst_ne3 = 32'd1;
                    dst_nb0 = 64'd4; dst_nb1 = 64'd73728;
                    dst_nb2 = 64'd73728; dst_nb3 = 64'd73728;
                    dst_region_size = 64'd73728;
                    dst_window_bytes = 64'd73728;
                end
                1: begin
                    operation = OP_CPY;
                    command_id = 64'h501;
                    src0_ne0 = 32'd128; src0_ne1 = 32'd128;
                    src0_ne2 = 32'd16; src0_ne3 = 32'd1;
                    src0_nb0 = 64'd4; src0_nb1 = 64'd512;
                    src0_nb2 = 64'd65536; src0_nb3 = 64'd1048576;
                    src0_region_size = 64'd1048576;
                    src0_window_bytes = 64'd1048576;
                    src1_ne0 = 32'd262144; src1_ne1 = 32'd1;
                    src1_ne2 = 32'd1; src1_ne3 = 32'd1;
                    src1_nb0 = 64'd4; src1_nb1 = 64'd1048576;
                    src1_nb2 = 64'd1048576; src1_nb3 = 64'd1048576;
                    src1_region_size = 64'd1048576;
                    src1_window_bytes = 64'd1048576;
                    dst_ne0 = 32'd262144; dst_ne1 = 32'd1;
                    dst_ne2 = 32'd1; dst_ne3 = 32'd1;
                    dst_nb0 = 64'd4; dst_nb1 = 64'd1048576;
                    dst_nb2 = 64'd1048576; dst_nb3 = 64'd1048576;
                    dst_region_size = 64'd1048576;
                    dst_window_bytes = 64'd1048576;
                end
                2: begin
                    operation = OP_CONT;
                    command_id = 64'h502;
                    source_arity = 3'd1;
                    src1_flags = 32'b0;
                    src1_dtype = 8'b0;
                    src1_region_base = 64'b0;
                    src1_region_size = 64'b0;
                    src1_view_off = 64'b0;
                    src1_ne0 = 32'b0; src1_ne1 = 32'b0;
                    src1_ne2 = 32'b0; src1_ne3 = 32'b0;
                    src1_nb0 = 64'b0; src1_nb1 = 64'b0;
                    src1_nb2 = 64'b0; src1_nb3 = 64'b0;
                    src1_window_base = 64'b0;
                    src1_window_bytes = 64'b0;
                    src0_ne0 = 32'd256; src0_ne1 = 32'd8;
                    src0_ne2 = 32'd1; src0_ne3 = 32'd1;
                    src0_nb0 = 64'd4; src0_nb1 = 64'd1024;
                    src0_nb2 = 64'd1024; src0_nb3 = 64'd8192;
                    src0_region_size = 64'd8192;
                    src0_window_bytes = 64'd8192;
                    dst_ne0 = 32'd2048; dst_ne1 = 32'd1;
                    dst_ne2 = 32'd1; dst_ne3 = 32'd1;
                    dst_nb0 = 64'd4; dst_nb1 = 64'd8192;
                    dst_nb2 = 64'd8192; dst_nb3 = 64'd8192;
                    dst_region_size = 64'd8192;
                    dst_window_bytes = 64'd8192;
                end
                3: begin
                    operation = OP_CONT;
                    command_id = 64'h503;
                    source_arity = 3'd1;
                    src1_flags = 32'b0;
                    src1_dtype = 8'b0;
                    src1_region_base = 64'b0;
                    src1_region_size = 64'b0;
                    src1_view_off = 64'b0;
                    src1_ne0 = 32'b0; src1_ne1 = 32'b0;
                    src1_ne2 = 32'b0; src1_ne3 = 32'b0;
                    src1_nb0 = 64'b0; src1_nb1 = 64'b0;
                    src1_nb2 = 64'b0; src1_nb3 = 64'b0;
                    src1_window_base = 64'b0;
                    src1_window_bytes = 64'b0;
                    src0_view_off = 64'd1024;
                    src0_ne0 = 32'd256; src0_ne1 = 32'd8;
                    src0_ne2 = 32'd1; src0_ne3 = 32'd1;
                    src0_nb0 = 64'd4; src0_nb1 = 64'd2048;
                    src0_nb2 = 64'd16384; src0_nb3 = 64'd16384;
                    src0_region_size = 64'd16384;
                    src0_window_bytes = 64'd16384;
                    dst_ne0 = 32'd2048; dst_ne1 = 32'd1;
                    dst_ne2 = 32'd1; dst_ne3 = 32'd1;
                    dst_nb0 = 64'd4; dst_nb1 = 64'd8192;
                    dst_nb2 = 64'd8192; dst_nb3 = 64'd8192;
                    dst_region_size = 64'd8192;
                    dst_window_bytes = 64'd8192;
                end
                default: begin
                    operation = OP_CONCAT;
                    command_id = 64'h504;
                    src0_ne0 = 32'd3; src0_ne1 = 32'd6144;
                    src0_ne2 = 32'd1; src0_ne3 = 32'd1;
                    src0_nb0 = 64'd4; src0_nb1 = 64'd12;
                    src0_nb2 = 64'd73728; src0_nb3 = 64'd73728;
                    src0_region_size = 64'd73728;
                    src0_window_bytes = 64'd73728;
                    src1_ne0 = 32'd1; src1_ne1 = 32'd6144;
                    src1_ne2 = 32'd1; src1_ne3 = 32'd1;
                    src1_nb0 = 64'd24576; src1_nb1 = 64'd4;
                    src1_nb2 = 64'd24576; src1_nb3 = 64'd24576;
                    src1_region_size = 64'd24576;
                    src1_window_bytes = 64'd24576;
                    dst_ne0 = 32'd4; dst_ne1 = 32'd6144;
                    dst_ne2 = 32'd1; dst_ne3 = 32'd1;
                    dst_nb0 = 64'd4; dst_nb1 = 64'd16;
                    dst_nb2 = 64'd98304; dst_nb3 = 64'd98304;
                    dst_region_size = 64'd98304;
                    dst_window_bytes = 64'd98304;
                end
            endcase
        end
    endtask

    task automatic configure_set(input logic transposed,
                                 input logic [63:0] cmd);
        begin
            clear_descriptor();
            operation = transposed ? OP_SET_TRANS : OP_SET_NATIVE;
            command_id = cmd;
            source_arity = 3'd3;
            src0_flags = 32'h10;
            src1_flags = 32'h1;
            src2_flags = transposed ? 32'h10 : 32'h0;
            src2_matches_dst = 1'b1;
            cache_capacity = 32'd256;
            physical_slot = transposed ? 32'd5 : 32'd3;
            src0_region_base = 64'h1000;
            src0_region_size = 64'd2048;
            src0_view_off = 64'b0;
            src0_window_base = src0_region_base;
            src0_window_bytes = 64'd2048;
            src1_dtype = 8'd27;
            src1_region_base = 64'h2000;
            src1_view_off = 64'b0;
            src1_window_base = src1_region_base;
            dst_dtype = 8'd1;
            dst_region_base = 64'h10000;
            dst_region_size = 64'd262144;
            dst_view_off = 64'b0;
            dst_window_base = dst_region_base;
            dst_window_bytes = 64'd262144;
            dst_ne2 = 32'd1; dst_ne3 = 32'd1;
            dst_nb0 = 64'd2;
            dst_nb2 = 64'd262144;
            dst_nb3 = 64'd262144;
            if (transposed) begin
                src0_ne0 = 32'd1; src0_ne1 = 32'd512;
                src0_ne2 = 32'd1; src0_ne3 = 32'd1;
                src0_nb0 = 64'd4; src0_nb1 = 64'd4;
                src0_nb2 = 64'd2048; src0_nb3 = 64'd2048;
                src1_ne0 = 32'd512; src1_ne1 = 32'd1;
                src1_ne2 = 32'd1; src1_ne3 = 32'd1;
                src1_nb0 = 64'd8; src1_nb1 = 64'd4096;
                src1_nb2 = 64'd4096; src1_nb3 = 64'd4096;
                src1_region_size = 64'd4096;
                src1_window_bytes = 64'd4096;
                dst_ne0 = 32'd1; dst_ne1 = 32'd131072;
                dst_nb1 = 64'd2;
            end else begin
                src0_ne0 = 32'd512; src0_ne1 = 32'd1;
                src0_ne2 = 32'd1; src0_ne3 = 32'd1;
                src0_nb0 = 64'd4; src0_nb1 = 64'd2048;
                src0_nb2 = 64'd2048; src0_nb3 = 64'd2048;
                src1_ne0 = 32'd1; src1_ne1 = 32'd1;
                src1_ne2 = 32'd1; src1_ne3 = 32'd1;
                src1_nb0 = 64'd8; src1_nb1 = 64'd8;
                src1_nb2 = 64'd8; src1_nb3 = 64'd8;
                src1_region_size = 64'd8;
                src1_window_bytes = 64'd8;
                dst_ne0 = 32'd512; dst_ne1 = 32'd256;
                dst_nb1 = 64'd1024;
            end
        end
    endtask

    task automatic seed_set_values;
        begin
            for (i = 0; i < 512; i = i + 1)
                put32(64'h1000 + (64'(i) << 2), raw_pattern(i));
        end
    endtask

    initial begin
        clk = 1'b0;
        rst = 1'b1;
        failures = 0;
        expected_issued = 64'b0;
        expected_completed = 64'b0;
        hold_response = 1'b0;
        gmem_req_ready = 1'b1;
        start = 1'b0;
        for (i = 0; i < MEM_BYTES; i = i + 1)
            memory[i] = 8'hc7;
        repeat (4) @(negedge clk);
        rst = 1'b0;
        repeat (2) @(negedge clk);

        // Busy start cannot mutate resident state; reset cancels it and clears
        // both response ownership and cumulative REQUIRED counters.
        clear_descriptor();
        seed_small_cpy();
        gmem_req_ready = 1'b0;
        issue_command();
        while (!gmem_req_valid)
            @(negedge clk);
        check(busy && !ready, "command was not resident while request blocked");
        command_id = 64'hdeadbeef;
        node_lo = 64'hbad0;
        start = 1'b1;
        @(negedge clk);
        start = 1'b0;
        check(required_issued == 64'd1,
              "busy start incorrectly incremented REQUIRED issued");
        rst = 1'b1;
        @(negedge clk);
        rst = 1'b0;
        gmem_req_ready = 1'b1;
        expected_issued = 64'b0;
        expected_completed = 64'b0;
        repeat (2) @(negedge clk);
        check(ready && !completion_valid && !gmem_outstanding,
              "reset did not restore clean ownership");
        check(required_issued == 64'b0 && required_completed == 64'b0,
              "reset did not clear REQUIRED counters");

        // Strided CPY: every logical destination byte is NPU-written, while
        // source-1 old-dst bytes and view-offset canaries remain untouched.
        clear_descriptor();
        command_id = 64'h101;
        seed_small_cpy();
        issue_command();
        wait_terminal(1'b1, 2000);
        check_counters(0, 4, 4, 4, 16, 4, 16);
        check(get32(64'h8010) == 32'h7fc00001, "CPY raw NaN bit loss");
        check(get32(64'h8014) == 32'h80000000, "CPY signed-zero bit loss");
        check(get32(64'h8018) == 32'h7f800000, "CPY infinity bit loss");
        check(get32(64'h801c) == 32'h00000001, "CPY subnormal bit loss");
        check(get32(64'h4000) == 32'h5a5a5a5a
              && get32(64'h4010) == 32'h5a5a5a5a,
              "CPY read or rewrote old-dst dependency bytes");
        check(get32(64'h800c) == 32'ha5a5a5a5
              && get32(64'h8020) == 32'ha5a5a5a5,
              "CPY wrote outside its view-offset logical domain");

        // Request backpressure must hold every payload bit and input mutation
        // must not change completion identity.
        clear_descriptor();
        command_id = 64'h1111222233334444;
        node_lo = 64'h5555666677778888;
        node_hi = 64'h9999aaaabbbbcccc;
        seed_small_cpy();
        gmem_req_ready = 1'b0;
        issue_command();
        while (!gmem_req_valid)
            @(negedge clk);
        last_req_addr = gmem_req_addr;
        last_req_write = gmem_req_write;
        repeat (4) begin
            @(negedge clk);
            check(gmem_req_valid && (gmem_req_addr == last_req_addr)
                  && (gmem_req_write == last_req_write)
                  && (gmem_req_wdata == 64'b0)
                  && (gmem_req_wstrb == 8'b0),
                  "GMEM request changed under backpressure");
            command_id = command_id + 64'd1;
            node_lo = node_lo ^ 64'hffff;
            node_hi = node_hi ^ 64'hffff0000;
        end
        gmem_req_ready = 1'b1;
        wait_terminal(1'b1, 2000);
        check_counters(0, 4, 4, 4, 16, 4, 16);

        // CONT proves logical strided gather to a flat destination.
        configure_cont_small();
        issue_command();
        wait_terminal(1'b1, 2000);
        check_counters(0, 4, 4, 4, 16, 4, 16);
        check(get32(64'h8010) == 32'h11111111
              && get32(64'h8014) == 32'h22222222
              && get32(64'h8018) == 32'h33333333
              && get32(64'h801c) == 32'h44444444,
              "CONT did not flatten logical coordinates");

        // CONCAT proves dim-0 row-wise interleave rather than physical span
        // concatenation.
        configure_concat_small();
        issue_command();
        wait_terminal(1'b1, 3000);
        check_counters(0, 6, 6, 6, 24, 6, 24);
        check(get32(64'h8010) == 32'ha0a0a0a0
              && get32(64'h8014) == 32'hb0b0b0b0
              && get32(64'h8018) == 32'he0e0e0e0
              && get32(64'h801c) == 32'hc0c0c0c0
              && get32(64'h8020) == 32'hd0d0d0d0
              && get32(64'h8024) == 32'hf0f0f0f0,
              "CONCAT0 logical row order mismatch");

        // Both frozen N=0 CPY profiles: legal commit, empty NPU write domain,
        // and absolutely no GMEM request.
        configure_empty_cpy(32'd18432, 64'd73728, 64'h401);
        put32(64'h000000000001a000, 32'h55aa33cc);
        issue_command();
        wait_terminal(1'b1, 100);
        check_counters(0, 0, 0, 0, 0, 0, 0);
        check(command_req_count == 64'b0,
              "18432x0 CPY generated GMEM traffic");
        check(get32(64'h000000000001a000) == 32'h55aa33cc,
              "empty CPY changed the destination backing point");
        configure_empty_cpy(32'd262144, 64'd1048576, 64'h402);
        issue_command();
        wait_terminal(1'b1, 100);
        check_counters(0, 0, 0, 0, 0, 0, 0);
        check(command_req_count == 64'b0,
              "262144x0 CPY generated GMEM traffic");

        // Static capability failure is fail-closed before any child request.
        configure_cont_small();
        command_id = 64'h410;
        src0_window_bytes = 64'd8;
        issue_command();
        wait_terminal(1'b0, 100);
        check(command_req_count == 64'b0,
              "short source capability emitted traffic");
        check_counters(0, 0, 0, 0, 0, 0, 0);

        // Permission inversion is a descriptor-static failure.
        clear_descriptor();
        command_id = 64'h413;
        dst_window_read = 1'b1;
        issue_command();
        wait_terminal(1'b0, 100);
        check(command_req_count == 64'b0,
              "invalid R/RW capability emitted traffic");
        check_counters(0, 0, 0, 0, 0, 0, 0);

        // 128-bit capability-end overflow must be rejected before truncation.
        clear_descriptor();
        command_id = 64'h414;
        src0_window_base = 64'hfffffffffffffff8;
        src0_window_bytes = 64'd16;
        issue_command();
        wait_terminal(1'b0, 100);
        check(command_req_count == 64'b0,
              "overflowing capability endpoint emitted traffic");
        check_counters(0, 0, 0, 0, 0, 0, 0);

        // Semantic source/destination words merely touch, but their aligned
        // eight-byte physical beats alias.  Private writeback must reject it.
        clear_descriptor();
        command_id = 64'h415;
        src0_view_off = 64'b0;
        src0_ne0 = 32'd1; src0_ne1 = 32'd1;
        src0_ne2 = 32'd1; src0_ne3 = 32'd1;
        src0_nb0 = 64'd4; src0_nb1 = 64'd4;
        src0_nb2 = 64'd4; src0_nb3 = 64'd4;
        src0_region_size = 64'd16;
        src0_window_bytes = 64'd8;
        src1_ne0 = 32'd1; src1_ne1 = 32'd1;
        src1_ne2 = 32'd1; src1_ne3 = 32'd1;
        src1_nb0 = 64'd4; src1_nb1 = 64'd4;
        src1_nb2 = 64'd4; src1_nb3 = 64'd4;
        dst_region_base = 64'h1000;
        dst_region_size = 64'd16;
        dst_view_off = 64'd4;
        dst_ne0 = 32'd1; dst_ne1 = 32'd1;
        dst_ne2 = 32'd1; dst_ne3 = 32'd1;
        dst_nb0 = 64'd4; dst_nb1 = 64'd4;
        dst_nb2 = 64'd4; dst_nb3 = 64'd4;
        dst_window_base = 64'h1000;
        dst_window_bytes = 64'd8;
        issue_command();
        wait_terminal(1'b0, 100);
        check(command_req_count == 64'b0,
              "aligned-beat alias emitted traffic");
        check_counters(0, 0, 0, 0, 0, 0, 0);

        // Late write fault changes no private-memory byte and cannot commit.
        clear_descriptor();
        command_id = 64'h411;
        seed_small_cpy();
        fail_next_write = 1'b1;
        issue_command();
        wait_terminal(1'b0, 1000);
        check(get32(64'h8010) == 32'ha5a5a5a5,
              "failed write became private-memory visible");
        check(read_beats == 64'd1 && read_responses == 64'd1
              && read_bytes == 64'd4 && write_beats == 64'd1
              && write_responses == 64'd1 && write_bytes == 64'd0,
              "late-write failure counters were not exact");
        check(elements_completed == 64'b0,
              "failed write counted a completed element");

        // Accepted read timeout retains its sole response credit and publishes
        // no completion until the late response has been drained.
        clear_descriptor();
        command_id = 64'h412;
        seed_small_cpy();
        hold_response = 1'b1;
        issue_command();
        while (!response_pending)
            @(negedge clk);
        repeat (16) @(negedge clk);
        check(!completion_valid && busy && gmem_outstanding,
              "timeout escaped before draining accepted response");
        hold_response = 1'b0;
        wait_terminal(1'b0, 200);
        check(read_beats == 64'd1 && read_responses == 64'd1
              && read_bytes == 64'd4 && write_beats == 64'b0,
              "timeout drain counters were not exact");

        // Every non-SET frozen shape receives widened high-address admission
        // and a first-read late-fault proof.  The exact first aligned address
        // demonstrates that view offsets/products were not truncated.
        for (i = 0; i < 5; i = i + 1) begin
            configure_high_profile(i);
            fail_next_read = 1'b1;
            issue_command();
            wait_terminal(1'b0, 1000);
            $display("[NPU-MOVER-SET-ROWS][PROFILE] id=%0d error=%0d child=%0d first_addr=%016x reads=%0d responses=%0d read_bytes=%0d",
                     i, error_code, child_error_code, last_req_addr,
                     read_beats, read_responses, read_bytes);
            check(read_beats == 64'd1 && read_responses == 64'd1
                  && read_bytes == 64'b0 && write_beats == 64'b0,
                  "high-profile late-read counters mismatch");
            check(last_req_addr[63:32] != 32'b0 && !last_req_write,
                  "high profile lost widened address bits");
        end

        // Exact native-K SET_ROWS.  The RTL converter owns all 512 F32->F16
        // results and the NPU writes exactly one complete cache row.
        configure_set(1'b0, 64'h601);
        seed_set_values();
        put64(64'h2000, 64'd3);
        for (i = 32'h00010000; i < 32'h00050000; i = i + 1)
            memory[i] = 8'h6d;
        issue_command();
        wait_terminal(1'b1, 20000);
        check_counters(1, 512, 512, 513, 2056, 512, 1024);
        for (i = 0; i < 512; i = i + 1)
            check(get16(64'h10c00 + (64'(i) << 1)) == half_pattern(i),
                  "native SET_ROWS raw F16 scatter mismatch");
        check(get16(64'h10bfe) == 16'h6d6d
              && get16(64'h11000) == 16'h6d6d,
              "native SET_ROWS wrote outside its 512-element row");

        // Exact transposed-V SET_ROWS.  Only p within every logical C-stride
        // row changes; adjacent backing bytes remain lifecycle-preserved.
        configure_set(1'b1, 64'h602);
        seed_set_values();
        for (i = 0; i < 512; i = i + 1)
            put64(64'h2000 + (64'(i) << 3), 64'(i * 256 + 5));
        for (i = 32'h00010000; i < 32'h00050000; i = i + 1)
            memory[i] = 8'h3c;
        issue_command();
        wait_terminal(1'b1, 30000);
        check_counters(512, 512, 512, 1024, 6144, 512, 1024);
        for (i = 0; i < 512; i = i + 1) begin
            check(get16(64'h1000a + (64'(i) << 9)) == half_pattern(i),
                  "transposed SET_ROWS raw F16 scatter mismatch");
            check(get16(64'h10008 + (64'(i) << 9)) == 16'h3c3c
                  && get16(64'h1000c + (64'(i) << 9)) == 16'h3c3c,
                  "transposed SET_ROWS changed bytes outside scatter domain");
        end

        // Invalid native index is a child domain terminal after its one raw
        // read; no value read or destination write may begin.
        configure_set(1'b0, 64'h603);
        seed_set_values();
        put64(64'h2000, 64'd4);
        issue_command();
        wait_terminal(1'b0, 1000);
        check(indices_completed == 64'b0
              && read_beats == 64'd1 && read_responses == 64'd1
              && read_bytes == 64'd8 && write_beats == 64'b0,
              "bad SET_ROWS index did not fail before values/writes");

        check(!memory_model_error, "GMEM model observed protocol misuse");
        if (failures == 0) begin
            $display("[NPU-MOVER-SET-ROWS][PASS] profiles=9 required_nodes=114 host_tensor_arithmetic=0 single_outstanding=1");
            $finish;
        end else begin
            $display("[NPU-MOVER-SET-ROWS][FAILURES] count=%0d", failures);
            $finish(1);
        end
    end

endmodule

`default_nettype wire
