`timescale 1ns/1ps
`default_nettype none
`include "tensor_npu_defs.vh"

// Directed public-port verification of the raw F32 lane portal.  Numerical
// expectations are produced only by an independent TensorNpuFp32AddMul RTL
// instance; the testbench performs raw operand selection and bit comparison.
module tb_f32_alu_portal_adapter;

    localparam logic [31:0] KERNEL_VECTOR_F32 = 32'h514e0010;
    localparam logic [31:0] FLAGS_PROFILE = 32'h00000010;
    localparam logic [31:0] OP_ADD   = 32'd1;
    localparam logic [31:0] OP_MUL   = 32'd2;
    localparam logic [31:0] OP_SUB   = 32'd3;
    localparam logic [31:0] OP_SCALE = 32'd4;
    localparam logic [63:0] SRC0_BASE = 64'h0000000000100000;
    localparam logic [63:0] SRC1_BASE = 64'h0000000000200000;
    localparam logic [63:0] DST_BASE  = 64'h0000000000400000;
    localparam logic [31:0] SCALE_P16 = 32'h3db504f3;

    localparam logic [31:0] ABI_ERROR_CAPABILITY = 32'd3;
    localparam logic [31:0] ABI_ERROR_LAYOUT = 32'd4;
    localparam logic [31:0] ABI_ERROR_GMEM = 32'd6;
    localparam logic [31:0] ABI_ERROR_TIMEOUT = 32'd10;
    localparam logic [31:0] ABI_ERROR_PROTOCOL = 32'd11;

    logic clk_i;
    logic rst_i;

    logic        abi_valid_i;
    logic [31:0] kernel_id_i;
    logic [31:0] command_flags_i;
    logic [31:0] capability_epoch_i;
    logic [31:0] node_count_i;
    logic [63:0] deadline_cycles_i;
    logic [31:0] vector_op_i;
    logic [31:0] vector_flags_i;
    logic [63:0] src0_iova_i;
    logic [63:0] src1_iova_i;
    logic [63:0] src2_iova_i;
    logic [63:0] dst_iova_i;
    logic [63:0] scratch_iova_i;
    logic [63:0] element_count_i;
    logic [31:0] outer_count_i;
    logic [31:0] dtype_i;
    logic [63:0] src0_stride_i;
    logic [63:0] src1_stride_i;
    logic [63:0] src2_stride_i;
    logic [63:0] dst_stride_i;
    logic [31:0] scalar0_i;
    logic [31:0] scalar1_i;
    logic [31:0] scratch_bytes_i;
    logic [31:0] rope_position_i;
    logic [63:0] src0_window_base_i;
    logic [63:0] src0_window_size_i;
    logic [1:0]  src0_window_perm_i;
    logic [63:0] src1_window_base_i;
    logic [63:0] src1_window_size_i;
    logic [1:0]  src1_window_perm_i;
    logic [63:0] dst_window_base_i;
    logic [63:0] dst_window_size_i;
    logic [1:0]  dst_window_perm_i;
    logic        windows_generation_valid_i;

    logic start_main;
    wire ready_main;
    wire busy_main;
    wire req_valid_main;
    logic req_ready_main;
    wire req_write_main;
    wire [7:0] req_mask_main;
    wire [511:0] req_src0_addr_main;
    wire [511:0] req_src1_addr_main;
    wire [511:0] req_dst_addr_main;
    wire [255:0] req_wdata_main;
    logic rsp_valid_main;
    wire rsp_ready_main;
    logic [7:0] rsp_mask_main;
    logic [255:0] rsp_src0_main;
    logic [255:0] rsp_src1_main;
    logic rsp_error_main;
    wire done_main;
    wire error_main;
    wire [7:0] error_code_main;
    wire [31:0] error_class_main;
    wire [63:0] gmem_read_main;
    wire [63:0] gmem_write_main;
    wire [63:0] vector_elements_main;
    wire [63:0] expected_gmem_read_main;
    wire [63:0] expected_gmem_write_main;
    wire [63:0] expected_elements_main;
    wire gmem_outstanding_main;
    wire f32_start_main;
    wire [63:0] portal_requests_main;
    wire [63:0] portal_responses_main;
    wire [63:0] read_groups_main;
    wire [63:0] write_groups_main;
    wire [63:0] input_words_main;
    wire [63:0] output_words_main;
    wire [63:0] read_bytes_main;
    wire [63:0] write_bytes_main;
    wire portal_outstanding_main;

    logic start_tail;
    wire ready_tail;
    wire busy_tail;
    wire req_valid_tail;
    logic req_ready_tail;
    wire req_write_tail;
    wire [5:0] req_mask_tail;
    wire [383:0] req_src0_addr_tail;
    wire [383:0] req_src1_addr_tail;
    wire [383:0] req_dst_addr_tail;
    wire [191:0] req_wdata_tail;
    logic rsp_valid_tail;
    wire rsp_ready_tail;
    logic [5:0] rsp_mask_tail;
    logic [191:0] rsp_src0_tail;
    logic [191:0] rsp_src1_tail;
    logic rsp_error_tail;
    wire done_tail;
    wire error_tail;
    wire [7:0] error_code_tail;
    wire [31:0] error_class_tail;
    wire [63:0] gmem_read_tail;
    wire [63:0] gmem_write_tail;
    wire [63:0] vector_elements_tail;
    wire [63:0] expected_gmem_read_tail;
    wire [63:0] expected_gmem_write_tail;
    wire [63:0] expected_elements_tail;
    wire gmem_outstanding_tail;
    wire f32_start_tail;
    wire [63:0] portal_requests_tail;
    wire [63:0] portal_responses_tail;
    wire [63:0] read_groups_tail;
    wire [63:0] write_groups_tail;
    wire [63:0] input_words_tail;
    wire [63:0] output_words_tail;
    wire [63:0] read_bytes_tail;
    wire [63:0] write_bytes_tail;
    wire portal_outstanding_tail;

    logic oracle_req_valid;
    wire oracle_req_ready;
    logic oracle_op_mul;
    logic [31:0] oracle_lhs;
    logic [31:0] oracle_rhs;
    wire oracle_rsp_valid;
    logic oracle_rsp_ready;
    wire [31:0] oracle_result;
    wire [4:0] oracle_flags;
    logic [31:0] expected_result [0:3][0:2047];
    logic [4:0] expected_flags [0:3][0:2047];

    integer cycle_count;
    integer request_hold_count;
    integer response_hold_count;
    integer tail_observed;
    integer broadcast_observed;
    integer busy_start_tested;

    TensorNpuF32AluPortalAdapter #(
        .STALL_TIMEOUT_CYCLES  (32'd64),
        .COMMAND_TIMEOUT_CYCLES(64'd200000)
    ) dut_main (
        .clk_i(clk_i), .rst_i(rst_i),
        .start_valid_i(start_main), .start_ready_o(ready_main),
        .busy_o(busy_main),
        .abi_valid_i(abi_valid_i), .kernel_id_i(kernel_id_i),
        .command_flags_i(command_flags_i),
        .capability_epoch_i(capability_epoch_i),
        .node_count_i(node_count_i),
        .deadline_cycles_i(deadline_cycles_i),
        .vector_op_i(vector_op_i), .vector_flags_i(vector_flags_i),
        .src0_iova_i(src0_iova_i), .src1_iova_i(src1_iova_i),
        .src2_iova_i(src2_iova_i), .dst_iova_i(dst_iova_i),
        .scratch_iova_i(scratch_iova_i),
        .element_count_i(element_count_i), .outer_count_i(outer_count_i),
        .dtype_i(dtype_i), .src0_stride_i(src0_stride_i),
        .src1_stride_i(src1_stride_i), .src2_stride_i(src2_stride_i),
        .dst_stride_i(dst_stride_i), .scalar0_i(scalar0_i),
        .scalar1_i(scalar1_i), .scratch_bytes_i(scratch_bytes_i),
        .rope_position_i(rope_position_i),
        .src0_window_base_i(src0_window_base_i),
        .src0_window_size_i(src0_window_size_i),
        .src0_window_perm_i(src0_window_perm_i),
        .src1_window_base_i(src1_window_base_i),
        .src1_window_size_i(src1_window_size_i),
        .src1_window_perm_i(src1_window_perm_i),
        .dst_window_base_i(dst_window_base_i),
        .dst_window_size_i(dst_window_size_i),
        .dst_window_perm_i(dst_window_perm_i),
        .windows_generation_valid_i(windows_generation_valid_i),
        .req_valid_o(req_valid_main), .req_ready_i(req_ready_main),
        .req_write_o(req_write_main), .req_mask_o(req_mask_main),
        .req_src0_addr_o(req_src0_addr_main),
        .req_src1_addr_o(req_src1_addr_main),
        .req_dst_addr_o(req_dst_addr_main), .req_wdata_o(req_wdata_main),
        .rsp_valid_i(rsp_valid_main), .rsp_ready_o(rsp_ready_main),
        .rsp_mask_i(rsp_mask_main), .rsp_src0_data_i(rsp_src0_main),
        .rsp_src1_data_i(rsp_src1_main), .rsp_error_i(rsp_error_main),
        .done_o(done_main), .error_o(error_main),
        .error_code_o(error_code_main), .error_class_o(error_class_main),
        .gmem_read_bytes_o(gmem_read_main),
        .gmem_write_bytes_o(gmem_write_main),
        .vector_elements_o(vector_elements_main),
        .expected_gmem_read_bytes_o(expected_gmem_read_main),
        .expected_gmem_write_bytes_o(expected_gmem_write_main),
        .expected_vector_elements_o(expected_elements_main),
        .gmem_outstanding_o(gmem_outstanding_main),
        .f32_start_pulse_o(f32_start_main),
        .portal_request_groups_o(portal_requests_main),
        .portal_response_groups_o(portal_responses_main),
        .portal_read_groups_o(read_groups_main),
        .portal_write_groups_o(write_groups_main),
        .input_words_o(input_words_main), .output_words_o(output_words_main),
        .read_bytes_o(read_bytes_main), .write_bytes_o(write_bytes_main),
        .portal_outstanding_o(portal_outstanding_main)
    );

    TensorNpuF32AluPortalAdapter #(
        .LANES(6),
        .STALL_TIMEOUT_CYCLES  (32'd64),
        .COMMAND_TIMEOUT_CYCLES(64'd200000)
    ) dut_tail (
        .clk_i(clk_i), .rst_i(rst_i),
        .start_valid_i(start_tail), .start_ready_o(ready_tail),
        .busy_o(busy_tail),
        .abi_valid_i(abi_valid_i), .kernel_id_i(kernel_id_i),
        .command_flags_i(command_flags_i),
        .capability_epoch_i(capability_epoch_i),
        .node_count_i(node_count_i),
        .deadline_cycles_i(deadline_cycles_i),
        .vector_op_i(vector_op_i), .vector_flags_i(vector_flags_i),
        .src0_iova_i(src0_iova_i), .src1_iova_i(src1_iova_i),
        .src2_iova_i(src2_iova_i), .dst_iova_i(dst_iova_i),
        .scratch_iova_i(scratch_iova_i),
        .element_count_i(element_count_i), .outer_count_i(outer_count_i),
        .dtype_i(dtype_i), .src0_stride_i(src0_stride_i),
        .src1_stride_i(src1_stride_i), .src2_stride_i(src2_stride_i),
        .dst_stride_i(dst_stride_i), .scalar0_i(scalar0_i),
        .scalar1_i(scalar1_i), .scratch_bytes_i(scratch_bytes_i),
        .rope_position_i(rope_position_i),
        .src0_window_base_i(src0_window_base_i),
        .src0_window_size_i(src0_window_size_i),
        .src0_window_perm_i(src0_window_perm_i),
        .src1_window_base_i(src1_window_base_i),
        .src1_window_size_i(src1_window_size_i),
        .src1_window_perm_i(src1_window_perm_i),
        .dst_window_base_i(dst_window_base_i),
        .dst_window_size_i(dst_window_size_i),
        .dst_window_perm_i(dst_window_perm_i),
        .windows_generation_valid_i(windows_generation_valid_i),
        .req_valid_o(req_valid_tail), .req_ready_i(req_ready_tail),
        .req_write_o(req_write_tail), .req_mask_o(req_mask_tail),
        .req_src0_addr_o(req_src0_addr_tail),
        .req_src1_addr_o(req_src1_addr_tail),
        .req_dst_addr_o(req_dst_addr_tail), .req_wdata_o(req_wdata_tail),
        .rsp_valid_i(rsp_valid_tail), .rsp_ready_o(rsp_ready_tail),
        .rsp_mask_i(rsp_mask_tail), .rsp_src0_data_i(rsp_src0_tail),
        .rsp_src1_data_i(rsp_src1_tail), .rsp_error_i(rsp_error_tail),
        .done_o(done_tail), .error_o(error_tail),
        .error_code_o(error_code_tail), .error_class_o(error_class_tail),
        .gmem_read_bytes_o(gmem_read_tail),
        .gmem_write_bytes_o(gmem_write_tail),
        .vector_elements_o(vector_elements_tail),
        .expected_gmem_read_bytes_o(expected_gmem_read_tail),
        .expected_gmem_write_bytes_o(expected_gmem_write_tail),
        .expected_vector_elements_o(expected_elements_tail),
        .gmem_outstanding_o(gmem_outstanding_tail),
        .f32_start_pulse_o(f32_start_tail),
        .portal_request_groups_o(portal_requests_tail),
        .portal_response_groups_o(portal_responses_tail),
        .portal_read_groups_o(read_groups_tail),
        .portal_write_groups_o(write_groups_tail),
        .input_words_o(input_words_tail), .output_words_o(output_words_tail),
        .read_bytes_o(read_bytes_tail), .write_bytes_o(write_bytes_tail),
        .portal_outstanding_o(portal_outstanding_tail)
    );

    TensorNpuFp32AddMul u_oracle_addmul (
        .clk_i(clk_i), .rst_i(rst_i),
        .req_valid_i(oracle_req_valid), .req_ready_o(oracle_req_ready),
        .op_mul_i(oracle_op_mul), .lhs_bits_i(oracle_lhs),
        .rhs_bits_i(oracle_rhs), .rsp_valid_o(oracle_rsp_valid),
        .rsp_ready_i(oracle_rsp_ready), .result_bits_o(oracle_result),
        .flags_o(oracle_flags)
    );

    initial clk_i = 1'b0;
    always #5 clk_i <= ~clk_i;

    always @(posedge clk_i) begin
        cycle_count <= cycle_count + 1;
        if (cycle_count >= 1000000) begin
            $fatal(1, "F32 portal global timeout cycle=%0d", cycle_count);
        end
        if (!rst_i) begin
            if ((done_main || error_main) && portal_outstanding_main)
                $fatal(1, "main terminal published with portal outstanding");
            if ((done_tail || error_tail) && portal_outstanding_tail)
                $fatal(1, "tail terminal published with portal outstanding");
            if ((gmem_read_main != 0) || (gmem_write_main != 0)
                    || (expected_gmem_read_main != 0)
                    || (expected_gmem_write_main != 0)
                    || gmem_outstanding_main
                    || (gmem_read_tail != 0) || (gmem_write_tail != 0)
                    || (expected_gmem_read_tail != 0)
                    || (expected_gmem_write_tail != 0)
                    || gmem_outstanding_tail) begin
                $fatal(1, "raw portal fabricated legacy GMEM accounting");
            end
        end
    end

    task automatic step_cycle;
        begin
            @(posedge clk_i);
            #1;
        end
    endtask

    function automatic [31:0] raw_lhs(input integer selector);
        begin
            case (selector % 13)
                0: raw_lhs = 32'h00000000;
                1: raw_lhs = 32'h80000000;
                2: raw_lhs = 32'h00000001;
                3: raw_lhs = 32'h807fffff;
                4: raw_lhs = 32'h3f800000;
                5: raw_lhs = 32'hc0200000;
                6: raw_lhs = 32'h7f800000;
                7: raw_lhs = 32'hff800000;
                8: raw_lhs = 32'h7fc12345;
                9: raw_lhs = 32'h7fa12345;
                10: raw_lhs = 32'h7f7fffff;
                11: raw_lhs = 32'h00800000;
                default: raw_lhs = 32'h40400000;
            endcase
        end
    endfunction

    function automatic [31:0] raw_rhs(input integer selector);
        begin
            case (selector % 13)
                0: raw_rhs = 32'h80000000;
                1: raw_rhs = 32'h00000000;
                2: raw_rhs = 32'h00000002;
                3: raw_rhs = 32'h40000000;
                4: raw_rhs = 32'hbf800000;
                5: raw_rhs = 32'h7f800000;
                6: raw_rhs = 32'h00000000;
                7: raw_rhs = 32'hff800000;
                8: raw_rhs = 32'h3f800000;
                9: raw_rhs = 32'h7fc54321;
                10: raw_rhs = 32'h40000000;
                11: raw_rhs = 32'h00000001;
                default: raw_rhs = 32'hc0400000;
            endcase
        end
    endfunction

    function automatic [31:0] lhs_for(
        input integer slot,
        input integer index
    );
        begin
            lhs_for = raw_lhs(index + (slot * 2));
        end
    endfunction

    function automatic [31:0] rhs_for(
        input integer slot,
        input integer index
    );
        begin
            if (slot == 1)
                rhs_for = raw_rhs((index / 128) + 7);
            else
                rhs_for = raw_rhs(index + (slot * 3));
        end
    endfunction

    function automatic integer slot_count(input integer slot);
        begin
            slot_count = (slot == 0) ? 16 : 2048;
        end
    endfunction

    function automatic integer slot_profile(input integer slot);
        begin
            case (slot)
                0: slot_profile = 0;
                1: slot_profile = 7;
                2: slot_profile = 15;
                default: slot_profile = 16;
            endcase
        end
    endfunction

    function automatic integer profile_slot(input integer profile);
        begin
            case (profile)
                0: profile_slot = 0;
                7: profile_slot = 1;
                15: profile_slot = 2;
                default: profile_slot = 3;
            endcase
        end
    endfunction

    function automatic integer profile_total(input integer profile);
        begin
            case (profile)
                0: profile_total = 16;
                7, 15, 16: profile_total = 2048;
                default: profile_total = 262144;
            endcase
        end
    endfunction

    function automatic [63:0] expected_src0_addr(
        input integer profile,
        input integer index
    );
        reg [63:0] flat_offset;
        begin
            flat_offset = {32'b0, index[31:0]} << 2;
            expected_src0_addr = SRC0_BASE + flat_offset;
            if (profile == 15)
                expected_src0_addr = expected_src0_addr + 64'd16384;
        end
    endfunction

    function automatic [63:0] expected_src1_addr(
        input integer profile,
        input integer index
    );
        begin
            if ((profile == 16) || (profile == 18)) begin
                expected_src1_addr = 64'b0;
            end else if (profile == 7) begin
                expected_src1_addr = SRC1_BASE
                                   + ({32'b0, (index / 128)} << 2);
            end else begin
                expected_src1_addr = SRC1_BASE
                                   + ({32'b0, index[31:0]} << 2);
            end
        end
    endfunction

    function automatic [63:0] expected_dst_addr(input integer index);
        begin
            expected_dst_addr = DST_BASE + ({32'b0, index[31:0]} << 2);
        end
    endfunction

    function automatic [7:0] mask8_for(input integer base_index,
                                        input integer total);
        integer lane;
        begin
            mask8_for = 8'b0;
            for (lane = 0; lane < 8; lane = lane + 1) begin
                if ((base_index + lane) < total)
                    mask8_for[lane] = 1'b1;
            end
        end
    endfunction

    function automatic [5:0] mask6_for(input integer base_index,
                                        input integer total);
        integer lane;
        begin
            mask6_for = 6'b0;
            for (lane = 0; lane < 6; lane = lane + 1) begin
                if ((base_index + lane) < total)
                    mask6_for[lane] = 1'b1;
            end
        end
    endfunction

    task automatic build_one_oracle(input integer slot,
                                     input integer index);
        integer guard;
        reg [31:0] selected_rhs;
        reg [31:0] held_result;
        reg [4:0] held_flags;
        begin
            guard = 0;
            while (!oracle_req_ready) begin
                step_cycle();
                guard = guard + 1;
                if (guard > 1000)
                    $fatal(1, "oracle request timeout");
            end
            selected_rhs = rhs_for(slot, index);
            if (slot == 2)
                selected_rhs = {~selected_rhs[31], selected_rhs[30:0]};
            else if (slot == 3)
                selected_rhs = SCALE_P16;
            oracle_op_mul = (slot == 1) || (slot == 3);
            oracle_lhs = lhs_for(slot, index);
            oracle_rhs = selected_rhs;
            oracle_rsp_ready = 1'b0;
            @(negedge clk_i);
            oracle_req_valid = 1'b1;
            step_cycle();
            oracle_req_valid = 1'b0;
            guard = 0;
            while (!oracle_rsp_valid) begin
                step_cycle();
                guard = guard + 1;
                if (guard > 1000)
                    $fatal(1, "oracle response timeout");
            end
            held_result = oracle_result;
            held_flags = oracle_flags;
            step_cycle();
            if (!oracle_rsp_valid || (oracle_result !== held_result)
                    || (oracle_flags !== held_flags)) begin
                $fatal(1, "oracle response hold changed");
            end
            expected_result[slot][index] = held_result;
            expected_flags[slot][index] = held_flags;
            @(negedge clk_i);
            oracle_rsp_ready = 1'b1;
            step_cycle();
            oracle_rsp_ready = 1'b0;
        end
    endtask

    task automatic build_oracle_table;
        integer slot;
        integer index;
        begin
            for (slot = 0; slot < 4; slot = slot + 1) begin
                for (index = 0; index < slot_count(slot);
                     index = index + 1) begin
                    build_one_oracle(slot, index);
                end
            end
        end
    endtask

    task automatic setup_descriptor(input integer profile);
        begin
            abi_valid_i = 1'b1;
            kernel_id_i = KERNEL_VECTOR_F32;
            command_flags_i = FLAGS_PROFILE;
            capability_epoch_i = 32'h00000001;
            node_count_i = 32'd1;
            deadline_cycles_i = 64'b0;
            vector_flags_i = profile;
            src2_iova_i = 64'b0;
            dst_iova_i = DST_BASE;
            scratch_iova_i = 64'b0;
            dtype_i = 32'd1;
            src2_stride_i = 64'b0;
            scalar1_i = 32'b0;
            scratch_bytes_i = 32'b0;
            rope_position_i = 32'b0;
            src0_window_base_i = SRC0_BASE;
            src0_window_perm_i = 2'b01;
            dst_window_base_i = DST_BASE;
            dst_window_perm_i = 2'b10;
            windows_generation_valid_i = 1'b1;
            case (profile)
                0: begin
                    vector_op_i = OP_ADD;
                    src0_iova_i = SRC0_BASE;
                    src1_iova_i = SRC1_BASE;
                    element_count_i = 64'd16;
                    outer_count_i = 32'd1;
                    src0_stride_i = 64'd64;
                    src1_stride_i = 64'd64;
                    dst_stride_i = 64'd64;
                    scalar0_i = 32'b0;
                    src0_window_size_i = 64'd64;
                    src1_window_base_i = SRC1_BASE;
                    src1_window_size_i = 64'd64;
                    src1_window_perm_i = 2'b01;
                    dst_window_size_i = 64'd64;
                end
                7: begin
                    vector_op_i = OP_MUL;
                    src0_iova_i = SRC0_BASE;
                    src1_iova_i = SRC1_BASE;
                    element_count_i = 64'd128;
                    outer_count_i = 32'd16;
                    src0_stride_i = 64'd512;
                    src1_stride_i = 64'd4;
                    dst_stride_i = 64'd512;
                    scalar0_i = 32'b0;
                    src0_window_size_i = 64'd8192;
                    src1_window_base_i = SRC1_BASE;
                    src1_window_size_i = 64'd64;
                    src1_window_perm_i = 2'b01;
                    dst_window_size_i = 64'd8192;
                end
                15: begin
                    vector_op_i = OP_SUB;
                    src0_iova_i = SRC0_BASE + 64'd16384;
                    src1_iova_i = SRC1_BASE;
                    element_count_i = 64'd128;
                    outer_count_i = 32'd16;
                    src0_stride_i = 64'd24576;
                    src1_stride_i = 64'd4;
                    dst_stride_i = 64'd512;
                    scalar0_i = 32'b0;
                    src0_window_size_i = 64'd24576;
                    src1_window_base_i = SRC1_BASE;
                    src1_window_size_i = 64'd8192;
                    src1_window_perm_i = 2'b01;
                    dst_window_size_i = 64'd8192;
                end
                16: begin
                    vector_op_i = OP_SCALE;
                    src0_iova_i = SRC0_BASE;
                    src1_iova_i = 64'b0;
                    element_count_i = 64'd128;
                    outer_count_i = 32'd16;
                    src0_stride_i = 64'd512;
                    src1_stride_i = 64'b0;
                    dst_stride_i = 64'd512;
                    scalar0_i = SCALE_P16;
                    src0_window_size_i = 64'd8192;
                    src1_window_base_i = 64'b0;
                    src1_window_size_i = 64'b0;
                    src1_window_perm_i = 2'b00;
                    dst_window_size_i = 64'd8192;
                end
                default: begin
                    vector_op_i = OP_SCALE;
                    src0_iova_i = SRC0_BASE;
                    src1_iova_i = 64'b0;
                    element_count_i = 64'd262144;
                    outer_count_i = 32'd1;
                    src0_stride_i = 64'd1048576;
                    src1_stride_i = 64'b0;
                    dst_stride_i = 64'd1048576;
                    scalar0_i = 32'b0;
                    src0_window_size_i = 64'd1048576;
                    src1_window_base_i = 64'b0;
                    src1_window_size_i = 64'b0;
                    src1_window_perm_i = 2'b00;
                    dst_window_size_i = 64'd1048576;
                end
            endcase
        end
    endtask

    task automatic issue_start_main;
        integer guard;
        begin
            guard = 0;
            while (!ready_main) begin
                step_cycle();
                guard = guard + 1;
                if (guard > 2000)
                    $fatal(1, "main idle timeout");
            end
            @(negedge clk_i);
            start_main = 1'b1;
            step_cycle();
            start_main = 1'b0;
        end
    endtask

    task automatic launch_main(input integer profile);
        integer guard;
        begin
            setup_descriptor(profile);
            issue_start_main();
            guard = 0;
            while (!f32_start_main) begin
                step_cycle();
                guard = guard + 1;
                if (error_main)
                    $fatal(1, "valid profile rejected profile=%0d", profile);
                if (guard > 2000)
                    $fatal(1, "child start timeout profile=%0d", profile);
            end
            if (!busy_main || ready_main
                    || (expected_elements_main != profile_total(profile))) begin
                $fatal(1, "main child start metadata mismatch profile=%0d",
                       profile);
            end
        end
    endtask

    task automatic check_main_request(
        input integer profile,
        input integer base_index,
        input integer write_request
    );
        integer lane;
        integer index;
        integer slot;
        reg [7:0] expected_mask;
        begin
            slot = profile_slot(profile);
            expected_mask = mask8_for(base_index, profile_total(profile));
            if ((req_write_main !== write_request[0])
                    || (req_mask_main !== expected_mask)) begin
                $fatal(1, "main request type/mask mismatch profile=%0d base=%0d",
                       profile, base_index);
            end
            for (lane = 0; lane < 8; lane = lane + 1) begin
                index = base_index + lane;
                if (expected_mask[lane]) begin
                    if (!write_request) begin
                        if (req_src0_addr_main[(lane*64) +: 64]
                                !== expected_src0_addr(profile, index)) begin
                            $fatal(1, "src0 address mismatch profile=%0d index=%0d",
                                   profile, index);
                        end
                        if (req_src1_addr_main[(lane*64) +: 64]
                                !== expected_src1_addr(profile, index)) begin
                            $fatal(1, "src1 address mismatch profile=%0d index=%0d",
                                   profile, index);
                        end
                        if ((req_dst_addr_main[(lane*64) +: 64] != 0)
                                || (req_wdata_main[(lane*32) +: 32] != 0)) begin
                            $fatal(1, "read request leaked write fields");
                        end
                    end else begin
                        if ((req_src0_addr_main[(lane*64) +: 64] != 0)
                                || (req_src1_addr_main[(lane*64) +: 64] != 0)
                                || (req_dst_addr_main[(lane*64) +: 64]
                                    !== expected_dst_addr(index))
                                || (req_wdata_main[(lane*32) +: 32]
                                    !== expected_result[slot][index])) begin
                            $fatal(1,
                                "write raw-bit/address mismatch profile=%0d index=%0d got=%08x expected=%08x",
                                profile, index,
                                req_wdata_main[(lane*32) +: 32],
                                expected_result[slot][index]);
                        end
                    end
                end else begin
                    if ((req_src0_addr_main[(lane*64) +: 64] != 0)
                            || (req_src1_addr_main[(lane*64) +: 64] != 0)
                            || (req_dst_addr_main[(lane*64) +: 64] != 0)
                            || (req_wdata_main[(lane*32) +: 32] != 0)) begin
                        $fatal(1, "inactive main lane leaked request fields");
                    end
                end
            end
            if ((profile == 7) && !write_request
                    && (req_src1_addr_main[63:0]
                        == req_src1_addr_main[127:64])) begin
                broadcast_observed = 1;
            end
        end
    endtask

    task automatic accept_main_request(
        input integer profile,
        input integer base_index,
        input integer write_request
    );
        integer guard;
        integer hold_index;
        reg [7:0] held_mask;
        reg [511:0] held_src0;
        reg [511:0] held_src1;
        reg [511:0] held_dst;
        reg [255:0] held_wdata;
        reg [63:0] requests_before;
        reg [63:0] read_before;
        reg [63:0] write_before;
        begin
            req_ready_main = 1'b0;
            guard = 0;
            while (!req_valid_main) begin
                step_cycle();
                guard = guard + 1;
                if (guard > 4000)
                    $fatal(1, "main request timeout profile=%0d base=%0d",
                           profile, base_index);
            end
            check_main_request(profile, base_index, write_request);
            held_mask = req_mask_main;
            held_src0 = req_src0_addr_main;
            held_src1 = req_src1_addr_main;
            held_dst = req_dst_addr_main;
            held_wdata = req_wdata_main;
            requests_before = portal_requests_main;
            read_before = read_groups_main;
            write_before = write_groups_main;

            if ((profile == 0) && (base_index == 0)
                    && !write_request && !busy_start_tested) begin
                busy_start_tested = 1;
                vector_flags_i = 32'd19;
                vector_op_i = 32'd99;
                @(negedge clk_i);
                start_main = 1'b1;
                step_cycle();
                start_main = 1'b0;
                setup_descriptor(profile);
                if (f32_start_main || ready_main)
                    $fatal(1, "busy start mutated portal command");
            end

            for (hold_index = 0; hold_index < 2;
                 hold_index = hold_index + 1) begin
                request_hold_count = request_hold_count + 1;
                step_cycle();
                if (!req_valid_main || (req_mask_main !== held_mask)
                        || (req_src0_addr_main !== held_src0)
                        || (req_src1_addr_main !== held_src1)
                        || (req_dst_addr_main !== held_dst)
                        || (req_wdata_main !== held_wdata)
                        || (portal_requests_main !== requests_before)) begin
                    $fatal(1, "main request hold changed");
                end
            end
            @(negedge clk_i);
            req_ready_main = 1'b1;
            step_cycle();
            req_ready_main = 1'b0;
            if (!portal_outstanding_main
                    || (portal_requests_main != requests_before + 64'd1)
                    || (read_groups_main
                        != read_before + (write_request ? 64'd0 : 64'd1))
                    || (write_groups_main
                        != write_before + (write_request ? 64'd1 : 64'd0))) begin
                $fatal(1, "main request accounting mismatch");
            end
        end
    endtask

    task automatic fill_main_response(input integer profile,
                                        input integer base_index);
        integer lane;
        integer index;
        integer slot;
        begin
            slot = profile_slot(profile);
            rsp_src0_main = 256'b0;
            rsp_src1_main = 256'b0;
            for (lane = 0; lane < 8; lane = lane + 1) begin
                index = base_index + lane;
                if (index < profile_total(profile)) begin
                    rsp_src0_main[(lane*32) +: 32] = lhs_for(slot, index);
                    if ((profile == 16) || (profile == 18))
                        rsp_src1_main[(lane*32) +: 32]
                            = raw_rhs(index + 11);
                    else
                        rsp_src1_main[(lane*32) +: 32] = rhs_for(slot, index);
                end
            end
        end
    endtask

    task automatic send_main_success_response(
        input integer profile,
        input integer base_index,
        input integer write_response
    );
        reg [63:0] responses_before;
        reg [255:0] held_src0;
        reg [255:0] held_src1;
        reg [7:0] held_mask;
        begin
            responses_before = portal_responses_main;
            fill_main_response(profile, base_index);
            rsp_mask_main = mask8_for(base_index, profile_total(profile));
            rsp_error_main = 1'b0;
            held_src0 = rsp_src0_main;
            held_src1 = rsp_src1_main;
            held_mask = rsp_mask_main;
            @(negedge clk_i);
            rsp_valid_main = 1'b1;
            if (rsp_ready_main)
                $fatal(1, "main response was not initially backpressured");
            step_cycle();
            response_hold_count = response_hold_count + 1;
            if (!rsp_valid_main || !rsp_ready_main
                    || (rsp_src0_main !== held_src0)
                    || (rsp_src1_main !== held_src1)
                    || (rsp_mask_main !== held_mask)
                    || (portal_responses_main !== responses_before)) begin
                $fatal(1, "main response hold mismatch");
            end
            step_cycle();
            rsp_valid_main = 1'b0;
            if (portal_outstanding_main
                    || (portal_responses_main != responses_before + 64'd1)) begin
                $fatal(1, "main response accounting mismatch");
            end
            if (write_response && (output_words_main == 0)
                    && (base_index != 0)) begin
                $fatal(1, "write response did not advance output ledger");
            end
        end
    endtask

    task automatic wait_main_terminal;
        integer guard;
        begin
            guard = 0;
            while (!done_main && !error_main) begin
                step_cycle();
                guard = guard + 1;
                if (guard > 5000)
                    $fatal(1, "main terminal timeout");
            end
        end
    endtask

    task automatic run_main_success(input integer profile);
        integer base_index;
        integer total;
        integer groups;
        integer input_word_total;
        begin
            total = profile_total(profile);
            groups = (total + 7) / 8;
            launch_main(profile);
            for (base_index = 0; base_index < total;
                 base_index = base_index + 8) begin
                accept_main_request(profile, base_index, 0);
                send_main_success_response(profile, base_index, 0);
                accept_main_request(profile, base_index, 1);
                send_main_success_response(profile, base_index, 1);
            end
            wait_main_terminal();
            input_word_total = ((profile == 16) ? total : total * 2);
            if (!done_main || error_main || portal_outstanding_main
                    || (error_code_main != `NPU_ERR_NONE)
                    || (error_class_main != 0)
                    || (vector_elements_main != total)
                    || (expected_elements_main != total)
                    || (portal_requests_main != (groups * 2))
                    || (portal_responses_main != (groups * 2))
                    || (read_groups_main != groups)
                    || (write_groups_main != groups)
                    || (input_words_main != input_word_total)
                    || (output_words_main != total)
                    || (read_bytes_main != (input_word_total * 4))
                    || (write_bytes_main != (total * 4))) begin
                $fatal(1, "main exact success ledger mismatch profile=%0d",
                       profile);
            end
            step_cycle();
            if (!ready_main || done_main || error_main)
                $fatal(1, "main terminal cleanup mismatch");
        end
    endtask

    task automatic issue_start_tail;
        integer guard;
        begin
            guard = 0;
            while (!ready_tail) begin
                step_cycle();
                guard = guard + 1;
                if (guard > 2000)
                    $fatal(1, "tail idle timeout");
            end
            @(negedge clk_i);
            start_tail = 1'b1;
            step_cycle();
            start_tail = 1'b0;
            guard = 0;
            while (!f32_start_tail) begin
                step_cycle();
                guard = guard + 1;
                if (guard > 2000 || error_tail)
                    $fatal(1, "tail child start failed");
            end
        end
    endtask

    task automatic check_tail_request(input integer base_index,
                                       input integer write_request);
        integer lane;
        integer index;
        reg [5:0] expected_mask;
        begin
            expected_mask = mask6_for(base_index, 16);
            if ((req_write_tail !== write_request[0])
                    || (req_mask_tail !== expected_mask)) begin
                $fatal(1, "tail request mask/type mismatch base=%0d",
                       base_index);
            end
            for (lane = 0; lane < 6; lane = lane + 1) begin
                index = base_index + lane;
                if (expected_mask[lane]) begin
                    if (!write_request) begin
                        if ((req_src0_addr_tail[(lane*64) +: 64]
                                !== expected_src0_addr(0, index))
                                || (req_src1_addr_tail[(lane*64) +: 64]
                                    !== expected_src1_addr(0, index))
                                || (req_dst_addr_tail[(lane*64) +: 64] != 0)
                                || (req_wdata_tail[(lane*32) +: 32] != 0)) begin
                            $fatal(1, "tail read payload mismatch");
                        end
                    end else begin
                        if ((req_src0_addr_tail[(lane*64) +: 64] != 0)
                                || (req_src1_addr_tail[(lane*64) +: 64] != 0)
                                || (req_dst_addr_tail[(lane*64) +: 64]
                                    !== expected_dst_addr(index))
                                || (req_wdata_tail[(lane*32) +: 32]
                                    !== expected_result[0][index])) begin
                            $fatal(1, "tail write payload mismatch");
                        end
                    end
                end else if ((req_src0_addr_tail[(lane*64) +: 64] != 0)
                        || (req_src1_addr_tail[(lane*64) +: 64] != 0)
                        || (req_dst_addr_tail[(lane*64) +: 64] != 0)
                        || (req_wdata_tail[(lane*32) +: 32] != 0)) begin
                    $fatal(1, "tail inactive lane leaked fields");
                end
            end
            if (expected_mask != 6'h3f)
                tail_observed = 1;
        end
    endtask

    task automatic accept_tail_request(input integer base_index,
                                        input integer write_request);
        integer guard;
        reg [383:0] held_src0;
        reg [383:0] held_src1;
        reg [383:0] held_dst;
        reg [191:0] held_wdata;
        reg [5:0] held_mask;
        begin
            req_ready_tail = 1'b0;
            guard = 0;
            while (!req_valid_tail) begin
                step_cycle();
                guard = guard + 1;
                if (guard > 3000)
                    $fatal(1, "tail request timeout");
            end
            check_tail_request(base_index, write_request);
            held_src0 = req_src0_addr_tail;
            held_src1 = req_src1_addr_tail;
            held_dst = req_dst_addr_tail;
            held_wdata = req_wdata_tail;
            held_mask = req_mask_tail;
            step_cycle();
            request_hold_count = request_hold_count + 1;
            if (!req_valid_tail || (req_src0_addr_tail !== held_src0)
                    || (req_src1_addr_tail !== held_src1)
                    || (req_dst_addr_tail !== held_dst)
                    || (req_wdata_tail !== held_wdata)
                    || (req_mask_tail !== held_mask)) begin
                $fatal(1, "tail request hold mismatch");
            end
            @(negedge clk_i);
            req_ready_tail = 1'b1;
            step_cycle();
            req_ready_tail = 1'b0;
        end
    endtask

    task automatic send_tail_response(input integer base_index);
        integer lane;
        integer index;
        reg [63:0] responses_before;
        begin
            rsp_src0_tail = 192'b0;
            rsp_src1_tail = 192'b0;
            rsp_mask_tail = mask6_for(base_index, 16);
            for (lane = 0; lane < 6; lane = lane + 1) begin
                index = base_index + lane;
                if (index < 16) begin
                    rsp_src0_tail[(lane*32) +: 32] = lhs_for(0, index);
                    rsp_src1_tail[(lane*32) +: 32] = rhs_for(0, index);
                end else begin
                    rsp_src0_tail[(lane*32) +: 32] = 32'hdeadbeef;
                    rsp_src1_tail[(lane*32) +: 32] = 32'hcafef00d;
                end
            end
            rsp_error_tail = 1'b0;
            responses_before = portal_responses_tail;
            @(negedge clk_i);
            rsp_valid_tail = 1'b1;
            if (rsp_ready_tail)
                $fatal(1, "tail response lacked arm backpressure");
            step_cycle();
            response_hold_count = response_hold_count + 1;
            if (!rsp_ready_tail
                    || (portal_responses_tail != responses_before)) begin
                $fatal(1, "tail response hold mismatch");
            end
            step_cycle();
            rsp_valid_tail = 1'b0;
        end
    endtask

    task automatic run_tail_p00;
        integer base_index;
        integer guard;
        begin
            setup_descriptor(0);
            issue_start_tail();
            for (base_index = 0; base_index < 16;
                 base_index = base_index + 6) begin
                accept_tail_request(base_index, 0);
                send_tail_response(base_index);
                accept_tail_request(base_index, 1);
                send_tail_response(base_index);
            end
            guard = 0;
            while (!done_tail && !error_tail) begin
                step_cycle();
                guard = guard + 1;
                if (guard > 3000)
                    $fatal(1, "tail terminal timeout");
            end
            if (!done_tail || error_tail || (vector_elements_tail != 16)
                    || (expected_elements_tail != 16)
                    || (portal_requests_tail != 6)
                    || (portal_responses_tail != 6)
                    || (read_groups_tail != 3) || (write_groups_tail != 3)
                    || (input_words_tail != 32) || (output_words_tail != 16)
                    || (read_bytes_tail != 128) || (write_bytes_tail != 64)) begin
                $fatal(1, "LANES=6 P00 tail ledger mismatch");
            end
            step_cycle();
        end
    endtask

    task automatic wait_main_error(input [7:0] expected_code,
                                   input [31:0] expected_class);
        begin
            wait_main_terminal();
            if (!error_main || done_main || portal_outstanding_main
                    || (error_code_main !== expected_code)
                    || (error_class_main !== expected_class)) begin
                $fatal(1, "main error mismatch got=%0d/%0d expected=%0d/%0d",
                       error_code_main, error_class_main,
                       expected_code, expected_class);
            end
        end
    endtask

    task automatic run_descriptor_errors;
        begin
            setup_descriptor(0);
            capability_epoch_i = 32'd2;
            issue_start_main();
            wait_main_error(`NPU_ERR_MACRO_CAPABILITY,
                            ABI_ERROR_CAPABILITY);
            if ((portal_requests_main != 0) || (portal_responses_main != 0))
                $fatal(1, "capability error published portal traffic");
            step_cycle();

            setup_descriptor(0);
            vector_flags_i = 32'd19;
            issue_start_main();
            wait_main_error(`NPU_ERR_MACRO_LAYOUT, ABI_ERROR_LAYOUT);
            if ((portal_requests_main != 0) || (portal_responses_main != 0))
                $fatal(1, "layout error published portal traffic");
            step_cycle();
        end
    endtask

    task automatic send_main_fault_response(
        input integer profile,
        input integer base_index,
        input [7:0] response_mask,
        input integer response_error
    );
        begin
            fill_main_response(profile, base_index);
            rsp_mask_main = response_mask;
            rsp_error_main = response_error[0];
            @(negedge clk_i);
            rsp_valid_main = 1'b1;
            step_cycle();
            rsp_valid_main = 1'b0;
            rsp_error_main = 1'b0;
        end
    endtask

    task automatic run_read_mask_error;
        begin
            launch_main(0);
            accept_main_request(0, 0, 0);
            send_main_fault_response(0, 0, 8'hfe, 0);
            wait_main_error(`NPU_ERR_MACRO_PROTOCOL, ABI_ERROR_PROTOCOL);
            if ((portal_requests_main != 1) || (portal_responses_main != 1)
                    || (read_groups_main != 1) || (write_groups_main != 0)
                    || (input_words_main != 0) || (output_words_main != 0)
                    || (read_bytes_main != 0) || (write_bytes_main != 0)
                    || (vector_elements_main != 0)) begin
                $fatal(1, "read-mask atomic failure ledger mismatch");
            end
            step_cycle();
        end
    endtask

    task automatic run_p18_response_error;
        begin
            launch_main(18);
            accept_main_request(18, 0, 0);
            if ((expected_elements_main != 64'd262144)
                    || (req_src0_addr_main[63:0] != SRC0_BASE)
                    || (|req_src1_addr_main)) begin
                $fatal(1, "P18 exact descriptor/address admission mismatch");
            end
            send_main_fault_response(18, 0, 8'hff, 1);
            wait_main_error(`NPU_ERR_GMEM_RESPONSE, ABI_ERROR_GMEM);
            if ((portal_requests_main != 1) || (portal_responses_main != 1)
                    || (read_groups_main != 1) || (write_groups_main != 0)
                    || (input_words_main != 0) || (output_words_main != 0)
                    || (read_bytes_main != 0) || (write_bytes_main != 0)) begin
                $fatal(1, "P18 response error ledger mismatch");
            end
            step_cycle();
        end
    endtask

    task automatic run_write_mask_error;
        begin
            launch_main(0);
            accept_main_request(0, 0, 0);
            send_main_success_response(0, 0, 0);
            accept_main_request(0, 0, 1);
            send_main_fault_response(0, 0, 8'hfe, 0);
            wait_main_error(`NPU_ERR_MACRO_PROTOCOL, ABI_ERROR_PROTOCOL);
            if ((portal_requests_main != 2) || (portal_responses_main != 2)
                    || (read_groups_main != 1) || (write_groups_main != 1)
                    || (input_words_main != 16) || (read_bytes_main != 64)
                    || (output_words_main != 0) || (write_bytes_main != 0)
                    || (vector_elements_main != 0)) begin
                $fatal(1, "write-mask commit suppression ledger mismatch");
            end
            step_cycle();
        end
    endtask

    task automatic run_timeout_drain;
        integer wait_index;
        begin
            launch_main(0);
            accept_main_request(0, 0, 0);
            for (wait_index = 0; wait_index < 80;
                 wait_index = wait_index + 1) begin
                step_cycle();
                if (error_main || done_main || !portal_outstanding_main)
                    $fatal(1, "timeout published before accepted response drain");
            end
            fill_main_response(0, 0);
            rsp_mask_main = 8'hff;
            rsp_error_main = 1'b0;
            @(negedge clk_i);
            rsp_valid_main = 1'b1;
            step_cycle();
            rsp_valid_main = 1'b0;
            wait_main_error(`NPU_ERR_MACRO_TIMEOUT, ABI_ERROR_TIMEOUT);
            if ((portal_requests_main != 1) || (portal_responses_main != 1)
                    || (input_words_main != 0) || (output_words_main != 0)
                    || (read_bytes_main != 0) || (write_bytes_main != 0)) begin
                $fatal(1, "timeout drain ledger mismatch");
            end
            step_cycle();
        end
    endtask

    initial begin
        cycle_count = 0;
        request_hold_count = 0;
        response_hold_count = 0;
        tail_observed = 0;
        broadcast_observed = 0;
        busy_start_tested = 0;
        rst_i = 1'b1;
        start_main = 1'b0;
        req_ready_main = 1'b0;
        rsp_valid_main = 1'b0;
        rsp_mask_main = 8'b0;
        rsp_src0_main = 256'b0;
        rsp_src1_main = 256'b0;
        rsp_error_main = 1'b0;
        start_tail = 1'b0;
        req_ready_tail = 1'b0;
        rsp_valid_tail = 1'b0;
        rsp_mask_tail = 6'b0;
        rsp_src0_tail = 192'b0;
        rsp_src1_tail = 192'b0;
        rsp_error_tail = 1'b0;
        oracle_req_valid = 1'b0;
        oracle_op_mul = 1'b0;
        oracle_lhs = 32'b0;
        oracle_rhs = 32'b0;
        oracle_rsp_ready = 1'b0;
        setup_descriptor(0);

        repeat (4) step_cycle();
        if (ready_main || ready_tail || oracle_req_ready)
            $fatal(1, "reset leaked ready");
        @(negedge clk_i);
        rst_i = 1'b0;
        step_cycle();
        if (!ready_main || !ready_tail || !oracle_req_ready)
            $fatal(1, "ready missing after reset");

        build_oracle_table();
        run_main_success(0);
        run_main_success(7);
        run_main_success(15);
        run_main_success(16);
        run_tail_p00();
        run_descriptor_errors();
        run_read_mask_error();
        run_write_mask_error();
        run_p18_response_error();
        run_timeout_drain();

        if (!tail_observed || !broadcast_observed || !busy_start_tested
                || (request_hold_count == 0)
                || (response_hold_count == 0)) begin
            $fatal(1,
                "coverage marker missing tail=%0d broadcast=%0d busy_start=%0d req_hold=%0d rsp_hold=%0d",
                tail_observed, broadcast_observed, busy_start_tested,
                request_hold_count, response_hold_count);
        end
        repeat (8) begin
            step_cycle();
            if (!ready_main || !ready_tail || busy_main || busy_tail
                    || done_main || error_main || done_tail || error_tail
                    || req_valid_main || req_valid_tail
                    || portal_outstanding_main || portal_outstanding_tail) begin
                $fatal(1, "final idle stability mismatch");
            end
        end

        $display("[NPU-F32-ALU-PORTAL][PASS] lanes=8+tail6 profiles=P00,P07,P15,P16,P18 ops=ADD,MUL,SUB,SCALE raw_bits=public-AddMul-exact specials=zeros,subnormals,finite,inf,qnan,snan broadcast=P07 tail=P00-mask0f p18=exact-admission one_outstanding=1 holds=req,rsp,result ledgers=groups,words,bytes exact gmem=zero errors=capability,layout,read-mask,write-mask,response,timeout-drain commit_suppressed=1");
        $finish;
    end

endmodule

`default_nettype wire
