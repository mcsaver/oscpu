`timescale 1ns/1ps
`default_nettype none

// SPDX-License-Identifier: MIT
//
// Clocked simulation-only bridge from one resident NPU command to one
// functional DPI transaction.  This module is intentionally not part of the
// synthesizable/public datapath.  It gives a simulation functional engine a
// strict transaction lifetime:
//
//   IDLE       accept and register every command field exactly once
//   EXECUTE    call npu_functional_command_execute exactly once
//   TERMINAL   publish one stable terminal beat, then return to IDLE
//
// The DPI function receives only the registered descriptor.  Live command
// inputs cannot affect execution after acceptance.  A destination commit is
// published only for a contract-valid success.  Malformed success/error
// framing, an unclosed byte/word ledger, or any callback error is converted to
// a deterministic fail-closed contract terminal.  read_words counts only
// non-Q8 raw32-equivalent units (one I64 counts as two units; two F16 values
// count as one); Q8 transport closes separately at 34 bytes per q8_blocks
// entry.
module TensorNpuFunctionalCommandDpi (
    input  logic clk_i,
    input  logic rst_i,
    input  logic enable_i,

    input  logic command_valid_i,
    output logic command_ready_o,
    output logic busy_o,

    input  logic        command_abi_valid_i,
    input  logic        windows_generation_valid_i,
    input  logic [31:0] kernel_id_i,
    input  logic [31:0] command_flags_i,
    input  logic [31:0] vector_op_i,
    input  logic [31:0] vector_flags_i,
    input  logic [31:0] context_id_i,
    input  logic [31:0] capability_epoch_i,
    input  logic [31:0] node_count_i,
    input  logic [63:0] sequence_id_i,
    input  logic [63:0] producer_id_i,
    input  logic [63:0] user_tag_i,
    input  logic [63:0] node_hash_lo_i,
    input  logic [63:0] node_hash_hi_i,
    input  logic [63:0] deadline_cycles_i,
    input  logic [63:0] src0_iova_i,
    input  logic [63:0] src1_iova_i,
    input  logic [63:0] src2_iova_i,
    input  logic [63:0] dst_iova_i,
    input  logic [63:0] scratch_iova_i,
    input  logic [63:0] element_count_i,
    input  logic [31:0] outer_count_i,
    input  logic [31:0] dtype_i,
    input  logic [63:0] src0_stride_i,
    input  logic [63:0] src1_stride_i,
    input  logic [63:0] src2_stride_i,
    input  logic [63:0] dst_stride_i,
    input  logic [31:0] scalar0_i,
    input  logic [31:0] scalar1_i,
    input  logic [31:0] scratch_bytes_i,
    input  logic [31:0] rope_position_i,
    input  logic [63:0] src0_window_base_i,
    input  logic [63:0] src0_window_size_i,
    input  logic [31:0] src0_window_perm_i,
    input  logic [63:0] src1_window_base_i,
    input  logic [63:0] src1_window_size_i,
    input  logic [31:0] src1_window_perm_i,
    input  logic [63:0] dst_window_base_i,
    input  logic [63:0] dst_window_size_i,
    input  logic [31:0] dst_window_perm_i,

    output logic        terminal_valid_o,
    output logic        terminal_success_o,
    output logic        terminal_error_o,
    output logic [31:0] terminal_error_code_o,
    output logic [31:0] terminal_error_class_o,
    output logic        dst_commit_o,

    output logic [31:0] completion_kernel_id_o,
    output logic [31:0] completion_command_flags_o,
    output logic [31:0] completion_vector_op_o,
    output logic [31:0] completion_vector_flags_o,
    output logic [31:0] completion_context_id_o,
    output logic [31:0] completion_capability_epoch_o,
    output logic [31:0] completion_node_count_o,
    output logic [63:0] completion_sequence_id_o,
    output logic [63:0] completion_producer_id_o,
    output logic [63:0] completion_user_tag_o,
    output logic [63:0] completion_node_hash_lo_o,
    output logic [63:0] completion_node_hash_hi_o,

    output logic [63:0] terminal_read_words_o,
    output logic [63:0] terminal_write_words_o,
    output logic [63:0] terminal_read_bytes_o,
    output logic [63:0] terminal_write_bytes_o,
    output logic [63:0] terminal_q8_blocks_o,
    output logic [63:0] terminal_q8_mac_count_o,
    output logic [63:0] terminal_vector_elements_o,
    output logic [31:0] terminal_callback_errors_o,

    output logic [63:0] dispatch_count_o,
    output logic [63:0] completion_count_o
);

    localparam logic [1:0] STATE_IDLE     = 2'd0;
    localparam logic [1:0] STATE_EXECUTE  = 2'd1;
    localparam logic [1:0] STATE_TERMINAL = 2'd2;

    localparam logic [31:0] ERROR_CLASS_DPI_CONTRACT = 32'hffff_ff00;
    localparam logic [31:0] ERROR_CODE_STATUS_FRAME   = 32'h0000_f001;
    localparam logic [31:0] ERROR_CODE_LEDGER_CLOSURE = 32'h0000_f002;
    localparam logic [31:0] ERROR_CODE_CALLBACK       = 32'h0000_f003;

    import "DPI-C" function void npu_functional_command_execute(
        input bit              abi_valid,
        input bit              windows_generation_valid,
        input int unsigned     kernel_id,
        input int unsigned     command_flags,
        input int unsigned     vector_op,
        input int unsigned     vector_flags,
        input int unsigned     context_id,
        input int unsigned     capability_epoch,
        input int unsigned     node_count,
        input longint unsigned sequence_id,
        input longint unsigned producer_id,
        input longint unsigned user_tag,
        input longint unsigned node_hash_lo,
        input longint unsigned node_hash_hi,
        input longint unsigned deadline_cycles,
        input longint unsigned src0_iova,
        input longint unsigned src1_iova,
        input longint unsigned src2_iova,
        input longint unsigned dst_iova,
        input longint unsigned scratch_iova,
        input longint unsigned element_count,
        input int unsigned     outer_count,
        input int unsigned     dtype,
        input longint unsigned src0_stride,
        input longint unsigned src1_stride,
        input longint unsigned src2_stride,
        input longint unsigned dst_stride,
        input int unsigned     scalar0,
        input int unsigned     scalar1,
        input int unsigned     scratch_bytes,
        input int unsigned     rope_position,
        input longint unsigned src0_window_base,
        input longint unsigned src0_window_size,
        input int unsigned     src0_window_perm,
        input longint unsigned src1_window_base,
        input longint unsigned src1_window_size,
        input int unsigned     src1_window_perm,
        input longint unsigned dst_window_base,
        input longint unsigned dst_window_size,
        input int unsigned     dst_window_perm,
        output bit              success,
        output int unsigned     error_code,
        output int unsigned     error_class,
        output longint unsigned read_words,
        output longint unsigned write_words,
        output longint unsigned read_bytes,
        output longint unsigned write_bytes,
        output longint unsigned q8_blocks,
        output longint unsigned q8_mac_count,
        output longint unsigned vector_elements,
        output int unsigned     callback_errors
    );

    logic [1:0] state_q;

    bit          abi_valid_q;
    bit          windows_generation_valid_q;
    logic [31:0] kernel_id_q;
    logic [31:0] command_flags_q;
    logic [31:0] vector_op_q;
    logic [31:0] vector_flags_q;
    logic [31:0] context_id_q;
    logic [31:0] capability_epoch_q;
    logic [31:0] node_count_q;
    logic [63:0] sequence_id_q;
    logic [63:0] producer_id_q;
    logic [63:0] user_tag_q;
    logic [63:0] node_hash_lo_q;
    logic [63:0] node_hash_hi_q;
    logic [63:0] deadline_cycles_q;
    logic [63:0] src0_iova_q;
    logic [63:0] src1_iova_q;
    logic [63:0] src2_iova_q;
    logic [63:0] dst_iova_q;
    logic [63:0] scratch_iova_q;
    logic [63:0] element_count_q;
    logic [31:0] outer_count_q;
    logic [31:0] dtype_q;
    logic [63:0] src0_stride_q;
    logic [63:0] src1_stride_q;
    logic [63:0] src2_stride_q;
    logic [63:0] dst_stride_q;
    logic [31:0] scalar0_q;
    logic [31:0] scalar1_q;
    logic [31:0] scratch_bytes_q;
    logic [31:0] rope_position_q;
    logic [63:0] src0_window_base_q;
    logic [63:0] src0_window_size_q;
    logic [31:0] src0_window_perm_q;
    logic [63:0] src1_window_base_q;
    logic [63:0] src1_window_size_q;
    logic [31:0] src1_window_perm_q;
    logic [63:0] dst_window_base_q;
    logic [63:0] dst_window_size_q;
    logic [31:0] dst_window_perm_q;

    logic        terminal_success_q;
    logic [31:0] terminal_error_code_q;
    logic [31:0] terminal_error_class_q;
    logic [31:0] completion_kernel_id_q;
    logic [31:0] completion_command_flags_q;
    logic [31:0] completion_vector_op_q;
    logic [31:0] completion_vector_flags_q;
    logic [31:0] completion_context_id_q;
    logic [31:0] completion_capability_epoch_q;
    logic [31:0] completion_node_count_q;
    logic [63:0] completion_sequence_id_q;
    logic [63:0] completion_producer_id_q;
    logic [63:0] completion_user_tag_q;
    logic [63:0] completion_node_hash_lo_q;
    logic [63:0] completion_node_hash_hi_q;
    logic [63:0] terminal_read_words_q;
    logic [63:0] terminal_write_words_q;
    logic [63:0] terminal_read_bytes_q;
    logic [63:0] terminal_write_bytes_q;
    logic [63:0] terminal_q8_blocks_q;
    logic [63:0] terminal_q8_mac_count_q;
    logic [63:0] terminal_vector_elements_q;
    logic [31:0] terminal_callback_errors_q;
    logic [63:0] dispatch_count_q;
    logic [63:0] completion_count_q;

    // DPI outputs and widened ledger arithmetic are edge-local temporaries.
    // Blocking assignment is required because the DPI call is one atomic
    // simulation transaction whose result is validated on the same edge.
    bit              dpi_success_tmp;
    int unsigned     dpi_error_code_tmp;
    int unsigned     dpi_error_class_tmp;
    longint unsigned dpi_read_words_tmp;
    longint unsigned dpi_write_words_tmp;
    longint unsigned dpi_read_bytes_tmp;
    longint unsigned dpi_write_bytes_tmp;
    longint unsigned dpi_q8_blocks_tmp;
    longint unsigned dpi_q8_mac_count_tmp;
    longint unsigned dpi_vector_elements_tmp;
    int unsigned     dpi_callback_errors_tmp;
    logic             dpi_status_valid_tmp;
    logic             dpi_ledger_closed_tmp;
    logic [65:0]      dpi_read_word_bytes_tmp;
    logic [65:0]      dpi_write_word_bytes_tmp;
    logic [69:0]      dpi_q8_bytes_tmp;
    logic [70:0]      dpi_expected_read_bytes_tmp;

    logic outputs_enabled_w;
    logic terminal_state_w;

    assign outputs_enabled_w = enable_i && !rst_i;
    assign terminal_state_w = outputs_enabled_w
                            && (state_q == STATE_TERMINAL);

    assign command_ready_o = outputs_enabled_w && (state_q == STATE_IDLE);
    assign busy_o = outputs_enabled_w && (state_q != STATE_IDLE);
    assign terminal_valid_o = terminal_state_w;
    assign terminal_success_o = terminal_state_w && terminal_success_q;
    assign terminal_error_o = terminal_state_w && !terminal_success_q;
    assign terminal_error_code_o = terminal_state_w
                                 ? terminal_error_code_q : 32'd0;
    assign terminal_error_class_o = terminal_state_w
                                  ? terminal_error_class_q : 32'd0;
    assign dst_commit_o = terminal_state_w && terminal_success_q;

    assign completion_kernel_id_o = terminal_state_w
                                  ? completion_kernel_id_q : 32'd0;
    assign completion_command_flags_o = terminal_state_w
                                      ? completion_command_flags_q : 32'd0;
    assign completion_vector_op_o = terminal_state_w
                                  ? completion_vector_op_q : 32'd0;
    assign completion_vector_flags_o = terminal_state_w
                                     ? completion_vector_flags_q : 32'd0;
    assign completion_context_id_o = terminal_state_w
                                   ? completion_context_id_q : 32'd0;
    assign completion_capability_epoch_o = terminal_state_w
                                         ? completion_capability_epoch_q
                                         : 32'd0;
    assign completion_node_count_o = terminal_state_w
                                   ? completion_node_count_q : 32'd0;
    assign completion_sequence_id_o = terminal_state_w
                                    ? completion_sequence_id_q : 64'd0;
    assign completion_producer_id_o = terminal_state_w
                                    ? completion_producer_id_q : 64'd0;
    assign completion_user_tag_o = terminal_state_w
                                 ? completion_user_tag_q : 64'd0;
    assign completion_node_hash_lo_o = terminal_state_w
                                     ? completion_node_hash_lo_q : 64'd0;
    assign completion_node_hash_hi_o = terminal_state_w
                                     ? completion_node_hash_hi_q : 64'd0;

    assign terminal_read_words_o = terminal_state_w
                                 ? terminal_read_words_q : 64'd0;
    assign terminal_write_words_o = terminal_state_w
                                  ? terminal_write_words_q : 64'd0;
    assign terminal_read_bytes_o = terminal_state_w
                                 ? terminal_read_bytes_q : 64'd0;
    assign terminal_write_bytes_o = terminal_state_w
                                  ? terminal_write_bytes_q : 64'd0;
    assign terminal_q8_blocks_o = terminal_state_w
                                ? terminal_q8_blocks_q : 64'd0;
    assign terminal_q8_mac_count_o = terminal_state_w
                                   ? terminal_q8_mac_count_q : 64'd0;
    assign terminal_vector_elements_o = terminal_state_w
                                      ? terminal_vector_elements_q : 64'd0;
    assign terminal_callback_errors_o = terminal_state_w
                                      ? terminal_callback_errors_q : 32'd0;

    assign dispatch_count_o = outputs_enabled_w ? dispatch_count_q : 64'd0;
    assign completion_count_o = outputs_enabled_w
                              ? completion_count_q : 64'd0;

    /* verilator lint_off BLKSEQ */
    always_ff @(posedge clk_i) begin
        if (rst_i || !enable_i) begin
            state_q <= STATE_IDLE;
            abi_valid_q <= 1'b0;
            windows_generation_valid_q <= 1'b0;
            kernel_id_q <= 32'd0;
            command_flags_q <= 32'd0;
            vector_op_q <= 32'd0;
            vector_flags_q <= 32'd0;
            context_id_q <= 32'd0;
            capability_epoch_q <= 32'd0;
            node_count_q <= 32'd0;
            sequence_id_q <= 64'd0;
            producer_id_q <= 64'd0;
            user_tag_q <= 64'd0;
            node_hash_lo_q <= 64'd0;
            node_hash_hi_q <= 64'd0;
            deadline_cycles_q <= 64'd0;
            src0_iova_q <= 64'd0;
            src1_iova_q <= 64'd0;
            src2_iova_q <= 64'd0;
            dst_iova_q <= 64'd0;
            scratch_iova_q <= 64'd0;
            element_count_q <= 64'd0;
            outer_count_q <= 32'd0;
            dtype_q <= 32'd0;
            src0_stride_q <= 64'd0;
            src1_stride_q <= 64'd0;
            src2_stride_q <= 64'd0;
            dst_stride_q <= 64'd0;
            scalar0_q <= 32'd0;
            scalar1_q <= 32'd0;
            scratch_bytes_q <= 32'd0;
            rope_position_q <= 32'd0;
            src0_window_base_q <= 64'd0;
            src0_window_size_q <= 64'd0;
            src0_window_perm_q <= 32'd0;
            src1_window_base_q <= 64'd0;
            src1_window_size_q <= 64'd0;
            src1_window_perm_q <= 32'd0;
            dst_window_base_q <= 64'd0;
            dst_window_size_q <= 64'd0;
            dst_window_perm_q <= 32'd0;
            terminal_success_q <= 1'b0;
            terminal_error_code_q <= 32'd0;
            terminal_error_class_q <= 32'd0;
            completion_kernel_id_q <= 32'd0;
            completion_command_flags_q <= 32'd0;
            completion_vector_op_q <= 32'd0;
            completion_vector_flags_q <= 32'd0;
            completion_context_id_q <= 32'd0;
            completion_capability_epoch_q <= 32'd0;
            completion_node_count_q <= 32'd0;
            completion_sequence_id_q <= 64'd0;
            completion_producer_id_q <= 64'd0;
            completion_user_tag_q <= 64'd0;
            completion_node_hash_lo_q <= 64'd0;
            completion_node_hash_hi_q <= 64'd0;
            terminal_read_words_q <= 64'd0;
            terminal_write_words_q <= 64'd0;
            terminal_read_bytes_q <= 64'd0;
            terminal_write_bytes_q <= 64'd0;
            terminal_q8_blocks_q <= 64'd0;
            terminal_q8_mac_count_q <= 64'd0;
            terminal_vector_elements_q <= 64'd0;
            terminal_callback_errors_q <= 32'd0;
            dispatch_count_q <= 64'd0;
            completion_count_q <= 64'd0;
            dpi_success_tmp = 1'b0;
            dpi_error_code_tmp = 32'd0;
            dpi_error_class_tmp = 32'd0;
            dpi_read_words_tmp = 64'd0;
            dpi_write_words_tmp = 64'd0;
            dpi_read_bytes_tmp = 64'd0;
            dpi_write_bytes_tmp = 64'd0;
            dpi_q8_blocks_tmp = 64'd0;
            dpi_q8_mac_count_tmp = 64'd0;
            dpi_vector_elements_tmp = 64'd0;
            dpi_callback_errors_tmp = 32'd0;
            dpi_status_valid_tmp = 1'b0;
            dpi_ledger_closed_tmp = 1'b0;
            dpi_read_word_bytes_tmp = 66'd0;
            dpi_write_word_bytes_tmp = 66'd0;
            dpi_q8_bytes_tmp = 70'd0;
            dpi_expected_read_bytes_tmp = 71'd0;
        end else begin
            case (state_q)
                STATE_IDLE: begin
                    if (command_valid_i) begin
                        abi_valid_q <= command_abi_valid_i;
                        windows_generation_valid_q
                            <= windows_generation_valid_i;
                        kernel_id_q <= kernel_id_i;
                        command_flags_q <= command_flags_i;
                        vector_op_q <= vector_op_i;
                        vector_flags_q <= vector_flags_i;
                        context_id_q <= context_id_i;
                        capability_epoch_q <= capability_epoch_i;
                        node_count_q <= node_count_i;
                        sequence_id_q <= sequence_id_i;
                        producer_id_q <= producer_id_i;
                        user_tag_q <= user_tag_i;
                        node_hash_lo_q <= node_hash_lo_i;
                        node_hash_hi_q <= node_hash_hi_i;
                        deadline_cycles_q <= deadline_cycles_i;
                        src0_iova_q <= src0_iova_i;
                        src1_iova_q <= src1_iova_i;
                        src2_iova_q <= src2_iova_i;
                        dst_iova_q <= dst_iova_i;
                        scratch_iova_q <= scratch_iova_i;
                        element_count_q <= element_count_i;
                        outer_count_q <= outer_count_i;
                        dtype_q <= dtype_i;
                        src0_stride_q <= src0_stride_i;
                        src1_stride_q <= src1_stride_i;
                        src2_stride_q <= src2_stride_i;
                        dst_stride_q <= dst_stride_i;
                        scalar0_q <= scalar0_i;
                        scalar1_q <= scalar1_i;
                        scratch_bytes_q <= scratch_bytes_i;
                        rope_position_q <= rope_position_i;
                        src0_window_base_q <= src0_window_base_i;
                        src0_window_size_q <= src0_window_size_i;
                        src0_window_perm_q <= src0_window_perm_i;
                        src1_window_base_q <= src1_window_base_i;
                        src1_window_size_q <= src1_window_size_i;
                        src1_window_perm_q <= src1_window_perm_i;
                        dst_window_base_q <= dst_window_base_i;
                        dst_window_size_q <= dst_window_size_i;
                        dst_window_perm_q <= dst_window_perm_i;
                        terminal_success_q <= 1'b0;
                        terminal_error_code_q <= 32'd0;
                        terminal_error_class_q <= 32'd0;
                        terminal_read_words_q <= 64'd0;
                        terminal_write_words_q <= 64'd0;
                        terminal_read_bytes_q <= 64'd0;
                        terminal_write_bytes_q <= 64'd0;
                        terminal_q8_blocks_q <= 64'd0;
                        terminal_q8_mac_count_q <= 64'd0;
                        terminal_vector_elements_q <= 64'd0;
                        terminal_callback_errors_q <= 32'd0;
                        dispatch_count_q <= dispatch_count_q + 64'd1;
                        state_q <= STATE_EXECUTE;
                    end
                end

                STATE_EXECUTE: begin
                    dpi_success_tmp = 1'b0;
                    dpi_error_code_tmp = 32'd0;
                    dpi_error_class_tmp = 32'd0;
                    dpi_read_words_tmp = 64'd0;
                    dpi_write_words_tmp = 64'd0;
                    dpi_read_bytes_tmp = 64'd0;
                    dpi_write_bytes_tmp = 64'd0;
                    dpi_q8_blocks_tmp = 64'd0;
                    dpi_q8_mac_count_tmp = 64'd0;
                    dpi_vector_elements_tmp = 64'd0;
                    dpi_callback_errors_tmp = 32'd0;

                    npu_functional_command_execute(
                        abi_valid_q,
                        windows_generation_valid_q,
                        kernel_id_q,
                        command_flags_q,
                        vector_op_q,
                        vector_flags_q,
                        context_id_q,
                        capability_epoch_q,
                        node_count_q,
                        sequence_id_q,
                        producer_id_q,
                        user_tag_q,
                        node_hash_lo_q,
                        node_hash_hi_q,
                        deadline_cycles_q,
                        src0_iova_q,
                        src1_iova_q,
                        src2_iova_q,
                        dst_iova_q,
                        scratch_iova_q,
                        element_count_q,
                        outer_count_q,
                        dtype_q,
                        src0_stride_q,
                        src1_stride_q,
                        src2_stride_q,
                        dst_stride_q,
                        scalar0_q,
                        scalar1_q,
                        scratch_bytes_q,
                        rope_position_q,
                        src0_window_base_q,
                        src0_window_size_q,
                        src0_window_perm_q,
                        src1_window_base_q,
                        src1_window_size_q,
                        src1_window_perm_q,
                        dst_window_base_q,
                        dst_window_size_q,
                        dst_window_perm_q,
                        dpi_success_tmp,
                        dpi_error_code_tmp,
                        dpi_error_class_tmp,
                        dpi_read_words_tmp,
                        dpi_write_words_tmp,
                        dpi_read_bytes_tmp,
                        dpi_write_bytes_tmp,
                        dpi_q8_blocks_tmp,
                        dpi_q8_mac_count_tmp,
                        dpi_vector_elements_tmp,
                        dpi_callback_errors_tmp
                    );

                    dpi_status_valid_tmp =
                        (dpi_success_tmp
                         && (dpi_error_code_tmp == 32'd0)
                         && (dpi_error_class_tmp == 32'd0))
                        || (!dpi_success_tmp
                            && (dpi_error_code_tmp != 32'd0)
                            && (dpi_error_class_tmp != 32'd0));
                    dpi_read_word_bytes_tmp =
                        {2'b00, dpi_read_words_tmp} << 2;
                    dpi_write_word_bytes_tmp =
                        {2'b00, dpi_write_words_tmp} << 2;
                    dpi_q8_bytes_tmp =
                        {6'b000000, dpi_q8_blocks_tmp} * 7'd34;
                    dpi_expected_read_bytes_tmp =
                        {5'b00000, dpi_read_word_bytes_tmp}
                        + {1'b0, dpi_q8_bytes_tmp};
                    dpi_ledger_closed_tmp =
                        (dpi_expected_read_bytes_tmp[70:64] == 7'd0)
                        && (dpi_expected_read_bytes_tmp[63:0]
                            == dpi_read_bytes_tmp)
                        && (dpi_write_word_bytes_tmp[65:64] == 2'd0)
                        && (dpi_write_word_bytes_tmp[63:0]
                            == dpi_write_bytes_tmp);

                    completion_kernel_id_q <= kernel_id_q;
                    completion_command_flags_q <= command_flags_q;
                    completion_vector_op_q <= vector_op_q;
                    completion_vector_flags_q <= vector_flags_q;
                    completion_context_id_q <= context_id_q;
                    completion_capability_epoch_q <= capability_epoch_q;
                    completion_node_count_q <= node_count_q;
                    completion_sequence_id_q <= sequence_id_q;
                    completion_producer_id_q <= producer_id_q;
                    completion_user_tag_q <= user_tag_q;
                    completion_node_hash_lo_q <= node_hash_lo_q;
                    completion_node_hash_hi_q <= node_hash_hi_q;
                    terminal_read_words_q <= dpi_read_words_tmp;
                    terminal_write_words_q <= dpi_write_words_tmp;
                    terminal_read_bytes_q <= dpi_read_bytes_tmp;
                    terminal_write_bytes_q <= dpi_write_bytes_tmp;
                    terminal_q8_blocks_q <= dpi_q8_blocks_tmp;
                    terminal_q8_mac_count_q <= dpi_q8_mac_count_tmp;
                    terminal_vector_elements_q <= dpi_vector_elements_tmp;
                    terminal_callback_errors_q <= dpi_callback_errors_tmp;
                    completion_count_q <= completion_count_q + 64'd1;

                    if (dpi_callback_errors_tmp != 32'd0) begin
                        terminal_success_q <= 1'b0;
                        terminal_error_code_q <= ERROR_CODE_CALLBACK;
                        terminal_error_class_q <= ERROR_CLASS_DPI_CONTRACT;
                    end else if (!dpi_status_valid_tmp) begin
                        terminal_success_q <= 1'b0;
                        terminal_error_code_q <= ERROR_CODE_STATUS_FRAME;
                        terminal_error_class_q <= ERROR_CLASS_DPI_CONTRACT;
                    end else if (!dpi_ledger_closed_tmp) begin
                        terminal_success_q <= 1'b0;
                        terminal_error_code_q <= ERROR_CODE_LEDGER_CLOSURE;
                        terminal_error_class_q <= ERROR_CLASS_DPI_CONTRACT;
                    end else if (dpi_success_tmp) begin
                        terminal_success_q <= 1'b1;
                        terminal_error_code_q <= 32'd0;
                        terminal_error_class_q <= 32'd0;
                    end else begin
                        terminal_success_q <= 1'b0;
                        terminal_error_code_q <= dpi_error_code_tmp;
                        terminal_error_class_q <= dpi_error_class_tmp;
                    end
                    state_q <= STATE_TERMINAL;
                end

                STATE_TERMINAL: begin
                    state_q <= STATE_IDLE;
                end

                default: begin
                    state_q <= STATE_IDLE;
                end
            endcase
        end
    end
    /* verilator lint_on BLKSEQ */

endmodule

`default_nettype wire
