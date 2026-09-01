`timescale 1ns/1ps
`default_nettype none

module tb_functional_command_dpi;

    localparam logic [31:0] KERNEL_ID = 32'h514e_ff01;
    localparam logic [31:0] COMMAND_FLAGS = 32'h0000_0011;
    localparam logic [31:0] VECTOR_OP = 32'h0000_0023;
    localparam logic [31:0] CONTEXT_ID = 32'h434d_4401;
    localparam logic [31:0] CAPABILITY_EPOCH = 32'h0000_0007;
    localparam logic [31:0] NODE_COUNT = 32'd3;
    localparam logic [63:0] SEQUENCE_BASE = 64'h0102_0304_0506_0700;
    localparam logic [63:0] PRODUCER_ID = 64'h1112_1314_1516_1718;
    localparam logic [63:0] USER_TAG = 64'h2122_2324_2526_2728;
    localparam logic [63:0] NODE_HASH_LO = 64'h3132_3334_3536_3738;
    localparam logic [63:0] NODE_HASH_HI = 64'h4142_4344_4546_4748;
    localparam logic [63:0] DEADLINE_CYCLES = 64'h0000_0000_0001_0000;
    localparam logic [63:0] SRC0_IOVA = 64'h0000_0000_1000_0040;
    localparam logic [63:0] SRC1_IOVA = 64'h0000_0000_2000_0080;
    localparam logic [63:0] SRC2_IOVA = 64'h0000_0000_3000_00c0;
    localparam logic [63:0] DST_IOVA = 64'h0000_0000_4000_0100;
    localparam logic [63:0] SCRATCH_IOVA = 64'h0000_0000_5000_0000;
    localparam logic [63:0] ELEMENT_COUNT = 64'd32;
    localparam logic [31:0] OUTER_COUNT = 32'd2;
    localparam logic [31:0] DTYPE = 32'd1;
    localparam logic [63:0] SRC0_STRIDE = 64'd4;
    localparam logic [63:0] SRC1_STRIDE = 64'd64;
    localparam logic [63:0] SRC2_STRIDE = 64'd128;
    localparam logic [63:0] DST_STRIDE = 64'd256;
    localparam logic [31:0] SCALAR0 = 32'h3f00_0000;
    localparam logic [31:0] SCALAR1 = 32'hbf80_0000;
    localparam logic [31:0] SCRATCH_BYTES = 32'd4096;
    localparam logic [31:0] ROPE_POSITION = 32'd7;
    localparam logic [63:0] SRC0_WINDOW_BASE = 64'h0000_0000_1000_0000;
    localparam logic [63:0] SRC0_WINDOW_SIZE = 64'd4096;
    localparam logic [31:0] SRC0_WINDOW_PERM = 32'd1;
    localparam logic [63:0] SRC1_WINDOW_BASE = 64'h0000_0000_2000_0000;
    localparam logic [63:0] SRC1_WINDOW_SIZE = 64'd4096;
    localparam logic [31:0] SRC1_WINDOW_PERM = 32'd1;
    localparam logic [63:0] DST_WINDOW_BASE = 64'h0000_0000_4000_0000;
    localparam logic [63:0] DST_WINDOW_SIZE = 64'd8192;
    localparam logic [31:0] DST_WINDOW_PERM = 32'd2;

    localparam logic [31:0] ERROR_CLASS_DPI_CONTRACT = 32'hffff_ff00;
    localparam logic [31:0] ERROR_CODE_STATUS_FRAME = 32'h0000_f001;
    localparam logic [31:0] ERROR_CODE_LEDGER_CLOSURE = 32'h0000_f002;
    localparam logic [31:0] ERROR_CODE_CALLBACK = 32'h0000_f003;
    localparam logic [31:0] DPI_ERROR_CODE = 32'h0000_e101;
    localparam logic [31:0] DPI_ERROR_CLASS = 32'h0000_e201;

    localparam logic [63:0] READ_WORDS = 64'd96;
    localparam logic [63:0] WRITE_WORDS = 64'd32;
    localparam logic [63:0] Q8_BLOCKS = 64'd4;
    localparam logic [63:0] READ_BYTES = 64'd520;
    localparam logic [63:0] WRITE_BYTES = 64'd128;
    localparam logic [63:0] Q8_MAC_COUNT = 64'd128;
    localparam logic [63:0] VECTOR_ELEMENTS = 64'd32;

    logic clk_i;
    logic rst_i;
    logic enable_i;
    logic command_valid_i;
    logic command_ready_o;
    logic busy_o;
    logic command_abi_valid_i;
    logic windows_generation_valid_i;
    logic [31:0] kernel_id_i;
    logic [31:0] command_flags_i;
    logic [31:0] vector_op_i;
    logic [31:0] vector_flags_i;
    logic [31:0] context_id_i;
    logic [31:0] capability_epoch_i;
    logic [31:0] node_count_i;
    logic [63:0] sequence_id_i;
    logic [63:0] producer_id_i;
    logic [63:0] user_tag_i;
    logic [63:0] node_hash_lo_i;
    logic [63:0] node_hash_hi_i;
    logic [63:0] deadline_cycles_i;
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
    logic [31:0] src0_window_perm_i;
    logic [63:0] src1_window_base_i;
    logic [63:0] src1_window_size_i;
    logic [31:0] src1_window_perm_i;
    logic [63:0] dst_window_base_i;
    logic [63:0] dst_window_size_i;
    logic [31:0] dst_window_perm_i;

    logic terminal_valid_o;
    logic terminal_success_o;
    logic terminal_error_o;
    logic [31:0] terminal_error_code_o;
    logic [31:0] terminal_error_class_o;
    logic dst_commit_o;
    logic [31:0] completion_kernel_id_o;
    logic [31:0] completion_command_flags_o;
    logic [31:0] completion_vector_op_o;
    logic [31:0] completion_vector_flags_o;
    logic [31:0] completion_context_id_o;
    logic [31:0] completion_capability_epoch_o;
    logic [31:0] completion_node_count_o;
    logic [63:0] completion_sequence_id_o;
    logic [63:0] completion_producer_id_o;
    logic [63:0] completion_user_tag_o;
    logic [63:0] completion_node_hash_lo_o;
    logic [63:0] completion_node_hash_hi_o;
    logic [63:0] terminal_read_words_o;
    logic [63:0] terminal_write_words_o;
    logic [63:0] terminal_read_bytes_o;
    logic [63:0] terminal_write_bytes_o;
    logic [63:0] terminal_q8_blocks_o;
    logic [63:0] terminal_q8_mac_count_o;
    logic [63:0] terminal_vector_elements_o;
    logic [31:0] terminal_callback_errors_o;
    logic [63:0] dispatch_count_o;
    logic [63:0] completion_count_o;

    longint unsigned expected_transactions;
    integer global_cycles;

    typedef struct packed {
        logic        valid;
        logic        success;
        logic        error;
        logic        commit;
        logic [31:0] error_code;
        logic [31:0] error_class;
        logic [31:0] kernel_id;
        logic [31:0] command_flags;
        logic [31:0] vector_op;
        logic [31:0] vector_flags;
        logic [31:0] context_id;
        logic [31:0] capability_epoch;
        logic [31:0] node_count;
        logic [63:0] sequence_id;
        logic [63:0] producer_id;
        logic [63:0] user_tag;
        logic [63:0] node_hash_lo;
        logic [63:0] node_hash_hi;
        logic [63:0] read_words;
        logic [63:0] write_words;
        logic [63:0] read_bytes;
        logic [63:0] write_bytes;
        logic [63:0] q8_blocks;
        logic [63:0] q8_mac_count;
        logic [63:0] vector_elements;
        logic [31:0] callback_errors;
        logic [63:0] dispatch_count;
        logic [63:0] completion_count;
    } terminal_snapshot_t;

    terminal_snapshot_t terminal_snapshot_before;

    import "DPI-C" function void npu_functional_command_stub_reset();
    import "DPI-C" function longint unsigned
        npu_functional_command_stub_call_count();

    TensorNpuFunctionalCommandDpi u_dut (
        .clk_i                         (clk_i),
        .rst_i                         (rst_i),
        .enable_i                      (enable_i),
        .command_valid_i               (command_valid_i),
        .command_ready_o               (command_ready_o),
        .busy_o                        (busy_o),
        .command_abi_valid_i           (command_abi_valid_i),
        .windows_generation_valid_i    (windows_generation_valid_i),
        .kernel_id_i                   (kernel_id_i),
        .command_flags_i               (command_flags_i),
        .vector_op_i                   (vector_op_i),
        .vector_flags_i                (vector_flags_i),
        .context_id_i                  (context_id_i),
        .capability_epoch_i            (capability_epoch_i),
        .node_count_i                  (node_count_i),
        .sequence_id_i                 (sequence_id_i),
        .producer_id_i                 (producer_id_i),
        .user_tag_i                    (user_tag_i),
        .node_hash_lo_i                (node_hash_lo_i),
        .node_hash_hi_i                (node_hash_hi_i),
        .deadline_cycles_i             (deadline_cycles_i),
        .src0_iova_i                   (src0_iova_i),
        .src1_iova_i                   (src1_iova_i),
        .src2_iova_i                   (src2_iova_i),
        .dst_iova_i                    (dst_iova_i),
        .scratch_iova_i                (scratch_iova_i),
        .element_count_i               (element_count_i),
        .outer_count_i                 (outer_count_i),
        .dtype_i                       (dtype_i),
        .src0_stride_i                 (src0_stride_i),
        .src1_stride_i                 (src1_stride_i),
        .src2_stride_i                 (src2_stride_i),
        .dst_stride_i                  (dst_stride_i),
        .scalar0_i                     (scalar0_i),
        .scalar1_i                     (scalar1_i),
        .scratch_bytes_i               (scratch_bytes_i),
        .rope_position_i               (rope_position_i),
        .src0_window_base_i            (src0_window_base_i),
        .src0_window_size_i            (src0_window_size_i),
        .src0_window_perm_i            (src0_window_perm_i),
        .src1_window_base_i            (src1_window_base_i),
        .src1_window_size_i            (src1_window_size_i),
        .src1_window_perm_i            (src1_window_perm_i),
        .dst_window_base_i             (dst_window_base_i),
        .dst_window_size_i             (dst_window_size_i),
        .dst_window_perm_i             (dst_window_perm_i),
        .terminal_valid_o              (terminal_valid_o),
        .terminal_success_o            (terminal_success_o),
        .terminal_error_o              (terminal_error_o),
        .terminal_error_code_o         (terminal_error_code_o),
        .terminal_error_class_o        (terminal_error_class_o),
        .dst_commit_o                  (dst_commit_o),
        .completion_kernel_id_o        (completion_kernel_id_o),
        .completion_command_flags_o    (completion_command_flags_o),
        .completion_vector_op_o        (completion_vector_op_o),
        .completion_vector_flags_o     (completion_vector_flags_o),
        .completion_context_id_o       (completion_context_id_o),
        .completion_capability_epoch_o (completion_capability_epoch_o),
        .completion_node_count_o       (completion_node_count_o),
        .completion_sequence_id_o      (completion_sequence_id_o),
        .completion_producer_id_o      (completion_producer_id_o),
        .completion_user_tag_o         (completion_user_tag_o),
        .completion_node_hash_lo_o     (completion_node_hash_lo_o),
        .completion_node_hash_hi_o     (completion_node_hash_hi_o),
        .terminal_read_words_o         (terminal_read_words_o),
        .terminal_write_words_o        (terminal_write_words_o),
        .terminal_read_bytes_o         (terminal_read_bytes_o),
        .terminal_write_bytes_o        (terminal_write_bytes_o),
        .terminal_q8_blocks_o          (terminal_q8_blocks_o),
        .terminal_q8_mac_count_o       (terminal_q8_mac_count_o),
        .terminal_vector_elements_o    (terminal_vector_elements_o),
        .terminal_callback_errors_o    (terminal_callback_errors_o),
        .dispatch_count_o              (dispatch_count_o),
        .completion_count_o            (completion_count_o)
    );

    initial clk_i = 1'b0;
    always #5 clk_i <= ~clk_i;

    always @(posedge clk_i) begin
        global_cycles <= global_cycles + 1;
        if (global_cycles >= 500) begin
            $fatal(1, "global timeout cycle=%0d", global_cycles + 1);
        end
    end

    function automatic terminal_snapshot_t sample_terminal;
        begin
            sample_terminal = {
                terminal_valid_o,
                terminal_success_o,
                terminal_error_o,
                dst_commit_o,
                terminal_error_code_o,
                terminal_error_class_o,
                completion_kernel_id_o,
                completion_command_flags_o,
                completion_vector_op_o,
                completion_vector_flags_o,
                completion_context_id_o,
                completion_capability_epoch_o,
                completion_node_count_o,
                completion_sequence_id_o,
                completion_producer_id_o,
                completion_user_tag_o,
                completion_node_hash_lo_o,
                completion_node_hash_hi_o,
                terminal_read_words_o,
                terminal_write_words_o,
                terminal_read_bytes_o,
                terminal_write_bytes_o,
                terminal_q8_blocks_o,
                terminal_q8_mac_count_o,
                terminal_vector_elements_o,
                terminal_callback_errors_o,
                dispatch_count_o,
                completion_count_o
            };
        end
    endfunction

    task automatic step_cycle;
        begin
            @(posedge clk_i);
            #1;
        end
    endtask

    task automatic drive_fixture(input logic [31:0] mode);
        begin
            command_abi_valid_i = 1'b1;
            windows_generation_valid_i = 1'b1;
            kernel_id_i = KERNEL_ID;
            command_flags_i = COMMAND_FLAGS;
            vector_op_i = VECTOR_OP;
            vector_flags_i = mode;
            context_id_i = CONTEXT_ID;
            capability_epoch_i = CAPABILITY_EPOCH;
            node_count_i = NODE_COUNT;
            sequence_id_i = SEQUENCE_BASE | {32'd0, mode};
            producer_id_i = PRODUCER_ID;
            user_tag_i = USER_TAG;
            node_hash_lo_i = NODE_HASH_LO;
            node_hash_hi_i = NODE_HASH_HI;
            deadline_cycles_i = DEADLINE_CYCLES;
            src0_iova_i = SRC0_IOVA;
            src1_iova_i = SRC1_IOVA;
            src2_iova_i = SRC2_IOVA;
            dst_iova_i = DST_IOVA;
            scratch_iova_i = SCRATCH_IOVA;
            element_count_i = ELEMENT_COUNT;
            outer_count_i = OUTER_COUNT;
            dtype_i = DTYPE;
            src0_stride_i = SRC0_STRIDE;
            src1_stride_i = SRC1_STRIDE;
            src2_stride_i = SRC2_STRIDE;
            dst_stride_i = DST_STRIDE;
            scalar0_i = SCALAR0;
            scalar1_i = SCALAR1;
            scratch_bytes_i = SCRATCH_BYTES;
            rope_position_i = ROPE_POSITION;
            src0_window_base_i = SRC0_WINDOW_BASE;
            src0_window_size_i = SRC0_WINDOW_SIZE;
            src0_window_perm_i = SRC0_WINDOW_PERM;
            src1_window_base_i = SRC1_WINDOW_BASE;
            src1_window_size_i = SRC1_WINDOW_SIZE;
            src1_window_perm_i = SRC1_WINDOW_PERM;
            dst_window_base_i = DST_WINDOW_BASE;
            dst_window_size_i = DST_WINDOW_SIZE;
            dst_window_perm_i = DST_WINDOW_PERM;
        end
    endtask

    task automatic poison_live_descriptor;
        begin
            command_abi_valid_i = 1'b0;
            windows_generation_valid_i = 1'b0;
            kernel_id_i = 32'hdead_beef;
            command_flags_i = 32'hffff_ffff;
            vector_op_i = 32'hffff_ffff;
            vector_flags_i = 32'hffff_ffff;
            context_id_i = 32'hffff_ffff;
            capability_epoch_i = 32'hffff_ffff;
            node_count_i = 32'hffff_ffff;
            sequence_id_i = 64'hffff_ffff_ffff_ffff;
            producer_id_i = 64'hffff_ffff_ffff_ffff;
            user_tag_i = 64'hffff_ffff_ffff_ffff;
            node_hash_lo_i = 64'hffff_ffff_ffff_ffff;
            node_hash_hi_i = 64'hffff_ffff_ffff_ffff;
            deadline_cycles_i = 64'hffff_ffff_ffff_ffff;
            src0_iova_i = 64'hffff_ffff_ffff_ffff;
            src1_iova_i = 64'hffff_ffff_ffff_ffff;
            src2_iova_i = 64'hffff_ffff_ffff_ffff;
            dst_iova_i = 64'hffff_ffff_ffff_ffff;
            scratch_iova_i = 64'hffff_ffff_ffff_ffff;
            element_count_i = 64'hffff_ffff_ffff_ffff;
            outer_count_i = 32'hffff_ffff;
            dtype_i = 32'hffff_ffff;
            src0_stride_i = 64'hffff_ffff_ffff_ffff;
            src1_stride_i = 64'hffff_ffff_ffff_ffff;
            src2_stride_i = 64'hffff_ffff_ffff_ffff;
            dst_stride_i = 64'hffff_ffff_ffff_ffff;
            scalar0_i = 32'hffff_ffff;
            scalar1_i = 32'hffff_ffff;
            scratch_bytes_i = 32'hffff_ffff;
            rope_position_i = 32'hffff_ffff;
            src0_window_base_i = 64'hffff_ffff_ffff_ffff;
            src0_window_size_i = 64'hffff_ffff_ffff_ffff;
            src0_window_perm_i = 32'hffff_ffff;
            src1_window_base_i = 64'hffff_ffff_ffff_ffff;
            src1_window_size_i = 64'hffff_ffff_ffff_ffff;
            src1_window_perm_i = 32'hffff_ffff;
            dst_window_base_i = 64'hffff_ffff_ffff_ffff;
            dst_window_size_i = 64'hffff_ffff_ffff_ffff;
            dst_window_perm_i = 32'hffff_ffff;
        end
    endtask

    task automatic check_outputs_zero(input string phase);
        begin
            if (command_ready_o !== 1'b0 || busy_o !== 1'b0
                || sample_terminal() !== '0) begin
                $fatal(1, "%s outputs must all be zero", phase);
            end
        end
    endtask

    task automatic wait_ready;
        integer guard;
        begin
            guard = 0;
            while (command_ready_o !== 1'b1) begin
                step_cycle();
                guard = guard + 1;
                if (guard > 10) begin
                    $fatal(1, "ready timeout");
                end
            end
        end
    endtask

    task automatic check_terminal(
        input logic [31:0] mode,
        input logic expected_success,
        input logic [31:0] expected_error_code,
        input logic [31:0] expected_error_class,
        input logic [63:0] expected_read_words,
        input logic [63:0] expected_write_words,
        input logic [63:0] expected_read_bytes,
        input logic [63:0] expected_write_bytes,
        input logic [63:0] expected_q8_blocks,
        input logic [63:0] expected_q8_mac_count,
        input logic [63:0] expected_vector_elements,
        input logic [31:0] expected_callback_errors
    );
        begin
            if (terminal_valid_o !== 1'b1
                || terminal_success_o !== expected_success
                || terminal_error_o !== !expected_success
                || dst_commit_o !== expected_success
                || terminal_error_code_o !== expected_error_code
                || terminal_error_class_o !== expected_error_class) begin
                $fatal(1,
                    "terminal status mismatch mode=%08x success=%0b code=%08x class=%08x",
                    mode, terminal_success_o, terminal_error_code_o,
                    terminal_error_class_o);
            end
            if (completion_kernel_id_o !== KERNEL_ID
                || completion_command_flags_o !== COMMAND_FLAGS
                || completion_vector_op_o !== VECTOR_OP
                || completion_vector_flags_o !== mode
                || completion_context_id_o !== CONTEXT_ID
                || completion_capability_epoch_o !== CAPABILITY_EPOCH
                || completion_node_count_o !== NODE_COUNT
                || completion_sequence_id_o
                    !== (SEQUENCE_BASE | {32'd0, mode})
                || completion_producer_id_o !== PRODUCER_ID
                || completion_user_tag_o !== USER_TAG
                || completion_node_hash_lo_o !== NODE_HASH_LO
                || completion_node_hash_hi_o !== NODE_HASH_HI) begin
                $fatal(1, "completion identity mismatch mode=%08x", mode);
            end
            if (terminal_read_words_o !== expected_read_words
                || terminal_write_words_o !== expected_write_words
                || terminal_read_bytes_o !== expected_read_bytes
                || terminal_write_bytes_o !== expected_write_bytes
                || terminal_q8_blocks_o !== expected_q8_blocks
                || terminal_q8_mac_count_o !== expected_q8_mac_count
                || terminal_vector_elements_o !== expected_vector_elements
                || terminal_callback_errors_o
                    !== expected_callback_errors) begin
                $fatal(1, "terminal ledger mismatch mode=%08x", mode);
            end
            if (dispatch_count_o !== expected_transactions
                || completion_count_o !== expected_transactions) begin
                $fatal(1,
                    "counter mismatch mode=%08x dispatch=%0d completion=%0d expected=%0d",
                    mode, dispatch_count_o, completion_count_o,
                    expected_transactions);
            end
        end
    endtask

    task automatic run_case(
        input logic [31:0] mode,
        input logic expected_success,
        input logic [31:0] expected_error_code,
        input logic [31:0] expected_error_class,
        input logic [63:0] expected_read_words,
        input logic [63:0] expected_write_words,
        input logic [63:0] expected_read_bytes,
        input logic [63:0] expected_write_bytes,
        input logic [63:0] expected_q8_blocks,
        input logic [63:0] expected_q8_mac_count,
        input logic [63:0] expected_vector_elements,
        input logic [31:0] expected_callback_errors
    );
        longint unsigned calls_before;
        begin
            wait_ready();
            calls_before = npu_functional_command_stub_call_count();
            expected_transactions = expected_transactions + 64'd1;

            @(negedge clk_i);
            drive_fixture(mode);
            command_valid_i = 1'b1;
            step_cycle();
            if (busy_o !== 1'b1 || command_ready_o !== 1'b0
                || terminal_valid_o !== 1'b0
                || dispatch_count_o !== expected_transactions
                || completion_count_o !== (expected_transactions - 64'd1)
                || npu_functional_command_stub_call_count() !== calls_before) begin
                $fatal(1, "accept/execute separation mismatch mode=%08x", mode);
            end

            // Keep valid asserted while busy and mutate every live descriptor
            // field.  The one DPI call must still see the registered command.
            @(negedge clk_i);
            poison_live_descriptor();
            step_cycle();
            if (npu_functional_command_stub_call_count()
                !== (calls_before + 64'd1)) begin
                $fatal(1, "DPI call count mismatch mode=%08x", mode);
            end
            check_terminal(
                mode,
                expected_success,
                expected_error_code,
                expected_error_class,
                expected_read_words,
                expected_write_words,
                expected_read_bytes,
                expected_write_bytes,
                expected_q8_blocks,
                expected_q8_mac_count,
                expected_vector_elements,
                expected_callback_errors
            );

            terminal_snapshot_before = sample_terminal();
            @(negedge clk_i);
            #1;
            if (sample_terminal() !== terminal_snapshot_before) begin
                $fatal(1, "terminal payload changed within beat mode=%08x", mode);
            end
            check_terminal(
                mode,
                expected_success,
                expected_error_code,
                expected_error_class,
                expected_read_words,
                expected_write_words,
                expected_read_bytes,
                expected_write_bytes,
                expected_q8_blocks,
                expected_q8_mac_count,
                expected_vector_elements,
                expected_callback_errors
            );
            command_valid_i = 1'b0;

            step_cycle();
            if (terminal_valid_o !== 1'b0 || busy_o !== 1'b0
                || command_ready_o !== 1'b1
                || dispatch_count_o !== expected_transactions
                || completion_count_o !== expected_transactions
                || npu_functional_command_stub_call_count()
                    !== (calls_before + 64'd1)) begin
                $fatal(1, "terminal duration/recovery mismatch mode=%08x", mode);
            end
            step_cycle();
            if (npu_functional_command_stub_call_count()
                !== (calls_before + 64'd1)) begin
                $fatal(1, "duplicate DPI call after terminal mode=%08x", mode);
            end
        end
    endtask

    initial begin
        global_cycles = 0;
        expected_transactions = 64'd0;
        rst_i = 1'b1;
        enable_i = 1'b1;
        command_valid_i = 1'b1;
        drive_fixture(32'h0000_0010);
        npu_functional_command_stub_reset();

        repeat (3) begin
            step_cycle();
            check_outputs_zero("reset");
        end
        if (npu_functional_command_stub_call_count() !== 64'd0) begin
            $fatal(1, "DPI called during reset");
        end

        @(negedge clk_i);
        rst_i = 1'b0;
        enable_i = 1'b0;
        repeat (2) begin
            step_cycle();
            check_outputs_zero("disable");
        end
        if (npu_functional_command_stub_call_count() !== 64'd0) begin
            $fatal(1, "DPI called while disabled");
        end

        // Accept a command, then disable before EXECUTE.  The pending command
        // must be discarded without entering DPI.
        @(negedge clk_i);
        enable_i = 1'b1;
        command_valid_i = 1'b0;
        step_cycle();
        @(negedge clk_i);
        drive_fixture(32'h0000_0010);
        command_valid_i = 1'b1;
        step_cycle();
        if (dispatch_count_o !== 64'd1 || busy_o !== 1'b1) begin
            $fatal(1, "disable-abort command was not accepted");
        end
        @(negedge clk_i);
        enable_i = 1'b0;
        #1;
        check_outputs_zero("disable-before-execute");
        step_cycle();
        if (npu_functional_command_stub_call_count() !== 64'd0) begin
            $fatal(1, "DPI called after disable-before-execute");
        end

        // Repeat the same cancellation with reset to cover reset priority over
        // the single EXECUTE edge.
        @(negedge clk_i);
        enable_i = 1'b1;
        command_valid_i = 1'b0;
        step_cycle();
        @(negedge clk_i);
        drive_fixture(32'h0000_0010);
        command_valid_i = 1'b1;
        step_cycle();
        if (dispatch_count_o !== 64'd1 || busy_o !== 1'b1) begin
            $fatal(1, "reset-abort command was not accepted");
        end
        @(negedge clk_i);
        rst_i = 1'b1;
        #1;
        check_outputs_zero("reset-before-execute");
        step_cycle();
        if (npu_functional_command_stub_call_count() !== 64'd0) begin
            $fatal(1, "DPI called after reset-before-execute");
        end
        @(negedge clk_i);
        rst_i = 1'b0;
        command_valid_i = 1'b0;
        step_cycle();
        expected_transactions = 64'd0;

        run_case(
            32'h0000_0010,
            1'b1,
            32'd0,
            32'd0,
            READ_WORDS,
            WRITE_WORDS,
            READ_BYTES,
            WRITE_BYTES,
            Q8_BLOCKS,
            Q8_MAC_COUNT,
            VECTOR_ELEMENTS,
            32'd0
        );
        run_case(
            32'h0000_0011,
            1'b0,
            DPI_ERROR_CODE,
            DPI_ERROR_CLASS,
            64'd0,
            64'd0,
            64'd0,
            64'd0,
            64'd0,
            64'd0,
            64'd0,
            32'd0
        );
        run_case(
            32'h0000_0012,
            1'b0,
            ERROR_CODE_LEDGER_CLOSURE,
            ERROR_CLASS_DPI_CONTRACT,
            READ_WORDS,
            WRITE_WORDS,
            READ_BYTES - 64'd1,
            WRITE_BYTES,
            Q8_BLOCKS,
            Q8_MAC_COUNT,
            VECTOR_ELEMENTS,
            32'd0
        );
        run_case(
            32'h0000_0013,
            1'b0,
            ERROR_CODE_CALLBACK,
            ERROR_CLASS_DPI_CONTRACT,
            READ_WORDS,
            WRITE_WORDS,
            READ_BYTES,
            WRITE_BYTES,
            Q8_BLOCKS,
            Q8_MAC_COUNT,
            VECTOR_ELEMENTS,
            32'd2
        );
        run_case(
            32'h0000_0014,
            1'b0,
            ERROR_CODE_STATUS_FRAME,
            ERROR_CLASS_DPI_CONTRACT,
            READ_WORDS,
            WRITE_WORDS,
            READ_BYTES,
            WRITE_BYTES,
            Q8_BLOCKS,
            Q8_MAC_COUNT,
            VECTOR_ELEMENTS,
            32'd0
        );

        if (npu_functional_command_stub_call_count() !== 64'd5
            || dispatch_count_o !== 64'd5
            || completion_count_o !== 64'd5) begin
            $fatal(1, "final exact-once ledger mismatch");
        end

        $display("[NPU-FUNCTIONAL-COMMAND-DPI][PASS] positive=1 dpi_error=1 closure_error=1 callback_error=1 status_error=1 reset_no_call=1 disable_no_call=1 busy_single_dispatch=1 terminal_stable=1 calls=5 dispatch=5 completion=5");
        $finish;
    end

endmodule

`default_nettype wire
